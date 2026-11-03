# forsythe-2022-young-workers-recessions · seeded · claude-code · 2026-11-02-a

| | |
|---|---|
| Paper | `forsythe-2022-young-workers-recessions` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-a |
| Date | 2026-11-02T06:08:46Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z` |
| Run directory | `benchmark/reproductions/forsythe-2022-young-workers-recessions/seeded/2026-11-02-a` |
| Executions | 6 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 6) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `young_x_unemp_rate_no_controls` | -0.335 (0.0203) | -0.335031 | 0.01% | ±0.0067 (relative) | PASS | PASS |
| `experienced_x_unemp_rate_no_controls` | -0.0367 (0.0131) | -0.036675 | 0.07% | ±0.000734 (relative) | PASS | PASS |
| `young_x_unemp_rate_preferred` | -0.253 (0.0185) | -0.253253 | 0.10% | ±0.00506 (relative) | PASS | PASS |
| `experienced_x_unemp_rate_preferred` | 0.0496 (0.0142) | 0.049562 | 0.08% | ±0.000992 (relative) | PASS | PASS |
| `aggregate_unemp_rate_no_controls` | -0.119 (0.015) | -0.119074 | 0.06% | ±0.00238 (relative) | PASS | PASS |
| `aggregate_unemp_rate_month_year_fe` | -0.0326 (0.0132) | -0.032623 | 0.07% | ±0.000652 (relative) | PASS | PASS |
| `young_x_unemp_rate_employed` | -0.168 (0.0156) | -0.167865 | 0.08% | ±0.00336 (relative) | PASS | PASS |
| `experienced_x_unemp_rate_employed` | 0.0179 (0.0101) | 0.017855 | 0.25% | ±0.000358 (relative) | PASS | PASS |
| `young_x_unemp_rate_unemployed` | -1.928 (0.167) | -1.92785 | 0.01% | ±0.03856 (relative) | PASS | PASS |
| `young_x_unemp_rate_nilf` | -0.49 (0.0332) | -0.489847 | 0.03% | ±0.0098 (relative) | PASS | PASS |
| `wage_young_x_unemp_rate_all_hires` | -0.0262 (0.0036) | -0.026174 | 0.10% | ±0.000524 (relative) | PASS | PASS |
| `wage_experienced_x_unemp_rate_all_hires` | -0.0116 (0.00348) | -0.011598 | 0.02% | ±0.000232 (relative) | PASS | PASS |
| `n_obs_full_sample` | 1.69485e+07 | 1.69485e+07 | 0.00% | ±847426 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Table 1 and Table 2 hiring regressions are estimated as weighted least squares on exact weighted cell means over (state, month, demo2, young, prior labour-force status group), with cell weights equal to summed CPS weights. All regressors and fixed effects are constant within these cells, so point estimates are algebraically identical to the person-level aweighted regressions in YH_regs.do. This keeps the run inside the 300 s / 4 GB sandbox. Clustered standard errors (state) use the same meat and bread, but the (N-1)/(N-K) small-sample factor is omitted; they are printed for information only.
- (reproduction.json) yh_data.csv was read in full (all 19,836,464 rows), but only the 19 columns the Table 1/2/10 specifications need (fread select=). The occupation/industry crosswalk merges are applied only to the new-hire wage sample.
- (DEVIATION: line) hiring regressions (Tables 1-2) estimated as WLS on exact weighted cell means over (state, month, demo2, young, prior labour-force status) to fit the 300 s / 4 GB sandbox; point estimates are algebraically identical, SEs use the same clustering but the small-sample N adjustment is omitted.

Agent notes: Seeded translation of YH_data_init.do and YH_regs.do: date harmonisation, state unemployment merge, potential experience from peeduca (the CSV column for Stata's peeduc), demo2 = minority x female x hispanic x 7 education levels, hired2 (excluding self-employment) x 100, young = PE<=10, and the young/old x U-rate interactions. Sample: exp and v2unemp non-missing, giving N = 16,948,516. Table 1 cols 1 and 4 (Panels A and B) and Table 2 cols 1-4 use fixest feols with state, demo2 and month FE, fixef.rm='none', and state clustering. Table 10 Panel B col 1 is run person-level on hires with v2prwernal==0: log real weekly wage on young, youngurate and oldurate, with state, date, demo2, 2002-recoded occupation and industry FE (crosswalks merged by code-year as in the do-file). Attempts 1-5 were exploratory and printed no RESULT lines. Attempt 1 timed a column-selected fread at 168 s. Attempt 2 timed raw I/O at 101 s, then crashed on a fread argument clash. Attempt 3 found 3-thread fread slower, at 205 s. Attempts 4-5 were smoke tests on the first 2M rows with RESULT renamed TEST. The final full run took 233 s, of which 221 s was reading the file. No comparison against claimed values was followed by a script change, so there are no claim attempts.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 63,630 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 829 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 271 bytes, from `benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/seeded/2026-11-02-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,091 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,041 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 941 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 260 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 268 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 835 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 3,843 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/attempt-3/stdout.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 8,939 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 1,690 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/attempt-4/stdout.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 9,195 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 1,690 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/attempt-5/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,802 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/reproduction.json`
- [`output/script.R`](output/script.R) — 9,204 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,729 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/claude-code/20261102T061959Z/stdout.txt`
