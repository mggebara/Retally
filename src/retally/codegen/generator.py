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
from pathlib import Path
from typing import TYPE_CHECKING

from retally.models import (
    ClaimType,
    ClaimValidationResult,
    Dataset,
    ExecutionResult,
    Language,
    Paper,
    ReproductionMode,
)

if TYPE_CHECKING:
    from retally.code.selector import SelectedFile


class UnsupportedLanguageError(NotImplementedError):
    """Raised when code generation is requested for a language we don't yet target.

    Today only ``Language.PYTHON`` is implemented.  ``R`` lands in a
    later PR; ``STATA`` is a deferred decision.  The pipeline catches
    this and converts it to a benchmark skip so a single R paper in
    the catalog doesn't crash the whole run.
    """


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
        self.prompt_log: list[str] = []
        """Every prompt sent by this generator, in call order.  Callers that
        want the prompts of one run read the slice added during it."""

    def generate(
        self,
        paper: Paper,
        dataset: Dataset,
        reference_files: list[SelectedFile] | None = None,
        package_scripts: list[SelectedFile] | None = None,
        reproduction_mode: ReproductionMode = ReproductionMode.SEEDED,
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
          - Optionally: an "Original replication scripts" section showing
            ``package_scripts`` — the authors' own analysis scripts found
            inside the replication package (the dataset directory).
            These are the ground truth for the estimating equation, so
            the prompt instructs the model to translate their
            specification exactly (not transliterate their syntax).

        ``reproduction_mode`` (default ``SEEDED``) records what the model
        may see.  ``SEEDED`` renders both optional sections above and is
        byte-identical to the prompt before the switch existed.
        ``INDEPENDENT`` withholds the authors' code: passing
        ``reference_files`` or ``package_scripts`` raises ``ValueError``
        (a silent leak would invalidate the measurement), and the prompt
        gains an "Independent Reproduction" section telling the model not
        to read any script files that appear in the dataset listing.

        Raises ``UnsupportedLanguageError`` when ``paper.language`` is
        not in ``{PYTHON, R}``.  Stata is deferred (proprietary
        runtime); UNKNOWN means classification failed and we won't guess.

        Returns the generated source code as a string.  The language of
        the returned code matches ``paper.language``.
        """
        _require_supported_language(paper, "generate")
        if reproduction_mode is ReproductionMode.INDEPENDENT and (reference_files or package_scripts):
            raise ValueError(
                "Independent reproduction withholds the authors' code; "
                "reference_files and package_scripts must be empty."
            )
        if paper.language is Language.R:
            prompt = self._build_generation_prompt_r(
                paper, dataset, reference_files or [], package_scripts or [], reproduction_mode
            )
        else:
            prompt = self._build_generation_prompt_python(
                paper, dataset, reference_files or [], package_scripts or [], reproduction_mode
            )
        response = self._call_claude(prompt)
        return self._extract_code_block(response)

    def refine(
        self,
        code: str,
        error: str,
        paper: Paper,
        dataset: Dataset,
        stdout: str = "",
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
        stdout:
            Standard output of the failed run.  A head/tail excerpt is shown
            in the prompt (when non-empty) so the model can see what its own
            diagnostic prints produced before the failure.

        Build a follow-up prompt that includes the original code and the
        error, and asks Claude to fix the specific problem.  Preserve the
        output convention requirement.
        """
        _require_supported_language(paper, "refine")
        if paper.language is Language.R:
            prompt = self._build_refinement_prompt_r(code, error, paper, dataset, stdout)
        else:
            prompt = self._build_refinement_prompt_python(code, error, paper, dataset, stdout)
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
        _require_supported_language(paper, "refine_for_claims")
        if paper.language is Language.R:
            prompt = self._build_claim_refinement_prompt_r(
                code, failed_claims, exec_result, paper, dataset, history
            )
        else:
            prompt = self._build_claim_refinement_prompt_python(
                code, failed_claims, exec_result, paper, dataset, history
            )
        response = self._call_claude(prompt)
        return self._extract_code_block(response)

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _build_generation_prompt_python(
        self,
        paper: Paper,
        dataset: Dataset,
        reference_files: list[SelectedFile],
        package_scripts: list[SelectedFile] | None = None,
        reproduction_mode: ReproductionMode = ReproductionMode.SEEDED,
    ) -> str:
        """Construct the full Python generation prompt.

        Sections:
          1. Role/context preamble
          2. Paper details (shared helper)
          3. Claims to reproduce (shared helper)
          4. Dataset details (shared helper)
          5. Output convention specification (Python-specific syntax)
          6. Code requirements (sklearn, pandas, …)
          7. Algorithm hints (Python-flavoured)
          8. Reference implementation (shared helper)
          9. Original replication scripts (shared helper)
         10. Independent-reproduction instruction (independent mode only)
        """
        lines = [
            "You are reproducing results from an older machine learning paper for validation purposes.",
            "",
        ]
        lines.extend(self._paper_section(paper))
        lines.extend(self._claims_section(paper.claims))
        lines.extend(self._dataset_section(dataset))

        lines.extend(
            [
                "## Required Output Convention",
                "Print each metric using EXACTLY this format: RESULT:<metric_name>=<numeric_value>",
                "For example: RESULT:accuracy=0.9342",
                "Use snake_case metric names matching the claim descriptions.",
                "",
            ]
        )

        lines.extend(
            [
                "## Code Requirements",
                (
                    f"Write complete, self-contained Python code using scikit-learn. "
                    f"{self._load_instruction(dataset, Language.PYTHON)} "
                    f"Use the target column from the metadata. "
                    f"Apply appropriate preprocessing (StandardScaler for numeric features, "
                    f"handle categorical with LabelEncoder or pd.get_dummies). "
                    f"Use a fixed random_state=42 for reproducibility. "
                    f"Do NOT access the internet. "
                    f"Do NOT use subprocess. "
                    f"Print all RESULT: lines at the end."
                ),
                "",
            ]
        )

        claim_types_present = {c.claim_type for c in paper.claims} if paper.claims else set()
        hint = self._algorithm_hint_python(claim_types_present)
        if hint:
            lines.extend(["## Algorithm Hints", hint, ""])

        lines.extend(self._reference_implementation_section(reference_files, dataset, "python"))
        lines.extend(self._package_scripts_section(package_scripts or [], Language.PYTHON))
        lines.extend(self._independent_mode_section(reproduction_mode))

        lines.append(
            "Now write the complete Python script. Output ONLY the code — no explanation, no markdown fences."
        )

        return "\n".join(lines)

    def _build_refinement_prompt_python(
        self, code: str, error: str, paper: Paper, dataset: Dataset, stdout: str = ""
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
            *_execution_log_section(stdout, ""),
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
            f"- {self._load_instruction(dataset, Language.PYTHON)}",
            "- Use scikit-learn for modelling.",
            "- Do NOT access the internet.",
            "- Do NOT use subprocess.",
            "- Use random_state=42 for reproducibility.",
            "- Print all RESULT: lines at the end.",
            "",
            "Output ONLY the corrected Python code — no explanation, no markdown fences.",
        ]

        return "\n".join(lines)

    def _build_claim_refinement_prompt_python(
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
            *_execution_log_section(exec_result.stdout, exec_result.stderr),
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
            self._load_instruction(dataset, Language.PYTHON),
            "Use scikit-learn.  No network, no subprocess.  random_state=42.",
            "",
            "Output ONLY the Python code — no explanation, no markdown fences.",
        ]

        return "\n".join(lines)

    # ------------------------------------------------------------------
    # R prompt builders
    # ------------------------------------------------------------------
    #
    # The R prompts share the paper / claims / dataset / reference
    # implementation sections with the Python ones — those bits are
    # language-agnostic.  Language-specific bits: role preamble, output
    # convention syntax (cat() instead of print()), code requirements
    # (read.csv / fixest / AER / plm instead of pandas / sklearn),
    # algorithm hints (econometrics-flavoured), and the closing
    # instruction (R syntax).

    def _build_generation_prompt_r(
        self,
        paper: Paper,
        dataset: Dataset,
        reference_files: list[SelectedFile],
        package_scripts: list[SelectedFile] | None = None,
        reproduction_mode: ReproductionMode = ReproductionMode.SEEDED,
    ) -> str:
        """Construct the R-flavoured generation prompt.

        Same structure as the Python version but targets R + the
        econometrics package set baked into retally-sandbox-r:
        ``fixest`` for fixed-effects regressions, ``AER`` for IV /
        Tobit, ``plm`` for panel data, ``lmtest`` + ``sandwich`` for
        robust SEs, ``modelsummary`` for tables, ``data.table`` /
        ``readr`` / ``dplyr`` for data manipulation.
        """
        lines = [
            "You are reproducing results from an econometrics paper for validation purposes.",
            "Write R code (not Python) — the paper's reference implementation is in R.",
            "",
        ]
        lines.extend(self._paper_section(paper))
        lines.extend(self._claims_section(paper.claims))
        lines.extend(self._dataset_section(dataset))

        # Output convention — note R uses cat() to write to stdout.
        lines.extend(
            [
                "## Required Output Convention",
                "Emit each reproduced metric on its own line to stdout using EXACTLY this format:",
                "    RESULT:<metric_name>=<numeric_value>",
                "For example:  cat('RESULT:beta=0.342\\n')",
                "Use snake_case metric names matching the claim descriptions.",
                "",
            ]
        )

        # Code requirements: prefer the econometrics packages in the sandbox.
        lines.extend(
            [
                "## Code Requirements",
                "Write a complete, self-contained R script that runs under Rscript.",
                self._load_instruction(dataset, Language.R),
                "Prefer the following packages, all pre-installed in the retally-sandbox-r image:",
                "  - fixest         fast fixed-effects regression (feols, feglm, fepois, …)",
                "  - AER            instrumental variables (ivreg), Tobit, count data",
                "  - plm            panel data econometrics",
                "  - lmtest         coefficient tests (coeftest)",
                "  - sandwich       robust / clustered covariance estimators (vcovHC, vcovCL)",
                "  - modelsummary   regression tables",
                "  - data.table     fast data manipulation",
                "  - dplyr / readr  tidyverse data manipulation + CSV reading",
                "  - haven          read Stata .dta / SPSS / SAS files (read_dta)",
                "Set a deterministic seed with ``set.seed(42)`` for any randomness.",
                "Do NOT access the internet; the container runs with --network none.",
                "Do NOT shell out via system() / system2().",
                "Emit RESULT:<name>=<value> lines to stdout at the end via cat().",
                "",
            ]
        )

        # Algorithm hints, R-flavoured.
        claim_types_present = {c.claim_type for c in paper.claims} if paper.claims else set()
        hint = self._algorithm_hint_r(claim_types_present)
        if hint:
            lines.extend(["## Algorithm Hints", hint, ""])

        # Reference implementation — same shape as the Python version,
        # but the code fence tag is ``r`` so a reader's markdown
        # renderer highlights it correctly.
        lines.extend(self._reference_implementation_section(reference_files, dataset, "r"))
        lines.extend(self._package_scripts_section(package_scripts or [], Language.R))
        lines.extend(self._independent_mode_section(reproduction_mode))

        lines.append(
            "Now write the complete R script. Output ONLY the code — no explanation, no markdown fences."
        )
        return "\n".join(lines)

    def _build_refinement_prompt_r(
        self, code: str, error: str, paper: Paper, dataset: Dataset, stdout: str = ""
    ) -> str:
        """R counterpart to _build_refinement_prompt_python.

        Re-shows the previous (failing) R code and the captured error,
        and asks Claude to fix the specific problem while keeping the
        output convention intact.
        """
        lines = [
            "You are fixing R code that was generated to reproduce results from an econometrics paper.",
            "",
            "## Original Code",
            "```r",
            code,
            "```",
            "",
            "## Error / Unexpected Output",
            "```",
            error,
            "```",
            "",
            *_execution_log_section(stdout, ""),
            "## Task",
            "Fix specifically the identified problem above. Do not rewrite the entire approach unless necessary.",
            "",
            "## Reminder: Output Convention",
            "The fixed R code MUST emit each reproduced metric on its own line using EXACTLY this format:",
            "    RESULT:<metric_name>=<numeric_value>",
            "For example:  cat('RESULT:beta=0.342\\n')",
            "Use snake_case metric names.",
            "",
            "## Reminder: Constraints",
            f"- {self._load_instruction(dataset, Language.R)}",
            "- Use the econometrics packages in the retally-sandbox-r image "
            "(fixest, AER, plm, lmtest, sandwich, modelsummary, data.table, readr, dplyr).",
            "- Do NOT access the internet.",
            "- Do NOT call system() / system2().",
            "- Use set.seed(42) for reproducibility.",
            "- Print all RESULT: lines at the end via cat().",
            "",
            "Output ONLY the corrected R code — no explanation, no markdown fences.",
        ]
        return "\n".join(lines)

    def _build_claim_refinement_prompt_r(
        self,
        code: str,
        failed_claims: list[ClaimValidationResult],
        exec_result: ExecutionResult,
        paper: Paper,
        dataset: Dataset,
        history: list[dict[str, float]],
    ) -> str:
        """R counterpart to _build_claim_refinement_prompt_python.

        Same shape and contract: the code ran cleanly but the reproduced
        values are outside tolerance; identify the gap and adjust.
        Returning the same code unchanged is the "this is unreproducible"
        signal.
        """
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

        outputs_block = "\n".join(f"  {k} = {v}" for k, v in exec_result.outputs.items()) or "  (none)"

        history_block = ""
        if history:
            history_lines = []
            for i, h in enumerate(history, 1):
                rendered = ", ".join(f"{k}={v}" for k, v in h.items()) or "(empty)"
                history_lines.append(f"  Attempt {i}: {rendered}")
            history_block = "\n".join(history_lines)

        lines = [
            "You are refining R code that reproduces results from an econometrics paper.",
            "The code RAN SUCCESSFULLY but the reproduced values do not match the",
            "paper's claims within the allowed tolerance.  Identify what is causing",
            "the gap and adjust the code to close it.",
            "",
            "## Paper",
            f"Title: {paper.title}",
        ]
        if paper.methodology_summary:
            lines.append(f"Methodology: {paper.methodology_summary}")
        lines.append("")

        lines += [
            "## Current Code",
            "```r",
            code,
            "```",
            "",
            "## What the code produced",
            outputs_block,
            "",
            *_execution_log_section(exec_result.stdout, exec_result.stderr),
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
            "Prefer changes that align more closely with the paper's stated methodology:",
            "re-read the methodology summary above and check the model specification,",
            "covariate selection, fixed effects, clustering, and seed against what the",
            "paper actually specifies.  In econometrics papers, common gap-closers are:",
            "  - getting the cluster-robust SE right (vcovCL / cluster_var argument)",
            "  - matching the paper's exact fixed-effects structure",
            "  - using the same sample-restriction filters the paper applied",
            "  - matching the paper's weighting scheme (weights= argument)",
            "",
            "## Deviation reporting",
            "If you must change something the paper did NOT specify in order to close",
            "the gap, emit a ``DEVIATION:`` line via cat() describing the change:",
            "",
            "    cat('DEVIATION: Used HC1 robust SE because the paper does not specify but the default did not converge\\n')",
            "",
            "## When to give up",
            "If after re-reading the methodology and the previous attempts you judge",
            "the gap cannot be closed without unreasonable deviation, return the SAME",
            "R CODE you were given, BYTE-FOR-BYTE unchanged.  The pipeline will record",
            "the claim as unreproducible.",
            "",
            "## Output convention (unchanged)",
            "Emit every metric as ``cat('RESULT:<name>=<value>\\n')``.",
            self._load_instruction(dataset, Language.R),
            "Use the econometrics packages in the retally-sandbox-r image.",
            "No network, no system().  set.seed(42).",
            "",
            "Output ONLY the R code — no explanation, no markdown fences.",
        ]

        return "\n".join(lines)

    # ------------------------------------------------------------------
    # Shared section helpers
    # ------------------------------------------------------------------
    #
    # These format the language-agnostic parts of the prompts: paper
    # info, claims list, dataset info, and the reference-implementation
    # block.  Each returns a list of lines that the language-specific
    # builders concatenate; trailing empty string for section spacing.

    def _paper_section(self, paper: Paper) -> list[str]:
        lines = ["## Paper Information", f"Title: {paper.title}"]
        if paper.abstract:
            lines.append(f"Abstract (first 500 chars): {paper.abstract[:500]}")
        if paper.methodology_summary:
            lines.append(f"Methodology Summary: {paper.methodology_summary}")
        lines.append("")
        return lines

    def _claims_section(self, claims) -> list[str]:
        lines = ["## Claims to Reproduce"]
        if claims:
            for i, claim in enumerate(claims, 1):
                unit_str = f" ({claim.unit})" if claim.unit else ""
                lines.append(
                    f"{i}. {claim.description}: {claim.value}{unit_str} [type: {claim.claim_type.value}]"
                )
        else:
            lines.append("No specific claims listed — reproduce the main reported metrics.")
        lines.append("")
        return lines

    def _dataset_section(self, dataset: Dataset) -> list[str]:
        root = _prompt_dataset_root(dataset)
        lines = [
            "## Dataset Information",
            f"Name: {dataset.name}",
            f"Local path: {root}",
            f"File format: {dataset.file_format}",
        ]
        if dataset.metadata:
            if "columns" in dataset.metadata:
                lines.append(f"Columns: {dataset.metadata['columns']}")
            if "target_column" in dataset.metadata:
                lines.append(f"Target column: {dataset.metadata['target_column']}")
            if "n_rows" in dataset.metadata:
                lines.append(f"Number of rows: {dataset.metadata['n_rows']}")
            if "task_type" in dataset.metadata:
                lines.append(f"Task type: {dataset.metadata['task_type']}")
        tree = _describe_dataset_files(root)
        if tree:
            lines.append("Files in the dataset directory (paths relative to the local path above):")
            lines.extend(tree)
        lines.append("")
        return lines

    @staticmethod
    def _load_instruction(dataset: Dataset, language: Language) -> str:
        """One-sentence instruction for where and how to load the data.

        Registry datasets are normalised by the downloader to a single
        ``data.csv`` at the dataset root; replication packages (e.g. an
        unpacked Zenodo archive) are arbitrary directory trees.  Point the
        model at whichever shape actually exists so it doesn't hardcode a
        ``data.csv`` path that isn't there — which is exactly what sank
        the first benchmark run.
        """
        root = _prompt_dataset_root(dataset)
        single_csv = root / "data.csv"
        if single_csv.is_file():
            if language is Language.R:
                return f"Load the dataset from '{single_csv}' using read.csv() or readr::read_csv()."
            return f"Load the dataset from {single_csv} using pandas."
        if language is Language.R:
            return (
                f"The dataset is a directory tree at '{root}' — see the file "
                "listing under Dataset Information.  Load the actual data file(s) by the "
                "exact paths listed there (readr::read_csv() for .csv, haven::read_dta() "
                "for Stata .dta)."
            )
        return (
            f"The dataset is a directory tree at {root} — see the file "
            "listing under Dataset Information.  Load the actual data file(s) by the "
            "exact paths listed there (pandas.read_csv for .csv, pandas.read_stata "
            "for Stata .dta)."
        )

    def _reference_implementation_section(
        self, reference_files: list[SelectedFile], dataset: Dataset, code_fence_tag: str
    ) -> list[str]:
        """Render the reference-implementation block when files are present.

        Returns empty list when no reference files were selected, so the
        caller can extend() unconditionally and not get an empty section
        header.  ``code_fence_tag`` is the language tag inside the
        triple-backticks for each file.
        """
        if not reference_files:
            return []
        lines = [
            "## Reference Implementation",
            (
                "The paper links a public code repository.  The most relevant "
                f"{code_fence_tag} source files from that repository are reproduced below.  "
                "PREFER ADAPTING these files over writing from scratch: keep the "
                "model specification, hyperparameters, preprocessing, and "
                "sample-construction conventions as close to the reference as "
                "possible.  You may need to change file paths (load the dataset "
                f"from the files under {_prompt_dataset_root(dataset)} — see the listing in "
                "Dataset Information — instead of whatever paths the "
                "reference uses) and you may need to omit code unrelated to the "
                "specific claims being reproduced.  Where the reference deviates "
                "from the paper's text, prefer the reference."
            ),
            "",
        ]
        for ref_file in reference_files:
            lines.append(f"### `{ref_file.relative_path}`")
            lines.append(f"```{code_fence_tag}")
            lines.append(ref_file.contents)
            lines.append("```")
            lines.append("")
        return lines

    def _package_scripts_section(
        self, package_scripts: list[SelectedFile], target_language: Language
    ) -> list[str]:
        """Render the authors' own replication-package scripts.

        These come from inside the dataset directory (an unpacked
        replication archive), not from a linked repo — they are the
        single most authoritative description of the estimating
        equation, variable names, sample restrictions, and clustering
        the paper actually used.  Returns empty list when no scripts
        were found so callers can extend() unconditionally.
        """
        if not package_scripts:
            return []
        target = "R" if target_language is Language.R else "Python"
        lines = [
            "## Original Replication Scripts",
            (
                "The replication package (the dataset directory) ships the "
                "authors' own analysis scripts, reproduced below.  These are "
                "the GROUND TRUTH for the exact estimating equation, variable "
                "names, sample restrictions, fixed effects, and standard-error "
                "clustering — follow them over anything reconstructed from the "
                "methodology summary, and prefer them over the paper's text "
                f"where the two disagree.  Your job is to write {target} code "
                "that implements the SAME SPECIFICATION: translate what the "
                "scripts estimate, do not transliterate their syntax line by "
                "line (a Stata .do file's regression, e.g. "
                "`reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the "
                "equivalent fixest::feols() call in R).  Keep only the parts "
                "that produce the specific claims being reproduced; skip "
                "figure construction and unrelated robustness checks.  The "
                "scripts' data-file paths refer to the package's internal "
                "layout — resolve them against the dataset directory listed "
                "under Dataset Information."
            ),
            "",
        ]
        if target_language is Language.R and any(
            s.relative_path.lower().endswith(".do") for s in package_scripts
        ):
            lines.extend(
                [
                    (
                        "Stata-to-fixest sample matching: feols() drops fixed-effect "
                        "singletons by default, but Stata's `reg y x i.fe` / `xi:` "
                        'dummies keep them.  Pass `fixef.rm = "none"` to every '
                        "feols() call that has fixed effects, otherwise the "
                        "observation count and the robust SEs drift from the "
                        "paper's.  Stata's `, r` / `vce(robust)` is "
                        '`vcov = "hetero"`.'
                    ),
                    "",
                ]
            )
        for script in package_scripts:
            lines.append(f"### `{script.relative_path}`")
            lines.append(f"```{_fence_tag_for(script.relative_path)}")
            lines.append(script.contents)
            lines.append("```")
            lines.append("")
        return lines

    @staticmethod
    def _independent_mode_section(reproduction_mode: ReproductionMode) -> list[str]:
        """Instruction block for independent reproduction; empty when seeded.

        The dataset directory is mounted into the sandbox as-is, so a
        replication package's own ``.do`` / ``.R`` scripts are still on
        disk (and named in the listing) even when their contents are
        withheld from the prompt.  Without an explicit instruction the
        model could read them at run time and quietly turn an independent
        reproduction back into a seeded one.  Returns ``[]`` for
        ``SEEDED`` so the seeded prompt stays byte-identical.
        """
        if reproduction_mode is not ReproductionMode.INDEPENDENT:
            return []
        return [
            "## Independent Reproduction",
            (
                "This is an INDEPENDENT reproduction: reconstruct the analysis "
                "from the paper's description alone.  The authors' own analysis "
                "code is deliberately withheld.  Do NOT open, read, source, or "
                "execute any script files that may appear in the dataset "
                "directory listing (.do, .ado, .R, .Rmd, .py, .sas, .sps, .m, "
                "and similar) — load data files only.  Derive the estimating "
                "equation, sample restrictions, fixed effects, and "
                "standard-error clustering from the paper information and "
                "claims above."
            ),
            "",
        ]

    def _call_claude(self, prompt: str) -> str:
        """Send a prompt to the Claude API and return the response text."""
        self.prompt_log.append(prompt)
        response = self._client.messages.create(
            model=self._model,
            max_tokens=8192,
            messages=[{"role": "user", "content": prompt}],
        )
        return response.content[0].text

    def _extract_code_block(self, response: str) -> str:
        """Strip a markdown code fence (```python / ```r / bare ```) if present.

        Falls back to the raw response when no fence is found.  The fence
        language tag is permissive: ``python``, ``py``, ``r``, ``R``, or
        absent all match — the calling generator already knows which
        language it asked for, so the tag here is just decoration.
        """
        pattern = re.compile(r"```(?:python|py|r|R)?\s*\n(.*?)```", re.DOTALL)
        match = pattern.search(response)
        if match:
            return match.group(1).strip()
        return response.strip()

    # ------------------------------------------------------------------
    # Private utility
    # ------------------------------------------------------------------

    @staticmethod
    def _algorithm_hint_python(claim_types: set) -> str:
        """Python-flavoured algorithm hints for the claim types seen."""
        hints = []

        classification_types = {
            ClaimType.ACCURACY,
            ClaimType.F1_SCORE,
            ClaimType.PRECISION,
            ClaimType.RECALL,
            ClaimType.AUC_ROC,
        }
        regression_types = {ClaimType.RMSE, ClaimType.MAE}
        econometric_types = {ClaimType.COEFFICIENT, ClaimType.STANDARD_ERROR, ClaimType.R_SQUARED}

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
        if claim_types & econometric_types:
            hints.append(
                "This paper reports econometric quantities (coefficients / standard errors / R²). "
                "In Python that means statsmodels: ``statsmodels.api.OLS`` or ``statsmodels.formula.api.ols`` "
                "for OLS with HC-robust SE via ``.get_robustcov_results('HC1')``, "
                "``statsmodels.discrete.discrete_model.Logit`` for binary outcomes, and "
                "``statsmodels.regression.linear_model.WLS`` for weighted models.  "
                "For instrumental variables and panel data use ``linearmodels`` if available; "
                "otherwise stick to statsmodels.  Emit each coefficient and SE as a separate "
                "RESULT: line with the variable name in the metric name."
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

    @staticmethod
    def _algorithm_hint_r(claim_types: set) -> str:
        """R-flavoured algorithm hints for the claim types seen.

        Targets the econometrics packages in the retally-sandbox-r image:
        fixest for fixed-effects / IV, AER for instrumental variables,
        plm for panel data, lmtest + sandwich for robust SEs.
        """
        hints = []
        regression_types = {ClaimType.RMSE, ClaimType.MAE}
        econometric_types = {ClaimType.COEFFICIENT, ClaimType.STANDARD_ERROR, ClaimType.R_SQUARED}

        # Default-but-conditional: emit the coefficient/SE guidance only
        # when the paper actually reports those.  Previously this hint
        # fired for every R paper unconditionally, which crowded out
        # the metric-specific hints below.
        if claim_types & econometric_types or not claim_types:
            hints.append(
                "This paper reports regression coefficients with standard errors. "
                "Default to fixest::feols() for OLS with fixed effects; switch to AER::ivreg() "
                "for instrumental variables and plm::plm() for panel data.  Use the cluster "
                "argument or cluster_var argument in feols() / vcovCL() from sandwich for "
                "cluster-robust standard errors.  Extract each coefficient via "
                "``coef(model)['varname']`` and each SE via "
                "``sqrt(diag(vcov(model)))['varname']`` so they can be emitted as separate "
                "RESULT: lines."
            )
        if ClaimType.R_SQUARED in claim_types:
            hints.append(
                "R-squared is reported — fixest provides ``r2(model)``; base R via "
                "``summary(model)$r.squared`` (and ``adj.r.squared`` for adjusted)."
            )
        if claim_types & regression_types:
            hints.append(
                "RMSE / MAE are reported — predict() the model on the held-out sample and "
                "compute residuals manually; sqrt(mean(residuals^2)) for RMSE, "
                "mean(abs(residuals)) for MAE."
            )
        if ClaimType.CORRELATION in claim_types:
            hints.append("Correlation is reported — use stats::cor() with method='pearson' or 'spearman'.")
        if ClaimType.P_VALUE in claim_types:
            hints.append(
                "p-values are reported — extract them from summary(model)$coefficients[,'Pr(>|t|)'] "
                "or lmtest::coeftest(model, vcov=sandwich::vcovHC); use lmtest::lrtest for "
                "likelihood-ratio tests."
            )

        return "\n".join(hints)


# ---------------------------------------------------------------------------
# Module helpers
# ---------------------------------------------------------------------------


_SUPPORTED_LANGUAGES = frozenset({Language.PYTHON, Language.R})

# Caps for the dataset file listing embedded in generation prompts.  A
# replication package can contain hundreds of files; the listing exists to
# orient the model toward the real data files, not to inventory everything,
# so it truncates with an explicit marker beyond these bounds.
_TREE_MAX_FILES = 80
_TREE_MAX_CSV_HEADERS = 10
_TREE_MAX_DTA_HEADERS = 10
_TREE_HEADER_CHARS = 240


def _fence_tag_for(relative_path: str) -> str:
    """Markdown code-fence language tag for a replication-package script.

    Purely cosmetic — the model reads the content either way — but a
    correct tag helps any human reading a logged prompt.
    """
    suffix = Path(relative_path).suffix.lower()
    return {
        ".do": "stata",
        ".r": "r",
        ".rmd": "r",
        ".py": "python",
    }.get(suffix, "text")


def _prompt_dataset_root(dataset: Dataset) -> Path:
    """Absolute path the generated code must read the dataset from.

    The Docker executors mount the dataset with
    ``-v {dataset.local_path.resolve()}:{same}:ro`` and run with
    ``--workdir /workspace``.  ``dataset.local_path`` itself is *relative*
    (the downloader caches under ``.cache/datasets``), so a prompt that
    embeds it verbatim makes the model emit ``list.files(".cache/...")`` /
    ``read.csv(".cache/...")`` — paths that resolve against ``/workspace``
    inside the container and don't exist, which is what made the generated
    R stop with "No .dta or .csv files found".  Every dataset path we put
    in the prompt must be this resolved absolute path so it matches the
    mount.  ``.resolve()`` here and in the executor run in the same process
    (same CWD), so they produce the identical string.
    """
    return dataset.local_path.resolve()


def _describe_dataset_files(root: Path) -> list[str]:
    """One prompt line per file under ``root``: relative path, size, column names.

    Column names are shown for ``.csv`` (the header line) and Stata
    ``.dta`` files (the variable names, read from the file header only —
    no data rows are loaded), each under the same caps: at most
    ``_TREE_MAX_CSV_HEADERS`` / ``_TREE_MAX_DTA_HEADERS`` files per format,
    each truncated to ``_TREE_HEADER_CHARS`` with a marker.  ``.dta``
    lines also give the column count, since wide Stata files are usually
    truncated.  ``.rds`` / ``.RData`` / ``.sav`` get no columns: no reader
    for them is a dependency.

    Registry datasets are a single ``data.csv`` and get a one-line listing;
    replication packages (e.g. an unpacked Zenodo archive) are arbitrary
    trees of ``.dta`` / ``.csv`` / ``.R`` / shapefile pieces, and without
    this listing the model has no way to know which files exist or what
    they're called — it would guess ``data.csv`` and fail.

    Sorted for prompt determinism.  Hidden files/directories are skipped.
    Returns ``[]`` when ``root`` isn't a directory or contains no files.
    """
    if not root.is_dir():
        return []
    files = sorted(
        p
        for p in root.rglob("*")
        if p.is_file() and not any(part.startswith(".") for part in p.relative_to(root).parts)
    )
    lines: list[str] = []
    csv_headers_shown = 0
    dta_headers_shown = 0
    for p in files[:_TREE_MAX_FILES]:
        line = f"- {p.relative_to(root)} ({_human_size(p.stat().st_size)})"
        suffix = p.suffix.lower()
        if suffix == ".csv" and csv_headers_shown < _TREE_MAX_CSV_HEADERS:
            header = _csv_header(p)
            if header:
                line += f" — columns: {header}"
                csv_headers_shown += 1
        elif suffix == ".dta" and dta_headers_shown < _TREE_MAX_DTA_HEADERS:
            names = _dta_columns(p)
            if names:
                line += f" — {len(names)} columns: {_truncate_header(', '.join(names))}"
                dta_headers_shown += 1
        lines.append(line)
    overflow = len(files) - _TREE_MAX_FILES
    if overflow > 0:
        lines.append(f"- … and {overflow} more files (listing truncated)")
    return lines


# Bounds for the execution-log excerpt fed back into refinement prompts:
# the first and last N characters of each stream.  The head keeps the
# model's early diagnostics (e.g. ``print(names(df))``), the tail keeps
# the results and any final error; a long middle is elided with a marker.
_LOG_HEAD_CHARS = 3000
_LOG_TAIL_CHARS = 3000


def _head_tail(text: str, head: int = _LOG_HEAD_CHARS, tail: int = _LOG_TAIL_CHARS) -> str:
    """``text`` if short, else its first ``head`` and last ``tail`` chars with an elision marker."""
    text = text.strip()
    if len(text) <= head + tail:
        return text
    omitted = len(text) - head - tail
    return f"{text[:head]}\n[... {omitted} characters omitted ...]\n{text[-tail:]}"


def _execution_log_section(stdout: str, stderr: str) -> list[str]:
    """Prompt lines showing a bounded excerpt of the last run's stdout/stderr.

    Refinement prompts used to show only the parsed ``RESULT:`` values (or
    stderr), so whatever the generated code printed to find its way around
    the data -- column names, row counts, regex hits -- was discarded.
    Returns ``[]`` when both streams are empty, leaving the prompt as it was.
    """
    lines: list[str] = []
    for label, text in (("stdout", stdout), ("stderr", stderr)):
        excerpt = _head_tail(text or "")
        if excerpt:
            lines += [
                f"## Last run's {label} (excerpt: first/last {_LOG_HEAD_CHARS} characters)",
                "```",
                excerpt,
                "```",
                "",
            ]
    return lines


def _human_size(n_bytes: int) -> str:
    """Format a byte count for prompt display, e.g. ``12.3 KB``."""
    size = float(n_bytes)
    for unit in ("B", "KB", "MB", "GB"):
        if size < 1024 or unit == "GB":
            return f"{size:.0f} {unit}" if unit == "B" else f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} GB"  # pragma: no cover — loop always returns


def _csv_header(path: Path) -> str:
    """First line of a CSV, truncated for prompt use.  '' on any read error."""
    try:
        with path.open("r", encoding="utf-8", errors="replace") as f:
            header = f.readline().strip()
    except OSError:
        return ""
    return _truncate_header(header)


def _truncate_header(header: str) -> str:
    if len(header) > _TREE_HEADER_CHARS:
        header = header[:_TREE_HEADER_CHARS] + "…"
    return header


def _dta_columns(path: Path) -> list[str]:
    """Variable names of a Stata ``.dta`` file, in file order.  [] on any error.

    ``pandas.read_stata(..., iterator=True)`` parses the header lazily;
    ``variable_labels()`` reads only the header (variable names, labels),
    never the data rows, so this stays cheap on multi-GB files.
    """
    try:
        import pandas as pd

        with pd.read_stata(path, iterator=True) as reader:
            return [str(name) for name in reader.variable_labels()]
    except Exception:
        return []


def _require_supported_language(paper: Paper, op: str) -> None:
    """Raise UnsupportedLanguageError when paper.language is unsupported.

    Centralised so every public generator method enforces the same rule.
    The caller catches the error and converts it to a benchmark skip or
    pipeline-level error — never silently downgrades to a wrong-language
    attempt, which would produce nonsense code with no feedback to the
    user.

    Today: PYTHON and R are supported.  STATA is deferred (proprietary
    runtime); UNKNOWN means we couldn't classify and shouldn't guess.
    """
    if paper.language not in _SUPPORTED_LANGUAGES:
        raise UnsupportedLanguageError(
            f"CodeGenerator.{op}() does not yet support language={paper.language.value}; "
            f"supported: {sorted(lang.value for lang in _SUPPORTED_LANGUAGES)}."
        )
