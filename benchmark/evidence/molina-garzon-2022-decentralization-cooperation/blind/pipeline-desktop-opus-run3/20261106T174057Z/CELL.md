# molina-garzon-2022-decentralization-cooperation · blind · pipeline-desktop-opus-run3 · 20261106T174057Z

| | |
|---|---|
| Paper | `molina-garzon-2022-decentralization-cooperation` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261106T174057Z |
| Date | 2026-11-06T17:40:57Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-1paper-all-modes-2026-11-06.json` |
| Artifacts | `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/blind/pipeline/20261106T174057Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 12/12 |
| First scored | 12/12 (execution 1) |
| Final | **12/12** |
| Package files withheld | 2 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `decentralized_table2_col1` | 0.83 (0.23) | 0.844014 | 1.69% | ±0.23 (se_band) | PASS | PASS |
| `communication_table2_col1` | 2.54 (0.21) | 2.5408 | 0.03% | ±0.21 (se_band) | PASS | PASS |
| `decentralized_table2_col2` | 0.41 (0.3) | 0.427787 | 4.34% | ±0.3 (se_band) | PASS | PASS |
| `communication_table2_col2` | 2.02 (0.32) | 2.02346 | 0.17% | ±0.32 (se_band) | PASS | PASS |
| `decentralized_x_communication_table2_col2` | 0.76 (0.38) | 0.761339 | 0.18% | ±0.38 (se_band) | PASS | PASS |
| `n_obs_table2` | 1980 | 1980 | 0.00% | ±99 (relative) | PASS | PASS |
| `decentralized_table3_allties_base` | 0.22 (0.12) | 0.192737 | 12.39% | ±0.12 (se_band) | PASS | PASS |
| `decentralized_table3_allties_full` | 0.24 (0.14) | 0.173629 | 27.65% | ±0.14 (se_band) | PASS | PASS |
| `decentralized_table3_strongties_base` | 0.61 (0.28) | 0.573736 | 5.94% | ±0.28 (se_band) | PASS | PASS |
| `decentralized_table3_strongties_full` | 1.07 (0.31) | 1.02888 | 3.84% | ±0.31 (se_band) | PASS | PASS |
| `n_obs_table3_base` | 231 | 231 | 0.00% | ±11.55 (relative) | PASS | PASS |
| `n_obs_table3_full` | 226 | 226 | 0.00% | ±11.3 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 15,725 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/blind/pipeline/20261106T174057Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/blind/pipeline/20261106T174057Z/execution.json`
- [`output/script.R`](output/script.R) — 10,822 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/blind/pipeline/20261106T174057Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/blind/pipeline/20261106T174057Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 8,674 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/blind/pipeline/20261106T174057Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,823 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/bb2a785fbaa7ce1db3c13f20.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 2.7 | 12 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request bb2a785fbaa7ce1db3c13f20: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
