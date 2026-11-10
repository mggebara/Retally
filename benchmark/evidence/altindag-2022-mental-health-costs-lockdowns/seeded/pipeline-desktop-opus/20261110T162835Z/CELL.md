# altindag-2022-mental-health-costs-lockdowns · seeded · pipeline-desktop-opus · 20261110T162835Z

| | |
|---|---|
| Paper | `altindag-2022-mental-health-costs-lockdowns` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261110T162835Z |
| Date | 2026-11-10T16:28:35Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-altindag-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 7/10 |
| First scored | 7/10 (execution 1) |
| Final | **8/10** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `days_outside_last_week_table3_col3` | -1.09 (0.18) | -1.08986 | 0.01% | ±0.0218 (relative) | PASS | PASS |
| `under_curfew_table3_col3` | 0.708 (0.045) | 0.708352 | 0.05% | ±0.01416 (relative) | PASS | PASS |
| `never_goes_out_table3_col3` | 0.297 (0.036) | 0.297368 | 0.12% | ±0.00594 (relative) | PASS | PASS |
| `n_obs_days_outside_table3_col3` | 1214 | 1214 | 0.00% | ±60.7 (relative) | PASS | PASS |
| `n_obs_under_curfew_table3_col3` | 1222 | 1222 | 0.00% | ±61.1 (relative) | PASS | PASS |
| `mental_distress_index_table4_col3` | 0.205 (0.094) | 0.157113 | 23.36% | ±0.0041 (relative) | FAIL | FAIL |
| `somatic_symptoms_index_table4_col3` | 0.175 (0.085) | 0.080142 | 54.20% | ±0.0035 (relative) | FAIL | FAIL |
| `nonsomatic_symptoms_index_table4_col3` | 0.158 (0.092) | 0.155809 | 1.39% | ±0.00316 (relative) | PASS | FAIL |
| `sum_srq20_yes_answers_table4_col3` | 0.734 (0.44) | 0.73423 | 0.03% | ±0.01468 (relative) | PASS | PASS |
| `n_obs_mental_distress_index_table4_col3` | 1133 | 1133 | 0.00% | ±56.65 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/10 pass, which agrees with the row's 8/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Mental health indices built with Anderson (2008) inverse-covariance weighting of control-group-standardized items (control group = born 1956 or later, full analysis sample), index re-standardized to control-group mean 0 / SD 1, and defined only for respondents answering all 20 SRQ items; the paper cites Anderson (2008) but does not spell out weighting, reference group or missing-item rule

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 197,457 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 14,584 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 15,702 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 15,578 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 264 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 5,239 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 479 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 265 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 5,766 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 632 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 270 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 5,186 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 694 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/attempt-3/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/execution.json`
- [`output/script.R`](output/script.R) — 5,787 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 882 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/seeded/pipeline/20261110T162835Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,240 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/4283653e6823d8f7b37ffa6e.json`
- [`output/answer-2.md`](output/answer-2.md) — 5,767 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/ebff11994e782c84e3a472e9.json`
- [`output/answer-3.md`](output/answer-3.md) — 5,187 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/81f907500e5dbe0748a5c217.json`
- [`output/answer-4.md`](output/answer-4.md) — 5,788 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/2e3da0864a5daec6f0bc7b6d.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 10 |
| attempt-2 | claim | 0 | — | — | 10 |
| attempt-3 | claim | 0 | — | — | 10 |
| final | final | 0 | no | 1.5 | 10 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 4283653e6823d8f7b37ffa6e: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request ebff11994e782c84e3a472e9: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus (request 81f907500e5dbe0748a5c217: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus (request 2e3da0864a5daec6f0bc7b6d: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 4 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
