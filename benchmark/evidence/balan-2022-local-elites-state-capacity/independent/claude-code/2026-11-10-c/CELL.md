# balan-2022-local-elites-state-capacity · independent · claude-code · 2026-11-10-c

| | |
|---|---|
| Paper | `balan-2022-local-elites-state-capacity` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-c |
| Date | 2026-11-10T17:23:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run3-1paper-balan-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z` |
| Run directory | `benchmark/reproductions/balan-2022-local-elites-state-capacity/independent/2026-11-10-c` |
| Executions | 13 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 13) |
| Final | **12/13** |
| Package files withheld | 58 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `compliance_local_table4_panelA_col1` | 0.023 (0.008) | 0.021121 | 8.17% | ±0.008 (se_band) | PASS | PASS |
| `compliance_local_table4_panelA_col2` | 0.032 (0.007) | 0.03592 | 12.25% | ±0.007 (se_band) | PASS | PASS |
| `compliance_local_house_fe_table4_panelA_col4` | 0.033 (0.007) | 0.036329 | 10.09% | ±0.007 (se_band) | PASS | PASS |
| `compliance_local_exempt_excluded_table4_panelA_col5` | 0.04 (0.008) | 0.043968 | 9.92% | ±0.008 (se_band) | PASS | PASS |
| `revenue_local_table4_panelB_col2` | 79.64 (22.856) | 84.6273 | 6.26% | ±22.856 (se_band) | PASS | PASS |
| `revenue_local_house_fe_table4_panelB_col4` | 68.855 (20.56) | 77.8616 | 13.08% | ±20.56 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 28872 | 28884 | 0.04% | ±1443.6 (relative) | PASS | PASS |
| `n_obs_table4_col2` | 27764 | 27446 | 1.15% | ±1388.2 (relative) | PASS | PASS |
| `paid_bribe_endline_local_table5_panelB` | 0.018 (0.009) | 0.013748 | 23.62% | ±0.009 (se_band) | PASS | PASS |
| `visited_by_collector_local_table6_col1` | -0.009 (0.026) | 0.027759 | 408.43% | ±0.026 (se_band) | FAIL | FAIL |
| `compliance_cli_table7_col1` | 0.024 (0.009) | 0.02228 | 7.17% | ±0.009 (se_band) | PASS | PASS |
| `revenue_cli_table7_col2` | 46.566 (21.2) | 33.6852 | 27.66% | ±21.2 (se_band) | PASS | PASS |
| `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 (0.007) | 0.059109 | 5.55% | ±0.007 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Property universe taken from admin_data/hh_distances.dta (45,177 properties) with registration attributes merged by compound code; its arm counts match Table 2 except Central (+12) and CLI (+3), so the Local+Central base is 28,884 rather than 28,872.
- (reproduction.json) De facto treatment: neighborhood a7=654 (assigned CXL; registration done by the chief alone; 93 properties) recoded to Local, which makes the Local and CXL counts equal Table 2 exactly.
- (reproduction.json) Compliance = tax ID appears in tax_payments_noPII.dta, excluding receipts flagged error_code==1 (tax-ID/neighborhood mismatch); with this the Central mean (0.068) and revenue mean (193.7 vs 192.9) match Table 4 column 1.
- (reproduction.json) Revenue: 8 receipt amounts that are not an official liability (e.g. 1,662,800 and 1,421,700 CF, 50 CF, missing) were replaced by the official liability implied by the receipt's USD rate (rateUSD*1900 snapped to the nearest official amount).
- (reproduction.json) Time fixed effects: property-level registration date; two-month (61-day) periods from floor(midpoint of the two arms' first registration days) to floor(midpoint of their last registration days); properties outside dropped. The exact rule of online Appendix A2.5 is not in the provided text; this gives 27,446 obs / 213 clusters for Local-Central (paper 27,764 / 213) and 19,567 / 155 for CLI-Central (paper 20,636 / 165). Extensive searches over alternative date definitions did not reproduce both paper sample sizes.
- (reproduction.json) House FE: registration house type 2 (high-value band) vs 1; exempt (Table 4 col 5) = collector-designated exempt in registration (missing treated as not exempt).
- (reproduction.json) Endline bribe (Table 5): endline_round1 'bribe' (paid the collector's transport); the question is only asked if the household reported a visit with someone home, so households reporting no visit / no one home are coded 0; one record per respondent code; Local+Central; stratum FE only. N=1,217 (paper 1,169), Central mean 0.013 (paper 0.014).
- (reproduction.json) Table 6 col 1: midline, first complete survey per compound; visited after registration = reported total visits >= 2 (the visit count includes the registration visit), 0 if no visit reported; merged to the windowed Local-Central property sample for house/period FE. N=16,323 (paper 18,162).
- (reproduction.json) Table 8 Panel A col 2: chief_consultations pay_ease (0-2; 8888 'don't know' set to missing), CLI properties, house and stratum FE (N=8,136 vs paper 8,135).

Agent notes: Independent reproduction from paper text and data only (no author code opened). Exploratory runs (attempts 1-12) inspected file structures and searched for the property universe and time-window rule; none printed RESULT lines. The final script was run once; its RESULT lines were not compared against claims to drive any change (no claim attempts). Main gaps: the campaign-period time window (online Appendix A2.5 not available) yields smaller samples than the paper for columns with time FE (27,446 vs 27,764; CLI 19,567 vs 20,636), which moves the time-FE coefficients (Local col2 0.036 vs 0.032; CLI revenue 33.7 vs 46.6). Table 6 visited sign differs (0.028 vs -0.009), likely due to the visit definition/sample. Documents read inside the mount: README.pdf and output.tex (LaTeX table shell; appendix text absent). No sandbox run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 27,387 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 931 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 276 bytes, from `benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,797 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 1,002 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 14,618 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 264 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,097 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 112,211 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 265 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 5,888 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 319 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 5,670 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 265 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-3/timing.json`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 3,484 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 6,234 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 265 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-4/timing.json`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 2,376 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 21,124 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-5/stdout.txt`
- [`output/attempt-5/timing.json`](output/attempt-5/timing.json) — 265 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-5/timing.json`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 5,512 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 6,227 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-6/stdout.txt`
- [`output/attempt-6/timing.json`](output/attempt-6/timing.json) — 264 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-6/timing.json`
- [`output/attempt-7/script.R`](output/attempt-7/script.R) — 4,078 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-7/script.R`
- [`output/attempt-7/stderr.txt`](output/attempt-7/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-7/stderr.txt`
- [`output/attempt-7/stdout.txt`](output/attempt-7/stdout.txt) — 7,835 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-7/stdout.txt`
- [`output/attempt-7/timing.json`](output/attempt-7/timing.json) — 265 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-7/timing.json`
- [`output/attempt-8/script.R`](output/attempt-8/script.R) — 2,966 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-8/script.R`
- [`output/attempt-8/stderr.txt`](output/attempt-8/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-8/stderr.txt`
- [`output/attempt-8/stdout.txt`](output/attempt-8/stdout.txt) — 1,333 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-8/stdout.txt`
- [`output/attempt-8/timing.json`](output/attempt-8/timing.json) — 265 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-8/timing.json`
- [`output/attempt-9/script.R`](output/attempt-9/script.R) — 3,312 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-9/script.R`
- [`output/attempt-9/stderr.txt`](output/attempt-9/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-9/stderr.txt`
- [`output/attempt-9/stdout.txt`](output/attempt-9/stdout.txt) — 11,139 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-9/stdout.txt`
- [`output/attempt-9/timing.json`](output/attempt-9/timing.json) — 265 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-9/timing.json`
- [`output/attempt-10/script.R`](output/attempt-10/script.R) — 2,314 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-10/script.R`
- [`output/attempt-10/stderr.txt`](output/attempt-10/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-10/stderr.txt`
- [`output/attempt-10/stdout.txt`](output/attempt-10/stdout.txt) — 20,228 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-10/stdout.txt`
- [`output/attempt-10/timing.json`](output/attempt-10/timing.json) — 265 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-10/timing.json`
- [`output/attempt-11/script.R`](output/attempt-11/script.R) — 3,456 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-11/script.R`
- [`output/attempt-11/stderr.txt`](output/attempt-11/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-11/stderr.txt`
- [`output/attempt-11/stdout.txt`](output/attempt-11/stdout.txt) — 3,868 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-11/stdout.txt`
- [`output/attempt-11/timing.json`](output/attempt-11/timing.json) — 266 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-11/timing.json`
- [`output/attempt-12/script.R`](output/attempt-12/script.R) — 3,246 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-12/script.R`
- [`output/attempt-12/stderr.txt`](output/attempt-12/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-12/stderr.txt`
- [`output/attempt-12/stdout.txt`](output/attempt-12/stdout.txt) — 5,720 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-12/stdout.txt`
- [`output/attempt-12/timing.json`](output/attempt-12/timing.json) — 265 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/attempt-12/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 4,369 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/reproduction.json`
- [`output/script.R`](output/script.R) — 8,991 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,812 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 265 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T173237Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
