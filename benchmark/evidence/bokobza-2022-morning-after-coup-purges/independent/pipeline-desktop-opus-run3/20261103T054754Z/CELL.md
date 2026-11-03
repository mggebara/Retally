# bokobza-2022-morning-after-coup-purges · independent · pipeline-desktop-opus-run3 · 20261103T054754Z

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T054754Z |
| Date | 2026-11-03T05:47:54Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z` |
| Executions | 5 |
| Refinements | 4 (1 error + 3 claim) |
| First attempt | 0/11 |
| First scored | 9/11 (execution 2) |
| Final | **11/11** |
| Package files withheld | 8 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `failed_coup_base_country_fe` | 0.1 (0.03) | 0.0791949 | 20.81% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_country_fe` | 0.11 (0.03) | 0.0869431 | 20.96% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_base_leader_fe` | 0.08 (0.03) | 0.05936 | 25.80% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_leader_fe` | 0.09 (0.03) | 0.0666505 | 25.94% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_experience_model` | 0.14 (0.04) | 0.138979 | 0.73% | ±0.04 (se_band) | PASS | PASS |
| `failed_coup_x_over_6_years_experience` | -0.1 (0.05) | -0.0954212 | 4.58% | ±0.05 (se_band) | PASS | PASS |
| `failed_coup_affiliation_model` | 0.17 (0.06) | 0.1504 | 11.53% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_x_leaders_party` | -0.13 (0.06) | -0.0976191 | 24.91% | ±0.06 (se_band) | PASS | FAIL |
| `failed_coup_responsibility_model` | 0.2 (0.07) | 0.208497 | 4.25% | ±0.07 (se_band) | PASS | PASS |
| `failed_coup_x_natural_resources` | -0.18 (0.08) | -0.198896 | 10.50% | ±0.08 (se_band) | PASS | PASS |
| `failed_coup_importance_model` | 0.37 (0.09) | 0.348688 | 5.76% | ±0.09 (se_band) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Affiliation model contrasts leader's-party ministers with all other ministers pooled (other party, unaffiliated, unknown); paper does not state the omitted category

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 16,662 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 23,345 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 31,846 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 33,793 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 34,702 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 843 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 14,534 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 843 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 8,681 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 186 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 16,054 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 1,011 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 12,543 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 95 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 17,513 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 1,159 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 14,677 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/attempt-3/stdout.txt`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 96 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 17,962 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 1,159 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 14,857 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/attempt-4/stdout.txt`
- [`output/script.R`](output/script.R) — 17,739 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,161 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 14,812 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T054754Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 14,535 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/fbf4f66335bd996caaa185f7.json`
- [`output/answer-2.md`](output/answer-2.md) — 16,055 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/0a6c463aecbdf345d8ebd9a5.json`
- [`output/answer-3.md`](output/answer-3.md) — 17,514 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/8925e66cc176edab70da4cb1.json`
- [`output/answer-4.md`](output/answer-4.md) — 17,963 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/ec9a3bf93776b3f84560a573.json`
- [`output/answer-5.md`](output/answer-5.md) — 17,740 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/ebbcb546089b563e37bfb0f2.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request fbf4f66335bd996caaa185f7: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request 0a6c463aecbdf345d8ebd9a5: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run3 (request 8925e66cc176edab70da4cb1: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run3 (request ec9a3bf93776b3f84560a573: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus-run3 (request ebbcb546089b563e37bfb0f2: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 5 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
