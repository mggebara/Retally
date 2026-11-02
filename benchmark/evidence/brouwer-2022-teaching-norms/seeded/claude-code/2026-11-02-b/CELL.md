# brouwer-2022-teaching-norms · seeded · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `brouwer-2022-teaching-norms` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T19:33:00Z |
| Results file | `benchmark/results/claude-code-run2-23papers-seeded-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/brouwer-2022-teaching-norms/seeded/claude-code/20261102T194315Z` |
| Run directory | `benchmark/reproductions/brouwer-2022-teaching-norms/seeded/2026-11-02-b` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 12/12 |
| First scored | 12/12 (execution 1) |
| Final | **12/12** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `child_punishment_no_controls` | 0.11 (0.05) | 0.11 | 0.00% | ±0.005 (printed_precision) | PASS | PASS |
| `child_punishment_controls` | 0.12 (0.04) | 0.116104 | 3.25% | ±0.005 (printed_precision) | PASS | PASS |
| `child_helping_no_controls` | 0.21 (0.05) | 0.212574 | 1.23% | ±0.005 (printed_precision) | PASS | PASS |
| `child_helping_controls` | 0.22 (0.06) | 0.221438 | 0.65% | ±0.005 (printed_precision) | PASS | PASS |
| `vh_punishment_controls` | -0.04 (0.03) | -0.038555 | 3.61% | ±0.005 (printed_precision) | PASS | PASS |
| `vh_helping_controls` | -0.1 (0.04) | -0.103548 | 3.55% | ±0.005 (printed_precision) | PASS | PASS |
| `child_x_vh_punishment_no_controls` | -0.13 (0.04) | -0.13 | 0.00% | ±0.005 (printed_precision) | PASS | PASS |
| `child_x_vh_punishment_controls` | -0.12 (0.04) | -0.12233 | 1.94% | ±0.005 (printed_precision) | PASS | PASS |
| `child_x_vh_helping_no_controls` | -0.06 (0.07) | -0.062574 | 4.29% | ±0.005 (printed_precision) | PASS | PASS |
| `child_x_vh_helping_controls` | -0.07 (0.08) | -0.067709 | 3.27% | ±0.005 (printed_precision) | PASS | PASS |
| `observations_punishment_controls` | 399 | 399 | 0.00% | ±3.99 (relative) | PASS | PASS |
| `observations_helping_no_controls` | 401 | 401 | 0.00% | ±4.01 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Translated the do-file's Table 2 regressions (reg y i.Child##i.ViolationHelp [controls] if Help==0 / Violation==0, cluster(School)) into fixest::feols with School-clustered SEs on master.dta. Controls: male, hugo, Morning, witness, rich, Rain, Hot; the one observation with missing male is dropped in the controlled models (N=399 punishment). Single run; no claim comparison was used to change the script.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 69,178 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/seeded/claude-code/20261102T194315Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 715 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/seeded/claude-code/20261102T194315Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 248 bytes, from `benchmark/.cache/claude-code/brouwer-2022-teaching-norms/seeded/2026-11-02-b/paper.txt`

## What it produced

- [`output/reproduction.json`](output/reproduction.json) — 833 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/seeded/claude-code/20261102T194315Z/reproduction.json`
- [`output/script.R`](output/script.R) — 1,679 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/seeded/claude-code/20261102T194315Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 118 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/seeded/claude-code/20261102T194315Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,530 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/seeded/claude-code/20261102T194315Z/stdout.txt`
