# Retally reproduction task: corno-2022-interaction-stereotypes-performance (seeded, run 2026-11-10-a)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `corno-2022-interaction-stereotypes-performance`, mode `seeded`, run `2026-11-10-a`
- Paper: Interaction, Stereotypes, and Performance: Evidence from South Africa
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a/mount/corno_2022_interaction_stereotypes_performance`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a/mount/corno_2022_interaction_stereotypes_performance` as data, and `<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a/paper.txt` as
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

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Claims to Reproduce
1. race_iat_mixed_room_whites_table3_col1: 0.316 (change in the Race IAT D-score (higher = less prejudice against black people)) [type: coefficient]
   Location: Table 3, Race IAT, Whites, column (1), Mixed Room
   Context: Table 3 ("Stereotypes and exposure to a roommate of different race"), column (1). OLS of the follow-up (end of first year) Race IAT score on Mixed Room, a dummy for having been assigned at baseline a roommate of a different race, controlling for the respondent's baseline Race IAT score, own baseline controls (female, UCT admission score, household wealth index, monthly consumption, foreign, private high school), the same controls for the roommate except female (rooms are single-sex), and residence fixed effects; missing values of controls other than the baseline IAT are replaced by means with …
2. race_iat_mixed_room_blacks_table3_col2: -0.094 (change in the Race IAT D-score (higher = less prejudice against black people)) [type: coefficient]
   Location: Table 3, Race IAT, Blacks, column (2), Mixed Room
   Context: Table 3, column (2): the column (1) regression (follow-up Race IAT on Mixed Room, baseline Race IAT, own and roommate baseline controls, residence fixed effects) for black students. Standard errors clustered at the room level.
3. n_obs_table3_whites: 117.0 (students) [type: count]
   Location: Table 3, No. Obs., columns (1) and (3) (Whites)
   Context: Number of observations in Table 3 for the white subsample: white students in the working sample (interviewed at baseline and follow-up with non-missing values for both IATs).
4. n_obs_table3_blacks: 332.0 (students) [type: count]
   Location: Table 3, No. Obs., columns (2) and (4) (Blacks)
   Context: Number of observations in Table 3 for the black subsample: black students in the working sample.
5. gpa_mixed_room_blacks_table4_panelB_col1: 0.257 (standard deviations of first-year GPA) [type: coefficient]
   Location: Table 4, Panel B: Blacks, column (1) GPA, Mixed Room
   Context: Table 4 ("Impact on academic performance"), Panel B, column (1). OLS of the student's first-year average GPA (standardized to mean 0 and SD 1 over the full sample) on Mixed Room, own baseline controls (female, UCT admission score, wealth index, consumption, foreign, private high school, with mean imputation and missing-value dummies), the roommate's baseline controls (all but female), residence fixed effects and academic program fixed effects. Sample: black students in the working sample. Standard errors clustered at the room level. The entry is the Mixed Room coefficient.
6. exams_passed_mixed_room_blacks_table4_panelB_col2: 0.645 (number of exams passed in the first year) [type: coefficient]
   Location: Table 4, Panel B: Blacks, column (2) Number of exams passed, Mixed Room
   Context: Table 4, Panel B, column (2): the same specification with the number of exams passed during the first year as the outcome; black students. Standard errors clustered at the room level.
7. eligible_mixed_room_blacks_table4_panelB_col3: 0.152 (change in the probability of being eligible to continue) [type: coefficient]
   Location: Table 4, Panel B: Blacks, column (3) Eligible to continue, Mixed Room
   Context: Table 4, Panel B, column (3): the same specification with a dummy for being in good standing and eligible to continue to the next academic year (Faculty Examination Committee assessment, possibly subject to make-up exams) as the outcome; black students. Standard errors clustered at the room level.
8. performance_index_mixed_room_blacks_table4_panelB_col4: 0.443 (units of the academic performance index (first principal component)) [type: coefficient]
   Location: Table 4, Panel B: Blacks, column (4) Index of Academic Performance, Mixed Room
   Context: Table 4, Panel B, column (4): the same specification with the index of academic performance, the first principal component of GPA, number of exams passed and eligible to continue, as the outcome; black students. Standard errors clustered at the room level.
9. gpa_mixed_room_whites_table4_panelA_col1: -0.028 (standard deviations of first-year GPA) [type: coefficient]
   Location: Table 4, Panel A: Whites, column (1) GPA, Mixed Room
   Context: Table 4, Panel A, column (1): the Panel B column (1) specification (standardized first-year GPA on Mixed Room, own and roommate baseline controls, residence and academic program fixed effects) for white students. Standard errors clustered at the room level.
10. gpa_mixed_room_full_table4_panelC_col1: 0.147 (standard deviations of first-year GPA) [type: coefficient]
   Location: Table 4, Panel C: Full Sample, column (1) GPA, Mixed Room
   Context: Table 4, Panel C, column (1): standardized first-year GPA on Mixed Room in the full working sample (all races), with own and roommate baseline controls, race dummies (White, Coloured, Indian/Other; Black omitted), race group x residence fixed effects (race groups: Black, White, and a residual group) and academic program fixed effects. Standard errors clustered at the room level.
11. exams_passed_mixed_room_full_table4_panelC_col2: 0.447 (number of exams passed in the first year) [type: coefficient]
   Location: Table 4, Panel C: Full Sample, column (2) Number of exams passed, Mixed Room
   Context: Table 4, Panel C, column (2): the Panel C specification (race dummies, race group x residence and academic program fixed effects, own and roommate controls) with the number of exams passed in the first year as the outcome; full sample. Standard errors clustered at the room level.
12. performance_index_mixed_room_full_table4_panelC_col4: 0.289 (units of the academic performance index (first principal component)) [type: coefficient]
   Location: Table 4, Panel C: Full Sample, column (4) Index of Academic Performance, Mixed Room
   Context: Table 4, Panel C, column (4): the Panel C specification with the index of academic performance (first principal component of GPA, exams passed and eligible to continue) as the outcome; full sample with the index non-missing. Standard errors clustered at the room level.
13. n_obs_table4_panelC_cols1_2: 499.0 (students) [type: count]
   Location: Table 4, Panel C: Full Sample, No. Obs., columns (1)-(2)
   Context: Number of observations in Table 4 Panel C, columns (1) and (2): the full working sample of first-year students in double rooms interviewed at baseline and follow-up with both IAT scores.

## Dataset Information
Name: corno_2022_interaction_stereotypes_performance
Local path: <repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a/mount/corno_2022_interaction_stereotypes_performance
File format: csv
Files in the dataset directory (paths relative to the local path above):
- ForJournals_a/Data/Clean/uctdata_balanced.dta (552.4 KB) — 998 rows, 89 columns: continue, Female, Race, coloured, white, black, Foreign, foreign_missing, roFalseuct2012, Falseuct2012, roconsbas_nomiss, consbas_nomiss, roprivschool_nomiss, DscoreraceIATbas, DscoreacaIATbas, mixracebas, DscoreraceIAT, DscoreacaIAT, falseuct2012, examspassed, Same_ro_yr2, samefaculty, Res_base, rowhite, roblack, roElse, blackRes, whiteRes, Else, roommate_study, continue2013, examspassed2013, rocoloured, mixsamefaculty, nstudent, regprogram, roForeign_bas, roforeign_missingb…
- ForJournals_a/Data/Clean/uctdata_clean.dta (573.8 KB) — 1139 rows, 83 columns: Faculty, continue, Female, Race, coloured, white, black, Foreign, foreign_missing, roFalseuct2012, Falseuct2012, roconsbas_nomiss, consbas_nomiss, roprivschool_nomiss, roDscoreraceIAT, roDscoreacaIAT, mixracebas, DscoreraceIAT, whi_raceIAT, col_raceIAT, DscoreacaIAT, examspassed, else_raceIAT, Res_base, roFaculty, blackRes, whiteRes, Else, continue2013, examspassed2013, rocoloured, regprogram, roForeign_bas, roforeign_missingbas, privateschool_nomiss, privateschool_miss, roco…
- ForJournals_a/Data/Clean/nstudents_fwer.dta (336.6 KB) — 758 rows, 63 columns: Female, Race, Falseuct2012_fwer, consbas_nomiss_fwer, examspassed2013_fu_fwer, GPA2013_fu_fwer, DscoreraceIAT_fwer, DscoreraceIAT_fu_fwer, DscoreacaIAT_fwer, DscoreacaIAT_fu_fwer, continue_fu_fwer, foreign_missing_fwer, Res_base, blackRes_fwer, whiteRes_fwer, Faculty_fwer, coloured_fwer, white_fwer, black_fwer, Else_fwer, Foreign_fwer, examspassed_fu_fwer, continue2013_fu_fwer, nstudent_fwer, regprogram, privateschool_nomiss_fwer, privateschool_miss_fwer, roomnum_base, missfa…
- ForJournals_a/Data/Clean/uctdata_tabA2.dta (3.2 MB) — 31675 rows, 19 columns: Female, Race, Foreign, falseuct2012, foreign_comp, studentinsample, populationgroup, studentinres_double, all_students, studentinres, studentinourres, nstudent, round, gender, acadyear, english_home_comp, zulu_home_comp, xhosa_home_comp, af…
- ForJournals_a/Data/Clean/ronstudent_sim.dta (268.9 KB) — 3815 rows, 11 columns: roFalseuct2012_sim, roconsbas_nomiss_sim, roforeign_missing_sim, roForeign_sim, ronstudent, roprivateschool_nomiss_sim, roprivateschool_miss_sim, romissfalse_sim, roconsbas_miss_sim, rodurpcabas_nomiss_sim, rodurpcabas_miss_sim
- ForJournals_a/Data/Clean/tabA5.dta (92.4 KB) — 2292 rows, 9 columns: Race, female, sample, nstudent, round, odd, n_order, roomnum_base, buildings_name
- ForJournals_a/Data/Clean/uctdata_dyadic.dta (26.9 MB) — 370272 rows, 25 columns: sameresidence, nstudent, A_Foreign, S_Foreign, A_privateschool_nomiss, S_privateschool_nomiss, A_DscoreraceIAT, S_DscoreraceIAT, A_DscoreacaIAT, S_DscoreacaIAT, id_d, id, Res_base, sameroom, samesex, samerace, A_zFalseuct2012, S_zFalseuct20…
- ForJournals_a/Data/Clean/new_accommodation_2012.dta (117.2 KB) — 3787 rows, 2 columns: nstudent, buildings_name
- ForJournals_a/Code/0_main.do (1.9 KB)
- ForJournals_a/Code/additional/fdr_sharpened_qvalues.do (2.4 KB)
- ForJournals_a/Code/analysis/1_main_tables.do (20.4 KB)
- ForJournals_a/Code/analysis/2_appendix_tables.do (33.7 KB)
- ForJournals_a/Code/analysis/3_fwer_master.do (2.1 KB)
- ForJournals_a/Code/analysis/4_appendixA2.do (8.6 KB)
- ForJournals_a/Code/analysis/5_tableA5_control.do (4.0 KB)
- ForJournals_a/Code/analysis/6_tableA5_nocontrol.do (2.9 KB)
- ForJournals_a/Code/analysis/FWER/10_fwer_tablea15.do (33.3 KB)
- ForJournals_a/Code/analysis/FWER/2_fwer_table3.do (33.1 KB)
- ForJournals_a/Code/analysis/FWER/3_fwer_table4.do (33.3 KB)
- ForJournals_a/Code/analysis/FWER/4_fwer_table5.do (33.2 KB)
- ForJournals_a/Code/analysis/FWER/5_fwer_tablea7.do (32.8 KB)
- ForJournals_a/Code/analysis/FWER/6_fwer_tablea9.do (33.0 KB)
- ForJournals_a/Code/analysis/FWER/7_fwer_tablea12.do (35.5 KB)
- ForJournals_a/Code/analysis/FWER/8_fwer_tablea13.do (36.3 KB)
- ForJournals_a/Code/analysis/FWER/9_fwer_tablea14.do (34.8 KB)
- ForJournals_a/Questionnaires/Questionnaire_R1_final.pdf (262.9 KB)
- ForJournals_a/Questionnaires/Questionnaire_R2_final.pdf (263.8 KB)
- ForJournals_a/README_a.pdf (235.6 KB)
- ForJournals_a/programs/ado/dyreg.ado (10.5 KB)
- ForJournals_a/programs/ado/ngreg.ado (6.1 KB)
- ForJournals_a/programs/ado/ngreg.hlp (1.3 KB)
- ForJournals_a/programs/ado/qap.ado (29.0 KB)
- metadata.json (241 B)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a/mount/corno_2022_interaction_stereotypes_performance' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
Installed packages (no network; nothing else can be installed): jsonlite, fixest, lfe, AER, ivreg, plm, estimatr, lme4, quantreg, car, sandwich, lmtest, clubSandwich, multiwayvcov, marginaleffects, MatchIt, optmatch, CBPS, WeightIt, cobalt, did, rdrobust, rddensity, Synth, modelsummary, stargazer, texreg, broom, tidyverse, dplyr, tidyr, readr, stringr, lubridate, data.table, haven, readxl, janitor, zoo, ggplot2, ggridges, ggrepel, gridExtra, cowplot, gtable, extrafont, sf, MASS, nnet, survival, splines, Matrix, boot, stats, utils.
Prefer fixest for fixed effects, IV and clustered SEs; use the other installed packages where the paper's method calls for them.
Set a deterministic seed with ``set.seed(42)`` for any randomness.
Do NOT access the internet; the container runs with --network none.
Do NOT shell out via system() / system2().
Emit RESULT:<name>=<value> lines to stdout at the end via cat().

## Original Replication Scripts
The replication package (the dataset directory) ships the authors' own analysis scripts, reproduced below.  These are the GROUND TRUTH for the exact estimating equation, variable names, sample restrictions, fixed effects, and standard-error clustering — follow them over anything reconstructed from the methodology summary, and prefer them over the paper's text where the two disagree.  Your job is to write R code that implements the SAME SPECIFICATION: translate what the scripts estimate, do not transliterate their syntax line by line (a Stata .do file's regression, e.g. `reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the equivalent fixest::feols() call in R).  Keep only the parts that produce the specific claims being reproduced; skip figure construction and unrelated robustness checks.  The scripts' data-file paths refer to the package's internal layout — resolve them against the dataset directory listed under Dataset Information.

Stata-to-fixest sample matching: feols() drops fixed-effect singletons by default, but Stata's `reg y x i.fe` / `xi:` dummies keep them.  Pass `fixef.rm = "none"` to every feols() call that has fixed effects, otherwise the observation count and the robust SEs drift from the paper's.  Stata's `, r` / `vce(robust)` is `vcov = "hetero"`.

### `ForJournals_a/Code/0_main.do`
```stata
/************************************************************************************************************************************************

Project: Interaction, Sterotypes and Performance: Evidence from South Africa
Corno L., La Ferrara E., Burns J.

Do file: 0_main.do


Last updated on: July 2022
*************************************************************************************************************************************************/


	cap log close
	set more off
	set varabbrev on
	clear all
	pause off
	set maxvar 32767 
	
	
	***Install packages
	
	*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	**Install user-written commands 
	
	foreach package in veracrypt polychoric diff nrow outreg outreg2 dyads estout xml_tab charlist unique  {
		 capture which `package'
		 if _rc==111 ssc install `package'
	}
	
	** Ado files can be found in programs
	*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	
	***specify directory
	cd "~/Dropbox/SouthAfrica_replication_rr/ForJournals/ForJournals_Final/ForJournals_a"

		global clean "Data/Clean"
		global main_tables "Output/Main"
		global appendix_tables "Output/Appendix"
		global fwer_tables "Output/FWER"
		global figures "Output/Figures"
		global fwer "Code/analysis/FWER"
		global dofiles "Code"
		global additional "Code/additional"

	*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	*			ANALYSIS
	*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		
	** Main tables
	
		do "$dofiles/analysis/1_main_tables.do"

	** Appendix tables
	
		do "$dofiles/analysis/2_appendix_tables.do"
	
	** Additional Appendix tables
	* Table A2
		do "$dofiles/analysis/4_appendixA2.do"
		
	* Table A5
		do "$dofiles/analysis/5_tableA5_control.do"
		do "$dofiles/analysis/6_tableA5_nocontrol.do"
	
	** FWER p-values
	
		do "$dofiles/analysis/3_fwer_master.do"
	
	
	exit	
	
		
		
		


```

### `ForJournals_a/Code/analysis/1_main_tables.do`
```stata
/************************************************************************************************************************************************

Project: Interaction, Sterotypes and Performance: Evidence from South Africa
Corno L., La Ferrara E., Burns J.

do file: 1_main_tables.do


Last updated on: July 2022
Output: Main tables and figures
*************************************************************************************************************************************************/


clear all

*To save tables in excel
local c_date=c(current_date)
local date_string = subinstr("`c_date'", " ", "_", .)
local namexls "$main_tables/Tables`date_string'.xls"
local appendixxls "$appendix_tables/AppendixTables`date_string'.xls"

local namecsv Tables`date_string'
local namepng Graphs`date_string'

****  LOCALS OF CONTROLS  ****

*FULL SAMPLE
local controls white coloured Else Female Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss     
*BLACK and WHITE subsamples
local controls_subsample Female Falseuct2012 missfalse Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss      
*NON WHITE subsample
local controls_nonwhite coloured Else Female Falseuct2012 missfalse  Foreign foreign_missing privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss  consbas_nomiss consbas_miss      
*Roommate controls
local rocontrols roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas  roprivschool_nomiss roprivschool_miss  rodurpcabas_nomiss rodurpcabas_miss  roconsbas_nomiss roconsbas_miss  

*** Controls without Female
*FULL SAMPLE
local controls_nfem white coloured Else  Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss     
*BLACK and WHITE subsamples
local controls_subsample_nfem Falseuct2012 missfalse Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss      
*NON WHITE subsample
local controls_nonwhite_nfem coloured Else Falseuct2012 missfalse  Foreign foreign_missing privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss  consbas_nomiss consbas_miss      
*Roommate controls
local rocontrols roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas  roprivschool_nomiss roprivschool_miss  rodurpcabas_nomiss rodurpcabas_miss  roconsbas_nomiss roconsbas_miss  


********************************************
******     FIGURES     *********************
********************************************

use "$clean/uctdata_balanced.dta", clear



**************************
*    DENSITY GRAPHS      *
**************************
	
	set scheme s1color


***  Fig. 1: Popul & Academic IAT
**STEREOTYPES AS MEASURED BY IAT AT BASELINE

	twoway kdensity DscoreraceIAT if (round==1&white==1), lcolor(navy) ||  kdensity DscoreraceIAT if (round==1&black==1), lpattern(dash) lcolor(cranberry) /*
	*/xtitle(Race IAT) ytitle("") legend(ring(0) pos(6)  label(1 "Whites") label(2 "Blacks") label(3 "Blacks"))
	graph export "$figures/Fig1A_raceIAT_base.png", replace

	twoway kdensity DscoreacaIAT if (round==1&white==1), lcolor(navy) ||  kdensity DscoreacaIAT if (round==1&black==1), lpattern(dash) lcolor(cranberry) /* 
	*/xtitle(Academic IAT) ytitle("") legend(ring(0) pos(2) label(1 "Whites") label(2 "Blacks") label(3 "Blacks"))
	graph export "$figures/Fig1B_acaIAT_base.png", replace

	
************************************
******     TABLES     **************
************************************

************************************
*  TABLE 1 - DESCRIPTIVE STATISTICS* 
************************************


use "$clean/uctdata_balanced.dta", clear

local balance_vars "DscoreraceIAT DscoreacaIAT Falseuct2012 durpcabas_nomiss consbas_nomiss  Foreign privateschool_nomiss"

*Full sample
estpost sum `balance_vars' if round==1 & mixracebas!=. 
eststo t1_sumtot
estpost sum `balance_vars' if round==1 & mixracebas==1
eststo t1_summix
estpost sum `balance_vars' if round==1 & mixracebas==0
eststo t1_sumsam
local vars_n=wordcount("`balance_vars'")
mat fe_beta=J(1,`vars_n',.)
mat fe_p_val=J(1,`vars_n',.)
local i=1
foreach var of varlist DscoreraceIAT DscoreacaIAT Falseuct2012 durpcabas_nomiss consbas_nomiss  Foreign privateschool_nomiss{
	reg `var' mixracebas i.Res_base#i.Race if round==1 
	mat fe_beta[1,`i']=_b[mixracebas]
	mat fe_p_val[1,`i']=r(table)[4,1]
	local ++i
}
eststo t1_ttest
mat colnames fe_beta = `balance_vars'
estadd mat fe_beta: t1_ttest
mat colnames fe_p_val = `balance_vars'
estadd mat fe_p_val: t1_ttest

*For whites
estpost sum `balance_vars' if round==1 & white==1 & mixracebas!=. 
eststo t1_sumtotw
estpost sum `balance_vars' if round==1 & white==1 & mixracebas==1
eststo t1_summixw
estpost sum `balance_vars' if round==1 & white==1 & mixracebas==0
eststo t1_sumsamw
local vars_n=wordcount("`balance_vars'")
mat fe_beta=J(1,`vars_n',.)
mat fe_p_val=J(1,`vars_n',.)
local i=1
foreach var of varlist DscoreraceIAT DscoreacaIAT Falseuct2012 durpcabas_nomiss consbas_nomiss  Foreign privateschool_nomiss{
	reg `var' mixracebas i.Res_base  if round==1 & white==1
	mat fe_beta[1,`i']=_b[mixracebas]
	mat fe_p_val[1,`i']=r(table)[4,1]
	local ++i
}
eststo t1_ttestw
mat colnames fe_beta = `balance_vars'
estadd mat fe_beta: t1_ttestw
mat colnames fe_p_val = `balance_vars'
estadd mat fe_p_val: t1_ttestw


*For blacks
estpost sum `balance_vars' if round==1 & black==1 & mixracebas!=. 
eststo t1_sumtotb
estpost sum `balance_vars' if round==1 & black==1 & mixracebas==1
eststo t1_summixb
estpost sum `balance_vars' if round==1 & black==1 & mixracebas==0
eststo t1_sumsamb
local vars_n=wordcount("`balance_vars'")
mat fe_beta=J(1,`vars_n',.)
mat fe_p_val=J(1,`vars_n',.)
local i=1
foreach var of varlist DscoreraceIAT DscoreacaIAT Falseuct2012 durpcabas_nomiss consbas_nomiss  Foreign privateschool_nomiss{
	reg `var' mixracebas i.Res_base  if round==1 & black==1
	mat fe_beta[1,`i']=_b[mixracebas]
	mat fe_p_val[1,`i']=r(table)[4,1]
	local ++i
}
eststo t1_ttestb
mat colnames fe_beta = `balance_vars'
estadd mat fe_beta: t1_ttestb
mat colnames fe_p_val = `balance_vars'
estadd mat fe_p_val: t1_ttestb


xml_tab t1_sumtot(count count)  t1_sumtot(mean sd)  t1_summix(mean sd) t1_sumsam(mean sd) t1_ttest(fe_beta fe_p_val,nostar), stars(0) stats(N) save(`namexls') replace /*
*/ ceq("Full sample" "Full sample" "Full sample" "Full sample" "Mixed rooms" "Mixed rooms" "Not mixed rooms"  "Not mixed rooms" "Beta" "Beta=0") /*
*/ showeq sh(Tab1_sustats)  title("Table 1: Summary statistics at baseline and difference in means between treatment and control")/*
*/ cnames("Obs. Number" "Min" "Mean" "Std. Dev" "Mean" "Std. Dev" "Mean" "Std. Dev" "Diff" "P-value")  drop(o*) /*
*/ note("Note: Mean outcomes. The P-values test the null hypothesis that the means are equal. *** 1%, **5%, *10% significance.",/*
*/"Higher values of IAT score indicate less prejudice against blacks.",/*
*/ "UCT entry score: sum of high school final grades, with weights depending on the specific departement the student enrolls in.") 



xml_tab t1_sumtotw(count count) t1_sumtotw(mean sd)  t1_summixw(mean sd) t1_sumsamw(mean sd) t1_ttestw(fe_beta fe_p_val,nostar), stars(0) stats(N) save(`namexls') append ceq("Full sample" "Full sample" "Full sample" "Full sample" "Mixed rooms" "Mixed rooms" "Not mixed rooms"  "Not mixed rooms" "Beta" "Beta=0") showeq sh(T1_whites)  title("Table 1B: Summary statistics at baseline and difference in means for whites") cnames("Obs. Number" "Min" "Mean" "Std. Dev" "Mean" "Std. Dev" "Mean" "Std. Dev" "Diff" "P-value") drop(o*)

xml_tab t1_sumtotb(count count) t1_sumtotb(mean sd) t1_summixb(mean sd) t1_sumsamb(mean sd) t1_ttestb(fe_beta fe_p_val,nostar), stars(0) stats(N) save(`namexls') append ceq("Full sample" "Full sample" "Full sample" "Full sample" "Mixed rooms" "Mixed rooms" "Not mixed rooms"  "Not mixed rooms" "Beta" "Beta=0") showeq sh(T1_blacks)  title("Table 1C: Summary statistics at baseline and difference in means for black")  cnames("Obs. Number" "Min" "Mean" "Std. Dev" "Mean" "Std. Dev" "Mean" "Std. Dev" "Diff" "P-value") drop(o*)




**************************************************************
*  TABLE 2: PROBABILITY OF BEING IN A MIXED ROOM AT BASELINE *
**************************************************************
eststo clear

*PANEL A 
foreach i in mixracebas  {
	reg `i'    DscoreraceIAT DscoreacaIAT  `controls_nfem' i.blackRes i.whiteRes i.Res_base if round==1 ,  robust cluster(roomnum_base)
		eststo  bal_1
		sum `i'  if mixracebas==0 & e(sample)==1  
		estadd scalar meanofdepvar=r(mean)
		
	reg `i'    DscoreraceIAT DscoreacaIAT  `controls_nfem'  `rocontrols' i.blackRes i.whiteRes i.Res_base if round==1 ,  robust cluster(roomnum_base)
		eststo  bal_2
			sum `i'  if mixracebas==0 & e(sample)==1  
		estadd scalar meanofdepvar=r(mean)
		
	xi: reg `i'   DscoreraceIAT DscoreacaIAT `controls_subsample_nfem' i.Res_base if round==1 & white==1,  robust cluster(roomnum_base)
		eststo  bal_3
		sum `i'  if mixracebas==0 & e(sample)==1&white==1  
		estadd scalar meanofdepvar=r(mean)
		
	xi: reg `i'   DscoreraceIAT DscoreacaIAT `controls_subsample_nfem'  `rocontrols'  i.Res_base if round==1 & white==1,  robust cluster(roomnum_base)
		eststo  bal_4
		sum `i'  if mixracebas==0 & e(sample)==1&white==1  
		estadd scalar meanofdepvar=r(mean)
		
	xi: reg `i'   DscoreraceIAT DscoreacaIAT  `controls_subsample_nfem' i.Res_base if round==1 & black==1,  robust cluster(roomnum_base)
		eststo  bal_5
		sum `i'  if mixracebas==0 & e(sample)==1&black==1  
		estadd scalar meanofdepvar=r(mean)
	xi: reg `i'   DscoreraceIAT DscoreacaIAT  `controls_subsample_nfem' `rocontrols'   i.Res_base if round==1 & black==1,  robust cluster(roomnum_base)
		eststo  bal_6
		sum `i'  if mixracebas==0 & e(sample)==1&black==1  
		estadd scalar meanofdepvar=r(mean)
	}

xml_tab   bal_* , save(`namexls') sh(Tab2a_BalanceReg) showeq stats(meanofdepvar r2 N) append note("Notes: Robust standard errors in parentheses.", "(a) In our sample all Coloureds are in mixed race rooms") title("Table 2: Balance Reg") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*) stars()
eststo clear



**PANEL B
foreach i in mixracebas  {

	xi: reg `i'   PCAattitude   `controls_nfem' i.blackRes i.whiteRes i.Res_base  if round==1,  robust cluster(roomnum_base)
		eststo  bal_1
		sum `i'  if mixracebas==0 & e(sample)==1  
		estadd scalar meanofdepvar=r(mean)
	xi: reg `i'   PCAattitude   `controls_nfem' `rocontrols'   i.blackRes i.whiteRes i.Res_base  if round==1,  robust cluster(roomnum_base)
		eststo  bal_2
		sum `i'  if mixracebas==0 & e(sample)==1  
		estadd scalar meanofdepvar=r(mean)
	
	xi: reg `i'    PCAattitude `controls_subsample_nfem'  i.Res_base  if round==1 & white==1,  robust cluster(roomnum_base)
		eststo  bal_3
		sum `i'  if mixracebas==0 & e(sample)==1  &white==1  
		estadd scalar meanofdepvar=r(mean)
	xi: reg `i'    PCAattitude `controls_subsample_nfem'  `rocontrols'  i.Res_base  if round==1 & white==1,  robust cluster(roomnum_base)
		eststo  bal_4
		sum `i'  if mixracebas==0 & e(sample)==1  &white==1  
		estadd scalar meanofdepvar=r(mean)
	
	xi: reg `i'  PCAattitude    `controls_subsample_nfem' i.Res_base  if round==1 & black==1,  robust cluster(roomnum_base)
		sum `i'  if mixracebas==0 & e(sample)==1  &black==1  
		estadd scalar meanofdepvar=r(mean)
		eststo  bal_5
		xi: reg `i'  PCAattitude    `controls_subsample_nfem' `rocontrols'   i.Res_base  if round==1 & black==1,  robust cluster(roomnum_base)
		eststo  bal_6
		sum `i'  if mixracebas==0 & e(sample)==1  &black==1  
		estadd scalar meanofdepvar=r(mean)

		
		}
		
		
xml_tab   bal_* , save(`namexls') sh(Tab2b_BalanceReg) showeq stats(meanofdepvar r2 N) append  note("Notes: Robust standard errors in parentheses.", "(a) In our sample all Coloureds are in mixed race rooms") title("Table 2: Balance Reg") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*) stars()
eststo clear

**PANEL C - Creation of a Dyadic dataset - Very long to run (about 2 hours)


preserve
	use  "$clean/uctdata_dyadic.dta", clear
	
	
	keep if samesex == 1 & sameresidence == 1

	tab Res_base, g(Res_base_dum_)
	rename A_privateschool_nomiss A_pschool_nomiss
	rename S_privateschool_nomiss S_pschool_nomiss

	dyreg sameroom  A_DscoreraceIAT A_DscoreacaIAT A_PCAattitude A_zFalseuct2012 A_pschool_nomiss A_durpcabas_nomiss A_consbas_nomiss  S_DscoreraceIAT S_DscoreacaIAT S_PCAattitude  S_zFalseuct2012  S_pschool_nomiss S_durpcabas_nomiss S_consbas_nomiss A_Foreign S_Foreign Res_base_dum_* if samerace!=. & S_balanced!=0, id(id id_d) inc group(Res_base)
	local depvar=e(depvar)
	qui summ `depvar' if e(sample)	
	eststo  bal_2

xml_tab   bal_2 , save(`namexls') sh(Tab2C_Dyadic_balanced) showeq stats(meanofdepvar r2 N_clust N) append  note("Notes: Robust standard errors in parentheses.", "(a) In our sample all Coloureds are in mixed race rooms")  title("Table 2C: Dyadic Balance Reg (with residence controls) with only at least one in balanced sample") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*)


eststo clear
restore



***********************************************************************
*  TABLE 3: **STEREOTYPES AND EXPOSURE TO A ROOMMATE OF DIFFERENT RACE*
***********************************************************************

eststo clear


xtset individual round
sort individual round

foreach i in DscoreraceIAT {

	*White
	xi: reg `i' mixracebas L.`i' `controls_subsample' `rocontrols' i.Res_base  if round==2&white==1,  robust   cluster(roomnum_base)  
		eststo  iat_1wc
	sum DscoreraceIAT if mixracebas==0 & e(sample)==1 & white==1
	estadd scalar meanofdepvar=r(mean)

	*Black
	xi: reg `i' mixracebas L.`i' `controls_subsample' `rocontrols' i.Res_base  if round==2&black==1,  robust  cluster(roomnum_base)  
		eststo  iat_1bc
	sum DscoreraceIAT if mixracebas==0 & e(sample)==1 & black==1	
	estadd scalar meanofdepvar=r(mean)
	}
		
		
foreach i in DscoreacaIAT {

	*White
	xi: reg `i' mixracebas L.`i' `controls_subsample' `rocontrols' i.Res_base if round==2&white==1,  robust cluster(roomnum_base)  
		eststo  iat_2wc
	sum DscoreacaIAT if mixracebas==0 & e(sample)==1 & white==1
	estadd scalar meanofdepvar=r(mean)

	*Black
	xi: reg `i' mixracebas L.`i' `controls_subsample' `rocontrols' i.Res_base if round==2&black==1,  robust cluster(roomnum_base)  
		eststo  iat_2bc
	sum DscoreacaIAT if mixracebas==0 & e(sample)==1 & black==1
	estadd scalar meanofdepvar=r(mean)
	}


xml_tab   iat_* , save(`namexls') sh(Tab3_IAT) showeq stats(meanofdepvar r2 N) append  note("Notes: Robust standard errors in parentheses. All regressions include Res_base FE and the controls listed in column 2 of Table 4.", "(a) In our sample all Coloureds are in mixed race rooms")  title("Table 3: IAT") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*) stars()
eststo clear

*********************************************
**TABLE 4   - IMPACT ON ACADEMIC PERFORMANCE*
********************************************

eststo clear

foreach i in GPA examspassed continue PCAperf {
	

	*White
	xi: reg `i'  mixracebas `controls_subsample' `rocontrols' i.Res_base i.regprogram if round==2&white==1,  robust cluster(roomnum_base)  
		eststo  perf_`i'_4w
	sum `i' if mixracebas==0 & e(sample)==1 & white==1 
	estadd scalar meanofdepvar=r(mean)

	*Black
	xi: reg `i'  mixracebas `controls_subsample' `rocontrols' i.Res_base   i.regprogram  if round==2&black==1,  robust cluster(roomnum_base)  
		eststo  perf_`i'_6b
	sum `i' if mixracebas==0 & e(sample)==1  & black==1
		estadd scalar meanofdepvar=r(mean)
		
	*Full
	xi: reg `i'  mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base   i.regprogram  if round==2,  robust cluster(roomnum_base)  
		eststo  perf_`i'_8f
	sum `i' if mixracebas==0 & e(sample)==1 
		estadd scalar meanofdepvar=r(mean)
	
}

xml_tab   perf_* , save(`namexls') sh(Tab4_perform) showeq  append stats(meanofdepvar r2 N) note("Notes: Robust standard errors in parentheses") title("Table: GPA") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*) stars()
eststo clear



************************************************************************************************
*****  TABLE 5   **IMPACT ON FRIENDSHIPS, ATTITUDINAL MEASURES AND PRO-SOCIAL BEHAVIOUR  *******
************************************************************************************************

eststo clear


foreach i in  PCAfriend PCAattitude PCAcomm  PCAsocial {

	
	*White
	xi: reg `i'  mixracebas `controls_subsample' `rocontrols' i.Res_base if round==2&white==1,  robust cluster(roomnum_base)
		eststo  soc_`i'_2w
	sum `i'  if mixracebas==0 & e(sample)==1 & white==1
	estadd scalar meanofdepvar=r(mean)
	
	*Blacks
	xi: reg `i'  mixracebas `controls_subsample' `rocontrols' i.Res_base if round==2&black==1, robust cluster(roomnum_base)
		eststo  soc_`i'_4b
	sum `i'  if mixracebas==0 & e(sample)==1 & black==1
	estadd scalar meanofdepvar=r(mean)
	
	*Full
	xi: reg `i'  mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base if round==2, robust cluster(roomnum_base)
		eststo  soc_`i'_6f
	sum `i'  if mixracebas==0 & e(sample)==1 
	estadd scalar meanofdepvar=r(mean)
}

xml_tab   soc_* , save(`namexls') sh(Tab5_attitudes) showeq  append stats(meanofdepvar r2 N_clust N) note("Notes: Standard errors in parentheses") title("Table: Friendships, attitudes, pro-social behavior") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*) stars()
eststo clear



****************************************************************
*  TABLE 6 **RESIDENTIAL CHOICES AT THE END OF THE FIRST YEAR  *
****************************************************************


eststo clear

** Panel A: Still in residence in yr 2

foreach i in   stillinres    {

	*White
	xi: reg `i'  mixracebas `controls_subsample' `rocontrols' i.Res_base if round==2&white==1,  robust cluster(roomnum_base)
		eststo  resid_1_1w
		sum `i'  if mixracebas==0 & e(sample)==1 & white==1
		estadd scalar meanofdepvar=r(mean)
		
	*Blacks
	xi: reg `i'  mixracebas `controls_subsample' `rocontrols' i.Res_base if round==2&black==1, robust cluster(roomnum_base)
		eststo  resid_1_1b
		sum `i'  if mixracebas==0 & e(sample)==1 & black==1
		estadd scalar meanofdepvar=r(mean)
		
	*Full
	xi: reg `i'  mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base if round==2, robust cluster(roomnum_base)
		eststo  resid_1_1f
		sum `i'  if mixracebas==0 & e(sample)==1
		estadd scalar meanofdepvar=r(mean)
}

* B 
foreach i in   Inresmix_yr2     {

xi: reg   `i'    mixracebas   `controls' `rocontrols' if round==2 & white==1, robust cluster(roomnum_base)
eststo  resid_2_1w
sum `i' if mixracebas==0 & e(sample)==1 
estadd scalar meanofdepvar=r(mean)

xi: reg   `i'   mixracebas   `controls' `rocontrols' if round==2 & black==1, robust cluster(roomnum_base)
eststo  resid_2_1b
sum `i' if mixracebas==0 & e(sample)==1 
estadd scalar meanofdepvar=r(mean)

		
	*Full
	xi: reg `i'  mixracebas `controls' `rocontrols' if round==2, robust cluster(roomnum_base)
		eststo  resid_2_1f
		sum `i'  if mixracebas==0 & e(sample)==1
		estadd scalar meanofdepvar=r(mean)
		
}


* E (Note 5 individuals are in a double room and still in residence but there is only one individual staying in the room in the admin data)
foreach i in   Same_ro_yr2    {
		
xi: reg   `i'   mixracebas   `controls' `rocontrols' if round==2 & white==1, robust cluster(roomnum_base)
eststo  resid_3_1w
sum `i' if mixracebas==0 & e(sample)==1 
estadd scalar meanofdepvar=r(mean)
		
xi: reg   `i'    mixracebas   `controls' `rocontrols' if round==2 & black==1, robust cluster(roomnum_base)
eststo  resid_3_1b
sum `i' if mixracebas==0 & e(sample)==1 
		estadd scalar meanofdepvar=r(mean)
		
	*Full
	xi: reg `i'  mixracebas `controls' `rocontrols' if round==2, robust cluster(roomnum_base)
		eststo  resid_3_1f
		sum `i'  if mixracebas==0 & e(sample)==1
		estadd scalar meanofdepvar=r(mean)
}



xml_tab   resid_* , save(`namexls') sh(Tab6_resid2) showeq  append stats(meanofdepvar r2 N_clust N) note("Notes: Robust standard errors in parentheses") title("Table: Residential choices") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*) stars()



exit

```

### `ForJournals_a/Code/analysis/2_appendix_tables.do`
```stata
 /************************************************************************************************************************************************

Project: Interaction, Sterotypes and Performance: Evidence from South Africa
Corno L., La Ferrara E., Burns J.

do file: 2_appendix_tables.do

Last updated on: July 2022
Output: Appendix tables and figures
*************************************************************************************************************************************************/

clear all

*To save tables in excel
local c_date=c(current_date)
local date_string = subinstr("`c_date'", " ", "_", .)
local namexls "$main_tables/Tables`date_string'.xls"
local appendixxls "$appendix_tables/AppendixTables`date_string'_stars.xls"
 
local namecsv Tables`date_string'
local namepng Graphs`date_string'

****  LOCALS OF CONTROLS  ****

*FULL SAMPLE
local controls white coloured Else Female Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss     
*BLACK and WHITE subsamples
local controls_subsample Female Falseuct2012 missfalse Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss      
*NON WHITE subsample
local controls_nonwhite coloured Else Female Falseuct2012 missfalse  Foreign foreign_missing privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss  consbas_nomiss consbas_miss      
*Roommate controls
local rocontrols roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas  roprivschool_nomiss roprivschool_miss  rodurpcabas_nomiss rodurpcabas_miss  roconsbas_nomiss roconsbas_miss  


********************************************
******     FIGURES     *********************
********************************************

***  Fig. A3: GPA
**GPA DISTRIBUTION, BY RACE

use "$clean/uctdata_balanced.dta", clear

	twoway kdensity GPA if (round==2&white==1), lcolor(navy) || kdensity GPA if (round==2&black==1), lpattern(dash) lcolor(cranberry) /* 
	*/xtitle(GPA) ytitle("") title(GPA at follow up) legend(ring(0) pos(11) label(1 "Whites") label(2 "Blacks") label(3 "Blacks"))
	graph export "$figures/FigA3_GPA.png", replace



**************************************************
*****  Table A1: **CORRELATES OF ATTRITION  *******
**************************************************

use "$clean/uctdata_clean.dta", clear 

merge m:1 nstudent using "$clean/new_accommodation_2012.dta", keepusing(building*) keep(1 3)

replace Res_base=10 if buildings_name==7
replace Res_base=9 if buildings_name==9
replace Res_base=8 if buildings_name==8
replace blackRes=Res_base*black
replace whiteRes=Res_base*white

foreach i in  balanced  {

xi:  reg `i'  mixracebas `controls' i.blackRes i.whiteRes i.Res_base if round==1, robust cluster(roomnum_base)
eststo  att_`i'_1full
sum `i' if  e(sample)==1 
estadd scalar meanofdepvar=r(mean)
	
	
xi:  reg `i'  DscoreraceIAT `controls' i.blackRes i.whiteRes i.Res_base if round==1, robust cluster(roomnum_base)
eststo  att_`i'_2full
sum `i'  if  e(sample)==1 
estadd scalar meanofdepvar=r(mean)

xi:  reg `i'  DscoreacaIAT `controls' i.blackRes i.whiteRes i.Res_base if round==1, robust cluster(roomnum_base)
eststo  att_`i'_3full
sum `i'  if  e(sample)==1 
estadd scalar meanofdepvar=r(mean)

xi:  reg `i'  mixracebas DscoreraceIAT DscoreraceIATmix `controls' i.blackRes i.whiteRes i.Res_base if round==1, robust cluster(roomnum_base)
eststo  att_`i'_4full
sum `i'  if  e(sample)==1 
estadd scalar meanofdepvar=r(mean)

xi:  reg `i'  mixracebas DscoreacaIAT DscoreacaIATmix `controls' i.blackRes i.whiteRes i.Res_base if round==1, robust cluster(roomnum_base)
eststo  att_`i'_5full
sum `i'  if  e(sample)==1 
estadd scalar meanofdepvar=r(mean)

xi:  reg `i'  mixracebas  DscoreraceIAT whi_raceIAT col_raceIAT else_raceIAT `controls' i.blackRes i.whiteRes i.Res_base if round==1, robust cluster(roomnum_base)
eststo  att_`i'_6full
sum `i'  if  e(sample)==1 
estadd scalar meanofdepvar=r(mean)

xi:  reg `i'  mixracebas DscoreacaIAT  whi_acaIAT col_acaIAT else_acaIAT `controls' i.blackRes i.whiteRes i.Res_base if round==1, robust cluster(roomnum_base)
eststo  att_`i'_7full
sum `i'  if  e(sample)==1 
estadd scalar meanofdepvar=r(mean)

}

xml_tab   att_* , save("`appendixxls'") sh(TabA1_attrition) showeq  replace stats(meanofdepvar r2  N) note("Notes: Robust standard errors in parentheses")  stars(* 0.1 ** 0.05 *** 0.01) title("Table A1: Correlates of attrition") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*)
eststo clear


************************************************************************
*  TABLE A2 - Comparison of sample w/ other UCT students
************************************************************************
do "$dofiles/analysis/4_appendixA2.do"
 
****************************************
*  TABLE A3: CORRELATES OF THE RACE IAT*  
****************************************

use "$clean/uctdata_clean.dta", clear 

*Games

foreach i in   Pris_coopbelief     {

	*White
	xi: reg `i'  DscoreraceIAT if round==2&white==1,  robust 
		eststo  games_`i'_1
	xi: reg `i'  DscoreraceIAT PCAfriend if round==2&white==1,  robust 
		eststo  games_`i'_2
	xi: reg `i'  DscoreraceIAT PCAfriend `controls_subsample' if round==2&white==1,  robust 
		eststo  games_`i'_3
	*Blacks
	xi: reg `i'  DscoreraceIAT if round==2&black==1,  robust 
		eststo  games_`i'_4
	xi: reg `i'  DscoreraceIAT PCAfriend if round==2&black==1,  robust 
		eststo  games_`i'_5
	xi: reg `i'  DscoreraceIAT PCAfriend `controls_subsample' if round==2&black==1,  robust 
		eststo  games_`i'_6
}

foreach i in   Cooperate     {
		
	*White
	xi: reg `i'  DscoreraceIAT if round==2&white==1,  robust 
		eststo  games_`i'_7
	xi: reg `i'  DscoreraceIAT PCAfriend if round==2&white==1,  robust 
		eststo  games_`i'_8
	xi: reg `i'  DscoreraceIAT PCAfriend `controls_subsample' if round==2&white==1,  robust 
		eststo  games_`i'_9
		
	*Blacks
	xi: reg `i'  DscoreraceIAT if round==2&black==1,  robust 
		eststo  games_`i'_10
	xi: reg `i'  DscoreraceIAT PCAfriend if round==2&black==1,  robust 
		eststo  games_`i'_11
	xi: reg `i'  DscoreraceIAT PCAfriend `controls_subsample' if round==2&black==1,  robust 
		eststo  games_`i'_12
}

xml_tab   games_* , save("`appendixxls'") sh(TabA3_Games) showeq  append stats(r2 N) note("Notes: Robust standard errors in parentheses") star(* .10 ** .05 *** .01) title("Table A3: IAT validation") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*)



*IAT at follow up
foreach i in   PCAattitude     {
		
	*White
	xi: reg `i'  DscoreraceIAT if round==2&white==1,  robust 
		eststo  fri_`i'_1
	xi: reg `i'  DscoreraceIAT  `controls_subsample' if round==2&white==1,  robust 
		eststo  fri_`i'_2
		
	*Blacks
	xi: reg `i'  DscoreraceIAT if round==2&black==1,  robust 
		eststo  fri_`i'_3
	xi: reg `i'  DscoreraceIAT  `controls_subsample' if round==2&black==1,  robust 
		eststo  fri_`i'_4
}

foreach i in   PCAfriend     {
	*White
	xi: reg `i'  DscoreraceIAT if round==2&white==1,  robust 
		eststo  fri_`i'_5
	xi: reg `i'  DscoreraceIAT  `controls_subsample' if round==2&white==1,  robust 
		eststo  fri_`i'_6
	*Blacks
	xi: reg `i'  DscoreraceIAT if round==2&black==1,  robust 
		eststo  fri_`i'_7
	xi: reg `i'  DscoreraceIAT  `controls_subsample' if round==2&black==1,  robust 
		eststo  fri_`i'_8
}



xml_tab   fri_* , save("`appendixxls'") sh(TabA3_friends) showeq  append stats(r2 N) note("Notes: Robust standard errors in parentheses") star(* .10 ** .05 *** .01) title("Table A3: Correlates of the Race IAT") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*)
eststo clear

*************************************************
*  TABLE A4: DESCRIPTIVE STATISTICS AT FOLLOW-UP*
*************************************************

use "$clean/uctdata_balanced.dta", clear 

ds DscoreraceIAT DscoreacaIAT Falseuct2012 durpcabas_nomiss consbas_nomiss  Foreign privateschool_nomiss Female GPA

local vars `r(varlist)'

di "`vars'"

*Full sample
estpost sum `vars' if round==2 & mixracebas!=. 
eststo t1_sumtot
estpost sum `vars' if round==2 & mixracebas==1
eststo t1_summix
estpost sum `vars' if round==2 & mixracebas==0
eststo t1_sumsam
estpost ttest `vars' if round==2, by(mixracebas)
eststo t1_ttest

*For whites
estpost sum `vars' if round==2 & white==1 & mixracebas!=. 
eststo t1_sumtotw
estpost sum `vars' if round==2 & white==1 & mixracebas==1
eststo t1_summixw
estpost sum `vars' if round==2 & white==1 & mixracebas==0
eststo t1_sumsamw
estpost ttest `vars' if round==2 & white==1, by(mixracebas)
eststo t1_ttestw

*For blacks
estpost sum `vars' if round==2 & black==1 & mixracebas!=. 
eststo t1_sumtotb
estpost sum `vars' if round==2 & black==1 & mixracebas==1
eststo t1_summixb
estpost sum `vars' if round==2 & black==1 & mixracebas==0
eststo t1_sumsamb
estpost ttest `vars' if round==2 & black==1, by(mixracebas)
eststo t1_ttestb


xml_tab t1_sumtot(count min)  t1_sumtot(mean sd)  t1_summix(mean sd) t1_sumsam(mean sd) t1_ttest(b p), stars(* 0.1 ** 0.05 *** 0.01) stats(N) save("`appendixxls'") append /*
*/ ceq("Full sample" "Full sample" "Full sample" "Full sample" "Mixed rooms" "Mixed rooms" "Not mixed rooms"  "Not mixed rooms" "Diff=0" "Diff=0") /*
*/ showeq sh(TabA4_sustats)  title("Table A4: Summary statistics at follow up and difference in means between treatment and control")/*
*/ cnames("Obs. Number" "Min" "Mean" "Std. Dev" "Mean" "Std. Dev" "Mean" "Std. Dev" "Diff" "P-value")  drop(o*) /*
*/ note("Note: Mean outcomes. The P-values test the null hypothesis that the means are equal. *** 1%, **5%, *10% significance.",/*
*/"Higher values of IAT score indicate less prejudice against blacks.",/*
*/ "UCT entry score: sum of high school final grades, with weights depending on the specific departement the student enrolls in.")

xml_tab t1_sumtotw(count min) t1_sumtotw(mean sd)  t1_summixw(mean sd) t1_sumsamw(mean sd) t1_ttestw(b p), stars(* 0.1 ** 0.05 *** 0.01) stats(N) save("`appendixxls'") append ceq("Full sample" "Full sample" "Full sample" "Full sample" "Mixed rooms" "Mixed rooms" "Not mixed rooms"  "Not mixed rooms" "Diff=0" "Diff=0") showeq sh(TA4_whites)  title("Table A3B: Summary statistics at follow up and difference in means for whites") cnames("Obs. Number" "Min" "Mean" "Std. Dev" "Mean" "Std. Dev" "Mean" "Std. Dev" "Diff" "P-value") drop(o*)

xml_tab t1_sumtotb(count min) t1_sumtotb(mean sd) t1_summixb(mean sd) t1_sumsamb(mean sd) t1_ttestb(b p), stars(* 0.1 ** 0.05 *** 0.01) stats(N) save("`appendixxls'") append ceq("Full sample" "Full sample" "Full sample" "Full sample" "Mixed rooms" "Mixed rooms" "Not mixed rooms"  "Not mixed rooms" "Diff=0" "Diff=0") showeq sh(TA4_blacks)  title("Table A3C: Summary statistics at baseline and difference in means for black")  cnames("Obs. Number" "Min" "Mean" "Std. Dev" "Mean" "Std. Dev" "Mean" "Std. Dev" "Diff" "P-value") drop(o*)


****************************
*** TABLE A5 - SIMULATION**
***************************
preserve
	do "$dofiles/analysis/5_tableA5_control.do"
	do "$dofiles/analysis/6_tableA5_nocontrol.do"
restore


*******************************************
*** TABLE A6: PLACEBO REGRESSIONS *********
*******************************************

use "$clean/uctdata_balanced.dta", clear 

*PANEL A

foreach i in  DscoreraceIATbas {
	
	*White
	xi: reg `i' mixracebas  `controls_subsample' i.Res_base  if round==2&white==1,  robust cluster(roomnum_base)
		eststo  iat_1w 
	sum DscoreraceIATbas if mixracebas==0 & e(sample)==1 & white==1

	*Black
	xi: reg `i' mixracebas `controls_subsample' i.Res_base  if round==2&black==1,  robust cluster(roomnum_base)
		eststo  iat_1b
	sum DscoreraceIATbas if mixracebas==0 & e(sample)==1 & black==1	
	
	*Full
	xi: reg `i' mixracebas `controls' i.blackRes i.whiteRes i.Res_base  if round==2,  robust cluster(roomnum_base)
		eststo  iat_1f
	sum DscoreraceIATbas if mixracebas==0 & e(sample)==1
	}
		
		*With roommate characteristics
	foreach i in  DscoreraceIATbas {
	
	*White
	xi: reg `i' mixracebas  `controls_subsample' `rocontrols'  i.Res_base  if round==2&white==1,  robust cluster(roomnum_base)
		eststo  iat_3w
	sum DscoreraceIATbas if mixracebas==0 & e(sample)==1 & white==1

	*Black
	xi: reg `i' mixracebas `controls_subsample' `rocontrols'  i.Res_base  if round==2&black==1,  robust cluster(roomnum_base)
		eststo  iat_3b
	sum DscoreraceIATbas if mixracebas==0 & e(sample)==1 & black==1	
	
	*Full
	xi: reg `i' mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base  if round==2,  robust cluster(roomnum_base)
		eststo  iat_3f
	sum DscoreraceIATbas if mixracebas==0 & e(sample)==1
	}	

**PANEL B
	
foreach i in DscoreacaIATbas {


	*White
	xi: reg `i' mixracebas  `controls_subsample'  i.Res_base if round==2&white==1,  robust cluster(roomnum_base)
		eststo  iat_2w
	sum DscoreacaIATbas if mixracebas==0 & e(sample)==1 & white==1

	*Black
	xi: reg `i' mixracebas  `controls_subsample'  i.Res_base if round==2&black==1,  robust cluster(roomnum_base)
		eststo  iat_2b
	sum DscoreacaIATbas if mixracebas==0 & e(sample)==1 & black==1
	
	*Full	
	xi: reg `i' mixracebas `controls' i.blackRes i.whiteRes i.Res_base  if round==2,  robust cluster(roomnum_base)
		eststo  iat_2f
	sum DscoreraceIATbas if mixracebas==0 & e(sample)==1
	}



	
foreach i in DscoreacaIATbas {
	
	*White
	xi: reg `i' mixracebas   `controls_subsample'  `rocontrols'  i.Res_base if round==2&white==1,  robust cluster(roomnum_base)
		eststo  iat_4w
	sum DscoreacaIATbas if mixracebas==0 & e(sample)==1 & white==1

	*Black
	xi: reg `i' mixracebas `controls_subsample'  `rocontrols'  i.Res_base if round==2&black==1,  robust cluster(roomnum_base)
		eststo  iat_4b
	sum DscoreacaIATbas if mixracebas==0 & e(sample)==1 & black==1
	
	*Full
	xi: reg `i' mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base  if round==2,  robust cluster(roomnum_base)
		eststo  iat_4f
	sum DscoreraceIATbas if mixracebas==0 & e(sample)==1
	}


xml_tab   iat_* , save("`appendixxls'") sh(A6_IAT_placebo) showeq stats(r2 N) append  note("Notes: Robust standard errors in parentheses. All regressions include Res_base FE and the controls listed in column 2 of Table 4.", "(a) In our sample all Coloureds are in mixed race rooms") star(* .10 ** .05 *** .01) title("Table A6: Placebo regression") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*)
eststo clear

**PANEL C

	foreach i in LPCAattitude {

	*White
	xi: reg `i'  mixracebas  `controls_subsample'   i.Res_base if round==2&white==1,  robust  cluster(roomnum_base)
		eststo  soc_`i'_1
	*Blacks
	xi: reg `i'  mixracebas `controls_subsample'   i.Res_base if round==2&black==1,  robust  cluster(roomnum_base)
		eststo  soc_`i'_2
	*Full
	xi: reg `i'  mixracebas `controls' i.blackRes i.whiteRes  i.Res_base if round==2,  robust  cluster(roomnum_base)
		eststo  soc_`i'_3
	
	}

	foreach i in LPCAattitude {
		
	*White
	xi: reg `i'  mixracebas  `controls_subsample'  `rocontrols'  i.Res_base if round==2&white==1,  robust  cluster(roomnum_base)
		eststo  soc_`i'_4
	*Blacks
	xi: reg `i'  mixracebas `controls_subsample'  `rocontrols'  i.Res_base if round==2&black==1,  robust  cluster(roomnum_base)
		eststo  soc_`i'_5
	*Full
	xi: reg `i'  mixracebas `controls' `rocontrols' i.blackRes i.whiteRes  i.Res_base if round==2,  robust  cluster(roomnum_base)
		eststo  soc_`i'_6
	}
	
xml_tab   soc_* , save("`appendixxls'") sh(TabA6_AttitudePCA_Placebo) showeq  append stats(r2 N) note("Notes: Standard errors in parentheses") star(* .10 ** .05 *** .01) title("Table A6: PCA attitudes") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*)
eststo clear


*********************************************************************************************
*** TABLE A7: STEREOTYPES AND EXPOSURE TO A ROOMMATE OF DIFFERENT RACE, NO ROOMMATE CONTROLS *
**********************************************************************************************


use "$clean/uctdata_balanced.dta", clear


xtset individual round
sort individual round



****  ROBUSTNESS:  without Roommate controls

foreach i in DscoreraceIAT {

	*Fake to order coeffs
	xi: reg `i'  mixracebas L.`i' `controls' i.blackRes i.whiteRes i.Res_base  if round==2,  robust cluster(roomnum_base)
		eststo  iat_0erase
	sum DscoreraceIAT if mixracebas==0 & e(sample)==1 
	estadd scalar meanofdepvar=r(mean)
	
	
	*White
	xi: reg `i' mixracebas L.`i' `controls_subsample' i.Res_base if round==2&white==1,  robust cluster(roomnum_base)
		eststo  iat_1wc
	sum DscoreraceIAT if mixracebas==0 & e(sample)==1 & white==1
	estadd scalar meanofdepvar=r(mean)
	
	*Black
	xi: reg `i' mixracebas L.`i' `controls_subsample' i.Res_base if round==2&black==1, robust cluster(roomnum_base) 
		eststo  iat_1bc
	sum DscoreraceIAT if mixracebas==0 & e(sample)==1 & black==1	
	estadd scalar meanofdepvar=r(mean)
	}
		
		
foreach i in DscoreacaIAT {
	
	
	*White
	xi: reg `i' mixracebas L.`i' `controls_subsample' i.Res_base if round==2&white==1,  robust cluster(roomnum_base)
		eststo  iat_2wc
	sum DscoreacaIAT if mixracebas==0 & e(sample)==1 & white==1
	estadd scalar meanofdepvar=r(mean)
	
	*Black
	xi: reg `i' mixracebas L.`i' `controls_subsample' i.Res_base if round==2&black==1,  robust cluster(roomnum_base)
		eststo  iat_2bc
	sum DscoreacaIAT if mixracebas==0 & e(sample)==1 & black==1
	estadd scalar meanofdepvar=r(mean)
	}


xml_tab   iat_* , save("`appendixxls'") sh(TabA7_IAT_NoRocontrols) showeq stats(meanofdepvar r2 N_clust N) append  note("Notes: Robust standard errors in parentheses. All regressions include Res_base FE and the controls listed in column 2 of Table 4.", "(a) In our sample all Coloureds are in mixed race rooms")  stars(* 0.1 ** 0.05 *** 0.01) title("Table A7: IAT, w/o roommate controls") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*)
eststo clear


***************************************************************************************
*** TABLE A8: STEREOTYPES AND EXPOSURE TO A ROOMMATE OF DIFFERENT RACE, BY RACE GROUP *
***************************************************************************************

preserve

* Keeping coloured
g mixracebas1=mixracebas
replace  mixracebas1=. if (Race==4)
replace  mixracebas1=. if white==1&(roRace==4)
replace  mixracebas1=. if black==1&(roRace==4)
replace mixracebas1=. if roRace==.
replace mixracebas1=. if Race==.

* Whites and Blacks only
replace  mixracebas=. if (Race==2|Race==4)
replace  mixracebas=. if white==1&(roRace==2|roRace==4)
replace  mixracebas=. if black==1&(roRace==2|roRace==4)
replace mixracebas=. if roRace==.
replace mixracebas=. if Race==.

g roothbas1=rooth if round==1
bys nstudent: egen roothbas=max(roothbas1)
drop roothbas1
replace roothbas=0 if roothbas==.&roRace==1
replace roothbas=0 if roothbas==.&roRace==3
replace roothbas=. if roRace==.

g rocolbas1=rocol if round==1
bys nstudent: egen rocolbas=max(rocolbas1)
drop rocolbas1
replace rocolbas=0 if rocolbas==.&roRace==1
replace rocolbas=0 if rocolbas==.&roRace==3
replace rocolbas=. if roRace==.


g roelsebas1=roElse if round==1
bys nstudent: egen roelsebas=max(roelsebas1)
drop roelsebas1
replace roelsebas=0 if roelsebas==.&roRace==1
replace roelsebas=0 if roelsebas==.&roRace==3
replace roelsebas=. if roRace==.

xtset individual round
sort individual round

g rocoloth=(roRace==2|roRace==4|roRace==5) if roRace!=.&round==1
g rocolothbas=L.rocoloth

g rowhitebas=L.rowhite
g roblabas=L.roblack


foreach i in DscoreraceIAT {
		
	xi: reg `i' roblabas rocolothbas L.`i' `controls_subsample' `rocontrols'  i.Res_base  if round==2&white==1,  robust    cluster (roomnum_base) 
	eststo  iat_3w
	test roblabas=rocolothbas
	sum DscoreraceIAT if mixracebas==0 & e(sample)==1 &white==1
	estadd scalar meanofdepvar=r(mean)

	xi: reg `i' rowhitebas rocolothbas L.`i' `controls_subsample' `rocontrols'  i.Res_base  if round==2&black==1,  robust    cluster (roomnum_base) 
	eststo  iat_3b
	test rowhitebas=rocolothbas
	sum DscoreraceIAT if mixracebas==0 & e(sample)==1 &black==1
	estadd scalar meanofdepvar=r(mean)
		}
		
		
foreach i in DscoreacaIAT {
	
	xi: reg `i' roblabas rocolothbas L.`i' `controls_subsample' `rocontrols' i.Res_base  if round==2&white==1,  robust    cluster (roomnum_base) 
	eststo  iat_6w
	test roblabas=rocolothbas
	sum DscoreraceIAT if mixracebas==0 & e(sample)==1 &white==1
	estadd scalar meanofdepvar=r(mean)
	
	xi: reg `i' rowhitebas rocolothbas L.`i' `controls_subsample' `rocontrols' i.Res_base  if round==2&black==1,  robust    cluster (roomnum_base) 
	eststo  iat_9b
	test rowhitebas=rocolothbas
	sum DscoreraceIAT if mixracebas==0 & e(sample)==1 &black==1
	estadd scalar meanofdepvar=r(mean)
		}
		
xml_tab   iat_* , save("`appendixxls'") sh(TabA8_IATWhitesBlacksOnly) showeq stats(meanofdepvar r2 N) append  note("Notes: Robust standard errors in parentheses. All regressions include Res_base FE and the controls listed in column 2 of Table 4.", "(a) In our sample all Coloureds are in mixed race rooms") star(* .10 ** .05 *** .01) title("Table A8: IAT") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*)
eststo clear

restore

**********************************************************************
*** TABLE A9: IMPACT OF ACADEMIC PERFORMANCE WITHOUT ROOMATE CONTROLS*
**********************************************************************


foreach i in GPA examspassed continue PCAperf {
	

	*White
	xi: reg `i'  mixracebas `controls_subsample'  i.Res_base i.regprogram   if round==2&white==1,  robust cluster(roomnum_base) 
		eststo  perf_`i'_1
	sum `i' if mixracebas==0 & e(sample)==1 & white==1 
	estadd scalar meanofdepvar=r(mean)

	*Black
	xi: reg `i'  mixracebas `controls_subsample'  i.Res_base i.regprogram  if round==2&black==1,  robust cluster(roomnum_base)
		eststo  perf_`i'_2
	sum `i' if mixracebas==0 & e(sample)==1  & black==1
	estadd scalar meanofdepvar=r(mean)
	
	*Full
	xi: reg `i'  mixracebas  `controls' i.blackRes i.whiteRes i.Res_base i.regprogram  if round==2,  robust cluster(roomnum_base)
		eststo  perf_`i'_3
	sum `i' if mixracebas==0 & e(sample)==1 
	estadd scalar meanofdepvar=r(mean)
	
}

xml_tab   perf_* , save("`appendixxls'") sh(TabA9_AcaPerf_NoRocontrols) showeq  append stats(meanofdepvar r2 N_clust N) note("Notes: Robust standard errors in parentheses")  stars(* 0.1 ** 0.05 *** 0.01) title("Table A9: Impact on academic performance, w/o roommate controls") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*)
eststo clear

********************************************************
**TABLE A10: **ACADEMIC PERFORMANCE IN THE SECOND YEAR**
********************************************************


foreach i in GPA2013  examspassed2013  continue2013 PCAperf2013 {

	
	*White
	xi: reg `i'  mixracebas `controls_subsample' `rocontrols' i.Res_base i.regprogram if round==2&white==1,  robust cluster(roomnum_base)
		eststo  perf13_`i'_1
	sum `i' if mixracebas==0 & e(sample)==1  &white==1
	estadd scalar meanofdepvar=r(mean)
	
	*Black
	xi: reg `i'  mixracebas `controls_subsample' `rocontrols' i.Res_base i.regprogram  if round==2&black==1,  robust cluster(roomnum_base)
		eststo  perf13_`i'_2
	sum `i' if mixracebas==0 & e(sample)==1  &black==1
	estadd scalar meanofdepvar=r(mean)
	
	*Full sample
	xi: reg `i'  mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base i.regprogram  if round==2,  robust cluster(roomnum_base)
		eststo  perf13_`i'_3
	sum `i'  if mixracebas==0 & e(sample)==1  
	estadd scalar meanofdepvar=r(mean)
}

xml_tab   perf13_* , save("`appendixxls'") sh(TabA10_perform2013) showeq  append stats(meanofdepvar r2 N_clust N) note("Notes: Robust Standard errors in parentheses")  stars(* 0.1 ** 0.05 *** 0.01) title("Table A10: Academic performance in the second year") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*)
eststo clear



***************************************************************************************
**TABLE A11: IMPACT ON PERFORMANCE AND STANDARD ACADEMIC INTERACTION, BLACK SUBSAMPLE**
***************************************************************************************

eststo clear

*Same Faculty

foreach i in PCAperf GPA {

	*Black
	xi: reg `i'  mixracebas mixsamefaculty samefaculty `controls_subsample' `rocontrols' i.Res_base i.regprogram  if round==2&black==1, robust cluster(roomnum_base)
		eststo  v_`i'_2b
	sum `i'  if mixracebas==0 & e(sample)==1  & black==1
	estadd scalar meanofdepvar=r(mean)
}

* Same course

foreach i in PCAperf GPA {

	*Black
	xi: reg `i'  mixracebas mixsamecourse same_course `controls_subsample' `rocontrols' i.Res_base i.regprogram  if round==2&black==1, robust cluster(roomnum_base)
		eststo  v_`i'_3b
	sum `i'  if mixracebas==0 & e(sample)==1  & black==1
	estadd scalar meanofdepvar=r(mean)
}

foreach i in roommate_study {

	*Black
	xi: reg `i'  mixracebas `controls_subsample' `rocontrols' i.Res_base i.regprogram  if round==2&black==1, robust cluster(roomnum_base)
		eststo  v_`i'_4b
	sum `i'  if mixracebas==0 & e(sample)==1  & black==1
	estadd scalar meanofdepvar=r(mean)
}

foreach i in roommate_study {

	*Black
	xi: reg `i'  mixracebas samefaculty `controls_subsample' `rocontrols' i.Res_base i.regprogram  if round==2&black==1, robust cluster(roomnum_base)
		eststo  v_`i'_5b
	sum `i'  if mixracebas==0 & e(sample)==1  & black==1
	estadd scalar meanofdepvar=r(mean)
}

xml_tab   v_* , save("`appendixxls'") sh(TabA11_channels) showeq  append stats(meanofdepvar r2 N_clust N) note("Notes: Standard errors in parentheses") title("Table A11: Academic peer effects") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*) stars()
eststo clear



*************************************
* TABLE A12: **IMPACT ON FRIENDSHIP *
*************************************


*Hang out with roommate in the last month: 0, nver, 1 sometimes, 2, often, 3 very often

foreach i in  hangdiff hanglast {
	
	*Full
	xi: ologit `i'  mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base if round==2,  robust cluster(roomnum_base)
		eststo  fri_`i'_1
		sum `i' if mixracebas==0 & e(sample)==1 
		estadd scalar meanofdepvar=r(mean)

	*Whites
	xi: ologit `i'  mixracebas `controls_subsample' `rocontrols' i.Res_base if round==2&white==1,  robust cluster(roomnum_base)
		eststo  fri_`i'_2
		sum `i' if mixracebas==0 & e(sample)==1  &white==1
		estadd scalar meanofdepvar=r(mean)

	*Black
	xi: ologit `i'   mixracebas `controls_subsample' `rocontrols' i.Res_base if round==2&black==1,  robust cluster(roomnum_base)
		eststo  fri_`i'_3
		sum `i' if mixracebas==0 & e(sample)==1  &black==1
		estadd scalar meanofdepvar=r(mean)

}

foreach i in  pctFriendsdiff_net pctStudydiffer_net LeisuOth StudyOth {
	
	*Full
	xi: reg `i'   mixracebas `controls' `rocontrols'  i.blackRes i.whiteRes i.Res_base if round==2, robust cluster(roomnum_base)
		eststo  fri_`i'_4
		sum `i' if mixracebas==0 & e(sample)==1 
		estadd scalar meanofdepvar=r(mean)

	*White
	xi: reg `i'   mixracebas `controls_subsample' `rocontrols' i.Res_base if round==2&white==1, robust cluster(roomnum_base)
		eststo  fri_`i'_5
		sum `i' if mixracebas==0 & e(sample)==1  &white==1
		estadd scalar meanofdepvar=r(mean)

	*Black
	xi: reg `i'  mixracebas `controls_subsample' `rocontrols' i.Res_base if round==2&black==1, robust cluster(roomnum_base)
		eststo  fri_`i'_7
		sum `i' if mixracebas==0 & e(sample)==1  &black==1
		estadd scalar meanofdepvar=r(mean)

}

cap xml_tab   fri_* , save("`appendixxls'") sh(TabA12_Friendship) showeq stats(meanofdepvar r2 N_clust N) append  note("Notes: Robust standard errors in parentheses. All regressions include Res_base FE and the controls listed in column 2 of Table 4.", "(a) In our sample all Coloureds are in mixed race rooms")  stars(* 0.1 ** 0.05 *** 0.01) title("Table A12: Impact on Friendship") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*)
eststo clear

***************************************************
***  TABLE A13: IMPACT ON ATTITUDINAL MEASURES  ***
***************************************************


	rename dancinganotherrace dancinganother
	rename boyfriendanotherrace boyfriendanother


foreach i in talk   {

	*Full
	xi: ologit `i' L.`i'  mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base if round==2,  robust cluster(roomnum_base)
		eststo  att_`i'_1f
		sum `i' if mixracebas==0 & e(sample)==1 
		estadd scalar meanofdepvar=r(mean)

	*Whites
	xi: ologit `i' L.`i'  mixracebas `controls_subsample' `rocontrols' i.Res_base if round==2&white==1,  robust cluster(roomnum_base)
		eststo  att_`i'_6w
		sum `i' if mixracebas==0 & e(sample)==1  &white==1
		estadd scalar meanofdepvar=r(mean)

	*Black
	xi: ologit `i' L.`i' mixracebas `controls_subsample' `rocontrols' i.Res_base if round==2&black==1,  robust cluster(roomnum_base)
		eststo  att_`i'_8b
		sum `i' if mixracebas==0 & e(sample)==1  &black==1
		estadd scalar meanofdepvar=r(mean)

}

foreach i in  excomfort Abolishaffirm_dis dancinganother boyfriendanother   {
	
	*Full
	xi: reg `i' L.`i'  mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base if round==2,  robust cluster(roomnum_base)
		eststo  att_`i'_9f
		sum `i' if mixracebas==0 & e(sample)==1
		estadd scalar meanofdepvar=r(mean)

	*Whites
	xi: reg `i' L.`i'  mixracebas `controls_subsample' `rocontrols' i.Res_base if round==2&white==1,  robust cluster(roomnum_base)
		eststo  att_`i'_10w
		sum `i' if mixracebas==0 & e(sample)==1  &white==1
		estadd scalar meanofdepvar=r(mean)

	*Black
	xi: reg `i'  L.`i'  mixracebas `controls_subsample' `rocontrols' i.Res_base if round==2&black==1,  robust cluster(roomnum_base)
		eststo  att_`i'_12b
		sum `i' if mixracebas==0 & e(sample)==1  &black==1
		estadd scalar meanofdepvar=r(mean)

}
	
cap xml_tab   att_* , save("`appendixxls'") sh(TabA13_attitudinalmeasures) showeq stats(meanofdepvar r2 N_clust N) append  note("Notes: Standard errors in parentheses. All regressions include Res_base FE and the controls listed in column 2 of Table 4.", "(a) In our sample all Coloureds are in mixed race rooms")  stars(* 0.1 ** 0.05 *** 0.01) title("Table A13: Attitudinal measures") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*)

eststo clear

***************************************************
*** TABLE A14: IMPACT ON PRO-SOCIAL BEHAVIOUR *****
***************************************************


foreach i in   community charity_amount  {
	*Full sample
	xi: reg `i'  mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base  if round==2,  robust cluster(roomnum_base)
		eststo vol_`i'_1
		sum `i'  if mixracebas==0 & e(sample)==1  
		estadd scalar meanofdepvar=r(mean)

	
	*White
	xi: reg `i'  mixracebas `controls_subsample' `rocontrols' i.Res_base  if round==2&white==1,  robust cluster(roomnum_base)
		eststo  vol_`i'_2w
		sum `i' if mixracebas==0 & e(sample)==1  &white==1
		estadd scalar meanofdepvar=r(mean)

	*Black
	xi: reg `i'  mixracebas `controls_subsample' `rocontrols' i.Res_base  if round==2&black==1,  robust cluster(roomnum_base)
		eststo  vol_`i'_4b
		sum `i' if mixracebas==0 & e(sample)==1  &black==1
		estadd scalar meanofdepvar=r(mean)

}

foreach i in Cooperate Pris_coopbelief {
	
	*Full sample
	xi: reg `i' mixracebas knowP  `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base if round==2, robust cluster(roomnum_base)
		eststo  vol_`i'_5
		sum `i'  if mixracebas==0 & e(sample)==1  
		estadd scalar meanofdepvar=r(mean)

	*Whites
	xi: reg `i' mixracebas knowP  `controls_subsample' `rocontrols' i.Res_base if round==2  & white==1, robust cluster(roomnum_base)
		eststo  vol_`i'_6w
		sum `i' if mixracebas==0 & e(sample)==1  &white==1
		estadd scalar meanofdepvar=r(mean)

	*Blacks
	xi: reg `i' mixracebas knowP   `controls_subsample' `rocontrols'  i.Res_base if round==2  & black==1,  robust cluster(roomnum_base)
		eststo  vol_`i'_7b
		sum `i' if mixracebas==0 & e(sample)==1  &black==1
		estadd scalar meanofdepvar=r(mean)

	
}

xml_tab   vol_* , save("`appendixxls'") sh(TabA14_prosocial) showeq stats(meanofdepvar r2 N_clust N) append  note("Notes: Robust standard errors in parentheses. All regressions include Res_base FE and the controls listed in column 2 of Table 4.", "(a) In our sample all Coloureds are in mixed race rooms")  stars(* 0.1 ** 0.05 *** 0.01) title("Table A14: Pro-social behavior") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*)
eststo clear


*********************************************
**TABLE A15: FRIENDSHIP NO MISSING VALUES  **
*********************************************


foreach i in  PCAfriend_nomiss PCAatt_nomiss PCAcomm_nomiss  PCAsocial_nomiss {

	*White
	xi: reg `i'  mixracebas `controls_subsample' `rocontrols' i.Res_base if round==2&white==1,  robust cluster (roomnum_base)
		eststo  soc_`i'_1w
	sum `i'  if mixracebas==0 & e(sample)==1 & white==1

	*Blacks
	xi: reg `i'  mixracebas `controls_subsample' `rocontrols' i.Res_base if round==2&black==1,  robust cluster (roomnum_base)
		eststo  soc_`i'_2b
	sum `i'  if mixracebas==0 & e(sample)==1 & black==1
	
	*Full sample
	reg `i'  mixracebas `controls' `rocontrols' i.whiteRes i.blackRes  i.Res_base if round==2,  robust cluster (roomnum_base)
		eststo  soc_`i'_3full
	sum `i'  if mixracebas==0 & e(sample)==1 
}

xml_tab   soc_* , save("`appendixxls'") sh(TabA15_Friendship_nomiss) showeq stats(meanofdepvar r2 N_clust N) append  note("Notes: Robust standard errors in parentheses. All regressions include Res_base FE and the controls listed in column 2 of Table 4.", "(a) In our sample all Coloureds are in mixed race rooms")  stars(* 0.1 ** 0.05 *** 0.01) title("Table A15: Friendship, no missing") below lines(_cons 2 LAST_ROW 13 COL_NAMES 2 EST_NAMES 13) drop( _I*)

eststo clear


exit 

```

### `ForJournals_a/Code/analysis/3_fwer_master.do`
```stata
/************************************************************************************************************************************************

Project: Interaction, Sterotypes and Performance: Evidence from South Africa
Corno L., La Ferrara E., Burns J.

do file: 3_fwer_master.do

Last updated on: March 2022
Output: All FWER p-values for the paper
All output here: \Dropbox\SouthAfrica_replication\Output\FWER

*************************************************************************************************************************************************/


**Massive thanks to Julian Reif for his .ado file and Anderson for his public FDR code
**http://fmwww.bc.edu/repec/bocode/w/wyoung.ado


	***************************************
	*  (1) Making the FWER sample
	***************************************

	*do "$fwer/1_fwer_sample.do"
	
	***************************************
	*  (2) Table 3
	***************************************
	
	do "$fwer/2_fwer_table3.do"


	***************************************
	*  (3) Table 4
	***************************************
	
	do "$fwer/3_fwer_table4.do"

	***************************************
	*  (4) Table 5
	***************************************
	
	do "$fwer/4_fwer_table5.do"
		

	***************************************
	*  (5) Table A7
	***************************************

	do "$fwer/5_fwer_tablea7.do"
	
	***************************************
	*  (6) Table A9
	***************************************

	do "$fwer/6_fwer_tablea9.do"
	
	***************************************
	*  (7) Table A12
	***************************************
	
	do "$fwer/7_fwer_tablea12.do"
	
	***************************************
	*  (8) Table A13
	***************************************
	
	do "$fwer/8_fwer_tablea13.do"

	***************************************
	*  (9) Table A14
	***************************************
	
	do "$fwer/9_fwer_tablea14.do"

	***************************************
	*  (10) Table A15
	***************************************
	
	do "$fwer/10_fwer_tablea15.do"

	
	
	
	
	
	
	exit 

```

### `ForJournals_a/Code/analysis/5_tableA5_control.do`
```stata
clear all
clear all
set more off
capture log close
set matsize 800
set mem 600m
pause off
set seed 3005

local rocontrols roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas  roprivschool_nomiss roprivschool_miss  rodurpcabas_nomiss rodurpcabas_miss  roconsbas_nomiss roconsbas_missing  

use "$clean/tabA5.dta", replace
	
local sims=10000
local ++sims
mat A=J(`sims',10,.)

qui{
forval i=1/`sims'{
	preserve
	sort n_order
	g rand=runiform() if odd==1 & sample==1
	bysort buildings_name female (rand): drop if _n==1 & rand!=.
	sort n_order
	qui g rand_1=runiform()
	qui g rand_2=runiform()
	
	qui g simulated_mixrace = . 
	qui g simulated_room = .
	qui bysort buildings_name female (n_order): g base_rank=_n
	sort buildings_name female rand_1 rand_2
	qui by buildings_name female: replace simulated_room=roomnum_base[base_rank]
	
	sort buildings_name female simulated_room (n_order)
	
	qui replace simulated_mixrace = 1  if Race[_n] != Race[_n+1] & Race[_n] != . & Race[_n+1] != . & buildings_name[_n] == buildings_name[_n+1] & female[_n] == female[_n+1]
	qui replace simulated_mixrace = 0  if Race[_n] == Race[_n+1] & Race[_n] != . & Race[_n+1] != . & buildings_name[_n] == buildings_name[_n+1] & female[_n] == female[_n+1]
	by buildings_name female : replace simulated_mixrace = 0  if Race[_n] == Race[_n-1] & Race[_n] != . & Race[_n-1] != . & buildings_name[_n] == buildings_name[_n-1] & female[_n] == female[_n-1] & _N==_n
	by buildings_name female : replace simulated_mixrace = 1  if Race[_n] != Race[_n-1] & Race[_n] != . & Race[_n-1] != . & buildings_name[_n] == buildings_name[_n-1] & female[_n] == female[_n-1] & _N==_n
	
	*Roommate characteristics
		qui replace simulated_mixrace = 1  if Race[_n] != Race[_n+1] & Race[_n] != . & Race[_n+1] != . & buildings_name[_n] == buildings_name[_n+1] & female[_n] == female[_n+1]
	qui replace simulated_mixrace = 0  if Race[_n] == Race[_n+1] & Race[_n] != . & Race[_n+1] != . & buildings_name[_n] == buildings_name[_n+1] & female[_n] == female[_n+1]
	by buildings_name female : replace simulated_mixrace = 0  if Race[_n] == Race[_n-1] & Race[_n] != . & Race[_n-1] != . & buildings_name[_n] == buildings_name[_n-1] & female[_n] == female[_n-1] & _N==_n
	by buildings_name female : replace simulated_mixrace = 1  if Race[_n] != Race[_n-1] & Race[_n] != . & Race[_n-1] != . & buildings_name[_n] == buildings_name[_n-1] & female[_n] == female[_n-1] & _N==_n
	
	bysort buildings_name female:gen room=mod(_n,2)
	g ronstudent=.
	by buildings_name female : replace ronstudent=nstudent[_n-1] if room==0 & room[_n-1]==1
	by buildings_name female : replace ronstudent=nstudent[_n+1] if room==1 & room[_n+1]==0

	merge 1:1 ronstudent using "$clean/ronstudent_sim.dta", nogen keep(1 3) keepusing(*_sim)

	merge 1:1 nstudent round using  "$clean/uctdata_balanced.dta", keepusing(white coloured Else Female Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss round DscoreraceIAT DscoreacaIAT  blackRes whiteRes Res_base mixracebas `rocontrols' ) keep(3)

	if `i'==1{
	reg mixracebas    DscoreraceIAT DscoreacaIAT white coloured Else Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss i.blackRes i.whiteRes i.Res_base `rocontrols'	
	}
	else{
	reg simulated_mixrace    DscoreraceIAT DscoreacaIAT white coloured Else Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss  i.blackRes i.whiteRes i.Res_base *_sim
	}

	restore
	
	matrix A[`i',1]=_b[DscoreraceIAT]
	matrix A[`i',2]=_b[DscoreacaIAT]
	matrix A[`i',3]=_b[white]
	matrix A[`i',4]=_b[coloured]
	matrix A[`i',5]=_b[Else]
	matrix A[`i',6]=_b[Falseuct2012]
	matrix A[`i',7]=_b[Foreign]
	matrix A[`i',8]=_b[privateschool_nomiss]
	matrix A[`i',9]=_b[durpcabas_nomiss]
	matrix A[`i',10]=_b[consbas_nomiss]
}
clear
svmat A
}

forval i=1/10{
	qui count if A`i'<A`i'[1] & _n!=1
	di r(N)/`sims'
}

```

### `ForJournals_a/Code/analysis/6_tableA5_nocontrol.do`
```stata
clear all
set more off
capture log close
set matsize 800
set mem 600m
set seed 152

local rocontrols roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas  roprivschool_nomiss roprivschool_miss  rodurpcabas_nomiss rodurpcabas_miss  roconsbas_nomiss roconsbas_missing  

use "$clean/tabA5.dta", replace
	
local sims=10000
local ++sims
mat A=J(`sims',10,.)

_dots 0, title(Loop running) reps(`sims')
qui{
forval i=1/`sims'{
	preserve
	noi _dots `i' 0
	sort n_order
	g rand=runiform() if odd==1 & sample==1
	bysort buildings_name female (rand): drop if _n==1 & rand!=.
	sort n_order
	qui g rand_1=runiform()
	qui g rand_2=runiform()
	
	qui g simulated_mixrace = . 
	qui g simulated_room = .
	qui bysort buildings_name female (n_order): g base_rank=_n
	sort buildings_name female rand_1 rand_2
	qui by buildings_name female: replace simulated_room=roomnum_base[base_rank]
	
	sort buildings_name female simulated_room (n_order)
	qui replace simulated_mixrace = 1  if Race[_n] != Race[_n+1] & Race[_n] != . & Race[_n+1] != . & buildings_name[_n] == buildings_name[_n+1] & female[_n] == female[_n+1]
	qui replace simulated_mixrace = 0  if Race[_n] == Race[_n+1] & Race[_n] != . & Race[_n+1] != . & buildings_name[_n] == buildings_name[_n+1] & female[_n] == female[_n+1]
	by buildings_name female : replace simulated_mixrace = 0  if Race[_n] == Race[_n-1] & Race[_n] != . & Race[_n-1] != . & buildings_name[_n] == buildings_name[_n-1] & female[_n] == female[_n-1] & _N==_n
	by buildings_name female : replace simulated_mixrace = 1  if Race[_n] != Race[_n-1] & Race[_n] != . & Race[_n-1] != . & buildings_name[_n] == buildings_name[_n-1] & female[_n] == female[_n-1] & _N==_n
	
	merge 1:1 nstudent round using  "$clean/uctdata_balanced.dta", keepusing(white coloured Else Female Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss round DscoreraceIAT DscoreacaIAT  blackRes whiteRes Res_base mixracebas  ) keep(3)
	if `i'==1{
	reg mixracebas    DscoreraceIAT DscoreacaIAT white coloured Else Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss  i.blackRes i.whiteRes i.Res_base
	}
	else{
	reg simulated_mixrace    DscoreraceIAT DscoreacaIAT white coloured Else Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss  i.blackRes i.whiteRes i.Res_base
	}
	

	restore
	
	matrix A[`i',1]=_b[DscoreraceIAT]
	matrix A[`i',2]=_b[DscoreacaIAT]
	matrix A[`i',3]=_b[white]
	matrix A[`i',4]=_b[coloured]
	matrix A[`i',5]=_b[Else]
	matrix A[`i',6]=_b[Falseuct2012]
	matrix A[`i',7]=_b[Foreign]
	matrix A[`i',8]=_b[privateschool_nomiss]
	matrix A[`i',9]=_b[durpcabas_nomiss]
	matrix A[`i',10]=_b[consbas_nomiss]
}
clear
svmat A
}

forval i=1/10{
	qui count if A`i'<A`i'[1] & _n!=1
	di r(N)/`sims'
}

```

### `ForJournals_a/Code/analysis/FWER/10_fwer_tablea15.do`
```stata
 /************************************************************************************************************************************************

Project: Interaction, Sterotypes and Performance: Evidence from South Africa
Corno L., La Ferrara E., Burns J.

do file: 10_fwer_tablea15.do
author: Vrinda Kapoor, 15/04/2019

Datasets used: uctdata_balanced_journals.dta, nstudent.dta

Output: Dropbox\SouthAfrica_clean\Output\FWER

*************************************************************************************************************************************************/

	clear all
	do $additional/fdr_sharpened_qvalues

	local N = 10000
	local full = 1
	local white = 1
	local black = 1



**DEPENDENT VARIABLES

	local dep_tablea15 PCAfriend_nomiss1 PCAatt_nomiss1 PCAcomm_nomiss1  PCAsocial_nomiss1

**************************************************
** Calculating the p-values
**************************************************
*important syntax to know
	*k hypotheses
	*N iterations/bootstraps, later local c

**************************************************
** Table A15 with full sample
**************************************************
local fdr_p ""

use "$clean/uctdata_balanced.dta", clear

xtset individual round
sort individual round


***first creating the coefficient, s.e., and original p-value

*FULL SAMPLE
local controls white coloured Else Female Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss     
*BLACK and WHITE subsamples
local controls_subsample Female Falseuct2012 missfalse Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss      
*Roommate controls
local rocontrols roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas  roprivschool_nomiss roprivschool_miss  rodurpcabas_nomiss rodurpcabas_miss  roconsbas_nomiss roconsbas_miss  


*FULL SAMPLE
local controls_fwer white_fwer coloured_fwer Else_fwer Female Falseuct2012_fwer missfalse_fwer  Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer     
*BLACK and WHITE subsamples
local controls_subsample_fwer Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer      
*Roommate controls
local rocontrols_fwer roForeign_fwer roforeign_missing_fwer roprivateschool_nomiss_fwer roprivateschool_miss_fwer roconsbas_nomiss_fwer roconsbas_miss_fwer rodurpcabas_nomiss_fwer rodurpcabas_miss_fwer roFalseuct2012_fwer romissfalse_fwer


			
local k =1


foreach i in `dep_tablea15' {
	
	
	xi: reg `i'  mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base  if round==2,  robust cluster(roomnum_base)
	
	local beta_`k'_t = _b[mixracebas]
	local se_`k'_t = _se[mixracebas]

	local beta_`k' : di %8.3f `beta_`k'_t'
	local se_`k' : di %8.3f `se_`k'_t'
	
	matrix rtable = r(table)
	local pvalue_`k'_t  = rtable[4,1] 
	local p_`k' :  di %8.3f `pvalue_`k'_t'
	local fdr_p `fdr_p' `p_`k''
	
	local N_`k' =  e(N)
	local k = `k'+1
}

***now we have locals p_1 p_2 p_3 p_4 for four hypotheses

***Pvalues based on 10,000 iterations

if `full'{
	set seed 3005
	keep if round == 2 // because the sample changes between the six hypotheses
	rename nstudent nstudent_fwer
	keep nstudent_fwer Res_base Female Race mixracebas
	g round=1 
	tempfile sample_full
	save `sample_full', replace
 
	g count=1
	collapse (count) count, by(Res_base Female Race mixracebas)
	reshape wide count, i(Res_base Female Race) j(mixracebas)
	tempfile merger
	save `merger', replace

	tempfile bs

forval c=1/`N' {
	
	di "iteration `c'"
	
	qui{
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', keep(3) nogen keepusing(nstudent_fwer)
	merge m:1 Res_base Female Race using `merger', nogen keep(3) keepusing(count?)

	egen count=rowtotal(count0 count1)
	replace count0=0 if count0==.

	* Shuffle individuals into mixed race and same race rooms
	sort nstudent_fwer
	g rand_num=runiform()
	bysort Res_base Female Race (rand_num): g mixracebas=1 if _n>count0
	replace mixracebas=0 if mixracebas==.
	
	* Shuffle room assignment
	sort nstudent_fwer
	g r_5=runiform()
	bysort Res_base Female Race mixracebas (r_5): g merge_room=_n
	drop r_5 rand_num
	tempfile nstudent_1
	save `nstudent_1', replace

	* for roommates
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', nogen keep(1 2) keepusing(nstudent_fwer)
	sort nstudent_fwer
	tempfile nstudent_2
	save `nstudent_2', replace

	use "$clean/uctdata_balanced.dta", clear

	g nstudent_fwer=nstudent
	merge 1:1 round nstudent_fwer using `sample_full', nogen keep(3) keepusing(nstudent_fwer)
	sort nstudent_fwer
	drop nstudent_fwer
	g temp_random = runiform()
	bysort Res_base Female Race mixracebas (temp_random): g merge_room=_n
	drop temp_random

	merge 1:1 Res_base Female Race mixracebas merge_room using `nstudent_1', keepusing( nstudent_fwer Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_nomiss1_fu_fwer PCAatt_nomiss1_fu_fwer PCAcomm_nomiss1_fu_fwer  PCAsocial_nomiss1_fu_fwer) nogen

	g roommate_fwer=.
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[2] if _n==1 & round[2]==1	
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[1] if _n==2 & round==1	

	* generate random sequence for Race draws
	preserve
	clear
	set obs 4
	g n=_n
	g order=runiform()
	sort order
	local order=" "

	forval i=1/4{
		local n=n[`i']
		local order="`order' " + "`n'"
	}
	restore

	levelsof Race, local(Race)
	foreach race in `order'{
	g roommate_match=.	
	keep if round==1
	sort nstudent_fwer
	g rrr=runiform()
	g sep =(((Race==1 & mixracebas==0) | Race!=1 & mixracebas==1) & roommate_fwer==. & round==1)
	sort nstudent_fwer
	bysort Res_base Female (sep rrr): replace roommate_match=_n
	
	sort nstudent_fwer
	drop rrr sep
	preserve
	tempfile race_`race'
	use `nstudent_2', clear
	keep if Race==`race'
	sort nstudent_fwer
	g temp_random = runiform()	
	bysort Res_base Female (temp_random): g roommate_match=_n	
	drop temp_random	
	sort Res_base Female roommate_match
	rename nstudent_fwer roommate_fwer
	save `race_`race'', replace
	restore
	merge 1:1 Res_base Female roommate_match using `race_`race'', update keepusing(roommate_fwer) nogen

	drop roommate_match
	}

	keep if round==1

	keep roommate_fwer nstudent_fwer roomnum_base mixracebas

	merge 1:1 nstudent_fwer using "$clean/nstudents_fwer.dta", keepusing(Race Res_base Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_nomiss1_fu_fwer PCAatt_nomiss1_fu_fwer PCAcomm_nomiss1_fu_fwer  PCAsocial_nomiss1_fu_fwer) nogen keep(3)

	preserve
	tempfile roommate_merge
	use "$clean/nstudents_fwer.dta", clear
	rename nstudent_fwer roommate_fwer
	rename Race roRace
	foreach var of varlist Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer{
		rename `var' ro`var'
	}
	save `roommate_merge',replace
	restore

	merge m:1 roommate_fwer using `roommate_merge', keepusing(ro*) nogen keep(1 3)

	keep roomnum_base Race Female roommate_fwer nstudent_fwer mixracebas Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer ro* Res_base  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_nomiss1_fu_fwer PCAatt_nomiss1_fu_fwer PCAcomm_nomiss1_fu_fwer  PCAsocial_nomiss1_fu_fwer


	local k =1
	 
	foreach var in `dep_tablea15' {
	
	xi: reg `var'_fu_fwer  mixracebas `controls_fwer' `rocontrols_fwer' i.blackRes i.whiteRes i.Res_base,  robust cluster(roomnum_base)

		matrix rtable = r(table)
		local pstar_`k'  = rtable[4,1] 

		local ++k
	}

		local K: word count `dep_tablea15'
		drop _all

		set obs `K'
		gen i = `c'
		gen k = _n

		gen pstar = .
		gen p = . 
		
		forval k = 1/`K' {
					replace pstar = `pstar_`k'' in `k'
					replace p  = `pvalue_`k'_t' in `k' // here i use pvalue because i want all the decimal places
				}
				
				
				if `c'>1 append using "`bs'"
				save "`bs'", replace
				
			
				
}
}


		use "`bs'", clear
		
		gsort i -p k	
		by i: gen qstar = pstar if _n==1
		by i: replace qstar = min(qstar[_n-1],pstar) if _n>1
			
		* Define minimum for single-step p-value
		by i: egen qstar1 = min(pstar)
			

	* Steps 3 and 4. Calculate step-down and single-step Westfall-Young adjusted p-value
		gen counter  = qstar <=p
		gen counter1 = qstar1<=p 
		collapse (sum) counter* `Nstats', by(k) fast
		gen pwyoung  = counter /`N'
		gen pwyoung1 = counter1/`N'
		drop counter*
		
		assert pwyoung<=pwyoung1	
	
	
	* Fill in descriptive information
		gen outcome=""
		gen double coef = .
		gen double stderr = .
		gen double p = .

		forval k = 1/`K' {
			replace outcome = "`k'"   if k==`k'
			replace coef = `beta_`k''              if k==`k'
			replace stderr = `se_`k''          if k==`k'
			replace p  = `pvalue_`k'_t'                   if k==`k' 
		}	
	
	* Step 5. Enforce monotonicity using successive maximization.  Include k in the sort to break ties.
	sort p k
	cap replace pwyoung  = max(pwyoung[_n-1]  ,pwyoung)   if _n>1
	cap replace pwyoung1 = max(pwyoung1[_n-1] ,pwyoung1)  if _n>1
	
	
	
	order k outcome coef stderr p pwyoung pwyoung1
	label var p  "Unadjusted p-value"
	cap label var pwyoung   "Westfall-Young adjusted p-value"
	cap label var pwyoung1 "Westfall-Young adjusted p-value (single-step)"

	forval k = 1/`K' {
	
		su pwyoung if k == `k'
		local p2_`k' = r(mean) 
		local pwyoung_`k': di %8.3f `p2_`k''
		
		su pwyoung1 if k == `k'
		local p3_`k' = r(mean) 
		local pwyoung1_`k': di %8.3f `p3_`k''		
	}

	* FDR
	preserve
		fdr, pvals(`fdr_p')
		forval k = 1/`K' {
		summ bky06_qval if _n==`k'
		local fdr_`k': di %8.3f r(mean)
		}
	restore
	

	cap file close soutput
	file open soutput using "$fwer_tables/tablea15_full_fwer_`N'.tex", write replace
	file write soutput "\begin{tabular}{@{\extracolsep{4pt}}p{6cm}*{5}{>{\centering\arraybackslash}m{2cm}}@{}}   \toprule "  _n
    file write soutput "  & Friendship & Attitudes & Pro-social & Social Behaviour  \\  \midrule "

	file write soutput " Mixracebas & `beta_1' & `beta_2' & `beta_3' & `beta_4'    \\" _n
	file write soutput "  Standard Error & `se_1' & `se_2' & `se_3'  & `se_4'     \\ "_n
	file write soutput " Unadjusted p-value & `p_1' & `p_2' & `p_3' & `p_4'    \\ "_n
	file write soutput " WY adjusted p-value & `pwyoung_1' & `pwyoung_2' & `pwyoung_3' & `pwyoung_4'  \\ "_n
	file write soutput " WY adjusted p-value (single-step) & `pwyoung1_1' & `pwyoung1_2' & `pwyoung1_3' & `pwyoung1_4'   \\ "_n
	file write soutput " FDR (q-value) & `fdr_1' & `fdr_2' & `fdr_3' & `fdr_4'\\ "_n
	file write soutput " Sample size & `N_1' & `N_2' & `N_3' & `N_4'    \\ "_n

	file write soutput "  \hline" _n
	file write soutput "\end{tabular}" _n
	file close soutput	


}

if `white'{
	set seed 3005
**************************************************
** Table a15 with whites only
**************************************************
local fdr_p ""

use "$clean/uctdata_balanced.dta", clear

xtset individual round
sort individual round


***first creating the coefficient, s.e., and original p-value

*FULL SAMPLE
local controls white coloured Else Female Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss     
*BLACK and WHITE subsamples
local controls_subsample Female Falseuct2012 missfalse Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss      
*Roommate controls
local rocontrols roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas  roprivschool_nomiss roprivschool_miss  rodurpcabas_nomiss rodurpcabas_miss  roconsbas_nomiss roconsbas_miss  


*FULL SAMPLE
local controls_fwer white_fwer coloured_fwer Else_fwer Female Falseuct2012_fwer missfalse_fwer  Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer     
*BLACK and WHITE subsamples
local controls_subsample_fwer Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer      
*Roommate controls
local rocontrols_fwer roForeign_fwer roforeign_missing_fwer roprivateschool_nomiss_fwer roprivateschool_miss_fwer roconsbas_nomiss_fwer roconsbas_miss_fwer rodurpcabas_nomiss_fwer rodurpcabas_miss_fwer roFalseuct2012_fwer romissfalse_fwer


			
local k =1


foreach i in `dep_tablea15' {
	
	xi: reg `i'  mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base  if round==2 & white==1,  robust cluster(roomnum_base)
	
	local beta_`k'_t = _b[mixracebas]
	local se_`k'_t = _se[mixracebas]

	local beta_`k' : di %8.3f `beta_`k'_t'
	local se_`k' : di %8.3f `se_`k'_t'
	
	matrix rtable = r(table)
	local pvalue_`k'_t  = rtable[4,1] 
	local p_`k' :  di %8.3f `pvalue_`k'_t'
	local fdr_p `fdr_p' `p_`k''
	
	local N_`k' =  e(N)
	local k = `k'+1
}

***now we have locals p_1 p_2 p_3 p_4 for four hypotheses

***Pvalues based on 10,000 iterations

	keep if round == 2 // because the sample changes between the six hypotheses
	rename nstudent nstudent_fwer
	keep nstudent_fwer Res_base Female Race mixracebas
	g round=1 
	sort nstudent_fwer
	tempfile sample_full
	save `sample_full', replace
 
	g count=1
	collapse (count) count, by(Res_base Female Race mixracebas)
	reshape wide count, i(Res_base Female Race) j(mixracebas)
	tempfile merger
	save `merger', replace

	tempfile bs

forval c=1/`N' {
	
	di "iteration `c'"
	
	qui{
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', keep(3) nogen keepusing(nstudent_fwer)
	merge m:1 Res_base Female Race using `merger', nogen keep(3) keepusing(count?)

	egen count=rowtotal(count0 count1)
	replace count0=0 if count0==.

	* Shuffle individuals into mixed race and same race rooms
	sort nstudent_fwer
	g rand_num=runiform()
	bysort Res_base Female Race (rand_num): g mixracebas=1 if _n>count0
	replace mixracebas=0 if mixracebas==.
	
	* Shuffle room assignment
	sort nstudent_fwer
	g r_5=runiform()
	bysort Res_base Female Race mixracebas (r_5): g merge_room=_n
	drop r_5 rand_num
	tempfile nstudent_1
	save `nstudent_1', replace

	* for roommates
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', nogen keep(1 2) keepusing(nstudent_fwer)
	sort nstudent_fwer
	tempfile nstudent_2
	save `nstudent_2', replace

	use "$clean/uctdata_balanced.dta", clear

	g nstudent_fwer=nstudent
	merge 1:1 round nstudent_fwer using `sample_full', nogen keep(3) keepusing(nstudent_fwer)
	sort nstudent_fwer
	drop nstudent_fwer
	g temp_random = runiform()
	bysort Res_base Female Race mixracebas (temp_random): g merge_room=_n
	drop temp_random

	merge 1:1 Res_base Female Race mixracebas merge_room using `nstudent_1', keepusing( nstudent_fwer Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_nomiss1_fu_fwer PCAatt_nomiss1_fu_fwer PCAcomm_nomiss1_fu_fwer  PCAsocial_nomiss1_fu_fwer) nogen

	g roommate_fwer=.
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[2] if _n==1 & round[2]==1	
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[1] if _n==2 & round==1	
	

	* generate random sequence for Race draws
	preserve
	clear
	set obs 4
	g n=_n
	g order=runiform()
	sort order
	local order=" "

	forval i=1/4{
		local n=n[`i']
		local order="`order' " + "`n'"
	}
	restore

	levelsof Race, local(Race)
	foreach race in `order'{
		
			
	g roommate_match=.	
	keep if round==1
	sort nstudent_fwer
	g rrr=runiform()
	g sep =(((Race==1 & mixracebas==0) | Race!=1 & mixracebas==1) & roommate_fwer==. & round==1)
	sort nstudent_fwer
	bysort Res_base Female (sep rrr): replace roommate_match=_n
	
	sort nstudent_fwer
	drop rrr sep
	preserve
	tempfile race_`race'
	use `nstudent_2', clear
	keep if Race==`race'
	sort nstudent_fwer
	g temp_random = runiform()	
	bysort Res_base Female (temp_random): g roommate_match=_n	
	drop temp_random	
	sort Res_base Female roommate_match
	
	rename nstudent_fwer roommate_fwer
	save `race_`race'', replace
	restore
	merge 1:1 Res_base Female roommate_match using `race_`race'', update keepusing(roommate_fwer) nogen
	
	drop roommate_match
	}

	keep if round==1

	keep roommate_fwer nstudent_fwer roomnum_base mixracebas

	merge 1:1 nstudent_fwer using "$clean/nstudents_fwer.dta", keepusing(Race Res_base Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_nomiss1_fu_fwer PCAatt_nomiss1_fu_fwer PCAcomm_nomiss1_fu_fwer  PCAsocial_nomiss1_fu_fwer) nogen keep(3)

	preserve
	tempfile roommate_merge
	use "$clean/nstudents_fwer.dta", clear
	rename nstudent_fwer roommate_fwer
	rename Race roRace
	foreach var of varlist Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer{
		rename `var' ro`var'
	}
	save `roommate_merge',replace
	restore

	merge m:1 roommate_fwer using `roommate_merge', keepusing(ro*) nogen keep(1 3)

	keep roomnum_base Race Female roommate_fwer nstudent_fwer mixracebas Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer ro* Res_base  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_nomiss1_fu_fwer PCAatt_nomiss1_fu_fwer PCAcomm_nomiss1_fu_fwer  PCAsocial_nomiss1_fu_fwer


	local k =1
	 
	foreach var in `dep_tablea15' {
	
	xi: reg `var'_fu_fwer  mixracebas `controls_fwer' `rocontrols_fwer' i.blackRes i.whiteRes i.Res_base if white_fwer==1,  robust cluster(roomnum_base)

		matrix rtable = r(table)
		local pstar_`k'  = rtable[4,1] 

		local ++k
	}

		local K: word count `dep_tablea15'
		drop _all

		set obs `K'
		gen i = `c'
		gen k = _n

		gen pstar = .
		gen p = . 
		
		forval k = 1/`K' {
					replace pstar = `pstar_`k'' in `k'
					replace p  = `pvalue_`k'_t' in `k' // here i use pvalue because i want all the decimal places
				}
				
				
				if `c'>1 append using "`bs'"
				save "`bs'", replace
				
				
}
}


		use "`bs'", clear
		
		gsort i -p k	
		by i: gen qstar = pstar if _n==1
		by i: replace qstar = min(qstar[_n-1],pstar) if _n>1
			
		* Define minimum for single-step p-value
		by i: egen qstar1 = min(pstar)
			

	* Steps 3 and 4. Calculate step-down and single-step Westfall-Young adjusted p-value
		gen counter  = qstar <=p
		gen counter1 = qstar1<=p 
		collapse (sum) counter* `Nstats', by(k) fast
		gen pwyoung  = counter /`N'
		gen pwyoung1 = counter1/`N'
		drop counter*
		
		assert pwyoung<=pwyoung1	
	
	
	* Fill in descriptive information
		gen outcome=""
		gen double coef = .
		gen double stderr = .
		gen double p = .

		forval k = 1/`K' {
			replace outcome = "`k'"   if k==`k'
			replace coef = `beta_`k''              if k==`k'
			replace stderr = `se_`k''          if k==`k'
			replace p  = `pvalue_`k'_t'                   if k==`k' 
		}	
	
	* Step 5. Enforce monotonicity using successive maximization.  Include k in the sort to break ties.
	sort p k
	cap replace pwyoung  = max(pwyoung[_n-1]  ,pwyoung)   if _n>1
	cap replace pwyoung1 = max(pwyoung1[_n-1] ,pwyoung1)  if _n>1
	
	
	
	order k outcome coef stderr p pwyoung pwyoung1
	label var p  "Unadjusted p-value"
	cap label var pwyoung   "Westfall-Young adjusted p-value"
	cap label var pwyoung1 "Westfall-Young adjusted p-value (single-step)"

	forval k = 1/`K' {
	
		su pwyoung if k == `k'
		local p2_`k' = r(mean) 
		local pwyoung_`k': di %8.3f `p2_`k''
		
		su pwyoung1 if k == `k'
		local p3_`k' = r(mean) 
		local pwyoung1_`k': di %8.3f `p3_`k''		
	}

	* FDR
	preserve
		fdr, pvals(`fdr_p')
		forval k = 1/`K' {
		summ bky06_qval if _n==`k'
		local fdr_`k': di %8.3f r(mean)
		}
	restore
	

	cap file close soutput
	file open soutput using "$fwer_tables/tablea15_white_fwer_`N'.tex", write replace
	file write soutput "\begin{tabular}{@{\extracolsep{4pt}}p{6cm}*{5}{>{\centering\arraybackslash}m{2cm}}@{}}   \toprule "  _n
    file write soutput "  & Friendship & Attitudes & Pro-social & Social Behaviour  \\  \midrule "

	file write soutput " Mixracebas & `beta_1' & `beta_2' & `beta_3' & `beta_4'    \\" _n
	file write soutput "  Standard Error & `se_1' & `se_2' & `se_3'  & `se_4'     \\ "_n
	file write soutput " Unadjusted p-value & `p_1' & `p_2' & `p_3' & `p_4'    \\ "_n
	file write soutput " WY adjusted p-value & `pwyoung_1' & `pwyoung_2' & `pwyoung_3' & `pwyoung_4'  \\ "_n
	file write soutput " WY adjusted p-value (single-step) & `pwyoung1_1' & `pwyoung1_2' & `pwyoung1_3' & `pwyoung1_4'   \\ "_n
	file write soutput " FDR (q-value) & `fdr_1' & `fdr_2' & `fdr_3' & `fdr_4'\\ "_n
	file write soutput " Sample size & `N_1' & `N_2' & `N_3' & `N_4'    \\ "_n

	file write soutput "  \hline" _n
	file write soutput "\end{tabular}" _n
	file close soutput	


}

if `black'{
	set seed 3005
**************************************************
** Table a15 with black only
**************************************************
local fdr_p ""

use "$clean/uctdata_balanced.dta", clear

xtset individual round
sort individual round


***first creating the coefficient, s.e., and original p-value

*FULL SAMPLE
local controls white coloured Else Female Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss     
*BLACK and WHITE subsamples
local controls_subsample Female Falseuct2012 missfalse Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss      
*Roommate controls
local rocontrols roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas  roprivschool_nomiss roprivschool_miss  rodurpcabas_nomiss rodurpcabas_miss  roconsbas_nomiss roconsbas_miss  


*FULL SAMPLE
local controls_fwer white_fwer coloured_fwer Else_fwer Female Falseuct2012_fwer missfalse_fwer  Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer     
*BLACK and WHITE subsamples
local controls_subsample_fwer Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer      
*Roommate controls
local rocontrols_fwer roForeign_fwer roforeign_missing_fwer roprivateschool_nomiss_fwer roprivateschool_miss_fwer roconsbas_nomiss_fwer roconsbas_miss_fwer rodurpcabas_nomiss_fwer rodurpcabas_miss_fwer roFalseuct2012_fwer romissfalse_fwer


			
local k =1


foreach i in `dep_tablea15' {
	
	xi: reg `i'  mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base  if round==2 & black==1,  robust cluster(roomnum_base)
	
	local beta_`k'_t = _b[mixracebas]
	local se_`k'_t = _se[mixracebas]

	local beta_`k' : di %8.3f `beta_`k'_t'
	local se_`k' : di %8.3f `se_`k'_t'
	
	matrix rtable = r(table)
	local pvalue_`k'_t  = rtable[4,1] 
	local p_`k' :  di %8.3f `pvalue_`k'_t'
	local fdr_p `fdr_p' `p_`k''
	
	local N_`k' =  e(N)
	local k = `k'+1
}

***now we have locals p_1 p_2 p_3 p_4 for four hypotheses

***Pvalues based on 10,000 iterations

	keep if round == 2 // because the sample changes between the six hypotheses
	rename nstudent nstudent_fwer
	keep nstudent_fwer Res_base Female Race mixracebas
	g round=1 
	sort nstudent_fwer
	tempfile sample_full
	save `sample_full', replace
 
	g count=1
	collapse (count) count, by(Res_base Female Race mixracebas)
	reshape wide count, i(Res_base Female Race) j(mixracebas)
	tempfile merger
	save `merger', replace

	tempfile bs

forval c=1/`N' {
	
	di "iteration `c'"
	
	qui{
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', keep(3) nogen keepusing(nstudent_fwer)
	merge m:1 Res_base Female Race using `merger', nogen keep(3) keepusing(count?)
	
	egen count=rowtotal(count0 count1)
	replace count0=0 if count0==.

	* Shuffle individuals into mixed race and same race rooms
	sort nstudent_fwer
	g rand_num=runiform()
	bysort Res_base Female Race (rand_num): g mixracebas=1 if _n>count0
	replace mixracebas=0 if mixracebas==.
	
	* Shuffle room assignment
	sort nstudent_fwer
	g r_5=runiform()
	bysort Res_base Female Race mixracebas (r_5): g merge_room=_n
	drop r_5 rand_num
	tempfile nstudent_1
	save `nstudent_1', replace

	* for roommates
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', nogen keep(1 2) keepusing(nstudent_fwer)
	tempfile nstudent_2
	save `nstudent_2', replace

	use "$clean/uctdata_balanced.dta", clear

	g nstudent_fwer=nstudent
	merge 1:1 round nstudent_fwer using `sample_full', nogen keep(3) keepusing(nstudent_fwer)
	sort nstudent_fwer
	drop nstudent_fwer
	g temp_random=runiform()
	bysort Res_base Female Race mixracebas (temp_random): g merge_room=_n
	drop temp_random

	merge 1:1 Res_base Female Race mixracebas merge_room using `nstudent_1', keepusing( nstudent_fwer Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_nomiss1_fu_fwer PCAatt_nomiss1_fu_fwer PCAcomm_nomiss1_fu_fwer  PCAsocial_nomiss1_fu_fwer) nogen

	g roommate_fwer=.
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[2] if _n==1 & round[2]==1
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[1] if _n==2 & round==1

	* generate random sequence for Race draws
	preserve
	clear
	set obs 4
	g n=_n
	g order=runiform()
	sort order
	local order=" "

	forval i=1/4{
		local n=n[`i']
		local order="`order' " + "`n'"
	}
	restore

	levelsof Race, local(Race)
	foreach race in `order'{
	g roommate_match=.	
	keep if round==1
	sort nstudent_fwer
	g rrr=runiform()
	g sep =(((Race==1 & mixracebas==0) | Race!=1 & mixracebas==1) & roommate_fwer==. & round==1)
	sort nstudent_fwer
	bysort Res_base Female (sep rrr): replace roommate_match=_n
	
	sort nstudent_fwer
	drop rrr sep
	preserve
	tempfile race_`race'
	use `nstudent_2', clear
	keep if Race==`race'
	sort nstudent_fwer
	g temp_random = runiform()	
	bysort Res_base Female (temp_random): g roommate_match=_n	
	drop temp_random	
	sort Res_base Female roommate_match
	
	rename nstudent_fwer roommate_fwer
	save `race_`race'', replace
	restore
	merge 1:1 Res_base Female roommate_match using `race_`race'', update keepusing(roommate_fwer) nogen
	
	drop roommate_match
	}

	keep if round==1

	keep roommate_fwer nstudent_fwer roomnum_base mixracebas

	merge 1:1 nstudent_fwer using "$clean/nstudents_fwer.dta", keepusing(Race Res_base Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_nomiss1_fu_fwer PCAatt_nomiss1_fu_fwer PCAcomm_nomiss1_fu_fwer  PCAsocial_nomiss1_fu_fwer) nogen keep(3)

	preserve
	tempfile roommate_merge
	use "$clean/nstudents_fwer.dta", clear
	rename nstudent_fwer roommate_fwer
	rename Race roRace
	foreach var of varlist Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer{
		rename `var' ro`var'
	}
	save `roommate_merge',replace
	restore

	merge m:1 roommate_fwer using `roommate_merge', keepusing(ro*) nogen keep(1 3)

	keep roomnum_base Race Female roommate_fwer nstudent_fwer mixracebas Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer ro* Res_base  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_nomiss1_fu_fwer PCAatt_nomiss1_fu_fwer PCAcomm_nomiss1_fu_fwer  PCAsocial_nomiss1_fu_fwer


	local k =1
	 
	foreach var in `dep_tablea15' {
	
	xi: reg `var'_fu_fwer  mixracebas `controls_fwer' `rocontrols_fwer' i.blackRes i.whiteRes i.Res_base if black_fwer==1,  robust cluster(roomnum_base)

		matrix rtable = r(table)
		local pstar_`k'  = rtable[4,1] 

		local ++k
	}

		local K: word count `dep_tablea15'
		drop _all

		set obs `K'
		gen i = `c'
		gen k = _n

		gen pstar = .
		gen p = . 
		
		forval k = 1/`K' {
					replace pstar = `pstar_`k'' in `k'
					replace p  = `pvalue_`k'_t' in `k' // here i use pvalue because i want all the decimal places
				}
				
				
				if `c'>1 append using "`bs'"
				save "`bs'", replace
				
				
}
}


		use "`bs'", clear
		
		gsort i -p k	
		by i: gen qstar = pstar if _n==1
		by i: replace qstar = min(qstar[_n-1],pstar) if _n>1
			
		* Define minimum for single-step p-value
		by i: egen qstar1 = min(pstar)
			

	* Steps 3 and 4. Calculate step-down and single-step Westfall-Young adjusted p-value
		gen counter  = qstar <=p
		gen counter1 = qstar1<=p 
		collapse (sum) counter* `Nstats', by(k) fast
		gen pwyoung  = counter /`N'
		gen pwyoung1 = counter1/`N'
		drop counter*
		
		assert pwyoung<=pwyoung1	
	
	
	* Fill in descriptive information
		gen outcome=""
		gen double coef = .
		gen double stderr = .
		gen double p = .

		forval k = 1/`K' {
			replace outcome = "`k'"   if k==`k'
			replace coef = `beta_`k''              if k==`k'
			replace stderr = `se_`k''          if k==`k'
			replace p  = `pvalue_`k'_t'                   if k==`k' 
		}	
	
	* Step 5. Enforce monotonicity using successive maximization.  Include k in the sort to break ties.
	sort p k
	cap replace pwyoung  = max(pwyoung[_n-1]  ,pwyoung)   if _n>1
	cap replace pwyoung1 = max(pwyoung1[_n-1] ,pwyoung1)  if _n>1
	
	
	
	order k outcome coef stderr p pwyoung pwyoung1
	label var p  "Unadjusted p-value"
	cap label var pwyoung   "Westfall-Young adjusted p-value"
	cap label var pwyoung1 "Westfall-Young adjusted p-value (single-step)"

	forval k = 1/`K' {
	
		su pwyoung if k == `k'
		local p2_`k' = r(mean) 
		local pwyoung_`k': di %8.3f `p2_`k''
		
		su pwyoung1 if k == `k'
		local p3_`k' = r(mean) 
		local pwyoung1_`k': di %8.3f `p3_`k''		
	}

	* FDR
	preserve
		fdr, pvals(`fdr_p')
		forval k = 1/`K' {
		summ bky06_qval if _n==`k'
		local fdr_`k': di %8.3f r(mean)
		}
	restore
	

	cap file close soutput
	file open soutput using "$fwer_tables/tablea15_black_fwer_`N'.tex", write replace
	file write soutput "\begin{tabular}{@{\extracolsep{4pt}}p{6cm}*{5}{>{\centering\arraybackslash}m{2cm}}@{}}   \toprule "  _n
    file write soutput "  & Friendship & Attitudes & Pro-social & Social Behaviour  \\  \midrule "

	file write soutput " Mixracebas & `beta_1' & `beta_2' & `beta_3' & `beta_4'    \\" _n
	file write soutput "  Standard Error & `se_1' & `se_2' & `se_3'  & `se_4'     \\ "_n
	file write soutput " Unadjusted p-value & `p_1' & `p_2' & `p_3' & `p_4'    \\ "_n
	file write soutput " WY adjusted p-value & `pwyoung_1' & `pwyoung_2' & `pwyoung_3' & `pwyoung_4'  \\ "_n
	file write soutput " WY adjusted p-value (single-step) & `pwyoung1_1' & `pwyoung1_2' & `pwyoung1_3' & `pwyoung1_4'   \\ "_n
	file write soutput " FDR (q-value) & `fdr_1' & `fdr_2' & `fdr_3' & `fdr_4'\\ "_n
	file write soutput " Sample size & `N_1' & `N_2' & `N_3' & `N_4'    \\ "_n

	file write soutput "  \hline" _n
	file write soutput "\end{tabular}" _n
	file close soutput	


}








exit 

```

### `ForJournals_a/Code/analysis/FWER/2_fwer_table3.do`
```stata
 /************************************************************************************************************************************************

Project: Interaction, Sterotypes and Performance: Evidence from South Africa
Corno L., La Ferrara E., Burns J.

do file: 2_fwer_table3.do
author: Vrinda Kapoor, 15/04/2019

Datasets used: uctdata_balanced.dta, nstudent.dta

Output: Dropbox\SouthAfrica_clean\Output\FWER

*************************************************************************************************************************************************/

	clear all
* Code for FDR adapted from Anderson
	do $additional/fdr_sharpened_qvalues

	local N = 10000
	local full = 0
	local white = 0
	local black =1

**************************************************
** Calculating the p-values
**************************************************
*important syntax to know
	*k hypotheses
	*N iterations/bootstraps, later local c

**************************************************
** Table 3 with full sample
**************************************************2
local fdr_p ""

use "$clean/uctdata_balanced.dta", clear

**DEPENDENT VARIABLES

local dep_table3 DscoreraceIAT DscoreacaIAT

***first creating the coefficient, s.e., and original p-value

*FULL SAMPLE
local controls white coloured Else Female Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss     
*BLACK and WHITE subsamples
local controls_subsample Female Falseuct2012 missfalse Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss      
*Roommate controls
local rocontrols roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas  roprivschool_nomiss roprivschool_miss  rodurpcabas_nomiss rodurpcabas_miss  roconsbas_nomiss roconsbas_miss  

*FULL SAMPLE
local controls_fwer white_fwer coloured_fwer Else_fwer Female Falseuct2012_fwer missfalse_fwer  Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer     
*BLACK and WHITE subsamples
local controls_subsample_fwer Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer      
*Roommate controls
local rocontrols_fwer roForeign_fwer roforeign_missing_fwer roprivateschool_nomiss_fwer roprivateschool_miss_fwer roconsbas_nomiss_fwer roconsbas_miss_fwer rodurpcabas_nomiss_fwer rodurpcabas_miss_fwer roFalseuct2012_fwer romissfalse_fwer
		
local k =1
xtset 

if `full'{
	set seed 3005

foreach i in `dep_table3' {
	
	*Full sample
	xi: reg `i' mixracebas L.`i' `controls' `rocontrols'  i.blackRes i.whiteRes i.Res_base  if round==2,  robust cluster(roomnum_base)
	
	local beta_`k'_t = _b[mixracebas]
	local se_`k'_t = _se[mixracebas]

	local beta_`k' : di %8.3f `beta_`k'_t'
	local se_`k' : di %8.3f `se_`k'_t'
	
	matrix rtable = r(table)
	local pvalue_`k'_t  = rtable[4,1] 
	local p_`k' :  di %8.3f `pvalue_`k'_t'
	local fdr_p `fdr_p' `p_`k''

	local N_`k' =  e(N)
	local k = `k'+1
}

***now we have locals p_1 p_2 p_3 for three hypotheses

***Pvalues based on 10,000 iterations

	qui xi:  reg DscoreraceIAT mixracebas L.`i' `controls' `rocontrols'  i.blackRes i.whiteRes i.Res_base  if round==2,  robust cluster(roomnum_base)
	keep if e(sample) 
	
	rename nstudent nstudent_fwer
	keep nstudent_fwer Res_base Female Race mixracebas
	g round=1 
	sort nstudent_fwer 
	tempfile sample_full
	save `sample_full', replace
 
	g count=1
	collapse (count) count, by(Res_base Female Race mixracebas)
	reshape wide count, i(Res_base Female Race) j(mixracebas)
	tempfile merger
	save `merger', replace

	
	tempfile bs

forval c=1/`N'{
	
	di "iteration `c'"
qui{
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', keep(3) nogen keepusing(nstudent_fwer)
	merge m:1 Res_base Female Race using `merger', nogen keep(3) keepusing(count?)

	egen count=rowtotal(count0 count1)
	replace count0=0 if count0==.

	* Shuffle individuals into mixed race and same race rooms
	sort nstudent_fwer 
	g rand_num=runiform()
	sort Res_base Female Race rand_num
	by Res_base Female Race: g mixracebas=1 if _n>count0
	replace mixracebas=0 if mixracebas==.

	* Shuffle room assignment
	sort nstudent_fwer 
	g r_5=runiform()
	sort Res_base Female Race mixracebas r_5
	by Res_base Female Race mixracebas: g merge_room=_n
	drop r_5 rand_num
	tempfile nstudent_1
	save `nstudent_1', replace

	* for roommates
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', nogen keep(1 2) keepusing(nstudent_fwer)
	sort nstudent_fwer
	tempfile nstudent_2
	save `nstudent_2', replace

	use "$clean/uctdata_balanced.dta", clear

	g nstudent_fwer=nstudent
	merge 1:1 round nstudent_fwer using `sample_full', nogen keep(3) keepusing(nstudent_fwer)
	sort nstudent_fwer
	drop nstudent_fwer
	g temp_random = runiform()	
	bysort Res_base Female Race mixracebas (temp_random): g merge_room=_n	
	drop temp_random

	merge 1:1 Res_base Female Race mixracebas merge_room using `nstudent_1', keepusing( nstudent_fwer Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer  durpcabas_nomiss_fwer durpcabas_miss_fwer whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer DscoreacaIAT_fwer DscoreacaIAT_fu_fwer DscoreraceIAT_fwer DscoreraceIAT_fu_fwer) nogen

	g roommate_fwer=.
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[2] if _n==1 & round[2]==1	
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[1] if _n==2 & round==1	

	

	* generate random sequence for Race draws
	preserve
	clear
	set obs 4
	g n=_n
	g order=runiform()
	sort order
	local order=" "

	forval i=1/4{
		local n=n[`i']
		local order="`order' " + "`n'"
	}
	restore

	levelsof Race, local(Race)
	foreach race in `order'{
		 
	g roommate_match=.	
	keep if round==1
	sort nstudent_fwer
	g rrr=runiform()
	g sep =(((Race==1 & mixracebas==0) | Race!=1 & mixracebas==1) & roommate_fwer==. & round==1)
	sort nstudent_fwer
	bysort Res_base Female (sep rrr): replace roommate_match=_n
	
	sort nstudent_fwer
	drop rrr sep

	preserve
	tempfile race_`race'
	use `nstudent_2', clear
	keep if Race==`race'
	sort nstudent_fwer
	g temp_random = runiform()	
	bysort Res_base Female (temp_random): g roommate_match=_n	
	drop temp_random	
	sort Res_base Female roommate_match

	rename nstudent_fwer roommate_fwer

	save `race_`race'', replace
	restore

	merge 1:1 Res_base Female roommate_match using `race_`race'', update keepusing(roommate_fwer) nogen
	drop roommate_match
	erase `race_`race''
	}

	keep if round==1

	keep roommate_fwer nstudent_fwer roomnum_base mixracebas

	merge 1:1 nstudent_fwer using "$clean/nstudents_fwer.dta", keepusing(Race Res_base Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer  durpcabas_nomiss_fwer durpcabas_miss_fwer  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer DscoreacaIAT_fwer DscoreraceIAT_fwer DscoreraceIAT_fu_fwer DscoreacaIAT_fu_fwer) nogen keep(3)

	preserve
	tempfile roommate_merge
	use "$clean/nstudents_fwer.dta", clear
	rename nstudent_fwer roommate_fwer
	rename Race roRace
	foreach var of varlist Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer  durpcabas_nomiss_fwer durpcabas_miss_fwer{
		rename `var' ro`var'
	}
	save `roommate_merge',replace
	restore

	merge m:1 roommate_fwer using `roommate_merge', keepusing(ro*) nogen keep(1 3)

	keep roomnum_base Race Female roommate_fwer nstudent_fwer mixracebas Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer  durpcabas_nomiss_fwer durpcabas_miss_fwer ro* Res_base  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer DscoreacaIAT_fwer DscoreraceIAT_fwer DscoreraceIAT_fu_fwer DscoreacaIAT_fu_fwer



	local k =1

	foreach var in `dep_table3' {
		
		*Full sample
		xi: reg `var'_fu_fwer  mixracebas `var'_fwer `controls_fwer' `rocontrols_fwer'  i.blackRes i.whiteRes i.Res_base, robust cluster(roomnum_base)
		
		matrix rtable = r(table)
		local pstar_`k'  = rtable[4,1] 

		local ++k
	}
	

		local K: word count `dep_table3'
		drop _all

		set obs `K'
		gen i = `c'
		gen k = _n

		gen pstar = .
		gen p = . 
		
		forval k = 1/`K' {
					replace pstar = `pstar_`k'' in `k'
					replace p  = `pvalue_`k'_t' in `k' // here i use pvalue because i want all the decimal places
				}
				
				
				if `c'>1 append using "`bs'"
				save "`bs'", replace
				
erase `nstudent_1'		
erase `nstudent_2'	
				
}
}


		use "`bs'", clear
		
		gsort i -p k	
		by i: gen qstar = pstar if _n==1
		by i: replace qstar = min(qstar[_n-1],pstar) if _n>1
			
		* Define minimum for single-step p-value
		by i: egen qstar1 = min(pstar)
			

	* Steps 3 and 4. Calculate step-down and single-step Westfall-Young adjusted p-value
		gen counter  = qstar <=p
		gen counter1 = qstar1<=p 
		collapse (sum) counter* `Nstats', by(k) fast
		gen pwyoung  = counter /`N'
		gen pwyoung1 = counter1/`N'
		drop counter*
		
		assert pwyoung<=pwyoung1	
	
	
	* Fill in descriptive information
		gen outcome=""
		gen double coef = .
		gen double stderr = .
		gen double p = .

		forval k = 1/`K' {
			replace outcome = "`k'"   if k==`k'
			replace coef = `beta_`k''              if k==`k'
			replace stderr = `se_`k''          if k==`k'
			replace p  = `pvalue_`k'_t'                   if k==`k' 
		}	
	
	* Step 5. Enforce monotonicity using successive maximization.  Include k in the sort to break ties.
	sort p k
	cap replace pwyoung  = max(pwyoung[_n-1]  ,pwyoung)   if _n>1
	cap replace pwyoung1 = max(pwyoung1[_n-1] ,pwyoung1)  if _n>1
	
	
	
	order k outcome coef stderr p pwyoung pwyoung1
	label var p  "Unadjusted p-value"
	cap label var pwyoung   "Westfall-Young adjusted p-value"
	cap label var pwyoung1 "Westfall-Young adjusted p-value (single-step)"

	forval k = 1/`K' {
	
		su pwyoung if k == `k'
		local p2_`k' = r(mean) 
		local pwyoung_`k': di %8.3f `p2_`k''
		
		su pwyoung1 if k == `k'
		local p3_`k' = r(mean) 
		local pwyoung1_`k': di %8.3f `p3_`k''		
	}
	
	* FDR
	di "`fdr_p'"
	preserve
		fdr, pvals(`fdr_p')
		forval k = 1/`K' {
		summ bky06_qval if _n==`k'
		local fdr_`k': di %8.3f r(mean)
		}
	restore
	
	cap file close soutput
	file open soutput using "$fwer_tables/table3_full_fwer_`N'.tex", write replace
	file write soutput "\begin{tabular}{@{\extracolsep{4pt}}p{6cm}*{3}{>{\centering\arraybackslash}m{2cm}}@{}}   \toprule "  _n
    file write soutput "  & Race IAT & Population IAT   \\  \midrule "

	file write soutput " Mixracebas & `beta_1' & `beta_2'  \\" _n
	file write soutput "  Standard Error & `se_1' & `se_2'   \\ "_n
	file write soutput " Unadjusted p-value & `p_1' & `p_2'   \\ "_n
	file write soutput " WY adjusted p-value & `pwyoung_1' & `pwyoung_2' \\ "_n
	file write soutput " WY adjusted p-value (single-step) & `pwyoung1_1' & `pwyoung1_2'  \\ "_n
	file write soutput " FDR (q-value) & `fdr_1' & `fdr_2'  \\ "_n
	file write soutput " Sample size & `N_1' & `N_2'  \\ "_n

	file write soutput "  \hline" _n
	file write soutput "\end{tabular}" _n
	file close soutput	

}
if `white'{	
set seed 3005
**************************************************
** Table 3 with whites only
**************************************************
local fdr_p ""


use "$clean/uctdata_balanced.dta", clear
local fdr_p ""

xtset
	local dep_table3 DscoreraceIAT DscoreacaIAT

***first creating the coefficient, s.e., and original p-value

*FULL SAMPLE
local controls whi col Else Female Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss     
*BLACK and WHITE subsamples
local controls_subsample Female Falseuct2012 missfalse Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss      
*Roommate controls
local rocontrols roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas  roprivschool_nomiss roprivschool_miss  rodurpcabas_nomiss rodurpcabas_miss  roconsbas_nomiss roconsbas_miss  


*FULL SAMPLE
local controls_fwer white_fwer coloured_fwer Else_fwer Female Falseuct2012_fwer missfalse_fwer  Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer     
*BLACK and WHITE subsamples
local controls_subsample_fwer Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer      
*Roommate controls
local rocontrols_fwer roForeign_fwer roforeign_missing_fwer roprivateschool_nomiss_fwer roprivateschool_miss_fwer roconsbas_nomiss_fwer roconsbas_miss_fwer rodurpcabas_nomiss_fwer rodurpcabas_miss_fwer roFalseuct2012_fwer romissfalse_fwer


			
local k =1

foreach i in `dep_table3' {
	
	*Full sample
	xi: reg `i' mixracebas L.`i' `controls_subsample' `rocontrols' i.Res_base  if round==2 &white==1,  robust cluster(roomnum_base)
	
	local beta_`k'_t = _b[mixracebas]
	local se_`k'_t = _se[mixracebas]

	local beta_`k' : di %8.3f `beta_`k'_t'
	local se_`k' : di %8.3f `se_`k'_t'
	
	matrix rtable = r(table)
	local pvalue_`k'_t  = rtable[4,1] 
	local p_`k' :  di %8.3f `pvalue_`k'_t'
	local fdr_p `fdr_p' `p_`k''


	local N_`k' =  e(N)
	local k = `k'+1
}

***now we have locals p_1 p_2 p_3 for three hypotheses

***Pvalues based on 10,000 iterations

	qui xi: reg DscoreacaIAT mixracebas L.DscoreacaIAT `controls_subsample' `rocontrols' i.Res_base  if round==2 &white==1,  robust cluster(roomnum_base) // running again, to get e(sample)
	keep if e(sample) 
	
	rename nstudent nstudent_fwer
	keep nstudent_fwer Res_base Female Race mixracebas
	g round=1 
	sort nstudent_fwer 
	tempfile sample_full
	save `sample_full', replace
 
	g count=1
	collapse (count) count, by(Res_base Female Race mixracebas)
	reshape wide count, i(Res_base Female Race) j(mixracebas)
	tempfile merger
	save `merger', replace

	
	tempfile bs

forval c=1/`N' {
	
	di "iteration `c'"
	
	qui{
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', keep(3) nogen keepusing(nstudent_fwer)
	merge m:1 Res_base Female Race using `merger', nogen keep(3) keepusing(count?)

	egen count=rowtotal(count0 count1)
	replace count0=0 if count0==.

	* Shuffle individuals into mixed race and same race rooms
	sort nstudent_fwer
	g rand_num=runiform()
	sort Res_base Female Race rand_num
	by Res_base Female Race: g mixracebas=1 if _n>count0
	replace mixracebas=0 if mixracebas==.

	* Shuffle room assignment
	sort nstudent_fwer 
	g r_5=runiform()
sort Res_base Female Race mixracebas r_5
	by Res_base Female Race mixracebas: g merge_room=_n
	drop r_5 rand_num
	tempfile nstudent_1
	save `nstudent_1', replace

	* for roommates
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', nogen keep(1 2) keepusing(nstudent_fwer)
	sort nstudent_fwer
	tempfile nstudent_2
	save `nstudent_2', replace

	use "$clean/uctdata_balanced.dta", clear

	g nstudent_fwer=nstudent
	merge 1:1 round nstudent_fwer using `sample_full', nogen keep(3) keepusing(nstudent_fwer)
	sort nstudent_fwer
	drop nstudent_fwer
	g temp_random = runiform()	
	bysort Res_base Female Race mixracebas (temp_random): g merge_room=_n	
	drop temp_random

	merge 1:1 Res_base Female Race mixracebas merge_room using `nstudent_1', keepusing( nstudent_fwer Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer  durpcabas_nomiss_fwer durpcabas_miss_fwer whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer DscoreacaIAT_fwer DscoreacaIAT_fu_fwer DscoreraceIAT_fwer DscoreraceIAT_fu_fwer) nogen
	
	g roommate_fwer=.
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[2] if _n==1 & round[2]==1	
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[1] if _n==2 & round==1	

	

	* generate random sequence for Race draws
	preserve
	clear
	set obs 4
	g n=_n
	g order=runiform()
	sort order
	local order=" "

	forval i=1/4{
		local n=n[`i']
		local order="`order' " + "`n'"
	}
	restore

	levelsof Race, local(Race)
	foreach race in `order'{
		
	g roommate_match=.
	keep if round==1
	sort nstudent_fwer
	g rrr=runiform()
		di "here"
	g sep =(((Race==1 & mixracebas==0) | Race!=1 & mixracebas==1) & roommate_fwer==. & round==1)
	sort nstudent_fwer
	bysort Res_base Female (sep rrr): replace roommate_match=_n
	
	sort nstudent_fwer
	drop rrr sep

	preserve
	tempfile race_`race'
	use `nstudent_2', clear
	keep if Race==`race'
	sort nstudent_fwer
	g temp_random = runiform()	
	bysort Res_base Female (temp_random): g roommate_match=_n	
	drop temp_random	
	sort Res_base Female roommate_match
	rename nstudent_fwer roommate_fwer

	save `race_`race'', replace
	restore

	merge 1:1 Res_base Female roommate_match using `race_`race'', update keepusing(roommate_fwer) nogen
	drop roommate_match
	}

	keep if round==1

	keep roommate_fwer nstudent_fwer roomnum_base mixracebas

	merge 1:1 nstudent_fwer using "$clean/nstudents_fwer.dta", keepusing(Race Res_base Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer  durpcabas_nomiss_fwer durpcabas_miss_fwer  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer DscoreacaIAT_fwer DscoreraceIAT_fwer DscoreraceIAT_fu_fwer DscoreacaIAT_fu_fwer) nogen keep(3)

	preserve
	tempfile roommate_merge
	use "$clean/nstudents_fwer.dta", clear
	rename nstudent_fwer roommate_fwer
	rename Race roRace
	foreach var of varlist Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer  durpcabas_nomiss_fwer durpcabas_miss_fwer{
		rename `var' ro`var'
	}
	save `roommate_merge',replace
	restore

	merge m:1 roommate_fwer using `roommate_merge', keepusing(ro*) nogen keep(1 3)

	keep roomnum_base Race Female roommate_fwer nstudent_fwer mixracebas Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer  durpcabas_nomiss_fwer durpcabas_miss_fwer ro* Res_base  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer DscoreacaIAT_fwer DscoreraceIAT_fwer DscoreraceIAT_fu_fwer DscoreacaIAT_fu_fwer



	local k =1
	 
	foreach var in `dep_table3' {
		
		*Full sample
		qui: xi: reg `var'_fu_fwer mixracebas `var'_fwer `controls_fwer' `rocontrols_fwer' if white_fwer==1, robust cluster(roomnum_base)
		
		matrix rtable = r(table)
		local pstar_`k'  = rtable[4,1] 

		local ++k
	}

		local K: word count `dep_table3'
		drop _all

		set obs `K'
		gen i = `c'
		gen k = _n

		gen pstar = .
		gen p = . 
		
		forval k = 1/`K' {
					replace pstar = `pstar_`k'' in `k'
					replace p  = `pvalue_`k'_t' in `k' // here i use pvalue because i want all the decimal places
				}
				
				
				if `c'>1 append using "`bs'"
				save "`bs'", replace
				
			
				
}
}


		use "`bs'", clear
		
		gsort i -p k	
		by i: gen qstar = pstar if _n==1
		by i: replace qstar = min(qstar[_n-1],pstar) if _n>1
			
		* Define minimum for single-step p-value
		by i: egen qstar1 = min(pstar)
			

	* Steps 3 and 4. Calculate step-down and single-step Westfall-Young adjusted p-value
		gen counter  = qstar <=p
		gen counter1 = qstar1<=p 
		collapse (sum) counter* `Nstats', by(k) fast
		gen pwyoung  = counter /`N'
		gen pwyoung1 = counter1/`N'
		drop counter*
		
		assert pwyoung<=pwyoung1	
	
	
	* Fill in descriptive information
		gen outcome=""
		gen double coef = .
		gen double stderr = .
		gen double p = .

		forval k = 1/`K' {
			replace outcome = "`k'"   if k==`k'
			replace coef = `beta_`k''              if k==`k'
			replace stderr = `se_`k''          if k==`k'
			replace p  = `pvalue_`k'_t'                   if k==`k' 
		}	
	
	* Step 5. Enforce monotonicity using successive maximization.  Include k in the sort to break ties.
	sort p k
	cap replace pwyoung  = max(pwyoung[_n-1]  ,pwyoung)   if _n>1
	cap replace pwyoung1 = max(pwyoung1[_n-1] ,pwyoung1)  if _n>1
	
	
	
	order k outcome coef stderr p pwyoung pwyoung1
	label var p  "Unadjusted p-value"
	cap label var pwyoung   "Westfall-Young adjusted p-value"
	cap label var pwyoung1 "Westfall-Young adjusted p-value (single-step)"

	forval k = 1/`K' {
	
		su pwyoung if k == `k'
		local p2_`k' = r(mean) 
		local pwyoung_`k': di %8.3f `p2_`k''
		
		su pwyoung1 if k == `k'
		local p3_`k' = r(mean) 
		local pwyoung1_`k': di %8.3f `p3_`k''		
	}
	
	preserve
		fdr, pvals(`fdr_p')
		forval k = 1/`K' {
		summ bky06_qval if _n==`k'
		local fdr_`k': di %8.3f r(mean)
		}
	restore
	
	
	cap file close soutput
	file open soutput using "$fwer_tables/table3_white_fwer_`N'.tex", write replace
	file write soutput "\begin{tabular}{@{\extracolsep{4pt}}p{6cm}*{3}{>{\centering\arraybackslash}m{2cm}}@{}}   \toprule "  _n
    file write soutput "  & Race IAT & Population IAT   \\  \midrule "

	file write soutput " Mixracebas & `beta_1' & `beta_2'  \\" _n
	file write soutput "  Standard Error & `se_1' & `se_2'   \\ "_n
	file write soutput " Unadjusted p-value & `p_1' & `p_2'   \\ "_n
	file write soutput " WY adjusted p-value & `pwyoung_1' & `pwyoung_2' \\ "_n
	file write soutput " WY adjusted p-value (single-step) & `pwyoung1_1' & `pwyoung1_2'  \\ "_n
	file write soutput " FDR (q-value) & `fdr_1' & `fdr_2'  \\ "_n
	file write soutput " Sample size & `N_1' & `N_2'  \\ "_n

	file write soutput "  \hline" _n
	file write soutput "\end{tabular}" _n
	file close soutput	

}	
if `black'{
set seed 3005
**************************************************
** Table 3 with blacks only
**************************************************
local fdr_p ""


use "$clean/uctdata_balanced.dta", clear
local fdr_p ""

xtset


***first creating the coefficient, s.e., and original p-value

*FULL SAMPLE
local controls whi col Else Female Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss     
*BLACK and WHITE subsamples
local controls_subsample Female Falseuct2012 missfalse Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss      
*Roommate controls
local rocontrols roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas  roprivschool_nomiss roprivschool_miss  rodurpcabas_nomiss rodurpcabas_miss  roconsbas_nomiss roconsbas_miss  


*FULL SAMPLE
local controls_fwer white_fwer coloured_fwer Else_fwer Female Falseuct2012_fwer missfalse_fwer  Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer     
*BLACK and WHITE subsamples
local controls_subsample_fwer Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer      
*Roommate controls
local rocontrols_fwer roForeign_fwer roforeign_missing_fwer roprivateschool_nomiss_fwer roprivateschool_miss_fwer roconsbas_nomiss_fwer roconsbas_miss_fwer rodurpcabas_nomiss_fwer rodurpcabas_miss_fwer roFalseuct2012_fwer romissfalse_fwer


			
local k =1

foreach i in `dep_table3' {
	
	*Full sample
	xi: reg `i' mixracebas L.`i' `controls_subsample' `rocontrols' i.Res_base  if round==2 &black==1,  robust cluster(roomnum_base)
	
	local beta_`k'_t = _b[mixracebas]
	local se_`k'_t = _se[mixracebas]

	local beta_`k' : di %8.3f `beta_`k'_t'
	local se_`k' : di %8.3f `se_`k'_t'
	
	matrix rtable = r(table)
	local pvalue_`k'_t  = rtable[4,1] 
	local p_`k' :  di %8.3f `pvalue_`k'_t'
	local fdr_p `fdr_p' `p_`k''

	local N_`k' =  e(N)
	local k = `k'+1
}

***now we have locals p_1 p_2 p_3 for three hypotheses

***Pvalues based on 10,000 iterations

	qui xi: reg DscoreacaIAT mixracebas L.DscoreacaIAT `controls_subsample' `rocontrols' i.Res_base  if round==2 &black==1,  robust cluster(roomnum_base) // running again, to get e(sample)
	keep if e(sample) 
	
	rename nstudent nstudent_fwer
	keep nstudent_fwer Res_base Female Race mixracebas
	g round=1 
	sort nstudent_fwer
	tempfile sample_full
	save `sample_full', replace
 
	g count=1
	collapse (count) count, by(Res_base Female Race mixracebas)
	reshape wide count, i(Res_base Female Race) j(mixracebas)
	tempfile merger
	save `merger', replace

	
	tempfile bs

forval c=1/`N' {
	
	di "iteration `c'"
	
qui{
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', keep(3) nogen keepusing(nstudent_fwer)
	merge m:1 Res_base Female Race using `merger', nogen keep(3) keepusing(count?)

	egen count=rowtotal(count0 count1)
	replace count0=0 if count0==.


	* Shuffle individuals into mixed race and same race rooms
	sort nstudent_fwer 
	g rand_num=runiform()
	sort Res_base Female Race rand_num
	by Res_base Female Race: g mixracebas=1 if _n>count0
	replace mixracebas=0 if mixracebas==.
	
	* Shuffle room assignment
	sort nstudent_fwer 
	g r_5=runiform()
	sort Res_base Female Race mixracebas r_5
	by Res_base Female Race mixracebas: g merge_room=_n
	drop r_5 rand_num
	tempfile nstudent_1
	save `nstudent_1'

	* for roommates
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', nogen keep(1 2) keepusing(nstudent_fwer)
	sort nstudent_fwer
	tempfile nstudent_2
	save `nstudent_2', replace
	

	use "$clean/uctdata_balanced.dta", clear

	g nstudent_fwer=nstudent
	merge 1:1 round nstudent_fwer using `sample_full', nogen keep(3) keepusing(nstudent_fwer)
	sort nstudent_fwer
	drop nstudent_fwer
	g temp_random = runiform()	
	bysort Res_base Female Race mixracebas (temp_random): g merge_room=_n	
	drop temp_random
	
	merge 1:1 Res_base Female Race mixracebas merge_room using `nstudent_1', keepusing( nstudent_fwer Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer  durpcabas_nomiss_fwer durpcabas_miss_fwer whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer DscoreacaIAT_fwer DscoreacaIAT_fu_fwer DscoreraceIAT_fwer DscoreraceIAT_fu_fwer) nogen

	g roommate_fwer=.
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[2] if _n==1 & round[2]==1	
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[1] if _n==2 & round==1	

	
	* generate random sequence for Race draws
	preserve
	clear
	set obs 4
	g n=_n
	g order=runiform()
	sort order
	local order=" "

	forval i=1/4{
		local n=n[`i']
		local order="`order' " + "`n'"
	}
	restore
	

	levelsof Race, local(Race)
	foreach race in `order'{
		g roommate_match=.	
	keep if round==1
	sort nstudent_fwer
	g rrr=runiform()
	g sep =(((Race==1 & mixracebas==0) | Race!=1 & mixracebas==1) & roommate_fwer==. & round==1)
	sort nstudent_fwer
	bysort Res_base Female (sep rrr): replace roommate_match=_n
	
	sort nstudent_fwer
	drop rrr sep
	preserve
	tempfile race_`race'
	use `nstudent_2', clear
	keep if Race==`race'
	sort nstudent_fwer
	g temp_random = runiform()	
	bysort Res_base Female (temp_random): g roommate_match=_n	
	drop temp_random	
	sort Res_base Female roommate_match

	rename nstudent_fwer roommate_fwer

	save `race_`race'', replace

	restore

	merge 1:1 Res_base Female roommate_match using `race_`race'', update keepusing(roommate_fwer) nogen
	drop roommate_match
	}

	keep if round==1
	keep roommate_fwer nstudent_fwer roomnum_base mixracebas
	
	merge 1:1 nstudent_fwer using "$clean/nstudents_fwer.dta", keepusing(Race Res_base Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer  durpcabas_nomiss_fwer durpcabas_miss_fwer  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer DscoreacaIAT_fwer DscoreraceIAT_fwer DscoreraceIAT_fu_fwer DscoreacaIAT_fu_fwer) nogen keep(3)
	


	preserve
	tempfile roommate_merge
	use "$clean/nstudents_fwer.dta", clear
	rename nstudent_fwer roommate_fwer
	rename Race roRace
	foreach var of varlist Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer  durpcabas_nomiss_fwer durpcabas_miss_fwer{
		rename `var' ro`var'
	}
	save `roommate_merge',replace
	restore

	merge m:1 roommate_fwer using `roommate_merge', keepusing(ro*) nogen keep(1 3)

	keep roomnum_base Race Female roommate_fwer nstudent_fwer mixracebas Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer  durpcabas_nomiss_fwer durpcabas_miss_fwer ro* Res_base  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer DscoreacaIAT_fwer DscoreraceIAT_fwer DscoreraceIAT_fu_fwer DscoreacaIAT_fu_fwer



	local k =1
	 
	foreach var in `dep_table3' {
		*Full sample
		xi: reg `var'_fu_fwer mixracebas `var'_fwer `controls_fwer' `rocontrols_fwer' if black_fwer==1, robust cluster(roomnum_base)
		
		matrix rtable = r(table)
		local pstar_`k'  = rtable[4,1] 

		local ++k
	}

		local K: word count `dep_table3'
		drop _all

		set obs `K'
		gen i = `c'
		gen k = _n

		gen pstar = .
		gen p = . 
		
		forval k = 1/`K' {
					replace pstar = `pstar_`k'' in `k'
					replace p  = `pvalue_`k'_t' in `k' // here i use pvalue because i want all the decimal places
				}
				
				
				if `c'>1 append using "`bs'"
				save "`bs'", replace
				
			
				
}
}


		use "`bs'", clear
		
		gsort i -p k	
		by i: gen qstar = pstar if _n==1
		by i: replace qstar = min(qstar[_n-1],pstar) if _n>1
			
		* Define minimum for single-step p-value
		by i: egen qstar1 = min(pstar)
			

	* Steps 3 and 4. Calculate step-down and single-step Westfall-Young adjusted p-value
		gen counter  = qstar <=p
		gen counter1 = qstar1<=p 
		collapse (sum) counter* `Nstats', by(k) fast
		gen pwyoung  = counter /`N'
		gen pwyoung1 = counter1/`N'
		drop counter*
		
		assert pwyoung<=pwyoung1	
	
	
	* Fill in descriptive information
		gen outcome=""
		gen double coef = .
		gen double stderr = .
		gen double p = .

		forval k = 1/`K' {
			replace outcome = "`k'"   if k==`k'
			replace coef = `beta_`k''              if k==`k'
			replace stderr = `se_`k''          if k==`k'
			replace p  = `pvalue_`k'_t'                   if k==`k' 
		}	
	
	* Step 5. Enforce monotonicity using successive maximization.  Include k in the sort to break ties.
	sort p k
	cap replace pwyoung  = max(pwyoung[_n-1]  ,pwyoung)   if _n>1
	cap replace pwyoung1 = max(pwyoung1[_n-1] ,pwyoung1)  if _n>1
	
	
	
	order k outcome coef stderr p pwyoung pwyoung1
	label var p  "Unadjusted p-value"
	cap label var pwyoung   "Westfall-Young adjusted p-value"
	cap label var pwyoung1 "Westfall-Young adjusted p-value (single-step)"

	forval k = 1/`K' {
	
		su pwyoung if k == `k'
		local p2_`k' = r(mean) 
		local pwyoung_`k': di %8.3f `p2_`k''
		
		su pwyoung1 if k == `k'
		local p3_`k' = r(mean) 
		local pwyoung1_`k': di %8.3f `p3_`k''		
	}
	
	preserve
		fdr, pvals(`fdr_p')
		forval k = 1/`K' {
		summ bky06_qval if _n==`k'
		local fdr_`k': di %8.3f r(mean)
		}
	restore
	
	
	cap file close soutput
	file open soutput using "$fwer_tables/table3_black_fwer_`N'.tex", write replace
	file write soutput "\begin{tabular}{@{\extracolsep{4pt}}p{6cm}*{3}{>{\centering\arraybackslash}m{2cm}}@{}}   \toprule "  _n
    file write soutput "  & Race IAT & Population IAT   \\  \midrule "

	file write soutput " Mixracebas & `beta_1' & `beta_2'  \\" _n
	file write soutput "  Standard Error & `se_1' & `se_2'   \\ "_n
	file write soutput " Unadjusted p-value & `p_1' & `p_2'   \\ "_n
	file write soutput " WY adjusted p-value & `pwyoung_1' & `pwyoung_2' \\ "_n
	file write soutput " WY adjusted p-value (single-step) & `pwyoung1_1' & `pwyoung1_2'  \\ "_n
	file write soutput " FDR (q-value) & `fdr_1' & `fdr_2'  \\ "_n
	file write soutput " Sample size & `N_1' & `N_2'  \\ "_n

	file write soutput "  \hline" _n
	file write soutput "\end{tabular}" _n
	file close soutput	
}
exit

```

### `ForJournals_a/Code/analysis/FWER/3_fwer_table4.do`
```stata
 /************************************************************************************************************************************************

Project: Interaction, Sterotypes and Performance: Evidence from South Africa
Corno L., La Ferrara E., Burns J.

do file: 3_fwer_table4.do
author: Vrinda Kapoor, 15/04/2019

Datasets used: uctdata_balanced.dta, nstudent.dta

Output: Dropbox\SouthAfrica_clean\Output\FWER

*************************************************************************************************************************************************/

	clear all
	do $additional/fdr_sharpened_qvalues

	local N = 10000
	local full = 0
	local white = 0
	local black =1 
	

	**CONTROLS

**DEPENDENT VARIABLES
	
	*local categories 		table4 					table8 				tablea8  /*
	*					*/	tablea10 				tablea11 			tablea12

	local dep_table4 	    GPA 					examspassed  		continue 

**************************************************
** Calculating the p-values
**************************************************
*important syntax to know
	*k hypotheses
	*N iterations/bootstraps, later local c

if `full'{
**************************************************
** table 4 with full sample
**************************************************
set seed 3005
local fdr_p ""


use "$clean/uctdata_balanced.dta", clear

***first creating the coefficient, s.e., and original p-value

*FULL SAMPLE
local controls white coloured Else Female Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss     
*BLACK and WHITE subsamples
local controls_subsample Female Falseuct2012 missfalse Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss      
*Roommate controls
local rocontrols roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas  roprivschool_nomiss roprivschool_miss  rodurpcabas_nomiss rodurpcabas_miss  roconsbas_nomiss roconsbas_miss  

*FULL SAMPLE
local controls_fwer white_fwer coloured_fwer Else_fwer Female Falseuct2012_fwer missfalse_fwer  Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer     
*BLACK and WHITE subsamples
local controls_subsample_fwer Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer      
*Roommate controls
local rocontrols_fwer roForeign_fwer roforeign_missing_fwer roprivateschool_nomiss_fwer roprivateschool_miss_fwer roconsbas_nomiss_fwer roconsbas_miss_fwer rodurpcabas_nomiss_fwer rodurpcabas_miss_fwer roFalseuct2012_fwer romissfalse_fwer
		

			
local k =1

foreach i in `dep_table4' {
	
	*Full sample
	xi: reg `i'  mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base i.regprogram  if round==2,  robust cluster(roomnum_base)
	
	local beta_`k'_t = _b[mixracebas]
	local se_`k'_t = _se[mixracebas]

	local beta_`k' : di %8.3f `beta_`k'_t'
	local se_`k' : di %8.3f `se_`k'_t'
	
	matrix rtable = r(table)
	local pvalue_`k'_t  = rtable[4,1] 
	local p_`k' :  di %8.3f `pvalue_`k'_t'
	local fdr_p `fdr_p' `p_`k''

	local N_`k' =  e(N)
	local k = `k'+1
}

***now we have locals p_1 p_2 p_3 for three hypotheses

***Pvalues based on 10,000 iterations

	qui xi: reg GPA mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base i.regprogram  if round==2,  robust cluster(roomnum_base) // running again, to get e(sample)
	keep if e(sample) 
	
	rename nstudent nstudent_fwer
	keep nstudent_fwer Res_base Female Race mixracebas
	g round=1 
	sort nstudent_fwer
	tempfile sample_full
	save `sample_full', replace
 
	g count=1
	collapse (count) count, by(Res_base Female Race mixracebas)
	reshape wide count, i(Res_base Female Race) j(mixracebas)
	tempfile merger
	save `merger', replace

	
	tempfile bs

forval c=1/`N' {
	
	di "iteration `c'"
	
	qui{
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', keep(3) nogen keepusing(nstudent_fwer)
	merge m:1 Res_base Female Race using `merger', nogen keep(3) keepusing(count?)

	egen count=rowtotal(count0 count1)
	replace count0=0 if count0==.

	* Shuffle individuals into mixed race and same race rooms
	sort nstudent_fwer
	g rand_num=runiform()
	sort Res_base Female Race rand_num
	by Res_base Female Race: g mixracebas=1 if _n>count0
	replace mixracebas=0 if mixracebas==.

	* Shuffle room assignment
	sort nstudent_fwer
	g r_5=runiform()
	sort Res_base Female Race mixracebas r_5
	by Res_base Female Race mixracebas: g merge_room=_n
	drop r_5 rand_num
	tempfile nstudent_1
	save `nstudent_1', replace

	* for roommates
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', nogen keep(1 2) keepusing(nstudent_fwer)
	sort nstudent_fwer
	tempfile nstudent_2
	save `nstudent_2', replace

	use "$clean/uctdata_balanced.dta", clear

	g nstudent_fwer=nstudent
	merge 1:1 round nstudent_fwer using `sample_full', nogen keep(3) keepusing(nstudent_fwer)
	sort nstudent_fwer
	drop nstudent_fwer
	g temp_random = runiform()	
	bysort Res_base Female Race mixracebas (temp_random): g merge_room=_n	
	drop temp_random

	merge 1:1 Res_base Female Race mixracebas merge_room using `nstudent_1', keepusing( nstudent_fwer Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer  durpcabas_nomiss_fwer durpcabas_miss_fwer whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer GPA_fu_fwer examspassed_fu_fwer continue_fu_fwer regprogram_fwer) nogen

	g roommate_fwer=.
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[2] if _n==1 & round[2]==1	
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[1] if _n==2 & round==1	

	* generate random sequence for Race draws
	preserve
	clear
	set obs 4
	g n=_n
	g order=runiform()
	sort order
	local order=" "

	forval i=1/4{
		local n=n[`i']
		local order="`order' " + "`n'"
	}
	restore

	levelsof Race, local(Race)
	foreach race in `order'{
		
	g roommate_match=.	
	keep if round==1
	sort nstudent_fwer
	g rrr=runiform()
	g sep =(((Race==1 & mixracebas==0) | Race!=1 & mixracebas==1) & roommate_fwer==. & round==1)
	sort nstudent_fwer
	bysort Res_base Female (sep rrr): replace roommate_match=_n
	
	sort nstudent_fwer
	drop rrr sep

	preserve
	tempfile race_`race'
	use `nstudent_2', clear
	keep if Race==`race'
	sort nstudent_fwer
	g temp_random = runiform()	
	bysort Res_base Female (temp_random): g roommate_match=_n	
	drop temp_random	
	sort Res_base Female roommate_match

	rename nstudent_fwer roommate_fwer

	save `race_`race'', replace
	restore

	merge 1:1 Res_base Female roommate_match using `race_`race'', update keepusing(roommate_fwer) nogen
	drop roommate_match
	}

	keep if round==1

	keep roommate_fwer nstudent_fwer roomnum_base mixracebas

	merge 1:1 nstudent_fwer using "$clean/nstudents_fwer.dta", keepusing(Race Res_base Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer  durpcabas_nomiss_fwer durpcabas_miss_fwer whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer GPA_fu_fwer examspassed_fu_fwer continue_fu_fwer regprogram_fwer) nogen keep(3)

	preserve
	tempfile roommate_merge
	use "$clean/nstudents_fwer.dta", clear
	rename nstudent_fwer roommate_fwer
	rename Race roRace
	foreach var of varlist Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer{
		rename `var' ro`var'
	}
	save `roommate_merge',replace
	restore

	merge m:1 roommate_fwer using `roommate_merge', keepusing(ro*) nogen keep(1 3)

	keep roomnum_base Race Female roommate_fwer nstudent_fwer mixracebas Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer  durpcabas_nomiss_fwer durpcabas_miss_fwer whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer GPA_fu_fwer examspassed_fu_fwer continue_fu_fwer regprogram_fwer Res_base blackRes_fwer whiteRes_fwer ro*



	local k =1
	 
	foreach var in `dep_table4' {
		
		*Full sample
		xi: reg `var'_fu_fwer  mixracebas `controls_fwer' `rocontrols_fwer' i.blackRes i.whiteRes i.Res_base i.regprogram, robust cluster(roomnum_base)
		
		matrix rtable = r(table)
		local pstar_`k'  = rtable[4,1] 

		local ++k
	}

		local K: word count `dep_table4'
		drop _all

		set obs `K'
		gen i = `c'
		gen k = _n

		gen pstar = .
		gen p = . 
		
		forval k = 1/`K' {
					replace pstar = `pstar_`k'' in `k'
					replace p  = `pvalue_`k'_t' in `k' // here i use pvalue because i want all the decimal places
				}
				
				
				if `c'>1 append using "`bs'"
				save "`bs'", replace
				
			
				
}
}


		use "`bs'", clear
		
		gsort i -p k	
		by i: gen qstar = pstar if _n==1
		by i: replace qstar = min(qstar[_n-1],pstar) if _n>1
			
		* Define minimum for single-step p-value
		by i: egen qstar1 = min(pstar)
			

	* Steps 3 and 4. Calculate step-down and single-step Westfall-Young adjusted p-value
		gen counter  = qstar <=p
		gen counter1 = qstar1<=p 
		collapse (sum) counter* `Nstats', by(k) fast
		gen pwyoung  = counter /`N'
		gen pwyoung1 = counter1/`N'
		drop counter*
		
		assert pwyoung<=pwyoung1	
	
	
	* Fill in descriptive information
		gen outcome=""
		gen double coef = .
		gen double stderr = .
		gen double p = .

		forval k = 1/`K' {
			replace outcome = "`k'"   if k==`k'
			replace coef = `beta_`k''              if k==`k'
			replace stderr = `se_`k''          if k==`k'
			replace p  = `pvalue_`k'_t'                   if k==`k' 
		}	
	
	* Step 5. Enforce monotonicity using successive maximization.  Include k in the sort to break ties.
	sort p k
	cap replace pwyoung  = max(pwyoung[_n-1]  ,pwyoung)   if _n>1
	cap replace pwyoung1 = max(pwyoung1[_n-1] ,pwyoung1)  if _n>1
	
	
	
	order k outcome coef stderr p pwyoung pwyoung1
	label var p  "Unadjusted p-value"
	cap label var pwyoung   "Westfall-Young adjusted p-value"
	cap label var pwyoung1 "Westfall-Young adjusted p-value (single-step)"

	forval k = 1/`K' {
	
		su pwyoung if k == `k'
		local p2_`k' = r(mean) 
		local pwyoung_`k': di %8.3f `p2_`k''
		
		su pwyoung1 if k == `k'
		local p3_`k' = r(mean) 
		local pwyoung1_`k': di %8.3f `p3_`k''		
	}
	
		* FDR
	preserve
		fdr, pvals(`fdr_p')
		forval k = 1/`K' {
		summ bky06_qval if _n==`k'
		local fdr_`k': di %8.3f r(mean)
		}
	restore
	
	
	
	
	cap file close soutput
	file open soutput using "$fwer_tables/table4_full_fwer_`N'.tex", write replace
	file write soutput "\begin{tabular}{@{\extracolsep{4pt}}p{6cm}*{4}{>{\centering\arraybackslash}m{2cm}}@{}}   \toprule "  _n
    file write soutput "  & GPA & Number of exams passed & Eligible to continue  \\  \midrule "

	file write soutput " Mixracebas & `beta_1' & `beta_2' & `beta_3'    \\" _n
	file write soutput "  Standard Error & `se_1' & `se_2' & `se_3'   \\ "_n
	file write soutput " Unadjusted p-value & `p_1' & `p_2' & `p_3'  \\ "_n
	file write soutput " WY adjusted p-value & `pwyoung_1' & `pwyoung_2' & `pwyoung_3'  \\ "_n
	file write soutput " WY adjusted p-value (single-step) & `pwyoung1_1' & `pwyoung1_2' & `pwyoung1_3'  \\ "_n
	file write soutput " FDR (q-value) & `fdr_1' & `fdr_2' & `fdr_3' \\ "_n
	file write soutput " Sample size & `N_1' & `N_2' & `N_3'  \\ "_n

	file write soutput "  \hline" _n
	file write soutput "\end{tabular}" _n
	file close soutput	
}
	
if `white'{	
	set seed 3005
**************************************************
** table 4 with whites only
**************************************************
local fdr_p ""

	local dep_table4 	    GPA 					examspassed  		continue 


use "$clean/uctdata_balanced.dta", clear

***first creating the coefficient, s.e., and original p-value

*FULL SAMPLE
local controls white coloured Else Female Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss     
*BLACK and WHITE subsamples
local controls_subsample Female Falseuct2012 missfalse Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss      
*Roommate controls
local rocontrols roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas  roprivschool_nomiss roprivschool_miss  rodurpcabas_nomiss rodurpcabas_miss  roconsbas_nomiss roconsbas_miss  

*FULL SAMPLE
local controls_fwer white_fwer coloured_fwer Else_fwer Female Falseuct2012_fwer missfalse_fwer  Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer     
*BLACK and WHITE subsamples
local controls_subsample_fwer Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer      
*Roommate controls
local rocontrols_fwer roForeign_fwer roforeign_missing_fwer roprivateschool_nomiss_fwer roprivateschool_miss_fwer roconsbas_nomiss_fwer roconsbas_miss_fwer rodurpcabas_nomiss_fwer rodurpcabas_miss_fwer roFalseuct2012_fwer romissfalse_fwer
			
local k =1

foreach i in `dep_table4' {
	
	*Full sample
	xi: reg `i'  mixracebas `controls_subsample' `rocontrols' i.Res_base i.regprogram  if round==2&white==1,  robust cluster(roomnum_base)
	
	local beta_`k'_t = _b[mixracebas]
	local se_`k'_t = _se[mixracebas]

	local beta_`k' : di %8.3f `beta_`k'_t'
	local se_`k' : di %8.3f `se_`k'_t'
	
	matrix rtable = r(table)
	local pvalue_`k'_t  = rtable[4,1] 
	local p_`k' :  di %8.3f `pvalue_`k'_t'
	local fdr_p `fdr_p' `p_`k''

	local N_`k' =  e(N)
	local k = `k'+1
}

***now we have locals p_1 p_2 p_3 for three hypotheses

***Pvalues based on 10,000 iterations

	qui xi: reg GPA mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base i.regprogram  if round==2,  robust cluster(roomnum_base) // running again, to get e(sample)
	keep if e(sample) 
	
	rename nstudent nstudent_fwer
	keep nstudent_fwer Res_base Female Race mixracebas
	g round=1 
	sort nstudent_fwer
	tempfile sample_full
	save `sample_full', replace
 
	g count=1
	collapse (count) count, by(Res_base Female Race mixracebas)
	reshape wide count, i(Res_base Female Race) j(mixracebas)
	tempfile merger
	save `merger', replace

	
	tempfile bs

forval c=1/`N' {
	
	di "iteration `c'"
	
	qui{
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', keep(3) nogen keepusing(nstudent_fwer)
	merge m:1 Res_base Female Race using `merger', nogen keep(3) keepusing(count?)

	egen count=rowtotal(count0 count1)
	replace count0=0 if count0==.

	* Shuffle individuals into mixed race and same race rooms
	sort nstudent_fwer
	g rand_num=runiform()
	sort Res_base Female Race rand_num
	by Res_base Female Race: g mixracebas=1 if _n>count0
	replace mixracebas=0 if mixracebas==.

	* Shuffle room assignment
	sort nstudent_fwer
	g r_5=runiform()
	sort Res_base Female Race mixracebas r_5
	by Res_base Female Race mixracebas: g merge_room=_n
	drop r_5 rand_num
	tempfile nstudent_1
	save `nstudent_1', replace

	* for roommates
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', nogen keep(1 2) keepusing(nstudent_fwer)
	sort nstudent_fwer
	tempfile nstudent_2
	save `nstudent_2', replace

	use "$clean/uctdata_balanced.dta", clear

	g nstudent_fwer=nstudent
	merge 1:1 round nstudent_fwer using `sample_full', nogen keep(3) keepusing(nstudent_fwer)
	sort nstudent_fwer
	drop nstudent_fwer
	g temp_random = runiform()
	bysort Res_base Female Race mixracebas (temp_random): g merge_room=_n
	drop temp_random

	merge 1:1 Res_base Female Race mixracebas merge_room using `nstudent_1', keepusing( nstudent_fwer Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer GPA_fu_fwer examspassed_fu_fwer continue_fu_fwer regprogram_fwer) nogen

	g roommate_fwer=.
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[2] if _n==1 & round[2]==1	
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[1] if _n==2 & round==1	
	

	* generate random sequence for Race draws
	preserve
	clear
	set obs 4
	g n=_n
	g order=runiform()
	sort order
	local order=" "

	forval i=1/4{
		local n=n[`i']
		local order="`order' " + "`n'"
	}
	restore

	levelsof Race, local(Race)
	foreach race in `order'{
		
		g roommate_match=.	
	keep if round==1
	sort nstudent_fwer
	g rrr=runiform()
	g sep =(((Race==1 & mixracebas==0) | Race!=1 & mixracebas==1) & roommate_fwer==. & round==1)
	sort nstudent_fwer
	bysort Res_base Female (sep rrr): replace roommate_match=_n
	
	sort nstudent_fwer
	drop rrr sep
	preserve
	tempfile race_`race'
	use `nstudent_2', clear
	keep if Race==`race'
	sort nstudent_fwer
	g temp_random = runiform()	
	bysort Res_base Female (temp_random): g roommate_match=_n	
	drop temp_random	
	sort Res_base Female roommate_match
	
	rename nstudent_fwer roommate_fwer

	save `race_`race'', replace
	restore

	merge 1:1 Res_base Female roommate_match using `race_`race'', update keepusing(roommate_fwer) nogen
	drop roommate_match
	}

	keep if round==1

	keep roommate_fwer nstudent_fwer roomnum_base mixracebas

	merge 1:1 nstudent_fwer using "$clean/nstudents_fwer.dta", keepusing(Race Res_base Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer GPA_fu_fwer examspassed_fu_fwer continue_fu_fwer regprogram_fwer) nogen keep(3)

	preserve
	tempfile roommate_merge
	use "$clean/nstudents_fwer.dta", clear
	rename nstudent_fwer roommate_fwer
	rename Race roRace
	foreach var of varlist Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer{
		rename `var' ro`var'
	}
	save `roommate_merge',replace
	restore

	merge m:1 roommate_fwer using `roommate_merge', keepusing(ro*) nogen keep(1 3)

	keep roomnum_base Race Female roommate_fwer nstudent_fwer mixracebas Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer ro* Res_base  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer GPA_fu_fwer examspassed_fu_fwer continue_fu_fwer regprogram_fwer



	local k =1
	 
	foreach var in `dep_table4' {
		
		*Full sample
		xi: reg `var'_fu_fwer  mixracebas `controls_subsample_fwer' `rocontrols_fwer' i.Res_base i.regprogram if white_fwer==1, robust cluster(roomnum_base)
		
		matrix rtable = r(table)
		local pstar_`k'  = rtable[4,1] 

		local ++k
	}

		local K: word count `dep_table4'
		drop _all

		set obs `K'
		gen i = `c'
		gen k = _n

		gen pstar = .
		gen p = . 
		
		forval k = 1/`K' {
					replace pstar = `pstar_`k'' in `k'
					replace p  = `pvalue_`k'_t' in `k' // here i use pvalue because i want all the decimal places
				}
				
				
				if `c'>1 append using "`bs'"
				save "`bs'", replace
				
			
				
}
}


		use "`bs'", clear
		
		gsort i -p k	
		by i: gen qstar = pstar if _n==1
		by i: replace qstar = min(qstar[_n-1],pstar) if _n>1
			
		* Define minimum for single-step p-value
		by i: egen qstar1 = min(pstar)
			

	* Steps 3 and 4. Calculate step-down and single-step Westfall-Young adjusted p-value
		gen counter  = qstar <=p
		gen counter1 = qstar1<=p 
		collapse (sum) counter* `Nstats', by(k) fast
		gen pwyoung  = counter /`N'
		gen pwyoung1 = counter1/`N'
		drop counter*
		
		assert pwyoung<=pwyoung1	
	
	
	* Fill in descriptive information
		gen outcome=""
		gen double coef = .
		gen double stderr = .
		gen double p = .

		forval k = 1/`K' {
			replace outcome = "`k'"   if k==`k'
			replace coef = `beta_`k''              if k==`k'
			replace stderr = `se_`k''          if k==`k'
			replace p  = `pvalue_`k'_t'                   if k==`k' 
		}	
	
	* Step 5. Enforce monotonicity using successive maximization.  Include k in the sort to break ties.
	sort p k
	cap replace pwyoung  = max(pwyoung[_n-1]  ,pwyoung)   if _n>1
	cap replace pwyoung1 = max(pwyoung1[_n-1] ,pwyoung1)  if _n>1
	
	
	
	order k outcome coef stderr p pwyoung pwyoung1
	label var p  "Unadjusted p-value"
	cap label var pwyoung   "Westfall-Young adjusted p-value"
	cap label var pwyoung1 "Westfall-Young adjusted p-value (single-step)"

	forval k = 1/`K' {
	
		su pwyoung if k == `k'
		local p2_`k' = r(mean) 
		local pwyoung_`k': di %8.3f `p2_`k''
		
		su pwyoung1 if k == `k'
		local p3_`k' = r(mean) 
		local pwyoung1_`k': di %8.3f `p3_`k''		
	}
	
		* FDR
	preserve
		fdr, pvals(`fdr_p')
		forval k = 1/`K' {
		summ bky06_qval if _n==`k'
		local fdr_`k': di %8.3f r(mean)
		}
	restore
	
	
	
	cap file close soutput
	file open soutput using "$fwer_tables/table4_white_fwer_`N'.tex", write replace
	file write soutput "\begin{tabular}{@{\extracolsep{4pt}}p{6cm}*{4}{>{\centering\arraybackslash}m{2cm}}@{}}   \toprule "  _n
    file write soutput "  & GPA & Number of exams passed & Eligible to continue  \\  \midrule "

	file write soutput " Mixracebas & `beta_1' & `beta_2' & `beta_3'    \\" _n
	file write soutput "  Standard Error & `se_1' & `se_2' & `se_3'   \\ "_n
	file write soutput " Unadjusted p-value & `p_1' & `p_2' & `p_3'  \\ "_n
	file write soutput " WY adjusted p-value & `pwyoung_1' & `pwyoung_2' & `pwyoung_3'  \\ "_n
	file write soutput " WY adjusted p-value (single-step) & `pwyoung1_1' & `pwyoung1_2' & `pwyoung1_3'  \\ "_n
	file write soutput " FDR (q-value) & `fdr_1' & `fdr_2' & `fdr_3' \\ "_n
	file write soutput " Sample size & `N_1' & `N_2' & `N_3'  \\ "_n

	file write soutput "  \hline" _n
	file write soutput "\end{tabular}" _n
	file close soutput	

}
	
if `black'{
	set seed 3005
**************************************************
** table 4 with blacks only
**************************************************
local fdr_p ""

use "$clean/uctdata_balanced.dta", clear


*FULL SAMPLE
local controls white coloured Else Female Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss     
*BLACK and WHITE subsamples
local controls_subsample Female Falseuct2012 missfalse Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss      
*Roommate controls
local rocontrols roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas  roprivschool_nomiss roprivschool_miss  rodurpcabas_nomiss rodurpcabas_miss  roconsbas_nomiss roconsbas_miss  

*FULL SAMPLE
local controls_fwer white_fwer coloured_fwer Else_fwer Female Falseuct2012_fwer missfalse_fwer  Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer     
*BLACK and WHITE subsamples
local controls_subsample_fwer Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer      
*Roommate controls
local rocontrols_fwer roForeign_fwer roforeign_missing_fwer roprivateschool_nomiss_fwer roprivateschool_miss_fwer roconsbas_nomiss_fwer roconsbas_miss_fwer rodurpcabas_nomiss_fwer rodurpcabas_miss_fwer roFalseuct2012_fwer romissfalse_fwer
		

			
local k =1

foreach i in `dep_table4' {
	
	*Full sample
	xi: reg `i'  mixracebas `controls_subsample' `rocontrols' i.Res_base i.regprogram  if round==2&black==1,  robust cluster(roomnum_base)
	
	local beta_`k'_t = _b[mixracebas]
	local se_`k'_t = _se[mixracebas]

	local beta_`k' : di %8.3f `beta_`k'_t'
	local se_`k' : di %8.3f `se_`k'_t'
	
	matrix rtable = r(table)
	local pvalue_`k'_t  = rtable[4,1] 
	local p_`k' :  di %8.3f `pvalue_`k'_t'
	local fdr_p `fdr_p' `p_`k''

	local N_`k' =  e(N)
	local k = `k'+1
}

***now we have locals p_1 p_2 p_3 for three hypotheses

***Pvalues based on 10,000 iterations

	qui xi: reg GPA mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base i.regprogram  if round==2,  robust cluster(roomnum_base) // running again, to get e(sample)
	keep if e(sample) 
	
	rename nstudent nstudent_fwer
	keep nstudent_fwer Res_base Female Race mixracebas
	g round=1 
	sort nstudent_fwer
	tempfile sample_full
	save `sample_full', replace
 
	g count=1
	collapse (count) count, by(Res_base Female Race mixracebas)
	reshape wide count, i(Res_base Female Race) j(mixracebas)
	tempfile merger
	save `merger', replace

	
	tempfile bs

forval c=1/`N' {
	
	di "iteration `c'"
	
	qui{
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', keep(3) nogen keepusing(nstudent_fwer)
	merge m:1 Res_base Female Race using `merger', nogen keep(3) keepusing(count?)

	egen count=rowtotal(count0 count1)
	replace count0=0 if count0==.

	* Shuffle individuals into mixed race and same race rooms
	sort nstudent_fwer
	g rand_num=runiform()
	sort Res_base Female Race rand_num
	by Res_base Female Race: g mixracebas=1 if _n>count0
	replace mixracebas=0 if mixracebas==.

	* Shuffle room assignment
	sort nstudent_fwer
	g r_5=runiform()
	sort Res_base Female Race mixracebas r_5
	by Res_base Female Race mixracebas: g merge_room=_n
	drop r_5 rand_num
	tempfile nstudent_1
	save `nstudent_1', replace

	* for roommates
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', nogen keep(1 2) keepusing(nstudent_fwer)
	tempfile nstudent_2
	save `nstudent_2', replace

	use "$clean/uctdata_balanced.dta", clear

	g nstudent_fwer=nstudent
	merge 1:1 round nstudent_fwer using `sample_full', nogen keep(3) keepusing(nstudent_fwer)
	sort nstudent_fwer
	drop nstudent_fwer
	g temp_random = runiform()	
	bysort Res_base Female Race mixracebas (temp_random): g merge_room=_n	
	drop temp_random

	merge 1:1 Res_base Female Race mixracebas merge_room using `nstudent_1', keepusing( nstudent_fwer Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer GPA_fu_fwer examspassed_fu_fwer continue_fu_fwer regprogram_fwer) nogen

	g roommate_fwer=.
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[2] if _n==1 & round[2]==1
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[1] if _n==2 & round==1

	* generate random sequence for Race draws
	preserve
	clear
	set obs 4
	g n=_n
	g order=runiform()
	sort order
	local order=" "

	forval i=1/4{
		local n=n[`i']
		local order="`order' " + "`n'"
	}
	restore

	levelsof Race, local(Race)
	foreach race in `order'{
					g roommate_match=.	
	keep if round==1
	sort nstudent_fwer
	g rrr=runiform()
	g sep =(((Race==1 & mixracebas==0) | Race!=1 & mixracebas==1) & roommate_fwer==. & round==1)
	sort nstudent_fwer
	bysort Res_base Female (sep rrr): replace roommate_match=_n
	
	sort nstudent_fwer
	drop rrr sep
	preserve
	tempfile race_`race'
	use `nstudent_2', clear
	keep if Race==`race'
	sort nstudent_fwer
	g temp_random = runiform()	
	bysort Res_base Female (temp_random): g roommate_match=_n	
	drop temp_random	
	sort Res_base Female roommate_match
	
	rename nstudent_fwer roommate_fwer

	save `race_`race'', replace
	restore

	merge 1:1 Res_base Female roommate_match using `race_`race'', update keepusing(roommate_fwer) nogen
	drop roommate_match
	}

	keep if round==1

	keep roommate_fwer nstudent_fwer roomnum_base mixracebas

	merge 1:1 nstudent_fwer using "$clean/nstudents_fwer.dta", keepusing(Race Res_base Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer GPA_fu_fwer examspassed_fu_fwer continue_fu_fwer regprogram_fwer) nogen keep(3)

	preserve
	tempfile roommate_merge
	use "$clean/nstudents_fwer.dta", clear
	rename nstudent_fwer roommate_fwer
	rename Race roRace
	foreach var of varlist Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer{
		rename `var' ro`var'
	}
	save `roommate_merge',replace
	restore

	merge m:1 roommate_fwer using `roommate_merge', keepusing(ro*) nogen keep(1 3)

	keep roomnum_base Race Female roommate_fwer nstudent_fwer mixracebas Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer ro* Res_base  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer GPA_fu_fwer examspassed_fu_fwer continue_fu_fwer regprogram_fwer



	local k =1
	 
	foreach var in `dep_table4' {
		*Full sample
		xi: reg `var'_fu_fwer  mixracebas `controls_subsample_fwer' `rocontrols_fwer' i.Res_base i.regprogram if black_fwer==1, robust cluster(roomnum_base)
		
		matrix rtable = r(table)
		local pstar_`k'  = rtable[4,1] 

		local ++k
	}

		local K: word count `dep_table4'
		drop _all

		set obs `K'
		gen i = `c'
		gen k = _n

		gen pstar = .
		gen p = . 
		
		forval k = 1/`K' {
					replace pstar = `pstar_`k'' in `k'
					replace p  = `pvalue_`k'_t' in `k' // here i use pvalue because i want all the decimal places
				}
				
				
				if `c'>1 append using "`bs'"
				save "`bs'", replace
				
			
				
}
}


		use "`bs'", clear
		
		gsort i -p k	
		by i: gen qstar = pstar if _n==1
		by i: replace qstar = min(qstar[_n-1],pstar) if _n>1
			
		* Define minimum for single-step p-value
		by i: egen qstar1 = min(pstar)
			

	* Steps 3 and 4. Calculate step-down and single-step Westfall-Young adjusted p-value
		gen counter  = qstar <=p
		gen counter1 = qstar1<=p 
		collapse (sum) counter* `Nstats', by(k) fast
		gen pwyoung  = counter /`N'
		gen pwyoung1 = counter1/`N'
		drop counter*
		
		assert pwyoung<=pwyoung1	
	
	
	* Fill in descriptive information
		gen outcome=""
		gen double coef = .
		gen double stderr = .
		gen double p = .

		forval k = 1/`K' {
			replace outcome = "`k'"   if k==`k'
			replace coef = `beta_`k''              if k==`k'
			replace stderr = `se_`k''          if k==`k'
			replace p  = `pvalue_`k'_t'                   if k==`k' 
		}	
	
	* Step 5. Enforce monotonicity using successive maximization.  Include k in the sort to break ties.
	sort p k
	cap replace pwyoung  = max(pwyoung[_n-1]  ,pwyoung)   if _n>1
	cap replace pwyoung1 = max(pwyoung1[_n-1] ,pwyoung1)  if _n>1
	
	
	
	order k outcome coef stderr p pwyoung pwyoung1
	label var p  "Unadjusted p-value"
	cap label var pwyoung   "Westfall-Young adjusted p-value"
	cap label var pwyoung1 "Westfall-Young adjusted p-value (single-step)"

	forval k = 1/`K' {
	
		su pwyoung if k == `k'
		local p2_`k' = r(mean) 
		local pwyoung_`k': di %8.3f `p2_`k''
		
		su pwyoung1 if k == `k'
		local p3_`k' = r(mean) 
		local pwyoung1_`k': di %8.3f `p3_`k''		
	}
	
	* FDR
	preserve
		fdr, pvals(`fdr_p')
		forval k = 1/`K' {
		summ bky06_qval if _n==`k'
		local fdr_`k': di %8.3f r(mean)
		}
	restore
	
	
	cap file close soutput
	file open soutput using "$fwer_tables/table4_black_fwer_`N'.tex", write replace
	file write soutput "\begin{tabular}{@{\extracolsep{4pt}}p{6cm}*{4}{>{\centering\arraybackslash}m{2cm}}@{}}   \toprule "  _n
    file write soutput "  & GPA & Number of exams passed & Eligible to continue  \\  \midrule "

	file write soutput " Mixracebas & `beta_1' & `beta_2' & `beta_3'    \\" _n
	file write soutput "  Standard Error & `se_1' & `se_2' & `se_3'   \\ "_n
	file write soutput " Unadjusted p-value & `p_1' & `p_2' & `p_3'  \\ "_n
	file write soutput " WY adjusted p-value & `pwyoung_1' & `pwyoung_2' & `pwyoung_3'  \\ "_n
	file write soutput " WY adjusted p-value (single-step) & `pwyoung1_1' & `pwyoung1_2' & `pwyoung1_3'  \\ "_n
	file write soutput " FDR (q-value) & `fdr_1' & `fdr_2' & `fdr_3' \\ "_n
	file write soutput " Sample size & `N_1' & `N_2' & `N_3'  \\ "_n
	file write soutput "  \hline" _n
	file write soutput "\end{tabular}" _n
	file close soutput	

}

exit

```

### `ForJournals_a/Code/analysis/FWER/4_fwer_table5.do`
```stata
 /************************************************************************************************************************************************

Project: Interaction, Sterotypes and Performance: Evidence from South Africa
Corno L., La Ferrara E., Burns J.

do file: 4_fwer_table5.do
author: Vrinda Kapoor, 15/04/2019

Datasets used: uctdata_balanced.dta, nstudent.dta

Output: Dropbox\SouthAfrica_clean\Output\FWER

*************************************************************************************************************************************************/

	clear all
	do $additional/fdr_sharpened_qvalues

	local N = 10000
	local full = 0
	local white = 0
	local black =1
	
	local dep_table5 		PCAfriend  				PCAattitude 		PCAcomm 	

**************************************************
** Calculating the p-values
**************************************************
*important syntax to know
	*k hypotheses
	*N iterations/bootstraps, later local c

if `full'{
	set seed 3005
**************************************************
** Table 5 with full sample
**************************************************
local fdr_p ""

use "$clean/uctdata_balanced.dta", clear



***first creating the coefficient, s.e., and original p-value

*FULL SAMPLE
local controls white coloured Else Female Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss     
*BLACK and WHITE subsamples
local controls_subsample Female Falseuct2012 missfalse Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss      
*Roommate controls
local rocontrols roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas  roprivschool_nomiss roprivschool_miss  rodurpcabas_nomiss rodurpcabas_miss  roconsbas_nomiss roconsbas_miss  

*FULL SAMPLE
local controls_fwer white_fwer coloured_fwer Else_fwer Female Falseuct2012_fwer missfalse_fwer  Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer     
*BLACK and WHITE subsamples
local controls_subsample_fwer Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer      
*Roommate controls
local rocontrols_fwer roForeign_fwer roforeign_missing_fwer roprivateschool_nomiss_fwer roprivateschool_miss_fwer roconsbas_nomiss_fwer roconsbas_miss_fwer rodurpcabas_nomiss_fwer rodurpcabas_miss_fwer roFalseuct2012_fwer romissfalse_fwer
		

			
local k =1

foreach i in `dep_table5' {
	
	*Full sample
	xi: reg `i'  mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base if round==2,  robust cluster(roomnum_base)
	
	local beta_`k'_t = _b[mixracebas]
	local se_`k'_t = _se[mixracebas]

	local beta_`k' : di %8.3f `beta_`k'_t'
	local se_`k' : di %8.3f `se_`k'_t'
	
	matrix rtable = r(table)
	local pvalue_`k'_t  = rtable[4,1] 
	local p_`k' :  di %8.3f `pvalue_`k'_t'
	local fdr_p `fdr_p' `p_`k''

	local N_`k' =  e(N)
	local k = `k'+1
}


***now we have locals p_1 p_2 p_3 for three hypotheses

***Pvalues based on 10,000 iterations

	*qui xi: reg PCAfriend  mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base if round==2,  robust cluster(roomnum_base) // running again, to get e(sample)
	*keep if e(sample) 
	keep if round == 2 // because the sample changes between the three hypotheses
	rename nstudent nstudent_fwer
	keep nstudent_fwer Res_base Female Race mixracebas
	g round=1 
	sort nstudent_fwer
	tempfile sample_full
	save `sample_full', replace
 
	g count=1
	collapse (count) count, by(Res_base Female Race mixracebas)
	reshape wide count, i(Res_base Female Race) j(mixracebas)
	tempfile merger
	save `merger', replace

	
	tempfile bs

forval c=1/`N' {
	
	di "iteration `c'"
	
qui{
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', keep(3) nogen keepusing(nstudent_fwer)
	merge m:1 Res_base Female Race using `merger', nogen keep(3) keepusing(count?)

	egen count=rowtotal(count0 count1)
	replace count0=0 if count0==.

	* Shuffle individuals into mixed race and same race rooms
	sort nstudent_fwer
	g rand_num=runiform()
	sort Res_base Female Race rand_num
	by Res_base Female Race: g mixracebas=1 if _n>count0
	replace mixracebas=0 if mixracebas==.

	* Shuffle room assignment
	sort nstudent_fwer
	g r_5=runiform()
	sort Res_base Female Race mixracebas r_5
	by Res_base Female Race mixracebas: g merge_room=_n
	drop r_5 rand_num
	tempfile nstudent_1
	save `nstudent_1', replace

	* for roommates
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', nogen keep(1 2) keepusing(nstudent_fwer)
	sort nstudent_fwer
	tempfile nstudent_2
	save `nstudent_2', replace

	use "$clean/uctdata_balanced.dta", clear

	g nstudent_fwer=nstudent
	merge 1:1 round nstudent_fwer using `sample_full', nogen keep(3) keepusing(nstudent_fwer)
	sort nstudent_fwer
	drop nstudent_fwer
	g temp_random = runiform()
	bysort Res_base Female Race mixracebas (temp_random): g merge_room=_n
	drop temp_random

	merge 1:1 Res_base Female Race mixracebas merge_room using `nstudent_1', keepusing( nstudent_fwer Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_fu_fwer  PCAattitude_fu_fwer PCAcomm_fu_fwer) nogen

	g roommate_fwer=.
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[2] if _n==1 & round[2]==1	
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[1] if _n==2 & round==1	

	* generate random sequence for Race draws
	preserve
	clear
	set obs 4
	g n=_n
	g order=runiform()
	sort order
	local order=" "

	forval i=1/4{
		local n=n[`i']
		local order="`order' " + "`n'"
	}
	restore

	levelsof Race, local(Race)
	foreach race in `order'{
		
g roommate_match=.	
	keep if round==1
	sort nstudent_fwer
	g rrr=runiform()
	g sep =(((Race==1 & mixracebas==0) | Race!=1 & mixracebas==1) & roommate_fwer==. & round==1)
	sort nstudent_fwer
	bysort Res_base Female (sep rrr): replace roommate_match=_n
	
	sort nstudent_fwer
	drop rrr sep
	preserve
	tempfile race_`race'
	use `nstudent_2', clear
	keep if Race==`race'
	sort nstudent_fwer
	g temp_random = runiform()	
	bysort Res_base Female (temp_random): g roommate_match=_n	
	drop temp_random	
	sort Res_base Female roommate_match

	rename nstudent_fwer roommate_fwer

	save `race_`race'', replace
	restore

	merge 1:1 Res_base Female roommate_match using `race_`race'', update keepusing(roommate_fwer) nogen
	drop roommate_match
	}

	keep if round==1

	keep roommate_fwer nstudent_fwer roomnum_base mixracebas

	merge 1:1 nstudent_fwer using "$clean/nstudents_fwer.dta", keepusing(Race Res_base Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_fu_fwer  PCAattitude_fu_fwer PCAcomm_fu_fwer) nogen keep(3)

	preserve
	tempfile roommate_merge
	use "$clean/nstudents_fwer.dta", clear
	rename nstudent_fwer roommate_fwer
	rename Race roRace
	foreach var of varlist Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer{
		rename `var' ro`var'
	}
	save `roommate_merge',replace
	restore

	merge m:1 roommate_fwer using `roommate_merge', keepusing(ro*) nogen keep(1 3)

	keep roomnum_base Race Female roommate_fwer nstudent_fwer mixracebas Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer ro* Res_base  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_fu_fwer  PCAattitude_fu_fwer PCAcomm_fu_fwer



	local k =1
	 
	foreach var in `dep_table5' {
		
		*Full sample
		xi: reg `var'_fu_fwer  mixracebas `controls_fwer' `rocontrols_fwer' i.blackRes i.whiteRes i.Res_base, robust cluster(roomnum_base)
		
		matrix rtable = r(table)
		local pstar_`k'  = rtable[4,1] 

		local ++k
	}

		local K: word count `dep_table5'
		drop _all

		set obs `K'
		gen i = `c'
		gen k = _n

		gen pstar = .
		gen p = . 
		
		forval k = 1/`K' {
					replace pstar = `pstar_`k'' in `k'
					replace p  = `pvalue_`k'_t' in `k' // here i use pvalue because i want all the decimal places
				}
				
				
				if `c'>1 append using "`bs'"
				save "`bs'", replace
				
			
				
}
}


		use "`bs'", clear
		
		gsort i -p k	
		by i: gen qstar = pstar if _n==1
		by i: replace qstar = min(qstar[_n-1],pstar) if _n>1
			
		* Define minimum for single-step p-value
		by i: egen qstar1 = min(pstar)
			

	* Steps 3 and 4. Calculate step-down and single-step Westfall-Young adjusted p-value
		gen counter  = qstar <=p
		gen counter1 = qstar1<=p 
		collapse (sum) counter* `Nstats', by(k) fast
		gen pwyoung  = counter /`N'
		gen pwyoung1 = counter1/`N'
		drop counter*
		
		assert pwyoung<=pwyoung1	
	
	
	* Fill in descriptive information
		gen outcome=""
		gen double coef = .
		gen double stderr = .
		gen double p = .

		forval k = 1/`K' {
			replace outcome = "`k'"   if k==`k'
			replace coef = `beta_`k''              if k==`k'
			replace stderr = `se_`k''          if k==`k'
			replace p  = `pvalue_`k'_t'                   if k==`k' 
		}	
	
	* Step 5. Enforce monotonicity using successive maximization.  Include k in the sort to break ties.
	sort p k
	cap replace pwyoung  = max(pwyoung[_n-1]  ,pwyoung)   if _n>1
	cap replace pwyoung1 = max(pwyoung1[_n-1] ,pwyoung1)  if _n>1
	
	
	
	order k outcome coef stderr p pwyoung pwyoung1
	label var p  "Unadjusted p-value"
	cap label var pwyoung   "Westfall-Young adjusted p-value"
	cap label var pwyoung1 "Westfall-Young adjusted p-value (single-step)"

	forval k = 1/`K' {
	
		su pwyoung if k == `k'
		local p2_`k' = r(mean) 
		local pwyoung_`k': di %8.3f `p2_`k''
		
		su pwyoung1 if k == `k'
		local p3_`k' = r(mean) 
		local pwyoung1_`k': di %8.3f `p3_`k''		
	}
	
	* FDR
	preserve
		fdr, pvals(`fdr_p')
		forval k = 1/`K' {
		summ bky06_qval if _n==`k'
		local fdr_`k': di %8.3f r(mean)
		}
	restore
	
	

	cap file close soutput
	file open soutput using "$fwer_tables/table5_full_fwer_`N'.tex", write replace
	file write soutput "\begin{tabular}{@{\extracolsep{4pt}}p{6cm}*{4}{>{\centering\arraybackslash}m{2cm}}@{}}   \toprule "  _n
    file write soutput "  & Index of friendship & Index of attitudinal measures & Index of pro-social behavior  \\  \midrule "

	file write soutput " Mixracebas & `beta_1' & `beta_2' & `beta_3'    \\" _n
	file write soutput "  Standard Error & `se_1' & `se_2' & `se_3'   \\ "_n
	file write soutput " Unadjusted p-value & `p_1' & `p_2' & `p_3'  \\ "_n
	file write soutput " WY adjusted p-value & `pwyoung_1' & `pwyoung_2' & `pwyoung_3'  \\ "_n
	file write soutput " WY adjusted p-value (single-step) & `pwyoung1_1' & `pwyoung1_2' & `pwyoung1_3'  \\ "_n
	file write soutput " FDR (q-value) & `fdr_1' & `fdr_2' & `fdr_3' \\ "_n
	file write soutput " Sample size & `N_1' & `N_2' & `N_3'  \\ "_n

	file write soutput "  \hline" _n
	file write soutput "\end{tabular}" _n
	file close soutput	
}

if `white'{	
	set seed 3005
**************************************************
** Table 5 with whites only
**************************************************
local fdr_p ""

use "$clean/uctdata_balanced.dta", clear



***first creating the coefficient, s.e., and original p-value
*FULL SAMPLE
local controls white coloured Else Female Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss     
*BLACK and WHITE subsamples
local controls_subsample Female Falseuct2012 missfalse Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss      
*Roommate controls
local rocontrols roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas  roprivschool_nomiss roprivschool_miss  rodurpcabas_nomiss rodurpcabas_miss  roconsbas_nomiss roconsbas_miss  

*FULL SAMPLE
local controls_fwer white_fwer coloured_fwer Else_fwer Female Falseuct2012_fwer missfalse_fwer  Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer     
*BLACK and WHITE subsamples
local controls_subsample_fwer Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer      
*Roommate controls
local rocontrols_fwer roForeign_fwer roforeign_missing_fwer roprivateschool_nomiss_fwer roprivateschool_miss_fwer roconsbas_nomiss_fwer roconsbas_miss_fwer rodurpcabas_nomiss_fwer rodurpcabas_miss_fwer roFalseuct2012_fwer romissfalse_fwer
		

			
local k =1

foreach i in `dep_table5' {
	
	*Full sample
	xi: reg `i'  mixracebas `controls' `rocontrols' i.Res_base if round==2&white==1,  robust cluster(roomnum_base)
	
	local beta_`k'_t = _b[mixracebas]
	local se_`k'_t = _se[mixracebas]

	local beta_`k' : di %8.3f `beta_`k'_t'
	local se_`k' : di %8.3f `se_`k'_t'
	
	matrix rtable = r(table)
	local pvalue_`k'_t  = rtable[4,1] 
	local p_`k' :  di %8.3f `pvalue_`k'_t'
	local fdr_p `fdr_p' `p_`k''

	local N_`k' =  e(N)
	local k = `k'+1
}


***now we have locals p_1 p_2 p_3 for three hypotheses

***Pvalues based on 10,000 iterations

	*qui xi: reg PCAfriend  mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base if round==2,  robust cluster(roomnum_base) // running again, to get e(sample)
	*keep if e(sample) 
	keep if round == 2 // because the sample changes between the three hypotheses
	rename nstudent nstudent_fwer
	keep nstudent_fwer Res_base Female Race mixracebas
	g round=1 
	sort nstudent_fwer
	tempfile sample_full
	save `sample_full', replace
 
	g count=1
	collapse (count) count, by(Res_base Female Race mixracebas)
	reshape wide count, i(Res_base Female Race) j(mixracebas)
	tempfile merger
	save `merger', replace

	
	tempfile bs

forval c=1/`N' {
	
	di "iteration `c'"
	
	qui{
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', keep(3) nogen keepusing(nstudent_fwer)
	merge m:1 Res_base Female Race using `merger', nogen keep(3) keepusing(count?)

	egen count=rowtotal(count0 count1)
	replace count0=0 if count0==.

	* Shuffle individuals into mixed race and same race rooms
	sort nstudent_fwer
	g rand_num=runiform()
	sort Res_base Female Race rand_num
	by Res_base Female Race: g mixracebas=1 if _n>count0
	replace mixracebas=0 if mixracebas==.

	* Shuffle room assignment
	sort nstudent_fwer
	g r_5=runiform()
	sort Res_base Female Race mixracebas r_5
	by Res_base Female Race mixracebas: g merge_room=_n
	drop r_5 rand_num
	tempfile nstudent_1
	save `nstudent_1', replace

	* for roommates
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', nogen keep(1 2) keepusing(nstudent_fwer)
	sort nstudent_fwer
	tempfile nstudent_2
	save `nstudent_2', replace

	use "$clean/uctdata_balanced.dta", clear

	g nstudent_fwer=nstudent
	merge 1:1 round nstudent_fwer using `sample_full', nogen keep(3) keepusing(nstudent_fwer)
	sort nstudent_fwer
	drop nstudent_fwer
	g temp_random = runiform()
	bysort Res_base Female Race mixracebas (temp_random): g merge_room=_n
	drop temp_random

	merge 1:1 Res_base Female Race mixracebas merge_room using `nstudent_1', keepusing( nstudent_fwer Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_fu_fwer  PCAattitude_fu_fwer PCAcomm_fu_fwer) nogen

	g roommate_fwer=.
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[2] if _n==1 & round[2]==1	
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[1] if _n==2 & round==1	
	
	* generate random sequence for Race draws
	preserve
	clear
	set obs 4
	g n=_n
	g order=runiform()
	sort order
	local order=" "

	forval i=1/4{
		local n=n[`i']
		local order="`order' " + "`n'"
	}
	restore

	levelsof Race, local(Race)
	foreach race in `order'{
		
		g roommate_match=.	
	keep if round==1
	sort nstudent_fwer
	g rrr=runiform()
	g sep =(((Race==1 & mixracebas==0) | Race!=1 & mixracebas==1) & roommate_fwer==. & round==1)
	sort nstudent_fwer
	bysort Res_base Female (sep rrr): replace roommate_match=_n
	
	sort nstudent_fwer
	drop rrr sep
	preserve
	tempfile race_`race'
	use `nstudent_2', clear
	keep if Race==`race'
	sort nstudent_fwer
	g temp_random = runiform()	
	bysort Res_base Female (temp_random): g roommate_match=_n	
	drop temp_random	
	sort Res_base Female roommate_match
	
	rename nstudent_fwer roommate_fwer

	save `race_`race'', replace
	restore

	merge 1:1 Res_base Female roommate_match using `race_`race'', update keepusing(roommate_fwer) nogen
	drop roommate_match
	}

	keep if round==1

	keep roommate_fwer nstudent_fwer roomnum_base mixracebas

	merge 1:1 nstudent_fwer using "$clean/nstudents_fwer.dta", keepusing(Race Res_base Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_fu_fwer  PCAattitude_fu_fwer PCAcomm_fu_fwer) nogen keep(3)

	preserve
	tempfile roommate_merge
	use "$clean/nstudents_fwer.dta", clear
	rename nstudent_fwer roommate_fwer
	rename Race roRace
	foreach var of varlist Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer{
		rename `var' ro`var'
	}
	save `roommate_merge',replace
	restore

	merge m:1 roommate_fwer using `roommate_merge', keepusing(ro*) nogen keep(1 3)

	keep roomnum_base Race Female roommate_fwer nstudent_fwer mixracebas Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer ro* Res_base  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_fu_fwer  PCAattitude_fu_fwer PCAcomm_fu_fwer



	local k =1
	 
	foreach var in `dep_table5' {
		
		*Full sample
		xi: reg `var'  mixracebas `controls_fwer' `rocontrols_fwer'  i.Res_base if white_fwer==1, robust cluster(roomnum_base)
		
		matrix rtable = r(table)
		local pstar_`k'  = rtable[4,1] 

		local ++k
	}

		local K: word count `dep_table5'
		drop _all

		set obs `K'
		gen i = `c'
		gen k = _n

		gen pstar = .
		gen p = . 
		
		forval k = 1/`K' {
					replace pstar = `pstar_`k'' in `k'
					replace p  = `pvalue_`k'_t' in `k' // here i use pvalue because i want all the decimal places
				}
				
				
				if `c'>1 append using "`bs'"
				save "`bs'", replace
				
			
				
}
}


		use "`bs'", clear
		
		gsort i -p k	
		by i: gen qstar = pstar if _n==1
		by i: replace qstar = min(qstar[_n-1],pstar) if _n>1
			
		* Define minimum for single-step p-value
		by i: egen qstar1 = min(pstar)
			

	* Steps 3 and 4. Calculate step-down and single-step Westfall-Young adjusted p-value
		gen counter  = qstar <=p
		gen counter1 = qstar1<=p 
		collapse (sum) counter* `Nstats', by(k) fast
		gen pwyoung  = counter /`N'
		gen pwyoung1 = counter1/`N'
		drop counter*
		
		assert pwyoung<=pwyoung1	
	
	
	* Fill in descriptive information
		gen outcome=""
		gen double coef = .
		gen double stderr = .
		gen double p = .

		forval k = 1/`K' {
			replace outcome = "`k'"   if k==`k'
			replace coef = `beta_`k''              if k==`k'
			replace stderr = `se_`k''          if k==`k'
			replace p  = `pvalue_`k'_t'                   if k==`k' 
		}	
	
	* Step 5. Enforce monotonicity using successive maximization.  Include k in the sort to break ties.
	sort p k
	cap replace pwyoung  = max(pwyoung[_n-1]  ,pwyoung)   if _n>1
	cap replace pwyoung1 = max(pwyoung1[_n-1] ,pwyoung1)  if _n>1
	
	
	
	order k outcome coef stderr p pwyoung pwyoung1
	label var p  "Unadjusted p-value"
	cap label var pwyoung   "Westfall-Young adjusted p-value"
	cap label var pwyoung1 "Westfall-Young adjusted p-value (single-step)"

	forval k = 1/`K' {
	
		su pwyoung if k == `k'
		local p2_`k' = r(mean) 
		local pwyoung_`k': di %8.3f `p2_`k''
		
		su pwyoung1 if k == `k'
		local p3_`k' = r(mean) 
		local pwyoung1_`k': di %8.3f `p3_`k''		
	}
	
	* FDR
	preserve
		fdr, pvals(`fdr_p')
		forval k = 1/`K' {
		summ bky06_qval if _n==`k'
		local fdr_`k': di %8.3f r(mean)
		}
	restore
	

	cap file close soutput
	file open soutput using "$fwer_tables/table5_white_fwer_`N'.tex", write replace
	file write soutput "\begin{tabular}{@{\extracolsep{4pt}}p{6cm}*{4}{>{\centering\arraybackslash}m{2cm}}@{}}   \toprule "  _n
    file write soutput "  & Index of friendship & Index of attitudinal measures & Index of pro-social behavior  \\  \midrule "

	file write soutput " Mixracebas & `beta_1' & `beta_2' & `beta_3'    \\" _n
	file write soutput "  Standard Error & `se_1' & `se_2' & `se_3'   \\ "_n
	file write soutput " Unadjusted p-value & `p_1' & `p_2' & `p_3'  \\ "_n
	file write soutput " WY adjusted p-value & `pwyoung_1' & `pwyoung_2' & `pwyoung_3'  \\ "_n
	file write soutput " WY adjusted p-value (single-step) & `pwyoung1_1' & `pwyoung1_2' & `pwyoung1_3'  \\ "_n
	file write soutput " FDR (q-value) & `fdr_1' & `fdr_2' & `fdr_3' \\ "_n
	file write soutput " Sample size & `N_1' & `N_2' & `N_3'  \\ "_n

	file write soutput "  \hline" _n
	file write soutput "\end{tabular}" _n
	file close soutput	
}

if `black'{	
	set seed 3005
**************************************************
** Table 5 with whites only
**************************************************
local fdr_p ""

use "$clean/uctdata_balanced.dta", clear



***first creating the coefficient, s.e., and original p-value
*FULL SAMPLE
local controls white coloured Else Female Falseuct2012 missfalse  Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss     
*BLACK and WHITE subsamples
local controls_subsample Female Falseuct2012 missfalse Foreign foreign_missing  privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss   consbas_nomiss consbas_miss      
*Roommate controls
local rocontrols roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas  roprivschool_nomiss roprivschool_miss  rodurpcabas_nomiss rodurpcabas_miss  roconsbas_nomiss roconsbas_miss  

*FULL SAMPLE
local controls_fwer white_fwer coloured_fwer Else_fwer Female Falseuct2012_fwer missfalse_fwer  Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer     
*BLACK and WHITE subsamples
local controls_subsample_fwer Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer  privateschool_nomiss_fwer privateschool_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer   consbas_nomiss_fwer consbas_miss_fwer      
*Roommate controls
local rocontrols_fwer roForeign_fwer roforeign_missing_fwer roprivateschool_nomiss_fwer roprivateschool_miss_fwer roconsbas_nomiss_fwer roconsbas_miss_fwer rodurpcabas_nomiss_fwer rodurpcabas_miss_fwer roFalseuct2012_fwer romissfalse_fwer
		


			
local k =1

foreach i in `dep_table5' {
	
	*Full sample
	xi: reg `i'  mixracebas `controls' `rocontrols' i.Res_base if round==2&black==1,  robust cluster(roomnum_base)
	
	local beta_`k'_t = _b[mixracebas]
	local se_`k'_t = _se[mixracebas]

	local beta_`k' : di %8.3f `beta_`k'_t'
	local se_`k' : di %8.3f `se_`k'_t'
	
	matrix rtable = r(table)
	local pvalue_`k'_t  = rtable[4,1] 
	local p_`k' :  di %8.3f `pvalue_`k'_t'
	local fdr_p `fdr_p' `p_`k''

	local N_`k' =  e(N)
	local k = `k'+1
}


***now we have locals p_1 p_2 p_3 for three hypotheses

***Pvalues based on 10,000 iterations

	*qui xi: reg PCAfriend  mixracebas `controls' `rocontrols' i.blackRes i.whiteRes i.Res_base if round==2,  robust cluster(roomnum_base) // running again, to get e(sample)
	*keep if e(sample) 
	keep if round == 2 // because the sample changes between the three hypotheses
	rename nstudent nstudent_fwer
	keep nstudent_fwer Res_base Female Race mixracebas
	g round=1 
	sort nstudent_fwer
	tempfile sample_full
	save `sample_full', replace
 
	g count=1
	collapse (count) count, by(Res_base Female Race mixracebas)
	reshape wide count, i(Res_base Female Race) j(mixracebas)
	tempfile merger
	save `merger', replace

	
	tempfile bs

forval c=1/`N' {
	
	di "iteration `c'"
	
	qui{
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', keep(3) nogen keepusing(nstudent_fwer)
	merge m:1 Res_base Female Race using `merger', nogen keep(3) keepusing(count?)

	egen count=rowtotal(count0 count1)
	replace count0=0 if count0==.

	* Shuffle individuals into mixed race and same race rooms
	sort nstudent_fwer
	g rand_num=runiform()
	sort Res_base Female Race rand_num
	by Res_base Female Race: g mixracebas=1 if _n>count0
	replace mixracebas=0 if mixracebas==.

	* Shuffle room assignment
	g r_5=runiform()
	sort Res_base Female Race mixracebas r_5
	by Res_base Female Race mixracebas: g merge_room=_n
	drop r_5 rand_num
	tempfile nstudent_1
	save `nstudent_1', replace

	* for roommates
	use "$clean/nstudents_fwer.dta", clear
	merge 1:1 nstudent_fwer using `sample_full', nogen keep(1 2) keepusing(nstudent_fwer)
	tempfile nstudent_2
	save `nstudent_2', replace

	use "$clean/uctdata_balanced.dta", clear

	g nstudent_fwer=nstudent
	merge 1:1 round nstudent_fwer using `sample_full', nogen keep(3) keepusing(nstudent_fwer)
	drop nstudent_fwer
	g temp_random = runiform()
	bysort Res_base Female Race mixracebas (temp_random): g merge_room=_n
	drop temp_random

	merge 1:1 Res_base Female Race mixracebas merge_room using `nstudent_1', keepusing( nstudent_fwer Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_fu_fwer  PCAattitude_fu_fwer PCAcomm_fu_fwer) nogen

	g roommate_fwer=.
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[2] if _n==1 & round[2]==1
	bysort round roomnum_base (nstudent_fwer): replace roommate_fwer=nstudent_fwer[1] if _n==2 & round==1

	* generate random sequence for Race draws
	preserve
	clear
	set obs 4
	g n=_n
	g order=runiform()
	sort order
	local order=" "

	forval i=1/4{
		local n=n[`i']
		local order="`order' " + "`n'"
	}
	restore

	levelsof Race, local(Race)
	foreach race in `order'{
		
	g roommate_match=.	
	keep if round==1
	sort nstudent_fwer
	g rrr=runiform()
	g sep =(((Race==1 & mixracebas==0) | Race!=1 & mixracebas==1) & roommate_fwer==. & round==1)
	sort nstudent_fwer
	bysort Res_base Female (sep rrr): replace roommate_match=_n
	
	sort nstudent_fwer
	drop rrr sep
	preserve
	tempfile race_`race'
	use `nstudent_2', clear
	keep if Race==`race'
	sort nstudent_fwer
	g temp_random = runiform()	
	bysort Res_base Female (temp_random): g roommate_match=_n	
	drop temp_random	
	sort Res_base Female roommate_match
	
	rename nstudent_fwer roommate_fwer

	save `race_`race'', replace
	restore

	merge 1:1 Res_base Female roommate_match using `race_`race'', update keepusing(roommate_fwer) nogen
	drop roommate_match
	}

	keep if round==1

	keep roommate_fwer nstudent_fwer roomnum_base mixracebas

	merge 1:1 nstudent_fwer using "$clean/nstudents_fwer.dta", keepusing(Race Res_base Female Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_fu_fwer  PCAattitude_fu_fwer PCAcomm_fu_fwer) nogen keep(3)

	preserve
	tempfile roommate_merge
	use "$clean/nstudents_fwer.dta", clear
	rename nstudent_fwer roommate_fwer
	rename Race roRace
	foreach var of varlist Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer{
		rename `var' ro`var'
	}
	save `roommate_merge',replace
	restore

	merge m:1 roommate_fwer using `roommate_merge', keepusing(ro*) nogen keep(1 3)

	keep roomnum_base Race Female roommate_fwer nstudent_fwer mixracebas Falseuct2012_fwer missfalse_fwer Foreign_fwer foreign_missing_fwer privateschool_nomiss_fwer privateschool_miss_fwer consbas_nomiss_fwer consbas_miss_fwer durpcabas_nomiss_fwer durpcabas_miss_fwer ro* Res_base  whiteRes_fwer blackRes_fwer white_fwer coloured_fwer Else_fwer black_fwer PCAfriend_fu_fwer  PCAattitude_fu_fwer PCAcomm_fu_fwer



	local k =1
	 
	foreach var in `dep_table5' {
		
		*Full sample
		xi: reg `var'_fu_fwer  mixracebas `controls_fwer' `rocontrols_fwer'  i.Res_base if black_fwer==1, robust cluster(roomnum_base)
		
		matrix rtable = r(table)
		local pstar_`k'  = rtable[4,1] 

		local ++k
	}

		local K: word count `dep_table5'
		drop _all

		set obs `K'
		gen i = `c'
		gen k = _n

		gen pstar = .
		gen p = . 
		
		forval k = 1/`K' {
					replace pstar = `pstar_`k'' in `k'
					replace p  = `pvalue_`k'_t' in `k' // here i use pvalue because i want all the decimal places
				}
				
				
				if `c'>1 append using "`bs'"
				save "`bs'", replace
				
			
				
}
}


		use "`bs'", clear
		
		gsort i -p k	
		by i: gen qstar = pstar if _n==1
		by i: replace qstar = min(qstar[_n-1],pstar) if _n>1
			
		* Define minimum for single-step p-value
		by i: egen qstar1 = min(pstar)
			

	* Steps 3 and 4. Calculate step-down and single-step Westfall-Young adjusted p-value
		gen counter  = qstar <=p
		gen counter1 = qstar1<=p 
		collapse (sum) counter* `Nstats', by(k) fast
		gen pwyoung  = counter /`N'
		gen pwyoung1 = counter1/`N'
		drop counter*
		
		assert pwyoung<=pwyoung1	
	
	
	* Fill in descriptive information
		gen outcome=""
		gen double coef = .
		gen double stderr = .
		gen double p = .

		forval k = 1/`K' {
			replace outcome = "`k'"   if k==`k'
			replace coef = `beta_`k''              if k==`k'
			replace stderr = `se_`k''          if k==`k'
			replace p  = `pvalue_`k'_t'                   if k==`k' 
		}	
	
	* Step 5. Enforce monotonicity using successive maximization.  Include k in the sort to break ties.
	sort p k
	cap replace pwyoung  = max(pwyoung[_n-1]  ,pwyoung)   if _n>1
	cap replace pwyoung1 = max(pwyoung1[_n-1] ,pwyoung1)  if _n>1
		
	
	order k outcome coef stderr p pwyoung pwyoung1
	label var p  "Unadjusted p-value"
	cap label var pwyoung   "Westfall-Young adjusted p-value"
	cap label var pwyoung1 "Westfall-Young adjusted p-value (single-step)"

	forval k = 1/`K' {
	
		su pwyoung if k == `k'
		local p2_`k' = r(mean) 
		local pwyoung_`k': di %8.3f `p2_`k''
		
		su pwyoung1 if k == `k'
		local p3_`k' = r(mean) 
		local pwyoung1_`k': di %8.3f `p3_`k''		
	}
	
	* FDR
	preserve
		fdr, pvals(`fdr_p')
		forval k = 1/`K' {
		summ bky06_qval if _n==`k'
		local fdr_`k': di %8.3f r(mean)
		}
	restore
	

	cap file close soutput
	file open soutput using "$fwer_tables/table5_black_fwer_`N'.tex", write replace
	file write soutput "\begin{tabular}{@{\extracolsep{4pt}}p{6cm}*{4}{>{\centering\arraybackslash}m{2cm}}@{}}   \toprule "  _n
    file write soutput "  & Index of friendship & Index of attitudinal measures & Index of pro-social behavior  \\  \midrule "

	file write soutput " Mixracebas & `beta_1' & `beta_2' & `beta_3'    \\" _n
	file write soutput "  Standard Error & `se_1' & `se_2' & `se_3'   \\ "_n
	file write soutput " Unadjusted p-value & `p_1' & `p_2' & `p_3'  \\ "_n
	file write soutput " WY adjusted p-value & `pwyoung_1' & `pwyoung_2' & `pwyoung_3'  \\ "_n
	file write soutput " WY adjusted p-value (single-step) & `pwyoung1_1' & `pwyoung1_2' & `pwyoung1_3'  \\ "_n
	file write soutput " FDR (q-value) & `fdr_1' & `fdr_2' & `fdr_3' \\ "_n
	file write soutput " Sample size & `N_1' & `N_2' & `N_3'  \\ "_n

	file write soutput "  \hline" _n
	file write soutput "\end{tabular}" _n
	file close soutput	
}

	
exit

```

### `ForJournals_a/Code/additional/fdr_sharpened_qvalues.do`
```stata
prog def fdr
 syntax , pvals(string)
 
 clear
 quietly gen float pval = .
  local n : word count `pvals'
  
 tokenize "`pvals'"
 
 set obs `n'
 forval i=1/`n'{
	replace pval = ``i''  in `i'
 }
* Collect the total number of p-values tested

quietly sum pval
local totalpvals = r(N)

* Sort the p-values in ascending order and generate a variable that codes each p-value's rank

quietly gen int original_sorting_order = _n
quietly sort pval
quietly gen int rank = _n if pval~=.

* Set the initial counter to 1 

local qval = 1

* Generate the variable that will contain the BKY (2006) sharpened q-values

gen bky06_qval = 1 if pval~=.

* Set up a loop that begins by checking which hypotheses are rejected at q = 1.000, then checks which hypotheses are rejected at q = 0.999, then checks which hypotheses are rejected at q = 0.998, etc.  The loop ends by checking which hypotheses are rejected at q = 0.001.


while `qval' > 0 {
	* First Stage
	* Generate the adjusted first stage q level we are testing: q' = q/1+q
	local qval_adj = `qval'/(1+`qval')
	* Generate value q'*r/M
	gen fdr_temp1 = `qval_adj'*rank/`totalpvals'
	* Generate binary variable checking condition p(r) <= q'*r/M
	gen reject_temp1 = (fdr_temp1>=pval) if pval~=.
	* Generate variable containing p-value ranks for all p-values that meet above condition
	gen reject_rank1 = reject_temp1*rank
	* Record the rank of the largest p-value that meets above condition
	egen total_rejected1 = max(reject_rank1)

	* Second Stage
	* Generate the second stage q level that accounts for hypotheses rejected in first stage: q_2st = q'*(M/m0)
	local qval_2st = `qval_adj'*(`totalpvals'/(`totalpvals'-total_rejected1[1]))
	* Generate value q_2st*r/M
	gen fdr_temp2 = `qval_2st'*rank/`totalpvals'
	* Generate binary variable checking condition p(r) <= q_2st*r/M
	gen reject_temp2 = (fdr_temp2>=pval) if pval~=.
	* Generate variable containing p-value ranks for all p-values that meet above condition
	gen reject_rank2 = reject_temp2*rank
	* Record the rank of the largest p-value that meets above condition
	egen total_rejected2 = max(reject_rank2)

	* A p-value has been rejected at level q if its rank is less than or equal to the rank of the max p-value that meets the above condition
	replace bky06_qval = `qval' if rank <= total_rejected2 & rank~=.
	* Reduce q by 0.001 and repeat loop
	drop fdr_temp* reject_temp* reject_rank* total_rejected*
	local qval = `qval' - .001
}
	

quietly sort original_sorting_order
end

```

## How to run a script

Write each script to a file under the output directory, then run it with
exactly this command (the data directory is mounted read-only at its own
path; nothing else from the host is visible; `$SCRIPT` is the absolute path of
the script you wrote):

    SCRIPT=<repo>/benchmark/reproductions/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a/script.R   # or <repo>/benchmark/reproductions/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a/attempt-<n>/script.R
    uv run --directory <repo> python -m benchmark.reproducers.run_sandbox --timeout 300 --label retally.run=claude-code-corno-2022-interaction-stereotypes-performance-seeded-2026-11-10-a --run-dir "$(dirname "$SCRIPT")" -- docker run --rm --label retally.run=claude-code-corno-2022-interaction-stereotypes-performance-seeded-2026-11-10-a --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a/mount/corno_2022_interaction_stereotypes_performance:<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a/mount/corno_2022_interaction_stereotypes_performance:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R; echo "exit code: $?"

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

The output directory `<repo>/benchmark/reproductions/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a/
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

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a`.
