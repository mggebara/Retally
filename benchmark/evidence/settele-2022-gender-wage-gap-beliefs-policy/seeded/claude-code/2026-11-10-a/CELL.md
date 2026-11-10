# settele-2022-gender-wage-gap-beliefs-policy · seeded · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `settele-2022-gender-wage-gap-beliefs-policy` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T06:24:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-settele-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T062750Z` |
| Run directory | `benchmark/reproductions/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-a` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 2) |
| Final | **13/13** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `perception_index_democrat_table3_panelA_col4` | 0.691 (0.066) | 0.690988 | 0.00% | ±0.01382 (relative) | PASS | PASS |
| `perception_index_female_table3_panelA_col4` | 0.181 (0.057) | 0.181404 | 0.22% | ±0.00362 (relative) | PASS | PASS |
| `perception_index_prior_table3_panelB_col4` | -0.729 (0.065) | -0.72936 | 0.05% | ±0.01458 (relative) | PASS | PASS |
| `n_obs_table3` | 921 | 921 | 0.00% | ±46.05 (relative) | PASS | PASS |
| `policy_demand_index_democrat_table4_panelA_col7` | 0.669 (0.051) | 0.669333 | 0.05% | ±0.01338 (relative) | PASS | PASS |
| `policy_demand_index_prior_table4_panelB_col7` | -0.302 (0.054) | -0.301538 | 0.15% | ±0.00604 (relative) | PASS | PASS |
| `first_stage_posterior_raw_t74_table5_panelA_col1` | -12.955 (0.594) | -12.9502 | 0.04% | ±0.2591 (relative) | PASS | PASS |
| `first_stage_posterior_z_t74_table5_panelA_col2` | -0.658 (0.03) | -0.658248 | 0.04% | ±0.01316 (relative) | PASS | PASS |
| `perception_index_t74_table5_panelA_col6` | 0.417 (0.032) | 0.41705 | 0.01% | ±0.00834 (relative) | PASS | PASS |
| `iv_affirmative_action_posterior_table5_panelC_col2` | -0.171 (0.053) | -0.171035 | 0.02% | ±0.00342 (relative) | PASS | PASS |
| `iv_equal_pay_legislation_posterior_table5_panelC_col3` | -0.177 (0.053) | -0.176886 | 0.06% | ±0.00354 (relative) | PASS | PASS |
| `iv_policy_demand_index_posterior_table5_panelC_col7` | -0.087 (0.038) | -0.086531 | 0.54% | ±0.00174 (relative) | PASS | PASS |
| `followup_perception_index_t74_table6_panelA_col7` | 0.156 (0.045) | 0.155612 | 0.25% | ±0.00312 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: attempt-1 was an exploratory run that inspected raw variable types and codes in the four survey files (no estimates). The final script translates dofiles 03/04 (Stage I cleaning of the variables needed), 05 (append, oversampling weights, z-scoring on the pure control group, Anderson-style indices with weights from the inverse correlation matrix -- weights match those in All.log), 06 (follow-up cleaning, full-sample z-scoring, follow-up perception index) and 08 (Tables 3-6) into R with fixest: weighted OLS with HC1 SEs, 2SLS for Table 5 Panel C with zposterior instrumented by T1, zposterior computed with Stata aweight mean/sd, Table 3/4 trimming at Stata 'summarize, detail' percentiles (R quantile type 2). The census/CPS treatment-value step (02) was skipped since no claim depends on it. All 13 claims reproduce to the reported precision except the Table 5 col 1 first stage (-12.950 vs -12.955 claimed). No comparison-driven changes were made.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 224,807 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T062750Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 820 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T062750Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 281 bytes, from `benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,491 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T062750Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T062750Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 8,534 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T062750Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 264 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T062750Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,454 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T062750Z/reproduction.json`
- [`output/script.R`](output/script.R) — 10,144 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T062750Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 303 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T062750Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,216 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T062750Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 264 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T062750Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
