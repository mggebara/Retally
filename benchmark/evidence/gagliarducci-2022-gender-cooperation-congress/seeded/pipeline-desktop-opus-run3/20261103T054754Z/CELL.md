# gagliarducci-2022-gender-cooperation-congress · seeded · pipeline-desktop-opus-run3 · 20261103T054754Z

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T054754Z |
| Date | 2026-11-03T05:47:54Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 11/13 |
| First scored | 11/13 (execution 1) |
| Final | **11/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.39531 | 0.02% | ±0.0279 (relative) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 3.14933 | 0.01% | ±0.06298 (relative) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 6.85691 | 1.83% | ±0.13468 (relative) | PASS | FAIL |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 2.56596 | 17.86% | ±0.06248 (relative) | FAIL | FAIL |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -1.50465 | 0.02% | ±0.0301 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -3.3989 | 1.43% | ±0.06702 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -1.82878 | 51.39% | ±0.02416 (relative) | FAIL | PASS |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 3.66566 | 0.01% | ±0.07332 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 2.90498 | 0.00% | ±0.0581 (relative) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60670 | 0.00% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4746 | 0.00% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 32846 | 0.00% | ±1642.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_rep_ols` | 27669 | 27669 | 0.00% | ±1383.45 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/13 pass, which agrees with the row's 11/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) plain RD (col 2) uses a CCT/MSE bandwidth selected on all bills of the party subsample; RD+IPW keeps the bandwidth selected on the mixed-gender complete-case sample; the paper does not state this choice
- (DEVIATION: line) IPW (district + indiv + absMV) propensity score estimated once by probit on the pooled sponsor-level sample (both parties, incl. sponsor_democrat) and applied to each party subsample; the paper does not state the pscore estimation sample
- (DEVIATION: line) RD bandwidth (CCT/MSE) selected on the mixed-gender complete-case RD sample rather than on all bills of the party subsample; the paper does not state the bandwidth selection sample

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 211,474 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 22,059 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 23,807 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 25,396 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 192 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 9,795 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 732 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,334 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 191 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 10,098 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 732 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,525 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 98 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 10,924 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 52 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 1,873 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/attempt-3/stdout.txt`
- [`output/script.R`](output/script.R) — 11,101 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 52 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,038 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261103T054754Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 9,796 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/308ca62f26f69f41be25fa13.json`
- [`output/answer-2.md`](output/answer-2.md) — 10,099 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/0941e7e1483de2614dda6921.json`
- [`output/answer-3.md`](output/answer-3.md) — 10,925 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/b9d6d6b3a08bdee047e801bd.json`
- [`output/answer-4.md`](output/answer-4.md) — 11,102 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/8e8bd3d6a2aa562235ae8183.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 308ca62f26f69f41be25fa13: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request 0941e7e1483de2614dda6921: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run3 (request b9d6d6b3a08bdee047e801bd: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run3 (request 8e8bd3d6a2aa562235ae8183: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 4 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
