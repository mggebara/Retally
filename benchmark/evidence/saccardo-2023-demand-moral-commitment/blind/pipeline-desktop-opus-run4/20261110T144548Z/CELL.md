# saccardo-2023-demand-moral-commitment · blind · pipeline-desktop-opus-run4 · 20261110T144548Z

| | |
|---|---|
| Paper | `saccardo-2023-demand-moral-commitment` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261110T144548Z |
| Date | 2026-11-10T14:45:48Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-1paper-saccardo-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T144548Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 5/13 |
| First scored | 5/13 (execution 1) |
| Final | **5/13** |
| Package files withheld | 4 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `see_incentive_first_costly_table2_col1` | -0.139 (0.018) | -0.145561 | 4.72% | ±0.018 (se_band) | PASS | PASS |
| `assess_quality_first_costly_table2_col1` | 0.152 (0.029) | 0.057978 | 61.86% | ±0.029 (se_band) | FAIL | FAIL |
| `choice_free_professionals_table2_col1` | -0.095 (0.026) | -0.088407 | 6.94% | ±0.026 (se_band) | PASS | PASS |
| `selfishness_table2_col2` | 0.028 (0.007) | 0.057789 | 106.39% | ±0.007 (se_band) | FAIL | FAIL |
| `selfishness_table2_col3` | 0.039 (0.009) | 0.078487 | 101.25% | ±0.009 (se_band) | FAIL | FAIL |
| `see_incentive_first_costly_x_selfishness_table2_col3` | -0.022 (0.016) | -0.045447 | 106.58% | ±0.016 (se_band) | FAIL | FAIL |
| `see_quality_first_costly_x_selfishness_table2_col3` | -0.021 (0.018) | -0.042427 | 102.03% | ±0.018 (se_band) | FAIL | FAIL |
| `n_obs_table2_col1` | 5908 | 6976 | 18.08% | ±295.4 (relative) | FAIL | FAIL |
| `n_obs_table2_cols2_3` | 5196 | 5588 | 7.54% | ±259.8 (relative) | FAIL | FAIL |
| `prefer_see_incentive_first_assigned_table3_col1` | 0.195 (0.016) | 0.185602 | 4.82% | ±0.016 (se_band) | PASS | PASS |
| `prefer_see_incentive_first_not_assigned_table3_col2` | 0.003 (0.029) | -0.006155 | 305.17% | ±0.029 (se_band) | PASS | PASS |
| `prefer_see_incentive_first_x_not_assigned_table3_col3` | -0.14 (0.026) | -0.138697 | 0.93% | ±0.026 (se_band) | PASS | PASS |
| `n_obs_table3_col1` | 4448 | 5243 | 17.87% | ±222.4 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 5/13 pass, which agrees with the row's 5/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 23,829 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T144548Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T144548Z/execution.json`
- [`output/script.R`](output/script.R) — 11,589 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T144548Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T144548Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 11,373 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T144548Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 11,590 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/1cd1d765b653c814beaa3116.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 1.4 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request 1cd1d765b653c814beaa3116: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
