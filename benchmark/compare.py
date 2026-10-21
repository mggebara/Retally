"""Compare two benchmark runs: ``python -m benchmark.compare baseline.json candidate.json``.

The prompt-tuning loop is: edit a prompt, sweep the dev set, and decide
keep-or-revert.  That decision needs "did candidate beat baseline?" to
be one command, not an eyeball-diff of two JSON files.  This prints:

* per-split closeness metrics for both runs, side by side
* per-entry deltas (passed counts, median rel err, and first-attempt
  passed counts when either run recorded them)
* which specific claims flipped — newly passing and newly failing —
  matched across runs by (entry_id, mode, claim description)

Rows are identified by ``(entry_id, mode)``: a seeded and an independent
result for the same paper are different measurements and are only ever
compared like-for-like (baseline seeded vs candidate seeded, etc.).
Rows from results files that predate the ``mode`` field count as seeded.

Exit code is always 0; this is a report, not a gate.  Wire it into CI
as a gate later if the numbers prove stable enough to enforce.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from statistics import median
from typing import Any

from benchmark import metrics

_MAX_FLIPS_SHOWN = 15


def compare_runs(baseline: list[dict[str, Any]], candidate: list[dict[str, Any]]) -> str:
    """Render a markdown comparison of two results.json payloads."""
    lines = ["# Benchmark run comparison", ""]
    lines.extend(_header_section(baseline, candidate))

    lines.extend(_split_section(baseline, candidate))
    lines.extend(_per_entry_section(baseline, candidate))
    lines.extend(_flips_section(baseline, candidate))

    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    if len(argv) != 2:
        print(
            "usage: python -m benchmark.compare <baseline_results.json> <candidate_results.json>",
            file=sys.stderr,
        )
        return 2

    payloads = []
    for arg in argv:
        path = Path(arg)
        try:
            payloads.append(metrics.result_rows(json.loads(path.read_text(encoding="utf-8"))))
        except (OSError, json.JSONDecodeError) as exc:
            print(f"cannot read {path}: {exc}", file=sys.stderr)
            return 2

    print(compare_runs(payloads[0], payloads[1]))
    return 0


# ---------------------------------------------------------------------------
# Sections
# ---------------------------------------------------------------------------


def _header_section(baseline: list[dict], candidate: list[dict]) -> list[str]:
    """Which reproducer(s) and mode(s) each run covers — the context for every delta below."""

    def _describe(rows: list[dict]) -> str:
        if not rows:
            return "(empty)"
        reproducers = ", ".join(metrics.reproducers_present(rows))
        modes = ", ".join(metrics.modes_present(rows))
        return f"reproducer {reproducers}; mode {modes}"

    return [f"- baseline:  {_describe(baseline)}", f"- candidate: {_describe(candidate)}", ""]


def _split_section(baseline: list[dict], candidate: list[dict]) -> list[str]:
    lines = ["## Closeness by split and mode", ""]
    base_by_group = _by_split_and_mode(baseline)
    cand_by_group = _by_split_and_mode(candidate)
    for split, mode in sorted(set(base_by_group) | set(cand_by_group)):
        lines.append(f"### {split} · {mode}")
        b = base_by_group.get((split, mode))
        c = cand_by_group.get((split, mode))
        lines.append(f"- baseline:  {metrics.format_metrics_line(b) if b else '(absent)'}")
        lines.append(f"- candidate: {metrics.format_metrics_line(c) if c else '(absent)'}")
        if b and c and b.median_rel_err is not None and c.median_rel_err is not None:
            delta = c.median_rel_err - b.median_rel_err
            arrow = "improved" if delta < 0 else ("worsened" if delta > 0 else "unchanged")
            lines.append(f"- median rel err {arrow}: {b.median_rel_err:.1%} → {c.median_rel_err:.1%}")
        lines.append("")
    return lines


def _per_entry_section(baseline: list[dict], candidate: list[dict]) -> list[str]:
    base_by_key = {_row_key(r): r for r in baseline}
    cand_by_key = {_row_key(r): r for r in candidate}
    # The first-attempt column appears only when some row recorded it, so
    # comparisons of older results files render as before.
    show_first = any(metrics.first_attempt_passed(r) is not None for r in (*baseline, *candidate))
    first_head = " First attempt (base → cand) |" if show_first else ""
    lines = [
        "## Per-entry deltas",
        "",
        "| Entry | Mode | Reproducer | Split | Passed (base → cand) |"
        f"{first_head} Median rel err (base → cand) |",
        "|---|---|---|---|---|---|" + ("---|" if show_first else ""),
    ]
    for key in sorted(set(base_by_key) | set(cand_by_key)):
        entry_id, mode = key
        b, c = base_by_key.get(key), cand_by_key.get(key)
        split = (c or b or {}).get("split", "dev")
        first_cell = f" {_first_attempt_str(b)} → {_first_attempt_str(c)} |" if show_first else ""
        lines.append(
            f"| `{entry_id}` | {mode} | {_reproducer_str(b, c)} | {split} "
            f"| {_passed_str(b)} → {_passed_str(c)} |{first_cell} "
            f"{_median_str(b)} → {_median_str(c)} |"
        )
    lines.append("")
    return lines


def _flips_section(baseline: list[dict], candidate: list[dict]) -> list[str]:
    base_passed = _passed_claims(baseline)
    cand_passed = _passed_claims(candidate)
    newly_passing = sorted(cand_passed - base_passed)
    newly_failing = sorted(base_passed - cand_passed)

    lines = ["## Claim flips", ""]
    lines.extend(_flip_block("Newly passing", newly_passing))
    lines.extend(_flip_block("Newly failing", newly_failing))
    return lines


def _flip_block(title: str, flips: list[tuple[str, str, str]]) -> list[str]:
    lines = [f"### {title}: {len(flips)}"]
    for entry_id, mode, description in flips[:_MAX_FLIPS_SHOWN]:
        lines.append(f"- `{entry_id}` ({mode}): {description}")
    if len(flips) > _MAX_FLIPS_SHOWN:
        lines.append(f"- … and {len(flips) - _MAX_FLIPS_SHOWN} more")
    lines.append("")
    return lines


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _row_key(r: dict) -> tuple[str, str]:
    """A results row's identity across runs: (entry_id, reproduction mode)."""
    return (r["entry_id"], metrics.mode_of(r))


def _by_split_and_mode(results: list[dict]) -> dict[tuple[str, str], metrics.ClosenessMetrics]:
    return {
        (split, mode): m
        for mode, rows in metrics.by_mode(results).items()
        for split, m in metrics.by_split(rows).items()
    }


def _passed_claims(results: list[dict]) -> set[tuple[str, str, str]]:
    """(entry_id, mode, claim description) triples that passed.

    Description is the join key across runs: claim order can shift when
    extraction re-runs, but a pinned/curated claim keeps its description.
    """
    return {
        (*_row_key(r), cd["description"])
        for r in results
        for cd in r.get("claim_details", [])
        if cd.get("passed")
    }


def _reproducer_str(b: dict | None, c: dict | None) -> str:
    names = [metrics.reproducer_of(r) for r in (b, c) if r is not None]
    return names[0] if len(set(names)) == 1 else " → ".join(names)


def _passed_str(r: dict | None) -> str:
    if r is None:
        return "—"
    details = r.get("claim_details", [])
    if not details:
        return f"{r.get('n_claims_with_paper_match', 0)}/?"
    return f"{sum(1 for cd in details if cd.get('passed'))}/{len(details)}"


def _first_attempt_str(r: dict | None) -> str:
    """First-attempt passed/total for a row; ``—`` when absent or not recorded."""
    first = metrics.first_attempt_passed(r) if r is not None else None
    if r is None or first is None:
        return "—"
    details = r.get("claim_details", [])
    return f"{first}/{len(details)}" if details else f"{first}/?"


def _median_str(r: dict | None) -> str:
    if r is None:
        return "—"
    errs = [cd["rel_err"] for cd in r.get("claim_details", []) if cd.get("rel_err") is not None]
    return f"{median(errs):.1%}" if errs else "—"


if __name__ == "__main__":
    raise SystemExit(main())
