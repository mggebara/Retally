# butera-2022-welfare-effects-shame-pride · blind · claude-code · 2026-11-10-d

| | |
|---|---|
| Paper | `butera-2022-welfare-effects-shame-pride` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-d |
| Date | 2026-11-10T14:30:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run4-1paper-butera-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z` |
| Run directory | `benchmark/reproductions/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-d` |
| Executions | 4 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 4) |
| Final | **13/13** |
| Package files withheld | 16 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `public_recognition_points_prolific_table5_col1` | 105.01 (12.25) | 106.144 | 1.08% | ±12.25 (se_band) | PASS | PASS |
| `financial_incentives_points_prolific_table5_col1` | 185.74 (12.56) | 182.487 | 1.75% | ±12.56 (se_band) | PASS | PASS |
| `public_recognition_points_berkeley_table5_col2` | 134.41 (22.56) | 134.742 | 0.25% | ±22.56 (se_band) | PASS | PASS |
| `financial_incentives_points_berkeley_table5_col2` | 177.76 (22.04) | 177.116 | 0.36% | ±22.04 (se_band) | PASS | PASS |
| `public_recognition_points_bu_table5_col3` | 103.61 (45.25) | 115.788 | 11.75% | ±45.25 (se_band) | PASS | PASS |
| `financial_incentives_points_bu_table5_col3` | 118.33 (39.62) | 132.257 | 11.77% | ±39.62 (se_band) | PASS | PASS |
| `n_obs_prolific_table5_col1` | 2904 | 2910 | 0.21% | ±145.2 (relative) | PASS | PASS |
| `n_obs_berkeley_table5_col2` | 1152 | 1152 | 0.00% | ±57.6 (relative) | PASS | PASS |
| `n_obs_bu_table5_col3` | 354 | 354 | 0.00% | ±17.7 (relative) | PASS | PASS |
| `action_signaling_gamma1_berkeley_table7_panelA` | 0.3 | 0.299882 | 0.04% | ±0.006 (relative) | PASS | PASS |
| `action_signaling_rho_berkeley_table7_panelA` | 0.87 | 0.871013 | 0.12% | ±0.0174 (relative) | PASS | PASS |
| `cost_parameter_c_berkeley_table7_panelA` | 0.21 | 0.213866 | 1.84% | ±0.005 (printed_precision) | PASS | PASS |
| `predicted_financial_incentive_effect_berkeley_table7_panelC` | 2.33 | 2.33791 | 0.34% | ±0.0233 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) The paper does not define 'incoherent' preferences operationally. The final script defines it on the yes/no preference-for-recognition profile over the 18 intervals: coherent = constant, a single 0->1 switch (weakly increasing), or single-peaked (0..1..0); anything else (decreasing, U-shaped, multiple switches) is incoherent. With the attention-check exclusion (item left blank = pass) this gives 40/11/2 incoherent exclusions, matching the counts in the table notes, and 384 Berkeley participants, matching the text; Prolific gives 970 participants, 2 more than the 968 the text reports. No further exclusion rule is described in the paper, so none was added.
- (reproduction.json) The BU experiment is taken to be the QM222 file only (121 completers, matching the paper's count); bu_qm221_survey_data.csv was not used.
- (reproduction.json) WTP is the budgeted response (pref_rec_*_1 if the participant wanted recognition in that interval, minus pref_anom_*_1 otherwise); the hypothetical uncensored follow-ups (*_10) were not used.
- (reproduction.json) For rho, the comparison-population average is the anonymous-round mean plus the Table 5 col (2) public-recognition effect (in hundreds of points), as the quantity definition specifies. c = (r1 + 2 r2 (a0 + tau)) / tau (Appendix eq. 27); gamma1 = sqrt(r1^2 - 4 r0 r2); predicted financial effect = 0.50 / c (5 cents per 10 points = $0.50 per hundred points).

Agent notes: Table 5: OLS of points on public-recognition and financial-incentive round indicators plus round-order dummies (position 1 omitted), one row per participant-round, SEs clustered by participant (fixest). Table 6 col (4): OLS of WTP ($) on interval midpoint in hundreds of points and its square, excluding the >=1700 interval, Berkeley final sample, clustered by participant. Table 7 Berkeley action-signaling parameters come from the Appendix F.1 mapping equations; a 1000-replication participant-block percentile bootstrap is printed in stdout only as a diagnostic. Attempts 1-3 were exploratory runs (data inspection and sample-definition checks); they printed no RESULT lines. No run hung; each finished in under 10 seconds.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,213 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 876 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 278 bytes, from `benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-d/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 2,415 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,342 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 259 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,998 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 6,339 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 259 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 1,867 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 7,711 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 259 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/attempt-3/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,710 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,780 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,296 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 259 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143418Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
