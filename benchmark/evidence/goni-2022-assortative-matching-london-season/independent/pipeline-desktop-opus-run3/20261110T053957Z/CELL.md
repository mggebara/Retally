# goni-2022-assortative-matching-london-season · independent · pipeline-desktop-opus-run3 · 20261110T053957Z

| | |
|---|---|
| Paper | `goni-2022-assortative-matching-london-season` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261110T053957Z |
| Date | 2026-11-10T05:39:57Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-1paper-all-modes-2026-11-09.json` |
| Artifacts | `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053957Z` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 12/13 |
| First scored | 12/13 (execution 1) |
| Final | **12/13** |
| Package files withheld | 120 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `treatment_married_commoner_table2_panelA_col1` | 0.005 (0.002) | 0.004534 | 9.32% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_heir_table2_panelA_col2` | -0.004 (0.002) | -0.003631 | 9.22% | ±0.002 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_abs_table2_panelA_col3` | 0.524 (0.196) | 0.524469 | 0.09% | ±0.196 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4` | -0.516 (0.225) | -0.516195 | 0.04% | ±0.225 (se_band) | PASS | PASS |
| `treatment_married_down_table2_panelA_col5` | 0.009 (0.003) | 0.008983 | 0.19% | ±0.003 (se_band) | PASS | PASS |
| `treatment_never_married_table2_panelA_col6` | 0.002 (0.002) | 0.001764 | 11.80% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_commoner_table2_panelB_col1` | 0.006 (0.002) | 0.006195 | 3.25% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_heir_table2_panelB_col2` | -0.005 (0.002) | -0.004689 | 6.22% | ±0.002 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_abs_table2_panelB_col3` | 0.512 (0.213) | 0.511759 | 0.05% | ±0.213 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4` | -0.537 (0.221) | -0.537401 | 0.07% | ±0.221 (se_band) | PASS | PASS |
| `n_obs_table2_panelA_baseline` | 644 | 644 | 0.00% | ±32.2 (relative) | PASS | PASS |
| `n_obs_table2_panelA_landholdings` | 324 | 324 | 0.00% | ±16.2 (relative) | PASS | PASS |
| `n_obs_table2_panelA_never_married` | 765 | 910 | 18.95% | ±38.25 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 20,584 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053957Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 18,574 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053957Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053957Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 83 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053957Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 8,334 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053957Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053957Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,236 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053957Z/attempt-1/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053957Z/execution.json`
- [`output/script.R`](output/script.R) — 9,385 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053957Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053957Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,404 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053957Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,335 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/2d94558d5e1d81a93deeb41b.json`
- [`output/answer-2.md`](output/answer-2.md) — 9,386 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/089d2e3fdc0466f2e4d116c5.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 10.9 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 2d94558d5e1d81a93deeb41b: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request 089d2e3fdc0466f2e4d116c5: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
