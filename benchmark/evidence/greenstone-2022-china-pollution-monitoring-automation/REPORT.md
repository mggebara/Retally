# Evidence report: greenstone-2022-china-pollution-monitoring-automation

**Can Technology Solve the Principal-Agent Problem? Evidence from China's War on Air Pollution** — Michael Greenstone, Guojun He, Ruixue Jia, Tong Liu

- Paper: https://www.nber.org/system/files/working_papers/w27502/w27502.pdf
- I4R report: https://www.econstor.eu/bitstream/10419/289782/1/I4R-DP113.pdf
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/greenstone-2022-china-pollution-monitoring-automation.yaml`
- Data access: manual (package downloaded by hand and placed at `benchmark/manual-packages/T9/125321-V1.zip`; AEA Data and Code Repository on openICPSR, project 125321, version V1 (doi:10.3886/E125321V1); login and terms-of-use click-through required, so the zip was downloaded by hand (2026-11-09) and placed unchanged at benchmark/manual-packages/T9/125321-V1.zip (125,741,529 bytes, md5 3e86d0601fdb93d205278e59d1224dda; SOURCE.txt beside it).  V1 is the only version.  71 entries, 241 MB uncompressed, no nested archives, all under China_Pollution_Monitoring/ plus a top-level README.pdf (3 pp.; data sources, file-to-table map, software and packages, run time, no estimates).  Data/ (Stata .dta): pollution_1116.dta (40 MB, station-day PM10 / SO2 / NO2), weather_1116.dta (29 MB, station-day temperature, rain, humidity, wind speed), station_list.dta (stations with city, wave and automation date), aod_month.dta (station-month AOD), mask_filter_search.dta (city-day Baidu search indices), city_info.dta, search_sale.dta, pm10_corrected_reference.dta (the authors' neural-net corrected PM10, appendix), and pollution.csv (78 MB, the raw scraped CSV); Data/temp/ is empty.  Code/ has six Stata do-files (MASTER.do, Prepare_Data.do, Tables.do, Figures.do, FS.do, TS.do) and Ado/brain.ado.  Results/figures/ holds only ArcGIS map inputs for Figures A1 and B5 (.mxd documents and shapefiles with city / station attributes and no estimates; the two 27 MB .shp are city polygons); no tables, logs or figure outputs ship.  The script-free copy (independent / blind) withholds the 7 scripts by suffix (6 .do, 1 .ado; benchmark.strip_rule.classify_tree on the extracted package, 2026-11-09); everything else stays, none of it printing a pinned value.  Project page: https://www.openicpsr.org/openicpsr/project/125321/version/V1/view)

> Headline findings: reported PM10 jumped at automation by 34.9 (5.8) ug/m3 with station FE, month FE and weather controls (Table 1 Panel A col 2; 34.7 (10.7) without; the text's "35 percent" relative to the post-automation mean of 99.5), 27.5 (9.8) in Wave 1, 64.7 (9.9) in Wave 2 and 57.1 (8.6) in deadline cities, with no jump in satellite AOD (-0.005 (0.021), col 2).  Event study (Panel B) 1-2 months after automation: 60.3 (11.0) deadline sample with month FE, 31.4 (11.1) with year-month FE, 66.5 (14.3) matched, 0.24 (0.09) log PM10 matched; N 176,426 in cols 1-2.  Searches (Table 2 Panel A col 2): face masks 11.03 (1.66), air filters 8.73 (1.86).
> Paper text and how it was verified.  The published AER: Insights article could not be read (paywalled; no open repository copy reachable from scripts, see the header).  The catalog source is NBER WP 27502 (July 2020).  Its Table 1 equals the published Table 1 in every printed number checked: all 10 Panel A coefficients and SEs, the Obs. and Bandwidth rows, all 35 Panel B coefficients with SEs and the Panel B Obs. row are identical to DP113's "Panel a. Original" blocks (DP Table 2 and Table 4; token-by-token comparison of the extracted text, 2026-11-09), which the DP labels as the original paper's Table 1 (the DP block also prints a Constant row the WP omits), and every pinned value / SE equals a meta-database o_coeff_dbl / o_std_err_dbl row (34.7/10.7, 34.9/5.8, 27.5/9.8, 64.7/9.9, 57.1/8.6, -0.005/0.021, 60.3/11.0, 31.4/11.1, 66.5/14.3, 0.24/0.09, 11.03/1.66, 8.73/1.86).  The WP's Table 3 is the published Table 2: columns 1-2 of Panel A are identical to DP Table 7 Panel a (10.10, 11.03, 7.36, 8.73, 1.06, 1.15, 0.18, 0.16 with SEs), but columns 3-4 (normal vs manipulating cities) differ from the published values (WP 7.18 / 15.43 for face masks vs published 6.46 / 18.77), so the published version changed the manipulating-city split; those columns are not pinned.  The R-squared row differs only in rounding (WP 0.34, DP 0.3).  The WP's Table 2 (city characteristics) is not a main table of the published article.  The contexts use the WP's wording; the published table titles are taken from DP113 ("Automating Air Quality Monitoring System and Avoidance Behaviors" for Table 2).  The claim text writes the pollutant as "PM₁₀" (Unicode subscript digits) and the descriptions as "pm": the leak checks read "PM10" as a stated "10", which is the one-figure rounding of several pinned values and SEs (9.8, 9.9, 10.7, 11.03).
> Curation pass (2026-11-09).  13 claims.  Left out: Panel A columns 1, 3-5 of the AOD row (placebo nulls; column 2 kept), the Obs. / Bandwidth rows (data-driven bandwidths), the pre-period event-study coefficients, the 3-4 / 5-6 / 7-12 months after coefficients, Table 2 columns 1, 3, 4 and the log-search rows, Table 2 Panel B (search event study; the meta-database's SE column for it holds p-value-like numbers such as 1.56e-05), and all appendix tables.
> Package-only facts (never in contexts).  Code/Tables.do, "Table 1A": station_day_1116 = pollution_1116.dta merged 1:1 with weather_1116.dta on station_n date, then station_list.dta on pm10_n (Prepare_Data.do step 1); T = date - auto_date; reghdfe pm10 wind_speed rain temp rh, absorb(pm10_n month) res(); rdrobust <y> T, c(0) p(1) q(2) kernel(tri) vce(cluster code_city) masspoints(off) — col 1 on raw pm10 restricted to non-missing weather, cols 2-5 on the residual, col 3 phase==1, col 4 phase==2, col 5 auto_date==19359 | 19724 (2013-01-01 / 2014-01-01). AOD row on station_month.dta (station-month means of the daily file merged with aod_month.dta, running variable n_month).  Obs. is e(N_h_l)+e(N_h_r), bandwidth floor(e(h_l)).  "Table 1B": years 2012-2013, deadline stations, treat = auto_date==19359, period dummies m712/m56/m34 before (Jan-Jun, Jul-Aug, Sep-Oct 2012), m12/m34/m56/m712 after (2013), reference Nov-Dec 2012; reghdfe pm10 treat_m* wind_speed rain temp rh, absorb(pm10_n month) or absorb(pm10_n year_month), vce(cluster code_city).  Matching (did_ddl_match.dta): geonear each Wave 1 deadline station to its nearest Wave 2 deadline station (ellipsoid), keep pairs within 400 km, joinby so control stations repeat (the 400 km cap is not in the paper).  "Table 2A": search_city_month.dta = city-day means of station_day_1116 merged with mask_filter_search.dta, averaged by code_city x n_month (months from automation); reghdfe pmmask / filter on weather, absorb(code_city month), rdrobust on the residual over n_month with the same options. Columns 3-4 use a city RD flag built in Prepare_Data.do from city-by-city RDs.  The neural-net PM10 correction (brain.ado) is appendix-only.  README states Stata/MP 15, 10-40 minutes.
> Blind-mode exposure (step 6, 2026-11-09).  The blind generation prompt states no pinned value or SE at printed precision.  It does carry the abstract's first 500 characters, which say reported PM10 "increased by 35%" — a percentage of the post-automation mean, not the pinned coefficient, but numerically the two-figure rounding of the headline 34.9 (and of 34.7); the README's blind-mode caveat covers this.  The paper parser takes the WP cover line "NBER WORKING PAPER SERIES" as the title.
> What was read.  NBER WP 27502 in full through the main tables (pp. 1-22), the BFI WP title pages; DP113 in full; the 271 meta-database rows; README.pdf; Tables.do and the relevant parts of Prepare_Data.do; the strip-rule classification of the extracted package; the attribute tables of the shipped shapefiles.
> What could not be verified.  The published article itself (pages, notes wording) was not read.  The authors' Stata code was not run (no Stata here) and no independent R cross-check was made in this pass.
> Original analysis in Stata 15 MP (ArcGIS 10.3 for maps); language: r is the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `rd_pm_daily_no_controls_table1_panelA_col1` | 34.7 | 10.7 | Table 1, Panel A (RD Estimates), RD in PM₁₀ (Daily), column (1) | 34.7 | matches |
| 1 | `rd_pm_daily_controls_table1_panelA_col2` | 34.9 | 5.8 | Table 1, Panel A (RD Estimates), RD in PM₁₀ (Daily), column (2) | 34.9 | matches |
| 2 | `rd_pm_daily_wave1_table1_panelA_col3` | 27.5 | 9.8 | Table 1, Panel A (RD Estimates), RD in PM₁₀ (Daily), column (3) Wave 1 | 27.5 | matches |
| 3 | `rd_pm_daily_wave2_table1_panelA_col4` | 64.7 | 9.9 | Table 1, Panel A (RD Estimates), RD in PM₁₀ (Daily), column (4) Wave 2 | 64.7 | matches |
| 4 | `rd_pm_daily_deadline_table1_panelA_col5` | 57.1 | 8.6 | Table 1, Panel A (RD Estimates), RD in PM₁₀ (Daily), column (5) Deadline | 57.1 | matches |
| 5 | `rd_aod_monthly_controls_table1_panelA_col2` | -0.005 | 0.021 | Table 1, Panel A (RD Estimates), RD in AOD, column (2) | -0.005 | matches |
| 6 | `event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1` | 60.3 | 11 | Table 1, Panel B (Event-Study Estimates), 1-2 Months after, column (1) | 60.3 | matches |
| 7 | `event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2` | 31.4 | 11.1 | Table 1, Panel B (Event-Study Estimates), 1-2 Months after, column (2) | 31.4 | matches |
| 8 | `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3` | 66.5 | 14.3 | Table 1, Panel B (Event-Study Estimates), 1-2 Months after, column (3) +Matching | 66.5 | matches |
| 9 | `event_study_log_pm_1_2_months_after_matched_table1_panelB_col5` | 0.24 | 0.09 | Table 1, Panel B (Event-Study Estimates), 1-2 Months after, column (5) Log(PM₁₀) | 0.24 | matches |
| 10 | `n_obs_table1_panelB_deadline_cols1_2` | 176426 | — | Table 1, Panel B, Obs., columns (1)-(2) | 176426 | matches |
| 11 | `rd_face_mask_searches_controls_table2_panelA_col2` | 11.03 | 1.66 | Table 2 (NBER WP Table 3), Panel A (RD Estimates), RD in Face Mask Searches, column (2) | 11.03 | matches |
| 12 | `rd_air_filter_searches_controls_table2_panelA_col2` | 8.73 | 1.86 | Table 2 (NBER WP Table 3), Panel A (RD Estimates), RD in Air Filter Searches, column (2) | 8.73 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[13/13](seeded/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b) | [12/13](independent/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[12/13](independent/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[13/13](independent/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[12/13](independent/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) | [12/13](blind/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[12/13](blind/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[12/13](blind/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[11/13](blind/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) |
| `pipeline-desktop-opus` | [13/13](seeded/pipeline-desktop-opus/20261110T055807Z/CELL.md) (20261110T055807Z) | [13/13](independent/pipeline-desktop-opus/20261110T061446Z/CELL.md) (20261110T061446Z) | [10/13](blind/pipeline-desktop-opus/20261110T055406Z/CELL.md) (20261110T055406Z) |
| `pipeline-desktop-opus-run2` | [13/13](seeded/pipeline-desktop-opus-run2/20261110T060636Z/CELL.md) (20261110T060636Z) | [13/13](independent/pipeline-desktop-opus-run2/20261110T061535Z/CELL.md) (20261110T061535Z) | [10/13](blind/pipeline-desktop-opus-run2/20261110T060037Z/CELL.md) (20261110T060037Z) |
| `pipeline-desktop-opus-run3` | [13/13](seeded/pipeline-desktop-opus-run3/20261110T060758Z/CELL.md) (20261110T060758Z) | [13/13](independent/pipeline-desktop-opus-run3/20261110T061323Z/CELL.md) (20261110T061323Z) | [10/13](blind/pipeline-desktop-opus-run3/20261110T055857Z/CELL.md) (20261110T055857Z) |
| `pipeline-desktop-opus-run4` | — | [12/13](independent/pipeline-desktop-opus-run4/20261110T062806Z/CELL.md) (20261110T062806Z) | [11/13](blind/pipeline-desktop-opus-run4/20261110T063528Z/CELL.md) (20261110T063528Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) | `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3` | 51.8279 | 66.5 | ±14.3 (se_band) | 1.026 | FAIL |
| [independent/claude-code/2026-11-10-a](independent/claude-code/2026-11-10-a/CELL.md) | `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3` | 51.8279 | 66.5 | ±14.3 (se_band) | 1.026 | FAIL |
| [blind/claude-code/2026-11-10-a](blind/claude-code/2026-11-10-a/CELL.md) | `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3` | 51.8279 | 66.5 | ±14.3 (se_band) | 1.026 | FAIL |
| [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) | `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3` | 51.8279 | 66.5 | ±14.3 (se_band) | 1.026 | FAIL |
| [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) | `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3` | 51.8279 | 66.5 | ±14.3 (se_band) | 1.026 | FAIL |
| [independent/claude-code/2026-11-10-b](independent/claude-code/2026-11-10-b/CELL.md) | `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3` | 51.8279 | 66.5 | ±14.3 (se_band) | 1.026 | FAIL |
| [independent/claude-code/2026-11-10-d](independent/claude-code/2026-11-10-d/CELL.md) | `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3` | 51.8279 | 66.5 | ±14.3 (se_band) | 1.026 | FAIL |
| [blind/pipeline-desktop-opus-run3/20261110T055857Z](blind/pipeline-desktop-opus-run3/20261110T055857Z/CELL.md) | `event_study_log_pm_1_2_months_after_matched_table1_panelB_col5` | 0.145186 | 0.24 | ±0.09 (se_band) | 1.053 | FAIL |
| [blind/pipeline-desktop-opus-run2/20261110T060037Z](blind/pipeline-desktop-opus-run2/20261110T060037Z/CELL.md) | `rd_pm_daily_controls_table1_panelA_col2` | 28.7618 | 34.9 | ±5.8 (se_band) | 1.058 | FAIL |
| [independent/pipeline-desktop-opus/20261110T061446Z](independent/pipeline-desktop-opus/20261110T061446Z/CELL.md) | `n_obs_table1_panelB_deadline_cols1_2` | 184725 | 176426 | ±8821.3 (relative) | 0.941 | PASS |

### Declared deviations

- [seeded/claude-code/2026-11-10-a](seeded/claude-code/2026-11-10-a/CELL.md) (13/13)
  - Stata rdrobust vce(cluster code_city) is implemented as R rdrobust 4.1.1 cluster=code_city with vce='cr1' (plug-in residuals, CR1 weights), the R equivalent; masspoints off, triangular kernel, p=1, q=2, MSE-optimal common bandwidth.
  - reghdfe residualization and event studies use fixest::feols with fixef.rm='singleton' (reghdfe drops singletons).
  - geonear nearest-neighbour matching (ellipsoid) is implemented with a Vincenty WGS84 distance in R; matches kept within 400 km, with replacement.
  - Only the parts of Prepare_Data.do needed for the claims are rebuilt (station_day, station_month+AOD, did_ddl_match, city-day and city-month search data); the rd underreporting dummy and the neural-net PM10 correction are not needed for the claimed columns and were skipped.
- [seeded/claude-code/2026-11-10-b](seeded/claude-code/2026-11-10-b/CELL.md) (13/13)
  - rdrobust: R package rdrobust 4.1.1 with vce='cr1' + cluster=code_city as the equivalent of Stata rdrobust vce(cluster code_city); p=1, q=2, triangular kernel, masspoints='off', default mserd bandwidth.
  - geonear (ellipsoid) nearest-neighbour matching reimplemented with a WGS84 Vincenty inverse distance; nearest Wave-2 deadline station per Wave-1 deadline station, kept if <= 400 km, controls replicated per match (joinby).
  - City-day aggregation for the search data takes auto_date/phase from the station with the latest auto_date (gsort -auto_date); ties broken by station id.
- [independent/claude-code/2026-11-10-a](independent/claude-code/2026-11-10-a/CELL.md) (12/13; failed: `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3`)
  - rdrobust run with masspoints='off' (no mass-point adjustment). The R default ('adjust') gave bandwidths of 179/494 days; 'off' reproduces the paper's reported bandwidths (109, 263, 140, 234, 184 days; 7 months for AOD) and effective observation counts exactly, so it was adopted. Clustered variance vce='cr1' by city.
  - Panel A columns (3)-(5) use the residuals from the single full-sample residualization (station FE, calendar-month FE, linear weather) rather than re-residualizing within each subsample; this reproduces the paper's reported obs/bandwidths exactly.
  - Deadline sample (Panel A col 5) = stations whose automation date is exactly 2013-01-01 or 2014-01-01 (365 stations, 73 cities), the same definition that reproduces Panel B's 242 treated / 123 control stations; the paper says 84 cities, which no definition tried reproduced, but this one reproduces the reported 86,042 obs and 184-day bandwidth.
  - Matched event study (Panel B cols 3, 5): each 2013-01-01 station matched to the nearest (haversine) 2014-01-01 station with replacement; matched controls duplicated once per match. This yields 231,990 obs vs the paper's 186,499; several alternative matching constructions tried (common-date pairs, dedup, city-centroid, Euclidean) also failed to reproduce 186,499, so the literal construction was kept.
  - Monthly running variable (AOD, searches) = calendar-month difference between the observation month and the automation month (automation month = 0, treated). Search RD uses the earliest station automation date in each city and city-month means of daily Baidu indices and station weather.
- [independent/claude-code/2026-11-10-b](independent/claude-code/2026-11-10-b/CELL.md) (12/13; failed: `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3`)
  - rdrobust run with masspoints='off' (the R default 'adjust' gives bandwidths 179/494 days; 'off' reproduces the paper's 109/263-day bandwidths, consistent with the pre-2020 Stata rdrobust). Reported RD coefficient is the conventional local-linear estimate.
  - 'Deadline' stations defined by automation date (exactly 2013-01-01 or 2014-01-01) regardless of listed wave: this gives the 242 treated / 123 control stations in the Table 1 notes (24 of the 242 are in cities coded wave 2). Panel A col 5 uses the same definition (73 cities, not the 84 quoted in the text; N within bandwidth 86,042 matches the table).
  - Matched event-study sample (Panel B cols 3 and 5): each 2013-01-01 station paired with its haversine-nearest 2014-01-01 station, with replacement, and the control station's data duplicated per match. This gives 231,990 obs rather than the paper's 186,499; none of the alternative definitions tried in exploratory attempts 5-6 (Euclidean or swapped coordinates, unique pairs, city-level matching, reverse matching) hit 186,499, so the literal description was kept. Station FE use the original station id.
  - Residualization for cols 3-5 uses residuals from the full-sample regression (station FE + month-of-year FE + four weather controls), then subsets. Singletons dropped as reghdfe would (19 in AOD).
  - Search RD: daily Baidu indices averaged to city-month; city weather = mean over the city's stations; months from automation = calendar-month difference to the city's modal station automation date (14 cities have several station dates).
- [independent/claude-code/2026-11-10-c](independent/claude-code/2026-11-10-c/CELL.md) (13/13)
  - Matched event-study sample (Table 1 Panel B cols 3 and 5): each Wave-1 deadline station (automated 2013-01-01) is matched to its nearest Wave-2 deadline station (automated 2014-01-01) by great-circle distance; the final sample keeps the Wave-1 stations plus the distinct set of matched Wave-2 stations, each once (136,886 obs vs the paper's 186,499). Attempt 8 used the pair-stacked version with duplicated controls (231,990 obs, col3 = 51.8); this was changed after comparing with the claimed 66.5. Neither construction reproduces the paper's observation count.
  - Wave-1 'deadline' stations are those automated on 2013-01-01 regardless of nominal wave (218 phase-1 + 24 phase-2 stations = 242, matching the paper's count); Wave-2 deadline = automated 2014-01-01 (123 stations). This gives 73 cities for Table 1 col 5, whereas the text mentions 84, but the col 5 bandwidth (184 days) and effective N (86,042) match the paper exactly.
  - rdrobust is run with masspoints='off' (city-clustered, triangular kernel, p=1, mserd); this reproduces the paper's reported bandwidths and effective sample sizes exactly (e.g. 109/263 days, 91,470/232,326 obs; AOD 7 months, 5,851 obs).
  - Search RD: daily Baidu PC indices averaged to city-month; city weather = mean across the city's stations; running variable = calendar-month difference from the city's automation date (the date shared by most of its stations, since 15 cities have stations with different dates). Mask sample 8,661 obs (paper 8,661), filter 8,589 (paper 8,590). Residualized estimates are 10.00 (claimed 11.03) and 8.21 (claimed 8.73).
  - matched sample has 136886 obs (paper 186,499); the paper's matching construction could not be pinned down from the text
- [independent/claude-code/2026-11-10-d](independent/claude-code/2026-11-10-d/CELL.md) (12/13; failed: `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3`)
  - Matched event study (Panel B cols 3/5): nearest Wave-2 deadline station by great-circle distance on the package's (shifted) station coordinates, with replacement, pairs stacked so reused controls repeat (231,990 obs vs paper's 186,499). The paper's matched sample could not be reconstructed exactly; an unstacked unique-control variant (136,886 obs) gives 67.9 for col 3 and is printed only as a diagnostic.
  - Search RD (Table 2): city automation date taken as the date on which most of the city's stations automated (ties -> earliest); running variable = calendar-month difference from that month, automation month coded as post.
  - rdrobust run with masspoints='off' (the older Stata rdrobust behaviour); this reproduces the paper's bandwidths and effective N exactly for Table 1 Panel A.
  - matched sample built from the package's shifted station coordinates (nearest Wave-2 deadline station by great-circle distance, pairs stacked); obs differ from the paper's 186,499
- [independent/pipeline-desktop-opus/20261110T061446Z](independent/pipeline-desktop-opus/20261110T061446Z/CELL.md) (13/13)
  - Wave-1 deadline (treated) stations = stations in a deadline city or with own automation date within 31 days of Jan 1, 2013 (all treated from Jan 1, 2013), to recover the paper's 242 Wave-1 deadline stations; Wave-2 controls keep exact station-level deadline
- [independent/pipeline-desktop-opus-run2/20261110T061535Z](independent/pipeline-desktop-opus-run2/20261110T061535Z/CELL.md) (13/13)
  - Wave-1 treated stations also include Wave-1 stations (or stations in Wave-1 cities) automated within 31 days of the Jan 1 2013 deadline, using the smallest window that reaches the 242 treated stations reported; they are coded as treated on Jan 1 2013
- [independent/pipeline-desktop-opus-run3/20261110T061323Z](independent/pipeline-desktop-opus-run3/20261110T061323Z/CELL.md) (13/13)
  - City automation date taken as the earliest station automation date within each city; running variable defined at city level
  - Deadline city defined as a city with at least one station automated exactly on its wave deadline
  - Table 1 Panel A col 5 uses residuals from the full-sample residualisation (station FE, month FE, weather) restricted to deadline cities
  - Matched event study pairs only stations that themselves automated on the wave deadline (Wave-1 on 2013-01-01 to nearest Wave-2 on 2014-01-01), restricted to stations present in the event-study sample
  - Table 1 Panel A cols 2 and 5 use the paper's reported CCT bandwidths (263 and 184 days) as fixed bandwidths instead of re-selecting them, since the R MSE-optimal selector returned much wider bandwidths
- [independent/pipeline-desktop-opus-run4/20261110T062806Z](independent/pipeline-desktop-opus-run4/20261110T062806Z/CELL.md) (12/13; failed: `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3`)
  - Wave-1 deadline stations defined as all stations in Wave-1 cities with at least one station automated on Jan 1 2013 (to approximate the paper's 242 treated stations)
  - Matched control pool uses all Wave-2 stations automated on/after Jan 1 2014 (never treated in the 2012-2013 window), not only the 123 Wave-2 deadline stations
- [blind/claude-code/2026-11-10-a](blind/claude-code/2026-11-10-a/CELL.md) (12/13; failed: `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3`)
  - Matched event-study sample (Table 1 Panel B cols 3 and 5): each station automated 2013-01-01 (242) is matched to its nearest station automated 2014-01-01 (123 candidates) by great-circle distance, with replacement; the paired sample stacks each treated station with a copy of its matched control (231,990 obs). The paper reports 186,499 obs for this sample; none of the variants tried in exploration (haversine vs Euclidean distance, 242 vs 218 treated stations, repeated vs unique controls, pair-days observed for both) reproduced that count, so the paper's exact matched-sample construction is not known and these two quantities may differ from it.
  - Deadline sample defined by automation date (stations automated on 2013-01-01 or 2014-01-01, 73 cities with data), which gives the paper's 242 treated / 123 control stations in Panel B and its Panel A col 5 daily N; the paper's text says 84 deadline cities.
  - City-level automation date for the city-month search RD: 15 cities have stations with different automation dates in station_list; the date shared by most of the city's stations is used (ties -> earliest).
  - rdrobust (R) with masspoints='off', cluster=city (vce cr1), triangular kernel, mserd bandwidth; conventional point estimate reported. The mass-point adjustment was turned off because the paper's reported bandwidths and in-bandwidth N (109/263 days; 91,470/232,326 obs) are reproduced exactly only without it (consistent with an older Stata rdrobust).
- [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) (12/13; failed: `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3`)
  - rdrobust (R) run with masspoints='off' (no mass-point adjustment), as in the pre-2020 Stata rdrobust the paper would have used; the bandwidths/obs-within-bandwidth reported in the Table 1 notes were seen in an exploratory run and are consistent with this choice. vce='hc1' with cluster=city (rdrobust switches to CR1). Conventional (not bias-corrected) point estimates are reported.
  - Panel A col 1 (no controls) is run on the station-days with PM10 and all four weather variables (1,049,325 obs, the count stated in the Table 1 notes), so cols 1 and 2 share a sample.
  - Residualization: one OLS of the outcome on station FE, calendar-month (month-of-year) FE and linear temperature, humidity, precipitation, wind speed on the full sample; the wave/deadline RDs use subsets of these full-sample residuals.
  - Deadline sample = stations in cities automated exactly on 2013-01-01 or 2014-01-01 (any wave); event-study treated = automated 2013-01-01 (242 stations), controls = automated 2014-01-01 (123 stations), matching the station counts in the Table 1 notes.
  - Event-study bins defined by calendar months relative to Jan 2013 (Jan-Jun 2012 = 7-12 before, ..., Nov-Dec 2012 = reference, Jan-Feb 2013 = 1-2 after, Jul-Dec 2013 = 7-12 after); indicators = treated x bin.
  - Matched sample: each treated station paired with its nearest (haversine) control station, with replacement; a copy of the control is stacked for every pair, with a pair-specific station FE (231,990 obs; the paper reports 186,499, so the authors' pairing/dedup differs from mine). Log(PM10) drops pm10 = 0.
  - AOD and Baidu RDs: running variable = calendar months from the automation month (automation month = 0, treated). Monthly weather = mean of daily station weather; city weather = mean across the city's stations. Baidu monthly index = mean of daily PC index within city-month, restricted to the 123 sample cities. City automation date = modal station automation date (13 cities have stations with differing dates).
- [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) (12/13; failed: `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3`)
  - RD estimates use R rdrobust 4.1.1 (local linear, triangular kernel, MSE-optimal common bandwidth 'mserd', cluster-robust by city via vce='hc0'+cluster which rdrobust maps to 'cr1', masspoints='off' to mimic the pre-2020 CCT (2014) implementation). Reported coefficient is the conventional estimate.
  - Covariate-adjusted RDs: outcome residualized once on the full sample (station FE + calendar-month FE + temperature, RH, precipitation, wind speed via fixest), then RD on residuals; wave/deadline subsamples reuse the full-sample residuals.
  - Monthly running variable (AOD, search) = calendar-month index minus the automation month (automation month coded 0, treated). Station-month weather = mean of daily station weather; city-month weather = mean over the city's stations. 13 cities list stations with different automation dates; for the city-level search RD the city's earliest automation month is used.
  - Search outcomes: monthly averages of the daily Baidu PC indices (pmmask, filter) from mask_filter_search.dta for the 123 sample cities.
  - RD Deadline sample (Panel A col 5) = phase-1 stations automated 2013-01-01 plus phase-2 stations automated 2014-01-01 (68 cities in the data vs 84 stated in the paper).
  - Event study: treated = all stations automated 2013-01-01 (242, incl. 24 phase-2 stations), control = stations automated 2014-01-01 (123), 2012-01-01..2013-12-31; bins by calendar month relative to Jan 2013; ref = Nov-Dec 2012. Matched sample: each treated station paired with its nearest (haversine) control station with replacement; control data duplicated once per pair. log(PM10) drops PM10 = 0 days.
- [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) (11/13; failed: `rd_pm_daily_controls_table1_panelA_col2`, `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3`)
  - Matched event-study sample keeps one copy of each Wave-2 control per treated station it is matched to (with replacement), giving 231,990 obs; the paper reports 186,499, so their pairing/deduplication evidently differs.
  - Deadline sample defined at station level as automation date equal to 2013-01-01 or 2014-01-01 (242 + 123 stations, matching the paper's station counts; 73 cities vs the paper's 84).
  - For the city-level search RD, cities with more than one station automation date (14) use the modal station date (earliest on ties).
  - Monthly running variable = calendar-month difference from the automation month (the automation month = 0, treated). Weather for AOD and searches is the station-month and city-month mean of the daily weather.
  - Residualization is run once on the full sample (station or city FE + month-of-year FE + 4 weather controls; singletons dropped). Subsample RDs use those residuals. rdrobust uses p=1, a triangular kernel, mserd bandwidth, cr1 clustering by city and default mass-points handling; the conventional estimate is reported.

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- blind: `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3` — pipeline 4/4, agent 0/4
- blind: `n_obs_table1_panelB_deadline_cols1_2` — pipeline 0/4, agent 4/4

Pass rates at least 50 points apart (not unanimous):

- independent: `event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3` — pipeline 3/4, agent 1/4
- blind: `rd_aod_monthly_controls_table1_panelA_col2` — pipeline 2/4, agent 4/4
- blind: `rd_pm_daily_controls_table1_panelA_col2` — pipeline 1/4, agent 3/4

## Cells

### seeded · claude-code · 2026-11-10-a

[`seeded/claude-code/2026-11-10-a/CELL.md`](seeded/claude-code/2026-11-10-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-10T05:50:30Z; from `claude-code-1paper-greenstone-all-modes-2026-11-09.json`; evidence complete.

### seeded · claude-code · 2026-11-10-b

[`seeded/claude-code/2026-11-10-b/CELL.md`](seeded/claude-code/2026-11-10-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-10T05:57:00Z; from `claude-code-run2-1paper-greenstone-all-modes-2026-11-09.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261110T055807Z

[`seeded/pipeline-desktop-opus/20261110T055807Z/CELL.md`](seeded/pipeline-desktop-opus/20261110T055807Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T05:58:07Z; from `pipeline-oracle-desktop-opus-1paper-greenstone-all-modes-2026-11-09.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261110T060636Z

[`seeded/pipeline-desktop-opus-run2/20261110T060636Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261110T060636Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T06:06:36Z; from `pipeline-oracle-desktop-opus-run2-1paper-greenstone-all-modes-2026-11-09.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261110T060758Z

[`seeded/pipeline-desktop-opus-run3/20261110T060758Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261110T060758Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T06:07:58Z; from `pipeline-oracle-desktop-opus-run3-1paper-greenstone-all-modes-2026-11-09.json`; evidence complete.

### independent · claude-code · 2026-11-10-a

[`independent/claude-code/2026-11-10-a/CELL.md`](independent/claude-code/2026-11-10-a/CELL.md) — final 12/13, re-scored 12/13; first scored 9/13; executions 8; 2026-11-10T05:56:30Z; from `claude-code-1paper-greenstone-all-modes-2026-11-09.json`; evidence complete.

### independent · claude-code · 2026-11-10-b

[`independent/claude-code/2026-11-10-b/CELL.md`](independent/claude-code/2026-11-10-b/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 7; 2026-11-10T06:03:00Z; from `claude-code-run2-1paper-greenstone-all-modes-2026-11-09.json`; evidence complete.

### independent · claude-code · 2026-11-10-c

[`independent/claude-code/2026-11-10-c/CELL.md`](independent/claude-code/2026-11-10-c/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 9; 2026-11-10T06:12:30Z; from `claude-code-run3-1paper-greenstone-indep-blind-2026-11-09.json`; evidence complete.

### independent · claude-code · 2026-11-10-d

[`independent/claude-code/2026-11-10-d/CELL.md`](independent/claude-code/2026-11-10-d/CELL.md) — final 12/13, re-scored 12/13; first scored 9/13; executions 7; 2026-11-10T06:10:00Z; from `claude-code-run4-1paper-greenstone-indep-blind-2026-11-09.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261110T061446Z

[`independent/pipeline-desktop-opus/20261110T061446Z/CELL.md`](independent/pipeline-desktop-opus/20261110T061446Z/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 3; 2026-11-10T06:14:46Z; from `pipeline-oracle-desktop-opus-1paper-greenstone-all-modes-2026-11-09.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261110T061535Z

[`independent/pipeline-desktop-opus-run2/20261110T061535Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261110T061535Z/CELL.md) — final 13/13, re-scored 13/13; first scored 11/13; executions 4; 2026-11-10T06:15:35Z; from `pipeline-oracle-desktop-opus-run2-1paper-greenstone-all-modes-2026-11-09.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261110T061323Z

[`independent/pipeline-desktop-opus-run3/20261110T061323Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261110T061323Z/CELL.md) — final 13/13, re-scored 13/13; first scored 9/13; executions 5; 2026-11-10T06:13:23Z; from `pipeline-oracle-desktop-opus-run3-1paper-greenstone-all-modes-2026-11-09.json`; evidence complete.

### independent · pipeline-desktop-opus-run4 · 20261110T062806Z

[`independent/pipeline-desktop-opus-run4/20261110T062806Z/CELL.md`](independent/pipeline-desktop-opus-run4/20261110T062806Z/CELL.md) — final 12/13, re-scored 12/13; first scored 11/13; executions 4; 2026-11-10T06:28:06Z; from `pipeline-oracle-desktop-opus-run4-1paper-greenstone-indep-blind-2026-11-09.json`; evidence complete.

### blind · claude-code · 2026-11-10-a

[`blind/claude-code/2026-11-10-a/CELL.md`](blind/claude-code/2026-11-10-a/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 9; 2026-11-10T05:55:00Z; from `claude-code-1paper-greenstone-all-modes-2026-11-09.json`; evidence complete.

### blind · claude-code · 2026-11-10-b

[`blind/claude-code/2026-11-10-b/CELL.md`](blind/claude-code/2026-11-10-b/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 5; 2026-11-10T06:02:00Z; from `claude-code-run2-1paper-greenstone-all-modes-2026-11-09.json`; evidence complete.

### blind · claude-code · 2026-11-10-c

[`blind/claude-code/2026-11-10-c/CELL.md`](blind/claude-code/2026-11-10-c/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 3; 2026-11-10T06:01:30Z; from `claude-code-run3-1paper-greenstone-indep-blind-2026-11-09.json`; evidence complete.

### blind · claude-code · 2026-11-10-d

[`blind/claude-code/2026-11-10-d/CELL.md`](blind/claude-code/2026-11-10-d/CELL.md) — final 11/13, re-scored 11/13; first scored 11/13; executions 4; 2026-11-10T06:06:37Z; from `claude-code-run4-1paper-greenstone-indep-blind-2026-11-09.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261110T055406Z

[`blind/pipeline-desktop-opus/20261110T055406Z/CELL.md`](blind/pipeline-desktop-opus/20261110T055406Z/CELL.md) — final 10/13, re-scored 10/13; first scored 10/13; executions 1; 2026-11-10T05:54:06Z; from `pipeline-oracle-desktop-opus-1paper-greenstone-all-modes-2026-11-09.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261110T060037Z

[`blind/pipeline-desktop-opus-run2/20261110T060037Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261110T060037Z/CELL.md) — final 10/13, re-scored 10/13; first scored 10/13; executions 1; 2026-11-10T06:00:37Z; from `pipeline-oracle-desktop-opus-run2-1paper-greenstone-all-modes-2026-11-09.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261110T055857Z

[`blind/pipeline-desktop-opus-run3/20261110T055857Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261110T055857Z/CELL.md) — final 10/13, re-scored 10/13; first scored 10/13; executions 1; 2026-11-10T05:58:57Z; from `pipeline-oracle-desktop-opus-run3-1paper-greenstone-all-modes-2026-11-09.json`; evidence complete.

### blind · pipeline-desktop-opus-run4 · 20261110T063528Z

[`blind/pipeline-desktop-opus-run4/20261110T063528Z/CELL.md`](blind/pipeline-desktop-opus-run4/20261110T063528Z/CELL.md) — final 11/13, re-scored 11/13; first scored 11/13; executions 1; 2026-11-10T06:35:28Z; from `pipeline-oracle-desktop-opus-run4-1paper-greenstone-indep-blind-2026-11-09.json`; evidence complete.

