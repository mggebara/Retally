"""The host-side sandbox time limit for Claude Code cells (``benchmark.reproducers.run_sandbox``)."""

from __future__ import annotations

import json
import re
import shlex
import subprocess

import pytest

from benchmark.reproducers import run_sandbox
from tests.test_claude_code_reproducer import _render

LABEL = "retally.run=claude-code-x-blind-r1"
CMD = ["docker", "run", "--rm", "--label", LABEL, "img", "Rscript", "/workspace/script.R"]


class FakeDocker:
    """Stands in for ``subprocess.run``: the docker command, then ``docker ps`` / ``docker kill``."""

    def __init__(self, *, returncode=0, timeout=False, running=("abc123",)):
        self.returncode, self.timeout, self.running = returncode, timeout, running
        self.calls: list[list[str]] = []

    def __call__(self, cmd, **kwargs):
        self.calls.append(list(cmd))
        if cmd[:2] == ["docker", "ps"]:
            return subprocess.CompletedProcess(cmd, 0, stdout="\n".join(self.running) + "\n", stderr="")
        if cmd[:2] == ["docker", "kill"]:
            return subprocess.CompletedProcess(cmd, 0)
        kwargs["stdout"].write(b"RESULT: beta = 1.0\n")
        kwargs["stderr"].write(b"some warning\n")
        if self.timeout:
            raise subprocess.TimeoutExpired(cmd, kwargs["timeout"])
        return subprocess.CompletedProcess(cmd, self.returncode)


def _main(tmp_path, monkeypatch, fake, timeout="300"):
    monkeypatch.setattr(run_sandbox.subprocess, "run", fake)
    argv = ["--timeout", timeout, "--label", LABEL, "--run-dir", str(tmp_path), "--", *CMD]
    code = run_sandbox.main(argv)
    return code, json.loads((tmp_path / "timing.json").read_text(encoding="utf-8"))


def test_success_writes_outputs_and_timing(tmp_path, monkeypatch):
    fake = FakeDocker()
    code, timing = _main(tmp_path, monkeypatch, fake)
    assert code == 0
    assert fake.calls == [CMD]  # no docker ps / kill on success
    assert (tmp_path / "stdout.txt").read_text() == "RESULT: beta = 1.0\n"
    assert (tmp_path / "stderr.txt").read_text() == "some warning\n"
    assert timing["timed_out"] is False
    assert timing["exit_code"] == 0
    assert timing["timeout_seconds"] == 300
    assert timing["label"] == LABEL
    assert timing["wall_seconds"] >= 0


def test_timeout_kills_the_labelled_container_and_exits_124(tmp_path, monkeypatch, capsys):
    fake = FakeDocker(timeout=True)
    code, timing = _main(tmp_path, monkeypatch, fake, timeout="5")
    assert code == run_sandbox.TIMEOUT_EXIT_CODE == 124
    assert fake.calls[1] == ["docker", "ps", "--filter", f"label={LABEL}", "--format", "{{.ID}}"]
    assert fake.calls[2] == ["docker", "kill", "abc123"]
    assert timing["timed_out"] is True
    assert timing["exit_code"] == 124
    assert timing["containers_killed"] == ["abc123"]
    stderr = (tmp_path / "stderr.txt").read_text()
    assert stderr.startswith("some warning\n")  # the partial output survives
    assert "time limit of 5 s reached" in stderr
    assert "TIMED OUT" in capsys.readouterr().err


def test_nonzero_exit_is_passed_through(tmp_path, monkeypatch):
    fake = FakeDocker(returncode=1)
    code, timing = _main(tmp_path, monkeypatch, fake)
    assert code == 1
    assert timing == timing | {"timed_out": False, "exit_code": 1}
    assert len(fake.calls) == 1


def test_signal_death_is_reported_as_128_plus_signal(tmp_path, monkeypatch):
    code, timing = _main(tmp_path, monkeypatch, FakeDocker(returncode=-9))
    assert code == timing["exit_code"] == 137


def test_refuses_a_command_without_the_label(tmp_path, monkeypatch):
    monkeypatch.setattr(run_sandbox.subprocess, "run", FakeDocker())
    with pytest.raises(SystemExit) as exc:
        run_sandbox.main(
            ["--timeout", "5", "--label", LABEL, "--run-dir", str(tmp_path), "--", "docker", "run", "img"]
        )
    assert exc.value.code == 2
    assert not (tmp_path / "timing.json").exists()


@pytest.mark.parametrize("mode", ["seeded", "independent", "blind"])
def test_rendered_task_runs_the_sandbox_through_the_wrapper(tmp_path, monkeypatch, mode):
    rendered = _render(tmp_path, mode)
    task = rendered.task_file.read_text(encoding="utf-8")
    assert "perl" not in task and "alarm" not in task
    assert "RESULT:" in task and "ten minutes" in task  # the exploratory-run and hang rules stay
    lines = [ln.strip() for ln in task.splitlines() if "benchmark.reproducers.run_sandbox" in ln]
    assert len(lines) == 1
    line = lines[0]
    assert line.endswith('; echo "exit code: $?"')
    assert re.search(r"--timeout 300 --label retally\.run=claude-code-\S+-r1 ", line)

    # The rendered line, with $SCRIPT expanded, is a valid wrapper invocation.
    script = rendered.output_dir / "attempt-1" / "script.R"
    line = line.removesuffix('; echo "exit code: $?"')
    line = line.replace('"$(dirname "$SCRIPT")"', shlex.quote(str(script.parent)))
    line = line.replace('"$SCRIPT"', shlex.quote(str(script)))
    argv = shlex.split(line)
    assert argv[:3] == ["uv", "run", "--directory"]
    assert argv[4:7] == ["python", "-m", "benchmark.reproducers.run_sandbox"]
    seen = {}
    monkeypatch.setattr(
        run_sandbox,
        "run",
        lambda cmd, **kw: (
            seen.update(cmd=cmd, **kw) or {"timed_out": False, "wall_seconds": 1, "exit_code": 0}
        ),
    )
    assert run_sandbox.main(argv[7:]) == 0
    assert seen["timeout"] == 300
    assert seen["run_dir"] == script.parent
    assert seen["cmd"][:3] == ["docker", "run", "--rm"]
    assert f"{script}:/workspace/script.R:ro" in seen["cmd"]
    assert seen["label"] in seen["cmd"]
