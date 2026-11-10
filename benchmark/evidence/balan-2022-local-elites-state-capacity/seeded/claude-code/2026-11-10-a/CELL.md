# balan-2022-local-elites-state-capacity · seeded · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `balan-2022-local-elites-state-capacity` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T17:09:22Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-balan-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171524Z` |
| Run directory | `benchmark/reproductions/balan-2022-local-elites-state-capacity/seeded/2026-11-10-a` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 2) |
| Final | **12/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `compliance_local_table4_panelA_col1` | 0.023 (0.008) | 0.022573 | 1.86% | ±0.0005 (printed_precision) | PASS | PASS |
| `compliance_local_table4_panelA_col2` | 0.032 (0.007) | 0.032213 | 0.67% | ±0.00064 (relative) | PASS | PASS |
| `compliance_local_house_fe_table4_panelA_col4` | 0.033 (0.007) | 0.033083 | 0.25% | ±0.00066 (relative) | PASS | PASS |
| `compliance_local_exempt_excluded_table4_panelA_col5` | 0.04 (0.008) | 0.039584 | 1.04% | ±0.0008 (relative) | PASS | PASS |
| `revenue_local_table4_panelB_col2` | 79.64 (22.856) | 79.6398 | 0.00% | ±1.5928 (relative) | PASS | PASS |
| `revenue_local_house_fe_table4_panelB_col4` | 68.855 (20.56) | 68.8553 | 0.00% | ±1.3771 (relative) | PASS | PASS |
| `n_obs_table4_col1` | 28872 | 28872 | 0.00% | ±1443.6 (relative) | PASS | PASS |
| `n_obs_table4_col2` | 27764 | 27764 | 0.00% | ±1388.2 (relative) | PASS | PASS |
| `paid_bribe_endline_local_table5_panelB` | 0.018 (0.009) | 0.017288 | 3.96% | ±0.0005 (printed_precision) | FAIL | FAIL |
| `visited_by_collector_local_table6_col1` | -0.009 (0.026) | -0.008777 | 2.48% | ±0.0005 (printed_precision) | PASS | PASS |
| `compliance_cli_table7_col1` | 0.024 (0.009) | 0.024207 | 0.86% | ±0.0005 (printed_precision) | PASS | PASS |
| `revenue_cli_table7_col2` | 46.566 (21.2) | 46.5658 | 0.00% | ±0.93132 (relative) | PASS | PASS |
| `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 (0.007) | 0.056125 | 0.22% | ±0.00112 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) analysis_data.dta is not shipped; it was rebuilt in R from the 01_base files following 2_Data_Construction.do, keeping only the variables the targeted tables use (fliers, stratum, randomization schedule incl. the a7 654 fix, registration, tax roll, midline, TDM payments; Stata merge semantics with master values winning on overlapping variables; carto-date imputations and today_alt as in the do-file). The pilot flier xlsx sets, chefferies and 2016 assignment merges were skipped because they only touch pilot polygons (dropped) or variables not used.
- (reproduction.json) Coefficients only are reported; fixest clustered SEs (by a7) use fixest's small-sample defaults, which can differ marginally from Stata reg, cl().

Agent notes: Attempt-1 was an exploratory run (column names/structure, no estimates). The single scored run reproduces Table 4 exactly (N 28,872 / 27,764 / 23,803; clusters 221 / 213; Central means 0.068 / 0.063), Table 7 cols 1-2 (N 20,636, 165 clusters) and Table 8 Panel A col 2 (N 8,135). Table 6 col 1 gives -0.0088 with N 18,152 (paper 18,162). Table 5 Panel B paid bribe (endline) gives 0.0173 with N 1,178 (paper 0.018, N 1,169); the small sample gap was not chased. No claim-driven changes were made. The host was awake, so no runs hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 201,777 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171524Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 794 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171524Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 271 bytes, from `benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/seeded/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 3,000 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171524Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171524Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,840 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171524Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 259 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171524Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,745 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171524Z/reproduction.json`
- [`output/script.R`](output/script.R) — 12,808 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171524Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 769 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171524Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,796 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171524Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 260 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171524Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
