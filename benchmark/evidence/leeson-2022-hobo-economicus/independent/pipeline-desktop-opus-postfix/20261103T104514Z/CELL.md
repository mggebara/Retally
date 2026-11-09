# leeson-2022-hobo-economicus · independent · pipeline-desktop-opus-postfix · 20261103T104514Z

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T104514Z |
| Date | 2026-11-03T10:45:14Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z` |
| Executions | 5 |
| Refinements | 4 (1 error + 3 claim) |
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

- (DEVIATION: line) passresp columns are 0/1 category indicators; friendliest response taken as the highest category marked (1-5 scale)
- (DEVIATION: line) full-sample regression uses 240 obs rather than 242 (missing covariates or singleton date FE)
- (DEVIATION: line) five-station regression uses 98 obs rather than 102
- (DEVIATION: line) dollars sample restricted using rule 'inkind_obs' (offer explicitly accepted / valid count) to match the 67 counted panhandlers

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 17,085 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 12,149 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 23,743 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 23,490 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 24,561 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 122 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 294 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 8,392 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 302 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,067 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 269 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-2/feedback.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 294 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 12,008 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 626 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,074 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 263 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-3/feedback.txt`
- [`output/attempt-3/samples.txt`](output/attempt-3/samples.txt) — 294 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-3/samples.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 10,889 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 1,160 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 1,067 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-3/stdout.txt`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 176 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-4/feedback.txt`
- [`output/attempt-4/samples.txt`](output/attempt-4/samples.txt) — 294 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-4/samples.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 11,440 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 1,121 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 1,287 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/attempt-4/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 294 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/samples.txt`
- [`output/script.R`](output/script.R) — 12,097 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,229 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,287 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/pipeline/20261103T104514Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,393 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/009a4b1fd9f59c097905880a.json`
- [`output/answer-2.md`](output/answer-2.md) — 12,009 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/6eb9a0ca3c03465e3ab8c177.json`
- [`output/answer-3.md`](output/answer-3.md) — 10,890 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/a522c2eac7ef2acdae94f0cb.json`
- [`output/answer-4.md`](output/answer-4.md) — 11,441 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/68c20132058c9bbf73e6006e.json`
- [`output/answer-5.md`](output/answer-5.md) — 12,098 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/a1ea2bf19b9dd32d839a3647.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request 009a4b1fd9f59c097905880a: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix (request 6eb9a0ca3c03465e3ab8c177: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix (request a522c2eac7ef2acdae94f0cb: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-postfix (request 68c20132058c9bbf73e6006e: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus-postfix (request a1ea2bf19b9dd32d839a3647: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 5 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
