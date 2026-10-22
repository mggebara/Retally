"""Score reproductions a Claude Code session wrote to disk: ``--reproducer claude-code``.

The harness does not drive the agent.  A Claude Code session is handed a
task rendered by ``benchmark.reproducers.render_task`` and writes its
scripts, sandbox output and a ``reproduction.json`` manifest under

    benchmark/reproductions/<entry_id>/<mode>/<run_id>/

(:data:`REPRODUCTIONS_DIR`, overridable with ``RETALLY_REPRODUCTIONS_DIR``).
:class:`FilesystemReproducer` reads that directory back as a
:class:`~benchmark.reproducer.Reproduction`, and the runner scores it like
any other reproducer.  The manifest's schema is :data:`REPRODUCTION_SCHEMA`.

**Numbers come from files, not from the manifest.**  ``outputs`` and
``deviations`` are parsed from the final ``stdout.txt`` with the
executor's own parsers, and ``attempt_outputs`` from each attempt's
``stdout.txt``; the manifest only says which files are which, their exit
codes and what kind of refinement followed each attempt.  Anything
malformed raises ``ValueError`` naming the file (the runner records
``retally_ran = False``); a cell nobody has run raises
:class:`~benchmark.reproducer.ReproductionMissingError` (a
``reproduction_missing`` skip).
"""

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from benchmark.reproducer import ComponentMetrics, Reproduction, ReproductionMissingError
from retally.models import Claim, DatasetReference, Language, ReproductionMode

__all__ = [
    "ATTEMPT_KINDS",
    "FilesystemReproducer",
    "REPRODUCTIONS_DIR",
    "REPRODUCTION_SCHEMA",
    "claude_code",
    "load_reproduction",
    "reproductions_root",
]

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
REPRODUCTIONS_DIR = REPO_ROOT / "benchmark" / "reproductions"
"""Default root of the reproductions tree (gitignored)."""

ROOT_ENV = "RETALLY_REPRODUCTIONS_DIR"
RUN_ID_ENV = "RETALLY_REPRODUCTION_RUN_ID"

MANIFEST_NAME = "reproduction.json"
RENDER_NAME = "render.json"
SCHEMA_VERSION = 1
ATTEMPT_KINDS = ("error", "claim", "")
MAX_ARTIFACT_BYTES = 2 * 1024 * 1024
SKIPPED_ARTIFACTS_NAME = "_skipped_artifacts.txt"

REPRODUCTION_SCHEMA = """\
reproduction.json (schema 1), written last by the agent into its run directory
benchmark/reproductions/<entry_id>/<mode>/<run_id>/:

{
  "schema": 1,
  "entry_id": "montero-2022-cooperative-property-rights",
  "mode": "independent",
  "run_id": "2026-10-22-a",
  "reproducer": "claude-code",
  "language": "r",
  "final": {"script": "script.R", "stdout": "stdout.txt", "stderr": "stderr.txt", "exit_code": 0},
  "attempts": [
    {"dir": "attempt-1", "exit_code": 1, "kind": "error"},
    {"dir": "attempt-2", "exit_code": 0, "kind": "claim"}
  ],
  "deviations": [],
  "notes": "free text: what the agent did, what it could not do",
  "files_read_outside_mount": [],
  "started_at": "2026-10-22T10:00:00Z",
  "finished_at": "2026-10-22T10:40:00Z"
}

* entry_id, mode and run_id must match the directory the file sits in.
* final: the run that is scored -- script.R, stdout.txt, stderr.txt at the
  run-dir root, and its exit code.  If the agent reverts to an earlier
  attempt it copies that attempt's files there.
* attempts: every execution before the final one, oldest first.  Each
  attempt-<n>/ holds script.R, stdout.txt, stderr.txt, and feedback.txt
  when kind is not "".  kind is the refinement that followed it:
  "error" (it crashed or printed no RESULT: line; the agent repaired it),
  "claim" (the agent compared its RESULT: values with the claimed values
  and changed the script; never allowed in blind mode), or "" (neither).
* All paths are relative to the run directory; absolute paths and ".."
  are rejected.
* deviations: free-text methodology changes, in addition to any
  DEVIATION: lines in the final stdout.
* The numbers scored are the RESULT: lines of the files, never anything
  written in this JSON.
"""
"""The ``reproduction.json`` contract, as shown to the agent in the task file."""


def reproductions_root() -> Path:
    """The reproductions root: ``$RETALLY_REPRODUCTIONS_DIR`` when set, else :data:`REPRODUCTIONS_DIR`."""
    env = os.environ.get(ROOT_ENV)
    return Path(env) if env else REPRODUCTIONS_DIR


class FilesystemReproducer:
    """A :class:`~benchmark.reproducer.Reproducer` that reads a finished run from disk.

    The cell is ``<root>/<entry_id>/<mode>/``.  ``entry_id`` is the
    dataset reference's ``name``, which the runner sets to the catalog
    entry id (no curated entry sets ``registry_key``); without one, the
    entry is found by matching ``paper_source`` against the
    ``render.json`` of each run.  The run is ``run_id`` (constructor) or
    ``$RETALLY_REPRODUCTION_RUN_ID`` when given, else the newest run
    directory holding a ``reproduction.json`` (by its ``finished_at``,
    then by mtime).  Directories with only a ``render.json`` (rendered,
    not yet run) are ignored.
    """

    name = "claude-code"

    def __init__(self, root: Path | str | None = None, *, run_id: str | None = None) -> None:
        self.root = Path(root) if root is not None else reproductions_root()
        self.run_id = run_id

    def reproduce(
        self,
        paper_source: str,
        *,
        language: Language,
        dataset_reference: DatasetReference | None,
        claims: list[Claim] | None,
        reproduction_mode: ReproductionMode,
    ) -> Reproduction:
        mode = reproduction_mode.value
        entry_id = self._entry_id(paper_source, dataset_reference, mode)
        run_dir = self._run_dir(entry_id, mode)
        return load_reproduction(run_dir, entry_id=entry_id, mode=mode, language=language)

    # -- cell lookup --------------------------------------------------------

    def _entry_id(self, paper_source: str, dataset_reference: DatasetReference | None, mode: str) -> str:
        name = getattr(dataset_reference, "name", None) if dataset_reference is not None else None
        if name:
            return str(name)
        for render in sorted(self.root.glob(f"*/{mode}/*/{RENDER_NAME}")):
            try:
                data = json.loads(render.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                continue
            if isinstance(data, dict) and data.get("paper_source") == paper_source:
                return render.parent.parent.parent.name
        raise ReproductionMissingError(
            f"no reproduction for paper {paper_source!r} in {mode} mode: the dataset reference names "
            f"no entry and no {RENDER_NAME} under {self.root}/*/{mode}/*/ records that paper_source"
        )

    def _run_dir(self, entry_id: str, mode: str) -> Path:
        cell = self.root / entry_id / mode
        run_id = self.run_id or os.environ.get(RUN_ID_ENV) or None
        if run_id:
            run_dir = cell / run_id
            if not (run_dir / MANIFEST_NAME).is_file():
                raise ReproductionMissingError(
                    f"no {MANIFEST_NAME} in {run_dir} (run id {run_id!r} requested)"
                )
            return run_dir
        runs = [d for d in cell.iterdir() if (d / MANIFEST_NAME).is_file()] if cell.is_dir() else []
        if not runs:
            raise ReproductionMissingError(
                f"no finished reproduction for {entry_id} ({mode}): no {cell}/<run_id>/{MANIFEST_NAME}"
            )
        return max(runs, key=_run_sort_key)


def claude_code() -> FilesystemReproducer:
    """Zero-arg factory for ``--reproducer claude-code``."""
    return FilesystemReproducer()


def _run_sort_key(run_dir: Path) -> tuple[datetime, float]:
    manifest = run_dir / MANIFEST_NAME
    data = _read_json(manifest)
    finished = _parse_time(data.get("finished_at")) if isinstance(data, dict) else None
    return finished or datetime.min.replace(tzinfo=timezone.utc), manifest.stat().st_mtime


def _parse_time(value: Any) -> datetime | None:
    if not isinstance(value, str):
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)


def _read_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"{path}: malformed JSON: {exc}") from exc
    except OSError as exc:
        raise ValueError(f"{path}: cannot read: {exc}") from exc


# ---------------------------------------------------------------------------
# Reading one run directory
# ---------------------------------------------------------------------------


def load_reproduction(
    run_dir: Path, *, entry_id: str, mode: str, language: Language | None = None
) -> Reproduction:
    """Read and validate one run directory into a :class:`Reproduction`.

    Raises ``ValueError`` naming the offending file for a malformed
    manifest, a missing named file, an unknown attempt kind, a blind run
    with a claim-targeted attempt, an unsafe path, or an entry / mode /
    run id / language that does not match the directory.
    """
    from retally.codegen.executor import parse_deviation_notes

    run_dir = Path(run_dir)
    manifest_path = run_dir / MANIFEST_NAME
    data = _read_json(manifest_path)
    if not isinstance(data, dict):
        raise ValueError(f"{manifest_path}: expected a JSON object")

    def bad(msg: str) -> ValueError:
        return ValueError(f"{manifest_path}: {msg}")

    if data.get("schema") != SCHEMA_VERSION:
        raise bad(f"schema must be {SCHEMA_VERSION}, got {data.get('schema')!r}")
    for key, expected in (("entry_id", entry_id), ("mode", mode), ("run_id", run_dir.name)):
        if data.get(key) != expected:
            raise bad(f"{key} is {data.get(key)!r} but the directory says {expected!r}")
    if language is not None and "language" in data and data["language"] != language.value:
        raise bad(f"language is {data['language']!r} but the catalog entry is {language.value!r}")

    final = data.get("final")
    if not isinstance(final, dict):
        raise bad("'final' must be an object with script, stdout, stderr and exit_code")
    exit_code = _int(final.get("exit_code"), bad, "final.exit_code")
    script = _read_named(run_dir, final.get("script"), bad, "final.script")
    stdout = _read_named(run_dir, final.get("stdout"), bad, "final.stdout")
    stderr = _read_named(run_dir, final.get("stderr"), bad, "final.stderr")

    attempts = data.get("attempts", [])
    if not isinstance(attempts, list):
        raise bad("'attempts' must be a list")
    attempt_outputs: list[str] = []
    attempt_kinds: list[str] = []
    for i, attempt in enumerate(attempts, start=1):
        label = f"attempts[{i - 1}]"
        if not isinstance(attempt, dict):
            raise bad(f"{label} must be an object with dir, exit_code and kind")
        kind = attempt.get("kind")
        if kind not in ATTEMPT_KINDS:
            raise bad(f"{label}.kind is {kind!r}; expected one of {list(ATTEMPT_KINDS)}")
        if kind == "claim" and mode == ReproductionMode.BLIND.value:
            raise bad(f"{label} is a claim-targeted attempt, which blind mode forbids")
        _int(attempt.get("exit_code"), bad, f"{label}.exit_code")
        attempt_dir = _safe_relative(attempt.get("dir"), bad, f"{label}.dir")
        if not (run_dir / attempt_dir).is_dir():
            raise ValueError(
                f"{run_dir / attempt_dir}: attempt directory named in {manifest_path} is missing"
            )
        required = ["script.R", "stdout.txt", "stderr.txt"] + (["feedback.txt"] if kind else [])
        for name in required:
            path = run_dir / attempt_dir / name
            if not path.is_file():
                raise ValueError(f"{path}: file required for {label} (kind {kind!r}) is missing")
        attempt_outputs.append(_read_text(run_dir / attempt_dir / "stdout.txt"))
        attempt_kinds.append(str(kind))
    attempt_outputs.append(stdout)
    attempt_kinds.append("")

    declared = data.get("deviations", [])
    if not isinstance(declared, list) or not all(isinstance(d, str) for d in declared):
        raise bad("'deviations' must be a list of strings")
    deviations = parse_deviation_notes(stdout)
    deviations += [d for d in declared if d.strip() and d not in deviations]

    n_error = attempt_kinds.count("error")
    n_claim = attempt_kinds.count("claim")
    return Reproduction(
        outputs=_parse_results(stdout),
        claims=[],
        generated_code=script,
        stdout=stdout,
        stderr=stderr,
        exit_code=exit_code,
        deviations=deviations,
        stages=ComponentMetrics(
            parsed=True,
            claims_extracted=None,
            dataset_extracted=None,
            dataset_downloaded=True,
            code_generated=bool(script),
            code_executed=exit_code == 0,
        ),
        usage=None,
        artifacts=_artifacts(run_dir),
        attempt_outputs=attempt_outputs,
        n_refinements=n_error + n_claim,
        n_executions=len(attempt_outputs),
        attempt_kinds=attempt_kinds,
        n_error_refinements=n_error,
        n_claim_refinements=n_claim,
        n_files_stripped=_n_files_stripped(run_dir, mode),
    )


def _parse_results(stdout: str) -> dict[str, float]:
    """``RESULT:`` lines with the executor's parser (malformed / ``NA`` lines dropped quietly)."""
    import warnings

    from retally.codegen.executor import parse_outputs

    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        return parse_outputs(stdout)


def _int(value: Any, bad: Any, label: str) -> int:
    if not isinstance(value, int) or isinstance(value, bool):
        raise bad(f"{label} must be an integer, got {value!r}")
    return value


def _safe_relative(value: Any, bad: Any, label: str) -> Path:
    if not isinstance(value, str) or not value.strip():
        raise bad(f"{label} must be a non-empty relative path, got {value!r}")
    path = Path(value)
    if path.is_absolute() or ".." in path.parts:
        raise bad(f"{label} {value!r} must be relative to the run directory, without '..'")
    return path


def _read_named(run_dir: Path, value: Any, bad: Any, label: str) -> str:
    path = run_dir / _safe_relative(value, bad, label)
    if not path.is_file():
        raise ValueError(f"{path}: file named by {label} in {run_dir / MANIFEST_NAME} is missing")
    return _read_text(path)


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def _n_files_stripped(run_dir: Path, mode: str) -> int | None:
    """``n_files_stripped`` from the run's ``render.json``; None in seeded mode or when absent."""
    if mode == ReproductionMode.SEEDED.value:
        return None
    render = run_dir / RENDER_NAME
    if not render.is_file():
        return None
    data = _read_json(render)
    value = data.get("n_files_stripped") if isinstance(data, dict) else None
    return value if isinstance(value, int) and not isinstance(value, bool) else None


def _artifacts(run_dir: Path) -> dict[str, str]:
    """Every regular file under ``run_dir`` as relative path -> text, for the runner to copy.

    Files over :data:`MAX_ARTIFACT_BYTES` are left out and listed in
    ``_skipped_artifacts.txt``; a ``mount/`` tree, if one was put there, is
    skipped entirely (it would be the data).
    """
    artifacts: dict[str, str] = {}
    skipped: list[str] = []
    for path in sorted(run_dir.rglob("*")):
        rel = path.relative_to(run_dir)
        if rel.parts[0] == "mount" or path.is_symlink() or not path.is_file():
            continue
        size = path.stat().st_size
        if size > MAX_ARTIFACT_BYTES:
            skipped.append(f"{rel.as_posix()}\t{size} bytes")
            continue
        artifacts[rel.as_posix()] = _read_text(path)
    if skipped:
        artifacts[SKIPPED_ARTIFACTS_NAME] = (
            f"Files over {MAX_ARTIFACT_BYTES} bytes, not copied:\n" + "\n".join(skipped) + "\n"
        )
    return artifacts
