"""The agent protocol: what the benchmark harness needs from a reproducer.

The benchmark (catalog + pinned claims + I4R ground truth + two-mode
scoring) is the durable contribution; ``ValidationPipeline`` is one
*reproducer* that sits the exam.  This module pins down the seam between
the two so any agent can be scored by the same code path:

* :class:`Reproducer` — the protocol.  One method, ``reproduce(...)``,
  taking a catalog entry's inputs (paper source, language, dataset
  reference, pinned claims, reproduction mode) and returning a
  :class:`Reproduction`.
* :class:`Reproduction` — the report contract: the raw ``{name: value}``
  numbers the agent's code produced, the claims it targeted, and the
  artefacts the report shows (generated code, stdout/stderr, exit code,
  declared deviations, per-stage success flags).  **It carries no
  verdicts.**  The harness (``benchmark.runner``) matches outputs to
  claims and applies the per-mode tolerance itself, with
  ``ResultComparator``, so no reproducer grades its own exam.
* :class:`PipelineReproducer` — the reference implementation: a thin
  adapter around an unmodified ``ValidationPipeline``.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Protocol, runtime_checkable

from retally.models import Claim, DatasetReference, Language, ReproductionMode

# ---------------------------------------------------------------------------
# Report contract
# ---------------------------------------------------------------------------


@dataclass
class ComponentMetrics:
    """Per-stage success flags for one reproduction attempt.

    Each flag is True only when the corresponding stage completed AND
    produced output the next stage could consume.  ``None`` means the
    stage was never attempted (or the reproducer has no such stage — a
    general-purpose agent may only be able to report ``code_generated``
    and ``code_executed``).
    """

    parsed: bool | None = None
    claims_extracted: bool | None = None
    dataset_extracted: bool | None = None
    dataset_downloaded: bool | None = None
    code_generated: bool | None = None
    code_executed: bool | None = None


@dataclass
class Reproduction:
    """What a reproducer returns: raw numbers plus artefacts, no verdicts.

    ``outputs`` is the whole scoring input.  Key each value by the claim's
    ``description`` (the catalog's snake_case token, e.g.
    ``warfare_coefficient_bivariate``) — the harness's matcher tries an
    exact normalised match first, then falls back to substring and
    claim-type matching (``ResultComparator._match_output``), so keying by
    description is the only way to guarantee a value lands on its claim.
    For a code-running agent this is simply the parsed
    ``RESULT:<name>=<value>`` lines of its final run.
    """

    outputs: dict[str, float] = field(default_factory=dict)
    """Reproduced values from the final attempt, keyed by claim description."""

    claims: list[Claim] = field(default_factory=list)
    """The claims the reproducer targeted.  When the catalog entry pins
    ``original_claims`` the harness scores against those regardless; this
    field only matters for unpinned entries (the reproducer extracted its
    own claims) and for the extracted-claims dump used when pinning."""

    generated_code: str = ""
    stdout: str = ""
    stderr: str = ""
    exit_code: int = -1
    deviations: list[str] = field(default_factory=list)
    """Methodology changes the agent declared (``DEVIATION:`` lines)."""

    stages: ComponentMetrics = field(default_factory=ComponentMetrics)


@runtime_checkable
class Reproducer(Protocol):
    """Anything the benchmark harness can score.

    ``reproduce`` receives one catalog entry's inputs, as the runner
    builds them:

    * ``paper_source`` — the entry's ``paper.source`` (URL, path, DOI,
      arXiv id, or raw text).
    * ``language`` — the catalog's declared language (``python`` / ``r``);
      the code the agent writes and runs must be in it.
    * ``dataset_reference`` — where the data lives (built from the
      entry's ``dataset`` block), or None when the entry names none.
    * ``claims`` — the pinned ``original_claims`` (with standard errors),
      or None when the entry has none pinned and the agent must extract
      its own.
    * ``reproduction_mode`` — ``SEEDED`` (the authors' package scripts
      may be used) or ``INDEPENDENT`` (they must not be).

    It returns a :class:`Reproduction`.  Raising is allowed: the harness
    records ``retally_ran = False`` with the exception text and moves on.
    """

    def reproduce(
        self,
        paper_source: str,
        *,
        language: Language,
        dataset_reference: DatasetReference | None,
        claims: list[Claim] | None,
        reproduction_mode: ReproductionMode,
    ) -> Reproduction: ...


# ---------------------------------------------------------------------------
# Reference implementation: ValidationPipeline
# ---------------------------------------------------------------------------


class PipelineReproducer:
    """``ValidationPipeline`` as a :class:`Reproducer` — the reference agent.

    A thin adapter: it calls the pipeline's unchanged public
    ``validate(...)`` and keeps only what the report contract asks for.
    The pipeline still compares claims internally (its claim-refinement
    loop needs to know which claims are off), but those verdicts are
    dropped here; the harness re-scores ``outputs`` itself.

    """

    name = "pipeline"

    def __init__(self, pipeline: Any) -> None:
        self.pipeline = pipeline

    def reproduce(
        self,
        paper_source: str,
        *,
        language: Language,
        dataset_reference: DatasetReference | None,
        claims: list[Claim] | None,
        reproduction_mode: ReproductionMode,
    ) -> Reproduction:
        report = self.pipeline.validate(
            paper_source,
            language=language,
            dataset_reference=dataset_reference,
            claims=claims,
            reproduction_mode=reproduction_mode,
        )
        return reproduction_from_report(report)


def reproduction_from_report(report: Any) -> Reproduction:
    """Translate a ``ValidationReport`` into the report contract.

    ``getattr`` throughout so the harness survives a renamed library field
    — it scores reproductions, it is not married to the pipeline's shape.
    ``claim_results`` / ``overall_passed`` are deliberately not read.
    """
    paper = getattr(report, "paper", None)
    exec_result = getattr(report, "execution_result", None)
    generated_code = str(getattr(exec_result, "generated_code", "") or "") if exec_result else ""
    exit_code = getattr(exec_result, "exit_code", -1) if exec_result else -1
    stages = ComponentMetrics(
        parsed=paper is not None,
        claims_extracted=bool(getattr(paper, "claims", []) if paper else False),
        dataset_extracted=bool(getattr(paper, "dataset_references", []) if paper else False),
        dataset_downloaded=getattr(report, "dataset", None) is not None,
        code_generated=bool(generated_code),
        code_executed=(exit_code == 0) if exec_result else False,
    )
    return Reproduction(
        outputs=dict(getattr(exec_result, "outputs", {}) or {}) if exec_result else {},
        claims=list(getattr(paper, "claims", []) or []) if paper else [],
        generated_code=generated_code,
        stdout=str(getattr(exec_result, "stdout", "") or "") if exec_result else "",
        stderr=str(getattr(exec_result, "stderr", "") or "") if exec_result else "",
        exit_code=exit_code,
        deviations=list(getattr(exec_result, "deviation_notes", []) or []) if exec_result else [],
        stages=stages,
    )
