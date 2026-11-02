# forsythe-2022-young-workers-recessions · independent · claude-code · 2026-11-02-a

| | |
|---|---|
| Paper | `forsythe-2022-young-workers-recessions` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-a |
| Date | 2026-11-02T06:12:30Z |
| Results file | `benchmark/results/claude-code-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T062001Z` |
| Run directory | `benchmark/reproductions/forsythe-2022-young-workers-recessions/independent/2026-11-02-a` |
| Executions | 4 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 4) |
| Final | **12/13** |
| Package files withheld | 7 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `young_x_unemp_rate_no_controls` | -0.335 (0.0203) | -0.344686 | 2.89% | ±0.0203 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_no_controls` | -0.0367 (0.0131) | -0.0429339 | 16.99% | ±0.0131 (se_band) | PASS | PASS |
| `young_x_unemp_rate_preferred` | -0.253 (0.0185) | -0.253563 | 0.22% | ±0.0185 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_preferred` | 0.0496 (0.0142) | 0.051861 | 4.56% | ±0.0142 (se_band) | PASS | PASS |
| `aggregate_unemp_rate_no_controls` | -0.119 (0.015) | -0.120697 | 1.43% | ±0.015 (se_band) | PASS | PASS |
| `aggregate_unemp_rate_month_year_fe` | -0.0326 (0.0132) | -0.0248603 | 23.74% | ±0.0132 (se_band) | PASS | PASS |
| `young_x_unemp_rate_employed` | -0.168 (0.0156) | -0.174291 | 3.74% | ±0.0156 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_employed` | 0.0179 (0.0101) | 0.0228465 | 27.63% | ±0.0101 (se_band) | PASS | PASS |
| `young_x_unemp_rate_unemployed` | -1.928 (0.167) | -1.98041 | 2.72% | ±0.167 (se_band) | PASS | PASS |
| `young_x_unemp_rate_nilf` | -0.49 (0.0332) | -0.584687 | 19.32% | ±0.0332 (se_band) | FAIL | FAIL |
| `wage_young_x_unemp_rate_all_hires` | -0.0262 (0.0036) | -0.0251223 | 4.11% | ±0.0036 (se_band) | PASS | PASS |
| `wage_experienced_x_unemp_rate_all_hires` | -0.0116 (0.00348) | -0.0103106 | 11.12% | ±0.00348 (se_band) | PASS | PASS |
| `n_obs_full_sample` | 1.69485e+07 | 1.69644e+07 | 0.09% | ±169485 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Hiring LPMs (Table 1 A/B cols 1 and 4, Table 2 cols 1-4) estimated by WLS on weighted cell means over state x month x demographic cell x PE<=10 x prior labour-force status; all regressors are constant within cells, so point estimates equal person-level WLS; state-clustered SEs not computed/reported.
- (reproduction.json) State (v2gestfips) is missing in the provided data for mid-2014 through 2016 (2.15M person-months); these cannot be matched to the state unemployment rate and are dropped. Sample also restricted to ages 16-80 (age top-coding above 80 varies over time) with non-missing Hispanic origin; resulting N = 16,964,441.
- (reproduction.json) Years of schooling for potential experience imputed from CPS PEEDUCA categories: <1st=0, 1-4=2.5, 5-6=5.5, 7-8=7.5, 9th=9, 10th=10, 11th=11, 12th no diploma=12, HS=12, some college=13, associate=14, BA=16, MA/professional/PhD=18.
- (reproduction.json) The 2 GB yh_data.csv was read with data.table::fread restricted to the 19 needed columns (select=), not loaded in full, because of the sandbox's 4 GB memory cap and 300 s time limit.
- (reproduction.json) Wage regression uses the average of the two months' CPS final weights (earnings weights not in the data); industry/occupation crosswalked to 2002 census codes by code vintage (industry 1990 codes to 2002, 2002 codes 2003-08, 2007 codes 2009-13, 2012 codes 2014+; occupation 1990 codes to 2002, 2002 codes 2003-10, 2010 codes 2011+).
- (DEVIATION: line) hiring LPMs estimated by WLS on weighted cell means (state x month x demographic x PE-group x prior-status); point estimates identical to person-level WLS, clustered SEs not reported
- (DEVIATION: line) v2gestfips (state) is missing in the data from mid-2014 onward; those person-months cannot be matched to a state unemployment rate and are dropped; sample further restricted to ages 16-80 with non-missing Hispanic origin
- (DEVIATION: line) years of schooling imputed from CPS education categories (assumed mapping; master's/professional/PhD = 18 years)

Agent notes: Data are pre-matched consecutive-month pairs (unprefixed = t-1, v2 = t). Hired (x100) = employed in t (PEMLR 1-2) and either non-employed in t-1, or employed in t-1 with PUIODP1 = 2 (no longer with last month's employer); new jobs with class of worker self-employed (PEIO1COW 6,7) are not hires. Young = potential experience (age - schooling - 6) <= 10. Demographic FE = sex x white x Hispanic x 7 education levels. Unemployment rate merged by state and month t. Weights = average of PWSSWGT in t-1 and t. Wage sample: new hires with positive, non-allocated (PRWERNAL = 0) weekly earnings deflated to 1994 by the provided CPI, with state, demographic, month-year, occupation and industry FE (N = 118,285). Exploratory attempts: attempt-1 timed the full fread (209 s) and tabulated variables; attempt-2 tested chunked readBin streaming, which was slower and timed out (killed); attempt-3 gathered sample-restriction diagnostics and ran out of memory at the end of its diagnostics. None printed RESULT lines. No claim-comparison attempts were made.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,491 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T062001Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 965 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T062001Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 276 bytes, from `benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/independent/2026-11-02-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,492 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T062001Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T062001Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 4,832 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T062001Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 4,350 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T062001Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T062001Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 225 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T062001Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 4,290 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T062001Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T062001Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 3,777 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T062001Z/attempt-3/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 3,054 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T062001Z/reproduction.json`
- [`output/script.R`](output/script.R) — 7,418 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T062001Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 217 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T062001Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,201 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T062001Z/stdout.txt`
