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
├── strip_rule.py           what a script-free copy withholds (by name and content)
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

## Reproduction modes: seeded, independent, blind

Every result row records the `mode` it ran in, and rows are identified by
`(entry_id, mode)` everywhere (results.json, the result cache, the report,
`benchmark.compare`):

| Mode | The generator sees | A pass measures | Tolerance |
|---|---|---|---|
| `seeded` (default) | paper text, claims, dataset listing, **and the authors' replication-package scripts** (plus any linked repo), presented as ground truth | *computational* reproduction — can the model translate the authors' Stata/R into fixest and run it | strict: per-type relative tolerance (COEFFICIENT 2 %, SE 5 %, …); never narrower than the printed precision (below) |
| `independent` | paper text, claims, and a **script-free copy** of the dataset only — scripts withheld from the prompt *and* removed from the directory that is listed and mounted, linked code not fetched, and the prompt forbids opening any script files | *independent* reproduction — can the model regenerate the analysis from the paper's description | SE-aware: within ±k·SE of the reported value when the claim pins a `standard_error` (k = 1, never narrower than the relative tolerance); relative tolerance otherwise; never narrower than the printed precision (below) |
| `blind` | everything `independent` withholds, **and every target**: each claim is listed by its token, type, unit label, location and context, but never its value, standard error or sample size; the methodology summary is asked to leave reported results out; the claim-targeted refinement loop is off (crash / no-RESULT repairs still run), so no "reproduced X, claimed Y" feedback is ever built | *derivation* — can the model compute the paper's numbers without ever being shown them | same as `independent` (the same policy object) |

In seeded and independent mode the model sees each pinned claim's value
(and the claim-refinement loop tells it which claims are off and by how
much), so independent means independent of the authors' *code*, not of
the answers.  **Blind pass counts are the only ones free of
target-guided search.**  Scoring is unchanged: the harness compares the
blind run's `RESULT:` lines with the catalog values under the
independent tolerance, and records first scored like every row.  It
equals the final count by construction — only crash repairs can run
after the first scored script — except when a script printed some
`RESULT:` lines and then crashed, so a repair produced the final one.  Curated claim `context`
strings are rendered verbatim, so no claim's context, location or unit
may state the value of any pinned claim of its entry (`papers/README.md`);
`tests/test_catalog_contexts.py` enforces that for every catalog entry.  Dataset mounting is the independent one (the
script-free copy), which also withholds the regression tables the
package ships (see [The script-free copy](#the-script-free-copy)); the
blind prompt still tells the model not to read result tables, logs or
output files, for anything the content test keeps.

### The script-free copy

In `independent` and `blind` mode the dataset directory the pipeline
lists and the sandbox mounts is a `<name>.script-free` sibling of the
downloaded package (`benchmark/strip_rule.py`, applied by
`script_free_copy` / `script_free_dataset`).  It leaves out:

- **By name:** `.do .ado .R .Rmd .py .ipynb .sas .sps .m` scripts,
  `.log .smcl .Rout` transcripts, `.Rhistory` and `log_*.txt` consoles.
- **By content**, for every other text file up to 50 MB (the first
  64 KB is read; 2 MB for `.tex`/`.html`), whatever its extension:
  Stata logs (`log type:` header, `Stata/MP` banner, `. reg`-style
  echoes, estimation output) and SMCL markup; R transcripts (`> lm(`
  prompts, `Call:` + `Coefficients:`, `Signif. codes`) and Python/
  statsmodels output; analysis *code* saved under another name (a
  do-file as `.txt` — Leeson 2022 ships three — or R/Python source in a
  `.md`): most non-comment lines are commands; regression tables —
  `.tex` (esttab fragments, stargazer, any tabular with `Observations` /
  R² / standard-error rows), `.html`, plain-text esttab/outreg2 output,
  `.csv` only with `Observations`/`R-squared` row labels plus `(1)`/
  coefficient/`(se)` columns, `.xlsx` whose strings read the same way.
- **Byte copies** of a file stripped by name.

Evidence must be strong (several independent markers) or the file
stays.  Data formats (`.dta .RData .rds .sav .parquet`, shapefiles, …)
are never stripped and never content-tested, binary files are not
content-tested, a plain `.csv` (figure data included) is kept, and a
`.tex` manuscript (`\documentclass`) stays unless one of its own
tabulars is a regression table.  Directory names (`output/`, `tables/`)
play no part.  Summary-statistics tables without regression markers
stay.

Every copy writes a manifest **beside** it, never inside the mounted
tree: `<name>.script-free.retally-stripped.json`, listing each withheld
path with its reason (`script-suffix`, `transcript-name`, `stata-log`,
`smcl`, `r-transcript`, `python-output`, `script-content:stata|r|python`,
`regression-table`, `duplicate-of-script`).  The benchmark row records
the count as `n_files_stripped` (None in seeded mode).  No prompt names
the withheld files.

Seeded and independent are both worth having; **the gap between them is the headline number** —
how much of a seeded pass survives without the authors' code.  A
both-mode report leads with a *Seeded vs independent* section listing,
per paper, the claims lost without the scripts; when the run also has
blind rows (`--mode all`) the table gains a Blind column (pass count and
first scored).

The SE band only bites when the pinned claim carries `standard_error` in
the catalog YAML, so pin SEs alongside coefficients.  The independent
band is deliberately looser than the seeded one: compare the two modes'
*pass sets*, and read the closeness bands (which use each claim's own
effective tolerance) with that in mind.

### Printed-precision floor (every mode)

Published tables round.  A coefficient printed as `-0.0006` is
consistent with any true value in [-0.00065, -0.00055], ±8 % of the
printed value, so a perfect reproduction could fail a 2 % relative band.
On top of whichever band the mode gives (per-type relative, or ±k·SE),
the comparator therefore never accepts an absolute band narrower than
half a unit in the pinned value's last printed place:

    effective band = max(tolerance × |claimed|, 0.5 × 10^-decimals)

The rule is the same in seeded, independent and blind mode and does not
depend on the model: a reproduction that rounds to the printed value
always passes.  It only ever widens a band.  `decimals` is inferred from
how `value` is written in the catalog YAML (`-0.0006` → 4, `3.710` → 3,
`660` → 0, `1.5e-3` → 4) unless the curator sets it (see
`papers/README.md`); written integers are exact (±0.5) unless `decimals`
is negative.  Each claim detail records which bound was binding in
`tolerance_source` (`relative`, `se_band` or `printed_precision`);
`tolerance` stays a relative number (`band / |claimed|`), except for a
claim of exactly 0, where the floor's absolute band is recorded as is.
Rows from files written before the floor carry no `tolerance_source`.

Committed results can be re-scored under the current rule without
re-running anything, since each claim detail stores `claimed` and
`reproduced`:

```bash
uv run python -m benchmark.rescore benchmark/results/<file>.json [--catalog DIR] [--write OUT.json]
```

It prints per-row before/after pass counts and every flipped claim;
the input file is never modified (`--write` writes a re-scored copy;
first-attempt / first-scored fields are left as recorded).  Introduced
2026-10-21: re-scoring `phase18-dincecco-both`, `phase3-alesina-both`,
`phase3b-bisbee-both` and `phase19-bisbee-independent` flipped no claim
(the floor binds on two Bisbee seeded interaction coefficients, printed
as `-0.016` and `-0.020`, without changing their verdicts).

### First-attempt vs final pass

The pipeline refines in two phases.  *Error refinements* repair a script
that crashed or printed no `RESULT:` lines: the model gets the stderr and
nothing about the targets.  *Claim refinements* follow once the script
runs: the model is told which claims are off target ("reproduced X,
claimed Y") and asked to fix the script, up to `max_claim_refinements`
times.  Only the second phase is target-guided search, so the final pass
count mixes "derived the specification from the paper" with "searched
until the number matched".

Each row therefore also records the **first-scored** pass count
(`n_claims_with_paper_match_first_scored`, and `passed_first_scored` per
claim): the first execution whose stdout has at least one parsable
`RESULT:` line (the final scorer's parser, so an all-`NA` output does not
count; the first execution when none has one), scored by the same
comparator, mode and tolerance.  It sits after any crash repairs and
before any claim-targeted feedback: the "before target feedback" number.
`first_scored_attempt_index` is its 0-based position among the
executions.  The split of refinements is recorded as
`n_error_refinements` and `n_claim_refinements` (`n_refinements` is their
sum); `n_executions` counts sandbox runs.

The raw **first-attempt** count (`n_claims_with_paper_match_first_attempt`,
`passed_first_attempt`) is kept: the very first execution, crash or not.
It conflates the two phases: on bisbee-2022 every run scored 0/11 on
first attempt because the first script crashed, and the final 7–8/11 came
after error repairs *and* claim refinements.

The report, `benchmark.compare` and `benchmark.artifacts` headline first
scored, e.g. `8 / 6 of 11 (first scored 3/11, 2 error + 3 claim
refinements)`; the seeded-vs-independent table compares the modes'
first-scored counts.  `benchmark.artifacts` also prints the raw
first-attempt count per row and claim.  Rows written before first-scored
scoring fall back to the first-attempt count (labelled as such);
reproducers that do not report their attempts (`Reproduction.attempt_outputs`
unset), and rows from older results files, have neither, and the reports
omit them.

To get first-scored numbers for a results file written before this
existed, rescore it from its run artifacts:

```bash
uv run python -m benchmark.artifacts benchmark/results/results.json --rescore
```

For each row whose `artifacts_dir` is on disk it orders the executions
`attempt-1`, `attempt-2`, …, then the final `stdout.txt`.  It assumes the
final run was last, except when the last attempt has no `feedback.txt`:
that is a broken claim refinement the pipeline reverted, so the final run
is placed just before it (marked † in the table).  It classifies each
attempt's `feedback.txt` as
error or claim feedback, re-scores with the catalog's pinned claims and
the row's mode tolerance, and prints entry, mode, data file(s), final,
first attempt, first scored and the error / claim refinement counts
(lower bounds: an unchanged-code refinement leaves no attempt directory).
It reads the results file and never writes it.

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
| `no_api_key` | `ANTHROPIC_API_KEY` not in env (the reproducer factory raised `MissingAPIKeyError`) |
| `reproducer_init_failed` | The reproducer factory raised anything else (e.g. Docker not running, sandbox image not built); the message is in `error` |
| `reproduction_missing` | The reproducer scores work done elsewhere and this (entry, mode) cell has not been done: `reproduce` raised `ReproductionMissingError` (e.g. `--reproducer claude-code` with no `benchmark/reproductions/<entry>/<mode>/<run_id>/reproduction.json`); where it looked is in `error` |

Skips are never written to the result cache.  Neither are **transient
errors**: a reproducer that raises because of a download / network / HTTP
failure, or an Anthropic API problem with the account or the service, gets
a row with `retally_ran = false`, the message in `error`,
`"transient": true` and an `error_kind`, and the runner logs `Not caching
<id> (<mode>): transient <kind> error: ...` instead of saving it, so the
next run retries the paper rather than replaying the failure.  The
classification (`_transient_error_kind` in `runner.py`) is narrow; the
exception or anything on its cause chain must be one of:

| `error_kind` | Matches |
|---|---|
| `network` | a `requests` exception (including wrapped HTTP 4xx/5xx), a `urllib3` / `http.client` error, a builtin `ConnectionError` / `TimeoutError`, or the downloader's `RuntimeError("Failed to download dataset ...")` |
| `api_billing` | `anthropic.BadRequestError` whose message mentions "credit balance" or "Plans & Billing", or any exception whose text contains "credit balance is too low" |
| `api_unavailable` | `anthropic.RateLimitError` (429), `APIConnectionError` / `APITimeoutError`, `InternalServerError` or any `APIStatusError` with status >= 500 |
| `api_auth` | `anthropic.AuthenticationError` (401) / `PermissionDeniedError` (403) |

Every other outcome — an ordinary 400 for a malformed request, a parse
failure, a generated script that crashed inside the sandbox — gets
`error_kind = "pipeline"` and is cached as before.  When any row was
transient the CLI ends with `WARNING: N row(s) failed on transient errors
(<kinds>) and were not cached; re-run after fixing the cause.` and
REPORT.md's headline carries the same warning, so a credit-exhausted run
cannot be mistaken for a measurement.

## Running it

```bash
export ANTHROPIC_API_KEY="sk-ant-..."   # or skip; the runner will record NO_API_KEY skips
make benchmark                                    # seeded mode (the default)
uv run python -m benchmark.runner --mode independent
uv run python -m benchmark.runner --mode both     # seeded + independent, one row per entry per mode
uv run python -m benchmark.runner --mode blind    # targets withheld, no claim-targeted refinement
uv run python -m benchmark.runner --mode all      # seeded + independent + blind
uv run python -m benchmark.runner --only dincecco-2022-india-warfare --mode both
```

`--mode {seeded,independent,blind,both,all}` (`both` is seeded and
independent, as before blind existed; `all` adds blind), `--only ENTRY_ID` (repeatable), and
`--reproducer NAME` (default `pipeline`; see below) combine.  For each
catalog entry and mode the runner emits one row in `results.json`,
carrying `"mode"` and `"reproducer"` fields (rows from files that
predate them are read as `seeded` / `pipeline`).
The renderer then produces a Markdown table and a self-contained HTML
page from that JSON.  The report file is committed; `results.json` is
not (it's a rebuildable artefact).

**Spend.**  `results.json` is `{"usage": {...}, "results": [...]}`
(older files are a bare list of rows; `benchmark.metrics.result_rows`
reads both).  Each row's `usage` holds the Claude API tokens its run
spent, by model (`input_tokens`, `output_tokens`,
`cache_creation_input_tokens`, `cache_read_input_tokens`, `api_calls`),
the number of calls the LLM cache answered for free (`llm_cache_hits`,
`llm_cache_served`), and `estimated_usd`; the top-level `usage` totals
the rows that were actually re-run (result-cache rows are excluded).
Prices live in one table, `benchmark/pricing.py`.  REPORT.md shows an
"Estimated API cost" section per paper per mode with the run total.

Re-running with no catalog or pipeline changes hits the cache and
finishes in seconds.  The result cache (`benchmark/.cache/<hash>.json`)
is keyed on the catalog entry, the retally version, **the mode**, and —
for anything other than the default pipeline — the reproducer, so a
seeded result is never served for an independent run nor one agent's
result for another's (independent- and blind-mode keys also carry the script-free
dataset contract, so results from before it are not reused); `split`,
`publication_date`, and `package_release_date` are excluded from the key
because they never reach the pipeline.  Skips and transient download/network
errors are not cached (see "Skip categories" above).  The LLM cache keys on full
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

## Run artifacts: what the model actually wrote

`results.json` keeps verdicts and per-claim numbers, not the code that
produced them.  Every executed row's artifacts are written to

```
benchmark/results/artifacts/<entry_id>/<mode>/<reproducer>/<run_id>/
  script.R | script.py        # the final generated script
  stdout.txt  stderr.txt      # its sandbox output
  attempt-<n>/                # each superseded refinement attempt, oldest first:
    script.*  stdout.txt  stderr.txt  feedback.txt   # feedback = what was sent back to the model
  prompt-<n>.txt              # every code-generation/refinement prompt, in order
```

`run_id` is the run's UTC start time (`20261020T183012Z`), so cache-off
variance runs (`RETALLY_LLM_CACHE=0`) never overwrite each other.  The
row's `artifacts_dir` points at the directory (repo-relative); a row
served from the result cache keeps the directory of the run that
produced it.  The runner prints where artifacts went at the end of a run.
Any reproducer can contribute files by filling `Reproduction.artifacts`
(relative path → text).

```bash
uv run python -m benchmark.artifacts benchmark/results/results.json \
    [--entry ID] [--mode seeded|independent|blind]
```

prints, per row: the artifacts directory, the data files the final
script reads (a grep for `read_dta`/`read.csv`/`readRDS`/`pd.read_*`/…
calls and `.dta`/`.csv`/`.rds` literals), the `RESULT:` lines of its
stdout, and each claim's pass/fail.  That is usually enough to tell a
wrong-data-file failure from a wrong-specification one.

`benchmark/results/artifacts/` is gitignored: it is per-run, can be
large, and may contain excerpts of the replication data.

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
cache miss.  A factory that raises `benchmark.reproducer.MissingAPIKeyError`
is recorded as a `no_api_key` skip; any other exception as a
`reproducer_init_failed` skip with the message in `error`.  Built in:
`pipeline` (the default) and `claude-code` (below).  An adapter that drives
a general-purpose agent itself (e.g. on the Claude Agent SDK) is planned in
`ROADMAP.md` Phase 2, not built.

### Claude Code as a reproducer

`--reproducer claude-code` scores reproductions a Claude Code session did
by hand, from the files it wrote.  The harness never drives the session
and never calls the API; it renders the task, and later reads the result
(`benchmark/reproducers/`).  Three steps per cell (entry, mode, run id):

```bash
# 1. Render the task: task.md, paper.txt and the mode's data mount.
uv run python -m benchmark.reproducers.render_task \
    --entry montero-2022-cooperative-property-rights --mode blind --run-id 2026-10-22-a
#    prints: the task file, the mount path, the output directory

# 2. In a Claude Code session: "Do the task in <task file>."  The agent writes
#    scripts, runs them in the R sandbox and records everything under the
#    output directory, reproduction.json last.

# 3. Score it like any reproducer (--no-cache when re-scoring a cell with a new run id).
uv run python -m benchmark.runner --reproducer claude-code --mode blind \
    --only montero-2022-cooperative-property-rights --no-cache
uv run python -m benchmark.report benchmark/results/pipeline.json benchmark/results/results.json
```

`render_task` gets the package from the pipeline's download cache
(`.cache/datasets/`, or `--package-dir`) and the paper text from
`paper.source` (cached in `benchmark/.cache/claude-code/papers/`, or
`--paper-text`).  The task directory,
`benchmark/.cache/claude-code/<entry>/<mode>/<run_id>/`, holds `task.md`,
`paper.txt`, `render.json` and `mount/<package>/` — the full package in
seeded mode, the script-free copy in independent and blind mode, whose
strip manifest is moved *outside* the task directory
(`<run_id>.retally-stripped.json` beside it), so nothing the agent is
pointed at names a withheld file.  The claims, dataset listing, output
convention, code requirements, package scripts and independent / blind
blocks in `task.md` are the pipeline generator's own rendering, so the
agent sees what the pipeline's prompt shows.  In blind mode every pinned
claim value and standard error is redacted from `paper.txt` (`[withheld]`;
the count is `paper_redactions` in `render.json`).

The session writes to `benchmark/reproductions/<entry>/<mode>/<run_id>/`
(gitignored; `RETALLY_REPRODUCTIONS_DIR` overrides the root):

```
render.json  task.md                # from render_task
script.R  stdout.txt  stderr.txt    # the final run: its RESULT: lines are scored
attempt-<n>/                        # every earlier execution, in order
  script.R  stdout.txt  stderr.txt  feedback.txt   # feedback when kind is "error" or "claim"
reproduction.json                   # the manifest (schema in benchmark/reproducers/filesystem.py)
```

`FilesystemReproducer` picks the run named by `RETALLY_REPRODUCTION_RUN_ID`,
else the newest one with a `reproduction.json` (directories with only
`render.json` were rendered but not run).  The numbers come from the files,
never from the manifest: `outputs` are the final `stdout.txt`'s `RESULT:`
lines, the first-attempt / first-scored counts come from the attempts'
`stdout.txt`, and the manifest's `kind` per attempt gives the
error / claim refinement counts.  A malformed manifest, a missing file, an
unknown kind, a blind run with a `claim` attempt, or an entry / mode / run
id that does not match the directory fails the row (`retally_ran = false`,
the file named in `error`); a cell with no finished run is a
`reproduction_missing` skip.  The whole run directory is copied to
`benchmark/results/artifacts/<entry>/<mode>/claude-code/<run_id>/`.

Mode rules the task states (the pipeline's, as far as they translate):
every mode — R only, run only in the `retally-sandbox-r` container with the
pipeline executor's flags (`--network none`, read-only, the mount at its own
path, the executor's memory / CPU / timeout), use only the mount and
`paper.txt`.  Seeded — the authors' scripts may be followed.  Independent
(and seeded) — the agent may compare its values with the claims, but each
time it then changes the script it records a `kind: "claim"` attempt whose
`feedback.txt` is the pipeline's own claim-gap text, produced by
`python -m benchmark.reproducers.check_attempt`; at most 3 claim and 3
error refinements, the pipeline's budgets.  Blind — the pipeline's blind
block; never look up the reported values in the paper or tune toward them;
no `claim` attempts (the check prints only the names of missing quantities);
at most 3 error repairs.

**Isolation caveat.**  An agent with a shell is isolated only by what is on
disk and by instruction.  The task directory contains only the mode's mount,
and the sandbox mounts nothing else, but the session itself runs in a full
checkout: the catalog YAMLs (with the pinned values), the download cache
(with the authors' scripts) and earlier results are all readable.  The rules
"use only the mount and `paper.txt`" and "list anything else you read in
`files_read_outside_mount`" are enforced by instruction and by inspecting
that list and the session transcript, not by the filesystem.  Treat a
`claude-code` row as trustworthy only after that inspection.

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

### What the downloader does to a replication package

`src/retally/dataset/downloader.py` fetches the package into
`.cache/datasets/<slug>/` before anything is mounted, and normalises two
repository quirks so the files match the names the authors' scripts use:

- **Harvard Dataverse originals.**  Dataverse ingests tabular uploads
  (`.csv`, `.dta`, `.sav`, ...) and serves them as `.tab` by default.  When a
  file's metadata lists an `originalFileFormat` / `originalFileName`, the
  downloader requests `?format=original` and saves it as the file's label
  stem plus the original extension (`usclimate_exp1.tab` ->
  `usclimate_exp1.csv`, even though Dataverse records the upload as
  `usclimate_exp1-1.csv`).  If the original request fails it falls back to
  the `.tab` and logs a warning.  Non-ingested files (`.tgz`, `.R`, `.dat`)
  are fetched as-is.  Files are downloaded in name order.
- **Nested archives.**  A downloaded `.zip` / `.tar` / `.tar.gz` / `.tgz` is
  extracted and deleted; archives inside it are extracted too (up to two
  levels down), each into a directory named after the inner archive
  (`3 replication package/replicate.zip` -> `3 replication package/replicate/`)
  and then deleted.  An archive with a member that would land outside its
  destination (zip-slip, escaping tar links) is refused and left in place, as
  is one that would push the tree past a 20 GiB uncompressed-size cap.

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
- Independent mode removes the analysis scripts, their logs and
  transcripts (by name and by content) and the generated regression
  tables from the directory the pipeline lists and mounts — see [The
  script-free copy](#the-script-free-copy).  What the content test keeps
  — summary-statistics tables, figure-data `.csv`, the README, a log too
  weak in markers to call — stays, as do the claimed values in the
  prompt: independent means independent of the authors' *code*, not
  blind to the answer (blind mode withholds the values; the blind prompt
  forbids reading whatever result files remain).  Review independent-
  and blind-mode code before trusting a surprising pass.
- Blind mode still shows the paper's abstract (its first 500 characters)
  and the LLM-written methodology summary; the summariser is told to
  leave results out, but an abstract that states a headline estimate
  reaches the prompt as written.
