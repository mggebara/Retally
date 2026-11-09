# hanlon-2022-aircraft-ip-spillovers · independent · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `hanlon-2022-aircraft-ip-spillovers` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T20:10:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261108T015654Z` |
| Run directory | `benchmark/reproductions/hanlon-2022-aircraft-ip-spillovers/independent/2026-11-07-a` |
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

Agent notes: attempt-1 was an exploratory run with no RESULT lines. It inspected airframe_data.dta and engine_data.dta: the fighter+bomber subset gives N=116 US wing-load models, 174 US max-speed models, 165 and 233 pooled US+UK models, and 85 US engines. The final script runs OLS on the precomputed log outcomes with a continuous two-piece linear spline in year (knot 1926: min(year,1926), max(year-1926,0)) and heteroskedasticity-robust (HC1) SEs. Table 1 cols 1-2 use US fighter and bomber models only. For cols 3-4 (eq. 5) the regressors are the common spline (the UK/comparison spline), a US indicator, and the US x spline interactions; the interactions give the US-relative slopes. Table 4 col 1 uses US engines from engine_data.dta (ln_hp_per_lbs) with the spline and liquid_cooled. All 12 values match the claims after rounding. The results were not compared with the claims before the final run, and there were no claim or error attempts.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 23,176 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261108T015654Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 906 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261108T015654Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 268 bytes, from `benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/independent/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 838 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261108T015654Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 210 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261108T015654Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,596 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261108T015654Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 259 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261108T015654Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,431 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261108T015654Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,670 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261108T015654Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 252 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261108T015654Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,492 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261108T015654Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 261 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261108T015654Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
