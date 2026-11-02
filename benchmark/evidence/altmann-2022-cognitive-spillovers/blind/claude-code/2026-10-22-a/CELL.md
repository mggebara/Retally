# altmann-2022-cognitive-spillovers · blind · claude-code · 2026-10-22-a

| | |
|---|---|
| Paper | `altmann-2022-cognitive-spillovers` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-22-a |
| Date | 2026-10-22T03:19:07Z |
| Results file | `benchmark/results/claude-code-6papers-all-modes-2026-10-22.json` |
| Artifacts | `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261022T032229Z` |
| Run directory | `benchmark/reproductions/altmann-2022-cognitive-spillovers/blind/2026-10-22-a` |
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
| `choice_quality_intervention_t2_col2` | 0.11 (0.017) | 0.111029 | 0.94% | ±0.017 (se_band) | PASS | PASS |
| `default_adherence_intervention_t2_col5` | -0.217 (0.022) | -0.216832 | 0.08% | ±0.022 (se_band) | PASS | PASS |
| `default_adherence_intervention_t2_col6` | -0.219 (0.022) | -0.220006 | 0.46% | ±0.022 (se_band) | PASS | PASS |
| `default_adherence_directed_attention_t2_col7` | -0.137 (0.026) | -0.137015 | 0.01% | ±0.026 (se_band) | PASS | PASS |
| `default_adherence_forced_choice_t2_col7` | -0.3 (0.021) | -0.299874 | 0.04% | ±0.021 (se_band) | PASS | PASS |
| `background_quality_intervention_lab_t3_col1` | -0.028 (0.017) | -0.028245 | 0.87% | ±0.017 (se_band) | PASS | PASS |
| `background_quality_intervention_lab_t3_col2` | -0.038 (0.014) | -0.03844 | 1.16% | ±0.014 (se_band) | PASS | PASS |
| `memory_intervention_online_t3_col5` | -0.114 (0.019) | -0.114252 | 0.22% | ±0.019 (se_band) | PASS | PASS |
| `payoff_share_intervention_t4_col1` | 0.006 (0.013) | 0.005834 | 2.77% | ±0.013 (se_band) | PASS | PASS |
| `n_obs_lab_tables_2_to_4` | 12160 | 12160 | 0.00% | ±121.6 (relative) | PASS | PASS |
| `n_subjects_lab_tables_2_to_4` | 608 | 608 | 0.00% | ±6.08 (relative) | PASS | PASS |
| `memory_intervention_online_t3_col6` | -0.113 (0.017) | -0.113364 | 0.32% | ±0.017 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Paper text supplied is the 2019 IZA working-paper version (no regression tables, no online experiment, 'Active Choice' instead of 'Forced Choice'); specifications were taken from the task descriptions of the published Tables 2-4 plus the data's variable labels.
- (reproduction.json) Control set mapping (choice of codings is mine): age = q_age; gender = q_gender (female dummy); field of study = subject_cat factor (4 categories); high school GPA = q_abitur_grade_cat factor (quartiles plus a 5th category for missing GPA, so no observations are dropped); last math grade = q_math_grade_cat factor (quartiles); ability = ability_load and ability_task; perceived multitasking ability = perc_multitasking_1 (Likert); payoff-scheme indicators = Treatment_Incentives factor (10/20/40); wave = original_lab factor.
- (reproduction.json) Online column 6 controls: age, gender as a factor (Female/Male/Other), and screen size entered as window_height1 and window_width1 linearly.

Agent notes: Lab sample: formatted_data_replication.dta restricted to Treatment_Incentives != Ample (scarce resources, 7-digit numbers), all three environments (Baseline, Directed Attention, Forced Choice), all 20 rounds, both waves: 12160 subject-rounds, 608 subjects. Outcomes: summation_correct (choice quality), default_followed (default adherence; in Forced Choice it codes choosing the alternative that is the default elsewhere), load_correct (background task), payoff_share (Table 4). Regressors: Treatment_intervention, or Directed/Forced dummies from Treatment_Environment (Baseline omitted). OLS via fixest::feols with SEs clustered by subject_id. Online: formatted_data_long_mturk.dta, memory on Treatment_intervention, 5472 subject-rounds, 608 subjects, clustered by subject. attempt-1 was an exploratory variable inspection with no RESULT lines. Before attempt-1, a botched launch (the script file had not been written, so Docker mounted an empty directory in its place and nothing ran) left an empty script.R directory and empty stdout/stderr; I removed the directory and overwrote those files with the real attempt-1 run. Only the README.md in the mount was read for documentation; no do-files, logs, .tex or figure outputs were opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 26,468 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261022T032229Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 855 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261022T032229Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 266 bytes, from `benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/blind/2026-10-22-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,142 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261022T032229Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261022T032229Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 14,847 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261022T032229Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,680 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261022T032229Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,855 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261022T032229Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 261 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261022T032229Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,415 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261022T032229Z/stdout.txt`
