# hollyer-2022-parties-as-disciplinarians · blind · claude-code · 2026-11-02-a

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-a |
| Date | 2026-11-02T01:50:00Z |
| Results file | `benchmark/results/claude-code-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T142249Z` |
| Run directory | `benchmark/reproductions/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a` |
| Executions | 3 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 3) |
| Final | **13/13** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `personalism_volatility_difference_overall` | 0.3 (0.06) | 0.292232 | 2.59% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_overall` | -0.11 (0.05) | -0.115558 | 5.05% | ±0.05 (se_band) | PASS | PASS |
| `personalism_volatility_difference_nonethnic` | 0.35 (0.06) | 0.352372 | 0.68% | ±0.06 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_nonethnic` | -0.15 (0.06) | -0.148855 | 0.76% | ±0.06 (se_band) | PASS | PASS |
| `personalism_ethnic_minus_nonethnic_low_volatility` | 0.31 (0.13) | 0.311271 | 0.41% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_ethnic_minus_nonethnic_high_volatility` | 0.2 (0.06) | 0.195941 | 2.03% | ±0.06 (se_band) | PASS | PASS |
| `personalism_volatility_difference_moderate` | 0.53 (0.13) | 0.530185 | 0.03% | ±0.13 (se_band) | PASS | PASS |
| `programmaticness_volatility_difference_moderate` | -0.3 (0.08) | -0.298719 | 0.43% | ±0.08 (se_band) | PASS | PASS |
| `personalism_extremist_minus_moderate_low_volatility` | 0.15 (0.17) | 0.126349 | 15.77% | ±0.17 (se_band) | PASS | PASS |
| `programmaticness_extremist_minus_moderate_high_volatility` | 0.44 (0.09) | 0.371349 | 15.60% | ±0.09 (se_band) | PASS | PASS |
| `n_obs_table1` | 431 | 430 | 0.23% | ±4.31 (relative) | PASS | PASS |
| `rd_effect_young` | -0.084 | -0.08427 | 0.32% | ±0.00168 (relative) | PASS | PASS |
| `rd_effect_young_outsider` | -0.092 | -0.092132 | 0.14% | ±0.00184 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Volatility 25th/75th percentiles taken over the party-level estimation sample (N=430) using Stata-style percentiles (R quantile type 2); the paper says only 'in the sample'.
- (reproduction.json) Ethnic party coded as ethnic > 0.5 (strict majority of expert coders report ethnic/linguistic linkages).
- (reproduction.json) Ideological extremism uses the supplied extremist2 variable (per the codebook, vote-share-weighted absolute distance from the country mean left-right placement); extremist party at distance 3, moderate at 0.
- (reproduction.json) Country covariates coded as: pluralty and pr dummies (mixed omitted); closed-list (cl==1) and open-list (cl==2) dummies (non-list omitted); mdmh; polity; demsys; system as a 3-level factor (presidential omitted); gdppc; gini; ethfrac. Party covariates: partysize, unions, business, religious.
- (reproduction.json) Table 1 sample is complete cases on both outcomes, volatility, all covariates, ethnic and extremist2 (430 parties, 75 countries), so every panel uses the same sample.

Agent notes: Table 1: OLS with country-clustered (HC1/CR1) SEs; the quantities are linear combinations of coefficients (beta*(p75-p25) for the volatility differences; b_group + b_interaction*vol for group differences), which do not depend on the covariate values. Table 2: rdrobust (local linear, triangular kernel, mserd bandwidths) on the open-seat sample (dlameduck_runs==0), running variable mv_incparty, cutoff 0; conventional point estimate reported. attempt-1 was an exploratory run (no RESULT lines). attempt-2: docker ran before the script file existed, because the sandbox guard refused the command that would have written it; Docker created an empty directory at script.R, nothing ran, and there was no output. attempt-2/script.R is an empty placeholder recording that. The codebook.pdf inside the mount was read for variable definitions. The authors' .do/.R scripts were not opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 19,354 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T142249Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 918 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T142249Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 277 bytes, from `benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 875 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T142249Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T142249Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 4,819 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T142249Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 428 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T142249Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T142249Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T142249Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T142249Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,419 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T142249Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,973 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T142249Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T142249Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,833 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T142249Z/stdout.txt`
