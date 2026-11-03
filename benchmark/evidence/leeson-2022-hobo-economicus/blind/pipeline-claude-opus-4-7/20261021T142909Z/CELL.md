# leeson-2022-hobo-economicus · blind · pipeline-claude-opus-4-7 · 20261021T142909Z

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | blind |
| Reproducer | pipeline |
| Model | claude-opus-4-7 |
| Run | 20261021T142909Z |
| Date | 2026-10-21T14:29:09Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-10papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261021T142909Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 4/11 |
| First scored | 4/11 (execution 1) |
| Final | **5/11** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `passersby_full_sample` | 0.005 (0.001) | 0.004102 | 17.96% | ±0.001 (se_band) | PASS | PASS |
| `passersby_five_station_subsample` | 0.006 (0.002) | 0.00553 | 7.83% | ±0.002 (se_band) | PASS | PASS |
| `friendliness_full_sample` | 1.595 (0.851) | 6.21903 | 289.91% | ±0.851 (se_band) | FAIL | FAIL |
| `shuttle_stop_full_sample` | 0.781 (0.182) | 0.779268 | 0.22% | ±0.182 (se_band) | PASS | PASS |
| `shuttle_stop_five_station_subsample` | 0.89 (0.227) | 0.928082 | 4.28% | ±0.227 (se_band) | PASS | PASS |
| `brown_forsythe_donations_per_hour` | 0.541 | 0.733823 | 35.64% | ±0.00541 (relative) | FAIL | FAIL |
| `brown_forsythe_dollars_per_hour` | 0.276 | 0.204963 | 25.74% | ±0.00276 (relative) | FAIL | FAIL |
| `anova_f_donations_per_hour` | 0.4 | 0.484024 | 21.01% | ±0.005 (printed_precision) | FAIL | FAIL |
| `anova_f_dollars_per_hour` | 0.15 | 0.101006 | 32.66% | ±0.005 (printed_precision) | FAIL | FAIL |
| `station_visits_full_sample` | 242 | 239 | 1.24% | ±12.1 (relative) | PASS | FAIL |
| `station_visits_five_station_subsample` | 102 | 87 | 14.71% | ±5.1 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 5/11 pass, which agrees with the row's 5/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 12,815 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261021T142909Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 5,755 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261021T142909Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 126 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261021T142909Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,310 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/pipeline/20261021T142909Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,755 bytes, from `benchmark/.cache/llm/ad95dbbf8ecc5b6243635f4f.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM cache (request ad95dbbf8ecc5b6243635f4f: model claude-opus-4-7, max_tokens 8192, effort None)
- usage records 2 model calls; 1 are code-generation prompts kept above, the other 1 (paper extraction) leave no prompt in the artifacts
