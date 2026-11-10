# altindag-2022-mental-health-costs-lockdowns · independent · claude-code · 2026-11-10-d

| | |
|---|---|
| Paper | `altindag-2022-mental-health-costs-lockdowns` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-d |
| Date | 2026-11-10T11:32:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run4-1paper-altindag-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z` |
| Run directory | `benchmark/reproductions/altindag-2022-mental-health-costs-lockdowns/independent/2026-11-10-d` |
| Executions | 4 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 0/10 |
| First scored | 10/10 (execution 3) |
| Final | **10/10** |
| Package files withheld | 17 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `days_outside_last_week_table3_col3` | -1.09 (0.18) | -1.08986 | 0.01% | ±0.18 (se_band) | PASS | PASS |
| `under_curfew_table3_col3` | 0.708 (0.045) | 0.708352 | 0.05% | ±0.045 (se_band) | PASS | PASS |
| `never_goes_out_table3_col3` | 0.297 (0.036) | 0.297368 | 0.12% | ±0.036 (se_band) | PASS | PASS |
| `n_obs_days_outside_table3_col3` | 1214 | 1214 | 0.00% | ±60.7 (relative) | PASS | PASS |
| `n_obs_under_curfew_table3_col3` | 1222 | 1222 | 0.00% | ±61.1 (relative) | PASS | PASS |
| `mental_distress_index_table4_col3` | 0.205 (0.094) | 0.157113 | 23.36% | ±0.094 (se_band) | PASS | PASS |
| `somatic_symptoms_index_table4_col3` | 0.175 (0.085) | 0.111989 | 36.01% | ±0.085 (se_band) | PASS | PASS |
| `nonsomatic_symptoms_index_table4_col3` | 0.158 (0.092) | 0.151908 | 3.86% | ±0.092 (se_band) | PASS | PASS |
| `sum_srq20_yes_answers_table4_col3` | 0.734 (0.44) | 0.73423 | 0.03% | ±0.44 (se_band) | PASS | PASS |
| `n_obs_mental_distress_index_table4_col3` | 1133 | 1133 | 0.00% | ±56.65 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/10 pass, which agrees with the row's 10/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Anderson (2008) indices built as: items standardized by control-group (born 1956+) mean and SD, inverse-covariance (row-sum) weights from the covariance of the standardized items over complete cases, index re-standardized to control mean 0 / SD 1; computed once on the full respondent sample (not within the bandwidth). The authors' _gweightave2.ado was not available, so the exact weighting/normalization may differ.

Agent notes: Spec: feols(y ~ before1955 + dif + dif:before1955 + female \| birth month + province + surveyor + education + ethnicity), \|dif\| <= 45 months, uniform kernel, SEs clustered by month-year of birth (modate), survey non-respondents dropped. Attempts 1-2 were exploratory (variable listing; sample-size counts showing \|dif\|<=45 with complete controls reproduces 1214/1222/1203/1133 exactly). Attempt 3 was the first estimating run; fixest dropped fixed-effect singletons (N=1199 etc.). check_attempt reported all claims within tolerance, but I had compared N with Table 3 myself, so the final run (singletons kept, fixef.rm='none', as dummy-variable OLS in Stata does) is recorded after a claim attempt. Final: mobility coefficients, SRQ-20 sum and all Ns match the paper (SEs too: 0.180, 0.045, 0.036, 0.440); the three Anderson indices come out lower than published (0.157 vs 0.205, 0.112 vs 0.175, 0.152 vs 0.158) although their samples match, so the index construction differs in a detail I could not recover from the text; I did not tune it to the claims.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 17,603 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 946 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 286 bytes, from `benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/independent/2026-11-10-d/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 638 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 14,109 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 269 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,751 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,440 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 269 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/attempt-2/timing.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 29 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 3,530 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 1,094 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 725 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 269 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/attempt-3/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,099 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,652 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 569 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 725 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 269 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113203Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
