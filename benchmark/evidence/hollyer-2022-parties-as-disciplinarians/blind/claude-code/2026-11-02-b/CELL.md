# hollyer-2022-parties-as-disciplinarians · blind · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T14:59:50Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-6papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T151025Z` |
| Run directory | `benchmark/reproductions/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-b` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 2) |
| Final | **13/13** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `personalism_volatility_difference_overall` | 0.3 (0.06) | 0.296601 | 1.13% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_overall` | -0.11 (0.05) | -0.111677 | 1.52% | ±0.05 (se_band) | PASS | PASS |
| `personalism_volatility_difference_nonethnic` | 0.35 (0.06) | 0.353671 | 1.05% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_nonethnic` | -0.15 (0.06) | -0.148187 | 1.21% | ±0.06 (se_band) | PASS | PASS |
| `personalism_ethnic_minus_nonethnic_low_volatility` | 0.31 (0.13) | 0.305323 | 1.51% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_ethnic_minus_nonethnic_high_volatility` | 0.2 (0.06) | 0.20353 | 1.76% | ±0.06 (se_band) | PASS | PASS |
| `personalism_volatility_difference_moderate` | 0.53 (0.13) | 0.530185 | 0.03% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_moderate` | -0.3 (0.08) | -0.298719 | 0.43% | ±0.08 (se_band) | PASS | PASS |
| `personalism_extremist_minus_moderate_low_volatility` | 0.15 (0.17) | 0.126349 | 15.77% | ±0.17 (se_band) | PASS | PASS |
| `programmaticness_extremist_minus_moderate_high_volatility` | 0.44 (0.09) | 0.371349 | 15.60% | ±0.09 (se_band) | PASS | PASS |
| `n_obs_table1` | 431 | 431 | 0.00% | ±21.55 (relative) | PASS | PASS |
| `rd_effect_young` | -0.084 | -0.08427 | 0.32% | ±0.00168 (relative) | PASS | PASS |
| `rd_effect_young_outsider` | -0.092 | -0.092132 | 0.14% | ±0.00184 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: attempt-1 was exploratory only (variable summaries, missingness, complete-case counts; no RESULT lines). Final run: Table 1 is a party-level OLS of personal / programmatic on ev_total plus party covariates (partysize, unions, business, religious) and country covariates (pluralty, pr [mixed omitted], closed- and open-list dummies from cl [non-list omitted], mdmh, polity, demsys, assembly-elected and parliamentary dummies from system [presidential omitted], gdppc, gini, ethfrac). SEs clustered by ccode (HC1). Each model uses its own complete-case sample: 431 parties / 75 countries for the overall and ethnic models, 430 for the extremism models (one party lacks extremist2). n_obs_table1 is reported as 431. Ethnic party = ethnic > 0.5 (the variable is already 0/1 in the data). Extremism = extremist2 (vote-share-weighted absolute left-right distance from the country mean); extremist party at 3, moderate at 0. Low and high volatility are the 25th and 75th percentiles of ev_total over the party-level estimation sample (Stata-style percentile definition, R type 2). The differences are linear combinations of coefficients, so where the other covariates are held does not affect them. Table 2: rdrobust on the open-seat sample (dlameduck_runs == 0), running variable mv_incparty, cutoff 0, local linear, triangular kernel, mserd bandwidths; the RESULT is the conventional estimate. The authors' scripts and any result files were not opened; the codebook PDF in the mount was read for variable definitions.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 19,354 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T151025Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 918 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T151025Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 277 bytes, from `benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,198 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T151025Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T151025Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 9,145 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T151025Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,007 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T151025Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,480 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T151025Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T151025Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,563 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T151025Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
