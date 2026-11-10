# goni-2022-assortative-matching-london-season · blind · pipeline-desktop-opus-run2 · 20261110T053855Z

| | |
|---|---|
| Paper | `goni-2022-assortative-matching-london-season` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261110T053855Z |
| Date | 2026-11-10T05:38:55Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-all-modes-2026-11-09.json` |
| Artifacts | `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053855Z` |
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
| `treatment_married_commoner_table2_panelA_col1` | 0.005 (0.002) | 0.00453358 | 9.33% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_heir_table2_panelA_col2` | -0.004 (0.002) | -0.00363064 | 9.23% | ±0.002 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_abs_table2_panelA_col3` | 0.524 (0.196) | 0.581372 | 10.95% | ±0.196 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4` | -0.516 (0.225) | -0.472649 | 8.40% | ±0.225 (se_band) | PASS | PASS |
| `treatment_married_down_table2_panelA_col5` | 0.009 (0.003) | 0.00898313 | 0.19% | ±0.003 (se_band) | PASS | PASS |
| `treatment_never_married_table2_panelA_col6` | 0.002 (0.002) | 0.00188878 | 5.56% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_commoner_table2_panelB_col1` | 0.006 (0.002) | 0.00619501 | 3.25% | ±0.002 (se_band) | PASS | PASS |
| `treatment_married_heir_table2_panelB_col2` | -0.005 (0.002) | -0.00468867 | 6.23% | ±0.002 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_abs_table2_panelB_col3` | 0.512 (0.213) | 0.565456 | 10.44% | ±0.213 (se_band) | PASS | PASS |
| `treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4` | -0.537 (0.221) | -0.500887 | 6.72% | ±0.221 (se_band) | PASS | PASS |
| `n_obs_table2_panelA_baseline` | 644 | 644 | 0.00% | ±32.2 (relative) | PASS | PASS |
| `n_obs_table2_panelA_landholdings` | 324 | 324 | 0.00% | ±16.2 (relative) | PASS | PASS |
| `n_obs_table2_panelA_never_married` | 765 | 911 | 19.08% | ±38.25 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 20,831 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053855Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 16,284 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053855Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 73 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053855Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 5,621 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053855Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 8,793 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053855Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 5,621 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053855Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053855Z/attempt-1/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053855Z/execution.json`
- [`output/script.R`](output/script.R) — 9,022 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053855Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 812 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053855Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 820 bytes, from `benchmark/results/artifacts/goni-2022-assortative-matching-london-season/blind/pipeline/20261110T053855Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,794 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/d4cae023b401f0bf13c4b075.json`
- [`output/answer-2.md`](output/answer-2.md) — 9,023 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/5e34f8326f33671b8d7b3d68.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 139 | — | — | 0 |
| final | final | 0 | no | 11.2 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request d4cae023b401f0bf13c4b075: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request 5e34f8326f33671b8d7b3d68: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
