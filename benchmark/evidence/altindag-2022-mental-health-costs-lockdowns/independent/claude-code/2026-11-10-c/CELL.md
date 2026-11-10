# altindag-2022-mental-health-costs-lockdowns · independent · claude-code · 2026-11-10-c

| | |
|---|---|
| Paper | `altindag-2022-mental-health-costs-lockdowns` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-c |
| Date | 2026-11-10T11:35:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run3-1paper-altindag-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113202Z` |
| Run directory | `benchmark/reproductions/altindag-2022-mental-health-costs-lockdowns/independent/2026-11-10-c` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/10 |
| First scored | 10/10 (execution 2) |
| Final | **10/10** |
| Package files withheld | 17 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `days_outside_last_week_table3_col3` | -1.09 (0.18) | -1.0899 | 0.01% | ±0.18 (se_band) | PASS | PASS |
| `under_curfew_table3_col3` | 0.708 (0.045) | 0.7084 | 0.06% | ±0.045 (se_band) | PASS | PASS |
| `never_goes_out_table3_col3` | 0.297 (0.036) | 0.2974 | 0.13% | ±0.036 (se_band) | PASS | PASS |
| `n_obs_days_outside_table3_col3` | 1214 | 1199 | 1.24% | ±60.7 (relative) | PASS | PASS |
| `n_obs_under_curfew_table3_col3` | 1222 | 1207 | 1.23% | ±61.1 (relative) | PASS | PASS |
| `mental_distress_index_table4_col3` | 0.205 (0.094) | 0.1571 | 23.37% | ±0.094 (se_band) | PASS | PASS |
| `somatic_symptoms_index_table4_col3` | 0.175 (0.085) | 0.112 | 36.00% | ±0.085 (se_band) | PASS | PASS |
| `nonsomatic_symptoms_index_table4_col3` | 0.158 (0.092) | 0.1519 | 3.86% | ±0.092 (se_band) | PASS | PASS |
| `sum_srq20_yes_answers_table4_col3` | 0.734 (0.44) | 0.7342 | 0.03% | ±0.44 (se_band) | PASS | PASS |
| `n_obs_mental_distress_index_table4_col3` | 1133 | 1117 | 1.41% | ±56.65 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/10 pass, which agrees with the row's 10/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) fixest removes fixed-effect singletons (15-16 obs per regression; does not change coefficients), so reported Ns (1199, 1207, 1117) are below the paper's (1214, 1222, 1133), which presumably keep singletons as Stata reg/areg would; adding those back matches the paper's Ns exactly.
- (reproduction.json) Anderson (2008) indices built on the full respondent sample: items z-scored with control-group (born 1956 or later) mean/SD, weighted by row sums of the inverse covariance matrix of the z-scores, complete cases only, then re-standardized by control mean/SD. The paper's exact weighting routine (_gweightave2) was not available; index coefficients (0.157, 0.112, 0.152) are below the paper's (0.205, 0.175, 0.158) while the SRQ-20 sum matches (0.734).

Agent notes: Attempt-1 was an exploratory variable listing (no RESULT lines). Final run: RD with before1955 treatment, running variable dif (months older than Dec 1955), linear on each side (dif + dif:before1955), sample \|dif\|<=45 among survey respondents (non_response==0), FE for birth month, province and surveyor, indicators for education, ethnicity and female, SEs clustered by month-year of birth (modate), via fixest::feols. Table 3 coefficients reproduce to 3 decimals. After the final run I ran check_attempt once (all claims within tolerance) and made no further changes. No run hung. The ICPSR 'read me .pdf' in the mount (data documentation) was read; no script files were opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 17,603 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113202Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 946 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113202Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 286 bytes, from `benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/independent/2026-11-10-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 579 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113202Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113202Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 14,518 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113202Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 269 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113202Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,932 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113202Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,779 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113202Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 996 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113202Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 863 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113202Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 269 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/claude-code/20261110T113202Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
