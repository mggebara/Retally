# hollyer-2022-parties-as-disciplinarians · independent · pipeline-desktop-opus-run4 · 20261108T083700Z

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261108T083700Z |
| Date | 2026-11-08T08:37:00Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 12/13 |
| First scored | 12/13 (execution 1) |
| Final | **12/13** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `personalism_volatility_difference_overall` | 0.3 (0.06) | 0.265465 | 11.51% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_overall` | -0.11 (0.05) | -0.15139 | 37.63% | ±0.05 (se_band) | PASS | PASS |
| `personalism_volatility_difference_nonethnic` | 0.35 (0.06) | 0.317005 | 9.43% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_nonethnic` | -0.15 (0.06) | -0.204731 | 36.49% | ±0.06 (se_band) | PASS | PASS |
| `personalism_ethnic_minus_nonethnic_low_volatility` | 0.31 (0.13) | 0.360024 | 16.14% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_ethnic_minus_nonethnic_high_volatility` | 0.2 (0.06) | 0.127561 | 36.22% | ±0.06 (se_band) | FAIL | FAIL |
| `personalism_volatility_difference_moderate` | 0.53 (0.13) | 0.494701 | 6.66% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_moderate` | -0.3 (0.08) | -0.304729 | 1.58% | ±0.08 (se_band) | PASS | PASS |
| `personalism_extremist_minus_moderate_low_volatility` | 0.15 (0.17) | 0.104543 | 30.30% | ±0.17 (se_band) | PASS | PASS |
| `programmaticness_extremist_minus_moderate_high_volatility` | 0.44 (0.09) | 0.468753 | 6.53% | ±0.09 (se_band) | PASS | PASS |
| `n_obs_table1` | 431 | 429 | 0.46% | ±21.55 (relative) | PASS | PASS |
| `rd_effect_young` | -0.084 | -0.08427 | 0.32% | ±0.00168 (relative) | PASS | PASS |
| `rd_effect_young_outsider` | -0.092 | -0.092132 | 0.14% | ±0.00184 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Ballot-rule control (erule, 7 codes) entered as a set of category dummies; the paper does not state its exact coding
- (DEVIATION: line) Low/high volatility set at the 25th/75th percentiles of the country-level volatility distribution (one value per country) rather than across party observations

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 16,275 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 18,198 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 18,935 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 20,220 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 105 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 5,800 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 606 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,670 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 321 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 5,993 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,821 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 105 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 6,260 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 606 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 2,864 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/attempt-3/stdout.txt`
- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/execution.json`
- [`output/script.R`](output/script.R) — 6,622 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 606 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,035 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261108T083700Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,801 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/6383c56820455a55eb838fa5.json`
- [`output/answer-2.md`](output/answer-2.md) — 5,994 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/8dd981fbb97276834ebdbeae.json`
- [`output/answer-3.md`](output/answer-3.md) — 6,261 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/a414945a456cd1d0a9ee6508.json`
- [`output/answer-4.md`](output/answer-4.md) — 6,623 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/abdb6e4f4fd7a3fec7893adb.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 13 |
| attempt-2 | claim | 0 | — | — | 13 |
| attempt-3 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 4.3 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request 6383c56820455a55eb838fa5: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run4 (request 8dd981fbb97276834ebdbeae: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run4 (request a414945a456cd1d0a9ee6508: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run4 (request abdb6e4f4fd7a3fec7893adb: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
