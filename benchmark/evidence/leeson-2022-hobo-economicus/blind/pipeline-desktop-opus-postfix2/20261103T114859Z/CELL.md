# leeson-2022-hobo-economicus · blind · pipeline-desktop-opus-postfix2 · 20261103T114859Z

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261103T114859Z |
| Date | 2026-11-03T11:48:59Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261103T114859Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 8/11 |
| First scored | 8/11 (execution 1) |
| Final | **8/11** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `passersby_full_sample` | 0.005 (0.001) | 0.00481358 | 3.73% | ±0.001 (se_band) | PASS | PASS |
| `passersby_five_station_subsample` | 0.006 (0.002) | 0.00689613 | 14.94% | ±0.002 (se_band) | PASS | PASS |
| `friendliness_full_sample` | 1.595 (0.851) | 12.9773 | 713.62% | ±0.851 (se_band) | FAIL | FAIL |
| `shuttle_stop_full_sample` | 0.781 (0.182) | 0.674967 | 13.58% | ±0.182 (se_band) | PASS | PASS |
| `shuttle_stop_five_station_subsample` | 0.89 (0.227) | 0.948825 | 6.61% | ±0.227 (se_band) | PASS | PASS |
| `brown_forsythe_donations_per_hour` | 0.541 | 0.541281 | 0.05% | ±0.00541 (relative) | PASS | PASS |
| `brown_forsythe_dollars_per_hour` | 0.276 | 0.394352 | 42.88% | ±0.00276 (relative) | FAIL | FAIL |
| `anova_f_donations_per_hour` | 0.4 | 0.398434 | 0.39% | ±0.005 (printed_precision) | PASS | PASS |
| `anova_f_dollars_per_hour` | 0.15 | 0.285048 | 90.03% | ±0.005 (printed_precision) | FAIL | FAIL |
| `station_visits_full_sample` | 242 | 240 | 0.83% | ±12.1 (relative) | PASS | PASS |
| `station_visits_five_station_subsample` | 102 | 98 | 3.92% | ±5.1 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/11 pass, which agrees with the row's 8/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 16,377 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261103T114859Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 10,804 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261103T114859Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 122 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261103T114859Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 272 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261103T114859Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 7,266 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261103T114859Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 302 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261103T114859Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 848 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261103T114859Z/attempt-1/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 272 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261103T114859Z/samples.txt`
- [`output/script.R`](output/script.R) — 10,368 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261103T114859Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 480 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261103T114859Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 857 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261103T114859Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,267 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/23aa6aff7da0b70ec51ec0cc.json`
- [`output/answer-2.md`](output/answer-2.md) — 10,369 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/2f8406c9a66bb1abd9a6c935.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request 23aa6aff7da0b70ec51ec0cc: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix2 (request 2f8406c9a66bb1abd9a6c935: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
