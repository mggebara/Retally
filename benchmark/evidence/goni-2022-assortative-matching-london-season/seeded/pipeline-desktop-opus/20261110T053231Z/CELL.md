# goni-2022-assortative-matching-london-season · seeded · pipeline-desktop-opus · 20261110T053231Z

| | |
|---|---|
| Paper | `goni-2022-assortative-matching-london-season` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261110T053231Z |
| Date | 2026-11-10T05:32:31Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-all-modes-2026-11-09.json` |
| Artifacts | `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/seeded/pipeline/20261110T053231Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 13/13 |
| First scored | 13/13 (execution 1) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `treatment_married_commoner_table2_panelA_col1` | 0.005 (0.002) | 0.004534 | 9.32% | ±0.0005 (printed_precision) | PASS | PASS |
| `treatment_married_heir_table2_panelA_col2` | -0.004 (0.002) | -0.003631 | 9.22% | ±0.0005 (printed_precision) | PASS | PASS |
| `treatment_landholdings_diff_abs_table2_panelA_col3` | 0.524 (0.196) | 0.524469 | 0.09% | ±0.01048 (relative) | PASS | PASS |
| `treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4` | -0.516 (0.225) | -0.516195 | 0.04% | ±0.01032 (relative) | PASS | PASS |
| `treatment_married_down_table2_panelA_col5` | 0.009 (0.003) | 0.008983 | 0.19% | ±0.0005 (printed_precision) | PASS | PASS |
| `treatment_never_married_table2_panelA_col6` | 0.002 (0.002) | 0.002085 | 4.25% | ±0.0005 (printed_precision) | PASS | PASS |
| `treatment_married_commoner_table2_panelB_col1` | 0.006 (0.002) | 0.006195 | 3.25% | ±0.0005 (printed_precision) | PASS | PASS |
| `treatment_married_heir_table2_panelB_col2` | -0.005 (0.002) | -0.004689 | 6.22% | ±0.0005 (printed_precision) | PASS | PASS |
| `treatment_landholdings_diff_abs_table2_panelB_col3` | 0.512 (0.213) | 0.511759 | 0.05% | ±0.01024 (relative) | PASS | PASS |
| `treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4` | -0.537 (0.221) | -0.537401 | 0.07% | ±0.01074 (relative) | PASS | PASS |
| `n_obs_table2_panelA_baseline` | 644 | 644 | 0.00% | ±32.2 (relative) | PASS | PASS |
| `n_obs_table2_panelA_landholdings` | 324 | 324 | 0.00% | ±16.2 (relative) | PASS | PASS |
| `n_obs_table2_panelA_never_married` | 765 | 765 | 0.00% | ±38.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 212,567 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/seeded/pipeline/20261110T053231Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/seeded/pipeline/20261110T053231Z/execution.json`
- [`output/script.R`](output/script.R) — 5,184 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/seeded/pipeline/20261110T053231Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/seeded/pipeline/20261110T053231Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,564 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/seeded/pipeline/20261110T053231Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,185 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/68b2d17a056d73c11a0c6c4b.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 10.2 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 68b2d17a056d73c11a0c6c4b: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 1 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
