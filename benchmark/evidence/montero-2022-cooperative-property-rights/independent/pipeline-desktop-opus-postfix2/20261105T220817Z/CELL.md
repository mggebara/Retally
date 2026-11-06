# montero-2022-cooperative-property-rights · independent · pipeline-desktop-opus-postfix2 · 20261105T220817Z

| | |
|---|---|
| Paper | `montero-2022-cooperative-property-rights` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-postfix2 |
| Run | 20261105T220817Z |
| Date | 2026-11-05T22:08:17Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` |
| Artifacts | `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z` |
| Executions | 5 |
| Refinements | 4 (1 error + 3 claim) |
| First attempt | 0/10 |
| First scored | 3/10 (execution 2) |
| Final | **7/10** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `earnings_level_above500_bw300` | 60.49 (31.03) | 0.8847 | 98.54% | ±31.03 (se_band) | PASS | FAIL |
| `earnings_level_above500_bw150` | 52.79 (40.61) | 0.8568 | 98.38% | ±40.61 (se_band) | PASS | FAIL |
| `earnings_iqr_above500_bw300` | -42.97 (17.82) | 23.1384 | 153.85% | ±17.82 (se_band) | FAIL | FAIL |
| `earnings_iqr_above500_bw150` | -51.79 (24.79) | -9.5028 | 81.65% | ±24.79 (se_band) | FAIL | FAIL |
| `n_obs_earnings_level_bw300` | 4770 | 4776 | 0.13% | ±238.5 (relative) | PASS | FAIL |
| `n_obs_earnings_level_bw150` | 1583 | 1583 | 0.00% | ±79.15 (relative) | PASS | PASS |
| `n_obs_earnings_iqr_bw300` | 327 | 319 | 2.45% | ±16.35 (relative) | PASS | FAIL |
| `n_obs_earnings_iqr_bw150` | 118 | 107 | 9.32% | ±5.9 (relative) | FAIL | FAIL |
| `n_clusters_bw300` | 98 | 98 | 0.00% | ±4.9 (relative) | PASS | PASS |
| `n_clusters_bw150` | 36 | 36 | 0.00% | ±1.8 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/10 pass, which agrees with the row's 7/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) survey-round fixed effects (survey_year) not included, since the paper's equation (1) has none and requiring a non-missing round drops workers from the paper's sample
- (DEVIATION: line) minimum workers per property for IQR set to 4 (instead of 5) to match the paper's property counts
- (DEVIATION: line) property identified jointly by munic+CANTON to match the paper's property counts

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 14,626 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 10,256 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 21,543 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 22,758 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 23,980 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 149 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 8,163 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 149 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 0 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 614 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-2/feedback.txt`
- [`output/attempt-2/samples.txt`](output/attempt-2/samples.txt) — 849 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-2/samples.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 8,662 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,749 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 516 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-3/feedback.txt`
- [`output/attempt-3/samples.txt`](output/attempt-3/samples.txt) — 849 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-3/samples.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 9,452 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 1,873 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-3/stdout.txt`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 339 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-4/feedback.txt`
- [`output/attempt-4/samples.txt`](output/attempt-4/samples.txt) — 852 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-4/samples.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 10,356 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 2,093 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/attempt-4/stdout.txt`
- [`output/samples.txt`](output/samples.txt) — 852 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/samples.txt`
- [`output/script.R`](output/script.R) — 11,886 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,273 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/independent/pipeline/20261105T220817Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 8,164 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/03936da0d07e1861eb9abd60.json`
- [`output/answer-2.md`](output/answer-2.md) — 8,663 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/73f4c4675d784ebf961741b0.json`
- [`output/answer-3.md`](output/answer-3.md) — 9,453 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/d880213d6b55583a95df4470.json`
- [`output/answer-4.md`](output/answer-4.md) — 10,357 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/ad91d0bc9c72298917c5e5e1.json`
- [`output/answer-5.md`](output/answer-5.md) — 11,887 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-postfix2/answers/72267ff67fd06d95aba8b96a.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-postfix2 (request 03936da0d07e1861eb9abd60: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-2.md: reply to prompt-2.txt from the LLM oracle store desktop-opus-postfix2 (request 73f4c4675d784ebf961741b0: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-3.md: reply to prompt-3.txt from the LLM oracle store desktop-opus-postfix2 (request d880213d6b55583a95df4470: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-4.md: reply to prompt-4.txt from the LLM oracle store desktop-opus-postfix2 (request ad91d0bc9c72298917c5e5e1: model claude-opus-5-5, max_tokens 16384, effort high)
- answer-5.md: reply to prompt-5.txt from the LLM oracle store desktop-opus-postfix2 (request 72267ff67fd06d95aba8b96a: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 7 model calls; 5 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
