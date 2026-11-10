# altindag-2022-mental-health-costs-lockdowns · blind · pipeline-desktop-opus-run4 · 20261110T145215Z

| | |
|---|---|
| Paper | `altindag-2022-mental-health-costs-lockdowns` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261110T145215Z |
| Date | 2026-11-10T14:52:15Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-1paper-altindag-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145215Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/10 |
| First scored | 10/10 (execution 2) |
| Final | **10/10** |
| Package files withheld | 17 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `days_outside_last_week_table3_col3` | -1.09 (0.18) | -1.08986 | 0.01% | ±0.18 (se_band) | PASS | PASS |
| `under_curfew_table3_col3` | 0.708 (0.045) | 0.708352 | 0.05% | ±0.045 (se_band) | PASS | PASS |
| `never_goes_out_table3_col3` | 0.297 (0.036) | 0.297368 | 0.12% | ±0.036 (se_band) | PASS | PASS |
| `n_obs_days_outside_table3_col3` | 1214 | 1199 | 1.24% | ±60.7 (relative) | PASS | PASS |
| `n_obs_under_curfew_table3_col3` | 1222 | 1207 | 1.23% | ±61.1 (relative) | PASS | PASS |
| `mental_distress_index_table4_col3` | 0.205 (0.094) | 0.155694 | 24.05% | ±0.094 (se_band) | PASS | PASS |
| `somatic_symptoms_index_table4_col3` | 0.175 (0.085) | 0.120128 | 31.36% | ±0.085 (se_band) | PASS | PASS |
| `nonsomatic_symptoms_index_table4_col3` | 0.158 (0.092) | 0.150024 | 5.05% | ±0.092 (se_band) | PASS | PASS |
| `sum_srq20_yes_answers_table4_col3` | 0.734 (0.44) | 0.73423 | 0.03% | ±0.44 (se_band) | PASS | PASS |
| `n_obs_mental_distress_index_table4_col3` | 1133 | 1117 | 1.41% | ±56.65 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/10 pass, which agrees with the row's 10/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 14,792 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145215Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 10,410 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145215Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145215Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 2,172 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145215Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 6,369 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145215Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 2,172 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145215Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145215Z/attempt-1/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145215Z/execution.json`
- [`output/script.R`](output/script.R) — 6,763 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145215Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 3,669 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145215Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 479 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145215Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,370 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/3763adf11763d145acf54880.json`
- [`output/answer-2.md`](output/answer-2.md) — 6,764 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/cfaeae581cb859ebcac44db5.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 1 | — | — | 0 |
| final | final | 0 | no | 1.2 | 10 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request 3763adf11763d145acf54880: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run4 (request cfaeae581cb859ebcac44db5: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
