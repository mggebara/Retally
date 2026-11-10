# corno-2022-interaction-stereotypes-performance · seeded · pipeline-desktop-opus-run2 · 20261110T221318Z

| | |
|---|---|
| Paper | `corno-2022-interaction-stereotypes-performance` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261110T221318Z |
| Date | 2026-11-10T22:13:18Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-corno-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z` |
| Executions | 3 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 6/13 |
| First scored | 6/13 (execution 1) |
| Final | **7/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `race_iat_mixed_room_whites_table3_col1` | 0.316 (0.14) | 0.315851 | 0.05% | ±0.00632 (relative) | PASS | PASS |
| `race_iat_mixed_room_blacks_table3_col2` | -0.094 (0.069) | -0.0944469 | 0.48% | ±0.00188 (relative) | PASS | PASS |
| `n_obs_table3_whites` | 117 | 117 | 0.00% | ±5.85 (relative) | PASS | PASS |
| `n_obs_table3_blacks` | 332 | 332 | 0.00% | ±16.6 (relative) | PASS | PASS |
| `gpa_mixed_room_blacks_table4_panelB_col1` | 0.257 (0.125) | 0.23668 | 7.91% | ±0.00514 (relative) | FAIL | FAIL |
| `exams_passed_mixed_room_blacks_table4_panelB_col2` | 0.645 (0.245) | 0.624308 | 3.21% | ±0.0129 (relative) | FAIL | FAIL |
| `eligible_mixed_room_blacks_table4_panelB_col3` | 0.152 (0.04) | 0.145329 | 4.39% | ±0.00304 (relative) | FAIL | FAIL |
| `performance_index_mixed_room_blacks_table4_panelB_col4` | 0.443 (0.141) | 0.420749 | 5.02% | ±0.00886 (relative) | FAIL | FAIL |
| `gpa_mixed_room_whites_table4_panelA_col1` | -0.028 (0.243) | -0.0352208 | 25.79% | ±0.00056 (relative) | FAIL | FAIL |
| `gpa_mixed_room_full_table4_panelC_col1` | 0.147 (0.102) | 0.149477 | 1.68% | ±0.00294 (relative) | PASS | FAIL |
| `exams_passed_mixed_room_full_table4_panelC_col2` | 0.447 (0.204) | 0.427174 | 4.44% | ±0.00894 (relative) | FAIL | PASS |
| `performance_index_mixed_room_full_table4_panelC_col4` | 0.289 (0.113) | 0.287006 | 0.69% | ±0.00578 (relative) | PASS | FAIL |
| `n_obs_table4_panelC_cols1_2` | 499 | 499 | 0.00% | ±24.95 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/13 pass, which agrees with the row's 7/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Table 4 regressions keep own private-school controls but drop roommate private-school controls (paper's control list is ambiguous; full and paper-stated sets bracket the reported values)

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 220,851 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 16,813 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 18,445 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 19,313 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 725 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 5,084 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 817 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 735 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 5,993 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 828 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/attempt-2/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/execution.json`
- [`output/script.R`](output/script.R) — 6,196 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,024 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/pipeline/20261110T221318Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,085 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/915dce1e7f1c973de7b74d1b.json`
- [`output/answer-2.md`](output/answer-2.md) — 5,994 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/80c5b8772923cec35bf0359c.json`
- [`output/answer-3.md`](output/answer-3.md) — 6,197 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/b3baee58c9ae190c727d257f.json`
- [`output/answer-4.md`](output/answer-4.md) — 6,197 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/71c79e9e1ec00b7b369b232a.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 13 |
| attempt-2 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 1.1 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 915dce1e7f1c973de7b74d1b: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request 80c5b8772923cec35bf0359c: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run2 (request b3baee58c9ae190c727d257f: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run2 (request 71c79e9e1ec00b7b369b232a: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 4 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
