# corno-2022-interaction-stereotypes-performance · blind · pipeline-desktop-opus-run3 · 20261110T172220Z

| | |
|---|---|
| Paper | `corno-2022-interaction-stereotypes-performance` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261110T172220Z |
| Date | 2026-11-10T17:22:20Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-1paper-corno-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/pipeline/20261110T172220Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 10/13 |
| First scored | 10/13 (execution 1) |
| Final | **10/13** |
| Package files withheld | 20 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `race_iat_mixed_room_whites_table3_col1` | 0.316 (0.14) | 0.319171 | 1.00% | ±0.14 (se_band) | PASS | PASS |
| `race_iat_mixed_room_blacks_table3_col2` | -0.094 (0.069) | -0.0930825 | 0.98% | ±0.069 (se_band) | PASS | PASS |
| `n_obs_table3_whites` | 117 | 117 | 0.00% | ±5.85 (relative) | PASS | PASS |
| `n_obs_table3_blacks` | 332 | 332 | 0.00% | ±16.6 (relative) | PASS | PASS |
| `gpa_mixed_room_blacks_table4_panelB_col1` | 0.257 (0.125) | 0.197251 | 23.25% | ±0.125 (se_band) | PASS | PASS |
| `exams_passed_mixed_room_blacks_table4_panelB_col2` | 0.645 (0.245) | 0.522401 | 19.01% | ±0.245 (se_band) | PASS | PASS |
| `eligible_mixed_room_blacks_table4_panelB_col3` | 0.152 (0.04) | 0.0749433 | 50.70% | ±0.04 (se_band) | FAIL | FAIL |
| `performance_index_mixed_room_blacks_table4_panelB_col4` | 0.443 (0.141) | 0.298085 | 32.71% | ±0.141 (se_band) | FAIL | FAIL |
| `gpa_mixed_room_whites_table4_panelA_col1` | -0.028 (0.243) | -0.0631093 | 125.39% | ±0.243 (se_band) | PASS | PASS |
| `gpa_mixed_room_full_table4_panelC_col1` | 0.147 (0.102) | 0.0745333 | 49.30% | ±0.102 (se_band) | PASS | PASS |
| `exams_passed_mixed_room_full_table4_panelC_col2` | 0.447 (0.204) | 0.277073 | 38.02% | ±0.204 (se_band) | PASS | PASS |
| `performance_index_mixed_room_full_table4_panelC_col4` | 0.289 (0.113) | 0.130254 | 54.93% | ±0.113 (se_band) | FAIL | FAIL |
| `n_obs_table4_panelC_cols1_2` | 499 | 499 | 0.00% | ±24.95 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/13 pass, which agrees with the row's 10/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,901 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/pipeline/20261110T172220Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/pipeline/20261110T172220Z/execution.json`
- [`output/script.R`](output/script.R) — 8,967 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/pipeline/20261110T172220Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,532 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/pipeline/20261110T172220Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 757 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/pipeline/20261110T172220Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,968 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/c14a2559be1e51512794d197.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 1.1 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request c14a2559be1e51512794d197: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
