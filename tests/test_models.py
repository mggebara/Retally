"""Tests for the shared dataclass models."""

from paper_validator.models import (
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
from pathlib import Path


def test_claim_defaults():
    claim = Claim(description="test accuracy", value=0.95)
    assert claim.claim_type == ClaimType.OTHER
    assert claim.unit is None
    assert claim.context == ""


def test_paper_defaults():
    paper = Paper(title="A Study")
    assert paper.authors == []
    assert paper.claims == []
    assert paper.dataset_references == []


def test_dataset_reference_defaults():
    ref = DatasetReference(name="UCI Adult")
    assert ref.source == DatasetSource.UNKNOWN
    assert ref.url is None


def test_execution_result_outputs_empty_by_default():
    result = ExecutionResult(generated_code="print('hello')")
    assert result.outputs == {}
    assert not result.timed_out


def test_claim_validation_result_failed_by_default():
    claim = Claim(description="accuracy", value=0.9)
    result = ClaimValidationResult(claim=claim, reproduced_value=None)
    assert not result.passed
