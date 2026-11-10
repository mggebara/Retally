# lopez-2022-patient-demand-prescription-overuse · blind · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `lopez-2022-patient-demand-prescription-overuse` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T06:45:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-lopez-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064620Z` |
| Run directory | `benchmark/reproductions/lopez-2022-patient-demand-prescription-overuse/blind/2026-11-10-a` |
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
| `any_malaria_treatment_prescribed_patient_voucher_table3_col2` | 0.052 (0.025) | 0.05582 | 7.35% | ±0.025 (se_band) | PASS | PASS |
| `any_malaria_treatment_prescribed_doctor_voucher_table3_col2` | 0.016 (0.025) | 0.027122 | 69.51% | ±0.025 (se_band) | PASS | PASS |
| `any_malaria_treatment_purchased_patient_voucher_table3_col3` | 0.14 (0.027) | 0.123097 | 12.07% | ±0.027 (se_band) | PASS | PASS |
| `any_malaria_treatment_purchased_doctor_voucher_table3_col3` | 0.085 (0.025) | 0.075604 | 11.05% | ±0.025 (se_band) | PASS | PASS |
| `severe_malaria_treatment_prescribed_patient_voucher_table3_col4` | -0.046 (0.018) | -0.035958 | 21.83% | ±0.018 (se_band) | PASS | PASS |
| `severe_malaria_treatment_prescribed_doctor_voucher_table3_col4` | -0.054 (0.021) | -0.049603 | 8.14% | ±0.021 (se_band) | PASS | PASS |
| `severe_malaria_treatment_purchased_patient_voucher_table3_col5` | -0.022 (0.02) | -0.0156 | 29.09% | ±0.02 (se_band) | PASS | PASS |
| `severe_malaria_treatment_purchased_doctor_voucher_table3_col5` | -0.05 (0.019) | -0.046596 | 6.81% | ±0.019 (se_band) | PASS | PASS |
| `n_obs_table3_col1` | 2055 | 2753 | 33.97% | ±102.75 (relative) | FAIL | FAIL |
| `n_obs_table3_cols2_5` | 2053 | 2429 | 18.31% | ±102.65 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/12 pass, which agrees with the row's 8/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Post-double-selection lasso implemented by hand in R (no glmnet/pdslasso available): rlasso-style plug-in lasso with cluster-robust (clinic) penalty loadings, c=1.1, gamma=0.1/log(60 clusters), lambda=2c*sqrt(n)*qnorm(1-gamma/(2p)), initial residuals from OLS on the 5 most-correlated candidates, loadings iterated on post-lasso residuals (max 15 iterations). Exact Stata pdslasso/rlasso defaults could not be verified, so the selected control set may differ from the authors'.
- (reproduction.json) Date fixed effects (date_morning_survey) are partialled out of outcome, treatments and candidate controls before the lassos, and included in the final OLS; the final OLS uses the union of controls selected in the outcome, Patient Voucher and Doctor Voucher lassos (PDS OLS, not the CHS orthogonalized estimator).

Agent notes: Data: LSS_analysis_datasets_20201108.dta. Sample: in-clinic survey patients (patient==1, N=2753) for column 1; for columns 2-5 the patients with non-missing prescription/purchase outcomes (N=2429). Treatments: patient_voucher and doctor_voucher (assigned schedule). Outcomes: used_vouchers_admin (col 1, admin voucher match), RXtreat_sev_simple_mal (col 2), treat_sev_simple_mal (col 3), RXtreat_severe_mal (col 4), treat_severe_mal (col 5). Candidate controls: all pre-built CC* variables in the dataset (symptom dummies, illness duration and square, age and square, under-5, gender, pregnancy plus missing dummy, respondent dummies, Bambara plus missing dummy, French, literacy, primary education, in-home-survey, and their pairwise interactions; 272 columns) plus 59 clinic dummies CL*. SEs clustered by clinic (cscomnum_OS) via fixest. Two exploratory runs (attempt-1, attempt-2) inspected variables only and printed no RESULT lines. The final script's diagnostic print line contains a leftover p-value expression that prints NA (cosmetic only, does not affect any RESULT). The diagnostic output also prints Control-group outcome means; these came out lower than the Control means printed in the paper's Table 3 notes (seen in the paper text while reading the method), which may mean the authors' cols 2-5 sample or outcome coding differs from mine. The specification was not changed in response. No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,991 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064620Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,019 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064620Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 292 bytes, from `benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/blind/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,147 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064620Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064620Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 547,802 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064620Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 266 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064620Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,568 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064620Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064620Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 4,593 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064620Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 266 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064620Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,776 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064620Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,173 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064620Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064620Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,129 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064620Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 267 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/claude-code/20261110T064620Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
