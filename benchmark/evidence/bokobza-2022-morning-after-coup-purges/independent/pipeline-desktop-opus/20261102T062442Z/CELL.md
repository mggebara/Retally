# bokobza-2022-morning-after-coup-purges · independent · pipeline-desktop-opus · 20261102T062442Z

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261102T062442Z |
| Date | 2026-11-02T06:24:42Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T062442Z` |
| Executions | 3 |
| Refinements | 2 (1 error + 1 claim) |
| First attempt | 0/11 |
| First scored | 6/11 (execution 2) |
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
| `failed_coup_experience_model` | 0.14 (0.04) | 0.115646 | 17.40% | ±0.04 (se_band) | PASS | FAIL |
| `failed_coup_x_over_6_years_experience` | -0.1 (0.05) | -0.074897 | 25.10% | ±0.05 (se_band) | PASS | FAIL |
| `failed_coup_affiliation_model` | 0.17 (0.06) | 0.199347 | 17.26% | ±0.06 (se_band) | PASS | FAIL |
| `failed_coup_x_leaders_party` | -0.13 (0.06) | -0.152668 | 17.44% | ±0.06 (se_band) | PASS | PASS |
| `failed_coup_responsibility_model` | 0.2 (0.07) | 0.164289 | 17.86% | ±0.07 (se_band) | PASS | FAIL |
| `failed_coup_x_natural_resources` | -0.18 (0.08) | -0.173906 | 3.39% | ±0.08 (se_band) | PASS | PASS |
| `failed_coup_importance_model` | 0.37 (0.09) | 0.364509 | 1.48% | ±0.09 (se_band) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 16,582 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T062442Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 22,891 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T062442Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 35,379 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T062442Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 602 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T062442Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 16,365 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T062442Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 602 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T062442Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 3,993 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T062442Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 474 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T062442Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 19,543 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T062442Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 473 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T062442Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 15,274 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T062442Z/attempt-2/stdout.txt`
- [`output/script.R`](output/script.R) — 22,120 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T062442Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 393 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T062442Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 15,664 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T062442Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 16,366 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/e3b91fa50f5679d1e03d0a70.json`
- [`output/answer-2.md`](output/answer-2.md) — 19,544 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/5321d60f8e67ad747e178202.json`
- [`output/answer-3.md`](output/answer-3.md) — 22,121 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/38b7d599496d360e4a0f760e.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request e3b91fa50f5679d1e03d0a70: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request 5321d60f8e67ad747e178202: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus (request 38b7d599496d360e4a0f760e: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
