# saccardo-2023-demand-moral-commitment · independent · claude-code · 2026-11-10-d

| | |
|---|---|
| Paper | `saccardo-2023-demand-moral-commitment` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-d |
| Date | 2026-11-10T11:28:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run4-1paper-saccardo-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z` |
| Run directory | `benchmark/reproductions/saccardo-2023-demand-moral-commitment/independent/2026-11-10-d` |
| Executions | 5 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 4) |
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

- (reproduction.json) Probabilistic-incentive and product-position controls are coded as the AMT wave-2 randomized design variation (incentiveshigh, incentiveleft, incentiveshigh_incentiveleft); the professionals' always-probabilistic scheme is absorbed by their treatment indicator. The first scored run (attempt-4) used probabilistic_incentive (which is 1 for all professionals) and gave a Choice Free-Professionals coefficient of -0.022; the change was made after comparing with the claimed -0.095.
- (reproduction.json) Selfishness uses the dataset's stdalpha (standardized MPL count) as provided; HC3 SEs via sandwich::vcovHC on lm.

Agent notes: Data: Data/Clean Data/choice_experiments.dta only. Sample: the four main Choice treatments (Table 1): AMT Choice Free (waves 1-3, low/standard and wave-2 probabilistic incentives; the 10-fold and 100-fold High Stakes arms dropped), Incentive First Costly (waves 1 and 3), Quality First Costly, plus 712 professionals; AMT advisors kept only with a consistent MPL (non-missing selfishness), which reproduces Table 1 Ns 2,574/1,562/1,067/712; dropping 7 advisors with missing age gives N=5,908 (5,196 AMT). Outcomes: choicebefore (prefer incentive first) for Table 2, recommendincentive for Table 3; controls female, age, AMT-2/AMT-3 wave dummies, probabilistic, position and their interaction. Table 3 splits on getyourchoice; column 3 adds notgetyourchoice and its interactions with choicebefore and noconflict. All Table 2/3 targets reproduce to 3 decimals except Choice Free-Professionals (-0.084 vs -0.095); Table 3 professionals coefficients (not claimed) also differ somewhat, suggesting the authors' exact coding of the probabilistic/position controls differs slightly. Attempts 1-3 were exploratory (variable inspection, sample counts). Runs were run in a scratch directory and copied here. No hangs.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 26,738 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 899 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 274 bytes, from `benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/independent/2026-11-10-d/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 634 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 210 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 6,693 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 858 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 4,697 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 515 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 2,976 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/attempt-3/timing.json`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 108 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 3,675 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 5,059 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/attempt-4/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,483 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,970 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,837 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112914Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
