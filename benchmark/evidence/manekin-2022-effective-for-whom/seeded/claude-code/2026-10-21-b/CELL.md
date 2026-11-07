# manekin-2022-effective-for-whom · seeded · claude-code · 2026-10-21-b

| | |
|---|---|
| Paper | `manekin-2022-effective-for-whom` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-21-b |
| Date | 2026-10-22T02:10:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-7papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261022T021417Z` |
| Run directory | `benchmark/reproductions/manekin-2022-effective-for-whom/seeded/2026-10-21-b` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 12/12 (execution 2) |
| Final | **12/12** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `study1_us_black_perceived_violence` | 0.235 (0.117) | 0.235246 | 0.10% | ±0.0047 (relative) | PASS | PASS |
| `study1_us_black_police_action` | 0.268 (0.127) | 0.26801 | 0.00% | ±0.00536 (relative) | PASS | PASS |
| `study1_israel_ethiopian_perceived_violence` | 0.425 (0.107) | 0.425066 | 0.02% | ±0.0085 (relative) | PASS | PASS |
| `study1_israel_ethiopian_police_action` | 0.181 (0.118) | 0.180704 | 0.16% | ±0.00362 (relative) | PASS | PASS |
| `study1_israel_arab_perceived_violence` | 0.623 (0.108) | 0.623088 | 0.01% | ±0.01246 (relative) | PASS | PASS |
| `study1_israel_arab_police_action` | 0.964 (0.119) | 0.9642 | 0.02% | ±0.01928 (relative) | PASS | PASS |
| `study2_us_black_perceived_violence` | 0.347 (0.115) | 0.346652 | 0.10% | ±0.00694 (relative) | PASS | PASS |
| `study2_us_black_police_action` | 0.429 (0.114) | 0.42873 | 0.06% | ±0.00858 (relative) | PASS | PASS |
| `respondents_study1_us` | 2269 | 2269 | 0.00% | ±113.45 (relative) | PASS | PASS |
| `respondents_study1_israel` | 3063 | 3063 | 0.00% | ±153.15 (relative) | PASS | PASS |
| `respondents_study2_us` | 3013 | 3013 | 0.00% | ±150.65 (relative) | PASS | PASS |
| `respondents_study2_israel` | 3465 | 3465 | 0.00% | ±173.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: The task's embedded 'Original Replication Scripts' section contained only macOS AppleDouble (._*) resource-fork files, so the real author scripts were read from the mounted data directory (Replication/Code/Manekin_Mitts_Effective_for_Whom_Replication.R, replicate_table_1.R, replicate_table_4.R). Paper Table 1 = package table_1 (weighted lm of outcome on identity_protesters + tactic, wave-1 data); paper Table 2 = package table_4 (unweighted lm on black + group_goal + commitment for US wave 2; identity_protesters + group_goal + commitment for Israel wave 2). Israel identity_protesters is coded 0/1/2; 1 = Ethiopian, 2 = Arab, following the authors' stargazer covariate labels. Respondent counts are nobs() of the perceived-violence regressions. Attempt-1 crashed on a coefficient-name pattern (selection by 'eth'/'arab' text); fixed by selecting identity_protesters1/2. The final values were eyeballed against the claims after the final run (all agree to the printed precision); no script change followed, so there is no claim attempt.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 29,913 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261022T021417Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 904 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261022T021417Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 256 bytes, from `benchmark/.cache/claude-code/manekin-2022-effective-for-whom/seeded/2026-10-21-b/paper.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 279 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261022T021417Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 2,566 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261022T021417Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 127 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261022T021417Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 962 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261022T021417Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,533 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261022T021417Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,552 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261022T021417Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261022T021417Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,020 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261022T021417Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
