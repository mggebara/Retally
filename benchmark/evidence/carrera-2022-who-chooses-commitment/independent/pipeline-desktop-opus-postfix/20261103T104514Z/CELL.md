# carrera-2022-who-chooses-commitment · independent · pipeline-desktop-opus-postfix · 20261103T104514Z

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T104514Z |
| Date | 2026-11-03T10:45:14Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z` |
| Executions | 5 |
| Refinements | 4 (3 error + 1 claim) |
| First attempt | 0/11 |
| First scored | 9/11 (execution 4) |
| Final | **9/11** |
| Package files withheld | 29 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `bcp_basic_info_treatment_col1` | 0.3 (0.56) | 0.203245 | 32.25% | ±0.56 (se_band) | PASS | PASS |
| `bcp_enhanced_info_treatment_col1` | 1.36 (0.57) | 1.24777 | 8.25% | ±0.57 (se_band) | PASS | PASS |
| `bcp_goal_minus_expected_attendance_col2` | 0.71 (0.29) | 0.767551 | 8.11% | ±0.29 (se_band) | PASS | PASS |
| `bcp_actual_minus_expected_attendance_col3` | 0.45 (0.22) | 0.482836 | 7.30% | ±0.22 (se_band) | PASS | PASS |
| `bcp_regression_observations` | 1126 | 1150 | 2.13% | ±56.3 (relative) | PASS | PASS |
| `takeup_more_basic_info_treatment_col1` | -0.022 (0.041) | -0.074115 | 236.89% | ±0.041 (se_band) | FAIL | FAIL |
| `takeup_more_enhanced_info_treatment_col1` | -0.08 (0.031) | -0.076303 | 4.62% | ±0.031 (se_band) | PASS | PASS |
| `takeup_more_behavior_change_premium_col2` | 0.027 (0.011) | 0.02552 | 5.48% | ±0.011 (se_band) | PASS | PASS |
| `takeup_more_goal_minus_expected_attendance_col3` | 0.038 (0.013) | 0.034235 | 9.91% | ±0.013 (se_band) | PASS | PASS |
| `takeup_more_actual_minus_expected_attendance_col4` | -0.043 (0.013) | -0.052659 | 22.46% | ±0.013 (se_band) | PASS | PASS |
| `takeup_more_regression_observations` | 2824 | 1150 | 59.28% | ±141.2 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/11 pass, which agrees with the row's 9/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) no wave-3 commitment-assignment rule gives exactly 1126; using rule 'inc_not07'

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 28,267 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 13,554 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 14,628 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 16,113 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 28,064 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 176 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 241 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 10,621 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 176 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 750 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 212 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-2/feedback.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 241 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 11,593 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 212 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 816 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 212 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-3/feedback.txt`
- [`output/attempt-3/samples.txt`](output/attempt-3/samples.txt) — 241 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-3/samples.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 13,019 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 212 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 875 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-3/stdout.txt`
- [`output/attempt-4/samples.txt`](output/attempt-4/samples.txt) — 264 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-4/samples.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 17,658 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 116 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 1,748 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/attempt-4/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 359 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/samples.txt`
- [`output/script.R`](output/script.R) — 16,018 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,434 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261103T104514Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,622 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/d7eb20a522f2d61319c17db4.json`
- [`output/answer-2.md`](output/answer-2.md) — 11,594 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/d9817a803e3b5ee0819a424e.json`
- [`output/answer-3.md`](output/answer-3.md) — 13,020 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/bfee9b901f30562baf4ca1a1.json`
- [`output/answer-4.md`](output/answer-4.md) — 16,019 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/b3bd16aaa359b0646727c892.json`
- [`output/answer-5.md`](output/answer-5.md) — 17,659 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/3f962099661f3c70c3a3d1d3.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request d7eb20a522f2d61319c17db4: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix (request d9817a803e3b5ee0819a424e: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix (request bfee9b901f30562baf4ca1a1: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-postfix (request b3bd16aaa359b0646727c892: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus-postfix (request 3f962099661f3c70c3a3d1d3: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 5 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
