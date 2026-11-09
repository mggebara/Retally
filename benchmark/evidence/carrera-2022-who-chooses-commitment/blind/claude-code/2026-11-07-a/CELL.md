# carrera-2022-who-chooses-commitment · blind · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T19:14:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261107T194821Z` |
| Run directory | `benchmark/reproductions/carrera-2022-who-chooses-commitment/blind/2026-11-07-a` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 11/11 (execution 3) |
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

Agent notes: Independent blind reproduction from paper text only; no author scripts or output files opened. Data: cleaned_commitment_study_data.dta (participant level). Attempts 1-2 were exploratory (variable listing; coding of flags and contract choice variables; q169/q295 coded 2 = chose the 'more' contract, chose_commit12 coded 1 = chose). Sample: drop the 44 endogenous-assignment participants (flag_exclude_exog==1 or flag_low_wtp==1) and the 122 remaining wave-3 participants assigned the $80-for-12-visits contract -> 1126 participants. BCP (conservative): per participant, mean over the pairs $1-2, $2-3, $3-5, $5-7, $7-12 of (WTP increase / incentive increase) minus the average of the forecasted attendance (days_k) at the two incentives; WTP variables already include fill-in-the-blank amounts. Goal gap = goal - days_0; actual gap = visits - days_{assigned incentive}; both (and BCP for Table 4) z-scored over the 1126-participant sample (sample SD). Table 3: OLS with wave FE, HC1 robust SEs; Table 4: stacked participant x threshold LPM (8/12/16 in waves 1-2, 12 in wave 3; 2824 obs) with wave and threshold FE, SEs clustered by participant. flag_confusion was not used as an exclusion (paper does not mention it for these tables).

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 25,210 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261107T194821Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 881 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261107T194821Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 283 bytes, from `benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/blind/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,019 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261107T194821Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261107T194821Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 14,745 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261107T194821Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 255 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261107T194821Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 871 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261107T194821Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261107T194821Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,160 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261107T194821Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 255 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261107T194821Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,779 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261107T194821Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,077 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261107T194821Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261107T194821Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,628 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261107T194821Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 256 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261107T194821Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
