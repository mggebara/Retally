# settele-2022-gender-wage-gap-beliefs-policy · seeded · pipeline-desktop-opus-run2 · 20261110T112930Z

| | |
|---|---|
| Paper | `settele-2022-gender-wage-gap-beliefs-policy` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261110T112930Z |
| Date | 2026-11-10T11:29:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-settele-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T112930Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 13/13 |
| First scored | 13/13 (execution 1) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `perception_index_democrat_table3_panelA_col4` | 0.691 (0.066) | 0.690988 | 0.00% | ±0.01382 (relative) | PASS | PASS |
| `perception_index_female_table3_panelA_col4` | 0.181 (0.057) | 0.181404 | 0.22% | ±0.00362 (relative) | PASS | PASS |
| `perception_index_prior_table3_panelB_col4` | -0.729 (0.065) | -0.72936 | 0.05% | ±0.01458 (relative) | PASS | PASS |
| `n_obs_table3` | 921 | 921 | 0.00% | ±46.05 (relative) | PASS | PASS |
| `policy_demand_index_democrat_table4_panelA_col7` | 0.669 (0.051) | 0.669333 | 0.05% | ±0.01338 (relative) | PASS | PASS |
| `policy_demand_index_prior_table4_panelB_col7` | -0.302 (0.054) | -0.301538 | 0.15% | ±0.00604 (relative) | PASS | PASS |
| `first_stage_posterior_raw_t74_table5_panelA_col1` | -12.955 (0.594) | -12.9502 | 0.04% | ±0.2591 (relative) | PASS | PASS |
| `first_stage_posterior_z_t74_table5_panelA_col2` | -0.658 (0.03) | -0.658248 | 0.04% | ±0.01316 (relative) | PASS | PASS |
| `perception_index_t74_table5_panelA_col6` | 0.417 (0.032) | 0.41705 | 0.01% | ±0.00834 (relative) | PASS | PASS |
| `iv_affirmative_action_posterior_table5_panelC_col2` | -0.171 (0.053) | -0.171035 | 0.02% | ±0.00342 (relative) | PASS | PASS |
| `iv_equal_pay_legislation_posterior_table5_panelC_col3` | -0.177 (0.053) | -0.176886 | 0.06% | ±0.00354 (relative) | PASS | PASS |
| `iv_policy_demand_index_posterior_table5_panelC_col7` | -0.087 (0.038) | -0.086531 | 0.54% | ±0.00174 (relative) | PASS | PASS |
| `followup_perception_index_t74_table6_panelA_col7` | 0.156 (0.045) | 0.155612 | 0.25% | ±0.00312 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 220,495 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T112930Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T112930Z/execution.json`
- [`output/script.R`](output/script.R) — 13,113 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T112930Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 547 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T112930Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 8,926 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T112930Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 13,114 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/3284db2103a2515204ba2839.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 2.2 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 3284db2103a2515204ba2839: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 1 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
