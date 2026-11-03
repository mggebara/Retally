# montero-2022-cooperative-property-rights · blind · pipeline-claude-opus-4-7 · 20261021T142909Z

| | |
|---|---|
| Paper | `montero-2022-cooperative-property-rights` |
| Mode | blind |
| Reproducer | pipeline |
| Model | claude-opus-4-7 |
| Run | 20261021T142909Z |
| Date | 2026-10-21T14:29:09Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-10papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261021T142909Z` |
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
| `earnings_level_above500_bw300` | 60.49 (31.03) | 215.706 | 256.60% | ±31.03 (se_band) | FAIL | FAIL |
| `earnings_level_above500_bw150` | 52.79 (40.61) | 221.158 | 318.94% | ±40.61 (se_band) | FAIL | FAIL |
| `earnings_iqr_above500_bw300` | -42.97 (17.82) | — | — | ±17.82 (se_band) | FAIL | FAIL |
| `earnings_iqr_above500_bw150` | -51.79 (24.79) | — | — | ±24.79 (se_band) | FAIL | FAIL |
| `n_obs_earnings_level_bw300` | 4770 | 1038 | 78.24% | ±238.5 (relative) | FAIL | FAIL |
| `n_obs_earnings_level_bw150` | 1583 | 407 | 74.29% | ±79.15 (relative) | FAIL | FAIL |
| `n_obs_earnings_iqr_bw300` | 327 | 40 | 87.77% | ±16.35 (relative) | FAIL | FAIL |
| `n_obs_earnings_iqr_bw150` | 118 | 16 | 86.44% | ±5.9 (relative) | FAIL | FAIL |
| `n_clusters_bw300` | 98 | 80 | 18.37% | ±4.9 (relative) | FAIL | FAIL |
| `n_clusters_bw150` | 36 | 31 | 13.89% | ±1.8 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 0/10 pass, which agrees with the row's 0/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 12,183 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261021T142909Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 6,888 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261021T142909Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 146 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261021T142909Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 9,105 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/pipeline/20261021T142909Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,897 bytes, from `benchmark/.cache/llm/8e48767d56d120214594a0b6.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM cache (request 8e48767d56d120214594a0b6: model claude-opus-4-7, max_tokens 8192, effort None)
- usage records 2 model calls; 1 are code-generation prompts kept above, the other 1 (paper extraction) leave no prompt in the artifacts
