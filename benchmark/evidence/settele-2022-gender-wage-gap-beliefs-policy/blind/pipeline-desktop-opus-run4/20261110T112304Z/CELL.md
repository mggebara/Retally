# settele-2022-gender-wage-gap-beliefs-policy · blind · pipeline-desktop-opus-run4 · 20261110T112304Z

| | |
|---|---|
| Paper | `settele-2022-gender-wage-gap-beliefs-policy` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261110T112304Z |
| Date | 2026-11-10T11:23:04Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-1paper-settele-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/pipeline/20261110T112304Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 1/13 (execution 2) |
| Final | **1/13** |
| Package files withheld | 34 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `perception_index_democrat_table3_panelA_col4` | 0.691 (0.066) | — | — | ±0.066 (se_band) | FAIL | FAIL |
| `perception_index_female_table3_panelA_col4` | 0.181 (0.057) | — | — | ±0.057 (se_band) | FAIL | FAIL |
| `perception_index_prior_table3_panelB_col4` | -0.729 (0.065) | — | — | ±0.065 (se_band) | FAIL | FAIL |
| `n_obs_table3` | 921 | — | — | ±46.05 (relative) | FAIL | FAIL |
| `policy_demand_index_democrat_table4_panelA_col7` | 0.669 (0.051) | — | — | ±0.051 (se_band) | FAIL | FAIL |
| `policy_demand_index_prior_table4_panelB_col7` | -0.302 (0.054) | — | — | ±0.054 (se_band) | FAIL | FAIL |
| `first_stage_posterior_raw_t74_table5_panelA_col1` | -12.955 (0.594) | — | — | ±0.594 (se_band) | FAIL | FAIL |
| `first_stage_posterior_z_t74_table5_panelA_col2` | -0.658 (0.03) | — | — | ±0.03 (se_band) | FAIL | FAIL |
| `perception_index_t74_table5_panelA_col6` | 0.417 (0.032) | — | — | ±0.032 (se_band) | FAIL | FAIL |
| `iv_affirmative_action_posterior_table5_panelC_col2` | -0.171 (0.053) | — | — | ±0.053 (se_band) | FAIL | FAIL |
| `iv_equal_pay_legislation_posterior_table5_panelC_col3` | -0.177 (0.053) | — | — | ±0.053 (se_band) | FAIL | FAIL |
| `iv_policy_demand_index_posterior_table5_panelC_col7` | -0.087 (0.038) | — | — | ±0.038 (se_band) | FAIL | FAIL |
| `followup_perception_index_t74_table6_panelA_col7` | 0.156 (0.045) | 0.130226 | 16.52% | ±0.045 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 1/13 pass, which agrees with the row's 1/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 19,664 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/pipeline/20261110T112304Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 30,734 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/pipeline/20261110T112304Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/pipeline/20261110T112304Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 11,449 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/pipeline/20261110T112304Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 17,324 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/pipeline/20261110T112304Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 11,449 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/pipeline/20261110T112304Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 41 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/pipeline/20261110T112304Z/attempt-1/stdout.txt`
- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/pipeline/20261110T112304Z/execution.json`
- [`output/script.R`](output/script.R) — 21,971 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/pipeline/20261110T112304Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 3,771 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/pipeline/20261110T112304Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 759 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/pipeline/20261110T112304Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 17,325 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/7cc24e6abc65a01fd5e0789c.json`
- [`output/answer-2.md`](output/answer-2.md) — 21,972 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/d9b5178d2e05acfb411a18a5.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 1 | — | — | 0 |
| final | final | 0 | no | 2.1 | 1 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request 7cc24e6abc65a01fd5e0789c: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run4 (request d9b5178d2e05acfb411a18a5: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
