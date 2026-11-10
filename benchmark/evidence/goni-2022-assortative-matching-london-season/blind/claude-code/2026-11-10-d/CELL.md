# goni-2022-assortative-matching-london-season · blind · claude-code · 2026-11-10-d

| | |
|---|---|
| Paper | `goni-2022-assortative-matching-london-season` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-d |
| Date | 2026-11-10T05:34:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run4-1paper-indep-blind-2026-11-09.json` |
| Artifacts | `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053413Z` |
| Run directory | `benchmark/reproductions/goni-2022-assortative-matching-london-season/blind/2026-11-10-d` |
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

- (reproduction.json) Probit marginal effects are average marginal effects (Stata margins dydx default); the paper does not say whether effects are averaged or evaluated at means.
- (reproduction.json) Used the dataset's pre-built sample flags (base_sample, marital_rates_sample), treatment (syntheticT), outcomes (cOut, mheir, fmissmatch, fmissmatch2, fdown) and controls (pr4, hengpee, biorder, distlondon) from data/final-data.dta; never married = nthismarriage == 0 in the marital-rates sample. A diagnostic rebuild of the synthetic probability from the 1815-1830 benchmark cohort correlates 0.9998 with syntheticT (small level differences from the exact exclusion rule).
- (reproduction.json) Standard errors (not scored) clustered by birth year (byear); probit AME SEs by delta method with CR0 cluster vcov. Bootstrap-t p-values not computed.

Agent notes: Two exploratory runs (variable listing; sample sizes and treatment by age) printed no RESULT lines, then one final run. Samples: baseline 644 married peers' daughters aged 15-35 in 1861; landholdings sample 324 (base with both spouses' Bateman landholdings); marital-rates sample 765. Panel B (distance to London) samples are 484 / 260 / 565, matching the Panel B observation counts printed in the paper text. Controls: duke/marquess/earl daughter indicator, English peerage indicator, birth order excluding heirs; Panel B adds distance from family seat to London. Probits via glm(probit), OLS via fixest. No script, log, table or README files from the package were opened. No runs hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 24,953 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053413Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 915 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053413Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 288 bytes, from `benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/blind/2026-11-10-d/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 970 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053413Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053413Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 29,298 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053413Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 265 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053413Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,260 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053413Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053413Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 6,959 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053413Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 265 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053413Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,047 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053413Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,586 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053413Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 124 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053413Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,068 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053413Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 264 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053413Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
