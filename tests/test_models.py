"""Tests for the shared dataclass models."""

from retally.models import (
    Claim,
    ClaimType,
    ClaimValidationResult,
    DatasetReference,
    DatasetSource,
    ExecutionResult,
    Language,
    Paper,
)


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


def test_paper_default_language_is_python():
    """Existing callers that don't set language must get PYTHON.

    This is the contract that makes the seam introduction
    byte-identical for the existing demo reports and tests.
    """
    assert Paper(title="x").language is Language.PYTHON


def test_execution_result_default_language_is_python():
    assert ExecutionResult(generated_code="x").language is Language.PYTHON


def test_language_enum_round_trips_to_string_values():
    # Used by benchmark catalog YAML and the markdown code fence —
    # check the values are stable and lowercase.
    assert Language.PYTHON.value == "python"
    assert Language.R.value == "r"
    assert Language.STATA.value == "stata"
    assert Language.UNKNOWN.value == "unknown"
