# brouwer-2022-teaching-norms · independent · pipeline-desktop-opus-run2 · 20261102T090216Z

| | |
|---|---|
| Paper | `brouwer-2022-teaching-norms` |
| Mode | independent |
| Reproducer | pipeline (LLM oracle) |
| Model | desktop-opus-run2 |
| Run | 20261102T090216Z |
| Date | 2026-11-02T09:02:16Z |
| Data access | public |
| Results file | `benchmark/results/pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/pipeline/20261102T090216Z` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 12/12 |
| First scored | 12/12 (execution 1) |
| Final | **12/12** |
| Package files withheld | 18 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `child_punishment_no_controls` | 0.11 (0.05) | 0.11 | 0.00% | ±0.05 (se_band) | PASS | PASS |
| `child_punishment_controls` | 0.12 (0.04) | 0.116104 | 3.25% | ±0.04 (se_band) | PASS | PASS |
| `child_helping_no_controls` | 0.21 (0.05) | 0.212574 | 1.23% | ±0.05 (se_band) | PASS | PASS |
| `child_helping_controls` | 0.22 (0.06) | 0.221438 | 0.65% | ±0.06 (se_band) | PASS | PASS |
| `vh_punishment_controls` | -0.04 (0.03) | -0.038555 | 3.61% | ±0.03 (se_band) | PASS | PASS |
| `vh_helping_controls` | -0.1 (0.04) | -0.103548 | 3.55% | ±0.04 (se_band) | PASS | PASS |
| `child_x_vh_punishment_no_controls` | -0.13 (0.04) | -0.13 | 0.00% | ±0.04 (se_band) | PASS | PASS |
| `child_x_vh_punishment_controls` | -0.12 (0.04) | -0.12233 | 1.94% | ±0.04 (se_band) | PASS | PASS |
| `child_x_vh_helping_no_controls` | -0.06 (0.07) | -0.062574 | 4.29% | ±0.07 (se_band) | PASS | PASS |
| `child_x_vh_helping_controls` | -0.07 (0.08) | -0.067709 | 3.27% | ±0.08 (se_band) | PASS | PASS |
| `observations_punishment_controls` | 399 | 399 | 0.00% | ±19.95 (relative) | PASS | PASS |
| `observations_helping_no_controls` | 401 | 401 | 0.00% | ±20.05 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

## What the model was given

- [`prompt/prompt-1.txt`](prompt/prompt-1.txt) — 18,714 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/pipeline/20261102T090216Z/prompt-1.txt`

## What it produced

- [`output/script.R`](output/script.R) — 2,920 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/pipeline/20261102T090216Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 118 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/pipeline/20261102T090216Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,976 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/pipeline/20261102T090216Z/stdout.txt`
- [`output/answer-1.md`](output/answer-1.md) — 2,921 bytes, from `benchmark/.cache/llm-oracle/desktop-opus-run2/answers/a27e406af3197f0e92bfe5e0.json`

## Notes

- answer-1.md: reply to prompt-1.txt from the LLM oracle store desktop-opus-run2 (request a27e406af3197f0e92bfe5e0: model claude-opus-5-5, max_tokens 16384, effort high)
- usage records 3 model calls; 1 are code-generation prompts kept above, the other 2 (paper extraction) leave no prompt in the artifacts
