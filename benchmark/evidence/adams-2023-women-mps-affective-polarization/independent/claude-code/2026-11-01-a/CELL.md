# adams-2023-women-mps-affective-polarization · independent · claude-code · 2026-11-01-a

| | |
|---|---|
| Paper | `adams-2023-women-mps-affective-polarization` |
| Mode | independent |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-01-a |
| Date | 2026-11-02T04:29:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-13papers-indep-blind-2026-11-01.json` |
| Artifacts | `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T043820Z` |
| Run directory | `benchmark/reproductions/adams-2023-women-mps-affective-polarization/independent/2026-11-01-a` |
| Executions | 4 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/11 |
| First scored | 11/11 (execution 4) |
| Final | **11/11** |
| Package files withheld | 1 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `women_mps_coef_bivariate` | 1.89 (0.43) | 1.8873 | 0.14% | ±0.43 (se_band) | PASS | PASS |
| `women_mps_coef_full` | 1.73 (0.52) | 1.7256 | 0.25% | ±0.52 (se_band) | PASS | PASS |
| `women_mps_coef_women_partisans` | 2.1 (0.53) | 2.0967 | 0.16% | ±0.53 (se_band) | PASS | PASS |
| `women_mps_coef_men_partisans` | 1.13 (0.5) | 1.131 | 0.09% | ±0.5 (se_band) | PASS | PASS |
| `right_left_distance_coef_full` | -0.6 (0.09) | -0.592 | 1.33% | ±0.09 (se_band) | PASS | PASS |
| `coalition_partners_coef_full` | 0.94 (0.25) | 0.9431 | 0.33% | ±0.25 (se_band) | PASS | PASS |
| `opposition_partners_coef_full` | 0.37 (0.11) | 0.3707 | 0.19% | ±0.11 (se_band) | PASS | PASS |
| `n_directed_dyads` | 1842 | 1842 | 0.00% | ±92.1 (relative) | PASS | PASS |
| `n_obs_women_partisans` | 1836 | 1836 | 0.00% | ±91.8 (relative) | PASS | PASS |
| `n_obs_men_partisans` | 1833 | 1833 | 0.00% | ±91.65 (relative) | PASS | PASS |
| `n_election_studies` | 81 | 81 | 0.00% | ±4.05 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 11/11 pass, which agrees with the row's 11/11.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Sample restriction implemented as out-party (to-party) prior lower-house seats >= 4 (to_prior_seats), which yields exactly the paper's 1,842 dyads; applying the >=4 filter to both parties gives 1,535. US rows coded 999 seats are kept (major parties).
- (reproduction.json) Coalition/opposition-partner dummies use prior_coalition / prior_opposition (codebook lists these as used in the analysis), not govern_together / opposition_together.
- (reproduction.json) Left-right distance (CMP rile_distance) standardized over the estimation sample (mean 22.5, SD 17.5 vs paper's 22.4 / 17.6).
- (reproduction.json) Gender-specific DV computed as 10 - dislike from gender_disagregated_8-8-21.rds (gender 2 = women, 1 = men).

Agent notes: Three exploratory runs (no RESULT lines) inspected variables and sample filters. Final: fixest OLS with country-year (cntryyr) fixed effects, SEs clustered by cntryyr. All coefficients and Ns match Table 1 at reported precision (1.89, 1.73, 2.10, 1.13, -0.59, 0.94, 0.37; N 1842/1836/1833; 81 elections). Clustered SEs are somewhat smaller than published (e.g. 0.36 vs 0.43 on the bivariate coefficient); SEs are not among the claims. Codebook .docx files and readme.rtf in the mount were read as data documentation; no script files were opened.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,017 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T043820Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 1,143 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T043820Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 285 bytes, from `benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/independent/2026-11-01-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 712 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T043820Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T043820Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 19,203 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T043820Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 1,782 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T043820Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T043820Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,567 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T043820Z/attempt-2/stdout.txt`
- [`output/attempt-3/script.R`](output/attempt-3/script.R) — 1,160 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T043820Z/attempt-3/script.R`
- [`output/attempt-3/stderr.txt`](output/attempt-3/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T043820Z/attempt-3/stderr.txt`
- [`output/attempt-3/stdout.txt`](output/attempt-3/stdout.txt) — 838 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T043820Z/attempt-3/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 1,840 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T043820Z/reproduction.json`
- [`output/script.R`](output/script.R) — 2,824 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T043820Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T043820Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 2,006 bytes, from `benchmark/results/artifacts/adams-2023-women-mps-affective-polarization/independent/claude-code/20261102T043820Z/stdout.txt`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
