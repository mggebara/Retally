# manekin-2022-effective-for-whom · seeded · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `manekin-2022-effective-for-whom` |
| Mode | seeded |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T19:38:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-23papers-seeded-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261102T194315Z` |
| Run directory | `benchmark/reproductions/manekin-2022-effective-for-whom/seeded/2026-11-02-b` |
| Executions | 1 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 12/12 |
| First scored | 12/12 (execution 1) |
| Final | **12/12** |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `study1_us_black_perceived_violence` | 0.235 (0.117) | 0.235246 | 0.10% | ±0.0047 (relative) | PASS | PASS |
| `study1_us_black_police_action` | 0.268 (0.127) | 0.26801 | 0.00% | ±0.00536 (relative) | PASS | PASS |
| `study1_israel_ethiopian_perceived_violence` | 0.425 (0.107) | 0.425066 | 0.02% | ±0.0085 (relative) | PASS | PASS |
| `study1_israel_ethiopian_police_action` | 0.181 (0.118) | 0.180704 | 0.16% | ±0.00362 (relative) | PASS | PASS |
| `study1_israel_arab_perceived_violence` | 0.623 (0.108) | 0.623088 | 0.01% | ±0.01246 (relative) | PASS | PASS |
| `study1_israel_arab_police_action` | 0.964 (0.119) | 0.9642 | 0.02% | ±0.01928 (relative) | PASS | PASS |
| `study2_us_black_perceived_violence` | 0.347 (0.115) | 0.346652 | 0.10% | ±0.00694 (relative) | PASS | PASS |
| `study2_us_black_police_action` | 0.429 (0.114) | 0.42873 | 0.06% | ±0.00858 (relative) | PASS | PASS |
| `respondents_study1_us` | 2269 | 2269 | 0.00% | ±113.45 (relative) | PASS | PASS |
| `respondents_study1_israel` | 3063 | 3063 | 0.00% | ±153.15 (relative) | PASS | PASS |
| `respondents_study2_us` | 3013 | 3013 | 0.00% | ±150.65 (relative) | PASS | PASS |
| `respondents_study2_israel` | 3465 | 3465 | 0.00% | ±173.25 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

_None declared._

Agent notes: Translated replicate_table_1.R (Study 1, weighted lm of outcome on identity_protesters + tactic factors) and replicate_table_4.R (paper's Table 2, Study 2, unweighted lm on black/identity_protesters + group_goal + commitment). Israeli identity factor levels 1=Ethiopian, 2=Arab (per replicate_table_A14.R labels). Respondent counts are nobs of the perceived-violence regressions. Single run; no comparison-driven changes.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 69,133 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261102T194315Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 904 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261102T194315Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 256 bytes, from `benchmark/.cache/claude-code/manekin-2022-effective-for-whom/seeded/2026-11-02-b/paper.txt`

## What it produced

- [`output/reproduction.json`](output/reproduction.json) — 853 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261102T194315Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,769 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261102T194315Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261102T194315Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 6,465 bytes, from `benchmark/results/artifacts/manekin-2022-effective-for-whom/seeded/claude-code/20261102T194315Z/stdout.txt`
