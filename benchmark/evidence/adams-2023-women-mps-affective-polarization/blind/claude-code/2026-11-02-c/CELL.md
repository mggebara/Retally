# adams-2023-women-mps-affective-polarization · blind · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:11:40Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T202753Z` |
| Run directory | `benchmark/reproductions/adams-2023-women-mps-affective-polarization/blind/2026-11-02-c` |
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
| `women_mps_coef_full` | 1.73 (0.52) | 1.92446 | 11.24% | ±0.52 (se_band) | PASS | PASS |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 2.11537 | 0.73% | ±0.53 (se_band) | PASS | PASS |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.23929 | 9.67% | ±0.5 (se_band) | PASS | PASS |
| `right_left_distance_coef_full` | -0.6 (0.09) | -0.573101 | 4.48% | ±0.09 (se_band) | PASS | PASS |
| `coalition_partners_coef_full` | 0.94 (0.25) | 1.07692 | 14.57% | ±0.25 (se_band) | PASS | PASS |
| `opposition_partners_coef_full` | 0.37 (0.11) | 0.380451 | 2.82% | ±0.11 (se_band) | PASS | PASS |
| `n_directed_dyads` | 1842 | 1535 | 16.67% | ±92.1 (relative) | FAIL | FAIL |
| `n_obs_women_partisans` | 1836 | 1535 | 16.39% | ±91.8 (relative) | FAIL | FAIL |
| `n_obs_men_partisans` | 1833 | 1529 | 16.58% | ±91.65 (relative) | FAIL | FAIL |
| `n_election_studies` | 81 | 81 | 0.00% | ±4.05 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/11 pass, which agrees with the row's 8/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Two exploratory runs (variable listing; sample/coding checks, no RESULT lines), then one scored run. Data: dyadic_data_1-4-22.Rdata (columns 1-2) and gender_disagregated_8-8-21.rds (columns 3-4). Sample: directed dyads with to_prior_seats >= 4 and from_prior_seats >= 4 (US parties carry a 999 placeholder seat count and are kept), rows with missing to_pfeml dropped by the estimator. DV: party_like (0-10 thermometer); for the gender file, 10 - dislike (codebook: dislike is the thermometer rescaled 0=like, 10=dislike; verified party_dislike == 10 - party_like in the dyadic file), gender 2 = women, 1 = men. Regressor to_pfeml; controls rile_distance_s (dataset's standardized CMP rile distance; raw mean 22.44 / SD 17.61 over the full file matching the paper's footnote), govern_together, opposition_together. fixest feols with cntryyr fixed effects and SEs clustered by cntryyr. n_election_studies = distinct cntryyr in the full-model estimation sample (one election date per cntryyr). No docker hangs.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 19,074 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T202753Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,111 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T202753Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 285 bytes, from `benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/blind/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,046 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T202753Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T202753Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 28,831 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T202753Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,912 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T202753Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T202753Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,370 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T202753Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,560 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T202753Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,708 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T202753Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 248 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T202753Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,032 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/claude-code/20261102T202753Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
