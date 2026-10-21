"""Run artifacts: captured by the reproducer, written by the runner, read by the CLI.

Everything is faked — no API key, Docker, or network.
"""

from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import MagicMock

from retally.codegen.generator import CodeGenerator
from retally.models import (
    Claim,
    ClaimType,
    Dataset,
    DatasetReference,
    DatasetSource,
    ExecutionResult,
    Language,
    ReproductionMode,
)
from retally.paper.extractor import ClaimExtractor
from retally.paper.parser import PaperParser
from retally.pipeline import ValidationPipeline
from retally.validation.comparator import ResultComparator
from retally.validation.reporter import ValidationReporter
from tests._loaders import REPO_ROOT, load_module_from_path

bschema = load_module_from_path("benchmark.schema", REPO_ROOT / "benchmark" / "schema.py")
load_module_from_path("benchmark.pricing", REPO_ROOT / "benchmark" / "pricing.py")
load_module_from_path("benchmark.metrics", REPO_ROOT / "benchmark" / "metrics.py")
reproducer_mod = load_module_from_path("benchmark.reproducer", REPO_ROOT / "benchmark" / "reproducer.py")
runner = load_module_from_path("benchmark.runner", REPO_ROOT / "benchmark" / "runner.py")
artifacts_cli = load_module_from_path("benchmark.artifacts", REPO_ROOT / "benchmark" / "artifacts.py")

SAMPLE_R = """\
library(haven)
df <- read_dta(file.path(data_dir, "main_panel.dta"))
cw <- read.csv("crosswalk.csv")
extra <- readRDS(rds_path)
print("RESULT:beta=0.5")
"""


def _entry(**overrides):
    base = {
        "id": "paper1",
        "i4r_report_url": "https://example.org/r",
        "language": bschema.Language.R,
        "outcome_label": bschema.OutcomeLabel.REPRODUCIBLE,
        "paper": bschema.PaperRef(source="raw paper text"),
        "original_claims": [bschema.OriginalClaim(description="beta", value=0.5, claim_type="other")],
    }
    base.update(overrides)
    return bschema.BenchmarkEntry(**base)


class ArtifactReproducer:
    """A fake agent that returns canned outputs plus artifacts."""

    def __init__(self, artifacts: dict[str, str]) -> None:
        self.artifacts = artifacts
        self.calls = 0

    def reproduce(self, paper_source, *, language, dataset_reference, claims, reproduction_mode):
        self.calls += 1
        return reproducer_mod.Reproduction(
            outputs={"beta": 0.5}, claims=list(claims or []), exit_code=0, artifacts=dict(self.artifacts)
        )


ARTS = {"script.R": SAMPLE_R, "stdout.txt": "RESULT:beta=0.5\n", "stderr.txt": "", "attempt-1/script.R": "x"}


def _run(tmp_path, agent, *, run_id="20261020T183012Z", reproducer="fake", **kw):
    return runner.run_benchmark(
        [_entry()],
        reproducer=reproducer,
        reproducer_factory=lambda: agent,
        cache_dir=tmp_path / "cache",
        artifacts_root=tmp_path / "artifacts",
        run_id=run_id,
        **kw,
    )


def test_artifacts_land_in_entry_mode_reproducer_run_dir(tmp_path):
    [row] = _run(tmp_path, ArtifactReproducer(ARTS))
    out = tmp_path / "artifacts" / "paper1" / "seeded" / "fake" / "20261020T183012Z"
    assert (out / "script.R").read_text(encoding="utf-8") == SAMPLE_R
    assert (out / "stdout.txt").read_text(encoding="utf-8") == "RESULT:beta=0.5\n"
    assert (out / "attempt-1" / "script.R").read_text(encoding="utf-8") == "x"
    assert row.artifacts_dir == str(out.resolve())
    assert runner._result_to_jsonable(row)["artifacts_dir"] == row.artifacts_dir


def test_artifacts_dir_is_repo_relative_under_the_repo(monkeypatch, tmp_path):
    monkeypatch.setattr(runner, "REPO_ROOT", tmp_path)
    [row] = _run(tmp_path, ArtifactReproducer(ARTS))
    assert row.artifacts_dir == str(Path("artifacts/paper1/seeded/fake/20261020T183012Z"))


def test_cached_rows_keep_their_artifacts_dir_and_are_not_rewritten(tmp_path):
    agent = ArtifactReproducer(ARTS)
    [first] = _run(tmp_path, agent, run_id="20261020T000000Z")
    [second] = _run(tmp_path, agent, run_id="20261021T000000Z")
    assert agent.calls == 1
    assert second.cached is True
    assert second.artifacts_dir == first.artifacts_dir
    assert not (tmp_path / "artifacts" / "paper1" / "seeded" / "fake" / "20261021T000000Z").exists()


def test_no_artifacts_root_or_no_artifacts_writes_nothing(tmp_path):
    [row] = runner.run_benchmark(
        [_entry()],
        reproducer_factory=lambda: ArtifactReproducer(ARTS),
        cache_dir=tmp_path / "c",
        use_cache=False,
    )
    assert row.artifacts_dir is None
    [row] = _run(tmp_path, ArtifactReproducer({}), use_cache=False)
    assert row.artifacts_dir is None
    assert not (tmp_path / "artifacts").exists()


def test_spec_reproducer_name_and_unsafe_paths_are_sanitised(tmp_path):
    agent = ArtifactReproducer({"../escape.txt": "no", "/abs.txt": "no", "ok.txt": "yes"})
    [row] = _run(tmp_path, agent, reproducer="pkg.mod:factory", use_cache=False)
    out = Path(row.artifacts_dir)
    assert out.parent.name == "pkg.mod_factory"
    assert (out / "ok.txt").read_text(encoding="utf-8") == "yes"
    assert not (out.parent / "escape.txt").exists()


def test_new_run_id_is_a_utc_timestamp():
    rid = runner.new_run_id()
    assert len(rid) == 16 and rid[8] == "T" and rid.endswith("Z")


# ── Capture: the pipeline exposes attempts and prompts ─────────────────


class _LLM:
    """Fake Anthropic client: a fresh script per call, or ``fixed`` text when given."""

    def __init__(self, fixed: str | None = None):
        self.messages = self
        self.fixed = fixed
        self.n = 0

    def create(self, *, messages, **_kwargs):
        self.n += 1
        text = (
            self.fixed if self.fixed is not None else f"```python\nprint('RESULT:beta=0.5')  # v{self.n}\n```"
        )
        response = MagicMock()
        response.content = [MagicMock(text=text)]
        return response


def test_pipeline_reproducer_captures_final_script_attempts_feedback_and_prompts(tmp_path):
    llm = _LLM()
    executor = MagicMock()
    executor.execute.side_effect = [
        ExecutionResult(generated_code="", stdout="loading\n", stderr="Error: no such file", exit_code=1),
        ExecutionResult(generated_code="", stdout="RESULT:beta=0.5\n", exit_code=0, outputs={"beta": 0.5}),
    ]
    downloader = MagicMock()
    downloader.download.side_effect = lambda ref: Dataset(name="d", source_url="", local_path=tmp_path)
    pipeline = ValidationPipeline(
        parser=PaperParser(),
        extractor=ClaimExtractor(_LLM(fixed="[]")),
        downloader=downloader,
        registry=MagicMock(),
        generator=CodeGenerator(llm),
        executor=executor,
        comparator=ResultComparator(),
        reporter=ValidationReporter(),
        include_code_references=False,
    )
    rep = reproducer_mod.PipelineReproducer(pipeline).reproduce(
        "raw paper text",
        language=Language.PYTHON,
        dataset_reference=DatasetReference(name="d", source=DatasetSource.DIRECT_URL, url="https://x/d.zip"),
        claims=[Claim(description="beta", value=0.5, claim_type=ClaimType.OTHER)],
        reproduction_mode=ReproductionMode.SEEDED,
    )
    arts = rep.artifacts
    assert arts["stdout.txt"] == "RESULT:beta=0.5\n"
    assert arts["script.py"] == rep.generated_code
    assert arts["attempt-1/stderr.txt"] == "Error: no such file"
    assert arts["attempt-1/stdout.txt"] == "loading\n"
    assert arts["attempt-1/feedback.txt"] == "Error: no such file"
    assert arts["attempt-1/script.py"] != arts["script.py"]
    prompts = sorted(k for k in arts if k.startswith("prompt-"))
    assert prompts == ["prompt-1.txt", "prompt-2.txt"]
    assert "Error: no such file" in arts["prompt-2.txt"]


# ── CLI ────────────────────────────────────────────────────────────────


def test_data_file_grep_finds_reads_and_literals():
    files = artifacts_cli.data_files_read(SAMPLE_R)
    assert "main_panel.dta" in files and "crosswalk.csv" in files and "rds_path" in files
    py = "import pandas as pd\ndf = pd.read_stata(DATA / 'wave2.dta')\nx = pd.read_csv(path)\n"
    assert artifacts_cli.data_files_read(py) == ["wave2.dta", "path"]


def test_cli_prints_dir_data_files_results_and_claims(tmp_path, capsys):
    [row] = _run(tmp_path, ArtifactReproducer(ARTS))
    results = tmp_path / "results.json"
    runner.write_results([row], results)
    assert artifacts_cli.main([str(results), "--entry", "paper1", "--mode", "seeded"]) == 0
    out = capsys.readouterr().out
    assert row.artifacts_dir in out
    assert "main_panel.dta" in out
    assert "RESULT:beta=0.5" in out
    assert "[PASS] beta" in out
    assert "earlier attempts: 1" in out
    assert artifacts_cli.main([str(results), "--mode", "independent"]) == 1
    json.loads(results.read_text(encoding="utf-8"))
