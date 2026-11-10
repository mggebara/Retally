# lopez-2022-patient-demand-prescription-overuse · independent · pipeline-desktop-opus · 20261110T065707Z

| | |
|---|---|
| Paper | `lopez-2022-patient-demand-prescription-overuse` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261110T065707Z |
| Date | 2026-11-10T06:57:07Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-lopez-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z` |
| Executions | 3 |
| Refinements | 2 (1 error + 1 claim) |
| First attempt | 0/12 |
| First scored | 7/12 (execution 2) |
| Final | **12/12** |
| Package files withheld | 36 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `voucher_used_patient_voucher_table3_col1` | 0.35 (0.03) | 0.351746 | 0.50% | ±0.03 (se_band) | PASS | FAIL |
| `voucher_used_doctor_voucher_table3_col1` | 0.26 (0.024) | 0.268245 | 3.17% | ±0.024 (se_band) | PASS | FAIL |
| `any_malaria_treatment_prescribed_patient_voucher_table3_col2` | 0.052 (0.025) | 0.066654 | 28.18% | ±0.025 (se_band) | PASS | PASS |
| `any_malaria_treatment_prescribed_doctor_voucher_table3_col2` | 0.016 (0.025) | 0.02302 | 43.87% | ±0.025 (se_band) | PASS | PASS |
| `any_malaria_treatment_purchased_patient_voucher_table3_col3` | 0.14 (0.027) | 0.152583 | 8.99% | ±0.027 (se_band) | PASS | PASS |
| `any_malaria_treatment_purchased_doctor_voucher_table3_col3` | 0.085 (0.025) | 0.092187 | 8.46% | ±0.025 (se_band) | PASS | PASS |
| `severe_malaria_treatment_prescribed_patient_voucher_table3_col4` | -0.046 (0.018) | -0.032981 | 28.30% | ±0.018 (se_band) | PASS | FAIL |
| `severe_malaria_treatment_prescribed_doctor_voucher_table3_col4` | -0.054 (0.021) | -0.057704 | 6.86% | ±0.021 (se_band) | PASS | PASS |
| `severe_malaria_treatment_purchased_patient_voucher_table3_col5` | -0.022 (0.02) | -0.011268 | 48.78% | ±0.02 (se_band) | PASS | PASS |
| `severe_malaria_treatment_purchased_doctor_voucher_table3_col5` | -0.05 (0.019) | -0.051432 | 2.86% | ±0.019 (se_band) | PASS | PASS |
| `n_obs_table3_col1` | 2055 | 2055 | 0.00% | ±102.75 (relative) | PASS | FAIL |
| `n_obs_table3_cols2_5` | 2053 | 2053 | 0.00% | ±102.65 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Restricted to analysis sample via dropme ==0 (n=2055) to match the paper's 2,055 acutely ill patients; the exact sample flag is not named in the paper

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 17,815 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 13,070 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 21,702 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 32 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 5,640 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 5,459 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 489 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 6,227 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 5,659 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z/attempt-2/stdout.txt`
- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z/execution.json`
- [`output/script.R`](output/script.R) — 7,014 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 5,843 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T065707Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,641 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/e69eb6127da73cb8cc46db73.json`
- [`output/answer-2.md`](output/answer-2.md) — 6,228 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/68ce98650cd636140b8b4ec5.json`
- [`output/answer-3.md`](output/answer-3.md) — 7,015 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/92a332fac50576ba5eb6434d.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 0 | — | — | 0 |
| attempt-2 | claim | 0 | — | — | 12 |
| final | final | 0 | no | 6.2 | 12 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request e69eb6127da73cb8cc46db73: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request 68ce98650cd636140b8b4ec5: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus (request 92a332fac50576ba5eb6434d: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
