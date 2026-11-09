# altmann-2022-cognitive-spillovers · independent · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `altmann-2022-cognitive-spillovers` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:00:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T202751Z` |
| Run directory | `benchmark/reproductions/altmann-2022-cognitive-spillovers/independent/2026-11-02-c` |
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

- (reproduction.json) The supplied paper.txt is an earlier working-paper version (564 subjects, one wave, 'Active Choice' naming), so the specification was taken from the claim descriptions together with the data's variable labels.
- (reproduction.json) Controls coding is my choice: field of study as subject_cat dummies, high-school GPA as q_abitur_grade_cat dummies (the category for missing GPA keeps N=12160), last math grade as q_math_grade_cat quartile dummies, perceived multitasking as both perc_multitasking_1 (Likert) and perc_multitasking_2 (relative), payoff scheme as Treatment_Incentives dummies, wave as original_lab. Online controls are age, gender dummies, and window_height1 and window_width1 for screen size.

Agent notes: Attempt-1 was exploratory: it looked at variables and labels and printed no RESULT lines. Final run: the lab sample drops the Ample condition (Treatment_Incentives==4), which leaves 12160 subject-rounds and 608 subjects across Baseline, Directed Attention and Forced Choice. All models are OLS with fixest, SEs clustered by subject_id. Outcomes: summation_correct (decision task), default_followed (default adherence), load_correct (background task), payoff_share; online: memory in formatted_data_long_mturk.dta (5472 obs, 608 subjects). Every RESULT matches its claimed value to the reported precision. I compared after the final run and did not change the script afterwards, so there are no claim attempts. No docker hangs.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 26,382 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T202751Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 887 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T202751Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 266 bytes, from `benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/independent/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 801 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T202751Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T202751Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 18,551 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T202751Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,922 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T202751Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,874 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T202751Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T202751Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,227 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/claude-code/20261102T202751Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
