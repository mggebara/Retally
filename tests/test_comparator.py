"""Tests for ResultComparator."""

import pytest

from retally.models import Claim, ClaimType, ReproductionMode
from retally.validation.comparator import ResultComparator, TolerancePolicy


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


def test_failed_claim_records_relative_error_in_notes(comparator):
    """A failure used to land with empty notes, leaving readers of the
    report to dig through stdout to understand why.  We now explain the
    gap inline so a glance at the report is enough.
    """
    claim = Claim(description="accuracy", value=0.95, claim_type=ClaimType.ACCURACY)
    result = comparator.compare(claim, reproduced_value=0.80)  # ~15.8% off
    assert not result.passed
    assert "reproduced=0.8" in result.notes
    assert "claimed=0.95" in result.notes
    assert "tolerance" in result.notes


def test_passing_claim_has_no_failure_notes(comparator):
    """The new diagnostic note must only fire on failures — passing claims
    keep their existing empty-notes contract (the dashboard treats any
    non-empty note as a yellow flag, so silence on a pass matters).
    """
    claim = Claim(description="accuracy", value=0.95, claim_type=ClaimType.ACCURACY)
    result = comparator.compare(claim, reproduced_value=0.951)
    assert result.passed
    assert result.notes == ""


# ── Per-mode tolerance policy ─────────────────────────────────────────


def _coef(value, se=None):
    return Claim(description="beta", value=value, claim_type=ClaimType.COEFFICIENT, standard_error=se)


def test_seeded_mode_ignores_standard_error(comparator):
    """Seeded (computational) reproduction is judged on the strict per-type
    tolerance only — a pinned SE must not widen it."""
    result = comparator.compare(_coef(3.713, se=0.305), 3.9, mode=ReproductionMode.SEEDED)
    assert not result.passed
    assert result.tolerance == pytest.approx(0.02)


def test_default_mode_is_seeded(comparator):
    result = comparator.compare(_coef(3.713, se=0.305), 3.9)
    assert not result.passed
    assert result.tolerance == pytest.approx(0.02)
    assert "SE band" not in result.notes


def test_independent_mode_passes_within_one_se(comparator):
    # |3.9 - 3.713| = 0.187 < 1 * 0.305
    result = comparator.compare(_coef(3.713, se=0.305), 3.9, mode=ReproductionMode.INDEPENDENT)
    assert result.passed
    assert result.tolerance == pytest.approx(0.305 / 3.713)


def test_independent_mode_fails_outside_k_se_and_explains_band(comparator):
    # |4.1 - 3.713| = 0.387 > 0.305
    result = comparator.compare(_coef(3.713, se=0.305), 4.1, mode=ReproductionMode.INDEPENDENT)
    assert not result.passed
    assert "±1·SE band" in result.notes


def test_independent_mode_falls_back_to_relative_without_se(comparator):
    result = comparator.compare(_coef(3.713), 3.9, mode=ReproductionMode.INDEPENDENT)
    assert not result.passed
    assert result.tolerance == pytest.approx(0.02)


def test_independent_mode_never_narrower_than_relative(comparator):
    """A tightly-estimated coefficient (tiny SE) keeps its rounding-level
    relative tolerance rather than an impossibly narrow SE band."""
    result = comparator.compare(_coef(0.50, se=0.001), 0.505, mode=ReproductionMode.INDEPENDENT)
    assert result.passed
    assert result.tolerance == pytest.approx(0.02)


def test_independent_band_rescues_near_zero_coefficient(comparator):
    """The near-zero COEFFICIENT problem: 2% of 0.01 is 0.0002, but ±1·SE
    is a meaningful band."""
    result = comparator.compare(_coef(0.010, se=0.004), 0.013, mode=ReproductionMode.INDEPENDENT)
    assert result.passed


def test_se_multiplier_is_configurable():
    comparator = ResultComparator(
        tolerance_policies={ReproductionMode.INDEPENDENT: TolerancePolicy(se_multiplier=2.0)}
    )
    # 0.387 > 1·SE but < 2·SE
    result = comparator.compare(_coef(3.713, se=0.305), 4.1, mode=ReproductionMode.INDEPENDENT)
    assert result.passed
    # The seeded policy is untouched by the override.
    assert comparator.tolerance_policies[ReproductionMode.SEEDED].se_multiplier is None


def test_compare_all_threads_mode():
    comparator = ResultComparator()
    [result] = comparator.compare_all(
        [_coef(3.713, se=0.305)], {"beta": 3.9}, mode=ReproductionMode.INDEPENDENT
    )
    assert result.passed


# ── No claim-type fallback (Phase 1.6) ─────────────────────────────────


def test_claim_without_result_line_is_unmatched_not_borrowed():
    """Regression for the Dincecco script-free run: the generated code
    printed ``RESULT:warfare_iv_coefficient_bivariate=NA`` (unparseable, so
    absent from outputs), and the old claim-type fallback scored the IV
    claim against the first output whose name contained "coefficient" —
    the OLS coefficient's -0.181.  The claim must be unmatched instead."""
    comparator = ResultComparator()
    claims = [
        Claim(description="warfare_coefficient_bivariate", value=3.713, claim_type=ClaimType.COEFFICIENT),
        Claim(description="warfare_iv_coefficient_bivariate", value=4.930, claim_type=ClaimType.COEFFICIENT),
        Claim(description="warfare_iv_se_bivariate", value=0.609, claim_type=ClaimType.STANDARD_ERROR),
    ]
    outputs = {"warfare_coefficient_bivariate": -0.181, "standard_error": 0.609}
    ols, iv, iv_se = comparator.compare_all(claims, outputs, mode=ReproductionMode.INDEPENDENT)
    assert ols.reproduced_value == -0.181
    assert iv.reproduced_value is None
    assert not iv.passed
    assert "No matching output" in iv.notes or "No reproduced value" in iv.notes
    # A generically named output matching only the claim *type* is not a
    # match either — that would have been a false pass.
    assert iv_se.reproduced_value is None
    assert not iv_se.passed


def test_exact_and_substring_matching_still_work():
    comparator = ResultComparator()
    claims = [
        Claim(description="warfare_coefficient_state_fe", value=1.601, claim_type=ClaimType.COEFFICIENT),
        Claim(description="sample size", value=660, claim_type=ClaimType.OTHER),
    ]
    outputs = {"Warfare-Coefficient State FE": 1.601, "sample_size_districts": 660.0}
    exact, substring = comparator.compare_all(claims, outputs)
    assert exact.passed and exact.reproduced_value == 1.601
    assert substring.passed and substring.reproduced_value == 660.0


def test_blind_is_scored_exactly_like_independent():
    from retally.validation.comparator import DEFAULT_TOLERANCE_POLICIES

    assert (
        DEFAULT_TOLERANCE_POLICIES[ReproductionMode.BLIND]
        is DEFAULT_TOLERANCE_POLICIES[ReproductionMode.INDEPENDENT]
    )
    comparator = ResultComparator()
    for reproduced in (3.9, 4.1):
        blind = comparator.compare(_coef(3.713, se=0.305), reproduced, mode=ReproductionMode.BLIND)
        independent = comparator.compare(
            _coef(3.713, se=0.305), reproduced, mode=ReproductionMode.INDEPENDENT
        )
        assert (blind.passed, blind.tolerance) == (independent.passed, independent.tolerance)
