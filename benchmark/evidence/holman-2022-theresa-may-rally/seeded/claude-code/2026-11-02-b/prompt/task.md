# Retally reproduction task: holman-2022-theresa-may-rally (seeded, run 2026-11-02-b)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `holman-2022-theresa-may-rally`, mode `seeded`, run `2026-11-02-b`
- Paper: The Curious Case of Theresa May and the Public That Did Not Rally: Gendered Reactions to Terrorist Attacks Can Cause Slumps Not Bumps
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/seeded/2026-11-02-b/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/seeded/2026-11-02-b/mount/holman_2022_theresa_may_rally`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/holman-2022-theresa-may-rally/seeded/2026-11-02-b`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/seeded/2026-11-02-b/mount/holman_2022_theresa_may_rally` as data, and `<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/seeded/2026-11-02-b/paper.txt` as
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

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/holman-2022-theresa-may-rally/seeded/2026-11-02-b --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Claims to Reproduce
1. intl_attack_table4: 3.112 (percentage points of executive approval) [type: coefficient]
   Location: Table 4, International terrorist attack (All countries, attacks with more than 15 deaths)
   Context: Table 4 ("Effect of Terrorist Attacks on Executive Approval Ratings"). Linear regression on time-series cross-sectional data of country-quarters: the percentage of the public approving of the executive in the quarter following the attack, regressed on an indicator for a major international terrorist attack (an attack with an international component under the Global Terrorism Database's definition and more than 15 deaths), the presence of a woman executive, their interaction, and controls for GDP growth, logged inflation, the left-center-right placement of the leader and elections, with country…
2. intl_attack_x_woman_exec_table4: -4.333 (percentage points of executive approval) [type: coefficient]
   Location: Table 4, International terrorist attack x Woman executive
   Context: Table 4, the paper's global test of the gender-revised rally framework: the coefficient on the interaction of a major international terrorist attack (more than 15 deaths) with a woman executive, in the same linear country-quarter regression of next-quarter executive approval (controls for woman executive, GDP, logged inflation, left-center-right placement of the leader and elections; country fixed effects; panel-corrected standard errors). Negative and significant at the 5% level in the paper.
3. n_obs_table4: 4328.0 (observations (country-quarters)) [type: other]
   Location: Table 4, Observations
   Context: Number of country-quarter observations in the Table 4 regression (all countries, attacks with more than 15 deaths).
4. did_attack_x_time_like_may_table2: -0.1274 (points on the 0-10 like/dislike scale) [type: coefficient]
   Location: Table 2, column May likeability, Manchester attack * time
   Context: Table 2 ("Difference-in-Difference, with Fixed Effects"), May likeability column. British Election Study internet panel, using waves before and after the 22 May 2017 Manchester Arena bombing. Outcome: how much the respondent likes Theresa May, 0 (strongly dislike) to 10 (strongly like). Regressors: Manchester attack (the respondent was surveyed after the attack in the attack wave, wave 12), time (0 for waves before the attack, 1 for waves from 12 onward), their interaction (the coefficient here), wave fixed effects, and controls for identifying as ethnically British, gender, Labour party membe…
5. did_attack_like_may_table2: 0.0178 (points on the 0-10 like/dislike scale) [type: coefficient]
   Location: Table 2, column May likeability, Manchester attack
   Context: Table 2, May likeability column: the coefficient on the Manchester attack (surveyed-after-the-attack) indicator in the same difference-in-differences regression (time, interaction, wave fixed effects, full controls). Not significant.
6. did_time_like_may_table2: -0.5007 (points on the 0-10 like/dislike scale) [type: coefficient]
   Location: Table 2, column May likeability, Time
   Context: Table 2, May likeability column: the coefficient on the time indicator (waves from the attack wave onward) in the same difference-in-differences regression.
7. did_attack_x_time_may_best_pm_table2: -0.0501 (change in the May-best-PM outcome (0/1)) [type: coefficient]
   Location: Table 2, column May best PM, Manchester attack * time
   Context: Table 2, May best PM column: the same difference-in-differences specification (Manchester attack, time, their interaction, wave fixed effects, full controls) with the outcome "Who would make the best prime minister?", coded 1 for Theresa May and 0 for Jeremy Corbyn. The table note describes this column as a logistic regression; standard errors in parentheses. This is the interaction coefficient.
8. did_attack_may_best_pm_table2: -0.0002 (change in the May-best-PM outcome (0/1)) [type: coefficient]
   Location: Table 2, column May best PM, Manchester attack
   Context: Table 2, May best PM column: the coefficient on the Manchester attack indicator. Not significant.
9. did_time_may_best_pm_table2: 0.2098 (change in the May-best-PM outcome (0/1)) [type: coefficient]
   Location: Table 2, column May best PM, Time
   Context: Table 2, May best PM column: the coefficient on the time indicator.
10. n_obs_did_like_may_table2: 143499.0 (observations (respondent-waves)) [type: other]
   Location: Table 2, Observations, column May likeability
   Context: Number of panel observations in the Table 2 May likeability regression.
11. n_obs_did_may_best_pm_table2: 97155.0 (observations (respondent-waves)) [type: other]
   Location: Table 2, Observations, column May best PM
   Context: Number of panel observations in the Table 2 May best PM regression.

## Dataset Information
Name: holman_2022_theresa_may_rally
Local path: <repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/seeded/2026-11-02-b/mount/holman_2022_theresa_may_rally
File format: csv
Files in the dataset directory (paths relative to the local path above):
- BES_data.dta (45.2 MB) — 92588 rows, 117 columns: gender, labour, income, ideology, attack_ideology, may_bestpm, may_bestpm11, likeCorbynW7, likeCorbynW8, likeCorbynW9, likeMayW9, likeMayW10, likeCorbynW10, likeCorbynW11, likeMayW12, likeCorbynW12, likeMayW13, likeCorbynW13, likeMayW14, likeCorbynW14, likeMayW15, likeCorbynW15, likeMayW16, likeCorbynW16, post_attack, bestPMW7, bestPMW8, bestPMW10, bestPMW11, bestPMW12, white, ideology2, ideo3, median_control, party_other, party3, gender_roles, gender_attitudes, hi_low_gender…
- did_data.dta (178.0 MB) — 1481408 rows, 34 columns: wave, gender, labour, income, ideology, time, may_bestpm, post_attack, white, treatment1, ideology2, ideo3, likeCorbynW, likeSturgeonW, party_other, gender_roles, id, wt_new_W12, starttimeW, endtimeW, likeMayW, post_bridge, dates_to_bomb, z_distance, conservative, likeMayW12a, likeMayW12b, female_equality, women_office, women_discrimin, women_jobs, likeFarronW, bestPMW, treatment2
- global_approval.dta (810.4 KB) — 5469 rows, 28 columns: country, growth, manchester, qtr, country_code, election_qtr, lag_approval, log_inflation, pres_15death, pres_20death, rally_events, rally_kill, rally_event_any, rally_event_any2, female_pres, execrlc, ccode, kill_16, kill_18, kill_10, kill_12, kill_14, kill_20, kill_08, kill_06, kill_under5, kill_1_5, kill_3_5
- CMPdata.dta (6.8 MB) — 4656 rows, 174 columns: country, party, countryname, partyname, partyabbrev, oecdmember, eumember, edate, date, parfam, coderid, manual, coderyear, testresult, testeditsim, pervote, voteest, presvote, absseat, totseats, progtype, datasetorigin, corpusversion, tota…
- constituency_results_2017_election.dta (1.5 MB) — 533 rows, 319 columns: Country, c11HouseOutright, c11EthnicityWhiteBritish, c11LookingAfterHome, c11IndustryPublicAdministration, Majority17, Majority15, Majority10, c11QualLevel1, c11QualLevel2, c11QualLevel3, c11QualLevel4, pano, ONSConstID, ConstituencyName, R…
- BESExpertSurveyTrendFile2014-2019.dta (189.4 KB) — 303 rows, 114 columns: Country, leftrightLab, leftrightCon, leftrightLibDem, leftrightUKIP, leftrightBrexit, leftrightGreen, leftrightSNP, leftrightPlaid, responseid, year, DateCompleted, libauthLab, libauthCon, libauthLibDem, libauthUKIP, libauthBrexit, libauthG…
- experimental2012.dta (49.6 KB) — 992 rows, 10 columns: terror, gt, tt, tt_rbi, econ, ft3a, feel_may, feel_warsi, feel_harman, feel_clegg
- Readme for The Curious Case of Theresa May.docx (17.1 KB)
- currency_rates.csv (679 B) — columns: date,gbp_to_eug
- metadata.json (587 B)
- replication_files.do (45.1 KB)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/seeded/2026-11-02-b/mount/holman_2022_theresa_may_rally' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
Installed packages (no network; nothing else can be installed): jsonlite, fixest, lfe, AER, ivreg, plm, estimatr, lme4, quantreg, car, sandwich, lmtest, clubSandwich, multiwayvcov, marginaleffects, MatchIt, optmatch, CBPS, WeightIt, cobalt, did, rdrobust, rddensity, Synth, modelsummary, stargazer, texreg, broom, tidyverse, dplyr, tidyr, readr, stringr, lubridate, data.table, haven, readxl, janitor, zoo, ggplot2, ggridges, ggrepel, gridExtra, cowplot, gtable, extrafont, sf, MASS, nnet, survival, splines, Matrix, boot, stats, utils.
Prefer fixest for fixed effects, IV and clustered SEs; use the other installed packages where the paper's method calls for them.
Set a deterministic seed with ``set.seed(42)`` for any randomness.
Do NOT access the internet; the container runs with --network none.
Do NOT shell out via system() / system2().
Emit RESULT:<name>=<value> lines to stdout at the end via cat().

## Original Replication Scripts
The replication package (the dataset directory) ships the authors' own analysis scripts, reproduced below.  These are the GROUND TRUTH for the exact estimating equation, variable names, sample restrictions, fixed effects, and standard-error clustering — follow them over anything reconstructed from the methodology summary, and prefer them over the paper's text where the two disagree.  Your job is to write R code that implements the SAME SPECIFICATION: translate what the scripts estimate, do not transliterate their syntax line by line (a Stata .do file's regression, e.g. `reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the equivalent fixest::feols() call in R).  Keep only the parts that produce the specific claims being reproduced; skip figure construction and unrelated robustness checks.  The scripts' data-file paths refer to the package's internal layout — resolve them against the dataset directory listed under Dataset Information.

Stata-to-fixest sample matching: feols() drops fixed-effect singletons by default, but Stata's `reg y x i.fe` / `xi:` dummies keep them.  Pass `fixef.rm = "none"` to every feols() call that has fixed effects, otherwise the observation count and the robust SEs drift from the paper's.  Stata's `, r` / `vce(robust)` is `vcov = "hetero"`.

### `replication_files.do`
```stata
clear
set more off
clear matrix
clear mata
set maxvar 10000

**** install the following if not already installed *** 
*ssc install estout
*ssc install lean2
*ssc install lincomest
*ssc install coefplot
*ssc install grc1leg

set scheme lean2

graph set window fontface "Times New Roman"


***********************************************************************
****************** do file for "Curious case of Theresa May"   ********
*******************    British elections survey           *************
*******************    + experimental data + constituency *************
*******************  + global analysis + BES expert survey ************
*******************             CMP + CSES                 ************
******************  Holman, Merolla, Zechmeister           ************
***********************************************************************

*set working directory here* 

clear

use BES_data.dta, replace

***** setting global controls  *****

global demographics white gender labour party_other income ideology2
global demographics2 white gender labour party_other income ideology2 vote_brexit


***** results ***** 

***** basic models  **** 
eststo clear 
eststo likemay1: reg likeMayW12 post_attack labour  [pw=wt_new_W12] , cluster(startdate)
eststo likemay2: reg likeMayW12 post_attack   $demographics   [pw=wt_new_W12] , cluster(startdate)
eststo maybest1: logit may_bestpm post_attack labour   [pw=wt_new_W12] , cluster(startdate)
eststo maybest2: logit may_bestpm post_attack  $demographics  [pw=wt_new_W12] , cluster(startdate)

		# delimit ;
		esttab 	using tab1_may_manchester_time.rtf, nogap se b(%9.3f) starlevels(* .05) r2(%9.4f) pr2(%9.4f) 
			title("Manchester Attack and Views of May" )
			 label nonumbers
			addnote("DV: Favorability towards May & preference for her over Corbyn as PM") 
			compress replace;
		#delimit cr
		
		
**** estimating substantive effects ***** 
eststo clear 
	
eststo likemay2: reg likeMayW12 post_attack   $demographics  [pw=wt_new_W12] , cluster(startdate)
margins, at(post_attack=(0,1))
margins, at(post_attack=(0,1) labour=(1))
margins, at(post_attack=(0,1) labour=(0) party_other=(0))

eststo clear 
eststo maybest2: logit may_bestpm post_attack  $demographics  [pw=wt_new_W12] , cluster(startdate)
margins, at(post_attack=(0,1))
margins, at(post_attack=(0,1) labour=(1))
margins, at(post_attack=(0,1) labour=(0) party_other=(0))

sum gender_attitudes, detail 
		
***** aggregate gender attitudes measure **** 

	eststo clear
	eststo gender_attitudes: reg likeMayW12 i.post_attack##c.gender_attitudes $demographics  [pw=wt_new_W12], cluster(startdate)
	margins r.post_attack, at(gender_attitudes=(0(.05)1)) atmeans

	marginsplot, title("") recast(line) recastci(rline) ///
	xtitle("Negative views of women", size(small)) ///
	xlab(0 "Least" 1 "Most", labsize(small)) ///
	ytitle ("", size(small))  title("May Likeability") ///
	addplot(histogram gender_attitudes, bin(10) yaxis(2) yscale(alt axis(2)) fcolor(%10) lc(black%20)) ///
	legend(order(2 "Effect of Manchester attack" 3 "Distribution of gender attitudes") rows(1) pos(6)) ///
	r1title("") 
	graph save "fig1_gender_attitudes.gph", replace
	graph export "fig1_gender_attitudes.pdf", replace 
	
		
		
**** comparison of leaders **** 
eststo clear

eststo likemay: reg likeMayW12 post_attack  $demographics  [pw=wt_new_W12] , cluster(startdate)
eststo likecor: reg likeCorbynW12 post_attack  $demographics [pw=wt_new_W12] , cluster(startdate)
eststo likefar: reg likeFarronW12 post_attack $demographics [pw=wt_new_W12] , cluster(startdate)
eststo likesturg: reg likeSturgeonW12 post_attack $demographics [pw=wt_new_W12] , cluster(startdate)
 

		# delimit ;
		esttab 	using tab3_comparison_leaders.rtf, nogap se b(%9.3f) starlevels(* .05) r2(%9.4f) 
			title("Manchester attack and view of leaders" "Wave survey weights" )
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr
		

************ sep models by PID ************* 

eststo clear 


eststo likemay_c: reg likeMayW12  post_attack  $demographics if conservative == 1  [pw=wt_new_W12]
eststo likemay_l: reg likeMayW12  post_attack  $demographics if labour == 1  [pw=wt_new_W12]
eststo likemay_po: reg likeMayW12  post_attack  $demographics if party_other == 1  [pw=wt_new_W12]


eststo bestpm_c: logit may_bestpm post_attack  $demographics if conservative == 1  [pw=wt_new_W12]
eststo bestpm_l: logit may_bestpm post_attack  $demographics if labour == 1  [pw=wt_new_W12]
eststo bestpm_po: logit may_bestpm post_attack  $demographics if party_other == 1  [pw=wt_new_W12]

	coefplot (likemay_c,  label("{it:Conservatives}")  msymbol(T)) ///
	(likemay_l,  label("{it:Labour}")mfcolor(white)  msymbol(O)), bylabel (Like May) ///
	|| (bestpm_c) (bestpm_l), bylabel (Prefer May as PM) /// 
	drop(_cons white gender labour party_other income ideology2) ///
	ylabel(,labsize(small)) ///
	xline(0, lpattern(dash) lcolor(gray) lwidth(vthin)) level(90) ///
	xtitle ("Difference in evaluation of May between pre and post attack") /// 
	ylab(none) /// 
	xlab(-.6 -.4 -.2 0 .2 ,labsize(small) angle(horizontal)) format(%9.2f)  ///
	title() grid(between) graphregion(margin(medlarge)) legend (rows(1) pos(6))
	graph save fig2_by_pid.gph, replace 
	graph export fig2_by_pid.pdf, replace 
	


**** counterfactual - something else happened

eststo clear 

**** one big graph / table **** 

eststo basic:  reg likeMayW12 post_attack   $demographics [pw=wt_new_W12]

**** including control for economy **** 

eststo econ: reg likeMayW12 econ_rate2 post_attack   $demographics  [pw=wt_new_W12]

**** including Brexit in models 

eststo brexit: reg likeMayW12 post_attack   $demographics2  [pw=wt_new_W12]


**** looking at smaller bandwidth **** 

eststo bandwidth10: reg likeMayW12 post_attack  $demographics   if bandwidth10 == 1  [pw=wt_new_W12]
eststo bandwidth4: reg likeMayW12 post_attack   $demographics if bandwidth3 == 1  [pw=wt_new_W12]


	coefplot (basic, label("{it:Basic model w controls}")) (econ, label ("{it:w control for economy}")) (brexit, label ("{it:w Brexit controls}")) ///
	(bandwidth10, label("{it:10 day bandwidth}")) (bandwidth4, label("{it:4 day bandwidth}")) ///
	, drop(_cons white gender labour party_other income ideology2 ideology vote_brexit *.date *.startdate econ_rate2) ///
	ylabel(none) xlabel(,labsize(small)) format(%9.2f) ///
	xline(0, lpattern(dash) lcolor(gray) lwidth(vthin)) level() ///
	xtitle ("Effect of attack") /// 
	title ("May likeability") ///
	legend(col(1) size(small)) ///
	title() grid(between) graphregion(margin(medlarge)) ///
	legend (rows(1) pos(6))
	graph save fig3a_alt_controls.gph, replace 
	
		
	
**** counterfactual of May best PM 

eststo clear 

**** one big graph / table **** 

eststo basic:  logit may_bestpm post_attack   $demographics [pw=wt_new_W12]

**** including control for economy **** 

eststo econ: logit may_bestpm econ_rate2 post_attack   $demographics  [pw=wt_new_W12]

**** including Brexit in models 

eststo brexit: logit may_bestpm  post_attack   $demographics2  [pw=wt_new_W12]


**** looking at smaller bandwidth **** 

eststo bandwidth10: logit may_bestpm  post_attack  $demographics   if bandwidth10 == 1  [pw=wt_new_W12]
eststo bandwidth4: logit may_bestpm  post_attack   $demographics if bandwidth3 == 1  [pw=wt_new_W12]


	coefplot (basic, label("{it:Basic model w controls}")) (econ, label ("{it:w control for economy}")) (brexit, label ("{it:w Brexit controls}")) ///
	(bandwidth10, label("{it:10 day bandwidth}")) (bandwidth4, label("{it:4 day bandwidth}")) ///
	, drop(_cons white gender labour party_other income ideology2 vote_brexit *.date *.startdate econ_rate2 startdate) ///
	ylabel(none) xlabel(,labsize(small)) format(%9.2f) ///
	xline(0, lpattern(dash) lcolor(gray) lwidth(vthin)) level() ///
	xtitle ("Effect of attack") /// 
	title ("May best PM") //////
	legend (rows(1) pos(6) size(small)) ///
	title() grid(between) graphregion(margin(medlarge)) 
	graph save fig3b_alt_controls_bestpm.gph, replace 
	
	
	grc1leg fig3a_alt_controls.gph  fig3b_alt_controls_bestpm.gph, scheme(s1mono) ycommon ///
	col(2) graphregion(margin(none)) ysize(3.5) 
	graph save fig3_alternative_specifications.gph, replace
	graph export fig3_alternative_specifications.pdf, replace 

	

*********************************************************************
********************** appendix materials ***************************
*********************************************************************

**** appendix A - main results + alternative specifications for tables 1 and 2 ***** 

eststo clear 

eststo likemay1: reg likeMayW12 post_attack labour  [pw=wt_new_W12] , cluster(startdate)
eststo likemay2: reg likeMayW12 post_attack   $demographics  [pw=wt_new_W12] , cluster(startdate)
eststo maybest1: logit may_bestpm post_attack labour   [pw=wt_new_W12] , cluster(startdate)
eststo maybest2: logit may_bestpm post_attack  $demographics  [pw=wt_new_W12] , cluster(startdate)
eststo likemay3: reg likeMayW12 post_attack   [pw=wt_new_W12] 
eststo maybest3: reg may_bestpm post_attack   [pw=wt_new_W12]  



		# delimit ;
		esttab 	using appendA_tab1_may_manchester_time.rtf, nogap se b(%9.3f) starlevels(* .05) r2(%9.4f) pr2(%9.4f) 
			title("Manchester Attack and Views of May" )
			 label nonumbers
			addnote("DV: Favorability towards May & preference for her over Corbyn as PM") 
			compress replace;
		#delimit cr
		
	***** appendix table to show increase in R2s **** 
		eststo clear
	
eststo likemay1: reg likeMayW12 post_attack labour  [pw=wt_new_W12] , cluster(startdate)
eststo likemay2: reg likeMayW12 post_attack  labour gender [pw=wt_new_W12] , cluster(startdate)
eststo likemay3: reg likeMayW12 post_attack  labour gender party_other [pw=wt_new_W12] , cluster(startdate)
eststo likemay4: reg likeMayW12 post_attack  labour gender party_other income [pw=wt_new_W12] , cluster(startdate)
eststo likemay5: reg likeMayW12 post_attack  labour gender party_other income ideology2 [pw=wt_new_W12] , cluster(startdate)
eststo likemay6: reg likeMayW12 post_attack  labour gender party_other income ideology2 white [pw=wt_new_W12] , cluster(startdate)


		# delimit ;
		esttab 	using appendA_controlsr2.rtf, nogap se b(%9.3f) starlevels(* .05) r2(%9.4f) 
			title("Manchester Attack and Views of May" )
			 label nonumbers
			addnote("DV: Favorability towards May & preference for her over Corbyn as PM" "Wave survey weights") 
			compress replace;
		#delimit cr
eststo clear		
		
eststo likemay1: logit may_bestpm  post_attack labour  [pw=wt_new_W12] , cluster(startdate)
eststo likemay2: logit may_bestpm  post_attack  labour gender [pw=wt_new_W12] , cluster(startdate)
eststo likemay3: logit may_bestpm  post_attack  labour gender party_other [pw=wt_new_W12] , cluster(startdate)
eststo likemay4: logit may_bestpm  post_attack  labour gender party_other income [pw=wt_new_W12] , cluster(startdate)
eststo likemay5: logit may_bestpm  post_attack  labour gender party_other income ideology2 [pw=wt_new_W12] , cluster(startdate)
eststo likemay6: logit may_bestpm  post_attack  labour gender party_other income ideology2 white [pw=wt_new_W12] , cluster(startdate)


		# delimit ;
		esttab 	using appendA_controlsr2_2.rtf, nogap se b(%9.3f) starlevels(* .05) pr2(%9.4f) 
			title("Manchester Attack and Views of May" )
			 label nonumbers
			addnote("DV: Favorability towards May & preference for her over Corbyn as PM" "Wave survey weights") 
			compress replace;
		#delimit cr

eststo clear 

eststo likemay: reg likeMayW12 post_attack likeMayW11   $demographics  [pw=wt_new_W12] 
eststo bestpm: logit may_bestpm post_attack may_bestpm11   $demographics  [pw=wt_new_W12] 


		# delimit ;
		esttab 	using appendA_like_previousrating.rtf, nogap se b(%9.3f) starlevels(* .05) r2(%9.4f)  pr2(%9.4f) 
			title("Like leaders + previous evals" )
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr
		

**** london bridge attack ***** 
eststo clear 
eststo likemay1: reg likeMayW12 post_bridge   $demographics  [pw=wt_new_W12] , cluster(startdate)
eststo likemay2: reg likeMayW12 post_bridge  post_attack $demographics  [pw=wt_new_W12] , cluster(startdate)
eststo maybest1: logit may_bestpm post_bridge  $demographics  [pw=wt_new_W12] , cluster(startdate)
eststo maybest2: logit may_bestpm post_bridge post_attack $demographics  [pw=wt_new_W12] , cluster(startdate)




		# delimit ;
		esttab 	using appendA_bridge_attack.rtf, nogap se b(%9.3f) starlevels(* .05) r2(%9.4f) pr2(%9.4f) 
			title("Manchester Attack and Views of May" )
			 label nonumbers
			addnote("DV: Favorability towards May & preference for her over Corbyn as PM") 
			compress replace;
		#delimit cr
		
		
***** Appendix B: random assignment and balance of random event ***** 

**** testing balance of pre and post survey **** 
eststo clear

eststo post_attack: logit post_attack white gender conservative labour income ideology2 vote_brexit

		# delimit ;
		esttab 	using appendB_balance_test.rtf, nogap se b(%9.3f) starlevels(* .05) pr2(%9.4f) 
			title("pre-post attack")
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr

eststo clear 

**** estimating the effect on a variable where we don't expect effects **** 

eststo clear 

eststo unrelated_var: reg keepNukesW12   post_attack $demographics    [pw=wt_new_W12], cluster(startdate)
eststo post_attack11: reg likeMayW11 post_attack $demographics    [pw=wt_new_W11]
eststo post_attack13: reg likeMayW13 post_attack  $demographics   [pw=wt_new_W13]


		# delimit ;
		esttab 	using appendB_othervariables.rtf, nogap se b(%9.3f) starlevels(* .05) r2(%9.4f) pr2(%9.4f) 
			title("pre-post attack")
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr


**** temporal stability of demographics across the wave **** 

eststo clear 
oneway white weeks, tab
oneway  gender weeks, tab
oneway  conservative weeks, tab
oneway  labour weeks, tab
oneway  income weeks, tab
oneway  ideology weeks, tab


		
*********** Appendix C Within Group Effects ************ 
	
****** appendix of gendered attitudes **** 



	eststo clear
	eststo gender_attitudes: reg likeMayW12 i.post_attack##c.gender_attitudes $demographics  [pw=wt_new_W12], cluster(startdate)
		margins r.post_attack, at(gender_attitudes=(1(.25)5)) atmeans
		eststo gender_attitudes2: logit may_bestpm i.post_attack##c.gender_attitudes $demographics [pw=wt_new_W12], cluster(startdate)
		margins r.post_attack, at(gender_attitudes=(1(.25)5)) atmeans

	
		# delimit ;
		esttab 	using appendC_gender_attitudes.rtf, nogap se b(%9.3f) starlevels(* .05) r2(%9.4f) pr2(%9.4f) 
			title("Manchester attack and view of leaders" "Wave survey weights" )
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr
		

		***** triple interactions ***** 
		

	eststo clear
	eststo ideo: reg likeMayW12 i.post_attack##c.gender_attitudes##i.ideo3 $demographics [pw=wt_new_W12], cluster(startdate)
	
	margins r.post_attack, at(gender_attitudes=(0(.05)1)) atmeans
	marginsplot, title("") recast(line) recastci(rline) ///
	xtitle("Negative views of women", size(small)) ///
	xlab(0 "Least" 1 "Most", labsize(small)) ///
	ytitle ("Effect of Manchester attack", size(small)) ////
	title("triple interaction attack x gender attitudes x ideology") ///
	addplot(histogram gender_attitudes, bin(10) yaxis(2) yscale(alt axis(2)) ytitle("Distribution of gender attitudes", axis(2) size(small)) fcolor(%10) lc(black%20)) ///
	legend(off) ///
	r1title("") 
	graph save "append_attack_gender_ideo_triple.gph", replace
		
	
	eststo clear
	eststo pid: reg likeMayW12 i.post_attack##c.gender_attitudes##i.party3 $demographics [pw=wt_new_W12], cluster(startdate)
	margins r.post_attack, at(gender_attitudes=(0(.05)1)) atmeans
	marginsplot, title("") recast(line) recastci(rline) ///
	xtitle("Negative views of women", size(small)) ///
	xlab(0 "Least" 1 "Most", labsize(small)) ///
	ytitle ("Effect of Manchester attack", size(small)) ////
	title("triple interaction attack x gender attitudes x party ID") ///
	addplot(histogram gender_attitudes, bin(10) yaxis(2) yscale(alt axis(2)) ytitle("Distribution of gender attitudes", axis(2) size(small)) fcolor(%10) lc(black%20)) ///
	legend(off) ///
	r1title("") 
	graph save "append_attack_gender_pid_triple.gph", replace
		
		
		***** including additional interactions ***** 
		
	eststo clear
	eststo ideo: reg likeMayW12 i.post_attack##c.gender_attitudes i.post_attack##i.ideo3 $demographics [pw=wt_new_W12], cluster(startdate)
	margins r.post_attack, at(gender_attitudes=(0(.05)1)) atmeans
	marginsplot, title("") recast(line) recastci(rline) ///
	xtitle("Negative views of women", size(small)) ///
	xlab(0 "Least" 1 "Most", labsize(small)) ///
	ytitle ("Effect of Manchester attack", size(small)) ////
	title("includes ideology x attack in model") ///
	addplot(histogram gender_attitudes, bin(10) yaxis(2) yscale(alt axis(2)) ytitle("Distribution of gender attitudes", axis(2) size(small)) fcolor(%10) lc(black%20)) ///
	legend(off) ///
	r1title("") 
	graph save "append_attack_gender_ideo.gph", replace
		
		
	eststo pid: reg likeMayW12 i.post_attack##c.gender_attitudes i.post_attack##i.party3 $demographics [pw=wt_new_W12], cluster(startdate)
	margins r.post_attack, at(gender_attitudes=(0(.05)1)) atmeans
	marginsplot, title("") recast(line) recastci(rline) ///
	xtitle("Negative views of women", size(small)) ///
	xlab(0 "Least" 1 "Most", labsize(small)) ///
	ytitle ("Effect of Manchester attack", size(small)) ////
	title("includes party x attack in model") ///
	addplot(histogram gender_attitudes, bin(10) yaxis(2) yscale(alt axis(2)) ytitle("Distribution of gender attitudes", axis(2) size(small)) fcolor(%10) lc(black%20)) ///
	legend(off) ///
	r1title("") 
	graph save "append_attack_gender_party.gph", replace
	
	
	graph combine  "append_attack_gender_ideo_triple.gph" "append_attack_gender_pid_triple.gph" ///
	"append_attack_gender_ideo.gph" "append_attack_gender_party.gph", rows(2) ycommon
	graph save "appendC_additional_interact.gph", replace
	graph export "appendC_additional_interact.png", replace width(1800)
		
eststo clear 

alpha gender_roles female_equality women_office women_discrimin women_jobs, std

	eststo gender_attitudes: reg likeMayW12 i.post_attack##c.gender_attitudes $demographics  [pw=wt_new_W12] , cluster(startdate)
	eststo gender_roles: reg likeMayW12 i.post_attack##c.gender_roles $demographics  [pw=wt_new_W12], cluster(startdate)
	eststo female_equality: reg likeMayW12 i.post_attack##c.female_equality $demographics  [pw=wt_new_W12], cluster(startdate)
	eststo women_office: reg likeMayW12 i.post_attack##c.women_office $demographics  [pw=wt_new_W12], cluster(startdate)
	eststo women_discrimin: reg likeMayW12 i.post_attack##c.women_discrimin $demographics  [pw=wt_new_W12], cluster(startdate)
	eststo women_jobs: reg likeMayW12 i.post_attack##c.women_jobs $demographics  [pw=wt_new_W12], cluster(startdate)
	
	
		# delimit ;
		esttab 	using appendC_gender_likemay.rtf, nogap se b(%9.3f) starlevels(* .05) r2(%9.4f) 
			title("Evals of May " )
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr


eststo clear 

	eststo gender_attitudes: logit may_bestpm i.post_attack##c.gender_attitudes $demographics  [pw=wt_new_W12], cluster(startdate)
	eststo gender_roles: logit may_bestpm i.post_attack##c.gender_roles $demographics  [pw=wt_new_W12], cluster(startdate)
	eststo female_equality: logit may_bestpm  i.post_attack##c.female_equality $demographics  [pw=wt_new_W12], cluster(startdate)
	eststo women_office: logit may_bestpm  i.post_attack##c.women_office $demographics  [pw=wt_new_W12], cluster(startdate)
	eststo women_discrimin: logit may_bestpm  i.post_attack##c.women_discrimin $demographics  [pw=wt_new_W12], cluster(startdate)
	eststo women_jobs: logit may_bestpm  i.post_attack##c.women_jobs $demographics  [pw=wt_new_W12], cluster(startdate)
	
	
		# delimit ;
		esttab 	using appendC_gender_bestpm.rtf, nogap se b(%9.3f) starlevels(* .05) pr2(%9.4f) 
			title("May best PM" )
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr
		
		
	eststo clear
	eststo gender_attitudes: reg likeMayW12 i.post_attack##c.gender_attitudes $demographics  [pw=wt_new_W12], cluster(startdate)
	margins r.post_attack, at(gender_attitudes=(0(.05)1)) atmeans

	marginsplot, title("") ///
	recast(line) recastci(rline) ciopts(lc(gray) lp(-) lw(vthin)) ///
	xtitle("Aggregate negative views of women", size(small)) ///
	xlab(0 "Least" 1 "Most", angle(45) labsize(small)) ///
	ytitle ("Diff in eval of May between pre & post attack", size(small))  title("") 
	graph save "append_gender_attitudes.gph", replace
		
***** gender roles *****


eststo clear 

	eststo gender_roles: reg likeMayW12 i.post_attack#c.gender_roles $demographics  [pw=wt_new_W12]
	margins r.post_attack, at(gender_roles=(1(1)5)) atmeans

 	marginsplot, title("") legend (rows(1) pos(6)) ///
	recast(line) recastci(rline) ciopts(lc(gray) lp(-) lw(vthin)) ///
	xtitle("A man’s job is to earn money", size(small)) ///
	xlab(1 "St. Disagree" 2 "Disagree" 3 "Neither" 4 "Agree" 5 "St. Agree", angle(45) labsize(small)) ///
	ytitle ("", size(small))  title("") 
	graph save "append_gender_roles.gph", replace
	graph export "append_gender_roles.png", replace width(1800)

	
**** women's equality 
eststo clear 

	eststo female_equality: reg likeMayW12 i.post_attack#c.female_equality $demographics  [pw=wt_new_W12]
	margins r.post_attack, at(female_equality=(1(1)5)) atmeans

 	marginsplot, title("") legend (rows(1) pos(6)) ///
	recast(line) recastci(rline) ciopts(lc(gray) lp(-) lw(vthin)) ///
	xtitle("Equal opportunities for women", size(small)) ///
	xlab(1 "Not nearly far enough" 2 "Not far enough" 3 "About right" 4 "Gone too far" 5 "Gone much too far", angle(45) labsize(small)) ///
	ytitle ("", size(small))  title("") 
	graph save "append_female_equality.gph", replace
	
eststo clear 		

**** women in office 
eststo clear 

	eststo women_office: reg likeMayW12 i.post_attack#c.women_office $demographics  [pw=wt_new_W12]
	margins r.post_attack, at(women_office=(1(1)5)) atmeans

 	marginsplot, title("") legend (rows(1) pos(6)) ///
	recast(line) recastci(rline) ciopts(lc(gray) lp(-) lw(vthin)) ///
	xtitle("Parliament +/- women", size(small)) ///
	xlab(1 "A lot more" 2 "Slightly more" 3 "Same as currently" 4 "Slightly fewer" 5 "A lot fewer", angle(45) labsize(small)) ///
	ytitle ("", size(small))  title("") 
	graph save "append_women_office.gph", replace
	
		
**** women discrimination 
eststo clear 

	eststo women_discrimin: reg likeMayW12 i.post_attack#c.women_discrimin $demographics  [pw=wt_new_W12]
	margins r.post_attack, at(women_discrimin=(1(1)10)) atmeans

 	marginsplot, title("") legend (rows(1) pos(6)) ///
	recast(line) recastci(rline) ciopts(lc(gray) lp(-) lw(vthin)) ///
	xtitle("Discrimination against women", size(small)) ///
	xlab(1 "Against" 2 3 4 5 6 7 8 9 10 "In favour", angle(45) labsize(small)) ///
	ytitle ("Diff in eval of May between pre & post attac", size(small))  title("") 
	graph save "append_women_discrimin.gph", replace
	
eststo clear

**** women in jobs 
eststo clear 

	eststo women_jobs: reg likeMayW12 i.post_attack#c.women_jobs $demographics  [pw=wt_new_W12]
	margins r.post_attack, at(women_jobs=(1(1)5)) atmeans

 	marginsplot, title("") legend (rows(1) pos(6)) ///
	recast(line) recastci(rline) ciopts(lc(gray) lp(-) lw(vthin)) ///
	xtitle("Women job advantage", size(small)) ///
	xlab(1 "St. disagree" 2 "Disagree" 3 "Neither" 4 "Agree" 5 "St. agree", angle(45) labsize(small)) ///
	ytitle ("", size(small))  title("") 
	graph save "append_women_jobs.gph", replace
	
	***** combining the graphs together ****** 
	
	
	graph combine "append_gender_attitudes.gph" "append_gender_roles.gph" "append_female_equality.gph" ///
	"append_women_discrimin.gph" "append_women_office.gph" "append_women_jobs.gph", ycommon ///
	col(3) graphregion(margin(none)) ysize(3.5) 
	graph save appendE_arfima_models.gph, replace
	graph export appendE_arfima_models.png, replace width(1800)
		
		
************ sep models by PID ************* 

eststo clear 


eststo likemay_l: reg likeMayW12  post_attack  $demographics if labour == 1  [pw=wt_new_W12]
eststo likemay_c: reg likeMayW12  post_attack  $demographics if conservative == 1  [pw=wt_new_W12]

eststo bestpm_l: logit may_bestpm post_attack  $demographics if labour == 1  [pw=wt_new_W12]
eststo bestpm_c: logit may_bestpm post_attack  $demographics if conservative == 1  [pw=wt_new_W12]



		# delimit ;
		esttab 	using appendC_bypid.rtf, nogap se b(%9.3f) starlevels(* .05) r2(%9.4f) pr2(%9.4f) 
			title("Like leaders + previous evals" )
			mtitle("Labour" "Conservatives" "Labour" "Conservatives")
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr
		
		

		
		***** looking within genders for appendix *** 

eststo clear 


eststo likemay_c: reg likeMayW12  post_attack  $demographics if gender == 0  [pw=wt_new_W12]
eststo likemay_l: reg likeMayW12  post_attack  $demographics if gender == 1  [pw=wt_new_W12]


		# delimit ;
		esttab 	using appendC_bygender.rtf, nogap se b(%9.3f) starlevels(* .05) r2(%9.4f) 
			title("Like leaders + previous evals" )
			mtitle("Men" "Women") 
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr
		
**** testing if differences between men and women are significant **** 

eststo clear 
eststo likemay_c: reg likeMayW12  post_attack##i.gender  $demographics  [pw=wt_new_W12]

		
***** ideological interactions **** 



eststo clear 



 reg likeMayW12  post_attack attack_ideology  $demographics
eststo ideo0: lincomest post_attack + [0]*attack_ideology
 reg likeMayW12  post_attack attack_ideology  $demographics
eststo ideo1: lincomest post_attack + [1]*attack_ideology
 reg likeMayW12  post_attack attack_ideology  $demographics
eststo ideo2: lincomest post_attack + [2]*attack_ideology
 reg likeMayW12  post_attack attack_ideology  $demographics
eststo ideo3:lincomest post_attack + [3]*attack_ideology
 reg likeMayW12  post_attack attack_ideology  $demographics
eststo ideo4:lincomest post_attack + [4]*attack_ideology
 reg likeMayW12  post_attack attack_ideology  $demographics
eststo ideo5:lincomest post_attack + [5]*attack_ideology
 reg likeMayW12  post_attack attack_ideology  $demographics
eststo ideo6:lincomest post_attack + [6]*attack_ideology
 reg likeMayW12  post_attack attack_ideology  $demographics
eststo ideo7:lincomest post_attack + [7]*attack_ideology
 reg likeMayW12  post_attack attack_ideology  $demographics
eststo ideo8:lincomest post_attack + [8]*attack_ideology
 reg likeMayW12  post_attack attack_ideology  $demographics
eststo ideo9:lincomest post_attack + [9]*attack_ideology
 reg likeMayW12  post_attack attack_ideology  $demographics
eststo ideo10:lincomest post_attack + [10]*attack_ideology



		# delimit ;
		esttab 	using appendC_ideology.rtf, nogap se b(%9.3f) starlevels(* .05) r2(%9.4f) 
			title("Like leaders + previous evals" )
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr
		
		

		
********** Appendix D comparing the results for other leaders ********* 

		
***** table of party effects to accompany figure 2 ***** 

	
**** comparison of leaders **** 
eststo clear

eststo likemay: reg likeMayW12 post_attack  $demographics  [pw=wt_new_W12] , cluster(startdate)
eststo likecor: reg likeCorbynW12 post_attack  $demographics [pw=wt_new_W12] , cluster(startdate)
eststo likefar: reg likeFarronW12 post_attack $demographics [pw=wt_new_W12] , cluster(startdate)
eststo likesturg: reg likeSturgeonW12 post_attack $demographics [pw=wt_new_W12] , cluster(startdate)
 

		# delimit ;
		esttab 	using appendD_comparison_leaders.rtf, nogap se b(%9.3f) starlevels(* .05) r2(%9.4f) 
			title("Manchester attack and view of leaders" "Wave survey weights" )
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr
		
		
****** including previous evals of leaders ***** 

eststo clear 

eststo likemay: reg likeMayW12 likeMayW11 post_attack  $demographics  [pw=wt_new_W12], cluster(startdate)
eststo likecor: reg likeCorbynW12 likeCorbynW11 post_attack $demographics  [pw=wt_new_W12], cluster(startdate)
eststo likefar: reg likeFarronW12 likeFarronW11 post_attack $demographics  [pw=wt_new_W12], cluster(startdate)
eststo likesturg: reg likeSturgeonW12 likeSturgeonW11 post_attack $demographics  [pw=wt_new_W12], cluster(startdate)

		# delimit ;
		esttab 	using appendD_like_previousrating.rtf, nogap se b(%9.3f) starlevels(* .05) r2(%9.4f) 
			title("Like leaders + previous evals" )
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr
		
	
*************** Appendix E time and validity checks *******************

eststo clear 


**** splitting control group at median *** 

eststo median_control: reg likeMayW12 median_control white gender labour party_other income ideology   [pw=wt_new_W12]
eststo median_control2: logit may_bestpm median_control white gender labour party_other income ideology  [pw=wt_new_W12]
     
		# delimit ;
		esttab 	using appendE_median_control.rtf, nogap se b(%9.3f) starlevels(* .05) r2(%9.4f) pr2(%9.4f) 
			title("pre-post attack")
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr

**** figure of currency values **** 
 
table startdate, c(mean econ_rate2)

*** note: to produce appendix figure, values were exported to excel **** 

**** counterfactual - something else happened


eststo clear 

eststo econ: reg likeMayW12 econ_rate2 post_attack   $demographics  [pw=wt_new_W12]
eststo brexit: reg likeMayW12 post_attack   $demographics2  [pw=wt_new_W12]
eststo bandwidth10: reg likeMayW12 post_attack  $demographics   if bandwidth10 == 1  [pw=wt_new_W12]
eststo bandwidth4: reg likeMayW12 post_attack   $demographics if bandwidth3 == 1  [pw=wt_new_W12]

		
		# delimit ;
		esttab 	using appendE_counterfact_like.rtf, nogap se b(%9.3f) starlevels(* .05) r2(%9.4f) 
			title("pre-post attack")
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr


	
**** counterfactual of May best PM 

eststo clear  

eststo econ: logit may_bestpm econ_rate2 post_attack   $demographics  [pw=wt_new_W12]
eststo brexit: logit may_bestpm  post_attack   $demographics2  [pw=wt_new_W12]
eststo bandwidth10: logit may_bestpm  post_attack  $demographics   if bandwidth10 == 1  [pw=wt_new_W12]
eststo bandwidth4: logit may_bestpm  post_attack   $demographics if bandwidth3 == 1  [pw=wt_new_W12]

		# delimit ;
		esttab 	using appendE_counterfact_best.rtf, nogap se b(%9.3f) starlevels(* .05) pr2(%9.4f) 
			title("pre-post attack")
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr



*** time accounts *** 


eststo clear 

	eststo cluster_day: reg likeMayW12 post_attack $demographics [iw=wt_new_W12], cluster(startdate)
	eststo cluster_date: reg likeMayW12 post_attack startdate $demographics [iw=wt_new_W12], cluster(startdate)
	eststo cluster_x_date: reg likeMayW12 post_attack i.post_attack#startdate $demographics [iw=wt_new_W12], cluster(startdate)
	eststo mlm: mixed likeMayW12 post_attack $demographics || startdate: 
	

		# delimit ;
		esttab 	using appendE_time_controls_like.rtf, nogap se b(%9.3f) starlevels(* .12) r2(%9.4f) 
			title("pre-post attack")
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr

eststo clear 

	eststo cluster_day: logit may_bestpm  post_attack $demographics [iw=wt_new_W12], cluster(startdate)
	eststo cluster_date: logit may_bestpm  post_attack startdate $demographics [iw=wt_new_W12], cluster(startdate)
	eststo cluster_x_date: logit may_bestpm  post_attack post_attack#startdate $demographics [iw=wt_new_W12], cluster(startdate)
	eststo mlm: mixed may_bestpm post_attack $demographics || startdate: 
	

		
		# delimit ;
		esttab 	using appendE_time_controls_best.rtf, nogap se b(%9.3f) starlevels(* .05) pr2(%9.4f) 
			title("pre-post attack")
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr

		
	***** ARFIMA MODELS **** 
		
		clear 
		
		use "BES_data.dta"
		
		collapse likeMayW12 may_bestpm likeCorbynW12 likeFarronW12 likeSturgeonW12 post_attack, by(startdate)
		
		
		tsset startdate, daily
	
		
		arfima likeMayW12 post_attack
		predict ptb
		label variable ptb "Predicted values in sample"
		predict fdtb, fdifference
		label variable fdtb "Predicted fractional-difference parameter" 
		twoway tsline ptb fdtb, legend(cols(1) pos(6)) ///
		ytitle("") xtitle("Views of May")
		graph save Graph  "appendE_like_may_arfima.gph",  replace
		
		
		arfima likeCorbynW12 post_attack
		predict ptb3
		label variable ptb3 "Predicted values in sample"
		predict fdtb3, fdifference
		label variable fdtb3 "Predicted fractional-difference parameter" 
		twoway tsline ptb3 fdtb3, legend(cols(1) pos(6)) ///
		ytitle("") xtitle("Views of Corbyn")
		graph save Graph  "appendE_like_corbyn_arfima.gph",  replace

		
		arfima likeFarronW12 post_attack
		predict ptb4
		label variable ptb4 "Predicted values in sample"
		predict fdtb4, fdifference
		label variable fdtb4 "Predicted fractional-difference parameter" 
		twoway tsline ptb4 fdtb4, legend(cols(1) pos(6)) ///
		ytitle("") xtitle("Views of Farron")
		graph save Graph  "appendE_like_farron_arfima.gph",  replace
		
		
		arfima likeSturgeonW12 post_attack
		predict ptb5
		label variable ptb5 "Predicted values in sample"
		predict fdtb5, fdifference
		label variable fdtb5 "Predicted fractional-difference parameter" 
		twoway tsline ptb5 fdtb5, legend(cols(1) pos(6)) ///
		ytitle("") xtitle("Views of Sturgeon")
		graph save Graph  "appendE_like_sturgeon_arfima.gph",  replace



	grc1leg appendE_like_may_arfima.gph appendE_like_corbyn_arfima.gph ///
	appendE_like_farron_arfima.gph  appendE_like_sturgeon_arfima.gph, scheme(s1mono) ycommon ///
	col(2) graphregion(margin(none)) ysize(3.5) 
	graph save appendE_arfima_models.gph, replace
	graph export appendE_arfima_models.png, replace width(1800)



		
**** difference in difference **** 

clear 
use did_data.dta

xtset id wave

eststo clear 

eststo didmay: xtreg likeMayW i.treatment1##i.time i.wave $demographics 
eststo didbestpm: xtreg bestPMW i.treatment1##i.time i.wave $demographics


		# delimit ;
		esttab 	using tab2_may_diff_diff.rtf, nogap se b(%9.4f) starlevels(* .05) 
			title("Diff-in-Diff evaluation" )
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr

eststo clear 

eststo didmay: xtreg likeMayW i.treatment1##i.time  $demographics 
eststo didbestpm: xtreg bestPMW i.treatment1##i.time $demographics


		# delimit ;
		esttab 	using appendA_may_diff_diff_ate.rtf, nogap se b(%9.3f) starlevels(* .05) 
			title("Diff-in-Diff evaluation" )
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr

eststo clear 
		
eststo didmay: xtreg likeMayW i.treatment1##i.time i.wave $demographics 
eststo didcorbyn: xtreg likeCorbynW i.treatment1##i.time i.wave $demographics 
eststo didfarron: xtreg likeFarronW i.treatment1##i.time i.wave $demographics 
eststo didsturg: xtreg likeSturgeonW i.treatment1##i.time i.wave $demographics 


		# delimit ;
		esttab 	using appendD_diffindiff_fe.rtf, nogap se b(%9.3f) starlevels(* .05)  
			title("Diff-in-Diff evaluation" )
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr

	****** 2012 Experiment ***** 
	clear
	set more off
	
	use "experimental2012.dta" 
		
***drop econ and gt***

drop if econ==1
drop if gt==1


reg feel_may terror
reg ft3a terror
reg feel_warsi terror
reg feel_clegg terror
reg feel_harman terror

sureg (ft3a terror) (feel_may terror)
test [ft3a]terror=[feel_may]terror
sureg (feel_warsi terror) (feel_may terror)
test [feel_warsi]terror=[feel_may]terror
sureg (feel_clegg terror) (feel_may terror)
test [feel_clegg]terror=[feel_may]terror
sureg (feel_harman terror) (feel_may terror)
test [feel_harman]terror=[feel_may]terror

eststo clear 

eststo may: quietly regress feel_may terror 
eststo cameron: quietly regress ft3a terror 
eststo warsi: quietly regress feel_warsi terror 
eststo clegg: quietly regress feel_clegg terror 
eststo harman: quietly regress feel_harman terror


		# delimit ;
		esttab  ///
		using appendF_2012experiment.rtf, nogap se b(%9.3f) starlevels(* .05) r2(%9.5f) 
			title("Feeling Thermometers & Terrorist Threat" )
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr
	
		
		***** outcome for Conservative party ***** 
		
clear


use "constituency_results_2017_election.dta" 



eststo clear
eststo con_change_1517: reg change_1517 distance c11Population over_65 c11EthnicityWhite  c11BornUK c11Christian c11Unemployed leave
	margins, at(distance=(1(5)430))   atmeans post 
	estimates store change_1517

eststo con_change_1015: reg change_1015 distance c11Population over_65 c11EthnicityWhite  c11BornUK c11Christian c11Unemployed leave
	margins, at(distance=(1(5)430))   atmeans post 
	estimates store change_1015

	
	coefplot (change_1517, label (Change 2015-2017)) (change_1015, label (Change 2010-2015)), ///
	 ytitle ("Conservative Vote Share")   title("") legend (rows(1) pos(6)) ///
	xlab(,labsize(vsmall)) xtitle ("Distance from Manchester (1000 km)") ///
	at recast(line) lwidth(*2) ciopts(recast(rline) lc(gray) lp(-) lw(vthin))
	graph save "fig4_distance_graph.gph", replace
	graph export "fig4_distance_graph.pdf", replace 

		# delimit ;
		esttab  ///
		using appendG_distance_conservative.rtf, nogap se b(%9.5f) starlevels(^ .10 * .05 ** .01 *** .001) r2(%9.5f) 
			title("Distance to Manchester & Change in Conservative Party Vote" )
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr
		

		************ Global analysis *************
		
		
set more off 
clear

**** set working directory here **** 

use "global_approval.dta"


**** testing where deaths = rally **** 
eststo clear 

eststo death_any:  quietly xtpcse lag_approval l(0/1).growth  l(0/1).log_inflation rally_event_any female_pres i.execrlc l(0/2).election_qtr f(1/2).election_qtr i.country_code , cor(psar1) i
eststo death6:  quietly xtpcse lag_approval l(0/1).growth   l(0/1).log_inflation rally_event_any female_pres i.execrlc l(0/2).election_qtr f(1/2).election_qtr i.country_code if rally_kill >=5, cor(psar1) i
eststo death11:  quietly xtpcse lag_approval l(0/1).growth   l(0/1).log_inflation rally_event_any female_pres i.execrlc l(0/2).election_qtr f(1/2).election_qtr i.country_code if rally_kill >=10, cor(psar1) i
eststo death12:  quietly xtpcse lag_approval l(0/1).growth   l(0/1).log_inflation rally_event_any female_pres i.execrlc l(0/2).election_qtr f(1/2).election_qtr i.country_code if rally_kill >=11, cor(psar1) i
eststo death13:  quietly xtpcse lag_approval l(0/1).growth   l(0/1).log_inflation rally_event_any female_pres i.execrlc l(0/2).election_qtr f(1/2).election_qtr i.country_code if rally_kill >=12, cor(psar1) i
eststo death14:  quietly xtpcse lag_approval l(0/1).growth   l(0/1).log_inflation rally_event_any female_pres i.execrlc l(0/2).election_qtr f(1/2).election_qtr i.country_code if rally_kill >=13, cor(psar1) i
eststo death15:  quietly xtpcse lag_approval l(0/1).growth   l(0/1).log_inflation rally_event_any female_pres i.execrlc l(0/2).election_qtr f(1/2).election_qtr i.country_code if rally_kill >=14, cor(psar1) i
eststo death16:  quietly xtpcse lag_approval l(0/1).growth   l(0/1).log_inflation rally_event_any female_pres i.execrlc l(0/2).election_qtr f(1/2).election_qtr i.country_code if rally_kill >=15, cor(psar1) i
eststo death17:  quietly xtpcse lag_approval l(0/1).growth   l(0/1).log_inflation rally_event_any female_pres i.execrlc l(0/2).election_qtr f(1/2).election_qtr i.country_code if rally_kill >=16, cor(psar1) i
eststo death18:  quietly xtpcse lag_approval l(0/1).growth   l(0/1).log_inflation rally_event_any female_pres i.execrlc l(0/2).election_qtr f(1/2).election_qtr i.country_code if rally_kill >=17, cor(psar1) i
eststo death19:  quietly xtpcse lag_approval l(0/1).growth   l(0/1).log_inflation rally_event_any female_pres i.execrlc l(0/2).election_qtr f(1/2).election_qtr i.country_code if rally_kill >=18, cor(psar1) i
eststo death20:  quietly xtpcse lag_approval l(0/1).growth   l(0/1).log_inflation rally_event_any female_pres i.execrlc l(0/2).election_qtr f(1/2).election_qtr i.country_code if rally_kill >=19, cor(psar1) i
eststo death21:  quietly xtpcse lag_approval l(0/1).growth   l(0/1).log_inflation rally_event_any female_pres i.execrlc l(0/2).election_qtr f(1/2).election_qtr i.country_code if rally_kill >=20, cor(psar1) i



*** note: to produce appendix figure, values were exported to excel **** 

	# delimit ;
		esttab  ///
		using "appendH_n_deaths.rtf", nogap se b(%9.3f) starlevels(* .05) r2(%9.4f) 
			title("Rally threshold" ) keep(rally_event_any) 
			mtitle ("Any deaths" "5+" "10+" "11+" "12+" "13+"  "14+"  "15+"  "16+"  "17+"  "18+"  "19+"  "20+")
			 label nonumbers
			//addnote("Dependent variable")//
			compress replace;
		#delimit cr
		
		
		
		
******  estimating effects of female pres 
		
		
eststo clear 

eststo comparative: xtpcse lag_approval c.kill_16##c.female_pres l(0/1).growth l(0/1).log_inflation  l(0/4).election_qtr i.execrlc i.country_code, cor(psar1) i

	# delimit ;
		esttab  ///
		using "tab4_global_analysis.rtf", nogap se b(%9.3f) starlevels(* .10 ** .05) r2(%9.5f) 
			title("International Terrorist Attacks and Executive Approval" )
			 label nonumbers
			addnote("Country fixed effects")
			compress replace;
		#delimit cr

		
		
**** estimating effects at different thresholds **** 

eststo clear 

eststo death08: quietly xtpcse lag_approval c.kill_08##c.female_pres l(0/1).growth l(0/1).log_inflation  l(0/4).election_qtr i.execrlc   i.country_code , cor(psar1) i
eststo death10: quietly  xtpcse lag_approval c.kill_10##c.female_pres l(0/1).growth l(0/1).log_inflation  l(0/4).election_qtr i.execrlc i.country_code , cor(psar1) i
eststo death12: quietly  xtpcse lag_approval c.kill_12##c.female_pres l(0/1).growth l(0/1).log_inflation  l(0/4).election_qtr i.execrlc   i.country_code , cor(psar1) i
eststo death14: quietly  xtpcse lag_approval c.kill_14##c.female_pres l(0/1).growth l(0/1).log_inflation  l(0/4).election_qtr i.execrlc i.country_code , cor(psar1) i
eststo death16: quietly  xtpcse lag_approval c.kill_16##c.female_pres  l(0/1).growth l(0/1).log_inflation  l(0/4).election_qtr i.execrlc i.country_code , cor(psar1) i
eststo death18: quietly  xtpcse lag_approval c.kill_18##c.female_pres  l(0/1).growth l(0/1).log_inflation  l(0/4).election_qtr i.execrlc i.country_code , cor(psar1) i

	# delimit ;
		esttab  ///
		using "appendH_thresholds.rtf", nogap se b(%9.3f) starlevels(* .10 ** .05) r2(%9.4f) 
			title("International Terrorist Attacks and Executive Approval" )
			 label nonumbers
			addnote("Country fixed effects")
			compress replace;
		#delimit cr
		
				
**** interaction between ideology and terrorism ****		
				
eststo clear 

eststo comparative: quietly  xtpcse lag_approval l(0/1).growth l(0/1).log_inflation c.kill_16##c.female_pres l(0/4).election_qtr c.kill_16##i.execrlc i.country_code, cor(psar1) i

	# delimit ;
		esttab  ///
		using "appendH_ideo_interact.rtf", nogap se b(%9.3f) starlevels(* .10 ** .05) r2(%9.5f) 
			title("International Terrorist Attacks and Executive Approval" )
			 label nonumbers
			addnote("Country fixed effects")
			compress replace;
		#delimit cr
		
		
****** party reputations ****** 

clear 

**** BES Expert survey **** 

**** set working directory **** 

use "BESExpertSurveyTrendFile2014-2019.dta" 

sum secvlibertiesCon secvlibertiesLibDem secvlibertiesSNP secvlibertiesLab if year == 2015
sum secvlibertiesCon secvlibertiesLibDem secvlibertiesSNP secvlibertiesLab if year == 2017
sum secvlibertiesCon secvlibertiesLibDem secvlibertiesSNP secvlibertiesLab if year == 2019

*** note: to produce appendix figure, values were exported to excel **** 
clear 

**** Comparative Manifesto Project *** 

**** set working directory ****

use "CMPdata.dta"

**** keeping Great Britain only **** 

keep if country == 51

**** law and order = per605 *** 

table partyname per605  if date == 201706 
table partyname per104  if date == 201706 

clear 

**** CSES data of party likability **** 

*** download data from https://cses.org/data-download/cses-integrated-module-dataset-imd/****
*** open that dataset ***

*drop all countries except UK 

drop if IMD1003<82601996
drop if IMD1003>82602015

*recode party like-dislike to make missing=.

recode IMD3008_A 96=. 98=. 99=., gen(like_partyA)
recode IMD3008_B 96=. 98=. 99=., gen(like_partyB)

*sort by election year and sum by year

sort IMD1013_Y
by IMD1013_Y: sum like_partyA
by IMD1013_Y: sum like_partyB


```

## How to run a script

Write each script to a file under the output directory, then run it with
exactly this command (the data directory is mounted read-only at its own
path; nothing else from the host is visible; `$SCRIPT` is the absolute path of
the script you wrote):

    SCRIPT=<repo>/benchmark/reproductions/holman-2022-theresa-may-rally/seeded/2026-11-02-b/script.R   # or <repo>/benchmark/reproductions/holman-2022-theresa-may-rally/seeded/2026-11-02-b/attempt-<n>/script.R
    docker run --rm --label retally.run=claude-code-holman-2022-theresa-may-rally-seeded-2026-11-02-b --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/seeded/2026-11-02-b/mount/holman_2022_theresa_may_rally:<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/seeded/2026-11-02-b/mount/holman_2022_theresa_may_rally:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R > "$(dirname "$SCRIPT")/stdout.txt" 2> "$(dirname "$SCRIPT")/stderr.txt"; echo "exit code: $?"

The sandbox time limit is 300 seconds (memory 4g, 1.0 CPU).  Wrap the
command in a timeout of that many seconds: prefix it with
`perl -e 'alarm shift; exec @ARGV' 300` (or `gtimeout 300` if installed;
macOS has no `timeout`).  If the timeout fires, stop the container with
`docker ps -q --filter label=retally.run=claude-code-holman-2022-theresa-may-rally-seeded-2026-11-02-b | xargs docker kill` and treat the
run as a crash (exit code 124).

## Output contract

The output directory `<repo>/benchmark/reproductions/holman-2022-theresa-may-rally/seeded/2026-11-02-b` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/holman-2022-theresa-may-rally/seeded/2026-11-02-b/
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

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/holman-2022-theresa-may-rally/seeded/2026-11-02-b`.
