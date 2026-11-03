# holman-2022-theresa-may-rally · independent · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:10:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z` |
| Run directory | `benchmark/reproductions/holman-2022-theresa-may-rally/independent/2026-11-02-c` |
| Executions | 11 |
| Refinements | 2 (1 error + 1 claim) |
| First attempt | 0/11 |
| First scored | 7/11 (execution 8) |
| Final | **8/11** |
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
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | -0.051961 | 3.71% | ±0.0044 (se_band) | PASS | PASS |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | -0.000207 | 3.50% | ±0.004 (se_band) | PASS | PASS |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | 0.2055 | 2.05% | ±0.004196 (relative) | FAIL | FAIL |
| `n_obs_did_like_may_table2` | 143499 | 143499 | 0.00% | ±7174.95 (relative) | PASS | PASS |
| `n_obs_did_may_best_pm_table2` | 97155 | 97155 | 0.00% | ±4857.75 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/11 pass, which agrees with the row's 8/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Table 4: N is 4486 country-quarters (44 countries) rather than the paper's 4328 (66 countries); the posted global_approval.dta contains 44 usable countries and no lead/lag or growth-rate variant tried (exploratory attempts 4 and 6) reproduced 4328.
- (reproduction.json) Table 4: the dependent variable is the posted 'lag_approval' (the only approval series in the file), regressed on the contemporaneous 16+-death international attack indicator kill_16; GDP enters in levels (variable 'growth', rescaled by 1e6), execrlc linear. Coefficients are OLS with country dummies; panel-corrected SEs computed by hand (Beck-Katz, pairwise covariances), no AR(1) correction.
- (reproduction.json) Table 2: both columns estimated by OLS (the May best PM column as a linear probability model, since the reported coefficients/SEs are on the probability scale despite the note saying logistic). Wave dummies entered after 'time' so the last collinear wave dummy is omitted, Stata-style; SEs clustered by respondent (not scored). Ideology uses ideology2 (missing set to midpoint), which reproduces both reported Ns exactly.

Agent notes: Attempts 1-6 explored the data (readme docx text, variable structure, sample-size searches for Table 4). Attempt 7 crashed (singular X'X in the PCSE function because GDP is in levels) and was fixed by rescaling GDP. Attempt 8 was the first scored run; I compared it with check_attempt (feedback.txt): the Table 4 coefficients were within tolerance, but N(Table 4) and the May-likeability interaction and time coefficients, plus the best-PM time coefficient, were off. Attempts 9 (crashed from a bug in the exploratory script) and 10 explored Table 2 variants (alternative ideology codings, treatment2, which wave dummy gets omitted, adding a Conservative dummy). None was better justified by the paper, so the final run reruns the attempt-8 script unchanged; its output is identical to attempt 8. Remaining gaps: May-likeability DiD interaction -0.0996 vs -0.1274 and time -0.451 vs -0.501; Table 4 N 4486 vs 4328. No docker run hung. replication_files.do was not opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,355 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,093 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 257 bytes, from `benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,045 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 20,464 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,370 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,807 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 1,537 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 3,236 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-3/stdout.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 1,838 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 934 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-4/stdout.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 1,815 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 2,694 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-5/stdout.txt`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 1,056 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 1,026 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-6/stdout.txt`
- [`output/attempt-7/feedback.txt`](output/attempt-7/feedback.txt) — 243 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-7/feedback.txt`
- [`output/attempt-7/script.R`](output/attempt-7/script.R) — 4,642 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-7/script.R`
- [`output/attempt-7/stderr.txt`](output/attempt-7/stderr.txt) — 174 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-7/stderr.txt`
- [`output/attempt-7/stdout.txt`](output/attempt-7/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-7/stdout.txt`
- [`output/attempt-8/feedback.txt`](output/attempt-8/feedback.txt) — 345 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-8/feedback.txt`
- [`output/attempt-8/script.R`](output/attempt-8/script.R) — 4,736 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-8/script.R`
- [`output/attempt-8/stderr.txt`](output/attempt-8/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-8/stderr.txt`
- [`output/attempt-8/stdout.txt`](output/attempt-8/stdout.txt) — 1,792 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-8/stdout.txt`
- [`output/attempt-9/script.R`](output/attempt-9/script.R) — 1,960 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-9/script.R`
- [`output/attempt-9/stderr.txt`](output/attempt-9/stderr.txt) — 1,102 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-9/stderr.txt`
- [`output/attempt-9/stdout.txt`](output/attempt-9/stdout.txt) — 561 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-9/stdout.txt`
- [`output/attempt-10/script.R`](output/attempt-10/script.R) — 1,968 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-10/script.R`
- [`output/attempt-10/stderr.txt`](output/attempt-10/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-10/stderr.txt`
- [`output/attempt-10/stdout.txt`](output/attempt-10/stdout.txt) — 2,227 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/attempt-10/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 3,048 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,736 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,792 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T202751Z/stdout.txt`
