# saccardo-2023-demand-moral-commitment · blind · claude-code · 2026-11-10-c

| | |
|---|---|
| Paper | `saccardo-2023-demand-moral-commitment` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-10-c |
| Date | 2026-11-10T11:27:30Z |
| Data access | manual (package downloaded by hand and placed on disk) |
| Results file | `benchmark/results/claude-code-run3-1paper-saccardo-indep-blind-2026-11-10.json` |
| Artifacts | `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112916Z` |
| Run directory | `benchmark/reproductions/saccardo-2023-demand-moral-commitment/blind/2026-11-10-c` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/13 |
| First scored | 12/13 (execution 3) |
| Final | **12/13** |
| Package files withheld | 4 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `see_incentive_first_costly_table2_col1` | -0.139 (0.018) | -0.139346 | 0.25% | ±0.018 (se_band) | PASS | PASS |
| `assess_quality_first_costly_table2_col1` | 0.152 (0.029) | 0.151734 | 0.17% | ±0.029 (se_band) | PASS | PASS |
| `choice_free_professionals_table2_col1` | -0.095 (0.026) | -0.021749 | 77.11% | ±0.026 (se_band) | FAIL | FAIL |
| `selfishness_table2_col2` | 0.028 (0.007) | 0.028195 | 0.70% | ±0.007 (se_band) | PASS | PASS |
| `selfishness_table2_col3` | 0.039 (0.009) | 0.039165 | 0.42% | ±0.009 (se_band) | PASS | PASS |
| `see_incentive_first_costly_x_selfishness_table2_col3` | -0.022 (0.016) | -0.022393 | 1.79% | ±0.016 (se_band) | PASS | PASS |
| `see_quality_first_costly_x_selfishness_table2_col3` | -0.021 (0.018) | -0.02114 | 0.67% | ±0.018 (se_band) | PASS | PASS |
| `n_obs_table2_col1` | 5908 | 5908 | 0.00% | ±295.4 (relative) | PASS | PASS |
| `n_obs_table2_cols2_3` | 5196 | 5196 | 0.00% | ±259.8 (relative) | PASS | PASS |
| `prefer_see_incentive_first_assigned_table3_col1` | 0.195 (0.016) | 0.195751 | 0.39% | ±0.016 (se_band) | PASS | PASS |
| `prefer_see_incentive_first_not_assigned_table3_col2` | 0.003 (0.029) | 0.002286 | 23.80% | ±0.029 (se_band) | PASS | PASS |
| `prefer_see_incentive_first_x_not_assigned_table3_col3` | -0.14 (0.026) | -0.140367 | 0.26% | ±0.026 (se_band) | PASS | PASS |
| `n_obs_table3_col1` | 4448 | 4448 | 0.00% | ±222.4 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/13 pass, which agrees with the row's 12/13.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Selfishness uses the dataset's prebuilt stdalpha (alphavaluefinal standardized over all advisors with a consistent MPL, incl. High Stakes rows) rather than re-standardizing within the estimation sample; the two mean/sd differ only in the 3rd decimal.
- (reproduction.json) 'Whether incentives were probabilistic' is coded with probabilistic_incentive (1 for professionals and the AMT wave-2 probabilistic subsample); 'position of products' with incentiveleft; their interaction as the product. The professionals wave dummy is collinear with the Professionals indicator and is dropped by lm.

Agent notes: Data: Data/Clean Data/choice_experiments.dta only. Sample = four main Choice treatments: dropped High Stakes x10/x100 rows; AMT advisors kept only with non-missing MPL moral-cost measure (consistent responders, the paper's preregistered exclusion); all 712 professionals kept. This reproduces Table 1's Ns exactly (712/2574/1562/1067 = 5915); 7 rows drop for missing age in regressions (N=5908; AMT-only 5196). OLS LPMs with controls female, age, wave dummies (AMT-1 base), probabilistic incentive, incentive-on-left, and their interaction; HC3 SEs via sandwich. Table 2: DV choicebefore (prefer to see incentive first). Table 3: DV recommendincentive; col1 getyourchoice==1, col2 getyourchoice==0, col3 pooled with notgetyourchoice and its interactions with preference and noconflict. Attempts 1-2 were exploratory (variable listing, sample cross-tabs), no RESULT lines. One final scored run; no error repairs, no claim comparisons.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 27,301 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112916Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 868 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112916Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 274 bytes, from `benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/blind/2026-11-10-c/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 679 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112916Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112916Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 10,394 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112916Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 257 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112916Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,344 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112916Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112916Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 3,650 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112916Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 257 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112916Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,065 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112916Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,616 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112916Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112916Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 7,447 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112916Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 257 bytes, from `benchmark/results/artifacts/saccardo-2023-demand-moral-commitment/blind/claude-code/20261110T112916Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
