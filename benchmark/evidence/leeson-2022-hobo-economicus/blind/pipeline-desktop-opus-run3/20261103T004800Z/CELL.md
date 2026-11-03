# leeson-2022-hobo-economicus · blind · pipeline-desktop-opus-run3 · 20261103T004800Z

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T004800Z |
| Date | 2026-11-03T00:48:00Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261103T004800Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 7/11 |
| First scored | 7/11 (execution 1) |
| Final | **8/11** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `passersby_full_sample` | 0.005 (0.001) | 0.00481358 | 3.73% | ±0.001 (se_band) | PASS | PASS |
| `passersby_five_station_subsample` | 0.006 (0.002) | 0.00689613 | 14.94% | ±0.002 (se_band) | PASS | PASS |
| `friendliness_full_sample` | 1.595 (0.851) | — | — | ±0.851 (se_band) | FAIL | FAIL |
| `shuttle_stop_full_sample` | 0.781 (0.182) | 0.674967 | 13.58% | ±0.182 (se_band) | PASS | PASS |
| `shuttle_stop_five_station_subsample` | 0.89 (0.227) | 0.948825 | 6.61% | ±0.227 (se_band) | PASS | PASS |
| `brown_forsythe_donations_per_hour` | 0.541 | 0.541281 | 0.05% | ±0.00541 (relative) | PASS | PASS |
| `brown_forsythe_dollars_per_hour` | 0.276 | 0.394352 | 42.88% | ±0.00276 (relative) | FAIL | FAIL |
| `anova_f_donations_per_hour` | 0.4 | 0.398434 | 0.39% | ±0.005 (printed_precision) | PASS | PASS |
| `anova_f_dollars_per_hour` | 0.15 | 0.285048 | 90.03% | ±0.005 (printed_precision) | FAIL | FAIL |
| `station_visits_full_sample` | 242 | 240 | 0.83% | ±12.1 (relative) | PASS | PASS |
| `station_visits_five_station_subsample` | 102 | 98 | 3.92% | ±5.1 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/11 pass, which agrees with the row's 8/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 14,008 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261103T004800Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 6,235 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261103T004800Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 302 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261103T004800Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 518 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261103T004800Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,236 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/a3b3e154cd5cb2e9cd178990.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request a3b3e154cd5cb2e9cd178990: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
