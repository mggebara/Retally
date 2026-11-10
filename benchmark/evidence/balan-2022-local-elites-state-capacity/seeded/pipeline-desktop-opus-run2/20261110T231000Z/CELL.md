# balan-2022-local-elites-state-capacity · seeded · pipeline-desktop-opus-run2 · 20261110T231000Z

| | |
|---|---|
| Paper | `balan-2022-local-elites-state-capacity` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261110T231000Z |
| Date | 2026-11-10T23:10:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-balan-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 0/13 |
| First scored | 0/13 (execution 1) |
| Final | **3/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `compliance_local_table4_panelA_col1` | 0.023 (0.008) | 0.0133403 | 42.00% | ±0.0005 (printed_precision) | FAIL | FAIL |
| `compliance_local_table4_panelA_col2` | 0.032 (0.007) | 0.0225879 | 29.41% | ±0.00064 (relative) | FAIL | FAIL |
| `compliance_local_house_fe_table4_panelA_col4` | 0.033 (0.007) | 0.0232863 | 29.44% | ±0.00066 (relative) | FAIL | FAIL |
| `compliance_local_exempt_excluded_table4_panelA_col5` | 0.04 (0.008) | 0.0281786 | 29.55% | ±0.0008 (relative) | FAIL | FAIL |
| `revenue_local_table4_panelB_col2` | 79.64 (22.856) | 115.158 | 44.60% | ±1.5928 (relative) | FAIL | FAIL |
| `revenue_local_house_fe_table4_panelB_col4` | 68.855 (20.56) | 89.9966 | 30.70% | ±1.3771 (relative) | FAIL | FAIL |
| `n_obs_table4_col1` | 28872 | 29303 | 1.49% | ±1443.6 (relative) | PASS | FAIL |
| `n_obs_table4_col2` | 27764 | 29303 | 5.54% | ±1388.2 (relative) | FAIL | FAIL |
| `paid_bribe_endline_local_table5_panelB` | 0.018 (0.009) | 0.0181901 | 1.06% | ±0.0005 (printed_precision) | PASS | FAIL |
| `visited_by_collector_local_table6_col1` | -0.009 (0.026) | 0.00835113 | 192.79% | ±0.0005 (printed_precision) | FAIL | FAIL |
| `compliance_cli_table7_col1` | 0.024 (0.009) | 0.00867444 | 63.86% | ±0.0005 (printed_precision) | FAIL | FAIL |
| `revenue_cli_table7_col2` | 46.566 (21.2) | 6.0165 | 87.08% | ±0.93132 (relative) | FAIL | FAIL |
| `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 (0.007) | 0.0560206 | 0.04% | ±0.00112 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 3/13 pass, which agrees with the row's 3/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Dropped duplicate receipts and late-collection payments and counted one payment (max amount) per property, since summed amounts double-counted revenue
- (DEVIATION: line) Campaign-wave FE built from property-level registration date (alternate date fields, then neighborhood median, where missing)
- (DEVIATION: line) Campaign-wave bins made open-ended at the first and last wave so early/late registration dates are not dropped

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 197,855 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 31,078 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 34,869 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 37,741 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 1,238 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 15,389 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 535 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 3,616 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 1,078 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 17,706 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 774 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 4,313 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 968 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 18,957 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 774 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 5,526 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/attempt-3/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/execution.json`
- [`output/script.R`](output/script.R) — 22,195 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 206 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 6,278 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T231000Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 15,390 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/48261e3e1626779174ed5e18.json`
- [`output/answer-2.md`](output/answer-2.md) — 17,707 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/9434408b78bbc4313a0de44e.json`
- [`output/answer-3.md`](output/answer-3.md) — 18,958 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/0cf76b3ed4eb3d6109acc92c.json`
- [`output/answer-4.md`](output/answer-4.md) — 22,196 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/c333035bb207ba41d9273e09.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 10 |
| attempt-2 | claim | 0 | — | — | 13 |
| attempt-3 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 14.9 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 48261e3e1626779174ed5e18: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request 9434408b78bbc4313a0de44e: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run2 (request 0cf76b3ed4eb3d6109acc92c: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run2 (request c333035bb207ba41d9273e09: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 4 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
