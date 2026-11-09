# douenne-2022-yellow-vests-carbon-tax · blind · pipeline-desktop-opus-run3 · 20261103T050517Z

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T050517Z |
| Date | 2026-11-03T05:05:17Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T050517Z` |
| Executions | 3 |
| Refinements | 2 (2 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 4/13 (execution 2) |
| Final | **13/13** |
| Package files withheld | 39 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.284585 | 5.79% | ±0.058 (se_band) | PASS | FAIL |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.251322 | 17.87% | ±0.066 (se_band) | PASS | PASS |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.2181 | 4.86% | ±0.035 (se_band) | PASS | FAIL |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.241342 | 1.89% | ±0.064 (se_band) | PASS | FAIL |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.0086661 | 42.23% | ±0.087 (se_band) | PASS | FAIL |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.0356089 | 87.42% | ±0.058 (se_band) | PASS | FAIL |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.157138 | 5.34% | ±0.079 (se_band) | PASS | FAIL |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.166503 | 10.27% | ±0.069 (se_band) | PASS | FAIL |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.11651 | 45.64% | ±0.079 (se_band) | PASS | FAIL |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.157967 | 3.25% | ±0.045 (se_band) | PASS | FAIL |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±37.85 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.534976 | 0.18% | ±0.132 (se_band) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.406186 | 2.36% | ±0.168 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 25,057 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T050517Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 13,854 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T050517Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 18,474 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T050517Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 280 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T050517Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 11,298 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T050517Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 280 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T050517Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 346 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T050517Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 211 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T050517Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 12,584 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T050517Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 211 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T050517Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,749 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T050517Z/attempt-2/stdout.txt`
- [`output/script.R`](output/script.R) — 13,298 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T050517Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 146 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T050517Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,879 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T050517Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 11,299 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/db5f647125873d0f8a849782.json`
- [`output/answer-2.md`](output/answer-2.md) — 12,585 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/055ac36246ca2568750e5cf9.json`
- [`output/answer-3.md`](output/answer-3.md) — 13,299 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/b04d664c8f74e19b125825f3.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request db5f647125873d0f8a849782: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request 055ac36246ca2568750e5cf9: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run3 (request b04d664c8f74e19b125825f3: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
