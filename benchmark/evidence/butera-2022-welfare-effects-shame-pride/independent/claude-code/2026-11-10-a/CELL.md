# butera-2022-welfare-effects-shame-pride · independent · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `butera-2022-welfare-effects-shame-pride` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T14:31:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-butera-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z` |
| Run directory | `benchmark/reproductions/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-a` |
| Executions | 7 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 7) |
| Final | **13/13** |
| Package files withheld | 16 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `public_recognition_points_prolific_table5_col1` | 105.01 (12.25) | 109.264 | 4.05% | ±12.25 (se_band) | PASS | PASS |
| `financial_incentives_points_prolific_table5_col1` | 185.74 (12.56) | 182.959 | 1.50% | ±12.56 (se_band) | PASS | PASS |
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
| `predicted_financial_incentive_effect_berkeley_table7_panelC` | 2.33 | 2.3379 | 0.34% | ±0.0233 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) The 'incoherent preferences' exclusion is not defined operationally in the paper text. I defined coherent as a 0/1 preference-for-recognition pattern over the 18 intervals that is weakly increasing (incl. constant) or single-peaked (0..1..0); decreasing, dipped, or multi-reversal patterns are incoherent. This reproduces the paper's incoherent counts exactly (40 Prolific, 11 Berkeley, 2 BU among attention-check passers) and the 1.0/1.8/1.7% non-monotonic shares among the coherent.
- (reproduction.json) Prolific: after attention-check and incoherence exclusions 970 participants remain vs 968 in the paper; I additionally dropped the 2 participants with a missing public-recognition group assignment or missing practice-round record (both scored 0-1 points in the public round). This rule is my guess, not stated in the paper. Prolific anonymous-round mean is 809.7 vs paper 807.9 and Table 6 Prolific estimates are close but not identical, so the Prolific sample likely differs slightly from the authors'.
- (reproduction.json) BU sample taken to be the BU QM222 file (121 completes, matching the paper); QM221 is not used.
- (reproduction.json) Round-order dummies: position (1st/2nd/3rd) of each round taken from the Condition string (e.g. 'RAE'); dummies for 2nd and 3rd with 1st omitted.
- (reproduction.json) Table 7 bootstrapped confidence intervals not computed (only point estimates are claimed).

Agent notes: Data: Raw Data/{prolific,berkeley,bu_qm222}_survey_data.csv. Exclusions: failed attention check (non-missing attention_check) and incoherent preferences (see deviations); final N 968/384/118. Table 5: OLS (fixest) of points on public-recognition and paid-round indicators plus round-position dummies, SE clustered by participant; N 2904/1152/354 match. Table 6 col 4 (Berkeley) reproduced exactly: r0=-3.3246, r1=0.3790, r2=-0.00404 (WTP = +pref_rec_X_1 if preference 1, -pref_anom_X_1 if 0; interval midpoints in hundreds of points; >=1700 interval excluded). Berkeley and BU control means (989.8, 815.9) match the paper exactly, yet Table 5 coefficients differ somewhat (Berkeley PR 134.74 vs 134.41; BU PR 115.79 vs 103.61, FI 132.26 vs 118.33), suggesting the authors' order-dummy coding differs from my position coding. Structural Berkeley action-signaling parameters from Appendix F.1: gamma1 = sqrt(r1^2-4 r0 r2), rho = (sqrt(r1^2-4 r2 r0)-r1)/(2 abar r2) with abar = anonymous mean + PR effect, c = (r1+2 r2(a0+tau))/tau, predicted FI effect = 0.5/c (5 cents/10 points = $0.50 per hundred points). Six exploratory runs (attempts 1-6, no RESULT lines) were used to work out the exclusion rule. After the first scored run I ran check_attempt once (reported all claims within tolerance) and did not change the script, so that run is the final run and is not recorded as a claim attempt. Also read (inside the mount, not scripts): Packet/README.pdf and the data dictionary.xlsx strings. No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 20,646 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 907 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 278 bytes, from `benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 2,270 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 3,244 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,635 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,435 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 1,302 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 7,434 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-3/timing.json`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 1,988 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 52 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 1,871 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-4/timing.json`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 2,011 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 2,525 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-5/stdout.txt`
- [`output/attempt-5/timing.json`](output/attempt-5/timing.json) — 264 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-5/timing.json`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 1,325 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 1,032 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-6/stdout.txt`
- [`output/attempt-6/timing.json`](output/attempt-6/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/attempt-6/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 3,633 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/reproduction.json`
- [`output/script.R`](output/script.R) — 5,708 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,187 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143414Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
