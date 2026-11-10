# butera-2022-welfare-effects-shame-pride · independent · claude-code · 2026-11-10-c

| | |
|---|---|
| Paper | `butera-2022-welfare-effects-shame-pride` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-c |
| Date | 2026-11-10T14:31:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run3-1paper-butera-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z` |
| Run directory | `benchmark/reproductions/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-c` |
| Executions | 5 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 9/13 (execution 4) |
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
| `action_signaling_gamma1_berkeley_table7_panelA` | 0.3 | 0.2999 | 0.03% | ±0.006 (relative) | PASS | FAIL |
| `action_signaling_rho_berkeley_table7_panelA` | 0.87 | 0.871 | 0.11% | ±0.0174 (relative) | PASS | FAIL |
| `cost_parameter_c_berkeley_table7_panelA` | 0.21 | 0.2139 | 1.86% | ±0.005 (printed_precision) | PASS | FAIL |
| `predicted_financial_incentive_effect_berkeley_table7_panelC` | 2.33 | 2.3379 | 0.34% | ±0.0233 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Prolific sample: after the attention-check and incoherence exclusions 970 participants remain; 2 more (one with missing recog_group_assign, one with missing PracticePts) are dropped to match the paper's stated N=968 and its group-size breakdown (17 groups of 13-15, 6 of 71-79, 1 of 278). The paper does not describe this step.
- (reproduction.json) Incoherent preferences are defined on the binary yes/no public-recognition choices over all 18 intervals. Coherent means never switching, a single no->yes switch (monotone increasing), or no->yes->no (single-peaked); every other pattern, including yes->no (decreasing), is incoherent. This reproduces the paper's exclusion counts exactly (40 Prolific, 11 Berkeley, 2 BU) and its non-monotonic shares (1.0/1.8/1.7%).
- (reproduction.json) BU sample = bu_qm222_survey_data.csv (121 completers, matching the paper); QM221 (Appendix Table A16) is not used.
- (DEVIATION: line) Prolific sample additionally drops 2 participants with missing recog_group_assign or PracticePts (to reach the paper's N=968)

Agent notes: Attempts 1-3 were exploratory (attention check, preference patterns, sample sizes; no estimates). Attempt 4 printed NA for the structural parameters because of named-vector indexing (fixed with unname). Final run: Table 5 cols 1-3 by OLS of points on public-recognition and financial-incentive round indicators plus round-position dummies (2nd, 3rd), SEs clustered by participant (fixest). Table 6 col 4 (Berkeley): OLS of signed WTP (pref_rec if the participant wants PR, minus pref_anom otherwise; dollars) on the interval midpoint in hundreds of points and its square, 1700+ interval excluded (N=6528). Table 7 Berkeley structural parameters use the Appendix F mapping: gamma1=sqrt(r1^2-4 r0 r2), rho=(gamma1-r1)/(2 abar r2) with abar = anonymous mean + PR effect (hundreds), c=(r1+2 r2 (a0+tau))/tau, prediction p/c with p=$0.50 per 100 points. A 1000-rep participant-blocked percentile bootstrap is printed (not scored); its intervals are close to the paper's. Round-order F-test p-values differ from the paper's (e.g. Berkeley 0.018 vs 0.497), so the authors' order dummies may be coded differently. check_attempt on the final run reported all claims within tolerance; no claim-driven changes were made. No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 20,646 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 907 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 278 bytes, from `benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 2,205 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,303 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,563 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,855 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 2,001 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 2,938 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/attempt-3/timing.json`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 226 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 6,603 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 1,952 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/attempt-4/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,772 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,696 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,976 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 265 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/claude-code/20261110T143415Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
