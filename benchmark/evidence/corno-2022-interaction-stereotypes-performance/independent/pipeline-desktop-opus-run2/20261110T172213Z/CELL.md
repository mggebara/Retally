# corno-2022-interaction-stereotypes-performance · independent · pipeline-desktop-opus-run2 · 20261110T172213Z

| | |
|---|---|
| Paper | `corno-2022-interaction-stereotypes-performance` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261110T172213Z |
| Date | 2026-11-10T17:22:13Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-corno-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T172213Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 13/13 |
| First scored | 13/13 (execution 1) |
| Final | **13/13** |
| Package files withheld | 20 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `race_iat_mixed_room_whites_table3_col1` | 0.316 (0.14) | 0.310493 | 1.74% | ±0.14 (se_band) | PASS | PASS |
| `race_iat_mixed_room_blacks_table3_col2` | -0.094 (0.069) | -0.088354 | 6.01% | ±0.069 (se_band) | PASS | PASS |
| `n_obs_table3_whites` | 117 | 117 | 0.00% | ±5.85 (relative) | PASS | PASS |
| `n_obs_table3_blacks` | 332 | 332 | 0.00% | ±16.6 (relative) | PASS | PASS |
| `gpa_mixed_room_blacks_table4_panelB_col1` | 0.257 (0.125) | 0.26014 | 1.22% | ±0.125 (se_band) | PASS | PASS |
| `exams_passed_mixed_room_blacks_table4_panelB_col2` | 0.645 (0.245) | 0.666856 | 3.39% | ±0.245 (se_band) | PASS | PASS |
| `eligible_mixed_room_blacks_table4_panelB_col3` | 0.152 (0.04) | 0.153279 | 0.84% | ±0.04 (se_band) | PASS | PASS |
| `performance_index_mixed_room_blacks_table4_panelB_col4` | 0.443 (0.141) | 0.451422 | 1.90% | ±0.141 (se_band) | PASS | PASS |
| `gpa_mixed_room_whites_table4_panelA_col1` | -0.028 (0.243) | -0.033075 | 18.12% | ±0.243 (se_band) | PASS | PASS |
| `gpa_mixed_room_full_table4_panelC_col1` | 0.147 (0.102) | 0.148335 | 0.91% | ±0.102 (se_band) | PASS | PASS |
| `exams_passed_mixed_room_full_table4_panelC_col2` | 0.447 (0.204) | 0.451631 | 1.04% | ±0.204 (se_band) | PASS | PASS |
| `performance_index_mixed_room_full_table4_panelC_col4` | 0.289 (0.113) | 0.290266 | 0.44% | ±0.113 (se_band) | PASS | PASS |
| `n_obs_table4_panelC_cols1_2` | 499 | 493 | 1.20% | ±24.95 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,514 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T172213Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T172213Z/execution.json`
- [`output/script.R`](output/script.R) — 10,109 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T172213Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,869 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T172213Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 714 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/pipeline/20261110T172213Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,110 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/58b131f64818ae515b4b9de8.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 1.1 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 58b131f64818ae515b4b9de8: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
