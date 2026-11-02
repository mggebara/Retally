# gagliarducci-2022-gender-cooperation-congress · independent · claude-code · 2026-10-22-a

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-22-a |
| Date | 2026-10-22T03:10:46Z |
| Results file | `benchmark/results/claude-code-6papers-all-modes-2026-10-22.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261022T032229Z` |
| Run directory | `benchmark/reproductions/gagliarducci-2022-gender-cooperation-congress/independent/2026-10-22-a` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 2) |
| Final | **13/13** |
| Package files withheld | 152 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.3232 | 5.15% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 2.3963 | 23.90% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 6.6978 | 0.54% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 2.7456 | 12.11% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -1.7783 | 18.16% | ±0.419 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -2.41 | 28.08% | ±1.91 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -1.5314 | 26.77% | ±0.525 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 4.1659 | 13.64% | ±0.916 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 3.1063 | 6.93% | ±0.82 (se_band) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60669 | 0.00% | ±606.7 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4746 | 0.00% | ±47.46 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 32846 | 0.00% | ±328.46 (relative) | PASS | PASS |
| `n_bills_pct_opposite_rep_ols` | 27669 | 27670 | 0.00% | ±276.69 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) RD columns (2)-(3) use the optimal bandwidths reported in the paper (25/30/13 for number of cosponsors, 16/24/11 for percent opposite) rather than the bandwidths from rdrobust::rdbwselect (mserd, bill level), which the script also computes and prints (e.g. 17.8 for Republicans/number of cosponsors, 25.0 for Democrats/percent opposite).
- (reproduction.json) Macro-area dummies were built from ICPSR state codes (Northeast 1-14, Midwest 21-37, South 40-56, West 61-82), since no region variable is in the data. Log population density = lnpop - lnarea.
- (reproduction.json) Rookie = tenure_run == 1; committee leader = chair (comc) or ranking member (comr); occupation dummies occ1-occ5 (unknown and miscellaneous form the base); total bills sponsored = count of bills per sponsor-Congress in the analysis file.
- (reproduction.json) Percent of cosponsors from the opposite party = 100 * pct_cosponsors_opposite, set to 0 for bills with no cosponsors.
- (reproduction.json) Propensity scores come from logits estimated at the bill level within each party subsample. The full-sample IPW columns use district characteristics + \|MV1_democrat\| (+ sponsor characteristics in column 5). The RD+IPW score uses district characteristics only, within the bandwidth. Weights are 1/p for female sponsors and 1/(1-p) for male sponsors.
- (reproduction.json) fixest drops one fixed-effect singleton (minor topic), so N is 1 lower than the paper's for some cells (60669 vs 60670).

Agent notes: Data: AnalysisData/bills_analysis_101-111_replication.dta only. Column 1 is OLS (feols) of the outcome on the female-sponsor dummy, sponsor characteristics, district characteristics, 33 committee-of-referral dummies, and Congress and minor-topic fixed effects, with SEs clustered by sponsor-Congress. Column 2 is a local-linear RD on MV1_female with separate slopes on each side and Congress FE, in mixed-gender races within the bandwidth. Column 3 adds bill characteristics and IPW weights to the column 2 regression. Columns 4-5 are weighted regressions on the full sample with Congress FE and bill characteristics. One exploratory run (attempt-1) inspected the variables. The first estimation run is the final one: check_attempt reported all claims within tolerance, and the script was not changed afterwards.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 30,233 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261022T032229Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 973 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261022T032229Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 290 bytes, from `benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/independent/2026-10-22-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 883 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261022T032229Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261022T032229Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 11,255 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261022T032229Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,720 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261022T032229Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,799 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261022T032229Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 2,716 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261022T032229Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,408 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261022T032229Z/stdout.txt`
