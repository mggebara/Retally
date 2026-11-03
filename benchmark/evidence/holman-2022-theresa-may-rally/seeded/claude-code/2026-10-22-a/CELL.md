# holman-2022-theresa-may-rally · seeded · claude-code · 2026-10-22-a

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-22-a |
| Date | 2026-10-22T03:04:50Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-6papers-all-modes-2026-10-22.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261022T032229Z` |
| Run directory | `benchmark/reproductions/holman-2022-theresa-may-rally/seeded/2026-10-22-a` |
| Executions | 3 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 11/11 (execution 3) |
| Final | **11/11** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `intl_attack_table4` | 3.112 (0.875) | 3.112 | 0.00% | ±0.06224 (relative) | PASS | PASS |
| `intl_attack_x_woman_exec_table4` | -4.333 (1.859) | -4.3327 | 0.01% | ±0.08666 (relative) | PASS | PASS |
| `n_obs_table4` | 4328 | 4328 | 0.00% | ±216.4 (relative) | PASS | PASS |
| `did_attack_x_time_like_may_table2` | -0.1274 (0.0187) | -0.1274 | 0.00% | ±0.002548 (relative) | PASS | PASS |
| `did_attack_like_may_table2` | 0.0178 (0.0278) | 0.0178 | 0.00% | ±0.000356 (relative) | PASS | PASS |
| `did_time_like_may_table2` | -0.5007 (0.0229) | -0.5007 | 0.00% | ±0.010014 (relative) | PASS | PASS |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | -0.0501 | 0.00% | ±0.001002 (relative) | PASS | PASS |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | -0.0002 | 0.00% | ±5e-05 (printed_precision) | PASS | PASS |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | 0.2098 | 0.00% | ±0.004196 (relative) | PASS | PASS |
| `n_obs_did_like_may_table2` | 143499 | 143499 | 0.00% | ±7174.95 (relative) | PASS | PASS |
| `n_obs_did_may_best_pm_table2` | 97155 | 97155 | 0.00% | ±4857.75 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Table 4 xtpcse corr(psar1) implemented by hand: OLS residuals -> panel-specific rho (rhotype regress, consecutive-quarter pairs using tsset-style lags) -> Prais-Winsten transform (a time gap starts a new segment) -> OLS. One panel's rho (1.070) was bounded to 1. Only point estimates and N are reported; panel-corrected SEs were not computed.
- (reproduction.json) Table 2 xtreg (Stata default random-effects GLS, Swamy-Arora with harmonic-mean T for unbalanced panels) implemented by hand. The paper's note calls the best-PM column logistic, but the authors' script runs linear xtreg RE, which is what is reproduced.

Agent notes: attempt-1 was exploratory (variable structure, sample sizes; no RESULT lines). attempt-2 crashed because one panel's AR(1) rho exceeded 1; fixed by bounding rho to [-1,1]. The final run reproduces all 11 claims: Table 2 RE DiD coefficients and Ns exactly; Table 4 kill_16 = 3.112, interaction = -4.333 (constant 46.030), N = 4328. No check_attempt comparison was needed or run.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 64,811 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261022T032229Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 966 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261022T032229Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 252 bytes, from `benchmark/.cache/claude-code/holman-2022-theresa-may-rally/seeded/2026-10-22-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,535 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261022T032229Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261022T032229Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 4,625 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261022T032229Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 302 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261022T032229Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 5,743 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261022T032229Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 113 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261022T032229Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 997 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261022T032229Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,534 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261022T032229Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,857 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261022T032229Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261022T032229Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,674 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261022T032229Z/stdout.txt`
