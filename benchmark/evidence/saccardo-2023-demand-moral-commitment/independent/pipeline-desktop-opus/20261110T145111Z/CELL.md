# saccardo-2023-demand-moral-commitment · independent · pipeline-desktop-opus · 20261110T145111Z

| | |
|---|---|
| Paper | `saccardo-2023-demand-moral-commitment` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261110T145111Z |
| Date | 2026-11-10T14:51:11Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-saccardo-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 4/13 |
| First scored | 4/13 (execution 1) |
| Final | **12/13** |
| Package files withheld | 4 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `see_incentive_first_costly_table2_col1` | -0.139 (0.018) | -0.144685 | 4.09% | ±0.018 (se_band) | PASS | PASS |
| `assess_quality_first_costly_table2_col1` | 0.152 (0.029) | 0.064438 | 57.61% | ±0.029 (se_band) | FAIL | FAIL |
| `choice_free_professionals_table2_col1` | -0.095 (0.026) | -0.074719 | 21.35% | ±0.026 (se_band) | PASS | FAIL |
| `selfishness_table2_col2` | 0.028 (0.007) | 0.030831 | 10.11% | ±0.007 (se_band) | PASS | FAIL |
| `selfishness_table2_col3` | 0.039 (0.009) | 0.042461 | 8.87% | ±0.009 (se_band) | PASS | FAIL |
| `see_incentive_first_costly_x_selfishness_table2_col3` | -0.022 (0.016) | -0.024351 | 10.69% | ±0.016 (se_band) | PASS | FAIL |
| `see_quality_first_costly_x_selfishness_table2_col3` | -0.021 (0.018) | -0.021486 | 2.31% | ±0.018 (se_band) | PASS | FAIL |
| `n_obs_table2_col1` | 5908 | 5915 | 0.12% | ±295.4 (relative) | PASS | FAIL |
| `n_obs_table2_cols2_3` | 5196 | 5203 | 0.13% | ±259.8 (relative) | PASS | FAIL |
| `prefer_see_incentive_first_assigned_table3_col1` | 0.195 (0.016) | 0.200532 | 2.84% | ±0.016 (se_band) | PASS | PASS |
| `prefer_see_incentive_first_not_assigned_table3_col2` | 0.003 (0.029) | 0.012459 | 315.30% | ±0.029 (se_band) | PASS | PASS |
| `prefer_see_incentive_first_x_not_assigned_table3_col3` | -0.14 (0.026) | -0.140953 | 0.68% | ±0.026 (se_band) | PASS | PASS |
| `n_obs_table3_col1` | 4448 | 4450 | 0.04% | ±222.4 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Multiple switchers identified as non-professional advisors with a missing selfishness (MPL) measure; High Stakes arms dropped via highx10/highx100 flags

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 24,078 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 26,889 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 25,190 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 24,914 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 72 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 837 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 9,591 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 8,617 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 657 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 8,506 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 5,174 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 215 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 8,275 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 5,472 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/attempt-3/stdout.txt`
- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/execution.json`
- [`output/script.R`](output/script.R) — 8,948 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 6,075 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T145111Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 9,592 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/5d1e11eae709ef1a881593d5.json`
- [`output/answer-2.md`](output/answer-2.md) — 8,507 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/b9ba5c8ad0b26f3153012ed2.json`
- [`output/answer-3.md`](output/answer-3.md) — 8,276 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/4ad087568f551611a5d025e4.json`
- [`output/answer-4.md`](output/answer-4.md) — 8,949 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/9734140ed29781b8fd1dca13.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | claim | 0 | — | — | 13 |
| attempt-2 | claim | 0 | — | — | 13 |
| attempt-3 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 1.4 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 5d1e11eae709ef1a881593d5: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request b9ba5c8ad0b26f3153012ed2: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus (request 4ad087568f551611a5d025e4: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus (request 9734140ed29781b8fd1dca13: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
