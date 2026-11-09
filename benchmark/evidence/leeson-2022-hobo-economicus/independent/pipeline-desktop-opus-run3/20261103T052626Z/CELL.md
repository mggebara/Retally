# leeson-2022-hobo-economicus · independent · pipeline-desktop-opus-run3 · 20261103T052626Z

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T052626Z |
| Date | 2026-11-03T05:26:26Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 7/11 |
| First scored | 7/11 (execution 1) |
| Final | **11/11** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `passersby_full_sample` | 0.005 (0.001) | 0.004914 | 1.72% | ±0.001 (se_band) | PASS | PASS |
| `passersby_five_station_subsample` | 0.006 (0.002) | 0.006135 | 2.25% | ±0.002 (se_band) | PASS | PASS |
| `friendliness_full_sample` | 1.595 (0.851) | 1.59511 | 0.01% | ±0.851 (se_band) | PASS | FAIL |
| `shuttle_stop_full_sample` | 0.781 (0.182) | 0.780689 | 0.04% | ±0.182 (se_band) | PASS | PASS |
| `shuttle_stop_five_station_subsample` | 0.89 (0.227) | 0.889644 | 0.04% | ±0.227 (se_band) | PASS | PASS |
| `brown_forsythe_donations_per_hour` | 0.541 | 0.541281 | 0.05% | ±0.00541 (relative) | PASS | PASS |
| `brown_forsythe_dollars_per_hour` | 0.276 | 0.275802 | 0.07% | ±0.00276 (relative) | PASS | FAIL |
| `anova_f_donations_per_hour` | 0.4 | 0.398434 | 0.39% | ±0.005 (printed_precision) | PASS | PASS |
| `anova_f_dollars_per_hour` | 0.15 | 0.150879 | 0.59% | ±0.005 (printed_precision) | PASS | FAIL |
| `station_visits_full_sample` | 242 | 242 | 0.00% | ±12.1 (relative) | PASS | PASS |
| `station_visits_five_station_subsample` | 102 | 102 | 0.00% | ±5.1 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Friendliness built from passerby-level max of response cells (long format); 0/1 indicator columns passresp1-5 decoded as response level k
- (DEVIATION: line) Dollars/hour sample/definition chosen as 'nonmiss_cash_inkind\|cash_plus_inkind' to match the paper's documented N=67 and station Ns

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 14,686 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 20,584 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 24,875 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 28,335 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 350 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 8,773 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 302 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 816 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 263 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 12,313 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 364 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 946 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 86 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 14,854 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 600 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 1,235 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/attempt-3/stdout.txt`
- [`output/script.R`](output/script.R) — 15,630 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 416 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,194 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T052626Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,774 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/02d8ef3cfd239637761aea35.json`
- [`output/answer-2.md`](output/answer-2.md) — 12,314 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/d3678564c0bbb0b712022b0c.json`
- [`output/answer-3.md`](output/answer-3.md) — 14,855 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/6c9e13aff6336bc7cc7cc275.json`
- [`output/answer-4.md`](output/answer-4.md) — 15,631 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/e1a08df4e8254b1fcba42cca.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 02d8ef3cfd239637761aea35: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request d3678564c0bbb0b712022b0c: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run3 (request 6c9e13aff6336bc7cc7cc275: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run3 (request e1a08df4e8254b1fcba42cca: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
