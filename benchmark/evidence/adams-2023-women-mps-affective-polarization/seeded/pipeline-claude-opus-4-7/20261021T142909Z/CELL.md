# adams-2023-women-mps-affective-polarization · seeded · pipeline-claude-opus-4-7 · 20261021T142909Z

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | seeded |
| Reproducer | pipeline |
| Model | claude-opus-4-7 |
| Run | 20261021T142909Z |
| Date | 2026-10-21T14:29:09Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-10papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/seeded/pipeline/20261021T142909Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 11/11 |
| First scored | 11/11 (execution 1) |
| Final | **11/11** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `women_mps_coef_bivariate` | 1.89 (0.43) | 1.8873 | 0.14% | ±0.0378 (relative) | PASS | PASS |
| `women_mps_coef_full` | 1.73 (0.52) | 1.7256 | 0.25% | ±0.0346 (relative) | PASS | PASS |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 2.0967 | 0.16% | ±0.042 (relative) | PASS | PASS |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.131 | 0.09% | ±0.0226 (relative) | PASS | PASS |
| `right_left_distance_coef_full` | -0.6 (0.09) | -0.5961 | 0.65% | ±0.012 (relative) | PASS | PASS |
| `coalition_partners_coef_full` | 0.94 (0.25) | 0.9431 | 0.33% | ±0.0188 (relative) | PASS | PASS |
| `opposition_partners_coef_full` | 0.37 (0.11) | 0.3707 | 0.19% | ±0.0074 (relative) | PASS | PASS |
| `n_directed_dyads` | 1842 | 1842 | 0.00% | ±92.1 (relative) | PASS | PASS |
| `n_obs_women_partisans` | 1836 | 1836 | 0.00% | ±91.8 (relative) | PASS | PASS |
| `n_obs_men_partisans` | 1833 | 1833 | 0.00% | ±91.65 (relative) | PASS | PASS |
| `n_election_studies` | 81 | 81 | 0.00% | ±4.05 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 42,995 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/seeded/pipeline/20261021T142909Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 2,838 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/seeded/pipeline/20261021T142909Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/seeded/pipeline/20261021T142909Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 417 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/seeded/pipeline/20261021T142909Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 2,847 bytes, from `benchmark/.cache/llm/64edd30e7bbdf7b525587d98.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM cache (request 64edd30e7bbdf7b525587d98: model claude-opus-4-7, max_tokens 8192, effort None)
- usage records 4 model calls; 1 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
