# montero-2022-cooperative-property-rights · seeded · pipeline-desktop-opus-run2 · 20261023T151837Z

| | |
|---|---|
| Paper | `montero-2022-cooperative-property-rights` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261023T151837Z |
| Date | 2026-10-23T15:18:37Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/montero-2022-cooperative-property-rights/seeded/pipeline/20261023T151837Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 10/10 |
| First scored | 10/10 (execution 1) |
| Final | **10/10** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `earnings_level_above500_bw300` | 60.49 (31.03) | 60.4948 | 0.01% | ±1.2098 (relative) | PASS | PASS |
| `earnings_level_above500_bw150` | 52.79 (40.61) | 52.7907 | 0.00% | ±1.0558 (relative) | PASS | PASS |
| `earnings_iqr_above500_bw300` | -42.97 (17.82) | -42.9673 | 0.01% | ±0.8594 (relative) | PASS | PASS |
| `earnings_iqr_above500_bw150` | -51.79 (24.79) | -51.7852 | 0.01% | ±1.0358 (relative) | PASS | PASS |
| `n_obs_earnings_level_bw300` | 4770 | 4770 | 0.00% | ±238.5 (relative) | PASS | PASS |
| `n_obs_earnings_level_bw150` | 1583 | 1583 | 0.00% | ±79.15 (relative) | PASS | PASS |
| `n_obs_earnings_iqr_bw300` | 327 | 327 | 0.00% | ±16.35 (relative) | PASS | PASS |
| `n_obs_earnings_iqr_bw150` | 118 | 118 | 0.00% | ±5.9 (relative) | PASS | PASS |
| `n_clusters_bw300` | 98 | 98 | 0.00% | ±4.9 (relative) | PASS | PASS |
| `n_clusters_bw150` | 36 | 36 | 0.00% | ±1.8 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/10 pass, which agrees with the row's 10/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 25,367 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/seeded/pipeline/20261023T151837Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 3,616 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/seeded/pipeline/20261023T151837Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,049 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/seeded/pipeline/20261023T151837Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 390 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/seeded/pipeline/20261023T151837Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 3,617 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/b4eb6eca89df0f041ad96209.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request b4eb6eca89df0f041ad96209: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 1 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
