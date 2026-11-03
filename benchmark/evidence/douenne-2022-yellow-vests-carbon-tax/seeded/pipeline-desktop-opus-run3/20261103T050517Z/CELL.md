# douenne-2022-yellow-vests-carbon-tax · seeded · pipeline-desktop-opus-run3 · 20261103T050517Z

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T050517Z |
| Date | 2026-11-03T05:05:17Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261103T050517Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 2) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.268692 | 0.11% | ±0.00538 (relative) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.306132 | 0.04% | ±0.00612 (relative) | PASS | PASS |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.208177 | 0.09% | ±0.00416 (relative) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.246062 | 0.03% | ±0.00492 (relative) | PASS | PASS |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.015333 | 2.22% | ±0.0005 (printed_precision) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.019281 | 1.48% | ±0.0005 (printed_precision) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.16612 | 0.07% | ±0.00332 (relative) | PASS | PASS |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.151474 | 0.31% | ±0.00302 (relative) | PASS | PASS |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.079694 | 0.38% | ±0.0016 (relative) | PASS | PASS |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.153068 | 0.04% | ±0.00306 (relative) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±37.85 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.534048 | 0.01% | ±0.01068 (relative) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.415553 | 0.11% | ±0.00832 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 210,709 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261103T050517Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 14,793 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261103T050517Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 7,050 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261103T050517Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 5,893 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261103T050517Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 7,050 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261103T050517Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261103T050517Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 7,619 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261103T050517Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261103T050517Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 781 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261103T050517Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,903 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/6159fd440f0053c329e25dda.json`
- [`output/answer-2.md`](output/answer-2.md) — 7,620 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/d3c484324af32f58c6f46828.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 6159fd440f0053c329e25dda: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request d3c484324af32f58c6f46828: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 2 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
