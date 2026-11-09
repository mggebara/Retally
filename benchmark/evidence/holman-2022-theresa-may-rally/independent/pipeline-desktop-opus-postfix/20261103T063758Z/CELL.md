# holman-2022-theresa-may-rally · independent · pipeline-desktop-opus-postfix · 20261103T063758Z

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T063758Z |
| Date | 2026-11-03T06:37:58Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T063758Z` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 1/11 |
| First scored | 1/11 (execution 1) |
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
| `did_time_like_may_table2` | -0.5007 (0.0229) | -0.300524 | 39.98% | ±0.0229 (se_band) | FAIL | FAIL |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | 2.79118e-16 | 100.00% | ±0.0044 (se_band) | FAIL | FAIL |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | 0.14669 | 73444.78% | ±0.004 (se_band) | FAIL | FAIL |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | 1.56599e-16 | 100.00% | ±0.004196 (relative) | FAIL | FAIL |
| `n_obs_did_like_may_table2` | 143499 | 239919 | 67.19% | ±7174.95 (relative) | FAIL | FAIL |
| `n_obs_did_may_best_pm_table2` | 97155 | 1.48139e+06 | 1424.77% | ±4857.75 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 1/11 pass, which agrees with the row's 1/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Table 4 N = 4423 differs from paper 4328
- (DEVIATION: line) like May DiD N = 239919 differs from paper 143499
- (DEVIATION: line) best PM DiD N = 1481392 differs from paper 97155
- (DEVIATION: line) best-PM DiD estimated as linear probability model (paper reports probability-scale coefficients)

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 22,643 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T063758Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 19,382 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T063758Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 361 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T063758Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 7,609 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T063758Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 417 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T063758Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 988 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T063758Z/attempt-1/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 367 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T063758Z/samples.txt`
- [`output/script.R`](output/script.R) — 6,897 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T063758Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 199 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T063758Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,265 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T063758Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,898 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/161e37a5e2f835569f2ad6c6.json`
- [`output/answer-2.md`](output/answer-2.md) — 7,610 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/63e3c566e7db8fd56f5a6f93.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request 161e37a5e2f835569f2ad6c6: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix (request 63e3c566e7db8fd56f5a6f93: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
