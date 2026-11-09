# Evidence report: mokyr-2022-wheels-of-change

**The Wheels of Change: Technology Adoption, Millwrights and the Persistence in Britain's Industrialisation** — Joel Mokyr, Assaf Sarid, Karine van der Beek

- Paper: https://bpb-us-e1.wpmucdn.com/sites.northwestern.edu/dist/3/1222/files/2024/02/The-Wheels-of-Change-2022-2d19383637e6a5b4.pdf
- I4R report: https://github.com/I4Replication/I4R-First-Meta-Paper
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/mokyr-2022-wheels-of-change.yaml`
- Data access: public

> Headline finding: English districts with more watermills in the Domesday Book (1086) had more apprentices to wrights (millwrights) in 1710-50, conditional on geography, agriculture, climate and trade access (Table 2: 0.15 unconditional, 0.12 (SE 0.03) with all controls), and the relation survives instrumenting Domesday mills with river x wheat suitability (Table 3 IV 0.16 / 0.15 / 0.16, first-stage F 19.90 / 16.96 / 16.17).  N = 298 districts in every column.
> Curation pass (2026-11-02).  Pinned 13 claims from the two core tables of Section 4.1: Table 2's watermills coefficient in all five columns, Table 3's column (5) OLS and the three IV columns, each with its SE in standard_error; the three first-stage F-statistics; and N.  The tables print two decimals; I4R records three for the three originals it examines (0.120 (0.028), 0.117 (0.028), 0.159 (0.037)), all of which round to the printed values.  The abstract states no numbers; the intro restates Table 2 col 3-4 (0.14).  Left out: Table 2 control coefficients and adjusted R2s, Table 3 columns (1) and (3) (column 1 is Table 2 column 1 again; column 3 is an OLS without the river and wheat controls), the river/wheat suitability coefficients, Table 1 summary statistics, Table 4 (Hampshire mill counts), Table 5 (the Black Death interaction; its note calls the evidence "suggestive"), Tables 6-9 (drapers, industrial vs other occupations, mediation, worsteds) and the online appendix.  Description tokens are distinct under substring matching (no col1 / col10 clash).
> What was read.  The published EJ PDF (all 33 pp.; Tables 2-3 and Section 4.1 in full, Tables 5-6 and the introduction); the Zenodo API metadata for records 5731589 and 5734954; the whole package listing, main.do and the Table 2 / Table 3 / Table 5-9 sections of Tables.do, the README PDF, the .aux and the head of the .log; Crossref metadata; the meta-database's 17 rows.  There is no I4R DP.
> Independent cross-check (not the package code: pandas + numpy OLS and 2SLS with county-clustered SEs on replication_data.dta, Stata's CR1 adjustment).  Reproduces every pinned value at the printed precision: Table 2 cols 1-5 0.1461 (0.0242), 0.1438 (0.0226), 0.1416 (0.0228), 0.1407 (0.0231), 0.1199 (0.0281), adjusted R2 0.568 / 0.583 / 0.590 / 0.590 / 0.606; Table 3 col 5 OLS 0.1168 (0.0279), adj. R2 0.616; IV col 2 0.1591 (0.0374), col 4 0.1522 (0.0400), col 6 0.1592 (0.0376) (IV SEs with the G/(G-1) cluster factor only, ivreg2's default); first-stage F = squared clustered t of the excluded instrument with the full CR1 adjustment: 19.90, 16.96, 16.17 exactly (without the (N-1)/(N-K) factor: 20.11, 17.61, 17.16).  N = 298, 35 county clusters in every column.
> Package-only facts (never in contexts).  main.do: cd "your_directory"; county_id = encode GAZ_CNTY (ancient county; 35 clusters in the estimation sample); mills_pc = mills / pcmean and wrights_pc = wrights / pcmean (pcmean: HYDE mean population 1710-50, in tens of thousands); wheat_suit = wheat_tmean <= 5; riv_rug26count is divided by 1000 and the instrument is msuit26mean = wheat_suit * riv_rug26count.  Tables.do, Table 2: reg wrights_pc mills_pc [controls], cluster(county_id); column 2 adds `if e(sample)==1`; column 3 adds suitmean wheat_suit dist_grass_mean; column 4 precip_mean_dist temp_mean_dist; column 5 pcmean min_harbor DIST_London min_dist* (min_dist_to_roman_rds, min_dist_2nav_rivers) area.  Table 3: column 2 ivreg2 wrights_pc (mills_pc = msuit26mean) riv_rug26count wheat_suit, cluster(county_id) first savefirst; column 4 adds longitude latitude dist_rug_mean dist_elevation_mean suitmean dist_grass_mean precip_mean_dist temp_mean_dist; columns 5 (reg) and 6 (ivreg2) add min_harbor DIST_London min_dist* pcmean area, `r cluster(county_id)`.  The First-stage F row is estadd scalar fstat = e(widstat), ivreg2's Kleibergen-Paap rk Wald F under clustering.  So every Table 3 SE is clustered by county although the Table 3 note mentions only heteroscedasticity robust SEs (the contexts quote the note and the Section 4.2 clustering statement).  Needs ssc estout, ivreg2, ranktest, sutex, medeff (mediation, Table 8).  The 298 of 325 rows are those with non-missing mills.
> Zero-cost end-to-end check (2026-11-02).  `uv run python -m benchmark.runner --llm-oracle curation-check --only mokyr-2022-wheels-of-change`, once with --mode blind and once with --mode independent: both cells stopped as llm_answer_pending on the first call, the methodology summary, whose prompt embeds the full paper text (Tables 2-3 included) by design and carried no package script text.  Because that stops before code generation, the blind and independent tasks were also rendered with benchmark.reproducers. render_task (no API calls): the blind task.md states none of the 13 values or SEs (as printed or rounded to 1-4 significant figures, nor I4R's three-decimal originals) and no script text; the blind paper.txt carries 150 redactions and keeps only "(0.2)", the Table 5 column 4 coefficient (not pinned).  The script-free mount withholds 17 files (five do/ado, the .log, the accepted and appendix PDFs, three manuscript .docx, six __MACOSX stubs) and keeps the data, the README codebook, figures.docx, the .aux / .synctex.gz, the xlsx and two figure PNGs.  Before the strip-rule extension made with this entry the accepted PDF, the appendix PDF and all four manuscript .docx were on the mount (tables_ocr.docx prints every table as text).
> What could not be verified.  The do-files were not run in Stata and no Stata log ships; the cross-check above is an independent re-estimate. The meta-database row numbers are the 0-based indices the corpus files use (5895-5911).
> Original analysis in Stata (main.do, Tables.do; reg and ivreg2); language is r, the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `watermills_table2_col1` | 0.15 | 0.02 | Table 2, column (1), Watermills (per capita) | 0.15 | matches |
| 1 | `watermills_table2_col2` | 0.14 | 0.02 | Table 2, column (2), Watermills (per capita) | 0.14 | matches |
| 2 | `watermills_table2_col3` | 0.14 | 0.02 | Table 2, column (3), Watermills (per capita) | 0.14 | matches |
| 3 | `watermills_table2_col4` | 0.14 | 0.02 | Table 2, column (4), Watermills (per capita) | 0.14 | matches |
| 4 | `watermills_table2_col5` | 0.12 | 0.03 | Table 2, column (5), Watermills (per capita) | 0.12 | matches |
| 5 | `watermills_ols_table3_col5` | 0.12 | 0.03 | Table 3, column (5) OLS, Watermills (per capita) | 0.117 | matches |
| 6 | `watermills_iv_table3_col2` | 0.16 | 0.04 | Table 3, column (2) IV, Watermills (per capita) | 0.16 | matches |
| 7 | `watermills_iv_table3_col4` | 0.15 | 0.04 | Table 3, column (4) IV, Watermills (per capita) | 0.15 | matches |
| 8 | `watermills_iv_table3_col6` | 0.16 | 0.04 | Table 3, column (6) IV, Watermills (per capita) | 0.159 | matches |
| 9 | `first_stage_f_table3_col2` | 19.9 | — | Table 3, column (2), First-stage F-statistic | 19.9 | matches |
| 10 | `first_stage_f_table3_col4` | 16.96 | — | Table 3, column (4), First-stage F-statistic | 16.96 | matches |
| 11 | `first_stage_f_table3_col6` | 16.17 | — | Table 3, column (6), First-stage F-statistic | 16.17 | matches |
| 12 | `n_districts_tables2_3` | 298 | — | Tables 2 and 3, Observations | 298 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[13/13](seeded/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) | [13/13](independent/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[13/13](independent/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b)<br>[13/13](independent/claude-code/2026-11-02-c/CELL.md) (2026-11-02-c)<br>[13/13](independent/claude-code/2026-11-07-a/CELL.md) (2026-11-07-a) | [13/13](blind/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[13/13](blind/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b)<br>[13/13](blind/claude-code/2026-11-02-c/CELL.md) (2026-11-02-c)<br>[13/13](blind/claude-code/2026-11-07-a/CELL.md) (2026-11-07-a) |
| `pipeline-desktop-opus` | [13/13](seeded/pipeline-desktop-opus/20261102T142733Z/CELL.md) (20261102T142733Z) | [13/13](independent/pipeline-desktop-opus/20261102T142733Z/CELL.md) (20261102T142733Z) | [1/13](blind/pipeline-desktop-opus/20261102T141403Z/CELL.md) (20261102T141403Z) |
| `pipeline-desktop-opus-postfix` | — | [13/13](independent/pipeline-desktop-opus-postfix/20261103T062157Z/CELL.md) (20261103T062157Z) | [13/13](blind/pipeline-desktop-opus-postfix/20261103T062809Z/CELL.md) (20261103T062809Z) |
| `pipeline-desktop-opus-postfix2` | — | [13/13](independent/pipeline-desktop-opus-postfix2/20261103T110326Z/CELL.md) (20261103T110326Z) | [13/13](blind/pipeline-desktop-opus-postfix2/20261103T111134Z/CELL.md) (20261103T111134Z) |
| `pipeline-desktop-opus-run2` | [13/13](seeded/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md) (20261102T152052Z) | [7/13](independent/pipeline-desktop-opus-run2/20261102T190406Z/CELL.md) (20261102T190406Z) | [1/13](blind/pipeline-desktop-opus-run2/20261102T151132Z/CELL.md) (20261102T151132Z) |
| `pipeline-desktop-opus-run3` | [13/13](seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) (20261103T010557Z) | [7/13](independent/pipeline-desktop-opus-run3/20261103T052626Z/CELL.md) (20261103T052626Z) | [7/13](blind/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md) (20261103T004800Z) |
| `pipeline-desktop-opus-run4` | — | [12/13](independent/pipeline-desktop-opus-run4/20261108T083700Z/CELL.md) (20261108T083700Z) | [1/13](blind/pipeline-desktop-opus-run4/20261108T013503Z/CELL.md) (20261108T013503Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [independent/pipeline-desktop-opus-run2/20261102T190406Z](independent/pipeline-desktop-opus-run2/20261102T190406Z/CELL.md) | `watermills_iv_table3_col4` | 0.189695 | 0.15 | ±0.04 (se_band) | 0.992 | PASS |
| [independent/pipeline-desktop-opus-run3/20261103T052626Z](independent/pipeline-desktop-opus-run3/20261103T052626Z/CELL.md) | `watermills_iv_table3_col4` | 0.185529 | 0.15 | ±0.04 (se_band) | 0.888 | PASS |
| [blind/pipeline-desktop-opus-run3/20261103T004800Z](blind/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md) | `watermills_iv_table3_col4` | 0.185529 | 0.15 | ±0.04 (se_band) | 0.888 | PASS |
| [independent/pipeline-desktop-opus-run4/20261108T083700Z](independent/pipeline-desktop-opus-run4/20261108T083700Z/CELL.md) | `first_stage_f_table3_col4` | 16.8112 | 16.96 | ±0.1696 (relative) | 0.877 | PASS |
| [blind/pipeline-desktop-opus-run3/20261103T004800Z](blind/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md) | `watermills_table2_col5` | 0.0848292 | 0.12 | ±0.03 (se_band) | 1.172 | FAIL |
| [independent/pipeline-desktop-opus-run2/20261102T190406Z](independent/pipeline-desktop-opus-run2/20261102T190406Z/CELL.md) | `watermills_iv_table3_col2` | 0.193018 | 0.16 | ±0.04 (se_band) | 0.825 | PASS |
| [independent/pipeline-desktop-opus-run3/20261103T052626Z](independent/pipeline-desktop-opus-run3/20261103T052626Z/CELL.md) | `watermills_iv_table3_col2` | 0.193018 | 0.16 | ±0.04 (se_band) | 0.825 | PASS |
| [blind/pipeline-desktop-opus-run3/20261103T004800Z](blind/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md) | `watermills_iv_table3_col2` | 0.193018 | 0.16 | ±0.04 (se_band) | 0.825 | PASS |
| [independent/pipeline-desktop-opus-run2/20261102T190406Z](independent/pipeline-desktop-opus-run2/20261102T190406Z/CELL.md) | `watermills_table2_col5` | 0.084349 | 0.12 | ±0.03 (se_band) | 1.188 | FAIL |
| [independent/pipeline-desktop-opus-run2/20261102T190406Z](independent/pipeline-desktop-opus-run2/20261102T190406Z/CELL.md) | `watermills_ols_table3_col5` | 0.084349 | 0.12 | ±0.03 (se_band) | 1.188 | FAIL |

### Declared deviations

- [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) (13/13)
  - First-stage F reported as an R translation of ivreg2's Kleibergen-Paap rk Wald F for one endogenous regressor and one excluded instrument: first-stage Wald statistic on msuit26mean with the unadjusted cluster (county_id) VCE, scaled by (N-K)/N*(G-1)/G. The squared cluster t-statistic with Stata's small-sample adjustment is printed as a diagnostic (not a RESULT).
- [independent/pipeline-desktop-opus-run2/20261102T190406Z](independent/pipeline-desktop-opus-run2/20261102T190406Z/CELL.md) (7/13; failed: `watermills_table2_col5`, `watermills_ols_table3_col5`, `watermills_iv_table3_col6`, `first_stage_f_table3_col2`, `first_stage_f_table3_col4`, `first_stage_f_table3_col6`)
  - First-stage F reported as heteroskedasticity-robust (HC1) Wald F on the excluded instrument rather than county-clustered, since the clustered F was roughly half the paper's values
- [independent/pipeline-desktop-opus-run3/20261103T052626Z](independent/pipeline-desktop-opus-run3/20261103T052626Z/CELL.md) (7/13; failed: `watermills_table2_col5`, `watermills_ols_table3_col5`, `watermills_iv_table3_col6`, `first_stage_f_table3_col2`, `first_stage_f_table3_col4`, `first_stage_f_table3_col6`)
  - wrights counts divided by mean population 1710-50 (pcmean, which is in units of 10,000 people) without an extra x10,000 factor, giving wright apprentices per 10,000 people
- [blind/claude-code/2026-11-02-a](blind/claude-code/2026-11-02-a/CELL.md) (13/13)
  - First-stage F reported as the county-clustered Wald F on the single excluded instrument (fixest ivwald1), consistent with the paper's statement that all regressions cluster at the county level; Table 3 notes mention heteroscedasticity-robust SEs, and the paper's exact F definition (e.g. Stata ivreg2 KP F with its small-sample corrections) is not stated.
- [blind/claude-code/2026-11-02-b](blind/claude-code/2026-11-02-b/CELL.md) (13/13)
  - First-stage F-statistics are cluster-robust (historical county) Wald F on the single excluded instrument (equivalent to Kleibergen-Paap Wald F); iid first-stage F values are printed as diagnostics but not scored.
  - Latitude/longitude use the dataset's labelled 'latitude'/'longitude' variables (projected coordinates), not y1/x1 (degrees).
- [blind/claude-code/2026-11-02-c](blind/claude-code/2026-11-02-c/CELL.md) (13/13)
  - First-stage F-statistic computed as the Wald F of the single excluded instrument using the historical-county clustered vcov (equivalent to Kleibergen-Paap F for one instrument); the paper does not state which F variant it reports. Non-robust first-stage F values are printed as diagnostics but not scored.
  - Wheat suitability control in Table 2 col 3+ and Table 3 is the binary indicator wheat_tmean <= 5, as the task context specifies.
  - first-stage F reported as cluster-robust (historical county) Wald F of the excluded instrument; paper's exact F variant not stated
- [blind/claude-code/2026-11-07-a](blind/claude-code/2026-11-07-a/CELL.md) (13/13)
  - First-stage F reported as the squared county-clustered t-statistic of the excluded instrument (equivalent to the cluster-robust Kleibergen-Paap Wald F with one instrument, without Stata small-sample conventions beyond fixest defaults). The Table 3 note mentions heteroscedasticity-robust SEs while Section 4 says all regressions are clustered by county; HC1 and iid variants are printed (not as RESULT lines) for reference: col2 32.0/69.3, col4 24.1/55.4, col6 23.2/65.5.
- [blind/pipeline-desktop-opus-run2/20261102T151132Z](blind/pipeline-desktop-opus-run2/20261102T151132Z/CELL.md) (1/13; failed: `watermills_table2_col1`, `watermills_table2_col2`, `watermills_table2_col3`, `watermills_table2_col4`, `watermills_table2_col5`, `watermills_ols_table3_col5`, `watermills_iv_table3_col2`, `watermills_iv_table3_col4`, `watermills_iv_table3_col6`, `first_stage_f_table3_col2`, `first_stage_f_table3_col4`, `first_stage_f_table3_col6`)
  - mills appears already per capita; used as is

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

_None._

Pass rates at least 50 points apart (not unanimous):

- independent: `first_stage_f_table3_col6` — pipeline 3/6, agent 4/4
- blind: `first_stage_f_table3_col2` — pipeline 2/6, agent 4/4
- blind: `first_stage_f_table3_col4` — pipeline 2/6, agent 4/4
- blind: `first_stage_f_table3_col6` — pipeline 2/6, agent 4/4
- blind: `watermills_iv_table3_col2` — pipeline 3/6, agent 4/4
- blind: `watermills_iv_table3_col4` — pipeline 3/6, agent 4/4
- blind: `watermills_iv_table3_col6` — pipeline 2/6, agent 4/4
- blind: `watermills_ols_table3_col5` — pipeline 2/6, agent 4/4
- blind: `watermills_table2_col1` — pipeline 3/6, agent 4/4
- blind: `watermills_table2_col2` — pipeline 3/6, agent 4/4
- blind: `watermills_table2_col3` — pipeline 3/6, agent 4/4
- blind: `watermills_table2_col4` — pipeline 3/6, agent 4/4
- blind: `watermills_table2_col5` — pipeline 2/6, agent 4/4

## Cells

### seeded · claude-code · 2026-11-02-a

[`seeded/claude-code/2026-11-02-a/CELL.md`](seeded/claude-code/2026-11-02-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-02T10:06:22Z; from `claude-code-6papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · claude-code · 2026-11-02-b

[`seeded/claude-code/2026-11-02-b/CELL.md`](seeded/claude-code/2026-11-02-b/CELL.md) — final 13/13, re-scored 13/13; first scored 10/13; executions 2; 2026-11-02T19:38:40Z; from `claude-code-run2-23papers-seeded-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261102T142733Z

[`seeded/pipeline-desktop-opus/20261102T142733Z/CELL.md`](seeded/pipeline-desktop-opus/20261102T142733Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-02T14:27:33Z; from `pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261102T152052Z

[`seeded/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-02T15:20:52Z; from `pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261103T010557Z

[`seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-03T01:05:57Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

### independent · claude-code · 2026-11-02-a

[`independent/claude-code/2026-11-02-a/CELL.md`](independent/claude-code/2026-11-02-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T10:06:30Z; from `claude-code-6papers-all-modes-2026-11-02.json`; evidence complete.

### independent · claude-code · 2026-11-02-b

[`independent/claude-code/2026-11-02-b/CELL.md`](independent/claude-code/2026-11-02-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T14:56:30Z; from `claude-code-run2-6papers-indep-blind-2026-11-02.json`; evidence complete.

### independent · claude-code · 2026-11-02-c

[`independent/claude-code/2026-11-02-c/CELL.md`](independent/claude-code/2026-11-02-c/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T20:06:08Z; from `claude-code-run3-23papers-indep-blind-2026-11-02.json`; evidence complete.

### independent · claude-code · 2026-11-07-a

[`independent/claude-code/2026-11-07-a/CELL.md`](independent/claude-code/2026-11-07-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-08T02:05:00Z; from `claude-code-run4-24papers-indep-blind-2026-11-08.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261102T142733Z

[`independent/pipeline-desktop-opus/20261102T142733Z/CELL.md`](independent/pipeline-desktop-opus/20261102T142733Z/CELL.md) — final 13/13, re-scored 13/13; first scored 1/13; executions 2; 2026-11-02T14:27:33Z; from `pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus-postfix · 20261103T062157Z

[`independent/pipeline-desktop-opus-postfix/20261103T062157Z/CELL.md`](independent/pipeline-desktop-opus-postfix/20261103T062157Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-03T06:21:57Z; from `pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json`; evidence complete.

### independent · pipeline-desktop-opus-postfix2 · 20261103T110326Z

[`independent/pipeline-desktop-opus-postfix2/20261103T110326Z/CELL.md`](independent/pipeline-desktop-opus-postfix2/20261103T110326Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-03T11:03:26Z; from `pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261102T190406Z

[`independent/pipeline-desktop-opus-run2/20261102T190406Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261102T190406Z/CELL.md) — final 7/13, re-scored 7/13; first scored 1/13; executions 4; 2026-11-02T19:04:06Z; from `pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261103T052626Z

[`independent/pipeline-desktop-opus-run3/20261103T052626Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261103T052626Z/CELL.md) — final 7/13, re-scored 7/13; first scored 1/13; executions 4; 2026-11-03T05:26:26Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

### independent · pipeline-desktop-opus-run4 · 20261108T083700Z

[`independent/pipeline-desktop-opus-run4/20261108T083700Z/CELL.md`](independent/pipeline-desktop-opus-run4/20261108T083700Z/CELL.md) — final 12/13, re-scored 12/13; first scored 1/13; executions 2; 2026-11-08T08:37:00Z; from `pipeline-oracle-desktop-opus-run4-24papers-indep-blind-2026-11-08.json`; evidence complete.

### blind · claude-code · 2026-11-02-a

[`blind/claude-code/2026-11-02-a/CELL.md`](blind/claude-code/2026-11-02-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T00:30:00Z; from `claude-code-6papers-all-modes-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-02-b

[`blind/claude-code/2026-11-02-b/CELL.md`](blind/claude-code/2026-11-02-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T14:59:00Z; from `claude-code-run2-6papers-indep-blind-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-02-c

[`blind/claude-code/2026-11-02-c/CELL.md`](blind/claude-code/2026-11-02-c/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T12:20:00Z; from `claude-code-run3-23papers-indep-blind-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-07-a

[`blind/claude-code/2026-11-07-a/CELL.md`](blind/claude-code/2026-11-07-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-08T01:57:00Z; from `claude-code-run4-24papers-indep-blind-2026-11-08.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261102T141403Z

[`blind/pipeline-desktop-opus/20261102T141403Z/CELL.md`](blind/pipeline-desktop-opus/20261102T141403Z/CELL.md) — final 1/13, re-scored 1/13; first scored 1/13; executions 1; 2026-11-02T14:14:03Z; from `pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus-postfix · 20261103T062809Z

[`blind/pipeline-desktop-opus-postfix/20261103T062809Z/CELL.md`](blind/pipeline-desktop-opus-postfix/20261103T062809Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-03T06:28:09Z; from `pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json`; evidence complete.

### blind · pipeline-desktop-opus-postfix2 · 20261103T111134Z

[`blind/pipeline-desktop-opus-postfix2/20261103T111134Z/CELL.md`](blind/pipeline-desktop-opus-postfix2/20261103T111134Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-03T11:11:34Z; from `pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261102T151132Z

[`blind/pipeline-desktop-opus-run2/20261102T151132Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261102T151132Z/CELL.md) — final 1/13, re-scored 1/13; first scored 1/13; executions 1; 2026-11-02T15:11:32Z; from `pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261103T004800Z

[`blind/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md) — final 7/13, re-scored 7/13; first scored 7/13; executions 1; 2026-11-03T00:48:00Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

### blind · pipeline-desktop-opus-run4 · 20261108T013503Z

[`blind/pipeline-desktop-opus-run4/20261108T013503Z/CELL.md`](blind/pipeline-desktop-opus-run4/20261108T013503Z/CELL.md) — final 1/13, re-scored 1/13; first scored 1/13; executions 1; 2026-11-08T01:35:03Z; from `pipeline-oracle-desktop-opus-run4-24papers-indep-blind-2026-11-08.json`; evidence complete.

