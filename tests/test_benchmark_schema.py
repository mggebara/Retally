"""Tests for the benchmark catalog schema."""

from __future__ import annotations

from pathlib import Path

import pytest

from tests._loaders import REPO_ROOT, load_module_from_path

schema = load_module_from_path("benchmark.schema", REPO_ROOT / "benchmark" / "schema.py")
load_entry = schema.load_entry
load_catalog = schema.load_catalog
SchemaError = schema.SchemaError
Language = schema.Language
OutcomeLabel = schema.OutcomeLabel
FindingOutcome = schema.FindingOutcome


def _write_yaml(path: Path, body: str) -> None:
    path.write_text(body, encoding="utf-8")


# ── Happy path ──────────────────────────────────────────────────────────


def test_loads_minimal_entry(tmp_path):
    p = tmp_path / "x.yaml"
    _write_yaml(
        p,
        """
id: foo
i4r_report_url: https://example.org/foo
language: python
outcome_label: reproducible
paper:
  source: "raw paper text"
""",
    )
    entry = load_entry(p)
    assert entry.id == "foo"
    assert entry.language is Language.PYTHON
    assert entry.outcome_label is OutcomeLabel.REPRODUCIBLE
    assert entry.paper.source == "raw paper text"
    assert entry.original_claims == []
    assert entry.i4r_replicator_findings == []


def test_loads_full_entry(tmp_path):
    p = tmp_path / "x.yaml"
    _write_yaml(
        p,
        """
id: full
i4r_report_url: https://example.org/full
i4r_report_doi: 10.1234/example
language: r
outcome_label: not_robust
paper:
  source: "https://arxiv.org/abs/2301.xxxxx"
  title: "An Example Paper"
  authors: [A, B]
dataset:
  source: "iris"
  registry_key: "iris"
  access_notes: "publicly available"
code_repo:
  url: https://github.com/foo/bar
  commit: abc123
original_claims:
  - description: "treatment effect"
    value: 0.32
    unit: null
    claim_type: coefficient
    standard_error: 0.08
    sample_size: 1500
    context: "Table 3 col 4"
    location: "Table 3, col 4"
i4r_replicator_findings:
  - claim_id: 0
    reproduced_value: 0.34
    outcome: matches
    notes: "within SE"
notes: "free text"
""",
    )
    entry = load_entry(p)
    assert entry.language is Language.R
    assert entry.outcome_label is OutcomeLabel.NOT_ROBUST
    assert entry.dataset is not None and entry.dataset.registry_key == "iris"
    assert entry.code_repo is not None and entry.code_repo.commit == "abc123"
    [claim] = entry.original_claims
    assert claim.value == 0.32
    assert claim.standard_error == 0.08
    assert claim.sample_size == 1500
    [finding] = entry.i4r_replicator_findings
    assert finding.outcome is FindingOutcome.MATCHES
    assert finding.reproduced_value == 0.34


def test_out_of_scope_reason_is_preserved(tmp_path):
    p = tmp_path / "x.yaml"
    _write_yaml(
        p,
        """
id: stata-skip
i4r_report_url: https://example.org/stata
language: stata
outcome_label: reproducible
out_of_scope_reason: "Original code is Stata"
paper:
  source: "raw"
""",
    )
    entry = load_entry(p)
    assert entry.out_of_scope_reason == "Original code is Stata"


# ── Optional-field handling ─────────────────────────────────────────────


def test_missing_optional_fields_become_none_or_default(tmp_path):
    p = tmp_path / "x.yaml"
    _write_yaml(
        p,
        """
id: minimal
i4r_report_url: https://example.org/minimal
language: python
outcome_label: reproducible
paper:
  source: "raw"
""",
    )
    entry = load_entry(p)
    assert entry.i4r_report_doi is None
    assert entry.dataset is None
    assert entry.code_repo is None
    assert entry.out_of_scope_reason is None
    assert entry.notes == ""


def test_empty_string_optional_becomes_none(tmp_path):
    # Optional string fields should normalize '' to None so that
    # downstream "is it set?" checks don't trip on empty strings.
    p = tmp_path / "x.yaml"
    _write_yaml(
        p,
        """
id: x
i4r_report_url: https://example.org/x
i4r_report_doi: ""
language: python
outcome_label: reproducible
paper:
  source: "raw"
""",
    )
    entry = load_entry(p)
    assert entry.i4r_report_doi is None


# ── Schema errors ───────────────────────────────────────────────────────


def test_missing_required_field_raises(tmp_path):
    p = tmp_path / "x.yaml"
    _write_yaml(p, "id: foo\n")  # missing everything else
    with pytest.raises(SchemaError, match="missing required field"):
        load_entry(p)


def test_invalid_yaml_raises(tmp_path):
    p = tmp_path / "x.yaml"
    _write_yaml(p, "id: foo\n  bad: indent: here\n")
    with pytest.raises(SchemaError, match="YAML parse failed"):
        load_entry(p)


def test_unknown_language_raises(tmp_path):
    p = tmp_path / "x.yaml"
    _write_yaml(
        p,
        """
id: x
i4r_report_url: https://example.org/x
language: julia
outcome_label: reproducible
paper:
  source: "raw"
""",
    )
    with pytest.raises(SchemaError):
        load_entry(p)


def test_unknown_outcome_label_raises(tmp_path):
    p = tmp_path / "x.yaml"
    _write_yaml(
        p,
        """
id: x
i4r_report_url: https://example.org/x
language: python
outcome_label: probably-fine
paper:
  source: "raw"
""",
    )
    with pytest.raises(SchemaError):
        load_entry(p)


def test_top_level_must_be_mapping(tmp_path):
    p = tmp_path / "x.yaml"
    _write_yaml(p, "- not a mapping\n")
    with pytest.raises(SchemaError, match="must be a mapping"):
        load_entry(p)


# ── Catalog loading ─────────────────────────────────────────────────────


def test_load_catalog_returns_entries_sorted_by_id(tmp_path):
    _write_yaml(
        tmp_path / "b.yaml",
        """
id: bbb
i4r_report_url: https://example.org/b
language: python
outcome_label: reproducible
paper: {source: "raw"}
""",
    )
    _write_yaml(
        tmp_path / "a.yaml",
        """
id: aaa
i4r_report_url: https://example.org/a
language: python
outcome_label: reproducible
paper: {source: "raw"}
""",
    )
    entries = load_catalog(tmp_path)
    assert [e.id for e in entries] == ["aaa", "bbb"]


def test_load_catalog_skips_malformed_entries(tmp_path, capsys):
    _write_yaml(
        tmp_path / "good.yaml",
        """
id: good
i4r_report_url: https://example.org/good
language: python
outcome_label: reproducible
paper: {source: "raw"}
""",
    )
    _write_yaml(tmp_path / "bad.yaml", "id: bad\n")  # missing required
    entries = load_catalog(tmp_path)
    assert [e.id for e in entries] == ["good"]
    err = capsys.readouterr().err
    assert "bad.yaml" in err


def test_load_catalog_returns_empty_when_dir_missing(tmp_path):
    assert load_catalog(tmp_path / "does-not-exist") == []


# ── Placeholder fixtures still load via the schema ─────────────────────


def test_placeholder_fixture_yaml_files_validate():
    """The placeholder fixtures must keep validating against the loader.

    Catches schema drift between the docs / examples and the loader.
    Lives under tests/fixtures/ so the real ``benchmark/papers/`` catalog
    isn't polluted by placeholder noise — adding a real I4R entry to the
    benchmark doesn't need to know anything about test fixtures.
    """
    fixtures = REPO_ROOT / "tests" / "fixtures" / "benchmark_placeholders"
    catalog = load_catalog(fixtures)
    ids = {e.id for e in catalog}
    assert "_placeholder_python_example" in ids
    assert "_placeholder_r_example" in ids
    assert "_placeholder_stata_out_of_scope" in ids


def test_real_benchmark_papers_dir_has_no_placeholders():
    """Regression: nobody should be re-adding placeholders to the real catalog."""
    real_dir = REPO_ROOT / "benchmark" / "papers"
    if not real_dir.is_dir():
        return
    placeholder_yamls = list(real_dir.glob("_placeholder*.yaml"))
    assert placeholder_yamls == [], (
        f"Unexpected placeholder YAMLs in {real_dir}: {placeholder_yamls}. "
        "Placeholders belong under tests/fixtures/benchmark_placeholders/."
    )
