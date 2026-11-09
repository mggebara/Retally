# hanlon-2022-aircraft-ip-spillovers · blind · claude-code · 2026-11-01-a

| | |
|---|---|
| Paper | `hanlon-2022-aircraft-ip-spillovers` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-01-a |
| Date | 2026-11-02T04:21:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-13papers-indep-blind-2026-11-01.json` |
| Artifacts | `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T043821Z` |
| Run directory | `benchmark/reproductions/hanlon-2022-aircraft-ip-spillovers/blind/2026-11-01-a` |
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

Agent notes: attempt-1 was exploratory (it inspected variables and counts in airframe_data.dta and engine_data.dta and printed no RESULT lines). Final run: airframes restricted to type in {fighter, bomber}, 1918-1935. The spline is continuous with pieces min(year,1926) and max(year-1926,0), as in Stata mkspline without the marginal option, so each coefficient is the slope inside its segment. Eq. (4): log outcome on the two pieces plus a constant, US only. Eq. (5): pooled US+UK, with a common spline as the UK baseline, a US indicator and the US-interacted pieces, so the US coefficients are slopes relative to the UK. Table 4 col 1: US rows of engine_data.dta (85 rows with ln_hp_per_lbs; the file looks pre-aggregated to fighter/bomber engines and has no type variable, so all US rows were used), with the pieces plus liquid_cooled. HC1 robust SEs via fixest; there are no weights. Only data files were loaded; no scripts, .tex, logs or PDFs from the mount were opened. Disclosure: when I printed paper.txt lines 755-900 plus 1055-1075 to read the method, the output included one stray line of three integers from the garbled Table 1 block (its observations row). That happened before any estimation. The specification was fixed from the method text alone and was not adjusted afterwards. Only one scored run was made.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 24,609 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T043821Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 875 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T043821Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 268 bytes, from `benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/blind/2026-11-01-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 675 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T043821Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 210 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T043821Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 9,219 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T043821Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,801 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T043821Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,620 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T043821Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 252 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T043821Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,266 bytes, from `benchmark/results/artifacts/hanlon-2022-aircraft-ip-spillovers/blind/claude-code/20261102T043821Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
