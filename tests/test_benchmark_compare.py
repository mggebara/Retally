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


def test_old_list_files_and_new_dict_files_both_load_and_compare():
    import json

    old_payload = json.loads(
        (REPO_ROOT / "benchmark" / "results" / "baseline-both-2026-10-19.json").read_text(encoding="utf-8")
    )
    assert isinstance(old_payload, list)  # pre-cost-accounting shape
    old_rows = compare.metrics.result_rows(old_payload)
    assert old_rows and all("usage" not in r for r in old_rows)
    new_rows = compare.metrics.result_rows({"usage": {}, "results": old_rows})
    assert new_rows == old_rows
    out = compare.compare_runs(old_rows, new_rows)
    assert "Newly failing: 0" in out


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
