# hanlon-2022-aircraft-ip-spillovers · blind · claude-code · 2026-11-03-a

| | |
|---|---|
| Paper | `hanlon-2022-aircraft-ip-spillovers` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-03-a |
| Date | 2026-11-03T00:13:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-redaction-3papers-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261103T001658Z` |
| Run directory | `benchmark/reproductions/hanlon-2022-aircraft-ip-spillovers/blind/2026-11-03-a` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 8/12 (execution 2) |
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
| `airframe_wingload_trend_before_1926_us_vs_uk` | 0.004 (0.009) | 0.004299 | 7.47% | ±0.009 (se_band) | PASS | FAIL |
| `airframe_wingload_trend_after_1926_us_vs_uk` | 0.025 (0.01) | 0.024838 | 0.65% | ±0.01 (se_band) | PASS | FAIL |
| `airframe_maxspeed_trend_before_1926_us_vs_uk` | -0.028 (0.009) | -0.028159 | 0.57% | ±0.009 (se_band) | PASS | FAIL |
| `airframe_maxspeed_trend_after_1926_us_vs_uk` | 0.031 (0.01) | 0.030549 | 1.45% | ±0.01 (se_band) | PASS | FAIL |
| `engine_hp_per_weight_trend_before_1926_us` | 0.039 (0.009) | 0.039488 | 1.25% | ±0.009 (se_band) | PASS | PASS |
| `engine_hp_per_weight_trend_after_1926_us` | -0.01 (0.005) | -0.010168 | 1.68% | ±0.005 (se_band) | PASS | PASS |
| `observations_airframe_wingload_us` | 116 | 116 | 0.00% | ±5.8 (relative) | PASS | PASS |
| `observations_engine_us` | 85 | 85 | 0.00% | ±4.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Pooled US-UK regressions (Table 1 cols 3-4) use a baseline year spline common to all observations plus the spline interacted with a US indicator (and a US indicator), so the US interaction coefficients are US-minus-UK slopes. The paper describes the baseline as a spline 'for the comparison country'; read literally as a UK-only spline, the US terms would just reproduce the US-only slopes, which contradicts the paper's description of them as relative to the UK.
- (reproduction.json) Engine sample is all United States rows of engine_data.dta with non-missing ln_hp_per_lbs (85). The file has no aircraft-type variable, so I assumed it already holds only engines used in fighters and bombers (every US row has a non-missing count from the airframe match).

Agent notes: Airframe sample: airframe_data.dta, type fighter or bomber, years 1918-1935, US (cols 1-2) or US+UK (cols 3-4), non-missing outcome. Continuous two-piece spline with each coefficient equal to its segment's slope: pre = min(year,1926)-1926, post = max(year,1926)-1926. OLS with heteroskedasticity-robust SEs (fixest). Engine regression adds a liquid-cooled indicator. attempt-1 was exploratory (data inspection, no RESULT lines). attempt-2 was the first scored run; its pooled spec used separate US and UK splines, so its 'vs UK' coefficients were the US-only slopes rather than relative slopes. I fixed that from the paper's text (no claimed values were seen or compared), and the result is the final run. No Docker hangs.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 23,472 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261103T001658Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 875 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261103T001658Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 281 bytes, from `benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/blind/2026-11-03-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 830 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261103T001658Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261103T001658Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 15,027 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261103T001658Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,726 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261103T001658Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 252 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261103T001658Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,913 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261103T001658Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,018 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261103T001658Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,897 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261103T001658Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 252 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261103T001658Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,657 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261103T001658Z/stdout.txt`
