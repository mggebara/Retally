# hollyer-2022-parties-as-disciplinarians · independent · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T20:46:58Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261108T015656Z` |
| Run directory | `benchmark/reproductions/hollyer-2022-parties-as-disciplinarians/independent/2026-11-07-a` |
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
| `n_obs_table1` | 431 | 431 | 0.00% | ±21.55 (relative) | PASS | PASS |
| `rd_effect_young` | -0.084 | -0.0843 | 0.36% | ±0.00168 (relative) | PASS | PASS |
| `rd_effect_young_outsider` | -0.092 | -0.0921 | 0.11% | ±0.00184 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: attempt-1 was an exploratory run that looked at the variables, missingness and complete-case counts, with no RESULT lines. The final script is the first scored run, and it was not changed after it ran. Table 1: party-level OLS of personal / programmatic on ev_total. Party covariates: partysize, unions, business, religious. Country covariates: pluralty and pr dummies (mixed omitted), cl as a factor (closed/open/non-list), mdmh, polity, demsys, system as a factor, gdppc, gini, ethfrac. SEs are clustered by country (ccode, HC1). Low and high volatility are the 25th and 75th percentiles of ev_total in the estimation sample. An ethnic party is one with ethnic > 0.5 (a majority of coders). Ideology models interact ev_total with extremist2; the moderate party is at 0 and the extremist party at 3. Sample: complete cases, N=431 in 75 countries; the ideology models have 430 because extremist2 is missing for one party. Table 2: rdrobust defaults (p=1, triangular kernel, mserd) on the open-seat sample (dlameduck_runs==0), running variable mv_incparty, cutoff 0; h, b, N and CIs match the paper. All cross-national quantities match the paper to two decimals except the two extremist-minus-moderate differences, 0.126 and 0.371 against 0.15 and 0.44. The moderate-party differences match exactly, so the gap probably comes from how the 'distance 3' extremist party is evaluated. The script was not tuned to close it.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 19,528 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261108T015656Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 950 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261108T015656Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 277 bytes, from `benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/independent/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 930 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261108T015656Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261108T015656Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 4,644 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261108T015656Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 265 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261108T015656Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,919 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261108T015656Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,224 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261108T015656Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261108T015656Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,546 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261108T015656Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 265 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261108T015656Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
