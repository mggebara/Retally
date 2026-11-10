# settele-2022-gender-wage-gap-beliefs-policy · independent · claude-code · 2026-11-10-c

| | |
|---|---|
| Paper | `settele-2022-gender-wage-gap-beliefs-policy` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-c |
| Date | 2026-11-10T06:41:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run3-1paper-settele-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z` |
| Run directory | `benchmark/reproductions/settele-2022-gender-wage-gap-beliefs-policy/independent/2026-11-10-c` |
| Executions | 5 |
| Refinements | 3 (2 error + 1 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 3) |
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
| `followup_perception_index_t74_table6_panelA_col7` | 0.156 (0.045) | 0.155612 | 0.25% | ±0.045 (se_band) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Posterior belief (Table 5 col 2 and the 2SLS endogenous regressor) is z-scored on the treatment-arm sample (pooled over the five posterior statistics) rather than on the pure control group; chosen after the attempt-3 claim check (control-group z-scoring gave -0.587 vs claimed -0.658).
- (reproduction.json) Policy demand index: wage transparency within companies (wave A) and the reporting website (wave B), each z-scored on its own wave's control group, share one slot in a 5-input Anderson index, since the two items are never jointly observed.
- (reproduction.json) Anderson (2008) indices: weights are row sums of the inverse covariance matrix of the standardised inputs (computed on the full main-survey sample, or on the full follow-up sample for Table 6); the weighted mean is not re-standardised.
- (reproduction.json) Log household income in the main survey is mapped from the income bracket using the per-bracket values found in the package's follow-up files (loghhinc), which are constant within bracket.
- (reproduction.json) Probability weights for the main survey are rebuilt from Appendix G.1 (wave B, age 18-24: women 0.6298, men 1.4615; age 55-65: women 0.8691, men 1.0184; else 1); they match the follow-up files' pweight for all 1,105 follow-up respondents.

Agent notes: Raw LimeSurvey exports decoded with the .lss survey definitions in the mount (treatment arms: RAND=1 is the ACS/$74 arm, RAND=2 the CPS/$94 arm, RAND=0 pure control; answer codes A1..An mapped to numeric scales; wave B follow-up wageproblem2 has the high/low-skilled subquestions swapped). Main-survey covariates were cross-checked against the derived variables in the follow-up files (gender, democrat, indep, otherpol, associatemore, anychildren, pweight all agree 1105/1105; prior 1104/1105). Table 3/4 sample: pure control with prior strictly between the control group's 5th and 95th percentiles (50, 113; R quantile type 2), N=921. Outcomes z-scored on the pure control group (follow-up outcomes on the full follow-up sample). WLS with probability weights via fixest; 2SLS via fixest IV. Attempts 1-2 were exploratory runs that crashed on coding errors in the diagnostic code (no RESULT lines). Attempt 3 was the first full run, and its claim check flagged only the posterior z-score. Attempt 4 was an exploratory comparison of standardisation choices for the posterior. Read Me.pdf, output/Display_Output.tex (only its LaTeX header/table list) and the surveys/*.lss files in the mount were consulted. No Docker run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 22,521 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 962 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 286 bytes, from `benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/independent/2026-11-10-c/paper.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 277 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,370 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 1,300 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 62,427 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 269 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-1/timing.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 409 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 5,144 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 289 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 8,107 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 269 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-2/timing.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 85 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 11,000 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 303 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 5,005 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 268 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-3/timing.json`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 9,924 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 783 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 1,568 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 269 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/attempt-4/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 3,135 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/reproduction.json`
- [`output/script.R`](output/script.R) — 11,188 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 303 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 5,005 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 269 bytes, from `benchmark/results/artifacts/settele-2022-gender-wage-gap-beliefs-policy/independent/claude-code/20261110T064126Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
