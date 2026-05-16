"""
ClaimExtractor — uses Claude to extract quantitative claims and dataset
references from paper text.

All methods call the Anthropic API with a structured prompt and parse the
JSON response into typed dataclasses.  Use pydantic or json.loads for
parsing; validate that numeric values are within plausible ranges before
accepting them.
"""

from __future__ import annotations

from paper_validator.models import Claim, DatasetReference, Paper


class ClaimExtractor:
    """LLM-powered extractor for quantitative claims and dataset references.

    Parameters
    ----------
    anthropic_client:
        An instantiated ``anthropic.Anthropic`` client.  Pass it in so the
        caller controls API key management and retry logic.
    model:
        Claude model to use.  Defaults to a capable but cost-efficient model.
        Recommended: ``"claude-opus-4-7"`` for production, ``"claude-haiku-4-5-20251001"``
        for fast/cheap iteration.
    """

    def __init__(self, anthropic_client, model: str = "claude-opus-4-7") -> None:
        self._client = anthropic_client
        self._model = model

    def extract_claims(self, paper: Paper) -> list[Claim]:
        """Identify all quantitative results stated in the paper.

        Prompt strategy
        ---------------
        Ask Claude to read ``paper.full_text`` and return a JSON array of
        objects with keys: description, value, unit, claim_type, context,
        table_ref, figure_ref.

        Post-processing
        ---------------
        - Parse the JSON response.
        - Map ``claim_type`` strings to ``ClaimType`` enum values.
        - Deduplicate identical (description, value) pairs.
        - Return a list of ``Claim`` objects.

        The returned list is assigned to ``paper.claims`` by the pipeline, but
        this method does not mutate the paper — it only returns the list.
        """
        raise NotImplementedError

    def extract_dataset_references(self, paper: Paper) -> list[DatasetReference]:
        """Find all dataset references in the paper text.

        Prompt strategy
        ---------------
        Ask Claude to identify every dataset mentioned in ``paper.full_text``
        and return a JSON array with keys: name, source, url, description,
        access_instructions.

        Post-processing
        ---------------
        - Parse the JSON response.
        - Map ``source`` strings to ``DatasetSource`` enum values.
        - Attempt to normalise Kaggle slugs and Zenodo DOIs from raw URLs.
        """
        raise NotImplementedError

    def extract_methodology(self, paper: Paper) -> str:
        """Summarise the paper's methodology in enough detail for code generation.

        Ask Claude to extract the experimental setup: algorithms used,
        hyperparameters, train/test split strategy, evaluation protocol, and
        any pre-processing steps.  Return a concise structured summary (not the
        raw section text) that will be included in the code-generation prompt.
        """
        raise NotImplementedError

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _call_claude(self, prompt: str) -> str:
        """Send a prompt to the Claude API and return the text response.

        Use ``self._client.messages.create`` with ``max_tokens`` large enough
        to hold the full JSON response (4096 is a reasonable starting point).
        Extract ``response.content[0].text``.
        """
        raise NotImplementedError

    def _parse_json_response(self, raw: str) -> list[dict]:
        """Extract a JSON array from a Claude response that may contain prose.

        Claude sometimes wraps JSON in markdown fences.  Strip any
        ```json ... ``` wrapper before calling json.loads.  Raise a
        ValueError with the raw response in the message if parsing fails,
        so callers can log it for debugging.
        """
        raise NotImplementedError
