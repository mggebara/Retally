# lopez-2022-patient-demand-prescription-overuse · blind · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `lopez-2022-patient-demand-prescription-overuse` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T06:49:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-lopez-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z` |
| Run directory | `benchmark/reproductions/lopez-2022-patient-demand-prescription-overuse/blind/2026-11-10-b` |
| Executions | 4 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 8/12 (execution 4) |
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

- (reproduction.json) Post-double-selection lasso implemented by hand in base R (coordinate descent) because glmnet/hdm/lassopack are not available; it follows Stata lassopack rlasso/pdslasso defaults as best known: date FE and constant partialled out, standardized controls, lambda = 2*1.1*sqrt(N)*qnorm(1-gamma/(2p)), cluster-robust (clinic) penalty loadings with gamma = 0.1/log(number of clinics), initial residuals from OLS on the 5 most correlated controls, 2 lasso-based loading updates with post-lasso residuals. The exact options the authors passed to pdslasso (heteroskedastic vs cluster loadings, gamma, iterations) are not stated in the paper, so selected controls may differ slightly.
- (reproduction.json) Candidate controls taken from the dataset's pre-built control set: CC* main effects (23 patient/respondent controls, mean-imputed, with missing dummies), their 249 pairwise interactions CCixCCj, and 59 clinic dummies CL1-CL59 (331 candidates), matching the Table 3 notes.

Agent notes: Data: LSS_analysis_datasets_20201108.dta only. Sample: in-clinic survey patients (patient==1), N=2753 for voucher use (used_vouchers_admin, administrative match); N=2429 for columns 2-5 (non-missing prescription/purchase outcomes). Outcomes: col2 RXtreat_sev_simple_mal, col3 treat_sev_simple_mal, col4 RXtreat_severe_mal, col5 treat_severe_mal. Treatments: patient_voucher, doctor_voucher (control days omitted). Date FE = date_morning_survey (36 dates); final OLS via fixest with date FE, the union of lasso-selected controls, SEs clustered by clinic (cscomnum_OS, 60 clinics). attempt-1 and attempt-2 were exploratory (variable listing, sample flags; no RESULT lines). attempt-3 crashed on a diagnostic p-value call (fixest::wald syntax) before printing RESULT lines; fixed by computing the p-value by hand, estimates unchanged. No runs hung. No author scripts, result tables (.tex), logs or PDFs from the package were opened. The no-controls version of equation (1) is printed in stdout for reference only.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,991 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,019 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 292 bytes, from `benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/blind/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 708 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 302,555 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 266 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,057 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 14,218 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 266 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/attempt-2/timing.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 291 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 8,175 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 172 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 240 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 266 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/attempt-3/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,589 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/reproduction.json`
- [`output/script.R`](output/script.R) — 8,425 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,826 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 267 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064946Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
