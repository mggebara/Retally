# hanlon-2022-aircraft-ip-spillovers · independent · claude-code · 2026-11-01-a

| | |
|---|---|
| Paper | `hanlon-2022-aircraft-ip-spillovers` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-01-a |
| Date | 2026-11-02T04:26:09Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-13papers-indep-blind-2026-11-01.json` |
| Artifacts | `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T043820Z` |
| Run directory | `benchmark/reproductions/hanlon-2022-aircraft-ip-spillovers/independent/2026-11-01-a` |
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

Agent notes: attempt-1 was exploratory (inspected airframe_data.dta and engine_data.dta, counted samples; no RESULT lines). Final: OLS with heteroskedasticity-robust SEs (fixest, vcov='hetero'). Airframes restricted to fighters and bombers, 1918-1935. Two-piece linear spline in year with a knot at 1926 (sp1=min(year,1926), sp2=max(year-1926,0); each coefficient is a segment slope, like Stata mkspline). Table 1 cols 1-2: US only, log wing load / log max speed on the spline plus a constant. Cols 3-4: pooled US+UK on spline, spline x US, US dummy and constant; the spline x US coefficients are the US slopes relative to the UK. Table 4 col 1: US engines from engine_data.dta (85 obs, all of them), log hp per lb on the spline, a liquid-cooled dummy and a constant. Sample sizes match the paper (116/174/165/233/85), as do the SEs. I compared the final RESULT values with the claims; all agree to the reported precision, and the script was not changed afterwards, so no claim attempt is recorded.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 24,038 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T043820Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 906 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T043820Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 268 bytes, from `benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/independent/2026-11-01-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 817 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T043820Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 512 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T043820Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 10,118 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T043820Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,481 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T043820Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,371 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T043820Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 252 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T043820Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,633 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/independent/claude-code/20261102T043820Z/stdout.txt`
