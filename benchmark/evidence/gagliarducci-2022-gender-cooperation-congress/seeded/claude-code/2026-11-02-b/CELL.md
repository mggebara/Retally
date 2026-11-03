# gagliarducci-2022-gender-cooperation-congress · seeded · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T19:41:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-23papers-seeded-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z` |
| Run directory | `benchmark/reproductions/gagliarducci-2022-gender-cooperation-congress/seeded/2026-11-02-b` |
| Executions | 5 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 2) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.39531 | 0.02% | ±0.0279 (relative) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 3.14933 | 0.01% | ±0.06298 (relative) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 6.73423 | 0.00% | ±0.13468 (relative) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 3.1239 | 0.00% | ±0.06248 (relative) | PASS | FAIL |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -1.50465 | 0.02% | ±0.0301 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -3.35058 | 0.01% | ±0.06702 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -1.20782 | 0.01% | ±0.02416 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 3.66566 | 0.01% | ±0.07332 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 2.90498 | 0.00% | ±0.0581 (relative) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60670 | 0.00% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4746 | 0.00% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 32846 | 0.00% | ±1642.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_rep_ols` | 27669 | 27669 | 0.00% | ±1383.45 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) rdbwselect_2014 (CCT 2014 bandwidth, uniform kernel, p=1, q=2, nn variance with 3 matches) is not in the installed R rdrobust (4.1.1), so it was re-implemented in R from the shipped rdbwselect_2014.ado and kconst.ado; the compiled rdvce .mo could not be read, so the nearest-neighbour variance follows the documented CCT rule (all observations within the 4th-smallest distance including self, Stata minindex tie handling). Bandwidths came out 13.06 (Rep, cosponsors) and 24.74 (Dem, pct opposite), matching the paper's 13 and 24.
- (reproduction.json) Stata probit perfect-prediction behaviour emulated by hand: a regressor whose nonzero values predict the outcome perfectly is dropped together with those observations, and (as Stata's predict without 'rules') those observations get a missing propensity score and so drop out of the weighted regression.

Agent notes: Translated Table5.do into R (haven + fixest). Columns: (1) OLS with i.v2, i.minor, house_* committee dummies, sponsor and district characteristics, clustered by sponsor-Congress; (2) RD within the CCT bandwidth on the e(sample) of the mixed-gender full-control regression; (3) same plus inverse probit propensity weights from district chars within the bandwidth; (4)/(5) full-sample IPW with probit on district chars + \|MV\| (+ sponsor chars) at one row per sponsor-Congress. attempt-1 explored variables/package availability; attempt-2 matched all claims but rep_ipw_sponsor (3.354 vs 3.124) because the probit had quasi-separation (black, occ3 for Republicans); attempt-3 dropped perfect predictors but kept their predicted scores (3.713); attempt-4 explored the separation; the final run sets pscore to missing for rule-excluded observations as Stata does, which reproduces every claim (rep_rd_ipw also moved from 6.857 to 6.734 since v2==101 had no female Republicans within the bandwidth). All 13 claims reproduce to the reported precision.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 215,424 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 828 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 285 bytes, from `benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/seeded/2026-11-02-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 753 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 4,351 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 96 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 11,592 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 634 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,552 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 96 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 11,915 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 558 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 1,559 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/attempt-3/stdout.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 10,213 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 152 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 1,345 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/attempt-4/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,567 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/reproduction.json`
- [`output/script.R`](output/script.R) — 12,353 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 558 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,584 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/claude-code/20261102T194315Z/stdout.txt`
