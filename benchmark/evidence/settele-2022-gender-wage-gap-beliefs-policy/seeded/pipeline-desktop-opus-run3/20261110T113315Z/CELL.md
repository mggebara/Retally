# settele-2022-gender-wage-gap-beliefs-policy · seeded · pipeline-desktop-opus-run3 · 20261110T113315Z

| | |
|---|---|
| Paper | `settele-2022-gender-wage-gap-beliefs-policy` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261110T113315Z |
| Date | 2026-11-10T11:33:15Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-1paper-settele-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T113315Z` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 9/13 |
| First scored | 9/13 (execution 1) |
| Final | **9/13** |
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
| `first_stage_posterior_raw_t74_table5_panelA_col1` | -12.955 (0.594) | -12.4596 | 3.82% | ±0.2591 (relative) | FAIL | FAIL |
| `first_stage_posterior_z_t74_table5_panelA_col2` | -0.658 (0.03) | -0.666491 | 1.29% | ±0.01316 (relative) | PASS | PASS |
| `perception_index_t74_table5_panelA_col6` | 0.417 (0.032) | 0.41705 | 0.01% | ±0.00834 (relative) | PASS | PASS |
| `iv_affirmative_action_posterior_table5_panelC_col2` | -0.171 (0.053) | -0.136642 | 20.09% | ±0.00342 (relative) | FAIL | FAIL |
| `iv_equal_pay_legislation_posterior_table5_panelC_col3` | -0.177 (0.053) | -0.224897 | 27.06% | ±0.00354 (relative) | FAIL | FAIL |
| `iv_policy_demand_index_posterior_table5_panelC_col7` | -0.087 (0.038) | -0.111905 | 28.63% | ±0.00174 (relative) | FAIL | FAIL |
| `followup_perception_index_t74_table6_panelA_col7` | 0.156 (0.045) | 0.155612 | 0.25% | ±0.00312 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/13 pass, which agrees with the row's 9/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Posterior belief filled from whichever of the five posterior questions (extrayoung/extraHS/extraoccu/extrachild/extrasame) the respondent answered when the RAND4-based mapping left it missing

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 220,495 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T113315Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 24,953 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T113315Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T113315Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 427 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T113315Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 12,922 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T113315Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 396 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T113315Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,594 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T113315Z/attempt-1/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T113315Z/execution.json`
- [`output/script.R`](output/script.R) — 13,583 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T113315Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 471 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T113315Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,797 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/pipeline/20261110T113315Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 12,923 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/3284db2103a2515204ba2839.json`
- [`output/answer-2.md`](output/answer-2.md) — 13,584 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/3d403ca93b58ecbb266be1c5.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 2.2 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 3284db2103a2515204ba2839: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request 3d403ca93b58ecbb266be1c5: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 2 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
