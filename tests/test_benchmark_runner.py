"""Tests for the benchmark runner.

The runner walks a catalog, calls ValidationPipeline.validate on each
paper, and scores the result.  These tests inject a fake pipeline so
no API key / Docker / network is needed.
"""

from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock

import pytest

from tests._loaders import REPO_ROOT, load_module_from_path

bschema = load_module_from_path("benchmark.schema", REPO_ROOT / "benchmark" / "schema.py")
runner = load_module_from_path("benchmark.runner", REPO_ROOT / "benchmark" / "runner.py")


# ── Helpers ─────────────────────────────────────────────────────────────


def _entry(**overrides):
    """Build a BenchmarkEntry with sensible defaults for testing."""
    base = {
        "id": "test",
        "i4r_report_url": "https://example.org/r",
        "language": bschema.Language.PYTHON,
        "outcome_label": bschema.OutcomeLabel.REPRODUCIBLE,
        "paper": bschema.PaperRef(source="raw paper text"),
    }
    base.update(overrides)
    return bschema.BenchmarkEntry(**base)


def _claim(value: float, repro: float | None, *, passed: bool):
    """Build a ClaimValidationResult-shaped mock."""
    from openra.models import Claim, ClaimType, ClaimValidationResult

    return ClaimValidationResult(
        claim=Claim(description="x", value=value, claim_type=ClaimType.OTHER),
        reproduced_value=repro,
        tolerance=0.01,
        passed=passed,
    )


def _fake_report(*, overall_passed=True, claim_results=None, exit_code=0):
    """Build a ValidationReport-shaped mock the runner can score."""
    from openra.models import Dataset, ExecutionResult, Paper, ValidationReport

    paper = Paper(title="t", claims=[MagicMock()], dataset_references=[MagicMock()])
    dataset = Dataset(name="d", source_url="", local_path=Path("/tmp/d"))
    exec_result = ExecutionResult(
        generated_code="print('hi')",
        exit_code=exit_code,
        outputs={"x": 1.0},
    )
    return ValidationReport(
        paper=paper,
        dataset=dataset,
        execution_result=exec_result,
        claim_results=claim_results or [],
        overall_passed=overall_passed,
    )


def _pipeline_factory_returning(report):
    """Build a zero-arg factory that returns a pipeline whose validate() yields ``report``."""
    pipeline = MagicMock()
    pipeline.validate.return_value = report
    return lambda: pipeline


# ── Skip paths ──────────────────────────────────────────────────────────


def test_skip_out_of_scope(tmp_path):
    entry = _entry(out_of_scope_reason="Original is Stata", language=bschema.Language.STATA)
    [result] = runner.run_benchmark([entry], cache_dir=tmp_path)
    assert result.skipped is True
    assert result.skip_reason is runner.SkipReason.OUT_OF_SCOPE
    assert result.openra_ran is None


def test_skip_language_not_yet_supported(tmp_path):
    entry = _entry(language=bschema.Language.R)
    [result] = runner.run_benchmark([entry], cache_dir=tmp_path)
    assert result.skipped is True
    assert result.skip_reason is runner.SkipReason.LANGUAGE_UNSUPPORTED


def test_out_of_scope_reason_beats_language_check(tmp_path):
    """If both apply, OUT_OF_SCOPE wins — explicit beats categorical."""
    entry = _entry(
        language=bschema.Language.R,
        out_of_scope_reason="explicitly skipped",
    )
    [result] = runner.run_benchmark([entry], cache_dir=tmp_path)
    assert result.skip_reason is runner.SkipReason.OUT_OF_SCOPE


def test_skip_when_pipeline_construction_fails(tmp_path):
    """No API key on the host → record a NO_API_KEY skip, don't crash."""

    def factory():
        raise RuntimeError("ANTHROPIC_API_KEY is not set")

    entry = _entry()
    [result] = runner.run_benchmark([entry], pipeline_factory=factory, cache_dir=tmp_path)
    assert result.skipped is True
    assert result.skip_reason is runner.SkipReason.NO_API_KEY
    assert "ANTHROPIC_API_KEY" in (result.error or "")


# ── Happy path ──────────────────────────────────────────────────────────


def test_pipeline_runs_and_passes_paper_claim(tmp_path):
    entry = _entry()
    report = _fake_report(
        overall_passed=True,
        claim_results=[_claim(0.95, 0.95, passed=True)],
    )
    [result] = runner.run_benchmark(
        [entry],
        pipeline_factory=_pipeline_factory_returning(report),
        cache_dir=tmp_path,
    )
    assert result.skipped is False
    assert result.openra_ran is True
    assert result.agrees_with_paper is True
    assert result.n_claims_with_paper_match == 1


def test_pipeline_raises_records_error_not_crash(tmp_path):
    pipeline = MagicMock()
    pipeline.validate.side_effect = RuntimeError("boom")
    [result] = runner.run_benchmark([_entry()], pipeline_factory=lambda: pipeline, cache_dir=tmp_path)
    assert result.openra_ran is False
    assert "boom" in (result.error or "")


# ── I4R-agreement scoring ──────────────────────────────────────────────


def test_agrees_with_i4r_when_value_matches(tmp_path):
    entry = _entry(
        original_claims=[bschema.OriginalClaim(description="x", value=0.5, claim_type="coefficient")],
        i4r_replicator_findings=[
            bschema.ReplicatorFinding(
                claim_id=0, reproduced_value=0.501, outcome=bschema.FindingOutcome.MATCHES
            )
        ],
    )
    # OpenRA produced 0.501 too — exactly the I4R value.
    report = _fake_report(
        overall_passed=False,  # may not match paper, but the I4R agreement is what we're testing
        claim_results=[_claim(0.5, 0.501, passed=False)],
    )
    [result] = runner.run_benchmark(
        [entry],
        pipeline_factory=_pipeline_factory_returning(report),
        cache_dir=tmp_path,
    )
    assert result.agrees_with_i4r is True
    assert result.n_claims_with_i4r_match == 1


def test_disagrees_with_i4r_when_value_differs(tmp_path):
    entry = _entry(
        original_claims=[bschema.OriginalClaim(description="x", value=0.5, claim_type="coefficient")],
        i4r_replicator_findings=[
            bschema.ReplicatorFinding(
                claim_id=0,
                reproduced_value=0.6,
                outcome=bschema.FindingOutcome.DOES_NOT_MATCH,
            )
        ],
    )
    report = _fake_report(
        overall_passed=True,  # OpenRA matched the paper value at 0.5
        claim_results=[_claim(0.5, 0.5, passed=True)],
    )
    [result] = runner.run_benchmark(
        [entry],
        pipeline_factory=_pipeline_factory_returning(report),
        cache_dir=tmp_path,
    )
    # OpenRA agrees with the paper but disagrees with the I4R replicator —
    # the meaningful "reproduced a non-robust finding" signal.
    assert result.agrees_with_paper is True
    assert result.agrees_with_i4r is False


def test_agrees_with_i4r_none_when_no_finding_has_a_value(tmp_path):
    entry = _entry(
        original_claims=[bschema.OriginalClaim(description="x", value=0.5, claim_type="other")],
        i4r_replicator_findings=[
            bschema.ReplicatorFinding(
                claim_id=0,
                reproduced_value=None,
                outcome=bschema.FindingOutcome.NOT_ATTEMPTED,
            )
        ],
    )
    report = _fake_report(
        claim_results=[_claim(0.5, 0.5, passed=True)],
    )
    [result] = runner.run_benchmark(
        [entry],
        pipeline_factory=_pipeline_factory_returning(report),
        cache_dir=tmp_path,
    )
    assert result.agrees_with_i4r is None


# ── Component metrics ──────────────────────────────────────────────────


def test_components_reflect_report_state(tmp_path):
    report = _fake_report()
    [result] = runner.run_benchmark(
        [_entry()],
        pipeline_factory=_pipeline_factory_returning(report),
        cache_dir=tmp_path,
    )
    c = result.components
    assert c.parsed is True
    assert c.claims_extracted is True
    assert c.dataset_extracted is True
    assert c.dataset_downloaded is True
    assert c.code_generated is True
    assert c.code_executed is True


# ── Cache ──────────────────────────────────────────────────────────────


def test_cache_hit_avoids_pipeline_call(tmp_path):
    entry = _entry()
    pipeline = MagicMock()
    pipeline.validate.return_value = _fake_report()
    factory = MagicMock(return_value=pipeline)

    # First call: pipeline is built once and invoked.
    runner.run_benchmark([entry], pipeline_factory=factory, cache_dir=tmp_path)
    assert factory.call_count == 1
    assert pipeline.validate.call_count == 1

    # Second call: cache hits, pipeline is NOT built or invoked.
    [result] = runner.run_benchmark([entry], pipeline_factory=factory, cache_dir=tmp_path)
    assert factory.call_count == 1
    assert pipeline.validate.call_count == 1
    assert result.cached is True


def test_cache_disabled_via_use_cache_flag(tmp_path):
    entry = _entry()
    pipeline = MagicMock()
    pipeline.validate.return_value = _fake_report()
    factory = MagicMock(return_value=pipeline)

    runner.run_benchmark([entry], pipeline_factory=factory, cache_dir=tmp_path)
    runner.run_benchmark([entry], pipeline_factory=factory, cache_dir=tmp_path, use_cache=False)
    assert pipeline.validate.call_count == 2


def test_cache_invalidates_when_entry_changes(tmp_path):
    pipeline = MagicMock()
    pipeline.validate.return_value = _fake_report()
    factory = MagicMock(return_value=pipeline)

    runner.run_benchmark(
        [_entry(id="x", paper=bschema.PaperRef(source="A"))],
        pipeline_factory=factory,
        cache_dir=tmp_path,
    )
    # Different paper source → different cache key → re-runs.
    runner.run_benchmark(
        [_entry(id="x", paper=bschema.PaperRef(source="B"))],
        pipeline_factory=factory,
        cache_dir=tmp_path,
    )
    assert pipeline.validate.call_count == 2


# ── Persistence ────────────────────────────────────────────────────────


def test_write_results_round_trips(tmp_path):
    results = [
        runner.BenchmarkResult(
            entry_id="r1",
            skipped=True,
            skip_reason=runner.SkipReason.OUT_OF_SCOPE,
        ),
        runner.BenchmarkResult(
            entry_id="r2",
            openra_ran=True,
            agrees_with_paper=True,
            agrees_with_i4r=None,
            n_claims_in_catalog=1,
            n_claims_with_paper_match=1,
        ),
    ]
    out = tmp_path / "results.json"
    runner.write_results(results, out)
    assert out.exists()
    import json

    decoded = json.loads(out.read_text(encoding="utf-8"))
    assert len(decoded) == 2
    assert decoded[0]["skip_reason"] == "out_of_scope"
    assert decoded[1]["openra_ran"] is True


def test_results_dir_created_on_write(tmp_path):
    nested = tmp_path / "deep" / "results.json"
    runner.write_results([], nested)
    assert nested.exists()


# ── End-to-end via placeholder fixtures ───────────────────────────────


def test_runner_on_placeholder_fixture_catalog(tmp_path):
    """The three placeholder fixtures walk through the runner cleanly.

    With no pipeline factory injected and ANTHROPIC_API_KEY unset, every
    entry should produce a sensible skip result without exceptions
    reaching the test.  Fixtures live under tests/fixtures/ so the real
    ``benchmark/papers/`` catalog isn't polluted by placeholder noise.
    """
    monkeypatch = pytest.MonkeyPatch()
    fixtures = REPO_ROOT / "tests" / "fixtures" / "benchmark_placeholders"
    try:
        monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)
        catalog = bschema.load_catalog(fixtures)
        results = runner.run_benchmark(catalog, cache_dir=tmp_path)
    finally:
        monkeypatch.undo()

    by_id = {r.entry_id: r for r in results}
    # Out-of-scope entry → OUT_OF_SCOPE skip.
    assert by_id["_placeholder_stata_out_of_scope"].skip_reason is runner.SkipReason.OUT_OF_SCOPE
    # R entry → LANGUAGE_UNSUPPORTED skip (R prompts exist but the runner
    # routing still treats non-Python as unsupported until PR 6).
    assert by_id["_placeholder_r_example"].skip_reason is runner.SkipReason.LANGUAGE_UNSUPPORTED
    # Python entry → NO_API_KEY skip (no key in env in test sandbox).
    assert by_id["_placeholder_python_example"].skip_reason is runner.SkipReason.NO_API_KEY
