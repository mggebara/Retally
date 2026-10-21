"""Tests for the run-comparison report (benchmark.compare)."""

from __future__ import annotations

from tests._loaders import REPO_ROOT, load_module_from_path

load_module_from_path("benchmark.metrics", REPO_ROOT / "benchmark" / "metrics.py")
compare = load_module_from_path("benchmark.compare", REPO_ROOT / "benchmark" / "compare.py")


def _row(entry_id="p", mode="seeded", passed=True, **extra):
    row = {
        "entry_id": entry_id,
        "mode": mode,
        "split": "dev",
        "claim_details": [
            {
                "description": "beta",
                "claim_type": "coefficient",
                "claimed": 1.0,
                "reproduced": 1.0 if passed else 2.0,
                "tolerance": 0.02,
                "rel_err": 0.0 if passed else 1.0,
                "passed": passed,
            }
        ],
    }
    row.update(extra)
    return row


def test_header_names_each_runs_reproducer_and_modes():
    out = compare.compare_runs([_row()], [_row(reproducer="myagent:make", mode="independent")])
    assert "- baseline:  reproducer pipeline; mode seeded" in out
    assert "- candidate: reproducer myagent:make; mode independent" in out


def test_per_entry_table_shows_reproducer_and_changes():
    out = compare.compare_runs([_row()], [_row(passed=False)])
    assert "| Entry | Mode | Reproducer | Split |" in out
    assert "| `p` | seeded | pipeline | dev | 1/1 → 0/1 |" in out
    swapped = compare.compare_runs([_row()], [_row(reproducer="other")])
    assert "| `p` | seeded | pipeline → other | dev |" in swapped
