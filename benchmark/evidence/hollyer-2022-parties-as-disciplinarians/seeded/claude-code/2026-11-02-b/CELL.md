# hollyer-2022-parties-as-disciplinarians · seeded · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T19:42:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-23papers-seeded-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/seeded/claude-code/20261102T194315Z` |
| Run directory | `benchmark/reproductions/hollyer-2022-parties-as-disciplinarians/seeded/2026-11-02-b` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 13/13 |
| First scored | 13/13 (execution 1) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `personalism_volatility_difference_overall` | 0.3 (0.06) | 0.296601 | 1.13% | ±0.006 (relative) | PASS | PASS |
| `programmaticness_volatility_difference_overall` | -0.11 (0.05) | -0.111677 | 1.52% | ±0.005 (printed_precision) | PASS | PASS |
| `personalism_volatility_difference_nonethnic` | 0.35 (0.06) | 0.353671 | 1.05% | ±0.007 (relative) | PASS | PASS |
| `programmaticness_volatility_difference_nonethnic` | -0.15 (0.06) | -0.148187 | 1.21% | ±0.005 (printed_precision) | PASS | PASS |
| `personalism_ethnic_minus_nonethnic_low_volatility` | 0.31 (0.13) | 0.305323 | 1.51% | ±0.0062 (relative) | PASS | PASS |
| `programmaticness_ethnic_minus_nonethnic_high_volatility` | 0.2 (0.06) | 0.20353 | 1.76% | ±0.005 (printed_precision) | PASS | PASS |
| `personalism_volatility_difference_moderate` | 0.53 (0.13) | 0.530185 | 0.03% | ±0.0106 (relative) | PASS | PASS |
| `programmaticness_volatility_difference_moderate` | -0.3 (0.08) | -0.298719 | 0.43% | ±0.006 (relative) | PASS | PASS |
| `personalism_extremist_minus_moderate_low_volatility` | 0.15 (0.17) | 0.149583 | 0.28% | ±0.005 (printed_precision) | PASS | PASS |
| `programmaticness_extremist_minus_moderate_high_volatility` | 0.44 (0.09) | 0.439637 | 0.08% | ±0.0088 (relative) | PASS | PASS |
| `n_obs_table1` | 431 | 431 | 0.00% | ±21.55 (relative) | PASS | PASS |
| `rd_effect_young` | -0.084 | -0.08427 | 0.32% | ±0.00168 (relative) | PASS | PASS |
| `rd_effect_young_outsider` | -0.092 | -0.092132 | 0.14% | ±0.00184 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Single run, no prior attempts. Table 1: OLS (fixest::feols, country-clustered SEs) following cross-national-analysis.do and cross-national-designate-controls.do: party controls partysize unions business religious; country controls pluralty, factor(pr), factor(cl) base 3, mdmh, factor(system) base 1, demsys, polity, gdppc, gini/100, ethfrac. Stata margins at ev_total = p25/p75 of the estimation sample (Stata summarize-detail percentiles = R quantile type 2) and group attachment = 0 vs p90 in the estimation sample (ethnic p90 = 1; extremist2 p90 = 3.55, as in the authors' script rather than the paper's stated 3); for a linear model these predictive margins reduce to linear contrasts of the coefficients, computed directly. N = 431 parties in 75 countries (430 in the extremism models due to one missing extremist2). Table 2: rdrobust defaults (conventional local-linear estimate, MSE-optimal bandwidths) on dlameduck_runs == 0, running variable mv_incparty. Did not compute SEs/p-values since no claim needs them. Did not run check_attempt; compared by eye after the final run only, no changes made.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 74,047 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/seeded/claude-code/20261102T194315Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 813 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/seeded/claude-code/20261102T194315Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 272 bytes, from `benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/seeded/2026-11-02-b/paper.txt`

## What it produced

- [`output/reproduction.json`](output/reproduction.json) — 1,546 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/seeded/claude-code/20261102T194315Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,561 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/seeded/claude-code/20261102T194315Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 372 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/seeded/claude-code/20261102T194315Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,452 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/seeded/claude-code/20261102T194315Z/stdout.txt`
