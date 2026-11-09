# carrera-2022-who-chooses-commitment · independent · pipeline-desktop-opus-run3 · 20261103T052626Z

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T052626Z |
| Date | 2026-11-03T05:26:26Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 0/11 |
| First scored | 0/11 (execution 1) |
| Final | **8/11** |
| Package files withheld | 29 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `bcp_basic_info_treatment_col1` | 0.3 (0.56) | -0.273601 | 191.20% | ±0.56 (se_band) | FAIL | FAIL |
| `bcp_enhanced_info_treatment_col1` | 1.36 (0.57) | 0.156288 | 88.51% | ±0.57 (se_band) | FAIL | FAIL |
| `bcp_goal_minus_expected_attendance_col2` | 0.71 (0.29) | 0.683304 | 3.76% | ±0.29 (se_band) | PASS | FAIL |
| `bcp_actual_minus_expected_attendance_col3` | 0.45 (0.22) | 0.497777 | 10.62% | ±0.22 (se_band) | PASS | FAIL |
| `bcp_regression_observations` | 1126 | 1126 | 0.00% | ±56.3 (relative) | PASS | FAIL |
| `takeup_more_basic_info_treatment_col1` | -0.022 (0.041) | -0.027085 | 23.11% | ±0.041 (se_band) | PASS | FAIL |
| `takeup_more_enhanced_info_treatment_col1` | -0.08 (0.031) | -0.024324 | 69.60% | ±0.031 (se_band) | FAIL | FAIL |
| `takeup_more_behavior_change_premium_col2` | 0.027 (0.011) | 0.020646 | 23.53% | ±0.011 (se_band) | PASS | FAIL |
| `takeup_more_goal_minus_expected_attendance_col3` | 0.038 (0.013) | 0.029226 | 23.09% | ±0.013 (se_band) | PASS | FAIL |
| `takeup_more_actual_minus_expected_attendance_col4` | -0.043 (0.013) | -0.032806 | 23.71% | ±0.013 (se_band) | PASS | FAIL |
| `takeup_more_regression_observations` | 2824 | 2824 | 0.00% | ±141.2 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/11 pass, which agrees with the row's 8/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Sample additionally excludes potentially endogenous assignments via rule rule1_flag_low_wtp chosen to match paper N=1126
- (DEVIATION: line) Unlabelled columns q169/q170 used as the >=8 and >=16 'more' contract choices

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 21,231 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 25,280 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 23,595 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 26,466 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 1,067 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 10,201 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 6,425 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 458 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 9,390 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 4,970 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 194 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 11,133 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 9,112 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/attempt-3/stdout.txt`
- [`output/script.R`](output/script.R) — 11,229 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 9,110 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T052626Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,202 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/ca1ed84721cad5d8694aa7d2.json`
- [`output/answer-2.md`](output/answer-2.md) — 9,391 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/0e51b94a029c827731283f0d.json`
- [`output/answer-3.md`](output/answer-3.md) — 11,134 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/8c320c3491b1690f33db18f4.json`
- [`output/answer-4.md`](output/answer-4.md) — 11,230 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/4e40888933879f97ec67f3c1.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request ca1ed84721cad5d8694aa7d2: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request 0e51b94a029c827731283f0d: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run3 (request 8c320c3491b1690f33db18f4: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run3 (request 4e40888933879f97ec67f3c1: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
