# goni-2022-assortative-matching-london-season · independent · claude-code · 2026-11-10-c

| | |
|---|---|
| Paper | `goni-2022-assortative-matching-london-season` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-c |
| Date | 2026-11-10T05:33:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run3-1paper-indep-blind-2026-11-09.json` |
| Artifacts | `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053312Z` |
| Run directory | `benchmark/reproductions/goni-2022-assortative-matching-london-season/independent/2026-11-10-c` |
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

- (reproduction.json) Probit marginal effects are computed as average marginal effects (mean of phi(xb) times beta); the paper does not say whether its marginal effects are averaged or taken at the means.

Agent notes: attempt-1 was exploratory: it listed the variables and labels in data/final-data.dta and printed no RESULT lines. The final script uses data/final-data.dta only. Samples come from the built-in flags: base_sample==1 (N=644) for columns 1-5, and marital_rates_sample==1 (N=765) for column 6. The landholdings columns use the observations where fmissmatch, fmissmatch2 or fdown are not missing (N=324). Panel B adds distlondon, which drops women without a recorded seat (N=484 and 260). Treatment is syntheticT. Controls are pr4 (duke/marquess/earl daughter), hengpee (English peerage) and biorder (birth order excluding heirs). Outcomes: cOut, mheir, fmissmatch (absolute difference), fmissmatch2 (husband minus wife), fdown, and celibacy (never married). Columns 1, 2, 5 and 6 are probits with average marginal effects; columns 3 and 4 are OLS. Standard errors are clustered by birth year (byear). The bootstrap-t p-values were not reproduced because they are not claimed. No claim-comparison iterations were needed. All 13 values match the paper at its reported precision, and the printed standard errors and dependent-variable means also match Table 2.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 24,387 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053312Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 946 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053312Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 288 bytes, from `benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/independent/2026-11-10-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 577 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053312Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053312Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 30,472 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053312Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 271 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053312Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,851 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053312Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,754 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053312Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053312Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,476 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053312Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 270 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053312Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
