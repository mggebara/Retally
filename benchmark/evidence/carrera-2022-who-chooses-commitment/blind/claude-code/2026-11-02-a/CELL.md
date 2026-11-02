# carrera-2022-who-chooses-commitment · blind · claude-code · 2026-11-02-a

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-a |
| Date | 2026-11-02T05:52:30Z |
| Results file | `benchmark/results/claude-code-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T062002Z` |
| Run directory | `benchmark/reproductions/carrera-2022-who-chooses-commitment/blind/2026-11-02-a` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 11/11 (execution 2) |
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
| `bcp_regression_observations` | 1126 | 1126 | 0.00% | ±11.26 (relative) | PASS | PASS |
| `takeup_more_basic_info_treatment_col1` | -0.022 (0.041) | -0.021511 | 2.22% | ±0.041 (se_band) | PASS | PASS |
| `takeup_more_enhanced_info_treatment_col1` | -0.08 (0.031) | -0.080176 | 0.22% | ±0.031 (se_band) | PASS | PASS |
| `takeup_more_behavior_change_premium_col2` | 0.027 (0.011) | 0.026744 | 0.95% | ±0.011 (se_band) | PASS | PASS |
| `takeup_more_goal_minus_expected_attendance_col3` | 0.038 (0.013) | 0.03821 | 0.55% | ±0.013 (se_band) | PASS | PASS |
| `takeup_more_actual_minus_expected_attendance_col4` | -0.043 (0.013) | -0.042759 | 0.56% | ±0.013 (se_band) | PASS | PASS |
| `takeup_more_regression_observations` | 2824 | 2824 | 0.00% | ±28.24 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Subject identifier for clustering in Table 4 is the participant row in cleaned_commitment_study_data.dta (one row per participant; no id column in that file).

Agent notes: attempt-1 was exploratory (variable listing, no RESULT lines). Final: participant-level data; dropped the 44 endogenous-assignment cases (flag_exclude_exog, flag_low_wtp) and wave-3 participants assigned the $80/12-visit contract, leaving N=1126. Conservative BCP = per-participant mean over pairs (1,2),(2,3),(3,5),(5,7),(7,12) of [wtp(q)-wtp(p)]/(q-p) - [days_p+days_q]/2. Goal gap = goal - days_0; actual gap = visits - days_{assigned incentive}; z-scored on the regression sample. Table 3: OLS on basic (wave 1 graph) and enhanced (waves 2-3) info dummies + wave FE, HC1 SEs. Table 4: stacked 'more' choices (q169==2 for >=8, chose_commit12 for >=12, q295==2 for >=16; waves 1-2 all three thresholds, wave 3 only 12), wave + threshold FE, SEs clustered by participant; N=2824. Sanity checks against values the paper reports as definitions (goal-gap mean 3.34/SD 3.64, actual-gap SD 6.61, info-control BCP mean 0.66, take-up 64/49/32%) matched; nothing was tuned.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 24,440 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T062002Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 881 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T062002Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 270 bytes, from `benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/blind/2026-11-02-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 531 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T062002Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 282 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T062002Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 19,125 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T062002Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,625 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T062002Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,227 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T062002Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T062002Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,630 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/claude-code/20261102T062002Z/stdout.txt`
