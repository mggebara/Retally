# brouwer-2022-teaching-norms · blind · claude-code · 2026-11-02-a

| | |
|---|---|
| Paper | `brouwer-2022-teaching-norms` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-a |
| Date | 2026-11-02T06:05:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-4papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/brouwer-2022-teaching-norms/blind/claude-code/20261102T062002Z` |
| Run directory | `benchmark/reproductions/brouwer-2022-teaching-norms/blind/2026-11-02-a` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 12/12 (execution 2) |
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

Agent notes: attempt-1 was exploratory (variable codings, missingness; no RESULT lines). Final: master.dta; punishment sample = scenes Violation and Violation+Help (400), helping sample = scenes Help and Violation+Help (401). feols OLS LPM of outcome on Child*VH (VH = scene==Violation+Help), controls male (Male Target), hugo (Male Actor), Morning, witness, rich, Rain, Hot; SEs clustered by School (30 clusters). The missing-gender target drops listwise (399 and 400 obs in the controlled models). Specification taken from the paper text; no paper values consulted.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,922 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/blind/claude-code/20261102T062002Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 809 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/blind/claude-code/20261102T062002Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 253 bytes, from `benchmark/.cache/claude-code/brouwer-2022-teaching-norms/blind/2026-11-02-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 814 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/blind/claude-code/20261102T062002Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/blind/claude-code/20261102T062002Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 2,308 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/blind/claude-code/20261102T062002Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,037 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/blind/claude-code/20261102T062002Z/reproduction.json`
- [`output/script.R`](output/script.R) — 1,799 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/blind/claude-code/20261102T062002Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 118 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/blind/claude-code/20261102T062002Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,677 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/blind/claude-code/20261102T062002Z/stdout.txt`
