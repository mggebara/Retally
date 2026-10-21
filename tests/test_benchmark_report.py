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
