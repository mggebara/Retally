# montero-2022-cooperative-property-rights · blind · pipeline-desktop-opus-run2 · 20261023T151837Z

| | |
|---|---|
| Paper | `montero-2022-cooperative-property-rights` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261023T151837Z |
| Date | 2026-10-23T15:18:37Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261023T151837Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/10 |
| First scored | 1/10 (execution 2) |
| Final | **3/10** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `earnings_level_above500_bw300` | 60.49 (31.03) | 101.435 | 67.69% | ±31.03 (se_band) | FAIL | FAIL |
| `earnings_level_above500_bw150` | 52.79 (40.61) | 94.6765 | 79.35% | ±40.61 (se_band) | FAIL | FAIL |
| `earnings_iqr_above500_bw300` | -42.97 (17.82) | 41.3073 | 196.13% | ±17.82 (se_band) | FAIL | FAIL |
| `earnings_iqr_above500_bw150` | -51.79 (24.79) | 116.443 | 324.84% | ±24.79 (se_band) | FAIL | FAIL |
| `n_obs_earnings_level_bw300` | 4770 | 3991 | 16.33% | ±238.5 (relative) | FAIL | FAIL |
| `n_obs_earnings_level_bw150` | 1583 | 1513 | 4.42% | ±79.15 (relative) | PASS | FAIL |
| `n_obs_earnings_iqr_bw300` | 327 | 76 | 76.76% | ±16.35 (relative) | FAIL | FAIL |
| `n_obs_earnings_iqr_bw150` | 118 | 28 | 76.27% | ±5.9 (relative) | FAIL | FAIL |
| `n_clusters_bw300` | 98 | 99 | 1.02% | ±4.9 (relative) | PASS | FAIL |
| `n_clusters_bw150` | 36 | 36 | 0.00% | ±1.8 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 3/10 pass, which agrees with the row's 3/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) IQR regressions use one observation per property; no survey-round FE (not identifiable with one obs per property)

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 13,055 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261023T151837Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 9,620 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261023T151837Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 1,713 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261023T151837Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 6,041 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261023T151837Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 1,713 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261023T151837Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261023T151837Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 6,170 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261023T151837Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,803 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261023T151837Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 513 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261023T151837Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,042 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/ddb449131531d7379738ca0b.json`
- [`output/answer-2.md`](output/answer-2.md) — 6,171 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/a93cd03d3d4b93b1eb85d0a3.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request ddb449131531d7379738ca0b: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request a93cd03d3d4b93b1eb85d0a3: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
