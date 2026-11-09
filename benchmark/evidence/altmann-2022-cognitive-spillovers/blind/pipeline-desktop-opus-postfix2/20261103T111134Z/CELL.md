# altmann-2022-cognitive-spillovers · blind · pipeline-desktop-opus-postfix2 · 20261103T111134Z

| | |
|---|---|
| Paper | `altmann-2022-cognitive-spillovers` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261103T111134Z |
| Date | 2026-11-03T11:11:34Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261103T111134Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 4/13 |
| First scored | 4/13 (execution 1) |
| Final | **4/13** |
| Package files withheld | 106 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `choice_quality_intervention_t2_col1` | 0.107 (0.018) | 0.082992 | 22.44% | ±0.018 (se_band) | FAIL | FAIL |
| `choice_quality_intervention_t2_col2` | 0.11 (0.017) | 0.085898 | 21.91% | ±0.017 (se_band) | FAIL | FAIL |
| `default_adherence_intervention_t2_col5` | -0.217 (0.022) | -0.157625 | 27.36% | ±0.022 (se_band) | FAIL | FAIL |
| `default_adherence_intervention_t2_col6` | -0.219 (0.022) | -0.158634 | 27.56% | ±0.022 (se_band) | FAIL | FAIL |
| `default_adherence_directed_attention_t2_col7` | -0.137 (0.026) | -0.098736 | 27.93% | ±0.026 (se_band) | FAIL | FAIL |
| `default_adherence_forced_choice_t2_col7` | -0.3 (0.021) | -0.217716 | 27.43% | ±0.021 (se_band) | FAIL | FAIL |
| `background_quality_intervention_lab_t3_col1` | -0.028 (0.017) | -0.018673 | 33.31% | ±0.017 (se_band) | PASS | PASS |
| `background_quality_intervention_lab_t3_col2` | -0.038 (0.014) | -0.018447 | 51.46% | ±0.014 (se_band) | FAIL | FAIL |
| `memory_intervention_online_t3_col5` | -0.114 (0.019) | -0.114252 | 0.22% | ±0.019 (se_band) | PASS | PASS |
| `payoff_share_intervention_t4_col1` | 0.006 (0.013) | 0.006465 | 7.75% | ±0.013 (se_band) | PASS | PASS |
| `n_obs_lab_tables_2_to_4` | 12160 | 17840 | 46.71% | ±608 (relative) | FAIL | FAIL |
| `n_subjects_lab_tables_2_to_4` | 608 | 892 | 46.71% | ±30.4 (relative) | FAIL | FAIL |
| `memory_intervention_online_t3_col6` | -0.113 (0.017) | -0.113364 | 0.32% | ±0.017 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 4/13 pass, which agrees with the row's 4/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 26,049 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261103T111134Z/prompt-1.txt`

## What it produced

- [`output/samples.txt`](output/samples.txt) — 394 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261103T111134Z/samples.txt`
- [`output/script.R`](output/script.R) — 8,600 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261103T111134Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 192 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261103T111134Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,201 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261103T111134Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,601 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/0c1fccab8d981718420653c5.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request 0c1fccab8d981718420653c5: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
