# goni-2022-assortative-matching-london-season · independent · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `goni-2022-assortative-matching-london-season` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T05:29:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-all-modes-2026-11-09.json` |
| Artifacts | `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053040Z` |
| Run directory | `benchmark/reproductions/goni-2022-assortative-matching-london-season/independent/2026-11-10-a` |
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

- (reproduction.json) Probit marginal effects are reported as average marginal effects (mean of phi(xb) times beta); the paper does not state whether margins are average or at the means.

Agent notes: attempt-1 and attempt-2 are the same exploratory script (variable listing and tabulations, no RESULT lines). attempt-1 failed only because my host-side zsh wrapper mangled the -v mount argument ($M:r modifier), so the data path was not mounted; fixed the wrapper (quoted ${M}) and reran unchanged as attempt-2. The final run is the first and only estimation run; no claim comparison led to any script change. Data: data/final-data.dta with the prepared indicators base_sample (N=644), marital_rates_sample (N=765), syntheticT (treatment), cOut, mheir, fdown, celibacy, fmissmatch, fmissmatch2 (landholdings sample = non-missing fmissmatch, N=324). Controls per the Table 2 notes: pr4 (duke/marquess/earl daughter), hengpee (peerage of England), biorder (birth order excluding heirs); Panel B adds distlondon and drops women without a recorded seat (N=484/260/565, matching the paper). Probits via glm(probit) with average marginal effects of syntheticT; OLS via lm; birth-year clustered SEs (sandwich::vcovCL, HC1) with delta-method SEs for the marginal effects, printed for information. Bootstrap-t p-values not reproduced (not claimed). All coefficients, Ns, percent-correct and dependent-variable means match Table 2 to the reported rounding. README.pdf was not read (no pdftotext available); no script files in the package were opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 24,387 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053040Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 946 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053040Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 288 bytes, from `benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/independent/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,061 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053040Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 219 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053040Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053040Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 270 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053040Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,061 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053040Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 144 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053040Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 28,889 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053040Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 271 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053040Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,073 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053040Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,142 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053040Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053040Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,709 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053040Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 270 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/claude-code/20261110T053040Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
