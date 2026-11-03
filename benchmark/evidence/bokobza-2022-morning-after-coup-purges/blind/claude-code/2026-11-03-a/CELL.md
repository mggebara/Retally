# bokobza-2022-morning-after-coup-purges · blind · claude-code · 2026-11-03-a

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-03-a |
| Date | 2026-11-03T00:16:00Z |
| Results file | `benchmark/results/claude-code-run4-redaction-3papers-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z` |
| Run directory | `benchmark/reproductions/bokobza-2022-morning-after-coup-purges/blind/2026-11-03-a` |
| Executions | 6 |
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
| `failed_coup_main_leader_fe` | 0.09 (0.03) | 0.063937 | 28.96% | ±0.03 (se_band) | PASS | PASS |
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

- (reproduction.json) Individual-level data: the supplied pop_pwt_ln_lag column is identical to gdp_cap_pwt_ln_lag, so lagged log GDP per capita and lagged log population were rebuilt from the country-year panel (value in the previous calendar year, missing if that year is absent).
- (reproduction.json) Country-level: lagged controls and the lagged BMR democracy filter (democracy1 at t-1 == 0) were built from the panel (previous calendar year only); years 1967-2016; failed coup = coupattempt_whogov (already July-recoded in the data).
- (reproduction.json) Leader-FE Main Model (Table A2): the lagged monarchy dummy is excluded explicitly, as in the paper, because in this data it varies within 5 leader spells and would otherwise not drop out. attempt-5 is the same script with monarchy kept (coefficient 0.0638 vs 0.0639).
- (reproduction.json) Affiliation model drops rows whose party_group is 'unknown' or missing (only the three categories named in the paper are used). Experience model drops junior ministers / other low-ranking posts (importance_numeric 0.5); other models keep them. Importance model drops importance code 0 and missing.
- (reproduction.json) fixest drops fixed-effect singletons (as reghdfe would); leader FE = leader_cab_id; country FE/cluster = COUNTRY_ID (country level) and country_isocode (individual level).

Agent notes: Attempts 1-4 were exploratory (variable inspection, sample counts; attempt-3 crashed on a table subscript in exploratory code and was rerun as attempt-4); none printed RESULT lines. attempt-5 was the first full estimation run; the final run differs only by excluding monarchy from the leader-FE Main Model. Individual sample: minister-years in autocracies (democracy_lag == 0), 1967-2016, leader excluded, outcome purged_y1, failed coup = coupattempt_presentyear (never coincides with a successful coup in the data), country and year FE, country-clustered SEs; 115 countries. Note that 2016 has purged_y1 mean ~0.91 in the data (next-year cabinet data largely missing); kept because the paper's sample runs to 2016. No paper values were consulted; no image, log or script files in the dataset directory were opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 20,194 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 992 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 289 bytes, from `benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-03-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,004 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 27,008 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,635 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,222 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 1,917 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 160 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 140 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/attempt-3/stdout.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 1,901 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 2,829 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/attempt-4/stdout.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 5,361 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 840 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 9,864 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/attempt-5/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,796 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,721 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 840 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 9,929 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/claude-code/20261103T001658Z/stdout.txt`
