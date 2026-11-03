# altmann-2022-cognitive-spillovers · seeded · claude-code · 2026-10-22-a

| | |
|---|---|
| Paper | `altmann-2022-cognitive-spillovers` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-22-a |
| Date | 2026-10-22T03:01:43Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-6papers-all-modes-2026-10-22.json` |
| Artifacts | `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/seeded/claude-code/20261022T032229Z` |
| Run directory | `benchmark/reproductions/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 13/13 |
| First scored | 13/13 (execution 1) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `choice_quality_intervention_t2_col1` | 0.107 (0.018) | 0.106921 | 0.07% | ±0.00214 (relative) | PASS | PASS |
| `choice_quality_intervention_t2_col2` | 0.11 (0.017) | 0.110224 | 0.20% | ±0.0022 (relative) | PASS | PASS |
| `default_adherence_intervention_t2_col5` | -0.217 (0.022) | -0.216832 | 0.08% | ±0.00434 (relative) | PASS | PASS |
| `default_adherence_intervention_t2_col6` | -0.219 (0.022) | -0.219333 | 0.15% | ±0.00438 (relative) | PASS | PASS |
| `default_adherence_directed_attention_t2_col7` | -0.137 (0.026) | -0.137015 | 0.01% | ±0.00274 (relative) | PASS | PASS |
| `default_adherence_forced_choice_t2_col7` | -0.3 (0.021) | -0.299874 | 0.04% | ±0.006 (relative) | PASS | PASS |
| `background_quality_intervention_lab_t3_col1` | -0.028 (0.017) | -0.028245 | 0.87% | ±0.00056 (relative) | PASS | PASS |
| `background_quality_intervention_lab_t3_col2` | -0.038 (0.014) | -0.037937 | 0.17% | ±0.00076 (relative) | PASS | PASS |
| `memory_intervention_online_t3_col5` | -0.114 (0.019) | -0.114252 | 0.22% | ±0.00228 (relative) | PASS | PASS |
| `payoff_share_intervention_t4_col1` | 0.006 (0.013) | 0.005834 | 2.77% | ±0.0005 (printed_precision) | PASS | PASS |
| `n_obs_lab_tables_2_to_4` | 12160 | 12160 | 0.00% | ±608 (relative) | PASS | PASS |
| `n_subjects_lab_tables_2_to_4` | 608 | 608 | 0.00% | ±30.4 (relative) | PASS | PASS |
| `memory_intervention_online_t3_col6` | -0.113 (0.017) | -0.113364 | 0.32% | ±0.00226 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Translated the authors' do-files (4_2_Interventions_targeted_domain.do, 4_2_Cognitive_Spillover.do, 4_3_Payoffs_And_Efficiency.do, globals from master.do) into fixest::feols OLS with subject-clustered SEs. Lab sample: formatted_data_replication.dta with Treatment_Incentives != 4 (Ample dropped); controls = i.Treatment_Incentives, i.original_lab, c.(ability_task ability_load)##i.original_lab, q_age, i.q_gender, i.perc_multitasking_1_easy, perc_multitasking_2, i.subject_cat, i.q_abitur_grade_cat, i.q_math_grade_cat. Online: formatted_data_long_mturk.dta, memory on Treatment_intervention (+ window_height1 window_width1 age i.gender). N = 12160 and 608 clusters in every lab regression; 5472 online. All RESULT values match the claims on rounding after a single scored run, so no claim or error attempts were recorded. Procedural note: an earlier docker invocation ran before script.R had been written (the shell write was blocked by the harness), and docker created an empty directory at the script.R mount path; Rscript had no script to execute and produced empty stdout/stderr. That spurious directory and the empty logs were deleted, and it is not counted as an attempt because no script was executed.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 90,589 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/seeded/claude-code/20261022T032229Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 754 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/seeded/claude-code/20261022T032229Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 261 bytes, from `benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a/paper.txt`

## What it produced

- [`output/reproduction.json`](output/reproduction.json) — 1,643 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/seeded/claude-code/20261022T032229Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,745 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/seeded/claude-code/20261022T032229Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/seeded/claude-code/20261022T032229Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 967 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/seeded/claude-code/20261022T032229Z/stdout.txt`
