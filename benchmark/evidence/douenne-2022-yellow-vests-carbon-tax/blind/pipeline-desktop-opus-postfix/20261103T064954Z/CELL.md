# douenne-2022-yellow-vests-carbon-tax · blind · pipeline-desktop-opus-postfix · 20261103T064954Z

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T064954Z |
| Date | 2026-11-03T06:49:54Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T064954Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 2) |
| Final | **13/13** |
| Package files withheld | 39 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.272329 | 1.24% | ±0.058 (se_band) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.325668 | 6.43% | ±0.066 (se_band) | PASS | PASS |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.237676 | 14.27% | ±0.035 (se_band) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.251653 | 2.30% | ±0.064 (se_band) | PASS | PASS |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.0588457 | 292.30% | ±0.087 (se_band) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.0308413 | 62.32% | ±0.058 (se_band) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.158987 | 4.22% | ±0.079 (se_band) | PASS | PASS |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.173248 | 14.73% | ±0.069 (se_band) | PASS | PASS |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.0977111 | 22.14% | ±0.079 (se_band) | PASS | PASS |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.155816 | 1.84% | ±0.045 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±37.85 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.46251 | 13.39% | ±0.132 (se_band) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.403865 | 2.92% | ±0.168 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 34,866 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T064954Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 14,623 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T064954Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 278 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T064954Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 12,405 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T064954Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 278 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T064954Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T064954Z/attempt-1/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 788 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T064954Z/samples.txt`
- [`output/script.R`](output/script.R) — 14,075 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T064954Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 478 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T064954Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,732 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261103T064954Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 12,406 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/57d6e26ad43c1e999dd93efa.json`
- [`output/answer-2.md`](output/answer-2.md) — 14,076 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/07ff806d4f14572b3797e2f0.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request 57d6e26ad43c1e999dd93efa: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix (request 07ff806d4f14572b3797e2f0: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
