# hanlon-2022-aircraft-ip-spillovers · independent · pipeline-claude-opus-4-7 · 20261021T142909Z

| | |
|---|---|
| Paper | `hanlon-2022-aircraft-ip-spillovers` |
| Mode | independent |
| Reproducer | pipeline |
| Model | claude-opus-4-7 |
| Run | 20261021T142909Z |
| Date | 2026-10-21T14:29:09Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-10papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/pipeline/20261021T142909Z` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 10/12 |
| First scored | 10/12 (execution 1) |
| Final | **10/12** |
| Package files withheld | 11 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `airframe_wingload_trend_before_1926_us` | 0.013 (0.006) | 0.0134 | 3.08% | ±0.006 (se_band) | PASS | PASS |
| `airframe_wingload_trend_after_1926_us` | 0.074 (0.006) | 0.0741 | 0.14% | ±0.006 (se_band) | PASS | PASS |
| `airframe_maxspeed_trend_before_1926_us` | -0.001 (0.006) | -0.0082 | 720.00% | ±0.006 (se_band) | FAIL | FAIL |
| `airframe_maxspeed_trend_after_1926_us` | 0.067 (0.006) | 0.075 | 11.94% | ±0.006 (se_band) | FAIL | FAIL |
| `airframe_wingload_trend_before_1926_us_vs_uk` | 0.004 (0.009) | 0.0043 | 7.50% | ±0.009 (se_band) | PASS | PASS |
| `airframe_wingload_trend_after_1926_us_vs_uk` | 0.025 (0.01) | 0.0248 | 0.80% | ±0.01 (se_band) | PASS | PASS |
| `airframe_maxspeed_trend_before_1926_us_vs_uk` | -0.028 (0.009) | -0.0282 | 0.71% | ±0.009 (se_band) | PASS | PASS |
| `airframe_maxspeed_trend_after_1926_us_vs_uk` | 0.031 (0.01) | 0.0305 | 1.61% | ±0.01 (se_band) | PASS | PASS |
| `engine_hp_per_weight_trend_before_1926_us` | 0.039 (0.009) | 0.0395 | 1.28% | ±0.009 (se_band) | PASS | PASS |
| `engine_hp_per_weight_trend_after_1926_us` | -0.01 (0.005) | -0.0102 | 2.00% | ±0.005 (se_band) | PASS | PASS |
| `observations_airframe_wingload_us` | 116 | 116 | 0.00% | ±5.8 (relative) | PASS | PASS |
| `observations_engine_us` | 85 | 85 | 0.00% | ±4.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/12 pass, which agrees with the row's 10/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Reparameterized the US max-speed spline using separate pre/post slope regressors (clamped at 1926) instead of the continuous-kink parameterization, to better match the paper reported pre and post slopes.

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 20,251 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/pipeline/20261021T142909Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 12,448 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/pipeline/20261021T142909Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 193 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/pipeline/20261021T142909Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 4,254 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/pipeline/20261021T142909Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/pipeline/20261021T142909Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 636 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/pipeline/20261021T142909Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 4,184 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/pipeline/20261021T142909Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/pipeline/20261021T142909Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 851 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/pipeline/20261021T142909Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 4,254 bytes, from `benchmark/.cache/llm/1e702f085ef92db7a77bf406.json`
- [`output/answer-2.md`](output/answer-2.md) — 4,184 bytes, from `benchmark/.cache/llm/ca4200c5289ef3bda110f97d.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM cache (request 1e702f085ef92db7a77bf406: model claude-opus-4-7, max_tokens 8192, effort None)
- answer-2.md: reply to prompt-2.txt from the LLM cache (request ca4200c5289ef3bda110f97d: model claude-opus-4-7, max_tokens 8192, effort None)
