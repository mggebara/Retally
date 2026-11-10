# saccardo-2023-demand-moral-commitment · independent · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `saccardo-2023-demand-moral-commitment` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T11:28:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-saccardo-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z` |
| Run directory | `benchmark/reproductions/saccardo-2023-demand-moral-commitment/independent/2026-11-10-b` |
| Executions | 5 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 3) |
| Final | **13/13** |
| Package files withheld | 4 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `see_incentive_first_costly_table2_col1` | -0.139 (0.018) | -0.139346 | 0.25% | ±0.018 (se_band) | PASS | PASS |
| `assess_quality_first_costly_table2_col1` | 0.152 (0.029) | 0.151734 | 0.17% | ±0.029 (se_band) | PASS | PASS |
| `choice_free_professionals_table2_col1` | -0.095 (0.026) | -0.083541 | 12.06% | ±0.026 (se_band) | PASS | FAIL |
| `selfishness_table2_col2` | 0.028 (0.007) | 0.028195 | 0.70% | ±0.007 (se_band) | PASS | PASS |
| `selfishness_table2_col3` | 0.039 (0.009) | 0.039165 | 0.42% | ±0.009 (se_band) | PASS | PASS |
| `see_incentive_first_costly_x_selfishness_table2_col3` | -0.022 (0.016) | -0.022393 | 1.79% | ±0.016 (se_band) | PASS | PASS |
| `see_quality_first_costly_x_selfishness_table2_col3` | -0.021 (0.018) | -0.02114 | 0.67% | ±0.018 (se_band) | PASS | PASS |
| `n_obs_table2_col1` | 5908 | 5908 | 0.00% | ±295.4 (relative) | PASS | PASS |
| `n_obs_table2_cols2_3` | 5196 | 5196 | 0.00% | ±259.8 (relative) | PASS | PASS |
| `prefer_see_incentive_first_assigned_table3_col1` | 0.195 (0.016) | 0.195751 | 0.39% | ±0.016 (se_band) | PASS | PASS |
| `prefer_see_incentive_first_not_assigned_table3_col2` | 0.003 (0.029) | 0.002286 | 23.80% | ±0.029 (se_band) | PASS | PASS |
| `prefer_see_incentive_first_x_not_assigned_table3_col3` | -0.14 (0.026) | -0.140367 | 0.26% | ±0.026 (se_band) | PASS | PASS |
| `n_obs_table3_col1` | 4448 | 4448 | 0.00% | ±222.4 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Probabilistic-incentive control is the dataset's incentiveshigh (randomized $15-to-1-in-100 payment within AMT wave 2) and its interaction with incentiveleft, not probabilistic_incentive (which also equals 1 for every professional); the paper's 'whether incentives were probabilistic' is ambiguous on this point. Chosen after the attempt-3 claim comparison.
- (reproduction.json) Selfishness is the dataset's prebuilt stdalpha (standardized MPL count, standardized over all advisors with a consistent MPL, including high-stakes variants), not re-standardized within the regression sample.
- (reproduction.json) Wave controls entered as a factor of the wave variable (AMT-1, AMT-2, AMT-3, Prolific/CloudResearch); the Prolific/CloudResearch level is collinear with the Professionals indicator and is dropped.

Agent notes: Data: Data/Clean Data/choice_experiments.dta. Sample: the four main Choice treatments (Choice Free AMT, Choice Free-Professionals, Incentive First Costly, Quality First Costly), excluding the High Stakes 10x/100x variants and AMT advisors with inconsistent MPL answers (missing stdalpha, i.e. multiple switchers); this gives exactly the Table 1 Ns (2574/712/1562/1067), and after age missings N=5908 (Table 2 col 1), 5196 (cols 2-3), 4448/1460/5908 (Table 3). OLS linear probability models with HC3 SEs (sandwich), controls female, age, wave factor, probabilistic incentive, incentive-left position and their interaction. Outcome Table 2: choicebefore; Table 3: recommendincentive with choicebefore, noconflict, interactions, treatment indicators, incentiveB; split by getyourchoice. Attempts 1, 2 and 4 were exploratory (variable inspection, sample counts, alternative control codings; no RESULT lines). Attempt-3 was the first scored run; check_attempt flagged only choice_free_professionals_table2_col1 (-0.022 vs -0.095); after switching the probabilistic control to incentiveshigh it is -0.084 (SE 0.023 vs paper 0.026). All other reproduced coefficients and counts match the paper to the reported precision. No hang occurred; every sandbox run took under 2 s.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 26,738 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 899 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 274 bytes, from `benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/independent/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 806 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 8,362 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,185 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,971 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/attempt-2/timing.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 108 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 4,117 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 7,550 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/attempt-3/timing.json`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 1,354 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 150 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 3,886 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/attempt-4/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,718 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,728 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,105 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112911Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
