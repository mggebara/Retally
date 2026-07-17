"""Turn the I4R meta-database into prefilled benchmark candidate YAMLs.

Reads the Institute for Replication "First Meta Database" (committed under
``benchmark/corpus/`` — see ``benchmark/corpus/SOURCE.md`` for provenance)
and emits one candidate YAML per replication report that OpenRA could
plausibly run, into ``benchmark/candidates/``.

Candidates are **not** catalog entries.  They land in ``benchmark/candidates/``
(gitignored-review-staging, distinct from ``benchmark/papers/``) prefilled
with everything the database gives — id, report URL, outcome label, language,
authors, title — and with ``TODO`` sentinels for the three things the
database never records: the paper URL, the dataset URL, and (for most reports)
the I4R report URL.  A human promotes a candidate by filling those TODOs from
the actual I4R report PDF and moving the file into ``benchmark/papers/``.

Scope filter — a report becomes a candidate only when OpenRA has a code path
for it, i.e. the target language resolves to R or Python (see
``resolve_language``).  Stata / MATLAB / Julia originals with no R replication
routine are dropped; the run summary reports the funnel so the
catalogued-vs-runnable gap stays visible.

Why claim seeding is left to promotion: the database carries the original and
replicator coefficients per estimate (``o_coeff_dbl`` / ``r_coeff_dbl``),
which are exactly the ``original_claims`` / ``i4r_replicator_findings`` values
the benchmark's ``agrees_with_i4r`` verdict wants.  But their descriptions are
terse table references (``"table 3"``) that won't align with what the pipeline's
claim extractor produces, and a report can carry 200+ of them.  Transcribing
them blindly would bloat every candidate with unreviewed noise, so this script
leaves ``original_claims`` empty (matching the first real catalog entry) and
lets a human seed curated claims during promotion.

Usage::

    uv run python scripts/import_i4r_candidates.py            # all runnable reports
    uv run python scripts/import_i4r_candidates.py --limit 5  # first 5 (by id)
    uv run python scripts/import_i4r_candidates.py --corpus path/to/other.csv.gz
"""

from __future__ import annotations

import argparse
import csv
import gzip
import re
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CORPUS = REPO_ROOT / "benchmark" / "corpus" / "i4r_first_meta_database.csv.gz"
DEFAULT_OUT_DIR = REPO_ROOT / "benchmark" / "candidates"

# The database labels an *unselected* survey checkbox with this string; a
# selected one holds the language name ("R", "Stata", ...).  Anything else
# (including blank) counts as not-selected.
NOT_SELECTED = "Response not selected"

# Placeholder authors the database uses to pad the fixed six name slots.
_ABSENT_AUTHOR = re.compile(r"^\s*no author number", re.IGNORECASE)

# Report-level columns are stored on a single summary row per team and left
# blank on the others; ``first_nonempty`` pulls the populated one.
_TODO_PAPER = "TODO: URL / DOI / arXiv id of the original paper (extractor input)"
_TODO_DATASET = "TODO: open dataset URL (Zenodo / Dataverse / OSF) — see the I4R report"
_TODO_REPORT = "TODO: I4R report URL — look up this paper at https://i4replication.org/reports"


@dataclass
class Candidate:
    """The fields we can fill for one I4R replication report."""

    id: str
    i4r_report_url: str
    language: str
    outcome_label: str
    title: str
    authors: list[str]
    journal: str
    year: str
    team: str
    original_language: str
    replicator_wrote_r: bool
    reproduction_summary: str
    paper_source: str = _TODO_PAPER
    dataset_source: str = _TODO_DATASET
    split: str = "dev"
    # True when i4r_report_url is a real link from the database rather than a TODO.
    has_report_url: bool = False


# ---------------------------------------------------------------------------
# Pure helpers — the tests cover each of these directly.
# ---------------------------------------------------------------------------


def slugify(text: str, max_words: int = 5) -> str:
    """Lowercase, keep the first ``max_words`` alphanumeric words, dash-join.

    Stopwords are dropped so ``"The Long-Run Effects of Sports Club Vouchers"``
    becomes ``long-run-effects-sports-club`` rather than ``the-long-run-effects-of``.
    """
    stop = {"the", "a", "an", "of", "and", "or", "in", "on", "to", "for", "with", "at"}
    words = re.findall(r"[a-z0-9]+", text.lower())
    kept = [w for w in words if w not in stop] or words
    return "-".join(kept[:max_words])


def surname(full_name: str) -> str:
    """Best-effort last token of a name, slugified (``"Alberto Alesina"`` -> ``alesina``)."""
    tokens = re.findall(r"[A-Za-z][A-Za-z'-]*", full_name)
    return re.sub(r"[^a-z0-9]", "", tokens[-1].lower()) if tokens else "unknown"


def collect_authors(row: dict[str, str], max_authors: int = 6) -> list[str]:
    """Real author names from the fixed ``o_a_name_1..N`` slots.

    Drops blanks and the ``"No Author Number N"`` padding the database uses to
    fill unused slots.
    """
    out: list[str] = []
    for i in range(1, max_authors + 1):
        name = (row.get(f"o_a_name_{i}") or "").strip()
        if name and not _ABSENT_AUTHOR.match(name):
            out.append(name)
    return out


def _selected(value: str | None, language: str) -> bool:
    """True when a ``*_prog_lang_*`` cell records that ``language`` was used."""
    return (value or "").strip() == language


def resolve_language(row: dict[str, str]) -> str | None:
    """Which language OpenRA should target for this report, or ``None`` to skip.

    * Original authors used R  -> ``"r"``      (regenerate R directly)
    * Original authors used Python -> ``"python"``
    * Original in Stata/MATLAB/Julia but the I4R replicator wrote an R routine
      -> ``"r"``  (the Dincecco case: R ground truth to validate against)
    * Otherwise -> ``None`` (out of OpenRA's scope; dropped)

    R is preferred over Python when the originals used both, matching the
    R-leaning bias of the current sandbox tooling.
    """
    if _selected(row.get("o_a_prog_lang_R"), "R"):
        return "r"
    if _selected(row.get("o_a_prog_lang_python"), "Python"):
        return "python"
    if _selected(row.get("report_prog_lang_R"), "R"):
        return "r"
    return None


def original_language(row: dict[str, str]) -> str:
    """Human-readable label of what the original authors coded in."""
    for col, label in (
        ("o_a_prog_lang_R", "R"),
        ("o_a_prog_lang_Stata", "Stata"),
        ("o_a_prog_lang_python", "Python"),
        ("o_a_prog_lang_matlab", "MATLAB"),
        ("o_a_prog_lang_julia", "Julia"),
    ):
        if _selected(row.get(col), label):
            return label
    return "unknown"


def map_outcome(perfect: str, computational: str) -> str:
    """Collapse the database's reproduction fields to a benchmark OutcomeLabel.

    ``perfect_reproduction`` is a clean Yes/No; ``computational_reproduction``
    is 1/0 (did the replicators reach a reproduction verdict at all).  We map
    "reproduced exactly" to ``reproducible``, a reached-but-imperfect verdict to
    ``inconclusive`` (reproduced-with-discrepancies — a human refines it), an
    explicit failure to ``not_reproducible``, and everything unknown to
    ``inconclusive``.
    """
    perfect = (perfect or "").strip().lower()
    computational = (computational or "").strip()
    if perfect == "yes":
        return "reproducible"
    if perfect == "no":
        # Computationally attempted but not an exact match: don't overclaim
        # either way — flag for human classification from the report.
        return "inconclusive"
    if computational in ("0", "0.0"):
        return "not_reproducible"
    if computational in ("1", "1.0"):
        return "reproducible"
    return "inconclusive"


def first_nonempty(rows: list[dict[str, str]], column: str) -> str:
    """First non-blank value of ``column`` across a report's rows.

    Report-level fields sit on one summary row and are blank on the rest, so a
    naive ``rows[0][column]`` misses them.
    """
    for row in rows:
        value = (row.get(column) or "").strip()
        if value:
            return value
    return ""


# ---------------------------------------------------------------------------
# Assembly
# ---------------------------------------------------------------------------


def build_candidate(team: str, rows: list[dict[str, str]]) -> Candidate | None:
    """Assemble a ``Candidate`` from one report's rows, or ``None`` if out of scope."""
    language = resolve_language(rows[0])
    if language is None:
        return None

    title = first_nonempty(rows, "paper_title") or "Untitled"
    year = first_nonempty(rows, "year_published")
    authors = collect_authors(rows[0])
    link = first_nonempty(rows, "replication_link")

    lead = surname(authors[0]) if authors else "unknown"
    year_slug = year.split(".")[0] if year else "n-d"
    slug = slugify(title)
    entry_id = "-".join(p for p in (lead, year_slug, slug) if p)

    return Candidate(
        id=entry_id,
        i4r_report_url=link or _TODO_REPORT,
        has_report_url=bool(link),
        language=language,
        outcome_label=map_outcome(
            first_nonempty(rows, "perfect_reproduction"),
            first_nonempty(rows, "computational_reproduction"),
        ),
        title=title,
        authors=authors,
        journal=first_nonempty(rows, "journal"),
        year=year_slug,
        team=str(int(float(team))) if team.replace(".", "").isdigit() else team,
        original_language=original_language(rows[0]),
        replicator_wrote_r=_selected(rows[0].get("report_prog_lang_R"), "R"),
        reproduction_summary=first_nonempty(rows, "best_describe_compreprod"),
    )


def load_candidates(corpus: Path) -> list[Candidate]:
    """Read the corpus CSV(.gz) and return in-scope candidates, sorted by id."""
    opener = gzip.open if corpus.suffix == ".gz" else open
    with opener(corpus, "rt", encoding="utf-8", newline="") as handle:
        by_team: dict[str, list[dict[str, str]]] = defaultdict(list)
        for row in csv.DictReader(handle):
            by_team[row["replicator_team"]].append(row)

    candidates = [c for team, rows in by_team.items() if (c := build_candidate(team, rows))]

    # Disambiguate any id collisions (two reports of similarly-titled papers)
    # by appending the internal team id — stable and unique.
    seen: dict[str, int] = defaultdict(int)
    for c in candidates:
        seen[c.id] += 1
    for c in candidates:
        if seen[c.id] > 1:
            c.id = f"{c.id}-r{c.team}"

    candidates.sort(key=lambda c: c.id)
    return candidates


# ---------------------------------------------------------------------------
# YAML rendering — hand-built (not yaml.dump) to keep TODO comments and a
# stable, reviewable field order that mirrors the catalog's real entries.
# ---------------------------------------------------------------------------


def _yaml_str(value: str) -> str:
    """Quote a scalar for YAML.  Double-quote and escape when needed."""
    if value == "":
        return '""'
    if re.search(r'[:#\[\]{}",\n]', value) or value.strip() != value:
        return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'
    return value


def render_yaml(c: Candidate) -> str:
    lines = [
        "# AUTO-GENERATED CANDIDATE — review before promoting to benchmark/papers/.",
        "# Fill every TODO from the I4R report PDF, then move this file into",
        "# benchmark/papers/ (see benchmark/README.md, 'Adding a new paper').",
        f"# Source: I4R First Meta Database, replication report team {c.team}.",
        "",
        f"id: {c.id}",
    ]
    if not c.has_report_url:
        lines.append(f"i4r_report_url: {_yaml_str(c.i4r_report_url)}  # TODO")
    else:
        lines.append(f"i4r_report_url: {_yaml_str(c.i4r_report_url)}")
    lines += [
        f"language: {c.language}",
        f"outcome_label: {c.outcome_label}  # from the database; verify against the report",
        f"split: {c.split}",
        "",
        "paper:",
        f"  source: {_yaml_str(c.paper_source)}  # TODO",
        f"  title: {_yaml_str(c.title)}",
    ]
    if c.authors:
        lines.append("  authors:")
        lines += [f"    - {_yaml_str(a)}" for a in c.authors]
    else:
        lines.append("  authors: []")
    lines += [
        "",
        "dataset:",
        f"  source: {_yaml_str(c.dataset_source)}  # TODO",
        "",
        "original_claims: []",
        "i4r_replicator_findings: []",
        "",
        "notes: >",
    ]
    note = (
        f"{c.journal or 'journal n/a'} ({c.year}). Original code language: "
        f"{c.original_language}."
        + (" I4R replicator wrote an R routine (R-verified)." if c.replicator_wrote_r else "")
        + (f" I4R reproduction outcome: {c.reproduction_summary}." if c.reproduction_summary else "")
        + " Auto-imported from the I4R First Meta Database; claims and dataset"
        " location still need to be filled from the report before promotion."
    )
    lines.append(f"  {note}")
    return "\n".join(lines) + "\n"


def write_candidates(candidates: list[Candidate], out_dir: Path) -> list[Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    for c in candidates:
        path = out_dir / f"{c.id}.yaml"
        path.write_text(render_yaml(c), encoding="utf-8")
        written.append(path)
    return written


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def _summarize(candidates: list[Candidate]) -> str:
    by_lang: dict[str, int] = defaultdict(int)
    with_url = 0
    for c in candidates:
        by_lang[c.language] += 1
        with_url += c.has_report_url
    langs = ", ".join(f"{k}={v}" for k, v in sorted(by_lang.items()))
    return (
        f"{len(candidates)} candidates ({langs}); "
        f"{with_url} have a real i4r_report_url, "
        f"{len(candidates) - with_url} need one filled in"
    )


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--corpus", type=Path, default=DEFAULT_CORPUS)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT_DIR)
    parser.add_argument("--limit", type=int, default=None, help="Only write the first N (by id).")
    args = parser.parse_args(argv)

    candidates = load_candidates(args.corpus)
    if args.limit is not None:
        candidates = candidates[: args.limit]

    written = write_candidates(candidates, args.out_dir)
    print(_summarize(candidates))
    print(f"Wrote {len(written)} candidate YAMLs to {args.out_dir.relative_to(REPO_ROOT)}/")


if __name__ == "__main__":
    main()
