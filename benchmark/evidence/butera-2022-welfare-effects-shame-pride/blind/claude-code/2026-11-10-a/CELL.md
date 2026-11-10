# butera-2022-welfare-effects-shame-pride · blind · claude-code · 2026-11-10-a

| | |
|---|---|
| Paper | `butera-2022-welfare-effects-shame-pride` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-a |
| Date | 2026-11-10T14:35:00Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-1paper-butera-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z` |
| Run directory | `benchmark/reproductions/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-a` |
| Executions | 7 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 11/13 (execution 7) |
| Final | **11/13** |
| Package files withheld | 16 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `public_recognition_points_prolific_table5_col1` | 105.01 (12.25) | 106.421 | 1.34% | ±12.25 (se_band) | PASS | PASS |
| `financial_incentives_points_prolific_table5_col1` | 185.74 (12.56) | 180.97 | 2.57% | ±12.56 (se_band) | PASS | PASS |
| `public_recognition_points_berkeley_table5_col2` | 134.41 (22.56) | 136.171 | 1.31% | ±22.56 (se_band) | PASS | PASS |
| `financial_incentives_points_berkeley_table5_col2` | 177.76 (22.04) | 183.217 | 3.07% | ±22.04 (se_band) | PASS | PASS |
| `public_recognition_points_bu_table5_col3` | 103.61 (45.25) | 115.118 | 11.11% | ±45.25 (se_band) | PASS | PASS |
| `financial_incentives_points_bu_table5_col3` | 118.33 (39.62) | 130.775 | 10.52% | ±39.62 (se_band) | PASS | PASS |
| `n_obs_prolific_table5_col1` | 2904 | 2916 | 0.41% | ±145.2 (relative) | PASS | PASS |
| `n_obs_berkeley_table5_col2` | 1152 | 1152 | 0.00% | ±57.6 (relative) | PASS | PASS |
| `n_obs_bu_table5_col3` | 354 | 354 | 0.00% | ±17.7 (relative) | PASS | PASS |
| `action_signaling_gamma1_berkeley_table7_panelA` | 0.3 | 0.302901 | 0.97% | ±0.006 (relative) | PASS | PASS |
| `action_signaling_rho_berkeley_table7_panelA` | 0.87 | 0.872559 | 0.29% | ±0.0174 (relative) | PASS | PASS |
| `cost_parameter_c_berkeley_table7_panelA` | 0.21 | 0.217198 | 3.43% | ±0.005 (printed_precision) | FAIL | FAIL |
| `predicted_financial_incentive_effect_berkeley_table7_panelC` | 2.33 | 2.30205 | 1.20% | ±0.0233 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/13 pass, which agrees with the row's 11/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Prolific final sample is 972 participants under the stated exclusions (attention check + incoherent preferences); the paper reports 968. The 4 extra exclusions could not be identified from the paper's description, so none were applied (n_obs Prolific = 2916).
- (reproduction.json) The 'incoherent' rule is not spelled out in the paper. Used: the signed WTP profile's strict preferences (non-zero WTP) must be weakly monotone increasing across the 18 intervals, i.e. a participant may never strictly prefer recognition at a lower interval and strictly prefer anonymity at a higher one; zero WTP is treated as indifference. This rule reproduces exactly the paper's stated incoherent counts (40 Prolific, 11 Berkeley, 2 BU), Berkeley N=384, BU N=118, QM221 N=52, and the stated 1.8% / 1.7% non-monotonic shares among the remaining Berkeley / BU participants.
- (reproduction.json) For rho, abar is the average performance with public recognition (anonymous-round mean + Table 5 col 2 PR effect, in hundreds of points), as the quantity definition says; Appendix eq. (22) writes this term as abar0_pop.
- (reproduction.json) Point estimates only; the bootstrapped confidence intervals in Table 7 were not computed.
- (DEVIATION: line) Prolific final sample has 972 participants under the stated exclusions (paper reports 968); no further unexplained exclusions applied.
- (DEVIATION: line) rho uses the average with-PR performance (anonymous mean + Table 5 col 2 PR effect) as abar, per the quantity definition.

Agent notes: Data: Packet/Raw Data/{prolific,berkeley,bu_qm222}_survey_data.csv. The BU sample is the QM222 class (121 completers, as in the paper); QM221 is not used. Attention check: attention_check non-missing = fail. Signed WTP per interval = pref_rec_X_1 if preference_X==1, otherwise -pref_anom_X_1. Table 5: long data with 3 rounds per participant (AnomPts, EarnPts, RecogPts), OLS of points on PR and financial-incentive round dummies plus round-position dummies taken from Condition (position 1 omitted), SEs clustered by participant (fixest). Table 6 col 4 (Berkeley): OLS of WTP on the interval midpoint in hundreds of points (0.5..16.5) and its square, with the 1700+ interval dropped (6528 obs, the same count as the paper). Structural (Appendix F.1): gamma1 = sqrt(r1^2 - 4 r0 r2), rho = (sqrt(r1^2 - 4 r0 r2) - r1)/(2 abar r2), c = (r1 + 2 r2 (a0 + tau))/tau, predicted FI effect = p/c with p = $0.50 per 100 points. Attempts 1-6 were exploratory (counts of exclusions under candidate incoherence rules, group sizes, data checks) and printed no RESULT lines. Besides paper.txt, I read the mount's documentation files: Packet/README.docx (text only, for the data provenance and the list of programs) and Packet/data dictionary.xlsx (variable definitions). I opened no scripts, logs, tables or PDFs from the package. While working, I saw the paper's non-withheld Table 6 Berkeley column (4) curvature and constant; my estimates differ from them slightly, and the specification was not adjusted toward them. No run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,213 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 876 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 278 bytes, from `benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 3,089 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 4,940 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 259 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,242 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 7,302 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 259 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-2/timing.json`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 1,155 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 8,237 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-3/stdout.txt`
- [`output/attempt-3/timing.json`](output/attempt-3/timing.json) — 259 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-3/timing.json`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 2,519 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 4,346 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-4/stdout.txt`
- [`output/attempt-4/timing.json`](output/attempt-4/timing.json) — 260 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-4/timing.json`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 1,876 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 4,059 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-5/stdout.txt`
- [`output/attempt-5/timing.json`](output/attempt-5/timing.json) — 259 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-5/timing.json`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 2,819 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 3,093 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-6/stdout.txt`
- [`output/attempt-6/timing.json`](output/attempt-6/timing.json) — 259 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/attempt-6/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 3,459 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,638 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,142 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 260 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/blind/claude-code/20261110T143622Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
