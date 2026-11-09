# bokobza-2022-morning-after-coup-purges · blind · pipeline-desktop-opus-run4 · 20261108T013503Z

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261108T013503Z |
| Date | 2026-11-08T01:35:03Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261108T013503Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 4/11 |
| First scored | 4/11 (execution 1) |
| Final | **4/11** |
| Package files withheld | 8 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `failed_coup_base_country_fe` | 0.1 (0.03) | 0.0791949 | 20.81% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_country_fe` | 0.11 (0.03) | 0.0869431 | 20.96% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_base_leader_fe` | 0.08 (0.03) | 0.05936 | 25.80% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_leader_fe` | 0.09 (0.03) | 0.0666505 | 25.94% | ±0.03 (se_band) | PASS | PASS |
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

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 17,662 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261108T013503Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 112 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261108T013503Z/execution.json`
- [`output/script.R`](output/script.R) — 8,588 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261108T013503Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 746 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261108T013503Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 13,204 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261108T013503Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,589 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/cf35fa9be184fc970928cf91.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 7.6 | 4 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request cf35fa9be184fc970928cf91: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
