# gagliarducci-2022-gender-cooperation-congress · seeded · pipeline-desktop-opus-run2 · 20261023T153400Z

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | seeded |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261023T153400Z |
| Date | 2026-10-23T15:34:00Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 11/13 |
| First scored | 11/13 (execution 1) |
| Final | **12/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.39531 | 0.02% | ±0.0279 (relative) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 3.14933 | 0.01% | ±0.06298 (relative) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 7.18008 | 6.62% | ±0.13468 (relative) | FAIL | FAIL |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 3.1239 | 0.00% | ±0.06248 (relative) | PASS | FAIL |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -1.50465 | 0.02% | ±0.0301 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -3.3989 | 1.43% | ±0.06702 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -1.20782 | 0.01% | ±0.02416 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 3.66566 | 0.01% | ±0.07332 (relative) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 2.90498 | 0.00% | ±0.0581 (relative) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60670 | 0.00% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4746 | 0.00% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 32846 | 0.00% | ±1642.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_rep_ols` | 27669 | 27669 | 0.00% | ±1383.45 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Propensity scores are set to missing (as Stata's default predict after probit does) for observations excluded by perfect-prediction rules (dropped Congress levels or dropped covariates' nonzero values), so they get no IPW weight
- (DEVIATION: line) RD-IPW propensity probit is estimated on one row per sponsor-Congress drawn from the RD estimation sample (mixed-gender races with complete data, within the bandwidth), rather than on the first row of each sponsor-Congress in the party subsample
- (DEVIATION: line) Propensity-score probit now mimics Stata's perfect-prediction handling for covariates (a regressor whose nonzero values perfectly predict sponsor gender is dropped along with those observations before fitting), not only for Congress dummies

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 210,937 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 35,502 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 42,611 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 49,407 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 192 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 8,544 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 1,122 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 6,809 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 192 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 9,466 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 1,122 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 7,061 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 93 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 10,242 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 1,122 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 7,301 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/attempt-3/stdout.txt`
- [`output/script.R`](output/script.R) — 10,624 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 1,122 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,559 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/seeded/pipeline/20261023T153400Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,545 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/836d9ed684c81304e2e0b491.json`
- [`output/answer-2.md`](output/answer-2.md) — 9,467 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/87560f2e4146fad0a7c466e4.json`
- [`output/answer-3.md`](output/answer-3.md) — 10,243 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/aea0a91e10d7414457382492.json`
- [`output/answer-4.md`](output/answer-4.md) — 10,625 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/ecf51e0a2c4d4c7d9c17c781.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 836d9ed684c81304e2e0b491: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request 87560f2e4146fad0a7c466e4: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run2 (request aea0a91e10d7414457382492: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run2 (request ecf51e0a2c4d4c7d9c17c781: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 4 are code-generation prompts kept above, the other 3 (paper extraction) leave no prompt in the artifacts
