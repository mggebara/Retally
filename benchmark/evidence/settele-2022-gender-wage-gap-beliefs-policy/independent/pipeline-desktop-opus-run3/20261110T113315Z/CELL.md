# settele-2022-gender-wage-gap-beliefs-policy · independent · pipeline-desktop-opus-run3 · 20261110T113315Z

| | |
|---|---|
| Paper | `settele-2022-gender-wage-gap-beliefs-policy` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261110T113315Z |
| Date | 2026-11-10T11:33:15Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-1paper-settele-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T113315Z` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 1/13 |
| First scored | 1/13 (execution 1) |
| Final | **1/13** |
| Package files withheld | 34 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `perception_index_democrat_table3_panelA_col4` | 0.691 (0.066) | — | — | ±0.066 (se_band) | FAIL | FAIL |
| `perception_index_female_table3_panelA_col4` | 0.181 (0.057) | — | — | ±0.057 (se_band) | FAIL | FAIL |
| `perception_index_prior_table3_panelB_col4` | -0.729 (0.065) | — | — | ±0.065 (se_band) | FAIL | FAIL |
| `n_obs_table3` | 921 | 0 | 100.00% | ±46.05 (relative) | FAIL | FAIL |
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

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 19,286 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T113315Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 40,102 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T113315Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 66 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T113315Z/attempt-1/execution.json`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 30,598 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T113315Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 113 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T113315Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 41,838 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T113315Z/attempt-1/stdout.txt`
- [`output/execution.json`](output/execution.json) — 112 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T113315Z/execution.json`
- [`output/script.R`](output/script.R) — 24,099 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T113315Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T113315Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 44,683 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T113315Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 24,100 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/4304b6085a335189f23d1703.json`
- [`output/answer-2.md`](output/answer-2.md) — 30,599 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/041bd43ca4d12ef7c0b5401d.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | — | 1 | — | — | 0 |
| final | final | 0 | no | 4.4 | 2 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 4304b6085a335189f23d1703: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request 041bd43ca4d12ef7c0b5401d: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
