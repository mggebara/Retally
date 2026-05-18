"""
Docker-sandboxed code execution for generated reproduction scripts.

Isolation guarantees (vs. the host-subprocess ``CodeExecutor``)
---------------------------------------------------------------
- **Network**: ``--network none`` — zero outbound connectivity.  Data must
  be downloaded *before* execution (DatasetDownloader handles that).
- **Filesystem**: ``--read-only`` — immutable container root.
  ``--tmpfs /tmp`` gives writable scratch space in memory only.
- **Privileges**: ``--cap-drop ALL --security-opt no-new-privileges`` —
  no Linux capabilities, no setuid escalation.
- **Resources**: ``--memory`` and ``--cpus`` cap host consumption.
- **User**: the sandbox images run as a non-root ``sandbox`` user.

Per-language subclasses
-----------------------
The shared logic lives in ``_DockerExecutorBase``.  Subclasses pin the
language-specific bits:

  * ``DockerExecutor`` — Python; uses ``openra-sandbox:latest`` and runs
    ``python -u /workspace/script.py``.  Also runs the Python AST
    preflight check before spinning up Docker.
  * ``RDockerExecutor`` — R; uses ``openra-sandbox-r:latest`` and runs
    ``Rscript /workspace/script.R``.  No preflight (R has no equivalent
    quick static check in the stdlib).

Adding a third language should be a ~20-line subclass: pick image tag,
script filename, interpreter command, optional preflight.

Dataset mounting
----------------
The dataset is mounted at its exact absolute host path (read-only).
Generated code that references that path therefore works without any
path rewriting.

The generated script is mounted at ``/workspace/script.<ext>`` (read-only).

Building images
---------------
Call ``<Executor>.build_image()`` or run the matching make target
(``make build-sandbox`` / ``make build-r-sandbox``).  The image must
be built before calling ``execute()``.
"""

from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path

from openra.codegen.executor import parse_deviation_notes, parse_outputs, preflight_check
from openra.models import Dataset, ExecutionResult

# Repo root, two levels up from src/openra/codegen/
_REPO_ROOT = Path(__file__).parents[3]
_DOCKERFILE_PYTHON = _REPO_ROOT / "docker" / "Dockerfile.sandbox"
_DOCKERFILE_R = _REPO_ROOT / "docker" / "Dockerfile.sandbox.r"

# Default image tags — build with ``make build-sandbox`` / ``make build-r-sandbox``.
DEFAULT_IMAGE = "openra-sandbox:latest"
DEFAULT_R_IMAGE = "openra-sandbox-r:latest"


class _DockerExecutorBase:
    """Shared logic for Docker-sandboxed script execution.

    Subclasses override the four ``_*`` class attributes plus
    optionally ``preflight`` to plug in language-specific bits.
    """

    # Image / Dockerfile to use by default.
    _DEFAULT_IMAGE: str = ""
    _DOCKERFILE: Path = Path()

    # Filename the generated script is mounted at inside the container.
    # Must include the language's conventional extension so the interpreter
    # can dispatch correctly (e.g. ``script.py``, ``script.R``).
    _SCRIPT_FILENAME: str = ""

    # The command that runs the script inside the container.  Includes the
    # in-container script path so subclasses don't have to compute it.
    _INTERPRETER_CMD: list[str] = []

    def __init__(
        self,
        image: str | None = None,
        timeout: int = 300,
        memory_limit: str = "4g",
        cpu_count: float = 1.0,
    ) -> None:
        self.image = image if image is not None else self._DEFAULT_IMAGE
        self.timeout = timeout
        self.memory_limit = memory_limit
        self.cpu_count = cpu_count

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def execute(self, code: str, dataset: Dataset) -> ExecutionResult:
        """Run ``code`` inside the Docker sandbox and return an ExecutionResult."""
        try:
            self.preflight(code)
        except ValueError as exc:
            return ExecutionResult(
                generated_code=code,
                stderr=str(exc),
                exit_code=1,
            )

        self._require_docker()

        work_dir = Path(tempfile.mkdtemp(prefix="openra_docker_"))
        try:
            script_path = work_dir / self._SCRIPT_FILENAME
            script_path.write_text(code, encoding="utf-8")

            cmd = self._build_run_cmd(script_path, dataset)

            timed_out = False
            try:
                proc = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    timeout=self.timeout,
                )
                stdout = proc.stdout
                stderr = proc.stderr
                exit_code = proc.returncode
            except subprocess.TimeoutExpired as exc:
                timed_out = True
                raw_out = exc.stdout or b""
                raw_err = exc.stderr or b""
                stdout = raw_out.decode("utf-8", errors="replace") if isinstance(raw_out, bytes) else raw_out
                stderr = raw_err.decode("utf-8", errors="replace") if isinstance(raw_err, bytes) else raw_err
                exit_code = -1
                self._kill_timeout_container()

            outputs = parse_outputs(stdout)
            deviation_notes = parse_deviation_notes(stdout)

            return ExecutionResult(
                generated_code=code,
                stdout=stdout,
                stderr=stderr,
                exit_code=exit_code,
                outputs=outputs,
                deviation_notes=deviation_notes,
                timed_out=timed_out,
            )
        finally:
            shutil.rmtree(work_dir, ignore_errors=True)

    def is_available(self) -> bool:
        """Return True if the Docker daemon is reachable."""
        try:
            result = subprocess.run(
                ["docker", "info"],
                capture_output=True,
                timeout=5,
            )
            return result.returncode == 0
        except (FileNotFoundError, subprocess.TimeoutExpired):
            return False

    def is_image_built(self) -> bool:
        """Return True if the sandbox image exists locally."""
        try:
            result = subprocess.run(
                ["docker", "image", "inspect", self.image],
                capture_output=True,
                timeout=10,
            )
            return result.returncode == 0
        except (FileNotFoundError, subprocess.TimeoutExpired):
            return False

    @classmethod
    def build_image(
        cls,
        image: str | None = None,
        dockerfile: Path | None = None,
        no_cache: bool = False,
    ) -> None:
        """Build the sandbox Docker image for this executor's language."""
        dockerfile = dockerfile or cls._DOCKERFILE
        image = image if image is not None else cls._DEFAULT_IMAGE
        context = dockerfile.parent

        cmd = ["docker", "build", "-f", str(dockerfile), "-t", image]
        if no_cache:
            cmd.append("--no-cache")
        cmd.append(str(context))

        print(f"Building sandbox image {image!r} …")
        result = subprocess.run(cmd, text=True)
        if result.returncode != 0:
            raise RuntimeError(
                f"docker build failed (exit {result.returncode}).\nRe-run with verbose output to inspect."
            )
        print(f"Image {image!r} built successfully.")

    # ------------------------------------------------------------------
    # Hooks subclasses can override
    # ------------------------------------------------------------------

    def preflight(self, code: str) -> None:
        """Per-language static check run before the container starts.

        Default is a no-op.  ``DockerExecutor`` overrides this to run
        the Python AST forbidden-imports scan; ``RDockerExecutor`` does
        not override (R has no comparable stdlib parser, and the
        Docker sandbox is the real boundary anyway).

        Override implementations should raise ``ValueError`` with a
        user-facing message; ``execute()`` translates that into an
        ExecutionResult with exit_code=1 rather than running Docker at all.
        """
        return None

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _build_run_cmd(self, script_path: Path, dataset: Dataset) -> list[str]:
        """Assemble the full ``docker run`` command.

        See the module docstring for the isolation flags applied.
        """
        dataset_path = dataset.local_path.resolve()
        script_mount = f"/workspace/{self._SCRIPT_FILENAME}"

        return [
            "docker",
            "run",
            "--rm",
            # Network isolation — the key requirement
            "--network",
            "none",
            # Resource limits
            "--memory",
            self.memory_limit,
            "--cpus",
            str(self.cpu_count),
            # Filesystem isolation
            "--read-only",
            "--tmpfs",
            "/tmp:size=256m",
            # Drop all Linux capabilities
            "--cap-drop",
            "ALL",
            "--security-opt",
            "no-new-privileges",
            # Mount generated script (read-only)
            "-v",
            f"{script_path}:{script_mount}:ro",
            # Mount dataset at its exact host path (read-only)
            "-v",
            f"{dataset_path}:{dataset_path}:ro",
            # Working directory
            "--workdir",
            "/workspace",
            # Image and entrypoint
            self.image,
            *self._INTERPRETER_CMD,
        ]

    def _require_docker(self) -> None:
        """Raise RuntimeError if Docker is not available or image not built."""
        if not self.is_available():
            raise RuntimeError(
                "Docker daemon is not running or 'docker' is not in PATH.\n"
                "Install Docker: https://docs.docker.com/get-docker/"
            )
        if not self.is_image_built():
            raise RuntimeError(
                f"Sandbox image {self.image!r} not found.\n"
                "Build it first via the matching ``make`` target, or call\n"
                f"  {type(self).__name__}.build_image()"
            )

    def _kill_timeout_container(self) -> None:
        """Best-effort: kill any container still running the sandbox image after timeout.

        Filters by ``ancestor={self.image}`` — the script path is not needed
        because all containers spawned by this executor share the same image.

        Failures are silently ignored — Docker will eventually clean up via
        its own mechanisms; this just makes resource release prompter.
        """
        try:
            ps = subprocess.run(
                ["docker", "ps", "--filter", f"ancestor={self.image}", "--format", "{{.ID}}"],
                capture_output=True,
                text=True,
                timeout=5,
            )
            for container_id in ps.stdout.strip().splitlines():
                subprocess.run(
                    ["docker", "kill", container_id],
                    capture_output=True,
                    timeout=5,
                )
        except Exception:
            pass


class DockerExecutor(_DockerExecutorBase):
    """Docker-sandboxed execution of generated Python reproduction code.

    Parameters
    ----------
    image:
        Docker image tag.  Defaults to ``openra-sandbox:latest``; build
        with ``DockerExecutor.build_image()`` or ``make build-sandbox``.
    timeout:
        Wall-clock seconds before the container is killed.
    memory_limit:
        Docker memory limit string, e.g. ``"4g"``, ``"512m"``.
    cpu_count:
        Number of CPUs available to the container (float, e.g. ``1.0``).
    """

    _DEFAULT_IMAGE = DEFAULT_IMAGE
    _DOCKERFILE = _DOCKERFILE_PYTHON
    _SCRIPT_FILENAME = "script.py"
    _INTERPRETER_CMD = ["python", "-u", "/workspace/script.py"]

    def preflight(self, code: str) -> None:
        """Python AST scan for obviously-forbidden imports.

        Cheap static check that catches the easiest mistakes before
        spinning up Docker.  Not a security boundary — that's what
        the container is.
        """
        preflight_check(code)


class RDockerExecutor(_DockerExecutorBase):
    """Docker-sandboxed execution of generated R reproduction code.

    Parameters
    ----------
    image:
        Docker image tag.  Defaults to ``openra-sandbox-r:latest``;
        build with ``RDockerExecutor.build_image()`` or
        ``make build-r-sandbox``.
    timeout, memory_limit, cpu_count:
        Same semantics as ``DockerExecutor``.

    Notes
    -----
    No preflight check.  R has no equivalent of Python's ``ast`` module
    in the standard library, so adding a cheap static guard would mean
    importing rpy2 or shelling out to ``lintr`` — both expensive and
    neither contributing to the actual sandbox boundary, which is the
    container itself.  Keeping ``preflight`` as a no-op is the honest
    answer: Docker is the security guarantee here, not a fallible
    text scan.

    The R script must follow the same output convention as Python:
    print ``RESULT:<name>=<value>`` lines for metrics and optional
    ``DEVIATION:<text>`` lines for methodology changes the model had
    to make.  ``cat()`` or ``message()`` are both fine emitters as long
    as the lines reach stdout.
    """

    _DEFAULT_IMAGE = DEFAULT_R_IMAGE
    _DOCKERFILE = _DOCKERFILE_R
    _SCRIPT_FILENAME = "script.R"
    _INTERPRETER_CMD = ["Rscript", "/workspace/script.R"]
