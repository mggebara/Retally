"""Evidence bundles (``benchmark.evidence``): built from fake rows, artifacts and run dirs in tmp_path.

No API, Docker or network: the "runs" are files written by the test.
"""

from __future__ import annotations

import json
from pathlib import Path

from tests._loaders import REPO_ROOT, load_module_from_path

load_module_from_path("benchmark.schema", REPO_ROOT / "benchmark" / "schema.py")
load_module_from_path("benchmark.pricing", REPO_ROOT / "benchmark" / "pricing.py")
load_module_from_path("benchmark.metrics", REPO_ROOT / "benchmark" / "metrics.py")
load_module_from_path("benchmark.reproducer", REPO_ROOT / "benchmark" / "reproducer.py")
load_module_from_path("benchmark.runner", REPO_ROOT / "benchmark" / "runner.py")
evidence = load_module_from_path("benchmark.evidence", REPO_ROOT / "benchmark" / "evidence.py")

ENTRY = "fake-2024-evidence"
PAPER = "Fake Paper\n\n" + "We regress outcomes on treatment with district fixed effects. " * 60

CATALOG_YAML = f"""\
id: {ENTRY}
i4r_report_url: https://example.org/i4r
language: r
outcome_label: reproducible
paper:
  source: https://example.org/paper.pdf
  title: Fake Paper
  authors: [A. Author]
original_claims:
  - description: treatment_coef
    value: 0.50
    standard_error: 0.10
    claim_type: coefficient
    location: Table 1, col 1
  - description: n_obs
    value: 1000
    claim_type: other
    location: Table 1
i4r_replicator_findings:
  - claim_id: 0
    reproduced_value: 0.49
    outcome: matches
"""


def _detail(name: str, claimed: float, reproduced: float | None, passed: bool, tol: float, src: str) -> dict:
    rel = None if reproduced is None else abs(reproduced - claimed) / abs(claimed)
    return {
        "description": name,
        "claim_type": "coefficient" if name == "treatment_coef" else "other",
        "claimed": claimed,
        "reproduced": reproduced,
        "tolerance": tol,
        "rel_err": rel,
        "passed": passed,
        "passed_first_attempt": passed,
        "passed_first_scored": passed,
        "tolerance_source": src,
    }


def _setup(tmp_path: Path) -> tuple[Path, Path, Path]:
    """A source checkout: one pipeline (oracle) cell, two agent cells; returns (root, catalog, results)."""
    root = tmp_path / "src"
    catalog = tmp_path / "papers"
    catalog.mkdir()
    (catalog / f"{ENTRY}.yaml").write_text(CATALOG_YAML, encoding="utf-8")

    # Pipeline cell, independent mode, answered by an LLM oracle labelled "oracle-x".
    art_p = root / "benchmark/results/artifacts" / ENTRY / "independent/pipeline/20260101T000000Z"
    (art_p / "attempt-1").mkdir(parents=True)
    prompt = "Reproduce this.\n\n## Paper\n" + PAPER + "\n\nWrite R."
    (art_p / "prompt-1.txt").write_text(prompt, encoding="utf-8")
    (art_p / "script.R").write_text("cat('RESULT:treatment_coef=0.55\\n')\n", encoding="utf-8")
    (art_p / "stdout.txt").write_text("RESULT:treatment_coef=0.55\nRESULT:n_obs=980\n", encoding="utf-8")
    (art_p / "stderr.txt").write_text("", encoding="utf-8")
    (art_p / "attempt-1" / "script.R").write_text("stop('x')\n", encoding="utf-8")
    (art_p / "attempt-1" / "stdout.txt").write_text("", encoding="utf-8")
    (art_p / "big.log").write_text("x" * (evidence.MAX_COPY_BYTES + 1), encoding="utf-8")
    (art_p / "extract.dta").write_bytes(b"\x00\x01data")
    answers = root / "benchmark/.cache/llm-oracle/oracle-x/answers"
    answers.mkdir(parents=True)
    kwargs = {
        "model": "claude-opus-5-5",
        "max_tokens": 16384,
        "messages": [{"role": "user", "content": prompt}],
        "output_config": {"effort": "high"},
    }
    (answers / f"{evidence.request_key(kwargs)}.json").write_text(
        json.dumps({"model": "oracle-x", "text": "```r\ncat('RESULT:treatment_coef=0.55')\n```"}),
        encoding="utf-8",
    )

    # Two agent cells (independent and blind runs) sharing the unredacted paper text.
    rows = [
        {
            "entry_id": ENTRY,
            "mode": "independent",
            "reproducer": "pipeline",
            "skipped": False,
            "n_claims_with_paper_match": 1,
            "n_claims_with_paper_match_first_scored": 1,
            "n_executions": 2,
            "usage": {"api_calls": 2, "by_model": {"oracle-x": {"api_calls": 2}}},
            "artifacts_dir": str(art_p.relative_to(root)),
            "claim_details": [
                _detail("treatment_coef", 0.5, 0.55, True, 0.2, "se_band"),
                _detail("n_obs", 1000, 980, False, 0.01, "relative"),
            ],
        },
        {"entry_id": ENTRY, "mode": "seeded", "skipped": True, "skip_reason": "out_of_scope"},
    ]
    for run, stamp in (("2026-01-02-a", "20260102T000000Z"), ("2026-01-03-a", "20260103T000000Z")):
        task_dir = root / "benchmark/.cache/claude-code" / ENTRY / "independent" / run
        task_dir.mkdir(parents=True)
        (task_dir / "paper.txt").write_text(PAPER, encoding="utf-8")
        (task_dir / "mount").mkdir()
        (task_dir / "mount" / "data.csv").write_text("a,b\n1,2\n", encoding="utf-8")
        art_a = root / "benchmark/results/artifacts" / ENTRY / "independent/claude-code" / stamp
        art_a.mkdir(parents=True)
        (art_a / "task.md").write_text(f"# Task\nPaper text: `{task_dir / 'paper.txt'}`\n", encoding="utf-8")
        (art_a / "render.json").write_text(
            json.dumps({"run_id": run, "task_dir": str(task_dir), "paper_redactions": None}), encoding="utf-8"
        )
        (art_a / "script.R").write_text("cat('RESULT:treatment_coef=0.9\\n')\n", encoding="utf-8")
        (art_a / "stdout.txt").write_text(
            "RESULT:treatment_coef=0.9\nRESULT:n_obs=1000\nDEVIATION: used HC1\n", encoding="utf-8"
        )
        (art_a / "stderr.txt").write_text("", encoding="utf-8")
        (art_a / "reproduction.json").write_text(
            json.dumps(
                {
                    "schema": 1,
                    "entry_id": ENTRY,
                    "mode": "independent",
                    "run_id": run,
                    "deviations": ["no weights"],
                }
            ),
            encoding="utf-8",
        )
        rows.append(
            {
                "entry_id": ENTRY,
                "mode": "independent",
                "reproducer": "claude-code",
                "skipped": False,
                "n_claims_with_paper_match": 1,
                "artifacts_dir": str(art_a.relative_to(root)),
                "claim_details": [
                    _detail("treatment_coef", 0.5, 0.9, False, 0.2, "se_band"),
                    _detail("n_obs", 1000, 1000, True, 0.01, "relative"),
                ],
            }
        )
    # The second agent row's run directory is gone; only its scored copy remains (still complete).
    results = tmp_path / "results.json"
    results.write_text(json.dumps({"usage": {}, "results": rows}), encoding="utf-8")
    return root, catalog, results


def _build(tmp_path: Path) -> tuple[Path, list[dict]]:
    root, catalog, results = _setup(tmp_path)
    out = tmp_path / "evidence"
    built = evidence.build([results], out_root=out, source_root=root, catalog_dir=catalog)
    return out, built


def test_build_writes_one_cell_per_non_skipped_row(tmp_path: Path) -> None:
    out, built = _build(tmp_path)
    cells = sorted(b["cell"] for b in built)
    assert cells == [
        f"{ENTRY}/independent/claude-code/2026-01-02-a",
        f"{ENTRY}/independent/claude-code/2026-01-03-a",
        f"{ENTRY}/independent/pipeline-oracle-x/20260101T000000Z",
    ]
    pipe = out / ENTRY / "independent/pipeline-oracle-x/20260101T000000Z"
    for name in ("prompt/prompt-1.txt", "output/script.R", "output/stdout.txt", "output/attempt-1/script.R"):
        assert (pipe / name).is_file(), name
    # The oracle's raw reply, found by request key.
    assert "```r" in (pipe / "output/answer-1.md").read_text(encoding="utf-8")
    agent = out / ENTRY / "independent/claude-code/2026-01-02-a"
    assert (agent / "prompt/task.md").is_file()
    assert (agent / "output/reproduction.json").is_file()
    cell_md = (agent / "CELL.md").read_text(encoding="utf-8")
    assert "no weights" in cell_md and "used HC1" in cell_md


def test_scoring_verdicts_equal_the_rows(tmp_path: Path) -> None:
    out, _ = _build(tmp_path)
    for scoring_path in (out / ENTRY).glob("*/*/*/scoring.json"):
        scoring = json.loads(scoring_path.read_text(encoding="utf-8"))
        assert scoring["summary"]["disagreements"] == []
        for rec in scoring["claims"]:
            assert rec["recomputed"]["passed"] == rec["row"]["passed"]
            assert rec["agrees_with_row"] is True
            assert rec["ground_truth"]["location"]
    pipe = json.loads(
        (out / ENTRY / "independent/pipeline-oracle-x/20260101T000000Z/scoring.json").read_text(
            encoding="utf-8"
        )
    )
    coef = pipe["claims"][0]
    assert coef["recomputed"]["band_source"] == "se_band"
    assert abs(coef["recomputed"]["band_absolute"] - 0.10) < 1e-12
    assert coef["recomputed"]["result_name"] == "treatment_coef"
    assert coef["i4r"]["reproduced_value"] == 0.49


def test_paper_text_is_stored_once_and_referenced(tmp_path: Path) -> None:
    out, _ = _build(tmp_path)
    papers = sorted(p.name for p in (out / ENTRY).glob("paper*.txt"))
    assert papers == ["paper.txt"]
    assert (out / ENTRY / "paper.txt").read_text(encoding="utf-8") == PAPER
    prompt = (out / ENTRY / "independent/pipeline-oracle-x/20260101T000000Z/prompt/prompt-1.txt").read_text(
        encoding="utf-8"
    )
    assert PAPER not in prompt
    assert f"[paper text: {ENTRY}/paper.txt, {len(PAPER)} chars, sha256 " in prompt
    ref = (out / ENTRY / "independent/claude-code/2026-01-02-a/prompt/paper.txt.ref").read_text(
        encoding="utf-8"
    )
    assert f"{ENTRY}/paper.txt" in ref


def test_oversize_and_data_files_are_listed_not_copied(tmp_path: Path) -> None:
    out, _ = _build(tmp_path)
    pipe = out / ENTRY / "independent/pipeline-oracle-x/20260101T000000Z"
    assert not (pipe / "output/big.log").exists()
    assert not (pipe / "output/extract.dta").exists()
    cell_md = (pipe / "CELL.md").read_text(encoding="utf-8")
    assert "big.log" in cell_md and "over the 2 MB limit" in cell_md
    assert "extract.dta" in cell_md
    # Nothing from a data mount ever lands in the tree.
    assert not list(out.rglob("data.csv"))


def test_missing_artifacts_are_reported_not_fatal(tmp_path: Path) -> None:
    root, catalog, results = _setup(tmp_path)
    payload = json.loads(results.read_text(encoding="utf-8"))
    payload["results"][0]["artifacts_dir"] = "benchmark/results/artifacts/gone/20250101T000000Z"
    results.write_text(json.dumps(payload), encoding="utf-8")
    out = tmp_path / "evidence"
    built = evidence.build([results], out_root=out, source_root=root, catalog_dir=catalog)
    partial = [b for b in built if not b["complete"]]
    assert len(partial) == 1
    cell_md = next((out / ENTRY / "independent").glob("pipeline-oracle-x/*/CELL.md")).read_text(
        encoding="utf-8"
    )
    assert "missing on disk" in cell_md and "## Missing" in cell_md


def test_report_renders(tmp_path: Path) -> None:
    out, _ = _build(tmp_path)
    catalog = tmp_path / "papers"
    written = evidence.report(out, catalog_dir=catalog)
    report_md = (out / ENTRY / "REPORT.md").read_text(encoding="utf-8")
    assert out / ENTRY / "REPORT.md" in written
    assert "## Pinned claims" in report_md and "0.49" in report_md
    assert "## Pass counts: mode × reproducer × run" in report_md
    assert "independent/claude-code/2026-01-02-a/CELL.md" in report_md
    assert "## What to hand-check" in report_md
    # The pipeline passed treatment_coef in its one run; the agent failed it in both.
    assert "`treatment_coef` — pipeline 1/1, agent 0/2" in report_md
    assert "no weights" in report_md
    index = (out / "INDEX.md").read_text(encoding="utf-8")
    assert f"{ENTRY}/REPORT.md" in index


def test_normalise_paths_rewrites_repo_worktree_and_scratch() -> None:
    roots = evidence.repo_roots(Path("/opt/Retally"))
    text = (
        "data: /opt/Retally/benchmark/.cache/x/mount\n"
        'root "/opt/Retally"\n'
        "wt: /opt/Retally/.claude/worktrees/agent-abc123/benchmark/runner.py\n"
        "scratch: /private/tmp/claude-501/-home-u-Retally/0f1e/scratchpad/brief.md\n"
        "other: /opt/RetallyOld/file and /tmp/claude-501/foo\n"
        "home: /Users/someone/.claude/projects/x/tool-results/a.txt\n"
    )
    out = evidence.normalise_paths(text, roots)
    assert "data: <repo>/benchmark/.cache/x/mount" in out
    assert 'root "<repo>"' in out
    assert "wt: <worktree>/benchmark/runner.py" in out
    assert "scratch: <scratch>/brief.md" in out
    # A sibling directory that merely shares the prefix is left alone.
    assert "/opt/RetallyOld/file" in out
    assert "home: <home>/.claude/projects/x/tool-results/a.txt" in out
    assert "<scratch>/foo" in out
    # The module's own checkout (and its main checkout, if a worktree) is always a root.
    assert str(evidence.REPO_ROOT) in evidence.repo_roots()


def test_normalise_paths_rewrites_home_paths_without_a_plain_user_name() -> None:
    text = (
        'global main "/Users/`c(username)\'/Downloads/Replication"\n'
        'else global main "C:/Users/`c(username)\'/Downloads/Replication"\n'
        'global PROJECT_ROOT "/Users/..."\n'
    )
    out = evidence.normalise_paths(text, [])
    assert "/Users/" not in out
    assert 'global main "<home>/Downloads/Replication"' in out
    assert 'global PROJECT_ROOT "<home>/"' in out


def test_built_tree_has_no_absolute_source_paths(tmp_path: Path) -> None:
    out, _ = _build(tmp_path)
    root = str((tmp_path / "src").resolve())
    task = (out / ENTRY / "independent/claude-code/2026-01-02-a/prompt/task.md").read_text(encoding="utf-8")
    assert "<repo>/benchmark/.cache/claude-code/" in task
    for path in out.rglob("*"):
        if path.is_file():
            text = path.read_text(encoding="utf-8")
            assert root not in text, path
            assert str(tmp_path) not in text, path
