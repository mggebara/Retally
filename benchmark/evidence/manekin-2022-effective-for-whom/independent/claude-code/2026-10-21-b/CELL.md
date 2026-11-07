# manekin-2022-effective-for-whom · independent · claude-code · 2026-10-21-b

| | |
|---|---|
| Paper | `manekin-2022-effective-for-whom` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-21-b |
| Date | 2026-10-22T02:07:14Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-7papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261022T021417Z` |
| Run directory | `benchmark/reproductions/manekin-2022-effective-for-whom/independent/2026-10-21-b` |
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

Agent notes: attempt-1 was exploratory (variable structure, treatment coding, weights; no RESULT lines). Final: OLS via lm(). Study 1 (US wave 1, Israel wave 1): outcome on minority-identity dummies (US: identity_protesters==1 Black; Israel: identity_protesters 1=Ethiopian, 2=Arab) and tactic dummies (tactic 1, 2), base white/march, weighted by the survey weight variable. Study 2 US (wave 2): outcome on black, group_goal, commitment, unweighted (no weight variable supplied); police-action regression drops the 5 missing responses (N=3008). Respondent counts are the regression N / data rows. Coefficients, standard errors, intercepts and R2 all line up with the paper's printed Tables 1 and 2. No claim-check attempts were needed; the script was not changed after the first estimating run.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 20,018 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261022T021417Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,034 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261022T021417Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 261 bytes, from `benchmark/.cache/claude-code/manekin-2022-effective-for-whom/independent/2026-10-21-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 637 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261022T021417Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261022T021417Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,916 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261022T021417Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,274 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261022T021417Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,711 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261022T021417Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261022T021417Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 5,215 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/claude-code/20261022T021417Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
