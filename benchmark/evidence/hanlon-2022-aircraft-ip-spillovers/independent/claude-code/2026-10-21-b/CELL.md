# hanlon-2022-aircraft-ip-spillovers · independent · claude-code · 2026-10-21-b

| | |
|---|---|
| Paper | `hanlon-2022-aircraft-ip-spillovers` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-21-b |
| Date | 2026-10-22T02:07:25Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-7papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261022T021417Z` |
| Run directory | `benchmark/reproductions/hanlon-2022-aircraft-ip-spillovers/independent/2026-10-21-b` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 12/12 (execution 2) |
| Final | **12/12** |
| Package files withheld | 11 |
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

Agent notes: attempt-1 was exploratory: it inspected airframe_data.dta and engine_data.dta (counts by country and type, no estimates). The final script uses only those two .dta files. Airframes: fighter and bomber models from 1918-1935, log wing load or log max speed regressed on a continuous two-piece linear spline in year with a knot at 1926 (s1 = min(year,1926), s2 = max(year-1926,0)) plus a constant, HC1 robust SEs (fixest hetero). For the US-UK comparison: pooled US+UK, with the common spline (which is the UK spline), a US dummy, and the spline interacted with US; the interaction coefficients are the US-relative slopes. Engines: US engines in engine_data.dta, log hp per lbs on the spline plus a liquid-cooled dummy, robust SEs. Sample sizes come out as 116/174/165/233 (Table 1) and 85 (Table 4), matching the paper. All 12 coefficients and counts match the claimed values to printed precision, and so do the standard errors. I compared the results with the claims after the first scored run but did not change the script, so there are no claim attempts. No script files in the dataset were opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 24,038 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261022T021417Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 906 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261022T021417Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 268 bytes, from `benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/independent/2026-10-21-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,108 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261022T021417Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 814 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261022T021417Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 11,628 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261022T021417Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,595 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261022T021417Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,194 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261022T021417Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 462 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261022T021417Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,266 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261022T021417Z/stdout.txt`
