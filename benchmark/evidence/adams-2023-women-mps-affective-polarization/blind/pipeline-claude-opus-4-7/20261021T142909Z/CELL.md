# adams-2023-women-mps-affective-polarization · blind · pipeline-claude-opus-4-7 · 20261021T142909Z

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | blind |
| Reproducer | pipeline |
| Model | claude-opus-4-7 |
| Run | 20261021T142909Z |
| Date | 2026-10-21T14:29:09Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-10papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261021T142909Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 1/11 (execution 2) |
| Final | **1/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `women_mps_coef_bivariate` | 1.89 (0.43) | -1.95393 | 203.38% | ±0.43 (se_band) | FAIL | FAIL |
| `women_mps_coef_full` | 1.73 (0.52) | -1.46589 | 184.73% | ±0.52 (se_band) | FAIL | FAIL |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | -1.18738 | 156.54% | ±0.53 (se_band) | FAIL | FAIL |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | -1.69146 | 249.69% | ±0.5 (se_band) | FAIL | FAIL |
| `right_left_distance_coef_full` | -0.6 (0.09) | 0.58237 | 197.06% | ±0.09 (se_band) | FAIL | FAIL |
| `coalition_partners_coef_full` | 0.94 (0.25) | -0.931327 | 199.08% | ±0.25 (se_band) | FAIL | FAIL |
| `opposition_partners_coef_full` | 0.37 (0.11) | -0.344646 | 193.15% | ±0.11 (se_band) | FAIL | FAIL |
| `n_directed_dyads` | 1842 | 2019 | 9.61% | ±92.1 (relative) | FAIL | FAIL |
| `n_obs_women_partisans` | 1836 | 2008 | 9.37% | ±91.8 (relative) | FAIL | FAIL |
| `n_obs_men_partisans` | 1833 | 2012 | 9.77% | ±91.65 (relative) | FAIL | FAIL |
| `n_election_studies` | 81 | 81 | 0.00% | ±4.05 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 1/11 pass, which agrees with the row's 1/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 13,624 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261021T142909Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 19,140 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261021T142909Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 840 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261021T142909Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 10,327 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261021T142909Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 840 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261021T142909Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,223 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261021T142909Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 5,336 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261021T142909Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261021T142909Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,496 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261021T142909Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,327 bytes, from `benchmark/.cache/llm/a57f35f745d3c9bdcf91db4d.json`
- [`output/answer-2.md`](output/answer-2.md) — 5,336 bytes, from `benchmark/.cache/llm/5dc72cb37e095fbb03ce92c1.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM cache (request a57f35f745d3c9bdcf91db4d: model claude-opus-4-7, max_tokens 8192, effort None)
- answer-2.md: reply to prompt-2.txt from the LLM cache (request 5dc72cb37e095fbb03ce92c1: model claude-opus-4-7, max_tokens 8192, effort None)
- usage records 3 model calls; 2 are code-generation prompts kept above, the other 1 (paper extraction) leave no prompt in the artifacts
