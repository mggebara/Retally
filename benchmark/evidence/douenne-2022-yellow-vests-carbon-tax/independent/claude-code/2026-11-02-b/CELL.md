# douenne-2022-yellow-vests-carbon-tax · independent · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T15:01:00Z |
| Results file | `benchmark/results/claude-code-run2-6papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z` |
| Run directory | `benchmark/reproductions/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-02-b` |
| Executions | 6 |
| Refinements | 2 (2 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 6) |
| Final | **13/13** |
| Package files withheld | 39 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.274994 | 2.23% | ±0.058 (se_band) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.271027 | 11.43% | ±0.066 (se_band) | PASS | PASS |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.231362 | 11.23% | ±0.035 (se_band) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.249443 | 1.40% | ±0.064 (se_band) | PASS | PASS |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.019963 | 33.09% | ±0.087 (se_band) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.033183 | 74.65% | ±0.058 (se_band) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.172669 | 4.02% | ±0.079 (se_band) | PASS | PASS |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.172348 | 14.14% | ±0.069 (se_band) | PASS | PASS |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.096302 | 20.38% | ±0.079 (se_band) | PASS | PASS |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.154205 | 0.79% | ±0.045 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±7.57 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.53768 | 0.69% | ±0.132 (se_band) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.419496 | 0.84% | ±0.168 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) The online-appendix list of controls is not available; controls were reconstructed: sociodemographics = sex, age bracket, education (4), town size (5), socio-professional category, region, household size, number aged 14+, number of adults; incomes = continuous piecewise-linear income percentiles of respondent and second adult (kinks at p20, p70; second-adult terms zeroed for singles) plus single dummy; estimated gains = simule_gain and its square; other motives = belief in environmental effectiveness (Tables 4 and 6) or initial win/lose category (Table 8). Progressivity beliefs were not used (asked only to the second half of the sample, collinear with the effectiveness-information instrument).
- (reproduction.json) All regressions weighted by the survey weight; heteroskedasticity-robust SEs (coefficients only are scored).
- (reproduction.json) Table 6 subsample [p10;p60]: respondent's own percentile in [10,60] or (non-single) second adult's percentile in [10,60]; N = 1961 vs 1969 in the paper.
- (reproduction.json) Info on environmental effectiveness (Z_E) taken as apres_modifs (second-half sample that saw the effectiveness information); Z_CC = info_CC.
- (reproduction.json) Table 4 R2 is lower than the paper's (0.267 vs 0.301 in col 1), suggesting the paper's control set is larger.

Agent notes: Data: s from after_preparation.RData (3,002 respondents). memisc-labelled columns stripped of attributes because memisc is not installed (attempts 2 and 4 crashed on this). Table 4: LPM of post-feedback belief (not lose / win) on predicted-winner indicator (simule_gagnant), initial acceptance, quadratic in estimated net gain, controls; \|gain\|<50 subsample gives N=757 exactly. Col 3 adds interactions with initial acceptance, Yellow Vests supporter (gilets_jaunes >= 1, i.e. part of or supports) and initial not-lose belief, plus initial win/lose category factor. Table 6 col 1: 2SLS of targeted-dividend acceptance on believing not losing, instrumented by T1, T2, T1xT2, with threshold FE, initial acceptance, income piecewise, single. Table 8 col 1: 2SLS of initial approval on believing effective ('Yes'), instrumented by Z_E and Z_CC, all 3,002. After the first estimation run I ran check_attempt once: all claims within tolerance, so the script was not changed and that run is the final one (no claim attempt). No author scripts were opened; functions stored inside the RData were not inspected.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 26,972 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 907 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 272 bytes, from `benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-02-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 455 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 38,623 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 276 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,308 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 276 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 720 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 985 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 778 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/attempt-3/stdout.txt`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 282 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 2,848 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 282 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/attempt-4/stdout.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 2,863 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 21,503 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/attempt-5/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 3,079 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,130 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 456 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,948 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/claude-code/20261102T151024Z/stdout.txt`
