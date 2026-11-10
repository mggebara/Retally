# settele-2022-gender-wage-gap-beliefs-policy · seeded · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `settele-2022-gender-wage-gap-beliefs-policy` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T06:35:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-settele-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T063249Z` |
| Run directory | `benchmark/reproductions/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 13/13 |
| First scored | 13/13 (execution 1) |
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

Agent notes: Single run, no attempts. Translated the authors' cleaning do-files (03, 04, 05 for the main survey; 06 for the follow-up) and the Table 3-6 regressions in 08_MainTables.do into R (haven + fixest). Main survey: z-scoring on the pure control group, Anderson-style indices weighted by the row sums of the inverse correlation matrix, wave-B probability weights. Tables 3/4: pure control group, prior z-scored, then trimmed strictly between the unweighted 5th/95th percentiles (Stata summarize-detail definition, R quantile type 2), N=921. Table 5: treatment arms, posterior z-scored with aweights (zscore.ado), OLS and 2SLS (fixest IV) with the baseline controls, pweights and HC1 SEs. Table 6: the follow-up, outcomes z-scored on the full follow-up sample, 4-item index, N=1105. Intermediate checks agree with the authors' All.log: index correlation obs 4065/1105, control group 1034, Table 5 N 3022/3031, and the Table 5 col 1 T74 coefficient -12.95017, identical to the log. The paper's -12.955 is therefore presumably a rounding or typo issue in the paper. All other claims match to the reported precision. The script was developed and run in a private scratch directory and copied here, and the run-dir passed to run_sandbox was that scratch directory. Besides the mount and the paper, I read only the task.md for this cell.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 224,807 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T063249Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 820 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T063249Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 281 bytes, from `benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b/paper.txt`

## What it produced

- [`output/reproduction.json`](output/reproduction.json) — 1,769 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T063249Z/reproduction.json`
- [`output/script.R`](output/script.R) — 11,337 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T063249Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 303 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T063249Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,437 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T063249Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 264 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/seeded/claude-code/20261110T063249Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
