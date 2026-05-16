"""
DockerExecutor — runs generated code inside an isolated Docker container.

Isolation guarantees (vs. CodeExecutor)
----------------------------------------
- **Network**: ``--network none`` — the container has zero outbound connectivity.
  All data must be downloaded *before* execution (DatasetDownloader handles this).
- **Filesystem**: ``--read-only`` — the container root FS is immutable.
  ``--tmpfs /tmp`` gives writable scratch space in memory only.
- **Privileges**: ``--cap-drop ALL --security-opt no-new-privileges`` —
  no Linux capabilities, no setuid escalation.
- **Resources**: ``--memory`` and ``--cpus`` prevent runaway processes from
  consuming the host.
- **User**: the sandbox image runs as a non-root ``sandbox`` user.

Dataset mounting
----------------
The dataset is mounted at its exact absolute host path (read-only).  Generated
code that references that path therefore works without any path rewriting.

The generated script is mounted at ``/workspace/script.py`` (read-only).

Building the image
------------------
Call ``DockerExecutor.build_image()`` or run ``make build-sandbox``.
The image must be built before calling ``execute()``.
"""

from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path

from paper_validator.codegen.executor import parse_outputs, preflight_check
from paper_validator.models import Dataset, ExecutionResult

# Default image tag — build with ``make build-sandbox``
DEFAULT_IMAGE = "paper-validator-sandbox:latest"

# Location of the Dockerfile relative to this file:
#   src/paper_validator/codegen/docker_executor.py  →  docker/Dockerfile.sandbox
_DOCKERFILE = Path(__file__).parents[3] / "docker" / "Dockerfile.sandbox"
_DOCKER_CONTEXT = _DOCKERFILE.parent


class DockerExecutor:
    """Runs generated reproduction code inside a Docker sandbox.

    Parameters
    ----------
    image:
        Docker image tag to use.  Build it with ``DockerExecutor.build_image()``
        or ``make build-sandbox``.
    timeout:
        Wall-clock seconds before the container is killed.
    memory_limit:
        Docker memory limit string, e.g. ``"4g"``, ``"512m"``.
    cpu_count:
        Number of CPUs available to the container (float, e.g. ``1.0``).
    """

    def __init__(
        self,
        image: str = DEFAULT_IMAGE,
        timeout: int = 300,
        memory_limit: str = "4g",
        cpu_count: float = 1.0,
    ) -> None:
        self.image = image
        self.timeout = timeout
        self.memory_limit = memory_limit
        self.cpu_count = cpu_count

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def execute(self, code: str, dataset: Dataset) -> ExecutionResult:
        """Run ``code`` inside the Docker sandbox and return an ExecutionResult.

        Steps
        -----
        1. AST preflight check (catches obvious issues before spinning up Docker).
        2. Write code to a temp file.
        3. Build the ``docker run`` command with all isolation flags.
        4. Run the container; capture stdout/stderr.
        5. Parse ``RESULT:`` lines from stdout.
        6. Clean up the temp file; return ExecutionResult.
        """
        # Step 1: fast preflight before touching Docker
        try:
            preflight_check(code)
        except ValueError as exc:
            return ExecutionResult(
                generated_code=code,
                stderr=str(exc),
                exit_code=1,
            )

        self._require_docker()

        work_dir = Path(tempfile.mkdtemp(prefix="paper_validator_docker_"))
        try:
            # Step 2: write script
            script_path = work_dir / "script.py"
            script_path.write_text(code, encoding="utf-8")

            # Step 3: build command
            cmd = self._build_run_cmd(script_path, dataset)

            # Step 4: run container
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
                stdout = (exc.stdout or b"")
                stderr = (exc.stderr or b"")
                if isinstance(stdout, bytes):
                    stdout = stdout.decode("utf-8", errors="replace")
                if isinstance(stderr, bytes):
                    stderr = stderr.decode("utf-8", errors="replace")
                exit_code = -1
                # Kill any lingering container by name if we set one
                self._kill_timeout_container(script_path)

            # Step 5: parse outputs
            outputs = parse_outputs(stdout)

            return ExecutionResult(
                generated_code=code,
                stdout=stdout,
                stderr=stderr,
                exit_code=exit_code,
                outputs=outputs,
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
        image: str = DEFAULT_IMAGE,
        dockerfile: Path | None = None,
        no_cache: bool = False,
    ) -> None:
        """Build the sandbox Docker image.

        Parameters
        ----------
        image:
            Tag for the built image.
        dockerfile:
            Path to the Dockerfile.  Defaults to ``docker/Dockerfile.sandbox``
            in the project root.
        no_cache:
            Pass ``--no-cache`` to force a full rebuild.
        """
        dockerfile = dockerfile or _DOCKERFILE
        context = dockerfile.parent

        cmd = ["docker", "build", "-f", str(dockerfile), "-t", image]
        if no_cache:
            cmd.append("--no-cache")
        cmd.append(str(context))

        print(f"Building sandbox image {image!r} …")
        result = subprocess.run(cmd, text=True)
        if result.returncode != 0:
            raise RuntimeError(
                f"docker build failed (exit {result.returncode}).\n"
                "Run 'make build-sandbox' to see the full output."
            )
        print(f"Image {image!r} built successfully.")

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _build_run_cmd(self, script_path: Path, dataset: Dataset) -> list[str]:
        """Assemble the full ``docker run`` command.

        Volume mounts
        -------------
        - Script: ``<host_script>:/workspace/script.py:ro``
        - Dataset: ``<host_dataset_dir>:<host_dataset_dir>:ro``
          (mounted at the exact host path so absolute paths in generated code
          work without rewriting)

        Security flags
        --------------
        ``--network none``            no outbound connectivity
        ``--read-only``               immutable container FS
        ``--tmpfs /tmp:size=256m``    writable scratch in RAM
        ``--cap-drop ALL``            no Linux capabilities
        ``--security-opt no-new-privileges``
        ``--memory``                  RAM cap
        ``--cpus``                    CPU cap
        """
        dataset_path = dataset.local_path.resolve()

        cmd = [
            "docker", "run",
            "--rm",
            # Network isolation — the key requirement
            "--network", "none",
            # Resource limits
            "--memory", self.memory_limit,
            "--cpus", str(self.cpu_count),
            # Filesystem isolation
            "--read-only",
            "--tmpfs", "/tmp:size=256m",
            # Drop all Linux capabilities
            "--cap-drop", "ALL",
            "--security-opt", "no-new-privileges",
            # Mount generated script (read-only)
            "-v", f"{script_path}:/workspace/script.py:ro",
            # Mount dataset at its exact host path (read-only)
            "-v", f"{dataset_path}:{dataset_path}:ro",
            # Working directory
            "--workdir", "/workspace",
            # Image and entrypoint
            self.image,
            "python", "-u", "/workspace/script.py",
        ]
        return cmd

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
                "Build it first:\n"
                "  make build-sandbox\n"
                "or:\n"
                "  from paper_validator.codegen.docker_executor import DockerExecutor\n"
                "  DockerExecutor.build_image()"
            )

    def _kill_timeout_container(self, script_path: Path) -> None:
        """Best-effort: kill any container still running our script after timeout.

        Uses ``docker ps`` to find containers running the sandbox image and
        kills them.  Failures are silently ignored — the container will be
        cleaned up by Docker's own timeout mechanisms.
        """
        try:
            ps = subprocess.run(
                ["docker", "ps", "--filter", f"ancestor={self.image}",
                 "--format", "{{.ID}}"],
                capture_output=True, text=True, timeout=5,
            )
            for container_id in ps.stdout.strip().splitlines():
                subprocess.run(
                    ["docker", "kill", container_id],
                    capture_output=True, timeout=5,
                )
        except Exception:
            pass
