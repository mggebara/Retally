"""Regenerate every numeric table in ``docs/report/draft.md`` from committed files.

Run from the repository root::

    uv run python docs/report/tables.py

It reads only committed inputs -- the results files under
``benchmark/results/``, the catalog YAMLs under ``benchmark/papers/``,
``benchmark/corpus/candidates-2026-10-21.json`` and ``ROADMAP.md`` (for the
discrepancy check) -- and writes one Markdown file per table to
``docs/report/tables/``.  It then copies each table into ``draft.md``
between its ``<!-- table:NAME -->`` and ``<!-- /table:NAME -->`` markers, so
the tables in the draft are always the generated ones.  Scoring is never recomputed here: pass counts,
first-scored counts and verdicts are read from the rows the harness wrote,
and closeness, labelling and mode handling come from ``benchmark.metrics``.

The only hand-written content is the failure-taxonomy classification
(``TAXONOMY_RULES``), which records a judgement per non-matching claim and
cites the ROADMAP section it rests on, and the original-software column for
the four papers the corpus shortlist does not cover (``ORIGINAL_SOFTWARE``).
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
AGENT_FILES = [
    "claude-code-7papers-all-modes-2026-10-21.json",
    "claude-code-6papers-all-modes-2026-10-22.json",
]
AGENT_RERUN_FILES = ["claude-code-blind-rerun-2026-10-22.json", "claude-code-blind-rerun-2026-10-22-b.json"]
# Second complete pipeline sample on all 13 evaluation papers, through the
# oracle (ROADMAP 3.5, "Variance pass"; label ``desktop-opus-run2``).  Kept
# out of ``RAW`` so that every single-sample table is unchanged; it feeds
# only the ``variance_pipeline`` tables.
PIPELINE_RUN2_FILE = "pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json"
RUN2_LABEL = "desktop-opus-run2"
# Second Claude Code sample on all 13 evaluation papers in independent and
# blind mode (ROADMAP 3.5, "Variance pass"; run id ``2026-11-01-a``).  Kept
# out of ``RAW`` for the same reason; it feeds only the ``variance_agent``
# tables and the probe comparison.  Seeded was not rerun.
AGENT_RUN2_FILE = "claude-code-run2-13papers-indep-blind-2026-11-01.json"
AGENT_RUN2_MODES = ("independent", "blind")
# Memorisation probe (ROADMAP 3.5, "Memorisation probe"; ``benchmark/probe.py``).
PROBE_FILE = "probe-desktop-opus-2026-11-01.json"
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
    P55_ALL: "Pipeline on Opus 5.5 (API for 4 papers, oracle for 9)",
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
    for p in json.loads((REPO / "benchmark" / "corpus" / "candidates-2026-10-21.json").read_text())["papers"]
}

RAW = (
    load_rows(PIPELINE_47_FILE)
    + load_rows(PIPELINE_55_API_FILE)
    + load_rows(PIPELINE_ORACLE_FILE)
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
ORACLE_NINE = sorted({e for (rep, e, _m) in CELL if rep == ORC})
ORACLE_THREE = sorted(set(SEVEN) - set(API_FOUR))
SIX_NEW = sorted(set(HOLDOUT) - set(SEVEN))
assert set(API_FOUR) | set(ORACLE_NINE) == set(HOLDOUT) and not set(API_FOUR) & set(ORACLE_NINE)


RUN2: dict[tuple[str, str], dict[str, Any]] = {}
for _r in load_rows(PIPELINE_RUN2_FILE):
    assert metrics.reproducer_of(_r) == "pipeline" and metrics.model_of(_r) == RUN2_LABEL, _r["entry_id"]
    assert not _r.get("skipped"), _r["entry_id"]
    _key = (_r["entry_id"], metrics.mode_of(_r))
    assert _key not in RUN2, f"duplicate run2 cell {_key}"
    RUN2[_key] = _r
assert {e for e, _m in RUN2} == set(HOLDOUT) and len(RUN2) == len(HOLDOUT) * len(MODES)

AGENT2: dict[tuple[str, str], dict[str, Any]] = {}
for _r in load_rows(AGENT_RUN2_FILE):
    assert metrics.reproducer_of(_r) == AGENT and not _r.get("skipped"), _r["entry_id"]
    _key = (_r["entry_id"], metrics.mode_of(_r))
    assert _key[1] in AGENT_RUN2_MODES and _key not in AGENT2, f"unexpected agent run2 cell {_key}"
    AGENT2[_key] = _r
assert {e for e, _m in AGENT2} == set(HOLDOUT) and len(AGENT2) == len(HOLDOUT) * len(AGENT_RUN2_MODES)

PROBE_ROWS = sorted(load_rows(PROBE_FILE), key=lambda r: r["entry_id"])
assert {r["entry_id"] for r in PROBE_ROWS} == set(HOLDOUT) and len(PROBE_ROWS) == len(HOLDOUT)


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
        (P55_ALL, HOLDOUT, "all 13 evaluation"),
        (AGENT, SEVEN, "7 evaluation (3.3)"),
        (AGENT, SIX_NEW, "6 evaluation (3.4)"),
        (AGENT, HOLDOUT, "all 13 evaluation"),
        (P47, DEV, "3 dev"),
    ]
    for rep, entries, label in groups:
        out.append([DISPLAY[rep], label] + [frac(rep, entries, m) for m in MODES])
    return (
        "Claims within tolerance of the paper's printed value, summed over papers; first-scored "
        "count in parentheses.  One run per cell.\n\n" + table(hdr, out, ["l", "l", "r", "r", "r"])
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
    for label, entries in [("6 papers (3.4 set)", SIX_NEW), ("all 13", HOLDOUT)]:
        for m in MODES:
            a, n, _ = sum_passed(AGENT, entries, m)
            p55, _, _ = sum_passed(P55_ALL, entries, m)
            out.append([label, m, n, "—", "—", f"{a - p55:+d}"])
    return (
        "Differences in claims within tolerance, summed over papers.  On the 3.2 set the total "
        "agent-over-pipeline-4.7 difference splits exactly into a model effect (pipeline on Opus 5.5 "
        "minus pipeline on 4.7) and a harness effect (agent minus pipeline on Opus 5.5).  The 3.4 "
        "papers have no 4.7 rows, so only the harness effect exists there.  One run per cell; no "
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
        (AGENT, HOLDOUT, "13"),
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
        (P55_ALL, HOLDOUT, "13"),
        (AGENT, HOLDOUT, "13"),
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
        "Mode",
        "Papers",
        "paper ✓ I4R ✓",
        "paper ✓ I4R ✗",
        "paper ✗ I4R ✓",
        "paper ✗ I4R ✗",
        "I4R n/a",
    ]
    out = []
    for rep, entries in [(P47, SEVEN), (P55_ALL, HOLDOUT), (AGENT, HOLDOUT)]:
        for m in MODES:
            rs = rows_for(rep, entries, m)
            k = Counter((bool(r.get("agrees_with_paper")), r.get("agrees_with_i4r")) for r in rs)
            out.append(
                [
                    DISPLAY[rep],
                    m,
                    len(rs),
                    k[(True, True)],
                    k[(True, False)],
                    k[(False, True)],
                    k[(False, False)],
                    k[(True, None)] + k[(False, None)],
                ]
            )
    summary = table(hdr, out, ["l", "l", "r", "r", "r", "r", "r", "r"])
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


def _variance_cells(mode: str) -> list[tuple[str, int, int, int, int]]:
    """(entry, n, sample 1, sample 2, agent) for one mode over the 13 evaluation papers."""
    out = []
    for e in HOLDOUT:
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
    every: list[tuple[str, int, int, int, int]] = []
    for m in MODES:
        cells = _variance_cells(m)
        every += cells
        n, s1, s2, a, same, sad, mx = _variance_stats(cells)
        out.append(
            [
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
        "Two samples of the pipeline on Opus 5.5 over the 13 evaluation papers (claims within "
        "tolerance of the paper's printed value).  *Sample 1* is the model-matched row used everywhere "
        "else in this report: the API run (`claude-opus-5-5`) for Grier, Leeson, Manekin and Montero "
        "and the first oracle run for the other nine.  *Sample 2* is a second oracle run on all 13 "
        f"(label `{RUN2_LABEL}`, `{PIPELINE_RUN2_FILE}`), so for the four API papers the two samples "
        "differ in route as well as draw.  The agent column is its first sample.  *Cells identical*, "
        "*mean* and *max abs. diff* compare the two pipeline samples cell by cell (paper × mode).\n\n"
        + table(hdr, out, ["l", "r", "r", "r", "r", "r", "r", "r", "r", "r"])
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


def _agent_variance_cells(mode: str) -> list[tuple[str, int, int, int, int, int]]:
    """(entry, n, agent 1, agent 2, pipeline 1, pipeline 2) for one mode over the 13 evaluation papers."""
    out = []
    for e in HOLDOUT:
        a1, a2, p1, p2 = cell(AGENT, e, mode), AGENT2[(e, mode)], p55_cell(e, mode), RUN2[(e, mode)]
        assert a1 is not None and p1 is not None and total(a1) == total(a2) == total(p1) == total(p2), (
            e,
            mode,
        )
        out.append((e, total(a1), passed(a1), passed(a2), passed(p1), passed(p2)))
    return out


def _agent_variance_stats(mode: str) -> dict[str, Any]:
    """Totals, agent cell agreement and the agent-minus-pipeline range for one mode."""
    cells = _agent_variance_cells(mode)
    diffs = [abs(c[2] - c[3]) for c in cells]
    n, a1, a2, p1, p2 = (sum(c[i] for c in cells) for i in range(1, 6))
    gaps = [a - p for a in (a1, a2) for p in (p1, p2)]
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
        "Mode",
        "Claims",
        "Agent sample 1",
        "Agent sample 2",
        "Pipeline sample 1",
        "Pipeline sample 2",
        "Agent cells identical",
        "Agent mean abs. diff per cell",
        "Agent max abs. diff",
        "Agent − pipeline (four pairings)",
    ]
    out = []
    for m in AGENT_RUN2_MODES:
        s = _agent_variance_stats(m)
        out.append(
            [
                m,
                s["n"],
                s["a1"],
                s["a2"],
                s["p1"],
                s["p2"],
                f"{s['same']} / {s['cells']}",
                f"{s['mean']:.2f}",
                s["max"],
                f"{s['gap_lo']} to {s['gap_hi']}",
            ]
        )
    return (
        "Two samples of the agent and two of the pipeline on Opus 5.5 over the 13 evaluation papers, "
        "in the two modes the agent was rerun in (claims within tolerance of the paper's printed "
        "value).  *Agent sample 1* is the row used everywhere else in this report (ROADMAP 3.3–3.4); "
        f"*agent sample 2* is a second Claude Code run on all 13 (`{AGENT_RUN2_FILE}`).  The pipeline "
        "samples are those of the table above.  *Cells identical*, *mean* and *max abs. diff* compare "
        "the two agent samples cell by cell; the last column is the smallest and largest of the four "
        "agent-minus-pipeline differences (each agent sample against each pipeline sample).\n\n"
        + table(hdr, out, ["l", "r", "r", "r", "r", "r", "r", "r", "r", "r"])
    )


def t_variance_agent_cells() -> str:
    hdr = ["Paper", "Mode", "n", "Agent 1", "Agent 2", "Agent abs. diff", "Pipeline 1", "Pipeline 2"]
    out = []
    for e, n, a1, a2, p1, p2, m in (c + (m,) for m in AGENT_RUN2_MODES for c in _agent_variance_cells(m)):
        d = abs(a1 - a2)
        out.append([f"`{short(e)}`", m, n, a1, a2, f"**{d}**" if d else "0", p1, p2])
    out.sort(key=lambda r: (r[0], AGENT_RUN2_MODES.index(r[1])))
    return (
        "Per paper, independent and blind mode: final claims within tolerance in each agent sample, "
        "their absolute difference (bold where non-zero), and the two pipeline samples.\n\n"
        + table(hdr, out, ["l", "l", "r", "r", "r", "r", "r", "r"])
    )


def _probe_hits() -> list[tuple[str, dict[str, Any]]]:
    return [
        (r["entry_id"], cd) for r in PROBE_ROWS for cd in r["claim_details"] if cd.get("within_tolerance")
    ]


def _probe_hit_class(cd: dict[str, Any]) -> str:
    if cd["name"] in PROBE_DERIVABLE:
        return "derivable from context"
    if cd.get("tolerance_source") == "se_band":
        return "inside ±1 SE band"
    return f"within {cd.get('tolerance_source')} tolerance"


def _probe_se_bands() -> tuple[float, float, int, int]:
    """(narrowest, widest relative band, bands at or below 65 %, count) over the SE-band hits."""
    bands = [cd["tolerance"] for _e, cd in _probe_hits() if _probe_hit_class(cd) == "inside ±1 SE band"]
    return min(bands), max(bands), sum(1 for b in bands if b <= 0.65), len(bands)


def _blind_total(get: Any) -> int:
    return sum(passed(get(e)) for e in HOLDOUT)


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
        lambda e: AGENT2[(e, "blind")],
        lambda e: p55_cell(e, "blind"),
        lambda e: RUN2[(e, "blind")],
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
        line(f"`{short(r['entry_id'])}`", probe._summary([r]), [passed(g(r["entry_id"])) for g in getters])
        for r in PROBE_ROWS
    ]
    tot = probe._summary(PROBE_ROWS)
    out.append(line("**total**", tot, [_blind_total(g) for g in getters]))
    k = Counter(_probe_hit_class(cd) for _e, cd in _probe_hits())
    lo, hi, n65, nb = _probe_se_bands()
    return (
        f"Memorization probe (`benchmark/probe.py`, `{PROBE_FILE}`): one no-tools desktop Opus "
        "subagent per paper, shown the title, authors, venue and each pinned claim's name, type and "
        "context, asked for each number from memory, scored with the blind-mode comparator.  *Within "
        "2×* and *within 5×* count answers whose relative error is at most two or five times the "
        "claim's tolerance.  The last four columns are the blind-mode counts of the two agent and two "
        f"pipeline samples, for comparison.  Of the {tot['tol']} hits, {k['derivable from context']} "
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
        "Pipeline 4.7: the seven 3.2 papers.  Pipeline 5.5: all thirteen evaluation papers "
        "(API rows for Grier, Leeson, Manekin and Montero; oracle rows for the other nine).  "
        "Agent: all thirteen.\n\n"
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
}
ENTRY_BY_SHORT = {short(e): e for e in HOLDOUT}


def _roadmap_35_cells() -> list[tuple[str, str, str, str, str]]:
    """(section, paper, mode, quoted, recomputed) for every cell of the two ROADMAP 3.5 per-paper tables."""
    text = (REPO / "ROADMAP.md").read_text()
    sec = text.split("### 3.5")[1].split("\n---\n")[0]
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
        q.append(("3.4", "agent, 13 papers", f"{mode} final", str(val), s(AGENT, HOLDOUT, mode)))
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
                s(P55_ALL, HOLDOUT, mode),
            )
        )
        q.append(
            (
                "3.5 variance pass",
                "pipeline sample 2, 13 papers",
                f"{mode} final",
                str(b),
                str(sum(passed(RUN2[(e, mode)]) for e in HOLDOUT)),
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

    _ps = probe._summary(PROBE_ROWS)
    _pk = Counter(_probe_hit_class(cd) for _e, cd in _probe_hits())
    _lo, _hi, _n65, _nb = _probe_se_bands()
    _gag = next(cd for _e, cd in _probe_hits() if cd["name"] == "n_sponsor_terms_ncosponsors_all_ols")
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
    checks = _roadmap_35_cells() + _quoted_totals()
    bad = [c for c in checks if c[3] != c[4]]
    rows = [[f"ROADMAP {sec}", what, item, quoted, recomputed] for sec, what, item, quoted, recomputed in bad]
    return (
        f"{len(checks)} numbers quoted in ROADMAP 3.2–3.5 (including the 3.5 variance pass, the "
        "agent's second sample and the memorization probe) were "
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
