# altmann-2022-cognitive-spillovers · blind · claude-code · 2026-11-01-a

| | |
|---|---|
| Paper | `altmann-2022-cognitive-spillovers` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-01-a |
| Date | 2026-11-02T04:40:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-13papers-indep-blind-2026-11-01.json` |
| Artifacts | `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T043821Z` |
| Run directory | `benchmark/reproductions/altmann-2022-cognitive-spillovers/blind/2026-11-01-a` |
| Executions | 3 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 3) |
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

- (reproduction.json) Paper text supplied is an earlier working-paper version without the regression tables or the online experiment; specifications follow the task's quantity descriptions.
- (reproduction.json) Controls: age, female, field of study (subject_cat), A-level GPA quartile indicators with a missing-GPA category (q_abitur_grade_cat, keeps N constant), last math grade quartile indicators (q_math_grade_cat), background- and decision-task ability from the practice parts, perceived multitasking (5-point Likert item perc_multitasking_1), payoff-scheme (10/20/40) and wave (original_lab) indicators.
- (reproduction.json) Online controls: age, gender (3-level factor), screen size as browser window height and width.
- (DEVIATION: line) GPA and last math grade entered as quartile indicators (GPA with a missing-category), perceived multitasking as the 5-point Likert item; online screen size as window height and width.

Agent notes: Lab sample = Scarce condition (Treatment_Incentives 10/20/40) in Baseline, Directed Attention and Forced Choice: 12160 subject-rounds, 608 subjects. OLS via fixest::feols with subject-clustered SEs. Outcomes: summation_correct (choice quality), default_followed (default adherence), load_correct (background task), payoff_share (Table 4). Online: memory on Treatment_intervention, 5472 obs, 608 subjects, clustered by subject. attempt-1 was exploratory (variable inspection, no RESULT lines); attempt-2 crashed in a print statement before RESULT lines and was fixed without changing the specification.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 26,468 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T043821Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 855 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T043821Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 266 bytes, from `benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/blind/2026-11-01-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 931 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T043821Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 72 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T043821Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 12,261 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T043821Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 437 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T043821Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 4,126 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T043821Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 360 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T043821Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 234 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T043821Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,834 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T043821Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,180 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T043821Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T043821Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,297 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261102T043821Z/stdout.txt`
