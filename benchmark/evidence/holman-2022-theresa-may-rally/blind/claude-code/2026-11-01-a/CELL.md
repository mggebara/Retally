# holman-2022-theresa-may-rally · blind · claude-code · 2026-11-01-a

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-01-a |
| Date | 2026-11-02T04:45:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-13papers-indep-blind-2026-11-01.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T043821Z` |
| Run directory | `benchmark/reproductions/holman-2022-theresa-may-rally/blind/2026-11-01-a` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 6/11 (execution 3) |
| Final | **7/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `intl_attack_table4` | 3.112 (0.875) | 2.32209 | 25.38% | ±0.875 (se_band) | PASS | PASS |
| `intl_attack_x_woman_exec_table4` | -4.333 (1.859) | -3.82839 | 11.65% | ±1.859 (se_band) | PASS | PASS |
| `n_obs_table4` | 4328 | 4486 | 3.65% | ±216.4 (relative) | PASS | FAIL |
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

- (reproduction.json) Table 4: the data file has no contemporaneous approval series, only `lag_approval` (labelled 'Lagged approval'); its timing (UK value drops at the Manchester quarter 2017q2) indicates it is the next-quarter approval aligned to the attack quarter, so it is used as the DV with the attack indicator in the same row.
- (reproduction.json) Table 4: attack indicator = kill_16 (international attack, 16+ i.e. more than 15 deaths); woman executive = female_pres; execrlc (DPI left/center/right, 0-3) entered linearly; country FE on country_code (44 panels survive listwise deletion, not 66). Point estimates are OLS with country dummies (identical to xtpcse without AR terms); panel-corrected SEs not reproduced (clustered SEs printed for information only; SEs are not scored).
- (reproduction.json) Table 2: did_data.dta; treatment = treatment1 (surveyed after attack in wave 12, constant within respondent), time = 1 for waves >= 12, interaction, wave dummies; time is collinear with the wave dummies, so (as Stata's left-to-right collinearity rule would) the last aliased wave dummy is dropped and time kept, which makes the time coefficient a contrast of the last wave with the base wave. Controls: white (ethnically British), female, labour, party_other, income, ideology2 (ideology with missing set to midpoint, per footnote 8); listwise deletion otherwise. Unweighted.
- (reproduction.json) Table 2 May best PM: outcome = bestPMW (waves 7, 8, 10, 11, 12), logistic regression per the table note; coefficients reported in log-odds.

Agent notes: Two exploratory runs (variable inspection, no RESULT lines), then one estimation run which is final. Readme docx in the dataset dir was read for documentation (it has no specification details). While reading the paper's global-analysis section for method, prose effect sizes and the Table 4 constant/R2 were visible; the specification was not adjusted toward them. No script files in the dataset were opened (replication_files.do is not present in the mount anyway).

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,435 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T043821Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,061 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T043821Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 257 bytes, from `benchmark/.cache/claude-code/holman-2022-theresa-may-rally/blind/2026-11-01-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,444 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T043821Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T043821Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 11,731 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T043821Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,359 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T043821Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T043821Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 15,651 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T043821Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,501 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T043821Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,036 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T043821Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T043821Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,629 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T043821Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
