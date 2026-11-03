# gagliarducci-2022-gender-cooperation-congress · blind · pipeline-desktop-opus-postfix · 20261103T062809Z

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T062809Z |
| Date | 2026-11-03T06:28:09Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261103T062809Z` |
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
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.74532 | 25.11% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 3.02092 | 4.07% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 6.56874 | 2.45% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 3.18465 | 1.94% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -0.029875 | 98.01% | ±0.419 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -0.051325 | 98.47% | ±1.91 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -0.039596 | 96.72% | ±0.525 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 0.060102 | 98.36% | ±0.916 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 0.033837 | 98.84% | ±0.82 (se_band) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60517 | 0.25% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4736 | 0.21% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 22712 | 30.85% | ±1642.3 (relative) | FAIL | FAIL |
| `n_bills_pct_opposite_rep_ols` | 27669 | 18691 | 32.45% | ±1383.45 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/13 pass, which agrees with the row's 7/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 44,993 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261103T062809Z/prompt-1.txt`

## What it produced

- [`output/samples.txt`](output/samples.txt) — 1,341 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261103T062809Z/samples.txt`
- [`output/script.R`](output/script.R) — 9,958 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261103T062809Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261103T062809Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,288 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261103T062809Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 9,959 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/27644e74109d714d1b71b093.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request 27644e74109d714d1b71b093: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
