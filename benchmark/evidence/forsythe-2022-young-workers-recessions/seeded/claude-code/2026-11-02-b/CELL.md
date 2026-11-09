# forsythe-2022-young-workers-recessions · seeded · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `forsythe-2022-young-workers-recessions` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T19:42:40Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-23papers-seeded-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T194315Z` |
| Run directory | `benchmark/reproductions/forsythe-2022-young-workers-recessions/seeded/2026-11-02-b` |
| Executions | 3 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 2) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `young_x_unemp_rate_no_controls` | -0.335 (0.0203) | -0.335031 | 0.01% | ±0.0067 (relative) | PASS | PASS |
| `experienced_x_unemp_rate_no_controls` | -0.0367 (0.0131) | -0.036675 | 0.07% | ±0.000734 (relative) | PASS | PASS |
| `young_x_unemp_rate_preferred` | -0.253 (0.0185) | -0.253253 | 0.10% | ±0.00506 (relative) | PASS | PASS |
| `experienced_x_unemp_rate_preferred` | 0.0496 (0.0142) | 0.0495623 | 0.08% | ±0.000992 (relative) | PASS | PASS |
| `aggregate_unemp_rate_no_controls` | -0.119 (0.015) | -0.119074 | 0.06% | ±0.00238 (relative) | PASS | PASS |
| `aggregate_unemp_rate_month_year_fe` | -0.0326 (0.0132) | -0.0326229 | 0.07% | ±0.000652 (relative) | PASS | PASS |
| `young_x_unemp_rate_employed` | -0.168 (0.0156) | -0.167865 | 0.08% | ±0.00336 (relative) | PASS | PASS |
| `experienced_x_unemp_rate_employed` | 0.0179 (0.0101) | 0.0178548 | 0.25% | ±0.000358 (relative) | PASS | PASS |
| `young_x_unemp_rate_unemployed` | -1.928 (0.167) | -1.92784 | 0.01% | ±0.03856 (relative) | PASS | PASS |
| `young_x_unemp_rate_nilf` | -0.49 (0.0332) | -0.489847 | 0.03% | ±0.0098 (relative) | PASS | PASS |
| `wage_young_x_unemp_rate_all_hires` | -0.0262 (0.0036) | -0.0261736 | 0.10% | ±0.000524 (relative) | PASS | PASS |
| `wage_experienced_x_unemp_rate_all_hires` | -0.0116 (0.00348) | -0.0115976 | 0.02% | ±0.000232 (relative) | PASS | PASS |
| `n_obs_full_sample` | 1.69485e+07 | 1.69485e+07 | 0.00% | ±847426 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) yh_data.csv (about 2 GB) read with data.table::fread(select=) of only the 19 columns the claimed specifications use, to fit the sandbox's 300 s / 4 GB limits.
- (reproduction.json) Hiring regressions (Table 1 Panels A/B, Table 2) estimated by weighted least squares on cells of state x month x demo2 x young x prior labour-force status, with the cell weight being the sum of the CPS weights and the outcome being the weighted mean of hired100. Every regressor and fixed effect is constant within a cell, so the point estimates equal those of the person-level aweighted regression; the clustered-SE small-sample factor uses the number of cells instead of persons. The wage regression (Table 10) is run at person level.
- (reproduction.json) Stata's m:1 crosswalk merges are done as lookups on keys deduplicated by (code, code-year).
- (DEVIATION: line) yh_data.csv read with data.table::fread(select=) of only the 19 columns used (memory/time limits of the sandbox)
- (DEVIATION: line) hiring regressions (Tables 1-2) estimated by WLS on state x month x demo2 x young x prior-status cells with summed CPS weights; identical point estimates to the person-level aweighted regression, clustered SE small-sample factor uses cell count

Agent notes: Followed YH_data_init.do and YH_regs.do: hired2 x 100 outcome, young = potential experience <= 10, youngurate/oldurate interactions, demo2 = group(minority, female, hisp, educ), state + month-year + demo2 fixed effects, CPS weight (v2pwsswgt+pwsswgt)/2, state-clustered SEs, fixef.rm='none'. Sample: exp and state unemployment rate non-missing (N = 16,948,516, matching the paper). Table 10 Panel B col 1: log real weekly wage of new hires with v2prwernal==0, with occupation (2002 recode) and industry (2002 recode) fixed effects (N = 112,858). attempt-1 was an exploratory read/timing run with no RESULT lines. attempt-2 was the first scored run; check_attempt reported every claim within tolerance. The only change after it was printing n_obs_full_sample as an exact integer (%.6g had rounded it to 1.69485e+07). The final run reproduces all 13 claims.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 63,630 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T194315Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 829 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T194315Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 271 bytes, from `benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/seeded/2026-11-02-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,187 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T194315Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T194315Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,769 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T194315Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 207 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T194315Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 6,864 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T194315Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 64 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T194315Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,245 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T194315Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,220 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T194315Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,899 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T194315Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 64 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T194315Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,243 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T194315Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
