"""Docker daemon health check, run by the harness before each sandbox execution.

On 2026-11-02 the Docker daemon wedged twice during long batches:
containers stuck in ``Created`` and ``docker run`` clients hanging for
minutes with no output.  A wedged daemon is a property of the host, not of
the paper, so the harness asks the daemon a cheap question first
(``docker info`` with a short timeout) and raises :class:`DockerUnavailable`
when it does not answer.  The runner classifies that as the transient
``docker_unavailable`` error kind (``runner._transient_error_kind``): the
row is reported but never cached, and the batch fails fast instead of
hanging on every remaining paper.

The pipeline itself (``src/retally/``) is untouched: ``PipelineReproducer``
wraps the pipeline's Docker executors in :class:`HealthCheckedExecutor` for
the duration of a ``reproduce`` call, the same way it wraps the downloader.
"""

from __future__ import annotations

import subprocess
from collections.abc import Callable
from typing import Any

__all__ = [
    "DOCKER_HEALTH_TIMEOUT_S",
    "DockerUnavailable",
    "HealthCheckedExecutor",
    "check_docker_daemon",
]

DOCKER_HEALTH_TIMEOUT_S = 10.0
"""How long the daemon gets to answer ``docker info`` before it counts as wedged."""

_HEALTH_COMMAND = ("docker", "info", "--format", "{{.ServerVersion}}")
"""Exits non-zero when the client cannot reach the daemon; prints one short line otherwise."""


class DockerUnavailable(RuntimeError):
    """The Docker daemon did not answer the harness's health check.

    Deliberately not a ``TimeoutError`` / ``ConnectionError`` subclass, so the
    runner records it as ``docker_unavailable`` rather than ``network``.
    """


def check_docker_daemon(
    *,
    timeout: float = DOCKER_HEALTH_TIMEOUT_S,
    run: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> None:
    """Return quietly when the Docker daemon answers within ``timeout`` seconds.

    Raises :class:`DockerUnavailable` when ``docker`` is not on PATH, the
    command times out (the wedged-daemon case), or it exits non-zero
    (daemon stopped).  ``run`` is injectable for tests.
    """
    try:
        proc = run(list(_HEALTH_COMMAND), capture_output=True, text=True, timeout=timeout)
    except FileNotFoundError as exc:
        raise DockerUnavailable("'docker' is not on PATH") from exc
    except subprocess.TimeoutExpired as exc:
        raise DockerUnavailable(
            f"Docker daemon did not answer 'docker info' within {timeout:g} s "
            "(wedged? restart Docker and re-run)"
        ) from exc
    if proc.returncode != 0:
        detail = (proc.stderr or proc.stdout or "").strip().splitlines()
        reason = detail[-1] if detail else "no output"
        raise DockerUnavailable(f"'docker info' exited {proc.returncode}: {reason}")


class HealthCheckedExecutor:
    """Wraps a pipeline executor so every ``execute`` is preceded by :func:`check_docker_daemon`.

    Every other attribute is delegated to the wrapped executor.
    """

    def __init__(self, inner: Any, *, check: Callable[[], None] = check_docker_daemon) -> None:
        self._inner = inner
        self._check = check

    def execute(self, *args: Any, **kwargs: Any) -> Any:
        self._check()
        return self._inner.execute(*args, **kwargs)

    def __getattr__(self, name: str) -> Any:
        return getattr(self._inner, name)
