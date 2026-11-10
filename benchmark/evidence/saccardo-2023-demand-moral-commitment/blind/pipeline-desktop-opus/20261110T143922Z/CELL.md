# saccardo-2023-demand-moral-commitment · blind · pipeline-desktop-opus · 20261110T143922Z

| | |
|---|---|
| Paper | `saccardo-2023-demand-moral-commitment` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261110T143922Z |
| Date | 2026-11-10T14:39:22Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-saccardo-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T143922Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 4/13 (execution 2) |
| Final | **4/13** |
| Package files withheld | 4 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `see_incentive_first_costly_table2_col1` | -0.139 (0.018) | -0.146593 | 5.46% | ±0.018 (se_band) | PASS | PASS |
| `assess_quality_first_costly_table2_col1` | 0.152 (0.029) | 0.110218 | 27.49% | ±0.029 (se_band) | FAIL | FAIL |
| `choice_free_professionals_table2_col1` | -0.095 (0.026) | -0.037807 | 60.20% | ±0.026 (se_band) | FAIL | FAIL |
| `selfishness_table2_col2` | 0.028 (0.007) | 0.057532 | 105.47% | ±0.007 (se_band) | FAIL | FAIL |
| `selfishness_table2_col3` | 0.039 (0.009) | 0.078184 | 100.47% | ±0.009 (se_band) | FAIL | FAIL |
| `see_incentive_first_costly_x_selfishness_table2_col3` | -0.022 (0.016) | -0.045376 | 106.25% | ±0.016 (se_band) | FAIL | FAIL |
| `see_quality_first_costly_x_selfishness_table2_col3` | -0.021 (0.018) | -0.04239 | 101.86% | ±0.018 (se_band) | FAIL | FAIL |
| `n_obs_table2_col1` | 5908 | 6965 | 17.89% | ±295.4 (relative) | FAIL | FAIL |
| `n_obs_table2_cols2_3` | 5196 | 5581 | 7.41% | ±259.8 (relative) | FAIL | FAIL |
| `prefer_see_incentive_first_assigned_table3_col1` | 0.195 (0.016) | 0.186804 | 4.20% | ±0.016 (se_band) | PASS | PASS |
| `prefer_see_incentive_first_not_assigned_table3_col2` | 0.003 (0.029) | -0.007785 | 359.50% | ±0.029 (se_band) | PASS | PASS |
| `prefer_see_incentive_first_x_not_assigned_table3_col3` | -0.14 (0.026) | -0.137848 | 1.54% | ±0.026 (se_band) | PASS | PASS |
| `n_obs_table3_col1` | 4448 | 5238 | 17.76% | ±222.4 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 4/13 pass, which agrees with the row's 4/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 23,829 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T143922Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 12,206 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T143922Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T143922Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 341 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T143922Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 6,989 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T143922Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 341 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T143922Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,946 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T143922Z/attempt-1/stdout.txt`
- [`output/execution.json`](output/execution.json) — 112 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T143922Z/execution.json`
- [`output/script.R`](output/script.R) — 7,948 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T143922Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,104 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T143922Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 11,166 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T143922Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,990 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/1cd1d765b653c814beaa3116.json`
- [`output/answer-2.md`](output/answer-2.md) — 7,949 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/0aa82347bbdc5fe991e6947b.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 1 | — | — | 0 |
| final | final | 0 | no | 1.4 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 1cd1d765b653c814beaa3116: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request 0aa82347bbdc5fe991e6947b: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
