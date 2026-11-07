# bokobza-2022-morning-after-coup-purges · blind · pipeline-desktop-opus-postfix2 · 20261103T114859Z

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261103T114859Z |
| Date | 2026-11-03T11:48:59Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T114859Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 4/11 |
| First scored | 4/11 (execution 1) |
| Final | **4/11** |
| Package files withheld | 8 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `failed_coup_base_country_fe` | 0.1 (0.03) | 0.102553 | 2.55% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_country_fe` | 0.11 (0.03) | 0.111954 | 1.78% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_base_leader_fe` | 0.08 (0.03) | 0.061535 | 23.08% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_leader_fe` | 0.09 (0.03) | 0.0638133 | 29.10% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_experience_model` | 0.14 (0.04) | — | — | ±0.04 (se_band) | FAIL | FAIL |
| `failed_coup_x_over_6_years_experience` | -0.1 (0.05) | — | — | ±0.05 (se_band) | FAIL | FAIL |
| `failed_coup_affiliation_model` | 0.17 (0.06) | — | — | ±0.06 (se_band) | FAIL | FAIL |
| `failed_coup_x_leaders_party` | -0.13 (0.06) | — | — | ±0.06 (se_band) | FAIL | FAIL |
| `failed_coup_responsibility_model` | 0.2 (0.07) | — | — | ±0.07 (se_band) | FAIL | FAIL |
| `failed_coup_x_natural_resources` | -0.18 (0.08) | — | — | ±0.08 (se_band) | FAIL | FAIL |
| `failed_coup_importance_model` | 0.37 (0.09) | — | — | ±0.09 (se_band) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 4/11 pass, which agrees with the row's 4/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 19,938 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T114859Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 15,999 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T114859Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 550 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T114859Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 824 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T114859Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 11,065 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T114859Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 620 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T114859Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,463 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T114859Z/attempt-1/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 836 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T114859Z/samples.txt`
- [`output/script.R`](output/script.R) — 12,593 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T114859Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 377 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T114859Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,475 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261103T114859Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 11,066 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/b62d548783d2945b70ebf86d.json`
- [`output/answer-2.md`](output/answer-2.md) — 12,594 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/960efcbf3b14932564430856.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request b62d548783d2945b70ebf86d: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix2 (request 960efcbf3b14932564430856: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
