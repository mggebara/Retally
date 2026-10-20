"""Data model for the benchmark catalog.

Each paper in the catalog is a ``BenchmarkEntry`` stored as a YAML file
under ``benchmark/papers/``.  The runner loads every YAML file, drops
the ones that don't validate, and walks the rest.

This module is deliberately separate from ``retally.models`` so the
benchmark schema can evolve independently of the pipeline's runtime
types.  When a benchmark field starts to make sense as a first-class
``ValidationReport`` field it can be promoted later; until then,
benchmark-only metadata stays out of the library's public surface.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Any

import yaml

# Language is defined in the library so the pipeline / generator /
# reporter can share the same enum.  Re-export it here so existing
# `benchmark.schema.Language` imports keep working (the loader uses
# Language(value) so all the test paper YAMLs are unaffected).
from retally.models import Language

__all__ = ["Language"]  # re-export for backwards compat with the previous local definition


class OutcomeLabel(Enum):
    """I4R's classification of the replication outcome.

    Distinct from anything Retally produces — this is what the human
    replicators concluded.  The runner uses it for stratification, not
    as ground truth for individual numbers.
    """

    REPRODUCIBLE = "reproducible"
    """Code runs and the numbers match the paper."""

    ROBUST = "robust"
    """Claims survive reasonable alternative specifications."""

    NOT_ROBUST = "not_robust"
    """Computationally reproducible but claims don't survive scrutiny."""

    NOT_REPRODUCIBLE = "not_reproducible"
    """Code doesn't run / data unavailable / numbers can't be matched."""

    INCONCLUSIVE = "inconclusive"
    """Replication attempted but no clear verdict."""


class FindingOutcome(Enum):
    """Per-claim verdict from the I4R replicator."""

    MATCHES = "matches"
    """Replicator got essentially the same number as the paper."""

    DOES_NOT_MATCH = "does_not_match"
    """Replicator got a meaningfully different number."""

    NOT_ATTEMPTED = "not_attempted"
    """Replicator did not try to reproduce this specific claim."""


@dataclass
class OriginalClaim:
    """A quantitative claim from the original paper that we want Retally to reproduce.

    Mirrors the shape of ``retally.models.Claim`` but adds econometrics-
    flavoured fields (``standard_error``, ``sample_size``) that the
    library's ``Claim`` doesn't carry today.  Those fields are accepted
    and stored; whether Retally can USE them is a separate question for
    the comparator + reporter extensions in later PRs.
    """

    description: str
    value: float
    unit: str | None = None
    claim_type: str = "other"
    """Free-form string, NOT retally.models.ClaimType — the benchmark
    catalog should accept claim labels that don't (yet) exist in the
    library's enum (``coefficient``, ``standard_error``, …)."""

    standard_error: float | None = None
    sample_size: int | None = None
    context: str = ""
    location: str | None = None
    """Table / figure / column reference, e.g. ``"Table 3, col 4"``."""


@dataclass
class ReplicatorFinding:
    """One replicator-produced number, paired with an OriginalClaim by index."""

    claim_id: int
    """Index into ``BenchmarkEntry.original_claims``."""

    reproduced_value: float | None
    """The number the I4R replicator got.  ``None`` means the
    replicator couldn't attempt it (data unavailable, code missing)."""

    outcome: FindingOutcome
    notes: str = ""


@dataclass
class PaperRef:
    source: str
    """URL, arXiv ID, DOI, or local path that ``ValidationPipeline.validate``
    can dispatch."""

    title: str = ""
    authors: list[str] = field(default_factory=list)


@dataclass
class DatasetRef:
    source: str
    """URL, registry ID, or other identifier the dataset downloader can resolve."""

    registry_key: str | None = None
    """Optional hint matching an entry in ``DatasetRegistry``."""

    access_notes: str = ""
    """Free text — useful for noting "OpenICPSR registered access required"
    or "embargoed until 2026" without making those a structured concern."""


@dataclass
class CodeRepoRef:
    url: str
    commit: str | None = None
    """Pin a specific commit for reproducibility.  When None the runner
    uses HEAD at clone time."""


@dataclass
class BenchmarkEntry:
    """One paper in the benchmark catalog.

    YAML files at ``benchmark/papers/<id>.yaml`` deserialize into this.
    The schema is intentionally permissive: missing optional fields
    are fine, unknown fields are ignored with a warning.  This lets us
    evolve the schema without breaking existing catalog entries.
    """

    id: str
    """Stable identifier used for filenames, cache keys, and report
    cross-references.  Typically ``<first-author>-<year>-<slug>``."""

    i4r_report_url: str
    language: Language
    outcome_label: OutcomeLabel

    paper: PaperRef
    original_claims: list[OriginalClaim] = field(default_factory=list)
    i4r_replicator_findings: list[ReplicatorFinding] = field(default_factory=list)

    i4r_report_doi: str | None = None
    dataset: DatasetRef | None = None
    code_repo: CodeRepoRef | None = None

    out_of_scope_reason: str | None = None
    """Set this (e.g. ``"stata required"``, ``"data is OpenICPSR-restricted"``)
    to keep the entry in the catalog but exclude it from execution.
    The runner records why each skip happened so the benchmark report
    can show the catalog-vs-runnable breakdown."""

    split: str = "dev"
    """Which evaluation split this entry belongs to: ``"dev"`` (default)
    or ``"holdout"``.  Prompt tuning iterates against dev entries; the
    holdout set is touched rarely, only to confirm that a dev-set win
    generalises rather than overfits.  The runner stamps the split onto
    each result so reports and run comparisons can group by it."""

    notes: str = ""


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------


class SchemaError(ValueError):
    """Raised when a YAML file doesn't deserialize into BenchmarkEntry."""


def load_entry(path: Path) -> BenchmarkEntry:
    """Load and validate a single benchmark YAML file."""
    try:
        raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    except yaml.YAMLError as exc:
        raise SchemaError(f"{path}: YAML parse failed: {exc}") from exc

    if not isinstance(raw, dict):
        raise SchemaError(f"{path}: top-level YAML must be a mapping, got {type(raw).__name__}")

    try:
        return _entry_from_dict(raw)
    except (KeyError, TypeError, ValueError) as exc:
        raise SchemaError(f"{path}: {exc}") from exc


def load_catalog(papers_dir: Path) -> list[BenchmarkEntry]:
    """Load every ``*.yaml`` file under ``papers_dir``.

    Returns entries in stable sorted-by-id order so report output is
    deterministic across runs.  Logs (does not raise) per-file errors;
    callers can decide whether a malformed entry should fail the run.
    """
    if not papers_dir.is_dir():
        return []

    entries: list[BenchmarkEntry] = []
    errors: list[str] = []
    for path in sorted(papers_dir.glob("*.yaml")):
        try:
            entries.append(load_entry(path))
        except SchemaError as exc:
            errors.append(str(exc))

    if errors:
        # Surface the errors but don't crash the runner; the report will
        # show which catalog entries were rejected.
        import sys

        for err in errors:
            print(f"[benchmark.schema] {err}", file=sys.stderr)

    entries.sort(key=lambda e: e.id)
    return entries


# ---------------------------------------------------------------------------
# Helpers — keep these dumb on purpose; tests should cover every branch.
# ---------------------------------------------------------------------------


def _entry_from_dict(d: dict[str, Any]) -> BenchmarkEntry:
    for required in ("id", "i4r_report_url", "language", "outcome_label", "paper"):
        if required not in d:
            raise KeyError(f"missing required field: {required}")

    return BenchmarkEntry(
        id=str(d["id"]),
        i4r_report_url=str(d["i4r_report_url"]),
        i4r_report_doi=_optional_str(d.get("i4r_report_doi")),
        language=Language(d["language"]),
        outcome_label=OutcomeLabel(d["outcome_label"]),
        paper=_paper_ref(d["paper"]),
        dataset=_dataset_ref(d.get("dataset")),
        code_repo=_code_repo_ref(d.get("code_repo")),
        original_claims=[_original_claim(c) for c in d.get("original_claims", [])],
        i4r_replicator_findings=[_finding(f) for f in d.get("i4r_replicator_findings", [])],
        out_of_scope_reason=_optional_str(d.get("out_of_scope_reason")),
        split=_split(d.get("split", "dev")),
        notes=str(d.get("notes", "")),
    )


_VALID_SPLITS = frozenset({"dev", "holdout"})


def _split(value: Any) -> str:
    """Validate the evaluation-split label.

    A typo like ``split: holdut`` silently landing in the dev set would
    quietly contaminate tuning, so unknown labels are a hard error.
    """
    s = str(value)
    if s not in _VALID_SPLITS:
        raise ValueError(f"split must be one of {sorted(_VALID_SPLITS)}, got {s!r}")
    return s


def _paper_ref(d: Any) -> PaperRef:
    if not isinstance(d, dict):
        raise TypeError(f"paper must be a mapping, got {type(d).__name__}")
    if "source" not in d:
        raise KeyError("paper.source is required")
    return PaperRef(
        source=str(d["source"]),
        title=str(d.get("title", "")),
        authors=[str(a) for a in d.get("authors", [])],
    )


def _dataset_ref(d: Any) -> DatasetRef | None:
    if d is None:
        return None
    if not isinstance(d, dict):
        raise TypeError(f"dataset must be a mapping, got {type(d).__name__}")
    if "source" not in d:
        raise KeyError("dataset.source is required")
    return DatasetRef(
        source=str(d["source"]),
        registry_key=_optional_str(d.get("registry_key")),
        access_notes=str(d.get("access_notes", "")),
    )


def _code_repo_ref(d: Any) -> CodeRepoRef | None:
    if d is None:
        return None
    if not isinstance(d, dict):
        raise TypeError(f"code_repo must be a mapping, got {type(d).__name__}")
    if "url" not in d:
        raise KeyError("code_repo.url is required")
    return CodeRepoRef(
        url=str(d["url"]),
        commit=_optional_str(d.get("commit")),
    )


def _original_claim(d: Any) -> OriginalClaim:
    if not isinstance(d, dict):
        raise TypeError(f"original_claims[] entry must be a mapping, got {type(d).__name__}")
    return OriginalClaim(
        description=str(d.get("description", "")),
        value=float(d["value"]),
        unit=_optional_str(d.get("unit")),
        claim_type=str(d.get("claim_type", "other")),
        standard_error=_optional_float(d.get("standard_error")),
        sample_size=_optional_int(d.get("sample_size")),
        context=str(d.get("context", "")),
        location=_optional_str(d.get("location")),
    )


def _finding(d: Any) -> ReplicatorFinding:
    if not isinstance(d, dict):
        raise TypeError(f"i4r_replicator_findings[] entry must be a mapping, got {type(d).__name__}")
    return ReplicatorFinding(
        claim_id=int(d["claim_id"]),
        reproduced_value=_optional_float(d.get("reproduced_value")),
        outcome=FindingOutcome(d.get("outcome", "not_attempted")),
        notes=str(d.get("notes", "")),
    )


def _optional_str(x: Any) -> str | None:
    if x is None:
        return None
    s = str(x)
    return s if s else None


def _optional_float(x: Any) -> float | None:
    return None if x is None else float(x)


def _optional_int(x: Any) -> int | None:
    return None if x is None else int(x)
