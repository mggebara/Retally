# lopez-2022-patient-demand-prescription-overuse · seeded · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `lopez-2022-patient-demand-prescription-overuse` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T06:43:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-lopez-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064333Z` |
| Run directory | `benchmark/reproductions/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 12/12 (execution 3) |
| Final | **12/12** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `voucher_used_patient_voucher_table3_col1` | 0.35 (0.03) | 0.346459 | 1.01% | ±0.007 (relative) | PASS | PASS |
| `voucher_used_doctor_voucher_table3_col1` | 0.26 (0.024) | 0.264222 | 1.62% | ±0.0052 (relative) | PASS | PASS |
| `any_malaria_treatment_prescribed_patient_voucher_table3_col2` | 0.052 (0.025) | 0.052492 | 0.95% | ±0.00104 (relative) | PASS | PASS |
| `any_malaria_treatment_prescribed_doctor_voucher_table3_col2` | 0.016 (0.025) | 0.016232 | 1.45% | ±0.0005 (printed_precision) | PASS | PASS |
| `any_malaria_treatment_purchased_patient_voucher_table3_col3` | 0.14 (0.027) | 0.14091 | 0.65% | ±0.005 (printed_precision) | PASS | PASS |
| `any_malaria_treatment_purchased_doctor_voucher_table3_col3` | 0.085 (0.025) | 0.08549 | 0.58% | ±0.0017 (relative) | PASS | PASS |
| `severe_malaria_treatment_prescribed_patient_voucher_table3_col4` | -0.046 (0.018) | -0.045509 | 1.07% | ±0.00092 (relative) | PASS | PASS |
| `severe_malaria_treatment_prescribed_doctor_voucher_table3_col4` | -0.054 (0.021) | -0.053749 | 0.46% | ±0.00108 (relative) | PASS | PASS |
| `severe_malaria_treatment_purchased_patient_voucher_table3_col5` | -0.022 (0.02) | -0.02189 | 0.50% | ±0.0005 (printed_precision) | PASS | PASS |
| `severe_malaria_treatment_purchased_doctor_voucher_table3_col5` | -0.05 (0.019) | -0.050268 | 0.54% | ±0.001 (relative) | PASS | PASS |
| `n_obs_table3_col1` | 2055 | 2055 | 0.00% | ±102.75 (relative) | PASS | PASS |
| `n_obs_table3_cols2_5` | 2053 | 2053 | 0.00% | ±102.65 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Stata's pdslasso/rlasso (lassopack) is not available in R (glmnet not installed either), so the rigorous cluster-robust lasso was re-implemented by hand: lassopack defaults c=1.1, gamma=0.1/log(number of clusters), lambda=2c*sqrt(N)*invnormal(1-gamma/(2p)), cluster-robust penalty loadings, initial residuals from OLS on the 5 most correlated regressors, 2 loading iterations with post-lasso residuals, date dummies and constant partialled out before selection; final post-double-selection OLS via fixest with date dummies and clinic-clustered SEs.
- (reproduction.json) The do-file clusters on `cscomnum`, which does not exist in the data; it is a Stata abbreviation that resolves to `cscomnum_OS` (the only variable with that prefix, 60 clinics), used here.

Agent notes: Table 3 of the paper (docpat_theory_lso in LSS_TablePrograms.do): pdslasso of each outcome on patient_voucher and doctor_voucher, penalized candidates CL1-CL59 and CC* (272 patient/respondent controls and interactions), DD1-DD35 partialled out, after dropping dropme==1 (2055 patients). Two exploratory runs (attempt-1, attempt-2) inspected variables and located the cluster variable; they printed no RESULT lines. The first estimating run is the final run; all 10 coefficients round to the published values and the clustered SEs also match the published table (e.g. 0.0307 vs 0.030, 0.0245 vs 0.024). N = 2055 (col 1) and 2053 (cols 2-5). No claim-feedback or error-repair iterations were needed. fixest dropped one selected control (CC23xCC27) as collinear in column 2, which does not affect the treatment coefficients.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 192,700 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064333Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 905 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064333Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 287 bytes, from `benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,590 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064333Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 171 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064333Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 6,507 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064333Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 267 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064333Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 588 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064333Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064333Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 16,378 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064333Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 267 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064333Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,132 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064333Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,811 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064333Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 85 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064333Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,598 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064333Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 267 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064333Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
