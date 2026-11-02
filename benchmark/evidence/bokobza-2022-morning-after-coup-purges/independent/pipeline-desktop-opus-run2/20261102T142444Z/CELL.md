# bokobza-2022-morning-after-coup-purges · independent · pipeline-desktop-opus-run2 · 20261102T142444Z

| | |
|---|---|
| Paper | `bokobza-2022-morning-after-coup-purges` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261102T142444Z |
| Date | 2026-11-02T14:24:44Z |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 4/11 |
| First scored | 4/11 (execution 1) |
| Final | **10/11** |
| Package files withheld | 8 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `failed_coup_base_country_fe` | 0.1 (0.03) | 0.079223 | 20.78% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_country_fe` | 0.11 (0.03) | 0.086977 | 20.93% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_base_leader_fe` | 0.08 (0.03) | 0.059602 | 25.50% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_main_leader_fe` | 0.09 (0.03) | 0.066903 | 25.66% | ±0.03 (se_band) | PASS | PASS |
| `failed_coup_experience_model` | 0.14 (0.04) | 0.145649 | 4.03% | ±0.04 (se_band) | PASS | FAIL |
| `failed_coup_x_over_6_years_experience` | -0.1 (0.05) | -0.106443 | 6.44% | ±0.05 (se_band) | PASS | FAIL |
| `failed_coup_affiliation_model` | 0.17 (0.06) | 0.113672 | 33.13% | ±0.06 (se_band) | PASS | FAIL |
| `failed_coup_x_leaders_party` | -0.13 (0.06) | -0.057996 | 55.39% | ±0.06 (se_band) | FAIL | FAIL |
| `failed_coup_responsibility_model` | 0.2 (0.07) | 0.178176 | 10.91% | ±0.07 (se_band) | PASS | FAIL |
| `failed_coup_x_natural_resources` | -0.18 (0.08) | -0.173543 | 3.59% | ±0.08 (se_band) | PASS | FAIL |
| `failed_coup_importance_model` | 0.37 (0.09) | 0.348505 | 5.81% | ±0.09 (se_band) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/11 pass, which agrees with the row's 10/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) affiliation model uses ministers from another (non-leader) party as reference category (paper does not state the base level; unaffiliated reference did not match)

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 17,089 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 28,255 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 30,849 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 31,430 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 633 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 13,729 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 107 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 5,009 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 95 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 15,631 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 12,521 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 95 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 15,758 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 12,638 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/attempt-3/stdout.txt`
- [`output/script.R`](output/script.R) — 15,816 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 12,695 bytes, from `benchmark/results/artifacts/bokobza-2022-morning-after-coup-purges/independent/pipeline/20261102T142444Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 13,730 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/09f6dfdb95d5923c567faf2f.json`
- [`output/answer-2.md`](output/answer-2.md) — 15,632 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/e135ca335f9f21acdf7570b8.json`
- [`output/answer-3.md`](output/answer-3.md) — 15,759 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/64fe46a1838e4bf2ef90abdc.json`
- [`output/answer-4.md`](output/answer-4.md) — 15,817 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/bd582d2e3a53e36547fbb75b.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 09f6dfdb95d5923c567faf2f: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request e135ca335f9f21acdf7570b8: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run2 (request 64fe46a1838e4bf2ef90abdc: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run2 (request bd582d2e3a53e36547fbb75b: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
