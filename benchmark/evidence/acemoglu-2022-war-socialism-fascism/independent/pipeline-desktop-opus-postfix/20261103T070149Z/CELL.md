# acemoglu-2022-war-socialism-fascism · independent · pipeline-desktop-opus-postfix · 20261103T070149Z

| | |
|---|---|
| Paper | `acemoglu-2022-war-socialism-fascism` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T070149Z |
| Date | 2026-11-03T07:01:49Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z` |
| Executions | 3 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 7/12 |
| First scored | 7/12 (execution 1) |
| Final | **7/12** |
| Package files withheld | 21 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `first_stage_casualties_table1_col1` | 0.12 (0.02) | 0.088337 | 26.39% | ±0.02 (se_band) | FAIL | FAIL |
| `first_stage_casualties_table1_col6` | 0.1 (0.01) | 0.083855 | 16.15% | ±0.01 (se_band) | FAIL | FAIL |
| `first_stage_fstat_table1_col6` | 50.59 | 43.3012 | 14.41% | ±0.5059 (relative) | FAIL | FAIL |
| `iv_violence_table2_panelA_col6` | 0.5 (0.2) | 0.396322 | 20.74% | ±0.2 (se_band) | PASS | PASS |
| `iv_branches_table2_panelC_col6` | 0.5 (0.2) | 0.243603 | 51.28% | ±0.2 (se_band) | FAIL | FAIL |
| `iv_fascist_vote1921_table3_panelA_col6` | 0.34 (0.18) | 0.272185 | 19.95% | ±0.18 (se_band) | PASS | PASS |
| `iv_fascist_vote1924_table3_panelC_col1` | 0.4 (0.17) | 0.329434 | 17.64% | ±0.17 (se_band) | PASS | PASS |
| `iv_fascist_vote1924_table3_panelC_col6` | 0.51 (0.17) | 0.20142 | 60.51% | ±0.17 (se_band) | FAIL | FAIL |
| `n_obs_main_sample` | 5775 | 5775 | 0.00% | ±288.75 (relative) | PASS | PASS |
| `n_clusters_main_sample` | 181 | 181 | 0.00% | ±9.05 (relative) | PASS | PASS |
| `n_obs_fascist_vote1921` | 5358 | 5358 | 0.00% | ±267.9 (relative) | PASS | PASS |
| `n_clusters_fascist_vote1921` | 175 | 175 | 0.00% | ±8.75 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/12 pass, which agrees with the row's 7/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) regiment dummies not found; regiment FE omitted

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 17,872 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 22,256 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 25,084 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 472 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 1,520 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 8,892 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 441 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,844 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 472 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z/attempt-2/feedback.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 1,520 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 10,182 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 1,212 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,778 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z/attempt-2/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 1,520 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z/samples.txt`
- [`output/script.R`](output/script.R) — 11,021 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,738 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/independent/pipeline/20261103T070149Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,893 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/41a5cf8e845afa953f9f0eb1.json`
- [`output/answer-2.md`](output/answer-2.md) — 10,183 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/7ca57f4532645493b05b0393.json`
- [`output/answer-3.md`](output/answer-3.md) — 11,022 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/f773788d2ec39c83d4a81eb5.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request 41a5cf8e845afa953f9f0eb1: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix (request 7ca57f4532645493b05b0393: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix (request f773788d2ec39c83d4a81eb5: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
