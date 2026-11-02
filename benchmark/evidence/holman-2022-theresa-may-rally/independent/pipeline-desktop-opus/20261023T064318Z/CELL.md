# holman-2022-theresa-may-rally · independent · pipeline-desktop-opus · 20261023T064318Z

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261023T064318Z |
| Date | 2026-10-23T06:43:18Z |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T064318Z` |
| Executions | 3 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 1/11 |
| First scored | 1/11 (execution 1) |
| Final | **3/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `intl_attack_table4` | 3.112 (0.875) | 0.890628 | 71.38% | ±0.875 (se_band) | FAIL | FAIL |
| `intl_attack_x_woman_exec_table4` | -4.333 (1.859) | -1.66283 | 61.62% | ±1.859 (se_band) | FAIL | FAIL |
| `n_obs_table4` | 4328 | 4369 | 0.95% | ±43.28 (relative) | PASS | PASS |
| `did_attack_x_time_like_may_table2` | -0.1274 (0.0187) | -0.082396 | 35.32% | ±0.0187 (se_band) | FAIL | FAIL |
| `did_attack_like_may_table2` | 0.0178 (0.0278) | -0.129012 | 824.79% | ±0.0278 (se_band) | FAIL | FAIL |
| `did_time_like_may_table2` | -0.5007 (0.0229) | -0.301854 | 39.71% | ±0.0229 (se_band) | FAIL | FAIL |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | -0.052204 | 4.20% | ±0.0044 (se_band) | PASS | FAIL |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | -0.001526 | 663.00% | ±0.004 (se_band) | PASS | FAIL |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | 0.023356 | 88.87% | ±0.004196 (relative) | FAIL | FAIL |
| `n_obs_did_like_may_table2` | 143499 | 145012 | 1.05% | ±1434.99 (relative) | FAIL | FAIL |
| `n_obs_did_may_best_pm_table2` | 97155 | 86517 | 10.95% | ±971.55 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 3/11 pass, which agrees with the row's 3/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Table 2 likeability model restricted to BES waves 1-13 (window chosen to match the paper's reported N; paper does not list waves)
- (DEVIATION: line) Table 2 best-PM model restricted to BES waves 9-12 (window chosen to match the paper's reported N; paper does not list waves)

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 16,146 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T064318Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 19,786 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T064318Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 22,648 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T064318Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 923 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T064318Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 8,549 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T064318Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 81 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T064318Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 495 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T064318Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 729 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T064318Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 11,162 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T064318Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 147 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T064318Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 617 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T064318Z/attempt-2/stdout.txt`
- [`output/script.R`](output/script.R) — 12,302 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T064318Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 771 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T064318Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 772 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T064318Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,559 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/5703be385b4120fe50685a90.json`
- [`output/answer-2.md`](output/answer-2.md) — 11,163 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/7064389c8a953375a2d9617f.json`
- [`output/answer-3.md`](output/answer-3.md) — 12,303 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/9d67f91d34ba60f256b194c0.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 5703be385b4120fe50685a90: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request 7064389c8a953375a2d9617f: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus (request 9d67f91d34ba60f256b194c0: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
