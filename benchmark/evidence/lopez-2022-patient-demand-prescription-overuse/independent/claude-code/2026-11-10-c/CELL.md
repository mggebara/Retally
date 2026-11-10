# lopez-2022-patient-demand-prescription-overuse · independent · claude-code · 2026-11-10-c

| | |
|---|---|
| Paper | `lopez-2022-patient-demand-prescription-overuse` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-c |
| Date | 2026-11-10T06:48:19Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run3-1paper-lopez-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064944Z` |
| Run directory | `benchmark/reproductions/lopez-2022-patient-demand-prescription-overuse/independent/2026-11-10-c` |
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

- (reproduction.json) glmnet/lassopack are not available, so the post-double-selection lasso is a hand-written rigorous (plug-in) lasso in the style of Stata's lassopack rlasso/pdslasso: coordinate descent, cluster-robust (clinic) penalty loadings iterated on post-lasso residuals (initialised from OLS on the 5 most correlated regressors), lambda = 2*1.1*sqrt(N)*qnorm(1-gamma/(2p)), gamma = 0.1/log(N_clusters). The exact Stata penalty settings used by the authors are not stated in the paper, so selected controls may differ slightly from theirs.

Agent notes: Sample: dropme==0 in LSS_analysis_datasets_20201108.dta (2055 in-clinic interviews; 2053 with prescription/purchase outcomes). Outcomes: used_vouchers_admin, RXtreat_sev_simple_mal, treat_sev_simple_mal, RXtreat_severe_mal, treat_severe_mal (control-group means match Table 3 exactly: 0.616/0.461/0.303/0.255). Treatments: patient_voucher, doctor_voucher (PI cross-cut not controlled, as in eq. 1). Candidate controls: the dataset's pre-built CC* individual controls (missings mean-coded plus missing dummies), their pairwise CCxCC interactions, and CL* clinic dummies (331 in all). Date FE (date_morning_survey) partialled out before the lasso; lasso run for the outcome, PV and DV separately and the union of selected controls used in an OLS with date FE and clinic-clustered SEs (fixest). Attempts 1-2 were exploratory (variable listing, sample counts), no RESULT lines. The first estimating run (final) matched all claims to reported precision except severe-prescribed PV (-0.0448 vs -0.046); no claim-driven changes were made. No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,421 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064944Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,050 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064944Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 292 bytes, from `benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/independent/2026-11-10-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 515 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064944Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064944Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 259,338 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064944Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 272 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064944Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,079 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064944Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064944Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 935 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064944Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 272 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064944Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,143 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064944Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,178 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064944Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 85 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064944Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,750 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064944Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 273 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/claude-code/20261110T064944Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
