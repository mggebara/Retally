# manekin-2022-effective-for-whom · blind · pipeline-claude-opus-5-5 · 20261022T044632Z

| | |
|---|---|
| Paper | `manekin-2022-effective-for-whom` |
| Mode | blind |
| Reproducer | pipeline |
| Model | claude-opus-5-5 |
| Run | 20261022T044632Z |
| Date | 2026-10-22T04:46:32Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-opus55-4papers-all-modes-2026-10-22.json` |
| Artifacts | `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/pipeline/20261022T044632Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 12/12 |
| First scored | 12/12 (execution 1) |
| Final | **12/12** |
| Package files withheld | 96 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `study1_us_black_perceived_violence` | 0.235 (0.117) | 0.235246 | 0.10% | ±0.117 (se_band) | PASS | PASS |
| `study1_us_black_police_action` | 0.268 (0.127) | 0.26801 | 0.00% | ±0.127 (se_band) | PASS | PASS |
| `study1_israel_ethiopian_perceived_violence` | 0.425 (0.107) | 0.425066 | 0.02% | ±0.107 (se_band) | PASS | PASS |
| `study1_israel_ethiopian_police_action` | 0.181 (0.118) | 0.180704 | 0.16% | ±0.118 (se_band) | PASS | PASS |
| `study1_israel_arab_perceived_violence` | 0.623 (0.108) | 0.623088 | 0.01% | ±0.108 (se_band) | PASS | PASS |
| `study1_israel_arab_police_action` | 0.964 (0.119) | 0.9642 | 0.02% | ±0.119 (se_band) | PASS | PASS |
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

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 17,917 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/pipeline/20261022T044632Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 6,166 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/pipeline/20261022T044632Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 474 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/pipeline/20261022T044632Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 554 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/pipeline/20261022T044632Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,166 bytes, from `benchmark/.cache/llm/c8e05619f6dfb84a279e61f7.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM cache (request c8e05619f6dfb84a279e61f7: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 2 model calls; 1 are code-generation prompts kept above, the other 1 (paper extraction) leave no prompt in the artifacts
