# montero-2022-cooperative-property-rights · blind · pipeline-desktop-opus-run3 · 20261103T010557Z

| | |
|---|---|
| Paper | `montero-2022-cooperative-property-rights` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T010557Z |
| Date | 2026-11-03T01:05:57Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T010557Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/10 |
| First scored | 0/10 (execution 2) |
| Final | **0/10** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `earnings_level_above500_bw300` | 60.49 (31.03) | — | — | ±31.03 (se_band) | FAIL | FAIL |
| `earnings_level_above500_bw150` | 52.79 (40.61) | — | — | ±40.61 (se_band) | FAIL | FAIL |
| `earnings_iqr_above500_bw300` | -42.97 (17.82) | — | — | ±17.82 (se_band) | FAIL | FAIL |
| `earnings_iqr_above500_bw150` | -51.79 (24.79) | — | — | ±24.79 (se_band) | FAIL | FAIL |
| `n_obs_earnings_level_bw300` | 4770 | 3907 | 18.09% | ±238.5 (relative) | FAIL | FAIL |
| `n_obs_earnings_level_bw150` | 1583 | 1472 | 7.01% | ±79.15 (relative) | FAIL | FAIL |
| `n_obs_earnings_iqr_bw300` | 327 | — | — | ±16.35 (relative) | FAIL | FAIL |
| `n_obs_earnings_iqr_bw150` | 118 | — | — | ±5.9 (relative) | FAIL | FAIL |
| `n_clusters_bw300` | 98 | 82 | 16.33% | ±4.9 (relative) | FAIL | FAIL |
| `n_clusters_bw150` | 36 | 26 | 27.78% | ±1.8 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 0/10 pass, which agrees with the row's 0/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 13,522 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T010557Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 8,920 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T010557Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 152 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T010557Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 5,232 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T010557Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 152 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T010557Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,603 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T010557Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 5,447 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T010557Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 146 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T010557Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,932 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T010557Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,233 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/027978921c72122c942df262.json`
- [`output/answer-2.md`](output/answer-2.md) — 5,448 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/fffa3392e09eeb28a2f50d11.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 027978921c72122c942df262: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request fffa3392e09eeb28a2f50d11: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
