# bokobza-2022-morning-after-coup-purges · seeded · claude-code · 2026-11-02-a

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-a |
| Date | 2026-11-02T06:10:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T061959Z` |
| Run directory | `benchmark/reproductions/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-a` |
| Executions | 3 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 7/11 (execution 2) |
| Final | **11/11** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `failed_coup_base_country_fe` | 0.1 (0.03) | 0.098488 | 1.51% | ±0.005 (printed_precision) | PASS | FAIL |
| `failed_coup_main_country_fe` | 0.11 (0.03) | 0.105549 | 4.05% | ±0.005 (printed_precision) | PASS | FAIL |
| `failed_coup_base_leader_fe` | 0.08 (0.03) | 0.083868 | 4.83% | ±0.005 (printed_precision) | PASS | FAIL |
| `failed_coup_main_leader_fe` | 0.09 (0.03) | 0.085272 | 5.25% | ±0.005 (printed_precision) | PASS | FAIL |
| `failed_coup_experience_model` | 0.14 (0.04) | 0.142112 | 1.51% | ±0.005 (printed_precision) | PASS | PASS |
| `failed_coup_x_over_6_years_experience` | -0.1 (0.05) | -0.102939 | 2.94% | ±0.005 (printed_precision) | PASS | PASS |
| `failed_coup_affiliation_model` | 0.17 (0.06) | 0.174175 | 2.46% | ±0.005 (printed_precision) | PASS | PASS |
| `failed_coup_x_leaders_party` | -0.13 (0.06) | -0.125832 | 3.21% | ±0.005 (printed_precision) | PASS | PASS |
| `failed_coup_responsibility_model` | 0.2 (0.07) | 0.202499 | 1.25% | ±0.005 (printed_precision) | PASS | PASS |
| `failed_coup_x_natural_resources` | -0.18 (0.08) | -0.183205 | 1.78% | ±0.005 (printed_precision) | PASS | PASS |
| `failed_coup_importance_model` | 0.37 (0.09) | 0.370185 | 0.05% | ±0.0074 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Country-level Stata xtreg, fe with i.YEAR_DATA translated to fixest::feols with panel and year fixed effects; Stata L. lags built by matching YEAR_DATA-1 within the xtset panel (COUNTRY_ID for Table A1, leader_cab_id for Table A2) on the full dataset before applying the democracy1==0 & independent==1 filter. fixest drops fixed-effect singletons (no effect on coefficients) and uses its own small-sample clustered SE correction, which differs slightly from Stata's xtreg.
- (reproduction.json) Individual-level lfe::felm models translated to fixest::feols; the failed coup factor coupattempt_presentyear is coded as a 0/1 indicator (1 = 'Coup attempt'), equivalent to the factor dummy felm creates.

Agent notes: Attempt-1 was exploratory (variable inspection, no RESULT lines). Attempt-2 printed NA for the four country-level claims because update() on a formula containing '\|' merged regressors and fixed effects into one term; fixed by writing the formulas out. No comparison with claimed values was used to change the script. Individual-level Ns match the authors' appendix_k1/k2.tex (90020, 86057, 76530, 90014).

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 81,050 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T061959Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 887 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T061959Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 271 bytes, from `benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 795 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T061959Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T061959Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 8,381 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T061959Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 462 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T061959Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 5,404 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T061959Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 1,230 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T061959Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 14,647 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T061959Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,652 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T061959Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,579 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T061959Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 858 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T061959Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 15,394 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T061959Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
