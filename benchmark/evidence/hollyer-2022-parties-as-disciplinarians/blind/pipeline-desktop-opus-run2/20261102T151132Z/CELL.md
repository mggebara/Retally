# hollyer-2022-parties-as-disciplinarians · blind · pipeline-desktop-opus-run2 · 20261102T151132Z

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261102T151132Z |
| Date | 2026-11-02T15:11:32Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261102T151132Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 12/13 |
| First scored | 12/13 (execution 1) |
| Final | **12/13** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `personalism_volatility_difference_overall` | 0.3 (0.06) | 0.348361 | 16.12% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_overall` | -0.11 (0.05) | -0.101434 | 7.79% | ±0.05 (se_band) | PASS | PASS |
| `personalism_volatility_difference_nonethnic` | 0.35 (0.06) | 0.41266 | 17.90% | ±0.06 (se_band) | FAIL | FAIL |
| `programmaticness_volatility_difference_nonethnic` | -0.15 (0.06) | -0.135534 | 9.64% | ±0.06 (se_band) | PASS | PASS |
| `personalism_ethnic_minus_nonethnic_low_volatility` | 0.31 (0.13) | 0.428185 | 38.12% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_ethnic_minus_nonethnic_high_volatility` | 0.2 (0.06) | 0.217762 | 8.88% | ±0.06 (se_band) | PASS | PASS |
| `personalism_volatility_difference_moderate` | 0.53 (0.13) | 0.582354 | 9.88% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_moderate` | -0.3 (0.08) | -0.276021 | 7.99% | ±0.08 (se_band) | PASS | PASS |
| `personalism_extremist_minus_moderate_low_volatility` | 0.15 (0.17) | 0.104118 | 30.59% | ±0.17 (se_band) | PASS | PASS |
| `programmaticness_extremist_minus_moderate_high_volatility` | 0.44 (0.09) | 0.35364 | 19.63% | ±0.09 (se_band) | PASS | PASS |
| `n_obs_table1` | 431 | 428 | 0.70% | ±21.55 (relative) | PASS | PASS |
| `rd_effect_young` | -0.084 | -0.0842705 | 0.32% | ±0.00168 (relative) | PASS | PASS |
| `rd_effect_young_outsider` | -0.092 | -0.0921315 | 0.14% | ±0.00184 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 16,062 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261102T151132Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 4,902 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261102T151132Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261102T151132Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 800 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261102T151132Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 4,903 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/5393322f20ac68fab7182772.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 5393322f20ac68fab7182772: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
