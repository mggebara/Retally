# holman-2022-theresa-may-rally · blind · claude-code · 2026-10-22-a

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-22-a |
| Date | 2026-10-22T03:21:35Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-6papers-all-modes-2026-10-22.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T032229Z` |
| Run directory | `benchmark/reproductions/holman-2022-theresa-may-rally/blind/2026-10-22-a` |
| Executions | 4 |
| Refinements | 1 (1 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 6/11 (execution 4) |
| Final | **7/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `intl_attack_table4` | 3.112 (0.875) | 2.32209 | 25.38% | ±0.875 (se_band) | PASS | PASS |
| `intl_attack_x_woman_exec_table4` | -4.333 (1.859) | -3.82839 | 11.65% | ±1.859 (se_band) | PASS | PASS |
| `n_obs_table4` | 4328 | 4486 | 3.65% | ±216.4 (relative) | PASS | FAIL |
| `did_attack_x_time_like_may_table2` | -0.1274 (0.0187) | -0.0996072 | 21.82% | ±0.0187 (se_band) | FAIL | FAIL |
| `did_attack_like_may_table2` | 0.0178 (0.0278) | 0.00880729 | 50.52% | ±0.0278 (se_band) | PASS | PASS |
| `did_time_like_may_table2` | -0.5007 (0.0229) | -0.451291 | 9.87% | ±0.0229 (se_band) | FAIL | FAIL |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | -0.321537 | 541.79% | ±0.0044 (se_band) | FAIL | FAIL |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | -0.00231452 | 1057.26% | ±0.004 (se_band) | PASS | PASS |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | 1.36411 | 550.20% | ±0.004196 (relative) | FAIL | FAIL |
| `n_obs_did_like_may_table2` | 143499 | 143499 | 0.00% | ±7174.95 (relative) | PASS | PASS |
| `n_obs_did_may_best_pm_table2` | 97155 | 97155 | 0.00% | ±4857.75 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 7/11 pass, which agrees with the row's 7/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Table 4: coefficients are from OLS with country (country_code) dummies; panel-corrected SEs are computed by hand (Beck-Katz, casewise) since no PCSE package is installed. Coefficients do not depend on the SE method. No AR(1)/Prais-Winsten correction was applied because the paper does not mention one.
- (reproduction.json) Table 4: DV is lag_approval (the only approval variable, labelled 'Lagged approval'); attack indicator is kill_16 (international attack with 16+ deaths, i.e. more than 15; exactly 60 country-quarters, 9 under women executives as the paper states); execrlc entered linearly; 'growth' is used as stored (it is a real-GDP level series). The estimation sample has 44 country-office units, not the 66 the paper mentions (country_code takes only 44 distinct values in the data).
- (reproduction.json) Table 2: all waves with a non-missing outcome are used (like May: waves 9-16; best PM: waves 7, 8, 10, 11, 12); likeMayW code 9999 (don't know) set to missing; outcome for best PM is bestPMW (1 = May, 0 = Corbyn), logit; controls white, gender, labour, party_other, income, ideology2 (ideology with missing coded to the scale midpoint); no survey weights. time is perfectly collinear with the wave dummies, so time is entered before them and the last wave dummy (16 for like May, 12 for best PM) is dropped; the reported Time coefficient depends on this choice.

Agent notes: Independent blind reproduction from the paper text and data files only (the readme .docx in the mount was read for file descriptions; replication_files.do is listed in metadata.json but is not in the mount and was not read). attempt-1 and attempt-2 were exploratory (variable inventories, codings, missingness); attempt-3 crashed in the hand-rolled PCSE step (singular X'X because GDP is on a ~1e7 scale) and was fixed by inverting via QR. Caveats: the Table 4 regression's R2 (0.268) is well below the R2 printed in the paper's Table 4 note, and the interaction is not significant under our PCSE (the paper says it is significant at 5%), so the paper's Table 4 specification probably differs in some way the text does not describe (e.g. sample, an xtpcse option, or variable construction). Per blind rules the specification was not adjusted toward any reported figure.

Files read outside the mount: `<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/blind/2026-10-22-a/task.md (task instructions, as directed by the user)`

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,435 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T032229Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,061 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T032229Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 257 bytes, from `benchmark/.cache/claude-code/holman-2022-theresa-may-rally/blind/2026-10-22-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,211 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T032229Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T032229Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 7,380 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T032229Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,269 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T032229Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T032229Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 7,594 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T032229Z/attempt-2/stdout.txt`
- [`output/attempt-3/feedback.txt`](output/attempt-3/feedback.txt) — 411 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T032229Z/attempt-3/feedback.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 4,462 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T032229Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 166 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T032229Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 621 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T032229Z/attempt-3/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,974 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T032229Z/reproduction.json`
- [`output/script.R`](output/script.R) — 4,633 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T032229Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T032229Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 3,460 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T032229Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
