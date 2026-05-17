"""Tests for the leaderboard aggregator in scripts/generate_leaderboard.py."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = REPO_ROOT / "scripts" / "generate_leaderboard.py"


def _load_module():
    """Load the generator script as a module without putting `scripts/` on sys.path.

    The script is a one-off CLI, not a package, so the test imports it
    via importlib rather than dropping ``scripts/`` into ``sys.path``.
    """
    spec = importlib.util.spec_from_file_location("generate_leaderboard", SCRIPT)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules["generate_leaderboard"] = module
    spec.loader.exec_module(module)
    return module


leaderboard_mod = _load_module()
build_leaderboard = leaderboard_mod.build_leaderboard


def _report(authors, claim_results, overall_passed):
    return {
        "paper": {"authors": authors},
        "claim_results": claim_results,
        "overall_passed": overall_passed,
    }


def _claim(passed: bool, reproduced: float | None = 0.9):
    return {"passed": passed, "reproduced_value": reproduced}


def test_single_paper_credits_every_author():
    reports = [_report(["Alice", "Bob"], [_claim(True), _claim(True)], True)]
    stats = build_leaderboard(reports)
    assert {s.author for s in stats} == {"Alice", "Bob"}
    for s in stats:
        assert s.papers == 1
        assert s.papers_passed == 1
        assert s.claims == 2
        assert s.claims_validated == 2
        assert s.claim_pass_rate == 1.0


def test_overall_failed_decrements_papers_passed_but_not_papers():
    reports = [_report(["Alice"], [_claim(False)], False)]
    stats = build_leaderboard(reports)
    assert stats[0].papers == 1
    assert stats[0].papers_passed == 0
    assert stats[0].paper_pass_rate == 0.0


def test_unvalidatable_counts_only_when_reproduced_value_is_none():
    reports = [
        _report(
            ["Alice"],
            [
                _claim(False, reproduced=None),  # unvalidatable
                _claim(False, reproduced=0.4),  # soft fail, not unvalidatable
            ],
            False,
        )
    ]
    stats = build_leaderboard(reports)
    assert stats[0].claims == 2
    assert stats[0].claims_validated == 0
    assert stats[0].claims_unvalidatable == 1


def test_ranking_by_pass_rate_then_total_claims_then_name():
    reports = [
        # Carol: 100%, 1 claim
        _report(["Carol"], [_claim(True)], True),
        # Alice: 100%, 2 claims (should outrank Carol on the tiebreak)
        _report(["Alice"], [_claim(True), _claim(True)], True),
        # Bob: 50%, 2 claims
        _report(["Bob"], [_claim(True), _claim(False)], False),
        # Dave: 0%
        _report(["Dave"], [_claim(False)], False),
    ]
    stats = build_leaderboard(reports)
    assert [s.author for s in stats] == ["Alice", "Carol", "Bob", "Dave"]


def test_alphabetical_tiebreak():
    reports = [
        _report(["Bob"], [_claim(True)], True),
        _report(["Alice"], [_claim(True)], True),
    ]
    stats = build_leaderboard(reports)
    # Same pass rate, same claim count → alphabetical
    assert [s.author for s in stats] == ["Alice", "Bob"]


def test_co_authorship_accumulates_across_papers():
    # Alice appears on two papers; should aggregate across both.
    reports = [
        _report(["Alice", "Bob"], [_claim(True)], True),
        _report(["Alice", "Carol"], [_claim(False)], False),
    ]
    stats = build_leaderboard(reports)
    by_author = {s.author: s for s in stats}
    assert by_author["Alice"].papers == 2
    assert by_author["Alice"].papers_passed == 1
    assert by_author["Alice"].claims == 2
    assert by_author["Alice"].claims_validated == 1
    assert by_author["Alice"].claim_pass_rate == 0.5


def test_empty_reports_returns_empty_list():
    assert build_leaderboard([]) == []


def test_paper_with_no_authors_is_skipped():
    reports = [_report([], [_claim(True)], True)]
    assert build_leaderboard(reports) == []


def test_real_reports_json_aggregates_cleanly():
    """End-to-end smoke test against the actual reports.json shape."""
    import json

    data = json.loads((REPO_ROOT / "docs" / "data" / "reports.json").read_text(encoding="utf-8"))
    stats = build_leaderboard(data)
    # At least one author per paper, no duplicates.
    assert len({s.author for s in stats}) == len(stats)
    # Ranking is sorted.
    pass_rates = [s.claim_pass_rate for s in stats]
    assert pass_rates == sorted(pass_rates, reverse=True)
