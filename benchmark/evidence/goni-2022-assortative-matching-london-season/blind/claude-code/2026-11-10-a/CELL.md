# goni-2022-assortative-matching-london-season · blind · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `goni-2022-assortative-matching-london-season` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T05:29:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-all-modes-2026-11-09.json` |
| Artifacts | `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053042Z` |
| Run directory | `benchmark/reproductions/goni-2022-assortative-matching-london-season/blind/2026-11-10-a` |
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

- (reproduction.json) Probit columns report the average marginal effect (dP/dT averaged over the estimation sample) of the synthetic probability; the paper does not say whether its marginal effects are averaged or evaluated at the means.
- (reproduction.json) Samples and the treatment use the flags/variables shipped in data/final-data.dta (base_sample, marital_rates_sample, syntheticT, cOut, mheir, fmissmatch, fmissmatch2, fdown, celibacy, distlondon); the synthetic probability was not rebuilt from the 1815-1830 benchmark cohort. Sample sizes with a family seat (484, 260, 565) and SD of T (7.3) agree with figures stated in the paper text.
- (reproduction.json) Standard errors (printed for information only, not scored) are clustered by birth year (byear), which has 22 distinct values in the data versus G = 21 stated in the paper; bootstrap-t p-values were not computed.

Agent notes: Blind independent reproduction of Goni (2022) Table 2, Panels A and B. Controls: duke/marquess/earl daughter (pr4), English peerage (hengpee), birth order excluding heirs (biorder); Panel B adds distlondon. Probit (glm probit link) for married a commoner, married an heir, married down, never married; OLS (fixest) for absolute and husband-minus-wife landholdings percentile-rank differences. Landholdings sample = baseline women with non-missing fmissmatch (324; 260 with a seat). Never-married outcome = celibacy in the marital-rates sample (765). attempt-1 and attempt-2 were exploratory (variable listing, sample checks); they print no RESULT lines. No author scripts or result files were opened (none appeared in the mount besides .mxd map files, which were not read).

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 24,953 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053042Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 915 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053042Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 288 bytes, from `benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/blind/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 629 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053042Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053042Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 27,956 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053042Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 265 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053042Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,482 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053042Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053042Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 4,270 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053042Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 265 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053042Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,165 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053042Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,953 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053042Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 124 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053042Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,122 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053042Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 265 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/claude-code/20261110T053042Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
