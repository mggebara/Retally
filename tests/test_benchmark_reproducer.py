"""Tests for the agent protocol (benchmark/reproducer.py) and harness-side scoring.

Three concerns:

* **Unchanged verdicts.**  Re-scoring the committed seeded baseline's raw
  values through the harness reproduces every recorded verdict — moving
  scoring out of the pipeline did not move the pipeline's numbers.
* **Conformance.**  The reference pipeline (real components, fake LLM)
  and a minimal fake reproducer go through the same harness path and
  are scored identically; a reproducer's own verdicts are never read.
* **Extension point.**  ``--reproducer`` resolves built-in names and
  ``module:attr`` specs; the result cache keys on the reproducer without
  disturbing the default pipeline's seeded keys.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from unittest.mock import MagicMock

import pytest

from retally.codegen.executor import CodeExecutor
from retally.codegen.generator import CodeGenerator
from retally.models import (
    Claim,
    ClaimType,
    ClaimValidationResult,
    Dataset,
    ExecutionResult,
    Language,
    Paper,
    ReproductionMode,
    ValidationReport,
)
from retally.paper.extractor import ClaimExtractor
from retally.paper.parser import PaperParser
from retally.pipeline import ValidationPipeline
from retally.validation.comparator import ResultComparator
from retally.validation.reporter import ValidationReporter
from tests._loaders import REPO_ROOT, load_module_from_path

bschema = load_module_from_path("benchmark.schema", REPO_ROOT / "benchmark" / "schema.py")
reproducer_mod = load_module_from_path("benchmark.reproducer", REPO_ROOT / "benchmark" / "reproducer.py")
runner = load_module_from_path("benchmark.runner", REPO_ROOT / "benchmark" / "runner.py")

Reproduction = reproducer_mod.Reproduction
PipelineReproducer = reproducer_mod.PipelineReproducer


# ── Helpers ─────────────────────────────────────────────────────────────


def _entry(**overrides):
    base = {
        "id": "test",
        "i4r_report_url": "https://example.org/r",
        "language": bschema.Language.PYTHON,
        "outcome_label": bschema.OutcomeLabel.REPRODUCIBLE,
        "paper": bschema.PaperRef(source="raw paper text"),
        "original_claims": [
            bschema.OriginalClaim(
                description="beta", value=0.5, claim_type="coefficient", standard_error=0.1
            ),
            bschema.OriginalClaim(description="n_obs", value=660, claim_type="other"),
        ],
        "i4r_replicator_findings": [
            bschema.ReplicatorFinding(
                claim_id=0, reproduced_value=0.5, outcome=bschema.FindingOutcome.MATCHES
            )
        ],
    }
    base.update(overrides)
    return bschema.BenchmarkEntry(**base)


class FakeReproducer:
    """The smallest possible conforming agent: returns canned outputs."""

    name = "fake"

    def __init__(self, outputs: dict[str, float]) -> None:
        self.outputs = outputs
        self.calls: list[dict] = []

    def reproduce(self, paper_source, *, language, dataset_reference, claims, reproduction_mode):
        self.calls.append(
            {
                "paper_source": paper_source,
                "language": language,
                "dataset_reference": dataset_reference,
                "claims": claims,
                "reproduction_mode": reproduction_mode,
            }
        )
        return Reproduction(
            outputs=dict(self.outputs),
            claims=list(claims or []),
            generated_code="print(1)",
            exit_code=0,
            stages=reproducer_mod.ComponentMetrics(code_generated=True, code_executed=True),
        )


def make_fake_reproducer():
    """Module-level factory, so a ``module:attr`` --reproducer spec can resolve it."""
    return FakeReproducer({"beta": 0.5, "n_obs": 660.0})


def _verdicts(result):
    return (
        result.retally_ran,
        result.agrees_with_paper,
        result.agrees_with_i4r,
        result.n_claims_with_paper_match,
        result.n_claims_with_i4r_match,
        [(cd.description, cd.reproduced, cd.tolerance, cd.passed) for cd in result.claim_details],
    )


# ── The committed baseline re-scores to its recorded verdicts ──────────


BASELINE = REPO_ROOT / "benchmark" / "results" / "baseline-2026-10-19.json"


def test_committed_seeded_baseline_rescores_identically():
    """Feed the baseline's raw reproduced values through the harness scorer.

    ``baseline-2026-10-19.json`` was scored by the pipeline's own
    comparator, before scoring moved into the harness.  Reconstructing the
    reproducer's raw outputs from its claim details and scoring them via
    ``score_reproduction`` must give back the identical per-claim
    pass/fail, tolerance and relative error, and the identical paper and
    I4R verdicts — the proof that the move did not change the pipeline's
    numbers.
    """
    [recorded] = json.loads(BASELINE.read_text(encoding="utf-8"))
    entry = {e.id: e for e in bschema.load_catalog(runner.CATALOG_DIR)}[recorded["entry_id"]]
    mode = recorded.get("mode", "seeded")
    outputs = {
        cd["description"]: cd["reproduced"]
        for cd in recorded["claim_details"]
        if cd["reproduced"] is not None
    }

    scored = runner.score_reproduction(entry, Reproduction(outputs=outputs), mode=mode)

    assert len(scored.claim_details) == len(recorded["claim_details"]) == 13
    for got, want in zip(scored.claim_details, recorded["claim_details"], strict=True):
        assert got.description == want["description"]
        assert got.claimed == want["claimed"]
        assert got.reproduced == want["reproduced"]
        assert got.tolerance == pytest.approx(want["tolerance"])
        assert got.rel_err == pytest.approx(want["rel_err"])
        assert got.passed is want["passed"]
    assert scored.agrees_with_paper is recorded["agrees_with_paper"] is True
    assert scored.agrees_with_i4r is recorded["agrees_with_i4r"] is True
    assert scored.n_claims_with_paper_match == recorded["n_claims_with_paper_match"]
    assert scored.n_claims_with_i4r_match == recorded["n_claims_with_i4r_match"]
    assert scored.n_claims_in_catalog == recorded["n_claims_in_catalog"]


def test_harness_rescoring_matches_the_pipelines_own_comparison():
    """For any outputs, the harness's verdict equals what the pipeline's
    default comparator computes internally — same claims, same outputs,
    same ``ResultComparator`` — including near-miss and unmatched claims."""
    entry = _entry()
    claims = runner._claims_override_for(entry)
    for outputs in ({"beta": 0.5, "n_obs": 660.0}, {"beta": 0.57, "n_obs": 661.0}, {"beta": 0.65}, {}):
        for mode in ("seeded", "independent"):
            internal = ResultComparator().compare_all(claims, outputs, mode=ReproductionMode(mode))
            scored = runner.score_reproduction(entry, Reproduction(outputs=outputs), mode=mode)
            assert [cd.passed for cd in scored.claim_details] == [cr.passed for cr in internal]
            assert [cd.tolerance for cd in scored.claim_details] == [cr.tolerance for cr in internal]
            assert scored.agrees_with_paper is (bool(internal) and all(cr.passed for cr in internal))


def test_independent_mode_scores_with_the_se_band():
    """0.57 vs 0.5 is 14 % off: a seeded fail, but inside ±1·SE (SE 0.1) independently."""
    entry = _entry()
    outputs = {"beta": 0.57, "n_obs": 660.0}
    seeded = runner.score_reproduction(entry, Reproduction(outputs=outputs), mode="seeded")
    independent = runner.score_reproduction(entry, Reproduction(outputs=outputs), mode="independent")
    assert seeded.claim_details[0].passed is False
    assert independent.claim_details[0].passed is True
    assert independent.agrees_with_paper is True


def test_pinned_claims_override_what_the_reproducer_says_it_targeted():
    """An agent cannot shrink the exam by reporting a smaller claim set."""
    entry = _entry()
    rep = Reproduction(outputs={"beta": 0.5}, claims=[Claim(description="beta", value=0.5)])
    scored = runner.score_reproduction(entry, rep)
    assert [cd.description for cd in scored.claim_details] == ["beta", "n_obs"]
    assert scored.agrees_with_paper is False


def test_unpinned_entry_is_scored_against_the_reproducers_claims():
    entry = _entry(original_claims=[], i4r_replicator_findings=[])
    rep = Reproduction(outputs={"acc": 0.9}, claims=[Claim(description="acc", value=0.9)])
    scored = runner.score_reproduction(entry, rep)
    assert scored.agrees_with_paper is True
    assert scored.n_claims_in_catalog == 0


def test_no_claims_is_not_a_pass():
    entry = _entry(original_claims=[], i4r_replicator_findings=[])
    assert runner.score_reproduction(entry, Reproduction(outputs={"x": 1.0})).agrees_with_paper is False


# ── Conformance: reference pipeline and a fake, one harness path ───────


class _FakeLLM:
    """Stands in for the Anthropic client: routes on prompt content, records prompts."""

    def __init__(self, code: str) -> None:
        self.code = code
        self.prompts: list[str] = []
        self.messages = self

    def create(self, *, messages, **_kwargs):
        prompt = messages[0]["content"]
        self.prompts.append(prompt)
        if "Now write the complete Python script" in prompt:
            text = self.code
        elif "Summarize the experimental methodology" in prompt:
            text = "- OLS of y on beta."
        else:
            text = "[]"
        response = MagicMock()
        response.content = [MagicMock(text=text)]
        return response


def _real_pipeline(code: str, dataset_dir: Path, executor=None):
    """A ValidationPipeline built from real components; only the LLM and the download are faked."""
    llm = _FakeLLM(code)
    downloader = MagicMock()
    downloader.download.side_effect = lambda ref: Dataset(
        name="d", source_url=ref.url or "", local_path=dataset_dir
    )
    pipeline = ValidationPipeline(
        parser=PaperParser(),
        extractor=ClaimExtractor(llm),
        downloader=downloader,
        registry=MagicMock(),
        generator=CodeGenerator(llm),
        executor=executor or CodeExecutor(timeout=60),
        comparator=ResultComparator(),
        reporter=ValidationReporter(),
        include_code_references=False,
    )
    return pipeline, llm


def _dataset_entry(**overrides):
    return _entry(dataset=bschema.DatasetRef(source="https://example.org/data.zip"), **overrides)


@pytest.mark.parametrize("mode", ["seeded", "independent"])
def test_reference_pipeline_and_fake_are_scored_identically(tmp_path, mode):
    data = tmp_path / "data"
    data.mkdir()
    (data / "data.csv").write_text("y,x\n1,2\n", encoding="utf-8")
    code = "print('RESULT:beta=0.5')\nprint('RESULT:n_obs=661')\n"
    pipeline, _ = _real_pipeline(code, data)

    [via_pipeline] = runner.run_benchmark(
        [_dataset_entry()], pipeline_factory=lambda: pipeline, cache_dir=tmp_path / "c1", modes=(mode,)
    )
    fake = FakeReproducer({"beta": 0.5, "n_obs": 661.0})
    [via_fake] = runner.run_benchmark(
        [_dataset_entry()],
        reproducer="fake",
        reproducer_factory=lambda: fake,
        cache_dir=tmp_path / "c2",
        modes=(mode,),
    )

    assert via_pipeline.error is None
    assert _verdicts(via_pipeline) == _verdicts(via_fake)
    # n_obs = 661 vs 660 is 0.15 %: inside OTHER's 1 % — both pass.
    assert via_pipeline.agrees_with_paper is True
    assert via_pipeline.agrees_with_i4r is True
    assert via_pipeline.reproducer == "pipeline"
    assert via_fake.reproducer == "fake"
    assert via_pipeline.components.code_executed is True
    # The fake received exactly the catalog-derived inputs.
    [call] = fake.calls
    assert call["language"] is Language.PYTHON
    assert call["reproduction_mode"] is ReproductionMode(mode)
    assert [c.description for c in call["claims"]] == ["beta", "n_obs"]
    assert call["dataset_reference"].url == "https://example.org/data.zip"


def test_reproducers_own_verdict_is_never_read(tmp_path):
    """A pipeline report claiming success with off-target outputs is scored a failure."""
    beta = Claim(description="beta", value=0.5, claim_type=ClaimType.COEFFICIENT)
    lying = ValidationReport(
        paper=Paper(title="t", claims=[beta]),
        dataset=Dataset(name="d", source_url="", local_path=tmp_path),
        execution_result=ExecutionResult(generated_code="x", exit_code=0, outputs={"beta": 9.0}),
        claim_results=[ClaimValidationResult(claim=beta, reproduced_value=0.5, passed=True)],
        overall_passed=True,
    )
    pipeline = MagicMock()
    pipeline.validate.return_value = lying
    [result] = runner.run_benchmark([_entry()], pipeline_factory=lambda: pipeline, cache_dir=tmp_path)
    assert result.agrees_with_paper is False
    assert result.claim_details[0].reproduced == 9.0
    assert result.agrees_with_i4r is False


def test_reproducer_that_raises_is_recorded(tmp_path):
    class Boom:
        def reproduce(self, *a, **k):
            raise RuntimeError("agent fell over")

    [result] = runner.run_benchmark(
        [_entry()], reproducer="boom", reproducer_factory=Boom, cache_dir=tmp_path
    )
    assert result.retally_ran is False
    assert "agent fell over" in (result.error or "")
    assert result.reproducer == "boom"


def test_protocol_conformance():
    assert isinstance(PipelineReproducer(MagicMock()), reproducer_mod.Reproducer)
    assert isinstance(make_fake_reproducer(), reproducer_mod.Reproducer)


def test_reproduction_from_report_carries_the_artefacts():
    report = ValidationReport(
        paper=Paper(title="t", claims=[Claim(description="b", value=1.0)]),
        dataset=Dataset(name="d", source_url="", local_path=Path("/tmp/d")),
        execution_result=ExecutionResult(
            generated_code="code",
            stdout="RESULT:b=1\nDEVIATION:used HC1",
            stderr="warn",
            exit_code=0,
            outputs={"b": 1.0},
            deviation_notes=["used HC1"],
        ),
        claim_results=[],
        overall_passed=False,
    )
    rep = reproducer_mod.reproduction_from_report(report)
    assert rep.outputs == {"b": 1.0}
    assert [c.description for c in rep.claims] == ["b"]
    assert (rep.generated_code, rep.stdout, rep.stderr, rep.exit_code) == (
        "code",
        "RESULT:b=1\nDEVIATION:used HC1",
        "warn",
        0,
    )
    assert rep.deviations == ["used HC1"]
    assert rep.stages.code_generated is True and rep.stages.code_executed is True


# ── Extension point: --reproducer and the registry ─────────────────────


def test_resolve_builtin_and_module_spec():
    assert runner.resolve_reproducer("pipeline") is runner.REPRODUCERS["pipeline"]
    factory = runner.resolve_reproducer("tests.test_benchmark_reproducer:make_fake_reproducer")
    assert isinstance(factory(), reproducer_mod.Reproducer)


@pytest.mark.parametrize("spec", ["claude-code", "no.such.module:x", "tests.test_benchmark_reproducer:nope"])
def test_resolve_rejects_unknown(spec):
    with pytest.raises(ValueError):
        runner.resolve_reproducer(spec)


def test_run_benchmark_resolves_a_module_spec(tmp_path):
    spec = "tests.test_benchmark_reproducer:make_fake_reproducer"
    [result] = runner.run_benchmark([_entry()], reproducer=spec, cache_dir=tmp_path)
    assert result.reproducer == spec
    assert result.agrees_with_paper is True


def test_main_rejects_unknown_reproducer(capsys):
    assert runner.main(["--reproducer", "claude-code"]) == 2
    assert "unknown reproducer" in capsys.readouterr().err


def test_main_passes_reproducer_through(tmp_path, monkeypatch):
    seen = {}

    def fake_run_benchmark(catalog, **kwargs):
        seen.update(kwargs)
        return []

    monkeypatch.setattr(runner, "CATALOG_DIR", REPO_ROOT / "tests" / "fixtures" / "benchmark_placeholders")
    monkeypatch.setattr(runner, "RESULTS_DIR", tmp_path)
    monkeypatch.setattr(runner, "REPO_ROOT", tmp_path.parent)
    monkeypatch.setattr(runner, "run_benchmark", fake_run_benchmark)
    assert runner.main([]) == 0
    assert seen["reproducer"] == "pipeline"


def test_both_factories_is_an_error(tmp_path):
    with pytest.raises(ValueError, match="not both"):
        runner.run_benchmark(
            [_entry()],
            pipeline_factory=MagicMock,
            reproducer_factory=make_fake_reproducer,
            cache_dir=tmp_path,
        )


def _pre_protocol_cache_key(entry, mode):
    """The cache-key formula before the Reproducer protocol, verbatim."""
    entry_payload = runner._entry_to_jsonable(entry)
    for metadata_only in ("split", "publication_date", "package_release_date"):
        entry_payload.pop(metadata_only, None)
    payload = json.dumps(
        {"entry": entry_payload, "retally_version": runner._retally_version(), "mode": mode},
        sort_keys=True,
        default=str,
    )
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()[:16]


def test_pipeline_cache_keys_are_unchanged():
    """A plain ``make benchmark`` keeps hitting the caches it wrote before this change."""
    entry = _entry()
    for mode in ("seeded", "independent"):
        assert runner._cache_key(entry, mode) == _pre_protocol_cache_key(entry, mode)
        assert runner._cache_key(entry, mode, "pipeline") == _pre_protocol_cache_key(entry, mode)


def test_cache_key_includes_reproducer():
    entry = _entry()
    for mode in ("seeded", "independent"):
        assert runner._cache_key(entry, mode, "pipeline") != runner._cache_key(entry, mode, "fake")


def test_cache_never_serves_one_reproducers_result_to_another(tmp_path):
    runner.run_benchmark(
        [_entry()], reproducer="a", reproducer_factory=make_fake_reproducer, cache_dir=tmp_path
    )
    [other] = runner.run_benchmark(
        [_entry()], reproducer="b", reproducer_factory=make_fake_reproducer, cache_dir=tmp_path
    )
    assert other.cached is False
    [again] = runner.run_benchmark(
        [_entry()], reproducer="a", reproducer_factory=make_fake_reproducer, cache_dir=tmp_path
    )
    assert again.cached is True and again.reproducer == "a"


def test_reproducer_round_trips_and_defaults_to_pipeline():
    d = runner._result_to_jsonable(runner.BenchmarkResult(entry_id="x", reproducer="fake"))
    assert d["reproducer"] == "fake"
    assert runner._result_from_jsonable(d).reproducer == "fake"
    assert runner._result_from_jsonable({"entry_id": "old"}).reproducer == "pipeline"
