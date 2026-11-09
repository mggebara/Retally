# brouwer-2022-teaching-norms · independent · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `brouwer-2022-teaching-norms` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T17:50:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261107T194817Z` |
| Run directory | `benchmark/reproductions/brouwer-2022-teaching-norms/independent/2026-11-07-a` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 12/12 (execution 2) |
| Final | **12/12** |
| Package files withheld | 19 |
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

Agent notes: attempt-1 was exploratory (tabulated scene/condition and control variables in master.csv; no RESULT lines). Final script: pooled OLS LPMs via fixest::feols, Punishment ~ Child*VH on Violation and Violation+Help scenes (n=400/399), Helping ~ Child*VH on Help and Violation+Help scenes (n=401/400), VH = ViolationHelp dummy, controls male (Male Target), hugo (Male Actor, inferred from Table 2 coefficient pattern / variable role), Morning, witness, rich, Rain, Hot; SEs clustered by School (30 clusters). The one missing-gender target is dropped by listwise deletion in the controlled models. The estimates matched every Table 2 coefficient, N and R2 at reported precision, so no claim-driven revisions were made.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 22,005 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261107T194817Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 841 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261107T194817Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 253 bytes, from `benchmark/.cache/claude-code/brouwer-2022-teaching-norms/independent/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 516 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261107T194817Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261107T194817Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 1,775 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261107T194817Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 253 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261107T194817Z/attempt-1/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 1,201 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261107T194817Z/reproduction.json`
- [`output/script.R`](output/script.R) — 1,567 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261107T194817Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 118 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261107T194817Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,677 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261107T194817Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 253 bytes, from `benchmark/results/artifacts/brouwer-2022-teaching-norms/independent/claude-code/20261107T194817Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
