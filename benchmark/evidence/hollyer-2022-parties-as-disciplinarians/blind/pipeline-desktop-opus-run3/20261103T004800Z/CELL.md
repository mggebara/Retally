# hollyer-2022-parties-as-disciplinarians · blind · pipeline-desktop-opus-run3 · 20261103T004800Z

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T004800Z |
| Date | 2026-11-03T00:48:00Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261103T004800Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 10/13 |
| First scored | 10/13 (execution 1) |
| Final | **10/13** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `personalism_volatility_difference_overall` | 0.3 (0.06) | 0.29349 | 2.17% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_overall` | -0.11 (0.05) | -0.175374 | 59.43% | ±0.05 (se_band) | FAIL | FAIL |
| `personalism_volatility_difference_nonethnic` | 0.35 (0.06) | 0.357031 | 2.01% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_nonethnic` | -0.15 (0.06) | -0.237115 | 58.08% | ±0.06 (se_band) | FAIL | FAIL |
| `personalism_ethnic_minus_nonethnic_low_volatility` | 0.31 (0.13) | 0.352066 | 13.57% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_ethnic_minus_nonethnic_high_volatility` | 0.2 (0.06) | 0.137021 | 31.49% | ±0.06 (se_band) | FAIL | FAIL |
| `personalism_volatility_difference_moderate` | 0.53 (0.13) | 0.517816 | 2.30% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_moderate` | -0.3 (0.08) | -0.33133 | 10.44% | ±0.08 (se_band) | PASS | PASS |
| `personalism_extremist_minus_moderate_low_volatility` | 0.15 (0.17) | 0.114501 | 23.67% | ±0.17 (se_band) | PASS | PASS |
| `programmaticness_extremist_minus_moderate_high_volatility` | 0.44 (0.09) | 0.474755 | 7.90% | ±0.09 (se_band) | PASS | PASS |
| `n_obs_table1` | 431 | 429 | 0.46% | ±21.55 (relative) | PASS | PASS |
| `rd_effect_young` | -0.084 | -0.08427 | 0.32% | ±0.00168 (relative) | PASS | PASS |
| `rd_effect_young_outsider` | -0.092 | -0.092132 | 0.14% | ±0.00184 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/13 pass, which agrees with the row's 10/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 16,587 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261103T004800Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 4,274 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261103T004800Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261103T004800Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 758 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261103T004800Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 4,275 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/95ac4f3e984a4a1641fc7b26.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 95ac4f3e984a4a1641fc7b26: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
