# saccardo-2023-demand-moral-commitment · blind · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `saccardo-2023-demand-moral-commitment` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T11:27:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-saccardo-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112915Z` |
| Run directory | `benchmark/reproductions/saccardo-2023-demand-moral-commitment/blind/2026-11-10-b` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 3) |
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

- (reproduction.json) Wave controls coded as AMT wave 2 and AMT wave 3 dummies (AMT wave 1 as base); professionals form their own wave/indicator, so the Choice Free-Professionals coefficient is relative to AMT Choice Free advisors net of these wave dummies. The paper does not state which wave is the reference category.
- (reproduction.json) 'Whether incentives were probabilistic' coded with probabilistic_incentive (1 for professionals and the probabilistic AMT wave-2 subsample); 'position of products' coded with incentiveleft; interaction = probabilistic_incentive x incentiveleft (equal to incentiveshigh_incentiveleft in the data).

Agent notes: Data: Data/Clean Data/choice_experiments.dta only. Sample: four main Choice treatments (Choice Free AMT, Choice Free-Professionals, Incentive First Costly, Quality First Costly), High Stakes x10/x100 arms dropped; AMT advisors restricted to attentive advisors with consistent MPL responses (non-missing selfishness measure), which reproduces the Table 1 Ns exactly (2,574 / 712 / 1,562 / 1,067); 7 further observations drop for missing age. Selfishness = stdalpha (standardized MPL count). OLS linear probability models with HC3 SEs (sandwich). Table 2 col1: choicebefore on professionals, costly-treatment dummies and controls (female, age, wave dummies, probabilistic, product position, probabilistic x position); cols 2-3 AMT only with selfishness (and its interactions with the two costly dummies). Table 3: recommendincentive on prefer-incentive-first, no-conflict and their interaction, treatment dummies, incentiveB and the same controls, split by assigned/not assigned preference (getyourchoice), and pooled with not-assigned and its interactions. Two exploratory runs (attempt-1, attempt-2) inspected variables and counts only and printed no RESULT lines. No author scripts, result files or online sources consulted; no run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 27,301 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112915Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 868 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112915Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 274 bytes, from `benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/blind/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 572 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112915Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112915Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 12,296 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112915Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 257 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112915Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,533 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112915Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112915Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 11,687 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112915Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 257 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112915Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,397 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112915Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,939 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112915Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112915Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,338 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112915Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 257 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112915Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
