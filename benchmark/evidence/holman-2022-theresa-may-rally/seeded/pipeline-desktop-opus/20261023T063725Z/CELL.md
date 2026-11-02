# holman-2022-theresa-may-rally · seeded · pipeline-desktop-opus · 20261023T063725Z

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261023T063725Z |
| Date | 2026-10-23T06:37:25Z |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/pipeline/20261023T063725Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 11/11 |
| First scored | 11/11 (execution 1) |
| Final | **11/11** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `intl_attack_table4` | 3.112 (0.875) | 3.11203 | 0.00% | ±0.06224 (relative) | PASS | PASS |
| `intl_attack_x_woman_exec_table4` | -4.333 (1.859) | -4.33272 | 0.01% | ±0.08666 (relative) | PASS | PASS |
| `n_obs_table4` | 4328 | 4328 | 0.00% | ±43.28 (relative) | PASS | PASS |
| `did_attack_x_time_like_may_table2` | -0.1274 (0.0187) | -0.12739 | 0.01% | ±0.002548 (relative) | PASS | PASS |
| `did_attack_like_may_table2` | 0.0178 (0.0278) | 0.017785 | 0.08% | ±0.000356 (relative) | PASS | PASS |
| `did_time_like_may_table2` | -0.5007 (0.0229) | -0.50065 | 0.01% | ±0.010014 (relative) | PASS | PASS |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | -0.05007 | 0.06% | ±0.001002 (relative) | PASS | PASS |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | -0.000171 | 14.50% | ±5e-05 (printed_precision) | PASS | PASS |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | 0.209799 | 0.00% | ±0.004196 (relative) | PASS | PASS |
| `n_obs_did_like_may_table2` | 143499 | 143499 | 0.00% | ±1434.99 (relative) | PASS | PASS |
| `n_obs_did_may_best_pm_table2` | 97155 | 97155 | 0.00% | ±971.55 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 62,002 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/pipeline/20261023T063725Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 6,724 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/pipeline/20261023T063725Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/pipeline/20261023T063725Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 493 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/seeded/pipeline/20261023T063725Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,725 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/f7d4adfba23a908e12002a7a.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request f7d4adfba23a908e12002a7a: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 1 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
