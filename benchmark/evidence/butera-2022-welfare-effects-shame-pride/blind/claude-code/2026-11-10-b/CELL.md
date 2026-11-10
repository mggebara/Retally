# butera-2022-welfare-effects-shame-pride · blind · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `butera-2022-welfare-effects-shame-pride` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T14:31:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-butera-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z` |
| Run directory | `benchmark/reproductions/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-b` |
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

- (reproduction.json) Prolific final sample is 970 participants (2910 participant-rounds) under my exclusion rules (7 attention-check failures, 40 incoherent among passers); the paper's text states a final Prolific sample of 968. I could not identify a documented rule that drops 2 more participants, so I did not drop any.
- (reproduction.json) Bootstrap CIs for Table 7 are computed (1000 participant-level resamples, seed 42) and printed for information only; scored quantities are full-sample point estimates.

Agent notes: Attempts 1-3 were exploratory (no RESULT lines): sample sizes, attention-check coding, WTP construction, and alternative definitions of 'incoherent' preferences. Final definitions: attention_check non-missing = fail. 'Incoherent' = binary opt-in preference (preference_0..preference_1700, 18 intervals) is neither weakly increasing in points (0..0 1..1, incl. all-0/all-1) nor single-peaked with an interior peak (0..1..0); this reproduces the exclusion counts stated in the table notes (40 Prolific, 11 Berkeley, 2 BU, and the QM221 N=52) and the share of non-monotonic coherent participants (peaks 10/7/2). BU = QM222 file. Table 5: OLS (fixest) of points on public-round and paid-round indicators (anonymous round omitted) plus dummies for round position 2 and 3 (from the Condition order string), participant-clustered SEs, 3 obs per participant. Table 6 col 4 (Berkeley): OLS of signed WTP (pref_rec_X_1 if opted in, minus pref_anom_X_1 if opted out; the _10 hypothetical follow-ups unused) on interval midpoint in hundreds and its square, >=1700 interval excluded. Table 7 (Berkeley, action-signaling): gamma1 = sqrt(r1^2 - 4 r0 r2); rho = (gamma1 - r1)/(2 abar r2) with abar = anonymous-round mean (hundreds) + Table 5 col 2 public recognition effect (as the task defines it; diagnostic with abar = anonymous mean only gives 0.990, printed but not scored); c = (r1 + 2 r2 (a0 + tau))/tau (Appendix F eq. 27); predicted financial incentive effect = 0.5/c (5 cents per 10 points = $0.50 per hundred points), in hundreds of points. While reading table notes I incidentally saw a few numbers printed at the end of Table 7 in paper.txt; they were not used. No hang occurred; all runs finished in seconds.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,213 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 876 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 278 bytes, from `benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 3,921 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 5,857 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 259 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,098 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 350 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 4,798 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 259 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 2,072 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 4,967 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 259 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/attempt-3/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,795 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/reproduction.json`
- [`output/script.R`](output/script.R) — 7,430 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,275 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 259 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143416Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
