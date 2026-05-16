"""Tests for CodeExecutor."""

import pytest
from pathlib import Path
from unittest.mock import MagicMock

from paper_validator.codegen.executor import CodeExecutor
from paper_validator.models import Dataset, ExecutionResult


@pytest.fixture
def executor():
    return CodeExecutor(timeout=10)


@pytest.fixture
def dummy_dataset(tmp_path):
    return Dataset(
        name="dummy",
        source_url="",
        local_path=tmp_path,
    )


def test_execute_simple_code(executor, dummy_dataset):
    code = "print('RESULT:accuracy=0.95')"
    result = executor.execute(code, dummy_dataset)
    assert result.exit_code == 0
    assert result.outputs.get("accuracy") == pytest.approx(0.95)


def test_execute_captures_stderr(executor, dummy_dataset):
    code = "import sys; sys.stderr.write('an error\\n')"
    result = executor.execute(code, dummy_dataset)
    assert "an error" in result.stderr


def test_execute_timeout(executor, dummy_dataset):
    executor.timeout = 1
    code = "import time; time.sleep(10)"
    result = executor.execute(code, dummy_dataset)
    assert result.timed_out


def test_preflight_rejects_subprocess_import(executor):
    code = "import subprocess\nsubprocess.run(['ls'])"
    with pytest.raises(ValueError, match="Forbidden"):
        executor._preflight_check(code)


def test_parse_outputs_handles_multiple_results(executor):
    stdout = "training...\nRESULT:accuracy=0.87\nRESULT:f1_score=0.83\ndone"
    outputs = executor._parse_outputs(stdout)
    assert outputs["accuracy"] == pytest.approx(0.87)
    assert outputs["f1_score"] == pytest.approx(0.83)


def test_parse_outputs_skips_malformed_lines(executor):
    stdout = "RESULT:bad_line\nRESULT:ok=0.5"
    outputs = executor._parse_outputs(stdout)
    assert "ok" in outputs
    assert "bad_line" not in outputs


def test_execute_nonzero_exit_on_error(executor, dummy_dataset):
    code = "raise RuntimeError('boom')"
    result = executor.execute(code, dummy_dataset)
    assert result.exit_code != 0
    assert "boom" in result.stderr


def test_preflight_allows_numpy_import(executor):
    code = "import numpy as np\nprint('ok')"
    executor._preflight_check(code)  # should not raise
