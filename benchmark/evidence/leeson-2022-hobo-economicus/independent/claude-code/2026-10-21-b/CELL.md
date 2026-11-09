# leeson-2022-hobo-economicus · independent · claude-code · 2026-10-21-b

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-21-b |
| Date | 2026-10-22T02:07:52Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-7papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261022T021417Z` |
| Run directory | `benchmark/reproductions/leeson-2022-hobo-economicus/independent/2026-10-21-b` |
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

Agent notes: Built the station-visit panel from metrovisitslog.csv (242 visits), merging WMATA monthly exits by station-month-year (Georgetown assigned Foggy Bottom), station-average friendliness (each passerby's highest response category 1-5 flagged in passresp1-5, averaged over all passersby at the station), shuttle and service indicators (walking minutes <= 10). Table 1 summary statistics are matched exactly. Table 2: OLS of panhandlers on these regressors with date fixed effects and SEs clustered by station (fixest). Attempt 1 used fixest's default singleton removal, which dropped single-visit dates (240/98 obs); after comparing with the claimed observation counts, the final run keeps singletons (fixef.rm='none'), giving 242/102 obs. Coefficients are unchanged, and the clustered SEs then match the paper's Table 2 to 3 decimals. Tables 3-4: Brown-Forsythe test (car::leveneTest, center=median) and one-way ANOVA of donations/hour (donations/minutes*60, n=80) and dollars/hour ((cash+inkind)/minutes*60, n=67) across the five stations. All values match the paper.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 15,829 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261022T021417Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 844 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261022T021417Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 253 bytes, from `benchmark/.cache/claude-code/leeson-2022-hobo-economicus/independent/2026-10-21-b/paper.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 70 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261022T021417Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 3,561 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261022T021417Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 126 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261022T021417Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,460 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261022T021417Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,558 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261022T021417Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,599 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261022T021417Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261022T021417Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,461 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261022T021417Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
