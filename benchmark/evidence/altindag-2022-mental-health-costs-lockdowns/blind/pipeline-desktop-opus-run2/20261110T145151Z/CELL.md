# altindag-2022-mental-health-costs-lockdowns · blind · pipeline-desktop-opus-run2 · 20261110T145151Z

| | |
|---|---|
| Paper | `altindag-2022-mental-health-costs-lockdowns` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261110T145151Z |
| Date | 2026-11-10T14:51:51Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-altindag-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145151Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 9/10 |
| First scored | 9/10 (execution 1) |
| Final | **9/10** |
| Package files withheld | 17 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `days_outside_last_week_table3_col3` | -1.09 (0.18) | -1.06375 | 2.41% | ±0.18 (se_band) | PASS | PASS |
| `under_curfew_table3_col3` | 0.708 (0.045) | 0.708019 | 0.00% | ±0.045 (se_band) | PASS | PASS |
| `never_goes_out_table3_col3` | 0.297 (0.036) | 0.285103 | 4.01% | ±0.036 (se_band) | PASS | PASS |
| `n_obs_days_outside_table3_col3` | 1214 | 1165 | 4.04% | ±60.7 (relative) | PASS | PASS |
| `n_obs_under_curfew_table3_col3` | 1222 | 1173 | 4.01% | ±61.1 (relative) | PASS | PASS |
| `mental_distress_index_table4_col3` | 0.205 (0.094) | 0.15046 | 26.60% | ±0.094 (se_band) | PASS | PASS |
| `somatic_symptoms_index_table4_col3` | 0.175 (0.085) | 0.145179 | 17.04% | ±0.085 (se_band) | PASS | PASS |
| `nonsomatic_symptoms_index_table4_col3` | 0.158 (0.092) | 0.135968 | 13.94% | ±0.092 (se_band) | PASS | PASS |
| `sum_srq20_yes_answers_table4_col3` | 0.734 (0.44) | 0.497153 | 32.27% | ±0.44 (se_band) | PASS | PASS |
| `n_obs_mental_distress_index_table4_col3` | 1133 | 1060 | 6.44% | ±56.65 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/10 pass, which agrees with the row's 9/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 14,792 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145151Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145151Z/execution.json`
- [`output/script.R`](output/script.R) — 7,753 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145151Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 999 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145151Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,343 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145151Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,754 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/3763adf11763d145acf54880.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 1.5 | 10 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 3763adf11763d145acf54880: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
