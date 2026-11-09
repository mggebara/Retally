# carrera-2022-who-chooses-commitment · independent · pipeline-desktop-opus · 20261102T065825Z

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261102T065825Z |
| Date | 2026-11-02T06:58:25Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z` |
| Executions | 5 |
| Refinements | 4 (1 error + 3 claim) |
| First attempt | 0/11 |
| First scored | 4/11 (execution 2) |
| Final | **7/11** |
| Package files withheld | 28 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `bcp_basic_info_treatment_col1` | 0.3 (0.56) | -0.273601 | 191.20% | ±0.56 (se_band) | FAIL | FAIL |
| `bcp_enhanced_info_treatment_col1` | 1.36 (0.57) | 0.219049 | 83.89% | ±0.57 (se_band) | FAIL | FAIL |
| `bcp_goal_minus_expected_attendance_col2` | 0.71 (0.29) | 0.642703 | 9.48% | ±0.29 (se_band) | PASS | FAIL |
| `bcp_actual_minus_expected_attendance_col3` | 0.45 (0.22) | 0.497777 | 10.62% | ±0.22 (se_band) | PASS | PASS |
| `bcp_regression_observations` | 1126 | 1248 | 10.83% | ±56.3 (relative) | FAIL | FAIL |
| `takeup_more_basic_info_treatment_col1` | -0.022 (0.041) | 0.008781 | 139.91% | ±0.041 (se_band) | PASS | PASS |
| `takeup_more_enhanced_info_treatment_col1` | -0.08 (0.031) | -0.016755 | 79.06% | ±0.031 (se_band) | FAIL | FAIL |
| `takeup_more_behavior_change_premium_col2` | 0.027 (0.011) | 0.021842 | 19.10% | ±0.011 (se_band) | PASS | PASS |
| `takeup_more_goal_minus_expected_attendance_col3` | 0.038 (0.013) | 0.040323 | 6.11% | ±0.013 (se_band) | PASS | FAIL |
| `takeup_more_actual_minus_expected_attendance_col4` | -0.043 (0.013) | -0.045058 | 4.79% | ±0.013 (se_band) | PASS | PASS |
| `takeup_more_regression_observations` | 2824 | 2946 | 4.32% | ±141.2 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/11 pass, which agrees with the row's 7/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 21,647 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 12,496 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 25,064 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 24,045 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 24,870 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 150 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 8,421 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 150 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,997 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 681 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 9,561 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 5,549 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 290 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 9,583 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 4,628 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/attempt-3/stdout.txt`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 302 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 9,790 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 4,714 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/attempt-4/stdout.txt`
- [`output/script.R`](output/script.R) — 9,886 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 128 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,648 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T065825Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,422 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/fae6ac1840f3d83305e8135f.json`
- [`output/answer-2.md`](output/answer-2.md) — 9,562 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/7967fe890c5ba159ce491762.json`
- [`output/answer-3.md`](output/answer-3.md) — 9,584 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/2366b0c65abb77939720c6b1.json`
- [`output/answer-4.md`](output/answer-4.md) — 9,791 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/a784952922db776011ef13ce.json`
- [`output/answer-5.md`](output/answer-5.md) — 9,887 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/bde2e80474eb5c4b8522ac66.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request fae6ac1840f3d83305e8135f: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request 7967fe890c5ba159ce491762: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus (request 2366b0c65abb77939720c6b1: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus (request a784952922db776011ef13ce: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus (request bde2e80474eb5c4b8522ac66: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 5 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
