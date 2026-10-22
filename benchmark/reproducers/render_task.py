"""Prepare one benchmark cell for a Claude Code session.

    uv run python -m benchmark.reproducers.render_task --entry ID --mode M --run-id R \\
        [--task-root DIR] [--package-dir DIR] [--paper-text FILE] [--force]

Builds ``<task_root>/<entry_id>/<mode>/<run_id>/`` (default task root
``benchmark/.cache/claude-code/``) holding

* ``task.md`` — the task, rendered from ``claude_code_task.md``.  The
  claims, dataset listing, output convention, code requirements, package
  scripts and independent / blind blocks are the pipeline's own
  rendering (``CodeGenerator``'s section helpers), so the agent is shown
  what the pipeline's generator is shown;
* ``paper.txt`` — title line plus the extracted paper text; in blind mode
  every pinned claim value and standard error is redacted;
* ``mount/<package>/`` — the ONLY data the agent gets: the full package
  (seeded) or its script-free copy (independent / blind).  The copy's
  strip manifest is moved OUTSIDE the task directory, to
  ``<task_root>/<entry_id>/<mode>/<run_id>.retally-stripped.json``, so
  nothing in the task directory names a withheld file;
* ``render.json`` — what was rendered, also written to the run's output
  directory ``benchmark/reproductions/<entry_id>/<mode>/<run_id>/``.

It prints the task file, the mount path and the output directory, one
per line.  No API calls; no network when ``--package-dir`` /
``--paper-text`` are given (or the package and paper are cached).
"""

from __future__ import annotations

import json
import os
import re
import shlex
import shutil
import string
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from benchmark import runner
from benchmark import schema as bschema
from benchmark.reproducer import script_free_copy
from benchmark.reproducers.filesystem import (
    REPRODUCTION_SCHEMA,
    reproductions_root,
)
from benchmark.strip_rule import classify_tree, manifest_path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
TASK_ROOT = REPO_ROOT / "benchmark" / ".cache" / "claude-code"
PAPER_CACHE_DIR = TASK_ROOT / "papers"
TEMPLATE_PATH = Path(__file__).resolve().parent / "claude_code_task.md"
MODES = (runner.SEEDED, runner.INDEPENDENT, runner.BLIND)
REDACTED = "[withheld]"

# The pipeline's refinement budgets (``ValidationPipeline.__init__`` defaults).
MAX_REFINEMENTS = 3
MAX_CLAIM_REFINEMENTS = 3


# ---------------------------------------------------------------------------
# Blind redaction
# ---------------------------------------------------------------------------


def value_strings(v: float) -> set[str]:
    """Every way a claim value could plausibly be printed (as ``tests/test_blind_prompt.py`` checks).

    ``str`` / ``repr``, ``%g`` at a few precisions, fixed decimals, and the
    sign-less magnitude of each; integers also bare and comma-grouped.
    Strings shorter than three characters would match unrelated text and
    are dropped.
    """
    forms: set[str] = set()
    for x in (v, abs(v)):
        forms |= {str(x), repr(x), f"{x:g}", f"{x:.6g}", f"{x:.4g}", f"{x:.3g}", f"{x:.4f}", f"{x:.3f}"}
        if float(x).is_integer():
            forms |= {str(int(x)), f"{int(x):,}"}
    return {f for f in forms if len(f) >= 3}


def claim_numbers(entry: bschema.BenchmarkEntry) -> list[float]:
    """The pinned claim values and standard errors of ``entry`` — what blind mode withholds."""
    numbers = [float(oc.value) for oc in entry.original_claims]
    numbers += [float(oc.standard_error) for oc in entry.original_claims if oc.standard_error is not None]
    return numbers


def redact_values(text: str, numbers: list[float]) -> tuple[str, int]:
    """Replace every :func:`value_strings` form of ``numbers`` in ``text`` with ``[withheld]``.

    A plain substring replacement, longest form first: over-redaction is
    fine, and there is deliberately no boundary check on the left, because
    PDF extraction can glue a digit onto a value (Montero's minus sign
    extracts as "2": "242.97" for -42.97).  Two-digit integer values, too
    short for :func:`value_strings`, are redacted as whole numbers.  Returns
    ``(text, replacements)``.
    """
    forms = sorted({f for v in numbers for f in value_strings(v)}, key=lambda f: (-len(f), f))
    n = 0
    for form in forms:
        count = text.count(form)
        if count:
            n += count
            text = text.replace(form, REDACTED)
    # Two-digit integers (a cluster count of 36) are too short for
    # value_strings; redact them as whole numbers only, or every year and
    # page number containing the digits would go too.
    for short in sorted({str(int(abs(v))) for v in numbers if float(v).is_integer() and 10 <= abs(v) < 100}):
        text, count = re.subn(rf"(?<![\d.]){short}(?!\.?\d)", REDACTED, text)
        n += count
    return text, n


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------


@dataclass
class RenderedTask:
    task_file: Path
    mount_path: Path
    output_dir: Path
    render: dict[str, Any]


def render_task(
    entry: bschema.BenchmarkEntry,
    mode: str,
    run_id: str,
    *,
    task_root: Path = TASK_ROOT,
    reproductions_dir: Path | None = None,
    package_dir: Path | None = None,
    paper_text: str | None = None,
    force: bool = False,
) -> RenderedTask:
    """Build the task directory for one (entry, mode, run_id) cell; see the module docstring."""
    from retally.models import ReproductionMode

    if mode not in MODES:
        raise ValueError(f"unknown mode {mode!r}; expected one of {list(MODES)}")
    if not run_id or Path(run_id).name != run_id or run_id in (".", ".."):
        raise ValueError(f"run id {run_id!r} must be a single path component")
    repro_mode = ReproductionMode(mode)
    claims = runner._claims_override_for(entry) or []
    ref = runner._dataset_reference_for(entry)

    cell_dir = Path(task_root).resolve() / entry.id / mode
    task_dir = cell_dir / run_id
    output_dir = (Path(reproductions_dir) if reproductions_dir else reproductions_root()).resolve()
    output_dir = output_dir / entry.id / mode / run_id
    if not force:
        if task_dir.exists():
            raise FileExistsError(f"{task_dir} exists; pass --force to re-render it")
        if (output_dir / "reproduction.json").exists():
            raise FileExistsError(f"{output_dir} already holds a finished run; pass --force to re-render")

    package = Path(package_dir) if package_dir is not None else _download_package(ref)
    if not package.is_dir():
        raise NotADirectoryError(f"package {package} is not a directory")
    if paper_text is None:
        paper_text = _paper_text(entry)

    if task_dir.exists():
        shutil.rmtree(task_dir)
    mount = task_dir / "mount" / package.name
    mount.parent.mkdir(parents=True)
    strip_manifest: Path | None = None
    n_files_stripped: int | None = None
    if repro_mode.withholds_code:
        script_free_copy(package, mount)
        strip_manifest = cell_dir / f"{run_id}.retally-stripped.json"
        shutil.move(str(manifest_path(mount)), strip_manifest)
        n_files_stripped = int(json.loads(strip_manifest.read_text(encoding="utf-8"))["n_stripped"])
        leftover = classify_tree(mount)
        if leftover:
            raise RuntimeError(f"script-free mount {mount} still holds {[s.path for s in leftover]}")
    else:
        shutil.copytree(package, mount, copy_function=_link_or_copy)

    title = entry.paper.title or entry.id
    paper_body = f"{title}\n\n{paper_text}"
    paper_redactions: int | None = None
    if repro_mode.withholds_targets:
        paper_body, paper_redactions = redact_values(paper_body, claim_numbers(entry))
    paper_path = task_dir / "paper.txt"
    paper_path.write_text(paper_body, encoding="utf-8")

    task_text, docker_image = _render_text(
        entry=entry,
        mode=repro_mode,
        run_id=run_id,
        claims=claims,
        title=title,
        source_url=getattr(ref, "url", None) or "",
        mount=mount,
        paper_path=paper_path,
        output_dir=output_dir,
    )
    task_file = task_dir / "task.md"
    task_file.write_text(task_text, encoding="utf-8")

    render = {
        "entry_id": entry.id,
        "mode": mode,
        "run_id": run_id,
        "paper_source": entry.paper.source,
        "language": entry.language.value,
        "task_dir": str(task_dir),
        "mount_path": str(mount.resolve()),
        "output_dir": str(output_dir),
        "n_files_stripped": n_files_stripped,
        "strip_manifest": str(strip_manifest) if strip_manifest else None,
        "paper_redactions": paper_redactions,
        "rendered_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "retally_version": runner._retally_version(),
        "docker_image": docker_image,
    }
    payload = json.dumps(render, indent=2) + "\n"
    (task_dir / "render.json").write_text(payload, encoding="utf-8")
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "render.json").write_text(payload, encoding="utf-8")
    return RenderedTask(task_file=task_file, mount_path=mount.resolve(), output_dir=output_dir, render=render)


def _render_text(
    *,
    entry: bschema.BenchmarkEntry,
    mode: Any,
    run_id: str,
    claims: list[Any],
    title: str,
    source_url: str,
    mount: Path,
    paper_path: Path,
    output_dir: Path,
) -> tuple[str, str]:
    """``(task.md text, docker image)``, with every prompt block rendered by the pipeline's own code."""
    from retally.code.selector import select_package_scripts
    from retally.codegen.docker_executor import _RUN_LABEL_KEY, RDockerExecutor
    from retally.codegen.generator import CodeGenerator
    from retally.models import Dataset, Language, Paper

    gen = CodeGenerator(None)  # the constructor only stores the client; nothing here calls it
    paper = Paper(title=title, claims=claims, language=Language.R)
    dataset = Dataset(name=mount.name, source_url=source_url, local_path=mount, metadata=_metadata(mount))
    prompt = gen._build_generation_prompt_r(paper, dataset, [], None, mode)
    scripts = select_package_scripts(mount) if not mode.withholds_code else []
    scripts_section = gen._package_scripts_section(scripts, Language.R)

    executor = RDockerExecutor()
    label = f"{_RUN_LABEL_KEY}=claude-code-{entry.id}-{mode.value}-{run_id}"
    cmd = executor._build_run_cmd(Path("__SCRIPT__"), dataset, "__LABEL__")
    run_command = (
        shlex.join(cmd)
        .replace("__SCRIPT__", '"$SCRIPT"')
        .replace(shlex.quote(f"{_RUN_LABEL_KEY}=__LABEL__"), shlex.quote(label))
    )

    values = {
        "entry_id": entry.id,
        "mode": mode.value,
        "run_id": run_id,
        "title": title,
        "paper_path": str(paper_path),
        "mount_path": str(mount.resolve()),
        "output_dir": str(output_dir),
        "main_checkout": str(REPO_ROOT),
        "max_refinements": str(MAX_REFINEMENTS),
        "max_claim_refinements": str(MAX_CLAIM_REFINEMENTS),
        "seeded_intro": (
            _indent(scripts_section[1]) if scripts_section else "    (No analysis scripts were found.)"
        ),
        "independent_block": _block(gen._independent_mode_section(mode)),
        "claims_block": _block(gen._claims_section(claims, mode)),
        "dataset_block": _block(gen._dataset_section(dataset, paper)),
        "output_convention_block": _block(_prompt_section(prompt, "## Required Output Convention")),
        "code_requirements_block": _block(_prompt_section(prompt, "## Code Requirements")),
        "package_scripts_block": _block(scripts_section) or "_No analysis scripts were found._\n",
        "run_command": run_command,
        "timeout": str(executor.timeout),
        "memory": executor.memory_limit,
        "cpus": str(executor.cpu_count),
        "label": label,
        "schema": REPRODUCTION_SCHEMA.rstrip("\n"),
    }
    template = _select_mode(TEMPLATE_PATH.read_text(encoding="utf-8"), mode.value)
    return string.Template(template).substitute(values), executor.image


_IF_BLOCK = re.compile(r"^\[\[if ([a-z,]+)\]\]\n(.*?)^\[\[end\]\]\n", re.DOTALL | re.MULTILINE)


def _select_mode(template: str, mode: str) -> str:
    """Keep ``[[if m1,m2]] ... [[end]]`` blocks that name ``mode``; drop the others."""
    return _IF_BLOCK.sub(lambda m: m.group(2) if mode in m.group(1).split(",") else "", template)


def _block(lines: list[str]) -> str:
    return "\n".join(lines).rstrip("\n") + "\n" if lines else ""


def _indent(text: str, prefix: str = "  ") -> str:
    import textwrap

    return textwrap.fill(text, width=100, initial_indent=prefix, subsequent_indent=prefix)


def _prompt_section(prompt: str, header: str) -> list[str]:
    """The lines of one ``## `` section of a rendered prompt, up to its blank line."""
    lines = prompt.splitlines()
    try:
        start = lines.index(header)
    except ValueError as exc:
        raise RuntimeError(f"the pipeline's generation prompt has no {header!r} section") from exc
    end = start
    while end < len(lines) and lines[end].strip():
        end += 1
    return lines[start:end] + [""]


def _metadata(mount: Path) -> dict[str, Any]:
    """``metadata.json`` at the package root, as the pipeline's downloader reads it; ``{}`` otherwise."""
    try:
        data = json.loads((mount / "metadata.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def _link_or_copy(src: str, dst: str) -> object:
    try:
        os.link(src, dst)
        return dst
    except OSError:
        return shutil.copy2(src, dst)


def _download_package(ref: Any) -> Path:
    """The entry's package through the pipeline's downloader (cache ``.cache/datasets``)."""
    if ref is None:
        raise ValueError("the catalog entry names no dataset; pass --package-dir")
    from retally.dataset.downloader import DatasetDownloader

    return Path(DatasetDownloader().download(ref).local_path)


def _paper_text(entry: bschema.BenchmarkEntry) -> str:
    """The paper's extracted text, cached at ``benchmark/.cache/claude-code/papers/<entry_id>.txt``.

    Dispatches on ``entry.paper.source`` as ``ValidationPipeline._parse_paper`` does
    (network for a URL, arXiv id or DOI).
    """
    cached = PAPER_CACHE_DIR / f"{entry.id}.txt"
    if cached.is_file():
        return cached.read_text(encoding="utf-8")
    from retally.paper.parser import PaperParser

    parser = PaperParser()
    source = entry.paper.source
    if source.startswith(("http://", "https://")):
        paper = parser.parse_url(source)
    elif source.endswith(".pdf"):
        paper = parser.parse_pdf(Path(source))
    elif source.endswith(".txt"):
        paper = parser.parse_text(Path(source).read_text())
    elif re.match(r"^\d{4}\.\d{4,5}(v\d+)?$", source):
        paper = parser.parse_arxiv(source)
    elif source.startswith("10."):
        paper = parser.parse_doi(source)
    else:
        paper = parser.parse_text(source)
    text = paper.full_text or ""
    cached.parent.mkdir(parents=True, exist_ok=True)
    cached.write_text(text, encoding="utf-8")
    return text


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    import argparse

    parser = argparse.ArgumentParser(
        prog="python -m benchmark.reproducers.render_task",
        description="Prepare one benchmark cell (entry, mode, run id) for a Claude Code session.",
    )
    parser.add_argument("--entry", required=True, metavar="ID", help="Catalog entry id.")
    parser.add_argument("--mode", required=True, choices=MODES)
    parser.add_argument("--run-id", required=True, metavar="R", help="Run id, e.g. 2026-10-22-a.")
    parser.add_argument(
        "--task-root", type=Path, default=TASK_ROOT, help=f"Default: {runner._display_path(TASK_ROOT)}."
    )
    parser.add_argument(
        "--package-dir", type=Path, help="Use this package directory instead of the downloader's copy."
    )
    parser.add_argument(
        "--paper-text", type=Path, help="Use this file's text instead of parsing the paper source."
    )
    parser.add_argument("--force", action="store_true", help="Re-render an existing task directory.")
    args = parser.parse_args(argv)

    entries = {e.id: e for e in bschema.load_catalog(runner.CATALOG_DIR)}
    entry = entries.get(args.entry)
    if entry is None:
        print(f"Unknown catalog entry id: {args.entry}", file=sys.stderr)
        return 2
    paper_text = args.paper_text.read_text(encoding="utf-8") if args.paper_text else None
    try:
        rendered = render_task(
            entry,
            args.mode,
            args.run_id,
            task_root=args.task_root,
            package_dir=args.package_dir,
            paper_text=paper_text,
            force=args.force,
        )
    except (FileExistsError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        return 2
    print(rendered.task_file)
    print(rendered.mount_path)
    print(rendered.output_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
