# bokobza-2022-morning-after-coup-purges · independent · pipeline-desktop-opus-run4 · 20261108T192145Z

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261108T192145Z |
| Date | 2026-11-08T19:21:45Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 4/11 |
| First scored | 4/11 (execution 1) |
| Final | **11/11** |
| Package files withheld | 8 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `failed_coup_base_country_fe` | 0.1 (0.03) | 0.079223 | 20.78% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_country_fe` | 0.11 (0.03) | 0.086977 | 20.93% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_base_leader_fe` | 0.08 (0.03) | 0.059602 | 25.50% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_leader_fe` | 0.09 (0.03) | 0.066903 | 25.66% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_experience_model` | 0.14 (0.04) | 0.134977 | 3.59% | ±0.04 (se_band) | PASS | FAIL |
| `failed_coup_x_over_6_years_experience` | -0.1 (0.05) | -0.094515 | 5.49% | ±0.05 (se_band) | PASS | FAIL |
| `failed_coup_affiliation_model` | 0.17 (0.06) | 0.121618 | 28.46% | ±0.06 (se_band) | PASS | FAIL |
| `failed_coup_x_leaders_party` | -0.13 (0.06) | -0.097075 | 25.33% | ±0.06 (se_band) | PASS | FAIL |
| `failed_coup_responsibility_model` | 0.2 (0.07) | 0.175933 | 12.03% | ±0.07 (se_band) | PASS | FAIL |
| `failed_coup_x_natural_resources` | -0.18 (0.08) | -0.169225 | 5.99% | ±0.08 (se_band) | PASS | FAIL |
| `failed_coup_importance_model` | 0.37 (0.09) | 0.349028 | 5.67% | ±0.09 (se_band) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) leader's-party interaction reported relative to all non-leader-party ministers pooled (other party + no party); reference category not stated in summary

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 16,582 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 26,618 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 28,971 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 30,388 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 633 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 10,413 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 1,269 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 6,002 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 189 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 12,954 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 1,169 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 27,398 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 95 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 13,877 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 1,320 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 28,943 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/attempt-3/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/execution.json`
- [`output/script.R`](output/script.R) — 14,444 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,471 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 29,907 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261108T192145Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,414 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/e3b91fa50f5679d1e03d0a70.json`
- [`output/answer-2.md`](output/answer-2.md) — 12,955 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/b2abf061acdebfbae4fe6e4a.json`
- [`output/answer-3.md`](output/answer-3.md) — 13,878 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/b717eeadb67d6f76fdc658b0.json`
- [`output/answer-4.md`](output/answer-4.md) — 14,445 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/a1a0f5e17b4e1ba105c57ba9.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 4 |
| attempt-2 | claim | 0 | — | — | 10 |
| attempt-3 | claim | 0 | — | — | 11 |
| final | final | 0 | no | 14.4 | 11 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request e3b91fa50f5679d1e03d0a70: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run4 (request b2abf061acdebfbae4fe6e4a: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run4 (request b717eeadb67d6f76fdc658b0: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run4 (request a1a0f5e17b4e1ba105c57ba9: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
