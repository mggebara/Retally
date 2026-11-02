# adams-2023-women-mps-affective-polarization · independent · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:01:30Z |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z` |
| Run directory | `benchmark/reproductions/adams-2023-women-mps-affective-polarization/independent/2026-11-02-c` |
| Executions | 5 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 0/11 |
| First scored | 7/11 (execution 2) |
| Final | **11/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `women_mps_coef_bivariate` | 1.89 (0.43) | 1.8873 | 0.14% | ±0.43 (se_band) | PASS | PASS |
| `women_mps_coef_full` | 1.73 (0.52) | 1.7583 | 1.64% | ±0.52 (se_band) | PASS | PASS |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 2.1314 | 1.50% | ±0.53 (se_band) | PASS | PASS |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.1654 | 3.13% | ±0.5 (se_band) | PASS | PASS |
| `right_left_distance_coef_full` | -0.6 (0.09) | -0.5967 | 0.55% | ±0.09 (se_band) | PASS | PASS |
| `coalition_partners_coef_full` | 0.94 (0.25) | 0.9517 | 1.24% | ±0.25 (se_band) | PASS | PASS |
| `opposition_partners_coef_full` | 0.37 (0.11) | 0.3339 | 9.76% | ±0.11 (se_band) | PASS | PASS |
| `n_directed_dyads` | 1842 | 1842 | 0.00% | ±18.42 (relative) | PASS | FAIL |
| `n_obs_women_partisans` | 1836 | 1836 | 0.00% | ±18.36 (relative) | PASS | FAIL |
| `n_obs_men_partisans` | 1833 | 1833 | 0.00% | ±18.33 (relative) | PASS | FAIL |
| `n_election_studies` | 81 | 81 | 0.00% | ±0.81 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Sample restriction 'at least four MPs each' is implemented as to_prior_seats >= 4 (the evaluated out-party j only, with the 999 seat code retained), because requiring >= 4 prior seats of both parties gave 1,525 dyads against the paper's 1,842; the out-party-only filter reproduces 1,842 / 1,836 / 1,833 exactly. Chosen after the claim comparison of attempt-2.
- (reproduction.json) Gender models use 10 - dislike from the gender-disaggregated file as the 0-10 like thermometer (gender 2 = women, 1 = men).

Agent notes: Data: dyadic_data_1-4-22.Rdata (updated_data) for columns 1-2, gender_disagregated_8-8-21.rds for columns 3-4. OLS with fixest::feols, DV = party_like (mean 0-10 thermometer of i's partisans toward j), regressor to_pfeml (out-party proportion women MPs, t-1), controls rile_distance_s, govern_together, opposition_together; country-year (election) fixed effects; SEs clustered by election. attempt-1: variable inspection. attempt-2: first full estimate with both-party seat filter (dropping 999 codes); compared with claims via check_attempt, Ns were off. attempts 3-4: exploratory sample counts under alternative seat filters. Final run: out-party seat filter; all Ns match and coefficients are within about 0.03 of the claims (1.89, 1.76, 2.13, 1.17, -0.60, 0.95, 0.33). No runs hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,494 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,143 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 285 bytes, from `benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/independent/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 880 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 6,310 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 282 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,552 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 248 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,234 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 1,309 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 740 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/attempt-3/stdout.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 1,664 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 4,929 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/attempt-4/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,958 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,582 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 264 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,234 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T202751Z/stdout.txt`
