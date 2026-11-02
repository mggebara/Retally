# bokobza-2022-morning-after-coup-purges · blind · claude-code · 2026-11-02-a

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-a |
| Date | 2026-11-02T06:01:00Z |
| Results file | `benchmark/results/claude-code-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z` |
| Run directory | `benchmark/reproductions/bokobza-2022-morning-after-coup-purges/blind/2026-11-02-a` |
| Executions | 5 |
| Refinements | 0 (0 error + 0 claim) |
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
| `failed_coup_base_leader_fe` | 0.08 (0.03) | 0.081164 | 1.45% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_leader_fe` | 0.09 (0.03) | 0.083025 | 7.75% | ±0.03 (se_band) | PASS | PASS |
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

- (reproduction.json) Individual-level data: the shipped pop_pwt_ln_lag column is an exact copy of gdp_cap_pwt_ln_lag (so fixest dropped it as collinear in attempt-3); the final script rebuilds lagged logged population from pop_pwt_ln (previous calendar year, within country).
- (reproduction.json) Leader-FE country-level models (Table A2): lagged controls are taken within the leader spell (as with Stata L. after xtset on the leader id), so each leader's first year has no lagged controls. Chosen because the paper/task state that lagged monarchy is collinear with leader FE, which holds only under within-leader lags (with within-country lags it varies in 5 leader spells right after a monarchy ended). Country-FE models use within-country lags.
- (reproduction.json) Autocracy filter at country level: lag of BMR democracy1 built within country (consecutive years), sample 1967-2016; the failed-coup variable coupattempt_whogov is taken as already July-aligned. Individual level uses democracy_lag == 0 and coupattempt_presentyear.
- (reproduction.json) Experience model (H2a): excludes the leader and importance tier 0.5 (junior minister or other low-ranking post); rows with missing importance are kept; no experience polynomials (paper footnote 15). Importance model drops the 6 rows with importance code 0 (Governor General) not in the paper's tier list.
- (DEVIATION: line) individual-level pop_pwt_ln_lag equals gdp_cap_pwt_ln_lag in the data; rebuilt from pop_pwt_ln lagged one year within country

Agent notes: Blind independent reproduction in R/fixest. Country level: OLS of replacement_rateadj_minister on coupattempt_whogov, lagged log GDP pc and log population (+ lagged monarchy, military, party dummies in Main), country or leader FE plus year FE, SEs clustered by country. Individual level: LPM of purged_y1 on failed-coup indicator x minister-characteristic dummies (experience group; party group with unknown/NA dropped; minister_type; importance tier), cubic in years in office (except experience model), lagged log GDP pc and population, country and year FE, SEs clustered by country; leader excluded; 1967-2016 autocracies. Attempts 1, 2 and 4 were exploratory (no RESULT lines). Attempt 3 was the first estimation run; after data diagnostics in attempt 4 (not any comparison with paper values, which were never seen) the final run fixed the population lag and the leader-FE lag structure. Image files (jpg) in the data directory were not opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 19,717 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 992 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 276 bytes, from `benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-02-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,296 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 28,565 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,932 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 11,285 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 5,262 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 928 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 7,267 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/attempt-3/stdout.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 1,952 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 6,296 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/attempt-4/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,910 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,947 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 646 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,995 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T062002Z/stdout.txt`
