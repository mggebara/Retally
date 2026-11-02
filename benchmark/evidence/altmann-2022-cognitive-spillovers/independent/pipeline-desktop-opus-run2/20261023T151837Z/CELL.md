# altmann-2022-cognitive-spillovers · independent · pipeline-desktop-opus-run2 · 20261023T151837Z

| | |
|---|---|
| Paper | `altmann-2022-cognitive-spillovers` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261023T151837Z |
| Date | 2026-10-23T15:18:37Z |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T151837Z` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 4/13 |
| First scored | 4/13 (execution 1) |
| Final | **13/13** |
| Package files withheld | 106 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `choice_quality_intervention_t2_col1` | 0.107 (0.018) | 0.106921 | 0.07% | ±0.018 (se_band) | PASS | FAIL |
| `choice_quality_intervention_t2_col2` | 0.11 (0.017) | 0.107187 | 2.56% | ±0.017 (se_band) | PASS | FAIL |
| `default_adherence_intervention_t2_col5` | -0.217 (0.022) | -0.216832 | 0.08% | ±0.022 (se_band) | PASS | FAIL |
| `default_adherence_intervention_t2_col6` | -0.219 (0.022) | -0.217599 | 0.64% | ±0.022 (se_band) | PASS | FAIL |
| `default_adherence_directed_attention_t2_col7` | -0.137 (0.026) | -0.137015 | 0.01% | ±0.026 (se_band) | PASS | FAIL |
| `default_adherence_forced_choice_t2_col7` | -0.3 (0.021) | -0.299874 | 0.04% | ±0.021 (se_band) | PASS | FAIL |
| `background_quality_intervention_lab_t3_col1` | -0.028 (0.017) | -0.028245 | 0.87% | ±0.017 (se_band) | PASS | PASS |
| `background_quality_intervention_lab_t3_col2` | -0.038 (0.014) | -0.033443 | 11.99% | ±0.014 (se_band) | PASS | FAIL |
| `memory_intervention_online_t3_col5` | -0.114 (0.019) | -0.114252 | 0.22% | ±0.019 (se_band) | PASS | PASS |
| `payoff_share_intervention_t4_col1` | 0.006 (0.013) | 0.005834 | 2.77% | ±0.013 (se_band) | PASS | PASS |
| `n_obs_lab_tables_2_to_4` | 12160 | 12160 | 0.00% | ±121.6 (relative) | PASS | FAIL |
| `n_subjects_lab_tables_2_to_4` | 608 | 608 | 0.00% | ±6.08 (relative) | PASS | FAIL |
| `memory_intervention_online_t3_col6` | -0.113 (0.017) | -0.113364 | 0.32% | ±0.017 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Sample for Tables 2-4 identified by searching subject-level variables for the definition yielding 608 subjects ( Treatment_Incentives!=Ample )

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 23,834 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T151837Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 29,173 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T151837Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 882 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T151837Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 11,956 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T151837Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T151837Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 9,866 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T151837Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 9,625 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T151837Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T151837Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 8,551 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T151837Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 11,957 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/68674da62b89f89837727fd3.json`
- [`output/answer-2.md`](output/answer-2.md) — 9,626 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/ce03bb56bbe533ed2ca48b0a.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 68674da62b89f89837727fd3: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request ce03bb56bbe533ed2ca48b0a: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
