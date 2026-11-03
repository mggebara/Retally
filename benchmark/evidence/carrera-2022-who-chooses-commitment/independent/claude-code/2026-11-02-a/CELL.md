# carrera-2022-who-chooses-commitment · independent · claude-code · 2026-11-02-a

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-a |
| Date | 2026-11-02T05:52:13Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T062001Z` |
| Run directory | `benchmark/reproductions/carrera-2022-who-chooses-commitment/independent/2026-11-02-a` |
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

Agent notes: attempt-1 was exploratory: it printed variable names, labels and summaries, and no RESULT lines. The final script reads cleaned_commitment_study_data.dta. It drops the 44 endogenously assigned participants (flag_exclude_exog or flag_low_wtp), leaving 1248, then drops the wave-3 threshold80_12 assignees, leaving 1126. The conservative BCP is the mean over the pairs (1,2),(2,3),(3,5),(5,7),(7,12) of (wtp_{k+1}-wtp_k)/Delta - (days_k+days_{k+1})/2. Goal-exp is goal - days_0; actual-exp is visits - days_{assigned incentive}. Both are z-scored over the 1126 sample, and the unstandardized means and SDs match the table notes (3.34/3.64 and -4.17/6.61). Table 3 is OLS with wave FE and HC1 SEs (fixest). Table 4 is an LPM on the long data: q169==2 (8+) and q295==2 (16+) for waves 1-2, and chose_commit12 for all waves. It has wave and threshold FE, SEs clustered by participant, and N=2824. All estimates match the paper's tables to the reported precision. The comparison with the claims was made after the final run and the script was not changed.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 23,865 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T062001Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 912 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T062001Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 270 bytes, from `benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/independent/2026-11-02-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 785 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T062001Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 210 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T062001Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 13,270 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T062001Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,546 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T062001Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,128 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T062001Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T062001Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,696 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T062001Z/stdout.txt`
