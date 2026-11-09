# douenne-2022-yellow-vests-carbon-tax · blind · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T20:31:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z` |
| Run directory | `benchmark/reproductions/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-07-a` |
| Executions | 6 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 6) |
| Final | **12/13** |
| Package files withheld | 39 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.276967 | 2.96% | ±0.058 (se_band) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.226182 | 26.08% | ±0.066 (se_band) | FAIL | FAIL |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.217685 | 4.66% | ±0.035 (se_band) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.238731 | 2.95% | ±0.064 (se_band) | PASS | PASS |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | -0.008 | 153.33% | ±0.087 (se_band) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.034873 | 83.54% | ±0.058 (se_band) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.168126 | 1.28% | ±0.079 (se_band) | PASS | PASS |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.161231 | 6.78% | ±0.069 (se_band) | PASS | PASS |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.112906 | 41.13% | ±0.079 (se_band) | PASS | PASS |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.16032 | 4.78% | ±0.045 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±37.85 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.543457 | 1.77% | ±0.132 (se_band) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.429189 | 3.17% | ±0.168 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) The control lists ('sociodemo', 'other motives') are in the online appendix, which is not available. Used as sociodemo: gender, age bracket, employment status, socio-professional category, region, education (4 levels), town size, household size, number aged 14+, number of adults, consumption units, smoker, main news source. Other motives: for the self-interest regressions (Tables 4 and 6), belief in environmental effectiveness (Yes/No/PNR) and perceived progressivity (Yes/No/PNR/not asked); for Table 8, initial win/lose category and perceived progressivity.
- (reproduction.json) Incomes: continuous piecewise-linear terms in the income percentiles of the respondent and second adult, with kinks at the 20th and 70th percentiles (paper eq. for Table 5), used in every table. Estimated gains: simule_gain and its square, used in every table.
- (reproduction.json) Initial tax acceptance (not 'No') is included in all four Table 4 columns, because the task describes cols 2 and 4 as the col 1 regression on a different sample or outcome.
- (reproduction.json) Z_E (info on scientific consensus about effectiveness) was taken to be the variable apres_modifs, listed among the dataset's random variables (variables_aleatoires). It splits the sample by survey date rather than by visible randomisation, and it is the only variable besides info_CC with a first-stage effect on the effectiveness belief. variante_monetaire, the other candidate, has no effect on that belief. Our Table 8 first-stage F is only about 2, against the paper's effective F of 11, so this mapping may be wrong.
- (reproduction.json) All regressions use the survey weight 'weight' with heteroskedasticity-robust SEs (fixest). Predicted winner = simule_gagnant, the feedback actually shown. The \|gain\|<50 window uses simule_gain; the two disagree in sign for 56 respondents.
- (reproduction.json) Yellow Vests supporter = gilets_jaunes >= 1 (supports or is part of the movement). G = initial win/lose category not 'Perdant'. Table 6 subsample: respondent or second-adult income percentile in [10, 60], which gives 1,969 respondents as in the paper.

Agent notes: Data come from s in code/after_preparation.RData. The memisc column classes were stripped to base vectors, because memisc is not installed. Attempts 1-5 were exploratory only: listing variables and tabulating. Attempts 2-4 crashed on memisc classes or on cor() of a character vector; none printed RESULT lines. One botched launch happened before the current attempt-5: its script file had not been copied yet, so docker mounted an empty directory and nothing ran. Its empty output directory was deleted and attempt-5 was re-run properly. Table 4 col 1 N = 757, and Table 6 N = 1,969, as in the paper. The Table 6 first-stage F is 15.6, matching the range the paper reports. The Table 8 first stage is weak (F about 2), so that IV estimate is imprecise (SE about 0.38). No claimed values were seen or compared. The questionnaire.qsf in the mount was grepped briefly to find the effectiveness-info variable; this was not conclusive.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 28,294 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 875 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 285 bytes, from `benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 503 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 17,685 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 257 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,395 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 278 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 569 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 256 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 2,445 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 282 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 257 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-3/timing.json`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 2,663 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 105 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 11,626 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 257 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-4/timing.json`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 1,207 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 1,030 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-5/stdout.txt`
- [`output/attempt-5/timing.json`](output/attempt-5/timing.json) — 256 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/attempt-5/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 3,694 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,018 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 103 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 12,969 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 257 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261108T015647Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
