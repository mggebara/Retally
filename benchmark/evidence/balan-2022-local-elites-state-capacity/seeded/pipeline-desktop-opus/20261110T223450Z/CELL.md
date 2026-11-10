# balan-2022-local-elites-state-capacity · seeded · pipeline-desktop-opus · 20261110T223450Z

| | |
|---|---|
| Paper | `balan-2022-local-elites-state-capacity` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261110T223450Z |
| Date | 2026-11-10T22:34:50Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-balan-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 0/13 |
| First scored | 0/13 (execution 1) |
| Final | **4/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `compliance_local_table4_panelA_col1` | 0.023 (0.008) | 0.0248275 | 7.95% | ±0.0005 (printed_precision) | FAIL | FAIL |
| `compliance_local_table4_panelA_col2` | 0.032 (0.007) | 0.0409456 | 27.96% | ±0.00064 (relative) | FAIL | FAIL |
| `compliance_local_house_fe_table4_panelA_col4` | 0.033 (0.007) | 0.0416102 | 26.09% | ±0.00066 (relative) | FAIL | FAIL |
| `compliance_local_exempt_excluded_table4_panelA_col5` | 0.04 (0.008) | 0.0501931 | 25.48% | ±0.0008 (relative) | FAIL | FAIL |
| `revenue_local_table4_panelB_col2` | 79.64 (22.856) | 163.649 | 105.49% | ±1.5928 (relative) | FAIL | FAIL |
| `revenue_local_house_fe_table4_panelB_col4` | 68.855 (20.56) | 138.466 | 101.10% | ±1.3771 (relative) | FAIL | FAIL |
| `n_obs_table4_col1` | 28872 | 29303 | 1.49% | ±1443.6 (relative) | PASS | FAIL |
| `n_obs_table4_col2` | 27764 | 27226 | 1.94% | ±1388.2 (relative) | PASS | FAIL |
| `paid_bribe_endline_local_table5_panelB` | 0.018 (0.009) | 0.0181901 | 1.06% | ±0.0005 (printed_precision) | PASS | FAIL |
| `visited_by_collector_local_table6_col1` | -0.009 (0.026) | 0.0383682 | 526.31% | ±0.0005 (printed_precision) | FAIL | FAIL |
| `compliance_cli_table7_col1` | 0.024 (0.009) | 0.0237111 | 1.20% | ±0.0005 (printed_precision) | PASS | FAIL |
| `revenue_cli_table7_col2` | 46.566 (21.2) | 42.1274 | 9.53% | ±0.93132 (relative) | FAIL | FAIL |
| `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 (0.007) | 0.059412 | 6.09% | ±0.00112 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 4/13 pass, which agrees with the row's 4/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Missing or non-2018 registration dates replaced by the neighborhood median registration date when building wave FE (today_alt)
- (DEVIATION: line) Revenue per property uses one payment per property (max over duplicate receipt records) rather than summing duplicate records

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 197,855 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 35,136 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 36,335 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 39,209 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 1,260 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 16,434 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 769 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 23,242 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 1,079 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 17,308 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 774 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 23,663 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 1,077 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 19,537 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 774 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 24,321 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/attempt-3/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/execution.json`
- [`output/script.R`](output/script.R) — 20,779 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 774 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 25,092 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/pipeline/20261110T223450Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 16,435 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/48261e3e1626779174ed5e18.json`
- [`output/answer-2.md`](output/answer-2.md) — 17,309 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/3321c4bdb564f8ee0ad5da24.json`
- [`output/answer-3.md`](output/answer-3.md) — 19,538 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/1aa73176754acafeb3cfd57d.json`
- [`output/answer-4.md`](output/answer-4.md) — 20,780 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/0f04740edb4d8440b0416632.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 13 |
| attempt-2 | claim | 0 | — | — | 13 |
| attempt-3 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 18.1 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 48261e3e1626779174ed5e18: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request 3321c4bdb564f8ee0ad5da24: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus (request 1aa73176754acafeb3cfd57d: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus (request 0f04740edb4d8440b0416632: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 4 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
