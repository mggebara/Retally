# Evidence report: leeson-2022-hobo-economicus

**Hobo Economicus** — Peter T. Leeson, R. August Hardy, Paola A. Suarez

- Paper: https://www.peterleeson.com/Hobo_Economicus.pdf
- I4R report: https://www.econstor.eu/bitstream/10419/274554/1/I4R-DP055.pdf
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/leeson-2022-hobo-economicus.yaml`

> Headline finding: panhandlers at Washington, DC Metrorail stations behave as maximisers — stations with more passersby attract more panhandlers (Table 2: 0.005 panhandlers per passerby unit, SE 0.001, full sample), and hourly panhandling receipts do not differ significantly across five neighbouring downtown stations (Tables 3-5: Brown-Forsythe, ANOVA and Kruskal-Wallis tests, all p > 0.5).
> Outcome label.  The I4R verdict is "minor discrepancies" (perfect_reproduction = No, computational_reproduction = 1; why_not_perfect_repro: Table 4 swaps the within/between labels, and the footnote 16-17 robustness checks are not created by the package).  The schema's OutcomeLabel has no such value (reproducible / robust / not_robust / not_reproducible / inconclusive); scripts/ import_i4r_candidates.py maps it to inconclusive pending human review. On review: every pinned number reproduces from the package (DP 55 and the cross-check below), so reproducible is used; the discrepancies are recorded here.  (Package detail: the analysis do-file runs Stata's robvar, whose W0 output is Levene's test, so the footnote 16 Levene variant is in the log output even though DP 55 counts it as missing; the footnote 17 bounded-minutes variants are genuinely absent.)
> Curation pass (2026-10-21).  Pinned 11 claims: five Table 2 coefficients with their clustered SEs in standard_error (passersby in both columns, friendliness in column 1 — the one the text calls significant only in the full sample — and the shuttle-stop indicator in both columns), the two Brown-Forsythe W and two ANOVA F statistics (sample_size = number of panhandler observations), and the two Table 2 observation counts.  The passersby coefficients are printed to three decimals (0.005, 0.006), i.e. one significant digit.  Left out: the homeless-service coefficients (0.450 / 0.815) and column 2 friendliness (1.462, SE 2.793), the adjusted R2s (0.39 / 0.06), Table 1 summary statistics, Table 3 and 5 per-station rows, the Table 4 sums of squares (mislabelled in the paper), the Kruskal-Wallis statistics (2.506 / 3.170), the in-text standardized effects (0.53 / 0.40 SD) and the power calculations.
> Context rewording (2026-11-01).  The contexts of the four test-statistic claims used to state each test's p-value, and the two ANOVA contexts its degrees of freedom; with the test named and the group count known, those pin the statistic (the memorisation probe's answering agent back-computed three of the four from them; ROADMAP 3.5, "Memorisation probe").  Moved here: Table 3 Brown-Forsythe W p-values 0.706 (Panel A, donations per hour) and 0.893 (Panel B, dollars per hour); Table 4 ANOVA F p-values 0.809 (Panel A) and 0.962 (Panel B), on 4 and 75 and on 4 and 62 degrees of freedom.  Values are unchanged.  Every Leeson run in ROADMAP up to and including 3.5 used the old contexts.
> What was read.  The published EJ PDF (Tables 1-5, text, footnotes); the Zenodo API metadata; the whole package (downloaded to a scratch directory, never committed): both zips, ReadMe.pdf, the three do-files and the six .csv files; I4R DP 55 (EconStor PDF); the meta-database's 16 rows.
> Independent cross-check (not the package code: pandas / scipy / statsmodels on the .csv files).  Reproduces every pinned value at the printed precision: Table 2 col 1 passersby 0.005 (0.001), friendliness 1.595 (0.851), shuttle 0.781 (0.182), service 0.450 (0.278), adj. R2 0.39, N 242; col 2 0.006 (0.002), 1.462 (2.793), 0.890 (0.227), 0.815 (0.525), 0.06, N 102; Brown-Forsythe W 0.541 (p 0.706) / 0.276 (0.893); ANOVA F 0.398 (0.809) / 0.151 (0.962); Kruskal-Wallis 2.506 / 3.170; 80 receipts rows, 76 unique panhandlers, 67.6 hours observed, 242 visits to 26 stations, 258 panhandlers counted.
> Package structure (package-only facts; never in contexts).  Inside replicate.zip: code/0_setup.do (hard-coded Windows `cd "C:\Documents\Projects\replicate"`; `ssc install` stripplot, outreg, labutil — needs network), code/1_dataprep.do (imports the csvs with Windows backslash paths such as "data\metrovisitslog", builds stationvisit.dta and receipts.dta), code/2_analysis.do (Table 1 sum, Table 2 `reg panhandlers passersby friendly shuttle service i.day, vce(cluster metroid)` written with outreg to output\table2.doc, Table 3 robvar, Table 4 oneway, Table 5 kwallis, Figure 1 stripplot, power oneway), each with an identical .txt copy.  Data: metrovisitslog.csv (metro, date, panhandlers; 242 rows), passersby.csv (metro, month, year, passersby in thousands), friendliness.csv (701 passersby, passresp1-5), service.csv and shuttle.csv (walking minutes to the nearest provider / stop; the indicators are minutes <= 10), receipts.csv (observationid, panhandlerid, date, metro, donations, minutes, cash, inkind, declinedoffer).  The five-station subsample is hard-coded as metroid 9/10/14/17/18 after `encode metro` (alphabetical ids; "Gallery Place" in the data); friendliness is the station mean of each passerby's highest response category.  Also Codebook.xlsx, ReadMe.pdf, and IRB_Approval.pdf in the outer zip.
> What could not be verified.  The package ships no logs or output and the do-files were not run; the cross-check above is an independent re-estimate.  No working paper was found, so publication_date is the EJ Advance Access date.
> Original analysis in Stata (three do-files); language is r, the reproduction target (the pipeline translates Stata originals to R, as for alesina-2022).
> First run 2026-10-21 (Phase 3.2 evaluation pass; main 0492c17, after the content-aware strip rule and the printed-precision floor; Opus 4.7, 47-package image, LLM cache on, --mode all, one run per mode; eval-7papers-all-modes-2026-10-21.json).  Seeded 11 / 11 and independent 9 / 11, both on the first script (first scored 11 and 9; independent 1 claim refinement that moved nothing): independent missed friendliness_full_sample (NA) and station_visits_five_station_subsample (87 vs 102).  Blind 4 / 11 (first scored 4): without targets the model chose different test statistics / sample for the friendliness, Brown-Forsythe and ANOVA rows; the two passerby and two shuttle-stop rows pass, the two station-visit counts do not (239 vs 242, 87 vs 102).  First run with the content-aware strip rule (6 files stripped; the old name-based rule had left the do-files on the mount).

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `passersby_full_sample` | 0.005 | 0.001 | Table 2, column (1) Full sample, Number of passersby | 0.005 | matches |
| 1 | `passersby_five_station_subsample` | 0.006 | 0.002 | Table 2, column (2) Five-station subsample, Number of passersby | 0.006 | matches |
| 2 | `friendliness_full_sample` | 1.595 | 0.851 | Table 2, column (1) Full sample, Passerby friendliness | 1.595 | matches |
| 3 | `shuttle_stop_full_sample` | 0.781 | 0.182 | Table 2, column (1) Full sample, Homeless shuttle stop | 0.781 | matches |
| 4 | `shuttle_stop_five_station_subsample` | 0.89 | 0.227 | Table 2, column (2) Five-station subsample, Homeless shuttle stop | 0.89 | matches |
| 5 | `brown_forsythe_donations_per_hour` | 0.541 | — | Table 3, Panel A: donations per hour, Brown-Forsythe W-statistic | 0.541 | matches |
| 6 | `brown_forsythe_dollars_per_hour` | 0.276 | — | Table 3, Panel B: dollars per hour, Brown-Forsythe W-statistic | 0.276 | matches |
| 7 | `anova_f_donations_per_hour` | 0.4 | — | Table 4, Panel A: donations per hour, ANOVA F-statistic | 0.4 | matches |
| 8 | `anova_f_dollars_per_hour` | 0.15 | — | Table 4, Panel B: dollars per hour, ANOVA F-statistic | 0.15 | matches |
| 9 | `station_visits_full_sample` | 242 | — | Table 2, column (1), Observations | 242 | matches |
| 10 | `station_visits_five_station_subsample` | 102 | — | Table 2, column (2), Observations | 102 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [11/11](seeded/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b) | [11/11](independent/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b)<br>[11/11](independent/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) | [11/11](blind/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b)<br>[11/11](blind/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) |
| `pipeline-claude-opus-4-7` | [11/11](seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) | [9/11](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) | [4/11](blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) |
| `pipeline-claude-opus-5-5` | [11/11](seeded/pipeline-claude-opus-5-5/20261022T044925Z/CELL.md) (20261022T044925Z) | [11/11](independent/pipeline-claude-opus-5-5/20261022T044925Z/CELL.md) (20261022T044925Z) | [8/11](blind/pipeline-claude-opus-5-5/20261022T044925Z/CELL.md) (20261022T044925Z) |
| `pipeline-desktop-opus-run2` | [11/11](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) (20261023T151837Z) | [8/11](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) (20261023T153002Z) | [7/11](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) (20261023T150832Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [independent/pipeline-claude-opus-4-7/20261021T142909Z](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `passersby_five_station_subsample` | 0.007827 | 0.006 | ±0.002 (se_band) | 0.914 | PASS |
| [blind/pipeline-claude-opus-4-7/20261021T142909Z](blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `passersby_full_sample` | 0.004102 | 0.005 | ±0.001 (se_band) | 0.898 | PASS |
| [blind/pipeline-claude-opus-5-5/20261022T044925Z](blind/pipeline-claude-opus-5-5/20261022T044925Z/CELL.md) | `station_visits_full_sample` | 240 | 242 | ±2.42 (relative) | 0.826 | PASS |
| [blind/pipeline-desktop-opus-run2/20261023T150832Z](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) | `station_visits_full_sample` | 240 | 242 | ±2.42 (relative) | 0.826 | PASS |
| [blind/pipeline-claude-opus-4-7/20261021T142909Z](blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `station_visits_full_sample` | 239 | 242 | ±2.42 (relative) | 1.240 | FAIL |
| [independent/pipeline-claude-opus-4-7/20261021T142909Z](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `shuttle_stop_five_station_subsample` | 1.05492 | 0.89 | ±0.227 (se_band) | 0.727 | PASS |
| [independent/pipeline-desktop-opus-run2/20261023T153002Z](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) | `passersby_full_sample` | 0.00435164 | 0.005 | ±0.001 (se_band) | 0.648 | PASS |
| [blind/pipeline-desktop-opus-run2/20261023T150832Z](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) | `shuttle_stop_full_sample` | 0.674967 | 0.781 | ±0.182 (se_band) | 0.583 | PASS |
| [independent/pipeline-claude-opus-4-7/20261021T142909Z](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `shuttle_stop_full_sample` | 0.674967 | 0.781 | ±0.182 (se_band) | 0.583 | PASS |
| [blind/pipeline-desktop-opus-run2/20261023T150832Z](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) | `passersby_five_station_subsample` | 0.00689613 | 0.006 | ±0.002 (se_band) | 0.448 | PASS |

### Declared deviations

- [independent/pipeline-claude-opus-5-5/20261022T044925Z](independent/pipeline-claude-opus-5-5/20261022T044925Z/CELL.md) (11/11)
  - Singleton date fixed-effect groups retained (fixef.rm='none') to match paper's Stata-style N
  - Dollars-per-hour sample definition (needboth, raw) selected among plausible coding rules to match paper's N=67
- [blind/claude-code/2026-10-21-b](blind/claude-code/2026-10-21-b/CELL.md) (11/11)
  - Homeless service / shuttle-stop indicators coded as walking time <= 10 minutes from service.csv / shuttle.csv (paper: 'within a ten-minute walk').
  - Passerby friendliness = highest response category (1-5) marked for each passerby, averaged over all passersby surveyed at the station (station-level constant).
  - Dollars per hour = (cash + inkind)/minutes*60, missing if either cash or inkind is missing (gives the 67 observations the paper describes).
  - Brown-Forsythe = Levene test centred on the median (car::leveneTest, center=median); ANOVA = one-way lm F test.
  - Table 2 estimated with fixest feols, date fixed effects, SEs clustered by station, fixef.rm='none' so date-singleton visits stay in the sample (equivalent to OLS with date dummies; point estimates unaffected).

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- blind: `anova_f_dollars_per_hour` — pipeline 0/3, agent 2/2
- blind: `brown_forsythe_dollars_per_hour` — pipeline 0/3, agent 2/2
- blind: `station_visits_five_station_subsample` — pipeline 0/3, agent 2/2

Pass rates at least 50 points apart (not unanimous):

- independent: `friendliness_full_sample` — pipeline 1/3, agent 2/2
- blind: `friendliness_full_sample` — pipeline 1/3, agent 2/2

## Cells

### seeded · claude-code · 2026-10-21-b

[`seeded/claude-code/2026-10-21-b/CELL.md`](seeded/claude-code/2026-10-21-b/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 1; 2026-10-22T02:03:30Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### seeded · pipeline-claude-opus-4-7 · 20261021T142909Z

[`seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 1; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### seeded · pipeline-claude-opus-5-5 · 20261022T044925Z

[`seeded/pipeline-claude-opus-5-5/20261022T044925Z/CELL.md`](seeded/pipeline-claude-opus-5-5/20261022T044925Z/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 1; 2026-10-22T04:49:25Z; from `pipeline-opus55-4papers-all-modes-2026-10-22.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261023T151837Z

[`seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 1; 2026-10-23T15:18:37Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### independent · claude-code · 2026-10-21-b

[`independent/claude-code/2026-10-21-b/CELL.md`](independent/claude-code/2026-10-21-b/CELL.md) — final 11/11, re-scored 11/11; first scored 10/11; executions 2; 2026-10-22T02:07:52Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### independent · claude-code · 2026-11-01-a

[`independent/claude-code/2026-11-01-a/CELL.md`](independent/claude-code/2026-11-01-a/CELL.md) — final 11/11, re-scored 11/11; first scored 10/11; executions 3; 2026-11-02T04:27:00Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### independent · pipeline-claude-opus-4-7 · 20261021T142909Z

[`independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 9/11, re-scored 9/11; first scored 9/11; executions 2; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### independent · pipeline-claude-opus-5-5 · 20261022T044925Z

[`independent/pipeline-claude-opus-5-5/20261022T044925Z/CELL.md`](independent/pipeline-claude-opus-5-5/20261022T044925Z/CELL.md) — final 11/11, re-scored 11/11; first scored 8/11; executions 3; 2026-10-22T04:49:25Z; from `pipeline-opus55-4papers-all-modes-2026-10-22.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261023T153002Z

[`independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) — final 8/11, re-scored 8/11; first scored 7/11; executions 4; 2026-10-23T15:30:02Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### blind · claude-code · 2026-10-21-b

[`blind/claude-code/2026-10-21-b/CELL.md`](blind/claude-code/2026-10-21-b/CELL.md) — final 11/11, re-scored 11/11; first scored 10/11; executions 3; 2026-10-22T02:12:41Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### blind · claude-code · 2026-11-01-a

[`blind/claude-code/2026-11-01-a/CELL.md`](blind/claude-code/2026-11-01-a/CELL.md) — final 11/11, re-scored 11/11; first scored 10/11; executions 3; 2026-11-02T04:21:30Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### blind · pipeline-claude-opus-4-7 · 20261021T142909Z

[`blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 4/11, re-scored 4/11; first scored 4/11; executions 1; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### blind · pipeline-claude-opus-5-5 · 20261022T044925Z

[`blind/pipeline-claude-opus-5-5/20261022T044925Z/CELL.md`](blind/pipeline-claude-opus-5-5/20261022T044925Z/CELL.md) — final 8/11, re-scored 8/11; first scored 8/11; executions 1; 2026-10-22T04:49:25Z; from `pipeline-opus55-4papers-all-modes-2026-10-22.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261023T150832Z

[`blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) — final 7/11, re-scored 7/11; first scored 7/11; executions 1; 2026-10-23T15:08:32Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

