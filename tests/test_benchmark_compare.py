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


def test_per_entry_table_adds_first_attempt_counts_when_recorded():
    base = _row()  # an older row: no first-attempt data
    cand = _row(n_claims_with_paper_match_first_attempt=0, n_refinements=2)
    out = compare.compare_runs([base], [cand])
    assert "| Passed (base → cand) | First attempt (base → cand) | Median rel err" in out
    assert "| `p` | seeded | pipeline | dev | 1/1 → 1/1 | — → 0/1 |" in out


def test_per_entry_table_omits_first_attempt_column_for_older_files():
    out = compare.compare_runs([_row()], [_row(passed=False)])
    assert "First attempt" not in out
    assert "| `p` | seeded | pipeline | dev | 1/1 → 0/1 | 0.0% → 100.0% |" in out


def test_per_entry_table_prefers_first_scored_counts():
    base = _row(n_claims_with_paper_match_first_attempt=0)  # a PR-45-era row: no first scored
    cand = _row(n_claims_with_paper_match_first_attempt=0, n_claims_with_paper_match_first_scored=1)
    out = compare.compare_runs([base], [cand])
    assert "| Passed (base → cand) | First scored (base → cand) | Median rel err" in out
    assert "| `p` | seeded | pipeline | dev | 1/1 → 1/1 | — → 1/1 |" in out
    assert "First attempt" not in out


def test_three_mode_runs_compare_like_for_like():
    base = [_row(mode="seeded"), _row(mode="independent"), _row(mode="blind", passed=False)]
    cand = [_row(mode="seeded"), _row(mode="independent"), _row(mode="blind")]
    out = compare.compare_runs(base, cand)
    assert "mode seeded, independent, blind" in out
    assert "### dev · blind" in out
    assert "| `p` | blind | pipeline | dev | 0/1 → 1/1 |" in out
    assert "| `p` | seeded | pipeline | dev | 1/1 → 1/1 |" in out
    assert "Newly passing: 1" in out and "`p` (blind): beta" in out


def test_two_mode_baseline_against_three_mode_candidate():
    base = [_row(mode="seeded"), _row(mode="independent")]
    cand = [*base, _row(mode="blind", n_claims_with_paper_match_first_scored=1)]
    out = compare.compare_runs(base, cand)
    assert "- baseline:  reproducer pipeline; mode seeded, independent" in out
    assert "- candidate: reproducer pipeline; mode seeded, independent, blind" in out
    assert "| `p` | blind | pipeline | dev | — → 1/1 | — → 1/1 |" in out
    assert "Newly passing: 1" in out
