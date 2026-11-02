# adams-2023-women-mps-affective-polarization · seeded · pipeline-desktop-opus · 20261023T063725Z

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261023T063725Z |
| Date | 2026-10-23T06:37:25Z |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/seeded/pipeline/20261023T063725Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 11/11 |
| First scored | 11/11 (execution 1) |
| Final | **11/11** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `women_mps_coef_bivariate` | 1.89 (0.43) | 1.88727 | 0.14% | ±0.0378 (relative) | PASS | PASS |
| `women_mps_coef_full` | 1.73 (0.52) | 1.72562 | 0.25% | ±0.0346 (relative) | PASS | PASS |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 2.0967 | 0.16% | ±0.042 (relative) | PASS | PASS |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.13099 | 0.09% | ±0.0226 (relative) | PASS | PASS |
| `right_left_distance_coef_full` | -0.6 (0.09) | -0.596057 | 0.66% | ±0.012 (relative) | PASS | PASS |
| `coalition_partners_coef_full` | 0.94 (0.25) | 0.943065 | 0.33% | ±0.0188 (relative) | PASS | PASS |
| `opposition_partners_coef_full` | 0.37 (0.11) | 0.370655 | 0.18% | ±0.0074 (relative) | PASS | PASS |
| `n_directed_dyads` | 1842 | 1842 | 0.00% | ±18.42 (relative) | PASS | PASS |
| `n_obs_women_partisans` | 1836 | 1836 | 0.00% | ±18.36 (relative) | PASS | PASS |
| `n_obs_men_partisans` | 1833 | 1833 | 0.00% | ±18.33 (relative) | PASS | PASS |
| `n_election_studies` | 81 | 81 | 0.00% | ±0.81 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 44,297 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/seeded/pipeline/20261023T063725Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 4,287 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/seeded/pipeline/20261023T063725Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/seeded/pipeline/20261023T063725Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 888 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/seeded/pipeline/20261023T063725Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 4,288 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/6f25676dfbd2daa82617b8e2.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 6f25676dfbd2daa82617b8e2: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 1 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
