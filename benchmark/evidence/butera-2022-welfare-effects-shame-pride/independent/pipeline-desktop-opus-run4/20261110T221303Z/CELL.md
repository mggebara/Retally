# butera-2022-welfare-effects-shame-pride · independent · pipeline-desktop-opus-run4 · 20261110T221303Z

| | |
|---|---|
| Paper | `butera-2022-welfare-effects-shame-pride` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run4 |
| Run | 20261110T221303Z |
| Date | 2026-11-10T22:13:03Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run4-1paper-butera-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z` |
| Executions | 5 |
| Refinements | 4 (1 error + 3 claim) |
| First attempt | 0/13 |
| First scored | 7/13 (execution 2) |
| Final | **9/13** |
| Package files withheld | 16 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `public_recognition_points_prolific_table5_col1` | 105.01 (12.25) | 102.17 | 2.70% | ±12.25 (se_band) | PASS | PASS |
| `financial_incentives_points_prolific_table5_col1` | 185.74 (12.56) | 178.678 | 3.80% | ±12.56 (se_band) | PASS | PASS |
| `public_recognition_points_berkeley_table5_col2` | 134.41 (22.56) | 137.461 | 2.27% | ±22.56 (se_band) | PASS | PASS |
| `financial_incentives_points_berkeley_table5_col2` | 177.76 (22.04) | 184.42 | 3.75% | ±22.04 (se_band) | PASS | PASS |
| `public_recognition_points_bu_table5_col3` | 103.61 (45.25) | 120.422 | 16.23% | ±45.25 (se_band) | PASS | PASS |
| `financial_incentives_points_bu_table5_col3` | 118.33 (39.62) | 131.111 | 10.80% | ±39.62 (se_band) | PASS | PASS |
| `n_obs_prolific_table5_col1` | 2904 | 3030 | 4.34% | ±145.2 (relative) | PASS | FAIL |
| `n_obs_berkeley_table5_col2` | 1152 | 1185 | 2.86% | ±57.6 (relative) | PASS | FAIL |
| `n_obs_bu_table5_col3` | 354 | 360 | 1.69% | ±17.7 (relative) | PASS | FAIL |
| `action_signaling_gamma1_berkeley_table7_panelA` | 0.3 | 0.401493 | 33.83% | ±0.006 (relative) | FAIL | FAIL |
| `action_signaling_rho_berkeley_table7_panelA` | 0.87 | 0.850862 | 2.20% | ±0.0174 (relative) | FAIL | PASS |
| `cost_parameter_c_berkeley_table7_panelA` | 0.21 | 0.279031 | 32.87% | ±0.005 (printed_precision) | FAIL | FAIL |
| `predicted_financial_incentive_effect_berkeley_table7_panelC` | 2.33 | 1.79192 | 23.09% | ±0.0233 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 9/13 pass, which agrees with the row's 9/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) BU sample uses only the QM222 class file (the paper describes a single BU statistics class); QM221 file not pooled
- (DEVIATION: line) Online samples restricted to attention-check passers with a complete WTP profile; the ad-hoc sign-change incoherence filter (not specified for the online experiments) is no longer applied
- (DEVIATION: line) Structural PRU for Berkeley estimated on WTP points within one SD of the individual public-minus-anonymous change of the participant's own public-round points (online analogue of the paper's within-4-visits restriction used in the structural analysis)
- (DEVIATION: line) Structural PRU for Berkeley estimated by two-limit Tobit (censoring at the WTP bounds observed in the data), per the paper's use of Tobit parametric assumptions for censoring

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,659 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 18,607 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 24,375 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 26,095 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 28,784 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 32 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 10,606 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 9,561 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 545 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 9,206 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 4,087 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 387 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 10,098 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 4,504 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-3/stdout.txt`
- [`output/attempt-4/execution.json`](output/attempt-4/execution.json) — 72 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-4/execution.json`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 316 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 11,794 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 4,942 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/attempt-4/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/execution.json`
- [`output/script.R`](output/script.R) — 12,935 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 5,315 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221303Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 10,607 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/82ae414bccfbcbad5c2c0171.json`
- [`output/answer-2.md`](output/answer-2.md) — 9,207 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/3218bf2cd40020c948824e6b.json`
- [`output/answer-3.md`](output/answer-3.md) — 10,099 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/0dca1096966c172774664ce5.json`
- [`output/answer-4.md`](output/answer-4.md) — 11,795 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/35c556e5c5ff204ff14cc406.json`
- [`output/answer-5.md`](output/answer-5.md) — 12,936 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run4/answers/b805f47d26474722d611c96e.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 0 | — | — | 0 |
| attempt-2 | claim | 0 | — | — | 13 |
| attempt-3 | claim | 0 | — | — | 13 |
| attempt-4 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 2.1 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run4 (request 82ae414bccfbcbad5c2c0171: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run4 (request 3218bf2cd40020c948824e6b: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run4 (request 0dca1096966c172774664ce5: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run4 (request 35c556e5c5ff204ff14cc406: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus-run4 (request b805f47d26474722d611c96e: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 5 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
