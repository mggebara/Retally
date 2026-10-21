"""Re-score a results file with the current comparator.

``uv run python -m benchmark.rescore <results.json> [--catalog DIR] [--write OUT.json]``

Every committed row carries, per claim, the pinned ``claimed`` value and
the ``reproduced`` value the reproducer printed.  That is all the
comparator needs, so a change to the scoring rule (e.g. the
printed-precision tolerance floor) can be applied to existing runs
without re-running anything: this module re-scores every claim of every
row with today's ``ResultComparator`` in the row's own mode, against the
claim's current catalog metadata (claim type, standard error, printed
precision), and prints per-row before/after pass counts and each claim
whose verdict flipped.

Read-only by default.  ``--write OUT.json`` writes a copy of the input
with each re-scored row's ``claim_details`` (``tolerance``,
``tolerance_source``, ``passed``), ``n_claims_with_paper_match``,
``agrees_with_paper`` and, when the row's claims line up with the
catalog's, the I4R agreement fields updated.  The first-attempt and
first-scored fields cannot be re-scored from a results file (only the
final reproduced values are stored) and are left as recorded.

Catalog claims are matched to a row's claim details by position, falling
back to the description; a row whose entry is no longer in the catalog,
or a claim with no catalog counterpart, is reported and left alone.  A
claim whose catalog value differs from the recorded ``claimed`` is
re-scored against the catalog value and flagged, so a flip caused by a
catalog edit is distinguishable from one caused by the rule.  No LLM
call is made.
"""

from __future__ import annotations

import argparse
import copy
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from benchmark import schema as bschema
from benchmark.metrics import reproducer_of, result_rows


@dataclass
class ClaimFlip:
    description: str
    claimed: float
    reproduced: float | None
    before: bool
    after: bool
    tolerance_before: float | None
    tolerance_after: float
    tolerance_source: str
    note: str = ""


@dataclass
class RowRescore:
    entry_id: str
    mode: str
    reproducer: str
    n_claims: int
    passed_before: int
    passed_after: int
    n_printed_precision: int = 0
    """Claims whose band is now set by the printed-precision floor."""
    flips: list[ClaimFlip] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)
    rescored: bool = True


def rescore_rows(
    rows: list[dict[str, Any]], catalog: list[bschema.BenchmarkEntry], comparator: Any = None
) -> tuple[list[RowRescore], list[dict[str, Any]]]:
    """Re-score ``rows``; return the per-row summaries and updated copies of the rows."""
    from retally.validation.comparator import ResultComparator

    comparator = comparator or ResultComparator()
    by_id = {e.id: e for e in catalog}
    summaries: list[RowRescore] = []
    updated: list[dict[str, Any]] = []
    for row in rows:
        summary, new_row = _rescore_row(row, by_id.get(str(row.get("entry_id"))), comparator)
        summaries.append(summary)
        updated.append(new_row)
    return summaries, updated


def _rescore_row(
    row: dict[str, Any], entry: bschema.BenchmarkEntry | None, comparator: Any
) -> tuple[RowRescore, dict[str, Any]]:
    from benchmark.runner import _claim_detail, _claims_override_for, _score_against_i4r
    from retally.models import ReproductionMode

    mode = str(row.get("mode") or "seeded")
    details = [cd for cd in row.get("claim_details") or [] if isinstance(cd, dict)]
    summary = RowRescore(
        entry_id=str(row.get("entry_id")),
        mode=mode,
        reproducer=reproducer_of(row),
        n_claims=len(details),
        passed_before=sum(1 for cd in details if cd.get("passed")),
        passed_after=sum(1 for cd in details if cd.get("passed")),
    )
    new_row = copy.deepcopy(row)
    if not details:
        summary.rescored = False
        summary.notes.append("no claim details (skipped or errored row)")
        return summary, new_row
    if entry is None:
        summary.rescored = False
        summary.notes.append("entry not in the catalog; left as recorded")
        return summary, new_row
    claims = _claims_override_for(entry) or []

    by_description = {c.description: c for c in claims}
    aligned = len(claims) == len(details)
    new_details: list[dict[str, Any]] = []
    results = []
    for i, cd in enumerate(details):
        description = str(cd.get("description"))
        claim = claims[i] if i < len(claims) and claims[i].description == description else None
        if claim is None:
            aligned = False
            claim = by_description.get(description)
        if claim is None:
            summary.notes.append(f"{description}: no catalog claim; left as recorded")
            new_details.append(dict(cd))
            continue
        reproduced = cd.get("reproduced")
        cr = comparator.compare(
            claim, None if reproduced is None else float(reproduced), mode=ReproductionMode(mode)
        )
        results.append(cr)
        fresh = _claim_detail(cr)
        merged = dict(cd)
        merged.update(
            claimed=fresh.claimed,
            tolerance=fresh.tolerance,
            tolerance_source=fresh.tolerance_source,
            rel_err=fresh.rel_err,
            passed=fresh.passed,
        )
        new_details.append(merged)
        if fresh.tolerance_source == "printed_precision":
            summary.n_printed_precision += 1
        note = ""
        if cd.get("claimed") is not None and float(cd["claimed"]) != float(claim.value):
            note = f"catalog value {claim.value:g} differs from recorded claimed {float(cd['claimed']):g}"
        if bool(cd.get("passed")) != fresh.passed:
            summary.flips.append(
                ClaimFlip(
                    description=description,
                    claimed=float(claim.value),
                    reproduced=None if reproduced is None else float(reproduced),
                    before=bool(cd.get("passed")),
                    after=fresh.passed,
                    tolerance_before=cd.get("tolerance"),
                    tolerance_after=fresh.tolerance,
                    tolerance_source=str(fresh.tolerance_source),
                    note=note,
                )
            )
        elif note:
            summary.notes.append(f"{description}: {note}")

    n_passed = sum(1 for cd in new_details if cd.get("passed"))
    summary.passed_after = n_passed
    new_row["claim_details"] = new_details
    new_row["n_claims_with_paper_match"] = n_passed
    new_row["agrees_with_paper"] = bool(new_details) and n_passed == len(new_details)
    if aligned and len(results) == len(details):
        n_i4r, agrees_i4r = _score_against_i4r(results, entry)
        new_row["n_claims_with_i4r_match"] = n_i4r
        new_row["agrees_with_i4r"] = agrees_i4r
    return summary, new_row


def render(summaries: list[RowRescore]) -> str:
    lines: list[str] = []
    total_flips = 0
    for s in summaries:
        head = f"{s.entry_id} [{s.mode}, {s.reproducer}]"
        if not s.rescored:
            lines.append(f"{head}: not re-scored ({'; '.join(s.notes)})")
            continue
        lines.append(
            f"{head}: {s.passed_before}/{s.n_claims} -> {s.passed_after}/{s.n_claims} passed"
            f" ({len(s.flips)} flipped; printed-precision floor binding on {s.n_printed_precision})"
        )
        for f in s.flips:
            total_flips += 1
            arrow = "PASS -> FAIL" if f.before else "FAIL -> PASS"
            tol_before = "n/a" if f.tolerance_before is None else f"{float(f.tolerance_before):.4g}"
            line = (
                f"  {arrow}  {f.description}: claimed {f.claimed:g}, reproduced {f.reproduced}, "
                f"tolerance {tol_before} -> {f.tolerance_after:.4g} ({f.tolerance_source})"
            )
            if f.note:
                line += f"  [{f.note}]"
            lines.append(line)
        for note in s.notes:
            lines.append(f"  note: {note}")
    lines.append("")
    lines.append(f"{total_flips} claim verdict(s) flipped across {len(summaries)} row(s).")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m benchmark.rescore", description=__doc__.splitlines()[0])
    parser.add_argument("results", type=Path, help="a results.json written by benchmark.runner")
    parser.add_argument(
        "--catalog", type=Path, default=None, help="catalog directory (default: benchmark/papers)"
    )
    parser.add_argument(
        "--write",
        type=Path,
        default=None,
        metavar="OUT.json",
        help="write the re-scored results here (the input file is never modified)",
    )
    args = parser.parse_args(argv)
    try:
        payload = json.loads(args.results.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"cannot read {args.results}: {exc}", file=sys.stderr)
        return 2

    from benchmark.runner import CATALOG_DIR

    catalog = bschema.load_catalog(args.catalog or CATALOG_DIR)
    summaries, updated = rescore_rows(result_rows(payload), catalog)
    print(render(summaries))

    if args.write is not None:
        if args.write.resolve() == args.results.resolve():
            print("refusing to overwrite the input file; pick another --write path", file=sys.stderr)
            return 2
        out: Any
        if isinstance(payload, dict):
            out = dict(payload)
            out["results"] = updated
        else:
            out = updated
        args.write.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {args.write}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
