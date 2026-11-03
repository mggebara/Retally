# bokobza-2022-morning-after-coup-purges · seeded · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T19:33:45Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-23papers-seeded-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T194315Z` |
| Run directory | `benchmark/reproductions/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b` |
| Executions | 3 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 11/11 (execution 3) |
| Final | **11/11** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `failed_coup_base_country_fe` | 0.1 (0.03) | 0.098488 | 1.51% | ±0.005 (printed_precision) | PASS | PASS |
| `failed_coup_main_country_fe` | 0.11 (0.03) | 0.105549 | 4.05% | ±0.005 (printed_precision) | PASS | PASS |
| `failed_coup_base_leader_fe` | 0.08 (0.03) | 0.083868 | 4.83% | ±0.005 (printed_precision) | PASS | PASS |
| `failed_coup_main_leader_fe` | 0.09 (0.03) | 0.085272 | 5.25% | ±0.005 (printed_precision) | PASS | PASS |
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

- (reproduction.json) Country-level xtreg, fe with i.YEAR_DATA translated to fixest::feols with panel (COUNTRY_ID or leader_cab_id) and year fixed effects, clustered by COUNTRY_ID; Stata L. lags reproduced as the value at (same xtset panel, year-1), missing across gaps, so leader-FE lags are within leader tenure. fixest drops fixed-effect singletons, which does not change the point estimates.
- (reproduction.json) Individual-level felm models translated to feols; the failed coup factor was recoded to a 0/1 indicator (fca) so the main FCA coefficient is the effect for the reference category, as in the authors' * interaction models.

Agent notes: Attempt-1 was exploratory (variable types, factor levels, uniqueness of panel keys; no RESULT lines). Attempt-2 crashed because update(f, . ~ . \| FE) collapsed the regressors into one dropped term; fixed by writing formulas explicitly. Final run follows the authors' do-file (Appendix A) and R script (Appendix K). Individual-level Ns match Tables K1/K2 exactly (90020, 86057, 76530, 90014); all eleven coefficients match the claimed values at reported precision. Country-level Ns: 3714/3676 (country FE), 3282/3261 (leader FE) after fixest singleton removal. No claim-feedback refinement was made.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 81,050 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T194315Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 887 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T194315Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 271 bytes, from `benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 791 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T194315Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T194315Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,119 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T194315Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 297 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T194315Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 5,236 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T194315Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 1,048 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T194315Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,103 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T194315Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,763 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T194315Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,445 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T194315Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 860 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T194315Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 11,628 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/claude-code/20261102T194315Z/stdout.txt`
