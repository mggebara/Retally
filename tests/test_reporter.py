"""Tests for ValidationReporter."""

from pathlib import Path

from openra.models import (
    Claim,
    ClaimType,
    ClaimValidationResult,
    Dataset,
    ExecutionResult,
    Paper,
)
from openra.validation.reporter import ValidationReporter


def _paper() -> Paper:
    return Paper(title="Test Paper")


def _dataset() -> Dataset:
    return Dataset(name="dummy", source_url="http://example.com/ds.csv", local_path=Path("/tmp/dummy"))


def _exec_result() -> ExecutionResult:
    return ExecutionResult(generated_code="print('hi')", exit_code=0)


def test_build_with_empty_claims_is_not_passed():
    reporter = ValidationReporter()
    report = reporter.build(_paper(), _dataset(), _exec_result(), claim_results=[])
    # A paper with no extracted claims hasn't been validated against anything,
    # so we must not call it PASSED.
    assert report.overall_passed is False
    assert "No claims" in report.summary


def test_build_with_all_claims_passing():
    reporter = ValidationReporter()
    claim = Claim(description="accuracy", value=0.95, claim_type=ClaimType.ACCURACY)
    cr = ClaimValidationResult(claim=claim, reproduced_value=0.95, passed=True)
    report = reporter.build(_paper(), _dataset(), _exec_result(), claim_results=[cr])
    assert report.overall_passed is True
    assert "1 of 1" in report.summary


def test_build_with_one_failing_claim():
    reporter = ValidationReporter()
    c1 = Claim(description="accuracy", value=0.95, claim_type=ClaimType.ACCURACY)
    c2 = Claim(description="f1", value=0.90, claim_type=ClaimType.F1_SCORE)
    r1 = ClaimValidationResult(claim=c1, reproduced_value=0.95, passed=True)
    r2 = ClaimValidationResult(claim=c2, reproduced_value=0.50, passed=False)
    report = reporter.build(_paper(), _dataset(), _exec_result(), claim_results=[r1, r2])
    assert report.overall_passed is False
    assert "1 of 2" in report.summary
    assert "f1" in report.summary
