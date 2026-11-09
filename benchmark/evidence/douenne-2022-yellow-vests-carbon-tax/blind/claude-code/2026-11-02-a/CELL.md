# douenne-2022-yellow-vests-carbon-tax · blind · claude-code · 2026-11-02-a

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-a |
| Date | 2026-11-02T14:17:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z` |
| Run directory | `benchmark/reproductions/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-02-a` |
| Executions | 7 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 6) |
| Final | **12/13** |
| Package files withheld | 39 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.281949 | 4.81% | ±0.058 (se_band) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.227924 | 25.52% | ±0.066 (se_band) | FAIL | FAIL |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.224876 | 8.11% | ±0.035 (se_band) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.227422 | 7.55% | ±0.064 (se_band) | PASS | PASS |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | -0.02537 | 269.13% | ±0.087 (se_band) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.037609 | 97.94% | ±0.058 (se_band) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.191002 | 15.06% | ±0.079 (se_band) | PASS | PASS |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.145431 | 3.69% | ±0.069 (se_band) | PASS | PASS |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.15118 | 88.98% | ±0.079 (se_band) | PASS | PASS |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.14324 | 6.38% | ±0.045 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±37.85 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.549709 | 2.94% | ±0.132 (se_band) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.426894 | 2.62% | ±0.168 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) The online-appendix control lists are unavailable. Controls were rebuilt from the data. Sociodemographics: sex, age bracket, employment status, CSP, education (4 levels), agglomeration size, region, household size, number aged 14+, left-right placement, smoker, main news source. Other motives: belief in environmental effectiveness and in progressivity. Incomes: continuous piecewise-linear terms in both adults' income percentiles with kinks at p20 and p70. Estimated gains: quadratic in the estimated net gain per consumption unit.
- (reproduction.json) Estimated net gain = simule_gain (EUR/yr per consumption unit). Predicted winner = simule_gagnant, the displayed feedback; it differs from 1{simule_gain>0} for 56 respondents, 52 of them inside the \|gain\|<50 band.
- (reproduction.json) Table 8: the progressivity belief is left out of the other-motive controls. It was only elicited in the survey wave that also received the effectiveness information (apres_modifs), so it is collinear with the instrument. The other-motive control there is the initial win/lose category.
- (reproduction.json) Yellow Vests supporter = Gilets_jaunes in {soutient, est_dedans}. The initial win/lose belief G = initial category not 'Loser'. Column 3 also controls for the 3-level initial category.
- (reproduction.json) Table 6 col 1 subsample = at least one adult's income percentile in [10,60] (both percentile variables as provided; 1,969 respondents). Eligibility instruments are traite_cible, traite_cible_conjoint and their product. Controls add policy-threshold fixed effects, a single-adult indicator and initial acceptance.
- (reproduction.json) Table 8 instruments: apres_modifs = info on the scientific consensus about effectiveness (identified by its effect on the effectiveness belief) and info_CC. Strict definitions: approval = 'Oui', effective = 'Oui'.
- (reproduction.json) Heteroskedasticity-robust standard errors (coefficients do not depend on this).
- (DEVIATION: line) control lists (online appendix) unavailable; sociodemo/other-motive/income controls reconstructed from variable names; heteroskedasticity-robust SEs.
- (DEVIATION: line) Table 8 other-motive controls = initial win/lose category only (progressivity belief omitted: its missingness coincides with the E.E. information wave, collinear with the instrument).

Agent notes: Data: the object s (3,002 respondents) from code/after_preparation.RData. memisc S4 columns were converted to base vectors because memisc is not installed. No scripts, logs or result files in the package were opened. Attempts 1-5 were exploratory and printed no RESULT lines. Attempts 2 and 3 crashed while converting the memisc columns. Before its final completed run, attempt 3 also hit Docker infrastructure failures: a 'Transport endpoint is not connected' mount error, hung containers stuck in 'Created', and a daemon crash. Docker Desktop was restarted and the identical script then ran. Attempt 6 was the first scored run. Its collinearity warning showed that the progressivity 'not asked' level was collinear with the effectiveness-information instrument, which collapsed the Table 8 first stage (F = 1.5). The final run drops that control from Table 8 only (first-stage F = 10.9). No paper values were consulted or compared. Paper numbers used were sample-description counts only: 1,968 feedback recipients and 1,969 respondents in the [p10;p60] subsample, both matched by construction.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 27,542 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 875 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 272 bytes, from `benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-02-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 367 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 17,671 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,983 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 275 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,230 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 3,374 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 117 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 86 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-3/stdout.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 3,559 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 95 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 12,462 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-4/stdout.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 2,422 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 2,475 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-5/stdout.txt`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 6,347 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 551 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 2,827 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/attempt-6/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 3,735 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,738 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 456 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,028 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T142249Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
