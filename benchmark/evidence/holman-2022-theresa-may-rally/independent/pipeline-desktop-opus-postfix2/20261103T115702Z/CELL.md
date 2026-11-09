# holman-2022-theresa-may-rally · independent · pipeline-desktop-opus-postfix2 · 20261103T115702Z

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261103T115702Z |
| Date | 2026-11-03T11:57:02Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T115702Z` |
| Executions | 3 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 1/11 |
| First scored | 1/11 (execution 1) |
| Final | **4/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `intl_attack_table4` | 3.112 (0.875) | 0.838427 | 73.06% | ±0.875 (se_band) | FAIL | FAIL |
| `intl_attack_x_woman_exec_table4` | -4.333 (1.859) | -1.61312 | 62.77% | ±1.859 (se_band) | FAIL | FAIL |
| `n_obs_table4` | 4328 | 4423 | 2.20% | ±216.4 (relative) | PASS | PASS |
| `did_attack_x_time_like_may_table2` | -0.1274 (0.0187) | -0.0823958 | 35.33% | ±0.0187 (se_band) | FAIL | FAIL |
| `did_attack_like_may_table2` | 0.0178 (0.0278) | -0.129012 | 824.79% | ±0.0278 (se_band) | FAIL | FAIL |
| `did_time_like_may_table2` | -0.5007 (0.0229) | -0.301854 | 39.71% | ±0.0229 (se_band) | FAIL | FAIL |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | -0.0524967 | 4.78% | ±0.0044 (se_band) | PASS | FAIL |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | -0.00198541 | 892.70% | ±0.004 (se_band) | PASS | FAIL |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | 0.229389 | 9.34% | ±0.004196 (relative) | FAIL | FAIL |
| `n_obs_did_like_may_table2` | 143499 | 145012 | 1.05% | ±7174.95 (relative) | PASS | FAIL |
| `n_obs_did_may_best_pm_table2` | 97155 | 91727 | 5.59% | ±4857.75 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 4/11 pass, which agrees with the row's 4/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) table4 estimation N=4423 differs from the paper's 4328
- (DEVIATION: line) panel-corrected standard errors not available in fixest; coefficients unaffected
- (DEVIATION: line) did_like_may: panel restricted to waves 9-13 (paper does not list waves; chosen to match its N)
- (DEVIATION: line) did_like_may estimation N=145012 differs from the paper's 143499
- (DEVIATION: line) did_may_best_pm: panel restricted to waves 8-12 and to wave-12 respondents (paper does not list waves; chosen to match its N)
- (DEVIATION: line) did_may_best_pm estimation N=91727 differs from the paper's 97155
- (DEVIATION: line) best-PM DiD estimated as a linear probability model (paper's coefficients are on the probability scale)

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 22,643 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T115702Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 22,026 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T115702Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 24,379 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T115702Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 942 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T115702Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 427 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T115702Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 8,012 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T115702Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T115702Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,826 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T115702Z/attempt-1/stdout.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 19 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T115702Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 10,909 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T115702Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 126 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T115702Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 332 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T115702Z/attempt-2/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 492 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T115702Z/samples.txt`
- [`output/script.R`](output/script.R) — 9,688 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T115702Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T115702Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,594 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/pipeline/20261103T115702Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,013 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/161e37a5e2f835569f2ad6c6.json`
- [`output/answer-2.md`](output/answer-2.md) — 9,689 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/a3a85a8b6dca6cb081fdf64d.json`
- [`output/answer-3.md`](output/answer-3.md) — 10,910 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/a771a53c13593d1de93425b4.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request 161e37a5e2f835569f2ad6c6: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix2 (request a3a85a8b6dca6cb081fdf64d: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix2 (request a771a53c13593d1de93425b4: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
