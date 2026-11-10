# altindag-2022-mental-health-costs-lockdowns · seeded · pipeline-desktop-opus-run2 · 20261110T163624Z

| | |
|---|---|
| Paper | `altindag-2022-mental-health-costs-lockdowns` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261110T163624Z |
| Date | 2026-11-10T16:36:24Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-altindag-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 7/10 |
| First scored | 7/10 (execution 1) |
| Final | **7/10** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `days_outside_last_week_table3_col3` | -1.09 (0.18) | -1.08986 | 0.01% | ±0.0218 (relative) | PASS | PASS |
| `under_curfew_table3_col3` | 0.708 (0.045) | 0.708352 | 0.05% | ±0.01416 (relative) | PASS | PASS |
| `never_goes_out_table3_col3` | 0.297 (0.036) | 0.297368 | 0.12% | ±0.00594 (relative) | PASS | PASS |
| `n_obs_days_outside_table3_col3` | 1214 | 1214 | 0.00% | ±60.7 (relative) | PASS | PASS |
| `n_obs_under_curfew_table3_col3` | 1222 | 1222 | 0.00% | ±61.1 (relative) | PASS | PASS |
| `mental_distress_index_table4_col3` | 0.205 (0.094) | 0.155508 | 24.14% | ±0.0041 (relative) | FAIL | FAIL |
| `somatic_symptoms_index_table4_col3` | 0.175 (0.085) | 0.143685 | 17.89% | ±0.0035 (relative) | FAIL | FAIL |
| `nonsomatic_symptoms_index_table4_col3` | 0.158 (0.092) | 0.146281 | 7.42% | ±0.00316 (relative) | FAIL | FAIL |
| `sum_srq20_yes_answers_table4_col3` | 0.734 (0.44) | 0.73423 | 0.03% | ±0.01468 (relative) | PASS | PASS |
| `n_obs_mental_distress_index_table4_col3` | 1133 | 1133 | 0.00% | ±56.65 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/10 pass, which agrees with the row's 7/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Indices built as equal-weighted averages of control-standardised item z-scores (per the paper's description), complete cases only; exact Anderson weighting/missing-item handling not stated

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 197,457 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 14,518 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 15,210 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 16,245 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 264 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 4,930 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 176 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 479 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 265 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 5,096 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 264 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 479 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 270 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 5,682 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 88 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 710 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/attempt-3/stdout.txt`
- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/execution.json`
- [`output/script.R`](output/script.R) — 5,138 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 176 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 679 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T163624Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 4,931 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/4283653e6823d8f7b37ffa6e.json`
- [`output/answer-2.md`](output/answer-2.md) — 5,097 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/f25663c147da315afc6b2067.json`
- [`output/answer-3.md`](output/answer-3.md) — 5,683 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/7497a5e143fb11dcea65e2de.json`
- [`output/answer-4.md`](output/answer-4.md) — 5,139 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/2943356c0fcc26f9decb3c24.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 10 |
| attempt-2 | claim | 0 | — | — | 10 |
| attempt-3 | claim | 0 | — | — | 10 |
| final | final | 0 | no | 2.2 | 10 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 4283653e6823d8f7b37ffa6e: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request f25663c147da315afc6b2067: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run2 (request 7497a5e143fb11dcea65e2de: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run2 (request 2943356c0fcc26f9decb3c24: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 4 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
