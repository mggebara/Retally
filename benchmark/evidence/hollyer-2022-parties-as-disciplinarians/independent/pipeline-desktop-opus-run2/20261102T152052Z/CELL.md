# hollyer-2022-parties-as-disciplinarians · independent · pipeline-desktop-opus-run2 · 20261102T152052Z

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261102T152052Z |
| Date | 2026-11-02T15:20:52Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T152052Z` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 10/13 |
| First scored | 10/13 (execution 1) |
| Final | **13/13** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `personalism_volatility_difference_overall` | 0.3 (0.06) | 0.283289 | 5.57% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_overall` | -0.11 (0.05) | -0.107242 | 2.51% | ±0.05 (se_band) | PASS | FAIL |
| `personalism_volatility_difference_nonethnic` | 0.35 (0.06) | 0.344765 | 1.50% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_nonethnic` | -0.15 (0.06) | -0.135652 | 9.57% | ±0.06 (se_band) | PASS | FAIL |
| `personalism_ethnic_minus_nonethnic_low_volatility` | 0.31 (0.13) | 0.346451 | 11.76% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_ethnic_minus_nonethnic_high_volatility` | 0.2 (0.06) | 0.198814 | 0.59% | ±0.06 (se_band) | PASS | FAIL |
| `personalism_volatility_difference_moderate` | 0.53 (0.13) | 0.515874 | 2.67% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_moderate` | -0.3 (0.08) | -0.294751 | 1.75% | ±0.08 (se_band) | PASS | PASS |
| `personalism_extremist_minus_moderate_low_volatility` | 0.15 (0.17) | 0.116474 | 22.35% | ±0.17 (se_band) | PASS | PASS |
| `programmaticness_extremist_minus_moderate_high_volatility` | 0.44 (0.09) | 0.370113 | 15.88% | ±0.09 (se_band) | PASS | PASS |
| `n_obs_table1` | 431 | 428 | 0.70% | ±21.55 (relative) | PASS | PASS |
| `rd_effect_young` | -0.084 | -0.08427 | 0.32% | ±0.00168 (relative) | PASS | PASS |
| `rd_effect_young_outsider` | -0.092 | -0.092132 | 0.14% | ±0.00184 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 16,431 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T152052Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 21,221 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T152052Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 322 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T152052Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 5,586 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T152052Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T152052Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 12,512 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T152052Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 5,642 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T152052Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T152052Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 12,596 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T152052Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,587 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/5776811b737996ab6ec77df9.json`
- [`output/answer-2.md`](output/answer-2.md) — 5,643 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/db01cf351c23f9ddaeece19d.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 5776811b737996ab6ec77df9: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request db01cf351c23f9ddaeece19d: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
