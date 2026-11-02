# adams-2023-women-mps-affective-polarization · seeded · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T19:36:00Z |
| Results file | `benchmark/results/claude-code-run2-23papers-seeded-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/seeded/claude-code/20261102T194315Z` |
| Run directory | `benchmark/reproductions/adams-2023-women-mps-affective-polarization/seeded/2026-11-02-b` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 11/11 |
| First scored | 11/11 (execution 1) |
| Final | **11/11** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `women_mps_coef_bivariate` | 1.89 (0.43) | 1.88727 | 0.14% | ±0.0378 (relative) | PASS | PASS |
| `women_mps_coef_full` | 1.73 (0.52) | 1.72562 | 0.25% | ±0.0346 (relative) | PASS | PASS |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 2.0967 | 0.16% | ±0.042 (relative) | PASS | PASS |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.13099 | 0.09% | ±0.0226 (relative) | PASS | PASS |
| `right_left_distance_coef_full` | -0.6 (0.09) | -0.596057 | 0.66% | ±0.012 (relative) | PASS | PASS |
| `coalition_partners_coef_full` | 0.94 (0.25) | 0.943065 | 0.33% | ±0.0188 (relative) | PASS | PASS |
| `opposition_partners_coef_full` | 0.37 (0.11) | 0.370655 | 0.18% | ±0.0074 (relative) | PASS | PASS |
| `n_directed_dyads` | 1842 | 1842 | 0.00% | ±18.42 (relative) | PASS | PASS |
| `n_obs_women_partisans` | 1836 | 1836 | 0.00% | ±18.36 (relative) | PASS | PASS |
| `n_obs_men_partisans` | 1833 | 1833 | 0.00% | ±18.33 (relative) | PASS | PASS |
| `n_election_studies` | 81 | 81 | 0.00% | ±0.81 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) lm(... + as.factor(cntryyr)) translated to fixest::feols with cntryyr absorbed as a fixed effect (identical point estimates). SEs clustered by country as in replication_code.R's starprep(clusters = country); the paper text says election-clustered, so the election-clustered summary is also printed (coefficients unaffected).

Agent notes: Single run following replication_code.R Table 1 sections: dyadic_data_1-4-22.Rdata with to_prior_seats >= 4 and na.omit over the script's variable list for columns 1-2; gender_disagregated_8-8-21.rds with like = 10 - dislike, gender==2 (women) and gender==1 (men) for columns 3-4; country-year FE. n_election_studies = distinct country-years in the column 1-2 estimation sample. All 11 values match the claims after rounding; no script changes after comparison.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 48,813 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/seeded/claude-code/20261102T194315Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,002 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/seeded/claude-code/20261102T194315Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 280 bytes, from `benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/seeded/2026-11-02-b/paper.txt`

## What it produced

- [`output/reproduction.json`](output/reproduction.json) — 1,239 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/seeded/claude-code/20261102T194315Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,863 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/seeded/claude-code/20261102T194315Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/seeded/claude-code/20261102T194315Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,077 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/seeded/claude-code/20261102T194315Z/stdout.txt`
