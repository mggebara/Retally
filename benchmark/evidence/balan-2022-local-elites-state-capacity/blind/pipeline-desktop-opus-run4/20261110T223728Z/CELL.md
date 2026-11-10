# balan-2022-local-elites-state-capacity · blind · pipeline-desktop-opus-run4 · 20261110T223728Z

| | |
|---|---|
| Paper | `balan-2022-local-elites-state-capacity` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261110T223728Z |
| Date | 2026-11-10T22:37:28Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-1paper-balan-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223728Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 5/13 (execution 2) |
| Final | **5/13** |
| Package files withheld | 58 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `compliance_local_table4_panelA_col1` | 0.023 (0.008) | 0.0219043 | 4.76% | ±0.008 (se_band) | PASS | PASS |
| `compliance_local_table4_panelA_col2` | 0.032 (0.007) | 0.0214793 | 32.88% | ±0.007 (se_band) | FAIL | FAIL |
| `compliance_local_house_fe_table4_panelA_col4` | 0.033 (0.007) | 0.0215256 | 34.77% | ±0.007 (se_band) | FAIL | FAIL |
| `compliance_local_exempt_excluded_table4_panelA_col5` | 0.04 (0.008) | 0.0276118 | 30.97% | ±0.008 (se_band) | FAIL | FAIL |
| `revenue_local_table4_panelB_col2` | 79.64 (22.856) | 355.188 | 345.99% | ±22.856 (se_band) | FAIL | FAIL |
| `revenue_local_house_fe_table4_panelB_col4` | 68.855 (20.56) | 348.192 | 405.69% | ±20.56 (se_band) | FAIL | FAIL |
| `n_obs_table4_col1` | 28872 | 28702 | 0.59% | ±1443.6 (relative) | PASS | PASS |
| `n_obs_table4_col2` | 27764 | 17195 | 38.07% | ±1388.2 (relative) | FAIL | FAIL |
| `paid_bribe_endline_local_table5_panelB` | 0.018 (0.009) | 0.0108513 | 39.72% | ±0.009 (se_band) | PASS | PASS |
| `visited_by_collector_local_table6_col1` | -0.009 (0.026) | -0.0280717 | 211.91% | ±0.026 (se_band) | PASS | PASS |
| `compliance_cli_table7_col1` | 0.024 (0.009) | 0.00554326 | 76.90% | ±0.009 (se_band) | FAIL | FAIL |
| `revenue_cli_table7_col2` | 46.566 (21.2) | 0.990572 | 97.87% | ±21.2 (se_band) | FAIL | FAIL |
| `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 (0.007) | 0.0560212 | 0.04% | ±0.007 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 5/13 pass, which agrees with the row's 5/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 25,453 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223728Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 22,303 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223728Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223728Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 2,592 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223728Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 13,804 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223728Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 2,592 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223728Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 3,975 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223728Z/attempt-1/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223728Z/execution.json`
- [`output/script.R`](output/script.R) — 15,471 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223728Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 146 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223728Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 5,264 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/pipeline/20261110T223728Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 13,805 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/aa6e1e1170e985065a9375e2.json`
- [`output/answer-2.md`](output/answer-2.md) — 15,472 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/f12bb3740d76d075f0bd4bb5.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 0 | — | — | 0 |
| final | final | 0 | no | 16.9 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request aa6e1e1170e985065a9375e2: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run4 (request f12bb3740d76d075f0bd4bb5: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
