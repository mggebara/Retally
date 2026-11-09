# gagliarducci-2022-gender-cooperation-congress · independent · claude-code · 2026-11-01-a

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-01-a |
| Date | 2026-11-02T04:30:29Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-13papers-indep-blind-2026-11-01.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T043820Z` |
| Run directory | `benchmark/reproductions/gagliarducci-2022-gender-cooperation-congress/independent/2026-11-01-a` |
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
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.384 | 0.79% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 2.3978 | 23.86% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 5.8671 | 12.87% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 2.2269 | 28.72% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -1.7838 | 18.52% | ±0.419 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -2.41 | 28.08% | ±1.91 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -1.3425 | 11.13% | ±0.525 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 4.1782 | 13.97% | ±0.916 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 2.7814 | 4.25% | ±0.82 (se_band) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60669 | 0.00% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4741 | 0.11% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 32846 | 0.00% | ±1642.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_rep_ols` | 27669 | 27669 | 0.00% | ±1383.45 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) RD bandwidths fixed at the paper-reported CCT optimal bandwidths (13 for Republican cosponsors, 24 for Democratic percent-opposite); rdbwselect (mserd, triangular, p=1, bill level) recomputed 17.8 and 25.0 and is printed for reference.
- (reproduction.json) Percent of opposite-party cosponsors set to 0 for bills with zero cosponsors (the CSV has it missing there; Table 5 Panel B Ns imply it was 0) and scaled to percentage points; one bill with a fraction above 1 set to missing.
- (reproduction.json) Constructed controls not in the CSV: rookie = tenure 1; committee leader = chair or ranking member (comc\|comr); total bills sponsored = count of bills per sponsor-Congress in the file; 4 macro regions (Northeast, Midwest, South, West) from ICPSR state codes; log population density = lnpop - lnarea; occupational dummies occ1-occ5 (occ0 and occ6 omitted); independent-party dummy alongside the Republican dummy.
- (reproduction.json) Propensity scores: logit with Congress fixed effects estimated at bill level; ATE inverse-probability weights 1/p for women and 1/(1-p) for men. The margin of victory of the elected candidate = 100*\|MV1_democrat\|. For RD+IPW the score uses district characteristics within the bandwidth.
- (reproduction.json) Sponsor-Congress clusters = Congress x sponsor name x state x district (4741 in the all-sponsor OLS against 4746 in the paper).
- (DEVIATION: line) RD bandwidths fixed at the paper-reported CCT optimal bandwidths (CCT bandwidths recomputed and printed for reference)

Agent notes: Independent reproduction of Table 5 from the paper text and bills_analysis_101-111_replication.csv only (no author code opened). Column 1: OLS of the outcome on the female dummy with Congress and minor-topic fixed effects, 33 committee-of-referral dummies, sponsor characteristics and district characteristics, SEs clustered by sponsor-Congress (fixest). RD: mixed-gender races, \|MV1_female\| <= bandwidth, female dummy + MV1_female + female x MV1_female + Congress FE. PS columns: full sample, weighted least squares of the outcome on the female dummy + Congress FE + bill characteristics. One exploratory run (attempt-1, no RESULT lines); the first estimating run was compared with the claims via check_attempt, which reported all claims within tolerance, so the script was not changed and that run is final. Point estimates differ from the paper for some cells (e.g. Republican OLS cosponsors 2.40 against 3.149; Republican RD-IPW 5.87 against 6.734).

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 30,233 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T043820Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 973 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T043820Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 290 bytes, from `benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/independent/2026-11-01-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,838 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T043820Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T043820Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 11,006 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T043820Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,785 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T043820Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,400 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T043820Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,800 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T043820Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,930 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T043820Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
