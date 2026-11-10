# settele-2022-gender-wage-gap-beliefs-policy · blind · claude-code · 2026-11-10-c

| | |
|---|---|
| Paper | `settele-2022-gender-wage-gap-beliefs-policy` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-c |
| Date | 2026-11-10T06:38:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run3-1paper-settele-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z` |
| Run directory | `benchmark/reproductions/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-c` |
| Executions | 4 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 6/13 (execution 4) |
| Final | **6/13** |
| Package files withheld | 34 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `perception_index_democrat_table3_panelA_col4` | 0.691 (0.066) | 0.761115 | 10.15% | ±0.066 (se_band) | FAIL | FAIL |
| `perception_index_female_table3_panelA_col4` | 0.181 (0.057) | 0.203834 | 12.62% | ±0.057 (se_band) | PASS | PASS |
| `perception_index_prior_table3_panelB_col4` | -0.729 (0.065) | -0.807659 | 10.79% | ±0.065 (se_band) | FAIL | FAIL |
| `n_obs_table3` | 921 | 921 | 0.00% | ±46.05 (relative) | PASS | PASS |
| `policy_demand_index_democrat_table4_panelA_col7` | 0.669 (0.051) | 0.904202 | 35.16% | ±0.051 (se_band) | FAIL | FAIL |
| `policy_demand_index_prior_table4_panelB_col7` | -0.302 (0.054) | -0.410505 | 35.93% | ±0.054 (se_band) | FAIL | FAIL |
| `first_stage_posterior_raw_t74_table5_panelA_col1` | -12.955 (0.594) | -12.9502 | 0.04% | ±0.594 (se_band) | PASS | PASS |
| `first_stage_posterior_z_t74_table5_panelA_col2` | -0.658 (0.03) | -0.586687 | 10.84% | ±0.03 (se_band) | FAIL | FAIL |
| `perception_index_t74_table5_panelA_col6` | 0.417 (0.032) | 0.457323 | 9.67% | ±0.032 (se_band) | FAIL | FAIL |
| `iv_affirmative_action_posterior_table5_panelC_col2` | -0.171 (0.053) | -0.191897 | 12.22% | ±0.053 (se_band) | PASS | PASS |
| `iv_equal_pay_legislation_posterior_table5_panelC_col3` | -0.177 (0.053) | -0.198462 | 12.13% | ±0.053 (se_band) | PASS | PASS |
| `iv_policy_demand_index_posterior_table5_panelC_col7` | -0.087 (0.038) | -0.130791 | 50.33% | ±0.038 (se_band) | FAIL | FAIL |
| `followup_perception_index_t74_table6_panelA_col7` | 0.156 (0.045) | 0.194246 | 24.52% | ±0.045 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 6/13 pass, which agrees with the row's 6/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Anderson (2008) summary indices: components z-scored on the pure control group (follow-up: full follow-up sample), weights = row sums of the inverse covariance matrix of the standardized components computed on the full sample the index is built on (all 4,065 main-survey respondents; 1,105 follow-up respondents), weighted mean over non-missing components, then re-standardized on the pure control group (follow-up: full follow-up sample). The paper does not state which sample the covariance matrix uses or whether the index is re-standardized.
- (reproduction.json) Policy demand index: wage transparency (wave A) and the reporting website (wave B) are the same survey slot (transparencyanchor); each is z-scored on its own wave's control group and they enter the index as one component (5 components), because the two items are never observed jointly and no covariance between them exists.
- (reproduction.json) Prior belief z-scored with the unweighted mean and SD of the full (untrimmed) pure control group; trimming uses Stata-style (type 2) unweighted 5th/95th percentiles of the control group's prior (50 and 113), keeping priors strictly inside.
- (reproduction.json) Posterior belief (Table 5 col 2 and the 2SLS regressor) z-scored with the pure control group's mean and SD of the pooled posterior statistic.
- (reproduction.json) Standardizations are unweighted; probability weights are used in all regressions; robust (HC1) standard errors via fixest.
- (reproduction.json) Main-survey covariates were rebuilt from raw LimeSurvey codes (answer codes taken from the .lss survey definitions); log household income uses the bracket values found in the authors' follow-up files.

Agent notes: Data are raw LimeSurvey exports (Stage I = main survey waves A/B, Stage II = follow-up waves A/B). Treatment from RAND (0 control, 1 = ACS/$74 = T74, 2 = CPS/$94), cross-checked against which treatment page each respondent saw. N: 4,065 main (1,034 control, 3,031 treated; 3,022 with posterior), 921 trimmed controls (443 wave A, 478 wave B), 1,105 follow-up. Rebuilt covariates match the authors' constructed covariates in the follow-up files for all 1,105 matched respondents (one prior-belief mismatch in wave B). Prior = incentivized or non-incentivized elicitation; posterior pooled over the five randomized statistics. Probability weights per Appendix G (wave B, ages 18-24: F 0.6298 / M 1.4615; ages 55-65: F 0.8691 / M 1.0184; otherwise 1), identical to the pweight in the follow-up files. Follow-up perception index: men-women problem, government support for women, high-skilled and low-skilled men-women problem. In wave B the alternative-order block wageproblem2 swaps SQ003/SQ004 (low/high skilled) per the .lss and was recoded. Attempts 1-3 were exploratory (variable listing, .lss codebook parsing, cross-checks; attempt 2 crashed on a wave-specific group-timer name) and printed no RESULT lines. Read Me.pdf, output/Display_Output.tex and ado files were not opened. The large IPUMS ACS/CPS extracts were not used, because none of the quantities depends on them. No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 23,083 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 931 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 286 bytes, from `benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,051 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 66,860 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 263 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 5,017 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 171 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,591 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 262 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 5,351 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 32,864 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 262 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/attempt-3/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 3,617 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/reproduction.json`
- [`output/script.R`](output/script.R) — 11,877 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 303 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,585 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 263 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T063901Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
