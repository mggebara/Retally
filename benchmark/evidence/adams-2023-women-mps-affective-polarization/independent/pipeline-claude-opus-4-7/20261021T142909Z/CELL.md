# adams-2023-women-mps-affective-polarization · independent · pipeline-claude-opus-4-7 · 20261021T142909Z

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | independent |
| Reproducer | pipeline |
| Model | claude-opus-4-7 |
| Run | 20261021T142909Z |
| Date | 2026-10-21T14:29:09Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-10papers-all-modes-2026-10-21.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z` |
| Executions | 5 |
| Refinements | 4 (1 error + 3 claim) |
| First attempt | 0/11 |
| First scored | 0/11 (execution 2) |
| Final | **7/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `women_mps_coef_bivariate` | 1.89 (0.43) | 1.90904 | 1.01% | ±0.43 (se_band) | PASS | FAIL |
| `women_mps_coef_full` | 1.73 (0.52) | 1.92446 | 11.24% | ±0.52 (se_band) | PASS | FAIL |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 1.86071 | 11.39% | ±0.53 (se_band) | PASS | FAIL |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.8661 | 65.14% | ±0.5 (se_band) | FAIL | FAIL |
| `right_left_distance_coef_full` | -0.6 (0.09) | -0.573101 | 4.48% | ±0.09 (se_band) | PASS | FAIL |
| `coalition_partners_coef_full` | 0.94 (0.25) | 1.07692 | 14.57% | ±0.25 (se_band) | PASS | FAIL |
| `opposition_partners_coef_full` | 0.37 (0.11) | 0.380451 | 2.82% | ±0.11 (se_band) | PASS | FAIL |
| `n_directed_dyads` | 1842 | 1535 | 16.67% | ±92.1 (relative) | FAIL | FAIL |
| `n_obs_women_partisans` | 1836 | 1535 | 16.39% | ±91.8 (relative) | FAIL | FAIL |
| `n_obs_men_partisans` | 1833 | 1529 | 16.58% | ±91.65 (relative) | FAIL | FAIL |
| `n_election_studies` | 81 | 81 | 0.00% | ±4.05 (relative) | PASS | FAIL |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/11 pass, which agrees with the row's 7/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (DEVIATION: line) Treated prior_seats==999 as missing and substituted mp_number to recover ~1842 dyad sample; paper does not clearly specify the handling of this sentinel value.

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 13,276 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/prompt-1.txt`
- [`prompt/prompt-2.txt`](prompt/prompt-2.txt) — 8,211 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/prompt-2.txt`
- [`prompt/prompt-3.txt`](prompt/prompt-3.txt) — 12,689 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/prompt-3.txt`
- [`prompt/prompt-4.txt`](prompt/prompt-4.txt) — 14,914 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/prompt-4.txt`
- [`prompt/prompt-5.txt`](prompt/prompt-5.txt) — 20,018 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/prompt-5.txt`

## What it produced

- [`output/attempt-1/feedback.txt`](output/attempt-1/feedback.txt) — 32 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/attempt-1/feedback.txt`
- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 2,021 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 4,222 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/attempt-1/stdout.txt`
- [`output/attempt-2/feedback.txt`](output/attempt-2/feedback.txt) — 886 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/attempt-2/feedback.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,730 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,237 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 395 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 4,634 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 3,238 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/attempt-3/stdout.txt`
- [`output/attempt-4/feedback.txt`](output/attempt-4/feedback.txt) — 462 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/attempt-4/feedback.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 6,719 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 8,393 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/attempt-4/stdout.txt`
- [`output/script.R`](output/script.R) — 7,303 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,219 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/pipeline/20261021T142909Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 2,021 bytes, from `benchmark/.cache/llm/4dfd798e6866eac112dc73ff.json`
- [`output/answer-2.md`](output/answer-2.md) — 2,730 bytes, from `benchmark/.cache/llm/13f9f6e8411858fd100d42b1.json`
- [`output/answer-3.md`](output/answer-3.md) — 4,634 bytes, from `benchmark/.cache/llm/488039e352019e1a0ffba0b9.json`
- [`output/answer-4.md`](output/answer-4.md) — 6,719 bytes, from `benchmark/.cache/llm/50c203c707441809c5637491.json`
- [`output/answer-5.md`](output/answer-5.md) — 7,303 bytes, from `benchmark/.cache/llm/74d167a6af6c54dc11c89c90.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM cache (request 4dfd798e6866eac112dc73ff: model claude-opus-4-7, max_tokens 8192, effort None)
- answer-2.md: reply to prompt-2.txt from the LLM cache (request 13f9f6e8411858fd100d42b1: model claude-opus-4-7, max_tokens 8192, effort None)
- answer-3.md: reply to prompt-3.txt from the LLM cache (request 488039e352019e1a0ffba0b9: model claude-opus-4-7, max_tokens 8192, effort None)
- answer-4.md: reply to prompt-4.txt from the LLM cache (request 50c203c707441809c5637491: model claude-opus-4-7, max_tokens 8192, effort None)
- answer-5.md: reply to prompt-5.txt from the LLM cache (request 74d167a6af6c54dc11c89c90: model claude-opus-4-7, max_tokens 8192, effort None)
