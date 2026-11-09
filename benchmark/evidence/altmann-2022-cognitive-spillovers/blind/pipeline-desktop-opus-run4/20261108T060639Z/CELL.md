# altmann-2022-cognitive-spillovers · blind · pipeline-desktop-opus-run4 · 20261108T060639Z

| | |
|---|---|
| Paper | `altmann-2022-cognitive-spillovers` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261108T060639Z |
| Date | 2026-11-08T06:06:39Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261108T060639Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 4/13 (execution 2) |
| Final | **4/13** |
| Package files withheld | 106 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `choice_quality_intervention_t2_col1` | 0.107 (0.018) | 0.0829921 | 22.44% | ±0.018 (se_band) | FAIL | FAIL |
| `choice_quality_intervention_t2_col2` | 0.11 (0.017) | 0.0858845 | 21.92% | ±0.017 (se_band) | FAIL | FAIL |
| `default_adherence_intervention_t2_col5` | -0.217 (0.022) | -0.157625 | 27.36% | ±0.022 (se_band) | FAIL | FAIL |
| `default_adherence_intervention_t2_col6` | -0.219 (0.022) | -0.158605 | 27.58% | ±0.022 (se_band) | FAIL | FAIL |
| `default_adherence_directed_attention_t2_col7` | -0.137 (0.026) | -0.098736 | 27.93% | ±0.026 (se_band) | FAIL | FAIL |
| `default_adherence_forced_choice_t2_col7` | -0.3 (0.021) | -0.217716 | 27.43% | ±0.021 (se_band) | FAIL | FAIL |
| `background_quality_intervention_lab_t3_col1` | -0.028 (0.017) | -0.0186727 | 33.31% | ±0.017 (se_band) | PASS | PASS |
| `background_quality_intervention_lab_t3_col2` | -0.038 (0.014) | -0.01869 | 50.82% | ±0.014 (se_band) | FAIL | FAIL |
| `memory_intervention_online_t3_col5` | -0.114 (0.019) | -0.114252 | 0.22% | ±0.019 (se_band) | PASS | PASS |
| `payoff_share_intervention_t4_col1` | 0.006 (0.013) | 0.00646536 | 7.76% | ±0.013 (se_band) | PASS | PASS |
| `n_obs_lab_tables_2_to_4` | 12160 | 17840 | 46.71% | ±608 (relative) | FAIL | FAIL |
| `n_subjects_lab_tables_2_to_4` | 608 | 892 | 46.71% | ±30.4 (relative) | FAIL | FAIL |
| `memory_intervention_online_t3_col6` | -0.113 (0.017) | -0.113364 | 0.32% | ±0.017 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 4/13 pass, which agrees with the row's 4/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 23,837 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261108T060639Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 12,205 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261108T060639Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261108T060639Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 156 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261108T060639Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 7,480 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261108T060639Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 156 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261108T060639Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,643 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261108T060639Z/attempt-1/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261108T060639Z/execution.json`
- [`output/script.R`](output/script.R) — 7,502 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261108T060639Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 621 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261108T060639Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 17,786 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/blind/pipeline/20261108T060639Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,481 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/6ddb729d1b6aaa4eba9ff1cc.json`
- [`output/answer-2.md`](output/answer-2.md) — 7,503 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/100377637ce27a097f0299f1.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 1 | — | — | 0 |
| final | final | 0 | no | 3.4 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request 6ddb729d1b6aaa4eba9ff1cc: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run4 (request 100377637ce27a097f0299f1: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
