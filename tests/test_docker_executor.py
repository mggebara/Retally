"""Tests for DockerExecutor.

Tests that do not require Docker to be running are always enabled.
Tests that actually spin up containers are gated by the ``requires_docker``
mark — they are skipped when Docker or the sandbox image is unavailable.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

import pytest

from openra.codegen.docker_executor import DEFAULT_IMAGE, DockerExecutor
from openra.models import Dataset

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _docker_and_image_available() -> bool:
    """Return True if Docker daemon is up AND sandbox image exists."""
    try:
        result = subprocess.run(
            ["docker", "image", "inspect", DEFAULT_IMAGE],
            capture_output=True,
            timeout=10,
        )
        return result.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


requires_docker = pytest.mark.skipif(
    not _docker_and_image_available(),
    reason="Docker not running or sandbox image not built (run 'make build-sandbox')",
)


@pytest.fixture
def executor():
    return DockerExecutor(timeout=30)


@pytest.fixture
def dummy_dataset(tmp_path):
    (tmp_path / "data.csv").write_text("a,b\n1,2\n")
    return Dataset(name="dummy", source_url="", local_path=tmp_path)


# ---------------------------------------------------------------------------
# Tests that don't need Docker running
# ---------------------------------------------------------------------------


def test_build_run_cmd_contains_network_none(executor, dummy_dataset):
    cmd = executor._build_run_cmd(Path("/tmp/script.py"), dummy_dataset)
    assert "--network" in cmd
    idx = cmd.index("--network")
    assert cmd[idx + 1] == "none"


def test_build_run_cmd_contains_read_only(executor, dummy_dataset):
    cmd = executor._build_run_cmd(Path("/tmp/script.py"), dummy_dataset)
    assert "--read-only" in cmd


def test_build_run_cmd_contains_cap_drop_all(executor, dummy_dataset):
    cmd = executor._build_run_cmd(Path("/tmp/script.py"), dummy_dataset)
    assert "--cap-drop" in cmd
    idx = cmd.index("--cap-drop")
    assert cmd[idx + 1] == "ALL"


def test_build_run_cmd_mounts_script(executor, dummy_dataset):
    script = Path("/tmp/myscript.py")
    cmd = executor._build_run_cmd(script, dummy_dataset)
    mounts = [cmd[i + 1] for i, v in enumerate(cmd) if v == "-v"]
    script_mounts = [m for m in mounts if "myscript.py" in m]
    assert script_mounts, "Script not mounted"
    assert ":ro" in script_mounts[0]


def test_build_run_cmd_mounts_dataset_readonly(executor, dummy_dataset):
    cmd = executor._build_run_cmd(Path("/tmp/script.py"), dummy_dataset)
    mounts = [cmd[i + 1] for i, v in enumerate(cmd) if v == "-v"]
    dataset_path = str(dummy_dataset.local_path.resolve())
    dataset_mounts = [m for m in mounts if dataset_path in m]
    assert dataset_mounts, "Dataset not mounted"
    assert ":ro" in dataset_mounts[0]


def test_build_run_cmd_memory_and_cpu(executor, dummy_dataset):
    executor.memory_limit = "2g"
    executor.cpu_count = 0.5
    cmd = executor._build_run_cmd(Path("/tmp/script.py"), dummy_dataset)
    assert "2g" in cmd
    assert "0.5" in cmd


def test_preflight_blocks_execution_without_docker(dummy_dataset):
    """Preflight failure should return an ExecutionResult without touching Docker."""
    executor = DockerExecutor()
    code = "import subprocess\nsubprocess.run(['ls'])"
    result = executor.execute(code, dummy_dataset)
    assert result.exit_code != 0
    assert "Forbidden" in result.stderr


def test_is_available_returns_bool(executor):
    result = executor.is_available()
    assert isinstance(result, bool)


def test_is_image_built_returns_bool(executor):
    result = executor.is_image_built()
    assert isinstance(result, bool)


# ---------------------------------------------------------------------------
# Tests that require Docker + sandbox image
# ---------------------------------------------------------------------------


@requires_docker
def test_execute_simple_code(executor, dummy_dataset):
    code = "print('RESULT:accuracy=0.95')"
    result = executor.execute(code, dummy_dataset)
    assert result.exit_code == 0
    assert result.outputs.get("accuracy") == pytest.approx(0.95)


@requires_docker
def test_execute_has_no_network(executor, dummy_dataset):
    """Code that tries to open a socket should fail inside the container."""
    code = (
        "import urllib.request\n"
        "try:\n"
        "    urllib.request.urlopen('http://example.com', timeout=2)\n"
        "    print('RESULT:connected=1')\n"
        "except Exception:\n"
        "    print('RESULT:connected=0')\n"
    )
    result = executor.execute(code, dummy_dataset)
    assert result.exit_code == 0
    assert result.outputs.get("connected") == pytest.approx(0.0)


@requires_docker
def test_execute_timeout(dummy_dataset):
    executor = DockerExecutor(timeout=2)
    code = "import time; time.sleep(60)"
    result = executor.execute(code, dummy_dataset)
    assert result.timed_out


@requires_docker
def test_execute_captures_stderr(executor, dummy_dataset):
    code = "import sys; sys.stderr.write('an error\\n')"
    result = executor.execute(code, dummy_dataset)
    assert "an error" in result.stderr


@requires_docker
def test_execute_nonzero_on_exception(executor, dummy_dataset):
    code = "raise ValueError('boom')"
    result = executor.execute(code, dummy_dataset)
    assert result.exit_code != 0
    assert "boom" in result.stderr


@requires_docker
def test_execute_sklearn_available(executor, dummy_dataset):
    code = (
        "from sklearn.linear_model import LogisticRegression\n"
        "import numpy as np\n"
        "X = np.array([[0, 0], [1, 1], [2, 2], [3, 3]])\n"
        "y = np.array([0, 0, 1, 1])\n"
        "clf = LogisticRegression().fit(X, y)\n"
        "acc = clf.score(X, y)\n"
        "print(f'RESULT:accuracy={acc}')\n"
    )
    result = executor.execute(code, dummy_dataset)
    assert result.exit_code == 0
    assert "accuracy" in result.outputs
    assert 0.0 <= result.outputs["accuracy"] <= 1.0


@requires_docker
def test_execute_dataset_readable(executor, tmp_path):
    """Generated code can read a CSV mounted from the host."""
    csv_path = tmp_path / "data.csv"
    csv_path.write_text("x,y\n1,2\n3,4\n5,6\n")
    dataset = Dataset(name="test", source_url="", local_path=tmp_path)

    code = f"import pandas as pd\ndf = pd.read_csv('{csv_path}')\nprint(f'RESULT:n_rows={{len(df)}}')\n"
    result = executor.execute(code, dataset)
    assert result.exit_code == 0
    assert result.outputs.get("n_rows") == pytest.approx(3.0)
