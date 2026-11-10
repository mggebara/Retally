# saccardo-2023-demand-moral-commitment · blind · claude-code · 2026-11-10-d

| | |
|---|---|
| Paper | `saccardo-2023-demand-moral-commitment` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-d |
| Date | 2026-11-10T11:27:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run4-1paper-saccardo-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z` |
| Run directory | `benchmark/reproductions/saccardo-2023-demand-moral-commitment/blind/2026-11-10-d` |
| Executions | 4 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 4) |
| Final | **12/13** |
| Package files withheld | 4 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `see_incentive_first_costly_table2_col1` | -0.139 (0.018) | -0.139346 | 0.25% | ±0.018 (se_band) | PASS | PASS |
| `assess_quality_first_costly_table2_col1` | 0.152 (0.029) | 0.151734 | 0.17% | ±0.029 (se_band) | PASS | PASS |
| `choice_free_professionals_table2_col1` | -0.095 (0.026) | -0.021749 | 77.11% | ±0.026 (se_band) | FAIL | FAIL |
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

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Data: Data/Clean Data/choice_experiments.dta. Attempts 1-3 were exploratory (variable inspection, sample counts; no RESULT lines). Sample: four main Choice treatments (High-Stakes x10/x100 arms dropped); AMT advisors with inconsistent MPL responses (missing alphavaluefinal/stdalpha) excluded per the paper's preregistered rule, professionals (no MPL) kept; this reproduces the Table 1 Ns exactly (2574/712/1562/1067). 7 further observations drop for missing age. Table 2: OLS of choicebefore on seeincentivecostly, seequalitycostly, professionalsfree (col 1) or stdalpha (cols 2-3, AMT only; plus interactions in col 3), controls female, age, wave2, wave3 (wave1 base; professionals have no AMT wave), probabilistic_incentive, incentiveleft, incentiveshigh_incentiveleft; HC3 SEs. Table 3: OLS of recommendincentive on choicebefore, noconflict, choicebefore x noconflict, treatment dummies, incentiveB and the same controls, split by getyourchoice (cols 1-2) and pooled with notgetyourchoice and its interactions with choicebefore and noconflict (col 3); HC3. Selfishness uses the dataset's stdalpha (standardized alphavaluefinal). No hangs; each sandbox run took ~2 s.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 27,301 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 868 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 274 bytes, from `benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/blind/2026-11-10-d/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 723 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 210 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 10,739 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 257 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,090 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 210 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 4,854 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 257 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 660 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 210 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 3,649 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 257 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/attempt-3/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,771 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,877 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 8,004 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 257 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112917Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
