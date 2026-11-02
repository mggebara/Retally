"""Tests for the harness's Docker daemon health check (``benchmark.docker_health``).

No Docker is needed: ``subprocess.run`` is stubbed, and the pipeline's
executors are ``MagicMock(spec=...)`` stand-ins.
"""

from __future__ import annotations

import subprocess
from pathlib import Path
from unittest.mock import MagicMock

import pytest

from retally.codegen.docker_executor import DockerExecutor, RDockerExecutor
from retally.codegen.executor import CodeExecutor
from retally.models import Claim, ClaimType, Dataset, ExecutionResult, Paper, ValidationReport
from tests._loaders import REPO_ROOT, load_module_from_path

bschema = load_module_from_path("benchmark.schema", REPO_ROOT / "benchmark" / "schema.py")
load_module_from_path("benchmark.pricing", REPO_ROOT / "benchmark" / "pricing.py")
health = load_module_from_path("benchmark.docker_health", REPO_ROOT / "benchmark" / "docker_health.py")
reproducer_mod = load_module_from_path("benchmark.reproducer", REPO_ROOT / "benchmark" / "reproducer.py")
runner = load_module_from_path("benchmark.runner", REPO_ROOT / "benchmark" / "runner.py")

DockerUnavailable = health.DockerUnavailable


# ── check_docker_daemon with a stubbed subprocess ───────────────────────


class _StubRun:
    """Stands in for ``subprocess.run``: records the call, then returns or raises."""

    def __init__(self, *, returncode=0, stdout="", stderr="", raises=None):
        self.returncode, self.stdout, self.stderr, self.raises = returncode, stdout, stderr, raises
        self.calls: list[tuple[list[str], dict]] = []

    def __call__(self, cmd, **kwargs):
        self.calls.append((cmd, kwargs))
        if self.raises is not None:
            raise self.raises
        return subprocess.CompletedProcess(cmd, self.returncode, self.stdout, self.stderr)


def test_healthy_daemon_passes_with_a_short_timeout():
    run = _StubRun(stdout="28.5.1\n")
    health.check_docker_daemon(run=run)
    [(cmd, kwargs)] = run.calls
    assert cmd[:2] == ["docker", "info"]
    assert kwargs["timeout"] == health.DOCKER_HEALTH_TIMEOUT_S == 10.0
    assert kwargs["capture_output"] is True


def test_timeout_raises_docker_unavailable():
    run = _StubRun(raises=subprocess.TimeoutExpired(["docker", "info"], 10.0))
    with pytest.raises(DockerUnavailable, match=r"did not answer 'docker info' within 10 s"):
        health.check_docker_daemon(run=run)


def test_nonzero_exit_raises_docker_unavailable_with_the_reason():
    run = _StubRun(returncode=1, stderr="Cannot connect to the Docker daemon. Is it running?\n")
    with pytest.raises(DockerUnavailable, match=r"exited 1: Cannot connect to the Docker daemon"):
        health.check_docker_daemon(run=run)


def test_missing_docker_binary_raises_docker_unavailable():
    with pytest.raises(DockerUnavailable, match="not on PATH"):
        health.check_docker_daemon(run=_StubRun(raises=FileNotFoundError("docker")))


def test_docker_unavailable_is_not_a_network_error_type():
    assert not issubclass(DockerUnavailable, (TimeoutError, ConnectionError))


# ── Classification: a failed check is a transient row, never cached ─────


def test_docker_unavailable_is_the_transient_docker_kind():
    assert runner._transient_error_kind(DockerUnavailable("wedged")) == "docker_unavailable"
    assert "docker_unavailable" in runner.TRANSIENT_ERROR_KINDS
    try:
        try:
            raise DockerUnavailable("wedged")
        except DockerUnavailable as inner:
            raise RuntimeError("execution failed") from inner
    except RuntimeError as outer:
        assert runner._transient_error_kind(outer) == "docker_unavailable"


def _entry():
    return bschema.BenchmarkEntry(
        id="test",
        i4r_report_url="https://example.org/r",
        language=bschema.Language.PYTHON,
        outcome_label=bschema.OutcomeLabel.REPRODUCIBLE,
        paper=bschema.PaperRef(source="raw paper text"),
    )


def _report():
    claims = [Claim(description="x", value=1.0, claim_type=ClaimType.OTHER)]
    return ValidationReport(
        paper=Paper(title="t", claims=claims, dataset_references=[MagicMock()]),
        dataset=Dataset(name="d", source_url="", local_path=Path("/tmp/d")),
        execution_result=ExecutionResult(generated_code="print('hi')", exit_code=0, outputs={"x": 1.0}),
        claim_results=[],
        overall_passed=True,
    )


def _failing_check():
    raise DockerUnavailable("Docker daemon did not answer 'docker info' within 10 s")


def _docker_pipeline():
    pipeline = MagicMock()
    pipeline.executor = MagicMock(spec=DockerExecutor)
    pipeline.r_executor = MagicMock(spec=RDockerExecutor)
    pipeline.validate.return_value = _report()
    return pipeline


def test_failed_check_makes_a_transient_uncached_row_without_running(tmp_path, caplog):
    pipeline = _docker_pipeline()
    agent = reproducer_mod.PipelineReproducer(pipeline, docker_check=_failing_check)
    [result] = runner.run_benchmark([_entry()], reproducer_factory=lambda: agent, cache_dir=tmp_path)
    assert result.retally_ran is False
    assert result.transient is True
    assert result.error_kind == "docker_unavailable"
    assert result.error.startswith("DockerUnavailable: ")
    assert pipeline.validate.call_count == 0, "no API call is paid for when Docker is already down"
    assert not list(tmp_path.glob("*.json")), "transient errors must not be cached"
    assert "transient docker_unavailable error" in caplog.text


def test_every_sandbox_execution_is_checked_and_executors_restored():
    pipeline = _docker_pipeline()
    python_exec, r_exec = pipeline.executor, pipeline.r_executor
    checks: list[int] = []

    def check():
        checks.append(1)
        if len(checks) > 2:  # healthy up front and on the first execution, then wedged
            _failing_check()

    def validate(*args, **kwargs):
        pipeline.executor.execute("code", None)
        pipeline.executor.execute("code", None)
        return _report()

    pipeline.validate.side_effect = validate
    agent = reproducer_mod.PipelineReproducer(pipeline, docker_check=check)
    with pytest.raises(DockerUnavailable):
        agent.reproduce(
            "raw paper text",
            language=bschema.Language.PYTHON,
            dataset_reference=None,
            claims=None,
            reproduction_mode=reproducer_mod.ReproductionMode.SEEDED,
        )
    assert len(checks) == 3
    assert python_exec.execute.call_count == 1, "the execution after the failed check never starts"
    assert pipeline.executor is python_exec and pipeline.r_executor is r_exec


def test_non_docker_executors_are_not_checked():
    pipeline = MagicMock()
    pipeline.executor = MagicMock(spec=CodeExecutor)
    pipeline.r_executor = None
    pipeline.validate.return_value = _report()

    def check():
        raise AssertionError("a host-subprocess executor must not trigger the Docker check")

    agent = reproducer_mod.PipelineReproducer(pipeline, docker_check=check)
    rep = agent.reproduce(
        "raw paper text",
        language=bschema.Language.PYTHON,
        dataset_reference=None,
        claims=None,
        reproduction_mode=reproducer_mod.ReproductionMode.SEEDED,
    )
    assert rep.outputs == {"x": 1.0}
