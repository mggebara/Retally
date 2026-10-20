# Retally benchmark harness

Scores a *reproducer* — by default Retally's own `ValidationPipeline` —
against an external ground-truth catalog (initially papers replicated by
the [Institute for Replication](https://i4replication.org)) and produces
per-paper + aggregate metrics.  The harness owns the scoring: any agent
that implements the `Reproducer` protocol is held to exactly the same
yardstick (see [Plugging in another agent](#plugging-in-another-agent)).

## Workflow

```
benchmark/
├── papers/                 catalog: one YAML file per paper (committed)
├── schema.py               BenchmarkEntry / dataclass model + loader
├── reproducer.py           the agent protocol (Reproducer / Reproduction),
│                           the pipeline adapter, script-free dataset copies
├── runner.py               walks the catalog, drives a Reproducer, scores
│                           its raw outputs, emits results.json
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
| `retally_ran` | The reproducer completed without raising. Distinct from "all claims passed" — we want to know whether the infrastructure works even when the science doesn't. |
| `agrees_with_paper` | The reproduced values pass against the paper's stated values — every claim, at least one claim (the same rule as the pipeline's `overall_passed`, but computed by the harness). |
| `agrees_with_i4r` | Retally's reproduced values pass against the *I4R replicator's* reproduced values (not the paper's). `None` when no I4R finding has a value to compare to. |

The three can disagree.  In particular, `ran ✓ / agrees_with_paper ✓ /
agrees_with_i4r ✗` means Retally faithfully reproduced what the paper
said, but the careful human replicators found a different number — the
"non-robust" signal we want to surface, not collapse.

**Who scores.**  Both agreement verdicts are computed by the harness
(`runner.score_reproduction`), never by the reproducer.  The reproducer
returns raw `{name: value}` outputs; the harness matches them to the
claims (the entry's pinned `original_claims`, or the reproducer's own
claims for an unpinned entry) with `ResultComparator` and applies the
mode's `TolerancePolicy`.  The pipeline still compares internally — its
claim-refinement loop needs to know which claims are off — but that
result is discarded at the adapter boundary.  For the pipeline the two
computations are identical (same comparator, same claims, same final
outputs); `tests/test_benchmark_reproducer.py` re-scores the committed
`results/baseline-2026-10-19.json` through the harness path and gets
every recorded verdict back.

## Two reproduction modes: seeded and independent

Every result row records the `mode` it ran in, and rows are identified by
`(entry_id, mode)` everywhere (results.json, the result cache, the report,
`benchmark.compare`):

| Mode | The generator sees | A pass measures | Tolerance |
|---|---|---|---|
| `seeded` (default) | paper text, claims, dataset listing, **and the authors' replication-package scripts** (plus any linked repo), presented as ground truth | *computational* reproduction — can the model translate the authors' Stata/R into fixest and run it | strict: per-type relative tolerance (COEFFICIENT 2 %, SE 5 %, …) |
| `independent` | paper text, claims, and a **script-free copy** of the dataset only — scripts withheld from the prompt *and* removed from the directory that is listed and mounted, linked code not fetched, and the prompt forbids opening any script files | *independent* reproduction — can the model regenerate the analysis from the paper's description | SE-aware: within ±k·SE of the reported value when the claim pins a `standard_error` (k = 1, never narrower than the relative tolerance); relative tolerance otherwise |

Both are worth having; **the gap between them is the headline number** —
how much of a seeded pass survives without the authors' code.  A
both-mode report leads with a *Seeded vs independent* section listing,
per paper, the claims lost without the scripts.

The SE band only bites when the pinned claim carries `standard_error` in
the catalog YAML, so pin SEs alongside coefficients.  The independent
band is deliberately looser than the seeded one: compare the two modes'
*pass sets*, and read the closeness bands (which use each claim's own
effective tolerance) with that in mind.

Contamination caveat: every paper in the corpus is 2022–2023 and every
current model's training data extends past that, so *both* modes are
pre-cutoff.  Record `publication_date` and `package_release_date` on each
entry (see below) so this can be discussed per paper; do not read the
seeded/independent gap as a contamination control.

## Skip categories (recorded, not failed)

A catalog entry can be cleanly skipped:

| Reason | When |
|---|---|
| `out_of_scope` | `out_of_scope_reason` is set on the entry (e.g. "Stata required") |
| `language_unsupported` | `language` is neither `python` nor `r`.  Stata is the canonical case — code is proprietary, we don't ship a sandbox image. |
| `no_api_key` | Reproducer construction failed (typically `ANTHROPIC_API_KEY` not in env) |

## Running it

```bash
export ANTHROPIC_API_KEY="sk-ant-..."   # or skip; the runner will record NO_API_KEY skips
make benchmark                                    # seeded mode (the default)
uv run python -m benchmark.runner --mode independent
uv run python -m benchmark.runner --mode both     # one row per entry per mode
uv run python -m benchmark.runner --only dincecco-2022-india-warfare --mode both
```

`--mode {seeded,independent,both}`, `--only ENTRY_ID` (repeatable), and
`--reproducer NAME` (default `pipeline`; see below) combine.  For each
catalog entry and mode the runner emits one row in `results.json`,
carrying `"mode"` and `"reproducer"` fields (rows from files that
predate them are read as `seeded` / `pipeline`).
The renderer then produces a Markdown table and a self-contained HTML
page from that JSON.  The report file is committed; `results.json` is
not (it's a rebuildable artefact).

Re-running with no catalog or pipeline changes hits the cache and
finishes in seconds.  The result cache (`benchmark/.cache/<hash>.json`)
is keyed on the catalog entry, the retally version, **the mode**, and —
for anything other than the default pipeline — the reproducer, so a
seeded result is never served for an independent run nor one agent's
result for another's (independent-mode keys also carry the script-free
dataset contract, so results from before it are not reused); `split`,
`publication_date`, and `package_release_date` are excluded from the key
because they never reach the pipeline.  The LLM cache keys on full
prompt content, so the two modes' generation calls are distinct entries
while the shared extraction calls replay across modes.

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
RETALLY_LLM_CACHE=0 make benchmark    # fully live run (measure variance)
rm -rf benchmark/.cache/llm          # cold-start the call cache
```

**Curating headline claims (the rubric).**  Pinned claims are scored
against, so what gets pinned defines what "reproduced" means.  A claim
qualifies as *headline* when it is (a) stated in the paper's abstract
or main results table, (b) an estimate the paper's conclusions rest on,
and (c) numerically stated (a coefficient, SE, R², or sample size —
not "significant at 5%").  Target 8–12 per paper; exclude summary
statistics, appendix robustness coefficients, and anything the text
calls "suggestive".  Write descriptions as compact snake_case tokens
(`warfare_coefficient_bivariate`) — the comparator matches claims to
`RESULT:<name>` outputs by normalised exact/substring match, and the
generation prompt instructs the model to name its outputs after the
claim descriptions, so a prose description that normalises to a
40-token string will simply never match.  Put the human-readable
specification (what the estimate is, which controls, which sample) in
`context`, and the table/column in `location`.  Cross-check every
value against the I4R meta-database's `o_coeff_dbl` / `o_std_err_dbl`
columns (`benchmark/corpus/`) where the paper has rows there.

**Pinned claims.**  When an entry's `original_claims` is populated, the
runner passes them straight to the reproducer (and scores against them
whatever the reproducer reports) and the pipeline's claims-extraction
call is skipped entirely.  Just as important: every run then scores
against the *same frozen claim set* — a live extractor can return a
slightly different set each call, silently moving the yardstick between
iterations.  To curate a pin, run once live: the runner dumps what the
extractor found to `benchmark/results/extracted_claims/<id>.json` in a
shape directly pasteable into the YAML's `original_claims`; review it
(drop junk claims, fix descriptions), paste, and every later run is
extraction-free and deterministic.

## Plugging in another agent

The harness talks to an agent only through the protocol in
`benchmark/reproducer.py`:

```python
class Reproducer(Protocol):
    def reproduce(
        self,
        paper_source: str,            # entry.paper.source: URL, path, DOI, arXiv id, or text
        *,
        language: Language,           # python | r — the language the agent's code must be in
        dataset_reference: DatasetReference | None,  # built from the entry's dataset block
        claims: list[Claim] | None,   # pinned original_claims (with SEs), or None
        reproduction_mode: ReproductionMode,         # SEEDED | INDEPENDENT
    ) -> Reproduction: ...
```

A `Reproduction` is the report contract — raw numbers and artefacts,
**no verdicts**:

| Field | What to put there |
|---|---|
| `outputs` | `{name: value}` from the final run, **keyed by claim description** (the snake_case token). The harness tries an exact normalised match first, then a substring match; a claim no output name matches is scored as missing (there is no claim-type fallback). Keying by description is the only way to guarantee a value lands on its claim. For a code-running agent: the parsed `RESULT:<name>=<value>` lines. |
| `claims` | The claims the agent targeted. Ignored for scoring when the entry pins claims; used for unpinned entries and the extracted-claims dump. |
| `generated_code`, `stdout`, `stderr`, `exit_code` | The final attempt's artefacts. |
| `deviations` | Methodology changes the agent declared (`DEVIATION:` lines). |
| `stages` | `ComponentMetrics` per-stage flags; leave a stage `None` if the agent has no such stage. |

Obligations an adapter must meet:

- **Honour the mode by what is on disk.**  In `INDEPENDENT` mode give
  the agent `script_free_dataset(...)` / `script_free_copy(...)` of the
  downloaded data, not the original package (`PipelineReproducer` does
  this by wrapping the pipeline's downloader).  An instruction alone is
  not enough.
- **Run the agent's code in the same network-less sandbox** (the
  `retally-sandbox` / `retally-sandbox-r` images) so results are
  comparable.
- **Raise rather than return junk** when the agent cannot produce
  anything; the harness records `retally_ran = false` with the message.
- **Don't score yourself.**  Anything the agent decides about pass/fail
  is ignored.

Registering it — either:

1. **In this repo:** add a zero-arg factory to `REPRODUCERS` in
   `benchmark/runner.py`, then `python -m benchmark.runner --reproducer NAME`.
2. **Without editing the repo:** expose a zero-arg factory (or a class
   with a no-argument constructor) in an importable module and pass its
   spec: `python -m benchmark.runner --reproducer my_pkg.agents:make_reproducer`.

Programmatically, `run_benchmark(catalog, reproducer="name",
reproducer_factory=...)` does the same.  The factory is only called on a
cache miss, and a factory that raises (e.g. no API key) is recorded as a
`no_api_key` skip.  `pipeline` is the only built-in reproducer today; a
general-purpose agent adapter (e.g. on the Claude Agent SDK) is planned
in `ROADMAP.md` Phase 2, not built.

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
description across runs).  Everything is keyed by `(entry_id, mode)`:
a seeded row is only ever compared with a seeded row, an independent
row with an independent row.  To see the seeded-vs-independent gap
itself, run `--mode both` and read the report's *Seeded vs independent*
section rather than diffing two single-mode runs.

## Building the corpus (candidate intake)

The catalog grows by hand, but the sourcing is scripted.  `benchmark/corpus/`
holds the I4R "First Meta Database" (110 replication reports over 109 papers;
provenance and column layout in `benchmark/corpus/SOURCE.md`).  The intake
script reads it, keeps the reports Retally has a code path for (R original,
Python original, or a Stata/other original with an I4R-written R routine), and
emits one prefilled candidate YAML per report:

```bash
uv run python scripts/import_i4r_candidates.py           # -> benchmark/candidates/
uv run python scripts/import_i4r_candidates.py --limit 5 # just the first few
```

Candidates land in `benchmark/candidates/` (gitignored — rebuildable), **not**
in `papers/`.  Each is prefilled with what the database records (id, language,
outcome label, title, authors, and — for the ~20 reports that carry one — the
I4R report URL) and carries `TODO` sentinels for the three things the database
never gives: the paper URL, the dataset URL, and (for most reports) the report
URL.  Promotion is the human step below.

## Adding a new paper

Either hand-write the YAML or promote a candidate:

```bash
$EDITOR benchmark/papers/<author>-<year>-<slug>.yaml   # or:
mv benchmark/candidates/<id>.yaml benchmark/papers/     # then fill its TODOs
```

Required fields: `id`, `i4r_report_url`, `language`, `outcome_label`,
`paper.source`.  See `schema.py` for the full surface.  Two optional
fields support the contamination discussion and should be filled in at
promotion time: `publication_date` (first public version of the paper,
working paper or journal, whichever came first) and
`package_release_date` (first publication of the replication package),
each an ISO date — `YYYY`, `YYYY-MM`, or `YYYY-MM-DD`.  Worked examples
covering Python, R, and an out-of-scope Stata entry live under
`tests/fixtures/benchmark_placeholders/` — they're test fixtures, not
catalog entries, so the real `papers/` directory stays uncluttered.

## Caveats

- The catalog is hand-curated.  We do NOT scrape I4R — entries are
  added by hand from the published reports.
- Many I4R papers are out of Retally's domain (Stata, R, restricted
  data).  The catalog is honest about which ones we can't run; the
  aggregate "Retally performance" metric uses the executed subset as
  its denominator, with the catalog-vs-executed gap surfaced
  separately in the report.
- "Agrees with I4R" uses the same tolerance as the comparator's
  paper-claim check for that claim and mode — the per-type relative
  tolerance, or in independent mode the ±k·SE band when that is
  wider.  Easy to tighten later if the data shows we systematically
  under/over-match.
- Independent mode now removes the analysis scripts (`.do`, `.ado`,
  `.R`, `.Rmd`, `.py`, `.ipynb`, `.sas`, `.sps`, `.m`) and Stata
  transcripts (`.log`, `.smcl`) from the directory the pipeline lists
  and mounts — a `<name>.script-free` sibling of the downloaded package.
  Other files that can carry the answers — `.tex` / `.csv` result tables
  the package ships, the README — stay, as do the claimed values in the
  prompt: independent means independent of the authors' *code*, not
  blind to the answer.  Review independent-mode code before trusting a
  surprising pass.
