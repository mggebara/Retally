# balan-2022-local-elites-state-capacity · independent · pipeline-desktop-opus-run2 · 20261110T225449Z

| | |
|---|---|
| Paper | `balan-2022-local-elites-state-capacity` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261110T225449Z |
| Date | 2026-11-10T22:54:49Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-balan-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 5/13 |
| First scored | 5/13 (execution 1) |
| Final | **7/13** |
| Package files withheld | 58 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `compliance_local_table4_panelA_col1` | 0.023 (0.008) | 0.0217347 | 5.50% | ±0.008 (se_band) | PASS | PASS |
| `compliance_local_table4_panelA_col2` | 0.032 (0.007) | 0.0224547 | 29.83% | ±0.007 (se_band) | FAIL | FAIL |
| `compliance_local_house_fe_table4_panelA_col4` | 0.033 (0.007) | 0.022656 | 31.35% | ±0.007 (se_band) | FAIL | FAIL |
| `compliance_local_exempt_excluded_table4_panelA_col5` | 0.04 (0.008) | 0.0283862 | 29.03% | ±0.008 (se_band) | FAIL | FAIL |
| `revenue_local_table4_panelB_col2` | 79.64 (22.856) | 52.2938 | 34.34% | ±22.856 (se_band) | FAIL | FAIL |
| `revenue_local_house_fe_table4_panelB_col4` | 68.855 (20.56) | 48.3959 | 29.71% | ±20.56 (se_band) | PASS | FAIL |
| `n_obs_table4_col1` | 28872 | 28673 | 0.69% | ±1443.6 (relative) | PASS | PASS |
| `n_obs_table4_col2` | 27764 | 28673 | 3.27% | ±1388.2 (relative) | PASS | FAIL |
| `paid_bribe_endline_local_table5_panelB` | 0.018 (0.009) | 0.0109048 | 39.42% | ±0.009 (se_band) | PASS | FAIL |
| `visited_by_collector_local_table6_col1` | -0.009 (0.026) | -0.0026762 | 70.26% | ±0.026 (se_band) | PASS | PASS |
| `compliance_cli_table7_col1` | 0.024 (0.009) | -0.000286611 | 101.19% | ±0.009 (se_band) | FAIL | FAIL |
| `revenue_cli_table7_col2` | 46.566 (21.2) | -10.7073 | 122.99% | ±21.2 (se_band) | FAIL | PASS |
| `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 (0.007) | 0.0560226 | 0.04% | ±0.007 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/13 pass, which agrees with the row's 7/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Per-property payment amounts winsorized at the 99th percentile of payers (13200 CF; 2 properties) to remove implausible receipt amounts that inflated revenue far above the statutory rates
- (DEVIATION: line) 88 Local/Central neighborhoods with no recoverable campaign start date kept with their own campaign-wave FE level instead of being dropped
- (DEVIATION: line) 77 CLI/Central neighborhoods with no recoverable campaign start date kept with their own campaign-wave FE level instead of being dropped
- (DEVIATION: line) Endline file survey_data/endline_round2_noPII.dta dropped from the bribe outcome: its only bribe items (bribe_freq,bribe_amt1) give an implausible bribe-payment rate of 0.69, so they do not measure whether a bribe was paid

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 24,542 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 32,190 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 36,239 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 43,518 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 810 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 14,612 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 520 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 12,067 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 834 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 17,959 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 525 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 16,097 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 1,128 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 24,013 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 528 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 14,392 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/attempt-3/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/execution.json`
- [`output/script.R`](output/script.R) — 25,086 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 533 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 14,815 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/pipeline/20261110T225449Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 14,613 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/815f206332cbfa10dfa87ef8.json`
- [`output/answer-2.md`](output/answer-2.md) — 17,960 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/c821c92ccec3c3e4b7ed1f32.json`
- [`output/answer-3.md`](output/answer-3.md) — 24,014 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/d1d5f29e9b5b2a3daca649fa.json`
- [`output/answer-4.md`](output/answer-4.md) — 25,087 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/911b52c8ca51c110404d3446.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 13 |
| attempt-2 | claim | 0 | — | — | 13 |
| attempt-3 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 17.3 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 815f206332cbfa10dfa87ef8: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request c821c92ccec3c3e4b7ed1f32: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run2 (request d1d5f29e9b5b2a3daca649fa: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run2 (request 911b52c8ca51c110404d3446: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
