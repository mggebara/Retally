# douenne-2022-yellow-vests-carbon-tax · seeded · claude-code · 2026-11-02-a

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-a |
| Date | 2026-11-02T10:08:00Z |
| Results file | `benchmark/results/claude-code-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T142251Z` |
| Run directory | `benchmark/reproductions/douenne-2022-yellow-vests-carbon-tax/seeded/2026-11-02-a` |
| Executions | 4 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 4) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.268692 | 0.11% | ±0.00538 (relative) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.306132 | 0.04% | ±0.00612 (relative) | PASS | PASS |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.208177 | 0.09% | ±0.00416 (relative) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.246062 | 0.03% | ±0.00492 (relative) | PASS | PASS |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.015333 | 2.22% | ±0.0005 (printed_precision) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.019281 | 1.48% | ±0.0005 (printed_precision) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.16612 | 0.07% | ±0.00332 (relative) | PASS | PASS |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.151474 | 0.31% | ±0.00302 (relative) | PASS | PASS |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.079694 | 0.38% | ±0.0016 (relative) | PASS | PASS |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.153068 | 0.04% | ±0.00306 (relative) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±7.57 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.534048 | 0.01% | ±0.01068 (relative) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.415553 | 0.11% | ±0.00832 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Hmisc/memisc 'labelled'/'.item' column classes were stripped to plain vectors (memisc is not installed); numeric memisc items such as diplome4 and taille_agglo therefore enter as numeric regressors.

Agent notes: Followed papier.R: Table 4 = reg_effect_feedback_1..4 (weighted lm, subset variante_taxe_info=='f' [& \|simule_gain\|<50]); Table 6 col 1 = manual 2SLS tsls1_si1/tsls2_si1 on the [p10,p60] subsample, instruments traite_cible*traite_cible_conjoint; Table 8 col 1 = manual 2SLS tsls1_ee1/tsls2_ee1, instruments apres_modifs + info_CC. Data from after_preparation.RData (as papier.R loads); control-name vectors rebuilt with piece.formula/variables_demo and checked identical to those stored in after_papier.RData. Attempts 1-2 were exploratory (attempt 1 crashed on a memisc class lookup while printing classes). Attempt 3 crashed on the same issue and was repaired. The final run's values were compared by eye with the claims; all round to the claimed values and no change followed, so there is no claim attempt.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 214,055 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T142251Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 772 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T142251Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 267 bytes, from `benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/seeded/2026-11-02-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,894 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T142251Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 276 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T142251Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 4,767 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T142251Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,509 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T142251Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T142251Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 5,303 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T142251Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 342 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T142251Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 5,958 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T142251Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 279 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T142251Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T142251Z/attempt-3/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,623 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T142251Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,027 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T142251Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T142251Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,264 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T142251Z/stdout.txt`
