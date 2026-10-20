"""
ResultComparator — matches reproduced metric values to paper claims and
decides whether each claim is validated.

Matching strategy
-----------------
The executor produces a flat dict of {metric_name: float} (from RESULT: lines).
The comparator must figure out which reproduced value corresponds to each Claim.
This is non-trivial because the paper may use names like "classification accuracy"
while the code emits "test_accuracy".

Approach:
  1. Exact key match (normalise both sides: lowercase, strip spaces/underscores).
  2. Substring match (claim description contains the key or vice versa).
  3. Match on claim_type name vs normalised output keys.

Tolerance
---------
The default tolerance is 1 % relative error for most metrics.  Some metrics
have tighter conventions (p-values should be exact) while others are looser
(wall-clock times, memory usage).  Override per-metric via ``_default_tolerance``.
"""

from __future__ import annotations

import re

from retally.models import Claim, ClaimType, ClaimValidationResult


class ResultComparator:
    """Compares reproduced results against paper claims.

    Parameters
    ----------
    default_tolerance:
        Default relative tolerance (fraction, not percentage).  A claim
        passes if ``|reproduced - claimed| / |claimed| <= tolerance``.
    """

    def __init__(
        self,
        default_tolerance: float = 0.01,
    ) -> None:
        self.default_tolerance = default_tolerance

    def compare_all(
        self,
        claims: list[Claim],
        outputs: dict[str, float],
    ) -> list[ClaimValidationResult]:
        """Match every claim to an output value and evaluate each.

        For each claim call ``_match_output`` to find the best matching key
        in ``outputs``, then call ``compare`` to produce a ClaimValidationResult.

        Claims that cannot be matched get ``reproduced_value=None`` and
        ``passed=False`` with an explanatory note.
        """
        results: list[ClaimValidationResult] = []
        for claim in claims:
            matched_key, matched_value = self._match_output(claim, outputs)
            result = self.compare(claim, matched_value)
            if matched_key is None and not result.notes:
                result.notes = (
                    f"No matching output found for claim: {claim.description!r}. "
                    f"Available outputs: {list(outputs.keys())}"
                )
            results.append(result)
        return results

    def compare(
        self,
        claim: Claim,
        reproduced_value: float | None,
        tolerance: float | None = None,
    ) -> ClaimValidationResult:
        """Evaluate a single claim against a reproduced value.

        Parameters
        ----------
        claim:
            The paper claim to validate.
        reproduced_value:
            The metric value produced by the generated code, or None if no
            matching output was found.
        tolerance:
            Relative tolerance override.  If None, use ``_default_tolerance(claim)``.

        A claim passes when:
            reproduced_value is not None
            AND |reproduced_value - claim.value| / max(|claim.value|, 1e-9) <= tolerance

        Special case: if claimed > 1.0 and reproduced <= 1.0, also try comparing
        claimed/100 vs reproduced (handles % vs decimal mismatch). Use whichever
        comparison gives the smaller error; note the unit mismatch if it passes.
        """
        if tolerance is None:
            tolerance = self._default_tolerance(claim)

        if reproduced_value is None:
            return ClaimValidationResult(
                claim=claim,
                reproduced_value=None,
                tolerance=tolerance,
                passed=False,
                notes="No reproduced value available.",
            )

        claimed = claim.value
        reproduced = reproduced_value

        # Primary comparison
        rel_err = abs(reproduced - claimed) / max(abs(claimed), 1e-9)
        passed = rel_err <= tolerance
        notes = ""

        # Special case: % vs decimal mismatch
        # If claimed > 1.0 and reproduced <= 1.0, also try claimed/100 vs reproduced
        if claimed > 1.0 and reproduced <= 1.0:
            scaled_claimed = claimed / 100.0
            scaled_rel_err = abs(reproduced - scaled_claimed) / max(abs(scaled_claimed), 1e-9)
            if scaled_rel_err < rel_err and scaled_rel_err <= tolerance:
                passed = True
                notes = (
                    "Unit mismatch detected: paper value appears to be in percentage "
                    f"({claimed}%) while reproduced value is in decimal ({reproduced}). "
                    "Claim validated after unit normalisation."
                )

        # If the claim failed and we don't already have an explanation
        # (unit-mismatch path can pass-with-a-note; this branch only fires
        # when we're going to record a failure), explain the gap so the
        # report doesn't just say "FAIL" with no context.
        if not passed and not notes:
            notes = (
                f"Outside tolerance: reproduced={reproduced} vs claimed={claimed} "
                f"(relative error {rel_err:.2%}, tolerance {tolerance:.2%})."
            )

        return ClaimValidationResult(
            claim=claim,
            reproduced_value=reproduced_value,
            tolerance=tolerance,
            passed=passed,
            notes=notes,
        )

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _match_output(self, claim: Claim, outputs: dict[str, float]) -> tuple[str | None, float | None]:
        """Find the best matching key in ``outputs`` for this claim.

        Returns ``(key, value)`` or ``(None, None)`` if no match found.

        Strategy (in order):
          1. Exact match on normalised claim description vs normalised output keys.
          2. Substring match (normalised claim key is substring of normalised output
             key, or vice versa).
          3. Check claim.claim_type name against normalised output keys.
        """
        if not outputs:
            return None, None

        norm_claim = self._normalise_key(claim.description)
        norm_outputs: dict[str, str] = {k: self._normalise_key(k) for k in outputs}

        # Strategy 1: exact normalised match
        for raw_key, norm_key in norm_outputs.items():
            if norm_key == norm_claim:
                return raw_key, outputs[raw_key]

        # Strategy 2: substring match
        for raw_key, norm_key in norm_outputs.items():
            if norm_claim in norm_key or norm_key in norm_claim:
                return raw_key, outputs[raw_key]

        # Strategy 3: match claim_type name against normalised output keys
        norm_type = self._normalise_key(claim.claim_type.name)
        for raw_key, norm_key in norm_outputs.items():
            if norm_type in norm_key or norm_key in norm_type:
                return raw_key, outputs[raw_key]

        return None, None

    def _default_tolerance(self, claim: Claim) -> float:
        """Return an appropriate tolerance for this claim's type.

        ML-side values:
          - ACCURACY, F1_SCORE, AUC_ROC, PRECISION, RECALL → 0.01 (1 %)
          - RMSE, MAE → 0.05 (5 %)
          - CORRELATION → 0.02
          - P_VALUE → 0.001
          - EFFECT_SIZE → 0.05

        Econometric values (PR 5):
          - COEFFICIENT → 0.02 (2 %).  Econ papers round coefficients
            more aggressively than ML metrics, so the looser tolerance
            soaks up reporting precision differences.  Coefficients
            close to zero can still trip this — that's a known
            limitation; standard-error-aware comparison is future work.
          - STANDARD_ERROR → 0.05 (5 %).  Heavily rounded in practice;
            replicators often see SE differences of 5-10 % from re-runs.
          - R_SQUARED → 0.01 (1 %).  Usually reported to 3 decimal
            places; 1 % matches typical precision.

        - OTHER → ``self.default_tolerance``
        """
        mapping = {
            ClaimType.ACCURACY: 0.01,
            ClaimType.F1_SCORE: 0.01,
            ClaimType.AUC_ROC: 0.01,
            ClaimType.PRECISION: 0.01,
            ClaimType.RECALL: 0.01,
            ClaimType.RMSE: 0.05,
            ClaimType.MAE: 0.05,
            ClaimType.CORRELATION: 0.02,
            ClaimType.P_VALUE: 0.001,
            ClaimType.EFFECT_SIZE: 0.05,
            ClaimType.COEFFICIENT: 0.02,
            ClaimType.STANDARD_ERROR: 0.05,
            ClaimType.R_SQUARED: 0.01,
            ClaimType.OTHER: self.default_tolerance,
        }
        return mapping.get(claim.claim_type, self.default_tolerance)

    def _normalise_key(self, s: str) -> str:
        """Lowercase, replace non-alphanumeric runs with '_', strip leading/trailing underscores.

        Note: does NOT strip trailing 's' to avoid false matches (e.g. "class" → "clas").
        """
        s = s.lower()
        s = re.sub(r"[^a-z0-9]+", "_", s)
        s = s.strip("_")
        return s
