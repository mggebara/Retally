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
  adapter around an unmodified ``ValidationPipeline``.  It also returns
  the run's script, sandbox output, refinement attempts and prompts as
  ``Reproduction.artifacts``, which the harness writes to disk.

Independent-mode integrity: :func:`script_free_copy` builds a copy of a
dataset directory with the authors' analysis scripts removed.
``PipelineReproducer`` uses it in independent mode so the sandbox mounts
data files only — the model cannot open the ``.do``/``.R`` files even if
it tries.  An adapter author should do the same with whatever directory
their agent is given.
"""

from __future__ import annotations

import os
import re
import shutil
from dataclasses import dataclass, field, replace
from pathlib import Path
from typing import Any, Protocol, runtime_checkable

from retally.models import Claim, Dataset, DatasetReference, Language, ReproductionMode
from retally.usage import UsageTracker

# ---------------------------------------------------------------------------
# Report contract
# ---------------------------------------------------------------------------


class MissingAPIKeyError(RuntimeError):
    """Raised by a reproducer factory when the API key it needs is not set.

    The runner records this as a ``no_api_key`` skip; any other exception
    from a factory is recorded as ``reproducer_init_failed`` with its
    message, so a Docker or import failure is not misreported as a
    missing key.  Third-party factories should raise it for the same case.
    """


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
    exact normalised match first, then a substring match, and nothing
    else (``ResultComparator._match_output``); a claim with no matching
    output is scored as missing.  Keying by description is the only way to
    guarantee a value lands on its claim.
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

    usage: dict[str, Any] | None = None
    """Optional token accounting for this reproduction, in the shape of
    ``retally.usage.UsageTracker.since()``: ``api_calls``,
    ``llm_cache_hits``, ``llm_cache_served`` and ``by_model`` (per model id:
    ``input_tokens``, ``output_tokens``, ``cache_creation_input_tokens``,
    ``cache_read_input_tokens``, ``api_calls``).  Only live API calls carry
    tokens; LLM-cache replays are free.  The harness prices it with
    ``benchmark.pricing``.  None when the reproducer does not track usage.
    A reproducer that wants spend recorded on a *failed* run too can also
    expose it as a ``last_usage`` attribute, which the harness reads when
    ``reproduce`` raises."""

    artifacts: dict[str, str] = field(default_factory=dict)
    """Optional files to keep for inspecting this run, as relative path →
    text.  The harness writes them under
    ``benchmark/results/artifacts/<entry>/<mode>/<reproducer>/<run_id>/``
    and points the result row at that directory.  ``PipelineReproducer``
    fills ``script.R``/``script.py``, ``stdout.txt``, ``stderr.txt``, one
    ``attempt-<n>/`` directory per superseded refinement attempt and
    ``prompt-<n>.txt`` per generation prompt (see
    :func:`pipeline_artifacts`).  Paths must be relative and must not
    contain ``..``.  Empty means nothing is written."""

    attempt_outputs: list[str] | None = None
    """Optional stdout of every execution the reproducer ran, in the order
    they ran (the first script's output first).  The harness parses the
    ``RESULT:`` lines of ``attempt_outputs[0]`` and scores them with the
    same comparator, mode and tolerance as ``outputs``: the *first-attempt*
    pass count.  It also scores the first entry with a parsable ``RESULT:``
    line the same way: the *first-scored* pass count, i.e. what the agent
    produced after any crash repairs but before feedback on which claims
    were off target.  The final run is ``stdout``; it is usually the
    last entry, but not when the agent reverted to an earlier run.  None
    when the reproducer does not report its attempts (then no
    first-attempt numbers are recorded)."""

    n_refinements: int | None = None
    """Optional number of refinement calls the agent made after its first
    script (error repairs and claim-targeted fixes).  0 means the first
    script was final.  None when not reported."""

    n_executions: int | None = None
    """Optional number of sandbox executions.  None when not reported; the
    harness then falls back to ``len(attempt_outputs)`` when that is set."""

    attempt_kinds: list[str] | None = None
    """Optional, parallel to ``attempt_outputs``: the kind of refinement
    that followed each execution — ``"error"`` (it crashed or printed no
    ``RESULT:`` lines and the agent was sent the error), ``"claim"`` (the
    agent was told which claims were off target), ``""`` for none and for
    the final run.  Informational: the harness finds the *first scored*
    attempt from the outputs themselves (the first execution with a
    parsable ``RESULT:`` line), not from these labels."""

    n_error_refinements: int | None = None
    """Optional number of execution-error refinements (crash / no-output
    repairs).  None when not reported."""

    n_claim_refinements: int | None = None
    """Optional number of claim-targeted refinements (the agent was shown
    which claims were off target).  None when not reported."""


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
      may be used) or ``INDEPENDENT`` (they must not be: hand the agent
      a :func:`script_free_copy` of the dataset, not the original).

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
# Independent-mode integrity: a script-free copy of the dataset
# ---------------------------------------------------------------------------

# The authors' analysis code, in every form a replication package ships it.
# Stata logs (.log / .smcl) are included because they echo every command
# the do-file ran — a transcript of the script.  Matches the file types the
# independent-mode prompt already tells the model not to open.
SCRIPT_SUFFIXES = frozenset(
    {".do", ".ado", ".r", ".rmd", ".py", ".ipynb", ".sas", ".sps", ".m", ".log", ".smcl", ".rout"}
)

# Transcripts that carry the code without a script suffix.  ``.Rhistory``
# has no suffix in pathlib's sense (it is a dotfile) and holds every R
# command typed; ``log_*.txt`` is a common name for a saved R console
# session (the Bisbee 2022 package ships several).  Result tables
# (``.tex``/``.csv``) are deliberately kept: they hold the paper's numbers,
# which the independent-mode prompt already states as the claims.
SCRIPT_NAMES = frozenset({".rhistory", ".rapp.history"})
SCRIPT_NAME_PATTERNS = (re.compile(r"^log[_-].*\.txt$", re.IGNORECASE),)

SCRIPT_FREE_SUFFIX = ".script-free"


def is_script(path: Path) -> bool:
    """True when ``path`` is an analysis script or a transcript of one.

    Matches by case-insensitive suffix (``SCRIPT_SUFFIXES``), by exact
    dotfile name (``SCRIPT_NAMES``), or by console-log name pattern
    (``SCRIPT_NAME_PATTERNS``).
    """
    name = path.name.lower()
    if path.suffix.lower() in SCRIPT_SUFFIXES or name in SCRIPT_NAMES:
        return True
    return any(pat.match(name) for pat in SCRIPT_NAME_PATTERNS)


def script_free_copy(source: Path, dest: Path) -> Path:
    """Copy ``source`` to ``dest`` without the analysis scripts; return ``dest``.

    ``dest`` is rebuilt from scratch on every call, so it always mirrors the
    current ``source``.  Data files are hard-linked when possible (cheap for
    multi-GB packages; the sandboxes mount the dataset read-only, so the
    originals cannot be modified through the links) and copied otherwise.
    Hidden files and directories are copied like any other file.
    """
    source = Path(source)
    dest = Path(dest)
    if not source.is_dir():
        raise NotADirectoryError(f"script_free_copy expects a directory, got {source}")
    if dest.exists():
        shutil.rmtree(dest)

    def _link_or_copy(src: str, dst: str) -> object:
        try:
            os.link(src, dst)
            return dst
        except OSError:
            return shutil.copy2(src, dst)

    shutil.copytree(
        source,
        dest,
        ignore=lambda d, names: {n for n in names if is_script(Path(d) / n) and (Path(d) / n).is_file()},
        copy_function=_link_or_copy,
    )
    return dest


def script_free_dataset(dataset: Dataset) -> Dataset:
    """Return ``dataset`` re-pointed at a script-free copy, or unchanged.

    Unchanged when the dataset directory contains no scripts (registry
    datasets, plain data deposits) — so the copy, and its new path in the
    prompt, only appear when there is something to withhold.  The copy
    sits next to the original as ``<name>.script-free``: a deterministic
    path, because the dataset path is embedded in generation prompts and a
    random temp path would defeat the LLM cache on every run.
    """
    root = getattr(dataset, "local_path", None)
    if not isinstance(root, Path) or not root.is_dir():
        return dataset
    if not any(p.is_file() and is_script(p) for p in root.rglob("*")):
        return dataset
    dest = root.parent / f"{root.name}{SCRIPT_FREE_SUFFIX}"
    return replace(dataset, local_path=script_free_copy(root, dest))


# ---------------------------------------------------------------------------
# Reference implementation: ValidationPipeline
# ---------------------------------------------------------------------------


class _ScriptFreeDownloader:
    """Wraps a pipeline's downloader so downloads come back script-free."""

    def __init__(self, inner: Any) -> None:
        self._inner = inner

    def download(self, ref: DatasetReference) -> Dataset:
        return script_free_dataset(self._inner.download(ref))

    def __getattr__(self, name: str) -> Any:
        return getattr(self._inner, name)


class PipelineReproducer:
    """``ValidationPipeline`` as a :class:`Reproducer` — the reference agent.

    A thin adapter: it calls the pipeline's unchanged public
    ``validate(...)`` and keeps only what the report contract asks for.
    The pipeline still compares claims internally (its claim-refinement
    loop needs to know which claims are off), but those verdicts are
    dropped here; the harness re-scores ``outputs`` itself.

    In ``INDEPENDENT`` mode the pipeline's downloader is wrapped for the
    duration of the call so the dataset it sees — in the prompt's file
    listing and in the sandbox mount — is a :func:`script_free_dataset`.
    The pipeline already withholds the scripts from the prompt; this makes
    the withholding physical.  ``isolate_independent_scripts=False``
    restores the prompt-only behaviour.
    """

    name = "pipeline"

    def __init__(self, pipeline: Any, *, isolate_independent_scripts: bool = True) -> None:
        self.pipeline = pipeline
        self.isolate_independent_scripts = isolate_independent_scripts
        self.last_usage: dict[str, Any] | None = None
        """Usage of the most recent ``reproduce`` call (set even when it raised)."""

    def reproduce(
        self,
        paper_source: str,
        *,
        language: Language,
        dataset_reference: DatasetReference | None,
        claims: list[Claim] | None,
        reproduction_mode: ReproductionMode,
    ) -> Reproduction:
        isolate = self.isolate_independent_scripts and reproduction_mode is ReproductionMode.INDEPENDENT
        original_downloader = getattr(self.pipeline, "downloader", None)
        if isolate and original_downloader is not None:
            self.pipeline.downloader = _ScriptFreeDownloader(original_downloader)
        prompt_log = getattr(getattr(self.pipeline, "generator", None), "prompt_log", None)
        prompts_before = len(prompt_log) if isinstance(prompt_log, list) else 0
        tracker = getattr(self.pipeline, "usage_tracker", None)
        if not isinstance(tracker, UsageTracker):
            tracker = None
        before = tracker.snapshot() if tracker is not None else None
        self.last_usage = None
        try:
            report = self.pipeline.validate(
                paper_source,
                language=language,
                dataset_reference=dataset_reference,
                claims=claims,
                reproduction_mode=reproduction_mode,
            )
        finally:
            if isolate and original_downloader is not None:
                self.pipeline.downloader = original_downloader
            if tracker is not None:
                self.last_usage = tracker.since(before)
        reproduction = reproduction_from_report(report)
        reproduction.usage = self.last_usage
        prompts = prompt_log[prompts_before:] if isinstance(prompt_log, list) else []
        reproduction.artifacts = pipeline_artifacts(report, prompts=prompts)
        return reproduction


def pipeline_artifacts(report: Any, *, prompts: list[str] | None = None) -> dict[str, str]:
    """The inspectable files of one pipeline run: final script and output, earlier attempts, prompts.

    * ``script.R`` / ``script.py`` (by the execution's language), ``stdout.txt``,
      ``stderr.txt`` — the final execution.
    * ``attempt-<n>/script.*``, ``attempt-<n>/stdout.txt``,
      ``attempt-<n>/stderr.txt`` and, when feedback was sent to the model
      after it, ``attempt-<n>/feedback.txt`` — each superseded execution
      from ``ExecutionResult.attempts``, oldest first, numbered from 1.
    * ``prompt-<n>.txt`` — the generator's prompts in call order
      (generation, then refinements), numbered from 1.
    """
    exec_result = getattr(report, "execution_result", None)
    artifacts: dict[str, str] = {}
    if exec_result is not None:
        language = getattr(exec_result, "language", None)
        script = "script.R" if getattr(language, "value", language) == "r" else "script.py"
        artifacts[script] = str(getattr(exec_result, "generated_code", "") or "")
        artifacts["stdout.txt"] = str(getattr(exec_result, "stdout", "") or "")
        artifacts["stderr.txt"] = str(getattr(exec_result, "stderr", "") or "")
        for n, attempt in enumerate(getattr(exec_result, "attempts", None) or [], start=1):
            prefix = f"attempt-{n}/"
            artifacts[prefix + script] = str(getattr(attempt, "code", "") or "")
            artifacts[prefix + "stdout.txt"] = str(getattr(attempt, "stdout", "") or "")
            artifacts[prefix + "stderr.txt"] = str(getattr(attempt, "stderr", "") or "")
            feedback = str(getattr(attempt, "feedback", "") or "")
            if feedback:
                artifacts[prefix + "feedback.txt"] = feedback
    for n, prompt in enumerate(prompts or [], start=1):
        artifacts[f"prompt-{n}.txt"] = prompt
    return artifacts


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
    attempt_outputs, n_refinements = _attempt_record(exec_result)
    attempt_kinds = _attempt_kinds(exec_result) if attempt_outputs is not None else None
    n_error = getattr(exec_result, "n_error_refinements", None) if attempt_outputs is not None else None
    n_claim = getattr(exec_result, "n_claim_refinements", None) if attempt_outputs is not None else None
    return Reproduction(
        attempt_outputs=attempt_outputs,
        attempt_kinds=attempt_kinds,
        n_refinements=n_refinements,
        n_error_refinements=n_error if isinstance(n_error, int) else None,
        n_claim_refinements=n_claim if isinstance(n_claim, int) else None,
        n_executions=None if attempt_outputs is None else len(attempt_outputs),
        outputs=dict(getattr(exec_result, "outputs", {}) or {}) if exec_result else {},
        claims=list(getattr(paper, "claims", []) or []) if paper else [],
        generated_code=generated_code,
        stdout=str(getattr(exec_result, "stdout", "") or "") if exec_result else "",
        stderr=str(getattr(exec_result, "stderr", "") or "") if exec_result else "",
        exit_code=exit_code,
        deviations=list(getattr(exec_result, "deviation_notes", []) or []) if exec_result else [],
        stages=stages,
    )


def _final_index(exec_result: Any, n_attempts: int) -> int:
    """Position of the final run among all executions (last when unknown)."""
    index = getattr(exec_result, "final_execution_index", None)
    if not isinstance(index, int) or not 0 <= index <= n_attempts:
        return n_attempts
    return index


def _attempt_kinds(exec_result: Any) -> list[str]:
    """Refinement kind that followed each execution, in run order; ``""`` for the final run.

    Parallel to the outputs of :func:`_attempt_record` (callers check that
    returned a list first).
    """
    attempts = getattr(exec_result, "attempts", None) or []
    kinds = [str(getattr(a, "kind", "") or "") for a in attempts]
    kinds.insert(_final_index(exec_result, len(kinds)), "")
    return kinds


def _attempt_record(exec_result: Any) -> tuple[list[str] | None, int | None]:
    """``(stdout of every execution in run order, refinement calls)`` from an ``ExecutionResult``.

    The final run sits at ``final_execution_index`` among the superseded
    ``attempts`` (oldest first); when the index is unknown it is taken to be
    last.  ``(None, None)`` when there was no execution or the result does
    not carry an attempt list.
    """
    if exec_result is None:
        return None, None
    attempts = getattr(exec_result, "attempts", None)
    if not isinstance(attempts, list):
        return None, None
    outputs = [str(getattr(a, "stdout", "") or "") for a in attempts]
    outputs.insert(_final_index(exec_result, len(outputs)), str(getattr(exec_result, "stdout", "") or ""))
    # Every execution after the first needed a refinement call; a call whose
    # code came back unchanged adds one without an execution.
    calls = getattr(exec_result, "refinement_calls", None)
    calls = calls if isinstance(calls, int) else 0
    return outputs, max(calls, len(outputs) - 1)
