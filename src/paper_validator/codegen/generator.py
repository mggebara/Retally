"""
CodeGenerator — uses Claude to produce Python code that reproduces the
results of an academic paper given its dataset.

The generated code must follow a strict output convention so that
CodeExecutor can parse results automatically:

    RESULT:<metric_name>=<numeric_value>

For example:
    RESULT:test_accuracy=0.9342
    RESULT:f1_score=0.8791

The generator should include this convention in its prompt and include
example output lines in the generated code's comments.

Refinement loop
---------------
The pipeline calls ``generate`` once, then ``refine`` up to N times if the
code fails to execute or does not produce the expected outputs.  Each
refinement call includes the error message and the previous code.
"""

from __future__ import annotations

import re

from paper_validator.models import ClaimType, Dataset, Paper


class CodeGenerator:
    """Generates and refines Python reproduction code using Claude.

    Parameters
    ----------
    anthropic_client:
        An instantiated ``anthropic.Anthropic`` client.
    model:
        Claude model to use.  Defaults to a capable reasoning model.
        Recommended: ``"claude-opus-4-7"`` for generation, ``"claude-sonnet-4-6"``
        for refinement iterations.
    max_refinements:
        Maximum number of refinement attempts before giving up.
    """

    def __init__(
        self,
        anthropic_client,
        model: str = "claude-opus-4-7",
        max_refinements: int = 3,
    ) -> None:
        self._client = anthropic_client
        self._model = model
        self.max_refinements = max_refinements

    def generate(self, paper: Paper, dataset: Dataset) -> str:
        """Generate Python code to reproduce the paper's results.

        The code must:
          1. Load the dataset from ``dataset.local_path``.
          2. Apply the preprocessing and modelling described in
             ``paper.methodology_summary``.
          3. Print each reproduced metric using the
             ``RESULT:<name>=<value>`` convention.
          4. Be self-contained — import all required libraries at the top.
          5. Not require network access.

        Build the prompt with:
          - Paper title and abstract
          - Methodology summary
          - List of claims to reproduce (metric names and target values)
          - Dataset path and file format
          - The output convention requirement

        Returns the generated Python source code as a string.
        """
        prompt = self._build_generation_prompt(paper, dataset)
        response = self._call_claude(prompt)
        return self._extract_code_block(response)

    def refine(
        self,
        code: str,
        error: str,
        paper: Paper,
        dataset: Dataset,
    ) -> str:
        """Refine previously generated code that produced an error.

        Parameters
        ----------
        code:
            The Python code that failed.
        error:
            The error message or unexpected output from execution.
        paper, dataset:
            Same as passed to ``generate``.

        Build a follow-up prompt that includes the original code and the
        error, and asks Claude to fix the specific problem.  Preserve the
        output convention requirement.
        """
        prompt = self._build_refinement_prompt(code, error, paper, dataset)
        response = self._call_claude(prompt)
        return self._extract_code_block(response)

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _build_generation_prompt(self, paper: Paper, dataset: Dataset) -> str:
        """Construct the full generation prompt.

        Structure:
          1. Role/context preamble
          2. Paper details (title, abstract, methodology summary)
          3. Claims to reproduce (formatted as a numbered list)
          4. Dataset details (local path, format, any metadata like column names)
          5. Output convention specification
          6. Code style requirements (self-contained, no network, reproducible seed)
        """
        # 1. Role/context preamble
        lines = [
            "You are reproducing results from an older machine learning paper for validation purposes.",
            "",
        ]

        # 2. Paper details
        lines.append("## Paper Information")
        lines.append(f"Title: {paper.title}")
        if paper.abstract:
            abstract_snippet = paper.abstract[:500]
            lines.append(f"Abstract (first 500 chars): {abstract_snippet}")
        if paper.methodology_summary:
            lines.append(f"Methodology Summary: {paper.methodology_summary}")
        lines.append("")

        # 3. Claims to reproduce
        lines.append("## Claims to Reproduce")
        if paper.claims:
            for i, claim in enumerate(paper.claims, 1):
                unit_str = f" ({claim.unit})" if claim.unit else ""
                lines.append(
                    f"{i}. {claim.description}: {claim.value}{unit_str}"
                    f" [type: {claim.claim_type.value}]"
                )
        else:
            lines.append("No specific claims listed — reproduce the main reported metrics.")
        lines.append("")

        # 4. Dataset details
        lines.append("## Dataset Information")
        lines.append(f"Name: {dataset.name}")
        lines.append(f"Local path: {dataset.local_path}")
        lines.append(f"File format: {dataset.file_format}")
        if dataset.metadata:
            if "columns" in dataset.metadata:
                lines.append(f"Columns: {dataset.metadata['columns']}")
            if "target_column" in dataset.metadata:
                lines.append(f"Target column: {dataset.metadata['target_column']}")
            if "n_rows" in dataset.metadata:
                lines.append(f"Number of rows: {dataset.metadata['n_rows']}")
            if "task_type" in dataset.metadata:
                lines.append(f"Task type: {dataset.metadata['task_type']}")
        lines.append("")

        # 5. Required output convention
        lines.append("## Required Output Convention")
        lines.append(
            "Print each metric using EXACTLY this format: RESULT:<metric_name>=<numeric_value>"
        )
        lines.append("For example: RESULT:accuracy=0.9342")
        lines.append(
            "Use snake_case metric names matching the claim descriptions."
        )
        lines.append("")

        # 6. Code requirements
        lines.append("## Code Requirements")
        lines.append(
            f"Write complete, self-contained Python code using scikit-learn. "
            f"Load the dataset from {dataset.local_path}/data.csv using pandas. "
            f"Use the target column from the metadata. "
            f"Apply appropriate preprocessing (StandardScaler for numeric features, "
            f"handle categorical with LabelEncoder or pd.get_dummies). "
            f"Use a fixed random_state=42 for reproducibility. "
            f"Do NOT access the internet. "
            f"Do NOT use subprocess. "
            f"Print all RESULT: lines at the end."
        )
        lines.append("")

        # 7. Algorithm hint based on claim types present
        claim_types_present = {c.claim_type for c in paper.claims} if paper.claims else set()
        hint = self._algorithm_hint(claim_types_present)
        if hint:
            lines.append("## Algorithm Hints")
            lines.append(hint)
            lines.append("")

        lines.append(
            "Now write the complete Python script. "
            "Output ONLY the code — no explanation, no markdown fences."
        )

        return "\n".join(lines)

    def _build_refinement_prompt(
        self, code: str, error: str, paper: Paper, dataset: Dataset
    ) -> str:
        """Construct the refinement prompt.

        Include:
          1. The original code (in a code block)
          2. The error output (in a code block)
          3. A targeted request to fix only the identified issue
          4. A reminder of the output convention
        """
        lines = [
            "You are fixing Python code that was generated to reproduce results from an older ML paper.",
            "",
            "## Original Code",
            "```python",
            code,
            "```",
            "",
            "## Error / Unexpected Output",
            "```",
            error,
            "```",
            "",
            "## Task",
            "Fix specifically the identified problem above. Do not rewrite the entire approach unless necessary.",
            "",
            "## Reminder: Output Convention",
            "The fixed code MUST print each metric using EXACTLY this format:",
            "    RESULT:<metric_name>=<numeric_value>",
            "For example: RESULT:accuracy=0.9342",
            "Use snake_case metric names.",
            "",
            "## Reminder: Constraints",
            f"- Load the dataset from {dataset.local_path}/data.csv using pandas.",
            "- Use scikit-learn for modelling.",
            "- Do NOT access the internet.",
            "- Do NOT use subprocess.",
            "- Use random_state=42 for reproducibility.",
            "- Print all RESULT: lines at the end.",
            "",
            "Output ONLY the corrected Python code — no explanation, no markdown fences.",
        ]

        return "\n".join(lines)

    def _call_claude(self, prompt: str) -> str:
        """Send a prompt to the Claude API and return the response text."""
        response = self._client.messages.create(
            model=self._model,
            max_tokens=8192,
            messages=[{"role": "user", "content": prompt}],
        )
        return response.content[0].text

    def _extract_code_block(self, response: str) -> str:
        """Extract the Python code block from a Claude response.

        Strip markdown fences (```python ... ```) if present.
        If no fence is found, return the raw response stripped of leading/
        trailing whitespace.
        """
        # Try to match ```python ... ``` first, then ``` ... ```
        pattern = re.compile(r"```(?:python)?\s*\n(.*?)```", re.DOTALL)
        match = pattern.search(response)
        if match:
            return match.group(1).strip()
        return response.strip()

    # ------------------------------------------------------------------
    # Private utility
    # ------------------------------------------------------------------

    @staticmethod
    def _algorithm_hint(claim_types: set) -> str:
        """Return a hint string about typical algorithms for the claim types seen."""
        hints = []

        classification_types = {
            ClaimType.ACCURACY,
            ClaimType.F1_SCORE,
            ClaimType.PRECISION,
            ClaimType.RECALL,
            ClaimType.AUC_ROC,
        }
        regression_types = {ClaimType.RMSE, ClaimType.MAE}

        if claim_types & classification_types:
            hints.append(
                "This paper reports classification metrics. "
                "Common algorithms from this era include: Support Vector Machines (SVC), "
                "Decision Trees, Random Forests, k-Nearest Neighbours, Naive Bayes, "
                "and Logistic Regression. Use cross-validation (StratifiedKFold) where appropriate."
            )
        if claim_types & regression_types:
            hints.append(
                "This paper reports regression metrics (RMSE/MAE). "
                "Common algorithms: Linear Regression, Ridge, Lasso, SVR, "
                "Decision Tree Regressor, Random Forest Regressor."
            )
        if ClaimType.AUC_ROC in claim_types:
            hints.append(
                "AUC-ROC is reported — use roc_auc_score from sklearn.metrics and ensure "
                "the model supports predict_proba or decision_function."
            )
        if ClaimType.CORRELATION in claim_types:
            hints.append(
                "Correlation is reported — consider scipy.stats.pearsonr or spearmanr, "
                "or numpy.corrcoef."
            )
        if ClaimType.P_VALUE in claim_types:
            hints.append(
                "p-values are reported — use scipy.stats for statistical tests."
            )

        return "\n".join(hints)
