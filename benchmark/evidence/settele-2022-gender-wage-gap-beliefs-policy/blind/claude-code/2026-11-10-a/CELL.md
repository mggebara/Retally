# settele-2022-gender-wage-gap-beliefs-policy · blind · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `settele-2022-gender-wage-gap-beliefs-policy` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T06:27:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-settele-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z` |
| Run directory | `benchmark/reproductions/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-a` |
| Executions | 5 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 8/13 (execution 4) |
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
| `iv_policy_demand_index_posterior_table5_panelC_col7` | -0.087 (0.038) | -0.130791 | 50.33% | ±0.038 (se_band) | FAIL | PASS |
| `followup_perception_index_t74_table6_panelA_col7` | 0.156 (0.045) | 0.194218 | 24.50% | ±0.045 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/13 pass, which agrees with the row's 7/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Table 3/4 sample trimmed at the 5th/95th percentiles of the full main-survey prior distribution (50 and 116, strict inequalities), which are the cutoffs stated in the paper's Appendix G; the task context describes the control group's own percentiles (which would be 50 and 113).
- (reproduction.json) Policy demand index: wage transparency (wave A only) and the reporting website (wave B only) are never observed for the same respondent, so their covariance is unidentified; they enter the Anderson index through one wave-specific slot (each z-scored on its own wave's pure control group), giving a 5-slot inverse-covariance weighted index.
- (reproduction.json) Anderson (2008) indices: items z-scored on the pure control group (follow-up: full follow-up sample), weights = row sums of the inverse covariance matrix estimated on the whole main (resp. follow-up) sample, weighted mean over non-missing items, then re-standardised on the pure control group (resp. full follow-up sample). Z-scoring and covariance are unweighted.
- (reproduction.json) Prior and posterior z-scored with the mean/sd of the full (untrimmed) pure control group; the posterior pools the five randomized statistic versions without version dummies (Table 5 notes list none).
- (reproduction.json) Table 5/6 controls: female, census region dummies, four age-group dummies (55-65 omitted), any children, log household income (bracket values taken from the cleaned follow-up files), 2-year college degree+, full-time, part-time, self-employed, unemployed, student, raw prior, wave B, Democrat, Independent, other political orientation. Probability weights as in Appendix G (wave B age 18-24 and 55-65 by gender); HC1 robust SEs; 2SLS via fixest.
- (DEVIATION: line) Table 3/4 trimming uses the 5th/95th percentiles of the full main-survey prior distribution (the cutoffs the paper's appendix states), not the control group's own percentiles.

Agent notes: All variables were built from the raw LimeSurvey exports (SurveyStageI_Wave{A,B}_raw.dta) with answer codes decoded from the survey .lss definitions in the mount; treatment arm from RAND (1 = $74/ACS, 2 = $94/CPS, 0 = pure control), giving 3,031 treated, 1,034 control, 1,105 follow-up respondents. Covariate codings and the probability weights were checked against the cleaned covariates in the follow-up files (all matched). Follow-up wave B items: wageproblem2 swaps the high/low-skilled sub-items, handled. attempt-1..3 were exploratory (variable listing, .lss decoding, covariate validation; attempt-1 crashed on a labelled-vector comparison, no RESULT lines). attempt-4 printed results with a pairwise-covariance policy index that set the unidentified transparency/website covariance to zero; this gave degenerate index weights (equal pay legislation weight 0.015 vs transparency 0.83), so on methodological grounds alone (no comparison with any paper value) the final run uses the single-slot construction. Only policy-index quantities changed between attempt-4 and the final run. While reading the paper text for methods I saw non-target numbers in Tables 2-4 (e.g. columns 1-3 of Table 3) and the Appendix G cutoffs (50/116); none was used to tune any estimate. Read Me.pdf and output/Display_Output.tex were not opened. No host R was run; all runs took about 2 s, no hangs.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 23,083 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 931 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 286 bytes, from `benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 936 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 1,300 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 52,727 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 263 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,052 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 150,170 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 263 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 3,087 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 6,086 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 263 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/attempt-3/timing.json`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 9,312 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 183 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 1,722 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 263 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/attempt-4/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 3,711 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/reproduction.json`
- [`output/script.R`](output/script.R) — 9,571 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 183 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,708 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 263 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/blind/claude-code/20261110T062752Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
