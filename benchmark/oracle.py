"""Driver for the LLM oracle — ``python -m benchmark.oracle``.

In LLM-oracle mode (``python -m benchmark.runner --llm-oracle LABEL``) the
pipeline's Claude calls are answered from
``benchmark/.cache/llm-oracle/<label>/`` instead of the API
(``retally.llm_oracle``).  A call with no answer writes its prompt to
``pending/<key>/prompt.md`` and the cell is skipped as
``llm_answer_pending``.  This driver manages that store:

* ``pending`` — list the prompts waiting for an answer;
* ``show KEY`` — print the paths of a prompt (for the shell);
* ``answer KEY FILE`` — install FILE's text as KEY's answer;
* ``install`` — install every ``pending/<key>/answer.md`` an answering
  agent wrote next to its prompt (the bulk path);
* ``status`` — counts of answered and pending prompts.

Pure file operations: nothing here calls an API, runs the pipeline, or
touches the real LLM cache (``benchmark/.cache/llm/``).
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
from pathlib import Path

from retally.llm_oracle import ANSWER_FILENAME, ANSWERS_DIRNAME, PENDING_DIRNAME, write_answer

REPO_ROOT = Path(__file__).resolve().parent.parent
ORACLE_DIR = REPO_ROOT / "benchmark" / ".cache" / "llm-oracle"
"""Parent of every oracle label's store; never the real LLM cache (``benchmark/.cache/llm``)."""

LLM_ORACLE_ENV = "RETALLY_LLM_ORACLE"
"""Same variable as ``benchmark.runner.LLM_ORACLE_ENV``: its value is the default ``--label``."""

DEFAULT_LABEL = "desktop-opus"
DEFAULT_ANSWERED_BY = "desktop-opus-subagent"


def oracle_root(label: str) -> Path:
    """The store for ``label``: ``benchmark/.cache/llm-oracle/<label>/``."""
    return ORACLE_DIR / label


def _pending_dirs(root: Path) -> list[Path]:
    pending = root / PENDING_DIRNAME
    if not pending.is_dir():
        return []
    return sorted(p for p in pending.iterdir() if p.is_dir())


def _meta(pending_dir: Path) -> dict:
    try:
        return json.loads((pending_dir / "meta.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def _install(root: Path, key: str, text: str, label: str, answered_by: str) -> Path:
    """Write ``answers/<key>.json`` and remove ``pending/<key>/``; return the answer path."""
    path = write_answer(root, key, text, label, answered_by)
    shutil.rmtree(root / PENDING_DIRNAME / key)
    return path


def cmd_pending(root: Path, args: argparse.Namespace) -> int:
    dirs = _pending_dirs(root)
    if not dirs:
        print(f"No pending prompts under {root}.")
        return 0
    for d in dirs:
        meta = _meta(d)
        has_answer = "answer.md present" if (d / ANSWER_FILENAME).exists() else "no answer.md"
        print(
            f"{d.name}  {meta.get('kind', '?')}  {meta.get('prompt_chars', '?')} chars  "
            f"{meta.get('created_at', '?')}  {has_answer}"
        )
    return 0


def cmd_show(root: Path, args: argparse.Namespace) -> int:
    d = root / PENDING_DIRNAME / args.key
    if not d.is_dir():
        print(f"{args.key} is not pending under {root}", file=sys.stderr)
        return 2
    print((d / "prompt.md").resolve())
    print((d / "request.json").resolve())
    return 0


def cmd_answer(root: Path, args: argparse.Namespace) -> int:
    if not (root / PENDING_DIRNAME / args.key).is_dir():
        print(f"{args.key} is not pending under {root}", file=sys.stderr)
        return 2
    text = Path(args.file).read_text(encoding="utf-8")
    if not text.strip():
        print(f"Refusing an empty answer from {args.file}", file=sys.stderr)
        return 2
    path = _install(root, args.key, text, args.label, args.by)
    print(f"Installed {args.key} ({len(text)} chars) -> {path}")
    return 0


def cmd_install(root: Path, args: argparse.Namespace) -> int:
    installed = 0
    for d in _pending_dirs(root):
        answer = d / ANSWER_FILENAME
        if not answer.exists():
            continue
        text = answer.read_text(encoding="utf-8")
        if not text.strip():
            print(f"Skipping {d.name}: {ANSWER_FILENAME} is empty", file=sys.stderr)
            continue
        path = _install(root, d.name, text, args.label, args.by)
        print(f"Installed {d.name} ({len(text)} chars) -> {path}")
        installed += 1
    remaining = len(_pending_dirs(root))
    print(f"{installed} answer(s) installed; {remaining} prompt(s) still pending.")
    return 0


def cmd_status(root: Path, args: argparse.Namespace) -> int:
    answers_dir = root / ANSWERS_DIRNAME
    answers = sorted(answers_dir.glob("*.json")) if answers_dir.is_dir() else []
    chars = 0
    for a in answers:
        try:
            chars += len(str(json.loads(a.read_text(encoding="utf-8"))["text"]))
        except (OSError, json.JSONDecodeError, KeyError, TypeError):
            continue
    print(
        f"LLM oracle '{args.label}' ({root}): {len(answers)} answered ({chars} chars), "
        f"{len(_pending_dirs(root))} pending."
    )
    return 0


def main(argv: list[str] | None = None) -> int:
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument(
        "--label",
        default=os.environ.get(LLM_ORACLE_ENV) or DEFAULT_LABEL,
        help=f"Oracle label (default ${LLM_ORACLE_ENV} or {DEFAULT_LABEL}); the store is "
        "benchmark/.cache/llm-oracle/<label>/.",
    )
    common.add_argument(
        "--by",
        default=DEFAULT_ANSWERED_BY,
        help=f"Recorded as answered_by on installed answers (default {DEFAULT_ANSWERED_BY}).",
    )
    parser = argparse.ArgumentParser(
        prog="python -m benchmark.oracle",
        description="Manage the LLM oracle's pending prompts and installed answers.",
    )
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("pending", parents=[common], help="List the prompts waiting for an answer.")
    show = sub.add_parser(
        "show", parents=[common], help="Print the paths of a pending prompt.md and request.json."
    )
    show.add_argument("key")
    answer = sub.add_parser("answer", parents=[common], help="Install FILE's text as the answer for KEY.")
    answer.add_argument("key")
    answer.add_argument("file")
    sub.add_parser("install", parents=[common], help=f"Install every pending/<key>/{ANSWER_FILENAME}.")
    sub.add_parser("status", parents=[common], help="Counts of answered and pending prompts.")
    args = parser.parse_args(argv)

    commands = {
        "pending": cmd_pending,
        "show": cmd_show,
        "answer": cmd_answer,
        "install": cmd_install,
        "status": cmd_status,
    }
    return commands[args.command](oracle_root(args.label), args)


if __name__ == "__main__":
    raise SystemExit(main())
