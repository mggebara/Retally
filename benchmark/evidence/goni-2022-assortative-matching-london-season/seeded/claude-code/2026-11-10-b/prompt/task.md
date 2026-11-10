# Retally reproduction task: goni-2022-assortative-matching-london-season (seeded, run 2026-11-10-b)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `goni-2022-assortative-matching-london-season`, mode `seeded`, run `2026-11-10-b`
- Paper: Assortative Matching at the Top of the Distribution: Evidence from the World's Most Exclusive Marriage Market
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/seeded/2026-11-10-b/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/seeded/2026-11-10-b/mount/goni_2022_assortative_matching_london_season`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/goni-2022-assortative-matching-london-season/seeded/2026-11-10-b`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/seeded/2026-11-10-b/mount/goni_2022_assortative_matching_london_season` as data, and `<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/seeded/2026-11-10-b/paper.txt` as
  the paper.
- Do not read anything else in this repository or on this machine: not the
  catalog YAMLs under `benchmark/papers/`, not `.cache/datasets/`, not
  `benchmark/results/`, not other reproductions under `benchmark/reproductions/`,
  not other task directories.  If you nevertheless read any other file, list
  it in `files_read_outside_mount` in `reproduction.json`, with why.
- Seeded mode: the authors' own analysis scripts are on disk under the data
  directory and reproduced below under "Original Replication Scripts".  You
  may follow them:

  The replication package (the dataset directory) ships the authors' own analysis scripts,
  reproduced below.  These are the GROUND TRUTH for the exact estimating equation, variable names,
  sample restrictions, fixed effects, and standard-error clustering — follow them over anything
  reconstructed from the methodology summary, and prefer them over the paper's text where the two
  disagree.  Your job is to write R code that implements the SAME SPECIFICATION: translate what the
  scripts estimate, do not transliterate their syntax line by line (a Stata .do file's regression,
  e.g. `reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the equivalent fixest::feols() call
  in R).  Keep only the parts that produce the specific claims being reproduced; skip figure
  construction and unrelated robustness checks.  The scripts' data-file paths refer to the package's
  internal layout — resolve them against the dataset directory listed under Dataset Information.
- You may compare your `RESULT:` values with the claimed values yourself.
  Every time you do that and then change the script, record the run you
  compared as an attempt with `kind: "claim"`, and write the comparison you
  made to that attempt's `feedback.txt`, one line per off-target claim in
  the form `<name>: reproduced <v>, claimed <c>`.  Produce it with:

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/goni-2022-assortative-matching-london-season/seeded/2026-11-10-b --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Claims to Reproduce
1. treatment_married_commoner_table2_panelA_col1: 0.005 (change in the probability of marrying a commoner per percentage point of synthetic probability) [type: coefficient]
   Location: Table 2, Panel A (Baseline), column (1) Married a commoner, Treatment
   Context: Table 2 ("The Season's Interruption and Marriage Outcomes, Probit, and OLS Estimation"), Panel A, column (1). Probit of an indicator for marrying a commoner (a husband classed as a commoner rather than a peer, a peer's son or a member of the gentry) on the treatment: a woman's synthetic probability (in percent) to marry during the interruption of the London Season (1861-1863), the sum of the percentages of women marrying at her ages in 1861, 1862 and 1863 in "normal times", computed from a benchmark cohort of peers' daughters born 1815-1830 (excluding those who married after 1861 or died befor…
2. treatment_married_heir_table2_panelA_col2: -0.004 (change in the probability of marrying a peer's heir per percentage point of synthetic probability) [type: coefficient]
   Location: Table 2, Panel A (Baseline), column (2) Married an heir, Treatment
   Context: Table 2, Panel A, column (2): the same probit as column (1) with an indicator for marrying an heir (a husband who would inherit a peerage title) as the outcome; marginal effect of the synthetic probability to marry during the interruption. Same controls, baseline sample and birth-year clustered standard errors.
3. treatment_landholdings_diff_abs_table2_panelA_col3: 0.524 (percentile ranks of family landholdings per percentage point of synthetic probability) [type: coefficient]
   Location: Table 2, Panel A (Baseline), column (3) Spouses' landholdings, Difference (absolute value), Treatment
   Context: Table 2, Panel A, column (3). OLS of the absolute difference between the spouses' birth families' landholdings, measured as percentile ranks in acres (Bateman 1883), on the synthetic probability to marry during the interruption and the Table 2 controls. Sample: the baseline sample restricted to marriages for which Bateman lists both spouses' family landholdings. Larger values mean less sorting. Standard errors clustered by birth year.
4. treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4: -0.516 (percentile ranks of family landholdings per percentage point of synthetic probability) [type: coefficient]
   Location: Table 2, Panel A (Baseline), column (4) Spouses' landholdings, Difference (husband - wife), Treatment
   Context: Table 2, Panel A, column (4): OLS as in column (3) with the signed difference in family-landholdings percentile ranks, husband minus wife, as the outcome (negative values are women marrying poorer husbands). Same landholdings sample, controls and birth-year clustered standard errors.
5. treatment_married_down_table2_panelA_col5: 0.009 (change in the probability of marrying down per percentage point of synthetic probability) [type: coefficient]
   Location: Table 2, Panel A (Baseline), column (5) Married down, Treatment
   Context: Table 2, Panel A, column (5): probit of an indicator for marrying down (a husband from a family with smaller landholdings than the wife's) on the synthetic probability to marry during the interruption and the Table 2 controls, in the landholdings sample of columns (3)-(4); marginal effect of the treatment on the probability. Standard errors clustered by birth year.
6. treatment_never_married_table2_panelA_col6: 0.002 (change in the probability of never marrying per percentage point of synthetic probability) [type: coefficient]
   Location: Table 2, Panel A (Baseline), column (6) Never married, Treatment
   Context: Table 2, Panel A, column (6): probit of an indicator for never marrying on the synthetic probability to marry during the interruption and the Table 2 controls; marginal effect on the probability. Sample: peers' daughters aged 15-35 in 1861 whether they married or not, excluding those who died before age 35. The paper notes the effect is not statistically different from zero. Standard errors clustered by birth year.
7. treatment_married_commoner_table2_panelB_col1: 0.006 (change in the probability of marrying a commoner per percentage point of synthetic probability) [type: coefficient]
   Location: Table 2, Panel B (Controlling for distance to London), column (1) Married a commoner, Treatment
   Context: Table 2, Panel B, column (1): the Panel A column (1) probit with the distance between the woman's family seat and London added as a control, which restricts the sample to women with a family seat recorded in Burke (1826). Marginal effect of the synthetic probability to marry during the interruption; standard errors clustered by birth year.
8. treatment_married_heir_table2_panelB_col2: -0.005 (change in the probability of marrying a peer's heir per percentage point of synthetic probability) [type: coefficient]
   Location: Table 2, Panel B (Controlling for distance to London), column (2) Married an heir, Treatment
   Context: Table 2, Panel B, column (2): the married-an-heir probit with the distance from the family seat to London as an added control (women with a recorded family seat). Marginal effect of the treatment; standard errors clustered by birth year.
9. treatment_landholdings_diff_abs_table2_panelB_col3: 0.512 (percentile ranks of family landholdings per percentage point of synthetic probability) [type: coefficient]
   Location: Table 2, Panel B (Controlling for distance to London), column (3) Difference (absolute value), Treatment
   Context: Table 2, Panel B, column (3): the column (3) OLS of the absolute difference in spouses' family-landholdings percentile ranks with the distance from the family seat to London added (landholdings sample, women with a recorded family seat). Standard errors clustered by birth year.
10. treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4: -0.537 (percentile ranks of family landholdings per percentage point of synthetic probability) [type: coefficient]
   Location: Table 2, Panel B (Controlling for distance to London), column (4) Difference (husband - wife), Treatment
   Context: Table 2, Panel B, column (4): the column (4) OLS of the husband- minus-wife difference in family-landholdings percentile ranks with the distance from the family seat to London added. Standard errors clustered by birth year.
11. n_obs_table2_panelA_baseline: 644.0 (women (peers' daughters who ever married)) [type: count]
   Location: Table 2, Panel A, Observations, columns (1)-(2)
   Context: Number of observations in Table 2, Panel A, columns (1) and (2): the baseline sample of peers' daughters aged 15-35 in 1861 who ever married, excluding second marriages, women married to foreigners and royals.
12. n_obs_table2_panelA_landholdings: 324.0 (marriages) [type: count]
   Location: Table 2, Panel A, Observations, columns (3)-(5)
   Context: Number of observations in Table 2, Panel A, columns (3) to (5): the baseline marriages for which Bateman (1883) lists both spouses' family landholdings.
13. n_obs_table2_panelA_never_married: 765.0 (women (peers' daughters, married or not)) [type: count]
   Location: Table 2, Panel A, Observations, column (6)
   Context: Number of observations in Table 2, Panel A, column (6): peers' daughters aged 15-35 in 1861 including those who never married, excluding those who died before age 35.

## Dataset Information
Name: goni_2022_assortative_matching_london_season
Local path: <repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/seeded/2026-11-10-b/mount/goni_2022_assortative_matching_london_season
File format: csv
Files in the dataset directory (paths relative to the local path above):
- programs/01_dataprep/dta-temp-files/final-data-men.dta (13.2 MB) — 1764 rows, 392 columns: title, entry, notes, heir, peerage, fmissmatch, fmissmatch2, biorder, fdown, missA, missV, heirspo, cOut, mheir, fatotal, nmarriages, nthismarriage, myear, mbefore, mafter, mage, syntheticT, entryflag, spousesurname, distlondon, soleheirship, allstillbirths, alllivebirths, oldfamily, soldfamily, base_sample, marital_rates_sample, heirstatus, peeragespo, ppeeragespo, hpeeragespo, bbefore, bafter, dbefore, dafter, sbbefore, sbafter, sdbefore, sdafter, dsbefore, dsafter, ppeerag…
- data/final-data-sec4.dta (25.7 MB) — 387 rows, 908 columns: title, entry, notes, heir, peerage, fmissmatch, fmissmatch2, biorder, cs, fdown, cOut, mheir, fatotal, nthismarriage, nmarriages, myear, mbefore, mafter, mage, syntheticT, distlondon, soleheirship, entryflag, spousesurname, allstillbirths, alllivebirths, oldfamily, soldfamily, base_sample, marital_rates_sample, peeragespo, ppeeragespo, hpeeragespo, bbefore, bafter, dbefore, dafter, sbbefore, sbafter, sdbefore, sdafter, dsbefore, dsafter, ppeerage, hpeerage, rankstrg, rankspo,…
- data/final-data.dta (220.5 MB) — 30414 rows, 360 columns: title, entry, notes, heir, peerage, fmissmatch, fmissmatch2, biorder, fdown, cOut, mheir, fatotal, nmarriages, nthismarriage, myear, mbefore, mafter, mage, syntheticT, soleheirship, entryflag, spousesurname, distlondon, allstillbirths, alllivebirths, oldfamily, soldfamily, base_sample, marital_rates_sample, peeragespo, ppeeragespo, hpeeragespo, bbefore, bafter, dbefore, dafter, sbbefore, sbafter, sdbefore, sdafter, dsbefore, dsafter, ppeerage, hpeerage, rankstrg, rankspo, pra…
- data/placebo-data.dta (8.1 MB) — 24628 rows, 65 columns: title, biorder, synthetic_plac, nthismarriage, myear, mage, syntheticT, crankspo, distlondon, sample01, sample0, base_sample, refno, byear, bdate, prank, pr4, hengpee, cOut, mheir, age1811, age1861_plac, mourn_plac, age1812, age1813, age181…
- README.pdf (320.2 KB)
- data/bateman-master.txt (327.9 KB)
- data/biographies.xls (2.0 MB)
- data/constituencies.xlsx (10.9 KB)
- data/countycntrls.txt (2.1 KB)
- data/familyseats.txt (210.8 KB)
- data/landholings-baseline-sample.txt (73.3 KB)
- data/peers.txt (9.7 MB)
- data/seasonattend.txt (13.0 KB)
- data/shapefiles/IseatXsb_10mi.cpg (5 B)
- data/shapefiles/IseatXsb_10mi.dbf (4.0 MB)
- data/shapefiles/IseatXsb_10mi.prj (417 B)
- data/shapefiles/IseatXsb_10mi.sbn (31.1 KB)
- data/shapefiles/IseatXsb_10mi.sbx (1.4 KB)
- data/shapefiles/IseatXsb_10mi.shp (90.3 KB)
- data/shapefiles/IseatXsb_10mi.shp.xml (9.6 KB)
- data/shapefiles/IseatXsb_10mi.shx (25.9 KB)
- data/shapefiles/IseatXsb_10mi.txt (891.4 KB)
- data/shapefiles/IseatXsb_10mi.txt.xml (9.6 KB)
- data/shapefiles/Iyver.img (3.8 MB)
- data/shapefiles/Iyver.img.aux.xml (2.3 KB)
- data/shapefiles/Iyver.rrd (1.4 MB)
- data/shapefiles/eng_counties.cpg (5 B)
- data/shapefiles/eng_counties.dbf (3.2 KB)
- data/shapefiles/eng_counties.prj (417 B)
- data/shapefiles/eng_counties.sbn (492 B)
- data/shapefiles/eng_counties.sbx (140 B)
- data/shapefiles/eng_counties.shp (3.3 MB)
- data/shapefiles/eng_counties.shp.xml (1.2 KB)
- data/shapefiles/eng_counties.shx (412 B)
- data/shapefiles/eng_dissolved.cpg (5 B)
- data/shapefiles/eng_dissolved.dbf (73 B)
- data/shapefiles/eng_dissolved.prj (145 B)
- data/shapefiles/eng_dissolved.sbn (132 B)
- data/shapefiles/eng_dissolved.sbx (116 B)
- data/shapefiles/eng_dissolved.shp (630.5 KB)
- data/shapefiles/eng_dissolved.shp.xml (5.0 KB)
- data/shapefiles/eng_dissolved.shx (108 B)
- data/shapefiles/fig11_example.cpg (5 B)
- data/shapefiles/fig11_example.dbf (9.2 KB)
- data/shapefiles/fig11_example.prj (417 B)
- data/shapefiles/fig11_example.sbn (236 B)
- data/shapefiles/fig11_example.sbx (124 B)
- data/shapefiles/fig11_example.shp (408 B)
- data/shapefiles/fig11_example.shp.xml (58.6 KB)
- data/shapefiles/fig11_example.shx (188 B)
- data/shapefiles/fig11_example2.cpg (5 B)
- data/shapefiles/fig11_example2.dbf (1.5 KB)
- data/shapefiles/fig11_example2.prj (417 B)
- data/shapefiles/fig11_example2.sbn (140 B)
- data/shapefiles/fig11_example2.sbx (116 B)
- data/shapefiles/fig11_example2.shp (28.1 KB)
- data/shapefiles/fig11_example2.shp.xml (12.3 KB)
- data/shapefiles/fig11_example2.shx (116 B)
- data/shapefiles/fig11_example3.cpg (5 B)
- data/shapefiles/fig11_example3.dbf (1.5 KB)
- data/shapefiles/fig11_example3.prj (417 B)
- data/shapefiles/fig11_example3.sbn (164 B)
- data/shapefiles/fig11_example3.sbx (124 B)
- data/shapefiles/fig11_example3.shp (156 B)
- data/shapefiles/fig11_example3.shp.xml (2.0 KB)
- data/shapefiles/fig11_example3.shx (116 B)
- data/shapefiles/pline_british_isles.cpg (5 B)
- data/shapefiles/pline_british_isles.dbf (65.8 KB)
- data/shapefiles/pline_british_isles.prj (145 B)
- data/shapefiles/pline_british_isles.sbn (13.2 KB)
- data/shapefiles/pline_british_isles.sbx (740 B)
- data/shapefiles/pline_british_isles.shp (9.0 MB)
- data/shapefiles/pline_british_isles.shp.xml (50.3 KB)
- data/shapefiles/pline_british_isles.shx (10.6 KB)
- data/shapefiles/schema.ini (511 B)
- data/shapefiles/schoolboards_all.cpg (5 B)
- data/shapefiles/schoolboards_all.dbf (980.5 KB)
- data/shapefiles/schoolboards_all.prj (417 B)
- data/shapefiles/schoolboards_all.sbn (14.6 KB)
- data/shapefiles/schoolboards_all.sbx (1.1 KB)
- … and 206 more files (listing truncated)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/seeded/2026-11-10-b/mount/goni_2022_assortative_matching_london_season' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
Installed packages (no network; nothing else can be installed): jsonlite, fixest, lfe, AER, ivreg, plm, estimatr, lme4, quantreg, car, sandwich, lmtest, clubSandwich, multiwayvcov, marginaleffects, MatchIt, optmatch, CBPS, WeightIt, cobalt, did, rdrobust, rddensity, Synth, modelsummary, stargazer, texreg, broom, tidyverse, dplyr, tidyr, readr, stringr, lubridate, data.table, haven, readxl, janitor, zoo, ggplot2, ggridges, ggrepel, gridExtra, cowplot, gtable, extrafont, sf, MASS, nnet, survival, splines, Matrix, boot, stats, utils.
Prefer fixest for fixed effects, IV and clustered SEs; use the other installed packages where the paper's method calls for them.
Set a deterministic seed with ``set.seed(42)`` for any randomness.
Do NOT access the internet; the container runs with --network none.
Do NOT shell out via system() / system2().
Emit RESULT:<name>=<value> lines to stdout at the end via cat().

## Original Replication Scripts
The replication package (the dataset directory) ships the authors' own analysis scripts, reproduced below.  These are the GROUND TRUTH for the exact estimating equation, variable names, sample restrictions, fixed effects, and standard-error clustering — follow them over anything reconstructed from the methodology summary, and prefer them over the paper's text where the two disagree.  Your job is to write R code that implements the SAME SPECIFICATION: translate what the scripts estimate, do not transliterate their syntax line by line (a Stata .do file's regression, e.g. `reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the equivalent fixest::feols() call in R).  Keep only the parts that produce the specific claims being reproduced; skip figure construction and unrelated robustness checks.  The scripts' data-file paths refer to the package's internal layout — resolve them against the dataset directory listed under Dataset Information.

Stata-to-fixest sample matching: feols() drops fixed-effect singletons by default, but Stata's `reg y x i.fe` / `xi:` dummies keep them.  Pass `fixef.rm = "none"` to every feols() call that has fixed effects, otherwise the observation count and the robust SEs drift from the paper's.  Stata's `, r` / `vce(robust)` is `vcov = "hetero"`.

### `programs/01_dataprep/master-dataprep.do`
```stata
/*******************************************************************************

This file contains the code to generate the variables and samples used in the
analysis.

	Contents:
	1. Hollingsworth's Genealogical Data on the Peerage (2001)
	2. Family seats from Burke's Heraldic Dictionary (1826)
	3. Family landholdings from Bateman (1883)
	4. Attendance to the Season
	5. Save final data for peerage marriages 
	6. Data for placebo tests
	7. Data for Secion 4 (Implications)
		7.1 Political power data
		7.2 Education provision by local School Boards
	8. Labels


The file "3 Replication package\programs00_setup.do" sets the path to all 
directories and installs the required ado packages. If you want to run this 
do file individually, unmark and specify location of parent directory here:

	*global dirroot = "SPECIFY\LOCATION\OF\PARENT\DIRECTORY\HERE"

and then run the following lines for the secondary directories (specified as 
downloaded in replication package):
	
	global dirdata = "${dirroot}\data"
	global dirdta  = "${dirroot}\programs\01_dataprep\dta-temp-files"
	global dirresu = "${dirroot}\results"

*******************************************************************************/




* ==============================================================================
* 1. HOLLINGSWORTH'S GENEALOGICAL DATA ON THE PEERAGE (2001)
* ------------------------------------------------------------------------------
/* This Section of the do file imports the original Hollingsworth genealogical 
   dataset and generates the following variables:
   1.1. Demographic characteristics:
	    gender; age at marriage; age at death; birth order (excluding heirs);
		celibacy.
   1.2. Social status:
	    own rank; parental rank; spouse rank; rank separating 6 titles.
   1.3. Peerage of origin (England and Wales, Scotland, Ireland).
  	    own; parental; highest; spouse.
   1.4. Assortative matching by social status:
        married a commoner; married an heir.
   1.5. Exposure to the interruption (1861-63):
        age at the start of the interruption; synthetic probability to marry 
		during the interruption; synthetic probability for the placebo samples; 
		married in 1861-63.
   1.6. Cohort variables.
	    size of the female cohort.
* ============================================================================ */



* Import original Hollingsworth dataset
clear all
set more off
insheet using "${dirdata}\peers.txt"



* ==============================================================================
* 1.1 DEMOGRAPHIC CHARACTERISTICS
* ------------------------------------------------------------------------------

* gender

gen wom = (sexdeath == 4 | sexdeath == 5 | sexdeath ==6)
replace wom = 1 if heir==4 | heir==5 & sexdeath==.


* age at marriage and age at death

foreach z in b d m sb sd{
qui replace `z'month = "x" if `z'month=="X"		// re-code months
qui replace `z'month = "y" if `z'month=="Y"
label define `z'month1 1 "x" 2 "y" 3 "0" 4 "1" 5 "2" 6 "3" 7 "4" 8 "5" 9 "6" 10 "7" 11 "8" 12 "9"
encode `z'month, gen(`z'month1)
gen `z'date = mdy(`z'month1, `z'day, `z'year)	// dates in %td format
format `z'date %td
drop `z'month1
}
gen smage0 = mdate-sbdate		
gen sdage0 = sddate-sbdate
foreach z in m d{
gen `z'age0  = `z'date-bdate					// age at marriage for individual and for his/her spouse
gen `z'age = floor(`z'age0/365)
gen s`z'age = floor(s`z'age0/365)
}
drop mage0 dage0 smage0 sdage0


* birth order, excluding heirs

	/* Note: The reference number (refno) of non-heirs is a consecutive number
	of the refno of their fathers (who are peers or peers' heirs). Here I use 
	the last digits of refno to identify an individual's birth order (excluding
	heirs, whose refno is not a consecutive number of their fathers'). */

tostring refno, gen(str_refno)
gen biorder = substr(str_refno,-2,.)
replace biorder = "10" if biorder=="0"
destring biorder, replace
replace biorder = biorder-50 if biorder>=50 & biorder<80
replace biorder = 2 if refno==163800		// manual corrections (from full matching of parents and children in Gobbi & Goni 2020 EJ)
replace biorder = 1 if refno==305600
replace biorder = 1 if refno==326150
replace biorder = 3 if refno==121600
replace biorder = 2 if refno==214882
replace biorder = 4 if refno==30200
replace biorder = 1 if refno==216850
replace biorder = 2 if refno==318250
replace biorder = 1 if refno==324900
replace biorder = 1 if refno==334850
replace biorder = 1 if refno==355800
replace biorder = 1 if refno==141242
replace biorder = 1 if refno==26250
replace biorder = 4 if refno==112406
replace biorder = 6 if refno==112408
replace biorder = 1 if refno==137403
replace biorder = 4 if refno==138402
replace biorder = 5 if refno==138408
replace biorder = 1 if refno==214881
replace biorder = 1 if refno==235341
*
replace biorder = 1  if refno==15891
replace biorder = 5  if refno==15895
replace biorder = 8  if refno==66512
replace biorder = 9  if refno==66513
replace biorder = 9  if refno==93061
replace biorder = 11 if refno==112863
replace biorder = 12 if refno==112864
replace biorder = 16 if refno==112868
replace biorder = 6  if refno==185176
replace biorder = 10 if refno==185180
replace biorder = 12 if refno==185182
replace biorder = 1  if refno==188891
replace biorder = 14 if refno==185184
replace biorder = 6  if refno==234358
replace biorder = 2  if refno==67804


* celibacy
gen celibacy = (nthismarr==0)
label var celibacy "Celibacy"



* ==============================================================================
* 1.2 SOCIAL STATUS
* ------------------------------------------------------------------------------

* recode rank variables in Hollingsworth dataset to numeric

foreach var of varlist hss hsh hsc originspouse hfs hfh hfc hms hmh hmc originparent{
qui replace `var' = "x" if `var'=="X"
qui replace `var' = "y" if `var'=="Y"
label define `var'1 0 "x" 1 "y" 2 "0" 3 "1" 4 "2" 5 "3" 6 "4" 7 "5" 8 "6" 9 "7" 10 "8" 11 "9"
encode `var', generate(`var'1)
qui gen rk`var' = .
qui replace rk`var' = 0 if `var'1==0 | `var'1==1 | `var'1==2	// Foreign
qui replace rk`var' = 1 if `var'1==3							// Commoner
qui replace rk`var' = 2 if `var'1==4							// Knight
qui replace rk`var' = 3 if `var'1==5							// Baronet
qui replace rk`var' = 4 if `var'1==9 | `var'1==10 | `var'1==11	// Viscount, Baron
qui replace rk`var' = 5 if `var'1==6 | `var'1==7  | `var'1==8	// Duke, Earl, Marquess
}
rename rank rankstrg


* Categorizartion for own, parental, and spouse titles, separating those received 
* from those one was heir at age 15

gen rank = max(rkhss,rkhsc,rkhsh)					 			// Highest title HIMSELF succeeded to, was heir to at age 15, or was created for him.
gen hrank = rkhsh	 								 			// Highest title HIMSELF was heir to at age 15.
rename rkoriginspouse rankspo						 			// Highest title the SPOUSE succeeded to, was heir to at age 15, or was created for.
gen prank = max(rkhfs,rkhfc,rkhfh,rkhms,rkhmc,rkhmh) 			// Highest title the PARENT succeeded to, was heir to at age 15, or was created for.
rename rkoriginparent prankspo						 			// Highest title the SPOUSE (highest ranked) PARENT succeeded to, was heir to at age 15, or was created for.
label define rnk 0 "Foreign" 1 "Commoner" 2 "Knight" 3 "Baronet" 4 "Baron" 5 "Duke" // labels (1)
label values rank rankspo hrank prank prankspo rnk
label define hnk 0 "Foreign" 1 "Commoner at 15" 2 "Knight" 3 "Baronet" 4 "Baron" 5 "Duke" // labels (2)
label values hrank hnk 
gen hrankspo = rankspo
gen womspo = 1-wom


* Categorization separating Dukes and Barons' younger sons (crank and crankspo)

foreach x in "" spo{
gen crank`x' = .
gen prank`x'2 = prank`x'+2 	// just done to adjust levels such that values to daughters of knights, baronets, viscount-barons, and duke-earl-marquis are, respectively, 4, 5, 6, and 7.
qui replace crank`x' = prank`x'  if wom`x'==1 & prank`x'<=1 	// Women receive parental rank
qui replace crank`x' = prank`x'2 if wom`x'==1 & prank`x'> 1 
drop prank`x'2
qui replace crank`x' = 0 if wom`x'==0 & hrank`x'==0 & prank`x'<4	// Foreign (men)
qui replace crank`x' = 1 if wom`x'==0 & hrank`x'==1 & prank`x'<4	// Pure blood commoners (men)
qui replace crank`x' = 2 if wom`x'==0 & hrank`x'==0 & prank`x'==4	// Barons's younger sons (men)
qui replace crank`x' = 2 if wom`x'==0 & hrank`x'==1 & prank`x'==4	 
qui replace crank`x' = 2 if wom`x'==0 & hrank`x'==2 & prank`x'==4	 
qui replace crank`x' = 2 if wom`x'==0 & hrank`x'==3 & prank`x'==4	 
qui replace crank`x' = 3 if wom`x'==0 & hrank`x'==0 & prank`x'==5	// Dukes's younger sons (men)
qui replace crank`x' = 3 if wom`x'==0 & hrank`x'==1 & prank`x'==5	 
qui replace crank`x' = 3 if wom`x'==0 & hrank`x'==2 & prank`x'==5	 
qui replace crank`x' = 3 if wom`x'==0 & hrank`x'==3 & prank`x'==5	 
qui replace crank`x' = 4 if wom`x'==0 & hrank`x'==2 & prank`x'<4	// Knights (men)
qui replace crank`x' = 5 if wom`x'==0 & hrank`x'==3 & prank`x'<4	// Baronets (men)
qui replace crank`x' = 6 if wom`x'==0 & hrank`x'==4					// Viscount, baron (men)
qui replace crank`x' = 7 if wom`x'==0 & hrank`x'==5					// Duke, earl, marquess (men)
}
label define crnk 0 "Foreign" 1 "Pure commoner" 2 "Baron younger son" 3 "Duke younger son" 4 "Knight" 5 "Baronet" 6 "Baron" 7 "Duke" // labels
label values crank crankspo crnk
drop womspo


* Categorization grouping Peers' sons and Gentry (grank and grankspo)

* ranks for wives
foreach x in "" spo{
gen grank`x' = crankspo if crank`x'<2	// below gentry
}
replace grank = 2 if crank==2 | crank`x'==3
replace grank = 3 if crank==4 | crank`x'==5
replace grank = 4 if crank==6
replace grank = 5 if crank==7
replace grank = 4 if rank==4 & grank==1
replace grank = 5 if rank==5 & title=="Cromartie" // corrections
replace grank = 5 if parent=="14E Moray/18B Gray?" // Earl Moray > Baron Grey
replace grank = 5 if refno==26250 // Earl's grand-daughter
label define frank_lbl 4 "Baron dau." 5 "Duke dau."	// labels
label values grank frank_lbl
* ranks for husbands
replace grankspo = 2 if crankspo==4 | crankspo==5 // husband is gentry
replace grankspo = 3 if crankspo==2 | crankspo==3 // husband is peers' son 
replace grankspo = 4 if crankspo==6	| crankspo==7 // husband is peers' heir
replace grankspo = 1 if grankspo==0				  // below gentry in one category
label define grankspo_lbl2 1 "Commoner" 2 "Gentry" 3 "Peer son" 4 "Peer heir" // labels
label values grankspo grankspo_lbl2
* this is only used for women and their husbands
replace grank = . if wom==0
replace grankspo = . if wom==0


* Indicator for dukes', earls', marquis' daughters

gen pr4 = (prank==5 & wom==1)


* Separating Dukes', Earls', Marquis', Barons', Viscounts' daughters as 6 categories 

	/* Note: To separate these titles, I use a string variable in the Hollingsworth 
	dataset (father's form of address) and biographical data from thepeerage.com.
	This is done only for the baseline sample (i.e., peers' daughters aged 15-35 
	in 1861 who ever married, excluding second-marriages, women married to 
	foreigners, and members of the royal family). For details, see Footnote 39 
	and Appendix B3 "Contingency tables separating wives' titles." */

gen parent0 = parent
replace parent0 = trim(parent)
* Using fathers' form of address (barons' daughters)
replace parent0="B" if parent0=="/8Bs Clifton" | parent0=="1?B" | parent0=="10B"	///
	| parent0=="11B" | parent0=="11Bs" | parent0=="11Bs/6B Byron" | parent0=="12B"	/// 
	| parent0=="12Bs" | parent0=="13B" | parent0=="13Bs" | parent0=="14B"	///
	| parent0=="15B" | parent0=="15B Darcy" | parent0=="15Bs" | parent0=="16B"	///
	| parent0=="16Bs" | parent0=="16Bs/8B Teynham" | parent0=="18B" | parent0=="1B"	///
	| parent0=="1B 1" | parent0=="1B Abinger" | parent0=="1B Howard of Effingham"	///
	| parent0=="1B Lucas of Shenfield" |  parent0=="1B/1Bs" | parent0=="1Bs"	///
	| parent0=="20B" | parent0=="B" | parent0=="20Bs" | parent0=="21B" 	///
	| parent0=="21Bs" | parent0=="22B" | parent0=="22Bs" | parent0=="23B" 	///
	| parent0=="24B" | parent0=="24Bs" | parent0=="27B" | parent0=="28B"		///
	| parent0=="2B" | parent0=="2B 2B" | parent0=="2B Wotton" | parent0=="2Bs"		///
	| parent0=="2Bs Keith" | parent0=="3B" | parent0=="3B Lovelace" | parent0=="3Bs"	///
	| parent0=="4B" | parent0=="4B Lennox(S)" | parent0=="4B Oliphant" | parent0=="6B"	///
	| parent0=="6B Abergavenny" | parent0=="6Bs" | parent0=="s&h 2B" | parent0=="s&h 6B"	///
	| parent0=="s&h ap 3B" | parent0=="s&h12B" | parent0=="s&h13B" | parent0=="s&h2B"	///
	| parent0=="s&h3B" | parent0=="s&h5B" | parent0=="SH 9B Hon Sir Thomas"	///
	| parent0=="SH11B" | parent0=="sh2B" | parent0=="SH9B" | parent0=="soh2B Clifford 3Cs"	///
	| parent0=="soh4B" | parent0=="25B" | parent0=="5B" | parent0=="5Bs"	///
	| parent0=="7B" | parent0=="7B Ogle" | parent0=="7Bs/2B" | parent0=="8B"	///
	| parent0=="8Bs" | parent0=="9B" | parent0=="9B Cathcart(S)" | parent0=="9Bs"	///
	| parent0=="B" | parent0=="h2B" | parent0=="h5B" | parent0=="h7B" | parent0=="17B"	///
	| parent0=="19B" | parent0=="19Bs"
* Using fathers' form of address (viscounts' daughters)
replace parent0="V" if parent0=="10V" | parent0=="11V" | parent0=="12V"	///
	| parent0=="13V" | parent0=="14V" | parent0=="15V" | parent0=="16V"	///
	| parent0=="1S 1M" | parent0=="1V" | parent0=="1V Bayning of Sudbury"	///
	| parent0=="1V Bayning-life" | parent0=="1V Cobham" | parent0=="1V/4V"	///
	| parent0=="1Vs" | parent0=="1Vs/h4V" | parent0=="2V" | parent0=="2V 2V"	///
	| parent0=="2V Grandison" | parent0=="3V" | parent0=="4V" | parent0=="5V"	///
	| parent0=="6V" | parent0=="7V" | parent0=="9V" | parent0=="9Vs/2V Ferrard"	///
	| parent0=="H 1V" | parent0=="8V" | parent0=="H 4V/1Vs" | parent0=="H 7V" 	///
	| parent0=="h3V" | parent0=="s&h 4V" | parent0=="s&h 7V" | parent0=="s&h1V"	///
	| parent0=="s&h2V" | parent0=="s&h5V" | parent0=="SH 4V" | parent0=="SH2V"	///
	| parent0=="soh 2V" | parent0=="V Maidstone" | parent0=="Vs"
* Using fathers' form of address (earls' daughters)
replace parent0="E" if parent0=="10E" |  parent0=="10E/11E" | parent0=="11E"	///
	| parent0=="11ESuffolk/4E Berkshire"  | parent0=="12E" | parent0=="13E"	///
	| parent0=="13E/11E" | parent0=="14E" | parent0=="15E" | parent0=="15E/16E"	///
	| parent0=="16E" | parent0=="17E" | parent0=="18E" | parent0=="19E"	///
	| parent0=="1E" | parent0=="1E Bath" | parent0=="1E Cleveland"	///
	| parent0=="1E Consingby" | parent0=="1E de Grey" | parent0=="1E Desmond(I)"	///
	| parent0=="1E Lovelace" | parent0=="1E Pembroke" | parent0=="1E Rivers"	///
	| parent0=="1E Sussex" | parent0=="1E Talbot" | parent0=="1s12E"	///
	| parent0=="20E" | parent0=="21E" | parent0=="22E" | parent0=="24E"	///
	| parent0=="25E" | parent0=="26E" | parent0=="2E" | parent0=="2E Arran(I)"	///
	| parent0=="2E Peterborough" | parent0=="2E/1E" | parent0=="2E? [3]" 	///
	| parent0=="3E" | parent0=="3E Breadalbane(S)" | parent0=="3E Clarendon"	///
	| parent0=="3E Guilford" | parent0=="3E of Cumberland" | parent0=="3E Selkirk/1E Ruglen"	///
	| parent0=="3E/1E" | parent0=="3E/2E" | parent0=="3ETyrone(I)"	///
	| parent0=="H 1E Limerick" | parent0=="4E" | parent0=="4E/3E" 	///
	| parent0=="4E/3E Cork/Burlington" | parent0=="5E" | parent0=="5E Cumberland"	///
	| parent0=="5E Plymouth" | parent0=="5E/2E" | parent0=="6E" | parent0=="6E Rutland"	///
	| parent0=="6E Thanet" |  parent0=="6E/1E" |  parent0=="6E/23E" | parent0=="7E"	///
	| parent0=="7E/2E" | parent0=="9E" | parent0=="9E Huntingdon" | parent0=="h 2E"	///
	| parent0=="h 5E" | parent0=="h1E" | parent0=="H2E" | parent0=="h2E"	/// 
	| parent0=="h3E" | parent0=="h8E" | parent0=="hap1E" | parent0=="s&h19E"	///
	| parent0=="s&h1E" | parent0=="s&h20E" | parent0=="s&h4E" | parent0=="s&h5E"	///
	| parent0=="s&h7E" | parent0=="s&h9E" | parent0=="s1E" | parent0=="s2E"	///
	| parent0=="SH 5E" | parent0=="SH 6E" | parent0=="SH5E" | parent0=="sh6E"	///
	| parent0=="SHapp 6E" | parent0=="soh 1E" | parent0=="soh 6E Thomond(I)"	///
	| parent0=="soh11E" | parent0=="soh1ERockingham" | parent0=="soh2E"	///
	| parent0=="soh3E" | parent0=="soh6E" | parent0=="soh8E" | parent0=="8E"
* Using fathers' form of address (marquis' daughters)
replace parent0="M" if parent0=="10M" | parent0=="12M" | parent0=="13M"	///
	| parent0=="14M" | parent0=="1M" | parent0=="1M 1M" | parent0=="2M"	///
	| parent0=="2M 2 2M" | parent0=="2M Hastings" | parent0=="3M"	///
	| parent0=="4M" | parent0=="5M" | parent0=="6M" | parent0=="7M"	///
	| parent0=="8M" | parent0=="8M 8 8 8 8M" | parent0=="9M" | parent0=="SH 3M"	///
	| parent0=="SH1M"
* Using fathers' form of address (dukes' daughters)
replace parent0="D" if parent0=="/h 1D Beaufort" | parent0=="10D" | parent0=="11D"	///
	| parent0=="12D" | parent0=="13D" | parent0=="14D" | parent0=="15D" | parent0=="1D"	///
	| parent0=="1d" | parent0=="1D Kent" | parent0=="1D Leinster" | parent0=="1Ds"	///
	| parent0=="19D" | parent0=="2D" | parent0=="2D Argyll" | parent0=="2D Richmond"	///
	| parent0=="3D" | parent0=="3D Ancaster" | parent0=="3D Dorset" | parent0=="3Ds&1D"	///
	| parent0=="4D" | parent0=="5D" | parent0=="6D" | parent0=="7D" | parent0=="7DSomerset"	///
	| parent0=="9D" | parent0=="h 1D" | parent0=="h2D" | parent0=="h3D" | parent0=="soh1D"	///
	| parent0=="soh 1D" | parent0=="soh 2D" | parent0=="8D"
* Double titles
replace parent0="B/V" if parent0=="10B/1V" | parent0=="2B/1V" | parent0=="V/B"
replace parent0="B/E" if parent0=="13Bs&1E" | parent0=="9Bs Congers/4EHuldernesse" ///
	| parent0=="H 3B & 1E"
replace parent0="B/C" if parent0=="14B Dacre/1Cs"
replace parent0="E/B" if parent0=="14E Moray/18B Gray?" | parent0=="1E/10B" ///
	| parent0=="1E/4B?" | parent0=="1E/8B" | parent0=="2E/1Bs Arden"  ///
	| parent0=="B/E" | parent0=="5E/1Bs Buckhurst"
replace parent0="E/B/V" if parent0=="1E Berkshire 2B Norris&V Thame"
replace parent0="E/M" if parent0=="19E/1M" | parent0=="2E Hardwicke/2Ms Grey" | parent0=="M/E"
replace parent0="V/B" if parent0=="s 2V/1B" | parent0=="1V&14Bs Strange" | parent0=="1V1B"
replace parent0="D/E" if parent0=="2Ds/2E Godolphin"
replace parent0="M/E" if parent0=="2M/E" | parent0=="2Ms/2E Hardwicke"
replace parent0="C/V" if parent0=="1Cs/1V" | parent0=="1Cs/V"
replace parent0="C/E" if parent0=="2Cs&4E Inchiquin" | parent0=="6Cs/1E"
replace parent0="C/M" if parent0=="3Cs&1M Thomond"
replace parent0="V/E" if parent0=="V Kil/soh 7E"
* Other
replace parent0="C" if parent0=="10Cs" | parent0=="12Cs" | parent0=="14Cs"	///
	| parent0=="18Cs" | parent0=="1Cs" | parent0=="1Cs Temple" | parent0=="2Cs"	///
	| parent0=="3Cs" | parent0=="4Cs" | parent0=="7Cs" | parent0=="Cs"
replace parent0="King" if parent0=="King Charles I" | parent0=="King Edward VII"	///
	| parent0=="King George I" | parent0=="King George II" | parent0=="King George III"	///
	| parent0=="King George IV" |  parent0=="King George V" |  parent0=="King James I"	///
	| parent0=="King James II"
replace parent0="Queen" if parent0=="Queen Victoria"
replace parent0="" if parent0=="?" | parent0=="SH" | parent0=="sh"
* define variable separating titles
gen ownrank = 1 if parent0=="B"
replace ownrank = 2 if parent0=="V"
replace ownrank = 3 if parent0=="E" | parent0=="E/B"
replace ownrank = 4 if parent0=="M"
replace ownrank = 5 if parent0=="D"
drop parent0
* manual fillings using biographical info from thepeerage.com
replace ownrank=1 if refno==30200 | refno==59651 | refno==59654 | refno==26250 | refno==305600
replace ownrank=2 if refno==326150
replace ownrank=3 if refno==216904 | refno==70850
* labels
label define ownrank_lbl 1 "Baron" 2 "Viscount" 3 "Earl" 4 "Marquis" 5 "Duke"
label values ownrank ownrank_lbl



* ==============================================================================
* 1.3 PEERAGE OF ORIGIN
* ------------------------------------------------------------------------------

* peerage of origin for every title

foreach var of varlist hss hsh hsc originspouse hfs hfh hfc hms hmh hmc originparent{
gen peerage`var' = .
qui replace peerage`var' = 0 if `var'1<3				// Foreign						
qui replace peerage`var' = 1 if `var'1>=3 & `var'1<=5	// British commoners and gentry
qui replace peerage`var' = 2 if `var'1==6 | `var'1==9	// Peerage of England
qui replace peerage`var' = 3 if `var'1==7 | `var'1==10	// Peerage of Scotland
qui replace peerage`var' = 4 if `var'1==8 | `var'1==11	// Peerage of Ireland
}


* own peerage of origin

gen peerage = .
gen peeragespo = .
foreach var of varlist hss hsh hsc{
qui replace rk`var' = -1 if rk`var'==.
}
gen hssdir =(rkhss>=rkhsc & rkhss> rkhsh & rkhss!=.)	// First check whether the highest rank was succeded, inherited, or created (heir>suceeded>created).
gen hshdir =(rkhsh>=rkhss & rkhsh>=rkhsc & rkhsh!=.)
gen hscdir =(rkhsc> rkhss & rkhsc> rkhsh & rkhsc!=.)	
foreach var of varlist hss hsh hsc{						// Attach the corresponding Peerage origin
qui replace rk`var' = . if rk`var'==-1
qui replace peerage = peerage`var' if `var'dir==1
}
qui replace peeragespo = peerageoriginspouse


* parental peerage of origin

gen ppeerage = .
gen ppeeragespo = .
foreach y in hfs hfh hfc hms hmh hmc{
qui replace rk`y' = -1 if rk`y'==.
}
gen fath = max(rkhfs,rkhfc,rkhfh)							// First check whether the highest rank comes from her father or her mother.
gen moth = max(rkhms,rkhmc,rkhmh)
gen hfdir = (fath>=moth)	
foreach x in hf hm{											// Now check whether the highest rank was succeded, inherited, or created (succedeed>heir>created).
gen `x'sdir=(rk`x's>=rk`x'c & rk`x's>=rk`x'h)
gen `x'hdir=(rk`x'h> rk`x's & rk`x'h>=rk`x'c)
gen `x'cdir=(rk`x'c> rk`x's & rk`x'c> rk`x'h)
foreach y in s h c{
qui replace rk`x'`y' = . if rk`x'`y'==-1
}
}
foreach var of varlist hfs hfh hfc{							// Attach the corresponding Peerage origin
qui replace ppeerage = peerage`var' if `var'dir==1 & hfdir==1
}
foreach var of varlist hms hmh hmc{
qui replace ppeerage = peerage`var' if `var'dir==1 & hfdir==0
}
qui replace ppeeragespo = peerageoriginparent


* highest peerage of origin

gen maxparent = (prank>=rank)
foreach x in "" spo{
gen hpeerage`x' = peerage`x'
qui replace hpeerage`x' = ppeerage`x' if maxparent==1
qui replace hpeerage`x' = peerage`x' if maxparent==0
}


* labels

label define regg 0 "Foreign" 1 "British Commoner" 2 "Peerage of England" 3 "Peerage of Scotland" 4 "Peerage of Ireland" 
label values peerage peeragespo ppeerage ppeeragespo hpeerage regg


* indicator dummies

gen hforeign = (hpeerage==0)
gen hbritcom = (hpeerage==1)
gen hengpee  = (hpeerage==2)
gen hscotpee = (hpeerage==3)
gen hiripee  = (hpeerage==4)



* drop original rank and peerage string-variables

foreach x in hss hsh hsc hfs hfh hfc hms hmh hmc{
drop `x' `x'1 rk`x' peerage`x' `x'dir
}
drop originspouse originparent originspouse1 originparent1 peerageoriginspouse peerageoriginparent fath moth hfdir maxparent



* ==============================================================================
* 1.4 ASSORTATIVE MATCHING BY SOCIAL STATUS
* ------------------------------------------------------------------------------

* Married a commoner

gen cOut = ((rank>=4 | prank>=4)==1 & (rankspo>=4 | prankspo>=4)==0) // own or fathers' rank in the peerage & spouses or spouses' father rank NOT in the peerage
replace cOut=1 if refno==156356 // Spouse was not a peers' heir until his late 50s
replace grankspo = 1 if cOut==1 & grankspo>2 // corrections for rank variable used in contingency tables
replace grankspo = 4 if cOut==0 & grankspo>4


* Married an heir

qui gen mheir = (grankspo>=4) 		// marrying an heir
qui replace mheir = 0 if cOut==1	// correction



* ==============================================================================
* 1.5 EXPOSURE TO THE INTERRUPTION (1861-63)
* ------------------------------------------------------------------------------

* Age at the start of the 1861 Season

gen age1861 = floor((td(31mar1861)-bdate)/365)
replace age1861 = 1861-byear-1 if age1861==. & byear!=.


* Synthetic probability to marry in 1861-63 (treatment variable)

	/* Note: A woman's synthetic probability to marry in 1861-63 is based on her 
	age in 1861-63 and on the percentage of women marrying at each age in 
	"normal times" (i.e., before the interruption). My benchmark cohort for
	"normal times" is peers' daughters born in 1815-30, excluding those who married 
	after 1861 or died before age 30. See main text for details. */
	
preserve
keep if wom==1 & nthismarriage<2 & byear<=1830 & byear>=1815 & dage>30 	// sample for benchmark cohort
replace mage = myear-byear if nthismarr==1 & mage==.	// exclude those married after 1861
drop if myear>=1861 & myear!=.
replace mage = 999 if nthismarr==0	// missing age at marriage for those never married
replace nthismarr = 1 if nthismarr==0 // keep never married as they are used in the precentage denominator
collapse (sum) freq = nthismarr, by(mage)
sort mage
while mage[1]>15{	// in case no woman married at a given age (15, 16,...35)
set obs `=_N+1'
replace mage = mage[1]-1 in l
replace freq = 0 in l
sort mage
}
drop if mage==. 
replace freq = 0 if freq==.
egen tot = sum(freq)	// total women in benchmark cohort (i.e., percentage denominator)
sort mage	
gen prob = 100*freq/tot // synthetic probability at each age [p(.) in equation (1)]
drop if mage == 999
keep mage prob
sort mage
gen syntheticT = prob+prob[_n+1]+prob[_n+2]	// synthetic probability  [T=p(t)+p(t+1)+p(t+2) in equation (1)]
drop prob
rename mage age1861	// for the purpose of merging
sort age1861
keep if age1861>=15 & age1861<=35
label var age1861 "Age at the start of the 1861 Season"
label var syntheticT "Treatment"
save "${dirdta}\syntheticprob.dta", replace // save as temp dta file
restore
merge m:1 age1861 using "${dirdta}\syntheticprob.dta", nogen // merge for baseline sample
erase "${dirdta}\syntheticprob.dta" // erase temp dta file


* Synthetic probability treatment for placebo samples

	/* Note: A woman's synthetic probability to marry in a placebo interruption 
	occurring j years before the real interruption (i.e., from 1861-j to 1863-j) 
	is based on her age in 1861-j to 1863-j and on the percentage of women 
	marrying at each age before the placebo interruption. My benchmark cohort 
	for the years before the placebo interruption is peers' daughters born in 
	1815-j to 1830-j, excluding those who married after 1861-j or died before 
	age 30. See main text for details. */

forvalues j = 10(1)50{
local i = `j'
local y = 1861-`j'
preserve
use "${dirdata}\final-data.dta", clear
gen age`y' = floor((td(31mar`y')-bdate)/365)
keep if wom==1 & nthismarriage<2 & byear<=1830-`j' & byear>=1815-`j' & dage>30 // analogous benchmark sample to calculate synthetic probability
drop if myear>=`y'
replace mage = 999 if nthismarr==0
replace nthismarr = 1 if nthismarr==0
collapse (sum) freq = nthismarr, by(mage)
drop if mage==. 
replace freq = 0 if freq==.
egen tot = sum(freq)
sort mage	
gen prob = 100*freq/tot
drop if mage == 999
rename mage age`y'
sort age`y'
gen synthetic_plac = prob+prob[_n+1]+prob[_n+2]
keep age`y' synthetic_plac
local y2 = 1863-`j'
label var age`y' "Age at the start of the `y'-`y2' Placebo Interruption of the Season"
label var synthetic_plac "Synthetic probability to marry during placebo interruption"
save "${dirdta}\synthetic_placebo_`j'.dta", replace
restore
}
	
	
* Married in 1861-63

gen mourn = (myear>=1861 & myear<=1863)



* ==============================================================================
* 1.6 COHORT VARIABLES
* ------------------------------------------------------------------------------

* Female cohort size (>18 & <=24 years of age)

gen all = 1
gen wrisk = . 	// Women at risk of marriage
forvalues i=1527/1959{
qui summ all if nthismarr<2 & `i'-byear>=19 & `i'-byear<=24 & dyear>=`i' & wom==1 	// # girls aged 18-23 when the LS starts
qui replace wrisk = r(N) if myear==`i'
}

* Housekeeping
drop all 
label var wrisk "Size of the marriageble cohort (women)"




* ==============================================================================
* 2. FAMILY SEATS FROM BURKE'S HERALDIC DICTIONARY (1826)
* ------------------------------------------------------------------------------
/* This Section of the do file adds information on family seats to the prepared 
   Hollingsworth genealogical data. The code is organized into the following 
   sub-sections:
   2.1. Prepare title (string variable) for merger.
   2.2. Add the corresponding family seats 
   2.3. Geographical variables
		distance between spouses' seats, distance to London
* ============================================================================ */


* ==============================================================================
* 2.1 PREPARE TITLE VARIABLE FOR MERGE
* ------------------------------------------------------------------------------

* Rename title variables
rename parentaltitle ptitle
rename spousetitle stitle
rename fatherttitle ftitle
rename fatheraddress faddress
rename motherttitle mtitle
rename motheraddress maddress

foreach x in title ptitle stitle ftitle mtitle{
* A. SPLIT `X' when TWO `X'S APPEAR
gen str60 `x'1 = ""
gen str60 `x'2 = ""

* A.1	SEPARATED BY A SLASH
gen slash`x' = regexm(`x',"/+")										// Whether `x’ has an "/"
replace `x'1 = substr(`x',strpos(`x',"/") + 1,.) if slash`x'==1		// Take the second part
replace `x'  = substr(`x',1,strpos(`x',"/") - 1) if slash`x'==1		// Take the first part
drop slash`x'

* A.2	SEPARATED BY AN OR
gen or`x' = regexm(`x'," or ")										// Whether `x’ has an "or"
replace `x'1 = substr(`x',strpos(`x'," or ") + 4,.) if or`x'==1		// Take the second part
replace `x'  = substr(`x',1,strpos(`x'," or ") - 1) if or`x'==1		// Take the first part
drop or`x'

* A.3 	SECOND SLASH
gen slash2`x' = regexm(`x'1,"/")
replace `x'2 = substr(`x'1,strpos(`x'1,"/")+1,.) if slash2`x'==1
replace `x'1 = substr(`x'1,1,strpos(`x'1,"/")-1) if slash2`x'==1
drop slash2`x'

* B. DROPPING ???
gen interr`x'  = regexm(`x',"\?")									// Whether `x’ has an "?"
gen interr1`x' = regexm(`x'1,"\?")
replace `x'  = substr(`x',1,strpos(`x',"?")-1)   if interr`x'==1	// Drop "?"
replace `x'1 = substr(`x'1,1,strpos(`x'1,"?")-1) if interr1`x'==1
drop interr`x' interr1`x'

* C. DROPPING (I) or (S)
* C.1	AT THE END
gen par`x' = regexm(`x',"\)$")			// Whether `x’ has an ")" at the end
gen par1`x' = regexm(`x'1,"\)$")
gen pari`x' = strpos(`x',"(")			// Position in which "(" appears
gen par1i`x' = strpos(`x'1,"(")
gen parii`x' = strpos(`x',")")			// Position in which ")" appears
gen par1ii`x' = strpos(`x'1,")")
gen parlngth`x' = parii`x'-pari`x'			
// To distinguish between parenthesis types
gen parlngth1`x' = par1ii`x'-par1i`x'
replace `x' = substr(`x',1,pari`x'-1) if parlngth`x'<=3 & parlngth`x'>0 & par`x'==1			
// Dropping (I)
replace `x'1 = substr(`x'1,1,par1i`x'-1) if parlngth1`x'<=3 & parlngth1`x'>0 & par1`x'==1
drop par`x' par1`x' pari`x' par1i`x' parii`x' par1ii`x' parlngth`x' parlngth1`x'
* C.2.	AFTER PARENTHESIS
gen parpar`x' = regexm(`x',"[A-Za-z]+\)+\(+[A-Z]+\)$")
gen parpar2`x' = strpos(`x',")")
replace `x' = substr(`x',1,parpar2`x') if parpar`x'==1
drop parpar`x' parpar2`x' 

* D. SPLITING NAMES & SURNAMES IN PARENTHESIS
gen nspar`x' = regexm(`x',"\)$")
replace `x'1 = substr(`x',strpos(`x',"(")+1,.) if nspar`x'==1
replace `x'1 = substr(`x'1,1,strpos(`x'1,")")-1) if nspar`x'==1
replace `x'  = substr(`x',1,strpos(`x',"(")-1) if nspar`x'==1
drop nspar`x'

* E. DROPPING THE REMAINING (I), (S) EXPRESSIONS
gen sis`x' = regexm(`x',"\(+[A-Z]+\)")
replace `x' = regexs(1)+" "+regexs(2) if regexm(`x',"([a-zA-Z]+[ ]*[a-zA-Z]*)[ ]*[\(][A-Z]+[\)][ ]*([&]*[0-9]*[ ]*[a-zA-Z]+[ ]*[a-zA-Z]+[ ]*[a-zA-Z]*)") & sis`x'==1
drop sis`x'

* F. RE-JOINING `X’, `X’1, and `X’2 AND LAST CLEANING
* Re-joining
gen of`x' = regexm(`x'1,"of$")
replace `x' = substr(`x'1,1,.) + " " + substr(`x',1,.) if of`x'==1
replace `x'1 = "" if of`x'==1
replace `x' = substr(`x',1,.) + " / " + substr(`x'1,1,.) + " / " + substr(`x'2,1,.) if `x'2!=""
replace `x' = substr(`x',1,.) + " / " + substr(`x'1,1,.) if `x'1!=""
drop of`x' `x'1 `x'2
* Dropping blank spaces at the end
gen blank`x' = regexm(`x'," $")
gen length`x' = strlen(`x')
replace `x' = substr(`x',1,length`x'-1) if blank`x'==1
drop blank`x' length`x'
* Dropping slash before an of:
gen slaof`x' = regexm(`x',"/ of")
replace `x' = substr(`x',1,strpos(`x',"/ of ")-1) + "" + substr(`x',strpos(`x',"/ of ")+2,.) if slaof`x'==1
drop slaof`x' 
* Counties in parenthesis
gen co`x' = regexm(`x',"Co [A-Za-z]+")
replace `x' = regexs(1) + " (Co" + regexs(2) + ")" if regexm(`x',"([a-zA-Z]+)[ ]+[/]*[ ]*[Co]+([ ]+[a-zA-Z]+[ ]*[a-zA-Z]*$)") & co`x'==1
drop co`x'
* Of at the beggining
gen ofbeg`x' = regexm(`x',"^of")
replace `x' = substr(`x',4,.) if ofbeg`x'==1
drop ofbeg`x'
}

* G. MANUAL STANDARDIZATION OF TITLE NAMES
*title
replace title="Kings & Dukes of Cornwall" if title=="(Kings & Dukes) Cornwall" | title=="George I" | title=="George II" | title=="George III / Cornwall" | title=="George IV" | title=="George V" | title=="George VI" | title=="Edward VII" | title=="Edward VIII / Windsor" | title=="Victoria" | title=="Charles I" | title=="Charles II" | title=="William III" | title=="William IV" | title=="Mary II" | title=="James II" | title=="James VI & I / (Kings & Dukes) Cornwall" | title=="Anne"
replace title="Carew (Co Wexford) & Carew of Castle Boro" if title=="Carew (Co Wexford)"
replace title="Clanbrassill" if title=="Clanbrassill 2nd Creation"
replace title="Kingston (Hull)" if title=="Kingston-upon-Hull"
replace title="Leinster / Cholmondeley of Kells / Cholmondeley of Ulichemalbank" if title=="Leinster / Cholmondeley of Kells / Cholmondeley of Ulichemalbank? / Cholmondeley of Kells"
replace title="Mount Temple" if title=="Mount Temple of Mount Temple"
replace title="Mountmorres of Castlemorrres" if title=="Mountmorres of Castlemorrres"
replace title="Duncan of Camperdown" if title=="(Duncan of) Camperdown"
replace title="Loftus of Ely" if title=="(Loftus of) Ely" | title=="(Loftus) of Ely"
replace title="Clifford" if title=="[de] Clifford"
replace title="Romney" if title=="Romney of Romney"
*ptitle
replace ptitle=	"Kings & Dukes of Cornwall" if ptitle=="(Kings & Dukes) Cornwall" | ptitle=="George I" | ptitle=="George II" | ptitle=="George III / Cornwall" | ptitle=="George IV" | ptitle=="George V" | ptitle=="George VI" | ptitle=="Edward VII" | ptitle=="Edward VIII / Windsor" | ptitle=="Edward VIII / Windsor"	| ptitle=="Charles  I" | ptitle=="Charles II" | ptitle=="William III" | ptitle=="William IV" | ptitle=="Mary II" | ptitle==	"James II" | ptitle==	"James VI & I / (Kings & Dukes) Cornwall" | ptitle=="Anne"
replace ptitle=	"Carew (Co Wexford) & Carew of Castle Boro" if ptitle=="Carew (Co Wexford)"
replace ptitle=	"Clanbrassill" if ptitle=="Clanbrassill 2nd Creation"
replace ptitle=	"Kingston (Hull)" if ptitle=="Kingston-upon-Hull"
replace ptitle=	"Leinster / Cholmondeley of Kells / Cholmondeley of Ulichemalbank" if ptitle=="	Leinster / Cholmondeley of Kells / Cholmondeley of Uli / Cholmondeley of Kells"
replace ptitle=	"Mountmorres of Castlemorrres" if ptitle=="Mountmorres of Castlemorrres    "
replace ptitle=	"Rivers / Darcy /Savage" if ptitle=="Rivers(Darcy / Savage)"
replace ptitle=	"Wenlock / Thompson/ Lawley" if ptitle=="Wenlock(Thompson / Lawley)"
replace ptitle=	"Carrick (Orkney Islands)" if ptitle=="Carrick(in Orkney) Scotland"
*stitle																																																									
replace stitle=	"Clifford" if stitle=="Clifford of Churdleigh"	| stitle=="Clifford of Lanesborough / Dungarvon"
replace stitle=	"Choiseul-Beaupre" if stitle=="de Choiseul Beaupre"	| stitle=="de Choiseul-Beaupre"
replace stitle=	"Dorchester" if stitle=="Dorchester / KUH"
replace stitle=	"Eglinton / Winton" if stitle=="Eglinton & Winton"
replace stitle=	"Falconer" if stitle=="Falconer of H"
replace stitle=	"Forbes of Pitsligo" if stitle=="Forbes of PitsligoS"
replace stitle=	"Mecklenburg-Strelitz" if stitle=="Grand D of Mecklenburg-Strelitz"
replace stitle=	"Gwydyr" if stitle=="Gwydyr / Gwydir"
replace stitle=	"Herbert of Chirbury / Hebert of Castle Island"	if stitle=="Herbert of Chirbury / [H'bert of]Castle Island"
replace stitle=	"Holdernesse / Conyers / Darcy de Knayth" if stitle=="Holdernesse / Conyers / Darcy de Knayth / Conyers"
replace stitle=	"Kingston (Hull)" if stitle=="Kingston-upon-Hull"
replace stitle=	"Lincolnshire / Carrington" if stitle=="Lincolnshire / C[arrington]"
replace stitle=	"Mount Edgecumbe" if stitle=="Mt Edgcumbe"	| stitle=="Mt Edgecumbe"
replace stitle=	"Northam (Northampton)" if stitle=="Northam[Northampton]"
replace stitle=	"Prussia" if stitle=="Germany of Prussia"	| stitle=="Royal of Prussia"
replace stitle=	"Empire" if stitle=="de Salis in Holy Roman Empire"		| stitle=="the Empire"
replace stitle=	"Carlyle of Torthorwald" if stitle=="[Carlyle of] Torthorwald"
replace stitle=	"Hastings" if stitle=="[Hastings]"
replace stitle=	"Atholl" if stitle=="Atholl(S"
*ftitle																																																									
replace ftitle=	"Downshire" if ftitle=="[Downshire]"
replace ftitle=	"Mackenzie" if ftitle==">ackenzie"
replace ftitle=	"Huyssen de Kattendyke"	if ftitle=="3B Huyssen de Kattendyke"
replace ftitle=	"Abernathy of Saltoun" if ftitle=="Abernethy of Saltoun"
replace ftitle=	"Argyll / Greenwich" if ftitle=="Argyll & Greenwich" | ftitle=="Argyll / Geeenwick"
replace ftitle=	"Argyll" if ftitle=="Argyll / S&UK"
replace ftitle=	"Arundell of Wardour" if ftitle=="Arundell of W" | ftitle=="Arundell of Wardom"
replace ftitle=	"Vernon of Kinderton" if ftitle=="B of Kindeton"
replace ftitle=	"Barnewall of Kingsland" if ftitle=="Barnewall of K"
replace ftitle=	"Rottenbury" if ftitle=="Baron de Rottenbury"
replace ftitle=	"Liege (Holy Roman Empire)"	if ftitle=="Baron of Holy Roman Empire of Liege"
replace ftitle=	"Leek & Beverwaet" if ftitle=="Baron of Leek and Beverwaet"
replace ftitle=	"Reed" if ftitle=="Baron of Reed"
replace ftitle=	"von Wassenaah" if ftitle=="Baron von"
replace ftitle=	"von Schunck" if ftitle=="Baron von Schunck"
replace ftitle=	"von Tuyll" if ftitle=="Baron von Tuyll"
replace ftitle=	"Bedford" if ftitle=="Bedfprd"
replace ftitle=	"Belhaven & Stenton" if ftitle=="Bellhaven"
replace ftitle=	"Brooke of Warwick Castle / Brooke"	if ftitle=="Brooke / 1E Warwick" | ftitle=="Brooke of Warick Castle" | ftitle=="Brooke of Warwick Castle"
replace ftitle=	"Buccleuch / Queensbury" if ftitle=="Buccleugh"
replace ftitle=	"Carrington" if ftitle=="Carrington Of Upton" | ftitle=="Carrington also GB"
replace ftitle=	"Chandos of Sudeley" if ftitle=="Chandos of Suddey"
replace ftitle=	"Chotek von Chothowa und Wogrin" if ftitle=="Chotek von Chothowa und Wogrin  "
replace ftitle= "Clifford of Chudleigh" if ftitle=="Clifford of C" | ftitle=="Clifford of Churdleigh"
replace ftitle=	"Cobham / Westcote / Lyttleton" if ftitle=="Cobham / Westcote / Lyttleton(GB) / Westcote"
replace ftitle=	"Cork & Orrery" if ftitle=="Cork and Orrey"	| ftitle=="Cork&Orrery"	| ftitle=="Corke"
replace ftitle=	"Courtenay" if ftitle=="Cour"
replace ftitle=	"Cranbrook" if ftitle=="Cranbrooke"
replace ftitle=	"Crawford / Lindsay" if ftitle=="Crawford & Lindsay"
replace ftitle=	"d'Albi (Holy Roman Empire)" if ftitle=="d'Albi of H Rom Emp"
replace ftitle=	"Saumarez" if ftitle=="de Samurez"
replace ftitle=	"Decazeset de Gluchsbjerg" if ftitle=="Decazes"
replace ftitle=	"Denmark & Norway" if ftitle=="Denmark&Norway"
replace ftitle=	"Ditchley (Co Oxford)" if ftitle=="Ditchley, Co Oxford"
replace ftitle=	"SHSG (Germany)" if ftitle=="Duke of SHSG / Germany"
replace ftitle=	"Dunraven" if ftitle=="Dunraven & Mt Earl"
replace ftitle=	"Uxhull" if ftitle=="d'Uxhull"
replace ftitle=	"Effingham" if ftitle=="Effingham / Howard of Effingham"
replace ftitle=	"Forth" if ftitle=="Forth / Brentwood"
replace ftitle=	"Grant / Freuchie" if ftitle=="Grant of Freuchie"
replace ftitle=	"Howard of Glossop" if ftitle=="Howard of G[lossop]"
replace ftitle=	"Winchester" if ftitle=="if Winchester"
replace ftitle=	"Kingston (Hull)" if ftitle=="Kingston Upon Hull"	| ftitle=="	Kingston-upon-Hull"
replace ftitle=	"Laverstoke (Hants)" if ftitle=="Laverstoke, Hants"
replace ftitle=	"le Despenser" if ftitle=="de Despenser"
replace ftitle=	"Leven / Melville" if ftitle=="Leven & Melville"
replace ftitle=	"Lexinton of Aram" if ftitle=="Lexington of Aram"
replace ftitle=	"Keith" if ftitle=="Lord Keith"
replace ftitle=	"Mountjoy" if ftitle=="M[oun]tjoy"
replace ftitle=	"Maitland of Thirlestane" if ftitle=="Maitland of THirlestane"
replace ftitle=	"Edgcumbe" if ftitle=="Mount Edgcumbe" | ftitle=="Mount Edgecumbe"																																																
replace ftitle=	"Mountnorris" if ftitle=="Mt Norris"
replace ftitle=	"Offaley" if ftitle=="Mt Offaley"
replace ftitle=	"Alexander" if ftitle=="Mt. Alexander"
replace ftitle=	"Garret" if ftitle=="Mtgarret"
replace ftitle=	"Newcastle (Lyne)" if ftitle=="Newcastle under Lyne" | ftitle=="Newcastle-under-Lyme"
replace ftitle=	"Newcastle (Tyne)" if ftitle=="Newcastle upon Tyne"	| ftitle=="	Newcastle-upon-Tyne"
replace ftitle=	"Oxford / Mortimer" if ftitle=="Oxford & Mortimer"
replace ftitle=	"Peterborough & Monmouth" if ftitle=="Peterborough &"
replace ftitle=	"Piombino" if ftitle=="pf Piombino"
replace ftitle=	"Stamford / Warrington"	if ftitle=="Stamford and Warrington"
replace ftitle=	"Strathmore / Kinghorne" if ftitle=="Strathmore & Kinghorn"	| ftitle=="Strathmore & Kinghorne"	| ftitle=="Strathmore / Kingham"
*mtitle
replace mtitle=	"Grey de Ruthin" if mtitle=="Grey de Ruthyn"	| mtitle=="Grey of Ruthin"
replace mtitle=	"Willoughby of Eresby" if mtitle=="W [Willoughby] of Eresby"																																																																																																										
*repeated names
replace title=	"Breadalbane" if title=="Breadalbane / Breadalbane"
replace title=	"Buchan" if title=="Buchan / Buchan"
replace title=	"Cloncurry" if title=="Cloncurry / Cloncurry"
replace title=	"Hamilton" if title=="Hamilton / Hamilton"
replace ptitle=	"Granville" if ptitle=="Granville / Granville"
replace ftitle=	"Bute" if ftitle=="Bute / Bute"
replace ftitle=	"Argyll" if ftitle=="Arygll / Arygll"
replace ftitle=	"Ruthven" if ftitle=="Ruthven / Ruthven"

* H. GEN TITLE VARIABLES
* Generate the variable geo indicating title for each individual
* Entries
gen str70 geo = ""
replace geo = title  if nthismarriage==1 & wom==0			  // For male entries, we take its own title and, if not available,  parental title.
replace geo = ptitle if nthismarriage==1 & wom==0 & geo==""
replace geo = ptitle if nthismarriage==1 & wom==1			  // For female entries, we take first parental and then own.
replace geo = title  if nthismarriage==1 & wom==1 & geo==""
* Spouses
gen str70 geospo = ""
replace geospo = stitle if nthismarriage==1			
foreach var of varlist stitle ftitle mtitle{				// For spouses, we take its own title and, if not available, his father's title
replace geospo = `var' if nthismarriage==1 & geospo==""		// then father's address, then mother's title, and finally mother's address. 
}
replace geospo = "Lincolnshire / Carrington" if geospo=="Lincolnshire / C[arrington]"
replace geospo = "Cobham / Westcote / Lyttleton" if geospo=="Cobham / Westcote / Lyttleton(GB) / Westcote"
replace geospo = "Effingham" if geospo=="Effingham / Howard of Effingham"
* Housekeeping
foreach x in "" spo{
replace geo`x'="Abercromby" if geo`x'=="Abercrombie"
replace geo`x'="Abernathy of Saltoun" if geo`x'=="Abernathy"
replace geo`x'="Antrim" if geo`x'=="Amtrim"
replace geo`x'="Argyll" if geo`x'=="Argyle"
replace geo`x'="Arundell" if geo`x'=="Arundel"
replace geo`x'="Arundell / Surrey" if geo`x'=="Arundel / Surrey"
replace geo`x'="Arundell of Wardour" if geo`x'=="Arundell of W"
replace geo`x'="Ashbrooke" if geo`x'=="Ashbrook"
replace geo`x'="Aylesford" if geo`x'=="Avlesford"
replace geo`x'="Balfour of Burleigh" if geo`x'=="Balfour of Bunleigh"
replace geo`x'="Balfour of Glenawley" if geo`x'=="Balfour of Glenawly"
replace geo`x'="Balmerinoch" if geo`x'=="Balmmerinoch"
replace geo`x'="Banbury of Southam" if geo`x'=="Banbury"
replace geo`x'="Aberdeen" if geo`x'=="Abedeen"
}
replace geo = "Feversham Duncombe Park" if title=="Feversham of Duncombe Park" | title=="Feversham of Ryedale"
replace geospo = "Feversham Duncombe Park" if stitle=="Feversham"

drop faddress maddress fatherfnames fathersurname motherfnames mothersurname



* ==============================================================================
* 2.2 FAMILY SEATS FROM BURKE (1826)
* ------------------------------------------------------------------------------

	/* Note: The file familyseats.txt contains the family seats in Burke (1826)
	for titles in the Hollingsworth dataset (variable geo) and for titles of 
	spouses in the Hollingsworth dataset (variable geospo). */


* save family seats data in .dta format
	
preserve
* family seats for titles in the Hollingsworth dataset
import delimited "${dirdata}\familyseats.txt", clear 
keep if geo!=""
keep geo countryseat county countryseat2 county2 countryseat3 county3 countryseat4 county4 wgslat wgslon wgslat2 wgslon2 wgslat3 wgslon3 wgslat4 wgslon4
label var geo             "Title to merge with Hollingsworth dataset"
local j = 1
foreach x in "" 2 3 4{
local N = "n"
if `j'==4{
local N = 4
}
label var countryseat`x' "Name of family seat (`j'/`N')"
label var county`x' "County where family seat is located (`j'/`N')"
label var wgslat`x' "Latitude of family seat (`j'/`N'), WGS84"
label var wgslon`x' "Longitude of family seat (`j'/`N'), WGS84"
local j = `j'+1
}
save "${dirdta}\familyseats.dta", replace	
* family seats for titles of spouses in the Hollingsworth dataset
import delimited "${dirdata}\familyseats.txt", clear 
keep if geospo!=""
keep geospo countryseatspo countyspo countryseat2spo county2spo countryseat3spo county3spo countryseat4spo county4spo countryseat5spo county5spo wgslatspo wgslonspo wgslat2spo wgslon2spo wgslat3spo wgslon3spo wgslat4spo wgslon4spo wgslat5spo wgslon5spo
label var geospo "Title to merge with Hollingswort dataset"
local j = 1
foreach x in "" 2 3 4 5{
local N = "n"
if `j'==5{
local N = 5
}
label var countryseat`x'spo "Name of seat (`j'/`N') (for spouses' families)"
label var county`x'spo "County where family seat is located (`j'/`N') (for spouses' families)"
label var wgslat`x'spo "Latitude of family seat (`j'/`N'), WGS84 (for spouses' families)"
label var wgslon`x'spo "Longitude of family seat (`j'/`N'), WGS84 (for spouses' families)"
local j = `j'+1
}
save "${dirdta}\familyseats_spo.dta", replace
restore


* merge family seats 

* family seats for titles in the Hollingsworth dataset
merge m:1 geo using "${dirdta}\familyseats.dta", nogen
* family seats for titles of spouses in the Hollingsworth dataset
merge m:1 geospo using "${dirdta}\familyseats_spo.dta", nogen
* erase temp files
erase "${dirdta}\familyseats.dta"
erase "${dirdta}\familyseats_spo.dta"
* housekeeping
drop geo geospo 
keep if refno!=.


			
* ==============================================================================
* 2.3 GEOGRAPHIC VARIABLES
* ------------------------------------------------------------------------------


* Distance between spouses' seats. When spouses have more than one seat, I use 
* the minimum distance between seats.

foreach x in "" 2 3 4{
foreach y in "" 2 3 4 5{
geodist wgslat`x' wgslon`x' wgslat`y'spo wgslon`y'spo, miles gen(disttmp`x'_`y')
}
}
gen dist = min(disttmp_, disttmp2_, disttmp3_, disttmp4_, disttmp_2, disttmp2_2, disttmp3_2, disttmp4_2, disttmp_3, disttmp2_3, disttmp3_3, disttmp4_3, disttmp_4, disttmp2_4, disttmp3_4, disttmp4_4, disttmp_5, disttmp2_5, disttmp3_5, disttmp4_5)
drop disttmp_ disttmp2_ disttmp3_ disttmp4_ disttmp_2 disttmp2_2 disttmp3_2 disttmp4_2 disttmp_3 disttmp2_3 disttmp3_3 disttmp4_3 disttmp_4 disttmp2_4 disttmp3_4 disttmp4_4 disttmp_5 disttmp2_5 disttmp3_5 disttmp4_5
* Manual corrections
* 	The following corrections correspond to a group of marriages where both spouses 
*	are peers' or peers' offspring; i.e., each spouse has its own entry in the
*	Hollingsworth dataset. However, for these individuals, the names or surnames
*	in the entries are not consistently reported. For the sake of illustration, take
*	the marriage between Edward Keppel Coke and Diana Mary Blanche Georgiana Ellis.
*	In Diana's entry (refno=59654) both names are correctly reported so I was able
*	to find their country seats and the corresponding distance. However, in Edward's 
*	entry (refno=154454) his name is correctly reported, but his wife only appears 
*	as "Diana," making it impossible to find her country seat and to calculate
*	the distance. The following lines correct for these mistakes, assigning both 
*	spouses' entries the same distance.
replace dist=87.49741 if refno==154454
replace dist=94.21429 if refno==27511
replace dist=91.12578 if refno==205653
replace dist=151.6865 if refno==117602
replace dist=347.8196 if refno==180652
replace dist=242.4853 if refno==257205
replace dist=279.2881 if refno==4103
replace dist=45.72152 if refno==124850
replace dist=7.508985 if refno==78251
replace dist=79.80771 if refno==302750
replace dist=213.4518 if refno==220652
replace dist=11.39863 if refno==69152



* Distance to London

	/* Note: this is calculated only for the baseline sample. To calculate it, 
	I use seats at the title level */

gen distsample = (wom==1 & nthismarriage<2) // distance to london only used for peers' daughters, excluding second-marriages and 20C marriages
gsort distsample surname title -nthismarr
foreach x in wgslat wgslon wgslat2 wgslon2 wgslat3 wgslon3 wgslat4 wgslon4{
by distsample surname title: gen `x'0 = `x'[1]
}
foreach i in "" 2 3 4{
geodist wgslat`i'0 wgslon`i'0 51.507222 -0.1275, miles gen(distlnd`i')
}
egen distlondon = rowmin(distlnd distlnd2 distlnd3 distlnd4)
replace distlondon = . if distsample!=1
drop distlnd distlnd2 distlnd3 distlnd4 wgslat0 wgslon0 wgslat20 wgslon20 wgslat30 wgslon30 wgslat40 wgslon40 distsample




* ==============================================================================
* 3. FAMILY LANDHOLDINGS FROM BATEMAN (1883)
* ------------------------------------------------------------------------------
/* This Section of the do file adds information on family landholdings to the 
   prepared Hollingsworth genealogical data. The code is organized into the 
   following sub-sections:
   3.1. Import data for baseline sample (women aged 15-35 in 1861)
   3.2. Import data for appendix sample (men marrying in 1851-75) 
   3.3. Sorting by landholdings variables
* ============================================================================ */


* ==============================================================================
* 3.1 IMPORT DATA FOR BASELINE SAMPLE
* ------------------------------------------------------------------------------

	/* Note: Here I import the family landholdings for women in my baseline 
	sample and their (first) husbands. A woman's family landholdings refers
	to the acreage owned by her birth family (idem for men). Out of a potential 
	sample of 644 women (peers' daughters aged 15-35 in 1861 who ever married,
	excluding second-marriages, women married to foreigners, and members of the 
	royal family), I found the family landholdings for 324 women and their 
	husbands. Eighty-one percent of the lost observations correspond to women 
	marrying landless commoners. The remaining 19 percent are women whose families 
	(or whose husbands families) owned fewer than 2,000 acres, and hence, were 
	not listed in Bateman (1883).	
	
	I constructed this dataset in three steps: 
	
	(i)   First, I digitized all 596 men who appear both in Bateman and in 
	      Hollingsworth's dataset. 
	(ii)  Second, I coded 353 of their wives' birth families. 
	
	The data from steps 1 and 2 is in the dataset bateman-master.txt. The file 
	also contains 70 entries in Bateman for men who do not appear in the 
	Hollingsworth dataset directly but that (first) married in 1858-66 
	to a peers' daughter in the baseline sample. From these two steps, I found 
	both spouses' family landholdings for 227 couples in my baseline sample. 
	This is indicated by the variables fsource (for women) and sfsource 
	(for their husbands): 
		
		fsource  = "bateman_master (notes)" 
		sfsource = "bateman_master (notes)" 
	
	Where notes lists the reference number in the bateman-master datset from 
	which the data comes from (and indicates whether this corresponds to their
	landholdings in bateman-master or to the landholdings of spouses in bateman-master)

	(iii) Third, I searched the remaining baseline sample's spouses (families) 
	      in Bateman's book manually. 
	
	From step three, I found 97 additional couples. This is indicated by the 
	variables sfsource (for their husbands): 
		
		sfsource = "Bateman 1883 (notes)"
	
	Where notes lists the page and the entry (i.e., the title of the landholder) 
	where the info comes from in Bateman's book. */
	

* import data

preserve
import delimited "${dirdata}\landholings-baseline-sample.txt", clear
label var refno "Reference number in Hollingsworth"
label var fatotal "Family landholdings"
label var sfatotal "Family landholdings, spouse"
label var id "Reference number in bateman-master for fatotal" 
label var sid "Reference number in bateman-master for sfaTotal" 
label var fsource "Source for fATotal (landholdings or landholdings of spouses in bateman-master)" 
label var sfsource "Source sfATotal (Bateman 1883;lholdings or lholdings spouses in bateman-master)"
save "${dirdta}\landholings-baseline-sample.dta", replace
restore

* merge family seats 

merge m:1 refno using "${dirdta}\landholings-baseline-sample.dta", nogen
erase "${dirdta}\landholings-baseline-sample.dta"

* sorting by landholdings' variables
xtile fATot  = fatotal  if fatotal!=. & nthismarr<2 & age1861>=15 & age1861<=35, nq(100) // rank percentiles for family landholdings
xtile sfATot = sfatotal if fatotal!=. & nthismarr<2 & age1861>=15 & age1861<=35, nq(100) // rank percentiles for spouses' family landholdings
gen fmissmatch  = abs(fATot-sfATot) // Difference in spouses' family landholdings (absolute value, rank percentiles)
gen fmissmatch2 = sfATot-fATot // Difference in spouses' family landholdings (rank percentiles)
gen fdown = 1 if fATot>sfATot & fATot!=. & sfATot!=. // Married down in landholdings
replace fdown = 0 if fATot<=sfATot & fATot!=. & sfATot!=.
label var fmissmatch "Difference in spouses' family landholdings (absolute value, percentile ranks)"
label var fmissmatch2 "Difference in spouses' family landholdings (hus-wife, percentile ranks)"
label var fdown "Married down in family landholdings"


* ==============================================================================
* 3.2 IMPORT DATA FOR APPENDIX SAMPLE (MEN)
* ------------------------------------------------------------------------------

* import data

preserve
import delimited "${dirdata}\bateman-master.txt", clear
keep if refno!=. // keep great landowners listed both in Bateman 1883 and in the Hollingsworth dataset
label var refno "Reference number in Hollingsworth dataset"
label var nthismarriage "Number this Marriage in Hollingsworth dataset"
label var firstnames "First Name"
label var surname "Surname"
label var title "Title"
label var byear "Birth year"
label var dyear "Death year"
label var id "Identifier for family landholdings' source in landholdings-baseline-sample.txt"
label var rnk_bate "Rank listed in Bateman (1883)"
label var accuracy "Accuracy Bateman entry (1 = least; 3 = most; see Bateman prologue)"
label var oldfamily "Head of family/family's junior branch who held land in England since Henry VII"
label var sfatherfirstname "Spouse's father first name"
label var ssurname "Spouse's surname"
label var stitle "Spouses' title"
label var sid "Identifier (spo) family landholdings' source in landholdings-baseline-sample.txt"
label var saccuracy "Accuracy Bateman entry for spouse family (1=least; 3=most; see Bateman prologue)"
label var soldfamily "Spouse in family/family's junior branch held land in England since Henry VII"
local s1 = 1
local Slab = ""
foreach S in "" s{
	if `s1'==2{
	local Slab = "(spouse's family)"
	}
label var `S'seatname "Address/name of seat in Bateman `Slab'"
label var `S'town "Town of address/seat in Bateman `Slab'"
label var `S'county "County of address/seat in Bateman `Slab'"
label var `S'school "School attended by landowner as of 1870s `Slab'"
label var `S'college "College attended by landowner as of 1870s `Slab'"
label var `S'militaryacademy "Military academy attended by landowner as of 1870s `Slab'"
label var `S'club "Club (1/n) to which landowner belonged `Slab'"
forvalues j=2/6{
label var `S'club`j' "Club (`j'/n) to which landowner belonged `Slab'"
}
label var `S'club7 "Club (7/7) to which landowner belonged `Slab'"
label var `S'succyear "Year of succession in Bateman `Slab'"
label var `S'woods "Woods included in Bateman `Slab'"
label var `S'acrestotal "Acreage (total) `Slab'"
label var `S'valuetotal "Gross annual value, pounds (total) `Slab'"

forvalues i=1/13{
label var `S'estate`i' "County `i'/n where landowners has estates `Slab'"
label var `S'acres`i' "Acres in county `i'/n `Slab'"
label var `S'value`i' "Gross annual value (pounds) in county `i'/n `Slab'"
}
label var `S'estate14 "County 14/14 where landowners has estates `Slab'"
label var `S'acres14 "Acres in county 14/14 `Slab'"
label var `S'value14 "Gross annual value (pounds) in county 14/14 `Slab'"
label var `S'queenservices "Services to the Queen, as of 1870s (1/n) `Slab'"
local j = 1
foreach x in queenservices2 queenservices3 queensevices4 queensevices5 queensevices6 queensevices7{
label var `S'`x' "Services to the Queen, as of 1870s (`j'/n) `Slab'"
local j = `j'+1
}
label var `S'queensevices8 "Services to the Queen, as of 1870s (8/8) `Slab'"
label var `S'parliament "Services to Parliament, as of 1870s (1/n) `Slab'"
label var `S'parliament2 "Services to Parliament, as of 1870s (2/n) `Slab'"
label var `S'parliament3 "Services to Parliament, as of 1870s (3/n) `Slab'"
label var `S'parliament4 "Services to Parliament, as of 1870s (4/4) `Slab'"
label var `S'wealthsources "Other wealth sources listed in Bateman (1/n) `Slab'"
label var `S'wealthsources2 "Other wealth sources listed in Bateman (1/2) `Slab'"
local s1 = `s1'+1
}
save "${dirdta}\bateman_master.dta", replace
restore

* merger

merge 1:1 refno nthismarriage using "${dirdta}\bateman_master.dta", nogen
erase "${dirdta}\bateman_master.dta"





* ==============================================================================
* 4. ATTENDANCE TO THE SEASON
* ------------------------------------------------------------------------------
/* This Section of the do file adds the yearly number of people who: (a) were 
   invited to a royal party during the Season, (b) who attended royal parties, 
   (c) who excused themselves from not attending (source: self collected from
   National Archives, reference provided). I also add the number of girls who 
   were presented at Court and the number of peers' daughters presented at Court 
   (source: Ellenberger 1990)
* ============================================================================ */


* Import original data

preserve
import delimited "${dirdata}\seasonattend.txt", clear
label var date "Date of the event"
label var year "Year of the event"
label var partyname "Name of event"
label var partytype "Type of event"
label var invited "Number of people invited"
label var attended "Number of people who attended the event"
label var excused "Number of people who were invited and excused themselves for not attending"
label var referenceparty "Reference in National Archives"
label var court "Yearly number of girls presented at court"
label var courtp "Yearly number of peers' daughters presented at court"
label var referencecourt "Source for court presentations data"


* Collapse data by year, separating events

encode partytype, gen(ptype)
keep ptype invited excused attended year court courtp
collapse (sum) invited excused attended, by(year ptype)
reshape wide invited excused attended, i(year) j(ptype)
foreach x in invited excused attended{
egen `x'_bc = rsum(`x'2 `x'5)
egen `x' = rsum(`x'1 `x'2 `x'3 `x'4 `x'5 `x'6 `x'7)
drop `x'1 `x'2 `x'3 `x'4 `x'5 `x'6 `x'7
}

... [truncated: 72,806 more bytes of this script omitted] ...

```

### `programs/02_analysis/master-analysis.do`
```stata
/*******************************************************************************

This file contains the code to replicate the tables and figures in the paper.

	Contents:
	0. Generate or import final dataset
	Figure 1: The Season in 1841
	Figure 2: Pressure  marry young.
	Figure 3: Attendees at royal parties, by type of event.
	Figure 4: Synthetic probability to marry during the Season's interruption (1861-63).
	Table  1: Marriage market before, during, and after the Season's interruption.
	Figure 5: The interruption of the Season and distance between spouses' seats.
	Table  2: The Season's interruption and marriage outcomes, probit and OLS estimation.
	Figure 6: Placebo tests. Dependent variable: married a commoner.
	Figure 7: Peer-commoner intermarriage, Probit estimation with age dummies.
	Table  3: The Season's interruption and marriage outcomes, IV estimation.
	Table  4: Contingency tables
	Table  5: The interruption and sorting by title, non-parametric estimates.
	Figure 8: Sorting by landholdings, non-parametric estimation.
	Table  6: Women's marriages to commoners and her family's political power, IV estimation.
	Table  7: Determinants of investments in state education, IV estimation.
		
The file "3 Replication package\programs00_setup.do" installs the required ado 
packages sets. It also sets the path to all directories. If you want to run this 
do file individually, after installing the required packages unnmark and specify 
location of parent directory here:

	*global dirroot = "SPECIFY\LOCATION\OF\PARENT\DIRECTORY\HERE"

and then run the following lines for the secondary directories (specified as 
downloaded in replication package):

	global dirdata = "${dirroot}\data"
	global dirdta  = "${dirroot}\programs\01_dataprep\dta-temp-files"
	global dirresu = "${dirroot}\programs\results"

*******************************************************************************/


* Set-up:

	do "${dirroot}\programs\00_setup.do"


* ==============================================================================
* 0. GENERATE OR IMPORT FINAL DATASET:
* ------------------------------------------------------------------------------
clear all
set more off
set matsize 10000

* To generate the final dataset run the following line:

	do "${dirroot}\programs\01_dataprep\master-dataprep.do"

* Alternatively, you can import the final dataset data directly by writting
* use "${dirdata}\final-data.dta", clear

* ==============================================================================



* ==============================================================================
* FIGURE 1: 
* The Season in 1841.
* ------------------------------------------------------------------------------

* Import Sheppard (1977)'s data on 4,000 movements into and out of London of 
* families participating in the Season of 1841, as reported in The Morning Post.
import delimited "${dirdata}\sheppard.txt", clear
label var week "Week"
label var arrivals "Arrivals to London of members of Fashionable World"
label var departures "Departures from London of members of Fashionable World"
label var cumulative "Cumulative members of Fashionable World in London"


* Figure 1:
twoway	(bar arrivals week, fcolor(dknavy) fintensity(inten50) lcolor(dknavy) barw(1)) 		///
		(bar departures week, fcolor(maroon) fintensity(inten50) lcolor(maroon) barw(1)) 	///
		(line cumulative week, lcolor(black))			///
		(scatter cumulative week if week==4 | week==15 | week==20 | week==32),	///
		ytitle("Number of families") xtitle("") 			///
		legend(col(3) on order(1 "Arrivals" 2 "Departures" 3 "Cummulative")) graphregion(color(white))	///
		xlabel(1 "Jan" 5 "Feb" 9 "Mar" 13 "Apr" 17 "May" 22 "Jun" 26 "Jul" 31 "Ago" 35 "Sep" 39 "Oct" 44 "Nov" 48 "Dec") ///
		text(310 4  "Opening of Parliament", place(e) size(small))	///
		text(440 17 "Queen arrives to London", place(s) size(small))	///
		text(850 20 "Royal ball", place(n) size(small))	///
		text(420 32 "End of the Season", place(e) size(small))
graph export "${dirresu}\Figure1.pdf", as(pdf) replace



* ==============================================================================
* FIGURE 2: 
* Pressure  marry young.
* ------------------------------------------------------------------------------

* Import final dataset
use "${dirdata}\final-data.dta", clear


* Sample: all 796 peers' daughters first marrying in 1851-75
keep if wom==1 & nthismarriage==1 & myear>=1851 & myear<=1875 & mage!=.


* Variables for Figure
gen agegroup = .					// age groups in figure
forvalues i=18(3)35{
replace agegroup = `i' if mage>=`i' & mage<=`i'+2
}
replace agegroup = 30 if mage>=30
keep if agegroup!=. & agegroup<=30
gen duk = (rankspo==5) 				// marrying a dukes' heir


* Figure 2, first panel
preserve
collapse (mean) duk (sd) sd_duk=duk (count) n_duk=duk, by(agegroup)
gen hi_duk = duk + invttail(n_duk-1,0.025)*(sd_duk / sqrt(n_duk))
gen lo_duk = duk - invttail(n_duk-1,0.025)*(sd_duk / sqrt(n_duk))
label var agegroup "Age at marriage"
label var duk "% marrying duke, marquis, earl heir"
label var hi_duk "CI high, % marrying duke, marquis, earl heir"
label var lo_duk "CI low, % marrying duke, marquis, earl heir"
twoway 	(scatter duk agegroup, lcolor(dknavy) mcolor(black) msymbol(circle)) 					///
		(rcap hi_duk lo_duk agegroup, lcolor(black)),											///
		xlabel(18 "18-20" 21 "21-23" 24 "24-26" 27 "27-29" 30 "{&ge}30", labsize(medlarge) angle(45))  	///
		ylabel(0 "0" 0.1 "10" 0.2 "20" 0.3 "30", labsize(medlarge)) 	///
		legend(on order(1 "All peers' daughters") ring(0) position(1) nobox region(lstyle(none))) ///
		ytitle("% marrying duke, marquis, earl heir", size(medlarge)) ///
		xtitle("Age at marriage", size(medlarge)) ///
		name(fig2panela, replace) graphregion(color(white))
restore


* Figure 2, second panel
preserve
collapse (mean) duk (sd) sd_duk=duk (count) n_duk=duk, by(agegroup prank)
gen hi_duk = duk + invttail(n_duk-1,0.025)*(sd_duk / sqrt(n_duk))
gen lo_duk = duk - invttail(n_duk-1,0.025)*(sd_duk / sqrt(n_duk))
replace lo_duk = 0 if lo_duk<0	// restrict lower bound of c.i. to zero for visual purposes  
label var duk "% marrying duke, marquis, earl heir"
label var hi_duk "CI high, % marrying duke, marquis, earl heir"
label var lo_duk "CI low, % marrying duke, marquis, earl heir"
gen agegroup1 = agegroup-0.3	// separate estimates for the two groups for visibility
gen agegroup0 = agegroup+0.3
label var agegroup "Age at marriage"
label var agegroup0 "Age at marriage"
label var agegroup1 "Age at marriage"
twoway 	(rcap hi_duk lo_duk agegroup1 if prank==5, lcolor(blue))			///
		(rcap hi_duk lo_duk agegroup0 if prank==4, lcolor(red))				///
		(scatter duk agegroup1 if prank==5, lcolor(blue) mcolor(blue) msymbol(diamond))			/// 
		(scatter duk agegroup0 if prank==4, lcolor(red) msymbol(diamond) mlc(red) mfc(white)),	/// 
		ylabel(0 "0" 0.1 "10" 0.2 "20" 0.3 "30" 0.4 "40", labsize(medlarge))				///
		xlabel(18 "18-20" 21 "21-23" 24 "24-26" 27 "27-29" 30 "{&ge}30", labsize(medlarge) angle(45))  		///
		legend(on order(3 "Dukes', Marquis', Earls' daughters" 4 "Barons', Viscounts' daughters") rows(2) ring(0) position(1) nobox region(lstyle(none))) ///
		ytitle(" ", size(medlarge)) ///
		xtitle("Age at marriage", size(medlarge)) ///
		name(fig2panelb, replace) graphregion(color(white))
restore


* Figure 2, combined panels
graph combine fig2panela fig2panelb, graphregion(color(white))
graph export "${dirresu}\Figure2.pdf", replace
graph drop fig2panela fig2panelb



* ==============================================================================
* FIGURE 3: 
* Attendees at royal parties, by type of event.
* ------------------------------------------------------------------------------

* Import data with the invitations to royal parties, the number of attendees 
* at each party, and the numbers presented at court in the Seasons of 1851-75.
import delimited "${dirdata}\seasonattend.txt", clear


* Calculate attendance to royal parties, by type of event  
gen str15 partytype2 = partytype
replace partytype2 = "Concert and Evening party" if partytype=="Concert" | partytype=="Evening Party"
replace partytype2 = "Breakfast and Afternoon party" if partytype=="Breakfast" | partytype=="Afternoon"
replace partytype2 = "Children's Ball" if partytype2=="Child's Ball"
local j = 1
foreach x in "Ball" "Concert and Evening party" "Breakfast and Afternoon party" "Children's Ball" "Court"{
bysort year: egen tattend`j' = sum(attended) if partytype2=="`x'"
gsort year -tattend`j'
by year: replace tattend`j' = tattend`j'[1] if tattend`j'==.
replace tattend`j' = 0 if tattend`j'==.
local j = `j'+1
}
gen tAttend2 = tattend1+tattend2
gen tAttend3 = tAttend2+tattend3
gen tAttend4 = tAttend3+tattend4
gen tAttend5 = tAttend4+tattend5
collapse tattend1 tAttend2 tAttend3  tAttend4  tAttend5 court, by(year)


* Figure 3
twoway 																			///
	(bar tattend1 year, barw(0.7) bcolor(dknavy) yaxis(1)) 						///
	(rbar tattend1 tAttend2 year, bcolor(orange) barw(0.7) yaxis(1))			///
	(rbar tAttend2 tAttend3 year, bcolor(forest_green) barw(0.7) yaxis(1))		///
	(rbar tAttend3 tAttend4 year, bcolor(maroon) barw(0.7) yaxis(1))			///
	(rbar tAttend4 tAttend5 year, bcolor(teal) barw(0.7) yaxis(1))				///
	(line court year, yaxis(2) lcolor(black)),									///
	ytitle("attendees", axis(1)) ytitle("debutantes", axis(2)) 					///
	legend(on order(1 "Ball" 2 "Concert and Evening party" 3 "Children's Ball"	/// 
	4 "Breakfast and Afternoon party" 5 "Court reception" 6 "Debutantes presented at court (Ellenberger 1990)") size(small) nobox region(lstyle(none)))	///
	xtitle("") xlabel(1851(1)1875, angle(90)) graphregion(color(white))
graph export "${dirresu}\Figure3.pdf", replace



* ==============================================================================
* FIGURE 4: 
* Synthetic probability to marry during the Season's interruption (1861-63).
* ------------------------------------------------------------------------------

* Import final dataset
use "${dirdata}\final-data.dta", clear


* Figure 4
keep if age1861>=15 & age1861<=35
collapse syntheticT, by(age1861)
twoway 	(connect syntheticT age1861, sort lcolor(dknavy) mcolor(dknavy) msymbol(diamond)),	///
		ytitle("synthetic probability to marry in 1861-63 (%)") xtitle("age in 1861") 	///
		legend(off) graphregion(color(white))
graph export "${dirresu}\Figure4.pdf", replace



* ==============================================================================
* TABLE 1: 
* Marriage market before, during, and after the Season's interruption.
* ------------------------------------------------------------------------------

* Import final dataset
clear all
use "${dirdata}\final-data.dta", clear


* Sample and labels
keep if wom==1 & nthismarriage==1 & myear>=1858 & myear<=1866
xtile fATot_tab1 = fatotal, nq(100) // percentiles for Table 1's sample
gen normal = 1-mourn // to have Interruption - Normal
global balancelist mage dage biorder pr4 hengpee fATot_tab1


* Results
mat define tab1 = (.,.,.,.,.,.,.,.,.,.\.,.,.,.,.,.,.,.,.,.\.,.,.,.,.,.,.,.,.,.\.,.,.,.,.,.,.,.,.,.\.,.,.,.,.,.,.,.,.,.\.,.,.,.,.,.,.,.,.,.\.,.,.,.,.,.,.,.,.,.)
* Panel A, mean
qui estpost sum $balancelist if normal==0
qui matrix mu=e(mean)
forvalues j=1/7{
    mat tab1[`j',1] = mu[1,`j']
}
mat drop mu
qui estpost sum $balancelist if normal==1 & myear<=1863
qui matrix mu=e(mean)
forvalues j=1/7{
    mat tab1[`j',3] = mu[1,`j']
}
mat drop mu
qui estpost sum $balancelist if normal==1 & myear>1863
qui matrix mu=e(mean)
forvalues j=1/7{
    mat tab1[`j',7] = mu[1,`j']
}
mat drop mu
* Panel A, ttest
eststo tstbef: qui estpost ttest $balancelist if myear<=1863, by(normal)
qui matrix di1=e(b)
qui matrix di2=e(se)
forvalues j=1/7{
    mat tab1[`j',5] = di1[1,`j']
    mat tab1[`j',6] = di2[1,`j']
}
mat drop di1 di2
eststo tstaft: qui estpost ttest $balancelist if myear>=1861, by(normal)
qui matrix di1=e(b)
qui matrix di2=e(se)
forvalues j=1/7{
    mat tab1[`j',9] = di1[1,`j']
    mat tab1[`j',10] = di2[1,`j']
}
mat drop di1 di2
* Panel A, se of means
local j = 1
foreach x in mage dage biorder pr4 hengpee fATot_tab1{
qui ttest `x' if myear<=1863, by(normal)
local se1 = `r(sd_1)'/sqrt(`r(N_1)')
local se2 = `r(sd_2)'/sqrt(`r(N_2)')
mat tab1[`j',2] = `se1'
mat tab1[`j',4] = `se2'
qui ttest `x' if myear>=1861, by(normal)
local se2 = `r(sd_2)'/sqrt(`r(N_2)')
mat tab1[`j',8] = `se2'
local j = `j'+1
}
* Panel B, mean
collapse wrisk mourn normal, by(myear)
qui estpost sum wrisk if normal==0
qui matrix mu=e(mean)
mat tab1[7,1] = mu[1,1]
mat drop mu
qui estpost sum wrisk if normal==1 & myear<=1863
qui matrix mu=e(mean)
mat tab1[7,3] = mu[1,1]
mat drop mu
qui estpost sum wrisk if normal==1 & myear>1863
qui matrix mu=e(mean)
mat tab1[7,7] = mu[1,1]
mat drop mu
* Panel B, ttest
eststo tstbef: qui estpost ttest wrisk if myear<=1863, by(normal)
qui matrix di1=e(b)
qui matrix di2=e(se)
mat tab1[7,5] = di1[1,1]
mat tab1[7,6] = di2[1,1]
mat drop di1 di2
eststo tstaft: qui estpost ttest wrisk if myear>=1861, by(normal)
qui matrix di1=e(b)
qui matrix di2=e(se)
mat tab1[7,9]  = di1[1,1]
mat tab1[7,10] = di2[1,1]
mat drop di1 di2
* Panel B, se of means
qui ttest wrisk if myear<=1863, by(normal)
local se1 = `r(sd_1)'/sqrt(`r(N_1)')
local se2 = `r(sd_2)'/sqrt(`r(N_2)')
mat tab1[7,2] = `se1'
mat tab1[7,4] = `se2'
qui ttest wrisk if myear>=1861, by(normal)
local se2 = `r(sd_2)'/sqrt(`r(N_2)')
mat tab1[7,8] = `se2'


* Table 1
mat list tab1
mat colnames tab1 = "Int:mean" "Int:se" "Bef:mean" "Bef:se" "Diff:mean" "Diff:se" "Aft:mean" "Aft:se" "Diff:mean" "Diff:se"
mat rownames tab1 = "Panel A: Age at first marriage" "Panel A: Life expectancy" "Panel A: Birth order (excl heirs)" "Panel A: Duke/Earl/Marquis daughter" "Panel A: Peerage of England" "Panel A: Family acreage (percentile)" "Panel B: Female cohort size"
esttab matrix(tab1, fmt(1 1 1 1 1 1 1)) using "${dirresu}\Table1.tex", ///
	mlabel("Table 1") replace
	

	
* ==============================================================================
* FIGURE 5: 
* The interruption of the Season and distance between spouses' seats.
* ------------------------------------------------------------------------------

* Import final dataset
use "${dirdata}\final-data.dta", clear


* Figure 5
keep if wom==1 & nthismarriage<2 & myear>=1858 & myear<=1866
collapse (mean) dist (mean) attendLC, by(myear)
twoway 	(bar attendLC myear, barw(0.3) yaxis(2) color(sand) xlabel(1858(1)1866))	///
		(connect dist myear, yaxis(1) mcolor(black) lcolor(black) msymbol(diamond)),	///
		ytitle("miles", axis(1)) ytitle("attendees", axis(2)) xtitle("year") ///
		legend(on order(1 "Royal parties" 2 "Distance between spouses' seats")) ///
		graphregion(color(white))
graph export "${dirresu}\Figure5.pdf", replace
	

	
* ==============================================================================
* TABLE 2: 
* The Season's interruption and marriage outcomes, probit and OLS estimation.
* ------------------------------------------------------------------------------

* Table 2, columns [1] to [5]

use "${dirdata}\final-data.dta", clear
keep if base_sample==1

	/* Note: Baseline sample is 644 peers' daughters aged 15-35 in 1861 who ever 
	married, excluding second-marriages, women married to foreigners, and 
	members of the royal family.  */

global controls pr4 biorder hengpee
label var distlondon "Distance"
local j = 1
foreach x in "" distlondon{
local panel "A"
if `j'==2{
local panel "B"
}
qui probit cOut syntheticT $controls `x', cluster(byear)
	qui estat classification
	local pcp1 = round(r(P_corr),1)
	qui summ cOut if e(sample)==1
	local mdepvar = round(r(mean),0.01)
	qui margins, dydx(*) predict(pr) post
	outreg2 using "${dirresu}\Table2_`panel'", keep(syntheticT distlondon) nocons nor2 ///
	label dec(4) coefastr ctitle("M common") ///
	addtext(% correct, `pcp1', Mean of Dep Var, `mdepvar', Controls, YES) ///
	tex replace
qui probit mheir syntheticT $controls `x', cluster(byear)
	qui estat classification
	local pcp1 = round(r(P_corr),1)
	qui summ mheir if e(sample)==1
	local mdepvar = round(r(mean),0.01)
	qui margins, dydx(*) predict(pr) post
	outreg2 using "${dirresu}\Table2_`panel'", keep(syntheticT distlondon) nocons nor2 ///
	label dec(4) coefastr ctitle("M heir") ///
	addtext(% correct, `pcp1', Mean of Dep Var, `mdepvar', Controls, YES) ///
	tex
qui reg fmissmatch syntheticT $controls `x', cluster(byear)
	qui summ fmissmatch if e(sample)==1
	local mdepvar = round(r(mean),1)
	outreg2 using "${dirresu}\Table2_`panel'", keep(syntheticT distlondon) nocons nor2 ///
	label dec(3) coefastr ctitle("Diff abs") ///
	addtext(% correct, . , Mean of Dep Var, `mdepvar', Controls, YES) ///
	tex
qui reg fmissmatch2 syntheticT $controls `x', cluster(byear)
	qui summ fmissmatch2 if e(sample)==1
	local mdepvar = round(r(mean),1)
	outreg2 using "${dirresu}\Table2_`panel'", keep(syntheticT distlondon) nocons nor2 ///
	label dec(3) coefastr ctitle("Diff h-w") ///
	addtext(% correct, . , Mean of Dep Var, `mdepvar', Controls, YES) ///
	tex
qui probit fdown syntheticT $controls `x', cluster(byear)
	qui estat classification
	local pcp1 = round(r(P_corr),1)
	qui summ fdown if e(sample)==1
	local mdepvar = round(r(mean),0.01)
	qui margins, dydx(*) predict(pr) post
	outreg2 using "${dirresu}\Table2_`panel'", keep(syntheticT distlondon) nocons nor2 ///
	label dec(4) coefastr ctitle("M down") ///
	addtext(% correct, `pcp1', Mean of Dep Var, `mdepvar', Controls, YES) ///
	tex
local j = `j'+1
}


* Table 2, column [6]

use "${dirdata}\final-data.dta", clear
keep if marital_rates_sample==1
label var distlondon "Distance"

	/*  Note: To examine marital rates, I consider women aged 15-35 in 1861,
	whether they married or not. To avoid counting women who died at an early 
	age as celibate, I exclude those dying before age 35 (see p.20).  */

local j = 1
foreach x in "" distlondon{
local panel "A"
if `j'==2{
local panel "B"
}
qui probit celibacy syntheticT $controls `x', cluster(byear)
	qui estat classification
	local pcp1 = round(r(P_corr),1)
	qui summ celibacy if e(sample)==1
	local mdepvar = round(r(mean),0.01)
	qui margins, dydx(*) predict(pr) post
	outreg2 using "${dirresu}\Table2_`panel'", keep(syntheticT distlondon) nocons nor2 ///
	label dec(4) coefastr ctitle("never M") ///
	addtext(% correct, `pcp1', Mean of Dep Var, `mdepvar', Controls, YES) ///
	tex
local j = `j'+1
}


* Small cluster correction (bootstrap-t procedure of Cameron, Gelbach and Miller, 2008)

	/*  Note: Results stored in log file in the following location:
	3 Replication package\results\Table2_smallcluster.log.  */

clear all
use "${dirdata}\final-data.dta", clear
gsort surname title -nthismarr 	// to get stable results
do "${dirauxp}\cgmreg.do"		// if not run in setup
capture log close				// save results in log file
cd "${dirresu}"
log using Table2_smallcluster.log, replace
keep if wom==1 & nthismarriage<2 & age1861>=15 & age1861<=35	// sample
preserve
keep if nthismarr==1 & myear!=.	// married
foreach x in "" distlondon{
qui probit cOut syntheticT $controls `x', cluster(byear)
keep if e(sample)==1	// keep sample of non-missing variables
clustse probit cOut syntheticT $controls `x', cluster(byear) method(pairs) reps(5000)
clustse probit mheir syntheticT $controls `x', cluster(byear) method(pairs) reps(5000)
cgmwildboot fmissmatch syntheticT $controls `x', cluster(byear) bootcluster(byear) reps(5000)
cgmwildboot fmissmatch2 syntheticT $controls `x', cluster(byear) bootcluster(byear) reps(5000)
clustse probit fdown syntheticT $controls `x', cluster(byear) method(pairs) reps(5000)
}
restore
keep if dage>35 & dyear>byear+1 & prank>1 // married and unmarried women
foreach x in "" distlondon{
qui probit celibacy syntheticT $controls `x', cluster(byear)
keep if e(sample)==1	// keep sample of non-missing variables
clustse probit celibacy syntheticT $controls `x', cluster(byear) method(pairs) reps(5000)
}
log close


* ==============================================================================
* FIGURE 6: 
* Placebo tests. Dependent variable: married a commoner.
* ------------------------------------------------------------------------------

* Import placebo dataset
use "${dirdata}\placebo-data.dta", clear
graph drop _all

* Estimates for baseline sample
global controls pr4 biorder hengpee
qui probit cOut syntheticT $controls distlondon if nthismarr==1 & base_sample==1, cluster(byearclst)
qui margins, dydx(*) post
estimates store baseEST

* Placebo estimates
sort refno sample01 	// drop observations in both baseline and placebo samples
by refno: gen dup=_N
by refno: drop if sample0[1]!= sample0[2] & dup>1
keep if nthismarr==1
drop syntheticT	// just for label purposes
gen syntheticT = synthetic_plac
forvalues i=1811/1851{
qui probit cOut syntheticT $controls distlondon if sample01==`i' & sample0=="placebo", cluster(byearclst)
qui margins, dydx(*) post
estimates store pE`i'
}

* Figure
graph drop _all
coefplot (baseEST, msymbol(circle)) (baseEST, mcolor(white) noci) (pE1851, pstyle(p2)) (pE1850, pstyle(p2))	///
		 (pE1849, pstyle(p2)) (pE1848, pstyle(p2)) (pE1847, pstyle(p2))	///
		 (pE1846, pstyle(p2)) (pE1845, pstyle(p2)) (pE1844, pstyle(p2))	///
		 (pE1843, pstyle(p2)) (pE1842, pstyle(p2)) (pE1841, pstyle(p2))	///
		 (pE1840, pstyle(p2)) (pE1839, pstyle(p2)) (pE1838, pstyle(p2))	///
		 (pE1837, pstyle(p2)) (pE1836, pstyle(p2)) (pE1835, pstyle(p2))	///
		 (pE1834, pstyle(p2)) (pE1833, pstyle(p2)) (pE1832, pstyle(p2))	///
		 (pE1831, pstyle(p2)) (pE1830, pstyle(p2)) (pE1829, pstyle(p2))	///
		 (pE1828, pstyle(p2)) (pE1827, pstyle(p2)) (pE1826, pstyle(p2))	///
		 (pE1825, pstyle(p2)) (pE1824, pstyle(p2)) (pE1823, pstyle(p2))	///
		 (pE1822, pstyle(p2)) (pE1821, pstyle(p2)) (pE1820, pstyle(p2))	///
		 (pE1819, pstyle(p2)) (pE1818, pstyle(p2)) (pE1817, pstyle(p2))	///
		 (pE1816, pstyle(p2)) (pE1815, pstyle(p2)) (pE1814, pstyle(p2))	///
		 (pE1813, pstyle(p2)) (pE1812, pstyle(p2)) (pE1811, pstyle(p2)), 	///	
		 drop(biorder hengpee pr4 pr_3 ̇_cons distlondon) ///
		 msymbol(d) mfcolor(white) levels(95 90) graphregion(color(white)) ///
		 title("Dep. Var: Married a commoner", color(black)) ytitle("mg. effect of T (synthetic prob.)") xtitle("years of placebo interruption") ///
		 ylabel(-0.015(0.005)0.015, nogrid) legend(on order(3 "Baseline (1861-63)" 9 "Placebo") rows(2) ring(0) position(5) bmargin(large)) ///
		 xlabel(0.568 "1851-53" 0.6816 "1846-48" 0.7955 "1841-43" 0.909 "1836-38" 1.023 "1831-33" 1.1366 "1826-28" 1.24939 "1821-23" 1.36392 "1816-18" 1.4775 "1811-13", angle(45)) ///
		 yline(0) lpattern(dash) baselevels vert ///
		 xline(0.568, lpattern(dot) lcolor(gray)) ///
		 xline(0.6816, lpattern(dot) lcolor(gray)) ///
		 xline(0.7955, lpattern(dot) lcolor(gray)) ///
		 xline(0.909, lpattern(dot) lcolor(gray)) ///
		 xline(1.023, lpattern(dot) lcolor(gray)) ///
		 xline(1.1366, lpattern(dot) lcolor(gray)) ///
		 xline(1.24939, lpattern(dot) lcolor(gray)) ///
		 xline(1.36392, lpattern(dot) lcolor(gray)) ///
		 xline(1.4775, lpattern(dot) lcolor(gray)) ///
	text(0.00539529 0.57037 ".037", size(vsmall) orientation(vertical)) ///
	text(0.00539529 0.59037 ".06", size(vsmall) orientation(vertical)) ///
	text(0.00250475 0.613635 ".01", size(vsmall) orientation(vertical)) ///
	text(0.00276912 0.636005 ".01", size(vsmall) orientation(vertical)) ///
	text(0.0012222 0.658375 ".00", size(vsmall) orientation(vertical)) ///
text(0.00079789 0.6816  ".00", size(vsmall) orientation(vertical) box bcolor(white) fcolor(white) lcolor(white)) ///
	text(0.00076157 0.70397 ".00", size(vsmall) orientation(vertical)) ///
	text(0.00128846 0.727235 ".00", size(vsmall) orientation(vertical)) ///
	text(0.00131826 0.749605 ".00", size(vsmall) orientation(vertical)) ///
	text(0.00379514 0.771975 ".02", size(vsmall) orientation(vertical)) ///
text(0.00402036 0.7955  ".02", size(vsmall) orientation(vertical) box bcolor(white) fcolor(white) lcolor(white)) ///
	text(0.00382393 0.81761 ".01", size(vsmall) orientation(vertical)) ///
	text(0.00283652 0.840875 ".01", size(vsmall) orientation(vertical)) ///
	text(0.00210621 0.86414 ".00", size(vsmall) orientation(vertical)) ///
	text(0.00346859 0.88651 ".01", size(vsmall) orientation(vertical)) ///
text(0.00176394 0.909  ".00", size(vsmall) orientation(vertical) box bcolor(white) fcolor(white) lcolor(white)) ///
	text(0.0017114 0.932145 ".00", size(vsmall) orientation(vertical)) ///
	text(0.00205746 0.954515 ".01", size(vsmall) orientation(vertical)) ///
	text(0.00234219 0.97778 ".01", size(vsmall) orientation(vertical)) ///
	text(0.00537774 1.00015 ".12", size(vsmall) orientation(vertical)) ///
text(0.0057546 1.023  ".14", size(vsmall) orientation(vertical) box bcolor(white) fcolor(white) lcolor(white)) ///
	text(0.00787327 1.04579 ".41", size(vsmall) orientation(vertical)) ///
	text(0.00696466 1.06816 ".23", size(vsmall) orientation(vertical)) ///
	text(0.00774832 1.09142 ".25", size(vsmall) orientation(vertical)) ///
	text(0.00742015 1.11379 ".20", size(vsmall) orientation(vertical)) ///
text(0.008436 1.1366  ".31", size(vsmall) orientation(vertical) box bcolor(white) fcolor(white) lcolor(white)) ///
	text(0.00712933 1.15943 ".22", size(vsmall) orientation(vertical)) ///
	text(0.00506362 1.1818 ".08", size(vsmall) orientation(vertical)) ///
	text(0.00545438 1.20506 ".10", size(vsmall) orientation(vertical)) ///
	text(0.00608598 1.22743 ".12", size(vsmall) orientation(vertical)) ///
text(0.00530855 1.24939  ".13", size(vsmall) orientation(vertical) box bcolor(white) fcolor(white) lcolor(white)) ///
	text(0.00537472 1.27307 ".17", size(vsmall) orientation(vertical)) ///
	text(0.00442368 1.29454 ".08", size(vsmall) orientation(vertical)) ///
	text(0.0031978 1.3187 ".03", size(vsmall) orientation(vertical)) ///
	text(0.00497223 1.34107 ".09", size(vsmall) orientation(vertical)) ///
text(0.00586515 1.36392  ".16", size(vsmall) orientation(vertical) box bcolor(white) fcolor(white) lcolor(white)) ///
	text(0.00497563 1.38671 ".11", size(vsmall) orientation(vertical)) ///
	text(0.00487153 1.40908 ".10", size(vsmall) orientation(vertical)) ///
	text(0.00658739 1.43145 ".21", size(vsmall) orientation(vertical)) ///
	text(0.00614651 1.45471 ".17", size(vsmall) orientation(vertical)) ///
text(0.00672715 1.4775  ".19", size(vsmall) orientation(vertical) box bcolor(white) fcolor(white) lcolor(white))
graph export "${dirresu}\Figure6.pdf", replace


* Tests equality of coefficients

	/* Note: the following tests for the equality of coefficients report all the 
	p-values displayed in the Figure above */
	
use "${dirdata}\placebo-data.dta", clear
keep if nthismarr==1
gen syntheticT0 = syntheticT // just for label purposes
replace syntheticT0 = synthetic_plac if synthetic_plac!=.
qui probit cOut syntheticT0 $controls distlondon if sample0=="baseline"
estimates store myreg0
sort refno sample01 	// drop observations in both baseline and placebo samples
by refno: gen dup=_N
by refno: drop if sample0[1]!= sample0[2] & dup>1
	*local count10 = 0
	*local count5 = 0
	*local count1 = 0
forvalues i=1851(-1)1811{
qui probit cOut syntheticT0 $controls distlondon if sample01==`i' & sample0=="placebo"
estimates store myreg`i'
* tests
qui suest myreg0 myreg`i', cluster(byearclst)
display "---- `i' ----"
test [myreg0_cOut]syntheticT0=[myreg`i'_cOut]syntheticT0
local pval = round(`r(p)',0.001)
di `pval'
}



* ==============================================================================
* FIGURE 7: 
* Peer-commoner intermarriage, Probit estimation with age dummies.
* ------------------------------------------------------------------------------

* Import placebo dataset
use "${dirdata}\placebo-data.dta", clear
global controls pr4 biorder hengpee


* Panel A: baseline sample
fvset base 16 age1861
qui probit cOut i.age1861 $controls if base_sample==1, cluster(byearclst)
qui margins, dydx(*) predict(pr) post
estimates store BASE
fvset base 0 age1861
qui reg syntheticT i.age1861 if base_sample==1, nocons
estimates store BASEsynth
coefplot (BASE, label("cohort-level effect (left axis)") ylabel(-0.2(0.1)0.5)) ///
		 (BASEsynth, label("synthetic prob. of marrying at interruption (right axis)") axis(2) ylabel(5(5)25, axis(2)) offset(-0.05) recast(line) symbol(none)), ///
		 drop(biorder hengpee pr4 ̇_cons 0.age1861 15.age1861 27.age1861 28.age1861 29.age1861 30.age1861 31.age1861 32.age1861 33.age1861 34.age1861 35.age1861) ///
		 msymbol(d) mfcolor(white) levels(99 95 90) graphregion(color(white)) ///
		 title("Baseline", color(black)) xtitle(age in 1861) ytitle("prob. of marrying a commoner") ///
		 legend(on rows(2) region(lstyle(none))) ///
		 xlabel(1 "16" 2 "17" 3 "18" 4 "19" 5 "20" 6 "21" 7 "22" 8 "23" 9 "24" 10 "25" 11 "26") ///
		 yline(0) ylabel(-0.2(0.1)0.6) lpattern(dash) name(base, replace) vert baselevels


* Panel B: placebo
sort refno sample01 	// drop observations in both baseline and placebo samples
by refno: gen dup=_N
by refno: drop if sample0[1]!= sample0[2] & dup>1
keep if nthismarr==1
drop age1861	// just for labelling purposes
rename age1861_plac age1861
fvset base 16 age1861
qui probit cOut i.age1861 $controls i.sample01 if sample0=="placebo", cluster(byearclst)
qui margins, dydx(*) predict(pr) post
estimates store PLAC
coefplot (PLAC, label("cohort-level effect (left axis)") ylabel(-0.2(0.1)0.5)) ///
		 (BASEsynth, label("synthetic prob. of marrying at interruption (right axis)") axis(2) ylabel(5(5)25, axis(2)) offset(-0.05) recast(line) symbol(none)), ///
		 keep(16.age1861 17.age1861 18.age1861 19.age1861 20.age1861 21.age1861 22.age1861 23.age1861 24.age1861 25.age1861 26.age1861) ///
		 msymbol(d) mfcolor(white) levels(99 95 90) graphregion(color(white)) ///
 		 title("Placebo", color(black)) xtitle(age in 1861-X) graphregion(color(white)) ///
		 legend(on rows(2) region(lstyle(none))) ///
		 xlabel(1 "16" 2 "17" 3 "18" 4 "19" 5 "20" 6 "21" 7 "22" 8 "23" 9 "24" 10 "25" 11 "26") ///
		 yline(0) ylabel(-0.2(0.1)0.6) lpattern(dash) name(placebo, replace) vert baselevels


* Figure:
grc1leg base placebo, legendfrom(base) graphregion(color(white))
graph export "${dirresu}\Figure7.pdf", replace
graph drop _all
erase "${dirdata}\placebo-data.dta"


* ==============================================================================
* TABLE 3: 
* The Season's interruption and marriage outcomes, IV estimation.
* ------------------------------------------------------------------------------

* Import data and keep baseline sample
use "${dirdata}\final-data.dta", clear
keep if base_sample==1


* IV regressions
global controls pr4 biorder hengpee

* [1]
qui summ cOut
	local mdepvar = round(`r(mean)',0.01)
qui reg mourn syntheticT $controls, cluster(byear)
	local F1 = round(e(F),0.1)
qui cmp (cOut = mourn $controls) (mourn = syntheticT $controls), ind(4 1) cluster(byear) quietly
	qui margins, dydx(*) predict(pr) post
	outreg2 using "${dirresu}\Table3_A", keep(mourn) nocons label dec(2) coefastr ctitle("M common") addtext(Weak iv p-val, ., Mean DV, `mdepvar') tex replace
qui cmp (cOut = mourn $controls) (mourn = syntheticT $controls), ind(4 1) cluster(byear) quietly
	qui margins, dydx(*) predict(eq(#2)) post
	outreg2 using "${dirresu}\Table3_B", keep(syntheticT) nocons label dec(2) coefastr ctitle("M interr") addtext(F-stat, `F1') tex replace

* [2]
qui summ cOut if distlondon!=.
	local mdepvar = round(`r(mean)',0.01)
qui reg mourn syntheticT $controls distlondon, cluster(byear)
	local F1 = round(e(F),0.1)
qui cmp (cOut = mourn $controls distlondon) (mourn = syntheticT $controls distlondon), ind(4 1) cluster(byear) quietly
	qui margins, dydx(*) predict(pr) post
	outreg2 using "${dirresu}\Table3_A", keep(mourn) nocons label dec(2) coefastr ctitle("M common") addtext(Weak iv p-val, ., Mean DV, `mdepvar') tex
qui cmp (cOut = mourn $controls distlondon) (mourn = syntheticT $controls distlondon), ind(4 1) cluster(byear) quietly
	qui margins, dydx(*) predict(eq(#2)) post
	outreg2 using "${dirresu}\Table3_B", keep(syntheticT) nocons label dec(2) coefastr ctitle("M interr") addtext(F-stat, `F1') tex
* [3] and [4]
foreach x in "" distlondon{
qui reg mheir syntheticT $controls `x', cluster(byear)
	qui summ mheir if e(sample)==1
	local mdepvar = round(`r(mean)',0.01)
qui reg mourn syntheticT $controls `x', cluster(byear)
	local F1 = round(e(F),0.1)
qui cmp (mheir = mourn $controls `x') (mourn = syntheticT $controls `x'), ind(4 1) cluster(byear) quietly
	qui margins, dydx(*) predict(pr) post
	outreg2 using "${dirresu}\Table3_A", keep(mourn) nocons label dec(2) coefastr ctitle("M heir") addtext(Weak iv p-val, ., Mean DV, `mdepvar') tex
qui cmp (mheir = mourn $controls `x') (mourn = syntheticT $controls `x'), ind(4 1) cluster(byear) quietly
	qui margins, dydx(*) predict(eq(#2)) post
	outreg2 using "${dirresu}\Table3_B", keep(syntheticT) nocons label dec(2) coefastr ctitle("M interr") addtext(F-stat, `F1') tex
}
* [5] and [6]
foreach x in "" distlondon{
qui reg fmissmatch syntheticT $controls `x', cluster(byear)
	qui summ fmissmatch if e(sample)==1
	local mdepvar = round(`r(mean)',1)
qui ivregress liml fmissmatch (mourn = syntheticT) $controls `x', cluster(byear) first
	qui weakiv, null(0) small
	local wivpv = round(e(ar_p), 0.01)
qui reg mourn syntheticT $controls `x' if fmissmatch!=., cluster(byear)
	local F1 = round(e(F),0.1)
qui ivregress liml fmissmatch (mourn = syntheticT) $controls `x', cluster(byear)
	outreg2 using "${dirresu}\Table3_A", keep(mourn) nocons label dec(1) coefastr ctitle("Diff abs") addtext(Weak iv p-val, `wivpv', Mean DV, `mdepvar') tex
qui cmp (fmissmatch = mourn $controls `x') (mourn = syntheticT $controls `x') if fmissmatch!=., ind(1 1) cluster(byear) quietly
	qui margins, dydx(*) predict(eq(#2)) post
	outreg2 using "${dirresu}\Table3_B", keep(syntheticT) nocons label dec(2) coefastr ctitle("M interr") addtext(F-stat, `F1') tex
}
* [7] and [8]
foreach x in "" distlondon{
qui reg fmissmatch2 syntheticT $controls `x', cluster(byear)
	qui summ fmissmatch2 if e(sample)==1
	local mdepvar = round(`r(mean)',1)
qui ivregress liml fmissmatch2 (mourn = syntheticT) $controls `x', cluster(byear) first
	qui weakiv, null(0) small
	local wivpv = round(e(ar_p), 0.01)
qui reg mourn syntheticT $controls `x' if fmissmatch2!=., cluster(byear)
	local F1 = round(e(F),0.1)
qui ivregress liml fmissmatch2 (mourn = syntheticT) $controls `x', cluster(byear)
	qui margins, dydx(*) post
	outreg2 using "${dirresu}\Table3_A", keep(mourn) nocons label dec(1) coefastr ctitle("Diff h-w") addtext(Weak iv p-val, `wivpv', Mean DV, `mdepvar') tex
qui cmp (fmissmatch2 = mourn $controls `x') (mourn = syntheticT $controls `x') if fmissmatch2!=., ind(1 1) cluster(byear) quietly
	qui margins, dydx(*) predict(eq(#2)) post
	outreg2 using "${dirresu}\Table3_B", keep(syntheticT) nocons label dec(2) coefastr ctitle("M interr") addtext(F-stat, `F1') tex
}
* [9] and [10]
foreach x in "" distlondon{
qui reg fdown syntheticT $controls `x', cluster(byear)
	qui summ fdown if e(sample)==1
	local mdepvar = round(`r(mean)',0.01)
qui ivregress liml fdown (mourn = syntheticT) $controls `x', cluster(byear)
	qui weakiv, null(0) small
	local wivpv = round(e(ar_p), 0.01)
qui reg mourn syntheticT $controls `x' if fdown!=., cluster(byear)
	local F1 = round(e(F),0.1)
qui cmp (fdown = mourn $controls `x') (mourn = syntheticT $controls `x') if fdown!=., ind(4 1) cluster(byear) quietly
	qui margins, dydx(*) predict(pr) post
	outreg2 using "${dirresu}\Table3_A", keep(mourn) nocons label dec(2) coefastr ctitle("M down") addtext(Weak iv p-val, `wivpv', Mean DV, `mdepvar') tex
qui cmp (fdown = mourn $controls `x') (mourn = syntheticT $controls `x') if fdown!=., ind(4 1) cluster(byear) quietly
	qui margins, dydx(*) predict(eq(#2)) post
	outreg2 using "${dirresu}\Table3_B", keep(syntheticT) nocons label dec(2) coefastr ctitle("M interr") addtext(F-stat, `F1') tex
}



* ==============================================================================
* TABLE 4: 
* Contingency tables.
* ------------------------------------------------------------------------------

* Import data and keep baseline sample
use "${dirdata}\final-data.dta", clear
keep if base_sample==1


* Treatment indicator for non-parametric analysis
_pctile syntheticT, nq(100)
gen treatment = (syntheticT > r(r80))

	/* Note: For the non-parametric estimation, I compare a high- vs. a low-treatment
	cohort. The high-treatment cohort are women with a synthetic probability to
	marry during the interruption above 20 percent. This corresponds to the top
	quintile; the 20% of women with the highest synthetic probability to marry in
	1861-63. Conversely, the low-treatment cohort are women below the top quintile. */


* Contingency tables
label var grank "Wife"
capture log close				// save results in log file
cd "${dirresu}"
log using Table4.log, replace

*  Panel A: Low-Treatment cohorts (T < 80th percentile)
tab grank grankspo if treatment==0, expected matcell(ofreqa)

*  Panel B: High-Treatment cohorts (T >= 80th percentile)
tab grank grankspo if treatment==1, expected matcell(ofreqa)
log close



* ==============================================================================
* TABLE 5: 
* The interruption and sorting by title, non-parametric estimates.
* ------------------------------------------------------------------------------

* Import data and keep baseline sample
use "${dirdata}\final-data.dta", clear
keep if base_sample==1


* Treatment indicator for non-parametric analysis
_pctile syntheticT, nq(100)
gen treatment = (syntheticT > r(r80))


* Non-parametric stats
forvalues i=0/1{
tab grank grankspo if treatment==`i', chi2 lrchi2
local chi2_`i' = r(chi2)
local chi2LR_`i' = r(chi2_lr)
local chi2p_`i' = r(p)
local chi2LRp_`i' = r(p_lr)
local df_`i' = e(df_r)
local N`i' = r(N)
ktau grank grankspo if treatment==`i', stats(taub)
local taub_`i' = r(tau_b)
local taubp_`i' = r(p)
}


* Add results to matrix tab5
mat define tab5 = (.,.,.\.,.,.\.,.,.\.,.,.\.,.,.\.,.,.\.,.,.)
forvalues j =0/1{
local col = `j'+1
mat tab5[1,`col'] = `chi2_`j''
mat tab5[2,`col'] = `chi2p_`j''
mat tab5[3,`col'] = `chi2LR_`j''
mat tab5[4,`col'] = `chi2LRp_`j''
mat tab5[5,`col'] = `taub_`j''
mat tab5[6,`col'] = `taubp_`j''
mat tab5[7,`col'] = `N`j''
}
mat tab5[5,3] = `taub_0'-`taub_1'
mat tab5[7,3] = `N0'+`N1'


* Difference chi-squared and LR-chi2
local chi2_diff = `chi2_0'-`chi2_1'
local chi2_diffp = chi2tail(3,`chi2_diff')
local chi2LR_diff = `chi2LR_0'-`chi2LR_1'
local chi2LR_diffp = chi2tail(3,`chi2LR_diff')
mat tab5[1,3] = `chi2_diff'
mat tab5[2,3] = `chi2_diffp'
mat tab5[3,3] = `chi2LR_diff'
mat tab5[4,3] = `chi2LR_diffp'


* Difference tau-b
qui ktau grank grankspo if treatment==0
local convtaub_0 = sin(3.141592654*`r(tau_b)'*0.5)
qui ktau grank grankspo if treatment==1
local convtaub_1 = sin(3.141592654*`r(tau_b)'*0.5)
cortesti `convtaub_0' `N0' `convtaub_1' `N1'
mat tab5[6,3] = 0.1637


* Table 5
mat colnames tab5 = "Low-treat" "High-treat" "Diff"
mat rownames tab5 = "Pearson chi-squared" "  p-val" "Likelihood ratio" "  p-val" "Kendall rank correlation" "  p-val" "N"
mat list tab5
esttab matrix(tab5, fmt(3 3)) using "${dirresu}\Table5.tex", mlabel("Table 5") replace



* ==============================================================================
* FIGURE 8: 
* Sorting by landholdings, non-parametric estimation.
* ------------------------------------------------------------------------------

* Import data and keep baseline sample
use "${dirdata}\final-data.dta", clear
keep if base_sample==1


* Treatment indicator for non-parametric analysis
_pctile syntheticT, nq(100)
gen treatment = (syntheticT > r(r80))
count if fmissmatch!=.	// sample (N=324)
count if fmissmatch!=. & treatment==0	// Low-treatment (N=256)
count if fmissmatch!=. & treatment==0 & age1861<22	// Low-treatment, younger (N=64)
count if fmissmatch!=. & treatment==0 & age1861>22	// Low-treatment, older (N=192)


* Kolmogorov-Smirnov tests
gen treat2`x' = treatment // for High vs. younger comparison
replace treat2 = . if treatment==0 & age1861>22
gen treat3 = treatment // for High vs. older comparison
replace treat3 = . if treatment==0 & age1861<22
foreach x in "" 2{
sort fmissmatch`x' age1861
qui ksmirnov fmissmatch`x', by(treatment) exact
local KS1`x' = round(`r(D)',0.01)
local pval1`x' = round(`r(p_exact)',0.001)
ksmirnov fmissmatch`x', by(treat2) exact
local KS2`x' = round(`r(D)',0.01)
local pval2`x' = round(`r(p_exact)',0.001)
ksmirnov fmissmatch`x', by(treat3) exact
local KS3`x' = round(`r(D)',0.01)
local pval3`x' = round(`r(p_exact)',0.001)
}


* Figure, Panel A
preserve
sort fmissmatch age1861
cumul fmissmatch if treatment>0, gen(cumTREAT)
cumul fmissmatch if treatment==0, gen(cumCONTROL)
cumul fmissmatch if treatment==0 & age1861>22, gen(cumCONTROLold)
cumul fmissmatch if treatment==0 & age1861<22, gen(cumCONTROLyoung)
twoway 	(line cumTREAT fmissmatch, c(J) lwidth(thick) lcolor(red)) ///
		(line cumCONTROL fmissmatch, c(J) lwidth(thin) lcolor(blue)) ///
		(line cumCONTROLold fmissmatch, c(J) lwidth(thin) lpattern(dash) lcolor(emidblue)) ///
		(line cumCONTROLyoung fmissmatch, c(J) lwidth(thin) lpattern(solid) lcolor(emidblue)), ///
		xtitle("|wife's percentile rank of acres - husband's percentile rank of acres|", size(med))	///
		ytitle("cumulative", size(med))	///
		legend(on order(1 "High-Treatment (T{&ge}80p)" 2 "Low-Treatment (T<80p)" 3 "older" 4 "younger") rows(4) ring(0) position(5) bmargin(large) region(lstyle(none))) ///
		graphregion(color(white)) ///
		note("High vs low: KS = `KS1' (`pval1'); High vs younger: KS = `KS2' (`pval2'); High vs older: KS = `KS3' (`pval3')")
graph export "${dirresu}\Figure8_A.pdf", as(pdf) replace
restore


* Figure, Panel B
preserve
sort fmissmatch2 age1861
cumul fmissmatch2 if treatment>0, gen(cumTREAT)
cumul fmissmatch2 if treatment==0, gen(cumCONTROL)
cumul fmissmatch2 if treatment==0 & age1861>22, gen(cumCONTROLold)
cumul fmissmatch2 if treatment==0 & age1861<22, gen(cumCONTROLyoung)
twoway 	(line cumTREAT fmissmatch2, c(J) lwidth(thick) lcolor(red)) ///
		(line cumCONTROL fmissmatch2, c(J) lwidth(thin) lcolor(blue)) ///
		(line cumCONTROLold fmissmatch2, c(J) lwidth(thin) lpattern(dash) lcolor(emidblue)) ///
		(line cumCONTROLyoung fmissmatch2, c(J) lwidth(thin) lpattern(solid) lcolor(emidblue)) ///
		(pcarrowi 0.95 -40 0.95 -60 "Marrying down", color(black)), ///
		xtitle("difference in acres' precentile rank (husband-wife)", size(med))	///
		xline(0, lcolor(black) lwidth(thick)) ytitle("cumulative", size(med))	///
		legend(on order(1 "High-Treat (T{&ge}80p.)" 2 "Low-Treat (T<80p.)" 3 "older" 4 "younger") rows(4) ring(0) position(5) bmargin(large) region(lstyle(none))) ///
		graphregion(color(white)) ///
		note("High vs low: KS = `KS12' (`pval12'); High vs younger: KS = `KS22' (`pval22'); High vs older: KS = `KS32' (`pval32')")
graph export "${dirresu}\Figure8_B.pdf", as(pdf) replace
restore



* ==============================================================================
* TABLE 6: 
* Women's marriages to commoners and her family's political power, IV estimation.
* ------------------------------------------------------------------------------

* Import data
use "${dirdata}/final-data-sec4.dta", clear


* Control variables:
gen nsib2 = nsib^2 											// Number of siblings squared
global controlsb distlondon i.prank nsib nsib2				// controls for regressions with brothers
global controlsh distlondon i.prank							// controls for regressions with family heads
global hechter propman100 logincome propcon propnonc relig	// county controls from Hechter


* Collapse data such that a woman (and her family) is the unit of observation
encode fbio1, gen(nfam) // clusters at the family level
collapse cOut syntheticT byear nfam d_MPb_aft d_MPf_bef MPb_years_aft MPf_years_bef d_MPb_locaft2 d_MPf_local2 MPb_years_locaft MPf_years_locbef d_MPh_aft d_MPh_bef MPh_years_aft MPh_years_bef ///
		 biorder distlondon prank nsib nsib2 $hechter, by(refno)
label var cOut "W married a commoner"


* Col [1]: Any brother is MP after woman's marriage

global polit d_MPb_aft
global polbefore d_MPf_bef
* CLR p-values
qui ivprobit $polit (cOut = syntheticT biorder) $hechter $controlsb $polbefore, first twostep
	weakiv, null(0) small
	local CLR1 = round(e(clr_p), 0.001)
* CLR p-values clustered by family
qui ivregress liml $polit (cOut = syntheticT biorder) $hechter $controlsb $polbefore, first vce(cluster nfam)
	local Nbobs = `e(N)'	// just so that N appears after CLR p-values in table
	weakiv, null(0) small
	local CLR2 = round(e(clr_p), 0.001)
	summ $polit if e(sample)==1
	local mdepvar = round(r(mean),0.01)
* Second stage coefficients
qui cmp ($polit = cOut $hechter $controlsb $polbefore) (cOut = syntheticT biorder $hechter $controlsb $polbefore), ind(4 1) quietly cluster(byear)
	qui margins, dydx(*) predict(pr) post
	outreg2 using "${dirresu}\Table6_A", keep(cOut) nocons label nose dec(2) noas noobs	///
	ctitle("MP (b)") addtext(CLR-pval, `CLR1', CLR-pval 2, `CLR2', Mean DP, `mdepvar', Nb observations, `Nbobs') tex replace
* First stage coefs in Panel B
qui reg cOut syntheticT biorder $hechter $controlsb $polbefore
	local F1 = round(e(F),0.1)
	outreg2 using "${dirresu}\Table6_B", keep(syntheticT) nocons label noas nor2 dec(3) coefastr ctitle("M common") addtext(F-stat, `F1') tex replace


* Col [2]: Years MP after woman's marriage (brothers)

global polit MPb_years_aft
global polbefore MPf_years_bef
* CLR p-values
qui ivregress liml $polit (cOut = syntheticT biorder) $hechter $controlsb $polbefore, first
	qui weakiv, null(0) small
	local CLR1 = round(e(clr_p), 0.001)
* CLR p-values clustered by family
qui ivregress liml $polit (cOut = syntheticT biorder) $hechter $controlsb $polbefore, first vce(cluster nfam)
	local Nbobs = `e(N)'	// just so that N appears after CLR p-values in table
	qui weakiv, null(0) small
	local CLR2 = round(e(clr_p), 0.001)
	summ $polit if e(sample)==1
	local mdepvar = round(r(mean),0.01)
* Second stage coefficients
qui cmp ($polit = cOut $hechter $controlsb $polbefore) (cOut = syntheticT biorder $hechter $controlsb $polbefore), ind(1 1) quietly cluster(byear)
	qui margins, dydx(*) post
	outreg2 using "${dirresu}\Table6_A", keep(cOut) nocons label nose dec(2) noas noobs	///
	ctitle("Years (b)") addtext(CLR-pval, `CLR1', CLR-pval 2, `CLR2', Mean DP, `mdepvar', Nb observations, `Nbobs') tex
* First stage coefs in Panel B
qui reg cOut syntheticT biorder $hechter $controlsb $polbefore
	local F1 = round(e(F),0.1)
	outreg2 using "${dirresu}\Table6_B", keep(syntheticT) nocons label noas nor2 dec(3) coefastr ctitle("M common") addtext(F-stat, `F1') tex

	
* Col [3]: Any brother is local MP after woman's marriage

global polit d_MPb_locaft2
global polbefore d_MPf_local2
* CLR p-values
qui ivprobit $polit (cOut = syntheticT biorder) $hechter $controlsb $polbefore, first twostep
	qui weakiv, null(0) small
	local CLR1 = round(e(clr_p), 0.001)
* CLR p-values clustered by family
qui ivregress liml $polit (cOut = syntheticT biorder) $hechter $controlsb $polbefore, first vce(cluster nfam)
	local Nbobs = `e(N)'	// just so that N appears after CLR p-values in table
	qui weakiv, null(0) small
	local CLR2 = round(e(clr_p), 0.001)
	summ $polit if e(sample)==1
	local mdepvar = round(r(mean),0.01)
* Second stage coefficients
qui cmp ($polit = cOut $hechter $controlsb $polbefore) (cOut = syntheticT biorder $hechter $controlsb $polbefore), ind(4 1) quietly cluster(byear)
	qui margins, dydx(*) predict(pr) post
	outreg2 using "${dirresu}\Table6_A", keep(cOut) nocons label nose dec(2) noas noobs	///
	ctitle("local MP (b)") addtext(CLR-pval, `CLR1', CLR-pval 2, `CLR2', Mean DP, `mdepvar', Nb observations, `Nbobs') tex
* First stage coefs in Panel B
qui reg cOut syntheticT biorder $hechter $controlsb $polbefore
	local F1 = round(e(F),0.1)
	outreg2 using "${dirresu}\Table6_B", keep(syntheticT) nocons label noas nor2 dec(3) coefastr ctitle("M common") addtext(F-stat, `F1') tex
	

* Col [4]: Years local MP after woman's marriage (brothers)

global polit MPb_years_locaft
global polbefore MPf_years_locbef
* CLR p-values
qui ivregress liml $polit (cOut = syntheticT biorder) $hechter $controlsb $polbefore, first
	qui weakiv, null(0) small
	local CLR1 = round(e(clr_p), 0.001)
* CLR p-values clustered by family
qui ivregress liml $polit (cOut = syntheticT biorder) $hechter $controlsb $polbefore, vce(cluster nfam)
	local Nbobs = `e(N)'	// just so that N appears after CLR p-values in table
	qui weakiv, null(0) small
	local CLR2 = round(e(clr_p), 0.001)
	summ $polit if e(sample)==1
	local mdepvar = round(r(mean),0.01)
* Second stage coefficients
qui cmp ($polit = cOut $hechter $controlsb $polbefore) (cOut = syntheticT biorder $hechter $controlsb $polbefore), ind(1 1) quietly cluster(byear)
	qui margins, dydx(*) post
	outreg2 using "${dirresu}\Table6_A", keep(cOut) nocons label nose dec(3) noas noobs	///
	ctitle("lyears (b)") addtext(CLR-pval, `CLR1', CLR-pval 2, `CLR2', Mean DP, `mdepvar', Nb observations, `Nbobs') tex
* First stage coefs in Panel B
qui reg cOut syntheticT biorder $hechter $controlsb $polbefore
	local F1 = round(e(F),0.1)
	outreg2 using "${dirresu}\Table6_B", keep(syntheticT) nocons label noas nor2 dec(3) coefastr ctitle("M common") addtext(F-stat, `F1') tex


* Col [5]: Family head is MP after woman's marriage

global polit d_MPh_aft
global polbefore d_MPh_bef
* CLR p-values
qui ivprobit $polit (cOut = syntheticT biorder) $hechter $controlsh $polbefore, first twostep
	qui weakiv, null(0) small
	local CLR1 = round(e(clr_p), 0.001)
* CLR p-values clustered by family
qui ivregress liml $polit (cOut = syntheticT biorder) $hechter $controlsh $polbefore, vce(cluster nfam)
	local Nbobs = `e(N)'	// just so that N appears after CLR p-values in table
	qui weakiv, null(0) small
	local CLR2 = round(e(clr_p), 0.001)
	summ $polit if e(sample)==1
	local mdepvar = round(r(mean),0.01)
* Second stage coefficients
qui cmp ($polit = cOut $hechter $controlsh $polbefore) (cOut = syntheticT biorder $hechter $controlsh $polbefore), ind(4 1) quietly cluster(byear)
	qui margins, dydx(*) predict(pr) post
	outreg2 using "${dirresu}\Table6_A", keep(cOut) nocons label nose dec(2) noas noobs	///
	ctitle("MP (h)") addtext(CLR-pval, `CLR1', CLR-pval 2, `CLR2', Mean DP, `mdepvar', Nb observations, `Nbobs') tex
* First stage coefs in Panel B
qui reg cOut syntheticT biorder $hechter $controlsh $polbefore
	local F1 = round(e(F),0.1)
	outreg2 using "${dirresu}\Table6_B", keep(syntheticT) nocons label noas nor2 dec(3) coefastr ctitle("M common") addtext(F-stat, `F1') tex


* Col [6]: Years MP after woman's marriage (family head)

global polit MPh_years_aft
global polbefore MPh_years_bef
* CLR p-values
qui ivregress liml $polit (cOut = syntheticT biorder) $hechter $controlsh $polbefore, first 	//
	qui weakiv, null(0) small
	local CLR1 = round(e(clr_p), 0.001)
* CLR p-values clustered by family
qui ivregress liml $polit (cOut = syntheticT biorder) $hechter $controlsh $polbefore, vce(cluster nfam)
	local Nbobs = `e(N)'	// just so that N appears after CLR p-values in table
	qui weakiv, null(0) small
	local CLR2 = round(e(clr_p), 0.001)
	summ $polit if e(sample)==1
	local mdepvar = round(r(mean),0.01)
* Second stage coefficients
qui cmp ($polit = cOut $hechter $controlsb $polbefore) (cOut = syntheticT biorder $hechter $controlsb $polbefore), ind(1 1) quietly cluster(byear)
	qui margins, dydx(*) post
	outreg2 using "${dirresu}\Table6_A", keep(cOut) nocons label nose dec(2) noas noobs	///
	ctitle("Years (h)") addtext(CLR-pval, `CLR1', CLR-pval 2, `CLR2', Mean DP, `mdepvar', Nb observations, `Nbobs') tex
* First stage coefs in Panel B
qui reg cOut syntheticT biorder $hechter $controlsh $polbefore
	local F1 = round(e(F),0.1)
	outreg2 using "${dirresu}\Table6_B", keep(syntheticT) nocons label noas nor2 dec(3) coefastr ctitle("M common") addtext(F-stat, `F1') tex



* ==============================================================================
* TABLE 7: 
* Determinants of investments in state education, IV estimation.
* ------------------------------------------------------------------------------

* Import data
use "${dirdata}/final-data-sec4.dta", clear


* Control variables:
gen nsib2 = nsib^2 											// Number of siblings squared
global controlsrf distlondon i.prank						// controls for reduced-form effect
global controlsb  distlondon i.prank nsib nsib2				// controls for regressions with brothers
global controlsh  distlondon i.prank							// controls for regressions with family heads
global hechter propman100 logincome propcon propnonc relig	// county controls from Hechter
encode fbio1, gen(nfam) 									// clusters at the family level
label var cOut "W married a commoner"

	/* Note: Panel B results for p-values (parenthesis) and CLR p-values 
	adjusted for weak instruments [brackets] are in one column in the paper,
	in two columns in the table produced by this code.  */

* Col [1]: Reduced-form effect

* CLR p-values
qui ivregress liml rateperpou (cOut = syntheticT biorder) $hechter $controlsrf , first
	qui weakiv, null(0) small
	local CLR1 = round(e(clr_p), 0.001)
* CLR p-values clustered by family
qui ivregress liml rateperpou (cOut = syntheticT biorder) $hechter $controlsrf , first vce(cluster nfam)
	local Nbobs = `e(N)'	// just so that N appears after CLR p-values in table
	weakiv, null(0) small
	local CLR2 = round(e(clr_p), 0.001)
* Second-stage coefficients
qui ivregress liml rateperpou (cOut = syntheticT biorder) $hechter $controlsrf , first
	outreg2 using "${dirresu}\Table7_A", keep(cOut) stats(coef) nocons label noobs dec(2) noas ///
	ctitle("tax rate") addtext(CLR-pval, `CLR1', CLR-pval 2, `CLR2', Nb observations, `Nbobs') tex replace	
* First stage coefs in Panel B
qui reg cOut syntheticT biorder $hechter $controlsrf
	local F1 = round(e(F),0.01)
qui ivreg2 rateperpound (cOut = syntheticT biorder) $hechter $controlsrf , first savefirst
	est restore _ivreg2_cOut
	outreg2 using "${dirresu}\Table7_B", keep(syntheticT) replace tex ctitle("M common") label dec(3) noaster nocons nor2 stats(coef pval) addtext(F-stat, `F1', cluster, .)
qui ivreg2 rateperpound (cOut = syntheticT biorder) $hechter $controlsrf , first cluster(nfam) savefirst
	est restore _ivreg2_cOut
	outreg2 using "${dirresu}\Table7_B", keep(syntheticT) tex ctitle("M common") label dec(3) noaster nocons nor2 stats(coef pval) bracket addtext(F-stat, `F1', cluster, family)

		
* Col [2]: Any brother is MP after marriage

global polit d_MPb_aft
global polbefore d_MPf_bef
* CLR p-values
qui ivregress liml rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first
	qui weakiv, null(0) small
	local CLR1 = round(e(clr_p), 0.001)
* CLR p-values clustered by family
qui ivregress liml rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first vce(cluster nfam)
	local Nbobs = `e(N)'	// just so that N appears after CLR p-values in table
	qui weakiv, null(0) small
	local CLR2 = round(e(clr_p), 0.001)
* Second-stage coefficients
qui ivregress liml rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first
	outreg2 using "${dirresu}\Table7_A", keep($polit) stats(coef) nocons label noobs dec(2) noas ///
	ctitle("tax rate") addtext(CLR-pval, `CLR1', CLR-pval 2, `CLR2', Nb observations, `Nbobs') tex
* First stage coefs in Panel B
qui reg $polit syntheticT biorder $hechter $controlsb $polbefore
	local F1 = round(e(F),0.01)
qui ivreg2 rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first savefirst
	est restore _ivreg2_d_MPb_aft
	outreg2 using "${dirresu}\Table7_B", keep(syntheticT) tex ctitle("MP (b)") label dec(3) noaster nocons nor2 stats(coef pval) addtext(F-stat, `F1', cluster, .)
qui ivreg2 rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first cluster(nfam) savefirst
	est restore _ivreg2_d_MPb_aft
	outreg2 using "${dirresu}\Table7_B", keep(syntheticT) tex ctitle("MP (b)") label dec(3) noaster nocons nor2 stats(coef pval) bracket addtext(F-stat, `F1', cluster, family)

	
* Col [3]: Years brother is MP after marriage

global polit MPb_years_aft
global polbefore MPf_years_bef
* CLR p-values
qui ivregress liml rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first
	qui weakiv, null(0) small
	local CLR1 = round(e(clr_p), 0.001)
* CLR p-values clustered by family
qui ivregress liml rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first vce(cluster nfam)
	local Nbobs = `e(N)'	// just so that N appears after CLR p-values in table
	qui weakiv, null(0) small
	local CLR2 = round(e(clr_p), 0.001)
* Second-stage coefficients
qui ivregress liml rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first
	outreg2 using "${dirresu}\Table7_A", keep($polit) stats(coef) nocons label noobs dec(2) noas ///
	ctitle("tax rate") addtext(CLR-pval, `CLR1', CLR-pval 2, `CLR2', Nb observations, `Nbobs') tex
* First stage coefs in Panel B
qui reg $polit syntheticT biorder $hechter $controlsb $polbefore
	local F1 = round(e(F),0.01)
qui ivreg2 rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first savefirst
	est restore _ivreg2_MPb_years_aft
	outreg2 using "${dirresu}\Table7_B", keep(syntheticT) tex ctitle("Years MP (b)") label dec(3) noaster nocons nor2 stats(coef pval) addtext(F-stat, `F1', cluster, .)
qui ivreg2 rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first cluster(nfam) savefirst
	est restore _ivreg2_MPb_years_aft
	outreg2 using "${dirresu}\Table7_B", keep(syntheticT) tex ctitle("Years MP (b)") label dec(3) noaster nocons nor2 stats(coef pval) bracket addtext(F-stat, `F1', cluster, family)


* Col [4]: Any brother is local MP after marriage

global polit d_MPb_locaft
global polbefore d_MPf_local
* CLR p-values
qui ivregress liml rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first
	qui weakiv, null(0) small
	local CLR1 = round(e(clr_p), 0.001)
* CLR p-values clustered by family
qui ivregress liml rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first vce(cluster nfam)
	local Nbobs = `e(N)'	// just so that N appears after CLR p-values in table
	qui weakiv, null(0) small
	local CLR2 = round(e(clr_p), 0.001)
* Second-stage coefficients
qui ivregress liml rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first
	outreg2 using "${dirresu}\Table7_A", keep($polit) stats(coef) nocons label noobs dec(2) noas ///
	ctitle("tax rate") addtext(CLR-pval, `CLR1', CLR-pval 2, `CLR2', Nb observations, `Nbobs') tex
* First stage coefs in Panel B
qui reg $polit syntheticT biorder $hechter $controlsb $polbefore
	local F1 = round(e(F),0.01)
qui ivreg2 rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first savefirst
	est restore _ivreg2_d_MPb_locaft
	outreg2 using "${dirresu}\Table7_B", keep(syntheticT) tex ctitle("local MP (b)") label dec(3) noaster nocons nor2 stats(coef pval) addtext(F-stat, `F1', cluster, .)
qui ivreg2 rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first cluster(nfam) savefirst
	est restore _ivreg2_d_MPb_locaft
	outreg2 using "${dirresu}\Table7_B", keep(syntheticT) tex ctitle("local MP (b)") label dec(3) noaster nocons nor2 stats(coef pval) bracket addtext(F-stat, `F1', cluster, family)


* Col [5]: Years brother is local MP after marriage

global polit MPb_years_locaft
global polbefore MPf_years_locbef
* CLR p-values
qui ivregress liml rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first
	qui weakiv, null(0) small
	local CLR1 = round(e(clr_p), 0.001)
* CLR p-values clustered by family
qui ivregress liml rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first vce(cluster nfam)
	local Nbobs = `e(N)'	// just so that N appears after CLR p-values in table
	qui weakiv, null(0) small
	local CLR2 = round(e(clr_p), 0.001)
* Second-stage coefficients
qui ivregress liml rateperpou ($polit = syntheticT biorder) $hechter $controlsb $polbefore , first

... [truncated: 4,257 more bytes of this script omitted] ...

```

### `programs/03_appendix/master-appendix.do`
```stata
/*******************************************************************************

This file contains the code to replicate the tables and figures in the appendix.

	Contents:
	0. Generate or import final dataset

	A. DATA APPENDIX
	Table A1: Summary statistics
	
	B. ROBUSTNESS
	
	C. IV ESTIMATION FOR MEN
	
	D. ADDITIONAL DESCRIPTIVE EVIDENCE
	
		
The file "3 Replication package\programs00_setup.do" installs the required ado 
packages sets. It also sets the path to all directories. If you want to run this 
do file individually, after installing the required packages unnmark and specify 
location of parent directory here:

	*global dirroot = "SPECIFY\LOCATION\OF\PARENT\DIRECTORY\HERE"

and then run the following lines for the secondary directories (specified as 
downloaded in replication package):

	global dirdata = "${dirroot}\data"
	global dirdta  = "${dirroot}\programs\01_dataprep\dta-temp-files"
	global dirresu = "${dirroot}\programs\results"

*******************************************************************************/


* Set-up:

	do "${dirroot}\programs\00_setup.do"

* ==============================================================================
* 0. GENERATE OR IMPORT FINAL DATASET:
* ------------------------------------------------------------------------------
clear all
set more off
set matsize 10000

* To generate the final dataset run the following line:

	do "${dirroot}\programs\01_dataprep\master-dataprep.do"

* Alternatively, you can import the final dataset data directly by writting
* use "${dirdata}\final-data.dta", clear

* ==============================================================================




********************************************************************************
********************************************************************************
********************************************************************************
*																			   *
*	 							A. DATA APPENDIX							   *
*																			   *
********************************************************************************
********************************************************************************
********************************************************************************

	

	
* ==============================================================================
* TABLE A1: 
* Summary statistics
* ------------------------------------------------------------------------------

* Import final dataset
use "${dirdata}\final-data.dta", clear
gen pr5 = (pr4!=1)
label var pr5 "Viscount's/baron's daughter"
global tosum cOut mheir fmissmatch fmissmatch2 fdown celibacy syntheticT mourn pr4 pr5 biorder hengpee hscotpee hiripee

* Summary stats (baseline)
preserve
foreach x in fmissmatch fmissmatch2 fdown celibacy{ 	// just so that variabels appear in the desired order
replace `x'=.
}
eststo sumbase: qui estpost summ $tosum if base_sample==1
estadd local obs = `e(N)'
restore

* Summary stats (married in landed elite)
preserve
replace celibacy = .
eststo sumlelite: qui estpost summ $tosum if base_sample==1 & fmissmatch!=.
estadd local obs = `e(N)'
restore

* Summary stats (including unmarried)
preserve
foreach x in cOut mheir fmissmatch fmissmatch2 fdown mourn{
replace `x'=.
}
eststo sumunmarr: qui estpost summ $tosum if marital_rates_sample==1
estadd local obs = `e(N)'
restore

* Output
esttab sumbase sumlelite sumunmarr using "${dirresu}\Appendix\TableA1.tex", ///
	mlabels("Baseline" "Land elite" "Inc unmarr") ///
	cells("mean(pattern(1 1 1) fmt(2)) sd(pattern(1 1 1) fmt(2))") ///
	stats(obs, labels("Observations") fmt(%9.0gc)) ///
	noobs label replace

	
	
* ==============================================================================
* TABLE A2: 
* Summary statistics, women with a family seat
* ------------------------------------------------------------------------------

* Import final dataset
use "${dirdata}\final-data.dta", clear
gen pr5 = (pr4!=1)
label var pr5 "Viscount's/baron's daughter"
global tosum cOut mheir fmissmatch fmissmatch2 fdown celibacy syntheticT mourn distlondon pr4 pr5 biorder hengpee hscotpee hiripee

* Sample: women with a family seat
keep if distlondon!=.

* Summary stats (baseline)
preserve
foreach x in fmissmatch fmissmatch2 fdown celibacy{ 	// just so that variabels appear in the desired order
replace `x'=.
}
eststo sumbase: qui estpost summ $tosum if base_sample==1
estadd local obs = `e(N)'
restore

* Summary stats (married in landed elite)
preserve
replace celibacy = .
eststo sumlelite: qui estpost summ $tosum if base_sample==1 & fmissmatch!=.
estadd local obs = `e(N)'
restore

* Summary stats (including unmarried)
preserve
foreach x in cOut mheir fmissmatch fmissmatch2 fdown mourn{
replace `x'=.
}
eststo sumunmarr: qui estpost summ $tosum if marital_rates_sample==1
estadd local obs = `e(N)'
restore

* Output
esttab sumbase sumlelite sumunmarr using "${dirresu}\Appendix\TableA2.tex", ///
	mlabels("Baseline" "Land elite" "Inc unmarr") ///
	cells("mean(pattern(1 1 1) fmt(2)) sd(pattern(1 1 1) fmt(2))") ///
	stats(obs, labels("Observations") fmt(%9.0gc)) ///
	noobs label replace

	
	
* ==============================================================================
* TABLE A3: 
* Summary statistics for marriage and political power
* ------------------------------------------------------------------------------

* Import data
use "${dirdata}/final-data-sec4.dta", clear
gen pr5 = (pr4!=1)
label var pr5 "Viscount's/baron's daughter"
global tosum d_MPb_aft MPb_years_aft d_MPb_locaft2 MPb_years_locaft d_MPh_aft MPh_years_aft ///
			 cOut syntheticT pr4 pr5 nsib biorder distlondon ///
			 d_MPf_bef MPf_years_bef d_MPf_local2  MPf_years_locbef d_MPh_bef MPh_years_bef

* Collapse data such that a woman (and her family) is the unit of observation
collapse $tosum, by(refno)
label var d_MPb_aft "Any brother is MP (after)"
label var MPb_years_aft "All brothers MP years (after)"
label var d_MPb_locaft2 "Any brother is local MP (after)"
label var MPb_years_locaft "All brothers' local MP years (after)"
label var d_MPh_aft "Family head is MP (after)"
label var MPh_years_aft "Family head's MP years (after)"
label var cOut "Married a commoner"
label var syntheticT "Treatment (synthetic prob)"
label var pr4 "Duke, marquis, earl's family"
label var pr5 "Viscount, baron's family"
label var nsib "Number of brothers"
label var biorder "Woman's birth order (excl. heirs)"
label var distlondon "Distance to London"
label var d_MPf_bef "Father is MP (before)"
label var MPf_years_bef "Father's MP years (before)"
label var d_MPf_local2 "Father is local MP (before)"
label var MPf_years_locbef "Father's local MP years (before)"
label var d_MPh_bef	"Family head is MP (before)"
label var MPh_years_bef "Family head's MP years (before)"

	/*  Note: the following measures of political power before marriage are used 
	only for regressions of brothers' political power.  */

foreach x in d_MPb_aft MPb_years_aft d_MPb_locaft2 MPb_years_locaft d_MPf_bef MPf_years_bef d_MPf_local2 MPf_years_locbef{ 
replace `x' = . if nsib==.
}

* Summary stats
eststo sumA3: qui estpost summ $tosum

* Summary stats for county controls (Hechter)
preserve
use "${dirdata}/final-data-sec4.dta", clear
collapse propman100 logincome propcon propnonc relig, by(countyN) // Collapse data such that a county is the unit of observation
gen propcon100 = propcon*100 // to have them as percentages (%)
gen propnonc100 = propnonc*100
label var propman100 "perc. working in manufacturing"
label var logincome "income pc (in logs)"
label var propcon100 "perc. voting conservative, 1885"
label var propnonc100 "perc. non-conformists"
label var relig "religiosity"

* Summary stats
eststo sumhech: qui estpost summ propman100 logincome propcon100 propnonc100 relig
restore

* Output
esttab sumA3 sumhech using "${dirresu}\Appendix\TableA3.tex", ///
	cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2)) count(fmt(0))") ///
	noobs label replace

	
	
* ==============================================================================
* TABLE A4: 
* MP elections, by type of constituency
* ------------------------------------------------------------------------------

* PANEL A: Distance from family seat to closest enfranchised constituency:

* import auxiliary appendix data with all dyads between constituencies' centroids
* and family seats in Section IV's sample. To consider enfranchized constituencies
* only, I exclude rotten boroughs.

import delimited "${dirroot}\programs\03_appendix\aux data appendix\seat_constituency_pairs_same_projection.txt", clear 

	/*  Note: For consistency, in this data file both seats and constituencies 
	are geolocated using the WGS84 projection.  */
	
* Calculate distance from seats to enfranchised constituencies
forvalues i=1/179{
geodist wgslat_sea wgslon_sea wgslat_cnt`i' wgslon_cnt`i', gen(dist`i') miles
}
egen dist_min = rowmin(dist1	dist2	dist3	dist4	dist5	dist6	dist7	dist8	dist9	dist10	dist11	dist12	dist13	dist14	dist15	dist16	dist17	dist18	dist19	dist20	dist21	dist22	dist23	dist24	dist25	dist26	dist27	dist28	dist29	dist30	dist31	dist32	dist33	dist34	dist35	dist36	dist37	dist38	dist39	dist40	dist41	dist42	dist43	dist44	dist45	dist46	dist47	dist48	dist49	dist50	dist51	dist52	dist53	dist54	dist55	dist56	dist57	dist58	dist59	dist60	dist61	dist62	dist63	dist64	dist65	dist66	dist67	dist68	dist69	dist70	dist71	dist72	dist73	dist74	dist75	dist76	dist77	dist78	dist79	dist80	dist81	dist82	dist83	dist84	dist85	dist86	dist87	dist88	dist89	dist90	dist91	dist92	dist93	dist94	dist95	dist96	dist97	dist98	dist99	dist100	dist101	dist102	dist103	dist104	dist105	dist106	dist107	dist108	dist109	dist110	dist111	dist112	dist113	dist114	dist115	dist116	dist117	dist118	dist119	dist120	dist121	dist122	dist123	dist124	dist125	dist126	dist127	dist128	dist129	dist130	dist131	dist132	dist133	dist134	dist135	dist136	dist137	dist138	dist139	dist140	dist141	dist142	dist143	dist144	dist145	dist146	dist147	dist148	dist149	dist150	dist151	dist152	dist153	dist154	dist155	dist156	dist157	dist158	dist159	dist160	dist161	dist162	dist163	dist164	dist165	dist166	dist167	dist168	dist169	dist170	dist171	dist172	dist173	dist174	dist175	dist176	dist177	dist178	dist179)
label var dist_min "Distance (in miles)"

* Summary stats
eststo sumdist: qui estpost summ dist_min
esttab sumdist using "${dirresu}\Appendix\TableA4_A.tex", ///
	cells("mean(fmt(2)) sd(fmt(2)) max(fmt(2))") ///
	noobs label replace
	


* PANEL B: MP elections, by type of constituency:

	/*  Note: first, reshape peers' biographies dataset to have one entry for 
	    each election (i.e., seat in parliament)  */

use "${dirdta}/Peers_biographies.dta", clear
sort refno
* 1. drop sisters
drop if refno==157408
encode fbio1, gen(nfam)
duplicates drop nfam, force
* 2. drop repeated biographies
foreach x in bio1 bio2{
rename f`x' `x'_0
rename h`x' `x'_11
replace `x'_11 = "" if fhead_1872!="other"
}
foreach x in 1 2 3 4 5 6 7 8 9 10{
rename b`x'bio1 bio1_`x'
rename b`x'bio2 bio2_`x'
}
qui sum MPf
local y = r(max)
if `y'>0{
	forvalues j = 1/`y'{
	gen term1_`j'_0 = term1f_`j'
	gen cnsty_`j'_0 = cnstyf_`j'
	gen cnstycounty_`j'_0 = cnstycountyf_`j' 
	gen cnstywgs_`j'_0 = cnstywgsf_`j' 
	}
}
*
qui sum MPh
local y = r(max)
if `y'>0{
	forvalues j = 1/`y'{
	gen term1_`j'_11 = term1h_`j'
	gen cnsty_`j'_11 = cnstyh_`j'
	gen cnstycounty_`j'_11 = cnstycountyh_`j' 
	gen cnstywgs_`j'_11 = cnstywgsh_`j' 
	}
}
*
foreach b in 1 2 3 4 5 6 7 8 9 10{
qui sum MPb`b'
local y = r(max)
if `y'>0{
	forvalues j = 1/`y'{
	gen term1_`j'_`b' = term1b`b'_`j'
	gen cnsty_`j'_`b' = cnstyb`b'_`j'
	gen cnstycounty_`j'_`b' = cnstycountyb`b'_`j' 
	gen cnstywgs_`j'_`b' = cnstywgsb`b'_`j' 
	}
}
}
drop firstnames surname title byear dyear myear wom mourn cOut cs fhead_1872 fhead_1878 relation_f relation_b1 heir_b1 note relation_b2 heir_b2 relation_b3 heir_b3 relation_b4 heir_b4 relation_b5 heir_b5 relation_b6 heir_b6 relation_b7 heir_b7 relation_b8 heir_b8 relation_b9 heir_b9 relation_b10 heir_b10 fh b1h b2h b3h b4h b5h b6h b7h b8h b9h b10h relation_b11 heir_b11 b11h byear_b01 byear_b1 byear_b02 byear_b2 byear_b03 byear_b3 byear_b04 byear_b4 byear_b05 byear_b5 byear_b06 byear_b6 byear_b07 byear_b7 byear_b08 byear_b8 byear_b09 byear_b9 byear_b010 byear_b10 myear_f_0 myear_f_alt myear_f myear_h_0 myear_h_alt myear_h myear_b1_0 myear_b1_alt myear_b1 myear_b2_0 myear_b2_alt myear_b2 myear_b3_0 myear_b3_alt myear_b3 myear_b4_0 myear_b4_alt myear_b4 myear_b5_0 myear_b5_alt myear_b5 myear_b6_0 myear_b6_alt myear_b6 myear_b7_0 myear_b7_alt myear_b7 myear_b8_0 myear_b8_alt myear_b8 myear_b9_0 myear_b9_alt myear_b9 myear_b10_0 myear_b10_alt myear_b10 d_MPf MP1fcount MP1fpos1 MP1fpos2 MP1fpos3 MP1fpos4 MP1fpos5 MPf d_MPh MP1hcount MP1hpos1 MP1hpos2 MP1hpos3 MP1hpos4 MPh d_MPb1 MP1b1count MP1b1pos1 MP1b1pos2 MP1b1pos3 MP1b1pos4 MP1b1pos5 MPb1 d_MPb2 MP1b2count MP1b2pos1 MP1b2pos2 MP1b2pos3 MP1b2pos4 MPb2 d_MPb3 MP1b3count MP1b3pos1 MP1b3pos2 MP1b3pos3 MP1b3pos4 MP1b3pos5 MP1b3pos6 MP1b3pos7 MP1b3pos8 MPb3 d_MPb4 MP1b4count MP1b4pos1 MP1b4pos2 MP1b4pos3 MPb4 d_MPb5 MP1b5count MP1b5pos1 MPb5 d_MPb6 MP1b6count MP1b6pos1 MPb6 d_MPb7 MP1b7count MP1b7pos1 MPb7 d_MPb8 MP1b8count MP1b8pos1 MPb8 d_MPb9 MP1b9count MPb9 d_MPb10 MP1b10count MPb10 MPb d_MPb libf toryf MPallf_1 partyf_1 cnstyf_1 term1f_1 term2f_1 MPallf_2 partyf_2 cnstyf_2 term1f_2 term2f_2 MPallf_3 partyf_3 cnstyf_3 term1f_3 term2f_3 MPallf_4 partyf_4 cnstyf_4 term1f_4 term2f_4 MPallf_5 partyf_5 cnstyf_5 term1f_5 term2f_5 libh toryh MPallh_1 partyh_1 cnstyh_1 term1h_1 term2h_1 MPallh_2 partyh_2 cnstyh_2 term1h_2 term2h_2 MPallh_3 partyh_3 cnstyh_3 term1h_3 term2h_3 MPallh_4 partyh_4 cnstyh_4 term1h_4 term2h_4 libb1 toryb1 MPallb1_1 partyb1_1 cnstyb1_1 term1b1_1 term2b1_1 MPallb1_2 partyb1_2 cnstyb1_2 term1b1_2 term2b1_2 MPallb1_3 partyb1_3 cnstyb1_3 term1b1_3 term2b1_3 MPallb1_4 partyb1_4 cnstyb1_4 term1b1_4 term2b1_4 MPallb1_5 partyb1_5 cnstyb1_5 term1b1_5 term2b1_5 libb2 toryb2 MPallb2_1 partyb2_1 cnstyb2_1 term1b2_1 term2b2_1 MPallb2_2 partyb2_2 cnstyb2_2 term1b2_2 term2b2_2 MPallb2_3 partyb2_3 cnstyb2_3 term1b2_3 term2b2_3 MPallb2_4 partyb2_4 cnstyb2_4 term1b2_4 term2b2_4 libb3 toryb3 MPallb3_1 partyb3_1 cnstyb3_1 term1b3_1 term2b3_1 MPallb3_2 partyb3_2 cnstyb3_2 term1b3_2 term2b3_2 MPallb3_3 partyb3_3 cnstyb3_3 term1b3_3 term2b3_3 MPallb3_4 partyb3_4 cnstyb3_4 term1b3_4 term2b3_4 MPallb3_5 partyb3_5 cnstyb3_5 term1b3_5 term2b3_5 MPallb3_6 partyb3_6 cnstyb3_6 term1b3_6 term2b3_6 MPallb3_7 partyb3_7 cnstyb3_7 term1b3_7 term2b3_7 MPallb3_8 partyb3_8 cnstyb3_8 term1b3_8 term2b3_8 libb4 toryb4 MPallb4_1 partyb4_1 cnstyb4_1 term1b4_1 term2b4_1 MPallb4_2 partyb4_2 cnstyb4_2 term1b4_2 term2b4_2 MPallb4_3 partyb4_3 cnstyb4_3 term1b4_3 term2b4_3 libb5 toryb5 MPallb5_1 partyb5_1 cnstyb5_1 term1b5_1 term2b5_1 libb6 toryb6 MPallb6_1 partyb6_1 cnstyb6_1 term1b6_1 term2b6_1 libb7 toryb7 MPallb7_1 partyb7_1 cnstyb7_1 term1b7_1 term2b7_1 libb8 toryb8 MPallb8_1 partyb8_1 cnstyb8_1 term1b8_1 term2b8_1 libb9 toryb9 libb10 toryb10 MPh_years MPh_years_aft d_MPh_bef d_MPh_aft MPf_years MPf_years_aft d_MPf_bef d_MPf_aft MPb1_years MPb1_years_aft d_MPb1_bef d_MPb1_aft MPb2_years MPb2_years_aft d_MPb2_bef d_MPb2_aft MPb3_years MPb3_years_aft d_MPb3_bef d_MPb3_aft MPb4_years MPb4_years_aft d_MPb4_bef d_MPb4_aft MPb5_years MPb5_years_aft d_MPb5_bef d_MPb5_aft MPb6_years MPb6_years_aft d_MPb6_bef d_MPb6_aft MPb7_years MPb7_years_aft d_MPb7_bef d_MPb7_aft MPb8_years MPb8_years_aft d_MPb8_bef d_MPb8_aft MPb9_years MPb9_years_aft d_MPb9_bef d_MPb9_aft MPb10_years MPb10_years_aft d_MPb10_bef d_MPb10_aft d_MPb_aft d_MPb_bef MPb_years MPb_years_aft cnstycountyh_1 cnstywgsh_1 cnstycountyh_2 cnstywgsh_2 cnstycountyh_3 cnstywgsh_3 cnstycountyh_4 cnstywgsh_4 cnstycountyf_1 cnstywgsf_1 cnstycountyf_2 cnstywgsf_2 cnstycountyf_3 cnstywgsf_3 cnstycountyf_4 cnstywgsf_4 cnstycountyf_5 cnstywgsf_5 cnstycountyb1_1 cnstywgsb1_1 cnstycountyb1_2 cnstywgsb1_2 cnstycountyb1_3 cnstywgsb1_3 cnstycountyb1_4 cnstywgsb1_4 cnstycountyb1_5 cnstywgsb1_5 cnstycountyb2_1 cnstywgsb2_1 cnstycountyb2_2 cnstywgsb2_2 cnstycountyb2_3 cnstywgsb2_3 cnstycountyb2_4 cnstywgsb2_4 cnstycountyb3_1 cnstywgsb3_1 cnstycountyb3_2 cnstywgsb3_2 cnstycountyb3_3 cnstywgsb3_3 cnstycountyb3_4 cnstywgsb3_4 cnstycountyb3_5 cnstywgsb3_5 cnstycountyb3_6 cnstywgsb3_6 cnstycountyb3_7 cnstywgsb3_7 cnstycountyb3_8 cnstywgsb3_8 cnstycountyb4_1 cnstywgsb4_1 cnstycountyb4_2 cnstywgsb4_2 cnstycountyb4_3 cnstywgsb4_3 cnstycountyb5_1 cnstywgsb5_1 cnstycountyb6_1 cnstywgsb6_1 cnstycountyb7_1 cnstywgsb7_1 cnstycountyb8_1 cnstywgsb8_1 fhead_1872_2 nfhead_1872 nsib nfam b11bio1 b11bio2
* reshape to have one entry per relative (i.e., fathers and borthers)
reshape long bio1_ bio2_ term1_1_ term1_2_ term1_3_ term1_4_ term1_5_ term1_6_ term1_7_ term1_8_ ///
						 cnsty_1_ cnsty_2_ cnsty_3_ cnsty_4_ cnsty_5_ cnsty_6_ cnsty_7_ cnsty_8_ ///
						 cnstycounty_1_ cnstycounty_2_ cnstycounty_3_ cnstycounty_4_ cnstycounty_5_ cnstycounty_6_ cnstycounty_7_ cnstycounty_8_ ///
						 cnstywgs_1_ cnstywgs_2_ cnstywgs_3_ cnstywgs_4_ cnstywgs_5_ cnstywgs_6_ cnstywgs_7_ cnstywgs_8_ ///
						 , i(refno) j(nrelative)
drop if bio1_=="" & bio2_==""
sort bio1_ bio2_ refno nrelative
by bio1_ bio2_: gen tokeep = _n
keep if tokeep==1
count // As before, I have 674 unique biographies
* 3. Reshape to have one election per entry
forvalues i=1/8{
rename term1_`i'_ term`i'
rename cnsty_`i'_ pc`i'
rename cnstycounty_`i'_ pccounty`i'
rename cnstywgs_`i'_ pcwgs`i'
}
gen idbio = _n
drop refno bio1_ bio2_ tokeep
reshape long term pc pccounty pcwgs, i(idbio) j(nelection)
sort idbio term nelection
keep if term!=.
rename pc cnsty
replace cnsty = "Egremont" if idbio==90
replace cnsty = "South Ayrshire" if idbio==587

* merge with constituency data (including type of constituency)
preserve 
import excel "${dirdata}\constituencies.xlsx", sheet("Sheet1") firstrow clear
keep cnsty note
label var cnsty "Electoral constituency"
label var note "Type of constituency"
save "${dirdta}\constituencies.dta", replace
restore
merge m:1 cnsty using "${dirdta}\constituencies.dta"
* housekeeping
replace note = "County constituency" if cnsty=="Ayrshire" | cnsty=="Caernarvonshire" | cnsty=="Hertfordshire" | cnsty=="Cumberland, Egremont Divisio"
replace note = "Rotten borough" if cnsty=="Newport Cornwall"
replace note = "Borough constituency" if cnsty=="Scarborough" | cnsty=="Brentwood" | cnsty=="Enfield"

* Panel B's sumary stats
capture log close				// save results in log file
cd "${dirresu}\Appendix"
log using TableA4_B.log, replace

*  All
tab note

*  Fathers
tab note if nrelative==0

*  Brothers
tab note if nrelative!=0

log close

	
	
* ==============================================================================
* TABLE A5: 
* Summary statistics for determinants of education provision
* ------------------------------------------------------------------------------

* Import data
use "${dirdata}/final-data-sec4.dta", clear
gen pr5 = (pr4!=1)
label var pr5 "Viscount's/baron's daughter"

* Add total funds raised from rates (pounds)
preserve 
import delimited "${dirroot}\programs\03_appendix\aux data appendix\funds_from_rates.txt", encoding(ISO-8859-2) clear 
label var refno "Reference number in Hollingsworth"
label var fid_b10sea "FID identifier for family seats of women in baseline sample (ArcGIS)"
label var rate_pound "Funds from rates (pound)"
save "${dirdta}/funds-from-rates.dta", replace
restore 
merge 1:1 refno fid_b10sea using "${dirdta}/funds-from-rates.dta", nogen
gen rate_log = log(rate_pound)

* Labels
label var rateperpou "Tax rate average"
label var rate_pound "Funds from rates (pound)"
label var numsb "Number of School Boards"
label var d_MPb_aft "Any brother is MP (after)"
label var MPb_years_aft "All brothers MP years (after)"
label var d_MPb_locaft "Any brother is local MP (after)"
label var MPb_years_locaft "All brothers' local MP years (after)"
label var d_MPh_aft "Family head is MP (after)"
label var MPh_years_aft "Family head's MP years (after)"
label var cOut "Married a commoner"
label var syntheticT "Treatment (synthetic prob)"
label var pr4 "Duke, marquis, earl's family"
label var pr5 "Viscount, baron's family"
label var nsib "Number of brothers"
label var biorder "Woman's birth order (excl. heirs)"
label var distlondon "Distance to London"
label var d_MPf_bef "Father is MP (before)"
label var MPf_years_bef "Father's MP years (before)"
label var d_MPf_local2 "Father is local MP (before)"
label var MPf_years_locbef "Father's local MP years (before)"
label var d_MPh_bef	"Family head is MP (before)"
label var MPh_years_bef "Family head's MP years (before)"

global tosum rateperpou rate_pound numsb ///
			 d_MPb_aft MPb_years_aft d_MPb_locaft MPb_years_locaft d_MPh_aft MPh_years_aft ///
			 cOut syntheticT pr4 pr5 nsib biorder distlondon  ///
			 d_MPf_bef MPf_years_bef d_MPf_local MPf_years_locbef d_MPh_bef MPh_years_bef

	/*  Note: the following measures of political power before marriage are used 
	only for regressions of brothers' political power.  */

foreach x in d_MPb_aft MPb_years_aft d_MPb_locaft MPb_years_locaft MPf_years_bef MPf_years_locbef d_MPf_bef d_MPf_local{
replace `x' = . if nsib==.
}

* Summary stats
eststo sumA5: qui estpost summ $tosum

* Output
esttab sumA5 using "${dirresu}\Appendix\TableA5.tex", ///
	cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2)) count(fmt(0))") ///
	noobs label replace

	
* ==============================================================================
* FIGURE A7: 
* MP elections overtime.
* ------------------------------------------------------------------------------

* Import data
use "${dirdta}/Peers_biographies.dta", clear

* Variables for time series figure
gen heir_f = 1
local i = 1
local rel = 1
foreach z in f b1 b2 b3 b4 b5 b6 b7 b8 b9 b10{
qui sum MP`z'
local y = r(max)
if `y'>0{
	forvalues j = 1/`y'{
	gen year0_`i' = term1`z'_`j'
	if `rel'<2{
	gen whoel_`i' = 0
	}
	if `rel'>1{
	gen whoel_`i' = .
	replace whoel_`i' = 1 if heir_`z'==1
	replace whoel_`i' = 2 if heir_`z'==0
	}
	local i = `i'+1
	}
}
local rel = `rel'+1
}
gen MPtot = MPb+MPf
keep refno fbio1 MPtot year0_1 whoel_1 year0_2 whoel_2 year0_3 whoel_3 year0_4 whoel_4 year0_5 whoel_5 year0_6 whoel_6 year0_7 whoel_7 year0_8 whoel_8 year0_9 whoel_9 year0_10 whoel_10 year0_11 whoel_11 year0_12 whoel_12 year0_13 whoel_13 year0_14 whoel_14 year0_15 whoel_15 year0_16 whoel_16 year0_17 whoel_17 year0_18 whoel_18 year0_19 whoel_19 year0_20 whoel_20 year0_21 whoel_21 year0_22 whoel_22 year0_23 whoel_23 year0_24 whoel_24 year0_25 whoel_25 year0_26 whoel_26 year0_27 whoel_27 year0_28 whoel_28 year0_29 whoel_29
bysort fbio1: gen sis = _n
keep if sis==1
reshape long year0_ whoel_, i(refno) j(j)
gen MPi = j
drop j
drop if year0_ == .
gen MPcount = 1
gen MPfcount = 1 if whoel_==0
gen MPhcount = 1 if whoel_==1
gen MPbcount = 1 if whoel_==2
collapse (sum) MPcount (sum) MPfcount (sum) MPhcount (sum) MPbcount, by(year0_)
tsset year0_
drop if year0_>=1889
tssmooth ma MPcount_ma = MPcount, window(2,1,2)
tssmooth ma MPfcount_ma = MPfcount, window(2,1,2)
tssmooth ma MPhcount_ma = MPhcount, window(2,1,2)
tssmooth ma MPbcount_ma = MPbcount, window(2,1,2)

* figure
twoway 	(scatter MPfcount year0_ if MPfcount>0 & year0_>1820 & year0_<1890, mcolor(black) ms(circle_hollow)) ///
		(scatter MPhcount year0_ if MPhcount>0 & year0_>1820 & year0_<1890, mcolor(black)) ///
		(scatter MPbcount year0_ if MPbcount>0 & year0_>1820 & year0_<1890, mcolor(black) ms(X)) ///
		(line MPcount_ma year0_ if MPcount_ma>0 & year0_>1820 & year0_<1890, lcolor(black)) ///
		(scatteri 0.5 1867 0.56 1867 , recast(line) lpattern(dash) lcolor(dkgreen)) ///
		(scatteri 0.5 1837 0.56 1837 , recast(line) lpattern(dot) lcolor(gray)), ///
		xlabel(1825(10)1885) xtitle("") ytitle("MP appointments") ylabel(0(5)20, nogrid) ///
		legend(on order(1 "Fathers" 2 "Brothers (heirs)" 3 "Brothers (non-heirs)" 4 "Moving avg.(2,2), total" 5 "Reform Act" 6 "General Election") rows(6) ring(0) position(1) bmargin(large)) ///
		xline(1832, lpattern(dash) lcolor(dkgreen)) xline(1867, lpattern(dash) lcolor(dkgreen)) ///
		xline(1884, lpattern(dash) lcolor(dkgreen))  ///
		xline(1826, lpattern(dot) lcolor(gray)) xline(1830, lpattern(dot) lcolor(gray)) ///		
		xline(1831, lpattern(dot) lcolor(gray)) xline(1832, lpattern(dot) lcolor(gray)) ///		
		xline(1835, lpattern(dot) lcolor(gray)) xline(1837, lpattern(dot) lcolor(gray)) ///		
		xline(1841, lpattern(dot) lcolor(gray)) xline(1847, lpattern(dot) lcolor(gray)) ///		
		xline(1852, lpattern(dot) lcolor(gray)) xline(1857, lpattern(dot) lcolor(gray)) ///		
		xline(1859, lpattern(dot) lcolor(gray)) xline(1865, lpattern(dot) lcolor(gray)) ///		
		xline(1868, lpattern(dot) lcolor(gray)) xline(1874, lpattern(dot) lcolor(gray)) ///		
		xline(1880, lpattern(dot) lcolor(gray)) xline(1885, lpattern(dot) lcolor(gray)) ///
		xline(1886, lpattern(dot) lcolor(gray)) graphregion(color(white))
graph export "${dirresu}\Appendix\FigureA7.pdf", as(pdf) replace



* ==============================================================================
* FIGURE A8: 
* Marriage and political power.
* ------------------------------------------------------------------------------

* Import data
use "${dirdata}/final-data-sec4.dta", clear


* Reshape data to have each brother as a separate data entry
local i = 1
foreach z in b1 b2 b3 b4 b5 b6 b7 b8 b9 b10{
qui sum MP`z'
local y = r(max)
if `y'>0{
	forvalues j = 1/`y'{
	gen year0_`i' = term1`z'_`j'-myear
	local i = `i'+1
	}
}
}
keep refno cOut myear MPb year0_1 year0_2 year0_3 year0_4 year0_5 year0_6 year0_7 year0_8 year0_9 year0_10 year0_11 year0_12 year0_13 year0_14 year0_15 year0_16 year0_17 year0_18 year0_19 year0_20 year0_21 year0_22 year0_23 year0_24 
duplicates drop
reshape long year0_ , i(refno) j(j)


* Indicators for MP elections, by years after sister's marriage
gen MPi = j
drop j
drop if year0_ == .
gen MPcount = 1
gen MPout = 1 if cOut==1
gen MPin  = 1 if cOut==0
gen year0_five = .
forvalues i = -40(10)40{
replace year0_five = `i' if year0_>=`i' & year0_<`i'+10
}
collapse (sum) MPcount (sum) MPout (sum) MPin, by(cOut year0_five)
drop if year0_five==-40


* Figure
twoway 	(connect MPcount year0_five if cOut==0 & year0_five<=20, lcolor(blue) ms(smdiamond) mc(blue)) 	///
		(connect MPcount year0_five if cOut==1 & year0_five<=20, lcolor(red) ms(smdiamond) mc(red) lw(thick)), 	///
		xtitle("years after sister's marriage") ytitle("Number of brothers elected MP") ///
		legend(on order(1 "sister married in the peerage" 2 "sister married a commoner")) ///
		xlabels(-30 "-30 to -20" -20 "-20 to -10" -10 "-10 to 0" 0 "0 to 10" 10 "10 to 20" 20 "20 to 30", angle(45)) ///
		graphregion(color(white)) xline(-10, lpattern(dash) lcolor(gray))
graph export "${dirresu}\Appendix\FigureA8.pdf", as(pdf) replace



********************************************************************************
********************************************************************************
********************************************************************************
*																			   *
*	 							B. ROBUSTNESS								   *
*																			   *
********************************************************************************
********************************************************************************
********************************************************************************

	
	
* ==============================================================================
* TABLE B1: 
* Synthetic probability based on alternative benchmark cohorts

* TABLE B2: 
* Synthetic probability based on alternative benchmark cohorts, controlling for distance to London.
* ------------------------------------------------------------------------------


* Compute alternative treatment using different benchmark cohorts

clear
set obs 21
gen mage = _n+14
gen freq = 0
label var mage "Age at marriage"
label var freq "Frequency (=0 as starting point of calculations)"
save "${dirdta}\agessyntheic.dta", replace
use "${dirdata}\final-data.dta", clear

foreach i in 1810 1815 1820 1835 1840 1845{

preserve
local j = `i'+15
local d b
if `i'>1820{
local d m
}
keep if wom==1 & nthismarriage<2 & `d'year<=`j' & `d'year>=`i' & dage>30
replace mage = myear-byear if nthismarr==1 & mage==.
drop if myear>=1861 & myear!=.
replace mage = 999 if nthismarr==0
replace nthismarr = 1 if nthismarr==0
collapse (sum) freq = nthismarr, by(mage)
sort mage
drop if mage==. 
replace freq = 0 if freq==.
merge 1:1 mage using "${dirdta}\agessyntheic.dta", nogen
egen tot = sum(freq)
sort mage	
gen prob = 100*freq/tot
drop if mage == 999
keep mage prob
sort mage
gen syntheticT_alt = prob+prob[_n+1]+prob[_n+2]
drop prob
rename mage age1861
sort age1861
keep if age1861>=15 & age1861<=35
label var syntheticT_alt "Alternative treatment based on `d' cohort (`i'-`j')"
label var age1861 "Age at the start of the 1861 Season"
save "${dirdta}\syntheticprob`i'_`j'_alt.dta", replace
restore
}


* Regressions

global controls pr4 biorder hengpee

local ite = 1

do "${dirauxp}\cgmreg.do"		// bootstrap-t procedure (Cameron, Gelbach and Miller, 2008)


foreach i in 1815 1810 1820 1845 1840 1835{

local panel : word `ite' of `c(ALPHA)'
local j = `i'+15
use "${dirdata}\final-data.dta", clear
merge m:1 age1861 using "${dirdta}\syntheticprob`i'_`j'_alt.dta"
label var syntheticT_alt "Alternative treatment"
label var _merge "Merge results for alternative treatment"
keep if _merge==3
keep if wom==1 & nthismarriage<2 & age1861>=15 & age1861<=35
save "${dirdta}\dataforregs.dta", replace
local q = 1

foreach x in "" distlondon{

use "${dirdta}\dataforregs.dta", clear
keep if nthismarr==1 & myear!=.
drop if prankspo==0 // no foreign spouses (+ drops saxe-coburg)
qui probit cOut syntheticT_alt $controls `x', cluster(byear)
	qui estat classification
	local pcp1 = round(r(P_corr),1)
	qui margins, dydx(*) post
	outreg2 using "${dirresu}\Appendix\TableB`q'_`panel'", keep(syntheticT_alt) nocons label dec(3) coefastr ctitle("M common") nor2 tex replace
qui probit mheir syntheticT_alt $controls `x', cluster(byear)
	qui estat classification
	local pcp1 = round(r(P_corr),1)
	qui margins, dydx(*) post
	outreg2 using "${dirresu}\Appendix\TableB`q'_`panel'", keep(syntheticT_alt) nocons label dec(3) coefastr ctitle("M heir") nor2 tex
qui reg fmissmatch syntheticT_alt $controls `x', cluster(byear)
	outreg2 using "${dirresu}\Appendix\TableB`q'_`panel'", keep(syntheticT_alt) nocons label dec(3) coefastr ctitle("Diff abs") nor2 tex
qui reg fmissmatch2 syntheticT_alt $controls `x', cluster(byear)
	outreg2 using "${dirresu}\Appendix\TableB`q'_`panel'", keep(syntheticT_alt) nocons label dec(3) coefastr ctitle("Diff h-w") nor2 tex
qui probit fdown syntheticT_alt $controls `x', cluster(byear)
	qui estat classification
	local pcp1 = round(r(P_corr),1)
	qui margins, dydx(*) post
	outreg2 using "${dirresu}\Appendix\TableB`q'_`panel'", keep(syntheticT_alt) nocons label dec(3) coefastr ctitle("M down") nor2 tex
use "${dirdta}\dataforregs.dta", clear
keep if dage>35 & dyear>byear+1 & prank>1
qui probit celibacy syntheticT_alt $controls `x', cluster(byear)
	qui estat classification
	local pcp1 = round(r(P_corr),1)
	qui margins, dydx(*) post
	outreg2 using "${dirresu}\Appendix\TableB`q'_`panel'", keep(syntheticT_alt) nocons label dec(3) coefastr ctitle("never M") nor2 tex title("T based on women from `i' to `j'")

* small cluster

	/* NOTE 1: IF THE REPLICATOR WISHES TO SKIP THE CALCULATION OF SMALL
	CLUSTERS (WHICH TAKES ABOUT 6H), TYPE "0" IN THE FOLLOWING LOCAL: */
	
local smallcluster = 1

if `smallcluster' == 1{

	/* NOTE 2: Results stored in log file in the following locations:
	3 Replication package\results\Appendix\...
		... TableB1_A_smallcluster.log; ... TableB1_B_smallcluster.log; 
		... TableB1_C_smallcluster.log; ... TableB1_D_smallcluster.log. 
		... TableB1_E_smallcluster.log; ... TableB1_F_smallcluster.log.
		
		... TableB2_A_smallcluster.log; ... TableB2_B_smallcluster.log; 
		... TableB2_C_smallcluster.log; ... TableB2_D_smallcluster.log.  
		... TableB2_E_smallcluster.log; ... TableB2_F_smallcluster.log.  
	See also Table 2 for small cluster p-values for benchmark cohorts (panel A 
	in both tables B1 and B2)  */


use "${dirdta}\dataforregs.dta", clear
keep if nthismarr==1 & myear!=.
drop if prankspo==0 // no foreign spouses (+ drops saxe-coburg)
qui probit cOut syntheticT_alt $controls `x', cluster(byear)
local d born
if `i'>1820{
local d marr
}
keep if e(sample)==1

if `ite'>1{
    
capture log close				// save results in log file
cd "${dirresu}\Appendix"
log using TableB`q'_`panel'_smallcluster.log, replace

	display "=================================================================="
	display "Table B`q', panel `panel', col [1]: `d'. `i' to `j' (M common)"
	display "=================================================================="
	clustse probit cOut syntheticT_alt $controls `x', cluster(byear) method(pairs) reps(5000)
	display "=================================================================="
	display "Table B`q', panel `panel', col [2]:  `d'. `i' to `j' (M heir) "
	display "=================================================================="
	clustse probit mheir syntheticT_alt $controls `x', cluster(byear) method(pairs) reps(5000)
	display "=================================================================="
	display "Table B`q', panel `panel', col [3]:  `d'. `i' to `j' (Diff abs) "
	display "=================================================================="
	****
	qui reg fmissmatch syntheticT_alt $controls `x', cluster(byear)
	keep if e(sample)==1
	****
	cgmwildboot fmissmatch syntheticT_alt $controls `x', cluster(byear) bootcluster(byear) reps(5000)
	display "=================================================================="
	display "Table B`q', panel `panel', col [4]:  `d'. `i' to `j' (Diff h-w) "
	display "=================================================================="
	cgmwildboot fmissmatch2 syntheticT_alt $controls `x', cluster(byear) bootcluster(byear) reps(5000)
	display "=================================================================="
	display "Table B`q', panel `panel', col [5]:  `d'. `i' to `j' (M down)  "
	display "=================================================================="
	clustse probit fdown syntheticT_alt $controls `x', cluster(byear) method(pairs) reps(5000)
use "${dirdta}\dataforregs.dta", clear
keep if dage>35 & dyear>byear+1 & prank>1
qui probit celibacy syntheticT_alt $controls `x', cluster(byear)
keep if e(sample)==1
	display "=================================================================="
	display "Table B`q', panel `panel', col [6]:  `d'. `i' to `j' (never M)  "
	display "=================================================================="
	clustse probit celibacy syntheticT_alt $controls `x', cluster(byear) method(pairs) reps(5000)
log close
}
}
local q = `q'+1
}
local ite = `ite'+1
}

	/*	Table B1, Panel A and Table B2, Panel A small clusters' p-values are the 
	same as in Table 2 (both consider benchmark cohorts). Hence, the code is the
	same as before: */
	
if `smallcluster' == 1{
use "${dirdata}\final-data.dta", clear
gsort surname title -nthismarr 	// to get stable results
***do "${dirauxp}\cgmreg.do"		// if not run in setup
capture log close				// save results in log file
cd "${dirresu}\Appendix"
log using TableB1_A_smallcluster.log, replace
keep if wom==1 & nthismarriage<2 & age1861>=15 & age1861<=35	// sample
preserve
keep if nthismarr==1 & myear!=.	// married
qui probit cOut syntheticT $controls, cluster(byear)
keep if e(sample)==1	// keep sample of non-missing variables
clustse probit cOut syntheticT $controls, cluster(byear) method(pairs) reps(5000)
clustse probit mheir syntheticT $controls, cluster(byear) method(pairs) reps(5000)
cgmwildboot fmissmatch syntheticT $controls, cluster(byear) bootcluster(byear) reps(5000)
cgmwildboot fmissmatch2 syntheticT $controls, cluster(byear) bootcluster(byear) reps(5000)
clustse probit fdown syntheticT $controls, cluster(byear) method(pairs) reps(5000)
restore
keep if dage>35 & dyear>byear+1 & prank>1 // married and unmarried women
qui probit celibacy syntheticT $controls, cluster(byear)
keep if e(sample)==1	// keep sample of non-missing variables
clustse probit celibacy syntheticT $controls, cluster(byear) method(pairs) reps(5000)
log close
*
use "${dirdata}\final-data.dta", clear
gsort surname title -nthismarr 	// to get stable results
capture log close				// save results in log file
cd "${dirresu}\Appendix"
log using TableB2_A_smallcluster.log, replace
keep if wom==1 & nthismarriage<2 & age1861>=15 & age1861<=35	// sample
preserve
keep if nthismarr==1 & myear!=.	// married
qui probit cOut syntheticT $controls distlondon, cluster(byear)
keep if e(sample)==1	// keep sample of non-missing variables
clustse probit cOut syntheticT $controls distlondon, cluster(byear) method(pairs) reps(5000)
clustse probit mheir syntheticT $controls distlondon, cluster(byear) method(pairs) reps(5000)
cgmwildboot fmissmatch syntheticT $controls distlondon, cluster(byear) bootcluster(byear) reps(5000)
cgmwildboot fmissmatch2 syntheticT $controls distlondon, cluster(byear) bootcluster(byear) reps(5000)
clustse probit fdown syntheticT $controls distlondon, cluster(byear) method(pairs) reps(5000)
restore
keep if dage>35 & dyear>byear+1 & prank>1 // married and unmarried women
qui probit celibacy syntheticT $controls distlondon, cluster(byear)
keep if e(sample)==1	// keep sample of non-missing variables
clustse probit celibacy syntheticT $controls distlondon, cluster(byear) method(pairs) reps(5000)
log close
}


* Erase temporary dta files
erase "${dirdta}\agessyntheic.dta"
erase "${dirdta}\dataforregs.dta"
erase "${dirdta}\syntheticprob1810_1825_alt.dta"
erase "${dirdta}\syntheticprob1815_1830_alt.dta"
erase "${dirdta}\syntheticprob1820_1835_alt.dta"
erase "${dirdta}\syntheticprob1835_1850_alt.dta"
erase "${dirdta}\syntheticprob1840_1855_alt.dta"
erase "${dirdta}\syntheticprob1845_1860_alt.dta"


	
	
* ==============================================================================
* TABLE B3: 
* Contingency tables, treatment based on marriage cohorts
* ------------------------------------------------------------------------------


* Import final data
use "${dirdata}\final-data.dta", clear

* Sample
keep if wom==1 & prank>1 & myear>=1858 & myear<=1863 & nthismarr==1 & mage<40

	/* Note: The sample is all peers' daughters marrying in 1858-63, excluding 
	second marriages and women married above 40.  */

* Contingency tables
label var grank "Wife"
capture log close				// save results in log file
cd "${dirresu}\Appendix"
log using TableB3.log, replace

*  Panel A: Control group (Season): peers' daughters marrying in 1858-60
tab grank grankspo if myear>=1858 & myear<=1860 & crankspo!=0 & nthismarr==1, expect

*  Panel B: Treatment group (Season): peers' daughters marrying in 1861-63
tab grank grankspo if myear>=1861 & myear<=1863 & crankspo!=0 & nthismarr==1, expect

log close

	
	
* ==============================================================================
* TABLE B4: 
* Sorting by title, non-parametric tests based on marriage cohorts.
* ------------------------------------------------------------------------------


* Import final data
use "${dirdata}\final-data.dta", clear

* Sample
keep if wom==1 & prank>1 & myear>=1858 & myear<=1863 & nthismarr==1 & mage<40

	/* Note: The sample is all peers' daughters marrying in 1858-63, excluding 
	second marriages and women married above 40.  */

* Add results to matrix tab5
mat define tabB4 = (.,.,.\.,.,.\.,.,.\.,.,.\.,.,.\.,.,.\.,.,.)

* Control group, m. in 1858-60
qui tab prank grankspo if myear>=1858 & myear<=1860, expect
	qui bootstrap r(taub), reps(1000): tab prank grankspo if mourn==0 & prank>1 & crankspo!=0, taub
	matrix taub0 = r(table)
	local taub = taub0[1,1]
	local taub_p = round(taub0[4,1],0.0001)
	qui tab prank grankspo if mourn==0 & prank>1 & crankspo!=0, chi2 lrchi2 taub nofreq

mat tabB4[1,1] = `r(chi2)'
mat tabB4[2,1] = `r(p)'
mat tabB4[3,1] = `r(chi2_lr)'
mat tabB4[4,1] = `r(p_lr)'
mat tabB4[5,1] = `taub'
mat tabB4[6,1] = `taub_p'
mat tabB4[7,1] = `r(N)'

* Treatment group, m. in 1861-63
qui tab prank grankspo if myear>=1861 & myear<=1863, expect
	qui bootstrap r(taub), reps(1000): tab prank grankspo if mourn==1 & prank>1 & crankspo!=0, taub
	matrix taub0 = r(table)
	local taub = taub0[1,1]
	local taub_p = round(taub0[4,1],0.0001)
	qui tab prank grankspo if mourn==1 & prank>1 & crankspo!=0, chi2 lrchi2 taub nofreq

mat tabB4[1,2] = `r(chi2)'
mat tabB4[2,2] = `r(p)'
mat tabB4[3,2] = `r(chi2_lr)'
mat tabB4[4,2] = `r(p_lr)'
mat tabB4[5,2] = `taub'
mat tabB4[6,2] = `taub_p'
mat tabB4[7,2] = `r(N)'

* Difference

mat tabB4[1,3] = tabB4[1,1]-tabB4[1,2]
mat tabB4[3,3] = tabB4[3,1]-tabB4[3,2]
mat tabB4[5,3] = tabB4[5,1]-tabB4[5,2]
mat tabB4[7,3] = tabB4[7,1]+tabB4[7,2]

	forvalues i=0/1{
	qui tab prank grankspo if mourn==`i' & prank>1 & crankspo!=0, all
	local conv_chi`i' = sqrt(r(chi2)/e(N))
	local conv_lrc`i' = sqrt(r(chi2_lr)/e(N))
	}
	forvalues i=0/1{
	qui bootstrap r(taub), reps(500000): tab prank grankspo if mourn==`i' & prank>1 & crankspo!=0, taub
	mat b`i' = e(b)
	local taub`i' = b`i'[1,1]
	local conv`i' = sin(3.141592654*`taub`i''*0.5)
	}
	* difference: pearson chi2
	cortesti `conv_chi0' 95 `conv_chi1' 87
	mat tabB4[2,3] = 0.0577
	* difference: likelihood chi2
	cortesti `conv_lrc0' 95 `conv_lrc1' 87
	mat tabB4[4,3] = 0.0459
	* difference: taub
	cortesti `conv0' 95 `conv1' 87
	mat tabB4[6,3] = 0.0017


* Table B4
mat colnames tabB4 = "Control" "Treat" "Diff"
mat rownames tabB4 = "Pearson chi-squared" "  p-val" "Likelihood ratio" "  p-val" "Kendall rank correlation" "  p-val" "N"
mat list tabB4
esttab matrix(tabB4, fmt(3 3)) using "${dirresu}\Appendix\TableB4.tex", mlabel("Table B4") replace


	
* ==============================================================================
* FIGURE B1: 
* Sorting by landholdings, K-S tests based on marriage cohorts
* ------------------------------------------------------------------------------


* Import final data
use "${dirdata}\final-data.dta", clear

* Sample
keep if myear>=1858 & myear<=1866 & prank>1 & mage<40 & fatotal!=. & sfatotal!=.

	/* Note: The sample is all peers' daughters marrying in 1858-63, excluding 
	second marriages and women married above 40.  */

* Re-calculate percentiles in new sample
drop sfATot fATot
xtile sfATot = sfatotal, nq(100)
xtile fATot  = fatotal, nq(100)
gen fmissmatchA  = abs(fATot-sfATot)
gen fmissmatchA2 = sfATot-fATot

* Treatment and control groups
gen prepost = 2 	if myear>=1861 & myear<=1863
replace prepost = 1 if myear<1861
keep if prepost!=.

* PANEL A (ABSOLUTE VALUE)
preserve
* cumulative plot
sort fmissmatchA prepost
qui ksmirnov fmissmatchA, by(prepost) exact
local KS1`x' = round(`r(D)',0.1)
local pval1`x' = round(`r(p_exact)',0.01)
cumul fmissmatchA if prepost==1, gen(cum1)
cumul fmissmatchA if prepost==2, gen(cum2)
twoway 	(line cum1 fmissmatchA, c(J) lpattern(solid) lcolor(blue) lwidth(thin)) ///
		(line cum2 fmissmatchA, c(J) lpattern(solid) lcolor(red) lwidth(thick)), ///
		xtitle("|wife's percentile rank of acres - husband's percentile rank of acres|", size(med))	///
		ytitle("cumulative", size(med))	///
		legend(on order(1 "Control (Season)" 2 "Treatment (no Season)") rows(2) ring(0) position(5) bmargin(large) region(lstyle(none))) ///
		graphregion(color(white)) ///
		note("KS = `KS1' (`pval1')") name(A, replace)
restore

* PANEL B (DIFFERENCE)
preserve
* cumulative plot
sort fmissmatchA2 prepost
qui ksmirnov fmissmatchA2, by(prepost) exact
local KS2`x' = round(`r(D)',0.01)
local pval2`x' = round(`r(p_exact)',0.01)
cumul fmissmatchA2 if prepost==1, gen(cum1)
cumul fmissmatchA2 if prepost==2, gen(cum2)
twoway 	(line cum1 fmissmatchA2, c(J) lpattern(solid) lcolor(blue) lwidth(thin)) ///
		(line cum2 fmissmatchA2, c(J) lpattern(solid) lcolor(red) lwidth(thick)) ///
		(pcarrowi 0.95 -40 0.95 -60 "Marrying down", color(black)), ///
		xtitle("|wife's percentile rank of acres - husband's percentile rank of acres|", size(med))	///
		xline(0, lcolor(black) lwidth(thick)) ytitle("cumulative", size(med))	///
		legend(on order(1 "Control (Season)" 2 "Treat (no Season)") rows(2) ring(0) position(5) bmargin(large) region(lstyle(none))) ///
		graphregion(color(white)) ///
		note("KS = `KS2' (`pval2')") name(B, replace)
restore

* COMBINE
graph combine A B, graphregion(color(white)) rows(2) altshrink
graph export "${dirresu}\Appendix\FigureB1.pdf", as(pdf) replace
graph drop _all


	
* ==============================================================================
* TABLE B5: 
* Contingency tables separating wives' titles
* ------------------------------------------------------------------------------


* Import data and keep baseline sample
use "${dirdata}\final-data.dta", clear
keep if base_sample==1


* Treatment indicator for non-parametric analysis
_pctile syntheticT, nq(100)
gen treatment = (syntheticT > r(r80))

	/* Note: For the non-parametric estimation, I compare a high- vs. a low-treatment
	cohort. The high-treatment cohort are women with a synthetic probability to
	marry during the interruption above 20 percent. This corresponds to the top
	quintile; the 20% of women with the highest synthetic probability to marry in
	1861-63. Conversely, the low-treatment cohort are women below the top quintile. */


* Contingency tables
label var ownrank "Wife"
capture log close				// save results in log file
cd "${dirresu}\Appendix"
log using TableB5.log, replace

*  Panel A: Low-Treatment cohorts (T < 80th percentile)
tab ownrank grankspo if treatment==0, expected matcell(ofreqa)

*  Panel B: High-Treatment cohorts (T >= 80th percentile)
tab ownrank grankspo if treatment==1, expected matcell(ofreqa)
log close


	
* ==============================================================================
* TABLE B6: 
* Non-parametric tests for contingency Table B.V
* ------------------------------------------------------------------------------


* Import data and keep baseline sample
use "${dirdata}\final-data.dta", clear
keep if base_sample==1


* Treatment indicator for non-parametric analysis
_pctile syntheticT, nq(100)
gen treatment = (syntheticT > r(r80))

* Non-parametric stats
forvalues i=0/1{
tab ownrank grankspo if treatment==`i', chi2 lrchi2
local chi2_`i' = round(`r(chi2)',0.01)
local chi2LR_`i' = round(`r(chi2_lr)',0.01)
local chi2p_`i' = r(p)
local chi2LRp_`i' = r(p_lr)
local df_`i' = e(df_r)
local N`i' = r(N)
ktau ownrank grankspo if treatment==`i', stats(taub)
local taub_`i' = round(`r(tau_b)',0.01)
local taubp_`i' = r(p)
}


* Add results to matrix tab5
mat define tabB6 = (.,.,.\.,.,.\.,.,.\.,.,.\.,.,.\.,.,.\.,.,.)
forvalues j =0/1{
local col = `j'+1
mat tabB6[1,`col'] = `chi2_`j''
mat tabB6[2,`col'] = `chi2p_`j''
mat tabB6[3,`col'] = `chi2LR_`j''
mat tabB6[4,`col'] = `chi2LRp_`j''
mat tabB6[5,`col'] = `taub_`j''
mat tabB6[6,`col'] = `taubp_`j''
mat tabB6[7,`col'] = `N`j''
}
mat tabB6[5,3] = `taub_0'-`taub_1'
mat tabB6[7,3] = `N0'+`N1'


* Difference chi-squared and LR-chi2
local chi2_diff = `chi2_0'-`chi2_1'
local chi2_diffp = chi2tail(3,`chi2_diff')
local chi2LR_diff = `chi2LR_0'-`chi2LR_1'
local chi2LR_diffp = chi2tail(3,`chi2LR_diff')
mat tabB6[1,3] = `chi2_diff'
mat tabB6[2,3] = `chi2_diffp'
mat tabB6[3,3] = `chi2LR_diff'
mat tabB6[4,3] = `chi2LR_diffp'


* Difference tau-b
qui ktau ownrank grankspo if treatment==0
local convtaub_0 = sin(3.141592654*`r(tau_b)'*0.5)
qui ktau ownrank grankspo if treatment==1
local convtaub_1 = sin(3.141592654*`r(tau_b)'*0.5)
cortesti `convtaub_0' `N0' `convtaub_1' `N1'
mat tabB6[6,3] = 0.1047


* Table B6
mat colnames tabB6 = "Low-treat" "High-treat" "Diff"
mat rownames tabB6 = "Pearson chi-squared" "  p-val" "Likelihood ratio" "  p-val" "Kendall rank correlation" "  p-val" "N"
mat list tabB6
esttab matrix(tabB6, fmt(3 3)) using "${dirresu}\Appendix\TableB6.tex", mlabel("Table B6") replace


	
* ==============================================================================
* TABLE B7: 
* Alternative contingency tables
* ------------------------------------------------------------------------------


* DATA PREPARATION
* ----------------
* Append (i) men and women who did not marry and (ii) men who failed to marry 
* peers' daughters for the non-parametric analysis of appendix BIV.


* Sample 1: All women (married and unmarried)

* Import data:
use "${dirdata}\final-data.dta", clear
_pctile syntheticT, nq(100)		
gen treatment = (syntheticT > r(r80)) 	// treatment variable for non-parametric analysis
* Sample:
keep if wom==1 & nthismarriage<2 & age1861>=15 & age1861<=35
drop if nthismarr==0 & dage<35
drop if prankspo==0
* Relabel marriage outcomes (to incorporate unmarried + spouse's rank at age 15):
gen rank_hus = 0 if nthismarr==0 | myear==.
replace rank_hus = grankspo if rank_hus==.
label define marroutcome_label 0 "Unmarried" 1 "Commoner" 2 "Gentry" 3 "Peer son" 4 "Peer heir"
label values rank_hus marroutcome_label
keep grank rank_hus treatment
rename grank rank_wif
gen married = (rank_hus==0)
gen sample = 1
* Save:
label var rank_hus "Unmarried / Husband's rank at age 15"
label var treatment "Treatment: =0 if low (T<80 pctile); =1 if high (T>80 pctile)"
label var married "Ever married (=0 no; =1 yes)"
label var sample "Sample (=1 women; =2 men)"
save "${dirdta}\sampleCT_allwomen.dta", replace


* Sample 2: All married men (incl. those who did not marry peers' daughters')

	/*  Note: For all women in the baseline sample, I searched the entry (refno) 
	their corresponding husbands in the hollingsworth dataset. I added husbands 
	whose wives wer not peers' daughters but who were also aged 15 to 35 in 1861.
	The information is stored in the data file:
	"${dirroot}\programs\03_appendix\aux data appendix\husbands_contingency_table.txt"	
	*/

* Import data and append to baseline sample of women
preserve
import delimited "${dirroot}\programs\03_appendix\aux data appendix\husbands_contingency_table.txt", clear
label var refno_hus "Reference number in Hollingsworth (Husbands)"
label var grank "Wife's parental rank"
	label define prankspo2_lbl2 1 "Commoner dau." 2 "Gentry dau." 4 "Baron dau." 5 "Duke dau.", replace
	label values grank prankspo2_lbl2
label var agewife1861 "Wife's age at the start of the 1861 Season"
label var grankspo "Peer son / Peer heir"
	label define grankspohusb_lbl 3 "Peer son" 4 "Peer heir"
	label values grankspo grankspohusb_lbl
label var prank_husb "Husband's parental rank"
label var rank_husb "Husband's highest title succeeded to/was heir to at 15/was created for"
	label define rnk 0 "Foreign" 1 "Commoner" 2 "Knight" 3 "Baronet" 4 "Baron" 5 "Duke"
	label values prank_husb rank_husb rnk
label var crank_husb "Husband's highest rank heir to at 15"
	label define crnk 0 "Foreign" 1 "Pure commoner" 2 "Baron younger son" 3 "Duke younger son" 4 "Knight" 5 "Baronet" 6 "Baron" 7 "Duke" // labels
	label values crank_husb crnk
label var hrank_husb "Husband's highest rank heir to at 15 (alt. categories)"
	label define hnk 0 "Foreign" 1 "Commoner at 15" 2 "Knight" 3 "Baronet" 4 "Baron" 5 "Duke"
	label values hrank_husb hnk
save "${dirdta}\husbands_contingency_table.dta", replace
restore
use "${dirdata}\final-data.dta", clear
keep if base_sample==1
gen agewife1861 = age1861
append using "${dirdta}\husbands_contingency_table.dta"
* Re-label and treatment for men
label define prankspo2_lbl2 1 "Commoner dau." 2 "Gentry dau." 4 "Baron dau." 5 "Duke dau.", replace
label values grank prankspo2_lbl2
gen treatment_m = 1 if agewife1861>=19 & agewife1861<=22
replace treatment_m = 0 if agewife1861<19 | agewife1861>22
keep if grankspo>=3
rename grank marroutcome
gen agemen1861 = floor((td(31mar1861)-sbdate)/365)
replace agemen1861 = 1861-sbyear if agemen1861==.
* Save and erase temp files
label var agewife1861 "Wife's age at the start of the 1861 Season"
label var treatment_m "Treatment for men (=0 low; =1 high)"
label var agemen1861 "Men's age at the start of the 1861 Season"
save "${dirdta}\sample_CT_marriedmen.dta", replace
erase "${dirdta}\husbands_contingency_table.dta"

* Sample 3: Unmarried men

* Import data and select unmarried men aged 15-35 in 1861:
use "${dirdata}\final-data.dta", clear
keep if wom==0 & nthismarr==0
gen agemen1861 = floor((td(31mar1861)-bdate)/365)
replace agemen1861 = 1861-byear if agemen1861==.
keep if agemen1861>=15 & agemen1861<=35
replace dage = dyear-byear if dage==.
keep if dage>=35 // for consistency with women's sample
* Re-label marriage outcomes:
gen marroutcome = 0
drop grankspo
gen grankspo = 3 if crank==2 | crank==3 	// husband
replace grankspo = 4 if crank==6 | crank==7	
drop if prank==1
* Save:
label var agemen1861 "Men's age at the start of the 1861 Season"
label var marroutcome "Marriage outcome (0=unmarried)"
label var grankspo "Peer son / Peer heir"
	label define grankspohusb_lbl 3 "Peer son" 4 "Peer heir"
	label values grankspo grankspohusb_lbl
save "${dirdta}\sample_CT_unmarriedmen.dta", replace


* Append all samples

* Married and unmarried men
use "${dirdta}\sample_CT_marriedmen.dta", clear
append using "${dirdta}\sample_CT_unmarriedmen.dta"
* Re-label and treatment for men
label define marrout_men_label 0 "Unmarried" 1 "Commoner dau." 2 "Gentry dau." 4 "Baron dau." 5 "Duke dau.", replace
label values marroutcome marrout_men_label
label var marroutcome "Marriage outcome"
replace treatment_m = 1 if agemen1861>=19 & agemen1861<=22 & nthismarr==0
replace treatment_m = 0 if (agemen1861<19 & nthismarr==0) | (agemen1861>22 & nthismarr==0)
keep grankspo marroutcome treatment_m
rename grankspo rank_hus
rename marroutcome rank_wif
rename treatment_m treatment
gen married = (rank_wif==0)
gen sample = 2
drop if rank_wif==4 | rank_wif==5
* Append women, married and unmarried men
append using "${dirdta}\sampleCT_allwomen.dta"
replace rank_wif = rank_wif-1 if rank_wif>=4
label define wom_lbl 0 "No wife" 1 "Commoner dau." 2 "Gentry dau." 3 "Baron dau." 4 "Duke dau."
label values rank_wif wom_lbl
label define men_lbl 0 "No husb." 1 "Commoner" 2 "Gentry" 3 "Peer son" 4 "Peer heir"
label values rank_hus men_lbl
* Save and erase temp files
label var treatment "Treatment (0=low; 1=high)"
label var married "Ever married (0= no; 1= yes)"
label var sample "Sample (=1 women; =2 men)"
save "${dirdta}\sampleCT_allwomen-men.dta", replace
erase "${dirdta}\sample_CT_marriedmen.dta"
erase "${dirdta}\sample_CT_unmarriedmen.dta"
erase "${dirdta}\sampleCT_allwomen.dta"


* CONTINGENCY TABLES
* ------------------

* Import data
use "${dirdta}\sampleCT_allwomen-men.dta", clear


* Contingency table
forvalues T=0/1{
tab rank_wif rank_hus if treatment==`T', matcell(ofreq)

* Re-arrange cells for beautification
local ite = `T'+1 
local panel : word `ite' of `c(ALPHA)'
mat define tabB7_`panel' = (.,.,.,.,.,.\.,.,.,.,.,.\.,.,.,.,.,.\.,.,.,.,.,.\.,.,.,.,.,.\.,.,.,.,.,.)
mat list tabB7_`panel'
* Re-arrange marriages
forvalues i=1/4{
local i2 = `i'+1
mat tabB7_`panel'[`i',1] = ofreq[`i2',2]
mat tabB7_`panel'[`i',2] = ofreq[`i2',3]
mat tabB7_`panel'[`i',3] = ofreq[`i2',4]
mat tabB7_`panel'[`i',4] = ofreq[`i2',5]
}
* Re-arrange N/A values
mat tabB7_`panel'[1,1] = .
mat tabB7_`panel'[2,1] = .
mat tabB7_`panel'[1,2] = .
mat tabB7_`panel'[2,2] = .
* Re-arrange totals
mat tabB7_`panel'[5,1] = tabB7_`panel'[3,1]+tabB7_`panel'[4,1]
mat tabB7_`panel'[5,2] = tabB7_`panel'[3,2]+tabB7_`panel'[4,2]
mat tabB7_`panel'[5,3] = tabB7_`panel'[1,3]+tabB7_`panel'[2,3]+tabB7_`panel'[3,3]+tabB7_`panel'[4,3]
mat tabB7_`panel'[5,4] = tabB7_`panel'[1,4]+tabB7_`panel'[2,4]+tabB7_`panel'[3,4]+tabB7_`panel'[4,4]
mat tabB7_`panel'[1,5] = tabB7_`panel'[1,3]+tabB7_`panel'[1,4]
mat tabB7_`panel'[2,5] = tabB7_`panel'[2,3]+tabB7_`panel'[2,4]
mat tabB7_`panel'[3,5] = tabB7_`panel'[3,1]+tabB7_`panel'[3,2]+tabB7_`panel'[3,3]+tabB7_`panel'[3,4]
mat tabB7_`panel'[4,5] = tabB7_`panel'[4,1]+tabB7_`panel'[4,2]+tabB7_`panel'[4,3]+tabB7_`panel'[4,4]
mat tabB7_`panel'[5,5] = tabB7_`panel'[5,1]+tabB7_`panel'[5,2]+tabB7_`panel'[5,3]+tabB7_`panel'[5,4]
* Re-arrange totals including unmarried
mat tabB7_`panel'[6,1] = tabB7_`panel'[5,1]+ofreq[1,2]
mat tabB7_`panel'[6,2] = tabB7_`panel'[5,2]+ofreq[1,3]
mat tabB7_`panel'[6,3] = tabB7_`panel'[5,3]+ofreq[1,4]
mat tabB7_`panel'[6,4] = tabB7_`panel'[5,4]+ofreq[1,5]
mat tabB7_`panel'[6,5] = tabB7_`panel'[5,5]+ofreq[1,6]
mat tabB7_`panel'[1,6] = tabB7_`panel'[1,5]+ofreq[2,1]
mat tabB7_`panel'[2,6] = tabB7_`panel'[2,5]+ofreq[3,1]
mat tabB7_`panel'[3,6] = tabB7_`panel'[3,5]+ofreq[4,1]
mat tabB7_`panel'[4,6] = tabB7_`panel'[4,5]+ofreq[5,1]
mat tabB7_`panel'[5,6] = tabB7_`panel'[5,5]+ofreq[6,1]
mat tabB7_`panel'[6,6] = `r(N)'
* Row and column labels
mat colnames tabB7_`panel' = "Commoner" "Gentry" "Peer son" "Peer heir" "Total" "Total + unmarr"
mat rownames tabB7_`panel' = "Commoner dau" "Gentry dau" "Baron/Visc dau" "Duke/Earl/Mar dau" "Total" "Total + unmarr"
}


* Table B6
esttab matrix(tabB7_A, fmt(0)) using "${dirresu}\Appendix\TableB7_A.tex", mlabel("Table B7 (Panel A)") replace
esttab matrix(tabB7_B, fmt(0)) using "${dirresu}\Appendix\TableB7_B.tex", mlabel("Table B7 (Panel B)") replace


	
* ==============================================================================
* TABLE B8: 
* Non-parametric tests for contingency Table B7
* ------------------------------------------------------------------------------

* Import data
use "${dirdta}\sampleCT_allwomen-men.dta", clear


* Matrix to export results
mat define tabB8_ = (24.6,0.000,3.50,0.320,21.1,0.000\24.9,0.000,3.60,0.315,21.3,0.000\0.20,0.000,0.11,0.191,0.09,0.164\.,.,.,.,.,.\.,.,.,.,.,.\0.20,0.000,0.11,0.191,0.09,0.164\.,.,.,.,.,.\.,.,.,.,.,.\0.20,0.000,0.11,0.191,0.09,0.164\.,.,.,.,.,.\.,.,.,.,.,.\.,.,.,.,.,.\.,.,.,.,.,.\.,.,.,.,.,.\.,.,.,.,.,.)

	/* Note: Panel A's results equivalent to those reported in Table 5 in paper 
	and reproduced in the master-analysis.do do-file. Results on Kendall's tau-b 
	for Panels B and C also equivalent to those reported in Table 5 in paper 
	and reproduced in the master-analysis.do do-file. The reason is that: 
	``Kendall's rank correlation is based on the number of concordant, discordant, 
	and tied marriages [...] Hence, estimates are not affected whether unmarried 
	individuals are included or not'' (see appendix B4 for details). */


* Set globals
global rank_wif rank_wif
global rank_hus rank_hus


* Panel B
* ------------------------------------------------------------------------------
global nacells  1 	// (=0 for 4x4 tables; =1 if n/a cells)
global sampleM	0	// (=0 baseline; =1 baseline+peer son)
global sampleRM 1	// (=0 baseline; =1 baseline+peer son; =2 baseline+peer son+unmarried)

if $nacells == 0{
global wom 1
global sampleM 999
global sampleRM 999
}

if $sampleM == 0 & $sampleRM == 0{
keep if $rank_wif>2 & $rank_hus>0
}
if $sampleM == 0{
global wom 3
}
if $sampleM == 1{
global wom 1
}

forvalues x = 1(-1)0{
* observed cell counts 
forvalues i = 1/4{
forvalues j = 1/4{
count if treatment==`x' & $rank_wif==`i' & $rank_hus==`j'
local O`i'`j' = r(N)
}
}
* expected cell counts 
forvalues z = 1/4{
local c`z' = `O1`z''+`O2`z''+`O3`z''+`O4`z''
local r`z' = `O`z'1'+`O`z'2'+`O`z'3'+`O`z'4'
}
if $sampleRM == 2{							// to include unmarried
	if `x'==0{				
	local c3 = `c3' + 75
	local c4 = `c4' + 17
	local r3 = `r3' + 82
	local r4 = `r4' + 59
	}
	if `x'==1{
	local c3 = `c3' + 25
	local c4 = `c4' + 3
	local r3 = `r3' + 28
	local r4 = `r4' + 10
	}
}
local Nmen = `c1'+`c2'+`c3'+`c4'
forvalues i = 1/4{
forvalues j = 1/4{
local E`i'`j' = `r`i''*`c`j''/`Nmen'
}
}
if $nacells == 1{
	local E11 = 0
	local E12 = 0
	local E21 = 0
	local E22 = 0
}
* concordant and discordant pairs
forvalues j = 1/3{
local y = `j'+1
forvalues i = 1/3{
local C`i'`j' = 0
local z = `i'+1
forvalues i0=`z'/4{
forvalues j0=`y'/4{
local C`i'`j' = `C`i'`j''+`O`i'`j''*`O`i0'`j0''
}
}
}
}
forvalues j = 4(-1)2{
local y = `j'-1
forvalues i = 1/3{
local D`i'`j' = 0
local z = `i'+1
forvalues i0=`z'/4{
forvalues j0=1/`y'{
local D`i'`j' = `D`i'`j''+`O`i'`j''*`O`i0'`j0''
}    
}
}
}

... [truncated: 303,740 more bytes of this script omitted] ...

```

### `programs/00_setup.do`
```stata
/*******************************************************************************

This file sets the path to all directories and installs the ado packages 
required to replicate the results.

*******************************************************************************/


* ==============================================================================
* 1. DIRECTORIES
* ------------------------------------------------------------------------------

* Unmark and specify location of parent directory here:

*global dirroot = "SPECIFY\LOCATION\OF\PARENT\DIRECTORY\HERE"
global dirroot = "C:\Users\s14759\Dropbox\London Season\Replication package"

* Secondary directories as in downloaded replication package: 

global dirdata = "${dirroot}\data"
global dirdta  = "${dirroot}\programs\01_dataprep\dta-temp-files"
global dirresu = "${dirroot}\results"
global dirauxp = "${dirroot}\programs\04_auxiliary"


* ==============================================================================
* 2. INSTALL NEEDED ADO PACKAGES
* ------------------------------------------------------------------------------

clear all
* moss (http://fmwww.bc.edu/RePEc/bocode/m);
ssc install moss
* outreg2 (http://fmwww.bc.edu/RePEc/bocode/o);
ssc install outreg2
* ivreg2 (http://ideas.repec.org/c/boc/bocode/s425401.html);
ssc install ivreg2
* geodist (http://fmwww.bc.edu/RePEc/bocode/g)
ssc install geodist
* cmp (http://fmwww.bc.edu/RePEc/bocode/c);
ssc install cmp, replace
* distinct (http://fmwww.bc.edu/RePEc/bocode/d)
ssc install distinct
* weakiv (http://fmwww.bc.edu/repec/bocode/w)
ssc install weakiv
* coefplot (http://fmwww.bc.edu/RePEc/bocode/c)
ssc install coefplot, replace
* cortesti (http://fmwww.bc.edu/RePEc/bocode/c)
ssc install cortesti

* For small clusters
ssc install clustse
ssc install clusterbs
do "${dirauxp}\cgmreg.do" // bootstrap-t procedure (Cameron, Gelbach and Miller, 2008)

* Install grc1leg manually from http://www.stata.com/users/vwiggins

	* 1. Run the following line
	search grc1leg
	* 2. Click on: 	"grc1leg from http://www.stata.com/users/vwiggins"
	* 3. Click on: 	"(click here to install)"
```

### `programs/02_analysis/numbers-paper.do`
```stata
* Set-up:

	do "${dirroot}\programs\00_setup.do"


* ==============================================================================
* Footnote 26: "In this sample, 20 % of peers in the House of Lords had sons 
* seating in the House of Commons"
* ------------------------------------------------------------------------------

use "${dirdta}/Peers_biographies.dta", clear
* drop sisters
drop if refno==157408
encode fbio1, gen(nfam)
duplicates drop nfam, force
* father's date seated at Lords (i.e., earliest succession date to a peerage)
* succeded
gen succ = regexm(fbio2, "He succeeded")
gen succ_info = substr(fbio2,strpos(fbio2,"He succeeded"),.) if succ==1
forvalues i=1/7{
gen possent`i' = strpos(succ_info,".`i'") if succ_info!=""
replace possent`i' = . if possent`i'==0
}
egen possent = rowmin(possent1 possent2 possent3 possent4 possent5 possent6 possent7)
replace succ_info = substr(succ_info,1,possent) if succ==1
drop possent possent1 possent2 possent3 possent4 possent5 possent6 possent7
replace succ_info="He succeeded as the 4th Earl of Ailesbury, Buckinghamshire [G.B., 1776] on 6 January 1878." if refno==2952
replace succ_info="He succeeded as the 6th Baron Ashford, of Ashford, Kent [E., 1697] on 15 March 1851." if refno==4104
replace succ_info="He succeeded to the title of 3rd Lord Camoys [E., 1383] on 27 August 1839." if refno==42658
replace succ_info = substr(succ_info,1,strpos(succ_info,", in his father's lifetime")) if succ==1 & regexm(succ_info,"in his father's lifetime")==1
gen succ_year = substr(succ_info,length(succ_info)-5,.) if succ==1
replace succ_year = substr(succ_year,1,5) if succ==1
replace succ_year = "" if succ_year=="arony"
destring succ_year, replace
* created
gen crea = regexm(fbio2, "He was created")
gen crea_info = substr(fbio2,strpos(fbio2,"He was created"),.) if crea==1
forvalues i=1/7{
gen possent`i' = strpos(crea_info,".`i'") if crea_info!=""
replace possent`i' = . if possent`i'==0
}
egen possent = rowmin(possent1 possent2 possent3 possent4 possent5 possent6 possent7)
replace crea_info = substr(crea_info,1,possent) if crea==1
drop possent possent1 possent2 possent3 possent4 possent5 possent6 possent7
replace crea_info = substr(crea_info,1,strpos(crea_info,", with a special")) if crea==1 & regexm(crea_info,"with a special")==1
gen crea_year = substr(crea_info,length(crea_info)-5,.) if crea==1
replace crea_year = substr(crea_year,1,5) if crea==1
destring crea_year, replace
* gained
gen gain = regexm(fbio2, "He gained the title")
gen gain_info = substr(fbio2,strpos(fbio2,"He gained the title"),.) if gain==1
forvalues i=1/7{
gen possent`i' = strpos(gain_info,".`i'") if gain_info!=""
replace possent`i' = . if possent`i'==0
}
egen possent = rowmin(possent1 possent2 possent3 possent4 possent5 possent6 possent7)
replace gain_info = substr(gain_info,1,possent) if gain==1
drop possent possent1 possent2 possent3 possent4 possent5 possent6 possent7
gen gain_year = .
replace gain_year =	1825 if refno==	33554
replace gain_year =	1862 if refno==	228704
replace gain_year =	1814 if refno==	263157
* styled
gen styl = regexm(fbio2, "He was styled as")
gen styl_info = substr(fbio2,strpos(fbio2,"He was styled as"),.) if styl==1
forvalues i=1/7{
gen possent`i' = strpos(styl_info,".`i'") if styl_info!=""
replace possent`i' = . if possent`i'==0
}
egen possent = rowmin(possent1 possent2 possent3 possent4 possent5 possent6 possent7)
replace styl_info = substr(styl_info,1,possent) if styl==1
drop possent possent1 possent2 possent3 possent4 possent5 possent6 possent7
gen styl_year = substr(styl_info,strpos(styl_info,"between"),.) if styl==1
replace styl_year = substr(styl_year,9,.) if styl==1
replace styl_year = substr(styl_year,1,4) if styl==1
destring styl_year, replace
replace styl_year=1820 if refno==211953
* other
replace succ_year = 1851 if refno==241001
gen writ_year = 1852 if refno==237952
replace succ_year = 1831 if refno==210454
replace succ_year = 1855 if refno==248805
replace succ_year = 1833 if refno==108451
replace succ_year = 1844 if refno==229660
replace succ_year = 1833 if refno==264903
replace succ_year = 1835 if refno==253951
replace succ_year = 1836 if refno==232251
replace succ_year = 1841 if refno==265705
replace succ_year = 1846 if refno==266101
replace succ_year = 1838 if refno==225902
* Lord's
egen lord_year = rowmin(succ_year gain_year crea_year)
replace lord_year = styl_year if lord_year==.
* father's death date
gen fdyear = substr(fbio1,strpos(fbio1,"d."),.)
replace fdyear = substr(fdyear,1,strpos(fdyear,"Last")-1)
replace fdyear = substr(fdyear,length(fdyear)-4,.)
destring fdyear, replace
replace fdyear = 1855 if refno==225902
* rename bio and MP data
rename fbio1 bio1_0
rename fbio2 bio2_0
rename hbio1 bio1_11
rename hbio2 bio2_11
replace bio1_11 = "" if fhead_1872!="other"
replace bio2_11 = "" if fhead_1872!="other" 
foreach x in 1 2 3 4 5 6 7 8 9 10{
rename b`x'bio1 bio1_`x'
rename b`x'bio2 bio2_`x'
}
qui sum MPf
local y = r(max)
if `y'>0{
	forvalues j = 1/`y'{
	gen term1_`j'_0 = term1f_`j'
	gen term2_`j'_0 = term2f_`j'
	gen cnsty_`j'_0 = cnstyf_`j'
	}
}
rename MPf MP_0
*
foreach b in 1 2 3 4 5 6 7 8 9 10{
qui sum MPb`b'
local y = r(max)
if `y'>0{
	forvalues j = 1/`y'{
	gen term1_`j'_`b' = term1b`b'_`j'
	gen term2_`j'_`b' = term2b`b'_`j'
	gen cnsty_`j'_`b' = cnstyb`b'_`j'
	}
}
rename MPb`b' MP_`b'
}
* reshape to each fathers and brother as an entry
reshape long bio1_ bio2_ MP_ ///
		term1_1_ term1_2_ term1_3_ term1_4_ term1_5_ term1_6_ term1_7_ term1_8_ ///
		term2_1_ term2_2_ term2_3_ term2_4_ term2_5_ term2_6_ term2_7_ term2_8_ ///
		cnsty_1_ cnsty_2_ cnsty_3_ cnsty_4_ cnsty_5_ cnsty_6_ cnsty_7_ cnsty_8_ ///
		, i(refno) j(nrelative)
keep 	refno bio1_ bio2_ MP_ refno nrelative ///
		lord_year fdyear ///
		term1_1_ term1_2_ term1_3_ term1_4_ term1_5_ term1_6_ term1_7_ term1_8_ ///
		term2_1_ term2_2_ term2_3_ term2_4_ term2_5_ term2_6_ term2_7_ term2_8_ ///
		cnsty_1_ cnsty_2_ cnsty_3_ cnsty_4_ cnsty_5_ cnsty_6_ cnsty_7_ cnsty_8_
drop if nrelative==11
drop if bio1_=="" & bio2_=="" & nrelative>0
tab nrelative 	// # fathers (N=159)
				// # brothers (N=510)
* first and last year in Parliament
egen first_MP = rowmin(term1_1_ term1_2_ term1_3_ term1_4_ term1_5_ term1_6_ term1_7_ term1_8_)
egen last_MP  = rowmin(term2_1_ term2_2_ term2_3_ term2_4_ term2_5_ term2_6_ term2_7_ term2_8_)

* SON MP WHILE FATHER IS A LORD
gen sMPfLord = .
replace sMPfLord = 1 if first_MP <= lord_year
replace sMPfLord = 0 if fdyear < first_MP
replace sMPfLord = 1 if lord_year <= first_MP & fdyear <= last_MP
replace sMPfLord = 1 if lord_year <= first_MP & last_MP <= fdyear
replace sMPfLord = 1 if first_MP <= lord_year & last_MP <= fdyear
replace sMPfLord = 0 if last_MP < lord_year
replace sMPfLord = 0 if first_MP==.
replace sMPfLord = . if nrelative==0
tab sMPfLord 				// 19% of sons sat in HoC while father sat in Lords
gen MPind = (MP_>0)
tab MPind if nrelative>0	// 20% of sons sat in HoC


* ==============================================================================
* ``I handcollected 674 biographies'' (p. 13).
* ------------------------------------------------------------------------------
use "${dirdta}/Peers_biographies.dta", clear
* drop sisters
drop if refno==157408
encode fbio1, gen(nfam)
duplicates drop nfam, force
* # fathers (N=159)
count if fbio1!=""
* # brothers (N=510)
preserve
drop if b1bio1==""
keep refno b1bio1 b1bio2 b2bio1 b2bio2 b3bio1 b3bio2 b4bio1 b4bio2 b5bio1 b5bio2 b6bio1 b6bio2 b7bio1 b7bio2 b8bio1 b8bio2 b9bio1 b9bio2 b10bio1 b10bio2
foreach x in b1 b2 b3 b4 b5 b6 b7 b8 b9 b10{
rename `x'bio1 bio1_`x'
rename `x'bio2 bio2_`x'
}
reshape long bio1_b bio2_b, i(refno) j(nbrother)
drop if bio1_b=="" & bio2_b==""
summ
restore
* # family heads who are not fathers nor brothers (N=15)
tab fhead_1872
* # TOTAL (N=674)
rename fbio1 bio1_0
rename fbio2 bio2_0
rename hbio1 bio1_11
rename hbio2 bio2_11
replace bio1_11 = "" if fhead_1872!="other"
replace bio2_11 = "" if fhead_1872!="other" 
foreach x in 1 2 3 4 5 6 7 8 9 10{
rename b`x'bio1 bio1_`x'
rename b`x'bio2 bio2_`x'
}
reshape long bio1_ bio2_, i(refno) j(nrelative)
drop if bio1_=="" & bio2_==""
sort bio1_ bio2_ 
by bio1_ bio2_: gen tokeep = _n
keep if tokeep==1
count


* ==============================================================================
* `` in 1851-75, 50% of peers' daughters married within this 0.03% group 
* [the titled aristocracy in Britain] (p. 8)
* ------------------------------------------------------------------------------
use "${dirdata}\final-data.dta", clear
tab grankspo if wom==1 & myear>=1851 & myear<1875 & nthismarr==1 & prank>0
di 100*(104+67+197)/764 	// ca. 50 of peers' daughters married a titled husband
```

## How to run a script

Write each script to a file under the output directory, then run it with
exactly this command (the data directory is mounted read-only at its own
path; nothing else from the host is visible; `$SCRIPT` is the absolute path of
the script you wrote):

    SCRIPT=<repo>/benchmark/reproductions/goni-2022-assortative-matching-london-season/seeded/2026-11-10-b/script.R   # or <repo>/benchmark/reproductions/goni-2022-assortative-matching-london-season/seeded/2026-11-10-b/attempt-<n>/script.R
    uv run --directory <repo> python -m benchmark.reproducers.run_sandbox --timeout 300 --label retally.run=claude-code-goni-2022-assortative-matching-london-season-seeded-2026-11-10-b --run-dir "$(dirname "$SCRIPT")" -- docker run --rm --label retally.run=claude-code-goni-2022-assortative-matching-london-season-seeded-2026-11-10-b --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/seeded/2026-11-10-b/mount/goni_2022_assortative_matching_london_season:<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/seeded/2026-11-10-b/mount/goni_2022_assortative_matching_london_season:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R; echo "exit code: $?"

The sandbox time limit is 300 seconds (memory 4g, 1.0 CPU).  The
command enforces it: `run_sandbox` runs the `docker run` after `--`, writes
its output to `stdout.txt` and `stderr.txt` next to the script, and writes
`timing.json` there too (wall-clock seconds, and whether the limit was
hit).  If the limit is hit it kills the container, appends a line saying
so to `stderr.txt` and exits with code 124: treat the run as a crash.  Do
not add your own timeout, do not redirect its output yourself, and do not
delete `timing.json`; keep it with the run's other files.

If a `docker run` produces no output for more than ten minutes (no
container output, no error, the command does not return), the Docker
daemon is probably wedged.  Stop: kill the command, and do not restart
Docker Desktop or the Docker daemon yourself.  The hung attempt is not
counted: do not save it as an `attempt-<n>` directory or as the final run,
and say in `notes` that it hung.  Report it in your final message (which
step hung, and for how long) instead of retrying.

## Output contract

The output directory `<repo>/benchmark/reproductions/goni-2022-assortative-matching-london-season/seeded/2026-11-10-b` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/goni-2022-assortative-matching-london-season/seeded/2026-11-10-b/
  script.R  stdout.txt  stderr.txt  timing.json   # the FINAL run: its RESULT: lines are what is scored
  attempt-1/  attempt-2/  ...           # every execution BEFORE the final one, in order
    script.R  stdout.txt  stderr.txt  timing.json  feedback.txt   # feedback.txt when kind is not ""
  reproduction.json                     # written LAST
```

- `attempt-<n>` directories are every execution before the final one, in
  the order they ran; the final files at the top are the run whose
  `RESULT:` lines are scored.  If you go back to an earlier attempt, copy
  that attempt's files to the top level as the final run.
- `feedback.txt` holds what you acted on before the next attempt: the error
  you fixed (`kind: "error"`) or the `check_attempt` comparison
  (`kind: "claim"`).
- Exploratory runs (inspecting variables, counting rows, checking a filter;
  no estimate of a listed quantity) are attempts with `kind: ""` and need no
  `feedback.txt`.  They must NOT print any `RESULT:` line, not even a
  placeholder: the first run that prints one is scored as your first scored
  attempt.  Print `RESULT:` lines only from a script that estimates the
  listed quantities, and `kind: "error"` only for a run that crashed or
  that was meant to print them and did not.
- Write `reproduction.json` last, in this schema:

```
reproduction.json (schema 1), written last by the agent into its run directory
benchmark/reproductions/<entry_id>/<mode>/<run_id>/:

{
  "schema": 1,
  "entry_id": "montero-2022-cooperative-property-rights",
  "mode": "independent",
  "run_id": "2026-10-22-a",
  "reproducer": "claude-code",
  "language": "r",
  "final": {"script": "script.R", "stdout": "stdout.txt", "stderr": "stderr.txt", "exit_code": 0},
  "attempts": [
    {"dir": "attempt-1", "exit_code": 1, "kind": "error"},
    {"dir": "attempt-2", "exit_code": 0, "kind": "claim"}
  ],
  "deviations": [],
  "notes": "free text: what the agent did, what it could not do",
  "files_read_outside_mount": [],
  "started_at": "2026-10-22T10:00:00Z",
  "finished_at": "2026-10-22T10:40:00Z"
}

* entry_id, mode and run_id must match the directory the file sits in.
* final: the run that is scored -- script.R, stdout.txt, stderr.txt at the
  run-dir root, and its exit code.  If the agent reverts to an earlier
  attempt it copies that attempt's files there.
* attempts: every execution before the final one, oldest first.  Each
  attempt-<n>/ holds script.R, stdout.txt, stderr.txt, and feedback.txt
  when kind is not "".  kind is the refinement that followed it:
  "error" (it crashed or printed no RESULT: line; the agent repaired it),
  "claim" (the agent compared its RESULT: values with the claimed values
  and changed the script; never allowed in blind mode), or "" (neither).
* All paths are relative to the run directory; absolute paths and ".."
  are rejected.
* deviations: free-text methodology changes, in addition to any
  DEVIATION: lines in the final stdout.
* The numbers scored are the RESULT: lines of the files, never anything
  written in this JSON.
```

End your final message with the final run's `RESULT:` lines and a short
note.  Nothing needed for scoring may live only in the message: the files
are the record.

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/goni-2022-assortative-matching-london-season/seeded/2026-11-10-b`.
