# douenne-2022-yellow-vests-carbon-tax · blind · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T15:09:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-6papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z` |
| Run directory | `benchmark/reproductions/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-02-b` |
| Executions | 10 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 10) |
| Final | **12/13** |
| Package files withheld | 39 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.277352 | 3.10% | ±0.058 (se_band) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.231724 | 24.27% | ±0.066 (se_band) | FAIL | FAIL |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.217187 | 4.42% | ±0.035 (se_band) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.231703 | 5.81% | ±0.064 (se_band) | PASS | PASS |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | -0.027615 | 284.10% | ±0.087 (se_band) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.041092 | 116.27% | ±0.058 (se_band) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.193751 | 16.72% | ±0.079 (se_band) | PASS | PASS |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.154539 | 2.34% | ±0.069 (se_band) | PASS | PASS |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.140012 | 75.02% | ±0.079 (se_band) | PASS | PASS |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.137447 | 10.17% | ±0.045 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±37.85 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.540737 | 1.26% | ±0.132 (se_band) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.431648 | 3.76% | ±0.168 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) The paper's control lists are in the online Appendix, which is not available. Controls were constructed as: incomes = respondent and second-adult income percentiles with kinks at the 20th and 70th percentiles (min(I-20,0), min(I-70,0)); estimated gains = simule_gain and its square; sociodemo = sex, age group, employment status, socio-professional category, region, diploma (4 levels), agglomeration size, household size, number of members aged 14+; other motives = belief in environmental effectiveness (taxe_efficace, 3 levels) and progressivity belief (prog_na, including the not-asked category).
- (reproduction.json) Table 8: the information on the scientific consensus about effectiveness (Z_E) has no dedicated variable; apres_modifs (listed among the dataset's random-treatment variables, the post-modification survey wave) was used as Z_E. Because the progressivity question exists only in that wave, progressivity was left out of the Table 8 controls (it would be collinear with Z_E); there other motives = initial win/lose category.
- (reproduction.json) Predicted winner = simule_gagnant (the feedback actually shown); estimated net gain = simule_gain (EUR/year). Yellow Vests supporter = gilets_jaunes >= 1 (supports or is part of). Table 4 col. 3 adds the initial win/lose category as a factor plus winner interactions with initial acceptance, Yellow Vests support and initial not-lose belief.
- (reproduction.json) Table 6 col. 1 sample: respondent or second-adult income percentile in [10, 60] (percentile_revenu_conjoint used as stored). Eligibility instruments = traite_cible, traite_cible_conjoint and their product; controls include policy-assigned (cible) fixed effects, single-adult dummy and initial acceptance.
- (reproduction.json) All regressions unweighted OLS/2SLS (fixest), heteroskedasticity-robust SEs (SEs not scored).

Agent notes: Data: s (3002 respondents) from code/after_preparation.RData; memisc item classes stripped to plain vectors since memisc is not installed. Attempts 1-8 were exploratory (variable inspection; several crashed on memisc classes; none printed RESULT lines). Inside the mount I also read README.md (file listing), the header rows of code/survey.csv and code/questionnaire.qsf to identify the effectiveness-information variable; no scripts or result files were opened. Attempt 9 was the first estimation run and crashed because apres_modifs is stored as TRUE/FALSE strings; fixed with a string-to-indicator helper, no specification change. Table 4 N(\|gain\|<50) = 757; Table 6 N = 1969; Table 8 N = 3002.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 27,542 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 875 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 272 bytes, from `benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-02-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 449 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 38,623 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,980 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 276 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,111 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 3,231 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 1,010 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 13,817 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-3/stdout.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 2,381 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 275 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 122 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-4/stdout.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 2,415 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 275 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 122 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-5/stdout.txt`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 2,422 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 278 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 122 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-6/stdout.txt`
- [`output/attempt-7/script.R`](output/attempt-7/script.R) — 2,487 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-7/script.R`
- [`output/attempt-7/stderr.txt`](output/attempt-7/stderr.txt) — 105 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-7/stderr.txt`
- [`output/attempt-7/stdout.txt`](output/attempt-7/stdout.txt) — 1,923 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-7/stdout.txt`
- [`output/attempt-8/script.R`](output/attempt-8/script.R) — 2,465 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-8/script.R`
- [`output/attempt-8/stderr.txt`](output/attempt-8/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-8/stderr.txt`
- [`output/attempt-8/stdout.txt`](output/attempt-8/stdout.txt) — 2,807 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-8/stdout.txt`
- [`output/attempt-9/feedback.txt`](output/attempt-9/feedback.txt) — 473 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-9/feedback.txt`
- [`output/attempt-9/script.R`](output/attempt-9/script.R) — 6,515 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-9/script.R`
- [`output/attempt-9/stderr.txt`](output/attempt-9/stderr.txt) — 669 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-9/stderr.txt`
- [`output/attempt-9/stdout.txt`](output/attempt-9/stdout.txt) — 1,003 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/attempt-9/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 3,427 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,644 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 477 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,011 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261102T151025Z/stdout.txt`
