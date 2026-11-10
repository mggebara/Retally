# saccardo-2023-demand-moral-commitment · independent · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `saccardo-2023-demand-moral-commitment` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T11:22:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-saccardo-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z` |
| Run directory | `benchmark/reproductions/saccardo-2023-demand-moral-commitment/independent/2026-11-10-a` |
| Executions | 6 |
| Refinements | 3 (1 error + 2 claim) |
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

- (reproduction.json) Probabilistic-incentive control entered as incentiveshigh (probabilistic incentives randomized within AMT wave 2) rather than probabilistic_incentive (which also equals 1 for every professional). Using probabilistic_incentive makes the Choice Free--Professionals indicator nearly collinear with it (prof coef -0.022, SE 0.048); the chosen coding gives -0.084 (SE 0.023), closer to the paper's -0.095 (0.026). Other coefficients are identical under both codings.

Agent notes: Data: Data/Clean Data/choice_experiments.dta. Sample: the four main Choice treatments (Choice Free--Professionals; Choice Free AMT = studies 2, 4, 6 without the High Stakes x10/x100 arms; Incentive First Costly; Quality First Costly), keeping AMT advisors with a consistent MPL (non-missing selfishness, stdalpha) and non-missing age, giving N=5908 / 5196 / 4448 exactly as in the paper. OLS with HC3 SEs; controls female, age, wave dummies, probabilistic incentives, incentivized product on left, and their interaction. Outcome Table 2: choicebefore; Table 3: recommendincentive, split by getyourchoice. All claims match to 3 decimals except Choice Free--Professionals in Table 2 col 1 (-0.084 vs -0.095), which depends on how the professional sample's design controls are coded; no tried variant (year dummies, no probabilistic control, etc.) gave -0.095. attempt-1/2 exploratory (variable inspection); attempt-3 first estimate (prof -0.022); attempt-4 same estimate plus diagnostic variants of the prof coefficient; attempt-5 an invalid run where script.R had not been written on the host so Docker mounted an empty directory (no output), fixed by writing the file. Paper text and the dataset's README.pdf were not read beyond paper.txt; no author scripts opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 26,738 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 899 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 274 bytes, from `benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/independent/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 812 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 10,443 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,064 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 6,496 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-2/timing.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 108 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 3,069 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 8,323 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-3/timing.json`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 108 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 4,302 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 9,027 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-4/timing.json`
- [`output/attempt-5/feedback.txt`](output/attempt-5/feedback.txt) — 255 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-5/feedback.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-5/stdout.txt`
- [`output/attempt-5/timing.json`](output/attempt-5/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/attempt-5/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,467 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,302 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 8,323 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 263 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/independent/claude-code/20261110T112910Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
