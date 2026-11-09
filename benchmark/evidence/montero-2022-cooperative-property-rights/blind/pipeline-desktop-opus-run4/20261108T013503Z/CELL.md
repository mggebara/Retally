# montero-2022-cooperative-property-rights · blind · pipeline-desktop-opus-run4 · 20261108T013503Z

| | |
|---|---|
| Paper | `montero-2022-cooperative-property-rights` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261108T013503Z |
| Date | 2026-11-08T01:35:03Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261108T013503Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 1/10 |
| First scored | 1/10 (execution 1) |
| Final | **1/10** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `earnings_level_above500_bw300` | 60.49 (31.03) | 112.298 | 85.65% | ±31.03 (se_band) | FAIL | FAIL |
| `earnings_level_above500_bw150` | 52.79 (40.61) | 104.48 | 97.92% | ±40.61 (se_band) | FAIL | FAIL |
| `earnings_iqr_above500_bw300` | -42.97 (17.82) | 43.6397 | 201.56% | ±17.82 (se_band) | FAIL | FAIL |
| `earnings_iqr_above500_bw150` | -51.79 (24.79) | 62.286 | 220.27% | ±24.79 (se_band) | FAIL | FAIL |
| `n_obs_earnings_level_bw300` | 4770 | 3991 | 16.33% | ±238.5 (relative) | FAIL | FAIL |
| `n_obs_earnings_level_bw150` | 1583 | 3951 | 149.59% | ±79.15 (relative) | FAIL | FAIL |
| `n_obs_earnings_iqr_bw300` | 327 | 76 | 76.76% | ±16.35 (relative) | FAIL | FAIL |
| `n_obs_earnings_iqr_bw150` | 118 | 73 | 38.14% | ±5.9 (relative) | FAIL | FAIL |
| `n_clusters_bw300` | 98 | 99 | 1.02% | ±4.9 (relative) | PASS | PASS |
| `n_clusters_bw150` | 36 | 95 | 163.89% | ±1.8 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 1/10 pass, which agrees with the row's 1/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 13,055 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261108T013503Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261108T013503Z/execution.json`
- [`output/script.R`](output/script.R) — 6,880 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261108T013503Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 488 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261108T013503Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 6,087 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261108T013503Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,881 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/d6ad4b97ff6c87f407afaeb6.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 1.5 | 10 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request d6ad4b97ff6c87f407afaeb6: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
