# forsythe-2022-young-workers-recessions · independent · claude-code · 2026-11-02-b

| | |
|---|---|
| Paper | `forsythe-2022-young-workers-recessions` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-b |
| Date | 2026-11-02T09:06:52Z |
| Results file | `benchmark/results/claude-code-run2-4papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T090910Z` |
| Run directory | `benchmark/reproductions/forsythe-2022-young-workers-recessions/independent/2026-11-02-b` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 13/13 (execution 3) |
| Final | **13/13** |
| Package files withheld | 7 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `young_x_unemp_rate_no_controls` | -0.335 (0.0203) | -0.344465 | 2.83% | ±0.0203 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_no_controls` | -0.0367 (0.0131) | -0.039631 | 7.99% | ±0.0131 (se_band) | PASS | PASS |
| `young_x_unemp_rate_preferred` | -0.253 (0.0185) | -0.25382 | 0.32% | ±0.0185 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_preferred` | 0.0496 (0.0142) | 0.055143 | 11.18% | ±0.0142 (se_band) | PASS | PASS |
| `aggregate_unemp_rate_no_controls` | -0.119 (0.015) | -0.123607 | 3.87% | ±0.015 (se_band) | PASS | PASS |
| `aggregate_unemp_rate_month_year_fe` | -0.0326 (0.0132) | -0.028558 | 12.40% | ±0.0132 (se_band) | PASS | PASS |
| `young_x_unemp_rate_employed` | -0.168 (0.0156) | -0.17096 | 1.76% | ±0.0156 (se_band) | PASS | PASS |
| `experienced_x_unemp_rate_employed` | 0.0179 (0.0101) | 0.021998 | 22.89% | ±0.0101 (se_band) | PASS | PASS |
| `young_x_unemp_rate_unemployed` | -1.928 (0.167) | -1.93912 | 0.58% | ±0.167 (se_band) | PASS | PASS |
| `young_x_unemp_rate_nilf` | -0.49 (0.0332) | -0.500341 | 2.11% | ±0.0332 (se_band) | PASS | PASS |
| `wage_young_x_unemp_rate_all_hires` | -0.0262 (0.0036) | -0.02428 | 7.33% | ±0.0036 (se_band) | PASS | PASS |
| `wage_experienced_x_unemp_rate_all_hires` | -0.0116 (0.00348) | -0.010682 | 7.91% | ±0.00348 (se_band) | PASS | PASS |
| `n_obs_full_sample` | 1.69485e+07 | 1.69485e+07 | 0.00% | ±169485 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) yh_data.csv (2 GB) read with data.table::fread(select=) restricted to the 20 needed columns, to fit the sandbox 4 GB memory / 300 s limits.
- (reproduction.json) Hiring regressions (Tables 1-2) estimated by WLS on cell means (state x month-year x demographic cell x PE group x t-1 status, weighted by summed person weights); point estimates are identical to person-level WLS because every regressor is constant within cells, but clustered SEs are not identical to the person-level ones.
- (reproduction.json) Sample restricted to age < 80 at t-1 (CPS age topcode); this restriction is not stated in the paper but reproduces N = 16,948,516 and the Table 2 subsample Ns exactly. The provided state-unemployment file and state identifiers end in May 2014, so the effective sample ends then.
- (reproduction.json) Years of education from PEEDUCA: 31=0, 32=2.5, 33=5.5, 34=7.5, 35=9, 36=10, 37=11, 38=12, 39=12, 40=13, 41-42=14, 43=16, 44=18, 45-46=20 (the paper does not give its mapping).
- (reproduction.json) Wage sample: hires in t with weekly earnings > 0 and allocation flag PRWERNAL == 0 (1994-early 1995 have no flag and drop out); occupation/industry crosswalk code year assigned by date (occ: 1990 codes through 2002, 2002 codes 2003-2010, 2010 codes 2011+; ind: 1990 through 2002, 2002 codes 2003-2008, 2007 codes 2009-2013, 2012 codes 2014+). N = 120,294 vs 112,858 in the paper.
- (DEVIATION: line) yh_data.csv (2 GB) read with data.table::fread(select=) restricted to the 20 columns needed, to fit the sandbox's 4 GB / 300 s limits

Agent notes: Two exploratory runs (no RESULT lines) checked coding and counts. They showed that the file holds matched t-1/t pairs, and that age<80 reproduces the paper's N exactly. The single scored run (final) estimates all 13 quantities: the hire indicator (x100) covers non-employment->employment, or employed in both months with a changed employer (PUIODP1==2), with self-employment (COW 6,7) not counted; weights are the average of the two months' weights; the state unemployment rate is for month t; demographic FE are sex x white x Hispanic x 7 education groups; SEs are clustered by state. Claimed values were visible in the task, but no comparison-driven change was made after the scored run, so there are no claim attempts. Gaps that remain: experienced preferred 0.055 vs 0.0496, aggregate with month-year FE -0.0286 vs -0.0326, wage N larger than the paper's.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,491 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T090910Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 965 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T090910Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 276 bytes, from `benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/independent/2026-11-02-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 2,050 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T090910Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T090910Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 5,047 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T090910Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,182 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T090910Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T090910Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,982 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T090910Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,750 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T090910Z/reproduction.json`
- [`output/script.R`](output/script.R) — 7,336 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T090910Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 147 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T090910Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,848 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T090910Z/stdout.txt`
