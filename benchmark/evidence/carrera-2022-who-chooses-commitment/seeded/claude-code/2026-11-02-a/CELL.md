# carrera-2022-who-chooses-commitment · seeded · claude-code · 2026-11-02-a

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-a |
| Date | 2026-11-02T05:52:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/seeded/claude-code/20261102T061959Z` |
| Run directory | `benchmark/reproductions/carrera-2022-who-chooses-commitment/seeded/2026-11-02-a` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 11/11 (execution 2) |
| Final | **11/11** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `bcp_basic_info_treatment_col1` | 0.3 (0.56) | 0.300805 | 0.27% | ±0.006 (relative) | PASS | PASS |
| `bcp_enhanced_info_treatment_col1` | 1.36 (0.57) | 1.35968 | 0.02% | ±0.0272 (relative) | PASS | PASS |
| `bcp_goal_minus_expected_attendance_col2` | 0.71 (0.29) | 0.707612 | 0.34% | ±0.0142 (relative) | PASS | PASS |
| `bcp_actual_minus_expected_attendance_col3` | 0.45 (0.22) | 0.447487 | 0.56% | ±0.009 (relative) | PASS | PASS |
| `bcp_regression_observations` | 1126 | 1126 | 0.00% | ±56.3 (relative) | PASS | PASS |
| `takeup_more_basic_info_treatment_col1` | -0.022 (0.041) | -0.021511 | 2.22% | ±0.0005 (printed_precision) | PASS | PASS |
| `takeup_more_enhanced_info_treatment_col1` | -0.08 (0.031) | -0.080176 | 0.22% | ±0.0016 (relative) | PASS | PASS |
| `takeup_more_behavior_change_premium_col2` | 0.027 (0.011) | 0.026744 | 0.95% | ±0.00054 (relative) | PASS | PASS |
| `takeup_more_goal_minus_expected_attendance_col3` | 0.038 (0.013) | 0.03821 | 0.55% | ±0.00076 (relative) | PASS | PASS |
| `takeup_more_actual_minus_expected_attendance_col4` | -0.043 (0.013) | -0.042759 | 0.56% | ±0.00086 (relative) | PASS | PASS |
| `takeup_more_regression_observations` | 2824 | 2824 | 0.00% | ±141.2 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Translated Tables.do (regs_avg_delta_ex1_all and regs_commit_pooled_all) to R. Sample: flag_low_wtp==0 & flag_exclude_exog==0, then !missing(incentive). Table 3: OLS of avg_delta_ex1 (mean of delta2..delta12) on wave2, wave3, first_info, new_info (+ z-scored gap), HC1 robust SEs. Z-scores standardized over the !missing(incentive) sample as in the do-file. Table 4: reshaped commit8/12/16 long, LPM with threshold FE (fixef.rm='none'), wave dummies, SEs clustered by id. attempt-1 was an exploratory run inspecting variable encodings (no RESULT lines). The final run was the first run to print RESULT lines; the script was not changed after comparing with claimed values, so there are no claim attempts.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 153,622 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/seeded/claude-code/20261102T061959Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 778 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/seeded/claude-code/20261102T061959Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 265 bytes, from `benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/seeded/2026-11-02-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 754 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/seeded/claude-code/20261102T061959Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/seeded/claude-code/20261102T061959Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,897 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/seeded/claude-code/20261102T061959Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,196 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/seeded/claude-code/20261102T061959Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,322 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/seeded/claude-code/20261102T061959Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 256 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/seeded/claude-code/20261102T061959Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,587 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/seeded/claude-code/20261102T061959Z/stdout.txt`
