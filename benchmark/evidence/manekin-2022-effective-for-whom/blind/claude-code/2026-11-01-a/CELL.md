# manekin-2022-effective-for-whom · blind · claude-code · 2026-11-01-a

| | |
|---|---|
| Paper | `manekin-2022-effective-for-whom` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-01-a |
| Date | 2026-11-02T04:20:30Z |
| Results file | `benchmark/results/claude-code-run2-13papers-indep-blind-2026-11-01.json` |
| Artifacts | `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T043821Z` |
| Run directory | `benchmark/reproductions/manekin-2022-effective-for-whom/blind/2026-11-01-a` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 12/12 (execution 2) |
| Final | **12/12** |
| Package files withheld | 96 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `study1_us_black_perceived_violence` | 0.235 (0.117) | 0.235246 | 0.10% | ±0.117 (se_band) | PASS | PASS |
| `study1_us_black_police_action` | 0.268 (0.127) | 0.26801 | 0.00% | ±0.127 (se_band) | PASS | PASS |
| `study1_israel_ethiopian_perceived_violence` | 0.425 (0.107) | 0.425066 | 0.02% | ±0.107 (se_band) | PASS | PASS |
| `study1_israel_ethiopian_police_action` | 0.181 (0.118) | 0.180704 | 0.16% | ±0.118 (se_band) | PASS | PASS |
| `study1_israel_arab_perceived_violence` | 0.623 (0.108) | 0.623088 | 0.01% | ±0.108 (se_band) | PASS | PASS |
| `study1_israel_arab_police_action` | 0.964 (0.119) | 0.9642 | 0.02% | ±0.119 (se_band) | PASS | PASS |
| `study2_us_black_perceived_violence` | 0.347 (0.115) | 0.346652 | 0.10% | ±0.115 (se_band) | PASS | PASS |
| `study2_us_black_police_action` | 0.429 (0.114) | 0.42873 | 0.06% | ±0.114 (se_band) | PASS | PASS |
| `respondents_study1_us` | 2269 | 2269 | 0.00% | ±22.69 (relative) | PASS | PASS |
| `respondents_study1_israel` | 3063 | 3063 | 0.00% | ±30.63 (relative) | PASS | PASS |
| `respondents_study2_us` | 3013 | 3013 | 0.00% | ±30.13 (relative) | PASS | PASS |
| `respondents_study2_israel` | 3465 | 3465 | 0.00% | ±34.65 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Israeli protester identity codes assumed 0=white Jews, 1=Ethiopian Jews, 2=Arabs (paper's listing order; the data factor has no labels).
- (reproduction.json) Study 2 regressions are unweighted because the Study 2 data files contain no weight variable; Study 1 regressions use the provided weight variable.

Agent notes: attempt-1 was exploratory (variable inspection, no RESULT lines). Final: OLS (lm) with indicator regressors as in Tables 1-2. Study 1 US: outcome ~ Black + shut-down-traffic + destroy-police-cars, weighted, full wave-1 data (all three waves pooled, N=2269). Study 1 Israel: outcome ~ Ethiopian + Arab + traffic + garbage cans, weighted, full sample incl. Arab-respondent subsample (N=3063). Study 2 US: outcome ~ Black + group goal + commitment, unweighted; police action drops 5 missing (N=3008). Study 2 Israel N from the perceived-violence regression on the full file (3465). No author scripts or result tables were opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 20,586 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T043821Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,002 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T043821Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 261 bytes, from `benchmark/.cache/claude-code/manekin-2022-effective-for-whom/blind/2026-11-01-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 614 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T043821Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T043821Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 11,030 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T043821Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,414 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T043821Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,000 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T043821Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T043821Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 5,980 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T043821Z/stdout.txt`
