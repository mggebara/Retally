# forsythe-2022-young-workers-recessions · seeded · pipeline-desktop-opus-run3 · 20261103T054754Z

| | |
|---|---|
| Paper | `forsythe-2022-young-workers-recessions` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T054754Z |
| Date | 2026-11-03T05:47:54Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z` |
| Executions | 4 |
| Refinements | 3 (3 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 0/13 (execution 1) |
| Final | **0/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `young_x_unemp_rate_no_controls` | -0.335 (0.0203) | — | — | ±0.0067 (relative) | FAIL | FAIL |
| `experienced_x_unemp_rate_no_controls` | -0.0367 (0.0131) | — | — | ±0.000734 (relative) | FAIL | FAIL |
| `young_x_unemp_rate_preferred` | -0.253 (0.0185) | — | — | ±0.00506 (relative) | FAIL | FAIL |
| `experienced_x_unemp_rate_preferred` | 0.0496 (0.0142) | — | — | ±0.000992 (relative) | FAIL | FAIL |
| `aggregate_unemp_rate_no_controls` | -0.119 (0.015) | — | — | ±0.00238 (relative) | FAIL | FAIL |
| `aggregate_unemp_rate_month_year_fe` | -0.0326 (0.0132) | — | — | ±0.000652 (relative) | FAIL | FAIL |
| `young_x_unemp_rate_employed` | -0.168 (0.0156) | — | — | ±0.00336 (relative) | FAIL | FAIL |
| `experienced_x_unemp_rate_employed` | 0.0179 (0.0101) | — | — | ±0.000358 (relative) | FAIL | FAIL |
| `young_x_unemp_rate_unemployed` | -1.928 (0.167) | — | — | ±0.03856 (relative) | FAIL | FAIL |
| `young_x_unemp_rate_nilf` | -0.49 (0.0332) | — | — | ±0.0098 (relative) | FAIL | FAIL |
| `wage_young_x_unemp_rate_all_hires` | -0.0262 (0.0036) | — | — | ±0.000524 (relative) | FAIL | FAIL |
| `wage_experienced_x_unemp_rate_all_hires` | -0.0116 (0.00348) | — | — | ±0.000232 (relative) | FAIL | FAIL |
| `n_obs_full_sample` | 1.69485e+07 | — | — | ±847426 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 0/13 pass, which agrees with the row's 0/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 60,175 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 10,813 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 12,963 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 14,682 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 32 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 8,929 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 32 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 11,079 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 34 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 12,796 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 34 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/attempt-3/stdout.txt`
- [`output/script.R`](output/script.R) — 13,521 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 34 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261103T054754Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,930 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/11c59c70da9878040a8e9c79.json`
- [`output/answer-2.md`](output/answer-2.md) — 11,080 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/4b365a7258862579a830ea33.json`
- [`output/answer-3.md`](output/answer-3.md) — 12,797 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/2776e27919b9d276861d937d.json`
- [`output/answer-4.md`](output/answer-4.md) — 13,522 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/f8d9d3535fcaeb041b735054.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 11c59c70da9878040a8e9c79: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request 4b365a7258862579a830ea33: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run3 (request 2776e27919b9d276861d937d: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run3 (request f8d9d3535fcaeb041b735054: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 4 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
