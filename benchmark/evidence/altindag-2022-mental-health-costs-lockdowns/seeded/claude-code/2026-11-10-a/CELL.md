# altindag-2022-mental-health-costs-lockdowns · seeded · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `altindag-2022-mental-health-costs-lockdowns` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T11:34:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-altindag-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z` |
| Run directory | `benchmark/reproductions/altindag-2022-mental-health-costs-lockdowns/seeded/2026-11-10-a` |
| Executions | 5 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 0/10 |
| First scored | 7/10 (execution 2) |
| Final | **8/10** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `days_outside_last_week_table3_col3` | -1.09 (0.18) | -1.08986 | 0.01% | ±0.0218 (relative) | PASS | PASS |
| `under_curfew_table3_col3` | 0.708 (0.045) | 0.708352 | 0.05% | ±0.01416 (relative) | PASS | PASS |
| `never_goes_out_table3_col3` | 0.297 (0.036) | 0.297368 | 0.12% | ±0.00594 (relative) | PASS | PASS |
| `n_obs_days_outside_table3_col3` | 1214 | 1214 | 0.00% | ±60.7 (relative) | PASS | PASS |
| `n_obs_under_curfew_table3_col3` | 1222 | 1222 | 0.00% | ±61.1 (relative) | PASS | PASS |
| `mental_distress_index_table4_col3` | 0.205 (0.094) | 0.214441 | 4.61% | ±0.0041 (relative) | FAIL | FAIL |
| `somatic_symptoms_index_table4_col3` | 0.175 (0.085) | 0.17319 | 1.03% | ±0.0035 (relative) | PASS | FAIL |
| `nonsomatic_symptoms_index_table4_col3` | 0.158 (0.092) | 0.147491 | 6.65% | ±0.00316 (relative) | FAIL | FAIL |
| `sum_srq20_yes_answers_table4_col3` | 0.734 (0.44) | 0.73423 | 0.03% | ±0.01468 (relative) | PASS | PASS |
| `n_obs_mental_distress_index_table4_col3` | 1133 | 1133 | 0.00% | ±56.65 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/10 pass, which agrees with the row's 8/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) The Anderson (2008) indices come from the authors' _gweightave2.ado (egen weightave2, normby(controldummy)), which is not in the replication package. It was reconstructed: items z-scored with control-group (born after Dec 1955) mean/SD; weights = row sums of the inverse covariance matrix of the z-scores estimated on complete cases in the control group; weighted average; index re-standardised to control-group mean 0, SD 1. The control-group covariance was chosen after claim comparisons (attempt-2 used full-sample covariance; attempt-4 scored a raw-item-covariance version and printed alternative constructions as '#' diagnostic lines, among which the control-group-covariance version fit the claimed coefficients and SEs best).
- (reproduction.json) Stata's xi: dummy regression is translated to feols with the month_*/province_n_* dummies and factor() terms as regressors (collinear month_12 and province_n_66 dropped automatically), clustered by modate.

Agent notes: Followed '1 Tables.do' Table 3 and Table 4 column (3): reg y on before1955, di1, di1_i plus month_*, province_n_*, i.ethnicity, i.education, female, i.survey_taker_id for \|dif\|<=45 among non_response==0, SEs clustered by modate. Mobility outcomes, SRQ-20 sum and all three observation counts match the paper exactly. Index coefficients depend on the unshipped weightave2 ado; the final reconstruction gives 0.214/0.173/0.147 vs claimed 0.205/0.175/0.158 (SEs 0.097/0.085/0.093 vs 0.094/0.085/0.092). attempt-1 and attempt-3 were exploratory (variable inspection; SRQ item coding, weights and item-level RD coefficients; no index estimates, no RESULT lines). Scripts were run from a scratch directory and copied here. No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 201,911 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 804 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 281 bytes, from `benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/seeded/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,246 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 3,216 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 264 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-1/timing.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 266 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,716 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 1,241 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 763 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 264 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 2,009 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 3,063 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 263 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-3/timing.json`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 266 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 4,996 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 4,439 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 1,741 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 264 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/attempt-4/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,356 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,881 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 763 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 264 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113607Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
