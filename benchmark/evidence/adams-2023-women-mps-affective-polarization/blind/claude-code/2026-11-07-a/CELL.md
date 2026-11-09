# adams-2023-women-mps-affective-polarization · blind · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T17:18:35Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261107T172508Z` |
| Run directory | `benchmark/reproductions/adams-2023-women-mps-affective-polarization/blind/2026-11-07-a` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 7/11 (execution 2) |
| Final | **7/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `women_mps_coef_bivariate` | 1.89 (0.43) | 1.91282 | 1.21% | ±0.43 (se_band) | PASS | PASS |
| `women_mps_coef_full` | 1.73 (0.52) | 1.8756 | 8.42% | ±0.52 (se_band) | PASS | PASS |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 2.06566 | 1.64% | ±0.53 (se_band) | PASS | PASS |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.1899 | 5.30% | ±0.5 (se_band) | PASS | PASS |
| `right_left_distance_coef_full` | -0.6 (0.09) | -0.578219 | 3.63% | ±0.09 (se_band) | PASS | PASS |
| `coalition_partners_coef_full` | 0.94 (0.25) | 1.04845 | 11.54% | ±0.25 (se_band) | PASS | PASS |
| `opposition_partners_coef_full` | 0.37 (0.11) | 0.389226 | 5.20% | ±0.11 (se_band) | PASS | PASS |
| `n_directed_dyads` | 1842 | 1525 | 17.21% | ±92.1 (relative) | FAIL | FAIL |
| `n_obs_women_partisans` | 1836 | 1525 | 16.94% | ±91.8 (relative) | FAIL | FAIL |
| `n_obs_men_partisans` | 1833 | 1519 | 17.13% | ±91.65 (relative) | FAIL | FAIL |
| `n_election_studies` | 81 | 76 | 6.17% | ±4.05 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/11 pass, which agrees with the row's 7/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: attempt-1 was exploratory (variable inspection, no RESULT lines). Final script: fixest feols on directed dyads (dyadic_data_1-4-22.Rdata), DV party_like (0-10 mean thermometer of i's partisans toward j), regressor to_pfeml (out-party proportion women MPs, t-1), country-year (cntryyr) fixed effects, SEs clustered by cntryyr. Sample: to_prior_seats >= 4 and from_prior_seats >= 4, with seat value 999 treated as a missing code (10 dyads); listwise deletion drops 44 more with missing to_pfeml. Full model adds rile_distance_s (pre-standardized \|CMP rile\| distance in the data), prior_coalition and prior_opposition (the codebook lists these, not govern_together/opposition_together, as the analysis variables; a diagnostic with the concurrent dummies gives a similar to_pfeml coefficient, 1.93, printed but not scored). Gender columns use gender_disagregated_8-8-21.rds, DV = 10 - dislike, gender 2 = women, 1 = men, same controls/FE/clustering/sample rule. n_election_studies = distinct cntryyr in the full-model sample. Read the three docx codebooks and readme.rtf in the mount; no scripts or result files opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 19,349 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261107T172508Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,111 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261107T172508Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 285 bytes, from `benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/blind/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,454 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261107T172508Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261107T172508Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 9,665 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261107T172508Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 263 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261107T172508Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,614 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261107T172508Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,569 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261107T172508Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 310 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261107T172508Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,740 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261107T172508Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 263 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261107T172508Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
