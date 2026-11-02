# gagliarducci-2022-gender-cooperation-congress · independent · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:05:00Z |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T202751Z` |
| Run directory | `benchmark/reproductions/gagliarducci-2022-gender-cooperation-congress/independent/2026-11-02-c` |
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
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.40253 | 0.54% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 2.39523 | 23.94% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 6.36493 | 5.48% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 2.46747 | 21.02% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -1.72048 | 14.32% | ±0.419 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -3.02136 | 9.84% | ±1.91 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -1.49986 | 24.16% | ±0.525 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 3.11552 | 15.02% | ±0.916 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 2.88964 | 0.53% | ±0.82 (se_band) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60669 | 0.00% | ±606.7 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4746 | 0.00% | ±47.46 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 32846 | 0.00% | ±328.46 (relative) | PASS | PASS |
| `n_bills_pct_opposite_rep_ols` | 27669 | 27670 | 0.00% | ±276.69 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Percent of opposite-party cosponsors constructed as 100*numb_cosponsors_opposite/(numb_cosponsors+1) per the paper's footnote 11, not the dataset's pct_cosponsors_opposite (which divides by numb_cosponsors).
- (reproduction.json) RD bandwidths fixed at the values reported in the paper (13 for Republican cosponsors, 24 for Democratic percent opposite) rather than recomputed; current rdrobust MSE bandwidths (19.7 and 9.5) are printed for reference. Uniform kernel, linear in the margin with slopes differing by side.
- (reproduction.json) Propensity scores: bill-level logit of the female dummy (no Congress FE), ATE inverse-probability weights 1/p and 1/(1-p); observations perfectly predicted by a binary covariate dropped as Stata's logit would. Column 3 PS on district characteristics within the bandwidth; columns 4/5 on district characteristics + \|MV1_democrat\| (+ sponsor characteristics in column 5).
- (reproduction.json) Macro areas = Census regions (Northeast, Midwest, South; West omitted); log population density = lnpop - lnarea; rookie = tenure_run==1; committee leader = chair or ranking member; occupational dummies occ1-occ5; total bills sponsored counted per sponsor-Congress in the data.
- (reproduction.json) fixest dropped one singleton fixed-effect observation, so the all-sponsor OLS uses 60,669 bills (paper 60,670; the complete-case sample is exactly 60,670 bills, 4,746 sponsor-terms).

Agent notes: Two exploratory runs (variable inspection, sample counts; no RESULT lines) then one estimating run, which is final. After it ran I compared its RESULT lines to the claims with check_attempt ('All claims within tolerance') and did not change the script, so no claim attempt is recorded. Data: Data/AnalysisData/bills_analysis_101-111_replication.dta. OLS: Congress and minor-topic FE, 33 committee dummies, sponsor and district characteristics, SE clustered by sponsor-Congress. The unweighted Republican RD for cosponsors (Table 5 Panel A col 2, not a listed claim) reproduces the paper exactly (6.101, 1,227 bills, 100 sponsors), which supports the RD sample construction. Party-specific OLS estimates are further from the paper than the pooled one (e.g. Republican cosponsors 2.40 vs 3.149), and PS-weighted samples are somewhat smaller than the paper's.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 30,710 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T202751Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 973 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T202751Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 290 bytes, from `benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/independent/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 761 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T202751Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T202751Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 11,794 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T202751Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,088 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T202751Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T202751Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,342 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T202751Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,781 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T202751Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,068 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T202751Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 863 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T202751Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,972 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/claude-code/20261102T202751Z/stdout.txt`
