# goni-2022-assortative-matching-london-season · blind · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `goni-2022-assortative-matching-london-season` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T05:33:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-all-modes-2026-11-09.json` |
| Artifacts | `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z` |
| Run directory | `benchmark/reproductions/goni-2022-assortative-matching-london-season/blind/2026-11-10-b` |
| Executions | 4 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 4) |
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

- (reproduction.json) Probit marginal effects are average marginal effects of the treatment (Stata margins default); the paper does not say whether effects are evaluated at means or averaged.
- (reproduction.json) Treatment uses the syntheticT variable shipped in data/final-data.dta (a deterministic function of age in 1861) rather than recomputing p(t) from the 1815-1830 benchmark cohort.
- (reproduction.json) Samples use the shipped base_sample (644) and marital_rates_sample (765) flags; landholdings sample = base_sample with non-missing fmissmatch/fmissmatch2/fdown (324); Panel B additionally requires non-missing distlondon (484 / 260).
- (reproduction.json) Clustering by byear gives 22 clusters in the data versus G=21 stated in the paper; this affects only standard errors, which are not reported quantities.

Agent notes: Independent blind reproduction of Table 2 from data/final-data.dta only. Outcomes: cOut (married a commoner), mheir (married an heir), fmissmatch (\|husband-wife\| landholdings percentile difference), fmissmatch2 (husband-wife), fdown (married down), celibacy (never married). Controls: pr4 (duke/marquess/earl daughter), hengpee (peerage of England), biorder (birth order excluding heirs); Panel B adds distlondon. Probit (cols 1,2,5,6) via glm probit link, reporting AME of treatment; OLS (cols 3,4). SEs clustered by birth year (printed, not scored). Attempts 1-3 were exploratory (variable listing; attempt-1 crashed on a labelled-vector comparison in the listing code; attempt-3 checked sample sizes) and printed no RESULT lines. No author scripts, result tables (.tex/.pdf in results/) or README were opened. No runs hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 24,953 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 915 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 288 bytes, from `benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/blind/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 930 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 1,300 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 870 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 265 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 950 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 34,603 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 265 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 1,806 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 5,782 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 265 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/attempt-3/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,198 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,352 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,010 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 265 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053311Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
