"""Tests for the leaderboard aggregator in scripts/generate_leaderboard.py."""

from __future__ import annotations

from tests._loaders import REPO_ROOT, load_module_from_path

leaderboard_mod = load_module_from_path(
    "generate_leaderboard", REPO_ROOT / "scripts" / "generate_leaderboard.py"
)
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


# ── Write / main round-trip ────────────────────────────────────────────


def test_write_json_round_trip(tmp_path, monkeypatch):
    import json

    monkeypatch.setattr(leaderboard_mod, "LEADERBOARD_JSON", tmp_path / "out.json")
    stats = build_leaderboard([_report(["Alice", "Bob"], [_claim(True), _claim(False)], False)])
    leaderboard_mod.write_json(stats)
    rows = json.loads((tmp_path / "out.json").read_text(encoding="utf-8"))
    assert len(rows) == 2
    by_author = {r["author"]: r for r in rows}
    assert set(by_author) == {"Alice", "Bob"}
    for r in by_author.values():
        assert r["papers"] == 1
        assert r["claims"] == 2
        assert r["claims_validated"] == 1
        assert r["claim_pass_rate"] == 0.5


def test_write_markdown_round_trip(tmp_path, monkeypatch):
    monkeypatch.setattr(leaderboard_mod, "LEADERBOARD_MD", tmp_path / "out.md")
    stats = build_leaderboard([_report(["Alice"], [_claim(True)], True)])
    leaderboard_mod.write_markdown(stats, n_reports=1)
    content = (tmp_path / "out.md").read_text(encoding="utf-8")
    assert "# OpenRA Reproducibility Leaderboard" in content
    assert "| 1 | Alice | 1 | 1 | 1 | 1 | 0 | 100.0% |" in content
    assert "1 reports" in content  # n_reports surfaced


def test_main_is_idempotent_on_unchanged_input(tmp_path, monkeypatch, capsys):
    """Running main() twice in a row must produce byte-identical files."""
    import json

    # Stage a small synthetic reports.json so we don't depend on the real one.
    reports_path = tmp_path / "reports.json"
    reports_path.write_text(
        json.dumps(
            [
                {
                    "paper": {"authors": ["Alice"]},
                    "claim_results": [{"passed": True, "reproduced_value": 0.95}],
                    "overall_passed": True,
                }
            ]
        )
    )
    monkeypatch.setattr(leaderboard_mod, "REPORTS_FILE", reports_path)
    monkeypatch.setattr(leaderboard_mod, "LEADERBOARD_JSON", tmp_path / "lb.json")
    monkeypatch.setattr(leaderboard_mod, "LEADERBOARD_MD", tmp_path / "lb.md")
    # main() prints relative paths; make REPO_ROOT a parent of the temp files
    # so .relative_to() doesn't blow up.
    monkeypatch.setattr(leaderboard_mod, "REPO_ROOT", tmp_path)

    leaderboard_mod.main()
    first_json = (tmp_path / "lb.json").read_bytes()
    first_md = (tmp_path / "lb.md").read_bytes()

    leaderboard_mod.main()
    assert (tmp_path / "lb.json").read_bytes() == first_json
    assert (tmp_path / "lb.md").read_bytes() == first_md
