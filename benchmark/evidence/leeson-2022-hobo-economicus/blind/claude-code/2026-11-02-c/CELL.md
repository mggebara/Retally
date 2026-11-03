# leeson-2022-hobo-economicus · blind · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:19:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T202753Z` |
| Run directory | `benchmark/reproductions/leeson-2022-hobo-economicus/blind/2026-11-02-c` |
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

Agent notes: attempt-1: exploratory run (codebook, station names, merges); no RESULT lines. attempt-2: full estimation. Coefficients came from fixest, which by default drops singleton date fixed effects (240/98 obs). Final run: same specification, but singletons kept (fixef.rm='none'; observation counts from an equivalent lm with date dummies). This matches a plain OLS with date dummies and gives 242/102 station-visits. Coefficients are identical; nothing was compared with paper values. Specification: OLS of panhandlers per visit on monthly passersby (thousands exiting; matched by visit month/year; Georgetown already carries Foggy Bottom's counts in passersby.csv), station-average friendliness (mean over passersby of their highest response category marked 1), shuttle indicator (shuttlemin<=10), service indicator (servicemin<=10), date FE, SEs clustered by station. Five-station subsample = Farragut North, Farragut West, Gallery Place, McPherson Square, Metro Center. Receipts: donations/minutes*60 (80 obs); (cash+inkind)/minutes*60 with rows missing either dropped (67 obs). Brown-Forsythe = car::leveneTest(center=median) F; ANOVA F = one-way aov by station. The Docker command was run through a wrapper script (literal paths) because of the sandbox guard. No hangs.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 16,735 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T202753Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 812 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T202753Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 253 bytes, from `benchmark/.cache/claude-code/leeson-2022-hobo-economicus/blind/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,131 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T202753Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T202753Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 20,539 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T202753Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,437 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T202753Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 126 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T202753Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,785 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T202753Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,805 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T202753Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,873 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T202753Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T202753Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,087 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261102T202753Z/stdout.txt`
