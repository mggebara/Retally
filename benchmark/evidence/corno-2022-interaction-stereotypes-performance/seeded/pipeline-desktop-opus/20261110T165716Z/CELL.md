# corno-2022-interaction-stereotypes-performance · seeded · pipeline-desktop-opus · 20261110T165716Z

| | |
|---|---|
| Paper | `corno-2022-interaction-stereotypes-performance` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261110T165716Z |
| Date | 2026-11-10T16:57:16Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-corno-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T165716Z` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 6/13 |
| First scored | 6/13 (execution 1) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `race_iat_mixed_room_whites_table3_col1` | 0.316 (0.14) | 0.315851 | 0.05% | ±0.00632 (relative) | PASS | PASS |
| `race_iat_mixed_room_blacks_table3_col2` | -0.094 (0.069) | -0.0944469 | 0.48% | ±0.00188 (relative) | PASS | PASS |
| `n_obs_table3_whites` | 117 | 117 | 0.00% | ±5.85 (relative) | PASS | PASS |
| `n_obs_table3_blacks` | 332 | 332 | 0.00% | ±16.6 (relative) | PASS | PASS |
| `gpa_mixed_room_blacks_table4_panelB_col1` | 0.257 (0.125) | 0.256671 | 0.13% | ±0.00514 (relative) | PASS | FAIL |
| `exams_passed_mixed_room_blacks_table4_panelB_col2` | 0.645 (0.245) | 0.644533 | 0.07% | ±0.0129 (relative) | PASS | FAIL |
| `eligible_mixed_room_blacks_table4_panelB_col3` | 0.152 (0.04) | 0.151538 | 0.30% | ±0.00304 (relative) | PASS | FAIL |
| `performance_index_mixed_room_blacks_table4_panelB_col4` | 0.443 (0.141) | 0.443286 | 0.06% | ±0.00886 (relative) | PASS | FAIL |
| `gpa_mixed_room_whites_table4_panelA_col1` | -0.028 (0.243) | -0.0282361 | 0.84% | ±0.00056 (relative) | PASS | FAIL |
| `gpa_mixed_room_full_table4_panelC_col1` | 0.147 (0.102) | 0.146735 | 0.18% | ±0.00294 (relative) | PASS | FAIL |
| `exams_passed_mixed_room_full_table4_panelC_col2` | 0.447 (0.204) | 0.446589 | 0.09% | ±0.00894 (relative) | PASS | PASS |
| `performance_index_mixed_room_full_table4_panelC_col4` | 0.289 (0.113) | 0.289163 | 0.06% | ±0.00578 (relative) | PASS | FAIL |
| `n_obs_table4_panelC_cols1_2` | 499 | 499 | 0.00% | ±24.95 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) roconsbas_miss (roommate consumption missing dummy) absent from data; reconstructed from roommate's consbas_miss / mean-imputed roconsbas_nomiss

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 220,851 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T165716Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 18,981 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T165716Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T165716Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 725 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T165716Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 6,516 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T165716Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 731 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T165716Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 754 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T165716Z/attempt-1/stdout.txt`
- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T165716Z/execution.json`
- [`output/script.R`](output/script.R) — 8,556 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T165716Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 774 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T165716Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 911 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T165716Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,517 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/915dce1e7f1c973de7b74d1b.json`
- [`output/answer-2.md`](output/answer-2.md) — 8,557 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/f6bffb801b9ec50e1f9e81c7.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 1.4 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 915dce1e7f1c973de7b74d1b: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request f6bffb801b9ec50e1f9e81c7: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 2 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
