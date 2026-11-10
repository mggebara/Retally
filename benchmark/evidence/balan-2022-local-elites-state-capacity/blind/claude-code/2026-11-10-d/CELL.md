# balan-2022-local-elites-state-capacity · blind · claude-code · 2026-11-10-d

| | |
|---|---|
| Paper | `balan-2022-local-elites-state-capacity` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-d |
| Date | 2026-11-10T17:15:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run4-1paper-balan-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z` |
| Run directory | `benchmark/reproductions/balan-2022-local-elites-state-capacity/blind/2026-11-10-d` |
| Executions | 8 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 8) |
| Final | **12/13** |
| Package files withheld | 58 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `compliance_local_table4_panelA_col1` | 0.023 (0.008) | 0.024418 | 6.17% | ±0.008 (se_band) | PASS | PASS |
| `compliance_local_table4_panelA_col2` | 0.032 (0.007) | 0.038989 | 21.84% | ±0.007 (se_band) | PASS | PASS |
| `compliance_local_house_fe_table4_panelA_col4` | 0.033 (0.007) | 0.039555 | 19.86% | ±0.007 (se_band) | PASS | PASS |
| `compliance_local_exempt_excluded_table4_panelA_col5` | 0.04 (0.008) | 0.047605 | 19.01% | ±0.008 (se_band) | PASS | PASS |
| `revenue_local_table4_panelB_col2` | 79.64 (22.856) | 92.0574 | 15.59% | ±22.856 (se_band) | PASS | PASS |
| `revenue_local_house_fe_table4_panelB_col4` | 68.855 (20.56) | 83.6806 | 21.53% | ±20.56 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 28872 | 29384 | 1.77% | ±1443.6 (relative) | PASS | PASS |
| `n_obs_table4_col2` | 27764 | 27911 | 0.53% | ±1388.2 (relative) | PASS | PASS |
| `paid_bribe_endline_local_table5_panelB` | 0.018 (0.009) | 0.013775 | 23.47% | ±0.009 (se_band) | PASS | PASS |
| `visited_by_collector_local_table6_col1` | -0.009 (0.026) | 0.027554 | 406.16% | ±0.026 (se_band) | FAIL | FAIL |
| `compliance_cli_table7_col1` | 0.024 (0.009) | 0.019927 | 16.97% | ±0.009 (se_band) | PASS | PASS |
| `revenue_cli_table7_col2` | 46.566 (21.2) | 30.333 | 34.86% | ±21.2 (se_band) | PASS | PASS |
| `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 (0.007) | 0.059273 | 5.84% | ±0.007 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Analysis data rebuilt from raw base files (authors' cleaning code withheld). Register = registration_noPII rows in the 356 randomised neighbourhoods, pilot==0, tot_complete==1, house band 1/2 (villas excluded), deduplicated on compound1 (tax ID). This yields 29,384 Local+Central properties; the authors' exact register cleaning rules are unknown.
- (reproduction.json) Compliance = tax ID appears in tax_payments_noPII (after dropping duplicate receipt copies, dup_receipt>=1). Revenue = sum of amountCF for the tax ID; 7 payers with missing amounts or amounts above the top statutory liability (13,200 CF; e.g. 1,421,700 and 1,662,800 CF entry errors) are set to their statutory liability (3,000 or 13,200 CF).
- (reproduction.json) Time fixed effects: property-level registration dates (registration start timestamp). Arm first/last days = min/max registration date of each arm; window from floor of the midpoint of the two first days to the midpoint of the two last days; two-month calendar periods counted from the window start; properties outside the window dropped. The paper's note to Table 4 col 3 (time periods vary within neighbourhood) motivated property-level dating.
- (reproduction.json) De facto treatment: neighbourhood a7 654 (assigned CXL) coded Local, identified from chief-only registration teams and the endline file's treatment code.
- (reproduction.json) Table 6 col 1: midline complete non-pilot surveys excluding flagged duplicates/unknown compounds, one row per compound; visited after registration = total reported visits >= 2 (the visits question includes the registration visit), 0 if visited==No or visits<=1; merged to the register by tax ID for house type and time period.
- (reproduction.json) Table 5 endline bribe: endline_round1 complete surveys; outcome 1 if paid collector 'transport' (bribe==1), 0 if bribe==0 or the household reported no visit / no one home (question skipped); don't know/refuse dropped.
- (reproduction.json) Table 8: CLI register properties merged to chief_consultations by compound1, pay_ease in {0,1,2} (don't know dropped); 0-2 coding (slope identical to a 1-3 coding).

Agent notes: Seven exploratory runs (variable listings, tabulations, date/sample diagnostics; no RESULT lines) then one final run estimating all 13 quantities with fixest (feols, SEs clustered by neighbourhood a7, randomisation stratum = randomization_assignment$stratum). No error repairs and no claim comparisons. Read the redacted paper.txt for method only. The final L/C window retained 213 of 221 clusters. Uncertainties: register sample cleaning (counts exceed the paper's Table 2 arm sizes by ~1-2%), payment-amount cleaning, the exact construction of campaign-period dates (registration dates for some neighbourhoods look like late data entry), midline duplicate handling, and the coding of non-asked endline bribe responses. No hung runs.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 27,951 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 900 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 276 bytes, from `benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-d/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,035 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 21,945 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 258 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,719 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 8,423 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 258 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 3,732 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 7,387 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 259 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-3/timing.json`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 1,986 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 75,643 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 259 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-4/timing.json`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 2,723 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 3,344 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-5/stdout.txt`
- [`output/attempt-5/timing.json`](output/attempt-5/timing.json) — 259 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-5/timing.json`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 3,157 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 8,272 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-6/stdout.txt`
- [`output/attempt-6/timing.json`](output/attempt-6/timing.json) — 259 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-6/timing.json`
- [`output/attempt-7/script.R`](output/attempt-7/script.R) — 2,930 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-7/script.R`
- [`output/attempt-7/stderr.txt`](output/attempt-7/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-7/stderr.txt`
- [`output/attempt-7/stdout.txt`](output/attempt-7/stdout.txt) — 2,646 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-7/stdout.txt`
- [`output/attempt-7/timing.json`](output/attempt-7/timing.json) — 259 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/attempt-7/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 3,604 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/reproduction.json`
- [`output/script.R`](output/script.R) — 8,077 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 5,316 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 259 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/blind/claude-code/20261110T171750Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
