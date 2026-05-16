"""
ValidationReporter — assembles all pipeline outputs into a ValidationReport
and renders it in human-readable formats.

Output formats:
  - Markdown (for GitHub issues, Notion, etc.)
  - JSON (for downstream processing or storage)
  - Console (coloured summary for interactive use)
"""

from __future__ import annotations

import json
from pathlib import Path

from paper_validator.models import (
    ClaimValidationResult,
    Dataset,
    ExecutionResult,
    Paper,
    ValidationReport,
)


class ValidationReporter:
    """Builds and serialises ValidationReport objects."""

    def build(
        self,
        paper: Paper,
        dataset: Dataset,
        execution_result: ExecutionResult,
        claim_results: list[ClaimValidationResult],
    ) -> ValidationReport:
        """Assemble a ValidationReport from pipeline components.

        ``overall_passed`` is True only when ALL claims passed.
        ``summary`` should be a one-paragraph human-readable overview
        (e.g. "3 of 4 claims validated; 1 failed (test_accuracy)").
        """
        raise NotImplementedError

    def to_markdown(self, report: ValidationReport) -> str:
        """Render the report as a Markdown document.

        Suggested structure:
          # Validation Report: <paper title>
          **Overall**: PASSED / FAILED
          ## Claims
          | Claim | Paper value | Reproduced | Tolerance | Status |
          |-------|-------------|------------|-----------|--------|
          ...
          ## Generated Code
          ```python
          <code>
          ```
          ## Execution Output
          ```
          <stdout>
          ```
          ## Notes
          <any warnings or failures>
        """
        raise NotImplementedError

    def to_json(self, report: ValidationReport) -> str:
        """Serialise the report to a JSON string.

        Convert all dataclasses to dicts (use ``dataclasses.asdict``), handle
        non-serialisable types (Path → str, enums → .value).
        Return ``json.dumps(data, indent=2)``.
        """
        raise NotImplementedError

    def to_console(self, report: ValidationReport) -> str:
        """Return a short console-friendly summary (no markdown).

        Use ANSI colour codes: green for PASSED, red for FAILED.
        Show each claim on one line with its status.
        """
        raise NotImplementedError

    def save(self, report: ValidationReport, path: Path, fmt: str = "markdown") -> None:
        """Save the report to a file.

        Parameters
        ----------
        path:
            Destination file path.
        fmt:
            One of ``"markdown"``, ``"json"``.  Inferred from ``path.suffix``
            if not provided (`.md` → markdown, `.json` → json).
        """
        raise NotImplementedError
