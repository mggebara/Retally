"""The claim check a Claude Code session runs between attempts.

    uv run python -m benchmark.reproducers.check_attempt --run-dir DIR --stdout FILE

Reads the run directory's ``render.json`` for the entry and mode, loads
the entry's pinned claims from the catalog and parses ``FILE``'s
``RESULT:`` lines.

* Seeded / independent: prints the pipeline's own claim-gap feedback
  (``retally.pipeline._claim_gap_feedback``) for every claim that fails
  under the harness comparator in that mode — the text the pipeline's
  claim-targeted refinement is sent, and what the agent writes to a
  ``kind: "claim"`` attempt's ``feedback.txt``.
* Blind: prints ONLY ``missing: <names>`` — the claims with no parsable
  value — never a value, a tolerance or a gap.

Always exits 0 once it could read its inputs.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from benchmark import runner
from benchmark import schema as bschema


def check(run_dir: Path, stdout_text: str, *, catalog_dir: Path | None = None) -> str:
    """The feedback text for ``stdout_text`` in the run directory's cell."""
    from retally.models import ReproductionMode
    from retally.pipeline import _claim_gap_feedback
    from retally.validation.comparator import ResultComparator

    render = json.loads((Path(run_dir) / "render.json").read_text(encoding="utf-8"))
    entry_id, mode = render["entry_id"], ReproductionMode(render["mode"])
    entries = {e.id: e for e in bschema.load_catalog(catalog_dir or runner.CATALOG_DIR)}
    if entry_id not in entries:
        raise ValueError(f"catalog has no entry {entry_id!r}")
    claims = runner._claims_override_for(entries[entry_id]) or []
    outputs = runner._parse_result_lines(stdout_text)
    results = ResultComparator().compare_all(claims, outputs, mode=mode)
    if mode.withholds_targets:
        missing = [cr.claim.description for cr in results if cr.reproduced_value is None]
        return "missing: " + (", ".join(missing) if missing else "(none)")
    failed = [cr for cr in results if not cr.passed]
    if not failed:
        return "All claims within tolerance."
    return _claim_gap_feedback(failed)


def main(argv: list[str] | None = None) -> int:
    import argparse

    parser = argparse.ArgumentParser(
        prog="python -m benchmark.reproducers.check_attempt",
        description="Claim feedback (seeded / independent) or missing names (blind) for one attempt.",
    )
    parser.add_argument("--run-dir", required=True, type=Path, help="The run's output directory.")
    parser.add_argument("--stdout", required=True, type=Path, help="The attempt's stdout.txt.")
    args = parser.parse_args(argv)
    try:
        text = check(args.run_dir, args.stdout.read_text(encoding="utf-8", errors="replace"))
    except (OSError, KeyError, ValueError, json.JSONDecodeError) as exc:
        print(f"check_attempt: {exc}", file=sys.stderr)
        return 2
    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
