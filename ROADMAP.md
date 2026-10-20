# Roadmap

## North star

This project's credible destination is a **research artifact**, not a
validation product: a rigorous public benchmark and a measured answer to
the question *"can LLM agents independently replicate published
econometrics?"*

Concretely, the end state is:

- a curated catalog of **20–30 papers** drawn from the I4R replication
  corpus, each with pinned headline claims and transcribed human-replicator
  ground truth;
- a frozen harness run over that catalog producing the **three-way verdict
  matrix** (`retally_ran` / `agrees_with_paper` / `agrees_with_i4r`),
  per-stage success rates, closeness distributions, and a failure
  taxonomy;
- a **technical report** presenting those numbers honestly, positioned
  alongside I4R's own AI replication-games work.

The distinctive measurement — the reason this is worth doing at all — is
that the pipeline performs **independent reproduction** (regenerate the
analysis from the paper's text) rather than computational reproduction
(re-run the authors' code), and scores the result against *both* the
paper's stated values and the human replicators' values. `agrees_with_paper
✓ / agrees_with_i4r ✗` is a signal no one else is producing at scale.

Everything below is ordered by a single rule: **the next PR moves the
reproduction number, not the machinery.** The infrastructure (caching,
splits, closeness metrics, compare tooling) is already ahead of the result
it measures. Current state of the core result: **0 / 102 claims** on the
one paper ever run end-to-end (Dincecco et al. 2022).

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

## Phase 1 — First nonzero reproduction (Dincecco 2022)

Goal: drive `dincecco-2022-india-warfare` from 0 matched claims to a
majority of *headline* claims matched. No new general infrastructure until
this lands. Both PR #24 and PR #25 already named these as the next step;
this phase is that step.

### 1.1 Seed the replication package's own scripts into codegen — ✅ built
*(highest leverage — do first; implemented 2026-07, awaits live verification
under 1.3)*

The Zenodo package the pipeline already downloads contains the authors'
own `.do`/`.R` scripts — the ground truth of the estimating equation. They
never reach the prompt: `select_relevant_files`
(`src/retally/code/selector.py`) only walks cloned GitHub repos and only
globs `*.py`, so the generator reconstructs the specification blind and
emits all-`NA` coefficients.

- Extend selection to also walk `dataset.local_path` when the dataset is a
  replication package (heuristic: contains `.do`/`.R`/`.Rmd` files).
- Accept `.R`, `.do`, `.Rmd` for R-language papers. A Stata `.do` file is
  a perfectly good *specification description* for an R generator — the
  prompt should say "translate the specification, do not transliterate the
  syntax."
- Language-aware scoring: prefer `master.do`, `main*.R`, `*tables*`,
  `*analysis*`; skip data-construction-only scripts when over budget.
  Keep the existing caps (files/bytes) and truncation markers.
- Render them through the existing `_reference_implementation_section`
  in `generator.py` (a new "Original replication scripts" variant), so
  Phase-1/Phase-2 refinement semantics stay unchanged.
- Tests: selector picks the right files from a fixture package tree;
  prompt contains the script text for R papers; Python/registry-dataset
  flow is byte-identical (zero churn to the demo path).

### 1.2 Pin curated headline claims — ✅ built
*(rubric written into `benchmark/README.md`; five headline Table 1 claims
pinned for Dincecco with I4R findings.  Four more Table 1 estimates are
identified in the entry's notes but need paper access to map to columns —
finish that mapping during 1.3, where the runner downloads the PDF anyway.)*

Scoring against 102 auto-extracted claims (every coefficient, SE, and R²
in the paper) is the wrong yardstick — I4R replicators verify headline
estimates. The pinned-claims workflow (PR #26) exists and
`original_claims` is still `[]`.

- Adopt a written curation rubric (add to `benchmark/README.md`):
  a headline claim is (a) in the paper's abstract or main results table,
  (b) an estimate the paper's conclusions rest on, (c) numerically stated.
  Target 8–12 per paper. Exclude summary stats, robustness appendix
  coefficients, and anything the text calls "suggestive."
- For Dincecco: Table 1 headline coefficient 3.713 (SE 0.305), the
  ~1.47 with-controls estimate, N=660, plus the handful of Table 1/2
  companions — seeded via the `extracted_claims/` dump workflow, reviewed
  by hand.
- Populate `i4r_replicator_findings` from I4R DP35 where it publishes
  values, activating `agrees_with_i4r` for the first time.

### 1.3 Iterate to green, with discipline

- Live run → `benchmark.compare` against the saved baseline → keep or
  revert. The LLM cache keeps each iteration cheap; pinned claims keep the
  yardstick frozen.
- Fix what the closeness metrics say is broken, in order of the gradient
  (5×-tolerance band first). Expected culprits after 1.1/1.2: sample
  restrictions, fixed-effects/cluster choices, and the near-zero
  `COEFFICIENT` tolerance problem — implement the already-documented
  SE-aware comparison (pass if within ±k·SE of the reported value, k
  configurable, default 1) *only if* it is actually what blocks a match.

**Exit criteria:** ≥50% of Dincecco's pinned headline claims within
tolerance, `REPORT.md` committed showing it, and a short writeup in the
catalog entry's `notes` of what each remaining miss is.

---

## Phase 2 — A real baseline (all four runnable entries)

Goal: prevent overfitting to one paper before any prompt tuning. The
dev/holdout machinery exists precisely for this.

- Pin headline claims (rubric from 1.2) for `alesina-2022`,
  `bisbee-2022`, and holdout `arias-2022`; transcribe the meta-database's
  `o_coeff_dbl` / `r_coeff_dbl` values into `i4r_replicator_findings`
  during the same pass — the corpus already carries the exact
  `agrees_with_i4r` ground truth (flagged in PR #28 as a "latent
  goldmine"; this is where it gets mined).
- Run the three dev entries live; commit `REPORT.md`. Arias (holdout)
  runs once, only to confirm the harness handles it — its numbers are not
  for tuning.
- Only after this baseline exists: prompt tuning sweeps on dev, holdout
  confirmation runs rarely, `benchmark.compare` as the keep-or-revert
  gate. This is the loop `benchmark/README.md` already describes; Phase 2
  is what makes it legitimate to start.

**Exit criteria:** committed baseline over ≥3 dev papers with pinned
claims and I4R findings; documented per-paper failure notes; tuning loop
demonstrably running (≥1 kept improvement with before/after compare
output in the PR).

---

## Phase 3 — Corpus growth (4 → 20–30 papers)

Goal: enough breadth that the final numbers mean something. PR #28's
funnel found 60 machine-readable runnable candidates (58 R, 2 Python) out
of 110 reports, but only ~9 R-runnable reports carry a public report link,
and open-data/open-paper attrition cut 5 researched candidates to 3
runnable. Growth is therefore a curation grind — budget it as such.

- **Promotion sprints:** batches of ~5 candidates from
  `benchmark/candidates/`, each needing manual research (paper URL,
  dataset URL, report URL). Record the funnel outcome for every researched
  candidate, including rejections — the funnel statistics are themselves a
  finding for the report.
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
    routine (that's the ground truth that makes them scorable).
- **Cost controls, added only when the spend justifies them** (in this
  order): Anthropic server-side prompt caching on the shared paper-text
  prefix; model tiering (extraction on a cheaper model, generation stays
  on the strongest); per-run cost accounting in `results.json` so the
  report can state "$X per paper" honestly.

**Exit criteria:** ≥20 catalog entries with pinned claims and I4R
findings, ≥5 of them holdout; funnel statistics table (sourced →
researched → promoted → runnable, with rejection reasons) committed.

---

## Phase 4 — The measurement and the report

Goal: turn the benchmark into the deliverable.

- **Freeze:** tag a harness version; full live run (cache cold,
  `RETALLY_LLM_CACHE=0`) over dev + holdout; run the holdout set 3× to
  measure sampling variance and report it — a reproducibility benchmark
  that doesn't report its own variance would be an irony too far.
- **Contamination analysis (must-have for credibility):** the model may
  have seen these papers, replication packages, and I4R reports in
  training. Mitigations to implement and report: (a) note each paper's
  publication date vs. the model's training cutoff; (b) include a small
  post-cutoff sub-sample (I4R publishes new reports continually — 2024–25
  games); (c) report results split by pre/post-cutoff. If post-cutoff
  performance collapses, that *is* the finding — publish it.
- **Failure taxonomy:** classify every non-match (data-file resolution,
  specification mismatch, sample restriction, SE/cluster choice, tolerance
  artifact, extraction error). The per-stage success table in `REPORT.md`
  is the skeleton; the taxonomy is the flesh.
- **Write the report:** methods (independent reproduction, not re-running
  packages — say this loudly), the three-way verdict matrix, closeness
  distributions, funnel statistics, cost per paper, variance, limitations
  (contamination, tolerance choices, R-only scope). Venue options:
  arXiv/SocArXiv preprint, I4R discussion-paper series (engage them —
  they have run AI replication games and this is directly adjacent), or a
  methods journal.
- **Publish the artifact:** the catalog, pinned claims, transcribed I4R
  values, and harness are the reusable contribution — license them
  clearly (data already MIT via the I4R meta-database) and document how
  others plug in a different model/agent. If the benchmark outlives the
  pipeline, that is success, not failure.

**Exit criteria:** preprint-quality report + citable frozen benchmark
release.

---

## Standing rules (all phases)

1. **No new machinery before Phase 1 exits.** The infrastructure debt is
   negative; the result debt is the whole balance sheet.
2. **Every pipeline-behavior PR shows a before/after `benchmark.compare`**
   on the dev set, or states why it can't (docs, refactor).
3. **Honesty invariants stay:** typed skips over silent failures, three
   verdicts never collapsed into one, committed `REPORT.md` always
   reflects the latest real run.
4. **Demo path stays frozen.** The sklearn/UCI flow is a smoke test and a
   README worked example — it gets bugfixes only, no features.

## Risks worth naming

| Risk | Mitigation |
|---|---|
| Independent reproduction is just hard; scores stay near zero even after Phase 1 | The failure taxonomy makes "why" the finding; a well-measured negative result over 20+ papers is still publishable |
| Training-data contamination inflates scores | Phase 4 pre/post-cutoff split; post-cutoff sub-sample |
| Corpus curation stalls (manual research per paper) | Manual-placement escape hatch for gated data; batch sprints; accept 20 papers as sufficient N |
| General-purpose agents make the bespoke pipeline obsolete | The moat is the *benchmark* (catalog + pinned claims + I4R ground truth + metrics), which any agent can be scored on — keep the harness agent-agnostic |
| ~~Name collision with the OpenRA game engine~~ | Renamed to Retally (Phase 0.2, done) |
