"""Tests for the reference-code file selector."""

from __future__ import annotations

from pathlib import Path

from retally.code.selector import (
    MAX_FILE_BYTES,
    MAX_FILES,
    MAX_SCRIPT_FILE_BYTES,
    MAX_TOTAL_BYTES,
    select_package_scripts,
    select_relevant_files,
)


def _write(root: Path, rel: str, contents: str = "print('hi')\n") -> None:
    p = root / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(contents, encoding="utf-8")


# ── Basic happy paths ───────────────────────────────────────────────────


def test_returns_empty_for_missing_directory(tmp_path):
    assert select_relevant_files(tmp_path / "does-not-exist") == []


def test_returns_empty_for_repo_with_no_python(tmp_path):
    _write(tmp_path, "README.md", "# hi")
    _write(tmp_path, "data.csv", "a,b\n1,2")
    assert select_relevant_files(tmp_path) == []


def test_picks_root_python_files(tmp_path):
    _write(tmp_path, "main.py", "x = 1\n")
    _write(tmp_path, "model.py", "y = 2\n")
    selected = select_relevant_files(tmp_path)
    paths = {f.relative_path for f in selected}
    assert paths == {"main.py", "model.py"}


# ── Priority and ordering ──────────────────────────────────────────────


def test_preferred_stems_outrank_random_names(tmp_path):
    _write(tmp_path, "train.py", "# train")
    _write(tmp_path, "utils.py", "# utils")
    _write(tmp_path, "helpers.py", "# helpers")
    selected = select_relevant_files(tmp_path)
    # train.py should rank first because it has the preferred-stem bonus.
    assert selected[0].relative_path == "train.py"


def test_root_files_outrank_deeper_files(tmp_path):
    _write(tmp_path, "main.py", "# top-level")
    _write(tmp_path, "src/model.py", "# deeper")
    selected = select_relevant_files(tmp_path)
    assert selected[0].relative_path == "main.py"


def test_preferred_stem_at_depth_outranks_root_random_name(tmp_path):
    # train.py at depth 1 (score 10) still outranks foo.py at depth 0 (score 5).
    _write(tmp_path, "foo.py", "# random root file")
    _write(tmp_path, "src/train.py", "# nested but preferred")
    selected = select_relevant_files(tmp_path)
    assert selected[0].relative_path == "src/train.py"


def test_ordering_is_deterministic(tmp_path):
    # Two files with identical priority/depth should sort by path.
    _write(tmp_path, "b_runner.py", "# b")
    _write(tmp_path, "a_runner.py", "# a")
    selected = select_relevant_files(tmp_path)
    paths = [f.relative_path for f in selected]
    assert paths == ["a_runner.py", "b_runner.py"]


# ── Skips ──────────────────────────────────────────────────────────────


def test_skips_init_py(tmp_path):
    _write(tmp_path, "model.py", "x = 1\n")
    _write(tmp_path, "__init__.py", "")
    paths = {f.relative_path for f in select_relevant_files(tmp_path)}
    assert paths == {"model.py"}


def test_skips_unit_tests(tmp_path):
    _write(tmp_path, "train.py", "# train")
    _write(tmp_path, "test_train.py", "# test")
    _write(tmp_path, "train_test.py", "# also test")
    paths = {f.relative_path for f in select_relevant_files(tmp_path)}
    assert paths == {"train.py"}


def test_skips_setup_and_conftest(tmp_path):
    _write(tmp_path, "main.py", "x = 1")
    _write(tmp_path, "setup.py", "from setuptools import setup")
    _write(tmp_path, "conftest.py", "import pytest")
    paths = {f.relative_path for f in select_relevant_files(tmp_path)}
    assert paths == {"main.py"}


def test_skips_known_noisy_directories(tmp_path):
    _write(tmp_path, "main.py", "# real")
    _write(tmp_path, ".git/HEAD", "ref: ...")
    _write(tmp_path, "docs/source.py", "# doc")
    _write(tmp_path, "tests/test_foo.py", "# test")
    _write(tmp_path, "notebooks/explore.py", "# notebook")
    _write(tmp_path, "examples/demo.py", "# example")
    _write(tmp_path, "__pycache__/main.cpython.py", "# cache")
    paths = {f.relative_path for f in select_relevant_files(tmp_path)}
    assert paths == {"main.py"}


def test_skips_empty_files(tmp_path):
    _write(tmp_path, "train.py", "# train")
    _write(tmp_path, "empty.py", "")
    paths = {f.relative_path for f in select_relevant_files(tmp_path)}
    assert paths == {"train.py"}


# ── Size limits ────────────────────────────────────────────────────────


def test_skips_files_larger_than_per_file_cap(tmp_path):
    _write(tmp_path, "tiny.py", "x = 1\n")
    _write(tmp_path, "huge.py", "x = 1\n" * (MAX_FILE_BYTES // 6 + 1))
    paths = {f.relative_path for f in select_relevant_files(tmp_path)}
    assert "tiny.py" in paths
    assert "huge.py" not in paths


def test_respects_max_files_cap(tmp_path):
    for i in range(MAX_FILES + 5):
        _write(tmp_path, f"file_{i:02d}.py", f"x = {i}\n")
    selected = select_relevant_files(tmp_path)
    assert len(selected) == MAX_FILES


def test_respects_total_bytes_cap(tmp_path):
    # Each file is just under the per-file cap; 12 of them would exceed
    # the total budget.  Selector must stop before that.
    chunk = "x = 1\n" * (MAX_FILE_BYTES // 6 - 10)
    for i in range(12):
        _write(tmp_path, f"file_{i:02d}.py", chunk)
    selected = select_relevant_files(tmp_path)
    total = sum(f.size_bytes for f in selected)
    assert total <= MAX_TOTAL_BYTES


# ── File contents ──────────────────────────────────────────────────────


def test_contents_round_trip_unchanged(tmp_path):
    body = "def main():\n    print('Hello, paper!')\n"
    _write(tmp_path, "main.py", body)
    [selected] = select_relevant_files(tmp_path)
    assert selected.contents == body
    assert selected.size_bytes == len(body.encode("utf-8"))


def test_non_utf8_file_is_skipped(tmp_path):
    # A binary .py would fail UnicodeDecodeError on read; selector must
    # skip rather than raise.
    (tmp_path / "good.py").write_text("x = 1\n", encoding="utf-8")
    (tmp_path / "bad.py").write_bytes(b"\xff\xfe\x00 not valid utf-8")
    selected = select_relevant_files(tmp_path)
    paths = {f.relative_path for f in selected}
    assert paths == {"good.py"}


# ── Replication-package script selection ────────────────────────────────


def test_package_scripts_empty_for_none_and_missing(tmp_path):
    assert select_package_scripts(None) == []
    assert select_package_scripts(tmp_path / "does-not-exist") == []


def test_package_scripts_empty_when_only_data(tmp_path):
    _write(tmp_path, "data/districts.csv", "id,lum\n1,2.0")
    _write(tmp_path, "README.txt", "replication package")
    assert select_package_scripts(tmp_path) == []


def test_package_scripts_picks_r_do_and_rmd(tmp_path):
    _write(tmp_path, "analysis.R", "library(fixest)\n")
    _write(tmp_path, "tables.do", "reghdfe y x, absorb(fe)\n")
    _write(tmp_path, "report.Rmd", "```{r}\nsummary(m)\n```\n")
    _write(tmp_path, "data.csv", "a,b\n1,2")
    paths = {f.relative_path for f in select_package_scripts(tmp_path)}
    assert paths == {"analysis.R", "tables.do", "report.Rmd"}


def test_package_scripts_suffix_match_is_case_insensitive(tmp_path):
    _write(tmp_path, "wii_replication.DO", "reg y x\n")
    paths = {f.relative_path for f in select_package_scripts(tmp_path)}
    assert paths == {"wii_replication.DO"}


def test_package_scripts_preferred_substrings_rank_first(tmp_path):
    _write(tmp_path, "code/utils.R", "# helpers\n")
    _write(tmp_path, "code/main_tables.R", "feols(y ~ x | fe, data)\n")
    selected = select_package_scripts(tmp_path)
    assert selected[0].relative_path == "code/main_tables.R"


def test_package_scripts_figures_rank_below_tables(tmp_path):
    # The figure penalty must outweigh the depth bonus: a root-level
    # figures script still ranks below a nested tables script.
    _write(tmp_path, "figures.do", "graph twoway ...\n")
    _write(tmp_path, "code/tables.do", "reghdfe y x, absorb(fe)\n")
    selected = select_package_scripts(tmp_path)
    assert selected[0].relative_path == "code/tables.do"


def test_package_scripts_skip_oversized_and_empty_files(tmp_path):
    _write(tmp_path, "master.do", "x" * (MAX_SCRIPT_FILE_BYTES + 1))
    _write(tmp_path, "empty.R", "")
    _write(tmp_path, "analysis.R", "lm(y ~ x)\n")
    paths = {f.relative_path for f in select_package_scripts(tmp_path)}
    assert paths == {"analysis.R"}


def test_package_scripts_respect_skip_dirs(tmp_path):
    _write(tmp_path, "docs/examples.R", "# doc example\n")
    _write(tmp_path, "analysis.R", "lm(y ~ x)\n")
    paths = {f.relative_path for f in select_package_scripts(tmp_path)}
    assert paths == {"analysis.R"}


def test_package_scripts_tolerate_non_utf8_bytes(tmp_path):
    # Old Stata do-files are frequently Latin-1; selection must not crash.
    p = tmp_path / "master.do"
    p.write_bytes(b"* Autor: Jos\xe9\nreg y x\n")
    selected = select_package_scripts(tmp_path)
    assert len(selected) == 1
    assert "reg y x" in selected[0].contents


def test_package_scripts_respect_total_byte_budget(tmp_path):
    # Four files that each clear the per-file cap but together exceed
    # the shared total: only three fit inside MAX_TOTAL_BYTES.
    chunk = "y" * (MAX_SCRIPT_FILE_BYTES - 1_000)
    n_fit = MAX_TOTAL_BYTES // len(chunk)
    for i in range(n_fit + 1):
        _write(tmp_path, f"analysis_{i}.R", chunk)
    selected = select_package_scripts(tmp_path)
    assert len(selected) == n_fit
