# montero-2022-cooperative-property-rights · independent · pipeline-desktop-opus-run3 · 20261103T054754Z

| | |
|---|---|
| Paper | `montero-2022-cooperative-property-rights` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T054754Z |
| Date | 2026-11-03T05:47:54Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z` |
| Executions | 5 |
| Refinements | 4 (1 error + 3 claim) |
| First attempt | 0/10 |
| First scored | 0/10 (execution 2) |
| Final | **10/10** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `earnings_level_above500_bw300` | 60.49 (31.03) | 82.545 | 36.46% | ±31.03 (se_band) | PASS | FAIL |
| `earnings_level_above500_bw150` | 52.79 (40.61) | 72.1809 | 36.73% | ±40.61 (se_band) | PASS | FAIL |
| `earnings_iqr_above500_bw300` | -42.97 (17.82) | -54.8037 | 27.54% | ±17.82 (se_band) | PASS | FAIL |
| `earnings_iqr_above500_bw150` | -51.79 (24.79) | -63.2275 | 22.08% | ±24.79 (se_band) | PASS | FAIL |
| `n_obs_earnings_level_bw300` | 4770 | 4781 | 0.23% | ±238.5 (relative) | PASS | FAIL |
| `n_obs_earnings_level_bw150` | 1583 | 1583 | 0.00% | ±79.15 (relative) | PASS | FAIL |
| `n_obs_earnings_iqr_bw300` | 327 | 332 | 1.53% | ±16.35 (relative) | PASS | FAIL |
| `n_obs_earnings_iqr_bw150` | 118 | 118 | 0.00% | ±5.9 (relative) | PASS | FAIL |
| `n_clusters_bw300` | 98 | 99 | 1.02% | ±4.9 (relative) | PASS | FAIL |
| `n_clusters_bw150` | 36 | 36 | 0.00% | ±1.8 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/10 pass, which agrees with the row's 10/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) IQR computed at the property x survey-wave x interview-year level, keeping all cells (Stata collapse-style percentiles, IQR=0 for single-worker cells) since the paper's IQR unit (327 properties at bw300) exceeds the number of distinct properties and of property x survey-year cells

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 12,645 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 12,053 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 21,807 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 15,914 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 16,293 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 129 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 6,476 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 129 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 3,515 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 837 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 6,614 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 5,810 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 407 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 4,429 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 2,545 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/attempt-3/stdout.txt`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 310 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 4,598 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 2,617 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/attempt-4/stdout.txt`
- [`output/script.R`](output/script.R) — 4,891 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,712 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T054754Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,477 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/788e67da3f4705924da75f93.json`
- [`output/answer-2.md`](output/answer-2.md) — 6,615 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/abd58757571a49734407fe2c.json`
- [`output/answer-3.md`](output/answer-3.md) — 4,430 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/cd27cd54c11e41e2c7886991.json`
- [`output/answer-4.md`](output/answer-4.md) — 4,599 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/9264546c480dd26e5d1fb43c.json`
- [`output/answer-5.md`](output/answer-5.md) — 4,892 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/5718a5d4cf5b13d054ad2bd1.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 788e67da3f4705924da75f93: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request abd58757571a49734407fe2c: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run3 (request cd27cd54c11e41e2c7886991: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run3 (request 9264546c480dd26e5d1fb43c: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus-run3 (request 5718a5d4cf5b13d054ad2bd1: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 5 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
