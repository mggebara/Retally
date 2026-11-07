# manekin-2022-effective-for-whom · blind · claude-code · 2026-10-21-b

| | |
|---|---|
| Paper | `manekin-2022-effective-for-whom` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-21-b |
| Date | 2026-10-22T02:25:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-7papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261022T021417Z` |
| Run directory | `benchmark/reproductions/manekin-2022-effective-for-whom/blind/2026-10-21-b` |
| Executions | 3 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 12/12 (execution 3) |
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

- (reproduction.json) Study 2 regressions (US and Israel) are unweighted: the Study 2 data files contain no weight variable. Study 1 regressions use the `weight` column, as the task context states.
- (reproduction.json) The Israeli identity_protesters factor is unlabeled; codes taken as 0 = white Jews, 1 = Ethiopian Jews, 2 = Arabs, following the order the paper lists the conditions (in Study 2 code 0 has about half the cell count of the others, consistent with the two omitted white-protester conditions, which supports 0 = white; the 1 vs 2 assignment cannot be verified from the data).
- (reproduction.json) Study 1 Israel uses the full file (Jewish and Arab respondents pooled, 3063 rows); no other sample restrictions applied anywhere.
- (DEVIATION: line) Study 2 regressions are unweighted (no weight variable in the Study 2 files); Israeli identity codes assumed 0=white,1=Ethiopian,2=Arab.

Agent notes: attempt-1 inspected variables and counts (no RESULT lines). attempt-2 was the first estimation script; it crashed because lm()'s weights argument could not see a helper-function variable, fixed without changing the specification. Final: OLS of degree_violence and police_action_required (0-10) on the protester-identity indicator(s) plus treatment indicators (Study 1: tactic dummies, base white protesters marching; Study 2: group_goal and commitment, base white/generic goal/no commitment). Sample sizes are the nobs of the perceived-violence regressions (US Study 2 police-action regression has 3008 obs because of 5 missing outcomes). Only paper.txt and .rdata files under the mount were read; no scripts, tables or figures in the dataset directory were opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 20,586 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261022T021417Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,002 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261022T021417Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 274 bytes, from `benchmark/.cache/claude-code/manekin-2022-effective-for-whom/blind/2026-10-21-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 629 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261022T021417Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261022T021417Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 8,840 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261022T021417Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 435 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261022T021417Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,254 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261022T021417Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 147 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261022T021417Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261022T021417Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,013 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261022T021417Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,294 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261022T021417Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261022T021417Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 5,828 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/blind/claude-code/20261022T021417Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
