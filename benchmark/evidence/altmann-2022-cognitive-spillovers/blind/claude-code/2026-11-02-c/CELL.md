# altmann-2022-cognitive-spillovers · blind · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `altmann-2022-cognitive-spillovers` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:11:57Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T202753Z` |
| Run directory | `benchmark/reproductions/altmann-2022-cognitive-spillovers/blind/2026-11-02-c` |
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
| `n_obs_lab_tables_2_to_4` | 12160 | 12160 | 0.00% | ±608 (relative) | PASS | PASS |
| `n_subjects_lab_tables_2_to_4` | 608 | 608 | 0.00% | ±30.4 (relative) | PASS | PASS |
| `memory_intervention_online_t3_col6` | -0.113 (0.017) | -0.113364 | 0.32% | ±0.017 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Field of study entered as the 4-category subject_cat (Others/Law/Economics/Sciences) rather than the 14-value q_subject.
- (reproduction.json) High-school GPA and last math grade entered as the dataset's categorical versions (q_abitur_grade_cat, quartiles with category 5 = missing/no A-level; q_math_grade_cat quartiles) so no observations are dropped for the 400 rows with missing GPA.
- (reproduction.json) Perceived multitasking ability entered as the Likert item perc_multitasking_1 only (not perc_multitasking_2).
- (reproduction.json) Online controls: age, gender factor (female/male/other), and screen size as window_height1 and window_width1 (linear).
- (reproduction.json) Clustered SEs use fixest's default small-sample correction; coefficients are unaffected.

Agent notes: Attempt-1 was an exploratory variable listing (no RESULT lines). Lab sample: formatted_data_replication.dta restricted to Treatment_Incentives != Ample (payoff schemes 10/20/40, both waves via original_lab), giving 12160 subject-rounds and 608 subjects in Baseline, Directed Attention and Forced Choice. Outcomes: summation_correct (decision task correct), default_followed (default adherence; in Forced Choice the dataset codes choice of the default-equivalent alternative), load_correct (background task correct), payoff_share (share of maximal payoff). Regressors: Treatment_intervention, or Directed/Forced indicators for column 7. Controls (cols 2, 6, T3 col 2): q_age, q_gender, subject_cat, q_abitur_grade_cat, q_math_grade_cat, ability_load, ability_task, perc_multitasking_1, payoff-scheme and wave dummies. Online: formatted_data_long_mturk.dta, memory (0-1 points in Memory task, read as fraction of pairs uncovered) on Treatment_intervention, 5472 subject-rounds, 608 subjects. All OLS via fixest with SEs clustered by subject_id. The paper text supplied appears to be an earlier version without the regression tables or online experiment, so specifications follow the task's quantity descriptions plus the data labels. Read the dataset README.md (inside the mount) for file descriptions only.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 26,945 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T202753Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 855 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T202753Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 266 bytes, from `benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/blind/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 914 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T202753Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 282 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T202753Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 12,316 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T202753Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,515 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T202753Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,203 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T202753Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T202753Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,150 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T202753Z/stdout.txt`
