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
    """Broad category for a quantitative claim found in a paper.

    ML-side categories are the ones extractors and the comparator have
    used since the project started.  Econometric categories
    (``COEFFICIENT``, ``STANDARD_ERROR``, ``R_SQUARED``) were added to
    accommodate I4R-style replication papers, which mostly report
    regression coefficients with standard errors and sample R-squareds.
    The comparator's per-type tolerance table treats them appropriately
    (looser than accuracy because econ papers round coefficients more
    aggressively, but not so loose that meaningful disagreements are
    smoothed over).
    """

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
    COEFFICIENT = "coefficient"
    """A regression coefficient (β).  Most common econometric claim type."""

    STANDARD_ERROR = "standard_error"
    """The standard error of a regression coefficient.  Papers report
    these alongside coefficients; both are first-class claims."""

    R_SQUARED = "r_squared"
    """Goodness-of-fit R-squared for a regression model."""

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


class CodeReferenceSource(Enum):
    """Where a paper's reference code lives.

    GitHub is the only fully-supported source today; the enum has more
    members so the extractor can record what it saw without forcing the
    downloader to handle every flavour.  Sources we don't download yet
    are surfaced in the report as 'we found this code but couldn't
    fetch it' rather than dropped silently.
    """

    GITHUB = "github"
    GITLAB = "gitlab"
    BITBUCKET = "bitbucket"
    ZENODO = "zenodo"
    DIRECT_URL = "direct_url"
    UNKNOWN = "unknown"


class Language(Enum):
    """The programming language a paper's reference code and reproduction use.

    Python is the only fully-supported language today.  ``R`` papers
    are catalogued (and skipped) until the R executor lands in a later
    PR; ``STATA`` is a deferred decision because Stata is proprietary
    and can't legally live in the project's sandbox image.

    Default for every Paper / ExecutionResult is PYTHON so this
    addition is byte-identical to prior behaviour for existing callers.
    """

    PYTHON = "python"
    R = "r"
    STATA = "stata"
    UNKNOWN = "unknown"


@dataclass
class CodeReference:
    """A reference implementation linked from a paper.

    Populated by ``ClaimExtractor.extract_code_references`` from URLs
    found in the paper text.  ``local_path`` is filled in by
    ``CodeDownloader.download``; until then it is None.
    """

    url: str
    source: CodeReferenceSource = CodeReferenceSource.UNKNOWN
    description: str = ""
    local_path: Path | None = None


class AuditStatus(Enum):
    """Outcome of auditing one paper-stated hyperparameter against the generated code."""

    MATCH = "match"
    """Code used the paper's stated value (literal equality, with float tolerance)."""

    MISMATCH = "mismatch"
    """Code used a different literal value for this hyperparameter."""

    NOT_FOUND = "not_found"
    """The hyperparameter's keyword argument never appeared in the code.

    The code may still be using the value via the library's default, but
    we cannot prove conformance from the AST alone.
    """

    UNRESOLVED = "unresolved"
    """The kwarg is present but bound to a variable / expression we cannot
    evaluate without executing the code.  A separate signal from
    MISMATCH because we don't know whether the actual runtime value
    matches or not."""


@dataclass
class HyperparameterSpec:
    """A hyperparameter the paper explicitly specifies.

    The extractor populates this from the paper's methodology section.
    ``name`` is expected to be the canonical sklearn keyword argument
    where one applies (``C``, ``n_estimators``, ``random_state``,
    ``test_size``, ``hidden_layer_sizes``, ``cv``, …); this lets the
    AST auditor match by kwarg name without further normalisation.

    ``value`` is whatever the paper states.  Lists / tuples are stored
    as lists.
    """

    name: str
    value: Any
    context: str = ""
    """Surrounding sentence(s) from the paper for disambiguation."""

    source_ref: str | None = None
    """Section / table / figure reference where this hyperparameter is stated,
    if available (e.g. '§3.2', 'Table 1')."""


@dataclass
class HyperparameterAudit:
    """Result of checking one HyperparameterSpec against the generated code."""

    spec: HyperparameterSpec
    status: AuditStatus
    observed_value: Any = None
    """The literal value the code used, when status is MATCH or MISMATCH;
    None for NOT_FOUND; the raw AST source string for UNRESOLVED."""

    notes: str = ""


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

    hyperparameters: list[HyperparameterSpec] = field(default_factory=list)
    """Hyperparameters the paper explicitly specifies, extracted by an LLM
    pass.  Consumed downstream by the AST hyperparameter auditor."""

    code_references: list[CodeReference] = field(default_factory=list)
    """Reference implementations linked from the paper (typically GitHub).
    When non-empty and successfully downloaded, the code generator uses
    a selection of files as a baseline rather than reconstructing the
    implementation from the methodology summary alone."""

    language: Language = Language.PYTHON
    """Programming language for the reproduction.  Defaults to Python so
    existing callers continue to work unchanged.  Set to R / STATA on
    benchmark entries the runner uses to decide whether the paper is
    in scope for the current pipeline configuration."""

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

    deviation_notes: list[str] = field(default_factory=list)
    """Free-text deviations the generator declared while refining toward a
    failed claim.  Populated from ``DEVIATION:<text>`` lines in stdout.

    These exist because the claim-refinement loop asks the model to flag
    any change it had to make that was not in the paper's stated
    methodology (e.g. switching from 5-fold CV to 10-fold to stabilise
    variance).  They surface in the final report so a reader can tell
    whether a claim was reproduced as-stated or with caveats.
    """

    claim_refinement_attempts: int = 0
    """Number of claim-targeted refinement passes the pipeline ran after the
    initial code first executed cleanly.  Distinct from the exec-error
    refinement count, which is implicit in the code's history."""

    hyperparameter_audits: list[HyperparameterAudit] = field(default_factory=list)
    """Per-spec audit results from comparing the final generated code's
    literal kwargs against ``Paper.hyperparameters``.  Independent of
    claim validation: a paper can be claim-validated while still
    failing the hyperparameter audit (and vice versa)."""

    language: Language = Language.PYTHON
    """The language the generated code is written in.  Used by the
    reporter to pick the correct markdown code-fence tag (``python``,
    ``r``, ``stata``) and by future executors to dispatch the right
    runtime.  Defaults to PYTHON; the pipeline copies ``paper.language``
    here after execution so reports stay consistent."""

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
