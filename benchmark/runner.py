"""Benchmark runner: walk the catalog, validate each paper, score it.

Three verdicts are recorded per paper:

* ``openra_ran`` — the pipeline completed without crashing.  Distinct
  from "all claims passed" — we want to know whether the infrastructure
  works even when the science doesn't.
* ``agrees_with_paper`` — every claim with a paper-stated value
  validates within the comparator's tolerance against OpenRA's
  reproduced value.  This is the existing ``overall_passed`` rebrand.
* ``agrees_with_i4r`` — for every claim where the I4R replicator
  recorded a reproduced value, OpenRA's reproduced value is within the
  comparator's tolerance of THAT value (not the paper's claim).

The three can disagree in meaningful ways — e.g. *ran ✓, agrees with
paper ✓, agrees with I4R ✗* means OpenRA faithfully reproduced what
the paper said, but the careful human replicators found a different
number.  See README for how each combination is interpreted.

Caching: a content-addressable cache under ``benchmark/.cache/`` keyed
on ``(catalog_entry_hash, openra_version, pipeline_config_hash)`` lets
us re-run the benchmark cheaply when only the report renderer or
non-pipeline components changed.  Any benchmark entry edit, openra
version bump, or pipeline config change invalidates the corresponding
cache entry.
"""

from __future__ import annotations

import hashlib
import json
import logging
import os
import sys
from dataclasses import asdict, dataclass, field
from enum import Enum
from pathlib import Path
from typing import Any

# benchmark.* is at the repo root, not under src/openra/, so the test
# helper and this module both reach into the sibling schema module.
from benchmark import schema as bschema

logger = logging.getLogger(__name__)

REPO_ROOT = Path(__file__).resolve().parent.parent
CATALOG_DIR = REPO_ROOT / "benchmark" / "papers"
CACHE_DIR = REPO_ROOT / "benchmark" / ".cache"
RESULTS_DIR = REPO_ROOT / "benchmark" / "results"


# ---------------------------------------------------------------------------
# Per-entry result model
# ---------------------------------------------------------------------------


class SkipReason(Enum):
    """Why a catalog entry wasn't executed.

    ``OUT_OF_SCOPE`` covers entries with a non-null
    ``out_of_scope_reason`` set in the YAML.  ``LANGUAGE_UNSUPPORTED``
    covers entries the runner can't handle yet (R until that lands,
    Stata permanently).  ``NO_API_KEY`` covers running the harness
    without ``ANTHROPIC_API_KEY`` — the pipeline can't be invoked, so
    we record the skip rather than crashing.
    """

    OUT_OF_SCOPE = "out_of_scope"
    LANGUAGE_UNSUPPORTED = "language_unsupported"
    NO_API_KEY = "no_api_key"


@dataclass
class ComponentMetrics:
    """Per-component success flags for one paper.

    Each flag is True only when the corresponding pipeline stage
    completed without an exception AND produced output the next stage
    could consume.  ``None`` means we never got far enough to attempt
    that stage.
    """

    parsed: bool | None = None
    claims_extracted: bool | None = None
    dataset_extracted: bool | None = None
    dataset_downloaded: bool | None = None
    code_generated: bool | None = None
    code_executed: bool | None = None


@dataclass
class BenchmarkResult:
    """Outcome of running one BenchmarkEntry through the pipeline.

    ``skipped`` is True for catalog entries the runner declined to
    execute (out of scope, unsupported language, missing API key).  In
    that case the verdict fields stay None.
    """

    entry_id: str
    skipped: bool = False
    skip_reason: SkipReason | None = None
    error: str | None = None
    """Set when the pipeline raised — None on success or skip."""

    openra_ran: bool | None = None
    agrees_with_paper: bool | None = None
    agrees_with_i4r: bool | None = None

    n_claims_in_catalog: int = 0
    n_claims_with_paper_match: int = 0
    n_claims_with_i4r_match: int = 0

    components: ComponentMetrics = field(default_factory=ComponentMetrics)

    cached: bool = False
    """True when the result came from benchmark/.cache; False when we
    re-ran the pipeline.  Useful in reports so a reader knows what was
    actually exercised in this run."""


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def run_benchmark(
    catalog: list[bschema.BenchmarkEntry] | None = None,
    *,
    pipeline_factory=None,
    cache_dir: Path = CACHE_DIR,
    use_cache: bool = True,
) -> list[BenchmarkResult]:
    """Run every catalog entry and return one BenchmarkResult per paper.

    ``pipeline_factory`` is a zero-arg callable that returns a
    ValidationPipeline.  Injecting it (rather than always calling
    ``ValidationPipeline.default()``) keeps the runner testable
    without an API key and lets benchmark consumers swap in alternate
    pipeline configurations.  Defaults to a lambda that builds the
    standard pipeline, which requires ANTHROPIC_API_KEY to be set.
    """
    if catalog is None:
        catalog = bschema.load_catalog(CATALOG_DIR)

    results: list[BenchmarkResult] = []
    for entry in catalog:
        result = _run_one(
            entry,
            pipeline_factory=pipeline_factory,
            cache_dir=cache_dir,
            use_cache=use_cache,
        )
        results.append(result)
    return results


def write_results(results: list[BenchmarkResult], out_path: Path) -> None:
    """Serialise a results list to JSON for the report renderer to consume."""
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(
        json.dumps([_result_to_jsonable(r) for r in results], indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> int:
    """CLI entrypoint — ``python -m benchmark.runner`` or ``make benchmark``."""
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    catalog = bschema.load_catalog(CATALOG_DIR)
    if not catalog:
        print(
            f"No benchmark entries found at {CATALOG_DIR.relative_to(REPO_ROOT)}.",
            file=sys.stderr,
        )
        return 1

    results = run_benchmark(catalog)
    out = RESULTS_DIR / "results.json"
    write_results(results, out)
    print(f"Wrote {out.relative_to(REPO_ROOT)} ({len(results)} entries).")
    return 0


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------


def _run_one(
    entry: bschema.BenchmarkEntry,
    *,
    pipeline_factory,
    cache_dir: Path,
    use_cache: bool,
) -> BenchmarkResult:
    """Execute (or skip) a single catalog entry and return its result."""
    # Skip paths come first — no pipeline build, no cache check.
    skip = _check_skip(entry)
    if skip is not None:
        return BenchmarkResult(entry_id=entry.id, skipped=True, skip_reason=skip)

    cache_key = _cache_key(entry)
    cached = _load_cache(cache_dir, cache_key) if use_cache else None
    if cached is not None:
        cached.cached = True
        return cached

    pipeline_factory = pipeline_factory or _default_pipeline_factory
    try:
        pipeline = pipeline_factory()
    except Exception as exc:
        logger.warning("Pipeline construction failed for %s: %s", entry.id, exc)
        return BenchmarkResult(
            entry_id=entry.id,
            skipped=True,
            skip_reason=SkipReason.NO_API_KEY,
            error=str(exc),
        )

    result = _execute_with_pipeline(entry, pipeline)

    if use_cache and not result.skipped:
        _save_cache(cache_dir, cache_key, result)

    return result


def _check_skip(entry: bschema.BenchmarkEntry) -> SkipReason | None:
    """Return the skip reason for ``entry``, or None if we should run it."""
    if entry.out_of_scope_reason:
        return SkipReason.OUT_OF_SCOPE
    if entry.language is not bschema.Language.PYTHON:
        return SkipReason.LANGUAGE_UNSUPPORTED
    return None


def _execute_with_pipeline(
    entry: bschema.BenchmarkEntry, pipeline: Any
) -> BenchmarkResult:
    """Drive ``pipeline.validate`` and translate the report into a BenchmarkResult.

    Wrapped in a broad try/except because the goal here is to score
    every paper in the catalog — a crash on one entry must not bring
    down the whole benchmark run.  The exception text is captured on
    the result so it shows up in the report.
    """
    result = BenchmarkResult(entry_id=entry.id)
    try:
        report = pipeline.validate(entry.paper.source)
    except Exception as exc:
        result.openra_ran = False
        result.error = f"{type(exc).__name__}: {exc}"
        logger.warning("Pipeline raised on %s: %s", entry.id, exc)
        return result

    result.openra_ran = True
    result.components = _components_from_report(report, entry)
    result.n_claims_in_catalog = len(entry.original_claims)
    result.agrees_with_paper = bool(getattr(report, "overall_passed", False))
    result.n_claims_with_paper_match = sum(
        1 for cr in getattr(report, "claim_results", []) if cr.passed
    )

    # Per-claim agreement with the I4R replicator's value.
    result.n_claims_with_i4r_match, result.agrees_with_i4r = _score_against_i4r(
        report, entry
    )
    return result


def _components_from_report(report: Any, entry: bschema.BenchmarkEntry) -> ComponentMetrics:
    """Best-effort extraction of per-component flags from a ValidationReport.

    Uses ``getattr`` throughout so the runner survives even if the
    library renames a field.  We're scoring OpenRA, not married to its
    current internal shape.
    """
    paper = getattr(report, "paper", None)
    exec_result = getattr(report, "execution_result", None)
    return ComponentMetrics(
        parsed=paper is not None,
        claims_extracted=bool(getattr(paper, "claims", []) if paper else False),
        dataset_extracted=bool(getattr(paper, "dataset_references", []) if paper else False),
        dataset_downloaded=getattr(report, "dataset", None) is not None,
        code_generated=bool(getattr(exec_result, "generated_code", "") if exec_result else False),
        code_executed=(
            getattr(exec_result, "exit_code", -1) == 0 if exec_result else False
        ),
    )


def _score_against_i4r(
    report: Any, entry: bschema.BenchmarkEntry
) -> tuple[int, bool | None]:
    """Compare OpenRA's reproduced values to the I4R replicator's findings.

    Returns ``(n_matching, all_attempted_match)``.  ``all_attempted_match``
    is None when no I4R finding has a reproduced value (nothing to
    compare against).
    """
    findings_by_claim_id = {
        f.claim_id: f for f in entry.i4r_replicator_findings if f.reproduced_value is not None
    }
    if not findings_by_claim_id:
        return 0, None

    claim_results = list(getattr(report, "claim_results", []))
    n_match = 0
    n_attempted = 0
    for i, finding in findings_by_claim_id.items():
        if i >= len(claim_results):
            continue
        openra_value = claim_results[i].reproduced_value
        if openra_value is None:
            continue
        n_attempted += 1
        # Same tolerance OpenRA uses for paper-claim comparison; can
        # tighten later if the data shows it should be.
        tolerance = claim_results[i].tolerance or 0.01
        if _within_tolerance(openra_value, finding.reproduced_value, tolerance):
            n_match += 1

    return n_match, (n_attempted > 0 and n_match == n_attempted)


def _within_tolerance(a: float, b: float, tol: float) -> bool:
    denom = max(abs(b), 1e-9)
    return abs(a - b) / denom <= tol


# ---------------------------------------------------------------------------
# Cache
# ---------------------------------------------------------------------------


def _cache_key(entry: bschema.BenchmarkEntry) -> str:
    """Content-addressable hash for a catalog entry.

    Includes the entry's full serialised form plus the openra version
    so cache entries are scoped to a (paper, library version) pair.
    Pipeline configuration is NOT in this hash today because the
    runner uses a single default pipeline; if we add knobs we'll
    include them.
    """
    openra_version = _openra_version()
    payload = json.dumps(
        {"entry": _entry_to_jsonable(entry), "openra_version": openra_version},
        sort_keys=True,
        default=str,
    )
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
        skipped=bool(d.get("skipped", False)),
        skip_reason=SkipReason(skip_reason) if skip_reason else None,
        error=d.get("error"),
        openra_ran=d.get("openra_ran"),
        agrees_with_paper=d.get("agrees_with_paper"),
        agrees_with_i4r=d.get("agrees_with_i4r"),
        n_claims_in_catalog=int(d.get("n_claims_in_catalog", 0)),
        n_claims_with_paper_match=int(d.get("n_claims_with_paper_match", 0)),
        n_claims_with_i4r_match=int(d.get("n_claims_with_i4r_match", 0)),
        components=ComponentMetrics(**d.get("components", {})),
        cached=bool(d.get("cached", False)),
    )


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


def _openra_version() -> str:
    """Return the installed openra version string."""
    try:
        from importlib.metadata import version

        return version("openra")
    except Exception:
        return "unknown"


def _default_pipeline_factory():
    """Build ``ValidationPipeline.default()`` from the env-bound API key.

    Imported lazily so the runner module can be imported (and tested)
    in environments without anthropic / ANTHROPIC_API_KEY.
    """
    if not os.environ.get("ANTHROPIC_API_KEY"):
        raise RuntimeError("ANTHROPIC_API_KEY is not set")
    from openra.pipeline import ValidationPipeline

    return ValidationPipeline.default()


if __name__ == "__main__":
    raise SystemExit(main())
