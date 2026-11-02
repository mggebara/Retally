# adams-2023-women-mps-affective-polarization · independent · pipeline-desktop-opus · 20261023T064839Z

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261023T064839Z |
| Date | 2026-10-23T06:48:39Z |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 6/11 |
| First scored | 6/11 (execution 1) |
| Final | **10/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `women_mps_coef_bivariate` | 1.89 (0.43) | 1.88727 | 0.14% | ±0.43 (se_band) | PASS | PASS |
| `women_mps_coef_full` | 1.73 (0.52) | 1.75827 | 1.63% | ±0.52 (se_band) | PASS | PASS |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 1.69263 | 19.40% | ±0.53 (se_band) | PASS | FAIL |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.69763 | 50.23% | ±0.5 (se_band) | FAIL | FAIL |
| `right_left_distance_coef_full` | -0.6 (0.09) | -0.592612 | 1.23% | ±0.09 (se_band) | PASS | PASS |
| `coalition_partners_coef_full` | 0.94 (0.25) | 0.951726 | 1.25% | ±0.25 (se_band) | PASS | PASS |
| `opposition_partners_coef_full` | 0.37 (0.11) | 0.333888 | 9.76% | ±0.11 (se_band) | PASS | PASS |
| `n_directed_dyads` | 1842 | 1842 | 0.00% | ±18.42 (relative) | PASS | FAIL |
| `n_obs_women_partisans` | 1836 | 1839 | 0.16% | ±18.36 (relative) | PASS | FAIL |
| `n_obs_men_partisans` | 1833 | 1836 | 0.16% | ±18.33 (relative) | PASS | FAIL |
| `n_election_studies` | 81 | 81 | 0.00% | ±0.81 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/11 pass, which agrees with the row's 10/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) to_/from_mp_number are CMP party codes, not seat counts; the >=4 MPs restriction is applied to to_/from_prior_seats (seats in year before survey)
- (DEVIATION: line) Party-size filter variant 'to4_drop' (handling of missing/999 seat codes, or which side is filtered) chosen as the one giving N closest to the paper's 1,842

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 14,578 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 19,079 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 21,981 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 22,439 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 389 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 4,899 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,212 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 309 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 7,262 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 8,127 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 93 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 7,675 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 8,413 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/attempt-3/stdout.txt`
- [`output/script.R`](output/script.R) — 10,570 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 8,969 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261023T064839Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 4,909 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/d4115e0ca2453bdbe68b38d2.json`
- [`output/answer-2.md`](output/answer-2.md) — 7,263 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/40230efb09d092bf7627ab14.json`
- [`output/answer-3.md`](output/answer-3.md) — 7,676 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/b52b447231d73bf9fde116f4.json`
- [`output/answer-4.md`](output/answer-4.md) — 10,571 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/183b7630f116d0caeac86383.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request d4115e0ca2453bdbe68b38d2: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request 40230efb09d092bf7627ab14: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus (request b52b447231d73bf9fde116f4: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus (request 183b7630f116d0caeac86383: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
