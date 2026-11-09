# hollyer-2022-parties-as-disciplinarians · blind · pipeline-desktop-opus · 20261102T095147Z

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261102T095147Z |
| Date | 2026-11-02T09:51:47Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261102T095147Z` |
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
| `personalism_volatility_difference_overall` | 0.3 (0.06) | 0.269936 | 10.02% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_overall` | -0.11 (0.05) | -0.163086 | 48.26% | ±0.05 (se_band) | FAIL | FAIL |
| `personalism_volatility_difference_nonethnic` | 0.35 (0.06) | 0.33537 | 4.18% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_nonethnic` | -0.15 (0.06) | -0.218785 | 45.86% | ±0.06 (se_band) | FAIL | FAIL |
| `personalism_ethnic_minus_nonethnic_low_volatility` | 0.31 (0.13) | 0.350471 | 13.06% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_ethnic_minus_nonethnic_high_volatility` | 0.2 (0.06) | 0.114707 | 42.65% | ±0.06 (se_band) | FAIL | FAIL |
| `personalism_volatility_difference_moderate` | 0.53 (0.13) | 0.490568 | 7.44% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_moderate` | -0.3 (0.08) | -0.303582 | 1.19% | ±0.08 (se_band) | PASS | PASS |
| `personalism_extremist_minus_moderate_low_volatility` | 0.15 (0.17) | 0.10549 | 29.67% | ±0.17 (se_band) | PASS | PASS |
| `programmaticness_extremist_minus_moderate_high_volatility` | 0.44 (0.09) | 0.46521 | 5.73% | ±0.09 (se_band) | PASS | PASS |
| `n_obs_table1` | 431 | 428 | 0.70% | ±21.55 (relative) | PASS | PASS |
| `rd_effect_young` | -0.084 | -0.0842705 | 0.32% | ±0.00168 (relative) | PASS | PASS |
| `rd_effect_young_outsider` | -0.092 | -0.0921315 | 0.14% | ±0.00184 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/13 pass, which agrees with the row's 10/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 16,545 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261102T095147Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 5,713 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261102T095147Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 606 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261102T095147Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 800 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/pipeline/20261102T095147Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,714 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/a4ab5e34daf7b9e094d089bf.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request a4ab5e34daf7b9e094d089bf: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
