# OpenRA benchmark harness

Runs `ValidationPipeline` against an external ground-truth catalog —
initially papers replicated by the
[Institute for Replication](https://i4replication.org) — and produces
per-paper + aggregate metrics.

## Workflow

```
benchmark/
├── papers/                 catalog: one YAML file per paper (committed)
├── schema.py               BenchmarkEntry / dataclass model + loader
├── runner.py               walks the catalog, drives ValidationPipeline,
│                           emits results.json
├── report.py               renders REPORT.md + report.html from results.json
├── .cache/                 content-addressable cache (gitignored)
└── results/
    ├── results.json        runner output (gitignored — rebuildable)
    ├── REPORT.md           committed; the human-readable artefact
    └── report.html         gitignored; standalone browsable copy
```

## Three verdicts per paper

The runner records three independent flags:

| Verdict | Meaning |
|---|---|
| `openra_ran` | The pipeline completed without raising. Distinct from "all claims passed" — we want to know whether the infrastructure works even when the science doesn't. |
| `agrees_with_paper` | OpenRA's reproduced values pass against the paper's stated values (the existing `overall_passed` signal). |
| `agrees_with_i4r` | OpenRA's reproduced values pass against the *I4R replicator's* reproduced values (not the paper's). `None` when no I4R finding has a value to compare to. |

The three can disagree.  In particular, `ran ✓ / agrees_with_paper ✓ /
agrees_with_i4r ✗` means OpenRA faithfully reproduced what the paper
said, but the careful human replicators found a different number — the
"non-robust" signal we want to surface, not collapse.

## Skip categories (recorded, not failed)

A catalog entry can be cleanly skipped:

| Reason | When |
|---|---|
| `out_of_scope` | `out_of_scope_reason` is set on the entry (e.g. "Stata required") |
| `language_unsupported` | `language` is neither `python` nor `r` (Stata is deferred — code is proprietary; we don't ship a sandbox image). |
| `no_api_key` | Pipeline construction failed (typically `ANTHROPIC_API_KEY` not in env) |

## Running it

```bash
export ANTHROPIC_API_KEY="sk-ant-..."   # or skip; the runner will record NO_API_KEY skips
make benchmark
```

For each catalog entry the runner emits one row in `results.json`.
The renderer then produces a Markdown table and a self-contained HTML
page from that JSON.  The report file is committed; `results.json` is
not (it's a rebuildable artefact).

Re-running with no catalog or pipeline changes hits the cache and
finishes in seconds:

```bash
make benchmark                       # cached re-run
make benchmark-report                # just re-render from results.json
```

## Adding a new paper

```bash
$EDITOR benchmark/papers/<author>-<year>-<slug>.yaml
```

Required fields: `id`, `i4r_report_url`, `language`, `outcome_label`,
`paper.source`.  See `schema.py` for the full surface.  Worked examples
covering Python, R, and an out-of-scope Stata entry live under
`tests/fixtures/benchmark_placeholders/` — they're test fixtures, not
catalog entries, so the real `papers/` directory stays uncluttered.

## Caveats

- The catalog is hand-curated.  We do NOT scrape I4R — entries are
  added by hand from the published reports.
- Many I4R papers are out of OpenRA's domain (Stata, R, restricted
  data).  The catalog is honest about which ones we can't run; the
  aggregate "OpenRA performance" metric uses the executed subset as
  its denominator, with the catalog-vs-executed gap surfaced
  separately in the report.
- "Agrees with I4R" uses the same tolerance as the comparator's
  paper-claim check today (default 1%).  Easy to tighten later if
  the data shows we systematically under/over-match.
