# Retally reproduction task: hanushek-2022-patience-risk-human-capital (seeded, run 2026-11-02-a)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `hanushek-2022-patience-risk-human-capital`, mode `seeded`, run `2026-11-02-a`
- Paper: Patience, Risk-Taking, and Human Capital Investment across Countries
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital` as data, and `<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a/paper.txt` as
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

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Claims to Reproduce
1. table1_col3_patience: 1.226 (SD of PISA math score per SD of national patience) [type: coefficient]
   Location: Table 1, column (3) Full sample, Patience
   Context: Table 1 ("National Preferences and Student Achievement across Countries: The Intertwined Roles of Patience and Risk-taking"), column (3), row Patience. Student-level least squares regression of the PISA math test score (original PISA scores divided by 100, so a unit is one standard deviation), pooled over all PISA waves 2000-2018, on the country's Global Preference Survey patience and risk-taking entered together. Each preference is z-standardised in the analytical sample and collapsed to the country level. Controls: student gender, age and migration status, imputation dummies, and test-wave f…
2. table1_col3_risk_taking: -1.241 (SD of PISA math score per SD of national risk-taking) [type: coefficient]
   Location: Table 1, column (3) Full sample, Risk-taking
   Context: Table 1, column (3), row Risk-taking. Same regression as table1_col3_patience (patience and risk-taking entered together).
3. table1_col1_patience: 0.917 (SD of PISA math score per SD of national patience) [type: coefficient]
   Location: Table 1, column (1) Full sample, Patience
   Context: Table 1, column (1), row Patience. Same specification as table1_col3_patience but with patience as the only preference measure (risk-taking omitted).
4. table1_col2_risk_taking: -0.482 (SD of PISA math score per SD of national risk-taking) [type: coefficient]
   Location: Table 1, column (2) Full sample, Risk-taking
   Context: Table 1, column (2), row Risk-taking. Same specification as table1_col3_patience but with risk-taking as the only preference measure (patience omitted).
5. table1_col5_natives_patience: 1.296 (SD of PISA math score per SD of national patience) [type: coefficient]
   Location: Table 1, column (5) Natives, Patience
   Context: Table 1, column (5) Natives, row Patience. The column (3) regression (patience and risk-taking together, same weighting, wave fixed effects and country-clustered SEs) estimated on native students only. Students are migrants if both parents were born abroad; natives are the rest. The migration-status controls drop out within this subsample.
6. table1_col5_natives_risk_taking: -1.32 (SD of PISA math score per SD of national risk-taking) [type: coefficient]
   Location: Table 1, column (5) Natives, Risk-taking
   Context: Table 1, column (5) Natives, row Risk-taking. Same regression as table1_col5_natives_patience.
7. table1_col3_observations: 1992276.0 (students) [type: other]
   Location: Table 1, column (3), Observations
   Context: Observations in the Table 1 column (3) regression: students in all PISA waves 2000-2018 in the 49 countries with GPS data (the full-sample N shared by columns 1-4, 7 and 8).
8. table2_col3_patience: 0.931 (SD of PISA math score per SD of country-of-origin patience) [type: coefficient]
   Location: Table 2, column (3) Full sample, Patience (country-of-origin)
   Context: Table 2 ("Patience, Risk-taking, and Student Achievement: Migrant Analysis"), column (3), row Patience (country-of-origin). Least squares regression of the PISA math score (divided by 100), PISA waves 2003-2018, on the GPS patience and risk-taking of the student's country of origin, entered together. Sample: migrant students, both of whose parents were born outside the country where the student attends school, with an identified origin country that has GPS data. First-generation migrants are assigned their country of birth, second-generation migrants their father's country of origin. The sampl…
9. table2_col3_risk_taking: -0.294 (SD of PISA math score per SD of country-of-origin risk-taking) [type: coefficient]
   Location: Table 2, column (3) Full sample, Risk-taking (country-of-origin)
   Context: Table 2, column (3), row Risk-taking (country-of-origin). Same regression as table2_col3_patience.
10. table2_col1_patience: 0.779 (SD of PISA math score per SD of country-of-origin patience) [type: coefficient]
   Location: Table 2, column (1) Full sample, Patience (country-of-origin)
   Context: Table 2, column (1), row Patience (country-of-origin). Same specification as table2_col3_patience but with country-of-origin patience as the only preference measure.
11. table2_col4_patience: 1.032 (SD of PISA math score per SD of country-of-origin patience) [type: coefficient]
   Location: Table 2, column (4) Full sample, Patience (country-of-origin)
   Context: Table 2, column (4), row Patience (country-of-origin). The column (3) regression plus the four other GPS preferences of the country of origin (positive reciprocity, negative reciprocity, altruism, trust) as controls.
12. table2_col4_risk_taking: -0.449 (SD of PISA math score per SD of country-of-origin risk-taking) [type: coefficient]
   Location: Table 2, column (4) Full sample, Risk-taking (country-of-origin)
   Context: Table 2, column (4), row Risk-taking (country-of-origin). Same regression as table2_col4_patience.
13. table2_col3_observations: 80398.0 (migrant students) [type: other]
   Location: Table 2, column (3), Observations
   Context: Observations in the Table 2 column (3) regression: first- and second-generation migrant students, PISA waves 2003-2018 (the full-sample N shared by columns 1-5).

## Dataset Information
Name: hanushek_2022_patience_risk_human_capital
Local path: <repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital
File format: csv
Files in the dataset directory (paths relative to the local path above):
- Replication/Data/Working/pisa_full_gps_final_imcoo.dta (104.7 MB) — 80398 rows, 236 columns: country, wave, oecd, patience, coo_oecd, coo_risktaking, migage, coo, pv1math, coo_posrecip_orig, coo_negrecip_orig, smctry, coo_patience, coo_altruism, coo_trust, coo_patience_orig, coo_altruism_orig, coo_trust_orig, schoolid, countrywave, patience_sd, coo_wvs_important_risk_orig, coo_wvs_important_risk, risktaking, migra0, migra1, migra2, risktaking_sd, coo_risktaking_orig, pv2math_orig, pv3math_orig, pv4math_orig, pv5math_orig, pv6math_orig, pv7math_orig, pv8math_orig, pv9…
- Replication/Data/Working/pisa_full_gps_final_cooavg.dta (22.8 MB) — 145506 rows, 28 columns: country, wave, coof_risktaking, coo_oecd, coof, coo_risktaking, coof_patience, coo, pv1math, coo_patience, coom_patience, coom_risktaking, countrywave, isocode, pv1readorig, pv1scieorig, pv1mathorig, stubrncnt, fatbrncnt, motbrncnt, coom, coo_isocode, image, age, imfemale, female, pv1scie, pv1read
- Replication/Data/Working/pisa_full_gps_final_imcooavg.dta (13.3 MB) — 83798 rows, 28 columns: country, wave, coof_risktaking, coo_oecd, coof, coo_risktaking, coof_patience, coo, pv1math, coo_patience, coom_patience, coom_risktaking, countrywave, isocode, pv1readorig, pv1scieorig, pv1mathorig, stubrncnt, fatbrncnt, motbrncnt, coom, coo_isocode, image, age, imfemale, female, pv1scie, pv1read
- Replication/Data/Working/pisa_full_gps_final.dta (2.3 GB) — 1992276 rows, 208 columns: wave, oecd, patience, altruism, trust, country, risktaking, pv1math, wvs_important_risk, schoolid, mmschoolbudgetgov, imschoolbudgetgov, migra0, migra1, migra2, pv2math_orig, pv3math_orig, pv4math_orig, pv5math_orig, pv6math_orig, pv7math_o…
- Replication/Data/Working/pisa_full_gps_final_coo.dta (16.6 MB) — 141155 rows, 22 columns: country, wave, coo_oecd, coo_risktaking, coo, pv1math, coo_patience, countrywave, isocode, pv1readorig, pv1scieorig, pv1mathorig, stubrncnt, fatbrncnt, motbrncnt, coo_isocode, image, age, imfemale, female, pv1scie, pv1read
- Replication/Data/Working/pisa_full_gps_final_coobothm.dta (16.6 MB) — 140951 rows, 22 columns: country, wave, coo_oecd, coo_risktaking, coo, pv1math, coo_patience, countrywave, isocode, pv1readorig, pv1scieorig, pv1mathorig, stubrncnt, fatbrncnt, motbrncnt, coo_isocode, image, age, imfemale, female, pv1scie, pv1read
- Replication/Data/Working/pisa_full_gps_final_imcoobothm.dta (9.6 MB) — 80194 rows, 22 columns: country, wave, coo_oecd, coo_risktaking, coo, pv1math, coo_patience, countrywave, isocode, pv1readorig, pv1scieorig, pv1mathorig, stubrncnt, fatbrncnt, motbrncnt, coo_isocode, image, age, imfemale, female, pv1scie, pv1read
- Replication/Data/Orig/Other/dist_cepii.dta (1.8 MB) — 50176 rows, 14 columns: smctry, iso_o, iso_d, contig, comlang_off, comlang_ethno, colony, comcol, curcol, col45, dist, distcap, distw, distwces
- Replication/Data/CSV/dist_cepii.csv (3.8 MB) — columns: iso_o,iso_d,contig,comlang_off,comlang_ethno,colony,comcol,curcol,col45,smctry,dist,distcap,distw,distwces
- Replication/Data/CSV/pisa_full_gps_final.csv (2.8 GB) — columns: schoolid,isocode,studid,pv1readorig,w_fstr1,w_fstr2,w_fstr3,w_fstr4,w_fstr5,w_fstr6,w_fstr7,w_fstr8,w_fstr9,w_fstr10,w_fstr11,w_fstr12,w_fstr13,w_fstr14,w_fstr15,w_fstr16,w_fstr17,w_fstr18,w_fstr19,w_fstr20,w_fstr21,w_fstr22,w_fstr23,w_fstr…
- Replication/Data/CSV/pisa_full_gps_final_coo.csv (18.2 MB) — columns: country,isocode,pv1readorig,pv1scieorig,pv1mathorig,stubrncnt,fatbrncnt,motbrncnt,wave,coo,coo_isocode,coo_patience,coo_risktaking,coo_oecd,image,age,imfemale,female,countrywave,pv1math,pv1scie,pv1read
- Replication/Data/CSV/pisa_full_gps_final_cooavg.csv (25.5 MB) — columns: country,isocode,pv1readorig,pv1scieorig,pv1mathorig,stubrncnt,fatbrncnt,motbrncnt,wave,coom,coof,coof_patience,coof_risktaking,coom_patience,coom_risktaking,coo_patience,coo_risktaking,coo,coo_isocode,coo_oecd,image,age,imfemale,female,coun…
- Replication/Data/CSV/pisa_full_gps_final_coobothm.csv (18.1 MB) — columns: country,isocode,pv1readorig,pv1scieorig,pv1mathorig,stubrncnt,fatbrncnt,motbrncnt,wave,coo,coo_isocode,coo_patience,coo_risktaking,coo_oecd,image,age,imfemale,female,countrywave,pv1math,pv1scie,pv1read
- Replication/Data/CSV/pisa_full_gps_final_imcoo.csv (117.8 MB) — columns: country,schoolid,isocode,studid,pv1readorig,w_fstr1,w_fstr2,w_fstr3,w_fstr4,w_fstr5,w_fstr6,w_fstr7,w_fstr8,w_fstr9,w_fstr10,w_fstr11,w_fstr12,w_fstr13,w_fstr14,w_fstr15,w_fstr16,w_fstr17,w_fstr18,w_fstr19,w_fstr20,w_fstr21,w_fstr22,w_fstr2…
- Replication/Data/CSV/pisa_full_gps_final_imcooavg.csv (15.3 MB) — columns: country,isocode,pv1readorig,pv1scieorig,pv1mathorig,stubrncnt,fatbrncnt,motbrncnt,wave,coom,coof,coom_patience,coom_risktaking,coof_patience,coof_risktaking,coo_patience,coo_risktaking,coo,coo_isocode,coo_oecd,image,age,imfemale,female,coun…
- Replication/Data/CSV/pisa_full_gps_final_imcoobothm.csv (10.3 MB) — columns: country,isocode,pv1readorig,pv1scieorig,pv1mathorig,stubrncnt,fatbrncnt,motbrncnt,wave,coo,coo_isocode,coo_patience,coo_risktaking,coo_oecd,image,age,imfemale,female,countrywave,pv1math,pv1scie,pv1read
- Replication/Data/Orig/Other/Continents.xlsx (11.2 KB)
- Replication/Data/Orig/Other/GDPpc_2000-2018_long.xlsx (38.2 KB)
- Replication/Data/Orig/Other/cee.xlsx (16.6 KB)
- Replication/Data/Orig/Other/hc_data.xlsx (43.7 KB)
- Replication/Data/Orig/Other/migsel.xlsx (667.1 KB)
- Replication/Data/Orig/Other/oecd.xlsx (9.3 KB)
- Replication/Data/Orig/PISA/2000/Thumbs.db (126.0 KB)
- Replication/Data/Orig/PISA/2003/Thumbs.db (121.0 KB)
- Replication/Data/Orig/PISA/2006/Thumbs.db (105.0 KB)
- Replication/Data/Orig/PISA/2009/Thumbs.db (70.5 KB)
- Replication/Data/Orig/PISA/2012/Thumbs.db (55.0 KB)
- Replication/Do/0_masterfile.do (563 B)
- Replication/Do/1a1_2000.do (8.8 KB)
- Replication/Do/1a2_2003.do (13.6 KB)
- Replication/Do/1a3_2006.do (16.3 KB)
- Replication/Do/1a4_2009.do (18.6 KB)
- Replication/Do/1a5_2012.do (27.2 KB)
- Replication/Do/1a6_2015.do (28.2 KB)
- Replication/Do/1a7_2018.do (27.8 KB)
- Replication/Do/1a_merge.do (4.6 KB)
- Replication/Do/1b_append.do (5.9 KB)
- Replication/Do/1c_weights_collapse.do (4.0 KB)
- Replication/Do/1d_merge_gps.do (6.4 KB)
- Replication/Do/1e_migdefs.do (17.6 KB)
- Replication/Do/2a_external_impute_indiv.do (10.1 KB)
- Replication/Do/2a_external_impute_indiv_migdefs.do (13.2 KB)
- Replication/Do/2b_labels.do (5.4 KB)
- Replication/Do/2b_labels_migdefs.do (4.1 KB)
- Replication/Do/2c_prepare_analysis.do (10.3 KB)
- Replication/Do/2d_effort.do (13.3 KB)
- Replication/Do/3_analysis_crosscountry.do (14.6 KB)
- Replication/Do/3_analysis_migrants.do (16.3 KB)
- Replication/README.docx (24.0 KB)
- metadata.json (296 B)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
Installed packages (no network; nothing else can be installed): jsonlite, fixest, lfe, AER, ivreg, plm, estimatr, lme4, quantreg, car, sandwich, lmtest, clubSandwich, multiwayvcov, marginaleffects, MatchIt, optmatch, CBPS, WeightIt, cobalt, did, rdrobust, rddensity, Synth, modelsummary, stargazer, texreg, broom, tidyverse, dplyr, tidyr, readr, stringr, lubridate, data.table, haven, readxl, janitor, zoo, ggplot2, ggridges, ggrepel, gridExtra, cowplot, gtable, extrafont, sf, MASS, nnet, survival, splines, Matrix, boot, stats, utils.
Prefer fixest for fixed effects, IV and clustered SEs; use the other installed packages where the paper's method calls for them.
Set a deterministic seed with ``set.seed(42)`` for any randomness.
Do NOT access the internet; the container runs with --network none.
Do NOT shell out via system() / system2().
Emit RESULT:<name>=<value> lines to stdout at the end via cat().

## Original Replication Scripts
The replication package (the dataset directory) ships the authors' own analysis scripts, reproduced below.  These are the GROUND TRUTH for the exact estimating equation, variable names, sample restrictions, fixed effects, and standard-error clustering — follow them over anything reconstructed from the methodology summary, and prefer them over the paper's text where the two disagree.  Your job is to write R code that implements the SAME SPECIFICATION: translate what the scripts estimate, do not transliterate their syntax line by line (a Stata .do file's regression, e.g. `reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the equivalent fixest::feols() call in R).  Keep only the parts that produce the specific claims being reproduced; skip figure construction and unrelated robustness checks.  The scripts' data-file paths refer to the package's internal layout — resolve them against the dataset directory listed under Dataset Information.

Stata-to-fixest sample matching: feols() drops fixed-effect singletons by default, but Stata's `reg y x i.fe` / `xi:` dummies keep them.  Pass `fixef.rm = "none"` to every feols() call that has fixed effects, otherwise the observation count and the robust SEs drift from the paper's.  Stata's `, r` / `vce(robust)` is `vcov = "hetero"`.

### `Replication/Do/0_masterfile.do`
```stata
*** CREATE GLOBAL FOR THE DIRECTORY PATHS ***
	global path "G:\Projekte\ICEPL\ICEPL - Economic Preferences\Replication"		
		
* DATASET PREPARATION *

	do "$path/Do/1a_merge.do"
	do "$path/Do/1b_append.do"
	do "$path/Do/1c_weights_collapse.do"
	do "$path/Do/1d_merge_gps.do"
	
* ADD EXTERNAL MEASURES, IMPUTE, AND LABEL *

	do "$path/Do/2a_external_impute_indiv.do"
	do "$path/Do/2b_labels.do"
	do "$path/Do/2c_prepare_analysis.do"
	
* TABLES AND FIGURES PAPER *

	do "$path/Do/3_analysis_crosscountry.do"
	do "$path/Do/3_analysis_migrants.do"

```

### `Replication/Do/2c_prepare_analysis.do`
```stata
***************
* FULL SAMPLE *
***************
	
	****************************
	* ADD FINAL MISSING VALUES *
	****************************
	
	use "$path/Data/Working\pisa_full_gps_prefinal.dta", clear
					
		collapse (mean) mmaut_content_index cee GDPpc, by(isocode wave)
			
		bysort isocode: replace mmaut_content_index= mmaut_content_index[_n-1] if missing(mmaut_content_index) & _n>1
		gen imautindex=0
		replace imautindex=1 if missing(mmaut_content_index)
		reg mmaut_content_index GDPpc i.wave
		predict xbaut, xb
		replace mmaut_content_index=xbaut if missing(mmaut_content_index)
			
		bysort isocode: replace cee=cee[_n-1] if missing(cee) & _n>1
		gen imcee=0
		replace imcee=1 if missing(cee)
		reg cee GDPpc i.wave
		predict xbcee, xb
		replace cee=xbcee if missing(cee)
			
		drop xbaut xbcee GDPpc
			
	save "$path/Data/Working\mediation.dta", replace
	
	*******************
	* EFFORT MEASURES *
	*******************
	
	do "$path/Do\2d_effort.do"
		
	********************************
	* STANDARDIZATION HOFSTEDE WVS *
	********************************
	
	use "$path/Data/Working\pisa_full_gps_prefinal.dta", clear

		keep isocode
		duplicates drop
		
		merge n:1 isocode using "$path/Data/Orig/GPS\country.dta", keep(match) nogen
						
		foreach var in hofstede_lto hofstede_uai wvs_child_save wvs_important_risk {
			qui sum `var', d
			gen `var'_stand=(`var'-r(mean))/r(sd)
			rename `var' `var'_orig
			rename `var'_stand `var'
		}
		
		keep hofstede_lto hofstede_uai wvs_child_save wvs_important_risk isocode
		
	save "$path/Data/Working\hofstede_wvs_countrystand.dta", replace

********************************************************************************
	
	use "$path/Data/Working\pisa_full_gps_prefinal.dta", clear
				
		drop mmaut_content_index cee 
		merge n:1 isocode wave using "$path/Data/Working\mediation.dta", nogen
		
		merge 1:1 wave isocode schoolid studid using "$path/Data/Working\nonresp.dta", keep(master match) nogen
		merge n:1 isocode wave using "$path/Data/Working\nonresp_clevel.dta", keep(master match) nogen
		
		drop hofstede* wvs*	
		merge n:1 isocode using "$path/Data/Working\hofstede_wvs_countrystand.dta", nogen

	save "$path/Data/Working\pisa_full_gps_final.dta", replace
	
	erase "$path/Data/Working\mediation.dta"
	erase "$path/Data/Working\nonresp_clevel.dta"
	erase "$path/Data/Working\hofstede_wvs_countrystand.dta"
	erase "$path/Data/Working\pisa_full_gps_prefinal.dta"
	
******************
* MIGRANT SAMPLE *
******************

	****************************
	* ADD FINAL MISSING VALUES *
	****************************
	
	use "$path/Data/Working\pisa_full_gps_final.dta", clear
		keep if isocode=="CAN" & wave==2018
		keep isocode wave numstudtotal
		duplicates drop
		rename numstudtotal numstudtotalcan18
	save "$path/Data/Working\pisa_full_gps_CAN18numstud.dta", replace
	
	*************************************
	* WITHIN COUNTRY CULTURAL VARIANCE  *
	*************************************

	use "$path/Data/Working\pisa_full_gps_prefinal_imcoo.dta", clear
	
		keep coo_isocode
		duplicates drop
		rename coo_isocode isocode
		
		merge 1:n isocode using "$path/Data/Orig/GPS\individual_plain.dta", gen(sel)
			drop if sel!=3
			collapse (sd) patience risk [aw=wgt], by(country isocode)
			keep isocode patience risk
			rename isocode coo_isocode
			rename patience patience_sd
			rename risktaking risktaking_sd
	
	save "$path/Data/Working\pisa_full_gps_final_imcoo_sel.dta", replace
	
	**********************
	* MIGRATION DISTANCE *
	**********************

	use	"$path/Data/Orig/Other\dist_cepii.dta", clear
	
		rename iso_d isocode
		rename iso_o coo_isocode
		
		replace isocode="ROU" if isocode=="ROM"
		replace coo_isocode="ROU" if coo_isocode=="ROM"
	
	save "$path/Data/Orig/Other\dist.dta", replace
	
	***************
	* SELECTIVITY *
	***************
	
	* from replication files of Hanushek, Ruhose and Woessmann (2017)
	
		foreach x in AUS AUT BEL CAN CZE DEN FIN FRA GER GRE HUN ISL IRE ITA JAP KOR LUX MEX NET NOR NZE POL POR SLO SPA SWE SWI TUR UK USA SAF {
			clear
			import excel using "$path/Data/Orig/Other\migsel.xlsx", firstrow sheet("`x'")
				gen destc="`x'"
				gen migallprim_rate = AllPrim/Total
				gen migallsec_rate  = AllSec/Total
				gen migallter_rate  = AllTer/Total
				
				save "$path/Data/Orig/Other\sel_`x'.dta", replace
		}
		
		use "$path/Data/Orig/Other\sel_AUS.dta", clear
		
			foreach x in AUT BEL CAN CZE DEN FIN FRA GER GRE HUN ISL IRE ITA JAP KOR LUX MEX NET NOR NZE POL POR SLO SPA SWE SWI TUR UK USA SAF {
				append using "$path/Data/Orig/Other\sel_`x'.dta"
			}
			
			replace destc="DNK" if destc=="DEN"
			replace destc="DEU" if destc=="GER"
			replace destc="IRL" if destc=="IRE"
			replace destc="NLD" if destc=="NET"
			replace destc="NZL" if destc=="NZE"
			replace destc="PRT" if destc=="POR"
			replace destc="SVK" if destc=="SLO"
			replace destc="ESP" if destc=="SPA"
			replace destc="CHE" if destc=="SWI"
			replace destc="GBR" if destc=="UK"
			
			drop if missing(Countryofbirth) & missing(Countryofcitizenship)
			
			gen citimp=0
			replace citimp=1 if !missing(Countryofcitizenship) & missing(Countryofbirth)
			
			replace Countryofbirth=Countryofcitizenship if missing(Countryofbirth)
			drop Countryofcitizenship
			rename Countryofbirth coo
			
			keep coo *rate destc citimp
			
			drop if missing(migallprim_rate)
		
		save "$path/Data/Orig/Other\sel.dta", replace
		
			foreach x in AUS AUT BEL CAN CZE DEN FIN FRA GER GRE HUN ISL IRE ITA JAP KOR LUX MEX NET NOR NZE POL POR SLO SPA SWE SWI TUR UK USA SAF {
				erase "$path/Data/Orig/Other\sel_`x'.dta"
		}

	clear
	import excel using "$path/Data/Orig/Other\hc_data.xlsx", firstrow
	
		drop if missing(Country)
	
		gen hc_allprim_rate = AllPrim/Total
		gen hc_allsec_rate  = AllSec/Total
		gen hc_allter_rate  = AllTer/Total
				
		rename Countryofresidence coo
		
		keep hc* coo
	
		merge 1:n coo using "$path/Data/Orig/Other\sel.dta"
			drop if _merge==2				
			drop _merge
		
		replace coo="South Korea" if coo=="Korea"
		replace coo="Bosnia Herzegovina" if coo=="Bosnia and Herzegovina"
		replace coo="Serbia" if coo=="Serbia and Montenegro"
		
	save "$path/Data/Working\selectivity.dta", replace 
	
	********************************
	* STANDARDIZATION HOFSTEDE WVS *
	********************************

	use "$path/Data/Working\pisa_full_gps_prefinal_imcoo.dta", clear
		
		keep coo_isocode
		rename coo_isocode isocode
		duplicates drop
		
		merge n:1 isocode using "$path/Data/Orig/GPS\country.dta", keep(match) nogen
		
		foreach var in patience risktaking negrecip posrecip altruism trust hofstede_lto hofstede_uai wvs_child_save wvs_important_risk {
			rename `var' coo_`var'
		}
		
		keep isocode coo_patience coo_risktaking coo_negrecip coo_posrecip coo_altruism coo_trust coo_hofstede_lto coo_hofstede_uai coo_wvs_child_save coo_wvs_important_risk
		
		foreach var in coo_patience coo_risktaking coo_negrecip coo_posrecip coo_altruism coo_trust coo_hofstede_lto coo_hofstede_uai coo_wvs_child_save coo_wvs_important_risk {
			sum `var', d
			gen `var'_stand=(`var'-r(mean))/r(sd)
			rename `var' `var'_orig
			rename `var'_stand `var'
		}
		
		rename isocode coo_isocode
		
	save "$path/Data/Working\hofstede_wvs_imcoo_countrystand.dta", replace
		
********************************************************************************

	use "$path/Data/Working\pisa_full_gps_prefinal_imcoo.dta", clear
	
		merge n:1 isocode wave using "$path/Data/Working\pisa_full_gps_CAN18numstud.dta", nogen
		replace numstudtotal=numstudtotalcan18 if isocode=="CAN" & wave==2018
		drop numstudtotalcan18
		
		merge 1:1 wave isocode schoolid studid using "$path/Data/Working\nonresp.dta", keep(master match) nogen
		merge n:1 coo_isocode wave using "$path/Data/Working\nonresp_coolevel.dta", keep(master match) nogen
		
		merge n:1 coo_isocode using "$path/Data/Working\pisa_full_gps_final_imcoo_sel.dta", nogen
		
		merge n:1 isocode coo_isocode using "$path/Data/Orig/Other\dist.dta", keep(master match) nogen		
			replace dist=527.25  if isocode=="LIE" & coo_isocode=="AUT"
			replace dist=632.08  if isocode=="LIE" & coo_isocode=="ITA"
			replace dist=658.34  if isocode=="LIE" & coo_isocode=="DEU"
			replace dist=563.89  if isocode=="LIE" & coo_isocode=="FRA"
			replace dist=869.97  if isocode=="LIE" & coo_isocode=="PRT"
			replace dist=1296.07 if isocode=="LIE" & coo_isocode=="ESP"
			replace dist=75.08   if isocode=="LIE" & coo_isocode=="CHE"
			replace dist=1693.92 if isocode=="LIE" & coo_isocode=="TUR"

			replace dist=498.77  if isocode=="AUT" & coo_isocode=="SRB"
			replace dist=196.63  if isocode=="BIH" & coo_isocode=="SRB"
			replace dist=367.41  if isocode=="HRV" & coo_isocode=="SRB"
			replace dist=1000.13 if isocode=="DEU" & coo_isocode=="SRB"
			replace dist=323.59  if isocode=="MKD" & coo_isocode=="SRB"
			replace dist=281.27  if isocode=="MNE" & coo_isocode=="SRB"
		
			replace dist=172.31  if isocode=="MNE" & coo_isocode=="BIH"
			replace dist=457.66  if isocode=="MNE" & coo_isocode=="HRV"
		
			replace dist=dist/1000
			
		gen abs_patdist=abs(coo_patience-patience)
		gen abs_riskdist=abs(coo_risktaking-risktaking)
		*alternative:
		gen patdist=coo_patience-patience
		gen riskdist=coo_risktaking-risktaking
		
		rename isocode destc
		merge m:n coo destc using "$path/Data/Working\selectivity.dta", keep(master match) nogen
		rename destc isocode
		gen p=migallprim_rate*0.5*hc_allprim_rate+migallsec_rate*(hc_allprim_rate+0.5*hc_allsec_rate)+migallter_rate*(hc_allprim_rate+hc_allsec_rate+0.5*hc_allter_rate)
	
		drop coo_hofstede_lto coo_hofstede_uai coo_wvs_child_save coo_wvs_important_risk		
		merge n:1 coo_isocode using "$path/Data/Working\hofstede_wvs_imcoo_countrystand.dta", nogen
		
	save "$path/Data/Working\pisa_full_gps_final_imcoo.dta", replace	
	
	erase "$path/Data/Working\pisa_full_gps_CAN18numstud.dta"
	erase "$path/Data/Working\nonresp.dta"
	erase "$path/Data/Working\nonresp_coolevel.dta"	
	erase "$path/Data/Working\pisa_full_gps_prefinal_imcoo.dta"
	erase "$path/Data/Working\selectivity.dta"
	erase "$path/Data/Working\pisa_full_gps_final_imcoo_sel.dta"
	erase "$path/Data/Working\hofstede_wvs_imcoo_countrystand.dta"
	*erase "$path/Data/Working\pisa_full_gps_prefinal_imcoo_cooiso.dta"

```

### `Replication/Do/3_analysis_crosscountry.do`
```stata
*** GLOBALS ***
	
	* INDIVIDUAL LEVEL
	global indiv "female age migra1 migra2 dhisced2 dhisced345 dhisced6 bluehigh whitlow whithigh dbook2 dbook3 dbook4 comp_home otherlang GDPpc"
	
	* SCHOOL LEVEL
		global schoolgen "dloc23 dloc45 numstudtotal"
		global teacher "cert_teachers"
		global shortage "shormat"
	global school "$schoolgen $teacher $shortage"
	
	* COUNTRY LEVEL
		global countrymeans_red "mmprivate mmschoolbudgetgov"
		global cee "cee"
		global autcountry "mmaut_content_index"
	global country "$countrymeans_red $cee $autcountry"
	
	* IMPUTATION DUMMIES
	global imp "imfemale image immigra1 imdhisced1 imwhithigh imdbook1 imcomp_home imotherlang imdloc1 imnumstudtotal imcert_teachers imshormat"
	
	* ALL CONTROLS
	global all_controls "$indiv $school $country"
		
	* FIXED EFFECTS
	global FE "i.wave"

	* PREFERENCES	
	global preferences "patience risktaking posrecip negrecip altruism trust"

********************************************************************************	
******************************* TABLES *****************************************
********************************************************************************	
		
******************************* TABLE 1 ****************************************
		
	use "$path/Data/Working\pisa_full_gps_final.dta", clear
						
		reg pv1math patience female age migra1 migra2 image imfemale immigra1 $FE [pw=wgtc], vce(cluster country)
		outreg2 using "$path/Results\T1.xls", label replace keep(patience) sortvar(pv1math patience) e(N_clust) dec(3) nocons
		reg pv1math risktaking female age migra1 migra2 image imfemale immigra1 $FE [pw=wgtc], vce(cluster country)
		outreg2 using "$path/Results\T1.xls", label append keep(risktaking) sortvar(pv1math risk) e(N_clust) dec(3) nocons						
		reg pv1math patience risktaking female age migra1 migra2 image imfemale immigra1 $FE [pw=wgtc], vce(cluster country)
		outreg2 using "$path/Results\T1.xls", label append keep(patience risktaking) sortvar(pv1math patience risktaking) e(N_clust) dec(3) nocons
		reg pv1math $preferences female age migra1 migra2 image imfemale immigra1 $FE [pw=wgtc], vce(cluster country)
		outreg2 using "$path/Results\T1.xls", label append keep($preferences) sortvar(pv1math $preferences) e(N_clust) dec(3) nocons
			
		reg pv1math patience risktaking female age image imfemale $FE [pw=wgtc] if migra0==1, vce(cluster country)
		outreg2 using "$path/Results\T1.xls", label ctitle("Natives") append keep(patience risktaking) sortvar(patience risktaking) e(N_clust) dec(3) nocons
		reg pv1math patience risktaking female age migra1 image imfemale immigra1 $FE [pw=wgtc] if migra0==0, vce(cluster country)
		outreg2 using "$path/Results\T1.xls", label ctitle("Migrants") append keep(patience risktaking) sortvar(patience risktaking) e(N_clust) dec(3) nocons
		
			*test for equality of patience & risk coefficients:
			preserve
				keep if inlist(migra0,0,1)
				foreach var in patience risktaking female age image imfemale {
					gen `var'_migra=`var'*migra0
				}
				qui tab wave, gen(dwave)
				forvalues i=1(1)7 {
					gen dwave`i'_migra=dwave`i'*migra0
				}
			
				reg pv1math migra0 patience risktaking female age image imfemale i.wave patience_migra risktaking_migra female_migra age_migra image_migra imfemale_migra dwave1_migra-dwave7_migra [pw=wgtc], vce(cluster country)
					test _b[migra0]=0, notest
					test _b[risktaking_migra]=0, accum
					test _b[migra0]=0, notest
					test _b[patience_migra]=0, accum
					
				drop *_migra
				drop dwave*
			restore
			
		reg pv1math patience risktaking nonresp female age migra1 migra2 image imfemale immigra1 $FE [pw=wgtc], vce(cluster country)
		outreg2 using "$path/Results\T1.xls", label ctitle("Effort") append keep(patience risktaking nonresp) sortvar(pv1math patience risktaking) e(N_clust) dec(3) nocons
		reg pv1math patience risktaking nonresp mmnonresp female age migra1 migra2 image imfemale immigra1 $FE [pw=wgtc], vce(cluster country)
		outreg2 using "$path/Results\T1.xls", label ctitle("Effort") append keep(patience risktaking nonresp mmnonresp) sortvar(pv1math patience risktaking) e(N_clust) dec(3) nocons
	
****************************** TABLE 4 **************************************
		
	preserve
		
		qui reg pv1math $all_controls [pw=wgtc], vce(cluster country)
		
		predict resid, res		
		predict xb, xb
		matrix coefs = e(b)
		matrix score lc = coefs
		matrix c_fam = coefs[1,1..16]
		matrix score fam = c_fam
		matrix c_res = coefs[1,17..21]
		matrix score res = c_res
		matrix c_ins = coefs[1,22..25]
		matrix score ins = c_ins
		
		collapse pv1math patience risktaking xb fam res ins lc resid [w=wgtc], by(isocode)

		reg fam patience risk
		outreg2 using "$path/Results\T4.xls", label ctitle("Family") replace dec(3) nocons
		reg res patience risk
		outreg2 using "$path/Results\T4.xls", label ctitle("School") append dec(3) nocons
		reg ins patience risk
		outreg2 using "$path/Results\T4.xls", label ctitle("System") append dec(3) nocons
		reg resid patience risk
		outreg2 using "$path/Results\T4.xls", label ctitle("Residual") append dec(3) nocons
		
	restore
	
	preserve
	
		qui reg pv1math $all_controls patience risk [pw=wgtc], vce(cluster country)
		
		predict resid, res		
		predict xb, xb
		matrix coefs = e(b)
		matrix score lc = coefs
		matrix c_fam = coefs[1,1..16]
		matrix score fam = c_fam
		matrix c_res = coefs[1,17..21]
		matrix score res = c_res
		matrix c_ins = coefs[1,22..25]
		matrix score ins = c_ins
		
		collapse pv1math patience risktaking xb fam res ins lc resid [w=wgtc], by(isocode)

		reg fam patience risk
		outreg2 using "$path/Results\T4.xls", label ctitle("Family") append dec(3) nocons
		reg res patience risk
		outreg2 using "$path/Results\T4.xls", label ctitle("School") append dec(3) nocons
		reg ins patience risk
		outreg2 using "$path/Results\T4.xls", label ctitle("System") append dec(3) nocons
		
	restore
	
******************************* TABLE A2 ***************************************

	preserve

		keep pv1math pv1scie pv1read patience risktaking posrecip negrecip altruism trust isocode wave wgtc		
		collapse (mean) pv1math pv1scie pv1read patience risktaking posrecip negrecip altruism trust [pw=wgtc], by(isocode)
		outreg2 using "$path/Results/TA2.xls", replace sum(log) eqkeep(mean sd min max) label dec(3) sortvar(pv1math pv1scie pv1read patience risk posrecip negrecip altruism trust)
		
	restore

******************************* TABLE A3 ***************************************

	cap ssc install mkcorr
	
	preserve

		keep isocode
		duplicates drop
		merge 1:1 isocode using "$path/Data/Orig/GPS\country.dta", keep(match) nogen

		mkcorr patience risktaking posrecip negrecip altruism trust wvs_child_save wvs_important_risk hofstede_lto hofstede_uai, log("$path/Results/TA3.xls") sig replace cdec(3)
		
	restore
	
******************************* TABLE A4 ***************************************
	
	reg pv1math patience risktaking age migra1 migra2 image immigra1 $FE [pw=wgtc] if female==1, vce(cluster country)
	outreg2 using "$path/Results\TA4_full.xls", label replace ctitle("Girls") keep(patience risktaking) sortvar(pv1math patience risktaking) e(N_clust) dec(3) nocons
	reg pv1math patience risktaking age migra1 migra2 image immigra1 $FE [pw=wgtc] if female==0, vce(cluster country)
	outreg2 using "$path/Results\TA4_full.xls", label append ctitle("Boys") keep(patience risktaking) sortvar(pv1math patience risktaking) e(N_clust) dec(3) nocons

******************************* TABLE A5 ***************************************

	reg pv1math patience risktaking $all_controls $imp imautindex imcee $FE [pw=wgtc], vce(cluster country)
	outreg2 using "$path/Results\TA5_full.xls", label ctitle("2000-2018") replace keep(patience risk) sortvar(patience risktaking) e(N_clust) dec(3) nocons

******************************* TABLE A6 ***************************************

	preserve
		
		keep if wave==2015
		
		reg pv1math patience female age migra1 migra2 image imfemale immigra1 [pw=wgt], vce(cluster country)
		outreg2 using "$path/Results\TA6.xls", label ctitle("2015") replace keep(patience) sortvar(pv1math patience) e(N_clust) dec(3) nocons
		reg pv1math risktaking female age migra1 migra2 image imfemale immigra1 [pw=wgt], vce(cluster country)
		outreg2 using "$path/Results\TA6.xls", label ctitle("2015") append keep(risktaking) sortvar(pv1math risk) e(N_clust) dec(3) nocons
		reg pv1math patience risktaking female age migra1 migra2 image imfemale immigra1 [pw=wgt], vce(cluster country)
		outreg2 using "$path/Results\TA6.xls", label ctitle("2015") append keep(patience risktaking) sortvar(pv1math patience risktaking) e(N_clust) dec(3) nocons
		reg pv1math $preferences female age migra1 migra2 image imfemale immigra1 [pw=wgt], vce(cluster country)
		outreg2 using "$path/Results\TA6.xls", label ctitle("2015") append keep($preferences) sortvar(pv1math $preferences) e(N_clust) dec(3) nocons		
		reg pv1math patience risktaking $all_controls $imp [pw=wgt], vce(cluster country)
		outreg2 using "$path/Results\TA6.xls", label ctitle("2015") append keep(patience risktaking) sortvar(pv1math patience risktaking) e(N_clust) dec(3) nocons		
			
	restore
	
******************************* TABLE A7 ***************************************

	reg pv1math patience risktaking female age migra1 migra2 image imfemale immigra1 $FE [pw=wgtc] if oecd==1, vce(cluster country)
	outreg2 using "$path/Results\TA7_full.xls", label ctitle("OECD") replace keep(patience risktaking) sortvar(patience risktaking) e(N_clust) dec(3) nocons
	reg pv1math patience risktaking female age migra1 migra2 image imfemale immigra1 $FE [pw=wgtc] if oecd==0, vce(cluster country)
	outreg2 using "$path/Results\TA7_full.xls", label ctitle("Non-OECD") append keep(patience risktaking) sortvar(patience risktaking) e(N_clust) dec(3) nocons
	
		*test for equality of patience & risk coefficients:
		foreach var in patience risktaking female age migra1 migra2 image imfemale immigra1 {
			gen `var'_oecd=`var'*oecd
		}
		
		qui tab wave, gen(dwave)
		forvalues i=1(1)7 {
			gen dwave`i'_oecd=dwave`i'*oecd
		}


		reg pv1math oecd patience risktaking female age migra1 migra2 image imfemale immigra1 i.wave patience_oecd risktaking_oecd female_oecd age_oecd migra1_oecd migra2_oecd image_oecd imfemale_oecd immigra1_oecd dwave1_oecd-dwave7_oecd [pw=wgtc], vce(cluster country)
			test _b[oecd] =0, notest
			test _b[risktaking_oecd] =0, accum
			test _b[oecd] =0, notest
			test _b[patience_oecd] =0, accum
			
		drop *_oecd
		drop dwave*

******************************* TABLE A8 ***************************************

	reg pv1scie patience risktaking female age migra1 migra2 image imfemale immigra1 $FE [pw=wgtc], vce(cluster country)
	outreg2 using "$path/Results\TA8_full.xls", label replace ctitle("Science") keep(patience risktaking) sortvar(patience risktaking) e(N_clust) dec(3) nocons
	reg pv1read patience risktaking female age migra1 migra2 image imfemale immigra1 $FE [pw=wgtcread], vce(cluster country)
	outreg2 using "$path/Results\TA8_full.xls", label append ctitle("Reading") keep(patience risktaking) sortvar(patience risktaking) e(N_clust) dec(3) nocons

******************************* TABLE A9 ***************************************
	
	reg pv1math wvs_child_save wvs_important_risk female age migra1 migra2 image imfemale immigra1 $FE [pw=wgtc], vce(cluster country)
	outreg2 using "$path/Results\TA9_full.xls", label replace keep(wvs_child_save wvs_important_risk) e(N_clust) dec(3) nocons
	reg pv1math hofstede_lto hofstede_uai female age migra1 migra2 image imfemale immigra1 $FE [pw=wgtc], vce(cluster country)
	outreg2 using "$path/Results\TA9_full.xls", label append keep(hofstede_lto hofstede_uai) e(N_clust) dec(3) nocons
	
******************************* TABLE A10 ***************************************

	reg pv1math patience risktaking i.wave [pw=wgtc], vce(cluster country)
	reg pv1math patience risktaking female age migra1 migra2 image imfemale immigra1 i.wave [pw=wgtc], vce(cluster country)
	*use as Rmax: 1.3*R^2 from TAB1COL3 = 1.3*0.198=0.26
	
	cap ssc install psacalc
	
	psacalc delta patience, mcontrol(risktaking i.wave) rmax(0.26)
	psacalc beta  patience, mcontrol(risktaking i.wave) rmax(0.26)

	psacalc delta risktaking, mcontrol(patience i.wave) rmax(0.26)			
	psacalc beta  risktaking, mcontrol(patience i.wave) rmax(0.26)

********************************************************************************	
******************************* FIGURES ****************************************
********************************************************************************

******************************* FIGURE 1 ***************************************
		
	preserve
		
		qui reg pv1math risk 
		predict cr_math, res
		qui reg patience risk 
		predict cr_patience, res
			
		qui reg pv1math patience
		predict cp_math, res
		qui reg risk patience
		predict cp_risk, res

		collapse (mean) pv1math patience risk cr_math cr_patience cp_math cp_risk [pweight=wgtc], by(isocode)

		scatter pv1math patience, mlabel(isocode) xtitle("Patience") ytitle("PISA math score") msymbol(none) mlabpos(0) mlabcolor(black) graphregion(fcolor(white)) || lfit pv1math patience, legend(off) lcolor(black)
		graph export "$path/Results\F1upperleft.tif", replace
			
		scatter pv1math risk, mlabel(isocode) msymbol(none) xtitle("Risk-taking") ytitle("PISA math score") mlabpos(0) mlabcolor(black) graphregion(fcolor(white)) || lfit pv1math risk, legend(off) lcolor(black)
		graph export "$path/Results\F1upperright.tif", replace

		scatter cr_math cr_patience, mlabel(isocode) msymbol(none) xtitle("Patience (conditional on risk-taking)") ytitle("PISA math score (conditional on risk-taking)") mlabpos(0) mlabcolor(black) graphregion(fcolor(white)) || lfit cr_math cr_patience, legend(off) lcolor(black)
		graph export "$path/Results\F1lowerleft.tif", replace

		scatter cp_math cp_risk, mlabel(isocode) msymbol(none) xtitle("Risk-taking (conditional on patience)") ytitle("PISA math score (conditional on patience)") mlabpos(0) mlabcolor(black) graphregion(fcolor(white)) || lfit cp_math cp_risk, legend(off) lcolor(black)
		graph export "$path/Results\F1lowerright.tif", replace
					
	restore
		
******************************* FIGURE A1 ***************************************
	
	preserve
	
		collapse (mean) patience risk [pweight=wgtc], by(isocode)

		scatter patience risktaking, mlabel(isocode) xtitle("Risk-taking") ytitle("Patience") msymbol(none) mlabpos(0) mlabcolor(black) graphregion(fcolor(white)) || lfit patience risk, legend(off) lcolor(black)
		graph export "$path/Results\FA1.tif", replace
		
	restore

```

### `Replication/Do/3_analysis_migrants.do`
```stata
*** GLOBALS ***
	
	* INDIVIDUAL LEVEL
	global indiv "female age dhisced2 dhisced345 dhisced6 bluehigh whitlow whithigh dbook2 dbook3 dbook4 comp_home otherlang"

	* SCHOOL LEVEL
		global schoolgen "dloc23 dloc45 numstudtotal"
		global teacher "cert_teachers"
		global shortage "shormat"
	global school "$schoolgen $teacher $shortage"
	
	* COUNTRY LEVEL
	global country "coo_lngdp_ave"
	
	* IMPUTATION DUMMIES
	global imp "imfemale image imotherlang imdhisced1 imwhithigh imdbook1 imcomp_home imdloc1 imnumstudtotal imcert_teachers imshormat"
	
	* ALL CONTROLS
	global all_controls "$indiv $school $country $imp"

	* FIXED EFFECTS
	global FE "i.countrywave"
	
	* PREFERENCES
	global preferences "coo_patience coo_risktaking coo_posrecip coo_negrecip coo_altruism coo_trust"
	
***************************** TABLE 2 **************************************
			
	use "$path/Data/Working\pisa_full_gps_final_imcoo.dta", clear
			
		reg pv1math coo_patience female age imfemale image coo_oecd $FE, vce(cluster coo)
		outreg2 using "$path/Results\T2.xls", label replace keep(coo_patience) e(N_clust) dec(3) nocons
		reg pv1math coo_risktaking female age imfemale image coo_oecd $FE, vce(cluster coo)
		outreg2 using "$path/Results\T2.xls", label append keep(coo_risktaking) e(N_clust) dec(3) nocons
		reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd $FE, vce(cluster coo)
		outreg2 using "$path/Results\T2.xls", label append keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
		reg pv1math $preferences female age imfemale image coo_oecd $FE, vce(cluster coo)
		outreg2 using "$path/Results\T2.xls", label append keep($preferences) e(N_clust) dec(3) nocons
		
		reg pv1math coo_patience coo_risktaking nonresp female age imfemale image coo_oecd $FE, vce(cluster coo)
		outreg2 using "$path/Results\T2.xls", label ctitle("Individual non-response") append keep(coo_patience coo_risktaking nonresp) e(N_clust) dec(3) nocons
		reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd $FE if !missing(mmnonresp), vce(cluster coo)
		outreg2 using "$path/Results\T2.xls", label ctitle("Subsample c-level non-response") append keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
		reg pv1math coo_patience coo_risktaking nonresp mmnonresp female age imfemale image coo_oecd $FE, vce(cluster coo)
		outreg2 using "$path/Results\T2.xls", label ctitle("Both non-response") append keep(coo_patience coo_risktaking nonresp mmnonresp) e(N_clust) dec(3) nocons

		reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd $FE if otherlang==0, vce(cluster coo)
		outreg2 using "$path/Results\T2.xls", label ctitle("Destination") append keep(coo_patience coo_risktaking)  e(N_clust) dec(3) nocons
		reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd $FE if otherlang==1, vce(cluster coo)
		outreg2 using "$path/Results\T2.xls", label ctitle("Other") append keep(coo_patience coo_risktaking) e(N_clust) dec(3) sortvar(coo_patience coo_risktaking coo_oecd) nocons
		
			*test for equality of patience & risk coefficients (col.5 vs col.6):
			preserve
			
				keep if inlist(otherlang,0,1)
				
				foreach var in coo_patience coo_risktaking female age imfemale image coo_oecd {
					gen `var'_otherlang=`var'*otherlang
				}
				
				tab countrywave, gen(dcntw)
				forvalues i=1(1)180 {
					gen dcntw`i'_otherlang=dcntw`i'*otherlang
				}


				reg pv1math otherlang coo_patience coo_risktaking female age imfemale image coo_oecd i.countrywave coo_patience_otherlang coo_risktaking_otherlang female_otherlang age_otherlang imfemale_otherlang image_otherlang coo_oecd_otherlang dcntw1_otherlang-dcntw180_otherlang, vce(cluster coo)
					test _b[otherlang] =0, notest
					test _b[coo_risktaking_otherlang] =0, accum
					test _b[otherlang] =0, notest
					test _b[coo_patience_otherlang] =0, accum
				
			restore
				
***************************** TABLE 3 **************************************
	
	reg pv1math coo_patience coo_risktaking female age i.cont imfemale image coo_oecd $FE, vce(cluster coo)
	outreg2 using "$path/Results\T3.xls", label ctitle("Incl. coo continent FE") replace keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
	reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd $FE patience_sd risktaking_sd, vce(cluster coo)
	outreg2 using "$path/Results\T3.xls", label ctitle("sd controls") append keep(coo_patience coo_risktaking patience_sd risktaking_sd) e(N_clust) dec(3) nocons
	reg pv1math coo_patience coo_risktaking female age imfemale image $FE coo_oecd dist, vce(cluster coo)
	outreg2 using "$path/Results\T3.xls", label ctitle("distance controls") append keep(coo_patience coo_risktaking dist) e(N_clust) dec(3) nocons		
	reg pv1math coo_patience coo_risktaking female age imfemale image $FE coo_oecd if !missing(patdist) & !missing(riskdist), vce(cluster coo)
	outreg2 using "$path/Results\T3.xls", label ctitle("cultural distance") append keep(coo_risktaking coo_patience) e(N_clust) dec(3) nocons
				
	preserve
		
		keep if !missing(patdist) & !missing(riskdist)
			
		foreach var in coo_patience coo_risktaking abs_patdist abs_riskdist patdist riskdist {
			qui sum `var'
			gen demean_`var'=`var'-r(mean)
		}
		
		reg pv1math demean_coo_patience c.demean_coo_patience#c.demean_abs_patdist demean_coo_risktaking c.demean_coo_risktaking#c.demean_abs_riskdist female age imfemale image $FE coo_oecd, vce(cluster coo)
		outreg2 using "$path/Results\T3.xls", label ctitle("cultural distance") append keep(demean_coo_patience c.demean_coo_patience#c.demean_abs_patdist demean_coo_risktaking c.demean_coo_risktaking#c.demean_abs_riskdist) e(N_clust) dec(3) nocons
		
	restore 
				
	reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd $FE if !missing(p), vce(cluster coo)
	outreg2 using "$path/Results\T3.xls", label ctitle("Selectivity") append keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
	reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd p $FE, vce(cluster coo)
	outreg2 using "$path/Results\T3.xls", label ctitle("Selectivity") append keep(coo_patience coo_risktaking p) e(N_clust) dec(3) nocons sortvar(coo_patience coo_risktaking patience_sd risktaking_sd dist demean_coo_patience demean_coo_risktaking demean_patdist c.demean_coo_patience#c.demean_patdist demean_riskdist c.demean_coo_risktaking#c.demean_riskdist p)
	
***************************** TABLE A4 **************************************
	
	reg pv1math coo_patience coo_risktaking age image coo_oecd $FE if female==1, vce(cluster coo)
	outreg2 using "$path/Results\TA4_mig.xls", label replace keep(coo_patience coo_risktaking) ctitle("Girls") e(N_clust) dec(3) nocons
	reg pv1math coo_patience coo_risktaking age image coo_oecd $FE if female==0, vce(cluster coo)
	outreg2 using "$path/Results\TA4_mig.xls", label append keep(coo_patience coo_risktaking) ctitle("Boys") e(N_clust) dec(3) nocons

***************************** TABLE A5 **************************************

	reg pv1math coo_patience coo_risktaking $all_controls coo_oecd $FE, vce(cluster coo)
	outreg2 using "$path/Results\TA5_mig.xls", label append keep(coo_patience coo_risktaking) e(N_clust) dec(3) sortvar($preferences coo_oecd) nocons

***************************** TABLE A7 **************************************
		
	reg pv1math coo_patience coo_risktaking female age imfemale image $FE if coo_oecd==1, vce(cluster coo)
	outreg2 using "$path/Results\TA7_mig.xls", label ctitle("OECD") replace keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
	reg pv1math coo_patience coo_risktaking female age imfemale image $FE if coo_oecd==0, vce(cluster coo)
	outreg2 using "$path/Results\TA7_mig.xls", label ctitle("Non-OECD") append keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
		
		*test for equality of patience & risk coefficients:
		foreach var in coo_patience coo_risktaking female age imfemale image {
			gen `var'_coecd=`var'*coo_oecd
		}
		
		tab countrywave, gen(dcntw)
		forvalues i=1(1)180 {
			gen dcntw`i'_coecd=dcntw`i'*coo_oecd
		}

		reg pv1math coo_oecd coo_patience coo_risktaking female age imfemale image i.countrywave coo_patience_coecd coo_risktaking_coecd female_coecd age_coecd imfemale_coecd image_coecd dcntw1_coecd-dcntw180_coecd, vce(cluster coo)
			test _b[coo_oecd] =0, notest
			test _b[coo_risktaking_coecd] =0, accum
			test _b[coo_oecd] =0, notest
			test _b[coo_patience_coecd] =0, accum
			
		drop *_coecd
		drop dcntw*

***************************** TABLE A8 **************************************	
	
	reg pv1scie coo_patience coo_risktaking female age imfemale image coo_oecd $FE, vce(cluster coo)
	outreg2 using "$path/Results\TA8_mig.xls", label ctitle("Science") replace keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
	reg pv1read coo_patience coo_risktaking female age imfemale image coo_oecd $FE, vce(cluster coo)
	outreg2 using "$path/Results\TA8_mig.xls", label ctitle("Reading") append keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
				
***************************** TABLE A9 **************************************
	
	reg pv1math coo_wvs_child_save coo_wvs_important_risk female age image imfemale coo_oecd $FE, vce(cluster coo)
	outreg2 using "$path/Results\TA9_mig.xls", label replace keep(coo_wvs_child_save coo_wvs_important_risk) e(N_clust) dec(3) nocons
	reg pv1math coo_hofstede_lto coo_hofstede_uai female age image imfemale coo_oecd $FE, vce(cluster coo)
	outreg2 using "$path/Results\TA9_mig.xls", label append keep(coo_hofstede_lto coo_hofstede_uai) e(N_clust) dec(3) nocons
	
***************************** TABLE A10 **************************************

	reg pv1math coo_patience coo_risktaking coo_oecd i.countrywave, vce(cluster coo)
	reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd i.countrywave, vce(cluster coo)
	*rmax is 0.36 (T2C3*1.3)
		
	psacalc delta coo_patience, mcontrol(coo_risktaking coo_oecd i.countrywave) rmax(0.36)			
	psacalc beta  coo_patience, mcontrol(coo_risktaking coo_oecd i.countrywave) rmax(0.36)
		
	psacalc delta coo_risktaking, mcontrol(coo_patience coo_oecd i.countrywave) rmax(0.36)					
	psacalc beta  coo_risktaking, mcontrol(coo_patience coo_oecd i.countrywave) rmax(0.36)

***************************** TABLE A11 **************************************
	
	reg pv1math coo_patience female age imfemale image coo_oecd i.country i.wave, vce(cluster coo)
	outreg2 using "$path/Results\TA11.xls", label replace keep(coo_patience) e(N_clust) dec(3) nocons
	reg pv1math coo_risktaking female age imfemale image coo_oecd i.country i.wave, vce(cluster coo)
	outreg2 using "$path/Results\TA11.xls", label append keep(coo_risktaking) e(N_clust) dec(3) nocons
	reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd i.country i.wave, vce(cluster coo)
	outreg2 using "$path/Results\TA11.xls", label append keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
	
***************************** TABLE A12 **************************************

	reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd $FE if migra1==0, vce(cluster coo)
	outreg2 using "$path/Results\TA12.xls", label ctitle("Second generation") replace keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
	reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd $FE if migra1==1, vce(cluster coo)
	outreg2 using "$path/Results\TA12.xls", label ctitle("First generation all") append keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
		
		*test for equality of patience & risk coefficients (col.1 vs col.2):
		foreach var in coo_patience coo_risktaking female age imfemale image coo_oecd {
			gen `var'_migra1=`var'*migra1
		}
		
		tab countrywave, gen(dcntw)
		forvalues i=1(1)180 {
			gen dcntw`i'_migra1=dcntw`i'*migra1
		}

		reg pv1math migra1 coo_patience coo_risktaking female age imfemale image coo_oecd i.countrywave coo_patience_migra1 coo_risktaking_migra1 female_migra1 age_migra1 imfemale_migra1 image_migra1 coo_oecd_migra1 dcntw1_migra1-dcntw180_migra1, vce(cluster coo)
			test _b[migra1] =0, notest
			test _b[coo_risktaking_migra1] =0, accum
			test _b[migra1] =0, notest
			test _b[coo_patience_migra1] =0, accum
			
		drop *_migra1
		drop dcntw*
		
	reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd $FE if migage<=6 & migra1==1 & !missing(migage), vce(cluster coo)
	outreg2 using "$path/Results\TA12.xls", label ctitle("Before age 6") append keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
	reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd $FE if migage>6 & migra1==1 & !missing(migage), vce(cluster coo)
	outreg2 using "$path/Results\TA12.xls", label ctitle("After age 6") append keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
		
		*test for equality of patience & risk coefficients (col.3 vs col.4):
		gen 	migage6=0 if !missing(migage) & migra1==1
		replace migage6=1 if migage>6 & !missing(migage) & migra1==1

		foreach var in coo_patience coo_risktaking female age imfemale image coo_oecd {
			gen `var'_migage6=`var'*migage6 if migra1==1
		}

		tab countrywave, gen(dcntw)
		forvalues i=1(1)180 {
			gen dcntw`i'_migage6=dcntw`i'*migage6 if migra1==1
		}


		reg pv1math migage6 coo_patience coo_risktaking female age imfemale image coo_oecd i.countrywave coo_patience_migage6 coo_risktaking_migage6 female_migage6 age_migage6 imfemale_migage6 image_migage6 coo_oecd_migage6 dcntw1_migage6-dcntw180_migage6 if migra1==1, vce(cluster coo)
			test _b[migage6] =0, notest
			test _b[coo_risktaking_migage6] =0, accum
			test _b[migage6] =0, notest
			test _b[coo_patience_migage6] =0, accum
			
		drop *_migage6
		drop dcntw*

***************************** TABLE A13 **************************************
	
	*** NARROW DEF. ***

	use "$path/Data/Working\pisa_full_gps_final_imcoobothm", clear
			
		reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd $FE, vce(cluster coo)
		outreg2 using "$path/Results\TA13.xls", label ctitle("Mothers origin") replace keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
		
	use "$path/Data/Working\pisa_full_gps_final_imcooavg.dta", clear
									
		reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd $FE, vce(cluster coo)			
		outreg2 using "$path/Results\TA13.xls", label ctitle("Average of both parents") append keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
		reg pv1math coom_patience coom_risktaking coof_patience coof_risktaking female age imfemale image coo_oecd $FE, vce(cluster coo)
		outreg2 using "$path/Results\TA13.xls", label ctitle("Both for both parents") append keep(coom_patience coof_patience coom_risktaking coof_risktaking) e(N_clust) dec(3) nocons

	*** WIDE DEF. ***

	use "$path/Data/Working\pisa_full_gps_final_coobothm", clear
				
		reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd $FE, vce(cluster coo)
		outreg2 using "$path/Results\TA13.xls", label ctitle("Mother") append keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
	
	use "$path/Data/Working\pisa_full_gps_final_coo", clear
				
		reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd $FE, vce(cluster coo)
		outreg2 using "$path/Results\TA13.xls", label ctitle("Father") append keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
				
	use "$path/Data/Working\pisa_full_gps_final_cooavg", clear	
				
		reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd $FE, vce(cluster coo)
		outreg2 using "$path/Results\TA13.xls", label ctitle("Average") append keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
		reg pv1math coom_patience coom_risktaking coof_patience coof_risktaking female age imfemale image coo_oecd $FE, vce(cluster coo)
		outreg2 using "$path/Results\TA13.xls", label ctitle("Both for both parents") append keep(coom_patience coof_patience coom_risktaking coof_risktaking) e(N_clust) dec(3) nocons

	*** ONLY COO WITH AT LEAST 50 OBS. ***
	
	use "$path/Data/Working\pisa_full_gps_final_imcoo.dta", clear
	
	preserve
	
		egen N_coo = count(studid), by(coo)	
		drop if N_coo<50
	
		reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd $FE, vce(cluster coo)
	outreg2 using "$path/Results\TA13.xls", label ctitle("Drop <50") append keep(coo_patience coo_risktaking) e(N_clust) dec(3) nocons
	
	restore

```

### `Replication/Do/1a1_2000.do`
```stata
use "$path/Data/Working/stsch_2000.dta", replace
	
	replace  age=age/12
	
	gen 	female = .
	replace female=1 if st03q01==1 
	replace female=0 if st03q01==2
		
	* parents' education *
	replace misced=. if inlist(misced,7,8,9)
	tab 	misced, gen(dmisced)
	replace fisced=. if inlist(fisced,7,8,9)
	tab 	fisced, gen(dfisced)
	gen 	hisced=misced
	replace hisced=fisced if missing(misced)
	replace hisced=fisced if fisced > misced & !missing(fisced)
	tab 	hisced, gen(dhisced)
		
		
	*parents' occupation *		
	destring st09q01, replace
	destring st11q01, replace

	gen 	occumoth=st09q01
	replace occumoth=. if st09q01==9997 |  st09q01==9998 |  st09q01==9999
	gen 	occufath=st11q01
	replace occufath=. if st11q01==9997 |  st11q01==9998 |  st11q01==9999
	
	gen 	mothwhithigh=0 if !missing(occumoth)
	replace mothwhithigh=1 if occumoth>=1000 & occumoth<4000
	gen 	fathwhithigh=0 if !missing(occufath)
	replace fathwhithigh=1 if occufath>=1000 & occufath<4000
	gen 	mothwhitlow=0 if !missing(occumoth)
	replace mothwhitlow=1 if (occumoth>=4000&occumoth<6000)|occumoth<1000
	gen 	fathwhitlow=0 if !missing(occufath)
	replace fathwhitlow=1 if (occufath>=4000&occufath<6000)|occufath<1000
	gen 	mothbluehigh=0 if !missing(occumoth)
	replace mothbluehigh=1 if occumoth>=6000 & occumoth<8000
	gen 	fathbluehigh=0 if !missing(occufath)
	replace fathbluehigh=1 if occufath>=6000 & occufath<8000
	gen 	mothbluelow=0 if !missing(occumoth)
	replace mothbluelow=1 if occumoth>=8000 & occumoth<9997
	gen 	fathbluelow=0 if !missing(occufath)
	replace fathbluelow=1 if occufath>=8000 & occufath<9997


	* create highest occupational status of parents
	gen 	whithigh=0 if !missing(mothwhithigh) | !missing(fathwhithigh)
	replace whithigh=1 if mothwhithigh==1 | fathwhithigh==1
	gen 	whitlow=0 if !missing(mothwhitlow) | !missing(fathwhitlow)
	replace whitlow=1 if mothwhitlow==1 & whithigh!=1 | fathwhitlow==1 & whithigh!=1
	gen 	bluehigh=0 if !missing(mothbluehigh) | !missing(fathbluehigh)
	replace bluehigh=1 if mothbluehigh==1 & whitlow!=1 & whithigh!=1 | fathbluehigh==1 & whitlow!=1 & whithigh!=1
	gen 	bluelow=0 if !missing(mothbluelow) | !missing(fathbluelow)
	replace bluelow=1 if mothbluelow==1 &  bluehigh!=1 & whitlow!=1 & whithigh!=1 | fathbluelow==1 & bluehigh!=1 & whitlow!=1 & whithigh!=1


	********************
	* Immigrant status *
	********************
	
		* student born in country *
		gen 	stubrncnt=.
		replace stubrncnt = 1 if st16q01==1 /* student born in test country*/
		replace stubrncnt = 0 if st16q01==2

		* father born in coutry *
		gen 	fatbrncnt = .
		replace fatbrncnt = 1 if st16q03==1 /* father born in test country*/
		replace fatbrncnt = 0 if st16q03==2
			
		* mother born in country *
		gen 	motbrncnt = .
		replace motbrncnt = 1 if st16q02==1 /* mother born in test country*/	
		replace motbrncnt = 0 if st16q02==2
		
		foreach v of varlist stubrncnt fatbrncnt motbrncnt {
			recode `v' (2 = 0) (1 = 1)
			replace `v' = . if `v' >= 97
		}

		*first generation: student born abroad (stubrncnt==1) with both parents born abroad
		gen 	im1=0
		replace im1=1 if motbrncnt==0 & fatbrncnt==0 & stubrncnt==0 
		replace im1=. if missing(motbrncnt) & missing(fatbrncnt) | missing(stubrncnt)

		*second generation: student born in test country AND both parents born abroad
		gen 	im2=0
		replace im2=1 if motbrncnt==0 & fatbrncnt==0  & stubrncnt==1
		replace im2=. if missing(motbrncnt) & missing(fatbrncnt) | missing(stubrncnt)
		

	***************************
	* Language spoken at home *
	***************************
	
		gen 	stulanguage=.
		replace stulanguage =1 if st17q01==1            /* testlang */
		replace stulanguage =2 if st17q01==2			/* other official language*/
		replace stulanguage =3 if st17q01==3            /* national dialect */
		replace stulanguage =4 if st17q01==4			/* other language*/

		gen 	otherlang=0 if stulanguage!=.
		replace otherlang=1 if stulanguage==2 | stulanguage==4

	
	*********************
	* Family Ressources *
	*********************
	
		*books at home*
		
			gen books = st37q01   

			foreach num of numlist 1/4{
				gen dbook`num'=0 if books!=.
			}
			
			replace dbook1=1 if books==1 | books==2
			replace dbook2=1 if books==3 | books==4
			replace dbook3=1 if books==5 | books==6
			replace dbook4=1 if books==7
		
		*computers*
				
			gen 	comp_home=st22q04
			label var comp_home "Computer at home"
			recode  comp_home (1=0) (2=1) (3=1) (4=1)

	**************************
	* location of the school *
	**************************
	
		gen 	schoolloc=sc01q01				
		tab 	schoolloc, gen(dloc)
		replace dloc5=1 if dloc6==1
		drop 	dloc6

	**********************
	* Number of students *
	**********************
	
		*boys
		gen 	numstudmale=sc02q01
		replace numstudmale=. if sc02q01>9000
		*girls
		gen 	numstudfemale=sc02q02
		replace numstudfemale=. if sc02q02>9000
		*total
		gen 	numstudtotal=numstudfemale+numstudmale if !missing(numstudfemale) & !missing(numstudmale)

	**************
	* Management *
	**************
	
		gen 	private=0 if sc03q01==1 	/*sc03q01: 1=public, 2=private*/
		replace private=1 if sc03q01==2

	**************************************
	* Share of school financing by [...] *
	**************************************
	
		replace sc04q01=. if sc04q01>100
		gen schoolbudgetgov  = sc04q01/100
		
	**********************
	* Certified Teachers *
	**********************
	
		gen 	cert_teachers=propcert
		recode 	cert_teachers (9997=.) (9998=.) (9999=.) (.m=.)
		replace cert_teachers=. if cert_teachers>1
		* requires combination of isced 5a BA / MA / 6 quali		
		
	*******************************************
	* Availability of infrastructure/material *
	*******************************************
	
		* lack of educational materials
		gen 	shormat=0 	if   sc11q04==1 | sc11q04==2
		replace shormat=1 	if   sc11q04==3 | sc11q04==4
			
		gen 	nomatshort=0 	if !missing(sc11q04)
		replace nomatshort=1 	if sc11q04==1
		gen 	largematshort=0 if !missing(sc11q04)
		replace largematshort=1 if sc11q04==4

	************
	* Autonomy *
	************
	
		*NOT AT SCHOOL LEVEL
		*choosing textbooks
		gen str1  respnotschtxtbook=substr(sc22q10,1,1)	
		*determining course content
		gen str1  respnotschcontent=substr(sc22q11,1,1)
		*which courses are offered 
		gen str1  respnotschcourses=substr(sc22q12,1,1)

		foreach x of varlist (respnotschcontent respnotschtxtbook respnotschcourses){
			replace `x'="." if `x'=="7" | `x'=="8" | `x'=="9" | `x'=="N"
			destring `x', replace
		}
		
		gen 	auttextbook = 1- respnotschtxtbook	
		gen 	autcontent  = 1- respnotschcontent
		gen 	autcourses  = 1- respnotschcourses			

		rename wnrschbw scweight			

	gen wave=2000

	gen oecd=.
		replace	oecd	=	0	if	cnt	==	"ALB"
		replace	oecd	=	0	if	cnt	==	"ARG"
		replace	oecd	=	1	if	cnt	==	"AUS"
		replace	oecd	=	1	if	cnt	==	"AUT"
		replace	oecd	=	1	if	cnt	==	"BEL"
		replace	oecd	=	0	if	cnt	==	"BGR"
		replace	oecd	=	0	if	cnt	==	"BRA"
		replace	oecd	=	1	if	cnt	==	"CAN"
		replace	oecd	=	1	if	cnt	==	"CHE"
		replace	oecd	=	0	if	cnt	==	"CHL"
		replace	oecd	=	1	if	cnt	==	"CZE"
		replace	oecd	=	1	if	cnt	==	"DEU"
		replace	oecd	=	1	if	cnt	==	"DNK"
		replace	oecd	=	1	if	cnt	==	"ESP"
		replace	oecd	=	1	if	cnt	==	"FIN"
		replace	oecd	=	1	if	cnt	==	"FRA"
		replace	oecd	=	1	if	cnt	==	"GBR"
		replace	oecd	=	1	if	cnt	==	"GRC"
		replace	oecd	=	0	if	cnt	==	"HKG"
		replace	oecd	=	1	if	cnt	==	"HUN"
		replace	oecd	=	0	if	cnt	==	"IDN"
		replace	oecd	=	1	if	cnt	==	"IRL"
		replace	oecd	=	1	if	cnt	==	"ISL"
		replace	oecd	=	0	if	cnt	==	"ISR"
		replace	oecd	=	1	if	cnt	==	"ITA"
		replace	oecd	=	1	if	cnt	==	"JPN"
		replace	oecd	=	1	if	cnt	==	"KOR"
		replace	oecd	=	0	if	cnt	==	"LIE"
		replace	oecd	=	1	if	cnt	==	"LUX"
		replace	oecd	=	0	if	cnt	==	"LVA"
		replace	oecd	=	1	if	cnt	==	"MEX"
		replace	oecd	=	0	if	cnt	==	"MKD"
		replace	oecd	=	1	if	cnt	==	"NLD"
		replace	oecd	=	1	if	cnt	==	"NOR"
		replace	oecd	=	1	if	cnt	==	"NZL"
		replace	oecd	=	0	if	cnt	==	"PER"
		replace	oecd	=	1	if	cnt	==	"POL"
		replace	oecd	=	1	if	cnt	==	"PRT"
		replace	oecd	=	0	if	cnt	==	"ROM"
		replace	oecd	=	0	if	cnt	==	"RUS"
		replace	oecd	=	1	if	cnt	==	"SWE"
		replace	oecd	=	0	if	cnt	==	"THA"
		replace	oecd	=	1	if	cnt	==	"TUR"
		replace	oecd	=	1	if	cnt	==	"USA"

#delimit;
keep pv1read pv1scie pv*math
	 age female
	 whithigh whitlow bluehigh bluelow dhisced*
	 im1 im2 stubrncnt motbrncnt fatbrncnt otherlang
	 dbook* comp_home
		 dloc* numstudtotal private schoolbudget*
		 cert_teachers shormat auttextbook autcontent autcourses
			oecd w_fstuwt w_fstr* wave cnt country schoolid studid;
#delimit cr

compress

save "$path/Data/Working/stsch_2000_renamed.dta", replace

	foreach x in math scie read  {
		erase "$path/Data/Working/stsch_`x'_2000.dta"
		erase "$path/Data/Working/intstud_`x'_sorted.dta"
	}
		erase "$path/Data/Working/stsch_2000.dta"

```

### `Replication/Do/1a2_2003.do`
```stata
use "$path/Data/Working/stsch_2003.dta", replace

		rename *, lower
		
		gen 	female = .
		replace female=1 if st03q01==1  // female 
		replace female=0 if st03q01==2  // male
		
	**********************
	* Parents' education *
	**********************
		tab 	misced, gen(dmisced)
		replace dmisced6=1 if dmisced7==1
		drop 	dmisced7

		tab 	fisced, gen(dfisced)
		replace dfisced6=1 if dfisced7==1
		drop 	dfisced7

		replace hisced=. if inlist(hisced,7,8,9)
		tab 	hisced, gen(dhisced)
		replace dhisced6=1 if dhisced7==1
		drop 	dhisced7


	****************
	* Parents' job *
	****************

		destring st07q01 , replace
		destring st09q01 , replace

		gen 	occumoth=st07q01
		replace occumoth=. if st07q01==9997 |  st07q01==9998 |  st07q01==9999
		gen 	occufath=st09q01
		replace occufath=. if st09q01==9997 |  st09q01==9998 |  st09q01==9999


		gen 	mothwhithigh=0 if !missing(occumoth)
		replace mothwhithigh=1 if occumoth>=1000 & occumoth<4000
		gen 	fathwhithigh=0 if !missing(occufath)
		replace fathwhithigh=1 if occufath>=1000 & occufath<4000 
		gen 	mothwhitlow=0 if !missing(occumoth)
		replace mothwhitlow=1 if occumoth>=4000 & occumoth<6000 | occumoth<1000
		gen 	fathwhitlow=0 if !missing(occufath)
		replace fathwhitlow=1 if occufath>=4000 & occufath<6000 | occufath<1000
		gen 	mothbluehigh=0 if !missing(occumoth)
		replace mothbluehigh=1 if occumoth>=6000 & occumoth<8000
		gen 	fathbluehigh=0 if !missing(occufath)
		replace fathbluehigh=1 if occufath>=6000 & occufath<8000
		gen 	mothbluelow=0 if !missing(occumoth)
		replace mothbluelow=1 if occumoth>=8000 & occumoth<9997
		gen 	fathbluelow=0 if !missing(occufath)
		replace fathbluelow=1 if occufath>=8000 & occufath<9997

		* create highest occupational status of parents
		gen 	whithigh=0 if mothwhithigh!=. | fathwhithigh!=.
		replace whithigh=1 if mothwhithigh==1 | fathwhithigh==1
		gen 	whitlow=0 if mothwhitlow!=. | fathwhitlow!=.
		replace whitlow=1 if mothwhitlow==1 & whithigh!=1 | fathwhitlow==1 & whithigh!=1
		gen 	bluehigh=0 if mothbluehigh!=. | fathbluehigh!=.
		replace bluehigh=1 if mothbluehigh==1 & whitlow!=1 & whithigh!=1| fathbluehigh==1 & whitlow!=1 & whithigh!=1
		gen 	bluelow=0 if mothbluelow!=. | fathbluelow!=.
		replace bluelow=1 if mothbluelow==1 &  bluehigh!=1 & whitlow!=1 & whithigh!=1 | fathbluelow==1 & bluehigh!=1 & whitlow!=1 & whithigh!=1

		drop 	mothwhit* fathwhit* mothblue* fathblue*


	********************
	* Immigrant status *
	********************
		* Student born in country *
		gen 	stubrncnt=.
		replace stubrncnt = 1 if   st15q01==1 /* student born in test country*/
		replace stubrncnt = 0 if   st15q01==2

		* father born in country *
		gen 	fatbrncnt = .
		replace fatbrncnt = 1 if  st15q03==1 /* father born in test country*/
		replace fatbrncnt = 0 if  st15q03== 2

		* mother born in country *
		gen 	motbrncnt = .
		replace motbrncnt = 1 if   st15q02==1 /* mother born in test country*/
		replace motbrncnt = 0 if  st15q02 == 2
		

		*first generation: born abroad (stubrncnt==1) with parents born abroad
		gen 	im1=0
		replace im1=1 if motbrncnt==0 & fatbrncnt==0 & stubrncnt==0 
		replace im1=. if missing(motbrncnt) & missing(fatbrncnt) | missing(stubrncnt)

		*second generation: born in country of test language, parents born abrod
		gen 	im2=0
		replace im2=1 if motbrncnt==0  & fatbrncnt==0  & stubrncnt==1
		replace im2=. if missing(motbrncnt) & missing(fatbrncnt) | missing(stubrncnt)
				
		* countries of birth for Figlio analysis
		rename iso_m bcntry_m
		rename iso_f bcntry_f
		rename iso_s bcntry
		
		label define bcntry ///
			3608261 "England" ///
			3608262	"Scotland" ///
			3609996	"Other" ///
			4000391	"Yugoslavia" ///
			4009996	"Other" ///
			5610021	"An African country (not Maghreb)" ///
			5610151	"A Maghreb country" ///
			5611501	"An other country of the EU" ///
			5619996	"Other" ///
			5620021	"An African country (not Maghreb)" ///
			5620151	"A Maghreb country" ///
			5621501	"Another country of the EU" ///
			5629996	"Other" ///
			7609996	"Other" ///
			12419996	"Other" ///
			12429996	"Other" ///
			12439996	"Other" ///
			20309996	"Other" ///
			20800391	"The former Yugoslavia" ///
			20809996	"Other" ///
			24609996	"Other" ///
			25009996	"Other" ///
			27601501	"Russia, Kazakhstan or another former Soviet republic" ///
			27608911	"Montenegro" ///
			27608912	"Serbia" ///
			27609996	"Other" ///
			30001501	"Country that belonged to the USSR" ///
			30009996	"Other" ///
			34409996	"Other" ///
			34809996	"Other" ///
			35209996	"Other" ///
			36009996	"Other" ///
			37200701	"Bosnia" ///
			37203761	"Palestine" ///
			37208261	"Northern Ireland" ///
			37208262	"Great Britain" ///
			37209996	"Other" ///
			38001501	"In an European country that is not member of the EU" ///
			38009996	"Other" ///
			39209996	"Other" ///
			41009996	"Other" ///
			42809996	"Other" ///
			44209996	"Other" ///
			44609996	"Other" ///
			48409996	"Other" ///
			52801501	"Other European country" ///
			52809996	"Other" ///
			55409996	"Other" ///
			57809996	"Other" ///
			61609996	"Other" ///
			62009996	"Other" ///
			64301501	"Former USSR republics" ///
			64309996	"Other" ///
			70301501	"In other country of Europe" ///
			70309996	"Other" ///
			72419996	"Other" ///
			72429996	"Other" ///
			72439996	"Other" ///
			72449996	"Other" ///
			75209996	"Other" ///
			75600391	"Ex-Yugoslavia" ///
			75600392	"Albania or Kosovo" ///
			75601551	"Germany or Austria" ///
			75601552	"France or Belgium" ///
			75607560	"Switzerland" ///
			75609996	"Other" ///
			76409996	"Other" ///
			78809996	"Other" ///
			79209996	"Other" ///
			82619996	"Other" ///
			82620301	"China (incl Hong Kong)" ///
			82621421	"Middle East" ///
			82621501	"Other European country" ///
			82628261	"England, Wales, N Ireland" ///
			82628262	"Scotland" ///
			82629996	"Other" ///
			84009996	"Other" ///
			85809996	"Other" ///
			89101491	"The former Yugoslavia" ///
			89109996	"Other" ///
			99990020	"Africa" ///
			99990080	"Albania" ///
			99990290	"Caribbean" ///
			99990320	"Argentina" ///
			99990360	"Australia" ///
			99990400	"Austria" ///
			99990500	"Bangladesh" ///
			99990560	"Belgium" ///
			99990600	"Bermuda" ///
			99990700	"Bosnia-Herzegovina" ///
			99990760	"Brazil" ///
			99991000	"Bulgaria" ///
			99991040	"Myanmar (Burma)" ///
			99991120	"Belarus" ///
			99991240	"Canada" ///
			99991440	"Sri Lanka" ///
			99991490	"Ex-Yugoslavia" ///
			99991510	"An East-European country" ///
			99991560	"China" ///
			99991840	"Cook Islands" ///
			99991910	"Croatia" ///
			99992030	"Czech Republic" ///
			99992080	"Denmark" ///
			99992330	"Estonia" ///
			99992420	"Fiji" ///
			99992460	"Finland" ///
			99992500	"France" ///
			99992680	"Georgia" ///
			99992760	"Germany" ///
			99993000	"Greece" ///
			99993440	"Hong Kong" ///
			99993480	"Hungary" ///
			99993520	"Iceland" ///
			99993560	"India" ///
			99993600	"Indonesia" ///
			99993640	"Iran" ///
			99993680	"Iraq" ///
			99993720	"Ireland" ///
			99993800	"Italy" ///
			99993880	"Jamaica" ///
			99993920	"Japan" ///
			99994000	"Jordan" ///
			99994100	"Korea" ///
			99994220	"Lebanon" ///
			99994280	"Latvia" ///
			99994340	"Libya" ///
			99994400	"Lithuania" ///
			99994420	"Luxembourg" ///
			99994460	"Macau" ///
			99994580	"Malaysia" ///
			99994840	"Mexico" ///
			99995160	"Namibia" ///
			99995280	"Netherlands" ///
			99995540	"New Zealand" ///
			99995660	"Nigeria" ///
			99995780	"Norway" ///
			99995860	"Pakistan" ///
			99996080	"Philippines" ///
			99996160	"Poland" ///
			99996200	"Portugal" ///
			99996420	"Romania" ///
			99996430	"Russia" ///
			99996820	"Saudi Arabia" ///
			99997030	"Slovakia" ///
			99997040	"Vietnam" ///
			99997050	"Slowenia" ///
			99997100	"South Africa" ///
			99997160	"Zimbabwe" ///
			99997240	"Spain" ///
			99997520	"Sweden" ///
			99997560	"Switzerland" ///
			99997640	"Thailand" ///
			99997760	"Tonga" ///
			99997880	"Tunisia" ///
			99997920	"Turkey" ///
			99998040	"Ukraine" ///
			99998070	"Macedonia" ///
			99998180	"Egypt" ///
			99998260	"United Kingdom" ///
			99998340	"Tanzania" ///
			99998400	"United States" ///
			99998580	"Uruguay" ///
			99998820	"Samoa" ///
			99998910	"Yugoslavia" ///
			99998940	"Zambia" ///
			99999970 "N/A" ///
			99999980 "Invalid" ///
			99999990 "Missing" 
			
		cap ssc install sdecode
			
		foreach v of varlist bcntry* {
			destring `v', replace
			label values `v' bcntry
			replace `v' = . if `v' == 99999970 |`v' == 99999980 | `v' == 99999990
			sdecode `v', replace
		}

		
		foreach v of varlist bcntry* {
			replace `v'="" if  `v'=="A Maghreb country"
			replace `v'="" if  `v'=="Africa" 
			replace `v'="" if  `v'=="An African country (not Maghreb)"
			replace `v'="" if  `v'=="An East-European country"
			replace `v'="" if  `v'=="An other country of the EU"
			replace `v'="" if  `v'=="Another country of the EU"
			replace `v'="" if  `v'=="Caribbean" 
			replace `v'="" if  `v'=="Country that belonged to the USSR"
			replace `v'="" if  `v'=="Former USSR republics"
			replace `v'="" if  `v'=="France or Belgium"
			replace `v'="" if  `v'=="Germany or Austria"
			replace `v'="" if  `v'=="In an European country that is not member of the EU"
			replace `v'="" if  `v'=="In other country of Europe"
			replace `v'="" if  `v'=="Middle East"			 
			replace `v'="" if  `v'=="Other"
			replace `v'="" if  `v'=="Other European country"
			replace `v'="" if  `v'=="Russia, Kazakhstan or another former Soviet republic" 			
		}
		
		
	**********************************
	* Age of arrival in test country *
	**********************************
	
		gen 	migage=.
		replace migage=st15q04
		replace migage=. if migage>age & !missing(migage)
		

	***************************
	* Language spoken at home *
	***************************
	
		gen 	stulanguage=.
		replace stulanguage=1 if st16q01==1         /* testlanguage */
		replace stulanguage=2 if st16q01==2			/* other national dialect  */ 
		replace stulanguage=3 if st16q01==3         /* other national language */
		replace stulanguage=4 if st16q01==4			/* other language */
	
		gen 	otherlang=0 if stulanguage!=.
		replace otherlang=1 if stulanguage==2 | stulanguage==4

	*********************
	* Family Ressources *
	*********************
	
		*books at home*
			gen books = st19q01                             

			foreach num of numlist 1/4{
				gen dbook`num'=0 if books!=.
			}
			
			replace dbook1=1 if books==1 
			replace dbook2=1 if books==2| books==3
			replace dbook3=1 if books==4| books==5
			replace dbook4=1 if books==6
			
		*computers*

			gen 	  comp_home=st17q04 
			label var comp_home "Computer at home"
			recode 	  comp_home (2=0)

		compress

	**************************
	* location of the school *
	**************************
		gen schoolloc=sc01q01
		tab schoolloc, gen(dloc)
		
	**********************
	* number of students *
	**********************
		*boys
		gen 	numstudmale=sc02q01
		replace numstudmale=. if sc02q01>9000
		*girls
		gen 	numstudfemale=sc02q02
		replace numstudfemale=. if sc02q02>9000
		*total
		gen 	numstudtotal=numstudfemale+numstudmale if !missing(numstudfemale) & !missing(numstudmale)

	**************
	* Management *
	**************
		gen 	private=0 if sc03q01==1		/*sc03q01: 1=public, 2=private*/
		replace private=1 if sc03q01 ==2
		
		* one could use the existing variable schltype here:
		gen 	priv=.
		replace priv=0 if schltype==3
		replace priv=1 if schltype==1 | schltype==2

	**************************************
	* Share of school financing by [...] *
	**************************************
	
		replace sc04q01 =. if sc04q01>100
		gen schoolbudgetgov  = sc04q01/100
			
	*************************
	* teacher certification *
	*************************
		gen 	cert_teachers=propcert
		recode 	cert_teachers (9997=.) (9998=.) (9999=.) (.m=.)
		* requires combination of isced 5a BA / MA / 6 quali
			
	*******************************************
	* Availability of infrastructure/material *
	*******************************************
	
		gen 	shormat=0 if  sc08q09==1 | sc08q09==2 //| sc08q10==1 | sc08q10==2
		replace shormat=1 if  sc08q09==3 | sc08q09==4 //| sc08q10==3 | sc08q10==4
			
	************
	* autonomy *
	************

		*not at school level
		*choosing textbooks
		gen str1 respnotschtxtbook=substr(sc26q10,1,1)
		*determining course content
		gen str1 respnotschcontent=substr(sc26q11,1,1)
		*which courses are offered
		gen str1 respnotschcourses=substr(sc26q12,1,1)


		foreach x of varlist (respnotschtxtbook respnotschcontent respnotschcourses){
			replace `x'="." if `x'=="7" | `x'=="8" | `x'=="9" | `x'=="N"
			destring `x', replace
			replace `x'=0 if `x'==2
		}
		
		gen 	auttextbook = 1- respnotschtxtbook	
		gen 	autcontent  = 1- respnotschcontent
		gen 	autcourses  = 1- respnotschcourses
		replace auttextbook=. if missing(respnotschtxtbook)
		replace autcontent=.  if missing(respnotschcontent)
		replace autcourses=.  if missing(respnotschcourses)
		
		
	gen wave=2003

*** drop vars not needed

#delimit;
keep pv1read pv1scie pv*math
	 age female
	 whithigh whitlow bluehigh bluelow dhisced*
	 im1 im2 otherlang migage stubrncnt motbrncnt fatbrncnt bcntry*
	 dbook* comp_home
		 dloc* numstudtotal private schoolbudgetgov
		 cert_teachers shormat auttextbook autcontent autcourses
			oecd w_fstuwt w_fstr* wave cnt country schoolid studid
;
#delimit cr

compress	
save "$path/Data/Working/stsch_2003_renamed.dta", replace
	erase "$path/Data/Working/stsch_2003.dta"

```

### `Replication/Do/1a3_2006.do`
```stata
use "$path/Data/Working/stsch_2006.dta", replace

	rename *, lower

	gen 	female=.
	replace female=1 if st04q01==1 /* weiblich */
	replace female=0 if st04q01==2  /* maennlich*/
	

	**********************
	* Parents' education *
	**********************
	
		tab 	misced, gen(dmisced)
		replace dmisced6=1 if dmisced7==1
		drop 	dmisced7

		tab 	fisced, gen(dfisced)
		replace dfisced6=1 if dfisced7==1
		drop 	dfisced7

		replace hisced=. if inlist(hisced,7,8,9)
		tab hisced, gen(dhisced)
		replace dhisced6=1 if dhisced7==1
		drop 	dhisced7

	****************
	* Parents' job *
	****************

		gen 	occumoth=msecateg
		replace occumoth=. if occumoth==9 /*missings */
		tab 	occumoth, gen(mocc)

		rename 	mocc1 mothwhithigh
		rename 	mocc2 mothwhitlow
		rename 	mocc3 mothbluehigh
		rename 	mocc4 mothbluelow

		gen 	occufath=fsecateg
		replace occufath=. if occufath==9 /*missings */
		tab 	occufath, gen(focc)
	
		rename  focc1 fathwhithigh
		rename 	focc2 fathwhitlow
		rename 	focc3 fathbluehigh
		rename 	focc4 fathbluelow

		gen 	whithigh=0 if mothwhithigh!=. | fathwhithigh!=.
		replace whithigh=1 if mothwhithigh==1 | fathwhithigh==1
		gen 	whitlow=0 if mothwhitlow!=. | fathwhitlow!=.
		replace whitlow=1 if mothwhitlow==1 & whithigh!=1 | fathwhitlow==1 & whithigh!=1
		gen 	bluehigh=0 if mothbluehigh!=. | fathbluehigh!=.
		replace bluehigh=1 if mothbluehigh==1 & whitlow!=1 & whithigh!=1| fathbluehigh==1 & whitlow!=1 & whithigh!=1
		gen 	bluelow=0 if mothbluelow!=. | fathbluelow!=.
		replace bluelow=1 if mothbluelow==1 &  bluehigh!=1 & whitlow!=1 & whithigh!=1 | fathbluelow==1 & bluehigh!=1 & whitlow!=1 & whithigh!=1

		drop mothwhit* fathwhit* mothblue* fathblue*

		
	********************
	* Immigrant status *
	********************
		* student born in country *
		gen 	stubrncnt=.
		replace stubrncnt = 1 if  st11q01==1 /* student born in test country*/
		replace stubrncnt = 0 if  st11q01==2

		* father born in coutry *
		gen 	fatbrncnt = .
		replace fatbrncnt = 1 if  st11q03==1 /* father born in test country*/
		replace fatbrncnt = 0 if  st11q03==2

		* mother born in country *
		gen 	motbrncnt = .
		replace motbrncnt = 1 if   st11q02==1 /* mother born in test country*/
		replace motbrncnt = 0 if   st11q02==2
		
		foreach v of varlist stubrncnt fatbrncnt motbrncnt {
			recode `v' (2 = 0) (1 = 1)
			replace `v' = . if `v' >= 97
		}

		* first generation: born abroad (stubrncnt==1) with parents born abroad
		gen 	im1=0
		replace im1=1 if motbrncnt==0 & fatbrncnt==0 & stubrncnt==0 
		replace im1=. if missing(motbrncnt) & missing(fatbrncnt) | missing(stubrncnt)

		* second generation: born in country of test language, parent(s) born abrod
		gen 	im2=0
		replace im2=1 if motbrncnt==0  & fatbrncnt==0  & stubrncnt==1
		replace im2=. if missing(motbrncnt) & missing(fatbrncnt) | missing(stubrncnt)
				
		rename cobn_m bcntry_m
		rename cobn_f bcntry_f
		rename cobn_s bcntry
		
		label define bcntry ///
			00020  "Africa" ///
			00021  "A Sub-Saharan country (Africa excl. Maghreb)" ///
			00080  "Albania" ///
			00110  "Cap Verde (in Western Africa)" ///
			00150  "North African country (Maghreb)" ///
			00290  "Caribbean" ///
			00310  "Azerbaijan" ///
			00320  "Argentina" ///
			00360  "Australia" ///
			00361  "England" ///
			00400  "Austria" ///
			00500  "Bangladesh" ///
			00560  "Belgium" ///
			00680  "Bolivia" ///
			00700  "Bosnia and Herzegovina" ///
			00760  "Brazil" ///
			01000  "Bulgaria" ///
			01120  "Belarus" ///
			01240  "Canada" ///
			01451  "Middle Eastern country" ///
			01510  "An Eastern European country" ///
			01520  "Chile" ///
			01560  "China" ///
			01561  "China (incl. HongKong)" ///
			01580  "Chinese Taipei" ///
			01700  "Colombia" ///
			01910  "Croatia" ///
			02030  "Czech Republic" ///
			02080  "Denmark" ///
			02330  "Estonia" ///
			02460  "Finland" ///
			02500  "France" ///
			02750  "Occupied Palestinian Territory" ///
			02760  "Germany" ///
			03000  "Greece" ///
			03440  "Hong Kong-China" ///
			03480  "Hungary" ///
			03520  "Iceland" ///
			03560  "India" ///
			03600  "Indonesia" ///
			03720  "Republic of Ireland" ///
			03760  "Israel" ///
			03800  "Italy" ///
			03920  "Japan" ///
			04000  "Jordan" ///
			04100  "Republic of Korea" ///
			04170  "Kyrgyzstan" ///
			04280  "Latvia" ///
			04380  "Liechtenstein" ///
			04400  "Lithuania" ///
			04420  "Luxembourg" ///
			04460  "Macao-China" ///
			04461  "Mainland China" ///
			04580  "Malaysia" ///
			04840  "Mexico" ///
			05280  "Netherlands" ///
			05540  "New Zealand" ///
			05780  "Norway" ///
			05860  "Pakistan" ///
			06000  "Paraguay" ///
			06080  "Philippines" ///
			06160  "Poland" ///
			06200  "Portugal" ///
			06340  "Qatar" ///
			06420  "Romania" ///
			06430  "Russian Federation" ///
			07020  "Singapore" ///
			07030  "Slovakia" ///
			07050  "Slovenia" ///
			07100  "South Africa" ///
			07240  "Spain" ///
			07241  "Andalusia (in Spain)" ///
			07242  "Aragon (in Spain)" ///
			07243  "Asturias (in Spain)" ///
			07244  "Balearic Islands (in Spain)" ///
			07245  "Canary Islands (in Spain)" ///
			07246  "Cantabria (in Spain)" ///
			07247  "Castile-La Mancha (in Spain)" ///
			07248  "Castile and Leon (in Spain)" ///
			07249  "Catalonia (in Spain)" ///
			07251  "Extremadura (in Spain)" ///
			07252  "Galicia (in Spain)" ///
			07253  "La Rioja (in Spain)" ///
			07254  "Madrid (in Spain)" ///
			07255  "Murcia (in Spain)" ///
			07256  "Navarre (in Spain)" ///
			07257  "Basque Country (in Spain)" ///
			07258  "Valencian Community (in Spain)" ///
			07259  "Ceuta and Melilla (in Spain)" ///
			07520  "Sweden" ///
			07560  "Switzerland" ///
			07620  "Tajikistan" ///
			07640  "Thailand" ///
			07880  "Tunisia" ///
			07920  "Turkey" ///
			08040  "Ukraine" ///
			08070  "Former Yugoslav Republic of Macedonia" ///
			08100  "A former USSR republic" ///
			08101  "Another former USSR republic (RUS)" ///
			08102  "Another former USSR republic (EST)" ///
			08180  "Egypt" ///
			08260  "United Kingdom" ///
			08261  "United Kingdom (excl.Scotland)" ///
			08262  "United Kingdom (Scotland)" ///
			08263  "Northern Ireland" ///
			08264  "Great Britain" ///
			08400  "United States" ///
			08580  "Uruguay" ///
			08600  "Uzbekistan" ///
			08820  "Samoa" ///
			08870  "Yemen" ///
			08900  "A former Yugoslav republic" ///
			08910  "Serbia-Montenegro" ///
			08911  "Serbia" ///
			08912  "Montenegro" ///
			10560  "Other Western European country (BEL)" ///
			11910  "Another former Yugoslav republic (HRV)" ///
			13800  "Other European Union Country (ITA)" ///
			14420  "Other European Union Country (LUX)" ///
			15280  "Other European country (NLD)" ///
			16200  "African country with Portuguese as the official language" ///
			18262  "Other European country (QSC)" ///
			18911  "One of the other former Yugoslav republics (SRB)" ///
			23800  "A European country that is not a member of the European Union" ///
			26200  "Other European Union Country (PRT)" ///
			36200  "An Eastern European country outside the EU" ///
			90310  "Other countries (AZE)" ///
			90320  "Other countries (ARG)" ///
			90360  "Other countries (AUS)" ///
			90400  "Other countries (AUT)" ///
			90560  "Other countries (BEL)" ///
			90760  "Other countries (BRA)" ///
			91000  "Other countries (BGR)" ///
			91240  "Other countries (CAN)" ///
			91520  "Other countries (CHL)" ///
			91580  "Other countries (TAP)" ///
			91700  "Other countries (COL)" ///
			91910  "Other countries (HRV)" ///
			92030  "Other countries (CZE)" ///
			92080  "Other countries (DNK)" ///
			92330  "Other countries (EST)" ///
			92460  "Other countries (FIN)" ///
			92500  "Other countries (FRA)" ///
			92760  "Other countries (DEU)" ///
			93000  "Other countries (GRC)" ///
			93440  "Other countries (HKG)" ///
			93480  "Other countries (HUN)" ///
			93520  "Other countries (ISL)" ///
			93600  "Other countries (IDN)" ///
			93720  "Other countries (IRL)" ///
			93760  "Other countries (ISR)" ///
			93800  "Other countries (ITA)" ///
			93920  "Other countries (JPN)" ///
			94000  "Other countries (JOR)" ///
			94100  "Other countries (KOR)" ///
			94170  "Other countries (KGZ)" ///
			94280  "Other countries (LVA)" ///
			94400  "Other countries (LTU)" ///
			94420  "Other countries (LUX)" ///
			94460  "Other countries (MAC)" ///
			94840  "Other countries (MEX)" ///
			95280  "Other countries (NLD)" ///
			95540  "Other countries (NZL)" ///
			95780  "Other countries (NOR)" ///
			96160  "Other countries (POL)" ///
			96200  "Other countries (PRT)" ///
			96340  "Other countries (QAT)" ///
			96420  "Other countries (ROU)" ///
			96430  "Other countries (RUS)" ///
			97030  "Other countries (SVK)" ///
			97050  "Other countries (SVN)" ///
			97240  "Other countries (ESP)" ///
			97520  "Other countries (SWE)" ///
			97560  "Other countries (CHE)" ///
			97640  "Other countries (THA)" ///
			97770  "Other countries (URY)" ///
			97880  "Other countries (TUN)" ///
			97920  "Other countries (TUR)" ///
			98260  "Other countries (GBR-QUK)" ///
			98262  "Other countries (GBR-QSC)" ///
			98400  "Other countries (USA)" ///
			98911  "Other countries (SRB)" ///
			98912  "Other countries (MNE)" ///
			99997  "N/A" ///
			99998  "Invalid" ///
			99999  "Missing"
	
		foreach v of varlist bcntry* {
			
			replace `v'="" if `v'==    "00020"   /* "Africa"*/ 
			replace `v'="" if `v'==    "00021"  /* "A Sub-Saharan country (Africa excl. Maghreb)" */
			replace `v'="" if `v' ==   "00150"  /* "North African country (Maghreb)" */
			replace `v'="" if `v' ==   "00290"  /* "Caribbean" */
			replace `v'="" if `v' ==   "01451"  /* "Middle Eastern country" */
			replace `v'="" if `v' ==   "01510"  /* "An Eastern European country" */
			replace `v'="" if `v' ==   "08100"  /* "A former USSR republic" */
			replace `v'="" if `v' ==   "08101"  /* "Another former USSR republic (RUS)" */
			replace `v'="" if `v' ==   "08102"  /* "Another former USSR republic (EST)" */
			replace `v'="" if `v' ==   "08900"  /* "A former Yugoslav republic" */
			replace `v'="" if `v' ==   "10560"  /* "Other Western European country (BEL)" */
			replace `v'="" if `v' ==   "11910"  /* "Another former Yugoslav republic (HRV)" */
			replace `v'="" if `v' ==   "13800"  /* "Other European Union Country (ITA)" */
			replace `v'="" if `v' ==   "14420"  /* "Other European Union Country (LUX)" */
			replace `v'="" if `v' ==   "15280"  /* "Other European country (NLD)" */
			replace `v'="" if `v' ==   "16200"  /* "African country with Portuguese as the official language" */
			replace `v'="" if `v' ==   "18262"  /* "Other European country (QSC)" */
			replace `v'="" if `v' ==   "18911"  /* "One of the other former Yugoslav republics (SRB)" */
			replace `v'="" if `v' ==   "23800"  /* "A European country that is not a member of the European Union" */
			replace `v'="" if `v' ==   "26200"  /* "Other European Union Country (PRT)" */
			replace `v'="" if `v' ==   "36200"  /* "An Eastern European country outside the EU" */		
		}

   
		foreach v of varlist bcntry* {
			destring `v', replace
			replace `v' = . if `v'>90000
			label values `v' bcntry
			replace `v' = . if `v' == 999999 |`v' == 999998 | `v' == 999997
			sdecode `v', replace
		}

	**********************************
	* Age of arrival in test country *
	**********************************
		
		gen 	migage=.
		replace migage=st11q04
		replace migage=. if migage>age & !missing(migage)
		replace migage=. if stubrncnt==1 & !missing(migage)

	***************************
	* Language spoken at home *
	***************************
	
		gen 	stulanguage=.
		replace stulanguage =1 if st12q01==1            /* Testsprache */
		replace stulanguage =2 if st12q01==2		    /* other national language*/ /*reversed to PISA 2000*/
		replace stulanguage =3 if st12q01==3           /* other language*/
	
		gen 	otherlang=0 if stulanguage!=.
		replace otherlang=1 if stulanguage==2 | stulanguage==3


	*********************
	* Family Ressources *
	*********************
	
		*books at home *
		gen books = st15q01                	
		
		foreach num of numlist 1/4{
			gen dbook`num'=0 if books!=.
		}
		
		replace dbook1=1 if books==1 
		replace dbook2=1 if books==2| books==3
		replace dbook3=1 if books==4| books==5
		replace dbook4=1 if books==6

		*computers
			
		gen comp_home=st13q04
		label var comp_home "Computer at home"
		recode comp_home (2=0)
	
	compress

	**************************
	* location of the school *
	**************************

		gen schoolloc=sc07q01 
		tab schoolloc,gen(dloc)
		
	**********************
	* number of students *
	**********************
		*boys
		gen numstudmale= sc01q01
		replace numstudmale=. if sc01q01>9000
		*girls
		gen numstudfemale=sc01q02
		replace numstudfemale=. if sc01q02>9000
		*total
		gen numstudtotal=numstudfemale+numstudmale if !missing(numstudfemale) & !missing(numstudmale)

	**************
	* Management *
	**************
		gen 	private=0 if  sc02q01==1		/*sc03q01: 1=public, 2=private*/
		replace private=1 if  sc02q01==2
		
		* one could use the existing variable schltype here:
		gen 	priv=.
		replace priv=0 if schltype==3
		replace priv=1 if schltype==1 | schltype==2

	**************************************
	* Share of school financing by [...] *
	**************************************
		replace sc03q01 =. if sc03q01>9000
		gen schoolbudgetgov  = sc03q01/100
		
	*************************
	* teacher certification *
	*************************
		
		gen 	cert_teachers=propcert 
		label var cert_teachers "Share certified teachers"
		recode 	cert_teachers (9997=.) (9998=.) (9999=.)
							
	*******************************************
	* Availability of infrastructure/material *
	*******************************************

		* instructional material
		gen 	shormat=0 if   sc14q08 ==1 | sc14q08==2
		replace shormat=1 if   sc14q08 ==3 | sc14q08==4
					
	************
	* autonomy *
	************
	
		*preperation
		* different options compared to 2000 and 2003
		* now: Principal or teachers, school board, regional or local authority, national authority
		* 2000 and 2003: not at school, school board, principal, dep head, teacher

		* -> autonomy variable==0 if resp "not at school" or at "regional or national authority"
		* -> autonomy variable==1 if teacher, principal, board, dep head responsible

		*Old classification: conflicting responses: oautonomy==1 if "not at school/national or regional authority" AND "other area" ticked
		*New classification: autonomy==0 if "not at school/national or regional authority" is ticked

		* if responsibility on national or regional level ticked: autonomy ==0
		**** choosing which textbooks are used
			gen 	auttextbook=1 
			replace auttextbook=0 if sc11qj3==1 | sc11qj4==1 
			replace auttextbook=. if sc11qj1==2 & sc11qj2==2 & sc11qj3==2 & sc11qj4==2
			replace auttextbook=. if sc11qj1==. & sc11qj2==. & sc11qj3==. & sc11qj4==.

			**** determining course content
			gen 	autcontent=1 
			replace autcontent=0 if sc11qk3==1 | sc11qk4==1 
			replace autcontent=. if sc11qk1==2 & sc11qk2==2 & sc11qk3==2 & sc11qk4==2
			replace autcontent=. if sc11qk1==. & sc11qk2==. & sc11qk3==. & sc11qk4==.

			**** deciding which courses are offered
			gen 	autcourses=1 
			replace autcourses=0 if sc11ql3==1 | sc11ql4==1 
			replace autcourses=. if sc11ql1==2 & sc11ql2==2 & sc11ql3==2 & sc11ql4==2
			replace autcourses=. if sc11ql1==. & sc11ql2==. & sc11ql3==. & sc11ql4==.

		
	gen wave=2006

******************************************
*Rename to make merge possible
******************************************
	rename  w_fschwt scweight
	rename cntfac cntfac2

*** drop vars not needed

#delimit;
keep pv1read pv1scie pv*math
	 age female
	 whithigh whitlow bluehigh bluelow dhisced*
	 im1 im2 otherlang migage stubrncnt motbrncnt fatbrncnt bcntry*
	 dbook* comp_home
		 dloc* numstudtotal private schoolbudgetgov
		 cert_teachers shormat auttextbook autcontent autcourses
			oecd w_fstuwt w_fstr* wave cnt country schoolid studid
;
#delimit cr

destring _all, replace

compress
save "$path/Data/Working/stsch_2006_renamed.dta", replace
	erase "$path/Data/Working/stsch_2006.dta"

```

### `Replication/Do/1a4_2009.do`
```stata
use "$path/Data/Working/stsch_2009.dta"

***************************
* STUDENT LEVEL VARIABLES *
***************************

	**********
	* Gender *
	**********

		gen 	female = .
		replace female=1 if st04q01==1 	 
		replace female=0 if st04q01==2 
				
	**********************
	* Parents' education *
	**********************

		tab 	misced, gen(dmisced)
		replace dmisced6=1 if dmisced7==1
		drop 	dmisced7

		tab 	fisced, gen(dfisced)
		replace dfisced6=1 if dfisced7==1
		drop 	dfisced7

		replace hisced=. if inlist(hisced,7,8,9)
		tab 	hisced, gen(dhisced)
		replace dhisced6=1 if dhisced7==1
		drop 	dhisced7

	****************
	* Parents' job *
	****************
		
		destring st09q01  , replace
		destring st13q01  , replace

		gen 	occumoth=st09q01
		replace occumoth=. if st09q01==9997 |  st09q01==9998 |  st09q01==9999
		gen 	occufath=st13q01
		replace occufath=. if st13q01==9997 |  st13q01==9998 |  st13q01==9999

		gen 	mothwhithigh=0 if occumoth!=.
		replace mothwhithigh=1 if occumoth>=1000 & occumoth<4000
		gen 	fathwhithigh=0 if occufath!=.
		replace fathwhithigh=1 if occufath>=1000 & occufath<4000
		gen 	mothwhitlow=0 if occumoth!=.
		replace mothwhitlow=1 if occumoth>=4000 & occumoth<6000 | occumoth<1000 
		gen 	fathwhitlow=0 if occufath!=.
		replace fathwhitlow=1 if occufath>=4000 & occufath<6000 | occufath<1000
		gen 	mothbluehigh=0 if occumoth!=.
		replace mothbluehigh=1 if occumoth>=6000 & occumoth<8000
		gen 	fathbluehigh=0 if occufath!=.
		replace fathbluehigh=1 if occufath>=6000 & occufath<8000
		gen 	mothbluelow=0 if occumoth!=.
		replace mothbluelow=1 if occumoth>=8000 & occumoth<9997
		gen 	fathbluelow=0 if occufath!=.
		replace fathbluelow=1 if occufath>=8000 & occufath<9997
		
		* create highest occupational status of parents
		gen 	whithigh=0 if mothwhithigh!=. | fathwhithigh!=.
		replace whithigh=1 if mothwhithigh==1 | fathwhithigh==1
		gen 	whitlow=0 if mothwhitlow!=. | fathwhitlow!=.
		replace whitlow=1 if mothwhitlow==1 & whithigh!=1 | fathwhitlow==1 & whithigh!=1
		gen 	bluehigh=0 if mothbluehigh!=. | fathbluehigh!=.
		replace bluehigh=1 if mothbluehigh==1 & whitlow!=1 & whithigh!=1| fathbluehigh==1 & whitlow!=1 & whithigh!=1
		gen 	bluelow=0 if mothbluelow!=. | fathbluelow!=.
		replace bluelow=1 if mothbluelow==1 &  bluehigh!=1 & whitlow!=1 & whithigh!=1   | fathbluelow==1 & bluehigh!=1 & whitlow!=1 & whithigh!=1

		drop 	mothwhit* fathwhit* mothblue* fathblue*


	********************
	* Immigrant status *
	********************
		* student born in country *
		gen 	stubrncnt=.
		replace stubrncnt = 1 if st17q01==1 /* student born in test country*/
		replace stubrncnt = 0 if st17q01==2

		* father born in coutry *
		gen 	fatbrncnt = .
		replace fatbrncnt = 1 if st17q03==1 /* father born in test country*/
		replace fatbrncnt = 0 if st17q03==2

		* mother born in country *
		gen 	motbrncnt = .
		replace motbrncnt = 1 if st17q02==1 /* mother born in test country*/
		replace motbrncnt = 0 if st17q02==2
		
		foreach v of varlist stubrncnt fatbrncnt motbrncnt {
			recode `v' (2 = 0) (1 = 1)
			replace `v' = . if `v' >= 97
		}

		*first generation: born abroad (stubrncnt==1) with parents born abroad
		gen 	im1=0
		replace im1=1 if motbrncnt==0 & fatbrncnt==0 & stubrncnt==0 
		replace im1=. if missing(motbrncnt) & missing(fatbrncnt) | missing(stubrncnt)

		*second generation: born in country of test language, parent(s) born abrod
		gen 	im2=0
		replace im2=1 if motbrncnt==0  & fatbrncnt==0  & stubrncnt==1
		replace im2=. if missing(motbrncnt) & missing(fatbrncnt) | missing(stubrncnt)
		
		rename cobn_m bcntry_m
		rename cobn_f bcntry_f
		rename cobn_s bcntry
		
		label define bcntry ///
			000400  "Afghanistan" ///
			000800  "Albania" ///
			002900  "Caribbean" ///
			003100  "Azerbaijan" ///
			003200  "Argentina" ///
			003600  "Australia" ///
			004000  "Austria" ///
			005000  "Bangladesh" ///
			005600  "Belgium" ///
			006800  "Bolivia (Plurinational State of)" ///
			007000  "Bosnia and Herzegovina" ///
			007600  "Brazil" ///
			010000  "Bulgaria" ///
			011200  "Belarus" ///
			012400  "Canada" ///
			013200  "Cape Verde" ///
			015200  "Chile" ///
			015600  "China" ///
			015601  "China (Shanghai)" ///
			015602  "Another province in mainland China (QCN)" ///
			015603  "Hong Kong Macau Chinese Taipei" ///
			015610  "China (incl. Hong Kong)" ///
			015800  "Chinese Taipei" ///
			017000  "Colombia" ///
			019100  "Croatia" ///
			020300  "Czech Republic" ///
			020800  "Denmark" ///
			023100  "Ethiopia" ///
			023300  "Estonia" ///
			024600  "Finland" ///
			025000  "France" ///
			027500  "Occupied Palestinian Territory" ///
			027600  "Germany" ///
			030000  "Greece" ///
			034400  "Hong Kong-China" ///
			034800  "Hungary" ///
			035200  "Iceland" ///
			035600  "India" ///
			036000  "Indonesia" ///
			036400  "Iran, Islamic Republic of" ///
			036800  "Iraq" ///
			037200  "Ireland" ///
			037600  "Israel" ///
			038000  "Italy" ///
			039200  "Japan" ///
			039800  "Kazakhstan" ///
			040000  "Jordan" ///
			041000  "Republic of Korea" ///
			041700  "Kyrgyzstan" ///
			042200  "Lebanon" ///
			042800  "Latvia" ///
			043800  "Liechtenstein" ///
			044000  "Lithuania" ///
			044200  "Luxembourg" ///
			044600  "Macao-China" ///
			045800  "Malaysia" ///
			048400  "Mexico" ///
			049900  "Montenegro" ///
			050400  "Morocco" ///
			052800  "Netherlands" ///
			053000  "Netherlands Antilles" ///
			055400  "New Zealand" ///
			057800  "Norway" ///
			058600  "Pakistan" ///
			059100  "Panama" ///
			060000  "Paraguay" ///
			060400  "Peru" ///
			060800  "Philippines" ///
			061600  "Poland" ///
			062000  "Portugal" ///
			063400  "Qatar" ///
			064200  "Romania" ///
			064300  "Russian Federation" ///
			068800  "Serbia" ///
			070200  "Singapore" ///
			070300  "Slovak Republic" ///
			070400  "Viet Nam" ///
			070500  "Slovenia" ///
			070600  "Somalia" ///
			071000  "South Africa" ///
			072400  "Spain" ///
			072401  "Andalusia (ESP)" ///
			072402  "Aragon (ESP)" ///
			072403  "Asturias (ESP)" ///
			072404  "Balearic Islands (ESP)" ///
			072405  "Canary Islands (ESP)" ///
			072406  "Cantabria (ESP)" ///
			072407  "Castile-La Mancha (ESP)" ///
			072408  "Castile and Leon (ESP)" ///
			072409  "Catalonia (ESP)" ///
			072410  "Extremadura (ESP)" ///
			072411  "Galicia (ESP)" ///
			072412  "La Rioja (ESP)" ///
			072413  "Madrid (ESP)" ///
			072414  "Murcia (ESP)" ///
			072415  "Navarre (ESP)" ///
			072416  "Basque Country (ESP)" ///
			072417  "Valencian Community (ESP)" ///
			072418  "Ceuta and Melilla (ESP)" ///
			074000  "Suriname" ///
			075200  "Sweden" ///
			075600  "Switzerland" ///
			076200  "Tajikistan" ///
			076400  "Thailand" ///
			078000  "Trinidad and Tobago" ///
			078410  "United Arab Emirates (Dubai)" ///
			078411  "Another Arabic country (QAR)" ///
			078800  "Tunisia" ///
			079200  "Turkey" ///
			080400  "Ukraine" ///
			080700  "FYR Macedonia" ///
			081800  "Egypt" ///
			082600  "United Kingdom" ///
			082611  "United Kingdom (England)" ///
			082612  "United Kingdom (Northern Ireland)" ///
			082640  "United Kingdom (Great Britain)" ///
			084000  "United States of America" ///
			085800  "Uruguay" ///
			086000  "Uzbekistan" ///
			088200  "Samoa" ///
			088700  "Yemen" ///
			100200  "Africa" ///
			100201  "African country with Portuguese as the official language" ///
			100202  "A Sub-Saharan country (Africa excl. Maghreb)" ///
			100204  "North African country (Maghreb)" ///
			100501  "South, Latin & Central America" ///
			114500  "Middle Eastern country" ///
			115000  "A European country" ///
			115001  "Other Western European country (BEL)" ///
			115003  "Other European Union Country (LUX)" ///
			115004  "A country from European Union (PRT)" ///
			115007  "Other European country (NLD)" ///
			115008  "Other European country (QSC)" ///
			115100  "An Eastern European country" ///
			115106  "An Eastern European country outside the EU" ///
			119001  "Another American country [URY]" ///
			181000  "One of the former USSR republics" ///
			181001  "In another former USSR republic (RUS)" ///
			181002  "In another former USSR republic (EST)" ///
			189000  "One of the former Yugoslav republics" ///
			189001  "One of the other former Yugoslav republics (HRV)" ///
			189002  "One of the other former Yugoslav republics (SRB)" ///
			189003  "Serbia and Montenegro" ///
			900800  "Another country (ALB)" ///
			903100  "Another country (AZE)" ///
			903200  "Another country (ARG)" ///
			903600  "Another country (AUS)" ///
			904000  "Another country (AUT)" ///
			905600  "Another country (BEL)" ///
			907600  "Another country (BRA)" ///
			910000  "Another country (BGR)" ///
			912400  "Another country (CAN)" ///
			915200  "Another country (CHL)" ///
			915601  "Another country (QCN )" ///
			915800  "Another country (TAP)" ///
			917000  "Another country (COL)" ///
			919100  "Another country (HRV)" ///
			920300  "Another country (CZE)" ///
			920800  "Another country (DNK)" ///
			923300  "Another country (EST)" ///
			924600  "Another country (FIN)" ///
			925000  "Another country (FRA)" ///
			927600  "Another country (DEU)" ///
			930000  "Another country (GRC)" ///
			934400  "Another country (HKG)" ///
			934800  "Another country (HUN)" ///
			935200  "Another country (ISL)" ///
			936000  "Another country (IDN)" ///
			937200  "Another country (IRL)" ///
			937600  "Another country (ISR)" ///
			938000  "Another country (ITA)" ///
			939200  "Another country (JPN)" ///
			939800  "Another country (KAZ)" ///
			940000  "Another country (JOR)" ///
			941000  "Another country (KOR)" ///
			941700  "Another country (KGZ)" ///
			942800  "Another country (LVA)" ///
			944000  "Another country (LTU)" ///
			944200  "Another country (LUX)" ///
			944600  "Another country (MAC)" ///
			948400  "Another country (MEX)" ///
			949900  "Another country (MNE)" ///
			952800  "Another country (NLD)" ///
			955400  "Another country (NZL)" ///
			957800  "Another country (NOR)" ///
			959100  "Another country (PAN)" ///
			960400  "Another country (PER)" ///
			961600  "Another country (POL)" ///
			962000  "Another country (PRT)" ///
			963400  "Another country (QAT)" ///
			964200  "Another country (ROU)" ///
			964300  "Another country (RUS)" ///
			968800  "Another country (SRB)" ///
			970200  "Another country (SGP)" ///
			970300  "Another country (SVK)" ///
			970500  "Another country (SVN)" ///
			972400  "Another country (ESP)" ///
			975200  "Another country (SWE)" ///
			975600  "Another country (CHE)" ///
			976400  "Another country (THA)" ///
			978000  "Another country (TTO)" ///
			978410  "Another country (QAR)" ///
			978800  "Another country (TUN)" ///
			979200  "Another country (TUR)" ///
			982610  "Another country (QUK)" ///
			982620  "Another country (QSC)" ///
			984000  "Another country (USA)" ///
			985800  "Another country (URY)" ///
			018800  "Costa Rica" ///
			026800  "Georgia" ///
			035610  "India (2009 States)" ///
			047000  "Malta" ///
			048000  "Mauritius" ///
			049800  "Republic of Moldova" ///
			078420  "United Arab Emirates (ex.Dubai)" ///
			078421  "Abu Dhabi (ARE ex Dubai)" ///
			078422  "Al Ain (ARE ex Dubai)" ///
			078423  "Western Region (ARE ex Dubai)" ///
			078424  "Sharjah (ARE ex Dubai)" ///
			078425  "Ajman (ARE ex Dubai)" ///
			078426  "Umm Al Quain (ARE ex Dubai)" ///
			078427  "Fujaurah (ARE ex Dubai)" ///
			078428  "Ras Al Khaimah (ARE ex Dubai)" ///
			086201  "Venezuela (Miranda)" ///
			115005  "A European country that is not a member of the European Union" ///
			115009  "Another country within the European Union (MLT)" ///
			181003  "In another former USSR republic (GEO)" ///
			918800  "Another country (CRI)" ///
			926800  "Another country (GEO)" ///
			935610  "Another country (QIN)" ///
			945800  "Another country (MYS)" ///
			947000  "Another country (MLT)" ///
			948000  "Another country (MUS)" ///
			949800  "Another country (MDA)" ///
			978420  "Another country (ARE ex Dubai)" ///
			986201  "Another country (QVE)" ///
			999997  "N/A" ///
			999998  "Invalid" ///
			999999  "Missing"
		   
		   
		   foreach v of varlist bcntry* {
		   replace `v' ="" if `v'=="078411"  /* "Another Arabic country (QAR) */
		   replace `v' ="" if `v'== "100201"  /* "African country with Portuguese as the official language */
		   replace `v' ="" if `v'== "100202"  /* "A Sub-Saharan country (Africa excl. Maghreb) */
		   replace `v' ="" if `v'== "100204"  /* "North African country (Maghreb) */
		   replace `v' ="" if `v'== "100501"  /* "South, Latin & Central America */
		   replace `v' ="" if `v'== "114500"  /* "Middle Eastern country */
		   replace `v' ="" if `v'== "115000"  /* "A European country */
		   replace `v' ="" if `v'== "115001"  /* "Other Western European country (BEL) */
		   replace `v' ="" if `v'== "115003"  /* "Other European Union Country (LUX) */
		   replace `v' ="" if `v'== "115004"  /* "A country from European Union (PRT) */
		   replace `v' ="" if `v'== "115007"  /* "Other European country (NLD) */
		   replace `v' ="" if `v'== "115008"  /* "Other European country (QSC) */
		   replace `v' ="" if `v'==  "115100"  /* "An Eastern European country */
		   replace `v' ="" if `v'==  "115106"  /* "An Eastern European country outside the EU */
		   replace `v' ="" if `v'=="119001"  /* "Another American country [URY] */
		   replace `v' ="" if `v'=="181000"  /* "One of the former USSR republics */
		   replace `v' ="" if `v'=="181001"  /* "In another former USSR republic (RUS) */
		   replace `v' ="" if `v'=="181002"  /* "In another former USSR republic (EST) */
		   replace `v' ="" if `v'=="189000"  /* "One of the former Yugoslav republics */
		   replace `v' ="" if `v'=="189001"  /* "One of the other former Yugoslav republics (HRV) */
		   replace `v' ="" if `v'=="189002"  /* "One of the other former Yugoslav republics (SRB) */
		   replace `v' ="" if `v'=="115005"  /* "A European country that is not a member of the European Union */
		   replace `v' ="" if `v'=="115009"  /* "Another country within the European Union (MLT) */
		   replace `v' ="" if `v'=="181003"  /* "In another former USSR republic (GEO) */
		}

		foreach v of varlist bcntry* {
			destring `v', replace
			label values `v' bcntry
			replace `v' = . if `v' == 999999 |`v' == 999998 | `v' == 999997
			replace  `v'=. if `v'>900000
			sdecode `v', replace
		}

	**********************************
	* Age of arrival in test country *
	**********************************
		
		gen 	migage=.
		replace migage=st18q01
		replace migage=. if migage>age & !missing(migage)

	***************************
	* Language spoken at home *
	***************************

		gen 	stulanguage=.
		replace stulanguage =1 if st19q01==1            /* testsprache */
		replace stulanguage =2 if st19q01==2           /* other language*/
				
		*other language == 1 if other than test language or national dialect
		gen 	otherlang=0 if stulanguage!=.
		replace otherlang=1 if stulanguage==2


	*********************
	* Family Ressources *
	*********************
	
		*books at home *
		gen books = st22q01       
			
		foreach num of numlist 1/4{
			gen dbook`num'=0 if books!=.
		}
		
		replace dbook1=1 if books==1 
		replace dbook2=1 if books==2| books==3
		replace dbook3=1 if books==4| books==5
		replace dbook4=1 if books==6

		*computers
		
			gen 	comp_home=st20q04
			label var comp_home "Computer at home"
			recode  comp_home (9997=.) (9998=.) (9999=.)
			recode  comp_home (2=0) 
				 	
		compress

	**************************
	* location of the school *
	**************************
		gen schoolloc=sc04q01 
		tab schoolloc,gen(dloc)

	**********************
	* number of students *
	**********************
		*boys
		gen 	numstudmale=sc06q01
		replace numstudmale=. if sc06q01>9000
		*girls
		gen 	numstudfemale=sc06q02
		replace numstudfemale=. if sc06q02>9000
		*total
		gen numstudtotal=numstudfemale+numstudmale if numstudfemale!=. & numstudmale !=.

	**************
	* Management *
	**************
		gen 	private=0 if  sc02q01==1		/*sc03q01: 1=public, 2=private*/
		replace private=1 if  sc02q01==2
		
		* one could use the existing variable schltype here:
		gen 	priv=.
		replace priv=0 if schtype==3
		replace priv=1 if schtype==1 | schtype==2

	**************************************
	* Share of school financing by [...] *
	**************************************
		replace sc03q01 =. if sc03q01>9000
		gen schoolbudgetgov  = sc03q01/100		
	
	*************************
	* teacher certification *
	*************************
		
		gen 	cert_teachers=propcert 
		label var cert_teachers "Share certified teachers"
		recode 	cert_teachers (9997=.) (9998=.) (9999=.)	
	
	*******************************************
	* Availability of infrastructure/material *
	*******************************************
	
		* instructional material
		gen 	shormat=0 if sc11q08 ==1 | sc11q08==2 
		replace shormat=1 if sc11q08 ==3 | sc11q08==4
		
	************
	* autonomy *
	************
		**** choosing which textbooks are used
			gen 	auttextbook=1
			replace auttextbook=0 if sc24qj4==1 | sc24qj5==1
			replace auttextbook=. if sc24qj1==2 & sc24qj2==2 & sc24qj3==2 & sc24qj4==2 & sc24qj5==2 
			replace auttextbook=. if sc24qj1==. & sc24qj2==. & sc24qj3==. & sc24qj4==. & sc24qj5==. 

		**** determining course content
			gen 	autcontent=1 
			replace autcontent=0 if sc24qk4==1 | sc24qk5==1
			replace autcontent=. if sc24qk1==2 & sc24qk2==2 & sc24qk3==2 & sc24qk4==2 & sc24qk5==2 
			replace autcontent=. if sc24qk1==. & sc24qk2==. & sc24qk3==. & sc24qk4==. & sc24qk5==.

		**** deciding which courses are offered
			gen 	autcourses=1 
			replace autcourses=0 if sc24ql4==1 | sc24ql5==1
			replace autcourses=. if sc24ql1==2 & sc24ql2==2 & sc24ql3==2 & sc24ql4==2 & sc24ql5==2 
			replace autcourses=. if sc24ql1==. & sc24ql2==. & sc24ql3==. & sc24ql4==. & sc24ql5==.		
	
	gen wave=2009

	rename  w_fschwt scweight
	rename  cntfac cntfac1

*** drop vars not needed

#delimit;
keep pv1read pv1scie pv*math
	 age female
	 whithigh whitlow bluehigh bluelow dhisced*
	 im1 im2 otherlang migage stubrncnt motbrncnt fatbrncnt bcntry*
	 dbook* comp_home
		 dloc* numstudtotal private schoolbudgetgov
		 cert_teachers shormat auttextbook autcontent autcourses
			oecd w_fstuwt w_fstr* wave cnt country schoolid studid
;
#delimit cr
	
destring _all, replace

compress
save "$path/Data/Working/stsch_2009_renamed.dta", replace
	erase "$path/Data/Working/stsch_2009.dta"

```

### `Replication/Do/1a5_2012.do`
```stata
use "$path/Data/Working/stsch_2012.dta"

		recode age (9999=.)
	
		gen 	female = .
		replace female=1 if  st04q01==1
		replace female=0 if  st04q01==2
		

	**********************
	* Parents' education *
	**********************
	
		replace misced=. if misced==9
		tab 	misced, gen(dmisced)
		replace dmisced6=1 if dmisced7==1
		drop 	dmisced7

		replace fisced=. if fisced==9
		tab 	fisced, gen(dfisced)
		replace dfisced6=1 if dfisced7==1
		drop 	dfisced7

		replace hisced=. if hisced==9
		tab 	hisced, gen(dhisced)
		replace dhisced6=1 if dhisced7==1
		drop 	dhisced7

	****************
	* Parents' job *
	****************

		destring ocod1,replace
		destring ocod2,replace
		
		gen 	occumoth=ocod1
		replace occumoth=. if ocod1==9997 |  ocod1==9998 |  ocod1==9999
		gen 	occufath=ocod2
		replace occufath=. if ocod2==9997 |  ocod2==9998 |  ocod2==9999
		
		replace occumoth=1 if ocod1>=1000&ocod1<4000
		replace occumoth=2 if (ocod1>=4000&ocod1<6000)|ocod1<1000
		replace occumoth=3 if ocod1>=6000&ocod1<8000
		replace occumoth=4 if ocod1>=8000&ocod1<9900

		replace occufath=1 if ocod2>=1000&ocod2<4000
		replace occufath=2 if (ocod2>=4000&ocod2<6000)|ocod2<1000
		replace occufath=3 if ocod2>=6000&ocod2<8000
		replace occufath=4 if ocod2>=8000&ocod2<9900

		
		gen 	mothwhithigh=0 if occumoth!=.
		replace mothwhithigh=1 if occumoth==1
		gen 	fathwhithigh=0 if occufath!=.
		replace fathwhithigh=1 if occufath==1
		gen 	mothwhitlow=0 if occumoth!=.
		replace mothwhitlow=1 if occumoth==2
		gen 	fathwhitlow=0 if occufath!=.
		replace fathwhitlow=1 if occufath==2
		gen 	mothbluehigh=0 if occumoth!=.
		replace mothbluehigh=1 if occumoth==3
		gen 	fathbluehigh=0 if occufath!=.
		replace fathbluehigh=1 if occufath==3
		gen 	mothbluelow=0 if occumoth!=.
		replace mothbluelow=1 if occumoth==4
		gen 	fathbluelow=0 if occufath!=.
		replace fathbluelow=1 if occufath==4

		* create highest occupational status of parents
		gen 	whithigh=0 if mothwhithigh!=. | fathwhithigh!=.
		replace whithigh=1 if mothwhithigh==1 | fathwhithigh==1
		gen 	whitlow=0 if mothwhitlow!=. | fathwhitlow!=.
		replace whitlow=1 if mothwhitlow==1 & whithigh!=1 | fathwhitlow==1 & whithigh!=1
		gen 	bluehigh=0 if mothbluehigh!=. | fathbluehigh!=.
		replace bluehigh=1 if mothbluehigh==1 & whitlow!=1 & whithigh!=1| fathbluehigh==1 & whitlow!=1 & whithigh!=1
		gen 	bluelow=0 if mothbluelow!=. | fathbluelow!=.
		replace bluelow=1 if mothbluelow==1 &  bluehigh!=1 & whitlow!=1 & whithigh!=1 | fathbluelow==1 & bluehigh!=1 & whitlow!=1 & whithigh!=1

		drop 	mothwhit* fathwhit* mothblue* fathblue*

	********************
	* Immigrant status *
	********************
		* student born in country *
		gen 	stubrncnt=.
		replace stubrncnt = 1 if st20q01 ==1 /* student born in test country*/
		replace stubrncnt = 0 if st20q01 ==2

		* father born in coutry *
		gen 	fatbrncnt = .
		replace fatbrncnt = 1 if st20q03 ==1 /* father born in test country*/
		replace fatbrncnt = 0 if st20q03 ==2

		* mother born in country *
		gen 	motbrncnt = .
		replace motbrncnt = 1 if st20q02 ==1 /* mother born in test country*/
		replace motbrncnt = 0 if st20q02 ==2
		
		foreach v of varlist stubrncnt fatbrncnt motbrncnt {
			recode `v' (2 = 0) (1 = 1)
			replace `v' = . if `v' >= 97
		}

		*first generation: born abroad (stubrncnt==1) with parents born abroad
		gen 	im1=0
		replace im1=1 if motbrncnt==0 & fatbrncnt==0 & stubrncnt==0 
		replace im1=. if missing(motbrncnt) & missing(fatbrncnt) | missing(stubrncnt)

		*second generation: born in country of test language, parent(s) born abrod
		gen 	im2=0
		replace im2=1 if motbrncnt==0 & fatbrncnt==0  & stubrncnt==1
		replace im2=. if missing(motbrncnt) & missing(fatbrncnt) | missing(stubrncnt)
		
		rename cobn_m bcntry_m
		rename cobn_f bcntry_f
		rename cobn_s bcntry
		
		label define bcntry ///
			000400  "Afghanistan" ///
			000800  "Albania" ///
			001200  "Algeria" ///
			001600  "American Samoa" ///
			002000  "Andorra" ///
			002400  "Angola" ///
			002800  "Antigua and Barbuda" ///
			002900  "Caribbean" ///
			003100  "Azerbaijan" ///
			003200  "Argentina" ///
			003600  "Australia" ///
			004000  "Austria" ///
			004400  "Bahamas" ///
			004800  "Bahrain" ///
			005000  "Bangladesh" ///
			005100  "Armenia" ///
			005200  "Barbados" ///
			005600  "Belgium" ///
			005601  "Belgium (Flanders)" ///
			005602  "Belgium (French community)" ///
			005603  "Belgium (German community)" ///
			006000  "Bermuda" ///
			006400  "Bhutan" ///
			006800  "Bolivia (Plurinational State of)" ///
			007000  "Bosnia and Herzegovina" ///
			007200  "Botswana" ///
			007600  "Brazil" ///
			008400  "Belize" ///
			009200  "British Virgin Islands" ///
			009600  "Brunei Darussalam" ///
			010000  "Bulgaria" ///
			010400  "Myanmar" ///
			010800  "Burundi" ///
			011200  "Belarus" ///
			011600  "Cambodia" ///
			012000  "Cameroon" ///
			012400  "Canada" ///
			013200  "Cape Verde" ///
			013600  "Cayman Islands" ///
			014000  "Central African Republic" ///
			014400  "Sri Lanka" ///
			014800  "Chad" ///
			015200  "Chile" ///
			015600  "China" ///
			015601  "China (Shanghai)" ///
			015604  "China (Beijing)" ///
			015610  "China (incl. Hong Kong)" ///
			015800  "Chinese Taipei" ///
			017000  "Colombia" ///
			017400  "Comoros" ///
			017500  "Mayotte" ///
			017800  "Congo" ///
			018000  "Democratic Republic of the Congo" ///
			018400  "Cook Islands" ///
			018800  "Costa Rica" ///
			019100  "Croatia" ///
			019200  "Cuba" ///
			020300  "Czech Republic" ///
			020400  "Benin" ///
			020800  "Denmark" ///
			021200  "Dominica" ///
			021400  "Dominican Republic" ///
			021800  "Ecuador" ///
			022200  "El Salvador" ///
			022600  "Equatorial Guinea" ///
			023100  "Ethiopia" ///
			023200  "Eritrea" ///
			023300  "Estonia" ///
			023400  "Faeroe Islands" ///
			023800  "Falkland Islands (Malvinas)" ///
			024200  "Fiji" ///
			024600  "Finland" ///
			024800  "land Islands" ///
			025000  "France" ///
			025400  "French Guiana" ///
			025800  "French Polynesia" ///
			026200  "Djibouti" ///
			026600  "Gabon" ///
			026800  "Georgia" ///
			027000  "Gambia" ///
			027500  "Occupied Palestinian Territory" ///
			027600  "Germany" ///
			028800  "Ghana" ///
			029200  "Gibraltar" ///
			029600  "Kiribati" ///
			030000  "Greece" ///
			030400  "Greenland" ///
			030800  "Grenada" ///
			031200  "Guadeloupe" ///
			031600  "Guam" ///
			032000  "Guatemala" ///
			032400  "Guinea" ///
			032800  "Guyana" ///
			033200  "Haiti" ///
			033600  "Holy See" ///
			034000  "Honduras" ///
			034400  "Hong Kong-China" ///
			034800  "Hungary" ///
			035200  "Iceland" ///
			035600  "India" ///
			035610  "India (2009 States)" ///
			036000  "Indonesia" ///
			036400  "Iran, Islamic Republic of" ///
			036800  "Iraq" ///
			037200  "Ireland" ///
			037600  "Israel" ///
			038000  "Italy" ///
			038001  "Provincia Autonoma of Bolzano (ITA)" ///
			038002  "Provincia Basilicata (ITA)" ///
			038003  "Provincia Campania (ITA)" ///
			038004  "Provincia Emilia Romagna (ITA)" ///
			038005  "Provincia Friuli Venezia Giulia (ITA)" ///
			038006  "Provincia Liguria (ITA)" ///
			038007  "Provincia Lombardia (ITA)" ///
			038008  "Provincia Piemonte (ITA)" ///
			038009  "Provincia Puglia (ITA)" ///
			038010  "Provincia Sardegna (ITA)" ///
			038011  "Provincia Sicilia (ITA)" ///
			038012  "Provincia Trento (ITA)" ///
			038013  "Provincia Veneto (ITA)" ///
			038014  "The rest of Italy (ITA)" ///
			038400  "C™te d'Ivoire" ///
			038800  "Jamaica" ///
			039200  "Japan" ///
			039800  "Kazakhstan" ///
			040000  "Jordan" ///
			040400  "Kenya" ///
			040800  "Democratic People's Republic of Korea" ///
			041000  "Republic of Korea" ///
			041400  "Kuwait" ///
			041700  "Kyrgyzstan" ///
			041800  "Lao People's Democratic Republic" ///
			042200  "Lebanon" ///
			042600  "Lesotho" ///
			042800  "Latvia" ///
			043000  "Liberia" ///
			043400  "Libyan Arab Jamahiriya" ///
			043800  "Liechtenstein" ///
			044000  "Lithuania" ///
			044200  "Luxembourg" ///
			044600  "Macao-China" ///
			045000  "Madagascar" ///
			045400  "Malawi" ///
			045800  "Malaysia" ///
			046200  "Maldives" ///
			046600  "Mali" ///
			047000  "Malta" ///
			047400  "Martinique" ///
			047800  "Mauritania" ///
			048000  "Mauritius" ///
			048400  "Mexico" ///
			049200  "Monaco" ///
			049600  "Mongolia" ///
			049800  "Republic of Moldova" ///
			049900  "Montenegro" ///
			050000  "Montserrat" ///
			050400  "Morocco" ///
			050800  "Mozambique" ///
			051200  "Oman" ///
			051600  "Namibia" ///
			052000  "Nauru" ///
			052400  "Nepal" ///
			052800  "Netherlands" ///
			053000  "Netherlands Antilles" ///
			053300  "Aruba" ///
			054000  "New Caledonia" ///
			054800  "Vanuatu" ///
			055400  "New Zealand" ///
			055800  "Nicaragua" ///
			056200  "Niger" ///
			056600  "Nigeria" ///
			057000  "Niue" ///
			057400  "Norfolk Island" ///
			057800  "Norway" ///
			058000  "Northern Mariana Islands" ///
			058300  "Micronesia, Federated States of" ///
			058400  "Marshall Islands" ///
			058500  "Palau" ///
			058600  "Pakistan" ///
			059100  "Panama" ///
			059800  "Papua New Guinea" ///
			060000  "Paraguay" ///
			060400  "Peru" ///
			060800  "Philippines" ///
			061200  "Pitcairn" ///
			061600  "Poland" ///
			062000  "Portugal" ///
			062400  "Guinea-Bissau" ///
			062600  "Timor-Leste" ///
			063000  "Puerto Rico" ///
			063400  "Qatar" ///
			063800  "RŽunion" ///
			064200  "Romania" ///
			064300  "Russian Federation" ///
			064600  "Rwanda" ///
			065200  "Saint-BarthŽlemy" ///
			065400  "Saint Helena" ///
			065900  "Saint Kitts and Nevis" ///
			066000  "Anguilla" ///
			066200  "Saint Lucia" ///
			066300  "Saint-Martin (French part)" ///
			066600  "Saint Pierre and Miquelon" ///
			067000  "Saint Vincent and the Grenadines" ///
			067400  "San Marino" ///
			067800  "Sao Tome and Principe" ///
			068200  "Saudi Arabia" ///
			068600  "Senegal" ///
			068800  "Serbia" ///
			069000  "Seychelles" ///
			069400  "Sierra Leone" ///
			070200  "Singapore" ///
			070300  "Slovak Republic" ///
			070400  "Viet Nam" ///
			070500  "Slovenia" ///
			070600  "Somalia" ///
			071000  "South Africa" ///
			071600  "Zimbabwe" ///
			072400  "Spain" ///
			072401  "Andalusia (ESP)" ///
			072402  "Aragon (ESP)" ///
			072403  "Asturias (ESP)" ///
			072404  "Balearic Islands (ESP)" ///
			072405  "Canary Islands (ESP)" ///
			072406  "Cantabria (ESP)" ///
			072407  "Castile-La Mancha (ESP)" ///
			072408  "Castile and Leon (ESP)" ///
			072409  "Catalonia (ESP)" ///
			072410  "Extremadura (ESP)" ///
			072411  "Galicia (ESP)" ///
			072412  "La Rioja (ESP)" ///
			072413  "Madrid (ESP)" ///
			072414  "Murcia (ESP)" ///
			072415  "Navarre (ESP)" ///
			072416  "Basque Country (ESP)" ///
			072417  "Valencian Community (ESP)" ///
			072418  "Ceuta and Melilla (ESP)" ///
			072419  "The rest of Spain (ESP)" ///
			073200  "Western Sahara" ///
			073600  "Sudan" ///
			074000  "Suriname" ///
			074400  "Svalbard and Jan Mayen Islands" ///
			074800  "Swaziland" ///
			075200  "Sweden" ///
			075600  "Switzerland" ///
			075601  "Switzerland (German-speaking community)" ///
			075602  "Switzerland (French-speaking community)" ///
			075603  "Switzerland (Italian-speaking community)" ///
			076000  "Syrian Arab Republic" ///
			076200  "Tajikistan" ///
			076400  "Thailand" ///
			076800  "Togo" ///
			077200  "Tokelau" ///
			077600  "Tonga" ///
			078000  "Trinidad and Tobago" ///
			078400  "United Arab Emirates" ///
			078410  "United Arab Emirates (Dubai)" ///
			078411  "Another Arabic country (ARE)" ///
			078420  "United Arab Emirates (ex.Dubai)" ///
			078800  "Tunisia" ///
			079200  "Turkey" ///
			079500  "Turkmenistan" ///
			079600  "Turks and Caicos Islands" ///
			079800  "Tuvalu" ///
			080000  "Uganda" ///
			080400  "Ukraine" ///
			080700  "FYR Macedonia" ///
			081800  "Egypt" ///
			082600  "United Kingdom" ///
			082610  "United Kingdom (excl.Scotland)" ///
			082611  "United Kingdom (England)" ///
			082612  "United Kingdom (Northern Ireland)" ///
			082613  "United Kingdom (Wales)" ///
			082620  "United Kingdom (Scotland)" ///
			082640  "United Kingdom (Great Britain)" ///
			083000  "Channel Islands" ///
			083100  "Guernsey" ///
			083200  "Jersey" ///
			083300  "Isle of Man" ///
			083400  "United Republic of Tanzania" ///
			084000  "United States of America" ///
			085000  "United States Virgin Islands" ///
			085400  "Burkina Faso" ///
			085800  "Uruguay" ///
			086000  "Uzbekistan" ///
			086200  "Venezuela (Bolivarian Republic of)" ///
			087600  "Wallis and Futuna Islands" ///
			088200  "Samoa" ///
			088700  "Yemen" ///
			089400  "Zambia" ///
			009000  "Solomon Islands" ///
			100200  "Africa" ///
			100201  "African country with Portuguese as the official language" ///
			100202  "A Sub-Saharan country (Africa excl. Maghreb)" ///
			100204  "North African country (Maghreb)" ///
			114500  "Middle Eastern country" ///
			115000  "A European country" ///
			115001  "Other Western European country (BEL)" ///
			115009  "Another country within the European Union (MLT)" ///
			115002  "Another country within the European Union (ITA)" ///
			115003  "Other European Union Country (LUX)" ///
			115004  "A country from European Union (PRT)" ///
			115005  "A European country that is not a member of the European Union" ///
			115007  "Other European country (NLD)" ///
			115008  "Other European country (QSC)" ///
			115100  "An Eastern European country" ///
			115106  "An Eastern European country outside the EU" ///
			181000  "One of the former USSR republics" ///
			181001  "In another former USSR republic (RUS)" ///
			181002  "In another former USSR republic (EST)" ///
			189000  "One of the former Yugoslav republics" ///
			189001  "One of the other former Yugoslav republics (HRV)" ///
			189002  "One of the other former Yugoslav republics (SRB)" ///
			189003  "Serbia and Montenegro" ///
			900800  "Another country (ALB)" ///
			903100  "Another country (AZE)" ///
			903200  "Another country (ARG)" ///
			903600  "Another country (AUS)" ///
			904000  "Another country (AUT)" ///
			905600  "Another country (BEL)" ///
			907600  "Another country (BRA)" ///
			910000  "Another country (BGR)" ///
			912400  "Another country (CAN)" ///
			915200  "Another country (CHL)" ///
			915601  "Another country (QCN )" ///
			915604  "Another country (QCH )" ///
			915800  "Another country (TAP)" ///
			917000  "Another country (COL)" ///
			919100  "Another country (HRV)" ///
			920300  "Another country (CZE)" ///
			920800  "Another country (DNK)" ///
			921400  "Another country (DOM)" ///
			923300  "Another country (EST)" ///
			924600  "Another country (FIN)" ///
			925000  "Another country (FRA)" ///
			927600  "Another country (DEU)" ///
			930000  "Another country (GRC)" ///
			934400  "Another country (HKG)" ///
			934800  "Another country (HUN)" ///
			935200  "Another country (ISL)" ///
			936000  "Another country (IDN)" ///
			937200  "Another country (IRL)" ///
			937600  "Another country (ISR)" ///
			938000  "Another country (ITA)" ///
			939200  "Another country (JPN)" ///
			939800  "Another country (KAZ)" ///
			940000  "Another country (JOR)" ///
			941000  "Another country (KOR)" ///
			941700  "Another country (KGZ)" ///
			942800  "Another country (LVA)" ///
			943800  "Another country (LIE)" ///
			944000  "Another country (LTU)" ///
			944200  "Another country (LUX)" ///
			944600  "Another country (MAC)" ///
			948400  "Another country (MEX)" ///
			949800  "Another country (MDA)" ///
			949900  "Another country (MNE)" ///
			952800  "Another country (NLD)" ///
			955400  "Another country (NZL)" ///
			957800  "Another country (NOR)" ///
			959100  "Another country (PAN )" ///
			960400  "Another country (PER)" ///
			961600  "Another country (POL)" ///
			962000  "Another country (PRT)" ///
			963400  "Another country (QAT)" ///
			964200  "Another country (ROU)" ///
			964300  "Another country (RUS)" ///
			968800  "Another country (SRB)" ///
			970200  "Another country (SGP)" ///
			970300  "Another country (SVK)" ///
			970500  "Another country (SVN)" ///
			972400  "Another country (ESP)" ///
			975200  "Another country (SWE)" ///
			975600  "Another country (CHE)" ///
			976400  "Another country (THA)" ///
			985800  "Another country (URY)" ///
			978000  "Another country (TTO)" ///
			978410  "Another country (QAR)" ///
			978800  "Another country (TUN)" ///
			979200  "Another country (TUR)" ///
			980700  "Another country (MKD)" ///
			982600  "Another country (GBR)" ///
			982610  "Another country (QUK)" ///
			982620  "Another country (QSC)" ///
			984000  "Another country (USA)" ///
			918800  "Another country (CRI)" ///
			926800  "Another country (GEO)" ///
			935610  "Another country (QIN)" ///
			945800  "Another country (MYS)" ///
			947000  "Another country (MLT)" ///
			948000  "Another country (MUS)" ///
			978420  "Another country (QRE)" ///
			015602  "Another province in mainland China (QCN)" ///
			015605  "Another province in mainland China (QCH)" ///
			015603  "Hong Kong, Macau, Taiwan" ///
			119001  "Another American country [URY]" ///
			178411  "Another Arabic country (QAR)" ///
			100501  "South, Latin  and Central America" ///
			078421  "Abu Dhabi (QRE)" ///
			078422  "Al Ain (QRE)" ///
			078423  "Western Region (QRE)" ///
			078424  "Sharjah (QRE)" ///
			078425  "Ajman (QRE)" ///
			078426  "Umm Al Quain (QRE)" ///
			078427  "Fujaurah (QRE)" ///
			078428  "Ras Al Khaimah (QRE)" ///
			086201  "Venezuela (Miranda)" ///
			986201  "Another country (QVE )" ///
			086220  "Venezuela (ex. Miranda)" ///
			181003  "In another former USSR republic (GEO)" ///
			099000  "ZedlandA" ///
			099100  "ZedlandB" ///
			099200  "ZedlandC" ///
			099300  "ZedlandD" ///
			099400  "ZedlandE" ///
			099500  "ZedlandF" ///
			099600  "ZedlandG" ///
			099700  "ZedlandH" ///
			099800  "ZedlandJ" ///
			099900  "ZedlandK" ///
			999000  "Another country (ZZA)" ///
			999100  "Another country (ZZB)" ///
			999200  "Another country (ZZC)" ///
			999300  "Another country (ZZD)" ///
			999400  "Another country (ZZE)" ///
			999500  "Another country (ZZF)" ///
			999600  "Another country (ZZG)" ///
			999700  "Another country (ZZH)" ///
			999800  "Another country (ZZJ)" ///
			999900  "Another country (ZZK)" ///
			978400  "Another Country (ARE)" ///
			919600  "Another Country (CYP)" ///
			970400  "Another Country (VNM)" ///
			181004  "In another former USSR republic (KAZ)" ///
			115006  "Other European country (ITA)" ///
			178401  "Another State of the Gulf Cooperation Council (ARE)" ///
			189004  "Serbia, Montenegro and Kosovo" ///
			089005  "Kosovo" /// 
			064301  "Perm (Russian Federation)" ///
			064302  "Another region of the Russian Federation" ///
			000000  "Not selected" ///
			777777  "N/A" ///
			888888  "Invalid" ///
			999997  "N/A" ///
			999998  "Invalid" ///
			999999  "Missing"

	foreach v of varlist bcntry* {
		replace `v' ="" if `v'=="100200" /* Africa" */
		replace `v' ="" if `v'=="100201" /*  "African country with Portuguese as the official language" */
		replace `v' ="" if `v'=="100202" /*  "A Sub-Saharan country (Africa excl. Maghreb)" */
		replace `v' ="" if `v'=="100204" /*  "North African country (Maghreb)" */
		replace `v' ="" if `v'=="114500" /*  "Middle Eastern country" */
		replace `v' ="" if `v'=="115000" /*  "A European country" */
		replace `v' ="" if `v'=="115001" /*  "Other Western European country (BEL)" */
		replace `v' ="" if `v'=="115009" /*  "Another country within the European Union (MLT)" */
		replace `v' ="" if `v'=="115002" /*  "Another country within the European Union (ITA)" */
		replace `v' ="" if `v'=="115003" /*  "Other European Union Country (LUX)" */
		replace `v' ="" if `v'=="115004" /*  "A country from European Union (PRT)" */
		replace `v' ="" if `v'=="115005" /*  "A European country that is not a member of the European Union" */
		replace `v' ="" if `v'=="115007" /*  "Other European country (NLD)" */
		replace `v' ="" if `v'=="115008" /*  "Other European country (QSC)" */
		replace `v' ="" if `v'=="115100" /*  "An Eastern European country" */
		replace `v' ="" if `v'=="115106" /*  "An Eastern European country outside the EU" */
		replace `v' ="" if `v'=="181000" /*  "One of the former USSR republics" */
		replace `v' ="" if `v'=="181001" /*  "In another former USSR republic (RUS)" */
		replace `v' ="" if `v'=="181002" /*  "In another former USSR republic (EST)" */
		replace `v' ="" if `v'=="189000" /*  "One of the former Yugoslav republics" */
		replace `v' ="" if `v'=="189001" /*  "One of the other former Yugoslav republics (HRV)" */
		replace `v' ="" if `v'=="189002" /*  "One of the other former Yugoslav republics (SRB)" */
		replace `v' ="" if `v'=="119001" /*  "Another American country [URY]" */
		replace `v' ="" if `v'=="178411" /*  "Another Arabic country (QAR)" */
		replace `v' ="" if `v'=="100501" /*  "South, Latin  and Central America" */
		replace `v' ="" if `v'=="181003" /*  "In another former USSR republic (GEO)" */
		replace `v' ="" if `v'=="099000" /*  "ZedlandA" */
		replace `v' ="" if `v'=="099100" /*  "ZedlandB" */
		replace `v' ="" if `v'=="099200" /*  "ZedlandC" */
		replace `v' ="" if `v'=="099300" /*  "ZedlandD" */
		replace `v' ="" if `v'=="099400" /*  "ZedlandE" */
		replace `v' ="" if `v'=="099500" /*  "ZedlandF" */
		replace `v' ="" if `v'=="099600" /*  "ZedlandG" */
		replace `v' ="" if `v'=="099700" /*  "ZedlandH" */
		replace `v' ="" if `v'=="099800" /*  "ZedlandJ" */
		replace `v' ="" if `v'=="099900" /*  "ZedlandK" */			
		replace `v' ="" if `v'=="181004" /*  "In another former USSR republic (KAZ)" */
		replace `v' ="" if `v'=="115006" /*  "Other European country (ITA)" */
		replace `v' ="" if `v'=="178401" /*  "Another State of the Gulf Cooperation Council (ARE)" */
		replace `v' ="" if `v'=="000000" /*  "Not selected" */
	}

	foreach v of varlist bcntry* {
		destring `v', replace
		label values `v' bcntry
		replace `v' = . if `v' == 777777 | `v' == 888888 |`v' == 999999 |`v' == 999998 | `v' == 999997
		replace  `v'=. if `v'>900000
		sdecode `v', replace
	}

	**********************************
	* Age of arrival in test country *
	**********************************
		
		gen 	migage=.
		replace migage=st21q01 if !missing(st21q01)
		recode 	migage (9997=.) (9998=.) (9999=.)
		replace migage=. if migage>age & !missing(migage)
		replace migage=. if stubrncnt==1 & !missing(migage)

	***************************
	* Language spoken at home *
	***************************
		recode st25q01 (7=.) (8=.) (9=.)
		
		gen 	stulanguage=.
		replace stulanguage =1 if st25q01==1
		replace stulanguage =2 if st19q01==2
				
		gen 	otherlang=0 if stulanguage!=.
		replace otherlang=1 if stulanguage==2

	*********************
	* Family Ressources *
	*********************
		*books at home *
		gen 	books =  st28q01   
		recode  books (7=.) (8=.) (9=.)
			
		foreach num of numlist 1/4{
			gen dbook`num'=0 if books!=.
		}
		
		replace dbook1=1 if books==1 
		replace dbook2=1 if books==2| books==3
		replace dbook3=1 if books==4| books==5
		replace dbook4=1 if books==6

		*computers
		
		gen		comp_home=st26q04
		label var comp_home "computer at home"
		recode  comp_home (7=.) (8=.) (9=.) (2=0)
			
	**************************
	* location of the school *
	**************************
		gen 	schoolloc=sc03q01 
		replace schoolloc=. if sc03q01==7 | sc03q01==8 | sc03q01==9
		tab 	schoolloc, gen(dloc)

	**********************
	* number of students *
	**********************
		*boys
		gen 	numstudmale=   sc07q01 
		replace numstudmale=. if sc07q01>9000
		*girls
		gen 	numstudfemale= sc07q02
		replace numstudfemale=. if sc07q02>9000
		*total
		gen numstudtotal=numstudfemale+numstudmale if numstudfemale!=. & numstudmale !=.

	**************
	* Management *
	**************
		gen 	private=0 if  sc01q01==1 //sc03q01: 1=public, 2=private*/
		replace private=1 if  sc01q01==2

	**************************************
	* Share of school financing by [...] *
	**************************************
		replace sc02q01 =. if sc02q01>9000
		gen schoolbudgetgov  = sc02q01 /100
		
	*************************************
	* Teachers: full time and part time *
	*************************************
	
		*************************
		* teacher certification *
		*************************
						
			*variable generated by PISA already
				gen 	cert_teachers=propcert 
				label var cert_teachers "share certified teachers"
				recode cert_teachers (9997=.) (9998=.) (9999=.)

	*******************************************
	* Availability of infrastructure/material *
	*******************************************

		recode sc14q06 (7=.) (8=.) (9=.)
		
		gen 	shormat=0 if sc14q06==1 | sc14q06==2
		replace shormat=1 if sc14q06==3 | sc14q06==4
						
	************
	* Autonomy *
	************	

		**** choosing which textbooks are used
		gen 	auttextbook=1
		replace auttextbook=0 if sc33q10d==1 | sc33q10e==1
		replace auttextbook=. if sc33q10a==2 & sc33q10b==2 & sc33q10c==2 & sc33q10d==2 & sc33q10e==2 
		replace auttextbook=. if (sc33q10a==. | sc33q10a==8 | sc33q10a==7) & (sc33q10b==. | sc33q10b==8 | sc33q10b==7) & (sc33q10c==. | sc33q10c==8 | sc33q10c==7) & (sc33q10d==. | sc33q10d==8 | sc33q10d==7) & (sc33q10e==. | sc33q10e==8 | sc33q10e==7) 

		**** determining course content
		gen 	autcontent=1 
		replace autcontent=0 if sc33q11d==1 | sc33q11e==1
		replace autcontent=. if sc33q11a==2 & sc33q11b==2 & sc33q11c==2 & sc33q11d==2 & sc33q11e==2 
		replace autcontent=. if (sc33q11a==. | sc33q11a==8 | sc33q11a==7) & (sc33q11b==. | sc33q11b==8 | sc33q11b==7) & (sc33q11c==. | sc33q11c==8 | sc33q11c==7) & (sc33q11d==. | sc33q11d==8 | sc33q11d==7) & (sc33q11e==. | sc33q11e==8 | sc33q11e==7) 
		 
		**** deciding which courses are offered
		gen 	autcourses=1 
		replace autcourses=0 if sc33q12d==1 | sc33q12e==1
		replace autcourses=. if sc33q12a==2 & sc33q12b==2 & sc33q12c==2 & sc33q12d==2 & sc33q12e==2 
		replace autcourses=. if (sc33q12a==. | sc33q12a==8 | sc33q12a==7) & (sc33q12b==. | sc33q12b==8 | sc33q12b==7) & (sc33q12c==. | sc33q12c==8 | sc33q12c==7) & (sc33q12d==. | sc33q12d==8 | sc33q12d==7) & (sc33q12e==. | sc33q12e==8 | sc33q12e==7) 
		     
*************************************
* Generate variable indicating wave *
*************************************
	gen wave=2012

*********************************
* rename to make merge possible *
*********************************
	rename  w_fschwt scweight

*** drop vars not needed

#delimit;
keep pv1read pv1scie pv*math
	 age female
	 whithigh whitlow bluehigh bluelow dhisced*
	 im1 im2 otherlang migage stubrncnt motbrncnt fatbrncnt bcntry*
	 dbook* comp_home
		 dloc* numstudtotal private schoolbudgetgov cert_teachers shormat
		 auttextbook autcontent autcourses
			oecd w_fstuwt w_fstr* wave cnt country schoolid studid
;
#delimit cr

destring _all, replace
	
compress
save "$path/Data/Working/stsch_2012_renamed.dta", replace
	erase "$path/Data/Working/stsch_2012.dta"

```

### `Replication/Do/1a6_2015.do`
```stata
use "$path/Data/Working/stsch_2015.dta", replace
	rename *, lower

***************************
* STUDENT LEVEL VARIABLES *
***************************		

	**********
	* Gender *
	**********
		gen 	female = .
		replace female=1 if  st004d01t ==1
		replace female=0 if  st004d01t ==2
		
	**********************
	* Parents' education *
	**********************
	
		replace misced=. if misced==. | misced==.i | misced==.m | misced==.n
		tab 	misced, gen(dmisced)
		replace dmisced6=1 if dmisced7==1
		drop 	dmisced7

		replace fisced=. if fisced==. | fisced==.i | fisced==.m | fisced==.n
		tab 	fisced, gen(dfisced)
		replace dfisced6=1 if dfisced7==1
		drop 	dfisced7

		replace hisced=. if hisced==.i | hisced==.m | hisced==.n
		tab 	hisced, gen(dhisced)
		replace dhisced6=1 if dhisced7==1
		drop 	dhisced7	
 
	****************
	* Parents' job *
	****************
	
		destring ocod1,replace
		destring ocod2,replace

		gen 	occumoth=ocod1
		replace occumoth=. if ocod1==9997 |  ocod1==9998 |  ocod1==9999

		gen 	occufath=ocod2
		replace occufath=. if ocod2==9997 |  ocod2==9998 |  ocod2==9999

		replace occumoth=1 if ocod1>=1000&ocod1<4000 				//managers, professionals, technicians and associate professionals
		replace occumoth=2 if (ocod1>=4000&ocod1<6000)|ocod1<1000 	//clerical support workers, services and sales workers, armed forces occupations
		replace occumoth=3 if ocod1>=6000&ocod1<8000 				//skilled agricultural, forestry and fishery workers; craft and related trades workers
		replace occumoth=4 if ocod1>=8000&ocod1<9900 				//plant and  machine operators and assemblers, elementary occupations

		replace occufath=1 if ocod2>=1000&ocod2<4000
		replace occufath=2 if (ocod2>=4000&ocod2<6000)|ocod2<1000
		replace occufath=3 if ocod2>=6000&ocod2<8000
		replace occufath=4 if ocod2>=8000&ocod2<9900

	
		gen 	mothwhithigh=0 if occumoth!=.
		replace mothwhithigh=1 if occumoth==1
		gen 	fathwhithigh=0 if occufath!=.
		replace fathwhithigh=1 if occufath==1
		gen 	mothwhitlow=0 if occumoth!=.
		replace mothwhitlow=1 if occumoth==2
		gen 	fathwhitlow=0 if occufath!=.
		replace fathwhitlow=1 if occufath==2
		gen 	mothbluehigh=0 if occumoth!=.
		replace mothbluehigh=1 if occumoth==3
		gen 	fathbluehigh=0 if occufath!=.
		replace fathbluehigh=1 if occufath==3
		gen 	mothbluelow=0 if occumoth!=.
		replace mothbluelow=1 if occumoth==4
		gen 	fathbluelow=0 if occufath!=.
		replace fathbluelow=1 if occufath==4

		* create highest occupational status of parents
		gen 	whithigh=0 if mothwhithigh!=. | fathwhithigh!=.
		replace whithigh=1 if mothwhithigh==1 | fathwhithigh==1
		gen 	whitlow=0 if mothwhitlow!=. | fathwhitlow!=.
		replace whitlow=1 if mothwhitlow==1 & whithigh!=1 | fathwhitlow==1 & whithigh!=1
		gen 	bluehigh=0 if mothbluehigh!=. | fathbluehigh!=.
		replace bluehigh=1 if mothbluehigh==1 & whitlow!=1 & whithigh!=1| fathbluehigh==1 & whitlow!=1 & whithigh!=1
		gen 	bluelow=0 if mothbluelow!=. | fathbluelow!=.
		replace bluelow=1 if mothbluelow==1 &  bluehigh!=1 & whitlow!=1 & whithigh!=1 | fathbluelow==1 & bluehigh!=1 & whitlow!=1 & whithigh!=1

	********************
	* Immigrant status *
	********************
		
		* student born in country *
		recode  st019aq01t (.i=.) (.m=.) (.n=.)
		gen 	stubrncnt=.
		replace stubrncnt = 1 if st019aq01t==1 /* student born in test country */
		replace stubrncnt = 0 if st019aq01t==2 /* student born in other country */

		* father born in country *
		recode  st019cq01t (.i=.) (.m=.) (.n=.)
		gen 	fatbrncnt = .
		replace fatbrncnt = 1 if  st019cq01t==1 /* father born in test country*/
		replace fatbrncnt = 0 if  st019cq01t==2
		
		* mother born in country *
		recode  st019bq01t (.i=.) (.m=.) (.n=.)
		gen 	motbrncnt = .
		replace motbrncnt = 1 if st019bq01t==1 /* mother born in test country*/
		replace motbrncnt = 0 if st019bq01t==2
		
		foreach v of varlist stubrncnt fatbrncnt motbrncnt {
			recode `v' (2 = 0) (1 = 1)
			replace `v' = . if `v' >= 97
		}


		*first generation: born abroad (stubrncnt==0) with parents born abroad
		gen 	im1=0
		replace im1=1 if motbrncnt==0 & fatbrncnt==0 & stubrncnt==0 
		replace im1=. if missing(motbrncnt) & missing(fatbrncnt) | missing(stubrncnt)

		*second generation: born in country of test language, parent(s) born abrod
		gen 	im2=0
		replace im2=1 if motbrncnt==0 & fatbrncnt==0 & stubrncnt==1
		replace im2=. if missing(motbrncnt) & missing(fatbrncnt) | missing(stubrncnt)
		
		* countries of origin
		
		rename cobn_m bcntry_m
		rename cobn_f bcntry_f
		rename cobn_s bcntry
		
		label define bcntry ///
			000400  "Afghanistan" ///
			000800  "Albania" ///
			001200  "Algeria" ///
			001600  "American Samoa" ///
			002000  "Andorra" ///
			002400  "Angola" ///
			002800  "Antigua and Barbuda" ///
			002900  "Caribbean" ///
			003100  "Azerbaijan" ///
			003200  "Argentina" ///
			003600  "Australia" ///
			004000  "Austria" ///
			004400  "Bahamas" ///
			004800  "Bahrain" ///
			005000  "Bangladesh" ///
			005100  "Armenia" ///
			005200  "Barbados" ///
			005600  "Belgium" ///
			005601  "Belgium (Flanders)" ///
			005602  "Belgium (French community)" ///
			005603  "Belgium (German community)" ///
			006000  "Bermuda" ///
			006400  "Bhutan" ///
			006800  "Bolivia (Plurinational State of)" ///
			007000  "Bosnia and Herzegovina" ///
			007200  "Botswana" ///
			007600  "Brazil" ///
			008400  "Belize" ///
			009200  "British Virgin Islands" ///
			009600  "Brunei Darussalam" ///
			010000  "Bulgaria" ///
			010400  "Myanmar" ///
			010800  "Burundi" ///
			011200  "Belarus" ///
			011600  "Cambodia" ///
			012000  "Cameroon" ///
			012400  "Canada" ///
			013200  "Cape Verde" ///
			013600  "Cayman Islands" ///
			014000  "Central African Republic" ///
			014400  "Sri Lanka" ///
			014800  "Chad" ///
			015200  "Chile" ///
			015600  "China" ///
			015601  "China (Shanghai)" ///
			015604  "China (Beijing)" ///
			015610  "China (incl. Hong Kong)" ///
			015800  "Chinese Taipei" ///
			017000  "Colombia" ///
			017400  "Comoros" ///
			017500  "Mayotte" ///
			017800  "Congo" ///
			018000  "Democratic Republic of the Congo" ///
			018400  "Cook Islands" ///
			018800  "Costa Rica" ///
			019100  "Croatia" ///
			019200  "Cuba" ///
			020300  "Czech Republic" ///
			020400  "Benin" ///
			020800  "Denmark" ///
			020801  "The Faroe Islands" ///
			020802  "Greenland" ///
			021200  "Dominica" ///
			021400  "Dominican Republic" ///
			021800  "Ecuador" ///
			022200  "El Salvador" ///
			022600  "Equatorial Guinea" ///
			023100  "Ethiopia" ///
			023200  "Eritrea" ///
			023300  "Estonia" ///
			023400  "Faeroe Islands" ///
			023800  "Falkland Islands (Malvinas)" ///
			024200  "Fiji" ///
			024600  "Finland" ///
			024800  "land Islands" ///
			025000  "France" ///
			025400  "French Guiana" ///
			025800  "French Polynesia" ///
			026200  "Djibouti" ///
			026600  "Gabon" ///
			026800  "Georgia" ///
			027000  "Gambia" ///
			027500  "Occupied Palestinian Territory" ///
			027600  "Germany" ///
			028800  "Ghana" ///
			029200  "Gibraltar" ///
			029600  "Kiribati" ///
			030000  "Greece" ///
			030400  "Greenland" ///
			030800  "Grenada" ///
			031200  "Guadeloupe" ///
			031600  "Guam" ///
			032000  "Guatemala" ///
			032400  "Guinea" ///
			032800  "Guyana" ///
			033200  "Haiti" ///
			033600  "Holy See" ///
			034000  "Honduras" ///
			034400  "Hong Kong-China" ///
			034800  "Hungary" ///
			035200  "Iceland" ///
			035600  "India" ///
			035610  "India (2009 States)" ///
			036000  "Indonesia" ///
			036400  "Iran, Islamic Republic of" ///
			036800  "Iraq" ///
			037200  "Ireland" ///
			037600  "Israel" ///
			038000  "Italy" ///
			038001  "Provincia Autonoma of Bolzano (ITA)" ///
			038002  "Provincia Basilicata (ITA)" ///
			038003  "Provincia Campania (ITA)" ///
			038004  "Provincia Emilia Romagna (ITA)" ///
			038005  "Provincia Friuli Venezia Giulia (ITA)" ///
			038006  "Provincia Liguria (ITA)" ///
			038007  "Provincia Lombardia (ITA)" ///
			038008  "Provincia Piemonte (ITA)" ///
			038009  "Provincia Puglia (ITA)" ///
			038010  "Provincia Sardegna (ITA)" ///
			038011  "Provincia Sicilia (ITA)" ///
			038012  "Provincia Trento (ITA)" ///
			038013  "Provincia Veneto (ITA)" ///
			038014  "The rest of Italy (ITA)" ///
			038400  "C™te d'Ivoire" ///
			038800  "Jamaica" ///
			039200  "Japan" ///
			039800  "Kazakhstan" ///
			040000  "Jordan" ///
			040400  "Kenya" ///
			040800  "Democratic People's Republic of Korea" ///
			041000  "Republic of Korea" ///
			041100	"Kosovo" ///
			041400  "Kuwait" ///
			041700  "Kyrgyzstan" ///
			041800  "Lao People's Democratic Republic" ///
			042200  "Lebanon" ///
			042600  "Lesotho" ///
			042800  "Latvia" ///
			043000  "Liberia" ///
			043400  "Libyan Arab Jamahiriya" ///
			043800  "Liechtenstein" ///
			044000  "Lithuania" ///
			044200  "Luxembourg" ///
			044600  "Macao-China" ///
			045000  "Madagascar" ///
			045400  "Malawi" ///
			045800  "Malaysia" ///
			046200  "Maldives" ///
			046600  "Mali" ///
			047000  "Malta" ///
			047400  "Martinique" ///
			047800  "Mauritania" ///
			048000  "Mauritius" ///
			048400  "Mexico" ///
			049200  "Monaco" ///
			049600  "Mongolia" ///
			049800  "Republic of Moldova" ///
			049900  "Montenegro" ///
			050000  "Montserrat" ///
			050400  "Morocco" ///
			050800  "Mozambique" ///
			051200  "Oman" ///
			051600  "Namibia" ///
			052000  "Nauru" ///
			052400  "Nepal" ///
			052800  "Netherlands" ///
			053000  "Netherlands Antilles" ///
			053300  "Aruba" ///
			054000  "New Caledonia" ///
			054800  "Vanuatu" ///
			055400  "New Zealand" ///
			055800  "Nicaragua" ///
			056200  "Niger" ///
			056600  "Nigeria" ///
			057000  "Niue" ///
			057400  "Norfolk Island" ///
			057800  "Norway" ///
			058000  "Northern Mariana Islands" ///
			058300  "Micronesia, Federated States of" ///
			058400  "Marshall Islands" ///
			058500  "Palau" ///
			058600  "Pakistan" ///
			059100  "Panama" ///
			059800  "Papua New Guinea" ///
			060000  "Paraguay" ///
			060400  "Peru" ///
			060800  "Philippines" ///
			061200  "Pitcairn" ///
			061600  "Poland" ///
			062000  "Portugal" ///
			062400  "Guinea-Bissau" ///
			062600  "Timor-Leste" ///
			063000  "Puerto Rico" ///
			063400  "Qatar" ///
			063800  "RŽunion" ///
			064200  "Romania" ///
			064300  "Russian Federation" ///
			064600  "Rwanda" ///
			065200  "Saint-BarthŽlemy" ///
			065400  "Saint Helena" ///
			065900  "Saint Kitts and Nevis" ///
			066000  "Anguilla" ///
			066200  "Saint Lucia" ///
			066300  "Saint-Martin (French part)" ///
			066600  "Saint Pierre and Miquelon" ///
			067000  "Saint Vincent and the Grenadines" ///
			067400  "San Marino" ///
			067800  "Sao Tome and Principe" ///
			068200  "Saudi Arabia" ///
			068600  "Senegal" ///
			068800  "Serbia" ///
			069000  "Seychelles" ///
			069400  "Sierra Leone" ///
			070200  "Singapore" ///
			070300  "Slovak Republic" ///
			070400  "Viet Nam" ///
			070500  "Slovenia" ///
			070600  "Somalia" ///
			071000  "South Africa" ///
			071600  "Zimbabwe" ///
			072400  "Spain" ///
			072401  "Andalusia (ESP)" ///
			072402  "Aragon (ESP)" ///
			072403  "Asturias (ESP)" ///
			072404  "Balearic Islands (ESP)" ///
			072405  "Canary Islands (ESP)" ///
			072406  "Cantabria (ESP)" ///
			072407  "Castile-La Mancha (ESP)" ///
			072408  "Castile and Leon (ESP)" ///
			072409  "Catalonia (ESP)" ///
			072410  "Extremadura (ESP)" ///
			072411  "Galicia (ESP)" ///
			072412  "La Rioja (ESP)" ///
			072413  "Madrid (ESP)" ///
			072414  "Murcia (ESP)" ///
			072415  "Navarre (ESP)" ///
			072416  "Basque Country (ESP)" ///
			072417  "Valencian Community (ESP)" ///
			072418  "Ceuta and Melilla (ESP)" ///
			072419  "The rest of Spain (ESP)" ///
			073200  "Western Sahara" ///
			073600  "Sudan" ///
			074000  "Suriname" ///
			074400  "Svalbard and Jan Mayen Islands" ///
			074800  "Swaziland" ///
			075200  "Sweden" ///
			075600  "Switzerland" ///
			075601  "Switzerland (German-speaking community)" ///
			075602  "Switzerland (French-speaking community)" ///
			075603  "Switzerland (Italian-speaking community)" ///
			076000  "Syrian Arab Republic" ///
			076200  "Tajikistan" ///
			076400  "Thailand" ///
			076800  "Togo" ///
			077200  "Tokelau" ///
			077600  "Tonga" ///
			078000  "Trinidad and Tobago" ///
			078400  "United Arab Emirates" ///
			078410  "United Arab Emirates (Dubai)" ///
			078411  "Another Arabic country (ARE)" ///
			078420  "United Arab Emirates (ex.Dubai)" ///
			078800  "Tunisia" ///
			079200  "Turkey" ///
			079500  "Turkmenistan" ///
			079600  "Turks and Caicos Islands" ///
			079800  "Tuvalu" ///
			080000  "Uganda" ///
			080400  "Ukraine" ///
			080700  "FYR Macedonia" ///
			081800  "Egypt" ///
			082600  "United Kingdom" ///
			082610  "United Kingdom (excl.Scotland)" ///
			082611  "United Kingdom (England)" ///
			082612  "United Kingdom (Northern Ireland)" ///
			082613  "United Kingdom (Wales)" ///
			082620  "United Kingdom (Scotland)" ///
			082640  "United Kingdom (Great Britain)" ///
			083000  "Channel Islands" ///
			083100  "Guernsey" ///
			083200  "Jersey" ///
			083300  "Isle of Man" ///
			083400  "United Republic of Tanzania" ///
			084000  "United States of America" ///
			085000  "United States Virgin Islands" ///
			085400  "Burkina Faso" ///
			085800  "Uruguay" ///
			086000  "Uzbekistan" ///
			086200  "Venezuela (Bolivarian Republic of)" ///
			087600  "Wallis and Futuna Islands" ///
			088200  "Samoa" ///
			088700  "Yemen" ///
			089400  "Zambia" ///
			009000  "Solomon Islands" ///
			100200  "Africa" ///
			100201  "African country with Portuguese as the official language" ///
			100202  "A Sub-Saharan country (Africa excl. Maghreb)" ///
			100204  "North African country (Maghreb)" ///
			114500  "Middle Eastern country" ///
			115000  "A European country" ///
			115001  "Other Western European country (BEL)" ///
			115009  "Another country within the European Union (MLT)" ///
			115002  "Another country within the European Union (ITA)" ///
			115003  "Other European Union Country (LUX)" ///
			115004  "A country from European Union (PRT)" ///
			115005  "A European country that is not a member of the European Union" ///
			115007  "Other European country (NLD)" ///
			115008  "Other European country (QSC)" ///
			115010	"Other European country (DNK)" ///
			115100  "An Eastern European country" ///
			115106  "An Eastern European country outside the EU" ///
			116001	"Other non-European country (DNK)" ///
			181000  "One of the former USSR republics" ///
			181001  "In another former USSR republic (RUS)" ///
			181002  "In another former USSR republic (EST)" ///
			189000  "One of the former Yugoslav republics" ///
			189001  "One of the other former Yugoslav republics (HRV)" ///
			189002  "One of the other former Yugoslav republics (SRB)" ///
			189003  "Serbia and Montenegro" ///
			900800  "Another country (ALB)" ///
			903100  "Another country (AZE)" ///
			903200  "Another country (ARG)" ///
			903600  "Another country (AUS)" ///
			904000  "Another country (AUT)" ///
			905600  "Another country (BEL)" ///
			907600  "Another country (BRA)" ///
			910000  "Another country (BGR)" ///
			912400  "Another country (CAN)" ///
			915200  "Another country (CHL)" ///
			915601  "Another country (QCN )" ///
			915604  "Another country (QCH )" ///
			915800  "Another country (TAP)" ///
			917000  "Another country (COL)" ///
			919100  "Another country (HRV)" ///
			920300  "Another country (CZE)" ///
			920800  "Another country (DNK)" ///
			921400  "Another country (DOM)" ///
			923300  "Another country (EST)" ///
			924600  "Another country (FIN)" ///
			925000  "Another country (FRA)" ///
			927600  "Another country (DEU)" ///
			930000  "Another country (GRC)" ///
			934400  "Another country (HKG)" ///
			934800  "Another country (HUN)" ///
			935200  "Another country (ISL)" ///
			936000  "Another country (IDN)" ///
			937200  "Another country (IRL)" ///
			937600  "Another country (ISR)" ///
			938000  "Another country (ITA)" ///
			939200  "Another country (JPN)" ///
			939800  "Another country (KAZ)" ///
			940000  "Another country (JOR)" ///
			941000  "Another country (KOR)" ///
			941700  "Another country (KGZ)" ///
			942800  "Another country (LVA)" ///
			943800  "Another country (LIE)" ///
			944000  "Another country (LTU)" ///
			944200  "Another country (LUX)" ///
			944600  "Another country (MAC)" ///
			948400  "Another country (MEX)" ///
			949800  "Another country (MDA)" ///
			949900  "Another country (MNE)" ///
			952800  "Another country (NLD)" ///
			955400  "Another country (NZL)" ///
			957800  "Another country (NOR)" ///
			959100  "Another country (PAN )" ///
			960400  "Another country (PER)" ///
			961600  "Another country (POL)" ///
			962000  "Another country (PRT)" ///
			963400  "Another country (QAT)" ///
			964200  "Another country (ROU)" ///
			964300  "Another country (RUS)" ///
			968800  "Another country (SRB)" ///
			970200  "Another country (SGP)" ///
			970300  "Another country (SVK)" ///
			970500  "Another country (SVN)" ///
			972400  "Another country (ESP)" ///
			975200  "Another country (SWE)" ///
			975600  "Another country (CHE)" ///
			976400  "Another country (THA)" ///
			985800  "Another country (URY)" ///
			978000  "Another country (TTO)" ///
			978410  "Another country (QAR)" ///
			978800  "Another country (TUN)" ///
			979200  "Another country (TUR)" ///
			980700  "Another country (MKD)" ///
			982600  "Another country (GBR)" ///
			982610  "Another country (QUK)" ///
			982620  "Another country (QSC)" ///
			984000  "Another country (USA)" ///
			918800  "Another country (CRI)" ///
			926800  "Another country (GEO)" ///
			935610  "Another country (QIN)" ///
			945800  "Another country (MYS)" ///
			947000  "Another country (MLT)" ///
			948000  "Another country (MUS)" ///
			978420  "Another country (QRE)" ///
			015602  "Another province in mainland China (QCN)" ///
			015605  "Another province in mainland China (QCH)" ///
			015603  "Hong Kong, Macau, Taiwan" ///
			119001  "Another American country [URY]" ///
			178411  "Another Arabic country (QAR)" ///
			100501  "South, Latin  and Central America" ///
			078421  "Abu Dhabi (QRE)" ///
			078422  "Al Ain (QRE)" ///
			078423  "Western Region (QRE)" ///
			078424  "Sharjah (QRE)" ///
			078425  "Ajman (QRE)" ///
			078426  "Umm Al Quain (QRE)" ///
			078427  "Fujaurah (QRE)" ///
			078428  "Ras Al Khaimah (QRE)" ///
			086201  "Venezuela (Miranda)" ///
			986201  "Another country (QVE )" ///
			086220  "Venezuela (ex. Miranda)" ///
			181003  "In another former USSR republic (GEO)" ///
			099000  "ZedlandA" ///
			099100  "ZedlandB" ///
			099200  "ZedlandC" ///
			099300  "ZedlandD" ///
			099400  "ZedlandE" ///
			099500  "ZedlandF" ///
			099600  "ZedlandG" ///
			099700  "ZedlandH" ///
			099800  "ZedlandJ" ///
			099900  "ZedlandK" ///
			999000  "Another country (ZZA)" ///
			999100  "Another country (ZZB)" ///
			999200  "Another country (ZZC)" ///
			999300  "Another country (ZZD)" ///
			999400  "Another country (ZZE)" ///
			999500  "Another country (ZZF)" ///
			999600  "Another country (ZZG)" ///
			999700  "Another country (ZZH)" ///
			999800  "Another country (ZZJ)" ///
			999900  "Another country (ZZK)" ///
			978400  "Another Country (ARE)" ///
			919600  "Another Country (CYP)" ///
			970400  "Another Country (VNM)" ///
			181004  "In another former USSR republic (KAZ)" ///
			115006  "Other European country (ITA)" ///
			178401  "Another State of the Gulf Cooperation Council (ARE)" ///
			189004  "Serbia, Montenegro and Kosovo" ///
			089005  "Kosovo" /// 
			064301  "Perm (Russian Federation)" ///
			064302  "Another region of the Russian Federation" ///
			000000  "Not selected" ///
			777777  "N/A" ///
			888888  "Invalid" ///
			999997  "N/A" ///
			999998  "Invalid" ///
			999999  "Missing"

	foreach v of varlist bcntry* {
		replace `v' ="" if `v'=="100200" /* Africa" */
		replace `v' ="" if `v'=="100201" /*  "African country with Portuguese as the official language" */
		replace `v' ="" if `v'=="100202" /*  "A Sub-Saharan country (Africa excl. Maghreb)" */
		replace `v' ="" if `v'=="100204" /*  "North African country (Maghreb)" */
		replace `v' ="" if `v'=="114500" /*  "Middle Eastern country" */
		replace `v' ="" if `v'=="115000" /*  "A European country" */
		replace `v' ="" if `v'=="115001" /*  "Other Western European country (BEL)" */
		replace `v' ="" if `v'=="115009" /*  "Another country within the European Union (MLT)" */
		replace `v' ="" if `v'=="115002" /*  "Another country within the European Union (ITA)" */
		replace `v' ="" if `v'=="115003" /*  "Other European Union Country (LUX)" */
		replace `v' ="" if `v'=="115004" /*  "A country from European Union (PRT)" */
		replace `v' ="" if `v'=="115005" /*  "A European country that is not a member of the European Union" */
		replace `v' ="" if `v'=="115007" /*  "Other European country (NLD)" */
		replace `v' ="" if `v'=="115008" /*  "Other European country (QSC)" */
		replace `v' ="" if `v'=="115100" /*  "An Eastern European country" */
		replace `v' ="" if `v'=="115106" /*  "An Eastern European country outside the EU" */
		replace `v' ="" if `v'=="181000" /*  "One of the former USSR republics" */
		replace `v' ="" if `v'=="181001" /*  "In another former USSR republic (RUS)" */
		replace `v' ="" if `v'=="181002" /*  "In another former USSR republic (EST)" */
		replace `v' ="" if `v'=="189000" /*  "One of the former Yugoslav republics" */
		replace `v' ="" if `v'=="189001" /*  "One of the other former Yugoslav republics (HRV)" */
		replace `v' ="" if `v'=="189002" /*  "One of the other former Yugoslav republics (SRB)" */
		replace `v' ="" if `v'=="119001" /*  "Another American country [URY]" */
		replace `v' ="" if `v'=="178411" /*  "Another Arabic country (QAR)" */
		replace `v' ="" if `v'=="100501" /*  "South, Latin  and Central America" */
		replace `v' ="" if `v'=="181003" /*  "In another former USSR republic (GEO)" */
		replace `v' ="" if `v'=="099000" /*  "ZedlandA" */
		replace `v' ="" if `v'=="099100" /*  "ZedlandB" */
		replace `v' ="" if `v'=="099200" /*  "ZedlandC" */
		replace `v' ="" if `v'=="099300" /*  "ZedlandD" */
		replace `v' ="" if `v'=="099400" /*  "ZedlandE" */
		replace `v' ="" if `v'=="099500" /*  "ZedlandF" */
		replace `v' ="" if `v'=="099600" /*  "ZedlandG" */
		replace `v' ="" if `v'=="099700" /*  "ZedlandH" */
		replace `v' ="" if `v'=="099800" /*  "ZedlandJ" */
		replace `v' ="" if `v'=="099900" /*  "ZedlandK" */			
		replace `v' ="" if `v'=="181004" /*  "In another former USSR republic (KAZ)" */
		replace `v' ="" if `v'=="115006" /*  "Other European country (ITA)" */
		replace `v' ="" if `v'=="178401" /*  "Another State of the Gulf Cooperation Council (ARE)" */
		replace `v' ="" if `v'=="000000" /*  "Not selected" */
	}

	foreach v of varlist bcntry* {
		destring `v', replace
		label values `v' bcntry
		replace `v' = . if `v' == 777777 | `v' == 888888 |`v' == 999999 |`v' == 999998 | `v' == 999997
		replace  `v'=. if `v'>900000
		sdecode `v', replace
	}

	
	**********************************
	* Age of arrival in test country *
	**********************************
		
		gen 	migage=.
		replace migage=st021q01ta if !missing(st021q01ta)
		recode 	migage (.m=.) (.n=.) (.v=.)
		recode 	migage (1=0) (2=1) (3=2) (4=3) (5=4) (6=5) (7=6) (8=7) (9=8) (10=9) (11=10) (12=11) (13=12) (14=13) (15=14) (16=15) (17=16)
		replace migage=. if migage>age & !missing(migage) //these are all migage 16 and age 15-16 but smaller than 16
		replace migage=. if stubrncnt==1 & !missing(migage) //moslty 0, 1,145>0
		
		
	***************************
	* Language spoken at home *
	***************************
	
		recode st022q01ta (.i=.) (.m=.) (.n=.)

		gen 	stulanguage=.
		replace stulanguage=1 if st022q01ta==1
		replace stulanguage=2 if st022q01ta==2
			
		gen 	otherlang=0 if !missing(stulanguage)
		replace otherlang=1 if stulanguage==2


	*********************
	* Family Ressources *
	*********************
	
		*books at home*
			gen 	books =  st013q01ta     
			replace books=. if books==.i | books==.n | books==.m
			
			foreach num of numlist 1/4{
				gen dbook`num'=0 if books!=.
				}
			replace dbook1=1 if books==1 
			replace dbook2=1 if books==2| books==3
			replace dbook3=1 if books==4| books==5
			replace dbook4=1 if books==6	

		* comp_home
			gen    comp_home=st011q04ta
			recode comp_home (.i=.) (.m=.) (.n=.)
			recode comp_home (2=0)
				
********************************************************************************
************************* SCHOOL QUESTIONNAIRE *********************************
********************************************************************************

	**************************
	* location of the school *
	**************************
		gen schoolloc=sc001q01ta 
		replace schoolloc=. if sc001q01ta==.i | sc001q01ta==.m
		tab schoolloc, gen(dloc)		

	**********************
	* number of students *
	**********************
		*boys
		gen 	numstudmale=sc002q01ta if !missing(sc002q01ta)
		*girls
		gen 	numstudfemale=sc002q02ta if !missing(sc002q02ta)
		*total
		gen 	numstudtotal=numstudfemale+numstudmale if !missing(numstudfemale) & !missing(numstudmale)
		
	**************
	* management *
	**************
		gen 	private=0 if  sc013q01ta==1
		replace private=1 if  sc013q01ta==2

	**************************************
	* share of school financing by [...] *
	**************************************

		gen schoolbudgetgov  = sc016q01ta/100 if !missing(sc016q01ta) //Government

	*************************************
	* Teachers: full time and part time *
	*************************************
	
		*teacher: certification 
				
			*variable generated by PISA already
				gen 	cert_teachers=proatce if !missing(proatce)
				label var cert_teachers "Share certified teachers"
				
	*******************************************
	* Availability of infrastructure/material *
	*******************************************

		* School instruction hindered by:
			* lack of educational materials		
			gen 	shormat=0 if sc017q05na==1 | sc017q05na==2  
			replace shormat=1 if sc017q05na==3 | sc017q05na==4			
			
	************
	* autonomy *
	************
		**** choosing which textbooks are used
		gen auttextbook=1
		replace auttextbook=0 if sc010q10td==1 | sc010q10te==1
		replace auttextbook=. if sc010q10ta==2 & sc010q10tb==2 & sc010q10tc==2 & sc010q10td==2 & sc010q10te==2 
		replace auttextbook=. if !missing(sc010q10ta) & !missing(sc010q10tb) & !missing(sc010q10tc) & !missing(sc010q10td) & !missing(sc010q10te) 

		**** determining course content
		gen autcontent=1 
		replace autcontent=0 if sc010q11td==1 | sc010q11te==1
		replace autcontent=. if sc010q11ta==2 & sc010q11tb==2 & sc010q11tc==2 & sc010q11td==2 & sc010q11te==2 
		replace autcontent=. if !missing(sc010q11ta) & !missing(sc010q11tb) & !missing(sc010q11tc) & !missing(sc010q11td) & !missing(sc010q11te) 

		**** deciding which courses are offered
		gen autcourses=1 
		replace autcourses=0 if sc010q12td==1 | sc010q12te==1
		replace autcourses=. if sc010q12ta==2 & sc010q12tb==2 & sc010q12tc==2 & sc010q12td==2 & sc010q12te==2 
		replace autcourses=. if !missing(sc010q12ta) & !missing(sc010q12tb) & !missing(sc010q12tc) & !missing(sc010q12td) & !missing(sc010q12te)
     
******************************************
*Generate variable indicating wave
******************************************
	gen wave=2015


	rename w_schgrnrabwt scweight
		
*** drop vars not needed

#delimit;
keep pv1read pv1scie pv*math
	 age female
	 whithigh whitlow bluehigh bluelow dhisced*
	 im1 im2 otherlang migage stubrncnt motbrncnt fatbrncnt bcntry*
	 dbook* comp_home
		 dloc* numstudtotal private schoolbudgetgov cert_teachers shormat
		 auttextbook autcontent autcourses
			oecd w_fstuwt w_fsturwt* wave cnt country schoolid studid
;
#delimit cr
	
forvalues i = 1(1) 80 {
	rename w_fsturwt`i' w_fstr`i'
}
	
destring _all, replace

compress
save "$path/Data/Working/stsch_2015_renamed.dta",replace
	erase "$path/Data/Working/stsch_2015.dta"

```

### `Replication/Do/1a7_2018.do`
```stata
use "$path/Data/Working/stsch_2018.dta", replace

	rename *, lower

***************************
* STUDENT LEVEL VARIABLES *
***************************		

	**********
	* Gender *
	**********
		gen female = .
		replace female=1 if  st004d01t ==1
		replace female=0 if  st004d01t ==2

	**********************
	* Parents' education *
	**********************
	
		tab misced, gen(dmisced)
		replace dmisced6=1 if dmisced7==1
		drop 	dmisced7

		tab 	fisced, gen(dfisced)
		replace dfisced6=1 if dfisced7==1
		drop 	dfisced7

		tab 	hisced, gen(dhisced)
		replace dhisced6=1 if dhisced7==1
		drop 	dhisced7	
 
	****************
	* Parents' job *
	****************
	
		destring ocod1,replace
		destring ocod2,replace

		gen 	occumoth=ocod1
		replace occumoth=. if ocod1==9997 |  ocod1==9998 |  ocod1==9999

		gen 	occufath=ocod2
		replace occufath=. if ocod2==9997 |  ocod2==9998 |  ocod2==9999

		replace occumoth=1 if ocod1>=1000&ocod1<4000 				//managers, professionals, technicians and associate professionals
		replace occumoth=2 if (ocod1>=4000&ocod1<6000)|ocod1<1000 	//clerical support workers, services and sales workers, armed forces occupations
		replace occumoth=3 if ocod1>=6000&ocod1<8000 				//skilled agricultural, forestry and fishery workers; craft and related trades workers
		replace occumoth=4 if ocod1>=8000&ocod1<9900 				//plant and  machine operators and assemblers, elementary occupations

		replace occufath=1 if ocod2>=1000&ocod2<4000
		replace occufath=2 if (ocod2>=4000&ocod2<6000)|ocod2<1000
		replace occufath=3 if ocod2>=6000&ocod2<8000
		replace occufath=4 if ocod2>=8000&ocod2<9900

	
		gen 	mothwhithigh=0 if occumoth!=.
		replace mothwhithigh=1 if occumoth==1
		gen 	fathwhithigh=0 if occufath!=.
		replace fathwhithigh=1 if occufath==1
		gen 	mothwhitlow=0 if occumoth!=.
		replace mothwhitlow=1 if occumoth==2
		gen 	fathwhitlow=0 if occufath!=.
		replace fathwhitlow=1 if occufath==2
		gen 	mothbluehigh=0 if occumoth!=.
		replace mothbluehigh=1 if occumoth==3
		gen 	fathbluehigh=0 if occufath!=.
		replace fathbluehigh=1 if occufath==3
		gen 	mothbluelow=0 if occumoth!=.
		replace mothbluelow=1 if occumoth==4
		gen 	fathbluelow=0 if occufath!=.
		replace fathbluelow=1 if occufath==4

		* create highest occupational status of parents
		gen 	whithigh=0 if mothwhithigh!=. | fathwhithigh!=.
		replace whithigh=1 if mothwhithigh==1 | fathwhithigh==1
		gen 	whitlow=0 if mothwhitlow!=. | fathwhitlow!=.
		replace whitlow=1 if mothwhitlow==1 & whithigh!=1 | fathwhitlow==1 & whithigh!=1
		gen 	bluehigh=0 if mothbluehigh!=. | fathbluehigh!=.
		replace bluehigh=1 if mothbluehigh==1 & whitlow!=1 & whithigh!=1| fathbluehigh==1 & whitlow!=1 & whithigh!=1
		gen 	bluelow=0 if mothbluelow!=. | fathbluelow!=.
		replace bluelow=1 if mothbluelow==1 &  bluehigh!=1 & whitlow!=1 & whithigh!=1 | fathbluelow==1 & bluehigh!=1 & whitlow!=1 & whithigh!=1

	********************
	* Immigrant status *
	********************
		
		* student born in country *
		gen 	stubrncnt=.
		replace stubrncnt = 1 if st019aq01t==1 /* student born in test country */
		replace stubrncnt = 0 if st019aq01t==2 /* student born in other country */

		* father born in country *
		gen 	fatbrncnt = .
		replace fatbrncnt = 1 if st019cq01t==1 /* father born in test country*/
		replace fatbrncnt = 0 if st019cq01t==2
		
		* mother born in country *
		gen 	motbrncnt = .
		replace motbrncnt = 1 if st019bq01t==1 /* mother born in test country*/
		replace motbrncnt = 0 if st019bq01t==2
		
		foreach v of varlist stubrncnt fatbrncnt motbrncnt {
			recode `v' (2 = 0) (1 = 1)
			replace `v' = . if `v' >= 97
		}


		*first generation: born abroad (stubrncnt==0) with parents born abroad
		gen 	im1=0
		replace im1=1 if motbrncnt==0 & fatbrncnt==0 & stubrncnt==0 
		replace im1=. if missing(motbrncnt) & missing(fatbrncnt) | missing(stubrncnt)

		*second generation: born in country of test language, parent(s) born abrod
		gen 	im2=0
		replace im2=1 if motbrncnt==0 & fatbrncnt==0 & stubrncnt==1
		replace im2=. if missing(motbrncnt) & missing(fatbrncnt) | missing(stubrncnt)
		
		* countries of origin	
		rename cobn_m bcntry_m
		rename cobn_f bcntry_f
		rename cobn_s bcntry
		
		label define bcntry ///
			000400  "Afghanistan" ///
			000800  "Albania" ///
			001200  "Algeria" ///
			001600  "American Samoa" ///
			002000  "Andorra" ///
			002400  "Angola" ///
			002800  "Antigua and Barbuda" ///
			002900  "Caribbean" ///
			003100  "Azerbaijan" ///
			003200  "Argentina" ///
			003600  "Australia" ///
			004000  "Austria" ///
			004002	"Former Yugoslavia (Bosnia-Herzegovina, Croatia, Kosovo, Macedonia, Montenegro, Serbia, Slovenia)" ///
			004003	"another country inside of Europe (AUT)" ///
			004004	"another country outside of Europe (AUT)" ///
			004400  "Bahamas" ///
			004800  "Bahrain" ///
			005000  "Bangladesh" ///
			005100  "Armenia" ///
			005200  "Barbados" ///
			005600  "Belgium" ///
			005601  "Belgium (Flanders)" ///
			005602  "Belgium (French community)" ///
			005603  "Belgium (German community)" ///
			006000  "Bermuda" ///
			006400  "Bhutan" ///
			006800  "Bolivia (Plurinational State of)" ///
			007000  "Bosnia and Herzegovina" ///
			007200  "Botswana" ///
			007600  "Brazil" ///
			008400  "Belize" ///
			009200  "British Virgin Islands" ///
			009600  "Brunei Darussalam" ///
			010000  "Bulgaria" ///
			010400  "Myanmar" ///
			010800  "Burundi" ///
			011200  "Belarus" ///
			011600  "Cambodia" ///
			012000  "Cameroon" ///
			012400  "Canada" ///
			013200  "Cape Verde" ///
			013600  "Cayman Islands" ///
			014000  "Central African Republic" ///
			014400  "Sri Lanka" ///
			014800  "Chad" ///
			015200  "Chile" ///
			015600  "China" ///
			015601  "China (Shanghai)" ///
			015604  "China (Beijing)" ///
			015610  "China (incl. Hong Kong)" ///
			015800  "Chinese Taipei" ///
			015801	"Taiwan" ///
			017000  "Colombia" ///
			017400  "Comoros" ///
			017500  "Mayotte" ///
			017800  "Congo" ///
			018000  "Democratic Republic of the Congo" ///
			018400  "Cook Islands" ///
			018800  "Costa Rica" ///
			019100  "Croatia" ///
			019200  "Cuba" ///
			020300  "Czech Republic" ///
			020400  "Benin" ///
			020800  "Denmark" ///
			020801  "The Faroe Islands" ///
			020802  "Greenland" ///
			021200  "Dominica" ///
			021400  "Dominican Republic" ///
			021800  "Ecuador" ///
			022200  "El Salvador" ///
			022600  "Equatorial Guinea" ///
			023100  "Ethiopia" ///
			023200  "Eritrea" ///
			023300  "Estonia" ///
			023400  "Faeroe Islands" ///
			023800  "Falkland Islands (Malvinas)" ///
			024200  "Fiji" ///
			024600  "Finland" ///
			024800  "land Islands" ///
			025000  "France" ///
			025400  "French Guiana" ///
			025800  "French Polynesia" ///
			026200  "Djibouti" ///
			026600  "Gabon" ///
			026800  "Georgia" ///
			026801	"Other European Country (GEO)" ///
			027000  "Gambia" ///
			027500  "Occupied Palestinian Territory" ///
			027600  "Germany" ///
			028800  "Ghana" ///
			029200  "Gibraltar" ///
			029600  "Kiribati" ///
			030000  "Greece" ///
			030400  "Greenland" ///
			030800  "Grenada" ///
			031200  "Guadeloupe" ///
			031600  "Guam" ///
			032000  "Guatemala" ///
			032400  "Guinea" ///
			032800  "Guyana" ///
			033200  "Haiti" ///
			033600  "Holy See" ///
			034000  "Honduras" ///
			034400  "Hong Kong-China" ///
			034401  "Hong Kong" ///
			034800  "Hungary" ///
			035200  "Iceland" ///
			035600  "India" ///
			035610  "India (2009 States)" ///
			036000  "Indonesia" ///
			036400  "Iran, Islamic Republic of" ///
			036800  "Iraq" ///
			037200  "Ireland" ///
			037600  "Israel" ///
			038000  "Italy" ///
			038001  "Provincia Autonoma of Bolzano (ITA)" ///
			038002  "Provincia Basilicata (ITA)" ///
			038003  "Provincia Campania (ITA)" ///
			038004  "Provincia Emilia Romagna (ITA)" ///
			038005  "Provincia Friuli Venezia Giulia (ITA)" ///
			038006  "Provincia Liguria (ITA)" ///
			038007  "Provincia Lombardia (ITA)" ///
			038008  "Provincia Piemonte (ITA)" ///
			038009  "Provincia Puglia (ITA)" ///
			038010  "Provincia Sardegna (ITA)" ///
			038011  "Provincia Sicilia (ITA)" ///
			038012  "Provincia Trento (ITA)" ///
			038013  "Provincia Veneto (ITA)" ///
			038014  "The rest of Italy (ITA)" ///
			038100  "Kosovo" ///
			038400  "C™te d'Ivoire" ///
			038800  "Jamaica" ///
			039200  "Japan" ///
			039800  "Kazakhstan" ///
			039801	"In other CIS countries (except Kazakhstan) (KAZ)" ///
			040000  "Jordan" ///
			040400  "Kenya" ///
			040800  "Democratic People's Republic of Korea" ///
			041000  "Republic of Korea" ///
			041100	"Kosovo" ///
			041400  "Kuwait" ///
			041700  "Kyrgyzstan" ///
			041800  "Lao People's Democratic Republic" ///
			042200  "Lebanon" ///
			042600  "Lesotho" ///
			042800  "Latvia" ///
			043000  "Liberia" ///
			043400  "Libyan Arab Jamahiriya" ///
			043800  "Liechtenstein" ///
			044000  "Lithuania" ///
			044200  "Luxembourg" ///
			044600  "Macao-China" ///
			044601  "Macao" ///
			045000  "Madagascar" ///
			045400  "Malawi" ///
			045800  "Malaysia" ///
			046200  "Maldives" ///
			046600  "Mali" ///
			047000  "Malta" ///
			047400  "Martinique" ///
			047800  "Mauritania" ///
			048000  "Mauritius" ///
			048400  "Mexico" ///
			049200  "Monaco" ///
			049600  "Mongolia" ///
			049800  "Republic of Moldova" ///
			049900  "Montenegro" ///
			050000  "Montserrat" ///
			050400  "Morocco" ///
			050800  "Mozambique" ///
			051200  "Oman" ///
			051600  "Namibia" ///
			052000  "Nauru" ///
			052400  "Nepal" ///
			052800  "Netherlands" ///
			053000  "Netherlands Antilles" ///
			053300  "Aruba" ///
			054000  "New Caledonia" ///
			054800  "Vanuatu" ///
			055400  "New Zealand" ///
			055800  "Nicaragua" ///
			056200  "Niger" ///
			056600  "Nigeria" ///
			057000  "Niue" ///
			057400  "Norfolk Island" ///
			057800  "Norway" ///
			058000  "Northern Mariana Islands" ///
			058300  "Micronesia, Federated States of" ///
			058400  "Marshall Islands" ///
			058500  "Palau" ///
			058600  "Pakistan" ///
			059100  "Panama" ///
			059800  "Papua New Guinea" ///
			060000  "Paraguay" ///
			060400  "Peru" ///
			060800  "Philippines" ///
			061200  "Pitcairn" ///
			061600  "Poland" ///
			062000  "Portugal" ///
			062400  "Guinea-Bissau" ///
			062600  "Timor-Leste" ///
			063000  "Puerto Rico" ///
			063400  "Qatar" ///
			063800  "RŽunion" ///
			064200  "Romania" ///
			064300  "Russian Federation" ///
			064600  "Rwanda" ///
			065200  "Saint-BarthŽlemy" ///
			065400  "Saint Helena" ///
			065900  "Saint Kitts and Nevis" ///
			066000  "Anguilla" ///
			066200  "Saint Lucia" ///
			066300  "Saint-Martin (French part)" ///
			066600  "Saint Pierre and Miquelon" ///
			067000  "Saint Vincent and the Grenadines" ///
			067400  "San Marino" ///
			067800  "Sao Tome and Principe" ///
			068200  "Saudi Arabia" ///
			068201	"Kuwait" ///
			068600  "Senegal" ///
			068800  "Serbia" ///
			069000  "Seychelles" ///
			069400  "Sierra Leone" ///
			070200  "Singapore" ///
			070300  "Slovak Republic" ///
			070400  "Viet Nam" ///
			070401  "Chinese (VNM)" ///
			070500  "Slovenia" ///
			070600  "Somalia" ///
			071000  "South Africa" ///
			071600  "Zimbabwe" ///
			072400  "Spain" ///
			072401  "Andalusia (ESP)" ///
			072402  "Aragon (ESP)" ///
			072403  "Asturias (ESP)" ///
			072404  "Balearic Islands (ESP)" ///
			072405  "Canary Islands (ESP)" ///
			072406  "Cantabria (ESP)" ///
			072407  "Castile-La Mancha (ESP)" ///
			072408  "Castile and Leon (ESP)" ///
			072409  "Catalonia (ESP)" ///
			072410  "Extremadura (ESP)" ///
			072411  "Galicia (ESP)" ///
			072412  "La Rioja (ESP)" ///
			072413  "Madrid (ESP)" ///
			072414  "Murcia (ESP)" ///
			072415  "Navarre (ESP)" ///
			072416  "Basque Country (ESP)" ///
			072417  "Valencian Community (ESP)" ///
			072418  "Ceuta and Melilla (ESP)" ///
			072419  "The rest of Spain (ESP)" ///
			073200  "Western Sahara" ///
			073600  "Sudan" ///
			074000  "Suriname" ///
			074400  "Svalbard and Jan Mayen Islands" ///
			074800  "Swaziland" ///
			075200  "Sweden" ///
			075600  "Switzerland" ///
			075601  "Switzerland (German-speaking community)" ///
			075602  "Switzerland (French-speaking community)" ///
			075603  "Switzerland (Italian-speaking community)" ///
			075700	"Syria" ///
			076000  "Syrian Arab Republic" ///
			076200  "Tajikistan" ///
			076400  "Thailand" ///
			076800  "Togo" ///
			077200  "Tokelau" ///
			077600  "Tonga" ///
			078000  "Trinidad and Tobago" ///
			078400  "United Arab Emirates" ///
			078410  "United Arab Emirates (Dubai)" ///
			078411  "Another Arabic country (ARE)" ///
			078420  "United Arab Emirates (ex.Dubai)" ///
			078800  "Tunisia" ///
			079200  "Turkey" ///
			079500  "Turkmenistan" ///
			079600  "Turks and Caicos Islands" ///
			079800  "Tuvalu" ///
			080000  "Uganda" ///
			080400  "Ukraine" ///
			080700  "FYR Macedonia" ///
			081800  "Egypt" ///
			082600  "United Kingdom" ///
			082610  "United Kingdom (excl.Scotland)" ///
			082611  "United Kingdom (England)" ///
			082612  "United Kingdom (Northern Ireland)" ///
			082613  "United Kingdom (Wales)" ///
			082620  "United Kingdom (Scotland)" ///
			082621	"Other European Union country (QSC)" ///
			082640  "United Kingdom (Great Britain)" ///
			083000  "Channel Islands" ///
			083100  "Guernsey" ///
			083200  "Jersey" ///
			083300  "Isle of Man" ///
			083400  "United Republic of Tanzania" ///
			084000  "United States of America" ///
			085000  "United States Virgin Islands" ///
			085400  "Burkina Faso" ///
			085800  "Uruguay" ///
			086000  "Uzbekistan" ///
			086200  "Venezuela (Bolivarian Republic of)" ///
			087600  "Wallis and Futuna Islands" ///
			088200  "Samoa" ///
			088700  "Yemen" ///
			089400  "Zambia" ///
			009000  "Solomon Islands" ///
			100200  "Africa" ///
			100201  "African country with Portuguese as the official language" ///
			100202  "A Sub-Saharan country (Africa excl. Maghreb)" ///
			100204  "North African country (Maghreb)" ///
			100502	"Other Latin American Country (CHL)" ///
			100503	"Other European Union Country (LUX)" ///
			114500  "Middle Eastern country" ///
			115000  "A European country" ///
			115001  "Other Western European country (BEL)" ///
			115009  "Another country within the European Union (MLT)" ///
			115002  "Another country within the European Union (ITA)" ///
			115003  "Other European Union Country (LUX)" ///
			115004  "A country from European Union (PRT)" ///
			115005  "A European country that is not a member of the European Union" ///
			115007  "Other European country (NLD)" ///
			115008  "Other European country (QSC)" ///
			115010	"Other European country (DNK)" ///
			115011	"European Countries (VNM)" ///
			115100  "An Eastern European country" ///
			115106  "An Eastern European country outside the EU" ///
			116001	"Other non-European country (DNK)" ///
			181000  "One of the former USSR republics" ///
			181001  "In another former USSR republic (RUS)" ///
			181002  "In another former USSR republic (EST)" ///
			189000  "One of the former Yugoslav republics" ///
			189001  "One of the other former Yugoslav republics (HRV)" ///
			189002  "One of the other former Yugoslav republics (SRB)" ///
			189003  "Serbia and Montenegro" ///
			189100  "ASEAN Countries (VNM)" ///
			900800  "Another country (ALB)" ///
			903100  "Another country (AZE)" ///
			903200  "Another country (ARG)" ///
			903600  "Another country (AUS)" ///
			904000  "Another country (AUT)" ///
			905600  "Another country (BEL)" ///
			907600  "Another country (BRA)" ///
			910000  "Another country (BGR)" ///
			912400  "Another country (CAN)" ///
			915200  "Another country (CHL)" ///
			915601  "Another country (QCN )" ///
			915604  "Another country (QCH )" ///
			915800  "Another country (TAP)" ///
			917000  "Another country (COL)" ///
			919100  "Another country (HRV)" ///
			920300  "Another country (CZE)" ///
			920800  "Another country (DNK)" ///
			921400  "Another country (DOM)" ///
			923300  "Another country (EST)" ///
			924600  "Another country (FIN)" ///
			925000  "Another country (FRA)" ///
			927600  "Another country (DEU)" ///
			930000  "Another country (GRC)" ///
			934400  "Another country (HKG)" ///
			934800  "Another country (HUN)" ///
			935200  "Another country (ISL)" ///
			936000  "Another country (IDN)" ///
			937200  "Another country (IRL)" ///
			937600  "Another country (ISR)" ///
			938000  "Another country (ITA)" ///
			939200  "Another country (JPN)" ///
			939800  "Another country (KAZ)" ///
			940000  "Another country (JOR)" ///
			941000  "Another country (KOR)" ///
			941700  "Another country (KGZ)" ///
			942800  "Another country (LVA)" ///
			943800  "Another country (LIE)" ///
			944000  "Another country (LTU)" ///
			944200  "Another country (LUX)" ///
			944600  "Another country (MAC)" ///
			948400  "Another country (MEX)" ///
			949800  "Another country (MDA)" ///
			949900  "Another country (MNE)" ///
			952800  "Another country (NLD)" ///
			955400  "Another country (NZL)" ///
			957800  "Another country (NOR)" ///
			959100  "Another country (PAN )" ///
			960400  "Another country (PER)" ///
			961600  "Another country (POL)" ///
			962000  "Another country (PRT)" ///
			963400  "Another country (QAT)" ///
			964200  "Another country (ROU)" ///
			964300  "Another country (RUS)" ///
			968800  "Another country (SRB)" ///
			970200  "Another country (SGP)" ///
			970300  "Another country (SVK)" ///
			970500  "Another country (SVN)" ///
			972400  "Another country (ESP)" ///
			975200  "Another country (SWE)" ///
			975600  "Another country (CHE)" ///
			976400  "Another country (THA)" ///
			985800  "Another country (URY)" ///
			978000  "Another country (TTO)" ///
			978410  "Another country (QAR)" ///
			978800  "Another country (TUN)" ///
			979200  "Another country (TUR)" ///
			980700  "Another country (MKD)" ///
			982600  "Another country (GBR)" ///
			982610  "Another country (QUK)" ///
			982620  "Another country (QSC)" ///
			984000  "Another country (USA)" ///
			918800  "Another country (CRI)" ///
			926800  "Another country (GEO)" ///
			935610  "Another country (QIN)" ///
			945800  "Another country (MYS)" ///
			947000  "Another country (MLT)" ///
			948000  "Another country (MUS)" ///
			978420  "Another country (QRE)" ///
			015602  "Another province in mainland China (QCN)" ///
			015605  "Another province in mainland China (QCH)" ///
			015603  "Hong Kong, Macau, Taiwan" ///
			119001  "Another American country [URY]" ///
			178411  "Another Arabic country (QAR)" ///
			100501  "South, Latin  and Central America" ///
			078421  "Abu Dhabi (QRE)" ///
			078422  "Al Ain (QRE)" ///
			078423  "Western Region (QRE)" ///
			078424  "Sharjah (QRE)" ///
			078425  "Ajman (QRE)" ///
			078426  "Umm Al Quain (QRE)" ///
			078427  "Fujaurah (QRE)" ///
			078428  "Ras Al Khaimah (QRE)" ///
			086201  "Venezuela (Miranda)" ///
			986201  "Another country (QVE )" ///
			086220  "Venezuela (ex. Miranda)" ///
			181003  "In another former USSR republic (GEO)" ///
			099000  "ZedlandA" ///
			099100  "ZedlandB" ///
			099200  "ZedlandC" ///
			099300  "ZedlandD" ///
			099400  "ZedlandE" ///
			099500  "ZedlandF" ///
			099600  "ZedlandG" ///
			099700  "ZedlandH" ///
			099800  "ZedlandJ" ///
			099900  "ZedlandK" ///
			999000  "Another country (ZZA)" ///
			999100  "Another country (ZZB)" ///
			999200  "Another country (ZZC)" ///
			999300  "Another country (ZZD)" ///
			999400  "Another country (ZZE)" ///
			999500  "Another country (ZZF)" ///
			999600  "Another country (ZZG)" ///
			999700  "Another country (ZZH)" ///
			999800  "Another country (ZZJ)" ///
			999900  "Another country (ZZK)" ///
			978400  "Another Country (ARE)" ///
			919600  "Another Country (CYP)" ///
			970400  "Another Country (VNM)" ///
			181004  "In another former USSR republic (KAZ)" ///
			115006  "Other European country (ITA)" ///
			178401  "Another State of the Gulf Cooperation Council (ARE)" ///
			189004  "Serbia, Montenegro and Kosovo" ///
			089005  "Kosovo" /// 
			064301  "Perm (Russian Federation)" ///
			064302  "Another region of the Russian Federation" ///
			000000  "Not selected" ///
			777777  "N/A" ///
			888888  "Invalid" ///
			999997  "N/A" ///
			999998  "Invalid" ///
			999999  "Missing"

			*find: 907000, 909600, 911200, 938100, 942200, 950400, 960800, 968200, 980400
			*missing: 100502, 100503, 115011, 15801, 189100, 26801, 34401, 38100, 39801, 4002, 4003, 4004, 44601, 68201, 70401, 75700, 82621
			
	foreach v of varlist bcntry* {
		replace `v' ="" if `v'=="100200" /* Africa" */
		replace `v' ="" if `v'=="100201" /*  "African country with Portuguese as the official language" */
		replace `v' ="" if `v'=="100202" /*  "A Sub-Saharan country (Africa excl. Maghreb)" */
		replace `v' ="" if `v'=="100204" /*  "North African country (Maghreb)" */
		replace `v' ="" if `v'=="114500" /*  "Middle Eastern country" */
		replace `v' ="" if `v'=="115000" /*  "A European country" */
		replace `v' ="" if `v'=="115001" /*  "Other Western European country (BEL)" */
		replace `v' ="" if `v'=="115009" /*  "Another country within the European Union (MLT)" */
		replace `v' ="" if `v'=="115002" /*  "Another country within the European Union (ITA)" */
		replace `v' ="" if `v'=="115003" /*  "Other European Union Country (LUX)" */
		replace `v' ="" if `v'=="115004" /*  "A country from European Union (PRT)" */
		replace `v' ="" if `v'=="115005" /*  "A European country that is not a member of the European Union" */
		replace `v' ="" if `v'=="115007" /*  "Other European country (NLD)" */
		replace `v' ="" if `v'=="115008" /*  "Other European country (QSC)" */
		replace `v' ="" if `v'=="115100" /*  "An Eastern European country" */
		replace `v' ="" if `v'=="115106" /*  "An Eastern European country outside the EU" */
		replace `v' ="" if `v'=="181000" /*  "One of the former USSR republics" */
		replace `v' ="" if `v'=="181001" /*  "In another former USSR republic (RUS)" */
		replace `v' ="" if `v'=="181002" /*  "In another former USSR republic (EST)" */
		replace `v' ="" if `v'=="189000" /*  "One of the former Yugoslav republics" */
		replace `v' ="" if `v'=="189001" /*  "One of the other former Yugoslav republics (HRV)" */
		replace `v' ="" if `v'=="189002" /*  "One of the other former Yugoslav republics (SRB)" */
		replace `v' ="" if `v'=="119001" /*  "Another American country [URY]" */
		replace `v' ="" if `v'=="178411" /*  "Another Arabic country (QAR)" */
		replace `v' ="" if `v'=="100501" /*  "South, Latin  and Central America" */
		replace `v' ="" if `v'=="181003" /*  "In another former USSR republic (GEO)" */
		replace `v' ="" if `v'=="099000" /*  "ZedlandA" */
		replace `v' ="" if `v'=="099100" /*  "ZedlandB" */
		replace `v' ="" if `v'=="099200" /*  "ZedlandC" */
		replace `v' ="" if `v'=="099300" /*  "ZedlandD" */
		replace `v' ="" if `v'=="099400" /*  "ZedlandE" */
		replace `v' ="" if `v'=="099500" /*  "ZedlandF" */
		replace `v' ="" if `v'=="099600" /*  "ZedlandG" */
		replace `v' ="" if `v'=="099700" /*  "ZedlandH" */
		replace `v' ="" if `v'=="099800" /*  "ZedlandJ" */
		replace `v' ="" if `v'=="099900" /*  "ZedlandK" */		
		replace `v' ="" if `v'=="181004" /*  "In another former USSR republic (KAZ)" */
		replace `v' ="" if `v'=="115006" /*  "Other European country (ITA)" */
		replace `v' ="" if `v'=="178401" /*  "Another State of the Gulf Cooperation Council (ARE)" */
		replace `v' ="" if `v'=="000000" /*  "Not selected" */
	}

	foreach v of varlist bcntry* {
		destring `v', replace
		label values `v' bcntry
		replace `v' = . if `v' == 777777 | `v' == 888888 |`v' == 999999 |`v' == 999998 | `v' == 999997
		replace  `v'=. if `v'>900000
		sdecode `v', replace
	}

	
	**********************************
	* Age of arrival in test country *
	**********************************
		
		gen 	migage=.
		replace migage=st021q01ta if !missing(st021q01ta)
		recode 	migage (1=0) (2=1) (3=2) (4=3) (5=4) (6=5) (7=6) (8=7) (9=8) (10=9) (11=10) (12=11) (13=12) (14=13) (15=14) (16=15) (17=16)
		replace migage=. if migage>age & !missing(migage) //these are all migage 16 and age 15-16 but smaller than 16
		replace migage=. if stubrncnt==1 & !missing(migage) //moslty 0, 1,859>0
		
		
	***************************
	* Language spoken at home *
	***************************
			
		gen 	stulanguage=.
		replace stulanguage =1 if st022q01ta==1            /* testsprache */
		replace stulanguage =2 if st022q01ta==2           /* other language*/
			
		gen 	otherlang=0 if stulanguage!=.
		replace otherlang=1 if stulanguage==2


	*********************
	* Family Ressources *
	*********************
	
		*books at home*
			gen books=st013q01ta if !missing(st013q01ta)
			
			* condensed categories for the testing specification
			foreach num of numlist 1/4{
				gen dbook`num'=0 if !missing(books)
				}
			replace dbook1=1 if books==1 
			replace dbook2=1 if books==2| books==3
			replace dbook3=1 if books==4| books==5
			replace dbook4=1 if books==6
							
		* comp_home
			gen    comp_home=st011q04ta if !missing(st011q04ta)
			recode comp_home (2=0) 
							
********************************************************************************
************************* SCHOOL QUESTIONNAIRE *********************************
********************************************************************************

	**************************
	* location of the school *
	**************************
		gen schoolloc=sc001q01ta if !missing(sc001q01ta)
		tab schoolloc, gen(dloc)		

	**********************
	* number of students *
	**********************
		*boys
		gen 	numstudmale=sc002q01ta if !missing(sc002q01ta)
		*girls
		gen 	numstudfemale= sc002q02ta if !missing(sc002q02ta)
		*total
		gen 	numstudtotal=numstudfemale+numstudmale if !missing(numstudfemale) & !missing(numstudmale)
		
	**************
	* management *
	**************
		gen 	private=0 if  sc013q01ta==1
		replace private=1 if  sc013q01ta==2

	**************************************
	* share of school financing by [...] *
	**************************************

		gen schoolbudgetgov = sc016q01ta/100 if !missing(sc016q01ta)		//Government

	*************************************
	* Teachers: full time and part time *
	*************************************
	
		************************************
		*teacher: certification 
		************************************
				gen 	cert_teachers=proatce if !missing(proatce)
				label var cert_teachers "Share certified teachers"
				*requires combination of isced 5a BA / MA / 6 quali
				
	*******************************************
	* Availability of infrastructure/material *
	*******************************************
				
		* School instruction hindered by:
			* lack of educational materials		
			gen 	shormat=0 if sc017q05na==1 | sc017q05na==2  
			replace shormat=1 if sc017q05na==3 | sc017q05na==4
							
	************
	* autonomy *
	************
	
	*** NOT AVAILABLE IN 2018 ***
     
******************************************
*Generate variable indicating wave
******************************************
	gen wave=2018

	rename w_schgrnrabwt scweight
	
#delimit;
keep pv1read pv1scie pv*math
	 age female
	 whithigh whitlow bluehigh bluelow dhisced*
	 im1 im2 otherlang migage stubrncnt motbrncnt fatbrncnt bcntry*
	 dbook* comp_home
		 dloc* numstudtotal private schoolbudgetgov cert_teachers shormat
			oecd w_fstuwt w_fsturwt* wave cnt country schoolid studid
;
#delimit cr

forvalues i = 1(1) 80 {
	rename w_fsturwt`i' w_fstr`i'
}
	
destring _all, replace

compress
save "$path/Data/Working/stsch_2018_renamed.dta",replace
	erase "$path/Data/Working/stsch_2018.dta"

```

### `Replication/Do/1a_merge.do`
```stata
********************************************************************************
***************** Merge datasets for students and schools **********************
********************************************************************************

************
*** 2000 ***
************

	use "$path/Data/Orig/PISA/2000/intstud_math.dta", clear
		rename *, lower
		sort schoolid
		save "$path/Data/Working/intstud_math_sorted.dta", replace
		
	use "$path/Data/Orig/PISA/2000/intstud_read.dta", clear
		rename *, lower
		sort schoolid
		save "$path/Data/Working/intstud_read_sorted.dta", replace
		
	use "$path/Data/Orig/PISA/2000/intstud_scie.dta", clear
		rename *, lower
		sort schoolid
		save "$path/Data/Working/intstud_scie_sorted.dta", replace
		
	use "$path/Data/Orig/PISA/2000/intscho.dta", clear
		rename *, lower
		merge 1:n country schoolid using "$path/Data/Working/intstud_math_sorted.dta",keep(using match) nogen
		save "$path/Data/Working/stsch_math_2000.dta", replace

	use "$path/Data/Orig/PISA/2000/intscho.dta", clear
		merge 1:n country schoolid  using "$path/Data/Working/intstud_read_sorted.dta",keep(using match) nogen
		save "$path/Data/Working/stsch_read_2000.dta", replace
		
	use "$path/Data/Orig/PISA/2000/intscho.dta", clear	
		merge 1:n country schoolid using "$path/Data/Working/intstud_scie_sorted.dta",keep(using match) nogen
		save "$path/Data/Working/stsch_scie_2000.dta", replace

		
	use "$path/Data/Working/stsch_read_2000.dta", clear
		merge 1:1 country schoolid stidstd using "$path/Data/Working/stsch_scie_2000.dta", nogen
		merge 1:1 country schoolid stidstd using "$path/Data/Working/stsch_math_2000.dta", nogen
		
		destring country, replace
		destring schoolid, replace
		rename stidstd studid
		destring studid, replace
		
	save "$path/Data/Working/stsch_2000.dta", replace
	
	do "$path/Do/1a1_2000.do"
	
************
*** 2003 ***
************

	use "$path/Data/Orig/PISA/2003/int_stui_2003.dta", clear
		rename *, lower
		sort country schoolid
	
		merge n:1 country schoolid using "$path/Data/Orig/PISA/2003/int_schi_2003.dta", nogen
		
		destring country, replace
		destring schoolid, replace
		rename stidstd studid
		destring studid, replace
		
	save "$path/Data/Working/stsch_2003.dta", replace

	do "$path/Do/1a2_2003.do"
	
************
*** 2006 ***
************

	use "$path/Data/Orig/PISA/2006/int_stu06_dec07.dta", clear
		rename *, lower
		sort country schoolid
		
		merge m:1 country schoolid using "$path/Data/Orig/PISA/2006/INT_Sch06_Dec07.dta", nogen
		
		destring country, replace
		destring schoolid, replace
		rename stidstd studid
		destring studid, replace
		
	save "$path/Data/Working/stsch_2006.dta", replace

	do "$path/Do/1a3_2006.do"
		
************
*** 2009 ***
************

	use "$path/Data/Orig/PISA\2009\2009student_final", clear
		rename *, lower
		sort country schoolid
		
		merge m:1 cnt schoolid using "$path/Data/Orig/PISA/2009/2009school_final.dta", nogen
		
		destring country cnt, replace
		rename *, lower
		destring schoolid, replace
		rename stidstd studid	
		destring studid, replace
	
	save "$path/Data/Working/stsch_2009.dta" , replace

	do "$path/Do/1a4_2009.do"
			
************
*** 2012 ***
************

	use "$path/Data/Orig/PISA/2012/INT_SCQ12_DEC03.dta", clear

	merge 1:m CNT SCHOOLID using "$path/Data/Orig/PISA/2012/INT_STU12_DEC03.dta", keep(match) nogen
		
		rename *, lower
		gen country=substr(subnatio,1,3)
		destring country, replace
		destring schoolid, replace
		rename stidstd studid
		destring studid, replace
		
	save "$path/Data/Working/stsch_2012.dta", replace
	
	do "$path/Do/1a5_2012.do"
		
************
*** 2015 ***
************
	
	use "$path/Data/Orig/PISA\2015\CY6_MS_CMB_SCH_QQQ.dta", clear		

		merge 1:m cnt cntschid using "$path/Data/Orig/PISA\2015\CY6_MS_CMB_STU_QQQ.dta", keep(match) nogen
							
		rename cntryid country
		destring country, replace
		rename cntschid schoolid
		sort schoolid
		destring schoolid, replace
		rename cntstuid studid 
		destring studid, replace

	save "$path/Data/Working/stsch_2015.dta", replace
	
	do "$path/Do/1a6_2015.do"
	
************
*** 2018 ***
************
	
	use "$path/Data/Orig/PISA\2018\CY07_MSU_SCH_QQQ.DTA", clear

		merge 1:m cnt cntschid using "$path/Data/Orig/PISA\2018\CY07_MSU_STU_QQQ.DTA", keep(match) nogen
				
		rename cntryid country
		destring country, replace
		rename cntschid schoolid
		sort schoolid
		destring schoolid, replace
		rename cntstuid studid
		destring studid, replace

	save "$path/Data/Working/stsch_2018.dta", replace
	
	do "$path/Do/1a7_2018.do"

```

### `Replication/Do/1b_append.do`
```stata
*******************************
* APPEND DATASETS 2003 - 2018 *
*******************************

	use "$path/Data/Working/stsch_2000_renamed.dta", clear

		append using "$path/Data/Working/stsch_2003_renamed.dta", gen(w1)

		append using "$path/Data/Working/stsch_2006_renamed.dta", gen(w2)
			
		append using "$path/Data/Working/stsch_2009_renamed.dta", gen(w3)
			
		append using "$path/Data/Working/stsch_2012_renamed.dta", gen(w4) 
			
		append using "$path/Data/Working/stsch_2015_renamed.dta", gen(w5)
		
		append using "$path/Data/Working/stsch_2018_renamed.dta", gen(w6)

	gen dloc23=dloc2+dloc3
	gen dloc45=dloc4+dloc5
	
	gen dhisced345 = dhisced3+dhisced4+dhisced5
	
	replace im1=0 if stubrncnt==1 & missing(fatbrncnt) & missing(motbrncnt)
	replace im2=0 if stubrncnt==0 & missing(fatbrncnt) & missing(motbrncnt)
	
	gen 	im0=0 if !missing(im1) | !missing(im2)
	replace im0=1 if im1==0 & im2==0
	
	drop w1 w2 w3 w4 w5 w6
	
*******************************************		
* make countries of birth more comparable *
*******************************************
	
	gen bcntry_orig   = bcntry
	gen bcntry_f_orig = bcntry_f
	gen bcntry_m_orig = bcntry_m
	
	foreach var in bcntry bcntry_f bcntry_m {
	
		replace `var' = "United Arab Emirates" if inlist(`var',"Abu Dhabi (ARE ex Dubai)","Ajman (ARE ex Dubai)","Al Ain (ARE ex Dubai)","Fujaurah (ARE ex Dubai)")
		replace `var' = "United Arab Emirates" if inlist(`var',"Ras Al Khaimah (ARE ex Dubai)","Sharjah (ARE ex Dubai)","Umm Al Quain (ARE ex Dubai)","United Arab Emirates (Dubai)","United Arab Emirates (ex.Dubai)","Western Region (ARE ex Dubai)")
		
		replace `var' = "Spain" if inlist(`var',"Andalusia (ESP)","Andalusia (in Spain)","Aragon (ESP)","Aragon (in Spain)","Asturias (ESP)","Asturias (in Spain)","Balearic Islands (ESP)","Balearic Islands (in Spain)")
		replace `var' = "Spain" if inlist(`var',"Basque Country (ESP)","Basque Country (in Spain)","Canary Islands (ESP)","Canary Islands (in Spain)","Cantabria (ESP)","Cantabria (in Spain)","Castile and Leon (ESP)","Castile and Leon (in Spain)")
		replace `var' = "Spain" if inlist(`var',"Castile-La Mancha (ESP)","Castile-La Mancha (in Spain)","Catalonia (ESP)","Catalonia (in Spain)","Ceuta and Melilla (ESP)","Ceuta and Melilla (in Spain)","Extremadura (ESP)","Extremadura (in Spain)")
		replace `var' = "Spain" if inlist(`var',"Galicia (ESP)","Galicia (in Spain)","La Rioja (ESP)","La Rioja (in Spain)","Madrid (ESP)","Madrid (in Spain)","Murcia (ESP)","Murcia (in Spain)")
		replace `var' = "Spain" if inlist(`var',"Navarre (ESP)","Navarre (in Spain)","Valencian Community (ESP)","Valencian Community (in Spain)")
		
		replace `var' = "China" if inlist(`var',"Another province in mainland China (QCN)","China (Beijing)","China (Shanghai)","China (incl Hong Kong)","China (incl. Hong Kong)","China (incl. HongKong)","Chinese Taipei","Hong Kong","Hong Kong Macau Chinese Taipei")
		replace `var' = "China" if inlist(`var',"Hong Kong, Macau, Taiwan","Hong Kong-China","Macau","Macao-China","Mainland China")
		
		replace `var' = "Bolivia" if inlist(`var',"Bolivia (Plurinational State of)")

		replace `var' = "Bosnia Herzegovina" if inlist(`var',"Bosnia","Bosnia and Herzegovina","Bosnia-Herzegovina")

		replace `var' = "Cape Verde" if inlist(`var',"Cap Verde (in Western Africa)")
		
		replace `var' = "United Kingdom" if inlist(`var',"Bermuda","Cook Islands","England","England, Wales, N Ireland","Great Britain","Northern Ireland","Scotland")
		replace `var' = "United Kingdom" if inlist(`var',"United Kingdom (England)","United Kingdom (Great Britain)","United Kingdom (Northern Ireland)","United Kingdom (Scotland)","United Kingdom (excl.Scotland)")
		
		replace `var' = "Macedonia" if inlist(`var',"FYR Macedonia","Former Yugoslav Republic of Macedonia")
		
		replace `var' = "Denmark" if inlist(`var',"Greenland","The Faroe Islands")
		
		replace `var' = "Yugoslavia" if inlist(`var',"The former Yugoslavia","Ex-Yugoslavia","Former Yugoslavia (Bosnia-Herzegovina, Croatia, Kosovo, Macedonia, Montenegro, Serbia, Slovenia)")

		replace `var' = "India" if inlist(`var',"India (2009 States)")

		replace `var' = "Ireland" if inlist(`var',"Republic of Ireland")

		replace `var' = "Iran" if inlist(`var',"Iran, Islamic Republic of")
		
		replace `var' = "South Korea" if inlist(`var',"Republic of Korea","Korea")
		
		replace `var' = "Moldova" if inlist(`var',"Republic of Moldova")
		
		replace `var' = "Palestine" if inlist(`var',"Occupied Palestinian Territory")
		
		replace `var' = "Russia" if inlist(`var',"Russian Federation","Perm (Russian Federation)","Another region of the Russian Federation")
		
		replace `var' = "Netherlands" if inlist(`var',"Netherlands Antilles")
		
		replace `var' = "Serbia" if inlist(`var',"Serbia and Montenegro","Serbia, Montenegro and Kosovo","Serbia-Montenegro")
		
		replace `var' = "Slovak Republic" if inlist(`var',"Slovakia")
		
		replace `var' = "Slovenia" if inlist(`var',"Slowenia")
		
		replace `var' = "United States" if inlist(`var',"United States of America")

		replace `var' = "Venezuela" if inlist(`var',"Venezuela (Miranda)","Venezuela (Bolivarian Republic of)")
		
		replace `var' = "Vietnam" if inlist(`var',"Viet Nam")
		
		replace `var' = "" if inlist(`var',"Africa","Albania or Kosovo","Another Arabic country (ARE)","Caribbean","Other European country (DNK)","Other non-European country (DNK)","ASEAN Countries (VNM)","Chinese (VNM)","European Countries (VNM)")
		replace `var' = "" if inlist(`var',"In other CIS countries (except Kazakhstan) (KAZ)","Other European Country (GEO)","Other European Union Country (LUX)","Other European Union country (QSC)","Other Latin American Country (CHL)","another country inside of Europe (AUT)","another country outside of Europe (AUT)")
}
	
save "$path/Data/Working/pisa_full.dta", replace

	foreach num in 2000 2003 2006 2009 2012 2015 2018  {
		erase "$path/Data/Working/stsch_`num'_renamed.dta"
	}

```

### `Replication/Do/1c_weights_collapse.do`
```stata
use "$path/Data/Working\pisa_full", clear

*************************
* CREATE COUNTRY SAMPLE *
*************************

	set more off, perm
	
	* Albania (no student questionnaire in 2015)
		drop if cnt=="ALB" & wave==2015

	* Argentina (Ciudad Autonoma de Buenos Aires)
		drop if cnt=="QAR"

	* Azerbaijan (only Baku)
		drop if cnt=="QAZ"

	* China  	
		drop if cnt=="QCH" // B-S-J-G (China) = Beijing, Shanghai, Jiangsu, Guangdong (2015)
		drop if cnt=="QCI" // B-S-J-Z (China) = Beijing, Shanghai, Jiangsu, Zhejiang (2018)
		drop if cnt=="QCN" // Shanghai (China) (2009, 2012)
		*keep Hong Kong (HKG, all waves), Macao (MAC, all but 2000), and Chinese Taipeh (TAP, 2006-2018) as separate countries
		
	* India (Tamil Nadu, Himachal Pradesh) - only in 2009, not India overall, no countries of birth other than India
		drop if cnt=="QHP" | cnt=="QTN"

	* Republics of Montenegro and Serbia were a united jurisdiction in the PISA 2003 assessment	
		drop if cnt=="YUG"
			  		
	* Romania has different isocodes --> unify
		replace cnt="ROU" if cnt=="ROM"

	* Russia	
		drop if cnt=="QRS"
		drop if cnt=="QMR"
		drop if cnt=="QMC"
		drop if cnt=="QRT"
		
	* Spain (only specific region)
		drop if cnt=="QES"

	* Venezuela (only Miranda and only in 2009)
		drop if cnt=="QVE"
		
	* Vietnam (missing all three domains in 2018)
		drop if cnt=="VNM" & wave==2018
							 	
	******************
	* OECD Indicator *
	******************

	* OECD members: (source: https://www.oecd.org/about/document/list-oecd-member-countries.htm)
	* assign membership as "ever OECD"
		* 	CHILE (joined 7 May 2010)
			replace oecd=1 if cnt=="CHL"
		* 	COLOMBIA (https://www.oecd.org/latin-america/countries/colombia/)
			replace oecd=1 if cnt=="COL"
		*	ESTONIA	(joined 9 December 2010)
			replace oecd=1 if cnt=="EST"
		* 	ISRAEL	(joined 7 September 2010)
			replace oecd=1 if cnt=="ISR"
		*	LITHUANIA (joined 5 July 2018)							
			replace oecd=1 if cnt=="LTU"
		*   LATVIA (joined 1 July 2016) --> no GPS
			replace oecd=1 if cnt=="LVA"
		*	SLOVENIA (joined 21 July 2010) --> no GPS
			replace oecd=1 if cnt=="SVN"

	
	foreach var of varlist(pv1math pv1read pv1scie) {
		drop if missing(`var') & wave==2000
	}
	
	*ESP and USA are entirely missing reading in 2006/2018 --> keep, will be automatically excluded from the analysis later
	
	
*************
* WEIGHTING *
*************
		
	*Equal weight for each country-wave-observation
		bys country wave: egen total=total(w_fstuwt)
		gen wgt=w_fstuwt/total
		
	*Equal weight for each country over all waves (math/science)
		bys country: egen total2=total(wgt)
		gen wgtc=wgt/total2
		
	*Equal weight for each country over all waves (reading)
		bys country: egen total3=total(wgt) if !missing(pv1read)
		gen wgtcread=wgt/total3
		
	drop total*
	drop w_fstuwt
			
save "$path/Data/Working\pisa_full_weights", replace

*************************************************************
******		Generate country-wave-specific means		*****
*************************************************************

#delimit ;
collapse (mean)
	mmpv1math=pv1math mmpv1scie=pv1scie mmpv1read=pv1read
	mmage=age mmfemale=female
	mmwhithigh=whithigh mmwhitlow=whitlow mmbluehigh=bluehigh mmbluelow=bluelow
	mmdhisced1=dhisced1 mmdhisced2=dhisced2 mmdhisced3=dhisced3 mmdhisced4=dhisced4 mmdhisced5=dhisced5 mmdhisced6=dhisced6 mmdhisced345=dhisced345
    mmim0=im0 mmim1=im1 mmim2=im2 mmotherlang=otherlang
	mmstubrncnt=stubrncnt mmmotbrncnt=motbrncnt mmfatbrncnt=fatbrncnt mmmigage=migage
	mmdbook1=dbook1  mmdbook2=dbook2  mmdbook3=dbook3  mmdbook4=dbook4 mmcomp_home=comp_home
		mmdloc1=dloc1 mmdloc2=dloc2 mmdloc3=dloc3 mmdloc4=dloc4 mmdloc5=dloc5 mmdloc23=dloc23 mmdloc45=dloc45
		mmnumstudtotal=numstudtotal mmprivate=private mmschoolbudgetgov=schoolbudgetgov
		mmcert_teachers=cert_teachers mmshormat=shormat
		mmautcontent=autcontent mmautcourses=autcourses mmauttextbook=auttextbook
[pweight=wgt], by(cnt wave);
#delimit cr

save "$path/Data/Working\pisa_full_collapsed", replace
	erase "$path/Data/Working\pisa_full.dta"

```

## How to run a script

Write each script to a file under the output directory, then run it with
exactly this command (the data directory is mounted read-only at its own
path; nothing else from the host is visible; `$SCRIPT` is the absolute path of
the script you wrote):

    SCRIPT=<repo>/benchmark/reproductions/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a/script.R   # or <repo>/benchmark/reproductions/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a/attempt-<n>/script.R
    docker run --rm --label retally.run=claude-code-hanushek-2022-patience-risk-human-capital-seeded-2026-11-02-a --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital:<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R > "$(dirname "$SCRIPT")/stdout.txt" 2> "$(dirname "$SCRIPT")/stderr.txt"; echo "exit code: $?"

The sandbox time limit is 300 seconds (memory 4g, 1.0 CPU).  Wrap the
command in a timeout of that many seconds: prefix it with
`perl -e 'alarm shift; exec @ARGV' 300` (or `gtimeout 300` if installed;
macOS has no `timeout`).  If the timeout fires, stop the container with
`docker ps -q --filter label=retally.run=claude-code-hanushek-2022-patience-risk-human-capital-seeded-2026-11-02-a | xargs docker kill` and treat the
run as a crash (exit code 124).

## Output contract

The output directory `<repo>/benchmark/reproductions/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a/
  script.R  stdout.txt  stderr.txt      # the FINAL run: its RESULT: lines are what is scored
  attempt-1/  attempt-2/  ...           # every execution BEFORE the final one, in order
    script.R  stdout.txt  stderr.txt  feedback.txt   # feedback.txt when kind is not ""
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

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a`.
