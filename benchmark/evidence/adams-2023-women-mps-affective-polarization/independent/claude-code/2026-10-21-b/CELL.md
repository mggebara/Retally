# adams-2023-women-mps-affective-polarization · independent · claude-code · 2026-10-21-b

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-21-b |
| Date | 2026-10-22T02:08:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-7papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261022T021417Z` |
| Run directory | `benchmark/reproductions/adams-2023-women-mps-affective-polarization/independent/2026-10-21-b` |
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
| `women_mps_coef_full` | 1.73 (0.52) | 1.75827 | 1.63% | ±0.52 (se_band) | PASS | PASS |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 2.13137 | 1.49% | ±0.53 (se_band) | PASS | PASS |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.16541 | 3.13% | ±0.5 (se_band) | PASS | PASS |
| `right_left_distance_coef_full` | -0.6 (0.09) | -0.596712 | 0.55% | ±0.09 (se_band) | PASS | PASS |
| `coalition_partners_coef_full` | 0.94 (0.25) | 0.951726 | 1.25% | ±0.25 (se_band) | PASS | PASS |
| `opposition_partners_coef_full` | 0.37 (0.11) | 0.333888 | 9.76% | ±0.11 (se_band) | PASS | PASS |
| `n_directed_dyads` | 1842 | 1842 | 0.00% | ±92.1 (relative) | PASS | PASS |
| `n_obs_women_partisans` | 1836 | 1836 | 0.00% | ±91.8 (relative) | PASS | PASS |
| `n_obs_men_partisans` | 1833 | 1833 | 0.00% | ±91.65 (relative) | PASS | PASS |
| `n_election_studies` | 81 | 81 | 0.00% | ±4.05 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) The paper restricts to dyads where both parties have at least four MPs in the year before the survey. In the data, filtering on the evaluated (to) party's prior seats (to_prior_seats >= 4) reproduces the reported N of 1,842 exactly, while filtering on both parties gives 1,535. I used the to-party filter. Dyads where to_pfeml is missing are dropped listwise.
- (reproduction.json) Elite right-left distance is the dataset's pre-standardized rile_distance_s (standardized over the full 2,266-row dyadic file; its raw mean of 22.4 and SD of 17.6 match the paper's footnote 3), not re-standardized within the estimation sample.
- (reproduction.json) Coalition and opposition partner dummies are govern_together and opposition_together (status at the time of the survey), not prior_coalition and prior_opposition.
- (reproduction.json) The gender-specific DV is 10 - dislike from gender_disagregated_8-8-21.rds (gender 2 = women, 1 = men), with the same to_prior_seats >= 4 filter.

Agent notes: Three exploratory runs (no RESULT lines) inspected the variables, the codebooks (extracted from the .docx with utils::unzip inside the sandbox) and sample-restriction counts. Final model: fixest feols of party_like on to_pfeml (+ rile_distance_s, govern_together, opposition_together in the full model) with cntryyr fixed effects and SEs clustered by cntryyr, for Table 1 columns 1-4. All four Ns (1842/1842/1836/1833) and the 81 elections match exactly. The coefficients are close to Table 1. The largest gaps are the full-model women-MPs coefficient (1.758 vs 1.73) and the opposition-partners coefficient (0.334 vs 0.37). I made no claim-driven changes and never ran check_attempt.

Files read outside the mount: `<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/independent/2026-10-21-b/task.md (the task instructions, read as directed)`, `<home>/.claude/projects/-Users-matthew-dev-Retally/4331b322-448f-44d6-bc9b-f556920716ab/tool-results/b2vazh9gx.txt (the harness saved the cat of paper.txt there because the output was too large; I read only its inline preview, which is the same paper text)`

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,006 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261022T021417Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,143 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261022T021417Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 285 bytes, from `benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/independent/2026-10-21-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 484 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261022T021417Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 261 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261022T021417Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 21,385 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261022T021417Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,655 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261022T021417Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261022T021417Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 17,146 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261022T021417Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 1,583 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261022T021417Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261022T021417Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 817 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261022T021417Z/attempt-3/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,668 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261022T021417Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,242 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261022T021417Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 264 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261022T021417Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,146 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261022T021417Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
