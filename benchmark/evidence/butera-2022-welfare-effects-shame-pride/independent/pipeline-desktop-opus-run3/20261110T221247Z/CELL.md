# butera-2022-welfare-effects-shame-pride · independent · pipeline-desktop-opus-run3 · 20261110T221247Z

| | |
|---|---|
| Paper | `butera-2022-welfare-effects-shame-pride` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run3 |
| Run | 20261110T221247Z |
| Date | 2026-11-10T22:12:47Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run3-1paper-butera-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z` |
| Executions | 5 |
| Refinements | 4 (1 error + 3 claim) |
| First attempt | 0/13 |
| First scored | 5/13 (execution 2) |
| Final | **9/13** |
| Package files withheld | 16 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `public_recognition_points_prolific_table5_col1` | 105.01 (12.25) | 102.932 | 1.98% | ±12.25 (se_band) | PASS | FAIL |
| `financial_incentives_points_prolific_table5_col1` | 185.74 (12.56) | 180.067 | 3.05% | ±12.56 (se_band) | PASS | PASS |
| `public_recognition_points_berkeley_table5_col2` | 134.41 (22.56) | 135.004 | 0.44% | ±22.56 (se_band) | PASS | PASS |
| `financial_incentives_points_berkeley_table5_col2` | 177.76 (22.04) | 181.556 | 2.14% | ±22.04 (se_band) | PASS | PASS |
| `public_recognition_points_bu_table5_col3` | 103.61 (45.25) | 115.118 | 11.11% | ±45.25 (se_band) | PASS | PASS |
| `financial_incentives_points_bu_table5_col3` | 118.33 (39.62) | 130.775 | 10.52% | ±39.62 (se_band) | PASS | PASS |
| `n_obs_prolific_table5_col1` | 2904 | 2967 | 2.17% | ±145.2 (relative) | PASS | FAIL |
| `n_obs_berkeley_table5_col2` | 1152 | 1176 | 2.08% | ±57.6 (relative) | PASS | FAIL |
| `n_obs_bu_table5_col3` | 354 | 354 | 0.00% | ±17.7 (relative) | PASS | FAIL |
| `action_signaling_gamma1_berkeley_table7_panelA` | 0.3 | 0.403934 | 34.64% | ±0.006 (relative) | FAIL | FAIL |
| `action_signaling_rho_berkeley_table7_panelA` | 0.87 | 0.851972 | 2.07% | ±0.0174 (relative) | FAIL | FAIL |
| `cost_parameter_c_berkeley_table7_panelA` | 0.21 | 0.28925 | 37.74% | ±0.005 (printed_precision) | FAIL | FAIL |
| `predicted_financial_incentive_effect_berkeley_table7_panelC` | 2.33 | 1.72861 | 25.81% | ±0.0233 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/13 pass, which agrees with the row's 9/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) WTP rebuilt by combining pref_rec (positive) and pref_anom (negative) slider amounts across both slider scales; only participants with no WTP responses or >2 sign switches are treated as incoherent
- (DEVIATION: line) Berkeley structural PRU (Table 7) uses a Tobit fit of WTP on midpoint and midpoint^2 (censored at the slider bounds) instead of OLS, following the paper's use of Tobit censoring assumptions in the structural analysis
- (DEVIATION: line) Berkeley structural Tobit restricted to WTP points whose interval midpoint lies within one SD of the (public - anonymous) change in points of the participant's own public-recognition performance, the online analogue of the paper's within-4-visits restriction used in the structural analysis
- (DEVIATION: line) BU sample is the QM222 statistics class file (one BU statistics class); participants with WTP profiles switching sign more than once are treated as incoherent in this sample

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,659 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 20,198 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 30,650 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 30,437 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 32,168 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 32 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 12,197 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,823 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 749 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 13,420 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 10,911 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 387 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 13,340 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 5,715 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-3/stdout.txt`
- [`output/attempt-4/execution.json`](output/attempt-4/execution.json) — 72 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-4/execution.json`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 280 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 14,269 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 7,508 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/attempt-4/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/execution.json`
- [`output/script.R`](output/script.R) — 15,415 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,916 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221247Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 12,198 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/82ae414bccfbcbad5c2c0171.json`
- [`output/answer-2.md`](output/answer-2.md) — 13,421 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/37042fcc2f56d711c1708243.json`
- [`output/answer-3.md`](output/answer-3.md) — 13,341 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/aa58094a01c1278bb640c892.json`
- [`output/answer-4.md`](output/answer-4.md) — 14,270 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/b67d2eeb0bf1f095d6085e4e.json`
- [`output/answer-5.md`](output/answer-5.md) — 15,416 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run3/answers/81d1dc86012c7bccfc5e0220.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 0 | — | — | 0 |
| attempt-2 | claim | 0 | — | — | 11 |
| attempt-3 | claim | 0 | — | — | 13 |
| attempt-4 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 2.5 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run3 (request 82ae414bccfbcbad5c2c0171: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run3 (request 37042fcc2f56d711c1708243: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run3 (request aa58094a01c1278bb640c892: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run3 (request b67d2eeb0bf1f095d6085e4e: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus-run3 (request 81d1dc86012c7bccfc5e0220: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 5 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
