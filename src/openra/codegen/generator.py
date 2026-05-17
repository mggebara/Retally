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
from typing import TYPE_CHECKING

from openra.models import ClaimType, ClaimValidationResult, Dataset, ExecutionResult, Paper

if TYPE_CHECKING:
    from openra.code.selector import SelectedFile


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

    def generate(
        self,
        paper: Paper,
        dataset: Dataset,
        reference_files: list[SelectedFile] | None = None,
    ) -> str:
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
          - Optionally: a "Reference implementation" section showing
            ``reference_files`` selected from the paper's linked code
            repo.  When present the prompt instructs the model to
            adapt that code rather than start from scratch.

        Returns the generated Python source code as a string.
        """
        prompt = self._build_generation_prompt(paper, dataset, reference_files or [])
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

    def refine_for_claims(
        self,
        code: str,
        failed_claims: list[ClaimValidationResult],
        exec_result: ExecutionResult,
        paper: Paper,
        dataset: Dataset,
        history: list[dict[str, float]],
    ) -> str:
        """Refine working code whose reproduced numbers are outside tolerance.

        Distinct from :meth:`refine` (which handles execution errors): here
        the code runs cleanly, captures values, but those values disagree
        with the paper's claims.  The prompt asks Claude to identify the
        cause of the gap and adjust the code minimally to close it.

        Parameters
        ----------
        code:
            The script that produced the unsatisfactory values.
        failed_claims:
            ``ClaimValidationResult`` objects where ``passed`` is False but
            ``reproduced_value`` is not None.  Hard failures (None values)
            belong in :meth:`refine`.
        exec_result:
            The :class:`ExecutionResult` that produced the failed claims —
            included so the prompt can show the reproduced values in
            context (e.g. alongside other metrics that DID pass).
        paper, dataset:
            Same as passed to :meth:`generate`.
        history:
            Past attempts' ``outputs`` dicts, oldest first.  Lets the model
            see what it has already tried so it doesn't loop.

        Returns
        -------
        New code.  If the model returns *exactly the same code unchanged*
        the pipeline interprets that as the model declaring the gap
        unreasonable and halts the refinement loop.
        """
        prompt = self._build_claim_refinement_prompt(
            code, failed_claims, exec_result, paper, dataset, history
        )
        response = self._call_claude(prompt)
        return self._extract_code_block(response)

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _build_generation_prompt(
        self,
        paper: Paper,
        dataset: Dataset,
        reference_files: list[SelectedFile],
    ) -> str:
        """Construct the full generation prompt.

        Structure:
          1. Role/context preamble
          2. Paper details (title, abstract, methodology summary)
          3. Claims to reproduce (formatted as a numbered list)
          4. Dataset details (local path, format, any metadata like column names)
          5. Output convention specification
          6. Code style requirements (self-contained, no network, reproducible seed)
          7. Algorithm hints derived from the claim types
          8. Reference implementation (only when ``reference_files`` is non-empty):
             a small selection of source files from the paper's linked
             code repo, with an instruction to adapt them rather than
             write from scratch.
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
                    f"{i}. {claim.description}: {claim.value}{unit_str} [type: {claim.claim_type.value}]"
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
        lines.append("Print each metric using EXACTLY this format: RESULT:<metric_name>=<numeric_value>")
        lines.append("For example: RESULT:accuracy=0.9342")
        lines.append("Use snake_case metric names matching the claim descriptions.")
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

        # 8. Reference implementation, when the paper linked code and we
        # were able to clone it.  This dramatically changes the prompt
        # shape: rather than reconstruct from the methodology summary
        # alone, the model is told to adapt real source files — typically
        # closes the gap on hyperparameter choices and dataset-loading
        # quirks the methodology summary glosses over.
        if reference_files:
            lines.append("## Reference Implementation")
            lines.append(
                "The paper links a public code repository.  The most relevant "
                "Python source files from that repository are reproduced below.  "
                "PREFER ADAPTING these files over writing from scratch: keep the "
                "model architecture, hyperparameters, preprocessing, and "
                "train/test split conventions as close to the reference as "
                "possible.  You may need to change file paths (load the dataset "
                f"from {dataset.local_path}/data.csv instead of whatever the "
                "reference uses) and you may need to omit code unrelated to the "
                "specific claims being reproduced.  Where the reference deviates "
                "from the paper's text, prefer the reference."
            )
            lines.append("")
            for ref_file in reference_files:
                lines.append(f"### `{ref_file.relative_path}`")
                lines.append("```python")
                lines.append(ref_file.contents)
                lines.append("```")
                lines.append("")

        lines.append(
            "Now write the complete Python script. Output ONLY the code — no explanation, no markdown fences."
        )

        return "\n".join(lines)

    def _build_refinement_prompt(self, code: str, error: str, paper: Paper, dataset: Dataset) -> str:
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

    def _build_claim_refinement_prompt(
        self,
        code: str,
        failed_claims: list[ClaimValidationResult],
        exec_result: ExecutionResult,
        paper: Paper,
        dataset: Dataset,
        history: list[dict[str, float]],
    ) -> str:
        """Construct a prompt that asks Claude to close the gap on soft-failed claims.

        The structure differs from :meth:`_build_refinement_prompt`:

        * No Python traceback — the code ran cleanly.  Instead we show the
          numeric gap between paper claim and reproduced value.
        * The history of previous attempts' outputs is included so the
          model can see it isn't on a productive trajectory.
        * The model is explicitly told to return the SAME code unchanged
          if it judges the gap unreproducible.  The pipeline reads that
          as a halt signal.
        * The model is told to emit ``DEVIATION:<text>`` stdout lines if
          it has to change anything the paper didn't specify.  These are
          surfaced in the final report.
        """
        # Failed-claim summary
        claim_lines = []
        for i, cr in enumerate(failed_claims, 1):
            claim = cr.claim
            unit = f" {claim.unit}" if claim.unit else ""
            reproduced = "N/A" if cr.reproduced_value is None else f"{cr.reproduced_value:.6g}"
            gap = ""
            if cr.reproduced_value is not None:
                rel = abs(cr.reproduced_value - claim.value) / max(abs(claim.value), 1e-9)
                gap = f", gap {rel * 100:.2f}% relative"
            claim_lines.append(
                f"{i}. {claim.description}: paper claims {claim.value}{unit} "
                f"({claim.claim_type.value}), your code produced {reproduced}, "
                f"tolerance {cr.tolerance:.4g}{gap}"
            )

        # All captured outputs so the model sees what passed too
        outputs_block = "\n".join(f"  {k} = {v}" for k, v in exec_result.outputs.items()) or "  (none)"

        # History of prior attempts (oldest first)
        history_block = ""
        if history:
            history_lines = []
            for i, h in enumerate(history, 1):
                rendered = ", ".join(f"{k}={v}" for k, v in h.items()) or "(empty)"
                history_lines.append(f"  Attempt {i}: {rendered}")
            history_block = "\n".join(history_lines)

        lines = [
            "You are refining Python code that reproduces results from an older ML paper.",
            "The code RAN SUCCESSFULLY but the reproduced values do not match the",
            "paper's claims within the allowed tolerance.  Your job is to identify",
            "what is causing the gap and adjust the code to close it.",
            "",
            "## Paper",
            f"Title: {paper.title}",
        ]
        if paper.methodology_summary:
            lines.append(f"Methodology: {paper.methodology_summary}")
        lines.append("")

        lines += [
            "## Current Code",
            "```python",
            code,
            "```",
            "",
            "## What the code produced",
            outputs_block,
            "",
            "## Claims still failing",
            *claim_lines,
            "",
        ]

        if history_block:
            lines += [
                "## Previous attempts (oldest first)",
                history_block,
                "",
                "These attempts have already been tried.  Do not repeat a strategy",
                "that has already produced the same values.",
                "",
            ]

        lines += [
            "## Task",
            "Adjust the code minimally to close the gap on the failing claims.",
            "Prefer changes that align more closely with the paper's stated",
            "methodology: re-read the methodology summary above and check the",
            "hyperparameters, preprocessing, train/test split, cross-validation",
            "strategy, and random seed against what the paper actually specifies.",
            "",
            "## Deviation reporting",
            "If you must change something the paper did NOT specify in order to",
            "close the gap (e.g. a different number of CV folds, a different",
            "subsampling strategy, an added preprocessing step, a different",
            "scoring function), emit a ``DEVIATION:`` line in the script's",
            "stdout describing the change.  Example:",
            "",
            "    print('DEVIATION: Increased max_iter from default 100 to 1000 because the paper does not specify but the default did not converge')",
            "",
            "Multiple DEVIATION lines are allowed and encouraged when several",
            "changes are made.",
            "",
            "## When to give up",
            "If after re-reading the methodology and the previous attempts you",
            "judge that the gap cannot be closed without unreasonable deviation",
            "from the paper, return the SAME CODE you were given, BYTE-FOR-BYTE",
            "unchanged.  The pipeline will treat that as a signal to stop",
            "refining and record the claim as unreproducible.",
            "",
            "## Output convention (unchanged)",
            "Every metric MUST still be printed as ``RESULT:<name>=<value>``.",
            f"Load the dataset from {dataset.local_path}/data.csv using pandas.",
            "Use scikit-learn.  No network, no subprocess.  random_state=42.",
            "",
            "Output ONLY the Python code — no explanation, no markdown fences.",
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
                "Correlation is reported — consider scipy.stats.pearsonr or spearmanr, or numpy.corrcoef."
            )
        if ClaimType.P_VALUE in claim_types:
            hints.append("p-values are reported — use scipy.stats for statistical tests.")

        return "\n".join(hints)
