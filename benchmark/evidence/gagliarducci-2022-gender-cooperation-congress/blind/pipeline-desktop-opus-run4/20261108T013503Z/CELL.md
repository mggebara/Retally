# gagliarducci-2022-gender-cooperation-congress · blind · pipeline-desktop-opus-run4 · 20261108T013503Z

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261108T013503Z |
| Date | 2026-11-08T01:35:03Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261108T013503Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 7/13 |
| First scored | 7/13 (execution 1) |
| Final | **7/13** |
| Package files withheld | 152 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.66081 | 19.05% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 3.02299 | 4.00% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 6.56874 | 2.45% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 3.33504 | 6.76% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -0.0298428 | 98.02% | ±0.419 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -0.0513248 | 98.47% | ±1.91 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -0.0317961 | 97.37% | ±0.525 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 0.0601066 | 98.36% | ±0.916 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 0.0338517 | 98.83% | ±0.82 (se_band) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60669 | 0.00% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4741 | 0.11% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 22712 | 30.85% | ±1642.3 (relative) | FAIL | FAIL |
| `n_bills_pct_opposite_rep_ols` | 27669 | 18691 | 32.45% | ±1383.45 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/13 pass, which agrees with the row's 7/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 27,773 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261108T013503Z/prompt-1.txt`

## What it produced

- [`output/execution.json`](output/execution.json) — 113 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261108T013503Z/execution.json`
- [`output/script.R`](output/script.R) — 9,869 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261108T013503Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,206 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261108T013503Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 704 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261108T013503Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 9,870 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/ad794ab0ee99e89b9990e807.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| final | final | 0 | no | 4.8 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request ad794ab0ee99e89b9990e807: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
