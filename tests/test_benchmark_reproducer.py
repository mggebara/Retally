"""Tests for the agent protocol (benchmark/reproducer.py) and harness-side scoring.

Four concerns:

* **Unchanged verdicts.**  Re-scoring the committed seeded baseline's raw
  values through the harness reproduces every recorded verdict — moving
  scoring out of the pipeline did not move the pipeline's numbers.
* **Conformance.**  The reference pipeline (real components, fake LLM)
  and a minimal fake reproducer go through the same harness path and
  are scored identically; a reproducer's own verdicts are never read.
* **Independent-mode integrity.**  In independent mode the pipeline's
  sandbox and prompt see a script-free copy of the dataset.
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
    DatasetReference,
    DatasetSource,
    ExecutionResult,
    Language,
    Paper,
    RefinementAttempt,
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
load_module_from_path("benchmark.pricing", REPO_ROOT / "benchmark" / "pricing.py")
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


BOTH_BASELINE = REPO_ROOT / "benchmark" / "results" / "baseline-both-2026-10-19.json"

# Raw RESULT outputs of the independent row of ``baseline-both-2026-10-19.json``,
# recovered by replaying that run's generation from the LLM cache (no live
# calls; the replay re-scored to the identical verdicts).  The three IV
# coefficient claims and three IV SE claims have no RESULT line (the code
# printed ``=NA``); ``results.json`` stores only the per-claim values, in
# which the old claim-type fallback had put the OLS -0.181 on the IV
# coefficients.
BOTH_BASELINE_INDEPENDENT_OUTPUTS = {
    "warfare_coefficient_bivariate": -0.181,
    "warfare_se_bivariate": 0.0507,
    "warfare_coefficient_state_fe": -0.181,
    "warfare_se_state_fe": 0.0507,
    "warfare_coefficient_full_controls": -0.2957,
    "warfare_se_full_controls": 0.1045,
    "sample_size_districts": 631.0,
}


def test_both_mode_baseline_rescores_without_borrowed_values():
    """Seeded row of the both-mode baseline still re-scores 13/13; the
    independent row's IV coefficients become unmatched (10 -> 7 matched),
    still 0/13 passed."""
    seeded, independent = json.loads(BOTH_BASELINE.read_text(encoding="utf-8"))
    entry = {e.id: e for e in bschema.load_catalog(runner.CATALOG_DIR)}[seeded["entry_id"]]

    outputs = {cd["description"]: cd["reproduced"] for cd in seeded["claim_details"]}
    scored = runner.score_reproduction(entry, Reproduction(outputs=outputs), mode="seeded")
    assert scored.n_claims_with_paper_match == 13
    assert [cd.passed for cd in scored.claim_details] == [cd["passed"] for cd in seeded["claim_details"]]

    recorded_matched = sum(cd["reproduced"] is not None for cd in independent["claim_details"])
    assert recorded_matched == 10
    scored = runner.score_reproduction(
        entry, Reproduction(outputs=BOTH_BASELINE_INDEPENDENT_OUTPUTS), mode="independent"
    )
    by_name = {cd.description: cd for cd in scored.claim_details}
    assert sum(cd.reproduced is not None for cd in scored.claim_details) == 7
    for name in ("bivariate", "state_fe", "full_controls"):
        assert by_name[f"warfare_iv_coefficient_{name}"].reproduced is None
    assert scored.n_claims_with_paper_match == 0
    # Every claim that did have a RESULT line keeps its recorded value.
    for cd in independent["claim_details"]:
        if cd["description"] in BOTH_BASELINE_INDEPENDENT_OUTPUTS:
            assert by_name[cd["description"]].reproduced == cd["reproduced"]


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


@pytest.mark.parametrize(("mode", "claim_refined"), [("independent", True), ("blind", False)])
def test_blind_run_end_to_end_never_shows_a_target(tmp_path, mode, claim_refined):
    """Real pipeline, off-target script: independent mode feeds the gap back
    ("paper claims 0.5"), blind mode never does, and blind's first-scored
    count equals its final count (no claim refinement ran after it)."""
    data = tmp_path / "data"
    data.mkdir()
    (data / "data.csv").write_text("y,x\n1,2\n", encoding="utf-8")
    pipeline, llm = _real_pipeline("print('RESULT:beta=0.75')\nprint('RESULT:n_obs=701')\n", data)

    [row] = runner.run_benchmark(
        [_dataset_entry()], pipeline_factory=lambda: pipeline, cache_dir=tmp_path / "c", modes=(mode,)
    )

    assert row.mode == mode
    assert row.agrees_with_paper is False
    claim_prompts = [p for p in llm.prompts if "paper claims" in p]
    assert bool(claim_prompts) is claim_refined
    if mode == "blind":
        generation = [p for p in llm.prompts if "Now write the complete Python script" in p]
        assert len(generation) == 1
        assert all("beta: 0.5" not in p and "660" not in p for p in llm.prompts)
        assert row.n_claims_with_paper_match_first_scored == row.n_claims_with_paper_match


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


# ── Independent-mode integrity: a script-free dataset ──────────────────


def _package(root: Path) -> Path:
    """A miniature replication package: data plus every kind of script."""
    (root / "code" / "sub").mkdir(parents=True)
    (root / "data").mkdir()
    (root / "data" / "panel.dta").write_bytes(b"\x00data")
    (root / "data" / "panel.csv").write_text("a,b\n1,2\n", encoding="utf-8")
    (root / "README.pdf").write_bytes(b"%PDF")
    for rel in ("master.do", "code/helper.ado", "code/Analysis.R", "code/sub/tables.Rmd", "code/run.log"):
        (root / rel).write_text("reg y x\n", encoding="utf-8")
    return root


def _files(root: Path) -> set[str]:
    return {str(p.relative_to(root)) for p in root.rglob("*") if p.is_file()}


def test_script_free_copy_drops_scripts_and_keeps_data(tmp_path):
    src = _package(tmp_path / "pkg")
    dest = reproducer_mod.script_free_copy(src, tmp_path / "out")
    assert _files(dest) == {"data/panel.dta", "data/panel.csv", "README.pdf"}
    assert (dest / "data" / "panel.csv").read_text(encoding="utf-8") == "a,b\n1,2\n"
    # The original is untouched.
    assert "master.do" in _files(src)


def test_script_free_copy_drops_transcripts_without_a_script_suffix(tmp_path):
    """.Rhistory, .Rout and log_*.txt console sessions carry the code too."""
    src = _package(tmp_path / "pkg")
    for rel in (".Rhistory", "code/.Rhistory", "code/run.Rout", "log_analysis.txt", "Log-session2.TXT"):
        (src / rel).parent.mkdir(parents=True, exist_ok=True)
        (src / rel).write_text("lm(y ~ x)\n", encoding="utf-8")
    # Plain text that is not a console log stays, as do result tables.
    (src / "notes.txt").write_text("codebook\n", encoding="utf-8")
    (src / "table1.tex").write_text("3.713\n", encoding="utf-8")
    dest = reproducer_mod.script_free_copy(src, tmp_path / "out")
    assert _files(dest) == {"data/panel.dta", "data/panel.csv", "README.pdf", "notes.txt", "table1.tex"}


def test_script_free_copy_rebuilds_the_destination(tmp_path):
    src = _package(tmp_path / "pkg")
    dest = tmp_path / "out"
    reproducer_mod.script_free_copy(src, dest)
    (dest / "stale.do").write_text("leftover", encoding="utf-8")
    reproducer_mod.script_free_copy(src, dest)
    assert "stale.do" not in _files(dest)


def test_script_free_dataset_is_a_no_op_without_scripts(tmp_path):
    (tmp_path / "data.csv").write_text("a\n1\n", encoding="utf-8")
    ds = Dataset(name="d", source_url="", local_path=tmp_path)
    assert reproducer_mod.script_free_dataset(ds) is ds


def test_script_free_dataset_uses_a_deterministic_sibling(tmp_path):
    src = _package(tmp_path / "pkg")
    ds = Dataset(name="d", source_url="u", local_path=src, metadata={"k": 1})
    first = reproducer_mod.script_free_dataset(ds)
    second = reproducer_mod.script_free_dataset(ds)
    assert first.local_path == second.local_path == tmp_path / "pkg.script-free"
    assert (first.name, first.source_url, first.metadata) == ("d", "u", {"k": 1})
    assert not any(reproducer_mod.is_script(Path(f)) for f in _files(first.local_path))


class _RecordingExecutor(CodeExecutor):
    """Records which files the sandbox would have been able to read."""

    def __init__(self) -> None:
        super().__init__(timeout=60)
        self.visible: list[set[str]] = []

    def execute(self, code, dataset):
        self.visible.append(_files(dataset.local_path))
        return super().execute(code, dataset)


@pytest.mark.parametrize(
    ("mode", "scripts_visible"),
    [("seeded", True), ("independent", False), ("blind", False)],
)
def test_pipeline_reproducer_mounts_script_free_data_in_independent_mode(tmp_path, mode, scripts_visible):
    pkg = _package(tmp_path / "pkg")
    executor = _RecordingExecutor()
    pipeline, llm = _real_pipeline("print('RESULT:beta=0.5')\n", pkg, executor=executor)
    original_downloader = pipeline.downloader

    PipelineReproducer(pipeline).reproduce(
        "raw paper text",
        language=Language.PYTHON,
        dataset_reference=DatasetReference(name="d", source=DatasetSource.DIRECT_URL, url="https://x"),
        claims=[Claim(description="beta", value=0.5)],
        reproduction_mode=ReproductionMode(mode),
    )

    [visible] = executor.visible
    assert ("master.do" in visible) is scripts_visible
    assert "data/panel.csv" in visible
    generation_prompt = next(p for p in llm.prompts if "Now write the complete Python script" in p)
    assert ("Analysis.R" in generation_prompt) is scripts_visible
    # The pipeline is handed back exactly as it was.
    assert pipeline.downloader is original_downloader


def test_isolation_can_be_switched_off(tmp_path):
    pkg = _package(tmp_path / "pkg")
    executor = _RecordingExecutor()
    pipeline, _ = _real_pipeline("print('RESULT:beta=0.5')\n", pkg, executor=executor)
    PipelineReproducer(pipeline, isolate_independent_scripts=False).reproduce(
        "raw paper text",
        language=Language.PYTHON,
        dataset_reference=DatasetReference(name="d", source=DatasetSource.DIRECT_URL, url="https://x"),
        claims=[Claim(description="beta", value=0.5)],
        reproduction_mode=ReproductionMode.INDEPENDENT,
    )
    assert "master.do" in executor.visible[0]


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


def test_seeded_pipeline_cache_keys_are_unchanged():
    """A plain ``make benchmark`` keeps hitting the caches it wrote before this change."""
    entry = _entry()
    assert runner._cache_key(entry, "seeded") == _pre_protocol_cache_key(entry, "seeded")
    assert runner._cache_key(entry, "seeded", "pipeline") == _pre_protocol_cache_key(entry, "seeded")


def test_independent_cache_keys_move_to_the_script_free_contract():
    entry = _entry()
    assert runner._cache_key(entry, "independent") != _pre_protocol_cache_key(entry, "independent")


def test_cache_key_includes_reproducer():
    entry = _entry()
    for mode in ("seeded", "independent", "blind"):
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


# ── First-attempt scoring ──────────────────────────────────────────────


class TwoAttemptReproducer:
    """An agent whose first script passed one claim and whose refined final script passed both."""

    name = "two-attempt"

    def reproduce(self, paper_source, *, language, dataset_reference, claims, reproduction_mode):
        first = "RESULT:beta=0.9\nRESULT:n_obs=660\n"
        final = "RESULT:beta=0.5\nRESULT:n_obs=660\n"
        return Reproduction(
            outputs={"beta": 0.5, "n_obs": 660.0},
            claims=list(claims or []),
            stdout=final,
            exit_code=0,
            attempt_outputs=[first, final],
            n_refinements=1,
            n_executions=2,
        )


def test_first_attempt_is_scored_with_the_same_comparator(tmp_path):
    [row] = runner.run_benchmark(
        [_entry()], reproducer="two", reproducer_factory=TwoAttemptReproducer, cache_dir=tmp_path
    )
    assert row.n_claims_with_paper_match == 2
    assert row.n_claims_with_paper_match_first_attempt == 1
    assert row.n_refinements == 1 and row.n_executions == 2
    assert [(cd.description, cd.passed, cd.passed_first_attempt) for cd in row.claim_details] == [
        ("beta", True, False),
        ("n_obs", True, True),
    ]
    # Round-trips through results JSON, and through the result cache.
    out = tmp_path / "results.json"
    runner.write_results([row], out)
    [loaded] = [runner._result_from_jsonable(d) for d in json.loads(out.read_text())["results"]]
    assert loaded.n_claims_with_paper_match_first_attempt == 1
    assert loaded.claim_details[0].passed_first_attempt is False
    [cached] = runner.run_benchmark(
        [_entry()], reproducer="two", reproducer_factory=TwoAttemptReproducer, cache_dir=tmp_path
    )
    assert cached.cached and cached.n_claims_with_paper_match_first_attempt == 1


def test_first_attempt_uses_the_modes_tolerance():
    """0.57 vs 0.5 fails seeded but sits inside ±1·SE independently, first attempt included."""
    rep = Reproduction(
        outputs={"beta": 0.5, "n_obs": 660.0},
        attempt_outputs=["RESULT:beta=0.57\nRESULT:n_obs=NA\n", "RESULT:beta=0.5\nRESULT:n_obs=660\n"],
    )
    seeded = runner.score_reproduction(_entry(), rep, mode="seeded")
    independent = runner.score_reproduction(_entry(), rep, mode="independent")
    assert seeded.n_claims_with_paper_match_first_attempt == 0
    assert independent.n_claims_with_paper_match_first_attempt == 1
    # n_executions falls back to the attempt count; refinements stay unreported.
    assert seeded.n_executions == 2 and seeded.n_refinements is None


def test_no_attempt_data_leaves_first_attempt_fields_unset():
    scored = runner.score_reproduction(_entry(), Reproduction(outputs={"beta": 0.5, "n_obs": 660.0}))
    assert scored.n_claims_with_paper_match == 2
    assert scored.n_claims_with_paper_match_first_attempt is None
    assert scored.n_refinements is None and scored.n_executions is None
    assert all(cd.passed_first_attempt is None for cd in scored.claim_details)


def test_old_results_rows_load_without_first_attempt_fields():
    for d in json.loads(BOTH_BASELINE.read_text(encoding="utf-8")):
        row = runner._result_from_jsonable(d)
        assert row.n_claims_with_paper_match_first_attempt is None
        assert row.n_refinements is None and row.n_executions is None
        assert all(cd.passed_first_attempt is None for cd in row.claim_details)


def test_pipeline_reproduction_lists_attempt_outputs_in_run_order():
    """A reverted refinement: the final run came first, the broken one after it."""
    beta = Claim(description="beta", value=0.5)
    final = ExecutionResult(
        generated_code="ok",
        stdout="RESULT:beta=0.5\n",
        exit_code=0,
        outputs={"beta": 0.5},
        attempts=[RefinementAttempt(code="broken", stdout="partial", exit_code=1)],
        final_execution_index=0,
        refinement_calls=1,
    )
    report = ValidationReport(
        paper=Paper(title="t", claims=[beta]),
        dataset=Dataset(name="d", source_url="", local_path=Path("/tmp/d")),
        execution_result=final,
        claim_results=[],
        overall_passed=False,
    )
    rep = reproducer_mod.reproduction_from_report(report)
    assert rep.attempt_outputs == ["RESULT:beta=0.5\n", "partial"]
    assert (rep.n_refinements, rep.n_executions) == (1, 2)

    # Without an index the final run is taken to be last; refinements are at
    # least one per execution after the first.
    final.final_execution_index = None
    final.refinement_calls = 0
    rep = reproducer_mod.reproduction_from_report(report)
    assert rep.attempt_outputs == ["partial", "RESULT:beta=0.5\n"]
    assert rep.n_refinements == 1


def test_reference_pipeline_records_first_attempt(tmp_path):
    """Real components, fake LLM: a first script that passes is recorded as such."""
    data = tmp_path / "data"
    data.mkdir()
    (data / "data.csv").write_text("y,x\n1,2\n", encoding="utf-8")
    pipeline, _ = _real_pipeline("print('RESULT:beta=0.5')\nprint('RESULT:n_obs=660')\n", data)
    [row] = runner.run_benchmark(
        [_dataset_entry()], pipeline_factory=lambda: pipeline, cache_dir=tmp_path / "c"
    )
    assert row.error is None
    assert row.n_claims_with_paper_match == row.n_claims_with_paper_match_first_attempt == 2
    assert (row.n_refinements, row.n_executions) == (0, 1)


# ── First-scored scoring (crash repairs excluded) ──────────────────────

_CRASH = "Error in read_dta(path): file not found\n"
_OFF_TARGET = "RESULT:beta=0.9\nRESULT:n_obs=660\n"
_ON_TARGET = "RESULT:beta=0.5\nRESULT:n_obs=660\n"


class CrashScoreRefineReproducer:
    """First script crashed, the error repair printed results, a claim refinement fixed beta."""

    name = "crash-score-refine"

    def reproduce(self, paper_source, *, language, dataset_reference, claims, reproduction_mode):
        return Reproduction(
            outputs={"beta": 0.5, "n_obs": 660.0},
            claims=list(claims or []),
            stdout=_ON_TARGET,
            exit_code=0,
            attempt_outputs=[_CRASH, _OFF_TARGET, _ON_TARGET],
            attempt_kinds=["error", "claim", ""],
            n_refinements=2,
            n_error_refinements=1,
            n_claim_refinements=1,
            n_executions=3,
        )


def test_first_scored_skips_crash_repairs(tmp_path):
    [row] = runner.run_benchmark(
        [_entry()], reproducer="csr", reproducer_factory=CrashScoreRefineReproducer, cache_dir=tmp_path
    )
    assert row.n_claims_with_paper_match == 2
    assert row.n_claims_with_paper_match_first_attempt == 0
    assert row.n_claims_with_paper_match_first_scored == 1
    assert row.first_scored_attempt_index == 1
    assert (row.n_error_refinements, row.n_claim_refinements, row.n_refinements) == (1, 1, 2)
    assert [
        (cd.description, cd.passed, cd.passed_first_attempt, cd.passed_first_scored)
        for cd in row.claim_details
    ] == [("beta", True, False, False), ("n_obs", True, False, True)]
    out = tmp_path / "results.json"
    runner.write_results([row], out)
    [loaded] = [runner._result_from_jsonable(d) for d in json.loads(out.read_text())["results"]]
    assert loaded.n_claims_with_paper_match_first_scored == 1
    assert loaded.first_scored_attempt_index == 1
    assert (loaded.n_error_refinements, loaded.n_claim_refinements) == (1, 1)
    assert loaded.claim_details[1].passed_first_scored is True
    [cached] = runner.run_benchmark(
        [_entry()], reproducer="csr", reproducer_factory=CrashScoreRefineReproducer, cache_dir=tmp_path
    )
    assert cached.cached and cached.n_claims_with_paper_match_first_scored == 1


def test_first_scored_is_the_first_attempt_when_the_first_script_printed_results():
    rep = Reproduction(outputs={"beta": 0.5, "n_obs": 660.0}, attempt_outputs=[_OFF_TARGET, _ON_TARGET])
    scored = runner.score_reproduction(_entry(), rep)
    assert scored.first_scored_attempt_index == 0
    assert scored.n_claims_with_paper_match_first_scored == 1
    assert scored.n_claims_with_paper_match_first_attempt == 1
    assert scored.n_error_refinements is None and scored.n_claim_refinements is None


def test_first_scored_ignores_na_only_output_and_falls_back_to_the_first_execution():
    na_only = "RESULT:beta=NA\nRESULT:n_obs=NA\n"
    rep = Reproduction(outputs={"beta": 0.5}, attempt_outputs=[_CRASH, na_only, _ON_TARGET])
    assert runner.score_reproduction(_entry(), rep).first_scored_attempt_index == 2
    none_scored = Reproduction(outputs={}, attempt_outputs=[_CRASH, na_only])
    scored = runner.score_reproduction(_entry(), none_scored)
    assert scored.first_scored_attempt_index == 0
    assert scored.n_claims_with_paper_match_first_scored == 0


def test_first_scored_uses_the_modes_tolerance():
    """0.57 vs 0.5 fails seeded but sits inside ±1·SE independently."""
    rep = Reproduction(
        outputs={"beta": 0.5, "n_obs": 660.0},
        attempt_outputs=[_CRASH, "RESULT:beta=0.57\n", _ON_TARGET],
    )
    assert runner.score_reproduction(_entry(), rep, mode="seeded").n_claims_with_paper_match_first_scored == 0
    assert (
        runner.score_reproduction(_entry(), rep, mode="independent").n_claims_with_paper_match_first_scored
        == 1
    )


def test_no_attempt_data_leaves_first_scored_fields_unset():
    scored = runner.score_reproduction(_entry(), Reproduction(outputs={"beta": 0.5, "n_obs": 660.0}))
    assert scored.n_claims_with_paper_match_first_scored is None
    assert scored.first_scored_attempt_index is None
    assert scored.n_error_refinements is None and scored.n_claim_refinements is None
    assert all(cd.passed_first_scored is None for cd in scored.claim_details)


def test_older_results_rows_load_without_first_scored_fields():
    # Before first-attempt scoring (PR #45) ...
    for d in json.loads(BOTH_BASELINE.read_text(encoding="utf-8")):
        row = runner._result_from_jsonable(d)
        assert row.n_claims_with_paper_match_first_scored is None
        assert row.first_scored_attempt_index is None
        assert row.n_error_refinements is None and row.n_claim_refinements is None
        assert all(cd.passed_first_scored is None for cd in row.claim_details)
    # ... and a PR-45-era row: first-attempt data, no first-scored keys.
    d = runner._result_to_jsonable(
        runner.BenchmarkResult(
            entry_id="x",
            n_claims_with_paper_match_first_attempt=0,
            n_refinements=3,
            claim_details=[runner.ClaimDetail("beta", "other", 0.5, 0.5, 0.01, 0.0, True, False)],
        )
    )
    for key in (
        "n_claims_with_paper_match_first_scored",
        "first_scored_attempt_index",
        "n_error_refinements",
        "n_claim_refinements",
    ):
        d.pop(key)
    d["claim_details"][0].pop("passed_first_scored")
    row = runner._result_from_jsonable(d)
    assert row.n_claims_with_paper_match_first_attempt == 0 and row.n_refinements == 3
    assert row.n_claims_with_paper_match_first_scored is None
    assert row.claim_details[0].passed_first_attempt is False
    assert row.claim_details[0].passed_first_scored is None


def test_pipeline_reproduction_carries_attempt_kinds_and_refinement_split():
    beta = Claim(description="beta", value=0.5)
    final = ExecutionResult(
        generated_code="v2",
        stdout=_ON_TARGET,
        exit_code=0,
        outputs={"beta": 0.5, "n_obs": 660.0},
        attempts=[
            RefinementAttempt(code="v0", stderr="boom", exit_code=1, feedback="boom", kind="error"),
            RefinementAttempt(
                code="v1",
                stdout=_OFF_TARGET,
                exit_code=0,
                feedback="beta: reproduced 0.9, claimed 0.5 (tolerance 0.01)",
                kind="claim",
            ),
        ],
        final_execution_index=2,
        refinement_calls=2,
        n_error_refinements=1,
        n_claim_refinements=1,
    )
    report = ValidationReport(
        paper=Paper(title="t", claims=[beta]),
        dataset=Dataset(name="d", source_url="", local_path=Path("/tmp/d")),
        execution_result=final,
        claim_results=[],
        overall_passed=True,
    )
    rep = reproducer_mod.reproduction_from_report(report)
    assert rep.attempt_outputs == ["", _OFF_TARGET, _ON_TARGET]
    assert rep.attempt_kinds == ["error", "claim", ""]
    assert (rep.n_error_refinements, rep.n_claim_refinements, rep.n_refinements) == (1, 1, 2)
    assert runner.score_reproduction(_entry(), rep).first_scored_attempt_index == 1


def test_pipeline_reproduction_places_the_final_kind_at_its_index():
    """A reverted refinement: the final run came first, the broken one after it."""
    final = ExecutionResult(
        generated_code="ok",
        stdout=_ON_TARGET,
        exit_code=0,
        attempts=[RefinementAttempt(code="broken", exit_code=1)],
        final_execution_index=0,
        refinement_calls=1,
        n_claim_refinements=1,
    )
    report = ValidationReport(
        paper=Paper(title="t", claims=[]),
        dataset=Dataset(name="d", source_url="", local_path=Path("/tmp/d")),
        execution_result=final,
        claim_results=[],
        overall_passed=False,
    )
    rep = reproducer_mod.reproduction_from_report(report)
    assert rep.attempt_outputs == [_ON_TARGET, ""]
    assert rep.attempt_kinds == ["", ""]
    assert (rep.n_error_refinements, rep.n_claim_refinements) == (0, 1)
