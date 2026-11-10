# altindag-2022-mental-health-costs-lockdowns · blind · claude-code · 2026-11-10-d

| | |
|---|---|
| Paper | `altindag-2022-mental-health-costs-lockdowns` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-d |
| Date | 2026-11-10T11:34:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run4-1paper-altindag-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113555Z` |
| Run directory | `benchmark/reproductions/altindag-2022-mental-health-costs-lockdowns/blind/2026-11-10-d` |
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

- (reproduction.json) Bandwidth +/-45 implemented as \|dif\| <= 45 (dif = months older than December 1955; treated side dif 0..45, control side -1..-45).
- (reproduction.json) Anderson (2008) indices: items standardized by control-group (born Jan 1956 or later) mean/SD over all respondents answering all 20 SRQ-20 items (not bandwidth-restricted); weights are row sums of the inverse covariance matrix of the standardized items (computed on that full complete-case sample); the weighted index is re-standardized to control-group mean 0 / SD 1.
- (reproduction.json) Fixed effects and indicators entered as factor dummies in feols (birth month, province, surveyor, education category, ethnicity category, female); observations with any missing outcome/control dropped; no singleton removal.

Agent notes: Two exploratory runs (variable listing; check of dif/before1955 coding and control categories), then one scored run. Sample: survey respondents (non_response == 0, N=1909). Treatment before1955 (born in or before Dec 1955), running variable dif, linear on each side (dif + dif:before1955), uniform kernel, \|dif\|<=45, controls as in the Table 3/4 notes, SEs clustered by month-year of birth (dif). No run hung. No specification was adjusted toward any paper number.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,176 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113555Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 914 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113555Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 286 bytes, from `benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/blind/2026-11-10-d/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 676 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113555Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113555Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 14,137 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113555Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 263 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113555Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 864 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113555Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113555Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,479 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113555Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 263 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113555Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,763 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113555Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,555 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113555Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113555Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,031 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113555Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 263 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/claude-code/20261110T113555Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
