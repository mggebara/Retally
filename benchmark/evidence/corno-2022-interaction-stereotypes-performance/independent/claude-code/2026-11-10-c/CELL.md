# corno-2022-interaction-stereotypes-performance · independent · claude-code · 2026-11-10-c

| | |
|---|---|
| Paper | `corno-2022-interaction-stereotypes-performance` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-c |
| Date | 2026-11-10T14:36:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run3-1paper-corno-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143915Z` |
| Run directory | `benchmark/reproductions/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c` |
| Executions | 3 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 2) |
| Final | **13/13** |
| Package files withheld | 20 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `race_iat_mixed_room_whites_table3_col1` | 0.316 (0.14) | 0.3159 | 0.03% | ±0.14 (se_band) | PASS | PASS |
| `race_iat_mixed_room_blacks_table3_col2` | -0.094 (0.069) | -0.0944 | 0.43% | ±0.069 (se_band) | PASS | PASS |
| `n_obs_table3_whites` | 117 | 117 | 0.00% | ±5.85 (relative) | PASS | PASS |
| `n_obs_table3_blacks` | 332 | 332 | 0.00% | ±16.6 (relative) | PASS | PASS |
| `gpa_mixed_room_blacks_table4_panelB_col1` | 0.257 (0.125) | 0.2567 | 0.12% | ±0.125 (se_band) | PASS | PASS |
| `exams_passed_mixed_room_blacks_table4_panelB_col2` | 0.645 (0.245) | 0.6445 | 0.08% | ±0.245 (se_band) | PASS | PASS |
| `eligible_mixed_room_blacks_table4_panelB_col3` | 0.152 (0.04) | 0.1515 | 0.33% | ±0.04 (se_band) | PASS | PASS |
| `performance_index_mixed_room_blacks_table4_panelB_col4` | 0.443 (0.141) | 0.4433 | 0.07% | ±0.141 (se_band) | PASS | PASS |
| `gpa_mixed_room_whites_table4_panelA_col1` | -0.028 (0.243) | -0.0282 | 0.71% | ±0.243 (se_band) | PASS | PASS |
| `gpa_mixed_room_full_table4_panelC_col1` | 0.147 (0.102) | 0.1467 | 0.20% | ±0.102 (se_band) | PASS | PASS |
| `exams_passed_mixed_room_full_table4_panelC_col2` | 0.447 (0.204) | 0.4466 | 0.09% | ±0.204 (se_band) | PASS | PASS |
| `performance_index_mixed_room_full_table4_panelC_col4` | 0.289 (0.113) | 0.2892 | 0.07% | ±0.113 (se_band) | PASS | PASS |
| `n_obs_table4_panelC_cols1_2` | 499 | 499 | 0.00% | ±24.95 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Data: ForJournals_a/Data/Clean/uctdata_balanced.dta (499 students x 2 rounds = working sample); estimation on the follow-up round. attempt-1 was an exploratory variable listing (no RESULT lines). Table 3: OLS of follow-up Race IAT (DscoreraceIAT) on mixracebas, baseline Race IAT (DscoreraceIATbas), own controls (Female, Falseuct2012, durpcabas_nomiss, consbas_nomiss, Foreign, privateschool_nomiss plus their missing dummies), roommate controls (roFalseuct2012, rodurpcabas_nomiss, roconsbas_nomiss, roForeign_bas, roprivschool_nomiss plus missing dummies), residence FE, SEs clustered by baseline room, separately for whites/blacks. Table 4: same controls without lagged outcome, residence + academic program (regprogram) FE in subsamples; full sample adds White/Coloured/Indian-Other dummies with race-group (Black/White/other) x residence FE and program FE. Performance index uses the dataset's PCAperf variable (labelled 'Performance index 2012, PCA'). attempt-2 (kind claim) gave identical coefficients but fixest dropped singleton FE groups (N 493 in Panel C); check_attempt reported all claims within tolerance, but since the paper's working sample is 499 the final run keeps singletons (fixef.rm='none'), which yields N=117/332/499 and standard errors matching the paper (e.g. 0.243, 0.125). Coefficients unchanged across attempt-2 and final. No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,249 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143915Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,016 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143915Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 291 bytes, from `benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,132 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143915Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143915Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 451,209 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143915Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 272 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143915Z/attempt-1/timing.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 279 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143915Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,671 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143915Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143915Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,372 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143915Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 272 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143915Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,932 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143915Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,780 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143915Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143915Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,372 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143915Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 272 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/independent/claude-code/20261110T143915Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
