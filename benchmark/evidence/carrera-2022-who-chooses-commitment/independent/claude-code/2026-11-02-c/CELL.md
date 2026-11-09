# carrera-2022-who-chooses-commitment · independent · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:10:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T202751Z` |
| Run directory | `benchmark/reproductions/carrera-2022-who-chooses-commitment/independent/2026-11-02-c` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 11/11 (execution 2) |
| Final | **11/11** |
| Package files withheld | 29 |
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

Agent notes: attempt-1 was exploratory (variable listing, no RESULT lines). Final run: participant-level file cleaned_commitment_study_data.dta; sample drops flag_exclude_exog==1 and flag_low_wtp==1 (endogenous incentive assignment, 44 obs) and wave-3 threshold80_12 group, giving N=1126. Conservative BCP = mean over pairs (1,2),(2,3),(3,5),(5,7),(7,12) of (wtp_{k+1}-wtp_k)/delta - (days_k+days_{k+1})/2 (mean 1.17, info-control 0.66, matching the paper). Goal gap = goal - days_0; actual gap = visits - days_{assigned incentive}; z-scored over the 1126 sample (unstandardized mean/SD match the table notes). Table 3: OLS with wave FE, HC1 robust SEs (fixest). Table 4: stacked 'more' choices (q169==2 at 8, chose_commit12 at 12, q295==2 at 16; waves 1-2 three thresholds, wave 3 only 12) giving 2824 obs; LPM with wave and threshold FE, SEs clustered by participant (row index, as the participant file has no id column). No claim-driven changes were made; all estimates agree with Table 3/4 to the reported precision.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 24,360 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T202751Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 912 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T202751Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 270 bytes, from `benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/independent/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 916 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T202751Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T202751Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 17,336 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T202751Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,504 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T202751Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,645 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T202751Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T202751Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,675 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T202751Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
