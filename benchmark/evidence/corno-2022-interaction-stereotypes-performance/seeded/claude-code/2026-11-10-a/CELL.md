# corno-2022-interaction-stereotypes-performance · seeded · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `corno-2022-interaction-stereotypes-performance` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T14:40:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-corno-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143624Z` |
| Run directory | `benchmark/reproductions/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
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

Agent notes: Translated 1_main_tables.do Tables 3 and 4 to fixest::feols on uctdata_balanced.dta (round 2). Table 3: Race IAT on mixracebas, lagged (round-1) Race IAT, own subsample controls, roommate controls, Res_base dummies, white/black subsamples. Table 4: GPA/examspassed/continue/PCAperf on mixracebas, controls, roommate controls, Res_base and regprogram dummies; full sample adds race dummies and blackRes/whiteRes dummies. Fixed effects entered as factor regressors (as in Stata xi/i.), SEs clustered by roomnum_base. Attempt 1 crashed because roconsbas_miss is a Stata varabbrev abbreviation of roconsbas_missing; the final script resolves abbreviations to the unique matching variable. No claim-feedback iterations were needed; all 13 reproduced values agree with the claimed values to the reported precision.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 224,663 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143624Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 871 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143624Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 286 bytes, from `benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 134 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143624Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 4,150 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143624Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 58 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143624Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143624Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 267 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143624Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,316 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143624Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,432 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143624Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 2,032 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143624Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,516 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143624Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 267 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/seeded/claude-code/20261110T143624Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
