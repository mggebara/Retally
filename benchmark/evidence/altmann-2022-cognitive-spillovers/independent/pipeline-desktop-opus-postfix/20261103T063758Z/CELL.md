# altmann-2022-cognitive-spillovers · independent · pipeline-desktop-opus-postfix · 20261103T063758Z

| | |
|---|---|
| Paper | `altmann-2022-cognitive-spillovers` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T063758Z |
| Date | 2026-11-03T06:37:58Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T063758Z` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 4/13 |
| First scored | 4/13 (execution 1) |
| Final | **13/13** |
| Package files withheld | 106 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `choice_quality_intervention_t2_col1` | 0.107 (0.018) | 0.106921 | 0.07% | ±0.018 (se_band) | PASS | FAIL |
| `choice_quality_intervention_t2_col2` | 0.11 (0.017) | 0.112783 | 2.53% | ±0.017 (se_band) | PASS | FAIL |
| `default_adherence_intervention_t2_col5` | -0.217 (0.022) | -0.216832 | 0.08% | ±0.022 (se_band) | PASS | FAIL |
| `default_adherence_intervention_t2_col6` | -0.219 (0.022) | -0.224243 | 2.39% | ±0.022 (se_band) | PASS | FAIL |
| `default_adherence_directed_attention_t2_col7` | -0.137 (0.026) | -0.137015 | 0.01% | ±0.026 (se_band) | PASS | FAIL |
| `default_adherence_forced_choice_t2_col7` | -0.3 (0.021) | -0.299874 | 0.04% | ±0.021 (se_band) | PASS | FAIL |
| `background_quality_intervention_lab_t3_col1` | -0.028 (0.017) | -0.028245 | 0.87% | ±0.017 (se_band) | PASS | PASS |
| `background_quality_intervention_lab_t3_col2` | -0.038 (0.014) | -0.036654 | 3.54% | ±0.014 (se_band) | PASS | FAIL |
| `memory_intervention_online_t3_col5` | -0.114 (0.019) | -0.114252 | 0.22% | ±0.019 (se_band) | PASS | PASS |
| `payoff_share_intervention_t4_col1` | 0.006 (0.013) | 0.005834 | 2.77% | ±0.013 (se_band) | PASS | PASS |
| `n_obs_lab_tables_2_to_4` | 12160 | 12160 | 0.00% | ±608 (relative) | PASS | FAIL |
| `n_subjects_lab_tables_2_to_4` | 608 | 608 | 0.00% | ±30.4 (relative) | PASS | FAIL |
| `memory_intervention_online_t3_col6` | -0.113 (0.017) | -0.113364 | 0.32% | ±0.017 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) experiment wave indicator not found

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 26,201 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T063758Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 25,091 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T063758Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 898 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T063758Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 457 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T063758Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 10,739 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T063758Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 483 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T063758Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,101 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T063758Z/attempt-1/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 457 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T063758Z/samples.txt`
- [`output/script.R`](output/script.R) — 11,745 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T063758Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 483 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T063758Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,615 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T063758Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,740 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/65b1f1fb1b8f55dfb7218600.json`
- [`output/answer-2.md`](output/answer-2.md) — 11,746 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/99ad4dbc33a49d0cf2500f10.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request 65b1f1fb1b8f55dfb7218600: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix (request 99ad4dbc33a49d0cf2500f10: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
