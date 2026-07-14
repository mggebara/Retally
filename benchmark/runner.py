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


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def run_benchmark(
    catalog: list[bschema.BenchmarkEntry] | None = None,
    *,
    pipeline_factory=None,
    cache_dir: Path = CACHE_DIR,
    use_cache: bool = True,
    extracted_claims_dir: Path | None = None,
) -> list[BenchmarkResult]:
    """Run every catalog entry and return one BenchmarkResult per paper.

    ``pipeline_factory`` is a zero-arg callable that returns a
    ValidationPipeline.  Injecting it (rather than always calling
    ``ValidationPipeline.default()``) keeps the runner testable
    without an API key and lets benchmark consumers swap in alternate
    pipeline configurations.  Defaults to a lambda that builds the
    standard pipeline, which requires ANTHROPIC_API_KEY to be set.

    ``extracted_claims_dir``, when set, receives one JSON file per
    executed entry containing the claims the extractor pulled from the
    paper — in a shape directly pasteable into the catalog YAML's
    ``original_claims``.  That's the pinning workflow: run once live,
    review the dump, curate it into the catalog, and every later run
    skips the extraction call and scores against a frozen claim set.
    Entries that already have pinned claims are not dumped (the file
    would just echo the catalog).  None (the default) disables dumping.
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
            extracted_claims_dir=extracted_claims_dir,
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

    results = run_benchmark(catalog, extracted_claims_dir=RESULTS_DIR / "extracted_claims")
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
    extracted_claims_dir: Path | None = None,
) -> BenchmarkResult:
    """Execute (or skip) a single catalog entry and return its result."""
    # Skip paths come first — no pipeline build, no cache check.
    skip = _check_skip(entry)
    if skip is not None:
        return BenchmarkResult(entry_id=entry.id, skipped=True, skip_reason=skip, split=entry.split)

    cache_key = _cache_key(entry)
    cached = _load_cache(cache_dir, cache_key) if use_cache else None
    if cached is not None:
        cached.cached = True
        # Split is a catalog property, not a run outcome — stamp the
        # entry's *current* assignment so moving a paper between splits
        # doesn't require invalidating its cached result.
        cached.split = entry.split
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

    result = _execute_with_pipeline(entry, pipeline, extracted_claims_dir=extracted_claims_dir)
    result.split = entry.split

    if use_cache and not result.skipped:
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


def _execute_with_pipeline(
    entry: bschema.BenchmarkEntry,
    pipeline: Any,
    *,
    extracted_claims_dir: Path | None = None,
) -> BenchmarkResult:
    """Drive ``pipeline.validate`` and translate the report into a BenchmarkResult.

    Wrapped in a broad try/except because the goal here is to score
    every paper in the catalog — a crash on one entry must not bring
    down the whole benchmark run.  The exception text is captured on
    the result so it shows up in the report.
    """
    result = BenchmarkResult(entry_id=entry.id)
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
        dataset_reference = _dataset_reference_for(entry)
        claims_override = _claims_override_for(entry)
        report = pipeline.validate(
            entry.paper.source,
            language=entry.language,
            dataset_reference=dataset_reference,
            claims=claims_override,
        )
    except Exception as exc:
        result.openra_ran = False
        result.error = f"{type(exc).__name__}: {exc}"
        logger.warning("Pipeline raised on %s: %s", entry.id, exc)
        return result

    # Dump what the extractor found so a human can curate it into the
    # catalog's original_claims (the pinning workflow).  Skipped when the
    # claims were already pinned — the dump would just echo the catalog.
    if extracted_claims_dir is not None and claims_override is None:
        _dump_extracted_claims(extracted_claims_dir, entry.id, report)

    result.openra_ran = True
    result.components = _components_from_report(report, entry)
    result.n_claims_in_catalog = len(entry.original_claims)
    result.agrees_with_paper = bool(getattr(report, "overall_passed", False))
    result.n_claims_with_paper_match = sum(1 for cr in getattr(report, "claim_results", []) if cr.passed)
    result.claim_details = [_claim_detail(cr) for cr in getattr(report, "claim_results", [])]

    # Per-claim agreement with the I4R replicator's value.
    result.n_claims_with_i4r_match, result.agrees_with_i4r = _score_against_i4r(report, entry)
    return result


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
    Imported lazily so the runner module stays importable without openra
    installed.

    Field mapping: the catalog's free-form ``claim_type`` string maps to
    the library enum, falling back to OTHER for labels the enum doesn't
    know; ``location`` ("Table 3, col 4") maps to ``table_ref``.  The
    catalog-only fields (``standard_error``, ``sample_size``) have no
    Claim counterpart yet and are dropped here — they still participate
    in I4R scoring via the entry itself.
    """
    if not entry.original_claims:
        return None

    from openra.models import Claim, ClaimType

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
            )
        )
    return claims


def _dump_extracted_claims(out_dir: Path, entry_id: str, report: Any) -> None:
    """Write the extractor's claims for one entry as catalog-ready JSON.

    Best-effort: the dump is a curation convenience, so any failure is
    logged and swallowed rather than allowed to fail the benchmark run.
    The output shape mirrors the YAML ``original_claims`` schema so a
    reviewed entry can be pasted across with minimal editing.
    """
    try:
        claims = list(getattr(getattr(report, "paper", None), "claims", []) or [])
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
    Imported lazily so the runner module stays importable without openra
    installed (the test harness relies on this).
    """
    dataset = getattr(entry, "dataset", None)
    if dataset is None or not dataset.source:
        return None

    from openra.models import DatasetReference, DatasetSource

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
        code_executed=(getattr(exec_result, "exit_code", -1) == 0 if exec_result else False),
    )


def _score_against_i4r(report: Any, entry: bschema.BenchmarkEntry) -> tuple[int, bool | None]:
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

    ``split`` is deliberately excluded: it labels how a result is
    *grouped* in reports, not what gets executed, so reassigning a
    paper between dev and holdout must not invalidate its (expensive)
    cached result — ``_run_one`` re-stamps the current split on cache
    hits instead.
    """
    openra_version = _openra_version()
    entry_payload = _entry_to_jsonable(entry)
    entry_payload.pop("split", None)
    payload = json.dumps(
        {"entry": entry_payload, "openra_version": openra_version},
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
        # Tolerant of pre-claim-detail cache files / results.json: absent
        # field → empty list, and any malformed record drops rather than
        # poisoning the whole load.
        claim_details=[ClaimDetail(**cd) for cd in d.get("claim_details", []) if isinstance(cd, dict)],
        split=str(d.get("split", "dev")),
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

    The LLM call cache is ON by default for benchmark runs — iterating
    on one pipeline stage shouldn't re-pay every extraction call when
    the paper and prompts haven't changed.  Set ``OPENRA_LLM_CACHE=0``
    for a fully live run (e.g. to measure sampling variance), or
    ``rm -rf benchmark/.cache/llm`` to start the cache cold.
    """
    if not os.environ.get("ANTHROPIC_API_KEY"):
        raise RuntimeError("ANTHROPIC_API_KEY is not set")
    from openra.pipeline import ValidationPipeline

    llm_cache_dir: Path | None = CACHE_DIR / "llm"
    if os.environ.get("OPENRA_LLM_CACHE", "1") == "0":
        llm_cache_dir = None
    return ValidationPipeline.default(llm_cache_dir=llm_cache_dir)


if __name__ == "__main__":
    raise SystemExit(main())
