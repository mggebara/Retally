# douenne-2022-yellow-vests-carbon-tax · seeded · pipeline-desktop-opus-run2 · 20261102T191457Z

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261102T191457Z |
| Date | 2026-11-02T19:14:57Z |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z` |
| Executions | 5 |
| Refinements | 4 (1 error + 3 claim) |
| First attempt | 0/13 |
| First scored | 5/13 (execution 2) |
| Final | **6/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.2725 | 1.30% | ±0.00538 (relative) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.306202 | 0.07% | ±0.00612 (relative) | PASS | PASS |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.210407 | 1.16% | ±0.00416 (relative) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.241792 | 1.71% | ±0.00492 (relative) | PASS | FAIL |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.020758 | 38.39% | ±0.0005 (printed_precision) | FAIL | FAIL |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.033433 | 75.96% | ±0.0005 (printed_precision) | FAIL | FAIL |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.160479 | 3.33% | ±0.00332 (relative) | FAIL | FAIL |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.162162 | 7.39% | ±0.00302 (relative) | FAIL | FAIL |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.110089 | 37.61% | ±0.0016 (relative) | FAIL | FAIL |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.149585 | 2.23% | ±0.00306 (relative) | FAIL | FAIL |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±7.57 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.536192 | 0.41% | ±0.01068 (relative) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.436128 | 4.84% | ±0.00832 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 6/13 pass, which agrees with the row's 6/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Yellow Vests supporter dummy defined as "supports" or "is part of" the movement; exact definition not given in the provided text

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 210,626 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 10,652 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 21,089 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 22,467 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 23,461 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 268 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 8,534 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 268 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 794 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 9,683 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 655 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 709 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 10,243 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 810 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/attempt-3/stdout.txt`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 713 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 10,379 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 952 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/attempt-4/stdout.txt`
- [`output/script.R`](output/script.R) — 10,518 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 950 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/seeded/pipeline/20261102T191457Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,535 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/ce354bd596bd213fc891bc63.json`
- [`output/answer-2.md`](output/answer-2.md) — 9,684 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/f17fbdb3041908d68d475c3c.json`
- [`output/answer-3.md`](output/answer-3.md) — 10,244 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/fd86fa751719ddbd6b0ad543.json`
- [`output/answer-4.md`](output/answer-4.md) — 10,380 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/07028645826950e0d70c326f.json`
- [`output/answer-5.md`](output/answer-5.md) — 10,519 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/19783d74a6c83e0342bdff1b.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request ce354bd596bd213fc891bc63: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request f17fbdb3041908d68d475c3c: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run2 (request fd86fa751719ddbd6b0ad543: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run2 (request 07028645826950e0d70c326f: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus-run2 (request 19783d74a6c83e0342bdff1b: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 8 model calls; 5 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
