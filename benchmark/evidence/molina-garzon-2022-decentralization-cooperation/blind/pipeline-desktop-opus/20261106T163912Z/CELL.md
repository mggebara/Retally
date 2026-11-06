# molina-garzon-2022-decentralization-cooperation · blind · pipeline-desktop-opus · 20261106T163912Z

| | |
|---|---|
| Paper | `molina-garzon-2022-decentralization-cooperation` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261106T163912Z |
| Date | 2026-11-06T16:39:12Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-all-modes-2026-11-06.json` |
| Artifacts | `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/blind/pipeline/20261106T163912Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 6/12 |
| First scored | 6/12 (execution 1) |
| Final | **6/12** |
| Package files withheld | 2 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `decentralized_table2_col1` | 0.83 (0.23) | 0.781731 | 5.82% | ±0.23 (se_band) | PASS | PASS |
| `communication_table2_col1` | 2.54 (0.21) | 2.54116 | 0.05% | ±0.21 (se_band) | PASS | PASS |
| `decentralized_table2_col2` | 0.41 (0.3) | 0.366411 | 10.63% | ±0.3 (se_band) | PASS | PASS |
| `communication_table2_col2` | 2.02 (0.32) | 2.02535 | 0.26% | ±0.32 (se_band) | PASS | PASS |
| `decentralized_x_communication_table2_col2` | 0.76 (0.38) | 0.759098 | 0.12% | ±0.38 (se_band) | PASS | PASS |
| `n_obs_table2` | 1980 | 1980 | 0.00% | ±99 (relative) | PASS | PASS |
| `decentralized_table3_allties_base` | 0.22 (0.12) | — | — | ±0.12 (se_band) | FAIL | FAIL |
| `decentralized_table3_allties_full` | 0.24 (0.14) | — | — | ±0.14 (se_band) | FAIL | FAIL |
| `decentralized_table3_strongties_base` | 0.61 (0.28) | — | — | ±0.28 (se_band) | FAIL | FAIL |
| `decentralized_table3_strongties_full` | 1.07 (0.31) | — | — | ±0.31 (se_band) | FAIL | FAIL |
| `n_obs_table3_base` | 231 | — | — | ±11.55 (relative) | FAIL | FAIL |
| `n_obs_table3_full` | 226 | — | — | ±11.3 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 6/12 pass, which agrees with the row's 6/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 15,725 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/blind/pipeline/20261106T163912Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/blind/pipeline/20261106T163912Z/execution.json`
- [`output/script.R`](output/script.R) — 10,511 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/blind/pipeline/20261106T163912Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/blind/pipeline/20261106T163912Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 5,489 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/blind/pipeline/20261106T163912Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,512 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/bb2a785fbaa7ce1db3c13f20.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 1.2 | 6 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request bb2a785fbaa7ce1db3c13f20: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
