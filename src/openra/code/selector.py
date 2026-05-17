"""Pick a small, prompt-friendly slice of a reference code repository.

Reference implementations are often hundreds of files; the LLM prompt
has a budget.  ``select_relevant_files`` filters a cloned repo down to
the ~20 most likely to be useful when generating reproduction code.

Heuristic, in order of priority:

1. Files in the repo root take precedence over deeper files
   (most papers ship a top-level ``train.py`` / ``main.py``).
2. Filenames matching a small allowlist (``train``, ``main``, ``model``,
   ``run``, ``reproduce``, ``experiment``, ``eval``) score higher than
   arbitrary names.
3. Python files only.  We skip ``__init__.py`` (usually empty), tests
   (``test_*.py``, ``*_test.py``), conftests, and setup / build files.
4. Any single file larger than ``MAX_FILE_BYTES`` is skipped — those
   are almost always generated data or saved models.

We stop once the cumulative byte count would exceed
``MAX_TOTAL_BYTES``, so the prompt stays bounded regardless of how
many files match.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

MAX_FILES = 20
MAX_FILE_BYTES = 20_000
MAX_TOTAL_BYTES = 200_000

_PREFERRED_STEMS = frozenset(
    {
        "train",
        "main",
        "model",
        "models",
        "run",
        "reproduce",
        "experiment",
        "experiments",
        "eval",
        "evaluation",
        "evaluate",
        "test_model",  # not a unit test — papers sometimes name eval scripts this way
    }
)

_SKIP_STEMS = frozenset(
    {
        "__init__",
        "setup",
        "conftest",
        "_version",
        "version",
    }
)

# Directories whose contents we never include.  These are uniformly noise
# in a research repo: notebooks bloat the prompt, vendored deps add
# nothing, build / cache dirs are obvious skips.
_SKIP_DIRS = frozenset(
    {
        ".git",
        ".github",
        "__pycache__",
        ".ipynb_checkpoints",
        "node_modules",
        "venv",
        ".venv",
        "env",
        "build",
        "dist",
        "docs",
        "tests",
        "test",
        "examples",
        "notebooks",
        "notebook",
    }
)


@dataclass(frozen=True)
class SelectedFile:
    """One file picked by the selector, with its contents pre-read."""

    relative_path: str
    """Path within the cloned repo, POSIX-style for prompt readability."""

    contents: str

    @property
    def size_bytes(self) -> int:
        return len(self.contents.encode("utf-8"))


def select_relevant_files(repo_root: Path) -> list[SelectedFile]:
    """Return up to ``MAX_FILES`` files from ``repo_root`` for the generator prompt.

    Returns ``[]`` if ``repo_root`` does not exist or contains no Python.
    Never raises on permission errors / unreadable files — those are
    skipped with the rest.
    """
    if not repo_root.is_dir():
        return []

    candidates: list[tuple[int, int, Path]] = []  # (priority, depth, path)
    for path in repo_root.rglob("*.py"):
        if not path.is_file():
            continue
        if _should_skip(path, repo_root):
            continue
        try:
            size = path.stat().st_size
        except OSError:
            continue
        if size > MAX_FILE_BYTES or size == 0:
            continue

        relative = path.relative_to(repo_root)
        depth = len(relative.parts) - 1  # files at root have depth 0
        candidates.append((_priority(path, depth), depth, path))

    # Sort: highest priority first; among ties prefer shallower paths;
    # final tiebreak by string for determinism.
    candidates.sort(key=lambda t: (-t[0], t[1], str(t[2])))

    selected: list[SelectedFile] = []
    total_bytes = 0
    for _, _, path in candidates:
        if len(selected) >= MAX_FILES:
            break
        try:
            contents = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        size = len(contents.encode("utf-8"))
        if total_bytes + size > MAX_TOTAL_BYTES:
            continue
        total_bytes += size
        selected.append(
            SelectedFile(
                relative_path=path.relative_to(repo_root).as_posix(),
                contents=contents,
            )
        )
    return selected


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _should_skip(path: Path, repo_root: Path) -> bool:
    """Filter out files we never want, regardless of priority."""
    relative = path.relative_to(repo_root)
    parts = relative.parts
    if any(part in _SKIP_DIRS for part in parts[:-1]):
        return True
    stem = path.stem
    if stem in _SKIP_STEMS:
        return True
    if stem.startswith("test_") or stem.endswith("_test"):
        return True
    return False


def _priority(path: Path, depth: int) -> int:
    """Higher score → more likely to be useful in the generator prompt.

    Composed as: preferred-stem bonus (10) + depth-zero bonus (5).
    Maximum 15 for ``./train.py``; minimum 0 for an arbitrarily-named
    file three directories deep.
    """
    score = 0
    if path.stem.lower() in _PREFERRED_STEMS:
        score += 10
    if depth == 0:
        score += 5
    return score
