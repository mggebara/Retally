# gagliarducci-2022-gender-cooperation-congress · blind · pipeline-desktop-opus-run3 · 20261103T010557Z

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T010557Z |
| Date | 2026-11-03T01:05:57Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261103T010557Z` |
| Executions | 2 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 7/13 (execution 2) |
| Final | **7/13** |
| Package files withheld | 152 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.73618 | 24.46% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 3.02299 | 4.00% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 3.35418 | 50.19% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 2.25465 | 27.83% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -0.0298428 | 98.02% | ±0.419 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -0.0513248 | 98.47% | ±1.91 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -0.0312419 | 97.41% | ±0.525 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 0.0601066 | 98.36% | ±0.916 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 0.036146 | 98.76% | ±0.82 (se_band) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60517 | 0.25% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4732 | 0.29% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 22712 | 30.85% | ±1642.3 (relative) | FAIL | FAIL |
| `n_bills_pct_opposite_rep_ols` | 27669 | 18691 | 32.45% | ±1383.45 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/13 pass, which agrees with the row's 7/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 27,837 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261103T010557Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 12,695 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261103T010557Z/prompt-2.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 328 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261103T010557Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 10,496 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261103T010557Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 328 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261103T010557Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261103T010557Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 10,676 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261103T010557Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,190 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261103T010557Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 702 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261103T010557Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,497 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/e950213dfd188c4e0eebeaea.json`
- [`output/answer-2.md`](output/answer-2.md) — 10,677 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/a25b5d273ed57a8c91cf271a.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request e950213dfd188c4e0eebeaea: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request a25b5d273ed57a8c91cf271a: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 4 model calls; 2 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
