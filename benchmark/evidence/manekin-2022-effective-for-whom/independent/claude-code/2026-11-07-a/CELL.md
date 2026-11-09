# manekin-2022-effective-for-whom · independent · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `manekin-2022-effective-for-whom` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-08T01:55:53Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261108T015701Z` |
| Run directory | `benchmark/reproductions/manekin-2022-effective-for-whom/independent/2026-11-07-a` |
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
| `respondents_study1_us` | 2269 | 2269 | 0.00% | ±113.45 (relative) | PASS | PASS |
| `respondents_study1_israel` | 3063 | 3063 | 0.00% | ±153.15 (relative) | PASS | PASS |
| `respondents_study2_us` | 3013 | 3013 | 0.00% | ±150.65 (relative) | PASS | PASS |
| `respondents_study2_israel` | 3465 | 3465 | 0.00% | ±173.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: attempt-1 was exploratory: it printed the structure, factor levels, and summaries of the four survey data frames, with no RESULT lines. Final script: OLS via lm(). Study 1 (US wave 1, Israel wave 1) regresses each 0-10 outcome on protester-identity and tactic factors (base: white protesters marching in the streets), weighted by the supplied weight variable. Israeli identity coding was assumed to be 0=white Jews, 1=Ethiopian, 2=Arab. Study 2 (US and Israel wave 2) regresses on black (or the Israeli identity factor), group_goal, and commitment, unweighted because those data frames have no weight variable. The police-action model for Study 2 US drops 5 respondents with a missing outcome, giving 3008 observations. Coefficients, SEs, intercepts, and R2 all match the paper's Tables 1 and 2 as printed in paper.txt, on the first scored run, so no claim-driven changes were made.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 20,770 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261108T015701Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,034 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261108T015701Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 261 bytes, from `benchmark/.cache/claude-code/manekin-2022-effective-for-whom/independent/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 622 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261108T015701Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261108T015701Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 8,343 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261108T015701Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 257 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261108T015701Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,375 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261108T015701Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,819 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261108T015701Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261108T015701Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 6,253 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261108T015701Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 256 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261108T015701Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
