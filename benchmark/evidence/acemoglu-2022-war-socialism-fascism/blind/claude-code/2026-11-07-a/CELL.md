# acemoglu-2022-war-socialism-fascism · blind · claude-code · 2026-11-07-a

| | |
|---|---|
| Paper | `acemoglu-2022-war-socialism-fascism` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-07-a |
| Date | 2026-11-07T17:40:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run4-24papers-indep-blind-2026-11-08.json` |
| Artifacts | `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261107T194747Z` |
| Run directory | `benchmark/reproductions/acemoglu-2022-war-socialism-fascism/blind/2026-11-07-a` |
| Executions | 3 |
| Refinements | 0 (0 error + 0 claim) |
| First attempt | 0/12 |
| First scored | 12/12 (execution 2) |
| Final | **12/12** |
| Package files withheld | 21 |
| Evidence | complete |

## Claims

| Claim | Ground truth | Reproduced | Rel. err | Band | Verdict | First scored |
|---|---|---|---|---|---|---|
| `first_stage_casualties_table1_col1` | 0.12 (0.02) | 0.118643 | 1.13% | ±0.02 (se_band) | PASS | PASS |
| `first_stage_casualties_table1_col6` | 0.1 (0.01) | 0.097885 | 2.12% | ±0.01 (se_band) | PASS | PASS |
| `first_stage_fstat_table1_col6` | 50.59 | 50.5877 | 0.00% | ±0.5059 (relative) | PASS | PASS |
| `iv_violence_table2_panelA_col6` | 0.5 (0.2) | 0.499883 | 0.02% | ±0.2 (se_band) | PASS | PASS |
| `iv_branches_table2_panelC_col6` | 0.5 (0.2) | 0.498394 | 0.32% | ±0.2 (se_band) | PASS | PASS |
| `iv_fascist_vote1921_table3_panelA_col6` | 0.34 (0.18) | 0.335966 | 1.19% | ±0.18 (se_band) | PASS | PASS |
| `iv_fascist_vote1924_table3_panelC_col1` | 0.4 (0.17) | 0.395648 | 1.09% | ±0.17 (se_band) | PASS | PASS |
| `iv_fascist_vote1924_table3_panelC_col6` | 0.51 (0.17) | 0.5126 | 0.51% | ±0.17 (se_band) | PASS | PASS |
| `n_obs_main_sample` | 5775 | 5775 | 0.00% | ±288.75 (relative) | PASS | PASS |
| `n_clusters_main_sample` | 181 | 181 | 0.00% | ±9.05 (relative) | PASS | PASS |
| `n_obs_fascist_vote1921` | 5358 | 5358 | 0.00% | ±267.9 (relative) | PASS | PASS |
| `n_clusters_fascist_vote1921` | 175 | 175 | 0.00% | ±8.75 (relative) | PASS | PASS |

Re-scored from `output/stdout.txt` with the runner's comparator: 12/12 pass, which agrees with the row's 12/12.

Per-claim ground truth, tolerance rule and errors: [`scoring.json`](scoring.json).

## Deviations declared

- (reproduction.json) Regiment fixed effects = all 359 d_reg* dummies in fascism_db.dta (any death from the municipality in that unit), including non-infantry units (artillery, alpini, bersaglieri, genio, navy, etc.); the paper does not list which units enter.
- (reproduction.json) Standardized coefficients: dependent variable, socialist 1919 share, instrument and continuous controls are z-scored within each estimation sample; regiment dummies left as 0/1 (does not affect the reported coefficients).
- (reproduction.json) First-stage F reported as the squared district-clustered t-statistic on the instrument in the full-controls first stage (fixest default small-sample adjustments; province FE nested in districts not counted in K). Exact F depends on the authors' small-sample corrections, which are unknown.
- (reproduction.json) Controls mapped to dataset variables: demographic = lpop1911, lpop2-4, sh_pop_1911_be6; geographic = larea, centre_alt, max_alt; psu1913_vv; military = veterans74_95, veterans96_00, ard_vol_pop6m, army_suppliers_d, cruent_d; agricultural = dlab, shcrop, landlord_ass; urban = ind_workers, ind_firms, literacy, elites, bourgeoisie. Province FE from provincia1921, clusters circondario1921.

Agent notes: Estimated with fixest feols (OLS first stage; 2SLS with foots_pop6m instrumenting psu1919_vv), province FE absorbed, SEs clustered by district (circondario1921). attempt-1 was an exploratory variable listing (no RESULT lines). attempt-2 was the first full estimation; fixest's default removed 3 singleton-province observations (4 in the 1921 sample). Because the paper's municipality sample is the full dataset and singletons are an fixest default, not part of the paper's method, the final run keeps them (fixef.rm = 'none'). That changed only the observation counts and, slightly, the F-statistic; the coefficients were unchanged. This was a judgment about method, not a comparison to the paper's values (none were seen). The main sample has 5775 municipalities in 181 districts. The 1921 sample is the 5358 rows with non-missing fascist1921_vv, in 175 districts. No Docker hangs.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 19,162 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261107T194747Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 959 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261107T194747Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 283 bytes, from `benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/blind/2026-11-07-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 755 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261107T194747Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 314 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261107T194747Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 60,337 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261107T194747Z/attempt-1/stdout.txt`
- [`output/attempt-1/timing.json`](output/attempt-1/timing.json) — 255 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261107T194747Z/attempt-1/timing.json`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,656 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261107T194747Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 441 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261107T194747Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,481 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261107T194747Z/attempt-2/stdout.txt`
- [`output/attempt-2/timing.json`](output/attempt-2/timing.json) — 256 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261107T194747Z/attempt-2/timing.json`
- [`output/reproduction.json`](output/reproduction.json) — 2,597 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261107T194747Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,694 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261107T194747Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261107T194747Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,480 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261107T194747Z/stdout.txt`
- [`output/timing.json`](output/timing.json) — 256 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261107T194747Z/timing.json`

## Executions

Execution metadata not recorded (the agent harness does not write `execution.json`).
