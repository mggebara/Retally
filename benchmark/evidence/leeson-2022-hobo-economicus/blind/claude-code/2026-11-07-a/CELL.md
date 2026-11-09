# leeson-2022-hobo-economicus · blind · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T21:06:48Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261108T015659Z` |
| Run directory | `benchmark/reproductions/leeson-2022-hobo-economicus/blind/2026-11-07-a` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
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

Agent notes: Table 2: OLS (fixest) of panhandlers per station-visit on WMATA monthly exits for the visit's month/year (passersby.csv already gives Georgetown Foggy Bottom's counts), station-average friendliness (each passerby's highest coded response category 1-5, averaged over all passersby surveyed at the station), shuttle-stop indicator (shuttlemin <= 10), homeless-service indicator (servicemin <= 10), date fixed effects, SEs clustered by station. Variable means match Table 1 Panel A (348.954, 3.112, 0.368). Tables 3/4: donations/hour = donations/minutes*60; dollars/hour = (cash+inkind)/minutes*60; Brown-Forsythe = car::leveneTest(center=median) F; ANOVA = aov F. Attempt-1 (it printed RESULT lines) differed from the final run in two sample-definition choices. Both were changed before the final run without comparing to any reported value: (1) fixest dropped singleton date groups (240/98 obs); the final keeps them (fixef.rm='none'; coefficients identical) since the paper describes plain OLS with date dummies over all station-visits; (2) attempt-1 treated a missing in-kind value as 0, giving 70 dollar observations vs the 67 the task description states; the final treats dollars as missing when either cash or in-kind was unrecorded (3 rows), giving 67. Disclosure: while reading the paper's method sections I saw the unredacted Table 4 sums of squares and Table 3 per-station means/SDs (these were not withheld in paper.txt). I did not use them to choose the specification, though the final dollars sample is consistent with them.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 17,010 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261108T015659Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 812 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261108T015659Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 253 bytes, from `benchmark/.cache/claude-code/leeson-2022-hobo-economicus/blind/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 3,612 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261108T015659Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 126 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261108T015659Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 3,382 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261108T015659Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 248 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261108T015659Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,018 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261108T015659Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,751 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261108T015659Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261108T015659Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,384 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261108T015659Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 247 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261108T015659Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
