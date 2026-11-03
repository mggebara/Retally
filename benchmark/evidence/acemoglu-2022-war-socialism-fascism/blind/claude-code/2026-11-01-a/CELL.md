# acemoglu-2022-war-socialism-fascism · blind · claude-code · 2026-11-01-a

| | |
|---|---|
| Paper | `acemoglu-2022-war-socialism-fascism` |
| Mode | blind |
| Reproducer | claude-code |
| Model | — |
| Run | 2026-11-01-a |
| Date | 2026-11-02T04:25:00Z |
| Data access | public |
| Results file | `benchmark/results/claude-code-run2-13papers-indep-blind-2026-11-01.json` |
| Artifacts | `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261102T043821Z` |
| Run directory | `benchmark/reproductions/acemoglu-2022-war-socialism-fascism/blind/2026-11-01-a` |
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

- (reproduction.json) Standardized coefficients computed by z-scoring the outcome, endogenous regressor, instrument and controls within each regression's estimation sample (for the 1921 vote share, within the 5,358-municipality 1921 sample).
- (reproduction.json) First-stage F-statistic for Table I col (6) computed as the squared district-clustered t-statistic of the casualty coefficient (fixest small-sample corrections, province FE nested in clusters); Stata ivreg2/reghdfe corrections may differ slightly.
- (reproduction.json) Highest-mortality-battles dummy taken to be cruent_d; assault troops + volunteers casualty share taken to be ard_vol_pop6m; regiment FE = all 359 d_reg* dummies; province FE = provincia1921; clusters = circondario1921.

Agent notes: Blind independent reproduction from paper text only (no author code, no result files). attempt-1: exploratory variable listing (no RESULT lines). attempt-2: full estimation with fixest, which by default dropped 3 singleton-province municipalities (N=5772); not an error, but on method grounds (the dataset ships explicit province dummies, implying the authors used dummy-variable province FE, which keeps singletons) the final run keeps all observations (fixef.rm='none'), giving N=5775 / 181 districts for the main sample and 5358 / 175 for the 1921 vote share. Coefficients are identical between attempt-2 and the final run; only N and SEs/F changed marginally. Specification: OLS first stage and 2SLS with fixest::feols, controls per Table I notes (demographic: lpop1911 + lpop2-4 + sh_pop_1911_be6; geographic: larea, centre_alt, max_alt; psu1913_vv; military: veterans74_95, veterans96_00, ard_vol_pop6m, army_suppliers_d, cruent_d; agricultural: dlab, shcrop, landlord_ass; urban: ind_workers, ind_firms, literacy, elites, bourgeoisie), SEs clustered by circondario1921. No paper values were seen or compared.

## What the model was given

- [`prompt/task.md`](prompt/task.md) — 18,410 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261102T043821Z/task.md`
- [`prompt/render.json`](prompt/render.json) — 959 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261102T043821Z/render.json`
- [`prompt/paper.txt.ref`](prompt/paper.txt.ref) — 270 bytes, from `benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/blind/2026-11-01-a/paper.txt`

## What it produced

- [`output/attempt-1/script.R`](output/attempt-1/script.R) — 787 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261102T043821Z/attempt-1/script.R`
- [`output/attempt-1/stderr.txt`](output/attempt-1/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261102T043821Z/attempt-1/stderr.txt`
- [`output/attempt-1/stdout.txt`](output/attempt-1/stdout.txt) — 57,801 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261102T043821Z/attempt-1/stdout.txt`
- [`output/attempt-2/script.R`](output/attempt-2/script.R) — 3,779 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261102T043821Z/attempt-2/script.R`
- [`output/attempt-2/stderr.txt`](output/attempt-2/stderr.txt) — 441 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261102T043821Z/attempt-2/stderr.txt`
- [`output/attempt-2/stdout.txt`](output/attempt-2/stdout.txt) — 1,134 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261102T043821Z/attempt-2/stdout.txt`
- [`output/reproduction.json`](output/reproduction.json) — 2,370 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261102T043821Z/reproduction.json`
- [`output/script.R`](output/script.R) — 3,922 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261102T043821Z/script.R`
- [`output/stderr.txt`](output/stderr.txt) — 0 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261102T043821Z/stderr.txt`
- [`output/stdout.txt`](output/stdout.txt) — 1,135 bytes, from `benchmark/results/artifacts/acemoglu-2022-war-socialism-fascism/blind/claude-code/20261102T043821Z/stdout.txt`
