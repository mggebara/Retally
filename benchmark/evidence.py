"""Evidence bundles: per cell, what the model was given, what it produced, and how it was scored.

``uv run python -m benchmark.evidence build RESULTS.json [RESULTS2.json ...] [--entry ID]
[--out benchmark/evidence] [--source-root DIR]``

``uv run python -m benchmark.evidence report [--entry ID] [--out FILE] [--evidence DIR]``

A *cell* is one non-skipped results row: (paper, mode, reproducer, run).
``build`` writes, for each one,

    <out>/<entry_id>/<mode>/<reproducer-label>/<run>/
      prompt/        everything the model was given
      output/        everything it produced (scripts, sandbox output, raw replies)
      scoring.json   the row's claim_details next to a fresh re-score with the
                     runner's own comparator, per claim with the ground truth
      CELL.md        a one-page human-readable report of the cell

and stores each paper text the cells reference once, at
``<out>/<entry_id>/paper.txt`` (``paper.blind.txt`` for the blind-redacted
version; a second distinct version of either gets its sha256 prefix in the
name).  ``report`` then renders ``<out>/<entry_id>/REPORT.md`` per paper and
``<out>/INDEX.md`` from what ``build`` wrote.

Where things come from (all read-only; ``--source-root`` defaults to the repo):

* Pipeline rows: ``artifacts_dir`` holds ``prompt-<n>.txt`` (every
  generation / refinement prompt, in call order), ``script.*``,
  ``stdout.txt``, ``stderr.txt``, ``attempt-<n>/``.  The raw reply to each
  prompt — before the pipeline stripped code fences — is looked up by
  request key: the pipeline sends ``{model, max_tokens, messages=[prompt],
  output_config}``, the LLM cache and the LLM oracle both key a request by
  ``sha256(json.dumps(kwargs, sort_keys=True))[:24]``
  (``retally.llm_cache._request_key``), so the reply is found by rebuilding
  the request around the prompt text and trying the few model / effort
  values the pipeline has used.  Oracle rows (a model label with a store
  under ``benchmark/.cache/llm-oracle/<label>/``) read that store's
  ``answers/``; API rows read ``benchmark/.cache/llm/``.  Only
  code-generation prompts are in the artifacts; the pipeline's other calls
  (paper extraction) are counted in the row's usage but leave no prompt.
* Pipeline rows whose artifacts directory is gone: an oracle answer file
  holds only the reply, never the request, so prompts are recoverable only
  from requests still waiting under ``pending/<key>/`` (``prompt.md``).
  Such a prompt is used when it names every pinned claim of the entry and
  carries the mode's prompt section; it is marked "reconstructed" and the
  cell is partial.  Otherwise ``CELL.md`` says the prompt is missing.
* Agent rows (``claude-code``): ``artifacts_dir`` is the scored copy of the
  run directory (``task.md``, ``render.json``, ``script.R``, ``stdout.txt``,
  ``stderr.txt``, ``attempt-<n>/``, ``reproduction.json``);
  ``benchmark/reproductions/<entry>/<mode>/<run_id>/`` fills anything the
  copy lacks.  ``task.md`` is the complete prompt; the paper text it points
  at is the ``paper.txt`` in the render's task directory.

Copy rules: text only; any file over 2 MB is listed with its size instead of
copied; data files (``.dta``, ``.csv``, ``.rds``, …) and anything under a
``mount`` directory are never copied.  Absolute paths are rewritten to ``<repo>``,
``<worktree>``, ``<scratch>`` or ``<home>`` (:func:`normalise_paths`).  Nothing else
is stripped.  A paper
text embedded verbatim in a prompt is replaced by a one-line reference
``[paper text: <entry>/paper.txt, N chars, sha256 …]``.

Scoring: ``scoring.json`` re-runs ``ResultComparator.compare_all`` on the
final stdout's ``RESULT:`` lines (parsed by the executor's parser) against
the catalog's pinned claims under the row's mode — the code path
``benchmark.runner.score_reproduction`` uses — and records, per claim, the
ground-truth record, the tolerance rule (per-type relative tolerance, ±k·SE
band, printed-precision floor, which one bound), the matched ``RESULT:``
name, the absolute and relative error and the verdict, next to the row's own
``claim_details`` entry and whether the two agree.  A disagreement means the
catalog or the comparator changed after the row was written.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from benchmark.metrics import mode_of, model_of, reproducer_of, result_rows

REPO_ROOT = Path(__file__).resolve().parent.parent
EVIDENCE_DIR = REPO_ROOT / "benchmark" / "evidence"
MAX_COPY_BYTES = 2 * 1024 * 1024
"""Files larger than this are listed with their size, never copied."""

DATA_SUFFIXES = frozenset(
    {
        ".dta",
        ".csv",
        ".tsv",
        ".rds",
        ".rdata",
        ".rda",
        ".sav",
        ".xls",
        ".xlsx",
        ".parquet",
        ".feather",
        ".zip",
        ".gz",
        ".7z",
        ".tar",
        ".pdf",
        ".docx",
        ".png",
        ".jpg",
        ".jpeg",
        ".gif",
        ".sas7bdat",
        ".shp",
        ".dbf",
    }
)
"""Never copied: data files and binary formats (the evidence tree is text only)."""

MODE_ORDER = ("seeded", "independent", "blind")
_MODE_SECTIONS = {
    "independent": "## Independent Reproduction",
    "blind": "## Blind Reproduction",
}
# Request shapes the pipeline's generator has sent (``CodeGenerator._call_claude``):
# tried in order when rebuilding a request around a prompt to find its reply.
_REQUEST_MODELS = ("claude-opus-5-5", "claude-opus-4-7", "claude-sonnet-4-6", "claude-opus-4-6")
_REQUEST_EFFORTS: tuple[str | None, ...] = ("high", None, "medium", "xhigh", "max")
_REQUEST_MAX_TOKENS = (16384, 8192, 32000)
_ATTEMPT_DIR = re.compile(r"^attempt-(\d+)$")
_PROMPT_FILE = re.compile(r"^prompt-(\d+)\.txt$")

# Absolute paths are machine-specific; every text file written into the tree
# has them rewritten to placeholders (see :func:`normalise_paths`).
_WORKTREE_PATH = re.compile(
    r"/[^\s\"'`<>|()]*?/\.claude/worktrees/agent-[^/\s\"'`<>|()]+(?:/|(?=[\s\"'`<>|()]|$))"
)
_SCRATCH_PATH = re.compile(
    r"(?:/private)?/tmp/claude-\d+/(?:[^\s\"'`<>|()]*?/scratchpad(?:/|(?=[\s\"'`<>|()]|$)))?"
)

# Last resort, after the repo / worktree / scratch rules: any other path in a
# home directory (e.g. ``~/.claude/projects/...`` an agent declared reading).
_HOME_PATH = re.compile(r"/(?:Users|home)/[^/\s\"'`<>|()]+/")
# Whatever ``/Users/`` prefix that leaves: a home path whose user segment is
# not a plain name, e.g. Stata's ``"/Users/`c(username)'/Downloads"`` or a
# ``"/Users/..."`` placeholder in replication code quoted in a prompt.
_HOME_PREFIX = re.compile(r"/Users/[^/\s\"]*/?")


def repo_roots(*extra: Path) -> list[str]:
    """Absolute repository roots to rewrite to ``<repo>``, longest first.

    The module's own repo (``REPO_ROOT``); when that is an agent worktree
    (``<main>/.claude/worktrees/agent-*``), also the main checkout it
    belongs to; plus any ``extra`` roots (the build's ``--source-root``).
    """
    roots = {str(REPO_ROOT), *(str(Path(e)) for e in extra), *(str(Path(e).resolve()) for e in extra)}
    for root in list(roots):
        parts = Path(root).parts
        if ".claude" in parts and parts[parts.index(".claude") + 1 : parts.index(".claude") + 2] == (
            "worktrees",
        ):
            roots.add(str(Path(*parts[: parts.index(".claude")])))
    return sorted((r for r in roots if r not in ("/", "")), key=len, reverse=True)


def normalise_paths(text: str, roots: list[str]) -> str:
    """``text`` with machine-specific absolute paths rewritten.

    Agent worktrees (``…/.claude/worktrees/agent-*/``) become
    ``<worktree>/``, Claude scratchpads (``/private/tmp/claude-<uid>/…/scratchpad/``,
    or any other ``/tmp/claude-<uid>/`` path) ``<scratch>/``, and each
    repository root in ``roots`` ``<repo>`` — in that order, so a worktree
    inside the repo is not half-rewritten.  Any remaining path in a home
    directory (``/Users/<name>/`` or ``/home/<name>/``) becomes ``<home>/``,
    and so does any ``/Users/`` prefix still left after that (a user segment
    that is not a plain name, such as Stata's `` `c(username)' ``).
    """
    text = _WORKTREE_PATH.sub("<worktree>/", text)
    text = _SCRATCH_PATH.sub("<scratch>/", text)
    for root in roots:
        text = re.sub(re.escape(root) + r"(?=/|[\s\"'`<>|()]|$)", "<repo>", text)
    return _HOME_PREFIX.sub("<home>/", _HOME_PATH.sub("<home>/", text))


# ---------------------------------------------------------------------------
# Sources
# ---------------------------------------------------------------------------


@dataclass
class Sources:
    """Where ``build`` reads from: the repo checkout that holds the gitignored run files."""

    root: Path

    @property
    def roots(self) -> list[str]:
        return repo_roots(self.root)

    def normalise(self, text: str) -> str:
        return normalise_paths(text, self.roots)

    @property
    def oracle_dir(self) -> Path:
        return self.root / "benchmark" / ".cache" / "llm-oracle"

    @property
    def llm_cache_dir(self) -> Path:
        return self.root / "benchmark" / ".cache" / "llm"

    @property
    def reproductions_dir(self) -> Path:
        return self.root / "benchmark" / "reproductions"

    def resolve(self, path: str | None) -> Path | None:
        """A row path (repo-relative or absolute) as an absolute path under this root."""
        if not path:
            return None
        p = Path(path)
        return p if p.is_absolute() else self.root / p

    def rebase(self, absolute: str | None) -> Path | None:
        """An absolute path recorded on another checkout, re-rooted here when it does not exist as given."""
        if not absolute:
            return None
        p = Path(absolute)
        if p.exists():
            return p
        parts = p.parts
        if "benchmark" in parts:
            return self.root.joinpath(*parts[parts.index("benchmark") :])
        return p

    def display(self, path: Path) -> str:
        try:
            return str(path.relative_to(self.root))
        except ValueError:
            return str(path)


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def request_key(kwargs: dict[str, Any]) -> str:
    """Same key as ``retally.llm_cache._request_key`` (kept local so this module needs no API code)."""
    return hashlib.sha256(json.dumps(kwargs, sort_keys=True, default=str).encode("utf-8")).hexdigest()[:24]


def find_reply(prompt: str, store: Path) -> tuple[Path, dict[str, Any]] | None:
    """``(answer file, request shape)`` of the stored reply to ``prompt`` in ``store``, or None."""
    if not store.is_dir():
        return None
    for model in _REQUEST_MODELS:
        for effort in _REQUEST_EFFORTS:
            for max_tokens in _REQUEST_MAX_TOKENS:
                kwargs: dict[str, Any] = {
                    "model": model,
                    "max_tokens": max_tokens,
                    "messages": [{"role": "user", "content": prompt}],
                }
                if effort is not None:
                    kwargs["output_config"] = {"effort": effort}
                path = store / f"{request_key(kwargs)}.json"
                if path.is_file():
                    shape = {"model": model, "max_tokens": max_tokens, "effort": effort}
                    return path, shape
    return None


# ---------------------------------------------------------------------------
# Paper texts: stored once per entry
# ---------------------------------------------------------------------------


@dataclass
class PaperVersion:
    text: str
    redacted: bool
    uses: int = 0
    name: str = ""

    @property
    def sha(self) -> str:
        return sha256_text(self.text)

    def reference(self, entry_id: str) -> str:
        return f"[paper text: {entry_id}/{self.name}, {len(self.text)} chars, sha256 {self.sha}]"


class PaperStore:
    """Distinct paper texts per entry; named after all cells are planned so names are order-free."""

    def __init__(self) -> None:
        self.versions: dict[str, dict[str, PaperVersion]] = defaultdict(dict)

    def add(self, entry_id: str, text: str, *, redacted: bool, count: bool = True) -> PaperVersion:
        sha = sha256_text(text)
        version = self.versions[entry_id].setdefault(sha, PaperVersion(text=text, redacted=redacted))
        if count:
            version.uses += 1
        return version

    def assign_names(self) -> None:
        for versions in self.versions.values():
            for redacted, base in ((False, "paper"), (True, "paper.blind")):
                group = sorted(
                    (v for v in versions.values() if v.redacted == redacted), key=lambda v: (-v.uses, v.sha)
                )
                for i, v in enumerate(group):
                    v.name = f"{base}.txt" if i == 0 else f"{base}.{v.sha[:12]}.txt"

    def replace_embedded(self, entry_id: str, text: str) -> tuple[str, list[PaperVersion]]:
        """``text`` with each verbatim copy of a paper text of ``entry_id`` replaced by its reference."""
        used: list[PaperVersion] = []
        for v in sorted(self.versions.get(entry_id, {}).values(), key=lambda v: -len(v.text)):
            if len(v.text) >= 2000 and v.text in text:
                text = text.replace(v.text, v.reference(entry_id))
                used.append(v)
        return text, used

    def write(self, out_root: Path, entry_ids: set[str]) -> list[Path]:
        written = []
        for entry_id in sorted(entry_ids):
            for v in self.versions.get(entry_id, {}).values():
                if v.uses == 0:
                    continue
                path = out_root / entry_id / v.name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(v.text, encoding="utf-8")
                written.append(path)
        return written


# ---------------------------------------------------------------------------
# Planning a cell
# ---------------------------------------------------------------------------


@dataclass
class Cell:
    row: dict[str, Any]
    results_file: str
    entry_id: str
    mode: str
    reproducer: str
    model: str | None
    label: str
    run: str
    art: Path | None
    rep_dir: Path | None = None
    render: dict[str, Any] | None = None
    manifest: dict[str, Any] | None = None
    paper: PaperVersion | None = None
    paper_path: Path | None = None
    oracle: bool = False
    also_in: list[str] = field(default_factory=list)

    @property
    def is_agent(self) -> bool:
        return self.reproducer != "pipeline"

    @property
    def relpath(self) -> str:
        return f"{self.entry_id}/{self.mode}/{self.label}/{self.run}"


def _read_json(path: Path | None) -> dict[str, Any] | None:
    if path is None or not path.is_file():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    return data if isinstance(data, dict) else None


def _label(row: dict[str, Any], sources: Sources) -> tuple[str, str | None, bool]:
    reproducer = reproducer_of(row)
    model = model_of(row)
    if reproducer == "pipeline":
        oracle = bool(model) and (sources.oracle_dir / str(model)).is_dir()
        return f"pipeline-{model or 'model-unknown'}", model, oracle
    return reproducer.replace("/", "_").replace(":", "_"), model, False


def plan_cells(
    results_files: list[Path], sources: Sources, entries: set[str] | None, papers: PaperStore
) -> list[Cell]:
    cells: dict[str, Cell] = {}
    for path in results_files:
        rows = result_rows(json.loads(path.read_text(encoding="utf-8")))
        for row in rows:
            entry_id = str(row.get("entry_id"))
            if row.get("skipped") or (entries and entry_id not in entries):
                continue
            label, model, oracle = _label(row, sources)
            art = sources.resolve(row.get("artifacts_dir"))
            stamp = Path(str(row.get("artifacts_dir"))).name if row.get("artifacts_dir") else "no-artifacts"
            cell = Cell(
                row=row,
                results_file=path.name,
                entry_id=entry_id,
                mode=mode_of(row),
                reproducer=reproducer_of(row),
                model=model,
                label=label,
                run=stamp,
                art=art,
                oracle=oracle,
            )
            if cell.is_agent:
                _plan_agent(cell, sources)
            key = cell.relpath
            if key in cells:
                prev = cells[key]
                if prev.row.get("artifacts_dir") == row.get("artifacts_dir"):
                    prev.also_in.append(path.name)
                    continue
                # Same run id scored twice from different copies: keep both, apart.
                cell.run = f"{cell.run}@{stamp}"
                key = cell.relpath
            cells[key] = cell
    for cell in cells.values():
        if cell.paper_path is not None and cell.paper_path.is_file():
            text = cell.paper_path.read_text(encoding="utf-8", errors="replace")
            redacted = bool((cell.render or {}).get("paper_redactions") is not None or cell.mode == "blind")
            cell.paper = papers.add(cell.entry_id, text, redacted=redacted)
    return list(cells.values())


def _plan_agent(cell: Cell, sources: Sources) -> None:
    art = cell.art if cell.art is not None and cell.art.is_dir() else None
    manifest = _read_json(art / "reproduction.json") if art else None
    render = _read_json(art / "render.json") if art else None
    run_id = (manifest or {}).get("run_id") or (render or {}).get("run_id")
    if run_id:
        cell.run = str(run_id)
        rep = sources.reproductions_dir / cell.entry_id / cell.mode / str(run_id)
        cell.rep_dir = rep if rep.is_dir() else None
        if cell.rep_dir is not None:
            manifest = manifest or _read_json(rep / "reproduction.json")
            render = render or _read_json(rep / "render.json")
    cell.manifest, cell.render = manifest, render
    task_dir = sources.rebase((render or {}).get("task_dir"))
    if task_dir is not None:
        cell.paper_path = task_dir / "paper.txt"


# ---------------------------------------------------------------------------
# Copying
# ---------------------------------------------------------------------------


@dataclass
class Copied:
    rel: str
    size: int
    source: str


@dataclass
class CellFiles:
    prompts: list[Copied] = field(default_factory=list)
    outputs: list[Copied] = field(default_factory=list)
    refused: list[str] = field(default_factory=list)
    missing: list[str] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)


def _is_text(data: bytes) -> bool:
    if b"\x00" in data[:8192]:
        return False
    try:
        data.decode("utf-8")
    except UnicodeDecodeError:
        return False
    return True


def _copy_file(
    src: Path, dst: Path, rel: str, sources: Sources, files: CellFiles, into: list[Copied]
) -> None:
    shown = sources.display(src)
    if "mount" in src.parts:
        files.refused.append(f"{shown} (inside a data mount; never copied)")
        return
    if src.suffix.lower() in DATA_SUFFIXES:
        files.refused.append(f"{shown} ({src.stat().st_size} bytes; data or binary file, not copied)")
        return
    size = src.stat().st_size
    if size > MAX_COPY_BYTES:
        files.refused.append(f"{shown} ({size} bytes; over the 2 MB limit, not copied)")
        return
    data = src.read_bytes()
    if not _is_text(data):
        files.refused.append(f"{shown} ({size} bytes; not UTF-8 text, not copied)")
        return
    _write_text(sources, dst, rel, data.decode("utf-8"), shown, into)


def _write_text(sources: Sources, dst: Path, rel: str, text: str, source: str, into: list[Copied]) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    data = sources.normalise(text).encode("utf-8")
    dst.write_bytes(data)
    into.append(Copied(rel=rel, size=len(data), source=source))


def _walk(root: Path) -> list[Path]:
    """Files under ``root``, sorted, skipping any ``mount`` directory entirely."""
    out = []
    for p in sorted(root.rglob("*")):
        rel_parts = p.relative_to(root).parts
        if "mount" in rel_parts:
            continue
        if p.is_file():
            out.append(p)
    return out


def _natural(name: str) -> tuple:
    return tuple(int(t) if t.isdigit() else t for t in re.split(r"(\d+)", name))


# ---------------------------------------------------------------------------
# Building one cell
# ---------------------------------------------------------------------------


def build_cell(
    cell: Cell, out_root: Path, sources: Sources, papers: PaperStore, catalog: dict[str, Any]
) -> dict:
    out = out_root / cell.relpath
    if out.exists():
        shutil.rmtree(out)
    (out / "prompt").mkdir(parents=True)
    (out / "output").mkdir(parents=True)
    files = CellFiles()
    art_ok = cell.art is not None and cell.art.is_dir()
    if not art_ok:
        files.missing.append(
            f"artifacts directory {cell.row.get('artifacts_dir') or '(none recorded)'} is not on disk"
        )
    if cell.is_agent:
        final_stdout = _collect_agent(cell, out, sources, papers, files)
    else:
        final_stdout = _collect_pipeline(cell, out, sources, papers, files)
    entry = catalog.get(cell.entry_id)
    scoring = score_cell(cell, entry, final_stdout)
    scoring["cell"] = cell_header(cell, files)
    (out / "scoring.json").write_text(
        sources.normalise(json.dumps(scoring, indent=2, ensure_ascii=False) + "\n"), encoding="utf-8"
    )
    (out / "CELL.md").write_text(sources.normalise(render_cell_md(cell, scoring, files)), encoding="utf-8")
    return {"cell": cell.relpath, "complete": not files.missing, "missing": list(files.missing)}


def _collect_pipeline(
    cell: Cell, out: Path, sources: Sources, papers: PaperStore, files: CellFiles
) -> str | None:
    art = cell.art if cell.art is not None and cell.art.is_dir() else None
    prompts: list[tuple[str, str, str]] = []  # (name, text, source)
    final_stdout: str | None = None
    if art is not None:
        for p in sorted(
            (p for p in art.iterdir() if _PROMPT_FILE.match(p.name)), key=lambda p: _natural(p.name)
        ):
            prompts.append((p.name, p.read_text(encoding="utf-8", errors="replace"), sources.display(p)))
        for src in _walk(art):
            rel = src.relative_to(art).as_posix()
            if _PROMPT_FILE.match(rel):
                continue
            _copy_file(src, out / "output" / rel, f"output/{rel}", sources, files, files.outputs)
        if (art / "stdout.txt").is_file():
            final_stdout = (art / "stdout.txt").read_text(encoding="utf-8", errors="replace")
        else:
            files.missing.append("final stdout.txt")
        if not any((art / n).is_file() for n in ("script.R", "script.py")):
            files.missing.append("final script")
    elif cell.oracle:
        for name, text, source in _reconstruct_from_pending(cell, sources):
            prompts.append((name, text, source))
            files.notes.append(
                f"{name} reconstructed from the oracle's pending request {source} (unverified match)"
            )
    if not prompts:
        files.missing.append("generation prompts (no prompt-<n>.txt)")
    store = sources.oracle_dir / str(cell.model) / "answers" if cell.oracle else sources.llm_cache_dir
    store_name = f"LLM oracle store {cell.model}" if cell.oracle else "LLM cache"
    for name, text, source in prompts:
        replaced, used = papers.replace_embedded(cell.entry_id, text)
        for v in used:
            files.notes.append(
                f"{name}: embedded paper text replaced by a reference to {cell.entry_id}/{v.name}"
            )
        _write_text(sources, out / "prompt" / name, f"prompt/{name}", replaced, source, files.prompts)
        n = _PROMPT_FILE.match(name)
        idx = n.group(1) if n else name
        hit = find_reply(text, store)
        if hit is None:
            files.missing.append(f"raw reply to {name} (not in the {store_name})")
            continue
        path, shape = hit
        reply = str((_read_json(path) or {}).get("text", ""))
        rel = f"output/answer-{idx}.md"
        _write_text(sources, out / rel, rel, reply, sources.display(path), files.outputs)
        files.notes.append(
            f"answer-{idx}.md: reply to {name} from the {store_name} "
            f"(request {path.stem}: model {shape['model']}, "
            f"max_tokens {shape['max_tokens']}, effort {shape['effort']})"
        )
    calls = (cell.row.get("usage") or {}).get("api_calls")
    if isinstance(calls, int) and calls > len(prompts):
        files.notes.append(
            f"usage records {calls} model calls; {len(prompts)} are code-generation prompts kept above, "
            "the other "
            f"{calls - len(prompts)} (paper extraction) leave no prompt in the artifacts"
        )
    return final_stdout


def _reconstruct_from_pending(cell: Cell, sources: Sources) -> list[tuple[str, str, str]]:
    pending = sources.oracle_dir / str(cell.model) / "pending"
    entry_claims = [str(d.get("description")) for d in cell.row.get("claim_details") or []]
    if not pending.is_dir() or not entry_claims:
        return []
    found = []
    for d in sorted(pending.iterdir()):
        prompt = d / "prompt.md"
        if not prompt.is_file():
            continue
        text = prompt.read_text(encoding="utf-8", errors="replace")
        if not all(c in text for c in entry_claims):
            continue
        has = {m for m, h in _MODE_SECTIONS.items() if h in text}
        want = {"seeded": set(), "independent": {"independent"}, "blind": {"independent", "blind"}}[cell.mode]
        if has != want:
            continue
        found.append((f"prompt-{len(found) + 1}.txt", text, sources.display(prompt)))
    return found


def _collect_agent(
    cell: Cell, out: Path, sources: Sources, papers: PaperStore, files: CellFiles
) -> str | None:
    roots = [r for r in (cell.art if cell.art and cell.art.is_dir() else None, cell.rep_dir) if r is not None]
    seen: dict[str, Path] = {}
    for root in roots:  # the scored copy first, then the run directory for anything it lacks
        for src in _walk(root):
            seen.setdefault(src.relative_to(root).as_posix(), src)
    if cell.rep_dir is None:
        files.notes.append(
            f"run directory benchmark/reproductions/{cell.entry_id}/{cell.mode}/{cell.run}/ not on disk; "
            "the scored copy is the only source"
        )
    for rel in ("task.md", "render.json"):
        if rel in seen:
            _copy_file(seen.pop(rel), out / "prompt" / rel, f"prompt/{rel}", sources, files, files.prompts)
        elif rel == "task.md":
            files.missing.append("task.md (the agent's prompt)")
    if cell.paper is not None:
        ref = cell.paper.reference(cell.entry_id)
        shown = sources.display(cell.paper_path) if cell.paper_path else "?"
        _write_text(
            sources,
            out / "prompt" / "paper.txt.ref",
            "prompt/paper.txt.ref",
            f"The task's paper file {shown}:\n{ref}\n",
            shown,
            files.prompts,
        )
    else:
        files.missing.append(
            "paper text the task points at "
            f"({sources.display(cell.paper_path) if cell.paper_path else 'no render.json'})"
        )
    for rel, src in sorted(seen.items(), key=lambda kv: _natural(kv[0])):
        _copy_file(src, out / "output" / rel, f"output/{rel}", sources, files, files.outputs)
    if "stdout.txt" not in seen:
        files.missing.append("final stdout.txt")
    if "script.R" not in seen and "script.py" not in seen:
        files.missing.append("final script")
    if "reproduction.json" not in seen:
        files.missing.append("reproduction.json")
    return seen["stdout.txt"].read_text(encoding="utf-8", errors="replace") if "stdout.txt" in seen else None


# ---------------------------------------------------------------------------
# Scoring
# ---------------------------------------------------------------------------


def score_cell(cell: Cell, entry: Any, final_stdout: str | None) -> dict[str, Any]:
    """Re-score the cell's final stdout with the runner's comparator, next to the row's claim_details."""
    from benchmark.runner import _claims_override_for, _parse_result_lines, _within_tolerance
    from retally.models import ReproductionMode
    from retally.validation.comparator import ResultComparator, printed_half_unit

    row_details = {str(d.get("description")): d for d in cell.row.get("claim_details") or []}
    result: dict[str, Any] = {
        "how": (
            "recomputed: ResultComparator().compare_all(catalog claims, RESULT lines of output/stdout.txt, "
            "mode) - the comparator and claim conversion benchmark.runner.score_reproduction uses; "
            "row: the results row's claim_details entry as written by the run (tolerance, tolerance_source "
            "and rel_err come from there unchanged)."
        ),
        "claims": [],
        "row_only_claims": [],
    }
    claims = _claims_override_for(entry) if entry is not None else None
    if entry is None:
        result["error"] = f"{cell.entry_id} is not in the catalog; only the row's claim_details are shown"
    if final_stdout is None:
        result["error"] = "no final stdout on disk; only the row's claim_details are shown"
    comparator = ResultComparator()
    mode = ReproductionMode(cell.mode)
    policy = comparator.tolerance_policies[mode]
    outputs = _parse_result_lines(final_stdout) if final_stdout is not None else None
    recomputed = (
        comparator.compare_all(claims, outputs, mode=mode) if claims and outputs is not None else None
    )
    findings = {f.claim_id: f for f in (entry.i4r_replicator_findings if entry is not None else [])}
    covered: set[str] = set()
    for i, oc in enumerate(entry.original_claims if entry is not None and claims else []):
        claim = claims[i]
        row = row_details.get(oc.description)
        covered.add(oc.description)
        rec: dict[str, Any] = {
            "name": oc.description,
            "ground_truth": {
                "value": oc.value,
                "standard_error": oc.standard_error,
                "unit": oc.unit,
                "claim_type": oc.claim_type,
                "location": oc.location,
                "context": oc.context,
                "decimals": oc.decimals,
                "sample_size": oc.sample_size,
            },
            "i4r": None,
            "rule": {
                "mode": cell.mode,
                "type_relative_tolerance": comparator._default_tolerance(claim),
                "se_multiplier": policy.se_multiplier,
                "se_band_relative": comparator._se_band(claim, mode),
                "printed_half_unit": printed_half_unit(claim),
            },
            "row": row,
        }
        finding = findings.get(i)
        if finding is not None:
            rec["i4r"] = {
                "reproduced_value": finding.reproduced_value,
                "outcome": getattr(finding.outcome, "value", str(finding.outcome)),
                "notes": finding.notes,
            }
        if recomputed is not None and outputs is not None:
            cr = recomputed[i]
            key, _ = comparator._match_output(claim, outputs)
            reproduced = cr.reproduced_value
            band_rel = float(cr.tolerance)
            claimed = float(oc.value)
            band_abs = (
                band_rel
                if claimed == 0 and cr.tolerance_source == "printed_precision"
                else band_rel * abs(claimed)
            )
            abs_err = None if reproduced is None else abs(float(reproduced) - claimed)
            rel_err = None if reproduced is None else abs_err / max(abs(claimed), 1e-9)  # type: ignore[operator]
            rec["recomputed"] = {
                "result_name": key,
                "reproduced": reproduced,
                "band_source": cr.tolerance_source,
                "band_relative": band_rel,
                "band_absolute": band_abs,
                "abs_err": abs_err,
                "rel_err": rel_err,
                "margin": None if abs_err is None or band_abs == 0 else abs_err / band_abs,
                "passed": bool(cr.passed),
                "notes": cr.notes,
            }
            if finding is not None and finding.reproduced_value is not None and reproduced is not None:
                rec["i4r"]["reproduced_within_band"] = _within_tolerance(
                    float(reproduced), float(finding.reproduced_value), band_rel or 0.01
                )
            rec["agrees_with_row"] = None if row is None else bool(row.get("passed")) == bool(cr.passed)
        else:
            rec["recomputed"] = None
            rec["agrees_with_row"] = None
        rec["verdict"] = _verdict(rec)
        result["claims"].append(rec)
    for name, d in row_details.items():
        if name not in covered:
            result["row_only_claims"].append(d)
    recs = result["claims"]
    result["summary"] = {
        "n_claims": len(recs) or len(row_details),
        "row_passed": sum(1 for d in row_details.values() if d.get("passed")),
        "recomputed_passed": None
        if recomputed is None
        else sum(1 for r in recs if (r.get("recomputed") or {}).get("passed")),
        "disagreements": [r["name"] for r in recs if r.get("agrees_with_row") is False],
    }
    return result


def _verdict(rec: dict[str, Any]) -> str:
    recomputed = rec.get("recomputed")
    if recomputed is not None:
        return "PASS" if recomputed["passed"] else "FAIL"
    row = rec.get("row")
    if row is not None:
        return ("PASS" if row.get("passed") else "FAIL") + " (row)"
    return "n/a"


# ---------------------------------------------------------------------------
# CELL.md
# ---------------------------------------------------------------------------


def cell_header(cell: Cell, files: CellFiles) -> dict[str, Any]:
    row = cell.row
    manifest = cell.manifest or {}
    deviations = list(manifest.get("deviations") or [])
    return {
        "entry_id": cell.entry_id,
        "mode": cell.mode,
        "reproducer": cell.reproducer,
        "label": cell.label,
        "model": cell.model,
        "oracle": cell.oracle,
        "run": cell.run,
        "results_file": cell.results_file,
        "also_in": cell.also_in,
        "artifacts_dir": row.get("artifacts_dir"),
        "run_dir": None
        if cell.rep_dir is None
        else f"benchmark/reproductions/{cell.entry_id}/{cell.mode}/{cell.run}",
        "date": _cell_date(cell),
        "data_access": str(row.get("data_access") or "public"),
        "retally_ran": row.get("retally_ran"),
        "error": row.get("error"),
        "n_claims": len(row.get("claim_details") or []),
        "final": row.get("n_claims_with_paper_match"),
        "first_scored": row.get("n_claims_with_paper_match_first_scored"),
        "first_scored_index": row.get("first_scored_attempt_index"),
        "first_attempt": row.get("n_claims_with_paper_match_first_attempt"),
        "n_refinements": row.get("n_refinements"),
        "n_error_refinements": row.get("n_error_refinements"),
        "n_claim_refinements": row.get("n_claim_refinements"),
        "n_executions": row.get("n_executions"),
        "n_files_stripped": row.get("n_files_stripped"),
        "agrees_with_i4r": row.get("agrees_with_i4r"),
        "deviations_manifest": deviations,
        "deviations_stdout": _stdout_deviations(cell),
        "notes": manifest.get("notes"),
        "files_read_outside_mount": manifest.get("files_read_outside_mount"),
        "paper_text": None if cell.paper is None else cell.paper.name,
        "complete": not files.missing,
        "missing": list(files.missing),
    }


def _stdout_deviations(cell: Cell) -> list[str]:
    from retally.codegen.executor import parse_deviation_notes

    for root in (cell.art, cell.rep_dir):
        if root is not None and (root / "stdout.txt").is_file():
            return parse_deviation_notes((root / "stdout.txt").read_text(encoding="utf-8", errors="replace"))
    return []


def _cell_date(cell: Cell) -> str | None:
    manifest = cell.manifest or {}
    if manifest.get("finished_at"):
        return str(manifest["finished_at"])
    m = re.match(
        r"^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z", Path(str(cell.row.get("artifacts_dir") or "")).name
    )
    if m:
        y, mo, d, h, mi, s = m.groups()
        return f"{y}-{mo}-{d}T{h}:{mi}:{s}Z"
    return None


def _fmt(v: Any) -> str:
    if v is None:
        return "—"
    if isinstance(v, bool):
        return "yes" if v else "no"
    if isinstance(v, float):
        return f"{v:.6g}"
    return str(v)


def _pct(v: Any) -> str:
    return "—" if not isinstance(v, (int, float)) else f"{100 * v:.2f}%"


def _md(s: Any) -> str:
    return str(s).replace("|", "\\|").replace("\n", " ")


def _count(n: Any, total: int) -> str:
    return "—" if n is None else f"{n}/{total}"


def render_cell_md(cell: Cell, scoring: dict[str, Any], files: CellFiles) -> str:
    h = scoring["cell"]
    total = h["n_claims"]
    lines = [
        f"# {cell.entry_id} · {cell.mode} · {cell.label} · {cell.run}",
        "",
        "| | |",
        "|---|---|",
        f"| Paper | `{cell.entry_id}` |",
        f"| Mode | {cell.mode} |",
        f"| Reproducer | {cell.reproducer}" + (" (LLM oracle)" if cell.oracle else "") + " |",
        f"| Model | {_fmt(cell.model)} |",
        f"| Run | {cell.run} |",
        f"| Date | {_fmt(h['date'])} |",
        f"| Data access | {h['data_access']}"
        + (" (package downloaded by hand and placed on disk)" if h["data_access"] == "manual" else "")
        + " |",
        f"| Results file | `benchmark/results/{cell.results_file}`"
        + (f" (also in {', '.join(f'`{f}`' for f in cell.also_in)})" if cell.also_in else "")
        + " |",
        f"| Artifacts | `{_fmt(h['artifacts_dir'])}`"
        + ("" if cell.art is not None and cell.art.is_dir() else " (missing on disk)")
        + " |",
    ]
    if h["run_dir"]:
        lines.append(f"| Run directory | `{h['run_dir']}` |")
    split = ""
    if h["n_error_refinements"] is not None or h["n_claim_refinements"] is not None:
        split = f" ({_fmt(h['n_error_refinements'])} error + {_fmt(h['n_claim_refinements'])} claim)"
    lines += [
        f"| Executions | {_fmt(h['n_executions'])} |",
        f"| Refinements | {_fmt(h['n_refinements'])}{split} |",
        f"| First attempt | {_count(h['first_attempt'], total)} |",
        f"| First scored | {_count(h['first_scored'], total)}"
        + (f" (execution {h['first_scored_index'] + 1})" if isinstance(h["first_scored_index"], int) else "")
        + " |",
        f"| Final | **{_count(h['final'], total)}** |",
    ]
    if h["n_files_stripped"] is not None:
        lines.append(f"| Package files withheld | {h['n_files_stripped']} |")
    if h["error"]:
        lines.append(f"| Error | {_md(h['error'])} |")
    lines.append(f"| Evidence | {'complete' if h['complete'] else 'partial'} |")
    lines += ["", "## Claims", ""]
    summary = scoring["summary"]
    if scoring.get("error"):
        lines += [f"_{scoring['error']}_", ""]
    lines += [
        "| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |",
        "|---|---|---|---|---|---|---|",
    ]
    for rec in scoring["claims"]:
        gt = rec["ground_truth"]
        truth = _fmt(gt["value"]) + (
            f" ({_fmt(gt['standard_error'])})" if gt["standard_error"] is not None else ""
        )
        rc = rec.get("recomputed") or {}
        row = rec.get("row") or {}
        reproduced = rc.get("reproduced", row.get("reproduced"))
        rel_err = rc.get("rel_err", row.get("rel_err"))
        if rc:
            band = f"±{_fmt(rc['band_absolute'])} ({rc['band_source']})"
        elif row:
            band = f"±{_pct(row.get('tolerance'))} rel ({row.get('tolerance_source')})"
        else:
            band = "—"
        verdict = rec["verdict"]
        if rec.get("agrees_with_row") is False:
            verdict += f" ≠ row {'PASS' if row.get('passed') else 'FAIL'}"
        first = row.get("passed_first_scored")
        lines.append(
            f"| `{rec['name']}` | {truth} | {_fmt(reproduced)} | {_pct(rel_err)} | {band} | {verdict} "
            f"| {'—' if first is None else ('PASS' if first else 'FAIL')} |"
        )
    for d in scoring["row_only_claims"]:
        lines.append(
            f"| `{d.get('description')}` (not in catalog now) | {_fmt(d.get('claimed'))} "
            f"| {_fmt(d.get('reproduced'))} "
            f"| {_pct(d.get('rel_err'))} | ±{_pct(d.get('tolerance'))} rel "
            f"| {'PASS' if d.get('passed') else 'FAIL'} (row) | — |"
        )
    lines += [""]
    if summary["recomputed_passed"] is not None:
        agree = "agrees with" if not summary["disagreements"] else "DIFFERS from"
        lines.append(
            f"Re-scored from `output/stdout.txt` with the runner's comparator: "
            f"{summary['recomputed_passed']}/{summary['n_claims']} pass, which {agree} the row's "
            f"{summary['row_passed']}/{summary['n_claims']}."
        )
        if summary["disagreements"]:
            lines.append(
                "Claims whose verdict changed: " + ", ".join(f"`{d}`" for d in summary["disagreements"]) + "."
            )
        lines.append("")
    lines.append("Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).")
    lines += ["", "## Deviations declared", ""]
    devs = [("reproduction.json", d) for d in h["deviations_manifest"]] + [
        ("DEVIATION: line", d) for d in h["deviations_stdout"]
    ]
    if devs:
        lines += [f"- ({src}) {_md(d)}" for src, d in devs]
    else:
        lines.append("_None declared._")
    if h.get("notes"):
        lines += ["", f"Agent notes: {_md(h['notes'])}"]
    if h.get("files_read_outside_mount"):
        lines += [
            "",
            "Files read outside the mount: " + ", ".join(f"`{f}`" for f in h["files_read_outside_mount"]),
        ]
    lines += ["", "## What the model was given", ""]
    lines += _file_list(files.prompts) or ["_Nothing on disk._"]
    lines += ["", "## What it produced", ""]
    lines += _file_list(files.outputs) or ["_Nothing on disk._"]
    lines += ["", "## Executions", ""]
    lines += _executions_md(cell)
    if files.refused:
        lines += ["", "## Not copied", ""] + [f"- {r}" for r in files.refused]
    if files.notes:
        lines += ["", "## Notes", ""] + [f"- {n}" for n in files.notes]
    if files.missing:
        lines += ["", "## Missing", ""] + [f"- {m}" for m in files.missing]
    return "\n".join(lines) + "\n"


EXECUTION_METADATA_PR = "#133"
"""The PR that started writing ``execution.json``; cells built from older artifacts lack it."""


def _executions(cell: Cell) -> list[tuple[str, dict[str, Any]]]:
    """``(label, execution.json)`` per execution in the cell's artifacts: attempt 1..n, then final.

    Only executions whose ``execution.json`` is on disk; empty for cells
    whose artifacts predate it (or agent cells, whose harness never wrote it).
    """
    art = cell.art if cell.art is not None and cell.art.is_dir() else None
    if art is None:
        return []
    found: list[tuple[str, dict[str, Any]]] = []
    attempts = sorted(
        (p for p in art.iterdir() if p.is_dir() and _ATTEMPT_DIR.match(p.name)),
        key=lambda p: _natural(p.name),
    )
    for d in attempts:
        meta = _read_json(d / "execution.json")
        if meta is not None:
            found.append((d.name, meta))
    meta = _read_json(art / "execution.json")
    if meta is not None:
        found.append(("final", meta))
    return found


def _executions_md(cell: Cell) -> list[str]:
    runs = _executions(cell)
    if not runs:
        if cell.is_agent:
            return ["Execution metadata not recorded (the agent harness does not write `execution.json`)."]
        return [f"Execution metadata not recorded (cell built before {EXECUTION_METADATA_PR})."]
    lines = [
        "| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |",
        "|---|---|---|---|---|---|",
    ]
    for label, meta in runs:
        kind = "final" if label == "final" else (meta.get("kind") or "—")
        elapsed = meta.get("elapsed_seconds")
        lines.append(
            f"| {label} | {_md(kind)} | {_fmt(meta.get('exit_code'))} | {_fmt(meta.get('timed_out'))} "
            f"| {'—' if not isinstance(elapsed, (int, float)) else f'{elapsed:.1f}'} "
            f"| {_fmt(meta.get('n_outputs'))} |"
        )
    return lines


def _file_list(items: list[Copied]) -> list[str]:
    return [f"- [`{c.rel}`]({c.rel}) — {c.size:,} bytes, from `{c.source}`" for c in items]


# ---------------------------------------------------------------------------
# build
# ---------------------------------------------------------------------------


def build(
    results_files: list[Path],
    *,
    out_root: Path = EVIDENCE_DIR,
    source_root: Path = REPO_ROOT,
    entries: set[str] | None = None,
    catalog_dir: Path | None = None,
) -> list[dict[str, Any]]:
    from benchmark import schema

    catalog_path = catalog_dir or REPO_ROOT / "benchmark" / "papers"
    catalog = {e.id: e for e in schema.load_catalog(catalog_path)}
    sources = Sources(root=source_root)
    papers = PaperStore()
    cells = plan_cells(results_files, sources, entries, papers)
    papers.assign_names()
    # A build is the whole truth for every paper it touches: stale cells from
    # an earlier build (a results file since dropped) must not linger.
    for entry_id in {c.entry_id for c in cells}:
        if (out_root / entry_id).is_dir():
            shutil.rmtree(out_root / entry_id)
    built = [build_cell(c, out_root, sources, papers, catalog) for c in cells]
    papers.write(out_root, {c.entry_id for c in cells})
    return built


def tree_size(root: Path) -> int:
    return sum(p.stat().st_size for p in root.rglob("*") if p.is_file())


# ---------------------------------------------------------------------------
# report
# ---------------------------------------------------------------------------


def load_cells(evidence: Path, entry_id: str) -> list[dict[str, Any]]:
    cells = []
    for path in sorted((evidence / entry_id).glob("*/*/*/scoring.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        data["_dir"] = path.parent.relative_to(evidence / entry_id).as_posix()
        cells.append(data)
    mode_rank = {m: i for i, m in enumerate(MODE_ORDER)}
    cells.sort(key=lambda c: (mode_rank.get(c["cell"]["mode"], 9), c["cell"]["label"], c["cell"]["run"]))
    return cells


def _passed(rec: dict[str, Any]) -> bool | None:
    rc = rec.get("recomputed")
    if rc is not None:
        return bool(rc["passed"])
    row = rec.get("row")
    return None if row is None else bool(row.get("passed"))


def render_report(entry_id: str, cells: list[dict[str, Any]], entry: Any = None) -> str:
    lines = [f"# Evidence report: {entry_id}", ""]
    if entry is not None:
        lines += [
            f"**{entry.paper.title or entry_id}**"
            + (f" — {', '.join(entry.paper.authors)}" if entry.paper.authors else ""),
            "",
            f"- Paper: {entry.paper.source}",
            f"- I4R report: {entry.i4r_report_url}",
            f"- I4R outcome label: {getattr(entry.outcome_label, 'value', entry.outcome_label)}; "
            f"split: {entry.split}",
            f"- Catalog entry (ground truth): `benchmark/papers/{entry_id}.yaml`",
        ]
        dataset = getattr(entry, "dataset", None)
        access = getattr(dataset, "data_access", "public") if dataset is not None else "public"
        if access == "manual":
            lines.append(
                f"- Data access: manual (package downloaded by hand and placed at `{dataset.source}`"
                + (f"; {dataset.access_notes.strip()}" if dataset.access_notes.strip() else "")
                + ")"
            )
        else:
            lines.append("- Data access: public")
        if entry.notes:
            lines += ["", "> " + entry.notes.strip().replace("\n", "\n> ")]
        lines += ["", "## Pinned claims", ""]
        lines += [
            "| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |",
            "|---|---|---|---|---|---|---|",
        ]
        findings = {f.claim_id: f for f in entry.i4r_replicator_findings}
        for i, oc in enumerate(entry.original_claims):
            f = findings.get(i)
            lines.append(
                f"| {i} | `{oc.description}` | {_fmt(oc.value)} | {_fmt(oc.standard_error)} "
                f"| {_md(oc.location or '')} "
                f"| {_fmt(None if f is None else f.reproduced_value)} "
                f"| {'—' if f is None else getattr(f.outcome, 'value', f.outcome)} |"
            )
        lines.append("")
    # Matrix
    lines += ["## Pass counts: mode × reproducer × run", ""]
    labels = sorted({c["cell"]["label"] for c in cells})
    modes = [m for m in MODE_ORDER if any(c["cell"]["mode"] == m for c in cells)]
    lines += ["| Reproducer | " + " | ".join(modes) + " |", "|---|" + "---|" * len(modes)]
    for label in labels:
        row = [f"`{label}`"]
        for m in modes:
            parts = []
            for c in cells:
                h = c["cell"]
                if h["label"] == label and h["mode"] == m:
                    mark = "" if h["complete"] else "*"
                    parts.append(
                        f"[{_count(h['final'], h['n_claims'])}]({c['_dir']}/CELL.md) ({h['run']}){mark}"
                    )
            row.append("<br>".join(parts) or "—")
        lines.append("| " + " | ".join(row) + " |")
    lines += [
        "",
        "Final pass counts as recorded in the results row; * = partial evidence (see the cell).",
        "",
    ]
    lines += _hand_check(cells)
    lines += ["## Cells", ""]
    for c in cells:
        h = c["cell"]
        s = c["summary"]
        rec = (
            "" if s["recomputed_passed"] is None else f", re-scored {s['recomputed_passed']}/{s['n_claims']}"
        )
        lines += [
            f"### {h['mode']} · {h['label']} · {h['run']}",
            "",
            f"[`{c['_dir']}/CELL.md`]({c['_dir']}/CELL.md) — final {_count(h['final'], h['n_claims'])}{rec}; "
            f"first scored {_count(h['first_scored'], h['n_claims'])}; executions {_fmt(h['n_executions'])}; "
            f"{_fmt(h['date'])}; from `{h['results_file']}`; "
            f"evidence {'complete' if h['complete'] else 'partial'}.",
        ]
        if h["missing"]:
            lines.append("Missing: " + "; ".join(h["missing"]) + ".")
        if s["disagreements"]:
            lines.append(
                "Re-score differs from the row on: " + ", ".join(f"`{d}`" for d in s["disagreements"]) + "."
            )
        lines.append("")
    return "\n".join(lines) + "\n"


def _hand_check(cells: list[dict[str, Any]]) -> list[str]:
    lines = ["## What to hand-check", ""]
    # 1. Narrowest margins.
    margins = []
    for c in cells:
        for rec in c["claims"]:
            rc = rec.get("recomputed") or {}
            if rc.get("margin") is not None:
                margins.append((abs(float(rc["margin"]) - 1.0), c, rec, rc))
    margins.sort(key=lambda t: t[0])
    lines += [
        "### Narrowest margins",
        "",
        "Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is "
        "one rounding away from flipping).",
        "",
    ]
    if margins:
        lines += [
            "| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |",
            "|---|---|---|---|---|---|---|",
        ]
        for _, c, rec, rc in margins[:10]:
            lines.append(
                f"| [{c['_dir']}]({c['_dir']}/CELL.md) | `{rec['name']}` | {_fmt(rc['reproduced'])} "
                f"| {_fmt(rec['ground_truth']['value'])} "
                f"| ±{_fmt(rc['band_absolute'])} ({rc['band_source']}) "
                f"| {rc['margin']:.3f} | {'PASS' if rc['passed'] else 'FAIL'} |"
            )
    else:
        lines.append("_No re-scored claims._")
    lines.append("")
    # 2. Declared deviations.
    lines += ["### Declared deviations", ""]
    any_dev = False
    for c in cells:
        h = c["cell"]
        devs = list(h.get("deviations_manifest") or []) + list(h.get("deviations_stdout") or [])
        if not devs:
            continue
        any_dev = True
        failed = [r["name"] for r in c["claims"] if _passed(r) is False]
        lines.append(
            f"- [{c['_dir']}]({c['_dir']}/CELL.md) ({_count(h['final'], h['n_claims'])}"
            + (f"; failed: {', '.join(f'`{n}`' for n in failed)}" if failed else "")
            + ")"
        )
        for d in devs:
            named = [r["name"] for r in c["claims"] if r["name"] in d]
            lines.append(
                f"  - {_md(d)}" + (f" — names {', '.join(f'`{n}`' for n in named)}" if named else "")
            )
    if not any_dev:
        lines.append("_No cell declared a deviation._")
    lines.append("")
    # 3. Pipeline vs agent disagreements, per mode and claim.
    lines += [
        "### Pipeline and agent disagree",
        "",
        "Claims where, in the same mode, one reproducer family passed in every run and the other "
        "failed in every run (pass counts per family).",
        "",
    ]
    tallies: dict[tuple[str, str], dict[str, list[bool]]] = defaultdict(lambda: defaultdict(list))
    for c in cells:
        fam = "pipeline" if c["cell"]["reproducer"] == "pipeline" else "agent"
        for rec in c["claims"]:
            p = _passed(rec)
            if p is not None:
                tallies[(c["cell"]["mode"], rec["name"])][fam].append(p)
    rows = []
    mixed = []
    for (mode, name), fams in sorted(
        tallies.items(),
        key=lambda kv: (MODE_ORDER.index(kv[0][0]) if kv[0][0] in MODE_ORDER else 9, kv[0][1]),
    ):
        if "pipeline" not in fams or "agent" not in fams:
            continue
        pv, av = fams["pipeline"], fams["agent"]
        p_all, p_none, a_all, a_none = all(pv), not any(pv), all(av), not any(av)
        desc = f"pipeline {sum(pv)}/{len(pv)}, agent {sum(av)}/{len(av)}"
        if (p_all and a_none) or (p_none and a_all):
            rows.append(f"- {mode}: `{name}` — {desc}")
        elif (sum(pv) / len(pv)) != (sum(av) / len(av)) and abs(sum(pv) / len(pv) - sum(av) / len(av)) >= 0.5:
            mixed.append(f"- {mode}: `{name}` — {desc}")
    lines += rows or ["_None._"]
    if mixed:
        lines += ["", "Pass rates at least 50 points apart (not unanimous):", ""] + mixed
    lines.append("")
    # 4. Row vs re-score.
    diffs = [(c, d) for c in cells for d in c["summary"]["disagreements"]]
    if diffs:
        lines += ["### Re-score differs from the recorded row", ""]
        lines += [f"- [{c['_dir']}]({c['_dir']}/CELL.md): `{d}`" for c, d in diffs]
        lines.append("")
    return lines


def render_index(evidence: Path) -> str:
    lines = [
        "# Evidence bundles",
        "",
        'Built by `python -m benchmark.evidence`; see `benchmark/README.md` ("Evidence bundles").',
        "",
    ]
    for entry_dir in sorted(p for p in evidence.iterdir() if p.is_dir()):
        cells = load_cells(evidence, entry_dir.name)
        if not cells:
            continue
        lines += [f"## [{entry_dir.name}]({entry_dir.name}/REPORT.md)", ""]
        for c in cells:
            h = c["cell"]
            lines.append(
                f"- [{h['mode']} · {h['label']} · {h['run']}]({entry_dir.name}/{c['_dir']}/CELL.md) — "
                f"{_count(h['final'], h['n_claims'])}" + ("" if h["complete"] else " (partial)")
            )
        lines.append("")
    return "\n".join(lines) + "\n"


def report(
    evidence: Path = EVIDENCE_DIR,
    *,
    entries: list[str] | None = None,
    out: Path | None = None,
    catalog_dir: Path | None = None,
) -> list[Path]:
    from benchmark import schema

    catalog = {e.id: e for e in schema.load_catalog(catalog_dir or REPO_ROOT / "benchmark" / "papers")}
    ids = entries or sorted(
        p.name for p in evidence.iterdir() if p.is_dir() and any(p.glob("*/*/*/scoring.json"))
    )
    written = []
    for entry_id in ids:
        cells = load_cells(evidence, entry_id)
        target = out if out is not None and len(ids) == 1 else evidence / entry_id / "REPORT.md"
        target.parent.mkdir(parents=True, exist_ok=True)
        text = render_report(entry_id, cells, catalog.get(entry_id))
        target.write_text(normalise_paths(text, repo_roots()), encoding="utf-8")
        written.append(target)
    index = evidence / "INDEX.md"
    index.write_text(normalise_paths(render_index(evidence), repo_roots()), encoding="utf-8")
    written.append(index)
    return written


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m benchmark.evidence", description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build", help="write prompt/, output/, scoring.json and CELL.md per non-skipped row")
    b.add_argument("results", type=Path, nargs="+", help="results files written by benchmark.runner")
    b.add_argument("--entry", action="append", metavar="ID", help="only this entry id (repeatable)")
    b.add_argument(
        "--out", type=Path, default=EVIDENCE_DIR, help="evidence root (default benchmark/evidence)"
    )
    b.add_argument(
        "--source-root",
        type=Path,
        default=REPO_ROOT,
        help="checkout holding the gitignored artifacts, reproductions and caches (default: this repo)",
    )
    b.add_argument("--catalog", type=Path, default=None, help="catalog directory (default benchmark/papers)")
    r = sub.add_parser("report", help="render <entry>/REPORT.md per paper and INDEX.md from a built tree")
    r.add_argument("--entry", action="append", metavar="ID", help="only this entry id (repeatable)")
    r.add_argument("--out", type=Path, default=None, help="output file (only with a single --entry)")
    r.add_argument(
        "--evidence", type=Path, default=EVIDENCE_DIR, help="evidence root (default benchmark/evidence)"
    )
    r.add_argument("--catalog", type=Path, default=None, help="catalog directory (default benchmark/papers)")
    args = parser.parse_args(argv)
    if args.cmd == "build":
        built = build(
            args.results,
            out_root=args.out,
            source_root=args.source_root,
            entries=set(args.entry) if args.entry else None,
            catalog_dir=args.catalog,
        )
        n_complete = sum(1 for b in built if b["complete"])
        for item in built:
            status = "complete" if item["complete"] else "partial: " + "; ".join(item["missing"])
            print(f"{item['cell']}: {status}")
        size = tree_size(args.out) if args.out.exists() else 0
        print(
            f"{len(built)} cells ({n_complete} complete, {len(built) - n_complete} partial); "
            f"tree {size:,} bytes"
        )
        return 0
    written = report(args.evidence, entries=args.entry, out=args.out, catalog_dir=args.catalog)
    for p in written:
        print(p)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
