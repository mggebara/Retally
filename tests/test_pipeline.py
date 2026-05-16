"""Integration-level tests for ValidationPipeline."""

from pathlib import Path
from unittest.mock import MagicMock

from openra.models import (
    Claim,
    ClaimType,
    ClaimValidationResult,
    Dataset,
    DatasetReference,
    DatasetSource,
    ExecutionResult,
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
