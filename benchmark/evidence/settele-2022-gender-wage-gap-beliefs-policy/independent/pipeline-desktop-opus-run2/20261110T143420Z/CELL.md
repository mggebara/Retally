# settele-2022-gender-wage-gap-beliefs-policy · independent · pipeline-desktop-opus-run2 · 20261110T143420Z

| | |
|---|---|
| Paper | `settele-2022-gender-wage-gap-beliefs-policy` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261110T143420Z |
| Date | 2026-11-10T14:34:20Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-settele-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 0/13 |
| First scored | 0/13 (execution 1) |
| Final | **12/13** |
| Package files withheld | 34 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `perception_index_democrat_table3_panelA_col4` | 0.691 (0.066) | 0.680825 | 1.47% | ±0.066 (se_band) | PASS | FAIL |
| `perception_index_female_table3_panelA_col4` | 0.181 (0.057) | 0.18818 | 3.97% | ±0.057 (se_band) | PASS | FAIL |
| `perception_index_prior_table3_panelB_col4` | -0.729 (0.065) | -0.719001 | 1.37% | ±0.065 (se_band) | PASS | FAIL |
| `n_obs_table3` | 921 | 921 | 0.00% | ±46.05 (relative) | PASS | FAIL |
| `policy_demand_index_democrat_table4_panelA_col7` | 0.669 (0.051) | 0.673818 | 0.72% | ±0.051 (se_band) | PASS | FAIL |
| `policy_demand_index_prior_table4_panelB_col7` | -0.302 (0.054) | -0.300286 | 0.57% | ±0.054 (se_band) | PASS | FAIL |
| `first_stage_posterior_raw_t74_table5_panelA_col1` | -12.955 (0.594) | -13.0113 | 0.43% | ±0.594 (se_band) | PASS | FAIL |
| `first_stage_posterior_z_t74_table5_panelA_col2` | -0.658 (0.03) | -0.605009 | 8.05% | ±0.03 (se_band) | FAIL | FAIL |
| `perception_index_t74_table5_panelA_col6` | 0.417 (0.032) | 0.416681 | 0.08% | ±0.032 (se_band) | PASS | FAIL |
| `iv_affirmative_action_posterior_table5_panelC_col2` | -0.171 (0.053) | -0.189775 | 10.98% | ±0.053 (se_band) | PASS | FAIL |
| `iv_equal_pay_legislation_posterior_table5_panelC_col3` | -0.177 (0.053) | -0.20459 | 15.59% | ±0.053 (se_band) | PASS | FAIL |
| `iv_policy_demand_index_posterior_table5_panelC_col7` | -0.087 (0.038) | -0.096878 | 11.35% | ±0.038 (se_band) | PASS | FAIL |
| `followup_perception_index_t74_table6_panelA_col7` | 0.156 (0.045) | 0.130226 | 16.52% | ±0.045 (se_band) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Survey probability weights not present in raw files; regressions are unweighted
- (DEVIATION: line) Raw main-survey demographic answer codes (gender, party, education, children, income bracket) carry no value labels; they were decoded by matching respondents to the follow-up files' coded dummies (female, democrat/indep/otherpol, associatemore, anychildren, loghhinc)
- (DEVIATION: line) Main-survey summary indices (perception, policy demand) are the Anderson (2008) inverse-covariance weighted mean of control-standardized outcomes, not re-standardized to unit control-group SD (paper's exact index normalization not stated in the summary)
- (DEVIATION: line) Posterior beliefs expressed in SD units using the pure-control-group SD of beliefs (prior belief SD), since posteriors refer to different randomly assigned wage statistics

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 19,286 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 37,148 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 46,698 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 53,154 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 1,387 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 20,986 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 28,211 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 29 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 784 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 25,122 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 5,375 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 6,007 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 574 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 30,317 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 7,787 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 8,532 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/attempt-3/stdout.txt`
- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/execution.json`
- [`output/script.R`](output/script.R) — 30,976 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 7,807 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 8,861 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/pipeline/20261110T143420Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 20,987 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/4304b6085a335189f23d1703.json`
- [`output/answer-2.md`](output/answer-2.md) — 25,123 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/75b99d617e414dea9e1aa87c.json`
- [`output/answer-3.md`](output/answer-3.md) — 30,318 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/af0b2dab9a4ca0e1b237803f.json`
- [`output/answer-4.md`](output/answer-4.md) — 30,977 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/db65854f3b066fc4dfe555cc.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 1 |
| attempt-2 | claim | 0 | — | — | 10 |
| attempt-3 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 3.3 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 4304b6085a335189f23d1703: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request 75b99d617e414dea9e1aa87c: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run2 (request af0b2dab9a4ca0e1b237803f: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run2 (request db65854f3b066fc4dfe555cc: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
