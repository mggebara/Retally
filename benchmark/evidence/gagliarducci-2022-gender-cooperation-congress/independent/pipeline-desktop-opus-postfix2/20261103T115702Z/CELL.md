# gagliarducci-2022-gender-cooperation-congress · independent · pipeline-desktop-opus-postfix2 · 20261103T115702Z

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261103T115702Z |
| Date | 2026-11-03T11:57:02Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z` |
| Executions | 3 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 7/13 |
| First scored | 7/13 (execution 1) |
| Final | **13/13** |
| Package files withheld | 152 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.6301 | 16.85% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 3.02841 | 3.83% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 8.29975 | 23.25% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 3.75843 | 20.31% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -1.90377 | 26.50% | ±0.419 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -2.73582 | 18.36% | ±1.91 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -1.19648 | 0.95% | ±0.525 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 3.65231 | 0.37% | ±0.916 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 2.80393 | 3.48% | ±0.82 (se_band) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60669 | 0.00% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4746 | 0.00% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 32846 | 0.00% | ±1642.3 (relative) | PASS | FAIL |
| `n_bills_pct_opposite_rep_ols` | 27669 | 27670 | 0.00% | ±1383.45 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) median income not found in data
- (DEVIATION: line) population density not found in data
- (DEVIATION: line) Democratic sponsor-control IPW uses ATT weights (treated=1, controls=p/(1-p)); weighting scheme not specified in text

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 44,647 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 24,231 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 22,691 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 593 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 810 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 9,947 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 1,039 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,743 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 113 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z/attempt-2/feedback.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 810 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 10,473 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 956 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,794 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z/attempt-2/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 810 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z/samples.txt`
- [`output/script.R`](output/script.R) — 10,688 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 956 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,923 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T115702Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 9,948 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/68214ed01d6b23bc73fd1982.json`
- [`output/answer-2.md`](output/answer-2.md) — 10,474 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/f1c355923ccdc2423805ad10.json`
- [`output/answer-3.md`](output/answer-3.md) — 10,689 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/89dc935e060134285cdf6981.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request 68214ed01d6b23bc73fd1982: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix2 (request f1c355923ccdc2423805ad10: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix2 (request 89dc935e060134285cdf6981: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
