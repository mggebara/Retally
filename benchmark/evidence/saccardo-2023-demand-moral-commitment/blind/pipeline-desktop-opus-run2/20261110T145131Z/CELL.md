# saccardo-2023-demand-moral-commitment · blind · pipeline-desktop-opus-run2 · 20261110T145131Z

| | |
|---|---|
| Paper | `saccardo-2023-demand-moral-commitment` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261110T145131Z |
| Date | 2026-11-10T14:51:31Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-saccardo-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T145131Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 4/13 |
| First scored | 4/13 (execution 1) |
| Final | **4/13** |
| Package files withheld | 4 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `see_incentive_first_costly_table2_col1` | -0.139 (0.018) | -0.146435 | 5.35% | ±0.018 (se_band) | PASS | PASS |
| `assess_quality_first_costly_table2_col1` | 0.152 (0.029) | 0.110101 | 27.57% | ±0.029 (se_band) | FAIL | FAIL |
| `choice_free_professionals_table2_col1` | -0.095 (0.026) | -0.037935 | 60.07% | ±0.026 (se_band) | FAIL | FAIL |
| `selfishness_table2_col2` | 0.028 (0.007) | 0.057662 | 105.94% | ±0.007 (se_band) | FAIL | FAIL |
| `selfishness_table2_col3` | 0.039 (0.009) | 0.078271 | 100.69% | ±0.009 (se_band) | FAIL | FAIL |
| `see_incentive_first_costly_x_selfishness_table2_col3` | -0.022 (0.016) | -0.045272 | 105.78% | ±0.016 (se_band) | FAIL | FAIL |
| `see_quality_first_costly_x_selfishness_table2_col3` | -0.021 (0.018) | -0.04218 | 100.86% | ±0.018 (se_band) | FAIL | FAIL |
| `n_obs_table2_col1` | 5908 | 6976 | 18.08% | ±295.4 (relative) | FAIL | FAIL |
| `n_obs_table2_cols2_3` | 5196 | 5588 | 7.54% | ±259.8 (relative) | FAIL | FAIL |
| `prefer_see_incentive_first_assigned_table3_col1` | 0.195 (0.016) | 0.186577 | 4.32% | ±0.016 (se_band) | PASS | PASS |
| `prefer_see_incentive_first_not_assigned_table3_col2` | 0.003 (0.029) | -0.006012 | 300.40% | ±0.029 (se_band) | PASS | PASS |
| `prefer_see_incentive_first_x_not_assigned_table3_col3` | -0.14 (0.026) | -0.13888 | 0.80% | ±0.026 (se_band) | PASS | PASS |
| `n_obs_table3_col1` | 4448 | 5243 | 17.87% | ±222.4 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 4/13 pass, which agrees with the row's 4/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 23,829 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T145131Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T145131Z/execution.json`
- [`output/script.R`](output/script.R) — 8,916 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T145131Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T145131Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 10,593 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/pipeline/20261110T145131Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,917 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/1cd1d765b653c814beaa3116.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 1.4 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 1cd1d765b653c814beaa3116: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
