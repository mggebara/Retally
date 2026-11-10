# saccardo-2023-demand-moral-commitment · independent · pipeline-desktop-opus-run4 · 20261110T164051Z

| | |
|---|---|
| Paper | `saccardo-2023-demand-moral-commitment` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261110T164051Z |
| Date | 2026-11-10T16:40:51Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-1paper-saccardo-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z` |
| Executions | 5 |
| Refinements | 4 (1 error + 3 claim) |
| First attempt | 0/13 |
| First scored | 4/13 (execution 2) |
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
| `n_obs_table2_cols2_3` | 5196 | 5203 | 0.13% | ±259.8 (relative) | PASS | PASS |
| `prefer_see_incentive_first_assigned_table3_col1` | 0.195 (0.016) | 0.204807 | 5.03% | ±0.016 (se_band) | PASS | FAIL |
| `prefer_see_incentive_first_not_assigned_table3_col2` | 0.003 (0.029) | 0.009275 | 209.17% | ±0.029 (se_band) | PASS | PASS |
| `prefer_see_incentive_first_x_not_assigned_table3_col3` | -0.14 (0.026) | -0.145022 | 3.59% | ±0.026 (se_band) | PASS | PASS |
| `n_obs_table3_col1` | 4448 | 4450 | 0.04% | ±222.4 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Advisors with missing attention flag (Professionals sample) treated as attentive so that professionals are retained
- (DEVIATION: line) Multiple switchers identified as non-professional advisors with missing selfishness (MPL) measure
- (DEVIATION: line) Controls restricted to design-variation controls (probabilistic payment, left position, their interaction) per fn. 14

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 24,078 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 18,333 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 28,601 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 25,831 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 24,001 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 32 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 10,334 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 8,408 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 875 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 11,370 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 10,577 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 735 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 8,586 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 5,720 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-3/stdout.txt`
- [`output/attempt-4/execution.json`](output/attempt-4/execution.json) — 72 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-4/execution.json`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 515 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 8,363 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 4,107 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/attempt-4/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/execution.json`
- [`output/script.R`](output/script.R) — 10,915 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,958 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/pipeline/20261110T164051Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,335 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/5d1e11eae709ef1a881593d5.json`
- [`output/answer-2.md`](output/answer-2.md) — 11,371 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/a08cc82b09a96216d866ca42.json`
- [`output/answer-3.md`](output/answer-3.md) — 8,587 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/e5402b898af07567f2057c0b.json`
- [`output/answer-4.md`](output/answer-4.md) — 8,364 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/0d54b9db0ba111df8463fda9.json`
- [`output/answer-5.md`](output/answer-5.md) — 10,916 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/174b4893d13020a73d2d6e8e.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 0 | — | — | 0 |
| attempt-2 | claim | 0 | — | — | 12 |
| attempt-3 | claim | 0 | — | — | 12 |
| attempt-4 | claim | 0 | — | — | 11 |
| final | final | 0 | no | 1.5 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request 5d1e11eae709ef1a881593d5: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run4 (request a08cc82b09a96216d866ca42: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run4 (request e5402b898af07567f2057c0b: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run4 (request 0d54b9db0ba111df8463fda9: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus-run4 (request 174b4893d13020a73d2d6e8e: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 5 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
