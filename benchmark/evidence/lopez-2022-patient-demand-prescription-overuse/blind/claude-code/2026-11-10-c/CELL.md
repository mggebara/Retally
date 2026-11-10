# lopez-2022-patient-demand-prescription-overuse · blind · claude-code · 2026-11-10-c

| | |
|---|---|
| Paper | `lopez-2022-patient-demand-prescription-overuse` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-c |
| Date | 2026-11-10T06:49:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run3-1paper-lopez-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064947Z` |
| Run directory | `benchmark/reproductions/lopez-2022-patient-demand-prescription-overuse/blind/2026-11-10-c` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 8/12 (execution 3) |
| Final | **8/12** |
| Package files withheld | 36 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `voucher_used_patient_voucher_table3_col1` | 0.35 (0.03) | 0.294839 | 15.76% | ±0.03 (se_band) | FAIL | FAIL |
| `voucher_used_doctor_voucher_table3_col1` | 0.26 (0.024) | 0.213482 | 17.89% | ±0.024 (se_band) | FAIL | FAIL |
| `any_malaria_treatment_prescribed_patient_voucher_table3_col2` | 0.052 (0.025) | 0.053725 | 3.32% | ±0.025 (se_band) | PASS | PASS |
| `any_malaria_treatment_prescribed_doctor_voucher_table3_col2` | 0.016 (0.025) | 0.025878 | 61.74% | ±0.025 (se_band) | PASS | PASS |
| `any_malaria_treatment_purchased_patient_voucher_table3_col3` | 0.14 (0.027) | 0.123841 | 11.54% | ±0.027 (se_band) | PASS | PASS |
| `any_malaria_treatment_purchased_doctor_voucher_table3_col3` | 0.085 (0.025) | 0.076115 | 10.45% | ±0.025 (se_band) | PASS | PASS |
| `severe_malaria_treatment_prescribed_patient_voucher_table3_col4` | -0.046 (0.018) | -0.035932 | 21.89% | ±0.018 (se_band) | PASS | PASS |
| `severe_malaria_treatment_prescribed_doctor_voucher_table3_col4` | -0.054 (0.021) | -0.050564 | 6.36% | ±0.021 (se_band) | PASS | PASS |
| `severe_malaria_treatment_purchased_patient_voucher_table3_col5` | -0.022 (0.02) | -0.0156 | 29.09% | ±0.02 (se_band) | PASS | PASS |
| `severe_malaria_treatment_purchased_doctor_voucher_table3_col5` | -0.05 (0.019) | -0.046596 | 6.81% | ±0.019 (se_band) | PASS | PASS |
| `n_obs_table3_col1` | 2055 | 2753 | 33.97% | ±102.75 (relative) | FAIL | FAIL |
| `n_obs_table3_cols2_5` | 2053 | 2429 | 18.31% | ±102.65 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/12 pass, which agrees with the row's 8/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Post-double-selection lasso implemented by hand (glmnet/hdm/lassopack unavailable): rigorous plug-in lasso following lassopack rlasso defaults as I understand them -- cluster-robust penalty loadings by clinic (psi_j = sqrt((1/N) sum_g (sum_{i in g} x_ij e_i)^2)), lambda = 2*1.1*sqrt(N)*qnorm(1 - gamma/(2p)) with gamma = 0.1/log(number of clusters), initial residuals from OLS on the 5 most correlated regressors, 2 loading iterations using post-lasso residuals. The authors' exact lasso implementation (pdslasso vs Stata dsregress, heteroskedastic vs cluster loadings, gamma) is not stated in the paper, so selected controls may differ.
- (reproduction.json) Candidate controls taken as the analysis file's prebuilt CC* variables (23 individual controls with missing values mean-recoded plus missing dummies, and their 249 pairwise interactions) and CL* clinic dummies (59); date dummies (DD*, plus constant) partialled out of all variables before the lassos and always included; final OLS with date fixed effects (date_morning_survey) and clinic-clustered SEs via fixest.
- (reproduction.json) Treatment dummies are patient_voucher and doctor_voucher (scheduled assignment) as in the analysis file; PI (information) cross-cut not controlled, pooled across arms as the paper's equation (1) describes.

Agent notes: Sample: rows with patient==1 (in-clinic survey patients, N=2753) for column 1 (outcome used_vouchers_admin, voucher redemption from admin records); columns 2-5 use the 2429 patients with prescription/purchase outcomes recorded (RXtreat_sev_simple_mal, treat_sev_simple_mal, RXtreat_severe_mal, treat_severe_mal). For each outcome, rlasso of y, patient_voucher and doctor_voucher on candidates; union of selections enters the final regression. Two exploratory runs (variable listing, sample/coding checks) printed no RESULT lines. The printed 'p(bP=bD)' diagnostic in stdout is actually fixest's joint Wald p-value for bP=bD=0 (mislabelled, not a scored quantity); the separate 't-test bP=bD' line is the equality test. No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,991 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064947Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,019 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064947Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 292 bytes, from `benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/blind/2026-11-10-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 928 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064947Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064947Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 416,700 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064947Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 266 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064947Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,346 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064947Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064947Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,256 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064947Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 266 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064947Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,569 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064947Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,449 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064947Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064947Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,172 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064947Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 266 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064947Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
