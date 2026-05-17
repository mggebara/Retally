"""Tests for ValidationReporter."""

from pathlib import Path

from openra.models import (
    AuditStatus,
    Claim,
    ClaimType,
    ClaimValidationResult,
    Dataset,
    ExecutionResult,
    HyperparameterAudit,
    HyperparameterSpec,
    Paper,
)
from openra.validation.reporter import ValidationReporter


def _paper() -> Paper:
    return Paper(title="Test Paper")


def _dataset() -> Dataset:
    return Dataset(name="dummy", source_url="http://example.com/ds.csv", local_path=Path("/tmp/dummy"))


def _exec_result() -> ExecutionResult:
    return ExecutionResult(generated_code="print('hi')", exit_code=0)


def test_build_with_empty_claims_is_not_passed():
    reporter = ValidationReporter()
    report = reporter.build(_paper(), _dataset(), _exec_result(), claim_results=[])
    # A paper with no extracted claims hasn't been validated against anything,
    # so we must not call it PASSED.
    assert report.overall_passed is False
    assert "No claims" in report.summary


def test_build_with_all_claims_passing():
    reporter = ValidationReporter()
    claim = Claim(description="accuracy", value=0.95, claim_type=ClaimType.ACCURACY)
    cr = ClaimValidationResult(claim=claim, reproduced_value=0.95, passed=True)
    report = reporter.build(_paper(), _dataset(), _exec_result(), claim_results=[cr])
    assert report.overall_passed is True
    assert "1 of 1" in report.summary


def test_build_with_one_failing_claim():
    reporter = ValidationReporter()
    c1 = Claim(description="accuracy", value=0.95, claim_type=ClaimType.ACCURACY)
    c2 = Claim(description="f1", value=0.90, claim_type=ClaimType.F1_SCORE)
    r1 = ClaimValidationResult(claim=c1, reproduced_value=0.95, passed=True)
    r2 = ClaimValidationResult(claim=c2, reproduced_value=0.50, passed=False)
    report = reporter.build(_paper(), _dataset(), _exec_result(), claim_results=[r1, r2])
    assert report.overall_passed is False
    assert "1 of 2" in report.summary
    assert "f1" in report.summary


def _report_with_refinement(deviations: list[str], attempts: int):
    reporter = ValidationReporter()
    claim = Claim(description="accuracy", value=0.95, claim_type=ClaimType.ACCURACY)
    cr = ClaimValidationResult(claim=claim, reproduced_value=0.95, passed=True)
    exec_result = ExecutionResult(
        generated_code="print('hi')",
        exit_code=0,
        deviation_notes=deviations,
        claim_refinement_attempts=attempts,
    )
    return reporter, reporter.build(_paper(), _dataset(), exec_result, claim_results=[cr])


def test_markdown_includes_refinement_section_when_attempts_made():
    reporter, report = _report_with_refinement(deviations=[], attempts=2)
    md = reporter.to_markdown(report)
    assert "## Refinement" in md
    assert "2 claim-targeted refinement passes" in md


def test_markdown_omits_refinement_section_when_no_activity():
    reporter, report = _report_with_refinement(deviations=[], attempts=0)
    md = reporter.to_markdown(report)
    assert "## Refinement" not in md


def test_markdown_lists_deviation_notes():
    reporter, report = _report_with_refinement(
        deviations=[
            "Used 10-fold CV instead of 5-fold to stabilise variance",
            "Increased max_iter from default 100 to 1000",
        ],
        attempts=1,
    )
    md = reporter.to_markdown(report)
    assert "Methodology deviations declared during refinement" in md
    assert "- Used 10-fold CV instead of 5-fold to stabilise variance" in md
    assert "- Increased max_iter from default 100 to 1000" in md


def test_console_output_mentions_refinement_and_deviations():
    reporter, report = _report_with_refinement(
        deviations=["Swapped solver from 'liblinear' to 'lbfgs'"],
        attempts=3,
    )
    console = reporter.to_console(report)
    assert "ran 3 claim-targeted refinement passes" in console
    assert "Deviation: Swapped solver from 'liblinear' to 'lbfgs'" in console


# ── Hyperparameter audit rendering ─────────────────────────────────────


def _report_with_audits(audits):
    reporter = ValidationReporter()
    claim = Claim(description="accuracy", value=0.95, claim_type=ClaimType.ACCURACY)
    cr = ClaimValidationResult(claim=claim, reproduced_value=0.95, passed=True)
    exec_result = ExecutionResult(
        generated_code="print('hi')",
        exit_code=0,
        hyperparameter_audits=audits,
    )
    return reporter, reporter.build(_paper(), _dataset(), exec_result, claim_results=[cr])


def _audit(name, value, status, observed=None, notes=""):
    return HyperparameterAudit(
        spec=HyperparameterSpec(name=name, value=value),
        status=status,
        observed_value=observed,
        notes=notes,
    )


def test_markdown_omits_audit_section_when_no_audits():
    reporter, report = _report_with_audits([])
    md = reporter.to_markdown(report)
    assert "## Hyperparameter audit" not in md


def test_markdown_audit_all_match_says_so():
    audits = [
        _audit("C", 1.0, AuditStatus.MATCH, observed=1.0),
        _audit("random_state", 42, AuditStatus.MATCH, observed=42),
    ]
    reporter, report = _report_with_audits(audits)
    md = reporter.to_markdown(report)
    assert "## Hyperparameter audit" in md
    assert "All **2** paper-stated hyperparameters matched" in md
    assert "| `C` |" in md
    assert "✓ match" in md


def test_markdown_audit_mismatch_renders_status_and_notes():
    audits = [
        _audit("C", 1.0, AuditStatus.MATCH, observed=1.0),
        _audit(
            "n_estimators",
            100,
            AuditStatus.MISMATCH,
            observed=50,
            notes="Paper specifies n_estimators=100, code uses n_estimators=50.",
        ),
    ]
    reporter, report = _report_with_audits(audits)
    md = reporter.to_markdown(report)
    assert "**1 of 2** paper-stated hyperparameters matched" in md
    assert "✗ mismatch" in md
    assert "Paper specifies n_estimators=100" in md


def test_markdown_audit_not_found_and_unresolved_render():
    audits = [
        _audit("C", 1.0, AuditStatus.NOT_FOUND),
        _audit("max_iter", 1000, AuditStatus.UNRESOLVED, observed="some_var"),
    ]
    reporter, report = _report_with_audits(audits)
    md = reporter.to_markdown(report)
    assert "○ not_found" in md
    assert "? unresolved" in md


def test_console_output_summarises_audit():
    audits = [
        _audit("C", 1.0, AuditStatus.MATCH, observed=1.0),
        _audit(
            "n_estimators",
            100,
            AuditStatus.MISMATCH,
            observed=50,
            notes="Paper specifies n_estimators=100, code uses n_estimators=50.",
        ),
    ]
    reporter, report = _report_with_audits(audits)
    console = reporter.to_console(report)
    assert "Hyperparameter audit: " in console
    assert "1/2 matched" in console
    # Non-matches show up individually for the human.
    assert "n_estimators: mismatch" in console
    # Matches do NOT appear in the per-line summary — the headline already
    # captures them and we don't want to clutter the terminal output.
    assert "C: match" not in console


def test_console_output_omits_audit_when_empty():
    reporter, report = _report_with_audits([])
    console = reporter.to_console(report)
    assert "Hyperparameter audit" not in console
