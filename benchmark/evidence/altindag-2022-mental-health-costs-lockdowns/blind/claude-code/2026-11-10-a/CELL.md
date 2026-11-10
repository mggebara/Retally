# altindag-2022-mental-health-costs-lockdowns · blind · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `altindag-2022-mental-health-costs-lockdowns` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T11:31:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-altindag-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113204Z` |
| Run directory | `benchmark/reproductions/altindag-2022-mental-health-costs-lockdowns/blind/2026-11-10-a` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/10 |
| First scored | 9/10 (execution 2) |
| Final | **9/10** |
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
| `somatic_symptoms_index_table4_col3` | 0.175 (0.085) | 0.080142 | 54.20% | ±0.085 (se_band) | FAIL | FAIL |
| `nonsomatic_symptoms_index_table4_col3` | 0.158 (0.092) | 0.155809 | 1.39% | ±0.092 (se_band) | PASS | PASS |
| `sum_srq20_yes_answers_table4_col3` | 0.734 (0.44) | 0.73423 | 0.03% | ±0.44 (se_band) | PASS | PASS |
| `n_obs_mental_distress_index_table4_col3` | 1133 | 1133 | 0.00% | ±56.65 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/10 pass, which agrees with the row's 9/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Bandwidth sample taken as \|dif\| <= 45 (dif = months older than December 1955; dif=0 is December 1955, treated). The paper's equation writes an open interval (c-h, c+h); the closed version was chosen because the text says 'born within 45 months'.
- (reproduction.json) Anderson (2008) indices: items standardized by control-group (born Jan 1956 or later, before1955==0) mean and SD over all respondents answering every SRQ-20 item (full sample, not just the bandwidth); weights are row sums of the inverse covariance matrix of the standardized items; the weighted index is re-standardized to mean 0, SD 1 in the control group.
- (reproduction.json) Observation counts are complete cases (outcome, treatment, running variable, education, ethnicity, female, birth month, province, surveyor) in the bandwidth, i.e. without dropping fixed-effect singletons (fixest drops 15-16 singletons in estimation, which does not change the point estimates).

Agent notes: Exploratory attempt-1 listed variables (no RESULT lines). Final script: sample excludes survey non-respondents (non_response==1); OLS of outcome on before1955, dif and dif*before1955 (linear separately on each side, uniform kernel), with education and ethnicity category dummies, female, and birth-month, province and surveyor fixed effects, SEs clustered by month-year of birth (dif), via fixest::feols. SRQ sum and indices defined only for respondents answering all 20 items. Used the dataset's head_ache variable as 'frequent headaches'. The ICPSR 'read me .pdf' was not opened. No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,176 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113204Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 914 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113204Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 286 bytes, from `benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/blind/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 909 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113204Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113204Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 19,881 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113204Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 263 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113204Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,014 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113204Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,022 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113204Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 483 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113204Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,242 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113204Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 262 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113204Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
