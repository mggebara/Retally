# carrera-2022-who-chooses-commitment · independent · pipeline-desktop-opus-postfix2 · 20261105T212407Z

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261105T212407Z |
| Date | 2026-11-05T21:24:07Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z` |
| Executions | 4 |
| Refinements | 3 (3 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 0/11 (execution 1) |
| Final | **0/11** |
| Package files withheld | 29 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `bcp_basic_info_treatment_col1` | 0.3 (0.56) | — | — | ±0.56 (se_band) | FAIL | FAIL |
| `bcp_enhanced_info_treatment_col1` | 1.36 (0.57) | — | — | ±0.57 (se_band) | FAIL | FAIL |
| `bcp_goal_minus_expected_attendance_col2` | 0.71 (0.29) | — | — | ±0.29 (se_band) | FAIL | FAIL |
| `bcp_actual_minus_expected_attendance_col3` | 0.45 (0.22) | — | — | ±0.22 (se_band) | FAIL | FAIL |
| `bcp_regression_observations` | 1126 | — | — | ±56.3 (relative) | FAIL | FAIL |
| `takeup_more_basic_info_treatment_col1` | -0.022 (0.041) | — | — | ±0.041 (se_band) | FAIL | FAIL |
| `takeup_more_enhanced_info_treatment_col1` | -0.08 (0.031) | — | — | ±0.031 (se_band) | FAIL | FAIL |
| `takeup_more_behavior_change_premium_col2` | 0.027 (0.011) | — | — | ±0.011 (se_band) | FAIL | FAIL |
| `takeup_more_goal_minus_expected_attendance_col3` | 0.038 (0.013) | — | — | ±0.013 (se_band) | FAIL | FAIL |
| `takeup_more_actual_minus_expected_attendance_col4` | -0.043 (0.013) | — | — | ±0.013 (se_band) | FAIL | FAIL |
| `takeup_more_regression_observations` | 2824 | — | — | ±141.2 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 0/11 pass, which agrees with the row's 0/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 28,267 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 10,167 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 9,981 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 12,004 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 101 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 7,891 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 101 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 168 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 60 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 7,982 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 60 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 324 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/attempt-3/feedback.txt`
- [`output/attempt-3/samples.txt`](output/attempt-3/samples.txt) — 55 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/attempt-3/samples.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 9,409 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 324 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 264 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/attempt-3/stdout.txt`
- [`output/script.R`](output/script.R) — 9,722 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,018 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 84 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/independent/pipeline/20261105T212407Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,892 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/d7eb20a522f2d61319c17db4.json`
- [`output/answer-2.md`](output/answer-2.md) — 7,983 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/8722f1bcba510baae1a82bf3.json`
- [`output/answer-3.md`](output/answer-3.md) — 9,410 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/6b36011d821358816c9c2de9.json`
- [`output/answer-4.md`](output/answer-4.md) — 9,723 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/2396e6e7441a39fcb7bd54df.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request d7eb20a522f2d61319c17db4: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix2 (request 8722f1bcba510baae1a82bf3: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix2 (request 6b36011d821358816c9c2de9: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-postfix2 (request 2396e6e7441a39fcb7bd54df: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
