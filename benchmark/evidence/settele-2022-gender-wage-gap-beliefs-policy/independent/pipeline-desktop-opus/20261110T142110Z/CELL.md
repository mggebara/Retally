# settele-2022-gender-wage-gap-beliefs-policy · independent · pipeline-desktop-opus · 20261110T142110Z

| | |
|---|---|
| Paper | `settele-2022-gender-wage-gap-beliefs-policy` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261110T142110Z |
| Date | 2026-11-10T14:21:10Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-settele-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z` |
| Executions | 5 |
| Refinements | 4 (1 error + 3 claim) |
| First attempt | 0/13 |
| First scored | 0/13 (execution 2) |
| Final | **2/13** |
| Package files withheld | 34 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `perception_index_democrat_table3_panelA_col4` | 0.691 (0.066) | — | — | ±0.066 (se_band) | FAIL | FAIL |
| `perception_index_female_table3_panelA_col4` | 0.181 (0.057) | — | — | ±0.057 (se_band) | FAIL | FAIL |
| `perception_index_prior_table3_panelB_col4` | -0.729 (0.065) | — | — | ±0.065 (se_band) | FAIL | FAIL |
| `n_obs_table3` | 921 | 954 | 3.58% | ±46.05 (relative) | PASS | FAIL |
| `policy_demand_index_democrat_table4_panelA_col7` | 0.669 (0.051) | — | — | ±0.051 (se_band) | FAIL | FAIL |
| `policy_demand_index_prior_table4_panelB_col7` | -0.302 (0.054) | — | — | ±0.054 (se_band) | FAIL | FAIL |
| `first_stage_posterior_raw_t74_table5_panelA_col1` | -12.955 (0.594) | — | — | ±0.594 (se_band) | FAIL | FAIL |
| `first_stage_posterior_z_t74_table5_panelA_col2` | -0.658 (0.03) | — | — | ±0.03 (se_band) | FAIL | FAIL |
| `perception_index_t74_table5_panelA_col6` | 0.417 (0.032) | — | — | ±0.032 (se_band) | FAIL | FAIL |
| `iv_affirmative_action_posterior_table5_panelC_col2` | -0.171 (0.053) | — | — | ±0.053 (se_band) | FAIL | FAIL |
| `iv_equal_pay_legislation_posterior_table5_panelC_col3` | -0.177 (0.053) | — | — | ±0.053 (se_band) | FAIL | FAIL |
| `iv_policy_demand_index_posterior_table5_panelC_col7` | -0.087 (0.038) | — | — | ±0.038 (se_band) | FAIL | FAIL |
| `followup_perception_index_t74_table6_panelA_col7` | 0.156 (0.045) | 0.131379 | 15.78% | ±0.045 (se_band) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 2/13 pass, which agrees with the row's 2/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 19,286 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 40,928 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 46,485 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 50,516 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 57,558 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 14,167 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 24,892 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 14,167 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 71 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 1,392 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 30,111 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 27,544 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 155 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 71 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 1,275 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 34,280 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 41,287 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 155 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-3/stdout.txt`
- [`output/attempt-4/execution.json`](output/attempt-4/execution.json) — 71 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-4/execution.json`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 1,214 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 39,453 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 45,421 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 2,005 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/attempt-4/stdout.txt`
- [`output/execution.json`](output/execution.json) — 112 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/execution.json`
- [`output/script.R`](output/script.R) — 44,401 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 48,113 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,960 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T142110Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 24,893 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/4304b6085a335189f23d1703.json`
- [`output/answer-2.md`](output/answer-2.md) — 30,112 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/5ce0348f3abb2ad34982c4ad.json`
- [`output/answer-3.md`](output/answer-3.md) — 34,281 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/682f65b10e7419f9fa4595c7.json`
- [`output/answer-4.md`](output/answer-4.md) — 39,454 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/8a22edad434b9bc4b39d8089.json`
- [`output/answer-5.md`](output/answer-5.md) — 44,402 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/b4ff3adf9a426167d5e8c63a.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 1 | — | — | 0 |
| attempt-2 | claim | 0 | — | — | 1 |
| attempt-3 | claim | 0 | — | — | 1 |
| attempt-4 | claim | 0 | — | — | 2 |
| final | final | 0 | no | 2.7 | 2 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 4304b6085a335189f23d1703: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request 5ce0348f3abb2ad34982c4ad: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus (request 682f65b10e7419f9fa4595c7: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus (request 8a22edad434b9bc4b39d8089: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus (request b4ff3adf9a426167d5e8c63a: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 5 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
