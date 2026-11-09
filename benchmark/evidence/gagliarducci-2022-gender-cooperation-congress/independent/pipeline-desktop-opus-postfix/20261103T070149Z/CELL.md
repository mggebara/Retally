# gagliarducci-2022-gender-cooperation-congress · independent · pipeline-desktop-opus-postfix · 20261103T070149Z

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T070149Z |
| Date | 2026-11-03T07:01:49Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z` |
| Executions | 3 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 10/13 |
| First scored | 10/13 (execution 1) |
| Final | **13/13** |
| Package files withheld | 152 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.66666 | 19.47% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 2.43211 | 22.77% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 8.29975 | 23.25% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 3.40782 | 9.09% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -1.88656 | 25.35% | ±0.419 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -2.73582 | 18.36% | ±1.91 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -1.58719 | 31.39% | ±0.525 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 3.11726 | 14.97% | ±0.916 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 2.82261 | 2.84% | ±0.82 (se_band) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60669 | 0.00% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4746 | 0.00% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 32846 | 0.00% | ±1642.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_rep_ols` | 27669 | 27670 | 0.00% | ±1383.45 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) dem IPW pct outcome capped at 100 (1 rows above 100)

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 44,647 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 25,285 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 26,498 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z/prompt-3.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 321 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z/attempt-1/feedback.txt`
- [`output/attempt-1/samples.txt`](output/attempt-1/samples.txt) — 962 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z/attempt-1/samples.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 13,464 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 300 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,243 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 113 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z/attempt-2/feedback.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 1,040 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 14,247 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 300 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,478 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z/attempt-2/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 1,040 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z/samples.txt`
- [`output/script.R`](output/script.R) — 14,595 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 300 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,542 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T070149Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 13,465 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/68214ed01d6b23bc73fd1982.json`
- [`output/answer-2.md`](output/answer-2.md) — 14,248 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/ab8f722864d1270b44ba250d.json`
- [`output/answer-3.md`](output/answer-3.md) — 14,596 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/47b8639b717e5dc06ffb1d13.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request 68214ed01d6b23bc73fd1982: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix (request ab8f722864d1270b44ba250d: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix (request 47b8639b717e5dc06ffb1d13: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 5 model calls; 3 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
