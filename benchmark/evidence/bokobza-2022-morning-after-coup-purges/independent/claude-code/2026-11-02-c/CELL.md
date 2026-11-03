# bokobza-2022-morning-after-coup-purges · independent · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:03:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T202751Z` |
| Run directory | `benchmark/reproductions/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-c` |
| Executions | 4 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 0/11 |
| First scored | 11/11 (execution 3) |
| Final | **11/11** |
| Package files withheld | 8 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `failed_coup_base_country_fe` | 0.1 (0.03) | 0.098488 | 1.51% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_country_fe` | 0.11 (0.03) | 0.105549 | 4.05% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_base_leader_fe` | 0.08 (0.03) | 0.083868 | 4.83% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_leader_fe` | 0.09 (0.03) | 0.085272 | 5.25% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_experience_model` | 0.14 (0.04) | 0.146839 | 4.88% | ±0.04 (se_band) | PASS | PASS |
| `failed_coup_x_over_6_years_experience` | -0.1 (0.05) | -0.100397 | 0.40% | ±0.05 (se_band) | PASS | PASS |
| `failed_coup_affiliation_model` | 0.17 (0.06) | 0.177012 | 4.12% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_x_leaders_party` | -0.13 (0.06) | -0.12264 | 5.66% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_responsibility_model` | 0.2 (0.07) | 0.2064 | 3.20% | ±0.07 (se_band) | PASS | PASS |
| `failed_coup_x_natural_resources` | -0.18 (0.08) | -0.180527 | 0.29% | ±0.08 (se_band) | PASS | PASS |
| `failed_coup_importance_model` | 0.37 (0.09) | 0.373758 | 1.02% | ±0.09 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Country-level autocracy sample uses democracy1 == 0 (the Boix-Miller-Rosato variable in the country file); this reproduces the reported base-model sample of 3,715 country-years in 115 countries (fixest drops 1 singleton, N = 3,714). A one-year lag of democracy1 gave 3,749 obs in 117 countries.
- (reproduction.json) Leader-FE models (Table A2) take the one-year lags of the controls within each leader spell (leader_cab_id), i.e. the panel is leader x year; this drops each leader's first year (N = 3,282 / 3,261 vs. reported 3,332 / 3,307) and makes lagged monarchy collinear with the leader FE, as the paper reports. Attempt 3 lagged within country (N = 3,591) and gave leader-FE coefficients of 0.059 / 0.062.
- (reproduction.json) Individual-level H2a (experience) model sample: non-leader minister-years in autocracies (democracy_lag == 0) with a non-missing importance tier, including junior ministers; this matches the reported N (90,020) better than excluding juniors (~80k). N = 89,746.
- (reproduction.json) In three of the four individual-level models fixest drops lagged log population as collinear with the country and year fixed effects even with collin.tol = 1e-14; the paper reports a coefficient for it. In the responsibility model, where it is kept, the failed-coup coefficients are unchanged from attempt 3, where it was dropped.

Agent notes: Attempts 1-2 were exploratory runs (variable listings and sample counts, no estimates). Attempt 3 was the first full run; check_attempt reported every claim within tolerance. I changed the script anyway on specification grounds: the leader-FE N (3,591) did not match the reported 3,332, and monarchy did not drop out as the paper says it should. The final run takes the lags within each leader spell for the leader-FE models and lowers the collinearity tolerance for the individual-level models. Country-level models: OLS (fixest) of replacement_rateadj_minister on coupattempt_whogov (already July-recoded in the data) with lagged log GDP per capita and population (plus lagged monarchy, military and party dummies in the Main models), country or leader FE plus year FE, clustered by country. Individual-level models: linear probability models of purged_y1 for non-leader ministers in autocracies, with the failed-coup indicator interacted with experience group, party group, minister type or importance tier; cubic in years in office except in the experience model; lagged log GDP per capita and population; country and year FE, clustered by country. No docker run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 19,609 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T202751Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,023 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T202751Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 276 bytes, from `benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,033 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T202751Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 210 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T202751Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 18,613 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T202751Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,058 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T202751Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 210 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T202751Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 10,042 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T202751Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 29 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T202751Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 4,773 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T202751Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 1,142 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T202751Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 9,956 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T202751Z/attempt-3/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 3,099 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T202751Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,541 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T202751Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,133 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T202751Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 10,162 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T202751Z/stdout.txt`
