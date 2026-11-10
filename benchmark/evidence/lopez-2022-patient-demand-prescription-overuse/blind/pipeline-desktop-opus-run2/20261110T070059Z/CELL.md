# lopez-2022-patient-demand-prescription-overuse · blind · pipeline-desktop-opus-run2 · 20261110T070059Z

| | |
|---|---|
| Paper | `lopez-2022-patient-demand-prescription-overuse` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261110T070059Z |
| Date | 2026-11-10T07:00:59Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-lopez-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T070059Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 3/12 |
| First scored | 3/12 (execution 1) |
| Final | **3/12** |
| Package files withheld | 36 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `voucher_used_patient_voucher_table3_col1` | 0.35 (0.03) | 0.297263 | 15.07% | ±0.03 (se_band) | FAIL | FAIL |
| `voucher_used_doctor_voucher_table3_col1` | 0.26 (0.024) | 0.215926 | 16.95% | ±0.024 (se_band) | FAIL | FAIL |
| `any_malaria_treatment_prescribed_patient_voucher_table3_col2` | 0.052 (0.025) | 0.043516 | 16.32% | ±0.025 (se_band) | PASS | PASS |
| `any_malaria_treatment_prescribed_doctor_voucher_table3_col2` | 0.016 (0.025) | 0.020021 | 25.13% | ±0.025 (se_band) | PASS | PASS |
| `any_malaria_treatment_purchased_patient_voucher_table3_col3` | 0.14 (0.027) | -0.069682 | 149.77% | ±0.027 (se_band) | FAIL | FAIL |
| `any_malaria_treatment_purchased_doctor_voucher_table3_col3` | 0.085 (0.025) | -0.056255 | 166.18% | ±0.025 (se_band) | FAIL | FAIL |
| `severe_malaria_treatment_prescribed_patient_voucher_table3_col4` | -0.046 (0.018) | -0.023104 | 49.77% | ±0.018 (se_band) | FAIL | FAIL |
| `severe_malaria_treatment_prescribed_doctor_voucher_table3_col4` | -0.054 (0.021) | -0.048232 | 10.68% | ±0.021 (se_band) | PASS | PASS |
| `severe_malaria_treatment_purchased_patient_voucher_table3_col5` | -0.022 (0.02) | — | — | ±0.02 (se_band) | FAIL | FAIL |
| `severe_malaria_treatment_purchased_doctor_voucher_table3_col5` | -0.05 (0.019) | — | — | ±0.019 (se_band) | FAIL | FAIL |
| `n_obs_table3_col1` | 2055 | 2770 | 34.79% | ±102.75 (relative) | FAIL | FAIL |
| `n_obs_table3_cols2_5` | 2053 | 2770 | 34.92% | ±102.65 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 3/12 pass, which agrees with the row's 3/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,685 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T070059Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T070059Z/execution.json`
- [`output/script.R`](output/script.R) — 7,916 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T070059Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T070059Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,506 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T070059Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,917 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/ff307cb78ed571188fa31d6b.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 5.9 | 10 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request ff307cb78ed571188fa31d6b: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
