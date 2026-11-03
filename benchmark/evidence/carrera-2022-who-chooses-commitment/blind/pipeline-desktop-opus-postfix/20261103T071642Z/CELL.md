# carrera-2022-who-chooses-commitment · blind · pipeline-desktop-opus-postfix · 20261103T071642Z

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T071642Z |
| Date | 2026-11-03T07:16:42Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z` |
| Executions | 4 |
| Refinements | 3 (3 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 8/11 (execution 4) |
| Final | **8/11** |
| Package files withheld | 29 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `bcp_basic_info_treatment_col1` | 0.3 (0.56) | 0.203245 | 32.25% | ±0.56 (se_band) | PASS | PASS |
| `bcp_enhanced_info_treatment_col1` | 1.36 (0.57) | 1.32675 | 2.44% | ±0.57 (se_band) | PASS | PASS |
| `bcp_goal_minus_expected_attendance_col2` | 0.71 (0.29) | 0.841352 | 18.50% | ±0.29 (se_band) | PASS | PASS |
| `bcp_actual_minus_expected_attendance_col3` | 0.45 (0.22) | 0.486171 | 8.04% | ±0.22 (se_band) | PASS | PASS |
| `bcp_regression_observations` | 1126 | 1280 | 13.68% | ±56.3 (relative) | FAIL | FAIL |
| `takeup_more_basic_info_treatment_col1` | -0.022 (0.041) | -0.074115 | 236.89% | ±0.041 (se_band) | FAIL | FAIL |
| `takeup_more_enhanced_info_treatment_col1` | -0.08 (0.031) | -0.056543 | 29.32% | ±0.031 (se_band) | PASS | PASS |
| `takeup_more_behavior_change_premium_col2` | 0.027 (0.011) | 0.020232 | 25.07% | ±0.011 (se_band) | PASS | PASS |
| `takeup_more_goal_minus_expected_attendance_col3` | 0.038 (0.013) | 0.040105 | 5.54% | ±0.013 (se_band) | PASS | PASS |
| `takeup_more_actual_minus_expected_attendance_col4` | -0.043 (0.013) | -0.05284 | 22.88% | ±0.013 (se_band) | PASS | PASS |
| `takeup_more_regression_observations` | 2824 | 1280 | 54.67% | ±141.2 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/11 pass, which agrees with the row's 8/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 28,844 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 10,683 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 11,244 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 11,934 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 84 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 8,660 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 84 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 186 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/attempt-2/feedback.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 106 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 8,799 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 186 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 252 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 186 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/attempt-3/feedback.txt`
- [`output/attempt-3/samples.txt`](output/attempt-3/samples.txt) — 106 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/attempt-3/samples.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 9,468 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 186 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 273 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/attempt-3/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 331 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/samples.txt`
- [`output/script.R`](output/script.R) — 10,989 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 128 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,281 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261103T071642Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,661 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/036219949b7d2f2dbe6e0cce.json`
- [`output/answer-2.md`](output/answer-2.md) — 8,800 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/686348cf0009fe01b4450b24.json`
- [`output/answer-3.md`](output/answer-3.md) — 9,469 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/d80574f8e7b3b70464f1da69.json`
- [`output/answer-4.md`](output/answer-4.md) — 10,990 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/23a02be16dbb959957f41ed5.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request 036219949b7d2f2dbe6e0cce: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix (request 686348cf0009fe01b4450b24: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix (request d80574f8e7b3b70464f1da69: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-postfix (request 23a02be16dbb959957f41ed5: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
