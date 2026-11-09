# leeson-2022-hobo-economicus · independent · pipeline-desktop-opus-postfix2 · 20261105T212407Z

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261105T212407Z |
| Date | 2026-11-05T21:24:07Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z` |
| Executions | 4 |
| Refinements | 3 (1 error + 2 claim) |
| First attempt | 8/11 |
| First scored | 8/11 (execution 1) |
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
| `station_visits_full_sample` | 242 | 240 | 0.83% | ±12.1 (relative) | PASS | PASS |
| `station_visits_five_station_subsample` | 102 | 98 | 3.92% | ±5.1 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) dollars/hour sample restricted by rule 'cash_and_inkind' to match the paper's N=67

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 17,085 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 12,759 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 26,404 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 28,564 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 122 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 372 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 8,612 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 302 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,457 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 269 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/attempt-2/feedback.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 372 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 11,800 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 2,065 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,561 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 91 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/attempt-3/feedback.txt`
- [`output/attempt-3/samples.txt`](output/attempt-3/samples.txt) — 409 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/attempt-3/samples.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 13,014 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 2,191 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 1,792 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/attempt-3/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 409 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/samples.txt`
- [`output/script.R`](output/script.R) — 13,960 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,314 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,761 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261105T212407Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,613 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/009a4b1fd9f59c097905880a.json`
- [`output/answer-2.md`](output/answer-2.md) — 11,801 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/77824a836def30a9e9888406.json`
- [`output/answer-3.md`](output/answer-3.md) — 13,015 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/f720c8948cea9674182ad218.json`
- [`output/answer-4.md`](output/answer-4.md) — 13,961 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/622b37b9fac8eeba3ce80d0e.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request 009a4b1fd9f59c097905880a: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix2 (request 77824a836def30a9e9888406: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix2 (request f720c8948cea9674182ad218: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-postfix2 (request 622b37b9fac8eeba3ce80d0e: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
