# montero-2022-cooperative-property-rights · blind · claude-code · 2026-11-01-a

| | |
|---|---|
| Paper | `montero-2022-cooperative-property-rights` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-01-a |
| Date | 2026-11-02T04:21:30Z |
| Results file | `benchmark/results/claude-code-run2-13papers-indep-blind-2026-11-01.json` |
| Artifacts | `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/claude-code/20261102T043821Z` |
| Run directory | `benchmark/reproductions/montero-2022-cooperative-property-rights/blind/2026-11-01-a` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/10 |
| First scored | 6/10 (execution 3) |
| Final | **6/10** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `earnings_level_above500_bw300` | 60.49 (31.03) | 82.3001 | 36.06% | ±31.03 (se_band) | PASS | PASS |
| `earnings_level_above500_bw150` | 52.79 (40.61) | 71.8293 | 36.07% | ±40.61 (se_band) | PASS | PASS |
| `earnings_iqr_above500_bw300` | -42.97 (17.82) | -48.558 | 13.00% | ±17.82 (se_band) | PASS | PASS |
| `earnings_iqr_above500_bw150` | -51.79 (24.79) | -202.009 | 290.05% | ±24.79 (se_band) | FAIL | FAIL |
| `n_obs_earnings_level_bw300` | 4770 | 4781 | 0.23% | ±47.7 (relative) | PASS | PASS |
| `n_obs_earnings_level_bw150` | 1583 | 1583 | 0.00% | ±15.83 (relative) | PASS | PASS |
| `n_obs_earnings_iqr_bw300` | 327 | 76 | 76.76% | ±3.27 (relative) | FAIL | FAIL |
| `n_obs_earnings_iqr_bw150` | 118 | 26 | 77.97% | ±1.18 (relative) | FAIL | FAIL |
| `n_clusters_bw300` | 98 | 99 | 1.02% | ±0.98 (relative) | FAIL | FAIL |
| `n_clusters_bw150` | 36 | 36 | 0.00% | ±0.5 (printed_precision) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 6/10 pass, which agrees with the row's 6/10.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Interquartile range computed per property pooling all survey rounds (Stata type-2 quantiles), properties with >=5 surveyed workers in the bandwidth sample; one observation per property. Because one observation per property cannot carry survey-round FE directly, columns 3-4 use FE for the property's modal survey round (fixest dropped 2 singletons at 150 ha, N=26 of 28 eligible properties).
- (reproduction.json) All survey years in the provided file (2000-2013) kept, although the paper text says 2002-2013; the data file is the authors' constructed analysis sample.
- (DEVIATION: line) IQR computed per property pooling all survey rounds (Stata-style type-2 quantiles); survey-round FE in columns 3-4 enter as the property's modal survey round

Agent notes: Two exploratory runs (variable listing; running-variable/sample checks; no RESULT lines), then one estimation run that is the final. Levels: feols(hh_income_pc ~ Above500 + norm_dist + norm_dist:Above500 \| year), \|norm_dist\| <= bandwidth (300 or 150 ha, inclusive), SEs clustered by former owner (Expropretario_ISTA). norm_dist equals own_amt - 500 and Above500 = 1(norm_dist >= 0). Clusters reported are former owners in the worker-level samples (99 at 300 ha, 36 at 150 ha). The IQR estimates are fragile: without the modal-round FE the Above500 coefficient changes sign (positive at both bandwidths), and their SEs are large. Outcome is nominal hh_income_pc (hh_inc_pc_real also exists in the file; the paper reports dollars per month, so nominal was used). README.pdf was not read.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 16,467 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/claude-code/20261102T043821Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 990 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/claude-code/20261102T043821Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 280 bytes, from `benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/blind/2026-11-01-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 529 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/claude-code/20261102T043821Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/claude-code/20261102T043821Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 12,465 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/claude-code/20261102T043821Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,974 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/claude-code/20261102T043821Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/claude-code/20261102T043821Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 5,148 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/claude-code/20261102T043821Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,898 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/claude-code/20261102T043821Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,318 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/claude-code/20261102T043821Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 63 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/claude-code/20261102T043821Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 910 bytes, from `benchmark/results/artifacts/montero-2022-cooperative-property-rights/blind/claude-code/20261102T043821Z/stdout.txt`
