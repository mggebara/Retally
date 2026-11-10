# altindag-2022-mental-health-costs-lockdowns · independent · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `altindag-2022-mental-health-costs-lockdowns` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T11:31:35Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-altindag-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z` |
| Run directory | `benchmark/reproductions/altindag-2022-mental-health-costs-lockdowns/independent/2026-11-10-b` |
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

- (reproduction.json) Anderson (2008) indices: items standardized by the mean/sd of the control group (born Jan 1956 or later) in the full respondent sample; inverse-covariance weights from all complete-case respondents; index defined only for respondents answering every component item; final index re-standardized to control mean 0 / sd 1. Exact details of the authors' implementation are not given in the paper, and the index coefficients (0.157, 0.112, 0.152) are below the published ones (0.205, 0.175, 0.158).

Agent notes: Sample: survey respondents (non_response == 0) with \|dif\| <= 45, dif = months born before Dec 1955 (Dec 1955 itself treated). OLS (fixest) of outcome on treatment, dif and treatment x dif; month-of-birth, province and surveyor fixed effects; education and ethnicity category dummies and female; SEs clustered by month-year of birth (dif). Attempts 1-2 were exploratory (variable listing; sample counts by bandwidth, which matched every published N under \|dif\| <= h with complete-case indices). Attempt 3 was the first estimating run; check_attempt reported all claims within tolerance, but my own comparison showed Ns 15-16 lower because fixest dropped fixed-effect singletons; the final run keeps singletons (fixef.rm = 'none'), which reproduces N = 1214 / 1222 / 1133 exactly and leaves coefficients unchanged. Mobility coefficients (-1.090, 0.708, 0.297) and the SRQ-20 sum (0.734) match the paper; the Anderson index coefficients are lower than published and were not tuned. No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 17,603 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 946 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 286 bytes, from `benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/independent/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 543 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 13,827 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 268 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,834 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,464 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 269 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/attempt-2/timing.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 759 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 3,133 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 996 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 885 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 268 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/attempt-3/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,112 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,265 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 499 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 885 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 268 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113216Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
