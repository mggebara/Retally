# bokobza-2022-morning-after-coup-purges · blind · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T19:18:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z` |
| Run directory | `benchmark/reproductions/bokobza-2022-morning-after-coup-purges/blind/2026-11-07-a` |
| Executions | 7 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 11/11 (execution 5) |
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
| `failed_coup_experience_model` | 0.14 (0.04) | 0.131264 | 6.24% | ±0.04 (se_band) | PASS | PASS |
| `failed_coup_x_over_6_years_experience` | -0.1 (0.05) | -0.082577 | 17.42% | ±0.05 (se_band) | PASS | PASS |
| `failed_coup_affiliation_model` | 0.17 (0.06) | 0.168998 | 0.59% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_x_leaders_party` | -0.13 (0.06) | -0.114866 | 11.64% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_responsibility_model` | 0.2 (0.07) | 0.203535 | 1.77% | ±0.07 (se_band) | PASS | PASS |
| `failed_coup_x_natural_resources` | -0.18 (0.08) | -0.183473 | 1.93% | ±0.08 (se_band) | PASS | PASS |
| `failed_coup_importance_model` | 0.37 (0.09) | 0.372632 | 0.71% | ±0.09 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Individual-level models: the shipped column pop_pwt_ln_lag is an exact copy of gdp_cap_pwt_ln_lag (within-R2 = 1, so fixest dropped it as collinear in attempt-5). Lagged log population was rebuilt from pop_pwt_ln as the previous calendar year's value within country (missing if the prior year is absent).
- (reproduction.json) Country-level autocracy filter: lagged Boix-Miller-Rosato democracy (democracy1, lagged one year within country) == 0, years 1967-2016, following the paper's text; the dataset's ldemocracy_br is labelled Bjornskov-Rode and was not used. This gives 115 clusters in the base model; the paper says 115 autocracies.
- (reproduction.json) Main model with leader FE: lagged monarchy is not collinear with leader FE in this data, so it stays in the model, not dropped as Table A2 describes.
- (reproduction.json) Individual-level sample: lagged democracy (the dataset's democracy_lag) == 0, 1967-2016, leader excluded, importance tier non-missing. Juniors/low-ranking posts excluded only in the experience model. 'No party affiliation' = party_group 'independent'; 'unknown' party dropped from the affiliation model. Responsibility model uses rows with a minister_type. The importance model excludes the 6 'Governor (General)' (tier 0) rows.

Agent notes: Independent blind reproduction in R/fixest. Country level: OLS of replacement_rateadj_minister on coupattempt_whogov (already July-recoded in the data) plus one-year-lagged log GDP per capita and log population (Base), and also lagged monarchy/military/party dummies (Main); country+year or leader(leader_cab_id)+year FE; SEs clustered by country. Individual level: LPM of purged_y1 on coupattempt_presentyear interacted with experience group / party group / minister type / importance tier, with lagged GDP and population and (except the experience model) a cubic in years in cabinet; country+year FE, country-clustered SEs. Attempts 1-4 and 6 were exploratory (no RESULT lines). Attempt 5 was the first full estimation; it printed RESULT lines but the population control was dropped because of the data bug described in deviations. The final run fixes that. No claimed values were seen or compared. No docker run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 20,469 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 992 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 289 bytes, from `benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,156 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 29,109 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 259 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,068 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 8,722 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 259 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 1,867 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 968 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 259 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-3/timing.json`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 1,162 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 670 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 259 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-4/timing.json`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 4,857 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 1,200 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 9,103 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-5/stdout.txt`
- [`output/attempt-5/timing.json`](output/attempt-5/timing.json) — 259 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-5/timing.json`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 1,292 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 83 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 4,749 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-6/stdout.txt`
- [`output/attempt-6/timing.json`](output/attempt-6/timing.json) — 259 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/attempt-6/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,910 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,433 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 840 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 9,253 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 259 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261107T194811Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
