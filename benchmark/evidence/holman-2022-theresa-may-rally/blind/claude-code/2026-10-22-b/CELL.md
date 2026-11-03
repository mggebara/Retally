# holman-2022-theresa-may-rally · blind · claude-code · 2026-10-22-b

| | |
|---|---|
| Paper | `holman-2022-theresa-may-rally` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-10-22-b |
| Date | 2026-10-22T03:30:01Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-blind-rerun-2026-10-22-b.json` |
| Artifacts | `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T033040Z` |
| Run directory | `benchmark/reproductions/holman-2022-theresa-may-rally/blind/2026-10-22-b` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 5/11 (execution 3) |
| Final | **6/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `intl_attack_table4` | 3.112 (0.875) | 2.21565 | 28.80% | ±0.875 (se_band) | FAIL | FAIL |
| `intl_attack_x_woman_exec_table4` | -4.333 (1.859) | -2.95667 | 31.76% | ±1.859 (se_band) | PASS | PASS |
| `n_obs_table4` | 4328 | 4486 | 3.65% | ±216.4 (relative) | PASS | FAIL |
| `did_attack_x_time_like_may_table2` | -0.1274 (0.0187) | -0.099607 | 21.82% | ±0.0187 (se_band) | FAIL | FAIL |
| `did_attack_like_may_table2` | 0.0178 (0.0278) | 0.008807 | 50.52% | ±0.0278 (se_band) | PASS | PASS |
| `did_time_like_may_table2` | -0.5007 (0.0229) | -0.451291 | 9.87% | ±0.0229 (se_band) | FAIL | FAIL |
| `did_attack_x_time_may_best_pm_table2` | -0.0501 (0.0044) | -0.321537 | 541.79% | ±0.0044 (se_band) | FAIL | FAIL |
| `did_attack_may_best_pm_table2` | -0.0002 (0.004) | -0.002315 | 1057.50% | ±0.004 (se_band) | PASS | PASS |
| `did_time_may_best_pm_table2` | 0.2098 (0.0036) | 1.36411 | 550.20% | ±0.004196 (relative) | FAIL | FAIL |
| `n_obs_did_like_may_table2` | 143499 | 143499 | 0.00% | ±7174.95 (relative) | PASS | PASS |
| `n_obs_did_may_best_pm_table2` | 97155 | 97155 | 0.00% | ±4857.75 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 6/11 pass, which agrees with the row's 6/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Table 4: global_approval.dta has 44 countries (paper says 66); used as provided. DV is `lag_approval`, which is missing in the last quarter of every panel and so is the next-quarter (lead) approval aligned to quarter t; regressed on contemporaneous kill_16 (16+ deaths = more than 15; 60 attack quarters, 9 under women in the full file, 50 / 9 in the estimation sample).
- (reproduction.json) Table 4: 'GDP' control is the `growth` variable as provided (values look like GDP levels); election control is election_qtr (the only election variable); execrlc (DPI left/center/right, 0 = no information) entered as categories; OLS with country dummies. Panel-corrected SEs do not affect point estimates and were not needed (the informational PCSE block returned NULL and printed nothing).
- (reproduction.json) Table 2: OLS (likeability) and logit (best PM, log-odds coefficients, as the table note says) with wave dummies entered after `time`; the collinear last wave dummy is dropped (wave 16 for likeability, wave 12 for best PM), so `time` is identified relative to that convention. Controls white, gender, labour, party_other, income, ideology2 (midpoint-recoded ideology); listwise deletion; no survey weights. Restricting to wave-12 participants gives identical samples and estimates.

Agent notes: Independent blind reproduction from paper text and data files only. Two exploratory runs (variable inspection; no RESULT lines), then one final run. The paper text had the target values withheld; no author scripts or result files were opened. The Readme .docx and metadata.json in the data directory were read for documentation only. Table 4 R2 from lm with dummies (0.27) differs from the R2 printed in the paper's Table 4; this was not used to change the specification.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,435 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T033040Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,061 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T033040Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 257 bytes, from `benchmark/.cache/claude-code/holman-2022-theresa-may-rally/blind/2026-10-22-b/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 1,117 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T033040Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T033040Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 16,353 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T033040Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 2,489 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T033040Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T033040Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 12,903 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T033040Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,276 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T033040Z/reproduction.json`
- [`output/script.R`](output/script.R) — 6,400 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T033040Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T033040Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,453 bytes, from `benchmark/results/artifacts/holman-2022-theresa-may-rally/blind/claude-code/20261022T033040Z/stdout.txt`
