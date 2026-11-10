# lopez-2022-patient-demand-prescription-overuse · independent · claude-code · 2026-11-10-d

| | |
|---|---|
| Paper | `lopez-2022-patient-demand-prescription-overuse` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-d |
| Date | 2026-11-10T06:48:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run4-1paper-lopez-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064945Z` |
| Run directory | `benchmark/reproductions/lopez-2022-patient-demand-prescription-overuse/independent/2026-11-10-d` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 12/12 (execution 2) |
| Final | **12/12** |
| Package files withheld | 36 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `voucher_used_patient_voucher_table3_col1` | 0.35 (0.03) | 0.347202 | 0.80% | ±0.03 (se_band) | PASS | PASS |
| `voucher_used_doctor_voucher_table3_col1` | 0.26 (0.024) | 0.267265 | 2.79% | ±0.024 (se_band) | PASS | PASS |
| `any_malaria_treatment_prescribed_patient_voucher_table3_col2` | 0.052 (0.025) | 0.062407 | 20.01% | ±0.025 (se_band) | PASS | PASS |
| `any_malaria_treatment_prescribed_doctor_voucher_table3_col2` | 0.016 (0.025) | 0.026254 | 64.09% | ±0.025 (se_band) | PASS | PASS |
| `any_malaria_treatment_purchased_patient_voucher_table3_col3` | 0.14 (0.027) | 0.149031 | 6.45% | ±0.027 (se_band) | PASS | PASS |
| `any_malaria_treatment_purchased_doctor_voucher_table3_col3` | 0.085 (0.025) | 0.09117 | 7.26% | ±0.025 (se_band) | PASS | PASS |
| `severe_malaria_treatment_prescribed_patient_voucher_table3_col4` | -0.046 (0.018) | -0.037499 | 18.48% | ±0.018 (se_band) | PASS | PASS |
| `severe_malaria_treatment_prescribed_doctor_voucher_table3_col4` | -0.054 (0.021) | -0.047642 | 11.77% | ±0.021 (se_band) | PASS | PASS |
| `severe_malaria_treatment_purchased_patient_voucher_table3_col5` | -0.022 (0.02) | -0.014017 | 36.29% | ±0.02 (se_band) | PASS | PASS |
| `severe_malaria_treatment_purchased_doctor_voucher_table3_col5` | -0.05 (0.019) | -0.044773 | 10.45% | ±0.019 (se_band) | PASS | PASS |
| `n_obs_table3_col1` | 2055 | 2055 | 0.00% | ±102.75 (relative) | PASS | PASS |
| `n_obs_table3_cols2_5` | 2053 | 2053 | 0.00% | ±102.65 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Post-double-selection lasso implemented by hand in R (glmnet/hdm not installed): rigorous plug-in lasso with heteroskedastic penalty loadings, lambda = 2*1.1*sqrt(n)*qnorm(1-gamma/(2p)), gamma = 0.1/log(n), initial residuals from OLS on the 5 most correlated candidates, post-lasso residuals for loading updates (up to 15 iterations); date fixed effects and constant partialled out before selection. This mimics Stata pdslasso/rlasso defaults; exact selected sets may differ from the authors' software.
- (reproduction.json) Candidate controls taken from the pre-built variables in the analysis file: CC* (individual controls with missing values set to the sample mean, plus missing dummies), CC*xCC* pairwise interactions, CL* clinic dummies.

Agent notes: Sample: LSS_analysis_datasets_20201108.dta restricted to dropme==0 (2,055 in-clinic patients; 2,053 with nonmissing prescription/purchase outcomes). Outcomes: used_vouchers_admin (col 1), RXtreat_sev_simple_mal, treat_sev_simple_mal, RXtreat_severe_mal, treat_severe_mal (cols 2-5). Treatments: patient_voucher, doctor_voucher (assigned schedule). Final OLS: y on PV, DV, union of lasso-selected controls (from lassos of y, PV and DV on the candidates), date FE (date_morning_survey), SEs clustered by clinic (cscomnum_OS). Control-group means match the paper exactly (0.616, 0.461, 0.303, 0.255). attempt-1 was an exploratory variable listing (no RESULT lines). The first scored run was compared with the claims via check_attempt ('All claims within tolerance') and kept unchanged as the final run, so no claim attempt is recorded. No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,421 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064945Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,050 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064945Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 292 bytes, from `benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/independent/2026-11-10-d/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 826 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064945Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064945Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 353,369 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064945Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 272 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064945Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,091 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064945Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,756 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064945Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064945Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,852 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064945Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 273 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064945Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
