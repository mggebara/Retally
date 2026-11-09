# gagliarducci-2022-gender-cooperation-congress · independent · pipeline-desktop-opus-run2 · 20261023T152513Z

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261023T152513Z |
| Date | 2026-10-23T15:25:13Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T152513Z` |
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
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.34887 | 3.31% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 3.03671 | 3.57% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 9.05242 | 34.43% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 3.50678 | 12.25% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -1.82019 | 20.94% | ±0.419 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -2.73582 | 18.36% | ±1.91 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -1.58334 | 31.07% | ±0.525 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 3.64715 | 0.51% | ±0.916 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 2.82968 | 2.59% | ±0.82 (se_band) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60669 | 0.00% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4750 | 0.08% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 32846 | 0.00% | ±1642.3 (relative) | PASS | FAIL |
| `n_bills_pct_opposite_rep_ols` | 27669 | 27670 | 0.00% | ±1383.45 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Dem pct-opposite matching estimate uses ATT propensity-score reweighting (treated weight 1, controls p/(1-p)) with full OLS controls in the outcome equation; exact matching estimator not specified in the provided text

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 26,823 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T152513Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 21,452 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T152513Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 21,466 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T152513Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 593 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T152513Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 9,033 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T152513Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 1,017 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T152513Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,303 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T152513Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 113 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T152513Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 9,279 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T152513Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 934 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T152513Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,433 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T152513Z/attempt-2/stdout.txt`
- [`output/script.R`](output/script.R) — 10,293 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T152513Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 998 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T152513Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,662 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T152513Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 9,034 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/382b9a4dcd64e05dc3f8274d.json`
- [`output/answer-2.md`](output/answer-2.md) — 9,280 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/7880565e6f5c2a9d5989d936.json`
- [`output/answer-3.md`](output/answer-3.md) — 10,294 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/b35decd08320e3c256dc41af.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 382b9a4dcd64e05dc3f8274d: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request 7880565e6f5c2a9d5989d936: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run2 (request b35decd08320e3c256dc41af: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
