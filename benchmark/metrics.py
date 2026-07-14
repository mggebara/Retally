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
