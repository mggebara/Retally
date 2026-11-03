# altmann-2022-cognitive-spillovers · independent · claude-code · 2026-11-01-a

| | |
|---|---|
| Paper | `altmann-2022-cognitive-spillovers` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-01-a |
| Date | 2026-11-02T04:28:24Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-13papers-indep-blind-2026-11-01.json` |
| Artifacts | `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T043820Z` |
| Run directory | `benchmark/reproductions/altmann-2022-cognitive-spillovers/independent/2026-11-01-a` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 2) |
| Final | **13/13** |
| Package files withheld | 106 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `choice_quality_intervention_t2_col1` | 0.107 (0.018) | 0.106921 | 0.07% | ±0.018 (se_band) | PASS | PASS |
| `choice_quality_intervention_t2_col2` | 0.11 (0.017) | 0.110841 | 0.76% | ±0.017 (se_band) | PASS | PASS |
| `default_adherence_intervention_t2_col5` | -0.217 (0.022) | -0.216832 | 0.08% | ±0.022 (se_band) | PASS | PASS |
| `default_adherence_intervention_t2_col6` | -0.219 (0.022) | -0.219869 | 0.40% | ±0.022 (se_band) | PASS | PASS |
| `default_adherence_directed_attention_t2_col7` | -0.137 (0.026) | -0.137015 | 0.01% | ±0.026 (se_band) | PASS | PASS |
| `default_adherence_forced_choice_t2_col7` | -0.3 (0.021) | -0.299874 | 0.04% | ±0.021 (se_band) | PASS | PASS |
| `background_quality_intervention_lab_t3_col1` | -0.028 (0.017) | -0.028245 | 0.87% | ±0.017 (se_band) | PASS | PASS |
| `background_quality_intervention_lab_t3_col2` | -0.038 (0.014) | -0.038489 | 1.29% | ±0.014 (se_band) | PASS | PASS |
| `memory_intervention_online_t3_col5` | -0.114 (0.019) | -0.114252 | 0.22% | ±0.019 (se_band) | PASS | PASS |
| `payoff_share_intervention_t4_col1` | 0.006 (0.013) | 0.005834 | 2.77% | ±0.013 (se_band) | PASS | PASS |
| `n_obs_lab_tables_2_to_4` | 12160 | 12160 | 0.00% | ±608 (relative) | PASS | PASS |
| `n_subjects_lab_tables_2_to_4` | 608 | 608 | 0.00% | ±30.4 (relative) | PASS | PASS |
| `memory_intervention_online_t3_col6` | -0.113 (0.017) | -0.113364 | 0.32% | ±0.017 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: attempt-1 was exploratory: it listed variables and labels and printed no RESULT lines. The final run is the first and only scored run. Lab sample: formatted_data_replication.dta with Treatment_Incentives != 4 (the scarce payoff schemes 10/20/40; 4 = Ample), all 3 environments, both waves: 12160 subject-rounds, 608 subjects. Outcomes: summation_correct (decision task), default_followed, load_correct (background task), payoff_share. Treatment: Treatment_intervention; col 7 uses Treatment_Environment==2 (Directed) and ==3 (Forced). Controls (picked from the claim descriptions before seeing any estimates): q_age, q_gender, subject_cat factor (field of study), q_abitur_grade_cat factor (GPA quartiles plus a missing category, so no rows are dropped), q_math_grade_cat factor, ability_load, ability_task, perc_multitasking_1 and _2, Treatment_Incentives factor, original_lab (wave). Online: formatted_data_long_mturk.dta, memory on Treatment_intervention; col 6 adds age, gender factor, window_height1 and window_width1 (screen size). All OLS via fixest with SEs clustered by subject_id. The paper.txt supplied is an earlier working-paper version (564 subjects, Active Choice, no online study), so I took the specifications from the claim descriptions. I read the dataset README.md (inside the mount); I opened no code files.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 25,905 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T043820Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 887 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T043820Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 266 bytes, from `benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/independent/2026-11-01-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,182 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T043820Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 72 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T043820Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 23,436 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T043820Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,823 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T043820Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,832 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T043820Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T043820Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 8,996 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T043820Z/stdout.txt`
