# saccardo-2023-demand-moral-commitment · blind · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `saccardo-2023-demand-moral-commitment` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T07:04:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-saccardo-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112202Z` |
| Run directory | `benchmark/reproductions/saccardo-2023-demand-moral-commitment/blind/2026-11-10-a` |
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

_None declared._

Agent notes: Independent blind reproduction from Data/Clean Data/choice_experiments.dta only. Attempts 1-2 were exploratory (variable listing, cross-tabs of treatments/waves/sample flags), no RESULT lines. Main Choice sample: drop the High Stakes (10-fold, 100-fold) robustness treatments and, for AMT advisors, those without a consistent MPL selfishness score (multiple switchers; preregistered restriction described in the paper); this yields exactly the Table 1 counts (Choice Free 2574, Professionals 712, Incentive First Costly 1562, Quality First Costly 1067 = 5915). Regressions dropping 7 advisors with missing age. LPMs by OLS with HC3 SEs (sandwich). Outcome Table 2: choicebefore (prefer to see incentive first); regressors professionalsfree, seeincentivecostly, seequalitycostly; Selfishness = stdalpha (standardized MPL count, as provided), interactions = indicator x stdalpha. Controls in all models: female, age, wave dummies (AMT-2, AMT-3; AMT-1 omitted, professionals' wave collinear with the Professionals indicator), probabilistic_incentive, incentiveleft (product position), probabilistic x incentiveleft. Table 3: outcome recommendincentive; regressors choicebefore, noconflict, choicebefore x noconflict, treatment indicators, incentiveB, controls; col 1 getyourchoice==1, col 2 getyourchoice==0, col 3 pooled adding notgetyourchoice and its interactions with choicebefore and noconflict. README.pdf was not read. No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 27,301 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112202Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 868 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112202Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 274 bytes, from `benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/blind/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,033 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112202Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112202Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 8,855 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112202Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 257 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112202Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,538 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112202Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112202Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,912 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112202Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 256 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112202Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,982 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112202Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,190 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112202Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112202Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 8,198 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112202Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 257 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112202Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
