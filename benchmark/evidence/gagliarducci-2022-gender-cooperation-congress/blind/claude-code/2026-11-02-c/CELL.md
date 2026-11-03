# gagliarducci-2022-gender-cooperation-congress · blind · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `gagliarducci-2022-gender-cooperation-congress` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:17:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T202753Z` |
| Run directory | `benchmark/reproductions/gagliarducci-2022-gender-cooperation-congress/blind/2026-11-02-c` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 9/13 (execution 3) |
| Final | **9/13** |
| Package files withheld | 152 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `female_sponsor_ncosponsors_all_ols` | 1.395 (0.628) | 1.40253 | 0.54% | ±0.628 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ols` | 3.149 (1.017) | 2.39523 | 23.94% | ±1.017 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 (3.946) | 6.69783 | 0.54% | ±3.946 (se_band) | PASS | PASS |
| `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 (1.04) | 2.74414 | 12.16% | ±1.04 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ols` | -1.505 (0.419) | -2.43877 | 62.04% | ±0.419 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_dem_rd` | -3.351 (1.91) | -5.13248 | 53.16% | ±1.91 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 (0.525) | -2.24183 | 85.58% | ±0.525 (se_band) | FAIL | FAIL |
| `female_sponsor_pct_opposite_rep_ols` | 3.666 (0.916) | 4.32794 | 18.06% | ±0.916 (se_band) | PASS | PASS |
| `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 (0.82) | 2.69888 | 7.10% | ±0.82 (se_band) | PASS | PASS |
| `n_bills_ncosponsors_all_ols` | 60670 | 60669 | 0.00% | ±3033.5 (relative) | PASS | PASS |
| `n_sponsor_terms_ncosponsors_all_ols` | 4746 | 4746 | 0.00% | ±237.3 (relative) | PASS | PASS |
| `n_bills_pct_opposite_dem_ols` | 32846 | 22712 | 30.85% | ±1642.3 (relative) | FAIL | FAIL |
| `n_bills_pct_opposite_rep_ols` | 27669 | 18691 | 32.45% | ±1383.45 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/13 pass, which agrees with the row's 9/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Data: bills_analysis_101-111_replication.dta; sample = public bills (private==0 or missing) with sponsor information; pct opposite is the file's pct_cosponsors_opposite (opposite/cosponsors, missing with zero cosponsors) x100.
- (reproduction.json) Macro-area dummies (3) built from Census regions of the sponsor's state; log population density = lnpop - lnarea; rookie = tenure_run==1; committee leader = comc or comr; occupation dummies occ1-occ5; total bills sponsored counted per sponsor-Congress in the data.
- (reproduction.json) Bill characteristics: 33 house_* committee-of-referral dummies plus minor-topic fixed effects; Congress fixed effects; fixest with singleton removal (reghdfe-style); SEs clustered by sponsor-Congress (v2 x state x district x term_served).
- (reproduction.json) RD: mixed-gender races, linear in MV1_female with separate slopes, uniform kernel, bandwidth fixed at the paper-stated optimal values (13 pp Rep number of cosponsors, 24 pp Dem pct opposite); rdrobust mserd bandwidths printed for information only (17.79, 16.45).
- (reproduction.json) Propensity scores: bill-level logits within the party sample; RD-IPW on district characteristics within bandwidth; full-sample IPW on district characteristics + winner margin \|MV1_democrat\| (+ sponsor characteristics in column 5); ATE weights 1/p, 1/(1-p).
- (DEVIATION: line) macro-area dummies built from Census regions of the sponsor state; log population density = lnpop - lnarea; rookie = tenure 1; committee leader = chair or ranking member; total bills sponsored counted per sponsor-Congress in the data; singletons dropped (reghdfe-style).
- (DEVIATION: line) RD bandwidths fixed at the paper-stated optimal values (13 pp Rep ncosp, 24 pp Dem pct opposite) with uniform kernel; IPW uses ATE weights 1/p and 1/(1-p) from a bill-level logit.

Agent notes: Two exploratory runs (variable inventory, definition checks; no RESULT lines), then one estimation run which is final. No claim comparisons (blind). Did not open Dofiles, Log, Output or README.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 31,270 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T202753Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 941 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T202753Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 290 bytes, from `benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/blind/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,059 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T202753Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T202753Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 11,881 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T202753Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,846 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T202753Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T202753Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 7,989 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T202753Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,036 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T202753Z/reproduction.json`
- [`output/script.R`](output/script.R) — 7,315 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T202753Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 678 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T202753Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,965 bytes, from `benchmark/results/artifacts/gagliarducci-2022-gender-cooperation-congress/blind/claude-code/20261102T202753Z/stdout.txt`
