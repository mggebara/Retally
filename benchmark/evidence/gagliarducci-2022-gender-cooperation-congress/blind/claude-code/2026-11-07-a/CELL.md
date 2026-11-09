# gagliarducci-2022-gender-cooperation-congress · blind · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T09:30:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261108T015650Z` |
| Run directory | `benchmark/reproductions/gagliarducci-2022-gender-cooperation-congress/blind/2026-11-07-a` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 9/13 (execution 3) |
| Final | **9/13** |
| Package files withheld | 152 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.39277 | 0.16% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 2.39634 | 23.90% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 6.59777 | 2.02% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 2.79161 | 10.64% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -2.43795 | 61.99% | ±0.419 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -5.13248 | 53.16% | ±1.91 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -2.17244 | 79.84% | ±0.525 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 4.31565 | 17.72% | ±0.916 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 2.71315 | 6.60% | ±0.82 (se_band) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60669 | 0.00% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4746 | 0.00% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 22712 | 30.85% | ±1642.3 (relative) | FAIL | FAIL |
| `n_bills_pct_opposite_rep_ols` | 27669 | 18691 | 32.45% | ±1383.45 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/13 pass, which agrees with the row's 9/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Percent of opposite-party cosponsors uses the dataset's pct_cosponsors_opposite (opposite / cosponsors, missing when a bill has zero cosponsors), times 100; paper footnote 11 describes a cosponsors+1 denominator, which the analysis file does not implement.
- (reproduction.json) RD bandwidths: used the bandwidths stated in the task for these rows (13 for Republican number of cosponsors, 24 for Democratic percent opposite). The R rdrobust mserd bandwidth on bill-level observations gives 17.8 and 16.5 (printed in stdout); the paper used the 2014 CCT Stata implementation, not available in R.
- (reproduction.json) Propensity scores estimated by probit (estimator truncated in the task text), ATE inverse-probability weights 1/p for women and 1/(1-p) for men, estimated at bill level separately by party; no Congress dummies in the propensity model.
- (reproduction.json) Constructed controls: rookie = tenure 1; committee leader = chair or ranking member; 5 occupation dummies = occ1-occ5 (unknown and miscellaneous as base); total bills sponsored = count of public bills by sponsor-Congress in the file; 3 macro-area dummies = Census regions from ICPSR state codes (South omitted); log population density = lnpop - lnarea; margin of victory of the elected candidate = 100*\|MV1_democrat\|.
- (reproduction.json) Within-party regressions drop the party dummy; missing covariates handled by listwise deletion; fixest drops fixed-effect singletons.

Agent notes: Sample: House public bills (private==0) in the bills_analysis_101-111_replication.dta file. Col 1 OLS: outcome on female, 33 committee-of-referral dummies, minor-topic FE, Congress FE, sponsor and district characteristics, SEs clustered by sponsor-Congress (state-district-term_served-Congress). Col 2 RD: mixed-gender races with \|MV1_female\| <= h, female, MV, female*MV, Congress FE, unweighted. Col 3: same within h plus committee dummies and minor-topic FE, weighted by inverse probit propensity score from district characteristics estimated within the bandwidth. Cols 4/5: all races, outcome on female + committee dummies + minor-topic FE + Congress FE, IPW from probit on district characteristics + winner's margin (col 4) plus sponsor characteristics (col 5). n_sponsor_terms is the number of sponsor-Congress clusters in the column-1 estimation sample. Two exploratory runs (attempt-1, attempt-2) inspected variables only and printed no RESULT lines; the final script was the first and only scored run.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 31,545 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261108T015650Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 941 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261108T015650Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 303 bytes, from `benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/blind/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,454 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261108T015650Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261108T015650Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 15,209 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261108T015650Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 266 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261108T015650Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,616 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261108T015650Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261108T015650Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,219 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261108T015650Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 265 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261108T015650Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,961 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261108T015650Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,385 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261108T015650Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,056 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261108T015650Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,102 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261108T015650Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 266 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261108T015650Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
