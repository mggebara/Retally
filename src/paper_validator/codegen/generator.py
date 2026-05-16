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

from paper_validator.models import Dataset, Paper


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
        raise NotImplementedError

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
        raise NotImplementedError

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
        raise NotImplementedError

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
        raise NotImplementedError

    def _call_claude(self, prompt: str) -> str:
        """Send a prompt to the Claude API and return the response text."""
        raise NotImplementedError

    def _extract_code_block(self, response: str) -> str:
        """Extract the Python code block from a Claude response.

        Strip markdown fences (```python ... ```) if present.
        If no fence is found, return the raw response stripped of leading/
        trailing whitespace.
        """
        raise NotImplementedError
