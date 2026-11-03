# carrera-2022-who-chooses-commitment · independent · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T07:04:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-4papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T090910Z` |
| Run directory | `benchmark/reproductions/carrera-2022-who-chooses-commitment/independent/2026-11-02-b` |
| Executions | 3 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 0/11 |
| First scored | 7/11 (execution 2) |
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
| `takeup_more_enhanced_info_treatment_col1` | -0.08 (0.031) | -0.080176 | 0.22% | ±0.031 (se_band) | PASS | FAIL |
| `takeup_more_behavior_change_premium_col2` | 0.027 (0.011) | 0.026744 | 0.95% | ±0.011 (se_band) | PASS | FAIL |
| `takeup_more_goal_minus_expected_attendance_col3` | 0.038 (0.013) | 0.03821 | 0.55% | ±0.013 (se_band) | PASS | FAIL |
| `takeup_more_actual_minus_expected_attendance_col4` | -0.043 (0.013) | -0.042759 | 0.56% | ±0.013 (se_band) | PASS | FAIL |
| `takeup_more_regression_observations` | 2824 | 2824 | 0.00% | ±141.2 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Participant-level file cleaned_commitment_study_data.dta. Sample: drop the 44 endogenous-assignment flags (flag_exclude_exog, flag_low_wtp) and the wave-3 threshold80_12 group -> 1126. Conservative BCP = per-participant mean over pairs (1,2),(2,3),(3,5),(5,7),(7,12) of (wtp_hi - wtp_lo)/(hi - lo) - (days_lo + days_hi)/2. Goal gap = goal - days_0; actual gap = visits - forecast under the assigned incentive; both (and the BCP in Table 4) z-scored over the 1126 sample. Table 3: OLS with wave FE, HC1 SEs. Table 4: long participant-by-threshold 'more' choices (8/12/16 in waves 1-2 from q169/chose_commit12/q295, 12 only in wave 3) -> 2824 rows; LPM with wave and threshold FE, SEs clustered by participant. Attempt-1 was exploratory (no RESULT lines). Attempt-2 coded q169/q295 == 1 as take-up; Table 3 matched but Table 4 was off, and the 8/16 take-up rates were the reverse of the paper's 64%/32%. Recoding take-up as == 2 reproduced all Table 4 claims. Final run: all 11 claims within tolerance.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 23,865 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T090910Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 912 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T090910Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 270 bytes, from `benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/independent/2026-11-02-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,099 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T090910Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T090910Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 13,979 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T090910Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 441 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T090910Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 4,273 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T090910Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T090910Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,685 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T090910Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,556 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T090910Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,455 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T090910Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T090910Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,716 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/claude-code/20261102T090910Z/stdout.txt`
