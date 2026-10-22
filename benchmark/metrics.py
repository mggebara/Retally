"""Closeness metrics over benchmark claim details — the tuning signal.

Binary pass counts saturate at the extremes: when 0 of 102 claims pass,
every prompt change reads as "still zero", including one that moved half
the claims from 300% relative error to 5%.  These aggregates move
smoothly as reproductions get closer, which is what makes A/B-comparing
prompt variants possible at all.

Consumed by ``benchmark.report`` (per-split section in REPORT.md) and
``benchmark.compare`` (run-vs-run diffs).  Everything here operates on
the plain-dict shape of ``results.json`` — one dict per entry, each with
a ``claim_details`` list — so both consumers can feed it JSON directly.
"""

from __future__ import annotations

from dataclasses import dataclass
from statistics import median
from typing import Any


@dataclass
class ClosenessMetrics:
    """Aggregates over every claim of every *executed* entry in a group."""

    n_entries: int
    """Executed (non-skipped) entries contributing claims."""

    n_claims: int
    """Total compared claims across those entries."""

    n_matched: int
    """Claims where some output value was matched (reproduced is not None).
    Unmatched claims usually mean the generated code never computed that
    quantity — a codegen/matching gap, distinct from a wrong value."""

    n_passed: int
    """Claims within their comparator tolerance."""

    median_rel_err: float | None
    """Median relative error over matched claims.  None when nothing
    matched.  Median, not mean: one claim matched against the wrong
    output can be off by 1000x and would swamp a mean."""

    frac_within_tol: float | None
    frac_within_2x_tol: float | None
    frac_within_5x_tol: float | None
    """Fractions of *matched* claims with rel_err inside 1x / 2x / 5x of
    that claim's own tolerance.  The widening bands are the gradient:
    a prompt fix often shows up at 5x before it shows up at 1x.  None
    when nothing matched."""

    match_rate: float | None
    """n_matched / n_claims — None when there are no claims at all."""


def closeness(results: list[dict[str, Any]]) -> ClosenessMetrics:
    """Compute ClosenessMetrics over the executed entries of ``results``."""
    executed = [r for r in results if not r.get("skipped")]
    details = [cd for r in executed for cd in r.get("claim_details", [])]
    matched = [cd for cd in details if cd.get("reproduced") is not None]

    def _frac_within(k: float) -> float | None:
        if not matched:
            return None
        n = sum(1 for cd in matched if cd["rel_err"] <= k * cd["tolerance"])
        return n / len(matched)

    return ClosenessMetrics(
        n_entries=len(executed),
        n_claims=len(details),
        n_matched=len(matched),
        n_passed=sum(1 for cd in details if cd.get("passed")),
        median_rel_err=median(cd["rel_err"] for cd in matched) if matched else None,
        frac_within_tol=_frac_within(1.0),
        frac_within_2x_tol=_frac_within(2.0),
        frac_within_5x_tol=_frac_within(5.0),
        match_rate=(len(matched) / len(details)) if details else None,
    )


def by_split(results: list[dict[str, Any]]) -> dict[str, ClosenessMetrics]:
    """Group results by their ``split`` label and compute metrics per group.

    Only splits that actually appear are returned, in sorted order — a
    dev-only catalog yields ``{"dev": ...}`` with no empty holdout row.
    """
    splits = sorted({r.get("split", "dev") for r in results})
    return {s: closeness([r for r in results if r.get("split", "dev") == s]) for s in splits}


def format_metrics_line(m: ClosenessMetrics) -> str:
    """One human-readable summary line, shared by report and compare."""
    if m.n_claims == 0:
        return f"{m.n_entries} entries, no claims compared"
    parts = [
        f"{m.n_entries} entries",
        f"{m.n_claims} claims",
        f"matched {_pct(m.match_rate)}",
        f"passed {m.n_passed}/{m.n_claims}",
    ]
    if m.median_rel_err is not None:
        parts.append(f"median rel err {m.median_rel_err:.1%}")
        parts.append(
            f"within tol/2x/5x: {_pct(m.frac_within_tol)}/"
            f"{_pct(m.frac_within_2x_tol)}/{_pct(m.frac_within_5x_tol)}"
        )
    return ", ".join(parts)


def _pct(v: float | None) -> str:
    return "—" if v is None else f"{v:.0%}"


# ---------------------------------------------------------------------------
# Reproduction modes (seeded vs independent vs blind)
# ---------------------------------------------------------------------------

_MODE_ORDER = ("seeded", "independent", "blind")


def mode_of(result: dict[str, Any]) -> str:
    """A result row's reproduction mode; rows predating the field were seeded."""
    return str(result.get("mode") or "seeded")


def result_rows(payload: Any) -> list[dict[str, Any]]:
    """The result rows of a loaded results JSON file.

    Current files are ``{"usage": {...}, "results": [...]}``; files written
    before run-level cost accounting are a bare list of rows.
    """
    if isinstance(payload, dict):
        return list(payload.get("results") or [])
    return list(payload or [])


def reproducer_of(result: dict[str, Any]) -> str:
    """The reproducer that produced a row; rows predating the field came from the pipeline."""
    return str(result.get("reproducer") or "pipeline")


def reproducers_present(results: list[dict[str, Any]]) -> list[str]:
    """Distinct reproducers in ``results``, sorted."""
    return sorted({reproducer_of(r) for r in results})


def modes_present(results: list[dict[str, Any]]) -> list[str]:
    """Modes appearing in ``results``: seeded, independent, blind, then any others sorted."""
    present = {mode_of(r) for r in results}
    return [m for m in _MODE_ORDER if m in present] + sorted(present - set(_MODE_ORDER))


def by_mode(results: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    """Group result rows by reproduction mode, in ``modes_present`` order.

    Every aggregate (verdicts, closeness, components) must be computed
    within one mode: pooling a seeded and an independent row of the same
    paper would double-count it and blend two different measurements.
    """
    return {m: [r for r in results if mode_of(r) == m] for m in modes_present(results)}


@dataclass
class ModeGap:
    """Seeded-vs-independent comparison for one paper run in both modes.

    The gap is the project's primary finding: how much of a computational
    reproduction (authors' scripts in the prompt) survives when the model
    must work from the paper text alone.
    """

    entry_id: str
    split: str
    seeded_passed: int
    seeded_total: int
    independent_passed: int
    independent_total: int
    lost: list[str]
    """Claim descriptions that pass seeded but not independent — what the
    authors' scripts were carrying."""

    gained: list[str]
    """Claim descriptions that pass independent but not seeded (rare; under
    the wider SE-aware independent band it is often a tolerance effect)."""

    reproducer: str = "pipeline"
    """The reproducer behind both rows (``seeded / independent`` if they differ)."""

    seeded_passed_first_attempt: int | None = None
    independent_passed_first_attempt: int | None = None
    """Claims each row's *first* execution already passed, before any
    refinement feedback (``n_claims_with_paper_match_first_attempt``).
    None when that row carries no attempt data (older files, or a
    reproducer that does not report attempts)."""

    seeded_passed_first_scored: int | None = None
    independent_passed_first_scored: int | None = None
    """Claims each row's *first scored* execution passed — the first one that
    printed a parsable ``RESULT:`` line, after crash repairs but before any
    claim-targeted feedback (``n_claims_with_paper_match_first_scored``).
    None on rows that predate the field."""

    blind_passed: int | None = None
    blind_total: int | None = None
    blind_passed_first_scored: int | None = None
    """The paper's blind row (targets withheld, no claim-targeted refinement),
    when the run executed one; all None otherwise.  First scored equals the
    final count by construction, but is read from the row like the others."""

    @property
    def has_blind(self) -> bool:
        return self.blind_passed is not None


def mode_gaps(results: list[dict[str, Any]]) -> list[ModeGap]:
    """One ModeGap per entry *executed* in both seeded and independent mode.

    Claims are joined across modes by description, the same key
    ``benchmark.compare`` uses across runs.  Sorted by entry id.  When the
    entry also has an executed blind row its counts fill the optional
    ``blind_*`` fields; ``lost`` / ``gained`` stay seeded-vs-independent.

    When several reproducers ran the same (entry, mode) cell -- results
    files concatenated by ``python -m benchmark.report a.json b.json`` --
    the entry gets one gap per reproducer, each from that reproducer's own
    rows, sorted by reproducer.  Otherwise rows are joined by entry alone,
    so a seeded row from one agent and an independent row from another
    still pair (``reproducer`` then reads ``a / b``).
    """
    executed = [r for r in results if not r.get("skipped")]
    gaps: list[ModeGap] = []
    for entry_id in sorted({r["entry_id"] for r in executed}):
        entry_rows = [r for r in executed if r["entry_id"] == entry_id]
        cells = [(mode_of(r), reproducer_of(r)) for r in entry_rows]
        shared = any(sum(1 for m, _ in cells if m == mode) > 1 for mode, _ in cells)
        groups = (
            [[r for r in entry_rows if reproducer_of(r) == rep] for rep in sorted({rp for _, rp in cells})]
            if shared
            else [entry_rows]
        )
        for group in groups:
            gap = _mode_gap(entry_id, {mode_of(r): r for r in group})
            if gap is not None:
                gaps.append(gap)
    return gaps


def _mode_gap(entry_id: str, rows: dict[str, dict[str, Any]]) -> ModeGap | None:
    """The ModeGap of one entry's rows keyed by mode; None unless seeded and independent both ran."""
    seeded = rows.get("seeded")
    independent = rows.get("independent")
    if seeded is None or independent is None:
        return None
    s_pass = {cd["description"] for cd in seeded.get("claim_details", []) if cd.get("passed")}
    i_pass = {cd["description"] for cd in independent.get("claim_details", []) if cd.get("passed")}
    blind = rows.get("blind")
    return ModeGap(
        entry_id=entry_id,
        split=str(seeded.get("split", "dev")),
        seeded_passed=len(s_pass),
        seeded_total=len(seeded.get("claim_details", [])),
        independent_passed=len(i_pass),
        independent_total=len(independent.get("claim_details", [])),
        lost=sorted(s_pass - i_pass),
        gained=sorted(i_pass - s_pass),
        reproducer=_joined_reproducer(seeded, independent),
        seeded_passed_first_attempt=first_attempt_passed(seeded),
        independent_passed_first_attempt=first_attempt_passed(independent),
        seeded_passed_first_scored=first_scored_passed(seeded),
        independent_passed_first_scored=first_scored_passed(independent),
        blind_passed=(
            None if blind is None else sum(1 for cd in blind.get("claim_details", []) if cd.get("passed"))
        ),
        blind_total=None if blind is None else len(blind.get("claim_details", [])),
        blind_passed_first_scored=None if blind is None else first_scored_passed(blind),
    )


def _int_field(result: dict[str, Any], key: str) -> int | None:
    v = result.get(key)
    return v if isinstance(v, int) and not isinstance(v, bool) else None


def first_attempt_passed(result: dict[str, Any]) -> int | None:
    """Claims a row's first execution passed; None when the row has no attempt data."""
    return _int_field(result, "n_claims_with_paper_match_first_attempt")


def first_scored_passed(result: dict[str, Any]) -> int | None:
    """Claims a row's first *scored* execution passed; None when not recorded."""
    return _int_field(result, "n_claims_with_paper_match_first_scored")


def before_feedback_passed(result: dict[str, Any]) -> tuple[str, int] | None:
    """The headline "before target feedback" count, as ``("first scored", n)``.

    Rows that predate first-scored scoring fall back to
    ``("first attempt", n)``; None when the row has neither.
    """
    scored = first_scored_passed(result)
    if scored is not None:
        return "first scored", scored
    first = first_attempt_passed(result)
    if first is not None:
        return "first attempt", first
    return None


def refinements_of(result: dict[str, Any]) -> int | None:
    """Refinement calls behind a row; None when not recorded."""
    return _int_field(result, "n_refinements")


def refinements_note(result: dict[str, Any]) -> str:
    """``2 error + 3 claim refinements`` when the split is recorded, else ``5 refinements``; "" if neither."""
    n_err = _int_field(result, "n_error_refinements")
    n_claim = _int_field(result, "n_claim_refinements")
    if n_err is not None and n_claim is not None:
        return f"{n_err} error + {n_claim} claim refinement{'' if n_err + n_claim == 1 else 's'}"
    n_ref = refinements_of(result)
    if n_ref is not None:
        return f"{n_ref} refinement{'' if n_ref == 1 else 's'}"
    return ""


def first_attempt_note(result: dict[str, Any]) -> str:
    """``first scored 3/11, 2 error + 3 claim refinements`` for a row with attempt data; "" otherwise.

    The count is :func:`before_feedback_passed`: first scored, or first
    attempt on rows that predate it (``first attempt 12/13, 2
    refinements``).  The denominator is the row's compared claims
    (``claim_details``), falling back to the catalog claim count.
    """
    before = before_feedback_passed(result)
    parts = []
    if before is not None:
        total = len(result.get("claim_details") or []) or int(result.get("n_claims_in_catalog") or 0)
        parts.append(f"{before[0]} {before[1]}/{total}")
    refinements = refinements_note(result)
    if refinements:
        parts.append(refinements)
    return ", ".join(parts)


def _joined_reproducer(seeded: dict[str, Any], independent: dict[str, Any]) -> str:
    s, i = reproducer_of(seeded), reproducer_of(independent)
    return s if s == i else f"{s} / {i}"
