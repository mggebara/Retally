# douenne-2022-yellow-vests-carbon-tax · blind · claude-code · 2026-11-03-a

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-03-a |
| Date | 2026-11-03T00:16:00Z |
| Results file | `benchmark/results/claude-code-run4-redaction-3papers-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z` |
| Run directory | `benchmark/reproductions/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-03-a` |
| Executions | 7 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 7) |
| Final | **13/13** |
| Package files withheld | 39 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.274928 | 2.20% | ±0.058 (se_band) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.25531 | 16.57% | ±0.066 (se_band) | PASS | PASS |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.226401 | 8.85% | ±0.035 (se_band) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.237315 | 3.53% | ±0.064 (se_band) | PASS | PASS |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.002188 | 85.41% | ±0.087 (se_band) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.031253 | 64.49% | ±0.058 (se_band) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.173352 | 4.43% | ±0.079 (se_band) | PASS | PASS |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.16552 | 9.62% | ±0.069 (se_band) | PASS | PASS |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.087002 | 8.75% | ±0.079 (se_band) | PASS | PASS |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.147001 | 3.92% | ±0.045 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±7.57 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.559352 | 4.75% | ±0.132 (se_band) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.376286 | 9.55% | ±0.168 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) The paper's full control lists are in the online Appendix, which is not available. Controls were constructed as: sociodemographics = sex, age bracket, socio-professional category, education (4 levels), town size, region (factors), household size, number of members aged 14+; incomes = continuous piecewise-linear in income percentiles of respondent and second adult with kinks at p20 and p70 (paper eq. 4); estimated gains = simule_gain and its square; other motives = belief the tax is effective (not 'No') and belief it is progressive (prog_not_no). For Table 8 the other motives are progressivity belief and initial belief of not losing (effectiveness is the endogenous variable).
- (reproduction.json) All regressions use the survey weights (variable weight), since the paper states observations are weighted; heteroskedasticity-robust SEs.
- (reproduction.json) Predicted winner = simule_gagnant (the feedback actually displayed); running variable = simule_gain (estimated net gain per consumption unit); feedback sample = variante_taxe_info == 'f' (1,968). simule_gagnant disagrees with sign(simule_gain) for 56 respondents; used as is.
- (reproduction.json) Yellow Vests supporter = gilets_jaunes_soutien or gilets_jaunes_dedans. Table 4 col 3 controls for the 3-category initial win/lose belief (factor) and interacts the predicted-winner indicator with the binary initial not-lose belief.
- (reproduction.json) Table 6 col 1 subsample: respondent's or second adult's income percentile in [10, 60] (1,969 obs); instruments traite_cible, traite_cible_conjoint and their product; fixed effects for the assigned target (cible); controls single, initial acceptance, incomes, estimated gains, sociodemo, other motives.
- (reproduction.json) Table 8 col 1: info on effectiveness identified as apres_modifs (its label says the second half of the sample received the information on effectiveness against pollution); info on climate change = info_CC.

Agent notes: Independent, blind reproduction from paper text and after_preparation.RData (object s). Exploratory runs attempt-1..6 printed no RESULT lines (attempt-2, 3, 5 crashed because memisc is not installed and memisc item classes had to be stripped; they were exploratory, not repairs). Single scored run (top-level). Caveat: in the Table 8 first stage my effectiveness-information instrument (apres_modifs) is weak (coef ~0.009, joint first-stage F ~2.8), suggesting the variable or control set may differ from the authors'; I did not change the specification after seeing this, per blind-mode rules. While exploring the RData (attempt-1) the listing printed the bodies of some utility functions stored in the RData (plotting/formatting helpers, weighting_s, piece.formula); none of the paper's analysis code was read. No docker hang.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 28,019 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 875 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 285 bytes, from `benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-03-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 545 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 62,417 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,823 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 278 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,014 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 2,969 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 281 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-3/stdout.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 2,994 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 13,185 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-4/stdout.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 2,465 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 276 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 3,866 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-5/stdout.txt`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 2,489 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 7,418 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/attempt-6/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 3,474 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,967 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 456 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 17,329 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/claude-code/20261103T001658Z/stdout.txt`
