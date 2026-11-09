# altmann-2022-cognitive-spillovers · independent · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `altmann-2022-cognitive-spillovers` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T17:38:31Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261107T194750Z` |
| Run directory | `benchmark/reproductions/altmann-2022-cognitive-spillovers/independent/2026-11-07-a` |
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

- (reproduction.json) Control set built from the dataset's prepared variables: q_age, female (q_gender), field of study (subject_cat factor), high-school GPA as quartile factor with a missing category (q_abitur_grade_cat) to keep all 12,160 observations, last math grade quartile factor (q_math_grade_cat), ability_load, ability_task, perceived multitasking as the 1-5 Likert item (perc_multitasking_1), payoff-scheme factor (Treatment_Incentives) and wave factor (original_lab). The exact coding the authors used is not stated in the paper text provided.
- (reproduction.json) Online experiment controls: age, gender factor (female/male/other), and screen size entered as window_height1 and window_width1 linearly.

Agent notes: attempt-1 was exploratory (variable listing, no RESULT lines). Lab sample = Treatment_Incentives != Ample (scarce resources; Baseline, Directed Attention, Forced Choice; all payoff schemes and both waves): 12,160 subject-rounds, 608 subjects. All regressions OLS via fixest::feols with SEs clustered by subject_id. Outcomes: summation_correct (choice quality), default_followed (default adherence), load_correct (background task), payoff_share (Table 4), memory (online). The final run is the first scored run; RESULT values were compared with the claims after the run, all agree to the reported rounding, and the script was not changed, so there are no claim attempts. The paper.txt supplied is an earlier working-paper version without the regression tables, so the specifications come from the claim descriptions. The README.md in the package (documentation, not a script) was read.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 26,657 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261107T194750Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 887 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261107T194750Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 266 bytes, from `benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/independent/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 842 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261107T194750Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 72 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261107T194750Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 11,667 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261107T194750Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 259 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261107T194750Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,067 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261107T194750Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,725 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261107T194750Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 270 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261107T194750Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,765 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261107T194750Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 259 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261107T194750Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
