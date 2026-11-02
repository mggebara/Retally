# Evidence report: hanlon-2022-aircraft-ip-spillovers

**Spillover Effects of Intellectual Property Protection in the Interwar Aircraft Industry** — Walker Hanlon, Taylor Jaworski

- Paper: https://www.nber.org/system/files/working_papers/w26490/w26490.pdf
- I4R report: https://github.com/I4Replication/I4R-First-Meta-Paper
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/hanlon-2022-aircraft-ip-spillovers.yaml`

> Headline finding: after the 1926 change gave U.S. airframe producers property rights over new designs, U.S. fighter and bomber airframe performance grew much faster (wing load about 1.3% a year before 1926 vs 7.4% after; maximum speed -0.1% vs 6.7%), the acceleration survives a comparison with the U.K., and aero-engine performance growth slowed (U.S. horsepower per pound 3.9% a year before vs -1.0% after).
> Original analysis in Stata (15.1 do-files); language: r is the reproduction target, as for alesina-2022 and dincecco-2022.
> Curation pass (2026-10-21).  Pinned 12 claims: the before/after-1926 spline slopes of Table 1 columns 1-4 (the four airframe regressions without engine controls) and Table 4 column 1 (U.S.-only horsepower per pound, the engine measure the paper calls most relevant), each with its robust SE in standard_error, and the two matching observation counts (116, 85).  The I4R rows cover only Table 1, so columns 1-4 have direct per-claim replicator values; Table 4 rests on the blanket verdict.
> Working-paper caveat.  paper.source is NBER w26490 ("Revised September 2021"), not the EJ text.  Its Table 1 and Table 4 are identical to the package's accepted manuscript (MS20201110_main.tex, 2021-10-06, same table numbers), to the package's own tables/Table1_*.tex and Table4_*.tex, and (for Table 1) to the meta-database's o_coeff / o_std_err (the replicators' record of the published values).  The EJ print version itself (paywalled, 403) was not seen.
> Left out.  Table 1 columns 5-6 (adds an indicator for more than one engine and log engine horsepower): the I4R R recode got 0.004 (0.010) and 0.020 (0.008) for column 5 vs the paper's -0.005 (0.010) and 0.023 (0.010), and -0.025 (0.010) / 0.025 (0.010) for column 6 vs -0.031 (0.009) / 0.024 (0.009), yet the database still records a perfect reproduction.  The likely cause is package-only: the do-file builds the multi-engine indicator as no_engines > 1, which Stata evaluates as true for a missing no_engines (11 of the 330 U.S./U.K. fighter-bomber rows), so Stata keeps 140 / 192 observations where an R recode dropping missings keeps 139 / 191.  A pinned claim that depends on Stata's missing-value ordering would penalise a correct R reproduction, so these columns are not pinned.  Also left out (12-claim target): Table 4 columns 2-6 (horsepower per displacement and per frontal area, and the U.S.-U.K. engine comparison, whose column 4 after-1926 slope is -0.048 (0.008), N 123), the F-statistics and p-values of the equality tests, Table 2 (liquid-cooled shares, descriptive), and Table 3 (adoption lag; column 2's interaction is only marginally significant).
> Package structure (package-only facts; never in contexts).  Stata 15.1; ssc packages keeporder, estout (README also lists grc1leg, pspline). Run order: do/1-data-airframes.do, 1-data-engines.do, 1-data-vintage.do (build data/dta/*.dta from data/raw/*.csv), then do/2-results-main.do (Figures 1-2, Tables 1-4) and 3-results-appendix.do.  The path is a commented-out global ($aircraft).  Table 1 (2-results-main.do lines ~246-400): use airframe_data.dta, keep country United States / United Kingdom and type fighter / bomber, mkspline pre1926 1926 post1926 = year, pre1926_US = US*pre1926, post1926_US = US*post1926; reg ln_wingload / ln_maxspeed pre1926_US post1926_US if US==1, vce(r) (cols 1-2); reg ... pre1926* post1926* US, vce(r) (cols 3-4); adding ln_enginehp and engines (cols 5-6).  Table 4 (lines ~507-600): engine_data.dta, keep US / UK, same spline, reg ln_hp_per_lbs pre1926_US post1926_US liquid_cooled if US, vce(r).  Note mkspline puts 1926 itself in the before segment.  Checked from the shipped .dta (read only, no code run): the U.S. fighter-bomber airframe sample has 116 non-missing ln_wingload and 174 ln_maxspeed, the pooled sample 165 / 233, and engine_data.dta has 85 U.S. / 123 U.S.+U.K. engines with ln_hp_per_lbs, matching every printed N.  Years run 1918-1935.  The unpacked directory contains the answers (tables/*.tex, the accepted manuscript .tex/.pdf).  Up to 2026-11-01 script_free_copy kept the four manuscript / online-appendix PDFs (1 paper/MS20201110_accepted.pdf, _main.pdf, _online_appendix.pdf; 2 appendix/MS20201110_online_appendix.pdf), so independent and blind runs relied on the prompt's instruction not to read them.
> Strip-rule update (2026-11-01, with brouwer-2022-teaching-norms): PDFs with a page that reads as a regression table are now withheld, so the four PDFs above leave the independent / blind mount (MS20201110_main.tex is withheld as a regression table on current main too).  Every earlier independent / blind run of this entry, up to and including the 2026-11-01-a agent sample and the run2 oracle sample, had them on the mount; the agents' own reports for those cells say they read only the .dta files.  The split esttab fragments under 3 replication files/tables/ (Table1_R.tex, Table1_N.tex, Table4_R.tex, ...: coefficient, SE, observation, F and p-value rows with no tabular or Observations label), which print the pinned Table 1 and Table 4 values, are withheld as table-fragment from 2026-11-01 (27 files, Appendix E fragments included; the descriptive Table2_PRE/POST and TableF1_match_* stay); they were on every independent / blind mount before.
> First run 2026-10-21 (Phase 3.2 evaluation pass; main 0492c17, after the content-aware strip rule and the printed-precision floor; Opus 4.7, 47-package image, LLM cache on, --mode all, one run per mode; eval-7papers-all-modes-2026-10-21.json).  Seeded 12 / 12 and blind 12 / 12, both exact on the first script (first scored 12; blind after 1 error repair); independent 10 / 12 (first scored 10; 1 claim refinement): the two Table 4 US max-speed trend claims off (-0.0082 vs -0.001, 0.075 vs 0.067).  Blind > independent here is single-run noise, not a finding.  11 files stripped from the independent / blind mount by the content-aware rule.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `airframe_wingload_trend_before_1926_us` | 0.013 | 0.006 | Table 1, column 1 (United States Only, Wing Load), Before 1926 x year x US | 0.013 | matches |
| 1 | `airframe_wingload_trend_after_1926_us` | 0.074 | 0.006 | Table 1, column 1 (United States Only, Wing Load), After 1926 x year x US | 0.074 | matches |
| 2 | `airframe_maxspeed_trend_before_1926_us` | -0.001 | 0.006 | Table 1, column 2 (United States Only, Maximum Speed), Before 1926 x year x US | -0.001 | matches |
| 3 | `airframe_maxspeed_trend_after_1926_us` | 0.067 | 0.006 | Table 1, column 2 (United States Only, Maximum Speed), After 1926 x year x US | 0.067 | matches |
| 4 | `airframe_wingload_trend_before_1926_us_vs_uk` | 0.004 | 0.009 | Table 1, column 3 (Comparison of US and UK, Wing Load), Before 1926 x year x US | 0.004 | matches |
| 5 | `airframe_wingload_trend_after_1926_us_vs_uk` | 0.025 | 0.01 | Table 1, column 3 (Comparison of US and UK, Wing Load), After 1926 x year x US | 0.025 | matches |
| 6 | `airframe_maxspeed_trend_before_1926_us_vs_uk` | -0.028 | 0.009 | Table 1, column 4 (Comparison of US and UK, Maximum Speed), Before 1926 x year x US | -0.028 | matches |
| 7 | `airframe_maxspeed_trend_after_1926_us_vs_uk` | 0.031 | 0.01 | Table 1, column 4 (Comparison of US and UK, Maximum Speed), After 1926 x year x US | 0.031 | matches |
| 8 | `engine_hp_per_weight_trend_before_1926_us` | 0.039 | 0.009 | Table 4, column 1 (United States Only, HP / Weight), Before 1926 x year x US | 0.039 | matches |
| 9 | `engine_hp_per_weight_trend_after_1926_us` | -0.01 | 0.005 | Table 4, column 1 (United States Only, HP / Weight), After 1926 x year x US | -0.01 | matches |
| 10 | `observations_airframe_wingload_us` | 116 | — | Table 1, column 1, observations | 116 | matches |
| 11 | `observations_engine_us` | 85 | — | Table 4, column 1, observations | 85 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [12/12](seeded/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b)<br>[12/12](seeded/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) | [12/12](independent/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b)<br>[12/12](independent/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) | [12/12](blind/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b)<br>[12/12](blind/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) |
| `pipeline-claude-opus-4-7` | [12/12](seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) | [10/12](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) | [12/12](blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) |
| `pipeline-desktop-opus` | [12/12](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) (20261023T063725Z) | [12/12](independent/pipeline-desktop-opus/20261023T062931Z/CELL.md) (20261023T062931Z) | [12/12](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) (20261023T062931Z) |
| `pipeline-desktop-opus-run2` | [12/12](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) (20261023T151837Z) | [12/12](independent/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) (20261023T150832Z) | [12/12](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) (20261023T150832Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [seeded/pipeline-desktop-opus/20261023T063725Z](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) | `airframe_wingload_trend_before_1926_us` | 0.0134392 | 0.013 | ±0.0005 (printed_precision) | 0.878 | PASS |
| [seeded/claude-code/2026-10-21-b](seeded/claude-code/2026-10-21-b/CELL.md) | `airframe_wingload_trend_before_1926_us` | 0.013439 | 0.013 | ±0.0005 (printed_precision) | 0.878 | PASS |
| [seeded/claude-code/2026-11-02-b](seeded/claude-code/2026-11-02-b/CELL.md) | `airframe_wingload_trend_before_1926_us` | 0.013439 | 0.013 | ±0.0005 (printed_precision) | 0.878 | PASS |
| [seeded/pipeline-claude-opus-4-7/20261021T142909Z](seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `airframe_wingload_trend_before_1926_us` | 0.013439 | 0.013 | ±0.0005 (printed_precision) | 0.878 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261023T151837Z](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) | `airframe_wingload_trend_before_1926_us` | 0.013439 | 0.013 | ±0.0005 (printed_precision) | 0.878 | PASS |
| [independent/pipeline-claude-opus-4-7/20261021T142909Z](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `airframe_maxspeed_trend_before_1926_us` | -0.0082 | -0.001 | ±0.006 (se_band) | 1.200 | FAIL |
| [seeded/pipeline-desktop-opus/20261023T063725Z](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) | `airframe_maxspeed_trend_after_1926_us_vs_uk` | 0.0305485 | 0.031 | ±0.00062 (relative) | 0.728 | PASS |
| [seeded/claude-code/2026-10-21-b](seeded/claude-code/2026-10-21-b/CELL.md) | `airframe_maxspeed_trend_after_1926_us_vs_uk` | 0.030549 | 0.031 | ±0.00062 (relative) | 0.727 | PASS |
| [seeded/claude-code/2026-11-02-b](seeded/claude-code/2026-11-02-b/CELL.md) | `airframe_maxspeed_trend_after_1926_us_vs_uk` | 0.030549 | 0.031 | ±0.00062 (relative) | 0.727 | PASS |
| [seeded/pipeline-claude-opus-4-7/20261021T142909Z](seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `airframe_maxspeed_trend_after_1926_us_vs_uk` | 0.030549 | 0.031 | ±0.00062 (relative) | 0.727 | PASS |

### Declared deviations

- [independent/pipeline-claude-opus-4-7/20261021T142909Z](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (10/12; failed: `airframe_maxspeed_trend_before_1926_us`, `airframe_maxspeed_trend_after_1926_us`)
  - Reparameterized the US max-speed spline using separate pre/post slope regressors (clamped at 1926) instead of the continuous-kink parameterization, to better match the paper reported pre and post slopes.
- [blind/claude-code/2026-10-21-b](blind/claude-code/2026-10-21-b/CELL.md) (12/12)
  - Engine sample: engine_data.dta taken as the paper's fighter/bomber engine file (it carries airframe-matched counts); US rows with non-missing ln_hp_per_lbs used without further filtering (85 engines). The paper text does not spell out how the file was built.
  - Spline: continuous two-piece linear spline in Stata mkspline form, before = min(year,1926), after = max(year-1926,0), so 1926 belongs to the before segment and the coefficients are segment slopes, not slope changes.
  - Equation (5) parameterized as a constant, a US indicator, a baseline spline on all observations (the UK/comparison slope) and spline x US (US slope minus UK slope).
- [blind/pipeline-desktop-opus/20261023T062931Z](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) (12/12)
  - none; filtered to fighter/bomber types

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

_None._

## Cells

### seeded · claude-code · 2026-10-21-b

[`seeded/claude-code/2026-10-21-b/CELL.md`](seeded/claude-code/2026-10-21-b/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-22T02:03:30Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### seeded · claude-code · 2026-11-02-b

[`seeded/claude-code/2026-11-02-b/CELL.md`](seeded/claude-code/2026-11-02-b/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-02T19:35:30Z; from `claude-code-run2-23papers-seeded-2026-11-02.json`; evidence complete.

### seeded · pipeline-claude-opus-4-7 · 20261021T142909Z

[`seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261023T063725Z

[`seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md`](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-23T06:37:25Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261023T151837Z

[`seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-23T15:18:37Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### independent · claude-code · 2026-10-21-b

[`independent/claude-code/2026-10-21-b/CELL.md`](independent/claude-code/2026-10-21-b/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-10-22T02:07:25Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### independent · claude-code · 2026-11-01-a

[`independent/claude-code/2026-11-01-a/CELL.md`](independent/claude-code/2026-11-01-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-11-02T04:26:09Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### independent · pipeline-claude-opus-4-7 · 20261021T142909Z

[`independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 10/12, re-scored 10/12; first scored 10/12; executions 2; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261023T062931Z

[`independent/pipeline-desktop-opus/20261023T062931Z/CELL.md`](independent/pipeline-desktop-opus/20261023T062931Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-23T06:29:31Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261023T150832Z

[`independent/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-23T15:08:32Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### blind · claude-code · 2026-10-21-b

[`blind/claude-code/2026-10-21-b/CELL.md`](blind/claude-code/2026-10-21-b/CELL.md) — final 12/12, re-scored 12/12; first scored 8/12; executions 3; 2026-10-22T02:12:14Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### blind · claude-code · 2026-11-01-a

[`blind/claude-code/2026-11-01-a/CELL.md`](blind/claude-code/2026-11-01-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-11-02T04:21:00Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### blind · pipeline-claude-opus-4-7 · 20261021T142909Z

[`blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261023T062931Z

[`blind/pipeline-desktop-opus/20261023T062931Z/CELL.md`](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-23T06:29:31Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261023T150832Z

[`blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-23T15:08:32Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

