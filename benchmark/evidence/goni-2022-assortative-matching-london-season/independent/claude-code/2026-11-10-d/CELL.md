# goni-2022-assortative-matching-london-season · independent · claude-code · 2026-11-10-d

| | |
|---|---|
| Paper | `goni-2022-assortative-matching-london-season` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-d |
| Date | 2026-11-10T05:45:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run4-1paper-indep-blind-2026-11-09.json` |
| Artifacts | `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053313Z` |
| Run directory | `benchmark/reproductions/goni-2022-assortative-matching-london-season/independent/2026-11-10-d` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 2) |
| Final | **13/13** |
| Package files withheld | 120 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `treatment_married_commoner_table2_panelA_col1` | 0.005 (0.002) | 0.004534 | 9.32% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_heir_table2_panelA_col2` | -0.004 (0.002) | -0.003631 | 9.22% | ±0.002 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_abs_table2_panelA_col3` | 0.524 (0.196) | 0.524469 | 0.09% | ±0.196 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4` | -0.516 (0.225) | -0.516195 | 0.04% | ±0.225 (se_band) | PASS | PASS |
| `treatment_married_down_table2_panelA_col5` | 0.009 (0.003) | 0.008983 | 0.19% | ±0.003 (se_band) | PASS | PASS |
| `treatment_never_married_table2_panelA_col6` | 0.002 (0.002) | 0.002085 | 4.25% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_commoner_table2_panelB_col1` | 0.006 (0.002) | 0.006195 | 3.25% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_heir_table2_panelB_col2` | -0.005 (0.002) | -0.004689 | 6.22% | ±0.002 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_abs_table2_panelB_col3` | 0.512 (0.213) | 0.511759 | 0.05% | ±0.213 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4` | -0.537 (0.221) | -0.537401 | 0.07% | ±0.221 (se_band) | PASS | PASS |
| `n_obs_table2_panelA_baseline` | 644 | 644 | 0.00% | ±32.2 (relative) | PASS | PASS |
| `n_obs_table2_panelA_landholdings` | 324 | 324 | 0.00% | ±16.2 (relative) | PASS | PASS |
| `n_obs_table2_panelA_never_married` | 765 | 765 | 0.00% | ±38.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: attempt-1 was exploratory: it printed variable labels and summaries of data/final-data.dta and no RESULT lines. The final script uses the prepared flags base_sample (644) and marital_rates_sample (765), syntheticT as the treatment, and these outcomes: cOut, mheir, fmissmatch (absolute difference), fmissmatch2 (husband minus wife), fdown, and never married (nthismarriage==0, which is identical to celibacy). Controls are pr4 (duke/marquess/earl daughter), hengpee (English peerage) and biorder (birth order excluding heirs). Panel B adds distlondon. Probit columns report the average marginal effect of syntheticT, with delta-method SEs from a vcovCL birth-year cluster. OLS columns use feols with SEs clustered by byear. All claimed coefficients and Ns match on the first scored run, and the clustered SEs also match Table 2. No claim comparison or repair was needed. The bootstrap-t p-values were not computed because they were not claimed. No runs hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 24,387 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053313Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 946 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053313Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 288 bytes, from `benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/independent/2026-11-10-d/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,079 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053313Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053313Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 27,458 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053313Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 271 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053313Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,464 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053313Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,512 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053313Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 276 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053313Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,760 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053313Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 269 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053313Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
