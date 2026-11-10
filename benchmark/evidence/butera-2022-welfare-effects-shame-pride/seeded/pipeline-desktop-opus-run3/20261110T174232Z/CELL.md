# butera-2022-welfare-effects-shame-pride · seeded · pipeline-desktop-opus-run3 · 20261110T174232Z

| | |
|---|---|
| Paper | `butera-2022-welfare-effects-shame-pride` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261110T174232Z |
| Date | 2026-11-10T17:42:32Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-1paper-butera-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/seeded/pipeline/20261110T174232Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 13/13 |
| First scored | 13/13 (execution 1) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `public_recognition_points_prolific_table5_col1` | 105.01 (12.25) | 105.008 | 0.00% | ±2.1002 (relative) | PASS | PASS |
| `financial_incentives_points_prolific_table5_col1` | 185.74 (12.56) | 185.736 | 0.00% | ±3.7148 (relative) | PASS | PASS |
| `public_recognition_points_berkeley_table5_col2` | 134.41 (22.56) | 134.413 | 0.00% | ±2.6882 (relative) | PASS | PASS |
| `financial_incentives_points_berkeley_table5_col2` | 177.76 (22.04) | 177.756 | 0.00% | ±3.5552 (relative) | PASS | PASS |
| `public_recognition_points_bu_table5_col3` | 103.61 (45.25) | 103.611 | 0.00% | ±2.0722 (relative) | PASS | PASS |
| `financial_incentives_points_bu_table5_col3` | 118.33 (39.62) | 118.327 | 0.00% | ±2.3666 (relative) | PASS | PASS |
| `n_obs_prolific_table5_col1` | 2904 | 2904 | 0.00% | ±145.2 (relative) | PASS | PASS |
| `n_obs_berkeley_table5_col2` | 1152 | 1152 | 0.00% | ±57.6 (relative) | PASS | PASS |
| `n_obs_bu_table5_col3` | 354 | 354 | 0.00% | ±17.7 (relative) | PASS | PASS |
| `action_signaling_gamma1_berkeley_table7_panelA` | 0.3 | 0.299882 | 0.04% | ±0.006 (relative) | PASS | PASS |
| `action_signaling_rho_berkeley_table7_panelA` | 0.87 | 0.871269 | 0.15% | ±0.0174 (relative) | PASS | PASS |
| `cost_parameter_c_berkeley_table7_panelA` | 0.21 | 0.21441 | 2.10% | ±0.005 (printed_precision) | PASS | PASS |
| `predicted_financial_incentive_effect_berkeley_table7_panelC` | 2.33 | 2.33198 | 0.08% | ±0.0233 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 174,196 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/seeded/pipeline/20261110T174232Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/seeded/pipeline/20261110T174232Z/execution.json`
- [`output/script.R`](output/script.R) — 7,179 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/seeded/pipeline/20261110T174232Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/seeded/pipeline/20261110T174232Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 769 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/seeded/pipeline/20261110T174232Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,180 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/2fb1fca7a634e05e481fe7c0.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 1.2 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 2fb1fca7a634e05e481fe7c0: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 1 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
