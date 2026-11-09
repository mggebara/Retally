# holman-2022-theresa-may-rally · independent · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-08T04:06:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z` |
| Run directory | `benchmark/reproductions/holman-2022-theresa-may-rally/independent/2026-11-07-a` |
| Executions | 7 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 6/11 (execution 7) |
| Final | **6/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `intl_attack_table4` | 3.112 (0.875) | 4.1997 | 34.95% | ±0.875 (se_band) | FAIL | FAIL |
| `intl_attack_x_woman_exec_table4` | -4.333 (1.859) | -6.2197 | 43.54% | ±1.859 (se_band) | FAIL | FAIL |
| `n_obs_table4` | 4328 | 4328 | 0.00% | ±216.4 (relative) | PASS | PASS |
| `did_attack_x_time_like_may_table2` | -0.1274 (0.0187) | -0.0996 | 21.82% | ±0.0187 (se_band) | FAIL | FAIL |
| `did_attack_like_may_table2` | 0.0178 (0.0278) | 0.0088 | 50.56% | ±0.0278 (se_band) | PASS | PASS |
| `did_time_like_may_table2` | -0.5007 (0.0229) | -0.4513 | 9.87% | ±0.0229 (se_band) | FAIL | FAIL |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | -0.052 | 3.79% | ±0.0044 (se_band) | PASS | PASS |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | -0.0002 | 0.00% | ±0.004 (se_band) | PASS | PASS |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | 0.2055 | 2.05% | ±0.004196 (relative) | FAIL | FAIL |
| `n_obs_did_like_may_table2` | 143499 | 143499 | 0.00% | ±7174.95 (relative) | PASS | PASS |
| `n_obs_did_may_best_pm_table2` | 97155 | 97155 | 0.00% | ±4857.75 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 6/11 pass, which agrees with the row's 6/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Table 2 May-best-PM column estimated as a linear probability model (OLS) although the table note says logistic; the published coefficients (constant 0.15, time 0.21) are on the probability scale.
- (reproduction.json) Table 2: 'time' is collinear with wave fixed effects; wave dummies use the first wave as base and omit the last post-attack wave (as Stata would when time precedes i.wave). Controls: white, gender, labour, party_other, income, ideology2 (ideology2 reproduces both published Ns exactly).
- (reproduction.json) Table 4: 'growth' in the data is a real-GDP level, so year-on-year % growth (4-quarter lag within country) was constructed; the duplicated Macedonia panel (country_code 34) was dropped. This combination reproduces N = 4,328 exactly, but the coefficients (4.20, -6.22) and R2 (0.29 vs 0.577) differ from the paper. Using the raw 'growth' level and all panels gives N = 4,486 with 2.32 / -3.83.
- (reproduction.json) Table 4 estimated by OLS with country dummies; panel-corrected SEs only affect standard errors (not reported). A Prais-Winsten AR(1) variant was explored (2.71 / -3.95 on the N=4328 sample) but not used, since the paper does not mention AR(1) correction.
- (DEVIATION: line) Table 2 May-best-PM column estimated as a linear probability model (coefficients reported on the probability scale)
- (DEVIATION: line) Table 4 estimated by OLS with country dummies (panel-corrected SEs affect only standard errors, not reported here)

Agent notes: Independent reproduction from paper text and data only. Attempts 1-6 were exploratory (structure, variable labels, sample sizes, specification variants); they printed no RESULT lines. Specification choices were guided by matching the published Ns (143,499; 97,155; 4,328), and the exploratory runs also printed Table 4 coefficients for several variants that I saw alongside the paper's table; no RESULT-based claim comparison (check_attempt) was run and the script was not changed after the final run. DV for Table 4 is 'lag_approval', which is missing in every country's last quarter and so appears to hold next-quarter approval; attack indicator kill_16 (international attack, 16+ deaths; 60 country-quarters, 9 under women, matching the paper). Table 2 matches closely (interaction -0.0996 vs -0.1274 for likeability; -0.0520 vs -0.0501 for best PM). Table 4 matches in sign and significance pattern but not magnitude, and the paper's R2 of 0.577 could not be reached with any specification tried, suggesting the posted global_approval.dta (45 country codes, vs 66 countries in the paper) differs from the one used. No Docker hang occurred.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,630 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,093 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 257 bytes, from `benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,311 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 17,723 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 255 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,261 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 1,118 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,595 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 255 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 1,823 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 871 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 4,710 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 254 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-3/timing.json`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 2,035 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 210 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 545 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 254 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-4/timing.json`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 1,426 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 1,362 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 1,325 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-5/stdout.txt`
- [`output/attempt-5/timing.json`](output/attempt-5/timing.json) — 255 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-5/timing.json`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 1,967 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 210 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 423 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-6/stdout.txt`
- [`output/attempt-6/timing.json`](output/attempt-6/timing.json) — 255 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/attempt-6/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 3,065 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,432 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 210 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 709 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 256 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261108T083657Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
