"""ROADMAP 3.8: data inventory, sample reconciliation, completeness repair.

Fakes only: a fake LLM client that answers with canned scripts and
records the prompts, and a fake executor that returns canned runs.  No
Docker, no network, no API call.  Fixture data is synthetic and generic.
"""

from __future__ import annotations

from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock

import pandas as pd
import pytest

from benchmark.artifacts import classify_feedback
from benchmark.reproducer import pipeline_artifacts
from retally.codegen.executor import parse_sample_lines
from retally.codegen.generator import CodeGenerator, is_sample_size_claim
from retally.codegen.inventory import CSV_EXACT_MAX_BYTES, build_inventory
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
    ReproductionMode,
)
from retally.pipeline import COMPLETENESS_FEEDBACK_HEADER, ValidationPipeline
from retally.validation.comparator import ResultComparator

# ── fakes ────────────────────────────────────────────────────────────────


class FakeLLM:
    """``messages.create`` answering with the next canned reply; prompts recorded."""

    def __init__(self, replies: list[str]) -> None:
        self.replies = list(replies)
        self.prompts: list[str] = []
        self.messages = self

    def create(self, **kwargs):
        self.prompts.append(kwargs["messages"][0]["content"])
        return SimpleNamespace(content=[SimpleNamespace(type="text", text=self.replies.pop(0))])


class FakeExecutor:
    """Returns the canned run for each script, keyed by the script text."""

    def __init__(self, runs: dict[str, ExecutionResult]) -> None:
        self.runs = runs
        self.scripts: list[str] = []
        self.timeout = 300

    def execute(self, code: str, dataset: Dataset) -> ExecutionResult:
        self.scripts.append(code)
        run = self.runs[code]
        return ExecutionResult(
            generated_code=code,
            stdout=run.stdout,
            stderr=run.stderr,
            exit_code=run.exit_code,
            outputs=dict(run.outputs),
            sample_lines=parse_sample_lines(run.stdout),
            timed_out=run.timed_out,
            elapsed_seconds=run.elapsed_seconds,
        )


def _run(stdout: str, exit_code: int = 0) -> ExecutionResult:
    from retally.codegen.executor import parse_outputs

    return ExecutionResult(
        generated_code="", stdout=stdout, exit_code=exit_code, outputs=parse_outputs(stdout)
    )


# ── (A) data inventory ───────────────────────────────────────────────────


def _write_fixtures(root: Path) -> None:
    (root / "data").mkdir(parents=True)
    pd.DataFrame({"unit_id": [1, 2, 3], "outcome": [0.5, 1.5, 2.5], "group": ["a", "b", "a"]}).to_csv(
        root / "data" / "small.csv", index=False
    )
    pd.DataFrame({"y": [1.0, 2.0, 3.0, 4.0], "x": [0.0, 1.0, 0.0, 1.0]}).to_stata(
        root / "data" / "panel.dta",
        write_index=False,
        variable_labels={"y": "Outcome in levels", "x": "Treatment indicator"},
    )


def test_inventory_profiles_a_small_csv_and_dta(tmp_path):
    _write_fixtures(tmp_path)
    lines = build_inventory(tmp_path)
    text = "\n".join(lines)
    csv_line = next(line for line in lines if "small.csv" in line)
    dta_line = next(line for line in lines if "panel.dta" in line)
    assert "3 rows, 3 columns: unit_id, outcome, group" in csv_line
    assert "4 rows, 2 columns" in dta_line
    assert 'y "Outcome in levels"' in dta_line and 'x "Treatment indicator"' in dta_line
    assert "Same columns" not in text  # no siblings here


def test_inventory_marks_a_large_csv_as_approximate_without_skipping_it(tmp_path, monkeypatch):
    from retally.codegen import inventory

    pd.DataFrame({"a": range(10), "b": range(10)}).to_csv(tmp_path / "big.csv", index=False)
    monkeypatch.setattr(inventory, "CSV_EXACT_MAX_BYTES", 1)
    assert "~10 rows" in "\n".join(build_inventory(tmp_path))
    monkeypatch.setattr(inventory, "CSV_COUNT_MAX_BYTES", 1)
    line = "\n".join(build_inventory(tmp_path))
    assert "big.csv" in line and "rows unknown: file too large to count quickly" in line
    assert CSV_EXACT_MAX_BYTES > 1  # the module constant itself is untouched


def test_inventory_says_which_columns_differ_between_files_sharing_columns(tmp_path):
    base = pd.DataFrame({"id": [1, 2, 3], "amount": [10.0, 20.0, 30.0], "flag": [0, 1, 0]})
    base.to_stata(tmp_path / "version_a.dta", write_index=False)
    other = base.copy()
    other["amount"] = [1.0, 2.0, 3.0]
    other.to_stata(tmp_path / "version_b.dta", write_index=False)
    text = "\n".join(build_inventory(tmp_path))
    assert "Same columns in 2 files: version_a.dta, version_b.dta" in text
    assert "differ in 1 column(s)" in text and "amount (mean 20" in text and "mean 2," in text
    # Blind mode: the differing column is named, its values are not.
    blind = "\n".join(build_inventory(tmp_path, show_values=False))
    assert "differ in 1 column(s): amount" in blind and "mean" not in blind


def test_generation_prompt_carries_the_inventory_only_when_switched_on(tmp_path):
    _write_fixtures(tmp_path)
    paper = Paper(title="T", claims=[Claim(description="beta", value=1.0, claim_type=ClaimType.COEFFICIENT)])
    paper.language = Language.R
    dataset = Dataset(name="pkg", source_url="", local_path=tmp_path)
    on, off = FakeLLM(["x <- 1"]), FakeLLM(["x <- 1"])
    CodeGenerator(on).generate(paper, dataset, reproduction_mode=ReproductionMode.INDEPENDENT)
    CodeGenerator(off, data_inventory=False, sample_reconciliation=False).generate(
        paper, dataset, reproduction_mode=ReproductionMode.INDEPENDENT
    )
    assert "Data inventory" in on.prompts[0] and 'y "Outcome in levels"' in on.prompts[0]
    assert "Data inventory" not in off.prompts[0] and "SAMPLE:" not in off.prompts[0]


# ── (B) sample reconciliation ────────────────────────────────────────────


def test_sample_lines_are_parsed_and_result_lines_untouched():
    stdout = (
        "SAMPLE:main:loaded=5000\n"
        "SAMPLE:main:drop_missing_outcome=4800\n"
        "noise SAMPLE:ignored=1\n"
        "SAMPLE:main:estimation=4700.0\n"
        "SAMPLE:broken=NA\n"
        "RESULT:beta=0.5\n"
    )
    assert parse_sample_lines(stdout) == [
        ("main:loaded", 5000.0),
        ("main:drop_missing_outcome", 4800.0),
        ("main:estimation", 4700.0),
    ]
    from retally.codegen.executor import parse_outputs

    assert parse_outputs(stdout) == {"beta": 0.5}


def test_sample_lines_reach_the_artifacts():
    final = ExecutionResult(generated_code="v2", stdout="SAMPLE:s:estimation=10\nRESULT:b=1\n", exit_code=0)
    from retally.models import RefinementAttempt

    final.attempts = [RefinementAttempt(code="v1", stdout="SAMPLE:s:loaded=12\n", exit_code=0)]
    report = SimpleNamespace(execution_result=final)
    arts = pipeline_artifacts(report)
    assert arts["samples.txt"] == "s:estimation=10\n"
    assert arts["attempt-1/samples.txt"] == "s:loaded=12\n"


def _n_claim(value: float = 1000) -> Claim:
    return Claim(description="n_obs_main_table", value=value, claim_type=ClaimType.OTHER)


def test_sample_size_claims_are_recognised_generically():
    assert is_sample_size_claim(_n_claim())
    assert is_sample_size_claim(Claim(description="n_clusters_main", value=40, claim_type=ClaimType.OTHER))
    assert is_sample_size_claim(
        Claim(description="table_total", value=40, claim_type=ClaimType.OTHER, unit="respondents")
    )
    assert not is_sample_size_claim(
        Claim(description="n_items_coef", value=0.3, claim_type=ClaimType.COEFFICIENT)
    )
    assert not is_sample_size_claim(Claim(description="n_obs_share", value=0.25, claim_type=ClaimType.OTHER))


def test_claim_refinement_prompt_opens_with_the_sample_gap():
    client = FakeLLM(["fixed"])
    gen = CodeGenerator(client)
    paper = Paper(title="T", claims=[], language=Language.R)
    stdout = "SAMPLE:main:loaded=1200\nSAMPLE:main:estimation=1100\nRESULT:n_obs_main_table=1100\n"
    failed = [
        ClaimValidationResult(claim=_n_claim(), reproduced_value=1100, tolerance=10.0, passed=False),
        ClaimValidationResult(
            claim=Claim(description="beta", value=0.5, claim_type=ClaimType.COEFFICIENT),
            reproduced_value=0.7,
            tolerance=0.05,
            passed=False,
        ),
    ]
    exec_result = ExecutionResult(generated_code="v1", stdout=stdout, exit_code=0, outputs={"beta": 0.7})
    gen.refine_for_claims(
        "v1", failed, exec_result, paper, Dataset(name="d", source_url="", local_path=Path("/x")), []
    )
    prompt = client.prompts[0]
    assert "## Sample size check (fix this first)" in prompt
    assert "n_obs_main_table: paper states 1000, your code produced 1100 (+100 rows)" in prompt
    assert "SAMPLE:main:estimation=1100" in prompt
    assert prompt.index("## Sample size check") < prompt.index("## Claims still failing")
    # Switched off: the frozen prompt has no such block.
    frozen = FakeLLM(["fixed"])
    CodeGenerator(frozen, sample_reconciliation=False).refine_for_claims(
        "v1", failed, exec_result, paper, Dataset(name="d", source_url="", local_path=Path("/x")), []
    )
    assert "Sample size check" not in frozen.prompts[0]


@pytest.mark.parametrize("mode", [ReproductionMode.SEEDED, ReproductionMode.INDEPENDENT])
def test_generation_prompt_asks_for_sample_lines_and_comparison(mode, tmp_path):
    client = FakeLLM(["x <- 1"])
    paper = Paper(title="T", claims=[_n_claim()], language=Language.R)
    CodeGenerator(client).generate(
        paper, Dataset(name="d", source_url="", local_path=tmp_path), reproduction_mode=mode
    )
    prompt = client.prompts[0]
    assert "SAMPLE:<sample_name>:<step>=<number_of_rows>" in prompt
    assert "compare each sample's count with any sample size the paper states" in prompt


def test_blind_generation_prompt_asks_for_restrictions_without_any_sample_size(tmp_path):
    client = FakeLLM(["x <- 1"])
    paper = Paper(title="T", claims=[_n_claim(98765)], language=Language.R)
    CodeGenerator(client).generate(
        paper, Dataset(name="d", source_url="", local_path=tmp_path), reproduction_mode=ReproductionMode.BLIND
    )
    prompt = client.prompts[0]
    assert "SAMPLE:<sample_name>:<step>=<number_of_rows>" in prompt
    assert "Apply every restriction the paper states, in order" in prompt
    assert "compare each sample's count" not in prompt
    assert "98765" not in prompt and "98,765" not in prompt


# ── (C) completeness repair ──────────────────────────────────────────────


def _pipeline(client: FakeLLM, executor: FakeExecutor, claims: list[Claim], **kwargs) -> ValidationPipeline:
    paper = Paper(
        title="Test Paper",
        claims=claims,
        dataset_references=[
            DatasetReference(name="d", source=DatasetSource.DIRECT_URL, url="http://x/d.csv")
        ],
        methodology_summary="OLS.",
        language=Language.R,
    )
    dataset = Dataset(name="d", source_url="http://x/d.csv", local_path=Path("/nonexistent-dataset"))
    parser = MagicMock()
    parser.parse_text.return_value = paper
    extractor = MagicMock()
    extractor.extract_methodology.return_value = paper.methodology_summary
    extractor.extract_hyperparameters.return_value = []
    extractor.extract_code_references.return_value = []
    downloader = MagicMock()
    downloader.download.return_value = dataset
    return ValidationPipeline(
        parser=parser,
        extractor=extractor,
        downloader=downloader,
        registry=MagicMock(),
        generator=CodeGenerator(client),
        executor=executor,
        r_executor=executor,
        comparator=ResultComparator(),
        reporter=MagicMock(),
        code_downloader=MagicMock(),
        **kwargs,
    )


def _claims() -> list[Claim]:
    return [
        Claim(description="beta_main", value=0.50, claim_type=ClaimType.COEFFICIENT, standard_error=0.05),
        Claim(
            description="beta_interaction", value=-0.20, claim_type=ClaimType.COEFFICIENT, standard_error=0.05
        ),
    ]


def _run_validate(pipeline: ValidationPipeline, mode: ReproductionMode) -> ExecutionResult:
    pipeline.validate(
        "some text",
        dataset_reference=DatasetReference(name="d", source=DatasetSource.DIRECT_URL, url="http://x/d.csv"),
        claims=_claims(),
        reproduction_mode=mode,
    )
    return pipeline.reporter.build.call_args.args[2]


@pytest.mark.parametrize("mode", [ReproductionMode.INDEPENDENT, ReproductionMode.BLIND])
def test_na_result_triggers_one_completeness_repair_and_no_claim_refinement(mode):
    v1, v2 = "script_v1 <- 1", "script_v2 <- 2"
    client = FakeLLM([v1, v2])
    executor = FakeExecutor(
        {
            v1: _run("SAMPLE:main:estimation=900\nRESULT:beta_main=0.5\nRESULT:beta_interaction=NA\n"),
            v2: _run("SAMPLE:main:estimation=900\nRESULT:beta_main=0.5\nRESULT:beta_interaction=-0.2\n"),
        }
    )
    pipeline = _pipeline(client, executor, _claims())
    result = _run_validate(pipeline, mode)

    assert len(client.prompts) == 2  # generation + one completeness repair, no claim refinement
    repair = client.prompts[1]
    assert "RAN TO COMPLETION" in repair
    assert "beta_interaction: printed a non-numeric value (e.g. NA)" in repair
    assert "beta_main" not in repair.split("## Quantities with no usable value")[1].split("##")[0]
    assert "-0.2" not in repair.split("## Current Code")[0]  # no claim value anywhere before the code
    assert executor.scripts == [v1, v2]
    assert result.outputs == {"beta_main": 0.5, "beta_interaction": -0.2}
    assert (result.n_error_refinements, result.n_completeness_refinements, result.n_claim_refinements) == (
        1,
        1,
        0,
    )
    assert [a.kind for a in result.attempts] == ["completeness"]
    assert result.attempts[0].feedback.startswith(COMPLETENESS_FEEDBACK_HEADER)
    assert classify_feedback(result.attempts[0].feedback) == "completeness"
    assert result.sample_lines == [("main:estimation", 900.0)]


def test_completeness_repair_switched_off_reproduces_the_frozen_loop():
    v1, v2 = "script_v1 <- 1", "script_v2 <- 2"
    client = FakeLLM([v1, v2])
    executor = FakeExecutor(
        {
            v1: _run("RESULT:beta_main=0.5\nRESULT:beta_interaction=NA\n"),
            v2: _run("RESULT:beta_main=0.5\nRESULT:beta_interaction=-0.2\n"),
        }
    )
    pipeline = _pipeline(client, executor, _claims(), completeness_repair=False)
    result = _run_validate(pipeline, ReproductionMode.INDEPENDENT)
    assert "your code produced N/A" in client.prompts[1]  # the claim refinement handles the NA
    assert (result.n_completeness_refinements, result.n_claim_refinements) == (0, 1)
    assert [a.kind for a in result.attempts] == ["claim"]


def test_completeness_repair_uses_the_error_budget_and_reverts_a_broken_repair():
    v1, v2 = "script_v1 <- 1", "script_v2 <- 2"
    client = FakeLLM([v1, v2])
    executor = FakeExecutor(
        {
            v1: _run("RESULT:beta_main=0.5\n"),  # beta_interaction never printed
            v2: _run("", exit_code=1),
        }
    )
    pipeline = _pipeline(client, executor, _claims(), max_claim_refinements=0)
    result = _run_validate(pipeline, ReproductionMode.BLIND)
    assert "beta_interaction: no RESULT line printed" in client.prompts[1]
    assert result.generated_code == v1 and result.final_execution_index == 0
    assert result.n_error_refinements == 1

    # No budget left: no repair.
    client = FakeLLM([v1])
    pipeline = _pipeline(
        client, FakeExecutor({v1: _run("RESULT:beta_main=0.5\n")}), _claims(), max_refinements=0
    )
    result = _run_validate(pipeline, ReproductionMode.BLIND)
    assert len(client.prompts) == 1 and result.n_completeness_refinements == 0


# ── (C′) timeout repair ──────────────────────────────────────────────────


def _timed_out(stdout: str) -> ExecutionResult:
    run = _run(stdout, exit_code=-1)
    run.timed_out = True
    run.elapsed_seconds = 301.4
    return run


@pytest.mark.parametrize("mode", [ReproductionMode.SEEDED, ReproductionMode.BLIND])
def test_a_timed_out_run_gets_a_timeout_repair_that_says_so(mode):
    v1, v2 = "script_v1 <- 1", "script_v2 <- 2"
    client = FakeLLM([v1, v2])
    executor = FakeExecutor(
        {
            v1: _timed_out("loading\nmain data: 1000000 rows, 25 cols\n"),
            v2: _run("RESULT:beta_main=0.5\nRESULT:beta_interaction=-0.2\n"),
        }
    )
    result = _run_validate(_pipeline(client, executor, _claims()), mode)

    repair = client.prompts[1]
    assert "killed the script at its wall-clock limit (300 s) after 301 s" in repair
    assert "main data: 1000000 rows, 25 cols" in repair
    assert "cutting input work, not by adding printing" in repair
    assert "No RESULT: lines found" not in repair
    assert [a.kind for a in result.attempts] == ["timeout-repair"]
    assert classify_feedback(result.attempts[0].feedback) == "timeout-repair"
    assert (result.n_error_refinements, result.n_completeness_refinements) == (1, 0)


def test_timeout_repair_switched_off_keeps_the_frozen_feedback():
    v1, v2 = "script_v1 <- 1", "script_v2 <- 2"
    client = FakeLLM([v1, v2])
    executor = FakeExecutor(
        {
            v1: _timed_out("main data: 1000000 rows, 25 cols\n"),
            v2: _run("RESULT:beta_main=0.5\nRESULT:beta_interaction=-0.2\n"),
        }
    )
    pipeline = _pipeline(client, executor, _claims(), completeness_repair=False)
    result = _run_validate(pipeline, ReproductionMode.INDEPENDENT)
    assert "No RESULT: lines found in output" in client.prompts[1]
    assert "wall-clock limit" not in client.prompts[1]
    assert [a.kind for a in result.attempts] == ["error"]
