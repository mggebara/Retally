# altmann-2022-cognitive-spillovers · blind · pipeline-desktop-opus · 20261023T062931Z

| | |
|---|---|
| Paper | `altmann-2022-cognitive-spillovers` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261023T062931Z |
| Date | 2026-10-23T06:29:31Z |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261023T062931Z` |
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
| `choice_quality_intervention_t2_col1` | 0.107 (0.018) | 0.0829921 | 22.44% | ±0.018 (se_band) | FAIL | FAIL |
| `choice_quality_intervention_t2_col2` | 0.11 (0.017) | — | — | ±0.017 (se_band) | FAIL | FAIL |
| `default_adherence_intervention_t2_col5` | -0.217 (0.022) | -0.157625 | 27.36% | ±0.022 (se_band) | FAIL | FAIL |
| `default_adherence_intervention_t2_col6` | -0.219 (0.022) | — | — | ±0.022 (se_band) | FAIL | FAIL |
| `default_adherence_directed_attention_t2_col7` | -0.137 (0.026) | -0.098736 | 27.93% | ±0.026 (se_band) | FAIL | FAIL |
| `default_adherence_forced_choice_t2_col7` | -0.3 (0.021) | -0.217716 | 27.43% | ±0.021 (se_band) | FAIL | FAIL |
| `background_quality_intervention_lab_t3_col1` | -0.028 (0.017) | -0.0186727 | 33.31% | ±0.017 (se_band) | PASS | PASS |
| `background_quality_intervention_lab_t3_col2` | -0.038 (0.014) | — | — | ±0.014 (se_band) | FAIL | FAIL |
| `memory_intervention_online_t3_col5` | -0.114 (0.019) | -0.114252 | 0.22% | ±0.019 (se_band) | PASS | PASS |
| `payoff_share_intervention_t4_col1` | 0.006 (0.013) | 0.00646536 | 7.76% | ±0.013 (se_band) | PASS | PASS |
| `n_obs_lab_tables_2_to_4` | 12160 | 17840 | 46.71% | ±121.6 (relative) | FAIL | FAIL |
| `n_subjects_lab_tables_2_to_4` | 608 | 892 | 46.71% | ±6.08 (relative) | FAIL | FAIL |
| `memory_intervention_online_t3_col6` | -0.113 (0.017) | -0.113364 | 0.32% | ±0.017 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 4/13 pass, which agrees with the row's 4/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 23,837 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261023T062931Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 8,925 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261023T062931Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 192 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261023T062931Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,855 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261023T062931Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,926 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/dc16ecf10f00faaea7187183.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request dc16ecf10f00faaea7187183: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
