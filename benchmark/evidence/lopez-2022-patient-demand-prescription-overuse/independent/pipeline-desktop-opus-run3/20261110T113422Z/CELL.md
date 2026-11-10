# lopez-2022-patient-demand-prescription-overuse · independent · pipeline-desktop-opus-run3 · 20261110T113422Z

| | |
|---|---|
| Paper | `lopez-2022-patient-demand-prescription-overuse` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261110T113422Z |
| Date | 2026-11-10T11:34:22Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-1paper-lopez-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z` |
| Executions | 3 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 2/12 |
| First scored | 2/12 (execution 1) |
| Final | **12/12** |
| Package files withheld | 36 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `voucher_used_patient_voucher_table3_col1` | 0.35 (0.03) | 0.351746 | 0.50% | ±0.03 (se_band) | PASS | FAIL |
| `voucher_used_doctor_voucher_table3_col1` | 0.26 (0.024) | 0.268245 | 3.17% | ±0.024 (se_band) | PASS | FAIL |
| `any_malaria_treatment_prescribed_patient_voucher_table3_col2` | 0.052 (0.025) | 0.0666537 | 28.18% | ±0.025 (se_band) | PASS | FAIL |
| `any_malaria_treatment_prescribed_doctor_voucher_table3_col2` | 0.016 (0.025) | 0.0230199 | 43.87% | ±0.025 (se_band) | PASS | PASS |
| `any_malaria_treatment_purchased_patient_voucher_table3_col3` | 0.14 (0.027) | 0.152583 | 8.99% | ±0.027 (se_band) | PASS | FAIL |
| `any_malaria_treatment_purchased_doctor_voucher_table3_col3` | 0.085 (0.025) | 0.092187 | 8.46% | ±0.025 (se_band) | PASS | FAIL |
| `severe_malaria_treatment_prescribed_patient_voucher_table3_col4` | -0.046 (0.018) | -0.0329807 | 28.30% | ±0.018 (se_band) | PASS | FAIL |
| `severe_malaria_treatment_prescribed_doctor_voucher_table3_col4` | -0.054 (0.021) | -0.0577039 | 6.86% | ±0.021 (se_band) | PASS | PASS |
| `severe_malaria_treatment_purchased_patient_voucher_table3_col5` | -0.022 (0.02) | -0.0112682 | 48.78% | ±0.02 (se_band) | PASS | FAIL |
| `severe_malaria_treatment_purchased_doctor_voucher_table3_col5` | -0.05 (0.019) | -0.0514317 | 2.86% | ±0.019 (se_band) | PASS | FAIL |
| `n_obs_table3_col1` | 2055 | 2055 | 0.00% | ±102.75 (relative) | PASS | FAIL |
| `n_obs_table3_cols2_5` | 2053 | 2053 | 0.00% | ±102.65 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 17,815 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 19,878 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 24,595 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 1,127 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 7,214 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 324 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,970 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 71 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 626 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 9,613 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 3,089 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,967 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z/attempt-2/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z/execution.json`
- [`output/script.R`](output/script.R) — 6,689 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,393 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,802 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T113422Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,215 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/e69eb6127da73cb8cc46db73.json`
- [`output/answer-2.md`](output/answer-2.md) — 9,614 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/a6eb7e599d5ddd2a7cf0b292.json`
- [`output/answer-3.md`](output/answer-3.md) — 6,690 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/9c42e6196e6a899af119d4e6.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 8 |
| attempt-2 | claim | 0 | — | — | 8 |
| final | final | 0 | no | 4.4 | 12 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request e69eb6127da73cb8cc46db73: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request a6eb7e599d5ddd2a7cf0b292: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run3 (request 9c42e6196e6a899af119d4e6: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
