# adams-2023-women-mps-affective-polarization · blind · pipeline-desktop-opus-run3 · 20261103T004800Z

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T004800Z |
| Date | 2026-11-03T00:48:00Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261103T004800Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 8/11 |
| First scored | 8/11 (execution 1) |
| Final | **8/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `women_mps_coef_bivariate` | 1.89 (0.43) | 1.60382 | 15.14% | ±0.43 (se_band) | PASS | PASS |
| `women_mps_coef_full` | 1.73 (0.52) | 1.48694 | 14.05% | ±0.52 (se_band) | PASS | PASS |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 1.71259 | 18.45% | ±0.53 (se_band) | PASS | PASS |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.21004 | 7.08% | ±0.5 (se_band) | PASS | PASS |
| `right_left_distance_coef_full` | -0.6 (0.09) | -0.580508 | 3.25% | ±0.09 (se_band) | PASS | PASS |
| `coalition_partners_coef_full` | 0.94 (0.25) | 0.937359 | 0.28% | ±0.25 (se_band) | PASS | PASS |
| `opposition_partners_coef_full` | 0.37 (0.11) | 0.313668 | 15.22% | ±0.11 (se_band) | PASS | PASS |
| `n_directed_dyads` | 1842 | 2019 | 9.61% | ±92.1 (relative) | FAIL | FAIL |
| `n_obs_women_partisans` | 1836 | 2012 | 9.59% | ±91.8 (relative) | FAIL | FAIL |
| `n_obs_men_partisans` | 1833 | 2008 | 9.55% | ±91.65 (relative) | FAIL | FAIL |
| `n_election_studies` | 81 | 81 | 0.00% | ±4.05 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/11 pass, which agrees with the row's 8/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 15,062 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261103T004800Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 8,053 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261103T004800Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261103T004800Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,252 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261103T004800Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,054 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/3651c8487368f40435d59f4a.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 3651c8487368f40435d59f4a: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
