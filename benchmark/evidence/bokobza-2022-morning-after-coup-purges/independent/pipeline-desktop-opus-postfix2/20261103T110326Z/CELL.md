# bokobza-2022-morning-after-coup-purges · independent · pipeline-desktop-opus-postfix2 · 20261103T110326Z

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261103T110326Z |
| Date | 2026-11-03T11:03:26Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T110326Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 11/11 |
| First scored | 11/11 (execution 1) |
| Final | **11/11** |
| Package files withheld | 8 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `failed_coup_base_country_fe` | 0.1 (0.03) | 0.102553 | 2.55% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_country_fe` | 0.11 (0.03) | 0.111954 | 1.78% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_base_leader_fe` | 0.08 (0.03) | 0.061535 | 23.08% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_leader_fe` | 0.09 (0.03) | 0.063813 | 29.10% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_experience_model` | 0.14 (0.04) | 0.134917 | 3.63% | ±0.04 (se_band) | PASS | PASS |
| `failed_coup_x_over_6_years_experience` | -0.1 (0.05) | -0.072174 | 27.83% | ±0.05 (se_band) | PASS | PASS |
| `failed_coup_affiliation_model` | 0.17 (0.06) | 0.175095 | 3.00% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_x_leaders_party` | -0.13 (0.06) | -0.123639 | 4.89% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_responsibility_model` | 0.2 (0.07) | 0.206058 | 3.03% | ±0.07 (se_band) | PASS | PASS |
| `failed_coup_x_natural_resources` | -0.18 (0.08) | -0.180449 | 0.25% | ±0.08 (se_band) | PASS | PASS |
| `failed_coup_importance_model` | 0.37 (0.09) | 0.374072 | 1.10% | ±0.09 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 19,390 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T110326Z/prompt-1.txt`

## What it produced

- [`output/samples.txt`](output/samples.txt) — 664 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T110326Z/samples.txt`
- [`output/script.R`](output/script.R) — 9,621 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T110326Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,124 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T110326Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,484 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261103T110326Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 9,622 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/358bc83a93948090c5b11bf5.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request 358bc83a93948090c5b11bf5: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
