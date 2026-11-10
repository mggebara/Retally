# greenstone-2022-china-pollution-monitoring-automation · blind · pipeline-desktop-opus · 20261110T055406Z

| | |
|---|---|
| Paper | `greenstone-2022-china-pollution-monitoring-automation` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261110T055406Z |
| Date | 2026-11-10T05:54:06Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-greenstone-all-modes-2026-11-09.json` |
| Artifacts | `benchmark/results/artifacts/greenstone-2022-china-pollution-monitoring-automation/blind/pipeline/20261110T055406Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 10/13 |
| First scored | 10/13 (execution 1) |
| Final | **10/13** |
| Package files withheld | 7 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `rd_pm_daily_no_controls_table1_panelA_col1` | 34.7 (10.7) | 43.4165 | 25.12% | ±10.7 (se_band) | PASS | PASS |
| `rd_pm_daily_controls_table1_panelA_col2` | 34.9 (5.8) | 27.5032 | 21.19% | ±5.8 (se_band) | FAIL | FAIL |
| `rd_pm_daily_wave1_table1_panelA_col3` | 27.5 (9.8) | 31.2426 | 13.61% | ±9.8 (se_band) | PASS | PASS |
| `rd_pm_daily_wave2_table1_panelA_col4` | 64.7 (9.9) | 60.0978 | 7.11% | ±9.9 (se_band) | PASS | PASS |
| `rd_pm_daily_deadline_table1_panelA_col5` | 57.1 (8.6) | 54.9848 | 3.70% | ±8.6 (se_band) | PASS | PASS |
| `rd_aod_monthly_controls_table1_panelA_col2` | -0.005 (0.021) | — | — | ±0.021 (se_band) | FAIL | FAIL |
| `event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1` | 60.3 (11) | 60.2488 | 0.08% | ±11 (se_band) | PASS | PASS |
| `event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2` | 31.4 (11.1) | 32.1379 | 2.35% | ±11.1 (se_band) | PASS | PASS |
| `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3` | 66.5 (14.3) | 53.5308 | 19.50% | ±14.3 (se_band) | PASS | PASS |
| `event_study_log_pm_1_2_months_after_matched_table1_panelB_col5` | 0.24 (0.09) | 0.181913 | 24.20% | ±0.09 (se_band) | PASS | PASS |
| `n_obs_table1_panelB_deadline_cols1_2` | 176426 | 164055 | 7.01% | ±8821.3 (relative) | FAIL | FAIL |
| `rd_face_mask_searches_controls_table2_panelA_col2` | 11.03 (1.66) | 9.99468 | 9.39% | ±1.66 (se_band) | PASS | PASS |
| `rd_air_filter_searches_controls_table2_panelA_col2` | 8.73 (1.86) | 7.99917 | 8.37% | ±1.86 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/13 pass, which agrees with the row's 10/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 21,972 bytes, from `benchmark/results/artifacts/greenstone-2022-china-pollution-monitoring-automation/blind/pipeline/20261110T055406Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/greenstone-2022-china-pollution-monitoring-automation/blind/pipeline/20261110T055406Z/execution.json`
- [`output/script.R`](output/script.R) — 9,327 bytes, from `benchmark/results/artifacts/greenstone-2022-china-pollution-monitoring-automation/blind/pipeline/20261110T055406Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 3,411 bytes, from `benchmark/results/artifacts/greenstone-2022-china-pollution-monitoring-automation/blind/pipeline/20261110T055406Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,854 bytes, from `benchmark/results/artifacts/greenstone-2022-china-pollution-monitoring-automation/blind/pipeline/20261110T055406Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 9,328 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/c46d37e11180c4ff2915e935.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 34.0 | 12 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request c46d37e11180c4ff2915e935: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
