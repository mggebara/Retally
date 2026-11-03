# holman-2022-theresa-may-rally · independent · pipeline-desktop-opus-run2 · 20261023T153002Z

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261023T153002Z |
| Date | 2026-10-23T15:30:02Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 3/11 |
| First scored | 3/11 (execution 1) |
| Final | **9/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `intl_attack_table4` | 3.112 (0.875) | 1.58308 | 49.13% | ±0.875 (se_band) | FAIL | FAIL |
| `intl_attack_x_woman_exec_table4` | -4.333 (1.859) | -2.14364 | 50.53% | ±1.859 (se_band) | FAIL | FAIL |
| `n_obs_table4` | 4328 | 4380 | 1.20% | ±216.4 (relative) | PASS | FAIL |
| `did_attack_x_time_like_may_table2` | -0.1274 (0.0187) | -0.114719 | 9.95% | ±0.0187 (se_band) | PASS | FAIL |
| `did_attack_like_may_table2` | 0.0178 (0.0278) | 0.0388849 | 118.45% | ±0.0278 (se_band) | PASS | PASS |
| `did_time_like_may_table2` | -0.5007 (0.0229) | -0.478198 | 4.49% | ±0.0229 (se_band) | PASS | FAIL |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | -0.0520978 | 3.99% | ±0.0044 (se_band) | PASS | FAIL |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | -0.000437208 | 118.60% | ±0.004 (se_band) | PASS | PASS |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | 0.205917 | 1.85% | ±0.004196 (relative) | PASS | FAIL |
| `n_obs_did_like_may_table2` | 143499 | 143499 | 0.00% | ±7174.95 (relative) | PASS | PASS |
| `n_obs_did_may_best_pm_table2` | 97155 | 97155 | 0.00% | ±4857.75 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/11 pass, which agrees with the row's 9/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Table 4 DV timing/attack timing/lagged-DV/consecutive-approval sample variant built from lag_approval chosen by sample size closest to 4328: dvlead0\|attlag0\|ldv\|req3
- (DEVIATION: line) Like-May DiD treatment/ideology/weight variant chosen among N-matching candidates by closeness of reported regressor coefficients: like\|treatment2\|raw\|ideo3\|none
- (DEVIATION: line) May-best-PM DiD estimated as a linear probability model (Table 2 magnitudes are on the probability scale)
- (DEVIATION: line) Best-PM DiD variant chosen among N-matching candidates by closeness of reported regressor coefficients: bpw_1v0\|treatment1\|raw\|ideo3\|none

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 17,192 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 21,604 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 24,110 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 27,147 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 726 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 7,364 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 1,002 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,128 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 797 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 8,435 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 2,821 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,406 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 436 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 10,144 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 2,561 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 2,962 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/attempt-3/stdout.txt`
- [`output/script.R`](output/script.R) — 10,818 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 3,955 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,048 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261023T153002Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,365 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/9fde7c03fe3cce93895292fe.json`
- [`output/answer-2.md`](output/answer-2.md) — 8,436 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/3a773bcbc32af3fa2cea701a.json`
- [`output/answer-3.md`](output/answer-3.md) — 10,145 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/27d4a08360c1092f693133d5.json`
- [`output/answer-4.md`](output/answer-4.md) — 10,819 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/fa99653ebab2e2c2e4c2bc59.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 9fde7c03fe3cce93895292fe: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request 3a773bcbc32af3fa2cea701a: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run2 (request 27d4a08360c1092f693133d5: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run2 (request fa99653ebab2e2c2e4c2bc59: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
