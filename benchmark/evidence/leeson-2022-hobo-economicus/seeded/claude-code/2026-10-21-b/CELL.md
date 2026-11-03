# leeson-2022-hobo-economicus · seeded · claude-code · 2026-10-21-b

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-21-b |
| Date | 2026-10-22T02:03:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-7papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/claude-code/20261022T021417Z` |
| Run directory | `benchmark/reproductions/leeson-2022-hobo-economicus/seeded/2026-10-21-b` |
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

Agent notes: Translated 1_dataprep.do and 2_analysis.do to R in a single run. metroid is rebuilt alphabetically per file, the way Stata encode does it; the five subsample stations (ids 9,10,14,17,18) are Farragut North, Farragut West, Gallery Place, McPherson Square and Metro Center. Friendliness is each passerby's highest response category, averaged by station. service and shuttle are walking distance <= 10 minutes. Table 2 is feols(panhandlers ~ passersby + friendly + shuttle + service \| day, cluster = metroid, fixef.rm = 'none'). Brown-Forsythe is car::leveneTest(center = median), the same as Stata robvar W50. ANOVA is a one-way aov by station. N = 242/102 station-visits and 80/67 receipt observations. The first run matched every claim at the printed precision, so there are no attempts and no claim comparison was used to change the script.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 31,476 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/claude-code/20261022T021417Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 719 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/claude-code/20261022T021417Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 248 bytes, from `benchmark/.cache/claude-code/leeson-2022-hobo-economicus/seeded/2026-10-21-b/paper.txt`

## What it produced

- [`output/reproduction.json`](output/reproduction.json) — 1,269 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/claude-code/20261022T021417Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,626 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/claude-code/20261022T021417Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/claude-code/20261022T021417Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,225 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/seeded/claude-code/20261022T021417Z/stdout.txt`
