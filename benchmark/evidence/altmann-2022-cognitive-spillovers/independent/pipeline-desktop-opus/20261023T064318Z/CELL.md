# altmann-2022-cognitive-spillovers · independent · pipeline-desktop-opus · 20261023T064318Z

| | |
|---|---|
| Paper | `altmann-2022-cognitive-spillovers` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261023T064318Z |
| Date | 2026-10-23T06:43:18Z |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T064318Z` |
| Executions | 3 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 4/13 |
| First scored | 4/13 (execution 1) |
| Final | **13/13** |
| Package files withheld | 106 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `choice_quality_intervention_t2_col1` | 0.107 (0.018) | 0.106921 | 0.07% | ±0.018 (se_band) | PASS | FAIL |
| `choice_quality_intervention_t2_col2` | 0.11 (0.017) | 0.112727 | 2.48% | ±0.017 (se_band) | PASS | FAIL |
| `default_adherence_intervention_t2_col5` | -0.217 (0.022) | -0.216832 | 0.08% | ±0.022 (se_band) | PASS | FAIL |
| `default_adherence_intervention_t2_col6` | -0.219 (0.022) | -0.224077 | 2.32% | ±0.022 (se_band) | PASS | FAIL |
| `default_adherence_directed_attention_t2_col7` | -0.137 (0.026) | -0.137015 | 0.01% | ±0.026 (se_band) | PASS | FAIL |
| `default_adherence_forced_choice_t2_col7` | -0.3 (0.021) | -0.299874 | 0.04% | ±0.021 (se_band) | PASS | FAIL |
| `background_quality_intervention_lab_t3_col1` | -0.028 (0.017) | -0.028245 | 0.87% | ±0.017 (se_band) | PASS | PASS |
| `background_quality_intervention_lab_t3_col2` | -0.038 (0.014) | -0.03649 | 3.97% | ±0.014 (se_band) | PASS | FAIL |
| `memory_intervention_online_t3_col5` | -0.114 (0.019) | -0.114252 | 0.22% | ±0.019 (se_band) | PASS | PASS |
| `payoff_share_intervention_t4_col1` | 0.006 (0.013) | 0.005834 | 2.77% | ±0.013 (se_band) | PASS | PASS |
| `n_obs_lab_tables_2_to_4` | 12160 | 12160 | 0.00% | ±121.6 (relative) | PASS | FAIL |
| `n_subjects_lab_tables_2_to_4` | 608 | 608 | 0.00% | ±6.08 (relative) | PASS | FAIL |
| `memory_intervention_online_t3_col6` | -0.113 (0.017) | -0.113364 | 0.32% | ±0.017 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 24,302 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T064318Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 26,251 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T064318Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 29,677 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T064318Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 898 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T064318Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 9,050 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T064318Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 192 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T064318Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 4,579 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T064318Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 898 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T064318Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 9,827 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T064318Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 192 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T064318Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 6,586 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T064318Z/attempt-2/stdout.txt`
- [`output/script.R`](output/script.R) — 8,644 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T064318Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 192 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T064318Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,601 bytes, from `benchmark/results/artifacts/altmann-2022-cognitive-spillovers/independent/pipeline/20261023T064318Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 9,060 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/f7f50325a9eb98579f0b4565.json`
- [`output/answer-2.md`](output/answer-2.md) — 9,828 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/2c9db8facd24391667ed336e.json`
- [`output/answer-3.md`](output/answer-3.md) — 8,645 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/f4a887ab4e28f36d359a0dbc.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request f7f50325a9eb98579f0b4565: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request 2c9db8facd24391667ed336e: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus (request f4a887ab4e28f36d359a0dbc: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
