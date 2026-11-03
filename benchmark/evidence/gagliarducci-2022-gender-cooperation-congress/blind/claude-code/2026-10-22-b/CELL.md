# gagliarducci-2022-gender-cooperation-congress · blind · claude-code · 2026-10-22-b

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-22-b |
| Date | 2026-10-22T03:29:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-blind-rerun-2026-10-22-b.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T033040Z` |
| Run directory | `benchmark/reproductions/gagliarducci-2022-gender-cooperation-congress/blind/2026-10-22-b` |
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
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.41183 | 1.21% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 2.3773 | 24.51% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 6.98674 | 3.75% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 2.92055 | 6.51% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -2.27199 | 50.96% | ±0.419 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -5.13248 | 53.16% | ±1.91 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -1.75153 | 44.99% | ±0.525 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 4.47979 | 22.20% | ±0.916 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 2.3146 | 20.32% | ±0.82 (se_band) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60669 | 0.00% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4746 | 0.00% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 22712 | 30.85% | ±1642.3 (relative) | FAIL | FAIL |
| `n_bills_pct_opposite_rep_ols` | 27669 | 18691 | 32.45% | ±1383.45 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/13 pass, which agrees with the row's 9/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Percent of opposite-party cosponsors: used the dataset's pct_cosponsors_opposite, which equals opposite-party cosponsors / cosponsors (sponsor not in the denominator, missing for bills with zero cosponsors), multiplied by 100. The paper's text describes the denominator as cosponsors plus sponsor; the shipped variable was used as the authors' constructed outcome.
- (reproduction.json) Propensity scores estimated by probit at the bill level (the paper's text does not say probit vs logit); ATE inverse-probability weights (1/p for women, 1/(1-p) for men). PS estimated separately within each party sample.
- (reproduction.json) RD columns use the bandwidths stated in the task for these rows (13 for Republicans Panel A col 3; 24 for Democrats Panel B col 2), uniform kernel, linear in the margin with slope differing at the threshold. CCT mserd bandwidths recomputed on bills (17.79 and 16.45) are printed as diagnostics only.
- (reproduction.json) Column 3 PS: district characteristics only (3 region dummies, % black, % over 65, % foreign born, % urban, log median income, log population density), estimated within the bandwidth; outcome regression adds Congress FE and bill characteristics.
- (reproduction.json) Columns 4/5 PS: district characteristics + margin of victory of the elected candidate (\|MV1_democrat\|) (+ sponsor characteristics in col 5); bills with missing MV1_democrat dropped.
- (reproduction.json) Macro regions built from ICPSR state codes (Northeast <20, Midwest 20-39, South 40-59, West 60+). Log population density = lnpop - ln(area in sq. miles); lnarea is stored in square meters for Congresses 108-111 (and a few earlier districts) and was converted to square miles.
- (reproduction.json) Occupational dummies: occ1-occ5 (education, lawyer, professional, business, agriculture), with unknown and miscellaneous as base. Party dummy entered as factor of sponsor_party (Dem/Rep/independent) in the pooled sample. Total bills sponsored = count of bills per sponsor-Congress in the sample with a matched sponsor.
- (reproduction.json) Minor topic and Congress absorbed as fixed effects (fixest); fixest drops fixed-effect singletons (1 bill in the all-sponsor OLS), as reghdfe would. Clusters: sponsor-Congress (Congress x state x district x seat order).
- (DEVIATION: line) percent of opposite-party cosponsors uses the dataset's pct_cosponsors_opposite (opposite/cosponsors, sponsor not in denominator) x100; propensity scores are probit at bill level with ATE inverse-probability weights; RD bandwidths are the ones stated for these rows (13, 24) with a uniform kernel.

Agent notes: Data: AnalysisData/bills_analysis_101-111_replication.dta, restricted to bills with a matched sponsor (61,334). Two exploratory runs (variable listing; checks of the pct variable, region codes, lnarea units). One estimation run, which is final. Column 1 OLS: outcome on female dummy + Congress FE + 226 minor topic FE + 33 committee-of-referral dummies + sponsor characteristics (age, tenure, rookie, committee chair/ranking member, black, party, 5 occupation dummies, Ivy League, born in state, bills sponsored in Congress) + district characteristics; SE clustered by sponsor-Congress. While reading the paper's method sections I incidentally saw some Table 3 and Table 4 numbers in the garbled text (Table 3 columns 1-4, including n. bills 61,334 for those columns; Table 5's numbers were not viewed); no specification choice was tuned toward them. No author scripts or output files in the dataset were opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 30,793 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T033040Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 941 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T033040Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 290 bytes, from `benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/blind/2026-10-22-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 950 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T033040Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T033040Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 12,175 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T033040Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,017 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T033040Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T033040Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,653 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T033040Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 3,653 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T033040Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,449 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T033040Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,008 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T033040Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,149 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261022T033040Z/stdout.txt`
