# douenne-2022-yellow-vests-carbon-tax · seeded · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T19:52:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-23papers-seeded-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z` |
| Run directory | `benchmark/reproductions/douenne-2022-yellow-vests-carbon-tax/seeded/2026-11-02-b` |
| Executions | 5 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 5) |
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
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±37.85 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.534048 | 0.01% | ±0.01068 (relative) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.415553 | 0.11% | ±0.00832 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) memisc is not installed in the sandbox, so memisc 'item' columns (e.g. taxe_approbation, taxe_efficace, gilets_jaunes, diplome4, taille_agglo) and Hmisc 'labelled' classes were stripped to their underlying values: character items enter lm as factors, double items as numeric, and no values are recoded as missing. With this, the Table 4 column 1 sample is 757, the same as the paper.
- (reproduction.json) The control-variable vectors (variables_reg_effect_feedback, variables_reg_self_interest, variables_reg_ee) are taken from after_papier.RData, where papier.R stored them; the data frame s comes from after_preparation.RData, as papier.R loads it.

Agent notes: Follows papier.R exactly, using weighted lm. Table 4 columns 1-4 are reg_effect_feedback_1..4. Table 6 column 1 is the manual two-step tsls_si1 on the [p10; p60] subsample, and Table 8 column 1 is the two-step tsls_ee1. These two-step point estimates equal weighted 2SLS. The 4 exploratory attempts inspected variable classes and memisc attributes and printed no RESULT lines; attempts 1-3 crashed while printing memisc S4 objects. The first scored run is the final run, and nothing was changed after any comparison with the claims.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 214,055 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 772 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 267 bytes, from `benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/seeded/2026-11-02-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,403 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 278 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 4,418 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,685 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 278 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,886 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 1,647 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 142 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 560 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/attempt-3/stdout.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 1,664 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 8,491 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/attempt-4/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,833 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,702 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,614 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/claude-code/20261102T194315Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
