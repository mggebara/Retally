# butera-2022-welfare-effects-shame-pride · independent · claude-code · 2026-11-10-b

| | |
|---|---|
| Paper | `butera-2022-welfare-effects-shame-pride` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-b |
| Date | 2026-11-10T14:35:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run2-1paper-butera-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z` |
| Run directory | `benchmark/reproductions/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-b` |
| Executions | 8 |
| Refinements | 1 (0 error + 1 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 5) |
| Final | **12/13** |
| Package files withheld | 16 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `public_recognition_points_prolific_table5_col1` | 105.01 (12.25) | 105.376 | 0.35% | ±12.25 (se_band) | PASS | PASS |
| `financial_incentives_points_prolific_table5_col1` | 185.74 (12.56) | 181.9 | 2.07% | ±12.56 (se_band) | PASS | PASS |
| `public_recognition_points_berkeley_table5_col2` | 134.41 (22.56) | 138.428 | 2.99% | ±22.56 (se_band) | PASS | PASS |
| `financial_incentives_points_berkeley_table5_col2` | 177.76 (22.04) | 180.388 | 1.48% | ±22.04 (se_band) | PASS | PASS |
| `public_recognition_points_bu_table5_col3` | 103.61 (45.25) | 115.118 | 11.11% | ±45.25 (se_band) | PASS | PASS |
| `financial_incentives_points_bu_table5_col3` | 118.33 (39.62) | 130.775 | 10.52% | ±39.62 (se_band) | PASS | PASS |
| `n_obs_prolific_table5_col1` | 2904 | 2898 | 0.21% | ±145.2 (relative) | PASS | PASS |
| `n_obs_berkeley_table5_col2` | 1152 | 1152 | 0.00% | ±57.6 (relative) | PASS | PASS |
| `n_obs_bu_table5_col3` | 354 | 354 | 0.00% | ±17.7 (relative) | PASS | PASS |
| `action_signaling_gamma1_berkeley_table7_panelA` | 0.3 | 0.3047 | 1.57% | ±0.006 (relative) | PASS | PASS |
| `action_signaling_rho_berkeley_table7_panelA` | 0.87 | 0.8586 | 1.31% | ±0.0174 (relative) | PASS | PASS |
| `cost_parameter_c_berkeley_table7_panelA` | 0.21 | 0.2116 | 0.76% | ±0.005 (printed_precision) | PASS | PASS |
| `predicted_financial_incentive_effect_berkeley_table7_panelC` | 2.33 | 2.3631 | 1.42% | ±0.0233 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) The paper does not spell out the charitable-experiment 'incoherent preference' rule beyond 'analogous to the YMCA analysis' (coherent = monotonically increasing, monotonically decreasing, or single-peaked). Implemented: coherent if the binary preference for recognition is weakly increasing across the 18 intervals, or if the signed WTP profile (WTP for recognition if preferred, minus WTP to avoid it otherwise; budget-limited '_1' answers) is non-constant and weakly decreasing or weakly single-peaked. This yields exactly the paper's exclusion counts for Berkeley (11) and BU (2) but 44 instead of 40 for Prolific (final N 966 vs 968, 2898 vs 2904 observations), and the selected Berkeley/BU individuals evidently differ in part from the authors' (anonymous-round means 985.8 vs 989.8 Berkeley, 830.9 vs 815.9 BU).
- (reproduction.json) BU sample = bu_qm222_survey_data.csv (121 completers, matching the paper's BU count); QM221 file not used.
- (reproduction.json) Rho uses the average performance under public recognition (anonymous mean + Table 5 col 2 effect) as the reference average, per the claim description; c = (r1 + 2 r2 (a0 + tau)) / tau (Appendix eq. 27); prediction = $0.50 per 100 points / c. Bootstrap CIs not computed (not claimed).

Agent notes: Attempts 1-4 were exploratory (data dictionary, attention-check / coherence-rule counts, inspection of non-monotone preference profiles); none printed RESULT lines. Attempt 5 was the first and only estimating script; after comparing it with the claims (check_attempt: only the Berkeley predicted financial-incentive effect off, 2.363 vs 2.33), attempts 6-7 explored by brute force which Berkeley/BU exclusions would reproduce the paper's Table 5 numbers; no exclusion set within the attention-passing samples matched exactly (for BU no pair of exclusions reproduces both the control mean and coefficients), so the script was not changed and the final run is a copy of attempt 5's files. Table 5: OLS of points on public-recognition and financial-incentive round dummies plus round-position dummies, participant-clustered SEs (fixest). Table 6 col 4 (Berkeley): OLS of signed WTP on interval midpoint (hundreds of points) and its square, 1700+ interval excluded, 6528 obs. Structural action-signaling mapping from Appendix F.1.3-F.1.4. No hangs.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 20,646 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 907 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 278 bytes, from `benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,616 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 360 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 133,710 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,414 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,480 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 1,532 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 2,173 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-3/timing.json`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 1,280 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 8,919 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-4/timing.json`
- [`output/attempt-5/feedback.txt`](output/attempt-5/feedback.txt) — 110 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-5/feedback.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 5,663 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 2,733 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-5/stdout.txt`
- [`output/attempt-5/timing.json`](output/attempt-5/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-5/timing.json`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 1,880 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 2,061 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-6/stdout.txt`
- [`output/attempt-6/timing.json`](output/attempt-6/timing.json) — 266 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-6/timing.json`
- [`output/attempt-7/script.R`](output/attempt-7/script.R) — 1,557 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-7/script.R`
- [`output/attempt-7/stderr.txt`](output/attempt-7/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-7/stderr.txt`
- [`output/attempt-7/stdout.txt`](output/attempt-7/stdout.txt) — 1,825 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-7/stdout.txt`
- [`output/attempt-7/timing.json`](output/attempt-7/timing.json) — 266 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/attempt-7/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 3,106 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,663 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,733 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143557Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
