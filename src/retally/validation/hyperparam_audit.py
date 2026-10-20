"""Audit a generated reproduction script against the paper's stated hyperparameters.

The auditor parses the script with :mod:`ast` and, for each
:class:`HyperparameterSpec` the extractor produced, decides whether the
code used the paper's value, used a different literal, or fell into one
of two ambiguous states (kwarg absent entirely, or present but bound to
something we cannot evaluate statically).

This module is deliberately deterministic and has no LLM dependency —
the LLM's job is upstream (extracting the spec).  Once we have the
spec, comparing it to the code is a code-inspection problem.

Limitations (intentional, documented for callers):

* Only literal arguments are matched.  ``LogisticRegression(C=1.0)`` ✓.
  ``c = 1.0; LogisticRegression(C=c)`` → UNRESOLVED.  We could chase
  trivial assignments but the false-positive rate of "I think I know
  what the variable is" is high enough that flagging UNRESOLVED and
  letting a human read the code seems safer.

* We do not match kwargs passed as ``**kwargs`` unpackings, dictionaries
  fed into ``set_params``, or values assigned post-construction.

* We do not match positional arguments — a paper-stated hyperparameter
  passed positionally will surface as NOT_FOUND.  Generated code in
  practice uses keyword arguments because the prompt asks for them.

Float comparison uses :func:`math.isclose` with ``rel_tol=1e-6`` and
``abs_tol=1e-9`` to absorb the usual round-trip noise (e.g. 0.1
serialised through JSON).
"""

from __future__ import annotations

import ast
import math
from typing import Any

from retally.models import AuditStatus, HyperparameterAudit, HyperparameterSpec


def audit_hyperparameters(code: str, specs: list[HyperparameterSpec]) -> list[HyperparameterAudit]:
    """Compare ``code`` to each spec; return one audit per spec, in order.

    If ``code`` does not parse as Python the entire spec list is
    returned as UNRESOLVED with a note explaining why — there's no
    point trying to walk a broken AST, but we also don't want a
    SyntaxError in generated code to crash the report builder.
    """
    if not specs:
        return []

    try:
        tree = ast.parse(code)
    except SyntaxError as exc:
        return [
            HyperparameterAudit(
                spec=s,
                status=AuditStatus.UNRESOLVED,
                notes=f"Could not parse generated code: {exc}",
            )
            for s in specs
        ]

    # Walk the AST once and gather every kwarg=value pair we see across
    # every Call.  We keep all observations per kwarg name because the
    # same hyperparameter can legitimately appear in multiple calls
    # (e.g. random_state passed to train_test_split AND to a model).
    observations: dict[str, list[_Observation]] = {}
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call):
            continue
        for kw in node.keywords:
            if kw.arg is None:
                continue  # **kwargs unpacking — skip
            observations.setdefault(kw.arg, []).append(_evaluate(kw.value))

    return [_audit_one(spec, observations.get(spec.name, [])) for spec in specs]


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------


class _Observation:
    """A single kwarg=value occurrence in the AST.

    ``value`` is the resolved Python literal when we could compute one;
    otherwise it is the unparsed source string and ``unresolved`` is True.
    """

    __slots__ = ("value", "unresolved")

    def __init__(self, value: Any, unresolved: bool = False) -> None:
        self.value = value
        self.unresolved = unresolved


def _evaluate(node: ast.expr) -> _Observation:
    """Try to evaluate ``node`` as a Python literal; return _Observation."""
    try:
        return _Observation(ast.literal_eval(node))
    except (ValueError, SyntaxError):
        return _Observation(ast.unparse(node), unresolved=True)


def _audit_one(spec: HyperparameterSpec, observations: list[_Observation]) -> HyperparameterAudit:
    """Apply audit rules to a single spec given every observation of its kwarg."""
    if not observations:
        return HyperparameterAudit(
            spec=spec,
            status=AuditStatus.NOT_FOUND,
            notes=(
                f"Keyword argument '{spec.name}' did not appear in any call. "
                "The code may be relying on the library default."
            ),
        )

    # If any observation matches, the spec is honoured.  We pick the
    # first match for the observed_value field; ties go to the earliest
    # match in source order.
    for obs in observations:
        if not obs.unresolved and _values_equal(obs.value, spec.value):
            return HyperparameterAudit(
                spec=spec,
                status=AuditStatus.MATCH,
                observed_value=obs.value,
            )

    # Nothing matched.  Distinguish MISMATCH (some resolvable literal
    # was observed but none equalled the spec) from UNRESOLVED (the
    # only observations are non-literal expressions).
    resolved = [o for o in observations if not o.unresolved]
    if resolved:
        return HyperparameterAudit(
            spec=spec,
            status=AuditStatus.MISMATCH,
            observed_value=resolved[0].value,
            notes=(
                f"Paper specifies {spec.name}={spec.value!r}, code uses {spec.name}={resolved[0].value!r}."
            ),
        )

    return HyperparameterAudit(
        spec=spec,
        status=AuditStatus.UNRESOLVED,
        observed_value=observations[0].value,
        notes=(
            f"'{spec.name}' is set to a non-literal expression "
            f"({observations[0].value!r}); cannot verify statically."
        ),
    )


def _values_equal(observed: Any, expected: Any) -> bool:
    """Compare a literal observed in the AST against a spec value.

    Rules:
    * Numerics (``int``, ``float``) compare with float tolerance.
    * Lists and tuples are interchangeable element-wise (papers may
      say "32 units" → spec value ``[32]`` while sklearn idiom is
      ``hidden_layer_sizes=(32,)``).
    * Strings compare case-sensitively after stripping surrounding
      whitespace (``'rbf'`` vs ``'rbf'``).
    * Everything else uses ``==``.
    """
    if isinstance(observed, bool) or isinstance(expected, bool):
        # bool is a subclass of int in Python, so ``True == 1`` is True.
        # Require strict type equality whenever either side is a bool so a
        # paper-stated fit_intercept=1 doesn't pretend to match
        # fit_intercept=True.
        return type(observed) is type(expected) and observed == expected
    if isinstance(observed, (int, float)) and isinstance(expected, (int, float)):
        return math.isclose(observed, expected, rel_tol=1e-6, abs_tol=1e-9)
    if isinstance(observed, (list, tuple)) and isinstance(expected, (list, tuple)):
        if len(observed) != len(expected):
            return False
        return all(_values_equal(o, e) for o, e in zip(observed, expected))
    if isinstance(observed, str) and isinstance(expected, str):
        return observed.strip() == expected.strip()
    return observed == expected
