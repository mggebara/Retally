# leeson-2022-hobo-economicus · independent · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T21:24:10Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261108T015700Z` |
| Run directory | `benchmark/reproductions/leeson-2022-hobo-economicus/independent/2026-11-07-a` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 9/11 |
| First scored | 9/11 (execution 1) |
| Final | **11/11** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `passersby_full_sample` | 0.005 (0.001) | 0.004914 | 1.72% | ±0.001 (se_band) | PASS | PASS |
| `passersby_five_station_subsample` | 0.006 (0.002) | 0.006135 | 2.25% | ±0.002 (se_band) | PASS | PASS |
| `friendliness_full_sample` | 1.595 (0.851) | 1.59511 | 0.01% | ±0.851 (se_band) | PASS | PASS |
| `shuttle_stop_full_sample` | 0.781 (0.182) | 0.780689 | 0.04% | ±0.182 (se_band) | PASS | PASS |
| `shuttle_stop_five_station_subsample` | 0.89 (0.227) | 0.889644 | 0.04% | ±0.227 (se_band) | PASS | PASS |
| `brown_forsythe_donations_per_hour` | 0.541 | 0.541281 | 0.05% | ±0.00541 (relative) | PASS | PASS |
| `brown_forsythe_dollars_per_hour` | 0.276 | 0.275802 | 0.07% | ±0.00276 (relative) | PASS | FAIL |
| `anova_f_donations_per_hour` | 0.4 | 0.398434 | 0.39% | ±0.005 (printed_precision) | PASS | PASS |
| `anova_f_dollars_per_hour` | 0.15 | 0.150879 | 0.59% | ±0.005 (printed_precision) | PASS | FAIL |
| `station_visits_full_sample` | 242 | 242 | 0.00% | ±12.1 (relative) | PASS | PASS |
| `station_visits_five_station_subsample` | 102 | 102 | 0.00% | ±5.1 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Table 2: OLS (fixest feols) of panhandlers per station-visit on WMATA monthly exits for the station in the visit month (passersby.csv, already has Georgetown rows), station mean of each passerby's friendliest response (highest category coded 1 among passresp1-5), shuttle indicator (shuttlemin <= 10), homeless-service indicator (servicemin <= 10), date fixed effects, SEs clustered by station. Five-station subsample = Farragut North/West, Gallery Place, McPherson Square, Metro Center. Tables 3-4: donations/minutes*60 and (cash+inkind)/minutes*60 by station; Brown-Forsythe = car::leveneTest(center=median), ANOVA = aov. Attempt-1 (compared with claims via check_attempt): dollars treated missing in-kind as 0 when cash was recorded, giving 70 dollar observations and off-target dollar statistics; also fixest dropped date-FE singletons (240/98 obs). Final: dollars = cash + inkind with missing propagated (67 obs, matching paper's N and per-station Ns) and fixef.rm='none' to keep singletons (242/102 obs). Final run matches all claimed coefficients, SEs, test statistics and Ns. The final docker run command took over 3 minutes of wall time to return (run_sandbox reported 5.9 s for the container); it did not hang.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 16,432 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261108T015700Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 844 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261108T015700Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 253 bytes, from `benchmark/.cache/claude-code/leeson-2022-hobo-economicus/independent/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 177 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261108T015700Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 3,692 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261108T015700Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 126 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261108T015700Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,638 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261108T015700Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 254 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261108T015700Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,714 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261108T015700Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,876 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261108T015700Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261108T015700Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,639 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261108T015700Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 253 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261108T015700Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
