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


# ── Econometric claim types (PR 5) ─────────────────────────────────────


def test_coefficient_tolerance_is_2_percent(comparator):
    """COEFFICIENT claims get a slightly looser tolerance than ACCURACY.

    Econ papers round coefficients more aggressively, so 2% relative is
    the calibrated default.  A 0.32 vs 0.325 disagreement (1.5% rel)
    must pass.
    """
    claim = Claim(
        description="treatment effect on log earnings",
        value=0.32,
        claim_type=ClaimType.COEFFICIENT,
    )
    result = comparator.compare(claim, reproduced_value=0.325)
    assert result.passed
    assert result.tolerance == 0.02


def test_coefficient_outside_tolerance_fails(comparator):
    claim = Claim(description="β", value=0.32, claim_type=ClaimType.COEFFICIENT)
    # 2.5% relative — outside 2% tolerance.
    result = comparator.compare(claim, reproduced_value=0.328)
    assert not result.passed


def test_standard_error_tolerance_is_5_percent(comparator):
    """STANDARD_ERROR is looser still — SEs are heavily rounded."""
    claim = Claim(
        description="SE on β",
        value=0.080,
        claim_type=ClaimType.STANDARD_ERROR,
    )
    result = comparator.compare(claim, reproduced_value=0.083)  # 3.75% rel
    assert result.passed
    assert result.tolerance == 0.05


def test_r_squared_tolerance_is_1_percent(comparator):
    """R² is usually 3 decimal places; 1% matches typical precision."""
    claim = Claim(description="R²", value=0.413, claim_type=ClaimType.R_SQUARED)
    # 0.5% relative — inside 1%.
    result = comparator.compare(claim, reproduced_value=0.415)
    assert result.passed
    assert result.tolerance == 0.01


def test_new_claim_types_serialize_to_lowercase_strings():
    """Confirm the enum values match the JSON strings the extractor will emit."""
    assert ClaimType.COEFFICIENT.value == "coefficient"
    assert ClaimType.STANDARD_ERROR.value == "standard_error"
    assert ClaimType.R_SQUARED.value == "r_squared"
