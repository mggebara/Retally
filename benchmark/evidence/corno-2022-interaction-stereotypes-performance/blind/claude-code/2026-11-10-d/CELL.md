# corno-2022-interaction-stereotypes-performance · blind · claude-code · 2026-11-10-d

| | |
|---|---|
| Paper | `corno-2022-interaction-stereotypes-performance` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-d |
| Date | 2026-11-10T14:36:40Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run4-1paper-corno-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z` |
| Run directory | `benchmark/reproductions/corno-2022-interaction-stereotypes-performance/blind/2026-11-10-d` |
| Executions | 4 |
| Refinements | 0 (0 error + 0 claim) |
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

- (reproduction.json) Academic performance index uses the dataset's provided PCAperf variable (first principal component of GPA, exams passed, eligible to continue) rather than recomputing the PCA.
- (reproduction.json) GPA uses the dataset's provided standardized GPA variable as is.

Agent notes: Data: uctdata_balanced.dta (499 students x 2 rounds); working sample = round 2 rows (499: 332 black, 117 white, 18 coloured, 32 Indian/other). Treatment mixracebas; cluster on roomnum_base (unique room id). Own controls: Female, Falseuct2012, durpcabas_nomiss, consbas_nomiss, Foreign, privateschool_nomiss plus their missing dummies (foreign_missing and privateschool_miss are all zero and drop out). Roommate controls: the ro* versions of the same (no female) plus missing dummies. Table 3: follow-up DscoreraceIAT on mixracebas + DscoreraceIATbas + controls \| residence FE, by race. Table 4: outcome (GPA, examspassed, continue, PCAperf) on mixracebas + controls \| residence FE + regprogram FE (panels A/B); panel C adds white/coloured/Else dummies and race-group (black/white/other) x residence FE + program FE. Estimated with fixest feols, clustered by room. Attempts 1-2 were exploratory (variable listing, coding checks; no RESULT lines). Attempt-3 printed RESULT lines using fixest's default singleton removal, which dropped observations alone in a program FE cell (No. Obs. 493 for panel C); I revised to fixef.rm='none' so the estimation sample matches OLS with dummies (No. Obs. 499). This was a methodological self-review, not a comparison with claimed values; coefficients are identical between attempt-3 and the final run, only the panel C count and SEs changed. Note: while reading the paper's method sections (sections 2-5) for specification details, the narrative text displayed some reported point estimates (e.g. the Table 3 white coefficient and Table 4 black GPA coefficient are quoted in section 5 prose); I did not search for them and did not tune anything toward them. Exploration and runs were quick; no hang.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,817 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 985 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 291 bytes, from `benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/blind/2026-11-10-d/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 836 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 529,891 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 266 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,484 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,186 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 266 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 3,946 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 1,329 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 266 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/attempt-3/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,601 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,159 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,330 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 266 bytes, from `benchmark/results/artifacts/corno-2022-interaction-stereotypes-performance/blind/claude-code/20261110T143921Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
