# Retally reproduction task: brouwer-2022-teaching-norms (seeded, run 2026-11-02-b)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `brouwer-2022-teaching-norms`, mode `seeded`, run `2026-11-02-b`
- Paper: Teaching Norms: Direct Evidence of Parental Transmission
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/seeded/2026-11-02-b/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/seeded/2026-11-02-b/mount/brouwer_2022_teaching_norms`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/brouwer-2022-teaching-norms/seeded/2026-11-02-b`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/seeded/2026-11-02-b/mount/brouwer_2022_teaching_norms` as data, and `<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/seeded/2026-11-02-b/paper.txt` as
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

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/brouwer-2022-teaching-norms/seeded/2026-11-02-b --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Claims to Reproduce
1. child_punishment_no_controls: 0.11 (probability of direct punishment (0-1)) [type: coefficient]
   Location: Table 2, column (1) Punishment, row Child
   Context: Table 2 ("Determinants of Punishment Rate (Left) and Helping Rate (Right)"), column (1), row Child. Pooled OLS linear probability model of Punishment, a dummy equal to 1 if the targeted parent verbally and explicitly confronted the actor about the littering violation, on a Child dummy (the parent was accompanying one or more children, against walking alone), a VH dummy (the Violation + Help scene, in which the actor also drops the contents of a bag after littering) and their interaction, with no other controls. The sample is the targeted parents in the Violation and Violation + Help scenes; th…
2. child_punishment_controls: 0.12 (probability of direct punishment (0-1)) [type: coefficient]
   Location: Table 2, column (2) Punishment, row Child
   Context: Table 2, column (2), row Child. Same punishment model and sample as child_punishment_no_controls, adding the controls Male Target (father targeted), Male Actor (the male actor played the scene), Morning, Witness (another non-targeted adult was observing and able to intervene), Rich area (the school's IRIS area median income is above the city-wide median), Rain and Hot. One observation is dropped for missing data on the target's gender. School-clustered standard errors.
3. child_helping_no_controls: 0.21 (probability of helping (0-1)) [type: coefficient]
   Location: Table 2, column (3) Helping, row Child
   Context: Table 2, column (3), row Child. Pooled OLS linear probability model of Helping, a dummy equal to 1 if the targeted parent picked up at least one of the dropped items (or asked the child to), on Child, VH and Child x VH, with no other controls. The sample is the parents in the Help and Violation + Help scenes; the Violation scene, which has no helping opportunity, is excluded. School-clustered standard errors.
4. child_helping_controls: 0.22 (probability of helping (0-1)) [type: coefficient]
   Location: Table 2, column (4) Helping, row Child
   Context: Table 2, column (4), row Child. Same helping model and sample as child_helping_no_controls, with the controls of child_punishment_controls (Male Target, Male Actor, Morning, Witness, Rich area, Rain, Hot). The target with missing gender is dropped. School-clustered standard errors.
5. vh_punishment_controls: -0.04 (probability of direct punishment (0-1)) [type: coefficient]
   Location: Table 2, column (2) Punishment, row VH
   Context: Table 2, column (2), row VH: the Violation + Help scene dummy in the controlled punishment regression of child_punishment_controls. It is the change in the punishment rate of parents alone when a helping opportunity follows the violation.
6. vh_helping_controls: -0.1 (probability of helping (0-1)) [type: coefficient]
   Location: Table 2, column (4) Helping, row VH
   Context: Table 2, column (4), row VH: the Violation + Help scene dummy in the controlled helping regression of child_helping_controls. It is the change in the helping rate of parents alone when the actor littered before dropping the items (indirect punishment).
7. child_x_vh_punishment_no_controls: -0.13 (probability of direct punishment (0-1)) [type: coefficient]
   Location: Table 2, column (1) Punishment, row Child x VH
   Context: Table 2, column (1), row Child x VH: the interaction of the Child and Violation + Help dummies in the uncontrolled punishment regression of child_punishment_no_controls.
8. child_x_vh_punishment_controls: -0.12 (probability of direct punishment (0-1)) [type: coefficient]
   Location: Table 2, column (2) Punishment, row Child x VH
   Context: Table 2, column (2), row Child x VH, in the controlled punishment regression of child_punishment_controls.
9. child_x_vh_helping_no_controls: -0.06 (probability of helping (0-1)) [type: coefficient]
   Location: Table 2, column (3) Helping, row Child x VH
   Context: Table 2, column (3), row Child x VH, in the uncontrolled helping regression of child_helping_no_controls. This is the test of the indirect-punishment conjecture (Result 3: not significant).
10. child_x_vh_helping_controls: -0.07 (probability of helping (0-1)) [type: coefficient]
   Location: Table 2, column (4) Helping, row Child x VH
   Context: Table 2, column (4), row Child x VH, in the controlled helping regression of child_helping_controls.
11. observations_punishment_controls: 399.0 (targeted parents) [type: other]
   Location: Table 2, column (2), Observations
   Context: Observations in the controlled punishment regression (Table 2, column 2): parents in the Violation and Violation + Help scenes with non-missing controls.
12. observations_helping_no_controls: 401.0 (targeted parents) [type: other]
   Location: Table 2, column (3), Observations
   Context: Observations in the uncontrolled helping regression (Table 2, column 3): parents in the Help and Violation + Help scenes.

## Dataset Information
Name: brouwer_2022_teaching_norms
Local path: <repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/seeded/2026-11-02-b/mount/brouwer_2022_teaching_norms
File format: csv
Files in the dataset directory (paths relative to the local path above):
- Data Replication Package EJ MS20210782/3 replication package/Data/master.dta (128.8 KB) — 601 rows, 44 columns: School, Child, children, scene, Violation, Help, Punishment, Helping, male, Morning, witness, rich, Rain, hugo, ViolationHelp, HelpingParents, children2, children3, OwnChild, childage2, childage3, childage4, childage5, childage6, childage7, childage8, childage9, childage10, childage11, childage12, obs, wobs, day, Condition, kidshelped, Hot, inc_Q, povrate, response2, TIME, T10, boy, girl, numkids
- Data Replication Package EJ MS20210782/3 replication package/Data/survey2.dta (74.4 KB) — 243 rows, 29 columns: gender, children, male, traitement, reasonteaching, obs, normlitter, normenforc, normperslitter, normpersenforc, region, reasonimage, reasonnorm, reasonother, reasonotherprecision, reasonno, reason1, reason2, reason3, reason4, age, belgium, earning, typecity, emotion, environment_ecology, civism, image, others
- Data Replication Package EJ MS20210782/3 replication package/Data/survey1.dta (36.0 KB) — 506 rows, 14 columns: Children, Child, Male, Income, obs, BirthYear, Arron, OrderHV, Educ, V, DP, H, VH, risk
- Data Replication Package EJ MS20210782/1 paper/EJ MS20210782_accepted.pdf (430.5 KB)
- Data Replication Package EJ MS20210782/1 paper/EJ_MS20210782_conclusion.tex (5.1 KB)
- Data Replication Package EJ MS20210782/1 paper/EJ_MS20210782_design.tex (12.7 KB)
- Data Replication Package EJ MS20210782/1 paper/EJ_MS20210782_introduction.tex (10.9 KB)
- Data Replication Package EJ MS20210782/1 paper/EJ_MS20210782_main.tex (8.3 KB)
- Data Replication Package EJ MS20210782/1 paper/EJ_MS20210782_results.tex (15.1 KB)
- Data Replication Package EJ MS20210782/1 paper/Exhibits/EJ_MS20210782_figure1.tex (563 B)
- Data Replication Package EJ MS20210782/1 paper/Exhibits/EJ_MS20210782_table1.tex (2.3 KB)
- Data Replication Package EJ MS20210782/1 paper/Exhibits/EJ_MS20210782_table2.tex (3.4 KB)
- Data Replication Package EJ MS20210782/1 paper/Exhibits/lpm.tex (3.6 KB)
- Data Replication Package EJ MS20210782/1 paper/Figures/EJ_MS20210782_figure1a.pdf (54.1 KB)
- Data Replication Package EJ MS20210782/1 paper/Figures/EJ_MS20210782_figure1b.pdf (52.9 KB)
- Data Replication Package EJ MS20210782/1 paper/Figures/Materials.png (288.3 KB)
- Data Replication Package EJ MS20210782/1 paper/Figures/Materials_2.png (60.3 KB)
- Data Replication Package EJ MS20210782/1 paper/References.bib (109.8 KB)
- Data Replication Package EJ MS20210782/1 paper/bst/ejbib.bst (31.7 KB)
- Data Replication Package EJ MS20210782/1 paper/latexmkrc (49 B)
- Data Replication Package EJ MS20210782/2 appendices/EJ_MS20210782_online_appendix.pdf (1.2 MB)
- Data Replication Package EJ MS20210782/3 replication package/Additional documentation/Design/EJ MS20210782_Design.pdf (252.2 KB)
- Data Replication Package EJ MS20210782/3 replication package/Additional documentation/IRB/EJ MS20210782_CEEI_2019-077_Avis 19-592_Projet X 627.pdf (817.3 KB)
- Data Replication Package EJ MS20210782/3 replication package/Additional documentation/Instructions/EJ MS20210782_instructions.pdf (603.9 KB)
- Data Replication Package EJ MS20210782/3 replication package/Additional documentation/Instructions/EJ MS20210782_instructions_VideoSurvey.pdf (250.5 KB)
- Data Replication Package EJ MS20210782/3 replication package/Additional documentation/Instructions/EJ MS20210782_instructions_VideoSurvey_FR.pdf (157.5 KB)
- Data Replication Package EJ MS20210782/3 replication package/Additional documentation/Instructions/EJ MS20210782_instructions_Vignette_study.pdf (235.5 KB)
- Data Replication Package EJ MS20210782/3 replication package/Additional documentation/Instructions/EJ MS20210782_instructions_Vignette_study_FR.pdf (102.1 KB)
- Data Replication Package EJ MS20210782/3 replication package/Additional documentation/Pre-registration/Pre-Registration_d9288.pdf (181.2 KB)
- Data Replication Package EJ MS20210782/3 replication package/Additional documentation/Selection and eligibility of participants/Selection and eligibility of participants.pdf (69.3 KB)
- Data Replication Package EJ MS20210782/3 replication package/Data/master.csv (74.3 KB) — columns: obs,wobs,School,day,Child,children,children2,children3,scene,Condition,Violation,ViolationHelp,Help,Punishment,Helping,HelpingParents,kidshelped,male,hugo,Morning,witness,rich,Rain,Hot,inc_Q,povrate,response2,OwnChild,TIME,T10,boy,girl,numk…
- Data Replication Package EJ MS20210782/3 replication package/Data/survey1.csv (42.0 KB) — columns: obs,BirthYear,Children,Arron,Child,OrderHV,Male,Educ,Income,V,DP,H,VH,risk
- Data Replication Package EJ MS20210782/3 replication package/Data/survey2.csv (40.8 KB) — columns: obs,traitement,normlitter,normenforc,normperslitter,normpersenforc,gender,children,region,reasonteaching,reasonimage,reasonnorm,reasonother,reasonotherprecision,reasonno,reason1,reason2,reason3,reason4,male,age,belgium,earning,typecity,emot…
- Data Replication Package EJ MS20210782/3 replication package/Do/Data_analysis_202208.do (44.3 KB)
- Data Replication Package EJ MS20210782/3 replication package/Do/variables_codebook.xlsx (15.2 KB)
- Data Replication Package EJ MS20210782/3 replication package/Log/Log_output.log (325.0 KB)
- Data Replication Package EJ MS20210782/3 replication package/ReadMe.docx (33.8 KB)
- Data Replication Package EJ MS20210782/3 replication package/ReadMe.pdf (192.0 KB)
- Data Replication Package EJ MS20210782/3 replication package/Results/Figure1a.pdf (54.1 KB)
- Data Replication Package EJ MS20210782/3 replication package/Results/Figure1b.pdf (52.9 KB)
- Data Replication Package EJ MS20210782/3 replication package/Results/Table1.tex (1.8 KB)
- Data Replication Package EJ MS20210782/3 replication package/Results/Table2.tex (2.6 KB)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA10.tex (3.4 KB)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA11_A.tex (2.0 KB)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA11_B.tex (1.9 KB)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA11_C.tex (2.0 KB)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA12_A.tex (842 B)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA12_B.tex (842 B)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA12_C.tex (842 B)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA12_D.tex (458 B)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA13.tex (556 B)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA14.tex (586 B)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA2.tex (1.3 KB)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA3.tex (2.5 KB)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA4.tex (1.8 KB)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA5.tex (1.6 KB)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA6.tex (2.2 KB)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA7.tex (2.2 KB)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA8.tex (14.6 KB)
- Data Replication Package EJ MS20210782/3 replication package/Results/TableA9.tex (14.6 KB)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/seeded/2026-11-02-b/mount/brouwer_2022_teaching_norms' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
Installed packages (no network; nothing else can be installed): jsonlite, fixest, lfe, AER, ivreg, plm, estimatr, lme4, quantreg, car, sandwich, lmtest, clubSandwich, multiwayvcov, marginaleffects, MatchIt, optmatch, CBPS, WeightIt, cobalt, did, rdrobust, rddensity, Synth, modelsummary, stargazer, texreg, broom, tidyverse, dplyr, tidyr, readr, stringr, lubridate, data.table, haven, readxl, janitor, zoo, ggplot2, ggridges, ggrepel, gridExtra, cowplot, gtable, extrafont, sf, MASS, nnet, survival, splines, Matrix, boot, stats, utils.
Prefer fixest for fixed effects, IV and clustered SEs; use the other installed packages where the paper's method calls for them.
Set a deterministic seed with ``set.seed(42)`` for any randomness.
Do NOT access the internet; the container runs with --network none.
Do NOT shell out via system() / system2().
Emit RESULT:<name>=<value> lines to stdout at the end via cat().

## Original Replication Scripts
The replication package (the dataset directory) ships the authors' own analysis scripts, reproduced below.  These are the GROUND TRUTH for the exact estimating equation, variable names, sample restrictions, fixed effects, and standard-error clustering — follow them over anything reconstructed from the methodology summary, and prefer them over the paper's text where the two disagree.  Your job is to write R code that implements the SAME SPECIFICATION: translate what the scripts estimate, do not transliterate their syntax line by line (a Stata .do file's regression, e.g. `reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the equivalent fixest::feols() call in R).  Keep only the parts that produce the specific claims being reproduced; skip figure construction and unrelated robustness checks.  The scripts' data-file paths refer to the package's internal layout — resolve them against the dataset directory listed under Dataset Information.

Stata-to-fixest sample matching: feols() drops fixed-effect singletons by default, but Stata's `reg y x i.fe` / `xi:` dummies keep them.  Pass `fixef.rm = "none"` to every feols() call that has fixed effects, otherwise the observation count and the robust SEs drift from the paper's.  Stata's `, r` / `vce(robust)` is `vcov = "hetero"`.

### `Data Replication Package EJ MS20210782/3 replication package/Do/Data_analysis_202208.do`
```stata
********************************************************************************
*
*							GENERAL INFORMATION
*
********************************************************************************
*
*Data_analysis_202206.do  Stata 17 - August, 2022
*
*Thijs Brouwer, Fabio Galeotti, and Marie-Claire Villeval 2022. 
*Teaching Norms: Direct Evidence of Parental Transmission
* 
*Requires the following additional ado files:
*  - estout
*
* To install and ado file type: ssc install NAME_OF_FILE
*
* inputs:
*  - master.dta
*  - survey1.dta
*  - survey2.dta
*
* The structure of the do-file follows approximately the structure of the paper  
*
*
********************************************************************************
*
*							DEFINE WORKING FOLDERS
*
********************************************************************************

* Define path of working directory here:
global PATH "C:\Users\galeotti\Desktop\3 replication package"

		
*** Set the current directory:
cd "$PATH"
	
*** Declare working folders:
global Do 			"$PATH\Do"
global Data 		"$PATH\Data"
global Results 		"$PATH\Results"
global Log 			"$PATH\Log"

*** Declare Log file:
set more off
log close _all

log using "$Log\Log_output.log", name(Log_output) replace

********************************************************************************
*
*								DATA ANALYSIS
*
********************************************************************************


********************************************************************************
*								 MAIN PAPER
********************************************************************************
use "$Data\master.dta", clear


************	1.Introduction

*****Number of schools
by School, sort: gen nvals = _n == 1
count if nvals
drop nvals
sort obs

*****General summary statistics
tab Punishment Condition, col nof
tab Helping Condition, col nof

quietly sum Helping if Condition==3
quietly local H_A = r(mean)
quietly sum Helping if Condition==5
di "Drop in help in Alone condition: " round(`H_A'-r(mean),.01)

quietly sum Helping if Condition==4
quietly local H_C = r(mean)
quietly sum Helping if Condition==6
di "Drop in help in Child condition: " round(`H_C'-r(mean),.01)

************	3.Results

*****3.1 Data Description

***N. of days
by day, sort: gen nvals = _n == 1
count if nvals
drop nvals
sort obs

***N. of observations
tab Child

***Table 1
estpost sum male witness hugo rich Morning Rain Hot response2
eststo all
estpost sum male witness hugo rich Morning Rain Hot response2 if Child==0
eststo alone
estpost sum male witness hugo rich Morning Rain Hot response2 if Child==1
eststo child
estpost ttest male witness hugo rich Morning Rain Hot response2, by(Child)
eststo test

esttab all alone child test using "$Results\Table1.tex", replace booktabs cells("mean(pattern(1 1 1 0) fmt(%10.2fc)) b(star pattern(0 0 0 1))" "sd(par pattern(1 1 1 0)) se(par pattern(0 0 0 1))" ) label mlabels(All Alone Child Diff.) nomtitles star(* 0.1 ** 0.05 *** 0.01) collabels(none) alignment(rrrrr) varlabels(male "Male Target" witness "Witness" hugo "Male Actor" rich "Rich IRIS" Morning "Morning" Rain "Rain" Hot "Hot" response2 "Survey Response")

***Who are those who answered the survey?
tab response2
tab OwnChild if response2==1

*****3.2 Main Results

***Figure 1
replace Helping=. if Violation==1
replace Punishment=. if Help==1

preserve
collapse (mean) meanH=Helping meanP=Punishment meanHu=hugo (sd) sdH=Helping sdP=Punishment (count) n=hugo, by(Help Violation ViolationHelp Child)
	generate hiH = meanH + invttail(n-1,0.025)*(sdH / sqrt(n))
	generate loH = meanH - invttail(n-1,0.025)*(sdH / sqrt(n))

	generate hiP = meanP + invttail(n-1,0.025)*(sdP / sqrt(n))
	generate loP = meanP - invttail(n-1,0.025)*(sdP / sqrt(n))

    gen statep=0 if Help==1 & Child==0
    replace statep=0.5 if ViolationHelp==1 & Child==0
    replace statep=1.5 if Help==1 & Child==1
    replace statep=2 if ViolationHelp==1 & Child==1

   	replace meanH=round(meanH,0.01)
	format meanH %9.2f

	twoway 	(bar meanH statep if statep==0 & Help==1, fcolor(dkgreen*0.7) barwidth(0.5) lcolor(black)) ///
			(bar meanH statep if statep==0.5 & ViolationHelp==1, fcolor(sand*0.7) barwidth(0.5) lcolor(black)) ///
	   		(bar meanH statep if statep==1.5 & Help==1, fcolor(dkgreen*0.7) barwidth(0.5) lcolor(black)) ///
			(bar meanH statep if statep==2 & ViolationHelp==1, fcolor(sand*0.7) barwidth(0.5) lcolor(black)) ///
	   		(rcap hiH loH statep, lwidth(thin) color(gs6)) ///
			(scatter meanH statep if statep==0 | statep==1.5, msym(none) mlab(meanH) mlabformat(%9.2f)  mlabpos(6) mlabcolor(white) mlabstyle(p1) mlabsize(medsmall)) ///
			(scatter meanH statep if statep==0.5 | statep==2, msym(none) mlab(meanH) mlabformat(%9.2f)  mlabpos(6) mlabcolor(black) mlabstyle(p1) mlabsize(medsmall)), ///
	   text(0.6 0 "n = 101" 0.6 0.5 "n = 100" 0.6 1.5 "n = 100" 0.6 2 "n = 100") ///	
	   legend(order(1 "Help" 2 "Violation + Help")) ///
	   xlabel(0.25 "Alone" 1.75 "Child", noticks) xsize(4) ///
	   xtitle("") ytitle("Helping Rate") ///
	   graphregion(color(dknavy*0.05)) ///
	   plotregion(color(dknavy*0.05)) ///
	   yscale(range(0 0.6)) ylabel(0 0.1 to 0.6, format(%9.1gc) glc(dknavy*0.1) glw(thin) angle(horizontal))
	   graph export "$Results\Figure1b.pdf", as(pdf) replace	  
	   
	   replace statep=0 if Violation==1 & Child==0
	   replace statep=1.5 if Violation==1 & Child==1
	   	   
	twoway 	(bar meanP statep if statep==0 & Violation==1, fcolor(dknavy*0.7) barwidth(0.5) lcolor(black)) ///
			(bar meanP statep if statep==0.5 & ViolationHelp==1, fcolor(sand*0.7) barwidth(0.5) lcolor(black)) ///
	   		(bar meanP statep if statep==1.5 & Violation==1, fcolor(dknavy*0.7) barwidth(0.5) lcolor(black)) ///
			(bar meanP statep if statep==2 & ViolationHelp==1, fcolor(sand*0.7) barwidth(0.5) lcolor(black)) ///
	   		(rcap hiP loP statep, lwidth(thin) color(gs6)) ///
			(scatter meanP statep if statep==0 | statep==1.5, msym(none) mlab(meanP) mlabformat(%9.2f)  mlabpos(6) mlabcolor(white) mlabstyle(p1) mlabsize(medsmall)) ///
			(scatter meanP statep if statep==0.5 | statep==2, msym(none) mlab(meanP) mlabformat(%9.2f)  mlabpos(6) mlabcolor(black) mlabstyle(p1) mlabsize(medsmall)), ///
	   text(0.6 0 "n = 100" 0.6 0.5 "n = 100" 0.6 1.5 "n = 100" 0.6 2 "n = 100") ///	
	   legend(order(1 "Violation" 2 "Violation + Help")) ///
	   xlabel(0.25 "Alone" 1.75 "Child", noticks) xsize(4) ///
	   xtitle("") ytitle("Punishment Rate") ///
	   graphregion(color(dknavy*0.05)) ///
	   plotregion(color(dknavy*0.05)) ///
	   yscale(range(0 0.6)) ylabel(0 0.1 to 0.6, format(%9.1gc) glc(dknavy*0.1) glw(thin) angle(horizontal))
	   graph export "$Results\Figure1a.pdf", as(pdf) replace
restore

***Chi^2 tests
tab Punishment Child if Violation==1, chi2
tab Helping Child if Help==1, chi2

*Drop in punishment between in V+H vs. V
tab Punishment Condition if Condition==1 | Condition==5, chi2
tab Punishment Condition if Condition==2 | Condition==6, chi2

*Drop in helping between in V+H vs. H
tab Helping Condition if Condition==3 | Condition==5, chi2
tab Helping Condition if Condition==4 | Condition==6, chi2

*Helping rate in V+H: Alone vs. Child
tab Helping Condition if Condition==5 | Condition==6, chi2

***Table 2
global controls i.male i.hugo i.Morning i.witness i.rich i.Rain i.Hot

eststo regp1: reg Punishment i.Child##i.ViolationHelp if Help==0, cluster(School)
eststo regp2: reg Punishment i.Child##i.ViolationHelp $controls if Help==0, cluster(School)
eststo regp3: reg Helping i.Child##i.ViolationHelp if Violation==0, cluster(School)
eststo regp4: reg Helping i.Child##i.ViolationHelp $controls if Violation==0, cluster(School)


esttab regp1 regp2 regp3 regp4 using "$Results\Table2.tex", replace booktabs cells(b(star pattern(1 1 1) fmt(%10.2fc)) se(par pattern(1 1 1))) label starlevels(* 0.10 ** 0.05 *** 0.01) nomtitles collabels(none) scalars("N Observations" "N_clust Clusters" "r2 \$R^2\$" "F \$F\$" "df_r df")  sfmt(%9.0g %9.0g  %9.2f %9.2f %9.0g) alignment(rrrr) nobaselevels varlabels(1.Child "Child" 1.ViolationHelp "VH" 1.Child#1.ViolationHelp "Child $\times$ VH" 1.male "Male Target" 1.hugo "Male Actor" 1.Morning "Morning" 1.witness "Witness" 1.witness#1.Child "Witness $\times$ Child" 1.rich "Rich area" 1.Rain "Rain" 1.Hot "Hot" _cons "Constant")

***Regressions with presence of a witness as treatment variable in the Alone condition

reg Punishment i.witness##i.ViolationHelp $controls if Help==0 & Child==0, cluster(School)
reg Helping i.witness##i.ViolationHelp $controls if Violation==0 & Child==0, cluster(School)

*******************************************************************************
*						ON-LINE APPENDIX (FIELD)
********************************************************************************

*****A.1 Additional Information

***Power Analysis and Number of Observations
power twoproportions 0.17, alpha(0.05) test(chi2) n1(100) n2(100) power(.80) effect(ratio)
power twoproportions 0.397, alpha(0.05) test(chi2) n1(100) n2(100) power(.80) effect(ratio)
power twoproportions 0.397 0.186, alpha(0.05) test(chi2) n1(100) n2(100)

*****A.4 Supplementary Analyses

***Table A2

estpost tabstat response2 if Morning==1 & Child==0, by(scene) statistics(mean sem) columns(statistics) listwise
eststo alone_morning
estpost tabstat response2 if Morning==1 & Child==1, by(scene) statistics(mean sem) columns(statistics) listwise
eststo child_morning
estpost tabstat response2 if Morning==1, by(scene) statistics(mean sem) columns(statistics) listwise
matrix p_chi2 = J(1,4 ,.)
	forvalue i=1(1)3{
	tab response2 Child if Morning==1 & scene==`i', chi2
	matrix p_chi2[1,`i'] = r(p)
}
tab response2 Child if Morning==1, chi2
matrix p_chi2[1,4] = r(p)
matrix colnames p_chi2 = "Help" "Violation" "Violation+Help" "Total"
estadd matrix p_chi2 = p_chi2, replace
eststo all_morning

estpost tabstat response2 if Morning==0 & Child==0, by(scene) statistics(mean sem) columns(statistics) listwise
eststo alone_afternoon
estpost tabstat response2 if Morning==0 & Child==1, by(scene) statistics(mean sem) columns(statistics) listwise
eststo child_afternoon
estpost tabstat response2 if Morning==0, by(scene) statistics(mean sem) columns(statistics) listwise
matrix p_chi2 = J(1,4 ,.)
	forvalue i=1(1)3{
	tab response2 Child if Morning==0 & scene==`i', chi2
	matrix p_chi2[1,`i'] = r(p)
}
tab response2 Child if Morning==0, chi2
matrix p_chi2[1,4] = r(p)
matrix colnames p_chi2 = "Help" "Violation" "Violation+Help" "Total"
estadd matrix p_chi2 = p_chi2, replace
eststo all_afternoon

esttab alone_morning child_morning all_morning alone_afternoon child_afternoon all_afternoon using "$Results\TableA2.tex", replace cells("mean(pattern(1 1 1 1 1 1) fmt(%10.2fc)) p_chi2(pattern(0 0 1 0 0 1) fmt(%10.3fc))" "semean(par pattern(1 1 1 1 1 1))") noobs mgroups("Morning" "Afternoon", pattern(1 0 0 1 0 0) prefix(\multicolumn{4}{c}{) suffix(})) nomtitles alignment(rrrrrr) nonumbers mlabels(Alone Child All Alone Child All) nomtitle collabels(none)


*Additional tests
tab response2 Child, chi2
tab response2 Child if Morning==0, chi2
tab response2 scene if scene!=3 , chi2 col nof
tab response2 scene if scene!=2 , chi2 col nof

***Correlation between responsing to survey and helping in Help treatment

reg response2 Helping if Help==1 & Child==0
reg response2 Helping if Help==1 & Child==1


***Table A3

estpost sum OwnChild boy girl numkids childage3 childage4 childage5 childage6 childage7 childage8 childage9 childage10 childage11 if response2==1
eststo all
estpost sum OwnChild boy girl numkids childage3 childage4 childage5 childage6 childage7 childage8 childage9 childage10 childage11 if Child==0 & response2==1
eststo alone
estpost sum OwnChild boy girl numkids childage3 childage4 childage5 childage6 childage7 childage8 childage9 childage10 childage11 if Child==1 & response2==1
eststo child
estpost ttest OwnChild boy girl numkids childage3 childage4 childage5 childage6 childage7 childage8 childage9 childage10 childage11 if response2==1, by(Child)
eststo test

esttab all alone child test using "$Results\TableA3.tex", replace booktabs cells("mean(pattern(1 1 1 0) fmt(%10.2fc)) b(star pattern(0 0 0 1))" "sd(par pattern(1 1 1 0)) se(par pattern(0 0 0 1))" ) label mlabels(All Alone Child Diff.) nomtitles star(* 0.1 ** 0.05 *** 0.01) collabels(none) alignment(rrrrr) varlabels(OwnChild "Own Child" boy "Son" girl "Daughter" numkids "No. of Children" childage3 "Child Age = 3" childage4 "Child Age = 4" childage5 "Child Age = 5" childage6 "Child Age = 6" childage7 "Child Age = 7" childage8 "Child Age = 8" childage9 "Child Age = 9" childage10 "Child Age = 10" childage11 "Child Age = 11") noobs

***Table A4

eststo regp1: reg Punishment i.Child##(i.ViolationHelp i.witness) i.male i.hugo i.Morning i.rich i.Rain i.Hot if Help==0, cluster(School)
eststo regp2: reg Helping i.Child##(i.ViolationHelp i.witness)  i.male i.hugo i.Morning i.rich i.Rain i.Hot if Violation==0, cluster(School)

esttab regp1 regp2 using "$Results\TableA4.tex", replace booktabs cells(b(star pattern(1 1 1) fmt(%10.2fc)) se(par pattern(1 1 1))) label starlevels(* 0.10 ** 0.05 *** 0.01) nomtitles collabels(none) scalars("N Observations" "N_clust Clusters" "r2 \$R^2\$" "F \$F\$" "df_r df")  sfmt(%9.0g %9.0g  %9.2f %9.2f %9.0g) alignment(rrrr) nobaselevels varlabels(1.Child "Child" 1.ViolationHelp "VH" 1.Child#1.ViolationHelp "Child $\times$ VH" 1.male "Male Target" 1.hugo "Male Actor" 1.Morning "Morning" 1.witness "Witness" 1.Child#1.witness "Witness $\times$ Child" 1.rich "Rich area" 1.Rain "Rain" 1.Hot "Hot" _cons "Constant")


***Table A5

eststo regp1: reg Punishment i.Child i.male i.hugo i.Morning i.witness i.rich i.Rain i.Hot if Violation==1, cluster(School)
eststo regp2: reg Punishment i.male##i.Child i.hugo i.Morning i.witness i.rich i.Rain i.Hot if Violation==1, cluster(School)

esttab regp1 regp2 using "$Results\TableA5.tex", replace booktabs cells(b(star pattern(1 1 1) fmt(%10.2fc)) se(par pattern(1 1 1))) label starlevels(* 0.10 ** 0.05 *** 0.01) nomtitles collabels(none) scalars("N Observations" "N_clust Clusters" "r2 \$R^2\$" "F \$F\$" "df_r df")  sfmt(%9.0g %9.0g  %9.2f %9.2f %9.0g)  alignment(rrrr) nobaselevels varlabels(1.Child "Child" 1.male "Male Target" 1.male#1.Child "Child $\times$ Male Target" 1.hugo "Male Actor" 1.Morning "Morning" 1.witness "Witness" 1.witness#1.Child "Witness $\times$ Child" 1.rich "Rich area" 1.Rain "Rain" 1.Hot "Hot" _cons "Constant") order(1.Child 1.male 1.male#1.Child)

test 1.Child 1.Child#1.male


***Table A6

global controls i.male i.hugo i.Morning i.witness i.rich i.Rain i.Hot

logit Helping i.Child##i.ViolationHelp $controls if Violation==0, cluster(School)
scalar pr2 = e(r2_p)
scalar clust = e(N_clust)
scalar wald_chi2 = e(chi2)
margins r.Child, dydx(ViolationHelp) post
scalar CvsA= e(chi2)[1,2]
quietly logit Helping i.Child##i.ViolationHelp $controls if Violation==0, cluster(School)
eststo reghl1: margins, dydx(*) at(Child=0 ViolationHelp=0) post
estadd scalar r2_p = pr2
estadd scalar N_clust = clust
estadd scalar chi2 = wald_chi2
estadd scalar chi2_CvsA = CvsA
logit Helping i.Child##i.ViolationHelp $controls if Violation==0, cluster(School)
eststo reghl2: margins, dydx(*) at(Child=1 ViolationHelp=0) post

logit Punishment i.Child##i.ViolationHelp $controls if Help==0, cluster(School)
scalar pr2 = e(r2_p)
scalar clust = e(N_clust)
scalar wald_chi2 = e(chi2)
margins r.Child, dydx(ViolationHelp) post
scalar CvsA= e(chi2)[1,2]
quietly logit Punishment i.Child##i.ViolationHelp $controls if Help==0, cluster(School)
eststo regpl1: margins, dydx(*) at(Child=0 ViolationHelp=0) post
estadd scalar r2_p = pr2
estadd scalar N_clust = clust
estadd scalar chi2 = wald_chi2
estadd scalar chi2_CvsA = CvsA
logit Punishment i.Child##i.ViolationHelp $controls if Help==0, cluster(School)
eststo regpl2: margins, dydx(*) at(Child=1 ViolationHelp=0) post

esttab regpl1 regpl2 reghl1 reghl2 using "$Results\TableA6.tex", replace booktabs cells(b(star pattern(1 1 1) fmt(%10.2fc)) se(par pattern(1 1 1))) label starlevels(* 0.10 ** 0.05 *** 0.01) nomtitles collabels(none) scalars("chi2_CvsA VH\$_C\$ vs. VH\$_A\$" "N Observations" "N_clust Clusters" "r2_p (Pseudo) \$R^2\$" "chi2 Wald \$\chi^2\$") sfmt(%9.2f %9.0g %9.0g %9.3f %9.2f) order(1.Child 1.ViolationHelp) alignment(rrrr) nobaselevels varlabels(1.Child "Child" 1.ViolationHelp "VH" 1.male "Male Target" 1.hugo "Male Actor" 1.Morning "Morning" 1.witness "Witness" 1.rich "Rich area" 1.Rain "Rain" 1.Hot "Hot" _cons "Constant") 
//Note: In the "VHC vs. VHA" row, levels of significance (represented by stars) are added manually based on the p-values (P>chi2) obtained from the command lines 312 and 297. 

***Table A7

global controls i.male i.hugo i.Morning i.witness i.rich i.Rain i.Hot

preserve
drop if OwnChild==0
eststo reg4: reg Helping i.Child##i.ViolationHelp $controls if Violation==0, cluster(School)
eststo reg1: reg Punishment i.Child##i.ViolationHelp $controls if Help==0, cluster(School)
restore

eststo reg5: reg Helping i.Child##i.ViolationHelp $controls if Violation==0 & children<2, cluster(School)
eststo reg2: reg Punishment i.Child##i.ViolationHelp $controls if Help==0  & children<2, cluster(School)

eststo reg6: reg Helping i.Child##i.ViolationHelp $controls if Violation==0 & witness==0, cluster(School)
eststo reg3: reg Punishment i.Child##i.ViolationHelp $controls if Help==0 & witness==0, cluster(School)

eststo reg7: reg HelpingParents i.Child##i.ViolationHelp $controls if Violation==0, cluster(School)

esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 using "$Results\TableA7.tex", replace booktabs cells(b(star pattern(1 1 1) fmt(%10.2fc)) se(par pattern(1 1 1))) label starlevels(* 0.10 ** 0.05 *** 0.01) nomtitles collabels(none) scalars("N Observations" "N_clust Clusters" "r2 \$R^2\$" "F \$F\$" "df_r df")  sfmt(%9.0g %9.0g  %9.2f %9.2f %9.0g) alignment(rrrr) nobaselevels varlabels(1.Child "Child" 1.ViolationHelp "VH" 1.Child#1.ViolationHelp "Child $\times$ VH" _cons "Constant") indicate(Controls = 1.male 1.hugo 1.Morning 1.witness 1.rich 1.Rain 1.Hot) drop(0.witness)
	
tab kidshelped scene
	 
***Table A8

global controls i.male i.hugo i.Morning i.witness i.rich i.Rain i.Hot

eststo reg1: reg Punishment i.Child##i.ViolationHelp $controls if Help==0, cluster(School)
eststo reg2: reg Punishment i.children##i.ViolationHelp $controls if Help==0, cluster(School)
eststo reg3: reg Punishment i.children2##i.ViolationHelp $controls if Help==0, cluster(School)
eststo reg4: reg Punishment i.children3##i.ViolationHelp $controls if Help==0, cluster(School)	 
eststo reg5: reg Punishment i.Child##(i.ViolationHelp i.male i.hugo) $controls if Help==0, cluster(School)
eststo reg6: reg Punishment i.Child##(i.ViolationHelp) i.male##i.hugo $controls if Help==0, cluster(School)
eststo reg7: reg Punishment i.Child##(i.ViolationHelp i.rich) $controls if Help==0, cluster(School)

local controls2 $controls
local not i.rich
local controls2: list controls2- not

eststo reg8: reg Punishment i.Child##(i.ViolationHelp i.inc_Q) `controls2' if Help==0, cluster(School)
 
esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 reg8 using "$Results\TableA8.tex", replace booktabs cells(b(star pattern(1 1 1) fmt(%10.2fc)) se(par pattern(1 1 1))) label starlevels(* 0.10 ** 0.05 *** 0.01) nomtitles collabels(none) scalars("N Observations" "N_clust Clusters" "r2 \$R^2\$" "F \$F\$" "df_r df")  sfmt(%9.0g %9.0g  %9.2f %9.2f %9.0g) alignment(rrrr) nobaselevels varlabels(1.Child "Child" 1.children "1 Child" 1.children2 "1 Boy" 2.children2 "1 Girl" 1.children3 "1 Child Age $\leq$ 5" 2.children3 "5 $<$ 1 Child Age $\leq$ 8" 3.children3 "1 Child Age $>$ 8" 2.children "2 Children" 3.children "3+ children" 3.children2 "2 children" 4.children2 "3+ children" 1.ViolationHelp "VH" 1.Child#1.ViolationHelp "VH $\times$ Child" 1.children#1.ViolationHelp "VH $\times$ 1 Child" 2.children#1.ViolationHelp "VH $\times$ 2 Children" 3.children#1.ViolationHelp "VH $\times$ 3+ Children" 1.children2#1.ViolationHelp "VH $\times$ 1 Boy" 2.children2#1.ViolationHelp "VH $\times$ 1 Girl" 3.children2#1.ViolationHelp "VH $\times$ 2 Children" 4.children2#1.ViolationHelp "VH $\times$ 3+ Children" 1.children3#1.ViolationHelp "VH $\times$ 1 Child Age $\leq$ 5" 2.children3#1.ViolationHelp "VH $\times$ 5 $<$ 1 Child Age $\leq$ 8" 3.children3#1.ViolationHelp "1 Child Age $>$ 9" 4.children3#1.ViolationHelp "VH $\times$ 2 Children" 5.children3#1.ViolationHelp "VH $\times$ 3+ Children" 1.male "Male Target" 1.Child#1.male "Male Target $\times$ Child" 1.hugo "Male Actor" 1.Child#1.hugo "Male Actor $\times$ Child" 1.male#1.hugo "Male Actor $\times$ Male target" 1.Morning "Morning" 1.witness "Witness" 1.rich "Rich area" 1.Child#1.rich "Rich area $\times$ Child" 1.Rain "Rain" 1.Hot "Hot" _cons "Constant" 2.inc_Q "Medium Low Income" 3.inc_Q "Medium High Income" 4.inc_Q "High Income" 1.Child#2.inc_Q "Medium Low Income $\times$ Child" 1.Child#3.inc_Q "Medium High Income $\times$ Child" 1.Child#4.inc_Q "High Income $\times$ Child") order(1.Child 1.children 1.children2 2.children2 1.children3 2.children3 3.children3 2.children 3.children 3.children2 4.children2 4.children3 5.children3 1.ViolationHelp 1.Child#1.ViolationHelp *.children#1.ViolationHelp *.children2#1.ViolationHelp *.children3#1.ViolationHelp 1.male 1.Child#1.male 1.hugo  1.Child#1.hugo 1.male#1.hugo 1.rich 1.Child#1.rich *.inc_Q 1.Child#*.inc_Q 1.Morning 1.witness 1.Rain 1.Hot) noomit	

***Table A9	 

global controls i.male i.hugo i.Morning i.witness i.rich i.Rain i.Hot

eststo reg1: reg Helping i.Child##i.ViolationHelp $controls if Violation==0, cluster(School)
eststo reg2: reg Helping i.children##i.ViolationHelp $controls if Violation==0, cluster(School)
eststo reg3: reg Helping i.children2##i.ViolationHelp $controls if Violation==0, cluster(School)
eststo reg4: reg Helping i.children3##i.ViolationHelp $controls if Violation==0, cluster(School)
eststo reg5: reg Helping i.Child##(i.ViolationHelp i.male i.hugo) $controls if Violation==0, cluster(School)
eststo reg6: reg Helping i.Child##(i.ViolationHelp) i.male##i.hugo $controls if Violation==0, cluster(School)
eststo reg7: reg Helping i.Child##(i.ViolationHelp i.rich) $controls if Violation==0, cluster(School)

local controls2 $controls
local not i.rich
local controls2: list controls2- not

eststo reg8: reg Helping i.Child##(i.ViolationHelp i.inc_Q) `controls2' if Violation==0, cluster(School)
 
esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 reg8 using "$Results\TableA9.tex", replace booktabs cells(b(star pattern(1 1 1) fmt(%10.2fc)) se(par pattern(1 1 1))) label starlevels(* 0.10 ** 0.05 *** 0.01) nomtitles collabels(none) scalars("N Observations" "N_clust Clusters" "r2 \$R^2\$" "F \$F\$" "df_r df")  sfmt(%9.0g %9.0g  %9.2f %9.2f %9.0g) alignment(rrrr) nobaselevels varlabels(1.Child "Child" 1.children "1 Child" 1.children2 "1 Boy" 2.children2 "1 Girl" 1.children3 "1 Child Age $\leq$ 5" 2.children3 "5 $<$ 1 Child Age $\leq$ 8" 3.children3 "1 Child Age $>$ 8" 2.children "2 Children" 3.children "3+ children" 3.children2 "2 children" 4.children2 "3+ children" 1.ViolationHelp "VH" 1.Child#1.ViolationHelp "VH $\times$ Child" 1.children#1.ViolationHelp "VH $\times$ 1 Child" 2.children#1.ViolationHelp "VH $\times$ 2 Children" 3.children#1.ViolationHelp "VH $\times$ 3+ Children" 1.children2#1.ViolationHelp "VH $\times$ 1 Boy" 2.children2#1.ViolationHelp "VH $\times$ 1 Girl" 3.children2#1.ViolationHelp "VH $\times$ 2 Children" 4.children2#1.ViolationHelp "VH $\times$ 3+ Children" 1.children3#1.ViolationHelp "VH $\times$ 1 Child Age $\leq$ 5" 2.children3#1.ViolationHelp "VH $\times$ 5 $<$ 1 Child Age $\leq$ 8" 3.children3#1.ViolationHelp "1 Child Age $>$ 9" 4.children3#1.ViolationHelp "VH $\times$ 2 Children" 5.children3#1.ViolationHelp "VH $\times$ 3+ Children" 1.male "Male Target" 1.Child#1.male "Male Target $\times$ Child" 1.hugo "Male Actor" 1.Child#1.hugo "Male Actor $\times$ Child" 1.male#1.hugo "Male Actor $\times$ Male target" 1.Morning "Morning" 1.witness "Witness" 1.rich "Rich area" 1.Child#1.rich "Rich area $\times$ Child" 1.Rain "Rain" 1.Hot "Hot" _cons "Constant" 2.inc_Q "Medium Low Income" 3.inc_Q "Medium High Income" 4.inc_Q "High Income" 1.Child#2.inc_Q "Medium Low Income $\times$ Child" 1.Child#3.inc_Q "Medium High Income $\times$ Child" 1.Child#4.inc_Q "High Income $\times$ Child") order(1.Child 1.children 1.children2 2.children2 1.children3 2.children3 3.children3 2.children 3.children 3.children2 4.children2 4.children3 5.children3 1.ViolationHelp 1.Child#1.ViolationHelp *.children#1.ViolationHelp *.children2#1.ViolationHelp *.children3#1.ViolationHelp 1.male 1.Child#1.male 1.hugo  1.Child#1.hugo 1.male#1.hugo 1.rich 1.Child#1.rich *.inc_Q 1.Child#*.inc_Q 1.Morning 1.witness 1.Rain 1.Hot) noomit	

***Appendix A.4.6 (additional statistics not contained in tables)

*Number of Children 
tab children scene if Child==1

*Child's Gender
tab children2 if children==1, miss

*Child's Age
tab children3 if children==1, miss

*Income Effects (additional regressions not reported in paper)
local controls2 i.male i.hugo i.Morning i.witness i.Rain i.Hot
reg Punishment i.Child##(i.ViolationHelp c.povrate) `controls2' if Help==0, cluster(School)
reg Helping i.Child##(i.ViolationHelp c.povrate) `controls2' if Violation==0, cluster(School)


***Table A10

*Timing
global controls i.male i.hugo i.Morning i.witness i.rich i.Rain i.Hot

gen TIME_arriving=(Child==1)*(Morning==1)*TIME+(Child==0)*(Morning==0)*TIME
gen TIME_leaving=(Child==0)*(Morning==1)*TIME+(Child==1)*(Morning==0)*TIME

eststo reg1: reg Punishment i.Child##i.ViolationHelp c.TIME_arriving c.TIME_leaving $controls if Help==0, cluster(School)
eststo reg4: reg Helping i.Child##i.ViolationHelp c.TIME_arriving c.TIME_leaving $controls if Violation==0, cluster(School)

gen T10_arriving=(Child==1)*(Morning==1)*T10+(Child==0)*(Morning==0)*T10
gen T10_leaving=(Child==0)*(Morning==1)*T10+(Child==1)*(Morning==0)*T10

eststo reg2: reg Punishment i.Child##i.ViolationHelp c.T10_arriving c.T10_leaving $controls if Help==0, cluster(School) 
eststo reg5: reg Helping i.Child##i.ViolationHelp c.T10_arriving c.T10_leaving $controls if Violation==0, cluster(School) 

gen wobs_arriving=(Child==1)*(Morning==1)*wobs+(Child==0)*(Morning==0)*wobs
gen wobs_leaving=(Child==0)*(Morning==1)*wobs+(Child==1)*(Morning==0)*wobs

eststo reg3: reg Punishment i.Child##i.ViolationHelp c.wobs_arriving c.wobs_leaving $controls if Help==0, cluster(School) 
eststo reg6: reg Helping i.Child##i.ViolationHelp c.wobs_arriving c.wobs_leaving $controls if Violation==0, cluster(School) 


esttab reg1 reg2 reg3 reg4 reg5 reg6 using "$Results\TableA10.tex", replace booktabs cells(b(star pattern(1 1 1) fmt(%10.3fc)) se(par pattern(1 1 1))) label starlevels(* 0.10 ** 0.05 *** 0.01) nomtitles collabels(none) scalars("N Observations" "N_clust Clusters" "r2 \$R^2\$" "F \$F\$") sfmt(%9.0g %9.0g  %9.2f %9.2f) alignment(rrrr) nobaselevels varlabels(1.Child "Child" 1.ViolationHelp "VH" 1.Child#1.ViolationHelp "Child $\times$ VH" TIME_arriving "Time $\times$ Arriving" TIME_leaving "Time $\times$ Leaving" T10_arriving "T10 $\times$ Arriving" T10_leaving "T10 $\times$ Leaving" wobs_arriving "No. $\times$ Arriving" wobs_leaving "No. $\times$ Leaving" _cons "Constant") indicate(Controls = 1.male 1.hugo 1.Morning 1.witness 1.rich 1.Rain 1.Hot) mgroups("Punishment" "Helping", pattern(1 0 0 1 0 0) prefix(\multicolumn{3}{c}{) suffix(}))

***Appendix A.4.7 Analysis of Timing Effects (additional regressions)

global controls i.male i.hugo i.Morning i.witness i.rich i.Rain i.Hot

reg Punishment i.Child##(i.ViolationHelp i.Morning)  $controls if Help==0, cluster(School)
reg Helping i.Child##(i.ViolationHelp i.Morning)  $controls if Violation==0, cluster(School)

*******************************************************************************
*						ON-LINE APPENDIX (SURVEY 1)
********************************************************************************

use "$Data\survey1.dta", clear

***Appendix A.5.1 (statistics reported in text)

sum V if Child==1
sum V if Child==0

signrank H = VH if Child==1
signrank H = VH if Child==0

foreach i in V DP H VH {
	ranksum `i', by(Child)
}

foreach i in V DP H VH {
	ranksum `i' if risk==1, by(Child)
}


signrank H = VH if Child==1 & risk==1
signrank H = VH if Child==0 & risk==1

foreach i in V DP H VH {
	ranksum `i' if risk==1, by(Child)
}


signrank H = VH if Child==1 & risk==0
signrank H = VH if Child==0 & risk==0

foreach i in V DP H VH {
	ranksum `i' if risk==0, by(Child)
}
*Additional tests
global controls c.BirthYear i.Male c.Educ c.Income c.Children i.OrderHV i.Arron

foreach i in V DP H VH {
	reg `i' Child $controls, robust
	}

***Table A11

*generate dummies
foreach z of varlist V DP H VH {
	local j=1
	foreach i in -1 -0.6 -0.2 0.2 0.6 1 {
		gen `z'`j' = `z'>`i'-.1 & `z'<`i'+.1  //this is to take into account that the decimals are not precise
	local j=`j'+1
	}
}

**Panel A: All respondents

*generate table for Child condition
estpost sum V DP H VH if Child==1

matrix freq = J(6,4 ,.)
forvalue j=1(1)6{
	local n=1
	foreach i of varlist V DP H VH {
	sum `i'`j' if Child==1
	matrix freq[`j',`n'] = r(mean)
	local n=`n'+1
}
}

matrix colnames freq = "V" "DP" "H" "VH"


forvalue j=1(1)6{
estadd matrix freq`j' = freq[`j',1..4]
}

*Add test H vs VH
signrank H=VH if Child==1
estadd scalar test = r(z)

eststo Child


*generate table for Alone condition
estpost sum V DP H VH if Child==0

matrix freq = J(6,4 ,.)
forvalue j=1(1)6{
	local n=1
	foreach i of varlist V DP H VH {
	sum `i'`j' if Child==0
	matrix freq[`j',`n'] = r(mean)
	local n=`n'+1
}
}

matrix colnames freq = "V" "DP" "H" "VH"

forvalue j=1(1)6{
estadd matrix freq`j' = freq[`j',1..4]
}

local j=1
matrix z_rank = J(1,4 ,.)
	foreach i of varlist V DP H VH {
	ranksum `i', by(Child)
	matrix z_rank[1,`j'] = r(z)
	local j=`j'+1
}

matrix colnames z_rank = "V" "DP" "H" "VH"

estadd matrix z_rank = z_rank

*Add test H vs VH
signrank H=VH if Child==0
estadd scalar test = r(z)

eststo Alone


esttab Child Alone using "$Results\TableA11_A.tex", replace  cells("mean(pattern(1 1) fmt(%10.2fc)) freq1(pattern(1 1) fmt(%10.2fc)) freq2(pattern(1 1) fmt(%10.2fc)) freq3(pattern(1 1) fmt(%10.2fc)) freq4(pattern(1 1) fmt(%10.2fc)) freq5(pattern(1 1) fmt(%10.2fc)) freq6(pattern(1 1) fmt(%10.2fc)) z_rank(pattern(0 1) fmt(%10.2fc))") label collabels("Mean" "-1" "-0.6" "-0.2" "+0.2" "+0.6" "+1" "Rank-sum test") nomtitles star(* 0.1 ** 0.05 *** 0.01) varlabels(V "Violation" DP "Direct Punishment" H "No Help" VH "No Help (Violation)") mgroups("CHILD CONDITION" "ALONE CONDITION", pattern(1  1) prefix(\multicolumn{7}{c}{) suffix(})) nonumbers booktabs stats(N test, fmt(%10.0fc %10.2fc) labels("Observations" "NH vs. NH(V)") star(test))
//Note: In the "Runk-sum test (z)" column, levels of significance (represented by stars) are added manually based on the p-values obtained from the command line 545. Similarly, in the "NH vs. NH(V)" row, levels of significance (represented by stars) are added manually based on the p-values obtained from the command lines 517 and 555. 

**Panel B: Scenario w/ risk

*generate table for Child condition
estpost sum V DP H VH if Child==1 & risk==1

matrix freq = J(6,4 ,.)
forvalue j=1(1)6{
	local n=1
	foreach i of varlist V DP H VH {
	sum `i'`j' if Child==1 & risk==1
	matrix freq[`j',`n'] = r(mean)
	local n=`n'+1
}
}

matrix colnames freq = "V" "DP" "H" "VH"


forvalue j=1(1)6{
estadd matrix freq`j' = freq[`j',1..4]
}

*Add test H vs VH
signrank H=VH if Child==1 & risk==1
estadd scalar test = r(z)

eststo Child


*generate table for Alone condition
estpost sum V DP H VH if Child==0 & risk==1

matrix freq = J(6,4 ,.)
forvalue j=1(1)6{
	local n=1
	foreach i of varlist V DP H VH {
	sum `i'`j' if Child==0 & risk==1
	matrix freq[`j',`n'] = r(mean)
	local n=`n'+1
}
}

matrix colnames freq = "V" "DP" "H" "VH"

forvalue j=1(1)6{
estadd matrix freq`j' = freq[`j',1..4]
}

local j=1
matrix z_rank = J(1,4 ,.)
	foreach i of varlist V DP H VH {
	ranksum `i' if risk==1, by(Child)
	matrix z_rank[1,`j'] = r(z)
	local j=`j'+1
}

matrix colnames z_rank = "V" "DP" "H" "VH"

estadd matrix z_rank = z_rank

*Add test H vs VH
signrank H=VH if Child==0 & risk==1
estadd scalar test = r(z)

eststo Alone


esttab Child Alone using "$Results\TableA11_B.tex", replace  cells("mean(pattern(1 1) fmt(%10.2fc)) freq1(pattern(1 1) fmt(%10.2fc)) freq2(pattern(1 1) fmt(%10.2fc)) freq3(pattern(1 1) fmt(%10.2fc)) freq4(pattern(1 1) fmt(%10.2fc)) freq5(pattern(1 1) fmt(%10.2fc)) freq6(pattern(1 1) fmt(%10.2fc)) z_rank(pattern(0 1) fmt(%10.2fc))") label collabels("Mean" "-1" "-0.6" "-0.2" "+0.2" "+0.6" "+1" "Rank-sum test") nomtitles star(* 0.1 ** 0.05 *** 0.01) varlabels(V "Violation" DP "Direct Punishment" H "No Help" VH "No Help (Violation)") mgroups("CHILD CONDITION" "ALONE CONDITION", pattern(1  1) prefix(\multicolumn{7}{c}{) suffix(})) nonumbers booktabs stats(N test, fmt(%10.0fc %10.2fc) labels("Observations" "NH vs. NH(V)"))
//Note: In the "Runk-sum test (z)" column, levels of significance (represented by stars) are added manually based on the p-values obtained from the command line 615. Similarly, in the "NH vs. NH(V)" row, levels of significance (represented by stars) are added manually based on the p-values obtained from the command lines 587 and 625. 

**Panel C: Scenario w/o risk

*generate table for Child condition
estpost sum V DP H VH if Child==1 & risk==0

matrix freq = J(6,4 ,.)
forvalue j=1(1)6{
	local n=1
	foreach i of varlist V DP H VH {
	sum `i'`j' if Child==1 & risk==0
	matrix freq[`j',`n'] = r(mean)
	local n=`n'+1
}
}

matrix colnames freq = "V" "DP" "H" "VH"


forvalue j=1(1)6{
estadd matrix freq`j' = freq[`j',1..4]
}

*Add test H vs VH
signrank H=VH if Child==1 & risk==0
estadd scalar test = r(z)

eststo Child


*generate table for Alone condition
estpost sum V DP H VH if Child==0 & risk==0

matrix freq = J(6,4 ,.)
forvalue j=1(1)6{
	local n=1
	foreach i of varlist V DP H VH {
	sum `i'`j' if Child==0 & risk==0
	matrix freq[`j',`n'] = r(mean)
	local n=`n'+1
}
}

matrix colnames freq = "V" "DP" "H" "VH"

forvalue j=1(1)6{
estadd matrix freq`j' = freq[`j',1..4]
}

local j=1
matrix z_rank = J(1,4 ,.)
	foreach i of varlist V DP H VH {
	ranksum `i' if risk==0, by(Child)
	matrix z_rank[1,`j'] = r(z)
	local j=`j'+1
}

matrix colnames z_rank = "V" "DP" "H" "VH"

estadd matrix z_rank = z_rank

*Add test H vs VH
signrank H=VH if Child==0 & risk==0
estadd scalar test = r(z)

eststo Alone


esttab Child Alone using "$Results\TableA11_C.tex", replace  cells("mean(pattern(1 1) fmt(%10.2fc)) freq1(pattern(1 1) fmt(%10.2fc)) freq2(pattern(1 1) fmt(%10.2fc)) freq3(pattern(1 1) fmt(%10.2fc)) freq4(pattern(1 1) fmt(%10.2fc)) freq5(pattern(1 1) fmt(%10.2fc)) freq6(pattern(1 1) fmt(%10.2fc)) z_rank(pattern(0 1) fmt(%10.2fc))") label collabels("Mean" "-1" "-0.6" "-0.2" "+0.2" "+0.6" "+1" "Rank-sum test") nomtitles star(* 0.1 ** 0.05 *** 0.01) varlabels(V "Violation" DP "Direct Punishment" H "No Help" VH "No Help (Violation)") mgroups("CHILD CONDITION" "ALONE CONDITION", pattern(1  1) prefix(\multicolumn{7}{c}{) suffix(})) nonumbers booktabs stats(N test, fmt(%10.0fc %10.2fc) labels("Observations" "NH vs. NH(V)") star(test))
//Note: In the "Runk-sum test (z)" column, levels of significance (represented by stars) are added manually based on the p-values obtained from the command line 685. Similarly, in the "NH vs. NH(V)" row, levels of significance (represented by stars) are added manually based on the p-values obtained from the command lines 657 and 695. 

*******************************************************************************
*						ON-LINE APPENDIX (SURVEY 2)
********************************************************************************

use "$Data\survey2.dta", clear

***Appendix A.6.2 (statistics reported in text)

version 16: table traitement, c(N obs mean normlitter mean normenforc mean normperslitter mean normpersenforc) format(%9.2f) row

signrank normlitter= normperslitter
signrank normenforc = normpersenforc

by traitement, sort: signrank normlitter= normperslitter
by traitement, sort: signrank normenforc = normpersenforc

sort obs
global controls = "i.male c.age i.belgium c.earning c.typecity c.children"

foreach i in normlitter normperslitter normenforc normpersenforc {
	kwallis `i', by(traitement)
	ranksum `i' if traitement!=2, by(traitement)
	ranksum `i' if traitement!=1, by(traitement)
	ranksum `i' if traitement!=0, by(traitement)
	reg `i' i.traitement
	reg `i' i.traitement $controls
	}

*Other motives
tab emotion if traitement==1	
tab environment_ecology if traitement==1	
tab civism if traitement==1
tab image if traitement==1

*teaching as a reason to punishment
tab reasonteaching if traitement==1, missing


*Wilcoxon signed-rank tests
preserve
foreach var of varlist reasonteaching reasonimage reasonnorm reasonother {
	replace `var'=99 if `var'==. & trait>0
}
signrank reasonteaching=reasonimage if trait==1
signrank reasonteaching=reasonother if trait==1
signrank reasonteaching=reasonnorm if trait==1
restore

***Table A12

*generate dummies
foreach z of varlist normlitter normperslitter normenforc normpersenforc {
	local j=1
	foreach i in -1 -0.6 -0.2 0.2 0.6 1 {
		gen `z'`j' = `z'>`i'-.1 & `z'<`i'+.1  //this is to take into account that the decimals are not precise
	local j=`j'+1
	}
}

*Panel A
estpost sum normlitter normperslitter normenforc normpersenforc if traitement==0

matrix freq = J(6,4 ,.)
forvalue j=1(1)6{
	local n=1
	foreach i of varlist normlitter normperslitter normenforc normpersenforc {
		sum `i'`j' if traitement==0
		matrix freq[`j',`n'] = r(mean)
		local n=`n'+1
	}
}

matrix colnames freq = "normlitter" "normperslitter" "normenforc" "normpersenforc"


forvalue j=1(1)6{
	estadd matrix freq`j' = freq[`j',1..4]
}

eststo Alone
	
esttab Alone using "$Results\TableA12_A.tex", replace  cells("mean(pattern(1 1) fmt(%10.2fc)) freq1(pattern(1 1) fmt(%10.2fc)) freq2(pattern(1 1) fmt(%10.2fc)) freq3(pattern(1 1) fmt(%10.2fc)) freq4(pattern(1 1) fmt(%10.2fc)) freq5(pattern(1 1) fmt(%10.2fc)) freq6(pattern(1 1) fmt(%10.2fc)) z_rank(pattern(0 1) fmt(%10.2fc))") label collabels("Mean" "-1" "-0.6" "-0.2" "+0.2" "+0.6" "+1") nomtitles star(* 0.1 ** 0.05 *** 0.01) varlabels( normlitter "Violation (Social)" normperslitter "Violation (Personal)" normenforc "Punishment (Social)" normpersenforc "Punishment (Personal)") mgroups("Alone Video", pattern(1) prefix(\multicolumn{7}{c}{) suffix(})) nonumbers booktabs noobs

*Panel B
estpost sum normlitter normperslitter normenforc normpersenforc if traitement==1

matrix freq = J(6,4 ,.)
forvalue j=1(1)6{
	local n=1
	foreach i of varlist normlitter normperslitter normenforc normpersenforc {
		sum `i'`j' if traitement==1
		matrix freq[`j',`n'] = r(mean)
		local n=`n'+1
	}
}

matrix colnames freq = "normlitter" "normperslitter" "normenforc" "normpersenforc"


forvalue j=1(1)6{
	estadd matrix freq`j' = freq[`j',1..4]
}

eststo Child
	
esttab Child using "$Results\TableA12_B.tex", replace  cells("mean(pattern(1 1) fmt(%10.2fc)) freq1(pattern(1 1) fmt(%10.2fc)) freq2(pattern(1 1) fmt(%10.2fc)) freq3(pattern(1 1) fmt(%10.2fc)) freq4(pattern(1 1) fmt(%10.2fc)) freq5(pattern(1 1) fmt(%10.2fc)) freq6(pattern(1 1) fmt(%10.2fc)) z_rank(pattern(0 1) fmt(%10.2fc))") label collabels("Mean" "-1" "-0.6" "-0.2" "+0.2" "+0.6" "+1") nomtitles star(* 0.1 ** 0.05 *** 0.01) varlabels( normlitter "Violation (Social)" normperslitter "Violation (Personal)" normenforc "Punishment (Social)" normpersenforc "Punishment (Personal)") mgroups("Child Video", pattern(1) prefix(\multicolumn{7}{c}{) suffix(})) nonumbers booktabs noobs

*Panel C
estpost sum normlitter normperslitter normenforc normpersenforc if traitement==2

matrix freq = J(6,4 ,.)
forvalue j=1(1)6{
	local n=1
	foreach i of varlist normlitter normperslitter normenforc normpersenforc {
		sum `i'`j' if traitement==2
		matrix freq[`j',`n'] = r(mean)
		local n=`n'+1
	}
}

matrix colnames freq = "normlitter" "normperslitter" "normenforc" "normpersenforc"


forvalue j=1(1)6{
	estadd matrix freq`j' = freq[`j',1..4]
}

eststo Adult
	
esttab Adult using "$Results\TableA12_C.tex", replace  cells("mean(pattern(1 1) fmt(%10.2fc)) freq1(pattern(1 1) fmt(%10.2fc)) freq2(pattern(1 1) fmt(%10.2fc)) freq3(pattern(1 1) fmt(%10.2fc)) freq4(pattern(1 1) fmt(%10.2fc)) freq5(pattern(1 1) fmt(%10.2fc)) freq6(pattern(1 1) fmt(%10.2fc)) z_rank(pattern(0 1) fmt(%10.2fc))") label collabels("Mean" "-1" "-0.6" "-0.2" "+0.2" "+0.6" "+1") nomtitles star(* 0.1 ** 0.05 *** 0.01) varlabels( normlitter "Violation (Social)" normperslitter "Violation (Personal)" normenforc "Punishment (Social)" normpersenforc "Punishment (Personal)") mgroups("Adult Video", pattern(1) prefix(\multicolumn{7}{c}{) suffix(})) nonumbers booktabs noobs


*Panel D

matrix test = J(4,4 ,.)
local j=0
foreach i in normlitter normperslitter normenforc normpersenforc {
	local j=`j'+1
	kwallis `i', by(traitement)
	matrix test[`j',1] = chi2tail(r(df), r(chi2_adj))
	ranksum `i' if traitement!=2, by(traitement)
	matrix test[`j',2] = r(p)
	ranksum `i' if traitement!=1, by(traitement)
	matrix test[`j',3] = r(p)
	ranksum `i' if traitement!=0, by(traitement)
	matrix test[`j',4] = r(p)
	}

matrix colnames test = "normlitter" "normperslitter" "normenforc" "normpersenforc"
mat rownames test = "Violation (Social)" "Violation (Personal)" "Punishment (Social)" "Punishment (Personal)"


esttab matrix(test, fmt(%10.3fc)) using "$Results\TableA12_D.tex", replace collabels("K-W test" "Alone vs. Child" "Alone vs. Two-adult" "Child vs. Two-adult") nomtitles booktabs
	

foreach z of varlist normlitter normperslitter normenforc normpersenforc {
	local j=1
	foreach i in -1 -0.6 -0.2 0.2 0.6 1 {
		drop `z'`j'
	local j=`j'+1
	}
}

***Table A13

*Generate dummies

foreach z of varlist reasonteaching reasonimage reasonnorm reasonother {
	local j=1
	foreach i in 1 2 3 4 {
		gen `z'`j' = `z'==`i'
	local j=`j'+1
	}
}

foreach z of varlist reasonteaching reasonimage reasonnorm reasonother {
		gen `z'0 = `z'==.
}

matrix reason = J(6,4 ,.)
local n1=1
foreach j of numlist 1(1)4 0 {
	local n2=1
	foreach i of varlist reasonteaching reasonimage reasonnorm reasonother {
		sum `i'`j' if traitement==1
		matrix reason[`n1',`n2'] = r(mean)
		local n2=`n2'+1
	}
	local n1=`n1'+1
}


local n=1
foreach i of varlist reasonteaching reasonimage reasonnorm reasonother {
	sum `i' if traitement==1
	matrix reason[6,`n'] = r(mean)
		local n=`n'+1
}


matrix colnames reason = "Teaching" "Social image" "Norm enforcement" "Other reasons"
mat rownames reason = "Ranking 1" "Ranking 2" "Ranking 3" "Ranking 4" "No Ranking" "Avg Ranking"

esttab matrix(reason, fmt(%10.2fc)) using "$Results\TableA13.tex", replace collabels("Teaching" "Social image" "Norm enforcement" "Other reasons") nomtitles booktabs

foreach z of varlist reasonteaching reasonimage reasonnorm reasonother {
	foreach i in 0 1 2 3 4 {
		drop `z'`i'
	}
}

***Regression analysis and Table A14

global controls = "i.male c.age i.belgium c.earning c.typecity c.children"

local j=1
	foreach i in reasonteaching reasonimage reasonnorm reasonother {
	rename `i' rank`j'
	local j=`j'+1
}

reshape long rank, i(obs) j(reason_type)

label define lreason_type 1 "Teaching" 2 "Image" 3 "Norm" 4 "Other"
label value reason_type lreason_type

*code unranked alternatives as 99
replace rank=99 if rank==. & trait>0

cmset obs reason_type

cmrologit rank i.reason_type##(i.male) i.reason_type##(c.age) i.reason_type##(i.belgium) i.reason_type##(c.children) i.reason_type##(c.earning)  i.reason_type##(c.typecity) if traitement==1, incomplete(99) vce(robust) reverse
testparm i.reason_type#(i.male c.age i.belgium c.children c.earning)

eststo regp1: cmrologit rank i.reason_type if traitement==1, incomplete(99) vce(robust) reverse
predict p if e(sample)
forvalue i=1(1)4 {
	sum p if traitement==1 & reason_type==`i'
	estadd scalar p`i' =round(r(mean),.01)
}

esttab regp1 using "$Results\TableA14.tex", replace booktabs cells(b(star pattern(1) fmt(%10.2fc)) se(par pattern(1))) label starlevels(* 0.10 ** 0.05 *** 0.01) nomtitles collabels(none) alignment(r)  varlabels(2.reason_type "Social image" 3.reason_type "Norm enforcement" 4.reason_type "Other reasons") nobaselevels noobs stats(p1 p2 p3 p4, fmt(%10.2fc %10.2fc %10.2fc %10.2fc) labels("Teaching" "Social image" "Norm enforcement" "Other reasons")) 
 
*** Close log file
log close Log_output



```

## How to run a script

Write each script to a file under the output directory, then run it with
exactly this command (the data directory is mounted read-only at its own
path; nothing else from the host is visible; `$SCRIPT` is the absolute path of
the script you wrote):

    SCRIPT=<repo>/benchmark/reproductions/brouwer-2022-teaching-norms/seeded/2026-11-02-b/script.R   # or <repo>/benchmark/reproductions/brouwer-2022-teaching-norms/seeded/2026-11-02-b/attempt-<n>/script.R
    docker run --rm --label retally.run=claude-code-brouwer-2022-teaching-norms-seeded-2026-11-02-b --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/seeded/2026-11-02-b/mount/brouwer_2022_teaching_norms:<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/seeded/2026-11-02-b/mount/brouwer_2022_teaching_norms:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R > "$(dirname "$SCRIPT")/stdout.txt" 2> "$(dirname "$SCRIPT")/stderr.txt"; echo "exit code: $?"

The sandbox time limit is 300 seconds (memory 4g, 1.0 CPU).  Wrap the
command in a timeout of that many seconds: prefix it with
`perl -e 'alarm shift; exec @ARGV' 300` (or `gtimeout 300` if installed;
macOS has no `timeout`).  If the timeout fires, stop the container with
`docker ps -q --filter label=retally.run=claude-code-brouwer-2022-teaching-norms-seeded-2026-11-02-b | xargs docker kill` and treat the
run as a crash (exit code 124).

## Output contract

The output directory `<repo>/benchmark/reproductions/brouwer-2022-teaching-norms/seeded/2026-11-02-b` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/brouwer-2022-teaching-norms/seeded/2026-11-02-b/
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

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/brouwer-2022-teaching-norms/seeded/2026-11-02-b`.
