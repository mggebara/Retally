# butera-2022-welfare-effects-shame-pride · blind · pipeline-desktop-opus-run2 · 20261110T174216Z

| | |
|---|---|
| Paper | `butera-2022-welfare-effects-shame-pride` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261110T174216Z |
| Date | 2026-11-10T17:42:16Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-butera-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T174216Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 7/13 (execution 2) |
| Final | **7/13** |
| Package files withheld | 16 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `public_recognition_points_prolific_table5_col1` | 105.01 (12.25) | 102.915 | 1.99% | ±12.25 (se_band) | PASS | PASS |
| `financial_incentives_points_prolific_table5_col1` | 185.74 (12.56) | 182.431 | 1.78% | ±12.56 (se_band) | PASS | PASS |
| `public_recognition_points_berkeley_table5_col2` | 134.41 (22.56) | 136.991 | 1.92% | ±22.56 (se_band) | PASS | PASS |
| `financial_incentives_points_berkeley_table5_col2` | 177.76 (22.04) | 182.894 | 2.89% | ±22.04 (se_band) | PASS | PASS |
| `public_recognition_points_bu_table5_col3` | 103.61 (45.25) | 115.018 | 11.01% | ±45.25 (se_band) | PASS | PASS |
| `financial_incentives_points_bu_table5_col3` | 118.33 (39.62) | 140.221 | 18.50% | ±39.62 (se_band) | PASS | PASS |
| `n_obs_prolific_table5_col1` | 2904 | 2964 | 2.07% | ±145.2 (relative) | PASS | PASS |
| `n_obs_berkeley_table5_col2` | 1152 | 1212 | 5.21% | ±57.6 (relative) | FAIL | FAIL |
| `n_obs_bu_table5_col3` | 354 | 525 | 48.31% | ±17.7 (relative) | FAIL | FAIL |
| `action_signaling_gamma1_berkeley_table7_panelA` | 0.3 | 0.031881 | 89.37% | ±0.006 (relative) | FAIL | FAIL |
| `action_signaling_rho_berkeley_table7_panelA` | 0.87 | -0.519237 | 159.68% | ±0.0174 (relative) | FAIL | FAIL |
| `cost_parameter_c_berkeley_table7_panelA` | 0.21 | 0.018299 | 91.29% | ±0.005 (printed_precision) | FAIL | FAIL |
| `predicted_financial_incentive_effect_berkeley_table7_panelC` | 2.33 | 27.3243 | 1072.72% | ±0.0233 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/13 pass, which agrees with the row's 7/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,312 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T174216Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 18,022 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T174216Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T174216Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 135 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T174216Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 9,918 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T174216Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 135 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T174216Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 9,037 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T174216Z/attempt-1/stdout.txt`
- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T174216Z/execution.json`
- [`output/script.R`](output/script.R) — 11,053 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T174216Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T174216Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 12,593 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T174216Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 9,919 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/b55ebb7dabbea3d6c0c9d982.json`
- [`output/answer-2.md`](output/answer-2.md) — 11,054 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/5518029cd25405a416536147.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 1 | — | — | 0 |
| final | final | 0 | no | 1.8 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request b55ebb7dabbea3d6c0c9d982: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request 5518029cd25405a416536147: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
