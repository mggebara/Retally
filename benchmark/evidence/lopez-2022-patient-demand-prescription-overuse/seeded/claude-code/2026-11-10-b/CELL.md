# lopez-2022-patient-demand-prescription-overuse · seeded · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `lopez-2022-patient-demand-prescription-overuse` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T06:44:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-lopez-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064342Z` |
| Run directory | `benchmark/reproductions/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-b` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 11/12 (execution 3) |
| Final | **11/12** |
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
| `severe_malaria_treatment_prescribed_patient_voucher_table3_col4` | -0.046 (0.018) | -0.044843 | 2.52% | ±0.00092 (relative) | FAIL | FAIL |
| `severe_malaria_treatment_prescribed_doctor_voucher_table3_col4` | -0.054 (0.021) | -0.054145 | 0.27% | ±0.00108 (relative) | PASS | PASS |
| `severe_malaria_treatment_purchased_patient_voucher_table3_col5` | -0.022 (0.02) | -0.02189 | 0.50% | ±0.0005 (printed_precision) | PASS | PASS |
| `severe_malaria_treatment_purchased_doctor_voucher_table3_col5` | -0.05 (0.019) | -0.050268 | 0.54% | ±0.001 (relative) | PASS | PASS |
| `n_obs_table3_col1` | 2055 | 2055 | 0.00% | ±102.75 (relative) | PASS | PASS |
| `n_obs_table3_cols2_5` | 2053 | 2053 | 0.00% | ±102.65 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/12 pass, which agrees with the row's 11/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Stata's pdslasso/rlasso (lassopack) is not available in R; the post-double-selection lasso was re-implemented by hand: rlasso with cluster-robust (by clinic) penalty loadings, lambda = 2*1.1*sqrt(N)*qnorm(1-gamma/(2p)) with gamma = 0.1/log(number of clusters), initial residuals from the 5 most correlated controls, up to 15 loading iterations using post-lasso residuals, coordinate-descent lasso. Date dummies DD1-DD35 and the constant are partialled out (unpenalised, always kept). Final OLS of the outcome on the voucher dummies, date dummies and the union of selected controls with clinic-clustered SEs (fixest). Small details of lassopack's defaults may differ from this implementation.

Agent notes: Followed docpat_theory_lso in LSS_TablePrograms.do for Table 3: drop dropme==1 (N=2055), pdslasso y patient_voucher doctor_voucher (DD1-DD35 CL1-CL59 CC*), clu(cscomnum) partial(DD1-DD35). The clustering variable 'cscomnum' does not exist in the data; it is Stata's unambiguous abbreviation of cscomnum_OS (60 clinics), which was used. attempt-1 and attempt-2 were exploratory (variable inspection; attempt-1 found cscomnum missing, attempt-2 located cscomnum_OS). The first estimating run became the final run unchanged; it reproduces all 10 coefficients and both Ns (2055, 2053) to the table's displayed precision except severe malaria prescribed, Patient Voucher (-0.0448 vs -0.046). Clustered SEs also match the table. No claim-driven revisions were made. All sandbox runs completed in seconds; nothing hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 192,700 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064342Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 905 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064342Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 287 bytes, from `benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,555 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064342Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 171 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064342Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,753 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064342Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 267 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064342Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 628 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064342Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064342Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 6,612 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064342Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 267 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064342Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,070 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064342Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,205 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064342Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 85 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064342Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,595 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064342Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 268 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/claude-code/20261110T064342Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
