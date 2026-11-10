# balan-2022-local-elites-state-capacity · seeded · pipeline-desktop-opus-run3 · 20261110T230259Z

| | |
|---|---|
| Paper | `balan-2022-local-elites-state-capacity` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261110T230259Z |
| Date | 2026-11-10T23:02:59Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-1paper-balan-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 0/13 |
| First scored | 0/13 (execution 1) |
| Final | **6/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `compliance_local_table4_panelA_col1` | 0.023 (0.008) | 0.0248275 | 7.95% | ±0.0005 (printed_precision) | FAIL | FAIL |
| `compliance_local_table4_panelA_col2` | 0.032 (0.007) | 0.0322537 | 0.79% | ±0.00064 (relative) | PASS | FAIL |
| `compliance_local_house_fe_table4_panelA_col4` | 0.033 (0.007) | 0.0328538 | 0.44% | ±0.00066 (relative) | PASS | FAIL |
| `compliance_local_exempt_excluded_table4_panelA_col5` | 0.04 (0.008) | 0.0399076 | 0.23% | ±0.0008 (relative) | PASS | FAIL |
| `revenue_local_table4_panelB_col2` | 79.64 (22.856) | 72.2579 | 9.27% | ±1.5928 (relative) | FAIL | FAIL |
| `revenue_local_house_fe_table4_panelB_col4` | 68.855 (20.56) | 62.5635 | 9.14% | ±1.3771 (relative) | FAIL | FAIL |
| `n_obs_table4_col1` | 28872 | 29303 | 1.49% | ±1443.6 (relative) | PASS | FAIL |
| `n_obs_table4_col2` | 27764 | 27295 | 1.69% | ±1388.2 (relative) | PASS | FAIL |
| `paid_bribe_endline_local_table5_panelB` | 0.018 (0.009) | 0.0181901 | 1.06% | ±0.0005 (printed_precision) | PASS | FAIL |
| `visited_by_collector_local_table6_col1` | -0.009 (0.026) | -0.025144 | 179.38% | ±0.0005 (printed_precision) | FAIL | FAIL |
| `compliance_cli_table7_col1` | 0.024 (0.009) | 0.0206401 | 14.00% | ±0.0005 (printed_precision) | FAIL | FAIL |
| `revenue_cli_table7_col2` | 46.566 (21.2) | 38.5698 | 17.17% | ±0.93132 (relative) | FAIL | FAIL |
| `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 (0.007) | 0.0594192 | 6.11% | ±0.00112 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 6/13 pass, which agrees with the row's 6/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Payment amounts above the highest statutory rate (13,200 CF) are capped at 13,200 CF (implausible receipt amounts, max 1,662,800 CF, treated as entry errors)
- (DEVIATION: line) Revenue per property uses one payment record per property (duplicate receipts dropped, max amount per compound) instead of summing all payment rows
- (DEVIATION: line) For the Local vs Central comparison, registration dates a few days outside the outer time-window cut points are assigned to the nearest campaign-wave window rather than dropped (registration date used in place of the cleaned today_alt)

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 197,855 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 31,316 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 30,759 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 32,504 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 1,235 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 12,661 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 769 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,176 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 1,048 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 13,868 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 774 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,991 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 680 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 15,004 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 774 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 4,702 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/attempt-3/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/execution.json`
- [`output/script.R`](output/script.R) — 15,801 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 774 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,961 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T230259Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 12,662 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/48261e3e1626779174ed5e18.json`
- [`output/answer-2.md`](output/answer-2.md) — 13,869 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/edc68de885ffe781dfa0227e.json`
- [`output/answer-3.md`](output/answer-3.md) — 15,005 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/02ba0bf0e2d40bf719a1a4b9.json`
- [`output/answer-4.md`](output/answer-4.md) — 15,802 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/a9cb4e2cffb0e824935be938.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 13 |
| attempt-2 | claim | 0 | — | — | 13 |
| attempt-3 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 16.6 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 48261e3e1626779174ed5e18: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request edc68de885ffe781dfa0227e: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run3 (request 02ba0bf0e2d40bf719a1a4b9: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run3 (request a9cb4e2cffb0e824935be938: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 4 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
