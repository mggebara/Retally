# corno-2022-interaction-stereotypes-performance · independent · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `corno-2022-interaction-stereotypes-performance` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T14:36:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-corno-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143913Z` |
| Run directory | `benchmark/reproductions/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-a` |
| Executions | 3 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 2) |
| Final | **13/13** |
| Package files withheld | 20 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `race_iat_mixed_room_whites_table3_col1` | 0.316 (0.14) | 0.315851 | 0.05% | ±0.14 (se_band) | PASS | PASS |
| `race_iat_mixed_room_blacks_table3_col2` | -0.094 (0.069) | -0.094447 | 0.48% | ±0.069 (se_band) | PASS | PASS |
| `n_obs_table3_whites` | 117 | 117 | 0.00% | ±5.85 (relative) | PASS | PASS |
| `n_obs_table3_blacks` | 332 | 332 | 0.00% | ±16.6 (relative) | PASS | PASS |
| `gpa_mixed_room_blacks_table4_panelB_col1` | 0.257 (0.125) | 0.256671 | 0.13% | ±0.125 (se_band) | PASS | PASS |
| `exams_passed_mixed_room_blacks_table4_panelB_col2` | 0.645 (0.245) | 0.644533 | 0.07% | ±0.245 (se_band) | PASS | PASS |
| `eligible_mixed_room_blacks_table4_panelB_col3` | 0.152 (0.04) | 0.151538 | 0.30% | ±0.04 (se_band) | PASS | PASS |
| `performance_index_mixed_room_blacks_table4_panelB_col4` | 0.443 (0.141) | 0.443286 | 0.06% | ±0.141 (se_band) | PASS | PASS |
| `gpa_mixed_room_whites_table4_panelA_col1` | -0.028 (0.243) | -0.028236 | 0.84% | ±0.243 (se_band) | PASS | PASS |
| `gpa_mixed_room_full_table4_panelC_col1` | 0.147 (0.102) | 0.146735 | 0.18% | ±0.102 (se_band) | PASS | PASS |
| `exams_passed_mixed_room_full_table4_panelC_col2` | 0.447 (0.204) | 0.446589 | 0.09% | ±0.204 (se_band) | PASS | PASS |
| `performance_index_mixed_room_full_table4_panelC_col4` | 0.289 (0.113) | 0.289163 | 0.06% | ±0.113 (se_band) | PASS | PASS |
| `n_obs_table4_panelC_cols1_2` | 499 | 499 | 0.00% | ±24.95 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Attempt-1 was exploratory: it printed variable names, labels and summaries of uctdata_balanced.dta and uctdata_clean.dta, with no RESULT lines. Working sample: uctdata_balanced.dta, follow-up round (round==2), 499 students (117 white, 332 black). The controls are the data's mean-imputed variables with missing dummies. Own controls: Female, Falseuct2012/missfalse, durpcabas_nomiss/miss, consbas_nomiss/miss, Foreign/foreign_missing, privateschool_nomiss/miss. Roommate controls: the same set without female. Table 3 regresses follow-up Race IAT on mixracebas plus baseline Race IAT and the controls, with residence FE. Table 4 uses GPA, examspassed, continue and PCAperf. The subsample regressions use residence FE plus regprogram FE. The full-sample regressions add white, coloured and Else dummies, with race group (Black/White/Other) x residence FE and regprogram FE. OLS via fixest, SEs clustered by room (Res_base x roomnum_base). Attempt-2 matched every claimed coefficient, but Table 4 N was 493 because fixest drops singleton FE cells. check_attempt reported all claims within tolerance; I still switched to fixef.rm='none' (keeping singletons, as dummy-variable OLS does). The final run gives N=499/498, and its SEs match the paper's Table 3 and Table 4 values to 3 decimals.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,249 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143913Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,016 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143913Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 291 bytes, from `benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 952 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143913Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143913Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 963,997 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143913Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 272 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143913Z/attempt-1/timing.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 252 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143913Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,901 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143913Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143913Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,348 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143913Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 272 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143913Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,853 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143913Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,995 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143913Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143913Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,348 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143913Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 272 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143913Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
