# forsythe-2022-young-workers-recessions · independent · claude-code · 2026-11-02-c

| | |
|---|---|
| Paper | `forsythe-2022-young-workers-recessions` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-02-c |
| Date | 2026-11-02T20:14:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run3-23papers-indep-blind-2026-11-02.json` |
| Artifacts | `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T202751Z` |
| Run directory | `benchmark/reproductions/forsythe-2022-young-workers-recessions/independent/2026-11-02-c` |
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
| `wage_young_x_unemp_rate_all_hires` | -0.0262 (0.0036) | -0.024277 | 7.34% | ±0.0036 (se_band) | PASS | PASS |
| `wage_experienced_x_unemp_rate_all_hires` | -0.0116 (0.00348) | -0.010661 | 8.09% | ±0.00348 (se_band) | PASS | PASS |
| `n_obs_full_sample` | 1.69485e+07 | 1.69485e+07 | 0.00% | ±847426 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 13/13 pass, which agrees with the row's 13/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) yh_data.csv (about 2 GB) is read with data.table::fread(select=) keeping only the needed columns, to fit the 4 GB / 300 s sandbox.
- (reproduction.json) Hiring regressions are estimated on weighted cell means (state x month-year x demographic cell x young x prior-month status x unemployment rate), weights = summed CPS weights; WLS point estimates are identical to the person-level regression, and N is the sum of cell counts.
- (reproduction.json) The supplied LAUS state unemployment file ends in May 2014, so the matched sample effectively ends there; dropping pairs without a state unemployment rate plus restricting to age < 80 reproduces the paper's N = 16,948,516 exactly.
- (reproduction.json) Years of education from peeduca: <1st grade 0, 1-4 2.5, 5-6 5.5, 7-8 7.5, 9th 9, 10th 10, 11th 11, 12th no diploma 12, HS 12, some college 13, associate 14, BA 16, MA 18, professional 20, PhD 20 (mapping not given in the paper).
- (reproduction.json) Industry/occupation codes mapped to 2002 Census codes with the supplied crosswalks, assuming code vintages by survey year (industry: 1990 codes to 2002, 2002 codes 2003-2008, 2007 codes 2009-2013, 2012 codes 2014+; occupation: 1990 to 2002, 2002 codes 2003-2010, 2010 codes 2011+); 12 unmatched industry codes kept as their own FE levels.
- (reproduction.json) Wage sample: hires with positive weekly earnings (v2prernwa) and earnings allocation flag v2prwernal == 0; this gives 120,306 observations versus 112,858 in the paper.
- (DEVIATION: line) yh_data.csv (2 GB) read with data.table::fread(select=) for only the needed columns, to fit the sandbox memory/time limits

Agent notes: Two exploratory runs (attempt-1: variable inspection and read timing; attempt-2: sample-count checks, killed by the 4 GB memory cap at exit 137 after printing the counts). The final run estimates all 13 quantities in one script: hired = 100 if employed in month t (pemlr 1-2), not self-employed (class of worker 6/7), and either non-employed in t-1 or employed in t-1 and reporting a different employer (v2puiodp1 == 2); young = potential experience (age - years of education - 6) <= 10; weights are the average of the two months' CPS weights; state, demographic (sex x white x Hispanic x 7 education levels) and month-year (month t) FEs; SEs clustered by state. Afterwards, check_attempt reported every claim within tolerance, and the script was not changed. The final run's own timer showed 314 s, mostly the 280 s CSV read (the first exploratory read took 89 s). The 300 s perl alarm wrapper did not fire, and the container exited 0. No docker run hung.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,968 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T202751Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 965 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T202751Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 276 bytes, from `benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/independent/2026-11-02-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,703 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T202751Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T202751Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,073 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T202751Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,132 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T202751Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T202751Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 2,346 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T202751Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,929 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T202751Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,921 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T202751Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T202751Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,225 bytes, from `benchmark/results/artifacts/forsythe-2022-young-workers-recessions/independent/claude-code/20261102T202751Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
