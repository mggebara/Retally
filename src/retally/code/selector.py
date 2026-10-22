"""Pick a small, prompt-friendly slice of a reference code repository.

Reference implementations are often hundreds of files; the LLM prompt
has a budget.  Two selectors share that budget philosophy:

``select_relevant_files``
    filters a cloned GitHub repo down to the ~20 Python files most
    likely to be useful when generating reproduction code.

``select_package_scripts``
    walks a *replication package* (the unpacked dataset directory of an
    econ paper — e.g. a Zenodo/Dataverse archive) for the authors' own
    analysis scripts (``.R`` / ``.do`` / ``.Rmd``).  Those scripts are
    the ground truth for the estimating equation, variable names,
    sample restrictions, and clustering choices, so surfacing them to
    the generator matters more than anything reconstructed from the
    methodology summary.

Heuristic for ``select_relevant_files``, in order of priority:

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

# Replication-package analysis scripts (a master .do file routinely runs
# past 20 KB) get a larger per-file allowance; the total stays shared.
MAX_SCRIPT_FILE_BYTES = 60_000

_SCRIPT_SUFFIXES = frozenset({".r", ".do", ".rmd"})

# Stems that look like the analysis entry point of a replication package.
# Matched as substrings (packages name scripts like ``01_main_tables.R``
# or ``wii_replication.do``), unlike the exact-stem match used for repos.
_SCRIPT_PREFERRED_SUBSTRINGS = (
    "master",
    "main",
    "analysis",
    "analyses",
    "table",
    "regression",
    "results",
    "estimat",
    "replicat",
)

# Figure/plot scripts rarely contain the estimating equation and often
# duplicate the tables script — score them below neutral.
_SCRIPT_PENALTY_SUBSTRINGS = ("figure", "fig_", "plot", "map")

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


def select_package_scripts(package_root: Path | None) -> list[SelectedFile]:
    """Return the analysis scripts shipped inside a replication package.

    ``package_root`` is typically ``dataset.local_path`` — the unpacked
    archive an econ paper's data lives in.  Alongside the data, these
    packages almost always contain the scripts that produced the paper's
    tables (Stata ``.do``, R ``.R`` / ``.Rmd``).  Selection heuristic:

    1. Stems that look like the analysis entry point score highest:
       ``master``, ``main``, ``analysis``, ``table(s)``, ``regression(s)``,
       ``results``, ``estimat*``, ``replicat*``.
    2. Figure/map/plot scripts score below neutral — they rarely contain
       the estimating equation and often duplicate a tables script.
    3. Shallower files win ties (packages usually keep the entry point
       at the root or one level down in ``code/`` / ``scripts/``).

    Caps mirror the repo selector's, with a larger per-file allowance
    (``MAX_SCRIPT_FILE_BYTES``) because a single master do-file routinely
    exceeds 20 KB; scripts beyond even that are truncated (head kept,
    with a marker) rather than dropped.  Returns ``[]`` when ``package_root`` is ``None``,
    missing, or contains no scripts.  Never raises on unreadable files.
    """
    if package_root is None or not package_root.is_dir():
        return []

    candidates: list[tuple[int, int, Path]] = []  # (priority, depth, path)
    for path in package_root.rglob("*"):
        if path.suffix.lower() not in _SCRIPT_SUFFIXES or not path.is_file():
            continue
        relative = path.relative_to(package_root)
        if _is_macos_metadata(relative):
            continue
        if any(part in _SKIP_DIRS for part in relative.parts[:-1]):
            continue
        try:
            size = path.stat().st_size
        except OSError:
            continue
        if size == 0:
            continue
        depth = len(relative.parts) - 1
        candidates.append((_script_priority(path, depth), depth, path))

    candidates.sort(key=lambda t: (-t[0], t[1], str(t[2])))

    selected: list[SelectedFile] = []
    total_bytes = 0
    for _, _, path in candidates:
        if len(selected) >= MAX_FILES:
            break
        try:
            contents = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        contents = _truncate_script(contents)
        size = len(contents.encode("utf-8"))
        if total_bytes + size > MAX_TOTAL_BYTES:
            continue
        total_bytes += size
        selected.append(
            SelectedFile(
                relative_path=path.relative_to(package_root).as_posix(),
                contents=contents,
            )
        )
    return selected


def _truncate_script(contents: str) -> str:
    """Cap one script at ``MAX_SCRIPT_FILE_BYTES``, cutting at a line boundary.

    Oversized scripts are truncated rather than skipped: replication
    packages often ship a single monolithic master do-file (Dincecco et
    al. 2022's ``wii_replication.do`` is 185 KB) that runs the main
    tables first and the appendix after, so its head is exactly the
    part the generator needs.  Skipping it left the prompt with no
    scripts at all.  An explicit marker tells the model the file
    continues.
    """
    encoded = contents.encode("utf-8")
    if len(encoded) <= MAX_SCRIPT_FILE_BYTES:
        return contents
    head = encoded[:MAX_SCRIPT_FILE_BYTES].decode("utf-8", errors="ignore")
    cut = head.rfind("\n")
    if cut > 0:
        head = head[: cut + 1]
    omitted = len(encoded) - len(head.encode("utf-8"))
    marker = f"\n... [truncated: {omitted:,} more bytes of this script omitted] ...\n"
    return head + marker


def _is_macos_metadata(relative: Path) -> bool:
    """True for macOS AppleDouble resource-fork stubs (``._name``, ``__MACOSX/``).

    Archives zipped on a Mac carry a ``._<name>`` sidecar for every file
    (binary metadata, not code) and sometimes a parallel ``__MACOSX/``
    tree.  They share the real file's suffix, so a suffix filter alone
    lets them through: on Manekin & Mitts (2022) every selected "script"
    was a ``._replicate_*.R`` stub and the authors' code never reached
    the prompt.  Mirrors the downloader's nested-archive rule.
    """
    return relative.name.startswith("._") or "__MACOSX" in relative.parts


def _should_skip(path: Path, repo_root: Path) -> bool:
    """Filter out files we never want, regardless of priority."""
    relative = path.relative_to(repo_root)
    if _is_macos_metadata(relative):
        return True
    parts = relative.parts
    if any(part in _SKIP_DIRS for part in parts[:-1]):
        return True
    stem = path.stem
    if stem in _SKIP_STEMS:
        return True
    if stem.startswith("test_") or stem.endswith("_test"):
        return True
    return False


def _script_priority(path: Path, depth: int) -> int:
    """Score a replication-package script for prompt inclusion.

    Preferred-substring bonus (10) + depth-zero bonus (5) −
    figure/plot penalty (8).  The penalty outweighs the depth bonus so
    a root-level ``figures.do`` still ranks below a nested
    ``code/tables.do``.
    """
    stem = path.stem.lower()
    score = 0
    if any(sub in stem for sub in _SCRIPT_PREFERRED_SUBSTRINGS):
        score += 10
    if depth == 0:
        score += 5
    if any(sub in stem for sub in _SCRIPT_PENALTY_SUBSTRINGS):
        score -= 8
    return score


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
