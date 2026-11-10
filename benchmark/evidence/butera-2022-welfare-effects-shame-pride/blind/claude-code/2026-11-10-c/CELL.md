# butera-2022-welfare-effects-shame-pride · blind · claude-code · 2026-11-10-c

| | |
|---|---|
| Paper | `butera-2022-welfare-effects-shame-pride` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-c |
| Date | 2026-11-10T14:30:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run3-1paper-butera-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143417Z` |
| Run directory | `benchmark/reproductions/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-c` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 3) |
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

- (reproduction.json) Prolific final sample is 970 participants (2910 participant-rounds), not the 968 stated in Section 6.1: applying the attention-check exclusion (7 failures) and the incoherent-preference exclusion (40, matching the paper's notes) leaves 970; no documented rule identifies the 2 further exclusions, so none were made.
- (reproduction.json) The 'incoherent' rule is not spelled out for the charity experiments; it was operationalised on the yes/no preference-for-recognition pattern across the 18 intervals: coherent = weakly increasing (incl. constant) or single-peaked; decreasing, U-shaped and multi-switch patterns excluded. This reproduces the stated exclusion counts (40/11/2) and the 1.0/1.8/1.7% non-monotone shares.
- (reproduction.json) Table 7 rho uses as reference average the anonymous-round mean plus the Table 5 col (2) public recognition effect (as described in the task), in hundreds of points; bootstrap CIs were not computed (point estimates only).

Agent notes: Exploratory attempts 1-2 inspected attention-check coding (non-missing = fail), round orders, and candidate coherence rules (no RESULT lines). Final: Table 5 = OLS of points on public-recognition and financial-incentive round dummies plus round-position dummies (first omitted), one obs per participant-round, SEs clustered by participant (fixest). BU = QM222 classroom file (121 completers); QM221 file not used. Signed WTP = pref_rec_X_1 if preference yes, minus pref_anom_X_1 if no (budget-constrained answers). Table 6 col (4) Berkeley: OLS of WTP on interval midpoint in hundreds of points and its square, 1700+ interval excluded (r0=-3.3246, r1=0.3790, r2=-0.00404). Structural (Appendix F.1): gamma1=sqrt(r1^2-4 r0 r2); rho=(sqrt(r1^2-4 r2 r0)-r1)/(2 abar r2); c=(r1+2 r2 (a0+tau))/tau; prediction=p/c with p=$0.50 per hundred points. While reading the paper text for methods, the extraction briefly displayed some BU rows of Table 7 (lines ~2780-2789); these were not used. Docker runs completed in under 2 s each; no hangs.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,213 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143417Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 876 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143417Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 278 bytes, from `benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,771 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143417Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143417Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 4,831 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143417Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 259 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143417Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,529 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143417Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143417Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,065 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143417Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 259 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143417Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,525 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143417Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,857 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143417Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143417Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,217 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143417Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 259 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143417Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
