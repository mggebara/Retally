# balan-2022-local-elites-state-capacity · independent · pipeline-desktop-opus-run4 · 20261110T230532Z

| | |
|---|---|
| Paper | `balan-2022-local-elites-state-capacity` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261110T230532Z |
| Date | 2026-11-10T23:05:32Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-1paper-balan-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z` |
| Executions | 5 |
| Refinements | 4 (1 error + 3 claim) |
| First attempt | 0/13 |
| First scored | 6/13 (execution 2) |
| Final | **6/13** |
| Package files withheld | 58 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `compliance_local_table4_panelA_col1` | 0.023 (0.008) | 0.021762 | 5.38% | ±0.008 (se_band) | PASS | PASS |
| `compliance_local_table4_panelA_col2` | 0.032 (0.007) | 0.021758 | 32.01% | ±0.007 (se_band) | FAIL | FAIL |
| `compliance_local_house_fe_table4_panelA_col4` | 0.033 (0.007) | 0.022072 | 33.12% | ±0.007 (se_band) | FAIL | FAIL |
| `compliance_local_exempt_excluded_table4_panelA_col5` | 0.04 (0.008) | 0.027619 | 30.95% | ±0.008 (se_band) | FAIL | FAIL |
| `revenue_local_table4_panelB_col2` | 79.64 (22.856) | 51.4005 | 35.46% | ±22.856 (se_band) | FAIL | FAIL |
| `revenue_local_house_fe_table4_panelB_col4` | 68.855 (20.56) | 45.7596 | 33.54% | ±20.56 (se_band) | FAIL | FAIL |
| `n_obs_table4_col1` | 28872 | 28673 | 0.69% | ±1443.6 (relative) | PASS | PASS |
| `n_obs_table4_col2` | 27764 | 28673 | 3.27% | ±1388.2 (relative) | PASS | FAIL |
| `paid_bribe_endline_local_table5_panelB` | 0.018 (0.009) | 0.010851 | 39.72% | ±0.009 (se_band) | PASS | PASS |
| `visited_by_collector_local_table6_col1` | -0.009 (0.026) | -0.018263 | 102.92% | ±0.026 (se_band) | PASS | PASS |
| `compliance_cli_table7_col1` | 0.024 (0.009) | -0.001694 | 107.06% | ±0.009 (se_band) | FAIL | FAIL |
| `revenue_cli_table7_col2` | 46.566 (21.2) | -14.3801 | 130.88% | ±21.2 (se_band) | FAIL | PASS |
| `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 (0.007) | 0.050073 | 10.58% | ±0.007 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 6/13 pass, which agrees with the row's 6/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Duplicate receipts dropped and receipt amounts (and per-property totals) capped at the top statutory rate of 13,200 CF to remove data-entry outliers
- (DEVIATION: line) Compliance and revenue rebuilt from 2018 receipt-printer records (tax_payments) matched by tax ID to the register
- (DEVIATION: line) Campaign-wave time FE built as two-month (or monthly) bins of each property's registration date with common support across arms

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 24,542 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 20,420 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 32,316 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 36,335 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 38,462 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 386 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 14,593 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 386 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 3,511 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 690 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 15,621 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 13,146 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 712 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 18,991 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 14,187 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-3/stdout.txt`
- [`output/attempt-4/execution.json`](output/attempt-4/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-4/execution.json`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 711 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 20,513 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 13,213 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/attempt-4/stdout.txt`
- [`output/execution.json`](output/execution.json) — 112 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/execution.json`
- [`output/script.R`](output/script.R) — 23,011 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 14,436 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230532Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 14,594 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/815f206332cbfa10dfa87ef8.json`
- [`output/answer-2.md`](output/answer-2.md) — 15,622 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/10bcb91e2496dd85d9f0ef1f.json`
- [`output/answer-3.md`](output/answer-3.md) — 18,992 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/4ac4b2376c6a057f5afcb99c.json`
- [`output/answer-4.md`](output/answer-4.md) — 20,514 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/739a0e42ac669d586f48ec9c.json`
- [`output/answer-5.md`](output/answer-5.md) — 23,012 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/51b2b7c825eb7ab6d3fb33fb.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 1 | — | — | 0 |
| attempt-2 | claim | 0 | — | — | 13 |
| attempt-3 | claim | 0 | — | — | 13 |
| attempt-4 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 16.3 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request 815f206332cbfa10dfa87ef8: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run4 (request 10bcb91e2496dd85d9f0ef1f: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run4 (request 4ac4b2376c6a057f5afcb99c: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run4 (request 739a0e42ac669d586f48ec9c: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus-run4 (request 51b2b7c825eb7ab6d3fb33fb: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 5 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
