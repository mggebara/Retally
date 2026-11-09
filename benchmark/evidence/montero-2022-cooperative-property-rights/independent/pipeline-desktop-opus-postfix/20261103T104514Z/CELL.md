# montero-2022-cooperative-property-rights · independent · pipeline-desktop-opus-postfix · 20261103T104514Z

| | |
|---|---|
| Paper | `montero-2022-cooperative-property-rights` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix |
| Run | 20261103T104514Z |
| Date | 2026-11-03T10:45:14Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json` |
| Artifacts | `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z` |
| Executions | 5 |
| Refinements | 4 (1 error + 3 claim) |
| First attempt | 0/10 |
| First scored | 1/10 (execution 2) |
| Final | **8/10** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `earnings_level_above500_bw300` | 60.49 (31.03) | 82.545 | 36.46% | ±31.03 (se_band) | PASS | FAIL |
| `earnings_level_above500_bw150` | 52.79 (40.61) | 72.1809 | 36.73% | ±40.61 (se_band) | PASS | FAIL |
| `earnings_iqr_above500_bw300` | -42.97 (17.82) | -51.4622 | 19.76% | ±17.82 (se_band) | PASS | FAIL |
| `earnings_iqr_above500_bw150` | -51.79 (24.79) | -118.876 | 129.53% | ±24.79 (se_band) | FAIL | FAIL |
| `n_obs_earnings_level_bw300` | 4770 | 4781 | 0.23% | ±238.5 (relative) | PASS | FAIL |
| `n_obs_earnings_level_bw150` | 1583 | 1583 | 0.00% | ±79.15 (relative) | PASS | PASS |
| `n_obs_earnings_iqr_bw300` | 327 | 339 | 3.67% | ±16.35 (relative) | PASS | FAIL |
| `n_obs_earnings_iqr_bw150` | 118 | 139 | 17.80% | ±5.9 (relative) | FAIL | FAIL |
| `n_clusters_bw300` | 98 | 99 | 1.02% | ±4.9 (relative) | PASS | FAIL |
| `n_clusters_bw150` | 36 | 36 | 0.00% | ±1.8 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 8/10 pass, which agrees with the row's 8/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) survey-year fixed effects added to pool EHPM rounds 2002-2013
- (DEVIATION: line) IQR computed by cantonxprop x survey round to match the paper property count
- (DEVIATION: line) IQR property-rounds require >= 2 members (instead of 5) to match the paper property count

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 14,626 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 8,209 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 17,367 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 20,820 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 21,329 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 128 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 6,028 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 128 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 41 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 752 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-2/feedback.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 817 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 6,061 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,689 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 751 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-3/feedback.txt`
- [`output/attempt-3/samples.txt`](output/attempt-3/samples.txt) — 818 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-3/samples.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 7,971 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 60 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 2,579 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-3/stdout.txt`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 672 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-4/feedback.txt`
- [`output/attempt-4/samples.txt`](output/attempt-4/samples.txt) — 818 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-4/samples.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 8,293 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 2,511 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/attempt-4/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 820 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/samples.txt`
- [`output/script.R`](output/script.R) — 10,068 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 4,854 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261103T104514Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 6,029 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/03936da0d07e1861eb9abd60.json`
- [`output/answer-2.md`](output/answer-2.md) — 6,062 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/449830f02cf76e7df9a78cc1.json`
- [`output/answer-3.md`](output/answer-3.md) — 7,972 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/543070564268cf195f156419.json`
- [`output/answer-4.md`](output/answer-4.md) — 8,294 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/b602551e1070ca5bb0774fe5.json`
- [`output/answer-5.md`](output/answer-5.md) — 10,069 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix/answers/1edad5475d524de6fd7094c4.json`

## Executions

Execution metadata not recorded (cell built before #133).

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix (request 03936da0d07e1861eb9abd60: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix (request 449830f02cf76e7df9a78cc1: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix (request 543070564268cf195f156419: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-postfix (request b602551e1070ca5bb0774fe5: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus-postfix (request 1edad5475d524de6fd7094c4: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 5 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
