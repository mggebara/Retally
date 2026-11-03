# douenne-2022-yellow-vests-carbon-tax · independent · pipeline-desktop-opus-postfix · 20261103T104817Z

| | |
|---|---|
| Paper | `douenne-2022-yellow-vests-carbon-tax` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T104817Z |
| Date | 2026-11-03T10:48:17Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z` |
| Executions | 7 |
| Refinements | 6 (3 error + 3 claim) |
| First attempt | 0/13 |
| First scored | 3/13 (execution 3) |
| Final | **12/13** |
| Package files withheld | 39 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `predicted_winner_believes_not_lose_table4_col1` | 0.269 (0.058) | 0.273694 | 1.74% | ±0.058 (se_band) | PASS | FAIL |
| `initial_acceptance_believes_not_lose_table4_col1` | 0.306 (0.066) | 0.298033 | 2.60% | ±0.066 (se_band) | PASS | FAIL |
| `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 (0.035) | 0.221039 | 6.27% | ±0.035 (se_band) | PASS | FAIL |
| `predicted_winner_heterogeneity_table4_col3` | 0.246 (0.064) | 0.257148 | 4.53% | ±0.064 (se_band) | PASS | FAIL |
| `initial_acceptance_heterogeneity_table4_col3` | 0.015 (0.087) | 0.052108 | 247.39% | ±0.087 (se_band) | PASS | PASS |
| `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 (0.058) | 0.038549 | 102.89% | ±0.058 (se_band) | PASS | PASS |
| `winner_x_initial_acceptance_table4_col3` | 0.166 (0.079) | 0.147589 | 11.09% | ±0.079 (se_band) | PASS | FAIL |
| `winner_x_yellow_vests_supporter_table4_col3` | -0.151 (0.069) | -0.175817 | 16.44% | ±0.069 (se_band) | PASS | FAIL |
| `winner_x_initial_win_belief_table4_col3` | 0.08 (0.079) | 0.105844 | 32.30% | ±0.079 (se_band) | PASS | FAIL |
| `predicted_winner_believes_wins_table4_col4` | 0.153 (0.045) | 0.14966 | 2.18% | ±0.045 (se_band) | PASS | FAIL |
| `n_obs_table4_col1` | 757 | 757 | 0.00% | ±37.85 (relative) | PASS | PASS |
| `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 (0.132) | 0.556228 | 4.16% | ±0.132 (se_band) | PASS | FAIL |
| `believes_effective_on_approval_iv_table8_col1` | 0.416 (0.168) | 0.036564 | 91.21% | ±0.168 (se_band) | FAIL | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) winning_feedback_category has codes 1,2,3 without usable labels; mapping lowest->winner, middle->unaffected, highest->loser (factor levels Gagnant < Non affecte < Perdant)
- (DEVIATION: line) winning_category has codes 1,2,3 without usable labels; mapping lowest->winner, middle->unaffected, highest->loser (factor levels Gagnant < Non affecte < Perdant)
- (DEVIATION: line) using gagnant_cible_categorie instead of win_cible_category for targeted winner category
- (DEVIATION: line) Table 8 endogenous belief coded as 'does not believe the tax is ineffective' (not No) and instrumented by the scientists-agree information and the climate-change information only

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 35,370 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 15,521 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 20,209 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 24,255 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 34,287 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/prompt-5.txt`
- [`prompt/prompt-6.txt`](prompt/prompt-6.txt) — 33,354 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/prompt-6.txt`
- [`prompt/prompt-7.txt`](prompt/prompt-7.txt) — 34,955 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/prompt-7.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 282 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 13,299 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 282 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 288 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-2/feedback.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 518 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 14,459 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 288 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,455 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 129 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-3/feedback.txt`
- [`output/attempt-3/samples.txt`](output/attempt-3/samples.txt) — 627 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-3/samples.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 17,554 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 424 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 3,873 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-3/stdout.txt`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 1,008 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-4/feedback.txt`
- [`output/attempt-4/samples.txt`](output/attempt-4/samples.txt) — 655 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-4/samples.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 19,459 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 382 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 2,973 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-4/stdout.txt`
- [`output/attempt-5/feedback.txt`](output/attempt-5/feedback.txt) — 112 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-5/feedback.txt`
- [`output/attempt-5/samples.txt`](output/attempt-5/samples.txt) — 655 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-5/samples.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 19,507 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 382 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 3,063 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-5/stdout.txt`
- [`output/attempt-6/feedback.txt`](output/attempt-6/feedback.txt) — 112 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-6/feedback.txt`
- [`output/attempt-6/samples.txt`](output/attempt-6/samples.txt) — 655 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-6/samples.txt`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 20,099 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 382 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 3,363 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/attempt-6/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 655 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/samples.txt`
- [`output/script.R`](output/script.R) — 20,496 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 382 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,304 bytes, from `benchmark/results/artifacts/douenne-2022-yellow-vests-carbon-tax/independent/pipeline/20261103T104817Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 13,300 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/2c81962bcf6c0ed959951e1c.json`
- [`output/answer-2.md`](output/answer-2.md) — 14,460 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/b17cd626b8fc2176382ec597.json`
- [`output/answer-3.md`](output/answer-3.md) — 17,555 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/99572b3057322b902c74847f.json`
- [`output/answer-4.md`](output/answer-4.md) — 19,460 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/408f24aeab62e96c670334a4.json`
- [`output/answer-5.md`](output/answer-5.md) — 19,508 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/54e0711f7613b1a6feb0e515.json`
- [`output/answer-6.md`](output/answer-6.md) — 20,100 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/fe969c01705b95235054caea.json`
- [`output/answer-7.md`](output/answer-7.md) — 20,497 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/73163cec1f9cd8c4cd94287a.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request 2c81962bcf6c0ed959951e1c: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix (request b17cd626b8fc2176382ec597: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix (request 99572b3057322b902c74847f: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-postfix (request 408f24aeab62e96c670334a4: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus-postfix (request 54e0711f7613b1a6feb0e515: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-6.md: reply to prompt-6.txt from the LLM oracle store desktop-opus-postfix (request fe969c01705b95235054caea: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-7.md: reply to prompt-7.txt from the LLM oracle store desktop-opus-postfix (request 73163cec1f9cd8c4cd94287a: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 9 model calls; 7 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
