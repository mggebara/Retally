# holman-2022-theresa-may-rally · blind · pipeline-desktop-opus-run3 · 20261103T004800Z

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T004800Z |
| Date | 2026-11-03T00:48:00Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T004800Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
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
| `did_time_like_may_table2` | -0.5007 (0.0229) | -1.04807 | 109.32% | ±0.0229 (se_band) | FAIL | FAIL |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | -3.86158e-11 | 100.00% | ±0.0044 (se_band) | FAIL | FAIL |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | 1.24922 | 624712.50% | ±0.004 (se_band) | FAIL | FAIL |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | 3.29003e-10 | 100.00% | ±0.004196 (relative) | FAIL | FAIL |
| `n_obs_did_like_may_table2` | 143499 | 239919 | 67.19% | ±7174.95 (relative) | FAIL | FAIL |
| `n_obs_did_may_best_pm_table2` | 97155 | 1.48139e+06 | 1424.77% | ±4857.75 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 0/11 pass, which agrees with the row's 0/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 15,484 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T004800Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 7,367 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T004800Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 86 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T004800Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,998 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/pipeline/20261103T004800Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,368 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/a964d92685a695f9a4df384f.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request a964d92685a695f9a4df384f: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
