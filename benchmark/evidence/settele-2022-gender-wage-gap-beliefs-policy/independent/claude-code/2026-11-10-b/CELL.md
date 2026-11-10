# settele-2022-gender-wage-gap-beliefs-policy · independent · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `settele-2022-gender-wage-gap-beliefs-policy` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T06:28:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-settele-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z` |
| Run directory | `benchmark/reproductions/settele-2022-gender-wage-gap-beliefs-policy/independent/2026-11-10-b` |
| Executions | 6 |
| Refinements | 2 (0 error + 2 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 4) |
| Final | **13/13** |
| Package files withheld | 34 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `perception_index_democrat_table3_panelA_col4` | 0.691 (0.066) | 0.69168 | 0.10% | ±0.066 (se_band) | PASS | PASS |
| `perception_index_female_table3_panelA_col4` | 0.181 (0.057) | 0.185238 | 2.34% | ±0.057 (se_band) | PASS | PASS |
| `perception_index_prior_table3_panelB_col4` | -0.729 (0.065) | -0.733978 | 0.68% | ±0.065 (se_band) | PASS | PASS |
| `n_obs_table3` | 921 | 921 | 0.00% | ±46.05 (relative) | PASS | PASS |
| `policy_demand_index_democrat_table4_panelA_col7` | 0.669 (0.051) | 0.669064 | 0.01% | ±0.051 (se_band) | PASS | PASS |
| `policy_demand_index_prior_table4_panelB_col7` | -0.302 (0.054) | -0.303753 | 0.58% | ±0.054 (se_band) | PASS | PASS |
| `first_stage_posterior_raw_t74_table5_panelA_col1` | -12.955 (0.594) | -12.9502 | 0.04% | ±0.594 (se_band) | PASS | PASS |
| `first_stage_posterior_z_t74_table5_panelA_col2` | -0.658 (0.03) | -0.659462 | 0.22% | ±0.03 (se_band) | PASS | FAIL |
| `perception_index_t74_table5_panelA_col6` | 0.417 (0.032) | 0.415603 | 0.34% | ±0.032 (se_band) | PASS | PASS |
| `iv_affirmative_action_posterior_table5_panelC_col2` | -0.171 (0.053) | -0.17072 | 0.16% | ±0.053 (se_band) | PASS | PASS |
| `iv_equal_pay_legislation_posterior_table5_panelC_col3` | -0.177 (0.053) | -0.176561 | 0.25% | ±0.053 (se_band) | PASS | PASS |
| `iv_policy_demand_index_posterior_table5_panelC_col7` | -0.087 (0.038) | -0.086099 | 1.04% | ±0.038 (se_band) | PASS | PASS |
| `followup_perception_index_t74_table6_panelA_col7` | 0.156 (0.045) | 0.154521 | 0.95% | ±0.045 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) The z-scored posterior belief (Table 5 Panel A col 2 and the 2SLS regressor in Panel C) is standardized with the mean and SD of the treatment-arm sample, pooled across the five posterior-statistic versions. The paper does not say which reference sample it uses for this variable; this choice was made after two claim comparisons (pure-control pooled SD, then pure-control SD by statistic version, both gave about -0.59 instead of -0.658).
- (reproduction.json) In the policy demand index, wage transparency (wave A) and the reporting website (wave B) enter as one item, each z-scored on its own wave's pure control group, because no respondent answered both.

Agent notes: Analysis data were built from the raw LimeSurvey exports (SurveyStageI_WaveA/B_raw.dta for the main survey, SurveyStageII_WaveA/B_raw.dta for the follow-up). The survey .lss files (survey structure, not code) were used to decode answer codes. Treatment: RAND0 1-4 = ACS/$74 (T74), 5-8 = CPS/$94 (T94), 9+ = pure control; this matches RAND 1/2/0. Prior = elicitbgendeMarc or elicitbgendernoinMar (incentivized or not). Controls (region, age brackets, employment, 2-year college+, log household income, children, party groups) were coded from Stage I and checked against the constructed variables in the Stage II files; they match exactly. Probability weights follow Appendix G.1 (wave B: ages 18-24 F 0.6298 / M 1.4615, ages 55-65 F 0.8691 / M 1.0184; all others 1). Tables 3/4 sample: pure control group with prior strictly between its 5th and 95th percentiles (50 and 113), N=921. Outcomes are z-scored on the pure control group (main survey) or on the full follow-up sample (Table 6). The Anderson (2008) indices are inverse-covariance-weighted averages of the standardized items and are not re-standardized. They use the covariance over the full main sample (main survey) or the full follow-up sample. All regressions are weighted OLS/2SLS with heteroskedasticity-robust SEs (fixest). Table 5/6 controls are as listed in the paper's Table 5 notes. Exploratory runs (attempts 1-3) inspected variables, crosswalks and the trimming rule's row counts. No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 22,521 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 962 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 286 bytes, from `benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/independent/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 907 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 67,877 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 269 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,127 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 11,200 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 269 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 1,182 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 1,410 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 269 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-3/timing.json`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 117 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 10,055 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 520 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 4,124 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 269 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-4/timing.json`
- [`output/attempt-5/feedback.txt`](output/attempt-5/feedback.txt) — 117 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-5/feedback.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 10,546 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 520 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 4,297 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-5/stdout.txt`
- [`output/attempt-5/timing.json`](output/attempt-5/timing.json) — 268 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/attempt-5/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,847 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/reproduction.json`
- [`output/script.R`](output/script.R) — 10,481 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 520 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,224 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 269 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T062914Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
