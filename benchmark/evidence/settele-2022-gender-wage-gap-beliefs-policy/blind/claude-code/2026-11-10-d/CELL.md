# settele-2022-gender-wage-gap-beliefs-policy · blind · claude-code · 2026-11-10-d

| | |
|---|---|
| Paper | `settele-2022-gender-wage-gap-beliefs-policy` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-d |
| Date | 2026-11-10T06:37:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run4-1paper-settele-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063902Z` |
| Run directory | `benchmark/reproductions/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-d` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 7/13 (execution 3) |
| Final | **7/13** |
| Package files withheld | 34 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `perception_index_democrat_table3_panelA_col4` | 0.691 (0.066) | 0.761115 | 10.15% | ±0.066 (se_band) | FAIL | FAIL |
| `perception_index_female_table3_panelA_col4` | 0.181 (0.057) | 0.203834 | 12.62% | ±0.057 (se_band) | PASS | PASS |
| `perception_index_prior_table3_panelB_col4` | -0.729 (0.065) | -0.807659 | 10.79% | ±0.065 (se_band) | FAIL | FAIL |
| `n_obs_table3` | 921 | 921 | 0.00% | ±46.05 (relative) | PASS | PASS |
| `policy_demand_index_democrat_table4_panelA_col7` | 0.669 (0.051) | 0.777977 | 16.29% | ±0.051 (se_band) | FAIL | FAIL |
| `policy_demand_index_prior_table4_panelB_col7` | -0.302 (0.054) | -0.391535 | 29.65% | ±0.054 (se_band) | FAIL | FAIL |
| `first_stage_posterior_raw_t74_table5_panelA_col1` | -12.955 (0.594) | -12.9502 | 0.04% | ±0.594 (se_band) | PASS | PASS |
| `first_stage_posterior_z_t74_table5_panelA_col2` | -0.658 (0.03) | -0.586687 | 10.84% | ±0.03 (se_band) | FAIL | FAIL |
| `perception_index_t74_table5_panelA_col6` | 0.417 (0.032) | 0.457323 | 9.67% | ±0.032 (se_band) | FAIL | FAIL |
| `iv_affirmative_action_posterior_table5_panelC_col2` | -0.171 (0.053) | -0.191897 | 12.22% | ±0.053 (se_band) | PASS | PASS |
| `iv_equal_pay_legislation_posterior_table5_panelC_col3` | -0.177 (0.053) | -0.198462 | 12.13% | ±0.053 (se_band) | PASS | PASS |
| `iv_policy_demand_index_posterior_table5_panelC_col7` | -0.087 (0.038) | -0.062164 | 28.55% | ±0.038 (se_band) | PASS | PASS |
| `followup_perception_index_t74_table6_panelA_col7` | 0.156 (0.045) | 0.194246 | 24.52% | ±0.045 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/13 pass, which agrees with the row's 7/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Analysis data rebuilt from the raw LimeSurvey exports (Stage I waves A and B, 4,065 respondents). Answer codes were mapped using the survey instruments (.lss) in the package. Covariate construction (party, region, age, children, education, employment, log household income from bracket, prior) and the Wave B probability weights (gender x age-bracket cells) were checked against the constructed variables in the follow-up files; all matched on the 1,105 linked respondents (prior matched for 1,104).
- (reproduction.json) T74 = RAND==1 (the ACS $74 screen is shown for RAND0 1-4); pure control = RAND==0.
- (reproduction.json) z-scores use the unweighted mean/SD of the full pure control group (both waves, untrimmed); the prior is z-scored the same way. The posterior belief (pooled over the five versions) is z-scored on the pure control group's posterior. No dummies for the posterior-statistic version, because Table 5's notes do not list them.
- (reproduction.json) Anderson (2008) indices: z-scored items weighted by the row sums of the inverse covariance matrix (pairwise-complete covariance over the whole main sample, or the whole follow-up sample for Table 6). Missing items are skipped in the weighted mean, and the index is re-standardized on the pure control group (on the full follow-up sample for Table 6). Wage transparency (Wave A) and the reporting website (Wave B) are never observed together, so their covariance is set to 0.
- (reproduction.json) Trimming for Tables 3-4: prior strictly between the 5th and 95th percentiles of the pooled pure-control prior distribution, unweighted, Stata-style percentiles (R quantile type 2).
- (reproduction.json) All regressions: weighted least squares with pweights and HC1 robust SEs (fixest). The 2SLS instruments the z-scored posterior with T74 and uses the full Table 5 control set.
- (reproduction.json) Follow-up Wave B: the item order was randomized (randorder2). In the second ordering (wageproblem2) sub-items 3 and 4 are low-/high-skilled, so they were swapped back before pooling. Table 6 controls come from the follow-up files.

Agent notes: Two exploratory runs printed no RESULT lines: attempt-1 listed variables, and attempt-2 checked the variable mappings and the merge with the follow-up. The final run was the first scored run and succeeded on the first try, with no error repairs and no claim comparisons. The trimmed control sample has N=921. The Table 5 posterior and 2SLS regressions use N=3,022 (9 treated respondents have no posterior). Table 6 uses N=1,105. Besides the data files, I read the LimeSurvey .lss instruments in the mount's surveys/ folder to decode answer codes, using a small host-side Python XML dump of question and answer text. That was reading only; all analysis ran in R in the sandbox. I did not open any script, log, .tex or result file in the package, and I read nothing outside the mount and paper.txt.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 23,083 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063902Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 931 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063902Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 286 bytes, from `benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-d/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,222 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063902Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063902Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 72,993 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063902Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 263 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063902Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,465 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063902Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063902Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 7,535 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063902Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 263 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063902Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 3,367 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063902Z/reproduction.json`
- [`output/script.R`](output/script.R) — 9,373 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063902Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 303 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063902Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,779 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063902Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 263 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063902Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
