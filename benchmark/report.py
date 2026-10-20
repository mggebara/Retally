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

from benchmark import metrics

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
            f"no_api_key={headline['no_api_key']}).  ",
            f"Reproduction mode: **{modes[0]}** ({_MODE_BLURB.get(modes[0], 'unrecognised mode')}).",
            "",
            _verdict_summary_markdown(results),
            "",
            _closeness_markdown(results),
            "",
            _component_breakdown_markdown(results),
            "",
        ]
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
    mode_th = "<th>Mode</th>" if multi else ""

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
          no_api_key={headline["no_api_key"]}).
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

    results = json.loads(src.read_text(encoding="utf-8"))
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
    }


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
        f"no_api_key={headline['no_api_key']}).",
        "",
        "Reproduction modes:",
        "",
    ]
    for mode in modes:
        lines.append(f"- **{mode}**: {_MODE_BLURB.get(mode, 'unrecognised mode')}.")
    lines.append("")
    return lines


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
    lines.extend(
        [
            f"- Seeded: **{s_pass} / {s_total}** claims passed",
            f"- Independent: **{i_pass} / {i_total}** claims passed",
            f"- Lost without the scripts: **{lost}**; gained: **{gained}**",
            "",
            "| Entry | Split | Seeded | Independent | Lost without scripts |",
            "|---|---|---|---|---|",
        ]
    )
    for g in gaps:
        lost_str = ", ".join(f"`{d}`" for d in g.lost) if g.lost else "—"
        lines.append(
            f"| `{g.entry_id}` | {g.split} | {g.seeded_passed}/{g.seeded_total} "
            f"| {g.independent_passed}/{g.independent_total} | {lost_str} |"
        )
    return "\n".join(lines)


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
    mode_col = " Mode |" if show_mode else ""
    return (
        f"| ID |{mode_col} Status | Ran | Agrees w/ paper | Agrees w/ I4R | Claims (paper / I4R) | Cached |"
    )


def _table_rule_markdown(show_mode: bool) -> str:
    return "|---|---|---|---|---|---|---|" + ("---|" if show_mode else "")


def _row_markdown(r: dict[str, Any], show_mode: bool = False) -> str:
    eid = r["entry_id"]
    mode_cell = f" {metrics.mode_of(r)} |" if show_mode else ""
    status = _status_label(r)
    ran = _bool_glyph(r.get("retally_ran"))
    paper = _bool_glyph(r.get("agrees_with_paper"))
    i4r = _bool_glyph(r.get("agrees_with_i4r"))
    n_total = r.get("n_claims_in_catalog", 0)
    n_paper = r.get("n_claims_with_paper_match", 0)
    n_i4r = r.get("n_claims_with_i4r_match", 0)
    claims = f"{n_paper} / {n_i4r} of {n_total}"
    cached = "✓" if r.get("cached") else ""
    return f"| `{eid}` |{mode_cell} {status} | {ran} | {paper} | {i4r} | {claims} | {cached} |"


def _row_html(r: dict[str, Any], show_mode: bool = False) -> str:
    mode_td = f"<td>{_escape(metrics.mode_of(r))}</td>" if show_mode else ""
    return (
        f"<tr>"
        f"<td><code>{_escape(r['entry_id'])}</code></td>"
        f"{mode_td}"
        f"<td>{_escape(_status_label(r))}</td>"
        f"<td>{_escape(_bool_glyph(r.get('retally_ran')))}</td>"
        f"<td>{_escape(_bool_glyph(r.get('agrees_with_paper')))}</td>"
        f"<td>{_escape(_bool_glyph(r.get('agrees_with_i4r')))}</td>"
        f"<td>{r.get('n_claims_with_paper_match', 0)} / {r.get('n_claims_with_i4r_match', 0)} "
        f"of {r.get('n_claims_in_catalog', 0)}</td>"
        f"<td>{'✓' if r.get('cached') else ''}</td>"
        f"</tr>"
    )


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
