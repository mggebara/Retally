# altindag-2022-mental-health-costs-lockdowns · independent · pipeline-desktop-opus-run2 · 20261110T163226Z

| | |
|---|---|
| Paper | `altindag-2022-mental-health-costs-lockdowns` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261110T163226Z |
| Date | 2026-11-10T16:32:26Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-altindag-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z` |
| Executions | 3 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 8/10 |
| First scored | 8/10 (execution 1) |
| Final | **10/10** |
| Package files withheld | 17 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `days_outside_last_week_table3_col3` | -1.09 (0.18) | -1.07242 | 1.61% | ±0.18 (se_band) | PASS | PASS |
| `under_curfew_table3_col3` | 0.708 (0.045) | 0.703413 | 0.65% | ±0.045 (se_band) | PASS | PASS |
| `never_goes_out_table3_col3` | 0.297 (0.036) | 0.287151 | 3.32% | ±0.036 (se_band) | PASS | PASS |
| `n_obs_days_outside_table3_col3` | 1214 | 1181 | 2.72% | ±60.7 (relative) | PASS | PASS |
| `n_obs_under_curfew_table3_col3` | 1222 | 1189 | 2.70% | ±61.1 (relative) | PASS | PASS |
| `mental_distress_index_table4_col3` | 0.205 (0.094) | 0.175576 | 14.35% | ±0.094 (se_band) | PASS | PASS |
| `somatic_symptoms_index_table4_col3` | 0.175 (0.085) | 0.144748 | 17.29% | ±0.085 (se_band) | PASS | FAIL |
| `nonsomatic_symptoms_index_table4_col3` | 0.158 (0.092) | 0.21872 | 38.43% | ±0.092 (se_band) | PASS | PASS |
| `sum_srq20_yes_answers_table4_col3` | 0.734 (0.44) | 0.704622 | 4.00% | ±0.44 (se_band) | PASS | PASS |
| `n_obs_mental_distress_index_table4_col3` | 1133 | 1154 | 1.85% | ±56.65 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/10 pass, which agrees with the row's 10/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Overall mental distress index set to missing for respondents with more than one missing SRQ-20 item (paper does not state its missing-item rule)

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 14,226 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 19,804 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 18,709 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 194 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 6,745 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 1,001 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 3,339 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 91 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 5,382 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 991 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,372 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z/attempt-2/stdout.txt`
- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z/execution.json`
- [`output/script.R`](output/script.R) — 6,237 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 992 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,658 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/independent/pipeline/20261110T163226Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,746 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/e3952c310c564a9b7abb63bc.json`
- [`output/answer-2.md`](output/answer-2.md) — 5,383 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/bff43531fea2aa420b4d1eff.json`
- [`output/answer-3.md`](output/answer-3.md) — 6,238 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/14c17d5cc266e476f73e97aa.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 10 |
| attempt-2 | claim | 0 | — | — | 10 |
| final | final | 0 | no | 2.5 | 10 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request e3952c310c564a9b7abb63bc: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request bff43531fea2aa420b4d1eff: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run2 (request 14c17d5cc266e476f73e97aa: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
