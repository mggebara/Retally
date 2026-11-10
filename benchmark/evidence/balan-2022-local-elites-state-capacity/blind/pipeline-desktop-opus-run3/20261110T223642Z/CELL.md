# balan-2022-local-elites-state-capacity · blind · pipeline-desktop-opus-run3 · 20261110T223642Z

| | |
|---|---|
| Paper | `balan-2022-local-elites-state-capacity` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261110T223642Z |
| Date | 2026-11-10T22:36:42Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-1paper-balan-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223642Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 5/13 |
| First scored | 5/13 (execution 1) |
| Final | **5/13** |
| Package files withheld | 58 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `compliance_local_table4_panelA_col1` | 0.023 (0.008) | 0.0221372 | 3.75% | ±0.008 (se_band) | PASS | PASS |
| `compliance_local_table4_panelA_col2` | 0.032 (0.007) | 0.0137623 | 56.99% | ±0.007 (se_band) | FAIL | FAIL |
| `compliance_local_house_fe_table4_panelA_col4` | 0.033 (0.007) | 0.0137623 | 58.30% | ±0.007 (se_band) | FAIL | FAIL |
| `compliance_local_exempt_excluded_table4_panelA_col5` | 0.04 (0.008) | 0.0174829 | 56.29% | ±0.008 (se_band) | FAIL | FAIL |
| `revenue_local_table4_panelB_col2` | 79.64 (22.856) | 0.0137623 | 99.98% | ±22.856 (se_band) | FAIL | FAIL |
| `revenue_local_house_fe_table4_panelB_col4` | 68.855 (20.56) | 0.0137623 | 99.98% | ±20.56 (se_band) | FAIL | FAIL |
| `n_obs_table4_col1` | 28872 | 29418 | 1.89% | ±1443.6 (relative) | PASS | PASS |
| `n_obs_table4_col2` | 27764 | 29418 | 5.96% | ±1388.2 (relative) | FAIL | FAIL |
| `paid_bribe_endline_local_table5_panelB` | 0.018 (0.009) | 0.0206655 | 14.81% | ±0.009 (se_band) | PASS | PASS |
| `visited_by_collector_local_table6_col1` | -0.009 (0.026) | — | — | ±0.026 (se_band) | FAIL | FAIL |
| `compliance_cli_table7_col1` | 0.024 (0.009) | 0.0217862 | 9.22% | ±0.009 (se_band) | PASS | PASS |
| `revenue_cli_table7_col2` | 46.566 (21.2) | 0.0217862 | 99.95% | ±21.2 (se_band) | FAIL | FAIL |
| `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 (0.007) | 0.056897 | 1.60% | ±0.007 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 5/13 pass, which agrees with the row's 5/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 25,453 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223642Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223642Z/execution.json`
- [`output/script.R`](output/script.R) — 14,443 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223642Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 18,594 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223642Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 846 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223642Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 14,444 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/aa6e1e1170e985065a9375e2.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 16.8 | 12 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request aa6e1e1170e985065a9375e2: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
