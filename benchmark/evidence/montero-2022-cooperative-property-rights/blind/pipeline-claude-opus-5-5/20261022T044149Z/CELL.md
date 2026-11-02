# montero-2022-cooperative-property-rights · blind · pipeline-claude-opus-5-5 · 20261022T044149Z

| | |
|---|---|
| Paper | `montero-2022-cooperative-property-rights` |
| Mode | blind |
| Reproducer | pipeline |
| Model | claude-opus-5-5 |
| Run | 20261022T044149Z |
| Date | 2026-10-22T04:41:49Z |
| Results file | `benchmark/results/pipeline-opus55-4papers-all-modes-2026-10-22.json` |
| Artifacts | `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261022T044149Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/10 |
| First scored | 0/10 (execution 1) |
| Final | **0/10** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `earnings_level_above500_bw300` | 60.49 (31.03) | 196.77 | 225.29% | ±31.03 (se_band) | FAIL | FAIL |
| `earnings_level_above500_bw150` | 52.79 (40.61) | 196.77 | 272.74% | ±40.61 (se_band) | FAIL | FAIL |
| `earnings_iqr_above500_bw300` | -42.97 (17.82) | — | — | ±17.82 (se_band) | FAIL | FAIL |
| `earnings_iqr_above500_bw150` | -51.79 (24.79) | — | — | ±24.79 (se_band) | FAIL | FAIL |
| `n_obs_earnings_level_bw300` | 4770 | 130 | 97.27% | ±47.7 (relative) | FAIL | FAIL |
| `n_obs_earnings_level_bw150` | 1583 | 126 | 92.04% | ±15.83 (relative) | FAIL | FAIL |
| `n_obs_earnings_iqr_bw300` | 327 | 7 | 97.86% | ±3.27 (relative) | FAIL | FAIL |
| `n_obs_earnings_iqr_bw150` | 118 | 7 | 94.07% | ±1.18 (relative) | FAIL | FAIL |
| `n_clusters_bw300` | 98 | 6 | 93.88% | ±0.98 (relative) | FAIL | FAIL |
| `n_clusters_bw150` | 36 | 6 | 83.33% | ±0.5 (printed_precision) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 0/10 pass, which agrees with the row's 0/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 12,948 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261022T044149Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 4,971 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261022T044149Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 382 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261022T044149Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,016 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261022T044149Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 4,971 bytes, from `benchmark/.cache/llm/77a1b121994f954d9accc63f.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM cache (request 77a1b121994f954d9accc63f: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 2 model calls; 1 are code-generation prompts kept above, the other 1 (paper extraction) leave no prompt in the artifacts
