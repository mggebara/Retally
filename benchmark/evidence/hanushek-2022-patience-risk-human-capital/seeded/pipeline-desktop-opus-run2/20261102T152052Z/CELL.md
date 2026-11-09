# hanushek-2022-patience-risk-human-capital · seeded · pipeline-desktop-opus-run2 · 20261102T152052Z

| | |
|---|---|
| Paper | `hanushek-2022-patience-risk-human-capital` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261102T152052Z |
| Date | 2026-11-02T15:20:52Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/hanushek-2022-patience-risk-human-capital/seeded/pipeline/20261102T152052Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 13/13 |
| First scored | 13/13 (execution 1) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `table1_col3_patience` | 1.226 (0.132) | 1.22593 | 0.01% | ±0.02452 (relative) | PASS | PASS |
| `table1_col3_risk_taking` | -1.241 (0.184) | -1.2413 | 0.02% | ±0.02482 (relative) | PASS | PASS |
| `table1_col1_patience` | 0.917 (0.127) | 0.917299 | 0.03% | ±0.01834 (relative) | PASS | PASS |
| `table1_col2_risk_taking` | -0.482 (0.261) | -0.481559 | 0.09% | ±0.00964 (relative) | PASS | PASS |
| `table1_col5_natives_patience` | 1.296 (0.133) | 1.29583 | 0.01% | ±0.02592 (relative) | PASS | PASS |
| `table1_col5_natives_risk_taking` | -1.32 (0.189) | -1.32034 | 0.03% | ±0.0264 (relative) | PASS | PASS |
| `table1_col3_observations` | 1.99228e+06 | 1.99228e+06 | 0.00% | ±99613.8 (relative) | PASS | PASS |
| `table2_col3_patience` | 0.931 (0.116) | 0.930657 | 0.04% | ±0.01862 (relative) | PASS | PASS |
| `table2_col3_risk_taking` | -0.294 (0.122) | -0.293956 | 0.01% | ±0.00588 (relative) | PASS | PASS |
| `table2_col1_patience` | 0.779 (0.115) | 0.778733 | 0.03% | ±0.01558 (relative) | PASS | PASS |
| `table2_col4_patience` | 1.032 (0.133) | 1.03244 | 0.04% | ±0.02064 (relative) | PASS | PASS |
| `table2_col4_risk_taking` | -0.449 (0.14) | -0.448965 | 0.01% | ±0.00898 (relative) | PASS | PASS |
| `table2_col3_observations` | 80398 | 80398 | 0.00% | ±4019.9 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 218,914 bytes, from `benchmark/results/artifacts/hanushek-2022-patience-risk-human-capital/seeded/pipeline/20261102T152052Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 5,975 bytes, from `benchmark/results/artifacts/hanushek-2022-patience-risk-human-capital/seeded/pipeline/20261102T152052Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/hanushek-2022-patience-risk-human-capital/seeded/pipeline/20261102T152052Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,007 bytes, from `benchmark/results/artifacts/hanushek-2022-patience-risk-human-capital/seeded/pipeline/20261102T152052Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,976 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/57a53b7d38c5aa7cad2464e2.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 57a53b7d38c5aa7cad2464e2: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 1 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
