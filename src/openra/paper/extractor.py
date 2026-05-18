"""
ClaimExtractor — uses Claude to extract quantitative claims and dataset
references from paper text.

All methods call the Anthropic API with a structured prompt and parse the
JSON response into typed dataclasses.
"""

from __future__ import annotations

import json
import re

from openra.models import (
    Claim,
    ClaimType,
    CodeReference,
    CodeReferenceSource,
    DatasetReference,
    DatasetSource,
    HyperparameterSpec,
    Paper,
)


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

IMPORTANT NOTES FOR ECONOMETRICS PAPERS:
- A regression coefficient (often labelled "β", "Estimate", or just bracketed in a column heading) is claim_type="coefficient". Include it whenever the paper attaches a specific numeric value to a covariate's effect.
- The standard error reported next to or below a coefficient (often in parentheses) is a separate claim with claim_type="standard_error". Emit it as its own claim when the paper reports it explicitly.
- R-squared / adjusted R² / pseudo R² → claim_type="r_squared".
- Sample size N, F-statistics, t-statistics are quantitative claims worth emitting as claim_type="other" when the paper highlights them.

Return ONLY a JSON array (no prose, no markdown explanation). Each item in the array must have exactly these keys:
- description (string): human-readable description of what is being measured, e.g. "test accuracy on MNIST" or "coefficient on log(price), Table 2 col 3"
- value (number): the numeric value as stated in the paper
- unit (string or null): e.g. "%" or null
- claim_type (string): one of: accuracy, f1_score, auc_roc, rmse, mae, precision, recall, correlation, p_value, effect_size, coefficient, standard_error, r_squared, other
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

    def extract_hyperparameters(self, paper: Paper) -> list[HyperparameterSpec]:
        """Pull paper-stated hyperparameters into structured specs.

        The downstream AST auditor matches by keyword-argument name, so the
        prompt explicitly instructs Claude to use canonical scikit-learn
        kwarg names (e.g. ``C``, ``n_estimators``, ``random_state``,
        ``test_size``, ``hidden_layer_sizes``, ``cv``).  If the paper
        describes a value that does not map to a known sklearn kwarg, the
        model is told to skip it rather than invent a name we cannot audit.

        Returns
        -------
        List of HyperparameterSpec.  Empty when the paper does not
        explicitly specify any hyperparameters (which is common — many
        older papers say "we used logistic regression" with no numbers).
        """
        context = f"Title: {paper.title}\n\n{paper.full_text[:6000]}"

        prompt = f"""You are extracting hyperparameter settings from a machine learning paper for automated reproducibility checking.

Find EVERY hyperparameter the paper EXPLICITLY specifies (with a numeric value, a categorical choice, or a list / tuple).  Examples of what counts:
- "logistic regression with C=1.0" → C
- "Random Forest with 100 trees" → n_estimators
- "5-fold cross-validation" → cv
- "80/20 train/test split" → test_size
- "k-NN with k=5" → n_neighbors
- "MLP with one hidden layer of 32 units, ReLU activation" → hidden_layer_sizes and activation
- "SGD with learning rate 0.01 and momentum 0.9" → learning_rate_init, momentum
- "random seed 42" or "random_state=42" → random_state
- "max_iter=1000" → max_iter
- "L2 penalty" → penalty

Use the CANONICAL scikit-learn keyword argument NAME (e.g. ``C``, ``n_estimators``, ``random_state``, ``test_size``, ``hidden_layer_sizes``, ``cv``, ``n_neighbors``, ``learning_rate_init``, ``momentum``, ``max_iter``, ``penalty``, ``activation``, ``solver``, ``kernel``, ``gamma``, ``max_depth``).  Use the exact name that ``sklearn`` expects — that is what the auditor will look for in the generated code.

If the paper describes a setting that does NOT map cleanly to a known sklearn kwarg, OMIT it entirely.  Do not invent names.

Paper:
{context}

Return ONLY a JSON array (no prose, no markdown).  Each item has these keys:
- name (string): the canonical sklearn kwarg name
- value (number / string / list / boolean / null): the value the paper specifies, in its natural type.  Hidden layer sizes should be a JSON array (e.g. [32] for "one hidden layer of 32 units", [100, 50] for two layers).  Train-test split ratios should be the TEST fraction as a float (e.g. 0.2 for an 80/20 split).
- context (string): the surrounding sentence from the paper
- source_ref (string or null): section / table / figure reference if applicable

Example:
[
  {{"name": "C", "value": 1.0, "context": "We use logistic regression with C=1.0.", "source_ref": "§3.2"}},
  {{"name": "test_size", "value": 0.2, "context": "80/20 stratified train/test split.", "source_ref": null}}
]

Return ONLY the JSON array."""

        raw = self._call_claude(prompt)
        items = self._parse_json_response(raw)

        specs: list[HyperparameterSpec] = []
        for item in items:
            try:
                name = str(item.get("name", "")).strip()
                if not name:
                    continue
                specs.append(
                    HyperparameterSpec(
                        name=name,
                        value=item.get("value"),
                        context=str(item.get("context", "")),
                        source_ref=item.get("source_ref") or None,
                    )
                )
            except (KeyError, TypeError, ValueError):
                continue

        return specs

    def extract_code_references(self, paper: Paper) -> list[CodeReference]:
        """Find every reference-implementation URL the paper links to.

        Most commonly a GitHub repo ("Code available at
        github.com/foo/bar"), occasionally a GitLab / Bitbucket / Zenodo
        link or a direct URL to a downloadable archive.  The LLM is
        asked to classify each into a ``CodeReferenceSource`` so the
        downloader can decide whether it can fetch it.

        Returns
        -------
        Empty list when no code link is found (the common case for
        older papers).  Never raises on extraction failure — code
        ingestion is opt-in convenience, not a load-bearing pipeline
        step.
        """
        context = f"Title: {paper.title}\n\n{paper.full_text[:6000]}"

        prompt = f"""You are extracting reference-code links from a machine learning paper.

Find EVERY URL the paper provides for a reference implementation, a code repository, or a downloadable code archive.  Typical patterns:
- "Our code is available at https://github.com/<owner>/<repo>"
- "Implementation: github.com/x/y"
- "https://gitlab.com/..." or "https://bitbucket.org/..."
- A Zenodo DOI / URL when the paper deposited code there
- A direct https URL to a .zip / .tar.gz of the code

DO NOT include URLs that go to:
- A paper PDF (arXiv, journal, doi.org)
- A dataset (UCI, Kaggle, OpenML, HuggingFace dataset page)
- A homepage / personal page that doesn't itself host code

Classify each URL into one of these ``source`` values: github, gitlab, bitbucket, zenodo, direct_url, unknown.  ``github`` means the URL starts with https://github.com/<owner>/<repo>; other code-hosting sites get their respective enum values; ``direct_url`` means a direct download link; ``unknown`` is the safe default when in doubt.

Paper:
{context}

Return ONLY a JSON array (no prose, no markdown).  Each item has these keys:
- url (string): the canonical URL
- source (string): one of the values above
- description (string): the surrounding sentence so a human can verify the match

Example:
[
  {{"url": "https://github.com/openai/baselines", "source": "github", "description": "Our reference implementation is available at https://github.com/openai/baselines."}}
]

Return ONLY the JSON array — empty (``[]``) if the paper does not link any code."""

        try:
            raw = self._call_claude(prompt)
            items = self._parse_json_response(raw)
        except ValueError:
            # Parse failure (rare, but bounded recovery is the right
            # behaviour for an opt-in feature) → no code references.
            return []

        refs: list[CodeReference] = []
        for item in items:
            try:
                url = str(item.get("url", "")).strip()
                if not url:
                    continue
                source_str = str(item.get("source", "unknown")).lower().strip()
                try:
                    source = CodeReferenceSource(source_str)
                except ValueError:
                    source = CodeReferenceSource.UNKNOWN
                refs.append(
                    CodeReference(
                        url=url,
                        source=source,
                        description=str(item.get("description", "")),
                    )
                )
            except (KeyError, TypeError, ValueError):
                continue

        return refs

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
