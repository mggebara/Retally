# holman-2022-theresa-may-rally · independent · pipeline-desktop-opus-run3 · 20261103T052626Z

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T052626Z |
| Date | 2026-11-03T05:26:26Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z` |
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
| `did_attack_x_time_like_may_table2` | -0.1274 (0.0187) | -0.086341 | 32.23% | ±0.0187 (se_band) | FAIL | FAIL |
| `did_attack_like_may_table2` | 0.0178 (0.0278) | 0.008056 | 54.74% | ±0.0278 (se_band) | PASS | FAIL |
| `did_time_like_may_table2` | -0.5007 (0.0229) | -0.561663 | 12.18% | ±0.0229 (se_band) | FAIL | FAIL |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | -0.049462 | 1.27% | ±0.0044 (se_band) | PASS | FAIL |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | -0.000131 | 34.50% | ±0.004 (se_band) | PASS | FAIL |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | 0.196442 | 6.37% | ±0.004196 (relative) | FAIL | FAIL |
| `n_obs_did_like_may_table2` | 143499 | 120732 | 15.87% | ±7174.95 (relative) | FAIL | FAIL |
| `n_obs_did_may_best_pm_table2` | 97155 | 82701 | 14.88% | ±4857.75 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 6/11 pass, which agrees with the row's 6/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Table 2 DiD uses listwise deletion on income/ideology instead of midpoint recoding (midpoint recoding is described for Table 1; reported DiD Ns imply complete cases)

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 16,441 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 19,198 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 20,110 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 20,351 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 966 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 4,993 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 2,043 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,346 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 801 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 5,838 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 74 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,111 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 512 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 6,234 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 74 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 3,066 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/attempt-3/stdout.txt`
- [`output/script.R`](output/script.R) — 7,067 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 74 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,399 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T052626Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 4,994 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/188c971a6643fba4d3260496.json`
- [`output/answer-2.md`](output/answer-2.md) — 5,839 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/43b4d1a4265915fd53be6850.json`
- [`output/answer-3.md`](output/answer-3.md) — 6,235 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/811e93dce23748ffff2047db.json`
- [`output/answer-4.md`](output/answer-4.md) — 7,068 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/b9f3f0bc9662afc8e1ae008b.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 188c971a6643fba4d3260496: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request 43b4d1a4265915fd53be6850: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run3 (request 811e93dce23748ffff2047db: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run3 (request b9f3f0bc9662afc8e1ae008b: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
