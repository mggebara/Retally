# molina-garzon-2022-decentralization-cooperation · seeded · claude-code · 2026-11-06-a

| | |
|---|---|
| Paper | `molina-garzon-2022-decentralization-cooperation` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-06-a |
| Date | 2026-11-06T16:32:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-1paper-all-modes-2026-11-06.json` |
| Artifacts | `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/seeded/claude-code/20261106T163416Z` |
| Run directory | `benchmark/reproductions/molina-garzon-2022-decentralization-cooperation/seeded/2026-11-06-a` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 12/12 |
| First scored | 12/12 (execution 1) |
| Final | **12/12** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `decentralized_table2_col1` | 0.83 (0.23) | 0.82582 | 0.50% | ±0.0166 (relative) | PASS | PASS |
| `communication_table2_col1` | 2.54 (0.21) | 2.54073 | 0.03% | ±0.0508 (relative) | PASS | PASS |
| `decentralized_table2_col2` | 0.41 (0.3) | 0.409236 | 0.19% | ±0.0082 (relative) | PASS | PASS |
| `communication_table2_col2` | 2.02 (0.32) | 2.02311 | 0.15% | ±0.0404 (relative) | PASS | PASS |
| `decentralized_x_communication_table2_col2` | 0.76 (0.38) | 0.761756 | 0.23% | ±0.0152 (relative) | PASS | PASS |
| `n_obs_table2` | 1980 | 1980 | 0.00% | ±99 (relative) | PASS | PASS |
| `decentralized_table3_allties_base` | 0.22 (0.12) | 0.217647 | 1.07% | ±0.005 (printed_precision) | PASS | PASS |
| `decentralized_table3_allties_full` | 0.24 (0.14) | 0.239524 | 0.20% | ±0.005 (printed_precision) | PASS | PASS |
| `decentralized_table3_strongties_base` | 0.61 (0.28) | 0.607208 | 0.46% | ±0.0122 (relative) | PASS | PASS |
| `decentralized_table3_strongties_full` | 1.07 (0.31) | 1.07411 | 0.38% | ±0.0214 (relative) | PASS | PASS |
| `n_obs_table3_base` | 231 | 231 | 0.00% | ±11.55 (relative) | PASS | PASS |
| `n_obs_table3_full` | 226 | 226 | 0.00% | ±11.3 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Single run, no attempts. Table 2: translated the authors' Stata reg with pweight=weights_games_full_scaled and vce(cluster publicid) into fixest::feols (weights, cluster=~publicid, p_type as factor), full sample of publicgoodgame_dataAug27.dta with listwise deletion (N=1980). Table 3: the authors' weighted Poisson glm with log-denominator offset on clanalysis_anondata_vNov16.csv, base and full (player-type) models, CR1 municipality-clustered SEs as in clse.f; N=231/226. All reproduced values match the paper at reported precision.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 69,219 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/seeded/claude-code/20261106T163416Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 814 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/seeded/claude-code/20261106T163416Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 288 bytes, from `benchmark/.cache/claude-code/molina-garzon-2022-decentralization-cooperation/seeded/2026-11-06-a/paper.txt`

## What it produced

- [`output/reproduction.json`](output/reproduction.json) — 983 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/seeded/claude-code/20261106T163416Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,684 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/seeded/claude-code/20261106T163416Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 168 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/seeded/claude-code/20261106T163416Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 5,477 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/seeded/claude-code/20261106T163416Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 268 bytes, from `benchmark/results/artifacts/molina-garzon-2022-decentralization-cooperation/seeded/claude-code/20261106T163416Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
