# acemoglu-2022-war-socialism-fascism · blind · pipeline-desktop-opus-postfix · 20261103T062809Z

| | |
|---|---|
| Paper | `acemoglu-2022-war-socialism-fascism` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T062809Z |
| Date | 2026-11-03T06:28:09Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/pipeline/20261103T062809Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 7/12 |
| First scored | 7/12 (execution 1) |
| Final | **7/12** |
| Package files withheld | 21 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `first_stage_casualties_table1_col1` | 0.12 (0.02) | 0.0883369 | 26.39% | ±0.02 (se_band) | FAIL | FAIL |
| `first_stage_casualties_table1_col6` | 0.1 (0.01) | 0.0838554 | 16.14% | ±0.01 (se_band) | FAIL | FAIL |
| `first_stage_fstat_table1_col6` | 50.59 | 43.3196 | 14.37% | ±0.5059 (relative) | FAIL | FAIL |
| `iv_violence_table2_panelA_col6` | 0.5 (0.2) | 0.396322 | 20.74% | ±0.2 (se_band) | PASS | PASS |
| `iv_branches_table2_panelC_col6` | 0.5 (0.2) | 0.243603 | 51.28% | ±0.2 (se_band) | FAIL | FAIL |
| `iv_fascist_vote1921_table3_panelA_col6` | 0.34 (0.18) | 0.27294 | 19.72% | ±0.18 (se_band) | PASS | PASS |
| `iv_fascist_vote1924_table3_panelC_col1` | 0.4 (0.17) | 0.329434 | 17.64% | ±0.17 (se_band) | PASS | PASS |
| `iv_fascist_vote1924_table3_panelC_col6` | 0.51 (0.17) | 0.20142 | 60.51% | ±0.17 (se_band) | FAIL | FAIL |
| `n_obs_main_sample` | 5775 | 5772 | 0.05% | ±288.75 (relative) | PASS | PASS |
| `n_clusters_main_sample` | 181 | 178 | 1.66% | ±9.05 (relative) | PASS | PASS |
| `n_obs_fascist_vote1921` | 5358 | 5354 | 0.07% | ±267.9 (relative) | PASS | PASS |
| `n_clusters_fascist_vote1921` | 175 | 171 | 2.29% | ±8.75 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/12 pass, which agrees with the row's 7/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,879 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/pipeline/20261103T062809Z/prompt-1.txt`

## What it produced

- [`output/samples.txt`](output/samples.txt) — 363 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/pipeline/20261103T062809Z/samples.txt`
- [`output/script.R`](output/script.R) — 9,743 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/pipeline/20261103T062809Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/pipeline/20261103T062809Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,025 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/pipeline/20261103T062809Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 9,744 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/f8f5368529f1c256853ac0ad.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request f8f5368529f1c256853ac0ad: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
