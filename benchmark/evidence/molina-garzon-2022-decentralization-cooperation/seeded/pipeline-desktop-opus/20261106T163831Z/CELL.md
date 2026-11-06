# molina-garzon-2022-decentralization-cooperation · seeded · pipeline-desktop-opus · 20261106T163831Z

| | |
|---|---|
| Paper | `molina-garzon-2022-decentralization-cooperation` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261106T163831Z |
| Date | 2026-11-06T16:38:31Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-all-modes-2026-11-06.json` |
| Artifacts | `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/seeded/pipeline/20261106T163831Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 12/12 |
| First scored | 12/12 (execution 1) |
| Final | **12/12** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `decentralized_table2_col1` | 0.83 (0.23) | 0.82582 | 0.50% | ±0.0166 (relative) | PASS | PASS |
| `communication_table2_col1` | 2.54 (0.21) | 2.54073 | 0.03% | ±0.0508 (relative) | PASS | PASS |
| `decentralized_table2_col2` | 0.41 (0.3) | 0.409236 | 0.19% | ±0.0082 (relative) | PASS | PASS |
| `communication_table2_col2` | 2.02 (0.32) | 2.02311 | 0.15% | ±0.0404 (relative) | PASS | PASS |
| `decentralized_x_communication_table2_col2` | 0.76 (0.38) | 0.761756 | 0.23% | ±0.0152 (relative) | PASS | PASS |
| `n_obs_table2` | 1980 | 1980 | 0.00% | ±99 (relative) | PASS | PASS |
| `decentralized_table3_allties_base` | 0.22 (0.12) | 0.217647 | 1.07% | ±0.005 (printed_precision) | PASS | PASS |
| `decentralized_table3_allties_full` | 0.24 (0.14) | 0.239524 | 0.20% | ±0.005 (printed_precision) | PASS | PASS |
| `decentralized_table3_strongties_base` | 0.61 (0.28) | 0.607208 | 0.46% | ±0.0122 (relative) | PASS | PASS |
| `decentralized_table3_strongties_full` | 1.07 (0.31) | 1.07411 | 0.38% | ±0.0214 (relative) | PASS | PASS |
| `n_obs_table3_base` | 231 | 231 | 0.00% | ±11.55 (relative) | PASS | PASS |
| `n_obs_table3_full` | 226 | 226 | 0.00% | ±11.3 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 65,074 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/seeded/pipeline/20261106T163831Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/seeded/pipeline/20261106T163831Z/execution.json`
- [`output/script.R`](output/script.R) — 5,159 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/seeded/pipeline/20261106T163831Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/seeded/pipeline/20261106T163831Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 546 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/seeded/pipeline/20261106T163831Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,160 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/eb2cb9c79b6b19f8d307eedf.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 2.7 | 12 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request eb2cb9c79b6b19f8d307eedf: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 1 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
