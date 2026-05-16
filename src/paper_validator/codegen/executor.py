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
from pathlib import Path
from typing import Any

from paper_validator.models import Dataset, ExecutionResult


# Names that generated code must not import or call.
_FORBIDDEN_MODULES = frozenset(
    ["subprocess", "socket", "multiprocessing", "ctypes", "pty", "fcntl"]
)

_RESULT_PREFIX = "RESULT:"


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
        raise NotImplementedError

    def _preflight_check(self, code: str) -> None:
        """Parse the code as an AST and raise ValueError if it uses forbidden imports.

        Walk the AST looking for ``Import`` and ``ImportFrom`` nodes.
        Raise ``ValueError(f"Forbidden import: {name}")`` for any module in
        ``_FORBIDDEN_MODULES``.

        This is a best-effort check, not a security guarantee.  For stronger
        isolation, combine with OS-level sandboxing.
        """
        raise NotImplementedError

    def _parse_outputs(self, stdout: str) -> dict[str, float]:
        """Extract RESULT:<name>=<value> lines from stdout.

        Parse each line that starts with ``RESULT:``.  Split on ``=`` to get
        the metric name and value.  Convert the value to float.  Skip lines
        that do not match or whose value cannot be parsed as a float (log a
        warning instead of raising).

        Returns a dict of {metric_name: float_value}.
        """
        raise NotImplementedError

    def _make_work_dir(self) -> Path:
        """Create and return a temporary working directory for this execution.

        Use ``tempfile.mkdtemp`` with a descriptive prefix.  The caller is
        responsible for cleanup after the ExecutionResult has been captured.
        """
        raise NotImplementedError
