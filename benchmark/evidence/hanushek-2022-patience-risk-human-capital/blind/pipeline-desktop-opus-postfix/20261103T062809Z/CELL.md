# hanushek-2022-patience-risk-human-capital · blind · pipeline-desktop-opus-postfix · 20261103T062809Z

| | |
|---|---|
| Paper | `hanushek-2022-patience-risk-human-capital` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T062809Z |
| Date | 2026-11-03T06:28:09Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/hanushek-2022-patience-risk-human-capital/blind/pipeline/20261103T062809Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 9/13 |
| First scored | 9/13 (execution 1) |
| Final | **9/13** |
| Package files withheld | 21 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `table1_col3_patience` | 1.226 (0.132) | 1.2195 | 0.53% | ±0.132 (se_band) | PASS | PASS |
| `table1_col3_risk_taking` | -1.241 (0.184) | -1.23194 | 0.73% | ±0.184 (se_band) | PASS | PASS |
| `table1_col1_patience` | 0.917 (0.127) | 0.912826 | 0.46% | ±0.127 (se_band) | PASS | PASS |
| `table1_col2_risk_taking` | -0.482 (0.261) | -0.47571 | 1.30% | ±0.261 (se_band) | PASS | PASS |
| `table1_col5_natives_patience` | 1.296 (0.133) | 1.29583 | 0.01% | ±0.133 (se_band) | PASS | PASS |
| `table1_col5_natives_risk_taking` | -1.32 (0.189) | -1.32034 | 0.03% | ±0.189 (se_band) | PASS | PASS |
| `table1_col3_observations` | 1.99228e+06 | 1.99228e+06 | 0.00% | ±99613.8 (relative) | PASS | PASS |
| `table2_col3_patience` | 0.931 (0.116) | 0.333403 | 64.19% | ±0.116 (se_band) | FAIL | FAIL |
| `table2_col3_risk_taking` | -0.294 (0.122) | -0.231388 | 21.30% | ±0.122 (se_band) | PASS | PASS |
| `table2_col1_patience` | 0.779 (0.115) | 0.259798 | 66.65% | ±0.115 (se_band) | FAIL | FAIL |
| `table2_col4_patience` | 1.032 (0.133) | 0.442287 | 57.14% | ±0.133 (se_band) | FAIL | FAIL |
| `table2_col4_risk_taking` | -0.449 (0.14) | -0.232767 | 48.16% | ±0.14 (se_band) | FAIL | FAIL |
| `table2_col3_observations` | 80398 | 80397 | 0.00% | ±4019.9 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/13 pass, which agrees with the row's 9/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 34,463 bytes, from `benchmark/results/artifacts/hanushek-2022-patience-risk-human-capital/blind/pipeline/20261103T062809Z/prompt-1.txt`

## What it produced

- [`output/samples.txt`](output/samples.txt) — 472 bytes, from `benchmark/results/artifacts/hanushek-2022-patience-risk-human-capital/blind/pipeline/20261103T062809Z/samples.txt`
- [`output/script.R`](output/script.R) — 7,742 bytes, from `benchmark/results/artifacts/hanushek-2022-patience-risk-human-capital/blind/pipeline/20261103T062809Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 180 bytes, from `benchmark/results/artifacts/hanushek-2022-patience-risk-human-capital/blind/pipeline/20261103T062809Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,052 bytes, from `benchmark/results/artifacts/hanushek-2022-patience-risk-human-capital/blind/pipeline/20261103T062809Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,743 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/b4d0fa9d7660bc0f13862066.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request b4d0fa9d7660bc0f13862066: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
