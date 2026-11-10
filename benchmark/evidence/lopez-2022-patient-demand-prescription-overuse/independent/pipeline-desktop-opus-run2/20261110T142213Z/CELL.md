# lopez-2022-patient-demand-prescription-overuse · independent · pipeline-desktop-opus-run2 · 20261110T142213Z

| | |
|---|---|
| Paper | `lopez-2022-patient-demand-prescription-overuse` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261110T142213Z |
| Date | 2026-11-10T14:22:13Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-lopez-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 2/12 |
| First scored | 2/12 (execution 1) |
| Final | **12/12** |
| Package files withheld | 36 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `voucher_used_patient_voucher_table3_col1` | 0.35 (0.03) | 0.322293 | 7.92% | ±0.03 (se_band) | PASS | FAIL |
| `voucher_used_doctor_voucher_table3_col1` | 0.26 (0.024) | 0.25979 | 0.08% | ±0.024 (se_band) | PASS | FAIL |
| `any_malaria_treatment_prescribed_patient_voucher_table3_col2` | 0.052 (0.025) | 0.0483511 | 7.02% | ±0.025 (se_band) | PASS | FAIL |
| `any_malaria_treatment_prescribed_doctor_voucher_table3_col2` | 0.016 (0.025) | 0.0358746 | 124.22% | ±0.025 (se_band) | PASS | PASS |
| `any_malaria_treatment_purchased_patient_voucher_table3_col3` | 0.14 (0.027) | 0.142837 | 2.03% | ±0.027 (se_band) | PASS | FAIL |
| `any_malaria_treatment_purchased_doctor_voucher_table3_col3` | 0.085 (0.025) | 0.105211 | 23.78% | ±0.025 (se_band) | PASS | FAIL |
| `severe_malaria_treatment_prescribed_patient_voucher_table3_col4` | -0.046 (0.018) | -0.0400887 | 12.85% | ±0.018 (se_band) | PASS | FAIL |
| `severe_malaria_treatment_prescribed_doctor_voucher_table3_col4` | -0.054 (0.021) | -0.0642778 | 19.03% | ±0.021 (se_band) | PASS | PASS |
| `severe_malaria_treatment_purchased_patient_voucher_table3_col5` | -0.022 (0.02) | -0.016029 | 27.14% | ±0.02 (se_band) | PASS | FAIL |
| `severe_malaria_treatment_purchased_doctor_voucher_table3_col5` | -0.05 (0.019) | -0.0574651 | 14.93% | ±0.019 (se_band) | PASS | FAIL |
| `n_obs_table3_col1` | 2055 | 2055 | 0.00% | ±102.75 (relative) | PASS | FAIL |
| `n_obs_table3_cols2_5` | 2053 | 2055 | 0.10% | ±102.65 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Any-antimalarial outcome constructed as simple-or-severe treatment because no single any-antimalarial variable was identified
- (DEVIATION: line) Any-antimalarial-prescribed coded from RXisantimal* (0 if no prescribed drug is an antimalarial) where the simple/severe prescription flags were both missing but the prescription record was observed

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 17,815 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 19,848 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 21,356 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 22,998 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 1,118 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 7,927 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 1,080 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 496 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 465 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 9,727 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 543 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 814 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 72 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 10,733 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 990 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 941 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/attempt-3/stdout.txt`
- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/execution.json`
- [`output/script.R`](output/script.R) — 11,718 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,050 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,151 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/independent/pipeline/20261110T142213Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,928 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/e69eb6127da73cb8cc46db73.json`
- [`output/answer-2.md`](output/answer-2.md) — 9,728 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/8f35df6e44c176a80e76fefa.json`
- [`output/answer-3.md`](output/answer-3.md) — 10,734 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/68ade05c5470cfe15bff4065.json`
- [`output/answer-4.md`](output/answer-4.md) — 11,719 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/11145521cb866aeeff615f77.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 8 |
| attempt-2 | claim | 0 | — | — | 12 |
| attempt-3 | claim | 0 | — | — | 12 |
| final | final | 0 | no | 5.4 | 12 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request e69eb6127da73cb8cc46db73: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request 8f35df6e44c176a80e76fefa: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run2 (request 68ade05c5470cfe15bff4065: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run2 (request 11145521cb866aeeff615f77: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
