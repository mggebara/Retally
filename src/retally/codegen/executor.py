"""
CodeExecutor — runs generated Python code in a sandboxed subprocess and
captures its outputs.

Safety considerations
---------------------
- Run code in a subprocess (never ``exec`` in the current process).
- Set a hard timeout to prevent runaway loops.
- Optionally restrict network access and filesystem writes outside the
  dataset directory using OS-level sandboxing (see implementation notes).
- Never allow the generated code to import or call ``subprocess``,
  ``os.system``, or ``socket`` — add a pre-flight AST scan if needed.

Output convention
-----------------
The executor scans stdout line by line for lines matching:
    RESULT:<name>=<value>
These are collected into ``ExecutionResult.outputs`` as {name: float}.
"""

from __future__ import annotations

import ast
import shutil
import subprocess
import sys
import tempfile
import warnings
from pathlib import Path

from retally.models import Dataset, ExecutionResult

# Names that generated code must not import or call.
_FORBIDDEN_MODULES = frozenset(["subprocess", "socket", "multiprocessing", "ctypes", "pty", "fcntl"])

_RESULT_PREFIX = "RESULT:"
_DEVIATION_PREFIX = "DEVIATION:"


# ---------------------------------------------------------------------------
# Module-level helpers — shared by CodeExecutor and DockerExecutor
# ---------------------------------------------------------------------------


def preflight_check(code: str) -> None:
    """Raise ValueError if ``code`` imports a forbidden module or calls os.system.

    This is a best-effort AST scan, not a security boundary.  Use OS-level
    sandboxing (Docker, seccomp, etc.) for real isolation.
    """
    try:
        tree = ast.parse(code)
    except SyntaxError as exc:
        raise ValueError(f"Syntax error in code: {exc}") from exc

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                module_root = alias.name.split(".")[0]
                if module_root in _FORBIDDEN_MODULES:
                    raise ValueError(f"Forbidden import: {alias.name}")

        elif isinstance(node, ast.ImportFrom):
            if node.module is not None:
                module_root = node.module.split(".")[0]
                if module_root in _FORBIDDEN_MODULES:
                    raise ValueError(f"Forbidden import: {node.module}")

        elif isinstance(node, ast.Call):
            func = node.func
            if (
                isinstance(func, ast.Attribute)
                and func.attr == "system"
                and isinstance(func.value, ast.Name)
                and func.value.id == "os"
            ):
                raise ValueError("Forbidden import: os.system")


def parse_outputs(stdout: str) -> dict[str, float]:
    """Extract ``RESULT:<name>=<value>`` lines from stdout.

    Skips malformed lines with a warning rather than raising.
    """
    outputs: dict[str, float] = {}
    for line in stdout.splitlines():
        line = line.strip()
        if not line.startswith(_RESULT_PREFIX):
            continue
        rest = line[len(_RESULT_PREFIX) :]
        if "=" not in rest:
            warnings.warn(f"Malformed RESULT line (no '='): {line!r}", stacklevel=2)
            continue
        name, _, value_str = rest.partition("=")
        name = name.strip()
        value_str = value_str.strip()
        if not name:
            warnings.warn(f"Malformed RESULT line (empty name): {line!r}", stacklevel=2)
            continue
        try:
            outputs[name] = float(value_str)
        except ValueError:
            warnings.warn(f"Could not parse float from RESULT line: {line!r}", stacklevel=2)
    return outputs


def parse_deviation_notes(stdout: str) -> list[str]:
    """Extract free-text ``DEVIATION:<note>`` lines from stdout.

    Emitted by the claim-refinement loop when the generator changes
    something the paper didn't specify (e.g. swapping a hyperparameter
    or preprocessing step to close a gap).  Empty notes are skipped.
    """
    notes: list[str] = []
    for line in stdout.splitlines():
        line = line.strip()
        if not line.startswith(_DEVIATION_PREFIX):
            continue
        note = line[len(_DEVIATION_PREFIX) :].strip()
        if note:
            notes.append(note)
    return notes


class CodeExecutor:
    """Executes generated code in a subprocess and parses its outputs.

    Parameters
    ----------
    timeout:
        Maximum wall-clock seconds allowed for the subprocess.  Processes
        that exceed this are killed and ``ExecutionResult.timed_out`` is set.
    work_dir:
        Working directory for the subprocess.  Defaults to a temp directory
        created per execution.
    """

    def __init__(self, timeout: int = 300, work_dir: Path | None = None) -> None:
        self.timeout = timeout
        self.work_dir = work_dir

    def execute(self, code: str, dataset: Dataset) -> ExecutionResult:
        """Run ``code`` and return an ExecutionResult.

        Steps:
          1. Call ``_preflight_check(code)`` and abort with a non-zero
             exit_code if it raises.
          2. Write the code to a temp .py file in a temp work directory.
          3. Run ``python <file>`` as a subprocess with ``timeout``.
          4. Capture stdout and stderr.
          5. Call ``_parse_outputs`` to extract RESULT lines from stdout.
          6. Return an ExecutionResult with all fields populated.

        If the subprocess times out, set ``ExecutionResult.timed_out = True``
        and ``exit_code = -1``.
        """
        # Step 1: preflight check
        try:
            self._preflight_check(code)
        except ValueError as exc:
            return ExecutionResult(
                generated_code=code,
                stdout="",
                stderr=str(exc),
                exit_code=1,
                outputs={},
                timed_out=False,
            )

        # Determine working directory; track whether we created a temp dir.
        temp_dir_created: Path | None = None
        if self.work_dir is not None:
            work_dir = self.work_dir
            work_dir.mkdir(parents=True, exist_ok=True)
        else:
            work_dir = self._make_work_dir()
            temp_dir_created = work_dir

        try:
            # Step 2: write code to a temp .py file
            script_path = work_dir / "generated_script.py"
            script_path.write_text(code, encoding="utf-8")

            # Step 3 & 4: run the script as a subprocess
            timed_out = False
            try:
                result = subprocess.run(
                    [sys.executable, str(script_path)],
                    capture_output=True,
                    text=True,
                    timeout=self.timeout,
                    cwd=str(work_dir),
                )
                stdout = result.stdout
                stderr = result.stderr
                exit_code = result.returncode
            except subprocess.TimeoutExpired as exc:
                timed_out = True
                raw_out = exc.stdout or b""
                raw_err = exc.stderr or b""
                stdout = raw_out.decode("utf-8", errors="replace") if isinstance(raw_out, bytes) else raw_out
                stderr = raw_err.decode("utf-8", errors="replace") if isinstance(raw_err, bytes) else raw_err
                exit_code = -1

            # Step 5: parse outputs and any DEVIATION notes
            outputs = self._parse_outputs(stdout)
            deviation_notes = parse_deviation_notes(stdout)

            # Step 6: return result
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
            # Clean up only temp dirs we created ourselves
            if temp_dir_created is not None:
                shutil.rmtree(temp_dir_created, ignore_errors=True)

    def _preflight_check(self, code: str) -> None:
        preflight_check(code)

    def _parse_outputs(self, stdout: str) -> dict[str, float]:
        return parse_outputs(stdout)

    def _make_work_dir(self) -> Path:
        """Create and return a temporary working directory for this execution.

        Use ``tempfile.mkdtemp`` with a descriptive prefix.  The caller is
        responsible for cleanup after the ExecutionResult has been captured.
        """
        return Path(tempfile.mkdtemp(prefix="retally_"))
