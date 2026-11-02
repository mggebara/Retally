# hollyer-2022-parties-as-disciplinarians · independent · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T14:58:00Z |
| Results file | `benchmark/results/claude-code-run2-6papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T151024Z` |
| Run directory | `benchmark/reproductions/hollyer-2022-parties-as-disciplinarians/independent/2026-11-02-b` |
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
| `personalism_volatility_difference_overall` | 0.3 (0.06) | 0.2966 | 1.13% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_overall` | -0.11 (0.05) | -0.1117 | 1.55% | ±0.05 (se_band) | PASS | PASS |
| `personalism_volatility_difference_nonethnic` | 0.35 (0.06) | 0.3537 | 1.06% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_nonethnic` | -0.15 (0.06) | -0.1482 | 1.20% | ±0.06 (se_band) | PASS | PASS |
| `personalism_ethnic_minus_nonethnic_low_volatility` | 0.31 (0.13) | 0.3053 | 1.52% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_ethnic_minus_nonethnic_high_volatility` | 0.2 (0.06) | 0.2035 | 1.75% | ±0.06 (se_band) | PASS | PASS |
| `personalism_volatility_difference_moderate` | 0.53 (0.13) | 0.5302 | 0.04% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_moderate` | -0.3 (0.08) | -0.2987 | 0.43% | ±0.08 (se_band) | PASS | PASS |
| `personalism_extremist_minus_moderate_low_volatility` | 0.15 (0.17) | 0.1263 | 15.80% | ±0.17 (se_band) | PASS | PASS |
| `programmaticness_extremist_minus_moderate_high_volatility` | 0.44 (0.09) | 0.3713 | 15.61% | ±0.09 (se_band) | PASS | PASS |
| `n_obs_table1` | 431 | 431 | 0.00% | ±4.31 (relative) | PASS | PASS |
| `rd_effect_young` | -0.084 | -0.0843 | 0.36% | ±0.00168 (relative) | PASS | PASS |
| `rd_effect_young_outsider` | -0.092 | -0.0921 | 0.11% | ±0.00184 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: attempt-1 was exploratory (variable summaries, complete-case counts; no RESULT lines). Final run: Table 1 via OLS (fixest, country-clustered SEs) of personal / programmatic on ev_total with party covariates (partysize, unions, business, religious) and country covariates (pluralty, pr, cl as factor, mdmh, polity, demsys, system as factor, gdppc, gini, ethfrac); complete-case sample gives 431 parties in 75 countries. Low/high volatility = 25th/75th percentile of ev_total in the estimation sample (Stata-like quantile type 2). Ethnic party = ethnic > 0.5 (majority of coders report ties); ethnic model adds ethnic_d and its interaction with ev_total. Ideology model adds extremist2 and its interaction (430 obs, one party missing extremist2); moderate = 0, extremist = 3. Differences in predicted values are linear combinations of coefficients, independent of covariate values. Brazil RD: rdrobust defaults (local linear, triangular kernel, mserd bandwidth) on the open-seat sample dlameduck_runs == 0; conventional point estimate reported. RD reproduces Table 2 exactly (h, b, N, CIs match). No claim comparison was used to modify the script.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,776 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T151024Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 950 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T151024Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 277 bytes, from `benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/independent/2026-11-02-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 876 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T151024Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T151024Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 4,331 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T151024Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,646 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T151024Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,687 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T151024Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T151024Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,254 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T151024Z/stdout.txt`
