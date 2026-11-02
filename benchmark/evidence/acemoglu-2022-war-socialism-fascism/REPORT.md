# Evidence report: acemoglu-2022-war-socialism-fascism

**War, Socialism, and the Rise of Fascism: an Empirical Exploration** — Daron Acemoglu, Giuseppe De Feo, Giacomo Davide De Luca, Gianluca Russo

- Paper: https://economics.mit.edu/sites/default/files/2023-01/War%2C%20Socialism%20and%20the%20Rise%20of%20Facism%20-%20An%20Empirical%20Exploration.pdf
- I4R report: https://doi.org/10.48152/ssrp-3s2g-m694
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/acemoglu-2022-war-socialism-fascism.yaml`

> Headline finding: across 5,775 Italian municipalities, World War I foot soldier casualties (relative to the 1911 male population over six) raised the Socialist vote share in 1919 (first stage, Table I: standardized 0.12 (0.02) with basic controls, 0.10 (0.01) with all, F = 41.68 to 50.59); instrumenting the 1919 socialist share with casualties, the socialist surge raised fascist violence in 1920-22 and the presence of fascist branches in 1921 (Table II Panels A and C, 0.38 to 0.53) and the fascist vote share in 1921 (Table III Panel A, 0.30 to 0.37, N = 5,358, 175 clusters) and 1924 (Panel C, 0.40 to 0.54) — the "red scare" mechanism.  OLS panels are near zero for the vote shares. 181 district clusters in the main sample.
> Original analysis in Stata (ivreg2, outreg2); two appendix tables in R. language: r is the reproduction target.
> Curation pass (2026-10-21).  Pinned 12 claims from Tables I-III — the three tables the I4R team covered: two first-stage coefficients and the column (6) first-stage F, five 2SLS coefficients (each with its SE in standard_error), and the observation and cluster counts of the two samples.  Values exactly as printed in the published QJE article (two decimals throughout, so the printed-precision floor is +-0.005 on every coefficient and SE).  The paper has no separate reduced-form table for these outcomes; the first stage (Table I) and 2SLS panels are the headline estimates.  The intro text quotes the Table I col 1 and Table III Panel A col 6 estimates, so blind-mode redaction of "0.12", "0.10", "0.50", "0.34" etc. will also hit unrelated numbers in other tables (harmless over-redaction).
> Working paper vs published.  The candidate list named NBER WP 27854 (September 2020); its tables differ from the published ones in numbering AND values, so the published typeset article was used as paper.source.  WP Table 1 (first stage) reports UNSTANDARDIZED coefficients at three decimals (2.034 (0.315) ... 1.689 (0.234)) and older control sets (F 41.68 / 42.27 / 56.37 / 57.55 / 53.96 / 52.18, R-squared 0.599-0.697); the published Table I reports standardized coefficients at two decimals, adds an assault-troop/volunteer casualty row and an army-supplier dummy to the military controls, and has F 41.68 / 42.29 / 56.39 / 55.24 / 51.69 / 50.59.  WP Table 2 is the falsification table (published elsewhere); WP Table 3 is the 2SLS on the 1924 fascist vote share only (unstandardized, 0.375-0.504; no 1921 panel), which became published Table III Panels C-D (with the new 1921 Panels A-B); WP Table 4 (violence and branches, unstandardized: violence 0.230-0.329, branches 0.507-0.672) became published Table II.  The meta-database's o_coeff values (three decimals, e.g. 0.119, 0.098, 0.533, 0.513) are the published standardized estimates, not WP values. A November 2021 author draft (MIT, 77 pp.) also exists; not used.
> What was read.  The published QJE PDF (data section, Section IV, Tables I-III with notes, footnotes 12-14); NBER WP 27854 (Tables 1-4, for the comparison above); the Dataverse API metadata and version list; the whole package (all do-files, both R scripts' headers, the .ado headers); the meta-database's 64 rows for the paper (team 104).  The SSRP record (doi:10.48152/ssrp-3s2g-m694 -> socialsciencereproduction.org /reproductions/790) could not be read: the host does not resolve (2026-10-21).
> Independent cross-check (not the package code; numpy on the package's fascism_db.dta, mimicking Tables1-7.do): every pinned number reproduces. Table I: 0.1186 (0.0184), 0.1140 (0.0175), 0.1034 (0.0138), 0.1015 (0.0136), 0.0976 (0.0136), 0.0979 (0.0138); F = t^2 = 41.68 / 42.29 / 56.39 / 55.24 / 51.69 / 50.59 exactly; N 5,775, 181 clusters.  2SLS (SEs without small-sample adjustment, ivreg2's default; multiplying by sqrt(G/(G-1)) moves them by ~0.3 %): Table II Panel A 0.3793 (0.1854), 0.3945 (0.1905), 0.4191 (0.2059), 0.5334 (0.2104), 0.5019 (0.2118), 0.4999 (0.2044); Panel C 0.3901 (0.1746), 0.4055 (0.1780), 0.4445 (0.1980), 0.5006 (0.2124), 0.4983 (0.2125), 0.4984 (0.2035); Table III Panel A 0.3049 (0.1658), 0.3287 (0.1620), 0.3691 (0.1830), 0.3632 (0.1915), 0.3565 (0.1971), 0.3369 (0.1842), N 5,358, 175 clusters; Panel C 0.3956 (0.1706), 0.4531 (0.1620), 0.5024 (0.1666), 0.5424 (0.1663), 0.5274 (0.1746), 0.5126 (0.1661).  These equal the database's o_coeff / o_std_err to three decimals.
> How the printed numbers are produced (package-only; never in contexts). Tables1-7.do loads fascism_db.dta and standardizes every variable in the blocks fascist_violence-strike_agr_1920, lpop1911-volunteers1866_pop and rain1918-rain_var with egen std (z_ prefix) over the WHOLE file, not the estimation sample — this matters for the 1921 sample (5,358 of 5,775 rows non-missing).  Controls: spec1 z_lpop1911 z_lpop2-4 z_sh_pop_1911_be6 d_reg* (359 regiment dummies) province* (69 province dummies); spec2 + z_larea z_centre_alt z_max_alt; spec3 + z_psu1913_vv; spec4 + z_veterans74_95 z_veterans96_00 z_ard_vol_pop6m z_cruent_d z_army_suppliers_d; spec5 + z_dlab z_shcrop z_landlord_ass; spec6 + z_ind_workers z_ind_firms z_literacy z_elites z_bourgeoisie.  Table I: reg z_psu1919_vv z_foots_pop6m spec, cl(circondario1921), F from test z_foots_pop6m.  Tables II-III: ivreg2 z_fascist_violence / z_fascist_branch / z_fascist1921_vv / z_fascist1924_vv (z_psu1919_vv = z_foots_pop6m) spec, partial(d_reg* province*) cl(circondario1921) — no small option, so the clustered SEs carry no finite-sample correction (an R reproduction with fixest's default small-sample adjustment will get SEs a few tenths of a percent larger, well inside the printed precision).  outreg2 dec(2) writes TAB_1.tex, TAB_2A-D.tex, TAB_3A-D.tex.  The master file's paths are placeholders (".../replication/data").
> Package facts.  fascism_db.dta (5,775 x 1,336) is all Tables I-VII need; fascism_mod_elections_db.dta (379 MB) feeds only Table VIII and appendix Tables A1 / A22.  x_gmm.ado / x_ols.ado implement Conley spatial SEs for appendix Table A2.  The two R scripts (TabA13FWER.R, Tab_A14.R) build appendix FWER / A14 tables; TabA13FWER.R reads a CSV produced by a do-file and not shipped.  The candidate-list risk "map figures may need geodata" is confirmed but irrelevant: fig1_maps.do needs fascism_map_db.dta and coord_italy*.dta, absent.
> Left out.  OLS panels (Tables II-III Panels B and D; near-zero, printed as 0.00-0.11); columns (2)-(5) of each panel (stable, reported above); Table I's veterans and assault-troop rows (controls, not the claim); Tables IV-VIII (party vote shares, heterogeneity, deportations, post-WWII votes: no I4R rows); appendix tables.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `first_stage_casualties_table1_col1` | 0.12 | 0.02 | Table I, column (1), Share of foot soldier casualties | — | not_attempted |
| 1 | `first_stage_casualties_table1_col6` | 0.1 | 0.01 | Table I, column (6), Share of foot soldier casualties | — | not_attempted |
| 2 | `first_stage_fstat_table1_col6` | 50.59 | — | Table I, column (6), F-stat. | — | — |
| 3 | `iv_violence_table2_panelA_col6` | 0.5 | 0.2 | Table II, Panel A (2SLS), column (6), Socialist vote share in 1919 | — | not_attempted |
| 4 | `iv_branches_table2_panelC_col6` | 0.5 | 0.2 | Table II, Panel C (2SLS), column (6), Socialist vote share in 1919 | — | not_attempted |
| 5 | `iv_fascist_vote1921_table3_panelA_col6` | 0.34 | 0.18 | Table III, Panel A (2SLS), column (6), Socialist vote share in 1919 | — | not_attempted |
| 6 | `iv_fascist_vote1924_table3_panelC_col1` | 0.4 | 0.17 | Table III, Panel C (2SLS), column (1), Socialist vote share in 1919 | — | not_attempted |
| 7 | `iv_fascist_vote1924_table3_panelC_col6` | 0.51 | 0.17 | Table III, Panel C (2SLS), column (6), Socialist vote share in 1919 | — | not_attempted |
| 8 | `n_obs_main_sample` | 5775 | — | Table I, Observations (all columns); also Table II and Table III Panels C-D | — | — |
| 9 | `n_clusters_main_sample` | 181 | — | Table I, Number of clusters (all columns); also Table II and Table III Panels C-D | — | — |
| 10 | `n_obs_fascist_vote1921` | 5358 | — | Table III, Panels A-B, Observations | — | — |
| 11 | `n_clusters_fascist_vote1921` | 175 | — | Table III, Panels A-B, Number of clusters | — | — |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [12/12](seeded/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[12/12](seeded/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) | [12/12](independent/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[12/12](independent/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) | [12/12](blind/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[12/12](blind/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) |
| `pipeline-desktop-opus` | [12/12](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) (20261023T063725Z) | [11/12](independent/pipeline-desktop-opus/20261023T064839Z/CELL.md) (20261023T064839Z) | [4/12](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) (20261023T062931Z) |
| `pipeline-desktop-opus-run2` | [12/12](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) (20261023T151837Z) | [11/12](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) (20261023T153002Z) | [6/12](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) (20261023T150832Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [blind/pipeline-desktop-opus-run2/20261023T150832Z](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) | `iv_fascist_vote1921_table3_panelA_col6` | 0.512978 | 0.34 | ±0.18 (se_band) | 0.961 | PASS |
| [blind/pipeline-desktop-opus/20261023T062931Z](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) | `iv_violence_table2_panelA_col6` | 0.27341 | 0.5 | ±0.2 (se_band) | 1.133 | FAIL |
| [blind/pipeline-desktop-opus/20261023T062931Z](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) | `iv_fascist_vote1921_table3_panelA_col6` | 0.236371 | 0.34 | ±0.18 (se_band) | 0.576 | PASS |
| [seeded/claude-code/2026-10-22-a](seeded/claude-code/2026-10-22-a/CELL.md) | `iv_fascist_vote1924_table3_panelC_col1` | 0.395648 | 0.4 | ±0.008 (relative) | 0.544 | PASS |
| [seeded/claude-code/2026-11-02-b](seeded/claude-code/2026-11-02-b/CELL.md) | `iv_fascist_vote1924_table3_panelC_col1` | 0.395648 | 0.4 | ±0.008 (relative) | 0.544 | PASS |
| [seeded/pipeline-desktop-opus/20261023T063725Z](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) | `iv_fascist_vote1924_table3_panelC_col1` | 0.395648 | 0.4 | ±0.008 (relative) | 0.544 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261023T151837Z](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) | `iv_fascist_vote1924_table3_panelC_col1` | 0.395648 | 0.4 | ±0.008 (relative) | 0.544 | PASS |
| [independent/pipeline-desktop-opus-run2/20261023T153002Z](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) | `first_stage_casualties_table1_col6` | 0.095048 | 0.1 | ±0.01 (se_band) | 0.495 | PASS |
| [independent/pipeline-desktop-opus-run2/20261023T153002Z](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) | `iv_violence_table2_panelA_col6` | 0.402824 | 0.5 | ±0.2 (se_band) | 0.486 | PASS |
| [blind/pipeline-desktop-opus/20261023T062931Z](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) | `iv_branches_table2_panelC_col6` | 0.193945 | 0.5 | ±0.2 (se_band) | 1.530 | FAIL |

### Declared deviations

- [independent/claude-code/2026-11-01-a](independent/claude-code/2026-11-01-a/CELL.md) (12/12)
  - Standardized coefficients computed by z-scoring the outcome, the 1919 socialist vote share and the casualty instrument over the full 5,775-municipality sample (also for the 1921 regression, whose sample is 5,358); controls are not standardized since that does not change the reported coefficient.
  - First-stage F-statistic computed as the squared cluster-robust t-statistic of the single excluded instrument (fixest default small-sample corrections).
- [independent/pipeline-desktop-opus/20261023T064839Z](independent/pipeline-desktop-opus/20261023T064839Z/CELL.md) (11/12; failed: `first_stage_fstat_table1_col6`)
  - Regiment FE extended from infantry (fanteria) regiments to all foot-soldier regiments (bersaglieri/alpini) present in the data
- [blind/claude-code/2026-10-22-a](blind/claude-code/2026-10-22-a/CELL.md) (12/12)
  - Standardized coefficients computed by standardizing the outcome, the 1919 socialist vote share and the instrument (mean 0, sd 1) over each variable's non-missing values in fascism_db.dta before estimation; for the 1921 fascist vote share (5,358 non-missing) this is the 1921-sample standardization of that variable, while the regressor and instrument use the full 5,775-municipality moments.
  - Regiment fixed effects entered as all 359 d_reg* dummy columns in fascism_db.dta (collinear ones dropped by fixest); province fixed effects absorbed via provincia1921; SEs clustered by circondario1921 with fixest's default small-sample corrections. F-stat is the squared cluster-robust t-statistic of the instrument in the first stage.
- [blind/claude-code/2026-11-01-a](blind/claude-code/2026-11-01-a/CELL.md) (12/12)
  - Standardized coefficients computed by z-scoring the outcome, endogenous regressor, instrument and controls within each regression's estimation sample (for the 1921 vote share, within the 5,358-municipality 1921 sample).
  - First-stage F-statistic for Table I col (6) computed as the squared district-clustered t-statistic of the casualty coefficient (fixest small-sample corrections, province FE nested in clusters); Stata ivreg2/reghdfe corrections may differ slightly.
  - Highest-mortality-battles dummy taken to be cruent_d; assault troops + volunteers casualty share taken to be ard_vol_pop6m; regiment FE = all 359 d_reg* dummies; province FE = provincia1921; clusters = circondario1921.
- [blind/pipeline-desktop-opus/20261023T062931Z](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) (4/12; failed: `first_stage_casualties_table1_col1`, `first_stage_casualties_table1_col6`, `first_stage_fstat_table1_col6`, `iv_violence_table2_panelA_col6`, `iv_branches_table2_panelC_col6`, `iv_fascist_vote1924_table3_panelC_col6`, `n_clusters_main_sample`, `n_clusters_fascist_vote1921`)
  - variable for elevation main center not found; omitted
  - variable for high-mortality battle dummy not found; omitted
  - variable for landowner association not found; omitted
  - regiment dummies not found; omitted

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- independent: `first_stage_fstat_table1_col6` — pipeline 0/2, agent 2/2
- blind: `first_stage_casualties_table1_col1` — pipeline 0/2, agent 2/2
- blind: `first_stage_casualties_table1_col6` — pipeline 0/2, agent 2/2
- blind: `first_stage_fstat_table1_col6` — pipeline 0/2, agent 2/2
- blind: `iv_branches_table2_panelC_col6` — pipeline 0/2, agent 2/2
- blind: `iv_fascist_vote1924_table3_panelC_col6` — pipeline 0/2, agent 2/2

Pass rates at least 50 points apart (not unanimous):

- blind: `iv_fascist_vote1924_table3_panelC_col1` — pipeline 1/2, agent 2/2
- blind: `iv_violence_table2_panelA_col6` — pipeline 1/2, agent 2/2
- blind: `n_clusters_fascist_vote1921` — pipeline 1/2, agent 2/2
- blind: `n_clusters_main_sample` — pipeline 1/2, agent 2/2

## Cells

### seeded · claude-code · 2026-10-22-a

[`seeded/claude-code/2026-10-22-a/CELL.md`](seeded/claude-code/2026-10-22-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-10-22T03:02:30Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### seeded · claude-code · 2026-11-02-b

[`seeded/claude-code/2026-11-02-b/CELL.md`](seeded/claude-code/2026-11-02-b/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 3; 2026-11-02T19:42:00Z; from `claude-code-run2-23papers-seeded-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261023T063725Z

[`seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md`](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-23T06:37:25Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261023T151837Z

[`seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-23T15:18:37Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### independent · claude-code · 2026-10-22-a

[`independent/claude-code/2026-10-22-a/CELL.md`](independent/claude-code/2026-10-22-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 3; 2026-10-22T03:11:30Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### independent · claude-code · 2026-11-01-a

[`independent/claude-code/2026-11-01-a/CELL.md`](independent/claude-code/2026-11-01-a/CELL.md) — final 12/12, re-scored 12/12; first scored 10/12; executions 3; 2026-11-02T04:31:00Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261023T064839Z

[`independent/pipeline-desktop-opus/20261023T064839Z/CELL.md`](independent/pipeline-desktop-opus/20261023T064839Z/CELL.md) — final 11/12, re-scored 11/12; first scored 4/12; executions 4; 2026-10-23T06:48:39Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261023T153002Z

[`independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) — final 11/12, re-scored 11/12; first scored 4/12; executions 4; 2026-10-23T15:30:02Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### blind · claude-code · 2026-10-22-a

[`blind/claude-code/2026-10-22-a/CELL.md`](blind/claude-code/2026-10-22-a/CELL.md) — final 12/12, re-scored 12/12; first scored 10/12; executions 3; 2026-10-22T03:20:20Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### blind · claude-code · 2026-11-01-a

[`blind/claude-code/2026-11-01-a/CELL.md`](blind/claude-code/2026-11-01-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 3; 2026-11-02T04:25:00Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261023T062931Z

[`blind/pipeline-desktop-opus/20261023T062931Z/CELL.md`](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) — final 4/12, re-scored 4/12; first scored 4/12; executions 1; 2026-10-23T06:29:31Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261023T150832Z

[`blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) — final 6/12, re-scored 6/12; first scored 6/12; executions 1; 2026-10-23T15:08:32Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

