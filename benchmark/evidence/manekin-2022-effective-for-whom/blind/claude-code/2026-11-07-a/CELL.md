# manekin-2022-effective-for-whom · blind · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `manekin-2022-effective-for-whom` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-08T02:10:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z` |
| Run directory | `benchmark/reproductions/manekin-2022-effective-for-whom/blind/2026-11-07-a` |
| Executions | 4 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 12/12 (execution 4) |
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
| `respondents_study1_us` | 2269 | 2269 | 0.00% | ±113.45 (relative) | PASS | PASS |
| `respondents_study1_israel` | 3063 | 3063 | 0.00% | ±153.15 (relative) | PASS | PASS |
| `respondents_study2_us` | 3013 | 3013 | 0.00% | ±150.65 (relative) | PASS | PASS |
| `respondents_study2_israel` | 3465 | 3465 | 0.00% | ±173.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Israeli protester identity coding assumed from the factor order: identity_protesters 0 = white Jews, 1 = Ethiopian Jews, 2 = Arab Israelis (order of mention in the paper; wave 2's smallest cell being 0 is consistent with white Jews appearing only with generic goals). The data carry no value labels.
- (reproduction.json) Study 2 regressions are unweighted: neither Study 2 data file contains a weight variable. Study 1 regressions use the 'weight' column (lm weights).

Agent notes: Data files are pre-cleaned analysis files; all rows used. Study 1: weighted OLS of degree_violence / police_action_required on minority-protester indicator(s) plus indicators for the two more intense tactics (base: white/majority protesters marching). Study 2 US: OLS on black, group_goal, commitment (police column drops 5 NA rows; respondents count taken from the perceived-violence regression, N=3013). Study 2 Israel: OLS on Ethiopian, Arab, group_goal, commitment, N=3465. Classical OLS SEs (only point estimates and N are scored). Attempt-1 inspected variables; attempt-2 was an exploratory look at the text-analysis lists (crashed: quanteda not installed; no estimates, so kind ''); attempt-3 crashed on lm weights scoping and was fixed. While reading the paper's method/table structure I unavoidably saw unredacted non-target entries of Tables 1-2 (intercepts, tactic/goal coefficients); the specification was derived from the paper's description and not adjusted toward any number.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,338 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,002 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 274 bytes, from `benchmark/.cache/claude-code/manekin-2022-effective-for-whom/blind/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 833 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 8,723 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 251 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 611 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 292 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 66 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 251 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/attempt-2/timing.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 289 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 3,123 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 147 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 251 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/attempt-3/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,054 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,130 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 5,628 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 251 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261108T015724Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
