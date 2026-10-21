"""Inspect the run artifacts a benchmark results file points at.

``uv run python -m benchmark.artifacts benchmark/results/results.json [--entry ID] [--mode MODE]``

For each row: its ``artifacts_dir``, the data files the final script
reads, the ``RESULT:`` lines of the final stdout, and the per-claim
pass/fail.  The data-file list is a grep, not a parse — enough to spot
"read the wrong file" at a glance.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from benchmark.metrics import first_attempt_passed, refinements_of, result_rows

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
    if n_ref is not None:
        n_exec = row.get("n_executions")
        lines.append(
            f"  refinements: {n_ref}" + (f" ({n_exec} executions)" if isinstance(n_exec, int) else "")
        )
    details = row.get("claim_details") or []
    if details:
        n_pass = sum(1 for d in details if d.get("passed"))
        first = first_attempt_passed(row)
        lines.append(
            f"  claims: {n_pass}/{len(details)} pass"
            + (f" (first attempt {first}/{len(details)})" if first is not None else "")
        )
        for d in details:
            reproduced = d.get("reproduced")
            rel_err = d.get("rel_err")
            err = f"rel_err {rel_err:.3g}" if isinstance(rel_err, (int, float)) else "unmatched"
            first_tag = ""
            if isinstance(d.get("passed_first_attempt"), bool):
                first_tag = f" [first attempt {'PASS' if d['passed_first_attempt'] else 'FAIL'}]"
            lines.append(
                f"    [{'PASS' if d.get('passed') else 'FAIL'}] {d.get('description')}: "
                f"claimed {d.get('claimed')}, reproduced {reproduced} ({err}){first_tag}"
            )
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python -m benchmark.artifacts", description=__doc__.splitlines()[0]
    )
    parser.add_argument("results", type=Path, help="a results.json written by benchmark.runner")
    parser.add_argument("--entry", action="append", metavar="ID", help="only this entry id (repeatable)")
    parser.add_argument("--mode", help="only rows in this mode (seeded / independent)")
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
    print("\n\n".join(describe_row(r) for r in rows))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
