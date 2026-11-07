# bokobza-2022-morning-after-coup-purges · independent · claude-code · 2026-11-02-a

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-a |
| Date | 2026-11-02T05:59:40Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z` |
| Run directory | `benchmark/reproductions/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a` |
| Executions | 5 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 0/11 |
| First scored | 11/11 (execution 4) |
| Final | **11/11** |
| Package files withheld | 8 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `failed_coup_base_country_fe` | 0.1 (0.03) | 0.098488 | 1.51% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_country_fe` | 0.11 (0.03) | 0.105549 | 4.05% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_base_leader_fe` | 0.08 (0.03) | 0.083868 | 4.83% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_leader_fe` | 0.09 (0.03) | 0.085272 | 5.25% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_experience_model` | 0.14 (0.04) | 0.144128 | 2.95% | ±0.04 (se_band) | PASS | PASS |
| `failed_coup_x_over_6_years_experience` | -0.1 (0.05) | -0.10138 | 1.38% | ±0.05 (se_band) | PASS | PASS |
| `failed_coup_affiliation_model` | 0.17 (0.06) | 0.175036 | 2.96% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_x_leaders_party` | -0.13 (0.06) | -0.123832 | 4.74% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_responsibility_model` | 0.2 (0.07) | 0.204123 | 2.06% | ±0.07 (se_band) | PASS | PASS |
| `failed_coup_x_natural_resources` | -0.18 (0.08) | -0.182342 | 1.30% | ±0.08 (se_band) | PASS | PASS |
| `failed_coup_importance_model` | 0.37 (0.09) | 0.372632 | 0.71% | ±0.09 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Individual-level lagged log population built from the country-year panel because the supplied pop_pwt_ln_lag column is identical to gdp_cap_pwt_ln_lag; lagged log GDP/cap also rebuilt the same way (matches the supplied GDP lag in 99.99% of rows).
- (reproduction.json) H2a experience model sample: non-leader minister-years with non-missing importance tier (junior ministers kept). The paper text says juniors are excluded, but its reported N (90,020, vs 90,014 for the importance model, a gap of exactly the 6 'tier 0' rows) indicates they were kept.
- (reproduction.json) Country-level autocracy filter uses democracy1 == 0 as stored (it reproduces the paper's 3,715 obs / 115 countries / 95 coups); lagging it again gives 3,745 obs / 117 countries.
- (reproduction.json) Leader-FE models (Table A2): controls lagged within leader spells (panel set by leader_cab_id), which reproduces the paper's N of 3,332 (3,282 plus 50 singletons) and the monarchy dummy dropping as collinear.

Agent notes: Country level: OLS of replacement_rateadj_minister on coupattempt_whogov, lagged log GDP/cap and population (plus lagged monarchy/military/party dummies in the Main model), with country or leader FE and year FE; fixest, country-clustered SEs; 1967-2016. Individual level: LPM of purged_y1 on the failed-coup indicator (coupattempt_presentyear) interacted with experience group, party group, minister type or importance tier; cubic in years in office except in the experience model; lagged log GDP/cap and population; country and year FE; country-clustered SEs; non-leader minister-years with democracy_lag==0, 1967-2016 (base N 95,344 vs the paper's 95,751). Attempts 1-3 were exploratory (variable inspection, sample counts). Attempt 4 was the first full estimation; check_attempt put every claim within tolerance, but I acted on my own comparison of the leader-FE coefficients (0.059/0.062 vs claimed 0.08/0.09) together with the N and collinearity mismatch, and switched to lags within leader spells. The final run's leader-FE estimates are 0.084/0.085.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 19,132 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,023 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 276 bytes, from `benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 799 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 210 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 34,741 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,401 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 599 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 7,890 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 2,553 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 210 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 1,607 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/attempt-3/stdout.txt`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 321 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 4,765 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 498 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 9,938 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/attempt-4/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,670 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,500 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 574 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 9,938 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T062001Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
