# hollyer-2022-parties-as-disciplinarians · blind · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T20:46:56Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261108T015655Z` |
| Run directory | `benchmark/reproductions/hollyer-2022-parties-as-disciplinarians/blind/2026-11-07-a` |
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

- (reproduction.json) Volatility 25th/75th percentiles taken over the party-level estimation sample using Stata's _pctile definition (R quantile type 2); the paper says only 'in the sample'.
- (reproduction.json) Separation-of-powers covariate entered as dummies for assembly-elected and parliamentary systems (presidential omitted); ballot rules as closed-list and open-list dummies (non-list omitted); electoral system as plurality and PR dummies (mixed omitted). Covariate set follows the paper text: party size, union/business/religious links, electoral system, ballot rules, logged mean district magnitude, polity, democratic tenure, political system, logged GDP pc, Gini, ethnic fractionalization.
- (reproduction.json) Ethnic party = more than half of expert coders report ethnic/linguistic linkages (ethnic > 0.5). Ideological extremism = extremist2; extremist party evaluated at distance 3, moderate at 0.
- (reproduction.json) Each Table 1 regression uses its own complete cases: 431 parties (75 countries) for the overall and ethnicity models, 430 for the ideology model (one party lacks extremist2). n_obs_table1 reports 431.

Agent notes: Table 1: OLS (fixest) of personal / programmatic on ev_total plus party- and country-level covariates, SEs clustered by country; the reported differences are linear combinations of the coefficients (high minus low volatility = beta*(p75-p25); group differences include the interaction evaluated at p25 or p75), so they do not depend on where the other covariates are held. Table 2: rdrobust, local linear, triangular kernel, mserd bandwidths, cutoff 0, running variable mv_incparty, open-seat sample dlameduck_runs==0; the conventional point estimate is reported. One exploratory run (attempt-1, no RESULT lines) inspected the variables; the final run is the first and only scored run. The mount held no author scripts; the codebook.pdf (variable definitions only) and 00-README.txt were read.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 20,106 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261108T015655Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 918 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261108T015655Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 290 bytes, from `benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/blind/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,100 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261108T015655Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261108T015655Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 6,216 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261108T015655Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 259 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261108T015655Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,368 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261108T015655Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,611 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261108T015655Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261108T015655Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,734 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261108T015655Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 260 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261108T015655Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
