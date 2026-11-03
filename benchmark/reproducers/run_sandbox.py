"""Run one sandbox execution for a Claude Code cell under a host-side time limit.

    uv run python -m benchmark.reproducers.run_sandbox --timeout 300 \\
        --label retally.run=<label> --run-dir DIR -- docker run ... --label retally.run=<label> ...

Runs the ``docker run`` command after ``--`` with its stdout and stderr
written to ``DIR/stdout.txt`` and ``DIR/stderr.txt``, under
``subprocess.run(timeout=...)``.  On timeout the attached ``docker run``
client is killed and so is the container, found by its label, as
``RDockerExecutor._kill_timeout_container`` does on the pipeline path; a
line saying so is appended to ``stderr.txt`` and the exit code is 124.
Otherwise the exit code is the command's own.

Either way ``DIR/timing.json`` records the wall-clock seconds, the limit
and whether it was hit, so an over-limit run is visible in the evidence
bundle.

Why not ``perl -e 'alarm shift; exec @ARGV' 300 docker run ...`` (the
earlier protocol): the SIGALRM goes to the attached ``docker run``
client, which proxies it into the container, where PID 1 is ``Rscript``
with no handler, so the kernel drops it.  A 314 s run finished with exit
0 that way (ROADMAP 3.7.3).  ``docker run --init`` would make the alarm
fatal (tini forwards it to ``Rscript``, which dies on it), but would not
record wall time.

Stdlib only, so it does not depend on ``retally`` being importable.
"""

from __future__ import annotations

import json
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

TIMEOUT_EXIT_CODE = 124
TIMING_NAME = "timing.json"
LABEL_KEY = "retally.run"  # ``retally.codegen.docker_executor._RUN_LABEL_KEY``


def kill_labelled(label: str) -> list[str]:
    """Kill every running container carrying ``label`` (``key=value``); best-effort.

    Returns the ids it tried to kill.
    """
    try:
        ps = subprocess.run(
            ["docker", "ps", "--filter", f"label={label}", "--format", "{{.ID}}"],
            capture_output=True,
            text=True,
            timeout=10,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
        print(f"run_sandbox: docker ps failed during timeout cleanup: {exc}", file=sys.stderr)
        return []
    ids = ps.stdout.split()
    for container_id in ids:
        try:
            subprocess.run(["docker", "kill", container_id], capture_output=True, timeout=10)
        except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
            print(f"run_sandbox: docker kill {container_id} failed: {exc}", file=sys.stderr)
    return ids


def _has_label(cmd: list[str], label: str) -> bool:
    """Whether ``cmd`` passes ``--label <label>`` (or ``--label=<label>``)."""
    pairs = zip(cmd, cmd[1:])
    return any(a in ("--label", "-l") and b == label for a, b in pairs) or f"--label={label}" in cmd


def run(cmd: list[str], *, timeout: float, label: str, run_dir: Path) -> dict:
    """Run ``cmd`` into ``run_dir``; return the timing record (also written to ``timing.json``)."""
    run_dir.mkdir(parents=True, exist_ok=True)
    started_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    t0 = time.monotonic()
    timed_out = False
    killed: list[str] = []
    with open(run_dir / "stdout.txt", "wb") as out, open(run_dir / "stderr.txt", "wb") as err:
        try:
            exit_code = subprocess.run(cmd, stdout=out, stderr=err, timeout=timeout).returncode
            if exit_code < 0:  # killed by a signal: report it the way a shell does
                exit_code = 128 - exit_code
        except subprocess.TimeoutExpired:
            timed_out = True
            exit_code = TIMEOUT_EXIT_CODE
            killed = kill_labelled(label)
    wall = round(time.monotonic() - t0, 2)
    if timed_out:
        with open(run_dir / "stderr.txt", "a", encoding="utf-8") as err:
            err.write(
                f"\nretally: sandbox time limit of {timeout:g} s reached after {wall:g} s; "
                f"container killed (label {label}); exit code {TIMEOUT_EXIT_CODE}\n"
            )
    record = {
        "wall_seconds": wall,
        "timeout_seconds": timeout,
        "timed_out": timed_out,
        "exit_code": exit_code,
        "label": label,
        "containers_killed": killed,
        "started_at": started_at,
    }
    (run_dir / TIMING_NAME).write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    return record


def main(argv: list[str] | None = None) -> int:
    import argparse

    parser = argparse.ArgumentParser(
        prog="python -m benchmark.reproducers.run_sandbox",
        description="Run a sandbox docker command under a host-side time limit and record its wall time.",
    )
    parser.add_argument("--timeout", type=float, required=True, help="Wall-clock limit in seconds.")
    parser.add_argument(
        "--label", required=True, help=f"The container's label, '{LABEL_KEY}=<value>', killed on timeout."
    )
    parser.add_argument(
        "--run-dir", type=Path, required=True, help="Where stdout.txt, stderr.txt and timing.json go."
    )
    parser.add_argument("cmd", nargs=argparse.REMAINDER, help="-- docker run ...")
    args = parser.parse_args(argv)
    cmd = args.cmd[1:] if args.cmd[:1] == ["--"] else args.cmd
    if not cmd:
        parser.error("no command given after --")
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    if "=" not in args.label:
        parser.error("--label must be key=value, e.g. retally.run=<value>")
    if not _has_label(cmd, args.label):
        parser.error(f"the command does not pass --label {args.label}, so a timeout could not kill it")

    record = run(cmd, timeout=args.timeout, label=args.label, run_dir=args.run_dir)
    if record["timed_out"]:
        print(
            f"run_sandbox: TIMED OUT after {record['wall_seconds']:g} s (limit {args.timeout:g} s); "
            f"killed {len(record['containers_killed'])} container(s); exit code {TIMEOUT_EXIT_CODE}",
            file=sys.stderr,
        )
    else:
        print(
            f"run_sandbox: finished in {record['wall_seconds']:g} s; exit code {record['exit_code']}",
            file=sys.stderr,
        )
    return int(record["exit_code"])


if __name__ == "__main__":
    raise SystemExit(main())
