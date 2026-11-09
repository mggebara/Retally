# adams-2023-women-mps-affective-polarization · independent · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T17:25:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z` |
| Run directory | `benchmark/reproductions/adams-2023-women-mps-affective-polarization/independent/2026-11-07-a` |
| Executions | 4 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 11/11 (execution 4) |
| Final | **11/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `women_mps_coef_bivariate` | 1.89 (0.43) | 1.88727 | 0.14% | ±0.43 (se_band) | PASS | PASS |
| `women_mps_coef_full` | 1.73 (0.52) | 1.72562 | 0.25% | ±0.52 (se_band) | PASS | PASS |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 2.0967 | 0.16% | ±0.53 (se_band) | PASS | PASS |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.13099 | 0.09% | ±0.5 (se_band) | PASS | PASS |
| `right_left_distance_coef_full` | -0.6 (0.09) | -0.596057 | 0.66% | ±0.09 (se_band) | PASS | PASS |
| `coalition_partners_coef_full` | 0.94 (0.25) | 0.943065 | 0.33% | ±0.25 (se_band) | PASS | PASS |
| `opposition_partners_coef_full` | 0.37 (0.11) | 0.370655 | 0.18% | ±0.11 (se_band) | PASS | PASS |
| `n_directed_dyads` | 1842 | 1842 | 0.00% | ±92.1 (relative) | PASS | PASS |
| `n_obs_women_partisans` | 1836 | 1836 | 0.00% | ±91.8 (relative) | PASS | PASS |
| `n_obs_men_partisans` | 1833 | 1833 | 0.00% | ±91.65 (relative) | PASS | PASS |
| `n_election_studies` | 81 | 81 | 0.00% | ±4.05 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Sample restriction 'at least four MPs each' implemented as to_prior_seats >= 4 (evaluated party only): requiring both to_prior_seats and from_prior_seats >= 4 gives 1,535 dyads, while the to-party-only filter gives exactly the paper's 1,842 (and 1,836 / 1,833 in the gender data). US rows have prior_seats coded 999 and pass the filter.
- (reproduction.json) Coalition/opposition dummies taken as prior_coalition / prior_opposition (the codebook lists these as used in the analysis and govern_together / opposition_together as unused), although the paper text describes them as measured at the time of the survey.
- (reproduction.json) Gender-split DV computed as 10 - dislike (the gender file stores only the reversed thermometer); gender 2 = women, 1 = men per codebook.

Agent notes: Independent reproduction of Table 1 from the paper text and the codebooks only (authors' code not opened). Data: dyadic_data_1-4-22.Rdata (updated_data) for columns 1-2, gender_disagregated_8-8-21.rds for columns 3-4. Model: fixest::feols, DV party_like (mean 0-10 thermometer of i's partisans toward j), regressor to_pfeml, controls rile_distance_s (standardized CMP rile distance, supplied in data), prior_coalition, prior_opposition; country-election (cntryyr) fixed effects; SEs clustered by cntryyr. Three exploratory runs (variable inspection and row counts under alternative seat filters, no estimates) preceded a single scored run; no claim-comparison iterations were used. All 11 point estimates/counts match the paper at its reported precision (adj. R2 also matches: 0.15/0.31/0.31/0.30). Clustered SEs from fixest are smaller than the paper's (e.g. 0.36 vs 0.43 for col 1, 0.42 vs 0.52 for col 2); SEs are not among the scored claims.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,769 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,143 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 285 bytes, from `benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/independent/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 917 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,360 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 269 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,396 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 286 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 269 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 1,674 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 1,061 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 269 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/attempt-3/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,310 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,288 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 264 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,982 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 269 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261107T172633Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
