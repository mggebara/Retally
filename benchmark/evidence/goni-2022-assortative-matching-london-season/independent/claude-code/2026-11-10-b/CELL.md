# goni-2022-assortative-matching-london-season · independent · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `goni-2022-assortative-matching-london-season` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T05:29:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-all-modes-2026-11-09.json` |
| Artifacts | `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053041Z` |
| Run directory | `benchmark/reproductions/goni-2022-assortative-matching-london-season/independent/2026-11-10-b` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 3) |
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

- (reproduction.json) Probit marginal effects are average marginal effects (Stata margins default) computed by hand from glm probit; SEs (diagnostic only) via delta method with sandwich::vcovCL HC1 clustered by birth year. Bootstrap-t p-values were not reproduced.

Agent notes: Used data/final-data.dta only. Samples from the prepared flags base_sample (N=644) and marital_rates_sample (N=765); outcomes cOut, mheir, fmissmatch, fmissmatch2, fdown, celibacy (never married); treatment syntheticT; controls pr4 (duke/marquess/earl daughter), hengpee (English peerage), biorder (birth order excl. heirs); Panel B adds distlondon (complete cases: N=484 / 260 / 565). OLS for landholdings differences, probit AMEs for binary outcomes, SEs clustered by byear. attempt-1 listed variables; attempt-2 ran all models with no RESULT lines (diagnostic). Estimates, Ns, SEs, means of dependent variable and percent-correct all match Table 2 Panels A and B to reported precision. No claim or error attempts were needed. started_at is approximate. No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 24,387 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053041Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 946 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053041Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 288 bytes, from `benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/independent/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 801 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053041Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053041Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 25,739 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053041Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 271 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053041Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,284 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053041Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053041Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,081 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053041Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 270 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053041Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,580 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053041Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,089 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053041Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053041Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,890 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053041Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 271 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053041Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
