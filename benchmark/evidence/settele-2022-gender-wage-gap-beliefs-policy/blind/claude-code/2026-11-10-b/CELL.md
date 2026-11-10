# settele-2022-gender-wage-gap-beliefs-policy · blind · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `settele-2022-gender-wage-gap-beliefs-policy` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T06:30:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-settele-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062753Z` |
| Run directory | `benchmark/reproductions/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-b` |
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
| `perception_index_democrat_table3_panelA_col4` | 0.691 (0.066) | 0.75941 | 9.90% | ±0.066 (se_band) | FAIL | FAIL |
| `perception_index_female_table3_panelA_col4` | 0.181 (0.057) | 0.207721 | 14.76% | ±0.057 (se_band) | PASS | PASS |
| `perception_index_prior_table3_panelB_col4` | -0.729 (0.065) | -0.792905 | 8.77% | ±0.065 (se_band) | PASS | PASS |
| `n_obs_table3` | 921 | 925 | 0.43% | ±46.05 (relative) | PASS | PASS |
| `policy_demand_index_democrat_table4_panelA_col7` | 0.669 (0.051) | 0.899916 | 34.52% | ±0.051 (se_band) | FAIL | FAIL |
| `policy_demand_index_prior_table4_panelB_col7` | -0.302 (0.054) | -0.410443 | 35.91% | ±0.054 (se_band) | FAIL | FAIL |
| `first_stage_posterior_raw_t74_table5_panelA_col1` | -12.955 (0.594) | -12.9502 | 0.04% | ±0.594 (se_band) | PASS | PASS |
| `first_stage_posterior_z_t74_table5_panelA_col2` | -0.658 (0.03) | -0.586687 | 10.84% | ±0.03 (se_band) | FAIL | FAIL |
| `perception_index_t74_table5_panelA_col6` | 0.417 (0.032) | 0.457323 | 9.67% | ±0.032 (se_band) | FAIL | FAIL |
| `iv_affirmative_action_posterior_table5_panelC_col2` | -0.171 (0.053) | -0.191897 | 12.22% | ±0.053 (se_band) | PASS | PASS |
| `iv_equal_pay_legislation_posterior_table5_panelC_col3` | -0.177 (0.053) | -0.198462 | 12.13% | ±0.053 (se_band) | PASS | PASS |
| `iv_policy_demand_index_posterior_table5_panelC_col7` | -0.087 (0.038) | -0.130791 | 50.33% | ±0.038 (se_band) | FAIL | FAIL |
| `followup_perception_index_t74_table6_panelA_col7` | 0.156 (0.045) | 0.194246 | 24.52% | ±0.045 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/13 pass, which agrees with the row's 7/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Policy demand index: wage transparency within firms (wave A) and the reporting website (wave B) were never elicited jointly, so their covariance is not identified; each is z-scored on its own wave's pure control group and they share one slot in the Anderson (2008) index, which therefore has 5 inverse-covariance-weighted inputs instead of 6 separate ones.
- (reproduction.json) Anderson index implementation (paper gives no formula): items z-scored on the pure control group (unweighted); weights are row sums of the inverse covariance matrix of the standardized items over the full main-survey sample (all 4,065, unweighted); index is the weighted mean of the non-missing items, re-standardized on the pure control group. The follow-up index uses the full follow-up sample for z-scoring, covariance and re-standardization.
- (reproduction.json) Trimming for Tables 3-4: 5th/95th percentiles of the prior computed on the full main-survey sample (type-2 quantiles, giving 50 and 116, the cut-offs the paper reports in Appendix G); the task text says the control group's distribution, whose percentiles would be 50 and 113. Kept control respondents with 50 < prior < 116 (strict).
- (reproduction.json) Prior (Table 3/4 Panel B) and posterior (Table 5 col 2 and the 2SLS) z-scored with the pure control group's mean and SD (both waves pooled, unweighted). Posterior regressions have no dummies for the posterior-statistic version (Table 5 notes list none).

Agent notes: Independent blind reproduction from the raw LimeSurvey exports (Stage I wave A/B main surveys, Stage II follow-ups). Response codes were decoded from the .lss survey-structure files (XML data, not scripts): RAND 0 = pure control, 1 = T74 (ACS), 2 = T94 (CPS); prior = incentivized or non-incentivized elicitation by RAND12; posterior pooled over the five randomized statistics (9 treated respondents have no posterior). Covariates were built from Stage I (Democrat = Dem + Ind. leaning Dem; Independent; 'other'; Republican + leaning Rep reference; region, 5 age brackets, employment dummies with retired/out-of-labor-force reference, >= 2-year degree, any children, log household income). Bracket-to-log-income values were taken from the author-coded loghhinc in the Stage II files; the constructed covariates match the Stage II coding for all 1,105 follow-up respondents. Probability weights per Appendix G (wave B ages 18-24 and 55-65, by gender). OLS and 2SLS with fixest, HC1-robust SEs, probability weights. Table 6 uses the Stage II files' own covariates; wave B's alternate item order (wageproblem2, where SQ003/SQ004 are swapped) was merged in. Two exploratory runs (variable listing; construction checks) printed no RESULT lines; the final run is the first and only scored run. Nothing hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 23,083 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062753Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 931 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062753Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 286 bytes, from `benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 971 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062753Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062753Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 43,507 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062753Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 263 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062753Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 4,217 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062753Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062753Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 4,951 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062753Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 263 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062753Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 3,274 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062753Z/reproduction.json`
- [`output/script.R`](output/script.R) — 9,350 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062753Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 303 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062753Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 8,546 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062753Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 263 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062753Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
