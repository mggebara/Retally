# douenne-2022-yellow-vests-carbon-tax · independent · pipeline-desktop-opus-postfix2 · 20261106T050743Z

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261106T050743Z |
| Date | 2026-11-06T05:07:43Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z` |
| Executions | 4 |
| Refinements | 3 (2 error + 1 claim) |
| First attempt | 0/13 |
| First scored | 3/13 (execution 2) |
| Final | **13/13** |
| Package files withheld | 39 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.26931 | 0.12% | ±0.058 (se_band) | PASS | FAIL |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.276449 | 9.66% | ±0.066 (se_band) | PASS | PASS |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.239228 | 15.01% | ±0.035 (se_band) | PASS | FAIL |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.242739 | 1.33% | ±0.064 (se_band) | PASS | FAIL |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.044118 | 194.12% | ±0.087 (se_band) | PASS | FAIL |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.038997 | 105.25% | ±0.058 (se_band) | PASS | FAIL |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.144552 | 12.92% | ±0.079 (se_band) | PASS | FAIL |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.164702 | 9.07% | ±0.069 (se_band) | PASS | FAIL |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.102577 | 28.22% | ±0.079 (se_band) | PASS | FAIL |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.160635 | 4.99% | ±0.045 (se_band) | PASS | FAIL |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±37.85 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.490185 | 8.21% | ±0.132 (se_band) | PASS | FAIL |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.395879 | 4.84% | ±0.168 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) YV supporter = (gilets_jaunes > 0) with PNR left missing (n missing=0, mean=0.341)
- (DEVIATION: line) Table 6 income-percentile window not stated; using all respondents with percentile polynomials as controls

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 35,260 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 15,713 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 20,705 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 30,640 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 289 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 16 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 13,267 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 289 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 149 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 733 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/attempt-2/feedback.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 539 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 14,682 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 702 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,285 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 227 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/attempt-3/feedback.txt`
- [`output/attempt-3/samples.txt`](output/attempt-3/samples.txt) — 567 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/attempt-3/samples.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 17,512 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 567 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 2,746 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/attempt-3/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 567 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/samples.txt`
- [`output/script.R`](output/script.R) — 18,389 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 567 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,920 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261106T050743Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 13,268 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/82f8f2fedda1d0b3c6670043.json`
- [`output/answer-2.md`](output/answer-2.md) — 14,683 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/336977d77ec042121d53b64e.json`
- [`output/answer-3.md`](output/answer-3.md) — 17,513 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/7d58240f9d276130f8e167a9.json`
- [`output/answer-4.md`](output/answer-4.md) — 18,389 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/ee99d0d51dc94b9e8b71c189.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request 82f8f2fedda1d0b3c6670043: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix2 (request 336977d77ec042121d53b64e: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix2 (request 7d58240f9d276130f8e167a9: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-postfix2 (request ee99d0d51dc94b9e8b71c189: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
