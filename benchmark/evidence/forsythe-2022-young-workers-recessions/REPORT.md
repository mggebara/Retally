# Evidence report: forsythe-2022-young-workers-recessions

**Why Don't Firms Hire Young Workers During Recessions?** — Eliza Forsythe

- Paper: https://publish.illinois.edu/elizaforsythe/files/2022/01/Forsythe_Youth_Hiring_prepub_version_2021.pdf
- I4R report: https://www.econstor.eu/bitstream/10419/303195/1/I4R-DP163.pdf
- I4R outcome label: robust; split: holdout
- Catalog entry (ground truth): `benchmark/papers/forsythe-2022-young-workers-recessions.yaml`

> Headline finding: in the matched monthly CPS (1994-2016), the monthly hiring probability of workers with at most ten years of potential experience falls with the state unemployment rate (Table 1 Panel B: -0.335 pp per point with no controls, -0.253 in the preferred specification with state, demographic and month-year fixed effects), while experienced workers' hiring barely moves (-0.0367) or rises (0.0496); the gap holds for hires from employment, unemployment and non-participation (Table 2), and new hires' log weekly wages fall faster for the young (Table 10: -0.0262 vs -0.0116 per point), which the paper reads as support for its bargained cyclical-upgrading model. Full-sample N 16,948,516.
> Outcome label.  The meta-database leaves computational_reproduction and perfect_reproduction blank for this paper and files every row as a robustness check; the shortlist recorded "reproducible (perfect_reproduction=Yes, computational_reproduction=1)", which the database copy in benchmark/corpus/ does not show.  DP 163 never ran the package: it reconstructs the data from IPUMS-CPS and recodes every regression, and concludes that the results "closely replicate" (same signs and significance in Tables 1, 2 and B.2; magnitude differences elsewhere that it attributes to the different data construction). outcome_label is therefore robust, not reproducible: in schema.py REPRODUCIBLE means the code runs and the numbers match, which nobody checked, while ROBUST means the claims survive reasonable alternative specifications, which is what DP 163 shows (an independent data build with a different N, recoded regressions, plus the 2019 sample extension and MSA-level unemployment).  No one on record has run the shipped do-files.  The per-claim findings record where the rebuilt data move a number by more than a paper SE; because the replicators did not use the package, they say nothing about whether the package itself reproduces the printed tables.
> Sandbox memory.  yh_data.csv is 2.17 GB uncompressed (35 columns of raw CPS person-month pairs), and the reproduction sandbox runs every script under a fixed memory cap: DockerExecutor (src/retally/codegen/docker_executor.py) starts each container with `docker run --memory 4g` (memory_limit default "4g", Pipeline docker_memory default "4g"; the benchmark runner does not override it), also with --cpus 1.0, a 300 s default timeout, a read-only root and a 256 MB /tmp.  A reproduction that loads the full file into R, or builds the fixed-effects design on all of its rows, may be killed for exceeding that cap, and a pass or fail on this entry has to be read with that in mind.  This is a property of the entry, recorded here, not something the entry works around.
> I4R rows (team 109, DP 163, rows 6412-6626; 215 rows, 214 with r_coeff).  158 "New data (all)" rows are the DP's Appendix A.1 direct replication (Tables 1-6, 10, B.2); 28 "Increase sample (time)" rows are Appendix A.2 (sample extended to 2019, Tables 1-2); 28 more add a changed main variable (Appendix A.3, MSA unemployment, Tables 1-2); one row is blank.  Transcription slips in o_coeff_dbl, checked against the paper and DP 163's "[original]" rows: Table 1 Panel B col 1 PE > 10 x U. Rate is printed -0.0367 but recorded as -0.367 (rows 6434, 6491); Table 4 col 1 PE <= 10 is printed 0.193 but recorded as 0.192 (not pinned). Every other pinned value and SE equals o_coeff_dbl / o_std_err_dbl.
> Curation pass (2026-11-01).  Pinned 13 claims, all from the main-text Tables 1, 2 and 10, with state-clustered SEs in standard_error: Table 1 Panel B young and experienced interactions in column (1) (no fixed effects; the abstract-level numbers of the introduction, which quotes five times these) and column (4) (preferred, = Table 2 column 1); Table 1 Panel A aggregate effect in columns (1) and (4); Table 2 young and experienced interactions for hires from employment, and the young interaction for hires from unemployment and from NILF; Table 10 Panel B column (1) young and experienced log-wage interactions; the full-sample N.  sample_size is set where the paper prints the N of the same regression (Table 1 / Table 2 col 1: 16,948,516); Table 2 columns 2-4 print 10,814,088 / 653,100 / 5,481,328 and Table 10 column 1 prints 112,858 (not pinned, not in contexts).  Left out: Table 1 columns (2)-(3) and the PE <= 10 main effects (4.988 etc.), R-squared, the Table 2 Wald statistics (569.88, 206.51, 38.15, 237.47), Table 2 experienced interactions for the unemployed (-1.505) and NILF (0.0148), Tables 3-9 (flows, separations, composition, search, availability, education), Table 10 columns (2)-(4) and Panel A, Figure 2 and the appendix (Table B.2).
> What was read.  The author's pre-publication PDF (whole text and Tables 1-10); Crossref and Zenodo API metadata; I4R DP 163 (EconStor PDF, whole text and Appendix A tables); the meta-database's 215 rows; the whole package listing, ReadMe.pdf, the CSV headers and the data-construction and regression do-files (downloaded to the gitignored .cache/datasets/, never committed).
> Package structure (package-only facts; never in contexts). YH_data_init.do: years from education (peeduc 31-46 mapped to 0-22, e.g. 39 -> 12, 43 -> 16), exp = age - yrsch - 6 (age set missing above 79); young = exp <= 10 (negative experience counts as young); youngurate / oldurate = v2unemp times the group indicator; hired = 1 if employed in month 2 (v2pemlr 1-2), reset to 0 if v2puiodp1 == 1 (same employer) or if employed in month 1 with v2puiodp1 missing; hired2 also 0 if v2peio1cow >= 5 (self-employed / without pay); hired100 = 100 x hired2; demo2 = group(minority female hisp educ) with educ in 7 levels; weight = (v2pwsswgt + pwsswgt) / 2; date = ym(v2hryear, v2hrmonth); log weekly real wage = log(v2prernwa / cpi), wage regressions restricted to hires with v2prwernal == 0 and occupation / industry fixed effects on the 2002-recoded codes; final sample keep if exp and v2unemp non-missing.  YH_regs.do: every table is Stata `reg ... [aweight=weight], vce(cl v2gestfips)` with i.v2gestfips i.date i.demo2 dummies; Table 2 columns 2-4 condition on pemlr 1-2 / 3-4 / >4 in month 1; output via esttab.  hryear is two-digit for 1994-1997 in the .csv.
> What could not be verified.  The do-files were not run and no estimate was recomputed here (the 2.2 GB .csv and a multi-hour Stata run made that out of scope for a zero-cost curation pass), so the entry rests on the paper, the meta-database and DP 163; whether the package reproduces the printed tables is untested by anyone on record. The published EJ PDF was not read (paywalled); the pre-publication version's pinned values agree with the published ones as recorded by the meta-database and DP 163.  publication_date is the 2016 working paper, dated from a news article rather than from the working-paper file itself.
> Original analysis in Stata 14.2 (seven do-files, parmest and esttab); language is r, the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `young_x_unemp_rate_no_controls` | -0.335 | 0.0203 | Table 1, Panel B, column (1), PE <= 10 x U. Rate | -0.343 | matches |
| 1 | `experienced_x_unemp_rate_no_controls` | -0.0367 | 0.0131 | Table 1, Panel B, column (1), PE > 10 x U. Rate | -0.0407 | matches |
| 2 | `young_x_unemp_rate_preferred` | -0.253 | 0.0185 | Table 1, Panel B, column (4), PE <= 10 x U. Rate (also Table 2, column (1)) | -0.244 | matches |
| 3 | `experienced_x_unemp_rate_preferred` | 0.0496 | 0.0142 | Table 1, Panel B, column (4), PE > 10 x U. Rate (also Table 2, column (1)) | 0.0616 | matches |
| 4 | `aggregate_unemp_rate_no_controls` | -0.119 | 0.015 | Table 1, Panel A, column (1), State Unemp. Rate | -0.119 | matches |
| 5 | `aggregate_unemp_rate_month_year_fe` | -0.0326 | 0.0132 | Table 1, Panel A, column (4), State Unemp. Rate | -0.0186 | does_not_match |
| 6 | `young_x_unemp_rate_employed` | -0.168 | 0.0156 | Table 2, column (2) Employed, PE <= 10 x U. Rate | -0.167 | matches |
| 7 | `experienced_x_unemp_rate_employed` | 0.0179 | 0.0101 | Table 2, column (2) Employed, PE > 10 x U. Rate | 0.0291 | does_not_match |
| 8 | `young_x_unemp_rate_unemployed` | -1.928 | 0.167 | Table 2, column (3) Unemployed, PE <= 10 x U. Rate | -1.887 | matches |
| 9 | `young_x_unemp_rate_nilf` | -0.49 | 0.0332 | Table 2, column (4) NILF, PE <= 10 x U. Rate | -0.578 | does_not_match |
| 10 | `wage_young_x_unemp_rate_all_hires` | -0.0262 | 0.0036 | Table 10, Panel B, column (1) All, PE <= 10 x U. Rate | -0.025 | matches |
| 11 | `wage_experienced_x_unemp_rate_all_hires` | -0.0116 | 0.00348 | Table 10, Panel B, column (1) All, PE > 10 x U. Rate | -0.0103 | matches |
| 12 | `n_obs_full_sample` | 1.69485e+07 | — | Table 1, N (all columns); Table 2, column (1) | 1.62086e+07 | does_not_match |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[13/13](seeded/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) | [12/13](independent/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[13/13](independent/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) | [11/13](blind/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[11/13](blind/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) |
| `pipeline-desktop-opus` | [13/13](seeded/pipeline-desktop-opus/20261102T062442Z/CELL.md) (20261102T062442Z) | [11/13](independent/pipeline-desktop-opus/20261102T064502Z/CELL.md) (20261102T064502Z) | [10/13](blind/pipeline-desktop-opus/20261102T062442Z/CELL.md) (20261102T062442Z) |
| `pipeline-desktop-opus-run2` | [13/13](seeded/pipeline-desktop-opus-run2/20261102T092119Z/CELL.md) (20261102T092119Z) | [11/13](independent/pipeline-desktop-opus-run2/20261102T142444Z/CELL.md) (20261102T142444Z) | [10/13](blind/pipeline-desktop-opus-run2/20261102T144228Z/CELL.md) (20261102T144228Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [blind/pipeline-desktop-opus/20261102T062442Z](blind/pipeline-desktop-opus/20261102T062442Z/CELL.md) | `aggregate_unemp_rate_month_year_fe` | -0.020142 | -0.0326 | ±0.0132 (se_band) | 0.944 | PASS |
| [blind/pipeline-desktop-opus-run2/20261102T144228Z](blind/pipeline-desktop-opus-run2/20261102T144228Z/CELL.md) | `aggregate_unemp_rate_month_year_fe` | -0.020142 | -0.0326 | ±0.0132 (se_band) | 0.944 | PASS |
| [blind/pipeline-desktop-opus/20261102T062442Z](blind/pipeline-desktop-opus/20261102T062442Z/CELL.md) | `young_x_unemp_rate_unemployed` | -1.7407 | -1.928 | ±0.167 (se_band) | 1.122 | FAIL |
| [blind/pipeline-desktop-opus-run2/20261102T144228Z](blind/pipeline-desktop-opus-run2/20261102T144228Z/CELL.md) | `young_x_unemp_rate_unemployed` | -1.74044 | -1.928 | ±0.167 (se_band) | 1.123 | FAIL |
| [blind/pipeline-desktop-opus/20261102T062442Z](blind/pipeline-desktop-opus/20261102T062442Z/CELL.md) | `young_x_unemp_rate_preferred` | -0.239404 | -0.253 | ±0.0185 (se_band) | 0.735 | PASS |
| [blind/pipeline-desktop-opus-run2/20261102T144228Z](blind/pipeline-desktop-opus-run2/20261102T144228Z/CELL.md) | `young_x_unemp_rate_preferred` | -0.239795 | -0.253 | ±0.0185 (se_band) | 0.714 | PASS |
| [blind/pipeline-desktop-opus-run2/20261102T144228Z](blind/pipeline-desktop-opus-run2/20261102T144228Z/CELL.md) | `wage_experienced_x_unemp_rate_all_hires` | -0.00913859 | -0.0116 | ±0.00348 (se_band) | 0.707 | PASS |
| [blind/pipeline-desktop-opus/20261102T062442Z](blind/pipeline-desktop-opus/20261102T062442Z/CELL.md) | `wage_experienced_x_unemp_rate_all_hires` | -0.00920471 | -0.0116 | ±0.00348 (se_band) | 0.688 | PASS |
| [blind/pipeline-desktop-opus/20261102T062442Z](blind/pipeline-desktop-opus/20261102T062442Z/CELL.md) | `wage_young_x_unemp_rate_all_hires` | -0.0238669 | -0.0262 | ±0.0036 (se_band) | 0.648 | PASS |
| [blind/pipeline-desktop-opus/20261102T062442Z](blind/pipeline-desktop-opus/20261102T062442Z/CELL.md) | `experienced_x_unemp_rate_no_controls` | -0.04513 | -0.0367 | ±0.0131 (se_band) | 0.644 | PASS |

### Declared deviations

- [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) (13/13)
  - Table 1 and Table 2 hiring regressions are estimated as weighted least squares on exact weighted cell means over (state, month, demo2, young, prior labour-force status group), with cell weights equal to summed CPS weights. All regressors and fixed effects are constant within these cells, so point estimates are algebraically identical to the person-level aweighted regressions in YH_regs.do. This keeps the run inside the 300 s / 4 GB sandbox. Clustered standard errors (state) use the same meat and bread, but the (N-1)/(N-K) small-sample factor is omitted; they are printed for information only.
  - yh_data.csv was read in full (all 19,836,464 rows), but only the 19 columns the Table 1/2/10 specifications need (fread select=). The occupation/industry crosswalk merges are applied only to the new-hire wage sample.
  - hiring regressions (Tables 1-2) estimated as WLS on exact weighted cell means over (state, month, demo2, young, prior labour-force status) to fit the 300 s / 4 GB sandbox; point estimates are algebraically identical, SEs use the same clustering but the small-sample N adjustment is omitted.
- [seeded/claude-code/2026-11-02-b](seeded/claude-code/2026-11-02-b/CELL.md) (13/13)
  - yh_data.csv (about 2 GB) read with data.table::fread(select=) of only the 19 columns the claimed specifications use, to fit the sandbox's 300 s / 4 GB limits.
  - Hiring regressions (Table 1 Panels A/B, Table 2) estimated by weighted least squares on cells of state x month x demo2 x young x prior labour-force status, with the cell weight being the sum of the CPS weights and the outcome being the weighted mean of hired100. Every regressor and fixed effect is constant within a cell, so the point estimates equal those of the person-level aweighted regression; the clustered-SE small-sample factor uses the number of cells instead of persons. The wage regression (Table 10) is run at person level.
  - Stata's m:1 crosswalk merges are done as lookups on keys deduplicated by (code, code-year).
  - yh_data.csv read with data.table::fread(select=) of only the 19 columns used (memory/time limits of the sandbox)
  - hiring regressions (Tables 1-2) estimated by WLS on state x month x demo2 x young x prior-status cells with summed CPS weights; identical point estimates to the person-level aweighted regression, clustered SE small-sample factor uses cell count
- [independent/claude-code/2026-11-02-a](independent/claude-code/2026-11-02-a/CELL.md) (12/13; failed: `young_x_unemp_rate_nilf`)
  - Hiring LPMs (Table 1 A/B cols 1 and 4, Table 2 cols 1-4) estimated by WLS on weighted cell means over state x month x demographic cell x PE<=10 x prior labour-force status; all regressors are constant within cells, so point estimates equal person-level WLS; state-clustered SEs not computed/reported.
  - State (v2gestfips) is missing in the provided data for mid-2014 through 2016 (2.15M person-months); these cannot be matched to the state unemployment rate and are dropped. Sample also restricted to ages 16-80 (age top-coding above 80 varies over time) with non-missing Hispanic origin; resulting N = 16,964,441.
  - Years of schooling for potential experience imputed from CPS PEEDUCA categories: <1st=0, 1-4=2.5, 5-6=5.5, 7-8=7.5, 9th=9, 10th=10, 11th=11, 12th no diploma=12, HS=12, some college=13, associate=14, BA=16, MA/professional/PhD=18.
  - The 2 GB yh_data.csv was read with data.table::fread restricted to the 19 needed columns (select=), not loaded in full, because of the sandbox's 4 GB memory cap and 300 s time limit.
  - Wage regression uses the average of the two months' CPS final weights (earnings weights not in the data); industry/occupation crosswalked to 2002 census codes by code vintage (industry 1990 codes to 2002, 2002 codes 2003-08, 2007 codes 2009-13, 2012 codes 2014+; occupation 1990 codes to 2002, 2002 codes 2003-10, 2010 codes 2011+).
  - hiring LPMs estimated by WLS on weighted cell means (state x month x demographic x PE-group x prior-status); point estimates identical to person-level WLS, clustered SEs not reported
  - v2gestfips (state) is missing in the data from mid-2014 onward; those person-months cannot be matched to a state unemployment rate and are dropped; sample further restricted to ages 16-80 with non-missing Hispanic origin
  - years of schooling imputed from CPS education categories (assumed mapping; master's/professional/PhD = 18 years)
- [independent/claude-code/2026-11-02-b](independent/claude-code/2026-11-02-b/CELL.md) (13/13)
  - yh_data.csv (2 GB) read with data.table::fread(select=) restricted to the 20 needed columns, to fit the sandbox 4 GB memory / 300 s limits.
  - Hiring regressions (Tables 1-2) estimated by WLS on cell means (state x month-year x demographic cell x PE group x t-1 status, weighted by summed person weights); point estimates are identical to person-level WLS because every regressor is constant within cells, but clustered SEs are not identical to the person-level ones.
  - Sample restricted to age < 80 at t-1 (CPS age topcode); this restriction is not stated in the paper but reproduces N = 16,948,516 and the Table 2 subsample Ns exactly. The provided state-unemployment file and state identifiers end in May 2014, so the effective sample ends then.
  - Years of education from PEEDUCA: 31=0, 32=2.5, 33=5.5, 34=7.5, 35=9, 36=10, 37=11, 38=12, 39=12, 40=13, 41-42=14, 43=16, 44=18, 45-46=20 (the paper does not give its mapping).
  - Wage sample: hires in t with weekly earnings > 0 and allocation flag PRWERNAL == 0 (1994-early 1995 have no flag and drop out); occupation/industry crosswalk code year assigned by date (occ: 1990 codes through 2002, 2002 codes 2003-2010, 2010 codes 2011+; ind: 1990 through 2002, 2002 codes 2003-2008, 2007 codes 2009-2013, 2012 codes 2014+). N = 120,294 vs 112,858 in the paper.
  - yh_data.csv (2 GB) read with data.table::fread(select=) restricted to the 20 columns needed, to fit the sandbox's 4 GB / 300 s limits
- [blind/claude-code/2026-11-02-a](blind/claude-code/2026-11-02-a/CELL.md) (11/13; failed: `young_x_unemp_rate_nilf`, `n_obs_full_sample`)
  - Sample restriction follows the paper's explicit statement only: civilians aged 16+ (peage>=16) with valid education and labour-force status in both months, month t from Feb 1994 to Sep 2016; no upper age bound was imposed (the paper says 'working-age' but gives no cap). Matches were taken as supplied (the file has no second-month sex/race/age to re-confirm matches).
  - Years of schooling mapped from peeduca: 31:0, 32:2.5, 33:5.5, 34:7.5, 35:9, 36:10, 37:11, 38:12, 39:12, 40:13, 41:14, 42:14, 43:16, 44:18, 45:20, 46:20; potential experience = age - years - 6, young = PE <= 10.
  - Hire = employed in t (pemlr 1-2) and either non-employed in t-1 or v2puiodp1 == 2 (changed employer); new job class of worker 6/7 (self-employed) excluded. v2puiodp1 codes -1/-2/-3 treated as no employer change.
  - Demographic FE = sex x white (race==1) x Hispanic (prhspnon, else pehspnon, == 1) x 7 education groups; demographics and t-1 status from the first month, state and unemployment rate from month t.
  - Hiring LPMs were estimated on weighted cell means (state x month x demographic cell x young x t-1 status), with weight = sum of the average of the two months' CPS weights. Point estimates are identical to person-level WLS because every regressor is constant within a cell. N is the person-level count. Done because the 2 GB file takes about 214 s of the 300 s limit to read in the sandbox.
  - Only the needed 19 of 35 columns of yh_data.csv were read (fread select=); the full file was not loaded.
  - Wage regression: new hires with v2prernwa > 0 and v2prwernal == 0 (not allocated), deflated by the supplied CPI series at month t. Weights are the average CPS weight (no earnings weight is in the data). Occupation codes mapped to 2002 codes via crosswalk vintage 1990 (<=2002), 2002 (2003-2010), 2010 (2011+); industry via 1990 (<=2002), 2002 (2003-2008), 2007 (2009-2013), 2012 (2014+). 11 obs with an unmatched industry were dropped.
- [blind/claude-code/2026-11-02-b](blind/claude-code/2026-11-02-b/CELL.md) (11/13; failed: `young_x_unemp_rate_nilf`, `n_obs_full_sample`)
  - yh_data.csv (about 2 GB) read with data.table::fread(select=) of only the needed columns, to fit the 300 s / 4 GB sandbox (also printed as a DEVIATION line).
  - The supplied state unemployment file v2unemp_smy.csv covers only Jan 1994 to May 2014. The 2,109,873 person-month pairs from Jun 2014 to Sep 2016 have no unemployment rate and are dropped, so every regression and n_obs_full_sample use Jan 1994 to May 2014 rather than the paper's Jan 1994 to Sep 2016. — names `n_obs_full_sample`
  - Hiring regressions are estimated on cell means (state x month x PE<=10 x demographic cell x t-1 status, with summed weights). Every regressor is constant within a cell, so the WLS point estimates equal the individual-level ones, but the clustered SEs printed are cell-level and are not reported as results.
  - Years of schooling are imputed from PEEDUCA (31=0, 32=2.5, 33=5.5, 34=7.5, 35=9, 36=10, 37=11, 38=12, 39=12, 40=13, 41/42=14, 43=16, 44=18, 45=20, 46=20). Potential experience = age - schooling - 6; young means PE <= 10.
  - Sample: age >= 16 (from the t-1 record), valid labour-force status in both months, positive average weight. Demographics, age and education come from the t-1 record. Hire: employed (PEMLR 1-2) in t, with the t job not self-employed (PEIO1COW 6/7), and either not employed in t-1 or employed in t-1 with PUIODP1=2 (different employer). Weight is the average of the two months' PWSSWGT.
  - Wage regression: hires in t with PRWERNAL=0 (not allocated) and PRERNWA>0, log(PRERNWA/cpi), with averaged CPS weights. Occupation and industry are crosswalked to 2002 codes assuming code years: occupation 1990 (<=2002), 2002 (2003-2010), 2010 (2011+); industry 1990 (<=2002), 2002 (2003-2008), 2007 (2009-2013), 2012 (2014+). Eleven hires with unmatched industry codes are dropped as singleton/NA by fixest.
  - yh_data.csv read with data.table::fread(select=) of the 20 needed columns only (2 GB file, 300 s / 4 GB sandbox)

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- independent: `n_obs_full_sample` — pipeline 0/2, agent 2/2
- blind: `young_x_unemp_rate_unemployed` — pipeline 0/2, agent 2/2

Pass rates at least 50 points apart (not unanimous):

- independent: `young_x_unemp_rate_nilf` — pipeline 0/2, agent 1/2

## Cells

### seeded · claude-code · 2026-11-02-a

[`seeded/claude-code/2026-11-02-a/CELL.md`](seeded/claude-code/2026-11-02-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 6; 2026-11-02T06:08:46Z; from `claude-code-4papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · claude-code · 2026-11-02-b

[`seeded/claude-code/2026-11-02-b/CELL.md`](seeded/claude-code/2026-11-02-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-02T19:42:40Z; from `claude-code-run2-23papers-seeded-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261102T062442Z

[`seeded/pipeline-desktop-opus/20261102T062442Z/CELL.md`](seeded/pipeline-desktop-opus/20261102T062442Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T06:24:42Z; from `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261102T092119Z

[`seeded/pipeline-desktop-opus-run2/20261102T092119Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261102T092119Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T09:21:19Z; from `pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json`; evidence complete.

### independent · claude-code · 2026-11-02-a

[`independent/claude-code/2026-11-02-a/CELL.md`](independent/claude-code/2026-11-02-a/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 4; 2026-11-02T06:12:30Z; from `claude-code-4papers-all-modes-2026-11-02.json`; evidence complete.

### independent · claude-code · 2026-11-02-b

[`independent/claude-code/2026-11-02-b/CELL.md`](independent/claude-code/2026-11-02-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-02T09:06:52Z; from `claude-code-run2-4papers-indep-blind-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261102T064502Z

[`independent/pipeline-desktop-opus/20261102T064502Z/CELL.md`](independent/pipeline-desktop-opus/20261102T064502Z/CELL.md) — final 11/13, re-scored 11/13; first scored 10/13; executions 4; 2026-11-02T06:45:02Z; from `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261102T142444Z

[`independent/pipeline-desktop-opus-run2/20261102T142444Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261102T142444Z/CELL.md) — final 11/13, re-scored 11/13; first scored 6/13; executions 4; 2026-11-02T14:24:44Z; from `pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-02-a

[`blind/claude-code/2026-11-02-a/CELL.md`](blind/claude-code/2026-11-02-a/CELL.md) — final 11/13, re-scored 11/13; first scored 11/13; executions 3; 2026-11-02T06:09:00Z; from `claude-code-4papers-all-modes-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-02-b

[`blind/claude-code/2026-11-02-b/CELL.md`](blind/claude-code/2026-11-02-b/CELL.md) — final 11/13, re-scored 11/13; first scored 11/13; executions 2; 2026-11-02T09:09:00Z; from `claude-code-run2-4papers-indep-blind-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261102T062442Z

[`blind/pipeline-desktop-opus/20261102T062442Z/CELL.md`](blind/pipeline-desktop-opus/20261102T062442Z/CELL.md) — final 10/13, re-scored 10/13; first scored 10/13; executions 3; 2026-11-02T06:24:42Z; from `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261102T144228Z

[`blind/pipeline-desktop-opus-run2/20261102T144228Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261102T144228Z/CELL.md) — final 10/13, re-scored 10/13; first scored 10/13; executions 4; 2026-11-02T14:42:28Z; from `pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json`; evidence complete.

