# hollyer-2022-parties-as-disciplinarians · independent · pipeline-desktop-opus-postfix · 20261103T062157Z

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T062157Z |
| Date | 2026-11-03T06:21:57Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T062157Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 13/13 |
| First scored | 13/13 (execution 1) |
| Final | **13/13** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `personalism_volatility_difference_overall` | 0.3 (0.06) | 0.292232 | 2.59% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_overall` | -0.11 (0.05) | -0.115558 | 5.05% | ±0.05 (se_band) | PASS | PASS |
| `personalism_volatility_difference_nonethnic` | 0.35 (0.06) | 0.352372 | 0.68% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_nonethnic` | -0.15 (0.06) | -0.148855 | 0.76% | ±0.06 (se_band) | PASS | PASS |
| `personalism_ethnic_minus_nonethnic_low_volatility` | 0.31 (0.13) | 0.311271 | 0.41% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_ethnic_minus_nonethnic_high_volatility` | 0.2 (0.06) | 0.195941 | 2.03% | ±0.06 (se_band) | PASS | PASS |
| `personalism_volatility_difference_moderate` | 0.53 (0.13) | 0.530185 | 0.03% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_moderate` | -0.3 (0.08) | -0.298719 | 0.43% | ±0.08 (se_band) | PASS | PASS |
| `personalism_extremist_minus_moderate_low_volatility` | 0.15 (0.17) | 0.126349 | 15.77% | ±0.17 (se_band) | PASS | PASS |
| `programmaticness_extremist_minus_moderate_high_volatility` | 0.44 (0.09) | 0.371349 | 15.60% | ±0.09 (se_band) | PASS | PASS |
| `n_obs_table1` | 431 | 430 | 0.23% | ±21.55 (relative) | PASS | PASS |
| `rd_effect_young` | -0.084 | -0.08427 | 0.32% | ±0.00168 (relative) | PASS | PASS |
| `rd_effect_young_outsider` | -0.092 | -0.092132 | 0.14% | ±0.00184 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) complete-case sample has 430 parties, paper reports 431

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 19,145 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T062157Z/prompt-1.txt`

## What it produced

- [`output/samples.txt`](output/samples.txt) — 515 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T062157Z/samples.txt`
- [`output/script.R`](output/script.R) — 6,618 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T062157Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T062157Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,445 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T062157Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,619 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/f4b99c563a8f8ee4dbd88d8b.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request f4b99c563a8f8ee4dbd88d8b: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
