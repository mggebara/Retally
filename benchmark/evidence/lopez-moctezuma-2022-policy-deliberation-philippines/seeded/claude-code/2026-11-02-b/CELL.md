# lopez-moctezuma-2022-policy-deliberation-philippines · seeded · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `lopez-moctezuma-2022-policy-deliberation-philippines` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T19:38:00Z |
| Results file | `benchmark/results/claude-code-run2-23papers-seeded-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/lopez-moctezuma-2022-policy-deliberation-philippines/seeded/claude-code/20261102T194315Z` |
| Run directory | `benchmark/reproductions/lopez-moctezuma-2022-policy-deliberation-philippines/seeded/2026-11-02-b` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 2) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `itt_turnout_barangay_table1_col1` | -4.544 | -4.54448 | 0.01% | ±0.09088 (relative) | PASS | PASS |
| `itt_vote_overall_barangay_table1_col2` | 1.096 | 1.09626 | 0.02% | ±0.02192 (relative) | PASS | PASS |
| `itt_vote_akbayan_barangay_table1_col3` | 1.955 | 1.95486 | 0.01% | ±0.0391 (relative) | PASS | PASS |
| `itt_vote_umalabka_barangay_table1_col4` | 0.36 | 0.360326 | 0.09% | ±0.0072 (relative) | PASS | PASS |
| `n_obs_barangay_table1_cols1_2` | 39 | 39 | 0.00% | ±0.5 (printed_precision) | PASS | PASS |
| `n_obs_barangay_akbayan_table1_col3` | 18 | 18 | 0.00% | ±0.5 (printed_precision) | PASS | PASS |
| `n_obs_barangay_umalabka_table1_col4` | 21 | 21 | 0.00% | ±0.5 (printed_precision) | PASS | PASS |
| `itt_poverty_index_akbayan_tableC3` | 0.496 | 0.496042 | 0.01% | ±0.00992 (relative) | PASS | PASS |
| `itt_poverty_index_umalabka_tableC3` | 0.126 | 0.126266 | 0.21% | ±0.00252 (relative) | PASS | PASS |
| `itt_gender_index_akbayan_tableC4` | 0.45 | 0.449758 | 0.05% | ±0.009 (relative) | PASS | PASS |
| `itt_gender_index_umalabka_tableC4` | 0.095 | 0.095357 | 0.38% | ±0.0019 (relative) | PASS | PASS |
| `itt_vote_overall_unweighted_tableF1_col2` | 23.242 | 23.267 | 0.11% | ±0.46484 (relative) | PASS | PASS |
| `itt_vote_akbayan_unweighted_tableF1_col3` | 31.729 | 31.7289 | 0.00% | ±0.63458 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) survey_clean.R links survey barangays to official barangays with fastLink (not installed); replaced by an exact barangay-name match, which matches all 10 treated survey barangays (control weights are 1 regardless).
- (reproduction.json) ri::estate / ri::genprobexact replaced by direct computation: assignment probability = share of assigned barangays within each city; ITT = lm(y ~ assignment + city dummies) with weights Z/p + (1-Z)/(1-p). Randomization-inference p-values and clustered SEs were not computed (only coefficients and N are claimed).
- (DEVIATION: line) fastLink record linkage of survey to official barangays replaced by exact barangay-name match (treated barangays share names in both files); ri::estate/genprobexact computed directly.

Agent notes: Attempt 1 was exploratory (inspected data_agg and survey_raw barangay names, attendance). Final script follows tables_figures_agg.R (Table 1), survey_clean.R (Anderson-style inverse-covariance indices, standardized on treatment==0 s.d.), tables_fig_ind.R (C.3/C.4: WLS with attendance weights att.prop/attendance.agg, city FE, by party list) and tables_fig_ind_unweighted.R (F.1: assignment-probability weights, city FE). All values match the claims to the reported precision except F.1 col 2 (23.267 vs claimed 23.242); not iterated on.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 192,944 bytes, from `benchmark/results/artifacts/lopez-moctezuma-2022-policy-deliberation-philippines/seeded/claude-code/20261102T194315Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,002 bytes, from `benchmark/results/artifacts/lopez-moctezuma-2022-policy-deliberation-philippines/seeded/claude-code/20261102T194315Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 298 bytes, from `benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/seeded/2026-11-02-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 622 bytes, from `benchmark/results/artifacts/lopez-moctezuma-2022-policy-deliberation-philippines/seeded/claude-code/20261102T194315Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 210 bytes, from `benchmark/results/artifacts/lopez-moctezuma-2022-policy-deliberation-philippines/seeded/claude-code/20261102T194315Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 9,200 bytes, from `benchmark/results/artifacts/lopez-moctezuma-2022-policy-deliberation-philippines/seeded/claude-code/20261102T194315Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,590 bytes, from `benchmark/results/artifacts/lopez-moctezuma-2022-policy-deliberation-philippines/seeded/claude-code/20261102T194315Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,332 bytes, from `benchmark/results/artifacts/lopez-moctezuma-2022-policy-deliberation-philippines/seeded/claude-code/20261102T194315Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/lopez-moctezuma-2022-policy-deliberation-philippines/seeded/claude-code/20261102T194315Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,938 bytes, from `benchmark/results/artifacts/lopez-moctezuma-2022-policy-deliberation-philippines/seeded/claude-code/20261102T194315Z/stdout.txt`
