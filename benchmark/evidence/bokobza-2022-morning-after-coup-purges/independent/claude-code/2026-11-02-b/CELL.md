# bokobza-2022-morning-after-coup-purges · independent · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T07:06:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-4papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z` |
| Run directory | `benchmark/reproductions/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-b` |
| Executions | 5 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 0/11 |
| First scored | 11/11 (execution 3) |
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
| `failed_coup_experience_model` | 0.14 (0.04) | 0.144128 | 2.95% | ±0.04 (se_band) | PASS | PASS |
| `failed_coup_x_over_6_years_experience` | -0.1 (0.05) | -0.10138 | 1.38% | ±0.05 (se_band) | PASS | PASS |
| `failed_coup_affiliation_model` | 0.17 (0.06) | 0.175036 | 2.96% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_x_leaders_party` | -0.13 (0.06) | -0.123832 | 4.74% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_responsibility_model` | 0.2 (0.07) | 0.204123 | 2.06% | ±0.07 (se_band) | PASS | PASS |
| `failed_coup_x_natural_resources` | -0.18 (0.08) | -0.182342 | 1.30% | ±0.08 (se_band) | PASS | PASS |
| `failed_coup_importance_model` | 0.37 (0.09) | 0.372632 | 0.71% | ±0.09 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Country level: sample = country-years 1967-2016 with one-year-lagged Boix-Miller-Rosato democracy (democracy1) == 0; lags built within country only for consecutive years. N = 3,743 (country FE base) vs 3,715 reported; fixest keeps FE singletons, which Stata reghdfe drops (this explains most of the leader-FE N gap, 3,626 vs 3,332, but does not change point estimates).
- (reproduction.json) Failed coup indicator taken as coupattempt_whogov (country level) and coupattempt_presentyear == 'Coup attempt' (individual level), assumed to already carry the July recoding.
- (reproduction.json) Leader FE uses leader_cab_id; lagged monarchy is not fully collinear with leader FE in this construction and is kept (paper says it drops).
- (reproduction.json) Individual level: the shipped pop_pwt_ln_lag column is identical to gdp_cap_pwt_ln_lag (correlation 1), so lagged log population was rebuilt by shifting the current-year pop_pwt_ln (and gdp_cap_pwt_ln) by one year within country.
- (reproduction.json) Individual samples: autocracies (democracy_lag == 0), 1967-2016, leader excluded. Experience model drops rows with missing rank tier (importance_numeric NA), which matches the reported N (90,020) better than dropping the 'junior minister' tier; no cubic experience terms. Affiliation model drops unknown/missing party. Responsibility model uses minister_type (ref. Defense). Importance model uses tiers 0.5/1/2/3 vs ref. 4 (PM/President not leader), dropping the 6 rows coded 0.

Agent notes: Two exploratory runs (attempts 1-2, no RESULT lines) inspected variables and sample sizes. Attempt 3 was the first full estimate; check_attempt reported all claims within tolerance, but fixest dropped lagged population as collinear. Attempt 4 tried a tighter collinearity tolerance (no effect; recorded as a claim attempt to be conservative since claims had been compared). Diagnosing it showed that the shipped pop lag duplicates the GDP lag; the final run rebuilds both lags from the current-year columns. Final estimates: country FE 0.103 / 0.112; leader FE 0.062 / 0.064 (claimed 0.08 / 0.09, still the weakest match); individual-level coefficients 0.144, -0.101, 0.175, -0.124, 0.204, -0.182, 0.373. No script files from the dataset were opened (none were present in the mount).

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 19,132 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,023 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 276 bytes, from `benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,102 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 15,745 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,314 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 5,733 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 29 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 4,931 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 1,168 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 8,052 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/attempt-3/stdout.txt`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 29 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 5,382 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 1,088 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 8,220 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/attempt-4/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,887 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,913 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 848 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 8,321 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/claude-code/20261102T090910Z/stdout.txt`
