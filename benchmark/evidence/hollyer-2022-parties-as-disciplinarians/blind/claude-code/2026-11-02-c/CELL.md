# hollyer-2022-parties-as-disciplinarians · blind · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `hollyer-2022-parties-as-disciplinarians` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:22:33Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T202753Z` |
| Run directory | `benchmark/reproductions/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-c` |
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

- (reproduction.json) Covariate set reconstructed from the paper text: party size, union/business/religious linkages; plurality and PR dummies (mixed omitted); ballot-rule dummies from cl (cl=1 omitted, codes unlabelled in the data); logged mean district magnitude; Polity; democracy tenure (demsys); separation of powers as dummies for system (presidential omitted); logged GDP pc; Gini; ethnic fractionalization. ctot (commodity terms of trade) not used since the paper does not list it.
- (reproduction.json) Volatility 25th/75th percentiles computed on the party-level estimation sample with the Stata _pctile definition (R quantile type 2).
- (reproduction.json) Extremism measure: extremist2 (overall left-right distance from country mean, labelled 'weighted by size'); extremist party set at distance 3. Ideology regressions use 430 parties (one missing extremism); n_obs_table1 reported from the common base sample (431 parties, 75 countries).
- (reproduction.json) Brazil RD sample: dlameduck_runs == 0 (incumbent mayor did not run for a second term at t, so the winner at t is not term-limited at t+1); rdrobust p=1, triangular kernel, mserd bandwidths, no clustering; conventional point estimate reported.

Agent notes: Attempt-1 was an exploratory variable inspection (no RESULT lines). The final run is the first and only scored run; no claim-based tuning. Disclosure: while reading the Brazil RD method passage of paper.txt (lines ~1394-1405), the text contained rough Table 2 point estimates and robust CIs that were not fully withheld; the RD specification (open-seat sample, rdrobust defaults, mserd) was fixed from the method description and Table 2 note and was not adjusted. No docker hangs.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 19,831 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T202753Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 918 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T202753Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 277 bytes, from `benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 912 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T202753Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T202753Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,128 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T202753Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,134 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T202753Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,755 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T202753Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T202753Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,141 bytes, from `benchmark/results/artifacts/hollyer-2022-parties-as-disciplinarians/blind/claude-code/20261102T202753Z/stdout.txt`
