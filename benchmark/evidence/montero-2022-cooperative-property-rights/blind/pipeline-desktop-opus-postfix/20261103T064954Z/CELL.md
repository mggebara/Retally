# montero-2022-cooperative-property-rights · blind · pipeline-desktop-opus-postfix · 20261103T064954Z

| | |
|---|---|
| Paper | `montero-2022-cooperative-property-rights` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T064954Z |
| Date | 2026-11-03T06:49:54Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T064954Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/10 |
| First scored | 3/10 (execution 2) |
| Final | **3/10** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `earnings_level_above500_bw300` | 60.49 (31.03) | 101.435 | 67.69% | ±31.03 (se_band) | FAIL | FAIL |
| `earnings_level_above500_bw150` | 52.79 (40.61) | 94.6765 | 79.35% | ±40.61 (se_band) | FAIL | FAIL |
| `earnings_iqr_above500_bw300` | -42.97 (17.82) | 77.7983 | 281.05% | ±17.82 (se_band) | FAIL | FAIL |
| `earnings_iqr_above500_bw150` | -51.79 (24.79) | -74.2325 | 43.33% | ±24.79 (se_band) | PASS | PASS |
| `n_obs_earnings_level_bw300` | 4770 | 3991 | 16.33% | ±238.5 (relative) | FAIL | FAIL |
| `n_obs_earnings_level_bw150` | 1583 | 1513 | 4.42% | ±79.15 (relative) | PASS | PASS |
| `n_obs_earnings_iqr_bw300` | 327 | 74 | 77.37% | ±16.35 (relative) | FAIL | FAIL |
| `n_obs_earnings_iqr_bw150` | 118 | 26 | 77.97% | ±5.9 (relative) | FAIL | FAIL |
| `n_clusters_bw300` | 98 | 95 | 3.06% | ±4.9 (relative) | PASS | PASS |
| `n_clusters_bw150` | 36 | 34 | 5.56% | ±1.8 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 3/10 pass, which agrees with the row's 3/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 15,473 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T064954Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 9,396 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T064954Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 1,193 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T064954Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 441 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T064954Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 5,652 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T064954Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 1,193 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T064954Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 539 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T064954Z/attempt-1/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 747 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T064954Z/samples.txt`
- [`output/script.R`](output/script.R) — 5,841 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T064954Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 286 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T064954Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,501 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T064954Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,653 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/bafadd20aefe14c4547b7256.json`
- [`output/answer-2.md`](output/answer-2.md) — 5,842 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/939280aaec923fa4a478e0d7.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request bafadd20aefe14c4547b7256: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix (request 939280aaec923fa4a478e0d7: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
