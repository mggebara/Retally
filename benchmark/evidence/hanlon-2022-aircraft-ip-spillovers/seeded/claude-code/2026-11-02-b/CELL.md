# hanlon-2022-aircraft-ip-spillovers · seeded · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `hanlon-2022-aircraft-ip-spillovers` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T19:35:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-23papers-seeded-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/claude-code/20261102T194315Z` |
| Run directory | `benchmark/reproductions/hanlon-2022-aircraft-ip-spillovers/seeded/2026-11-02-b` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 12/12 |
| First scored | 12/12 (execution 1) |
| Final | **12/12** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `airframe_wingload_trend_before_1926_us` | 0.013 (0.006) | 0.013439 | 3.38% | ±0.0005 (printed_precision) | PASS | PASS |
| `airframe_wingload_trend_after_1926_us` | 0.074 (0.006) | 0.074146 | 0.20% | ±0.00148 (relative) | PASS | PASS |
| `airframe_maxspeed_trend_before_1926_us` | -0.001 (0.006) | -0.000777 | 22.30% | ±0.0005 (printed_precision) | PASS | PASS |
| `airframe_maxspeed_trend_after_1926_us` | 0.067 (0.006) | 0.066793 | 0.31% | ±0.00134 (relative) | PASS | PASS |
| `airframe_wingload_trend_before_1926_us_vs_uk` | 0.004 (0.009) | 0.004299 | 7.47% | ±0.0005 (printed_precision) | PASS | PASS |
| `airframe_wingload_trend_after_1926_us_vs_uk` | 0.025 (0.01) | 0.024838 | 0.65% | ±0.0005 (relative) | PASS | PASS |
| `airframe_maxspeed_trend_before_1926_us_vs_uk` | -0.028 (0.009) | -0.028159 | 0.57% | ±0.00056 (relative) | PASS | PASS |
| `airframe_maxspeed_trend_after_1926_us_vs_uk` | 0.031 (0.01) | 0.030549 | 1.45% | ±0.00062 (relative) | PASS | PASS |
| `engine_hp_per_weight_trend_before_1926_us` | 0.039 (0.009) | 0.039488 | 1.25% | ±0.00078 (relative) | PASS | PASS |
| `engine_hp_per_weight_trend_after_1926_us` | -0.01 (0.005) | -0.010168 | 1.68% | ±0.0005 (printed_precision) | PASS | PASS |
| `observations_airframe_wingload_us` | 116 | 116 | 0.00% | ±5.8 (relative) | PASS | PASS |
| `observations_engine_us` | 85 | 85 | 0.00% | ±4.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Translated Table 1 (cols 1-4) and Table 4 (col 1) from 2-results-main.do into fixest::feols with heteroskedasticity-robust SEs. Data: airframe_data.dta restricted to US/UK fighters and bombers; engine_data.dta restricted to US/UK. Stata mkspline pre1926 1926 post1926 = year reproduced as pre1926 = min(year,1926), post1926 = max(year-1926,0); US interactions as in the do-file. US-only regressions use only the US-interacted spline pieces plus a constant (plus liquid_cooled for engines); pooled regressions include pre1926, pre1926_US, post1926, post1926_US and US. Single run, no claim comparison or repairs.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 132,094 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/claude-code/20261102T194315Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 773 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/claude-code/20261102T194315Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 263 bytes, from `benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/seeded/2026-11-02-b/paper.txt`

## What it produced

- [`output/reproduction.json`](output/reproduction.json) — 1,046 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/claude-code/20261102T194315Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,534 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/claude-code/20261102T194315Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 252 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/claude-code/20261102T194315Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,252 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/claude-code/20261102T194315Z/stdout.txt`
