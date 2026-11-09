# hanlon-2022-aircraft-ip-spillovers · blind · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `hanlon-2022-aircraft-ip-spillovers` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T20:10:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261108T015654Z` |
| Run directory | `benchmark/reproductions/hanlon-2022-aircraft-ip-spillovers/blind/2026-11-07-a` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 12/12 (execution 2) |
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

Agent notes: attempt-1 was an exploratory data inspection (no RESULT lines). Final script: airframe_data.dta restricted to type fighter or bomber, 1918-1935; continuous two-piece linear spline in year with knot at 1926 (yr_before = min(year,1926), yr_after = max(year-1926,0)); OLS with HC1 robust SEs. US-only columns: log wing load / log max speed on the spline plus constant. US-UK columns: pooled US+UK fighters/bombers with a common spline (the UK spline), a US indicator, and the spline interacted with the US indicator; the interaction coefficients are reported as the US-relative slopes. No engine controls. Engine column: engine_data.dta (Jane's, which appears already limited to engines used in fighters/bombers: US+UK rows = 123, matching the Table 4 pooled N), US only, log hp per lb on the spline, a liquid-cooled indicator and a constant. Observation counts are the regression Ns. No weights.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 23,747 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261108T015654Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 875 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261108T015654Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 281 bytes, from `benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/blind/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 845 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261108T015654Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261108T015654Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,070 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261108T015654Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 255 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261108T015654Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,383 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261108T015654Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,923 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261108T015654Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 150 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261108T015654Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,927 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261108T015654Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 255 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261108T015654Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
