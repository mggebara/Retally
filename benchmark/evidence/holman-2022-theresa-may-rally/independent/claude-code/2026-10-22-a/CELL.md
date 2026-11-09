# holman-2022-theresa-may-rally · independent · claude-code · 2026-10-22-a

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-22-a |
| Date | 2026-10-22T03:15:29Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-6papers-all-modes-2026-10-22.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z` |
| Run directory | `benchmark/reproductions/holman-2022-theresa-may-rally/independent/2026-10-22-a` |
| Executions | 7 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 0/11 |
| First scored | 10/11 (execution 5) |
| Final | **11/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `intl_attack_table4` | 3.112 (0.875) | 2.32209 | 25.38% | ±0.875 (se_band) | PASS | PASS |
| `intl_attack_x_woman_exec_table4` | -4.333 (1.859) | -3.82839 | 11.65% | ±1.859 (se_band) | PASS | PASS |
| `n_obs_table4` | 4328 | 4486 | 3.65% | ±216.4 (relative) | PASS | FAIL |
| `did_attack_x_time_like_may_table2` | -0.1274 (0.0187) | -0.12739 | 0.01% | ±0.0187 (se_band) | PASS | PASS |
| `did_attack_like_may_table2` | 0.0178 (0.0278) | 0.017785 | 0.08% | ±0.0278 (se_band) | PASS | PASS |
| `did_time_like_may_table2` | -0.5007 (0.0229) | -0.50065 | 0.01% | ±0.0229 (se_band) | PASS | PASS |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | -0.050069 | 0.06% | ±0.0044 (se_band) | PASS | PASS |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | -0.000171 | 14.50% | ±0.004 (se_band) | PASS | PASS |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | 0.209799 | 0.00% | ±0.004196 (relative) | PASS | PASS |
| `n_obs_did_like_may_table2` | 143499 | 143499 | 0.00% | ±7174.95 (relative) | PASS | PASS |
| `n_obs_did_may_best_pm_table2` | 97155 | 97155 | 0.00% | ±4857.75 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Table 4: estimation sample is every complete country-quarter in global_approval.dta (4,486 obs, 44 country_code panels) instead of the reported 4,328; no rule found in the paper or data that yields 4,328 (checked lagged regressors, lead DV, execrlc>0, AR(1) spell trimming).
- (reproduction.json) Table 4: coefficients from OLS with country_code fixed effects (xtpcse without AR(1) gives the same point estimates); printed SEs are iid, not panel-corrected.
- (reproduction.json) Table 4: dependent variable is lag_approval, which the series shows to be approval in the quarter after row t (US 9/11 row holds the 2001Q4 peak; UK Manchester row holds the post-election 2017Q3 slump), i.e. next-quarter approval as the paper describes; attack = kill_16 (16+ deaths, matches the paper's 60 attack quarters, 9 under women).
- (reproduction.json) Table 2: estimated as random-effects GLS (Stata xtreg re, Swamy-Arora with harmonic-mean T) implemented by hand, with wave dummies (base = first wave; last post-attack wave omitted as collinear with time, as Stata does). The May best PM column is a linear probability model, not a logit, because the reported magnitudes and SEs are LPM-scale. Income missing values are dropped (not imputed); ideology2 (missing set to midpoint) is used.
- (DEVIATION: line) Table 4 sample is all complete country-quarters in global_approval.dta ( 4486 ), not 4,328 as reported; SEs printed are iid, not panel-corrected (coefficients unaffected).
- (DEVIATION: line) Table 2 estimated as random-effects GLS (xtreg re style) with wave dummies; the May best PM column is a linear probability model (reported magnitudes are LPM-scale), not logit.

Agent notes: Exploratory runs attempt-1..4 inspected variables, sample sizes and series timing (no RESULT lines). attempt-5 was the first estimating run; I compared it with the claims (check_attempt flagged only n_obs_table4), ran one more sample-size exploration (attempt-6) looking for a rule giving 4,328, found none, and reverted to attempt-5 unchanged as the final run. Table 2 reproduces every coefficient, SE (to 4 dp) and both Ns exactly. Table 4 gives 2.322 (claimed 3.112) and -3.828 (claimed -4.333) with N 4,486 vs 4,328. Before attempt-1 a malformed run occurred: the script file had not been written (a shell write was refused), so Docker mounted an empty directory as script.R and Rscript produced no output; that directory was removed and the run is not listed as an attempt because no script existed. The dataset readme .docx and metadata.json in the mount were read as documentation; replication_files.do is listed in metadata.json but is not in the mount and was not read.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 17,878 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,093 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 257 bytes, from `benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-10-22-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,607 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 17,631 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,941 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,621 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 1,681 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 2,939 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-3/stdout.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 765 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 2,871 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-4/stdout.txt`
- [`output/attempt-5/feedback.txt`](output/attempt-5/feedback.txt) — 65 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-5/feedback.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 4,908 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 460 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 2,905 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-5/stdout.txt`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 1,030 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 764 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/attempt-6/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,986 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,908 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 460 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,905 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261022T032229Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
