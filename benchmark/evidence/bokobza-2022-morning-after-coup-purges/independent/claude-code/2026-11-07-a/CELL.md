# bokobza-2022-morning-after-coup-purges · independent · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T19:15:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z` |
| Run directory | `benchmark/reproductions/bokobza-2022-morning-after-coup-purges/independent/2026-11-07-a` |
| Executions | 5 |
| Refinements | 1 (0 error + 1 claim) |
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
| `failed_coup_base_leader_fe` | 0.08 (0.03) | 0.081164 | 1.45% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_leader_fe` | 0.09 (0.03) | 0.083025 | 7.75% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_experience_model` | 0.14 (0.04) | 0.146604 | 4.72% | ±0.04 (se_band) | PASS | PASS |
| `failed_coup_x_over_6_years_experience` | -0.1 (0.05) | -0.100179 | 0.18% | ±0.05 (se_band) | PASS | PASS |
| `failed_coup_affiliation_model` | 0.17 (0.06) | 0.175977 | 3.52% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_x_leaders_party` | -0.13 (0.06) | -0.121527 | 6.52% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_responsibility_model` | 0.2 (0.07) | 0.206058 | 3.03% | ±0.07 (se_band) | PASS | PASS |
| `failed_coup_x_natural_resources` | -0.18 (0.08) | -0.180449 | 0.25% | ±0.08 (se_band) | PASS | PASS |
| `failed_coup_importance_model` | 0.37 (0.09) | 0.374061 | 1.10% | ±0.09 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Country level: coupattempt_whogov used as delivered (taken to be the July-aligned WhoGov coup indicator); autocracy filter = one-year lag of democracy1 (BMR) == 0, years 1967-2016; country-FE sample N=3743 (paper 3,715), 93 failed coups (paper 95).
- (reproduction.json) Leader-FE models (Table A2): one-year lags of democracy and controls taken within each leader spell (leader_cab_id), as if the panel were set on the leader id, so each spell's first year drops; N=3277 (paper 3,332). With country-panel lags (attempt-4) N was 3626 and the coefficients 0.062/0.064. Monarchy is (near-)collinear with leader FE, as the paper notes.
- (reproduction.json) Individual level: experience model (H2a) does not drop junior ministers despite footnote 16; the sample is minister-years with non-missing importance tier, which reproduces the paper's coup-year count (1,926). Importance model drops the 6 tier-0 rows (coup-year count 1,925 as in the paper). Affiliation model drops party_group unknown/NA. N are ~380 below the paper's in each individual model.
- (reproduction.json) Individual models: fixest drops pop_pwt_ln_lag (as supplied in the .rds) as collinear with country+year FE, even with collin.tol=1e-14; the paper reports a population coefficient. Lagged population was not reconstructed.

Agent notes: Independent reconstruction from the paper text with fixest: OLS of replacement_rateadj_minister on failed coup indicator + lagged log GDPpc and population (+ lagged monarchy/military/party dummies in Main), country or leader FE plus year FE, country-clustered SEs, singletons dropped. Individual LPMs of purged_y1 with fca x characteristic interactions, lagged GDPpc/pop, cubic in experience (not in the experience model), country+year FE, clustered by country; non-leader minister-years with lagged BMR democracy == 0, 1967-2016. Attempts 1-3 were exploratory (variable inspection and sample counts). Attempt 4 was the first estimating run; check_attempt reported all claims within tolerance, but the leader-FE sample size was well above the paper's, so the final run changes how lags are taken for the leader-FE models (and sets a tighter collinearity tolerance, which had no effect). No authors' scripts were opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 19,884 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,023 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 276 bytes, from `benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 822 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 21,774 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 265 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,067 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 10,488 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 265 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 3,286 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 1,878 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 265 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/attempt-3/timing.json`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 286 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 5,034 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 892 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 6,212 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 265 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/attempt-4/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,843 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,998 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 888 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 6,236 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 265 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261107T194812Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
