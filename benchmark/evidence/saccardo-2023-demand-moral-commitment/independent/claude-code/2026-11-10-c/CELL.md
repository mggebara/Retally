# saccardo-2023-demand-moral-commitment · independent · claude-code · 2026-11-10-c

| | |
|---|---|
| Paper | `saccardo-2023-demand-moral-commitment` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-c |
| Date | 2026-11-10T11:40:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run3-1paper-saccardo-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z` |
| Run directory | `benchmark/reproductions/saccardo-2023-demand-moral-commitment/independent/2026-11-10-c` |
| Executions | 4 |
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

- (reproduction.json) Choice Free-Professionals coefficient in Table 2 col 1 is -0.084 vs claimed -0.095; the exact coding of the probabilistic-incentive / product-position controls for professionals is not documented in the paper. Final script uses the dataset's wave-2 design indicators (incentiveshigh, incentiveleft, incentiveshigh_incentiveleft), which are zero for professionals.
- (reproduction.json) Table 3 Choice Free-Professionals coefficients (not claimed) do not match the paper's column values (e.g. col 1: 0.004 vs -0.026), consistent with the same control-coding uncertainty.

Agent notes: Data: Data/Clean Data/choice_experiments.dta. Sample: four main Choice treatments (Choice Free, Incentive First Costly, Quality First Costly, Choice Free-Professionals): dropped High Stakes 10x/100x treatments, and for AMT advisors kept only those with a non-missing MPL selfishness measure (attentive, consistent); this matches Table 1 Ns exactly (2574/1562/1067/712); 7 AMT advisors with missing age drop out, giving N=5908 / 5196. Outcome Table 2: choicebefore (prefers to see incentive first); Selfishness = stdalpha. Controls: female, age, wave2, wave3 dummies, wave-2 probabilistic-incentive indicator, incentive-left position indicator and their interaction. Table 3: recommendincentive on choicebefore, noconflict, their interaction, treatment dummies, incentiveB and controls; col1 getyourchoice==1 (N=4448), col2 ==0 (N=1460), col3 pooled with not-assigned and its interactions. OLS with HC3 SEs (sandwich). attempt-1/2 exploratory (variable listing, cross-tabs). attempt-3 used probabilistic_incentive (=1 for all professionals) as the control, giving professionals coef -0.022; after comparing with the claim, switched to the wave-2 design indicators (incentiveshigh family), which gives -0.084. All other claims reproduced to 3 decimals on attempt-3 and unchanged in the final run.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 26,738 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 899 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 274 bytes, from `benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/independent/2026-11-10-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 513 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 11,692 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,021 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,892 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/attempt-2/timing.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 108 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 4,432 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 8,387 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/attempt-3/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,470 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,768 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 8,609 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112913Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
