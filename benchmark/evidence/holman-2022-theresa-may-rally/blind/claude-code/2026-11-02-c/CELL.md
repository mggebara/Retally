# holman-2022-theresa-may-rally · blind · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:19:29Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T202753Z` |
| Run directory | `benchmark/reproductions/holman-2022-theresa-may-rally/blind/2026-11-02-c` |
| Executions | 4 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 6/11 (execution 4) |
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

- (reproduction.json) Table 4: panel-corrected SEs computed by a hand-written Beck-Katz estimator (pairwise contemporaneous covariances, like Stata xtpcse's default) because no PCSE package is installed; coefficients are plain OLS with country_code dummies.
- (reproduction.json) Table 4: execrlc (DPI executive ideology, 0-3) entered linearly as given, including its unlabelled 0 code; growth used as the dataset provides it (a GDP level).
- (reproduction.json) Table 2: time is collinear with the wave dummies; the last wave dummy is omitted (what Stata does when time comes before i.wave), so the Time coefficient is the last wave's shift relative to the first wave of each outcome's panel. SEs clustered by respondent (the paper says only 'standard errors'). No survey weights.

Agent notes: Independent blind reproduction from the paper text and data files only (the replication .do file is not in the mount and was not sought). Table 4: global_approval.dta; DV lag_approval (missing in each panel's last quarter, so it is next-quarter approval despite its label); attack = kill_16 (international attack with 16+ deaths, 60 country-quarters, matching the paper's count); interaction with female_pres; controls growth, log_inflation, execrlc, election_qtr; country_code fixed effects; complete cases (N=4486, 44 panels). Table 2: did_data.dta long panel; treatment1 (surveyed after the Manchester attack in wave 12) x time (wave>=12), wave FE, controls white, gender, labour, party_other, income, ideology2 (ideology with missing values set to the midpoint, per footnote 8); like May = likeMayW, OLS, waves 9-16; May best PM = bestPMW (1 May, 0 Corbyn), logit, waves 7,8,10,11,12; logit coefficients reported. Attempts 1-2 were exploratory (variable labels, tabulations); attempt 3 crashed in the PCSE bread (singular solve due to scaling) and was fixed with the QR-based unscaled covariance. No docker hang. No specification was tuned toward any paper number.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,912 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T202753Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,061 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T202753Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 257 bytes, from `benchmark/.cache/claude-code/holman-2022-theresa-may-rally/blind/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,365 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T202753Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T202753Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 43,679 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T202753Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,843 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T202753Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T202753Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 8,313 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T202753Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 352 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T202753Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 5,355 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T202753Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 179 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T202753Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T202753Z/attempt-3/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,505 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T202753Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,423 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T202753Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T202753Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,485 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261102T202753Z/stdout.txt`
