"""Claude Code as a reproducer: the filesystem adapter, the task renderer, the claim check.

* ``FilesystemReproducer`` reads a run directory a Claude Code session
  wrote (``tests/fixtures/claude_code_reproduction/``) into a
  ``Reproduction``: numbers from the files, never from the manifest;
  strict validation; a missing cell is a ``reproduction_missing`` skip.
* ``render_task`` builds the task directory per mode: the seeded task
  carries the package scripts, the independent mount holds no script and
  its strip manifest sits outside the task directory, and blind
  ``task.md`` / ``paper.txt`` carry no claim value in any printed form
  (checked for every curated catalog entry).
* ``check_attempt`` prints the pipeline's claim-gap feedback, or in blind
  mode only the names of missing quantities.
* ``python -m benchmark.report a.json b.json`` renders several
  reproducers' rows in one report.

No network, no Docker, no API key.
"""

from __future__ import annotations

import json
import os
import shutil
from pathlib import Path

import pytest

from retally.models import DatasetReference, DatasetSource, Language, ReproductionMode
from tests._loaders import REPO_ROOT, load_module_from_path

bschema = load_module_from_path("benchmark.schema", REPO_ROOT / "benchmark" / "schema.py")
load_module_from_path("benchmark.pricing", REPO_ROOT / "benchmark" / "pricing.py")
load_module_from_path("benchmark.metrics", REPO_ROOT / "benchmark" / "metrics.py")
reproducer_mod = load_module_from_path("benchmark.reproducer", REPO_ROOT / "benchmark" / "reproducer.py")
runner = load_module_from_path("benchmark.runner", REPO_ROOT / "benchmark" / "runner.py")
report = load_module_from_path("benchmark.report", REPO_ROOT / "benchmark" / "report.py")
strip_rule = load_module_from_path("benchmark.strip_rule", REPO_ROOT / "benchmark" / "strip_rule.py")
filesystem = load_module_from_path(
    "benchmark.reproducers.filesystem", REPO_ROOT / "benchmark" / "reproducers" / "filesystem.py"
)
render_mod = load_module_from_path(
    "benchmark.reproducers.render_task", REPO_ROOT / "benchmark" / "reproducers" / "render_task.py"
)
check_mod = load_module_from_path(
    "benchmark.reproducers.check_attempt", REPO_ROOT / "benchmark" / "reproducers" / "check_attempt.py"
)

FilesystemReproducer = filesystem.FilesystemReproducer
ReproductionMissingError = reproducer_mod.ReproductionMissingError

FIXTURE_ROOT = Path(__file__).parent / "fixtures" / "claude_code_reproduction"
RUN_DIR = FIXTURE_ROOT / "fixture-paper" / "independent" / "run-a"
PAPER_STUB = FIXTURE_ROOT / "paper_stub.txt"
PACKAGE_DIR = Path(__file__).parent / "fixtures" / "seeded_prompt" / "package"
CATALOG = [e for e in bschema.load_catalog(runner.CATALOG_DIR) if e.original_claims]


# ── Helpers ─────────────────────────────────────────────────────────────


def _entry(**overrides):
    """The fixture paper: two pinned claims, an R entry with a dataset (so the reference names it)."""
    base = {
        "id": "fixture-paper",
        "i4r_report_url": "https://example.org/r",
        "language": bschema.Language.R,
        "outcome_label": bschema.OutcomeLabel.REPRODUCIBLE,
        "paper": bschema.PaperRef(source="fixture paper text", title="Warfare and Development"),
        "dataset": bschema.DatasetRef(source="https://zenodo.org/records/1"),
        "original_claims": [
            bschema.OriginalClaim(
                description="beta",
                value=3.713,
                claim_type="coefficient",
                standard_error=0.305,
                location="Table 1, col 1",
            ),
            bschema.OriginalClaim(description="n_obs", value=660.0, claim_type="other"),
        ],
    }
    base.update(overrides)
    return bschema.BenchmarkEntry(**base)


def _reproduce(root=FIXTURE_ROOT, *, mode=ReproductionMode.INDEPENDENT, name="fixture-paper", **kwargs):
    ref = DatasetReference(name=name, source=DatasetSource.ZENODO) if name else None
    return FilesystemReproducer(root=root, **kwargs).reproduce(
        "fixture paper text",
        language=Language.R,
        dataset_reference=ref,
        claims=None,
        reproduction_mode=mode,
    )


def _copy_fixture(tmp_path: Path) -> Path:
    root = tmp_path / "reproductions"
    shutil.copytree(FIXTURE_ROOT / "fixture-paper", root / "fixture-paper")
    return root


def _edit_manifest(run_dir: Path, **changes) -> None:
    path = run_dir / "reproduction.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    data.update(changes)
    path.write_text(json.dumps(data), encoding="utf-8")


def _value_strings(v: float, *, percent: bool = True) -> set[str]:
    return render_mod.value_strings(v, percent=percent)


def _occurs(form: str, text: str) -> bool:
    import re

    return re.search(rf"(?<![\d.]){re.escape(form)}(?!\d)", text) is not None


def _leaks(text: str, curated: str, numbers: list[float], *, percent: bool = True) -> list[str]:
    """Value forms of ``numbers`` in ``text`` not already in ``curated``.

    ``percent=False`` skips the x100 forms of sub-unit values, which only
    paper prose uses; task boilerplate ("1.0 CPU", "2.5 KB") would trip them.
    """
    return sorted(
        form
        for v in numbers
        for form in _value_strings(v, percent=percent)
        if _occurs(form, text) and not _occurs(form, curated)
    )


# ── FilesystemReproducer: reading a run ─────────────────────────────────


def test_round_trip_reads_numbers_from_the_files():
    rep = _reproduce()
    # The manifest's "_comment" carries a RESULT:beta=999 trap: never read.
    assert rep.outputs == {"beta": 3.7, "n_obs": 660.0}
    assert rep.exit_code == 0
    assert rep.generated_code == (RUN_DIR / "script.R").read_text(encoding="utf-8")
    assert rep.stdout == (RUN_DIR / "stdout.txt").read_text(encoding="utf-8")
    assert rep.stderr.startswith("NOTE: 2 observations removed")
    assert rep.attempt_outputs == [
        (RUN_DIR / "attempt-1" / "stdout.txt").read_text(encoding="utf-8"),
        (RUN_DIR / "attempt-2" / "stdout.txt").read_text(encoding="utf-8"),
        rep.stdout,
    ]
    assert rep.attempt_kinds == ["error", "claim", ""]
    assert (rep.n_error_refinements, rep.n_claim_refinements, rep.n_refinements) == (1, 1, 2)
    assert rep.n_executions == 3
    assert rep.n_files_stripped == 2
    assert rep.usage is None
    assert rep.claims == []
    assert rep.deviations == [
        "Dropped two districts with missing population density.",
        "Used HC1 rather than HC0 standard errors.",
    ]
    stages = rep.stages
    assert (stages.parsed, stages.claims_extracted, stages.dataset_extracted) == (True, None, None)
    assert (stages.dataset_downloaded, stages.code_generated, stages.code_executed) == (True, True, True)
    assert set(rep.artifacts) == {
        "reproduction.json",
        "render.json",
        "script.R",
        "stdout.txt",
        "stderr.txt",
        "attempt-1/script.R",
        "attempt-1/stdout.txt",
        "attempt-1/stderr.txt",
        "attempt-1/feedback.txt",
        "attempt-2/script.R",
        "attempt-2/stdout.txt",
        "attempt-2/stderr.txt",
        "attempt-2/feedback.txt",
    }


def test_cell_found_by_paper_source_when_the_reference_names_no_entry():
    assert _reproduce(name=None).outputs == {"beta": 3.7, "n_obs": 660.0}


def test_seeded_mode_reports_no_stripped_files(tmp_path):
    root = _copy_fixture(tmp_path)
    shutil.copytree(root / "fixture-paper" / "independent", root / "fixture-paper" / "seeded")
    _edit_manifest(root / "fixture-paper" / "seeded" / "run-a", mode="seeded")
    assert _reproduce(root, mode=ReproductionMode.SEEDED).n_files_stripped is None


def test_newest_finished_run_wins_and_render_only_runs_are_ignored(tmp_path, monkeypatch):
    root = _copy_fixture(tmp_path)
    cell = root / "fixture-paper" / "independent"
    shutil.copytree(cell / "run-a", cell / "run-b")
    _edit_manifest(cell / "run-b", run_id="run-b", finished_at="2026-10-23T09:00:00Z")
    (cell / "run-b" / "stdout.txt").write_text("RESULT:beta=1.5\nRESULT:n_obs=660\n", encoding="utf-8")
    (cell / "run-c").mkdir()  # rendered, not run: only render.json
    shutil.copy(cell / "run-a" / "render.json", cell / "run-c" / "render.json")
    monkeypatch.delenv(filesystem.RUN_ID_ENV, raising=False)
    assert _reproduce(root).outputs["beta"] == 1.5

    monkeypatch.setenv(filesystem.RUN_ID_ENV, "run-a")
    assert _reproduce(root).outputs["beta"] == 3.7
    monkeypatch.setenv(filesystem.RUN_ID_ENV, "run-c")
    with pytest.raises(ReproductionMissingError, match="run-c"):
        _reproduce(root)


def test_root_defaults_to_the_env_override(tmp_path, monkeypatch):
    monkeypatch.setenv(filesystem.ROOT_ENV, str(tmp_path))
    assert filesystem.claude_code().root == tmp_path
    monkeypatch.delenv(filesystem.ROOT_ENV)
    assert filesystem.claude_code().root == filesystem.REPRODUCTIONS_DIR
    assert FilesystemReproducer.name == "claude-code"


def test_missing_cell_raises_reproduction_missing(tmp_path):
    with pytest.raises(ReproductionMissingError, match=str(tmp_path)):
        _reproduce(tmp_path)
    with pytest.raises(ReproductionMissingError):
        _reproduce(tmp_path, name=None)


@pytest.mark.parametrize(
    ("change", "message"),
    [
        (lambda d: (d / "reproduction.json").write_text("{not json", encoding="utf-8"), "malformed JSON"),
        (lambda d: _edit_manifest(d, mode="seeded"), "mode is 'seeded'"),
        (lambda d: _edit_manifest(d, entry_id="other"), "entry_id is 'other'"),
        (lambda d: _edit_manifest(d, run_id="run-z"), "run_id is 'run-z'"),
        (lambda d: _edit_manifest(d, schema=2), "schema must be 1"),
        (lambda d: (d / "attempt-2" / "feedback.txt").unlink(), "feedback.txt"),
        (lambda d: (d / "stdout.txt").unlink(), "final.stdout"),
        (
            lambda d: _edit_manifest(d, attempts=[{"dir": "attempt-1", "exit_code": 1, "kind": "crash"}]),
            "kind is 'crash'",
        ),
        (
            lambda d: _edit_manifest(
                d,
                final={
                    "script": "/etc/passwd",
                    "stdout": "stdout.txt",
                    "stderr": "stderr.txt",
                    "exit_code": 0,
                },
            ),
            "must be relative",
        ),
        (
            lambda d: _edit_manifest(d, attempts=[{"dir": "../run-a/attempt-1", "exit_code": 1, "kind": ""}]),
            "without '..'",
        ),
        (
            lambda d: _edit_manifest(
                d,
                final={
                    "script": "script.R",
                    "stdout": "stdout.txt",
                    "stderr": "stderr.txt",
                    "exit_code": "0",
                },
            ),
            "exit_code must be an integer",
        ),
    ],
    ids=[
        "bad-json",
        "mode",
        "entry",
        "run-id",
        "schema",
        "no-feedback",
        "no-stdout",
        "bad-kind",
        "absolute",
        "dotdot",
        "exit-code",
    ],
)
def test_malformed_runs_fail_loudly_naming_the_file(tmp_path, change, message):
    root = _copy_fixture(tmp_path)
    run_dir = root / "fixture-paper" / "independent" / "run-a"
    change(run_dir)
    with pytest.raises(ValueError, match=message) as info:
        _reproduce(root)
    assert str(run_dir) in str(info.value)


def test_blind_cell_with_a_claim_attempt_is_rejected(tmp_path):
    root = _copy_fixture(tmp_path)
    shutil.move(root / "fixture-paper" / "independent", root / "fixture-paper" / "blind")
    _edit_manifest(root / "fixture-paper" / "blind" / "run-a", mode="blind")
    with pytest.raises(ValueError, match="blind mode forbids"):
        _reproduce(root, mode=ReproductionMode.BLIND)


def test_artifacts_skip_large_files_and_any_mount_tree(tmp_path):
    root = _copy_fixture(tmp_path)
    run_dir = root / "fixture-paper" / "independent" / "run-a"
    (run_dir / "big.log").write_bytes(b"x" * (filesystem.MAX_ARTIFACT_BYTES + 1))
    (run_dir / "mount" / "pkg").mkdir(parents=True)
    (run_dir / "mount" / "pkg" / "data.csv").write_text("a,b\n", encoding="utf-8")
    (run_dir / "task.md").write_text("# task\n", encoding="utf-8")
    artifacts = _reproduce(root).artifacts
    assert "big.log" not in artifacts
    assert "big.log" in artifacts["_skipped_artifacts.txt"]
    assert not any(k.startswith("mount/") for k in artifacts)
    assert artifacts["task.md"] == "# task\n"


# ── Through the runner ──────────────────────────────────────────────────


def test_claude_code_is_a_registered_reproducer():
    assert "claude-code" in runner.REPRODUCERS
    assert isinstance(runner.resolve_reproducer("claude-code")(), FilesystemReproducer)


def test_run_benchmark_scores_the_fixture_and_copies_its_artifacts(tmp_path):
    [row] = runner.run_benchmark(
        [_entry()],
        reproducer="claude-code",
        reproducer_factory=lambda: FilesystemReproducer(root=FIXTURE_ROOT),
        modes=("independent",),
        cache_dir=tmp_path / "cache",
        artifacts_root=tmp_path / "artifacts",
        run_id="score-1",
    )
    assert row.retally_ran is True and row.error is None
    assert row.reproducer == "claude-code"
    assert row.n_claims_with_paper_match == 2
    assert row.agrees_with_paper is True
    assert row.n_claims_with_paper_match_first_attempt == 0  # attempt 1 crashed
    assert row.n_claims_with_paper_match_first_scored == 1  # attempt 2: n_obs right, beta off
    assert row.first_scored_attempt_index == 1
    assert (row.n_executions, row.n_refinements) == (3, 2)
    assert (row.n_error_refinements, row.n_claim_refinements) == (1, 1)
    assert row.n_files_stripped == 2
    copied = tmp_path / "artifacts" / "fixture-paper" / "independent" / "claude-code" / "score-1"
    assert (copied / "reproduction.json").is_file()
    assert (copied / "attempt-2" / "feedback.txt").read_text(encoding="utf-8").startswith("beta:")
    assert row.artifacts_dir is not None and row.artifacts_dir.endswith("claude-code/score-1")


def test_missing_reproduction_is_an_uncached_skip(tmp_path):
    cache = tmp_path / "cache"
    [row] = runner.run_benchmark(
        [_entry()],
        reproducer="claude-code",
        reproducer_factory=lambda: FilesystemReproducer(root=tmp_path / "empty"),
        modes=("blind",),
        cache_dir=cache,
    )
    assert row.skipped is True
    assert row.skip_reason is runner.SkipReason.REPRODUCTION_MISSING
    assert str(tmp_path / "empty") in (row.error or "")
    assert row.retally_ran is None
    assert not cache.exists() or not list(cache.glob("*.json"))
    raw = runner._result_to_jsonable(row)
    assert raw["skip_reason"] == "reproduction_missing"
    assert runner._result_from_jsonable(raw).skip_reason is runner.SkipReason.REPRODUCTION_MISSING


@pytest.mark.parametrize("bad", ["json", "blind-claim"])
def test_invalid_reproduction_is_a_failed_row_with_the_message(tmp_path, bad):
    root = _copy_fixture(tmp_path)
    mode = "independent"
    run_dir = root / "fixture-paper" / "independent" / "run-a"
    if bad == "json":
        (run_dir / "reproduction.json").write_text("[", encoding="utf-8")
    else:
        mode = "blind"
        shutil.move(root / "fixture-paper" / "independent", root / "fixture-paper" / "blind")
        run_dir = root / "fixture-paper" / "blind" / "run-a"
        _edit_manifest(run_dir, mode="blind")
    [row] = runner.run_benchmark(
        [_entry()],
        reproducer="claude-code",
        reproducer_factory=lambda: FilesystemReproducer(root=root),
        modes=(mode,),
        cache_dir=tmp_path / "cache",
    )
    assert row.skipped is False
    assert row.retally_ran is False
    assert "reproduction.json" in (row.error or "")


@pytest.mark.parametrize(("argv", "use_cache"), [([], True), (["--no-cache"], False)])
def test_main_no_cache_flag(tmp_path, monkeypatch, argv, use_cache):
    seen = {}

    def fake_run_benchmark(catalog, **kwargs):
        seen.update(kwargs)
        return []

    monkeypatch.setattr(runner, "CATALOG_DIR", REPO_ROOT / "tests" / "fixtures" / "benchmark_placeholders")
    monkeypatch.setattr(runner, "RESULTS_DIR", tmp_path)
    monkeypatch.setattr(runner, "ARTIFACTS_DIR", tmp_path / "artifacts")
    monkeypatch.setattr(runner, "REPO_ROOT", tmp_path.parent)
    monkeypatch.setattr(runner, "run_benchmark", fake_run_benchmark)
    assert runner.main(["--reproducer", "claude-code", *argv]) == 0
    assert seen["use_cache"] is use_cache
    assert seen["reproducer"] == "claude-code"


# ── render_task ─────────────────────────────────────────────────────────


def _render(tmp_path, mode, entry=None, paper_text=None, run_id="r1"):
    return render_mod.render_task(
        entry or _entry(),
        mode,
        run_id,
        task_root=tmp_path / "tasks",
        reproductions_dir=tmp_path / "reproductions",
        package_dir=PACKAGE_DIR,
        paper_text=PAPER_STUB.read_text(encoding="utf-8") if paper_text is None else paper_text,
    )


def _task_files_text(task_dir: Path) -> str:
    """Every text file in the task directory except the mounted data."""
    return "\n".join(
        p.read_text(encoding="utf-8", errors="replace")
        for p in sorted(task_dir.rglob("*"))
        if p.is_file() and "mount" not in p.relative_to(task_dir).parts
    )


def test_render_seeded_task_carries_scripts_and_values(tmp_path):
    rendered = _render(tmp_path, "seeded")
    task = rendered.task_file.read_text(encoding="utf-8")
    assert "## Original Replication Scripts" in task
    assert "reghdfe lum warfare, absorb(state) cluster(district)" in task
    assert "1. beta: 3.713 [type: coefficient]" in task
    assert "## Independent Reproduction" not in task
    assert (rendered.mount_path / "code" / "master.do").is_file()
    assert rendered.render["n_files_stripped"] is None
    assert rendered.render["strip_manifest"] is None
    assert "3.713" in (rendered.task_file.parent / "paper.txt").read_text(encoding="utf-8")


def test_render_independent_task_has_values_but_no_scripts_on_disk(tmp_path):
    rendered = _render(tmp_path, "independent")
    task_dir = rendered.task_file.parent
    task = rendered.task_file.read_text(encoding="utf-8")
    assert "1. beta: 3.713 [type: coefficient]" in task
    assert "## Independent Reproduction" in task
    assert "## Blind Reproduction" not in task
    assert "## Original Replication Scripts" not in task
    assert "reghdfe" not in task and "feols(lum" not in task
    files = [p for p in rendered.mount_path.rglob("*") if p.is_file()]
    assert files and not any(reproducer_mod.is_script(p) for p in files)
    assert strip_rule.classify_tree(rendered.mount_path) == []
    # The strip manifest lives outside the task directory; nothing inside names a withheld file.
    manifest = Path(rendered.render["strip_manifest"])
    assert manifest.is_file() and task_dir not in manifest.parents
    assert json.loads(manifest.read_text(encoding="utf-8"))["n_stripped"] == 2
    assert rendered.render["n_files_stripped"] == 2
    assert not list(task_dir.rglob("*.retally-stripped.json"))
    everything = _task_files_text(task_dir)
    assert "master.do" not in everything and "main_tables" not in everything
    # render.json is written to both places.
    out = json.loads((rendered.output_dir / "render.json").read_text(encoding="utf-8"))
    assert (rendered.output_dir / "task.md").read_text(encoding="utf-8") == rendered.task_file.read_text(
        encoding="utf-8"
    )
    assert out == rendered.render
    assert out["mount_path"] == str(rendered.mount_path)
    assert out["paper_source"] == "fixture paper text"
    assert out["docker_image"] == "retally-sandbox-r:latest"


def test_render_blind_task_and_paper_carry_no_claim_value(tmp_path):
    rendered = _render(tmp_path, "blind")
    task = rendered.task_file.read_text(encoding="utf-8")
    paper = (rendered.task_file.parent / "paper.txt").read_text(encoding="utf-8")
    assert "## Blind Reproduction" in task
    assert "## Quantities to Compute" in task
    assert 'kind: "claim"` attempts are forbidden' in task
    numbers = [3.713, 0.305, 660.0]
    assert _leaks(task, "beta n_obs Table 1, col 1 Warfare and Development", numbers) == []
    assert _leaks(paper, "", numbers) == []
    assert "[withheld]" in paper
    assert rendered.render["paper_redactions"] >= 3


def test_render_refuses_to_overwrite_without_force(tmp_path):
    _render(tmp_path, "independent")
    with pytest.raises(FileExistsError):
        _render(tmp_path, "independent")
    render_mod.render_task(
        _entry(),
        "independent",
        "r1",
        task_root=tmp_path / "tasks",
        reproductions_dir=tmp_path / "reproductions",
        package_dir=PACKAGE_DIR,
        paper_text="text",
        force=True,
    )


def test_render_cli_prints_the_three_paths(tmp_path, monkeypatch, capsys):
    monkeypatch.setenv(filesystem.ROOT_ENV, str(tmp_path / "reproductions"))
    argv = [
        "--entry",
        CATALOG[0].id,
        "--mode",
        "blind",
        "--run-id",
        "cli",
        "--task-root",
        str(tmp_path / "tasks"),
        "--package-dir",
        str(PACKAGE_DIR),
        "--paper-text",
        str(PAPER_STUB),
    ]
    assert render_mod.main(argv) == 0
    task_file, mount, output_dir = capsys.readouterr().out.strip().splitlines()
    assert Path(task_file).is_file() and Path(mount).is_dir() and Path(output_dir).is_dir()
    assert Path(output_dir).parent.parent.parent == tmp_path / "reproductions"


def test_redaction_ignores_left_word_boundaries():
    text, n = render_mod.redact_values(
        "Table 5: 242.97** (17.82); clusters 36, year 1936", [-42.97, 17.82, 36.0]
    )
    assert "42.97" not in text and "17.82" not in text
    assert "clusters [withheld]," in text and "1936" in text
    assert n == 3


def test_blind_paper_redacts_percentage_forms_of_sub_unit_values(tmp_path):
    entry = _entry(
        original_claims=[bschema.OriginalClaim(description="share", value=0.224, claim_type="other")]
    )
    paper_text = "Founded in 1922. The share rose by 22.4% (22.40 percentage points) after treatment.\n"
    rendered = _render(tmp_path, "blind", entry=entry, paper_text=paper_text)
    paper = (rendered.task_file.parent / "paper.txt").read_text(encoding="utf-8")
    assert "22.4" not in paper and "22.40" not in paper
    assert "[withheld]% ([withheld] percentage points)" in paper
    assert "1922" in paper
    assert rendered.render["paper_redactions"] == 2


def test_catalog_has_pinned_claims_to_check():
    assert CATALOG


@pytest.mark.parametrize("entry", CATALOG, ids=lambda e: e.id)
def test_blind_task_for_every_catalog_entry_leaks_no_value(tmp_path, entry):
    numbers = [oc.value for oc in entry.original_claims]
    numbers += [oc.standard_error for oc in entry.original_claims if oc.standard_error is not None]
    # A paper text that prints every value and SE, plain and with a glued minus-as-"2".
    stub = "\n".join(f"{form} 2{form} ({form})" for v in numbers for form in sorted(_value_strings(v)))
    rendered = _render(tmp_path, "blind", entry=entry, paper_text=stub)
    task = rendered.task_file.read_text(encoding="utf-8")
    paper = (rendered.task_file.parent / "paper.txt").read_text(encoding="utf-8")
    curated = (
        "\n".join(
            " ".join(str(part).split())
            for oc in entry.original_claims
            for part in (oc.description, oc.location or "", oc.context or "", oc.unit or "")
        )
        + "\n"
        + (entry.paper.title or entry.id)
    )
    with_n = numbers + [float(oc.sample_size) for oc in entry.original_claims if oc.sample_size is not None]
    assert _leaks(task, curated, with_n, percent=False) == []
    assert _leaks(paper, "", numbers) == []
    for oc in entry.original_claims:
        assert oc.description in task


# ── check_attempt ───────────────────────────────────────────────────────

MONTERO = "montero-2022-cooperative-property-rights"


def _render_json(tmp_path: Path, mode: str) -> Path:
    run_dir = tmp_path / "run"
    run_dir.mkdir()
    (run_dir / "render.json").write_text(json.dumps({"entry_id": MONTERO, "mode": mode}), encoding="utf-8")
    return run_dir


def test_check_attempt_independent_prints_the_pipeline_claim_gap(tmp_path, capsys):
    run_dir = _render_json(tmp_path, "independent")
    stdout = tmp_path / "stdout.txt"
    stdout.write_text("RESULT:earnings_level_above500_bw300=10.0\n", encoding="utf-8")
    assert check_mod.main(["--run-dir", str(run_dir), "--stdout", str(stdout)]) == 0
    out = capsys.readouterr().out
    assert "earnings_level_above500_bw300: reproduced 10.0, claimed 60.49 (tolerance" in out
    assert "n_clusters_bw150: reproduced N/A, claimed 36" in out


def test_check_attempt_blind_prints_names_only(tmp_path, capsys):
    run_dir = _render_json(tmp_path, "blind")
    stdout = tmp_path / "stdout.txt"
    stdout.write_text("RESULT:earnings_level_above500_bw300=10.0\n", encoding="utf-8")
    assert check_mod.main(["--run-dir", str(run_dir), "--stdout", str(stdout)]) == 0
    out = capsys.readouterr().out
    assert out.startswith("missing: earnings_level_above500_bw150, ")
    assert "earnings_level_above500_bw300" not in out
    entry = next(e for e in CATALOG if e.id == MONTERO)
    numbers = [oc.value for oc in entry.original_claims]
    numbers += [oc.standard_error for oc in entry.original_claims if oc.standard_error is not None]
    assert _leaks(out, "", numbers) == []
    assert "tolerance" not in out and "claimed" not in out
    # The only digits are those inside the claim names (bw300, above500, ...).
    names = " ".join(oc.description for oc in entry.original_claims)
    assert all(tok in names for tok in out.removeprefix("missing: ").strip().split(", "))


# ── Report: several results files ───────────────────────────────────────


def _row(entry_id, mode, reproducer, passed):
    return {
        "entry_id": entry_id,
        "mode": mode,
        "reproducer": reproducer,
        "skipped": False,
        "retally_ran": True,
        "agrees_with_paper": passed,
        "n_claims_in_catalog": 1,
        "n_claims_with_paper_match": int(passed),
        "claim_details": [
            {
                "description": "beta",
                "claim_type": "coefficient",
                "claimed": 1.0,
                "reproduced": 1.0 if passed else 2.0,
                "tolerance": 0.1,
                "rel_err": 0.0 if passed else 1.0,
                "passed": passed,
            }
        ],
        "components": {},
    }


def test_report_concatenates_several_results_files(tmp_path, monkeypatch):
    a = tmp_path / "pipeline.json"
    b = tmp_path / "claude.json"
    a.write_text(
        json.dumps(
            {"results": [_row("p", "seeded", "pipeline", True), _row("p", "independent", "pipeline", False)]}
        ),
        encoding="utf-8",
    )
    b.write_text(
        json.dumps(
            {
                "results": [
                    _row("p", "seeded", "claude-code", True),
                    _row("p", "independent", "claude-code", True),
                    {
                        "entry_id": "q",
                        "mode": "independent",
                        "reproducer": "claude-code",
                        "skipped": True,
                        "skip_reason": "reproduction_missing",
                        "error": "no run",
                    },
                ]
            }
        ),
        encoding="utf-8",
    )
    out_dir = tmp_path / "out"
    monkeypatch.setattr(report, "RESULTS_DIR", out_dir)
    monkeypatch.setattr(report, "REPO_ROOT", tmp_path)
    assert report.main([str(a), str(b)]) == 0
    md = (out_dir / "REPORT.md").read_text(encoding="utf-8")
    assert "**claude-code**" in md and "**pipeline**" in md
    assert "reproduction_missing=1" in md
    # The mode-gap table shows one line per reproducer, not one overwriting the other.
    assert "| `p` | dev | claude-code | 1/1 | 1/1 |" in md
    assert "| `p` | dev | pipeline | 1/1 | 0/1 |" in md
    assert "skipped: reproduction_missing" in md
    assert (out_dir / "report.html").is_file()


def test_report_single_mode_two_reproducers_shows_the_reproducer_column():
    md = report.render_markdown(
        [_row("p", "blind", "pipeline", True), _row("p", "blind", "claude-code", False)]
    )
    assert "| `p` | blind | pipeline |" in md and "| `p` | blind | claude-code |" in md


def test_report_main_without_paths_reads_the_default(tmp_path, monkeypatch):
    monkeypatch.setattr(report, "RESULTS_DIR", tmp_path)
    monkeypatch.setattr(report, "REPO_ROOT", tmp_path.parent)
    assert report.main([]) == 1  # no results.json yet
    (tmp_path / "results.json").write_text(
        json.dumps([_row("p", "seeded", "pipeline", True)]), encoding="utf-8"
    )
    assert report.main([]) == 0
    assert (tmp_path / "REPORT.md").is_file()


def test_nothing_rendered_into_the_repository(tmp_path):
    """The tests above wrote only under tmp_path (render_task's defaults are gitignored anyway)."""
    assert not (REPO_ROOT / "benchmark" / "reproductions" / "fixture-paper").exists()
    assert os.path.isdir(FIXTURE_ROOT)
