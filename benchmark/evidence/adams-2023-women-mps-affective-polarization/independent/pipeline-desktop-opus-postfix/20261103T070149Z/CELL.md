# adams-2023-women-mps-affective-polarization · independent · pipeline-desktop-opus-postfix · 20261103T070149Z

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T070149Z |
| Date | 2026-11-03T07:01:49Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z` |
| Executions | 3 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 4/11 |
| First scored | 4/11 (execution 1) |
| Final | **7/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `women_mps_coef_bivariate` | 1.89 (0.43) | 1.60382 | 15.14% | ±0.43 (se_band) | PASS | FAIL |
| `women_mps_coef_full` | 1.73 (0.52) | 1.48694 | 14.05% | ±0.52 (se_band) | PASS | FAIL |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 1.45509 | 30.71% | ±0.53 (se_band) | FAIL | PASS |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.45694 | 28.93% | ±0.5 (se_band) | PASS | FAIL |
| `right_left_distance_coef_full` | -0.6 (0.09) | -0.583628 | 2.73% | ±0.09 (se_band) | PASS | PASS |
| `coalition_partners_coef_full` | 0.94 (0.25) | 0.937359 | 0.28% | ±0.25 (se_band) | PASS | PASS |
| `opposition_partners_coef_full` | 0.37 (0.11) | 0.313668 | 15.22% | ±0.11 (se_band) | PASS | FAIL |
| `n_directed_dyads` | 1842 | 2019 | 9.61% | ±92.1 (relative) | FAIL | FAIL |
| `n_obs_women_partisans` | 1836 | 2016 | 9.80% | ±91.8 (relative) | FAIL | FAIL |
| `n_obs_men_partisans` | 1833 | 2013 | 9.82% | ±91.65 (relative) | FAIL | FAIL |
| `n_election_studies` | 81 | 81 | 0.00% | ±4.05 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/11 pass, which agrees with the row's 7/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,287 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 15,589 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 17,453 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 584 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 399 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 5,275 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 334 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 987 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 310 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z/attempt-2/feedback.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 399 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 5,972 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 1,588 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 987 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z/attempt-2/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 399 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z/samples.txt`
- [`output/script.R`](output/script.R) — 7,681 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,693 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 987 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261103T070149Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 5,276 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/33f8ac3406bf5f51faa3e91d.json`
- [`output/answer-2.md`](output/answer-2.md) — 5,973 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/9be5744e2c536c86b42f1b5d.json`
- [`output/answer-3.md`](output/answer-3.md) — 7,682 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/1c84de1af944adbf013a53ed.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request 33f8ac3406bf5f51faa3e91d: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix (request 9be5744e2c536c86b42f1b5d: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix (request 1c84de1af944adbf013a53ed: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
