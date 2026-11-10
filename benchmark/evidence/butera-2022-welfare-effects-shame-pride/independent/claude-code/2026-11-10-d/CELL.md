# butera-2022-welfare-effects-shame-pride · independent · claude-code · 2026-11-10-d

| | |
|---|---|
| Paper | `butera-2022-welfare-effects-shame-pride` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-d |
| Date | 2026-11-10T14:35:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run4-1paper-butera-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z` |
| Run directory | `benchmark/reproductions/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-d` |
| Executions | 9 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 5) |
| Final | **13/13** |
| Package files withheld | 16 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `public_recognition_points_prolific_table5_col1` | 105.01 (12.25) | 104.038 | 0.93% | ±12.25 (se_band) | PASS | PASS |
| `financial_incentives_points_prolific_table5_col1` | 185.74 (12.56) | 186.442 | 0.38% | ±12.56 (se_band) | PASS | PASS |
| `public_recognition_points_berkeley_table5_col2` | 134.41 (22.56) | 134.742 | 0.25% | ±22.56 (se_band) | PASS | PASS |
| `financial_incentives_points_berkeley_table5_col2` | 177.76 (22.04) | 177.116 | 0.36% | ±22.04 (se_band) | PASS | PASS |
| `public_recognition_points_bu_table5_col3` | 103.61 (45.25) | 115.788 | 11.75% | ±45.25 (se_band) | PASS | PASS |
| `financial_incentives_points_bu_table5_col3` | 118.33 (39.62) | 132.257 | 11.77% | ±39.62 (se_band) | PASS | PASS |
| `n_obs_prolific_table5_col1` | 2904 | 2904 | 0.00% | ±145.2 (relative) | PASS | PASS |
| `n_obs_berkeley_table5_col2` | 1152 | 1152 | 0.00% | ±57.6 (relative) | PASS | PASS |
| `n_obs_bu_table5_col3` | 354 | 354 | 0.00% | ±17.7 (relative) | PASS | PASS |
| `action_signaling_gamma1_berkeley_table7_panelA` | 0.3 | 0.2999 | 0.03% | ±0.006 (relative) | PASS | PASS |
| `action_signaling_rho_berkeley_table7_panelA` | 0.87 | 0.871 | 0.11% | ±0.0174 (relative) | PASS | PASS |
| `cost_parameter_c_berkeley_table7_panelA` | 0.21 | 0.2139 | 1.86% | ±0.005 (printed_precision) | PASS | PASS |
| `predicted_financial_incentive_effect_berkeley_table7_panelC` | 2.33 | 2.3379 | 0.34% | ±0.0233 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) The paper does not define 'incoherent' preferences for the charity experiments beyond 'analogous to the YMCA analysis'. Final rule, applied to the yes/no recognition choices over the 18 intervals: coherent = weakly increasing (0...01...1, incl. constant) or single-peaked with an interior peak (0..01..10..0); everything else (multiple switches, or recognition wanted only at low scores, 1..10..0) is incoherent. This reproduces the paper's incoherent counts (40 among attention-passers in Prolific, 11 Berkeley, 2 BU), the ~1.0/1.8/1.7% non-monotone shares, and the Table 5 control means (807.9, 989.8, 815.9).
- (reproduction.json) Prolific: two participants with a round score above 3000 points (3493/3501 and 3202; every other score in all samples is at most 2521) are dropped as implausible. The paper does not mention this; it was inferred because it yields the paper's final N (968) and control mean (807.9) exactly.
- (reproduction.json) Attention check: a participant passes when attention_check is missing (data dictionary).
- (reproduction.json) Signed WTP = pref_rec_X_1 if preference_X == 1, else -pref_anom_X_1 (budget-capped answers; the hypothetical _10 columns are not used). Table 6 col (4): OLS of WTP on interval midpoint (hundreds of points) and its square, intervals 0-1699 only, clustered by participant.
- (reproduction.json) Table 7 Berkeley: gamma1 = sqrt(r1^2 - 4 r0 r2); rho = (gamma1 - r1)/(2 r2 abar) with abar = anonymous-round mean + Table 5 PR effect (hundreds of points); c = (r1 + 2 r2 (a0 + tau))/tau; predicted financial-incentive effect = 0.50/c ($0.50 per 100 points). The bootstrap in the script (200 participant-block reps) is informational only; the paper uses 1000.

Agent notes: Attempts 1-4 and 6-8 were exploratory (looking at the data and at candidate exclusion rules; no RESULT lines). Attempt 5 was the first full estimate. Its exclusion rule was based on WTP shape and left Prolific at N=966. I compared it with the claims using check_attempt; only the panel (c) prediction was off target (2.363 vs 2.33). I then revised the exclusion rule using paper-text statistics that are not claims (incoherent counts, non-monotone shares, Table 5 control means). The final run reproduces Ns of 2904/1152/354, the Table 5 control means exactly, and the Table 6 column (4) coefficients (0.379, -0.004, -3.325). The BU public-recognition coefficient is 115.8 vs 103.6 in the paper, even though the BU sample mean matches; the cause is unknown. Only the task mount, paper.txt and my scratch directory were used. Mount files read: the CSV data, README.pdf and the data dictionary xlsx (documentation only). No scripts were opened. No sandbox run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 20,646 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 907 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 278 bytes, from `benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-d/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 2,495 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 3,005 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,140 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 7,164 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 2,068 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 2,899 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-3/timing.json`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 1,787 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 5,872 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-4/timing.json`
- [`output/attempt-5/feedback.txt`](output/attempt-5/feedback.txt) — 110 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-5/feedback.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 6,793 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 1,479 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-5/stdout.txt`
- [`output/attempt-5/timing.json`](output/attempt-5/timing.json) — 264 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-5/timing.json`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 1,931 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 3,527 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-6/stdout.txt`
- [`output/attempt-6/timing.json`](output/attempt-6/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-6/timing.json`
- [`output/attempt-7/script.R`](output/attempt-7/script.R) — 1,728 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-7/script.R`
- [`output/attempt-7/stderr.txt`](output/attempt-7/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-7/stderr.txt`
- [`output/attempt-7/stdout.txt`](output/attempt-7/stdout.txt) — 2,632 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-7/stdout.txt`
- [`output/attempt-7/timing.json`](output/attempt-7/timing.json) — 266 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-7/timing.json`
- [`output/attempt-8/script.R`](output/attempt-8/script.R) — 764 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-8/script.R`
- [`output/attempt-8/stderr.txt`](output/attempt-8/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-8/stderr.txt`
- [`output/attempt-8/stdout.txt`](output/attempt-8/stdout.txt) — 3,985 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-8/stdout.txt`
- [`output/attempt-8/timing.json`](output/attempt-8/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/attempt-8/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 3,505 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,885 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,545 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143623Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
