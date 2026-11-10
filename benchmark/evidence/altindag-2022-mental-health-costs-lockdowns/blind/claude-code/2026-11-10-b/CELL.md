# altindag-2022-mental-health-costs-lockdowns · blind · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `altindag-2022-mental-health-costs-lockdowns` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T11:31:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-altindag-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113206Z` |
| Run directory | `benchmark/reproductions/altindag-2022-mental-health-costs-lockdowns/blind/2026-11-10-b` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/10 |
| First scored | 9/10 (execution 3) |
| Final | **9/10** |
| Package files withheld | 17 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `days_outside_last_week_table3_col3` | -1.09 (0.18) | -1.08986 | 0.01% | ±0.18 (se_band) | PASS | PASS |
| `under_curfew_table3_col3` | 0.708 (0.045) | 0.708352 | 0.05% | ±0.045 (se_band) | PASS | PASS |
| `never_goes_out_table3_col3` | 0.297 (0.036) | 0.297368 | 0.12% | ±0.036 (se_band) | PASS | PASS |
| `n_obs_days_outside_table3_col3` | 1214 | 1199 | 1.24% | ±60.7 (relative) | PASS | PASS |
| `n_obs_under_curfew_table3_col3` | 1222 | 1207 | 1.23% | ±61.1 (relative) | PASS | PASS |
| `mental_distress_index_table4_col3` | 0.205 (0.094) | 0.157113 | 23.36% | ±0.094 (se_band) | PASS | PASS |
| `somatic_symptoms_index_table4_col3` | 0.175 (0.085) | 0.080142 | 54.20% | ±0.085 (se_band) | FAIL | FAIL |
| `nonsomatic_symptoms_index_table4_col3` | 0.158 (0.092) | 0.155809 | 1.39% | ±0.092 (se_band) | PASS | PASS |
| `sum_srq20_yes_answers_table4_col3` | 0.734 (0.44) | 0.73423 | 0.03% | ±0.44 (se_band) | PASS | PASS |
| `n_obs_mental_distress_index_table4_col3` | 1133 | 1117 | 1.41% | ±56.65 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/10 pass, which agrees with the row's 9/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Anderson (2008) indices: items standardized by control-group (born Jan 1956 or later, full +/-72-month respondent sample) mean/SD, combined with inverse-covariance weights (row sums of inverse covariance of standardized items, computed on respondents answering all 20 SRQ-20 items), then the index is rescaled to control-group mean 0 / SD 1. Indices and SRQ-20 sum defined only for respondents answering all 20 items. The paper's main text describes a simple average of z-scores while Appendix B describes inverse-covariance weighting; Appendix B was followed.
- (reproduction.json) Bandwidth +/-45 implemented as \|dif\| <= 45, where dif = months older than December 1955 (treated: dif >= 0).
- (reproduction.json) Estimated with fixest::feols (month, province, surveyor FE absorbed; education and ethnicity category dummies and female as regressors; clustered by month-year of birth). fixest drops fixed-effect singletons (15-16 obs here), as reghdfe would; the reported N excludes them.

Agent notes: Two exploratory runs (attempt-1: variable listing; attempt-2: running-variable coding, control categories, missingness), no RESULT lines. Final run: RD with treatment z = born in/before Dec 1955, linear running variable with slope allowed to differ across the cutoff, uniform kernel, 45-month bandwidth, respondents only (non_response == 0), listwise deletion on outcome and controls. No runs hung; each sandbox run took ~1 s.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,176 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113206Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 914 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113206Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 286 bytes, from `benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/blind/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 999 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113206Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113206Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 14,912 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113206Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 263 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113206Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,697 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113206Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113206Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,565 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113206Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 263 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113206Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,946 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113206Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,802 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113206Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 997 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113206Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 895 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113206Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 263 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113206Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
