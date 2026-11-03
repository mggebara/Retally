# gagliarducci-2022-gender-cooperation-congress · blind · pipeline-desktop-opus · 20261023T062931Z

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | blind |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261023T062931Z |
| Date | 2026-10-23T06:29:31Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261023T062931Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 12/13 |
| First scored | 12/13 (execution 1) |
| Final | **12/13** |
| Package files withheld | 152 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.66081 | 19.05% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 3.02306 | 4.00% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 6.56874 | 2.45% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 2.64854 | 15.22% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -1.83523 | 21.94% | ±0.419 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -2.73582 | 18.36% | ±1.91 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -2.7332 | 126.26% | ±0.525 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 4.17344 | 13.84% | ±0.916 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 2.31949 | 20.16% | ±0.82 (se_band) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60669 | 0.00% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4750 | 0.08% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 32846 | 0.00% | ±1642.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_rep_ols` | 27669 | 27670 | 0.00% | ±1383.45 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 27,773 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261023T062931Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 11,299 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261023T062931Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 956 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261023T062931Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 693 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/pipeline/20261023T062931Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 11,300 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/2f8adea2cc0e25ca10da925d.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 2f8adea2cc0e25ca10da925d: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
