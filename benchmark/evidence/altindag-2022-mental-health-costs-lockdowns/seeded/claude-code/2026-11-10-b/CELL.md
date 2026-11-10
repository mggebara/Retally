# altindag-2022-mental-health-costs-lockdowns · seeded · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `altindag-2022-mental-health-costs-lockdowns` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T11:33:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-altindag-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z` |
| Run directory | `benchmark/reproductions/altindag-2022-mental-health-costs-lockdowns/seeded/2026-11-10-b` |
| Executions | 4 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 0/10 |
| First scored | 7/10 (execution 2) |
| Final | **10/10** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `days_outside_last_week_table3_col3` | -1.09 (0.18) | -1.08986 | 0.01% | ±0.0218 (relative) | PASS | PASS |
| `under_curfew_table3_col3` | 0.708 (0.045) | 0.708352 | 0.05% | ±0.01416 (relative) | PASS | PASS |
| `never_goes_out_table3_col3` | 0.297 (0.036) | 0.297368 | 0.12% | ±0.00594 (relative) | PASS | PASS |
| `n_obs_days_outside_table3_col3` | 1214 | 1214 | 0.00% | ±60.7 (relative) | PASS | PASS |
| `n_obs_under_curfew_table3_col3` | 1222 | 1222 | 0.00% | ±61.1 (relative) | PASS | PASS |
| `mental_distress_index_table4_col3` | 0.205 (0.094) | 0.207392 | 1.17% | ±0.0041 (relative) | PASS | FAIL |
| `somatic_symptoms_index_table4_col3` | 0.175 (0.085) | 0.175803 | 0.46% | ±0.0035 (relative) | PASS | FAIL |
| `nonsomatic_symptoms_index_table4_col3` | 0.158 (0.092) | 0.160233 | 1.41% | ±0.00316 (relative) | PASS | FAIL |
| `sum_srq20_yes_answers_table4_col3` | 0.734 (0.44) | 0.73423 | 0.03% | ±0.01468 (relative) | PASS | PASS |
| `n_obs_mental_distress_index_table4_col3` | 1133 | 1133 | 0.00% | ±56.65 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/10 pass, which agrees with the row's 10/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) The authors' _gweightave2.ado (Asher & Novosad) is not in the package, so the Anderson (2008) index was re-implemented in R: items z-scored with the control-group (before1955==0) mean and SD over the non-response==0 sample, combined with weights equal to the row sums of the inverse correlation matrix of the z-scores (complete cases), then rescaled to mean 0 / SD 1 in the control group, and set to missing if any item is missing. The weighting and rescaling were chosen by comparing variants against the claimed Table 4 values (attempt-3 diagnostics); the chosen variant also matches the paper's standard errors.

Agent notes: Followed '1 Tables.do': keep non_response==0; OLS of outcome on before1955, di1, di1_i (separate linear slopes on each side), month_1-12 and province_n_* dummies, female, and factor ethnicity, education, survey_taker_id; sample \|dif\|<=45; SEs clustered by modate (fixest::feols). attempt-1: exploratory variable inspection. attempt-2: first full run; Table 3 and SRQ-20 sum matched but the indices (inverse-covariance weights, no rescaling) were too small. attempt-3: same RESULTs plus non-scored diagnostics over index weighting variants; inverse-correlation weights + control-group rescaling matched all three indices (coefficients and t-stats). Final run: all 10 claims within rounding (index coefficients 0.207/0.176/0.160 vs 0.205/0.175/0.158; SEs 0.095/0.086/0.093 vs 0.094/0.085/0.092). No hangs.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 201,911 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 804 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 281 bytes, from `benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/seeded/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,008 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 6,938 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 264 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/attempt-1/timing.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 266 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 4,551 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 972 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 264 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/attempt-2/timing.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 266 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 5,664 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 2,052 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 263 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/attempt-3/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,045 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,904 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 787 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 264 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/claude-code/20261110T113553Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
