# acemoglu-2022-war-socialism-fascism · seeded · pipeline-desktop-opus · 20261023T063725Z

| | |
|---|---|
| Paper | `acemoglu-2022-war-socialism-fascism` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261023T063725Z |
| Date | 2026-10-23T06:37:25Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/seeded/pipeline/20261023T063725Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 12/12 |
| First scored | 12/12 (execution 1) |
| Final | **12/12** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `first_stage_casualties_table1_col1` | 0.12 (0.02) | 0.118643 | 1.13% | ±0.005 (printed_precision) | PASS | PASS |
| `first_stage_casualties_table1_col6` | 0.1 (0.01) | 0.097885 | 2.12% | ±0.005 (printed_precision) | PASS | PASS |
| `first_stage_fstat_table1_col6` | 50.59 | 50.5877 | 0.00% | ±0.5059 (relative) | PASS | PASS |
| `iv_violence_table2_panelA_col6` | 0.5 (0.2) | 0.499883 | 0.02% | ±0.01 (relative) | PASS | PASS |
| `iv_branches_table2_panelC_col6` | 0.5 (0.2) | 0.498394 | 0.32% | ±0.01 (relative) | PASS | PASS |
| `iv_fascist_vote1921_table3_panelA_col6` | 0.34 (0.18) | 0.336898 | 0.91% | ±0.0068 (relative) | PASS | PASS |
| `iv_fascist_vote1924_table3_panelC_col1` | 0.4 (0.17) | 0.395648 | 1.09% | ±0.008 (relative) | PASS | PASS |
| `iv_fascist_vote1924_table3_panelC_col6` | 0.51 (0.17) | 0.5126 | 0.51% | ±0.0102 (relative) | PASS | PASS |
| `n_obs_main_sample` | 5775 | 5775 | 0.00% | ±288.75 (relative) | PASS | PASS |
| `n_clusters_main_sample` | 181 | 181 | 0.00% | ±9.05 (relative) | PASS | PASS |
| `n_obs_fascist_vote1921` | 5358 | 5358 | 0.00% | ±267.9 (relative) | PASS | PASS |
| `n_clusters_fascist_vote1921` | 175 | 175 | 0.00% | ±8.75 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 116,203 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/seeded/pipeline/20261023T063725Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 5,046 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/seeded/pipeline/20261023T063725Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/seeded/pipeline/20261023T063725Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,088 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/seeded/pipeline/20261023T063725Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,047 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/68761d514f3142cbb1c4f48c.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 68761d514f3142cbb1c4f48c: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 1 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
