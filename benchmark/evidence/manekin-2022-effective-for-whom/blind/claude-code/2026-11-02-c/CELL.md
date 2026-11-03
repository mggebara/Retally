# manekin-2022-effective-for-whom · blind · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `manekin-2022-effective-for-whom` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:20:30Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T202753Z` |
| Run directory | `benchmark/reproductions/manekin-2022-effective-for-whom/blind/2026-11-02-c` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 12/12 (execution 2) |
| Final | **12/12** |
| Package files withheld | 96 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `study1_us_black_perceived_violence` | 0.235 (0.117) | 0.235246 | 0.10% | ±0.117 (se_band) | PASS | PASS |
| `study1_us_black_police_action` | 0.268 (0.127) | 0.26801 | 0.00% | ±0.127 (se_band) | PASS | PASS |
| `study1_israel_ethiopian_perceived_violence` | 0.425 (0.107) | 0.425066 | 0.02% | ±0.107 (se_band) | PASS | PASS |
| `study1_israel_ethiopian_police_action` | 0.181 (0.118) | 0.180704 | 0.16% | ±0.118 (se_band) | PASS | PASS |
| `study1_israel_arab_perceived_violence` | 0.623 (0.108) | 0.623088 | 0.01% | ±0.108 (se_band) | PASS | PASS |
| `study1_israel_arab_police_action` | 0.964 (0.119) | 0.9642 | 0.02% | ±0.119 (se_band) | PASS | PASS |
| `study2_us_black_perceived_violence` | 0.347 (0.115) | 0.346652 | 0.10% | ±0.115 (se_band) | PASS | PASS |
| `study2_us_black_police_action` | 0.429 (0.114) | 0.42873 | 0.06% | ±0.114 (se_band) | PASS | PASS |
| `respondents_study1_us` | 2269 | 2269 | 0.00% | ±113.45 (relative) | PASS | PASS |
| `respondents_study1_israel` | 3063 | 3063 | 0.00% | ±153.15 (relative) | PASS | PASS |
| `respondents_study2_us` | 3013 | 3013 | 0.00% | ±150.65 (relative) | PASS | PASS |
| `respondents_study2_israel` | 3465 | 3465 | 0.00% | ±173.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Israeli identity factor coding assumed 0 = white Jews, 1 = Ethiopian Jews, 2 = Arabs (the paper's listing order; 0 confirmed as white by Study 2's omitted white/group-goal cells, 1 vs 2 not labelled in the data).
- (reproduction.json) Study 2 regressions are unweighted because the Study 2 data files carry no weight variable; Study 1 regressions use the 'weight' column.

Agent notes: attempt-1 was exploratory (str/tables/NA counts, no RESULT lines). Final: Study 1 weighted OLS of each 0-10 outcome on minority-identity dummies plus tactic dummies (base white protesters marching), all respondents in each file (US wave file pools its three waves; Israeli file includes Jewish and Arab respondents). Study 2 OLS on black/minority dummies + group_goal + commitment. Sample sizes are regression nobs (US S2 police action drops 5 missing, nobs 3008; perceived violence nobs 3013). No script, table, log or figure file in the dataset was opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,063 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T202753Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,002 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T202753Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 261 bytes, from `benchmark/.cache/claude-code/manekin-2022-effective-for-whom/blind/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 589 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T202753Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T202753Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 10,986 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T202753Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,411 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T202753Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,843 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T202753Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T202753Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 658 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261102T202753Z/stdout.txt`
