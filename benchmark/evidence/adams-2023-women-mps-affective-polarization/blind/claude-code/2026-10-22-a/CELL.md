# adams-2023-women-mps-affective-polarization · blind · claude-code · 2026-10-22-a

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-22-a |
| Date | 2026-10-22T02:45:01Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-blind-rerun-2026-10-22.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T024643Z` |
| Run directory | `benchmark/reproductions/adams-2023-women-mps-affective-polarization/blind/2026-10-22-a` |
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
| `n_directed_dyads` | 1842 | 1535 | 16.67% | ±92.1 (relative) | FAIL | FAIL |
| `n_obs_women_partisans` | 1836 | 1535 | 16.39% | ±91.8 (relative) | FAIL | FAIL |
| `n_obs_men_partisans` | 1833 | 1529 | 16.58% | ±91.65 (relative) | FAIL | FAIL |
| `n_election_studies` | 81 | 81 | 0.00% | ±4.05 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/11 pass, which agrees with the row's 8/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Two exploratory runs (variable listing, seat-count and missingness checks; no RESULT lines), then one scored run. Specification taken from the paper text and the dataset codebooks: OLS with fixest, country-year (cntryyr) fixed effects, SEs clustered by cntryyr. Sample: directed dyads in dyadic_data_1-4-22.Rdata with to_prior_seats >= 4 and from_prior_seats >= 4 (the paper's 'at least four MPs each'; the 999 seat code, used only for the two US parties, passes the test), minus 44 dyads with missing to_pfeml. DV for columns 1-2 is party_like. For columns 3-4 it is 10 - dislike from gender_disagregated_8-8-21.rds (gender 2 = women, 1 = men), with the same seat filter. Regressors: to_pfeml; rile_distance_s, the CMP rile distance standardized over the full dataset (mean 22.44, SD 17.61, matching footnote 3); prior_coalition and prior_opposition, which the codebook lists as the variables used in the analysis (govern_together and opposition_together are marked 'not used'). n_election_studies counts the distinct cntryyr in the column-2 estimation sample. Judgment call: requiring only the out-party to have at least four seats would give a larger sample. I kept the paper's wording, which requires both parties to have at least four.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,586 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T024643Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,111 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T024643Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 298 bytes, from `benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/blind/2026-10-22-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,328 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T024643Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T024643Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 9,338 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T024643Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,774 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T024643Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T024643Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 4,706 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T024643Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,793 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T024643Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,940 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T024643Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 248 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T024643Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,017 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261022T024643Z/stdout.txt`
