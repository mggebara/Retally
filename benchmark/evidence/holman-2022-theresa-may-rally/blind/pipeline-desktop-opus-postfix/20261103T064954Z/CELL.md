# holman-2022-theresa-may-rally · blind · pipeline-desktop-opus-postfix · 20261103T064954Z

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T064954Z |
| Date | 2026-11-03T06:49:54Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T064954Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 0/11 (execution 1) |
| Final | **0/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `intl_attack_table4` | 3.112 (0.875) | — | — | ±0.875 (se_band) | FAIL | FAIL |
| `intl_attack_x_woman_exec_table4` | -4.333 (1.859) | — | — | ±1.859 (se_band) | FAIL | FAIL |
| `n_obs_table4` | 4328 | — | — | ±216.4 (relative) | FAIL | FAIL |
| `did_attack_x_time_like_may_table2` | -0.1274 (0.0187) | -0.150165 | 17.87% | ±0.0187 (se_band) | FAIL | FAIL |
| `did_attack_like_may_table2` | 0.0178 (0.0278) | -0.105036 | 690.09% | ±0.0278 (se_band) | FAIL | FAIL |
| `did_time_like_may_table2` | -0.5007 (0.0229) | -0.61463 | 22.75% | ±0.0229 (se_band) | FAIL | FAIL |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | 4.71664e-11 | 100.00% | ±0.0044 (se_band) | FAIL | FAIL |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | 1.24922 | 624712.50% | ±0.004 (se_band) | FAIL | FAIL |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | -7.82112e-11 | 100.00% | ±0.004196 (relative) | FAIL | FAIL |
| `n_obs_did_like_may_table2` | 143499 | 239919 | 67.19% | ±7174.95 (relative) | FAIL | FAIL |
| `n_obs_did_may_best_pm_table2` | 97155 | 1.48139e+06 | 1424.77% | ±4857.75 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 0/11 pass, which agrees with the row's 0/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 21,658 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T064954Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 9,931 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T064954Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 370 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T064954Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 288 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T064954Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 6,043 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T064954Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 362 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T064954Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 872 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T064954Z/attempt-1/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 288 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T064954Z/samples.txt`
- [`output/script.R`](output/script.R) — 9,339 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T064954Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 900 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T064954Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 879 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T064954Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,044 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/21845d21ea822df5232c4048.json`
- [`output/answer-2.md`](output/answer-2.md) — 9,340 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/635b63cae893313e4c85db7d.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request 21845d21ea822df5232c4048: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix (request 635b63cae893313e4c85db7d: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
