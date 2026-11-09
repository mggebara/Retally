# adams-2023-women-mps-affective-polarization · independent · pipeline-desktop-opus-postfix2 · 20261103T115702Z

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261103T115702Z |
| Date | 2026-11-03T11:57:02Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z` |
| Executions | 3 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 7/11 |
| First scored | 7/11 (execution 1) |
| Final | **10/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `women_mps_coef_bivariate` | 1.89 (0.43) | 1.61285 | 14.66% | ±0.43 (se_band) | PASS | PASS |
| `women_mps_coef_full` | 1.73 (0.52) | 1.51867 | 12.22% | ±0.52 (se_band) | PASS | PASS |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 1.48399 | 29.33% | ±0.53 (se_band) | FAIL | FAIL |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.48633 | 31.53% | ±0.5 (se_band) | PASS | PASS |
| `right_left_distance_coef_full` | -0.6 (0.09) | -0.576437 | 3.93% | ±0.09 (se_band) | PASS | PASS |
| `coalition_partners_coef_full` | 0.94 (0.25) | 0.959197 | 2.04% | ±0.25 (se_band) | PASS | PASS |
| `opposition_partners_coef_full` | 0.37 (0.11) | 0.363849 | 1.66% | ±0.11 (se_band) | PASS | PASS |
| `n_directed_dyads` | 1842 | 1826 | 0.87% | ±92.1 (relative) | PASS | FAIL |
| `n_obs_women_partisans` | 1836 | 1823 | 0.71% | ±91.8 (relative) | PASS | FAIL |
| `n_obs_men_partisans` | 1833 | 1820 | 0.71% | ±91.65 (relative) | PASS | FAIL |
| `n_election_studies` | 81 | 81 | 0.00% | ±4.05 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/11 pass, which agrees with the row's 10/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) main dropped 193 dyads whose in-party lacks women-MP data (from_pfeml)
- (DEVIATION: line) women_partisans dropped 193 dyads whose in-party lacks women-MP data (from_pfeml)
- (DEVIATION: line) men_partisans dropped 193 dyads whose in-party lacks women-MP data (from_pfeml)

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,287 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 20,470 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 23,395 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 310 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 693 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 6,734 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 3,560 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 95 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z/attempt-2/feedback.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 830 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 8,732 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 7,191 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z/attempt-2/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 830 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z/samples.txt`
- [`output/script.R`](output/script.R) — 10,241 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,350 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T115702Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,735 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/33f8ac3406bf5f51faa3e91d.json`
- [`output/answer-2.md`](output/answer-2.md) — 8,733 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/f6f6fc04ff2852f8f71bb269.json`
- [`output/answer-3.md`](output/answer-3.md) — 10,242 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/7667bb1a334105fb94f8ab69.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request 33f8ac3406bf5f51faa3e91d: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix2 (request f6f6fc04ff2852f8f71bb269: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix2 (request 7667bb1a334105fb94f8ab69: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
