# douenne-2022-yellow-vests-carbon-tax · blind · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:26:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z` |
| Run directory | `benchmark/reproductions/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-02-c` |
| Executions | 6 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 5) |
| Final | **13/13** |
| Package files withheld | 39 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.27222 | 1.20% | ±0.058 (se_band) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.246483 | 19.45% | ±0.066 (se_band) | PASS | PASS |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.226396 | 8.84% | ±0.035 (se_band) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.230106 | 6.46% | ±0.064 (se_band) | PASS | PASS |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | -0.007064 | 147.09% | ±0.087 (se_band) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.030443 | 60.23% | ±0.058 (se_band) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.181748 | 9.49% | ±0.079 (se_band) | PASS | PASS |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.148962 | 1.35% | ±0.069 (se_band) | PASS | PASS |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.148682 | 85.85% | ±0.079 (se_band) | PASS | PASS |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.144215 | 5.74% | ±0.045 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±37.85 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.543593 | 1.80% | ±0.132 (se_band) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.4348 | 4.52% | ±0.168 (se_band) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) The online-appendix control lists are not available; controls were constructed from the paper's description: socio-demographics (sex, age bracket, employment status, occupation, region, education, household size, number aged 14+, number of adults, smoker, news source, urban-area size, consumption units, following the dataset's variables_demo list minus income variables); incomes as a continuous piecewise-linear function of the respondent's and second adult's income percentiles with kinks at p20 and p70 (eq. 4); estimated gains as simule_gain and its square; other motives as belief in environmental effectiveness (Yes/No/PNR) and perceived progressivity (prog_not_no) in Tables 4 and 6, and initial win/lose category in Table 8.
- (reproduction.json) Table 8: the progressivity control was dropped because that question was asked only in the second half of the sample (apres_modifs), the same indicator as the effectiveness-information instrument, so it is mechanically zero in the instrument's control group (bad control). This change was made after attempt-5, whose first stage on this instrument was nearly absent (F about 2.3); Tables 4 and 6 were left unchanged.
- (reproduction.json) Yellow Vests supporter = gilets_jaunes > 0 (is part of or supports the movement). Predicted winner = simule_gagnant (the feedback actually shown); running variable = simule_gain (EUR/yr per c.u.). Initial win/lose belief G = initial category not 'Perdant'; column 3 also controls for the 3-level initial category.
- (reproduction.json) Table 6 [p10;p60] subsample: respondent percentile in [10,60], or a second adult (nb_adultes > 1) whose percentile is in [10,60]. Unweighted OLS/2SLS (fixest), heteroskedasticity-robust SEs (point estimates do not depend on this).
- (reproduction.json) memisc is not installed, so the labelled/memisc item columns were turned into plain vectors by stripping their attributes. No author functions stored in the RData were called.

Agent notes: Blind independent reproduction. Attempts 1-4 were exploratory (listing objects and variables, tabulating candidate variables, reading variable labels to identify the effectiveness-information indicator apres_modifs); attempt-2 crashed on memisc-classed columns and was exploratory. Attempt-5 was the first scored run; the final run differs from it only in the Table 8 control set (see deviations), and all Table 4 and Table 6 values are identical. The questionnaire.qsf and survey.csv header in the mount were grepped to identify variables; the dataset README.md was read. No script files were opened. No docker run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 28,019 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 875 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 272 bytes, from `benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 446 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 38,620 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,912 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 275 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,794 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 3,202 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 15,266 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/attempt-3/stdout.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 1,364 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 202 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 4,195 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/attempt-4/stdout.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 5,373 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 39,468 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/attempt-5/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 3,239 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,580 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 39,188 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T202753Z/stdout.txt`
