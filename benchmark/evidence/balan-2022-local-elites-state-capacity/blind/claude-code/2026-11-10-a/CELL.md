# balan-2022-local-elites-state-capacity · blind · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `balan-2022-local-elites-state-capacity` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T17:12:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-balan-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z` |
| Run directory | `benchmark/reproductions/balan-2022-local-elites-state-capacity/blind/2026-11-10-a` |
| Executions | 5 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 8/13 (execution 5) |
| Final | **8/13** |
| Package files withheld | 58 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `compliance_local_table4_panelA_col1` | 0.023 (0.008) | 0.024357 | 5.90% | ±0.008 (se_band) | PASS | PASS |
| `compliance_local_table4_panelA_col2` | 0.032 (0.007) | 0.042499 | 32.81% | ±0.007 (se_band) | FAIL | FAIL |
| `compliance_local_house_fe_table4_panelA_col4` | 0.033 (0.007) | 0.043119 | 30.66% | ±0.007 (se_band) | FAIL | FAIL |
| `compliance_local_exempt_excluded_table4_panelA_col5` | 0.04 (0.008) | 0.052015 | 30.04% | ±0.008 (se_band) | FAIL | FAIL |
| `revenue_local_table4_panelB_col2` | 79.64 (22.856) | 100.096 | 25.69% | ±22.856 (se_band) | PASS | PASS |
| `revenue_local_house_fe_table4_panelB_col4` | 68.855 (20.56) | 92.0599 | 33.70% | ±20.56 (se_band) | FAIL | FAIL |
| `n_obs_table4_col1` | 28872 | 29367 | 1.71% | ±1443.6 (relative) | PASS | PASS |
| `n_obs_table4_col2` | 27764 | 27083 | 2.45% | ±1388.2 (relative) | PASS | PASS |
| `paid_bribe_endline_local_table5_panelB` | 0.018 (0.009) | 0.013748 | 23.62% | ±0.009 (se_band) | PASS | PASS |
| `visited_by_collector_local_table6_col1` | -0.009 (0.026) | 0.034447 | 482.74% | ±0.026 (se_band) | FAIL | FAIL |
| `compliance_cli_table7_col1` | 0.024 (0.009) | 0.019919 | 17.00% | ±0.009 (se_band) | PASS | PASS |
| `revenue_cli_table7_col2` | 46.566 (21.2) | 30.4139 | 34.69% | ±21.2 (se_band) | PASS | PASS |
| `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 (0.007) | 0.059271 | 5.84% | ±0.007 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/13 pass, which agrees with the row's 8/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Property sample built from taxroll_noPII.dta (one row per registered compound) merged to registration_noPII.dta for house band and collector exemption; villas (house type 3) dropped. Compliance = compound appears in tax_payments_noPII.dta (receipt data); revenue = amountCF, 0 for non-payers.
- (reproduction.json) Revenue: 7 payers with missing or implausible receipt amounts (>13,200 CF, two records of >1.4m CF) were assigned the median amount paid in their house band.
- (reproduction.json) De facto treatment: neighborhood 654 (CXL in the schedule) coded Local, identified as the misassigned neighborhood (chief-only registration, coded Local in the endline survey).
- (reproduction.json) Randomization strata: the 'stratum' variable of randomization_assignment.dta (32 strata).
- (reproduction.json) Time fixed effects: each neighborhood's campaign date is the median registration date in it; window from the midpoint of the two arms' earliest neighborhood dates to the midpoint of their latest; consecutive two-calendar-month bins from the window start; neighborhoods outside the window dropped. This drops 19 Central neighborhoods in Local vs Central and 35 in CLI vs Central.
- (reproduction.json) Table 6 col 1: midline surveys with tot_complete==1, deduplicated by compound, merged to the register for house band; outcome = 1 if reported visits (which include the registration visit) >= 2, 0 if not visited or visits <= 1.
- (reproduction.json) Table 5 endline bribe: endline_round1 respondents with a non-missing 'visited' answer, deduplicated by respondent code; outcome = 1 if paid the collector's transport, 0 if answered no or if not visited / nobody home; Local vs Central by survey neighborhood a7.
- (reproduction.json) Table 8 panel A col 2: CLI-arm properties matched to chief_consultations.dta pay_ease (0-2 scale), house and stratum FE.

Agent notes: Four exploratory runs (attempt-1 crashed in a descriptive helper on a Date column; none printed RESULT lines) inspected the raw data files; the first estimating script is the final run. The authors' code is not in the package (no script files in the mount); README.pdf and output.tex were not opened. While reading paper.txt for method, the Table 4/5/6/7/8 text was read in passing (some unwithheld cells such as cluster counts and a few non-target coefficients are visible there); no specification was changed after the estimating run, and no adjustment was made toward any paper number. Main uncertainty: the exact construction of the campaign-period time fixed effects (neighborhood date definition and bin boundaries), which governs n_obs_table4_col2 and all time-FE columns; and the endline/midline sample definitions. No sandbox run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 27,951 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 900 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 276 bytes, from `benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,461 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 162 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 31,406 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 258 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,931 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 243,935 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 259 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 6,474 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 9,260 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 259 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/attempt-3/timing.json`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 2,655 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 2,663 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 259 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/attempt-4/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 3,264 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/reproduction.json`
- [`output/script.R`](output/script.R) — 8,837 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 634 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,993 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 259 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171527Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
