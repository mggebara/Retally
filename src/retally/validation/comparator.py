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

A claim that matches no output by name is *unmatched* (scored as missing).
There is deliberately no fallback on claim type: matching a coefficient
claim to "the first output whose name contains 'coefficient'" made a claim
with no RESULT line borrow another claim's value (Phase 1.6: three NA IV
coefficients were scored against the OLS coefficient), which inflates the
matched rate and could produce a false pass.

Tolerance
---------
The default tolerance is 1 % relative error for most metrics.  Some metrics
have tighter conventions (p-values should be exact) while others are looser
(wall-clock times, memory usage).  Override per-metric via ``_default_tolerance``.

Per-mode tolerance policy
-------------------------
How close is "reproduced" depends on what was reproduced (see
``ReproductionMode``):

* ``SEEDED`` (computational reproduction — the authors' scripts were in
  the prompt) is judged strictly: the per-type relative tolerance above,
  nothing more.  Re-running the same specification on the same data
  should land on the reported number up to rounding.
* ``INDEPENDENT`` (regenerated from the paper text) is SE-aware: when the
  claim carries a pinned ``standard_error``, it passes if the reproduced
  value is within ±k·SE of the reported value (k defaults to 1).  The SE
  band is expressed as a relative tolerance, ``k·SE / |claimed|``, and
  the claim gets the *wider* of that and its per-type relative tolerance,
  so a tightly-estimated coefficient is never held to a band narrower
  than the paper's own rounding.  With no SE pinned it falls back to the
  per-type relative tolerance.
* ``BLIND`` (independent, with the targets withheld from the model) is
  judged exactly like ``INDEPENDENT``: the default policy map gives both
  the same ``TolerancePolicy`` object.  An override passed for one mode
  does not change the other.

Because the effective band is recorded as an ordinary relative tolerance
on each ``ClaimValidationResult``, downstream consumers (benchmark
closeness bands, I4R scoring) need no special-casing.
"""

from __future__ import annotations

import re
from collections.abc import Mapping
from dataclasses import dataclass

from retally.models import Claim, ClaimType, ClaimValidationResult, ReproductionMode


@dataclass(frozen=True)
class TolerancePolicy:
    """How claims are judged in one reproduction mode."""

    se_multiplier: float | None = None
    """k in the ±k·SE pass band.  None disables the SE-aware band, leaving
    only the per-type relative tolerance."""


_INDEPENDENT_POLICY = TolerancePolicy(se_multiplier=1.0)

DEFAULT_TOLERANCE_POLICIES: Mapping[ReproductionMode, TolerancePolicy] = {
    ReproductionMode.SEEDED: TolerancePolicy(se_multiplier=None),
    ReproductionMode.INDEPENDENT: _INDEPENDENT_POLICY,
    # Blind differs from independent only in what the model is shown, not
    # in how its numbers are judged: the same policy object.
    ReproductionMode.BLIND: _INDEPENDENT_POLICY,
}


class ResultComparator:
    """Compares reproduced results against paper claims.

    Parameters
    ----------
    default_tolerance:
        Default relative tolerance (fraction, not percentage).  A claim
        passes if ``|reproduced - claimed| / |claimed| <= tolerance``.
    tolerance_policies:
        Per-mode ``TolerancePolicy`` overrides, merged over
        ``DEFAULT_TOLERANCE_POLICIES`` — e.g.
        ``{ReproductionMode.INDEPENDENT: TolerancePolicy(se_multiplier=2.0)}``
        widens the independent band to ±2·SE.
    """

    def __init__(
        self,
        default_tolerance: float = 0.01,
        tolerance_policies: Mapping[ReproductionMode, TolerancePolicy] | None = None,
    ) -> None:
        self.default_tolerance = default_tolerance
        self.tolerance_policies: dict[ReproductionMode, TolerancePolicy] = {
            **DEFAULT_TOLERANCE_POLICIES,
            **(tolerance_policies or {}),
        }

    def compare_all(
        self,
        claims: list[Claim],
        outputs: dict[str, float],
        mode: ReproductionMode = ReproductionMode.SEEDED,
    ) -> list[ClaimValidationResult]:
        """Match every claim to an output value and evaluate each.

        For each claim call ``_match_output`` to find the best matching key
        in ``outputs``, then call ``compare`` to produce a ClaimValidationResult.

        Claims that cannot be matched get ``reproduced_value=None`` and
        ``passed=False`` with an explanatory note.

        ``mode`` selects the tolerance policy (see module docstring).
        """
        results: list[ClaimValidationResult] = []
        for claim in claims:
            matched_key, matched_value = self._match_output(claim, outputs)
            result = self.compare(claim, matched_value, mode=mode)
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
        mode: ReproductionMode = ReproductionMode.SEEDED,
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
            Relative tolerance override.  If None, use the mode's policy:
            ``_default_tolerance(claim)``, widened to the ±k·SE band when
            the policy is SE-aware and the claim pins a standard error.
        mode:
            Reproduction mode whose ``TolerancePolicy`` applies.  Ignored
            when ``tolerance`` is given explicitly.

        A claim passes when:
            reproduced_value is not None
            AND |reproduced_value - claim.value| / max(|claim.value|, 1e-9) <= tolerance

        Special case: if claimed > 1.0 and reproduced <= 1.0, also try comparing
        claimed/100 vs reproduced (handles % vs decimal mismatch). Use whichever
        comparison gives the smaller error; note the unit mismatch if it passes.
        """
        se_band_note = ""
        if tolerance is None:
            tolerance = self._default_tolerance(claim)
            se_band = self._se_band(claim, mode)
            if se_band is not None and se_band > tolerance:
                tolerance = se_band
                k = self.tolerance_policies[mode].se_multiplier
                se_band_note = f", the ±{k:g}·SE band with SE={claim.standard_error:g}"

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
                f"(relative error {rel_err:.2%}, tolerance {tolerance:.2%}{se_band_note})."
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

        No claim-type fallback: an output is only ever matched by name, so a
        claim never borrows another claim's value.
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

        return None, None

    def _se_band(self, claim: Claim, mode: ReproductionMode) -> float | None:
        """The ±k·SE band as a relative tolerance, or None when it doesn't apply.

        Applies only when ``mode``'s policy sets ``se_multiplier`` and the
        claim pins a positive ``standard_error``.
        """
        policy = self.tolerance_policies.get(mode, TolerancePolicy())
        se = claim.standard_error
        if policy.se_multiplier is None or se is None or se <= 0:
            return None
        return policy.se_multiplier * se / max(abs(claim.value), 1e-9)

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
            close to zero can still trip this under the strict (seeded)
            policy; the independent policy's ±k·SE band addresses it
            when the claim pins a standard error.
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
