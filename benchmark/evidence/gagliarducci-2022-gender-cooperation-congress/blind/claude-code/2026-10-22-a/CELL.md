# gagliarducci-2022-gender-cooperation-congress · blind · claude-code · 2026-10-22-a

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-22-a |
| Date | 2026-10-22T03:21:43Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-6papers-all-modes-2026-10-22.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T032229Z` |
| Run directory | `benchmark/reproductions/gagliarducci-2022-gender-cooperation-congress/blind/2026-10-22-a` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 7/13 (execution 3) |
| Final | **7/13** |
| Package files withheld | 152 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.42789 | 2.36% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 2.97745 | 5.45% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 5.95492 | 11.57% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 2.57983 | 17.42% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -2.43107 | 61.53% | ±0.419 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -5.13248 | 53.16% | ±1.91 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -2.08203 | 72.35% | ±0.525 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 4.77727 | 30.31% | ±0.916 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 1.94547 | 33.03% | ±0.82 (se_band) | FAIL | FAIL |
| `n_bills_ncosponsors_all_ols` | 60670 | 60669 | 0.00% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4746 | 0.00% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 22712 | 30.85% | ±1642.3 (relative) | FAIL | FAIL |
| `n_bills_pct_opposite_rep_ols` | 27669 | 18691 | 32.45% | ±1383.45 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/13 pass, which agrees with the row's 7/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Data: AnalysisData/bills_analysis_101-111_replication.csv, restricted to public bills (private==0) with non-missing sponsor info; listwise deletion on all regressors.
- (reproduction.json) Percent opposite-party cosponsors uses the dataset's pct_cosponsors_opposite (verified = opposite/number of cosponsors, missing when a bill has zero cosponsors) times 100, not opposite/(cosponsors+1) as described in the working-paper text.
- (reproduction.json) Constructed variables not in the file: rookie = tenure_run==1; committee leader = chair or ranking member (comc\|comr); total bills sponsored = count of public bills per sponsor-Congress in the file; census macro areas (Northeast base; Delaware coded South) from ICPSR state codes; log population density = lnpop - lnarea; sponsor-Congress cluster = Congress x state x district x term_served.
- (reproduction.json) Occupation entered as 6 dummies (occ1-occ6, occ0 base) since the file has 7 categories, not the 5 dummies stated in the notes.
- (reproduction.json) Bill characteristics: 33 committee-of-referral dummies as regressors plus minor-topic fixed effects; Congress fixed effects; fixest drops FE singletons (as reghdfe does).
- (reproduction.json) RD bandwidths taken from the task context (13 pp for Rep #cosponsors RD-IPW, 24 pp for Dem percent-opposite RD) rather than recomputed with CCT 2014 (rdbwselect_2014 not available in R); uniform kernel, linear with separate slopes in MV1_female.
- (reproduction.json) Propensity scores: probit of sponsor_female on district characteristics (macro areas, % black, % urban, % foreign born, % over 65, log median income, log density) plus Congress dummies, estimated at bill level separately by party; col 4 adds \|MV1_democrat\|*100 (margin of victory of the winner); col 5 further adds sponsor characteristics (age, tenure, rookie, leader, black, Ivy, born in state, bills sponsored, occupation dummies). ATE weights 1/p for women and 1/(1-p) for men; no trimming. Lagged Democratic share and campaign spending ratio not used (lagged share entirely missing in Congresses 101, 103, 108).

Agent notes: Two exploratory runs (variable inspection, missingness, outcome definition check, rdbwselect diagnostics; no RESULT lines), then one scored run. Outcome regressions with fixest feols, SE clustered by sponsor-Congress. Uncertain choices: probit vs logit for the propensity score, exact PS covariate set, bill-level vs member-level PS estimation, occupation coding, and whether the authors used missing-value imputation for controls. README.pdf/docx in the package were not read.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 30,793 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T032229Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 941 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T032229Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 290 bytes, from `benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/blind/2026-10-22-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 2,591 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T032229Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T032229Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 11,946 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T032229Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,235 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T032229Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 1,026 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T032229Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,899 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T032229Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 3,042 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T032229Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,865 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T032229Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 748 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T032229Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,754 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T032229Z/stdout.txt`
