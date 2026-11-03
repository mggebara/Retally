"""Re-score stored results files offline, with no LLM call.

``uv run python -m benchmark.rescore FILES... [--dry-run]``

Every committed row carries, per claim, the pinned ``claimed`` value and
the ``reproduced`` value the reproducer printed.  That is all the
comparator needs, so a change to the scoring rule can be applied to
existing runs without re-running anything.

Default: the ``count-5pct`` policy (2026-11-03).  Claims the catalog now
types ``count`` (numbers of observations, clusters, respondents, ...)
are held to 5 % instead of the 1 % of ``other``.  For each file, each
row, each claim detail whose catalog claim (matched by ``entry_id`` +
description) is a ``count``, the comparator re-scores the stored
``reproduced`` value in the row's mode (probe rows as blind), and the
claim's ``claim_type``, ``tolerance``, ``tolerance_source``, ``rel_err``
and ``passed`` are updated.  On rows where a verdict flipped,
``n_claims_with_paper_match`` and ``agrees_with_paper`` are recomputed;
the I4R fields move by the difference the new band makes on the stored
values.  ``n_claims_with_paper_match_first_scored`` / ``passed_first_scored``
(and the first-attempt fields) are left as recorded: a row stores only
the final reproduced value, not the first scored one, so they cannot be
re-scored (the band only widened, so a recorded first-scored pass stays
a pass; a recorded first-scored miss may undercount).  Rows with empty
``claim_details`` and every non-``count`` claim are untouched.  Files are
rewritten in place, formatted as before, with a top-level
``"rescored": {"policy": "count-5pct", "date": "2026-11-03", "flipped": N}``
(a bare-list file, written before run-level cost accounting, keeps its
shape and carries no marker).
Idempotent: a second run changes nothing.  ``--dry-run`` prints the
flips without writing.

``--all-claims RESULTS.json [--write OUT.json]``: the original mode.
Re-scores every claim of every row with today's ``ResultComparator``
against the claim's current catalog metadata (claim type, standard
error, printed precision), and prints per-row before/after pass counts
and each flipped claim.  Read-only unless ``--write`` writes a copy (the
input file is never modified).  Catalog claims are matched to a row's
claim details by position, falling back to the description; a claim
whose catalog value differs from the recorded ``claimed`` is re-scored
against the catalog value and flagged.
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


# ---------------------------------------------------------------------------
# Policy rescore: the COUNT claim type at 5 % (2026-11-03), in place
# ---------------------------------------------------------------------------

COUNT_POLICY = "count-5pct"
COUNT_POLICY_DATE = "2026-11-03"


@dataclass
class CountFlip:
    entry_id: str
    mode: str
    reproducer: str
    description: str
    claimed: float
    reproduced: float | None
    rel_err: float | None
    before: bool
    after: bool


@dataclass
class CountRowSummary:
    entry_id: str
    mode: str
    reproducer: str
    n_claims: int
    passed_before: int
    passed_after: int
    n_count_claims: int = 0
    flips: list[CountFlip] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)


def _comparison_mode(mode: str) -> Any:
    """The comparator mode a row was scored in (probe rows are scored as blind)."""
    from retally.models import ReproductionMode

    if mode == "probe":
        return ReproductionMode.BLIND
    return ReproductionMode(mode or "seeded")


def rescore_counts_rows(
    rows: list[dict[str, Any]], catalog: list[bschema.BenchmarkEntry], comparator: Any = None
) -> tuple[list[CountRowSummary], list[dict[str, Any]]]:
    """Re-score only the claims the catalog now types ``count``; return summaries and updated rows.

    Every other claim, and every row without a catalog ``count`` claim, is
    returned unchanged.  Matching is by ``entry_id`` + claim description.
    The first-attempt / first-scored fields are left as recorded: a row
    stores only the final ``reproduced`` value, not the first scored one.
    """
    from retally.validation.comparator import ResultComparator

    comparator = comparator or ResultComparator()
    by_id = {e.id: e for e in catalog}
    summaries: list[CountRowSummary] = []
    updated: list[dict[str, Any]] = []
    for row in rows:
        summary, new_row = _rescore_counts_row(row, by_id.get(str(row.get("entry_id"))), comparator)
        summaries.append(summary)
        updated.append(new_row)
    return summaries, updated


def _rescore_counts_row(
    row: dict[str, Any], entry: bschema.BenchmarkEntry | None, comparator: Any
) -> tuple[CountRowSummary, dict[str, Any]]:
    from benchmark.runner import _claim_detail, _claims_override_for, _score_against_i4r
    from retally.models import ClaimType, ClaimValidationResult

    mode = str(row.get("mode") or "seeded")
    details = row.get("claim_details") or []
    n_passed = sum(1 for cd in details if isinstance(cd, dict) and cd.get("passed"))
    summary = CountRowSummary(
        entry_id=str(row.get("entry_id")),
        mode=mode,
        reproducer=reproducer_of(row),
        n_claims=len(details),
        passed_before=n_passed,
        passed_after=n_passed,
    )
    if not details or entry is None:
        if details and entry is None:
            summary.notes.append("entry not in the catalog; left as recorded")
        return summary, row
    claims = _claims_override_for(entry) or []
    by_description = {c.description: c for c in claims}

    new_row = copy.deepcopy(row)
    new_details = new_row["claim_details"]
    old_tolerances: list[float | None] = []
    changed = False
    for cd in new_details:
        old_tolerances.append(cd.get("tolerance") if isinstance(cd, dict) else None)
        if not isinstance(cd, dict):
            continue
        claim = by_description.get(str(cd.get("description")))
        if claim is None or claim.claim_type is not ClaimType.COUNT:
            continue
        summary.n_count_claims += 1
        reproduced = cd.get("reproduced")
        cr = comparator.compare(
            claim, None if reproduced is None else float(reproduced), mode=_comparison_mode(mode)
        )
        fresh = _claim_detail(cr)
        if cd.get("claimed") is not None and float(cd["claimed"]) != float(claim.value):
            summary.notes.append(
                f"{claim.description}: catalog value {claim.value:g} differs from recorded "
                f"claimed {float(cd['claimed']):g}; scored against the catalog value"
            )
        before = bool(cd.get("passed"))
        update = {
            "claim_type": "count",
            "tolerance": fresh.tolerance,
            "tolerance_source": fresh.tolerance_source,
            "rel_err": fresh.rel_err,
            "passed": fresh.passed,
        }
        if "within_tolerance" in cd:  # probe rows mirror ``passed`` here
            update["within_tolerance"] = fresh.passed
        if any(cd.get(k) != v for k, v in update.items()):
            changed = True
        cd.update(update)
        if before != fresh.passed:
            summary.flips.append(
                CountFlip(
                    entry_id=summary.entry_id,
                    mode=mode,
                    reproducer=summary.reproducer,
                    description=claim.description,
                    claimed=float(claim.value),
                    reproduced=None if reproduced is None else float(reproduced),
                    rel_err=fresh.rel_err,
                    before=before,
                    after=fresh.passed,
                )
            )
    if not changed:
        return summary, row

    if summary.flips:
        n_after = sum(1 for cd in new_details if isinstance(cd, dict) and cd.get("passed"))
        summary.passed_after = n_after
        new_row["n_claims_with_paper_match"] = n_after
        new_row["agrees_with_paper"] = bool(new_details) and n_after == len(new_details)

    # The I4R comparison reuses each claim's tolerance.  Re-run it on the
    # stored values with the old and the new tolerances, and apply the
    # difference, so the I4R fields move only by what the new band changed.
    descriptions = [str(cd.get("description")) for cd in new_details if isinstance(cd, dict)]
    if (
        new_row.get("n_claims_with_i4r_match") is not None
        and descriptions == [c.description for c in claims]
        and entry.i4r_replicator_findings
    ):

        def _results(tolerances: list[float | None]) -> list[Any]:
            return [
                ClaimValidationResult(
                    claim=c,
                    reproduced_value=None if cd.get("reproduced") is None else float(cd["reproduced"]),
                    tolerance=float(t) if t is not None else 0.01,
                )
                for c, cd, t in zip(claims, new_details, tolerances, strict=True)
            ]

        n_old, _ = _score_against_i4r(_results(old_tolerances), entry)
        n_new, agrees_new = _score_against_i4r(_results([cd.get("tolerance") for cd in new_details]), entry)
        if n_new != n_old:
            new_row["n_claims_with_i4r_match"] = int(new_row["n_claims_with_i4r_match"]) + n_new - n_old
            new_row["agrees_with_i4r"] = agrees_new
            summary.notes.append(f"I4R matches {n_old} -> {n_new} on the stored values")
    return summary, new_row


def _dump_like(payload: Any, original: str) -> str:
    """Serialise ``payload`` the way ``original`` was written (indent 2; ASCII escapes; final newline)."""
    for ensure_ascii in (True, False):
        text = json.dumps(json.loads(original), indent=2, ensure_ascii=ensure_ascii)
        for suffix in ("\n", ""):
            if text + suffix == original:
                return json.dumps(payload, indent=2, ensure_ascii=ensure_ascii) + suffix
    return json.dumps(payload, indent=2) + "\n"


def rescore_counts_file(
    path: Path, catalog: list[bschema.BenchmarkEntry], *, dry_run: bool = False
) -> tuple[list[CountRowSummary], bool]:
    """Apply the count policy to one results file in place; return the summaries and whether it changed.

    A bare-list results file (written before run-level cost accounting)
    keeps its list shape, which has nowhere to hold the ``rescored``
    marker; it is re-scored all the same.
    """
    original = path.read_text(encoding="utf-8")
    payload = json.loads(original)
    summaries, updated = rescore_counts_rows(result_rows(payload), catalog)
    changed = updated != result_rows(payload)
    n_flips = sum(len(s.flips) for s in summaries)
    if not any(s.n_count_claims for s in summaries):
        return summaries, False
    if dry_run:
        return summaries, changed
    if isinstance(payload, dict):
        marker = payload.get("rescored")
        if not changed and isinstance(marker, dict) and marker.get("policy") == COUNT_POLICY:
            return summaries, False
        prior = (
            marker.get("flipped", 0)
            if isinstance(marker, dict) and marker.get("policy") == COUNT_POLICY
            else 0
        )
        out = dict(payload)
        out["results"] = updated
        out["rescored"] = {"policy": COUNT_POLICY, "date": COUNT_POLICY_DATE, "flipped": prior + n_flips}
    else:
        # A bare-list file (written before run-level cost accounting) keeps
        # its shape -- readers unpack it as a list -- so it carries no marker.
        if not changed:
            return summaries, False
        out = updated
    text = _dump_like(out, original)
    if text != original:
        path.write_text(text, encoding="utf-8")
        return summaries, True
    return summaries, False


def render_counts(path: Path, summaries: list[CountRowSummary], changed: bool) -> str:
    lines = [f"{path}: {'re-scored' if changed else 'unchanged'}"]
    for s in summaries:
        if not s.n_count_claims and not s.notes:
            continue
        lines.append(
            f"  {s.entry_id} [{s.mode}, {s.reproducer}]: {s.passed_before}/{s.n_claims} -> "
            f"{s.passed_after}/{s.n_claims} passed "
            f"({s.n_count_claims} count claim(s), {len(s.flips)} flipped)"
        )
        for f in s.flips:
            arrow = "PASS -> FAIL" if f.before else "FAIL -> PASS"
            rel = "n/a" if f.rel_err is None else f"{f.rel_err:.4f}"
            lines.append(
                f"    {arrow}  {f.description}: claimed {f.claimed:g}, "
                f"reproduced {f.reproduced}, rel_err {rel}"
            )
        for note in s.notes:
            lines.append(f"    note: {note}")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m benchmark.rescore", description=__doc__.splitlines()[0])
    parser.add_argument("results", type=Path, nargs="+", help="results files written by benchmark.runner")
    parser.add_argument(
        "--catalog", type=Path, default=None, help="catalog directory (default: benchmark/papers)"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="count policy: print what would change, write nothing"
    )
    parser.add_argument(
        "--all-claims",
        action="store_true",
        help="re-score every claim with today's comparator (read-only unless --write; one file)",
    )
    parser.add_argument(
        "--write",
        type=Path,
        default=None,
        metavar="OUT.json",
        help="with --all-claims: write the re-scored results here (the input file is never modified)",
    )
    args = parser.parse_args(argv)

    from benchmark.runner import CATALOG_DIR

    catalog = bschema.load_catalog(args.catalog or CATALOG_DIR)

    if not args.all_claims:
        if args.write is not None:
            print("--write goes with --all-claims; the count policy writes in place", file=sys.stderr)
            return 2
        total = 0
        for path in args.results:
            try:
                summaries, changed = rescore_counts_file(path, catalog, dry_run=args.dry_run)
            except (OSError, json.JSONDecodeError) as exc:
                print(f"cannot read {path}: {exc}", file=sys.stderr)
                return 2
            total += sum(len(s.flips) for s in summaries)
            print(render_counts(path, summaries, changed))
        verb = "would flip" if args.dry_run else "flipped"
        print(f"\n{total} count claim verdict(s) {verb} across {len(args.results)} file(s).")
        return 0

    if len(args.results) != 1:
        print("--all-claims takes one results file", file=sys.stderr)
        return 2
    results_path = args.results[0]
    try:
        payload = json.loads(results_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"cannot read {results_path}: {exc}", file=sys.stderr)
        return 2

    summaries, updated = rescore_rows(result_rows(payload), catalog)
    print(render(summaries))

    if args.write is not None:
        if args.write.resolve() == results_path.resolve():
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
