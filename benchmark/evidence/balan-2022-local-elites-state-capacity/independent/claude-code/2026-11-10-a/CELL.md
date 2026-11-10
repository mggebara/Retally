# balan-2022-local-elites-state-capacity · independent · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `balan-2022-local-elites-state-capacity` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T17:17:31Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-balan-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z` |
| Run directory | `benchmark/reproductions/balan-2022-local-elites-state-capacity/independent/2026-11-10-a` |
| Executions | 10 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 11/13 (execution 10) |
| Final | **11/13** |
| Package files withheld | 58 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `compliance_local_table4_panelA_col1` | 0.023 (0.008) | 0.024298 | 5.64% | ±0.008 (se_band) | PASS | PASS |
| `compliance_local_table4_panelA_col2` | 0.032 (0.007) | 0.038535 | 20.42% | ±0.007 (se_band) | PASS | PASS |
| `compliance_local_house_fe_table4_panelA_col4` | 0.033 (0.007) | 0.038866 | 17.78% | ±0.007 (se_band) | PASS | PASS |
| `compliance_local_exempt_excluded_table4_panelA_col5` | 0.04 (0.008) | 0.0469 | 17.25% | ±0.008 (se_band) | PASS | PASS |
| `revenue_local_table4_panelB_col2` | 79.64 (22.856) | 90.0659 | 13.09% | ±22.856 (se_band) | PASS | PASS |
| `revenue_local_house_fe_table4_panelB_col4` | 68.855 (20.56) | 82.0899 | 19.22% | ±20.56 (se_band) | PASS | PASS |
| `n_obs_table4_col1` | 28872 | 28921 | 0.17% | ±1443.6 (relative) | PASS | PASS |
| `n_obs_table4_col2` | 27764 | 27507 | 0.93% | ±1388.2 (relative) | PASS | PASS |
| `paid_bribe_endline_local_table5_panelB` | 0.018 (0.009) | 0.0136 | 24.44% | ±0.009 (se_band) | PASS | PASS |
| `visited_by_collector_local_table6_col1` | -0.009 (0.026) | 0.029637 | 429.30% | ±0.026 (se_band) | FAIL | FAIL |
| `compliance_cli_table7_col1` | 0.024 (0.009) | 0.017639 | 26.50% | ±0.009 (se_band) | PASS | PASS |
| `revenue_cli_table7_col2` | 46.566 (21.2) | 17.9642 | 61.42% | ±21.2 (se_band) | FAIL | FAIL |
| `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 (0.007) | 0.052338 | 6.54% | ±0.007 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/13 pass, which agrees with the row's 11/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) The package ships only raw (01_base) data, so the analysis file was rebuilt: properties = non-pilot registration records with house type low/high (villas excluded) that carry a numeric tax liability on the tax roll (drops 'Voir le tract', 'Paye', blank and villa rows), deduplicated by compound code. This gives 28,921 Local+Central properties vs 28,872 in the paper.
- (reproduction.json) De facto assignment: the paper says one CXL neighborhood was run by the chief alone; registration records show chief-only teams in CXL neighborhoods 654 and 639. Neighborhood 654 was recoded to Local (a guess).
- (reproduction.json) Time fixed effects: property-level registration date; two-month (61-day) bins starting at floor of the midpoint between the two arms' first registration days, ending at the midpoint between their last days; properties outside dropped. Local-Central gives 213 clusters (as in the paper) but 27,507 obs (paper 27,764); CLI-Central gives 155 clusters (paper 165).
- (reproduction.json) Revenue = receipt amount (amountCF) matched by compound code, 0 for non-payers; two receipts with amounts above 1.4 million CF (max liability 13,200 CF) were set to the property's liability.
- (reproduction.json) Exempt (Table 4 col 5) = collector designated exempt in the registration record. House FE = registration house type (low/high band).
- (reproduction.json) Table 6 outcome: midline (tot_complete==1, first record per compound) visits >= 2 (registration visit counted in 'visits'), 0 if household reported no visit; 99999 codes set missing.
- (reproduction.json) Table 5 endline bribe: endline round 1 'bribe' (paid the collector's transport), asked only of households visited with someone present; set to 0 for households reporting no visit or a visit with nobody home (N = 1,222 vs paper 1,169).
- (reproduction.json) Table 8: chief consultation pay_ease (0-2; 'don't know' set missing), CLI properties, house and stratum FE, N = 8,159 (paper 8,135).

Agent notes: Independent reconstruction from paper text and raw admin/survey data. Strata from randomization_assignment.dta (32 strata); SEs clustered by neighborhood (a7) with fixest. Nine exploratory runs (no RESULT lines) inspected the data, sample definition and time-window variants; attempt-8 crashed in a diagnostic table (exploratory only). The first estimating run is the final run. After it, I compared the results with the claims using check_attempt: two claims were outside tolerance (revenue_cli_table7_col2 reproduced 17.96 vs claimed 46.57; visited_by_collector_local_table6_col1 reproduced 0.030 vs claimed -0.009). I did not change the script after the comparison. The main uncertainty is the exact time-window construction (online Appendix A2.5 is not in the paper text) and the analysis-sample cleaning, which cannot be fully reconstructed from the noPII raw files. No runs hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 27,387 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 931 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 276 bytes, from `benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,536 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 38,064 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 264 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 4,330 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 353 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 6,166 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 264 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 2,504 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 20,295 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 265 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-3/timing.json`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 2,487 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 2,410 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 264 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-4/timing.json`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 3,102 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 143 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 7,922 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-5/stdout.txt`
- [`output/attempt-5/timing.json`](output/attempt-5/timing.json) — 265 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-5/timing.json`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 2,196 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 320 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 42,227 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-6/stdout.txt`
- [`output/attempt-6/timing.json`](output/attempt-6/timing.json) — 265 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-6/timing.json`
- [`output/attempt-7/script.R`](output/attempt-7/script.R) — 2,609 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-7/script.R`
- [`output/attempt-7/stderr.txt`](output/attempt-7/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-7/stderr.txt`
- [`output/attempt-7/stdout.txt`](output/attempt-7/stdout.txt) — 2,533 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-7/stdout.txt`
- [`output/attempt-7/timing.json`](output/attempt-7/timing.json) — 265 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-7/timing.json`
- [`output/attempt-8/script.R`](output/attempt-8/script.R) — 2,011 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-8/script.R`
- [`output/attempt-8/stderr.txt`](output/attempt-8/stderr.txt) — 337 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-8/stderr.txt`
- [`output/attempt-8/stdout.txt`](output/attempt-8/stdout.txt) — 37,870 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-8/stdout.txt`
- [`output/attempt-8/timing.json`](output/attempt-8/timing.json) — 265 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-8/timing.json`
- [`output/attempt-9/script.R`](output/attempt-9/script.R) — 4,797 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-9/script.R`
- [`output/attempt-9/stderr.txt`](output/attempt-9/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-9/stderr.txt`
- [`output/attempt-9/stdout.txt`](output/attempt-9/stdout.txt) — 3,038 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-9/stdout.txt`
- [`output/attempt-9/timing.json`](output/attempt-9/timing.json) — 265 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/attempt-9/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 3,690 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/reproduction.json`
- [`output/script.R`](output/script.R) — 7,745 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,973 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 265 bytes, from `benchmark/results/artifacts/balan-2022-local-elites-state-capacity/independent/claude-code/20261110T171751Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
