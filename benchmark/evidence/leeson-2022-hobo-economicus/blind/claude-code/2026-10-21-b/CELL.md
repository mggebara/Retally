# leeson-2022-hobo-economicus · blind · claude-code · 2026-10-21-b

| | |
|---|---|
| Paper | `leeson-2022-hobo-economicus` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-21-b |
| Date | 2026-10-22T02:12:41Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-7papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261022T021417Z` |
| Run directory | `benchmark/reproductions/leeson-2022-hobo-economicus/blind/2026-10-21-b` |
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

- (reproduction.json) Homeless service / shuttle-stop indicators coded as walking time <= 10 minutes from service.csv / shuttle.csv (paper: 'within a ten-minute walk').
- (reproduction.json) Passerby friendliness = highest response category (1-5) marked for each passerby, averaged over all passersby surveyed at the station (station-level constant).
- (reproduction.json) Dollars per hour = (cash + inkind)/minutes*60, missing if either cash or inkind is missing (gives the 67 observations the paper describes).
- (reproduction.json) Brown-Forsythe = Levene test centred on the median (car::leveneTest, center=median); ANOVA = one-way lm F test.
- (reproduction.json) Table 2 estimated with fixest feols, date fixed effects, SEs clustered by station, fixef.rm='none' so date-singleton visits stay in the sample (equivalent to OLS with date dummies; point estimates unaffected).

Agent notes: attempt-1: exploratory run (merge coverage, codebook, receipt missingness), no RESULT lines. attempt-2: first scored run; fixest dropped 2 (full) and 4 (subsample) date-singleton visits by default, giving 240/98 observations although the task's sample description is all 242 station-visits and the 102 subsample visits; rerun with fixef.rm='none'. Coefficients are identical between attempt-2 and the final run; only observation counts, SEs and adjusted R2 changed. This was a sample-definition fix, not a comparison with reported values (kind '' since it was neither a crash nor a claim check). All passersby month merges succeeded (Georgetown already carries Foggy Bottom's counts in passersby.csv). Only the CSV data files and Codebook.xlsx (first sheet, variable descriptions) were read from the mount; no PDFs or scripts opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 16,407 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261022T021417Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 812 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261022T021417Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 266 bytes, from `benchmark/.cache/claude-code/leeson-2022-hobo-economicus/blind/2026-10-21-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,402 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261022T021417Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261022T021417Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 3,258 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261022T021417Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 571 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261022T021417Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 4,226 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261022T021417Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 126 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261022T021417Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,449 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261022T021417Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,176 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261022T021417Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,260 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261022T021417Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261022T021417Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,450 bytes, from `benchmark/results/artifacts/leeson-2022-hobo-economicus/blind/claude-code/20261022T021417Z/stdout.txt`
