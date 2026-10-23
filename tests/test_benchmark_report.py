"""Tests for the benchmark report renderer."""

from __future__ import annotations

from tests._loaders import REPO_ROOT, load_module_from_path

# report.py does ``from benchmark import metrics`` — pre-load it so the
# from-import resolves via sys.modules under the file-based test loader.
load_module_from_path("benchmark.metrics", REPO_ROOT / "benchmark" / "metrics.py")
load_module_from_path("benchmark.pricing", REPO_ROOT / "benchmark" / "pricing.py")
report = load_module_from_path("benchmark.report", REPO_ROOT / "benchmark" / "report.py")


def _result(**overrides):
    """Build a result dict in the shape runner.write_results emits."""
    base = {
        "entry_id": "test",
        "skipped": False,
        "skip_reason": None,
        "error": None,
        "retally_ran": True,
        "agrees_with_paper": True,
        "agrees_with_i4r": True,
        "n_claims_in_catalog": 1,
        "n_claims_with_paper_match": 1,
        "n_claims_with_i4r_match": 1,
        "components": {
            "parsed": True,
            "claims_extracted": True,
            "dataset_extracted": True,
            "dataset_downloaded": True,
            "code_generated": True,
            "code_executed": True,
        },
        "cached": False,
    }
    base.update(overrides)
    return base


# ── Empty / placeholder rendering ───────────────────────────────────────


def test_empty_results_markdown_is_clear():
    md = report.render_markdown([])
    assert "catalog is empty" in md.lower() or "empty" in md.lower()


def test_empty_results_html_is_valid():
    html = report.render_html([])
    assert "<html" in html
    assert "No benchmark results" in html


# ── Headline counts ────────────────────────────────────────────────────


def test_headline_counts_categorise_skips():
    results = [
        _result(entry_id="a", skipped=True, skip_reason="out_of_scope"),
        _result(entry_id="b", skipped=True, skip_reason="language_unsupported"),
        _result(entry_id="c", skipped=True, skip_reason="no_api_key"),
        _result(entry_id="d"),  # executed
    ]
    md = report.render_markdown(results)
    assert "Catalog size: **4**" in md
    assert "Executed: **1**" in md
    assert "out_of_scope=1" in md
    assert "language_unsupported=1" in md
    assert "no_api_key=1" in md
    assert "reproducer_init_failed" not in md  # absent kinds don't change the headline


def test_headline_counts_reproducer_init_failures():
    results = [
        _result(entry_id="a", skipped=True, skip_reason="reproducer_init_failed", error="RuntimeError: x"),
        _result(entry_id="b"),
    ]
    md = report.render_markdown(results)
    assert "no_api_key=0, reproducer_init_failed=1)" in md
    assert "reproducer_init_failed=1" in report.render_html(results)


def test_verdict_summary_counts_executed_only():
    """The verdict summary's denominator is executed papers, not the whole catalog."""
    results = [
        _result(entry_id="skipped1", skipped=True, skip_reason="out_of_scope"),
        _result(entry_id="exec1", retally_ran=True, agrees_with_paper=True),
        _result(entry_id="exec2", retally_ran=True, agrees_with_paper=False),
    ]
    md = report.render_markdown(results)
    assert "Pipeline completed without crashing: **2 / 2**" in md
    assert "Agrees with the paper's stated values: **1 / 2**" in md


def test_verdict_summary_omits_i4r_papers_without_findings():
    """agrees_with_i4r=None means no I4R value to compare against."""
    results = [
        _result(entry_id="x", agrees_with_i4r=None),  # nothing to compare
        _result(entry_id="y", agrees_with_i4r=True),
        _result(entry_id="z", agrees_with_i4r=False),
    ]
    md = report.render_markdown(results)
    # Denominator counts only papers where i4r is True or False (not None).
    assert "Agrees with the I4R replicator: **1 / 2**" in md


def test_verdict_summary_when_no_executed():
    md = report.render_markdown([_result(entry_id="x", skipped=True, skip_reason="out_of_scope")])
    assert "No papers were executed" in md


# ── Per-component breakdown ────────────────────────────────────────────


def test_component_breakdown_rates():
    components_full = {
        "parsed": True,
        "claims_extracted": True,
        "dataset_extracted": True,
        "dataset_downloaded": True,
        "code_generated": True,
        "code_executed": True,
    }
    components_partial = {**components_full, "code_executed": False}
    results = [
        _result(entry_id="a", components=components_full),
        _result(entry_id="b", components=components_partial),
    ]
    md = report.render_markdown(results)
    # 2/2 parsed, but 1/2 code_executed.
    assert "| parsed | 2 | 2 | 100% |" in md
    assert "| code_executed | 1 | 2 | 50% |" in md


# ── Per-row rendering ──────────────────────────────────────────────────


def test_per_paper_row_contains_id_and_glyphs():
    md = report.render_markdown([_result(entry_id="foo-2023")])
    assert "`foo-2023`" in md
    # All three verdicts True → three checkmarks in the row.
    assert "| ✓ | ✓ | ✓ |" in md


def test_skipped_paper_row_shows_skip_reason():
    md = report.render_markdown(
        [
            _result(
                entry_id="x",
                skipped=True,
                skip_reason="out_of_scope",
                # Skipped entries have None verdicts; the default helper
                # sets them to True so override explicitly.
                retally_ran=None,
                agrees_with_paper=None,
                agrees_with_i4r=None,
            )
        ]
    )
    assert "skipped: out_of_scope" in md
    assert "| — | — | — |" in md  # None verdicts rendered as em dash


def test_cached_paper_row_marked():
    md = report.render_markdown([_result(entry_id="cached1", cached=True)])
    # Cached column shows a checkmark.  Entry id is rendered in backticks
    # for markdown formatting.
    assert "| `cached1` |" in md
    # The cached glyph appears at end of the row, after the claims column.
    [row] = [line for line in md.splitlines() if "cached1" in line]
    assert row.rstrip().endswith("| ✓ |")


def test_error_row_truncates_long_messages():
    long_err = "RuntimeError: " + "x" * 500
    md = report.render_markdown([_result(entry_id="err1", retally_ran=False, error=long_err)])
    [row] = [line for line in md.splitlines() if "err1" in line]
    # Truncated to ~60 chars per _status_label.
    assert len(row) < 200


# ── HTML rendering ─────────────────────────────────────────────────────


def test_html_includes_table_and_row():
    html = report.render_html([_result(entry_id="r1")])
    assert "<table>" in html
    assert "r1" in html
    assert "<thead>" in html


def test_html_escapes_html_in_entry_id():
    html = report.render_html([_result(entry_id="<script>alert(1)</script>")])
    assert "<script>" not in html
    assert "&lt;script&gt;" in html


# ── Write-to-disk ──────────────────────────────────────────────────────


def test_write_report_emits_both_files(tmp_path):
    report.write_report([_result(entry_id="x")], out_dir=tmp_path)
    md = (tmp_path / "REPORT.md").read_text(encoding="utf-8")
    html = (tmp_path / "report.html").read_text(encoding="utf-8")
    assert "Retally benchmark report" in md
    assert "<title>Retally benchmark report</title>" in html


def test_write_report_creates_dir(tmp_path):
    nested = tmp_path / "deep" / "nest"
    report.write_report([], out_dir=nested)
    assert (nested / "REPORT.md").exists()
    assert (nested / "report.html").exists()


# ── Closeness section (tuning metrics) ─────────────────────────────────


def test_closeness_section_renders_per_split():
    results = [
        _result(
            entry_id="d1",
            claim_details=[
                {
                    "description": "beta",
                    "claim_type": "coefficient",
                    "claimed": 1.0,
                    "reproduced": 1.5,
                    "tolerance": 0.02,
                    "rel_err": 0.5,
                    "passed": False,
                }
            ],
        ),
    ]
    results[0]["split"] = "dev"
    md = report.render_markdown(results)
    assert "## Closeness (per split)" in md
    assert "**dev**" in md
    assert "median rel err 50.0%" in md


def test_closeness_section_absent_without_claim_details():
    """Old results.json (no claim_details) renders exactly as before."""
    md = report.render_markdown([_result(entry_id="x")])
    assert "Closeness" not in md


# ── Reproduction modes ──────────────────────────────────────────────────


def _cd(description, passed):
    return {
        "description": description,
        "claim_type": "coefficient",
        "claimed": 1.0,
        "reproduced": 1.0 if passed else 2.0,
        "tolerance": 0.02,
        "rel_err": 0.0 if passed else 1.0,
        "passed": passed,
    }


def test_single_mode_report_states_the_mode_and_has_no_mode_column():
    md = report.render_markdown([_result(entry_id="x")])  # pre-mode row → seeded
    assert "Reproduction mode: **seeded**" in md
    assert "Reproducer: **pipeline**." in md  # rows predating the field: the pipeline
    assert "| ID | Status |" in md
    assert "Seeded vs independent" not in md


def test_both_mode_report_presents_modes_side_by_side():
    results = [
        _result(entry_id="p", mode="seeded", claim_details=[_cd("beta", True), _cd("se", True)]),
        _result(entry_id="p", mode="independent", claim_details=[_cd("beta", True), _cd("se", False)]),
    ]
    md = report.render_markdown(results)
    # Papers are counted once, runs once per mode.
    assert "Catalog size: **1** papers, each run in 2 reproduction modes" in md
    assert "Runs (paper × mode): **2**" in md
    assert "## Verdicts — seeded" in md and "## Verdicts — independent" in md
    assert "## Seeded vs independent" in md
    assert "- Seeded: **2 / 2** claims passed" in md
    assert "- Independent: **1 / 2** claims passed" in md
    assert "| `p` | dev | pipeline | 2/2 | 1/2 | `se` |" in md
    assert "**dev · seeded**" in md and "**dev · independent**" in md
    assert "| ID | Mode | Reproducer | Status |" in md
    assert "| `p` | independent | pipeline | ran |" in md
    assert "Reproducer: **pipeline**." in md
    html = report.render_html(results)
    assert "<th>Mode</th><th>Reproducer</th>" in html
    assert "<td>independent</td><td>pipeline</td>" in html


def test_reproducer_shown_alongside_mode_for_a_plugged_in_agent():
    results = [
        _result(entry_id="p", mode="seeded", reproducer="myagent:make", claim_details=[_cd("b", True)]),
        _result(entry_id="p", mode="independent", reproducer="myagent:make", claim_details=[_cd("b", False)]),
    ]
    md = report.render_markdown(results)
    assert "Reproducer: **myagent:make**." in md
    assert "| `p` | dev | myagent:make | 1/1 | 0/1 | `b` |" in md
    assert "| `p` | seeded | myagent:make | ran |" in md


# ── Estimated API cost ─────────────────────────────────────────────────


def _usage(inp=1_000_000, out=100_000, calls=3, hits=2, model="claude-opus-4-7"):
    return {
        "api_calls": calls,
        "llm_cache_hits": hits,
        "llm_cache_served": hits > 0,
        "by_model": {
            model: {
                "input_tokens": inp,
                "output_tokens": out,
                "cache_creation_input_tokens": 0,
                "cache_read_input_tokens": 0,
                "api_calls": calls,
            }
        },
    }


def test_cost_section_absent_for_results_without_usage():
    md = report.render_markdown([_result(entry_id="x")])
    assert "Estimated API cost" not in md


def test_cost_section_per_paper_per_mode_and_total():
    results = [
        _result(entry_id="p", mode="seeded", usage=_usage()),
        _result(entry_id="p", mode="independent", usage=_usage(inp=2_000_000, out=0, hits=0)),
        _result(entry_id="q", mode="seeded", cached=True, usage=_usage()),
        _result(entry_id="r", mode="seeded", skipped=True, skip_reason="out_of_scope"),
    ]
    md = report.render_markdown(results)
    assert "## Estimated API cost" in md
    # 7.50 (seeded p) + 10.00 (independent p); q came from the result cache.
    assert "Total estimated spend this run: **$17.50** across 6 API calls" in md
    assert "2 further calls served free by the LLM cache" in md
    assert "1 rows from the result cache" in md
    assert "| `p` | seeded | pipeline | 3 | 2 | 1,000,000 | 100,000 | 0 | 0 | $7.50 |" in md
    assert "| `p` | independent | pipeline | 3 | 0 | 2,000,000 | 0 | 0 | 0 | $10.00 |" in md
    assert "result cache (was $7.50)" in md
    assert "| `r` |" not in md.split("## Estimated API cost")[1].split("## Per-paper")[0]


def test_cost_section_flags_unpriced_models():
    md = report.render_markdown([_result(entry_id="p", usage=_usage(model="claude-unknown-9"))])
    assert "Not priced (absent from the table): `claude-unknown-9`." in md


# ── First-attempt vs final pass counts ─────────────────────────────────


def _cd_first(description, passed, first):
    return {**_cd(description, passed), "passed_first_attempt": first}


def test_per_paper_row_shows_first_attempt_and_refinements():
    row = _result(
        entry_id="p",
        n_claims_in_catalog=2,
        n_claims_with_paper_match=2,
        n_claims_with_paper_match_first_attempt=1,
        n_refinements=1,
        n_executions=2,
        claim_details=[_cd_first("beta", True, False), _cd_first("se", True, True)],
    )
    md = report.render_markdown([row])
    assert "| 2 / 1 of 2 (first attempt 1/2, 1 refinement) |" in md
    html = report.render_html([row])
    assert "2 / 1 of 2 (first attempt 1/2, 1 refinement)</td>" in html


def test_rows_without_attempt_data_render_as_before():
    md = report.render_markdown([_result(entry_id="p")])
    assert "| 1 / 1 of 1 |" in md
    assert "first attempt" not in md
    assert "first attempt" not in report.render_html([_result(entry_id="p")])


def test_mode_gap_table_adds_a_first_attempt_pair():
    results = [
        _result(
            entry_id="p",
            mode="seeded",
            n_claims_with_paper_match_first_attempt=2,
            n_refinements=0,
            claim_details=[_cd_first("beta", True, True), _cd_first("se", True, True)],
        ),
        _result(
            entry_id="p",
            mode="independent",
            n_claims_with_paper_match_first_attempt=0,
            n_refinements=3,
            claim_details=[_cd_first("beta", True, False), _cd_first("se", False, False)],
        ),
    ]
    md = report.render_markdown(results)
    assert "- Seeded: **2 / 2** claims passed (first attempt 2 / 2)" in md
    assert "- Independent: **1 / 2** claims passed (first attempt 0 / 2)" in md
    assert "| First attempt (seeded / independent) |" in md
    assert "| `p` | dev | pipeline | 2/2 | 1/2 | 2/2 / 0/2 | `se` |" in md
    assert "(first attempt 0/2, 3 refinements)" in md


def test_mode_gap_table_without_attempt_data_is_unchanged():
    results = [
        _result(entry_id="p", mode="seeded", claim_details=[_cd("beta", True)]),
        _result(entry_id="p", mode="independent", claim_details=[_cd("beta", False)]),
    ]
    md = report.render_markdown(results)
    assert "| Entry | Split | Reproducer | Seeded | Independent | Lost without scripts |" in md
    assert "First attempt" not in md and "first attempt" not in md


# ── First scored (after crash repairs, before claim feedback) ──────────


def test_per_paper_row_headlines_first_scored_with_the_refinement_split():
    row = _result(
        entry_id="p",
        n_claims_in_catalog=2,
        n_claims_with_paper_match=2,
        n_claims_with_paper_match_first_attempt=0,
        n_claims_with_paper_match_first_scored=1,
        first_scored_attempt_index=2,
        n_refinements=5,
        n_error_refinements=2,
        n_claim_refinements=3,
        claim_details=[_cd_first("beta", True, False), _cd_first("se", True, False)],
    )
    md = report.render_markdown([row])
    assert "| 2 / 1 of 2 (first scored 1/2, 2 error + 3 claim refinements) |" in md
    assert "first attempt" not in md
    html = report.render_html([row])
    assert "2 / 1 of 2 (first scored 1/2, 2 error + 3 claim refinements)</td>" in html


def test_mode_gap_table_uses_first_scored_when_recorded():
    results = [
        _result(
            entry_id="p",
            mode="seeded",
            n_claims_with_paper_match_first_attempt=0,
            n_claims_with_paper_match_first_scored=2,
            n_error_refinements=1,
            n_claim_refinements=0,
            claim_details=[_cd("beta", True), _cd("se", True)],
        ),
        _result(
            entry_id="p",
            mode="independent",
            n_claims_with_paper_match_first_attempt=0,
            n_claims_with_paper_match_first_scored=1,
            n_error_refinements=2,
            n_claim_refinements=3,
            claim_details=[_cd("beta", True), _cd("se", False)],
        ),
    ]
    md = report.render_markdown(results)
    assert "- Seeded: **2 / 2** claims passed (first scored 2 / 2)" in md
    assert "- Independent: **1 / 2** claims passed (first scored 1 / 2)" in md
    assert "*First scored* is" in md
    assert "| First scored (seeded / independent) |" in md
    assert "| `p` | dev | pipeline | 2/2 | 1/2 | 2/2 / 1/2 | `se` |" in md
    assert "First attempt" not in md


def _three_mode_results(blind_entries=("p",)):
    rows = []
    for entry_id in ("p", "q"):
        rows += [
            _result(
                entry_id=entry_id,
                mode="seeded",
                n_claims_with_paper_match_first_scored=2,
                claim_details=[_cd("beta", True), _cd("se", True)],
            ),
            _result(
                entry_id=entry_id,
                mode="independent",
                n_claims_with_paper_match_first_scored=1,
                claim_details=[_cd("beta", True), _cd("se", False)],
            ),
        ]
        if entry_id in blind_entries:
            rows.append(
                _result(
                    entry_id=entry_id,
                    mode="blind",
                    n_claims_with_paper_match=0,
                    n_claims_with_paper_match_first_scored=0,
                    n_claim_refinements=0,
                    claim_details=[_cd("beta", False), _cd("se", False)],
                )
            )
    return rows


def test_three_mode_report_adds_a_blind_column():
    md = report.render_markdown(_three_mode_results(blind_entries=("p", "q")))
    assert "each run in 3 reproduction modes" in md
    assert "- **blind**: the authors' scripts and the claimed values were withheld" in md
    assert "## Verdicts — seeded" in md and "## Verdicts — blind" in md
    assert md.index("## Verdicts — independent") < md.index("## Verdicts — blind")
    assert "## Seeded vs independent vs blind" in md
    assert "only ones free of target-guided search" in md
    assert "- Blind: **0 / 4** claims passed (first scored 0 / 4)" in md
    assert (
        "| Entry | Split | Reproducer | Seeded | Independent | Blind "
        "| First scored (seeded / independent / blind) |" in md
    )
    assert "| `p` | dev | pipeline | 2/2 | 1/2 | 0/2 | 2/2 / 1/2 / 0/2 | `se` |" in md
    assert "| `p` | blind | pipeline |" in md


def test_blind_column_marks_papers_without_a_blind_row():
    md = report.render_markdown(_three_mode_results(blind_entries=("p",)))
    assert "- Blind: **0 / 2** claims passed (on 1 of 2 papers) (first scored 0 / 2)" in md
    assert "| `q` | dev | pipeline | 2/2 | 1/2 | — | 2/2 / 1/2 / —/— | `se` |" in md


def test_two_mode_report_has_no_blind_column():
    md = report.render_markdown(_three_mode_results(blind_entries=()))
    assert "## Seeded vs independent\n" in md
    assert "Blind" not in md and "blind" not in md
    assert "| `p` | dev | pipeline | 2/2 | 1/2 | 2/2 / 1/2 | `se` |" in md


def test_single_blind_mode_report_states_the_mode():
    md = report.render_markdown([_result(entry_id="x", mode="blind")])
    assert "Reproduction mode: **blind** (the authors' scripts and the claimed values were withheld" in md


def _transient(entry_id, kind):
    return _result(entry_id=entry_id, retally_ran=False, error="APIError: x", transient=True, error_kind=kind)


def test_headline_flags_transient_failures():
    results = [
        _transient("a", "api_billing"),
        _transient("b", "api_unavailable"),
        _transient("c", "api_billing"),
        _result(entry_id="d"),
    ]
    md = report.render_markdown(results)
    expected = "**WARNING: 3 run(s) failed on transient errors (api_billing=2, api_unavailable=1)"
    assert f"{expected} and were not cached" in md
    assert "transient error (api_billing)" in md
    assert "WARNING: 3 run(s) failed on transient errors" in report.render_html(results)


def test_headline_has_no_transient_note_without_transient_rows():
    results = [_result(entry_id="a", retally_ran=False, error="RuntimeError: boom", error_kind="pipeline")]
    md = report.render_markdown(results)
    assert "transient" not in md
    assert "transient" not in report.render_html(results)


# ── Byte-stable rendering of single-reproducer results ──────────────────

_SNAPSHOTS = REPO_ROOT / "tests" / "fixtures" / "report_snapshots"


def _committed_results(name):
    import json

    path = REPO_ROOT / "benchmark" / "results" / f"{name}.json"
    return report.metrics.result_rows(json.loads(path.read_text(encoding="utf-8")))


def test_single_reproducer_reports_match_committed_snapshots():
    """Single-reproducer reports render byte-for-byte as they did before per-reproducer sections."""
    for name in ("eval-7papers-all-modes-2026-10-21", "baseline-2026-10-19"):
        results = _committed_results(name)
        assert report.render_markdown(results) == (_SNAPSHOTS / f"{name}.md").read_text(encoding="utf-8")
        assert report.render_html(results) == (_SNAPSHOTS / f"{name}.html").read_text(encoding="utf-8")


# ── Several reproducers in one report ───────────────────────────────────


def _two_reproducer_results():
    """A pipeline run (2 claims) and a claude-code run (3 claims) of the same paper, both modes."""
    pipeline = [
        _result(
            entry_id="p", mode="seeded", reproducer="pipeline", claim_details=[_cd("a", True), _cd("b", True)]
        ),
        _result(
            entry_id="p",
            mode="independent",
            reproducer="pipeline",
            agrees_with_paper=False,
            claim_details=[_cd("a", True), _cd("b", False)],
        ),
    ]
    claude_code = [
        _result(
            entry_id="p",
            mode="seeded",
            reproducer="claude-code",
            retally_ran=False,
            components={"parsed": True, "code_executed": False},
            claim_details=[_cd("a", True), _cd("b", False), _cd("c", False)],
        ),
        _result(
            entry_id="p",
            mode="independent",
            reproducer="claude-code",
            claim_details=[_cd("a", False), _cd("b", False), _cd("c", False)],
        ),
    ]
    return pipeline + claude_code


def test_multi_reproducer_report_renders_pooled_sections_per_reproducer():
    md = report.render_markdown(_two_reproducer_results())
    assert "Reproducer: **claude-code**, **pipeline**." in md
    # Verdicts: one section per (reproducer, mode), never one pooling both agents.
    for rep in ("claude-code", "pipeline"):
        for mode in ("seeded", "independent"):
            assert f"## Verdicts — {mode} · {rep} (among executed papers)" in md
    assert "## Verdicts — seeded (among executed papers)" not in md
    assert "## Verdicts — independent (among executed papers)" not in md
    seeded_cc = md.split("## Verdicts — seeded · claude-code")[1].split("##")[0]
    assert "Pipeline completed without crashing: **0 / 1**" in seeded_cc
    independent_pipeline = md.split("## Verdicts — independent · pipeline")[1].split("##")[0]
    assert "Agrees with the paper's stated values: **0 / 1**" in independent_pipeline
    # Totals lines, labelled per reproducer, in sorted order, no unlabelled pooled line.
    assert "- claude-code · Seeded: **1 / 3** claims passed" in md
    assert "- claude-code · Independent: **0 / 3** claims passed" in md
    assert "- claude-code · Lost without the scripts: **1**; gained: **0**" in md
    assert "- pipeline · Seeded: **2 / 2** claims passed" in md
    assert "- pipeline · Independent: **1 / 2** claims passed" in md
    assert "- pipeline · Lost without the scripts: **1**; gained: **0**" in md
    assert md.index("- claude-code · Seeded") < md.index("- pipeline · Seeded")
    assert "- Seeded:" not in md and "- Independent:" not in md and "- Lost without" not in md
    assert "3 / 5" not in md  # the pooled seeded total
    # Closeness lines and component tables per reproducer.
    assert "- **claude-code · dev · seeded**: 1 entries, 3 claims" in md
    assert "- **pipeline · dev · seeded**: 1 entries, 2 claims" in md
    assert "**dev · seeded**" not in md
    assert "## Per-component success — seeded · claude-code (executed papers only)" in md
    assert "## Per-component success — seeded · pipeline (executed papers only)" in md
    assert "## Per-component success — seeded (executed papers only)" not in md
    cc_components = md.split("## Per-component success — seeded · claude-code")[1].split("##")[0]
    assert "| code_executed | 0 | 1 | 0% |" in cc_components


def test_multi_reproducer_single_mode_report_splits_sections():
    results = [r for r in _two_reproducer_results() if r["mode"] == "seeded"]
    md = report.render_markdown(results)
    assert "Reproduction mode: **seeded**" in md
    assert "## Verdicts — claude-code (among executed papers)" in md
    assert "## Verdicts — pipeline (among executed papers)" in md
    assert "## Verdicts (among executed papers)" not in md
    assert "- **claude-code · dev**: 1 entries, 3 claims" in md
    assert "- **pipeline · dev**: 1 entries, 2 claims" in md
    assert "## Per-component success — claude-code (executed papers only)" in md
    assert "## Per-component success — pipeline (executed papers only)" in md


def test_multi_reproducer_html_headline_per_reproducer():
    html = report.render_html(_two_reproducer_results())
    assert "<strong>claude-code</strong> · Catalog size: <strong>2</strong> papers." in html
    assert "<strong>pipeline</strong> · Catalog size: <strong>2</strong> papers." in html
    assert "Catalog size: <strong>4</strong>" not in html
    assert html.index("<strong>claude-code</strong> ·") < html.index("<strong>pipeline</strong> ·")


# ── one reproducer on two models (ROADMAP 3.5) ───────────────────────────


def _pipeline_row_on(model: str, entry_id: str = "paper-a", mode: str = "seeded", passed: int = 1):
    details = [
        {
            "description": f"c{i}",
            "claim_type": "coefficient",
            "claimed": 1.0,
            "reproduced": 1.0,
            "tolerance": 0.02,
            "rel_err": 0.0,
            "passed": i < passed,
        }
        for i in range(2)
    ]
    usage = None
    if model:
        usage = {
            "by_model": {model: {"input_tokens": 10, "output_tokens": 5, "api_calls": 1}},
            "api_calls": 1,
            "estimated_usd": 0.001,
        }
    return {
        "entry_id": entry_id,
        "mode": mode,
        "reproducer": "pipeline",
        "skipped": False,
        "retally_ran": True,
        "agrees_with_paper": passed == 2,
        "n_claims_in_catalog": 2,
        "n_claims_with_paper_match": passed,
        "claim_details": details,
        "split": "holdout",
        "usage": usage,
    }


def test_model_of_reads_usage_by_model():
    from benchmark import metrics

    assert metrics.model_of(_pipeline_row_on("claude-opus-5-5")) == "claude-opus-5-5"
    assert metrics.model_of(_pipeline_row_on("")) is None
    assert metrics.model_of({"entry_id": "x", "mode": "seeded"}) is None
    two = _pipeline_row_on("claude-opus-5-5")
    two["usage"]["by_model"]["claude-sonnet-4-6"] = {"input_tokens": 1, "output_tokens": 1, "api_calls": 1}
    assert metrics.model_of(two) == "claude-opus-5-5 + claude-sonnet-4-6"


def test_disambiguate_reproducers_only_when_one_reproducer_spans_models():
    from benchmark import metrics

    single = [
        _pipeline_row_on("claude-opus-4-7"),
        _pipeline_row_on("claude-opus-4-7", mode="independent"),
        _pipeline_row_on("", entry_id="paper-b"),  # a skip or a pre-cost-accounting row
    ]
    assert metrics.disambiguate_reproducers(single) == single
    assert metrics.reproducers_present(metrics.disambiguate_reproducers(single)) == ["pipeline"]

    mixed = [
        _pipeline_row_on("claude-opus-4-7"),
        _pipeline_row_on("claude-opus-5-5", passed=2),
        _pipeline_row_on("", entry_id="paper-b"),
    ]
    out = metrics.disambiguate_reproducers(mixed)
    assert [r["reproducer"] for r in out] == [
        "pipeline (claude-opus-4-7)",
        "pipeline (claude-opus-5-5)",
        "pipeline (model unknown)",
    ]
    assert all(r["reproducer"] == "pipeline" for r in mixed)  # input untouched


def test_report_keeps_the_same_reproducer_on_two_models_apart():
    from benchmark import metrics

    rows = [
        _pipeline_row_on("claude-opus-4-7", mode="seeded", passed=1),
        _pipeline_row_on("claude-opus-4-7", mode="independent", passed=0),
        _pipeline_row_on("claude-opus-5-5", mode="seeded", passed=2),
        _pipeline_row_on("claude-opus-5-5", mode="independent", passed=2),
    ]
    md = report.render_markdown(rows)
    assert "Reproducer: **pipeline (claude-opus-4-7)**, **pipeline (claude-opus-5-5)**." in md
    assert "- pipeline (claude-opus-4-7) · Seeded: **1 / 2** claims passed" in md
    assert "- pipeline (claude-opus-5-5) · Seeded: **2 / 2** claims passed" in md
    assert "**3 / 4**" not in md  # never pooled across the two models
    gaps = metrics.mode_gaps(metrics.disambiguate_reproducers(rows))
    assert [(g.reproducer, g.seeded_passed, g.independent_passed) for g in gaps] == [
        ("pipeline (claude-opus-4-7)", 1, 0),
        ("pipeline (claude-opus-5-5)", 2, 2),
    ]
    html = report.render_html(rows)
    assert "pipeline (claude-opus-5-5)" in html
