# forsythe-2022-young-workers-recessions · blind · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `forsythe-2022-young-workers-recessions` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-08T21:33:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z` |
| Run directory | `benchmark/reproductions/forsythe-2022-young-workers-recessions/blind/2026-11-07-a` |
| Executions | 8 |
| Refinements | 3 (3 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 8) |
| Final | **12/13** |
| Package files withheld | 7 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `young_x_unemp_rate_no_controls` | -0.335 (0.0203) | -0.343066 | 2.41% | ±0.0203 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_no_controls` | -0.0367 (0.0131) | -0.039095 | 6.53% | ±0.0131 (se_band) | PASS | PASS |
| `young_x_unemp_rate_preferred` | -0.253 (0.0185) | -0.256665 | 1.45% | ±0.0185 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_preferred` | 0.0496 (0.0142) | 0.051657 | 4.15% | ±0.0142 (se_band) | PASS | PASS |
| `aggregate_unemp_rate_no_controls` | -0.119 (0.015) | -0.115205 | 3.19% | ±0.015 (se_band) | PASS | PASS |
| `aggregate_unemp_rate_month_year_fe` | -0.0326 (0.0132) | -0.024615 | 24.49% | ±0.0132 (se_band) | PASS | PASS |
| `young_x_unemp_rate_employed` | -0.168 (0.0156) | -0.172814 | 2.87% | ±0.0156 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_employed` | 0.0179 (0.0101) | 0.022795 | 27.35% | ±0.0101 (se_band) | PASS | PASS |
| `young_x_unemp_rate_unemployed` | -1.928 (0.167) | -1.9813 | 2.76% | ±0.167 (se_band) | PASS | PASS |
| `young_x_unemp_rate_nilf` | -0.49 (0.0332) | -0.593998 | 21.22% | ±0.0332 (se_band) | FAIL | FAIL |
| `wage_young_x_unemp_rate_all_hires` | -0.0262 (0.0036) | -0.025135 | 4.06% | ±0.0036 (se_band) | PASS | PASS |
| `wage_experienced_x_unemp_rate_all_hires` | -0.0116 (0.00348) | -0.010249 | 11.65% | ±0.00348 (se_band) | PASS | PASS |
| `n_obs_full_sample` | 1.69485e+07 | 1.73573e+07 | 2.41% | ±847426 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Hiring regressions (Tables 1 and 2) are estimated on cells (state x month-year x demographic cell x PE<=10 x labour-force status in t-1): the outcome is the CPS-weighted mean of the hired indicator (x100) and the regression weight is the cell's summed weight. All regressors and fixed effects are constant within a cell, so the point estimates equal the person-level weighted regression, and the state-clustered score sums are the same too (only the CR1 small-sample factor uses the cell count). This was needed because reading the 2 GB CSV through the sandbox's file sharing (~8 MB/s) takes ~200 s of the 300 s limit. N is reported as the number of person-level observations.
- (reproduction.json) Years of schooling from PEEDUCA (used for potential experience = age - schooling - 6): <1st grade 0, 1st-4th 2.5, 5th-6th 5.5, 7th-8th 7.5, 9th 9, 10th 10, 11th 11, 12th no diploma 12, HS 12, some college 13, associate degrees 14, BA 16, MA 18, professional 20, PhD 20. The paper does not give its mapping.
- (reproduction.json) Industry/occupation crosswalk vintage assigned by survey date (industry: 1990 codes through 2002, 2002 codes 2003-2008, 2007 codes 2009-2013, 2012 codes 2014+; occupation: 1990 through 2002, 2002 codes 2003-2010, 2010 codes 2011+).

Agent notes: Independent blind reproduction from the redacted paper text and data column names only. Sample: matched consecutive-month CPS pairs in yh_data.csv with month t from Feb 1994 to Sep 2016 (t-1 May-Aug 1995 absent), civilians age 16+ with valid education, employment status in both months and a state code: 17,357,345 person-month observations. Hired (x100) = employed at t, not self-employed (PEIO1COW 6/7) at t, and either not employed at t-1 or employed at t-1 and answering that they no longer work for last month's employer (PUIODP1 = 2). The state unemployment rate is for month t. Weights are the average of the two months' final weights. Demographic FE = sex x white x Hispanic (PEHSPNON, PRHSPNON before 2003) x seven education levels; month-year FE are for month t; SEs are clustered by state. Wage regression: new hires with non-allocated (PRWERNAL = 0), positive weekly earnings at t, deflated with the provided CPI series to 1994 dollars, logged, with state, demographic, month-year, 2002-consistent occupation and industry FE (n = 118,376). Run history: attempt-1 explored the data (no estimates). attempts 2 and 3 crashed in a memory-saving column-subset loop (data.table names shared by reference). attempt-4 hit the 300 s limit during the data read. attempt-5 (chunked-read test) also timed out. attempt-6 measured raw read throughput (~8 MB/s). attempt-7 code-tested the cell-collapsed pipeline on the first 3M rows without printing estimates. The final run took 216 s. Another, unrelated sandbox container was running alongside most of these runs. The ReadMe.pdf in the data directory was not opened, and no author scripts or output files were opened. No hung docker run.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 19,793 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 934 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 289 bytes, from `benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/blind/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,583 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 6,528 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 260 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-1/timing.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 706 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 7,225 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 90 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 82 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 260 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-2/timing.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 518 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 7,069 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 95 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 54 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 259 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-3/timing.json`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 1,049 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 7,082 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 184 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 54 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 283 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-4/timing.json`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 1,806 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 183 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-5/stdout.txt`
- [`output/attempt-5/timing.json`](output/attempt-5/timing.json) — 282 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-5/timing.json`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 631 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 1,014 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-6/stdout.txt`
- [`output/attempt-6/timing.json`](output/attempt-6/timing.json) — 259 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-6/timing.json`
- [`output/attempt-7/script.R`](output/attempt-7/script.R) — 7,966 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-7/script.R`
- [`output/attempt-7/stderr.txt`](output/attempt-7/stderr.txt) — 145 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-7/stderr.txt`
- [`output/attempt-7/stdout.txt`](output/attempt-7/stdout.txt) — 592 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-7/stdout.txt`
- [`output/attempt-7/timing.json`](output/attempt-7/timing.json) — 258 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/attempt-7/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 3,763 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/reproduction.json`
- [`output/script.R`](output/script.R) — 8,068 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 147 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,423 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 260 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261108T215404Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
