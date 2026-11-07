# bokobza-2022-morning-after-coup-purges · blind · pipeline-desktop-opus-run2 · 20261102T091036Z

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261102T091036Z |
| Date | 2026-11-02T09:10:36Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261102T091036Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 10/11 (execution 2) |
| Final | **10/11** |
| Package files withheld | 8 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `failed_coup_base_country_fe` | 0.1 (0.03) | 0.0792227 | 20.78% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_country_fe` | 0.11 (0.03) | 0.0869769 | 20.93% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_base_leader_fe` | 0.08 (0.03) | 0.0596024 | 25.50% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_leader_fe` | 0.09 (0.03) | 0.0669028 | 25.66% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_experience_model` | 0.14 (0.04) | 0.144035 | 2.88% | ±0.04 (se_band) | PASS | PASS |
| `failed_coup_x_over_6_years_experience` | -0.1 (0.05) | -0.104017 | 4.02% | ±0.05 (se_band) | PASS | PASS |
| `failed_coup_affiliation_model` | 0.17 (0.06) | 0.121618 | 28.46% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_x_leaders_party` | -0.13 (0.06) | -0.0673015 | 48.23% | ±0.06 (se_band) | FAIL | FAIL |
| `failed_coup_responsibility_model` | 0.2 (0.07) | 0.177989 | 11.01% | ±0.07 (se_band) | PASS | PASS |
| `failed_coup_x_natural_resources` | -0.18 (0.08) | -0.169013 | 6.10% | ±0.08 (se_band) | PASS | PASS |
| `failed_coup_importance_model` | 0.37 (0.09) | 0.349028 | 5.67% | ±0.09 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/11 pass, which agrees with the row's 10/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 17,207 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261102T091036Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 16,412 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261102T091036Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 2,650 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261102T091036Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 11,819 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261102T091036Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 2,650 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261102T091036Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 11 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261102T091036Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 13,696 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261102T091036Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 3,836 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261102T091036Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,319 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/blind/pipeline/20261102T091036Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 11,820 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/4b5b2dacce9c80274dbcd6b4.json`
- [`output/answer-2.md`](output/answer-2.md) — 13,697 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/76b13ef803a07b6610f030ee.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 4b5b2dacce9c80274dbcd6b4: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request 76b13ef803a07b6610f030ee: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
