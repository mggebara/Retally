"""Tests for benchmark closeness metrics and the run-comparison tool."""

from __future__ import annotations

from tests._loaders import REPO_ROOT, load_module_from_path

metrics = load_module_from_path("benchmark.metrics", REPO_ROOT / "benchmark" / "metrics.py")
compare = load_module_from_path("benchmark.compare", REPO_ROOT / "benchmark" / "compare.py")


def _cd(claimed=1.0, reproduced=1.0, tolerance=0.01, *, passed=None, description="c"):
    """Build a claim_details dict in results.json shape."""
    rel_err = None if reproduced is None else abs(reproduced - claimed) / max(abs(claimed), 1e-9)
    if passed is None:
        passed = rel_err is not None and rel_err <= tolerance
    return {
        "description": description,
        "claim_type": "coefficient",
        "claimed": claimed,
        "reproduced": reproduced,
        "tolerance": tolerance,
        "rel_err": rel_err,
        "passed": passed,
    }


def _result(entry_id="e1", split="dev", claim_details=None, *, skipped=False):
    return {
        "entry_id": entry_id,
        "skipped": skipped,
        "split": split,
        "claim_details": claim_details or [],
    }


# ── closeness() ─────────────────────────────────────────────────────────


def test_closeness_counts_and_median():
    results = [
        _result(
            claim_details=[
                _cd(claimed=1.0, reproduced=1.0),  # rel_err 0.0, passes
                _cd(claimed=1.0, reproduced=1.5),  # rel_err 0.5
                _cd(claimed=1.0, reproduced=2.0),  # rel_err 1.0
                _cd(claimed=1.0, reproduced=None),  # unmatched
            ]
        )
    ]
    m = metrics.closeness(results)
    assert m.n_claims == 4
    assert m.n_matched == 3
    assert m.n_passed == 1
    assert m.median_rel_err == 0.5
    assert m.match_rate == 3 / 4


def test_closeness_widening_tolerance_bands_show_gradient():
    """A claim at 1.5% error with 1% tolerance fails the pass check but
    lands inside the 2x band — that IS the tuning gradient."""
    results = [_result(claim_details=[_cd(claimed=1.0, reproduced=1.015, tolerance=0.01)])]
    m = metrics.closeness(results)
    assert m.n_passed == 0
    assert m.frac_within_tol == 0.0
    assert m.frac_within_2x_tol == 1.0
    assert m.frac_within_5x_tol == 1.0


def test_closeness_skipped_entries_excluded():
    results = [
        _result(entry_id="ran", claim_details=[_cd()]),
        _result(entry_id="skip", skipped=True, claim_details=[_cd(), _cd()]),
    ]
    m = metrics.closeness(results)
    assert m.n_entries == 1
    assert m.n_claims == 1


def test_closeness_no_matched_claims_yields_none_medians():
    results = [_result(claim_details=[_cd(reproduced=None)])]
    m = metrics.closeness(results)
    assert m.median_rel_err is None
    assert m.frac_within_tol is None
    assert m.match_rate == 0.0


def test_by_split_groups_and_omits_absent_splits():
    results = [
        _result(entry_id="d", split="dev", claim_details=[_cd()]),
        _result(entry_id="h", split="holdout", claim_details=[_cd(reproduced=2.0)]),
    ]
    grouped = metrics.by_split(results)
    assert set(grouped) == {"dev", "holdout"}
    assert grouped["dev"].n_passed == 1
    assert grouped["holdout"].n_passed == 0


def test_format_metrics_line_is_human_readable():
    line = metrics.format_metrics_line(metrics.closeness([_result(claim_details=[_cd()])]))
    assert "1 entries" in line
    assert "median rel err" in line


# ── compare ─────────────────────────────────────────────────────────────


def _runs_with_improvement():
    baseline = [
        _result(
            claim_details=[
                _cd(description="beta", claimed=3.713, reproduced=9.0),  # way off
                _cd(description="r2", claimed=0.5, reproduced=0.9),
            ]
        )
    ]
    candidate = [
        _result(
            claim_details=[
                _cd(
                    description="beta", claimed=3.713, reproduced=3.72
                ),  # now passes (rel ~0.2%... tolerance 1%)
                _cd(description="r2", claimed=0.5, reproduced=0.6),  # closer, still fails
            ]
        )
    ]
    return baseline, candidate


def test_compare_reports_median_improvement_and_flips():
    baseline, candidate = _runs_with_improvement()
    out = compare.compare_runs(baseline, candidate)
    assert "median rel err improved" in out
    assert "Newly passing: 1" in out
    assert "beta" in out
    assert "Newly failing: 0" in out


def test_compare_handles_entry_only_in_one_run():
    baseline = [_result(entry_id="old-only", claim_details=[_cd()])]
    candidate = [_result(entry_id="new-only", claim_details=[_cd()])]
    out = compare.compare_runs(baseline, candidate)
    assert "`old-only`" in out and "`new-only`" in out
    assert "—" in out  # absent side rendered as em dash, not a crash


def test_compare_cli_main(tmp_path, capsys):
    import json as _json

    baseline, candidate = _runs_with_improvement()
    b = tmp_path / "base.json"
    c = tmp_path / "cand.json"
    b.write_text(_json.dumps(baseline), encoding="utf-8")
    c.write_text(_json.dumps(candidate), encoding="utf-8")

    rc = compare.main([str(b), str(c)])
    assert rc == 0
    out = capsys.readouterr().out
    assert "# Benchmark run comparison" in out


def test_compare_cli_usage_error(capsys):
    rc = compare.main(["only-one.json"])
    assert rc == 2
    assert "usage" in capsys.readouterr().err


# ── Reproduction modes ──────────────────────────────────────────────────


def _moded(mode, claim_details, entry_id="e1"):
    return {**_result(entry_id=entry_id, claim_details=claim_details), "mode": mode}


def test_rows_without_mode_count_as_seeded():
    assert metrics.mode_of({"entry_id": "old"}) == "seeded"
    assert metrics.modes_present([{"entry_id": "a"}, {"entry_id": "b", "mode": "independent"}]) == [
        "seeded",
        "independent",
    ]


def test_mode_gaps_join_claims_by_description():
    results = [
        _moded("seeded", [_cd(description="beta", passed=True), _cd(description="se", passed=True)]),
        _moded("independent", [_cd(description="beta", passed=True), _cd(description="se", passed=False)]),
        _moded("seeded", [_cd(description="x", passed=True)], entry_id="seeded-only"),
    ]
    [gap] = metrics.mode_gaps(results)  # seeded-only entry has no pair → excluded
    assert (gap.entry_id, gap.seeded_passed, gap.independent_passed) == ("e1", 2, 1)
    assert gap.lost == ["se"]
    assert gap.gained == []


def test_modes_present_orders_blind_after_independent():
    rows = [{"entry_id": "a", "mode": m} for m in ("blind", "zzz", "independent", "seeded")]
    assert metrics.modes_present(rows) == ["seeded", "independent", "blind", "zzz"]


def test_mode_gaps_carry_an_optional_blind_row():
    results = [
        _moded("seeded", [_cd(description="beta", passed=True), _cd(description="se", passed=True)]),
        _moded("independent", [_cd(description="beta", passed=True), _cd(description="se", passed=False)]),
        {
            **_moded("blind", [_cd(description="beta", passed=True), _cd(description="se", passed=False)]),
            "n_claims_with_paper_match_first_scored": 1,
        },
        _moded("seeded", [_cd(description="x", passed=True)], entry_id="e2"),
        _moded("independent", [_cd(description="x", passed=True)], entry_id="e2"),
    ]
    with_blind, without = metrics.mode_gaps(results)
    assert with_blind.has_blind
    assert (with_blind.blind_passed, with_blind.blind_total, with_blind.blind_passed_first_scored) == (
        1,
        2,
        1,
    )
    assert with_blind.lost == ["se"]  # lost / gained stay seeded-vs-independent
    assert not without.has_blind
    assert (without.blind_passed, without.blind_total, without.blind_passed_first_scored) == (
        None,
        None,
        None,
    )


def test_compare_keys_rows_by_entry_and_mode():
    """A seeded and an independent row of the same paper must never be
    diffed against each other — only like-for-like across runs."""
    baseline = [
        _moded("seeded", [_cd(description="beta", passed=True)]),
        _moded("independent", [_cd(description="beta", passed=False)]),
    ]
    candidate = [
        _moded("seeded", [_cd(description="beta", passed=True)]),
        _moded("independent", [_cd(description="beta", passed=True)]),
    ]
    out = compare.compare_runs(baseline, candidate)
    assert "Newly passing: 1" in out
    assert "`e1` (independent): beta" in out
    assert "Newly failing: 0" in out
    assert "### dev · seeded" in out and "### dev · independent" in out
    assert "| `e1` | seeded |" in out and "| `e1` | independent |" in out


def test_compare_old_results_without_mode_match_seeded_rows():
    baseline = [_result(claim_details=[_cd(description="beta", passed=False)])]  # pre-mode file
    candidate = [_moded("seeded", [_cd(description="beta", passed=True)])]
    out = compare.compare_runs(baseline, candidate)
    assert "Newly passing: 1" in out
    assert "`e1` (seeded): beta" in out
