# lopez-2022-patient-demand-prescription-overuse · independent · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `lopez-2022-patient-demand-prescription-overuse` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T06:43:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-lopez-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064343Z` |
| Run directory | `benchmark/reproductions/lopez-2022-patient-demand-prescription-overuse/independent/2026-11-10-a` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 12/12 (execution 3) |
| Final | **12/12** |
| Package files withheld | 36 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `voucher_used_patient_voucher_table3_col1` | 0.35 (0.03) | 0.346459 | 1.01% | ±0.03 (se_band) | PASS | PASS |
| `voucher_used_doctor_voucher_table3_col1` | 0.26 (0.024) | 0.264222 | 1.62% | ±0.024 (se_band) | PASS | PASS |
| `any_malaria_treatment_prescribed_patient_voucher_table3_col2` | 0.052 (0.025) | 0.052492 | 0.95% | ±0.025 (se_band) | PASS | PASS |
| `any_malaria_treatment_prescribed_doctor_voucher_table3_col2` | 0.016 (0.025) | 0.016232 | 1.45% | ±0.025 (se_band) | PASS | PASS |
| `any_malaria_treatment_purchased_patient_voucher_table3_col3` | 0.14 (0.027) | 0.14091 | 0.65% | ±0.027 (se_band) | PASS | PASS |
| `any_malaria_treatment_purchased_doctor_voucher_table3_col3` | 0.085 (0.025) | 0.08549 | 0.58% | ±0.025 (se_band) | PASS | PASS |
| `severe_malaria_treatment_prescribed_patient_voucher_table3_col4` | -0.046 (0.018) | -0.044843 | 2.52% | ±0.018 (se_band) | PASS | PASS |
| `severe_malaria_treatment_prescribed_doctor_voucher_table3_col4` | -0.054 (0.021) | -0.054145 | 0.27% | ±0.021 (se_band) | PASS | PASS |
| `severe_malaria_treatment_purchased_patient_voucher_table3_col5` | -0.022 (0.02) | -0.02189 | 0.50% | ±0.02 (se_band) | PASS | PASS |
| `severe_malaria_treatment_purchased_doctor_voucher_table3_col5` | -0.05 (0.019) | -0.050268 | 0.54% | ±0.019 (se_band) | PASS | PASS |
| `n_obs_table3_col1` | 2055 | 2055 | 0.00% | ±102.75 (relative) | PASS | PASS |
| `n_obs_table3_cols2_5` | 2053 | 2053 | 0.00% | ±102.65 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Post-double-selection lasso implemented by hand in R (glmnet/hdm not available): rlasso-style rigorous plug-in penalty lambda = 2*1.1*sqrt(n)*qnorm(1-gamma/(2p)), gamma = 0.1/log(#clusters), clinic-cluster-robust penalty loadings iterated with post-lasso residuals (initial residuals from OLS on the 5 most correlated candidates). The authors' Stata lasso implementation (pdslasso vs dsregress, exact penalty constants) is unknown, so the selected control set may differ slightly.

Agent notes: Sample: dropme==0 (2,055 in-clinic patients; 2,053 with non-missing prescription/purchase outcomes). Outcomes: used_vouchers_admin (col 1), RXtreat_sev_simple_mal (col 2), treat_sev_simple_mal (col 3), RXtreat_severe_mal (col 4), treat_severe_mal (col 5). Treatments patient_voucher and doctor_voucher. Date fixed effects (DD1-DD35 dummies) partialled out before lasso and included in the final OLS. Candidate controls: the 23 prepared CC* individual controls (missings mean-coded, with missing dummies), their 249 pairwise interactions CCaxCCb, and 59 clinic dummies CL*. Union of controls selected in the lasso for y, PV and DV; final OLS via fixest with SEs clustered by clinic (cscomnum_OS). Attempts 1-2 were exploratory (variable listing, sample and outcome checks; no RESULT lines). The final run was the first estimation run; after comparing with the claims by eye, nothing was changed (all coefficients within about 0.002 of the paper, Ns exact, SEs also close). No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,421 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064343Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,050 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064343Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 292 bytes, from `benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/independent/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,196 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064343Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064343Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 100,657 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064343Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 272 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064343Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,837 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064343Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064343Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 6,759 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064343Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 272 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064343Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,036 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064343Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,520 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064343Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 85 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064343Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,150 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064343Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 273 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064343Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
