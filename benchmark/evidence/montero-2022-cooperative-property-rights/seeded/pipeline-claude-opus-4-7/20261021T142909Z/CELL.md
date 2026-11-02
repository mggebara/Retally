# montero-2022-cooperative-property-rights · seeded · pipeline-claude-opus-4-7 · 20261021T142909Z

| | |
|---|---|
| Paper | `montero-2022-cooperative-property-rights` |
| Mode | seeded |
| Reproducer | pipeline |
| Model | claude-opus-4-7 |
| Run | 20261021T142909Z |
| Date | 2026-10-21T14:29:09Z |
| Results file | `benchmark/results/pipeline-10papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/montero-2022-cooperative-property-rights/seeded/pipeline/20261021T142909Z` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 0/10 |
| First scored | 0/10 (execution 1) |
| Final | **10/10** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `earnings_level_above500_bw300` | 60.49 (31.03) | 60.4948 | 0.01% | ±1.2098 (relative) | PASS | FAIL |
| `earnings_level_above500_bw150` | 52.79 (40.61) | 52.7907 | 0.00% | ±1.0558 (relative) | PASS | FAIL |
| `earnings_iqr_above500_bw300` | -42.97 (17.82) | -42.9673 | 0.01% | ±0.8594 (relative) | PASS | FAIL |
| `earnings_iqr_above500_bw150` | -51.79 (24.79) | -51.7852 | 0.01% | ±1.0358 (relative) | PASS | FAIL |
| `n_obs_earnings_level_bw300` | 4770 | 4770 | 0.00% | ±47.7 (relative) | PASS | FAIL |
| `n_obs_earnings_level_bw150` | 1583 | 1583 | 0.00% | ±15.83 (relative) | PASS | FAIL |
| `n_obs_earnings_iqr_bw300` | 327 | 327 | 0.00% | ±3.27 (relative) | PASS | FAIL |
| `n_obs_earnings_iqr_bw150` | 118 | 118 | 0.00% | ±1.18 (relative) | PASS | FAIL |
| `n_clusters_bw300` | 98 | 98 | 0.00% | ±0.98 (relative) | PASS | FAIL |
| `n_clusters_bw150` | 36 | 36 | 0.00% | ±0.5 (printed_precision) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/10 pass, which agrees with the row's 10/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 24,055 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/seeded/pipeline/20261021T142909Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 13,728 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/seeded/pipeline/20261021T142909Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 779 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/seeded/pipeline/20261021T142909Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 4,641 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/seeded/pipeline/20261021T142909Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 360 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/seeded/pipeline/20261021T142909Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 381 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/seeded/pipeline/20261021T142909Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 4,304 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/seeded/pipeline/20261021T142909Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 360 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/seeded/pipeline/20261021T142909Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 387 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/seeded/pipeline/20261021T142909Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 4,641 bytes, from `benchmark/.cache/llm/7badc75e9bde00325c64b896.json`
- [`output/answer-2.md`](output/answer-2.md) — 4,304 bytes, from `benchmark/.cache/llm/f775ff76b67634095e72e316.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM cache (request 7badc75e9bde00325c64b896: model claude-opus-4-7, max_tokens 8192, effort None)
- answer-2.md: reply to prompt-2.txt from the LLM cache (request f775ff76b67634095e72e316: model claude-opus-4-7, max_tokens 8192, effort None)
- usage records 5 model calls; 2 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
