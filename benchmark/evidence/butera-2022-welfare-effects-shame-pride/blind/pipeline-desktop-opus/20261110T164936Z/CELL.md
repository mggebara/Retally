# butera-2022-welfare-effects-shame-pride · blind · pipeline-desktop-opus · 20261110T164936Z

| | |
|---|---|
| Paper | `butera-2022-welfare-effects-shame-pride` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261110T164936Z |
| Date | 2026-11-10T16:49:36Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-butera-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T164936Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 8/13 (execution 2) |
| Final | **8/13** |
| Package files withheld | 16 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `public_recognition_points_prolific_table5_col1` | 105.01 (12.25) | 103.407 | 1.53% | ±12.25 (se_band) | PASS | PASS |
| `financial_incentives_points_prolific_table5_col1` | 185.74 (12.56) | 182.143 | 1.94% | ±12.56 (se_band) | PASS | PASS |
| `public_recognition_points_berkeley_table5_col2` | 134.41 (22.56) | 135.004 | 0.44% | ±22.56 (se_band) | PASS | PASS |
| `financial_incentives_points_berkeley_table5_col2` | 177.76 (22.04) | 181.556 | 2.14% | ±22.04 (se_band) | PASS | PASS |
| `public_recognition_points_bu_table5_col3` | 103.61 (45.25) | 114.182 | 10.20% | ±45.25 (se_band) | PASS | PASS |
| `financial_incentives_points_bu_table5_col3` | 118.33 (39.62) | 140.3 | 18.57% | ±39.62 (se_band) | PASS | PASS |
| `n_obs_prolific_table5_col1` | 2904 | 2946 | 1.45% | ±145.2 (relative) | PASS | PASS |
| `n_obs_berkeley_table5_col2` | 1152 | 1176 | 2.08% | ±57.6 (relative) | PASS | PASS |
| `n_obs_bu_table5_col3` | 354 | 513 | 44.92% | ±17.7 (relative) | FAIL | FAIL |
| `action_signaling_gamma1_berkeley_table7_panelA` | 0.3 | 0.031341 | 89.55% | ±0.006 (relative) | FAIL | FAIL |
| `action_signaling_rho_berkeley_table7_panelA` | 0.87 | -0.521166 | 159.90% | ±0.0174 (relative) | FAIL | FAIL |
| `cost_parameter_c_berkeley_table7_panelA` | 0.21 | 0.0186098 | 91.14% | ±0.005 (printed_precision) | FAIL | FAIL |
| `predicted_financial_incentive_effect_berkeley_table7_panelC` | 2.33 | 26.8675 | 1053.11% | ±0.0233 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/13 pass, which agrees with the row's 8/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,312 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T164936Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 17,520 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T164936Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T164936Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 363 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T164936Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 9,188 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T164936Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 363 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T164936Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,776 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T164936Z/attempt-1/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T164936Z/execution.json`
- [`output/script.R`](output/script.R) — 10,093 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T164936Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T164936Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 12,026 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/pipeline/20261110T164936Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 9,189 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/b55ebb7dabbea3d6c0c9d982.json`
- [`output/answer-2.md`](output/answer-2.md) — 10,094 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/19c844eea6a9610500e829eb.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 0 | — | — | 0 |
| final | final | 0 | no | 1.8 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request b55ebb7dabbea3d6c0c9d982: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request 19c844eea6a9610500e829eb: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
