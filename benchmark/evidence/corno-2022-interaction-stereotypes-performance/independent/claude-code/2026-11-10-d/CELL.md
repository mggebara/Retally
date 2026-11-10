# corno-2022-interaction-stereotypes-performance · independent · claude-code · 2026-11-10-d

| | |
|---|---|
| Paper | `corno-2022-interaction-stereotypes-performance` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-d |
| Date | 2026-11-10T14:37:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run4-1paper-corno-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z` |
| Run directory | `benchmark/reproductions/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-d` |
| Executions | 4 |
| Refinements | 2 (1 error + 1 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 3) |
| Final | **13/13** |
| Package files withheld | 20 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `race_iat_mixed_room_whites_table3_col1` | 0.316 (0.14) | 0.315851 | 0.05% | ±0.14 (se_band) | PASS | PASS |
| `race_iat_mixed_room_blacks_table3_col2` | -0.094 (0.069) | -0.094447 | 0.48% | ±0.069 (se_band) | PASS | PASS |
| `n_obs_table3_whites` | 117 | 117 | 0.00% | ±5.85 (relative) | PASS | PASS |
| `n_obs_table3_blacks` | 332 | 332 | 0.00% | ±16.6 (relative) | PASS | PASS |
| `gpa_mixed_room_blacks_table4_panelB_col1` | 0.257 (0.125) | 0.256671 | 0.13% | ±0.125 (se_band) | PASS | PASS |
| `exams_passed_mixed_room_blacks_table4_panelB_col2` | 0.645 (0.245) | 0.644533 | 0.07% | ±0.245 (se_band) | PASS | PASS |
| `eligible_mixed_room_blacks_table4_panelB_col3` | 0.152 (0.04) | 0.151538 | 0.30% | ±0.04 (se_band) | PASS | PASS |
| `performance_index_mixed_room_blacks_table4_panelB_col4` | 0.443 (0.141) | 0.443286 | 0.06% | ±0.141 (se_band) | PASS | PASS |
| `gpa_mixed_room_whites_table4_panelA_col1` | -0.028 (0.243) | -0.028236 | 0.84% | ±0.243 (se_band) | PASS | PASS |
| `gpa_mixed_room_full_table4_panelC_col1` | 0.147 (0.102) | 0.146735 | 0.18% | ±0.102 (se_band) | PASS | PASS |
| `exams_passed_mixed_room_full_table4_panelC_col2` | 0.447 (0.204) | 0.446589 | 0.09% | ±0.204 (se_band) | PASS | PASS |
| `performance_index_mixed_room_full_table4_panelC_col4` | 0.289 (0.113) | 0.289163 | 0.06% | ±0.113 (se_band) | PASS | PASS |
| `n_obs_table4_panelC_cols1_2` | 499 | 499 | 0.00% | ±24.95 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Used ForJournals_a/Data/Clean/uctdata_balanced.dta (499 students x 2 rounds; follow-up round 2 rows carry outcomes, baseline IAT in *bas variables). Attempt-1: exploratory variable listing. Attempt-2: crashed (helper function named se shadowed fixest::se). Attempt-3: all estimates; check_attempt reported all claims within tolerance, but Table 4 N was 493/106/324 because fixest drops singleton academic-program FE cells by default; final run sets fixef.rm='none' (as OLS with program dummies), giving N=499/117/332 as in the paper, unchanged coefficients, and SEs and R2 matching the paper's Table 4. Spec: OLS, own controls (female, UCT score/1000, durable-goods PCA wealth index, consumption, foreign, private school, with mean-imputation and missing dummies as supplied in the data), roommate controls (same minus female), residence FE (subsamples) or race-group x residence FE plus White/Coloured/Indian-Other dummies (full sample), academic program FE for Table 4, baseline IAT for Table 3; SEs clustered by baseline room. GPA and the performance index (PCAperf) taken as provided in the data file. No hangs; each sandbox run took under 2 s.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,249 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,016 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 291 bytes, from `benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-d/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,151 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 494,461 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 272 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/attempt-1/timing.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 223 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 4,539 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 98 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 125 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 272 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/attempt-2/timing.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 404 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 4,549 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 1,496 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 272 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/attempt-3/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,774 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,621 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,496 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 271 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143916Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
