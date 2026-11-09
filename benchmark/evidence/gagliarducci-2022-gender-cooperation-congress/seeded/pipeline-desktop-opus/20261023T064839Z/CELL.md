# gagliarducci-2022-gender-cooperation-congress · seeded · pipeline-desktop-opus · 20261023T064839Z

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261023T064839Z |
| Date | 2026-10-23T06:48:39Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T064839Z` |
| Executions | 2 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 8/13 |
| First scored | 8/13 (execution 1) |
| Final | **8/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 0.987577 | 29.21% | ±0.0279 (relative) | FAIL | FAIL |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 3.23017 | 2.58% | ±0.06298 (relative) | FAIL | FAIL |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 5.5476 | 17.62% | ±0.13468 (relative) | FAIL | FAIL |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 3.06373 | 1.93% | ±0.06248 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -1.73016 | 14.96% | ±0.0301 (relative) | FAIL | FAIL |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -3.3989 | 1.43% | ±0.06702 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -1.7755 | 46.98% | ±0.02416 (relative) | FAIL | FAIL |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 3.70586 | 1.09% | ±0.07332 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 2.90496 | 0.00% | ±0.0581 (relative) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60685 | 0.02% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4747 | 0.02% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 32846 | 0.00% | ±1642.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_rep_ols` | 27669 | 27669 | 0.00% | ±1383.45 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/13 pass, which agrees with the row's 8/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 211,789 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T064839Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 21,338 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T064839Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 22,072 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T064839Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 472 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T064839Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 10,479 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T064839Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 284 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T064839Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 792 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T064839Z/attempt-1/stdout.txt`
- [`output/script.R`](output/script.R) — 10,513 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T064839Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 284 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T064839Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 856 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T064839Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,480 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/bb0f6108671c3e92af4bbafb.json`
- [`output/answer-2.md`](output/answer-2.md) — 10,514 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/83594157d8dd25d5d12f69ba.json`
- [`output/answer-3.md`](output/answer-3.md) — 10,514 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/52f0e88dea6946f4dc4fb550.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request bb0f6108671c3e92af4bbafb: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request 83594157d8dd25d5d12f69ba: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus (request 52f0e88dea6946f4dc4fb550: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 3 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
