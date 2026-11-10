# corno-2022-interaction-stereotypes-performance · blind · claude-code · 2026-11-10-c

| | |
|---|---|
| Paper | `corno-2022-interaction-stereotypes-performance` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-c |
| Date | 2026-11-10T14:37:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run3-1paper-corno-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z` |
| Run directory | `benchmark/reproductions/corno-2022-interaction-stereotypes-performance/blind/2026-11-10-c` |
| Executions | 4 |
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
| `performance_index_mixed_room_blacks_table4_panelB_col4` | 0.443 (0.141) | 0.557987 | 25.96% | ±0.141 (se_band) | PASS | PASS |
| `gpa_mixed_room_whites_table4_panelA_col1` | -0.028 (0.243) | -0.028236 | 0.84% | ±0.243 (se_band) | PASS | PASS |
| `gpa_mixed_room_full_table4_panelC_col1` | 0.147 (0.102) | 0.146735 | 0.18% | ±0.102 (se_band) | PASS | PASS |
| `exams_passed_mixed_room_full_table4_panelC_col2` | 0.447 (0.204) | 0.446589 | 0.09% | ±0.204 (se_band) | PASS | PASS |
| `performance_index_mixed_room_full_table4_panelC_col4` | 0.289 (0.113) | 0.367585 | 27.19% | ±0.113 (se_band) | PASS | PASS |
| `n_obs_table4_panelC_cols1_2` | 499 | 499 | 0.00% | ±24.95 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Academic performance index computed by us as the first principal component (correlation-matrix PCA, prcomp with scaling, sign set to correlate positively with GPA) of GPA, exams passed and eligible to continue over the 498 working-sample students with all three non-missing. The dataset's own PCAperf variable correlates 0.995 with it but has a smaller SD (1.15 vs 1.36), so it was apparently computed on a different sample or normalisation; we did not use it.
- (reproduction.json) GPA used as provided (variable GPA, already standardized in the data file; SD 1.005 in the working sample); not re-standardized.

Agent notes: Working sample = round-2 rows of uctdata_balanced.dta (499 students with baseline and follow-up and both IATs; 117 white, 332 black, 157 in mixed rooms). Mixed Room = mixracebas. Own controls: Female, Falseuct2012 (UCT score/1000, mean-imputed) + missfalse, durpcabas_nomiss (wealth index) + durpcabas_miss, consbas_nomiss + consbas_miss, Foreign, privateschool_nomiss (foreign_missing and privateschool_miss are all zero and dropped). Roommate controls: roFalseuct2012, missrofalse, rodurpcabas_nomiss, rodurpcabas_miss, roconsbas_nomiss, roconsbas_missing, roForeign_bas, roforeign_missingbas, roprivschool_nomiss, roprivschool_miss. Table 3: follow-up DscoreraceIAT on mixracebas + DscoreraceIATbas + controls, residence (Res_base) FE, by race. Table 4: GPA / examspassed / continue / PCA index on mixracebas + controls with Res_base and regprogram FE (Panels A/B); Panel C adds white, coloured, Else dummies and race-group (black/white/other) x residence FE (white and Else are absorbed/collinear and dropped by fixest). OLS via fixest, SEs clustered by roomnum_base (room ids are unique across residences). attempt-1 and attempt-2 were exploratory (variable inspection, no RESULT lines). attempt-3 was the first estimating run; it used fixest's default removal of fixed-effect singletons (academic programs with one student), which dropped observations (N 493 in Panel C) relative to the paper's dummy-variable OLS; the final run sets fixef.rm='none' so all working-sample observations are kept (coefficients unchanged, N = 499; SEs slightly different). This change was made for sample definition only, not by comparison with any reported value. The paper's FWER p-values were not computed (not requested). No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,817 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 985 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 291 bytes, from `benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/blind/2026-11-10-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,128 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 581,865 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 266 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,782 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 4,229 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 266 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 5,390 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 1,286 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 1,851 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 266 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/attempt-3/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,940 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,485 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 494 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,851 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 266 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143920Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
