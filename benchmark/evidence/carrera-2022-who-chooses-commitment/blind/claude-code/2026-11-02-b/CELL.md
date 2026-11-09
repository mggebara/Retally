# carrera-2022-who-chooses-commitment · blind · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T07:20:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-4papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T090911Z` |
| Run directory | `benchmark/reproductions/carrera-2022-who-chooses-commitment/blind/2026-11-02-b` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 11/11 (execution 3) |
| Final | **11/11** |
| Package files withheld | 28 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `bcp_basic_info_treatment_col1` | 0.3 (0.56) | 0.300805 | 0.27% | ±0.56 (se_band) | PASS | PASS |
| `bcp_enhanced_info_treatment_col1` | 1.36 (0.57) | 1.35968 | 0.02% | ±0.57 (se_band) | PASS | PASS |
| `bcp_goal_minus_expected_attendance_col2` | 0.71 (0.29) | 0.707612 | 0.34% | ±0.29 (se_band) | PASS | PASS |
| `bcp_actual_minus_expected_attendance_col3` | 0.45 (0.22) | 0.447487 | 0.56% | ±0.22 (se_band) | PASS | PASS |
| `bcp_regression_observations` | 1126 | 1126 | 0.00% | ±56.3 (relative) | PASS | PASS |
| `takeup_more_basic_info_treatment_col1` | -0.022 (0.041) | -0.021511 | 2.22% | ±0.041 (se_band) | PASS | PASS |
| `takeup_more_enhanced_info_treatment_col1` | -0.08 (0.031) | -0.080176 | 0.22% | ±0.031 (se_band) | PASS | PASS |
| `takeup_more_behavior_change_premium_col2` | 0.027 (0.011) | 0.026744 | 0.95% | ±0.011 (se_band) | PASS | PASS |
| `takeup_more_goal_minus_expected_attendance_col3` | 0.038 (0.013) | 0.03821 | 0.55% | ±0.013 (se_band) | PASS | PASS |
| `takeup_more_actual_minus_expected_attendance_col4` | -0.043 (0.013) | -0.042759 | 0.56% | ±0.013 (se_band) | PASS | PASS |
| `takeup_more_regression_observations` | 2824 | 2824 | 0.00% | ±141.2 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Data: cleaned_commitment_study_data.dta (participant level). Sample: dropped the 44 endogenous-assignment cases (flag_exclude_exog=12, flag_low_wtp=32) and the 122 remaining wave-3 participants assigned threshold80_12, leaving N=1126. Conservative BCP = mean over the pairs (1,2),(2,3),(3,5),(5,7),(7,12) of (wtp_{k+1}-wtp_k)/(p_{k+1}-p_k) - (days_k+days_{k+1})/2; wtp already includes the fill-in WTP above the slider maximum. Info dummies come from type_of_info (1-onlygraph = basic, 2-graphplus = enhanced). Goal gap = goal - days_0. Actual gap = visits - days_{assigned incentive}. Gaps and BCP are z-scored over the 1126-participant sample. Table 3: feols with wavenum fixed effects and HC1 SEs. Table 4: stacked 'more' choices (q169==2 for >=8, chose_commit12==1 for 12, q295==2 for >=16; waves 1-2 have all three, wave 3 only 12), giving 2824 rows; wavenum + threshold fixed effects, SEs clustered by participant. q169/q295 coding (2 = chose the contract) was inferred from how they cross-tabulate with chose_commit12. Attempts 1-2 were exploratory (variable inspection, flags, coding), with no estimates and no RESULT lines.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 24,440 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T090911Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 881 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T090911Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 270 bytes, from `benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/blind/2026-11-02-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 897 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T090911Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 72 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T090911Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 15,378 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T090911Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,216 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T090911Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T090911Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,165 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T090911Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,677 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T090911Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,972 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T090911Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T090911Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,499 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T090911Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
