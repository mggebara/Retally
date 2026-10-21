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
A target-blind variant (claims named but values withheld) is a possible
later mode, not part of this plan.

Everything below is ordered by a single rule: **the next PR moves the
reproduction number, not the machinery.** Current state (2026-10-21):
**three dev papers measured in both modes** (Opus 4.7, Docker R sandbox;
one seeded run and, for independent, one cached plus three cache-off
runs per paper — distributions, not yet rates).

- **Dincecco 2022 is closed.**  Seeded 13 / 13; independent 13 / 13 in
  all three cache-off runs, each exact on its *first* script with no
  refinement (Phase 1.8, after generic Stata-label matching in the `.dta`
  listing).  The road there: independent 0 / 13 in Phase 1.5, 1–12 in
  1.6, 13 / 13 in 4 of 7 runs in 1.7.
- **Alesina 2022 is the first specification-level gap.**  Seeded 7 / 11;
  independent 7 / 11 cached and 0, 6, 5 of 11 cache-off (first scored 1
  cached; 0, 5, 1 cache-off).  Both modes read the right file; the independent losses are
  reconstructions of the specification (outcome composition, sample
  trimming, index direction), plus one run that printed results under
  its own names (Phase 3, below).
- **Bisbee 2022 is partly measured.**  Seeded 10 / 11 on the 47-package
  sandbox image built in Phase 1.8.  Independent was measured only on the old
  image, where every first script crashed on a missing package (0 / 11
  cached; 8, 8, 5 cache-off, first scored 2, 4, 0); the new-image
  independent runs hit an exhausted API credit balance.

Read against the thesis: Dincecco's independent failures were all
package navigation (wrong file, then wrong column), now fixed
generically, so its 13 / 13 says the paper's text is enough to recover
its specification; Alesina's are the specification gap the thesis is
about.  The first-scored metric (Phase 1.8) separates derivation from
target-guided search, and Bisbee shows why it matters: 0–4 of 11 first
scored against 5–8 final in the cache-off independent runs.

The committed `REPORT.md` is built from one row per paper and mode
(listed under Phase 3, below).  Spend recorded for Phases 1.8 and 3:
about $14.27.

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

### 1.5 First independent run on Dincecco — ✅ done (2026-10-20) — gap 13 / 13
*(Seeded 13/13; independent 0/13 with the script-free mount (three runs:
0, 0, 0) and 0/13 with prompt-only withholding (three runs: 0, 0, 1, the
one pass a coincidental SE match).  Every loss has one cause: the model
loaded the wrong `.dta` and never found the outcome or instrument,
because `.dta` column names are not in the listing and the
claim-refinement prompt never shows stdout; per-claim notes, the
script-access check (clean), and a latent methodology-extraction error
are in the entry's `notes`; `benchmark/results/baseline-both-2026-10-19.json`.)*

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

## Phase 3 — dev-set baseline over three papers — ⚠ partly measured (2026-10-21)

Goal: prevent overfitting to one paper before any prompt tuning. The
dev/holdout machinery exists precisely for this.

*(Measured: Dincecco (Phase 1.8, above), Alesina, and Bisbee seeded on
the new sandbox image.  **Not measured: Bisbee independent on the new
image** — the API credit ran out on its first generation call.  Next:
re-run `measure` for bisbee independent ×3 cache-off, then the first
three-paper both-mode baseline.  Same protocol as 1.7–1.8: one
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
Independent: **not measured** (the `phase3b-bisbee-both` independent row
and the three `phase3b-bisbee-variance-*` files are "credit balance too
low" error rows with no claims scored; kept because they are honest
records of what ran).

- **Every first script crashed** on `library(MatchIt)` / `library(CBPS)`,
  not installed in the old image — which is what #48/#49 fix.
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
  The seeded script and two cache-off independent runs implemented the
  paper's window and got N = 1,591 (the others printed NA or 628).  On the new image seeded follows the package's filter
  and the three March claims pass; only `anti_estab_x_cases_interaction`
  fails (0.0138 vs −0.016).  Curation: the three contexts now quote the
  paper's own words for the sample (they paraphrased the same window
  before); values unchanged; the package filter and the N discrepancy are
  in the entry's `notes`.  A reproducer that follows the text is
  expected to fail these three claims: a "seeded ✓ / independent ✗"
  that is about the paper, not the model.

**`REPORT.md`** is built from a combined `results.json` (gitignored) of
six rows: Dincecco both rows from `phase18-dincecco-both-2026-10-20.json`,
Alesina both rows from `phase3-alesina-both-2026-10-20.json`, Bisbee
seeded from `phase3b-bisbee-both-2026-10-20.json` (new image) and Bisbee
independent from `phase3-bisbee-both-2026-10-20.json` (the old-image
cache-on 0 / 11 run; the new-image independent row is unmeasured).
First-scored fields for rows written before #45/#47 were filled from the
run artifacts with the `--rescore` scoring path.  It is a cross-run
composite, not one run, so its "Seeded vs independent" table is a
snapshot of the latest measurement per cell.

**Spend** (sum of row `usage.estimated_usd`): Dincecco $1.48 (Phase
1.8), Alesina $5.89, Bisbee $6.90 (including $0.41 billed on the
credit-error row before the balance ran out, and $0.17 on the 403 run);
total **$14.27**.  A cache-off independent run cost $0.25 (Dincecco),
$0.33–0.91 (Alesina), $1.35–1.47 (Bisbee, 8 calls each).

Still open from the original Phase 3 plan:

- Pin `arias-2022` (holdout): claims, I4R findings, dates.  *Claims, I4R
  findings and dates are pinned for `alesina-2022` and `bisbee-2022`.*
  Arias runs once, only to confirm the harness handles it — its numbers
  are not for tuning.
- Only after the three-paper baseline exists: prompt tuning sweeps on
  dev, holdout confirmation runs rarely, `benchmark.compare` as the
  keep-or-revert gate, always like-for-like per mode.  Tuning should
  target the **independent** number — tuning the seeded prompt mostly
  improves translation — and every kept change reports its effect on
  *both* modes, because a change that helps seeded and hurts independent
  widens the gap for the wrong reason.  Headline first scored, not final:
  final mixes derivation with target-guided search.

**Exit criteria:** committed both-mode baseline over ≥3 dev papers with
pinned claims (with SEs) and I4R findings — *two of three fully
measured; Bisbee independent on the current image outstanding*;
documented per-paper failure notes for every independent-mode loss —
*done for Dincecco and Alesina; Bisbee's old-image losses noted*; tuning
loop demonstrably running (≥1 kept improvement with before/after compare
output in the PR) — *not started*.

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
| Independent mode leaks: package scripts on disk and named in the dataset listing | Fixed in the benchmark (Phase 2): independent runs see a script-free copy, so scripts are neither listed nor mounted. Still open: result tables (`.tex`/`.csv`) and READMEs shipped in the package, and direct `validate()` callers outside the harness (prompt-only withholding) |
| Wider independent tolerance flatters independent mode | Tolerance policy reported per mode; claims lost/gained listed individually; SE band never narrower than the relative tolerance, and only applies where an SE is pinned |
| Corpus curation stalls (manual research per paper) | Manual-placement escape hatch for gated data; batch sprints; accept 20 papers as sufficient N |
| General-purpose agents make the bespoke pipeline obsolete | The moat is the *benchmark*; Phase 2 formalises the agent protocol so any agent can be scored on it |
| ~~Name collision with the OpenRA game engine~~ | Renamed to Retally (Phase 0.2, done) |
