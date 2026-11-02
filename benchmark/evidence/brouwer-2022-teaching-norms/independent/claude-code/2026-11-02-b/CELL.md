# brouwer-2022-teaching-norms · independent · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `brouwer-2022-teaching-norms` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T07:03:00Z |
| Results file | `benchmark/results/claude-code-run2-4papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261102T090910Z` |
| Run directory | `benchmark/reproductions/brouwer-2022-teaching-norms/independent/2026-11-02-b` |
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
| `observations_punishment_controls` | 399 | 399 | 0.00% | ±3.99 (relative) | PASS | PASS |
| `observations_helping_no_controls` | 401 | 401 | 0.00% | ±4.01 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: attempt-1 was exploratory: it tabulated scene/condition coding and missingness in master.csv and printed no RESULT lines. The final run estimates Table 2 as pooled OLS linear probability models (fixest::feols) of Punishment (Violation and Violation+Help scenes) and Helping (Help and Violation+Help scenes) on Child, VH (ViolationHelp), and Child x VH, with School-clustered SEs (30 clusters). Columns 2 and 4 add the controls male (Male Target), hugo (Male Actor, inferred from coding; its coefficients match the paper), Morning, witness, rich, Rain and Hot. Listwise deletion drops the one observation with missing male in each sample, giving N = 400/399/401/400. Every coefficient, constant and R2 matches Table 2 at the reported precision. The first scored run is the final one, and the script was not changed after the comparison.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 21,345 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261102T090910Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 841 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261102T090910Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 253 bytes, from `benchmark/.cache/claude-code/brouwer-2022-teaching-norms/independent/2026-11-02-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 688 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261102T090910Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261102T090910Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 5,533 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261102T090910Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,324 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261102T090910Z/reproduction.json`
- [`output/script.R`](output/script.R) — 1,732 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261102T090910Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 118 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261102T090910Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,677 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261102T090910Z/stdout.txt`
