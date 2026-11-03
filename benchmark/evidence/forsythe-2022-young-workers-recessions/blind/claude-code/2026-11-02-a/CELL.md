# forsythe-2022-young-workers-recessions · blind · claude-code · 2026-11-02-a

| | |
|---|---|
| Paper | `forsythe-2022-young-workers-recessions` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-a |
| Date | 2026-11-02T06:09:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261102T062002Z` |
| Run directory | `benchmark/reproductions/forsythe-2022-young-workers-recessions/blind/2026-11-02-a` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 11/13 (execution 3) |
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
| `n_obs_full_sample` | 1.69485e+07 | 1.73573e+07 | 2.41% | ±847426 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Sample restriction follows the paper's explicit statement only: civilians aged 16+ (peage>=16) with valid education and labour-force status in both months, month t from Feb 1994 to Sep 2016; no upper age bound was imposed (the paper says 'working-age' but gives no cap). Matches were taken as supplied (the file has no second-month sex/race/age to re-confirm matches).
- (reproduction.json) Years of schooling mapped from peeduca: 31:0, 32:2.5, 33:5.5, 34:7.5, 35:9, 36:10, 37:11, 38:12, 39:12, 40:13, 41:14, 42:14, 43:16, 44:18, 45:20, 46:20; potential experience = age - years - 6, young = PE <= 10.
- (reproduction.json) Hire = employed in t (pemlr 1-2) and either non-employed in t-1 or v2puiodp1 == 2 (changed employer); new job class of worker 6/7 (self-employed) excluded. v2puiodp1 codes -1/-2/-3 treated as no employer change.
- (reproduction.json) Demographic FE = sex x white (race==1) x Hispanic (prhspnon, else pehspnon, == 1) x 7 education groups; demographics and t-1 status from the first month, state and unemployment rate from month t.
- (reproduction.json) Hiring LPMs were estimated on weighted cell means (state x month x demographic cell x young x t-1 status), with weight = sum of the average of the two months' CPS weights. Point estimates are identical to person-level WLS because every regressor is constant within a cell. N is the person-level count. Done because the 2 GB file takes about 214 s of the 300 s limit to read in the sandbox.
- (reproduction.json) Only the needed 19 of 35 columns of yh_data.csv were read (fread select=); the full file was not loaded.
- (reproduction.json) Wage regression: new hires with v2prernwa > 0 and v2prwernal == 0 (not allocated), deflated by the supplied CPI series at month t. Weights are the average CPS weight (no earnings weight is in the data). Occupation codes mapped to 2002 codes via crosswalk vintage 1990 (<=2002), 2002 (2003-2010), 2010 (2011+); industry via 1990 (<=2002), 2002 (2003-2008), 2007 (2009-2013), 2012 (2014+). 11 obs with an unmatched industry were dropped.

Agent notes: Independent blind reproduction in R (data.table + fixest). attempt-1: exploratory read and tabulation of coding (no RESULT lines). attempt-2: exploratory I/O timing probe that exceeded 300 s and was killed (treated as a timeout, exit 124; no RESULT lines). Final run: Table 1 Panel A cols 1 and 4, Panel B cols 1 and 4, Table 2 cols 2-4 (by t-1 status), and Table 10 Panel B col 1. All with CPS weights and state-clustered SEs. Ran in 243 s.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 19,041 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261102T062002Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 934 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261102T062002Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 276 bytes, from `benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/blind/2026-11-02-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,327 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261102T062002Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261102T062002Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 3,628 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261102T062002Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 758 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261102T062002Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261102T062002Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 41 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261102T062002Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,961 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261102T062002Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,608 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261102T062002Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261102T062002Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,467 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/claude-code/20261102T062002Z/stdout.txt`
