"""Memorisation probe — ``python -m benchmark.probe``.

Every catalog paper predates every model's training cutoff, so the
benchmark cannot split pre- from post-cutoff papers.  The probe is the
cheap substitute: ask a model for each pinned claim's number *from
memory*, with no data, no paper text and no tools, and score the answers
with the same tolerance blind mode uses.  A hit means the number is
recoverable from training data; a miss does not mean the paper was
unseen.

The answering happens out of band, as for the LLM oracle
(``benchmark/oracle.py``): a Claude Code subagent with no tools reads one
``prompt.md`` and writes its reply, verbatim, to ``answer.md`` beside it.
This driver manages the store, ``benchmark/.cache/probe/<label>/``:

* ``render [--split dev|holdout]`` — write ``<entry_id>/prompt.md`` and
  ``meta.json`` for every in-scope catalog entry with pinned claims;
* ``pending`` — list rendered entries with no installed answer;
* ``show ENTRY`` — print the paths of an entry's ``prompt.md`` and the
  ``answer.md`` the answering agent should write;
* ``answer ENTRY FILE`` — install FILE's text as ENTRY's answer;
* ``install`` — install every ``<entry_id>/answer.md`` into
  ``answer.json`` (with ``answered_at`` and ``answered_by``);
* ``status`` — counts of rendered, answered and pending entries;
* ``score [--out FILE] [--compare FILE ...]`` — score every installed
  answer, write a runner-shaped result file and print a Markdown table.

What the prompt shows: the paper's title and authors (the YAML's
``paper.title`` / ``paper.authors``), the journal and year, and for each
pinned claim its ``description`` token (the name to answer under), its
``claim_type`` and its curated ``context``, verbatim.  No unit, location,
value, standard error or note.  The catalog has no journal or year
field, so both are parsed from the header comment's ``# Original paper:``
citation (that line and its ``#``-continuation lines, joined): the year
is the first ``(YYYY)``, the journal is the text between the title's
closing quote and the first ``, <digit>`` (the volume).  Either is left
out when the citation does not parse.  ``render`` refuses to write a
prompt that states any pinned value or standard error of the entry (as
printed, or rounded to 1-3 significant figures; see :func:`leaked_values`).

Scoring calls the comparator exactly as blind mode does:
``ResultComparator().compare(claim, value, mode=ReproductionMode.BLIND)``
on the claims ``benchmark.runner._claims_override_for`` builds from the
catalog — the ±1·SE band where an SE is pinned, the per-type relative
tolerance otherwise, never narrower than the printed-precision floor.
Each answer is compared with its own claim only (by name, not through the
runner's substring matcher, so a null can never borrow another claim's
value).

Pure file operations: nothing here calls an API or runs a reproducer.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from decimal import ROUND_HALF_EVEN, Decimal, InvalidOperation
from pathlib import Path
from statistics import median
from typing import Any

from benchmark import metrics
from benchmark import schema as bschema

REPO_ROOT = Path(__file__).resolve().parent.parent
PROBE_DIR = REPO_ROOT / "benchmark" / ".cache" / "probe"
"""Parent of every probe label's store."""

PAPERS_DIR = REPO_ROOT / "benchmark" / "papers"
RESULTS_DIR = REPO_ROOT / "benchmark" / "results"

DEFAULT_LABEL = "desktop-opus"
DEFAULT_ANSWERED_BY = "desktop-opus-subagent"

PROMPT_FILENAME = "prompt.md"
META_FILENAME = "meta.json"
ANSWER_MD = "answer.md"
ANSWER_JSON = "answer.json"

PROBE_MODE = "probe"
PROBE_REPRODUCER = "memory-probe"

CONFIDENCE_LEVELS = ("recalled", "inferred", "none")

INSTRUCTION = (
    "From memory only, with no data and no tools, give your best estimate of each quantity "
    "as the paper reports it. Answer as a JSON object mapping each name to a number, or null "
    "if you have no recollection. Then a one-line `CONFIDENCE:` rating per name: `recalled` "
    "(you remember this specific paper's number), `inferred` (a guess from domain knowledge), "
    "or `none`."
)


def probe_root(label: str) -> Path:
    """The store for ``label``: ``benchmark/.cache/probe/<label>/``."""
    return PROBE_DIR / label


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


# ---------------------------------------------------------------------------
# Catalog
# ---------------------------------------------------------------------------


def in_scope(entry: bschema.BenchmarkEntry) -> bool:
    """Entries the runner would execute (``_check_skip``) that pin claims to probe."""
    from benchmark.runner import _check_skip

    return bool(entry.original_claims) and _check_skip(entry) is None


def probe_entries(papers_dir: Path = PAPERS_DIR, split: str | None = None) -> list[bschema.BenchmarkEntry]:
    entries = [e for e in bschema.load_catalog(papers_dir) if in_scope(e)]
    if split is not None:
        entries = [e for e in entries if e.split == split]
    return entries


_CITATION_START = re.compile(r"^#\s*Original paper:\s*(.*)$")


def header_citation(yaml_text: str) -> str | None:
    """The ``# Original paper:`` citation of a catalog YAML's header comment, joined to one line."""
    lines = yaml_text.splitlines()
    for i, line in enumerate(lines):
        m = _CITATION_START.match(line)
        if not m:
            continue
        parts = [m.group(1).strip()]
        for cont in lines[i + 1 :]:
            if not cont.startswith("#"):
                break
            body = cont[1:].strip()
            if not body or _CITATION_START.match(cont):
                break
            parts.append(body)
        return " ".join(p for p in parts if p)
    return None


def journal_and_year(citation: str | None) -> tuple[str | None, str | None]:
    """``(journal, year)`` parsed from a citation; either None when it does not parse."""
    if not citation:
        return None, None
    year_m = re.search(r"\((\d{4})\)", citation)
    journal_m = re.search(r"[.?!]\"\s*(.+?),\s*\d", citation)
    journal = journal_m.group(1).strip() if journal_m else None
    return journal, (year_m.group(1) if year_m else None)


# ---------------------------------------------------------------------------
# Prompt and leak check
# ---------------------------------------------------------------------------


def render_prompt(entry: bschema.BenchmarkEntry, journal: str | None, year: str | None) -> str:
    lines = ["# Recall a paper's reported numbers", ""]
    lines.append(f"Paper: {entry.paper.title or entry.id}")
    if entry.paper.authors:
        lines.append(f"Authors: {', '.join(entry.paper.authors)}")
    venue = ", ".join(x for x in (journal, year) if x)
    if venue:
        lines.append(f"Published: {venue}")
    lines += ["", "## Quantities", ""]
    for oc in entry.original_claims:
        lines.append(f"- `{oc.description}` ({oc.claim_type}): {oc.context.strip()}")
    names = [oc.description for oc in entry.original_claims]
    lines += [
        "",
        "## Instructions",
        "",
        INSTRUCTION,
        "",
        "Format:",
        "",
        "```json",
        "{"
        + ", ".join(f'"{n}": <number or null>' for n in names[:2])
        + (", ..." if len(names) > 2 else "")
        + "}",
        "```",
        "",
        f"CONFIDENCE: {names[0]}: recalled|inferred|none" if names else "CONFIDENCE: <name>: <level>",
        "",
    ]
    return "\n".join(lines)


def _round_sig(x: float, sig: int) -> str:
    """``x`` rounded to ``sig`` significant figures, written as a plain decimal."""
    d = Decimal(repr(x))
    if d == 0:
        return "0"
    exp = d.adjusted() - sig + 1
    q = d.quantize(Decimal(1).scaleb(exp), rounding=ROUND_HALF_EVEN)
    return format(q, "f")


def value_forms(v: float, decimals: int | None = None) -> set[str]:
    """Every way a prompt could state ``v``: as printed and rounded to 1-3 significant figures.

    Signed and sign-less, ``repr``/``%g``, fixed at the printed ``decimals``,
    with thousands separators for integers.  Two exemptions keep round
    numbers in the curated text from reading as leaks:

    * integer forms below 10 ("3", "0") are dropped: they are table and
      column references, not values;
    * an integer value (a count) is not checked at one significant figure:
      186 -> "200" or 327 -> "300" would match a "$200" threshold or a
      "300 ha" bandwidth.  Its 2- and 3-figure roundings ("190", "186")
      are checked, as is every rounding of a non-integer value
      (0.0178 -> "0.02").
    """
    forms: set[str] = set()
    for x in (float(v), abs(float(v))):
        forms |= {repr(x), f"{x:g}"}
        if decimals is not None and decimals >= 0:
            forms.add(f"{x:.{decimals}f}")
        sigs = (2, 3) if x.is_integer() else (1, 2, 3)
        candidates = [repr(x)] + [_round_sig(x, s) for s in sigs]
        for c in candidates:
            forms.add(c)
            try:
                dc = Decimal(c)
            except InvalidOperation:
                continue
            if dc == dc.to_integral_value():
                forms |= {str(int(dc)), f"{int(dc):,}"}
    out = set()
    for f in forms:
        try:
            n = float(f.replace(",", ""))
        except ValueError:
            continue
        if n.is_integer() and abs(n) < 10:
            continue
        out.add(f)
    return out


_REFERENCE_WORD = re.compile(r"(?:column|col\.|table|panel|study|wave|figure)\s*$", re.IGNORECASE)


def _stated(form: str, text: str) -> bool:
    """``form`` occurs in ``text`` as a whole number, not introduced by a table-reference word
    ("Table 12") and not an ordinal ("25th percentile")."""
    for m in re.finditer(rf"(?<![\d.]){re.escape(form)}(?!\d|st\b|nd\b|rd\b|th\b)", text):
        if not _REFERENCE_WORD.search(text[: m.start()]):
            return True
    return False


def leaked_values(prompt: str, entry: bschema.BenchmarkEntry) -> list[str]:
    """Pinned values / standard errors of ``entry`` that ``prompt`` states; empty when clean."""
    text = " ".join(prompt.split())
    found = []
    for oc in entry.original_claims:
        targets = [("value", oc.value, oc.decimals)]
        if oc.standard_error is not None:
            se_lit = repr(float(oc.standard_error))
            targets.append(("standard_error", oc.standard_error, bschema.infer_decimals(se_lit)))
        for kind, v, dec in targets:
            for form in sorted(value_forms(v, dec)):
                if _stated(form, text):
                    found.append(f"{oc.description}.{kind} as {form!r}")
    return sorted(set(found))


# ---------------------------------------------------------------------------
# Commands: render / pending / show / answer / install / status
# ---------------------------------------------------------------------------


def render_entry(root: Path, entry: bschema.BenchmarkEntry, yaml_text: str, label: str) -> Path:
    """Write ``<root>/<entry.id>/prompt.md`` and ``meta.json``; raise if the prompt leaks a value."""
    journal, year = journal_and_year(header_citation(yaml_text))
    prompt = render_prompt(entry, journal, year)
    leaks = leaked_values(prompt, entry)
    if leaks:
        raise ValueError(f"{entry.id}: the probe prompt states pinned numbers: {', '.join(leaks)}")
    d = root / entry.id
    d.mkdir(parents=True, exist_ok=True)
    (d / PROMPT_FILENAME).write_text(prompt, encoding="utf-8")
    meta = {
        "entry": entry.id,
        "label": label,
        "n_claims": len(entry.original_claims),
        "created_at": _now(),
    }
    (d / META_FILENAME).write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
    return d / PROMPT_FILENAME


def _entry_dirs(root: Path) -> list[Path]:
    if not root.is_dir():
        return []
    return sorted(p for p in root.iterdir() if p.is_dir() and (p / PROMPT_FILENAME).exists())


def _write_answer(d: Path, text: str, label: str, answered_by: str) -> Path:
    path = d / ANSWER_JSON
    payload = {
        "entry": d.name,
        "label": label,
        "text": text,
        "answered_at": _now(),
        "answered_by": answered_by,
    }
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return path


def cmd_render(root: Path, args: argparse.Namespace) -> int:
    papers_dir = Path(args.papers_dir)
    entries = probe_entries(papers_dir, args.split)
    for entry in entries:
        yaml_text = (papers_dir / f"{entry.id}.yaml").read_text(encoding="utf-8")
        path = render_entry(root, entry, yaml_text, args.label)
        print(f"{entry.id}  {len(entry.original_claims)} claims -> {path}")
    print(f"{len(entries)} prompt(s) rendered under {root}.")
    return 0


def cmd_pending(root: Path, args: argparse.Namespace) -> int:
    dirs = [d for d in _entry_dirs(root) if not (d / ANSWER_JSON).exists()]
    if not dirs:
        print(f"No pending prompts under {root}.")
        return 0
    for d in dirs:
        has_answer = "answer.md present" if (d / ANSWER_MD).exists() else "no answer.md"
        print(f"{d.name}  {has_answer}")
    return 0


def cmd_show(root: Path, args: argparse.Namespace) -> int:
    d = root / args.entry
    if not (d / PROMPT_FILENAME).exists():
        print(f"{args.entry} has no prompt under {root}", file=sys.stderr)
        return 2
    print((d / PROMPT_FILENAME).resolve())
    print((d / ANSWER_MD).resolve())
    return 0


def cmd_answer(root: Path, args: argparse.Namespace) -> int:
    d = root / args.entry
    if not (d / PROMPT_FILENAME).exists():
        print(f"{args.entry} has no prompt under {root}", file=sys.stderr)
        return 2
    text = Path(args.file).read_text(encoding="utf-8")
    if not text.strip():
        print(f"Refusing an empty answer from {args.file}", file=sys.stderr)
        return 2
    path = _write_answer(d, text, args.label, args.by)
    print(f"Installed {args.entry} ({len(text)} chars) -> {path}")
    return 0


def cmd_install(root: Path, args: argparse.Namespace) -> int:
    installed = 0
    for d in _entry_dirs(root):
        answer = d / ANSWER_MD
        if not answer.exists():
            continue
        text = answer.read_text(encoding="utf-8")
        if not text.strip():
            print(f"Skipping {d.name}: {ANSWER_MD} is empty", file=sys.stderr)
            continue
        existing = _load_answer(d)
        if existing is not None and existing.get("text") == text:
            continue
        path = _write_answer(d, text, args.label, args.by)
        print(f"Installed {d.name} ({len(text)} chars) -> {path}")
        installed += 1
    remaining = sum(1 for d in _entry_dirs(root) if not (d / ANSWER_JSON).exists())
    print(f"{installed} answer(s) installed; {remaining} prompt(s) still pending.")
    return 0


def cmd_status(root: Path, args: argparse.Namespace) -> int:
    dirs = _entry_dirs(root)
    answered = sum(1 for d in dirs if (d / ANSWER_JSON).exists())
    print(
        f"Probe '{args.label}' ({root}): {len(dirs)} rendered, {answered} answered, "
        f"{len(dirs) - answered} pending."
    )
    return 0


# ---------------------------------------------------------------------------
# Parsing answers
# ---------------------------------------------------------------------------


_CONFIDENCE_LINE = re.compile(r"^\W*confidence\b", re.IGNORECASE)
_RATING = re.compile(r"([A-Za-z0-9_]+)\W+(recalled|inferred|none)\b", re.IGNORECASE)


def parse_answer(text: str) -> tuple[dict[str, Any], dict[str, str]]:
    """``(values, confidence)`` from an answer's text.

    Tolerant: code fences are ignored, ``CONFIDENCE`` lines are removed
    before the JSON object (first ``{`` to its last ``}``) is parsed, and a
    bare ``CONFIDENCE:`` header followed by ``name: level`` lines is read
    as well as ``CONFIDENCE: name: level``.  Raises ``ValueError`` when no
    JSON object can be read.
    """
    confidence: dict[str, str] = {}
    body: list[str] = []
    in_block = False
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("```"):
            continue
        if _CONFIDENCE_LINE.match(stripped):
            rest = _CONFIDENCE_LINE.sub("", stripped, count=1)
            m = _RATING.search(rest)
            if m:
                confidence[m.group(1)] = m.group(2).lower()
                in_block = False
            else:
                in_block = True
            continue
        if in_block:
            m = _RATING.search(stripped)
            if m and "{" not in stripped:
                confidence[m.group(1)] = m.group(2).lower()
                continue
            if stripped:
                in_block = False
        body.append(line)
    joined = "\n".join(body)
    start, end = joined.find("{"), joined.rfind("}")
    if start < 0 or end <= start:
        raise ValueError("no JSON object in the answer")
    obj = json.loads(joined[start : end + 1])
    if not isinstance(obj, dict):
        raise ValueError("the answer's JSON is not an object")
    return obj, confidence


def _as_number(x: Any) -> float | None:
    if x is None or isinstance(x, bool):
        return None
    if isinstance(x, int | float):
        return float(x)
    try:
        return float(str(x).replace(",", "").strip())
    except ValueError:
        return None


def _load_answer(d: Path) -> dict[str, Any] | None:
    try:
        payload = json.loads((d / ANSWER_JSON).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    return payload if isinstance(payload, dict) else None


# ---------------------------------------------------------------------------
# Scoring
# ---------------------------------------------------------------------------


def blind_compare(claim: Any, value: float | None) -> Any:
    """The comparator call blind mode makes for one claim (``ClaimValidationResult``)."""
    from retally.models import ReproductionMode
    from retally.validation.comparator import ResultComparator

    return ResultComparator().compare(claim, value, mode=ReproductionMode.BLIND)


def score_entry(entry: bschema.BenchmarkEntry, answer: dict[str, Any]) -> dict[str, Any]:
    """One runner-shaped result row for ``entry`` from an installed ``answer.json`` payload."""
    from benchmark.runner import BenchmarkResult, _claim_detail, _claims_override_for, _result_to_jsonable

    text = str(answer.get("text") or "")
    parse_error = None
    try:
        values, confidence = parse_answer(text)
    except (ValueError, json.JSONDecodeError) as exc:
        values, confidence, parse_error = {}, {}, str(exc)

    claims = _claims_override_for(entry) or []
    results = [blind_compare(c, _as_number(values.get(c.description))) for c in claims]
    result = BenchmarkResult(
        entry_id=entry.id,
        mode=PROBE_MODE,
        reproducer=PROBE_REPRODUCER,
        split=entry.split,
        retally_ran=parse_error is None,
        agrees_with_paper=bool(results) and all(r.passed for r in results),
        n_claims_in_catalog=len(entry.original_claims),
        n_claims_with_paper_match=sum(1 for r in results if r.passed),
        claim_details=[_claim_detail(r) for r in results],
        error=parse_error,
    )
    row = _result_to_jsonable(result)
    for cd in row["claim_details"]:
        name = cd["description"]
        cd.update(
            name=name,
            paper_value=cd["claimed"],
            answered=cd["reproduced"],
            within_tolerance=cd["passed"],
            confidence=confidence.get(name),
        )
    row.update(
        label=answer.get("label"),
        answered_by=answer.get("answered_by"),
        answered_at=answer.get("answered_at"),
        n_answered=sum(1 for cd in row["claim_details"] if cd["answered"] is not None),
    )
    return row


def score_store(root: Path, papers_dir: Path = PAPERS_DIR) -> list[dict[str, Any]]:
    catalog = {e.id: e for e in bschema.load_catalog(papers_dir)}
    rows = []
    for d in _entry_dirs(root):
        answer = _load_answer(d)
        if answer is None or d.name not in catalog:
            continue
        rows.append(score_entry(catalog[d.name], answer))
    return rows


def write_probe_results(rows: list[dict[str, Any]], out_path: Path) -> None:
    from benchmark import pricing

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(
        json.dumps({"usage": pricing.aggregate(rows), "results": rows}, indent=2) + "\n",
        encoding="utf-8",
    )


def _within(cd: dict[str, Any], k: float) -> bool:
    return cd.get("rel_err") is not None and cd["rel_err"] <= k * cd["tolerance"]


def _summary(rows: list[dict[str, Any]]) -> dict[str, Any]:
    details = [cd for r in rows for cd in r["claim_details"]]
    answered = [cd for cd in details if cd.get("answered") is not None]
    conf = Counter(cd.get("confidence") or "missing" for cd in details)
    return {
        "n": len(details),
        "answered": len(answered),
        "tol": sum(1 for cd in details if cd.get("within_tolerance")),
        "x2": sum(1 for cd in answered if _within(cd, 2.0)),
        "x5": sum(1 for cd in answered if _within(cd, 5.0)),
        "median": median(cd["rel_err"] for cd in answered) if answered else None,
        "conf": conf,
    }


def _blind_cells(compare_files: list[Path]) -> list[tuple[str, dict[str, str]]]:
    """Per compare file: ``(column title, {entry_id: "k/n" cell})`` from its blind rows."""
    columns = []
    for path in compare_files:
        rows = metrics.result_rows(json.loads(path.read_text(encoding="utf-8")))
        by_entry: dict[str, list[str]] = {}
        blind = [r for r in rows if metrics.mode_of(r) == "blind"]
        multi = len(metrics.reproducers_present(blind)) > 1
        for r in blind:
            cell = (
                "skip"
                if r.get("skipped")
                else f"{r.get('n_claims_with_paper_match', 0)}/{r.get('n_claims_in_catalog', 0)}"
            )
            if multi:
                cell += f" ({metrics.reproducer_of(r)})"
            by_entry.setdefault(r["entry_id"], []).append(cell)
        columns.append((f"blind: {path.stem}", {k: ", ".join(v) for k, v in by_entry.items()}))
    return columns


def markdown_table(rows: list[dict[str, Any]], compare_files: list[Path] | None = None) -> str:
    columns = _blind_cells(compare_files or [])
    head = [
        "paper",
        "claims",
        "answered",
        "within tol",
        "within 2x",
        "within 5x",
        "median rel err",
        "recalled / inferred / none / missing",
    ] + [c[0] for c in columns]
    out = ["| " + " | ".join(head) + " |", "|" + "---|" * len(head)]

    def line(name: str, s: dict[str, Any], extra: list[str]) -> str:
        med = "—" if s["median"] is None else f"{s['median']:.1%}"
        c = s["conf"]
        conf = f"{c['recalled']} / {c['inferred']} / {c['none']} / {c['missing']}"
        cells = [name, str(s["n"]), str(s["answered"]), str(s["tol"]), str(s["x2"]), str(s["x5"]), med, conf]
        return "| " + " | ".join(cells + extra) + " |"

    for r in sorted(rows, key=lambda r: r["entry_id"]):
        extra = [col.get(r["entry_id"], "—") for _, col in columns]
        out.append(line(r["entry_id"], _summary([r]), extra))
    out.append(line("**total**", _summary(rows), ["" for _ in columns]))
    return "\n".join(out)


def cmd_score(root: Path, args: argparse.Namespace) -> int:
    rows = score_store(root, Path(args.papers_dir))
    if not rows:
        print(f"No installed answers under {root}.", file=sys.stderr)
        return 1
    date = datetime.now(timezone.utc).date().isoformat()
    out = Path(args.out) if args.out else RESULTS_DIR / f"probe-{args.label}-{date}.json"
    write_probe_results(rows, out)
    for r in rows:
        if r.get("error"):
            print(f"{r['entry_id']}: answer did not parse ({r['error']})", file=sys.stderr)
    print(markdown_table(rows, [Path(p) for p in args.compare or []]))
    print(f"\nWrote {out}")
    return 0


def main(argv: list[str] | None = None) -> int:
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument(
        "--label",
        default=DEFAULT_LABEL,
        help=f"Probe label (default {DEFAULT_LABEL}); the store is benchmark/.cache/probe/<label>/.",
    )
    common.add_argument(
        "--by",
        default=DEFAULT_ANSWERED_BY,
        help=f"Recorded as answered_by on installed answers (default {DEFAULT_ANSWERED_BY}).",
    )
    common.add_argument("--papers-dir", default=str(PAPERS_DIR), help=argparse.SUPPRESS)
    parser = argparse.ArgumentParser(
        prog="python -m benchmark.probe",
        description="Memorisation probe: render recall prompts, install answers, score them.",
    )
    sub = parser.add_subparsers(dest="command", required=True)
    render = sub.add_parser("render", parents=[common], help="Write prompt.md for every in-scope entry.")
    render.add_argument("--split", choices=["dev", "holdout"], default=None, help="Only this split.")
    sub.add_parser("pending", parents=[common], help="List rendered entries with no installed answer.")
    show = sub.add_parser(
        "show", parents=[common], help="Print the paths of ENTRY's prompt.md and answer.md."
    )
    show.add_argument("entry")
    answer = sub.add_parser("answer", parents=[common], help="Install FILE's text as ENTRY's answer.")
    answer.add_argument("entry")
    answer.add_argument("file")
    sub.add_parser("install", parents=[common], help=f"Install every <entry>/{ANSWER_MD}.")
    sub.add_parser("status", parents=[common], help="Counts of rendered, answered and pending entries.")
    score = sub.add_parser(
        "score", parents=[common], help="Score installed answers with the blind tolerance."
    )
    score.add_argument(
        "--out", default=None, help="Result file (default benchmark/results/probe-<label>-<date>.json)."
    )
    score.add_argument(
        "--compare",
        nargs="+",
        default=None,
        metavar="FILE",
        help="Result files whose blind rows to show alongside.",
    )
    args = parser.parse_args(argv)

    commands = {
        "render": cmd_render,
        "pending": cmd_pending,
        "show": cmd_show,
        "answer": cmd_answer,
        "install": cmd_install,
        "status": cmd_status,
        "score": cmd_score,
    }
    return commands[args.command](probe_root(args.label), args)


if __name__ == "__main__":
    raise SystemExit(main())
