"""
ValidationReporter — assembles all pipeline outputs into a ValidationReport
and renders it in human-readable formats.

Output formats:
  - Markdown (for GitHub issues, Notion, etc.)
  - JSON (for downstream processing or storage)
  - Console (coloured summary for interactive use)
"""

from __future__ import annotations

import dataclasses
import json
import math
from enum import Enum
from pathlib import Path

from openra.models import (
    ClaimValidationResult,
    Dataset,
    ExecutionResult,
    Paper,
    ValidationReport,
)

# ANSI colour codes
_GREEN = "\033[92m"
_RED = "\033[91m"
_RESET = "\033[0m"


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
        n_total = len(claim_results)
        n_passed = sum(1 for r in claim_results if r.passed)
        # A paper with zero extracted claims has not been validated against
        # anything, so we do not call it PASSED.
        overall_passed = n_total > 0 and n_passed == n_total

        if n_total == 0:
            summary_parts = ["No claims were extracted from the paper; nothing to validate."]
        else:
            summary_parts = [f"{n_passed} of {n_total} claims validated."]
            failed = [r for r in claim_results if not r.passed]
            if failed:
                failed_names = ", ".join(r.claim.description for r in failed)
                summary_parts.append(f"Failed: {failed_names}.")

        summary = " ".join(summary_parts)

        return ValidationReport(
            paper=paper,
            dataset=dataset,
            execution_result=execution_result,
            claim_results=claim_results,
            overall_passed=overall_passed,
            summary=summary,
        )

    def to_markdown(self, report: ValidationReport) -> str:
        """Render the report as a Markdown document."""
        lines: list[str] = []

        # Header
        lines.append(f"# Validation Report: {report.paper.title}")
        lines.append("")

        # Overall status badge
        if report.overall_passed:
            lines.append("**Overall**: ✓ PASSED")
        else:
            lines.append("**Overall**: ✗ FAILED")
        lines.append("")

        # Summary
        lines.append(f"**Summary**: {report.summary}")
        lines.append("")

        # Dataset info
        lines.append(f"**Dataset**: {report.dataset.name} ({report.dataset.source_url})")
        lines.append("")

        # Claims table
        lines.append("## Claims")
        lines.append("")
        lines.append("| Claim | Paper Value | Reproduced | Tolerance | Status |")
        lines.append("|-------|-------------|------------|-----------|--------|")

        for r in report.claim_results:
            claim_desc = r.claim.description
            paper_val = str(r.claim.value)
            if r.claim.unit:
                paper_val += f" {r.claim.unit}"
            if r.reproduced_value is not None:
                reproduced_str = f"{r.reproduced_value:.6g}"
            else:
                reproduced_str = "N/A"
            tolerance_str = f"{r.tolerance:.4g}"
            status = "✓ PASSED" if r.passed else "✗ FAILED"
            lines.append(f"| {claim_desc} | {paper_val} | {reproduced_str} | {tolerance_str} | {status} |")

        lines.append("")

        # Notes for failed claims
        failed_with_notes = [r for r in report.claim_results if not r.passed and r.notes]
        if failed_with_notes:
            lines.append("## Notes")
            lines.append("")
            for r in failed_with_notes:
                lines.append(f"- **{r.claim.description}**: {r.notes}")
            lines.append("")

        # Generated Code
        lines.append("## Generated Code")
        lines.append("")
        lines.append("```python")
        lines.append(report.execution_result.generated_code)
        lines.append("```")
        lines.append("")

        # Execution Output
        lines.append("## Execution Output")
        lines.append("")
        lines.append("```")
        lines.append(report.execution_result.stdout)
        lines.append("```")
        lines.append("")

        # Stderr (only if non-empty)
        if report.execution_result.stderr:
            lines.append("## Stderr")
            lines.append("")
            lines.append("```")
            lines.append(report.execution_result.stderr)
            lines.append("```")
            lines.append("")

        return "\n".join(lines)

    def to_json(self, report: ValidationReport) -> str:
        """Serialise the report to a JSON string.

        Convert all dataclasses to dicts (use ``dataclasses.asdict``), handle
        non-serialisable types (Path → str, enums → .value, nan/inf → None).
        Return ``json.dumps(data, indent=2)``.
        """
        data = dataclasses.asdict(report)

        def _clean(obj):
            if isinstance(obj, dict):
                return {k: _clean(v) for k, v in obj.items()}
            elif isinstance(obj, list):
                return [_clean(v) for v in obj]
            elif isinstance(obj, Path):
                return str(obj)
            elif isinstance(obj, Enum):
                return obj.value
            elif isinstance(obj, float):
                if math.isnan(obj) or math.isinf(obj):
                    return None
                return obj
            return obj

        cleaned = _clean(data)
        return json.dumps(cleaned, indent=2)

    def to_console(self, report: ValidationReport) -> str:
        """Return a short console-friendly summary (no markdown).

        Use ANSI colour codes: green for PASSED, red for FAILED.
        Show each claim on one line with its status.
        """
        lines: list[str] = []

        # Overall status
        if report.overall_passed:
            overall_str = f"{_GREEN}PASSED{_RESET}"
        else:
            overall_str = f"{_RED}FAILED{_RESET}"

        lines.append(f"Validation Report: {report.paper.title}")
        lines.append(f"Overall: {overall_str}")
        lines.append(f"Summary: {report.summary}")
        lines.append("")

        for r in report.claim_results:
            if r.passed:
                status = f"{_GREEN}PASSED{_RESET}"
            else:
                status = f"{_RED}FAILED{_RESET}"

            if r.reproduced_value is not None:
                repro_str = f"{r.reproduced_value:.6g}"
            else:
                repro_str = "N/A"

            lines.append(f"  [{status}] {r.claim.description}: paper={r.claim.value}, reproduced={repro_str}")

        return "\n".join(lines)

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
        path = Path(path)

        # Infer format from suffix if the caller passed the default
        suffix = path.suffix.lower()
        if suffix == ".md":
            fmt = "markdown"
        elif suffix == ".json":
            fmt = "json"

        if fmt == "markdown":
            content = self.to_markdown(report)
        elif fmt == "json":
            content = self.to_json(report)
        else:
            raise ValueError(f"Unsupported format: {fmt!r}. Use 'markdown' or 'json'.")

        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
