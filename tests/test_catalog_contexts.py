"""Curated claim text never states the value of a pinned claim.

A pinned claim's ``context``, ``location`` and ``unit`` are rendered
verbatim into the generation prompt in every reproduction mode, blind
included (``tests/test_blind_prompt.py`` exempts curated text from its
leak search).  So for every catalog entry with ``original_claims``, no
claim's curated text may state the ``value`` or ``standard_error`` of any
pinned claim of the same entry -- a context saying "1,842 dyads" hands the
blind model the target of the dyad-count claim.  Sample sizes, cluster
counts and means that are pinned belong in the entry's ``notes``, which
the model never sees (``benchmark/papers/README.md``).

The rule, as checked here:

* every printed form ``tests/test_blind_prompt.py::_value_strings``
  produces for a value or standard error, matched with its ``_occurs``
  whole-number rule (not as the prefix or suffix of a longer number),
  except a fixed-decimal form whose rounding changes the value's leading
  significant digit (-0.0006 at three decimals is "-0.001", which is not
  the value; Grier's contexts print "p = 0.001" next to coefficients
  printed as -0.0006);
* integer values of two digits (cluster counts like 98 or 36) are
  checked too, as whole numbers, although ``_value_strings`` drops forms
  shorter than three characters;
* integer values below 10 are not checked: "column 1", "Table 5" and
  "Study 2" are table references, not leaks;
* a number immediately preceded by one of the words "column", "col.",
  "Table", "Panel", "Study", "wave" or "Figure" (case-insensitive,
  optional whitespace between) is a reference, not a stated value, and is
  not counted.
"""

from __future__ import annotations

import re

import pytest

from tests._loaders import REPO_ROOT, load_module_from_path
from tests.test_blind_prompt import _occurs, _value_strings

bschema = load_module_from_path("benchmark.schema", REPO_ROOT / "benchmark" / "schema.py")

CATALOG = [e for e in bschema.load_catalog(REPO_ROOT / "benchmark" / "papers") if e.original_claims]

_REFERENCE_WORD = re.compile(r"(?:column|col\.|table|panel|study|wave|figure)\s*$", re.IGNORECASE)


def _leading_digit(x: float) -> str:
    return f"{abs(x):.0e}"


def _forms(v: float) -> set[str]:
    # A fixed-decimal form that rounds away the value's leading digit is
    # not the value: -0.0006 at three decimals is "-0.001", which a
    # context printing "p = 0.001" would otherwise match.
    forms = {f for f in _value_strings(v) if _leading_digit(float(f.replace(",", ""))) == _leading_digit(v)}
    if float(v).is_integer():
        if abs(v) < 10:
            return set()
        forms.add(str(int(abs(v))))
    return forms


def _stated(form: str, text: str) -> bool:
    """``form`` occurs in ``text`` as a whole number not introduced by a
    table-reference word."""
    if not _occurs(form, text):
        return False
    for m in re.finditer(rf"(?<![\d.]){re.escape(form)}(?!\d)", text):
        if not _REFERENCE_WORD.search(text[: m.start()]):
            return True
    return False


def _findings(entry) -> list[str]:
    targets = []
    for oc in entry.original_claims:
        targets.append((oc.description, "value", oc.value))
        if oc.standard_error is not None:
            targets.append((oc.description, "standard_error", oc.standard_error))
    out = []
    for oc in entry.original_claims:
        for field in ("context", "location", "unit"):
            text = " ".join(str(getattr(oc, field) or "").split())
            for target, kind, v in targets:
                for form in sorted(_forms(v)):
                    if _stated(form, text):
                        out.append(f"{oc.description}.{field} states {target}.{kind} as {form!r}")
    return sorted(set(out))


def test_catalog_has_pinned_claims_to_check():
    assert CATALOG


@pytest.mark.parametrize("entry", CATALOG, ids=lambda e: e.id)
def test_claim_text_does_not_state_pinned_values(entry):
    assert _findings(entry) == []


def test_rule_catches_a_stated_count_and_skips_references():
    assert _stated("1,842", "Dyadic sample of 1,842 dyads")
    assert _stated("98", "clustered at the canton level (98 clusters)")
    assert not _stated("98", "Table 98")
    assert not _stated("12", "column 12")
    assert not _stated("0.3", "coefficient 0.342")
    assert _forms(5.0) == set()
    assert "36" in _forms(36.0)
