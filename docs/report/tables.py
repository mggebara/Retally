"""Regenerate every numeric table in ``docs/report/draft.md`` from committed files.

Run from the repository root::

    uv run python docs/report/tables.py

It reads only committed inputs -- the results files under
``benchmark/results/``, the catalog YAMLs under ``benchmark/papers/``,
``benchmark/corpus/candidates-2026-10-21.json``,
``candidates-2026-11-01.json`` and ``candidates-2026-11-02.json``, and
``ROADMAP.md`` (for the discrepancy check) -- and writes one Markdown file per
table to ``docs/report/tables/``.
It then copies each table into ``draft.md`` between its
``<!-- table:NAME -->`` and ``<!-- /table:NAME -->`` markers, so
the tables in the draft are always the generated ones.  Scoring is never recomputed here: pass counts,
first-scored counts and verdicts are read from the rows the harness wrote,
and closeness, labelling and mode handling come from ``benchmark.metrics``.

The only hand-written content is the failure-taxonomy classification
(``TAXONOMY_RULES``), which records a judgement per non-matching claim and
cites the ROADMAP section it rests on, and the original-software column for
the papers the corpus shortlists do not cover or describe in prose
(``ORIGINAL_SOFTWARE``).
"""

from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO))

from benchmark import metrics
from benchmark.schema import load_catalog

RESULTS = REPO / "benchmark" / "results"
OUT = Path(__file__).resolve().parent / "tables"

# ---------------------------------------------------------------------------
# Inputs
# ---------------------------------------------------------------------------

PIPELINE_47_FILE = "pipeline-10papers-all-modes-2026-10-21.json"
PIPELINE_55_API_FILE = "pipeline-opus55-4papers-all-modes-2026-10-22.json"
PIPELINE_ORACLE_FILE = "pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json"
# The four papers curated on 2026-11-01 (ROADMAP 3.6): the pipeline through the
# oracle (label ``desktop-opus``, first sample) and the agent (run ``2026-11-02-a``).
PIPELINE_ORACLE_NEW_FILE = "pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json"
AGENT_NEW_FILE = "claude-code-4papers-all-modes-2026-11-02.json"
# The six papers curated on 2026-11-02 (ROADMAP 3.7), first sample of each system:
# the pipeline through the oracle (label ``desktop-opus``) and the agent (run ``2026-11-02-a``).
PIPELINE_ORACLE_SIX_FILE = "pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json"
AGENT_SIX_FILE = "claude-code-6papers-all-modes-2026-11-02.json"
AGENT_FILES = [
    "claude-code-7papers-all-modes-2026-10-21.json",
    "claude-code-6papers-all-modes-2026-10-22.json",
    AGENT_NEW_FILE,
    AGENT_SIX_FILE,
]
AGENT_RERUN_FILES = ["claude-code-blind-rerun-2026-10-22.json", "claude-code-blind-rerun-2026-10-22-b.json"]
# Second complete pipeline sample, through the oracle (label ``desktop-opus-run2``):
# all 13 papers of ROADMAP 3.2-3.5 ("Variance pass"), the four papers of 3.6
# (ROADMAP 3.7) and the six of 3.7 (ROADMAP 3.7.1), so the pipeline has two
# samples on all 23.  Kept out of ``RAW`` so that every single-sample table is
# unchanged; it feeds only the ``variance_pipeline`` tables and the probe comparison.
PIPELINE_RUN2_FILE = "pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json"
PIPELINE_RUN2_NEW_FILE = "pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json"
PIPELINE_RUN2_SIX_FILE = "pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json"
RUN2_LABEL = "desktop-opus-run2"
# Second Claude Code sample in independent and blind mode: the 13 papers of
# ROADMAP 3.5 ("Agent second sample"; run id ``2026-11-01-a``) and the four of
# 3.6 (ROADMAP 3.7; run id ``2026-11-02-b``).  Kept out of ``RAW`` for the same
# reason; it feeds only the ``variance_agent`` tables and the probe comparison.
# Seeded was not rerun.
AGENT_RUN2_FILE = "claude-code-run2-13papers-indep-blind-2026-11-01.json"
AGENT_RUN2_NEW_FILE = "claude-code-run2-4papers-indep-blind-2026-11-02.json"
# ... and the six of 3.7 (run id ``2026-11-02-b``), so the agent has two samples on all 23.
AGENT_RUN2_SIX_FILE = "claude-code-run2-6papers-indep-blind-2026-11-02.json"
AGENT_RUN2_MODES = ("independent", "blind")
# Memorisation probe (ROADMAP 3.5, "Memorisation probe"; ``benchmark/probe.py``),
# re-scored over all 23 evaluation papers (ROADMAP 3.6, 3.7).  Its rows for the
# earlier papers are identical to the earlier files'.
PROBE_FILE = "probe-desktop-opus-2026-11-02.json"
# Probe hits the answering agent said it back-computed from the p-value and
# degrees of freedom the claim context stated (ROADMAP 3.5, "Memorisation
# probe"): derivable from the prompt, not recalled.
PROBE_DERIVABLE = {
    "brown_forsythe_donations_per_hour",
    "anova_f_donations_per_hour",
    "anova_f_dollars_per_hour",
}

# Pipeline 4.7 variance on the dev papers (ROADMAP 1.8 and Phase 3): one
# cache-on independent row plus three cache-off runs, at the pipeline state
# REPORT.md uses for each paper.
DEV_VARIANCE = {
    "dincecco-2022-india-warfare": (
        ("phase18-dincecco-both-2026-10-20.json", "cache on"),
        ("phase18-dincecco-variance-independent-run1-2026-10-20.json", "cache off, run 1"),
        ("phase18-dincecco-variance-independent-run2-2026-10-20.json", "cache off, run 2"),
        ("phase18-dincecco-variance-independent-run3-2026-10-20.json", "cache off, run 3"),
    ),
    "alesina-2022-immigration-redistribution": (
        ("phase3-alesina-both-2026-10-20.json", "cache on"),
        ("phase3-alesina-variance-independent-run1-2026-10-20.json", "cache off, run 1"),
        ("phase3-alesina-variance-independent-run2-2026-10-20.json", "cache off, run 2"),
        ("phase3-alesina-variance-independent-run3-2026-10-20.json", "cache off, run 3"),
    ),
    "bisbee-2022-flight-to-safety": (
        ("phase19-bisbee-independent-2026-10-20.json", "cache on"),
        ("phase19-bisbee-variance-independent-run1-2026-10-20.json", "cache off, run 1"),
        ("phase19-bisbee-variance-independent-run2-2026-10-20.json", "cache off, run 2"),
        ("phase19-bisbee-variance-independent-run3-2026-10-20.json", "cache off, run 3"),
    ),
}

MODES = ("seeded", "independent", "blind")

# Report labels for the four reproducer labels ``metrics.disambiguate_reproducers`` produces.
AGENT = "claude-code"
P47 = "pipeline (claude-opus-4-7)"
P55 = "pipeline (claude-opus-5-5)"
ORC = "pipeline (desktop-opus)"
P55_ALL = "pipeline on Opus 5.5 (API + oracle)"
DISPLAY = {
    AGENT: "Agent (Claude Code, desktop Opus)",
    P47: "Pipeline, `claude-opus-4-7`",
    P55: "Pipeline, `claude-opus-5-5` (API)",
    ORC: "Pipeline, desktop Opus (oracle)",
    P55_ALL: "Pipeline on Opus 5.5 (API for 4 papers, oracle for the rest)",
}

# Original software of the four papers outside the 2026-10-21 shortlist
# (the other twelve come from candidates-2026-10-21.json).  Sources: the
# entries' header comments (Alesina: "primarily Stata (.do)"; Bisbee:
# "Original analysis code is R"; Dincecco: "replication package in Stata")
# and ROADMAP 3.2 (Arias: "R, reproducible").
ORIGINAL_SOFTWARE = {
    "alesina-2022-immigration-redistribution": "Stata",
    "bisbee-2022-flight-to-safety": "R",
    "dincecco-2022-india-warfare": "Stata",
    "arias-2022-changing-tides-climate-migration": "R",
    "frederiksen-2022-competence-undemocratic": "—",
    "marcus-2022-sports-club-vouchers": "—",
    # candidates-2026-11-01.json describes Bokobza's mix in prose; Brouwer was a
    # 2026-10-21 reserve (entry header: "Small Stata package").
    "bokobza-2022-morning-after-coup-purges": "Stata + R",
    "brouwer-2022-teaching-norms": "Stata",
    # candidates-2026-11-02.json lists Douenne as "Python + R (original)"; the entry
    # header calls it an R original, with Python 2 only for the tax microsimulation.
    "douenne-2022-yellow-vests-carbon-tax": "R (+ Python)",
}

JOURNALS = {
    "American Political Science Review": "APSR",
    "American Journal of Political Science": "AJPS",
    "The Journal of Politics": "JOP",
    "Journal of Political Economy": "JPE",
    "Quarterly Journal of Economics": "QJE",
    "The Review of Economic Studies": "REStud",
    "Review of Economic Studies": "REStud",
    "The Economic Journal": "EJ",
    "Economic Journal": "EJ",
    "American Economic Journal: Economic Policy": "AEJ: Policy",
}


def load_rows(name: str) -> list[dict[str, Any]]:
    return metrics.result_rows(json.loads((RESULTS / name).read_text()))


def short(entry_id: str) -> str:
    """``grier-2023-sugar-roll-call-voting`` -> ``grier-2023``."""
    m = re.match(r"(.+?-\d{4})", entry_id)
    return m.group(1) if m else entry_id


def passed(row: dict[str, Any]) -> int:
    return sum(1 for cd in row.get("claim_details", []) if cd.get("passed"))


def total(row: dict[str, Any]) -> int:
    return len(row.get("claim_details", []))


def fs(row: dict[str, Any]) -> int | None:
    return metrics.first_scored_passed(row)


def refs(row: dict[str, Any]) -> tuple[int, int]:
    return int(row.get("n_error_refinements") or 0), int(row.get("n_claim_refinements") or 0)


def usd(row: dict[str, Any]) -> float:
    return float((row.get("usage") or {}).get("estimated_usd") or 0.0)


def calls(row: dict[str, Any]) -> int:
    return int((row.get("usage") or {}).get("api_calls") or 0)


def table(header: list[str], rows: list[list[Any]], align: list[str] | None = None) -> str:
    align = align or ["l"] + ["r"] * (len(header) - 1)
    rule = ["---:" if a == "r" else "---" for a in align]
    lines = ["| " + " | ".join(header) + " |", "|" + "|".join(rule) + "|"]
    lines += ["| " + " | ".join(str(c) for c in r) + " |" for r in rows]
    return "\n".join(lines) + "\n"


def pct(v: float | None, digits: int = 1) -> str:
    return "—" if v is None else f"{v * 100:.{digits}f} %"


# ---------------------------------------------------------------------------
# Data
# ---------------------------------------------------------------------------

CATALOG = {e.id: e for e in load_catalog(REPO / "benchmark" / "papers")}
CANDIDATES = {
    p["id"]: p
    for name in ("candidates-2026-10-21.json", "candidates-2026-11-01.json", "candidates-2026-11-02.json")
    for p in json.loads((REPO / "benchmark" / "corpus" / name).read_text())["papers"]
}

RAW = (
    load_rows(PIPELINE_47_FILE)
    + load_rows(PIPELINE_55_API_FILE)
    + load_rows(PIPELINE_ORACLE_FILE)
    + load_rows(PIPELINE_ORACLE_NEW_FILE)
    + load_rows(PIPELINE_ORACLE_SIX_FILE)
    + [r for f in AGENT_FILES for r in load_rows(f)]
)
ROWS = [r for r in metrics.disambiguate_reproducers(RAW) if not r.get("skipped")]
CELL: dict[tuple[str, str, str], dict[str, Any]] = {}
for _r in ROWS:
    _key = (metrics.reproducer_of(_r), _r["entry_id"], metrics.mode_of(_r))
    assert _key not in CELL, f"duplicate cell {_key}"
    CELL[_key] = _r

HOLDOUT = sorted(e.id for e in CATALOG.values() if e.split == "holdout" and not e.out_of_scope_reason)
DEV = sorted(e.id for e in CATALOG.values() if e.split == "dev" and not e.out_of_scope_reason)
SEVEN = sorted({e for (rep, e, _m) in CELL if rep == P47 and e in HOLDOUT})
API_FOUR = sorted({e for (rep, e, _m) in CELL if rep == P55})
# Both oracle files carry the label ``desktop-opus``; the paper sets come from the files.
ORACLE_NINE = sorted({r["entry_id"] for r in load_rows(PIPELINE_ORACLE_FILE)})
NEW_FOUR = sorted({r["entry_id"] for r in load_rows(PIPELINE_ORACLE_NEW_FILE)})
assert sorted({r["entry_id"] for r in load_rows(AGENT_NEW_FILE)}) == NEW_FOUR
NEW_SIX = sorted({r["entry_id"] for r in load_rows(PIPELINE_ORACLE_SIX_FILE)})
assert sorted({r["entry_id"] for r in load_rows(AGENT_SIX_FILE)}) == NEW_SIX
ORACLE_THREE = sorted(set(SEVEN) - set(API_FOUR))
# The 13 evaluation papers of ROADMAP 3.2-3.5.
THIRTEEN = sorted(set(API_FOUR) | set(ORACLE_NINE))
SIX_NEW = sorted(set(THIRTEEN) - set(SEVEN))
# The 17 papers of ROADMAP 3.2-3.6, which have second samples of both systems (ROADMAP 3.5, 3.7).
SEVENTEEN = sorted(set(THIRTEEN) | set(NEW_FOUR))
assert not set(API_FOUR) & set(ORACLE_NINE) and not set(THIRTEEN) & set(NEW_FOUR)
assert not set(SEVENTEEN) & set(NEW_SIX)
assert set(SEVENTEEN) | set(NEW_SIX) == set(HOLDOUT) and len(HOLDOUT) == 23


RUN2: dict[tuple[str, str], dict[str, Any]] = {}
for _r in (
    load_rows(PIPELINE_RUN2_FILE) + load_rows(PIPELINE_RUN2_NEW_FILE) + load_rows(PIPELINE_RUN2_SIX_FILE)
):
    assert metrics.reproducer_of(_r) == "pipeline" and metrics.model_of(_r) == RUN2_LABEL, _r["entry_id"]
    assert not _r.get("skipped"), _r["entry_id"]
    _key = (_r["entry_id"], metrics.mode_of(_r))
    assert _key not in RUN2, f"duplicate run2 cell {_key}"
    RUN2[_key] = _r
assert {e for e, _m in RUN2} == set(HOLDOUT) and len(RUN2) == len(HOLDOUT) * len(MODES)

AGENT2: dict[tuple[str, str], dict[str, Any]] = {}
for _r in load_rows(AGENT_RUN2_FILE) + load_rows(AGENT_RUN2_NEW_FILE) + load_rows(AGENT_RUN2_SIX_FILE):
    assert metrics.reproducer_of(_r) == AGENT and not _r.get("skipped"), _r["entry_id"]
    _key = (_r["entry_id"], metrics.mode_of(_r))
    assert _key[1] in AGENT_RUN2_MODES and _key not in AGENT2, f"unexpected agent run2 cell {_key}"
    AGENT2[_key] = _r
assert {e for e, _m in AGENT2} == set(HOLDOUT) and len(AGENT2) == len(HOLDOUT) * len(AGENT_RUN2_MODES)

PROBE_ROWS = sorted(load_rows(PROBE_FILE), key=lambda r: r["entry_id"])
assert {r["entry_id"] for r in PROBE_ROWS} == set(HOLDOUT) and len(PROBE_ROWS) == len(HOLDOUT)
PROBE_ROWS_13 = [r for r in PROBE_ROWS if r["entry_id"] in THIRTEEN]
PROBE_ROWS_17 = [r for r in PROBE_ROWS if r["entry_id"] in SEVENTEEN]


def p55_cell(entry: str, mode: str) -> dict[str, Any] | None:
    """The model-matched pipeline row: the API run where it exists, else the oracle run."""
    return CELL.get((P55, entry, mode)) or CELL.get((ORC, entry, mode))


def cell(rep: str, entry: str, mode: str) -> dict[str, Any] | None:
    if rep == P55_ALL:
        return p55_cell(entry, mode)
    return CELL.get((rep, entry, mode))


def rows_for(rep: str, entries: list[str], mode: str) -> list[dict[str, Any]]:
    out = [cell(rep, e, mode) for e in entries]
    return [r for r in out if r is not None]


def sum_passed(rep: str, entries: list[str], mode: str) -> tuple[int, int, int | None]:
    rs = rows_for(rep, entries, mode)
    fss = [fs(r) for r in rs]
    return (
        sum(passed(r) for r in rs),
        sum(total(r) for r in rs),
        None if any(v is None for v in fss) else sum(v for v in fss if v is not None),
    )


def frac(rep: str, entries: list[str], mode: str, with_fs: bool = True) -> str:
    p, n, f = sum_passed(rep, entries, mode)
    if n == 0:
        return "—"
    return f"{p} / {n}" + (f" ({f})" if with_fs and f is not None else "")


# ---------------------------------------------------------------------------
# Tables
# ---------------------------------------------------------------------------


def t_catalog() -> str:
    hdr = [
        "Entry",
        "Journal",
        "Year",
        "Split",
        "Original software",
        "Pinned claims",
        "with SE",
        "I4R outcome label",
        "I4R values",
        "Publication date",
        "Package release",
    ]
    out = []
    for eid in sorted(CATALOG):
        e = CATALOG[eid]
        cand = CANDIDATES.get(eid)
        header = (REPO / "benchmark" / "papers" / f"{eid}.yaml").read_text().split("\nid:")[0]
        flat = " ".join(line.lstrip("#").strip() for line in header.splitlines()[:8])
        journal = next((JOURNALS[n] for n in sorted(JOURNALS, key=len, reverse=True) if n in flat), "—")
        year_m = re.search(r"\((\d{4})\)", flat)
        year = year_m.group(1) if year_m else "—"
        software = ORIGINAL_SOFTWARE.get(eid) or (cand["software"] if cand else "—")
        software = software.split(" (")[0].replace(" + R calibration", " (+ R)")
        n_se = sum(1 for c in e.original_claims if c.standard_error is not None)
        n_i4r = sum(1 for f in e.i4r_replicator_findings if f.reproduced_value is not None)
        split = "out of scope" if e.out_of_scope_reason else ("evaluation" if e.split == "holdout" else "dev")
        out.append(
            [
                f"`{short(eid)}`",
                journal,
                year,
                split,
                software,
                len(e.original_claims),
                n_se,
                e.outcome_label.value,
                n_i4r,
                e.publication_date or "—",
                e.package_release_date or "—",
            ]
        )
    in_scope = [e for e in CATALOG.values() if not e.out_of_scope_reason]
    ev = [e for e in in_scope if e.split == "holdout"]
    dv = [e for e in in_scope if e.split == "dev"]
    n_i4r_total = sum(
        1 for e in in_scope for f in e.i4r_replicator_findings if f.reproduced_value is not None
    )
    summary = (
        f"Catalog entries: {len(CATALOG)}; in scope: {len(in_scope)} "
        f"({len(dv)} dev, {len(ev)} evaluation).  Pinned claims: "
        f"{sum(len(e.original_claims) for e in ev)} on the evaluation papers, "
        f"{sum(len(e.original_claims) for e in dv)} on the dev papers.  "
        f"Claims with a pinned standard error: "
        f"{sum(1 for e in in_scope for c in e.original_claims if c.standard_error is not None)} of "
        f"{sum(len(e.original_claims) for e in in_scope)}.  "
        f"Claims with an I4R replicator value: {n_i4r_total}.\n\n"
    )
    oos = "".join(
        f"- `{short(e.id)}` is out of scope: {e.out_of_scope_reason}.\n"
        for e in sorted(CATALOG.values(), key=lambda x: x.id)
        if e.out_of_scope_reason
    )
    return summary + table(hdr, out, ["l", "l", "r", "l", "l", "r", "r", "l", "r", "l", "l"]) + "\n" + oos


def t_headline() -> str:
    hdr = ["Reproducer", "Papers", "Seeded", "Independent", "Blind"]
    out = []
    groups = [
        (P47, SEVEN, "7 evaluation (3.2)"),
        (P55, API_FOUR, "4 evaluation (3.5, API)"),
        (ORC, ORACLE_NINE, "9 evaluation (3.5, oracle)"),
        (ORC, NEW_FOUR, "4 evaluation (3.6, oracle)"),
        (ORC, NEW_SIX, "6 evaluation (3.7, oracle)"),
        (P55_ALL, THIRTEEN, "13 earlier evaluation (3.2–3.5)"),
        (P55_ALL, SEVENTEEN, "17 evaluation (3.2–3.6)"),
        (P55_ALL, HOLDOUT, "all 23 evaluation"),
        (AGENT, SEVEN, "7 evaluation (3.3)"),
        (AGENT, SIX_NEW, "6 evaluation (3.4)"),
        (AGENT, NEW_FOUR, "4 evaluation (3.6)"),
        (AGENT, NEW_SIX, "6 evaluation (3.7)"),
        (AGENT, THIRTEEN, "13 earlier evaluation (3.3–3.4)"),
        (AGENT, SEVENTEEN, "17 evaluation (3.3–3.6)"),
        (AGENT, HOLDOUT, "all 23 evaluation"),
        (P47, DEV, "3 dev"),
    ]
    for rep, entries, label in groups:
        out.append([DISPLAY[rep], label] + [frac(rep, entries, m) for m in MODES])
    return (
        "Claims within tolerance of the paper's printed value, summed over papers; first-scored "
        "count in parentheses.  One run per cell (the first sample of each system).  Rows marked 13 "
        "cover the evaluation papers of ROADMAP 3.2–3.5; rows marked 17 add the four papers of "
        "ROADMAP 3.6; rows marked 23 add the six papers of ROADMAP 3.7.\n\n"
        + table(hdr, out, ["l", "l", "r", "r", "r"])
    )


def t_confound() -> str:
    hdr = ["Papers", "Mode", "Pipeline 4.7", "Pipeline on Opus 5.5", "Agent"]
    out = []
    for label, entries in [
        ("7 papers (3.2 set)", SEVEN),
        ("API route: " + ", ".join(short(e) for e in API_FOUR), API_FOUR),
        ("oracle route: " + ", ".join(short(e) for e in ORACLE_THREE), ORACLE_THREE),
    ]:
        for m in MODES:
            out.append([label, m, frac(P47, entries, m), frac(P55_ALL, entries, m), frac(AGENT, entries, m)])
    return (
        'Same papers, same modes, three ways.  "Pipeline on Opus 5.5" is the API run '
        "(`claude-opus-5-5`) for the API-route papers and the oracle run (desktop Opus) for the "
        "oracle-route papers.  First scored in parentheses.\n\n" + table(hdr, out, ["l", "l", "r", "r", "r"])
    )


def _cell_note(row: dict[str, Any] | None, refinements: bool = True) -> str:
    if row is None:
        return "—"
    s = f"{passed(row)}"
    parts = []
    if fs(row) is not None:
        parts.append(str(fs(row)))
    if refinements:
        e, c = refs(row)
        parts.append(f"{e}/{c}")
    return s + (f" ({'; '.join(parts)})" if parts else "")


def t_seven_per_paper() -> str:
    hdr = ["Paper", "Route", "Mode", "n", "Pipeline 4.7", "Pipeline on Opus 5.5", "Agent"]
    out = []
    for e in sorted(SEVEN, key=lambda x: (x not in API_FOUR, x)):
        route = "API" if e in API_FOUR else "oracle"
        for m in MODES:
            r47 = cell(P47, e, m)
            out.append(
                [
                    f"`{short(e)}`",
                    route,
                    m,
                    total(r47) if r47 else "—",
                    _cell_note(r47),
                    _cell_note(cell(P55_ALL, e, m)),
                    _cell_note(cell(AGENT, e, m)),
                ]
            )
    return (
        "Final count (first scored; error / claim refinements).  The agent's refinement counts are "
        "its own bookkeeping (ROADMAP 3.3).\n\n" + table(hdr, out, ["l", "l", "l", "r", "r", "r", "r"])
    )


def t_nine_oracle() -> str:
    hdr = ["Paper", "Mode", "n", "Pipeline 4.7", "Pipeline, oracle", "Agent"]
    out = []
    for e in ORACLE_NINE:
        for m in MODES:
            ro = cell(ORC, e, m)
            out.append(
                [
                    f"`{short(e)}`",
                    m,
                    total(ro) if ro else "—",
                    _cell_note(cell(P47, e, m)),
                    _cell_note(ro),
                    _cell_note(cell(AGENT, e, m)),
                ]
            )
    for m in MODES:
        out.append(
            [
                "**Total, 9 papers**",
                m,
                sum_passed(ORC, ORACLE_NINE, m)[1],
                "—",
                f"**{frac(ORC, ORACLE_NINE, m)}**",
                f"**{frac(AGENT, ORACLE_NINE, m)}**",
            ]
        )
    return (
        "Final count (first scored; error / claim refinements); totals show final (first scored).  "
        "Pipeline 4.7 rows exist only for the three 3.2 papers.\n\n"
        + table(hdr, out, ["l", "l", "r", "r", "r", "r"])
    )


def t_four_new() -> str:
    hdr = ["Paper", "Mode", "n", "Pipeline, oracle", "Agent"]
    out = []
    for e in NEW_FOUR:
        for m in MODES:
            ro = cell(ORC, e, m)
            out.append(
                [f"`{short(e)}`", m, total(ro) if ro else "—", _cell_note(ro), _cell_note(cell(AGENT, e, m))]
            )
    for m in MODES:
        out.append(
            [
                "**Total, 4 papers**",
                m,
                sum_passed(ORC, NEW_FOUR, m)[1],
                f"**{frac(ORC, NEW_FOUR, m)}**",
                f"**{frac(AGENT, NEW_FOUR, m)}**",
            ]
        )
    return (
        "The four papers added on 2026-11-02 (ROADMAP 3.6): the pipeline through the oracle "
        f"(`{PIPELINE_ORACLE_NEW_FILE}`) and the agent (`{AGENT_NEW_FILE}`), first sample of each.  "
        "Final count (first scored; error / claim refinements); totals show final (first scored).\n\n"
        + table(hdr, out, ["l", "l", "r", "r", "r"])
    )


def t_six_new() -> str:
    hdr = ["Paper", "Mode", "n", "Pipeline, oracle", "Agent"]
    out = []
    for e in NEW_SIX:
        for m in MODES:
            ro = cell(ORC, e, m)
            out.append(
                [f"`{short(e)}`", m, total(ro) if ro else "—", _cell_note(ro), _cell_note(cell(AGENT, e, m))]
            )
    for m in MODES:
        out.append(
            [
                "**Total, 6 papers**",
                m,
                sum_passed(ORC, NEW_SIX, m)[1],
                f"**{frac(ORC, NEW_SIX, m)}**",
                f"**{frac(AGENT, NEW_SIX, m)}**",
            ]
        )
    return (
        "The six papers curated on 2026-11-02 (ROADMAP 3.7): the pipeline through the oracle "
        f"(`{PIPELINE_ORACLE_SIX_FILE}`) and the agent (`{AGENT_SIX_FILE}`), first sample of each.  "
        "Final count (first scored; error / claim refinements); totals show final (first scored).\n\n"
        + table(hdr, out, ["l", "l", "r", "r", "r"])
    )


def t_gap() -> str:
    hdr = [
        "Papers",
        "Mode",
        "Claims",
        "Agent − pipeline 4.7",
        "Model effect (5.5 − 4.7)",
        "Harness effect (agent − 5.5)",
    ]
    out = []
    for label, entries in [
        ("7 papers (3.2 set)", SEVEN),
        ("API route (4)", API_FOUR),
        ("oracle route (3)", ORACLE_THREE),
    ]:
        for m in MODES:
            a, n, _ = sum_passed(AGENT, entries, m)
            p47, _, _ = sum_passed(P47, entries, m)
            p55, _, _ = sum_passed(P55_ALL, entries, m)
            out.append([label, m, n, f"{a - p47:+d}", f"{p55 - p47:+d}", f"{a - p55:+d}"])
    for label, entries in [
        ("6 papers (3.4 set)", SIX_NEW),
        ("4 papers (3.6 set)", NEW_FOUR),
        ("6 papers (3.7 set)", NEW_SIX),
        ("13 earlier", THIRTEEN),
        ("17 (3.2–3.6)", SEVENTEEN),
        ("all 23", HOLDOUT),
    ]:
        for m in MODES:
            a, n, _ = sum_passed(AGENT, entries, m)
            p55, _, _ = sum_passed(P55_ALL, entries, m)
            out.append([label, m, n, "—", "—", f"{a - p55:+d}"])
    return (
        "Differences in claims within tolerance, summed over papers.  On the 3.2 set the total "
        "agent-over-pipeline-4.7 difference splits exactly into a model effect (pipeline on Opus 5.5 "
        "minus pipeline on 4.7) and a harness effect (agent minus pipeline on Opus 5.5).  The 3.4, "
        "3.6 and 3.7 papers have no 4.7 rows, so only the harness effect exists there.  One run per cell; no "
        "uncertainty is attached to any difference.\n\n" + table(hdr, out, ["l", "l", "r", "r", "r", "r"])
    )


def t_refinement() -> str:
    hdr = [
        "Reproducer",
        "Papers",
        "Mode",
        "Final",
        "First scored",
        "First attempt",
        "Final − first scored",
        "Error refinements",
        "Claim refinements",
        "Cells with a claim refinement",
    ]
    out = []
    for rep, entries, label in [
        (P47, SEVEN, "7"),
        (P55, API_FOUR, "4"),
        (ORC, ORACLE_NINE, "9"),
        (ORC, NEW_FOUR, "4 (3.6)"),
        (ORC, NEW_SIX, "6 (3.7)"),
        (AGENT, THIRTEEN, "13"),
        (AGENT, NEW_FOUR, "4 (3.6)"),
        (AGENT, NEW_SIX, "6 (3.7)"),
    ]:
        for m in MODES:
            rs = rows_for(rep, entries, m)
            fin = sum(passed(r) for r in rs)
            f = sum(fs(r) or 0 for r in rs)
            fa = sum(metrics.first_attempt_passed(r) or 0 for r in rs)
            e = sum(refs(r)[0] for r in rs)
            c = sum(refs(r)[1] for r in rs)
            nc = sum(1 for r in rs if refs(r)[1] > 0)
            out.append(
                [
                    DISPLAY[rep],
                    label,
                    m,
                    f"{fin} / {sum(total(r) for r in rs)}",
                    f,
                    "n/a" if rep == AGENT else fa,
                    f"{fin - f:+d}",
                    e,
                    c,
                    f"{nc} / {len(rs)}",
                ]
            )
    return (
        "*First attempt* is the very first execution, crash or not; *first scored* is the first "
        "execution that printed a parsable `RESULT:` line (after crash repairs, before any "
        "claim-targeted feedback).  The agent's first execution is usually a data-inspection run, so "
        "its first-attempt count is not reported.  Blind mode runs no claim refinements by "
        "construction.\n\n" + table(hdr, out, ["l", "r", "l", "r", "r", "r", "r", "r", "r", "r"])
    )


def t_closeness() -> str:
    hdr = [
        "Reproducer",
        "Papers",
        "Mode",
        "Claims",
        "Matched",
        "Median rel. error",
        "≤1× tol",
        "≤2× tol",
        "≤5× tol",
    ]
    out = []
    for rep, entries, label in [
        (P47, SEVEN, "7 (3.2 set)"),
        (P55_ALL, SEVEN, "7 (3.2 set)"),
        (AGENT, SEVEN, "7 (3.2 set)"),
        (P55_ALL, THIRTEEN, "13"),
        (AGENT, THIRTEEN, "13"),
        (P55_ALL, SEVENTEEN, "17"),
        (AGENT, SEVENTEEN, "17"),
        (P55_ALL, HOLDOUT, "23"),
        (AGENT, HOLDOUT, "23"),
    ]:
        for m in MODES:
            c = metrics.closeness(rows_for(rep, entries, m))
            out.append(
                [
                    DISPLAY[rep],
                    label,
                    m,
                    c.n_claims,
                    pct(c.match_rate, 0),
                    pct(c.median_rel_err),
                    pct(c.frac_within_tol, 0),
                    pct(c.frac_within_2x_tol, 0),
                    pct(c.frac_within_5x_tol, 0),
                ]
            )
    return (
        "From `benchmark.metrics.closeness`.  Relative error and the tolerance multiples are over "
        "*matched* claims (a value was reported); each claim's own effective tolerance is used, so "
        "seeded (1–2 % relative) and independent / blind (±1 SE) bands differ.\n\n"
        + table(hdr, out, ["l", "r", "l", "r", "r", "r", "r", "r", "r"])
    )


def _verdict(row: dict[str, Any] | None) -> str:
    if row is None:
        return "—"
    p = "✓" if row.get("agrees_with_paper") else "✗"
    i = row.get("agrees_with_i4r")
    i_s = "n/a" if i is None else ("✓" if i else "✗")
    return f"{p} / {i_s} ({passed(row)}/{total(row)}; {row.get('n_claims_with_i4r_match', 0)})"


def t_three_way() -> str:
    hdr = [
        "Reproducer",
        "Set",
        "Mode",
        "Papers",
        "paper ✓ I4R ✓",
        "paper ✓ I4R ✗",
        "paper ✗ I4R ✓",
        "paper ✗ I4R ✗",
        "I4R n/a",
    ]
    out = []
    for rep, entries, label in [
        (P47, SEVEN, "7"),
        (P55_ALL, THIRTEEN, "13"),
        (P55_ALL, SEVENTEEN, "17"),
        (P55_ALL, HOLDOUT, "23"),
        (AGENT, THIRTEEN, "13"),
        (AGENT, SEVENTEEN, "17"),
        (AGENT, HOLDOUT, "23"),
    ]:
        for m in MODES:
            rs = rows_for(rep, entries, m)
            k = Counter((bool(r.get("agrees_with_paper")), r.get("agrees_with_i4r")) for r in rs)
            out.append(
                [
                    DISPLAY[rep],
                    label,
                    m,
                    len(rs),
                    k[(True, True)],
                    k[(True, False)],
                    k[(False, True)],
                    k[(False, False)],
                    k[(True, None)] + k[(False, None)],
                ]
            )
    summary = table(hdr, out, ["l", "r", "l", "r", "r", "r", "r", "r", "r"])
    per_paper_hdr = ["Paper", "I4R label", "I4R values", "Reproducer", "Seeded", "Independent", "Blind"]
    pp = []
    for e in HOLDOUT:
        ent = CATALOG[e]
        n_i4r = sum(1 for f in ent.i4r_replicator_findings if f.reproduced_value is not None)
        for rep in (P47, P55_ALL, AGENT):
            if cell(rep, e, "seeded") is None:
                continue
            pp.append(
                [
                    f"`{short(e)}`",
                    ent.outcome_label.value,
                    n_i4r,
                    DISPLAY[rep],
                    *(_verdict(cell(rep, e, m)) for m in MODES),
                ]
            )
    return (
        "Paper-level verdicts.  `agrees_with_paper`: every pinned claim within tolerance of the "
        "paper's printed value.  `agrees_with_i4r`: every claim with an I4R replicator value within "
        "tolerance of *that* value; n/a when the entry has no I4R value.\n\n"
        + summary
        + "\n\nPer paper: `paper / I4R` verdicts (claims matching the paper / total; claims matching "
        "the I4R value).\n\n" + table(per_paper_hdr, pp, ["l", "l", "r", "l", "l", "l", "l"])
    )


def t_variance() -> str:
    out = []
    for e, files in DEV_VARIANCE.items():
        vals = []
        for f, _label in files:
            rows = [r for r in load_rows(f) if r["entry_id"] == e and metrics.mode_of(r) == "independent"]
            assert len(rows) == 1, (f, e)
            vals.append(f"{passed(rows[0])}")
        out.append([f"`{short(e)}`", total(rows[0]), *vals])
    t1 = table(
        [
            "Dev paper (independent, pipeline 4.7)",
            "n",
            "Cache on",
            "Cache off 1",
            "Cache off 2",
            "Cache off 3",
        ],
        out,
    )
    rr = []
    for f in AGENT_RERUN_FILES:
        for r in load_rows(f):
            e = r["entry_id"]
            first = cell(AGENT, e, "blind")
            rr.append([f"`{short(e)}`", total(r), passed(first) if first else "—", passed(r), f"`{f}`"])
    t2 = table(
        ["Agent, blind", "n", "First run", "Second run", "Second-run file"], rr, ["l", "r", "r", "r", "l"]
    )
    return (
        "Earlier repeat runs: the pipeline on `claude-opus-4-7` on the three dev papers (independent "
        "mode), and the agent's blind reruns of ROADMAP 3.4.\n\n"
        + t1
        + "\nAgent blind reruns (ROADMAP 3.4):\n\n"
        + t2
    )


def _variance_cells(mode: str, entries: list[str] | None = None) -> list[tuple[str, int, int, int, int]]:
    """(entry, n, sample 1, sample 2, agent) for one mode over ``entries`` (default: 13 earlier)."""
    out = []
    for e in THIRTEEN if entries is None else entries:
        s1, s2, a = p55_cell(e, mode), RUN2[(e, mode)], cell(AGENT, e, mode)
        assert s1 is not None and a is not None and total(s1) == total(s2) == total(a), (e, mode)
        out.append((e, total(s1), passed(s1), passed(s2), passed(a)))
    return out


def _variance_stats(
    cells: list[tuple[str, int, int, int, int]],
) -> tuple[int, int, int, int, int, float, int]:
    """(n, sample 1, sample 2, agent, cells identical, sum of abs. diffs, max abs. diff)."""
    diffs = [abs(s1 - s2) for _e, _n, s1, s2, _a in cells]
    return (
        sum(c[1] for c in cells),
        sum(c[2] for c in cells),
        sum(c[3] for c in cells),
        sum(c[4] for c in cells),
        sum(1 for d in diffs if d == 0),
        float(sum(diffs)),
        max(diffs),
    )


def t_variance_pipeline() -> str:
    hdr = [
        "Papers",
        "Mode",
        "Claims",
        "Sample 1",
        "Sample 2",
        "Agent (sample 1)",
        "Agent − sample 1",
        "Agent − sample 2",
        "Cells identical",
        "Mean abs. diff per cell",
        "Max abs. diff",
    ]
    out = []
    for label, entries in (
        ("13 earlier", THIRTEEN),
        ("4 (3.6 set)", NEW_FOUR),
        ("17", SEVENTEEN),
        ("6 (3.7 set)", NEW_SIX),
        ("23", HOLDOUT),
    ):
        every: list[tuple[str, int, int, int, int]] = []
        for m in MODES:
            cells = _variance_cells(m, entries)
            every += cells
            n, s1, s2, a, same, sad, mx = _variance_stats(cells)
            out.append(
                [
                    label,
                    m,
                    n,
                    s1,
                    s2,
                    a,
                    f"{a - s1:+d}",
                    f"{a - s2:+d}",
                    f"{same} / {len(cells)}",
                    f"{sad / len(cells):.2f}",
                    mx,
                ]
            )
        n, s1, s2, a, same, sad, mx = _variance_stats(every)
        out.append(
            [
                label,
                "**all modes**",
                n,
                s1,
                s2,
                a,
                "—",
                "—",
                f"**{same} / {len(every)}**",
                f"**{sad / len(every):.2f}**",
                f"**{mx}**",
            ]
        )
    return (
        "Two samples of the pipeline on Opus 5.5 over all 23 evaluation papers (claims within "
        "tolerance of the paper's printed value).  *Sample 1* is the model-matched row used everywhere "
        "else in this report: the API run (`claude-opus-5-5`) for Grier, Leeson, Manekin and Montero "
        "and the first oracle run for the other nineteen.  *Sample 2* is a second oracle run "
        f"(label `{RUN2_LABEL}`; `{PIPELINE_RUN2_FILE}` for the 13 earlier papers, "
        f"`{PIPELINE_RUN2_NEW_FILE}` for the four of ROADMAP 3.6, `{PIPELINE_RUN2_SIX_FILE}` for the six "
        "of ROADMAP 3.7), so for the four API papers the two "
        "samples differ in route as well as draw.  The agent column is its first sample.  *Cells "
        "identical*, *mean* and *max abs. diff* compare the two pipeline samples cell by cell "
        "(paper × mode).\n\n" + table(hdr, out, ["l", "l", "r", "r", "r", "r", "r", "r", "r", "r", "r"])
    )


def t_variance_pipeline_cells() -> str:
    hdr = ["Paper", "Sample 1 route", "Mode", "n", "Sample 1", "Sample 2", "Abs. diff", "Agent"]
    out = []
    for e in HOLDOUT:
        route = "API" if e in API_FOUR else "oracle"
        for m in MODES:
            s1, s2, a = p55_cell(e, m), RUN2[(e, m)], cell(AGENT, e, m)
            assert s1 is not None and a is not None
            d = abs(passed(s1) - passed(s2))
            out.append(
                [
                    f"`{short(e)}`",
                    route,
                    m,
                    total(s1),
                    passed(s1),
                    passed(s2),
                    f"**{d}**" if d else "0",
                    passed(a),
                ]
            )
    return (
        "Per paper and mode: final claims within tolerance in each pipeline sample, their absolute "
        "difference (bold where non-zero), and the agent's first sample.\n\n"
        + table(hdr, out, ["l", "l", "l", "r", "r", "r", "r", "r"])
    )


def _agent_variance_cells(mode: str, entries: list[str] | None = None) -> list[tuple[Any, ...]]:
    """(entry, n, agent 1, agent 2, pipeline 1, pipeline 2 or None) for one mode over ``entries``.

    The default is the 13 earlier papers.  Pipeline 2 is None for a paper without a second
    pipeline sample (none since ROADMAP 3.7.1; kept so a new paper can enter before its rerun).
    """
    out = []
    for e in THIRTEEN if entries is None else entries:
        a1, a2, p1, p2 = cell(AGENT, e, mode), AGENT2[(e, mode)], p55_cell(e, mode), RUN2.get((e, mode))
        assert a1 is not None and p1 is not None and total(a1) == total(a2) == total(p1), (e, mode)
        assert p2 is None or total(p2) == total(a1), (e, mode)
        out.append((e, total(a1), passed(a1), passed(a2), passed(p1), None if p2 is None else passed(p2)))
    return out


def _agent_variance_stats(mode: str, entries: list[str] | None = None) -> dict[str, Any]:
    """Totals, agent cell agreement and the agent-minus-pipeline range for one mode."""
    cells = _agent_variance_cells(mode, entries)
    diffs = [abs(c[2] - c[3]) for c in cells]
    n, a1, a2, p1 = (sum(c[i] for c in cells) for i in range(1, 5))
    p2 = None if any(c[5] is None for c in cells) else sum(c[5] for c in cells)
    gaps = [a - p for a in (a1, a2) for p in (p1, p2) if p is not None]
    return {
        "cells": len(cells),
        "n": n,
        "a1": a1,
        "a2": a2,
        "p1": p1,
        "p2": p2,
        "same": sum(1 for d in diffs if d == 0),
        "mean": sum(diffs) / len(cells),
        "max": max(diffs),
        "gap_lo": min(gaps),
        "gap_hi": max(gaps),
    }


def t_variance_agent() -> str:
    hdr = [
        "Papers",
        "Mode",
        "Claims",
        "Agent sample 1",
        "Agent sample 2",
        "Pipeline sample 1",
        "Pipeline sample 2",
        "Agent cells identical",
        "Agent mean abs. diff per cell",
        "Agent max abs. diff",
        "Agent − pipeline (pairings)",
    ]
    out = []
    for (label, entries), m in (
        (le, m)
        for le in (
            ("13 earlier", THIRTEEN),
            ("4 (3.6 set)", NEW_FOUR),
            ("17", SEVENTEEN),
            ("6 (3.7 set)", NEW_SIX),
            ("23", HOLDOUT),
        )
        for m in AGENT_RUN2_MODES
    ):
        s = _agent_variance_stats(m, entries)
        pairings = "" if s["p2"] is not None else " (two pairings)"
        out.append(
            [
                label,
                m,
                s["n"],
                s["a1"],
                s["a2"],
                s["p1"],
                "—" if s["p2"] is None else s["p2"],
                f"{s['same']} / {s['cells']}",
                f"{s['mean']:.2f}",
                s["max"],
                f"{s['gap_lo']} to {s['gap_hi']}{pairings}",
            ]
        )
    return (
        "Two samples of the agent over all 23 evaluation papers, in the two modes the agent was rerun in, "
        "against the pipeline on Opus 5.5, which has two samples on all 23 (claims within tolerance of "
        "the paper's printed value).  "
        "*Agent sample 1* is the row used everywhere else in this report (ROADMAP 3.3, 3.4, 3.6, 3.7); "
        f"*agent sample 2* is a second Claude Code run (`{AGENT_RUN2_FILE}` for the 13 earlier papers, "
        f"`{AGENT_RUN2_NEW_FILE}` for the four of ROADMAP 3.6, `{AGENT_RUN2_SIX_FILE}` for the six of "
        "ROADMAP 3.7).  The pipeline samples are those of the table above.  *Cells identical*, *mean* "
        "and *max abs. diff* compare the two agent samples cell by cell; the last column is the "
        "smallest and largest of the agent-minus-pipeline differences over the four pairings (each agent "
        "sample against each pipeline sample).\n\n"
        + table(hdr, out, ["l", "l", "r", "r", "r", "r", "r", "r", "r", "r", "r"])
    )


def t_variance_agent_cells() -> str:
    hdr = ["Paper", "Mode", "n", "Agent 1", "Agent 2", "Agent abs. diff", "Pipeline 1", "Pipeline 2"]
    out = []
    for e, n, a1, a2, p1, p2, m in (
        c + (m,) for m in AGENT_RUN2_MODES for c in _agent_variance_cells(m, HOLDOUT)
    ):
        d = abs(a1 - a2)
        out.append([f"`{short(e)}`", m, n, a1, a2, f"**{d}**" if d else "0", p1, "—" if p2 is None else p2])
    out.sort(key=lambda r: (r[0], AGENT_RUN2_MODES.index(r[1])))
    return (
        "Per paper, independent and blind mode: final claims within tolerance in each agent sample, "
        "their absolute difference (bold where non-zero), and the two pipeline samples.\n\n"
        + table(hdr, out, ["l", "l", "r", "r", "r", "r", "r", "r"])
    )


def _probe_hits(rows: list[dict[str, Any]] | None = None) -> list[tuple[str, dict[str, Any]]]:
    rows = PROBE_ROWS if rows is None else rows
    return [(r["entry_id"], cd) for r in rows for cd in r["claim_details"] if cd.get("within_tolerance")]


def _probe_hit_class(cd: dict[str, Any]) -> str:
    if cd["name"] in PROBE_DERIVABLE:
        return "derivable from context"
    if cd.get("tolerance_source") == "se_band":
        return "inside ±1 SE band"
    return f"within {cd.get('tolerance_source')} tolerance"


def _probe_se_bands(rows: list[dict[str, Any]] | None = None) -> tuple[float, float, int, int]:
    """(narrowest, widest relative band, bands at or below 65 %, count) over the SE-band hits."""
    bands = [cd["tolerance"] for _e, cd in _probe_hits(rows) if _probe_hit_class(cd) == "inside ±1 SE band"]
    return min(bands), max(bands), sum(1 for b in bands if b <= 0.65), len(bands)


def _blind_total(get: Any, entries: list[str]) -> int | str:
    """Blind claims passed over ``entries``, or "—" when a sample lacks any of them."""
    rows = [get(e) for e in entries]
    return "—" if any(r is None for r in rows) else sum(passed(r) for r in rows)


def t_probe() -> str:
    from benchmark import probe

    hdr = [
        "Paper",
        "Claims",
        "Answered",
        "Within tol.",
        "Within 2×",
        "Within 5×",
        "Median rel. err",
        "Recalled / inferred / none",
        "Agent blind 1",
        "Agent blind 2",
        "Pipeline blind 1",
        "Pipeline blind 2",
    ]
    getters = [
        lambda e: cell(AGENT, e, "blind"),
        lambda e: AGENT2.get((e, "blind")),
        lambda e: p55_cell(e, "blind"),
        lambda e: RUN2.get((e, "blind")),
    ]

    def line(name: str, s: dict[str, Any], extra: list[Any]) -> list[Any]:
        c = s["conf"]
        assert c["missing"] == 0, name
        med = "—" if s["median"] is None else pct(s["median"])
        return [
            name,
            s["n"],
            s["answered"],
            s["tol"],
            s["x2"],
            s["x5"],
            med,
            f"{c['recalled']} / {c['inferred']} / {c['none']}",
            *extra,
        ]

    out = [
        line(
            f"`{short(r['entry_id'])}`",
            probe._summary([r]),
            [_blind_total(g, [r["entry_id"]]) for g in getters],
        )
        for r in PROBE_ROWS
    ]
    tot = probe._summary(PROBE_ROWS)
    out.append(
        line(
            "**total, 13 earlier papers**",
            probe._summary(PROBE_ROWS_13),
            [_blind_total(g, THIRTEEN) for g in getters],
        )
    )
    out.append(
        line(
            "**total, 17 papers (3.2–3.6)**",
            probe._summary(PROBE_ROWS_17),
            [_blind_total(g, SEVENTEEN) for g in getters],
        )
    )
    out.append(line("**total, 23 papers**", tot, [_blind_total(g, HOLDOUT) for g in getters]))
    k = Counter(_probe_hit_class(cd) for _e, cd in _probe_hits())
    lo, hi, n65, nb = _probe_se_bands()
    return (
        f"Memorization probe (`benchmark/probe.py`, `{PROBE_FILE}`): one no-tools desktop Opus "
        "subagent per paper, shown the title, authors, venue and each pinned claim's name, type and "
        "context, asked for each number from memory, scored with the blind-mode comparator.  *Within "
        "2×* and *within 5×* count answers whose relative error is at most two or five times the "
        "claim's tolerance.  The last four columns are the blind-mode counts of the two agent and two "
        "pipeline samples, for comparison (both systems' second samples cover all 23 papers).  Over all "
        f"23 papers, of the {tot['tol']} hits, {k['derivable from context']} "
        f"are derivable from the claim context, {sum(v for c, v in k.items() if c.startswith('within '))} "
        f"passes a relative tolerance, and {k['inside ±1 SE band']} land inside a ±1 SE band whose "
        f"relative half-width is {pct(lo, 0)} to {pct(hi, 0)} ({n65} of {nb} at or below 65 %).\n\n"
        + table(hdr, out, ["l", "r", "r", "r", "r", "r", "r", "l", "r", "r", "r", "r"])
    )


def t_probe_hits() -> str:
    hdr = ["Paper", "Claim", "Printed", "Probe answer", "Band (rel.)", "Band source", "Confidence", "Class"]
    out = [
        [
            f"`{short(e)}`",
            f"`{cd['name']}`",
            f"{cd['paper_value']:g}",
            f"{cd['answered']:g}",
            pct(cd["tolerance"]),
            cd["tolerance_source"],
            cd.get("confidence") or "—",
            _probe_hit_class(cd),
        ]
        for e, cd in _probe_hits()
    ]
    n = sum(len(r["claim_details"]) for r in PROBE_ROWS)
    return (
        f"Every memorization-probe answer within tolerance ({len(out)} of {n} claims).  *Band* is the "
        "comparator's relative tolerance for the claim; *derivable from context* marks the Leeson test "
        "statistics the answering agent said it back-computed from the p-values and degrees of freedom "
        "the claim contexts then stated (Section 6).\n\n"
        + table(hdr, out, ["l", "l", "r", "r", "r", "l", "l", "l"])
    )


def t_cost() -> str:
    hdr = ["Paper", "Pipeline 4.7 (S / I / B)", "Pipeline 5.5 API (S / I / B)", "Oracle calls (S / I / B)"]
    out = []
    tot47 = tot55 = 0.0
    totc = 0
    for e in HOLDOUT:
        a = [cell(P47, e, m) for m in MODES]
        b = [cell(P55, e, m) for m in MODES]
        o = [cell(ORC, e, m) for m in MODES]
        tot47 += sum(usd(r) for r in a if r)
        tot55 += sum(usd(r) for r in b if r)
        totc += sum(calls(r) for r in o if r)
        out.append(
            [
                f"`{short(e)}`",
                " / ".join(f"${usd(r):.2f}" for r in a) if all(a) else "—",
                " / ".join(f"${usd(r):.2f}" for r in b) if all(b) else "—",
                " / ".join(str(calls(r)) for r in o) if all(o) else "—",
            ]
        )
    out.append(["**Total**", f"**${tot47:.2f}**", f"**${tot55:.2f}**", f"**{totc}**"])
    same47 = sum(usd(r) for e in API_FOUR for m in MODES if (r := cell(P47, e, m)))
    dev = sum(usd(r) for e in DEV for m in MODES if (r := cell(P47, e, m)))
    tok_in = sum(
        (r.get("usage") or {}).get("by_model", {}).get("claude-opus-5-5", {}).get("input_tokens", 0)
        for e in API_FOUR
        for m in MODES
        if (r := cell(P55, e, m))
    )
    tok_out = sum(
        (r.get("usage") or {}).get("by_model", {}).get("claude-opus-5-5", {}).get("output_tokens", 0)
        for e in API_FOUR
        for m in MODES
        if (r := cell(P55, e, m))
    )
    tok_out47 = sum(
        (r.get("usage") or {}).get("by_model", {}).get("claude-opus-4-7", {}).get("output_tokens", 0)
        for e in API_FOUR
        for m in MODES
        if (r := cell(P47, e, m))
    )
    return (
        "Estimated API cost per paper and mode (`benchmark/pricing.py` list prices: `claude-opus-4-7` "
        "$5 / $25, `claude-opus-5-5` $4 / $20 per million input / output tokens).  Oracle rows cost "
        "no API credit; the column gives the number of Claude calls the oracle answered.  The agent "
        "rows record no token usage.\n\n"
        + table(hdr, out, ["l", "r", "r", "r"])
        + f"\nSame twelve API-route cells on `claude-opus-4-7`: ${same47:.2f} "
        f"(output tokens {tok_out47:,}); on `claude-opus-5-5`: ${tot55:.2f} (input {tok_in:,}, "
        f"output {tok_out:,}).  The three dev papers' pipeline 4.7 rows in the REPORT composite: "
        f"${dev:.2f}.\n"
    )


def t_dates() -> str:
    out = []
    for e in sorted(DEV + HOLDOUT):
        ent = CATALOG[e]
        out.append([f"`{short(e)}`", ent.publication_date or "—", ent.package_release_date or "—"])
    dates = [CATALOG[e].publication_date for e in DEV + HOLDOUT if CATALOG[e].publication_date]
    pkgs = [CATALOG[e].package_release_date for e in DEV + HOLDOUT if CATALOG[e].package_release_date]
    return (
        f"First public version of the paper: {min(dates)} to {max(dates)}.  Package release: "
        f"{min(pkgs)} to {max(pkgs)}.\n\n"
        + table(["Paper", "Publication date", "Package release date"], out, ["l", "l", "l"])
    )


# ---------------------------------------------------------------------------
# Failure taxonomy
# ---------------------------------------------------------------------------

DATA_FILE = "data-file resolution"
SPEC = "specification mismatch"
SAMPLE = "sample restriction"
SE_CHOICE = "SE / cluster choice"
TOL = "tolerance artifact"
EXTRACT = "extraction error"
UNDER = "under-specified methods section"
UNCLASSIFIED = "unclassified"
CATEGORIES = [DATA_FILE, SPEC, SAMPLE, SE_CHOICE, TOL, EXTRACT, UNDER, UNCLASSIFIED]

HARNESS_47 = "pipeline 4.7"
HARNESS_55 = "pipeline 5.5"
HARNESS_AGENT = "agent"

# One rule per (harness, paper, mode) cell with misses.  Keys inside a rule:
# "na" (category for claims with no reported value), "claims" (explicit
# claim -> category), "rest" (everything else).  Every rule cites the
# ROADMAP passage it rests on.  "unclassified" means the ROADMAP text does
# not say why that claim missed.
ADAMS_COUNTS = {"n_directed_dyads", "n_obs_women_partisans", "n_obs_men_partisans"}
ARIAS_COUNTS = {"respondents_us", "respondents_germany", "choice_tasks_us", "choice_tasks_germany"}
GRIER_COUNTS = {"observations_district_fe", "observations_incumbent_fe"}
HOLMAN_N = {"n_obs_did_like_may_table2", "n_obs_did_may_best_pm_table2"}
LEESON_TESTS = {
    "friendliness_full_sample",
    "brown_forsythe_donations_per_hour",
    "brown_forsythe_dollars_per_hour",
    "anova_f_donations_per_hour",
    "anova_f_dollars_per_hour",
}
LEESON_VISITS = {"station_visits_full_sample", "station_visits_five_station_subsample"}
FORSYTHE_N = {"n_obs_full_sample"}
CARRERA_N = {"bcp_regression_observations", "takeup_more_regression_observations"}
LABANDEIRA_IV_COL2 = {"reform_consumption_iv_col2"}
LABANDEIRA_EXPENDITURE = {
    "reform_expenditure_ols_col5",
    "reform_expenditure_iv_col6",
    "reform_expenditure_fe_col7",
    "reform_expenditure_fe_iv_col8",
}
LABANDEIRA_N = {"n_obs_table2", "n_households_table2"}

TAXONOMY_RULES: dict[tuple[str, str, str], dict[str, Any]] = {
    # --- agent (ROADMAP 3.3, 3.4) ---
    # 3.3: the authors' own script gives -0.000565, printed -0.0005; 12.9 % vs 10 %.
    (HARNESS_AGENT, "grier-2023", "independent"): {"rest": TOL},
    # 3.3: deflator base year unstated; run b deflated to 2018 and moved this claim.
    (HARNESS_AGENT, "grier-2023", "blind"): {"rest": UNDER},
    # 3.3: the paper's stated four-MP rule gives 1,535 dyads; the authors filtered differently.
    (HARNESS_AGENT, "adams-2023", "blind"): {"rest": UNDER},
    # 3.4: the agent used the data's percent-opposite variable; the paper divides by cosponsors + 1.
    (HARNESS_AGENT, "gagliarducci-2022", "blind"): {"rest": SPEC},
    # 3.4: "no stated rule gives 4,328".
    (HARNESS_AGENT, "holman-2022", "independent"): {"rest": UNDER},
    # 3.4: the agent did what the paper says (fixed effects, logit); the code ran random effects, linear.
    (HARNESS_AGENT, "holman-2022", "blind"): {"rest": UNDER},
    # 3.4: the paper does not state the attendance-weight formula or the item orientations.
    (HARNESS_AGENT, "lopez-moctezuma-2022", "independent"): {"rest": UNDER},
    (HARNESS_AGENT, "lopez-moctezuma-2022", "blind"): {"rest": UNDER},
    # --- the four papers of ROADMAP 3.6 (agent and oracle pipeline) ---
    # 3.6: the Table 2 out-of-the-labour-force interaction lands near -0.59 against -0.49 in all
    # four independent / blind cells of both reproducers, and on the printed value seeded; no cause
    # is recorded.  The full-sample N drifts with the handling of the rows that have no state code
    # from mid-2014 (3.6), a sample restriction.
    (HARNESS_AGENT, "forsythe-2022", "independent"): {"rest": UNCLASSIFIED},
    (HARNESS_AGENT, "forsythe-2022", "blind"): {
        "claims": dict.fromkeys(FORSYTHE_N, SAMPLE),
        "rest": UNCLASSIFIED,
    },
    (HARNESS_55, "forsythe-2022", "independent"): {
        "claims": dict.fromkeys(FORSYTHE_N, SAMPLE),
        "rest": UNCLASSIFIED,
    },
    (HARNESS_55, "forsythe-2022", "blind"): {
        "claims": dict.fromkeys(FORSYTHE_N, SAMPLE),
        "rest": UNCLASSIFIED,
    },
    # 3.6: N 1,248 / 2,946 against 1,126 / 2,824, i.e. the wave-3 $80 / 12-visit assignees kept (the
    # agents dropped them); the coefficient misses have no recorded cause beyond that.
    (HARNESS_55, "carrera-2022", "independent"): {
        "claims": dict.fromkeys(CARRERA_N, SAMPLE),
        "rest": UNCLASSIFIED,
    },
    # 3.6: the script's sample filter emptied the data (N = 0 printed), so every claim missed.
    (HARNESS_55, "carrera-2022", "blind"): {"rest": SAMPLE},
    # 3.6: NA for the seven individual-level coefficients; why is not recorded.
    (HARNESS_55, "bokobza-2022", "blind"): {"na": EXTRACT, "rest": UNCLASSIFIED},
    # --- the six papers of ROADMAP 3.7 (agent and oracle pipeline) ---
    # 3.7: the package's IV columns omit the quarterly dummies the paper says every column has, so a
    # text-following column 2 misses; the other independent misses have no recorded cause.
    (HARNESS_AGENT, "labandeira-2022", "independent"): {
        "claims": dict.fromkeys(LABANDEIRA_IV_COL2, UNDER),
        "rest": UNCLASSIFIED,
    },
    # 3.7: the blind agent took price = expenditure / quantity, so its expenditure columns equal its
    # consumption columns; the package's price is a real price, which the paper does not state.
    (HARNESS_AGENT, "labandeira-2022", "blind"): {
        "claims": dict.fromkeys(LABANDEIRA_IV_COL2 | LABANDEIRA_EXPENDITURE, UNDER),
        "rest": UNCLASSIFIED,
    },
    # 3.7: Table 4 col 1 initial acceptance 0.228 vs 0.306; no cause recorded.
    (HARNESS_AGENT, "douenne-2022", "blind"): {"rest": UNCLASSIFIED},
    # 3.7: per-capita regressors built per 10,000 of another population column; coefficients ~10,000x
    # and first-stage F about half (a rescaling alone would leave F unchanged).
    (HARNESS_55, "mokyr-2022", "blind"): {"rest": SPEC},
    # 3.7: N 21,317 / 11,852 households from the run's own instrument-availability rule.
    (HARNESS_55, "labandeira-2022", "independent"): {
        "claims": dict.fromkeys(LABANDEIRA_N, SAMPLE),
        "rest": UNCLASSIFIED,
    },
    # 3.7: N 12,349 / 8,404 households (different treatment / non-missing filters); expenditure
    # columns equal consumption columns, as in the agent's blind run.
    (HARNESS_55, "labandeira-2022", "blind"): {
        "claims": dict.fromkeys(LABANDEIRA_EXPENDITURE, UNDER),
        "rest": SAMPLE,
    },
    # 3.7: Table 8 IV 0.177 vs 0.416; no cause recorded.
    (HARNESS_55, "douenne-2022", "blind"): {"rest": UNCLASSIFIED},
    # 3.7: three Programmaticness rows (not the extremist rows DP 54 missed); no cause recorded.
    (HARNESS_55, "hollyer-2022", "blind"): {"rest": UNCLASSIFIED},
    # 3.7: four Table 2 migrant coefficients 48-67 % off (patience about a third of printed).
    (HARNESS_55, "hanushek-2022", "independent"): {"rest": UNCLASSIFIED},
    (HARNESS_55, "hanushek-2022", "blind"): {"rest": UNCLASSIFIED},
    # --- pipeline on claude-opus-4-7 (ROADMAP 3.2; counts read against 3.3 / 3.5) ---
    # Counts equal the agent's 1,535 / 1,529 from the paper's four-MP rule (3.3);
    # the coefficient's cause is not stated.
    (HARNESS_47, "adams-2023", "independent"): {
        "claims": dict.fromkeys(ADAMS_COUNTS, UNDER),
        "rest": UNCLASSIFIED,
    },
    # 3.2: all seven coefficients sign-flipped; 3.5: the 2,019-dyad rule.
    (HARNESS_47, "adams-2023", "blind"): {"claims": dict.fromkeys(ADAMS_COUNTS, SAMPLE), "rest": SPEC},
    # 3.2: AMCEs near zero (cause not stated); respondents 1,033 / 1,029.
    (HARNESS_47, "arias-2022", "independent"): {
        "claims": dict.fromkeys(ARIAS_COUNTS, SAMPLE),
        "rest": UNCLASSIFIED,
    },
    # 3.2: AMCEs ~2x too large, as seeded (feols instead of cjoint::amce).
    (HARNESS_47, "arias-2022", "blind"): {"claims": dict.fromkeys(ARIAS_COUNTS, SAMPLE), "rest": SPEC},
    # 3.2: "The independent run printed no value at all (three error repairs)."
    (HARNESS_47, "grier-2023", "independent"): {"rest": EXTRACT},
    # N reported over all rows (842 / 604), as 3.2 describes for the seeded row.  3.2's estimator
    # account quotes the seeded row's numbers (-0.00009, N 860 / 612), not this row's.  The blind
    # coefficients equal the pipeline-5.5 API blind row's and the second oracle sample's to every
    # printed digit, and no stated cause covers them (draft section 5, "Unclassified").
    (HARNESS_47, "grier-2023", "blind"): {
        "claims": dict.fromkeys(GRIER_COUNTS, SAMPLE),
        "rest": UNCLASSIFIED,
    },
    # 3.2: "the two Table 4 US max-speed trend claims off" (no cause given).
    (HARNESS_47, "hanlon-2022", "independent"): {"rest": UNCLASSIFIED},
    # 3.2: friendliness NA; five-station visit count 87 vs 102.
    (HARNESS_47, "leeson-2022", "independent"): {"na": EXTRACT, "rest": SAMPLE},
    # 3.2: different test statistics / sample for the test rows; station counts 239 / 87.
    (HARNESS_47, "leeson-2022", "blind"): {
        "claims": {**dict.fromkeys(LEESON_TESTS, SPEC), **dict.fromkeys(LEESON_VISITS, SAMPLE)}
    },
    # 3.2: blind prints NA for all six Study 1 coefficients.
    (HARNESS_47, "manekin-2022", "blind"): {"na": EXTRACT, "rest": UNCLASSIFIED},
    # 3.2: independent 3 / 10, no cause given for the misses.
    (HARNESS_47, "montero-2022", "independent"): {"rest": UNCLASSIFIED},
    # 3.2: blind applied the paper's stated five-member rule, which the code never applied; IQR NA.
    (HARNESS_47, "montero-2022", "blind"): {"na": EXTRACT, "rest": UNDER},
    # --- pipeline on Opus 5.5: API rows (ROADMAP 3.5, first table) ---
    # 3.5: 172 / 94 observations, the undocumented _iter1 / _iter2 window files.
    (HARNESS_55, "grier-2023", "independent"): {"rest": DATA_FILE},
    # N 172 / 96, which 3.5 groups with the independent row's 172 / 94 under the window files.  The
    # coefficients equal the 4.7 blind row's; the window files cannot explain the Table 1 claims,
    # which come from the main file, so the coefficients stay unclassified (see above).
    (HARNESS_55, "grier-2023", "blind"): {
        "claims": dict.fromkeys(GRIER_COUNTS, DATA_FILE),
        "rest": UNCLASSIFIED,
    },
    # 3.5: 130 rows instead of 4,770; never finds the right data file.
    (HARNESS_55, "montero-2022", "blind"): {"rest": DATA_FILE},
    # 3.5: five-station subsample wrong (98 vs 102) and with it the two dollars-per-hour tests.
    (HARNESS_55, "leeson-2022", "blind"): {"rest": SAMPLE},
    # --- pipeline on Opus 5.5: oracle rows (ROADMAP 3.5, second table and reading) ---
    # F statistic 3 % off a 1 % band; no cause given.
    (HARNESS_55, "acemoglu-2022", "independent"): {"rest": UNCLASSIFIED},
    # 3.5: 178 / 171 clusters instead of 181 / 175.
    (HARNESS_55, "acemoglu-2022", "blind"): {"rest": SAMPLE},
    (HARNESS_55, "adams-2023", "independent"): {"rest": UNCLASSIFIED},
    # 3.5: the 2,019-dyad rule.
    (HARNESS_55, "adams-2023", "blind"): {"rest": SAMPLE},
    # 3.5: 17,840 observations instead of 12,160 (wrong treatment-arm subset); three claims NA.
    (HARNESS_55, "altmann-2022", "blind"): {"na": EXTRACT, "rest": SAMPLE},
    (HARNESS_55, "dertwinkel-kalt-2022", "blind"): {"rest": UNCLASSIFIED},
    (HARNESS_55, "gagliarducci-2022", "blind"): {"rest": UNCLASSIFIED},
    # 3.5 says "random-effects / linear probability models where the paper uses fixed effects and
    # logit", but 3.4 and the entry's notes say the authors' do-file is itself random effects and
    # linear, and that specification reproduces Table 2 in seeded mode, so it cannot be the cause
    # of a miss.  No other cause is stated: the coefficients are unclassified.  The two Table 2 N
    # claims show a different estimation sample on their face (145,012 / 86,517 independent;
    # 239,919 / 1,481,392 blind; printed 143,499 / 97,155).
    (HARNESS_55, "holman-2022", "independent"): {
        "claims": dict.fromkeys(HOLMAN_N, SAMPLE),
        "rest": UNCLASSIFIED,
    },
    (HARNESS_55, "holman-2022", "blind"): {
        "na": EXTRACT,
        "claims": dict.fromkeys(HOLMAN_N, SAMPLE),
        "rest": UNCLASSIFIED,
    },
    # Same four index claims as the agent (3.4): weights and orientations unstated.
    (HARNESS_55, "lopez-moctezuma-2022", "independent"): {"rest": UNDER},
    (HARNESS_55, "lopez-moctezuma-2022", "blind"): {"rest": UNDER},
}


def classify(harness: str, entry: str, mode: str, cd: dict[str, Any]) -> str:
    rule = TAXONOMY_RULES.get((harness, short(entry), mode))
    if rule is None:
        return UNCLASSIFIED
    if cd["description"] in rule.get("claims", {}):
        return rule["claims"][cd["description"]]
    if cd.get("reproduced") is None and "na" in rule:
        return rule["na"]
    return rule.get("rest", UNCLASSIFIED)


def taxonomy_misses() -> list[tuple[str, str, str, dict[str, Any], str]]:
    out = []
    for harness, rep, entries in [
        (HARNESS_47, P47, SEVEN),
        (HARNESS_55, P55_ALL, HOLDOUT),
        (HARNESS_AGENT, AGENT, HOLDOUT),
    ]:
        for e in entries:
            for m in ("independent", "blind"):
                r = cell(rep, e, m)
                if r is None:
                    continue
                for cd in r["claim_details"]:
                    if not cd.get("passed"):
                        out.append((harness, e, m, cd, classify(harness, e, m, cd)))
    used = {(h, short(e), m) for h, e, m, _cd, _c in out}
    stale = set(TAXONOMY_RULES) - used
    assert not stale, f"taxonomy rules with no misses: {sorted(stale)}"
    return out


def t_taxonomy() -> str:
    misses = taxonomy_misses()
    cols = [(h, m) for h in (HARNESS_47, HARNESS_55, HARNESS_AGENT) for m in ("independent", "blind")]
    counts = Counter((cat, h, m) for h, _e, m, _cd, cat in misses)
    rows = []
    for cat in CATEGORIES:
        rows.append(
            [cat] + [counts[(cat, h, m)] for h, m in cols] + [sum(counts[(cat, h, m)] for h, m in cols)]
        )
    rows.append(
        ["**all misses**"] + [sum(counts[(c, h, m)] for c in CATEGORIES) for h, m in cols] + [len(misses)]
    )
    hdr = ["Category"] + [f"{h}, {m}" for h, m in cols] + ["Total"]
    n_claims = {
        (h, m): sum(total(r) for r in rows_for(rep, entries, m))
        for h, rep, entries in (
            (HARNESS_47, P47, SEVEN),
            (HARNESS_55, P55_ALL, HOLDOUT),
            (HARNESS_AGENT, AGENT, HOLDOUT),
        )
        for m in ("independent", "blind")
    }
    rows.append(["claims scored"] + [n_claims[c] for c in cols] + [sum(n_claims.values())])
    main = table(hdr, rows, ["l"] + ["r"] * (len(hdr) - 1))
    papers = (
        "Pipeline 4.7: the seven 3.2 papers.  Pipeline 5.5: all twenty-three evaluation papers "
        "(API rows for Grier, Leeson, Manekin and Montero; oracle rows for the other nineteen).  "
        "Agent: all twenty-three.  First sample of each system.\n\n"
    )
    detail = table(
        ["Harness", "Paper", "Mode", "Claim", "Claimed", "Reproduced", "Category"],
        [
            [
                h,
                f"`{short(e)}`",
                m,
                f"`{cd['description']}`",
                f"{cd['claimed']:g}",
                "NA" if cd.get("reproduced") is None else f"{cd['reproduced']:.4g}",
                cat,
            ]
            for h, e, m, cd, cat in misses
        ],
        ["l", "l", "l", "l", "r", "r", "l"],
    )
    (OUT / "taxonomy_claims.md").write_text(
        "<!-- generated by docs/report/tables.py; do not edit by hand -->\n\n"
        "Every non-matching evaluation-paper claim in independent and blind mode, with its category "
        "(rules and sources in `TAXONOMY_RULES`, `docs/report/tables.py`).\n\n" + detail
    )
    return papers + main


# ---------------------------------------------------------------------------
# ROADMAP vs recomputation
# ---------------------------------------------------------------------------

ROADMAP_NAMES = {
    "grier": "grier-2023",
    "montero": "montero-2022",
    "manekin": "manekin-2022",
    "leeson": "leeson-2022",
    "arias": "arias-2022",
    "adams": "adams-2023",
    "hanlon": "hanlon-2022",
    "altmann": "altmann-2022",
    "dertwinkel-kalt": "dertwinkel-kalt-2022",
    "acemoglu": "acemoglu-2022",
    "lópez-moctezuma": "lopez-moctezuma-2022",
    "gagliarducci": "gagliarducci-2022",
    "holman": "holman-2022",
    "carrera": "carrera-2022",
    "forsythe": "forsythe-2022",
    "bokobza": "bokobza-2022",
    "brouwer": "brouwer-2022",
    "mokyr": "mokyr-2022",
    "labandeira": "labandeira-2022",
    "douenne": "douenne-2022",
    "hollyer": "hollyer-2022",
    "hanushek": "hanushek-2022",
    "dancygier": "dancygier-2022",
}
ENTRY_BY_SHORT = {short(e): e for e in HOLDOUT}


def _roadmap_35_cells() -> list[tuple[str, str, str, str, str]]:
    """(section, paper, mode, quoted, recomputed) for every cell of the two ROADMAP 3.5 per-paper tables."""
    text = (REPO / "ROADMAP.md").read_text()
    sec = text.split("### 3.5")[1].split("\n### 3.6")[0].split("\n---\n")[0]
    out = []
    num = r"(\d+|—)(?: \((\d+), (\d+)\))?"
    pat = re.compile(
        rf"^\| ([A-Za-zé-]+) \| (seeded|independent|blind) \| (\d+) \| {num} \| {num} \| (\d+) \|$"
    )
    for line in sec.splitlines():
        m = pat.match(line.strip())
        if not m:
            continue
        name, mode, n = m.group(1), m.group(2), int(m.group(3))
        e = ENTRY_BY_SHORT[ROADMAP_NAMES[name.lower()]]
        second = P55 if e in API_FOUR else ORC
        r47, r55, ra = cell(P47, e, mode), cell(second, e, mode), cell(AGENT, e, mode)
        checks = [
            ("n", str(n), str(total(r55))),
            ("pipeline 4.7 final", m.group(4), str(passed(r47)) if r47 else "—"),
            ("pipeline 5.5 / oracle final", m.group(7), str(passed(r55))),
            ("agent final", m.group(10), str(passed(ra))),
        ]
        if m.group(5) is not None and r47:
            checks += [
                ("pipeline 4.7 first scored", m.group(5), str(fs(r47))),
                ("pipeline 4.7 refinements", m.group(6), str(sum(refs(r47)))),
            ]
        if m.group(8) is not None:
            checks += [
                ("pipeline 5.5 / oracle first scored", m.group(8), str(fs(r55))),
                ("pipeline 5.5 / oracle refinements", m.group(9), str(sum(refs(r55)))),
            ]
        for what, q, rcalc in checks:
            out.append(("3.5 per-paper table", f"{short(e)} {mode}", what, q, rcalc))
    return out


def _roadmap_36_checks() -> list[tuple[str, str, str, str, str]]:
    """Every cell of the ROADMAP 3.6 per-paper table, and the totals and probe figures 3.6 quotes."""
    text = (REPO / "ROADMAP.md").read_text()
    sec = text.split("\n### 3.6")[1].split("\n### 3.7")[0].split("\n---\n")[0]
    out: list[tuple[str, str, str, str, str]] = []
    pat = re.compile(
        r"^\| ([A-Za-zé-]+) \| (seeded|independent|blind) \| (\d+) \| "
        r"(\d+) \((\d+), (\d+)\) \| (\d+) \((\d+), (\d+)\) \|$"
    )
    n_cells = 0
    for line in sec.splitlines():
        m = pat.match(line.strip())
        if not m:
            continue
        n_cells += 1
        e = ENTRY_BY_SHORT[ROADMAP_NAMES[m.group(1).lower()]]
        mode = m.group(2)
        ra, ro = cell(AGENT, e, mode), cell(ORC, e, mode)
        assert ra is not None and ro is not None, (e, mode)
        for what, q, rc in (
            ("n", m.group(3), str(total(ro))),
            ("agent final", m.group(4), str(passed(ra))),
            ("agent first scored", m.group(5), str(fs(ra))),
            ("agent refinements", m.group(6), str(sum(refs(ra)))),
            ("pipeline oracle final", m.group(7), str(passed(ro))),
            ("pipeline oracle first scored", m.group(8), str(fs(ro))),
            ("pipeline oracle refinements", m.group(9), str(sum(refs(ro)))),
        ):
            out.append(("3.6 per-paper table", f"{short(e)} {mode}", what, q, rc))
    assert n_cells == len(NEW_FOUR) * len(MODES), n_cells

    def s(rep: str, entries: list[str], mode: str) -> str:
        return str(sum_passed(rep, entries, mode)[0])

    def f(rep: str, entries: list[str], mode: str) -> str:
        return str(sum_passed(rep, entries, mode)[2])

    def gap(entries: list[str], mode: str) -> str:
        return str(sum_passed(AGENT, entries, mode)[0] - sum_passed(P55_ALL, entries, mode)[0])

    sec_t = "3.6"
    for mode, a4, a4f, p4, p4f, a17, a17f, p17, p17f, g4, g13, g17 in (
        ("seeded", 47, 43, 45, 45, 200, 194, 194, 193, 2, 4, 6),
        ("independent", 46, 46, 40, 32, 194, 192, 169, 121, 6, 19, 25),
        ("blind", 45, 45, 26, 26, 180, 173, 118, 118, 19, 43, 62),
    ):
        out += [
            (sec_t, "agent, 4 new papers", f"{mode} final", str(a4), s(AGENT, NEW_FOUR, mode)),
            (sec_t, "agent, 4 new papers", f"{mode} first scored", str(a4f), f(AGENT, NEW_FOUR, mode)),
            (sec_t, "pipeline oracle, 4 new papers", f"{mode} final", str(p4), s(ORC, NEW_FOUR, mode)),
            (
                sec_t,
                "pipeline oracle, 4 new papers",
                f"{mode} first scored",
                str(p4f),
                f(ORC, NEW_FOUR, mode),
            ),
            (sec_t, "agent, 17 papers", f"{mode} final", str(a17), s(AGENT, SEVENTEEN, mode)),
            (sec_t, "agent, 17 papers", f"{mode} first scored", str(a17f), f(AGENT, SEVENTEEN, mode)),
            (
                sec_t,
                "pipeline on Opus 5.5, 17 papers",
                f"{mode} final",
                str(p17),
                s(P55_ALL, SEVENTEEN, mode),
            ),
            (
                sec_t,
                "pipeline on Opus 5.5, 17 papers",
                f"{mode} first scored",
                str(p17f),
                f(P55_ALL, SEVENTEEN, mode),
            ),
            (sec_t, "harness gap, 4 new papers", mode, str(g4), gap(NEW_FOUR, mode)),
            (sec_t, "harness gap, 13 earlier papers", mode, str(g13), gap(THIRTEEN, mode)),
            (sec_t, "harness gap, 17 papers", mode, str(g17), gap(SEVENTEEN, mode)),
        ]
    from benchmark import probe

    ps = probe._summary(PROBE_ROWS_17)
    pk = Counter(_probe_hit_class(cd) for _e, cd in _probe_hits(PROBE_ROWS_17))
    lo, hi, n65, nb = _probe_se_bands(PROBE_ROWS_17)
    new_hits = _probe_hits([r for r in PROBE_ROWS if r["entry_id"] in NEW_FOUR])
    sec_p = "3.6 memorisation probe"
    out += [
        (sec_p, "probe, 17 papers", "claims", "201", str(ps["n"])),
        (sec_p, "probe, 17 papers", "answered", "104", str(ps["answered"])),
        (sec_p, "probe, 17 papers", "within tolerance", "36", str(ps["tol"])),
        (
            sec_p,
            "probe, 17 papers",
            "recalled / inferred / none",
            "0 / 104 / 97",
            f"{ps['conf']['recalled']} / {ps['conf']['inferred']} / {ps['conf']['none']}",
        ),
        (sec_p, "probe hits", "derivable from context", "3", str(pk["derivable from context"])),
        (sec_p, "probe hits", "inside ±1 SE band", "32", str(pk["inside ±1 SE band"])),
        (sec_p, "probe hits", "SE band range", "6 %–225 %", f"{pct(lo, 0)}–{pct(hi, 0)}"),
        (sec_p, "probe hits", "SE bands at or below 65 %", "29 of 32", f"{n65} of {nb}"),
        (sec_p, "probe hits", "hits on the 4 new papers", "10", str(len(new_hits))),
        (
            sec_p,
            "probe hits",
            "new-paper hits inside a ±1 SE band",
            "10",
            str(sum(1 for _e, cd in new_hits if _probe_hit_class(cd) == "inside ±1 SE band")),
        ),
    ]
    return out


def _roadmap_37_checks() -> list[tuple[str, str, str, str, str]]:
    """Every cell of the ROADMAP 3.7 per-paper table, its totals, two-sample ranges and probe figures."""
    text = (REPO / "ROADMAP.md").read_text()
    sec = text.split("\n### 3.7")[1].split("\n---\n")[0]
    out: list[tuple[str, str, str, str, str]] = []
    pat = re.compile(
        r"^\| ([A-Za-zé-]+) \| (seeded|independent|blind) \| (\d+) \| "
        r"(\d+) \((\d+), (\d+)\) \| (\d+) \((\d+), (\d+)\) \|$"
    )
    n_cells = 0
    for line in sec.splitlines():
        m = pat.match(line.strip())
        if not m:
            continue
        n_cells += 1
        e = ENTRY_BY_SHORT[ROADMAP_NAMES[m.group(1).lower()]]
        mode = m.group(2)
        ra, ro = cell(AGENT, e, mode), cell(ORC, e, mode)
        assert ra is not None and ro is not None, (e, mode)
        for what, q, rc in (
            ("n", m.group(3), str(total(ro))),
            ("agent final", m.group(4), str(passed(ra))),
            ("agent first scored", m.group(5), str(fs(ra))),
            ("agent refinements", m.group(6), str(sum(refs(ra)))),
            ("pipeline oracle final", m.group(7), str(passed(ro))),
            ("pipeline oracle first scored", m.group(8), str(fs(ro))),
            ("pipeline oracle refinements", m.group(9), str(sum(refs(ro)))),
        ):
            out.append(("3.7 per-paper table", f"{short(e)} {mode}", what, q, rc))
    assert n_cells == len(NEW_SIX) * len(MODES), n_cells

    def s(rep: str, entries: list[str], mode: str) -> str:
        return str(sum_passed(rep, entries, mode)[0])

    def f(rep: str, entries: list[str], mode: str) -> str:
        return str(sum_passed(rep, entries, mode)[2])

    def gap(entries: list[str], mode: str) -> str:
        return str(sum_passed(AGENT, entries, mode)[0] - sum_passed(P55_ALL, entries, mode)[0])

    sec_t = "3.7"
    for mode, a6, a6f, p6, p6f, a23, a23f, p23, p23f, g6, g17, g23 in (
        ("seeded", 77, 73, 69, 69, 277, 267, 263, 262, 8, 6, 14),
        ("independent", 73, 60, 66, 47, 267, 252, 235, 168, 7, 25, 32),
        ("blind", 70, 70, 52, 52, 250, 243, 170, 170, 18, 62, 80),
    ):
        out += [
            (sec_t, "agent, 6 new papers", f"{mode} final", str(a6), s(AGENT, NEW_SIX, mode)),
            (sec_t, "agent, 6 new papers", f"{mode} first scored", str(a6f), f(AGENT, NEW_SIX, mode)),
            (sec_t, "pipeline oracle, 6 new papers", f"{mode} final", str(p6), s(ORC, NEW_SIX, mode)),
            (sec_t, "pipeline oracle, 6 new papers", f"{mode} first scored", str(p6f), f(ORC, NEW_SIX, mode)),
            (sec_t, "agent, 23 papers", f"{mode} final", str(a23), s(AGENT, HOLDOUT, mode)),
            (sec_t, "agent, 23 papers", f"{mode} first scored", str(a23f), f(AGENT, HOLDOUT, mode)),
            (sec_t, "pipeline on Opus 5.5, 23 papers", f"{mode} final", str(p23), s(P55_ALL, HOLDOUT, mode)),
            (
                sec_t,
                "pipeline on Opus 5.5, 23 papers",
                f"{mode} first scored",
                str(p23f),
                f(P55_ALL, HOLDOUT, mode),
            ),
            (sec_t, "harness gap, 6 new papers", mode, str(g6), gap(NEW_SIX, mode)),
            (sec_t, "harness gap, 17 papers", mode, str(g17), gap(SEVENTEEN, mode)),
            (sec_t, "harness gap, 23 papers", mode, str(g23), gap(HOLDOUT, mode)),
        ]

    # Two samples: the four 3.6 papers and the 17-paper table.
    sec_v = "3.7 two samples"
    for mode, a2, p2 in (("seeded", None, 43), ("independent", 47, 33), ("blind", 45, 38)):
        if a2 is not None:
            out.append(
                (
                    sec_v,
                    "agent sample 2, 4 papers",
                    mode,
                    str(a2),
                    str(sum(passed(AGENT2[(e, mode)]) for e in NEW_FOUR)),
                )
            )
        out.append(
            (
                sec_v,
                "pipeline sample 2, 4 papers",
                mode,
                str(p2),
                str(sum(passed(RUN2[(e, mode)]) for e in NEW_FOUR)),
            )
        )
    for short_id, mode, a, b in (
        ("carrera-2022", "blind", 0, 6),
        ("carrera-2022", "independent", 6, 0),
        ("bokobza-2022", "blind", 4, 10),
        ("bokobza-2022", "seeded", 9, 7),
    ):
        e = ENTRY_BY_SHORT[short_id]
        out.append(
            (
                sec_v,
                f"{short_id} {mode}",
                "pipeline 1 → 2",
                f"{a} → {b}",
                f"{passed(cell(ORC, e, mode) or {})} → {passed(RUN2[(e, mode)])}",
            )
        )
    e = ENTRY_BY_SHORT["forsythe-2022"]
    out.append(
        (
            sec_v,
            "forsythe-2022 independent",
            "agent 1 → 2",
            "12 → 13",
            f"{passed(cell(AGENT, e, 'independent') or {})} → {passed(AGENT2[(e, 'independent')])}",
        )
    )
    for mode, a1, a2, p1, p2, rng, rng13, rng4 in (
        ("seeded", "200", "—", "194", "195", "5–6", "1–4", "2–4"),
        ("independent", "194", "194", "169", "161", "25–33", "18–20", "6–14"),
        ("blind", "180", "177", "118", "120", "57–62", "40–53", "7–19"),
    ):
        s1 = str(sum(passed(cell(P55_ALL, e, mode) or {}) for e in SEVENTEEN))
        s2 = str(sum(passed(RUN2[(e, mode)]) for e in SEVENTEEN))
        ag1 = sum_passed(AGENT, SEVENTEEN, mode)[0]
        out += [
            (sec_v, "17 papers", f"{mode} agent 1", a1, str(ag1)),
            (sec_v, "17 papers", f"{mode} pipeline 1", p1, s1),
            (sec_v, "17 papers", f"{mode} pipeline 2", p2, s2),
        ]
        if mode == "seeded":
            for label, entries, quoted in (
                ("17", SEVENTEEN, rng),
                ("13", THIRTEEN, rng13),
                ("4", NEW_FOUR, rng4),
            ):
                a = sum_passed(AGENT, entries, mode)[0]
                ps = [sum(passed(cell(P55_ALL, x, mode) or {}) for x in entries)] + [
                    sum(passed(RUN2[(x, mode)]) for x in entries)
                ]
                gaps = [a - p for p in ps]
                out.append(
                    (sec_v, f"seeded gap range, {label} papers", mode, quoted, f"{min(gaps)}–{max(gaps)}")
                )
        else:
            st = _agent_variance_stats(mode, SEVENTEEN)
            out.append((sec_v, "17 papers", f"{mode} agent 2", a2, str(st["a2"])))
            for label, entries, quoted in (
                ("17", SEVENTEEN, rng),
                ("13", THIRTEEN, rng13),
                ("4", NEW_FOUR, rng4),
            ):
                sv = _agent_variance_stats(mode, entries)
                out.append(
                    (sec_v, f"gap range, {label} papers", mode, quoted, f"{sv['gap_lo']}–{sv['gap_hi']}")
                )
    for mode, same in (("independent", "15 of 17"), ("blind", "14 of 17")):
        st = _agent_variance_stats(mode, SEVENTEEN)
        out.append((sec_v, "agent cells identical, 17 papers", mode, same, f"{st['same']} of {st['cells']}"))
    for mode, same in (("seeded", "14 of 17"), ("independent", "10 of 17"), ("blind", "8 of 17")):
        pc = _variance_stats(_variance_cells(mode, SEVENTEEN))
        out.append((sec_v, "pipeline cells identical, 17 papers", mode, same, f"{pc[4]} of 17"))
    _every = [c for m in MODES for c in _variance_cells(m, SEVENTEEN)]
    _vs = _variance_stats(_every)
    out += [
        (
            sec_v,
            "pipeline samples 1 vs 2, 17 papers",
            "cells identical",
            "32 of 51",
            f"{_vs[4]} of {len(_every)}",
        ),
        (
            sec_v,
            "pipeline samples 1 vs 2, 17 papers",
            "mean abs. diff",
            "1.16",
            f"{_vs[5] / len(_every):.2f}",
        ),
        (sec_v, "pipeline samples 1 vs 2, 17 papers", "max abs. diff", "6", str(_vs[6])),
    ]

    # The agent's second sample on the six papers of 3.7 and over all 23.
    for mode, a6 in (("independent", 76), ("blind", 71)):
        out.append(
            (
                sec_v,
                "agent sample 2, 6 papers",
                mode,
                str(a6),
                str(sum(passed(AGENT2[(e, mode)]) for e in NEW_SIX)),
            )
        )
    pat2 = re.compile(r"^\| ([A-Za-zé-]+) \| (\d+) → (\d+) \| (\d+) → (\d+) \|$")
    n2 = 0
    for line in sec.splitlines():
        m = pat2.match(line.strip())
        if not m:
            continue
        n2 += 1
        e = ENTRY_BY_SHORT[ROADMAP_NAMES[m.group(1).lower()]]
        for i, mode in ((2, "independent"), (4, "blind")):
            out.append(
                (
                    sec_v,
                    f"{short(e)} {mode}",
                    "agent 1 → 2",
                    f"{m.group(i)} → {m.group(i + 1)}",
                    f"{passed(cell(AGENT, e, mode) or {})} → {passed(AGENT2[(e, mode)])}",
                )
            )
    assert n2 == len(NEW_SIX), n2
    for mode, a1, a2, same, rng in (
        ("independent", 267, 270, "20 of 23", "32–35"),
        ("blind", 250, 248, "19 of 23", "78–80"),
    ):
        st = _agent_variance_stats(mode, HOLDOUT)
        # 3.7 paired both agent samples with the pipeline's first sample only (3.7.1 has all four).
        g1 = [st["a1"] - st["p1"], st["a2"] - st["p1"]]
        out += [
            (sec_v, "agent, 23 papers", f"{mode} sample 1", str(a1), str(st["a1"])),
            (sec_v, "agent, 23 papers", f"{mode} sample 2", str(a2), str(st["a2"])),
            (sec_v, "agent, 23 papers", f"{mode} cells identical", same, f"{st['same']} of {st['cells']}"),
            (
                sec_v,
                "gap range, 23 papers, against pipeline sample 1 (two pairings)",
                mode,
                rng,
                f"{min(g1)}–{max(g1)}",
            ),
        ]

    from benchmark import probe

    ps23 = probe._summary(PROBE_ROWS)
    pk = Counter(_probe_hit_class(cd) for _e, cd in _probe_hits())
    lo, hi, n65, nb = _probe_se_bands()
    new_rows = [r for r in PROBE_ROWS if r["entry_id"] in NEW_SIX]
    new_hits = _probe_hits(new_rows)
    sec_p = "3.7 memorisation probe"
    out += [
        (sec_p, "probe, 23 papers", "claims", "278", str(ps23["n"])),
        (sec_p, "probe, 23 papers", "answered", "150", str(ps23["answered"])),
        (sec_p, "probe, 23 papers", "within tolerance", "41", str(ps23["tol"])),
        (
            sec_p,
            "probe, 23 papers",
            "recalled / inferred / none",
            "0 / 150 / 128",
            f"{ps23['conf']['recalled']} / {ps23['conf']['inferred']} / {ps23['conf']['none']}",
        ),
        (sec_p, "probe hits", "derivable from context", "3", str(pk["derivable from context"])),
        (sec_p, "probe hits", "inside ±1 SE band", "37", str(pk["inside ±1 SE band"])),
        (sec_p, "probe hits", "SE band range", "6 %–225 %", f"{pct(lo, 0)}–{pct(hi, 0)}"),
        (sec_p, "probe hits", "SE bands at or below 65 %", "34 of 37", f"{n65} of {nb}"),
        (sec_p, "probe hits", "hits on the 6 new papers", "5", str(len(new_hits))),
        (
            sec_p,
            "probe hits",
            "new-paper hits per paper (Dancygier, Douenne, Hanushek, Hollyer, Labandeira, Mokyr)",
            "0, 3, 0, 1, 1, 0",
            ", ".join(str(probe._summary([r])["tol"]) for r in new_rows),
        ),
        (
            sec_p,
            "agent blind",
            "6 new papers, per paper",
            "13, 12, 13, 13, 6, 13",
            ", ".join(str(passed(cell(AGENT, r["entry_id"], "blind") or {})) for r in new_rows),
        ),
    ]
    # The six new probe rows as printed in 3.7 (probe.markdown_table columns).
    prow = re.compile(r"^\| ([a-z-]+-20\d\d-[a-z0-9-]+) \| (\d+) \| (\d+) \| (\d+) \| (\d+) \| (\d+) \| ")
    for line in sec.splitlines():
        m = prow.match(line.strip())
        if not m or m.group(1) not in NEW_SIX:
            continue
        sm = probe._summary([r for r in PROBE_ROWS if r["entry_id"] == m.group(1)])
        q = " / ".join(m.group(i) for i in range(2, 7))
        rc = " / ".join(str(sm[k]) for k in ("n", "answered", "tol", "x2", "x5"))
        out.append((sec_p, f"probe row {short(m.group(1))}", "claims / answered / tol / 2x / 5x", q, rc))
    return out


def _roadmap_371_checks() -> list[tuple[str, str, str, str, str]]:
    """ROADMAP 3.7.1: the pipeline's second sample on the six papers of 3.7 and the 23-paper ranges."""
    text = (REPO / "ROADMAP.md").read_text()
    sec = text.split("\n### 3.7.1")[1].split("\n---\n")[0]
    out: list[tuple[str, str, str, str, str]] = []
    src = "3.7.1"

    def s(rep: str, entries: list[str], mode: str) -> str:
        return str(sum_passed(rep, entries, mode)[0])

    def f(rep: str, entries: list[str], mode: str) -> str:
        return str(sum_passed(rep, entries, mode)[2])

    cellpat = r"(\d+) \((\d+)\) → (\d+) \((\d+)\)"
    pat = re.compile(rf"^\| ([A-Za-zé-]+) \| (\d+) \| {cellpat} \| {cellpat} \| {cellpat} \|$")
    n_rows = 0
    for line in sec.splitlines():
        m = pat.match(line.strip())
        if not m:
            continue
        n_rows += 1
        e = ENTRY_BY_SHORT[ROADMAP_NAMES[m.group(1).lower()]]
        for i, mode in enumerate(MODES):
            s1, s2 = cell(ORC, e, mode), RUN2[(e, mode)]
            assert s1 is not None, (e, mode)
            g = 3 + 4 * i
            if i == 0:
                out.append((src, f"{short(e)}", "n", m.group(2), str(total(s1))))
            for what, q, rc in (
                ("sample 1 final", m.group(g), str(passed(s1))),
                ("sample 1 first scored", m.group(g + 1), str(fs(s1))),
                ("sample 2 final", m.group(g + 2), str(passed(s2))),
                ("sample 2 first scored", m.group(g + 3), str(fs(s2))),
            ):
                out.append((src, f"{short(e)} {mode}", what, q, rc))
    assert n_rows == len(NEW_SIX), n_rows

    def s2sum(entries: list[str], mode: str) -> tuple[int, int | None]:
        rs = [RUN2[(e, mode)] for e in entries]
        fss = [fs(r) for r in rs]
        return sum(passed(r) for r in rs), None if any(v is None for v in fss) else sum(v or 0 for v in fss)

    for mode, p1, p1f, p2, p2f, same in (
        ("seeded", 69, 69, 70, 69, 5),
        ("independent", 66, 47, 62, 48, 4),
        ("blind", 52, 52, 52, 52, 3),
    ):
        fin2, fs2 = s2sum(NEW_SIX, mode)
        pc = _variance_stats(_variance_cells(mode, NEW_SIX))
        out += [
            (src, "pipeline sample 1, 6 papers", f"{mode} final", str(p1), s(ORC, NEW_SIX, mode)),
            (src, "pipeline sample 1, 6 papers", f"{mode} first scored", str(p1f), f(ORC, NEW_SIX, mode)),
            (src, "pipeline sample 2, 6 papers", f"{mode} final", str(p2), str(fin2)),
            (src, "pipeline sample 2, 6 papers", f"{mode} first scored", str(p2f), str(fs2)),
            (src, "pipeline cells identical, 6 papers", mode, f"{same} of 6", f"{pc[4]} of {len(NEW_SIX)}"),
        ]
    _six = [c for m in MODES for c in _variance_cells(m, NEW_SIX)]
    _vs6 = _variance_stats(_six)
    out += [
        (
            src,
            "pipeline samples 1 vs 2, 6 papers",
            "cells identical",
            "12 of 18",
            f"{_vs6[4]} of {len(_six)}",
        ),
        (src, "pipeline samples 1 vs 2, 6 papers", "mean abs. diff", "0.83", f"{_vs6[5] / len(_six):.2f}"),
        (src, "pipeline samples 1 vs 2, 6 papers", "max abs. diff", "6", str(_vs6[6])),
        (
            src,
            "oracle answered calls, sample 2 on the six",
            "calls",
            "79",
            str(json.loads((RESULTS / PIPELINE_RUN2_SIX_FILE).read_text())["usage"]["api_calls"]),
        ),
    ]

    # The 23-paper range table: totals and gap ranges per mode, with the 17- and 6-paper ranges beside.
    rpat = re.compile(
        r"^\| (seeded|independent|blind) \| (\d+) \| (\d+|—) \| (\d+) \| (\d+) \| "
        r"\*\*(\d+)–(\d+)\*\* \| (\d+)–(\d+) \| (\d+)–(\d+) \|$"
    )
    n_modes = 0
    for line in sec.splitlines():
        m = rpat.match(line.strip())
        if not m:
            continue
        n_modes += 1
        mode = m.group(1)
        p1 = sum(passed(cell(P55_ALL, e, mode) or {}) for e in HOLDOUT)
        p2 = sum(passed(RUN2[(e, mode)]) for e in HOLDOUT)
        a1 = sum_passed(AGENT, HOLDOUT, mode)[0]
        a2 = sum(passed(AGENT2[(e, mode)]) for e in HOLDOUT) if mode in AGENT_RUN2_MODES else None
        out += [
            (src, "23 papers", f"{mode} agent 1", m.group(2), str(a1)),
            (src, "23 papers", f"{mode} agent 2", m.group(3), "—" if a2 is None else str(a2)),
            (src, "23 papers", f"{mode} pipeline 1", m.group(4), str(p1)),
            (src, "23 papers", f"{mode} pipeline 2", m.group(5), str(p2)),
        ]
        for label, entries, lo, hi in (
            ("23", HOLDOUT, m.group(6), m.group(7)),
            ("17", SEVENTEEN, m.group(8), m.group(9)),
            ("6", NEW_SIX, m.group(10), m.group(11)),
        ):
            if mode in AGENT_RUN2_MODES:
                sv = _agent_variance_stats(mode, entries)
                assert sv["p2"] is not None, (label, mode)
                rng = f"{sv['gap_lo']}–{sv['gap_hi']}"
            else:
                a = sum_passed(AGENT, entries, mode)[0]
                gaps = [a - sum(passed(cell(P55_ALL, x, mode) or {}) for x in entries)] + [
                    a - sum(passed(RUN2[(x, mode)]) for x in entries)
                ]
                rng = f"{min(gaps)}–{max(gaps)}"
            out.append((src, f"gap range, {label} papers", mode, f"{lo}–{hi}", rng))
    assert n_modes == len(MODES), n_modes

    for mode, same in (("seeded", "19 of 23"), ("independent", "14 of 23"), ("blind", "11 of 23")):
        pc = _variance_stats(_variance_cells(mode, HOLDOUT))
        out.append((src, "pipeline cells identical, 23 papers", mode, same, f"{pc[4]} of {len(HOLDOUT)}"))
    for mode, same in (("independent", "20 of 23"), ("blind", "19 of 23")):
        st = _agent_variance_stats(mode, HOLDOUT)
        out.append((src, "agent cells identical, 23 papers", mode, same, f"{st['same']} of {st['cells']}"))
    _all = [c for m in MODES for c in _variance_cells(m, HOLDOUT)]
    _vs = _variance_stats(_all)
    out += [
        (
            src,
            "pipeline samples 1 vs 2, 23 papers",
            "cells identical",
            "44 of 69",
            f"{_vs[4]} of {len(_all)}",
        ),
        (src, "pipeline samples 1 vs 2, 23 papers", "mean abs. diff", "1.07", f"{_vs[5] / len(_all):.2f}"),
        (src, "pipeline samples 1 vs 2, 23 papers", "max abs. diff", "6", str(_vs[6])),
    ]
    return out


def _quoted_totals() -> list[tuple[str, str, str, str, str]]:
    """Totals ROADMAP states in prose or table footers, each with its section."""

    def s(rep: str, entries: list[str], mode: str) -> str:
        return str(sum_passed(rep, entries, mode)[0])

    def f(rep: str, entries: list[str], mode: str) -> str:
        return str(sum_passed(rep, entries, mode)[2])

    def harness_gap(entries: list[str], mode: str) -> str:
        return str(sum_passed(AGENT, entries, mode)[0] - sum_passed(P55_ALL, entries, mode)[0])

    q: list[tuple[str, str, str, str, str]] = []
    for mode, val, fsv in (("seeded", 55, 46), ("independent", 41, 27), ("blind", 24, 24)):
        q.append(("3.2", "pipeline 4.7, 7 papers", f"{mode} final", str(val), s(P47, SEVEN, mode)))
        q.append(("3.2", "pipeline 4.7, 7 papers", f"{mode} first scored", str(fsv), f(P47, SEVEN, mode)))
    for mode, val, fsv in (("seeded", 78, 78), ("independent", 78, 77), ("blind", 75, 70)):
        q.append(("3.3", "agent, 7 papers", f"{mode} final", str(val), s(AGENT, SEVEN, mode)))
        q.append(("3.3", "agent, 7 papers", f"{mode} first scored", str(fsv), f(AGENT, SEVEN, mode)))
    for mode, val, fsv in (("seeded", 75, 73), ("independent", 70, 69), ("blind", 60, 58)):
        q.append(("3.4", "agent, 6 papers", f"{mode} final", str(val), s(AGENT, SIX_NEW, mode)))
        q.append(("3.4", "agent, 6 papers", f"{mode} first scored", str(fsv), f(AGENT, SIX_NEW, mode)))
    for mode, val in (("seeded", 153), ("independent", 148), ("blind", 135)):
        q.append(("3.4", "agent, 13 papers", f"{mode} final", str(val), s(AGENT, THIRTEEN, mode)))
    for mode, a, b, c in (("seeded", 28, 44, 43), ("independent", 24, 33, 43), ("blind", 10, 20, 43)):
        q.append(("3.5", "API 4 papers, pipeline 4.7", f"{mode} final", str(a), s(P47, API_FOUR, mode)))
        q.append(("3.5", "API 4 papers, pipeline 5.5", f"{mode} final", str(b), s(P55, API_FOUR, mode)))
        q.append(("3.5", "API 4 papers, agent", f"{mode} final", str(c), s(AGENT, API_FOUR, mode)))
    for mode, a, b in (("seeded", 105, 110), ("independent", 96, 105), ("blind", 72, 92)):
        q.append(("3.5", "oracle 9 papers, oracle", f"{mode} final", str(a), s(ORC, ORACLE_NINE, mode)))
        q.append(("3.5", "oracle 9 papers, agent", f"{mode} final", str(b), s(AGENT, ORACLE_NINE, mode)))
    for mode, a in (("seeded", 79), ("independent", 67), ("blind", 51)):
        q.append(("3.5", "7 papers, pipeline on Opus 5.5", f"{mode} final", str(a), s(P55_ALL, SEVEN, mode)))
    for mode, a in (("seeded", 0), ("independent", 11), ("blind", 24)):
        q.append(("3.5", "harness gap, 7 papers", mode, str(a), harness_gap(SEVEN, mode)))
    for mode, a in (("seeded", 5), ("independent", 9), ("blind", 20)):
        q.append(("3.5", "harness gap, 6 papers (3.4 set)", mode, str(a), harness_gap(SIX_NEW, mode)))
    for mode, a, b in (("seeded", 149, 152), ("independent", 129, 128), ("blind", 92, 82)):
        q.append(
            (
                "3.5 variance pass",
                "pipeline sample 1, 13 papers",
                f"{mode} final",
                str(a),
                s(P55_ALL, THIRTEEN, mode),
            )
        )
        q.append(
            (
                "3.5 variance pass",
                "pipeline sample 2, 13 papers",
                f"{mode} final",
                str(b),
                str(sum(passed(RUN2[(e, mode)]) for e in THIRTEEN)),
            )
        )
    _every = [c for m in MODES for c in _variance_cells(m)]
    _vs = _variance_stats(_every)
    q.append(
        (
            "3.5 variance pass",
            "pipeline samples 1 vs 2",
            "cells identical",
            "25 of 39",
            f"{_vs[4]} of {len(_every)}",
        )
    )
    q.append(
        (
            "3.5 variance pass",
            "pipeline samples 1 vs 2",
            "mean abs. diff",
            "0.97",
            f"{_vs[5] / len(_every):.2f}",
        )
    )
    q.append(("3.5 variance pass", "pipeline samples 1 vs 2", "max abs. diff", "5", str(_vs[6])))
    # Agent second sample (ROADMAP 3.5, "Agent second sample").
    for mode, a1, a2, same, mean, mx, gap in (
        ("independent", 148, 147, "12 of 13", "0.08", "1", "18–20"),
        ("blind", 135, 132, "10 of 13", "0.54", "4", "40–53"),
    ):
        st = _agent_variance_stats(mode)
        sec, what = "3.5 agent second sample", f"agent samples 1 vs 2, {mode}"
        q += [
            (sec, what, "agent sample 1 final", str(a1), str(st["a1"])),
            (sec, what, "agent sample 2 final", str(a2), str(st["a2"])),
            (sec, what, "cells identical", same, f"{st['same']} of {st['cells']}"),
            (sec, what, "mean abs. diff", mean, f"{st['mean']:.2f}"),
            (sec, what, "max abs. diff", mx, str(st["max"])),
            (sec, what, "harness gap range", gap, f"{st['gap_lo']}–{st['gap_hi']}"),
        ]
    for short_id, mode, a, b in (
        ("grier-2023", "independent", 10, 9),
        ("montero-2022", "blind", 10, 6),
        ("gagliarducci-2022", "blind", 7, 9),
        ("adams-2023", "blind", 8, 7),
    ):
        e = ENTRY_BY_SHORT[short_id]
        q.append(
            (
                "3.5 agent second sample",
                f"{short_id} {mode}",
                "agent 1 → 2",
                f"{a} → {b}",
                f"{passed(cell(AGENT, e, mode) or {})} → {passed(AGENT2[(e, mode)])}",
            )
        )
    for mode, same in (("independent", "8 of 13"), ("blind", "6 of 13")):
        _pc = _variance_stats(_variance_cells(mode))
        q.append(
            (
                "3.5 agent second sample",
                "pipeline samples 1 vs 2",
                f"{mode} cells identical",
                same,
                f"{_pc[4]} of 13",
            )
        )
    # Memorisation probe (ROADMAP 3.5, "Memorisation probe").
    from benchmark import probe

    _ps = probe._summary(PROBE_ROWS_13)
    _pk = Counter(_probe_hit_class(cd) for _e, cd in _probe_hits(PROBE_ROWS_13))
    _lo, _hi, _n65, _nb = _probe_se_bands(PROBE_ROWS_13)
    _gag = next(
        cd for _e, cd in _probe_hits(PROBE_ROWS_13) if cd["name"] == "n_sponsor_terms_ncosponsors_all_ols"
    )
    sec = "3.5 memorisation probe"
    q += [
        (sec, "probe", "claims", "154", str(_ps["n"])),
        (sec, "probe", "answered", "79", str(_ps["answered"])),
        (sec, "probe", "within tolerance", "26", str(_ps["tol"])),
        (
            sec,
            "probe",
            "recalled / inferred / none",
            "0 / 79 / 75",
            f"{_ps['conf']['recalled']} / {_ps['conf']['inferred']} / {_ps['conf']['none']}",
        ),
        (sec, "probe hits", "derivable from context", "3", str(_pk["derivable from context"])),
        (sec, "probe hits", "inside ±1 SE band", "22", str(_pk["inside ±1 SE band"])),
        (sec, "probe hits", "SE band range", "12 %–225 %", f"{pct(_lo, 0)}–{pct(_hi, 0)}"),
        (sec, "probe hits", "SE bands at or below 65 %", "19 of 22", f"{_n65} of {_nb}"),
        (
            sec,
            "probe hits",
            "Gagliarducci count",
            "4,700 vs 4,746",
            f"{_gag['answered']:,.0f} vs {_gag['paper_value']:,.0f}",
        ),
        (
            sec,
            "probe",
            "Gagliarducci hits",
            "6",
            str(
                probe._summary([r for r in PROBE_ROWS if short(r["entry_id"]) == "gagliarducci-2022"])["tol"]
            ),
        ),
    ]
    for mode, a in (("seeded", "0.3%"), ("independent", "4.9%"), ("blind", "22.3%")):
        c = metrics.closeness(rows_for(P47, SEVEN, mode))
        q.append(("3.2", "pipeline 4.7 median rel. error", mode, a, f"{c.median_rel_err * 100:.1f}%"))
    q.append(
        (
            "3.5",
            "API 4 papers cost",
            "pipeline 5.5 / same cells on 4.7",
            "$3.54 / $3.62",
            f"${sum(usd(r) for e in API_FOUR for m in MODES if (r := cell(P55, e, m))):.2f} / "
            f"${sum(usd(r) for e in API_FOUR for m in MODES if (r := cell(P47, e, m))):.2f}",
        )
    )
    q.append(
        (
            "3.2",
            "evaluation pass cost",
            "21 rows, pipeline 4.7",
            "$8.11",
            f"${sum(usd(r) for e in SEVEN for m in MODES if (r := cell(P47, e, m))):.2f}",
        )
    )
    return q


# ---------------------------------------------------------------------------
# Claim-level evidence for the two section-5 consistency questions
# ---------------------------------------------------------------------------

CONSISTENCY_CELLS = [
    ("grier-2023", "independent"),
    ("grier-2023", "blind"),
    ("holman-2022", "independent"),
    ("holman-2022", "blind"),
]


def _claim_value(row: dict[str, Any] | None, claim: str) -> str:
    if row is None:
        return "—"
    cd = next(c for c in row["claim_details"] if c["description"] == claim)
    v = cd.get("reproduced")
    if v is None:
        s = "NA"
    elif float(v).is_integer() and abs(v) >= 1:
        s = f"{int(v):,}"
    else:
        s = f"{v:.4g}"
    return s + (" ✓" if cd.get("passed") else "")


def t_consistency_claims() -> str:
    hdr = ["Paper", "Mode", "Claim", "Printed", "Pipeline 4.7", "Pipeline 5.5, sample 1", "Sample 2", "Agent"]
    out = []
    for short_id, m in CONSISTENCY_CELLS:
        e = ENTRY_BY_SHORT[short_id]
        s1, s2, r47, a = p55_cell(e, m), RUN2[(e, m)], cell(P47, e, m), cell(AGENT, e, m)
        assert s1 is not None
        for cd in s1["claim_details"]:
            c = cd["description"]
            out.append(
                [
                    f"`{short_id}`",
                    m,
                    f"`{c}`",
                    f"{cd['claimed']:g}",
                    _claim_value(r47, c),
                    _claim_value(s1, c),
                    _claim_value(s2, c),
                    _claim_value(a, c),
                ]
            )
    return (
        "Reproduced values (✓ = within tolerance) for the Grier and Holman cells discussed in "
        "Section 5.  Sample 1 is the API row for Grier and the first oracle row for Holman; sample 2 "
        "is the second oracle run (Section 4.8).  Pipeline 4.7 has no Holman rows.\n\n"
        + table(hdr, out, ["l", "l", "l", "r", "r", "r", "r", "r"])
    )


def t_discrepancies() -> str:
    checks = (
        _roadmap_35_cells()
        + _quoted_totals()
        + _roadmap_36_checks()
        + _roadmap_37_checks()
        + _roadmap_371_checks()
    )
    bad = [c for c in checks if c[3] != c[4]]
    rows = [[f"ROADMAP {sec}", what, item, quoted, recomputed] for sec, what, item, quoted, recomputed in bad]
    return (
        f"{len(checks)} numbers quoted in ROADMAP 3.2–3.7.1 (including the 3.5 variance pass, the "
        "agent's second sample, the memorization probe, the four papers of 3.6, the six papers "
        "and two-sample ranges of 3.7, and the pipeline's second sample and 23-paper ranges of "
        "3.7.1) were "
        "recomputed from the results files; "
        f"{len(bad)} differ.\n\n"
        + (
            table(["Source", "What", "Item", "ROADMAP", "Recomputed"], rows, ["l", "l", "l", "r", "r"])
            if rows
            else "None.\n"
        )
    )


TABLES = {
    "catalog": t_catalog,
    "headline": t_headline,
    "confound": t_confound,
    "seven_per_paper": t_seven_per_paper,
    "nine_oracle": t_nine_oracle,
    "four_new": t_four_new,
    "six_new": t_six_new,
    "gap_decomposition": t_gap,
    "refinement": t_refinement,
    "closeness": t_closeness,
    "three_way": t_three_way,
    "variance": t_variance,
    "variance_pipeline": t_variance_pipeline,
    "variance_pipeline_cells": t_variance_pipeline_cells,
    "variance_agent": t_variance_agent,
    "variance_agent_cells": t_variance_agent_cells,
    "probe": t_probe,
    "probe_hits": t_probe_hits,
    "cost": t_cost,
    "dates": t_dates,
    "taxonomy": t_taxonomy,
    "consistency_claims": t_consistency_claims,
    "discrepancies": t_discrepancies,
}


DRAFT = Path(__file__).resolve().parent / "draft.md"
SPLICE = re.compile(r"(<!-- table:(\w+) -->\n)(.*?)(<!-- /table:\2 -->)", re.S)


def splice(draft: str, bodies: dict[str, str]) -> str:
    """Replace the text between ``<!-- table:NAME -->`` and ``<!-- /table:NAME -->`` with table NAME."""

    def repl(m: re.Match[str]) -> str:
        name = m.group(2)
        if name not in bodies:
            raise KeyError(f"draft.md references unknown table {name!r}")
        return f"{m.group(1)}{bodies[name].rstrip()}\n{m.group(4)}"

    return SPLICE.sub(repl, draft)


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    bodies = {}
    for name, fn in TABLES.items():
        bodies[name] = fn()
        (OUT / f"{name}.md").write_text(
            f"<!-- generated by docs/report/tables.py; do not edit by hand -->\n\n{bodies[name]}"
        )
        print(f"wrote {OUT.relative_to(REPO) / (name + '.md')}")
    bodies["taxonomy_claims"] = (OUT / "taxonomy_claims.md").read_text().split("-->\n\n", 1)[1]
    if DRAFT.exists():
        DRAFT.write_text(splice(DRAFT.read_text(), bodies))
        print(f"spliced tables into {DRAFT.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
