# forsythe-2022-young-workers-recessions · blind · pipeline-desktop-opus-postfix2 · 20261103T120039Z

| | |
|---|---|
| Paper | `forsythe-2022-young-workers-recessions` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261103T120039Z |
| Date | 2026-11-03T12:00:39Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z` |
| Executions | 3 |
| Refinements | 2 (2 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 9/13 (execution 3) |
| Final | **9/13** |
| Package files withheld | 7 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `young_x_unemp_rate_no_controls` | -0.335 (0.0203) | -0.334056 | 0.28% | ±0.0203 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_no_controls` | -0.0367 (0.0131) | -0.045125 | 22.96% | ±0.0131 (se_band) | PASS | PASS |
| `young_x_unemp_rate_preferred` | -0.253 (0.0185) | -0.23897 | 5.55% | ±0.0185 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_preferred` | 0.0496 (0.0142) | 0.053197 | 7.25% | ±0.0142 (se_band) | PASS | PASS |
| `aggregate_unemp_rate_no_controls` | -0.119 (0.015) | -0.116496 | 2.10% | ±0.015 (se_band) | PASS | PASS |
| `aggregate_unemp_rate_month_year_fe` | -0.0326 (0.0132) | -0.017014 | 47.81% | ±0.0132 (se_band) | FAIL | FAIL |
| `young_x_unemp_rate_employed` | -0.168 (0.0156) | -0.161431 | 3.91% | ±0.0156 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_employed` | 0.0179 (0.0101) | 0.016818 | 6.04% | ±0.0101 (se_band) | PASS | PASS |
| `young_x_unemp_rate_unemployed` | -1.928 (0.167) | -1.74381 | 9.55% | ±0.167 (se_band) | FAIL | FAIL |
| `young_x_unemp_rate_nilf` | -0.49 (0.0332) | -0.555676 | 13.40% | ±0.0332 (se_band) | FAIL | FAIL |
| `wage_young_x_unemp_rate_all_hires` | -0.0262 (0.0036) | -0.023261 | 11.22% | ±0.0036 (se_band) | PASS | PASS |
| `wage_experienced_x_unemp_rate_all_hires` | -0.0116 (0.00348) | -0.009067 | 21.84% | ±0.00348 (se_band) | PASS | PASS |
| `n_obs_full_sample` | 1.69485e+07 | 1.42966e+07 | 15.65% | ±847426 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/13 pass, which agrees with the row's 9/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 19,142 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 15,397 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 16,868 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 32 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 24 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 13,150 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 205 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 122 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z/attempt-2/feedback.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 24 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 14,708 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 122 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 28 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z/attempt-2/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 1,028 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z/samples.txt`
- [`output/script.R`](output/script.R) — 14,797 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 73 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,404 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/blind/pipeline/20261103T120039Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 13,151 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/a3f1b201078ceadb0ca05c25.json`
- [`output/answer-2.md`](output/answer-2.md) — 14,709 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/cd2c14e9775c749806a0077e.json`
- [`output/answer-3.md`](output/answer-3.md) — 14,798 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/36a54c6c58872fa502081581.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request a3f1b201078ceadb0ca05c25: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix2 (request cd2c14e9775c749806a0077e: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix2 (request 36a54c6c58872fa502081581: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
