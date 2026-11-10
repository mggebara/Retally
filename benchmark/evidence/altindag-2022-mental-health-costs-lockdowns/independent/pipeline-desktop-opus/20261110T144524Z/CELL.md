# altindag-2022-mental-health-costs-lockdowns · independent · pipeline-desktop-opus · 20261110T144524Z

| | |
|---|---|
| Paper | `altindag-2022-mental-health-costs-lockdowns` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261110T144524Z |
| Date | 2026-11-10T14:45:24Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-altindag-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z` |
| Executions | 3 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 9/10 |
| First scored | 9/10 (execution 1) |
| Final | **10/10** |
| Package files withheld | 17 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `days_outside_last_week_table3_col3` | -1.09 (0.18) | -1.07299 | 1.56% | ±0.18 (se_band) | PASS | PASS |
| `under_curfew_table3_col3` | 0.708 (0.045) | 0.70489 | 0.44% | ±0.045 (se_band) | PASS | PASS |
| `never_goes_out_table3_col3` | 0.297 (0.036) | 0.289577 | 2.50% | ±0.036 (se_band) | PASS | PASS |
| `n_obs_days_outside_table3_col3` | 1214 | 1181 | 2.72% | ±60.7 (relative) | PASS | PASS |
| `n_obs_under_curfew_table3_col3` | 1222 | 1189 | 2.70% | ±61.1 (relative) | PASS | PASS |
| `mental_distress_index_table4_col3` | 0.205 (0.094) | 0.207079 | 1.01% | ±0.094 (se_band) | PASS | PASS |
| `somatic_symptoms_index_table4_col3` | 0.175 (0.085) | 0.146617 | 16.22% | ±0.085 (se_band) | PASS | PASS |
| `nonsomatic_symptoms_index_table4_col3` | 0.158 (0.092) | 0.206241 | 30.53% | ±0.092 (se_band) | PASS | PASS |
| `sum_srq20_yes_answers_table4_col3` | 0.734 (0.44) | 0.620494 | 15.46% | ±0.44 (se_band) | PASS | PASS |
| `n_obs_mental_distress_index_table4_col3` | 1133 | 1187 | 4.77% | ±56.65 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/10 pass, which agrees with the row's 10/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Anderson indices average z-scores over answered SRQ items, restricted to respondents answering at least 75% of the items (paper does not state its missing-item rule)

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 14,226 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 16,931 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 17,960 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 91 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 6,784 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 1,141 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 479 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 91 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 7,203 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 1,116 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 680 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z/attempt-2/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z/execution.json`
- [`output/script.R`](output/script.R) — 8,196 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,132 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,417 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T144524Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,785 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/e3952c310c564a9b7abb63bc.json`
- [`output/answer-2.md`](output/answer-2.md) — 7,204 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/ae5ba575903a9da05f918834.json`
- [`output/answer-3.md`](output/answer-3.md) — 8,197 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/f451719fa3805149e216f4ef.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 10 |
| attempt-2 | claim | 0 | — | — | 10 |
| final | final | 0 | no | 1.2 | 10 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request e3952c310c564a9b7abb63bc: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request ae5ba575903a9da05f918834: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus (request f451719fa3805149e216f4ef: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
