# montero-2022-cooperative-property-rights · blind · pipeline-desktop-opus-postfix2 · 20261103T111134Z

| | |
|---|---|
| Paper | `montero-2022-cooperative-property-rights` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261103T111134Z |
| Date | 2026-11-03T11:11:34Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T111134Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 2/10 |
| First scored | 2/10 (execution 1) |
| Final | **2/10** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `earnings_level_above500_bw300` | 60.49 (31.03) | 101.435 | 67.69% | ±31.03 (se_band) | FAIL | FAIL |
| `earnings_level_above500_bw150` | 52.79 (40.61) | 94.6765 | 79.35% | ±40.61 (se_band) | FAIL | FAIL |
| `earnings_iqr_above500_bw300` | -42.97 (17.82) | 44.9009 | 204.49% | ±17.82 (se_band) | FAIL | FAIL |
| `earnings_iqr_above500_bw150` | -51.79 (24.79) | 95.6526 | 284.69% | ±24.79 (se_band) | FAIL | FAIL |
| `n_obs_earnings_level_bw300` | 4770 | 3991 | 16.33% | ±238.5 (relative) | FAIL | FAIL |
| `n_obs_earnings_level_bw150` | 1583 | 1513 | 4.42% | ±79.15 (relative) | PASS | PASS |
| `n_obs_earnings_iqr_bw300` | 327 | 76 | 76.76% | ±16.35 (relative) | FAIL | FAIL |
| `n_obs_earnings_iqr_bw150` | 118 | 28 | 76.27% | ±5.9 (relative) | FAIL | FAIL |
| `n_clusters_bw300` | 98 | 95 | 3.06% | ±4.9 (relative) | PASS | PASS |
| `n_clusters_bw150` | 36 | 34 | 5.56% | ±1.8 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 2/10 pass, which agrees with the row's 2/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 15,473 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T111134Z/prompt-1.txt`

## What it produced

- [`output/samples.txt`](output/samples.txt) — 783 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T111134Z/samples.txt`
- [`output/script.R`](output/script.R) — 5,951 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T111134Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 146 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T111134Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,442 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261103T111134Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,952 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/bafadd20aefe14c4547b7256.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request bafadd20aefe14c4547b7256: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
