# leeson-2022-hobo-economicus · blind · pipeline-desktop-opus-run4 · 20261108T013503Z

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261108T013503Z |
| Date | 2026-11-08T01:35:03Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261108T013503Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 9/11 |
| First scored | 9/11 (execution 1) |
| Final | **9/11** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `passersby_full_sample` | 0.005 (0.001) | 0.00491392 | 1.72% | ±0.001 (se_band) | PASS | PASS |
| `passersby_five_station_subsample` | 0.006 (0.002) | 0.00613459 | 2.24% | ±0.002 (se_band) | PASS | PASS |
| `friendliness_full_sample` | 1.595 (0.851) | 1.59511 | 0.01% | ±0.851 (se_band) | PASS | PASS |
| `shuttle_stop_full_sample` | 0.781 (0.182) | 0.780689 | 0.04% | ±0.182 (se_band) | PASS | PASS |
| `shuttle_stop_five_station_subsample` | 0.89 (0.227) | 0.889644 | 0.04% | ±0.227 (se_band) | PASS | PASS |
| `brown_forsythe_donations_per_hour` | 0.541 | 0.541281 | 0.05% | ±0.00541 (relative) | PASS | PASS |
| `brown_forsythe_dollars_per_hour` | 0.276 | 0.394352 | 42.88% | ±0.00276 (relative) | FAIL | FAIL |
| `anova_f_donations_per_hour` | 0.4 | 0.398434 | 0.39% | ±0.005 (printed_precision) | PASS | PASS |
| `anova_f_dollars_per_hour` | 0.15 | 0.285048 | 90.03% | ±0.005 (printed_precision) | FAIL | FAIL |
| `station_visits_full_sample` | 242 | 240 | 0.83% | ±12.1 (relative) | PASS | PASS |
| `station_visits_five_station_subsample` | 102 | 98 | 3.92% | ±5.1 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/11 pass, which agrees with the row's 9/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 14,849 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261108T013503Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261108T013503Z/execution.json`
- [`output/script.R`](output/script.R) — 6,199 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261108T013503Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 126 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261108T013503Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 499 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261108T013503Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,200 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/b76b8bd35718edf657e549b2.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 1.5 | 11 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request b76b8bd35718edf657e549b2: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
