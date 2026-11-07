# manekin-2022-effective-for-whom · blind · pipeline-claude-opus-4-7 · 20261021T142909Z

| | |
|---|---|
| Paper | `manekin-2022-effective-for-whom` |
| Mode | blind |
| Reproducer | pipeline |
| Model | claude-opus-4-7 |
| Run | 20261021T142909Z |
| Date | 2026-10-21T14:29:09Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-10papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/pipeline/20261021T142909Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 6/12 |
| First scored | 6/12 (execution 1) |
| Final | **6/12** |
| Package files withheld | 96 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `study1_us_black_perceived_violence` | 0.235 (0.117) | — | — | ±0.117 (se_band) | FAIL | FAIL |
| `study1_us_black_police_action` | 0.268 (0.127) | — | — | ±0.127 (se_band) | FAIL | FAIL |
| `study1_israel_ethiopian_perceived_violence` | 0.425 (0.107) | — | — | ±0.107 (se_band) | FAIL | FAIL |
| `study1_israel_ethiopian_police_action` | 0.181 (0.118) | — | — | ±0.118 (se_band) | FAIL | FAIL |
| `study1_israel_arab_perceived_violence` | 0.623 (0.108) | — | — | ±0.108 (se_band) | FAIL | FAIL |
| `study1_israel_arab_police_action` | 0.964 (0.119) | — | — | ±0.119 (se_band) | FAIL | FAIL |
| `study2_us_black_perceived_violence` | 0.347 (0.115) | 0.346652 | 0.10% | ±0.115 (se_band) | PASS | PASS |
| `study2_us_black_police_action` | 0.429 (0.114) | 0.42873 | 0.06% | ±0.114 (se_band) | PASS | PASS |
| `respondents_study1_us` | 2269 | 2269 | 0.00% | ±113.45 (relative) | PASS | PASS |
| `respondents_study1_israel` | 3063 | 3063 | 0.00% | ±153.15 (relative) | PASS | PASS |
| `respondents_study2_us` | 3013 | 3013 | 0.00% | ±150.65 (relative) | PASS | PASS |
| `respondents_study2_israel` | 3465 | 3465 | 0.00% | ±173.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 6/12 pass, which agrees with the row's 6/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 16,742 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/pipeline/20261021T142909Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 5,463 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/pipeline/20261021T142909Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/pipeline/20261021T142909Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 646 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/pipeline/20261021T142909Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,463 bytes, from `benchmark/.cache/llm/0237dd27254b0b572b8ba26c.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM cache (request 0237dd27254b0b572b8ba26c: model claude-opus-4-7, max_tokens 8192, effort None)
- usage records 2 model calls; 1 are code-generation prompts kept above, the other 1 (paper extraction) leave no prompt in the artifacts
