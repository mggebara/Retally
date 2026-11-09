# douenne-2022-yellow-vests-carbon-tax · blind · pipeline-desktop-opus · 20261102T142733Z

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261102T142733Z |
| Date | 2026-11-02T14:27:33Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T142733Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 2) |
| Final | **12/13** |
| Package files withheld | 39 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.2778 | 3.27% | ±0.058 (se_band) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.300593 | 1.77% | ±0.066 (se_band) | PASS | PASS |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.222766 | 7.10% | ±0.035 (se_band) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.237154 | 3.60% | ±0.064 (se_band) | PASS | PASS |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.0427458 | 184.97% | ±0.087 (se_band) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.0247056 | 30.03% | ±0.058 (se_band) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.155586 | 6.27% | ±0.079 (se_band) | PASS | PASS |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.160689 | 6.42% | ±0.069 (se_band) | PASS | PASS |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.094744 | 18.43% | ±0.079 (se_band) | PASS | PASS |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.151005 | 1.30% | ±0.045 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±37.85 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.534976 | 0.18% | ±0.132 (se_band) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.177377 | 57.36% | ±0.168 (se_band) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 25,517 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T142733Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 25,527 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T142733Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 8,312 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T142733Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 15,353 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T142733Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 8,312 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T142733Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T142733Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 16,624 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T142733Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 8,635 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T142733Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 33,654 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/blind/pipeline/20261102T142733Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 15,354 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/bea48f6238f259d3d17f2b66.json`
- [`output/answer-2.md`](output/answer-2.md) — 16,625 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/c21660165e2046f4e1af908c.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request bea48f6238f259d3d17f2b66: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request c21660165e2046f4e1af908c: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
