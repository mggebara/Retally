# holman-2022-theresa-may-rally · independent · claude-code · 2026-11-01-a

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-01-a |
| Date | 2026-11-02T04:38:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-13papers-indep-blind-2026-11-01.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z` |
| Run directory | `benchmark/reproductions/holman-2022-theresa-may-rally/independent/2026-11-01-a` |
| Executions | 9 |
| Refinements | 3 (1 error + 2 claim) |
| First attempt | 0/11 |
| First scored | 6/11 (execution 6) |
| Final | **11/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `intl_attack_table4` | 3.112 (0.875) | 2.32209 | 25.38% | ±0.875 (se_band) | PASS | FAIL |
| `intl_attack_x_woman_exec_table4` | -4.333 (1.859) | -3.82839 | 11.65% | ±1.859 (se_band) | PASS | PASS |
| `n_obs_table4` | 4328 | 4486 | 3.65% | ±216.4 (relative) | PASS | FAIL |
| `did_attack_x_time_like_may_table2` | -0.1274 (0.0187) | -0.127429 | 0.02% | ±0.0187 (se_band) | PASS | FAIL |
| `did_attack_like_may_table2` | 0.0178 (0.0278) | 0.017777 | 0.13% | ±0.0278 (se_band) | PASS | PASS |
| `did_time_like_may_table2` | -0.5007 (0.0229) | -0.500722 | 0.00% | ±0.0229 (se_band) | PASS | FAIL |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | -0.050098 | 0.00% | ±0.0044 (se_band) | PASS | PASS |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | -0.000164 | 18.00% | ±0.004 (se_band) | PASS | PASS |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | 0.20976 | 0.02% | ±0.004196 (relative) | PASS | FAIL |
| `n_obs_did_like_may_table2` | 143499 | 143499 | 0.00% | ±7174.95 (relative) | PASS | PASS |
| `n_obs_did_may_best_pm_table2` | 97155 | 97155 | 0.00% | ±4857.75 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Table 2 May best PM column estimated as a linear probability model (random-effects GLS), not the logit the table note describes; the published coefficients/SEs/constant are on the linear-probability scale.
- (reproduction.json) Table 2 estimated as respondent random-effects GLS (Swamy-Arora, plm), i.e. Stata xtreg's default, with explicit wave dummies; time is collinear with the wave dummies, so the last wave dummy is dropped.
- (reproduction.json) Table 4: DV is the dataset's only approval measure (lag_approval) regressed on the contemporaneous kill_16 (16+ deaths) indicator; execrlc entered linearly; country_code fixed effects via OLS. The sample is all complete cases (N=4486); the paper's N=4328 could not be reconstructed (growth-rate, lead/lag timing and AR(1)-trimming variants were counted in exploratory runs and none gives 4328). Point estimates are OLS-LSDV; Beck-Katz panel-corrected SEs (plm vcovBK) are printed but not scored, and no AR(1) correction was applied.
- (DEVIATION: line) Table 2 May best PM column estimated as a linear probability model (random-effects GLS), not logit
- (DEVIATION: line) Table 4 approval timing uses the dataset's lag_approval with the contemporaneous kill_16 indicator

Agent notes: Exploratory runs (attempts 1-5) inspected variables and counted complete cases only. In the DiD, controls white+gender+labour+party_other+income+ideology2 give exactly N=143,499 / 97,155. Attempt 6 (pooled OLS DiD; factor execrlc in Table 4) was compared with the claims; Table 4 then moved to linear execrlc and the DiD treatment to post_attack (estimates identical to treatment1 in these samples). Attempt 7 crashed because plm masked dplyr::lead; fixed. Attempt 8 was compared; the DiD then moved from pooled OLS to random-effects GLS, which reproduces all Table 2 coefficients, constants and SEs exactly. Table 4: both coefficients are within tolerance (2.32 vs 3.11, -3.83 vs -4.33), but N (4486 vs 4328) and R2 (0.27 vs 0.58) differ, so the paper's exact Table 4 sample/estimator (likely xtpcse, possibly with AR(1)) was not recovered. The dataset Readme (.docx, a documentation file inside the mount) was read; no script files were opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 17,878 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,093 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 257 bytes, from `benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-01-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 908 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 14,126 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,041 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 10,262 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 2,313 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 2,512 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-3/stdout.txt`
- [`output/attempt-4/script.R`](output/attempt-4/script.R) — 1,137 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-4/script.R`
- [`output/attempt-4/stderr.txt`](output/attempt-4/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-4/stderr.txt`
- [`output/attempt-4/stdout.txt`](output/attempt-4/stdout.txt) — 4,132 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-4/stdout.txt`
- [`output/attempt-5/script.R`](output/attempt-5/script.R) — 1,237 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-5/script.R`
- [`output/attempt-5/stderr.txt`](output/attempt-5/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-5/stderr.txt`
- [`output/attempt-5/stdout.txt`](output/attempt-5/stdout.txt) — 904 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-5/stdout.txt`
- [`output/attempt-6/feedback.txt`](output/attempt-6/feedback.txt) — 432 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-6/feedback.txt`
- [`output/attempt-6/script.R`](output/attempt-6/script.R) — 4,020 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-6/script.R`
- [`output/attempt-6/stderr.txt`](output/attempt-6/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-6/stderr.txt`
- [`output/attempt-6/stdout.txt`](output/attempt-6/stdout.txt) — 1,917 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-6/stdout.txt`
- [`output/attempt-7/feedback.txt`](output/attempt-7/feedback.txt) — 258 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-7/feedback.txt`
- [`output/attempt-7/script.R`](output/attempt-7/script.R) — 5,632 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-7/script.R`
- [`output/attempt-7/stderr.txt`](output/attempt-7/stderr.txt) — 988 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-7/stderr.txt`
- [`output/attempt-7/stdout.txt`](output/attempt-7/stdout.txt) — 1,219 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-7/stdout.txt`
- [`output/attempt-8/feedback.txt`](output/attempt-8/feedback.txt) — 345 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-8/feedback.txt`
- [`output/attempt-8/script.R`](output/attempt-8/script.R) — 5,674 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-8/script.R`
- [`output/attempt-8/stderr.txt`](output/attempt-8/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-8/stderr.txt`
- [`output/attempt-8/stdout.txt`](output/attempt-8/stdout.txt) — 2,890 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/attempt-8/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,795 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,381 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,814 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/independent/claude-code/20261102T043820Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
