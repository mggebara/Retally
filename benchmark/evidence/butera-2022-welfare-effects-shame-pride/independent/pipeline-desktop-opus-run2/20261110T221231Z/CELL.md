# butera-2022-welfare-effects-shame-pride · independent · pipeline-desktop-opus-run2 · 20261110T221231Z

| | |
|---|---|
| Paper | `butera-2022-welfare-effects-shame-pride` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261110T221231Z |
| Date | 2026-11-10T22:12:31Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-1paper-butera-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z` |
| Executions | 5 |
| Refinements | 4 (1 error + 3 claim) |
| First attempt | 0/13 |
| First scored | 8/13 (execution 2) |
| Final | **10/13** |
| Package files withheld | 16 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `public_recognition_points_prolific_table5_col1` | 105.01 (12.25) | 103.492 | 1.45% | ±12.25 (se_band) | PASS | PASS |
| `financial_incentives_points_prolific_table5_col1` | 185.74 (12.56) | 180.566 | 2.79% | ±12.56 (se_band) | PASS | PASS |
| `public_recognition_points_berkeley_table5_col2` | 134.41 (22.56) | 137.284 | 2.14% | ±22.56 (se_band) | PASS | PASS |
| `financial_incentives_points_berkeley_table5_col2` | 177.76 (22.04) | 183.746 | 3.37% | ±22.04 (se_band) | PASS | PASS |
| `public_recognition_points_bu_table5_col3` | 103.61 (45.25) | 117.354 | 13.27% | ±45.25 (se_band) | PASS | PASS |
| `financial_incentives_points_bu_table5_col3` | 118.33 (39.62) | 134.431 | 13.61% | ±39.62 (se_band) | PASS | PASS |
| `n_obs_prolific_table5_col1` | 2904 | 2961 | 1.96% | ±145.2 (relative) | PASS | PASS |
| `n_obs_berkeley_table5_col2` | 1152 | 1197 | 3.91% | ±57.6 (relative) | PASS | PASS |
| `n_obs_bu_table5_col3` | 354 | 360 | 1.69% | ±17.7 (relative) | PASS | FAIL |
| `action_signaling_gamma1_berkeley_table7_panelA` | 0.3 | 0.288438 | 3.85% | ±0.006 (relative) | FAIL | FAIL |
| `action_signaling_rho_berkeley_table7_panelA` | 0.87 | 0.864241 | 0.66% | ±0.0174 (relative) | PASS | FAIL |
| `cost_parameter_c_berkeley_table7_panelA` | 0.21 | 0.202409 | 3.61% | ±0.005 (printed_precision) | FAIL | FAIL |
| `predicted_financial_incentive_effect_berkeley_table7_panelC` | 2.33 | 2.47024 | 6.02% | ±0.0233 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 10/13 pass, which agrees with the row's 10/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) BU sample restricted to the single statistics class file bu_qm222 (paper describes one BU statistics class; combined classes far exceed the reported N)
- (DEVIATION: line) Incoherent participants defined as those whose binary recognition/anonymity choice switches more than twice across performance thresholds (exact rule not given in the provided text)
- (DEVIATION: line) Tobit censoring limits for Berkeley WTP set at the observed minimum and maximum of the elicited WTP (exact limits not given in the provided text)

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,659 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 20,245 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 29,215 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 32,107 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 32,619 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 160 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 12,116 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 160 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,358 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 475 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 12,447 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 10,853 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 543 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 14,414 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 6,581 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-3/stdout.txt`
- [`output/attempt-4/execution.json`](output/attempt-4/execution.json) — 72 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-4/execution.json`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 412 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 14,445 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 6,506 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/attempt-4/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/execution.json`
- [`output/script.R`](output/script.R) — 15,372 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,534 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T221231Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 12,117 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/82ae414bccfbcbad5c2c0171.json`
- [`output/answer-2.md`](output/answer-2.md) — 12,448 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/8f21dd40c7396d15c08f1858.json`
- [`output/answer-3.md`](output/answer-3.md) — 14,415 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/6d8bdc3244b0e40f249043ab.json`
- [`output/answer-4.md`](output/answer-4.md) — 14,446 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/12cd59d820c93ff8912718cc.json`
- [`output/answer-5.md`](output/answer-5.md) — 15,373 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/79d166b6a0b925131dec91d3.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 1 | — | — | 0 |
| attempt-2 | claim | 0 | — | — | 11 |
| attempt-3 | claim | 0 | — | — | 13 |
| attempt-4 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 2.4 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request 82ae414bccfbcbad5c2c0171: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-run2 (request 8f21dd40c7396d15c08f1858: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-run2 (request 6d8bdc3244b0e40f249043ab: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-run2 (request 12cd59d820c93ff8912718cc: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus-run2 (request 79d166b6a0b925131dec91d3: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 5 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
