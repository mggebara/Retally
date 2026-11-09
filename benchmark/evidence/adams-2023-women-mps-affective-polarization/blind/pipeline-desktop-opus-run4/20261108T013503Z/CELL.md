# adams-2023-women-mps-affective-polarization · blind · pipeline-desktop-opus-run4 · 20261108T013503Z

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261108T013503Z |
| Date | 2026-11-08T01:35:03Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261108T013503Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 7/11 |
| First scored | 7/11 (execution 1) |
| Final | **7/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `women_mps_coef_bivariate` | 1.89 (0.43) | 1.60382 | 15.14% | ±0.43 (se_band) | PASS | PASS |
| `women_mps_coef_full` | 1.73 (0.52) | 1.48694 | 14.05% | ±0.52 (se_band) | PASS | PASS |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 1.45509 | 30.71% | ±0.53 (se_band) | FAIL | FAIL |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.45694 | 28.93% | ±0.5 (se_band) | PASS | PASS |
| `right_left_distance_coef_full` | -0.6 (0.09) | -0.580508 | 3.25% | ±0.09 (se_band) | PASS | PASS |
| `coalition_partners_coef_full` | 0.94 (0.25) | 0.937359 | 0.28% | ±0.25 (se_band) | PASS | PASS |
| `opposition_partners_coef_full` | 0.37 (0.11) | 0.313668 | 15.22% | ±0.11 (se_band) | PASS | PASS |
| `n_directed_dyads` | 1842 | 2019 | 9.61% | ±92.1 (relative) | FAIL | FAIL |
| `n_obs_women_partisans` | 1836 | 2016 | 9.80% | ±91.8 (relative) | FAIL | FAIL |
| `n_obs_men_partisans` | 1833 | 2013 | 9.82% | ±91.65 (relative) | FAIL | FAIL |
| `n_election_studies` | 81 | 81 | 0.00% | ±4.05 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/11 pass, which agrees with the row's 7/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 15,136 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261108T013503Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261108T013503Z/execution.json`
- [`output/script.R`](output/script.R) — 4,930 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261108T013503Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261108T013503Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,222 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261108T013503Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 4,931 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/9a6fb9215aa86a9d09b49986.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 3.7 | 11 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request 9a6fb9215aa86a9d09b49986: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
