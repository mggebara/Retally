# lopez-2022-patient-demand-prescription-overuse · seeded · pipeline-desktop-opus-run3 · 20261110T113744Z

| | |
|---|---|
| Paper | `lopez-2022-patient-demand-prescription-overuse` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261110T113744Z |
| Date | 2026-11-10T11:37:44Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-1paper-lopez-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z` |
| Executions | 3 |
| Refinements | 2 (1 error + 1 claim) |
| First attempt | 0/12 |
| First scored | 4/12 (execution 2) |
| Final | **12/12** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `voucher_used_patient_voucher_table3_col1` | 0.35 (0.03) | 0.346459 | 1.01% | ±0.007 (relative) | PASS | PASS |
| `voucher_used_doctor_voucher_table3_col1` | 0.26 (0.024) | 0.264222 | 1.62% | ±0.0052 (relative) | PASS | FAIL |
| `any_malaria_treatment_prescribed_patient_voucher_table3_col2` | 0.052 (0.025) | 0.052492 | 0.95% | ±0.00104 (relative) | PASS | FAIL |
| `any_malaria_treatment_prescribed_doctor_voucher_table3_col2` | 0.016 (0.025) | 0.016232 | 1.45% | ±0.0005 (printed_precision) | PASS | FAIL |
| `any_malaria_treatment_purchased_patient_voucher_table3_col3` | 0.14 (0.027) | 0.14091 | 0.65% | ±0.005 (printed_precision) | PASS | FAIL |
| `any_malaria_treatment_purchased_doctor_voucher_table3_col3` | 0.085 (0.025) | 0.08549 | 0.58% | ±0.0017 (relative) | PASS | PASS |
| `severe_malaria_treatment_prescribed_patient_voucher_table3_col4` | -0.046 (0.018) | -0.045509 | 1.07% | ±0.00092 (relative) | PASS | FAIL |
| `severe_malaria_treatment_prescribed_doctor_voucher_table3_col4` | -0.054 (0.021) | -0.053749 | 0.46% | ±0.00108 (relative) | PASS | FAIL |
| `severe_malaria_treatment_purchased_patient_voucher_table3_col5` | -0.022 (0.02) | -0.02189 | 0.50% | ±0.0005 (printed_precision) | PASS | FAIL |
| `severe_malaria_treatment_purchased_doctor_voucher_table3_col5` | -0.05 (0.019) | -0.050268 | 0.54% | ±0.001 (relative) | PASS | FAIL |
| `n_obs_table3_col1` | 2055 | 2055 | 0.00% | ±102.75 (relative) | PASS | PASS |
| `n_obs_table3_cols2_5` | 2053 | 2053 | 0.00% | ±102.65 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 188,017 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 9,043 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 28,245 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 138 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 6,879 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 138 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 99 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 935 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 11,343 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 85 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 9,381 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z/attempt-2/stdout.txt`
- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z/execution.json`
- [`output/script.R`](output/script.R) — 11,964 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 85 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 9,435 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/seeded/pipeline/20261110T113744Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,880 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/36b19160f08e174e63d1b627.json`
- [`output/answer-2.md`](output/answer-2.md) — 11,344 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/13aed2cd88ce3f6027bc5825.json`
- [`output/answer-3.md`](output/answer-3.md) — 11,965 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/37449000150a7f3c1fc33a22.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 1 | — | — | 0 |
| attempt-2 | claim | 0 | — | — | 12 |
| final | final | 0 | no | 8.6 | 12 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 36b19160f08e174e63d1b627: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request 13aed2cd88ce3f6027bc5825: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run3 (request 37449000150a7f3c1fc33a22: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 3 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
