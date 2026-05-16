"""
ClaimExtractor — uses Claude to extract quantitative claims and dataset
references from paper text.

All methods call the Anthropic API with a structured prompt and parse the
JSON response into typed dataclasses.
"""

from __future__ import annotations

import json
import re

from openra.models import Claim, ClaimType, DatasetReference, DatasetSource, Paper


class ClaimExtractor:
    """LLM-powered extractor for quantitative claims and dataset references.

    Parameters
    ----------
    anthropic_client:
        An instantiated ``anthropic.Anthropic`` client.
    model:
        Claude model to use.
    """

    def __init__(self, anthropic_client, model: str = "claude-opus-4-7") -> None:
        self._client = anthropic_client
        self._model = model

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def extract_claims(self, paper: Paper) -> list[Claim]:
        """Identify all quantitative results stated in the paper.

        Prompts Claude to return a JSON array of claims, then maps claim_type
        strings to ClaimType enum values.

        Returns
        -------
        List of Claim objects (does not mutate the paper).
        """
        context = f"Title: {paper.title}\n\n{paper.full_text[:6000]}"

        prompt = f"""You are an expert at reading machine learning research papers and extracting quantitative results.

Analyze the following paper and find ALL quantitative results: accuracy, error rate, F1, AUC, precision, recall, RMSE, MAE, correlation, p-values, and any other numeric performance metrics.

Paper:
{context}

IMPORTANT NOTES FOR OLDER ML PAPERS:
- Error rate and accuracy are very common. If the paper says "error rate of 5%", you may create a claim with claim_type="accuracy", value=95.0, unit="%" OR create it with value=5.0 and a description that includes "error rate". Use the EXACT number from the paper.
- Look in tables, figures, and inline text for reported numbers.
- Include results for all datasets, all methods, and all experimental conditions reported.

Return ONLY a JSON array (no prose, no markdown explanation). Each item in the array must have exactly these keys:
- description (string): human-readable description of what is being measured, e.g. "test accuracy on MNIST"
- value (number): the numeric value as stated in the paper
- unit (string or null): e.g. "%" or null
- claim_type (string): one of: accuracy, f1_score, auc_roc, rmse, mae, precision, recall, correlation, p_value, effect_size, other
- context (string): the surrounding sentence from the paper
- table_ref (string or null): table number or label if applicable, e.g. "Table 1" or null
- figure_ref (string or null): figure number or label if applicable, e.g. "Figure 2" or null

Example output format:
[
  {{"description": "test accuracy on UCI Iris dataset", "value": 97.3, "unit": "%", "claim_type": "accuracy", "context": "Our method achieved 97.3% accuracy on the Iris dataset.", "table_ref": "Table 2", "figure_ref": null}}
]

Return ONLY the JSON array."""

        raw = self._call_claude(prompt)
        items = self._parse_json_response(raw)

        claims = []
        for item in items:
            try:
                ct_str = str(item.get("claim_type", "other")).lower()
                try:
                    claim_type = ClaimType(ct_str)
                except ValueError:
                    claim_type = ClaimType.OTHER

                claim = Claim(
                    description=str(item.get("description", "")),
                    value=float(item.get("value", 0.0)),
                    unit=item.get("unit") or None,
                    claim_type=claim_type,
                    context=str(item.get("context", "")),
                    table_ref=item.get("table_ref") or None,
                    figure_ref=item.get("figure_ref") or None,
                )
                claims.append(claim)
            except (KeyError, TypeError, ValueError):
                # Skip malformed entries
                continue

        return claims

    def extract_dataset_references(self, paper: Paper) -> list[DatasetReference]:
        """Find all dataset references in the paper text.

        Returns
        -------
        List of DatasetReference objects (does not mutate the paper).
        """
        context = f"Title: {paper.title}\n\n{paper.full_text[:4000]}"

        prompt = f"""You are an expert at identifying datasets used in machine learning research papers.

Analyze the following paper and identify ALL datasets mentioned or used.

Paper:
{context}

NOTES FOR CLASSIC ML PAPERS:
- Common datasets in older ML papers include UCI Repository datasets (Iris, Adult/Census, Breast Cancer Wisconsin, Wine, Pima Indians Diabetes, Letter Recognition, etc.), MNIST, CIFAR-10, ImageNet, Reuters, 20 Newsgroups, and similar benchmarks.
- If a UCI dataset is mentioned by name, set source="uci".
- If an OpenML dataset is mentioned, set source="openml".
- If a Kaggle dataset is mentioned, set source="kaggle".

Return ONLY a JSON array (no prose, no markdown explanation). Each item must have exactly these keys:
- name (string): common name of the dataset, e.g. "UCI Breast Cancer Wisconsin"
- source (string): one of: direct_url, kaggle, zenodo, uci, harvard_dataverse, figshare, openml, unknown
- url (string or null): direct URL or repository identifier, or null
- description (string): brief description extracted from the paper
- access_instructions (string or null): any special steps required, or null

Example output format:
[
  {{"name": "UCI Adult Income", "source": "uci", "url": "https://archive.ics.uci.edu/ml/datasets/adult", "description": "Census income dataset with 48842 instances", "access_instructions": null}}
]

Return ONLY the JSON array."""

        raw = self._call_claude(prompt)
        items = self._parse_json_response(raw)

        dataset_refs = []
        for item in items:
            try:
                source_str = str(item.get("source", "unknown")).lower()
                try:
                    source = DatasetSource(source_str)
                except ValueError:
                    source = DatasetSource.UNKNOWN

                dataset_ref = DatasetReference(
                    name=str(item.get("name", "")),
                    source=source,
                    url=item.get("url") or None,
                    description=str(item.get("description", "")),
                    access_instructions=item.get("access_instructions") or None,
                )
                dataset_refs.append(dataset_ref)
            except (KeyError, TypeError, ValueError):
                # Skip malformed entries
                continue

        return dataset_refs

    def extract_methodology(self, paper: Paper) -> str:
        """Summarise the paper's methodology in enough detail for code generation.

        Returns
        -------
        A concise structured summary of the experimental setup.
        """
        context = f"Title: {paper.title}\n\n{paper.full_text[:6000]}"

        prompt = f"""Summarize the experimental methodology in this ML paper in 3-5 bullet points. Focus on:
- The algorithm(s) used
- Preprocessing steps applied to the data
- Train/test split strategy (e.g. holdout, k-fold cross-validation, leave-one-out)
- Cross-validation approach and number of folds if applicable
- Key hyperparameter settings mentioned
- Evaluation protocol and metrics used

Be specific and concise. Use exact numbers and names from the paper where available.

Paper:
{context}"""

        return self._call_claude(prompt)

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _call_claude(self, prompt: str) -> str:
        """Send a prompt to the Claude API and return the text response."""
        response = self._client.messages.create(
            model=self._model,
            max_tokens=4096,
            messages=[{"role": "user", "content": prompt}],
        )
        return response.content[0].text

    def _parse_json_response(self, raw: str) -> list[dict]:
        """Extract a JSON array from a Claude response that may contain prose.

        Strips markdown code fences, then finds the first '[' and last ']'
        to isolate the JSON array.

        Raises
        ------
        ValueError
            If no valid JSON array can be extracted.
        """
        # Strip ```json ... ``` or ``` ... ``` fences
        cleaned = re.sub(r"```(?:json)?\s*", "", raw)
        cleaned = re.sub(r"```\s*", "", cleaned)

        # Find the first '[' and last ']'
        start = cleaned.find("[")
        end = cleaned.rfind("]")

        if start == -1 or end == -1 or end <= start:
            raise ValueError(f"Cannot parse JSON from: {raw[:200]}")

        json_str = cleaned[start : end + 1]

        try:
            result = json.loads(json_str)
            if not isinstance(result, list):
                raise ValueError(f"Expected a JSON array but got: {type(result)}")
            return result
        except json.JSONDecodeError as exc:
            raise ValueError(f"Cannot parse JSON from: {raw[:200]}") from exc
