# saccardo-2023-demand-moral-commitment · seeded · pipeline-desktop-opus-run2 · 20261110T145131Z

| | |
|---|---|
| Paper | `saccardo-2023-demand-moral-commitment` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261110T145131Z |
| Date | 2026-11-10T14:51:31Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-saccardo-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/seeded/pipeline/20261110T145131Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 13/13 |
| First scored | 13/13 (execution 1) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `see_incentive_first_costly_table2_col1` | -0.139 (0.018) | -0.139343 | 0.25% | ±0.00278 (relative) | PASS | PASS |
| `assess_quality_first_costly_table2_col1` | 0.152 (0.029) | 0.151746 | 0.17% | ±0.00304 (relative) | PASS | PASS |
| `choice_free_professionals_table2_col1` | -0.095 (0.026) | -0.0952064 | 0.22% | ±0.0019 (relative) | PASS | PASS |
| `selfishness_table2_col2` | 0.028 (0.007) | 0.0281949 | 0.70% | ±0.00056 (relative) | PASS | PASS |
| `selfishness_table2_col3` | 0.039 (0.009) | 0.0391652 | 0.42% | ±0.00078 (relative) | PASS | PASS |
| `see_incentive_first_costly_x_selfishness_table2_col3` | -0.022 (0.016) | -0.0223933 | 1.79% | ±0.0005 (printed_precision) | PASS | PASS |
| `see_quality_first_costly_x_selfishness_table2_col3` | -0.021 (0.018) | -0.0211398 | 0.67% | ±0.0005 (printed_precision) | PASS | PASS |
| `n_obs_table2_col1` | 5908 | 5908 | 0.00% | ±295.4 (relative) | PASS | PASS |
| `n_obs_table2_cols2_3` | 5196 | 5196 | 0.00% | ±259.8 (relative) | PASS | PASS |
| `prefer_see_incentive_first_assigned_table3_col1` | 0.195 (0.016) | 0.195469 | 0.24% | ±0.0039 (relative) | PASS | PASS |
| `prefer_see_incentive_first_not_assigned_table3_col2` | 0.003 (0.029) | 0.0029917 | 0.28% | ±0.0005 (printed_precision) | PASS | PASS |
| `prefer_see_incentive_first_x_not_assigned_table3_col3` | -0.14 (0.026) | -0.140218 | 0.16% | ±0.0028 (relative) | PASS | PASS |
| `n_obs_table3_col1` | 4448 | 4448 | 0.00% | ±222.4 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 146,965 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/seeded/pipeline/20261110T145131Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/seeded/pipeline/20261110T145131Z/execution.json`
- [`output/script.R`](output/script.R) — 5,056 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/seeded/pipeline/20261110T145131Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/seeded/pipeline/20261110T145131Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 727 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/seeded/pipeline/20261110T145131Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,057 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/eac175981ca06b6117ce0842.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 1.3 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request eac175981ca06b6117ce0842: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 1 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
