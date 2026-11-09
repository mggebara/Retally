# mokyr-2022-wheels-of-change · blind · claude-code · 2026-11-02-a

| | |
|---|---|
| Paper | `mokyr-2022-wheels-of-change` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-a |
| Date | 2026-11-02T00:30:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-6papers-all-modes-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/mokyr-2022-wheels-of-change/blind/claude-code/20261102T142249Z` |
| Run directory | `benchmark/reproductions/mokyr-2022-wheels-of-change/blind/2026-11-02-a` |
| Executions | 2 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 2) |
| Final | **13/13** |
| Package files withheld | 17 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `watermills_table2_col1` | 0.15 (0.02) | 0.146106 | 2.60% | ±0.02 (se_band) | PASS | PASS |
| `watermills_table2_col2` | 0.14 (0.02) | 0.143814 | 2.72% | ±0.02 (se_band) | PASS | PASS |
| `watermills_table2_col3` | 0.14 (0.02) | 0.141614 | 1.15% | ±0.02 (se_band) | PASS | PASS |
| `watermills_table2_col4` | 0.14 (0.02) | 0.140689 | 0.49% | ±0.02 (se_band) | PASS | PASS |
| `watermills_table2_col5` | 0.12 (0.03) | 0.119902 | 0.08% | ±0.03 (se_band) | PASS | PASS |
| `watermills_ols_table3_col5` | 0.12 (0.03) | 0.116758 | 2.70% | ±0.03 (se_band) | PASS | PASS |
| `watermills_iv_table3_col2` | 0.16 (0.04) | 0.159129 | 0.54% | ±0.04 (se_band) | PASS | PASS |
| `watermills_iv_table3_col4` | 0.15 (0.04) | 0.152249 | 1.50% | ±0.04 (se_band) | PASS | PASS |
| `watermills_iv_table3_col6` | 0.16 (0.04) | 0.159158 | 0.53% | ±0.04 (se_band) | PASS | PASS |
| `first_stage_f_table3_col2` | 19.9 | 19.9036 | 0.02% | ±0.199 (relative) | PASS | PASS |
| `first_stage_f_table3_col4` | 16.96 | 16.9575 | 0.01% | ±0.1696 (relative) | PASS | PASS |
| `first_stage_f_table3_col6` | 16.17 | 16.1736 | 0.02% | ±0.1617 (relative) | PASS | PASS |
| `n_districts_tables2_3` | 298 | 298 | 0.00% | ±14.9 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) First-stage F reported as the county-clustered Wald F on the single excluded instrument (fixest ivwald1), consistent with the paper's statement that all regressions cluster at the county level; Table 3 notes mention heteroscedasticity-robust SEs, and the paper's exact F definition (e.g. Stata ivreg2 KP F with its small-sample corrections) is not stated.

Agent notes: attempt-1 was exploratory (variable inspection, no RESULT lines). Data: replication_data.dta. Dependent var = wrights/pcmean, regressor = mills/pcmean (pcmean = mean population 1710-50; the per-10,000 scale cancels in the coefficient). Sample = 298 districts with non-missing Domesday mills. Controls: main = latitude, longitude, dist_rug_mean, dist_elevation_mean; agricultural = suitmean, wheat_hi (wheat_tmean<=5), dist_grass_mean; climatic = precip_mean_dist, temp_mean_dist; other = pcmean, min_harbor, DIST_London, min_dist_to_roman_rds, min_dist_2nav_rivers, area. River suitability = riv_rug26count; instrument = riv_rug26count x wheat_hi. Table 3 col 2 IV controls only river suitability and wheat_hi; col 4 adds main/agri/climatic; col 6 adds other + population; col 5 OLS = Table 2 col 5 + river suitability. SEs clustered by GAZ_CNTY (35 clusters in sample). fixest feols for OLS and 2SLS.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,433 bytes, from `benchmark/results/artifacts/mokyr-2022-wheels-of-change/blind/claude-code/20261102T142249Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 892 bytes, from `benchmark/results/artifacts/mokyr-2022-wheels-of-change/blind/claude-code/20261102T142249Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 254 bytes, from `benchmark/.cache/claude-code/mokyr-2022-wheels-of-change/blind/2026-11-02-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,166 bytes, from `benchmark/results/artifacts/mokyr-2022-wheels-of-change/blind/claude-code/20261102T142249Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/mokyr-2022-wheels-of-change/blind/claude-code/20261102T142249Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,584 bytes, from `benchmark/results/artifacts/mokyr-2022-wheels-of-change/blind/claude-code/20261102T142249Z/attempt-1/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,749 bytes, from `benchmark/results/artifacts/mokyr-2022-wheels-of-change/blind/claude-code/20261102T142249Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,237 bytes, from `benchmark/results/artifacts/mokyr-2022-wheels-of-change/blind/claude-code/20261102T142249Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/mokyr-2022-wheels-of-change/blind/claude-code/20261102T142249Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,142 bytes, from `benchmark/results/artifacts/mokyr-2022-wheels-of-change/blind/claude-code/20261102T142249Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
