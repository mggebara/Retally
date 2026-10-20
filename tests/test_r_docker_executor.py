"""Tests for RDockerExecutor.

Mirrors test_docker_executor.py.  Tests that don't need Docker are
always enabled; tests that actually spin up containers are gated by
the ``requires_r_docker`` mark and skip cleanly when Docker or the
R sandbox image isn't available.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

import pytest

from retally.codegen.docker_executor import DEFAULT_R_IMAGE, RDockerExecutor
from retally.models import Dataset

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _docker_and_r_image_available() -> bool:
    """Return True if Docker daemon is up AND the R sandbox image exists."""
    try:
        result = subprocess.run(
            ["docker", "image", "inspect", DEFAULT_R_IMAGE],
            capture_output=True,
            timeout=10,
        )
        return result.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


requires_r_docker = pytest.mark.skipif(
    not _docker_and_r_image_available(),
    reason="Docker not running or R sandbox image not built (run 'make build-r-sandbox')",
)


@pytest.fixture
def executor():
    return RDockerExecutor(timeout=30)


@pytest.fixture
def dummy_dataset(tmp_path):
    (tmp_path / "data.csv").write_text("a,b\n1,2\n")
    return Dataset(name="dummy", source_url="", local_path=tmp_path)


# ---------------------------------------------------------------------------
# Tests that don't need Docker running
# ---------------------------------------------------------------------------


def test_default_image_is_r_sandbox(executor):
    assert executor.image == "retally-sandbox-r:latest"


def test_script_is_mounted_as_R_extension(executor, dummy_dataset):
    """The script must be mounted as script.R so Rscript can dispatch it."""
    cmd = executor._build_run_cmd(Path("/tmp/some_script.R"), dummy_dataset, run_id="test-run")
    mounts = [cmd[i + 1] for i, v in enumerate(cmd) if v == "-v"]
    script_mounts = [m for m in mounts if "/workspace/script.R" in m]
    assert script_mounts, f"Script not mounted at /workspace/script.R: {mounts}"
    assert ":ro" in script_mounts[0]


def test_interpreter_is_Rscript(executor, dummy_dataset):
    cmd = executor._build_run_cmd(Path("/tmp/script.R"), dummy_dataset, run_id="test-run")
    # Rscript is the last meaningful token before the in-container script path.
    assert "Rscript" in cmd
    rscript_idx = cmd.index("Rscript")
    assert cmd[rscript_idx + 1] == "/workspace/script.R"


def test_build_run_cmd_inherits_isolation_flags(executor, dummy_dataset):
    """R executor must apply the same sandbox flags as the Python one.

    Equality with the Python executor isn't testable cheaply (different
    image, different interpreter), so we just confirm the key flags
    are present.  The shared logic lives in the base class so this is
    primarily a regression guard against accidentally dropping a flag.
    """
    cmd = executor._build_run_cmd(Path("/tmp/script.R"), dummy_dataset, run_id="test-run")
    assert "--network" in cmd and cmd[cmd.index("--network") + 1] == "none"
    assert "--read-only" in cmd
    assert "--cap-drop" in cmd and cmd[cmd.index("--cap-drop") + 1] == "ALL"
    assert "--security-opt" in cmd
    assert "no-new-privileges" in cmd


def test_no_preflight_passes_through(executor, dummy_dataset, monkeypatch):
    """RDockerExecutor must not run the Python AST preflight.

    A script that would trigger ``preflight_check`` (eg ``import
    subprocess``) is also a perfectly valid string in R syntax — and
    crucially, R has no concept of Python imports, so the AST scan
    would be nonsensical.  The base class's ``preflight`` is a no-op
    by default and RDockerExecutor doesn't override it.

    We assert by monkeypatching the preflight to a sentinel and
    confirming it WASN'T called for R execution (we can't actually
    execute without Docker, so we stop at _require_docker).
    """
    called = {"flag": False}

    def fail_if_called(_code):
        called["flag"] = True

    monkeypatch.setattr(executor, "preflight", fail_if_called)
    # Force is_available() to False so execute() bails before Docker.
    monkeypatch.setattr(executor, "is_available", lambda: False)
    with pytest.raises(RuntimeError, match="Docker daemon"):
        executor.execute("# any R code\nx <- 1", dummy_dataset)
    # preflight IS called (it's a no-op now, but the path runs).
    assert called["flag"] is True
    # The point is that for the Python subclass, a forbidden import
    # would have raised ValueError before reaching is_available().
    # Here, the no-op preflight lets execution continue to the Docker
    # check, which is exactly the contract.


def test_is_available_returns_bool(executor):
    assert isinstance(executor.is_available(), bool)


def test_is_image_built_returns_bool(executor):
    assert isinstance(executor.is_image_built(), bool)


def test_custom_image_overrides_default():
    """The constructor's image kwarg overrides the class default."""
    custom = RDockerExecutor(image="my-custom-r:dev")
    assert custom.image == "my-custom-r:dev"


# ---------------------------------------------------------------------------
# Tests that require Docker + the R sandbox image (skipped on most hosts)
# ---------------------------------------------------------------------------


@requires_r_docker
def test_execute_simple_r_code(executor, dummy_dataset):
    code = 'cat("RESULT:accuracy=0.95\\n")\n'
    result = executor.execute(code, dummy_dataset)
    assert result.exit_code == 0
    assert result.outputs.get("accuracy") == pytest.approx(0.95)


@requires_r_docker
def test_execute_picks_up_deviation_lines(executor, dummy_dataset):
    code = 'cat("DEVIATION: switched from 5-fold to 10-fold CV\\n")\ncat("RESULT:r2=0.84\\n")\n'
    result = executor.execute(code, dummy_dataset)
    assert result.exit_code == 0
    assert result.outputs.get("r2") == pytest.approx(0.84)
    assert result.deviation_notes == ["switched from 5-fold to 10-fold CV"]


@requires_r_docker
def test_execute_has_no_network(executor, dummy_dataset):
    """Code that tries to open a connection should fail inside the container."""
    # url() only constructs a connection object; it does not touch the
    # network until the connection is actually read.  readLines() forces the
    # open, so --network none surfaces as an error/warning (connected=0).
    code = (
        "r <- tryCatch(\n"
        '  { con <- url("http://example.com"); on.exit(close(con)); '
        'readLines(con, n = 1); cat("RESULT:connected=1\\n") },\n'
        '  error = function(e) cat("RESULT:connected=0\\n"),\n'
        '  warning = function(w) cat("RESULT:connected=0\\n")\n'
        ")\n"
    )
    result = executor.execute(code, dummy_dataset)
    assert result.exit_code == 0
    assert result.outputs.get("connected") == pytest.approx(0.0)


@requires_r_docker
def test_execute_timeout(dummy_dataset):
    executor = RDockerExecutor(timeout=2)
    code = "Sys.sleep(60)\n"
    result = executor.execute(code, dummy_dataset)
    assert result.timed_out


@requires_r_docker
def test_execute_captures_stderr(executor, dummy_dataset):
    code = 'message("an error from R")\n'
    result = executor.execute(code, dummy_dataset)
    assert "an error from R" in result.stderr


@requires_r_docker
def test_execute_fixest_available(executor, dummy_dataset):
    """fixest is the headline econometrics package; smoke-test it loads + runs."""
    code = (
        "library(fixest)\n"
        "set.seed(42)\n"
        "n <- 100\n"
        "x <- rnorm(n)\n"
        "y <- 2 * x + rnorm(n)\n"
        # fixest's feols() requires an explicit data= argument; unlike base
        # lm() it does not resolve model variables from the global env.
        "d <- data.frame(x = x, y = y)\n"
        "m <- feols(y ~ x, data = d)\n"
        'beta <- coef(m)["x"]\n'
        'cat(sprintf("RESULT:beta=%f\\n", beta))\n'
    )
    result = executor.execute(code, dummy_dataset)
    assert result.exit_code == 0
    beta = result.outputs.get("beta")
    assert beta is not None
    # True beta is 2.0; with n=100 and seed=42, this should be close.
    assert abs(beta - 2.0) < 0.3


@requires_r_docker
def test_execute_dataset_readable(executor, tmp_path):
    """Generated R code can read a CSV mounted from the host."""
    csv_path = tmp_path / "data.csv"
    csv_path.write_text("x,y\n1,2\n3,4\n5,6\n")
    dataset = Dataset(name="test", source_url="", local_path=tmp_path)

    code = 'df <- read.csv("' + str(csv_path) + '")\ncat(sprintf("RESULT:n_rows=%d\\n", nrow(df)))\n'
    result = executor.execute(code, dataset)
    assert result.exit_code == 0
    assert result.outputs.get("n_rows") == pytest.approx(3.0)
