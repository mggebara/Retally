# lopez-2022-patient-demand-prescription-overuse · blind · pipeline-desktop-opus · 20261110T064634Z

| | |
|---|---|
| Paper | `lopez-2022-patient-demand-prescription-overuse` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261110T064634Z |
| Date | 2026-11-10T06:46:34Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-lopez-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T064634Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 0/12 (execution 2) |
| Final | **0/12** |
| Package files withheld | 36 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `voucher_used_patient_voucher_table3_col1` | 0.35 (0.03) | 0.290058 | 17.13% | ±0.03 (se_band) | FAIL | FAIL |
| `voucher_used_doctor_voucher_table3_col1` | 0.26 (0.024) | 0.209419 | 19.45% | ±0.024 (se_band) | FAIL | FAIL |
| `any_malaria_treatment_prescribed_patient_voucher_table3_col2` | 0.052 (0.025) | — | — | ±0.025 (se_band) | FAIL | FAIL |
| `any_malaria_treatment_prescribed_doctor_voucher_table3_col2` | 0.016 (0.025) | — | — | ±0.025 (se_band) | FAIL | FAIL |
| `any_malaria_treatment_purchased_patient_voucher_table3_col3` | 0.14 (0.027) | — | — | ±0.027 (se_band) | FAIL | FAIL |
| `any_malaria_treatment_purchased_doctor_voucher_table3_col3` | 0.085 (0.025) | — | — | ±0.025 (se_band) | FAIL | FAIL |
| `severe_malaria_treatment_prescribed_patient_voucher_table3_col4` | -0.046 (0.018) | — | — | ±0.018 (se_band) | FAIL | FAIL |
| `severe_malaria_treatment_prescribed_doctor_voucher_table3_col4` | -0.054 (0.021) | — | — | ±0.021 (se_band) | FAIL | FAIL |
| `severe_malaria_treatment_purchased_patient_voucher_table3_col5` | -0.022 (0.02) | — | — | ±0.02 (se_band) | FAIL | FAIL |
| `severe_malaria_treatment_purchased_doctor_voucher_table3_col5` | -0.05 (0.019) | — | — | ±0.019 (se_band) | FAIL | FAIL |
| `n_obs_table3_col1` | 2055 | 2753 | 33.97% | ±102.75 (relative) | FAIL | FAIL |
| `n_obs_table3_cols2_5` | 2053 | — | — | ±102.65 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 0/12 pass, which agrees with the row's 0/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,685 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T064634Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 13,452 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T064634Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T064634Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 141 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T064634Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 11,209 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T064634Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 141 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T064634Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 163 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T064634Z/attempt-1/stdout.txt`
- [`output/execution.json`](output/execution.json) — 112 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T064634Z/execution.json`
- [`output/script.R`](output/script.R) — 11,408 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T064634Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T064634Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,489 bytes, from `benchmark/results/artifacts/lopez-2022-patient-demand-prescription-overuse/blind/pipeline/20261110T064634Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 11,210 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/ff307cb78ed571188fa31d6b.json`
- [`output/answer-2.md`](output/answer-2.md) — 11,409 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/09dd61dd91c9b4b043cf4023.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 1 | — | — | 0 |
| final | final | 0 | no | 8.7 | 3 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request ff307cb78ed571188fa31d6b: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request 09dd61dd91c9b4b043cf4023: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
