# hollyer-2022-parties-as-disciplinarians · independent · pipeline-desktop-opus-run3 · 20261103T052626Z

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T052626Z |
| Date | 2026-11-03T05:26:26Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 11/13 |
| First scored | 11/13 (execution 1) |
| Final | **12/13** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `personalism_volatility_difference_overall` | 0.3 (0.06) | 0.300068 | 0.02% | ±0.06 (se_band) | PASS | FAIL |
| `programmaticness_volatility_difference_overall` | -0.11 (0.05) | -0.070871 | 35.57% | ±0.05 (se_band) | PASS | PASS |
| `personalism_volatility_difference_nonethnic` | 0.35 (0.06) | 0.350899 | 0.26% | ±0.06 (se_band) | PASS | FAIL |
| `programmaticness_volatility_difference_nonethnic` | -0.15 (0.06) | -0.092345 | 38.44% | ±0.06 (se_band) | PASS | PASS |
| `personalism_ethnic_minus_nonethnic_low_volatility` | 0.31 (0.13) | 0.411094 | 32.61% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_ethnic_minus_nonethnic_high_volatility` | 0.2 (0.06) | 0.150625 | 24.69% | ±0.06 (se_band) | PASS | PASS |
| `personalism_volatility_difference_moderate` | 0.53 (0.13) | 0.540969 | 2.07% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_moderate` | -0.3 (0.08) | -0.247327 | 17.56% | ±0.08 (se_band) | PASS | PASS |
| `personalism_extremist_minus_moderate_low_volatility` | 0.15 (0.17) | 0.096865 | 35.42% | ±0.17 (se_band) | PASS | PASS |
| `programmaticness_extremist_minus_moderate_high_volatility` | 0.44 (0.09) | 0.347105 | 21.11% | ±0.09 (se_band) | FAIL | PASS |
| `n_obs_table1` | 431 | 428 | 0.70% | ±21.55 (relative) | PASS | PASS |
| `rd_effect_young` | -0.084 | -0.08427 | 0.32% | ±0.00168 (relative) | PASS | PASS |
| `rd_effect_young_outsider` | -0.092 | -0.092132 | 0.14% | ±0.00184 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) 25th/75th volatility percentiles computed using convention 'country' (full = all DALP parties with volatility data; country = country-level distribution)
- (DEVIATION: line) Political-openness controls used: polity

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 16,324 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 15,849 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 18,231 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 19,172 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 202 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 5,823 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 758 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 202 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 7,417 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 861 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 124 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 7,716 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 975 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/attempt-3/stdout.txt`
- [`output/script.R`](output/script.R) — 9,020 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 975 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/pipeline/20261103T052626Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,824 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/176165b376bfc4f21517631f.json`
- [`output/answer-2.md`](output/answer-2.md) — 7,418 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/62e1a6a367e8fcaf972bb233.json`
- [`output/answer-3.md`](output/answer-3.md) — 7,717 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/f31c8ecb094c6986424b2a3d.json`
- [`output/answer-4.md`](output/answer-4.md) — 9,021 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/d89ae7a72bc325b0d09d223b.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 176165b376bfc4f21517631f: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request 62e1a6a367e8fcaf972bb233: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run3 (request f31c8ecb094c6986424b2a3d: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run3 (request d89ae7a72bc325b0d09d223b: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
