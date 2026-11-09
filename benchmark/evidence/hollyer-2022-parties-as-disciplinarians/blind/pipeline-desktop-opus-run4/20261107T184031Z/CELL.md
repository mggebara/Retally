# hollyer-2022-parties-as-disciplinarians · blind · pipeline-desktop-opus-run4 · 20261107T184031Z

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261107T184031Z |
| Date | 2026-11-07T18:40:31Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261107T184031Z` |
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
| `personalism_volatility_difference_overall` | 0.3 (0.06) | 0.290579 | 3.14% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_overall` | -0.11 (0.05) | -0.121666 | 10.61% | ±0.05 (se_band) | PASS | PASS |
| `personalism_volatility_difference_nonethnic` | 0.35 (0.06) | 0.358559 | 2.45% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_nonethnic` | -0.15 (0.06) | -0.156064 | 4.04% | ±0.06 (se_band) | PASS | PASS |
| `personalism_ethnic_minus_nonethnic_low_volatility` | 0.31 (0.13) | 0.355842 | 14.79% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_ethnic_minus_nonethnic_high_volatility` | 0.2 (0.06) | 0.210101 | 5.05% | ±0.06 (se_band) | PASS | PASS |
| `personalism_volatility_difference_moderate` | 0.53 (0.13) | 0.519798 | 1.92% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_moderate` | -0.3 (0.08) | -0.303481 | 1.16% | ±0.08 (se_band) | PASS | PASS |
| `personalism_extremist_minus_moderate_low_volatility` | 0.15 (0.17) | 0.115881 | 22.75% | ±0.17 (se_band) | PASS | PASS |
| `programmaticness_extremist_minus_moderate_high_volatility` | 0.44 (0.09) | 0.364781 | 17.10% | ±0.09 (se_band) | PASS | PASS |
| `n_obs_table1` | 431 | 428 | 0.70% | ±21.55 (relative) | PASS | PASS |
| `rd_effect_young` | -0.084 | -0.08427 | 0.32% | ±0.00168 (relative) | PASS | PASS |
| `rd_effect_young_outsider` | -0.092 | -0.092132 | 0.14% | ±0.00184 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 16,545 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261107T184031Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 111 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261107T184031Z/execution.json`
- [`output/script.R`](output/script.R) — 5,555 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261107T184031Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261107T184031Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 15,800 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261107T184031Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,556 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/02d72fedd775e7460a86a245.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 9.2 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request 02d72fedd775e7460a86a245: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
