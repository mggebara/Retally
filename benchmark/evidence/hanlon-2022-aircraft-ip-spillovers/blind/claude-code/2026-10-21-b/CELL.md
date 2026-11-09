# hanlon-2022-aircraft-ip-spillovers · blind · claude-code · 2026-10-21-b

| | |
|---|---|
| Paper | `hanlon-2022-aircraft-ip-spillovers` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-21-b |
| Date | 2026-10-22T02:12:14Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-7papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261022T021417Z` |
| Run directory | `benchmark/reproductions/hanlon-2022-aircraft-ip-spillovers/blind/2026-10-21-b` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 8/12 (execution 2) |
| Final | **12/12** |
| Package files withheld | 11 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `airframe_wingload_trend_before_1926_us` | 0.013 (0.006) | 0.0134392 | 3.38% | ±0.006 (se_band) | PASS | PASS |
| `airframe_wingload_trend_after_1926_us` | 0.074 (0.006) | 0.0741463 | 0.20% | ±0.006 (se_band) | PASS | PASS |
| `airframe_maxspeed_trend_before_1926_us` | -0.001 (0.006) | -0.000777187 | 22.28% | ±0.006 (se_band) | PASS | PASS |
| `airframe_maxspeed_trend_after_1926_us` | 0.067 (0.006) | 0.0667927 | 0.31% | ±0.006 (se_band) | PASS | PASS |
| `airframe_wingload_trend_before_1926_us_vs_uk` | 0.004 (0.009) | 0.00429866 | 7.47% | ±0.009 (se_band) | PASS | FAIL |
| `airframe_wingload_trend_after_1926_us_vs_uk` | 0.025 (0.01) | 0.0248384 | 0.65% | ±0.01 (se_band) | PASS | FAIL |
| `airframe_maxspeed_trend_before_1926_us_vs_uk` | -0.028 (0.009) | -0.0281592 | 0.57% | ±0.009 (se_band) | PASS | FAIL |
| `airframe_maxspeed_trend_after_1926_us_vs_uk` | 0.031 (0.01) | 0.0305485 | 1.46% | ±0.01 (se_band) | PASS | FAIL |
| `engine_hp_per_weight_trend_before_1926_us` | 0.039 (0.009) | 0.039488 | 1.25% | ±0.009 (se_band) | PASS | PASS |
| `engine_hp_per_weight_trend_after_1926_us` | -0.01 (0.005) | -0.0101684 | 1.68% | ±0.005 (se_band) | PASS | PASS |
| `observations_airframe_wingload_us` | 116 | 116 | 0.00% | ±5.8 (relative) | PASS | PASS |
| `observations_engine_us` | 85 | 85 | 0.00% | ±4.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Engine sample: engine_data.dta taken as the paper's fighter/bomber engine file (it carries airframe-matched counts); US rows with non-missing ln_hp_per_lbs used without further filtering (85 engines). The paper text does not spell out how the file was built.
- (reproduction.json) Spline: continuous two-piece linear spline in Stata mkspline form, before = min(year,1926), after = max(year-1926,0), so 1926 belongs to the before segment and the coefficients are segment slopes, not slope changes.
- (reproduction.json) Equation (5) parameterized as a constant, a US indicator, a baseline spline on all observations (the UK/comparison slope) and spline x US (US slope minus UK slope).

Agent notes: Data: airframe_data.dta (types fighter and bomber, US and UK, years 1918-1935, all years in the file) and engine_data.dta. OLS with lm(); HC1 robust SEs printed but no point estimates depend on them. Table 1 columns 1-2: US only, log wing load / log max speed on the spline plus a constant (N=116 wing load, 174 max speed). Columns 3-4: pooled US+UK (N=165, 233). Table 4 column 1: US engines, log hp per lb on the spline plus a liquid-cooled indicator plus a constant (N=85). Attempt-1 was exploratory (variable inspection, no RESULT lines). Attempt-2 printed RESULT lines, but its pooled regressions used separate US-only and UK-only splines, so the 'vs UK' coefficients were plain US slopes (identical to columns 1-2) instead of relative slopes. Found by self-review of the specification, not by comparison with any paper value; reparameterized for the final run (see attempt-2/feedback.txt). Kind is '' because neither 'error' nor 'claim' applies. Disclosure: while reading paper.txt for the method (the Table 1 notes area, lines 1055-1075), a garbled fragment of three bare numbers from the Table 1 extraction showed on screen; it was not searched for and the specification was not adjusted toward it. No .do/.R or result files (.tex/.log/.pdf) in the mount were opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 24,609 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261022T021417Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 875 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261022T021417Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 281 bytes, from `benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/blind/2026-10-21-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 955 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261022T021417Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261022T021417Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 11,363 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261022T021417Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 670 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261022T021417Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,974 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261022T021417Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 150 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261022T021417Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,896 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261022T021417Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,482 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261022T021417Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,052 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261022T021417Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 150 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261022T021417Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,894 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261022T021417Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
