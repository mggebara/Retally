# adams-2023-women-mps-affective-polarization · blind · pipeline-desktop-opus-run2 · 20261023T150832Z

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261023T150832Z |
| Date | 2026-10-23T15:08:32Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261023T150832Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 2/11 |
| First scored | 2/11 (execution 1) |
| Final | **2/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `women_mps_coef_bivariate` | 1.89 (0.43) | — | — | ±0.43 (se_band) | FAIL | FAIL |
| `women_mps_coef_full` | 1.73 (0.52) | — | — | ±0.52 (se_band) | FAIL | FAIL |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 1.71259 | 18.45% | ±0.53 (se_band) | PASS | PASS |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.21004 | 7.08% | ±0.5 (se_band) | PASS | PASS |
| `right_left_distance_coef_full` | -0.6 (0.09) | — | — | ±0.09 (se_band) | FAIL | FAIL |
| `coalition_partners_coef_full` | 0.94 (0.25) | — | — | ±0.25 (se_band) | FAIL | FAIL |
| `opposition_partners_coef_full` | 0.37 (0.11) | — | — | ±0.11 (se_band) | FAIL | FAIL |
| `n_directed_dyads` | 1842 | — | — | ±92.1 (relative) | FAIL | FAIL |
| `n_obs_women_partisans` | 1836 | 2012 | 9.59% | ±91.8 (relative) | FAIL | FAIL |
| `n_obs_men_partisans` | 1833 | 2008 | 9.55% | ±91.65 (relative) | FAIL | FAIL |
| `n_election_studies` | 81 | — | — | ±4.05 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 2/11 pass, which agrees with the row's 2/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 14,912 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261023T150832Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 7,313 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261023T150832Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 381 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261023T150832Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 6,271 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/blind/pipeline/20261023T150832Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 7,314 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/b305b92c07ea31da868c9fd0.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request b305b92c07ea31da868c9fd0: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
