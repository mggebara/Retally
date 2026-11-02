# forsythe-2022-young-workers-recessions · seeded · pipeline-desktop-opus · 20261102T062442Z

| | |
|---|---|
| Paper | `forsythe-2022-young-workers-recessions` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261102T062442Z |
| Date | 2026-11-02T06:24:42Z |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261102T062442Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 2) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `young_x_unemp_rate_no_controls` | -0.335 (0.0203) | -0.335031 | 0.01% | ±0.0067 (relative) | PASS | PASS |
| `experienced_x_unemp_rate_no_controls` | -0.0367 (0.0131) | -0.036675 | 0.07% | ±0.000734 (relative) | PASS | PASS |
| `young_x_unemp_rate_preferred` | -0.253 (0.0185) | -0.253253 | 0.10% | ±0.00506 (relative) | PASS | PASS |
| `experienced_x_unemp_rate_preferred` | 0.0496 (0.0142) | 0.049562 | 0.08% | ±0.000992 (relative) | PASS | PASS |
| `aggregate_unemp_rate_no_controls` | -0.119 (0.015) | -0.119074 | 0.06% | ±0.00238 (relative) | PASS | PASS |
| `aggregate_unemp_rate_month_year_fe` | -0.0326 (0.0132) | -0.032623 | 0.07% | ±0.000652 (relative) | PASS | PASS |
| `young_x_unemp_rate_employed` | -0.168 (0.0156) | -0.167865 | 0.08% | ±0.00336 (relative) | PASS | PASS |
| `experienced_x_unemp_rate_employed` | 0.0179 (0.0101) | 0.017855 | 0.25% | ±0.000358 (relative) | PASS | PASS |
| `young_x_unemp_rate_unemployed` | -1.928 (0.167) | -1.92785 | 0.01% | ±0.03856 (relative) | PASS | PASS |
| `young_x_unemp_rate_nilf` | -0.49 (0.0332) | -0.489847 | 0.03% | ±0.0098 (relative) | PASS | PASS |
| `wage_young_x_unemp_rate_all_hires` | -0.0262 (0.0036) | -0.026174 | 0.10% | ±0.000524 (relative) | PASS | PASS |
| `wage_experienced_x_unemp_rate_all_hires` | -0.0116 (0.00348) | -0.011598 | 0.02% | ±0.000232 (relative) | PASS | PASS |
| `n_obs_full_sample` | 1.69485e+07 | 1.69485e+07 | 0.00% | ±169485 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 60,294 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261102T062442Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 12,717 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261102T062442Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 32 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261102T062442Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 10,246 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261102T062442Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261102T062442Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 531 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261102T062442Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 11,857 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261102T062442Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261102T062442Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 626 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/seeded/pipeline/20261102T062442Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,247 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/7360b142b59e98f168ed0b4e.json`
- [`output/answer-2.md`](output/answer-2.md) — 11,858 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/bdca71002fe3ccd25548d925.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 7360b142b59e98f168ed0b4e: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request bdca71002fe3ccd25548d925: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 2 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
