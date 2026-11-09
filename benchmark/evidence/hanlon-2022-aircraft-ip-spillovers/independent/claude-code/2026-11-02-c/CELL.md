# hanlon-2022-aircraft-ip-spillovers · independent · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `hanlon-2022-aircraft-ip-spillovers` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:02:43Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T202751Z` |
| Run directory | `benchmark/reproductions/hanlon-2022-aircraft-ip-spillovers/independent/2026-11-02-c` |
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

Agent notes: attempt-1 was exploratory (variable labels, country/type counts, non-missing outcome counts; no RESULT lines). Final run: airframe_data.dta restricted to fighters and bombers; continuous two-piece linear spline in year with knot at 1926 (pre = min(year-1926,0), post = max(year-1926,0)); OLS with HC1 robust SEs via fixest. Table 1 cols 1-2: US only, log wing load / log max speed on spline + constant (N=116 / 174). Cols 3-4: pooled US+UK, common spline (the UK spline) + US indicator + US x spline pieces; the US x spline coefficients are the relative slopes (N=165 / 233). Table 4 col 1: engine_data.dta, US engines, log hp per lb on spline + liquid-cooled indicator + constant (N=85). All 12 quantities matched the paper at reported precision on the first scored run, so no claim-driven changes were made. No script files from the dataset were opened. Timestamps taken from the host clock.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 22,901 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T202751Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 906 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T202751Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 268 bytes, from `benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/independent/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 887 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T202751Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 143 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T202751Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 8,985 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T202751Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,389 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T202751Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,612 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T202751Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 252 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T202751Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,569 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T202751Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
