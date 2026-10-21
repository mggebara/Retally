"""Render benchmark results to a human-readable report.

Reads the JSON produced by ``runner.write_results`` and emits:

* ``benchmark/results/REPORT.md`` — committable, browsable on GitHub.
* ``benchmark/results/report.html`` — same content as a single-page
  HTML file you can open in a browser without the dashboard's
  surrounding chrome.

The report is the *only* per-PR artefact that gets committed.  The
raw ``results.json`` and the ``.cache/`` directory stay gitignored —
they're build outputs, not source.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from benchmark import metrics, pricing

REPO_ROOT = Path(__file__).resolve().parent.parent
RESULTS_DIR = REPO_ROOT / "benchmark" / "results"


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def render_markdown(results: list[dict[str, Any]]) -> str:
    """Return the benchmark report as a single Markdown string."""
    if not results:
        return _empty_report_markdown()

    grouped = metrics.by_mode(results)
    modes = list(grouped)
    multi = len(modes) > 1
    if multi:
        lines = _multi_mode_header(results, modes)
        for mode, rows in grouped.items():
            lines.extend([_verdict_summary_markdown(rows, mode=mode), ""])
        lines.extend([_mode_gap_markdown(results), ""])
        lines.extend([_closeness_markdown(results), ""])
        for mode, rows in grouped.items():
            lines.extend([_component_breakdown_markdown(rows, mode=mode), ""])
    else:
        headline = _headline_counts(results)
        lines = [
            "# Retally benchmark report",
            "",
            f"Catalog size: **{headline['total']}** papers.  ",
            f"Executed: **{headline['executed']}**.  ",
            f"Skipped: **{headline['skipped']}** "
            f"(out_of_scope={headline['out_of_scope']}, "
            f"language_unsupported={headline['language_unsupported']}, "
            f"no_api_key={headline['no_api_key']}{_init_failed_suffix(headline)}).  ",
            f"Reproduction mode: **{modes[0]}** ({_MODE_BLURB.get(modes[0], 'unrecognised mode')}).  ",
            _reproducer_line(results),
            "",
            _verdict_summary_markdown(results),
            "",
            _closeness_markdown(results),
            "",
            _component_breakdown_markdown(results),
            "",
        ]
    cost = _cost_markdown(results)
    if cost:
        lines.extend([cost, ""])
    lines.extend(
        [
            "## Per-paper results",
            "",
            _table_header_markdown(multi),
            _table_rule_markdown(multi),
        ]
    )
    for r in results:
        lines.append(_row_markdown(r, show_mode=multi))
    lines.append("")
    return "\n".join(lines)


def render_html(results: list[dict[str, Any]]) -> str:
    """Return the report as a self-contained HTML page.

    Deliberately ascetic — table-driven, no JS, no external CSS.  This
    is a build artefact you open in a browser; it's not the user-facing
    dashboard.
    """
    headline = _headline_counts(results) if results else None
    multi = len(metrics.modes_present(results)) > 1 if results else False
    rows_html = "".join(_row_html(r, show_mode=multi) for r in results) if results else ""
    mode_th = "<th>Mode</th><th>Reproducer</th>" if multi else ""

    body = ""
    if headline is None:
        body = "<p>No benchmark results.</p>"
    else:
        body = f"""
        <h1>Retally benchmark report</h1>
        <p>
          Catalog size: <strong>{headline["total"]}</strong> papers.
          Executed: <strong>{headline["executed"]}</strong>.
          Skipped: <strong>{headline["skipped"]}</strong>
          (out_of_scope={headline["out_of_scope"]},
          language_unsupported={headline["language_unsupported"]},
          no_api_key={headline["no_api_key"]}{_init_failed_suffix(headline)}).
        </p>
        <table>
          <thead>
            <tr>
              <th>ID</th>{mode_th}<th>Status</th><th>Ran</th>
              <th>Agrees w/ paper</th><th>Agrees w/ I4R</th>
              <th>Claims (paper / I4R)</th><th>Cached</th>
            </tr>
          </thead>
          <tbody>{rows_html}</tbody>
        </table>
        """

    return _HTML_TEMPLATE.format(body=body)


def write_report(results: list[dict[str, Any]], out_dir: Path = RESULTS_DIR) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "REPORT.md").write_text(render_markdown(results), encoding="utf-8")
    (out_dir / "report.html").write_text(render_html(results), encoding="utf-8")


def main() -> int:
    """CLI entrypoint — reads results.json, writes REPORT.md + report.html."""
    src = RESULTS_DIR / "results.json"
    if not src.exists():
        import sys

        print(
            f"No results file at {src.relative_to(REPO_ROOT)}.  Run 'make benchmark' first.",
            file=sys.stderr,
        )
        return 1

    results = metrics.result_rows(json.loads(src.read_text(encoding="utf-8")))
    write_report(results)
    print(f"Wrote {(RESULTS_DIR / 'REPORT.md').relative_to(REPO_ROOT)}")
    print(f"Wrote {(RESULTS_DIR / 'report.html').relative_to(REPO_ROOT)}")
    return 0


# ---------------------------------------------------------------------------
# Aggregates
# ---------------------------------------------------------------------------


def _headline_counts(results: list[dict[str, Any]]) -> dict[str, int]:
    skipped = [r for r in results if r.get("skipped")]
    skip_reasons = [r.get("skip_reason") for r in skipped]
    return {
        "total": len(results),
        "executed": sum(1 for r in results if not r.get("skipped")),
        "skipped": len(skipped),
        "out_of_scope": sum(1 for s in skip_reasons if s == "out_of_scope"),
        "language_unsupported": sum(1 for s in skip_reasons if s == "language_unsupported"),
        "no_api_key": sum(1 for s in skip_reasons if s == "no_api_key"),
        "reproducer_init_failed": sum(1 for s in skip_reasons if s == "reproducer_init_failed"),
    }


def _init_failed_suffix(headline: dict[str, int]) -> str:
    """``, reproducer_init_failed=N`` when any run hit it; empty otherwise (keeps old reports stable)."""
    n = headline["reproducer_init_failed"]
    return f", reproducer_init_failed={n}" if n else ""


_MODE_BLURB = {
    "seeded": (
        "the authors' replication-package scripts were in the generation prompt — computational reproduction"
    ),
    "independent": (
        "the authors' scripts were withheld; reproduced from the paper text — independent reproduction"
    ),
}


def _multi_mode_header(results: list[dict[str, Any]], modes: list[str]) -> list[str]:
    """Headline for a run covering several reproduction modes.

    Counts papers once (not once per mode), then counts runs — one
    (paper, mode) row each — so the denominators stay honest.
    """
    headline = _headline_counts(results)
    n_papers = len({r["entry_id"] for r in results})
    lines = [
        "# Retally benchmark report",
        "",
        f"Catalog size: **{n_papers}** papers, each run in {len(modes)} reproduction modes.  ",
        f"Runs (paper × mode): **{headline['total']}**.  ",
        f"Executed runs: **{headline['executed']}**.  ",
        f"Skipped runs: **{headline['skipped']}** "
        f"(out_of_scope={headline['out_of_scope']}, "
        f"language_unsupported={headline['language_unsupported']}, "
        f"no_api_key={headline['no_api_key']}{_init_failed_suffix(headline)}).",
        "",
        "Reproduction modes:",
        "",
    ]
    for mode in modes:
        lines.append(f"- **{mode}**: {_MODE_BLURB.get(mode, 'unrecognised mode')}.")
    lines.extend(["", _reproducer_line(results), ""])
    return lines


def _reproducer_line(results: list[dict[str, Any]]) -> str:
    """Which agent(s) produced the rows — shown wherever the mode is."""
    names = ", ".join(f"**{n}**" for n in metrics.reproducers_present(results))
    return f"Reproducer: {names}."


def _mode_gap_markdown(results: list[dict[str, Any]]) -> str:
    """The seeded-vs-independent gap — the headline finding of a both-mode run."""
    gaps = metrics.mode_gaps(results)
    lines = [
        "## Seeded vs independent",
        "",
        "Claims passing with the authors' scripts in the prompt (seeded) versus "
        "without them (independent), per paper executed in both modes.  "
        "*Lost* claims pass seeded but not independent — what the scripts were carrying.",
        "",
    ]
    if not gaps:
        lines.append("_No paper was executed in both modes._")
        return "\n".join(lines)
    s_pass = sum(g.seeded_passed for g in gaps)
    s_total = sum(g.seeded_total for g in gaps)
    i_pass = sum(g.independent_passed for g in gaps)
    i_total = sum(g.independent_total for g in gaps)
    lost = sum(len(g.lost) for g in gaps)
    gained = sum(len(g.gained) for g in gaps)
    # The "before target feedback" column: first scored when any row recorded
    # it, else first attempt (files from before first-scored scoring), else
    # omitted (older files still).
    seeded_first = [g.seeded_passed_first_scored for g in gaps]
    independent_first = [g.independent_passed_first_scored for g in gaps]
    label = "first scored"
    explanation = (
        "*First scored* is what each mode's first script that printed results passed: "
        "after any crash repairs, before the refinement loop showed the model which claims "
        "were off target."
    )
    if all(v is None for v in (*seeded_first, *independent_first)):
        seeded_first = [g.seeded_passed_first_attempt for g in gaps]
        independent_first = [g.independent_passed_first_attempt for g in gaps]
        label = "first attempt"
        explanation = (
            "*First attempt* is what each mode's first script passed, before the refinement "
            "loop showed the model which claims were off target."
        )
    show_first = any(v is not None for v in (*seeded_first, *independent_first))
    s_first = _summed_first_attempt(seeded_first)
    i_first = _summed_first_attempt(independent_first)
    lines.extend(
        [
            f"- Seeded: **{s_pass} / {s_total}** claims passed"
            + (f" ({label} {s_first} / {s_total})" if s_first is not None else ""),
            f"- Independent: **{i_pass} / {i_total}** claims passed"
            + (f" ({label} {i_first} / {i_total})" if i_first is not None else ""),
            f"- Lost without the scripts: **{lost}**; gained: **{gained}**",
            "",
        ]
    )
    if show_first:
        lines.extend(
            [
                explanation,
                "",
                "| Entry | Split | Reproducer | Seeded | Independent "
                f"| {label.capitalize()} (seeded / independent) | Lost without scripts |",
                "|---|---|---|---|---|---|---|",
            ]
        )
    else:
        lines.extend(
            [
                "| Entry | Split | Reproducer | Seeded | Independent | Lost without scripts |",
                "|---|---|---|---|---|---|",
            ]
        )
    for g, s_one, i_one in zip(gaps, seeded_first, independent_first, strict=True):
        lost_str = ", ".join(f"`{d}`" for d in g.lost) if g.lost else "—"
        first_cell = ""
        if show_first:
            first_cell = (
                f" {_count_or_dash(s_one)}/{g.seeded_total} / {_count_or_dash(i_one)}/{g.independent_total} |"
            )
        lines.append(
            f"| `{g.entry_id}` | {g.split} | {g.reproducer} | {g.seeded_passed}/{g.seeded_total} "
            f"| {g.independent_passed}/{g.independent_total} |{first_cell} {lost_str} |"
        )
    return "\n".join(lines)


def _summed_first_attempt(values: list[int | None]) -> int | None:
    """Sum of first-attempt / first-scored counts, or None unless every row recorded one."""
    if not values or any(v is None for v in values):
        return None
    return sum(v for v in values if v is not None)


def _count_or_dash(v: int | None) -> str:
    return "—" if v is None else str(v)


def _verdict_summary_markdown(results: list[dict[str, Any]], mode: str | None = None) -> str:
    suffix = f" — {mode}" if mode else ""
    executed = [r for r in results if not r.get("skipped")]
    if not executed:
        return f"## Verdicts{suffix}\n\n_No papers were executed in this run._"

    ran = sum(1 for r in executed if r.get("retally_ran"))
    agree_paper = sum(1 for r in executed if r.get("agrees_with_paper"))
    agree_i4r = sum(1 for r in executed if r.get("agrees_with_i4r"))
    i4r_attempted = sum(1 for r in executed if r.get("agrees_with_i4r") is not None)

    return (
        f"## Verdicts{suffix} (among executed papers)\n\n"
        f"- Pipeline completed without crashing: **{ran} / {len(executed)}**\n"
        f"- Agrees with the paper's stated values: **{agree_paper} / {len(executed)}**\n"
        f"- Agrees with the I4R replicator: **{agree_i4r} / {i4r_attempted}** "
        f"(of papers where I4R published a value to compare against)"
    )


def _closeness_markdown(results: list[dict[str, Any]]) -> str:
    """Per-split closeness metrics — the smooth signal prompt tuning reads.

    Empty string when no executed entry carries claim_details (older
    results.json, or nothing executed), so pre-existing reports render
    unchanged.
    """
    if not any(r.get("claim_details") for r in results if not r.get("skipped")):
        return ""
    grouped = metrics.by_mode(results)
    if len(grouped) == 1:
        lines = ["## Closeness (per split)", ""]
        for split, m in metrics.by_split(results).items():
            lines.append(f"- **{split}**: {metrics.format_metrics_line(m)}")
        return "\n".join(lines)
    lines = ["## Closeness (per split and mode)", ""]
    for mode, rows in grouped.items():
        for split, m in metrics.by_split(rows).items():
            lines.append(f"- **{split} · {mode}**: {metrics.format_metrics_line(m)}")
    return "\n".join(lines)


def _cost_markdown(results: list[dict[str, Any]]) -> str:
    """Estimated API spend per paper per mode, and the run total.

    Empty string when no row carries ``usage`` (results files that predate
    cost accounting, or reproducers that do not track it), so older reports
    render unchanged.  Prices come from ``benchmark/pricing.py``.  Calls the
    LLM cache answered cost nothing; rows served from the benchmark result
    cache made no calls in this run and are left out of the total.
    """
    if not any(r.get("usage") for r in results):
        return ""
    total = pricing.aggregate(results)
    lines = [
        "## Estimated API cost",
        "",
        f"Total estimated spend this run: **{pricing.format_usd(total['estimated_usd'])}** "
        f"across {total['api_calls']} API calls "
        f"({total['llm_cache_hits']} further calls served free by the LLM cache"
        + (
            f"; {total['rows_from_result_cache']} rows from the result cache, not re-run"
            if total["rows_from_result_cache"]
            else ""
        )
        + ").  Estimates from the price table in `benchmark/pricing.py`.",
    ]
    if total.get("unpriced_models"):
        unpriced = ", ".join(f"`{m}`" for m in total["unpriced_models"])
        lines[-1] += f"  Not priced (absent from the table): {unpriced}."
    lines.extend(
        [
            "",
            "| ID | Mode | Reproducer | API calls | LLM-cache hits | Input tok | Output tok "
            "| Cache write tok | Cache read tok | Est. cost |",
            "|---|---|---|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )
    for r in results:
        if r.get("skipped") and not r.get("usage"):
            continue
        lines.append(_cost_row_markdown(r))
    return "\n".join(lines)


def _cost_row_markdown(r: dict[str, Any]) -> str:
    head = f"| `{r['entry_id']}` | {metrics.mode_of(r)} | {metrics.reproducer_of(r)} |"
    usage = r.get("usage")
    if not usage:
        return head + " — | — | — | — | — | — | — |"
    tokens = dict.fromkeys(
        ("input_tokens", "output_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"), 0
    )
    for model_tokens in (usage.get("by_model") or {}).values():
        for k in tokens:
            tokens[k] += int((model_tokens or {}).get(k) or 0)
    usd, _ = pricing.estimate(usage)
    cost = pricing.format_usd(usd)
    if r.get("cached"):
        cost = f"result cache (was {cost})"
    return (
        f"{head} {usage.get('api_calls', 0)} | {usage.get('llm_cache_hits', 0)} "
        f"| {tokens['input_tokens']:,} | {tokens['output_tokens']:,} "
        f"| {tokens['cache_creation_input_tokens']:,} | {tokens['cache_read_input_tokens']:,} | {cost} |"
    )


def _component_breakdown_markdown(results: list[dict[str, Any]], mode: str | None = None) -> str:
    executed = [r for r in results if not r.get("skipped")]
    if not executed:
        return ""
    suffix = f" — {mode}" if mode else ""

    components = [
        "parsed",
        "claims_extracted",
        "dataset_extracted",
        "dataset_downloaded",
        "code_generated",
        "code_executed",
    ]
    lines = [
        f"## Per-component success{suffix} (executed papers only)",
        "",
        "| Component | Succeeded | Total | Rate |",
        "|---|---:|---:|---:|",
    ]
    for c in components:
        success = sum(1 for r in executed if (r.get("components") or {}).get(c) is True)
        rate = f"{100 * success / len(executed):.0f}%" if executed else "—"
        lines.append(f"| {c} | {success} | {len(executed)} | {rate} |")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Per-row rendering
# ---------------------------------------------------------------------------


def _table_header_markdown(show_mode: bool) -> str:
    mode_col = " Mode | Reproducer |" if show_mode else ""
    return (
        f"| ID |{mode_col} Status | Ran | Agrees w/ paper | Agrees w/ I4R | Claims (paper / I4R) | Cached |"
    )


def _table_rule_markdown(show_mode: bool) -> str:
    return "|---|---|---|---|---|---|---|" + ("---|---|" if show_mode else "")


def _row_markdown(r: dict[str, Any], show_mode: bool = False) -> str:
    eid = r["entry_id"]
    mode_cell = f" {metrics.mode_of(r)} | {metrics.reproducer_of(r)} |" if show_mode else ""
    status = _status_label(r)
    ran = _bool_glyph(r.get("retally_ran"))
    paper = _bool_glyph(r.get("agrees_with_paper"))
    i4r = _bool_glyph(r.get("agrees_with_i4r"))
    n_total = r.get("n_claims_in_catalog", 0)
    n_paper = r.get("n_claims_with_paper_match", 0)
    n_i4r = r.get("n_claims_with_i4r_match", 0)
    claims = f"{n_paper} / {n_i4r} of {n_total}"
    note = metrics.first_attempt_note(r)
    if note:
        claims += f" ({note})"
    cached = "✓" if r.get("cached") else ""
    return f"| `{eid}` |{mode_cell} {status} | {ran} | {paper} | {i4r} | {claims} | {cached} |"


def _row_html(r: dict[str, Any], show_mode: bool = False) -> str:
    mode_td = (
        f"<td>{_escape(metrics.mode_of(r))}</td><td>{_escape(metrics.reproducer_of(r))}</td>"
        if show_mode
        else ""
    )
    return (
        f"<tr>"
        f"<td><code>{_escape(r['entry_id'])}</code></td>"
        f"{mode_td}"
        f"<td>{_escape(_status_label(r))}</td>"
        f"<td>{_escape(_bool_glyph(r.get('retally_ran')))}</td>"
        f"<td>{_escape(_bool_glyph(r.get('agrees_with_paper')))}</td>"
        f"<td>{_escape(_bool_glyph(r.get('agrees_with_i4r')))}</td>"
        f"<td>{r.get('n_claims_with_paper_match', 0)} / {r.get('n_claims_with_i4r_match', 0)} "
        f"of {r.get('n_claims_in_catalog', 0)}{_html_first_attempt(r)}</td>"
        f"<td>{'✓' if r.get('cached') else ''}</td>"
        f"</tr>"
    )


def _html_first_attempt(r: dict[str, Any]) -> str:
    note = metrics.first_attempt_note(r)
    return f" ({_escape(note)})" if note else ""


def _status_label(r: dict[str, Any]) -> str:
    if r.get("skipped"):
        return f"skipped: {r.get('skip_reason', 'unknown')}"
    if r.get("error"):
        return f"error: {r['error'][:60]}"
    return "ran"


def _bool_glyph(v: bool | None) -> str:
    if v is True:
        return "✓"
    if v is False:
        return "✗"
    return "—"


def _escape(s: str) -> str:
    return str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def _empty_report_markdown() -> str:
    return (
        "# Retally benchmark report\n\n"
        "_The catalog is empty.  Add YAML files under benchmark/papers/ and re-run._\n"
    )


_HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Retally benchmark report</title>
<style>
  body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          max-width: 1100px; margin: 2rem auto; padding: 0 1.5rem; color: #1a202c; }}
  h1 {{ font-size: 1.6rem; }}
  table {{ width: 100%; border-collapse: collapse; margin-top: 1.5rem; font-size: .9rem; }}
  th, td {{ padding: .5rem .75rem; text-align: left; border-bottom: 1px solid #e2e6ea; }}
  th {{ background: #f9fafb; font-size: .75rem; text-transform: uppercase;
        letter-spacing: .4px; color: #6b7280; }}
  code {{ font-family: "Fira Code", "Cascadia Code", "JetBrains Mono", "Menlo", monospace;
          font-size: .85em; }}
</style>
</head>
<body>
{body}
</body>
</html>
"""


if __name__ == "__main__":
    raise SystemExit(main())
