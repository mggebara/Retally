# hollyer-2022-parties-as-disciplinarians · independent · pipeline-desktop-opus · 20261102T141403Z

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261102T141403Z |
| Date | 2026-11-02T14:14:03Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T141403Z` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 11/13 |
| First scored | 11/13 (execution 1) |
| Final | **13/13** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `personalism_volatility_difference_overall` | 0.3 (0.06) | 0.295219 | 1.59% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_overall` | -0.11 (0.05) | -0.117809 | 7.10% | ±0.05 (se_band) | PASS | FAIL |
| `personalism_volatility_difference_nonethnic` | 0.35 (0.06) | 0.360174 | 2.91% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_nonethnic` | -0.15 (0.06) | -0.155346 | 3.56% | ±0.06 (se_band) | PASS | FAIL |
| `personalism_ethnic_minus_nonethnic_low_volatility` | 0.31 (0.13) | 0.348073 | 12.28% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_ethnic_minus_nonethnic_high_volatility` | 0.2 (0.06) | 0.217003 | 8.50% | ±0.06 (se_band) | PASS | PASS |
| `personalism_volatility_difference_moderate` | 0.53 (0.13) | 0.519798 | 1.92% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_moderate` | -0.3 (0.08) | -0.303481 | 1.16% | ±0.08 (se_band) | PASS | PASS |
| `personalism_extremist_minus_moderate_low_volatility` | 0.15 (0.17) | 0.115881 | 22.75% | ±0.17 (se_band) | PASS | PASS |
| `programmaticness_extremist_minus_moderate_high_volatility` | 0.44 (0.09) | 0.364781 | 17.10% | ±0.09 (se_band) | PASS | PASS |
| `n_obs_table1` | 431 | 429 | 0.46% | ±21.55 (relative) | PASS | PASS |
| `rd_effect_young` | -0.084 | -0.08427 | 0.32% | ±0.00168 (relative) | PASS | PASS |
| `rd_effect_young_outsider` | -0.092 | -0.092132 | 0.14% | ±0.00184 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 16,275 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T141403Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 15,781 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T141403Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 216 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T141403Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 5,593 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T141403Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 118 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T141403Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 758 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T141403Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 5,591 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T141403Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 118 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T141403Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 758 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261102T141403Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,594 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/e12cc72fe039af5b8226a543.json`
- [`output/answer-2.md`](output/answer-2.md) — 5,592 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/bbf2f5e54038adae2420d571.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request e12cc72fe039af5b8226a543: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request bbf2f5e54038adae2420d571: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
