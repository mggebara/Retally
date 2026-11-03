# forsythe-2022-young-workers-recessions · independent · pipeline-desktop-opus-postfix · 20261103T070149Z

| | |
|---|---|
| Paper | `forsythe-2022-young-workers-recessions` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T070149Z |
| Date | 2026-11-03T07:01:49Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T070149Z` |
| Executions | 3 |
| Refinements | 2 (1 error + 1 claim) |
| First attempt | 0/13 |
| First scored | 9/13 (execution 2) |
| Final | **9/13** |
| Package files withheld | 7 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `young_x_unemp_rate_no_controls` | -0.335 (0.0203) | -0.333281 | 0.51% | ±0.0203 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_no_controls` | -0.0367 (0.0131) | -0.0449223 | 22.40% | ±0.0131 (se_band) | PASS | PASS |
| `young_x_unemp_rate_preferred` | -0.253 (0.0185) | -0.238302 | 5.81% | ±0.0185 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_preferred` | 0.0496 (0.0142) | 0.0533386 | 7.54% | ±0.0142 (se_band) | PASS | PASS |
| `aggregate_unemp_rate_no_controls` | -0.119 (0.015) | -0.116271 | 2.29% | ±0.015 (se_band) | PASS | PASS |
| `aggregate_unemp_rate_month_year_fe` | -0.0326 (0.0132) | -0.0169882 | 47.89% | ±0.0132 (se_band) | FAIL | FAIL |
| `young_x_unemp_rate_employed` | -0.168 (0.0156) | -0.160867 | 4.25% | ±0.0156 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_employed` | 0.0179 (0.0101) | 0.016955 | 5.28% | ±0.0101 (se_band) | PASS | PASS |
| `young_x_unemp_rate_unemployed` | -1.928 (0.167) | -1.75081 | 9.19% | ±0.167 (se_band) | FAIL | FAIL |
| `young_x_unemp_rate_nilf` | -0.49 (0.0332) | -0.555306 | 13.33% | ±0.0332 (se_band) | FAIL | FAIL |
| `wage_young_x_unemp_rate_all_hires` | -0.0262 (0.0036) | -0.0230259 | 12.11% | ±0.0036 (se_band) | PASS | PASS |
| `wage_experienced_x_unemp_rate_all_hires` | -0.0116 (0.00348) | -0.00905336 | 21.95% | ±0.00348 (se_band) | PASS | PASS |
| `n_obs_full_sample` | 1.69485e+07 | 1.43625e+07 | 15.26% | ±847426 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/13 pass, which agrees with the row's 9/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) no month-in-sample variable in the data; the 8-month MIS 4->5 break and Madrian-Lefgren matching are assumed already applied in the matched file.

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,298 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T070149Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 12,852 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T070149Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 24,065 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T070149Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 32 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T070149Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 206 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T070149Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 10,423 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T070149Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T070149Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 387 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T070149Z/attempt-1/stdout.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 99 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T070149Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 11,485 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T070149Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T070149Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 299 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T070149Z/attempt-2/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 968 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T070149Z/samples.txt`
- [`output/script.R`](output/script.R) — 10,697 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T070149Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 74 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T070149Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,518 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T070149Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,424 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/2140f874528586bdf06de528.json`
- [`output/answer-2.md`](output/answer-2.md) — 10,698 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/d98efd1fb0919747c29b529d.json`
- [`output/answer-3.md`](output/answer-3.md) — 11,486 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/9ae84337570a98162a2a24d1.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request 2140f874528586bdf06de528: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix (request d98efd1fb0919747c29b529d: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix (request 9ae84337570a98162a2a24d1: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
