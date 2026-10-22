"""
ClaimExtractor — uses Claude to extract quantitative claims and dataset
references from paper text.

All methods call the Anthropic API with a structured prompt and parse the
JSON response into typed dataclasses.
"""

from __future__ import annotations

import json
import re

from retally.llm import DEFAULT_EXTRACTION_EFFORT, DEFAULT_MODEL, request_options, response_text
from retally.models import (
    Claim,
    ClaimType,
    CodeReference,
    CodeReferenceSource,
    DatasetReference,
    DatasetSource,
    HyperparameterSpec,
    Paper,
)

# How much of the paper body to send when extracting quantitative claims.
# The headline metric of a short ML paper sits in its abstract/intro, but an
# econometrics paper's regression tables live deep in the body — e.g. the main
# results of the first benchmark catalog entry (Dincecco et al. 2022) start
# ~32k chars in and run past 90k.  A small window structurally cannot see
# them, so this is sized to capture main + most appendix tables while bounding
# per-call token cost.  ``min(len, cap)`` means short papers are unaffected.
_CLAIMS_CONTEXT_CHARS = 120_000

# How much of the paper body to send when summarising methodology.  The
# estimating equation / empirical-strategy section of an econometrics paper
# sits mid-body (Dincecco et al.: ~20-40k chars in) — the old 6k window saw
# only the cover page and abstract, so the generated code had no regression
# specification to work from.  Smaller than the claims window because
# methodology doesn't need the appendix tables.
_METHODOLOGY_CONTEXT_CHARS = 60_000

# Appended to the methodology prompt in blind reproduction, where the
# summary must describe how to compute the results without stating them.
_WITHHOLD_RESULTS_INSTRUCTION = (
    "\nDo NOT report any of the paper's results: no estimated coefficients, standard errors, "
    "confidence intervals, test statistics, p-values, means or differences of the outcome, "
    "or fitted metrics.  Numbers that define the method (sample restrictions, cut-offs, "
    "bandwidths, numbers of folds, years) are fine; numbers the method produces are not.\n"
)


class ClaimExtractor:
    """LLM-powered extractor for quantitative claims and dataset references.

    Parameters
    ----------
    anthropic_client:
        An instantiated ``anthropic.Anthropic`` client.
    model:
        Claude model to use.  Defaults to ``retally.llm.DEFAULT_MODEL``.
    effort:
        ``output_config.effort`` for every call; ``None`` sends no effort
        and takes the model's default.  Defaults to
        ``retally.llm.DEFAULT_EXTRACTION_EFFORT``.
    """

    def __init__(
        self,
        anthropic_client,
        model: str = DEFAULT_MODEL,
        effort: str | None = DEFAULT_EXTRACTION_EFFORT,
    ) -> None:
        self._client = anthropic_client
        self._model = model
        self._effort = effort

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
        context = f"Title: {paper.title}\n\n{paper.full_text[:_CLAIMS_CONTEXT_CHARS]}"

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

    def extract_methodology(self, paper: Paper, *, withhold_results: bool = False) -> str:
        """Summarise the paper's methodology in enough detail for code generation.

        ``withhold_results`` (blind reproduction) appends an instruction
        to leave out every reported result -- estimates, standard errors,
        test statistics, p-values, fitted metrics -- since the summary is
        pasted into a generation prompt that must not show the targets.
        The prompt is unchanged when it is False (the default).

        Returns
        -------
        A concise structured summary of the experimental setup.
        """
        context = f"Title: {paper.title}\n\n{paper.full_text[:_METHODOLOGY_CONTEXT_CHARS]}"

        prompt = f"""Summarize the experimental methodology in this research paper in 3-8 bullet points. Focus on:
- The algorithm(s) / estimation method(s) used
- Preprocessing steps applied to the data
- Train/test split strategy (e.g. holdout, k-fold cross-validation, leave-one-out)
- Cross-validation approach and number of folds if applicable
- Key hyperparameter settings mentioned
- Evaluation protocol and metrics used

For econometrics / regression-based papers, additionally capture:
- The estimating equation / regression specification: dependent variable, key regressor(s), functional form (e.g. log-log)
- Units of the headline coefficients: describe a variable or coefficient as standardised only if the paper explicitly says the headline estimates are standardised.  Papers often report a standardised (beta) coefficient as an extra row or column next to the unstandardised estimate; that does not make the headline estimate standardised.
- Fixed effects and the full control set of the preferred specification
- How standard errors are computed (robust / clustered, and clustered on what)
- Sample restrictions defining the estimation sample (which observations are dropped and why)

Be specific and concise. Use exact numbers, variable names, and table/column references from the paper where available.
{_WITHHOLD_RESULTS_INSTRUCTION if withhold_results else ""}
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
            # Headroom for the larger claim arrays an econometrics paper's
            # many regression tables can produce.  A response that still
            # overflows this is recovered object-by-object by
            # _parse_json_response's salvage path rather than discarded.
            max_tokens=16384,
            messages=[{"role": "user", "content": prompt}],
            **request_options(self._effort),
        )
        return response_text(response)

    def _parse_json_response(self, raw: str) -> list[dict]:
        """Extract a JSON array from a Claude response that may contain prose.

        Strips markdown code fences, then finds the first '[' and last ']'
        to isolate the JSON array.  When the strict parse fails — most
        commonly because a long response (e.g. an econometrics paper's many
        regression coefficients) was truncated at ``max_tokens`` mid-array —
        falls back to salvaging every complete object from the array prefix
        and dropping the incomplete trailing one, rather than discarding the
        whole response.

        Raises
        ------
        ValueError
            If no valid JSON array can be extracted and no objects can be
            salvaged.
        """
        # Strip ```json ... ``` or ``` ... ``` fences
        cleaned = re.sub(r"```(?:json)?\s*", "", raw)
        cleaned = re.sub(r"```\s*", "", cleaned)

        start = cleaned.find("[")
        if start == -1:
            raise ValueError(f"Cannot parse JSON from: {raw[:200]}")

        # Fast path: a well-formed array bounded by the first '[' and last ']'.
        end = cleaned.rfind("]")
        if end > start:
            try:
                result = json.loads(cleaned[start : end + 1])
                if not isinstance(result, list):
                    raise ValueError(f"Expected a JSON array but got: {type(result)}")
                return result
            except json.JSONDecodeError:
                pass  # fall through to object-by-object salvage

        # Salvage path: pull complete objects off the front of the array,
        # tolerating a truncated final element.
        salvaged = self._salvage_objects(cleaned[start + 1 :])
        if salvaged:
            return salvaged
        raise ValueError(f"Cannot parse JSON from: {raw[:200]}")

    @staticmethod
    def _salvage_objects(body: str) -> list[dict]:
        """Decode as many consecutive JSON objects as possible from ``body``.

        ``body`` is the interior of a JSON array (after the opening ``[``).
        Uses ``raw_decode`` to consume one object at a time, skipping the
        commas/whitespace between them, and stops at the first point it can
        no longer decode — which is exactly where a truncated response cuts
        off.  Only ``dict`` elements are kept.
        """
        decoder = json.JSONDecoder()
        objects: list[dict] = []
        idx = 0
        n = len(body)
        while idx < n:
            # Advance to the next value, skipping separators/whitespace.
            while idx < n and body[idx] in ", \t\r\n":
                idx += 1
            if idx >= n or body[idx] == "]":
                break
            try:
                obj, offset = decoder.raw_decode(body, idx)
            except json.JSONDecodeError:
                break
            if isinstance(obj, dict):
                objects.append(obj)
            idx = offset
        return objects
