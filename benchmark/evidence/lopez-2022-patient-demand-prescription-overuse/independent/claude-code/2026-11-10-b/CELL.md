# lopez-2022-patient-demand-prescription-overuse · independent · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `lopez-2022-patient-demand-prescription-overuse` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T06:44:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-lopez-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064345Z` |
| Run directory | `benchmark/reproductions/lopez-2022-patient-demand-prescription-overuse/independent/2026-11-10-b` |
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
| `voucher_used_patient_voucher_table3_col1` | 0.35 (0.03) | 0.346459 | 1.01% | ±0.03 (se_band) | PASS | PASS |
| `voucher_used_doctor_voucher_table3_col1` | 0.26 (0.024) | 0.264222 | 1.62% | ±0.024 (se_band) | PASS | PASS |
| `any_malaria_treatment_prescribed_patient_voucher_table3_col2` | 0.052 (0.025) | 0.053159 | 2.23% | ±0.025 (se_band) | PASS | PASS |
| `any_malaria_treatment_prescribed_doctor_voucher_table3_col2` | 0.016 (0.025) | 0.016681 | 4.26% | ±0.025 (se_band) | PASS | PASS |
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

- (reproduction.json) Post-double-selection lasso implemented by hand in R (glmnet/hdm not installed): rigorous BCH penalty lambda = 2*1.1*sqrt(n)*qnorm(1-gamma/(2p)), gamma = 0.1/log(#clusters), clinic-cluster-robust penalty loadings iterated on post-lasso residuals (up to 15 iterations, initial residuals from OLS on the 5 most correlated candidates), date fixed effects partialled out before selection. This approximates Stata pdslasso/rlasso with cluster(); exact Stata defaults (e.g. psi-iteration count) may differ.

Agent notes: Sample: dropme==0 (N=2055; 2053 with non-missing treatment outcomes). Outcomes: used_vouchers_admin, RXtreat_sev_simple_mal, treat_sev_simple_mal, RXtreat_severe_mal, treat_severe_mal. Regressors patient_voucher, doctor_voucher; date FE (date_morning_survey); SEs clustered by cscomnum_OS. Candidate controls taken from the pre-built columns in the analysis file: clinic dummies CL1-CL59, individual controls CC* (mean-imputed, plus missing dummies CC28/CC34), and their pairwise interactions CCaxCCb (249). Union of selections from lasso of y, PV and DV on candidates; final OLS via fixest. All 10 coefficients and both Ns match the paper at reported precision (clustered SEs also match). attempt-1 was an exploratory variable listing (no RESULT lines). No claim-feedback iterations were needed. No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,421 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064345Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,050 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064345Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 292 bytes, from `benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/independent/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 767 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064345Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064345Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 262,343 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064345Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 272 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064345Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,827 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064345Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,930 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064345Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 85 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064345Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,136 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064345Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 273 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064345Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
