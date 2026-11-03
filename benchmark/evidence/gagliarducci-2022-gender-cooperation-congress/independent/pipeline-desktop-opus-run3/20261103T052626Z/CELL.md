# gagliarducci-2022-gender-cooperation-congress · independent · pipeline-desktop-opus-run3 · 20261103T052626Z

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261103T052626Z |
| Date | 2026-11-03T05:26:26Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z` |
| Executions | 4 |
| Refinements | 3 (0 error + 3 claim) |
| First attempt | 7/13 |
| First scored | 7/13 (execution 1) |
| Final | **12/13** |
| Package files withheld | 152 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.58224 | 13.42% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 2.96047 | 5.99% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 7.96516 | 18.28% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 3.22703 | 3.30% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -1.67562 | 11.34% | ±0.419 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -2.73582 | 18.36% | ±1.91 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -2.09121 | 73.11% | ±0.525 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 4.01937 | 9.64% | ±0.916 (se_band) | PASS | FAIL |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 2.89077 | 0.49% | ±0.82 (se_band) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60684 | 0.02% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4742 | 0.08% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 32846 | 0.00% | ±1642.3 (relative) | PASS | FAIL |
| `n_bills_pct_opposite_rep_ols` | 27669 | 27670 | 0.00% | ±1383.45 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Dem sponsor-PS IPW uses ATT weights (controls ps/(1-ps)) and only the sponsor controls listed in the paper (drops black, borninstate); paper does not specify weighting scheme

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 27,360 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 21,780 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 21,414 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 22,069 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/prompt-4.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 593 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 8,503 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 2,797 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 734 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 113 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 8,525 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 2,688 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 734 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 113 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 8,573 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 2,688 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 734 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/attempt-3/stdout.txt`
- [`output/script.R`](output/script.R) — 9,214 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 2,688 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 920 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/independent/pipeline/20261103T052626Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,504 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/dce04a5a3857d1c7caf3b690.json`
- [`output/answer-2.md`](output/answer-2.md) — 8,526 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/b74fa0545ae61f03b0708d70.json`
- [`output/answer-3.md`](output/answer-3.md) — 8,574 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/ad236f61612538eac0ac857a.json`
- [`output/answer-4.md`](output/answer-4.md) — 9,215 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/e61c422ab5bcf6f19eaa2c47.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request dce04a5a3857d1c7caf3b690: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request b74fa0545ae61f03b0708d70: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run3 (request ad236f61612538eac0ac857a: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run3 (request e61c422ab5bcf6f19eaa2c47: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 6 model calls; 4 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
