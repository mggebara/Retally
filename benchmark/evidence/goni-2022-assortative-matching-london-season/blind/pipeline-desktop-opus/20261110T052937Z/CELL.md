# goni-2022-assortative-matching-london-season · blind · pipeline-desktop-opus · 20261110T052937Z

| | |
|---|---|
| Paper | `goni-2022-assortative-matching-london-season` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261110T052937Z |
| Date | 2026-11-10T05:29:37Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-all-modes-2026-11-09.json` |
| Artifacts | `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T052937Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 13/13 |
| First scored | 13/13 (execution 1) |
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
| `treatment_never_married_table2_panelA_col6` | 0.002 (0.002) | 0.002085 | 4.25% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_commoner_table2_panelB_col1` | 0.006 (0.002) | 0.006195 | 3.25% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_heir_table2_panelB_col2` | -0.005 (0.002) | -0.004689 | 6.22% | ±0.002 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_abs_table2_panelB_col3` | 0.512 (0.213) | 0.511759 | 0.05% | ±0.213 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4` | -0.537 (0.221) | -0.537401 | 0.07% | ±0.221 (se_band) | PASS | PASS |
| `n_obs_table2_panelA_baseline` | 644 | 644 | 0.00% | ±32.2 (relative) | PASS | PASS |
| `n_obs_table2_panelA_landholdings` | 324 | 324 | 0.00% | ±16.2 (relative) | PASS | PASS |
| `n_obs_table2_panelA_never_married` | 765 | 765 | 0.00% | ±38.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 20,831 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T052937Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T052937Z/execution.json`
- [`output/script.R`](output/script.R) — 7,791 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T052937Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T052937Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,648 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T052937Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,792 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/d4cae023b401f0bf13c4b075.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 11.8 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request d4cae023b401f0bf13c4b075: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
