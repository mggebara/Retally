# leeson-2022-hobo-economicus · independent · pipeline-desktop-opus-run4 · 20261108T204839Z

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261108T204839Z |
| Date | 2026-11-08T20:48:39Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 6/11 |
| First scored | 6/11 (execution 1) |
| Final | **9/11** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `passersby_full_sample` | 0.005 (0.001) | 0.00491392 | 1.72% | ±0.001 (se_band) | PASS | PASS |
| `passersby_five_station_subsample` | 0.006 (0.002) | 0.00613459 | 2.24% | ±0.002 (se_band) | PASS | PASS |
| `friendliness_full_sample` | 1.595 (0.851) | 1.59511 | 0.01% | ±0.851 (se_band) | PASS | FAIL |
| `shuttle_stop_full_sample` | 0.781 (0.182) | 0.780689 | 0.04% | ±0.182 (se_band) | PASS | PASS |
| `shuttle_stop_five_station_subsample` | 0.89 (0.227) | 0.889644 | 0.04% | ±0.227 (se_band) | PASS | FAIL |
| `brown_forsythe_donations_per_hour` | 0.541 | 0.541281 | 0.05% | ±0.00541 (relative) | PASS | PASS |
| `brown_forsythe_dollars_per_hour` | 0.276 | 0.933392 | 238.19% | ±0.00276 (relative) | FAIL | FAIL |
| `anova_f_donations_per_hour` | 0.4 | 0.398434 | 0.39% | ±0.005 (printed_precision) | PASS | PASS |
| `anova_f_dollars_per_hour` | 0.15 | 0.826411 | 450.94% | ±0.005 (printed_precision) | FAIL | FAIL |
| `station_visits_full_sample` | 242 | 242 | 0.00% | ±12.1 (relative) | PASS | PASS |
| `station_visits_five_station_subsample` | 102 | 102 | 0.00% | ±5.1 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/11 pass, which agrees with the row's 9/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Friendliness response columns are 0/1 indicators of response levels; each passerby's friendliest response is the highest level indicated (1-5), averaged by station
- (DEVIATION: line) Dollars-per-hour sample defined as 'cash+inkind, declined excluded, repeat panhandlers counted once' to match the paper's N=67 counted panhandlers

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 13,217 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 17,081 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 18,663 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 20,820 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 458 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 6,739 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 304 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 763 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 273 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 8,056 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 941 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 180 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 9,684 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 946 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/attempt-3/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/execution.json`
- [`output/script.R`](output/script.R) — 11,078 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,185 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261108T204839Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,740 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/e6e361e404123ffa1a9e0aff.json`
- [`output/answer-2.md`](output/answer-2.md) — 8,057 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/800bc4476601e87ce7c96e7e.json`
- [`output/answer-3.md`](output/answer-3.md) — 9,685 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/eb13517c4fc26eb5ecd46908.json`
- [`output/answer-4.md`](output/answer-4.md) — 11,079 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/779cd56be9cc4cbb4d0d87a0.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 16 |
| attempt-2 | claim | 0 | — | — | 17 |
| attempt-3 | claim | 0 | — | — | 17 |
| final | final | 0 | no | 1.3 | 17 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request e6e361e404123ffa1a9e0aff: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run4 (request 800bc4476601e87ce7c96e7e: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run4 (request eb13517c4fc26eb5ecd46908: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run4 (request 779cd56be9cc4cbb4d0d87a0: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
