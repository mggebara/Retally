# bokobza-2022-morning-after-coup-purges · blind · pipeline-desktop-opus-run3 · 20261103T010557Z

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T010557Z |
| Date | 2026-11-03T01:05:57Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T010557Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 9/11 (execution 2) |
| Final | **9/11** |
| Package files withheld | 8 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `failed_coup_base_country_fe` | 0.1 (0.03) | 0.0792227 | 20.78% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_country_fe` | 0.11 (0.03) | 0.0869769 | 20.93% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_base_leader_fe` | 0.08 (0.03) | 0.0596024 | 25.50% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_leader_fe` | 0.09 (0.03) | 0.0669028 | 25.66% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_experience_model` | 0.14 (0.04) | 0.146049 | 4.32% | ±0.04 (se_band) | PASS | PASS |
| `failed_coup_x_over_6_years_experience` | -0.1 (0.05) | -0.105594 | 5.59% | ±0.05 (se_band) | PASS | PASS |
| `failed_coup_affiliation_model` | 0.17 (0.06) | 0.11602 | 31.75% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_x_leaders_party` | -0.13 (0.06) | -0.0604941 | 53.47% | ±0.06 (se_band) | FAIL | FAIL |
| `failed_coup_responsibility_model` | 0.2 (0.07) | 0.177989 | 11.01% | ±0.07 (se_band) | PASS | PASS |
| `failed_coup_x_natural_resources` | -0.18 (0.08) | -0.169013 | 6.10% | ±0.08 (se_band) | PASS | PASS |
| `failed_coup_importance_model` | 0.37 (0.09) | 0.707304 | 91.16% | ±0.09 (se_band) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/11 pass, which agrees with the row's 9/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 17,240 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T010557Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 19,752 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T010557Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 2,431 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T010557Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 12,963 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T010557Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 2,431 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T010557Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,427 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T010557Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 14,564 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T010557Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 3,092 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T010557Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 8,490 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T010557Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 12,964 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/2912832dfeab7b4985648f55.json`
- [`output/answer-2.md`](output/answer-2.md) — 14,565 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/dfc1041ba1306c76c2f49e41.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 2912832dfeab7b4985648f55: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request dfc1041ba1306c76c2f49e41: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
