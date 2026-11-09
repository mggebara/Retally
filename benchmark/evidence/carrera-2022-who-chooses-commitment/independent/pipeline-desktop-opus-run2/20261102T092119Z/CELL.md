# carrera-2022-who-chooses-commitment · independent · pipeline-desktop-opus-run2 · 20261102T092119Z

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261102T092119Z |
| Date | 2026-11-02T09:21:19Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T092119Z` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 0/11 |
| First scored | 0/11 (execution 1) |
| Final | **0/11** |
| Package files withheld | 28 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `bcp_basic_info_treatment_col1` | 0.3 (0.56) | — | — | ±0.56 (se_band) | FAIL | FAIL |
| `bcp_enhanced_info_treatment_col1` | 1.36 (0.57) | — | — | ±0.57 (se_band) | FAIL | FAIL |
| `bcp_goal_minus_expected_attendance_col2` | 0.71 (0.29) | — | — | ±0.29 (se_band) | FAIL | FAIL |
| `bcp_actual_minus_expected_attendance_col3` | 0.45 (0.22) | — | — | ±0.22 (se_band) | FAIL | FAIL |
| `bcp_regression_observations` | 1126 | 0 | 100.00% | ±56.3 (relative) | FAIL | FAIL |
| `takeup_more_basic_info_treatment_col1` | -0.022 (0.041) | — | — | ±0.041 (se_band) | FAIL | FAIL |
| `takeup_more_enhanced_info_treatment_col1` | -0.08 (0.031) | — | — | ±0.031 (se_band) | FAIL | FAIL |
| `takeup_more_behavior_change_premium_col2` | 0.027 (0.011) | — | — | ±0.011 (se_band) | FAIL | FAIL |
| `takeup_more_goal_minus_expected_attendance_col3` | 0.038 (0.013) | — | — | ±0.013 (se_band) | FAIL | FAIL |
| `takeup_more_actual_minus_expected_attendance_col4` | -0.043 (0.013) | — | — | ±0.013 (se_band) | FAIL | FAIL |
| `takeup_more_regression_observations` | 2824 | — | — | ±141.2 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 0/11 pass, which agrees with the row's 0/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) wave coded by group size (smallest=1, largest=2, middle=3) because wave values are not numeric

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 21,250 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T092119Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 18,736 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T092119Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 1,067 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T092119Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 7,694 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T092119Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 938 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T092119Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,060 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T092119Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 11,468 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T092119Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 938 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T092119Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,136 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261102T092119Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,695 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/a65cf976a1b632d020063e20.json`
- [`output/answer-2.md`](output/answer-2.md) — 11,469 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/2ec59bcbfee75debd262ef5f.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request a65cf976a1b632d020063e20: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request 2ec59bcbfee75debd262ef5f: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
