# hanlon-2022-aircraft-ip-spillovers · independent · pipeline-desktop-opus-postfix2 · 20261103T110326Z

| | |
|---|---|
| Paper | `hanlon-2022-aircraft-ip-spillovers` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261103T110326Z |
| Date | 2026-11-03T11:03:26Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/pipeline/20261103T110326Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 12/12 |
| First scored | 12/12 (execution 1) |
| Final | **12/12** |
| Package files withheld | 42 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `airframe_wingload_trend_before_1926_us` | 0.013 (0.006) | 0.013439 | 3.38% | ±0.006 (se_band) | PASS | PASS |
| `airframe_wingload_trend_after_1926_us` | 0.074 (0.006) | 0.074146 | 0.20% | ±0.006 (se_band) | PASS | PASS |
| `airframe_maxspeed_trend_before_1926_us` | -0.001 (0.006) | -0.000777 | 22.30% | ±0.006 (se_band) | PASS | PASS |
| `airframe_maxspeed_trend_after_1926_us` | 0.067 (0.006) | 0.066793 | 0.31% | ±0.006 (se_band) | PASS | PASS |
| `airframe_wingload_trend_before_1926_us_vs_uk` | 0.004 (0.009) | 0.004299 | 7.47% | ±0.009 (se_band) | PASS | PASS |
| `airframe_wingload_trend_after_1926_us_vs_uk` | 0.025 (0.01) | 0.024838 | 0.65% | ±0.01 (se_band) | PASS | PASS |
| `airframe_maxspeed_trend_before_1926_us_vs_uk` | -0.028 (0.009) | -0.028159 | 0.57% | ±0.009 (se_band) | PASS | PASS |
| `airframe_maxspeed_trend_after_1926_us_vs_uk` | 0.031 (0.01) | 0.030549 | 1.45% | ±0.01 (se_band) | PASS | PASS |
| `engine_hp_per_weight_trend_before_1926_us` | 0.039 (0.009) | 0.039488 | 1.25% | ±0.009 (se_band) | PASS | PASS |
| `engine_hp_per_weight_trend_after_1926_us` | -0.01 (0.005) | -0.010168 | 1.68% | ±0.005 (se_band) | PASS | PASS |
| `observations_airframe_wingload_us` | 116 | 116 | 0.00% | ±5.8 (relative) | PASS | PASS |
| `observations_engine_us` | 85 | 85 | 0.00% | ±4.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 29,217 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/pipeline/20261103T110326Z/prompt-1.txt`

## What it produced

- [`output/samples.txt`](output/samples.txt) — 624 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/pipeline/20261103T110326Z/samples.txt`
- [`output/script.R`](output/script.R) — 6,578 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/pipeline/20261103T110326Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 252 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/pipeline/20261103T110326Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,649 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/pipeline/20261103T110326Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,579 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/f753b05a27bf2a965410bc27.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request f753b05a27bf2a965410bc27: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
