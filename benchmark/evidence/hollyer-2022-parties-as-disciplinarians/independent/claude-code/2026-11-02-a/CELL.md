# hollyer-2022-parties-as-disciplinarians · independent · claude-code · 2026-11-02-a

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-a |
| Date | 2026-11-02T01:50:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T142247Z` |
| Run directory | `benchmark/reproductions/hollyer-2022-parties-as-disciplinarians/independent/2026-11-02-a` |
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

- (reproduction.json) Ethnic party coded as ethnic > 0.5 (majority of expert coders report ethnic/linguistic linkages); extremism uses extremist2 (vote-share-weighted absolute distance from country mean, per codebook) with the extremist party at distance 3 as the paper states.
- (reproduction.json) Covariate mapping inferred from paper text and codebook: partysize, unions, business, religious, pluralty, pr (mixed omitted), cl dummies (closed, open; non-list omitted), mdmh, polity, demsys, system dummies (presidential omitted), gdppc, gini, ethfrac. Volatility percentiles taken over the 431-party estimation sample. Extremism models use 430 parties (one missing extremist2).

Agent notes: Attempt-1 was exploratory (summaries, complete-case count = 431 parties / 75 countries). The final run is the first scored run; I compared it with the claims and did not change the script afterwards. Ten of 13 values match to the reported precision. The two extremist-minus-moderate differences come out as 0.126 and 0.371, against 0.15 and 0.44 claimed. Both are off by the same factor (~1.19), which suggests the paper's extremist party sits at an effective distance of about 3.56 rather than 3. I did not tune this. RD (open-seat sample, dlameduck_runs==0, rdrobust local linear, mserd) matches exactly: h=13.491, b=24.643, N=527/559.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,776 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T142247Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 950 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T142247Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 277 bytes, from `benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/independent/2026-11-02-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 903 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T142247Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T142247Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 4,364 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T142247Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,791 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T142247Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,121 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T142247Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T142247Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,974 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/independent/claude-code/20261102T142247Z/stdout.txt`
