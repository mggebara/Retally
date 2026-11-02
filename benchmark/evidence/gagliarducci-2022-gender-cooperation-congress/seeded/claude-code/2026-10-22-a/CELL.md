# gagliarducci-2022-gender-cooperation-congress · seeded · claude-code · 2026-10-22-a

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-22-a |
| Date | 2026-10-22T03:08:00Z |
| Results file | `benchmark/results/claude-code-6papers-all-modes-2026-10-22.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z` |
| Run directory | `benchmark/reproductions/gagliarducci-2022-gender-cooperation-congress/seeded/2026-10-22-a` |
| Executions | 5 |
| Refinements | 2 (1 error + 1 claim) |
| First attempt | 0/13 |
| First scored | 11/13 (execution 4) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.39531 | 0.02% | ±0.0279 (relative) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 3.14933 | 0.01% | ±0.06298 (relative) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 6.85691 | 1.83% | ±0.13468 (relative) | PASS | FAIL |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 3.1239 | 0.00% | ±0.06248 (relative) | PASS | FAIL |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -1.50465 | 0.02% | ±0.0301 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -3.35058 | 0.01% | ±0.06702 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -1.20782 | 0.01% | ±0.02416 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 3.66566 | 0.01% | ±0.07332 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 2.90498 | 0.00% | ±0.0581 (relative) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60670 | 0.00% | ±606.7 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4746 | 0.00% | ±47.46 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 32846 | 0.00% | ±328.46 (relative) | PASS | PASS |
| `n_bills_pct_opposite_rep_ols` | 27669 | 27669 | 0.00% | ±276.69 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) rdbwselect_2014 (CCT 2014 bandwidth selector) is not available in the installed rdrobust 4.1.1; it was re-implemented in R from the shipped rdbwselect_2014.ado (p=1, q=2, uniform kernel, nearest-neighbour variance with 3 matches, regularisation on). Stata's compiled helper routines (.mo) could not be read, so the kernel weights and NN variance follow the CCT 2014 formulas, with ties in the matching handled as Stata's minindex() does (all observations at the 4 smallest distinct distances). The bandwidths obtained (e.g. 13.05 for Republicans/cosponsors, 24.53 for Democrats/percent opposite) agree with the paper's rounded values for most rows, and the RD samples match the paper's bill and sponsor counts (1,227/100 and 1,978/167).
- (reproduction.json) Stata probit perfect-prediction handling was mimicked: a regressor x for which 'x != 0' perfectly predicts the outcome is dropped along with those observations, and their propensity scores are set to missing (Stata predict default), so those observations drop out of the weighted regressions. The base level of i.v2 is never checked. For Republicans in column 5 this drops black and occ3, which reproduces the paper's 23,818 bills and 1,953 sponsors.
- (reproduction.json) Congress (v2) and minor-topic dummies are absorbed as fixed effects in fixest (fixef.rm='none'). The female-sponsor coefficient is identical to Stata reg with i.v2 i.minor; clustered SEs may differ slightly through small-sample corrections.

Agent notes: Translated Table5.do for both dependent variables, all 3 samples and all 5 columns, then printed the claimed cells. 12 of the 13 claims match. female_sponsor_ncosponsors_rep_rd_ipw reproduces as 6.857, which is exactly the value printed in the paper's own Table 5 (paper.txt), with the same N (1,227 bills, 100 sponsors); the claimed 6.734 could not be reached. Attempt-4 (the first scored run) predicted pscores for observations Stata excludes as perfect predictions; fixing this, after the check_attempt comparison, moved col 5 for Republicans to 3.124 (which matches) and RD-IPW to 6.857. Attempt-1 was an exploratory run that crashed on a package-listing call (recorded as kind error); attempts 2 and 3 were exploratory (data inspection, bandwidth check) and printed no RESULT lines.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 215,424 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 828 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 285 bytes, from `benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/seeded/2026-10-22-a/paper.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 149 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 986 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 123 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 25 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 992 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 4,094 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 6,106 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 712 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/attempt-3/stdout.txt`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 187 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 10,922 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 142 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 4,012 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/attempt-4/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,913 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/reproduction.json`
- [`output/script.R`](output/script.R) — 11,492 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,040 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261022T032229Z/stdout.txt`
