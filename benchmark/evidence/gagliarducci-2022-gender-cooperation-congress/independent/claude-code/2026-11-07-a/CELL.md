# gagliarducci-2022-gender-cooperation-congress · independent · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T20:01:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261108T015651Z` |
| Run directory | `benchmark/reproductions/gagliarducci-2022-gender-cooperation-congress/independent/2026-11-07-a` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 3) |
| Final | **13/13** |
| Package files withheld | 152 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.3928 | 0.16% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 2.3963 | 23.90% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 6.6978 | 0.54% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 2.7456 | 12.11% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -1.5203 | 1.02% | ±0.419 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -2.7358 | 18.36% | ±1.91 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -1.2481 | 3.32% | ±0.525 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 3.1467 | 14.17% | ±0.916 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 2.8388 | 2.28% | ±0.82 (se_band) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60669 | 0.00% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4746 | 0.00% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 32844 | 0.01% | ±1642.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_rep_ols` | 27669 | 27668 | 0.00% | ±1383.45 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Percent of opposite-party cosponsors rebuilt as 100*numb_cosponsors_opposite/(numb_cosponsors+1) per paper fn. 11 (the stored pct_cosponsors_opposite is missing for zero-cosponsor bills); bills with more opposite-party cosponsors than cosponsors set to missing.
- (reproduction.json) Sponsor characteristics: rookie = tenure 1; committee leader = comc or comr; 5 occupation dummies taken as occ1-occ5 (occ0 unknown and occ6 misc as reference); number of bills sponsored computed per sponsor-Congress from the bill file. District: 3 census-region dummies from ICPSR state codes, log density = lnpop - lnarea.
- (reproduction.json) RD columns use the bandwidths reported in the paper (13 for Republican cosponsors, 24 for Democratic pct-opposite) on mixed-gender races with \|MV1_female\| <= h, uniform weights; the CCT mserd bandwidths computed with rdrobust on bill-level data (17.8 and 30.9) are printed as diagnostics only.
- (reproduction.json) Propensity scores: bill-level logits of the female dummy; column 3 on district characteristics within the bandwidth; columns 4/5 on district characteristics plus \|MV1_democrat\| (margin of victory of the winner), plus sponsor characteristics in column 5; ATE weights 1/p and 1/(1-p).
- (reproduction.json) fixest drops one singleton fixed-effect observation, so bill counts are 1-3 lower than the paper's.

Agent notes: Two exploratory runs (variable inspection, sample counts; no RESULT lines) then one estimating run, which is the final run. I compared it with the claims once using check_attempt, which reported all claims within tolerance, so the script was left unchanged and no claim attempt is recorded. Bill-level OLS/RD/IPW regressions with Congress FE (+ minor-topic FE and 33 committee-of-referral dummies where bill characteristics apply), SEs clustered by sponsor-Congress. Largest gaps from the printed values: Republican OLS cosponsors 2.40 vs 3.149, Republican col-5 IPW 2.75 vs 3.124, Democratic RD pct-opposite -2.74 vs -3.351. No hung docker runs.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 30,985 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261108T015651Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 973 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261108T015651Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 290 bytes, from `benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/independent/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,188 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261108T015651Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261108T015651Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 14,624 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261108T015651Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 272 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261108T015651Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,111 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261108T015651Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261108T015651Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,134 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261108T015651Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 271 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261108T015651Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,507 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261108T015651Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,346 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261108T015651Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,086 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261108T015651Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,336 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261108T015651Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 272 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261108T015651Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
