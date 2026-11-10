# balan-2022-local-elites-state-capacity · seeded · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `balan-2022-local-elites-state-capacity` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T17:11:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-balan-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171526Z` |
| Run directory | `benchmark/reproductions/balan-2022-local-elites-state-capacity/seeded/2026-11-10-b` |
| Executions | 3 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 2) |
| Final | **13/13** |
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
| `paid_bribe_endline_local_table5_panelB` | 0.018 (0.009) | 0.01754 | 2.56% | ±0.0005 (printed_precision) | PASS | FAIL |
| `visited_by_collector_local_table6_col1` | -0.009 (0.026) | -0.009014 | 0.16% | ±0.0005 (printed_precision) | PASS | PASS |
| `compliance_cli_table7_col1` | 0.024 (0.009) | 0.024207 | 0.86% | ±0.0005 (printed_precision) | PASS | PASS |
| `revenue_cli_table7_col2` | 46.566 (21.2) | 46.5658 | 0.00% | ±0.93132 (relative) | PASS | PASS |
| `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 (0.007) | 0.056125 | 0.22% | ±0.00112 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Data/03_clean_combined/analysis_data.dta is not shipped, so the script rebuilds it in R by translating 2_Data_Construction.do: fliers plus pilot fliers, stratum, assignment with the pilot rows and the a7==654 fix, registration, taxroll, de-duplicated midline, TDM payments. It uses Stata merge semantics, keeping master values for overlapping variables, and rebuilds taxes_paid, rate and taxes_paid_amt, the TDM date corrections, the sequential carto-date imputation and today_alt, then drops rows with missing rate. The regressions then follow Table4/5/6/7/8.do with fixest (cluster a7, fixef.rm='none'). Table 8 reproduces the 1:m merge with the endline survey (duplicated master rows) and the m:1 merge with chief_consultations. attempt-1 was exploratory (variable listing). attempt-2 was the first full run: all claims matched except the endline bribe coefficient (0.0173 vs 0.018). The final run fixes a Stata-semantics translation issue. 'replace bribe = bribe2a if bribe==.' only fills system-missing values, not extended missing (.d), and 'visits!=.' / 'visits>1' are true for .d in Table 6. The R code now tracks haven tagged missings for these. Final bribe coefficient is 0.0175 (rounds to 0.018) and Table 6 is -0.0090. Table 4 N matches exactly (28872, 27764).

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 201,777 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171526Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 794 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171526Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 271 bytes, from `benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/seeded/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 2,155 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171526Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171526Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 14,086 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171526Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 260 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171526Z/attempt-1/timing.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 107 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171526Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 14,356 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171526Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 769 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171526Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 931 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171526Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 260 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171526Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,826 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171526Z/reproduction.json`
- [`output/script.R`](output/script.R) — 15,148 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171526Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 769 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171526Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,004 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171526Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 260 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/seeded/claude-code/20261110T171526Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
