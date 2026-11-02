# carrera-2022-who-chooses-commitment · seeded · pipeline-desktop-opus-run2 · 20261102T091036Z

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261102T091036Z |
| Date | 2026-11-02T09:10:36Z |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/seeded/pipeline/20261102T091036Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 11/11 |
| First scored | 11/11 (execution 1) |
| Final | **11/11** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `bcp_basic_info_treatment_col1` | 0.3 (0.56) | 0.300805 | 0.27% | ±0.006 (relative) | PASS | PASS |
| `bcp_enhanced_info_treatment_col1` | 1.36 (0.57) | 1.35968 | 0.02% | ±0.0272 (relative) | PASS | PASS |
| `bcp_goal_minus_expected_attendance_col2` | 0.71 (0.29) | 0.707612 | 0.34% | ±0.0142 (relative) | PASS | PASS |
| `bcp_actual_minus_expected_attendance_col3` | 0.45 (0.22) | 0.447487 | 0.56% | ±0.009 (relative) | PASS | PASS |
| `bcp_regression_observations` | 1126 | 1126 | 0.00% | ±11.26 (relative) | PASS | PASS |
| `takeup_more_basic_info_treatment_col1` | -0.022 (0.041) | -0.021511 | 2.22% | ±0.0005 (printed_precision) | PASS | PASS |
| `takeup_more_enhanced_info_treatment_col1` | -0.08 (0.031) | -0.080176 | 0.22% | ±0.0016 (relative) | PASS | PASS |
| `takeup_more_behavior_change_premium_col2` | 0.027 (0.011) | 0.026744 | 0.95% | ±0.00054 (relative) | PASS | PASS |
| `takeup_more_goal_minus_expected_attendance_col3` | 0.038 (0.013) | 0.03821 | 0.55% | ±0.00076 (relative) | PASS | PASS |
| `takeup_more_actual_minus_expected_attendance_col4` | -0.043 (0.013) | -0.042759 | 0.56% | ±0.00086 (relative) | PASS | PASS |
| `takeup_more_regression_observations` | 2824 | 2824 | 0.00% | ±28.24 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 149,930 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/seeded/pipeline/20261102T091036Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 4,585 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/seeded/pipeline/20261102T091036Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/seeded/pipeline/20261102T091036Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 612 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/seeded/pipeline/20261102T091036Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 4,586 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/e569b1b899fbc80ec2eed7fa.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request e569b1b899fbc80ec2eed7fa: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 1 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
