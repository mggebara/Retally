# altmann-2022-cognitive-spillovers · independent · pipeline-desktop-opus-postfix2 · 20261103T115702Z

| | |
|---|---|
| Paper | `altmann-2022-cognitive-spillovers` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261103T115702Z |
| Date | 2026-11-03T11:57:02Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z` |
| Executions | 3 |
| Refinements | 2 (1 error + 1 claim) |
| First attempt | 4/13 |
| First scored | 4/13 (execution 1) |
| Final | **4/13** |
| Package files withheld | 106 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `choice_quality_intervention_t2_col1` | 0.107 (0.018) | 0.082992 | 22.44% | ±0.018 (se_band) | FAIL | FAIL |
| `choice_quality_intervention_t2_col2` | 0.11 (0.017) | 0.08681 | 21.08% | ±0.017 (se_band) | FAIL | FAIL |
| `default_adherence_intervention_t2_col5` | -0.217 (0.022) | -0.157625 | 27.36% | ±0.022 (se_band) | FAIL | FAIL |
| `default_adherence_intervention_t2_col6` | -0.219 (0.022) | -0.159198 | 27.31% | ±0.022 (se_band) | FAIL | FAIL |
| `default_adherence_directed_attention_t2_col7` | -0.137 (0.026) | -0.098736 | 27.93% | ±0.026 (se_band) | FAIL | FAIL |
| `default_adherence_forced_choice_t2_col7` | -0.3 (0.021) | -0.217716 | 27.43% | ±0.021 (se_band) | FAIL | FAIL |
| `background_quality_intervention_lab_t3_col1` | -0.028 (0.017) | -0.018673 | 33.31% | ±0.017 (se_band) | PASS | PASS |
| `background_quality_intervention_lab_t3_col2` | -0.038 (0.014) | -0.019821 | 47.84% | ±0.014 (se_band) | FAIL | FAIL |
| `memory_intervention_online_t3_col5` | -0.114 (0.019) | -0.114252 | 0.22% | ±0.019 (se_band) | PASS | PASS |
| `payoff_share_intervention_t4_col1` | 0.006 (0.013) | 0.006465 | 7.75% | ±0.013 (se_band) | PASS | PASS |
| `n_obs_lab_tables_2_to_4` | 12160 | 17840 | 46.71% | ±608 (relative) | FAIL | FAIL |
| `n_subjects_lab_tables_2_to_4` | 608 | 892 | 46.71% | ±30.4 (relative) | FAIL | FAIL |
| `memory_intervention_online_t3_col6` | -0.113 (0.017) | -0.113364 | 0.32% | ±0.017 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 4/13 pass, which agrees with the row's 4/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) no cognitive-load treatment column found; scarce restriction not applied
- (DEVIATION: line) lab sample has 17840 rows vs 12160 stated
- (DEVIATION: line) control wave not found

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 26,201 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 15,342 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 27,841 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 377 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 390 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 10,342 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 857 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,482 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 898 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z/attempt-2/feedback.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 489 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 13,457 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 729 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,722 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z/attempt-2/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 489 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z/samples.txt`
- [`output/script.R`](output/script.R) — 14,855 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 729 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,563 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261103T115702Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,343 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/65b1f1fb1b8f55dfb7218600.json`
- [`output/answer-2.md`](output/answer-2.md) — 13,458 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/267fbc6f317b711663779e61.json`
- [`output/answer-3.md`](output/answer-3.md) — 14,856 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/18c35ffb2b8aefdcac82c6a2.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request 65b1f1fb1b8f55dfb7218600: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix2 (request 267fbc6f317b711663779e61: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix2 (request 18c35ffb2b8aefdcac82c6a2: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
