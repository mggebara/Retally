"""Tests for ResultComparator."""

import pytest

from openra.models import Claim, ClaimType
from openra.validation.comparator import ResultComparator


@pytest.fixture
def comparator():
    return ResultComparator(default_tolerance=0.01)


def _claim(description, value, claim_type=ClaimType.ACCURACY):
    return Claim(description=description, value=value, claim_type=claim_type)


def test_compare_exact_match_passes(comparator):
    claim = _claim("test accuracy", 0.95)
    result = comparator.compare(claim, reproduced_value=0.95)
    assert result.passed


def test_compare_within_tolerance_passes(comparator):
    claim = _claim("test accuracy", 0.95)
    result = comparator.compare(claim, reproduced_value=0.9499)
    assert result.passed


def test_compare_outside_tolerance_fails(comparator):
    claim = _claim("test accuracy", 0.95)
    result = comparator.compare(claim, reproduced_value=0.90)
    assert not result.passed


def test_compare_none_reproduced_fails(comparator):
    claim = _claim("accuracy", 0.95)
    result = comparator.compare(claim, reproduced_value=None)
    assert not result.passed
    assert result.reproduced_value is None


def test_compare_all_matches_by_key(comparator):
    claims = [
        _claim("test accuracy", 0.95),
        _claim("f1 score", 0.88, ClaimType.F1_SCORE),
    ]
    outputs = {"test_accuracy": 0.950, "f1_score": 0.882}
    results = comparator.compare_all(claims, outputs)
    assert len(results) == 2
    # f1 score 0.882 vs 0.88: relative error = 0.002/0.88 ≈ 0.0023 < 0.01
    assert all(r.passed for r in results)


def test_normalise_key(comparator):
    assert comparator._normalise_key("Test Accuracy") == comparator._normalise_key("test_accuracy")
    assert comparator._normalise_key("F1-Score") == comparator._normalise_key("f1_score")


def test_compare_percent_vs_decimal(comparator):
    """Paper says 95.0% but code outputs 0.95 — should still pass."""
    claim = _claim("accuracy", 95.0)
    claim.unit = "%"
    result = comparator.compare(claim, reproduced_value=0.95)
    assert result.passed
