# corno-2022-interaction-stereotypes-performance · blind · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `corno-2022-interaction-stereotypes-performance` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T14:37:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-corno-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143919Z` |
| Run directory | `benchmark/reproductions/corno-2022-interaction-stereotypes-performance/blind/2026-11-10-b` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 3) |
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

- (reproduction.json) Performance index: used the dataset's provided PCAperf variable (first principal component of GPA, exams passed, eligible to continue) rather than recomputing it; a PC1 recomputed on the 498-student working sample correlates 0.995 with PCAperf but has a different scale (sd ratio 1.18), so it was printed as an unscored robustness line only.
- (reproduction.json) GPA: used the dataset's provided standardized GPA variable (standardized on a sample broader than the 499-student working sample; mean -0.01 in it).

Agent notes: Data: uctdata_balanced.dta (499 students x 2 rounds); kept the follow-up round (round 2), one row per student, with baseline IATs from DscoreraceIATbas/DscoreacaIATbas. Working sample 499 (332 black, 117 white, 18 coloured, 32 Indian/Asian/other). Own controls: Female, UCT admission score (Falseuct2012 + missfalse), wealth index (durpcabas_nomiss + miss dummy), consumption (consbas_nomiss + miss dummy), Foreign, private high school (mean-imputed with missing dummies; all-zero missing dummies dropped). Roommate controls: same minus female, with their missing dummies. Table 3: OLS of follow-up Race IAT on mixracebas + baseline Race IAT + controls, residence FE, by race. Table 4: adds academic program (regprogram) FE; panels A/B residence FE; panel C adds White/Coloured/Indian-Other dummies and race-group (Black/White/residual) x residence FE. SEs clustered by roomnum_base (room ids are unique across residences). fixest::feols. Attempts 1-2 were exploratory (variable listing, panel structure, PCA check), no RESULT lines. The final script was the only scored run; no repairs. No docker hangs. Only the task's mount and paper.txt were read; no script files in the package were opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,817 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143919Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 985 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143919Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 291 bytes, from `benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/blind/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 770 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143919Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143919Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 350,103 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143919Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 266 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143919Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,609 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143919Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143919Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 8,914 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143919Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 266 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143919Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,258 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143919Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,556 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143919Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143919Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,546 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143919Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 266 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143919Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
