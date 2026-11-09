# carrera-2022-who-chooses-commitment · blind · pipeline-desktop-opus-run3 · 20261103T010557Z

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T010557Z |
| Date | 2026-11-03T01:05:57Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T010557Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 4/11 (execution 2) |
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

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 21,834 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T010557Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 12,814 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T010557Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 188 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T010557Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 6,249 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T010557Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 188 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T010557Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 4,449 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T010557Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 7,764 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T010557Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 128 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T010557Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 8,248 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T010557Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,250 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/3ea0a0cfa13e4294758f92ae.json`
- [`output/answer-2.md`](output/answer-2.md) — 7,765 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/2861c7b6232538c32528a51e.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 3ea0a0cfa13e4294758f92ae: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request 2861c7b6232538c32528a51e: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
