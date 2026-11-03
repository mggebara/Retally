# leeson-2022-hobo-economicus · seeded · pipeline-desktop-opus-run2 · 20261023T151837Z

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261023T151837Z |
| Date | 2026-10-23T15:18:37Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/pipeline/20261023T151837Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 11/11 |
| First scored | 11/11 (execution 1) |
| Final | **11/11** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `passersby_full_sample` | 0.005 (0.001) | 0.004914 | 1.72% | ±0.0005 (printed_precision) | PASS | PASS |
| `passersby_five_station_subsample` | 0.006 (0.002) | 0.006135 | 2.25% | ±0.0005 (printed_precision) | PASS | PASS |
| `friendliness_full_sample` | 1.595 (0.851) | 1.59511 | 0.01% | ±0.0319 (relative) | PASS | PASS |
| `shuttle_stop_full_sample` | 0.781 (0.182) | 0.780689 | 0.04% | ±0.01562 (relative) | PASS | PASS |
| `shuttle_stop_five_station_subsample` | 0.89 (0.227) | 0.889644 | 0.04% | ±0.0178 (relative) | PASS | PASS |
| `brown_forsythe_donations_per_hour` | 0.541 | 0.541281 | 0.05% | ±0.00541 (relative) | PASS | PASS |
| `brown_forsythe_dollars_per_hour` | 0.276 | 0.275802 | 0.07% | ±0.00276 (relative) | PASS | PASS |
| `anova_f_donations_per_hour` | 0.4 | 0.398434 | 0.39% | ±0.005 (printed_precision) | PASS | PASS |
| `anova_f_dollars_per_hour` | 0.15 | 0.150879 | 0.59% | ±0.005 (printed_precision) | PASS | PASS |
| `station_visits_full_sample` | 242 | 242 | 0.00% | ±12.1 (relative) | PASS | PASS |
| `station_visits_five_station_subsample` | 102 | 102 | 0.00% | ±5.1 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 27,911 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/pipeline/20261023T151837Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 7,121 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/pipeline/20261023T151837Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/pipeline/20261023T151837Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,002 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/pipeline/20261023T151837Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,122 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/cd5bd60e4ce983d2efb50e39.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request cd5bd60e4ce983d2efb50e39: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 1 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
