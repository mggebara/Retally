# holman-2022-theresa-may-rally · blind · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T21:40:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261108T015657Z` |
| Run directory | `benchmark/reproductions/holman-2022-theresa-may-rally/blind/2026-11-07-a` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 7/11 (execution 2) |
| Final | **7/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `intl_attack_table4` | 3.112 (0.875) | 2.32209 | 25.38% | ±0.875 (se_band) | PASS | PASS |
| `intl_attack_x_woman_exec_table4` | -4.333 (1.859) | -3.82839 | 11.65% | ±1.859 (se_band) | PASS | PASS |
| `n_obs_table4` | 4328 | 4486 | 3.65% | ±216.4 (relative) | PASS | PASS |
| `did_attack_x_time_like_may_table2` | -0.1274 (0.0187) | -0.099607 | 21.82% | ±0.0187 (se_band) | FAIL | FAIL |
| `did_attack_like_may_table2` | 0.0178 (0.0278) | 0.008807 | 50.52% | ±0.0278 (se_band) | PASS | PASS |
| `did_time_like_may_table2` | -0.5007 (0.0229) | -0.451291 | 9.87% | ±0.0229 (se_band) | FAIL | FAIL |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | -0.321537 | 541.79% | ±0.0044 (se_band) | FAIL | FAIL |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | -0.002315 | 1057.50% | ±0.004 (se_band) | PASS | PASS |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | 1.36411 | 550.20% | ±0.004196 (relative) | FAIL | FAIL |
| `n_obs_did_like_may_table2` | 143499 | 143499 | 0.00% | ±7174.95 (relative) | PASS | PASS |
| `n_obs_did_may_best_pm_table2` | 97155 | 97155 | 0.00% | ±4857.75 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/11 pass, which agrees with the row's 7/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Table 4: global_approval.dta holds a single approval series, 'lag_approval'; it is used as the outcome in the same row as the attack indicator (the file appears pre-aligned for the 'quarter following the attack' design). The >15-death international attack indicator is kill_16 (16+ deaths; 60 country-quarters, matching the paper's count). Country fixed effects use country_code (country x office; 66 units, matching the paper's N countries). execrlc entered linearly (0-3 DPI code), growth as given. Sample = complete cases (4,486). Beck-Katz PCSEs from plm::vcovBK are printed for reference only.
- (reproduction.json) Table 2: OLS (like May, waves 9-16) and logit (best PM, waves 7,8,10,11,12), unweighted, regressors treatment1 (= post_attack), time (wave>=12), their interaction, wave dummies and controls white, female, labour, party_other, income, ideology2 (ideology with missing set to midpoint, per footnote 8). Time is collinear with the wave dummies; as Stata would, the last collinear wave dummy (wave 16 / wave 12) is dropped, so the Time coefficient depends on that normalisation. Conventional (non-clustered) SEs.

Agent notes: attempt-1 was exploratory (variable inspection, no RESULT lines). The final script estimates all 11 quantities in one run (67 s). Table 4 R2 from my model is 0.268, which suggests the authors' specification differs in some way (outcome alignment, the control set or the R2 definition). I did not tune anything toward it. The Readme docx was read as data documentation; no script files were opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 19,187 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261108T015657Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,061 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261108T015657Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 270 bytes, from `benchmark/.cache/claude-code/holman-2022-theresa-may-rally/blind/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,692 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261108T015657Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261108T015657Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 14,678 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261108T015657Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 251 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261108T015657Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,006 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261108T015657Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,144 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261108T015657Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 115 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261108T015657Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,389 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261108T015657Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 250 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261108T015657Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
