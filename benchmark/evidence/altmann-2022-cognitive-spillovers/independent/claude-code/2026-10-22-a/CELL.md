# altmann-2022-cognitive-spillovers · independent · claude-code · 2026-10-22-a

| | |
|---|---|
| Paper | `altmann-2022-cognitive-spillovers` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-22-a |
| Date | 2026-10-22T03:10:05Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-6papers-all-modes-2026-10-22.json` |
| Artifacts | `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261022T032229Z` |
| Run directory | `benchmark/reproductions/altmann-2022-cognitive-spillovers/independent/2026-10-22-a` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 3) |
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

- (reproduction.json) Control set operationalised from variable labels: field of study = subject_cat factor; high-school GPA = q_abitur_grade_cat factor (quartiles, category 5 = missing, keeps all 12160 obs); last math grade = q_math_grade_cat factor (quartiles); perceived multitasking = perc_multitasking_1 (Likert) and perc_multitasking_2 (relative) entered linearly; payoff scheme = Treatment_Incentives factor; wave = original_lab.
- (reproduction.json) Online screen size control entered as window_height1 and window_width1 linearly; gender as a factor (3 levels).

Agent notes: Lab sample: formatted_data_replication.dta restricted to Treatment_Incentives != 4 (drops the Ample condition), giving 12160 subject-rounds and 608 subjects across Baseline, Directed Attention, Forced Choice. OLS via fixest with SEs clustered by subject_id. Outcomes: summation_correct (decision task), default_followed (default adherence), load_correct (background task), payoff_share. Online: formatted_data_long_mturk.dta, memory on Treatment_intervention, clustered by subject. Two exploratory runs (variable inspection, sample counts) preceded the single scored run; no claim-comparison or error-repair attempts were made. The supplied paper.txt appears to be an earlier version of the paper (no online experiment, different table numbering), so specifications followed the task's claim descriptions. The dataset README.md was read (documentation within the mount, not a script); no .do or other script files were opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 25,905 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261022T032229Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 887 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261022T032229Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 266 bytes, from `benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/independent/2026-10-22-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 854 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261022T032229Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261022T032229Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 129,243 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261022T032229Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,041 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261022T032229Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261022T032229Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 4,521 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261022T032229Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,018 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261022T032229Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,272 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261022T032229Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261022T032229Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,166 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261022T032229Z/stdout.txt`
