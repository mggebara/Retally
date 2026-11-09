# gagliarducci-2022-gender-cooperation-congress · independent · pipeline-desktop-opus · 20261023T064839Z

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261023T064839Z |
| Date | 2026-10-23T06:48:39Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 7/13 |
| First scored | 7/13 (execution 1) |
| Final | **13/13** |
| Package files withheld | 152 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.58927 | 13.93% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 2.43436 | 22.69% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 7.34116 | 9.02% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 3.07644 | 1.52% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -1.89122 | 25.66% | ±0.419 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -2.73582 | 18.36% | ±1.91 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -1.19992 | 0.67% | ±0.525 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 3.11795 | 14.95% | ±0.916 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 3.00012 | 3.27% | ±0.82 (se_band) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60669 | 0.00% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4741 | 0.11% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 32846 | 0.00% | ±1642.3 (relative) | PASS | FAIL |
| `n_bills_pct_opposite_rep_ols` | 27669 | 27670 | 0.00% | ±1383.45 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Democratic sponsor-characteristics propensity score uses ATT weights (treated 1, controls p/(1-p)) as in matching on the treated; the paper text does not specify the weighting scheme

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 27,675 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 21,662 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 21,495 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 22,567 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 593 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 8,529 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 1,039 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,146 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 113 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 8,670 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 956 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,200 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 113 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 8,946 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 956 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 2,389 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/attempt-3/stdout.txt`
- [`output/script.R`](output/script.R) — 9,541 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 956 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,394 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261023T064839Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,539 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/89e4420a8dd23c4f574cd7d1.json`
- [`output/answer-2.md`](output/answer-2.md) — 8,671 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/0c87f278700fdeba63907cf6.json`
- [`output/answer-3.md`](output/answer-3.md) — 8,947 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/c8b69adc6d2d45a253c8a697.json`
- [`output/answer-4.md`](output/answer-4.md) — 9,542 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/d916f97d1cc357f456d44476.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 89e4420a8dd23c4f574cd7d1: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request 0c87f278700fdeba63907cf6: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus (request c8b69adc6d2d45a253c8a697: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus (request d916f97d1cc357f456d44476: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
