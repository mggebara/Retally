# leeson-2022-hobo-economicus · blind · pipeline-claude-opus-5-5 · 20261022T044925Z

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | blind |
| Reproducer | pipeline |
| Model | claude-opus-5-5 |
| Run | 20261022T044925Z |
| Date | 2026-10-22T04:49:25Z |
| Results file | `benchmark/results/pipeline-opus55-4papers-all-modes-2026-10-22.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261022T044925Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 8/11 |
| First scored | 8/11 (execution 1) |
| Final | **8/11** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `passersby_full_sample` | 0.005 (0.001) | 0.004914 | 1.72% | ±0.001 (se_band) | PASS | PASS |
| `passersby_five_station_subsample` | 0.006 (0.002) | 0.006135 | 2.25% | ±0.002 (se_band) | PASS | PASS |
| `friendliness_full_sample` | 1.595 (0.851) | 1.59511 | 0.01% | ±0.851 (se_band) | PASS | PASS |
| `shuttle_stop_full_sample` | 0.781 (0.182) | 0.780689 | 0.04% | ±0.182 (se_band) | PASS | PASS |
| `shuttle_stop_five_station_subsample` | 0.89 (0.227) | 0.889644 | 0.04% | ±0.227 (se_band) | PASS | PASS |
| `brown_forsythe_donations_per_hour` | 0.541 | 0.541281 | 0.05% | ±0.00541 (relative) | PASS | PASS |
| `brown_forsythe_dollars_per_hour` | 0.276 | 0.466319 | 68.96% | ±0.00276 (relative) | FAIL | FAIL |
| `anova_f_donations_per_hour` | 0.4 | 0.398434 | 0.39% | ±0.005 (printed_precision) | PASS | PASS |
| `anova_f_dollars_per_hour` | 0.15 | 0.312473 | 108.32% | ±0.005 (printed_precision) | FAIL | FAIL |
| `station_visits_full_sample` | 242 | 240 | 0.83% | ±2.42 (relative) | PASS | PASS |
| `station_visits_five_station_subsample` | 102 | 98 | 3.92% | ±1.02 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/11 pass, which agrees with the row's 8/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 14,035 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261022T044925Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 7,356 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261022T044925Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 126 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261022T044925Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,166 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261022T044925Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,356 bytes, from `benchmark/.cache/llm/798d8411a9bec575067f71d2.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM cache (request 798d8411a9bec575067f71d2: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 2 model calls; 1 are code-generation prompts kept above, the other 1 (paper extraction) leave no prompt in the artifacts
