# douenne-2022-yellow-vests-carbon-tax · independent · pipeline-desktop-opus · 20261102T143152Z

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261102T143152Z |
| Date | 2026-11-02T14:31:52Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T143152Z` |
| Executions | 3 |
| Refinements | 2 (1 error + 1 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 2) |
| Final | **13/13** |
| Package files withheld | 39 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.277646 | 3.21% | ±0.058 (se_band) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.315627 | 3.15% | ±0.066 (se_band) | PASS | FAIL |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.214805 | 3.27% | ±0.035 (se_band) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.239497 | 2.64% | ±0.064 (se_band) | PASS | PASS |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | -0.022107 | 247.38% | ±0.087 (se_band) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.039742 | 109.17% | ±0.058 (se_band) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.169262 | 1.97% | ±0.079 (se_band) | PASS | PASS |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.169896 | 12.51% | ±0.069 (se_band) | PASS | PASS |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.115998 | 45.00% | ±0.079 (se_band) | PASS | PASS |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.167045 | 9.18% | ±0.045 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±37.85 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.534976 | 0.18% | ±0.132 (se_band) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.477062 | 14.68% | ±0.168 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Table 4 col. 1 drops effectiveness/progressivity belief controls (control list not given in provided text)

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 23,668 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T143152Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 13,630 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T143152Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 22,571 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T143152Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 276 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T143152Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 11,492 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T143152Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 276 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T143152Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T143152Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 116 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T143152Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 13,186 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T143152Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T143152Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 782 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T143152Z/attempt-2/stdout.txt`
- [`output/script.R`](output/script.R) — 13,627 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T143152Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T143152Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 900 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T143152Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 11,493 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/d24607cad88e7a1be6b21b69.json`
- [`output/answer-2.md`](output/answer-2.md) — 13,187 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/c5e34e1f942f91ee2370b1ca.json`
- [`output/answer-3.md`](output/answer-3.md) — 13,628 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/2c9e2b53565cca9fdf2f64e0.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request d24607cad88e7a1be6b21b69: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request c5e34e1f942f91ee2370b1ca: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus (request 2c9e2b53565cca9fdf2f64e0: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
