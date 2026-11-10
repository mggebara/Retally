# balan-2022-local-elites-state-capacity · independent · pipeline-desktop-opus-run3 · 20261110T230259Z

| | |
|---|---|
| Paper | `balan-2022-local-elites-state-capacity` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261110T230259Z |
| Date | 2026-11-10T23:02:59Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-1paper-balan-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z` |
| Executions | 5 |
| Refinements | 4 (1 error + 3 claim) |
| First attempt | 0/13 |
| First scored | 5/13 (execution 2) |
| Final | **11/13** |
| Package files withheld | 58 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `compliance_local_table4_panelA_col1` | 0.023 (0.008) | 0.0219308 | 4.65% | ±0.008 (se_band) | PASS | PASS |
| `compliance_local_table4_panelA_col2` | 0.032 (0.007) | 0.0324448 | 1.39% | ±0.007 (se_band) | PASS | FAIL |
| `compliance_local_house_fe_table4_panelA_col4` | 0.033 (0.007) | 0.0330814 | 0.25% | ±0.007 (se_band) | PASS | FAIL |
| `compliance_local_exempt_excluded_table4_panelA_col5` | 0.04 (0.008) | 0.0398106 | 0.47% | ±0.008 (se_band) | PASS | FAIL |
| `revenue_local_table4_panelB_col2` | 79.64 (22.856) | 83.5903 | 4.96% | ±22.856 (se_band) | PASS | FAIL |
| `revenue_local_house_fe_table4_panelB_col4` | 68.855 (20.56) | 74.1141 | 7.64% | ±20.56 (se_band) | PASS | FAIL |
| `n_obs_table4_col1` | 28872 | 28714 | 0.55% | ±1443.6 (relative) | PASS | PASS |
| `n_obs_table4_col2` | 27764 | 28714 | 3.42% | ±1388.2 (relative) | PASS | FAIL |
| `paid_bribe_endline_local_table5_panelB` | 0.018 (0.009) | 0.0109048 | 39.42% | ±0.009 (se_band) | PASS | PASS |
| `visited_by_collector_local_table6_col1` | -0.009 (0.026) | -0.0057978 | 35.58% | ±0.026 (se_band) | PASS | PASS |
| `compliance_cli_table7_col1` | 0.024 (0.009) | 0.00341933 | 85.75% | ±0.009 (se_band) | FAIL | FAIL |
| `revenue_cli_table7_col2` | 46.566 (21.2) | -5.73555 | 112.32% | ±21.2 (se_band) | FAIL | FAIL |
| `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 (0.007) | 0.056242 | 0.43% | ±0.007 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/13 pass, which agrees with the row's 11/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Campaign start per neighborhood taken from earliest 2018 registration dates in the property register (program_start in the neighborhood file is 2016-dated and missing for many neighborhoods)
- (DEVIATION: line) 7 payer amounts that were missing, non-positive or above 15x the median payment were replaced by the median payment for that house type
- (DEVIATION: line) Time FE built as two-month campaign periods with neighborhoods starting outside the Local/Central overlap window pooled into the edge periods instead of being dropped (paper does not detail period construction)

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 24,542 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 39,662 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 32,196 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 34,752 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 38,795 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 22,930 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 14,868 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 22,930 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 774 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 15,036 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 6,073 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 539 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 722 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 16,713 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 5,809 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 914 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-3/stdout.txt`
- [`output/attempt-4/execution.json`](output/attempt-4/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-4/execution.json`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 190 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 20,504 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 7,100 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 1,260 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/attempt-4/stdout.txt`
- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/execution.json`
- [`output/script.R`](output/script.R) — 21,099 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 7,356 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,206 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T230259Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 14,869 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/815f206332cbfa10dfa87ef8.json`
- [`output/answer-2.md`](output/answer-2.md) — 15,037 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/5fbea9c14aca4a42cf4d9a5b.json`
- [`output/answer-3.md`](output/answer-3.md) — 16,714 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/a337a2da2f934263a929a250.json`
- [`output/answer-4.md`](output/answer-4.md) — 20,505 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/869f44e742796851386115a4.json`
- [`output/answer-5.md`](output/answer-5.md) — 21,100 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/57a96f4d9321a4dd9c992b80.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 0 | — | — | 0 |
| attempt-2 | claim | 0 | — | — | 10 |
| attempt-3 | claim | 0 | — | — | 13 |
| attempt-4 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 16.3 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 815f206332cbfa10dfa87ef8: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request 5fbea9c14aca4a42cf4d9a5b: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run3 (request a337a2da2f934263a929a250: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run3 (request 869f44e742796851386115a4: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus-run3 (request 57a96f4d9321a4dd9c992b80: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 5 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
