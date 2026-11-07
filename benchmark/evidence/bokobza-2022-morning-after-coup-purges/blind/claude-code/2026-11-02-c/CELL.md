# bokobza-2022-morning-after-coup-purges · blind · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:18:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z` |
| Run directory | `benchmark/reproductions/bokobza-2022-morning-after-coup-purges/blind/2026-11-02-c` |
| Executions | 8 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 11/11 (execution 6) |
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

- (reproduction.json) Individual-level data: the supplied pop_pwt_ln_lag column is an exact copy of gdp_cap_pwt_ln_lag (correlation 1), so population dropped out as collinear in attempt-6. The final script rebuilds the one-year lag of logged population from the country-year pop_pwt_ln series (consecutive years within country); the rebuilt GDP lag matches the supplied one to 4e-7.
- (reproduction.json) H2a experience model sample: footnote 16 says junior ministers / other low-ranking posts are excluded, but the reported N (90,020) is only matched by keeping junior ministers and dropping minister-years without an importance tier (my N 89,637; excluding juniors would give 85,711). I used non-leader minister-years with a non-missing importance tier, i.e. the N-consistent sample.
- (reproduction.json) Leader-FE country models: controls lagged within leader spells (Stata-style L. with leader as panel), which drops each leader's first year; this reproduces the reported N pattern (3,361 before singleton removal vs 3,332 reported; country-FE 3,745 vs 3,715 reported, the same ~30-observation gap).
- (reproduction.json) The country-level failed-coup variable coupattempt_whogov was taken as already recoded to the July-to-July WhoGov window (it lines up with the individual-level coupattempt_presentyear shifted one year, regardless of coup month); no further recoding applied. Individual level uses coupattempt_presentyear (Powell & Thyne); the _br variables (Bjørnskov-Rode) were not used.
- (reproduction.json) fixest removes fixed-effect singletons (2 countries in country-FE, ~84 leaders in leader-FE models); this does not change point estimates.
- (reproduction.json) Country-level sample: lagged Boix-Miller-Rosato democracy1 == 0 (lag within country), years 1967-2016. Individual-level sample: democracy_lag == 0, 1967-2016, leader == 0; affiliation drops 'unknown' party; responsibility uses minister_type (ref Defense); importance uses tiers 0.5-4 (ref 4 = PM/President not the leader). Individual samples are ~350-380 obs smaller than reported in every column, cause not identified.

Agent notes: Five exploratory runs (attempt-1..5, no RESULT lines) inspected variables and sample sizes. attempt-6 was the first full estimation; inspecting its output showed log population dropped as collinear in all individual-level models, traced in exploratory attempt-7 to pop_pwt_ln_lag being a duplicate of the GDP lag; the final run rebuilds the population lag. No comparison with paper values was made (blind). All models are OLS/LPM via fixest with country (or leader) and year fixed effects and country-clustered SEs.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 20,194 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 992 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 276 bytes, from `benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,047 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 19,596 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,413 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 7,608 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 3,055 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 2,155 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-3/stdout.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 2,889 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 1,303 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-4/stdout.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 1,191 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 555 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-5/stdout.txt`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 5,353 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 1,285 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 6,464 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-6/stdout.txt`
- [`output/attempt-7/script.R`](output/attempt-7/script.R) — 995 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-7/script.R`
- [`output/attempt-7/stderr.txt`](output/attempt-7/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-7/stderr.txt`
- [`output/attempt-7/stdout.txt`](output/attempt-7/stdout.txt) — 2,975 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/attempt-7/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 3,348 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,523 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 925 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 6,878 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261102T202753Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
