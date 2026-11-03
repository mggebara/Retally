# leeson-2022-hobo-economicus · independent · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:05:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T202751Z` |
| Run directory | `benchmark/reproductions/leeson-2022-hobo-economicus/independent/2026-11-02-c` |
| Executions | 2 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 10/11 |
| First scored | 10/11 (execution 1) |
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
| `brown_forsythe_dollars_per_hour` | 0.276 | 0.275802 | 0.07% | ±0.00276 (relative) | PASS | PASS |
| `anova_f_donations_per_hour` | 0.4 | 0.398434 | 0.39% | ±0.005 (printed_precision) | PASS | PASS |
| `anova_f_dollars_per_hour` | 0.15 | 0.150879 | 0.59% | ±0.005 (printed_precision) | PASS | PASS |
| `station_visits_full_sample` | 242 | 242 | 0.00% | ±12.1 (relative) | PASS | PASS |
| `station_visits_five_station_subsample` | 102 | 102 | 0.00% | ±5.1 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Built from the paper text and the data CSVs only; no scripts were opened. Table 2: OLS of panhandlers per station-visit on WMATA monthly exits, matched by station and month (the Georgetown row is already in passersby.csv); the station average of each passerby's friendliest response (the highest marked category, 1-5); shuttle-stop and homeless-service dummies (<=10 walking minutes); date fixed effects; SEs clustered by station (fixest). Tables 3-4: donations/minutes*60 and (cash+inkind)/minutes*60 across the five stations (N=80 and 67); Brown-Forsythe = car::leveneTest(center=median); one-way ANOVA via aov. Attempt 1 used fixest's default removal of date-FE singletons, which dropped 2 and 4 visits (N 240/98) and left the coefficients unchanged. After the check_attempt comparison, the final run keeps singletons (fixef.rm='none'). That gives N 242/102, and the clustered SEs then match the paper exactly (e.g. 0.851 and 2.793). All coefficients and test statistics match the paper to its reported precision.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 16,157 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T202751Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 844 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T202751Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 253 bytes, from `benchmark/.cache/claude-code/leeson-2022-hobo-economicus/independent/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 70 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T202751Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 3,508 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T202751Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 126 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T202751Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,104 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T202751Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,510 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T202751Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,645 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T202751Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T202751Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,105 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T202751Z/stdout.txt`
