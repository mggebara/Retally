# altindag-2022-mental-health-costs-lockdowns · independent · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `altindag-2022-mental-health-costs-lockdowns` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T11:31:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-altindag-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113201Z` |
| Run directory | `benchmark/reproductions/altindag-2022-mental-health-costs-lockdowns/independent/2026-11-10-a` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/10 |
| First scored | 10/10 (execution 3) |
| Final | **10/10** |
| Package files withheld | 17 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `days_outside_last_week_table3_col3` | -1.09 (0.18) | -1.0899 | 0.01% | ±0.18 (se_band) | PASS | PASS |
| `under_curfew_table3_col3` | 0.708 (0.045) | 0.7084 | 0.06% | ±0.045 (se_band) | PASS | PASS |
| `never_goes_out_table3_col3` | 0.297 (0.036) | 0.2974 | 0.13% | ±0.036 (se_band) | PASS | PASS |
| `n_obs_days_outside_table3_col3` | 1214 | 1199 | 1.24% | ±60.7 (relative) | PASS | PASS |
| `n_obs_under_curfew_table3_col3` | 1222 | 1207 | 1.23% | ±61.1 (relative) | PASS | PASS |
| `mental_distress_index_table4_col3` | 0.205 (0.094) | 0.1585 | 22.68% | ±0.094 (se_band) | PASS | PASS |
| `somatic_symptoms_index_table4_col3` | 0.175 (0.085) | 0.1126 | 35.66% | ±0.085 (se_band) | PASS | PASS |
| `nonsomatic_symptoms_index_table4_col3` | 0.158 (0.092) | 0.1505 | 4.75% | ±0.092 (se_band) | PASS | PASS |
| `sum_srq20_yes_answers_table4_col3` | 0.734 (0.44) | 0.7342 | 0.03% | ±0.44 (se_band) | PASS | PASS |
| `n_obs_mental_distress_index_table4_col3` | 1133 | 1117 | 1.41% | ±56.65 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/10 pass, which agrees with the row's 10/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) fixest's default removed 15-16 fixed-effect singleton observations per regression, so reported N (1199, 1207, 1117) is below the full estimation sample (1214, 1222, 1133 identified in exploratory attempt-2 with \|dif\|<=45 and complete controls); coefficients are unaffected by singleton removal. Not changed after comparison with claims.
- (reproduction.json) Anderson (2008) indices built on the full respondent sample (non_response==0): items standardized by control-group (born Jan 1956 or later) mean/SD, weighted by row sums of the inverse covariance matrix of standardized items, index re-standardized to control mean 0/SD 1; index defined only where all component items are observed (matches the paper's sample sizes).

Agent notes: Attempt-1: variable listing. Attempt-2: checked running variable (dif = months older than Dec 1955; before1955=1 for dif>=0) and sample counts; \|dif\|<=45 with complete controls reproduces the paper's Ns exactly. Final: feols of outcome on before1955 + dif + dif*before1955 + female + education and ethnicity dummies \| birth-month, province and surveyor FE, SEs clustered by month-year of birth (dif), uniform kernel, 45-month bandwidth. Compared RESULTs with claims once via check_attempt ('All claims within tolerance.'); script not changed afterwards, so no claim attempt recorded. Mental-health index coefficients are below the claimed values (mental distress 0.159 vs 0.205, somatic 0.113 vs 0.175, nonsomatic 0.151 vs 0.158); the SRQ-20 sum (0.734) and mobility outcomes match closely, so the gap likely comes from index construction details (e.g. sample used for standardization/weights). No hung runs.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 17,603 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113201Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 946 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113201Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 286 bytes, from `benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/independent/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 853 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113201Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113201Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 17,734 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113201Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 269 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113201Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,494 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113201Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113201Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,376 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113201Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 269 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113201Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,186 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113201Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,079 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113201Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 996 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113201Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 872 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113201Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 269 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113201Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
