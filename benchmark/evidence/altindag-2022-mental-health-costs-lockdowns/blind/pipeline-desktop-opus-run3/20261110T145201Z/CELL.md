# altindag-2022-mental-health-costs-lockdowns · blind · pipeline-desktop-opus-run3 · 20261110T145201Z

| | |
|---|---|
| Paper | `altindag-2022-mental-health-costs-lockdowns` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261110T145201Z |
| Date | 2026-11-10T14:52:01Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-1paper-altindag-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145201Z` |
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
| `days_outside_last_week_table3_col3` | -1.09 (0.18) | -1.07459 | 1.41% | ±0.18 (se_band) | PASS | PASS |
| `under_curfew_table3_col3` | 0.708 (0.045) | 0.706841 | 0.16% | ±0.045 (se_band) | PASS | PASS |
| `never_goes_out_table3_col3` | 0.297 (0.036) | 0.29172 | 1.78% | ±0.036 (se_band) | PASS | PASS |
| `n_obs_days_outside_table3_col3` | 1214 | 1181 | 2.72% | ±60.7 (relative) | PASS | PASS |
| `n_obs_under_curfew_table3_col3` | 1222 | 1189 | 2.70% | ±61.1 (relative) | PASS | PASS |
| `mental_distress_index_table4_col3` | 0.205 (0.094) | 0.151673 | 26.01% | ±0.094 (se_band) | PASS | PASS |
| `somatic_symptoms_index_table4_col3` | 0.175 (0.085) | 0.112917 | 35.48% | ±0.085 (se_band) | PASS | PASS |
| `nonsomatic_symptoms_index_table4_col3` | 0.158 (0.092) | 0.147615 | 6.57% | ±0.092 (se_band) | PASS | PASS |
| `sum_srq20_yes_answers_table4_col3` | 0.734 (0.44) | 0.540861 | 26.31% | ±0.44 (se_band) | PASS | PASS |
| `n_obs_mental_distress_index_table4_col3` | 1133 | 1073 | 5.30% | ±56.65 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/10 pass, which agrees with the row's 9/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 14,792 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145201Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145201Z/execution.json`
- [`output/script.R`](output/script.R) — 6,509 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145201Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,001 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145201Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,748 bytes, from `benchmark/results/artifacts/altindag-2022-mental-health-costs-lockdowns/blind/pipeline/20261110T145201Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,510 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/3763adf11763d145acf54880.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 1.5 | 10 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 3763adf11763d145acf54880: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
