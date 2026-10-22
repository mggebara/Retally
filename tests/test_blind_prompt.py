"""Blind reproduction: no claim value reaches the model, in any form.

Blind mode (``ReproductionMode.BLIND``) is independent mode with the
targets withheld: the generation prompt names each claim (token, type,
unit label, location, context) but never its value or standard error, and
the claim-targeted refinement loop never runs.  These tests guard the
"never" with string searches over the rendered prompts:

* every curated catalog entry's pinned claims, converted exactly as the
  benchmark runner converts them, rendered into a blind prompt, searched
  for each claim's value, standard error and sample size in every format
  the prompt code could produce;
* a golden blind R prompt (``tests/fixtures/seeded_prompt/
  generation_prompt_blind_r.txt``) over the same fixture package the
  seeded goldens use, so any change to the blind prompt is deliberate.

Curated free text (description, location, context, unit) is rendered
verbatim and may mention a number -- an N, a control mean.  That is the
curator's responsibility (``benchmark/papers/README.md``), so a format
string that already occurs in the curated text is not counted as a leak
here; every other occurrence is.  ``tests/test_catalog_contexts.py``
checks the curated text itself: it may not state any pinned value.
"""

from __future__ import annotations

import os
import re
from pathlib import Path
from unittest.mock import MagicMock

import pytest

from retally.codegen.generator import CodeGenerator
from retally.models import Claim, ClaimType, Dataset, Language, Paper, ReproductionMode
from tests._loaders import REPO_ROOT, load_module_from_path

bschema = load_module_from_path("benchmark.schema", REPO_ROOT / "benchmark" / "schema.py")
load_module_from_path("benchmark.pricing", REPO_ROOT / "benchmark" / "pricing.py")
load_module_from_path("benchmark.reproducer", REPO_ROOT / "benchmark" / "reproducer.py")
runner = load_module_from_path("benchmark.runner", REPO_ROOT / "benchmark" / "runner.py")

FIXTURE_DIR = Path(__file__).parent / "fixtures" / "seeded_prompt"
PACKAGE_DIR = FIXTURE_DIR / "package"
BLIND_GOLDEN = FIXTURE_DIR / "generation_prompt_blind_r.txt"

CATALOG = [e for e in bschema.load_catalog(runner.CATALOG_DIR) if e.original_claims]


def _value_strings(v: float) -> set[str]:
    """Every way the prompt code could plausibly format ``v``.

    ``str`` / ``repr`` (the f-string ``{claim.value}``), ``%g`` at a few
    precisions (``{x:.6g}`` is what the claim-refinement prompt used),
    fixed decimals, and the sign-less magnitude of each.  Strings shorter
    than three characters ("0", "-1") would match unrelated text and are
    dropped.
    """
    forms: set[str] = set()
    for x in (v, abs(v)):
        forms |= {str(x), repr(x), f"{x:g}", f"{x:.6g}", f"{x:.4g}", f"{x:.3g}", f"{x:.4f}", f"{x:.3f}"}
        if float(x).is_integer():
            forms |= {str(int(x)), f"{int(x):,}"}
    return {f for f in forms if len(f) >= 3}


def _blind_prompt(paper: Paper, language: Language = Language.R) -> str:
    client = MagicMock()
    client.messages.create.return_value = MagicMock(content=[MagicMock(text="x <- 1")])
    CodeGenerator(client).generate(
        paper,
        Dataset(name="pkg", source_url="", local_path=PACKAGE_DIR),
        reproduction_mode=ReproductionMode.BLIND,
    )
    return client.messages.create.call_args.kwargs["messages"][0]["content"]


def _occurs(form: str, text: str) -> bool:
    """``form`` occurs in ``text`` as a whole number, not as the prefix or
    suffix of a longer one ("0.3" inside the template's "0.342" is not a leak
    of 0.3)."""
    return re.search(rf"(?<![\d.]){re.escape(form)}(?!\d)", text) is not None


def _leaks(prompt: str, curated: str, numbers: list[float]) -> list[str]:
    return sorted(
        form
        for v in numbers
        for form in _value_strings(v)
        if _occurs(form, prompt) and not _occurs(form, curated)
    )


def test_catalog_has_pinned_claims_to_check():
    assert CATALOG, "no catalog entry has original_claims; the leak test would check nothing"


@pytest.mark.parametrize("language", [Language.R, Language.PYTHON], ids=["r", "python"])
@pytest.mark.parametrize("entry", CATALOG, ids=lambda e: e.id)
def test_blind_prompt_contains_no_catalog_claim_value(entry, language):
    claims = runner._claims_override_for(entry)
    paper = Paper(
        title=entry.paper.title or entry.id,
        abstract="",
        full_text="",
        claims=claims,
        methodology_summary="",
        language=language,
    )
    prompt = _blind_prompt(paper, language)

    curated = (
        "\n".join(
            " ".join(str(part).split())
            for oc in entry.original_claims
            for part in (oc.description, oc.location or "", oc.context or "", oc.unit or "")
        )
        + "\n"
        + (entry.paper.title or entry.id)
    )
    numbers = [oc.value for oc in entry.original_claims]
    numbers += [oc.standard_error for oc in entry.original_claims if oc.standard_error is not None]
    numbers += [float(oc.sample_size) for oc in entry.original_claims if oc.sample_size is not None]

    assert _leaks(prompt, curated, numbers) == []
    for oc in entry.original_claims:
        assert oc.description in prompt  # still told what to compute


def test_seeded_prompt_does_show_the_values():
    """The search above would catch a leak: the same claims in a seeded
    prompt are found by it."""
    claim = Claim(
        description="beta_ols", value=-1.948, claim_type=ClaimType.COEFFICIENT, standard_error=0.416
    )
    paper = Paper(title="T", abstract="", full_text="", claims=[claim], language=Language.R)
    client = MagicMock()
    client.messages.create.return_value = MagicMock(content=[MagicMock(text="x <- 1")])
    CodeGenerator(client).generate(paper, Dataset(name="pkg", source_url="", local_path=PACKAGE_DIR))
    seeded = client.messages.create.call_args.kwargs["messages"][0]["content"]
    assert _leaks(seeded, "beta_ols", [-1.948]) != []
    assert _leaks(_blind_prompt(paper), "beta_ols", [-1.948, 0.416]) == []


@pytest.mark.parametrize("language", [Language.R, Language.PYTHON], ids=["r", "python"])
def test_error_refinement_prompt_shows_no_claim_value(language):
    """Crash repairs still run in blind mode; their prompt carries the code
    and the error, never the claims."""
    claim = Claim(
        description="beta_ols", value=-1.948, claim_type=ClaimType.COEFFICIENT, standard_error=0.416
    )
    paper = Paper(title="T", abstract="", full_text="", claims=[claim], language=language)
    client = MagicMock()
    client.messages.create.return_value = MagicMock(content=[MagicMock(text="x <- 1")])
    CodeGenerator(client).refine(
        "x <- 1", "Error: object not found", paper, Dataset(name="pkg", source_url="", local_path=PACKAGE_DIR)
    )
    prompt = client.messages.create.call_args.kwargs["messages"][0]["content"]
    assert _leaks(prompt, "", [-1.948, 0.416]) == []


# ── Golden blind prompt ─────────────────────────────────────────────────


def _golden_paper() -> Paper:
    # Same paper as tests/test_seeded_prompt_golden.py.
    return Paper(
        title="Warfare and Development in India",
        abstract="We study the long-run effect of precolonial warfare on development.",
        full_text="",
        claims=[
            Claim(
                description="warfare_coefficient_bivariate",
                value=3.713,
                claim_type=ClaimType.COEFFICIENT,
                table_ref="Table 1",
                context="Table 1 column 1.  OLS with population density as a control.",
            ),
            Claim(description="n_districts", value=660, claim_type=ClaimType.OTHER),
        ],
        methodology_summary="OLS of night lights on conflict counts with state fixed effects.",
        language=Language.R,
    )


def test_blind_r_prompt_matches_golden():
    """To regenerate deliberately: ``RETALLY_REGEN_GOLDEN=1 uv run pytest tests/test_blind_prompt.py``."""
    client = MagicMock()
    client.messages.create.return_value = MagicMock(content=[MagicMock(text="x <- 1")])
    CodeGenerator(client).generate(
        _golden_paper(),
        Dataset(name="wii-package", source_url="https://zenodo.org/records/1", local_path=PACKAGE_DIR),
        reproduction_mode=ReproductionMode.BLIND,
    )
    prompt = client.messages.create.call_args.kwargs["messages"][0]["content"]
    prompt = prompt.replace(str(PACKAGE_DIR.resolve()), "<DATASET_ROOT>")
    if os.environ.get("RETALLY_REGEN_GOLDEN") == "1":
        BLIND_GOLDEN.write_text(prompt, encoding="utf-8")
    assert prompt == BLIND_GOLDEN.read_text(encoding="utf-8")
    assert _leaks(prompt, "", [3.713, 660.0]) == []
