# douenne-2022-yellow-vests-carbon-tax · blind · pipeline-desktop-opus-postfix2 · 20261106T044539Z

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261106T044539Z |
| Date | 2026-11-06T04:45:39Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261106T044539Z` |
| Executions | 3 |
| Refinements | 2 (2 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 6/13 (execution 2) |
| Final | **12/13** |
| Package files withheld | 39 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.212887 | 20.86% | ±0.058 (se_band) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.333242 | 8.90% | ±0.066 (se_band) | PASS | PASS |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.187265 | 9.97% | ±0.035 (se_band) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.222897 | 9.39% | ±0.064 (se_band) | PASS | FAIL |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.110197 | 634.65% | ±0.087 (se_band) | FAIL | FAIL |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | -0.013652 | 171.85% | ±0.058 (se_band) | PASS | FAIL |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.097048 | 41.54% | ±0.079 (se_band) | PASS | FAIL |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.129313 | 14.36% | ±0.069 (se_band) | PASS | FAIL |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.10017 | 25.21% | ±0.079 (se_band) | PASS | FAIL |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.150551 | 1.60% | ±0.045 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±37.85 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.494108 | 7.47% | ±0.132 (se_band) | PASS | FAIL |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.340161 | 18.23% | ±0.168 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 34,699 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261106T044539Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 12,862 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261106T044539Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 18,769 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261106T044539Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 358 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261106T044539Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 10,564 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261106T044539Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 358 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261106T044539Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261106T044539Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 639 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261106T044539Z/attempt-2/feedback.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 500 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261106T044539Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 12,313 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261106T044539Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 1,416 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261106T044539Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,102 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261106T044539Z/attempt-2/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 505 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261106T044539Z/samples.txt`
- [`output/script.R`](output/script.R) — 15,674 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261106T044539Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,647 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261106T044539Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,420 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261106T044539Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,565 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/6e4b8288d519caafd54b4afa.json`
- [`output/answer-2.md`](output/answer-2.md) — 12,314 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/1468ddfa3e3313de1c9d9beb.json`
- [`output/answer-3.md`](output/answer-3.md) — 15,675 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/0e902bd69715ad5bf717ccd8.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request 6e4b8288d519caafd54b4afa: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix2 (request 1468ddfa3e3313de1c9d9beb: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix2 (request 0e902bd69715ad5bf717ccd8: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
