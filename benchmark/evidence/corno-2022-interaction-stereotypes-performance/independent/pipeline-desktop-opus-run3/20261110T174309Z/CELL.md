# corno-2022-interaction-stereotypes-performance · independent · pipeline-desktop-opus-run3 · 20261110T174309Z

| | |
|---|---|
| Paper | `corno-2022-interaction-stereotypes-performance` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261110T174309Z |
| Date | 2026-11-10T17:43:09Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-1paper-corno-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T174309Z` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 12/13 |
| First scored | 12/13 (execution 1) |
| Final | **13/13** |
| Package files withheld | 20 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `race_iat_mixed_room_whites_table3_col1` | 0.316 (0.14) | 0.315851 | 0.05% | ±0.14 (se_band) | PASS | PASS |
| `race_iat_mixed_room_blacks_table3_col2` | -0.094 (0.069) | -0.0944469 | 0.48% | ±0.069 (se_band) | PASS | PASS |
| `n_obs_table3_whites` | 117 | 117 | 0.00% | ±5.85 (relative) | PASS | PASS |
| `n_obs_table3_blacks` | 332 | 332 | 0.00% | ±16.6 (relative) | PASS | PASS |
| `gpa_mixed_room_blacks_table4_panelB_col1` | 0.257 (0.125) | 0.256671 | 0.13% | ±0.125 (se_band) | PASS | PASS |
| `exams_passed_mixed_room_blacks_table4_panelB_col2` | 0.645 (0.245) | 0.644533 | 0.07% | ±0.245 (se_band) | PASS | PASS |
| `eligible_mixed_room_blacks_table4_panelB_col3` | 0.152 (0.04) | 0.151538 | 0.30% | ±0.04 (se_band) | PASS | FAIL |
| `performance_index_mixed_room_blacks_table4_panelB_col4` | 0.443 (0.141) | 0.443286 | 0.06% | ±0.141 (se_band) | PASS | PASS |
| `gpa_mixed_room_whites_table4_panelA_col1` | -0.028 (0.243) | -0.0282361 | 0.84% | ±0.243 (se_band) | PASS | PASS |
| `gpa_mixed_room_full_table4_panelC_col1` | 0.147 (0.102) | 0.146735 | 0.18% | ±0.102 (se_band) | PASS | PASS |
| `exams_passed_mixed_room_full_table4_panelC_col2` | 0.447 (0.204) | 0.446589 | 0.09% | ±0.204 (se_band) | PASS | PASS |
| `performance_index_mixed_room_full_table4_panelC_col4` | 0.289 (0.113) | 0.289163 | 0.06% | ±0.113 (se_band) | PASS | PASS |
| `n_obs_table4_panelC_cols1_2` | 499 | 499 | 0.00% | ±24.95 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,514 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T174309Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 23,578 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T174309Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T174309Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 113 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T174309Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 10,987 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T174309Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 2,138 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T174309Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 716 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T174309Z/attempt-1/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T174309Z/execution.json`
- [`output/script.R`](output/script.R) — 11,179 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T174309Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 2,211 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T174309Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 716 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T174309Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,988 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/58b131f64818ae515b4b9de8.json`
- [`output/answer-2.md`](output/answer-2.md) — 11,180 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/59d587546534508b4645360b.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 1.2 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 58b131f64818ae515b4b9de8: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request 59d587546534508b4645360b: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
