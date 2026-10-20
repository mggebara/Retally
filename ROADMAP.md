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
reproduction number, not the machinery.** Current state of the core
result: **seeded 13 / 13 pinned headline claims** on Dincecco et al. 2022
(2026-10-19, `benchmark/results/baseline-2026-10-19.json`; was 0 / 102
auto-extracted claims in July) — one paper, one sampled generation, so not
yet a rate. **Independent: 0 / 13** (script-free mount, 3 runs: 0, 0, 0;
prompt-only withholding, 3 runs: 0, 0, 1) — Phase 1.5, below; still 0 / 13
after the Phase 1.6 plumbing fixes (measured through step 3; step 4 and the
variance runs blocked by API credit), with an offline counterfactual
showing the model's own specification hits 7 / 13 once the data file is
right.

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

### 1.6 Independent-mode plumbing fixes — ⚠ partly measured (2026-10-20)
*(Four fixes, one commit each: the comparator no longer scores a claim
with no RESULT line against another claim's value (independent "matched"
10 → 7 of 13, no verdict change); `.dta` column names in the dataset
listing; head/tail stdout/stderr in refinement prompts; the methodology
prompt no longer primes "standardised".  Seeded 13/13 after every step;
independent 0/13 after steps 1–3.  Step 2 fixed variable resolution
(right names) but the model chose `biclean.dta` (N=271) because
`conflictexposure.dta`'s 1288 columns are truncated before the outcome
and instrument.  Step 4's independent run, the three cache-off variance
runs, and a 2026-10-20 baseline were not run: the API account ran out of
credit.  Offline counterfactual (step-3 script, file swapped, no
`scale()`): 3/13, and 7/13 (every OLS claim, to 3–4 dp) once population
density is added to columns 1–2, which the claim token "bivariate"
misleads the model into dropping.  The IV claims were never attempted
(instrument not found).  Classification in the entry's `notes`;
`benchmark/results/phase16-step3-both-2026-10-20.json`.)*

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

## Phase 3 — A real baseline (all four runnable entries, both modes)

Goal: prevent overfitting to one paper before any prompt tuning. The
dev/holdout machinery exists precisely for this.

- Pin headline claims (rubric from 1.2, **with SEs**) for `alesina-2022`,
  `bisbee-2022`, and holdout `arias-2022`; transcribe the meta-database's
  `o_coeff_dbl` / `r_coeff_dbl` values into `i4r_replicator_findings`
  during the same pass — the corpus already carries the exact
  `agrees_with_i4r` ground truth (flagged in PR #28 as a "latent
  goldmine"; this is where it gets mined). Record both dates.
  *Status (2026-10-20): claims, I4R findings and dates pinned for `alesina-2022` and `bisbee-2022`; `arias-2022` still open.*
- Run the three dev entries live with `--mode both`; commit `REPORT.md`.
  Arias (holdout) runs once, only to confirm the harness handles it — its
  numbers are not for tuning.
- Only after this baseline exists: prompt tuning sweeps on dev, holdout
  confirmation runs rarely, `benchmark.compare` as the keep-or-revert
  gate, always like-for-like per mode. Tuning should target the
  **independent** number — tuning the seeded prompt mostly improves
  translation — and every kept change reports its effect on *both* modes,
  because a change that helps seeded and hurts independent widens the gap
  for the wrong reason.

**Exit criteria:** committed both-mode baseline over ≥3 dev papers with
pinned claims (with SEs) and I4R findings; documented per-paper failure
notes for every independent-mode loss; tuning loop demonstrably running
(≥1 kept improvement with before/after compare output in the PR).

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
