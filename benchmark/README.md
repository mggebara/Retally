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
| `language_unsupported` | `language` is neither `python` nor `r`.  Stata is the canonical case — code is proprietary, we don't ship a sandbox image. |
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

## Keeping iteration cheap

A single live run against a real paper is expensive — five extraction
calls (claims alone sends ~120k chars of paper text), generation, and
up to six refinement rounds, all on the most capable model.  Two
mechanisms keep repeat runs from re-paying all of that:

**LLM call cache** (`benchmark/.cache/llm/`, on by default).  Every
Claude call is cached on disk keyed by its full request content, so a
re-run only pays for calls whose prompts actually changed — iterate on
the codegen prompt and the five extraction calls replay for free.
Invalidation is automatic (any prompt/model change is a new key).

```bash
OPENRA_LLM_CACHE=0 make benchmark    # fully live run (measure variance)
rm -rf benchmark/.cache/llm          # cold-start the call cache
```

**Pinned claims.**  When an entry's `original_claims` is populated, the
runner passes them straight to the pipeline and the claims-extraction
call is skipped entirely.  Just as important: every run then scores
against the *same frozen claim set* — a live extractor can return a
slightly different set each call, silently moving the yardstick between
iterations.  To curate a pin, run once live: the runner dumps what the
extractor found to `benchmark/results/extracted_claims/<id>.json` in a
shape directly pasteable into the YAML's `original_claims`; review it
(drop junk claims, fix descriptions), paste, and every later run is
extraction-free and deterministic.

## Prompt tuning: splits, closeness metrics, run comparison

Binary pass counts saturate — at 0/102 every prompt change reads as
"still zero", even one that halved every error.  Three mechanisms turn
benchmark runs into a tuning signal:

**Closeness metrics.**  Each executed entry's `results.json` row now
carries `claim_details` (claimed vs reproduced value, relative error,
tolerance, per claim).  `REPORT.md` aggregates them per split: median
relative error, match rate, and the fraction of claims within 1x / 2x /
5x of their tolerance — the widening bands are the gradient; a fix
often shows up at 5x before it registers at 1x.

**Dev / holdout splits.**  Catalog entries carry `split: dev` (default)
or `split: holdout`.  Tune prompts against dev; run holdout rarely,
only to confirm a dev-set win generalises.  Reassigning a paper doesn't
invalidate its cached result — split labels grouping, not execution.

**Run comparison.**  Keep-or-revert should be one command:

```bash
cp benchmark/results/results.json /tmp/baseline.json
# ... edit a prompt, re-run the benchmark ...
uv run python -m benchmark.compare /tmp/baseline.json benchmark/results/results.json
```

The output shows per-split metric movement, per-entry deltas, and the
specific claims that flipped (newly passing / newly failing, matched by
description across runs).

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
