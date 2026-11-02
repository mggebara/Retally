# carrera-2022-who-chooses-commitment · blind · pipeline-desktop-opus · 20261102T055735Z

| | |
|---|---|
| Paper | `carrera-2022-who-chooses-commitment` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261102T055735Z |
| Date | 2026-11-02T05:57:35Z |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261102T055735Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 0/11 (execution 1) |
| Final | **0/11** |
| Package files withheld | 28 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `bcp_basic_info_treatment_col1` | 0.3 (0.56) | — | — | ±0.56 (se_band) | FAIL | FAIL |
| `bcp_enhanced_info_treatment_col1` | 1.36 (0.57) | — | — | ±0.57 (se_band) | FAIL | FAIL |
| `bcp_goal_minus_expected_attendance_col2` | 0.71 (0.29) | — | — | ±0.29 (se_band) | FAIL | FAIL |
| `bcp_actual_minus_expected_attendance_col3` | 0.45 (0.22) | — | — | ±0.22 (se_band) | FAIL | FAIL |
| `bcp_regression_observations` | 1126 | 0 | 100.00% | ±11.26 (relative) | FAIL | FAIL |
| `takeup_more_basic_info_treatment_col1` | -0.022 (0.041) | — | — | ±0.041 (se_band) | FAIL | FAIL |
| `takeup_more_enhanced_info_treatment_col1` | -0.08 (0.031) | — | — | ±0.031 (se_band) | FAIL | FAIL |
| `takeup_more_behavior_change_premium_col2` | 0.027 (0.011) | — | — | ±0.011 (se_band) | FAIL | FAIL |
| `takeup_more_goal_minus_expected_attendance_col3` | 0.038 (0.013) | — | — | ±0.013 (se_band) | FAIL | FAIL |
| `takeup_more_actual_minus_expected_attendance_col4` | -0.043 (0.013) | — | — | ±0.013 (se_band) | FAIL | FAIL |
| `takeup_more_regression_observations` | 2824 | 0 | 100.00% | ±28.24 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 0/11 pass, which agrees with the row's 0/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 21,795 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261102T055735Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 6,410 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261102T055735Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261102T055735Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,565 bytes, from `benchmark/results/artifacts/carrera-2022-who-chooses-commitment/blind/pipeline/20261102T055735Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,411 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/2e5b2dcebd231b614f3d9f60.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 2e5b2dcebd231b614f3d9f60: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
