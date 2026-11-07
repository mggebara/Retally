# manekin-2022-effective-for-whom · independent · pipeline-desktop-opus-postfix2 · 20261103T113209Z

| | |
|---|---|
| Paper | `manekin-2022-effective-for-whom` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261103T113209Z |
| Date | 2026-11-03T11:32:09Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/pipeline/20261103T113209Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 8/12 |
| First scored | 8/12 (execution 1) |
| Final | **12/12** |
| Package files withheld | 96 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `study1_us_black_perceived_violence` | 0.235 (0.117) | 0.235246 | 0.10% | ±0.117 (se_band) | PASS | PASS |
| `study1_us_black_police_action` | 0.268 (0.127) | 0.26801 | 0.00% | ±0.127 (se_band) | PASS | PASS |
| `study1_israel_ethiopian_perceived_violence` | 0.425 (0.107) | 0.425066 | 0.02% | ±0.107 (se_band) | PASS | FAIL |
| `study1_israel_ethiopian_police_action` | 0.181 (0.118) | 0.180704 | 0.16% | ±0.118 (se_band) | PASS | FAIL |
| `study1_israel_arab_perceived_violence` | 0.623 (0.108) | 0.623088 | 0.01% | ±0.108 (se_band) | PASS | FAIL |
| `study1_israel_arab_police_action` | 0.964 (0.119) | 0.9642 | 0.02% | ±0.119 (se_band) | PASS | FAIL |
| `study2_us_black_perceived_violence` | 0.347 (0.115) | 0.346652 | 0.10% | ±0.115 (se_band) | PASS | PASS |
| `study2_us_black_police_action` | 0.429 (0.114) | 0.42873 | 0.06% | ±0.114 (se_band) | PASS | PASS |
| `respondents_study1_us` | 2269 | 2269 | 0.00% | ±113.45 (relative) | PASS | PASS |
| `respondents_study1_israel` | 3063 | 3063 | 0.00% | ±153.15 (relative) | PASS | PASS |
| `respondents_study2_us` | 3013 | 3013 | 0.00% | ±150.65 (relative) | PASS | PASS |
| `respondents_study2_israel` | 3465 | 3465 | 0.00% | ±173.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 23,210 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/pipeline/20261103T113209Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 11,968 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/pipeline/20261103T113209Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 366 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/pipeline/20261103T113209Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 445 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/pipeline/20261103T113209Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 7,468 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/pipeline/20261103T113209Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/pipeline/20261103T113209Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,920 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/pipeline/20261103T113209Z/attempt-1/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 445 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/pipeline/20261103T113209Z/samples.txt`
- [`output/script.R`](output/script.R) — 8,317 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/pipeline/20261103T113209Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/pipeline/20261103T113209Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,272 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/independent/pipeline/20261103T113209Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,469 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/5d49784016853c2aba877fdd.json`
- [`output/answer-2.md`](output/answer-2.md) — 8,318 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/9265fd0089f9bc630a002a12.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request 5d49784016853c2aba877fdd: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix2 (request 9265fd0089f9bc630a002a12: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
