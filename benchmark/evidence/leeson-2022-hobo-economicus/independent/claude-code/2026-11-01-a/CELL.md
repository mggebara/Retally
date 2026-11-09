# leeson-2022-hobo-economicus · independent · claude-code · 2026-11-01-a

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-01-a |
| Date | 2026-11-02T04:27:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-13papers-indep-blind-2026-11-01.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T043820Z` |
| Run directory | `benchmark/reproductions/leeson-2022-hobo-economicus/independent/2026-11-01-a` |
| Executions | 3 |
| Refinements | 1 (0 error + 1 claim) |
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

Agent notes: attempt-1: exploratory data inspection (no RESULT lines). attempt-2: full analysis. Table 2: OLS of panhandlers per station-visit on monthly passersby (WMATA exits; Georgetown matched to Foggy Bottom if absent from passersby file -- it was present in the file), station-average friendliest response (max category 1-5 per passerby), shuttle (shuttlemin<=10) and service (servicemin<=10) indicators, date FE, SEs clustered by station (fixest). Tables 3/4: donations and dollars (cash+inkind, rows with both non-missing -> 67) per hour = x/minutes*60; Brown-Forsythe = car::leveneTest center=median; one-way ANOVA F. attempt-2 matched every coefficient and statistic, but fixest dropped date-singleton observations (240/98 vs 242/102). After the check_attempt comparison (five-station N 98 vs 102 off target), the final run keeps singletons (fixef.rm='none'). Coefficients are unchanged, and SEs (0.851, 2.793, 0.182, 0.227) and adjusted R2 (0.39, 0.06) now also match the paper's Table 2. Final run: all claims within tolerance.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 15,804 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T043820Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 844 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T043820Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 253 bytes, from `benchmark/.cache/claude-code/leeson-2022-hobo-economicus/independent/2026-11-01-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 905 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T043820Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T043820Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 6,461 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T043820Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 87 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T043820Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,425 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T043820Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 126 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T043820Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,804 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T043820Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,574 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T043820Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,459 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T043820Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T043820Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,805 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/independent/claude-code/20261102T043820Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
