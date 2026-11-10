# goni-2022-assortative-matching-london-season · blind · pipeline-desktop-opus-run3 · 20261110T053957Z

| | |
|---|---|
| Paper | `goni-2022-assortative-matching-london-season` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261110T053957Z |
| Date | 2026-11-10T05:39:57Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-1paper-all-modes-2026-11-09.json` |
| Artifacts | `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053957Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 2) |
| Final | **12/13** |
| Package files withheld | 120 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `treatment_married_commoner_table2_panelA_col1` | 0.005 (0.002) | 0.004534 | 9.32% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_heir_table2_panelA_col2` | -0.004 (0.002) | -0.003631 | 9.22% | ±0.002 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_abs_table2_panelA_col3` | 0.524 (0.196) | 0.570804 | 8.93% | ±0.196 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4` | -0.516 (0.225) | -0.46264 | 10.34% | ±0.225 (se_band) | PASS | PASS |
| `treatment_married_down_table2_panelA_col5` | 0.009 (0.003) | 0.008983 | 0.19% | ±0.003 (se_band) | PASS | PASS |
| `treatment_never_married_table2_panelA_col6` | 0.002 (0.002) | 0.002126 | 6.30% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_commoner_table2_panelB_col1` | 0.006 (0.002) | 0.006195 | 3.25% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_heir_table2_panelB_col2` | -0.005 (0.002) | -0.004689 | 6.22% | ±0.002 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_abs_table2_panelB_col3` | 0.512 (0.213) | 0.555599 | 8.52% | ±0.213 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4` | -0.537 (0.221) | -0.490665 | 8.63% | ±0.221 (se_band) | PASS | PASS |
| `n_obs_table2_panelA_baseline` | 644 | 644 | 0.00% | ±32.2 (relative) | PASS | PASS |
| `n_obs_table2_panelA_landholdings` | 324 | 324 | 0.00% | ±16.2 (relative) | PASS | PASS |
| `n_obs_table2_panelA_never_married` | 765 | 1740 | 127.45% | ±38.25 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 20,831 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053957Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 13,616 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053957Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053957Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 142 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053957Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 9,435 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053957Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 142 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053957Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,101 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053957Z/attempt-1/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053957Z/execution.json`
- [`output/script.R`](output/script.R) — 9,704 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053957Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053957Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,261 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053957Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 9,436 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/d4cae023b401f0bf13c4b075.json`
- [`output/answer-2.md`](output/answer-2.md) — 9,705 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/00955a9e1eb04a1ddb3bc567.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 1 | — | — | 0 |
| final | final | 0 | no | 10.9 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request d4cae023b401f0bf13c4b075: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request 00955a9e1eb04a1ddb3bc567: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
