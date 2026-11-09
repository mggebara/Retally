# hollyer-2022-parties-as-disciplinarians · independent · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:09:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T202751Z` |
| Run directory | `benchmark/reproductions/hollyer-2022-parties-as-disciplinarians/independent/2026-11-02-c` |
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

- (reproduction.json) Table 1 covariate set reconstructed from the paper text and codebook: party size, union/business/religious links; plurality and PR indicators (mixed omitted), list type (cl: closed/open/non-list, factor), logged mean district magnitude, Polity, log democratic tenure, political system (factor), log GDP per capita, Gini, ethnic fractionalization. Sample = complete cases on outcomes, volatility, these covariates and the ethnic-links variable (431 parties, 75 countries); the extremism models lose one party with missing extremist2 (430).
- (reproduction.json) Ethnic party = ethnic > 0.5 (majority of expert coders report ethnic/linguistic ties). Extremism = extremist2 (vote-weighted absolute left-right distance from country mean); extremist party evaluated at 3 as the paper states. Volatility p25/p75 taken over the party-level estimation sample. Predicted-value differences computed as linear contrasts of OLS coefficients; SEs clustered by country (HC1).
- (reproduction.json) Table 2: rdrobust defaults (local linear, triangular kernel, mserd bandwidth, NN variance) on the open-seat sample dlameduck_runs == 0, cutoff 0 on mv_incparty.

Agent notes: One exploratory run (attempt-1, no RESULT lines) to inspect variables and complete-case counts, then a single estimation run (final). No claim comparisons were made and no claim-driven changes. The RD estimates match Table 2 exactly (incl. bandwidths and effective N). Table 1 volatility differences match to two decimals; the extremist-minus-moderate contrasts at distance 3 come out smaller than the paper's (personalism low-volatility 0.126 vs 0.15; programmaticness high-volatility 0.371 vs 0.44), consistent in ratio with the paper having evaluated the extremist party at a somewhat larger distance (~3.5), but the paper text says 3, so 3 was kept. One launch of the run wrapper failed before docker started (output directory missing; a combined write+copy command had been refused by the sandbox guard); nothing executed, so it is not counted as an attempt.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 19,253 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T202751Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 950 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T202751Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 277 bytes, from `benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/independent/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,067 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T202751Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T202751Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 4,447 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T202751Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,488 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T202751Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,959 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T202751Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T202751Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,578 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T202751Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
