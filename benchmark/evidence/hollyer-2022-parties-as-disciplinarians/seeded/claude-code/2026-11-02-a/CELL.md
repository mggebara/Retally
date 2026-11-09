# hollyer-2022-parties-as-disciplinarians · seeded · claude-code · 2026-11-02-a

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-a |
| Date | 2026-11-02T09:47:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/seeded/claude-code/20261102T142251Z` |
| Run directory | `benchmark/reproductions/hollyer-2022-parties-as-disciplinarians/seeded/2026-11-02-a` |
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

Agent notes: Single run. Table 1: OLS (fixest::feols, country-clustered SEs) of personal/programmatic on ev_total (+ ethnic or extremist2 interaction) with the authors' $p_controls and $controls (pr factor, cl base 3, system base 1, gini/100), listwise deletion as in Stata reg. Stata margins reproduced analytically from the linear coefficients: volatility at p25/p75 of e(sample) (Stata summarize-detail percentiles = R quantile type 2), group attachment at 0 vs p90 of e(sample) as in the authors' getmargins program (ethnic: 1; extremist2: 3.55, whereas the paper text says 3; the script was followed). N = 431 parties / 75 countries (430 in the extremism models). Table 2: rdrobust defaults (local linear, MSE-optimal h and b) on dlameduck_runs == 0. All values round to the claimed figures; no comparison-driven changes were made.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 74,047 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/seeded/claude-code/20261102T142251Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 813 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/seeded/claude-code/20261102T142251Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 272 bytes, from `benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/seeded/2026-11-02-a/paper.txt`

## What it produced

- [`output/reproduction.json`](output/reproduction.json) — 1,263 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/seeded/claude-code/20261102T142251Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,755 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/seeded/claude-code/20261102T142251Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 372 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/seeded/claude-code/20261102T142251Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,896 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/seeded/claude-code/20261102T142251Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
