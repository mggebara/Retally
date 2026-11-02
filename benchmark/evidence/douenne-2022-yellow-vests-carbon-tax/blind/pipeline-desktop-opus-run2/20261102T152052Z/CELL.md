# douenne-2022-yellow-vests-carbon-tax · blind · pipeline-desktop-opus-run2 · 20261102T152052Z

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261102T152052Z |
| Date | 2026-11-02T15:20:52Z |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T152052Z` |
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
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.249718 | 7.17% | ±0.058 (se_band) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.315339 | 3.05% | ±0.066 (se_band) | PASS | PASS |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.22663 | 8.96% | ±0.035 (se_band) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.213419 | 13.24% | ±0.064 (se_band) | PASS | PASS |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.05623 | 274.87% | ±0.087 (se_band) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.031123 | 63.81% | ±0.058 (se_band) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.152539 | 8.11% | ±0.079 (se_band) | PASS | PASS |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.170266 | 12.76% | ±0.069 (se_band) | PASS | PASS |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.103587 | 29.48% | ±0.079 (se_band) | PASS | PASS |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.139418 | 8.88% | ±0.045 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±7.57 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.549435 | 2.89% | ±0.132 (se_band) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.419185 | 0.77% | ±0.168 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 25,279 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T152052Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 12,811 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T152052Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 425 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T152052Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 10,252 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T152052Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 425 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T152052Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 210 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T152052Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 11,190 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T152052Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,174 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T152052Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,477 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T152052Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,253 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/a869719069519222f6ea3b91.json`
- [`output/answer-2.md`](output/answer-2.md) — 11,191 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/34182a6795815d9433cf5f6a.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request a869719069519222f6ea3b91: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request 34182a6795815d9433cf5f6a: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
