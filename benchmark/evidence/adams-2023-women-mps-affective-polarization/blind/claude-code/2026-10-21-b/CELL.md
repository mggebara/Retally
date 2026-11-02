# adams-2023-women-mps-affective-polarization · blind · claude-code · 2026-10-21-b

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-21-b |
| Date | 2026-10-22T02:12:33Z |
| Results file | `benchmark/results/claude-code-7papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T021417Z` |
| Run directory | `benchmark/reproductions/adams-2023-women-mps-affective-polarization/blind/2026-10-21-b` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 8/11 (execution 3) |
| Final | **8/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `women_mps_coef_bivariate` | 1.89 (0.43) | 1.90904 | 1.01% | ±0.43 (se_band) | PASS | PASS |
| `women_mps_coef_full` | 1.73 (0.52) | 1.87189 | 8.20% | ±0.52 (se_band) | PASS | PASS |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 2.06223 | 1.80% | ±0.53 (se_band) | PASS | PASS |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.18651 | 5.00% | ±0.5 (se_band) | PASS | PASS |
| `right_left_distance_coef_full` | -0.6 (0.09) | -0.578241 | 3.63% | ±0.09 (se_band) | PASS | PASS |
| `coalition_partners_coef_full` | 0.94 (0.25) | 1.0484 | 11.53% | ±0.25 (se_band) | PASS | PASS |
| `opposition_partners_coef_full` | 0.37 (0.11) | 0.38918 | 5.18% | ±0.11 (se_band) | PASS | PASS |
| `n_directed_dyads` | 1842 | 1535 | 16.67% | ±18.42 (relative) | FAIL | FAIL |
| `n_obs_women_partisans` | 1836 | 1535 | 16.39% | ±18.36 (relative) | FAIL | FAIL |
| `n_obs_men_partisans` | 1833 | 1529 | 16.58% | ±18.33 (relative) | FAIL | FAIL |
| `n_election_studies` | 81 | 81 | 0.00% | ±0.81 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/11 pass, which agrees with the row's 8/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Sample restriction applied literally as the paper states it: both parties i and j had >= 4 prior lower-chamber seats (from_prior_seats >= 4 & to_prior_seats >= 4), then listwise deletion on to_pfeml (44 rows), giving 1,535 dyads. Exploration (attempt-2) showed that filtering on the evaluated (to) party's seats only, with non-missing to_pfeml, yields 1,842 rows -- the dyad count quoted in the task context -- which suggests the authors' code may have applied the >=4-MP filter only to the out-party. This alternative was NOT adopted, because switching to it would be adjusting the specification toward a number given in the task.
- (reproduction.json) Coalition/opposition-partner dummies use prior_coalition / prior_opposition (government status in the period before/at the time of the post-election survey), which the dataset codebook lists as the variables used in the analysis; govern_together / opposition_together are listed by the codebook as not used.
- (reproduction.json) Elite left-right distance uses the dataset's pre-standardized rile_distance_s (standardized over the full 2,266-row dyadic file, mean 22.44, SD 17.61, matching footnote 3), not re-standardized on the estimation sample.
- (reproduction.json) Gender-disaggregated DV computed as 10 - dislike (dislike is the reversed 0-10 thermometer); gender 2 = women, 1 = men per the codebook. Same >=4-seat rule for both parties.

Agent notes: Independent, blind reproduction of Table 1. Data: dyadic_data_1-4-22.Rdata (updated_data) for columns 1-2 and gender_disagregated_8-8-21.rds for columns 3-4. DV = party_like (mean 0-10 thermometer i's partisans give j). Regressor = to_pfeml (j's share of women MPs at t-1). Full model adds rile_distance_s, prior_coalition, prior_opposition. OLS via fixest::feols with country-year (cntryyr) fixed effects and SEs clustered by cntryyr (election). n_election_studies = distinct cntryyr in the column-2 estimation sample (81, 20 countries). Read, besides paper.txt and data files, the data directory's readme.rtf and the three codebook .docx files (data documentation, not scripts or result tables). No author code was present or read. Two exploratory runs (attempt-1, attempt-2) printed no RESULT lines; the final run is the first and only scored estimation.

Files read outside the mount: `<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/blind/2026-10-21-b/task.md (the task instructions, read as directed)`

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,586 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T021417Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,111 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T021417Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 298 bytes, from `benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/blind/2026-10-21-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,428 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T021417Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T021417Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 10,063 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T021417Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,148 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T021417Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T021417Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,392 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T021417Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,931 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T021417Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,847 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T021417Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 248 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T021417Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,629 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T021417Z/stdout.txt`
