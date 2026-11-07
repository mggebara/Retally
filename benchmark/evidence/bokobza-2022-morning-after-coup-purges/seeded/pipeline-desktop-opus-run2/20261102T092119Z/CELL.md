# bokobza-2022-morning-after-coup-purges · seeded · pipeline-desktop-opus-run2 · 20261102T092119Z

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261102T092119Z |
| Date | 2026-11-02T09:21:19Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/pipeline/20261102T092119Z` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 7/11 |
| First scored | 7/11 (execution 1) |
| Final | **7/11** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `failed_coup_base_country_fe` | 0.1 (0.03) | 0.079195 | 20.81% | ±0.005 (printed_precision) | FAIL | FAIL |
| `failed_coup_main_country_fe` | 0.11 (0.03) | 0.086943 | 20.96% | ±0.005 (printed_precision) | FAIL | FAIL |
| `failed_coup_base_leader_fe` | 0.08 (0.03) | 0.05936 | 25.80% | ±0.005 (printed_precision) | FAIL | FAIL |
| `failed_coup_main_leader_fe` | 0.09 (0.03) | 0.066651 | 25.94% | ±0.005 (printed_precision) | FAIL | FAIL |
| `failed_coup_experience_model` | 0.14 (0.04) | 0.142112 | 1.51% | ±0.005 (printed_precision) | PASS | PASS |
| `failed_coup_x_over_6_years_experience` | -0.1 (0.05) | -0.102939 | 2.94% | ±0.005 (printed_precision) | PASS | PASS |
| `failed_coup_affiliation_model` | 0.17 (0.06) | 0.174175 | 2.46% | ±0.005 (printed_precision) | PASS | PASS |
| `failed_coup_x_leaders_party` | -0.13 (0.06) | -0.125832 | 3.21% | ±0.005 (printed_precision) | PASS | PASS |
| `failed_coup_responsibility_model` | 0.2 (0.07) | 0.202499 | 1.25% | ±0.005 (printed_precision) | PASS | PASS |
| `failed_coup_x_natural_resources` | -0.18 (0.08) | -0.183205 | 1.78% | ±0.005 (printed_precision) | PASS | PASS |
| `failed_coup_importance_model` | 0.37 (0.09) | 0.370185 | 0.05% | ±0.0074 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/11 pass, which agrees with the row's 7/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 77,930 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/pipeline/20261102T092119Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 26,424 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/pipeline/20261102T092119Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 364 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/pipeline/20261102T092119Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 9,570 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/pipeline/20261102T092119Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 803 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/pipeline/20261102T092119Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 23,235 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/pipeline/20261102T092119Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 10,335 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/pipeline/20261102T092119Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 803 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/pipeline/20261102T092119Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 23,465 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/seeded/pipeline/20261102T092119Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 9,571 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/d533a968fbfa783c82a9fec1.json`
- [`output/answer-2.md`](output/answer-2.md) — 10,336 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/748a642800b614359a9991f1.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request d533a968fbfa783c82a9fec1: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request 748a642800b614359a9991f1: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 2 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
