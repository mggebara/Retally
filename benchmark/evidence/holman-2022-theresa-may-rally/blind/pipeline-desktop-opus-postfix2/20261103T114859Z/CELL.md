# holman-2022-theresa-may-rally · blind · pipeline-desktop-opus-postfix2 · 20261103T114859Z

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261103T114859Z |
| Date | 2026-11-03T11:48:59Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T114859Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 1/11 (execution 2) |
| Final | **1/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `intl_attack_table4` | 3.112 (0.875) | 0.838427 | 73.06% | ±0.875 (se_band) | FAIL | FAIL |
| `intl_attack_x_woman_exec_table4` | -4.333 (1.859) | -1.61312 | 62.77% | ±1.859 (se_band) | FAIL | FAIL |
| `n_obs_table4` | 4328 | 4423 | 2.20% | ±216.4 (relative) | PASS | PASS |
| `did_attack_x_time_like_may_table2` | -0.1274 (0.0187) | -0.150165 | 17.87% | ±0.0187 (se_band) | FAIL | FAIL |
| `did_attack_like_may_table2` | 0.0178 (0.0278) | -0.105036 | 690.09% | ±0.0278 (se_band) | FAIL | FAIL |
| `did_time_like_may_table2` | -0.5007 (0.0229) | -0.226436 | 54.78% | ±0.0229 (se_band) | FAIL | FAIL |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | 0 | 100.00% | ±0.0044 (se_band) | FAIL | FAIL |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | 1.24923 | 624712.50% | ±0.004 (se_band) | FAIL | FAIL |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | -0 | 100.00% | ±0.004196 (relative) | FAIL | FAIL |
| `n_obs_did_like_may_table2` | 143499 | 239919 | 67.19% | ±7174.95 (relative) | FAIL | FAIL |
| `n_obs_did_may_best_pm_table2` | 97155 | 1.48139e+06 | 1424.77% | ±4857.75 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 1/11 pass, which agrees with the row's 1/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 21,658 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T114859Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 7,986 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T114859Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 154 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T114859Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 19 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T114859Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 5,805 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T114859Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 154 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T114859Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 26 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T114859Z/attempt-1/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 296 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T114859Z/samples.txt`
- [`output/script.R`](output/script.R) — 6,964 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T114859Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 338 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T114859Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 817 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T114859Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,806 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/21845d21ea822df5232c4048.json`
- [`output/answer-2.md`](output/answer-2.md) — 6,965 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/50d9846e48d21a9a5a0a59e4.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request 21845d21ea822df5232c4048: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix2 (request 50d9846e48d21a9a5a0a59e4: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
