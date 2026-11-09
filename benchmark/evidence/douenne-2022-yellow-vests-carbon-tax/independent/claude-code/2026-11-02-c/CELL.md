# douenne-2022-yellow-vests-carbon-tax · independent · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:09:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z` |
| Run directory | `benchmark/reproductions/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-02-c` |
| Executions | 6 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 6) |
| Final | **13/13** |
| Package files withheld | 39 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.2883 | 7.17% | ±0.058 (se_band) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.2705 | 11.60% | ±0.066 (se_band) | PASS | PASS |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.2408 | 15.77% | ±0.035 (se_band) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.2403 | 2.32% | ±0.064 (se_band) | PASS | PASS |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.0272 | 81.33% | ±0.087 (se_band) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.0267 | 40.53% | ±0.058 (se_band) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.1671 | 0.66% | ±0.079 (se_band) | PASS | PASS |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.1653 | 9.47% | ±0.069 (se_band) | PASS | PASS |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.1122 | 40.25% | ±0.079 (se_band) | PASS | PASS |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.1572 | 2.75% | ±0.045 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±37.85 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.5481 | 2.64% | ±0.132 (se_band) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.4162 | 0.05% | ±0.168 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) The paper's full control list is in the online appendix, which is not available; controls were reconstructed: incomes = respondent and second-adult income percentiles with kinks at the 20th and 70th percentiles (p, min(p-20,0), min(p-70,0)); estimated gains = simule_gain and its square; sociodemographics = sex, age bracket, socio-professional category, education (4), town size, region, consumption units, number aged 14+, smoker, main news source; other motives = belief the tax is effective (not 'No') in Tables 4 and 6, and the initial win/lose category in Table 8.
- (reproduction.json) All regressions use the survey weights (weight) and heteroskedasticity-robust SEs.
- (reproduction.json) Table 6 subsample built as respondent percentile in [10,60] or (more than one adult and second-adult percentile in [10,60]); this gives 1,961 observations versus 1,969 in the paper.
- (reproduction.json) Effectiveness information treatment Z_E identified as the apres_modifs indicator (the random half-split whose first-stage effect on believing in effectiveness is about 6 p.p.).

Agent notes: Data: s (3,002 respondents) from after_preparation.RData; memisc-classed columns were stripped to base vectors because memisc is not installed in the sandbox. Attempts 1-4 were exploratory (object/column listing and variable tabulations; attempts 2-3 crashed on memisc classes during exploration and printed no RESULT lines). Attempt 5 was the first estimation script and crashed on a type error (TRUE/FALSE-coded Yellow Vests columns stored as character); fixed and rerun as the final run. The final run's values were compared with the claims via check_attempt ('All claims within tolerance'); the script was not changed afterwards, so no claim attempt is recorded. Table 4: RDD LPM on the 1,968 feedback recipients (757 with \|gain\|<50), quadratic in estimated gain; col 3 adds interactions with initial acceptance, Yellow Vests supporter (part of or supports the movement), and initial not-lose belief plus initial win/lose category controls. Table 6 col 1: 2SLS of targeted-dividend acceptance on believing one does not lose, instrumented by T1, T2, T1xT2 with policy-threshold FE, single-adult indicator and initial acceptance. Table 8 col 1: 2SLS of initial approval on believing the tax effective ('Yes'), instrumented by the effectiveness and climate-change information treatments. No docker run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 27,449 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 907 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 272 bytes, from `benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 584 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 31,867 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,237 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 276 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,424 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 2,331 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 273 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 22 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/attempt-3/stdout.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 2,530 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 9,141 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/attempt-4/stdout.txt`
- [`output/attempt-5/feedback.txt`](output/attempt-5/feedback.txt) — 233 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/attempt-5/feedback.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 6,169 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 147 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/attempt-5/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 3,070 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,247 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 467 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 8,169 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T202751Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
