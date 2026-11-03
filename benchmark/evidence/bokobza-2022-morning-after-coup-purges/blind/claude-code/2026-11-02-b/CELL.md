# bokobza-2022-morning-after-coup-purges · blind · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T07:07:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-4papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z` |
| Run directory | `benchmark/reproductions/bokobza-2022-morning-after-coup-purges/blind/2026-11-02-b` |
| Executions | 6 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 11/11 (execution 4) |
| Final | **11/11** |
| Package files withheld | 8 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `failed_coup_base_country_fe` | 0.1 (0.03) | 0.102553 | 2.55% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_country_fe` | 0.11 (0.03) | 0.111954 | 1.78% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_base_leader_fe` | 0.08 (0.03) | 0.061535 | 23.08% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_leader_fe` | 0.09 (0.03) | 0.063813 | 29.10% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_experience_model` | 0.14 (0.04) | 0.133582 | 4.58% | ±0.04 (se_band) | PASS | PASS |
| `failed_coup_x_over_6_years_experience` | -0.1 (0.05) | -0.072555 | 27.45% | ±0.05 (se_band) | PASS | PASS |
| `failed_coup_affiliation_model` | 0.17 (0.06) | 0.175036 | 2.96% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_x_leaders_party` | -0.13 (0.06) | -0.123832 | 4.74% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_responsibility_model` | 0.2 (0.07) | 0.204123 | 2.06% | ±0.07 (se_band) | PASS | PASS |
| `failed_coup_x_natural_resources` | -0.18 (0.08) | -0.182342 | 1.30% | ±0.08 (se_band) | PASS | PASS |
| `failed_coup_importance_model` | 0.37 (0.09) | 0.372632 | 0.71% | ±0.09 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Individual-level models: the provided pop_pwt_ln_lag column is an exact copy of gdp_cap_pwt_ln_lag (verified in the final script), so it was collinear and dropped in attempt-4. The final script rebuilds lagged ln population as the year-1 value of pop_pwt_ln within country from the same file, as the paper's method specifies. This was found from a data diagnostic (attempt-5), not by comparing with any reported value.
- (reproduction.json) Affiliation model: party_group 'independent' is treated as 'no party affiliation'; 'unknown' and missing party_group are excluded (reference: other_party).
- (reproduction.json) Experience model excludes the leader and importance tier 0.5 (junior minister or other low-ranking post); rows with missing importance are kept. Importance model keeps tiers 4 (reference), 3, 2, 1, 0.5 and drops tier 0 and missing values. Responsibility model drops rows with missing minister_type.
- (reproduction.json) Country level: autocracy = lagged Boix-Miller-Rosato democracy1 == 0 (lag built by country and year-1 match), years 1967-2016; controls lagged one year the same way. In the leader-FE Main model the lagged monarchy dummy is not fully collinear with leader FE under this lag construction, so it stays in the model (the paper says it drops).
- (DEVIATION: line) individual-level lagged ln population rebuilt from pop_pwt_ln (provided pop_pwt_ln_lag duplicates GDP lag)

Agent notes: Independent blind reproduction from the paper text only; no author scripts, logs, .tex or images were opened. Country level (Tables A1/A2): fixest OLS of replacement_rateadj_minister on coupattempt_whogov (failed coup attempt already recoded July-to-July in the data), with lagged ln GDP/cap and ln pop (Base), plus lagged monarchy/military/party dummies (Main), and country or leader (leader_cab_id) FE plus year FE; SEs clustered by country. N: 3743/3703 (country FE), 3626/3590 (leader FE). Individual level (Tables K1/K2): LPM of purged_y1 on the failed coup indicator (coupattempt_presentyear), category dummies and their interactions with it, lagged ln GDP/cap and ln pop, and a cubic in experience (not in the experience model); country and year FE; SEs clustered by country. Sample: lagged BMR democracy == 0, 1967-2016, leader excluded, giving 95,344 minister-years before the model-specific restrictions. attempt-1, attempt-2 and attempt-5 were exploratory (no RESULT lines). attempt-3 crashed because update() does not handle fixest's \| syntax. attempt-4 printed RESULTs, but stderr showed the population lag dropped as collinear; that led to the attempt-5 diagnostic and the data fix in the final run. The fix changes only the individual-level coefficients, and only slightly.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 19,717 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 992 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 276 bytes, from `benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-02-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,605 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 28,161 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,592 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 7,809 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 391 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 6,525 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 220 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/attempt-3/stdout.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 6,744 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 928 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 6,044 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/attempt-4/stdout.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 1,390 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 3,862 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/attempt-5/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 3,246 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/reproduction.json`
- [`output/script.R`](output/script.R) — 7,568 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 568 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 6,472 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T090911Z/stdout.txt`
