# leeson-2022-hobo-economicus · seeded · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T19:35:40Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-23papers-seeded-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/claude-code/20261102T194315Z` |
| Run directory | `benchmark/reproductions/leeson-2022-hobo-economicus/seeded/2026-11-02-b` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 11/11 |
| First scored | 11/11 (execution 1) |
| Final | **11/11** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `passersby_full_sample` | 0.005 (0.001) | 0.004914 | 1.72% | ±0.0005 (printed_precision) | PASS | PASS |
| `passersby_five_station_subsample` | 0.006 (0.002) | 0.006135 | 2.25% | ±0.0005 (printed_precision) | PASS | PASS |
| `friendliness_full_sample` | 1.595 (0.851) | 1.59511 | 0.01% | ±0.0319 (relative) | PASS | PASS |
| `shuttle_stop_full_sample` | 0.781 (0.182) | 0.780689 | 0.04% | ±0.01562 (relative) | PASS | PASS |
| `shuttle_stop_five_station_subsample` | 0.89 (0.227) | 0.889644 | 0.04% | ±0.0178 (relative) | PASS | PASS |
| `brown_forsythe_donations_per_hour` | 0.541 | 0.541281 | 0.05% | ±0.00541 (relative) | PASS | PASS |
| `brown_forsythe_dollars_per_hour` | 0.276 | 0.275802 | 0.07% | ±0.00276 (relative) | PASS | PASS |
| `anova_f_donations_per_hour` | 0.4 | 0.398434 | 0.39% | ±0.005 (printed_precision) | PASS | PASS |
| `anova_f_dollars_per_hour` | 0.15 | 0.150879 | 0.59% | ±0.005 (printed_precision) | PASS | PASS |
| `station_visits_full_sample` | 242 | 242 | 0.00% | ±12.1 (relative) | PASS | PASS |
| `station_visits_five_station_subsample` | 102 | 102 | 0.00% | ±5.1 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Translated 1_dataprep.do and 2_analysis.do. Station-visit data merged by station name (equivalent to the scripts' per-file encode ids, since all files share the same 26 names); passersby merged by station-month-year; service/shuttle = walk <= 10 min; friendliness = station mean of each passerby's friendliest response (all-zero responses missing). Table 2: feols with date fixed effects (fixef.rm='none'), SEs clustered by station; subsample = alphabetical ids 9,10,14,17,18 (Farragut North, Farragut West, Gallery Place, McPherson Square, Metro Center). Table 3: car::leveneTest center=median (Stata robvar W50); Table 4: one-way ANOVA F via lm. Single run; no claim comparison followed by a script change; all values match the claims to their reported precision.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 31,327 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/claude-code/20261102T194315Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 719 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/claude-code/20261102T194315Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 248 bytes, from `benchmark/.cache/claude-code/leeson-2022-hobo-economicus/seeded/2026-11-02-b/paper.txt`

## What it produced

- [`output/reproduction.json`](output/reproduction.json) — 1,193 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/claude-code/20261102T194315Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,651 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/claude-code/20261102T194315Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/claude-code/20261102T194315Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,711 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/claude-code/20261102T194315Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
