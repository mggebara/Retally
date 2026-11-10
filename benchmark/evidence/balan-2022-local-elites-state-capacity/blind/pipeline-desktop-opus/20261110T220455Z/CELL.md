# balan-2022-local-elites-state-capacity · blind · pipeline-desktop-opus · 20261110T220455Z

| | |
|---|---|
| Paper | `balan-2022-local-elites-state-capacity` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261110T220455Z |
| Date | 2026-11-10T22:04:55Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-balan-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T220455Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 2/13 |
| First scored | 2/13 (execution 1) |
| Final | **2/13** |
| Package files withheld | 58 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `compliance_local_table4_panelA_col1` | 0.023 (0.008) | 0.0426194 | 85.30% | ±0.008 (se_band) | FAIL | FAIL |
| `compliance_local_table4_panelA_col2` | 0.032 (0.007) | 0.0444358 | 38.86% | ±0.007 (se_band) | FAIL | FAIL |
| `compliance_local_house_fe_table4_panelA_col4` | 0.033 (0.007) | 0.0454258 | 37.65% | ±0.007 (se_band) | FAIL | FAIL |
| `compliance_local_exempt_excluded_table4_panelA_col5` | 0.04 (0.008) | 0.0528957 | 32.24% | ±0.008 (se_band) | FAIL | FAIL |
| `revenue_local_table4_panelB_col2` | 79.64 (22.856) | 226.183 | 184.01% | ±22.856 (se_band) | FAIL | FAIL |
| `revenue_local_house_fe_table4_panelB_col4` | 68.855 (20.56) | 179.581 | 160.81% | ±20.56 (se_band) | FAIL | FAIL |
| `n_obs_table4_col1` | 28872 | 24262 | 15.97% | ±1443.6 (relative) | FAIL | FAIL |
| `n_obs_table4_col2` | 27764 | 23532 | 15.24% | ±1388.2 (relative) | FAIL | FAIL |
| `paid_bribe_endline_local_table5_panelB` | 0.018 (0.009) | 0.0301204 | 67.34% | ±0.009 (se_band) | FAIL | FAIL |
| `visited_by_collector_local_table6_col1` | -0.009 (0.026) | -0.010305 | 14.50% | ±0.026 (se_band) | PASS | PASS |
| `compliance_cli_table7_col1` | 0.024 (0.009) | 0.0107391 | 55.25% | ±0.009 (se_band) | FAIL | FAIL |
| `revenue_cli_table7_col2` | 46.566 (21.2) | 23.9837 | 48.50% | ±21.2 (se_band) | FAIL | FAIL |
| `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 (0.007) | 0.0585854 | 4.62% | ±0.007 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 2/13 pass, which agrees with the row's 2/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 25,453 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T220455Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T220455Z/execution.json`
- [`output/script.R`](output/script.R) — 16,925 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T220455Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 72 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T220455Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 9,977 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T220455Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 16,926 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/aa6e1e1170e985065a9375e2.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 16.9 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request aa6e1e1170e985065a9375e2: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
