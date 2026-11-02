# adams-2023-women-mps-affective-polarization · blind · claude-code · 2026-11-01-a

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-01-a |
| Date | 2026-11-02T04:24:00Z |
| Results file | `benchmark/results/claude-code-run2-13papers-indep-blind-2026-11-01.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T043821Z` |
| Run directory | `benchmark/reproductions/adams-2023-women-mps-affective-polarization/blind/2026-11-01-a` |
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
| `n_directed_dyads` | 1842 | 1525 | 17.21% | ±18.42 (relative) | FAIL | FAIL |
| `n_obs_women_partisans` | 1836 | 1525 | 16.94% | ±18.36 (relative) | FAIL | FAIL |
| `n_obs_men_partisans` | 1833 | 1519 | 17.13% | ±18.33 (relative) | FAIL | FAIL |
| `n_election_studies` | 81 | 76 | 6.17% | ±0.81 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/11 pass, which agrees with the row's 7/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Coalition/opposition dummies use prior_coalition / prior_opposition (governing status in the period up to the survey), which the dataset codebook flags as the analysis variables; govern_together / opposition_together (flagged 'not used') were not used.
- (reproduction.json) Women/men partisan DV built as 10 - dislike from the gender-disaggregated file (it stores only the reversed 0=like scale), so coefficients are on the 0-10 liking scale like columns 1-2.
- (reproduction.json) Seat counts of 999 treated as missing; the four-MP restriction requires to_prior_seats >= 4 and from_prior_seats >= 4.
- (reproduction.json) Country-year fixed effects and clustering both on cntryyr (no country-year in the estimation sample holds two election dates). The table's 'Country and year fixed effects' label was read as country-year FE, following the text.
- (reproduction.json) Left-right distance uses the dataset's precomputed standardized rile_distance_s (raw rile_distance mean 22.44 over the full file).

Agent notes: One exploratory run (attempt-1, no RESULT lines) checked the variables, then one estimation run (final). OLS via fixest::feols on directed dyads with both parties >= 4 MPs (prior seats), country-year FE, SEs clustered by election (cntryyr). n_directed_dyads is the column-2 N (the same as column 1: 1525); n_election_studies is the number of distinct country-years in that sample (76; 19 countries remain after the restrictions). No specification was tuned toward any paper value.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,597 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T043821Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,111 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T043821Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 298 bytes, from `benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/blind/2026-11-01-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,270 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T043821Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T043821Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 8,319 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T043821Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,932 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T043821Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,215 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T043821Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 248 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T043821Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,158 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T043821Z/stdout.txt`
