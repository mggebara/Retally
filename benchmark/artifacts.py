"""Inspect the run artifacts a benchmark results file points at.

``uv run python -m benchmark.artifacts benchmark/results/results.json [--entry ID] [--mode MODE]``

For each row: its ``artifacts_dir``, the data files the final script
reads, the ``RESULT:`` lines of the final stdout, and the per-claim
pass/fail.  The data-file list is a grep, not a parse — enough to spot
"read the wrong file" at a glance.

``--rescore`` instead re-scores each row from its artifacts on disk and
prints one table: final, first-attempt and first-scored pass counts and
the error / claim refinement split.  It is how rows written before
first-scored scoring existed get that number; the results file is only
read, never written.  See :func:`rescore_row` for what it assumes.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from benchmark.metrics import (
    first_attempt_passed,
    first_scored_passed,
    refinements_of,
    result_rows,
)

REPO_ROOT = Path(__file__).resolve().parent.parent

_READ_CALL = re.compile(
    r"\b(?:read_dta|read\.dta|read_csv|read\.csv|read_excel|readRDS|read_rds|load|fread"
    r"|pd\.read_\w+|haven::\w+|read_sav|read_parquet)\s*\(\s*([^)\n]*)"
)
_DATA_LITERAL = re.compile(
    r"""["']([^"'\n]*\.(?:dta|csv|rds|rdata|sav|xlsx?|parquet|tsv))["']""", re.IGNORECASE
)
_RESULT_LINE = re.compile(r"^\s*RESULT:.*$", re.MULTILINE)


def data_files_read(script: str) -> list[str]:
    """Data files a script appears to read: file-name literals plus the first argument of read calls."""
    found: list[str] = []
    for match in _DATA_LITERAL.finditer(script):
        found.append(match.group(1))
    for match in _READ_CALL.finditer(script):
        # A call whose arguments hold a file-name literal is already listed;
        # otherwise record the first argument (usually a path variable).
        if _DATA_LITERAL.search(match.group(1)):
            continue
        arg = match.group(1).split(",")[0].strip()
        if arg:
            found.append(arg)
    return list(dict.fromkeys(found))


def _final_script(artifacts: Path) -> tuple[str, str] | None:
    for name in ("script.R", "script.py"):
        path = artifacts / name
        if path.is_file():
            return name, path.read_text(encoding="utf-8", errors="replace")
    return None


def describe_row(row: dict[str, Any], *, repo_root: Path = REPO_ROOT) -> str:
    """A plain-text block summarising one result row and its artifacts."""
    head = f"== {row.get('entry_id')} [{row.get('mode', 'seeded')} / {row.get('reproducer', 'pipeline')}]"
    if row.get("cached"):
        head += " (cached)"
    lines = [head]
    if row.get("skipped"):
        lines.append(f"  skipped: {row.get('skip_reason')}")
    if row.get("error"):
        lines.append(f"  error: {row['error']}")
    rel = row.get("artifacts_dir")
    if not rel:
        lines.append("  artifacts: none recorded")
    else:
        art = Path(rel) if Path(rel).is_absolute() else repo_root / rel
        lines.append(f"  artifacts: {rel}" + ("" if art.is_dir() else "  (missing on disk)"))
        script = _final_script(art) if art.is_dir() else None
        if script is not None:
            files = data_files_read(script[1])
            lines.append(f"  {script[0]} reads: " + (", ".join(files) if files else "(no data files found)"))
        attempts = sorted(p.name for p in art.glob("attempt-*") if p.is_dir()) if art.is_dir() else []
        if attempts:
            lines.append(f"  earlier attempts: {len(attempts)}")
        stdout = art / "stdout.txt"
        if stdout.is_file():
            results = _RESULT_LINE.findall(stdout.read_text(encoding="utf-8", errors="replace"))
            lines.append(f"  RESULT lines ({len(results)}):")
            lines.extend(f"    {r.strip()}" for r in results)
    n_ref = refinements_of(row)
    n_err, n_claim = row.get("n_error_refinements"), row.get("n_claim_refinements")
    if n_ref is not None or (isinstance(n_err, int) and isinstance(n_claim, int)):
        n_exec = row.get("n_executions")
        split = (
            f"{n_err} error + {n_claim} claim" if isinstance(n_err, int) and isinstance(n_claim, int) else ""
        )
        total = str(n_ref) if n_ref is not None else ""
        lines.append(
            "  refinements: "
            + (f"{total} ({split})" if total and split else total or split)
            + (f" ({n_exec} executions)" if isinstance(n_exec, int) else "")
        )
    details = row.get("claim_details") or []
    if details:
        n_pass = sum(1 for d in details if d.get("passed"))
        first = first_attempt_passed(row)
        scored = first_scored_passed(row)
        before = []
        if scored is not None:
            index = row.get("first_scored_attempt_index")
            at = f" at execution {index + 1}" if isinstance(index, int) else ""
            before.append(f"first scored {scored}/{len(details)}{at}")
        if first is not None:
            before.append(f"first attempt {first}/{len(details)}")
        before_str = f" ({', '.join(before)})" if before else ""
        lines.append(f"  claims: {n_pass}/{len(details)} pass{before_str}")
        for d in details:
            reproduced = d.get("reproduced")
            rel_err = d.get("rel_err")
            err = f"rel_err {rel_err:.3g}" if isinstance(rel_err, (int, float)) else "unmatched"
            first_tag = ""
            if isinstance(d.get("passed_first_scored"), bool):
                first_tag += f" [first scored {'PASS' if d['passed_first_scored'] else 'FAIL'}]"
            if isinstance(d.get("passed_first_attempt"), bool):
                first_tag += f" [first attempt {'PASS' if d['passed_first_attempt'] else 'FAIL'}]"
            lines.append(
                f"    [{'PASS' if d.get('passed') else 'FAIL'}] {d.get('description')}: "
                f"claimed {d.get('claimed')}, reproduced {reproduced} ({err}){first_tag}"
            )
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# --rescore: first-scored numbers recomputed from artifacts on disk
# ---------------------------------------------------------------------------

_ATTEMPT_DIR = re.compile(r"^attempt-(\d+)$")
# One line of the pipeline's claim-gap feedback (``_claim_gap_feedback``):
# ``<description>: reproduced <value>, claimed <value> (tolerance <tol>)``.
_CLAIM_FEEDBACK_LINE = re.compile(r": reproduced \S+, claimed \S+")


def classify_feedback(text: str) -> str:
    """``"claim"`` for claim-gap feedback, ``"error"`` for anything else non-empty, ``""`` for none.

    Claim feedback is the pipeline's "<claim>: reproduced X, claimed Y"
    list; execution-error feedback is the sandbox's stderr or "No RESULT:
    lines found in output".
    """
    if not text.strip():
        return ""
    if "reproduced" in text and "claimed" in text and _CLAIM_FEEDBACK_LINE.search(text):
        return "claim"
    return "error"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace") if path.is_file() else ""


def attempts_from_artifacts(art: Path) -> tuple[list[str], list[str], int]:
    """``(stdout of every execution, refinement kind after each, final run's index)`` from an artifacts dir.

    Order: ``attempt-1``, ``attempt-2``, … (numerically), then the final
    ``stdout.txt``.  The artifacts do not record ``final_execution_index``,
    so the final run is assumed last, with one exception the artifacts do
    show: the pipeline writes ``feedback.txt`` for every superseded run
    except a broken claim refinement it reverted (it then stops and keeps
    the run before).  So when the *last* attempt has no ``feedback.txt``,
    the final run is placed just before it, and its kind is ``"claim"``
    (the refinement that broke the script followed it).  Otherwise the
    final run's kind is ``""``.
    """
    numbered = []
    for p in art.iterdir():
        m = _ATTEMPT_DIR.match(p.name)
        if m and p.is_dir():
            numbered.append((int(m.group(1)), p))
    outputs: list[str] = []
    kinds: list[str] = []
    for _, d in sorted(numbered):
        outputs.append(_read(d / "stdout.txt"))
        kinds.append(classify_feedback(_read(d / "feedback.txt")))
    final = _read(art / "stdout.txt")
    if kinds and kinds[-1] == "":
        index = len(outputs) - 1
        outputs.insert(index, final)
        kinds.insert(index, "claim")
    else:
        index = len(outputs)
        outputs.append(final)
        kinds.append("")
    return outputs, kinds, index


def rescore_row(row: dict[str, Any], entry: Any, art: Path) -> dict[str, Any]:
    """Re-score one row from its artifacts with the catalog's claims and the row's mode tolerance.

    Rebuilds a ``Reproduction`` from :func:`attempts_from_artifacts` and
    runs it through ``benchmark.runner.score_reproduction`` — the same
    code path a live run uses — so "final", "first attempt" and "first
    scored" match what the runner would have recorded.  The refinement
    counts come from the attempts' ``feedback.txt`` (plus the inferred
    claim refinement after a reverted final run) and are lower bounds: a
    claim refinement whose code came back unchanged leaves no attempt
    directory.
    """
    from benchmark.reproducer import Reproduction
    from benchmark.runner import _parse_result_lines, score_reproduction

    outputs, kinds, final_index = attempts_from_artifacts(art)
    final_stdout = outputs[final_index]
    reproduction = Reproduction(
        outputs=_parse_result_lines(final_stdout),
        stdout=final_stdout,
        attempt_outputs=outputs,
        attempt_kinds=kinds,
        n_executions=len(outputs),
        n_error_refinements=kinds.count("error"),
        n_claim_refinements=kinds.count("claim"),
    )
    mode = str(row.get("mode", "seeded"))
    scored = score_reproduction(entry, reproduction, mode=mode)
    script = _final_script(art)
    return {
        "entry_id": row.get("entry_id"),
        "mode": mode,
        "files": data_files_read(script[1]) if script else [],
        "n_claims": len(scored.claim_details),
        "final": scored.n_claims_with_paper_match,
        "first_attempt": scored.n_claims_with_paper_match_first_attempt,
        "first_scored": scored.n_claims_with_paper_match_first_scored,
        "first_scored_index": scored.first_scored_attempt_index,
        "final_index": final_index,
        "n_executions": len(outputs),
        "n_error_refinements": reproduction.n_error_refinements,
        "n_claim_refinements": reproduction.n_claim_refinements,
    }


def rescore_table(rows: list[dict[str, Any]], catalog: list[Any], *, repo_root: Path = REPO_ROOT) -> str:
    """Markdown table of :func:`rescore_row` per row with artifacts on disk; the rest listed below it."""
    entries = {e.id: e for e in catalog}
    lines = [
        "| Entry | Mode | File | Final | First attempt | First scored | Error / claim refinements |",
        "|---|---|---|---|---|---|---|",
    ]
    skipped: list[str] = []
    for row in rows:
        label = f"{row.get('entry_id')} [{row.get('mode', 'seeded')}]"
        rel = row.get("artifacts_dir")
        art = (Path(rel) if Path(rel).is_absolute() else repo_root / rel) if rel else None
        if art is None or not art.is_dir():
            skipped.append(f"{label}: no artifacts on disk")
            continue
        entry = entries.get(row.get("entry_id"))
        if entry is None:
            skipped.append(f"{label}: not in the catalog")
            continue
        if not entry.original_claims:
            skipped.append(f"{label}: no pinned claims to score against")
            continue
        r = rescore_row(row, entry, art)
        n = r["n_claims"]
        at = f" (execution {r['first_scored_index'] + 1} of {r['n_executions']})"
        reverted = " †" if r["final_index"] != r["n_executions"] - 1 else ""
        lines.append(
            f"| `{r['entry_id']}` | {r['mode']} | {', '.join(r['files']) or '—'} "
            f"| {r['final']}/{n}{reverted} | {r['first_attempt']}/{n} | {r['first_scored']}/{n}{at} "
            f"| {r['n_error_refinements']} / {r['n_claim_refinements']} |"
        )
    if len(lines) == 2:
        lines = ["_No row has artifacts on disk to rescore._"]
    if skipped:
        lines.extend(["", "Not rescored:"])
        lines.extend(f"- {s}" for s in skipped)
    lines.extend(
        [
            "",
            "Executions are ordered attempt-1, attempt-2, …, then the final run, assumed last "
            "unless the last attempt has no feedback.txt (a broken refinement the pipeline "
            "reverted; the final run then ran just before it, marked †).  Refinement counts are "
            "read from feedback.txt and are lower bounds.",
        ]
    )
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python -m benchmark.artifacts", description=__doc__.splitlines()[0]
    )
    parser.add_argument("results", type=Path, help="a results.json written by benchmark.runner")
    parser.add_argument("--entry", action="append", metavar="ID", help="only this entry id (repeatable)")
    parser.add_argument("--mode", help="only rows in this mode (seeded / independent)")
    parser.add_argument(
        "--rescore",
        action="store_true",
        help="re-score each row from its artifacts (first attempt, first scored, refinement split); "
        "prints a table and leaves the results file unchanged",
    )
    parser.add_argument(
        "--catalog",
        type=Path,
        default=None,
        help="catalog directory for --rescore (default: benchmark/papers)",
    )
    args = parser.parse_args(argv)
    try:
        rows = result_rows(json.loads(args.results.read_text(encoding="utf-8")))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"cannot read {args.results}: {exc}", file=sys.stderr)
        return 2
    rows = [
        r
        for r in rows
        if (not args.entry or r.get("entry_id") in args.entry)
        and (not args.mode or r.get("mode", "seeded") == args.mode)
    ]
    if not rows:
        print("no matching rows", file=sys.stderr)
        return 1
    if args.rescore:
        from benchmark import schema
        from benchmark.runner import CATALOG_DIR

        print(rescore_table(rows, schema.load_catalog(args.catalog or CATALOG_DIR)))
        return 0
    print("\n\n".join(describe_row(r) for r in rows))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
