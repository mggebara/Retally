# altmann-2022-cognitive-spillovers · blind · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `altmann-2022-cognitive-spillovers` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T17:41:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261107T194749Z` |
| Run directory | `benchmark/reproductions/altmann-2022-cognitive-spillovers/blind/2026-11-07-a` |
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

- (reproduction.json) Paper text supplied is an earlier working-paper version (Active Choice, no online experiment, no regression tables); specifications follow the task's quantity descriptions plus the data's variable labels.
- (reproduction.json) Control set (cols 2, 6, Table 3 col 2): q_age, q_gender, field of study as factor(subject_cat), high-school GPA as factor(q_abitur_grade_cat) (quartiles + missing category, keeps N fixed), last math grade as factor(q_math_grade_cat) (quartiles), ability_load, ability_task, perceived multitasking as perc_multitasking_1 (Likert, linear), factor(Treatment_Incentives) payoff scheme, factor(original_lab) wave. Exact coding of these controls in the original is a guess.
- (reproduction.json) Online controls (Table 3 col 6): age, factor(gender), screen size entered as window_height1 and window_width1 linearly.

Agent notes: Lab sample: formatted_data_replication.dta with Ample condition (Treatment_Incentives==4) dropped -> 12160 subject-rounds, 608 subjects (Baseline, Directed Attention, Forced Choice; all payoff schemes, both waves). Outcomes: summation_correct (decision task correct), default_followed, load_correct (background task correct), payoff_share. Intervention = Treatment_intervention; col 7 uses Treatment_Environment==2/3 dummies vs Baseline. Online: formatted_data_long_mturk.dta, memory on Treatment_intervention (5472 obs, 608 subjects). All OLS via fixest::feols with SEs clustered by subject_id. attempt-1 was an exploratory variable inspection (no RESULT lines). README.md of the package was read for file descriptions only; no scripts, logs, .tex or figures were opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 27,220 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261107T194749Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 855 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261107T194749Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 279 bytes, from `benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/blind/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,052 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261107T194749Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261107T194749Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 23,541 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261107T194749Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 253 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261107T194749Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,077 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261107T194749Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,002 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261107T194749Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261107T194749Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 12,379 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261107T194749Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 253 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/claude-code/20261107T194749Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
