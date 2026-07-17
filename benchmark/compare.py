"""Compare two benchmark runs: ``python -m benchmark.compare baseline.json candidate.json``.

The prompt-tuning loop is: edit a prompt, sweep the dev set, and decide
keep-or-revert.  That decision needs "did candidate beat baseline?" to
be one command, not an eyeball-diff of two JSON files.  This prints:

* per-split closeness metrics for both runs, side by side
* per-entry deltas (passed counts, median rel err)
* which specific claims flipped — newly passing and newly failing —
  matched across runs by (entry_id, claim description)

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
            payloads.append(json.loads(path.read_text(encoding="utf-8")))
        except (OSError, json.JSONDecodeError) as exc:
            print(f"cannot read {path}: {exc}", file=sys.stderr)
            return 2

    print(compare_runs(payloads[0], payloads[1]))
    return 0


# ---------------------------------------------------------------------------
# Sections
# ---------------------------------------------------------------------------


def _split_section(baseline: list[dict], candidate: list[dict]) -> list[str]:
    lines = ["## Closeness by split", ""]
    base_by_split = metrics.by_split(baseline)
    cand_by_split = metrics.by_split(candidate)
    for split in sorted(set(base_by_split) | set(cand_by_split)):
        lines.append(f"### {split}")
        b = base_by_split.get(split)
        c = cand_by_split.get(split)
        lines.append(f"- baseline:  {metrics.format_metrics_line(b) if b else '(absent)'}")
        lines.append(f"- candidate: {metrics.format_metrics_line(c) if c else '(absent)'}")
        if b and c and b.median_rel_err is not None and c.median_rel_err is not None:
            delta = c.median_rel_err - b.median_rel_err
            arrow = "improved" if delta < 0 else ("worsened" if delta > 0 else "unchanged")
            lines.append(f"- median rel err {arrow}: {b.median_rel_err:.1%} → {c.median_rel_err:.1%}")
        lines.append("")
    return lines


def _per_entry_section(baseline: list[dict], candidate: list[dict]) -> list[str]:
    base_by_id = {r["entry_id"]: r for r in baseline}
    cand_by_id = {r["entry_id"]: r for r in candidate}
    lines = [
        "## Per-entry deltas",
        "",
        "| Entry | Split | Passed (base → cand) | Median rel err (base → cand) |",
        "|---|---|---|---|",
    ]
    for entry_id in sorted(set(base_by_id) | set(cand_by_id)):
        b, c = base_by_id.get(entry_id), cand_by_id.get(entry_id)
        split = (c or b or {}).get("split", "dev")
        lines.append(
            f"| `{entry_id}` | {split} "
            f"| {_passed_str(b)} → {_passed_str(c)} "
            f"| {_median_str(b)} → {_median_str(c)} |"
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


def _flip_block(title: str, flips: list[tuple[str, str]]) -> list[str]:
    lines = [f"### {title}: {len(flips)}"]
    for entry_id, description in flips[:_MAX_FLIPS_SHOWN]:
        lines.append(f"- `{entry_id}`: {description}")
    if len(flips) > _MAX_FLIPS_SHOWN:
        lines.append(f"- … and {len(flips) - _MAX_FLIPS_SHOWN} more")
    lines.append("")
    return lines


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _passed_claims(results: list[dict]) -> set[tuple[str, str]]:
    """(entry_id, claim description) pairs that passed.

    Description is the join key across runs: claim order can shift when
    extraction re-runs, but a pinned/curated claim keeps its description.
    """
    return {
        (r["entry_id"], cd["description"])
        for r in results
        for cd in r.get("claim_details", [])
        if cd.get("passed")
    }


def _passed_str(r: dict | None) -> str:
    if r is None:
        return "—"
    details = r.get("claim_details", [])
    if not details:
        return f"{r.get('n_claims_with_paper_match', 0)}/?"
    return f"{sum(1 for cd in details if cd.get('passed'))}/{len(details)}"


def _median_str(r: dict | None) -> str:
    if r is None:
        return "—"
    errs = [cd["rel_err"] for cd in r.get("claim_details", []) if cd.get("rel_err") is not None]
    return f"{median(errs):.1%}" if errs else "—"


if __name__ == "__main__":
    raise SystemExit(main())
