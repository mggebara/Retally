# goni-2022-assortative-matching-london-season · seeded · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `goni-2022-assortative-matching-london-season` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T05:35:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-all-modes-2026-11-09.json` |
| Artifacts | `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/seeded/claude-code/20261110T053039Z` |
| Run directory | `benchmark/reproductions/goni-2022-assortative-matching-london-season/seeded/2026-11-10-a` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 13/13 |
| First scored | 13/13 (execution 1) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `treatment_married_commoner_table2_panelA_col1` | 0.005 (0.002) | 0.004534 | 9.32% | ±0.0005 (printed_precision) | PASS | PASS |
| `treatment_married_heir_table2_panelA_col2` | -0.004 (0.002) | -0.003631 | 9.22% | ±0.0005 (printed_precision) | PASS | PASS |
| `treatment_landholdings_diff_abs_table2_panelA_col3` | 0.524 (0.196) | 0.524469 | 0.09% | ±0.01048 (relative) | PASS | PASS |
| `treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4` | -0.516 (0.225) | -0.516195 | 0.04% | ±0.01032 (relative) | PASS | PASS |
| `treatment_married_down_table2_panelA_col5` | 0.009 (0.003) | 0.008983 | 0.19% | ±0.0005 (printed_precision) | PASS | PASS |
| `treatment_never_married_table2_panelA_col6` | 0.002 (0.002) | 0.002085 | 4.25% | ±0.0005 (printed_precision) | PASS | PASS |
| `treatment_married_commoner_table2_panelB_col1` | 0.006 (0.002) | 0.006195 | 3.25% | ±0.0005 (printed_precision) | PASS | PASS |
| `treatment_married_heir_table2_panelB_col2` | -0.005 (0.002) | -0.004689 | 6.22% | ±0.0005 (printed_precision) | PASS | PASS |
| `treatment_landholdings_diff_abs_table2_panelB_col3` | 0.512 (0.213) | 0.511759 | 0.05% | ±0.01024 (relative) | PASS | PASS |
| `treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4` | -0.537 (0.221) | -0.537401 | 0.07% | ±0.01074 (relative) | PASS | PASS |
| `n_obs_table2_panelA_baseline` | 644 | 644 | 0.00% | ±32.2 (relative) | PASS | PASS |
| `n_obs_table2_panelA_landholdings` | 324 | 324 | 0.00% | ±16.2 (relative) | PASS | PASS |
| `n_obs_table2_panelA_never_married` | 765 | 765 | 0.00% | ±38.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Translated Table 2 of programs/02_analysis/master-analysis.do: data/final-data.dta, base_sample==1 for cols 1-5 and marital_rates_sample==1 for col 6; controls pr4 biorder hengpee (+ distlondon in Panel B). Probits (cOut, mheir, fdown, celibacy) via glm probit with the average marginal effect of syntheticT (Stata margins, dydx(*) predict(pr)); OLS for fmissmatch/fmissmatch2. SEs clustered by byear (printed for information only). Single run; no claim comparison was used to change the script. The script was developed and run in a scratch directory and copied here with cp.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 217,447 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/seeded/claude-code/20261110T053039Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 802 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/seeded/claude-code/20261110T053039Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 283 bytes, from `benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/seeded/2026-11-10-a/paper.txt`

## What it produced

- [`output/reproduction.json`](output/reproduction.json) — 1,021 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/seeded/claude-code/20261110T053039Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,813 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/seeded/claude-code/20261110T053039Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/seeded/claude-code/20261110T053039Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,442 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/seeded/claude-code/20261110T053039Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 266 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/seeded/claude-code/20261110T053039Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
