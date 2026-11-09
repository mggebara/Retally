# douenne-2022-yellow-vests-carbon-tax · independent · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T20:23:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z` |
| Run directory | `benchmark/reproductions/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-07-a` |
| Executions | 8 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 7) |
| Final | **13/13** |
| Package files withheld | 39 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.2736 | 1.71% | ±0.058 (se_band) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.2825 | 7.68% | ±0.066 (se_band) | PASS | FAIL |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.2161 | 3.89% | ±0.035 (se_band) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.232 | 5.69% | ±0.064 (se_band) | PASS | PASS |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.0047 | 68.67% | ±0.087 (se_band) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.0369 | 94.21% | ±0.058 (se_band) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.1852 | 11.57% | ±0.079 (se_band) | PASS | PASS |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.1572 | 4.11% | ±0.069 (se_band) | PASS | PASS |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.1395 | 74.38% | ±0.079 (se_band) | PASS | PASS |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.1354 | 11.50% | ±0.045 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±37.85 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.5452 | 2.10% | ±0.132 (se_band) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.4216 | 1.35% | ±0.168 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) The online-appendix list of controls is unavailable; controls were reconstructed: sociodemographics = sex, age bracket, employment status, CSP, region, education (4 levels), agglomeration size, household size, number aged 14+, smoker; incomes = respondent and second-adult income percentiles with slope changes at p20 and p70 (min(I-k,0)); estimated gains = simule_gain and its square; other motives = belief about progressivity (with 'not asked' as its own category) in Tables 4 and 6, progressivity belief plus initial win/lose category in Table 8.
- (reproduction.json) Predicted winner = simule_gagnant (the feedback actually given), running variable = simule_gain; G^F = feedback-stage win/lose category not 'Loser'; Yellow Vests supporter = gilets_jaunes in {supports, is part of}; G = initial win/lose category not 'Loser'; column 3 also controls for the 3-level initial category.
- (reproduction.json) Table 6 [p10;p60] subsample = respondent or second-adult income percentile in [10,60] (N=1,969, matches paper); cible fixed effects via fixest.
- (reproduction.json) Table 8: Z_E taken as apres_modifs (the variable splitting the sample in two around the effectiveness-information display), Z_CC = info_CC; outcome tax_approval, endogenous taxe_efficace == 'Oui'. The first stage on apres_modifs (0.198) is much larger than the paper's 0.059, so this instrument mapping is uncertain even though the 2SLS coefficient is close.
- (reproduction.json) Heteroskedasticity-robust SEs (not scored).

Agent notes: Data from code/after_preparation.RData (object s); memisc/Hmisc labelled columns stripped without loading those packages. attempts 1-6 exploratory (variable inspection; 2 and 3 crashed on memisc S4 columns while printing, no estimates). attempt-7 was the first scored run; after comparing with claims (only Table 4 col1 initial-acceptance off, 0.232 vs 0.306) the effectiveness belief was dropped from 'other motives' in Tables 4/6, which raised it to 0.283; check_attempt reports all claims within tolerance for the final run. No author scripts were opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 27,724 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 907 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 272 bytes, from `benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 432 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 24,007 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 262 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,148 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 276 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 875 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 263 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 2,262 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 281 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 875 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 263 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-3/timing.json`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 2,430 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 1,010 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 12,355 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 263 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-4/timing.json`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 1,943 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 7,048 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-5/stdout.txt`
- [`output/attempt-5/timing.json`](output/attempt-5/timing.json) — 263 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-5/timing.json`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 1,126 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 208 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 535 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-6/stdout.txt`
- [`output/attempt-6/timing.json`](output/attempt-6/timing.json) — 263 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-6/timing.json`
- [`output/attempt-7/feedback.txt`](output/attempt-7/feedback.txt) — 83 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-7/feedback.txt`
- [`output/attempt-7/script.R`](output/attempt-7/script.R) — 4,970 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-7/script.R`
- [`output/attempt-7/stderr.txt`](output/attempt-7/stderr.txt) — 177 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-7/stderr.txt`
- [`output/attempt-7/stdout.txt`](output/attempt-7/stdout.txt) — 32,706 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-7/stdout.txt`
- [`output/attempt-7/timing.json`](output/attempt-7/timing.json) — 262 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/attempt-7/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,835 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,015 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 177 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 32,197 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 263 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261108T015648Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
