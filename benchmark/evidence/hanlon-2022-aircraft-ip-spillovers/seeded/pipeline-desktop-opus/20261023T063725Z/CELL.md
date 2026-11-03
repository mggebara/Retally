# hanlon-2022-aircraft-ip-spillovers · seeded · pipeline-desktop-opus · 20261023T063725Z

| | |
|---|---|
| Paper | `hanlon-2022-aircraft-ip-spillovers` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261023T063725Z |
| Date | 2026-10-23T06:37:25Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/pipeline/20261023T063725Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 12/12 |
| First scored | 12/12 (execution 1) |
| Final | **12/12** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `airframe_wingload_trend_before_1926_us` | 0.013 (0.006) | 0.0134392 | 3.38% | ±0.0005 (printed_precision) | PASS | PASS |
| `airframe_wingload_trend_after_1926_us` | 0.074 (0.006) | 0.0741463 | 0.20% | ±0.00148 (relative) | PASS | PASS |
| `airframe_maxspeed_trend_before_1926_us` | -0.001 (0.006) | -0.000777187 | 22.28% | ±0.0005 (printed_precision) | PASS | PASS |
| `airframe_maxspeed_trend_after_1926_us` | 0.067 (0.006) | 0.0667927 | 0.31% | ±0.00134 (relative) | PASS | PASS |
| `airframe_wingload_trend_before_1926_us_vs_uk` | 0.004 (0.009) | 0.00429866 | 7.47% | ±0.0005 (printed_precision) | PASS | PASS |
| `airframe_wingload_trend_after_1926_us_vs_uk` | 0.025 (0.01) | 0.0248384 | 0.65% | ±0.0005 (relative) | PASS | PASS |
| `airframe_maxspeed_trend_before_1926_us_vs_uk` | -0.028 (0.009) | -0.0281592 | 0.57% | ±0.00056 (relative) | PASS | PASS |
| `airframe_maxspeed_trend_after_1926_us_vs_uk` | 0.031 (0.01) | 0.0305485 | 1.46% | ±0.00062 (relative) | PASS | PASS |
| `engine_hp_per_weight_trend_before_1926_us` | 0.039 (0.009) | 0.039488 | 1.25% | ±0.00078 (relative) | PASS | PASS |
| `engine_hp_per_weight_trend_after_1926_us` | -0.01 (0.005) | -0.0101684 | 1.68% | ±0.0005 (printed_precision) | PASS | PASS |
| `observations_airframe_wingload_us` | 116 | 116 | 0.00% | ±5.8 (relative) | PASS | PASS |
| `observations_engine_us` | 85 | 85 | 0.00% | ±4.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 128,753 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/pipeline/20261023T063725Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 4,195 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/pipeline/20261023T063725Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/pipeline/20261023T063725Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,341 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/pipeline/20261023T063725Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 4,196 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/135c6316838e3227705ffe03.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 135c6316838e3227705ffe03: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 1 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
