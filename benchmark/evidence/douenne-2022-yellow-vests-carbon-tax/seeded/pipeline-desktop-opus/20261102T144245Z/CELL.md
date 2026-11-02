# douenne-2022-yellow-vests-carbon-tax · seeded · pipeline-desktop-opus · 20261102T144245Z

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261102T144245Z |
| Date | 2026-11-02T14:42:45Z |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z` |
| Executions | 5 |
| Refinements | 4 (1 error + 3 claim) |
| First attempt | 0/13 |
| First scored | 5/13 (execution 2) |
| Final | **5/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.2725 | 1.30% | ±0.00538 (relative) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.306202 | 0.07% | ±0.00612 (relative) | PASS | PASS |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.210407 | 1.16% | ±0.00416 (relative) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.263172 | 6.98% | ±0.00492 (relative) | FAIL | FAIL |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.076305 | 408.70% | ±0.0005 (printed_precision) | FAIL | FAIL |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.011818 | 37.80% | ±0.0005 (printed_precision) | FAIL | FAIL |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.145488 | 12.36% | ±0.00332 (relative) | FAIL | FAIL |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.140325 | 7.07% | ±0.00302 (relative) | FAIL | FAIL |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.238755 | 198.44% | ±0.0016 (relative) | FAIL | FAIL |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.149585 | 2.23% | ±0.00306 (relative) | FAIL | FAIL |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±7.57 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.536192 | 0.41% | ±0.01068 (relative) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.45953 | 10.46% | ±0.00832 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 5/13 pass, which agrees with the row's 5/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 209,674 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 13,139 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 23,187 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 25,478 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 26,519 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 378 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 10,911 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 378 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 774 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 12,469 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 959 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 423 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 709 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 13,460 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 915 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 781 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/attempt-3/stdout.txt`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 713 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 13,784 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 914 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 782 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/attempt-4/stdout.txt`
- [`output/script.R`](output/script.R) — 13,760 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 915 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 781 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T144245Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,912 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/a05df3ec25f42e1bbc51042a.json`
- [`output/answer-2.md`](output/answer-2.md) — 12,470 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/af4124fa7a19fa814d861232.json`
- [`output/answer-3.md`](output/answer-3.md) — 13,461 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/ef8c6f86c160ffe34499e4a7.json`
- [`output/answer-4.md`](output/answer-4.md) — 13,785 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/3ec439f5985640828c75ce89.json`
- [`output/answer-5.md`](output/answer-5.md) — 13,761 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/91a1fccee42dcef36c844eee.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request a05df3ec25f42e1bbc51042a: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request af4124fa7a19fa814d861232: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus (request ef8c6f86c160ffe34499e4a7: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus (request 3ec439f5985640828c75ce89: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus (request 91a1fccee42dcef36c844eee: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 8 model calls; 5 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
