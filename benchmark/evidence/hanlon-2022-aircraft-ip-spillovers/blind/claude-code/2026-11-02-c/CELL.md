# hanlon-2022-aircraft-ip-spillovers · blind · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `hanlon-2022-aircraft-ip-spillovers` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:16:30Z |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T202753Z` |
| Run directory | `benchmark/reproductions/hanlon-2022-aircraft-ip-spillovers/blind/2026-11-02-c` |
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
| `airframe_wingload_trend_before_1926_us` | 0.013 (0.006) | 0.0134392 | 3.38% | ±0.006 (se_band) | PASS | PASS |
| `airframe_wingload_trend_after_1926_us` | 0.074 (0.006) | 0.0741463 | 0.20% | ±0.006 (se_band) | PASS | PASS |
| `airframe_maxspeed_trend_before_1926_us` | -0.001 (0.006) | -0.000777187 | 22.28% | ±0.006 (se_band) | PASS | PASS |
| `airframe_maxspeed_trend_after_1926_us` | 0.067 (0.006) | 0.0667927 | 0.31% | ±0.006 (se_band) | PASS | PASS |
| `airframe_wingload_trend_before_1926_us_vs_uk` | 0.004 (0.009) | 0.00429866 | 7.47% | ±0.009 (se_band) | PASS | PASS |
| `airframe_wingload_trend_after_1926_us_vs_uk` | 0.025 (0.01) | 0.0248384 | 0.65% | ±0.01 (se_band) | PASS | PASS |
| `airframe_maxspeed_trend_before_1926_us_vs_uk` | -0.028 (0.009) | -0.0281592 | 0.57% | ±0.009 (se_band) | PASS | PASS |
| `airframe_maxspeed_trend_after_1926_us_vs_uk` | 0.031 (0.01) | 0.0305485 | 1.46% | ±0.01 (se_band) | PASS | PASS |
| `engine_hp_per_weight_trend_before_1926_us` | 0.039 (0.009) | 0.039488 | 1.25% | ±0.009 (se_band) | PASS | PASS |
| `engine_hp_per_weight_trend_after_1926_us` | -0.01 (0.005) | -0.0101684 | 1.68% | ±0.005 (se_band) | PASS | PASS |
| `observations_airframe_wingload_us` | 116 | 116 | 0.00% | ±1.16 (relative) | PASS | PASS |
| `observations_engine_us` | 85 | 85 | 0.00% | ±0.85 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: attempt-1 was exploratory (variable structure, country/type/year tabulations; no RESULT lines). Final: prepared airframe_data.dta restricted to fighters and bombers, 1918-1935; continuous two-piece linear spline in year with knot at 1926 (s_before=min(year,1926), s_after=max(year-1926,0)); OLS with heteroskedasticity-robust (HC1) SEs via fixest. Table 1 cols 1-2: US only, ln_wingload / ln_maxspeed on spline + constant. Cols 3-4: pooled US+UK, ln outcome on constant, US indicator, common (UK baseline) spline, and spline x US; the spline x US coefficients are the US-relative slopes (numerically equivalent to a UK-only spline plus US interactions). Table 4 col 1: engine_data.dta (taken as the already-prepared engines-used-in-fighters/bombers file; it has no aircraft-type field), US only, ln_hp_per_lbs on spline + constant + liquid_cooled. No runs hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 23,472 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T202753Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 875 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T202753Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 268 bytes, from `benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/blind/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 807 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T202753Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T202753Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 8,738 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T202753Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,351 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T202753Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,037 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T202753Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 252 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T202753Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,305 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T202753Z/stdout.txt`
