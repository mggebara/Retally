# hanlon-2022-aircraft-ip-spillovers · seeded · claude-code · 2026-10-21-b

| | |
|---|---|
| Paper | `hanlon-2022-aircraft-ip-spillovers` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-21-b |
| Date | 2026-10-22T02:03:30Z |
| Results file | `benchmark/results/claude-code-7papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/claude-code/20261022T021417Z` |
| Run directory | `benchmark/reproductions/hanlon-2022-aircraft-ip-spillovers/seeded/2026-10-21-b` |
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
| `observations_airframe_wingload_us` | 116 | 116 | 0.00% | ±1.16 (relative) | PASS | PASS |
| `observations_engine_us` | 85 | 85 | 0.00% | ±0.85 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Translated the Table 1 and Table 4 blocks of 2-results-main.do into fixest::feols with vcov='hetero' (Stata vce(r)). Airframes: airframe_data.dta restricted to US/UK fighters and bombers; mkspline knot 1926 as pre1926=min(year,1926), post1926=max(year-1926,0); US-only columns regress ln_wingload / ln_maxspeed on pre1926_US post1926_US; pooled columns add pre1926, post1926 and a US dummy. Engines: engine_data.dta US/UK, US-only regression of ln_hp_per_lbs on pre1926_US post1926_US liquid_cooled. Single run, no comparison-driven changes; all estimates round to the claimed values (N=116 and 85 match).

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 134,703 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/claude-code/20261022T021417Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 773 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/claude-code/20261022T021417Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 263 bytes, from `benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/seeded/2026-10-21-b/paper.txt`

## What it produced

- [`output/reproduction.json`](output/reproduction.json) — 1,040 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/claude-code/20261022T021417Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,614 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/claude-code/20261022T021417Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 252 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/claude-code/20261022T021417Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,642 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/seeded/claude-code/20261022T021417Z/stdout.txt`
