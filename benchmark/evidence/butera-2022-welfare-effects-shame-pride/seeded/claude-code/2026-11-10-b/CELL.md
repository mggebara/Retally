# butera-2022-welfare-effects-shame-pride · seeded · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `butera-2022-welfare-effects-shame-pride` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T14:35:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-butera-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/seeded/claude-code/20261110T142901Z` |
| Run directory | `benchmark/reproductions/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-b` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 13/13 |
| First scored | 13/13 (execution 1) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `public_recognition_points_prolific_table5_col1` | 105.01 (12.25) | 105.008 | 0.00% | ±2.1002 (relative) | PASS | PASS |
| `financial_incentives_points_prolific_table5_col1` | 185.74 (12.56) | 185.736 | 0.00% | ±3.7148 (relative) | PASS | PASS |
| `public_recognition_points_berkeley_table5_col2` | 134.41 (22.56) | 134.413 | 0.00% | ±2.6882 (relative) | PASS | PASS |
| `financial_incentives_points_berkeley_table5_col2` | 177.76 (22.04) | 177.756 | 0.00% | ±3.5552 (relative) | PASS | PASS |
| `public_recognition_points_bu_table5_col3` | 103.61 (45.25) | 103.611 | 0.00% | ±2.0722 (relative) | PASS | PASS |
| `financial_incentives_points_bu_table5_col3` | 118.33 (39.62) | 118.327 | 0.00% | ±2.3666 (relative) | PASS | PASS |
| `n_obs_prolific_table5_col1` | 2904 | 2904 | 0.00% | ±145.2 (relative) | PASS | PASS |
| `n_obs_berkeley_table5_col2` | 1152 | 1152 | 0.00% | ±57.6 (relative) | PASS | PASS |
| `n_obs_bu_table5_col3` | 354 | 354 | 0.00% | ±17.7 (relative) | PASS | PASS |
| `action_signaling_gamma1_berkeley_table7_panelA` | 0.3 | 0.299882 | 0.04% | ±0.006 (relative) | PASS | PASS |
| `action_signaling_rho_berkeley_table7_panelA` | 0.87 | 0.871269 | 0.15% | ±0.0174 (relative) | PASS | PASS |
| `cost_parameter_c_berkeley_table7_panelA` | 0.21 | 0.21441 | 2.10% | ±0.005 (printed_precision) | PASS | PASS |
| `predicted_financial_incentive_effect_berkeley_table7_panelC` | 2.33 | 2.33198 | 0.08% | ±0.0233 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Table 7 parameters are reported as full-sample point estimates only; the 1000-rep cluster bootstrap used for the paper's percentile CIs was not run (no CI is claimed).

Agent notes: Single run. Rebuilt the charity data from the raw CSVs following Prolific_Build/University_Build/Gen_Vars (attention-check flag = non-missing attention_check; consistent_b from preference switches; WTP = -anonymous slider WTP, else recognition slider WTP). Table 5: dropped participants with any round > 3000 points, kept flag_attention_check == 0 & consistent_b == 1, reshaped long by round, regressed pts on SR, ownpay and order dummies o1, o2 (order mapping from Label_Rounds.do) with id-clustered SEs, for Prolific, Berkeley, BU (bu_qm222). Table 7 Berkeley: as in welfare_estimates.do param_effort: tau and anonymous mean from pts/100; reduced-form PRU from OLS of WTP on interval midpoint (hundreds) and its square, intervals 0-16 (1700+ excluded), data long by id x round x interval as in the do-file; gamma2 = r2, gamma1 = sqrt(r1^2 - 4 r2 r0), rho = (gamma1 - r1)/(2 gamma2 pts_im), c = (r1 + 2 r2 pts_im)/tau, predicted FI effect = 0.5/c. All 13 values match the claims at reported precision. No result comparison led to script changes. Initial data inspection (column names, sample labels, conditions, attention-check counts) was done by reading the raw CSVs with a small host Python script, not R.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 177,260 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/seeded/claude-code/20261110T142901Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 769 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/seeded/claude-code/20261110T142901Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 273 bytes, from `benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-b/paper.txt`

## What it produced

- [`output/reproduction.json`](output/reproduction.json) — 1,826 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/seeded/claude-code/20261110T142901Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,549 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/seeded/claude-code/20261110T142901Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/seeded/claude-code/20261110T142901Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,330 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/seeded/claude-code/20261110T142901Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 260 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/seeded/claude-code/20261110T142901Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
