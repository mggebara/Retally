# carrera-2022-who-chooses-commitment · blind · pipeline-desktop-opus-run4 · 20261108T060639Z

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261108T060639Z |
| Date | 2026-11-08T06:06:39Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z` |
| Executions | 3 |
| Refinements | 2 (2 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 4/11 (execution 3) |
| Final | **4/11** |
| Package files withheld | 29 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `bcp_basic_info_treatment_col1` | 0.3 (0.56) | -0.391157 | 230.39% | ±0.56 (se_band) | FAIL | FAIL |
| `bcp_enhanced_info_treatment_col1` | 1.36 (0.57) | 0.258863 | 80.97% | ±0.57 (se_band) | FAIL | FAIL |
| `bcp_goal_minus_expected_attendance_col2` | 0.71 (0.29) | -0.142052 | 120.01% | ±0.29 (se_band) | FAIL | FAIL |
| `bcp_actual_minus_expected_attendance_col3` | 0.45 (0.22) | 0.564759 | 25.50% | ±0.22 (se_band) | PASS | PASS |
| `bcp_regression_observations` | 1126 | 1280 | 13.68% | ±56.3 (relative) | FAIL | FAIL |
| `takeup_more_basic_info_treatment_col1` | -0.022 (0.041) | 0.007469 | 133.95% | ±0.041 (se_band) | PASS | PASS |
| `takeup_more_enhanced_info_treatment_col1` | -0.08 (0.031) | -0.030136 | 62.33% | ±0.031 (se_band) | FAIL | FAIL |
| `takeup_more_behavior_change_premium_col2` | 0.027 (0.011) | 0.018246 | 32.42% | ±0.011 (se_band) | PASS | PASS |
| `takeup_more_goal_minus_expected_attendance_col3` | 0.038 (0.013) | 0.0978 | 157.37% | ±0.013 (se_band) | FAIL | FAIL |
| `takeup_more_actual_minus_expected_attendance_col4` | -0.043 (0.013) | -0.03397 | 21.00% | ±0.013 (se_band) | PASS | PASS |
| `takeup_more_regression_observations` | 2824 | 1280 | 54.67% | ±141.2 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 4/11 pass, which agrees with the row's 4/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 21,813 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 12,922 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 14,345 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 152 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 7,278 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 152 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 3,564 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 71 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 207 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 7,711 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 207 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 4,499 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z/attempt-2/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z/execution.json`
- [`output/script.R`](output/script.R) — 9,619 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 128 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 9,210 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261108T060639Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,279 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/71447e634e802e61aa8364fe.json`
- [`output/answer-2.md`](output/answer-2.md) — 7,712 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/eb044179487ae2fe004f3ff8.json`
- [`output/answer-3.md`](output/answer-3.md) — 9,620 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/efdda85813c406f4ca792d36.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 1 | — | — | 0 |
| attempt-2 | error | 1 | — | — | 0 |
| final | final | 0 | no | 1.6 | 11 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request 71447e634e802e61aa8364fe: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run4 (request eb044179487ae2fe004f3ff8: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run4 (request efdda85813c406f4ca792d36: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
