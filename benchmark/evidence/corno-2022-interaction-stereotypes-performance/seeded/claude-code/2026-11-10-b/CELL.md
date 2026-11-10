# corno-2022-interaction-stereotypes-performance · seeded · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `corno-2022-interaction-stereotypes-performance` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T14:35:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-corno-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143625Z` |
| Run directory | `benchmark/reproductions/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-b` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 2) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `race_iat_mixed_room_whites_table3_col1` | 0.316 (0.14) | 0.315851 | 0.05% | ±0.00632 (relative) | PASS | PASS |
| `race_iat_mixed_room_blacks_table3_col2` | -0.094 (0.069) | -0.094447 | 0.48% | ±0.00188 (relative) | PASS | PASS |
| `n_obs_table3_whites` | 117 | 117 | 0.00% | ±5.85 (relative) | PASS | PASS |
| `n_obs_table3_blacks` | 332 | 332 | 0.00% | ±16.6 (relative) | PASS | PASS |
| `gpa_mixed_room_blacks_table4_panelB_col1` | 0.257 (0.125) | 0.256671 | 0.13% | ±0.00514 (relative) | PASS | PASS |
| `exams_passed_mixed_room_blacks_table4_panelB_col2` | 0.645 (0.245) | 0.644533 | 0.07% | ±0.0129 (relative) | PASS | PASS |
| `eligible_mixed_room_blacks_table4_panelB_col3` | 0.152 (0.04) | 0.151538 | 0.30% | ±0.00304 (relative) | PASS | PASS |
| `performance_index_mixed_room_blacks_table4_panelB_col4` | 0.443 (0.141) | 0.443286 | 0.06% | ±0.00886 (relative) | PASS | PASS |
| `gpa_mixed_room_whites_table4_panelA_col1` | -0.028 (0.243) | -0.028236 | 0.84% | ±0.00056 (relative) | PASS | PASS |
| `gpa_mixed_room_full_table4_panelC_col1` | 0.147 (0.102) | 0.146735 | 0.18% | ±0.00294 (relative) | PASS | PASS |
| `exams_passed_mixed_room_full_table4_panelC_col2` | 0.447 (0.204) | 0.446589 | 0.09% | ±0.00894 (relative) | PASS | PASS |
| `performance_index_mixed_room_full_table4_panelC_col4` | 0.289 (0.113) | 0.289163 | 0.06% | ±0.00578 (relative) | PASS | PASS |
| `n_obs_table4_panelC_cols1_2` | 499 | 499 | 0.00% | ±24.95 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: attempt-1 was exploratory (variable listing, no RESULT lines). Final script translates 1_main_tables.do Table 3 (DscoreraceIAT on mixracebas, lagged round-1 DscoreraceIAT, own and roommate controls, Res_base FE; round 2, whites/blacks) and Table 4 (GPA, examspassed, continue, PCAperf on mixracebas, controls, Res_base + regprogram FE for whites/blacks; full sample adds white/coloured/Else dummies and blackRes + whiteRes + Res_base + regprogram FE) using fixest::feols with fixef.rm='none' and SEs clustered by roomnum_base, on uctdata_balanced.dta. The do-file's 'roconsbas_miss' is a Stata abbreviation of the dataset variable roconsbas_missing, used here. Collinear dummies (foreign_missing, privateschool_miss, and white/Else in the full sample, absorbed by the race x residence FE) are dropped by fixest, as Stata would omit them. All 13 RESULT values match the claimed values at the reported precision; no claim-driven revisions were made. The run was done in a scratch directory and the files copied here.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 224,663 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143625Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 871 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143625Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 286 bytes, from `benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 936 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143625Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143625Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 4,731 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143625Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 266 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143625Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,517 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143625Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,442 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143625Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,756 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143625Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,300 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143625Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 267 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143625Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
