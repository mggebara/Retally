# goni-2022-assortative-matching-london-season · independent · pipeline-desktop-opus-run4 · 20261110T054433Z

| | |
|---|---|
| Paper | `goni-2022-assortative-matching-london-season` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261110T054433Z |
| Date | 2026-11-10T05:44:33Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-1paper-indep-blind-2026-11-09.json` |
| Artifacts | `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z` |
| Executions | 3 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 8/13 |
| First scored | 8/13 (execution 1) |
| Final | **13/13** |
| Package files withheld | 120 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `treatment_married_commoner_table2_panelA_col1` | 0.005 (0.002) | 0.004534 | 9.32% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_heir_table2_panelA_col2` | -0.004 (0.002) | -0.003631 | 9.22% | ±0.002 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_abs_table2_panelA_col3` | 0.524 (0.196) | 0.570804 | 8.93% | ±0.196 (se_band) | PASS | FAIL |
| `treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4` | -0.516 (0.225) | -0.46264 | 10.34% | ±0.225 (se_band) | PASS | FAIL |
| `treatment_married_down_table2_panelA_col5` | 0.009 (0.003) | 0.008983 | 0.19% | ±0.003 (se_band) | PASS | PASS |
| `treatment_never_married_table2_panelA_col6` | 0.002 (0.002) | 0.002085 | 4.25% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_commoner_table2_panelB_col1` | 0.006 (0.002) | 0.006195 | 3.25% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_heir_table2_panelB_col2` | -0.005 (0.002) | -0.004689 | 6.22% | ±0.002 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_abs_table2_panelB_col3` | 0.512 (0.213) | 0.555599 | 8.52% | ±0.213 (se_band) | PASS | FAIL |
| `treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4` | -0.537 (0.221) | -0.490665 | 8.63% | ±0.221 (se_band) | PASS | FAIL |
| `n_obs_table2_panelA_baseline` | 644 | 644 | 0.00% | ±32.2 (relative) | PASS | PASS |
| `n_obs_table2_panelA_landholdings` | 324 | 324 | 0.00% | ±16.2 (relative) | PASS | FAIL |
| `n_obs_table2_panelA_never_married` | 765 | 765 | 0.00% | ±38.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Percentile ranks of family acres computed on the pooled wife+husband distribution within the landholdings sample

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 20,584 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 19,251 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 21,638 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 580 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 7,456 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,827 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 497 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 8,551 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,527 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z/attempt-2/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z/execution.json`
- [`output/script.R`](output/script.R) — 10,924 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,584 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T054433Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,457 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/2d94558d5e1d81a93deeb41b.json`
- [`output/answer-2.md`](output/answer-2.md) — 8,552 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/d39c7c7033133ccc4ed76445.json`
- [`output/answer-3.md`](output/answer-3.md) — 10,925 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/0ea3193e8b7bfead23e56bb0.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 13 |
| attempt-2 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 11.1 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request 2d94558d5e1d81a93deeb41b: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run4 (request d39c7c7033133ccc4ed76445: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run4 (request 0ea3193e8b7bfead23e56bb0: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
