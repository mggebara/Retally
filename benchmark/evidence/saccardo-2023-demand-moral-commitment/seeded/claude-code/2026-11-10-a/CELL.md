# saccardo-2023-demand-moral-commitment · seeded · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `saccardo-2023-demand-moral-commitment` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T07:05:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-saccardo-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/seeded/claude-code/20261110T112200Z` |
| Run directory | `benchmark/reproductions/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 13/13 |
| First scored | 13/13 (execution 1) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `see_incentive_first_costly_table2_col1` | -0.139 (0.018) | -0.139343 | 0.25% | ±0.00278 (relative) | PASS | PASS |
| `assess_quality_first_costly_table2_col1` | 0.152 (0.029) | 0.151746 | 0.17% | ±0.00304 (relative) | PASS | PASS |
| `choice_free_professionals_table2_col1` | -0.095 (0.026) | -0.095206 | 0.22% | ±0.0019 (relative) | PASS | PASS |
| `selfishness_table2_col2` | 0.028 (0.007) | 0.028195 | 0.70% | ±0.00056 (relative) | PASS | PASS |
| `selfishness_table2_col3` | 0.039 (0.009) | 0.039165 | 0.42% | ±0.00078 (relative) | PASS | PASS |
| `see_incentive_first_costly_x_selfishness_table2_col3` | -0.022 (0.016) | -0.022393 | 1.79% | ±0.0005 (printed_precision) | PASS | PASS |
| `see_quality_first_costly_x_selfishness_table2_col3` | -0.021 (0.018) | -0.02114 | 0.67% | ±0.0005 (printed_precision) | PASS | PASS |
| `n_obs_table2_col1` | 5908 | 5908 | 0.00% | ±295.4 (relative) | PASS | PASS |
| `n_obs_table2_cols2_3` | 5196 | 5196 | 0.00% | ±259.8 (relative) | PASS | PASS |
| `prefer_see_incentive_first_assigned_table3_col1` | 0.195 (0.016) | 0.195469 | 0.24% | ±0.0039 (relative) | PASS | PASS |
| `prefer_see_incentive_first_not_assigned_table3_col2` | 0.003 (0.029) | 0.002992 | 0.27% | ±0.0005 (printed_precision) | PASS | PASS |
| `prefer_see_incentive_first_x_not_assigned_table3_col3` | -0.14 (0.026) | -0.140218 | 0.16% | ±0.0028 (relative) | PASS | PASS |
| `n_obs_table3_col1` | 4448 | 4448 | 0.00% | ±222.4 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Single run, no prior attempts. Translated the Table 2 and Table 3 regressions of Code/analysis.do: loaded Data/Clean Data/choice_experiments.dta, dropped non-professional (study!=1) participants with missing alphavaluefinal, restricted to Highx10==0 & Highx100==0, and ran OLS (lm) with HC3 robust SEs (sandwich::vcovHC) on the authors' covariates2 list. Table 2 col 2 restricts to professionals==0; col 3 drops professionals implicitly via missing stdalpha (as in Stata). Table 3 cols 1/2 split on getyourchoice==1/0; col 3 pools and adds notgetyourchoice and its interactions. Collinear terms (professionalsfree, professionalscloudresearch in AMT-only samples) are dropped as in Stata. Run done in a scratch directory and copied into the output directory. The run took about 1.4 s and did not hang. I did not compare results with the claims through check_attempt or change the script afterwards.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 150,702 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/seeded/claude-code/20261110T112200Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 764 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/seeded/claude-code/20261110T112200Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 269 bytes, from `benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a/paper.txt`

## What it produced

- [`output/reproduction.json`](output/reproduction.json) — 1,335 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/seeded/claude-code/20261110T112200Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,983 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/seeded/claude-code/20261110T112200Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/seeded/claude-code/20261110T112200Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 5,198 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/seeded/claude-code/20261110T112200Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 258 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/seeded/claude-code/20261110T112200Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
