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
    AuditStatus,
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

        # Reference code lifted from the paper, when any
        if report.paper.code_references:
            lines.append("**Reference code**:")
            for ref in report.paper.code_references:
                status = "cloned" if ref.local_path else "found but not fetched"
                lines.append(f"- [{ref.url}]({ref.url}) ({status})")
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

        # Refinement summary + methodology deviations
        exec_result = report.execution_result
        if exec_result.claim_refinement_attempts > 0 or exec_result.deviation_notes:
            lines.append("## Refinement")
            lines.append("")
            if exec_result.claim_refinement_attempts > 0:
                attempts = exec_result.claim_refinement_attempts
                lines.append(
                    f"The pipeline ran **{attempts} claim-targeted refinement "
                    f"pass{'es' if attempts != 1 else ''}** after the initial "
                    "execution succeeded, attempting to close the gap between "
                    "reproduced values and paper claims."
                )
                lines.append("")
            if exec_result.deviation_notes:
                lines.append("Methodology deviations declared during refinement:")
                lines.append("")
                for note in exec_result.deviation_notes:
                    lines.append(f"- {note}")
                lines.append("")

        # Hyperparameter audit — only render when the paper specified
        # hyperparameters that we actually checked against.
        if exec_result.hyperparameter_audits:
            lines.extend(self._hyperparameter_audit_section(exec_result))

        # Generated Code — fence tag matches the execution result's language
        # so a reader's markdown renderer highlights it correctly.  Defaults
        # to ``python`` because ExecutionResult.language defaults to PYTHON
        # for byte-identical rendering of existing reports.
        lines.append("## Generated Code")
        lines.append("")
        lines.append(f"```{report.execution_result.language.value}")
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

    def _hyperparameter_audit_section(self, exec_result: ExecutionResult) -> list[str]:
        """Render the hyperparameter-audit block as markdown lines.

        Headline summarises matched / total; the table lists every audit
        with its observed value and any note.  When every audit is MATCH
        the section still renders, on purpose — readers benefit from
        confirmation that the paper's hyperparameters made it through.
        """
        audits = exec_result.hyperparameter_audits
        n_total = len(audits)
        n_match = sum(1 for a in audits if a.status is AuditStatus.MATCH)

        lines = ["## Hyperparameter audit", ""]
        if n_match == n_total:
            lines.append(
                f"All **{n_total}** paper-stated hyperparameter"
                f"{'s' if n_total != 1 else ''} matched the generated code."
            )
        else:
            lines.append(
                f"**{n_match} of {n_total}** paper-stated hyperparameters "
                "matched the generated code.  Non-matches do not affect "
                "claim validation but flag a reproduction-fidelity concern."
            )
        lines.append("")
        lines.append("| Parameter | Paper value | Observed | Status | Notes |")
        lines.append("|---|---|---|---|---|")
        for a in audits:
            observed = "—" if a.observed_value is None else repr(a.observed_value)
            status_icon = {
                AuditStatus.MATCH: "✓ match",
                AuditStatus.MISMATCH: "✗ mismatch",
                AuditStatus.NOT_FOUND: "○ not_found",
                AuditStatus.UNRESOLVED: "? unresolved",
            }[a.status]
            notes = a.notes.replace("|", "\\|") if a.notes else ""
            lines.append(f"| `{a.spec.name}` | {a.spec.value!r} | {observed} | {status_icon} | {notes} |")
        lines.append("")
        return lines

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
        if report.paper.code_references:
            n_cloned = sum(1 for r in report.paper.code_references if r.local_path)
            n_total = len(report.paper.code_references)
            lines.append(f"Reference code: {n_cloned}/{n_total} cloned")
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

        exec_result = report.execution_result
        if exec_result.claim_refinement_attempts > 0 or exec_result.deviation_notes:
            lines.append("")
            if exec_result.claim_refinement_attempts > 0:
                attempts = exec_result.claim_refinement_attempts
                lines.append(
                    f"  (ran {attempts} claim-targeted refinement pass{'es' if attempts != 1 else ''})"
                )
            for note in exec_result.deviation_notes:
                lines.append(f"  ! Deviation: {note}")

        if exec_result.hyperparameter_audits:
            audits = exec_result.hyperparameter_audits
            n_total = len(audits)
            n_match = sum(1 for a in audits if a.status is AuditStatus.MATCH)
            colour = _GREEN if n_match == n_total else _RED
            lines.append("")
            lines.append(f"  Hyperparameter audit: {colour}{n_match}/{n_total} matched{_RESET}")
            for audit in audits:
                if audit.status is AuditStatus.MATCH:
                    continue
                lines.append(
                    f"    ! {audit.spec.name}: {audit.status.value}"
                    + (f" — {audit.notes}" if audit.notes else "")
                )

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
