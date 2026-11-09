# douenne-2022-yellow-vests-carbon-tax · independent · pipeline-desktop-opus-run4 · 20261108T015935Z

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261108T015935Z |
| Date | 2026-11-08T01:59:35Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z` |
| Executions | 3 |
| Refinements | 2 (1 error + 1 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 2) |
| Final | **13/13** |
| Package files withheld | 39 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.222239 | 17.38% | ±0.058 (se_band) | PASS | PASS |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.250949 | 17.99% | ±0.066 (se_band) | PASS | PASS |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.198432 | 4.60% | ±0.035 (se_band) | PASS | PASS |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.202956 | 17.50% | ±0.064 (se_band) | PASS | PASS |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.0367489 | 144.99% | ±0.087 (se_band) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | -0.0184548 | 197.13% | ±0.058 (se_band) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.123619 | 25.53% | ±0.079 (se_band) | PASS | PASS |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.112584 | 25.44% | ±0.069 (se_band) | PASS | PASS |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.0919067 | 14.88% | ±0.079 (se_band) | PASS | PASS |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.153484 | 0.32% | ±0.045 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±37.85 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.466254 | 12.69% | ±0.132 (se_band) | PASS | PASS |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.456039 | 9.62% | ±0.168 (se_band) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 24,593 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 11,733 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 22,646 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 282 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 9,061 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 282 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 460 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 112 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 10,536 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 579 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,943 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z/attempt-2/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z/execution.json`
- [`output/script.R`](output/script.R) — 10,950 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 579 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,029 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261108T015935Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 9,062 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/5878d7e9474053617f655f0c.json`
- [`output/answer-2.md`](output/answer-2.md) — 10,537 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/d53a7ae7b6d8f43a41778c21.json`
- [`output/answer-3.md`](output/answer-3.md) — 10,951 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/50f78c9d9792e526fdd31c0c.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 1 | — | — | 0 |
| attempt-2 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 2.2 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request 5878d7e9474053617f655f0c: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run4 (request d53a7ae7b6d8f43a41778c21: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run4 (request 50f78c9d9792e526fdd31c0c: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
