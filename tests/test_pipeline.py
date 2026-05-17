"""Integration-level tests for ValidationPipeline."""

from pathlib import Path
from unittest.mock import MagicMock

from openra.models import (
    AuditStatus,
    Claim,
    ClaimType,
    ClaimValidationResult,
    Dataset,
    DatasetReference,
    DatasetSource,
    ExecutionResult,
    HyperparameterSpec,
    Paper,
    ValidationReport,
)
from openra.pipeline import ValidationPipeline


def _make_pipeline():
    """Build a pipeline with all components mocked out."""
    paper = Paper(
        title="Test Paper",
        claims=[Claim(description="accuracy", value=0.95, claim_type=ClaimType.ACCURACY)],
        dataset_references=[
            DatasetReference(name="dummy", source=DatasetSource.DIRECT_URL, url="http://example.com/ds.csv")
        ],
        methodology_summary="Train a logistic regression and report accuracy.",
    )
    dataset = Dataset(name="dummy", source_url="http://example.com/ds.csv", local_path=Path("/tmp/dummy"))
    exec_result = ExecutionResult(
        generated_code="print('RESULT:accuracy=0.95')",
        stdout="RESULT:accuracy=0.95\n",
        exit_code=0,
        outputs={"accuracy": 0.95},
    )
    claim_result = ClaimValidationResult(claim=paper.claims[0], reproduced_value=0.95, passed=True)
    report = ValidationReport(
        paper=paper,
        dataset=dataset,
        execution_result=exec_result,
        claim_results=[claim_result],
        overall_passed=True,
        summary="1 of 1 claims validated.",
    )

    parser = MagicMock()
    parser.parse_text.return_value = paper
    extractor = MagicMock()
    extractor.extract_claims.return_value = paper.claims
    extractor.extract_dataset_references.return_value = paper.dataset_references
    extractor.extract_methodology.return_value = paper.methodology_summary
    extractor.extract_hyperparameters.return_value = []
    registry = MagicMock()
    registry.lookup.return_value = paper.dataset_references[0]
    downloader = MagicMock()
    downloader.download.return_value = dataset
    generator = MagicMock()
    generator.generate.return_value = exec_result.generated_code
    executor = MagicMock()
    executor.execute.return_value = exec_result
    comparator = MagicMock()
    comparator.compare_all.return_value = [claim_result]
    reporter = MagicMock()
    reporter.build.return_value = report

    pipeline = ValidationPipeline(
        parser=parser,
        extractor=extractor,
        downloader=downloader,
        registry=registry,
        generator=generator,
        executor=executor,
        comparator=comparator,
        reporter=reporter,
    )
    return pipeline, report


def test_validate_returns_report():
    pipeline, expected_report = _make_pipeline()
    report = pipeline.validate("some text content")
    assert isinstance(report, ValidationReport)
    assert report.overall_passed


def test_pipeline_calls_components_in_order():
    pipeline, _ = _make_pipeline()
    pipeline.validate("some text content")
    pipeline.parser.parse_text.assert_called_once()
    pipeline.extractor.extract_claims.assert_called_once()
    pipeline.downloader.download.assert_called_once()
    pipeline.generator.generate.assert_called_once()
    pipeline.executor.execute.assert_called_once()
    pipeline.comparator.compare_all.assert_called_once()
    pipeline.reporter.build.assert_called_once()


def test_refinement_loop_retries_on_failure():
    pipeline, _ = _make_pipeline()
    fail_result = ExecutionResult(generated_code="bad code", exit_code=1, stderr="SyntaxError")
    ok_result = ExecutionResult(generated_code="good code", exit_code=0, outputs={"accuracy": 0.95})
    pipeline.executor.execute.side_effect = [fail_result, ok_result]
    pipeline.validate("some text content")
    assert pipeline.generator.refine.call_count == 1


def test_refinement_stops_at_max_refinements():
    pipeline, _ = _make_pipeline()
    pipeline.max_refinements = 2
    always_fail = ExecutionResult(generated_code="bad", exit_code=1, stderr="error", outputs={})
    pipeline.executor.execute.return_value = always_fail
    pipeline.validate("some text content")
    # Initial generate() + exactly max_refinements refine() calls when every
    # attempt fails.  Total executions = max_refinements + 1.
    assert pipeline.generator.refine.call_count == pipeline.max_refinements
    assert pipeline.executor.execute.call_count == pipeline.max_refinements + 1


def test_parse_paper_dispatches_arxiv_id():
    pipeline, _ = _make_pipeline()
    pipeline.validate("2301.00001")
    pipeline.parser.parse_arxiv.assert_called_once_with("2301.00001")


def test_parse_paper_dispatches_url():
    pipeline, _ = _make_pipeline()
    pipeline.validate("https://example.com/paper.pdf")
    pipeline.parser.parse_url.assert_called_once_with("https://example.com/paper.pdf")


def test_parse_paper_dispatches_doi():
    pipeline, _ = _make_pipeline()
    pipeline.validate("10.1145/1234567.1234568")
    pipeline.parser.parse_doi.assert_called_once_with("10.1145/1234567.1234568")


def test_validate_with_known_dataset_skips_ref_extraction():
    pipeline, _ = _make_pipeline()
    ref = DatasetReference(name="iris", source=DatasetSource.UCI, url="53")
    pipeline.validate_with_known_dataset("some text", ref)
    pipeline.extractor.extract_dataset_references.assert_not_called()
    pipeline.downloader.download.assert_called_once_with(ref)


# ── Claim-refinement loop ──────────────────────────────────────────────


def _claim_result(value: float, reproduced: float | None, *, passed: bool):
    """Build a ClaimValidationResult for an accuracy claim.

    Reproduced may be None to model a hard failure (no captured value);
    pass passed=False with reproduced=<some float> for a soft failure.
    """
    claim = Claim(description="accuracy", value=value, claim_type=ClaimType.ACCURACY)
    return ClaimValidationResult(
        claim=claim, reproduced_value=reproduced, tolerance=0.01, passed=passed, notes=""
    )


def _failing_claim_result(value: float, reproduced: float):
    return _claim_result(value, reproduced, passed=False)


def _passing_claim_result(value: float, reproduced: float):
    return _claim_result(value, reproduced, passed=True)


def _exec_ok(code: str, **outputs: float):
    """Build a successful ExecutionResult with the given RESULT outputs."""
    stdout = "".join(f"RESULT:{k}={v}\n" for k, v in outputs.items())
    return ExecutionResult(generated_code=code, stdout=stdout, exit_code=0, outputs=dict(outputs))


def _setup_soft_failure_then_pass(pipeline):
    """Configure mocks so the first run soft-fails and refinement passes."""
    fail_exec = _exec_ok("v1", accuracy=0.80)
    pass_exec = _exec_ok("v2", accuracy=0.95)
    pipeline.executor.execute.side_effect = [fail_exec, pass_exec]
    pipeline.comparator.compare_all.side_effect = [
        [_failing_claim_result(0.95, 0.80)],
        [_passing_claim_result(0.95, 0.95)],
    ]
    pipeline.generator.refine_for_claims.return_value = "v2"
    return fail_exec, pass_exec


def test_claim_refinement_runs_when_soft_failure(_pipeline=None):
    pipeline, _ = _make_pipeline()
    _setup_soft_failure_then_pass(pipeline)
    pipeline.validate("some text")
    pipeline.generator.refine_for_claims.assert_called_once()
    # Two executions: initial + one refinement.
    assert pipeline.executor.execute.call_count == 2


def test_claim_refinement_records_attempt_count():
    pipeline, _ = _make_pipeline()
    _, pass_exec = _setup_soft_failure_then_pass(pipeline)
    pipeline.validate("some text")
    assert pass_exec.claim_refinement_attempts == 1


def test_claim_refinement_stops_when_model_returns_identical_code():
    """If the generator returns the same script, treat it as 'gap is unreproducible'."""
    pipeline, _ = _make_pipeline()
    pipeline.generator.generate.return_value = "v1"
    fail_exec = ExecutionResult(
        generated_code="v1", stdout="RESULT:accuracy=0.80\n", exit_code=0, outputs={"accuracy": 0.80}
    )
    pipeline.executor.execute.return_value = fail_exec
    pipeline.comparator.compare_all.return_value = [_failing_claim_result(0.95, 0.80)]
    # Generator returns the SAME code — pipeline must stop, not re-execute.
    pipeline.generator.refine_for_claims.return_value = "v1"

    pipeline.validate("some text")
    # Exactly one refine call (the one that returned identical code).
    assert pipeline.generator.refine_for_claims.call_count == 1
    # Only one execution: the original.  The identical-code refinement
    # must NOT be re-executed.
    assert pipeline.executor.execute.call_count == 1


def test_claim_refinement_stops_when_outputs_unchanged():
    """No-progress detector: if reproduced values are identical to last attempt, stop."""
    pipeline, _ = _make_pipeline()
    pipeline.executor.execute.side_effect = [
        _exec_ok("v1", accuracy=0.80),
        _exec_ok("v2", accuracy=0.80),  # different code, same numbers
    ]
    pipeline.comparator.compare_all.return_value = [_failing_claim_result(0.95, 0.80)]
    pipeline.generator.refine_for_claims.return_value = "v2"

    pipeline.validate("some text")
    # First refinement happened; second was suppressed by no-progress.
    assert pipeline.generator.refine_for_claims.call_count == 1
    assert pipeline.executor.execute.call_count == 2


def test_claim_refinement_reverts_when_refinement_breaks_code():
    """A refinement that produces a crashing script must roll back, not stick."""
    pipeline, _ = _make_pipeline()
    ok_exec = _exec_ok("ok", accuracy=0.80)
    broken_exec = ExecutionResult(
        generated_code="broken", stdout="", stderr="SyntaxError", exit_code=1, outputs={}
    )
    pipeline.executor.execute.side_effect = [ok_exec, broken_exec]
    pipeline.comparator.compare_all.return_value = [_failing_claim_result(0.95, 0.80)]
    pipeline.generator.refine_for_claims.return_value = "broken"

    pipeline.validate("some text")
    # The report should be built from the last WORKING exec_result.
    built_with = pipeline.reporter.build.call_args[0][2]
    assert built_with is ok_exec


def test_claim_refinement_skips_hard_failures():
    """A claim with reproduced_value=None is not a soft failure; do not refine."""
    pipeline, _ = _make_pipeline()
    pipeline.executor.execute.return_value = _exec_ok("ok", other=0.80)
    pipeline.comparator.compare_all.return_value = [_claim_result(0.95, reproduced=None, passed=False)]

    pipeline.validate("some text")
    pipeline.generator.refine_for_claims.assert_not_called()


def test_claim_refinement_disabled_when_max_set_to_zero():
    pipeline, _ = _make_pipeline()
    pipeline.max_claim_refinements = 0
    pipeline.executor.execute.return_value = _exec_ok("v1", accuracy=0.80)
    pipeline.comparator.compare_all.return_value = [_failing_claim_result(0.95, 0.80)]

    pipeline.validate("some text")
    pipeline.generator.refine_for_claims.assert_not_called()


def test_claim_refinement_annotates_notes_when_gap_not_closed():
    """If refinement ran but the claim still fails, the note should say so."""
    pipeline, _ = _make_pipeline()
    fail_v1 = _exec_ok("v1", accuracy=0.80)
    fail_v2 = _exec_ok("v2", accuracy=0.82)
    pipeline.executor.execute.side_effect = [fail_v1, fail_v2, fail_v2]
    pipeline.comparator.compare_all.side_effect = [
        [_failing_claim_result(0.95, 0.80)],
        [_failing_claim_result(0.95, 0.82)],
        [_failing_claim_result(0.95, 0.82)],
    ]
    pipeline.generator.refine_for_claims.side_effect = ["v2", "v2"]  # second returns identical
    pipeline.max_claim_refinements = 3

    pipeline.validate("some text")
    final_claims = pipeline.reporter.build.call_args[0][3]
    assert not final_claims[0].passed
    # The annotation tells the reader refinement was attempted.
    assert "claim-targeted refinement" in final_claims[0].notes


# ── Hyperparameter audit integration ───────────────────────────────────


def test_pipeline_calls_extract_hyperparameters():
    pipeline, _ = _make_pipeline()
    pipeline.validate("some text")
    pipeline.extractor.extract_hyperparameters.assert_called_once()


def test_pipeline_runs_audit_after_refinement():
    pipeline, _ = _make_pipeline()
    # Generated code uses C=1.0, but the spec demands C=0.5 — audit must
    # see the MISMATCH and store it on the ExecutionResult that goes to
    # the reporter.
    code = "LogisticRegression(C=1.0)"
    pipeline.generator.generate.return_value = code
    pipeline.executor.execute.return_value = ExecutionResult(
        generated_code=code,
        stdout="RESULT:accuracy=0.95\n",
        exit_code=0,
        outputs={"accuracy": 0.95},
    )
    pipeline.extractor.extract_hyperparameters.return_value = [
        HyperparameterSpec(name="C", value=0.5, context="paper says C=0.5"),
    ]

    pipeline.validate("some text")
    exec_result = pipeline.reporter.build.call_args[0][2]
    assert len(exec_result.hyperparameter_audits) == 1
    assert exec_result.hyperparameter_audits[0].status is AuditStatus.MISMATCH


def test_pipeline_audit_runs_on_final_code_not_initial():
    """If refinement changes the code, the audit must see the FINAL version."""
    pipeline, _ = _make_pipeline()
    pipeline.generator.generate.return_value = "LogisticRegression(C=0.1)"
    pipeline.generator.refine_for_claims.return_value = "LogisticRegression(C=1.0)"
    pipeline.executor.execute.side_effect = [
        ExecutionResult(
            generated_code="LogisticRegression(C=0.1)",
            stdout="RESULT:accuracy=0.50\n",
            exit_code=0,
            outputs={"accuracy": 0.50},
        ),
        ExecutionResult(
            generated_code="LogisticRegression(C=1.0)",
            stdout="RESULT:accuracy=0.95\n",
            exit_code=0,
            outputs={"accuracy": 0.95},
        ),
    ]
    pipeline.comparator.compare_all.side_effect = [
        [_failing_claim_result(0.95, 0.50)],
        [_passing_claim_result(0.95, 0.95)],
    ]
    pipeline.extractor.extract_hyperparameters.return_value = [HyperparameterSpec(name="C", value=1.0)]

    pipeline.validate("some text")
    exec_result = pipeline.reporter.build.call_args[0][2]
    [audit] = exec_result.hyperparameter_audits
    # The audit was run on the refined code (C=1.0), not the initial (C=0.1).
    assert audit.status is AuditStatus.MATCH


def test_pipeline_audit_empty_when_no_specs():
    """Audit must be a no-op when the extractor found no hyperparameters."""
    pipeline, _ = _make_pipeline()
    pipeline.extractor.extract_hyperparameters.return_value = []
    pipeline.validate("some text")
    exec_result = pipeline.reporter.build.call_args[0][2]
    assert exec_result.hyperparameter_audits == []
