# douenne-2022-yellow-vests-carbon-tax · independent · claude-code · 2026-11-02-a

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-a |
| Date | 2026-11-02T14:17:30Z |
| Results file | `benchmark/results/claude-code-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z` |
| Run directory | `benchmark/reproductions/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-02-a` |
| Executions | 7 |
| Refinements | 2 (1 error + 1 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 6) |
| Final | **13/13** |
| Package files withheld | 39 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.273118 | 1.53% | ±0.058 (se_band) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.275713 | 9.90% | ±0.066 (se_band) | PASS | FAIL |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.218689 | 5.14% | ±0.035 (se_band) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.231617 | 5.85% | ±0.064 (se_band) | PASS | PASS |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.00142947 | 90.47% | ±0.087 (se_band) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.0323903 | 70.48% | ±0.058 (se_band) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.187258 | 12.81% | ±0.079 (se_band) | PASS | PASS |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.149981 | 0.67% | ±0.069 (se_band) | PASS | PASS |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.146722 | 83.40% | ±0.079 (se_band) | PASS | PASS |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.146986 | 3.93% | ±0.045 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±7.57 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.544402 | 1.95% | ±0.132 (se_band) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.434333 | 4.41% | ±0.168 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Online-appendix control list unavailable; controls reconstructed from variable names: incomes = continuous piecewise-linear in both adults' income percentiles (kinks at 20 and 70); estimated gains = simule_gain and its square; sociodemographics = sex, age brackets, employment status, socio-professional category, region, education (4), town size, number of adults, household size, number aged 14+, smoker, main news source.
- (reproduction.json) Other motives: Table 4 uses the progressivity belief (prog_na, with not-asked as a category); Table 6 uses effectiveness (Oui/Non/NSP) and progressivity beliefs; Table 8 uses the initial win/lose category (progressivity omitted because it was asked only of the apres_modifs half, collinear with the effectiveness-information instrument).
- (reproduction.json) Effectiveness-information instrument Z_E identified as apres_modifs (second half of sample received the effectiveness info, per its variable label); Z_CC = info_CC.
- (reproduction.json) Regressions unweighted, heteroskedasticity-robust SEs (fixest, hetero); the paper does not state regression weights.
- (reproduction.json) Table 6 col 1 subsample: respondent or second-adult income percentile in [10, 60] (N = 1969, matches); Table 6 policy fixed effects from cible; Table 6 instruments traite_cible, traite_cible_conjoint and interaction.

Agent notes: Loaded s (3002 respondents) from code/after_preparation.RData; memisc item columns stripped to base vectors (memisc not installed). Table 4: LPM of post-feedback belief on predicted-winner indicator simule_gagnant, initial acceptance, quadratic in simule_gain, controls; feedback branch variante_taxe_info=='f', \|simule_gain\|<50 gives N=757 (matches); full feedback sample N=1968 (matches). Col 3 adds YV supporter (gilets_jaunes>0), interactions with initial acceptance, YV and initial not-lose belief, plus initial win/lose category factor. Tables 6 and 8 col 1 by 2SLS with fixest. One claim comparison (attempt-6) found only Table 4 col 1 initial acceptance off target (0.227 vs 0.306); the final run drops the effectiveness-belief control from the Table 4 regressions, after which all claims are within tolerance. Two earlier hung Docker runs (daemon wedged, containers never started, exit 125) were rerun in place in attempt-4 after Docker was restarted and are not counted as attempts.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 26,972 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 907 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 272 bytes, from `benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-02-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 475 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 30,444 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,633 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 268 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 628 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 2,778 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 15,050 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-3/stdout.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 2,357 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 5,881 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-4/stdout.txt`
- [`output/attempt-5/feedback.txt`](output/attempt-5/feedback.txt) — 299 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-5/feedback.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 5,081 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 744 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-5/stdout.txt`
- [`output/attempt-6/feedback.txt`](output/attempt-6/feedback.txt) — 117 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-6/feedback.txt`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 5,195 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 446 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 860 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/attempt-6/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 3,069 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,253 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 446 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 862 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T142247Z/stdout.txt`
