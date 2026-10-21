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
# Reproduction modes (seeded vs independent)
# ---------------------------------------------------------------------------

_MODE_ORDER = ("seeded", "independent")


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
    """Modes appearing in ``results``: seeded, then independent, then any others sorted."""
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


def mode_gaps(results: list[dict[str, Any]]) -> list[ModeGap]:
    """One ModeGap per entry *executed* in both seeded and independent mode.

    Claims are joined across modes by description, the same key
    ``benchmark.compare`` uses across runs.  Sorted by entry id.
    """
    rows: dict[tuple[str, str], dict[str, Any]] = {
        (r["entry_id"], mode_of(r)): r for r in results if not r.get("skipped")
    }
    gaps: list[ModeGap] = []
    for entry_id in sorted({eid for eid, _ in rows}):
        seeded = rows.get((entry_id, "seeded"))
        independent = rows.get((entry_id, "independent"))
        if seeded is None or independent is None:
            continue
        s_pass = {cd["description"] for cd in seeded.get("claim_details", []) if cd.get("passed")}
        i_pass = {cd["description"] for cd in independent.get("claim_details", []) if cd.get("passed")}
        gaps.append(
            ModeGap(
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
            )
        )
    return gaps


def first_attempt_passed(result: dict[str, Any]) -> int | None:
    """Claims a row's first execution passed; None when the row has no attempt data."""
    v = result.get("n_claims_with_paper_match_first_attempt")
    return v if isinstance(v, int) and not isinstance(v, bool) else None


def refinements_of(result: dict[str, Any]) -> int | None:
    """Refinement calls behind a row; None when not recorded."""
    v = result.get("n_refinements")
    return v if isinstance(v, int) and not isinstance(v, bool) else None


def first_attempt_note(result: dict[str, Any]) -> str:
    """``first attempt 12/13, 2 refinements`` for a row with attempt data; empty otherwise.

    The denominator is the row's compared claims (``claim_details``),
    falling back to the catalog claim count.
    """
    first = first_attempt_passed(result)
    n_ref = refinements_of(result)
    parts = []
    if first is not None:
        total = len(result.get("claim_details") or []) or int(result.get("n_claims_in_catalog") or 0)
        parts.append(f"first attempt {first}/{total}")
    if n_ref is not None:
        parts.append(f"{n_ref} refinement{'' if n_ref == 1 else 's'}")
    return ", ".join(parts)


def _joined_reproducer(seeded: dict[str, Any], independent: dict[str, Any]) -> str:
    s, i = reproducer_of(seeded), reproducer_of(independent)
    return s if s == i else f"{s} / {i}"
