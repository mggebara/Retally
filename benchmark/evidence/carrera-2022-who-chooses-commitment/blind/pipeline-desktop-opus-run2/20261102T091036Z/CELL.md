# carrera-2022-who-chooses-commitment · blind · pipeline-desktop-opus-run2 · 20261102T091036Z

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261102T091036Z |
| Date | 2026-11-02T09:10:36Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261102T091036Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 6/11 (execution 2) |
| Final | **7/11** |
| Package files withheld | 28 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `bcp_basic_info_treatment_col1` | 0.3 (0.56) | 0.203245 | 32.25% | ±0.56 (se_band) | PASS | PASS |
| `bcp_enhanced_info_treatment_col1` | 1.36 (0.57) | 1.25885 | 7.44% | ±0.57 (se_band) | PASS | PASS |
| `bcp_goal_minus_expected_attendance_col2` | 0.71 (0.29) | -0.0877375 | 112.36% | ±0.29 (se_band) | FAIL | FAIL |
| `bcp_actual_minus_expected_attendance_col3` | 0.45 (0.22) | 0.486171 | 8.04% | ±0.22 (se_band) | PASS | PASS |
| `bcp_regression_observations` | 1126 | 1152 | 2.31% | ±56.3 (relative) | PASS | FAIL |
| `takeup_more_basic_info_treatment_col1` | -0.022 (0.041) | -0.0741149 | 236.89% | ±0.041 (se_band) | FAIL | FAIL |
| `takeup_more_enhanced_info_treatment_col1` | -0.08 (0.031) | -0.07605 | 4.94% | ±0.031 (se_band) | PASS | PASS |
| `takeup_more_behavior_change_premium_col2` | 0.027 (0.011) | 0.025385 | 5.98% | ±0.011 (se_band) | PASS | PASS |
| `takeup_more_goal_minus_expected_attendance_col3` | 0.038 (0.013) | 0.0960554 | 152.78% | ±0.013 (se_band) | FAIL | FAIL |
| `takeup_more_actual_minus_expected_attendance_col4` | -0.043 (0.013) | -0.0528401 | 22.88% | ±0.013 (se_band) | PASS | PASS |
| `takeup_more_regression_observations` | 2824 | 1152 | 59.21% | ±141.2 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/11 pass, which agrees with the row's 7/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 21,695 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261102T091036Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 14,049 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261102T091036Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 32 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261102T091036Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 7,658 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261102T091036Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261102T091036Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 4,430 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261102T091036Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 9,622 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261102T091036Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261102T091036Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,419 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261102T091036Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,659 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/6ce23c5a1d74f8d1b91f967c.json`
- [`output/answer-2.md`](output/answer-2.md) — 9,623 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/b97ed3fea16b262d25518d36.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 6ce23c5a1d74f8d1b91f967c: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request b97ed3fea16b262d25518d36: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
