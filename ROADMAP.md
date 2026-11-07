# Roadmap

## North star

This project's credible destination is a **research artifact**, not a
validation product: a rigorous public benchmark and a measured answer to
the question *"can LLM agents replicate published econometrics — and how
much of what looks like replication is really translating the authors'
code?"*

There are two different measurements hiding in that question, and the
pipeline can now make both of them on the same papers:

- **Seeded (computational) reproduction.** The authors' own
  `.do`/`.R`/`.Rmd` scripts from the replication package are in the
  generation prompt, presented as ground truth. A pass means "the model
  translated the authors' Stata/R into fixest and ran it". Useful, and a
  necessary sanity check on the harness, but it is close to what re-running
  the package already does.
- **Independent reproduction.** The scripts are withheld. The generator
  works from the paper text (title, abstract, methodology summary), the
  pinned claims, and the dataset directory listing only. A pass means "the
  model regenerated the analysis from the paper's description" — the thing
  a human replicator does when they rebuild a result from the methods
  section.

Concretely, the end state is:

- a curated catalog of **20–30 papers** drawn from the I4R replication
  corpus, each with pinned headline claims (with standard errors),
  transcribed human-replicator ground truth, and recorded publication and
  replication-package release dates;
- a frozen harness run over that catalog **in both modes**, producing the
  **three-way verdict matrix** (`retally_ran` / `agrees_with_paper` /
  `agrees_with_i4r`) per mode, per-stage success rates, closeness
  distributions, a failure taxonomy, and — the headline — the
  **seeded-vs-independent gap**: which claims survive when the authors'
  code is taken away;
- a **technical report** presenting those numbers honestly, positioned
  alongside I4R's own AI replication-games work.

**The signal no one else is producing** is the gap, scored against two
yardsticks: per paper, how many headline claims a model reproduces with the
authors' code versus from the text alone, and — for each — whether it
agrees with the paper's stated value, with the human replicators' value,
or with neither. `independent ✓ / agrees_with_paper ✓ / agrees_with_i4r ✗`
(the text alone leads to the paper's number, which careful humans could not
reproduce) and `seeded ✓ / independent ✗` (the paper's description is not
enough to recover its own specification) are both findings about the
literature, not just about the model.

**What the earlier framing got wrong.** This roadmap used to say the
pipeline performs independent reproduction. Phase 1.1 then fed the
authors' package scripts into the prompt and told the model to prefer them
over the paper — so the first green result (Dincecco 13/13, Phase 1.3) is a
*seeded* result, with the authors' 185 KB master do-file in the prompt. It
proves the harness works end to end; it says nothing yet about independent
reproduction. The mode switch (Phase 1.4) makes the distinction explicit
and recorded on every result, so the two can never again be conflated.

**Contamination, honestly.** Every paper in the I4R corpus
(`benchmark/corpus/i4r_first_meta_database.csv.gz`) was published in 2022
or 2023 — there are no 2024–25 replication games in it — and current model
training cutoffs extend into 2026. A clean post-cutoff sample barely
exists, and it shrinks with every model release. So the honest framing is:

- **every result is pre-cutoff**, in both modes, and the report says so up
  front rather than offering a pre/post split it cannot populate;
- **publication and package-release dates are recorded per entry**
  (`publication_date`, `package_release_date` in the catalog schema) so a
  reader can judge exposure paper by paper, and so a post-cutoff sub-sample
  can be added if one ever becomes available;
- **the seeded-vs-independent gap is the primary finding, not a
  contamination control.** Memorisation of a paper, its package, or its
  I4R report could help either mode; the gap measures what the authors'
  code contributes *given* whatever the model already knows.

A second honesty note: both modes see the claimed values (they are the
targets in the prompt, and the claim-refinement loop chases them). "Independent"
means independent of the authors' *code*, not blind to the *answer*; any
methodology change made to close a gap is surfaced as a `DEVIATION:` line.
A target-blind variant (claims named but values withheld, no claim
refinement) is built as `--mode blind` (Phase 3.1) and was measured on
the seven evaluation papers in Phase 3.2: it is the honest headline.

Everything below is ordered by a single rule: **the next PR moves the
reproduction number, not the machinery.** Current state (2026-10-21):
**ten curated papers** — three dev papers measured in seeded and
independent mode (Opus 4.7, Docker R sandbox; one seeded run and, for
independent, one cached plus three cache-off runs per paper), and seven
holdout evaluation papers measured once each in all three modes with
pipeline tuning frozen (Phase 3.2).

- **Evaluation pass, 7 papers × 3 modes (Phase 3.2): seeded 55 / 79,
  independent 41 / 79, blind 24 / 79 claims.**  Blind — claim values
  withheld, no claim refinement — is the only count free of
  target-guided search, so **24 / 79 is the honest headline**; the
  17-claim drop from independent to blind is what seeing the targets
  (and chasing them) was worth on these papers.  One run per cell:
  counts, not rates.
- **Montero 2022 is the first case of target-guided refinement
  reproducing a wrong published number.**  The paper's Table 5 earnings
  results were withdrawn after I4R found duplicated rows.  Seeded, the
  first script matched neither the paper nor the replicators (0 / 10);
  one claim-refinement round, told the gaps to the printed values,
  reproduced the paper's numbers exactly (10 / 10) — numbers the human
  replicators showed to be wrong.  Blind, following the paper's stated
  five-member rule, reproduced neither (0 / 10).  `agrees_with_i4r` is
  false in all three modes.
- **Seeded is not a ceiling.**  Grier (0 / 11 seeded: conditional logit
  instead of the paper's fixed-effect logit, estimates ~1/7 of the
  printed values) and Arias (4 / 12: AMCEs re-estimated with `feols`
  instead of `cjoint::amce`) failed with the authors' code in the prompt,
  so their seeded-vs-independent gap is undefined.

- **Dincecco 2022 is closed.**  Seeded 13 / 13; independent 13 / 13 in
  all three cache-off runs, each exact on its *first* script with no
  refinement (Phase 1.8, after generic Stata-label matching in the `.dta`
  listing).  The road there: independent 0 / 13 in Phase 1.5, 1–12 in
  1.6, 13 / 13 in 4 of 7 runs in 1.7.
- **Alesina 2022 is the first specification-level gap.**  Seeded 7 / 11;
  independent 7 / 11 cached and 0, 6, 5 of 11 cache-off (first scored 1
  cached; 0, 5, 1 cache-off).  Both modes read the right file; the
  independent losses are reconstructions of the specification (outcome
  composition, sample trimming, index direction), plus one run that
  printed results under its own names (Phase 3, below).
- **Bisbee 2022: seeded 10 / 11; independent 5 / 11 cached and 7, 8, 8
  cache-off** after the `.RData` contents were listed (Phase 1.9), with
  first scored equal to final in every independent run (first scored 9
  seeded).  No first script crashes any more, and claim refinement adds
  nothing.  The two March-sample coefficients and the March N fail in
  every independent run for a paper-vs-code reason: the paper describes
  the sample as March 1 – April 7, the package uses every election from
  March 1 on (Phase 3, below).

Read against the thesis: Dincecco's independent failures were all
package navigation (wrong file, then wrong column), now fixed
generically, so its 13 / 13 says the paper's text is enough to recover
its specification; Alesina's are the specification gap the thesis is
about.  The first-scored metric (Phase 1.8) separates derivation from
target-guided search, and Bisbee showed why it matters: 0–4 of 11 first
scored against 7–8 final in the Phase 3 new-image independent runs,
because every first script crashed on guessed `.RData` variable names.
With the objects and columns listed (Phase 1.9) first scored is 5–8 and
equals final, so Bisbee's independent numbers are now derivation.

The committed `REPORT.md` is built from one row per paper and mode
(listed under Phase 3.2, below): 27 rows over ten papers.  Spend
recorded for Phases 1.8, 1.9 and 3: about $21.10; the evaluation pass
(3.2) $8.11; running total recorded for the day about $32.

---

## Phase 0 — Stop the bleeding (small, immediate, no API cost)

### 0.1 Remove the author leaderboard — ✅ done

`LEADERBOARD.md` ranks real, named authors by "reproducibility pass rate"
computed from synthetic demo runs against UCI dataset donation citations —
not real papers. At the pipeline's current precision, a failed claim means
the *tool* failed, not the author. Publicly attaching pass/fail verdicts to
named people is the least defensible artifact in the repo.

- ~~Delete `LEADERBOARD.md`, `scripts/generate_leaderboard.py`, the
  `make leaderboard` target, and the README links to them.~~ Done, plus
  `tests/test_leaderboard.py`, `docs/data/leaderboard.json`, the
  `check-leaderboard-fresh` gate, and the CI freshness step.
- ~~Relabel `docs/index.html` + `docs/data/reports.json` explicitly as
  **demo output of the pipeline on synthetic inputs**.~~ Done — the
  dashboard header and README now say demo/smoke-test explicitly.
  Deleting them outright remains an option once the benchmark dashboard
  replaces them.
- Decision to make later, not now: if an author-facing artifact ever
  returns, it requires far higher precision than exists today and should be
  paper-level, not person-level.

### 0.2 Rename to Retally — ✅ done (2026-10)

The old name, "OpenRA", collided with the widely known open-source RTS
engine (openra.net), and its expansion ("Open Source Research Assistant")
described assistance rather than replication. "Retally" — re-tally the
numbers — carries the project's actual job. The code-side rename covered:

- `src/retally/` package path, `pyproject.toml` name, all imports;
- Docker image tags `retally-sandbox` / `retally-sandbox-r`, the
  `retally.run=` container label, `RETALLY_LLM_CACHE` env var,
  `.retally-clone-complete` sentinel;
- README/docs/Makefile text, the GitHub repo name (GitHub redirects old
  URLs automatically).
- Keep a shim-free clean break — the project has no external users yet;
  this gets strictly more expensive with every week of visibility.
- Still manual (repository-settings writes are blocked from cloud
  sessions): the GitHub repo rename to ``retally`` and the repository
  description, both under Settings on github.com.

**Exit criteria:** leaderboard gone from `main`; rename checklist exists
(this section) and executes within a day of a name decision.

---

## Phase 1 — First nonzero reproduction (Dincecco 2022), in both modes

Goal: drive `dincecco-2022-india-warfare` from 0 matched claims to a
majority of *headline* claims matched with the authors' scripts in the
prompt (seeded — done), then measure how much of that survives without
them (independent — next). No new general infrastructure until this lands.

### 1.1 Seed the replication package's own scripts into codegen — ✅ built (now "seeded mode")
*(implemented 2026-07; verified live under 1.3.  Since 1.4 this is the
`seeded` reproduction mode — the default — and is withheld entirely in
`independent` mode.)*

The Zenodo package the pipeline already downloads contains the authors'
own `.do`/`.R` scripts — the ground truth of the estimating equation.
Feeding them into the prompt turns the task into *computational*
reproduction: translate the specification, do not transliterate the
syntax.

- Selection walks `dataset.local_path` when the dataset is a replication
  package (contains `.do`/`.R`/`.Rmd` files), language-aware scoring
  prefers `master.do`, `main*.R`, `*tables*`, `*analysis*`; oversized
  scripts are truncated with a marker rather than dropped.
- Rendered as an "Original Replication Scripts" prompt section, with
  Stata-to-fixest hints (e.g. the singleton `fixef.rm = "none"` note) that
  only appear alongside the scripts.
- Python/registry-dataset flow is byte-identical (zero churn to the demo
  path).

### 1.2 Pin curated headline claims — ✅ built
*(rubric in `benchmark/README.md`; Dincecco now carries 13 pinned claims —
Table 1 and the Table 2 Panel B IV estimates — with standard errors on the
coefficient claims and I4R findings.)*

- Curation rubric: a headline claim is (a) in the paper's abstract or main
  results table, (b) an estimate the paper's conclusions rest on, (c)
  numerically stated. Target 8–12 per paper.
- **Pin the SE with every coefficient** (`standard_error:` on the claim).
  It costs nothing in seeded mode and is what activates the independent
  mode's ±k·SE tolerance band.
- Populate `i4r_replicator_findings` from the I4R report / meta-database
  values, activating `agrees_with_i4r`.

### 1.3 Iterate to green, with discipline — ✅ done (2026-10-19) — *seeded baseline*
*(13/13 pinned claims within tolerance **in seeded mode**.  What this
proved: the harness works end to end — download, script selection,
generation, sandboxed R execution, comparison, I4R scoring — and a model
can translate a 185 KB Stata master do-file into a fixest specification
that hits every headline number.  What it did not prove: anything about
independent reproduction, since that do-file was in the prompt.  The fix
that mattered was that the do-file had been silently dropped by the
per-file script cap (truncating instead of skipping took the run from 0/5
to 5/5); a Stata-to-fixest singleton note then made N exact.  SE-aware
tolerance was not needed — consistent with seeded mode's strict policy.
`benchmark/results/baseline-2026-10-19.json` is the committed seeded
baseline.)*

- Loop: live run → `benchmark.compare` against the saved baseline → keep
  or revert. The LLM cache keeps each iteration cheap; pinned claims keep
  the yardstick frozen.

### 1.4 Make the reproduction mode an explicit, recorded switch — ✅ built (2026-10)

- `ReproductionMode` (`seeded` | `independent`) on
  `ValidationPipeline.validate(...)` and `CodeGenerator.generate(...)`,
  defaulting to `seeded` (byte-identical prompts — pinned by a golden-file
  test). `independent` skips package-script selection and the
  code-reference extraction/clone, refuses any authors' code passed to the
  generator, and tells the model not to open script files it sees in the
  dataset listing.
- The mode is recorded on every `ValidationReport`, every
  `results.json` row, and in the result-cache key; the LLM cache keys on
  full prompt content, so the two modes' generation calls never collide.
- `python -m benchmark.runner --mode {seeded,independent,both}`; the
  report presents modes side by side with a *Seeded vs independent*
  section; `benchmark.compare` keys rows by `(entry_id, mode)`.
- Per-mode tolerance: `seeded` is strict (per-type relative tolerance —
  computational reproduction should match closely); `independent` passes
  within ±k·SE of the reported value when an SE is pinned (k = 1,
  configurable; never narrower than the relative tolerance), falling back
  to the relative tolerance otherwise. This is the SE-aware comparison
  1.3 had deferred, keyed to the mode where it belongs.
- Catalog schema gains `publication_date` and `package_release_date`.

**Printed-precision floor (2026-10-21).**  Every mode now has a
tolerance floor at the pinned value's printed precision: the effective
absolute band is max(mode tolerance × |claimed|, half a unit in the last
printed decimal place), so a reproduction that rounds to the printed
value always passes, and no existing band is narrowed.  Printed decimals
are inferred from the YAML literal (`-0.0006` → 4) or set via a claim's
`decimals` (negative for rounded integers); each claim detail records
the binding bound (`relative` / `se_band` / `printed_precision`).  It
matters for papers that print coefficients to one significant digit
(grier-2023, leeson-2022); `python -m benchmark.rescore` re-scoring the
committed Dincecco, Alesina and Bisbee result files flipped no claim.

### 1.5 First independent run on Dincecco — ✅ done (2026-10-20) — gap 13 / 13
*(Seeded 13/13; independent 0/13 with the script-free mount (three runs:
0, 0, 0) and 0/13 with prompt-only withholding (three runs: 0, 0, 1, the
one pass a coincidental SE match).  Every loss has one cause: the model
loaded the wrong `.dta` and never found the outcome or instrument,
because `.dta` column names are not in the listing and the
claim-refinement prompt never shows stdout; per-claim notes, the
script-access check (clean), and a latent methodology-extraction error
are in the entry's `notes`; `benchmark/results/baseline-both-2026-10-19.json`.)*

*Exposure note (2026-10-21): this phase's independent mounts predate the
content-aware strip rule (PR #61) and still carried the package's generated
`.tex` result tables; see Phase 3.2.*

- `python -m benchmark.runner --only dincecco-2022-india-warfare --mode both`;
  commit `REPORT.md` showing both modes and the gap.
- For every claim lost without the scripts, write a one-line note in the
  entry's `notes`: what the paper's text did not say that the do-file did
  (sample restriction, fixed-effect set, clustering, variable
  construction, singleton handling, …). These notes are the first rows of
  the failure taxonomy and a direct finding about the paper's methods
  section.
- Read the independent-mode generated code for any attempt to open the
  package scripts at run time (they are still on disk — see Risks).
- Record Dincecco's `publication_date` and `package_release_date`.

### 1.6 Independent-mode plumbing fixes — ✅ measured (2026-10-20) — independent 1–12 / 13 across runs
*(Four fixes, one commit each: the comparator no longer scores a claim
with no RESULT line against another claim's value (independent "matched"
10 → 7 of 13, no verdict change); `.dta` column names in the dataset
listing; head/tail stdout/stderr in refinement prompts; the methodology
prompt no longer primes "standardised".  Seeded 13/13 after every step;
independent 0/13 after steps 1–3.  Step 2 fixed variable resolution
(right names) but the model chose `biclean.dta` (N=271) because
`conflictexposure.dta`'s 1288 columns are truncated before the outcome
and instrument.  Offline counterfactual after step 3 (step-3 script, file
swapped, no `scale()`): 3/13, and 7/13 (every OLS claim, to 3–4 dp) once
population density is added to columns 1–2, which the claim token
"bivariate" misleads the model into dropping.  After step 4 (commit
1d30611, the only pipeline change since step 3) independent is no longer
a flat zero but swings from 1 to 12 of 13 between samples.  Classification
in the entry's `notes`; `benchmark/results/phase16-step3-both-2026-10-20.json`
(steps 1–3), `baseline-both-2026-10-20.json` and
`variance-independent-postfix-run{1,2,3}-2026-10-20.json` (step 4).)*

Step 4 measured on `main` at 9b4bbb9:

| Result file | Mode | LLM cache | Passed |
|---|---|---|---|
| `baseline-both-2026-10-20.json` | seeded | on | 13 / 13 |
| `baseline-both-2026-10-20.json` | independent | on | 12 / 13 |
| `variance-independent-postfix-run1-2026-10-20.json` | independent | off | 4 / 13 |
| `variance-independent-postfix-run2-2026-10-20.json` | independent | off | 10 / 13 |
| `variance-independent-postfix-run3-2026-10-20.json` | independent | off | 1 / 13 |

- **Headline.** Independent moved from a flat 0/13 (step 3, and three
  earlier cache-off runs, all 0) to 1–12/13; the three cache-off runs give
  a median of 4/13 and a mean of 5/13.  Seeded matches every value exactly.
- **The 12/13 run finds the file by searching on the target N.**  One
  generation plus three refinements; it fails only
  `warfare_iv_se_full_controls` (6.7% off against the 5% cap).  The final
  script lists every `.dta` in the package recursively and keeps the one
  whose row count is closest to 660, the N given in the claims — so it
  reached `conflictexposure.dta` through the target, not the listing.
  Variable names came from the `.dta` column listing (data, not code; the
  script-free copy was checked: 58 files, no scripts or logs).  Close but
  not exact: N=664 vs 660 (the authors drop four island districts the
  paper does not mention), Table 1 col 1 3.723 vs 3.713, IV col 3 3.713
  vs 3.482 (inside only the ±1·SE band).
- **Cache-off failure modes (inferred from the numbers — these runs kept
  no script).**  Runs 1 and 2 (4/13, 10/13) both report 7.1688 (SE 0.5159)
  for Table 1 col 1 and get col 3 essentially exact (1.4646): consistent
  with omitting log population density from col 1, which the misnamed
  token `warfare_coefficient_bivariate` invites (the column does control
  for it, as the claim `context` says; the context reaches the prompt only
  from PR #40).  Run 2 also gets IV cols 2–3 essentially exact (4.6339,
  3.4823) and N=664; run 1 gets the IV half wrong, with sign flips.
  Run 3 (1/13) picked a wrong file (N=374) and misses everything else.
- **Consequence for measurement.**  With one pipeline state spanning
  1–12/13, a single run per change can no longer tell changes apart.  From
  here each step is measured with one seeded run plus three cache-off
  independent runs and compared as a distribution; cache-off runs now
  keep their generated scripts (PR #42), so classification need no longer
  be inferred.  Spend was not recorded (cost accounting landed in PR #41,
  after these runs); roughly 4–6 Opus 4.7 calls per independent run.

### 1.7 File-selection round — ✅ measured (2026-10-20) — independent 13 / 13 in 4 of 7 fresh runs after step 5
*(Three fixes, one commit each, after a first commit that rewrote the
curated claim contexts in paper language (see "Context leak" below):
(4) each claim's `location` and `context` are rendered under it in the
generation prompt; (5) the `.dta` listing gives row counts, puts columns
named in the paper text first (exact name, or a Stata label that is a
phrase of the text), and lists the most relevant `.dta` files first;
(6) NA claims go to claim refinement, and "no progress" counts NA lines
and is waived once on a data-file switch.  Each step was measured on the
rebased commit like 1.6 step 4: one `--mode both` run (LLM cache on) and
three `RETALLY_LLM_CACHE=0 --mode independent` runs, result-cache rows
deleted before every run, Opus 4.7, Docker R sandbox.  Files:
`benchmark/results/phase17-step{4,5,6}-both-2026-10-20.json` and
`phase17-step{4,5,6}-variance-independent-run{1,2,3}-2026-10-20.json`.)*

*Exposure note (2026-10-21): this phase's independent mounts predate the
content-aware strip rule (PR #61) and still carried the package's generated
`.tex` result tables; see Phase 3.2.*

| Pipeline state | Seeded (cache on) | Independent (cache on) | Independent, 3 cache-off runs |
|---|---|---|---|
| `main` 9b4bbb9 = 1.6 step 4 | 13 / 13 | 12 / 13 | 4, 10, 1 |
| step 4 (8bc07dd) contexts rendered, paper-language contexts | 13 / 13 | 0 / 13 | 0, 0, 13 |
| step 5 (09e6fe3) paper-vocabulary-ordered `.dta` listing | 13 / 13 | 13 / 13 | 2, 13, 2 |
| step 6 (dbbd696) NA claims to refinement | 13 / 13 | 13 / 13 \* | 13, 2, 13 |

\* Not an independent sample.  The step-6 cache-on run made **0 API
calls**: all 8 LLM calls (both modes) were served by the LLM cache,
because step 6 changes only refinement-loop behaviour and the step-5 run
needed no refinement, so its prompts were identical.  It is a replay of
the step-5 run.  The committed `REPORT.md` is generated from it.

- **Headline.**  Independent reaches 13 / 13 — every value to 3–4 dp —
  in 4 of the 7 fresh runs at steps 5–6, up from 1 of 4 at step 4 and a
  1–12 spread on `main`.  Seeded is 13 / 13 exact at every step, so no
  commit is reverted.  The distribution is bimodal: a run is either exact
  or wrong for one structural reason.  Classification is read from the
  saved scripts (`python -m benchmark.artifacts`, PR #42), not inferred.
- **Step 4: data-file selection.**  All three 0/13 runs (cache-on, run 1,
  run 2) loaded `bgdpak.dta` (N=93) and produced identical numbers (col 1
  = 12.4861, N=93); one or two refinement attempts did not switch files.
  Run 3 (13/13) loaded `conflictexposure.dta`.  With contexts rendered
  but the old listing, the model picks the wrong file deterministically
  most of the time.
- **Steps 5–6: variable selection, the population-density control.**  All
  three 2/13 runs (step 5 runs 1 and 3, step 6 run 2) read
  `conflictexposure.dta` with N=656–660 and used `Land_250_1757`,
  `lnlights_001`, `state_gadm`, the ten geography columns and
  `instrument` correctly, but for "log population density in 1990" chose
  `lnpop1990` (log population, not density), `pdgpd1990` (unlogged
  density) or a hand-built `log(pop1990/area)` instead of `lnpdgpd1990`.
  Every coefficient is then off in the same direction (col 1 ≈ 6.2–6.8 vs
  3.713); the two passes are N and one IV value inside the ±1·SE band.
  The package has ~90 `pop*`/`lnpop*` columns; the right one is
  distinguishable only by its Stata label, and after the context rewrite
  `lnpdgpd1990` falls past the listing cap (below).
- **The 13/13 runs** (step 4 run 3; step 5 cache-on and run 2; step 6
  runs 1 and 3) all use the right file, `lnpdgpd1990`, `instrument` and
  `feols(..., vcov="hetero")`; coefficients exact to 3–4 dp; N reported
  656–664 (inside the 1% tolerance); IV SEs 2.5–3.4% off (HC1 vs Stata's
  HC0), inside the 5% cap.
- **The 1.6 failure mode is gone.**  Population density omitted from
  column 1 because of the `bivariate` token did not recur in any step-4+
  run: once the context is rendered, every script includes the density
  control.  OLS and IV halves move together: every 13/13 run passes both,
  every failing run fails both for the same reason, and no run passes OLS
  while failing IV.
- **Spend** (cost accounting from PR #41): about $4.0 recorded across
  the 12 runs; a cache-off independent run costs $0.25–0.53 (3–6 Opus 4.7
  calls); a both-mode run with the cache on about $0.41 (the step-6 one
  $0).
- **Honest framing.**  n = 4 independent samples per step, one of them (step
  6 cache-on) a replay.  The step-to-step movement of the cache-off runs
  (median 0 → 2 → 13; mean 4.3 → 5.7 → 9.3) is suggestive, not
  significant.  The context-rewrite commit was not measured alone,
  because contexts are not rendered until step 4; its effect is folded
  into step 4.

**Next.**  Surface the population-density column: match Stata labels for
"population density" when ordering columns, and/or revisit the listing cap
so `lnpdgpd1990` is in view.  Then alesina-2022 and bisbee-2022 in both
modes (Phase 3).

*Context leak.  Rendering contexts (4) exposed that the curated contexts
had been written from the replication package: Dincecco's named
`Land_250_1757`, `lnpdgpd1990`, `instrument` and `ivreg2, r`; Alesina's
and Bisbee's (PR #36) named package variables (`tax_top1`, `immigfirst`,
`pcttw_sanders`, `treatBin`, ...), R/Stata calls (`lfe::felm`,
`WeightIt::weightit`, `reg, robust`) and code-only facts (Bisbee's
150-second attentive cutoff, classical SEs).  Independent mode is
independent of the authors' code, so these were leaks.  Decision: rewrite
every context in the paper's own words, checked against the paper text
(no `curation_source` field; the `warfare_coefficient_bivariate` token is
kept for run-to-run comparability, and its context quotes the paper's
"bivariate correlation after controlling for log population density").
The rewrite is the branch's first commit, so (4) is measured with clean
contexts; package-only facts moved to the entries' `notes`, which the
model never sees.  The rule for curators is now in
`benchmark/papers/README.md`.  Consequence for (5): the listing's hints
lose the leaked names; offline, with title and claim fields as hints
(no methodology summary), `conflictexposure.dta` still leads, with
`lnlights_001` (its label matches "ln(0.01+Luminosity)") and
`instrument` (the paper's "Khyber proximity instrument") in view, but
`Land_250_1757` and `lnpdgpd1990` fall past the listing cap.*

### 1.8 Label matching, first-scored metric, sandbox packages — ✅ measured (2026-10-21)
*(Five PRs.  The label fix closes Dincecco: independent 13 / 13 on the
first script in all three cache-off runs.  The first-scored metric and
the sandbox packages were built for Phase 3 and are measured there.
Dincecco measured on `main` 1101e88 (after #44, before #46–#49) like 1.7:
one `--mode both` run (LLM cache on) and three `RETALLY_LLM_CACHE=0
--mode independent` runs, result-cache rows deleted before every run,
Opus 4.7, Docker R sandbox.  Files:
`benchmark/results/phase18-dincecco-both-2026-10-20.json` and
`phase18-dincecco-variance-independent-run{1,2,3}-2026-10-20.json`.)*

*Exposure note (2026-10-21): this phase's independent mounts predate the
content-aware strip rule (PR #61) and still carried the package's generated
`.tex` result tables; see Phase 3.2.*

- **PR #44 — generic Stata-label matching in the `.dta` listing.**  A
  column is put in view when its Stata label matches the paper's
  vocabulary: `ln`/`log` treated as equivalent, all of a phrase's content
  words or an in-order run of three words; numbers only rank, never
  match; columns whose labels have the same words collapse into one
  family; every strong match is shown, up to 40.  Offline, with the
  claim fields as hints: `lnpdgpd1990`, `lnlights_001`, `Land_250_1757`,
  `instrument` and the ten geography controls are all in view for
  Dincecco (in 1.7 the first and third fell past the cap).  Nothing in it
  names a Dincecco variable.
- **PRs #45 and #47 — first-attempt and first-scored pass counts** on
  every row, with the error / claim refinement split, in `REPORT.md`,
  `benchmark.compare` and `benchmark.artifacts`, plus `--rescore` to
  recover them from run artifacts for older results files.  *First
  scored* is the first execution that printed a parsable `RESULT:` line:
  after crash repairs, before any claim-targeted (target-guided)
  feedback.  It separates "derived the specification" from "searched
  until the number matched" (`benchmark/README.md`, "First-attempt vs
  final pass").
- **PR #46 — Retally `User-Agent` on every request.**  Harvard Dataverse
  returns 403 to `python-requests`, which made Bisbee's first Phase 3
  run fail before generation; transient download errors are never
  written to the result cache.
- **PR #48 — R sandbox packages.**  The image grows from 11 to 47
  packages (plus base), including MatchIt, CBPS, WeightIt, cobalt, lfe,
  optmatch, lme4, estimatr, did and rdrobust; the bspm D-Bus warning is
  silenced; image 1.09 → 1.61 GB; `make check-r-sandbox` verifies it.
- **PR #49 — the prompts list the installed packages.**  Generation and
  refinement prompts list the image's packages, read from the image's
  own list, with a test that fails when the two drift.

Dincecco after #44:

| Run | Final | First scored | Error / claim refinements |
|---|---|---|---|
| seeded, cache on | 13 / 13 | 13 / 13 | 0 / 0 |
| independent, cache on | 11 / 13 | 11 / 13 \* | 1 / 3 |
| independent cache-off run 1 | 13 / 13 | 13 / 13 | 0 / 0 |
| independent cache-off run 2 | 13 / 13 | 13 / 13 | 0 / 0 |
| independent cache-off run 3 | 13 / 13 | 13 / 13 | 0 / 0 |

\* First attempt 0 / 13: the first script crashed in a dplyr
`if_all(all_of(...))` filter and printed nothing; after one error repair
it scored 11 / 13, and three claim refinements did not move the two
misses (`warfare_se_full_controls` 0.3456 vs 0.370 and
`warfare_iv_se_full_controls` 1.0719 vs 1.389, both outside the 5% SE
cap).  First-scored numbers from `benchmark.artifacts --rescore`.

- **Headline.**  The population-density failure that held the 1.7 runs at
  2 / 13 (13, 2, 13 at step 6) did not recur: all three cache-off runs
  used `lnpdgpd1990` and were exact on the first script with no
  refinement.  Seeded stays 13 / 13 exact.
- **What it means.**  Every Dincecco independent loss since Phase 1.5 was
  package navigation — the wrong file (1.5–1.7 step 4), then the wrong
  column (1.7 steps 5–6) — and both are now fixed by generic listing
  changes, not by anything that names this paper's variables.  None was
  evidence that the paper's text cannot pin down its specification.
- **Spend:** $1.48 over the four runs (a cache-off independent run
  $0.25, 3 Opus 4.7 calls).

**Exit criteria:** (a) seeded: ≥50% of Dincecco's pinned headline claims
within tolerance — **met (13/13)**; (b) independent: a committed
both-mode `REPORT.md` for Dincecco with the gap stated and every lost
claim explained in the entry's `notes`. There is deliberately **no pass
target for independent mode** — whatever it is, it is the finding.

### 1.9 R data files in the dataset listing — ✅ measured (2026-10-21)
*(PR #52.  Bisbee measured on `main` a972e04 (after #52, before #53):
one cache-on and three `RETALLY_LLM_CACHE=0 --mode independent` runs,
result-cache rows deleted before every run, Opus 4.7, 47-package Docker
R sandbox, prompt otherwise as in Phase 3.  Files:
`benchmark/results/phase19-bisbee-independent-2026-10-20.json` and
`phase19-bisbee-variance-independent-run{1,2,3}-2026-10-20.json`.)*

- **PR #52 — `.RData` / `.rds` contents in the dataset listing.**  A
  small reader for R's save format (XDR serialization, vector contents
  skipped) lists each file's objects, every data frame's row count and
  columns, because pyreadr cannot open Bisbee's main file
  (`replication_data.RData`) and gives no row counts; pyreadr is the
  fallback.  Columns are ordered by the same paper-vocabulary matching
  as `.dta` columns (R has no labels, so two generic name rules stand in),
  and Dincecco's listing is byte-identical.

Bisbee independent after #52:

| Run | Final | First attempt | First scored | Error / claim refinements | March N | Spend |
|---|---|---|---|---|---|---|
| cache on | 5 / 11 | 5 / 11 | 5 / 11 | 0 / 3 | 1,461 | $0.57 |
| cache-off run 1 | 7 / 11 | 7 / 11 | 7 / 11 | 0 / 1 | 626 | $0.48 |
| cache-off run 2 | 8 / 11 | 8 / 11 | 8 / 11 | 0 / 3 | 703 | $0.85 |
| cache-off run 3 | 8 / 11 | 8 / 11 | 8 / 11 | 0 / 3 | 1,591 | $0.77 |

Before #52 (Phase 3, same image and prompt otherwise): final 8, 7, 8, 7;
first attempt 0, 0, 0, 0 (every first script crashed on guessed variable
names); first scored 4, 4, 1, 0; 1 error + 3 claim refinements each.

- **The crash cause is fixed.**  With the objects and columns listed, no
  first script crashed (0 error refinements in all four runs) and the
  first script already scored 5–8 of 11.
- **Claim refinement added nothing** in any run (first scored equals
  final everywhere), so Bisbee's independent numbers are now derivation,
  not target-guided search.
- **Final pass counts are unchanged in distribution** (5–8 vs 7–8).  The
  persistent failures are the two March coefficients (the paper-vs-code
  sample definition, Phase 3) and `sample_size_march` (N 626–1,591 vs
  1,710); `sample_size_full` (1,723 and 724 vs 1,882) fails in two runs
  and both interaction claims in the cached run.
- **What it means.**  Bisbee's independent first-scored distribution moved
  from 0–4 to 5–8 for a non-paper reason — the listing, not anything
  about this paper's variables — which is the fair kind of fix.
- **Spend:** $2.67 over the four runs.

---

## Phase 2 — Agent protocol — ✅ protocol built (2026-10); general-agent adapter TODO

Goal: make the benchmark scorable for *any* reproducer, not just this
pipeline — the moat is the benchmark (catalog, pinned claims, I4R ground
truth, two-mode scoring), and a general-purpose agent should be able to
sit the same exam.

*(Built ahead of the Phase 1.5 exit, as a refactor: no pipeline
behaviour changed in seeded mode, and the committed seeded baseline
re-scores to identical verdicts.  Standing rule 2's before/after compare
is replaced by that re-scoring test, since no live run was made.)*

The seam already existed: the runner never constructed the pipeline, it
called an injected `pipeline_factory`, and touched the result only
through `getattr` on a handful of report fields.  Phase 2 formalised it:

- **Protocol — ✅ done.**  `Reproducer` (`typing.Protocol`) in
  `benchmark/reproducer.py`: `reproduce(paper_source, *, language,
  dataset_reference, claims, reproduction_mode) -> Reproduction`.  (Named
  `reproduce`, not `validate`: the agent no longer validates anything.)
  The report contract, `Reproduction`, is the raw `{name: value}`
  outputs keyed by claim description, the claims targeted, the generated
  code, stdout/stderr, exit code, declared deviations, and per-stage
  flags — **no verdicts**.  Documented in `benchmark/README.md`
  ("Plugging in another agent").  The runner takes any reproducer:
  `--reproducer NAME` (built-in: `pipeline` only) or `--reproducer
  package.module:factory`; the reproducer is recorded on every result
  row and keys the result cache (default-pipeline seeded keys are
  unchanged, so existing caches stay valid).
- **Scoring belongs to the harness — ✅ done.**  The harness
  (`runner.score_reproduction`) re-scores the raw outputs itself with
  `ResultComparator` and the per-mode `TolerancePolicy` — claim
  matching, tolerance, closeness, `agrees_with_paper`,
  `agrees_with_i4r`.  The pipeline's own `claim_results` /
  `overall_passed` are no longer read.  Pinned claims are scored
  whatever claim set the agent reports, so no reproducer can grade its
  own exam or shrink it.
- **Reference implementation — ✅ done.**  `PipelineReproducer` adapts
  an unmodified `ValidationPipeline` (its public `validate(...)` and the
  README quick start are untouched).  Conformance tests run the real
  pipeline (real parser/extractor/generator/executor/comparator, fake
  LLM) and a minimal fake reproducer through the same harness path and
  assert identical verdicts; a report that claims success with
  off-target outputs is scored a failure.  Its numbers did not move:
  `tests/test_benchmark_reproducer.py` re-scores the committed
  `baseline-2026-10-19.json` through the harness and reproduces every
  recorded per-claim and per-paper verdict (13/13, I4R 13/13).
- **Mode enforced by what is on disk — ✅ done (back-ported to the
  pipeline adapter).**  In independent mode the harness hands the agent a
  script-free copy of the dataset (`script_free_copy` /
  `script_free_dataset`: `.do .ado .R .Rmd .py .ipynb .sas .sps .m` and
  Stata `.log`/`.smcl` transcripts removed, data hard-linked, a
  deterministic `<name>.script-free` sibling so prompts stay
  cache-stable).  `PipelineReproducer` applies it by wrapping the
  pipeline's downloader for independent calls, so the prompt's listing
  and the sandbox mount see data files only.  Independent-mode result
  cache keys changed once as a consequence.  ⚠ Independent-mode numbers
  produced before this (the first Dincecco independent run, Phase 1.5)
  saw the scripts *on disk*; re-run before comparing like for like.
  *Content-aware strip rule (`benchmark/strip_rule.py`).*  Name-based
  stripping leaked: Leeson 2022 ships its three do-files again as
  `code/*.txt`, and packages ship the esttab/stargazer tables that hold
  the answers.  The copy now also strips, by content and whatever the
  extension (text files up to 50 MB), Stata logs and SMCL, R/Python
  transcripts, analysis code under another name, byte copies of
  scripts, and regression tables (`.tex`, `.html`, plain text,
  regression-shaped `.csv`/`.xlsx`); data formats are never touched and
  plain `.csv` stays.  Each copy writes a
  `<name>.script-free.retally-stripped.json` manifest beside (not in)
  the mounted tree, and rows carry `n_files_stripped`.  On the cached
  packages: Dincecco +10 (`table*.tex`), Alesina +5 (`Out/Tables`
  regressions; summary stats kept), Bisbee +7 (stargazer `.tex`), Leeson
  +3 (`code/*.txt`); no data file stripped.  Independent result-cache
  keys were *not* bumped for this, so a cached independent row from
  before it may have seen those files.
- **General-purpose agent adapter — TODO (design only, not built).**  An
  adapter that hands an agent (e.g. one built on the Claude Agent SDK, or
  Claude Code driven headless) the paper text, the pinned claims, and a
  `script_free_dataset` copy (independent) or the full package (seeded)
  inside the same network-less sandbox images, and asks for
  `RESULT:<name>=<value>` lines keyed by claim description; it returns a
  `Reproduction` and registers in `REPRODUCERS` (or via a
  `module:attr` spec).  Open design questions: how the agent's tool
  loop is confined to the sandbox (no host shell), a per-paper budget
  (turns / tokens / wall clock) recorded on the result, and whether its
  intermediate attempts are logged as artefacts.  The contract and
  obligations it must meet are in `benchmark/README.md`.
- **Out of scope for this phase:** a leaderboard. Scores for third-party
  agents are reported in the technical report under the same honesty
  rules as our own.

**Exit criteria:** protocol + report contract documented — **met**;
harness-side re-scoring in place with the reference pipeline's committed
numbers unchanged — **met**; conformance test passing for the reference
and a fake — **met**; adapter design written up (not necessarily built)
— **met** (above; building it is the open TODO).

---

## Phase 3 — dev-set baseline over three papers — ⚠ baseline measured, tuning not started (2026-10-21)

Goal: prevent overfitting to one paper before any prompt tuning. The
dev/holdout machinery exists precisely for this.

*(Measured in both modes: Dincecco (Phase 1.8, above), Alesina, and
Bisbee on the new sandbox image.  Next: the tuning loop on dev (below).
Same protocol as 1.7–1.8: one
`--mode both` run (LLM cache on) and three `RETALLY_LLM_CACHE=0 --mode
independent` runs per paper, result-cache rows deleted before every
run, Opus 4.7, Docker R sandbox.  First-scored counts from
`benchmark.artifacts --rescore`.)*

**Alesina 2022** (`main` 1101e88, after #44/#45, before #46–#49).
Files: `benchmark/results/phase3-alesina-both-2026-10-20.json` and
`phase3-alesina-variance-independent-run{1,2,3}-2026-10-20.json`.  The
earlier `phase3-alesina-2022-immigration-redistribution-both-2026-10-20.json`
is the very first run, on `main` before #44 (seeded 6 / 11, independent
9 / 11), kept for the record.

| Run | Final | First scored | Error / claim refinements | Median rel. error |
|---|---|---|---|---|
| seeded, cache on | 7 / 11 | 7 / 11 | 0 / 3 | 0.9% |
| independent, cache on | 7 / 11 | 1 / 11 | 0 / 3 | 6.4% |
| independent cache-off run 1 | 0 / 11 | 0 / 11 | 1 / 1 | — (all NA) |
| independent cache-off run 2 | 6 / 11 | 5 / 11 | 1 / 3 | 10.0% |
| independent cache-off run 3 | 5 / 11 | 1 / 11 | 1 / 3 | 14.2% |

Classification, read from the saved scripts.  Both modes read the right
file, `Data/survey_analysis.dta`.

- **Seeded's four failures are 3–5% off** (e.g. `order_effect_tax_bottom50`
  0.8686 vs 0.914; N 19,694 vs 19,765, inside tolerance) and fail only
  the strict 1% seeded tolerance: sample-trimming details (survey-duration
  trimming, inattentive respondents).
- **Independent failures are genuine specification reconstruction.**
  (a) Outcome composition: the Social Budget outcome is built from
  `budget_socialsecurity` alone instead of health plus the social safety
  net, winsorised — although the claim context states the composition,
  so this is a model miss as much as a methods-section gap; the Social
  Budget order effect is near zero or wrong-signed in every independent
  run (0.003, 0.038, −0.134 vs −0.543), the Education Budget one in all
  but one.  (b) Sample: control-arm only (N 5,532) in the very first
  run; untrimmed N 20,730–20,933, or 16,950, in the others.  (c) The
  Hard Work effect on the immigration-support index has the wrong sign
  in every run that printed it (index direction).  (d) Cache-off run 1
  printed `RESULT` lines under its own names (per-arm treatment effects
  instead of the Order effect), so nothing matched: a name-mismatch /
  extraction failure, not a finding about the paper.
- **Alesina is the first paper where "seeded ✓ / independent ✗" appears
  for specification reasons.**  Per-claim detail in the entry's `notes`.
- **Tolerance caveat.**  In the very first run independent (9 / 11) beat
  seeded (6 / 11) only because the independent ±1·SE band passes values
  5–10% off while seeded's 1% band rejects 3–5% deviations (median
  relative error 4.8% vs 1.2%).  Pass counts are not comparable across
  modes on closeness; report median relative error alongside them.

**Bisbee 2022.**  The first run, on `main` before #46, failed outright:
Harvard Dataverse returned 403 to the `python-requests` user agent
(`phase3-bisbee-2022-flight-to-safety-both-2026-10-20.json`, both rows
errors).  After #46, on the old 11-package image (`phase3-bisbee-*`):

| Run | Final | First attempt | First scored | Error / claim refinements |
|---|---|---|---|---|
| seeded, cache on | 7 / 11 | 0 / 11 | 8 / 11 | 1 / 2 |
| independent, cache on | 0 / 11 | 0 / 11 | 0 / 11 | 2 / 1 |
| independent cache-off run 1 | 8 / 11 | 0 / 11 | 2 / 11 | 2 / 3 |
| independent cache-off run 2 | 8 / 11 | 0 / 11 | 4 / 11 | 2 / 3 |
| independent cache-off run 3 | 5 / 11 | 0 / 11 | 0 / 11 | 2 / 3 |

After #48/#49 (`main` b93e049: 47-package image, packages listed in the
prompt; `phase3b-bisbee-both-2026-10-20.json`): **seeded 10 / 11**
(first attempt 0, first scored 9 / 11, 1 error + 2 claim refinements).
The independent row of that `--mode both` run is a "credit balance too
low" error row with no claims scored (kept as an honest record); once
credit was restored, independent was measured on the same commit as a
separate cache-on run (`phase3b-bisbee-independent-2026-10-20.json`)
plus three cache-off runs (`phase3b-bisbee-variance-independent-run{1,2,3}-2026-10-20.json`,
which replace that afternoon's credit-error files):

| Run (new image) | Final | First attempt | First scored | Error / claim refinements | March N | Fails |
|---|---|---|---|---|---|---|
| independent, cache on | 8 / 11 | 0 / 11 | 4 / 11 | 1 / 3 | 1,599 | both March coefficients, `sample_size_march` |
| independent cache-off run 1 | 7 / 11 | 0 / 11 | 4 / 11 | 1 / 3 | 1,698 | `full_cbps`, both March coefficients, `anxiety_prime_effect_attentive` |
| independent cache-off run 2 | 8 / 11 | 0 / 11 | 1 / 11 | 1 / 3 | 619 | both March coefficients, `sample_size_march` |
| independent cache-off run 3 | 7 / 11 | 0 / 11 | 0 / 11 | 1 / 3 | 1,591 | both March coefficients, `sample_size_march`, `anxiety_prime_effect_attentive` |

Reading: the March coefficients fail in every independent run, for the
paper-vs-code reason below (the reproduced column 4 coefficient ranges
from −0.41 to +0.41 against −0.885); and first scored (0–4) against final
(7–8) shows that most independent passes still come from claim
refinement, not from the first script that ran.

- **Old image: every first script crashed** on `library(MatchIt)` /
  `library(CBPS)`, not installed — which is what #48/#49 fix.
- **New image: every independent first script still failed once (one
  error repair each), but not on packages.**  From each run's
  `attempt-1/stderr.txt` and `stdout.txt`: the listing shows the
  `.RData` files without their object or column names (only `.dta`
  columns are listed), so each first script guessed variable names by
  pattern matching.  In the cache-on run and cache-off run 1 the guesses
  came back NA (e.g. the House-primary vote share and endorsement
  indicators were not found), and the
  script, which printed only non-NA values, emitted no `RESULT:` line at
  all.  Run 3 built a formula from an empty variable name
  (`y_sd_units ~  + caucus_switch + ...`, `str2lang` "unexpected end of
  input").  Run 2 died on an R parse error ("unexpected end of input")
  after printing only `NA` results.  The error repair, which sees the
  printed column names, then produced the first scored script.  Listing
  `.RData` contents like `.dta` columns is the obvious generic fix.
  **That fix is PR #52 (Phase 1.9): the crash cause is gone — no first
  independent script crashed after it, and first scored (5–8 / 11)
  equals final.**
- **Most independent passes came after claim refinement** — target-guided
  search, e.g. run 1 went 2 → 8; one run grid-searched start and end
  dates for the March window against the target N.  First scored (0–4)
  against final (5–8) is the clearest case yet for headlining first
  scored.
- **The March sample, a paper-vs-code discrepancy.**  On the old image
  `exposure_coefficient_march_basic`, `exposure_coefficient_march_cbps`
  and `sample_size_march` failed in both modes (N 1,591 vs 1,710).  The
  paper says columns 4–6 cover "the elections that occurred between
  March 1st and April 7th" (header "March & April 7th"); the package's
  Table 1 script (`Table 1, SI3, SI4, SI5, Figure SI13, SI14.R`, lines
  ~124–149) filters `date >= as.Date('2020-03-01')` with no upper bound.
  On the old image the seeded script and two cache-off independent runs
  implemented the paper's window and got N = 1,591 (the others printed
  NA or 628).  On the new image seeded follows the package's filter and
  the three March claims pass; only `anti_estab_x_cases_interaction`
  fails (0.0138 vs −0.016).  Curation: the three contexts now quote the
  paper's own words for the sample (they paraphrased the same window
  before); values unchanged; the package filter and the N discrepancy are
  in the entry's `notes`.  A reproducer that follows the text is
  expected to fail these three claims: a "seeded ✓ / independent ✗"
  that is about the paper, not the model.

**`REPORT.md`** is built from a combined `results.json` (gitignored);
its dev rows (kept unchanged since this phase; the 21 evaluation rows
were added in Phase 3.2, which lists all 27) are these
six: Dincecco both rows from `phase18-dincecco-both-2026-10-20.json`,
Alesina both rows from `phase3-alesina-both-2026-10-20.json`, Bisbee
seeded from `phase3b-bisbee-both-2026-10-20.json` (new image, cache on)
and Bisbee independent from `phase19-bisbee-independent-2026-10-20.json`
(new image, after #52, cache on: 5 / 11, first scored 5; the old-image
and pre-#52 rows are not in it).
First-scored fields for rows written before #45/#47 were filled from the
run artifacts with the `--rescore` scoring path.  It is a cross-run
composite, not one run, so its "Seeded vs independent" table is a
snapshot of the latest measurement per cell.

**Spend** (sum of row `usage.estimated_usd`): Dincecco $1.48 (Phase
1.8), Alesina $5.89, Bisbee $11.06 (old image $5.81 including $0.17 on
the 403 run; new image $5.25 including $0.41 billed on the credit-error
row before the balance ran out); total **$18.43**.  A cache-off
independent run cost $0.25 (Dincecco), $0.33–0.91 (Alesina), $1.35–1.47
on the old image and $1.16–1.28 on the new one (Bisbee).

Still open from the original Phase 3 plan:

- Pin `arias-2022` (holdout): claims, I4R findings, dates.  *Claims, I4R
  findings and dates are pinned for `alesina-2022` and `bisbee-2022`.*
  Arias runs once, only to confirm the harness handles it — its numbers
  are not for tuning.
- Now that the three-paper baseline exists: prompt tuning sweeps on
  dev, holdout confirmation runs rarely, `benchmark.compare` as the
  keep-or-revert gate, always like-for-like per mode.  Tuning should
  target the **independent** number — tuning the seeded prompt mostly
  improves translation — and every kept change reports its effect on
  *both* modes, because a change that helps seeded and hurts independent
  widens the gap for the wrong reason.  Headline first scored, not final:
  final mixes derivation with target-guided search.

**Exit criteria:** committed both-mode baseline over ≥3 dev papers with
pinned claims (with SEs) and I4R findings — *measured (one seeded,
one cached and three cache-off independent runs per paper; the
committed `REPORT.md` is a cross-run composite)*; documented per-paper
failure notes for every independent-mode loss — *done*; tuning
loop demonstrably running (≥1 kept improvement with before/after compare
output in the PR) — *not started*.

### 3.1 Blind mode — built; measured, see 3.2

`--mode blind` (and `--mode all` = seeded + independent + blind; `both`
still means seeded + independent) adds `ReproductionMode.BLIND`: the
independent setup (scripts withheld, script-free dataset copy, linked
code not fetched) with every target withheld as well.  The generation
prompt lists each claim's token, type, unit label, location and curated
context, never its value, standard error or sample size; the
methodology summariser is told to leave reported results out; the
claim-targeted refinement loop does not run (crash / no-RESULT repairs
keep their budget), so no "reproduced X, claimed Y" feedback is built.
Scoring is unchanged — the harness compares the `RESULT:` lines with
the catalog values under the independent ±1·SE policy — and first scored
equals final by construction (unless a script printed results and then
crashed, and a crash repair produced the final run).  Blind pass counts are the only ones free
of target-guided search, which is the North star's open tension.

First measured in Phase 3.2 (blind 24 / 79 on seven papers, $0.20–0.48
per paper).  Before that run the estimate was: measuring it costs about the same as an
independent run per paper (a cache-off independent run was $0.25–1.47
in Phase 3; blind skips the claim-refinement calls, so it should not
cost more).  Known residue: the abstract's first 500 characters are
still shown; result tables the package ships were left on the mounted
disk under the name-based strip rule (the prompt forbids reading them)
and are stripped by content since PR #61.

### 3.2 Evaluation set, first pass — ✅ measured (2026-10-21): 7 papers × 3 modes, one run each

*(Run on `main` 0492c17 — after the content-aware strip rule (PR #61)
and the printed-precision tolerance floor (PR #62) — 47-package R image,
Opus 4.7, LLM call cache on, `--mode all`, one run per paper per mode.
Pipeline tuning is frozen and none of these papers was used to tune
anything (`split: holdout`).  File:
`benchmark/results/eval-7papers-all-modes-2026-10-21.json`.  Spend
**$8.11** for all 21 rows (84 API calls; $0.19–1.17 per row, $0.78
(Grier) to $2.44 (Arias) per paper for all three modes).)*

| Paper (orig. language, I4R verdict) | Seeded final (first scored) | Independent final (first scored; err/claim refinements) | Blind final (first scored; err ref) |
|---|---|---|---|
| adams-2023 (R, reproducible) | 11/11 (11) | 7/11 (0; 1/3) | 1/11 (1; 1) |
| arias-2022 (R, reproducible; holdout) | 4/12 (4) | 0/12 (0; 3/3) | 1/12 (1; 1) |
| grier-2023 (Stata, reproducible) | 0/11 (0) | 0/11 (0; 3/0) | 0/11 (0; 2) |
| hanlon-2022 (Stata, reproducible) | 12/12 (12) | 10/12 (10; 0/1) | 12/12 (12; 1) |
| leeson-2022 (Stata, reproducible w/ minor discrepancies) | 11/11 (11) | 9/11 (9; 0/1) | 4/11 (4; 0) |
| manekin-2022 (R, reproducible w/ minor discrepancies) | 7/12 (8*) | 12/12 (6; 1/1) | 6/12 (6; 0) |
| montero-2022 (Stata, NOT reproducible per I4R) | 10/10 (0) | 3/10 (2; 2/3) | 0/10 (0; 0) |
| **Total** | **55/79** (first scored 46) | **41/79** (first scored 27) | **24/79** (24) |

\* Manekin seeded first scored (8) is *above* final (7): a claim
refinement made the score worse and was kept because it fixed a
different claim (it fixed the Ethiopian perceived-violence coefficient
but dropped the Study 1 weights, losing both U.S. coefficients).

**Modes read against the thesis.**  Blind (targets withheld, no claim
refinement) is the only count free of target-guided search: **24 / 79
blind vs 41 / 79 independent vs 55 / 79 seeded**.  Independent first
scored (27) against final (41) is the target-guided search inside
independent mode; blind sits at about independent's first-scored level.
Seeded is not a ceiling: two packages (Grier, Stata original; Arias, R
original) failed seeded for translation reasons, so "seeded ✓ /
independent ✗" needs seeded to pass first — for Grier and Arias the gap
is undefined.  Pass counts are not comparable across modes on closeness
alone (seeded 1% vs independent / blind ±1·SE band; Manekin's
independent 12 / 12 passes the unweighted Study 1 coefficients inside
the SE band, the same numbers that fail seeded's 1% band); `REPORT.md`
gives median relative error per mode (holdout: seeded 0.3%, independent
4.9%, blind 22.3%).

Per-paper classification, read from the saved scripts:

- **Grier (0 in every mode, even seeded).**  The model estimated a
  conditional logit (`survival::clogit` with `strata(id)`) instead of
  the paper's logit with district / incumbent fixed-effect dummies, so
  every coefficient is ~1/7 of the printed value (−0.00009 vs −0.0006)
  and N is 860 / 612 instead of 186 / 106 (it reported all rows rather
  than the estimation sample).  The do-file was in the seeded prompt and
  still got mistranslated.  Grier prints coefficients to one
  significant digit and no SEs, so the printed-precision floor (PR #62)
  was the binding tolerance on most claims (`tolerance_source:
  printed_precision`); it rescued nothing because the estimates are an
  order of magnitude off.  The independent run printed no value at all
  (three error repairs).
- **Arias (seeded 4 / 12: only the four counts).**  The model reshaped
  the Qualtrics exports and estimated the AMCEs with `feols` clustered
  by respondent rather than the package's `cjoint::amce` with the
  design's randomisation constraints; the AMCEs come out ~1.5–2× too
  large (0.069 vs 0.035) and one German attribute level failed a label
  regex (NA).  The 3,700-line package script with hard-coded Windows
  paths was in the prompt; the model rewrote rather than translated.
  Independent 0 / 12 (3 error + 3 claim refinements; AMCEs near zero,
  respondents 1,033 / 1,029 vs 1,086 / 1,074); blind 1 / 12 (AMCEs again
  ~2× too large, one German level inside its SE band).
- **Montero (the headline case).**  The only public package is the I4R
  comment's (original data plus code that re-runs the original Table 5
  and then the duplicate-corrected version; `outcome_label:
  not_reproducible`; the I4R corrected values are pinned as
  `reproduced_value`).  *Seeded:* the first script produced neither the
  paper's numbers nor the replicators' (79.19 / 71.31 / −51.37 / −61.81;
  N 3,982 / 1,513 / 275 / 99).  One claim-refinement round, told the
  gaps to the paper's printed values, then reproduced the paper's
  numbers exactly (60.49 / 52.79 / −42.97 / −51.79; N 4,770 / 1,583 /
  327 / 118): target-guided search converged on numbers the human
  replicators showed to be wrong.  *Independent* 3 / 10 (one coefficient
  inside its ±1·SE band, two N).  *Blind* applied the paper's stated
  five-member rule (`filter(n_workers >= 5)`), which the original code
  never applied, and got 215.7 / 221.2 for the levels and NA for the IQR
  columns, N 1,038 / 407 / 40 / 16: following the paper's text
  reproduces neither the paper nor the replicators.  `agrees_with_i4r`
  is false in all three modes; the "agrees with I4R, not with the paper"
  cell did not occur.  This is the first measured case of the failure
  the first-scored metric and blind mode exist to expose: a seeded 10 /
  10 that is a target match, not a reproduction.
- **Hanlon.**  Seeded and blind both 12 / 12 exact on the first script;
  independent 10 / 12 (the two Table 4 US max-speed trend claims off).
  Blind > independent here is single-run noise, not a finding.
- **Leeson.**  Seeded 11 / 11 and independent 9 / 11 on the first
  script (independent: the friendliness statistic NA, the five-station
  visit count 87 vs 102).  Blind 4 / 11: without targets the model chose
  different test statistics / sample for the friendliness, Brown–Forsythe
  and ANOVA rows; the two passerby and two shuttle-stop rows pass, the
  two station-visit counts do not (239 vs 242, 87 vs 102).
- **Manekin.**  Independent 12 / 12 only after refinement (first scored
  6); blind 6 / 12 on the first script; seeded 7 / 12 (the Study 1
  weighting that only the supplement states; see the entry's `notes`).
  The two 6 / 12 first-script counts are the same six claims: the two
  Study 2 U.S. Black-protester coefficients (0.347, 0.429) and the four
  sample sizes; every Study 1 coefficient fails (blind prints NA for
  all six).
- **Adams.**  Seeded 11 / 11 on the first script; independent 7 / 11
  after 1 error + 3 claim refinements from a crashed first script
  (first scored 0); blind 1 / 11 (crashed first script, repaired, then
  only the count of election studies matched; all seven coefficients
  came out with the opposite sign and N 2,019 vs 1,842).

**Exposure note.**  PR #61 found that the old name-based strip rule had
left Dincecco's esttab table fragments (`1 paper/table1.tex`,
`table2a.tex`, …, i.e. the answers) and Alesina's and Bisbee's generated
`.tex` tables on the independent mount for every independent run before
2026-10-21 (Phases 1.5–1.9 and the Phase 3 dev baseline).  The saved
scripts of those runs read only `.dta` / `.RData` files and computed
their numbers, and the prompt forbade reading tables, but the exposure
existed.  The content-aware rule strips them (manifest per package:
Dincecco 12 files, Alesina 24, Bisbee 37, Leeson 6).  Today's
seven-paper run is the first with the content-aware rule (rows'
`n_files_stripped`: Manekin 96, Hanlon 11, Leeson 6, the rest 1).

**`REPORT.md`** is now built from a combined `results.json` (gitignored)
of 27 rows: the six dev rows listed under Phase 3 (Dincecco both rows
from `phase18-dincecco-both-2026-10-20.json`, Alesina both rows from
`phase3-alesina-both-2026-10-20.json`, Bisbee seeded from
`phase3b-bisbee-both-2026-10-20.json`, Bisbee independent from
`phase19-bisbee-independent-2026-10-20.json`; first-scored fields of the
Dincecco and Alesina rows filled from their artifacts with the
`--rescore` scoring path, final counts not re-scored) plus all 21 rows
of `eval-7papers-all-modes-2026-10-21.json`; `usage` is the sum ($11.97,
106 API calls).  It is a cross-run composite: the dev papers have no
blind row, so the report's blind totals cover the seven evaluation
papers only.

**Next.**

- (a) Variance only where it changes a conclusion: Montero seeded
  (does the first script ever land on the paper's or the replicators'
  numbers without refinement?) and Manekin independent (12 / 12 final
  from 6 first scored).
- (b) The next six shortlisted papers — altmann, lopez-moctezuma,
  dertwinkel-kalt, holman (pin Dataverse v1.0), acemoglu, gagliarducci —
  at ≈$1–2.50 per paper for all three modes.
- (c) The first technical-report draft once ≥10 evaluation papers
  exist.

### 3.3 Claude Code as a reproducer — ✅ built and measured (2026-10-21): 7 papers × 3 modes, no API spend

**What it is.**  A second agent in the benchmark, scored by the same
harness as the pipeline (PR #64, task fix #65).  `--reproducer
claude-code` is `benchmark/reproducers/filesystem.py`: it reads a run
directory `benchmark/reproductions/<entry>/<mode>/<run_id>/` that a
Claude Code session wrote — `script.R` / `stdout.txt` / `stderr.txt`
for the final run, `attempt-<n>/` for every earlier execution with its
`kind` (`error`, `claim`, or `""` for exploration) and `feedback.txt`,
and a `reproduction.json` manifest — and returns a `Reproduction`.  The
numbers come from the files (the executor's own `RESULT:` parser), never
from the manifest.  `python -m benchmark.reproducers.render_task` prepares
one cell: `task.md` (the pipeline generator's own claims block, dataset
listing, output convention, code requirements, package scripts and
independent / blind blocks, so the agent is shown what the pipeline is
shown), `paper.txt` (the extracted paper; in blind mode every pinned
value and SE redacted to `[withheld]`), and `mount/<package>/` — the
full package in seeded mode, the script-free copy in independent and
blind, its strip manifest moved outside the task directory.  The task
gives the exact `docker run` line the pipeline executor uses (same image,
`--network none`, read-only, the mount at its own path, 300 s / 4 GB /
1 CPU) and the output contract.  `check_attempt` prints the pipeline's
own claim-gap feedback (seeded / independent) or only the names of
missing quantities (blind).  The orchestrating session spawns one Opus
subagent per cell with the task file as its only input; the harness
never drives the agent and never calls the API (the HANDOFF rule: no
`claude -p` loops inside the runner).  Rows carry `reproducer:
claude-code` and sit beside the `pipeline` rows; the result cache keys on
the reproducer, `--no-cache` re-scores a cell with a new run id.

**Isolation caveat.**  An agent with a shell is isolated only by what is
on disk and by instruction.  The task directory holds only the mode's
mount and the sandbox mounts nothing else, but each subagent runs in a
full worktree of this repository: the catalog YAMLs (pinned values and
curation notes), `.cache/datasets/` (the authors' scripts) and earlier
results are readable.  The rules are enforced by instruction, by the
`files_read_outside_mount` list each agent must write, and by reading
its report.  Across the 27 runs below every agent reported an empty list
or only its own `task.md` / `render.json` / the harness's saved copy of a
long `cat`.  One real channel appeared: the subagents share one session
scratchpad, and in the two-cell test two agents overwrote each other's
scratch scripts (the Grier blind agent saw the Montero exploration
script, and said it did not use it).  Later waves used a private
scratch subdirectory per cell.  A second, structural leak is in the
*catalog*, not the harness, and affects the pipeline's blind prompt
identically: curated claim `context` fields of the count claims state
the sample sizes (Adams "1,842 dyads", Leeson "242 visits / 102",
Montero "4,770 workers; 327 properties; 98 clusters; mean 73.59").  Blind
agents read them: the Montero blind agents used them to pin the sample
("I used the property counts in the task text to pick the sample"), the
Leeson blind agent re-ran to match them, the Adams blind agent saw 1,842
and *declined* to tune toward it.  So a blind pass on a count claim
whose context states the count is not blind.

**Two-cell test (run `2026-10-21-a`, Montero and Grier, all three
modes; `benchmark/results/claude-code-test-cells-2026-10-21.json`).**
Grier 10 / 9 / 10 of 11 (pipeline 0 / 0 / 0), Montero 10 / 10 / 10 of
10 (pipeline 10 / 3 / 0).  Two harness findings, fixed in PR #65: the
Grier agents printed a placeholder `RESULT:explore=N` line in each
data-inspection run, which the harness scored as the first scored
attempt (0 / 11); and one agent labelled an inspection run `kind:
"error"`.  The task now says exploratory runs are `kind: ""` attempts
that print no `RESULT:` line, and `render_task` copies `task.md` into
the output directory so the artifacts carry the task.

**21-cell run (run `2026-10-21-b`, the seven evaluation papers × 3
modes, rendered from the #65 branch, one subagent per cell in three
waves of seven by mode; `benchmark/results/claude-code-7papers-all-modes-2026-10-21.json`).**
Subagents ran on the desktop app's Opus model (the agents report it as
Claude Opus 5.5), against the pipeline's `claude-opus-4-7`: **the two
rows differ in model as well as in harness**, so the gap below is an
upper bound on what the agentic loop adds.  No API spend; ≈1.8 M
subagent tokens of plan usage for the 21 cells (≈0.6 M for the six test
cells), 1.5–5.3 min wall clock per cell.

| Paper | Seeded final (first scored; err/claim ref) | Independent final (first scored; err/claim ref) | Blind final (first scored; err ref) | Pipeline (3.2) seeded / independent / blind |
|---|---|---|---|---|
| adams-2023 | 11/11 (11; 0/0) | 11/11 (11; 0/0) | 8/11 (8; 0) | 11 / 7 / 1 |
| arias-2022 | 12/12 (12; 0/0) | 12/12 (12; 0/0) | 12/12 (12; 0) | 4 / 0 / 1 |
| grier-2023 | 10/11 (10; 0/0) | 10/11 (10; 0/0) | 10/11 (10; 0) | 0 / 0 / 0 |
| hanlon-2022 | 12/12 (12; 0/0) | 12/12 (12; 0/0) | 12/12 (8; 0) | 12 / 10 / 12 |
| leeson-2022 | 11/11 (11; 0/0) | 11/11 (10; 0/1) | 11/11 (10; 0) | 11 / 9 / 4 |
| manekin-2022 | 12/12 (12; 1/0) | 12/12 (12; 0/0) | 12/12 (12; 1) | 7 / 12 / 6 |
| montero-2022 | 10/10 (10; 0/0) | 10/10 (10; 0/0) | 10/10 (10; 0) | 10 / 3 / 0 |
| **Total** | **78/79** (78; 1/0) | **78/79** (77; 0/1) | **75/79** (70; 2) | 55 / 41 / 24 |

Median relative error (`benchmark.compare` against
`eval-7papers-all-modes-2026-10-21.json`): seeded 0.1% (pipeline 0.3%),
independent 0.2% (4.9%), blind 0.3% (22.3%).  `agrees_with_paper` per
paper: seeded and independent 6 / 7 (Grier fails), blind 5 / 7 (Grier
and Adams).  `agrees_with_i4r`: Montero false in every mode, as for the
pipeline; the "agrees with I4R, not with the paper" cell did not occur.

**Metric semantics for an agent.**  *First attempt* is meaningless for
an agent (its first execution is usually a data-inspection run that
prints nothing); *first scored* — the first execution with a `RESULT:`
line — is the comparable number, and 70–78 of 79 per mode says the
agents' first estimating script was essentially final.  `n_executions`
(1–5 per cell) includes exploration.  The error / claim refinement
counts are the agent's own bookkeeping: across 21 cells, 2 error repairs
(Manekin seeded and blind, a crashed first script) and 1 claim
refinement (Leeson independent).  Two more re-runs were steered by a
number without a `claim` label, both toward counts stated in the claim
*contexts* (Leeson blind, Montero blind) — under the task's definition a
"claimed value" is what `check_attempt` compares against, and the
contexts are not that.  Treat the agent's refinement counts as a lower
bound.

**Per-paper reading, with the caveats.**

- **Grier (10 / 11 in every mode; pipeline 0 everywhere).**  Every agent
  wrote the paper's logit with district / incumbent dummies on the
  vote-switching sample (93 districts, 186 rows; 53 incumbents, 106) —
  seeded by translating the do-file, independent and blind by working it
  out from the data (the three `.dta` files differ only in `totalcont`;
  which file is which window is undocumented and was inferred from
  nesting and refunds).  The single miss is a printed-precision case: the
  authors' own script gives −0.000565 for the calendar-year incumbent
  coefficient, printed as −0.0005 (one significant digit; 12.9% relative,
  tolerance 10%), so the package does not reproduce that printed digit
  either.  The deflator base year is unstated: run a's blind agent
  deflated to 2013 dollars, run b's to 2018, which rescales every
  contribution coefficient by 8% and moved the blind miss to the
  calendar-year district coefficient (−0.00053 vs −0.0006).
- **Montero (10 / 10 in every mode, both runs; pipeline 10 / 3 / 0).**
  *Seeded*, both runs: the first script follows the do-file's
  "replicating original results" block (deflated income with 2010 set to
  0, sex / age / age² controls, Stata percentiles) and lands exactly on
  the paper's printed numbers — the ones I4R showed are wrong — with no
  refinement at all, where the pipeline needed one claim-refinement
  round.  *Independent and blind*, all four runs (a and b): the same
  specification each time — nominal `hh_income_pc`, no demographic
  controls, strict bandwidth, property-by-round cells, no five-member
  rule (every agent tried it, found no definition that gives 327 / 118,
  and said so) — and the same numbers, 82.25 / 71.83 / −56.42 / −63.73
  against the printed 60.49 / 52.79 / −42.97 / −51.79 and the
  replicators' 13.21 / −24.24 / −72.24 / −79.78.  They pass only because
  the independent and blind tolerance is ±1·SE (relative errors 23–36%),
  and the six counts pass because the contexts state them.  The honest
  reading: the agents' paper-faithful specification matches neither the
  paper nor I4R, exactly as the entry's "Benchmark implications"
  predicted; the 10 / 10 is the SE band plus the context leak.  One
  independent agent reported the checker's "All claims within tolerance"
  for 82.25 vs 60.49 as a suspected fault; it is the band.
- **Adams (11 / 11 / 8).**  Blind applied the paper's stated rule
  literally — both parties need at least four MPs — and got 1,535 dyads
  against the published 1,842 (the authors filtered on the evaluated
  party only, which the agent found in an exploratory run and refused to
  adopt because the number came from the task).  Independent used the
  filter that gives 1,842 from the start.  The pipeline's blind row had
  every coefficient sign-flipped; the agent's are within 5%.
- **Arias (12 / 12 in every mode; pipeline 4 / 0 / 1).**  `cjoint` is
  not in the sandbox; the seeded agent re-implemented `read.qualtrics`
  and `amce` from the 3,700-line package script, the independent and
  blind agents reshaped the Qualtrics exports themselves.  Blind counts
  are slightly off (1,085 / 1,072 respondents, 18,952 / 18,826 profiles)
  but inside tolerance.  Redaction gap: the paper's prose states effect
  sizes in percentage points ("3.5 points" for a claim pinned as 0.035),
  a unit conversion the value-form redaction does not catch; the agent
  disclosed reading them and fixed its specification before estimating.
- **Hanlon (12 / 12 everywhere).**  Blind first scored 8 / 12: the first
  estimating script gave the US and the UK separate splines, so the "vs
  UK" terms were plain US slopes; the agent fixed it against the paper's
  definition, not against a number.
- **Leeson (11 / 11 everywhere; pipeline blind 4 / 11).**  Independent
  and blind first scripts both lost the two visit counts to fixest's
  singleton-group default (240 / 98 vs 242 / 102); `fixef.rm = "none"`
  fixed both without moving a coefficient.
- **Manekin (12 / 12 everywhere; pipeline seeded 7 / 12).**  A
  pipeline-side bug surfaced: the seeded task's "Original Replication
  Scripts" block held only macOS `._*` AppleDouble resource-fork files,
  because `select_package_scripts` ranks them like real `.R` files — so
  the pipeline's seeded prompt for Manekin never showed the authors'
  code.  The agent read the real scripts from the mount (allowed in
  seeded mode).  Fix pending (pipeline tuning is frozen; this is a
  selector bug, to be measured as its own step).

**What the agent does that the pipeline cannot.**  It inspects the data
before estimating (1–4 exploratory runs per cell: variable lists, row
counts, which file is which), reads the whole paper rather than a
500-character abstract plus a summary, reads package READMEs (including
`.docx`), re-implements a missing package, and checks its own sample
counts against the paper's text.  The pipeline's failure modes in 3.2 —
wrong estimator (Grier), rewrite-instead-of-translate (Arias), wrong
file (Dincecco earlier), sign flips (Adams blind) — did not occur.

**`REPORT.md`** now renders both reproducers from two committed files:
`pipeline-10papers-all-modes-2026-10-21.json` (the exact 27-row
composite 3.2 describes, now committed, with the Dincecco / Alesina
first-scored and refinement fields filled from the 3.2 report; it
re-renders the previous REPORT.md byte for byte) and
`claude-code-7papers-all-modes-2026-10-21.json`.

**Next.**

- (a) Curation: move sample sizes and means out of the count claims'
  `context` fields (Adams, Leeson, Montero, and check the rest) — a
  catalog change that re-keys the pipeline's cached rows, so it is a
  deliberate step with a before / after.
- (b) `select_package_scripts`: skip `._*` AppleDouble files; measure
  Manekin seeded on the pipeline afterwards.
- (c) Model confound: run the pipeline with the same model as the agent,
  or the agent with Opus 4.7, on these seven papers before reading the
  gap as "agentic loop".
- (d) The six shortlisted papers (altmann, lopez-moctezuma,
  dertwinkel-kalt, holman, acemoglu, gagliarducci) now cost no API credit
  to measure with the agent; the pipeline rows remain the paid part.
- (e) Variance where it matters: a second blind run of Adams (the
  four-MP rule) and Grier (the deflator).

### 3.4 Corpus 10 → 18, harness fixes from 3.3, and the agent on the six new papers — ✅ measured (2026-10-22), no API spend

**Harness and catalog fixes (3.3's list, all merged in order).**  #68
`select_package_scripts` skips macOS `._*` / `__MACOSX` stubs (Manekin:
all 20 "scripts" the pipeline's seeded prompt showed were stubs); #69 a
catalog test (`tests/test_catalog_contexts.py`): no claim `context` /
`location` / `unit` may state a pinned value of its entry, and seven
entries reworded (Adams, Alesina, Bisbee, Dincecco, Grier, Leeson,
Montero — counts and means moved to `notes`; this re-keys those entries'
pipeline cache rows, deliberately); #75 blind paper redaction also
withholds percentage forms of sub-unit values ("22.4%" for 0.224,
"3.5 points" for 0.035 — found live on Dertwinkel-Kalt and Arias); #77
the strip rule content-tests binary `.xls` workbooks (Gagliarducci's
`Output/Table5_*.xls` held every pinned value to six decimals on the
blind mount; 128 → 152 files stripped, the 15 other packages unchanged);
from curation, `PaperParser.parse_url` sniffs `%PDF` when a repository
serves a PDF as `application/octet-stream` (#73) and the Dataverse
downloader pins `version=<v>` (#76, Holman 1.0 vs the post-corrigendum
2.0).  Still open from 3.3: the model confound (paid).

**Blind second runs (run `2026-10-22-a`;
`benchmark/results/claude-code-blind-rerun-2026-10-22.json`).**  Adams
8 / 11 with the same numbers to six decimals (1,535 dyads from the
paper's stated four-MP rule, both times: a stable, principled miss).
Arias 12 / 12 (this time every count exact, after one error repair).
Grier 9 / 11: the agent mapped the two robustness-window files the
other way round — the package never says which `_iter` file is which
window, so this is an undocumented coin-flip worth two claims — and the
two runs chose opposite deflator base years.

*Second blind samples for the two weakest new cells (run
`2026-10-22-b`; `claude-code-blind-rerun-2026-10-22-b.json`):*
Gagliarducci 9 / 13 (first run 7 / 13): the same percent-opposite
definition both times (the data's variable, missing for bills with no
cosponsors), so the two Panel B counts miss both times; two Panel B
coefficients moved inside the SE band.  Holman 5 / 11 (first run 6 /
11): Table 2 identical to six decimals in both runs (the paper's fixed
effects and logit, not the code's random effects and linear model),
Table 4 slightly different (2.22 / −2.96 vs 2.32 / −3.83).  Both misses
are stable: paper-versus-code, not run-to-run noise.  The Grier entry's
`notes` now record the window-file mapping and deflator ambiguities.

**Curation (PRs #70–#74, #76; agents, from
`benchmark/corpus/candidates-2026-10-21.md`; 75 pinned claims).**
Catalog 10 → 18 (16 in scope).  Caveats recorded per entry: the open PDF
is a working paper for Altmann (the 2019 IZA draft has no regression
tables and no online experiment: blind and independent runs work from
the claim contexts), Gagliarducci (NBER 2016; one pinned Table 5 cell
differs, 6.857 in the WP vs 6.734 published) and Dertwinkel-Kalt (DP
076, same tables); Acemoglu switched to the published QJE PDF hosted at
MIT because the WP's tables differ in numbering and values.  I4R
findings: Acemoglu has none usable (every database row is a robustness
variant: `not_attempted`), López-Moctezuma's rest on the team's survey
answer only, Gagliarducci's on the clustering-variant rows, Holman's are
DP41's corrected values (`not_reproducible`).  Two leaks that are
properties of the data, not the harness: the dataset listing's row
counts equal a pinned N for Acemoglu (5,775) and López-Moctezuma (39),
and a rounded prose value survives redaction (Holman "3.1 points" for
3.112).  Both affect the pipeline's prompts identically.

**Results (one Opus subagent per cell, run `2026-10-22-a`;
`benchmark/results/claude-code-6papers-all-modes-2026-10-22.json`).  No
pipeline rows yet for these six papers (API credit; ≈$1–2.50 per paper
for the three modes).**

| Paper | Seeded final (first scored; err/claim ref) | Independent final (first scored; err/claim ref) | Blind final (first scored; err ref) |
|---|---|---|---|
| acemoglu-2022 (Stata, reproducible) | 12/12 (12; 0/0) | 12/12 (12; 0/1) | 12/12 (10; 0) |
| altmann-2022 (Stata, minor discrepancies) | 13/13 (13; 0/0) | 13/13 (13; 0/0) | 13/13 (13; 0) |
| dertwinkel-kalt-2022 (Stata, reproducible) | 13/13 (13; 0/0) | 13/13 (12; 0/1) | 13/13 (13; 0) |
| gagliarducci-2022 (Stata, reproducible) | 13/13 (11; 1/1) | 13/13 (13; 0/0) | 7/13 (7; 0) |
| holman-2022 (Stata, NOT reproducible) | 11/11 (11; 1/0) | 10/11 (10; 0/1) | 6/11 (6; 1) |
| lopez-moctezuma-2022 (R, minor discrepancies) | 13/13 (13; 0/0) | 9/13 (9; 0/2) | 9/13 (9; 0) |
| **Total** | **75/75** (73) | **70/75** (69) | **60/75** (58) |

Median relative error 0.0% / 0.2% / 0.3%.  `agrees_with_paper`: seeded
6 / 6, independent 4 / 6, blind 4 / 6.  Over all 13 evaluation papers
the agent is at seeded 153 / 154, independent 148 / 154, blind 135 /
154.  The remaining misses are paper-versus-code gaps, not translation
or harness failures:

- **Holman (the not-reproducible case).**  Seeded 11 / 11 by following
  the do-file: Stata's `xtreg` *without* `fe` (random effects) and a
  linear model for "May best PM", where the paper says fixed effects and
  a logit; and `xtpcse, cor(psar1)`, both re-implemented by hand.
  Independent 10 / 11: Table 2 exact (the agent inferred the random
  effects from the printed magnitudes), Table 4 at 2.32 / −3.83 vs 3.112
  / −4.333 (inside the SE band) with N 4,486 vs 4,328 (no stated rule
  gives 4,328).  Blind 6 / 11: the agent did what the paper says (fixed
  effects, logit) and the two "best PM" coefficients come out on a
  different scale.  `agrees_with_i4r` false in every mode: seeded
  reproduces the printed numbers that DP41 corrected; blind reproduces
  neither.
- **López-Moctezuma.**  Table 1 exact in every mode (the agent
  re-implemented the archived `ri` package and rebuilt two intermediate
  files the package omits); the four attitude-index effects (SI Tables
  C.3–C.4) fail independent and blind both: the paper does not state the
  attendance-weight formula or the item orientations, and no variant the
  agents tried matches.  Seeded 13 / 13 from the scripts.
- **Gagliarducci.**  Seeded 13 / 13 after one error repair and one claim
  refinement (the 2014 bandwidth selector re-implemented from the
  shipped `.ado`; Stata's probit perfect-predictor handling copied);
  the WP-vs-published cell passes at 1.8%.  Independent 13 / 13 inside
  the SE band with the Republican OLS cells a quarter off.  Blind 7 / 13:
  the agent used the data's percent-opposite variable (missing for
  bills with no cosponsors) where the paper divides by cosponsors + 1,
  so Panel B loses 19k bills and its coefficients move.
- **Acemoglu, Altmann, Dertwinkel-Kalt.**  Every mode full marks; the
  first scored scripts lost only singleton observations (Acemoglu blind
  first scored 10 / 12) or the preregistered sample flag (Dertwinkel-Kalt
  independent 12 / 13).  Altmann's blind and independent runs had no
  usable paper tables and still matched every published value from the
  claim contexts plus the data's variable labels.

**`REPORT.md`** is rendered from three files:
`pipeline-10papers-all-modes-2026-10-21.json`,
`claude-code-7papers-all-modes-2026-10-21.json` and
`claude-code-6papers-all-modes-2026-10-22.json` (the blind second runs
are not in it; they would collide with the first runs' cells).

**Next.**

- (a) Pipeline rows for the six new papers (paid; ask first).
- (b) The model confound from 3.3 (paid; ask first).
- (c) Second blind samples for Gagliarducci and Holman, and a note in
  the Grier entry about the undocumented window-file mapping.
- (d) Corpus: the two reserves (Guay & Johnston, Brouwer et al.) if
  their PDFs become reachable; otherwise a new shortlist pass.

### 3.5 Pipeline model: Opus 4.7 → Opus 5.5 — ✅ measured on 4 of the 7 evaluation papers (2026-10-22), $3.54

The pipeline's default model had been `claude-opus-4-7` since the
generator and extractor were written, and every pipeline row in 3.2–3.4
was produced on it, without thinking (the calls sent no `thinking`
parameter, and on 4.7 that means none).  The agent rows in 3.3–3.4 ran
on the desktop app's Opus 5.5.  This step moves the pipeline to the
same model so the confound in 3.3 can be measured rather than argued
about, and because 5.5 is 20 % cheaper per token ($4 / $20 vs $5 / $25
per MTok; same tokenizer, so the same prompts cost the same input).

What changed (one PR, no prompt text touched — the tuning freeze
holds):

- `retally.llm` holds the defaults: `DEFAULT_MODEL = "claude-opus-5-5"`,
  generation and refinement at `output_config.effort = "high"`, claim
  extraction at `"medium"` (the model default).  On Opus 5.5 thinking
  cannot be disabled; effort is the only depth control, and the thinking
  tokens are billed as output and count against `max_tokens`.
- Responses are read with `retally.llm.response_text`, which takes the
  first `text` block: a 5.5 response opens with a thinking block, so the
  old `response.content[0].text` would have read the wrong block.  The
  LLM call cache persists only the text.
- Generation `max_tokens` 8192 → 16384 (room for the think-through plus
  the script); extraction stays at 16384.
- `benchmark.runner --model MODEL_ID` / `RETALLY_PIPELINE_MODEL`
  selects the pipeline's model, and the pipeline's result-cache key now
  carries it, so Opus 4.7 and Opus 5.5 rows never collide.  Every
  pipeline cache key changed once with this; the 3.2–3.4 pipeline rows
  live in `benchmark/results/pipeline-10papers-all-modes-2026-10-21.json`.

Cost expectation: per token 20 % less, per run roughly the same, because
the thinking tokens are new output.  The 3.2 pass was $8.11 for 21 rows
on 4.7; budget $8–12 for the same 21 cells on 5.5.

**Measured (2026-10-22, run ids `20261022T04xxxxZ`, one run per cell,
LLM cache cold for 5.5).**  Credit allowed four of the seven papers;
they were chosen by agent-over-pipeline gap per dollar (Grier, Montero,
Manekin, Leeson; Arias had the largest gap but cost $2.44 alone), so
they lean toward papers where the 4.7 pipeline did badly.  Files:
`benchmark/results/pipeline-opus55-{grier,montero,manekin,leeson}-all-modes-2026-10-22.json`
and the composite `pipeline-opus55-4papers-all-modes-2026-10-22.json`.
The same 12 cells, three ways (claims within tolerance of the paper;
first-scored and refinement counts in parentheses for the pipelines):

| Paper | Mode | n | Pipeline 4.7 | Pipeline 5.5 | Agent (5.5) |
|---|---|---|---|---|---|
| Grier | seeded | 11 | 0 (0, 1) | 11 (10, 3) | 10 |
| Grier | independent | 11 | 0 (0, 3) | 0 (0, 2) | 10 |
| Grier | blind | 11 | 0 (0, 2) | 0 (0, 0) | 10 |
| Montero | seeded | 10 | 10 (0, 1) | 10 (10, 0) | 10 |
| Montero | independent | 10 | 3 (2, 5) | 10 (1, 3) | 10 |
| Montero | blind | 10 | 0 (0, 0) | 0 (0, 0) | 10 |
| Manekin | seeded | 12 | 7 (8, 4) | 12 (12, 0) | 12 |
| Manekin | independent | 12 | 12 (6, 2) | 12 (12, 0) | 12 |
| Manekin | blind | 12 | 6 (6, 0) | 12 (12, 0) | 12 |
| Leeson | seeded | 11 | 11 (11, 0) | 11 (11, 0) | 11 |
| Leeson | independent | 11 | 9 (9, 1) | 11 (8, 2) | 11 |
| Leeson | blind | 11 | 4 (4, 0) | 8 (8, 0) | 11 |
| **Total** | seeded | 44 | **28** | **44** | **43** |
| | independent | 44 | **24** | **33** | **43** |
| | blind | 44 | **10** | **20** | **43** |

Reading: on these four papers the model change alone closes the seeded
gap (44/44, first attempt in three of four) and about half of the
independent and blind gaps; what remains in independent (33 → 43) and
blind (20 → 43) is the harness.  The pipeline's remaining misses are
all sample construction: Grier independent/blind land on 172 / 94
observations instead of 186 / 106 (the undocumented `_iter1`/`_iter2`
window files, see 3.4 — the agent resolved this by trying both; the
pipeline gets one shot plus refinement on the error text), Montero
blind builds the regression on 130 rows instead of 4,770 (it never finds
the right data file without the scripts), Leeson blind gets the
five-station subsample wrong (98 vs 102 visits) and with it the two
dollars-per-hour tests.  Montero seeded on 5.5 still lands on the
paper's wrong numbers from the do-file, as in 3.2.

Cost: $3.54 for the 12 cells against $3.62 for the same cells on 4.7
— output tokens up 41 % (77.7 k → 109.6 k; the thinking), input tokens
unchanged (335 k → 337 k), per-token price down 20 %.  A wash per run,
as predicted; `claude-opus-5-5` rows price at $4 / $20 in
`benchmark/pricing.py`.  Total project spend ≈ $35.5.

Caveats: one run per cell; four papers chosen by expected gain, not at
random; the agent rows are from 3.3 (predate the #69 context rewording)
and share the 3.3/3.4 caveats; Opus 5.5 effort is `high` for generation
and `medium` for extraction while the agent runs at the desktop default.
REPORT.md carries both pipeline rows: the renderer labels a reproducer
that appears on several models with the model (`pipeline
(claude-opus-5-5)`, from each row's `usage.by_model`) so the two never
pool.

**Oracle run (2026-10-23, zero API spend): the remaining nine papers
through the pipeline harness with every Claude call answered by a
desktop Opus subagent.**  Built as PR #83 (`--llm-oracle LABEL`,
`retally.llm_oracle`, `benchmark.oracle`; README "Running the pipeline
on plan usage"): the pipeline's requests are byte-identical to a live
run's, each unanswered one is parked on disk, a Claude Code subagent
(told to use no tools and read nothing but the prompt) writes the
answer, the driver installs it, and the run resumes.  Nine papers ×
3 modes took seven rounds (109 answered calls, 88 subagent spawns, ≈6.5 M
plan tokens, about 40 minutes wall clock).  File:
`benchmark/results/pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`;
REPORT.md labels the rows `pipeline (desktop-opus)`.

| Paper | Mode | n | Pipeline 4.7 | Pipeline oracle (first scored, refinements) | Agent (5.5) |
|---|---|---|---|---|---|
| Arias | seeded | 12 | 4 | 12 (12, 0) | 12 |
| Arias | independent | 12 | 0 | 12 (12, 0) | 12 |
| Arias | blind | 12 | 1 | 12 (12, 0) | 12 |
| Adams | seeded | 11 | 11 | 11 (11, 0) | 11 |
| Adams | independent | 11 | 7 | 10 (6, 3) | 11 |
| Adams | blind | 11 | 1 | 7 (7, 1) | 8 |
| Hanlon | seeded | 12 | 12 | 12 (12, 0) | 12 |
| Hanlon | independent | 12 | 10 | 12 (12, 0) | 12 |
| Hanlon | blind | 12 | 12 | 12 (12, 0) | 12 |
| Altmann | seeded | 13 | — | 13 (13, 0) | 13 |
| Altmann | independent | 13 | — | 13 (4, 2) | 13 |
| Altmann | blind | 13 | — | 4 (4, 0) | 13 |
| Dertwinkel-Kalt | seeded | 13 | — | 13 (13, 0) | 13 |
| Dertwinkel-Kalt | independent | 13 | — | 13 (13, 0) | 13 |
| Dertwinkel-Kalt | blind | 13 | — | 12 (12, 0) | 13 |
| Acemoglu | seeded | 12 | — | 12 (12, 0) | 12 |
| Acemoglu | independent | 12 | — | 11 (4, 3) | 12 |
| Acemoglu | blind | 12 | — | 4 (4, 0) | 12 |
| López-Moctezuma | seeded | 13 | — | 13 (13, 0) | 13 |
| López-Moctezuma | independent | 13 | — | 9 (9, 3) | 9 |
| López-Moctezuma | blind | 13 | — | 9 (9, 0) | 9 |
| Gagliarducci | seeded | 13 | — | 8 (8, 2) | 13 |
| Gagliarducci | independent | 13 | — | 13 (7, 3) | 13 |
| Gagliarducci | blind | 13 | — | 12 (12, 0) | 7 |
| Holman | seeded | 11 | — | 11 (11, 0) | 11 |
| Holman | independent | 11 | — | 3 (1, 2) | 10 |
| Holman | blind | 11 | — | 0 (0, 0) | 6 |
| **Total, 9 papers** | seeded | 110 | — | **105** | **110** |
| | independent | 110 | — | **96** | **105** |
| | blind | 110 | — | **72** | **92** |

**The seven-paper confound row is now complete** (pipeline on the
agent's model: four papers through the API, three through the oracle):

| Mode | Pipeline 4.7 | Pipeline on Opus 5.5 (API + oracle) | Agent (5.5) |
|---|---|---|---|
| seeded | 55 / 79 | **79 / 79** | 78 / 79 |
| independent | 41 / 79 | **67 / 79** | 78 / 79 |
| blind | 24 / 79 | **51 / 79** | 75 / 79 |

Reading: with the model held fixed, the harness gap is zero in seeded
mode, 11 claims in independent mode and 24 in blind mode on the seven
3.2 papers; on the six 3.4 papers it is 5 / 9 / 20 of 75.  The agentic
loop's advantage is concentrated where the scripts are withheld and
grows when the targets are withheld too — the pipeline gets one script
plus feedback, the agent gets to try alternatives.  Where the oracle
pipeline falls short it is again sample construction and model choice:
Altmann blind runs on 17,840 observations instead of 12,160 (wrong
treatment-arm subset), Acemoglu blind on 178 / 171 clusters instead of
181 / 175, Adams blind on the 2,019-dyad rule the agent also tried
first, Holman independent and blind on random-effects / linear
probability models where the paper uses fixed effects and logit
(the agent's miss in 3.4, worse here), Gagliarducci seeded on a
different percent-opposite definition.  Two cells beat the agent:
Gagliarducci blind 12 vs 7 and Hanlon blind first-scored 12 vs 8.

Caveats specific to the oracle: the subagents answer at the desktop
app's default effort, not the pipeline's `output_config`; isolation is
by instruction (two of 88 subagents reported running a harmless shell
command on their own answer file; none read anything outside the
prompt); the extraction prompts truncate the paper text by design
(several answering agents noted the cut-off); one run per cell; the
agent rows it is compared with were produced in 3.3–3.4 and carry
those caveats.

**Variance pass (2026-10-23, zero API spend): a second complete sample
of the pipeline on all 13 evaluation papers through the oracle** (label
`desktop-opus-run2`; six rounds, 157 answered calls, 157 subagent
spawns; file
`benchmark/results/pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`,
not folded into REPORT.md to keep its label count down).  Sample 1 is
the four API papers plus the nine oracle papers above; sample 2 is all
oracle.

| Mode | Pipeline sample 1 | Pipeline sample 2 | Agent (one sample) |
|---|---|---|---|
| seeded | 149 / 154 | 152 / 154 | 153 / 154 |
| independent | 129 / 154 | 128 / 154 | 148 / 154 |
| blind | 92 / 154 | 82 / 154 | 135 / 154 |

Cell level: 25 of 39 cells identical across the two samples; mean
absolute difference 0.97 claims; the largest swings are Gagliarducci
(seeded 8 → 12, blind 12 → 7), Holman independent (3 → 8), Adams blind
(7 → 2), Leeson independent (11 → 8), Manekin blind (12 → 9), Montero
independent (10 → 7).  The mode totals move by 3, 1 and 10 claims; the
harness gap against the agent is 1–4 seeded, 19–20 independent, 43–53
blind.  So the headline is stable under resampling of the pipeline arm:
the independent-mode gap is about 20 claims and the blind-mode gap
about 45–55 of 154, and the seeded gap is within the run-to-run noise.
Per-cell noise of up to five claims means no single-paper comparison in
the tables above should be read on its own.  Caveats: the oracle
caveats of the first run apply; four cells' sample 1 came from the API
at the pipeline's configured effort while sample 2 came from the
desktop default, so for those four papers the two samples differ in
route as well as draw; the agent had one sample per cell except the
five blind reruns in 3.4 until its second sample below.

**Agent second sample (2026-11-01, zero API spend): Claude Code again
on all 13 evaluation papers in independent and blind mode** (run id
`2026-11-01-a`, desktop Opus, label `claude-code`; 26 cells; file
`benchmark/results/claude-code-run2-13papers-indep-blind-2026-11-01.json`,
not folded into REPORT.md).  Produced as in 3.3–3.4: one Opus subagent
per cell, `render_task` → agent → `runner --reproducer claude-code
--no-cache`.  Seeded was not rerun (its pipeline gap is within noise in
both pipeline samples).  Agent sample 1 is the 3.3 and 3.4 files
(`claude-code-7papers-all-modes-2026-10-21.json` +
`claude-code-6papers-all-modes-2026-10-22.json`).

| Mode | Agent sample 1 | Agent sample 2 | Pipeline sample 1 | Pipeline sample 2 |
|---|---|---|---|---|
| independent | 148 / 154 | 147 / 154 | 129 / 154 | 128 / 154 |
| blind | 135 / 154 | 132 / 154 | 92 / 154 | 82 / 154 |

Cell level, agent sample 1 vs 2: independent 12 of 13 cells identical,
mean absolute difference 0.08 claims, max 1 (Grier 10 → 9); blind 10
of 13 identical, mean 0.54, max 4 (Montero 10 → 6; also Gagliarducci
7 → 9, Adams 8 → 7).  The agent moves much less than the pipeline did
between its two samples (8 and 6 of 13 cells identical in independent
and blind).  With both agent samples against both pipeline samples the
harness gap is **18–20 claims in independent mode and 40–53 in blind
mode** (of 154); the blind range comes mostly from the pipeline's own
spread (92 vs 82).  The headline survives resampling of both arms.

Agent-side notes.  Every agent reported reading nothing outside its
mount, with three exceptions, none of which the agent reported using to
adjust a value: the Hanlon blind agent glimpsed one garbled table row
of three integers while printing the paper text; the Grier independent
agent read the harness's saved copy of its own `cat paper.txt` output;
the Holman blind agent saw prose effect sizes while reading the method
section.  The Altmann independent agent noted that `paper.txt` is an
earlier working-paper version (564 subjects, no online study) and took
the specifications from the claim descriptions.  Montero blind's IQR
estimates were flagged fragile by its own agent (they flip sign
without a survey-round fixed effect).  Adams independent used the
one-sided four-seat rule (1,842 dyads), Adams blind the two-sided rule
(1,525).  `n_refinements` is the agents' self-report, as before.

**Memorisation probe (2026-11-01, zero API spend).**  `benchmark/probe.py`
(PR #87; benchmark/README.md "Memorisation probe") on the 13 evaluation
papers: one no-tools desktop Opus subagent per paper, given the title,
authors, venue and each pinned claim's name, type and context only,
asked for each number from memory with a `recalled | inferred | none`
confidence per claim, and scored with the blind-mode comparator.  File:
`benchmark/results/probe-desktop-opus-2026-11-01.json`.  The table is
what `benchmark.probe score --compare` prints with the three agent
files (sample 1 = the first two columns, sample 2 = the third), here
rendered by `probe.markdown_table` from the results file's rows (the
probe store under `benchmark/.cache/probe/` is not committed):

| paper | claims | answered | within tol | within 2x | within 5x | median rel err | recalled / inferred / none / missing | blind: claude-code-7papers-all-modes-2026-10-21 | blind: claude-code-6papers-all-modes-2026-10-22 | blind: claude-code-run2-13papers-indep-blind-2026-11-01 |
|---|---|---|---|---|---|---|---|---|---|---|
| acemoglu-2022-war-socialism-fascism | 12 | 7 | 5 | 5 | 6 | 21.6% | 0 / 7 / 5 / 0 | — | 12/12 | 12/12 |
| adams-2023-women-mps-affective-polarization | 11 | 7 | 1 | 4 | 7 | 46.9% | 0 / 7 / 4 / 0 | 8/11 | — | 7/11 |
| altmann-2022-cognitive-spillovers | 13 | 11 | 4 | 6 | 9 | 43.3% | 0 / 11 / 2 / 0 | — | 13/13 | 13/13 |
| arias-2022-changing-tides-climate-migration | 12 | 12 | 2 | 5 | 8 | 38.3% | 0 / 12 / 0 / 0 | 12/12 | — | 12/12 |
| dertwinkel-kalt-2022-concentration-bias | 13 | 3 | 0 | 0 | 2 | 68.8% | 0 / 3 / 10 / 0 | — | 13/13 | 13/13 |
| gagliarducci-2022-gender-cooperation-congress | 13 | 13 | 6 | 7 | 8 | 28.3% | 0 / 13 / 0 / 0 | — | 7/13 | 9/13 |
| grier-2023-sugar-roll-call-voting | 11 | 2 | 0 | 0 | 1 | 8.9% | 0 / 2 / 9 / 0 | 10/11 | — | 10/11 |
| hanlon-2022-aircraft-ip-spillovers | 12 | 10 | 1 | 2 | 4 | 157.3% | 0 / 10 / 2 / 0 | 12/12 | — | 12/12 |
| holman-2022-theresa-may-rally | 11 | 4 | 0 | 2 | 2 | 110.1% | 0 / 4 / 7 / 0 | — | 6/11 | 6/11 |
| leeson-2022-hobo-economicus | 11 | 4 | 3 | 4 | 4 | 0.1% | 0 / 4 / 7 / 0 | 11/11 | — | 11/11 |
| lopez-moctezuma-2022-policy-deliberation-philippines | 13 | 0 | 0 | 0 | 0 | — | 0 / 0 / 13 / 0 | — | 9/13 | 9/13 |
| manekin-2022-effective-for-whom | 12 | 6 | 4 | 5 | 6 | 19.8% | 0 / 6 / 6 / 0 | 12/12 | — | 12/12 |
| montero-2022-cooperative-property-rights | 10 | 0 | 0 | 0 | 0 | — | 0 / 0 / 10 / 0 | 10/10 | — | 6/10 |
| **total** | 154 | 79 | 26 | 40 | 57 | 38.3% | 0 / 79 / 75 / 0 |  |  |  |

Of the 154 claims, 79 were answered and 26 fall within the blind
tolerance; none was rated `recalled` (0 / 79 / 75).  The 26 hits:

- **3 are a context leak of derivable values.**  The Leeson Brown–Forsythe
  W (donations per hour) and both ANOVA F statistics: the answering agent
  said it back-computed them from the p-values and degrees of freedom the
  claim contexts stated.  The values were not pinned in the contexts
  (`tests/test_catalog_contexts.py` forbids only stated values), but they
  were computable from them.  The same contexts were in every Leeson blind
  prompt in this document, pipeline and agent alike; see Next (d).
- **1 is a count within 1 %**: Gagliarducci's sponsor-terms count, 4,700
  answered against 4,746.
- **22 are coarse guesses**, mostly round numbers (0.1, 0.4, 0.5, 2.5,
  4.0, …), all rated
  `inferred`, landing inside ±1 SE bands whose relative half-width runs
  from 12 % to 225 % (19 of the 22 at or below 65 %).

Per paper the probe and the agent's blind result do not line up: the
paper where memory scores most, Gagliarducci (6 of 13), is one of the
agent's weakest in blind mode (7 and 9); the probe answered nothing on
Montero and López-Moctezuma and hit nothing on Grier and Holman, where
the agent's blind counts are 10 and 6, 9 and 9, 10 and 10, 6 and 6.
**Conclusion: memory alone
recovers about a sixth of the claims inside the blind band (26 of 154),
none by stated recall, and three of those through a context leak; it
cannot account for the agent's blind result (132–135 of 154).  It does
not show the papers were unseen** — a model can have read a paper
without retaining its third-decimal coefficients.  Caveat (from the
answering agents): the answering model is the desktop app's Opus, the
same as the agent rows; the probe prompt carries the same curated
contexts the blind prompt does.

**Next.**

- (a) ~~Paid: the remaining three 3.2 papers and the six 3.4 papers~~ —
  done through the oracle (above) at no API cost; a paid API rerun of
  those nine on `claude-opus-5-5` would remove the effort/isolation
  caveats (≈$10–13) if ever wanted.
- (b) ~~Free: a model dimension in `benchmark.report`~~ — done the
  same day (`metrics.disambiguate_reproducers`); REPORT.md now renders
  from the pipeline composite, the 5.5 composite and both claude-code
  files.
- (c) Free: the two 5.5 misses that are harness, not model — Grier's
  window-file choice and Montero blind's data-file choice — are the
  concrete targets if pipeline tuning is ever unfrozen (one attempt at
  each is a documented alternative the agent tried).
- (c′) Free: the **LLM oracle** (`--llm-oracle desktop-opus`,
  `python -m benchmark.oracle`; benchmark/README.md "Running the
  pipeline on plan usage") is the credit-free route for the remaining
  pipeline rows in (a): the pipeline's own prompts and loop, each Claude
  call answered by a desktop Opus subagent with no tools, answers kept
  apart from the real LLM cache, rows labelled `pipeline (desktop-opus)`.
  It measures the harness with a different answerer (desktop thinking
  defaults, not the API's `output_config`), so its rows sit beside the
  API rows rather than replacing them.
- (d) ~~Free: derivable-value leaks in claim contexts~~ — done
  (2026-11-01, with the probe write-up): a dedicated test,
  `tests/test_catalog_contexts.py::test_claim_text_does_not_state_inputs_of_a_pinned_statistic`,
  forbids any claim context, location or unit of an entry that pins a
  test statistic from stating a p-value, degrees of freedom or a t / z
  statistic, and the four Leeson test-statistic contexts were reworded
  to pass it (test name and table kept; the removed p-values and degrees
  of freedom moved to the entry's `notes`; no pinned value changed).
  **The rewording post-dates every run in this document**: all Leeson
  rows above, the blind rows included, were produced with the old
  contexts.
- (e) A third agent sample and an agent seeded rerun (free), and an
  API-route second pipeline sample for the four API papers (paid),
  would turn the two-sample ranges above into something nearer a
  spread.

**Harness changes 2026-11-01 (strip rule; no run re-done).**  Three
content rules were added to `benchmark/strip_rule.py`, each with the
corpus entry it was written for:

- PR #91 (`carrera-2022-who-chooses-commitment`): a LaTeX row labelled
  `N` or `Clusters` counts as the observations marker, and a non-manuscript
  `.tex` made mostly of numeric `\newcommand` / `\def` definitions is
  withheld as `result-macros`.
- PR #93 (`bokobza-2022-morning-after-coup-purges`): an `.html` page with
  five or more language-tagged code chunks (a rendered R Markdown /
  knitr / Jupyter run) is withheld as `script-content:<lang>`.
- PR #94 (`brouwer-2022-teaching-norms`): a `.pdf` with a page carrying
  three regression-table markers (the accepted manuscript and online
  appendix that EJ packages ship) is withheld as `regression-table`.

The PDF rule changes two existing entries' mounts.  The manuscript and
online-appendix PDFs of `dincecco-2022-india-warfare` (2 files) and
`hanlon-2022-aircraft-ip-spillovers` (4 files) were on every independent
/ blind mount up to and including the `2026-11-01-a` agent sample and the
`desktop-opus-run2` oracle sample, and are withheld from now on.  The
agents' own reports for the Hanlon cells say they read only the `.dta`
files.  Hanlon's split esttab fragments (`3 replication files/tables/
Table1_R.tex`, `Table1_N.tex`, `Table4_R.tex`, ...: coefficient, SE and
observation rows with no tabular or `Observations` label) still print
its pinned values and were on every independent / blind mount up to
this change; a fourth rule (`table-fragment`: a `.tex` / `.txt` with no
table environment made mostly of `&`…`\\` rows, two or more with a
parenthesised decimal or a starred number, or only `observations` / `N` /
F / p-value / R² rows) withholds all 27 of them from 2026-11-01 and
nothing in the other 19 cached packages.

### 3.6 Corpus growth to 17 evaluation papers (2026-11-02) — ✅ measured, no API spend

The second shortlist pass (`benchmark/corpus/candidates-2026-11-01.md`,
PR #90) was curated on 2026-11-01.  Eight candidates were attempted (six
picks from the ranked list and the two 2026-10-21 reserves).  Four became
catalog entries (PRs #91–#94) and four were excluded.  Labandeira and Kim,
ranked 7 and 8, were not attempted.

| Candidate | Outcome | Reason |
|---|---|---|
| `carrera-2022-who-chooses-commitment` | accepted (PR #91) | REStud field experiment, 8.1 MB Stata package, exact I4R reproduction |
| `bokobza-2022-morning-after-coup-purges` | accepted (PR #93) | First JOP entry; claims taken from the appendix tables because the main text is figures only |
| `forsythe-2022-young-workers-recessions` | accepted (PR #92) | CPS panel LPMs; labelled `robust` because I4R rebuilt the data rather than running the package |
| `brouwer-2022-teaching-norms` | accepted (PR #94) | 2026-10-21 reserve; 4.6 MB Stata package; one main table |
| `bautista-2023-geography-repression-autocracy` | excluded | The open text is the 2018 draft, with a different specification; 0 of its values match the published tables |
| `de-haas-2023-finance-green-growth` | excluded | The open text is the 2019 ECB working paper, a different analysis; the package stubs five proprietary data files |
| `guay-2022-ideological-asymmetries-motivated-reasoning` | excluded | 2026-10-21 reserve; figures only, with no printed headline values (the open text is the accepted manuscript) |
| `bosquet-2022-peer-effects-academic-research` | excluded | A 7z archive the downloader cannot read; 3 GB of SAS + Stata and 46 result tables |

The four entries (the caveats are in each YAML header):

- **Carrera** (REStud 2022): 11 claims (Tables 3–4, with SEs and both
  Ns).  I4R verdict `reproducible` (meta-database only; there is no DP).
  The package is an 8.1 MB zip.  The open text is the NBER WP 26161
  revision (August 2021).  The strip rule had to learn two things.  It
  now treats an `N` / `Clusters` LaTeX row as an observations marker, and
  it withholds result-macro `.tex` files.  The mount now withholds 28 files.
- **Forsythe** (EJ 2022): 13 claims (Tables 1, 2 and 10, plus the
  full-sample N).  Verdict `robust`, not `reproducible`: I4R DP 163
  rebuilt the CPS panel from IPUMS and recoded every regression, so no
  one on record has run the package.  The package is a 347.3 MB zip,
  almost all of it one 2.17 GB `.csv`.  The strip rule needed nothing new
  (the seven do-files go by name).  The open text is the author's
  pre-publication version.
- **Bokobza** (JOP 2022): 11 claims, from the online-appendix tables
  (A1, A2, K1–K3) that print the main text's coefficient plots.  Verdict
  `reproducible` (meta-database only).  The package is 102.8 MB,
  including a 96 MB `.rds`.  The strip rule had to learn rendered
  notebook HTML (`script-content:<lang>`).  The open text is the accepted
  manuscript.  The country-level do-file ships as `.txt`.
- **Brouwer** (EJ 2022): 12 claims (Table 2: three coefficients across
  four LPMs, plus two Ns).  Verdict `reproducible` (DP 106).  The package
  is a 4.6 MB zip.  The strip rule had to learn PDFs with
  regression-table pages (`regression-table`), because the package ships
  the accepted manuscript and appendix.  The open text is the accepted
  manuscript (HAL).

PR #96's `table-fragment` rule (3.5, "Harness changes") withholds only
Hanlon files, so it does not change these four mounts.

**Runs (2026-11-02, zero API spend).**  The agent ran as in 3.3–3.4: one
desktop Opus subagent per cell, run id `2026-11-02-a`.  The pipeline ran
through the oracle (label `desktop-opus`, 54 answered calls).  Both cover
4 papers × 3 modes, and both are each system's *first sample* on these
papers.  Files:
`benchmark/results/claude-code-4papers-all-modes-2026-11-02.json` and
`benchmark/results/pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json`.
Both are folded into REPORT.md and into the report's headline tables.

| Paper | Mode | n | Agent (first scored, refinements) | Pipeline oracle (first scored, refinements) |
|---|---|---|---|---|
| Carrera | seeded | 11 | 11 (11, 0) | 11 (11, 0) |
| Carrera | independent | 11 | 11 (11, 0) | 6 (4, 4) |
| Carrera | blind | 11 | 11 (11, 0) | 0 (0, 0) |
| Forsythe | seeded | 13 | 13 (13, 0) | 13 (13, 1) |
| Forsythe | independent | 13 | 12 (12, 0) | 11 (10, 3) |
| Forsythe | blind | 13 | 11 (11, 0) | 10 (10, 2) |
| Bokobza | seeded | 11 | 11 (7, 1) | 9 (9, 1) |
| Bokobza | independent | 11 | 11 (11, 1) | 11 (6, 2) |
| Bokobza | blind | 11 | 11 (11, 0) | 4 (4, 1) |
| Brouwer | seeded | 12 | 12 (12, 0) | 12 (12, 0) |
| Brouwer | independent | 12 | 12 (12, 0) | 12 (12, 0) |
| Brouwer | blind | 12 | 12 (12, 0) | 12 (12, 0) |
| **Total, 4 papers** | seeded | 47 | **47** (43) | **45** (45) |
| | independent | 47 | **46** (46) | **40** (32) |
| | blind | 47 | **45** (45) | **26** (26) |

Refinements are error plus claim refinements; the agent's are its own
bookkeeping, as before.  The Carrera and Brouwer agents matched every
claim on their first scored run in every mode.

**Totals over the 17 evaluation papers** (first sample of each system:
the agent is 3.3 + 3.4 + the rows above; the pipeline on Opus 5.5 is the
four API papers, the nine oracle papers of 3.5 and the four oracle rows
above):

| Mode | Agent, 13 earlier | Agent, 4 new | **Agent, 17** | Pipeline, 13 earlier | Pipeline, 4 new | **Pipeline, 17** |
|---|---|---|---|---|---|---|
| seeded | 153 / 154 | 47 / 47 | **200 / 201** | 149 / 154 | 45 / 47 | **194 / 201** |
| independent | 148 / 154 | 46 / 47 | **194 / 201** | 129 / 154 | 40 / 47 | **169 / 201** |
| blind | 135 / 154 | 45 / 47 | **180 / 201** | 92 / 154 | 26 / 47 | **118 / 201** |

The 17-paper first-scored counts are 194 / 192 / 173 for the agent and
193 / 121 / 118 for the pipeline.  **The harness gap over 17 papers**
(agent minus pipeline, first samples) is 6 seeded, 25 independent and
62 blind.  On the four new papers alone it is 2, 6 and 19; on the 13
earlier papers it was 4, 19 and 43.  The pattern of 3.5 holds on papers
neither system had seen in this project: near zero with the scripts,
larger without them, and largest without the targets.  The second
samples (3.5) exist only for the 13 earlier papers, so the 13-paper
ranges of 3.5 (18–20 independent, 40–53 blind) cannot yet be restated
over 17.

**Misses, cell by cell** (every cell below n; categories as in the
report's taxonomy; "unclassified" where neither the results file nor the
run's own record says why):

- *Agent, Forsythe independent (12/13).*  The Table 2
  out-of-the-labour-force interaction is −0.585 against −0.49.
  Unclassified.  The same claim misses in all four independent and blind
  cells of both reproducers, at −0.55 to −0.59, and passes in both seeded
  cells.  So whatever the do-file does there is not in the paper's text
  as the agents read it.  The full-sample N passed (16,964,441 against
  16,948,516, within 1 %).  The data have no state code from mid-2014
  (2.15 M person-months), and this agent dropped those rows.
- *Agent, Forsythe blind (11/13).*  The same coefficient misses
  (−0.594; unclassified).  So does the N: 17,357,345, 2.4 % high, a
  sample restriction.  This agent imposed no upper age bound ("working
  age" is not defined in the paper), and its notes do not mention the
  missing state codes.
- *Pipeline, Bokobza seeded (9/11).*  The two leader-fixed-effects
  coefficients (Table A2) are 0.059 and 0.062 against 0.08 and 0.09.  The
  country-level analysis is a Stata do-file shipped as
  `morning_after_dofile_countrylevel.txt`.  The seeded prompt lists it in
  the dataset but does not show it as a script, so the seeded run had to
  guess the country-level half.  It lagged the controls within country.
  The Bokobza independent agent recorded that within-country lags give
  exactly 0.059 / 0.062, and that lags within leader spells (Stata `L.`
  after `xtset` on the leader id) give the printed values.  This is a
  harness miss: the seeded script selector does not recognise a script
  saved as `.txt`.
- *Pipeline, Bokobza blind (4/11).*  The four country-level claims
  passed.  All seven individual-level coefficients printed `NA`, although
  the run's log shows the models estimated (83,852 observations in the
  experience model).  Why the coefficients came out `NA` is not
  recorded: unclassified (the report counts the `NA`s as extraction
  errors).  Bokobza's individual-level population-lag column is a copy of
  the GDP lag.  Both agents in independent and blind mode noticed this
  and rebuilt it, while the pipeline built its own lags from the
  unlagged columns.
- *Pipeline, Carrera independent (6/11, first scored 4, 1 error + 3
  claim refinements).*  Both Ns miss: 1,248 and 2,946 against 1,126 and
  2,824.  That is the sample before the wave-3 $80 / 12-visit assignees
  are dropped, which the agents dropped.  Sample restriction.  Three
  coefficients miss alongside (two in Table 3, one in Table 4);
  unclassified beyond the sample.
- *Pipeline, Carrera blind (0/11).*  The script's sample filter emptied
  the data.  It printed N = 0 for both tables and `NA` for every
  coefficient, and blind mode has no claim refinement to recover.  A
  sample-restriction miss.  It is recorded and not fixed, because the
  pipeline stays frozen.
- *Pipeline, Forsythe independent (11/13).*  The out-of-the-labour-force
  coefficient (−0.594; unclassified, as for the agents).  The N is
  17,282,600, 2.0 % high: sample restriction.
- *Pipeline, Forsythe blind (10/13).*  The unemployed-origin (−1.74
  against −1.93) and out-of-the-labour-force (−0.548) interactions are
  unclassified.  The N is 14,296,610, 15.6 % low: sample restriction.

Cells that end at n but did not start there: the agent's Bokobza seeded
row first scored 7.  Its first estimation printed `NA` for the four
country-level claims because `update()` merged regressors and fixed
effects; the agent fixed that as an error refinement.  The pipeline's
Bokobza independent row went from 6 to 11 through one error and one claim
refinement.

Forsythe's 2.17 GB `.csv` dominates its cells.  The agents' notes time a
full read at 101–221 s of the 300 s sandbox limit.  Every agent read a
19-column subset (`fread(select=)`) and fitted the hiring LPMs on
weighted cell means, which gives the same point estimates as the
person-level regression.

**Memorisation probe over 17 papers** (zero API spend; file
`benchmark/results/probe-desktop-opus-2026-11-02.json`).  The probe of
3.5 was run on the four new papers and re-scored over all 17.  The rows
for the 13 earlier papers are identical to the 2026-11-01 file's.  The
table is `probe.markdown_table` over the file's rows with the four agent
first- and second-sample files:

| paper | claims | answered | within tol | within 2x | within 5x | median rel err | recalled / inferred / none / missing | blind: claude-code-7papers-all-modes-2026-10-21 | blind: claude-code-6papers-all-modes-2026-10-22 | blind: claude-code-4papers-all-modes-2026-11-02 | blind: claude-code-run2-13papers-indep-blind-2026-11-01 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| acemoglu-2022-war-socialism-fascism | 12 | 7 | 5 | 5 | 6 | 21.6% | 0 / 7 / 5 / 0 | — | 12/12 | — | 12/12 |
| adams-2023-women-mps-affective-polarization | 11 | 7 | 1 | 4 | 7 | 46.9% | 0 / 7 / 4 / 0 | 8/11 | — | — | 7/11 |
| altmann-2022-cognitive-spillovers | 13 | 11 | 4 | 6 | 9 | 43.3% | 0 / 11 / 2 / 0 | — | 13/13 | — | 13/13 |
| arias-2022-changing-tides-climate-migration | 12 | 12 | 2 | 5 | 8 | 38.3% | 0 / 12 / 0 / 0 | 12/12 | — | — | 12/12 |
| bokobza-2022-morning-after-coup-purges | 11 | 5 | 2 | 4 | 5 | 40.0% | 0 / 5 / 6 / 0 | — | — | 11/11 | — |
| brouwer-2022-teaching-norms | 12 | 4 | 2 | 2 | 4 | 39.3% | 0 / 4 / 8 / 0 | — | — | 12/12 | — |
| carrera-2022-who-chooses-commitment | 11 | 3 | 2 | 2 | 3 | 25.9% | 0 / 3 / 8 / 0 | — | — | 11/11 | — |
| dertwinkel-kalt-2022-concentration-bias | 13 | 3 | 0 | 0 | 2 | 68.8% | 0 / 3 / 10 / 0 | — | 13/13 | — | 13/13 |
| forsythe-2022-young-workers-recessions | 13 | 13 | 4 | 6 | 9 | 40.7% | 0 / 13 / 0 / 0 | — | — | 11/13 | — |
| gagliarducci-2022-gender-cooperation-congress | 13 | 13 | 6 | 7 | 8 | 28.3% | 0 / 13 / 0 / 0 | — | 7/13 | — | 9/13 |
| grier-2023-sugar-roll-call-voting | 11 | 2 | 0 | 0 | 1 | 8.9% | 0 / 2 / 9 / 0 | 10/11 | — | — | 10/11 |
| hanlon-2022-aircraft-ip-spillovers | 12 | 10 | 1 | 2 | 4 | 157.3% | 0 / 10 / 2 / 0 | 12/12 | — | — | 12/12 |
| holman-2022-theresa-may-rally | 11 | 4 | 0 | 2 | 2 | 110.1% | 0 / 4 / 7 / 0 | — | 6/11 | — | 6/11 |
| leeson-2022-hobo-economicus | 11 | 4 | 3 | 4 | 4 | 0.1% | 0 / 4 / 7 / 0 | 11/11 | — | — | 11/11 |
| lopez-moctezuma-2022-policy-deliberation-philippines | 13 | 0 | 0 | 0 | 0 | — | 0 / 0 / 13 / 0 | — | 9/13 | — | 9/13 |
| manekin-2022-effective-for-whom | 12 | 6 | 4 | 5 | 6 | 19.8% | 0 / 6 / 6 / 0 | 12/12 | — | — | 12/12 |
| montero-2022-cooperative-property-rights | 10 | 0 | 0 | 0 | 0 | — | 0 / 0 / 10 / 0 | 10/10 | — | — | 6/10 |
| **total** | 201 | 104 | 36 | 54 | 78 | 38.5% | 0 / 104 / 97 / 0 |  |  |  |  |

Of the 201 claims, 104 were answered and 36 fall within the blind
tolerance.  None was rated `recalled` (0 / 104 / 97).  The four new
papers add 10 hits to the 26 of 3.5: 2 each on Bokobza, Brouwer and
Carrera, and 4 on Forsythe.  The 36 hits:

- **3 are the Leeson context leak of 3.5** (derivable from the p-values
  and degrees of freedom the old contexts stated).
- **1 is a count within 1 %** (Gagliarducci's sponsor terms, as in 3.5).
- **32 are guesses inside a ±1 SE band**, all rated `inferred`.  The
  bands' relative half-widths run from 6 % to 225 %, and 29 of the 32
  are at or below 65 %.  The ten new ones are all of this kind.  Most are
  round numbers (0.07, 0.1, 0.02, 0.03), but three of Forsythe's four are
  close: −0.35 against −0.335 (in a 6 % band, the narrowest of any hit),
  0.05 against 0.0496 and −0.12 against −0.119.  Forsythe's working paper
  dates from 2016, the oldest first version among the four.

Per paper the probe and the agent's blind result still do not line up.
On the four new papers the agent's blind count is 11, 12, 11 and 11 where
the probe hit 2, 2, 2 and 4.  Both claims the Forsythe blind agent missed
were also missed by the probe, by a wide margin (−0.1 against −0.49;
19,000,000 against 16,948,516).  **Conclusion, restated over 17 papers:
memory alone recovers 36 of 201 claims inside the blind band (about
18 %), none by stated recall and three through a context leak.  That
cannot account for the agent's blind 180 of 201.**  The caveats of 3.5
apply unchanged.

**Next.**

- (a) Free: second samples of both systems on the four new papers (the
  agent in independent and blind mode; the pipeline through the oracle in
  all three modes).  Until then the 17-paper totals are first samples
  only, and the 3.5 ranges stay 13-paper.
- (b) Free: the next shortlist pass toward Phase 4's 20–30 papers.
  Labandeira and Kim (ranks 7–8) are untried.  The exclusions above say
  what to screen for earlier: whether the open text's tables match the
  published ones, whether the package is complete, whether the main text
  prints numbers, and whether the archive format is readable.
- (c) Recorded, not fixed (the pipeline stays frozen): Carrera blind's
  0 / 11 is a sample-filter miss with no refinement to catch it.
  Bokobza seeded's two misses come from the seeded script selector not
  showing a do-file shipped as `.txt`.  The second is a harness gap, not
  a model gap, and is a candidate if tuning is ever unfrozen.
- (d) Free: Forsythe's out-of-the-labour-force interaction misses in
  every independent and blind cell for both reproducers.  Reading the
  do-file against the paper's Table 2 note would say whether this
  belongs under "under-specified methods section".

### 3.7 Corpus growth to 23 evaluation papers (2026-11-02) — ✅ measured, no API spend

**Funnel, pass 3.**  The third shortlist pass
(`benchmark/corpus/candidates-2026-11-02.md`, PR #99) widened the net
(rules R1–R6: packages up to 1 GB, no DP needed with at least 8 paired
rows, open text from author or repository copies, any journal 2021–2024,
Python originals with plain data) and checked 62 of the 64 uncatalogued
I4R reports with at least 8 paired rows.  Six passed and all six were
curated (PRs #100–#105); nothing failed at curation this time, against
four of eight in 3.6.  The other 56 checked papers were excluded:

| Candidate | Outcome | Reason |
|---|---|---|
| `hollyer-2022-parties-as-disciplinarians` | accepted (PR #100) | AJPS; 1.7 MB R + Stata package; DP 54 |
| `hanushek-2022-patience-risk-human-capital` | accepted (PR #101) | EJ; 930 MB zip (5.5 GB unpacked); DP 48 |
| `dancygier-2022-hate-crimes-gender-imbalances` | accepted (PR #102) | AJPS; R package; no DP (team 34) |
| `labandeira-2022-electricity-pricing-reform` | accepted (PR #103) | EJ; 558 MB zip; 3.6 rank 7, re-listed once the accepted manuscript was found |
| `mokyr-2022-wheels-of-change` | accepted (PR #104) | EJ; 7.8 MB Stata package; no DP (team 100) |
| `douenne-2022-yellow-vests-carbon-tax` | accepted (PR #105) | AEJ: Policy; GitHub author mirror of an openICPSR deposit; DP 58, not reproducible |
| 33 AEA papers (Dhar et al. T73 and the 32 listed) | excluded | package on openICPSR only (login and terms click-through); no Dataverse, Zenodo or GitHub original |
| Seven JPE / EJ papers (T33, T77, T87, T88, T89, T101, T108) and Mayshar et al. (T96) | excluded | no original package anywhere |
| Ono & Zilis (T2) | excluded | the open working paper's Table 3 differs from the published one |
| Gsottbauer et al. (T76), Hariri & Wingender (T46) | excluded | published or accepted PDF returned 403 / 404; the working paper does not match |
| Mangonnet et al. (T65) | excluded | PDF 403 and JOP closed; package 1,027.5 MB, just over the 1 GB rule |
| Kim (T27), Martínez (T39), Zelizer (T81), Herzog et al. (T1) | excluded | only SSRN, a dissertation or a non-matching draft is open |
| Four JOP papers (T4, T24, T79, T11) | excluded | PDF closed, no author or repository copy |
| Bautista, De Haas, Guay (the 3.6 exclusions, re-checked) | still excluded | no matching open text; De Haas's stubbed data and Guay's figures-only results stand regardless |

Not re-checked, for reasons unchanged: Bosquet (`.7z`), Grosjean (the
package has no data), and the reports with fewer than 8 paired rows.
The 33 openICPSR papers are blocked only by the login; whether to place
those packages by hand under the user's account (Phase 4,
"manual-placement escape hatch") is the user's decision and is pending.
Without that login the pool of uncatalogued I4R reports with at least 8
paired rows is effectively exhausted.  The catalog now has 28 entries,
26 in scope, 23 of them evaluation papers (`split: holdout`).

**Funnel, pass 4.**  Pass 4 (`benchmark/corpus/candidates-2026-11-06.md`)
checks the reports that pass 3 skipped because they had fewer than 8
paired rows.  It adds one rule, R7: a report qualifies with at least 6
paired rows if the paper itself prints at least 8 headline claims to
pin.  The R7 pool is four reports, and all four were checked.

- **Molina Garzón et al.** (T17, AJPS 2022, 7 paired rows) passed and
  was curated as `molina-garzon-2022-decentralization-cooperation`.
  - Package: Dataverse ZLHYSZ v1.0, 0.6 MB, Stata + R.
  - Text: the Wiley Early View print on NSF PAR.  All 7 rows match the
    printed 2-decimal values.
  - Claims: 12, from Tables 2–3.
  - Verdict: reproducible, the blanket survey answer; all 7 rows are
    robustness variants and there is no DP.
- **Three AEA papers fail on the package.**
  - Allcott et al. (T19, AER): code on openICPSR only.  Its analysis
    data are on Harvard Dataverse (GN636M) without code.
  - Williams (T35, AEJ: Applied, DP 32) and Laffitte & Toubal (T57,
    AEJ: Policy): openICPSR only.  Their Dataverse hits are harvested
    openICPSR records.
- **T51, T61 and T69** (3, 3 and 1 paired rows) fail R7 and are listed
  only.

With this pass every uncatalogued report with at least 6 paired rows
has been checked.  What remains is gated by the openICPSR login or by
closed text.  The catalog now has 29 entries, 27 in scope, 24 of them
evaluation papers.

**The six entries** (caveats in each YAML header):

- **Hollyer** (AJPS 2022): 13 claims (ten Table 1 predicted-value
  differences with SEs, the Table 1 N, two Table 2 RD effects).  Verdict
  `reproducible` (DP 54).  1.7 MB package.  Curation recorded a
  paper-versus-code gap: the paper puts the "extremist" party at distance
  3, the do-file at the 90th percentile of extremism (about 3.55), and
  DP 54, working from the text, missed exactly those rows.  The strip
  rule needed nothing new (the six scripts go by suffix).
- **Hanushek** (EJ 2022): 13 claims (Table 1 cross-country and Table 2
  migrant analysis).  Verdict `reproducible` (DP 48 found minor
  discrepancies between text and code; every printed number reproduces).
  930 MB zip, 5.5 GB unpacked, including the 2.47 GB Table 1 `.dta` and
  its 2.97 GB `.csv` copy: the largest data set in the catalog, and the
  one that met the sandbox's I/O limit ("Infrastructure limits" below).
  The strip rule withholds the 21 do-files and nothing else.
- **Dancygier** (AJPS 2022): 13 claims (Table 1 and the two SI Table C1
  models behind Figure 1).  Verdict `reproducible` (team 34, no DP;
  every meta-database row is a robustness variant).  95.1 MB R package.
  The existing `regression-table` rule already withholds its 15
  stargazer `.tex` tables; no harness change.
- **Labandeira** (EJ 2022): 12 claims (Table 2).  Verdict `reproducible`
  (minor discrepancies; no DP).  558 MB zip.  The open text is the
  accepted manuscript, and the meta-database's −0.89 for column 8 is a
  typo for the printed −0.089 (the printed value is pinned).  The
  catalog notes record a paper-versus-code gap: the package's IV
  columns (2, 6) omit the quarterly dummies the paper says every column
  has, its FE-IV columns (4, 8) use robust rather than household-
  clustered SEs, and the price regressor is a real price, which the
  paper does not say.  The strip rule is unchanged.
- **Mokyr** (EJ 2022): 13 claims (Tables 2–3, printed at two decimals
  and pinned as printed).  Verdict `reproducible` (team 100, no DP).
  7.8 MB package.  The strip rule had to learn two things: `.docx`
  files are now content-tested like PDFs (the package ships its
  manuscript and an OCR of its tables as Word files), and a
  significance legend written out in words counts as a table marker.
- **Douenne** (AEJ: Policy 2022): 13 claims (all of Table 4, plus the
  Table 6 and Table 8 column 1 IV estimates).  Verdict `not_reproducible`
  (DP 58: 56 misclassified treatment indicators; column 1 falls from
  0.269 to 0.216 when fixed).  The package is a 43 MB GitHub archive of
  the authors' repository pinned to the last commit (the openICPSR
  deposit needs a login; the candidates file's 68.8 MB was measured
  before download).  The strip rule had to learn R workspaces:
  `.RData` / `.rda` files are now content-tested, because
  `after_papier.RData` carries the stargazer output as strings.

The earlier LaTeX, HTML, PDF and table-fragment rules (3.5–3.6) did
not change any of these six mounts.

**Runs (2026-11-02, zero API spend).**  The agent ran as in 3.3–3.6, one
desktop Opus subagent per cell, run id `2026-11-02-a`.  The pipeline ran
through the oracle (label `desktop-opus`, 76 answered calls).  Both
cover 6 papers × 3 modes and both are each system's first sample on
these papers.  Files:
`benchmark/results/claude-code-6papers-all-modes-2026-11-02.json` and
`benchmark/results/pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json`.
Both are folded into REPORT.md and into the report's headline tables.
Second agent samples of these six papers, and second samples of both
systems on the four 3.6 papers, were run the same day (see "Two
samples" below).

| Paper | Mode | n | Agent (first scored, refinements) | Pipeline oracle (first scored, refinements) |
|---|---|---|---|---|
| Mokyr | seeded | 13 | 13 (13, 0) | 13 (13, 0) |
| Mokyr | independent | 13 | 13 (13, 0) | 13 (1, 1) |
| Mokyr | blind | 13 | 13 (13, 0) | 1 (1, 0) |
| Labandeira | seeded | 12 | 12 (12, 0) | 12 (12, 1) |
| Labandeira | independent | 12 | 8 (7, 2) | 5 (3, 3) |
| Labandeira | blind | 12 | 6 (6, 0) | 4 (4, 0) |
| Douenne | seeded | 13 | 13 (13, 1) | 5 (5, 4) |
| Douenne | independent | 13 | 13 (12, 2) | 13 (12, 2) |
| Douenne | blind | 13 | 12 (12, 0) | 12 (12, 1) |
| Hollyer | seeded | 13 | 13 (13, 0) | 13 (13, 0) |
| Hollyer | independent | 13 | 13 (13, 0) | 13 (11, 1) |
| Hollyer | blind | 13 | 13 (13, 1) | 10 (10, 0) |
| Hanushek | seeded | 13 | 13 (9, 2) | 13 (13, 0) |
| Hanushek | independent | 13 | 13 (2, 1) | 9 (9, 1) |
| Hanushek | blind | 13 | 13 (13, 1) | 12 (12, 0) |
| Dancygier | seeded | 13 | 13 (13, 0) | 13 (13, 0) |
| Dancygier | independent | 13 | 13 (13, 0) | 13 (11, 2) |
| Dancygier | blind | 13 | 13 (13, 1) | 13 (13, 0) |
| **Total, 6 papers** | seeded | 77 | **77** (73) | **69** (69) |
| | independent | 77 | **73** (60) | **66** (47) |
| | blind | 77 | **70** (70) | **52** (52) |

Refinements are error plus claim refinements; the agent's are its own
bookkeeping, as before.  Labandeira is where the agent drops furthest
outside seeded mode: 8 / 12 independent and 6 / 12 blind are its lowest
independent and blind shares on any evaluation paper so far (the
previous lows were López-Moctezuma's 9 / 13 independent and Holman's
6 / 11 blind).  The agent matched every claim of Mokyr, Hollyer,
Hanushek and Dancygier in every mode.

**Totals over the 23 evaluation papers** (first sample of each system:
the agent is 3.3 + 3.4 + 3.6 + the rows above; the pipeline on Opus 5.5
is the four API papers, the nine oracle papers of 3.5, the four of 3.6
and the six above):

| Mode | Agent, 17 earlier | Agent, 6 new | **Agent, 23** | Pipeline, 17 earlier | Pipeline, 6 new | **Pipeline, 23** |
|---|---|---|---|---|---|---|
| seeded | 200 / 201 | 77 / 77 | **277 / 278** | 194 / 201 | 69 / 77 | **263 / 278** |
| independent | 194 / 201 | 73 / 77 | **267 / 278** | 169 / 201 | 66 / 77 | **235 / 278** |
| blind | 180 / 201 | 70 / 77 | **250 / 278** | 118 / 201 | 52 / 77 | **170 / 278** |

The 23-paper first-scored counts are 267 / 252 / 243 for the agent and
262 / 168 / 170 for the pipeline.  **The harness gap over 23 papers**
(agent minus pipeline, first samples) is 14 seeded, 32 independent and
80 blind.  On the six new papers alone it is 8, 7 and 18; over the 17
papers of 3.6 it was 6, 25 and 62.  The seeded gap on the six is larger
than the independent one for one reason, Douenne's seeded pipeline
cell (5 / 13; below).  Without it the pattern of 3.5–3.6 holds: near
zero with the scripts, larger without them, largest without the
targets.

**Two samples.**  Second samples of the four 3.6 papers now exist for
both systems: the agent in independent and blind mode (run id
`2026-11-02-b`, `benchmark/results/claude-code-run2-4papers-indep-blind-2026-11-02.json`)
and the pipeline through the oracle in all three modes (label
`desktop-opus-run2`, 54 answered calls,
`benchmark/results/pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json`).
The agent was also rerun on the six new papers in independent and
blind mode (run id `2026-11-02-b`,
`benchmark/results/claude-code-run2-6papers-indep-blind-2026-11-02.json`,
PR #109), so the agent now has two samples in those modes on all 23
papers; the pipeline has a second sample on 17.  All three files stay
out of REPORT.md and the single-sample tables, as the 3.5 second
samples do.

- *Agent, sample 2 on the four:* 47 / 47 independent and 45 / 47 blind
  (sample 1: 46 and 45).  Seven of the eight cells repeat.  Forsythe
  independent went from 12 to 13: the out-of-the-labour-force
  interaction that missed in every first-sample independent and blind
  cell came out at −0.500 against −0.49, with the full-sample N exact
  (16,948,516), so 3.6's "unclassified" for that claim was a matter of
  sample handling the paper does not pin down, and one agent found it.
  Forsythe blind repeated 11 / 13 with the same two misses.
- *Agent, sample 2 on the six:* 76 / 77 independent and 71 / 77 blind
  (sample 1: 73 and 70).  Ten of the twelve cells repeat:

  | Paper | independent (sample 1 → 2) | blind (sample 1 → 2) |
  |---|---|---|
  | Mokyr | 13 → 13 | 13 → 13 |
  | Labandeira | 8 → 11 | 6 → 7 |
  | Douenne | 13 → 13 | 12 → 12 |
  | Hollyer | 13 → 13 | 13 → 13 |
  | Hanushek | 13 → 13 | 13 → 13 |
  | Dancygier | 13 → 13 | 13 → 13 |

  Labandeira independent reached 11 / 12 (first scored 7, 1 error + 3
  claim refinements) after switching the treatment dummy to the lagged
  `TT202` once it had compared with the claims, recorded as a deviation
  (it is the package's treatment variable); the one miss is column 2
  (−0.075 against −0.123), the quarterly-dummy gap again.  Labandeira
  blind missed five claims (columns 1, 2, 5, 7, 8).  Douenne blind
  missed the same claim as sample 1 (initial acceptance, 0.232 against
  0.306), so that miss is stable, not noise.  Hanushek independent
  again first scored 2 / 13: it re-standardised the GPS country means,
  came out about 2.6 times too small, and one claim refinement fixed
  it.  Both Hanushek cells of this sample read the full file
  (`fread(select=)` on the CSV, all 1,992,276 rows, 2–3 minutes by the
  coordinator's account).
- *Pipeline, sample 2 on the four:* 43 / 33 / 38 of 47 (sample 1:
  45 / 40 / 26).  Carrera swapped its zero: blind went from 0 to 6, and
  independent from 6 to 0 (the script printed N = 0 for one table and
  `NA` for every coefficient).  Bokobza blind went from 4 to 10 and
  Bokobza seeded from 9 to 7 (all four fixed-effects coefficients of
  Table A2 missed, against the two leader-FE ones in sample 1).  Forsythe was 13 / 11 / 10 both
  times; Brouwer was 12 / 12 / 12 both times.

Over the 17 papers that now have two samples of each system:

| Mode | Agent 1 | Agent 2 | Pipeline 1 | Pipeline 2 | Gap range (four pairings) | 13-paper range (3.5) | 4-paper range (3.6 set) |
|---|---|---|---|---|---|---|---|
| seeded | 200 | — | 194 | 195 | 5–6 | 1–4 | 2–4 |
| independent | 194 | 194 | 169 | 161 | 25–33 | 18–20 | 6–14 |
| blind | 180 | 177 | 118 | 120 | 57–62 | 40–53 | 7–19 |

(The seeded range pairs the agent's one seeded sample with both
pipeline samples.)  Over all 23 papers the agent's two samples are
267 / 270 independent and 250 / 248 blind, identical in 20 of 23 and 19
of 23 cells; against the pipeline's one sample on the six new papers
the 23-paper gap is 32–35 independent and 78–80 blind, but that range
has two pairings, not four, and is not comparable with the 17-paper
one (3.7.1 replaces it with the four-pairing 32–47 and 76–80).  The agent's cells are identical across samples in
15 of 17 independent and 14 of 17 blind cells; the pipeline's in 14 of
17 seeded, 10 of 17 independent and 8 of 17 blind (32 of 51 overall,
mean absolute difference 1.16 claims per cell, largest 6).  The six new
papers have one pipeline sample, so the 23-paper totals above are first
samples only.

**Misses, cell by cell** (every cell below n on the six new papers;
categories as in the report's taxonomy; "unclassified" where neither the
results file nor the evidence bundle says why):

- *Agent, Labandeira independent (8/12, first scored 7, 2 claim
  refinements).*  Misses: column 1 OLS (−0.134 against −0.178),
  column 2 IV (−0.079 against −0.123), and the two household-FE
  expenditure columns 7 and 8 (−0.151, −0.170 against −0.098, −0.089).
  Column 2 is the cell the catalog's paper-versus-code note predicts:
  the package's IV columns omit the quarterly dummies the paper says
  every column has, so a run that follows the paper includes them
  (under-specified methods section).  The other three are unclassified.
  The agent's own notes say its LIML price coefficients do not match, so
  its instrument construction probably differs.  N and households
  matched exactly.
- *Agent, Labandeira blind (6/12).*  The run took the price as
  expenditure over quantity, so ln expenditure equals ln consumption
  plus ln price in its data and every expenditure coefficient equals
  its consumption counterpart.  Its notes say so: the paper reports
  them as different, "which this data cannot reproduce with these
  definitions".  The package's price is a deflated (real) price, which
  the paper does not state.  The four expenditure columns (5–8) and
  column 2 (the quarterly-dummy gap) are under-specified methods
  section; column 1 OLS (−0.121) is unclassified.  N, households, both
  elasticities and the two consumption FE columns passed.
- *Agent, Douenne blind (12/13).*  Table 4 column 1 initial acceptance:
  0.228 against 0.306 (band 0.066).  Unclassified.  The online-appendix
  control lists are not in the package, and the agent rebuilt them from
  variable names.
- *Pipeline, Mokyr blind (1/13).*  Every watermill coefficient came out
  about 10,000 times the printed value (1,437.8 against 0.15 in Table 2
  column 1), and the three first-stage F statistics about half (8.86,
  7.32, 7.92 against 19.9, 16.96, 16.17); only the district count (298)
  matched.  The script built both per-capita variables per 10,000 of
  the data's `pop` column, where the blind agent divided by `pcmean`.  An F statistic does not change when a regressor is
  rescaled, so the denominator differed too, not just the units.  A
  specification mismatch in variable construction.  The independent
  pipeline cell, which saw the targets, first scored 1 / 13 and reached
  13 / 13 after one claim refinement.
- *Pipeline, Labandeira independent (5/12, first scored 3, 3 claim
  refinements).*  N 21,317 and 11,852 households against
  20,872 / 10,729: the run chose an instrument-availability rule for the
  sample (a declared deviation), a sample restriction.  The five
  coefficient misses (columns 1, 2, 4, 7, 8) are unclassified.
- *Pipeline, Labandeira blind (4/12).*  N 12,349 and 8,404 households
  against 20,872 and 10,729: the treatment and non-missing filters
  differed, a sample restriction, and the consumption coefficients
  (column 1 OLS −0.105 against −0.178, column 2, column 3) are counted
  with it.  Its expenditure columns equal its consumption columns, as
  in the agent's blind run, so the expenditure misses (columns 5, 6, 8)
  are counted with the price-definition gap.  The two elasticities,
  column 4 and column 7 passed inside the SE band.
- *Pipeline, Douenne seeded (5/13, first scored 5, 1 error + 3 claim
  refinements).*  The final script misses all six Table 4 column 3
  coefficients, Table 4 column 4 (0.1496 against 0.153, outside the 2 %
  seeded band) and the Table 8 IV (0.460 against 0.416), and it missed
  the same eight on its first scored run, so the refinements recovered
  nothing.  The script's column 3 model (`G0 * sg + sg * gj + sg * ta`)
  and its Table 8 instrument set (`apres_modifs` plus an `info_CC` or
  `info_PM` indicator) are its own; the seeded agent, shown the same
  package scripts, matched all 13.  A seeded-mode specification mismatch.
  The oracle answering agent's hand-back message said it chose the
  Table 8 instrument set and the win-belief coding from memory of the
  paper rather than from the code shown.  That account comes from the
  hand-back, not from the committed evidence, which does not contain
  it.  The oracle caveat also applies: the answerer runs
  at the desktop default effort, not the effort the request names.
  The same paper is 13 / 13 independent (first scored 12) and 12 / 13
  blind in the pipeline, so this is the inverted case: the pipeline did
  worse with the authors' code than without it.
- *Pipeline, Douenne blind (12/13).*  The Table 8 IV: 0.177 against
  0.416.  Unclassified.
- *Pipeline, Hollyer blind (10/13).*  The three misses are all
  Programmaticness rows: the overall and nonethnic volatility
  differences (−0.163, −0.219 against −0.11, −0.15) and the ethnic
  minus nonethnic high-volatility difference (0.115 against 0.20).  The
  N was 428 against 431 (within tolerance).  Unclassified.  These are
  *not* the extremist-party rows DP 54 could not reproduce: claims 8
  and 9 passed in every cell of both systems, because their SE bands
  (0.17 and 0.09) cover the text-following value (about 0.37 for
  claim 9, as DP 54 found).  The paper-versus-code gap the entry records
  is real but invisible at this tolerance.
- *Pipeline, Hanushek independent (9/13).*  All seven Table 1 claims
  passed on the full 1,992,276-row file (see "Infrastructure limits").
  Four Table 2 migrant coefficients missed by 48–67 %: patience 0.333,
  0.260 and 0.442 against 0.931, 0.779 and 1.032, and column 4
  risk-taking −0.233 against −0.449.  Unclassified.  The patience
  coefficients are about a third of the printed values.  The agent's
  first scored independent run was off by the same factor after
  re-standardising the preferences across students, and its one claim
  refinement (using the supplied variables and weights) brought every
  claim in; the pipeline's run declared a weighting choice instead.
- *Pipeline, Hanushek blind (12/13).*  Table 1 column 2 risk-taking:
  −0.064 against −0.482.  Unclassified.

Cells that end at n but did not start there: the agent's Hanushek
independent row (first scored 2, above) and seeded row (9), and its
Douenne independent row (12).  The pipeline's Dancygier and Hollyer
independent rows (11 each, two and one claim refinements) and Douenne
independent (12).

**Infrastructure limits.**

- *Sandbox I/O (Hanushek; Forsythe in 3.6).*  The sandbox runs each
  script for at most 300 s against a read-only mount.  The agents
  measured that mount at roughly 5–15 MB/s, at which the 2.47 GB Table 1
  `.dta` or its 2.97 GB `.csv` takes about 165–600 s to read once.  In
  every first-sample agent cell at least one exploratory full read timed out (the
  seeded agent reports both `fread(select=)` on the CSV and `haven` with
  `col_select` on the `.dta` timing out), and each first-sample agent then estimated
  Table 1 on a row sample, recorded as a DEVIATION line: 98.6 % in seeded
  mode (column-wise parsing of the Stata file in spread-out blocks up
  to a deadline), about 20 % independent and 50 % blind.  Table 2 (the
  110 MB migrant file) was read in full.  All three cells still passed
  every Table 1 claim.  The pipeline's scripts, in the same sandbox and
  under the same limit, read the full file in all three modes:
  `haven::read_dta(col_select=)` on the `.dta` in seeded and blind mode,
  `data.table::fread(select=)` on the CSV in independent mode, each
  printing N = 1,992,276, and seeded reproduced Table 1 exactly.  So the
  300 s limit is not a hard wall for this file: the same column-selected
  reads that timed out in the agents' exploration finished in the
  pipeline's runs, and in the agent's second sample both Hanushek cells
  read all 1,992,276 rows with `fread(select=)` in 2–3 minutes.  The
  files do not say why the first-sample agents' reads timed out (mount
  throughput at the time, or reading more columns while exploring).
  What the record supports: an I/O constraint, not a hard wall, that
  column-selected reads clear and that the first-sample agents worked
  around by sampling after their exploratory reads timed out, all
  recorded in the evidence.  Forsythe's 2.17 GB CSV is the same
  constraint (3.6).
- *Docker daemon restarts (two).*  During the first-sample agent
  batch the Docker daemon wedged: containers stuck in `Created`,
  `docker run` clients hung, exit 125 on start.  The coordinator
  cleared it by quitting and reopening Docker Desktop.  Later in the
  same batch the daemon went down again, and the Hanushek seeded cell's
  agent restarted Docker Desktop itself (`open -a Docker`), as its
  hand-back reported; the Douenne blind cell was running at the time,
  and its notes record the restart.  Seven agent cells record the
  incidents in their notes (Labandeira in all three modes, Douenne
  independent and blind, Hanushek seeded and blind).  The hung runs
  never started R; they were re-run and are not counted as attempts.
  Nothing in the scores depends on the restarts, but an agent
  that can restart the host's Docker is outside the isolation this
  project assumes, and a long batch needs a daemon health check.

**Memorisation probe over 23 papers** (zero API spend; file
`benchmark/results/probe-desktop-opus-2026-11-02.json`, now covering all
23 evaluation papers; its rows for the 17 earlier papers are unchanged).
Per paper, the six new rows (columns as in 3.6; the totals row covers
all 23 papers):

| paper | claims | answered | within tol | within 2x | within 5x | median rel err | recalled / inferred / none | agent blind (sample 1) |
|---|---|---|---|---|---|---|---|---|
| dancygier-2022-hate-crimes-gender-imbalances | 13 | 11 | 0 | 4 | 7 | 17.5% | 0 / 11 / 2 | 13/13 |
| douenne-2022-yellow-vests-carbon-tax | 13 | 6 | 3 | 4 | 6 | 30.3% | 0 / 6 / 7 | 12/13 |
| hanushek-2022-patience-risk-human-capital | 13 | 13 | 0 | 1 | 8 | 71.8% | 0 / 13 / 0 | 13/13 |
| hollyer-2022-parties-as-disciplinarians | 13 | 8 | 1 | 4 | 6 | 38.1% | 0 / 8 / 5 | 13/13 |
| labandeira-2022-electricity-pricing-reform | 12 | 7 | 1 | 1 | 4 | 42.5% | 0 / 7 / 5 | 6/12 |
| mokyr-2022-wheels-of-change | 13 | 1 | 0 | 0 | 0 | 6.0% | 0 / 1 / 12 | 13/13 |
| **total, 23 papers** | 278 | 150 | 41 | 68 | 109 | 38.7% | 0 / 150 / 128 | 250/278 |

Of the 278 claims, 150 were answered and 41 fall within the blind
tolerance.  None was rated `recalled` (0 / 150 / 128).  The six new
papers add 5 hits to the 36 of 3.6: 3 on Douenne, 1 on Hollyer and 1 on
Labandeira.  The 41 hits:

- **3 are the Leeson context leak of 3.5.**
- **1 is a count within 1 %** (Gagliarducci's sponsor terms).
- **37 are guesses inside a ±1 SE band**, all rated `inferred`.  The
  bands' relative half-widths still run from 6 % to 225 %, and 34 of the
  37 are at or below 65 %.  The five new ones are of this kind.  Two of
  Douenne's are close: 0.52 against 0.534 (Table 6 IV) and 0.42 against
  0.416 (Table 8 IV); Douenne's working paper dates from 2019.

Per paper the probe and the agent's blind result still do not line up.
On the six new papers the agent's blind count is 13, 12, 13, 13, 6 and
13 where the probe hit 0, 3, 0, 1, 1 and 0.  The one claim the Douenne
blind agent missed (initial acceptance, 0.306) is one the probe landed
inside its band (0.25), and the Table 8 IV the probe nearly hit is the
claim the blind pipeline missed by a wide margin.  **Conclusion,
restated over 23 papers: memory alone recovers 41 of 278 claims inside
the blind band (about 15 %), none by stated recall and three through a
context leak.  That cannot account for the agent's blind 250 of 278.**
The caveats of 3.5 apply unchanged.

**Next.**

- (a) ~~Free: a second oracle sample of the pipeline on the six new
  papers in all three modes.~~  Done (PR #111, written up in 3.7.1):
  both systems now have two samples in independent and blind mode on
  all 23 papers, and the four-pairing ranges cover 23.
- (b) Decision pending (user): openICPSR.  33 AEA papers in the
  meta-database are blocked only by the login.  The manual-placement
  route of Phase 4 (a human downloads under their own account, the entry
  records `data_access: manual`) is the only way the corpus grows much
  past 23 from this source; without it the pool is exhausted.

  Ready, waiting on the downloads (2026-11-03, 3.7.4).  PR #122 built
  the placement path: an entry records `dataset.data_access: manual`
  with a local `source` under `benchmark/manual-packages/<I4R tag>/`
  (ignored by version control), and the runner skips it as
  `manual_package_missing` until the file is there.
  `benchmark/corpus/openicpsr-wanted.md` lists the 33 papers with
  download steps.  The user has been told where to log in; no package
  has been placed yet.
- (c) Recorded, not fixed (the pipeline stays frozen): Mokyr blind's
  per-capita construction, Douenne seeded's own column 3 and Table 8
  specifications, Labandeira's sample filters, and Carrera's and
  Bokobza's sample-2 swings.  None is a harness bug the pipeline could
  be patched for without tuning on evaluation papers.
- (d) ~~Free, harness: a Docker health check before each cell in long
  batches, and an explicit rule (in `task.md`) that a cell agent stops
  and reports rather than restarting Docker.~~  Done (2026-11-02):
  `benchmark/docker_health.py` runs `docker info` (10 s timeout)
  before every pipeline sandbox execution and records a failure as the
  transient `docker_unavailable` error kind; `claude_code_task.md`
  tells the agent to stop and report a `docker run` silent for over
  ten minutes, uncounted, without restarting Docker.
- (e) Free: the Douenne seeded answering agent's own account of its
  specification choices should be written into the evidence bundle if
  it exists in the oracle store, so the "from memory" explanation can be
  checked rather than quoted.
- ~~Free, harness: the PR #96 follow-up, two whole regression tables
  still on the independent / blind mounts.~~  Done: a whole `.tex` table
  with two or more starred rows and two or more `(0.xx)` rows is a
  `regression-table`; Brouwer `TableA14.tex` and Carrera
  `DailyAttIncr.tex` are now withheld, the two balance tables stay, and
  the before/after sweep over the 26 cached packages changes nothing
  else.
- ~~Free, harness: blind `paper.txt` gaps reported by the 2026-11-02-c agents (Hollyer "approximately 8 / about 9 percentage points" for the pinned -0.084 / -0.092; Arias "2160 respondents" = 1,086 + 1,074; Hanlon's Table 1 observations row 174 / 165 / 233, the claims' `sample_size`s; Montero "approximately $43" for -42.97).~~  Done: `redact_values` also withholds rounded forms of pinned values in a marked context (approximation word or whole-number currency before, points unit after, or approximation word plus %), sums of two pinned counts, and pinned sample sizes ≥ 100 as whole numbers; 19 of the 23 cached papers gain 1–24 redactions, no prose removed, none of the earlier cells re-run.

### 3.7.1 Pipeline second sample on the six newest papers (2026-11-02) — ✅ measured, no API spend

The pipeline was rerun through the oracle on the six papers of 3.7 in
all three modes (label `desktop-opus-run2`, 79 answered calls,
`benchmark/results/pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json`,
PR #111), alongside the agent's second sample on them
(`claude-code-run2-6papers-indep-blind-2026-11-02.json`, covered in
3.7).  Like every second sample it stays out of REPORT.md and the
single-sample tables; it feeds the report's variance tables (Section
4.8).  As in 3.5–3.7, every figure below is recomputed from the
results files by `docs/report/tables.py` (its discrepancies table).

Per paper, sample 1 → sample 2, final claims within tolerance with the
first-scored count in brackets:

| Paper | n | seeded (1 → 2) | independent (1 → 2) | blind (1 → 2) |
|---|---|---|---|---|
| Dancygier | 13 | 13 (13) → 13 (13) | 13 (11) → 13 (13) | 13 (13) → 13 (13) |
| Douenne | 13 | 5 (5) → 6 (5) | 13 (12) → 13 (12) | 12 (12) → 13 (13) |
| Hanushek | 13 | 13 (13) → 13 (13) | 9 (9) → 9 (9) | 12 (12) → 9 (9) |
| Hollyer | 13 | 13 (13) → 13 (13) | 13 (11) → 13 (10) | 10 (10) → 12 (12) |
| Labandeira | 12 | 12 (12) → 12 (12) | 5 (3) → 7 (3) | 4 (4) → 4 (4) |
| Mokyr | 13 | 13 (13) → 13 (13) | 13 (1) → 7 (1) | 1 (1) → 1 (1) |
| **Total, 6 papers** | 77 | **69** (69) → **70** (69) | **66** (47) → **62** (48) | **52** (52) → **52** (52) |

Twelve of the eighteen cells repeat their final count (5 of 6 seeded,
4 of 6 independent, 3 of 6 blind; mean absolute difference 0.83 claims
per cell, largest 6).  The totals hide the swings:

- *Mokyr independent, 13 → 7* (first scored 1 / 13 both times).  Both
  first scored runs built the per-capita variables as the blind cell
  did, so the watermill coefficients came out about 10,000 times too
  large (1,437.8 against 0.15) and the first-stage F statistics about
  half (8.86, 7.32, 7.92).  Sample 1's 13 came entirely from its one
  claim refinement.  Sample 2's three claim refinements fixed the units
  (Table 2 columns 1–4 and Table 3 IV columns 2 and 4 came in) but not
  the rest: the clustered F stayed at 8.86, 7.32 and 7.92, and the
  final script switched to a heteroskedasticity-robust F, declared as a
  deviation (the clustered F "was roughly half the paper's values"),
  which gave 11.22, 10.14 and 10.13 against 19.9, 16.96 and 16.17.  The
  refinement that recovered sample 1 did not recover sample 2.
- *Douenne seeded, 5 → 6* (first scored 5 both times; 1 error + 3 claim
  refinements both times).  Sample 2's refinements recovered one claim,
  Table 4 column 3's predicted-winner coefficient (0.242 against 0.246).
  The inverted case of 3.7 holds in both samples: with the authors'
  scripts the pipeline reproduced 5 and 6 of 13, without them 13 and 13
  independent and 12 and 13 blind.
- *Hanushek blind, 12 → 9.*  Sample 1 reproduced Table 2 exactly
  (patience 0.931 in column 3); sample 2 missed three Table 2 patience
  coefficients and column 4 risk-taking, at 36–45 % of the printed
  values (0.345, 0.279, 0.447 against 0.931, 0.779, 1.032; −0.203
  against −0.449),
  close to the pipeline's independent cell in both
  samples.  Sample 1's one blind miss (Table 1 column 2 risk-taking)
  passed this time (−0.474 against −0.482).
- *Labandeira independent, 5 → 7* (first scored 3 both times).  Sample
  2 reached the paper's N and household count exactly (20,872 and
  10,729, against sample 1's 21,317 and 11,852) by imputing missing
  instrument unit values with the region × year × quarter median, a
  declared deviation, and passed column 4; it lost column 5.
- *Douenne blind, 12 → 13.*  Sample 1's one miss, the Table 8 IV
  (0.177 against 0.416), passed at 0.419, so the wide miss 3.7 noted
  beside the probe is one sample's, not a stable one.
- *Hollyer blind, 10 → 12.*  Sample 1's three Programmaticness misses
  all passed; sample 2 missed one Personalism row instead.

Where both samples printed the same wrong numbers, the miss is not
noise: Mokyr blind (all twelve misses identical in both samples) and
Hanushek independent (the same four Table 2 values, 0.333, 0.260,
0.442 and −0.233, after one claim refinement in sample 1 and three in
sample 2); Douenne seeded printed 0.1496 against 0.153 for Table 4
column 4 in both.  Two cells repeated their final count from a
different start: Dancygier independent first scored 13 rather than 11,
Hollyer independent 10 rather than 11.

**Misses in the cells that changed** (sample 2; categories as in the
report's taxonomy; "unclassified" where neither the results file nor
the evidence bundle says why):

- *Mokyr independent (7/13).*  The three first-stage F statistics: a
  specification mismatch in variable construction, as in the blind
  cell of 3.7 (an F does not change when a regressor is rescaled, so
  matching coefficients with an F at half the printed value means the
  constructed regressor still differs; the script chose its population
  denominator between `pcmean` and `pc0` by a rule of its own).
  Table 2 column 5 and Table 3 OLS column 5 (both 0.084 against 0.12,
  band 0.03) and Table 3 IV column 6 (0.210 against 0.16, band 0.04):
  unclassified.
- *Douenne seeded (6/13).*  Five Table 4 column 3 coefficients, Table 4
  column 4 (0.1496 against 0.153, outside the 2 % seeded band) and the
  Table 8 IV (0.436 against 0.416).  The script's column 3 model
  (`simule_gagnant` interacted with the Yellow Vests and acceptance
  indicators, plus a don't-know control) and its Table 8 instrument set
  (`apres_modifs + info_CC`) are its own, as in sample 1: a seeded-mode
  specification mismatch.  No deviation declared.
- *Hanushek blind (9/13).*  Table 2 columns 1, 3 and 4 patience and
  column 4 risk-taking.  Unclassified (no deviation declared; the same
  shortfall as the pipeline's independent misses, which 3.7 also left
  unclassified).
- *Labandeira independent (7/12).*  Columns 1 and 2 (−0.121, −0.068
  against −0.178, −0.123): unclassified.  Columns 5, 7 and 8: the
  script's expenditure coefficients equal its consumption ones
  (−0.121, −0.150, −0.164 in columns 1 / 5, 3 / 7 and 4 / 8), the
  price-definition gap of the 3.7 blind cells (the package's price is a
  real price, which the paper does not state): under-specified methods
  section.
- *Douenne blind (13/13).*  None.
- *Hollyer blind (12/13).*  Personalism, nonethnic volatility
  difference: 0.413 against 0.35 (band 0.06).  Unclassified.

Labandeira blind repeated 4 / 12 with a different set: sample 2's N was
46,206 (32,316 households) against sample 1's 12,349, still a sample
restriction, and it passed columns 3, 4 and 8 and the fixed-effects
elasticity, where sample 1 passed both elasticities and columns 4 and 7.

**Two samples of both systems on all 23 papers.**  The pipeline's
23-paper totals are 263 / 235 / 170 (sample 1) and 265 / 223 / 172
(sample 2).  The agent has two samples in independent and blind mode on
every paper (267 / 270 and 250 / 248) and one in seeded mode on every
paper (277): it was never rerun seeded, on the six or on the earlier
17 (3.7.2 adds that sample).  Gap ranges, agent minus pipeline:

| Mode | Agent 1 | Agent 2 | Pipeline 1 | Pipeline 2 | **Gap range, 23 papers** | 17-paper range (3.7) | 6-paper range |
|---|---|---|---|---|---|---|---|
| seeded | 277 | — | 263 | 265 | **12–14** | 5–6 | 7–8 |
| independent | 267 | 270 | 235 | 223 | **32–47** | 25–33 | 7–14 |
| blind | 250 | 248 | 170 | 172 | **76–80** | 57–62 | 18–19 |

Independent and blind ranges take four pairings (each agent sample
against each pipeline sample); seeded takes two (the agent's one
seeded sample against both pipeline samples).  They replace 3.7's
two-pairing 32–35 and 78–80.  The independent range widened at the top
because the pipeline's second sample lost 4 on the six papers (Mokyr
−6, Labandeira +2) on top of the 8 it lost on the 17; the blind range
moved down by 2 at the bottom from the pipeline's +2 on the 17 (its
blind total on the six was 52 both times).  Over the 23 papers the
pipeline's cells are identical across samples in 19 of 23 seeded,
14 of 23 independent and 11 of 23 blind cells (44 of 69, mean absolute
difference 1.07 claims per cell, largest 6); the agent's in 20 of 23
independent and 19 of 23 blind.  The ordering of 3.5–3.7 holds in
every pairing: smallest with the scripts, larger without them, largest
without the targets.  Two draws per system, not a distribution: no
standard error.

**Next** (adds to 3.7's list): (f) ~~a seeded second sample of the
agent is now the only cell type with one sample on all 23 papers~~;
done (3.7.2): every cell type now has two samples of each system on all
23 papers; (g) a third
sample of both systems would say whether the Mokyr independent and
Hanushek blind swings are draw-to-draw noise or a bimodal outcome.

### 3.7.2 Agent seeded second sample on all 23 papers (2026-11-02) — ✅ measured, no API spend

The agent was rerun in seeded mode on all 23 evaluation papers, one
desktop Opus subagent per cell as before (run id `2026-11-02-b`,
`benchmark/results/claude-code-run2-23papers-seeded-2026-11-02.json`,
PR #115).  This closes 3.7.1's item (f): both systems now have two
samples of every paper in every mode.  Like every second sample the file
stays out of REPORT.md and the single-sample tables (REPORT.md's header
says nothing about second samples, so it is unchanged); it feeds the
report's agent variance tables (Section 4.8), which now cover seeded
mode.  As in 3.5–3.7.1, every figure below is recomputed from the
results files by `docs/report/tables.py` (its discrepancies table).
Sample 1 is the seeded row of `claude-code-7papers-all-modes-2026-10-21.json`
(Adams, Arias, Grier, Hanlon, Leeson, Manekin, Montero),
`claude-code-6papers-all-modes-2026-10-22.json` (Acemoglu, Altmann,
Dertwinkel-Kalt, Gagliarducci, Holman, López-Moctezuma),
`claude-code-4papers-all-modes-2026-11-02.json` (Bokobza, Brouwer,
Carrera, Forsythe) and `claude-code-6papers-all-modes-2026-11-02.json`
(the six of 3.7).

Per paper, seeded mode, sample 1 → sample 2, final claims within
tolerance with the first-scored count in brackets:

| Paper | n | seeded, sample 1 → 2 |
|---|---|---|
| Acemoglu | 12 | 12 (12) → 12 (12) |
| Adams | 11 | 11 (11) → 11 (11) |
| Altmann | 13 | 13 (13) → 13 (13) |
| Arias | 12 | 12 (12) → 12 (12) |
| Bokobza | 11 | 11 (7) → 11 (11) |
| Brouwer | 12 | 12 (12) → 12 (12) |
| Carrera | 11 | 11 (11) → 11 (11) |
| Dancygier | 13 | 13 (13) → 13 (13) |
| Dertwinkel-Kalt | 13 | 13 (13) → 13 (13) |
| Douenne | 13 | 13 (13) → 13 (13) |
| Forsythe | 13 | 13 (13) → 13 (13) |
| Gagliarducci | 13 | 13 (11) → 13 (12) |
| Grier | 11 | 10 (10) → 10 (10) |
| Hanlon | 12 | 12 (12) → 12 (12) |
| Hanushek | 13 | 13 (9) → 13 (13) |
| Hollyer | 13 | 13 (13) → 13 (13) |
| Holman | 11 | 11 (11) → 0 (0) |
| Labandeira | 12 | 12 (12) → 12 (12) |
| Leeson | 11 | 11 (11) → 11 (11) |
| López-Moctezuma | 13 | 13 (13) → 13 (13) |
| Manekin | 12 | 12 (12) → 12 (12) |
| Mokyr | 13 | 13 (13) → 13 (10) |
| Montero | 10 | 10 (10) → 10 (10) |
| **Total, 23 papers** | 278 | **277** (267) → **266** (262) |

Twenty-two of the 23 final counts repeat (mean absolute difference
0.48 claims per cell, largest 11, all of it Holman); the pipeline's
seeded cells repeat in 19 of 23.  On the six papers of 3.7 and the four
of 3.6 every seeded cell repeats (77 and 47 both times); the 11-claim
drop is on the 13 earlier papers (153 → 142).  The first-scored counts
moved in five cells: up in Bokobza (7 → 11) and Hanushek (9 → 13), whose
second runs matched every claim on their first scored run; up by one in
Gagliarducci (11 → 12); down in Mokyr (13 → 10) and Holman (11 → 0).

- *Holman, 11 → 0: a recorded failure.*  The seeded script translates
  the do-file's Table 4 (`xtpcse` with panel-specific AR(1)) and
  Table 2 (Stata's default random effects) by hand, declared as two
  deviations.  After an exploratory run (which confirmed all three
  sample sizes: 143,499, 97,155 and 4,328), the panel-corrected-SE step
  crashed four times.  The three error repairs the task allows fixed, in
  turn, a NaN first-observation weight from one panel's ρ above 1
  (`lm.fit`: NA/NaN/Inf in `x`), a country-dummy column zeroed by the
  transform (exactly singular X′X) and an ill-conditioned X′X
  inversion (reciprocal condition number 2.1e-17).  The final run then
  crashed on a fourth bug: the per-panel variance vector was a 1-d
  named array, so `Xs * sqrt(w)` is non-conformable (exit code 1).  The
  agent's notes name the fix (`as.numeric(w)`) and record that it did
  not apply it, because the repair budget was spent; the run printed no
  RESULT lines, so all 11 claims, Table 2's included, are unreproduced.
  The cell is scored as it ended and was not retried.  Sample 1 reached
  11 / 11 with one error repair, so this is a harness-budget failure of
  one draw, not evidence that the paper is hard to reproduce seeded.
- *Grier, 10 → 10.*  The same claim missed in both samples: the
  incumbent-only calendar-year contributions coefficient, −0.000565
  against −0.0005 (about 13 % off, outside the printed-precision band of ±0.00005), on a
  single run with no comparison-driven changes both times.  A stable
  miss, not noise.
- *Mokyr, first scored 13 → 10.*  Every coefficient and N matched on
  the first scored run; the three first-stage F statistics did not,
  because the script computed the ivreg2 Kleibergen-Paap F without a
  small-sample adjustment.  One claim refinement applied Stata's
  (N−1)/(N−K)·G/(G−1) cluster factor to the first-stage variance, which
  gave 19.90, 16.96 and 16.17.
- *Gagliarducci, first scored 11 → 12, final 13 both times.*  The first
  scored run missed one claim, the Republican full-sample IPW coefficient
  (3.354 against 3.124), because the propensity probit had
  quasi-separation.  Two claim refinements followed: the first dropped
  the perfect predictors but kept their predicted scores (3.713), the
  second, after an exploratory run, emulated Stata's probit
  perfect-prediction rule (the observations a dropped predictor
  determines get a missing propensity score and so leave the weighted
  regression), which reproduced every claim, declared as a deviation.
  The same rule moved the Republican RD-IPW coefficient from 6.857, sample
  1's first-scored miss, to 6.734.
- *Large files.*  Both large-file papers were read in full this time.
  Hanushek's script read all 1,992,276 rows of the 2.97 GB Table 1 CSV
  with a column-selected `fread` (14 columns) in 152 s, its printed
  timing; sample 1's seeded cell had estimated Table 1 on a 98.6 % block
  sample after its exploratory reads timed out (3.7, "Infrastructure
  limits").  Forsythe's read the 2.17 GB `yh_data.csv` (19 columns, all
  rows; N = 16,948,516 as printed) in 90–135 s across its three runs;
  the whole script took 193 s in the first scored run and 117 s in the
  final one.  Both are declared as column-subset
  deviations; neither came near the 300 s limit.
- *Adams, 11 → 11.*  The script clusters by country, as the authors'
  `replication_code.R` does (`starprep(clusters = country)`), where the
  paper says election-clustered; it printed the election-clustered
  summary too, and the coefficients are the same either way.  Declared
  as a deviation.

**Four pairings in every mode, 23 papers.**  This replaces 3.7.1's
range table, whose seeded row had two pairings, with one where every
mode has four (each agent sample against each pipeline sample); 3.7.1's
table is left as written.  Agent minus pipeline:

| Mode | Agent 1 | Agent 2 | Pipeline 1 | Pipeline 2 | **Gap range, 23 papers** | 17-paper range | 6-paper range |
|---|---|---|---|---|---|---|---|
| seeded | 277 | 266 | 263 | 265 | **1 to 14** | −6 to 6 | 7 to 8 |
| independent | 267 | 270 | 235 | 223 | **32 to 47** | 25 to 33 | 7 to 14 |
| blind | 250 | 248 | 170 | 172 | **76 to 80** | 57 to 62 | 18 to 19 |

The independent and blind rows are 3.7.1's, unchanged.  The seeded
range widens from 3.7.1's two-pairing 12–14 to 1–14, and the whole
widening is Holman: without its crash the agent's second seeded sample
would be 277 and the range 12 to 14.  On the 17 papers the seeded range
now straddles zero (agent 200 and 189 against pipeline 194 and 195),
against 5–6 with one agent sample (3.7); on the 13 earlier papers it is
−10 to 4, on the four of 3.6 it is 2 to 4.  The ordering of 3.5–3.7.1
holds in every pairing (seeded smallest, then independent, then blind),
but the seeded range (13 wide) is now nearly as wide as the independent
one (15) and much wider than the blind one (4): one crashed cell moves
it by 11.  The agent's seeded cells repeat more
often than the pipeline's (22 of 23 against 19 of 23), but its one
swing is the largest single-cell move in either system's seeded mode.
Two draws per system, not a distribution: no standard error.

**Next** (adds to 3.7.1's list): (g) and 3.7's item (b) (openICPSR)
stand.  Holman's crash is recorded, not fixed: raising the repair
budget for one cell would change the protocol after seeing the result.

### 3.7.3 Agent third sample, independent and blind, on all 23 papers (2026-11-02) — ✅ measured, no API spend

The agent was run a third time in independent and blind mode on all 23
evaluation papers, one desktop Opus subagent per cell as before (run id
`2026-11-02-c`, 46 cells, none skipped,
`benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json`,
PR #117).  This is the agent half of 3.7.1's item (g) for those two
modes.  Seeded mode has no third agent sample, and the pipeline still
has two samples per cell.  Like every later sample the file stays out
of REPORT.md and the single-sample tables (REPORT.md's header says
nothing about later samples, so it is unchanged); it feeds the report's
agent variance tables (Section 4.8), which gain a third-sample column.
As in 3.5–3.7.2, every figure below is recomputed from the results
files by `docs/report/tables.py` (its discrepancies table).  Sample 1
and sample 2 are the files named in 3.7.2 and 3.7: sample 1 the
independent and blind rows of the four first-sample agent files, sample
2 `claude-code-run2-13papers-indep-blind-2026-11-01.json`,
`claude-code-run2-4papers-indep-blind-2026-11-02.json` and
`claude-code-run2-6papers-indep-blind-2026-11-02.json`.

Per paper, sample 1 → sample 2 → sample 3, final claims within
tolerance with the first-scored count in brackets:

| Paper | n | independent (1 → 2 → 3) | blind (1 → 2 → 3) |
|---|---|---|---|
| Acemoglu | 12 | 12 (12) → 12 (10) → 12 (10) | 12 (10) → 12 (12) → 12 (12) |
| Adams | 11 | 11 (11) → 11 (11) → 11 (7) | 8 (8) → 7 (7) → 8 (8) |
| Altmann | 13 | 13 (13) → 13 (13) → 13 (13) | 13 (13) → 13 (13) → 13 (13) |
| Arias | 12 | 12 (12) → 12 (12) → 12 (12) | 12 (12) → 12 (12) → 12 (12) |
| Bokobza | 11 | 11 (11) → 11 (11) → 11 (11) | 11 (11) → 11 (11) → 11 (11) |
| Brouwer | 12 | 12 (12) → 12 (12) → 12 (12) | 12 (12) → 12 (12) → 12 (12) |
| Carrera | 11 | 11 (11) → 11 (7) → 11 (11) | 11 (11) → 11 (11) → 11 (11) |
| Dancygier | 13 | 13 (13) → 13 (13) → 13 (13) | 13 (13) → 13 (13) → 13 (13) |
| Dertwinkel-Kalt | 13 | 13 (12) → 13 (13) → 13 (13) | 13 (13) → 13 (13) → 13 (13) |
| Douenne | 13 | 13 (12) → 13 (13) → 13 (13) | 12 (12) → 12 (12) → 13 (12) |
| Forsythe | 13 | 12 (12) → 13 (13) → 13 (13) | 11 (11) → 11 (11) → 11 (11) |
| Gagliarducci | 13 | 13 (13) → 13 (13) → 13 (13) | 7 (7) → 9 (9) → 9 (9) |
| Grier | 11 | 10 (10) → 9 (9) → 9 (9) | 10 (10) → 10 (10) → 8 (8) |
| Hanlon | 12 | 12 (12) → 12 (12) → 12 (12) | 12 (8) → 12 (12) → 12 (12) |
| Hanushek | 13 | 13 (2) → 13 (2) → 13 (13) | 13 (13) → 13 (13) → 13 (13) |
| Hollyer | 13 | 13 (13) → 13 (13) → 13 (13) | 13 (13) → 13 (13) → 13 (13) |
| Holman | 11 | 10 (10) → 10 (6) → 7 (7) | 6 (6) → 6 (6) → 6 (6) |
| Labandeira | 12 | 8 (7) → 11 (7) → 8 (7) | 6 (6) → 7 (7) → 7 (7) |
| Leeson | 11 | 11 (10) → 11 (10) → 11 (10) | 11 (10) → 11 (10) → 11 (10) |
| López-Moctezuma | 13 | 9 (9) → 9 (9) → 9 (9) | 9 (9) → 9 (9) → 9 (9) |
| Manekin | 12 | 12 (12) → 12 (12) → 12 (12) | 12 (12) → 12 (12) → 12 (12) |
| Mokyr | 13 | 13 (13) → 13 (13) → 13 (13) | 13 (13) → 13 (13) → 13 (13) |
| Montero | 10 | 10 (10) → 10 (10) → 10 (10) | 10 (10) → 6 (6) → 5 (5) |
| **Total, 23 papers** | 278 | **267** (252) → **270** (244) → **264** (256) | **250** (243) → **248** (247) → **247** (245) |

Nineteen of the 23 independent cells and 17 of the 23 blind cells have
the same final count in all three samples; the largest spread in a cell
is 3 independent (Holman, Labandeira) and 5 blind (Montero).  Sample 3
had the most first-scored passes of the three in independent mode (256,
against 252 and 244), with fewer claim refinements doing the work.

**Cells that changed across samples, and why** (from the results files
and the evidence bundles under `benchmark/evidence/`):

- *Holman independent, 10 → 10 → 7* (1 error and 1 claim refinement).
  Three Table 2 difference-in-differences claims missed: the
  like-May interaction −0.0996 against −0.1274 and the like-May time
  coefficient −0.451 against −0.501 (the same values every blind
  sample prints), and the best-PM time coefficient 0.2055 against
  0.2098 under the relative tolerance (the blind samples miss that
  claim too, at 1.364).  The notes say two exploratory Table 2 variants
  after the claim comparison were no better justified by the paper, so
  the final run repeats the first scored script.  The Table 4 N, 4,486
  against 4,328 with 44 usable countries in the posted file, misses in
  every sample of both modes.
- *Labandeira independent, 8 → 11 → 8* (first scored 7 each time).
  Sample 3 printed sample 1's values claim for claim; sample 2's 11 came
  from its own refinements (3.7).  Blind, 6 → 7 → 7: sample 3 printed
  sample 2's values claim for claim.
- *Grier independent, 10 → 9 → 9.*  Sample 3 missed the two tenure
  coefficients under the relative tolerance (−0.3077 against −0.30 and
  −1.3996 against −1.43) and passed all four contribution coefficients,
  with contributions used undeflated (assumed already adjusted by the
  authors).  *Grier blind, 10 → 10 → 8:* sample 3 deflated
  contributions to 2018 dollars with CPI-U and mapped the two window
  files the other way round from the independent cell (iter1 the
  12-month window, iter2 the calendar year), both inferences the notes
  declare.  Its 12-month district coefficient (−0.000530) is the value
  samples 1 and 2 printed for the calendar-year district claim, which is
  what the swapped mapping predicts.
- *Montero blind, 10 → 6 → 5* (below).
- *Douenne blind, 12 → 12 → 13* (first scored 12).  The Table 4 column 1
  initial-acceptance coefficient passed at 0.246 against 0.306 (samples
  1 and 2 missed it at 0.228 and 0.232), and the Table 8 IV passed after
  the first scored run, at 0.435 against 0.416, once the script dropped a
  progressivity control that was asked only in the instrument's
  treatment half (no claim comparison in blind mode; declared).
- *Forsythe independent, 12 → 13 → 13.*  Samples 2 and 3 both passed the
  out-of-the-labour-force interaction that sample 1 missed.  Blind, 11
  in all three samples, with the same two misses: that interaction
  (−0.594 against −0.49) and N, 17,357,345 against 16,948,516.  Sample
  3's blind notes say the state code is missing from mid-2014 and the
  state unemployment file ends in May 2014, so its sample also ends
  there; the independent cell's notes say dropping pairs without a state
  unemployment rate *and* restricting to age below 80 reproduce the
  printed N exactly.
- *Gagliarducci blind, 7 → 9 → 9.*  Sample 3 missed the same four claims
  as sample 2 (the two Democratic opposite-party coefficients and the two
  opposite-party bill counts, 22,712 and 18,691 against 32,846 and
  27,669).
- *Adams.*  Independent, first scored 11 → 11 → 7: one claim refinement
  replaced the both-party seat filter with an out-party-only one, which
  gives 1,842 / 1,836 / 1,833 exactly.  Blind, 8 → 7 → 8: sample 3
  printed sample 1's counts (1,535 / 1,535 / 1,529).
- *First scored only.*  Hanushek independent first scored 13 with no
  refinements, against 2 in samples 1 and 2; Acemoglu independent first
  scored 10 with one claim refinement for the two cluster counts, as in
  sample 2; Carrera independent first scored 11, as in sample 1.
- *López-Moctezuma, 9 / 13 in all six cells.*  The four Appendix C.3 /
  C.4 attitude-index effects miss in every sample of both modes because
  the paper states neither the attendance-weight formula nor the item
  directions; sample 3 independent printed sample 2's values.

**Three-sample ranges.**  Agent totals, with the pipeline's two
samples, 23 papers:

| Mode | Agent 1 | Agent 2 | Agent 3 | Pipeline 1 | Pipeline 2 | **Gap range, 23 papers (six pairings)** |
|---|---|---|---|---|---|---|
| independent | 267 | 270 | 264 | 235 | 223 | **29 to 47** |
| blind | 250 | 248 | 247 | 170 | 172 | **75 to 80** |

Each range takes six pairings (each of three agent samples against each
of two pipeline samples).  By paper set:

| Papers | Independent agent range | Independent gap | Blind agent range | Blind gap |
|---|---|---|---|---|
| 23 | 264–270 | 29 to 47 | 247–250 | 75 to 80 |
| 17 | 191–194 | 22 to 33 | 175–180 | 55 to 62 |
| 6 (3.7 set) | 73–76 | 7 to 14 | 70–72 | 18 to 20 |
| 13 earlier | 144–148 | 15 to 20 | 130–135 | 38 to 53 |
| 4 (3.6 set) | 46–47 | 6 to 14 | 45–45 | 7 to 19 |

On 23 papers the independent range moves from 3.7.1's four-pairing 32
to 47 to 29 to 47 and the blind range from 76 to 80 to 75 to 80: the
third sample is the lowest agent total in both modes, so only the
bottoms move.  The ordering of 3.5–3.7.2 holds in every pairing.
Seeded mode has no third agent sample; its ranges stay as in 3.7.2.
Three draws of the agent and two of the pipeline, not a distribution:
no standard error.

**Montero blind: paper against code, made visible by following the
text.**  The paper says the IQR columns use properties with at least
five members in the surveys.  Sample 3 (5 / 10) applied that rule, with
the survey year of each property's first row as the round fixed effect
and singleton groups kept: N 76 and 28 against 327 and 118, and the IQR
effects changed sign (+24.50 and +52.65 against −42.97 and −51.79).  It
also missed the cluster count (99 against 98); its worker-level N, 4,781
against 4,770, passes.  Sample 2 (run `2026-11-01-a`, 6 / 10) also
applied the rule (N 76 and 26) but used each property's modal survey
round as the fixed effect: −48.56 passed at 300 ha and −202.0 missed at
150 ha, and its notes say the sign flips without the modal-round fixed
effect.  Sample 1 (run `2026-10-21-b`, 10 / 10) did not apply the rule:
it used every property-by-round cell, matched 327 and 118 and passed on
the SE band.  Its notes say it chose that sample because the literal
rule contradicted the property counts the paper reports for those
columns, so its pass came from matching the code's sample rather than
the paper's stated one (and from counts in the text it was given; see
the disclosures below).  Two of three blind samples followed the text
and only sample 1 set it aside, so this cell is classified as a
paper-versus-code discrepancy that following the text exposes, not as
draw-to-draw noise.

**Infrastructure: the agent's 300 s limit is not enforced.**  The
Forsythe independent cell's notes say the final run's own timer showed
314 s (280 s of it the CSV read), that "the 300 s perl alarm wrapper did
not fire", and that the container exited 0.  On the agent path nothing
in the harness enforces the limit.
`benchmark/reproducers/claude_code_task.md` tells the agent to prefix
the rendered `docker run` command (`RDockerExecutor._build_run_cmd` in
`src/retally/codegen/docker_executor.py`, via
`benchmark/reproducers/render_task.py`) with
`perl -e 'alarm shift; exec @ARGV' 300` and to `docker kill` the run's
label itself if it fires; neither `check_attempt` nor the results
adapter records or checks elapsed time.  The alarm is set before
`exec`, so it covers the whole `docker run` client, container creation
and start-up included, and with 314 s timed inside the script it was
due before the script finished.  It most likely did fire and was
absorbed: an attached `docker run` forwards the signals it receives to
the container (`--sig-proxy` defaults to true), the command passes no
`--init`, so the container's PID 1 is `Rscript` itself, which installs
no SIGALRM handler, and the kernel drops a signal with default
disposition sent to a PID-namespace init.  The client therefore never
died, and the run exited 0.  (Inferred from the code and Docker's
documented behaviour; no Docker was run for this section.)  The
pipeline is not affected: `_DockerExecutorBase.execute` runs the same
command under `subprocess.run(timeout=300)`, which kills the client and
then kills the labelled container, start-up included.  Forsythe's 14
extra seconds changed no claim, but an agent cell can exceed the limit
without anyone seeing it.

**Blind-mode disclosures and the redaction follow-up.**  Several blind
agents reported seeing values in `paper.txt` that were not withheld and
said they did not tune toward them: Hollyer (Table 2 RD estimates and
confidence intervals in the method prose), Arias (method-section values:
U.S. wildfires about 4 points, German about 6, and two Table 2
vulnerability rows), Forsythe (the Table 2 subsample Ns for employed,
unemployed and out of the labour force), Montero (a dollar figure for
the IQR difference in prose) and Hanushek (some Table 2 values in
prose).  Hanlon's agent disclosed nothing in its bundle (3.7's list nonetheless counts Hanlon among the reported leftovers).  The Hollyer, Forsythe and
Montero disclosures are in their evidence bundles' notes; the Arias and
Hanushek ones were in the agents' final messages only.  The follow-up
is done (PR #118, recorded in 3.7's list): every reported leftover was
real (Hollyer "approximately 8 / about 9 percentage points" for the
pinned −0.084 / −0.092; Arias's abstract "2160 respondents", which is
1,086 + 1,074, and "4 / 6 percentage points" for 0.04 / 0.06; Hanlon's
174 / 165 / 233, the pinned claims' sample sizes in Table 1's
observations row; Montero "approximately $43" for −42.97 and a footnote
"$60" for 60.49).  `benchmark/reproducers/render_task.py` now adds three
narrow redaction passes: sums of two pinned counts of at least 100,
claim sample sizes of at least 100, and half-up rounded forms only where
an approximation word, a currency sign or a points unit marks them as
rounded.  New redactions per paper: Bokobza 24 (sample sizes and "10 /
11 / 20 percentage points"), Douenne 12 ("27 / 53 / 42 / 15 p.p." for
the pinned 0.269 / 0.534 / 0.416 / 0.153, which no agent reported),
Hanlon 6, Brouwer 5, Acemoglu 4, Forsythe 4, Arias 3, Labandeira 3,
Manekin 3, two each for Dertwinkel-Kalt, Hollyer, Mokyr and Montero,
one each for Altmann, Carrera, Dancygier, Gagliarducci, Hanushek and
Holman; Adams, Grier, Leeson and López-Moctezuma are unchanged.  The
known over-redactions remove numbers only (for example Brouwer's "(16
vs. 10 percentage points)" and Labandeira's "about 10% of Spanish
households").  All three blind agent samples and both pipeline blind
samples were rendered under the old redaction, so they are consistent
with one another and the blind figures in this section stand as
measured.  Any later blind sample uses the new redaction and is not
directly comparable with these on the affected papers.

**Next** (replaces 3.7.2's list): (g) agent side done for independent
and blind mode, three samples each on all 23 papers; still open are a
third pipeline sample in every mode and a third agent seeded sample.
(h) Done: cells now run the sandbox through
`benchmark.reproducers.run_sandbox`, which enforces the 300 s limit
host-side (subprocess timeout, labelled container killed, exit 124) and
records each execution's wall time in a `timing.json` beside its
`stdout.txt`; for later samples only.  (`--init` alone would also have
made the alarm fatal: SIGALRM sent to the client killed the container
in 3 s with it, and was ignored for the full 12 s without it.)  (i)
~~A fourth blind agent sample under the new
redaction on the papers it changed most (Bokobza, Douenne, Hanlon), to
measure what the redaction does to a blind count.~~  Done 2026-11-03
(run `2026-11-03-a`, `claude-code-run4-redaction-3papers-blind-2026-11-03.json`):
Bokobza 11/11, Douenne 13/13, Hanlon 12/12 (first-scored 11, 13, 8),
against 10–11, 12–13 and 12 in the three old-redaction samples.  The
redaction removed the rounded prose forms and sample sizes without
moving a single final count on these three papers; figure check: three
rows in that file.  3.7's item (b)
(openICPSR) stands.

### 3.7.4 Pipeline third sample, count-claim band, manual placement (2026-11-03) — ✅ measured, no API spend

The pipeline was run a third time through the oracle on all 23
evaluation papers in all three modes, one desktop Opus subagent per
prompt (label `desktop-opus-run3`, 297 answered calls, no API spend,
`benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`,
PR #125; 69 rows, none skipped or errored).  Its runs are stamped
00:48–05:57 UTC on 2026-11-03, before the 3.8 unfreeze merged (PR #124,
05:58), so it is a frozen-pipeline sample, the pipeline half of 3.7.1's
item (g), comparable with samples 1 and 2.  Like every
later sample it stays out of REPORT.md and the single-sample tables.
`docs/report/tables.py` now reads it as the pipeline's sample 3 (a
module constant beside the first two samples' files), so the report's
variance, probe and claim-level tables include it; every figure below
was recomputed from the results files and agrees with those tables.  Since 3.7.3 every stored results file has also been rescored
with sample-size claims at a 5 % band (below), so this section gives
totals both ways.  Sample 1 is the model-matched row (the API run for
Grier, Leeson, Manekin and Montero, the first oracle run for the other
19), sample 2 the `desktop-opus-run2` files named in 3.7.1.

**Totals, 23 papers, 278 claims**, final claims within tolerance under
the original 1 % count band → after the count rescore:

| Mode | Pipeline 1 | Pipeline 2 | Pipeline 3 | Agent 1 | Agent 2 | Agent 3 |
|---|---|---|---|---|---|---|
| seeded | 263 → 263 | 265 → 265 | 254 → 254 | 277 → 277 | 266 → 266 | — |
| independent | 235 → **239** | 223 → **226** | 224 → **227** | 267 → **268** | 270 → **271** | 264 → **265** |
| blind | 170 → **173** | 172 → **176** | 177 → **181** | 250 → **252** | 248 → **251** | 247 → **250** |

No seeded verdict flipped in either system.  The pipeline's cells are
identical in all three samples in 17 of 23 seeded, 10 of 23 independent
and 6 of 23 blind cells (largest spread in one cell 13, 12 and 9
claims), against 19, 14 and 12 of 23 for samples 1 and 2 alone after
the rescore (19, 14 and 11 under the 1 % band, 3.7.1).

**Nine-pairing ranges, 23 papers** (agent minus pipeline, rescored
files; independent and blind take each of three agent samples against
each of three pipeline samples, seeded each of two agent samples
against each of three pipeline samples, six pairings):

| Mode | **Rescored, all pairings** | Under the 1 % band, all pairings | Rescored, pipeline samples 1–2 only | 3.7.2 / 3.7.3 as written (1 % band) |
|---|---|---|---|---|
| seeded (6 pairings) | **1 to 23** | 1 to 23 | 1 to 14 | 1 to 14 |
| independent (9) | **26 to 45** | 29 to 47 | 26 to 45 | 29 to 47 |
| blind (9) | **69 to 79** | 70 to 80 | 74 to 79 | 75 to 80 |

By paper set, rescored, all pairings: 17 papers −6 to 17 seeded, 20 to
31 independent, 51 to 61 blind; 13 earlier papers −10 to 4, 11 to 19,
35 to 51; the four of 3.6 2 to 15, 4 to 16, 7 to 20; the six of 3.7 6 to
8, 6 to 14, 16 to 20.  What drives the width:

- *Seeded, 1 to 23.*  The top is agent sample 1 (277) against pipeline
  sample 3 (254), new in this section.  Sample 3's seeded total is 11
  below sample 2's: Forsythe −13 (0 / 13) and Labandeira −6 (6 / 12),
  partly offset by Douenne +7 (13 / 13) and Bokobza +2 (Gagliarducci −1).  The bottom is
  still agent sample 2 against pipeline sample 2 (266 against 265), the
  Holman crash of 3.7.2.  One cell of each system moves the range by
  11 to 13 claims.
- *Independent, 26 to 45.*  The bottom is agent sample 3 (265) against
  pipeline sample 1 (239); the top agent sample 2 (271) against pipeline
  sample 2 (226).  Pipeline sample 3 (227) sits beside sample 2, so it
  moves neither end: against sample 2 its Forsythe −12, Holman −3 and
  Labandeira −3 are offset by Carrera +8, Hanushek +4, Adams +3, Leeson
  +3 and Montero +2, among others.
- *Blind, 69 to 79.*  The bottom is agent sample 3 (250) against
  pipeline sample 3 (181), the highest pipeline blind total of the
  three; the top agent sample 1 (252) against pipeline sample 1 (173).
  Against sample 2, sample 3 gained Altmann +9 (13 / 13, against 4 and
  4), Adams +6 and Mokyr +6 (7 / 13, against 1 and 1), and lost Arias −5,
  Forsythe −5, Carrera −3 and Montero −3, among others.

The ordering of 3.5–3.7.3 holds in every pairing: seeded smallest,
then independent, then blind.  Three draws per system (two for the
agent seeded) are still not a distribution: no standard error.

**Cells, from the results file, its artifacts under
`benchmark/results/artifacts/` and the rebuilt
`benchmark/evidence/<paper>/REPORT.md`** (final count, first-scored in
brackets, rescored):

- *Forsythe seeded and independent, 0 / 13 each* (13 and 13 in samples
  1 and 2 seeded, 12 and 12 independent).  Each cell ran four
  executions, three error repairs, and never printed a `RESULT:` line.
  Seeded: the first two executions printed nothing at all (empty stdout
  and stderr); the third and the final one printed only
  `main data: 19836464 rows, 25 cols`.  Independent: each execution
  printed its column map and got a little further (`N raw: 19836464`,
  then `N after age/educ: 19467218`; the final script read the file in
  eight chunks of up to 2.5 million rows and stopped after printing
  `N raw`).  No stderr
  holds an R error.  The rows and artifacts do not store the exit code,
  `timed_out` or the elapsed time, so that these runs were killed at the
  300 s limit is inferred from the output stopping mid-preparation with
  no error, not read from the record.  On a kill the executor sets
  `timed_out=True` and exit −1 (`_DockerExecutorBase.execute`), but the
  frozen repair loop (`src/retally/pipeline.py`, line 542 at the run's
  commit) built its feedback as `result.stderr or "No RESULT: lines
  found in output"` and never consulted `timed_out`: the seeded cell's
  first two repairs were told "No RESULT: lines found in output", its
  third and the independent cell's three were shown the progress lines
  from stderr, and none was told the script had been killed.  All six
  run-3 scripts read `yh_data.csv` with a column-selected
  `fread(select=)` over all rows, as samples 1 and 2 did, and samples 1
  and 2 printed their results; what made run 3 slower is not in the
  record.  This is the timeout sub-case that 3.8's timeout repair
  addresses (PR #124).
- *Labandeira seeded, 6 / 12 (1)*, against 12 / 12 in samples 1 and 2.
  The first execution crashed (`1:max(eidx, na.rm = TRUE)`: result
  would be too long a vector); one error repair and three claim
  refinements followed, and the values moved between refinements (Table
  2 column 1, −0.128, −0.098, −0.138, final −0.173 against −0.178).  The
  final script passes the four expenditure columns and both counts
  (20,872 and 10,729 exactly) and misses the four consumption columns and
  both elasticities (−0.991 and −0.988 against −1.044 and −1.026), with
  one declared deviation (it filled 172,361 missing log-consumption
  values from `c_ele`).
- *Holman blind 0 / 11*, as in samples 1 and 2, and *Montero blind
  0 / 10*, as in sample 1 (3 in sample 2).  Holman, on one execution,
  printed no Table 4 values and Table 2 samples of 239,919 and 1,481,392
  against 143,499 and 97,155.  Montero printed no IQR effect or IQR
  sample and worker-level samples of 3,907 and 1,472 against 4,770 and
  1,583.
- *Montero independent, 8 → 10 / 10 under the rescore* (first scored 0;
  one error repair, three claim refinements): the two counts that
  flipped are the 300 ha IQR observation count, 332 against 327
  (1.53 %), and the 300 ha cluster count, 99 against 98 (1.02 %).
- *Mokyr independent, 7 / 13 (1)*, as in sample 2 (13 in sample 1).
  The three first-stage F statistics are 8.86, 7.32 and 7.92 against
  19.9, 16.96 and 16.17, the values sample 2 printed; three claim
  refinements did not move them.
- *Douenne seeded, 13 / 13 (13)*, against 5 and 6 in samples 1 and 2
  (one error repair, no claim refinement).  The inverted cell of 3.7 and
  3.7.1 did not recur: with the scripts the pipeline now matched every
  claim.  Why this draw differs was not examined for this section.
- *Seeded, smaller misses:* Bokobza 9 / 11 (9 and 7 before), Gagliarducci
  11 / 13 (8 and 12), Grier 10 / 11 (11 and 10).
- *Blind, smaller counts:* Acemoglu 6 / 12 (4 under the 1 % band; 6 and 6
  in samples 1 and 2 after the rescore), Carrera 4 / 11 (0 and 7), Grier
  2 / 11 (0 and 0), Arias 7 / 12 (6 under the 1 % band; 12 and 12 before),
  Forsythe 5 / 13 (10 and 10).
- *Larger counts than samples 1 and 2:* Altmann blind 13 / 13 (4, 4),
  Mokyr blind 7 / 13 (1, 1), Hanushek independent 13 / 13 (9, 9), Carrera
  independent 8 / 11 (7, 0), Adams independent 11 / 11 (10, 8).  Not
  examined beyond the counts.

**Count claims at 5 %** (PR #123, user decision 2026-11-03).  Sample-size
claims (observations, clusters, respondents, districts, bills) are a new
`ClaimType.COUNT` with a 5 % band; 62 catalog claims across 25 papers
were relabelled from `other` (1 %), and `other` claims (F statistics,
ANOVA and Brown-Forsythe statistics, percentage points) keep 1 %.  Every
stored results file was rescored offline from its stored `reproduced`
values, no run repeated: 56 verdicts flipped across the 76 files then on
main (75 rewritten), all FAIL → PASS
(`benchmark/results/RESCORE-count-5pct.md`, per file and mode), and 7 more
in the run-3 file, which was rescored when it landed (its `rescored` key
says `count-5pct`, 7 flipped; its rows were appended to the RESCORE
file afterwards, marked as rescored at assembly).
First-scored and first-attempt fields were left as recorded, because a
row stores only the final reproduced value, not the first-scored one:
a recorded first-scored count miss may now be an undercount.  The headline
totals before → after are in the table above; on the earlier sets the
pipeline's first samples move from 41 to 47 independent and 24 to 29
blind on the seven papers on `claude-opus-4-7` (3.2), and the API
four-paper blind from 20 to 21.  Every pre-rescore figure quoted in
3.2–3.7.3 stands as written; `docs/report/tables.py`'s ROADMAP check now
reports 188 of 1,347 quoted numbers as different from the rescored files
(3 before), and the report's tables, spliced into `docs/report/draft.md`
in this PR, carry the rescored values.

**Manual package placement** (PR #122).  A catalog entry can now record
`dataset.data_access: manual` with a local `source` under
`benchmark/manual-packages/<I4R tag>/` (git-ignored); the runner skips a
manual entry whose file is missing (`manual_package_missing`).
`benchmark/corpus/openicpsr-wanted.md` lists the 33 AEA papers, with
download steps.  No package has been placed yet; 3.7's item (b) is
ready and waits on the downloads.

**Carrera `access_notes`** corrected (PR #125): the script-free copy
withholds 29 files (8 scripts, 17 regression `.tex` tables, among them
`DailyAttIncr.tex` since PR #113's whole-table rule, and 4 macro files).
The notes are part of the catalog entry's serialised form, so Carrera's
result-cache keys change from here on; no stored row is affected.

**Evidence.**  `benchmark/evidence/` was rebuilt for all 23 papers from
every results file: 420 cells in `INDEX.md`, 69 of them run 3.

**Next** (replaces 3.7.3's list):

- (b) openICPSR downloads: the user's.  The placement path is built
  (above); curation follows once packages are under
  `benchmark/manual-packages/`.
- (g) Done for the pipeline: three samples in every mode on all 23
  papers.  A third agent seeded sample is still open.
- 3.8: the pipeline unfreeze (PR #124, merged) adds the timeout repair
  that the Forsythe cells above lacked, among its fixes.
- A post-fix oracle sample on the 23 papers (`desktop-opus-postfix`,
  3.8's Next), labelled post-fix and not pooled with the three frozen
  samples.

### 3.8 Pipeline unfreeze (2026-11-03) — built, not yet measured, no API spend

**Decision.**  The pipeline (`src/retally/`) had been frozen since 3.2
so that no evaluation number was tuned on an evaluation paper.  The
user decided on 2026-11-03: "unfreeze to fix the largest pipeline
failures, then refreeze."  The fixes are general mechanisms, not
paper patches: no file name, variable name, sample rule or number from
any catalog paper is in the code or the prompts.

**Protocol.**  These fixes were made *after* seeing the evaluation
results (the report's Section 5 taxonomy), so they are post hoc.  Every
later pipeline measurement is labelled post-fix and is not pooled with
the frozen samples; the frozen samples of 3.2–3.7 stand unchanged and
remain the pipeline's headline numbers.  The agent's task file keeps
the frozen prompt blocks, so agent rows stay comparable across the
unfreeze.

**The mechanisms** (three plus a timeout sub-case of the third; first-sample misses of the pipeline on Opus
5.5, independent + blind, 278 claims on 23 papers; draft Section 5):

| Mechanism | Misses (indep. + blind) | Change | Switch (default on) |
|---|---:|---|---|
| Sample restriction | 7 + 40 | **Sample reconciliation.**  The generation prompt asks for `SAMPLE:<sample>:<step>=<rows>` lines before the `RESULT:` lines: rows after loading, after each restriction the paper states (in its order), and at estimation.  Seeded and independent prompts ask the script to compare each sample with any stated sample size before estimating; the blind prompt only asks for the stated restrictions in order and names no sample size.  In claim refinement (seeded and independent only), a failing sample-size claim opens the prompt as "Sample size check (fix this first)" with the stated N, the script's N, the gap and the script's SAMPLE lines.  `RESULT:` parsing is unchanged; SAMPLE lines are parsed into `ExecutionResult.sample_lines` and written to `samples.txt` in the run artifacts. | `CodeGenerator(sample_reconciliation=...)` |
| Data-file resolution | 11 + 12 | **Data inventory.**  Before generation, no model call: every data file in the mount (`.csv`/`.tsv`, `.dta`, `.rds`/`.RData`/`.rda`, `.xlsx`; `.parquet`/`.sav` and others listed as "not profiled") gets rows, columns, leading column names and Stata variable labels, profiled on the host in Python (pandas header reads, the existing R-serialisation walker, the workbook XML).  Bounds are by size, not time, so the prompt stays deterministic; a CSV over 50 MB gets an approximate (`~`) row count and over 1 GB "rows unknown", never skipped.  Files that share their columns are compared and the columns that differ are named (with per-file means except in blind mode).  Capped at 30 files and ~16k characters, beside the existing listing. | `CodeGenerator(data_inventory=...)` |
| Extraction error | 0 + 13 (12 + 8 on 4.7) | **Completeness repair.**  After the execution-repair phase, if the script ran to completion but some claims got no value (`NA` or no `RESULT:` line), one targeted repair ("these names are missing or NA; here is the log; fix the printing or the model that produced NA") runs before any claim refinement, in every mode including blind.  It spends one slot of the existing error-repair budget, is recorded as attempt kind `completeness` (feedback starts "Completeness check:"), counts in `n_error_refinements` and in `n_completeness_refinements`, and is kept only if it still runs and prints at least as many usable values. | `ValidationPipeline(completeness_repair=...)` |
| Extraction error, timeout sub-case (found in the third oracle sample, not in the taxonomy counts: Forsythe seeded and independent at 0 / 13 after four executions, each printing only its first data-load line) | **Timeout repair.**  When the sandbox kills a run at its wall-clock limit (`timed_out`), the error repair is no longer told only "No RESULT: lines found in output": its feedback says the script was killed at the limit (the limit and the executor's measured elapsed time, now recorded as `ExecutionResult.elapsed_seconds`), quotes the last printed line, and says the fix must cut input work (only the needed columns, no full-file or repeated reads, subset before merging), not add printing.  An error repair in the same budget, recorded as attempt kind `timeout-repair` (feedback starts "Timeout: the sandbox killed the script"). | same switch, `completeness_repair` |

All three switches off (`ValidationPipeline.default(data_inventory=False,
sample_reconciliation=False, completeness_repair=False)`, or
`RETALLY_PIPELINE_FROZEN=1` for the benchmark runner) reproduces the
frozen pipeline: the seeded and blind golden prompts are byte-identical
with the switches off.  Pipeline result-cache keys carry a
`pipeline_fixes` tag unless `RETALLY_PIPELINE_FROZEN=1`, so a post-fix
run is never served a frozen row.

What the evidence showed that the taxonomy does not: Montero blind's
script-free mount holds a single data file (5,060 rows, 119 columns,
already listed with its columns), and the script read it; its 130 rows
come from its own filters, so that cell is a sample-construction miss
more than a file-resolution one.  Grier's three files share 27 columns
and 862 rows and differ only in one contribution column, which the
listing could not show and the inventory now names.

**Next:** a post-fix oracle sample on the 23 papers, independent and
blind, labelled `desktop-opus-postfix`.

**Refrozen.**  The pipeline is refrozen at this PR's merge commit; any
further change to `src/retally/` prompts or loop needs a new unfreeze
decision and section.

### 3.8.1 Post-fix oracle sample (2026-11-03) — ✅ measured, no API spend

**What ran.**  One oracle sample of the post-fix pipeline (refrozen at
41a4039, PR #124), on all 23 evaluation papers, independent and blind mode
only (no seeded), label `desktop-opus-postfix`.  It ran through the desktop
oracle, one Opus subagent per prompt, with no API spend:
`benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json`
(PR #127).  The file has 46 rows, none skipped or errored, and 188 answered
calls.  Count claims are scored at 5 % by the live comparator, and the
file's `rescored` key records `count-5pct` with 0 flipped.  Artifacts are
stamped 06:21–10:48 UTC.  The extraction prompts were byte-identical to
the frozen samples' prompts, and their stored answers were reused (46
methodology, 23 hyperparameter).  The rows agree: each records exactly 2
calls beyond its generation and refinement prompts (92 counted), which fits
69 distinct prompts with the hyperparameter prompt shared across the two
modes.  The reuse itself is not recorded in any committed file.  Every
generation and refinement prompt (96 of them) was answered fresh.

**Totals, 23 papers, 278 claims** (frozen samples after the count rescore,
3.7.4):

| Mode | Frozen 1 | Frozen 2 | Frozen 3 | **Post-fix** | Agent 1 / 2 / 3 | Post-fix cells above / within / below the frozen range |
|---|---|---|---|---|---|---|
| independent | 239 | 226 | 227 | **233** | 268 / 271 / 265 | 2 / 17 / 4 |
| blind | 173 | 176 | 181 | **191** | 252 / 251 / 250 | 5 / 17 / 1 |

Post-fix independent sits inside the frozen range (226–239).  Post-fix
blind is 10 above the highest frozen blind total.  The cell-by-cell table is
`docs/report/tables/postfix.md`.

**Protocol.**  This is a post-hoc sample: the three fixes were designed
after reading the evaluation results (3.8).  So the run is not pooled with
the frozen samples and enters no gap-range or pairing table with them.
`docs/report/tables.py` reads it only for its own `postfix` table, a
separate row labelled post-fix.  One draw, no standard error.  Every
comparison below is descriptive: post-fix against the frozen samples'
range, per mode and per cell.  The frozen samples remain the pipeline's
headline numbers.

**Mechanisms, over the 46 rows** (from the git-ignored artifacts under
`benchmark/results/artifacts/<paper>/<mode>/pipeline/<run>/`: prompts,
`samples.txt`, and the first line of each attempt's `feedback.txt`):

- *Data inventory:* in the first prompt of all 46 runs.
- *SAMPLE lines:* printed by all 46 runs (a non-empty `samples.txt` in
  every row).
- *Completeness repair:* 5 cells.  Bokobza independent went from 4 usable
  values to 11, Leeson independent from 10 to 11 and Leeson blind from 14
  to 16.  Douenne independent got its repair at attempt 3,
  adding the missing Table 6 IV value (12 to 13).  Holman blind's repair
  ran, but the cell stayed at 0 / 11.
- *Timeout repair:* 0 cells.  Forsythe blind's one error repair was told
  "No RESULT: lines found in output", so no run was recorded as killed at
  the limit.
- *Error repairs:* 17 of the 46 rows have `n_error_refinements` > 0 (5 of
  them completeness repairs, which share that budget).
- *`n_completeness_refinements` is not on the rows.*  The pipeline sets it
  on `ValidationResult` (`src/retally/pipeline.py`), but the harness never
  copies it into a result row.  The completeness and timeout counts above
  come from `feedback.txt`.
- *The sample-size check never fired.*  No refinement prompt in the run
  contains "## Sample size check (fix this first)".
  `is_sample_size_claim` (`src/retally/codegen/generator.py`) returns False
  for any claim whose type is not `ClaimType.OTHER`.  Since PR #123 the
  catalog types its sample-size claims `count`, and the runner maps them to
  `ClaimType.COUNT`.  So the 12 claim-refinement prompts (in 8 independent
  cells) that listed a failing count claim did not get the block: Adams 2,
  Altmann 1, Carrera 1, Forsythe 1, Grier 1, Holman 1, Labandeira 2,
  Montero 3.  The SAMPLE half of the mechanism ran, but its refinement half
  was inert in this sample.  The two PRs were written in parallel and
  merged 2026-11-02 21:48 (#123) and 22:06 (#124).  Fixing this needs a new
  unfreeze decision (3.8, "Refrozen").

**Cells outside the frozen range** (post-fix, then frozen samples 1, 2
and 3; first scored in brackets):

- *Grier independent, 10 / 11 (6)*, against 0, 2 and 2.  The data
  inventory is at work here.  The inventory reports that the three
  `SugarReplicate*.dta` files differ only in `totalcont`, with per-file
  means.  The script's comments repeat that finding, and it assigns the
  three files to the baseline, calendar-year and 12-month windows.  Two
  claim refinements followed, and both counts pass (186 and 106).  Grier
  blind stayed at 2 / 11.
- *Carrera independent, 9 / 11 (9)*, against 7, 0 and 8; *Carrera blind,
  8 / 11 (8)*, against 0, 7 and 4.  Each cell had three ordinary error
  repairs ("All observations contain NA values" and similar).  The SAMPLE
  lines show the wave-3 restriction changing between attempts (blind: 1,152
  rows, then 1,280 in the final run).  No completeness or timeout repair
  ran, and the artifacts do not single out one fix.
- *Bokobza blind, 11 / 11*, against 4, 10 and 9: one error repair (stderr
  notes as feedback), after which every value printed.
- *Mokyr blind, 13 / 13*, against 1, 1 and 7.  This is not attributable to
  a fix.  The script read the same file, and its SAMPLE lines show the same
  298 districts as every frozen sample.  No repair ran.  It built the
  densities per head of `pcmean` without the ×10,000 of samples 1 and 2,
  and it printed first-stage F statistics of 19.9, 16.96 and 16.17, against
  8.86, 7.32 and 7.92 in all three frozen samples.
- *Hollyer blind, 13 / 13*, against 10, 12 and 10, and *Acemoglu blind,
  7 / 12*, against 6, 6 and 6.  Same files, no repair.  These are draw
  differences.
- *Below the range, independent:* Acemoglu 7 / 12 (11, 11, 11), with the
  same counts as frozen and lower first-stage and IV coefficients, no
  repair and two claim refinements.  Adams 7 / 11 (10, 8, 11): a sample
  miss (2,019 dyads against 1,842), and both of its claim-refinement
  prompts listed the failing counts without the sample-size check.  Douenne
  12 / 13 (13, 13, 13), after six refinements (two error, one completeness,
  three claim): it misses the Table 8 IV coefficient (0.037 against
  0.416).  Holman 1 / 11 (4, 9, 6): its Table 2 samples are 239,919 and
  1,481,392 against 143,499 and 97,155.  Its one claim refinement (no
  sample-size check) broke the script and was reverted.
- *Below the range, blind:* Arias, below.

**Within the frozen range** (named in the brief for this section; post-fix,
then frozen 1, 2 and 3): independent Mokyr 13 (13, 7, 7), Altmann 13
(13, 13, 13; first scored 4), Gagliarducci 13 (13, 13, 12), Bokobza 11
(11, 10, 11; completeness repair), Leeson 11 (11, 8, 11; completeness
repair), Montero 8 (10, 8, 10; first scored 1), Forsythe 9 (12, 12, 0),
Labandeira 4 (6, 7, 4), Hanushek 9 (9, 9, 13), López-Moctezuma 9 (9, 9, 9).
Blind Dancygier 13 (13, 13, 11), Douenne 13 (12, 13, 13), Dertwinkel-Kalt
13 (12, 13, 13), Forsythe 9 (10, 10, 5), Leeson 8 (9, 8, 8), Montero 3
(0, 3, 0), Grier 2 (0, 0, 2), Holman 0 (0, 0, 0), Labandeira 4 (4, 4, 4),
Gagliarducci 7 (12, 7, 7), Adams 8 (7, 2, 8), Hanushek 9 (12, 9, 9),
López-Moctezuma 9 (9, 9, 9), and Altmann, below.  Forsythe's frozen
sample-3 timeouts (3.7.4) did not recur: both post-fix Forsythe cells
reached 9 / 13.

**Arias blind, 1 / 12 (1)**, against 12, 12 and 7.  The script reads the
same two conjoint files as every frozen sample.  Its choice-column
detector excludes `force_choice` as metadata: the regex of survey
bookkeeping columns lists it beside `SURVEY_HISTORY`, and the inventory
prints it between `POL_INTEREST` and `SURVEY_HISTORY`.  Samples 1 and 2
printed their nine choice columns as `force_choice, Q184, Q186, …,
Q198`.  So `force_choice` is the first choice task, and without it the
detector's nine-column window covers different columns.  Sample 3's
script names no choice columns in its output.  The post-fix script does not
print which columns it picked either, so the misalignment is inferred from
the code and the result.  Every AMCE comes out near zero (US drought
0.003 against 0.035), and the SAMPLE lines show 1,143 US respondents
completing the conjoint against 1,086, and 16,384 and 16,682 profiles
against 18,966 and 18,862.  This is a sample- and coding-construction miss.
The blind prompt names no sample size, and blind mode has no claim
refinement, so nothing in the loop could catch it.

**Altmann blind, 4 / 13 (4)**, against 4, 4 and 13.  The post-fix cell
estimates on the same sample as frozen samples 1 and 2: 17,840 lab rows
and 892 subjects, against 12,160 and 608.  Its coefficients without
controls are the same as theirs (0.08299, −0.1576, −0.09874, −0.2177), and
it passes the same four claims.  Frozen sample 3's 13 / 13
came from a fallback that restricted the sample to scarce resources as
`Treatment_Incentives != Ample` (12,160 rows).  The post-fix script looks
for the scarce-resource treatment by name patterns (`^Treatment_Load`,
`^scarce`, `cognitive_load`, …), finds none and drops nothing.  Its SAMPLE
lines show `lab:loaded=17840` and `lab:scarce_resources=17840`.  The
inventory line for the lab file is cut off (`…`) before the
`Treatment_Incentives*` columns.  The plain listing in the same prompt does
show `Treatment_Incentives_Baseline_sc…`.  So this is a regression only
against sample 3: the post-fix draw repeats the frozen pipeline's usual
miss.

**Report.**  `docs/report/tables.py` adds the `postfix` table (separate,
labelled post-fix, never in the frozen pairings or gap ranges).
`docs/report/draft.md` gets the spliced table, a post-fix paragraph in
Section 4.8 and a limitations sentence.

**Evidence.**  `benchmark/evidence/` was rebuilt with the post-fix cells
(PR #127): 466 cells in `INDEX.md`, 46 of them `pipeline-desktop-opus-postfix`
(420 before).

**Next** (replaces 3.8's):

- A second post-fix sample, if wanted, under the same protocol.
- (b) openICPSR downloads: the user's.
- Nothing else new.

### 3.8.2 Sample-size check: `count` claims (2026-11-03) — ✅ fixed, refrozen

The sample reconciliation of 3.8 opens a claim-refinement prompt with the
gap between the stated N and the script's N, but `is_sample_size_claim`
accepted only claims typed `other`.  PR #123 had already retyped every
catalog sample size as `count` (62 claims), so the check never fired: in
the first post-fix sample (3.8.1) 12 refinement prompts in 8 independent
cells went out without the "Sample size check (fix this first)" block,
and the sample measured the data inventory, the SAMPLE lines and the
completeness repair only.  The fix accepts `count` claims directly and
keeps the keyword heuristics for the older `other` typing; a test covers
both.  Nothing else in the loop or the prompts changed, so the first
post-fix sample stands as recorded, labelled "check not firing".  The
second post-fix sample (`desktop-opus-postfix2`) is run with the check
firing and is reported as its own row.  The pipeline is refrozen at this
PR's merge commit.

**Harness note — paper downloads are now cached (2026-11-05).**  The
second post-fix sample never converged on Douenne: its extraction prompt
came back with a new hash every round.  The paper is served by UvA-DARE
with a cover sheet that stamps `Download date:DD Mon YYYY`, and the
pipeline's `parse_url` streams the PDF to a temp file and discards it, so
a loop spanning midnight parsed a different text each day, and the oracle
(whose request ids hash the prompt) raised a fresh pending prompt for the
same cell.  `PipelineReproducer` now keeps the first download of every
`http(s)` paper at `benchmark/.cache/papers/<sha256(url)[:16]>.pdf` and
hands the pipeline that path (`cached_paper_source`); non-PDF responses
pass through.  Pipeline code and the result-cache key are untouched.
Frozen samples are unaffected in substance (each cell parsed one
download, stamped with its own day), but the paper text in Douenne's
evidence folders differs by that cover line between samples.

### 3.8.3 Second post-fix oracle sample (2026-11-05) — ✅ measured, no API spend

**What ran.**  A second oracle sample of the post-fix pipeline, now
refrozen at 38faba7 (PR #129, the sample-size check fix of 3.8.2), on
all 23 evaluation papers, independent and blind mode only, label
`desktop-opus-postfix2`.  Same protocol as 3.8.1: one Opus subagent per
prompt at the desktop default effort, isolated by instruction (it reads
one prompt and writes one answer), no API spend.  File:
`benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json`
(PR #131).  46 rows, none skipped or errored, `cached` false on every
row, 183 answered calls; the `rescored` key records `count-5pct` with 0
flipped.  Artifacts are stamped 2026-11-03 11:03 to 2026-11-06 05:07
UTC.  Extraction answers (methodology and hyperparameter) for 22 papers
were reused from earlier labels by prompt-hash id, since the prompts
were identical; this reuse is not recorded in any committed file.
Every generation and refinement prompt got a fresh agent, and nothing
from the first post-fix sample's generation answers was reused.

**Totals, 23 papers, 278 claims** (frozen samples after the count
rescore, 3.7.4):

| Mode | Frozen 1 | Frozen 2 | Frozen 3 | Post-fix 1 (check not firing) | **Post-fix 2 (check firing)** | Post-fix 2 cells above / within / below the frozen range |
|---|---|---|---|---|---|---|
| independent | 239 | 226 | 227 | 233 | **231** | 2 / 19 / 2 |
| blind | 173 | 176 | 181 | 191 | **182** | 4 / 16 / 3 |

Post-fix 2 independent is inside the frozen range (226–239); blind is
1 above the highest frozen total.
Against post-fix 1 it is 2 lower independent and 9 lower blind.  The
cell-by-cell table (both post-fix samples side by side) is
`docs/report/tables/postfix.md`.

**Where the check fired.**  Counted from the complete oracle prompts in
the evidence tree (`grep -rl 'Sample size check'
benchmark/evidence/*/*/pipeline-desktop-opus-postfix2/`): 13 refinement
prompts in 9 independent cells, none in blind (blind has no
claim-targeted refinement, by design).  Post-fix 1 has none.  Per cell
(prompts with the block; first scored → final; what the named count
claims did):

- *Adams* (1; 7 → 10): 2,019 dyads against 1,842; all three named
  counts pass (1,826, 1,823, 1,820).  No other claim moved.
- *Altmann* (1; 4 → 4): 17,840 rows and 892 subjects against 12,160 and
  608; both still fail.  The script finds no scarce-resource flag, the
  same miss as Altmann blind in 3.8.1.
- *Arias* (1; 2 → 12): 16,798 and 16,714 choice tasks against 18,966 and
  18,862; both pass, and all eight AMCEs with them.
- *Forsythe* (1; 9 → 9): 14.3 M against 16.9 M rows; still fails.
- *Gagliarducci* (1; 7 → 13): both bill counts pass, and four
  coefficients with them.
- *Grier* (1, in the second claim refinement; 0 → 10): both counts pass,
  and eight coefficients with them.
- *Holman* (2; 1 → 4): the like-May count passes; the best-PM count
  (named in both prompts, first too high, then too low) still fails.
  Two coefficients pass.
- *Labandeira* (2; 4 → 6): the household count still fails; the
  observation count, which passed when first scored, fails at the end.
  Three coefficients pass.
- *Montero* (3; 3 → 7): two of three named counts pass; the bandwidth-150
  IQR count still fails.  Two coefficients pass.

Of 19 distinct count claims named, 12 passed at the end, 6 still failed
and 1 went from pass to fail.  The same refinements moved 27 other
claims from fail to pass.  The refinement prompt also lists every other
failing claim, so the check's effect cannot be separated from the rest
of the refinement.  The nine cells went 37 first scored → 75 final,
against 51 → 77 in post-fix 1 and 80 / 84 / 70 in the frozen samples;
the other fourteen independent cells reproduced 156 in both post-fix
samples.  So the check repaired sample sizes where it fired, but the
first drafts were worse and the independent total did not rise.

**Cells outside the frozen range** (post-fix 2, then frozen 1, 2 and 3):
independent above, Acemoglu 12 (11, 11, 11) and Grier 10 (0, 2, 2;
Grier was 10 in post-fix 1 too); independent below, Altmann 4 (13, 13,
13) and Montero 7 (10, 8, 10).  Blind above, Carrera 9 (0, 7, 4),
Hollyer 13 (10, 12, 10), Holman 1 (0, 0, 0) and Mokyr 13 (1, 1, 7);
blind below, Arias 2 (12, 12, 7; its script again excludes
`force_choice` as metadata, as in 3.8.1), Gagliarducci 6 (12, 7, 7) and
Labandeira 3 (4, 4, 4).  Hollyer, Mokyr and Carrera blind were above the
range in post-fix 1 too; Arias blind was below it.

**Douenne.**  The loop did not converge on Douenne until 2026-11-05: the
publisher's cover sheet stamps the download date, so a loop spanning
midnight parsed a new paper text and raised a new extraction prompt
each day (harness note under 3.8.2, PR #130).  With the download cached,
its chain was answered fresh (independent first scored 3 → final 13,
blind 6 → 12), and its paper text in the evidence folders differs from
earlier samples by that one cover line.

**Procedural note.**  For one Douenne blind completeness-repair prompt
(`7d58…`) two answering agents wrote an answer: the first hung for about
80 minutes, a replacement was launched, and the first then overwrote the
replacement's file.  The installed answer is the first agent's.  One
draw either way.

**Protocol and caveats.**  Post hoc, as 3.8.1: not pooled with the frozen
samples or with post-fix 1, in no gap range or pairing; `tables.py`
reads it only for the `postfix` table.  One draw per post-fix sample, no
standard error.  Post-fix 1 stays labelled "check not firing".  The
frozen samples remain the pipeline's headline numbers.

**Report.**  `docs/report/tables.py` loads both post-fix files and the
`postfix` table shows them side by side; `docs/report/draft.md` gets a
second post-fix paragraph in Section 4.8 and an updated "Few runs per
cell" limitation.

**Evidence.**  Rebuilt in PR #131 with every results file: 512 cells,
46 of them `pipeline-desktop-opus-postfix2`.

**Next:** nothing new on the pipeline; (b) openICPSR downloads remain
the user's.

**Harness note — execution metadata recorded (2026-11-06).**  Each
pipeline run's artifacts now carry `execution.json` for the final
execution and every `attempt-<n>/` (exit code, sandbox kill at the
wall-clock limit, elapsed seconds, refinement kind, `RESULT:` values
parsed), and each evidence `CELL.md` shows them in an "Executions" table;
cells built from older artifacts (all 512 in the committed tree) say
"Execution metadata not recorded".  It would have settled two cases this
section could only infer: Forsythe seeded/independent 0/13 in frozen
sample 3 (a 300 s kill, inferred), and a Douenne independent final
execution whose container was seen running 18 minutes against the 300 s
limit (results complete, kill status unknown).  Harness only; the
pipeline is unchanged.

### 3.9 A 24th evaluation paper under rule R7 (2026-11-06) — ✅ measured, no API spend

**What ran.**  `molina-garzon-2022-decentralization-cooperation` (AJPS
2022; corpus pass 4, rule R7, PR #134; 12 claims, 7 I4R rows, verdict
reproducible; 0.6 MB Dataverse package) was run three times by each
system, the same way as the other 23.  The pipeline ran frozen through
the desktop oracle (`RETALLY_PIPELINE_FROZEN=1`), labels `desktop-opus`,
`desktop-opus-run2` and `desktop-opus-run3`, all modes.  The agent ran as
Claude Code cells: run ids `2026-11-06-a` and `-b` in all modes,
`2026-11-06-c` in independent and blind.  No API spend.  Six files
(PR #135), each rescored under the count policy with 0 flips:

- `benchmark/results/pipeline-oracle-desktop-opus-1paper-all-modes-2026-11-06.json`
- `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-all-modes-2026-11-06.json`
- `benchmark/results/pipeline-oracle-desktop-opus-run3-1paper-all-modes-2026-11-06.json`
- `benchmark/results/claude-code-1paper-all-modes-2026-11-06.json`
- `benchmark/results/claude-code-run2-1paper-all-modes-2026-11-06.json`
- `benchmark/results/claude-code-run3-1paper-indep-blind-2026-11-06.json`

**Counts, 12 claims** (final, first scored in brackets):

| Sample | Pipeline seeded | Pipeline independent | Pipeline blind | Agent seeded | Agent independent | Agent blind |
|---|---|---|---|---|---|---|
| 1 | 12 (12) | 12 (6) | 6 (6) | 12 (12) | 12 (12) | 12 (12) |
| 2 | 12 (12) | 12 (6) | 6 (6) | 12 (12) | 12 (12) | 12 (12) |
| 3 | 12 (12) | 6 (6) | 12 (12) | — | 12 (12) | 12 (12) |

Each pipeline independent cell ran one claim refinement; in sample 3 it
did not help.  The agent logged one error repair in run b blind and one
in run c independent, both its own tooling slip: Docker started before
the script file existed (the shell refused the heredoc in b, the copy
was refused in c), so Docker bind-mounted an empty directory and nothing
ran.  Both are recorded in the cells' `reproduction.json`.

**Why the pipeline missed Table 3.**  Every pipeline miss is the same
six claims: Table 3's four Poisson coefficients and its two Ns, printed
`NA`.  Table 2 (weighted OLS on the game panel) passed in all nine
cells.  From the evidence cells (`CELL.md`, `output/script.R`,
`output/stdout.txt`, `prompt/`), the three failing cells failed the same
way:

- The prompt's data inventory lists the network CSV's columns but cuts
  the list off at `…,Participant_G,Partic…`.  The columns that hold the
  answer, `net_crosslevel_propnumknown` / `propnumfriends` (the tie
  counts) and `net_crosslevel_propdenomknown` / `propdenomfriends` (the
  possible ties, whose log is the offset), come after the cut.
- Each script therefore searched the CSV for count columns at run time.
  Its patterns skipped them (they exclude names containing `prop`, read
  as proportions; sample 2 blind's even classed some as denominators)
  and fell back to building per-participant tie counts from
  `Participant_A/C/G/R`, read as dyadic tie columns.  Those are the
  player-type dummies (the YAML's package notes; the authors' full model
  uses `Participant_C/G/R` as controls).
- Every constructed count was 0.  `fepois` stopped on "the dependent
  variable is a constant" in samples 1 and 2 blind (all four models) and
  on "0 observations" in sample 3 independent, and each script's
  `tryCatch` printed `NA`.  The weights (`weights_games_full_scaled`,
  present in the CSV), the offset and the municipality cluster were
  coded correctly and never reached.
- In independent mode all three samples first scored 6 this way.  In
  samples 1 and 2 the first script printed the CSV's column names, the
  claim-refinement prompt carried that stdout, and the corrected script
  used `propnum*` / `propdenom*` and passed 12.  In sample 3 the first
  script crashed (`object 'fit' not found`) before printing them, the
  refinement prompt never named the `net_crosslevel` columns, and the
  second script rebuilt the counts from the dummies again (0 observations).
- Blind mode has no claim refinement.  Sample 3 blind passed because its
  pattern found `net_crosslevel_hoursrcknown` / `hoursrcfriends` as the
  counts with `propdenomknown` as the offset: not the authors' variables,
  but inside every ±1 SE band (0.193, 0.174, 0.574, 1.029 against 0.22,
  0.24, 0.61, 1.07; Ns 231 / 226 exact).
- Seeded, the authors' R script names the columns; all three samples
  passed 12 with the authors' values (0.218, 0.240, 0.607, 1.074).

So it is one failure, reached three times: a truncated inventory plus a
column-name heuristic, not the second dataset's estimator.  The
taxonomy counts the six first-sample blind misses as data-file
resolution (the right file, the wrong columns).  The truncation is a
pipeline prompt property; the pipeline stays frozen and this is
recorded, not fixed.

**Agent deviations** (from `reproduction.json`; none changes a scored
value): the blind run a agent inferred the `p_type` coding (1 = A ...
4 = R) from counts; several agents used `gen_trust` as coded in the CSV
(1/2, the codebook says 0/1), which moves only the intercept; for
Table 2's SEs the run b independent agent used HC1 and the run c
independent agent clustered by municipality, where the do-file clusters
by participant (coefficients unaffected); the one participant without a
matching weight is dropped (232 → 231), as the authors' weighted model
does.

**I4R rows.**  All 7 paired rows are robustness variants (five Table 2
rows drop the individual controls; two Table 3 rows refit as OLS on the
proportion), so the entry records the paper's printed value under the
team's blanket verdict ("same output") as `i4r_replicator_findings`.
"Agrees with I4R" on this paper therefore means agreeing with the paper
on those 7 claims.  `n_claims_with_i4r_match` is 7 in every cell that
passes 12; in the three pipeline cells with Table 3 `NA` it is 5, and
`agrees_with_i4r` is still true because the I4R comparison skips claims
with no reproduced value (the same artifact as Bokobza blind, report
Section 4.7).

**Caveats.**  (1) Leak path noted in the YAML: the game `.dta` ships the
authors' fitted values and CI bounds from the Table 2 models
(`outcome_ols_1`, `standarderror_ols`, `highconf_1`, `lowconf_1`,
`outcome_ols_2`, …); the strip rule never touches data files, and
regressing `outcome_ols_1` on the regressors would recover the column 1
coefficients, not the SEs or the column 2 interaction.  The run c blind
agent says it dropped those columns unread; no cell reports using them.
(2) Table 2's note says robust SEs; the do-file clusters by participant.
Only coefficients and Ns are pinned with SE bands, so the band is the
printed SE either way.  (3) The open text is the Wiley Early View print
(NSF PAR); whether the issue PDF (pp. 554-569) differs was not checked.

**Totals, 24 papers, 290 claims** (recomputed the way
`docs/report/tables.py` does; the 23-paper figures in brackets):

| Mode | Pipeline 1 | Pipeline 2 | Pipeline 3 | Agent 1 | Agent 2 | Agent 3 | Gap range (pairings) |
|---|---|---|---|---|---|---|---|
| seeded | 275 (263) | 277 (265) | 266 (254) | 289 (277) | 278 (266) | — | 1 to 23 (6) [1 to 23] |
| independent | 251 (239) | 238 (226) | 233 (227) | 280 (268) | 283 (271) | 277 (265) | 26 to 50 (9) [26 to 45] |
| blind | 179 (173) | 182 (176) | 193 (181) | 264 (252) | 263 (251) | 262 (250) | 69 to 85 (9) [69 to 79] |

First-sample gap: 14 / 29 / 85 (14 / 29 / 79 on the 23).  The
independent top end moves to 50 because pipeline sample 3 lost six
claims on this paper; the blind top end to 85 because sample 1 did.
Cells identical in all three pipeline samples: 18 / 10 / 6 of 24; in
all agent samples: 23 / 20 / 18 of 24.

**What stays 23-paper.**  The memorization probe
(`probe-desktop-opus-2026-11-02.json`) was not run on this paper, so the
probe tables stay 23-paper.  The post-fix samples (3.8.1, 3.8.3) predate
it and stay 23-paper, never pooled.  The ROADMAP checks of 3.5-3.7.3 in
the discrepancy table recompute over the same 23 papers (`TWENTY_THREE`
in `tables.py`), so that table is unchanged.

**Report.**  `docs/report/tables.py` reads the six files (first samples
into the pooled rows, the others into the variance tables), derives 24
evaluation papers from the catalog, and adds 1-paper (3.9) and
23-paper rows beside the 24-paper rows; `docs/report/draft.md` gets a
seventh pass (title "twenty-four", pass 4 in Section 3.1.1, the Table 3
paragraph in Section 4.8, the taxonomy and limitations updates).
`benchmark/results/REPORT.md` is re-rendered with the first-sample files.

**Evidence.**  `benchmark/evidence/molina-garzon-2022-decentralization-cooperation/`
has 17 cells (9 pipeline, 8 agent); the tree has 529 (512 + 17).

**Next:** nothing on the pipeline (frozen); the openICPSR packages remain
the user's call.

#### Harness note — `agrees_with_i4r` and missing values (2026-11-06)

**Before.**  `benchmark/runner.py::_score_against_i4r` skipped a claim the
I4R replicator valued when Retally printed no value for it, and set
`agrees_with_i4r` when every *remaining* claim matched.  A cell that
printed NA for some replicator-valued claims could therefore read as
"paper ✗, I4R ✓", the combination meant to say the replicators found a
different number, when Retally had in fact produced nothing for those
claims.  `agrees_with_paper` already counted a missing value as a miss.

**Now.**  A replicator-valued claim with no Retally value counts as
attempted and not matching, so `agrees_with_i4r` is False;
`n_claims_with_i4r_match` is unchanged, and the flag is still None when
no finding carries a value.  Harness-only: nothing under `src/retally/`
changed, and no run was repeated.

**Rescore.**  `uv run python -m benchmark.rescore --policy i4r-missing
benchmark/results/*.json` applied the rule offline to the stored rows
(only `True` → `False` is possible).  It stamps a second top-level key,
`rescored_i4r_missing`, beside the count policy's `rescored`.  Eight rows
in eight files flipped (`benchmark/results/RESCORE-i4r-missing.md`):
the six expected (Manekin blind on `claude-opus-4-7`, 6 of 12 valued
claims missing; Bokobza blind in the oracle 4-paper and post-fix2
files, 7 of 11; Molina-Garzón blind in the oracle 1-paper sample 1 and 2
files and independent in sample 3, 2 of 7), plus two more: the same
Manekin blind cell in `pipeline-10papers-all-modes-2026-10-21.json` (the
file the report reads for `claude-opus-4-7`), and the pre-3.4 Dincecco
independent row in `pre34-promptonly-both-run1-2026-10-19.json` (12 of
13; not read by the report).  In the report's
verdict table the "paper ✗ I4R ✓" column now holds only the agent's
three Grier rows (the claim missed has no I4R value) and its independent
Forsythe row (a real value, −0.585 against the paper's −0.49 and I4R's
−0.578; `docs/report/draft.md` Section 4.7).  `benchmark/results/REPORT.md`
was re-rendered from the same first-sample files (I4R agreement 2 → 1 of 7
on `claude-opus-4-7`, 6 → 4 of 19 on desktop Opus), and the
`eval-7papers` report snapshot under `tests/fixtures/` was updated to
match.  The evidence bundles of the three pipeline papers still show the
old flag until they are rebuilt.

---

## Phase 4 — Corpus growth (4 → 20–30 papers)

Goal: enough breadth that the final numbers mean something. PR #28's
funnel found 60 machine-readable runnable candidates (58 R, 2 Python) out
of 110 reports, but only ~9 R-runnable reports carry a public report link,
and open-data/open-paper attrition cut 5 researched candidates to 3
runnable. Growth is therefore a curation grind — budget it as such.

- **Promotion sprints:** batches of ~5 candidates from
  `benchmark/candidates/`, each needing manual research (paper URL,
  dataset URL, report URL, **publication date, package release date**).
  Record the funnel outcome for every researched candidate, including
  rejections — the funnel statistics are themselves a finding for the
  report.
- **Widen the funnel where it's cheap:**
  - *Gated-but-free data* (openICPSR sign-in): support a manual-placement
    escape hatch — a human downloads under their own account and points
    the entry at a local path; the runner records `data_access: manual` so
    provenance stays honest. This single change likely doubles the
    reachable pool (AEA journals dominate the corpus).
    **✅ Escape hatch built (2026-11-02, [PR #122](https://github.com/mggebara/Retally/pull/122)).** A zip saved
    unchanged under `benchmark/manual-packages/<I4R tag>/` (git-ignored,
    with a `SOURCE.txt` naming the openICPSR id and version) is referenced
    by `dataset.source: <that path>` plus `data_access: manual`; the
    downloader's new `DatasetSource.LOCAL` extracts it like a downloaded
    archive and records its path, size and sha256 in `metadata.json`; every
    result row and the evidence CELL.md / REPORT.md carry `data_access`. A
    local path without `manual` is a load-time schema error; a manual entry
    whose file is absent is a `manual_package_missing` skip naming the file
    to place. No package has been placed yet; the 33 wanted are listed in
    `benchmark/corpus/openicpsr-wanted.md`. See `benchmark/README.md`,
    "Manually placed packages".
  - *Report-URL recovery:* the I4R discussion-paper index can be searched
    by paper title by a human; `replicator_team` IDs can't be mapped
    mechanically, so treat this as part of promotion research, not
    tooling.
  - Stata-original papers stay in scope **only** when I4R wrote an R
    routine (that's the ground truth that makes them scorable). Their
    Stata `.do` files are still usable as seeded-mode input.
- **Cost controls, added only when the spend justifies them** (in this
  order): Anthropic server-side prompt caching on the shared paper-text
  prefix; model tiering (extraction on a cheaper model, generation stays
  on the strongest); per-run cost accounting in `results.json` so the
  report can state "$X per paper per mode" honestly. Both-mode runs share
  the extraction calls (identical prompts replay from the LLM cache), so
  the second mode costs roughly one generation + refinement budget.

**Exit criteria:** ≥20 catalog entries with pinned claims, SEs, I4R
findings, and both dates, ≥5 of them holdout; funnel statistics table
(sourced → researched → promoted → runnable, with rejection reasons)
committed.

---

## Phase 5 — The measurement and the report

Goal: turn the benchmark into the deliverable.

- **Freeze:** tag a harness version; full live run (cache cold,
  `RETALLY_LLM_CACHE=0`) over dev + holdout in both modes; run the holdout
  set 3× per mode to measure sampling variance and report it — a
  reproducibility benchmark that doesn't report its own variance would be
  an irony too far. The gap needs its own variance estimate, not just each
  mode's.
- **Contamination (stated, not "controlled"):** every paper is
  pre-cutoff for every current model, so the report says so up front,
  tabulates each entry's `publication_date` / `package_release_date`
  against the evaluated model's stated training cutoff, and does **not**
  present a pre/post-cutoff split it cannot populate. If I4R later
  publishes machine-readable post-cutoff replications, a small sub-sample
  is a welcome addition — a bonus, not a pillar, and one that expires with
  the next model release. Probe memorisation directly where cheap (e.g.
  ask for a paper's headline coefficient with no data access) and report
  the result alongside the gap.
- **Failure taxonomy:** classify every non-match, per mode (data-file
  resolution, specification mismatch, sample restriction, SE/cluster
  choice, tolerance artifact, extraction error, *under-specified methods
  section* — the last being independent-mode losses that seeded mode
  recovers). The per-stage success table in `REPORT.md` is the skeleton;
  the taxonomy is the flesh.
- **Write the report:** methods (say loudly and early which numbers are
  seeded/computational and which are independent), the seeded-vs-
  independent gap as the headline, the three-way verdict matrix per mode,
  closeness distributions, the tolerance policy per mode and why,
  funnel statistics, cost per paper, variance, limitations
  (contamination, both modes see target values, independent-mode result
  tables on disk, tolerance choices, R-only scope). Venue options:
  arXiv/SocArXiv preprint, I4R discussion-paper series (engage them —
  they have run AI replication games and this is directly adjacent), or a
  methods journal.
- **Publish the artifact:** the catalog, pinned claims, transcribed I4R
  values, dates, and harness are the reusable contribution — license them
  clearly (data already MIT via the I4R meta-database) and document how
  others plug in a different model/agent via the Phase 2 protocol. If the
  benchmark outlives the pipeline, that is success, not failure.
- **Hand-checkable evidence:** every scored cell gets an evidence bundle —
  the exact prompt, the raw output, the per-claim scoring against the
  catalog and a `CELL.md`, pulled together per paper in a `REPORT.md`
  (`python -m benchmark.evidence`; see "Evidence bundles" in
  `benchmark/README.md`).  Committed so far for grier-2023, montero-2022
  and hanlon-2022 under `benchmark/evidence/`.

**Exit criteria:** preprint-quality report + citable frozen benchmark
release.

---

## Standing rules (all phases)

1. **No new machinery before Phase 1 exits.** The infrastructure debt is
   negative; the result debt is the whole balance sheet. (The 1.4 mode
   switch is the exception that proves the rule: without it the Phase 1
   result could not be stated honestly.)
2. **Every pipeline-behavior PR shows a before/after `benchmark.compare`**
   on the dev set, in each mode it affects, or states why it can't (docs,
   refactor).
3. **Honesty invariants stay:** typed skips over silent failures, three
   verdicts never collapsed into one, **two modes never pooled into one
   number**, committed `REPORT.md` always reflects the latest real run.
4. **Demo path stays frozen.** The sklearn/UCI flow is a smoke test and a
   README worked example — it gets bugfixes only, no features.

## Risks worth naming

| Risk | Mitigation |
|---|---|
| Seeded passes get read as independent replication | Mode recorded on every result and cache key; report presents modes side by side; this roadmap's north star says which is which |
| Independent reproduction is just hard; scores stay near zero | The gap and the failure taxonomy make "why" the finding — "the methods section does not pin down the specification" is a result about the literature; a well-measured negative result over 20+ papers is still publishable |
| Training-data contamination inflates scores | Cannot be controlled with this corpus (all 2022–23, all pre-cutoff); stated up front, dates recorded per entry, memorisation probed where cheap, gap framed as conditional on whatever the model knows |
| Independent mode leaks: package scripts on disk and named in the dataset listing | Fixed in the benchmark (Phase 2): independent runs see a script-free copy, so scripts are neither listed nor mounted. Result tables, logs and code under other names are stripped by content since the strip-rule change (manifest beside the copy). Still open: READMEs and summary-statistics tables shipped in the package, and direct `validate()` callers outside the harness (prompt-only withholding) |
| Wider independent tolerance flatters independent mode | Tolerance policy reported per mode; claims lost/gained listed individually; SE band never narrower than the relative tolerance, and only applies where an SE is pinned |
| Corpus curation stalls (manual research per paper) | Manual-placement escape hatch for gated data; batch sprints; accept 20 papers as sufficient N |
| General-purpose agents make the bespoke pipeline obsolete | The moat is the *benchmark*; Phase 2 formalises the agent protocol so any agent can be scored on it |
| ~~Name collision with the OpenRA game engine~~ | Renamed to Retally (Phase 0.2, done) |
