# butera-2022-welfare-effects-shame-pride · independent · pipeline-desktop-opus · 20261110T171753Z

| | |
|---|---|
| Paper | `butera-2022-welfare-effects-shame-pride` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus |
| Run | 20261110T171753Z |
| Date | 2026-11-10T17:17:53Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-1paper-butera-all-modes-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z` |
| Executions | 5 |
| Refinements | 4 (1 error + 3 claim) |
| First attempt | 0/13 |
| First scored | 6/13 (execution 2) |
| Final | **8/13** |
| Package files withheld | 16 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `public_recognition_points_prolific_table5_col1` | 105.01 (12.25) | 103.142 | 1.78% | ±12.25 (se_band) | PASS | PASS |
| `financial_incentives_points_prolific_table5_col1` | 185.74 (12.56) | 168.962 | 9.03% | ±12.56 (se_band) | FAIL | PASS |
| `public_recognition_points_berkeley_table5_col2` | 134.41 (22.56) | 154.054 | 14.61% | ±22.56 (se_band) | PASS | PASS |
| `financial_incentives_points_berkeley_table5_col2` | 177.76 (22.04) | 183.062 | 2.98% | ±22.04 (se_band) | PASS | PASS |
| `public_recognition_points_bu_table5_col3` | 103.61 (45.25) | 121.636 | 17.40% | ±45.25 (se_band) | PASS | PASS |
| `financial_incentives_points_bu_table5_col3` | 118.33 (39.62) | 133.304 | 12.65% | ±39.62 (se_band) | PASS | PASS |
| `n_obs_prolific_table5_col1` | 2904 | 2874 | 1.03% | ±145.2 (relative) | PASS | FAIL |
| `n_obs_berkeley_table5_col2` | 1152 | 1176 | 2.08% | ±57.6 (relative) | PASS | FAIL |
| `n_obs_bu_table5_col3` | 354 | 363 | 2.54% | ±17.7 (relative) | PASS | FAIL |
| `action_signaling_gamma1_berkeley_table7_panelA` | 0.3 | 0.403393 | 34.46% | ±0.006 (relative) | FAIL | FAIL |
| `action_signaling_rho_berkeley_table7_panelA` | 0.87 | 0.819266 | 5.83% | ±0.0174 (relative) | FAIL | FAIL |
| `cost_parameter_c_berkeley_table7_panelA` | 0.21 | 0.247926 | 18.06% | ±0.005 (printed_precision) | FAIL | FAIL |
| `predicted_financial_incentive_effect_berkeley_table7_panelC` | 2.33 | 2.01673 | 13.45% | ±0.0233 (relative) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/13 pass, which agrees with the row's 8/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Prolific sample restricted by data-derived screen 'all points > 0' (paper's exact exclusion rule not available in provided text)
- (DEVIATION: line) Berkeley sample restricted by data-derived screen 'all points > 0' (paper's exact exclusion rule not available in provided text)
- (DEVIATION: line) BU sample restricted by data-derived screen 'Sample==BU' (paper's exact exclusion rule not available in provided text)
- (DEVIATION: line) Berkeley structural WTP profile restricted to intervals whose midpoint is within one SD of the change in performance (4.174 hundred points) of the participant's public-recognition score, the online analogue of the paper's within-4-visits restriction
- (DEVIATION: line) Berkeley WTP profile estimated by Tobit with censoring bounds set to observed min/max WTP (-25, 25) since exact bounds are not stated in provided text

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,659 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 21,335 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 24,425 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 28,161 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 30,224 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/execution.json`](output/attempt-1/execution.json) — 71 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-1/execution.json`
- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 77 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 13,288 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 77 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 34,238 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-1/stdout.txt`
- [`output/attempt-2/execution.json`](output/attempt-2/execution.json) — 72 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-2/execution.json`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 641 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 8,651 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 4,487 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-2/stdout.txt`
- [`output/attempt-3/execution.json`](output/attempt-3/execution.json) — 72 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-3/execution.json`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 432 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 10,981 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 5,646 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-3/stdout.txt`
- [`output/attempt-4/execution.json`](output/attempt-4/execution.json) — 72 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-4/execution.json`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 433 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 11,944 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 6,780 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/attempt-4/stdout.txt`
- [`output/execution.json`](output/execution.json) — 114 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/execution.json`
- [`output/script.R`](output/script.R) — 12,791 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,122 bytes, from `benchmark/results/artifacts/butera-2022-welfare-effects-shame-pride/independent/pipeline/20261110T171753Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 13,289 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/82ae414bccfbcbad5c2c0171.json`
- [`output/answer-2.md`](output/answer-2.md) — 8,652 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/9b27105a427248f8689e265f.json`
- [`output/answer-3.md`](output/answer-3.md) — 10,982 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/e365e50797f4bc3f074a7d81.json`
- [`output/answer-4.md`](output/answer-4.md) — 11,945 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/2a2c750938e3f480048808cc.json`
- [`output/answer-5.md`](output/answer-5.md) — 12,792 bytes, from `benchmark/.cache/llm-oracle/desktop-opus/answers/4c56c9954b20167420eb9529.json`

## Executions

| Execution | Kind | Exit code | Timed out | Elapsed (s) | Outputs parsed |
|---|---|---|---|---|---|
| attempt-1 | error | 0 | — | — | 0 |
| attempt-2 | claim | 0 | — | — | 13 |
| attempt-3 | claim | 0 | — | — | 13 |
| attempt-4 | claim | 0 | — | — | 13 |
| final | final | 0 | no | 2.1 | 13 |

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus (request 82ae414bccfbcbad5c2c0171: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus (request 9b27105a427248f8689e265f: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus (request e365e50797f4bc3f074a7d81: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus (request 2a2c750938e3f480048808cc: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus (request 4c56c9954b20167420eb9529: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 5 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
