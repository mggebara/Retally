# corno-2022-interaction-stereotypes-performance · independent · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `corno-2022-interaction-stereotypes-performance` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T14:36:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-corno-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143914Z` |
| Run directory | `benchmark/reproductions/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-b` |
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

Agent notes: Data: ForJournals_a/Data/Clean/uctdata_balanced.dta (499 students x 2 rounds = the working sample with both IATs at baseline and follow-up); the follow-up row (round==2) is used, with DscoreraceIATbas as the baseline Race IAT. Treatment mixracebas. Own controls: Female, Falseuct2012 (UCT score/1000), durpcabas_nomiss (wealth PCA), consbas_nomiss, Foreign, privateschool_nomiss, each with its missing-value dummy (already mean-imputed in the data); roommate controls: the same five without female, each with its missing dummy. Table 3: OLS of follow-up DscoreraceIAT on mixracebas + baseline IAT + controls with residence FE, by race (white/black). Table 4: GPA (standardized cumcareergpa), examspassed, continue (eligible), PCAperf (the dataset's performance PCA index) on mixracebas + controls with residence FE and academic program (regprogram) FE for whites/blacks; full sample adds white/coloured/Else dummies and race-group (Black/White/other) x residence FE. SEs clustered by baseline room (Res_base x roomnum_base, 340 rooms). fixest feols. attempt-1 was an exploratory variable listing. attempt-2 matched every coefficient but fixest's default dropped 6 program-FE singletons (N=493 in Panel C); the final run keeps them (fixef.rm='none'), which gives N=499/498, and the R-squared and SEs now also match the paper. No hangs.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,249 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143914Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,016 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143914Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 291 bytes, from `benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,090 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143914Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143914Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 530,014 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143914Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 271 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143914Z/attempt-1/timing.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 277 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143914Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 4,340 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143914Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143914Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 7,994 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143914Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 272 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143914Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,901 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143914Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,359 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143914Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143914Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,994 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143914Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 272 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143914Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
