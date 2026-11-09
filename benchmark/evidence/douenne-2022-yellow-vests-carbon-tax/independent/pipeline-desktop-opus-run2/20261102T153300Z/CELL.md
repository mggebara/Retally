# douenne-2022-yellow-vests-carbon-tax · independent · pipeline-desktop-opus-run2 · 20261102T153300Z

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261102T153300Z |
| Date | 2026-11-02T15:33:00Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T153300Z` |
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
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.285665 | 6.20% | ±0.058 (se_band) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.322152 | 5.28% | ±0.066 (se_band) | PASS | FAIL |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.232059 | 11.57% | ±0.035 (se_band) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.258513 | 5.09% | ±0.064 (se_band) | PASS | PASS |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.074335 | 395.57% | ±0.087 (se_band) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.016715 | 12.03% | ±0.058 (se_band) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.159799 | 3.74% | ±0.079 (se_band) | PASS | PASS |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.164486 | 8.93% | ±0.069 (se_band) | PASS | PASS |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.081558 | 1.95% | ±0.079 (se_band) | PASS | PASS |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.162115 | 5.96% | ±0.045 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±37.85 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.545843 | 2.22% | ±0.132 (se_band) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.373247 | 10.28% | ±0.168 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 24,620 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T153300Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 14,005 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T153300Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 24,853 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T153300Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 279 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T153300Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 9,013 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T153300Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 279 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T153300Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,784 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T153300Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 116 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T153300Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 10,304 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T153300Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T153300Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 4,996 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T153300Z/attempt-2/stdout.txt`
- [`output/script.R`](output/script.R) — 10,383 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T153300Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T153300Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 5,002 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261102T153300Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 9,014 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/d9c44f4c6358f5c517215347.json`
- [`output/answer-2.md`](output/answer-2.md) — 10,305 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/741c39c52fe767a3b51257bc.json`
- [`output/answer-3.md`](output/answer-3.md) — 10,384 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/c0944b457b40adc53dafbe55.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request d9c44f4c6358f5c517215347: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request 741c39c52fe767a3b51257bc: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run2 (request c0944b457b40adc53dafbe55: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
