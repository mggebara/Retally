# balan-2022-local-elites-state-capacity · blind · claude-code · 2026-11-10-c

| | |
|---|---|
| Paper | `balan-2022-local-elites-state-capacity` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-c |
| Date | 2026-11-10T17:15:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run3-1paper-balan-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z` |
| Run directory | `benchmark/reproductions/balan-2022-local-elites-state-capacity/blind/2026-11-10-c` |
| Executions | 9 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 9/13 (execution 9) |
| Final | **9/13** |
| Package files withheld | 58 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `compliance_local_table4_panelA_col1` | 0.023 (0.008) | 0.024452 | 6.31% | ±0.008 (se_band) | PASS | PASS |
| `compliance_local_table4_panelA_col2` | 0.032 (0.007) | 0.040923 | 27.88% | ±0.007 (se_band) | FAIL | FAIL |
| `compliance_local_house_fe_table4_panelA_col4` | 0.033 (0.007) | 0.041587 | 26.02% | ±0.007 (se_band) | FAIL | FAIL |
| `compliance_local_exempt_excluded_table4_panelA_col5` | 0.04 (0.008) | 0.050182 | 25.45% | ±0.008 (se_band) | FAIL | FAIL |
| `revenue_local_table4_panelB_col2` | 79.64 (22.856) | 95.6379 | 20.09% | ±22.856 (se_band) | PASS | PASS |
| `revenue_local_house_fe_table4_panelB_col4` | 68.855 (20.56) | 86.4457 | 25.55% | ±20.56 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 28872 | 29384 | 1.77% | ±1443.6 (relative) | PASS | PASS |
| `n_obs_table4_col2` | 27764 | 27310 | 1.64% | ±1388.2 (relative) | PASS | PASS |
| `paid_bribe_endline_local_table5_panelB` | 0.018 (0.009) | 0.013742 | 23.66% | ±0.009 (se_band) | PASS | PASS |
| `visited_by_collector_local_table6_col1` | -0.009 (0.026) | 0.034975 | 488.61% | ±0.026 (se_band) | FAIL | FAIL |
| `compliance_cli_table7_col1` | 0.024 (0.009) | 0.020115 | 16.19% | ±0.009 (se_band) | PASS | PASS |
| `revenue_cli_table7_col2` | 46.566 (21.2) | 30.8977 | 33.65% | ±21.2 (se_band) | PASS | PASS |
| `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 (0.007) | 0.059273 | 5.84% | ±0.007 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/13 pass, which agrees with the row's 9/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Package ships only raw (01_base) data, so the analysis sample was rebuilt: property register = registration_noPII rows in the 356 randomized neighborhoods with pilot==0, tot_complete==1, house in {low, high band} (285 villas dropped), unique compound code. This gives 46,506 non-villa properties (paper reports 45,162), so observation counts differ from the paper's construction.
- (reproduction.json) De facto treatment taken from campaign_collector_info Tmt (neighborhood 654, randomized CXL, coded Local), giving 111 Local / 110 Central as in the paper.
- (reproduction.json) Time fixed effects: online Appendix A2.5 is not available. Implemented as 61-day (two-month) periods starting at the midpoint between the earliest property registration dates of the two arms compared and ending at the midpoint between their latest registration dates. Each property is dated by its own registration date, and properties outside the window are dropped. The paper describes neighborhood-level assignment; the exact date variable used for it is unknown.
- (reproduction.json) Compliance = registered compound appears in tax_payments_noPII receipt data with a positive amount (all receipts kept, including error_code==1). Revenue = sum of amountCF, 0 for non-payers. Two keyed amounts above 1 million CF were recoded to the band liability (3,000 or 13,200).
- (reproduction.json) Column 5 drops properties with registration exempt==1 (collector designated exempt); missing exemption answers are kept.
- (reproduction.json) Endline bribe: endline_round1 (tot_complete==1, non-pilot, one record per respondent code). Bribe is asked only of households reporting a collector visit with someone present, so households reporting no visit or nobody home are coded 0; 8888/9999 are set to missing. Treatment comes from the endline a7.
- (reproduction.json) Table 6 visited: midline (tot_complete==1, non-pilot, first record per compound) matched to the register. 'Visited after registration' = 1 if the reported total visits (which include the registration visit) are >= 2, and 0 if no visit was reported. House type and registration date come from the register.
- (reproduction.json) Table 8: chief_consultations pay_ease coded 0/1/2 (8888 don't know set to missing), merged to registered CLI properties by compound code; stratum = randomization_assignment stratum (32 groups) throughout.

Agent notes: Independent blind reproduction from raw admin and survey files. Attempts 1-8 were exploratory: they inspected variables, labels, merges and dates, printed no RESULT lines and estimated no listed quantity. The final script estimates all 13 quantities with fixest OLS, stratum FE (plus period/house FE where specified) and SEs clustered by neighborhood (a7). The largest uncertainty is the time-FE construction: with registration-date windows, 209 of 221 Local/Central clusters keep at least one property in column 2 (paper: 213 clusters). Observation counts are also above the paper's because the paper's register cleaning (45,162 properties) could not be reproduced exactly. I did not consult any reported values; the only tool feedback was check_attempt's missing-name check. No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 27,951 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 900 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 276 bytes, from `benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,085 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 26,099 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 258 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,858 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 321 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 6,607 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 258 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 1,800 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 33,015 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 259 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-3/timing.json`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 1,661 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 26,537 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 259 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-4/timing.json`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 2,440 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 41,043 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-5/stdout.txt`
- [`output/attempt-5/timing.json`](output/attempt-5/timing.json) — 259 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-5/timing.json`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 1,806 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 51,910 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-6/stdout.txt`
- [`output/attempt-6/timing.json`](output/attempt-6/timing.json) — 259 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-6/timing.json`
- [`output/attempt-7/script.R`](output/attempt-7/script.R) — 2,328 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-7/script.R`
- [`output/attempt-7/stderr.txt`](output/attempt-7/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-7/stderr.txt`
- [`output/attempt-7/stdout.txt`](output/attempt-7/stdout.txt) — 2,736 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-7/stdout.txt`
- [`output/attempt-7/timing.json`](output/attempt-7/timing.json) — 259 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-7/timing.json`
- [`output/attempt-8/script.R`](output/attempt-8/script.R) — 1,556 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-8/script.R`
- [`output/attempt-8/stderr.txt`](output/attempt-8/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-8/stderr.txt`
- [`output/attempt-8/stdout.txt`](output/attempt-8/stdout.txt) — 1,478 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-8/stdout.txt`
- [`output/attempt-8/timing.json`](output/attempt-8/timing.json) — 258 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/attempt-8/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 3,938 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/reproduction.json`
- [`output/script.R`](output/script.R) — 8,704 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 5,107 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 259 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171529Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
