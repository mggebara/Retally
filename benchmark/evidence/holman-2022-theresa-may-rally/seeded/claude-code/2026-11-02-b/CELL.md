# holman-2022-theresa-may-rally · seeded · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T19:40:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-23papers-seeded-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z` |
| Run directory | `benchmark/reproductions/holman-2022-theresa-may-rally/seeded/2026-11-02-b` |
| Executions | 5 |
| Refinements | 3 (3 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 0/11 (execution 1) |
| Final | **0/11** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `intl_attack_table4` | 3.112 (0.875) | — | — | ±0.06224 (relative) | FAIL | FAIL |
| `intl_attack_x_woman_exec_table4` | -4.333 (1.859) | — | — | ±0.08666 (relative) | FAIL | FAIL |
| `n_obs_table4` | 4328 | — | — | ±216.4 (relative) | FAIL | FAIL |
| `did_attack_x_time_like_may_table2` | -0.1274 (0.0187) | — | — | ±0.002548 (relative) | FAIL | FAIL |
| `did_attack_like_may_table2` | 0.0178 (0.0278) | — | — | ±0.000356 (relative) | FAIL | FAIL |
| `did_time_like_may_table2` | -0.5007 (0.0229) | — | — | ±0.010014 (relative) | FAIL | FAIL |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | — | — | ±0.001002 (relative) | FAIL | FAIL |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | — | — | ±5e-05 (printed_precision) | FAIL | FAIL |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | — | — | ±0.004196 (relative) | FAIL | FAIL |
| `n_obs_did_like_may_table2` | 143499 | — | — | ±7174.95 (relative) | FAIL | FAIL |
| `n_obs_did_may_best_pm_table2` | 97155 | — | — | ±4857.75 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 0/11 pass, which agrees with the row's 0/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Table 4 (xtpcse, cor(psar1), independent) implemented by hand: OLS residuals, panel-specific rho from regressing e_t on e_{t-1} over consecutive quarters, truncated to [-1, 1]; Prais-Winsten transform with the sqrt(1 - rho^2) first-observation weight also applied to the first observation after an internal gap (195 such gaps in the estimation sample); panel-heteroskedastic PCSEs. Stata's exact handling of gaps and of rho > 1 (one panel, rho = 1.07) is not known; with rho truncated to 1 that country's dummy is aliased after the transform.
- (reproduction.json) Table 2 (xtreg, default random effects) implemented by hand as Swamy-Arora GLS with the unbalanced-panel harmonic-mean T; wave dummies with the later collinear wave dummy omitted (Stata ordering), linear model also for the best-PM column as in the do-file.

Agent notes: Exploratory run confirmed the samples: Table 2 complete cases give exactly 143,499 (likeability) and 97,155 (best PM) respondent-waves; Table 4 complete cases give 4,328 country-quarters (44 panels). The three repairs fixed, in turn, rho > 1 (NaN first-observation weight), a zero country-dummy column after the transform, and an ill-conditioned X'X inversion. The final run then crashed on a further bug in the PCSE step (the per-panel variance vector w was a 1-d named array, so 'Xs * sqrt(w)' is non-conformable; as.numeric(w) would fix it). The task allows at most 3 error repairs, so I did not repair it again: the final run printed no RESULT lines. No claim comparisons were made.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 64,811 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 966 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 252 bytes, from `benchmark/.cache/claude-code/holman-2022-theresa-may-rally/seeded/2026-11-02-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,475 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 10,669 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 249 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 5,819 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 113 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 106 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 323 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 5,928 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 153 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 130 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/attempt-3/stdout.txt`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 397 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 6,056 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 168 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 171 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/attempt-4/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,165 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,652 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 64 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 206 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/claude-code/20261102T194315Z/stdout.txt`
