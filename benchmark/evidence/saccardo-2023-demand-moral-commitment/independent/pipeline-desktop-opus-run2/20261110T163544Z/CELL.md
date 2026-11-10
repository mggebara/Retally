# saccardo-2023-demand-moral-commitment · independent · pipeline-desktop-opus-run2 · 20261110T163544Z

| | |
|---|---|
| Paper | `saccardo-2023-demand-moral-commitment` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261110T163544Z |
| Date | 2026-11-10T16:35:44Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-saccardo-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 4/13 |
| First scored | 4/13 (execution 1) |
| Final | **13/13** |
| Package files withheld | 4 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `see_incentive_first_costly_table2_col1` | -0.139 (0.018) | -0.137528 | 1.06% | ±0.018 (se_band) | PASS | PASS |
| `assess_quality_first_costly_table2_col1` | 0.152 (0.029) | 0.155549 | 2.33% | ±0.029 (se_band) | PASS | FAIL |
| `choice_free_professionals_table2_col1` | -0.095 (0.026) | -0.080962 | 14.78% | ±0.026 (se_band) | PASS | FAIL |
| `selfishness_table2_col2` | 0.028 (0.007) | 0.030849 | 10.18% | ±0.007 (se_band) | PASS | FAIL |
| `selfishness_table2_col3` | 0.039 (0.009) | 0.042486 | 8.94% | ±0.009 (se_band) | PASS | FAIL |
| `see_incentive_first_costly_x_selfishness_table2_col3` | -0.022 (0.016) | -0.024365 | 10.75% | ±0.016 (se_band) | PASS | FAIL |
| `see_quality_first_costly_x_selfishness_table2_col3` | -0.021 (0.018) | -0.021499 | 2.38% | ±0.018 (se_band) | PASS | FAIL |
| `n_obs_table2_col1` | 5908 | 5915 | 0.12% | ±295.4 (relative) | PASS | FAIL |
| `n_obs_table2_cols2_3` | 5196 | 5203 | 0.13% | ±259.8 (relative) | PASS | FAIL |
| `prefer_see_incentive_first_assigned_table3_col1` | 0.195 (0.016) | 0.200532 | 2.84% | ±0.016 (se_band) | PASS | PASS |
| `prefer_see_incentive_first_not_assigned_table3_col2` | 0.003 (0.029) | 0.012459 | 315.30% | ±0.029 (se_band) | PASS | PASS |
| `prefer_see_incentive_first_x_not_assigned_table3_col3` | -0.14 (0.026) | -0.140953 | 0.68% | ±0.026 (se_band) | PASS | PASS |
| `n_obs_table3_col1` | 4448 | 4450 | 0.04% | ±222.4 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Table 2 col 1 includes wave/sample fixed effects ( wave ) so costly arms are compared with Choice Free advisors from the same wave; not stated in the excerpt
- (DEVIATION: line) Selfishness measured as standardized continuous MPL value (alphavaluefinal), sign-oriented to agree with the binary selfish indicator, instead of the standardized 0/1 selfish dummy

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 24,078 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 25,238 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 22,566 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 23,033 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 837 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 7,938 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 10,049 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 517 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 5,776 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 5,521 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 107 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 6,228 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 5,849 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/attempt-3/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/execution.json`
- [`output/script.R`](output/script.R) — 7,615 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 8,699 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T163544Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,939 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/5d1e11eae709ef1a881593d5.json`
- [`output/answer-2.md`](output/answer-2.md) — 5,777 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/74ce8e68adada86be527d5f8.json`
- [`output/answer-3.md`](output/answer-3.md) — 6,229 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/d4def7e61978e98057dc4f81.json`
- [`output/answer-4.md`](output/answer-4.md) — 7,616 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/2e2e271413f82596048bf56d.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 13 |
| attempt-2 | claim | 0 | — | — | 13 |
| attempt-3 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 2.6 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 5d1e11eae709ef1a881593d5: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request 74ce8e68adada86be527d5f8: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run2 (request d4def7e61978e98057dc4f81: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run2 (request 2e2e271413f82596048bf56d: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
