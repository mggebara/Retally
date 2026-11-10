# ambuehl-2022-deliberative-competence-financial-choice · blind · pipeline-desktop-opus-run3 · 20261110T070218Z

| | |
|---|---|
| Paper | `ambuehl-2022-deliberative-competence-financial-choice` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261110T070218Z |
| Date | 2026-11-10T07:02:18Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-1paper-ambuehl-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/ambuehl-2022-deliberative-competence-financial-choice/blind/pipeline/20261110T070218Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 0/13 (execution 1) |
| Final | **0/13** |
| Package files withheld | 5 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `test_score_compounding_treatment_minus_control_expA_table4_col1` | 1.442 (0.194) | -0.52335 | 136.29% | ±0.194 (se_band) | FAIL | FAIL |
| `test_score_compounding_treatment_minus_control_expB_table4_col2` | 1.601 (0.143) | — | — | ±0.143 (se_band) | FAIL | FAIL |
| `test_score_control_module_treatment_minus_control_expA_table4_col3` | -1.058 (0.146) | -0.0309158 | 97.08% | ±0.146 (se_band) | FAIL | FAIL |
| `test_score_control_module_treatment_minus_control_expB_table4_col4` | -0.374 (0.141) | — | — | ±0.141 (se_band) | FAIL | FAIL |
| `n_obs_table4_expA_cols1_3` | 215 | 611 | 184.19% | ±10.75 (relative) | FAIL | FAIL |
| `n_obs_table4_expB_cols2_4` | 348 | — | — | ±17.4 (relative) | FAIL | FAIL |
| `deliberative_competence_control_expA_table7_col1` | -24.448 (1.633) | — | — | ±1.633 (se_band) | FAIL | FAIL |
| `deliberative_competence_treatment_expA_table7_col1` | -22.864 (1.741) | — | — | ±1.741 (se_band) | FAIL | FAIL |
| `deliberative_competence_substance_only_expA_table7_col1` | -22.012 (1.433) | — | — | ±1.433 (se_band) | FAIL | FAIL |
| `deliberative_competence_rhetoric_only_expA_table7_col1` | -19.797 (1.406) | — | — | ±1.406 (se_band) | FAIL | FAIL |
| `deliberative_competence_control_expB_table7_col2` | -25.673 (1.357) | — | — | ±1.357 (se_band) | FAIL | FAIL |
| `deliberative_competence_treatment_expB_table7_col2` | -18.569 (1.177) | — | — | ±1.177 (se_band) | FAIL | FAIL |
| `n_obs_table7_expA_col1` | 4550 | — | — | ±227.5 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 0/13 pass, which agrees with the row's 0/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,764 bytes, from `benchmark/results/artifacts/ambuehl-2022-deliberative-competence-financial-choice/blind/pipeline/20261110T070218Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 112 bytes, from `benchmark/results/artifacts/ambuehl-2022-deliberative-competence-financial-choice/blind/pipeline/20261110T070218Z/execution.json`
- [`output/script.R`](output/script.R) — 11,476 bytes, from `benchmark/results/artifacts/ambuehl-2022-deliberative-competence-financial-choice/blind/pipeline/20261110T070218Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/ambuehl-2022-deliberative-competence-financial-choice/blind/pipeline/20261110T070218Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 173,471 bytes, from `benchmark/results/artifacts/ambuehl-2022-deliberative-competence-financial-choice/blind/pipeline/20261110T070218Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 11,477 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/cf876e8ebe1b1a64e2468ee6.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 2.9 | 3 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request cf876e8ebe1b1a64e2468ee6: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
