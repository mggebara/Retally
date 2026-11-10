# balan-2022-local-elites-state-capacity · independent · pipeline-desktop-opus · 20261110T222850Z

| | |
|---|---|
| Paper | `balan-2022-local-elites-state-capacity` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261110T222850Z |
| Date | 2026-11-10T22:28:50Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-balan-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 2/13 |
| First scored | 2/13 (execution 1) |
| Final | **13/13** |
| Package files withheld | 58 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `compliance_local_table4_panelA_col1` | 0.023 (0.008) | 0.024717 | 7.47% | ±0.008 (se_band) | PASS | FAIL |
| `compliance_local_table4_panelA_col2` | 0.032 (0.007) | 0.029261 | 8.56% | ±0.007 (se_band) | PASS | FAIL |
| `compliance_local_house_fe_table4_panelA_col4` | 0.033 (0.007) | 0.029894 | 9.41% | ±0.007 (se_band) | PASS | FAIL |
| `compliance_local_exempt_excluded_table4_panelA_col5` | 0.04 (0.008) | 0.036278 | 9.31% | ±0.008 (se_band) | PASS | FAIL |
| `revenue_local_table4_panelB_col2` | 79.64 (22.856) | 72.2422 | 9.29% | ±22.856 (se_band) | PASS | FAIL |
| `revenue_local_house_fe_table4_panelB_col4` | 68.855 (20.56) | 62.2332 | 9.62% | ±20.56 (se_band) | PASS | FAIL |
| `n_obs_table4_col1` | 28872 | 29274 | 1.39% | ±1443.6 (relative) | PASS | FAIL |
| `n_obs_table4_col2` | 27764 | 27264 | 1.80% | ±1388.2 (relative) | PASS | FAIL |
| `paid_bribe_endline_local_table5_panelB` | 0.018 (0.009) | 0.020075 | 11.53% | ±0.009 (se_band) | PASS | PASS |
| `visited_by_collector_local_table6_col1` | -0.009 (0.026) | 0.001024 | 111.38% | ±0.026 (se_band) | PASS | PASS |
| `compliance_cli_table7_col1` | 0.024 (0.009) | 0.024695 | 2.90% | ±0.009 (se_band) | PASS | FAIL |
| `revenue_cli_table7_col2` | 46.566 (21.2) | 45.3164 | 2.68% | ±21.2 (se_band) | PASS | FAIL |
| `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 (0.007) | 0.059271 | 5.84% | ±0.007 (se_band) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Payment amounts above the maximum statutory rate (13,200 CF) treated as data-entry errors and capped at 13,200 CF
- (DEVIATION: line) Revenue counts one payment per property (max amount across duplicate receipts) instead of summing all receipt rows
- (DEVIATION: line) Time fixed effects for Table 4 (cols 2,4,5) are the calendar month of each property's registration visit; properties without a dated registration record are dropped from these columns
- (DEVIATION: line) Time fixed effects built as two-month calendar periods of each neighborhood's median 2018 registration date, keeping only periods in which both compared arms operated (exact wave definition not given in the summary)

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 24,542 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 33,593 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 35,039 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 39,141 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 1,004 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 17,039 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 6,878 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 375 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 593 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 17,775 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 5,549 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,067 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 287 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 20,388 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 5,922 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 2,169 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/attempt-3/stdout.txt`
- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/execution.json`
- [`output/script.R`](output/script.R) — 22,435 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 5,912 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,487 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T222850Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 17,040 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/815f206332cbfa10dfa87ef8.json`
- [`output/answer-2.md`](output/answer-2.md) — 17,776 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/c211b1e28cde53717b24a413.json`
- [`output/answer-3.md`](output/answer-3.md) — 20,389 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/b8b26f7f55ad7f293e16298f.json`
- [`output/answer-4.md`](output/answer-4.md) — 22,436 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/dc1cb02f980842de6a7d2618.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 2 |
| attempt-2 | claim | 0 | — | — | 13 |
| attempt-3 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 16.7 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 815f206332cbfa10dfa87ef8: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request c211b1e28cde53717b24a413: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus (request b8b26f7f55ad7f293e16298f: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus (request dc1cb02f980842de6a7d2618: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
