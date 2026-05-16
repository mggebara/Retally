"""
Shared data models for the paper validation framework.

These dataclasses flow through every stage of the pipeline:
  Paper -> (ClaimExtractor) -> Claim list
  DatasetReference -> (DatasetDownloader) -> Dataset
  Paper + Dataset -> (CodeGenerator) -> code str -> (CodeExecutor) -> ExecutionResult
  Claim list + ExecutionResult -> (ResultComparator) -> ClaimValidationResult list
  All of the above -> (ValidationReporter) -> ValidationReport
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Any


class ClaimType(Enum):
    """Broad category for a quantitative claim found in a paper."""

    ACCURACY = "accuracy"
    F1_SCORE = "f1_score"
    AUC_ROC = "auc_roc"
    RMSE = "rmse"
    MAE = "mae"
    PRECISION = "precision"
    RECALL = "recall"
    CORRELATION = "correlation"
    P_VALUE = "p_value"
    EFFECT_SIZE = "effect_size"
    OTHER = "other"


class DatasetSource(Enum):
    """Supported public dataset repositories."""

    DIRECT_URL = "direct_url"
    KAGGLE = "kaggle"
    ZENODO = "zenodo"
    UCI = "uci"
    HARVARD_DATAVERSE = "harvard_dataverse"
    FIGSHARE = "figshare"
    OPENML = "openml"
    UNKNOWN = "unknown"


@dataclass
class Claim:
    """A single quantitative result asserted in a paper."""

    description: str
    """Human-readable description of what is being measured (e.g. 'test accuracy on MNIST')."""

    value: float
    """The numeric value as stated in the paper."""

    unit: str | None = None
    """Optional unit or percentage indicator (e.g. '%', 'ms')."""

    claim_type: ClaimType = ClaimType.OTHER
    """Semantic category of this metric."""

    context: str = ""
    """Surrounding sentence(s) from the paper for disambiguation."""

    table_ref: str | None = None
    """Table number or label where this claim appears, if applicable."""

    figure_ref: str | None = None
    """Figure number or label where this claim appears, if applicable."""


@dataclass
class DatasetReference:
    """A reference to a dataset mentioned in a paper."""

    name: str
    """Common name of the dataset (e.g. 'UCI Adult Income')."""

    source: DatasetSource = DatasetSource.UNKNOWN
    """Which repository or mechanism should be used to download it."""

    url: str | None = None
    """Direct URL or repository identifier (e.g. Kaggle slug 'username/dataset-name')."""

    description: str = ""
    """Brief description extracted from the paper."""

    access_instructions: str | None = None
    """Any special steps required (e.g. accepting terms, using an API key)."""


@dataclass
class Paper:
    """Parsed representation of an academic paper."""

    title: str
    authors: list[str] = field(default_factory=list)
    abstract: str = ""
    full_text: str = ""

    claims: list[Claim] = field(default_factory=list)
    """Quantitative claims extracted from the paper."""

    dataset_references: list[DatasetReference] = field(default_factory=list)
    """Dataset references extracted from the paper."""

    methodology_summary: str = ""
    """LLM-summarised methodology section, used as context for code generation."""

    source_path: Path | None = None
    """Local path of the original file this paper was parsed from."""

    source_url: str | None = None
    """Remote URL the paper was fetched from, if any."""


@dataclass
class Dataset:
    """A dataset that has been downloaded and is ready for use."""

    name: str
    source_url: str
    local_path: Path
    """Root directory containing the downloaded files."""

    file_format: str = "csv"
    """Primary file format of the dataset (e.g. 'csv', 'json', 'parquet')."""

    metadata: dict[str, Any] = field(default_factory=dict)
    """Arbitrary key/value metadata (row count, column names, license, etc.)."""


@dataclass
class ExecutionResult:
    """Outcome of running the generated reproduction code."""

    generated_code: str
    stdout: str = ""
    stderr: str = ""
    exit_code: int = -1

    outputs: dict[str, float] = field(default_factory=dict)
    """Named numeric outputs captured from the code's stdout (metric_name -> value).

    Convention: the generated code should print results in the form
        RESULT:<metric_name>=<value>
    so the executor can parse them into this dict.
    """

    timed_out: bool = False


@dataclass
class ClaimValidationResult:
    """Comparison of a single paper claim against the reproduced value."""

    claim: Claim
    reproduced_value: float | None
    """The value produced by the generated code, or None if it could not be matched."""

    tolerance: float = 0.01
    """Acceptable relative difference (default 1 %)."""

    passed: bool = False
    notes: str = ""


@dataclass
class ValidationReport:
    """Top-level output of the full validation pipeline."""

    paper: Paper
    dataset: Dataset
    execution_result: ExecutionResult
    claim_results: list[ClaimValidationResult]
    overall_passed: bool
    summary: str = ""
