# lopez-2022-patient-demand-prescription-overuse · blind · claude-code · 2026-11-10-d

| | |
|---|---|
| Paper | `lopez-2022-patient-demand-prescription-overuse` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-d |
| Date | 2026-11-10T07:20:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run4-1paper-lopez-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064949Z` |
| Run directory | `benchmark/reproductions/lopez-2022-patient-demand-prescription-overuse/blind/2026-11-10-d` |
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

- (reproduction.json) Post-double-selection lasso implemented by hand (no glmnet/hdm/lassopack in the sandbox): rigorous plug-in penalty lambda = 2*1.1*sqrt(N)*qnorm(1-gamma/(2p)), gamma = 0.1/log(number of clinics), cluster-robust (clinic) penalty loadings, initial residuals from OLS on the 5 most correlated regressors, loadings iterated with post-lasso residuals (up to 15 iterations). Exact Stata (pdslasso/rlasso) penalty conventions may differ, which can change the selected control set.
- (reproduction.json) Date fixed effects partialled out (within-date demeaning) of outcome, treatments and candidates before the lasso steps; they enter the final OLS unpenalised.

Agent notes: Sample: dropme==0 (2,055 patients; 60 clinics; 36 dates). Treatments: patient_voucher (PV and PI-PV days) and doctor_voucher (DV and PI-DV days); control-group omitted category. Outcomes: col1 used_vouchers_admin, col2 RXtreat_sev_simple_mal, col3 treat_sev_simple_mal, col4 RXtreat_severe_mal, col5 treat_severe_mal (2 obs missing prescription records -> N=2053). Candidate controls: 59 clinic dummies (CL*), 23 prepared individual controls with missings mean-recoded and missing dummies (CC1..CC41), and the 249 prepared pairwise interactions (CCaxCCb) in the analysis file. Union of controls selected by lasso of y, PV and DV on candidates; final OLS via fixest with date FE, SEs clustered by clinic (cscomnum_OS). attempt-1 was an exploratory variable listing (no RESULT lines). No runs hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,991 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064949Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,019 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064949Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 292 bytes, from `benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/blind/2026-11-10-d/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 972 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064949Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 68 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064949Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 354,750 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064949Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 266 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064949Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,945 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064949Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,825 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064949Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 85 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064949Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,131 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064949Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 266 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064949Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
