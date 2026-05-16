"""
ResultComparator — matches reproduced metric values to paper claims and
decides whether each claim is validated.

Matching strategy
-----------------
The executor produces a flat dict of {metric_name: float} (from RESULT: lines).
The comparator must figure out which reproduced value corresponds to each Claim.
This is non-trivial because the paper may use names like "classification accuracy"
while the code emits "test_accuracy".

Recommended approach:
  1. Exact key match (normalise both sides: lowercase, strip spaces/underscores).
  2. Substring match (claim description contains the key or vice versa).
  3. As a fallback, use Claude to match claims to output keys by semantic
     similarity (optional, add a ``use_llm_matching`` flag to __init__).

Tolerance
---------
The default tolerance is 1 % relative error for most metrics.  Some metrics
have tighter conventions (p-values should be exact) while others are looser
(wall-clock times, memory usage).  Override per-metric via ``_default_tolerance``.
"""

from __future__ import annotations

from paper_validator.models import Claim, ClaimType, ClaimValidationResult


class ResultComparator:
    """Compares reproduced results against paper claims.

    Parameters
    ----------
    default_tolerance:
        Default relative tolerance (fraction, not percentage).  A claim
        passes if ``|reproduced - claimed| / |claimed| <= tolerance``.
    use_llm_matching:
        If True, fall back to an LLM call to match ambiguous metric names.
        Requires ``anthropic_client`` to be provided.
    anthropic_client:
        Required only when ``use_llm_matching=True``.
    """

    def __init__(
        self,
        default_tolerance: float = 0.01,
        use_llm_matching: bool = False,
        anthropic_client=None,
    ) -> None:
        self.default_tolerance = default_tolerance
        self.use_llm_matching = use_llm_matching
        self._client = anthropic_client

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
        raise NotImplementedError

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
        """
        raise NotImplementedError

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _match_output(
        self, claim: Claim, outputs: dict[str, float]
    ) -> tuple[str | None, float | None]:
        """Find the best matching key in ``outputs`` for this claim.

        Returns ``(key, value)`` or ``(None, None)`` if no match found.

        Strategy (in order):
          1. Normalise both claim description and all output keys
             (lowercase, replace spaces/hyphens/underscores with a single
             underscore, strip trailing 's').
          2. Exact match on normalised strings.
          3. Substring match.
          4. LLM match (if ``use_llm_matching`` is True).
        """
        raise NotImplementedError

    def _default_tolerance(self, claim: Claim) -> float:
        """Return an appropriate tolerance for this claim's type.

        Suggested values:
          - ACCURACY, F1, AUC_ROC, PRECISION, RECALL → 0.01 (1 %)
          - RMSE, MAE → 0.05 (5 %)
          - CORRELATION → 0.02
          - P_VALUE → 0.001 (absolute, not relative — handle specially)
          - EFFECT_SIZE → 0.05
          - OTHER → ``self.default_tolerance``
        """
        raise NotImplementedError

    def _normalise_key(self, s: str) -> str:
        """Lowercase, replace non-alphanumeric runs with '_', strip trailing 's'."""
        raise NotImplementedError
