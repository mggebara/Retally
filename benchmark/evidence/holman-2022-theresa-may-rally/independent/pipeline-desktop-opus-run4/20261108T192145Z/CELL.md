# holman-2022-theresa-may-rally · independent · pipeline-desktop-opus-run4 · 20261108T192145Z

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261108T192145Z |
| Date | 2026-11-08T19:21:45Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 0/11 |
| First scored | 0/11 (execution 1) |
| Final | **6/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `intl_attack_table4` | 3.112 (0.875) | 2.32209 | 25.38% | ±0.875 (se_band) | PASS | FAIL |
| `intl_attack_x_woman_exec_table4` | -4.333 (1.859) | -3.82839 | 11.65% | ±1.859 (se_band) | PASS | FAIL |
| `n_obs_table4` | 4328 | 4486 | 3.65% | ±216.4 (relative) | PASS | FAIL |
| `did_attack_x_time_like_may_table2` | -0.1274 (0.0187) | -0.086144 | 32.38% | ±0.0187 (se_band) | FAIL | FAIL |
| `did_attack_like_may_table2` | 0.0178 (0.0278) | 0.007883 | 55.71% | ±0.0278 (se_band) | PASS | FAIL |
| `did_time_like_may_table2` | -0.5007 (0.0229) | -0.567732 | 13.39% | ±0.0229 (se_band) | FAIL | FAIL |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | -0.047114 | 5.96% | ±0.0044 (se_band) | PASS | FAIL |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | -0.002401 | 1100.50% | ±0.004 (se_band) | PASS | FAIL |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | 0.192954 | 8.03% | ±0.004196 (relative) | FAIL | FAIL |
| `n_obs_did_like_may_table2` | 143499 | 119903 | 16.44% | ±7174.95 (relative) | FAIL | FAIL |
| `n_obs_did_may_best_pm_table2` | 97155 | 80423 | 17.22% | ±4857.75 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 6/11 pass, which agrees with the row's 6/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Outcome for Table 4 is lag_approval as deposited (no other approval variable exists in global_approval.dta)
- (DEVIATION: line) Table 2 DiD drops respondent-waves with missing income/ideology instead of midpoint imputation, to match the reported panel Ns
- (DEVIATION: line) DiD sample restricted to panel members who answered the outcome item in wave 12 (the wave where attack assignment is observed); rectangular panel otherwise includes non-participants

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 16,146 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 19,006 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 21,641 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 20,592 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 966 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 5,904 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,657 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 736 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 6,767 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 4,297 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 447 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 6,114 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 4,009 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/attempt-3/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/execution.json`
- [`output/script.R`](output/script.R) — 6,223 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,131 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261108T192145Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,905 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/869129fa94349a233a61043c.json`
- [`output/answer-2.md`](output/answer-2.md) — 6,768 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/22d9b8263c394c0966a71a24.json`
- [`output/answer-3.md`](output/answer-3.md) — 6,115 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/bdad8c514a5f138a1dcc376d.json`
- [`output/answer-4.md`](output/answer-4.md) — 6,224 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/c5b4beec91518b752053744d.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 8 |
| attempt-2 | claim | 0 | — | — | 11 |
| attempt-3 | claim | 0 | — | — | 11 |
| final | final | 0 | no | 10.3 | 11 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request 869129fa94349a233a61043c: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run4 (request 22d9b8263c394c0966a71a24: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run4 (request bdad8c514a5f138a1dcc376d: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run4 (request c5b4beec91518b752053744d: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
