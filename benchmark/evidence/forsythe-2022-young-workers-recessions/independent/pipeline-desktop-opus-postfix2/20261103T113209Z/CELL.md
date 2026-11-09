# forsythe-2022-young-workers-recessions · independent · pipeline-desktop-opus-postfix2 · 20261103T113209Z

| | |
|---|---|
| Paper | `forsythe-2022-young-workers-recessions` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261103T113209Z |
| Date | 2026-11-03T11:32:09Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T113209Z` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 9/13 |
| First scored | 9/13 (execution 1) |
| Final | **9/13** |
| Package files withheld | 7 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `young_x_unemp_rate_no_controls` | -0.335 (0.0203) | -0.333638 | 0.41% | ±0.0203 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_no_controls` | -0.0367 (0.0131) | -0.04513 | 22.97% | ±0.0131 (se_band) | PASS | PASS |
| `young_x_unemp_rate_preferred` | -0.253 (0.0185) | -0.238566 | 5.71% | ±0.0185 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_preferred` | 0.0496 (0.0142) | 0.053226 | 7.31% | ±0.0142 (se_band) | PASS | PASS |
| `aggregate_unemp_rate_no_controls` | -0.119 (0.015) | -0.116496 | 2.10% | ±0.015 (se_band) | PASS | PASS |
| `aggregate_unemp_rate_month_year_fe` | -0.0326 (0.0132) | -0.017014 | 47.81% | ±0.0132 (se_band) | FAIL | FAIL |
| `young_x_unemp_rate_employed` | -0.168 (0.0156) | -0.161102 | 4.11% | ±0.0156 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_employed` | 0.0179 (0.0101) | 0.016838 | 5.93% | ±0.0101 (se_band) | PASS | PASS |
| `young_x_unemp_rate_unemployed` | -1.928 (0.167) | -1.74396 | 9.55% | ±0.167 (se_band) | FAIL | FAIL |
| `young_x_unemp_rate_nilf` | -0.49 (0.0332) | -0.55526 | 13.32% | ±0.0332 (se_band) | FAIL | FAIL |
| `wage_young_x_unemp_rate_all_hires` | -0.0262 (0.0036) | -0.023181 | 11.52% | ±0.0036 (se_band) | PASS | PASS |
| `wage_experienced_x_unemp_rate_all_hires` | -0.0116 (0.00348) | -0.009133 | 21.27% | ±0.00348 (se_band) | PASS | PASS |
| `n_obs_full_sample` | 1.69485e+07 | 1.42966e+07 | 15.65% | ±847426 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/13 pass, which agrees with the row's 9/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) 2035872 person-months had no match in v2unemp_smy.csv; their state unemployment rate is filled with the CPS-weighted state-month rate (level-adjusted per state) so the sample matches the paper's N.
- (DEVIATION: line) full sample has 14296610 rows vs 16948516 stated in the paper (Table 1 N).
- (DEVIATION: line) month-in-sample is not in the data; outgoing-rotation months are identified by non-missing weekly earnings.

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,298 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T113209Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 26,196 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T113209Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 374 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T113209Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 905 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T113209Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 11,037 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T113209Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 73 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T113209Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,571 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T113209Z/attempt-1/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 905 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T113209Z/samples.txt`
- [`output/script.R`](output/script.R) — 12,625 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T113209Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 73 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T113209Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,933 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/pipeline/20261103T113209Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 11,038 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/2140f874528586bdf06de528.json`
- [`output/answer-2.md`](output/answer-2.md) — 12,626 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/2e0b2d12ec4309f7305b2cc8.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request 2140f874528586bdf06de528: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix2 (request 2e0b2d12ec4309f7305b2cc8: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
