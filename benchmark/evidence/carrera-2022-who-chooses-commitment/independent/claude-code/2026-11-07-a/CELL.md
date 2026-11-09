# carrera-2022-who-chooses-commitment · independent · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T18:58:12Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261107T194824Z` |
| Run directory | `benchmark/reproductions/carrera-2022-who-chooses-commitment/independent/2026-11-07-a` |
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

Agent notes: Two exploratory runs (variable listing; flag counts, sample size, proxy means/SDs), then a single estimating run. Sample: cleaned_commitment_study_data.dta minus flag_exclude_exog==1 or flag_low_wtp==1 (44) minus treatment threshold80_12 (122) = 1126. BCP = mean over adjacent pairs (1,2),(2,3),(3,5),(5,7),(7,12) of (wtp_{k+1}-wtp_k)/dp - (days_k+days_{k+1})/2 (mean 1.17, control mean 0.66, as in the paper). Proxies: goal - days_0, and visits - days_<assigned incentive>; these and the BCP are z-scored over the 1126 sample (the unstandardized means and SDs match the table notes). Table 3: feols with wave FE and HC1 SEs. Table 4: long panel of 'more' choices (q169/q295 coded 2 = chose; chose_commit12), with wave and threshold FE and SEs clustered by participant, N = 2824. The coefficients and SEs match Tables 3 and 4 to the reported rounding. No claim comparison was done before the final run. The author scripts were not opened (the Code/ folders in the mount are empty).

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 24,635 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261107T194824Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 912 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261107T194824Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 270 bytes, from `benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/independent/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 607 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261107T194824Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 210 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261107T194824Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 12,197 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261107T194824Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 261 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261107T194824Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,213 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261107T194824Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 210 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261107T194824Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 851 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261107T194824Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 261 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261107T194824Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,532 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261107T194824Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,667 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261107T194824Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261107T194824Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,494 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261107T194824Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 262 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261107T194824Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
