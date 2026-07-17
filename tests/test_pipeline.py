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
    extractor.extract_code_references.return_value = []
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

    code_downloader = MagicMock()
    code_downloader.download_all.return_value = []

    pipeline = ValidationPipeline(
        parser=parser,
        extractor=extractor,
        downloader=downloader,
        registry=registry,
        generator=generator,
        executor=executor,
        comparator=comparator,
        reporter=reporter,
        code_downloader=code_downloader,
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


def test_validate_with_dataset_reference_skips_ref_extraction():
    pipeline, _ = _make_pipeline()
    ref = DatasetReference(name="iris", source=DatasetSource.UCI, url="53")
    pipeline.validate("some text", dataset_reference=ref)
    pipeline.extractor.extract_dataset_references.assert_not_called()
    pipeline.downloader.download.assert_called_once_with(ref)


def test_validate_without_dataset_reference_runs_extraction():
    """Sanity: the default code path still calls extract_dataset_references."""
    pipeline, _ = _make_pipeline()
    pipeline.validate("some text")
    pipeline.extractor.extract_dataset_references.assert_called_once()


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


# ── Paper-linked code baseline integration ─────────────────────────────


def test_pipeline_calls_extract_code_references_by_default():
    pipeline, _ = _make_pipeline()
    pipeline.validate("some text")
    pipeline.extractor.extract_code_references.assert_called_once()


def test_pipeline_skips_code_extraction_when_disabled():
    pipeline, _ = _make_pipeline()
    pipeline.include_code_references = False
    pipeline.validate("some text")
    pipeline.extractor.extract_code_references.assert_not_called()
    pipeline.code_downloader.download_all.assert_not_called()


def test_pipeline_forwards_reference_files_to_generator(tmp_path):
    """When code is found, cloned, and selectable, generate() must receive it."""
    from openra.models import CodeReference, CodeReferenceSource

    pipeline, _ = _make_pipeline()
    # Extractor finds a GitHub repo.
    ref = CodeReference(
        url="https://github.com/openai/baselines",
        source=CodeReferenceSource.GITHUB,
    )
    pipeline.extractor.extract_code_references.return_value = [ref]

    # Stand up a tiny fake "clone" on disk so the selector has something
    # to pick up.  This is realistic: the downloader's job ends at the
    # filesystem boundary.
    clone_dir = tmp_path / "openai__baselines"
    clone_dir.mkdir()
    (clone_dir / "train.py").write_text("# real reference code\n")
    pipeline.code_downloader.download_all.return_value = [
        CodeReference(
            url=ref.url,
            source=ref.source,
            description=ref.description,
            local_path=clone_dir,
        )
    ]

    pipeline.validate("some text")

    # generate() received a non-empty reference_files kwarg.
    [call] = pipeline.generator.generate.call_args_list
    files = call.kwargs.get("reference_files") or (call.args[2] if len(call.args) > 2 else None)
    assert files is not None
    assert len(files) == 1
    assert files[0].relative_path == "train.py"


def test_pipeline_records_resolved_references_on_paper():
    """paper.code_references must be updated even when downloads fail."""
    from openra.models import CodeReference, CodeReferenceSource

    pipeline, _ = _make_pipeline()
    ref = CodeReference(
        url="https://gitlab.com/x/y",
        source=CodeReferenceSource.GITLAB,
    )
    pipeline.extractor.extract_code_references.return_value = [ref]
    # GitLab is recognised but not supported → downloader returns the
    # reference with local_path=None.
    pipeline.code_downloader.download_all.return_value = [ref]

    pipeline.validate("some text")

    paper_arg = pipeline.reporter.build.call_args[0][0]
    assert paper_arg.code_references == [ref]


def test_pipeline_no_clone_when_no_references_found():
    pipeline, _ = _make_pipeline()
    pipeline.extractor.extract_code_references.return_value = []
    pipeline.validate("some text")
    pipeline.code_downloader.download_all.assert_not_called()


# ── _outputs_close (refinement no-progress detector) ─────────────────


def test_outputs_close_treats_float_jitter_as_no_progress():
    """The refinement loop used to compare output dicts with ``==``, so
    0.95000000001 vs 0.95 looked like progress and burned a slot.
    """
    from openra.pipeline import _outputs_close

    a = {"accuracy": 0.95}
    b = {"accuracy": 0.9500000001}
    assert _outputs_close(a, b)


def test_outputs_close_real_change_is_not_close():
    from openra.pipeline import _outputs_close

    assert not _outputs_close({"accuracy": 0.90}, {"accuracy": 0.95})


def test_outputs_close_different_keys_are_not_close():
    """Adding or removing a metric counts as real progress even when the
    overlap matches.  A refinement that produces a new RESULT line is
    new information; don't collapse it.
    """
    from openra.pipeline import _outputs_close

    assert not _outputs_close({"accuracy": 0.95}, {"accuracy": 0.95, "f1": 0.92})


# ── Language-aware executor dispatch ─────────────────────────────────


def _make_pipeline_with_r_executor():
    """Variant of _make_pipeline that also wires an R executor.

    The two executors record their calls separately so the language-
    routing tests can assert which one ran without touching the rest of
    the mock setup.
    """
    pipeline, report = _make_pipeline()
    pipeline.r_executor = MagicMock()
    pipeline.r_executor.execute.return_value = report.execution_result
    return pipeline, report


def test_python_paper_routes_to_python_executor():
    """A Python paper must invoke executor.execute, not r_executor.execute."""
    from openra.models import Language

    pipeline, _ = _make_pipeline_with_r_executor()
    pipeline.parser.parse_text.return_value.language = Language.PYTHON

    pipeline.validate("some text")
    assert pipeline.executor.execute.called
    assert not pipeline.r_executor.execute.called


def test_r_paper_routes_to_r_executor():
    """An R paper must invoke r_executor.execute, not executor.execute."""
    from openra.models import Language

    pipeline, _ = _make_pipeline_with_r_executor()
    pipeline.parser.parse_text.return_value.language = Language.R

    pipeline.validate("some text")
    assert pipeline.r_executor.execute.called
    assert not pipeline.executor.execute.called


def test_r_paper_without_r_executor_raises_clearly():
    """When r_executor is None and an R paper arrives, the error must
    explain how to fix it — not surface as a generic AttributeError.
    """
    import pytest

    from openra.models import Language

    pipeline, _ = _make_pipeline()
    assert pipeline.r_executor is None
    pipeline.parser.parse_text.return_value.language = Language.R

    with pytest.raises(RuntimeError, match="no R executor configured"):
        pipeline.validate("some text")


# ── Pinned-claims override ────────────────────────────────────────────


def test_validate_with_claims_skips_extraction():
    """Pinned claims must bypass the extraction call — it's the single
    most expensive LLM call in the pipeline, and skipping it also makes
    repeat runs score against a stable claim set."""
    pipeline, _ = _make_pipeline()
    pinned = [Claim(description="beta", value=3.713, claim_type=ClaimType.COEFFICIENT)]
    pipeline.validate("some text", claims=pinned)
    pipeline.extractor.extract_claims.assert_not_called()
    # The comparator is scored against exactly the pinned set.
    (claims_arg, _), _ = pipeline.comparator.compare_all.call_args
    assert claims_arg == pinned


def test_validate_without_claims_still_extracts():
    pipeline, _ = _make_pipeline()
    pipeline.validate("some text")
    pipeline.extractor.extract_claims.assert_called_once()


def test_pipeline_forwards_package_scripts_to_generator(tmp_path):
    """Analysis scripts inside the downloaded dataset must reach generate()."""
    pipeline, _ = _make_pipeline()

    # A replication-package-shaped dataset: data + the authors' scripts.
    package = tmp_path / "zenodo_pkg"
    package.mkdir()
    (package / "districts.csv").write_text("id,lum\n1,2.0\n")
    (package / "main_tables.R").write_text("feols(lum ~ conflict | state, data)\n")
    pipeline.downloader.download.return_value = Dataset(
        name="replication package",
        source_url="https://zenodo.org/records/1",
        local_path=package,
    )

    pipeline.validate("some text")

    [call] = pipeline.generator.generate.call_args_list
    scripts = call.kwargs.get("package_scripts")
    assert scripts is not None
    assert [s.relative_path for s in scripts] == ["main_tables.R"]


def test_pipeline_passes_no_package_scripts_for_registry_datasets():
    """The classic single-CSV flow must see package_scripts=None, not []."""
    pipeline, _ = _make_pipeline()
    pipeline.validate("some text")
    [call] = pipeline.generator.generate.call_args_list
    assert call.kwargs.get("package_scripts") is None
