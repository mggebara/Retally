# leeson-2022-hobo-economicus · blind · claude-code · 2026-11-01-a

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-01-a |
| Date | 2026-11-02T04:21:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-13papers-indep-blind-2026-11-01.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T043821Z` |
| Run directory | `benchmark/reproductions/leeson-2022-hobo-economicus/blind/2026-11-01-a` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 10/11 (execution 2) |
| Final | **11/11** |
| Package files withheld | 6 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `passersby_full_sample` | 0.005 (0.001) | 0.00491392 | 1.72% | ±0.001 (se_band) | PASS | PASS |
| `passersby_five_station_subsample` | 0.006 (0.002) | 0.00613459 | 2.24% | ±0.002 (se_band) | PASS | PASS |
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

Agent notes: attempt-1: exploratory (station-name matching, merges, missingness; no RESULT lines). attempt-2: first full estimation; fixest's default dropped date fixed-effect singletons (N 240/98). Final: same specification with fixef.rm='none' so N counts every station-visit, as OLS with date dummies would (242/102). Coefficients are identical; the change was made for a method reason, not by comparison with any paper value (none were seen). Spec: OLS of panhandlers per visit on monthly station exits (passersby.csv merged on station-month-year; Georgetown assigned Foggy Bottom's counts), station mean of each passerby's friendliest response (highest marked category 1-5), shuttle indicator (shuttlemin<=10) and service indicator (servicemin<=10), visit-date FE, SEs clustered by station; five-station subsample = Farragut North, Farragut West, Gallery Place, McPherson Square, Metro Center. Receipts: donations/minutes*60 (N=80); (cash+inkind)/minutes*60, keeping rows with both non-missing (N=67). Brown-Forsythe = car::leveneTest(center=median); one-way ANOVA via aov.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 16,382 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T043821Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 812 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T043821Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 253 bytes, from `benchmark/.cache/claude-code/leeson-2022-hobo-economicus/blind/2026-11-01-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 964 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T043821Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T043821Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 16,883 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T043821Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,664 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T043821Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 126 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T043821Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,795 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T043821Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,602 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T043821Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,795 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T043821Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T043821Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,797 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T043821Z/stdout.txt`
