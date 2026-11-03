# gagliarducci-2022-gender-cooperation-congress · blind · claude-code · 2026-11-01-a

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-01-a |
| Date | 2026-11-02T04:24:44Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-13papers-indep-blind-2026-11-01.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T043821Z` |
| Run directory | `benchmark/reproductions/gagliarducci-2022-gender-cooperation-congress/blind/2026-11-01-a` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 9/13 (execution 2) |
| Final | **9/13** |
| Package files withheld | 152 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.33104 | 4.58% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 2.39634 | 23.90% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 8.28988 | 23.10% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 3.14288 | 0.60% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -2.43795 | 61.99% | ±0.419 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -5.13248 | 53.16% | ±1.91 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -2.52395 | 108.94% | ±0.525 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 4.31565 | 17.72% | ±0.916 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 2.91092 | 0.20% | ±0.82 (se_band) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60669 | 0.00% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4746 | 0.00% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 22712 | 30.85% | ±1642.3 (relative) | FAIL | FAIL |
| `n_bills_pct_opposite_rep_ols` | 27669 | 18691 | 32.45% | ±1383.45 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/13 pass, which agrees with the row's 9/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) RD bandwidths: used the bandwidths stated in the task context for these rows (13 pp for Republican number of cosponsors, 24 pp for Democratic percent opposite-party) rather than my own rdbwselect (mserd, nn vce) output, which gave 17.8 and 16.5; uniform kernel (linear regression within the bandwidth, separate slopes each side).
- (reproduction.json) Propensity scores estimated by logit at the race (sponsor-Congress) level, ATE inverse-probability weights (1/p treated, 1/(1-p) controls), no trimming. Full-sample PS logits include Congress dummies; the within-bandwidth RD PS logit (district characteristics only) does not, because the sample is small (107 races).
- (reproduction.json) Margin of victory of the elected candidate = \|MV1_democrat\|. Log population density = lnpop - lnarea. Macro areas = 4 regions from ICPSR state codes (3 dummies). Occupation dummies occ1-occ5 (occ0 unknown and occ6 misc as base). Committee leader = chair or ranking member (comc\|comr). Rookie = tenure 1. Total bills sponsored counted per sponsor-Congress in the bill file. Party dummy (Democrat) only in pooled regressions.
- (reproduction.json) Percent opposite-party cosponsors: the dataset's pct_cosponsors_opposite x 100 (missing for bills with zero cosponsors, which therefore drop). Minor topic and Congress absorbed as fixed effects with singleton removal (mimicking reghdfe); 33 committee-of-referral dummies as regressors; listwise deletion on covariates. SEs clustered by sponsor-Congress.

Agent notes: Data: AnalysisData/bills_analysis_101-111_replication.dta only. Attempt-1 was an exploratory variable inventory (no RESULT lines). The final run is the first and only scored run; no repairs, no tuning. Outcome-regression controls for PS/RD-IPW columns: Congress FE + committee dummies + minor-topic FE; RD column 2 has Congress FE only. Sample: public bills of sponsors with nonmissing gender; party subsamples by sponsor_party 100/200 (independents only in pooled sample).

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 30,793 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T043821Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 941 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T043821Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 290 bytes, from `benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/blind/2026-11-01-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 886 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T043821Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T043821Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 11,304 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T043821Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,429 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T043821Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,943 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T043821Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,086 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T043821Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,517 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T043821Z/stdout.txt`
