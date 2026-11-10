# goni-2022-assortative-matching-london-season · independent · pipeline-desktop-opus · 20261110T053231Z

| | |
|---|---|
| Paper | `goni-2022-assortative-matching-london-season` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261110T053231Z |
| Date | 2026-11-10T05:32:31Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-all-modes-2026-11-09.json` |
| Artifacts | `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053231Z` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 11/13 |
| First scored | 11/13 (execution 1) |
| Final | **13/13** |
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
| `treatment_never_married_table2_panelA_col6` | 0.002 (0.002) | 0.00197 | 1.50% | ±0.002 (se_band) | PASS | FAIL |
| `treatment_married_commoner_table2_panelB_col1` | 0.006 (0.002) | 0.006195 | 3.25% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_heir_table2_panelB_col2` | -0.005 (0.002) | -0.004689 | 6.22% | ±0.002 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_abs_table2_panelB_col3` | 0.512 (0.213) | 0.511759 | 0.05% | ±0.213 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4` | -0.537 (0.221) | -0.537401 | 0.07% | ±0.221 (se_band) | PASS | PASS |
| `n_obs_table2_panelA_baseline` | 644 | 644 | 0.00% | ±32.2 (relative) | PASS | PASS |
| `n_obs_table2_panelA_landholdings` | 324 | 324 | 0.00% | ±16.2 (relative) | PASS | PASS |
| `n_obs_table2_panelA_never_married` | 765 | 763 | 0.26% | ±38.25 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Never-married sample constructed from base sample plus never-married women aged 15-35 in 1861 surviving to 35 (no ready-made sample flag); definition chosen as closest to the paper N among candidates

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 20,584 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053231Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 17,753 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053231Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053231Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 171 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053231Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 6,414 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053231Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053231Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,343 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053231Z/attempt-1/stdout.txt`
- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053231Z/execution.json`
- [`output/script.R`](output/script.R) — 8,733 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053231Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053231Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,326 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/independent/pipeline/20261110T053231Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,415 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/2d94558d5e1d81a93deeb41b.json`
- [`output/answer-2.md`](output/answer-2.md) — 8,734 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/966c9aed6a63b83c0645d4b1.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 11 |
| final | final | 0 | no | 9.0 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 2d94558d5e1d81a93deeb41b: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request 966c9aed6a63b83c0645d4b1: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
