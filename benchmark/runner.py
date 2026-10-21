"""Benchmark runner: walk the catalog, reproduce each paper, score it.

The runner is the *harness*: it hands each catalog entry to a
``Reproducer`` (``benchmark.reproducer``; ``ValidationPipeline`` via
``PipelineReproducer`` is the reference one and the default), takes back
the raw ``{name: value}`` outputs, and scores them itself with
``ResultComparator`` under the mode's ``TolerancePolicy``.  A reproducer's
own pass/fail judgement is never read, so every agent is held to the
identical yardstick.

Three verdicts are recorded per paper:

* ``retally_ran`` — the reproducer completed without crashing.  Distinct
  from "all claims passed" — we want to know whether the infrastructure
  works even when the science doesn't.
* ``agrees_with_paper`` — every claim with a paper-stated value
  validates within the comparator's tolerance against the reproduced
  value.  Computed by the harness, from the reproducer's raw outputs.
* ``agrees_with_i4r`` — for every claim where the I4R replicator
  recorded a reproduced value, the reproduced value is within the
  comparator's tolerance of THAT value (not the paper's claim).

The three can disagree in meaningful ways — e.g. *ran ✓, agrees with
paper ✓, agrees with I4R ✗* means Retally faithfully reproduced what
the paper said, but the careful human replicators found a different
number.  See README for how each combination is interpreted.

Reproduction modes: every result is stamped with the ``mode`` it ran
in — ``seeded`` (the authors' replication-package scripts are in the
generation prompt: computational reproduction) or ``independent``
(they are withheld: reproduction from the paper text).  The runner can
run one mode or both; a result row is identified by ``(entry_id,
mode)``, never by ``entry_id`` alone, so the two are never conflated.

Caching: a content-addressable cache under ``benchmark/.cache/`` keyed
on ``(catalog_entry_hash, retally_version, mode, reproducer)`` lets us
re-run the benchmark cheaply when only the report renderer or
non-pipeline components changed.  Any benchmark entry edit, retally
version bump, mode change, or reproducer change selects a different
cache entry.

Artifacts: when ``run_benchmark`` is given an ``artifacts_root`` (the CLI
passes ``benchmark/results/artifacts/``), each executed row's
``Reproduction.artifacts`` — the generated script, sandbox stdout/stderr,
refinement attempts, prompts — are written to
``<artifacts_root>/<entry_id>/<mode>/<reproducer>/<run_id>/`` and the row's
``artifacts_dir`` points there.  ``python -m benchmark.artifacts`` reads
them back.
"""

from __future__ import annotations

import hashlib
import http.client
import importlib
import json
import logging
import os
import re
import sys
from collections.abc import Callable
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from enum import Enum
from pathlib import Path
from typing import Any

import requests
import urllib3.exceptions

# benchmark.* is at the repo root, not under src/retally/, so the test
# helper and this module both reach into the sibling schema module.
from benchmark import pricing
from benchmark import schema as bschema
from benchmark.reproducer import (
    ComponentMetrics,
    MissingAPIKeyError,
    PipelineReproducer,
    Reproducer,
    Reproduction,
)

__all__ = [
    "BenchmarkResult",
    "ClaimDetail",
    "ComponentMetrics",
    "DEFAULT_REPRODUCER",
    "REPRODUCERS",
    "new_run_id",
    "resolve_reproducer",
    "run_benchmark",
    "score_reproduction",
    "write_results",
]

logger = logging.getLogger(__name__)

REPO_ROOT = Path(__file__).resolve().parent.parent
CATALOG_DIR = REPO_ROOT / "benchmark" / "papers"
CACHE_DIR = REPO_ROOT / "benchmark" / ".cache"
RESULTS_DIR = REPO_ROOT / "benchmark" / "results"
ARTIFACTS_DIR = RESULTS_DIR / "artifacts"

# Reproduction modes, as the plain strings recorded in results.json.  They
# mirror ``retally.models.ReproductionMode`` values; kept as strings here so
# this module stays importable without retally installed.
SEEDED = "seeded"
INDEPENDENT = "independent"
BLIND = "blind"
MODES = (SEEDED, INDEPENDENT, BLIND)
BOTH_MODES = (SEEDED, INDEPENDENT)
"""What ``--mode both`` runs: seeded and independent, as before blind existed.
``--mode all`` runs every mode in ``MODES``."""
SCRIPT_FREE_MODES = frozenset({INDEPENDENT, BLIND})
"""Modes whose dataset is the script-free copy (see ``benchmark.reproducer``)."""

DEFAULT_REPRODUCER = "pipeline"


# ---------------------------------------------------------------------------
# Per-entry result model
# ---------------------------------------------------------------------------


class SkipReason(Enum):
    """Why a catalog entry wasn't executed.

    ``OUT_OF_SCOPE`` covers entries with a non-null
    ``out_of_scope_reason`` set in the YAML.  ``LANGUAGE_UNSUPPORTED``
    covers entries the runner can't handle yet (R until that lands,
    Stata permanently).  ``NO_API_KEY`` covers running the harness
    without ``ANTHROPIC_API_KEY`` — the reproducer factory raised
    ``MissingAPIKeyError``, so we record the skip rather than crashing.
    ``REPRODUCER_INIT_FAILED`` covers a factory that raised anything else
    (Docker unavailable, sandbox image not built, a bad plugin import);
    the exception text goes in ``error``.
    """

    OUT_OF_SCOPE = "out_of_scope"
    LANGUAGE_UNSUPPORTED = "language_unsupported"
    NO_API_KEY = "no_api_key"
    REPRODUCER_INIT_FAILED = "reproducer_init_failed"


@dataclass
class ClaimDetail:
    """Per-claim comparison record — the tuning signal.

    Binary pass counts are too coarse for prompt iteration: at 0/102 a
    change that drags half the claims from 300% error to 5% error reads
    as "still zero".  Storing the actual (claimed, reproduced) pair per
    claim lets reports and run comparisons compute distance metrics
    (median relative error, fraction within k× tolerance) that move
    smoothly as prompts improve.
    """

    description: str
    claim_type: str
    claimed: float
    reproduced: float | None
    """None when no output could be matched to this claim at all."""

    tolerance: float
    rel_err: float | None
    """``|reproduced - claimed| / max(|claimed|, 1e-9)`` — same formula
    the comparator uses for the pass decision.  None when unmatched."""

    passed: bool

    passed_first_attempt: bool | None = None
    """Whether the reproducer's *first* execution already passed this claim
    (same comparator, mode and tolerance as ``passed``), before any
    refinement feedback.  None when the reproducer reported no attempts,
    and on rows from files that predate the field."""

    passed_first_scored: bool | None = None
    """Whether the *first scored* execution (the first whose stdout had a
    parsable ``RESULT:`` line — crash repairs skipped) passed this claim,
    before any claim-targeted feedback.  None when the reproducer reported
    no attempts, and on rows from files that predate the field."""

    tolerance_source: str | None = None
    """Which bound set ``tolerance``: ``"relative"`` (per-type relative
    tolerance), ``"se_band"`` (±k·SE, SE-aware modes) or
    ``"printed_precision"`` (half a unit in the pinned value's last
    printed place).  None on rows from files that predate the field."""


@dataclass
class BenchmarkResult:
    """Outcome of running one BenchmarkEntry through the pipeline.

    ``skipped`` is True for catalog entries the runner declined to
    execute (out of scope, unsupported language, missing API key).  In
    that case the verdict fields stay None.
    """

    entry_id: str
    mode: str = SEEDED
    """Reproduction mode this row was produced in (``seeded`` /
    ``independent``).  ``(entry_id, mode)`` identifies a row; results
    deserialised from files that predate the field default to seeded,
    which is what every earlier run was."""

    reproducer: str = DEFAULT_REPRODUCER
    """Which reproducer produced this row (a ``REPRODUCERS`` name or a
    ``module:attr`` spec).  Files that predate the field were all
    produced by the pipeline."""

    skipped: bool = False
    skip_reason: SkipReason | None = None
    error: str | None = None
    """Set when the pipeline raised — None on success or skip."""

    transient: bool = False
    """True when ``error`` came from a download / network / HTTP failure or
    an Anthropic API account / service error (see :func:`_is_transient_error`).
    Such rows are reported but never written to the result cache, so the
    next run retries the paper instead of replaying the failure."""

    error_kind: str | None = None
    """Classification of ``error``: one of :data:`TRANSIENT_ERROR_KINDS`
    (``network``, ``api_billing``, ``api_unavailable``, ``api_auth``) when
    ``transient``, ``pipeline`` for a genuine pipeline error, None when the
    reproducer did not raise (and on rows from older files)."""

    retally_ran: bool | None = None
    agrees_with_paper: bool | None = None
    agrees_with_i4r: bool | None = None

    n_claims_in_catalog: int = 0
    n_claims_with_paper_match: int = 0
    n_claims_with_i4r_match: int = 0

    n_claims_with_paper_match_first_attempt: int | None = None
    """Claims the reproducer's first execution already passed against the
    paper — before the refinement loop showed it which claims were off
    target.  ``n_claims_with_paper_match`` is the final pass, after that
    target-guided search.  None when the reproducer reported no attempt
    data (and on rows from older files)."""

    n_refinements: int | None = None
    """Refinement calls the reproducer made after its first script (0: the
    first script was final).  None when not reported."""

    n_executions: int | None = None
    """Sandbox executions the reproducer ran.  None when not reported."""

    n_claims_with_paper_match_first_scored: int | None = None
    """Claims passed by the *first scored* execution: the first one whose
    stdout had at least one parsable ``RESULT:`` line (falling back to the
    first execution when none had any).  Execution-error repairs (a crash,
    no output) come before it, claim-targeted feedback after it, so this is
    the "before target feedback" number; the raw first-attempt count is 0
    whenever the first script crashed.  None when the reproducer reported
    no attempt data (and on rows from older files)."""

    first_scored_attempt_index: int | None = None
    """0-based position of the first scored execution among all executions
    (0 when the first script already produced output).  None when not
    recorded."""

    n_error_refinements: int | None = None
    """Execution-error refinements (crash / no-output repairs).  None when
    not reported."""

    n_claim_refinements: int | None = None
    """Claim-targeted refinements (the model was shown which claims were off
    target).  None when not reported."""

    claim_details: list[ClaimDetail] = field(default_factory=list)
    """One record per compared claim.  Empty on skips/crashes and on
    results deserialised from pre-claim-detail cache files."""

    split: str = "dev"
    """Evaluation split, stamped from the catalog entry at run time (so
    a cached result reflects the entry's *current* split assignment)."""

    components: ComponentMetrics = field(default_factory=ComponentMetrics)

    cached: bool = False
    """True when the result came from benchmark/.cache; False when we
    re-ran the pipeline.  Useful in reports so a reader knows what was
    actually exercised in this run."""

    usage: dict[str, Any] | None = None
    """Claude API spend of the run that produced this row: the
    reproducer's ``Reproduction.usage`` (tokens by model, API calls, LLM-cache
    hits) plus ``estimated_usd`` from ``benchmark.pricing``.  None for skips,
    for reproducers that do not track usage, and for rows from files that
    predate the field.  On a result-cache hit (``cached``) it describes the
    original run, not this one, and run totals exclude it."""

    artifacts_dir: str | None = None
    """Where this row's run artifacts (generated script, sandbox output,
    refinement attempts, prompts) were written, relative to the repo root
    when under it.  None when artifacts were not written (skips, crashes,
    a reproducer that returns none, or a run without an artifacts root).
    A result-cache hit keeps the directory of the run that produced it."""


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def run_benchmark(
    catalog: list[bschema.BenchmarkEntry] | None = None,
    *,
    reproducer: str = DEFAULT_REPRODUCER,
    reproducer_factory: Callable[[], Reproducer] | None = None,
    pipeline_factory: Callable[[], Any] | None = None,
    cache_dir: Path = CACHE_DIR,
    use_cache: bool = True,
    extracted_claims_dir: Path | None = None,
    modes: tuple[str, ...] = (SEEDED,),
    artifacts_root: Path | None = None,
    run_id: str | None = None,
) -> list[BenchmarkResult]:
    """Run every catalog entry in each of ``modes``; one BenchmarkResult per (paper, mode).

    ``reproducer`` names the agent being scored — a ``REPRODUCERS`` key
    (``"pipeline"``, the default) or a ``module:attr`` spec, see
    :func:`resolve_reproducer`.  It is recorded on every result and is part
    of the cache key.  ``reproducer_factory`` is a zero-arg callable
    returning a :class:`~benchmark.reproducer.Reproducer`; when omitted it
    is resolved from ``reproducer``.  Injecting it keeps the runner
    testable without an API key.  It is only called on a cache miss.  A
    factory that raises ``MissingAPIKeyError`` is recorded as a
    ``no_api_key`` skip; one that raises anything else as a
    ``reproducer_init_failed`` skip carrying the exception message.

    ``pipeline_factory`` is the older convenience form: a zero-arg callable
    returning a ``ValidationPipeline`` (or anything with a compatible
    ``validate(...)``), wrapped in ``PipelineReproducer``.  Mutually
    exclusive with ``reproducer_factory``.

    Whatever the reproducer, scoring is done here, by
    :func:`score_reproduction`, from its raw outputs.

    ``extracted_claims_dir``, when set, receives one JSON file per
    executed entry containing the claims the extractor pulled from the
    paper — in a shape directly pasteable into the catalog YAML's
    ``original_claims``.  That's the pinning workflow: run once live,
    review the dump, curate it into the catalog, and every later run
    skips the extraction call and scores against a frozen claim set.
    Entries that already have pinned claims are not dumped (the file
    would just echo the catalog).  None (the default) disables dumping.

    ``modes`` selects the reproduction modes to run (any of ``"seeded"``,
    ``"independent"`` and ``"blind"``).  The default, seeded only, is the
    historical behaviour.  Results are ordered by entry, then by mode in
    the order given, so a both-mode run puts each paper's two rows next
    to each other.

    ``artifacts_root``, when set, receives each executed row's
    ``Reproduction.artifacts`` under
    ``<artifacts_root>/<entry_id>/<mode>/<reproducer>/<run_id>/``
    (``run_id`` defaults to :func:`new_run_id`, one per call) and the row's
    ``artifacts_dir`` records it.  None (the default) writes nothing.
    Cached rows are returned as cached, with their original
    ``artifacts_dir``.
    """
    if run_id is None:
        run_id = new_run_id()
    if catalog is None:
        catalog = bschema.load_catalog(CATALOG_DIR)
    unknown = [m for m in modes if m not in MODES]
    if unknown:
        raise ValueError(f"unknown reproduction mode(s) {unknown}; expected a subset of {list(MODES)}")
    if pipeline_factory is not None:
        if reproducer_factory is not None:
            raise ValueError("pass reproducer_factory or pipeline_factory, not both")
        reproducer_factory = _pipeline_reproducer_factory(pipeline_factory)
    elif reproducer_factory is None:
        # Resolve eagerly so a typo fails before any paper runs; the factory
        # itself is only called on a cache miss.
        reproducer_factory = resolve_reproducer(reproducer)

    results: list[BenchmarkResult] = []
    for entry in catalog:
        for mode in modes:
            result = _run_one(
                entry,
                reproducer_factory=reproducer_factory,
                reproducer=reproducer,
                cache_dir=cache_dir,
                use_cache=use_cache,
                extracted_claims_dir=extracted_claims_dir,
                mode=mode,
                artifacts_root=artifacts_root,
                run_id=run_id,
            )
            results.append(result)
    return results


def write_results(results: list[BenchmarkResult], out_path: Path) -> None:
    """Serialise results to JSON for the report renderer to consume.

    Shape: ``{"usage": <run-level spend>, "results": [<row>, ...]}`` —
    ``usage`` is :func:`benchmark.pricing.aggregate` over the rows.  Files
    written before the spend accounting are a bare list of rows; readers go
    through :func:`benchmark.metrics.result_rows`, which accepts both.
    """
    rows = [_result_to_jsonable(r) for r in results]
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(
        json.dumps({"usage": pricing.aggregate(rows), "results": rows}, indent=2) + "\n",
        encoding="utf-8",
    )


def main(argv: list[str] | None = None) -> int:
    """CLI entrypoint — ``python -m benchmark.runner`` or ``make benchmark``."""
    import argparse

    parser = argparse.ArgumentParser(
        prog="python -m benchmark.runner",
        description="Run the benchmark catalog and write benchmark/results/results.json.",
    )
    parser.add_argument(
        "--only",
        action="append",
        metavar="ENTRY_ID",
        help="Run only this catalog entry (repeatable).  Other entries are omitted from results.json.",
    )
    parser.add_argument(
        "--mode",
        choices=[SEEDED, INDEPENDENT, BLIND, "both", "all"],
        default=SEEDED,
        help=(
            "Reproduction mode: 'seeded' (authors' package scripts in the prompt; the default), "
            "'independent' (scripts withheld), 'blind' (scripts and claim values withheld, no "
            "claim-targeted refinement), 'both' (seeded and independent) or 'all' (all three); "
            "one results.json row per entry per mode."
        ),
    )
    parser.add_argument(
        "--reproducer",
        default=DEFAULT_REPRODUCER,
        metavar="NAME",
        help=(
            f"Agent to score: a built-in name ({', '.join(sorted(REPRODUCERS))}; the default) "
            "or a 'package.module:factory' spec naming a zero-arg callable that returns a "
            "benchmark.reproducer.Reproducer."
        ),
    )
    args = parser.parse_args(argv)
    modes = {"both": BOTH_MODES, "all": MODES}.get(args.mode, (args.mode,))
    try:
        resolve_reproducer(args.reproducer)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 2

    logging.basicConfig(level=logging.INFO, format="%(message)s")
    catalog = bschema.load_catalog(CATALOG_DIR)
    if args.only:
        known = {e.id for e in catalog}
        unknown = sorted(set(args.only) - known)
        if unknown:
            print(f"Unknown catalog entry id(s): {', '.join(unknown)}", file=sys.stderr)
            return 2
        catalog = [e for e in catalog if e.id in set(args.only)]
    if not catalog:
        # Empty catalog is a legitimate state — the placeholders moved to
        # tests/fixtures/ in PR #18 and the real I4R entries haven't landed
        # yet.  Write an empty results.json (so the report renderer can
        # produce an honest "catalog is empty" REPORT.md) and exit 0,
        # rather than bail and leave a stale REPORT.md in place.
        print(
            f"No benchmark entries at {CATALOG_DIR.relative_to(REPO_ROOT)} — writing empty results.",
            file=sys.stderr,
        )
        write_results([], RESULTS_DIR / "results.json")
        return 0

    run_id = new_run_id()
    results = run_benchmark(
        catalog,
        reproducer=args.reproducer,
        extracted_claims_dir=RESULTS_DIR / "extracted_claims",
        modes=modes,
        artifacts_root=ARTIFACTS_DIR,
        run_id=run_id,
    )
    out = RESULTS_DIR / "results.json"
    write_results(results, out)
    print(f"Wrote {out.relative_to(REPO_ROOT)} ({len(results)} entries).")
    n_fresh = sum(1 for r in results if r.artifacts_dir and not r.cached)
    print(
        f"Artifacts: {n_fresh} row(s) written under {_display_path(ARTIFACTS_DIR)}/<entry>/<mode>/"
        f"<reproducer>/{run_id}/ (inspect with: uv run python -m benchmark.artifacts {_display_path(out)})."
    )
    spend = pricing.aggregate([_result_to_jsonable(r) for r in results])
    print(
        f"Estimated API spend: {pricing.format_usd(spend['estimated_usd'])} "
        f"({spend['api_calls']} API calls; {spend['llm_cache_hits']} served free by the LLM cache)."
    )
    notice = transient_notice(results)
    if notice:
        print(notice)
    return 0


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------


def _run_one(
    entry: bschema.BenchmarkEntry,
    *,
    reproducer_factory: Callable[[], Reproducer],
    reproducer: str = DEFAULT_REPRODUCER,
    cache_dir: Path,
    use_cache: bool,
    extracted_claims_dir: Path | None = None,
    mode: str = SEEDED,
    artifacts_root: Path | None = None,
    run_id: str = "",
) -> BenchmarkResult:
    """Execute (or skip) a single catalog entry in ``mode`` and return its result."""
    # Skip paths come first — no reproducer build, no cache check.
    skip = _check_skip(entry)
    if skip is not None:
        return BenchmarkResult(
            entry_id=entry.id,
            mode=mode,
            reproducer=reproducer,
            skipped=True,
            skip_reason=skip,
            split=entry.split,
        )

    cache_key = _cache_key(entry, mode, reproducer)
    cached = _load_cache(cache_dir, cache_key) if use_cache else None
    if cached is not None:
        cached.cached = True
        # Split is a catalog property, not a run outcome — stamp the
        # entry's *current* assignment so moving a paper between splits
        # doesn't require invalidating its cached result.
        cached.split = entry.split
        cached.mode = mode
        cached.reproducer = reproducer
        return cached

    try:
        agent = reproducer_factory()
    except MissingAPIKeyError as exc:
        logger.warning("No API key for %s: %s", entry.id, exc)
        return BenchmarkResult(
            entry_id=entry.id,
            mode=mode,
            reproducer=reproducer,
            skipped=True,
            skip_reason=SkipReason.NO_API_KEY,
            error=str(exc),
        )
    except Exception as exc:
        logger.warning("Reproducer construction failed for %s: %s", entry.id, exc)
        return BenchmarkResult(
            entry_id=entry.id,
            mode=mode,
            reproducer=reproducer,
            skipped=True,
            skip_reason=SkipReason.REPRODUCER_INIT_FAILED,
            error=f"{type(exc).__name__}: {exc}",
        )

    result, artifacts = _execute_with_reproducer(
        entry, agent, extracted_claims_dir=extracted_claims_dir, mode=mode
    )
    result.split = entry.split
    result.reproducer = reproducer
    if artifacts_root is not None and artifacts:
        out_dir = artifacts_root / entry.id / mode / _path_component(reproducer) / (run_id or new_run_id())
        if _write_artifacts(out_dir, artifacts):
            result.artifacts_dir = _display_path(out_dir)

    if use_cache and not result.skipped:
        if result.transient:
            logger.warning(
                "Not caching %s (%s): transient %s error: %s", entry.id, mode, result.error_kind, result.error
            )
        else:
            _save_cache(cache_dir, cache_key, result)

    return result


_SUPPORTED_LANGUAGES = {bschema.Language.PYTHON, bschema.Language.R}


def _check_skip(entry: bschema.BenchmarkEntry) -> SkipReason | None:
    """Return the skip reason for ``entry``, or None if we should run it."""
    if entry.out_of_scope_reason:
        return SkipReason.OUT_OF_SCOPE
    if entry.language not in _SUPPORTED_LANGUAGES:
        # Stata is the main case — generator + sandbox don't ship.  Anything
        # else (UNKNOWN, or a future enum addition the runner doesn't yet
        # know about) is also a clean skip rather than a crash.
        return SkipReason.LANGUAGE_UNSUPPORTED
    return None


def _execute_with_reproducer(
    entry: bschema.BenchmarkEntry,
    agent: Reproducer,
    *,
    extracted_claims_dir: Path | None = None,
    mode: str = SEEDED,
) -> tuple[BenchmarkResult, dict[str, str]]:
    """Drive ``agent.reproduce`` and score what it returns.

    Returns the scored row and the reproduction's ``artifacts`` (empty when
    the reproducer raised or returned none) for :func:`_run_one` to write.

    Wrapped in a broad try/except because the goal here is to score
    every paper in the catalog — a crash on one entry must not bring
    down the whole benchmark run.  The exception text is captured on
    the result so it shows up in the report.
    """
    from retally.models import ReproductionMode

    claims_override = _claims_override_for(entry)
    try:
        # The parser never infers language from the paper text, so the
        # catalog's declared language must be propagated explicitly —
        # otherwise every R entry would silently run through the Python
        # generator + executor.
        #
        # Likewise, papers frequently don't mention a downloadable dataset
        # URL in their body (the replication package is deposited
        # separately), so the extractor's dataset resolution comes up
        # empty.  When the catalog names a dataset source we pass it as an
        # explicit override, skipping the extractor's guesswork entirely.
        #
        # Finally, when the catalog has curated ``original_claims`` we pin
        # them: the claims-extraction call (the pipeline's most expensive)
        # is skipped, and — just as important — every run scores against
        # the same frozen claim set instead of whatever the extractor
        # happened to return this time.
        #
        # The reproduction mode is always passed explicitly — it is part of
        # the contract a reproducer must honour, and it decides whether the
        # authors' package scripts may be used.
        reproduction = agent.reproduce(
            entry.paper.source,
            language=entry.language,
            dataset_reference=_dataset_reference_for(entry),
            claims=claims_override,
            reproduction_mode=ReproductionMode(mode),
        )
    except Exception as exc:
        logger.warning("Reproducer raised on %s: %s", entry.id, exc)
        kind = _transient_error_kind(exc)
        # A failed run still spent tokens; a reproducer may expose them.
        failed = BenchmarkResult(
            entry_id=entry.id,
            mode=mode,
            retally_ran=False,
            error=f"{type(exc).__name__}: {exc}",
            transient=kind is not None,
            error_kind=kind or PIPELINE_ERROR,
            usage=_priced_usage(getattr(agent, "last_usage", None)),
        )
        return failed, {}

    # Dump what the extractor found so a human can curate it into the
    # catalog's original_claims (the pinning workflow).  Skipped when the
    # claims were already pinned — the dump would just echo the catalog.
    if extracted_claims_dir is not None and claims_override is None:
        _dump_extracted_claims(extracted_claims_dir, entry.id, reproduction.claims)

    result = score_reproduction(entry, reproduction, mode=mode)
    result.usage = _priced_usage(getattr(reproduction, "usage", None))
    return result, dict(getattr(reproduction, "artifacts", None) or {})


_NETWORK_EXCEPTIONS: tuple[type[BaseException], ...] = (
    requests.exceptions.RequestException,  # HTTPError (4xx/5xx), ConnectionError, Timeout, ...
    urllib3.exceptions.HTTPError,  # ProtocolError, ReadTimeoutError, ...
    http.client.HTTPException,  # IncompleteRead, RemoteDisconnected, ...
    ConnectionError,  # builtin: resets, refused, broken pipe
    TimeoutError,  # builtin; socket.timeout is an alias
)

_DOWNLOAD_FAILURE_PREFIX = "Failed to download dataset "
"""Prefix of the ``RuntimeError`` ``DatasetDownloader.download`` wraps every
dataset-fetch failure in."""


# ``error_kind`` values.  The first four are transient (never cached).
NETWORK_ERROR = "network"
API_BILLING_ERROR = "api_billing"
API_UNAVAILABLE_ERROR = "api_unavailable"
API_AUTH_ERROR = "api_auth"
PIPELINE_ERROR = "pipeline"
TRANSIENT_ERROR_KINDS = (NETWORK_ERROR, API_BILLING_ERROR, API_UNAVAILABLE_ERROR, API_AUTH_ERROR)

_CREDIT_EXHAUSTED_TEXT = "credit balance is too low"
"""Anthropic's 400 message when the account is out of credit.  Matched on
any exception's text, so a ``RuntimeError`` / string that wraps it still
classifies as billing."""

_BILLING_MARKERS = ("credit balance", "plans & billing")
"""Narrow, lower-case markers that make an Anthropic ``BadRequestError`` a
billing problem rather than a malformed request."""


def _anthropic_error_kind(exc: BaseException) -> str | None:
    """Classify one exception as an Anthropic account / service error, or None.

    ``anthropic`` is imported lazily and guarded, so the runner stays
    importable (and this simply returns None) without the SDK.
    """
    try:
        import anthropic
    except ImportError:  # pragma: no cover - the SDK is a project dependency
        return None
    if isinstance(exc, anthropic.APIConnectionError):  # includes APITimeoutError
        return API_UNAVAILABLE_ERROR
    if isinstance(exc, anthropic.RateLimitError):
        return API_UNAVAILABLE_ERROR
    if isinstance(exc, (anthropic.AuthenticationError, anthropic.PermissionDeniedError)):
        return API_AUTH_ERROR
    if isinstance(exc, anthropic.BadRequestError):
        text = str(exc).lower()
        return API_BILLING_ERROR if any(m in text for m in _BILLING_MARKERS) else None
    if isinstance(exc, anthropic.APIStatusError) and exc.status_code >= 500:
        return API_UNAVAILABLE_ERROR  # InternalServerError, overloaded (529), ...
    return None


def _transient_error_kind(exc: BaseException) -> str | None:
    """The transient ``error_kind`` of ``exc``, or None for a genuine pipeline error.

    Deliberately narrow: transient iff the exception, or anything on its
    ``__cause__`` / ``__context__`` chain, is

    * ``network``: a ``requests`` / ``urllib3`` / ``http.client`` /
      socket-level network error, or the downloader's
      ``RuntimeError("Failed to download dataset ...")``;
    * ``api_billing``: an Anthropic ``BadRequestError`` whose message
      mentions the credit balance or Plans & Billing, or any exception whose
      text contains "credit balance is too low" (string-wrapped errors);
    * ``api_unavailable``: an Anthropic rate limit (429), connection error
      or timeout, or any ``APIStatusError`` with status >= 500;
    * ``api_auth``: an Anthropic ``AuthenticationError`` (401) or
      ``PermissionDeniedError`` (403).

    These are about the account, the service or the network, not the paper.
    Everything else — a parse failure, a generation error, a sandbox
    problem, an ordinary 400 for a malformed request — is a genuine outcome
    and stays cacheable.  (A script that crashes *inside* the sandbox never
    raises here at all; it comes back as a scored reproduction.)
    """
    seen: set[int] = set()
    cur: BaseException | None = exc
    while cur is not None and id(cur) not in seen:
        seen.add(id(cur))
        kind = _anthropic_error_kind(cur)
        if kind is not None:
            return kind
        if _CREDIT_EXHAUSTED_TEXT in str(cur).lower():
            return API_BILLING_ERROR
        if isinstance(cur, _NETWORK_EXCEPTIONS):
            return NETWORK_ERROR
        if isinstance(cur, RuntimeError) and str(cur).startswith(_DOWNLOAD_FAILURE_PREFIX):
            return NETWORK_ERROR
        cur = cur.__cause__ or cur.__context__
    return None


def _is_transient_error(exc: BaseException) -> bool:
    """True when ``exc`` is a network or Anthropic account / service failure.

    See :func:`_transient_error_kind` for the classification.
    """
    return _transient_error_kind(exc) is not None


def transient_notice(results: list[BenchmarkResult]) -> str | None:
    """A loud one-line warning when any row failed on a transient error, else None.

    A credit-exhausted or rate-limited run must not be mistaken for a
    measurement, so the CLI prints this at the end of its summary.
    """
    transient = [r for r in results if r.transient]
    if not transient:
        return None
    kinds = sorted({r.error_kind or "unknown" for r in transient})
    return (
        f"WARNING: {len(transient)} row(s) failed on transient errors ({', '.join(kinds)}) "
        "and were not cached; re-run after fixing the cause."
    )


def new_run_id() -> str:
    """A UTC timestamp naming one benchmark run's artifact directories, e.g. ``20261020T183012Z``."""
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def _path_component(name: str) -> str:
    """``name`` made safe as one path segment (a ``module:attr`` reproducer spec has a colon)."""
    return re.sub(r"[^A-Za-z0-9._-]+", "_", name).strip(".") or "_"


def _display_path(path: Path) -> str:
    """``path`` relative to the repo root when it is under it, else absolute."""
    try:
        return str(path.resolve().relative_to(REPO_ROOT))
    except ValueError:
        return str(path.resolve())


def _write_artifacts(out_dir: Path, artifacts: dict[str, str]) -> bool:
    """Write ``artifacts`` (relative path → text) under ``out_dir``; True on success.

    Best-effort, like the extracted-claims dump: a failure is logged and the
    row simply carries no ``artifacts_dir``.  Paths that are absolute or
    climb out with ``..`` are skipped.
    """
    try:
        out_dir.mkdir(parents=True, exist_ok=True)
        for rel, text in artifacts.items():
            rel_path = Path(rel)
            if rel_path.is_absolute() or ".." in rel_path.parts:
                logger.warning("Skipping unsafe artifact path %r", rel)
                continue
            target = out_dir / rel_path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(str(text), encoding="utf-8")
        return True
    except OSError as exc:
        logger.warning("Failed to write artifacts to %s: %s", out_dir, exc)
        return False


def _priced_usage(usage: Any) -> dict[str, Any] | None:
    """A reproducer's usage dict with ``estimated_usd`` added; None when absent or malformed."""
    return pricing.priced(usage) if isinstance(usage, dict) else None


def score_reproduction(
    entry: bschema.BenchmarkEntry,
    reproduction: Reproduction,
    *,
    mode: str = SEEDED,
    comparator: Any = None,
) -> BenchmarkResult:
    """Score one reproduction against the paper and the I4R replicators.

    This is the single scoring code path for every reproducer.  It reads
    only ``reproduction.outputs`` (raw ``{name: value}``), the stage
    flags, and — for unpinned entries only — ``reproduction.claims``.  Any
    verdict the agent computed for itself is never consulted.

    * Claims scored: the entry's pinned ``original_claims`` when it has
      any (whatever the agent says it targeted), else
      ``reproduction.claims`` (an unpinned entry is scored against what
      the agent extracted — a weaker yardstick, which is why entries get
      pinned).
    * Matching and tolerance: ``ResultComparator.compare_all(...,
      mode=...)`` — per-type relative tolerance in seeded mode, the ±k·SE
      band in independent mode where an SE is pinned.  ``comparator``
      overrides the default ``ResultComparator()`` (e.g. a different k).
    * ``agrees_with_paper``: at least one claim, and every claim passes
      (the same rule as the pipeline's ``overall_passed``).
      ``agrees_with_i4r``: each claim's effective tolerance, applied
      against the replicator's value.
    """
    from retally.models import ReproductionMode
    from retally.validation.comparator import ResultComparator

    claims = _claims_override_for(entry)
    if claims is None:
        claims = list(reproduction.claims)
    comparator = comparator or ResultComparator()
    claim_results = comparator.compare_all(claims, dict(reproduction.outputs), mode=ReproductionMode(mode))
    n_passed = sum(1 for cr in claim_results if cr.passed)
    n_i4r_match, agrees_with_i4r = _score_against_i4r(claim_results, entry)
    details = [_claim_detail(cr) for cr in claim_results]

    # First attempt: the first execution's RESULT lines, scored identically.
    # First scored: the first execution that printed any parsable RESULT
    # line, i.e. after crash repairs but before claim-targeted feedback.
    attempt_outputs = getattr(reproduction, "attempt_outputs", None)
    n_first: int | None = None
    n_first_scored: int | None = None
    first_scored_index: int | None = None
    if attempt_outputs:
        first = comparator.compare_all(
            claims, _parse_result_lines(str(attempt_outputs[0] or "")), mode=ReproductionMode(mode)
        )
        for detail, cr in zip(details, first, strict=True):
            detail.passed_first_attempt = bool(cr.passed)
        n_first = sum(1 for cr in first if cr.passed)
        first_scored_index = first_scored_attempt(attempt_outputs)
        scored = comparator.compare_all(
            claims,
            _parse_result_lines(str(attempt_outputs[first_scored_index] or "")),
            mode=ReproductionMode(mode),
        )
        for detail, cr in zip(details, scored, strict=True):
            detail.passed_first_scored = bool(cr.passed)
        n_first_scored = sum(1 for cr in scored if cr.passed)
    n_executions = getattr(reproduction, "n_executions", None)
    if n_executions is None and attempt_outputs is not None:
        n_executions = len(attempt_outputs)

    return BenchmarkResult(
        entry_id=entry.id,
        mode=mode,
        split=entry.split,
        retally_ran=True,
        agrees_with_paper=bool(claim_results) and n_passed == len(claim_results),
        agrees_with_i4r=agrees_with_i4r,
        n_claims_in_catalog=len(entry.original_claims),
        n_claims_with_paper_match=n_passed,
        n_claims_with_i4r_match=n_i4r_match,
        n_claims_with_paper_match_first_attempt=n_first,
        n_refinements=getattr(reproduction, "n_refinements", None),
        n_executions=n_executions,
        n_claims_with_paper_match_first_scored=n_first_scored,
        first_scored_attempt_index=first_scored_index,
        n_error_refinements=_optional_int(getattr(reproduction, "n_error_refinements", None)),
        n_claim_refinements=_optional_int(getattr(reproduction, "n_claim_refinements", None)),
        claim_details=details,
        components=reproduction.stages,
    )


def first_scored_attempt(attempt_outputs: list[str]) -> int:
    """Index of the first stdout with at least one parsable ``RESULT:`` line; 0 when none has one.

    Uses the same parser as final scoring, so an all-``NA`` or malformed
    output does not count as scored.
    """
    for i, stdout in enumerate(attempt_outputs):
        if _parse_result_lines(str(stdout or "")):
            return i
    return 0


def _parse_result_lines(stdout: str) -> dict[str, float]:
    """``RESULT:<name>=<value>`` lines of ``stdout``, as the executors parse them.

    Malformed and ``=NA`` lines are dropped silently (the executor warns
    about them when the run happens; re-warning while scoring is noise).
    """
    import warnings

    from retally.codegen.executor import parse_outputs

    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        return parse_outputs(stdout)


def _claim_detail(cr: Any) -> ClaimDetail:
    """Flatten one ClaimValidationResult into a serialisable ClaimDetail."""
    claimed = float(cr.claim.value)
    reproduced = cr.reproduced_value
    rel_err = None
    if reproduced is not None:
        rel_err = abs(float(reproduced) - claimed) / max(abs(claimed), 1e-9)
    return ClaimDetail(
        description=str(cr.claim.description),
        claim_type=getattr(cr.claim.claim_type, "value", str(cr.claim.claim_type)),
        claimed=claimed,
        reproduced=None if reproduced is None else float(reproduced),
        tolerance=float(cr.tolerance or 0.0),
        rel_err=rel_err,
        passed=bool(cr.passed),
        tolerance_source=str(getattr(cr, "tolerance_source", "relative")),
    )


# Host substrings mapped to the downloader's DatasetSource.  Anything
# not matched here that still looks like an http(s) URL falls back to
# DIRECT_URL; a non-URL identifier falls back to UNKNOWN.
_DATASET_HOST_SOURCES = {
    "zenodo.org": "zenodo",
    "dataverse.harvard.edu": "harvard_dataverse",
    "figshare.com": "figshare",
    "kaggle.com": "kaggle",
    "openml.org": "openml",
    "archive.ics.uci.edu": "uci",
}


def _claims_override_for(entry: bschema.BenchmarkEntry):
    """Convert the catalog's curated ``original_claims`` into pipeline Claims.

    Returns ``None`` when the entry has no curated claims, in which case
    the pipeline extracts claims from the paper text (a live LLM call).
    Imported lazily so the runner module stays importable without retally
    installed.

    Field mapping: the catalog's free-form ``claim_type`` string maps to
    the library enum, falling back to OTHER for labels the enum doesn't
    know; ``location`` ("Table 3, col 4") maps to ``table_ref``;
    ``standard_error`` is carried across so the comparator's SE-aware
    (independent-mode) tolerance can use it, and ``decimals`` (explicit or
    inferred from the YAML literal) for its printed-precision floor
    (every mode).  ``sample_size`` has no
    Claim counterpart and is dropped here.
    """
    if not entry.original_claims:
        return None

    from retally.models import Claim, ClaimType

    claims = []
    for oc in entry.original_claims:
        try:
            claim_type = ClaimType(oc.claim_type)
        except ValueError:
            claim_type = ClaimType.OTHER
        claims.append(
            Claim(
                description=oc.description,
                value=oc.value,
                unit=oc.unit,
                claim_type=claim_type,
                context=oc.context,
                table_ref=oc.location,
                standard_error=oc.standard_error,
                decimals=oc.decimals,
            )
        )
    return claims


def _dump_extracted_claims(out_dir: Path, entry_id: str, claims: list) -> None:
    """Write the extractor's claims for one entry as catalog-ready JSON.

    Best-effort: the dump is a curation convenience, so any failure is
    logged and swallowed rather than allowed to fail the benchmark run.
    The output shape mirrors the YAML ``original_claims`` schema so a
    reviewed entry can be pasted across with minimal editing.
    """
    try:
        payload = [
            {
                "description": c.description,
                "value": c.value,
                "unit": c.unit,
                "claim_type": getattr(c.claim_type, "value", str(c.claim_type)),
                "context": c.context,
                "location": c.table_ref,
            }
            for c in claims
        ]
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / f"{entry_id}.json"
        out_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        logger.info("Dumped %d extracted claims to %s", len(payload), out_path)
    except Exception as exc:
        logger.warning("Failed to dump extracted claims for %s: %s", entry_id, exc)


def _dataset_reference_for(entry: bschema.BenchmarkEntry):
    """Build a ``DatasetReference`` override from the catalog's dataset block.

    Returns ``None`` when the entry names no dataset source, in which case
    the pipeline falls back to extracting the dataset from the paper text.
    Imported lazily so the runner module stays importable without retally
    installed (the test harness relies on this).
    """
    dataset = getattr(entry, "dataset", None)
    if dataset is None or not dataset.source:
        return None

    from retally.models import DatasetReference, DatasetSource

    source_val = "unknown"
    for host, mapped in _DATASET_HOST_SOURCES.items():
        if host in dataset.source:
            source_val = mapped
            break
    else:
        if dataset.source.startswith("http://") or dataset.source.startswith("https://"):
            source_val = "direct_url"

    return DatasetReference(
        name=dataset.registry_key or entry.id,
        source=DatasetSource(source_val),
        url=dataset.source,
        description=dataset.access_notes,
    )


def _score_against_i4r(claim_results: list, entry: bschema.BenchmarkEntry) -> tuple[int, bool | None]:
    """Compare the reproduced values to the I4R replicator's findings.

    ``claim_results`` are the harness's own comparisons, in claim order —
    a finding's ``claim_id`` indexes into them.

    Returns ``(n_matching, all_attempted_match)``.  ``all_attempted_match``
    is None when no I4R finding has a reproduced value (nothing to
    compare against).
    """
    findings_by_claim_id = {
        f.claim_id: f for f in entry.i4r_replicator_findings if f.reproduced_value is not None
    }
    if not findings_by_claim_id:
        return 0, None

    n_match = 0
    n_attempted = 0
    for i, finding in findings_by_claim_id.items():
        if i >= len(claim_results):
            continue
        retally_value = claim_results[i].reproduced_value
        if retally_value is None:
            continue
        n_attempted += 1
        # Same tolerance the harness used for the paper-claim comparison —
        # which, in independent mode, is the SE-aware band when the claim
        # pins a standard error.  Can tighten later if the data shows it
        # should be.
        tolerance = claim_results[i].tolerance or 0.01
        if _within_tolerance(retally_value, finding.reproduced_value, tolerance):
            n_match += 1

    return n_match, (n_attempted > 0 and n_match == n_attempted)


def _within_tolerance(a: float, b: float, tol: float) -> bool:
    denom = max(abs(b), 1e-9)
    return abs(a - b) / denom <= tol


# ---------------------------------------------------------------------------
# Cache
# ---------------------------------------------------------------------------


def _cache_key(
    entry: bschema.BenchmarkEntry, mode: str = SEEDED, reproducer: str = DEFAULT_REPRODUCER
) -> str:
    """Content-addressable hash for a (catalog entry, reproduction mode, reproducer) triple.

    Includes the entry's full serialised form, the retally version, and
    the reproduction mode, so cache entries are scoped to a (paper,
    library version, mode) triple — a seeded result can never be served
    for an independent run or vice versa.  Other pipeline configuration
    is NOT in this hash because the runner uses a single default
    pipeline; if we add knobs we'll include them.

    ``split`` is deliberately excluded: it labels how a result is
    *grouped* in reports, not what gets executed, so reassigning a
    paper between dev and holdout must not invalidate its (expensive)
    cached result — ``_run_one`` re-stamps the current split on cache
    hits instead.  ``publication_date`` / ``package_release_date`` are
    excluded for the same reason: they are curation metadata for the
    contamination discussion and never reach the pipeline.

    The reproducer name joins the payload only when it is not the default
    pipeline, and the independent-mode dataset contract (a script-free
    copy, see ``benchmark.reproducer.script_free_copy``) only in
    independent and blind mode — so seeded pipeline keys, i.e. a plain
    ``make benchmark``, are byte-identical to the keys from before the
    Reproducer protocol, and existing seeded caches stay valid.
    Independent pipeline keys change once, deliberately: a result produced
    with the scripts on disk must not be served as a script-free one.
    """
    retally_version = _retally_version()
    entry_payload = _entry_to_jsonable(entry)
    for metadata_only in ("split", "publication_date", "package_release_date"):
        entry_payload.pop(metadata_only, None)
    key_payload: dict[str, Any] = {"entry": entry_payload, "retally_version": retally_version, "mode": mode}
    if reproducer != DEFAULT_REPRODUCER:
        key_payload["reproducer"] = reproducer
    if mode in SCRIPT_FREE_MODES:
        key_payload["independent_dataset"] = "script-free"
    payload = json.dumps(key_payload, sort_keys=True, default=str)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()[:16]


def _load_cache(cache_dir: Path, key: str) -> BenchmarkResult | None:
    p = cache_dir / f"{key}.json"
    if not p.exists():
        return None
    try:
        raw = json.loads(p.read_text(encoding="utf-8"))
        return _result_from_jsonable(raw)
    except (json.JSONDecodeError, OSError, KeyError, ValueError) as exc:
        logger.warning("Cache read failed for %s: %s", key, exc)
        return None


def _save_cache(cache_dir: Path, key: str, result: BenchmarkResult) -> None:
    cache_dir.mkdir(parents=True, exist_ok=True)
    (cache_dir / f"{key}.json").write_text(
        json.dumps(_result_to_jsonable(result), indent=2) + "\n",
        encoding="utf-8",
    )


# ---------------------------------------------------------------------------
# Serialisation
# ---------------------------------------------------------------------------


def _result_to_jsonable(r: BenchmarkResult) -> dict[str, Any]:
    d = asdict(r)
    if r.skip_reason is not None:
        d["skip_reason"] = r.skip_reason.value
    return d


def _result_from_jsonable(d: dict[str, Any]) -> BenchmarkResult:
    skip_reason = d.get("skip_reason")
    return BenchmarkResult(
        entry_id=d["entry_id"],
        mode=str(d.get("mode", SEEDED)),
        reproducer=str(d.get("reproducer", DEFAULT_REPRODUCER)),
        skipped=bool(d.get("skipped", False)),
        skip_reason=SkipReason(skip_reason) if skip_reason else None,
        error=d.get("error"),
        transient=bool(d.get("transient", False)),
        error_kind=d.get("error_kind") if isinstance(d.get("error_kind"), str) else None,
        retally_ran=d.get("retally_ran"),
        agrees_with_paper=d.get("agrees_with_paper"),
        agrees_with_i4r=d.get("agrees_with_i4r"),
        n_claims_in_catalog=int(d.get("n_claims_in_catalog", 0)),
        n_claims_with_paper_match=int(d.get("n_claims_with_paper_match", 0)),
        n_claims_with_i4r_match=int(d.get("n_claims_with_i4r_match", 0)),
        # Absent in files that predate first-attempt scoring.
        n_claims_with_paper_match_first_attempt=_optional_int(
            d.get("n_claims_with_paper_match_first_attempt")
        ),
        n_refinements=_optional_int(d.get("n_refinements")),
        n_executions=_optional_int(d.get("n_executions")),
        n_claims_with_paper_match_first_scored=_optional_int(d.get("n_claims_with_paper_match_first_scored")),
        first_scored_attempt_index=_optional_int(d.get("first_scored_attempt_index")),
        n_error_refinements=_optional_int(d.get("n_error_refinements")),
        n_claim_refinements=_optional_int(d.get("n_claim_refinements")),
        # Tolerant of pre-claim-detail cache files / results.json: absent
        # field → empty list, and any malformed record drops rather than
        # poisoning the whole load.
        claim_details=[ClaimDetail(**cd) for cd in d.get("claim_details", []) if isinstance(cd, dict)],
        split=str(d.get("split", "dev")),
        components=ComponentMetrics(**d.get("components", {})),
        cached=bool(d.get("cached", False)),
        # Absent in files that predate cost accounting.
        usage=d.get("usage") if isinstance(d.get("usage"), dict) else None,
        artifacts_dir=d.get("artifacts_dir") if isinstance(d.get("artifacts_dir"), str) else None,
    )


def _optional_int(x: Any) -> int | None:
    return x if isinstance(x, int) and not isinstance(x, bool) else None


def _entry_to_jsonable(entry: bschema.BenchmarkEntry) -> dict[str, Any]:
    d = asdict(entry)
    d["language"] = entry.language.value
    d["outcome_label"] = entry.outcome_label.value
    for f in d.get("i4r_replicator_findings", []):
        if isinstance(f.get("outcome"), bschema.FindingOutcome):
            f["outcome"] = f["outcome"].value
    # asdict() already converts enums on the per-finding outcome path
    # via the dataclass machinery, but be defensive: walk and stringify
    # anything that survived as an Enum.
    return _stringify_enums(d)


def _stringify_enums(obj: Any) -> Any:
    if isinstance(obj, Enum):
        return obj.value
    if isinstance(obj, dict):
        return {k: _stringify_enums(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_stringify_enums(v) for v in obj]
    return obj


def _retally_version() -> str:
    """Return the installed retally version string."""
    try:
        from importlib.metadata import version

        return version("retally")
    except Exception:
        return "unknown"


def _default_pipeline_factory():
    """Build ``ValidationPipeline.default()`` from the env-bound API key.

    Imported lazily so the runner module can be imported (and tested)
    in environments without anthropic / ANTHROPIC_API_KEY.

    The LLM call cache is ON by default for benchmark runs — iterating
    on one pipeline stage shouldn't re-pay every extraction call when
    the paper and prompts haven't changed.  Set ``RETALLY_LLM_CACHE=0``
    for a fully live run (e.g. to measure sampling variance), or
    ``rm -rf benchmark/.cache/llm`` to start the cache cold.
    """
    if not os.environ.get("ANTHROPIC_API_KEY"):
        raise MissingAPIKeyError("ANTHROPIC_API_KEY is not set")
    from retally.pipeline import ValidationPipeline

    llm_cache_dir: Path | None = CACHE_DIR / "llm"
    if os.environ.get("RETALLY_LLM_CACHE", "1") == "0":
        llm_cache_dir = None
    return ValidationPipeline.default(llm_cache_dir=llm_cache_dir)


def _pipeline_reproducer_factory(pipeline_factory: Callable[[], Any]) -> Callable[[], Reproducer]:
    """Wrap a zero-arg pipeline factory so it yields a ``PipelineReproducer``."""
    return lambda: PipelineReproducer(pipeline_factory())


def _default_pipeline_reproducer() -> Reproducer:
    """The reference reproducer: ``ValidationPipeline.default()`` behind ``PipelineReproducer``."""
    return PipelineReproducer(_default_pipeline_factory())


# ---------------------------------------------------------------------------
# Reproducer registry — the extension point
# ---------------------------------------------------------------------------

REPRODUCERS: dict[str, Callable[[], Reproducer]] = {
    DEFAULT_REPRODUCER: _default_pipeline_reproducer,
}
"""Built-in reproducers selectable by ``--reproducer NAME``: name → zero-arg
factory.  To add an agent, either register it here (one line, in this
repo) or, without editing the repo, pass ``--reproducer
package.module:factory`` — see :func:`resolve_reproducer` and "Plugging in
another agent" in ``benchmark/README.md``."""


def resolve_reproducer(spec: str) -> Callable[[], Reproducer]:
    """Turn a ``--reproducer`` value into a zero-arg reproducer factory.

    ``spec`` is a ``REPRODUCERS`` name, or ``package.module:attr`` naming
    a zero-arg callable (a factory function, or a ``Reproducer`` class
    with a no-argument constructor) importable from the current
    environment.  Raises ``ValueError`` for anything else.  The factory is
    returned uncalled: constructing an agent may need an API key, and the
    runner only does that on a cache miss.
    """
    if spec in REPRODUCERS:
        return REPRODUCERS[spec]
    module_name, sep, attr = spec.partition(":")
    if not sep or not module_name or not attr:
        raise ValueError(
            f"unknown reproducer {spec!r}: expected one of {sorted(REPRODUCERS)} "
            "or a 'package.module:factory' spec"
        )
    try:
        factory = getattr(importlib.import_module(module_name), attr)
    except (ImportError, AttributeError) as exc:
        raise ValueError(f"cannot load reproducer {spec!r}: {exc}") from exc
    if not callable(factory):
        raise ValueError(f"reproducer {spec!r} is not callable")
    return factory


if __name__ == "__main__":
    raise SystemExit(main())
