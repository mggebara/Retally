# adams-2023-women-mps-affective-polarization · independent · pipeline-desktop-opus-run3 · 20261103T050517Z

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T050517Z |
| Date | 2026-11-03T05:05:17Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T050517Z` |
| Executions | 3 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 2/11 |
| First scored | 2/11 (execution 1) |
| Final | **11/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `women_mps_coef_bivariate` | 1.89 (0.43) | 1.61285 | 14.66% | ±0.43 (se_band) | PASS | FAIL |
| `women_mps_coef_full` | 1.73 (0.52) | 1.51867 | 12.22% | ±0.52 (se_band) | PASS | FAIL |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 1.69044 | 19.50% | ±0.53 (se_band) | PASS | FAIL |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.19772 | 5.99% | ±0.5 (se_band) | PASS | FAIL |
| `right_left_distance_coef_full` | -0.6 (0.09) | -0.569331 | 5.11% | ±0.09 (se_band) | PASS | PASS |
| `coalition_partners_coef_full` | 0.94 (0.25) | 0.959197 | 2.04% | ±0.25 (se_band) | PASS | PASS |
| `opposition_partners_coef_full` | 0.37 (0.11) | 0.363849 | 1.66% | ±0.11 (se_band) | PASS | FAIL |
| `n_directed_dyads` | 1842 | 1826 | 0.87% | ±92.1 (relative) | PASS | FAIL |
| `n_obs_women_partisans` | 1836 | 1819 | 0.93% | ±91.8 (relative) | PASS | FAIL |
| `n_obs_men_partisans` | 1833 | 1816 | 0.93% | ±91.65 (relative) | PASS | FAIL |
| `n_election_studies` | 81 | 81 | 0.00% | ±4.05 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Sample restricted with additional filter 'from_ws_nonmiss' (women-share data completeness / MP threshold) to match the paper's dyad count; exact filter not stated in the paper

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 14,736 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T050517Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 23,161 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T050517Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 19,967 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T050517Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 748 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T050517Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 7,983 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T050517Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T050517Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,082 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T050517Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 214 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T050517Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 5,472 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T050517Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T050517Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 7,287 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T050517Z/attempt-2/stdout.txt`
- [`output/script.R`](output/script.R) — 6,856 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T050517Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T050517Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,985 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T050517Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,984 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/77654428fb573988a544e2ca.json`
- [`output/answer-2.md`](output/answer-2.md) — 5,473 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/6b1c95578090e598bbec356d.json`
- [`output/answer-3.md`](output/answer-3.md) — 6,857 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/f5da972bf7eabee8a44dd981.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 77654428fb573988a544e2ca: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request 6b1c95578090e598bbec356d: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run3 (request f5da972bf7eabee8a44dd981: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
