# Retally reproduction task: settele-2022-gender-wage-gap-beliefs-policy (seeded, run 2026-11-10-b)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `settele-2022-gender-wage-gap-beliefs-policy`, mode `seeded`, run `2026-11-10-b`
- Paper: How Do Beliefs About the Gender Wage Gap Affect the Demand for Public Policy?
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b/mount/settele_2022_gender_wage_gap_beliefs_policy`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b/mount/settele_2022_gender_wage_gap_beliefs_policy` as data, and `<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b/paper.txt` as
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

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Claims to Reproduce
1. perception_index_democrat_table3_panelA_col4: 0.691 (standard deviations of the perception index) [type: coefficient]
   Location: Table 3, Panel A, Democrat, column (4) Perception Index
   Context: Table 3 ("Correlates of perceptions"), Panel A, column (4). OLS of the perception summary index on a Democrat indicator (Democrats include Independents leaning Democrat), a Female indicator, indicators for Independent and "other" political orientation (Republicans, incl. Independents leaning Republican, are the reference) and a dummy for survey wave B. The index combines the three perception items of columns (1)-(3) (gender differences in wages are large, are a problem, government should mitigate the gap), each z-scored on the pure control group, following Anderson (2008). Sample: the pure con…
2. perception_index_female_table3_panelA_col4: 0.181 (standard deviations of the perception index) [type: coefficient]
   Location: Table 3, Panel A, Female, column (4) Perception Index
   Context: Table 3, Panel A, column (4): the same regression of the perception index on Democrat, Female, Independent, "other" political orientation and a wave B dummy in the trimmed pure control group; the entry is the Female coefficient. Probability weights; robust standard errors.
3. perception_index_prior_table3_panelB_col4: -0.729 (standard deviations of the perception index per standard deviation of the prior) [type: coefficient]
   Location: Table 3, Panel B, Prior (z-scored), column (4) Perception Index
   Context: Table 3, Panel B, column (4): OLS of the perception index on the respondent's prior belief about females' relative wages (a woman's average wage for every $100 made by a man when both are 45-year-old employees with a Bachelor's degree working 40 hours per week), z-scored within the pure control group, and a wave B dummy. Same trimmed pure control group sample, probability weights and robust standard errors.
4. n_obs_table3: 921.0 (respondents) [type: count]
   Location: Table 3, Observations (all columns)
   Context: Number of observations in Table 3 (every column): pure control group respondents of both main-survey waves whose prior belief lies strictly between the 5th and 95th percentiles of the control group's prior distribution.
5. policy_demand_index_democrat_table4_panelA_col7: 0.669 (standard deviations of the policy demand index) [type: coefficient]
   Location: Table 4, Panel A, Democrat, column (7) Policy demand index
   Context: Table 4 ("Correlates of demand for specific policies"), Panel A, column (7). OLS of the policy demand summary index (Anderson 2008) over the six specific policies of columns (1)-(6) (gender quotas for leading positions, statutory affirmative action, stricter equal pay legislation, wage transparency within companies (wave A) or a reporting website for company wage statistics (wave B), subsidies to child care), each z-scored on the pure control group, on Democrat, Female, Independent and "other" political orientation and a wave B dummy. Trimmed pure control group as in Table 3; probability weigh…
6. policy_demand_index_prior_table4_panelB_col7: -0.302 (standard deviations of the policy demand index per standard deviation of the prior) [type: coefficient]
   Location: Table 4, Panel B, Prior (z-scored), column (7) Policy demand index
   Context: Table 4, Panel B, column (7): OLS of the policy demand index on the z-scored prior belief about females' relative wages and a wave B dummy in the trimmed pure control group. Probability weights; robust standard errors.
7. first_stage_posterior_raw_t74_table5_panelA_col1: -12.955 (dollars per $100 earned by a man (posterior belief, 0-200 scale)) [type: coefficient]
   Location: Table 5, Panel A: First Stage, T74, column (1)
   Context: Table 5 ("Treatment effect on perceptions and demand for specific policies"), Panel A, column (1). OLS of the respondent's posterior belief about females' relative wages (dollars per $100 a man earns, pooled across the five randomized versions of the posterior wage statistic) on T74, a dummy for the high-wage-gap information arm (told the ACS-based statistic) versus the low-wage-gap arm (told the CPS-based statistic). Sample: the two treatment arms of the main survey, both waves (pure control group excluded). Controls: survey wave, gender, prior belief, census region, age categories, having a …
8. first_stage_posterior_z_t74_table5_panelA_col2: -0.658 (standard deviations of the posterior belief) [type: coefficient]
   Location: Table 5, Panel A: First Stage, T74, column (2)
   Context: Table 5, Panel A, column (2): the column (1) regression with the posterior belief about females' relative wages z-scored as the outcome; the first stage of the Panel C 2SLS. Same treatment-arm sample, controls, probability weights and robust standard errors.
9. perception_index_t74_table5_panelA_col6: 0.417 (standard deviations of the perception index) [type: coefficient]
   Location: Table 5, Panel A: First Stage, T74, column (6) Perception Index
   Context: Table 5, Panel A, column (6): effect of T74 on the perception summary index over columns (3)-(5) (gender differences in wages are large, are a problem, government should mitigate the gap; each z-scored using the pure control group's mean and standard deviation), following Anderson (2008). Treatment-arm sample, the Table 5 controls, probability weights, robust standard errors.
10. iv_affirmative_action_posterior_table5_panelC_col2: -0.171 (standard deviations of policy demand per standard deviation of the posterior belief) [type: coefficient]
   Location: Table 5, Panel C: 2SLS, Posterior belief about fem. rel. wage (z-scored), column (2) Statutory affirmative action
   Context: Table 5, Panel C, column (2). 2SLS of demand for statutory affirmative action programs (agreement with the policy statement, z-scored on the pure control group) on the z-scored posterior belief about females' relative wages, instrumented by T74 (first stage: Panel A, column 2), with the Table 5 controls. Treatment-arm sample; probability weights; robust standard errors.
11. iv_equal_pay_legislation_posterior_table5_panelC_col3: -0.177 (standard deviations of policy demand per standard deviation of the posterior belief) [type: coefficient]
   Location: Table 5, Panel C: 2SLS, Posterior belief about fem. rel. wage (z-scored), column (3) Stricter equal pay legislation
   Context: Table 5, Panel C, column (3): the same 2SLS (z-scored posterior belief instrumented by T74, Table 5 controls) for demand for stricter equal pay legislation. Treatment-arm sample; probability weights; robust standard errors.
12. iv_policy_demand_index_posterior_table5_panelC_col7: -0.087 (standard deviations of the policy demand index per standard deviation of the posterior belief) [type: coefficient]
   Location: Table 5, Panel C: 2SLS, Posterior belief about fem. rel. wage (z-scored), column (7) Policy demand index
   Context: Table 5, Panel C, column (7): the same 2SLS for the policy demand summary index over the six specific policies (Anderson 2008). Treatment-arm sample; probability weights; robust standard errors.
13. followup_perception_index_t74_table6_panelA_col7: 0.156 (standard deviations of the follow-up perception index) [type: coefficient]
   Location: Table 6, Panel A: Perceptions, T74, column (7) Perception Index
   Context: Table 6 ("Persistence of the treatment effect in obfuscated follow-up survey"), Panel A, column (7). OLS of the follow-up perception summary index over columns (3)-(6) (gender differences in wages are a problem; government should increase efforts to support women in the labor market; gender wage differences are a problem among high-skilled and among low-skilled workers; each z-scored on the full follow-up sample), following Anderson (2008), on T74 and the Table 5 controls. Sample: treated respondents (both arms) who completed the follow-up survey, both waves. Probability weights; robust standa…

## Dataset Information
Name: settele_2022_gender_wage_gap_beliefs_policy
Local path: <repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b/mount/settele_2022_gender_wage_gap_beliefs_policy
File format: csv
Files in the dataset directory (paths relative to the local path above):
- data/SurveyStageII_WaveB_raw.dta (164.7 KB) — 606 rows, 56 columns: unemployed, student, gender, democrat, prior, wave, associatemore, loghhinc, selfemp, genderII, indep, govlowskilled, legislationanchorII, posteriorII, anychildren, govwomen, govwomenorder, fampolicy, fampolicyorder, wageproblemSQ001, wageproblemSQ002, wageproblemSQ003, wageproblemSQ004, wageproblem2SQ001, wageproblem2SQ002, wageproblem2SQ003, wageproblem2SQ004, submitdateII, panelID, startdateII, datestampII, ageII, employmentII, randorder2, fairnessSQ001, fairnessSQ002, gov…
- data/SurveyStageII_WaveA_raw.dta (124.6 KB) — 499 rows, 43 columns: unemployed, student, gender, democrat, prior, wave, associatemore, loghhinc, selfemp, genderII, indep, govwomen, govlowskilled, fampolicy, posteriorII, anychildren, wageproblemSQ001, wageproblemSQ002, wageproblemSQ003, wageproblemSQ004, submitdateII, panelID, startdateII, datestampII, ageII, employmentII, fairnessSQ001, fairnessSQ002, antidiscr, readII, discussII, rand, fulltime, parttime, midwest, south, west, age1, age2, age3, age4, otherpol, pweight
- data/SurveyStageI_WaveB_raw.dta (3.9 MB) — 1555 rows, 419 columns: region, gender, regionTime, transparencyanchor, legislationanchor, donationsummary, companysize, hhincome, trustcensus, transparencyanchorTime, legislationanchorTime, donationsummaryTime, companysizeTime, hhincomeTime, trustcensusTime, controlgroupnote, controlgroupnotenoin, womenwages, womenwagesorder, infodemand0, infodemand02, controlgroupnoteTime, controlgroupnotenoinTime, womenwagesTime, womenwagesorderTime, infodemand0Time, infodemand02Time, womenwage, womenwageTime, ch…
- data/SurveyStageI_WaveA_raw.dta (6.9 MB) — 2510 rows, 373 columns: region, gender, regionTime, controlgroupnote, transparencyanchor, legislationanchor, donationsummary, companysize, hhincome, trustcensus, controlgroupnoteTime, transparencyanchorTime, legislationanchorTime, donationsummaryTime, companysizeT…
- data/usa_00025.dta (5.5 GB) — 63194821 rows, 57 columns: year, region, nchild, datanum, serial, hhwt, statefip, county, countyfips, met2013, puma, gq, pernum, perwt, nchlt5, eldch, yngch, sex, age, marst, birthyr, marrinyr, fertyr, chborn, race, raced, hispan, hispand, bpl, bpld, citizen, racesin…
- data/cps_00004.dta (161.9 MB) — 1276235 rows, 54 columns: year, region, statecensus, serial, hwtfinl, cpsid, statefip, asecflag, metro, metarea, county, metfips, month, pernum, cpsidp, earnwt, wtfinl, lineno, age, sex, race, marst, popstat, bpl, mbpl, fbpl, nativity, hispan, educ, educ99, edcyc, e…
- All.log (2.2 MB)
- Read Me.pdf (381.4 KB)
- ado/_eststo.ado (841 B)
- ado/binscatter.ado (31.9 KB)
- ado/coefplot.ado (126.0 KB)
- ado/estadd.ado (78.8 KB)
- ado/estout.ado (169.1 KB)
- ado/estpost.ado (67.6 KB)
- ado/eststo.ado (10.0 KB)
- ado/esttab.ado (49.2 KB)
- ado/ivreg2.ado (223.0 KB)
- ado/minq.ado (1.1 KB)
- ado/multproc.ado (15.2 KB)
- ado/scheme-lean2.scheme (4.9 KB)
- ado/sigstar.ado (731 B)
- ado/sigstarnostars.ado (741 B)
- ado/sutex.ado (8.8 KB)
- ado/winsor.ado (2.5 KB)
- ado/wyoung.ado (9.1 KB)
- ado/wyoung.sthlp (8.8 KB)
- ado/zscore.ado (1.0 KB)
- data/Codebook_SurveyStageII_WaveA_raw.log (27.4 KB)
- data/Codebook_SurveyStageII_WaveB_raw.log (35.9 KB)
- data/Codebook_SurveyStageI_WaveA_raw.log (225.9 KB)
- data/Codebook_SurveyStageI_WaveB_raw.log (256.4 KB)
- data/acs_codebook.txt (106.4 KB)
- data/cps_codebook.txt (52.2 KB)
- dofiles/01_Master_Replication.do (3.4 KB)
- dofiles/02_Generate_Treatment_Values.do (2.1 KB)
- dofiles/03_SurveyStageIA_cleaning.do (23.9 KB)
- dofiles/04_SurveyStageIB_cleaning.do (26.2 KB)
- dofiles/05_SurveyStageIAB_append.do (15.3 KB)
- dofiles/06_SurveyStageIIAB_append_clean.do (9.9 KB)
- dofiles/07_MainFigures.do (11.1 KB)
- dofiles/08_MainTables.do (48.3 KB)
- dofiles/09_AdditionalFigures.do (58.4 KB)
- dofiles/10_AdditionalTables.do (121.1 KB)
- dofiles/11_InTextResults.do (14.9 KB)
- metadata.json (243 B)
- output/Display_Output.pdf (5.7 MB)
- output/Display_Output.tex (12.2 KB)
- surveys/limesurvey_survey_247726.lss (158.0 KB)
- surveys/limesurvey_survey_344617.lss (122.3 KB)
- surveys/limesurvey_survey_736385.lss (404.5 KB)
- surveys/limesurvey_survey_918833.lss (444.9 KB)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b/mount/settele_2022_gender_wage_gap_beliefs_policy' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
Installed packages (no network; nothing else can be installed): jsonlite, fixest, lfe, AER, ivreg, plm, estimatr, lme4, quantreg, car, sandwich, lmtest, clubSandwich, multiwayvcov, marginaleffects, MatchIt, optmatch, CBPS, WeightIt, cobalt, did, rdrobust, rddensity, Synth, modelsummary, stargazer, texreg, broom, tidyverse, dplyr, tidyr, readr, stringr, lubridate, data.table, haven, readxl, janitor, zoo, ggplot2, ggridges, ggrepel, gridExtra, cowplot, gtable, extrafont, sf, MASS, nnet, survival, splines, Matrix, boot, stats, utils.
Prefer fixest for fixed effects, IV and clustered SEs; use the other installed packages where the paper's method calls for them.
Set a deterministic seed with ``set.seed(42)`` for any randomness.
Do NOT access the internet; the container runs with --network none.
Do NOT shell out via system() / system2().
Emit RESULT:<name>=<value> lines to stdout at the end via cat().

## Original Replication Scripts
The replication package (the dataset directory) ships the authors' own analysis scripts, reproduced below.  These are the GROUND TRUTH for the exact estimating equation, variable names, sample restrictions, fixed effects, and standard-error clustering — follow them over anything reconstructed from the methodology summary, and prefer them over the paper's text where the two disagree.  Your job is to write R code that implements the SAME SPECIFICATION: translate what the scripts estimate, do not transliterate their syntax line by line (a Stata .do file's regression, e.g. `reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the equivalent fixest::feols() call in R).  Keep only the parts that produce the specific claims being reproduced; skip figure construction and unrelated robustness checks.  The scripts' data-file paths refer to the package's internal layout — resolve them against the dataset directory listed under Dataset Information.

Stata-to-fixest sample matching: feols() drops fixed-effect singletons by default, but Stata's `reg y x i.fe` / `xi:` dummies keep them.  Pass `fixef.rm = "none"` to every feols() call that has fixed effects, otherwise the observation count and the robust SEs drift from the paper's.  Stata's `, r` / `vce(robust)` is `vcov = "hetero"`.

### `dofiles/01_Master_Replication.do`
```stata


***********************************************************************************
// Replication Files
**********************************************************************************
/*
HOW DO BELIEFS ABOUT THE GENDER WAGE GAP AFFECT THE DEMAND FOR PUBLIC POLICY?
Sonja Settele
AEJ:pol
*/
**********************************************************************************

***********************************************************************************
**** Master file: Adjust directory and run to reproduce all results 
***********************************************************************************

clear 

global pm = char(177)
set more off

gl date = c(current_date)
if c(os) == "MacOSX" gl user "<home>/"
else if c(os) == "Windows" gl user "C:\Users\\`c(username)'"
else if c(os) == "Unix" gl user "/usr/`c(username)'"
di "$user

set graphics on  
 
** Adjust the following path to your own directory in which you store "data" and "dofiles" 
 
if "$user" == "C:\Users\gxf271"{
global path "C:\Users\gxf271\Dropbox\Forschung\Gender\redistribution\AEJPolicy_Revision\ReplicationFiles"
}

global output "$path\output"
adopath + "$path\ado"

set scheme lean2, permanent

cd "$path\dofiles" 

cap log close
log using "$path\All.log", replace	

// Baseline set of controls
global controls wave gender prior democrat indep otherpol midwest south west age1 age2 age3 age4 anychildren loghhinc associatemore fulltime parttime selfemp unemp student


*ØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØ*
***************** Generate Treatment Values ******************************************
*ØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØ*

do "02_Generate_Treatment_Values.do"

*ØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØ*
***************** Clean Survey Data ******************************************
*ØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØ*

// Wave A, main survey, prepare data
do "03_SurveyStageIA_cleaning.do"

// Wave B, main survey, prepare data
do "04_SurveyStageIB_cleaning.do"

// Wave A + B, main survey, append waves
do "05_SurveyStageIAB_append.do"

// Wave A + B, follow-up, append waves and prepare data
do "06_SurveyStageIIAB_append_clean.do"


*ØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØ*
***************** Replicate Tables and Figures  ***********************************
*ØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØ*

// Main Figures
do "07_MainFigures.do"

//Main Tables
do "08_MainTables.do"

// Appendix Figures
do "09_AdditionalFigures.do"

// Appendix Tables
do "10_AdditionalTables.do"

// In-text Results
do "11_InTextResults.do"



********************************************************************************************	
// END
*******************************************************************************************	

log off
exit
	

```

### `dofiles/08_MainTables.do`
```stata

***********************************************************************************
// Replication Files
**********************************************************************************
/*
HOW DO BELIEFS ABOUT THE GENDER WAGE GAP AFFECT THE DEMAND FOR PUBLIC POLICY?
Sonja Settele
AEJ:pol
*/
**********************************************************************************

***********************************************************************************
**** Generate Tables 2-8 in main paper 
**********************************************************************************

***********************************************************************************
// Table 2: Correlates of prior beliefs about gender differences in wages
***********************************************************************************

clear all
set more off

use "$path\data\SurveyStageI_AB_final.dta", clear
 
* Keep only incentivized priors 
keep if prior1==1

loc experiments "1 2 3 4 5 6 7 8"

preserve

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

/* Statistics */

loc colnum = 1
loc colnames ""
gen cons=1


    reg prior gender [pweight=pweight], vce(r)
    sigstar gender, prec(1)
    estadd loc thisstat2 = "`r(bstar)'": col`colnum'
    estadd loc thisstat3 = "`r(sestar)'": col`colnum'
	
	sigstar _cons, prec(1)
	estadd loc thisstat29 = "`r(bstar)'": col`colnum'
    estadd loc thisstat30 = "`r(sestar)'": col`colnum'
	qui sum prior
    estadd loc thisstat32 = r(N): col`colnum'
	
loc ++colnum
	
	reg prior democrat indep otherpol [pweight=pweight], vce(r)
	
	sigstar democrat, prec(1)
    estadd loc thisstat5 = "`r(bstar)'": col`colnum'
    estadd loc thisstat6 = "`r(sestar)'": col`colnum'
	sigstar indep, prec(1)
    estadd loc thisstat8 = "`r(bstar)'": col`colnum'
    estadd loc thisstat9 = "`r(sestar)'": col`colnum'
		
	sigstar _cons, prec(1)
	estadd loc thisstat29 = "`r(bstar)'": col`colnum'
    estadd loc thisstat30 = "`r(sestar)'": col`colnum'
	qui sum prior
    estadd loc thisstat32 = r(N): col`colnum'

loc ++colnum

	reg prior gender democrat indep otherpol [pweight=pweight], vce(r)
	sigstar gender, prec(1)
    estadd loc thisstat2 = "`r(bstar)'": col`colnum'
    estadd loc thisstat3 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(1)
    estadd loc thisstat5 = "`r(bstar)'": col`colnum'
    estadd loc thisstat6 = "`r(sestar)'": col`colnum'
	sigstar indep, prec(1)
    estadd loc thisstat8 = "`r(bstar)'": col`colnum'
    estadd loc thisstat9 = "`r(sestar)'": col`colnum'
		
	sigstar _cons, prec(1)
	estadd loc thisstat29 = "`r(bstar)'": col`colnum'
    estadd loc thisstat30 = "`r(sestar)'": col`colnum'
	qui sum prior
    estadd loc thisstat32 = r(N): col`colnum'
	
loc ++colnum

	reg prior gender democrat indep otherpol femdem femindep femotherpol [pweight=pweight], vce(r)
	sigstar gender, prec(1)
    estadd loc thisstat2 = "`r(bstar)'": col`colnum'
    estadd loc thisstat3 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(1)
    estadd loc thisstat5 = "`r(bstar)'": col`colnum'
    estadd loc thisstat6 = "`r(sestar)'": col`colnum'
	sigstar indep, prec(1)
    estadd loc thisstat8 = "`r(bstar)'": col`colnum'
    estadd loc thisstat9 = "`r(sestar)'": col`colnum'
	sigstar femdem, prec(1)
    estadd loc thisstat11 = "`r(bstar)'": col`colnum'
    estadd loc thisstat12 = "`r(sestar)'": col`colnum'
	sigstar femindep, prec(1)
    estadd loc thisstat14 = "`r(bstar)'": col`colnum'
    estadd loc thisstat15 = "`r(sestar)'": col`colnum'
		
	sigstar _cons, prec(1)
	estadd loc thisstat29 = "`r(bstar)'": col`colnum'
    estadd loc thisstat30 = "`r(sestar)'": col`colnum'
	qui sum prior
    estadd loc thisstat32 = r(N): col`colnum'
	
loc ++colnum
	
qui reg prior gender democrat indep otherpol employee [pweight=pweight], vce(r)
	sigstar gender, prec(1)
    estadd loc thisstat2 = "`r(bstar)'": col`colnum'
    estadd loc thisstat3 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(1)
    estadd loc thisstat5 = "`r(bstar)'": col`colnum'
    estadd loc thisstat6 = "`r(sestar)'": col`colnum'
	sigstar indep, prec(1)
    estadd loc thisstat8 = "`r(bstar)'": col`colnum'
    estadd loc thisstat9 = "`r(sestar)'": col`colnum'
	sigstar employee, prec(1)
	estadd loc thisstat17 = "`r(bstar)'": col`colnum'
    estadd loc thisstat18 = "`r(sestar)'": col`colnum'
		
	sigstar _cons, prec(1)
	estadd loc thisstat29 = "`r(bstar)'": col`colnum'
    estadd loc thisstat30 = "`r(sestar)'": col`colnum'
	qui sum prior
    estadd loc thisstat32 = r(N): col`colnum'
	
loc ++colnum
	
	reg prior gender democrat indep otherpol employee fememp [pweight=pweight], vce(r)
	sigstar gender, prec(1)
    estadd loc thisstat2 = "`r(bstar)'": col`colnum'
    estadd loc thisstat3 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(1)
    estadd loc thisstat5 = "`r(bstar)'": col`colnum'
    estadd loc thisstat6 = "`r(sestar)'": col`colnum'
	sigstar indep, prec(1)
    estadd loc thisstat8 = "`r(bstar)'": col`colnum'
    estadd loc thisstat9 = "`r(sestar)'": col`colnum'
	sigstar employee, prec(1)
	estadd loc thisstat17 = "`r(bstar)'": col`colnum'
    estadd loc thisstat18 = "`r(sestar)'": col`colnum'
	sigstar fememp, prec(1)
	estadd loc thisstat20 = "`r(bstar)'": col`colnum'
    estadd loc thisstat21 = "`r(sestar)'": col`colnum'
		
	sigstar _cons, prec(1)
	estadd loc thisstat29 = "`r(bstar)'": col`colnum'
    estadd loc thisstat30 = "`r(sestar)'": col`colnum'
	qui sum prior
    estadd loc thisstat32 = r(N): col`colnum'
	
loc ++colnum


qui reg prior gender democrat indep otherpol associatemore femassociate [pweight=pweight], vce(r)
	sigstar gender, prec(1)
    estadd loc thisstat2 = "`r(bstar)'": col`colnum'
    estadd loc thisstat3 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(1)
    estadd loc thisstat5 = "`r(bstar)'": col`colnum'
    estadd loc thisstat6 = "`r(sestar)'": col`colnum'
	sigstar indep, prec(1)
    estadd loc thisstat8 = "`r(bstar)'": col`colnum'
    estadd loc thisstat9 = "`r(sestar)'": col`colnum'
	sigstar associatemore, prec(1)
	estadd loc thisstat23 = "`r(bstar)'": col`colnum'
    estadd loc thisstat24 = "`r(sestar)'": col`colnum'
	sigstar femassociate, prec(1)
	estadd loc thisstat26 = "`r(bstar)'": col`colnum'
    estadd loc thisstat27 = "`r(sestar)'": col`colnum'
	
	sigstar _cons, prec(1)
	estadd loc thisstat29 = "`r(bstar)'": col`colnum'
    estadd loc thisstat30 = "`r(sestar)'": col`colnum'
	qui sum prior
    estadd loc thisstat32 = r(N): col`colnum'
	
loc ++colnum


	reg prior gender democrat indep otherpol employee fememp associatemore femassociate [pweight=pweight], vce(r)
	sigstar gender, prec(1)
    estadd loc thisstat2 = "`r(bstar)'": col`colnum'
    estadd loc thisstat3 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(1)
    estadd loc thisstat5 = "`r(bstar)'": col`colnum'
    estadd loc thisstat6 = "`r(sestar)'": col`colnum'
	sigstar indep, prec(1)
    estadd loc thisstat8 = "`r(bstar)'": col`colnum'
    estadd loc thisstat9 = "`r(sestar)'": col`colnum'
	sigstar employee, prec(1)
	estadd loc thisstat17 = "`r(bstar)'": col`colnum'
    estadd loc thisstat18 = "`r(sestar)'": col`colnum'
	sigstar fememp, prec(1)
	estadd loc thisstat20 = "`r(bstar)'": col`colnum'
    estadd loc thisstat21 = "`r(sestar)'": col`colnum'
	sigstar associatemore, prec(1)
	estadd loc thisstat23 = "`r(bstar)'": col`colnum'
    estadd loc thisstat24 = "`r(sestar)'": col`colnum'
	sigstar femassociate, prec(1)
	estadd loc thisstat26 = "`r(bstar)'": col`colnum'
    estadd loc thisstat27 = "`r(sestar)'": col`colnum'
	
	sigstar _cons, prec(1)
	estadd loc thisstat29 = "`r(bstar)'": col`colnum'
    estadd loc thisstat30 = "`r(sestar)'": col`colnum'
	qui sum prior
    estadd loc thisstat32 = r(N): col`colnum'
	
loc ++colnum
	
   
loc rowlabels " " " "Female" " " " " "Democrat" " " " " "Independent" " " " " "Female x Democrat" " " " " "Female x Independent" " " " " "Employee" " " " " "Female x Employee" " " " " "Associate Degree +" " " " " "Female x Ass. Degree +" " " " " "Constant" " " " " "Observations" "
loc rowstats ""

forval i = 1/32 {
    loc rowstats "`rowstats' thisstat`i'"
}

esttab * using "$output\priorcorrAB.tex", replace cells(none) booktabs nonotes nonum compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
  mtitle("(1)" "(2)" "(3)" "(4)" "(5)" "(6)" "(7)" "(8)") ///
 mgroups("Outcome variable: Incentivized prior belief", pattern(1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))



***********************************************************************************
// Table 3: Correlates of perceptions 
***********************************************************************************

clear all
set more off

use "$path\data\SurveyStageI_AB_final.dta", clear

loc experiments "large problem govmore z_mani_index"

*Keep only control group respondents
keep if rand==0

**z-score prior beliefs:  
foreach var of varlist prior{
egen mean_`var'=mean(`var') 
egen sd_`var'=sd(`var')
replace `var'=(`var'-mean_`var')/sd_`var'
drop mean_`var' sd_`var'
}


*Keep only those with prior beliefs above the 5th and below the 95th percentile of the distribution
sum prior,d
keep if prior > r(p5) & prior < r(p95)


// Build Panels A-C		    		   

preserve

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore


/* Statistics */

loc colnum = 1
loc colnames ""


foreach choice in `experiments' {

	
***Panel A: Main correlates: Dem, Female 
	
    qui reg `choice' i.wave democrat indep otherpol gender [pweight=pweight],r
	
	sigstar democrat, prec(3)
    estadd loc thisstat3 = "`r(bstar)'": col`colnum'
    estadd loc thisstat4 = "`r(sestar)'": col`colnum'
	
	sigstar gender, prec(3)
    estadd loc thisstat6 = "`r(bstar)'": col`colnum'
    estadd loc thisstat7 = "`r(sestar)'": col`colnum'

	
***Panel B: Raw correlation: z-scored prior 
	
    qui reg `choice' i.wave prior [pweight=pweight],r
	
	sigstar prior, prec(3)
    estadd loc thisstat10 = "`r(bstar)'": col`colnum'
    estadd loc thisstat11 = "`r(sestar)'": col`colnum'


***Panel C: Prior and main correlates: Dem, Rep, Female 

    qui reg `choice' prior i.wave democrat indep otherpol gender [pweight=pweight],r
	
	sigstar prior, prec(3)
    estadd loc thisstat14 = "`r(bstar)'": col`colnum'
    estadd loc thisstat15 = "`r(sestar)'": col`colnum'
	
	sigstar democrat, prec(3)
    estadd loc thisstat17 = "`r(bstar)'": col`colnum'
    estadd loc thisstat18= "`r(sestar)'": col`colnum'
	
	sigstar gender, prec(3)
    estadd loc thisstat20 = "`r(bstar)'": col`colnum'
    estadd loc thisstat21 = "`r(sestar)'": col`colnum'
	
	qui sum `choice'  
    estadd loc thisstat22 = r(N): col`colnum'	
	
    loc ++colnum
    loc colnames "`colnames' `"`: var la `choice''"'"	
	
	}


loc rowlabels " "{\bf Panel A}" " " "Democrat" " " " " "Female" " "  "\hline {\bf Panel B}" " " "Prior (z-scored)" " " "\hline {\bf Panel C}" " " "Prior (z-scored)" " " " " "Democrat" " " " " "Female" " " "\hline Observations" "\hline" "
loc rowstats ""  


loc rowstats ""

forval i = 1/22 {
    loc rowstats "`rowstats' thisstat`i'"
}

esttab * using "$output\tab_correlates_AB_5_95_PanelsA_C.tex", replace cells(none) booktabs nonotes nomtitles compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
	mgroups("\shortstack{Gender diff.\\ in wages\\are large}" "\shortstack{Gender diff.\\ in wages\\are a problem}"  ///
  "\shortstack{Government\\should mitigate\\gender wage gap}" "\shortstack{Perception\\Index}", pattern(1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

eststo clear



***********************************************************************************
// Table 4: Correlates of demand for specific policies
***********************************************************************************
  
preserve

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

loc experiments "quotaanchor AAanchor legislationanchor transparencyanchor UKtool childcare z_lmpolicy_index"

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore


/* Statistics */

loc colnum = 1
loc colnames ""


foreach choice in `experiments' {

	
***Panel A: Main correlates: Dem, Female 
	
    qui reg `choice' i.wave democrat indep otherpol gender [pweight=pweight],r
	
	sigstar democrat, prec(3)
    estadd loc thisstat3 = "`r(bstar)'": col`colnum'
    estadd loc thisstat4 = "`r(sestar)'": col`colnum'
	
	sigstar gender, prec(3)
    estadd loc thisstat6 = "`r(bstar)'": col`colnum'
    estadd loc thisstat7 = "`r(sestar)'": col`colnum'

	
***Panel B: Raw correlation: z-scored prior 
	
    qui reg `choice' i.wave prior [pweight=pweight],r
	
	sigstar prior, prec(3)
    estadd loc thisstat10 = "`r(bstar)'": col`colnum'
    estadd loc thisstat11 = "`r(sestar)'": col`colnum'


***Panel C: Prior and main correlates: Dem, Rep, Female 

    qui reg `choice' prior i.wave democrat indep otherpol gender [pweight=pweight],r
	
	sigstar prior, prec(3)
    estadd loc thisstat14 = "`r(bstar)'": col`colnum'
    estadd loc thisstat15 = "`r(sestar)'": col`colnum'
	
	sigstar democrat, prec(3)
    estadd loc thisstat17 = "`r(bstar)'": col`colnum'
    estadd loc thisstat18= "`r(sestar)'": col`colnum'
	
	sigstar gender, prec(3)
    estadd loc thisstat20 = "`r(bstar)'": col`colnum'
    estadd loc thisstat21 = "`r(sestar)'": col`colnum'
	
	qui sum `choice'  
    estadd loc thisstat22 = r(N): col`colnum'	
	
    loc ++colnum
    loc colnames "`colnames' `"`: var la `choice''"'"	
	
	}



loc rowlabels " "{\bf Panel A}" " " "Democrat" " " " " "Female" " "  "\hline {\bf Panel B}" " " "Prior (z-scored)" " " "\hline {\bf Panel C}" " " "Prior (z-scored)" " " " " "Democrat" " " " " "Female" " " "\hline Observations" "\hline" "
loc rowstats ""  


loc rowstats ""

forval i = 1/22 {
    loc rowstats "`rowstats' thisstat`i'"
}


esttab * using "$output\tab_correlates_AB_5_95_PanelsD_F.tex", replace cells(none) booktabs nonotes nomtitles compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
	mgroups("\shortstack{Introduce\\gender\\quotas}" "\shortstack{Statutory\\affirmative\\action}"  ///
  "\shortstack{Stricter\\equal pay\\legislation}" "\shortstack{Wage transp.\\within\\ companies}" "\shortstack{Introduce\\reporting\\website}" "\shortstack{Increase\\subsidies\\to child care}" ///
   "\shortstack{Policy\\demand\\index}", pattern(1 1 1 1 1 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))


***********************************************************************************
// Table 5: Treatment effect on perceptions and demand for specific policies
***********************************************************************************

// Note: The following code produces one table for Panel A and another table for Panels B-C. Stack manually to obtain final table.


clear all
set more off

use "$path\data\SurveyStageI_AB_final.dta", clear

* Drop pure control group
drop if rand==0

// Build Panel A
zscore posterior [aweight=pweight], stub(z)


loc experiments "posterior zposterior large problem govmore z_mani_index"
			   
preserve

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

/* Statistics */

loc colnum = 1
loc colnames ""



foreach choice in `experiments' {

   reg `choice' T1 $controls [pweight=pweight], vce(r) 
	
		local n = round(e(N))
			
			sigstar T1, prec(3)
			estadd loc thisstat3 = "`r(bstar)'": col`colnum'
			estadd loc thisstat4 = "`r(sestar)'": col`colnum'
			
			estadd loc thisstat7 = "`n'": col`colnum'
			
			loc ++colnum
}


* Calculate sharpened q-values for columns 3-5
 mat def P = J(5, 1, .)
	reg large T1 $controls [pweight=pweight], vce(r)
    qui test T1 = 0
    mat def P[1, 1] = r(p)	
	reg problem T1 $controls [pweight=pweight], vce(r)
	qui test T1 = 0
    mat def P[2, 1] = r(p)		
	reg govmore T1 $controls [pweight=pweight], vce(r)
	qui test T1 = 0
    mat def P[3, 1] = r(p)		

	
minq P, q("Q") step(0.001)
	
	estadd loc thisstat5 = "[" + string(Q[1, 1], "%9.3f") +"]" : col3
    estadd loc thisstat5 = "[" +string(Q[2, 1], "%9.3f")+"]": col4
    estadd loc thisstat5 = "[" + string(Q[3, 1], "%9.3f")+"]": col5
	
	
loc rowlabels " "\multicolumn{2}{l}{{\bf Panel A: First Stage}}" " " "T$^{74}$" " " "Sharpened q-value" " " "Observations" "

loc rowstats ""

forval i = 1/7 {
    loc rowstats "`rowstats' thisstat`i'"
}	
		

esttab * using "$output/tab_treatment_main_PanelA.tex", replace cells(none) booktabs nonotes nomtitles compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
	mgroups("\shortstack{Post. belief about\\fem. rel. wage\\(0-200)}" "\shortstack{Post. belief about\\fem. rel. wage\\(z-scored)}" "\shortstack{Gender diff.\\ in wages\\are large}" "\shortstack{Gender diff.\\ in wages\\are a problem}"  ///
  "\shortstack{Government\\should mitigate\\gender wage gap}" "\shortstack{Perception\\Index\\((2)-(4))}", pattern(1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	
eststo clear


// Build Panels B-C


preserve

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

loc experiments "quotaanchor AAanchor legislationanchor transparencyanchor UKtool childcare z_lmpolicy_index"

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore


/* Statistics */

loc colnum = 1
 
  
foreach choice in `experiments' {

***Panel B	

    reg `choice' T1 $controls [pweight=pweight], vce(r)
	local n = round(e(N))
	
    sigstar T1, prec(3)
    estadd loc thisstat3 = "`r(bstar)'": col`colnum'
    estadd loc thisstat4 = "`r(sestar)'": col`colnum'
	
	estadd loc thisstat7 = "`n'": col`colnum'
	

***Panel C	
	
	ivregress 2sls `choice' $controls (zposterior = T1) [pweight=pweight], vce(r) first
	local n = round(e(N))
	
    sigstar zposterior, prec(3)
    estadd loc thisstat10 = "`r(bstar)'": col`colnum'
    estadd loc thisstat11 = "`r(sestar)'": col`colnum'
	
	estadd loc thisstat13 = "`n'": col`colnum'
	
	
	loc ++colnum

}

* Calculate sharpened q-values for Panel B, columns 1-6
 mat def P = J(6, 1, .)
	reg quotaanchor T1 $controls [pweight=pweight], vce(r)
    qui test T1 = 0
    mat def P[1, 1] = r(p)	
	reg AAanchor T1 $controls [pweight=pweight], vce(r)
	qui test T1 = 0
    mat def P[2, 1] = r(p)		
	reg legislationanchor T1 $controls [pweight=pweight], vce(r)
	qui test T1 = 0
    mat def P[3, 1] = r(p)		
	reg transparencyanchor T1 $controls [pweight=pweight], vce(r)
	qui test T1 = 0
    mat def P[4, 1] = r(p)	
	reg UKtool T1 $controls [pweight=pweight], vce(r)
	qui test T1 = 0
    mat def P[5, 1] = r(p)
	reg childcare T1 $controls [pweight=pweight], vce(r)
	qui test T1 = 0
    mat def P[6, 1] = r(p)	

	
minq P, q("Q") step(0.001)
	
	estadd loc thisstat5 = "[" + string(Q[1, 1], "%9.3f") +"]" : col1
    estadd loc thisstat5 = "[" +string(Q[2, 1], "%9.3f")+"]": col2
    estadd loc thisstat5 = "[" + string(Q[3, 1], "%9.3f")+"]": col3
    estadd loc thisstat5 = "["+ string(Q[4, 1], "%9.3f")+"]": col4
    estadd loc thisstat5 = "["+ string(Q[5, 1], "%9.3f")+"]": col5
	estadd loc thisstat5 = "["+ string(Q[6, 1], "%9.3f")+"]": col6 
  
  
loc rowlabels " "\multicolumn{2}{l}{{\bf Panel B: Reduced Form}}" " " "T$^{74}$" " " "Sharpened q-value" " " "Observations" "\hline \multicolumn{2}{l}{{\bf Panel C: 2SLS}}" " " "$\widehat{\text{Posterior belief about}}$" "fem. rel. wage (z-scored)" " " "Observations" "
loc rowstats ""

forval i = 1/13 {
    loc rowstats "`rowstats' thisstat`i'"
}

esttab * using "$output\tab_treatment_main_PanelBC.tex", replace cells(none) booktabs nonotes nomtitles compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
	mgroups("\shortstack{Introduce\\gender\\quotas}" "\shortstack{Statutory\\affirmative\\action}"  ///
  "\shortstack{Stricter\\equal pay\\legislation}" "\shortstack{Wage transp.\\within\\ companies}" "\shortstack{Introduce\\reporting\\website}" "\shortstack{Increase\\subsidies\\to child care}" ///
   "\shortstack{Policy\\demand\\index}", pattern(1 1 1 1 1 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))


   
***********************************************************************************
// Table 6: Persistence of the treatment effect in obfuscated follow-up survey
***********************************************************************************

// Note: Code produces one table for Panel A and another table for Panel B. Stack manually to obtain final table.

clear all

use "$path\data\SurveyStageIIAB_final.dta"

drop if rand==0


// Build Panel A

loc experimentsII "posteriorII zposteriorII problemII govmoreII problemIIHS problemIILS z_maniII_index2"

			   
preserve

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experimentsII' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

/* Statistics */

loc colnum = 1
loc colnames ""


foreach choice in `experimentsII' {

***Panel A	

    reg `choice' T1 $controls [pweight=pweight], vce(r)
	local n = round(e(N))
	
	sigstar T1, prec(3)
    estadd loc thisstat3 = "`r(bstar)'": col`colnum'
    estadd loc thisstat4 = "`r(sestar)'": col`colnum'
	sigstar gender, prec(3)
    estadd loc thisstat7 = "`r(bstar)'": col`colnum'
    estadd loc thisstat8 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(3)
    estadd loc thisstat10 = "`r(bstar)'": col`colnum'
    estadd loc thisstat11 = "`r(sestar)'": col`colnum'
	
	estadd loc thisstat13 = "`n'": col`colnum'
   
    loc ++colnum
    loc colnames "`colnames' `"`: var la `choice''"'"

}


// FDR control
 
  mat def P = J(6, 1, .)
	reg posteriorII T1 $controls [pweight=pweight], vce(r)
    qui test T1 = 0
    mat def P[1, 1] = r(p)	
	reg zposteriorII T1 $controls [pweight=pweight], vce(r)
    qui test T1 = 0
    mat def P[2, 1] = r(p)	
	reg problemII T1 $controls [pweight=pweight], vce(r)
	qui test T1 = 0
    mat def P[3, 1] = r(p)		
	reg govmoreII T1 $controls [pweight=pweight], vce(r)
	qui test T1 = 0
    mat def P[4, 1] = r(p)	
	reg problemIIHS T1 $controls [pweight=pweight], vce(r)
	qui test T1 = 0
    mat def P[5, 1] = r(p)		
	reg problemIILS T1 $controls [pweight=pweight], vce(r)
	qui test T1 = 0
    mat def P[6, 1] = r(p)		
	
minq P, q("Q") step(0.001)
	
	estadd loc thisstat5 = "[" + string(Q[1, 1], "%9.3f") +"]" : col1
    estadd loc thisstat5 = "[" +string(Q[2, 1], "%9.3f")+"]": col2
    estadd loc thisstat5 = "[" + string(Q[3, 1], "%9.3f")+"]": col3
    estadd loc thisstat5 = "["+ string(Q[4, 1], "%9.3f")+"]": col4
    estadd loc thisstat5 = "["+ string(Q[5, 1], "%9.3f")+"]": col5
	estadd loc thisstat5 = "["+ string(Q[6, 1], "%9.3f")+"]": col6


    
loc rowlabels " "{\bf Panel A: Perceptions}" " " "T$^{74}$" " " "Sharpened q-value" " " "Female" " " " " "Democrat" " " " " "Observations" "
loc rowstats ""

forval i = 1/13 {
    loc rowstats "`rowstats' thisstat`i'"
}



esttab * using "$output\StageIIABmain_PanelA.tex", replace cells(none) booktabs nonotes compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
  mtitle("\shortstack{Post. belief \\about fem. \\rel. wage\\(0-200)}" "\shortstack{Post. belief\\ about fem.\\ rel. wage\\(z-scored)}" "\shortstack{Gender diff.\\ in wages\\are a \\problem}"  ///
 "\shortstack{Government\\should mitigate \\ gender \\ wage gap}" "\shortstack{Gender diff. in\\wages are a\\problem among\\high-skilled}" ///
 "\shortstack{Gender diff. in\\wages are a\\problem among\\low-skilled}"  "\shortstack{Perception\\Index\\((3)-(6))}") ///
    mgroups("Re-elicited Outcomes" "Newly elicited Outcomes" "Summary Index", pattern(1 0 0 0 1 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

eststo clear



// Build Panel B

loc experimentsIII "AAanchorII legislationanchorII fampolII antidiscII z_lmpolicyII_specific_index z_lmpolicyII_types_index fairII" 
 
preserve 

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experimentsIII' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

/* Statistics */

loc colnum = 1
loc colnames ""


foreach choice in `experimentsIII' {

***Panel A	

    reg `choice' T1 $controls [pweight=pweight], vce(r)
	local n = round(e(N))
	
    sigstar T1, prec(3)
    estadd loc thisstat3 = "`r(bstar)'": col`colnum'
    estadd loc thisstat4 = "`r(sestar)'": col`colnum'
	sigstar gender, prec(3)
    estadd loc thisstat7 = "`r(bstar)'": col`colnum'
    estadd loc thisstat8 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(3)
    estadd loc thisstat10 = "`r(bstar)'": col`colnum'
    estadd loc thisstat11 = "`r(sestar)'": col`colnum'
	
	estadd loc thisstat13 = "`n'": col`colnum'
   
    loc ++colnum
    loc colnames "`colnames' `"`: var la `choice''"'"

}

// FDR control 

mat def P = J(2, 1, .)
	reg AAanchorII T1 $controls [pweight=pweight], vce(r)
	qui test T1 = 0
    mat def P[1, 1] = r(p)	
	reg legislationanchorII T1 $controls [pweight=pweight], vce(r)
	qui test T1 = 0
    mat def P[2, 1] = r(p)
	
minq P, q("Q") step(0.001)
	estadd loc thisstat5 = "["+ string(Q[1, 1], "%9.3f")+"]": col1
	estadd loc thisstat5 = "["+ string(Q[2, 1], "%9.3f")+"]": col2		

 mat def P = J(2, 1, .)
	
	reg fampolII T1 $controls [pweight=pweight], vce(r)
	qui test T1 = 0
    mat def P[1, 1] = r(p)	
	reg antidiscII T1 $controls [pweight=pweight], vce(r)
	qui test T1 = 0
    mat def P[2, 1] = r(p)	
	
minq P, q("Q") step(0.001)
	estadd loc thisstat5 = "["+ string(Q[1, 1], "%9.3f")+"]": col3
	estadd loc thisstat5 = "["+ string(Q[2, 1], "%9.3f")+"]": col4	
	

	
loc rowlabels " "{\bf Panel B: Policy Demand}" " " "T$^{74}$" " " "Sharpened q-value" " " "Female" " " " " "Democrat" " " " " "Observations"  "
loc rowstats ""

forval i = 1/13 {
    loc rowstats "`rowstats' thisstat`i'"
}


esttab * using "$output\StageIIABmain_PanelB.tex", replace cells(none) booktabs nonotes compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
  mtitle("\shortstack{Statutory\\affirmative\\action}" "\shortstack{Stricter\\equal pay\\legislation}" ///
  "\shortstack{Supportive\\ policy}" "\shortstack{Anti- \\discrimination \\policy}"  ///
  "\shortstack{Policy\\demand\\index\\((1)-(2))}"  "\shortstack{Policy\\demand\\index\\((3)-(4))}" "\shortstack{Women's \\ wages\\are\\ fair}") ///
    mgroups("Re-elicited Outcomes" "Newly elicited Outcomes" "Summary Indices" "Mechanism", pattern(1 0 1 0 1 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))



***********************************************************************************
// Table 7: Heterogeneity in the treatment effect by gender and political orientation
***********************************************************************************

clear all
set more off

use "$path\data\SurveyStageI_AB_final.dta", clear


// Generate variable that indicates which posterior belief statistic was elicited
gen postgroup =. 
replace postgroup =1 if wave==1&RAND4== 9
replace postgroup = 2 if wave==1&RAND4==10
replace postgroup= 3 if wave==1&RAND4==11
replace postgroup = 4 if wave==2&RAND4==10
replace postgroup=5 if wave==2&RAND4==11


loc experiments1 "posterior quotaanchor AAanchor legislationanchor transparencyanchor UKtool childcare z_lmpolicy_index"
loc experiments "quotaanchor AAanchor legislationanchor transparencyanchor UKtool childcare z_lmpolicy_index"
  
 
// Set up table  
 
preserve

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments1' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

// Panel A: Heterogeneity by Gender

/* Column 1 */

reg posterior T1 T1female $controls i.postgroup [pweight=pweight] if rand!=0, vce(r)
    local n = round(e(N))
	
	sigstar T1, prec(3)
    estadd loc thisstat3 = "`r(bstar)'": col1
    estadd loc thisstat4 = "`r(sestar)'": col1
	sigstar T1female, prec(3)
    estadd loc thisstat6 = "`r(bstar)'": col1
    estadd loc thisstat7 = "`r(sestar)'": col1
	test 	T1 + T1female = 0
	estadd loc thisstat8 = string(r(p), "%9.3f"): col1
	
	sigstar gender, prec(3)
    estadd loc thisstat10 = "`r(bstar)'": col1
    estadd loc thisstat11 = "`r(sestar)'": col1
	
	estadd loc thisstat13 = "`n'": col1

	
	
/* Columns 2-9 */	
loc colnum = 2
loc colnames ""

foreach choice in `experiments' {

    qui reg `choice' T1 T1female $controls [pweight=pweight] if rand!=0, vce(r)
    local n = round(e(N))
	
	sigstar T1, prec(3)
    estadd loc thisstat3 = "`r(bstar)'": col`colnum'
    estadd loc thisstat4 = "`r(sestar)'": col`colnum'
	sigstar T1female, prec(3)
    estadd loc thisstat6 = "`r(bstar)'": col`colnum'
    estadd loc thisstat7 = "`r(sestar)'": col`colnum'
	test 	T1 + T1female = 0
	estadd loc thisstat8 = string(r(p), "%9.3f"): col`colnum'
	
	sigstar gender, prec(3)
    estadd loc thisstat10 = "`r(bstar)'": col`colnum'
    estadd loc thisstat11 = "`r(sestar)'": col`colnum'
	
	estadd loc thisstat13 = "`n'": col`colnum'

    loc ++colnum
    loc colnames "`colnames' `"`: var la `choice''"'"
	
}

// Panel B: Heterogeneity by political orientation

/* Column 1 */

    reg posterior T1 T1democrat T1indep $controls i.postgroup [pweight=pweight] if rand!=0&otherpol!=1, vce(r)
    local n = round(e(N))
	
	sigstar T1, prec(3)
    estadd loc thisstat16 = "`r(bstar)'": col1
    estadd loc thisstat17 = "`r(sestar)'": col1
	sigstar T1democrat, prec(3)
    estadd loc thisstat19 = "`r(bstar)'": col1
    estadd loc thisstat20 = "`r(sestar)'": col1
	
	test 	T1 + T1democrat = 0
	estadd loc thisstat21 = string(r(p), "%9.3f"): col1
	
	sigstar T1indep, prec(3)
    estadd loc thisstat23 = "`r(bstar)'": col1
    estadd loc thisstat24 = "`r(sestar)'": col1
	test 	T1 + T1indep = 0
	estadd loc thisstat25 = string(r(p), "%9.3f"): col1
	
	sigstar democrat, prec(3)
    estadd loc thisstat27 = "`r(bstar)'": col1
    estadd loc thisstat28 = "`r(sestar)'": col1
	sigstar indep, prec(3)
    estadd loc thisstat30 = "`r(bstar)'": col1
    estadd loc thisstat31 = "`r(sestar)'": col1
	
	estadd loc thisstat33 = "`n'": col1

/* Columns 2-9 */
	
loc colnum = 2
loc colnames ""

foreach choice in `experiments' {


    reg `choice' T1 T1democrat T1indep $controls [pweight=pweight] if rand!=0&otherpol!=1, vce(r)
    local n = round(e(N))
	
	sigstar T1, prec(3)
    estadd loc thisstat16 = "`r(bstar)'": col`colnum'
    estadd loc thisstat17 = "`r(sestar)'": col`colnum'
	sigstar T1democrat, prec(3)
    estadd loc thisstat19 = "`r(bstar)'": col`colnum'
    estadd loc thisstat20 = "`r(sestar)'": col`colnum'
	
	test 	T1 + T1democrat = 0
	estadd loc thisstat21 = string(r(p), "%9.3f"): col`colnum'
	
	sigstar T1indep, prec(3)
    estadd loc thisstat23 = "`r(bstar)'": col`colnum'
    estadd loc thisstat24 = "`r(sestar)'": col`colnum'
	test 	T1 + T1indep = 0
	estadd loc thisstat25 = string(r(p), "%9.3f"): col`colnum'
	
	sigstar democrat, prec(3)
    estadd loc thisstat27 = "`r(bstar)'": col`colnum'
    estadd loc thisstat28 = "`r(sestar)'": col`colnum'
	sigstar indep, prec(3)
    estadd loc thisstat30 = "`r(bstar)'": col`colnum'
    estadd loc thisstat31 = "`r(sestar)'": col`colnum'
	
	estadd loc thisstat33 = "`n'": col`colnum'
	
    loc ++colnum
    loc colnames "`colnames' `"`: var la `choice''"'"

}

	
loc rowlabels " "\multicolumn{2}{l}{{\bf Panel A: Het. by gender}}" " " "T$^{74}$" " " " " "T$^{74}$ x Female" " " "p-value [T$^{74}$ + T$^{74}$ x female]" " " "Female" " " " " "Observations" "\hline \multicolumn{2}{l}{{\bf Panel B: Het. by pol. orientation}}" " " "T$^{74}$" " " " " "T$^{74}$ x Democrat" " " "p-value [T$^{74}$ + T$^{74}$ x Dem.]" " " "T$^{74}$ x Independent" " " "p-value [T$^{74}$ + T$^{74}$ x Indep.]" " " "Democrat" " " " " "Independent" " " " " "Observations" " 
loc rowstats ""

forval i = 1/33 {
    loc rowstats "`rowstats' thisstat`i'"
}


esttab * using "$output\HetTreatment_femdemindAB.tex", replace cells(none) booktabs nonotes compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
	mtitle("\shortstack{Posterior\\belief about\\fem. rel. wage}"  ///
	"\shortstack{Introduce\\gender\\quotas}" "\shortstack{Statutory\\affirmative\\action}"  ///
  "\shortstack{Stricter\\equal pay\\legislation}" "\shortstack{Wage transp.\\within\\ companies}" "\shortstack{Introduce\\reporting\\website}" "\shortstack{Increase\\subsidies\\to child care}" ///
   "\shortstack{Policy\\demand\\index}" ) ///
   mgroups("First Stage" "Policy Demand", pattern(1 1 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

eststo clear



***********************************************************************************
// Table 8: Treatment effect on beliefs about underlying factors and fairness perceptions
***********************************************************************************


clear all
set more off

use "$path\data\SurveyStageI_AB_final.dta", clear

// Code produces two panels. Stack manually to obtain final table

// Drop pure control group
drop if rand==0

loc experimentsA "ambitious talented interested z_personalreasons_index"
loc experimentsB "discrimination boys society z_extreasons_index womenwages"

	
// Panel A:

	   
preserve

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experimentsB' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

/* Statistics */

loc colnum = 1
loc colnames ""


foreach choice in `experimentsA' {


    qui reg `choice' T1 $controls [pweight=pweight] if rand!=0, vce(r) 
	local n = round(e(N))
	
    sigstar T1, prec(3)
    estadd loc thisstat3 = "`r(bstar)'": col`colnum'
    estadd loc thisstat4 = "`r(sestar)'": col`colnum'
	sigstar gender, prec(3)
    estadd loc thisstat7 = "`r(bstar)'": col`colnum'
    estadd loc thisstat8 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(3)
    estadd loc thisstat10 = "`r(bstar)'": col`colnum'
    estadd loc thisstat11 = "`r(sestar)'": col`colnum'

	estadd loc thisstat13 = "`n'": col`colnum'
	
   
    loc ++colnum
    loc colnames "`colnames' `"`: var la `choice''"'"

}


// FDR control
mat def P = J(3, 1, .)

	reg ambitious T1 $controls if rand!=0, vce(r)
	qui test T1 = 0
    mat def P[1, 1] = r(p)	
	reg talented T1 $controls if rand!=0, vce(r)
	qui test T1 = 0
    mat def P[2, 1] = r(p)	
	reg interested T1 $controls if rand!=0, vce(r)
	qui test T1 = 0
    mat def P[3, 1] = r(p)	
	
	minq P, q("Q") step(0.001)

    estadd loc thisstat5 = "["+ string(Q[1, 1], "%9.3f")+"]": col1
	estadd loc thisstat5 = "["+ string(Q[2, 1], "%9.3f")+"]": col2
	estadd loc thisstat5 = "["+ string(Q[3, 1], "%9.3f")+"]": col3
	
	
loc rowlabels " "{\bf Panel A}" " " "T$^{74}$" " " "Sharpened q-value" " " "Female" " " " " "Democrat" " " " " "Observations" "
loc rowstats ""

forval i = 1/13 {
    loc rowstats "`rowstats' thisstat`i'"
}


esttab * using "$output\reasonsmainA.tex", replace cells(none) booktabs nonotes compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
  mtitle("Ambitions" "Talent" "Preferences" "Index") ///
    mgroups("Personal Factors", pattern(1 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

eststo clear



// Panel B:

	   
preserve

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experimentsB' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

/* Statistics */

loc colnum = 1
loc colnames ""


foreach choice in `experimentsB' {


    qui reg `choice' T1 $controls [pweight=pweight] if rand!=0, vce(r) 
	local n = round(e(N))
	
    sigstar T1, prec(3)
    estadd loc thisstat3 = "`r(bstar)'": col`colnum'
    estadd loc thisstat4 = "`r(sestar)'": col`colnum'
	sigstar gender, prec(3)
    estadd loc thisstat7 = "`r(bstar)'": col`colnum'
    estadd loc thisstat8 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(3)
    estadd loc thisstat10 = "`r(bstar)'": col`colnum'
    estadd loc thisstat11 = "`r(sestar)'": col`colnum'

	estadd loc thisstat13 = "`n'": col`colnum'
	
   
    loc ++colnum
    loc colnames "`colnames' `"`: var la `choice''"'"

}


mat def P = J(3, 1, .)

	reg discrimination T1 $controls if rand!=0, vce(r) 
    qui test T1 = 0
    mat def P[1, 1] = r(p)	
	reg boys T1 $controls if rand!=0, vce(r) 
	qui test T1 = 0
    mat def P[2, 1] = r(p)		
	reg society T1 $controls if rand!=0, vce(r) 
	qui test T1 = 0
    mat def P[3, 1] = r(p)		
	
	
minq P, q("Q") step(0.001)
	
	estadd loc thisstat5 = "[" + string(Q[1, 1], "%9.3f") +"]" : col1
    estadd loc thisstat5 = "[" +string(Q[2, 1], "%9.3f")+"]": col2
    estadd loc thisstat5 = "[" + string(Q[3, 1], "%9.3f")+"]": col3
	
loc rowlabels " "{\bf Panel B}" " " "T$^{74}$" " " "Sharpened q-value" " " "Female" " " " " "Democrat" " " " " "Observations" "
loc rowstats ""

forval i = 1/13 {
    loc rowstats "`rowstats' thisstat`i'"
}	


esttab * using "$output\reasonsmainB.tex", replace cells(none) booktabs nonotes compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
  mtitle("Discrimination" "Socialization" "Work-Family"  "Index" "of Women's Wages" ) ///
    mgroups("Impersonal Factors" "Fairness", pattern(1 0 0 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

eststo clear



***********************************************************************************
// Table 9: The role of beliefs about the effectiveness of policies
***********************************************************************************

*Note: Code produces three separate tables for Panels A,B and C. Stack panels manually to obtain final table

use "$path\data\SurveyStageI_AB_final.dta", clear

// Keep treatment groups of Wave B 
drop if rand==0
keep if wave==2

// Construct indicator for above median perceived effectiveness based on summary index
egen median_eff=median(z_eff_index)
gen abovemedeff=z_eff_index>median_eff 
replace abovemedeff=. if z_eff_index==.
gen T1abovemedeff= T1*abovemedeff


// Build Panel A

loc experiments "effdis effAA effworkfam z_eff_index"
  			   
preserve	

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

/* Statistics */

loc colnum = 1
loc colnames ""

foreach choice in `experiments' {


***Panel A	

    qui reg `choice' T1 $controls [pweight=pweight], vce(r)
    sigstar T1, prec(3)
    estadd loc thisstat2 = "`r(bstar)'": col`colnum'
    estadd loc thisstat3 = "`r(sestar)'": col`colnum'
	sigstar gender, prec(3)
    estadd loc thisstat5 = "`r(bstar)'": col`colnum'
    estadd loc thisstat6 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(3)
    estadd loc thisstat8 = "`r(bstar)'": col`colnum'
    estadd loc thisstat9 = "`r(sestar)'": col`colnum'
	
	qui sum `choice'
    estadd loc thisstat11 = r(N): col`colnum'

   
    loc ++colnum
    loc colnames "`colnames' `"`: var la `choice''"'"

}

	
loc rowlabels " "{\bf Panel A: Treatment Effect}" "T$^{74}$" " " " " "Female" " " " " "Democrat" " " " " "Observations" " "   "
loc rowstats ""

forval i = 1/11 {
    loc rowstats "`rowstats' thisstat`i'"
}



esttab * using "$output\effectivenessAB_PanelA.tex", replace cells(none) booktabs nonotes nomtitles compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
	mgroups("\shortstack{Perceived\\effectiveness\\of anti-disc. \\policies}" "\shortstack{Perceived\\effectiveness \\of affirmative\\ action }"  ///
  "\shortstack{Perceived\\effectiveness\\of work-family\\policies}" "\shortstack{Perceived\\effectiveness\\index\\((1)-(3))}"  ///
  , pattern(1 1 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	  
eststo clear


// Build Panel B 

loc experiments "quotaanchor AAanchor legislationanchor UKtool childcare z_lmpolicy_index"
		
		
preserve

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

/* Statistics */

loc colnum = 1
loc colnames ""

loc experiments "posterior large problem govmore z_mani_index"

foreach choice in `experiments' {

   reg `choice' T1 T1abovemedeff abovemedeff $controls [pweight=pweight], vce(r) 
	
		local n = round(e(N))
			
			sigstar T1, prec(3)
			estadd loc thisstat3 = "`r(bstar)'": col`colnum'
			estadd loc thisstat4 = "`r(sestar)'": col`colnum'
			
			sigstar T1abovemedeff, prec(3)
			estadd loc thisstat6 = "`r(bstar)'": col`colnum'
			estadd loc thisstat7 = "`r(sestar)'": col`colnum'
			
			sigstar abovemedeff, prec(3)
			estadd loc thisstat9 = "`r(bstar)'": col`colnum'
			estadd loc thisstat10 = "`r(sestar)'": col`colnum'
			
			test T1 + T1abovemedeff =0
			estadd loc thisstat12 = string(r(p), "%9.3f"): col`colnum'
			
			*estadd loc thisstat13 = "`n'": col`colnum'
			
			loc ++colnum
}


loc rowlabels " "\midline" "{\bf Panel B: First Stage}" "T$^{74}$ (a)" " " " " "T$^{74}$ x $\textbf{1}$ (Perceived" "effectiveness > p50) (b) " " " "$\textbf{1}$ (Perceived" "effectiveness > p50)" " " "p-value [(a) + (b) = 0]"  "
loc rowstats ""

forval i = 1/12 {
    loc rowstats "`rowstats' thisstat`i'"
}


esttab * using "$output\TreatmentFirst_hetbyeff_PanelB.tex", replace cells(none) booktabs nonotes nomtitles compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
mgroups("\shortstack{Posterior \\ belief about \\fem. rel. wage}" "\shortstack{Gender diff.\\ in wages\\are large}" "\shortstack{Gender diff.\\ in wages\\are a problem}"  ///
  "\shortstack{Government\\should mitigate\\gender wage gap}" "\shortstack{Perception\\index\\((2)-(4))}", pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

eststo clear


// Build Panel C

loc colnum = 1

loc experiments "quotaanchor AAanchor legislationanchor UKtool childcare z_lmpolicy_index"

preserve

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore
 			   
foreach choice in `experiments' {

    qui reg `choice' T1 T1abovemedeff abovemedeff $controls [pweight=pweight], vce(r)
	
	local n = round(e(N))
	
    sigstar T1, prec(3)
    estadd loc thisstat3 = "`r(bstar)'": col`colnum'
    estadd loc thisstat4 = "`r(sestar)'": col`colnum'
	sigstar T1abovemedeff, prec(3)
    estadd loc thisstat6 = "`r(bstar)'": col`colnum'
    estadd loc thisstat7 = "`r(sestar)'": col`colnum'

	sigstar abovemedeff, prec(3)
    estadd loc thisstat9 = "`r(bstar)'": col`colnum'
    estadd loc thisstat10 = "`r(sestar)'": col`colnum'
	
	test 	T1 + T1abovemedeff = 0
	estadd loc thisstat12 = string(r(p), "%9.3f"): col`colnum'
	
	
	estadd loc thisstat13 = "`n'": col`colnum'

			
	loc ++colnum

}


	
loc rowlabels " " " "{\bf Panel C: Reduced Form}" "T$^{74}$ (a)" " " " " "T$^{74}$ x $\textbf{1}$ (perceived" "effectiveness > p50) (b)" " " "$\textbf{1}$ (perceived" "effectiveness > p50" " " "p-value [(a) + (b) = 0]" "\hline Observations" " "   "
loc rowstats ""

forval i = 1/13 {
    loc rowstats "`rowstats' thisstat`i'"
}


esttab * using "$output\Treatmentpolicy_hetbyeff_PanelC.tex", replace cells(none) booktabs nonotes nomtitles compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
	mgroups("\shortstack{Introduce\\gender \\quotas}" "\shortstack{Statutory\\affirmative\\ action}"  ///
  "\shortstack{Stricter\\equal pay\\ legislation}" "\shortstack{Introduce\\reporting \\website}" "\shortstack{Increase\\subsidies\\ to child care}" ///
   "\shortstack{Policy\\demand\\Index}", pattern(1 1 1 1 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
  
  
eststo clear



***********************************************************************************
// Table 10: Correlates of willingness to pay for additional information
***********************************************************************************

use "$path\data\SurveyStageI_AB_final.dta", clear

// Keep only control group
keep if rand==0

// z-score willingness to pay for info 
foreach var of varlist infopaysupport infopayoppose{
egen mean_`var'=mean(`var') 
egen sd_`var'=sd(`var') 
replace `var'=(`var'-mean_`var')/sd_`var'
drop mean_`var' sd_`var'
}


loc experiments "infopaysupport infopaysupport infopaysupport infopaysupport infopaysupport infopaysupport infopaysupport infopaysupport"

preserve	

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

/* Statistics */

loc colnum = 1
loc colnames ""


foreach var in infopaysupport infopayoppose{

    qui reg `var' democrat indep otherpol [pweight=pweight], vce(r)
	local n = round(e(N))
	
	sigstar democrat, prec(3)
    estadd loc thisstat2 = "`r(bstar)'": col`colnum'
    estadd loc thisstat3 = "`r(sestar)'": col`colnum'
  
	estadd loc thisstat11 = "`n'": col`colnum'

    loc ++colnum
	
	reg `var' gender [pweight=pweight], vce(r)
	local n = round(e(N))
	
	sigstar gender, prec(3)
    estadd loc thisstat5 = "`r(bstar)'": col`colnum'
    estadd loc thisstat6 = "`r(sestar)'": col`colnum'
	
	estadd loc thisstat11 = "`n'": col`colnum'
	
	loc ++colnum
	
	
	reg `var' z_lmpolicy_index [pweight=pweight], vce(r)
	local n = round(e(N))
	
	sigstar z_lmpolicy_index, prec(3)
    estadd loc thisstat8 = "`r(bstar)'": col`colnum'
    estadd loc thisstat9 = "`r(sestar)'": col`colnum'
	
	estadd loc thisstat11 = "`n'": col`colnum'

    loc ++colnum
	
	reg `var' z_lmpolicy_index democrat indep otherpol gender [pweight=pweight], vce(r)
	local n = round(e(N))
   
	sigstar democrat, prec(3)
    estadd loc thisstat2 = "`r(bstar)'": col`colnum'
    estadd loc thisstat3 = "`r(sestar)'": col`colnum'
	
	sigstar gender, prec(3)
    estadd loc thisstat5 = "`r(bstar)'": col`colnum'
    estadd loc thisstat6 = "`r(sestar)'": col`colnum'
	
	sigstar z_lmpolicy_index, prec(3)
    estadd loc thisstat8 = "`r(bstar)'": col`colnum'
    estadd loc thisstat9 = "`r(sestar)'": col`colnum'
	
	estadd loc thisstat11 = "`n'": col`colnum'

    loc ++colnum
	
	
}
     
	
loc rowlabels " " " "Democrat" " " " " "Female" " " " " "Policy Demand (Index)" " " " " "Observations" " "   "
loc rowstats ""

forval i = 1/11 {
    loc rowstats "`rowstats' thisstat`i'"
}


esttab * using "$output\infopay_corr.tex", replace cells(none) booktabs nonotes nonum compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
  mtitle("(1)" "(2)" "(3)" "(4)" "(5)" "(6)" "(7)" "(8)") 	///
    mgroups("Willingness to pay for progressive info" "Willingness to pay for traditional info" , pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

eststo clear






```

### `dofiles/10_AdditionalTables.do`
```stata

***********************************************************************************
// Replication Files
**********************************************************************************
/*
HOW DO BELIEFS ABOUT THE GENDER WAGE GAP AFFECT THE DEMAND FOR PUBLIC POLICY?
Sonja Settele
AEJ:pol
*/
**********************************************************************************

***************************f********************************************************
**** Generate Appendix Tables 
***********************************************************************************

***********************************************************************************
// Table B.1: Representativeness of the sample in terms of targeted variables
***********************************************************************************

* Column "Mean: U.S. population age 18-65" -> Calculate values based on ACS 2016

clear all
set more off

use "$path\data\usa_00025.dta", clear

keep if year==2016
keep if age>17&age<66

//Census Region
gen northeast=(region==11|region==12)
gen midwest=(region==21|region==22)
gen south=(region==31|region==32|region==33)
gen west=(region==41|region==42)

mean northeast [pweight=perwt]
mean midwest [pweight=perwt]
mean south [pweight=perwt]
mean west [pweight=perwt]

// Age
mean age [pweight=perwt]

// Sex
replace sex=sex-1
mean sex [pweight=perwt]

// Employment
gen employed = (empstat==1)
mean employed [pweight=perwt]

// Household income
replace ftotinc=. if ftotinc==9999999
gen lowinc=ftotinc<=50000
mean lowinc [pweight=perwt]


clear all
use "$path\data\SurveyStageI_AB_final.dta"

* Define Democrats as Democrats (excluding Independents leaning Democrat)
replace democrat=0
replace democrat=1 if pol==2

* Define Republicans as Republicans (excluding Independents leaning Republican)
replace republican=0
replace republican=1 if pol==-2

* Define Independents as Independents and Independents leaning Democrat/Republican 
replace indep=0
replace indep=1 if pol==-1|pol==0|pol==1

lab var democrat "Democrat"
lab var republican "Republican"
lab var indep "Independent (including Indep. leaning Dem. or Rep.)"

* Targeted quotas 
*(Based on ACS 2016 for demographics -> See above)
*(Based on Pew Research 2018 for political orientation -> https://www.pewresearch.org/politics/2018/03/20/wide-gender-gap-growing-educational-divide-in-voters-party-identification/)

gen northeastACS=0.177
gen midwestACS=0.209
gen southACS=0.376
gen westACS=0.238
gen age_detACS=41.05
gen femaleACS=0.50
gen maleACS=0.50
gen employedACS=0.711
gen nonemployedACS=0.289
gen lowincACS=0.39
gen highincACS=0.61
gen democratACS=0.33
gen republicanACS=0.26
gen indepACS=0.37

loc covars "northeast midwest south west age_det female male employed nonemployed lowinc highinc democrat republican indep"

 preserve

    clear all
    eststo clear
    estimates drop _all

    set obs 10
    qui gen x = 1
    qui gen y = 1

    forval i = 1/2 {

        qui eststo col`i': reg x y

    }

    restore

	
/* Statistics */

    loc tabletitle "Representativeness of the sample in terms of targeted variables"
    loc rowstats ""
    loc rowlabels ""
    loc colnames " "Mean: Sample" "Mean: U.S. population age 18-65" "

    loc varlength: list sizeof covars
    loc varindex = 1

    mat def P1 = J(`varlength', 1, .)
    mat def P2 = J(`varlength', 1, .)
    mat def P3 = J(`varlength', 1, .)
	
	

 foreach var in `covars' {

	
        cap noi {
            mean `var' [pweight=pweight]
			matrix mean=e(b)
            estadd loc `var'_mean = string(mean[1,1], "%9.2f"): col1
        }
		
		 cap noi {
            sum `var'ACS 
            estadd loc `var'_mean = string(r(mean), "%9.2f"): col2
        }


        loc rowstats " `rowstats' `var'_mean "
        loc rowlabels "`rowlabels' `"`: var la `var''"' "

        loc ++varindex

    }

	esttab * using "$output\repACS2AB.tex", replace cells(none) booktabs nonotes nonum compress alignment(c) nogap noobs nobaselevels label mtitle(`colnames') stats(`rowstats', labels(`rowlabels'))
	eststo clear



***********************************************************************************
// Table B.2:  Main survey: Integrity of randomization
***********************************************************************************


use "$path\data\SurveyStageI_AB_final.dta", clear


* Generate indicators for any treatment group and for pure control group
gen T=T1+T2
gen C=rand==0


loc covars "female democrat republican indep otherpol prior northeast midwest south west age1 age2 age3 age4 age5 anychildren loghhinc associatemore fulltime parttime selfemp unemployed student oolf"


/* Balance table */

    preserve

    clear all
    eststo clear
    estimates drop _all

    set obs 10
    qui gen x = 1
    qui gen y = 1


loc experiments "Full Treatment Control T1 T2 Incent Noincent pvalueTC pvalueT1T2 pvalueincent"


loc columns = 0
	
	foreach choice in `experiments' {
	loc ++columns
    qui eststo col`columns': reg x y
}

    restore

loc colnum = 1
loc colnames ""



** Column 1: Full sample

loc varindex = 2

foreach var in `covars' {

summ `var'
local mean=round(r(mean),.001)
cap: estadd loc thisstat`varindex' = string(`mean', "%9.2f"): col1

loc ++varindex

}


summ prior 
local mean=round(r(N),.001)
cap: estadd loc thisstat27 = string(`mean', "%9.0f"): col1


** Column 2: Treatment groups pooled
loc varindex = 2

foreach var in `covars' {

summ `var' if T==1
local mean=round(r(mean),.001)
cap: estadd loc thisstat`varindex' = string(`mean', "%9.2f"): col2

loc ++varindex

}

summ prior if T==1
local mean=round(r(N),.001)
cap: estadd loc thisstat27 = string(`mean', "%9.0f"): col2


** Column 3: Control group
loc varindex = 2

foreach var in `covars' {

summ `var' if T==0
local mean=round(r(mean),.001)
cap: estadd loc thisstat`varindex' = string(`mean', "%9.2f"): col3

loc ++varindex

}

summ prior if T==0
local mean=round(r(N),.001)
cap: estadd loc thisstat27 = string(`mean', "%9.0f"): col3


** Column 4: T74
loc varindex = 2

foreach var in `covars' {

summ `var' if T1==1
local mean=round(r(mean),.001)
cap: estadd loc thisstat`varindex' = string(`mean', "%9.2f"): col4

loc ++varindex

}

summ prior if T1==1
local mean=round(r(N),.001)
cap: estadd loc thisstat27 = string(`mean', "%9.0f"): col4


** Column 5: T94
loc varindex = 2

foreach var in `covars' {

summ `var' if T2==1
local mean=round(r(mean),.001)
cap: estadd loc thisstat`varindex' = string(`mean', "%9.2f"): col5

loc ++varindex

}

summ prior if T2==1
local mean=round(r(N),.001)
cap: estadd loc thisstat27 = string(`mean', "%9.0f"): col5


* Column 6: Incentivized prior
loc varindex = 2

foreach var in `covars' {

summ `var' if prior1==1
local mean=round(r(mean),.001)
cap: estadd loc thisstat`varindex' = string(`mean', "%9.2f"): col6

loc ++varindex

}

summ prior if prior1==1
local mean=round(r(N),.001)
cap: estadd loc thisstat27 = string(`mean', "%9.0f"): col6



* Column 7: T94
loc varindex = 2

foreach var in `covars' {

summ `var' if prior1==0
local mean=round(r(mean),.001)
cap: estadd loc thisstat`varindex' = string(`mean', "%9.2f"): col7

loc ++varindex

}

summ prior if prior1==0
local mean=round(r(N),.001)
cap: estadd loc thisstat27 = string(`mean', "%9.0f"): col7



** Column 8: P-value for testing equality of means T-C 
loc varindex = 2

foreach var in `covars' {
mvtest means `var', by(T)
local p=round(r(p_F),.001)
cap: estadd loc thisstat`varindex' = string(`p', "%9.3f"): col8


loc ++varindex
}


** Column 9: P-value for testing equality of means T74 - T94 
loc varindex = 2

foreach var in `covars' {
mvtest means `var' if rand!=0, by(T1) 
local p=round(r(p_F),.001)
cap: estadd loc thisstat`varindex' = string(`p', "%9.3f"): col9

loc ++varindex
}


** Column 10: P-value for testing equality of means inc - no inc  
loc varindex = 2

foreach var in `covars' {
mvtest means `var', by(prior1)
local p=round(r(p_F),.001)
cap: estadd loc thisstat`varindex' = string(`p', "%9.3f"): col10

loc ++varindex

}


loc rowlabels " "Female" "Democrat" "Republican" "Independent" "Other pol. orientation" "Prior belief" "Northeast" "Midwest" "South" "West" "Age 18-24" "Age 25-34" "Age 35-44" "Age 45-54" "Age 55-65" "Has children" "Log household income" "Associate degree or more" "Full-time employee" "Part-time employee" "Self-employed" "Unemployed" "Student" "Out of labor force" " " "Observations" "

loc rowstats ""


forval i = 2/27	 {
    loc rowstats "`rowstats' thisstat`i'"
}


esttab * using "$output\sumstats_balance_main.tex", replace cells(none) booktabs nonotes /*nonum*//*nomtitles*/ compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
      mtitle("\shortstack{Full\\Sample}" "\shortstack{Treatment\\Groups}" "\shortstack{Control\\Group}" "\shortstack{T$^{74}$}" "\shortstack{T$^{94}$}" ///
	  "\shortstack{Prior\\incentivized}" "\shortstack{Prior not\\incentivized}" ///
	  "\shortstack{p-value \\ $(2)=(3)$}" "\shortstack{p-value \\ $(4)=(5)$}" "\shortstack{p-value \\ $(6)=(7)$}") ///
	  mgroups("Main survey" "Follow-up survey", pattern(1 0 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

	

// Joint F-tests mentioned in Table footnotes:
* Regress "any treatment group" on all covariats
reg T female democrat republican indep otherpol prior northeast midwest south west age1 age2 age3 age4 age5 anychildren loghhinc associatemore fulltime parttime selfemp unemployed student oolf, vce(r)
* Regress T74 dummy on all covariates, omitting pure control	  
reg T1 female democrat republican indep otherpol prior northeast midwest south west age1 age2 age3 age4 age5 anychildren loghhinc associatemore fulltime parttime selfemp unemployed student oolf if rand!=0, vce(r)
* Regress indicator for incentivized prior belief on all covariates
reg prior1 female democrat republican indep otherpol prior northeast midwest south west age1 age2 age3 age4 age5 anychildren loghhinc associatemore fulltime parttime selfemp unemployed student oolf, vce(r)
	
	
***********************************************************************************
// Table B.3:  Follow-up survey: Attrition and integrity of randomization
***********************************************************************************

use "$path\data\SurveyStageI_AB_final.dta", clear

// Merge Follow-up Data
merge 1:1 panelID using "$path\data\SurveyStageIIAB_final.dta"

* Identifier for Follow-up participants
gen StageII=(_merge==3)
drop _merge


* Generate indicators for any treatment group and for pure control group
gen T=T1+T2
gen C=rand==0


loc covars "female democrat republican indep otherpol prior northeast midwest south west age1 age2 age3 age4 age5 anychildren loghhinc associatemore fulltime parttime selfemp unemployed student oolf"


/* Balance table */

    preserve

    clear all
    eststo clear
    estimates drop _all

    set obs 10
    qui gen x = 1
    qui gen y = 1


loc experiments "StageII NoStageII T1follow T2follow pvalueStageII pvalueT1T2II"


loc columns = 0
	
	foreach choice in `experiments' {
	loc ++columns
    qui eststo col`columns': reg x y
}


    restore

loc colnum = 1
loc colnames ""



** Column 1: In follow-up (including control group)
loc varindex = 2

foreach var in `covars' {

summ `var' if StageII==1
local mean=round(r(mean),.001)
cap: estadd loc thisstat`varindex' = string(`mean', "%9.2f"): col1

loc ++varindex

}

summ prior if StageII==1
local mean=round(r(N),.001)
cap: estadd loc thisstat27 = string(`mean', "%9.0f"): col1


** Column 2: Not in follow-up (including control group)
loc varindex = 2

foreach var in `covars' {

summ `var' if StageII==0&T==1
local mean=round(r(mean),.001)
cap: estadd loc thisstat`varindex' = string(`mean', "%9.2f"): col2

loc ++varindex

}

summ prior if StageII==0&T==1
local mean=round(r(N),.001)
cap: estadd loc thisstat27 = string(`mean', "%9.0f"): col2


** Column 3: T74 in follow-up
loc varindex = 2

foreach var in `covars' {

summ `var' if T1==1&StageII==1
local mean=round(r(mean),.001)
cap: estadd loc thisstat`varindex' = string(`mean', "%9.2f"): col3

loc ++varindex

}

summ prior if T1==1&StageII==1
local mean=round(r(N),.001)
cap: estadd loc thisstat27 = string(`mean', "%9.0f"): col3


** Column 4: T94 in follow-up
loc varindex = 2

foreach var in `covars' {

summ `var' if T2==1&StageII==1
local mean=round(r(mean),.001)
cap: estadd loc thisstat`varindex' = string(`mean', "%9.2f"): col4

loc ++varindex

loc rowlabels "`rowlabels' `"`: var la `var''"' "

}

summ prior if T2==1&StageII==1
local mean=round(r(N),.001)
cap: estadd loc thisstat27 = string(`mean', "%9.0f"): col4


** Column 5: P-value for testing Stage II vs. not Stage II
loc varindex = 2

foreach var in `covars' {
mvtest means `var' if rand!=0, by(StageII) 
local p=round(r(p_F),.001)
cap: estadd loc thisstat`varindex' = string(`p', "%9.3f"): col5

loc ++varindex
}


** Column 6: P-value for testing equality of means T74 - T94 in follow-up
loc varindex = 2

foreach var in `covars' {
mvtest means `var' if rand!=0&StageII==1, by(T1) 
local p=round(r(p_F),.001)
cap: estadd loc thisstat`varindex' = string(`p', "%9.3f"): col6

loc ++varindex
}


loc rowlabels " "Female" "Democrat" "Republican" "Independent" "Other pol. orientation" "Prior belief" "Northeast" "Midwest" "South" "West" "Age 18-24" "Age 25-34" "Age 35-44" "Age 45-54" "Age 55-65" "Has children" "Log household income" "Associate degree or more" "Full-time employee" "Part-time employee" "Self-employed" "Unemployed" "Student" "Out of labor force" " " "Observations" "

loc rowstats ""


forval i = 2/27	 {
    loc rowstats "`rowstats' thisstat`i'"
}


esttab * using "$output\sumstats_balance_followup.tex", replace cells(none) booktabs nonotes /*nonum*//*nomtitles*/ compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
      mtitle("\shortstack{In\\Stage II sample}" "\shortstack{Not in\\Stage II sample}" "\shortstack{T$^{74}$\\(Stage II sample)}" "\shortstack{T$^{94}$\\(Stage II sample)}" ///
	   "\shortstack{p-value \\ $(1)=(2)$}"  "\shortstack{p-value \\ $(3)=(4)$}") ///
	  mgroups("Follow-up survey (Eligible respondents only)", pattern(1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

// P-values from joint F-tests mentioned in Table footnotes
* Outcome = Participation in follow-up
reg StageII female democrat republican indep otherpol prior northeast midwest south west age1 age2 age3 age4 age5 anychildren loghhinc associatemore fulltime parttime selfemp unemployed student oolf, vce(r)
* Outcome = T74, sample restricted to follow-up sample
reg T1 female democrat republican indep otherpol prior northeast midwest south west age1 age2 age3 age4 age5 anychildren loghhinc associatemore fulltime parttime selfemp unemployed student oolf if StageII==1, vce(r)
	

 
***********************************************************************************
// Table C.1: Gender and partisan differences in beliefs about the gender wage gap compared to other politically relevant beliefs
***********************************************************************************

// Calculate fem-male difference and left-right difference in z-scored prior beliefs

clear all
set more off

use "$path\data\SurveyStageI_AB_final", clear 

* Keep only incentivized priors 
keep if prior1==1

* z-score prior
egen z_prior=std(prior)

reg z_prior gender democrat indep otherpol [pweight=pweight], vce(r)

***********************************************************************************
// Table C.2: Correlates of beahvioral proxies of demand for government intervention
***********************************************************************************

clear all
set more off

use "$path\data\SurveyStageI_AB_final", clear 

* Drop control group
keep if rand==0

loc experiments "petIraw petIIraw donation fblike2raw"

**z-score prior:  
foreach var of varlist prior{
egen mean_`var'=mean(`var') 
egen sd_`var'=sd(`var')
replace `var'=(`var'-mean_`var')/sd_`var'
drop mean_`var' sd_`var'
}

*Keep only those with prior beliefs above the 5th and below the 95th percentile of the distribution
sum prior,d
keep if prior > r(p5) & prior < r(p95)

			    		   
preserve

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore


/* Statistics */

loc colnum = 1
loc colnames ""


foreach choice in `experiments' {

	
***Panel A: Main correlates: Dem, Female 
	
    reg `choice' democrat indep otherpol gender [pweight=pweight],r
	
	sigstar democrat, prec(3)
    estadd loc thisstat4 = "`r(bstar)'": col`colnum'
    estadd loc thisstat5 = "`r(sestar)'": col`colnum'
	
	sigstar gender, prec(3)
    estadd loc thisstat7 = "`r(bstar)'": col`colnum'
    estadd loc thisstat8 = "`r(sestar)'": col`colnum'
	

	
***Panel B: Raw correlation: z-scored prior 
	
    reg `choice' prior [pweight=pweight],r
	
	sigstar prior, prec(3)
    estadd loc thisstat13 = "`r(bstar)'": col`colnum'
    estadd loc thisstat14 = "`r(sestar)'": col`colnum'


***Panel C: Prior and main correlates: Dem, Rep, Female 

    reg `choice' prior democrat indep otherpol gender [pweight=pweight],r
	
	sigstar prior, prec(3)
    estadd loc thisstat19 = "`r(bstar)'": col`colnum'
    estadd loc thisstat20 = "`r(sestar)'": col`colnum'
	
	sigstar democrat, prec(3)
    estadd loc thisstat22 = "`r(bstar)'": col`colnum'
    estadd loc thisstat23 = "`r(sestar)'": col`colnum'
	
	sigstar gender, prec(3)
    estadd loc thisstat25 = "`r(bstar)'": col`colnum'
    estadd loc thisstat26 = "`r(sestar)'": col`colnum'


***Panel D: Correlates with prior, full set of controls 
	
    reg `choice' prior $controls [pweight=pweight],r
	
	sigstar prior, prec(3)
    estadd loc thisstat31 = "`r(bstar)'": col`colnum'
    estadd loc thisstat32 = "`r(sestar)'": col`colnum'
	
	sigstar democrat, prec(3)
    estadd loc thisstat34 = "`r(bstar)'": col`colnum'
    estadd loc thisstat35 = "`r(sestar)'": col`colnum'
	
	sigstar gender, prec(3)
    estadd loc thisstat37 = "`r(bstar)'": col`colnum'
    estadd loc thisstat38 = "`r(sestar)'": col`colnum'
	
	
	mean `choice' [pweight=pweight]
	matrix mean=e(b)
	matrix nobs=e(N)
	estadd loc thisstat40 = string(mean[1,1], "%9.2f"): col`colnum'
    estadd loc thisstat41 = string(nobs[1,1], "%9.0f"): col`colnum'

	
    loc ++colnum
    loc colnames "`colnames' `"`: var la `choice''"'"	
	
	}



loc rowlabels " "\hline" "{\bf Panel A: Gender and political orientation}" " " "Democrat" " " " " "Female" " " " "  "\hline" "{\bf Panel B: Prior belief about wage gap}" " " "Prior (z-scored)" " " " "  "\hline" "{\bf Panel C: Prior, gender, pol. orientation}" " " "Prior (z-scored)" " " " " "Democrat" " " " " "Female" " " " " "\hline" "{\bf Panel D: Full set of controls}" " " "Prior (z-scored)" " " " " "Democrat" " " " " "Female" " " " " "Mean outcome (control group)"  "Observations" " "  "\hline" "\hline"  "
loc rowstats ""  


loc rowstats ""

forval i = 1/42 {
    loc rowstats "`rowstats' thisstat`i'"
}

esttab * using "$output\tab_correlates_behaviorAB_5_95.tex", replace cells(none) booktabs nonotes nomtitles compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
	mgroups("\shortstack{Intention to sign\\Petition I}" "\shortstack{Intention to sign\\Petition II}"  ///
  "\shortstack{Amount donated\\to supportive NGO}" "\shortstack{Facebook Like}", pattern(1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	
eststo clear


***********************************************************************************
// Table D.1: Treatment effect on posterior beliefs
***********************************************************************************

clear all
set more off

use "$path\data\SurveyStageI_AB_final", clear 

* Drop control group
drop if rand==0

* Generate dummy indicating which posterior belief statistic respondent was assigned to
gen postgroup =. 
replace postgroup =1 if wave==1&RAND4== 9
replace postgroup = 2 if wave==1&RAND4==10
replace postgroup= 3 if wave==1&RAND4==11
replace postgroup = 4 if wave==2&RAND4==10
replace postgroup=5 if wave==2&RAND4==11


loc experiments "extraHS extrayoung extraoccu extrasame extrachild posterior" 	
	   
preserve

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

/* Statistics */

loc colnum = 1
loc colnames ""


foreach choice in `experiments' {

***Panel A	

    reg `choice' T1 $controls i.postgroup [pweight=pweight], vce(r)
    local n = round(e(N))
	
	sigstar T1, prec(1)
    estadd loc thisstat4 = "`r(bstar)'": col`colnum'
    estadd loc thisstat5 = "`r(sestar)'": col`colnum'
	sigstar gender, prec(1)
    estadd loc thisstat7 = "`r(bstar)'": col`colnum'
    estadd loc thisstat8 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(1)
    estadd loc thisstat10 = "`r(bstar)'": col`colnum'
    estadd loc thisstat11 = "`r(sestar)'": col`colnum'
	sigstar prior, prec(1)
    estadd loc thisstat13 = "`r(bstar)'": col`colnum'
    estadd loc thisstat14 = "`r(sestar)'": col`colnum'
	estadd loc thisstat16 = "`n'": col`colnum'
	

***Panel B	: het by gender

    reg `choice' T1 T1female $controls i.postgroup [pweight=pweight], vce(r)
	local n = round(e(N))
	
    sigstar T1, prec(1)
    estadd loc thisstat20 = "`r(bstar)'": col`colnum'
    estadd loc thisstat21 = "`r(sestar)'": col`colnum'
	sigstar T1female, prec(1)
    estadd loc thisstat23 = "`r(bstar)'": col`colnum'
    estadd loc thisstat24 = "`r(sestar)'": col`colnum'
	sigstar gender, prec(1)
    estadd loc thisstat27 = "`r(bstar)'": col`colnum'
    estadd loc thisstat28 = "`r(sestar)'": col`colnum'
	
	test 	T1 + T1female = 0
	estadd loc thisstat25 = string(r(p), "%9.3f"): col`colnum'
	estadd loc thisstat30 = "`n'": col`colnum'
	

***Panel C	: het by political orientation

    reg `choice' T1 T1democrat T1indep $controls i.postgroup [pweight=pweight] if otherpol==0, vce(r)
	local n = round(e(N))
		
    sigstar T1, prec(1)
    estadd loc thisstat34 = "`r(bstar)'": col`colnum'
    estadd loc thisstat35 = "`r(sestar)'": col`colnum'
	sigstar T1democrat, prec(1)
    estadd loc thisstat37 = "`r(bstar)'": col`colnum'
    estadd loc thisstat38 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(1)
    estadd loc thisstat41 = "`r(bstar)'": col`colnum'
    estadd loc thisstat42 = "`r(sestar)'": col`colnum'
	sigstar T1indep, prec(1)
    estadd loc thisstat44 = "`r(bstar)'": col`colnum'
    estadd loc thisstat45 = "`r(sestar)'": col`colnum'
	sigstar indep, prec(1)
    estadd loc thisstat48 = "`r(bstar)'": col`colnum'
    estadd loc thisstat49 = "`r(sestar)'": col`colnum'
	
	test 	T1 + T1democrat = 0
	estadd loc thisstat39 = string(r(p), "%9.3f"): col`colnum'
	test 	T1 + T1indep = 0
	estadd loc thisstat46 = string(r(p), "%9.3f"): col`colnum'
	
	estadd loc thisstat51 = "`n'": col`colnum'

    loc ++colnum
    loc colnames "`colnames' `"`: var la `choice''"'"

}

	
loc rowlabels " " " "{\bf Panel A: Avg. Treatment Effect}" " " "T$^{74}$" " " " " "Female" " " " " "Democrat" " " " " "Prior" " " " " "Observations"  "\hline"  "{\bf Panel B: Het by Gender}" " " "T$^{74}$" " " " " "T$^{74}$ * Female" " " "p-value [T$^{74}$ + T$^{74}$ x Female]" " " "Female" " " " " "Observations"  "\hline" "{\bf Panel C: Het by pol. attitude}" " " "T$^{74}$" " " " " "T$^{74}$ * Democrat" " " "p-value [T$^{74}$ + T$^{74}$ x Democrat]" " " "Democrat" " " " " "T$^{74}$ * Independent" " " "p-value [T$^{74}$ + T$^{74}$ x Independent]" " " "Independent" " "  " " "Observations" " " "
loc rowstats ""

forval i = 1/51 {
    loc rowstats "`rowstats' thisstat`i'"
}


esttab * using "$output/beliefhet_fempolAB.tex", replace cells(none) booktabs nonotes nomtitles compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
	mgroups("\shortstack{High school\\Degree}" "\shortstack{Age 25}"  ///
  "\shortstack{Same\\occupation}" "\shortstack{Parent}" "\shortstack{Same\\job}" "\shortstack{Posterior\\(pooled)}" ///
  , pattern(1 1 1 1 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	
	
eststo clear


***********************************************************************************
// Table D.2: Correlates of beliefs and treatment effect on beliefs about the wage gap
***********************************************************************************

clear all

use "$path\data\SurveyStageI_AB_final.dta", clear

* Drop respondents assigned to the unincentivized posterior belief about the wage gap controlling for job and employer
drop if extrasame!=.

loc experiments "extrayoung extraHS extraoccu extrachild posterior"
  		   
preserve	

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

/* Statistics */

loc colnum = 1
loc colnames ""


loc experiments "extrayoung extraHS extraoccu extrachild"

foreach choice in `experiments' {

* Panel A: Correlations

    reg `choice' gender democrat indep otherpol [pweight=pweight] if rand==0, vce(r)
    local n = round(e(N))
	
	sigstar gender, prec(2)
    estadd loc thisstat4 = "`r(bstar)'": col`colnum'
    estadd loc thisstat5 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(2)
    estadd loc thisstat7 = "`r(bstar)'": col`colnum'
    estadd loc thisstat8 = "`r(sestar)'": col`colnum'
	
	estadd loc thisstat10 = "`n'": col`colnum'
	
	
* Panel B: Treatment effect

	qui reg `choice' T1 $controls  [pweight=pweight] if rand!=0, vce(r)
	local n = round(e(N))
	
	sigstar T1, prec(2)
    estadd loc thisstat16 = "`r(bstar)'": col`colnum'
    estadd loc thisstat17 = "`r(sestar)'": col`colnum'
	
	estadd loc thisstat19 = "`n'": col`colnum'
    loc ++colnum

}

// Add unweighted averages manually

* Panel A: 
	estadd loc thisstat4 = "-1.80": col5
    estadd loc thisstat7 = "-4.50": col5
	estadd loc thisstat10 = "763": col5

* Panel B: 
	estadd loc thisstat16 = "-13.36": col5
	estadd loc thisstat19 = "2,499": col5
	
loc rowlabels " " " "{\bf Panel A: Correlations}" " " "Female" " " " " "Democrat" " " " " "Observations" " "   "\hline" " " "{\bf Panel B: Treatment effect}" " " "T$^{74}$" " " " " "Observations" " " "
loc rowstats ""

forval i = 1/20 {
    loc rowstats "`rowstats' thisstat`i'"
}


esttab * using "$output/backofenvelope_beliefsAB.tex", replace cells(none) booktabs nonotes compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
  mtitle("Age 25" "HS degree" "Same occu."  "Parent" "Average") ///
    mgroups("Outcome: (Incentivized) beliefs about the size of the wage gap", pattern(1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))


***********************************************************************************
// Table D.4: Follow-up survey: No treatment effect on placebo outcomes
***********************************************************************************

use "$path\data\SurveyStageIIAB_final.dta", clear

drop if rand==0

loc experimentsII "problemskill fairskill govmoreLS"
  		   
preserve

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experimentsII' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

/* Statistics */

loc colnum = 1
loc colnames ""


foreach choice in `experimentsII' {

    reg `choice' T1 $controls [pweight=pweight], vce(r)
    sigstar T1, prec(3)
    estadd loc thisstat2 = "`r(bstar)'": col`colnum'
    estadd loc thisstat3 = "`r(sestar)'": col`colnum'
	sigstar gender, prec(3)
    estadd loc thisstat5 = "`r(bstar)'": col`colnum'
    estadd loc thisstat6 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(3)
    estadd loc thisstat8 = "`r(bstar)'": col`colnum'
    estadd loc thisstat9 = "`r(sestar)'": col`colnum'
	qui sum `choice'
    estadd loc thisstat11 = r(N): col`colnum'

    loc ++colnum
    loc colnames "`colnames' `"`: var la `choice''"'"

}

    
	
loc rowlabels " " " "T$^{74}$" " " " " "Female" " " " " "Democrat" " " " " "Observations"  "
loc rowstats ""

forval i = 1/11 {
    loc rowstats "`rowstats' thisstat`i'"
}


esttab * using "$output/StageIIAB_placebo.tex", replace cells(none) booktabs nonotes nomtitles compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
	mgroups("\shortstack{Wage differences btw high-\\and low-skilled are a prob.}" "\shortstack{Low skilled workers's wages\\are fair}"  ///
  "\shortstack{Government should support\\low-skilled workers more}", pattern(1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
 
 eststo clear
	

***********************************************************************************
// Table D.5:  Follow-up survey: No role for attrition
***********************************************************************************	

clear all
set more off

use "$path\data\SurveyStageI_AB_final", clear

// Merge Follow-up Data
merge 1:1 panelID using "$path\data\SurveyStageIIAB_final.dta"

* Identifier for Follow-up participants
gen StageII=(_merge==3)
drop _merge

* Drop pure control
drop if rand==0

// Generate table
loc experiments "posterior problem womenwages govmore AAanchor legislationanchor"
 	
preserve

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

/* Statistics */

loc colnum = 1
loc colnames ""


foreach choice in `experiments' {

***Panel A: Stage I results

    qui reg `choice' T1 $controls [pweight=pweight], vce(r)
    local n = round(e(N))
	
	sigstar T1, prec(3)
    estadd loc thisstat4 = "`r(bstar)'": col`colnum'
    estadd loc thisstat5 = "`r(sestar)'": col`colnum'
	sigstar gender, prec(3)
    estadd loc thisstat7 = "`r(bstar)'": col`colnum'
    estadd loc thisstat8 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(3)
    estadd loc thisstat10 = "`r(bstar)'": col`colnum'
    estadd loc thisstat11 = "`r(sestar)'": col`colnum'
	
	estadd loc thisstat13 = "`n'": col`colnum'
	
	
***Panel B: Stage I results restricted to Stage II sample	

    qui reg `choice' T1 $controls [pweight=pweight] if StageII==1 , vce(r)
    local n = round(e(N))
	
	sigstar T1, prec(3)
    estadd loc thisstat19 = "`r(bstar)'": col`colnum'
    estadd loc thisstat20 = "`r(sestar)'": col`colnum'
	sigstar gender, prec(3)
    estadd loc thisstat22 = "`r(bstar)'": col`colnum'
    estadd loc thisstat23 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(3)
    estadd loc thisstat25 = "`r(bstar)'": col`colnum'
    estadd loc thisstat26 = "`r(sestar)'": col`colnum'
	
   estadd loc thisstat28 = "`n'": col`colnum'
   
   loc ++colnum
   loc colnames "`colnames' `"`: var la `choice''"'"

}


loc colnum = 1
loc colnames ""

loc experimentsII "posteriorII problemII fairII govmoreII AAanchorII legislationanchorII"

foreach choice in `experimentsII' {

***Panel C: Stage II results

    qui reg `choice' T1 $controls [pweight=pweight], vce(r)
	local n = round(e(N))
  
	sigstar T1, prec(3)
    estadd loc thisstat34 = "`r(bstar)'": col`colnum'
    estadd loc thisstat35 = "`r(sestar)'": col`colnum'
	sigstar gender, prec(3)
    estadd loc thisstat37 = "`r(bstar)'": col`colnum'
    estadd loc thisstat38 = "`r(sestar)'": col`colnum'
	sigstar democrat, prec(3)
    estadd loc thisstat40 = "`r(bstar)'": col`colnum'
    estadd loc thisstat41 = "`r(sestar)'": col`colnum'
	
	estadd loc thisstat43 = "`n'": col`colnum'

 loc ++colnum
 loc colnames "`colnames' `"`: var la `choice''"'"

}


loc rowlabels " " " "{\bf Panel A: Main results}" " " "T$^{74}$" " " " " "Female" " " " " "Democrat" " " " " "Observations" " " "\hline" " " "{\bf Panel B: Main results (follow-up sample)}" " " "T$^{74}$" " " " " "Female" " " " " "Democrat" " " " " "Observations" " "  "\hline" " " "{\bf Panel C: Follow-up results}" " " "T$^{74}$" " " " " "Female" " " " " "Democrat" " " " " "Observations" " "   "
loc rowstats ""


forval i = 1/43 {
    loc rowstats "`rowstats' thisstat`i'"
}


esttab * using "$output\StageI_II_selection.tex", replace cells(none) booktabs nonotes nomtitles compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
	mgroups("\shortstack{Posterior\\belief about\\fem.rel.wage\\(percent)}" "\shortstack{Gender\\differences\\in wages\\are a problem}"  ///
  "\shortstack{Women's\\wages\\are\\fair}" "\shortstack{Government\\should mitigate\\gender\\wage gap}" ///
  "\shortstack{Statutory\\affirmative\\action}" "\shortstack{Stricter\\equal pay\\legislation}", pattern(1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
 
 eststo clear
 	
 
***********************************************************************************
// Table D.6: First stage, reduced form and 2SLS: Heterogeneity by interest in topic
***********************************************************************************

clear all

// Note: The following code produces one table for Panels A and another table for Panel B. Stack manually to obtain final table.

use "$path\data\SurveyStageI_AB_final.dta", clear

// Panel A: 

drop if read==2
gen T1read=T1*read

gen posteriorread=posterior*read
gen largeread=large*read
gen problemread=problem*read

drop if rand==0

gen postgroup =. 
replace postgroup =1 if wave==1&RAND4== 9
replace postgroup = 2 if wave==1&RAND4==10
replace postgroup= 3 if wave==1&RAND4==11
replace postgroup = 4 if wave==2&RAND4==10
replace postgroup=5 if wave==2&RAND4==11

loc experiments "posterior large problem z_lmpolicy_index"
			   
preserve

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

/* Statistics */

loc colnum = 1
loc colnames ""



foreach choice in `experiments' {

   reg `choice' T1 T1read read  $controls [pweight=pweight], vce(r) 
	
		local n = round(e(N))
			
			sigstar T1, prec(3)
			estadd loc thisstat3 = "`r(bstar)'": col`colnum'
			estadd loc thisstat4 = "`r(sestar)'": col`colnum'
			
			sigstar T1read, prec(3)
			estadd loc thisstat6 = "`r(bstar)'": col`colnum'
			estadd loc thisstat7 = "`r(sestar)'": col`colnum'
			
			test T1 + T1read =0
			estadd loc thisstat8 = string(r(p), "%9.3f"): col`colnum'
			
			estadd loc thisstat10 = "`n'": col`colnum'
			
			loc ++colnum
}


loc rowlabels " "{\bf Panel A: First Stage/Reduced Form}" " " "T$^{74}$" " " " " "T$^{74}$ x read" " " "p-value [T$^{74}$ + T$^{74}$ x read]" " " "Observations" "

	loc rowstats ""
	
	forval i = 1/10{
		loc rowstats "`rowstats' thisstat`i'"
	}
	

esttab * using "$output\TableCompliers_PanelA.tex", replace cells(none) booktabs nonotes nomtitles compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
	mgroups("\shortstack{Posterior \\ belief about \\fem. rel. wage}" "\shortstack{Gender diff.\\ in wages\\are large}" "\shortstack{Gender diff.\\ in wages\\are a problem}"  ///
  "\shortstack{Policy\\Demand\\Index}", pattern(1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))


*** Panel B


loc experiments "1 2 3"
			   
preserve

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

/* Statistics */

loc colnum = 1
loc colnames ""


ivregress 2sls z_lmpolicy_index read $controls (posterior posteriorread = T1 T1read ) [pweight=pweight], vce(r) 
	
		local n = round(e(N))
			
			sigstar posterior, prec(3)
			estadd loc thisstat3 = "`r(bstar)'": col`colnum'
			estadd loc thisstat4 = "`r(sestar)'": col`colnum'
			
			sigstar posteriorread, prec(3)
			estadd loc thisstat6 = "`r(bstar)'": col`colnum'
			estadd loc thisstat7 = "`r(sestar)'": col`colnum'
			
			test posterior + posteriorread =0
			estadd loc thisstat8 = string(r(p), "%9.3f"): col`colnum'
			
			
			estadd loc thisstat10 = "Posterior": col`colnum'
			estadd loc thisstat11 = "belief about": col`colnum'
			estadd loc thisstat12 = "wage gap": col`colnum'

			estadd loc thisstat14 = "`n'": col`colnum'


			loc ++colnum
			
			
ivregress 2sls z_lmpolicy_index read $controls (large largeread = T1 T1read ) [pweight=pweight], vce(r) 
	
		local n = round(e(N))
			
			sigstar large, prec(3)
			estadd loc thisstat3 = "`r(bstar)'": col`colnum'
			estadd loc thisstat4 = "`r(sestar)'": col`colnum'
			
			sigstar largeread, prec(3)
			estadd loc thisstat6 = "`r(bstar)'": col`colnum'
			estadd loc thisstat7 = "`r(sestar)'": col`colnum'
			
			test large + largeread = 0
			estadd loc thisstat8 = string(r(p), "%9.3f"): col`colnum'
			
			estadd loc thisstat10 = "Gender diff.": col`colnum'
			estadd loc thisstat11 = "in wages": col`colnum'
			estadd loc thisstat12 = "are large": col`colnum'

			estadd loc thisstat14 = "`n'": col`colnum'


			loc ++colnum


ivregress 2sls z_lmpolicy_index read $controls (problem problemread = T1 T1read ) [pweight=pweight], vce(r) 
	
		local n = round(e(N))
			
			sigstar problem, prec(3)
			estadd loc thisstat3 = "`r(bstar)'": col`colnum'
			estadd loc thisstat4 = "`r(sestar)'": col`colnum'
			
			sigstar problemread, prec(3)
			estadd loc thisstat6 = "`r(bstar)'": col`colnum'
			estadd loc thisstat7 = "`r(sestar)'": col`colnum'
			
			test problem + problemread =0
			estadd loc thisstat8 = string(r(p), "%9.3f"): col`colnum'
			
			estadd loc thisstat10 = "Gender diff.": col`colnum'
			estadd loc thisstat11 = "in wages": col`colnum'
			estadd loc thisstat12 = "are a problem": col`colnum'

			estadd loc thisstat14 = "`n'": col`colnum'
			
			loc ++colnum			
			
  
 loc rowlabels " "{\bf Panel B: 2SLS}" " " "\widehat{\text{Perception}}" " " " " "\widehat{\text{Perception x read}}" " " "p-value [\widehat{\text{Perception}} + \widehat{\text{Perception x read}}]" " " "Perception measure" " " " " " " "Observations" " " "

	loc rowstats ""
	
	forval i = 1/14{
		loc rowstats "`rowstats' thisstat`i'"
	}
	

esttab * using "$output\TableCompliers_PanelB.tex", replace cells(none) booktabs nonotes nomtitles compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
	mgroups("\shortstack{Policy Demand Index}", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))


***********************************************************************************
// Table D.7: Treatment effect on beliefs about the wage gap and related perceptions
***********************************************************************************

clear all

use "$path\data\SurveyStageI_AB_final.dta", clear

gen priornorm=prior

* Standardize prior beliefs based on control group
foreach var of varlist priornorm{
egen mean_`var'=mean(`var') if rand==0
egen max_mean_`var'=min(mean_`var')
replace mean_`var'=max_mean_`var'
drop max_mean_`var'
egen sd_`var'=sd(`var') if rand==0
egen min_sd_`var'=min(sd_`var')
replace sd_`var'=min_sd_`var'
drop min_sd_`var'
replace `var'=(`var'-mean_`var')/sd_`var'
drop mean_`var' sd_`var'
}

* Generate measures of over- and underestimation compared to treatment signals
gen bias74=74-prior			//underestimation before T1
gen bias94=prior-94			//overestimated before T2

replace bias74=(bias74>0)	//Dummy for prior belief below 74
replace bias94=(bias94>0)	//Dummy for prior belief above 94

* Generate dummy for moderate prior beliefs between 74 and 94
gen normal=0
replace normal=(bias74==0)&(bias94==0)

* Generate independent variables of interest
gen T1normal=T1*normal		//Dummy for assigned to T74 and moderate prior
gen T2normal=T2*normal		//Dummy for assigned to T94 and moderate prior

gen T1bias74=T1*bias74		//Dummy for assigned to T74 and prior below 74
gen T2bias94=T2*bias94		//Dummy for assigned to T94 and prior below 74

gen T1bias94=T1*bias94		//Dummy for assigned to T74 and prior above 94
gen T2bias74=T2*bias74		//Dummy for assigned to T94 and prior above 94

preserve	

clear all
eststo clear
estimates drop _all


loc experiments "posterior large problem govmore z_mani_index"

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore


loc colnum = 1


foreach choice in `experiments' {

    reg `choice' T1normal T2normal T1bias74 T1bias94 T2bias74 T2bias94 bias74 bias94 normal $controls prior1 [pweight=pweight], nocons vce(r)
    sigstar T1normal, prec(3)
    estadd loc thisstat2 = "`r(bstar)'": col`colnum'
    estadd loc thisstat3 = "`r(sestar)'": col`colnum'
	sigstar T2normal, prec(3)
    estadd loc thisstat5 = "`r(bstar)'": col`colnum'
    estadd loc thisstat6 = "`r(sestar)'": col`colnum'
	
	sigstar T1bias74, prec(3)
    estadd loc thisstat9 = "`r(bstar)'": col`colnum'
    estadd loc thisstat10 = "`r(sestar)'": col`colnum'
	sigstar T2bias74, prec(3)
    estadd loc thisstat12 = "`r(bstar)'": col`colnum'
    estadd loc thisstat13 = "`r(sestar)'": col`colnum'
	
	
	sigstar T1bias94, prec(3)
    estadd loc thisstat16 = "`r(bstar)'": col`colnum'
    estadd loc thisstat17 = "`r(sestar)'": col`colnum'	
	
	sigstar T2bias94, prec(3)
    estadd loc thisstat19 = "`r(bstar)'": col`colnum'
    estadd loc thisstat20 = "`r(sestar)'": col`colnum'
	
	* p-values
	test 	T1normal - T2normal = 0
	estadd loc thisstat7 = string(r(p), "%9.2f"): col`colnum'
	
	test 	T1bias74 - T2bias74 = 0
	estadd loc thisstat14 = string(r(p), "%9.2f"): col`colnum'
	
	test 	T1bias94 - T2bias94 = 0
	estadd loc thisstat21 = string(r(p), "%9.2f"): col`colnum'	
	
	
	test 	T1normal - T1bias74 = 0
	estadd loc thisstat23 = string(r(p), "%9.2f"): col`colnum'
	
	test 	T1normal - T1bias94 = 0
	estadd loc thisstat24 = string(r(p), "%9.2f"): col`colnum'
	
	test 	T1bias74 - T1bias94 = 0
	estadd loc thisstat25 = string(r(p), "%9.2f"): col`colnum'
	
	
	test 	T2normal - T2bias74 = 0
	estadd loc thisstat27 = string(r(p), "%9.2f"): col`colnum'
	
	test 	T2normal - T2bias94 = 0
	estadd loc thisstat28 = string(r(p), "%9.2f"): col`colnum'
	
	test 	T2bias74 - T2bias94 = 0
	estadd loc thisstat29 = string(r(p), "%9.2f"): col`colnum'
	
	* Control group mean and Nobs for each belief bracket:
	mean `choice' [pweight=pweight] if normal == 1&rand==0
	matrix mean=e(b)
	matrix nobs=e(N)
	estadd loc thisstat31 = string(mean[1,1], "%9.2f"): col`colnum'
    estadd loc thisstat32 = string(nobs[1,1], "%9.0f"): col`colnum'
	
	mean `choice' [pweight=pweight] if bias74 == 1&rand==0
	matrix mean=e(b)
	matrix nobs=e(N)
	estadd loc thisstat34 = string(mean[1,1], "%9.2f"): col`colnum'
    estadd loc thisstat35 = string(nobs[1,1], "%9.0f"): col`colnum'
	
	mean `choice' [pweight=pweight] if bias94 == 1&rand==0
	matrix mean=e(b)
	matrix nobs=e(N)
	estadd loc thisstat37 = string(mean[1,1], "%9.2f"): col`colnum'
    estadd loc thisstat38 = string(nobs[1,1], "%9.0f"): col`colnum'
	
	* Total number of observations
	sum `choice' 
    estadd loc thisstat40 = r(N): col`colnum'
	

    loc ++colnum
    loc colnames "`colnames' `"`: var la `choice''"'"
}

	
loc rowlabels " " " "T$^{74}$ x (74 $\leq$ prior $\leq$ 94)" " " " " "T$^{94}$ x (74 $\leq$ prior $\leq$ 94)" " " "p-value [T$^{74}$ x (74 $\leq$ prior $\leq$ 94) = T$^{94}$ x (74 $\leq$ prior $\leq$ 94)]" " " "T$^{74}$ x (prior < 74)" " " " " "T$^{94}$ x (prior < 74)" " " "p-value [T$^{74}$ x (prior < 74) = T$^{94}$ x (prior < 74)]" " " "T$^{74}$ x (prior > 94)" " " " " "T$^{94}$ x (prior > 94)" " " "p-value [T$^{74}$ (prior > 94) = T$^{94}$ x (prior > 94)]" " " "p-value [T$^{74}$ x (74 $\leq$ prior $\leq$ 94) = T$^{74}$ x (prior < 74)]" "p-value [T$^{74}$ x (74 $\leq$ prior $\leq$ 94) = T$^{74}$ x (prior > 94)]" "p-value [T$^{74}$ x (prior < 74) = T$^{74}$ x (prior > 94)]" " " "p-value [T$^{94}$ x (74 $\leq$ prior $\leq$ 94) = T$^{94}$ x (prior < 74)]" "p-value [T$^{94}$ x (74 $\leq$ prior $\leq$ 94) = T$^{94}$ x (prior > 94)]" "p-value [T$^{94}$ x (prior < 74) = T$^{94}$ x (prior > 94)]" " " "Control group mean (74 $\leq$ prior $\leq$ 94)" " " " " "Control group mean (prior < 74)" " " " " "Control group mean (prior > 94)" " " " " "Observations"  " "  "
loc rowstats ""



forval i = 1/40 {
    loc rowstats "`rowstats' thisstat`i'"
}


esttab * using "$output\manicheckaltspec_interact.tex", replace cells(none) booktabs nonotes nomtitles compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
	mgroups("\shortstack{Posterior\\belief}" "\shortstack{Gender diff. in wages\\are large}" "\shortstack{Gender diff. in wages\\are a problem}"  ///
  "\shortstack{Government should\\promote gender wage equality}" "\shortstack{Index\\(2)-(4)}", pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))


eststo clear



***********************************************************************************
// Table D.8: Treatment effect on demand for specific policies
***********************************************************************************


preserve	

clear all
eststo clear
estimates drop _all

loc experiments "quotaanchor AAanchor legislationanchor transparencyanchor UKtool childcare  z_lmpolicy_index"

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore


loc colnum = 1


foreach choice in `experiments' {

    reg `choice' T1normal T2normal T1bias74 T1bias94 T2bias74 T2bias94 bias74 bias94 normal $controls prior1 [pweight=pweight], nocons vce(r)
    sigstar T1normal, prec(3)
    estadd loc thisstat2 = "`r(bstar)'": col`colnum'
    estadd loc thisstat3 = "`r(sestar)'": col`colnum'
	sigstar T2normal, prec(3)
    estadd loc thisstat5 = "`r(bstar)'": col`colnum'
    estadd loc thisstat6 = "`r(sestar)'": col`colnum'
	
	sigstar T1bias74, prec(3)
    estadd loc thisstat9 = "`r(bstar)'": col`colnum'
    estadd loc thisstat10 = "`r(sestar)'": col`colnum'
	sigstar T2bias74, prec(3)
    estadd loc thisstat12 = "`r(bstar)'": col`colnum'
    estadd loc thisstat13 = "`r(sestar)'": col`colnum'
	
	
	sigstar T1bias94, prec(3)
    estadd loc thisstat16 = "`r(bstar)'": col`colnum'
    estadd loc thisstat17 = "`r(sestar)'": col`colnum'	
	
	sigstar T2bias94, prec(3)
    estadd loc thisstat19 = "`r(bstar)'": col`colnum'
    estadd loc thisstat20 = "`r(sestar)'": col`colnum'
	
	* p-values
	test 	T1normal - T2normal = 0
	estadd loc thisstat7 = string(r(p), "%9.2f"): col`colnum'
	
	test 	T1bias74 - T2bias74 = 0
	estadd loc thisstat14 = string(r(p), "%9.2f"): col`colnum'
	
	test 	T1bias94 - T2bias94 = 0
	estadd loc thisstat21 = string(r(p), "%9.2f"): col`colnum'	
	
	
	test 	T1normal - T1bias74 = 0
	estadd loc thisstat23 = string(r(p), "%9.2f"): col`colnum'
	
	test 	T1normal - T1bias94 = 0
	estadd loc thisstat24 = string(r(p), "%9.2f"): col`colnum'
	
	test 	T1bias74 - T1bias94 = 0
	estadd loc thisstat25 = string(r(p), "%9.2f"): col`colnum'
	
	
	test 	T2normal - T2bias74 = 0
	estadd loc thisstat27 = string(r(p), "%9.2f"): col`colnum'
	
	test 	T2normal - T2bias94 = 0
	estadd loc thisstat28 = string(r(p), "%9.2f"): col`colnum'
	
	test 	T2bias74 - T2bias94 = 0
	estadd loc thisstat29 = string(r(p), "%9.2f"): col`colnum'
	
	* Control group mean and Nobs for each belief bracket:
	mean `choice' [pweight=pweight] if normal == 1&rand==0
	matrix mean=e(b)
	matrix nobs=e(N)
	estadd loc thisstat31 = string(mean[1,1], "%9.2f"): col`colnum'
    estadd loc thisstat32 = string(nobs[1,1], "%9.0f"): col`colnum'
	
	mean `choice' [pweight=pweight] if bias74 == 1&rand==0
	matrix mean=e(b)
	matrix nobs=e(N)
	estadd loc thisstat34 = string(mean[1,1], "%9.2f"): col`colnum'
    estadd loc thisstat35 = string(nobs[1,1], "%9.0f"): col`colnum'
	
	mean `choice' [pweight=pweight] if bias94 == 1&rand==0
	matrix mean=e(b)
	matrix nobs=e(N)
	estadd loc thisstat37 = string(mean[1,1], "%9.2f"): col`colnum'
    estadd loc thisstat38 = string(nobs[1,1], "%9.0f"): col`colnum'
	
	* Total number of observations
	sum `choice' 
    estadd loc thisstat40 = r(N): col`colnum'
	

    loc ++colnum
    loc colnames "`colnames' `"`: var la `choice''"'"
}

	
loc rowlabels " " " "T$^{74}$ x (74 $\leq$ prior $\leq$ 94)" " " " " "T$^{94}$ x (74 $\leq$ prior $\leq$ 94)" " " "p-value [T$^{74}$ x (74 $\leq$ prior $\leq$ 94) = T$^{94}$ x (74 $\leq$ prior $\leq$ 94)]" " " "T$^{74}$ x (prior < 74)" " " " " "T$^{94}$ x (prior < 74)" " " "p-value [T$^{74}$ x (prior < 74) = T$^{94}$ x (prior < 74)]" " " "T$^{74}$ x (prior > 94)" " " " " "T$^{94}$ x (prior > 94)" " " "p-value [T$^{74}$ (prior > 94) = T$^{94}$ x (prior > 94)]" " " "p-value [T$^{74}$ x (74 $\leq$ prior $\leq$ 94) = T$^{74}$ x (prior < 74)]" "p-value [T$^{74}$ x (74 $\leq$ prior $\leq$ 94) = T$^{74}$ x (prior > 94)]" "p-value [T$^{74}$ x (prior < 74) = T$^{74}$ x (prior > 94)]" " " "p-value [T$^{94}$ x (74 $\leq$ prior $\leq$ 94) = T$^{94}$ x (prior < 74)]" "p-value [T$^{94}$ x (74 $\leq$ prior $\leq$ 94) = T$^{94}$ x (prior > 94)]" "p-value [T$^{94}$ x (prior < 74) = T$^{94}$ x (prior > 94)]" " " "Control group mean (74 $\leq$ prior $\leq$ 94)" " " " " "Control group mean (prior < 74)" " " " " "Control group mean (prior > 94)" " " " " "Observations"  " "  "
loc rowstats ""



forval i = 1/40 {
    loc rowstats "`rowstats' thisstat`i'"
}


esttab * using "$output\policyaltspec_interact.tex", replace cells(none) booktabs nonotes nomtitles compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
	mgroups("\shortstack{Introduce\\gender\\quotas}" "\shortstack{Statutory\\affirmative\\action}"  ///
  "\shortstack{Stricter\\equal pay\\legislation}" "\shortstack{Wage transp.\\within\\ companies}" "\shortstack{Introduce\\reporting\\website}" "\shortstack{Increase\\subsidies\\to child care}" ///
   "\shortstack{Policy\\demand\\index}", pattern(1 1 1 1 1 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

eststo clear



***********************************************************************************
// Table D.9: Treatment effect on beliefs about the wage gap and related perceptions
***********************************************************************************

use "$path\data\SurveyStageI_AB_final.dta", clear

gen bias74=74-prior			//degree of underestimation of females' wages compared to T1
gen bias94=94-prior			//degree of underestimation of females' wages compared to T2

* Generate a measure of the update each respondent receives 
gen signal=0 if rand==0
replace signal=bias74 if T1==1
replace signal=bias94 if T2==1

* Dummy for "any treatment group"
gen treatment=T1+T2

* Dummies for whether information update compared to prior belief is positive/negative
gen posshock = 0
replace posshock= 1 if bias74>0&T1==1
replace posshock = 1 if bias94>0&T2==1
gen negshock=0
replace negshock=1 if bias74<0&T1==1
replace negshock=1 if bias94<0&T2==1

// Interaction terms: 
gen signalpos=signal*posshock
gen signalneg=signal*negshock

gen signalT1=signal*T1
gen signalT2=signal*T2


loc experiments "posterior large problem govmore z_mani_index"

*Standardize prior based on mean and st. dev. in the pure control group	
foreach var of varlist prior{
egen mean_`var'=mean(`var') if rand==0
egen max_mean_`var'=min(mean_`var')
replace mean_`var'=max_mean_`var'
drop max_mean_`var'
egen sd_`var'=sd(`var') if rand==0
egen min_sd_`var'=min(sd_`var')
replace sd_`var'=min_sd_`var'
drop min_sd_`var'
replace `var'=(`var'-mean_`var')/sd_`var'
drop mean_`var' sd_`var'
}


*Keep only those with prior beliefs above the 5th and below the 95th percentile of the control group distribution
sum prior if rand==0,d
keep if prior > r(p5) & prior < r(p95)
	

preserve	

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

/* Statistics */

loc colnum = 1


foreach choice in `experiments' {


***Panel A: Role of information update
    qui reg `choice' signal $controls [pweight=pweight], vce(r)
	local n = round(e(N))
	
    sigstar signal, prec(3)
    estadd loc thisstat3 = "`r(bstar)'": col`colnum'
    estadd loc thisstat4 = "`r(sestar)'": col`colnum'
	sigstar prior, prec(3)
    estadd loc thisstat6 = "`r(bstar)'": col`colnum'
    estadd loc thisstat7 = "`r(sestar)'": col`colnum'

	estadd loc thisstat9 = "`n'": col`colnum'
	
	
*** Panel B: Interaction of update with T74 and T94
    reg `choice' signalT1 signalT2 $controls  [pweight=pweight], vce(r)
	local n = round(e(N))
	
    sigstar signalT1, prec(3)
    estadd loc thisstat12 = "`r(bstar)'": col`colnum'
	estadd loc thisstat13 = "`r(sestar)'": col`colnum'
	sigstar signalT2, prec(3)
    estadd loc thisstat15 = "`r(bstar)'": col`colnum'
	estadd loc thisstat16 = "`r(sestar)'": col`colnum'
	
	test 	signalT1 - signalT2 = 0
	estadd loc thisstat17 = string(r(p), "%9.3f"): col`colnum'
	
	sigstar prior, prec(3)
    estadd loc thisstat19 = "`r(bstar)'": col`colnum'
    estadd loc thisstat20 = "`r(sestar)'": col`colnum'
	
	estadd loc thisstat22 = "`n'": col`colnum'
	
*** Panel C: Interaction of update with pos. update and neg. update	
	reg `choice' signalpos signalneg $controls  [pweight=pweight], vce(r)
	local n = round(e(N))
	
    sigstar signalpos, prec(3)
    estadd loc thisstat25 = "`r(bstar)'": col`colnum'
	estadd loc thisstat26 = "`r(sestar)'": col`colnum'
	sigstar signalneg, prec(3)
    estadd loc thisstat28 = "`r(bstar)'": col`colnum'
	estadd loc thisstat29 = "`r(sestar)'": col`colnum'
	
	test 	signalpos - signalneg = 0
	estadd loc thisstat30 = string(r(p), "%9.3f"): col`colnum'
	
	sigstar prior, prec(3)
    estadd loc thisstat32 = "`r(bstar)'": col`colnum'
    estadd loc thisstat33 = "`r(sestar)'": col`colnum'
	
	estadd loc thisstat35 = "`n'": col`colnum'

    loc ++colnum
    loc colnames "`colnames' `"`: var la `choice''"'"
	
}
	
loc rowlabels " "{\bf Panel A: Baseline Specification}" " " "(Signal -- Prior)" " " " " "Prior" " " " " "Observations" "\hline {\bf Panel B: Interaction with T$^{74}$ and T$^{94}$}" " " "(Signal -- Prior) x T$^{74}$ (a)" " " " " "(Signal -- Prior) x T$^{94}$ (b)" " " "p-value [(a) -- (b) = 0]" " " "Prior" " " " " "Observations" "\hline {\bf Panel C: Interact. with pos./neg. Signal}" " " "(Signal -- Prior) x $\textbf{1}$(Signal -- Prior > 0) (a)" " " " " "(Signal -- Prior) x $\textbf{1}$(Signal -- Prior < 0) (b)" " " "p-value [(a) -- (b) = 0]" " " "Prior" " " " " "Observations" " " "
loc rowstats ""

forval i = 1/35 {
    loc rowstats "`rowstats' thisstat`i'"
}


esttab * using "$output\manicheckalt_infoupdate.tex", replace cells(none) booktabs nonotes nomtitles compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
  mgroups("\shortstack{Posterior\\belief about\\fem. rel. wage\\ (percent)}" "\shortstack{Gender\\ differences\\ in wages\\are large}" "\shortstack{Gender\\ differences\\ in wages\\are a problem}"  ///
  "\shortstack{Gov. should\\promote\\gender wage\\equality}" "\shortstack{Index\\(2)-(4)}", pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))


eststo clear




***********************************************************************************
// Table D.10: Treatment effect on the demand for specific policies
***********************************************************************************

loc experiments "quotaanchor AAanchor legislationanchor transparencyanchor UKtool childcare z_lmpolicy_index"

preserve	

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}

restore

/* Statistics */

loc colnum = 1


foreach choice in `experiments' {


***Panel A: Role of information update
    qui reg `choice' signal $controls [pweight=pweight], vce(r)
	local n = round(e(N))
	
    sigstar signal, prec(3)
    estadd loc thisstat3 = "`r(bstar)'": col`colnum'
    estadd loc thisstat4 = "`r(sestar)'": col`colnum'
	sigstar prior, prec(3)
    estadd loc thisstat6 = "`r(bstar)'": col`colnum'
    estadd loc thisstat7 = "`r(sestar)'": col`colnum'

	estadd loc thisstat9 = "`n'": col`colnum'
	
	
*** Panel B: Interaction of update with T74 and T94
    reg `choice' signalT1 signalT2 $controls  [pweight=pweight], vce(r)
	local n = round(e(N))
	
    sigstar signalT1, prec(3)
    estadd loc thisstat12 = "`r(bstar)'": col`colnum'
	estadd loc thisstat13 = "`r(sestar)'": col`colnum'
	sigstar signalT2, prec(3)
    estadd loc thisstat15 = "`r(bstar)'": col`colnum'
	estadd loc thisstat16 = "`r(sestar)'": col`colnum'
	
	test 	signalT1 - signalT2 = 0
	estadd loc thisstat17 = string(r(p), "%9.3f"): col`colnum'
	
	sigstar prior, prec(3)
    estadd loc thisstat19 = "`r(bstar)'": col`colnum'
    estadd loc thisstat20 = "`r(sestar)'": col`colnum'
	
	estadd loc thisstat22 = "`n'": col`colnum'
	
*** Panel C: Interaction of update with pos. update and neg. update	
	reg `choice' signalpos signalneg $controls  [pweight=pweight], vce(r)
	local n = round(e(N))
	
    sigstar signalpos, prec(3)
    estadd loc thisstat25 = "`r(bstar)'": col`colnum'
	estadd loc thisstat26 = "`r(sestar)'": col`colnum'
	sigstar signalneg, prec(3)
    estadd loc thisstat28 = "`r(bstar)'": col`colnum'
	estadd loc thisstat29 = "`r(sestar)'": col`colnum'
	
	test 	signalpos - signalneg = 0
	estadd loc thisstat30 = string(r(p), "%9.3f"): col`colnum'
	
	sigstar prior, prec(3)
    estadd loc thisstat32 = "`r(bstar)'": col`colnum'
    estadd loc thisstat33 = "`r(sestar)'": col`colnum'
	
	estadd loc thisstat35 = "`n'": col`colnum'

    loc ++colnum
    loc colnames "`colnames' `"`: var la `choice''"'"
	
}
	
loc rowlabels " "{\bf Panel A: Baseline Specification}" " " "(Signal -- Prior)" " " " " "Prior" " " " " "Observations" "\hline {\bf Panel B: Interaction with T$^{74}$ and T$^{94}$}" " " "(Signal -- Prior) x T$^{74}$ (a)" " " " " "(Signal -- Prior) x T$^{94}$ (b)" " " "p-value [(a) -- (b) = 0]" " " "Prior" " " " " "Observations" "\hline {\bf Panel C: Interact. with pos./neg. Signal}" " " "(Signal -- Prior) x $\textbf{1}$(Signal -- Prior > 0) (a)" " " " " "(Signal -- Prior) x $\textbf{1}$(Signal -- Prior < 0) (b)" " " "p-value [(a) -- (b) = 0]" " " "Prior" " " " " "Observations" " " "
loc rowstats ""

forval i = 1/35 {
    loc rowstats "`rowstats' thisstat`i'"
}


esttab * using "$output\policyalt_infoupdate.tex", replace cells(none) booktabs nonotes nomtitles compress alignment(c) nogap noobs nobaselevels label stats(`rowstats', labels(`rowlabels')) ///
 mgroups("\shortstack{Introduce\\gender\\quotas}" "\shortstack{Statutory\\affirmative\\action}"  ///
  "\shortstack{Stricter\\equal pay\\legislation}" "\shortstack{Wage transp.\\within\\ companies}" "\shortstack{Introduce\\reporting\\website}" "\shortstack{Increase\\subsidies\\to child care}" ///
   "\shortstack{Policy\\demand\\index}", pattern(1 1 1 1 1 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))


eststo clear


***********************************************************************************
// Table D.11: Robustness of main treatment effect to FWER control
***********************************************************************************

use "$path\data\SurveyStageI_AB_final.dta", clear

drop if rand==0

loc experiments "z_mani_index z_lmpolicy_index z_extreasons_index"
  	   
preserve	

clear all
eststo clear
estimates drop _all

set obs 10
qui gen x = 1
qui gen y = 1

loc columns = 0

foreach choice in `experiments' {

    loc ++columns
    qui eststo col`columns': reg x y

}


... [truncated: 60,035 more bytes of this script omitted] ...

```

### `dofiles/11_InTextResults.do`
```stata

***********************************************************************************
// Replication Files
**********************************************************************************
/*
HOW DO BELIEFS ABOUT THE GENDER WAGE GAP AFFECT THE DEMAND FOR PUBLIC POLICY?
Sonja Settele
AEJ:pol
*/
**********************************************************************************

***********************************************************************************
**** Replication of in-text results: 
***********************************************************************************

***********************************************************************************
/* Page 11: "Roughly 20 percent of the respondents hold a prior belief below the ACS-
based value of $74, while another 20 percent hold a belief above the CPS-based value
of $94. The median belief is $81." */
***********************************************************************************

clear all
set more off

use "$path\data\SurveyStageI_AB_final.dta", clear

gen prior_below_74=prior<74
gen prior_above_94=prior>94

tab prior_below_74
tab prior_above_94

sum prior,d

***********************************************************************************
/* Page 11: "When beliefs are incentivized, (...) respondents spend on average 16 seconds
more on their prior estimate." */
***********************************************************************************

reg timeprior prior1 [pweight=pweight],robust

***********************************************************************************
/* Footnote 15: "Only about one third of individuals in the ACS with a 
Bachelor's degree also hold a higher degree, and females' relative wages remain almost
the same when those indiviudals are included ($75 vs. $74)." */
***********************************************************************************

clear all
set more off

use "$path\data\usa_00025.dta", clear

keep if year==2016

keep if age>17&age<66

// Set missing wages to missing if applicable
replace incwage=. if incwage==9999999
replace incwage=. if incwage==999999

gen female=0 if sex!=.
replace female=1 if sex==2

gen GWG_ACS_45_Bachelormore=. 

gen e_sample=.

* uhrswork = weekly hours worked
* educd==101 -> Bachelor's degree
* classwkr=2 -> Employee

/* Calculate women's wages as a share of male wages in the group of 45-year-old employees with 
AT LEAST a Bachelors degree who work 40 hours per week */

reg incwage female if age==45&empstat==1&uhrswork==40&educd>=101&classwkr==2 [pweight=perwt], robust
mat beta = e(b)
sca feml = beta[1,1]
disp feml
replace e_sample=0
replace e_sample=1 if e(sample)==1
mean incwage if female==0&age==45&empstat==1&uhrswork==40&educd>=101&classwkr==2 [pweight=perwt]
matrix mean=e(b)
mat list mean
sca const=mean[1,1]
replace GWG_ACS_45_Bachelormore = 1+(feml/const) if educd>=101&age==45&empstat==1&uhrswork==40&classwkr==2

tab GWG_ACS_45_Bachelormore


// Share of those with a Bachelor's who hold more than a Bachelor's degree: 
tab educd if educd>=101


***********************************************************************************
/* Page 12: "The difference between the 10th and the 90th percentile of the distribution of 
females' actual relative wages across occupation groups amounts to 18 percentage points." */
***********************************************************************************

clear all
set more off

use "$path\data\usa_00025.dta", clear

keep if year==2016

keep if classwkr==2 			//keep only employees

//wage and salary income, set missings to missing
replace incwage=. if incwage==9999999
replace incwage=. if incwage==999999

gen female=0 if sex!=.
replace female=1 if sex==2

// 26 occupation groups based on ACS				//Name of group										BLS category		
gen occ=1 if occ2010>=10&occ2010<=430				//Management, Business, Science and arts			1
replace occ=2 if occ2010>=500&occ2010<=730			//Business Operations Specialists					2
replace occ=3 if occ2010>=800&occ2010<=950			//Financial Specialists								2
replace occ=4 if occ2010>=1000&occ2010<=1240		//Computer and Mathematical							3
replace occ=5 if occ2010>=1300&occ2010<=1540		//Architecture and Engineering						4
replace occ=6 if occ2010>=1550&occ2010<=1560		//Technicians										4
replace occ=7 if occ2010>=1600&occ2010<=1980		//Life, physical and social science					5
replace occ=8 if occ2010>=2000&occ2010<=2060		//Community and Social services						6
replace occ=9 if occ2010>=2100&occ2010<=2150		//Legal												7
replace occ=10 if occ2010>=2200&occ2010<=2550		//Education, Training and library					8
replace occ=11 if occ2010>=2600&occ2010<=2920		//Arts, design, entertainment, sports and media		9
replace occ=12 if occ2010>=3000&occ2010<=3540		//Healthcare practitioners and technical			10
replace occ=13 if occ2010>=3600&occ2010<=3650		//Healthcare support								11
replace occ=14 if occ2010>=3700&occ2010<=3950		//Protective Service								12
replace occ=15 if occ2010>=4000&occ2010<=4150		//Food preparation and serving						13
replace occ=16 if occ2010>=4200&occ2010<=4250		//Building and grounds cleaning and maintentance	14
replace occ=17 if occ2010>=4300&occ2010<=4650		//Personal care and service							15
replace occ=18 if occ2010>=4700&occ2010<=4965		//Sales and related									16
replace occ=19 if occ2010>=5000&occ2010<=5940		//Office and administrative support					17
replace occ=20 if occ2010>=6005&occ2010<=6130		//Farming, fishing and forestry						18
replace occ=21 if occ2010>=6200&occ2010<=6765		//Construction										19
replace occ=22 if occ2010>=6800&occ2010<=6940		//Extraction										19
replace occ=23 if occ2010>=7000&occ2010<=7630		//Installation, maintenance and repair				20
replace occ=24 if occ2010>=7799&occ2010<=8965		//Production										21
replace occ=25 if occ2010>=9000&occ2010<=9750		//Transportation and material moving				22
replace occ=26 if occ2010>=9800&occ2010<=9830		//Military specific


keep if age>24&age<66

// Drop following industries: 0=N/A, 992=last worked 1984 or earlier, 999=did not respond
drop if ind1990==0|ind1990==992|ind1990==999

//Summarize some occupation groups -> map to Bureau of Labor Statistics categories: 
replace occ=21 if occ==22  			//Extraction: Add to Construction
replace occ=2 if occ==3				//Financial Specialists: Add to business specialists
replace occ=5 if occ==6				//Technicians: Add to architecture and engineering
replace occ=. if occ==26			//Drop military

egen occnew= group (occ)

rename occ occold
rename occnew occ


//BLS categories
*occ=1 			//Management, Business, Science and arts			
*occ=2 			//Business Operations Specialists and Financial Specialists					
*occ=3 			//Computer and Mathematical							
*occ=4 			//Architecture and Engineering and Technicians					
*occ=5 			//Life, physical and social science					
*occ=6 			//Community and Social services					
*occ=7 			//Legal												
*occ=8 			//Education, Training and library					
*occ=9 			//Arts, design, entertainment, sports and media		
*occ=10 		//Healthcare practitioners and technical			
*occ=11 		//Healthcare support								
*occ=12 		//Protective Service								
*occ=13 		//Food preparation and serving						
*occ=14 		//Building and grounds cleaning and maintentance	
*occ=15 		//Personal care and service							
*occ=16 		//Sales and related									
*occ=17 		//Office and administrative support					
*occ=18 		//Farming, fishing and forestry						
*occ=19 		//Construction and Extraction									
*occ=20 		//Installation, maintenance and repair				
*occ=21 		//Production										
*occ=22 		//Transportation and material moving	


// Generate occupation-level measure of females' relative wages
gen GWG_ACS_2565_occ=.
gen e_sample=.

forvalues i= 1/22 {
disp `i'
reg incwage female if empstat==1&uhrswork==40&classwkr==2&occ==`i' [pweight=perwt], robust
mat beta = e(b)
sca feml = beta[1,1]
disp feml
replace e_sample=0
replace e_sample=1 if e(sample)==1
mean incwage if female==0&empstat==1&uhrswork==40&classwkr==2&occ==`i' [pweight=perwt]
matrix mean=e(b)
mat list mean
sca const=mean[1,1]
replace GWG_ACS_2565_occ = 1+(feml/const) if empstat==1&uhrswork==40&classwkr==2&occ==`i'
replace e_sample=.
}

_pctile GWG_ACS_2565_occ [pw=perwt], p(10)
return list
*-> .704116702079773 		

_pctile GWG_ACS_2565_occ [pw=perwt], p(90)
return list
*-> .8796714544296265 

// Diff: 0.1755

***********************************************************************************
/* Page 12: "The difference between the 10th and the 90th percentile of females' actual 
relative wages across states amounts to 8 percentage points." */
***********************************************************************************

gen state=""
replace state="Alabama" if statefip==1
replace state="Alaska" if statefip==2
replace state="Arizona" if statefip==4
replace state="Arkansas" if statefip==5
replace state="California" if statefip==6
replace state="Colorado" if statefip==8
replace state="Connecticut" if statefip==9
replace state="Delaware" if statefip==10
replace state="District of Columbia" if statefip==11
replace state="Florida" if statefip==12
replace state="Georgia" if statefip==13
replace state="Hawaii" if statefip==15
replace state="Idaho" if statefip==16
replace state="Illinois" if statefip==17
replace state="Indiana" if statefip==18
replace state="Iowa" if statefip==19
replace state="Kansas" if statefip==20
replace state="Kentucky" if statefip==21
replace state="Louisiana" if statefip==22
replace state="Maine" if statefip==23
replace state="Maryland" if statefip==24
replace state="Massachusetts" if statefip==25
replace state="Michigan" if statefip==26
replace state="Minnesota" if statefip==27
replace state="Mississippi" if statefip==28
replace state="Missouri" if statefip==29
replace state="Montana" if statefip==30
replace state="Nebraska" if statefip==31
replace state="Nevada" if statefip==32
replace state="New Hampshire" if statefip==33
replace state="New Jersey" if statefip==34
replace state="New Mexico" if statefip==35
replace state="New York" if statefip==36
replace state="North Carolina" if statefip==37
replace state="North Dakota" if statefip==38
replace state="Ohio" if statefip==39
replace state="Oklahoma" if statefip==40
replace state="Oregon" if statefip==41
replace state="Pennsylvania" if statefip==42
replace state="Rhode Island" if statefip==44
replace state="South Carolina" if statefip==45
replace state="South Dakota" if statefip==46
replace state="Tennessee" if statefip==47
replace state="Texas" if statefip==48
replace state="Utah" if statefip==49
replace state="Vermont" if statefip==50
replace state="Virginia" if statefip==51
replace state="Washington" if statefip==53
replace state="West Virginia" if statefip==54
replace state="Wisconsin" if statefip==55
replace state="Wyoming" if statefip==56		


// Generate state-level measure of females' relative wages
replace e_sample=.
gen GWG_ACS_2565_state=.

egen group= group (statefip)
sum group, meanonly

forvalues i= 1/`r(max)' {
disp `i'
reg incwage female if empstat==1&uhrswork==40&classwkr==2&group==`i' [pweight=perwt], robust
mat beta = e(b)
sca feml = beta[1,1]
disp feml
replace e_sample=0
replace e_sample=1 if e(sample)==1
mean incwage if female==0&empstat==1&uhrswork==40&classwkr==2&group==`i' [pweight=perwt]
matrix mean=e(b)
mat list mean
sca const=mean[1,1]
replace GWG_ACS_2565_state = 1+(feml/const) if empstat==1&uhrswork==40&classwkr==2&group==`i'
replace e_sample=.
}

_pctile GWG_ACS_2565_state [pw=perwt], p(10)
return list

_pctile GWG_ACS_2565_state [pw=perwt], p(90)
return list

// Diff: 0.07


***********************************************************************************
/* Footnote 30: "Young individuals are an exception: The treatment effect 
on specific policy demand in the group of 18 to 24-year-olds corresponds to a 
substantial 0.25 standard deviations for female and to zero for male respondents 
(p-value of the difference <0.05). */
***********************************************************************************

clear all

use "$path\data\SurveyStageI_AB_final.dta", clear

global controls wave democrat indep otherpol prior midwest south west anychildren loghhinc associatemore fulltime parttime selfemp unemp student

// Drop control group, keep only individuals aged 18-24
drop if rand==0
keep if age==1

* Split samples by gender: Test for equality of treatment coefficient 
eststo: reg z_lmpolicy_index T1 $controls [aweight=pweight] if female==0
eststo: reg z_lmpolicy_index T1 $controls [aweight=pweight] if female==1
    
suest est1 est2, vce(robust)
test [est1_mean]T1 = [est2_mean]T1


***********************************************************************************
/* Footnote 31: "15, 14 and 36 percent of respondents in the pure control group agree 
that men are inherently more i) ambitious, ii) talented for demanding tasks and iii) interested
 in ``technical'' jobs, respectively. Conversely, 71, 70 and 62 percent believe that i) women 
 face discrimination in the labor market, ii) men have been encouraged more to pursue ambitious 
 careers and iii) women face larger difficulties in combining work and family in today's society." */
***********************************************************************************

clear all
set more off

use "$path\data\SurveyStageI_AB_final.dta", clear

* keep only pure control group
keep if rand==0

// Answer scale: 1=completely disagree, 2=disagree, 3=neither agree nor disagree, 4=agree, 5=completely agree

gen ambitiousagree=ambitiousraw>3 if ambitiousraw!=.
gen talentedagree=talentedraw>3 if talentedraw!=.
gen interestedagree=interestedraw>3 if interestedraw!=.

tab ambitiousagree
tab talentedagree
tab interestedagree

gen discriminationagree=discriminationraw>3 if discriminationraw!=.
gen encouragedagree=boysraw>3 if boysraw!=.
gen difficultiesagree=societyraw>3 if societyraw!=.

tab discriminationagree
tab encouragedagree
tab difficultiesagree

***********************************************************************************
/* Footnote 34: "34, 30 and 36 percent of the respondents believe that 
anti-discrimination, affirmative action and family policies, respectively, are 
`` somewhat effective'' or ``highly effective'' rather than ``strongly/somewhat 
counterproductive'' or ``neither effective nor counterproductive''." */
***********************************************************************************

clear all
set more off

use "$path\data\SurveyStageI_AB_final.dta", clear

/* Answer scale: 1=strongly counterproductive, 2=somewhat counterproductive, 3=Neither 
effective nor counterproductive, 4=somewhat effective, 5=highly effective */

gen effdisagree=effdisraw>3 if effdisraw!=.
gen effAAagree=effAAraw>3 if effAAraw!=.
gen effworkfamagree=effworkfamraw>3 if effworkfamraw!=. 

tab effdisagree
tab effAAagree
tab effworkfamagree








```

### `dofiles/07_MainFigures.do`
```stata

***********************************************************************************
// Replication Files
**********************************************************************************
/*
HOW DO BELIEFS ABOUT THE GENDER WAGE GAP AFFECT THE DEMAND FOR PUBLIC POLICY?
Sonja Settele
AEJ:pol
*/
**********************************************************************************

***********************************************************************************
**** Generate Figures 2-3 in main paper 
***********************************************************************************

***********************************************************************************
// Figure 2: Treatment effect on signatures for real online petitions
***********************************************************************************

/* Number of potential signatures for Petitions I and II per treatment group correspond to the number of respondents assigned to either treatment group 
The numbers of actual signatures for Petitions I and II are all "manually" retrieved from the White House Petition Website. 
*/

// PETITION I
/* Run prtesti for a two-sided proportion test for Petition I. 
Input: 	Total number of potential signatures in T74 (1531)
		Number of actual signatures in T74 (259)
		Total number of potentila signatures in T94 (1500)
		Number of actual signatures in T94 (220)
Output: Proportion of signatures in T74 (incl. 95% CI)
		Proportion of signatures in T94 (incl. 95% CI)
		P-value of two-sided proportion test
		--> Output entered manually below
*/

prtesti 1531 259 1500 220, count

clear all
set scheme s2mono

global legend = `"label(1 "T{sup:74}") label(2 "T{sup:94}") order(1 2) size(large)"'


**** Set numbers for bar graph in a matrix

* Petition I: 

mat R=J(2,6,.)

local pvalue1 = 0.09		//2-sided test

* Means
mat R[1,1] = 0.16917		// All T74
mat R[2,1] = 0.14667		// All T94

* Lower bounds
mat R[1,2] = 0.1504		// All T74
mat R[2,2] = 0.1288		// All T94

* Upper bounds
mat R[1,3] = 0.1879		// All T74
mat R[2,3] = 0.1646		// All T94

mat R[1,4]=1
mat R[2,4]=2

mat R[1,5] = 1 
mat R[2,5] = 1 

mat R[1,6] = 1
mat R[2,6] = 1

preserve
clear
svmat R
tempfile Pet1
save `Pet1'
restore



// PETITION II
/* Run prtesti for a two-sided proportion test for Petition II. 
Input: 	Total number of potential signatures in T74 (1531)
		Number of actual signatures in T74 (19)
		Total number of potentila signatures in T94 (1500)
		Number of actual signatures in T94 (35)
Output: Proportion of signatures in T74 (incl. 95% CI)
		Proportion of signatures in T94 (incl. 95% CI)
		P-value of two-sided proportion test
		--> Output entered manually below
*/

prtesti 1531 19 1500 35, count


**********************************
* Petition II


local pvalue2 = 0.02		//2-sided test

* Means
mat R[1,1] = 0.01241		// All T74
mat R[2,1] = 0.02333		// All T94

* Lower bounds
mat R[1,2] = 0.0069		// All T74
mat R[2,2] = 0.0157		// All T94

* Upper bounds
mat R[1,3] = 0.01796	// All T74
mat R[2,3] = 0.031		// All T94

mat R[1,4]=1
mat R[2,4]=2

mat R[1,5] = 1 
mat R[2,5] = 1 

mat R[1,6] = 2
mat R[2,6] = 2

preserve
clear
svmat R
tempfile Pet2
save `Pet2'
restore


* Save bar graph matrix as dataset
clear

local numcats = "1 2 "
foreach a of local numcats {
	append using `Pet`a''
}


* For alignment along the x-axis
gen s1 = R6
gen s2 = .
replace s2 = s1 - 0.2 if R6 == 1
replace s2 = s1 - 0.6 if R6 == 2
replace s2 = s1 - 1.0 if R6 == 3
replace s2 = s1 - 1.4 if R6 == 4
replace s2 = s1 - 1.8 if R6 == 5
gen p1 = (s2 - 0.1) - .6
gen p2 = s2 + 0.1 - .6


* This recovers the group means with which to label each bar.
local i = 0
foreach pgrade of local numcats {
forval rel = 1/2 {
	local ++i
	sum R1 if R4 == `rel' & R6 == `pgrade' 
	local barval`i' = trim("`: di %9.2f r(mean)'")
}
}

* Set positions of elements in graph
*if "$grades" == "separate" {
	global barlabels `" " 0.8 " " "'
	global pvalues `"0.22 0.2 "p-value = `pvalue1'" 0.22 0.8 "p-value = `pvalue2'"  "'
	global grouplabels `"0.27 0.2 "Petition I:" 0.27 0.8 "Petition II:""'
	global grouplabels2 `"0.258 0.2 "Increase rep. requirements" 0.258 0.8 "Decrease rep. requirements""'
	global barvalues = `"0.04 0.1 "`barval1'" 0.04 0.3 "`barval2'" 0.04 0.7 "`barval3'" 0.04 0.9 "`barval4'" "'
*}


twoway (bar R1 p1 if R4 == 1, barw(0.18) fi(inten50) lc(black) lw(medium)) (bar R1 p2 if R4 == 2, barw(0.18) fi(inten20) lc(black) lw(medium)) ///
	(rcap R3 R2 p1 if R4 == 1, lc(gs5)) (rcap R3 R2 p2 if R4 == 2, lc(gs5)), legend(${legend}) graphregion(color(white)) ///
	yscale(range(0.3)) yla(0(0.05)0.3) xla(none) text($pvalues, size(4.0)) text($grouplabels, size(4.0)) text($grouplabels2, size(4.0)) text($barvalues, size(4.0)) ///
	 ytitle("Fraction of respondents who signed", height(5) size(4.2)) 
	graph export "$output\fig_petitions_combined.pdf", replace
	
	

***********************************************************************************
// Figure 3: Incentivized vs. non-incentivized prior beliefs.
***********************************************************************************	
	
set scheme s2mono

use "$path\data\SurveyStageI_AB_final.dta", clear

keep prior prior1 pweight wave democrat republican indep otherpol gender midwest south west age1 age2 age3 age4 anychildren loghhinc associatemore fulltime parttime selfemp unemp student

gen priormen=prior if gender==0
gen priorwoman=prior if gender==1
gen priorrepub=prior if republican==1
gen priordem = prior if democrat==1

lab var priormen "Men"
lab var priorwoman "Women"
lab var priorrepub "Republican"
lab var priordem "Democrat"

rename prior1 incentive

global legend = `"label(1 "No incentive") label(2 "Incentive") order(1 2) size(small)"'

gen notincentive = 1-incentive

local gender = "$gender"
if "$gender" == "male"  local genval = 0
if "$gender" == "female" local genval = 1

	local group1 = "priormen"
	local group2 = "priorwoman"
	local group3 = "priorrepub"
	local group4 = "priordem"
	local numcats = "1 2 3 4"


**** Calculate numbers for bar graph matrix

* Group 1: Men

* Set up matrix
mat R=J(2,5,.)

* Store means by incentive condition
local row=1
foreach X in notincentive incentive{
	mean `group1' if `X' == 1 [pweight=pweight]
	mat R[`row',1] = e(b)
	local ++row
}


* Calculate and store mean belief in no-incentive condition 
mean `group1' if notincentive == 1 [pweight=pweight]
matrix meannoin=e(b)

* Calculate and store incentive coeficient and p-value
reg `group1' incentive [pweight=pweight], robust
local pvalue1 = trim("`: di %9.3f 2*ttail(e(df_r), abs(_b[incentive]/_se[incentive]))'")


local row=1
foreach X in notincentive incentive  {
	mat R[`row',2]= meannoin[1,1] + _b[incentive]-1.96*_se[incentive]
	mat R[`row',3]= meannoin[1,1] + _b[incentive]+1.96*_se[incentive]
	mat R[`row',4]=`row'
	mat R[`row',5] = 1 
	local ++row
}



preserve
clear
svmat R
tempfile cat1
save `cat1'
restore

* Group 2: Women

* Set up matrix
mat R=J(2,5,.)

* Store means by incentive condition
local row=1
foreach X in notincentive incentive{
	mean `group2' if `X' == 1 [pweight=pweight]
	mat R[`row',1] = e(b)
	local ++row
}

* Calculate and store mean belief in no-incentive condition 
mean `group2' if notincentive == 1 [pweight=pweight]
matrix meannoin=e(b)

* Calculate and store incentive coeficient and p-value
reg `group2' incentive  [pweight=pweight], robust
local pvalue2 = trim("`: di %9.3f 2*ttail(e(df_r), abs(_b[incentive]/_se[incentive]))'")


local row=1
foreach X in notincentive incentive  {
	mat R[`row',2]= meannoin[1,1]  + _b[incentive]-1.96*_se[incentive]
	mat R[`row',3]= meannoin[1,1]  + _b[incentive]+1.96*_se[incentive]
	mat R[`row',4]=`row'
	mat R[`row',5] = 2 
	local ++row
}


preserve
clear
svmat R
tempfile cat2
save `cat2'
restore

* Group 3: Republicans

* Set up matrix
mat R=J(2,5,.)

* Store means by incentive condition
local row=1
foreach X in notincentive incentive{
	mean `group3' if `X' == 1 [pweight=pweight]
	mat R[`row',1] = e(b)
	local ++row
}


* Calculate and store mean belief in no-incentive condition 
mean `group3' if notincentive == 1 [pweight=pweight]
matrix meannoin=e(b)

* Calculate and store incentive coeficient and p-value
reg `group3' incentive [pweight=pweight], robust
local pvalue3 = trim("`: di %9.3f 2*ttail(e(df_r), abs(_b[incentive]/_se[incentive]))'")

local row=1
foreach X in notincentive incentive  {
	mat R[`row',2]=  meannoin[1,1] + _b[incentive]-1.96*_se[incentive]
	mat R[`row',3]=  meannoin[1,1] + _b[incentive]+1.96*_se[incentive]
	mat R[`row',4]=`row'
	mat R[`row',5] = 3 // group
	local ++row
}



preserve
clear
svmat R
tempfile cat3
save `cat3'
restore

* Group4: Democrats

* Set up matrix
mat R=J(2,5,.)

* Store means by incentive condition
local row=1
foreach X in notincentive incentive{
	mean `group4' if `X' == 1 [pweight=pweight]
	mat R[`row',1] = e(b)
	local ++row
}


* Calculate and store mean belief in no-incentive condition 
mean `group4' if notincentive == 1 [pweight=pweight]
matrix meannoin=e(b)

* Calculate and store incentive coeficient and p-value
reg `group4' incentive  [pweight=pweight], robust
local pvalue4 = trim("`: di %9.3f 2*ttail(e(df_r), abs(_b[incentive]/_se[incentive]))'")

local row=1
foreach X in notincentive incentive  {
	mat R[`row',2]= meannoin[1,1] + _b[incentive]-1.96*_se[incentive]
	mat R[`row',3]= meannoin[1,1] + _b[incentive]+1.96*_se[incentive]
	mat R[`row',4]=`row'	
	mat R[`row',5] = 4 // group
	local ++row
}


preserve
clear
svmat R
tempfile cat4
save `cat4'
restore


* Save bar graph matrix as dataset
clear
foreach a of local numcats {
	append using `cat`a''
}


* For alignment along the x-axis
gen s1 = R5
gen s2 = .
replace s2 = s1 - 0.2 if R5 == 1
replace s2 = s1 - 0.6 if R5 == 2
replace s2 = s1 - 1.0 if R5 == 3
replace s2 = s1 - 1.4 if R5 == 4
gen pgrade1 = (s2 - 0.1) - .6
gen pgrade2 = s2 + 0.1 - .6

* This recovers the group means with which to label each bar.
local i = 0
foreach pgroup of local numcats {
forval rel = 1/2 {
	local ++i
	sum R1 if R4 == `rel' & R5 == `pgroup' 
	local barval`i' = trim("`: di %9.2f r(mean)'")
}
}

global barlabels `"0.2 "Men" 0.8 "Women" 1.4 "Republicans" 2.0 "Democrats""'
global pvalues `"95 0.2 "p-value = `pvalue1'" 95 0.8 "p-value = `pvalue2'" 95 1.4 "p-value = `pvalue3'" 95 2.0 "p-value = `pvalue4'""'
global barvalues = `"65 0.1 "`barval1'" 65 0.3 "`barval2'" 65 0.7 "`barval3'" 65 0.9 "`barval4'" 65 1.3 "`barval5'" 65 1.5 "`barval6'" 65 1.9 "`barval7'" 65 2.1 "`barval8'""'


twoway (bar R1 pgrade1 if R4 == 1, barw(0.18) fi(inten50) lc(black) lw(medium)) (bar R1 pgrade2 if R4 == 2, barw(0.18) fi(inten20) lc(black) lw(medium)) ///
	(rcap R3 R2 pgrade2 if R4 == 2, lc(gs5)), legend(${legend}) graphregion(color(white)) ///
	yscale(range(98)) yla(60(20)100) xla($barlabels, labsize(3.5)) text($pvalues, size(3.5)) text($barvalues, size(3.5)) ///
	ytitle("Prior belief", size (4) height(5))
graph export "$output\fig_motbeliefs1_truncABcont.pdf", replace		



	
	

```

### `dofiles/02_Generate_Treatment_Values.do`
```stata
*** Baseline wage statistic: Gender wage gap among those age 45 who work 40 hours per week and hold a Bachelor degree

// Based on the American Community Survey:
clear all
set more off

use "$path\data\usa_00025.dta", clear

// Latest available wave as of January 2018: Year 2016
keep if year==2016

keep if age>17&age<66

// Set missing wages to missing if applicable
replace incwage=. if incwage==9999999
replace incwage=. if incwage==999999

gen female=0 if sex!=.
replace female=1 if sex==2

gen GWG_ACS_45_Bachelor=. 

gen e_sample=.

* uhrswork = weekly hours worked
* educd==101 -> Bachelor's degree
* classwkr=2 -> Employee

// Calculate women's wages as a share of male wages in the group of 45-year-old employees with a Bachelors degree who work 40 hours per week
reg incwage female if age==45&empstat==1&uhrswork==40&educd==101&classwkr==2 [pweight=perwt], robust
mat beta = e(b)
sca feml = beta[1,1]
disp feml
replace e_sample=0
replace e_sample=1 if e(sample)==1
mean incwage if female==0&age==45&empstat==1&uhrswork==40&educd==101&classwkr==2 [pweight=perwt]
matrix mean=e(b)
mat list mean
sca const=mean[1,1]
replace GWG_ACS_45_Bachelor = 1+(feml/const) if educd==101&age==45&empstat==1&uhrswork==40&classwkr==2

tab GWG_ACS_45_Bachelor

*******

// Based on the Current Population Survey:

use "$path\data\cps_00004.dta", clear

// Latest available wave as of January 2018: October 2017
keep if year==2017
keep if month==10

//keep if eligible for outgoing rotation group (otherwise labor market earnings not elicited)
keep if eligorg==1 				

gen inc_male=. 
gen inc_female=.

// Calculate women's wages as a share of male wages in the group of 45-year-old employees with a Bachelors degree who work 40 hours per week
mean earnweek [pweight=earnwt] if  sex==1&uhrswork1==40&age==45&educ==111
matrix mean1=e(b)
replace inc_male=mean1[1,1]  if uhrswork1==40&age==45&educ==111
mean earnweek [pweight=earnwt] if  sex==2&uhrswork1==40&age==45&educ==111
matrix mean2=e(b)
replace inc_female=mean2[1,1] if uhrswork1==40&age==45&educ==111
gen GWG_45_Bachelor_month_10=inc_female/inc_male

tab GWG_45_Bachelor_month_10



```

### `dofiles/03_SurveyStageIA_cleaning.do`
```stata

***********************************************************************************
// Replication Files
**********************************************************************************
/*
HOW DO BELIEFS ABOUT THE GENDER WAGE GAP AFFECT THE DEMAND FOR PUBLIC POLICY?
Sonja Settele
AEJ:pol
*/
**********************************************************************************

***********************************************************************************
**** Cleaning file Survey Wave A, Stage I (main survey): 
***********************************************************************************

clear all
set more off

use "$path\data\SurveyStageI_WaveA_raw.dta", clear
// Variables not included for confidentiality: zip code and final thoughts/comments by respondent

keep submitdate lastpage startdate panelID interviewtime								///
groupTime499 groupTime742																/// 
region agebracket gender employment hhincbracket demrep demrepother						/// demographics 	
RAND0 RAND RAND12 RAND6 RAND13 RAND2 RAND3 RAND4 RAND5 RAND7 RAND8 RAND9 RAND10 RANDINST		/// randomization
elicitbgendeMarc elicitbgendernoinMar													///
manicheckSQ001 manicheckSQ002 manicheckSQ003 womenwages									///
legislationanchor AAanchor transparencyanchor quotaanchor childcare						///
AAanchorder transpanchorder legisanchorder childcareorder quotaanchorder				///
petition1 AAUW fblike																	///
reasonsSQ003 reasonsSQ004 reasonsSQ005 reasonsSQ006 reasonsSQ001 reasonsSQ002			///
reasons2SQ012 reasons2SQ011 reasons2SQ010 reasons2SQ009 reasons2SQ008 reasons2SQ007		///
reasons3SQ012 reasons3SQ011 reasons3SQ010 reasons3SQ009 reasons3SQ008 reasons3SQ007		///
reasons4SQ007 reasons4SQ008 reasons4SQ009 reasons4SQ010 reasons4SQ011 reasons4SQ012		///
reasons5SQ007 reasons5SQ008 reasons5SQ009 reasons5SQ010 reasons5SQ011 reasons5SQ012		///
Scenario01 Scenario02 Scenario03 Scenario04 Scenario05 Scenario06 						///
Scenario0B1 Scenario0B2 Scenario0B3 Scenario0B4 Scenario0B5 Scenario0B6					///
extrayoung extraHSS extraoccuu															///
genderroleattSQ001 genderroleattSQ002													///
tenyears wageexpectation fairown demo1 demo2 demo2other demo3 ind1 ind1other ind2 occ	///
companysize labinc hhincome hrsweek maritalst maritalstother 							///
childrenSQ001 childrenSQ002 birthyear fblikesettings biased relevant read 			///
trustworthy trustcensus interviewtime 


********************************************************************************
//// Screening questions *****************************************************
********************************************************************************

//employment
gen employ=.
replace employ= 1 if employment=="A1"
replace employ=2 if employment=="A2"
replace employ=3 if employment=="A3"
replace employ=4 if employment=="A4"
replace employ=5 if employment=="A5"
replace employ=6 if employment=="A6"
replace employ=7 if employment=="A7"

label define empl 1 "full-time" 2 "part-time" 3 "self-empl" 4 "unempl" 5 "student" 6 "retired" 7 "out of LF"
label values employ empl

gen employee=(employ==1|employ==2) if employ!=.
lab var employee "Full- or part-time employee"
drop employment

gen employed=(employ==1|employ==2|employ==3) if employ!=.
lab var employed "Employed (full- or part-time or self-emp.)" 

gen nonemployed=(employ==4|employ==5|employ==6|employ==7) if employ!=.
lab var nonemployed "Not employed (unempl., student, out of labor force)"

gen fulltime=(employ==1)
label var fulltime "Full-time employee"
gen parttime=(employ==2)
label var parttime "Part-time employee"
gen selfemp=(employ==3)
label var selfemp "Self-employed"
gen unemployed=(employ==4)
lab var unemployed "Unemployed"
gen student=(employ==5)
lab var student "Student"
gen oolf=(employ==6|employ==7)
label var oolf "Out of labor force"

gen oolf2=student + oolf
label var oolf2 "Out of LF (incl. student and retired)"

//region
rename region regionstring
gen region=.
replace region = 1 if regionstring=="A1"
replace region = 2 if regionstring=="A2"
replace region = 3 if regionstring=="A3"
replace region = 4 if regionstring=="A4"
drop regionstring

gen northeast = (region==1)
gen midwest = (region==2)
gen south = (region==3)
gen west = (region==4)

label var northeast "Northeast"
label var midwest "Midwest"
label var south "South"
label var west "West"

//age group
gen age=. 
replace age = 1 if agebracket=="A1"
replace age = 2 if agebracket=="A2"
replace age = 3 if agebracket=="A3"
replace age = 4 if agebracket=="A4"
replace age = 5 if agebracket=="A5"

label define age 1 "18-24" 2 "25-34" 3 "35-44" 4 "45-54" 5 "55-65"
drop agebracket
tab age, gen(age)

label var age1 "Age 18-24"
label var age2 "Age 25-34"
label var age3 "Age 35-44"
label var age4 "Age 45-54"
label var age5 "Age 55-65"

//household income
gen hhinc=.
forvalues i=1/8{
replace hhinc=`i' if hhincbracket=="A`i'"
}


label define hhinc 1 "< \textdollar 15,000" 2 "\textdollar 15,000 - \textdollar 25,000" 3 "\textdollar 25,000 - \textdollar 50,000" 4 "\textdollar 50,000 - \textdollar 75,000" 5 "\textdollar 75,000 - \textdollar 100,000" 6 "\textdollar 100,000 - \textdollar 150,000" 7 "\textdollar 150,000 - \textdollar 200,000" 8 "> \textdollar 200,000"
label values hhinc hhinc

tab hhinc, gen (hhinc)

label var hhinc1 "Yearly household inc. < \textdollar 15,000" 
label var hhinc2 "Yearly household inc. \textdollar 15,000 - \textdollar 25,000" 
label var hhinc3 "Yearly household inc. \textdollar 25,000 - \textdollar 50,000" 
label var hhinc4 "Yearly household inc. \textdollar 50,000 - \textdollar 75,000" 
label var hhinc5 "Yearly household inc. \textdollar 75,000 - \textdollar 100,000" 
label var hhinc6 "Yearly household inc. \textdollar 100,000 - \textdollar 150,000" 
label var hhinc7 "Yearly household inc. \textdollar 150,000 - \textdollar 200,000" 
label var hhinc8 "Yearly household inc. > \textdollar 200,000" 

gen lowinc=hhinc1+hhinc2+hhinc3
gen highinc=hhinc4+hhinc5+hhinc6+hhinc7+hhinc8

label var lowinc "Household inc $\leq$ \textdollar 50,000" 
label var highinc "Household inc. > \textdollar 50,000"


//gender
rename gender gendstring
gen gender = . 
replace gender = 0 if gendstring== "A1"
replace gender = 1 if gendstring== "A2"

label define gender 0 "male" 1 "female"
label values gender gender
drop gendstring

gen female=gender
label values female gender
label var female "Female"

gen male=0 if female==1
replace male=1 if female==0
lab var male "Male"

// political orientation
gen pol=.
replace pol=-2 if demrep=="A1"
replace pol=-1 if demrep=="A2"
replace	pol=0 if demrep=="A3"
replace pol=1 if demrep=="A4"
replace pol=2 if demrep=="A5"

gen otherpol=(demrep=="-oth-")
label var otherpol "Other pol. orientation"

drop demrep

label define demrep -2 "Republican" -1 "Indep (Repub)" 0 "Independent" 1 "Indep (Demo)" 2 "Democrat" 
label values pol demrep

gen repubindep=(pol<1) if pol!=.

gen republican= (pol<0)
gen democrat= (pol>0&pol!=.)
gen indep = (pol==0)
replace republican=0 if otherpol==1
replace democrat=0 if otherpol==1
replace indep=0 if otherpol==1

label var republican "Republican (incl. indep leaning repub.)"
label var democrat "Democrat (incl. indep. leaning dem.)"
label var indep "Independent"

gen repubonly=(pol==-2)
gen indeprepub=(pol==-1)
gen indeponly=(pol==0)
gen indepdem=(pol==1)
gen demonly=(pol==2)

lab var repubonly "Republican"
lab var indeprepub "Indep. leaning Republican"
lab var indeponly "Independent"
lab var indepdem "Indep. leaning Democrat"
lab var demonly "Democrat"

gen testpol=democrat+indep+republican+otherpol

tab testpol
drop testpol


********************************************************************************
//// Treatment conditions **********************************************
********************************************************************************

// Randomized treatment groups
* T1: High wage gap treatment (74%)
* T2: Low wage gap treatment (94%)
gen T2=(RAND==2) if RAND!=.
gen T1=(RAND==1) if RAND!=.


********************************************************************************
//// Prior beliefs *****************************************************
********************************************************************************

// Prior incentivized or not
gen prior1=(RAND12==1)
lab var prior1 "Incentive"

// prior belief
gen prior = elicitbgendeMarc if RAND12==1
replace prior = elicitbgender if RAND12==0

label var prior "Prior belief"


// Time spent on prior belief: 
*groupTime499: time spent on prior estimate in incentivized condition 
*groupTime742: time spent on prior estimate in unincentivized condition
rename groupTime499 timepriorinc
rename groupTime742 timepriornoinc
gen timeprior=timepriorinc
replace timeprior=timepriornoinc if timeprior==.


********************************************************************************
********************************************************************************
//// Outcome variables *****************************************************
********************************************************************************
********************************************************************************
 
********************************************************************************
//// Self-reported main outcomes *****************************************************
******************************************************************************** 

// Posterior belief about females' relative wages
* RAND4 determines which posterior belief statistic respondent was assigned to
gen posterior = extrayoung
replace posterior = extraHS if RAND4==10
replace posterior = extraoccu if RAND4==11

label var extrayoung "Posterior belief (age 25)"
label var extraHS "Posterior belief (HS degree)"
label var extraoccu "Posterior belief (same occu.)"

tab posterior,m
* -> 13 missing observations, not recorded due to bug in survey


//Manipulation check/ Perceptions related to wage gap
rename manicheckSQ001 large
rename manicheckSQ002 problem
rename manicheckSQ003 govmore


foreach var in large problem govmore womenwages fairown{
rename `var' `var'string
gen `var'=.
forvalues i=1/10{
replace `var'=`i' if `var'string=="A`i'"
}
drop `var'string
}

* Set perceived fairness of own most recent or current wage to missing for those who have never worked
replace fairown=. if fairown==6

label var large "GWG large"
label var problem "GWG problem"
label var govmore "Gvmt. should do more"
label var womenwages "Women's wages are fair"
label var fairown "My own wage is fair"


//Demand for specific policies
foreach var in quotaanchor AAanchor transparencyanchor legislationanchor childcare{
rename `var' `var'string
gen `var'=.
forvalues i=1/5{
replace `var'=`i' if `var'string=="A`i'"
}
drop `var'string
}


label var quotaanchor "Gender quotas"
label var AAanchor "Aff. action"
label var legislationanchor "Equal pay legislation"
label var transparencyanchor "Wage transparency"
label var childcare "Public child care"


********************************************************************************
//// Behavioral outcomes *****************************************************
******************************************************************************** 

//Intentions to sign petition
gen petition=-1 if petition1=="A2"
replace petition=0 if petition1=="A3"
replace petition=1 if petition1=="A1"

gen petitionI=0 if petition<1
replace petitionI=1 if petition==1

gen petitionII=0 if petition>-1 &petition!=.
replace petitionII=1 if petition==-1

label var petitionI "Petition I (increase reporting)"
label var petitionII "Petition II (abolish reporting)"

drop petition1


//Donation decision
label var AAUW "Donation for NGO"


// Facebook like
rename fblike fblikestring
gen fblike=0 if fblikestring=="not clicked"
replace fblike=1 if fblikestring=="clicked"

label var fblike "Facebook like for NGO"

drop fblikestring

gen fblike2=fblike
replace fblike2=. if fblikesettings=="A3"


// Decision to acquire additional information
replace Scenario0B3="A2" if Scenario0B3=="A3"

* RANDINST==1: First three choices were about information from progressive source, last three about conservative source
* RANDINST==2: First three choices were about information from conservative source, last three from progressive source
gen scenario1support=0
replace scenario1support=1 if (Scenario01=="A1"&RANDINST==1)|(Scenario0B4=="A1"&RANDINST==2)
gen scenario2support=0
replace scenario2support=1 if (Scenario02=="A1"&RANDINST==1)|(Scenario0B5=="A1"&RANDINST==2)
gen scenario3support=0
replace scenario3support=1 if (Scenario03=="A1"&RANDINST==1)|(Scenario0B6=="A1"&RANDINST==2)

gen scenario1oppose=0
replace scenario1oppose=1 if (Scenario04=="A1"&RANDINST==1)|(Scenario0B1=="A1"&RANDINST==2)
gen scenario2oppose=0
replace scenario2oppose=1 if (Scenario05=="A1"&RANDINST==1)|(Scenario0B2=="A1"&RANDINST==2)
gen scenario3oppose=0
replace scenario3oppose=1 if (Scenario06=="A1"&RANDINST==1)|(Scenario0B3=="A1"&RANDINST==2)

* Number of times respondent chose info over money:
gen infopaysupport=scenario1support + scenario2support + scenario3support
gen infopayoppose=scenario1oppose + scenario2oppose + scenario3oppose

tab infopaysupport
tab infopayoppose

label var infopaysupport "Will. to pay for progressive info"
label var infopayoppose "Will. to pay for traditional info"

drop Scenario01-Scenario06
drop Scenario0B1-Scenario0B6


********************************************************************************
//// Additional outcomes/mechanisms *********************************************
********************************************************************************

// Beliefs about prevalence of underlying factors
local reasons reasonsSQ001 reasonsSQ002 reasonsSQ003 reasonsSQ004 reasonsSQ005 reasonsSQ006			/// reasons 1
reasons2SQ012 reasons2SQ011 reasons2SQ010 reasons2SQ009 reasons2SQ008 reasons2SQ007		/// reasons 2
reasons3SQ012 reasons3SQ011 reasons3SQ010 reasons3SQ009 reasons3SQ008 reasons3SQ007		/// reasons 3
reasons4SQ007 reasons4SQ008 reasons4SQ009 reasons4SQ010 reasons4SQ011 reasons4SQ012 	/// reasons 4
reasons5SQ007 reasons5SQ008 reasons5SQ009 reasons5SQ010 reasons5SQ011 reasons5SQ012		
	

foreach var in `reasons'{
rename `var' `var'string
gen `var'=.
forvalues i=1/5{
replace `var'=`i' if `var'string=="A`i'"
}
drop `var'string
}

* RAND 3 indicates which out of 5 randomized orders was chosen

gen interested = . 
replace interested = reasonsSQ001 if RAND3==6
replace interested = reasons2SQ007 if RAND3==7
replace interested = reasons3SQ010 if RAND3==8
replace interested = reasons4SQ008 if RAND3==9
replace interested = reasons5SQ010 if RAND3==10
label var interested "Diff. interests"

gen society=.
replace society = reasonsSQ002 if RAND3==6
replace society = reasons2SQ008 if RAND3==7
replace society = reasons3SQ011 if RAND3==8
replace society = reasons4SQ011 if RAND3==9
replace society = reasons5SQ007 if RAND3==10
label var society "Work vs. family"

gen boys=.
replace boys = reasonsSQ003 if RAND3==6
replace boys = reasons2SQ009 if RAND3==7
replace boys = reasons3SQ012 if RAND3==8
replace boys = reasons4SQ010 if RAND3==9
replace boys = reasons5SQ008 if RAND3==10
label var boys "Sozialisation"

gen discrimination=. 
replace discrimination = reasonsSQ004 if RAND3==6
replace discrimination = reasons2SQ010 if RAND3==7
replace discrimination = reasons3SQ007 if RAND3==8
replace discrimination = reasons4SQ007 if RAND3==9
replace discrimination = reasons5SQ011 if RAND3==10 
label var discrimination "Discrimination"

gen ambitious=.
replace ambitious = reasonsSQ005 if RAND3==6
replace ambitious = reasons2SQ011 if RAND3==7
replace ambitious = reasons3SQ008 if RAND3==8
replace ambitious = reasons4SQ012  if RAND3==9
replace ambitious = reasons5SQ009 if RAND3==10
label var ambitious "Diff. ambitions"

gen talented=.
replace talented = reasonsSQ006 if RAND3==6
replace talented = reasons2SQ012 if RAND3==7
replace talented = reasons3SQ009 if RAND3==8
replace talented = reasons4SQ009 if RAND3==9
replace talented = reasons5SQ012 if RAND3==10
label var talented "Diff. talents"

local reasons ambitious talented interested boys discrimination society

drop reasonsSQ001 reasonsSQ002 reasonsSQ003 reasonsSQ004 reasonsSQ005 reasonsSQ006		/// reasons 1
reasons2SQ012 reasons2SQ011 reasons2SQ010 reasons2SQ009 reasons2SQ008 reasons2SQ007		/// reasons 2
reasons3SQ012 reasons3SQ011 reasons3SQ010 reasons3SQ009 reasons3SQ008 reasons3SQ007		/// reasons 3
reasons4SQ007 reasons4SQ008 reasons4SQ009 reasons4SQ010 reasons4SQ011 reasons4SQ012 	/// reasons 4
reasons5SQ007 reasons5SQ008 reasons5SQ009 reasons5SQ010 reasons5SQ011 reasons5SQ012	

gen orderint=1 if RAND3==6
replace orderint=6 if RAND3==7
replace orderint=3 if RAND3==8
replace orderint=2 if RAND3==9
replace orderint=4 if RAND3==10

gen ordersociety=2 if RAND3==6
replace ordersociety=5 if RAND3==7
replace ordersociety=2 if RAND3==8
replace ordersociety=5 if RAND3==9
replace ordersociety=1 if RAND3==10

gen orderboys=3 if RAND3==6
replace orderboys=4 if RAND3==7
replace orderboys=1 if RAND3==8
replace orderboys=4 if RAND3==9
replace orderboys=2 if RAND3==10

gen orderdisc=4 if RAND3==6
replace orderdisc=3 if RAND3==7
replace orderdisc=6 if RAND3==8
replace orderdisc=1 if RAND3==9
replace orderdisc=5 if RAND3==10

gen orderambitious=5 if RAND3==6
replace orderambitious=2 if RAND3==7
replace orderambitious=5 if RAND3==8
replace orderambitious=6 if RAND3==9
replace orderambitious=3 if RAND3==10

gen ordertalent=6 if RAND3==6
replace ordertalent=1 if RAND3==7
replace ordertalent=4 if RAND3==8
replace ordertalent=3 if RAND3==9
replace ordertalent=6 if RAND3==10


//Treatment info perceived as relevant
rename relevant relevantstring
gen relevant=.
forvalues i=1/5{
replace relevant=`i' if relevantstring=="A`i'"
}


// Info perceived as trustworthy
rename trustworthy trustw
gen trustworthy=.
forvalues i=1/5{
replace trustworthy=`i' if trustw=="A`i'"
}
drop trustw

//Trust in survey data provided by census
rename trustcensus trustcensusstring
gen trustcensus=.
forvalues i=1/6{
replace trustcensus=`i' if trustcensusstring=="A`i'"
}

replace trustcensus=. if trustcensus==6


// Survey perceived as biased
rename biased biasedstring
gen biased = 0 if biasedstring=="A3"
replace biased = -1 if biasedstring=="A1"
replace biased = 1 if biasedstring=="A2"
drop biasedstring


// Personal wage expectations (ten years from now) 
rename tenyears tenyearsstring
gen tenyears=.
forvalues i=1/3{
replace tenyears=`i' if tenyearsstring=="A`i'"
}

replace tenyears=-tenyears
drop tenyearsstring

gen wageexp=.
forvalues i=1/5{
replace wageexp=`i' if wageexpectation=="A`i'"
}
drop wageexpectation


// Views/attitudes of control group
rename genderroleattSQ001 GRA
rename genderroleattSQ002 zerosum

foreach var in GRA zerosum{
rename `var' `var'string
gen `var'=.
forvalues i=1/5{
replace `var'=`i' if `var'string=="A`i'"
}
drop `var'string
}

				

********************************************************************************
***********Additional Controls/Background info   ******************************
********************************************************************************


// education
rename demo1 education
gen educ=.

forvalues i=1/9{
replace educ=`i' if education=="A`i'"
}

label define edu 1 "8th degree" 2 "some HS" 3 "HS" 4 "some college" 5 "2-year college" 6 "4-year college" 7 "Master" 8 "Dr." 9 "Prof. Degree"
label values educ edu

gen bachelormore=(educ>5) if educ!=.
gen associatemore=(educ>4) if educ!=.
drop education

label var bachelormore "Bachelor's degree or more"
label var associatemore "2-year College degree +"

tab educ, gen(educ)

gen educ0= (educ==1)

lab var educ0 "8th degree"
lab var educ1 "Some HS"
lab var educ2 "HS"
lab var educ3 "Some college"
lab var educ4 "2-year college"
lab var educ5 "4-year college"
lab var educ6 "Master"
lab var educ7 "PhD"
lab var educ8 "Prof. Degree (JD, MD, MBA)"


// race
gen white = (demo2=="A1")
gen black = (demo2=="A2")
gen asian = (demo2=="A3")
gen otherrace= (demo2=="-oth-")

label var white "White/Caucasian"
label var black "Black/African American"
label var asian "Asian American"

label var otherrace "Other race"

// hispanic
gen hispanic = (demo3=="A1")
label var hispanic "Hispanic or latino origin"

// Continuous measure of hh income
tab hhinc
gen hhinccont=.
replace hhinccont=6735 if hhinc==1
replace hhinccont=19742 if hhinc==2
replace hhinccont=36701 if hhinc==3
replace hhinccont=61275 if hhinc==4
replace hhinccont=86204 if hhinc==5
replace hhinccont=120686 if hhinc==6
replace hhinccont=170381 if hhinc==7
replace hhinccont=327261 if hhinc==8

gen loghhinc=log(hhinccont)

label var loghhinc "Log household income"
label var hhinccon "Household income"

// own labor market income 
* Some respondents used a dot to indicate "thousands" -> Correct manually
replace labinc=9936 if labinc==9.936
replace labinc=14122 if labinc==14.411
replace labinc=16945 if labinc==16.945
replace labinc=28999 if labinc==28.999
replace labinc=29999 if labinc==29.999
replace labinc=34674 if labinc==34.674
replace labinc=37042 if labinc==37.042
replace labinc=45169 if labinc==45.169
replace labinc=45812 if labinc==45.812
replace labinc=46125 if labinc==46.125
replace labinc=64999 if labinc==64.999
replace labinc=93855 if labinc==93.855


winsor labinc, gen (labincome) p(0.005)

// company size
rename companysize companysizestring
gen companysize=1 if companysizestring=="A1"
replace companysize=2 if companysizestring=="A2"
replace companysize=3 if companysizestring=="A3"
drop companysizestring


// hours worked per week
gen hours=.

forvalues i=1/12{
replace hours=`i' if hrsweek=="A`i'"
}



// civil status
rename maritalst married1
gen married=. 
replace married=1 if married1=="A1"
replace married=2 if married1=="A2"
replace married=3 if married1=="A3"
replace married=4 if married1=="A4"
drop married1

rename married civil

gen single = (civil==1) if civil!=.
label var single "Single"
gen married = (civil==2) if civil!=.
label var married "Married"
gen divorced = (civil==3) if civil!=.
label var divorced "Divorced"
gen widowed = (civil==4) if civil!=.
label var widowed "Widowed"

// number of children

rename childrenSQ001 boy
rename childrenSQ002 girl

foreach var in boy girl{
rename `var' `var'string
gen `var'=.
forvalues i=1/6{
replace `var'=`i' if `var'string=="A`i'"
}
drop `var'string
replace `var'=`var'-1
}

gen children=boy+girl
gen anychildren=(children>0&children!=.)
label var anychildren "Has children"

tab children

//  Birthyear
rename birthyear by
gen birthyear=.
replace birthyear=1951 if by=="A1"
replace birthyear=1952 if by=="A2"
replace birthyear=1953 if by=="A3"
replace birthyear=1954 if by=="A4"
replace birthyear=1955 if by=="A5"
replace birthyear=1956 if by=="A6"
replace birthyear=1957 if by=="A7"
replace birthyear=1958 if by=="A8"
replace birthyear=1959 if by=="A9"
replace birthyear=1960 if by=="A10"
replace birthyear=1961 if by=="A11"
replace birthyear=1962 if by=="A12"
replace birthyear=1963 if by=="A13"

gen birthyearhelp=.

forvalues i=1/37{
replace birthyearhelp=`i' if by=="`i'"
}

replace birthyear=birthyearhelp+1963 if birthyearhelp!=.

drop by

gen age_det=2018-birthyear
label var age_det "Age"

// fblikesettings
gen fbset=.
forvalues i=1/3{
replace fbset=`i' if fblikesettings=="A`i'"
}
drop fblikesettings

label define fbset 1 "visible" 2 "private" 3 "no facebook"
label values fbset fbset


//Have you read about the topic in the past 3 weeks?
rename read readcat
gen read=.
replace read=0 if readcat=="A2"
replace read=1 if readcat=="A1"
replace read=2 if readcat=="A3"

drop readcat

rename RAND rand

save "$path\data\SurveyStageIA_beforezscore.dta", replace 


exit



```

### `dofiles/04_SurveyStageIB_cleaning.do`
```stata

***********************************************************************************
// Replication Files
**********************************************************************************
/*
HOW DO BELIEFS ABOUT THE GENDER WAGE GAP AFFECT THE DEMAND FOR PUBLIC POLICY?
Sonja Settele
AEJ:pol
*/
**********************************************************************************

***********************************************************************************
**** Cleaning file Survey Wave B, Stage I (main survey): 
***********************************************************************************

clear all
set more off

use "$path\data\SurveyStageI_WaveB_raw.dta", clear
// Variables not included for confidentiality: zip code and final thoughts/comments by respondent


keep submitdate lastpage startdate panelID interviewtime								///
groupTime843 groupTime883																/// 
region agebracket gender employment hhincbracket demrep demrepother						/// 	
RAND0 RAND RAND12 RAND6 RAND13 RAND2 RAND3 RAND4 RAND5 RAND6 RAND7 RAND8 RAND9 RAND10 RANDINST		/// 
 RAND14 RAND15 RAND16 RAND17 	 														///
elicitbgendeMarc elicitbgendernoinMar													///
manicheckSQ001 manicheckSQ002 manicheckSQ003 womenwages									///
legislationanchor AAanchor transparencyanchor quotaanchor childcare						///
AAanchorder transpanchorder legisanchorder childcareorder quotaanchorder				///
petition1 AAUW fblike																	///
Scenario01 Scenario02 Scenario03 Scenario04 Scenario05 Scenario06 						///
Scenario0B1 Scenario0B2 Scenario0B3 Scenario0B4 Scenario0B5 Scenario0B6					///
effectivenessSQ001 effectivenessSQ003 effectivenessSQ004 								///
effectiveness2SQ001 effectiveness2SQ003 effectiveness2SQ004								///
effectiveness3SQ001 effectiveness3SQ003 effectiveness3SQ004								///
trustgov costsSQ002 costsSQ003 costsSQ004 costs2SQ002 costs2SQ003 costs2SQ004			///
costs3SQ002 costs3SQ003 costs3SQ004														///
extrasame extrachild 																	///
genderroleattSQ001 genderroleattSQ002 genderroleattSQ004 genderroleattSQ005				///
genderroleattSQ006 genderroleattSQ007													///
attitudes2SQ001 attitudes2SQ002 attitudes2SQ004 attitudes2SQ005 						///
attitudes2SQ006 attitudes2SQ007															///
attitudes3SQ001 attitudes3SQ002 attitudes3SQ004 attitudes3SQ005 attitudes3SQ006 		///
attitudes3SQ007 																		///
attitudes4SQ001 attitudes4SQ002 attitudes4SQ004 attitudes4SQ005 attitudes4SQ006 		///
attitudes4SQ007 																		///
attitudes5SQ001 attitudes5SQ002 attitudes5SQ004 attitudes5SQ005 attitudes5SQ006 		///
attitudes5SQ007 																		///
attitudes6SQ001 attitudes6SQ002 attitudes6SQ004 attitudes6SQ005 attitudes6SQ006 		///
attitudes6SQ007																			///
tenyears wageexpectation 																///
importanceSQ001 importanceSQ002 importanceSQ003 importanceSQ004 						///
importance2SQ001 importance2SQ002 importance2SQ003 importance2SQ004						///
importance3SQ001 importance3SQ002 importance3SQ003 importance3SQ004 					///
importance4SQ001 importance4SQ002 importance4SQ003 importance4SQ004						///
vote voteother																			///
tenyears wageexpectation fairown demo1 demo2 demo2other demo3 ind1 ind1other ind2 occ	///
companysize labinc hhincome hrsweek maritalst maritalstother 							///
childrenSQ001 childrenSQ002 birthyear fblikesettings biased relevant read 			///
trustworthy trustcensus interviewtime payoffinfo131


********************************************************************************
//// Screening questions *****************************************************
********************************************************************************

//employment
gen employ=.
replace employ=1 if employment=="A1"
replace employ=2 if employment=="A2"
replace employ=3 if employment=="A3"
replace employ=4 if employment=="A4"
replace employ=5 if employment=="A5"
replace employ=6 if employment=="A6"
replace employ=7 if employment=="A7"

label define empl 1 "full-time" 2 "part-time" 3 "self-empl" 4 "unempl" 5 "student" 6 "retired" 7 "out of LF"
label values employ empl

gen employee=(employ==1|employ==2) if employ!=.
lab var employee "Full- or part-time employee"
drop employment

gen employed=(employ==1|employ==2|employ==3) if employ!=.
lab var employed "Employed (full- or part-time or self-emp.)" 

gen nonemployed=(employ==4|employ==5|employ==6|employ==7) if employ!=.
lab var nonemployed "Not employed (unempl., student, out of labor force)"

gen fulltime=(employ==1)
label var fulltime "Full-time employee"
gen parttime=(employ==2)
label var parttime "Part-time employee"
gen selfemp=(employ==3)
label var selfemp "Self-employed"
gen unemployed=(employ==4)
lab var unemployed "Unemployed"
gen student=(employ==5)
lab var student "Student"
gen oolf=(employ==6|employ==7)
label var oolf "Out of labor force"

gen oolf2=student + oolf
label var oolf2 "Out of LF (incl. student and retired)"

//region
rename region regionstring
gen region=.
replace region = 1 if regionstring=="A1"
replace region = 2 if regionstring=="A2"
replace region = 3 if regionstring=="A3"
replace region = 4 if regionstring=="A4"
drop regionstring

gen northeast = (region==1)
gen midwest = (region==2)
gen south = (region==3)
gen west = (region==4)

label var northeast "Northeast"
label var midwest "Midwest"
label var south "South"
label var west "West"

*agegroup
gen age=. 
replace age = 1 if agebracket=="A1"
replace age = 2 if agebracket=="A2"
replace age = 3 if agebracket=="A3"
replace age = 4 if agebracket=="A4"
replace age = 5 if agebracket=="A5"

label define age 1 "18-24" 2 "25-34" 3 "35-44" 4 "45-54" 5 "55-65"
drop agebracket

//hhinc
gen hhinc=.
forvalues i=1/8{
replace hhinc=`i' if hhincbracket=="A`i'"
}


label define hhinc 1 "< \textdollar 15,000" 2 "\textdollar 15,000 - \textdollar 25,000" 3 "\textdollar 25,000 - \textdollar 50,000" 4 "\textdollar 50,000 - \textdollar 75,000" 5 "\textdollar 75,000 - \textdollar 100,000" 6 "\textdollar 100,000 - \textdollar 150,000" 7 "\textdollar 150,000 - \textdollar 200,000" 8 "> \textdollar 200,000"
label values hhinc hhinc


//gender
rename gender gendstring
gen gender = . 
replace gender = 0 if gendstring== "A1"
replace gender = 1 if gendstring== "A2"

label define gender 0 "male" 1 "female"
label values gender gender
drop gendstring

gen female=gender
label values female gender
label var female "Female"

gen male=0 if female==1
replace male=1 if female==0
lab var male "Male"

// political orientation
gen pol=.
replace pol=-2 if demrep=="A1"
replace pol=-1 if demrep=="A2"
replace	pol=0 if demrep=="A3"
replace pol=1 if demrep=="A4"
replace pol=2 if demrep=="A5"

gen otherpol=(demrep=="-oth-")
label var otherpol "Other pol. orientation"

drop demrep

label define demrep -2 "Republican" -1 "Indep (Repub)" 0 "Independent" 1 "Indep (Demo)" 2 "Democrat" 
label values pol demrep

gen repubindep=(pol<1) if pol!=.

gen republican= (pol<0)
gen democrat= (pol>0&pol!=.)
gen indep = (pol==0)
replace republican=0 if otherpol==1
replace democrat=0 if otherpol==1
replace indep=0 if otherpol==1

label var republican "Republican (incl. indep leaning repub.)"
label var democrat "Democrat (incl. indep. leaning dem.)"
label var indep "Independent"

gen repubonly=(pol==-2)
gen indeprepub=(pol==-1)
gen indeponly=(pol==0)
gen indepdem=(pol==1)
gen demonly=(pol==2)

lab var repubonly "Republican"
lab var indeprepub "Indep. leaning Republican"
lab var indeponly "Independent"
lab var indepdem "Indep. leaning Democrat"
lab var demonly "Democrat"

gen testpol=democrat+indep+republican+otherpol

tab testpol
drop testpol


********************************************************************************
//// Treatment conditions **********************************************
********************************************************************************

// Randomized treatment groups
* T1: High wage gap treatment (74%)
* T2: Low wage gap treatment (94%)
gen T2=(RAND==2) if RAND!=.
gen T1=(RAND==1) if RAND!=.

********************************************************************************
//// Prior beliefs *****************************************************
********************************************************************************

// Prior incentivized or not
gen prior1=(RAND12==1)
lab var prior1 "Incentive"

// prior belief
gen prior = elicitbgendeMarc if RAND12==1
replace prior = elicitbgender if RAND12==0

label var prior "Prior belief"

// Time for prior guess: 
*groupTime843: time spent on prior estimate in incentivized condition
*groupTime883: time spent on prior estimate in unincentivized condition
rename groupTime843 timepriorinc
rename groupTime883 timepriornoinc
gen timeprior=timepriorinc
replace timeprior=timepriornoinc if timeprior==.


********************************************************************************
********************************************************************************
//// Outcome variables *****************************************************
********************************************************************************
********************************************************************************
 
// posterior belief 
gen posterior = extrachild  if RAND4==11
replace posterior = extrasame if RAND4==10

label var extrachild "Posterior belief (with child)"
label var extrasame "Posterior belief (same job)"


tab posterior,m


//Manipulation check
rename manicheckSQ001 large
rename manicheckSQ002 problem
rename manicheckSQ003 govmore


foreach var in large problem govmore womenwages fairown{
rename `var' `var'string
gen `var'=.
forvalues i=1/10{
replace `var'=`i' if `var'string=="A`i'"
}
drop `var'string
}

replace fairown=. if fairown==6

label var large "GWG large"
label var problem "GWG problem"
label var govmore "Gvmt. should do more"
label var womenwages "Women's wages are fair"
label var fairown "My own wage is fair"


//Anchored policies
foreach var in quotaanchor AAanchor transparencyanchor legislationanchor childcare{
rename `var' `var'string
gen `var'=.
forvalues i=1/5{
replace `var'=`i' if `var'string=="A`i'"
}
drop `var'string
}

foreach var in quotaanchor AAanchor transparencyanchor legislationanchor childcare{
tab `var' if RAND==0
}

* The variable called transparencyanchor contained a different question in Wave B 
* Question in Wave B is about demand for a reporting tool similar to the one in the UK -> rename
gen UKtool=transparencyanchor 
replace transparencyanchor = . 

label var UKtool "Public website"

label var quotaanchor "Gender quotas"
label var AAanchor "Aff. action"
label var legislationanchor "Equal pay legislation"
label var childcare "Public child care"


********************************************************************************
//// Behavioral outcomes *****************************************************
******************************************************************************** 

//Petition decision
gen petition=-1 if petition1=="A2"
replace petition=0 if petition1=="A3"
replace petition=1 if petition1=="A1"

gen petitionI=0 if petition<1
replace petitionI=1 if petition==1

gen petitionII=0 if petition>-1 &petition!=.
replace petitionII=1 if petition==-1

label var petitionI "Petition I (increase reporting)"
label var petitionII "Petition II (abolish reporting)"


//donation decision
label var AAUW "Donation for NGO"


// facebook like
rename fblike fblikestring
gen fblike=0 if fblikestring=="not clicked"
replace fblike=1 if fblikestring=="clicked left"|fblikestring=="clicked right"

label var fblike "Facebook like for NGO"

drop fblikestring

gen fblike2=fblike
replace fblike2=. if fblikesettings=="A3"


//Info decision
replace Scenario0B3="A2" if Scenario0B3=="A3"

* RANDINST==1: First three choices were about information from progressive source, last three about conservative source
* RANDINST==2: First three choices were about information from conservative source, last three from progressive source

gen scenario1support=0 if RAND!=0
replace scenario1support=1 if (Scenario01=="A1"&RANDINST==1)|(Scenario0B4=="A1"&RANDINST==2)
gen scenario2support=0
replace scenario2support=1 if (Scenario02=="A1"&RANDINST==1)|(Scenario0B5=="A1"&RANDINST==2)
gen scenario3support=0
replace scenario3support=1 if (Scenario03=="A1"&RANDINST==1)|(Scenario0B6=="A1"&RANDINST==2)

gen scenario1oppose=0 if RAND!=0
replace scenario1oppose=1 if (Scenario04=="A1"&RANDINST==1)|(Scenario0B1=="A1"&RANDINST==2)
gen scenario2oppose=0
replace scenario2oppose=1 if (Scenario05=="A1"&RANDINST==1)|(Scenario0B2=="A1"&RANDINST==2)
gen scenario3oppose=0
replace scenario3oppose=1 if (Scenario06=="A1"&RANDINST==1)|(Scenario0B3=="A1"&RANDINST==2)

gen infopaysupport=scenario1support + scenario2support + scenario3support
gen infopayoppose=scenario1oppose + scenario2oppose + scenario3oppose

tab infopaysupport
tab infopayoppose

label var infopaysupport "Will. to pay for progressive info"
label var infopayoppose "Will. to pay for traditional info"

drop Scenario01-Scenario06
drop Scenario0B1-Scenario0B6



********************************************************************************
//// Additional outcomes/mechanisms *********************************************
********************************************************************************


* Perceived Effectiveness 

local effective effectivenessSQ001 effectivenessSQ003 effectivenessSQ004 ///
effectiveness2SQ001 effectiveness2SQ003 effectiveness2SQ004 ///
effectiveness3SQ001 effectiveness3SQ003 effectiveness3SQ004	


foreach var in `effective'{
rename `var' `var'string
gen `var'=.
forvalues i=1/5{
replace `var'=`i' if `var'string=="A`i'"
}
drop `var'string
}



gen effdis = . 
replace effdis = effectivenessSQ001 if RAND14==1
replace effdis = effectiveness2SQ003 if RAND14==2
replace effdis = effectiveness3SQ004 if RAND14==3
label var effdis "Effective Anti-Disc."

gen effAA=.
replace effAA = effectivenessSQ003 if RAND14==1
replace effAA = effectiveness2SQ004 if RAND14==2
replace effAA = effectiveness3SQ001 if RAND14==3
label var effAA "Effective AA"

gen effworkfam=.
replace effworkfam = effectivenessSQ004 if RAND14==1
replace effworkfam = effectiveness2SQ001 if RAND14==2
replace effworkfam = effectiveness3SQ003 if RAND14==3
label var effworkfam "Effective work-fam"

local effective effdis effAA effworkfam


drop effectivenessSQ001 effectivenessSQ003 effectivenessSQ004 ///
effectiveness2SQ001 effectiveness2SQ003 effectiveness2SQ004 ///
effectiveness3SQ001 effectiveness3SQ003 effectiveness3SQ004	


gen ordereffdis=1 if RAND14==1
replace ordereffdis=2 if RAND14==2 
replace ordereffdis=3 if RAND14==3

gen ordereffAA = 2 if RAND14==1 
replace ordereffAA = 3 if RAND14==2
replace ordereffAA = 1 if RAND14==3

gen ordereffworkfam=3 if RAND14==1
replace ordereffworkfam=1 if RAND14==2
replace ordereffworkfam=2 if RAND14==3

**Trust in government
foreach var in trustgov{
rename `var' `var'string
gen `var'=.
forvalues i=1/5{
replace `var'=`i' if `var'string=="A`i'"
}
drop `var'string
}

* Wage expectations
rename tenyears tenyearsstring
gen tenyears=.
forvalues i=1/3{
replace tenyears=`i' if tenyearsstring=="A`i'"
}

replace tenyears=-tenyears
drop tenyearsstring

gen wageexp=.
forvalues i=1/5{
replace wageexp=`i' if wageexpectation=="A`i'"
}
drop wageexpectation



********************************************************************************
***********Additional Controls *************************************************
********************************************************************************

// Views/attitudes of control group:

local attitudes																			///
genderroleattSQ001 genderroleattSQ002 genderroleattSQ004 genderroleattSQ005				///
genderroleattSQ006 genderroleattSQ007													///
attitudes2SQ001 attitudes2SQ002 attitudes2SQ004 attitudes2SQ005 						///
attitudes2SQ006 attitudes2SQ007															///
attitudes3SQ001 attitudes3SQ002 attitudes3SQ004 attitudes3SQ005 attitudes3SQ006 		///
attitudes3SQ007 																		///
attitudes4SQ001 attitudes4SQ002 attitudes4SQ004 attitudes4SQ005 attitudes4SQ006 		///
attitudes4SQ007 																		///
attitudes5SQ001 attitudes5SQ002 attitudes5SQ004 attitudes5SQ005 attitudes5SQ006 		///
attitudes5SQ007 																		///
attitudes6SQ001 attitudes6SQ002 attitudes6SQ004 attitudes6SQ005 attitudes6SQ006 		///
attitudes6SQ007																			///

foreach var in `attitudes'{
rename `var' `var'string
gen `var'=.
forvalues i=1/5{
replace `var'=`i' if `var'string=="A`i'"
}
drop `var'string
}

gen GRA=.
replace GRA=genderroleattSQ001 if RAND16==1
replace GRA=attitudes2SQ004 if RAND16==2
replace GRA=attitudes3SQ005 if RAND16==3
replace GRA=attitudes4SQ007 if RAND16==4
replace GRA=attitudes5SQ002 if RAND16==5
replace GRA=attitudes6SQ006 if RAND16==6

gen zerosum=.
replace zerosum=genderroleattSQ002 if RAND16==1
replace zerosum= attitudes2SQ007 if RAND16==2
replace zerosum=attitudes3SQ006 if RAND16==3
replace zerosum=attitudes4SQ005 if RAND16==4
replace zerosum=attitudes5SQ004 if RAND16==5
replace zerosum=attitudes6SQ001 if RAND16==6

gen meritocracy=.
replace meritocracy= genderroleattSQ004 if RAND16==1
replace meritocracy= attitudes2SQ005 if RAND16==2
replace meritocracy= attitudes3SQ002 if RAND16==3
replace meritocracy= attitudes4SQ001 if RAND16==4
replace meritocracy= attitudes5SQ006 if RAND16==5
replace meritocracy= attitudes6SQ007 if RAND16==6 

gen priority=.
replace priority=genderroleattSQ005 if RAND16==1
replace priority=attitudes2SQ001 if RAND16==2
replace priority=attitudes3SQ004 if RAND16==3
replace priority=attitudes4SQ006 if RAND16==4
replace priority=attitudes5SQ007 if RAND16==5
replace priority=attitudes6SQ002 if RAND16==6

gen tallshort=.
replace tallshort=genderroleattSQ006 if RAND16==1
replace tallshort=attitudes2SQ002 if RAND16==2
replace tallshort=attitudes3SQ007  if RAND16==3
replace tallshort=attitudes4SQ004 if RAND16==4
replace tallshort=attitudes5SQ001 if RAND16==5
replace tallshort=attitudes6SQ005 if RAND16==6

gen reversedisc=.
replace reversedisc=genderroleattSQ007 if RAND16==1
replace reversedisc=attitudes2SQ006 if RAND16==2
replace reversedisc=attitudes3SQ001 if RAND16==3
replace reversedisc=attitudes4SQ002 if RAND16==4
replace reversedisc=attitudes5SQ005 if RAND16==5
replace reversedisc=attitudes6SQ004 if RAND16==6

drop genderroleattSQ001 genderroleattSQ002 genderroleattSQ004 genderroleattSQ005		///
genderroleattSQ006 genderroleattSQ007													///
attitudes2SQ001 attitudes2SQ002 attitudes2SQ004 attitudes2SQ005 						///
attitudes2SQ006 attitudes2SQ007															///
attitudes3SQ001 attitudes3SQ002 attitudes3SQ004 attitudes3SQ005 attitudes3SQ006 		///
attitudes3SQ007 																		///
attitudes4SQ001 attitudes4SQ002 attitudes4SQ004 attitudes4SQ005 attitudes4SQ006 		///
attitudes4SQ007 																		///
attitudes5SQ001 attitudes5SQ002 attitudes5SQ004 attitudes5SQ005 attitudes5SQ006 		///
attitudes5SQ007 																		///
attitudes6SQ001 attitudes6SQ002 attitudes6SQ004 attitudes6SQ005 attitudes6SQ006 		///
attitudes6SQ007	
 
 // Perceived Costs of policy intervention
 
local costs costsSQ002 costsSQ003 costsSQ004 costs2SQ002 costs2SQ003 costs2SQ004 ///
costs3SQ002 costs3SQ003 costs3SQ004

foreach var in `costs'{
rename `var' `var'string
gen `var'=.
forvalues i=1/5{
replace `var'=`i' if `var'string=="A`i'"
}
drop `var'string
}

gen monetary=.
replace monetary = costsSQ002 if RAND15==1
replace monetary = costs2SQ004 if RAND15==2
replace monetary = costs3SQ003 if RAND15==3

gen bureaucracy=. 
replace bureaucracy = costsSQ003 if RAND15==1
replace bureaucracy = costs2SQ002 if RAND15==2
replace bureaucracy = costs3SQ004 if RAND15==3

gen distortion=.
replace distortion = costsSQ004 if RAND15==1
replace distortion = costs2SQ003 if RAND15==2
replace distortion = costs3SQ002 if RAND15==3


*****
*Importance of the topic (Control group only)***
****

local importance importanceSQ001 importanceSQ002 importanceSQ003 importanceSQ004 ///
importance2SQ001 importance2SQ002 importance2SQ003 importance2SQ004 ///
importance3SQ001 importance3SQ002 importance3SQ003 importance3SQ004 					///
importance4SQ001 importance4SQ002 importance4SQ003 importance4SQ004						///

foreach var in `importance'{
rename `var' `var'string
gen `var'=.
forvalues i=1/5{
replace `var'=`i' if `var'string=="A`i'"
}
drop `var'string
}


gen impclimate=importanceSQ001 if RAND17==1
replace impclimate=importance2SQ004 if RAND17==2
replace impclimate=importance3SQ002 if RAND17==3
replace impclimate=importance4SQ003 if RAND17==4

gen impgender=importanceSQ002 if RAND17==1
replace impgender=importance2SQ003 if RAND17==2
replace impgender=importance3SQ004 if RAND17==3
replace impgender=importance4SQ001 if RAND17==4

gen imphealth=importanceSQ003 if RAND17==1
replace imphealth=importance2SQ002 if RAND17==2
replace imphealth=importance3SQ001 if RAND17==3
replace imphealth=importance4SQ004 if RAND17==4

gen impimmi=importanceSQ004 if RAND17==1
replace impimmi=importance2SQ001 if RAND17==2
replace impimmi=importance3SQ003 if RAND17==3
replace impimmi=importance4SQ002 if RAND17==4



// race
gen white = (demo2=="A1")
gen black = (demo2=="A2")
gen asian = (demo2=="A3")
gen otherrace= (demo2=="-oth-")

label var white "White/Caucasian"
label var black "Black/African American"
label var asian "Asian American"

label var otherrace "Other race"

// hispanic
gen hispanic = (demo3=="A1")
label var hispanic "Hispanic or latino origin"

// hh income
tab hhinc
gen hhinccont=.
replace hhinccont=6735 if hhinc==1
replace hhinccont=19742 if hhinc==2
replace hhinccont=36701 if hhinc==3
replace hhinccont=61275 if hhinc==4
replace hhinccont=86204 if hhinc==5
replace hhinccont=120686 if hhinc==6
replace hhinccont=170381 if hhinc==7
replace hhinccont=327261 if hhinc==8

gen loghhinc=log(hhinccont)

label var loghhinc "Log household income"
label var hhinccon "Household income"


*company size
rename companysize companysizestring

gen companysize=1 if companysizestring=="A1"
replace companysize=2 if companysizestring=="A2"
replace companysize=3 if companysizestring=="A3"
drop companysizestring


//hours worked per week
gen hours=.

forvalues i=1/12{
replace hours=`i' if hrsweek=="A`i'"
}


*education
rename demo1 education
gen educ=.

forvalues i=1/9{
replace educ=`i' if education=="A`i'"
}

label define edu 1 "8th degree" 2 "some HS" 3 "HS" 4 "some college" 5 "2-year college" 6 "4-year college" 7 "Master" 8 "Dr." 9 "Prof. Degree"
label values educ edu

gen bachelormore=(educ>5) if educ!=.
gen associatemore=(educ>4) if educ!=.
drop education

label var bachelormore "Bachelor's degree or more"
label var associatemore "2-year College degree +"


*civil status
rename maritalst married1
gen married=. 
replace married=1 if married1=="A1"
replace married=2 if married1=="A2"
replace married=3 if married1=="A3"
replace married=4 if married1=="A4"
drop married1

rename married civil

gen single = (civil==1) if civil!=.
label var single "Single"
gen married = (civil==2) if civil!=.
label var married "Married"
gen divorced = (civil==3) if civil!=.
label var divorced "Divorced"
gen widowed = (civil==4) if civil!=.
label var widowed "Widowed"

* children
rename childrenSQ001 boy
rename childrenSQ002 girl

foreach var in boy girl{
rename `var' `var'string
gen `var'=.
forvalues i=1/6{
replace `var'=`i' if `var'string=="A`i'"
}
drop `var'string
replace `var'=`var'-1
}

gen children=boy+girl
gen anychildren=(children>0&children!=.)
label var anychildren "Has children"

tab children


* birthyear
rename birthyear by
gen birthyear=.
replace birthyear=1951 if by=="A1"
replace birthyear=1952 if by=="A2"
replace birthyear=1953 if by=="A3"
replace birthyear=1954 if by=="A4"
replace birthyear=1955 if by=="A5"
replace birthyear=1956 if by=="A6"
replace birthyear=1957 if by=="A7"
replace birthyear=1958 if by=="A8"
replace birthyear=1959 if by=="A9"
replace birthyear=1960 if by=="A10"
replace birthyear=1961 if by=="A11"
replace birthyear=1962 if by=="A12"
replace birthyear=1963 if by=="A13"

gen birthyearhelp=.

forvalues i=1/37{
replace birthyearhelp=`i' if by=="`i'"
}

replace birthyear=birthyearhelp+1963 if birthyearhelp!=.

drop by

gen age_det=2018-birthyear
label var age_det "Age"

*fblikesettings

gen fbset=.
forvalues i=1/3{
replace fbset=`i' if fblikesettings=="A`i'"
}
drop fblikesettings

label define fbset 1 "visible" 2 "private" 3 "no facebook"
label values fbset fbset


//Have you read about the topic in the past 3 weeks?
rename read readcat
gen read=.
replace read=0 if readcat=="A2"
replace read=1 if readcat=="A1"
replace read=2 if readcat=="A3"

drop readcat

rename RAND rand



// own labor market income
replace labinc=4452 if labinc==4.452
replace labinc=7904 if labinc==7.904
replace labinc=9999 if labinc==9.999
replace labinc=19999 if labinc==19.999
replace labinc=20101 if labinc==20.101

winsor labinc, gen (labincome) p(0.005)


//generate dummies

// age
tab age, gen(age)

label var age1 "Age 18-24"
label var age2 "Age 25-34"
label var age3 "Age 35-44"
label var age4 "Age 45-54"
label var age5 "Age 55-65"

// hh inc
tab hhinc, gen (hhinc)

label var hhinc1 "Yearly household inc. < \textdollar 15,000" 
label var hhinc2 "Yearly household inc. \textdollar 15,000 - \textdollar 25,000" 
label var hhinc3 "Yearly household inc. \textdollar 25,000 - \textdollar 50,000" 
label var hhinc4 "Yearly household inc. \textdollar 50,000 - \textdollar 75,000" 
label var hhinc5 "Yearly household inc. \textdollar 75,000 - \textdollar 100,000" 
label var hhinc6 "Yearly household inc. \textdollar 100,000 - \textdollar 150,000" 
label var hhinc7 "Yearly household inc. \textdollar 150,000 - \textdollar 200,000" 
label var hhinc8 "Yearly household inc. > \textdollar 200,000" 

gen lowinc=hhinc1+hhinc2+hhinc3
gen highinc=hhinc4+hhinc5+hhinc6+hhinc7+hhinc8

label var lowinc "Household inc $\leq$ \textdollar 50,000" 
label var highinc "Household inc. > \textdollar 50,000"

gen wave=2

save "$path\data\SurveyStageIB_beforezscore.dta", replace





```

### `dofiles/06_SurveyStageIIAB_append_clean.do`
```stata


***********************************************************************************
// Replication Files
**********************************************************************************
/*
HOW DO BELIEFS ABOUT THE GENDER WAGE GAP AFFECT THE DEMAND FOR PUBLIC POLICY?
Sonja Settele
AEJ:pol
*/
**********************************************************************************

***********************************************************************************
**** Cleaning file Survey Waves A and B, Stage II (follow-up survey): 
***********************************************************************************

// Append Waves A and B: 

use "$path\data\SurveyStageII_WaveA_raw.dta", clear
append using "$path\data\SurveyStageII_WaveB_raw.dta"


// Prepare Data
// Demographics
* Age
rename ageII agecatII

gen ageII=1 if agecatII=="A1"		//18-24
replace ageII=2 if agecatII=="A2"	//25-34
replace ageII=3 if agecatII=="A3"	//35-54
replace ageII=4 if agecatII=="A4"	//55-70
replace ageII=5 if agecatII=="A5"	//71+

drop agecatII
tab ageII

* Gender
rename genderII gendercatII

gen genderII=0 if gendercatII=="A1"	//male
replace genderII=1 if gendercatII=="A2"	//female

drop gendercatII

* Employment
rename employmentII employmentcatII
tab employmentcatII

gen employmentII=1 if employmentcatII=="A1"		//working
replace employmentII=2 if employmentcatII=="A2"	//business owner
replace employmentII=3 if employmentcatII=="A3"	//oolf


// Outcome variables: Perceptions and policy demand
* (Order of subquestions was randomized in Wave B, not in Wave A)

* "Wage differences between high- and low-skilled are a problem"
gen problemskill=.

forvalues i=1/6{
replace problemskill=`i' if wave=="B"&wageproblemSQ001=="A`i'" & randorder2==1
replace problemskil=`i' if wave=="B"&wageproblem2SQ001=="A`i'" & randorder2==2
replace problemskill=`i' if wave=="A"&wageproblemSQ001=="A`i'" 
}

drop wageproblemSQ001 wageproblem2SQ001

* "Wage differences between men and women are a problem"
gen problemII=.

forvalues i=1/6{
replace problemII=`i' if wave=="B"&wageproblemSQ002=="A`i'" & randorder2==1
replace problemII=`i' if wave=="B"&wageproblem2SQ002=="A`i'" & randorder2==2
replace problemII=`i' if wave=="A"&wageproblemSQ002=="A`i'"
}

drop wageproblemSQ002 wageproblem2SQ002

* "Wage differences between high-skilled men and women are a problem"
gen problemIIHS=.

forvalues i=1/6{
replace problemIIHS=`i' if wave=="B"&wageproblemSQ003=="A`i'" & randorder2==1
replace problemIIHS=`i' if wave=="B"&wageproblem2SQ004=="A`i'" & randorder2==2
replace problemIIHS=`i' if wave=="A"&wageproblemSQ003=="A`i'"
}

drop wageproblemSQ003 wageproblem2SQ004


* "Wage differences between low-skilled men and women are a problem"

gen problemIILS=.

forvalues i=1/6{
replace problemIILS=`i' if wave=="B"&wageproblemSQ004=="A`i'" & randorder2==1
replace problemIILS=`i' if wave=="B"&wageproblem2SQ003=="A`i'" & randorder2==2
replace problemIILS=`i' if wave=="A"&wageproblemSQ004=="A`i'"
}

drop wageproblemSQ004 wageproblem2SQ003


* Specific policy demand (Wave B only)
foreach var in AAanchorII legislationanchorII{
rename `var' `var'string
gen `var'=.
forvalues i=1/5{
replace `var'=`i' if `var'string=="A`i'"
}
drop `var'string
}

* How fair are wages of low-skilled workers/ of women?
gen fairskill=.
gen fairII=.
forvalues i=1/5{
replace fairskill=`i' if fairnessSQ001=="A`i'"
replace fairII=`i' if fairnessSQ002=="A`i'"
}

tab fairskill if submitdateII!=""
tab fairII if submitdateII!=""
drop fairnessSQ001 fairnessSQ002

label define fair 1 "much less than fair" 2 "less than fair" 3 "fair" 4 "more than fair" 5 "much more than fair"
label values fairII fair


* Government should increase efforts to support low-skilled workers/women in the labor market
gen govmoreII=.
gen govmoreLS=.

forvalues i=1/7{
replace govmoreII=`i' if govwomen=="A`i'"
replace govmoreLS=`i' if govlowskilled=="A`i'"
}

drop govwomen govlowskilled


* Government should strengthen anti-disc policies/policies to help women combine work and family
gen antidiscII=. 
gen fampolII=.
forvalues i=1/5{
replace antidiscII=`i' if antidiscr=="A`i'"
replace fampolII=`i' if fampolicy=="A`i'"
}

drop antidiscr fampolicy


* Read and discuss about topic since last survey
rename readII readIIcat
gen readII = 1 if readIIcat == "A1"
replace readII=0 if readIIcat=="A2"|readIIcat=="A3"

rename discussII discussIIcat
gen discussII = 1 if discussIIcat=="A1"
replace discussII=0 if discussIIcat=="A2"|discussIIcat=="A3"

* Never taken survey on the topic before
gen firsttime=(readIIcat=="A4"&discussIIcat=="A4")
drop readIIcat discussIIcat


//z-score outcomes
local outcomesII AAanchorII legislationanchorII problemskill problemII problemIIHS problemIILS fairskill fairII govmoreII govmoreLS antidiscII fampolII readII discussII
foreach var in `outcomesII'{
egen mean_`var'=mean(`var') 
egen sd_`var'=sd(`var') 
replace `var'=(`var'-mean_`var')/sd_`var'
drop mean_`var' sd_`var'
}

// Survey wave
rename wave wavecat
gen wave=1 if wavecat=="A"
replace wave=2 if wavecat=="B"

//Treatment dummy T1 corresponding to T74
gen T1=(rand==1)


// Generate additional outcomes, such as summary indices

// z-scored version of posterior belief
egen zposteriorII=std(posteriorII)


// Build index for perceptions
gen dm_y1 = problemII
gen dm_y2 = govmoreII
gen dm_y3 = problemIIHS
gen dm_y4 = problemIILS


corr dm_y1 dm_y2 dm_y3 dm_y4 
 
matrix varcov_dmsimple = r(C)
matrix varcov_inv_dmsimple  = invsym(varcov_dmsimple)

	matrix list varcov_dmsimple
	matrix list varcov_inv_dmsimple

// Sum of row elements give us the weight
forvalues nvars = 1/4{										// Do this for n Indicators (rows)
	scalar weight_var`nvars' = 0							// Placeholder for the weight. Start at 0 
	local totrowscols = rowsof(varcov_inv_dmsimple) 		// Tell me the size of a symetric matrix
	// Loop for each column 
	forvalues n=1/`totrowscols' {									
		qui local ele`n' = varcov_inv_dmsimple[`nvars',`n'] 		// Get for each indicator (row) each column (element)
		qui scalar weight_var`nvars' = weight_var`nvars' + `ele`n''	// For each indicator (row) summ the elements. This is the weight
		}
scalar list weight_var`nvars' // Display weight
}

// Get SUM n=1 to n=N of (WEIGHT_n X INDICATOR_n) (In this case n=6 indicators)
 gen 	numerator =  (dm_y1 * weight_var1) 
// We loop to get the sum
forvalues h=2/4{
replace numerator = numerator + (dm_y`h' * weight_var`h') 
}

// The final step is to get the SUM of the weights
scalar denominator = 0
	forvalues nvars = 1/4{
	scalar denominator = denominator + weight_var`nvars' 
	}

gen z_maniII_index2 = numerator / denominator

label var z_maniII_index2 "Perception Index"

drop dm_y1 dm_y2 dm_y3 dm_y4  numerator


// Build index for demand for two newly elicited types of policies 
gen dm_y1 = antidiscII
gen dm_y2 = fampolII


corr dm_y1 dm_y2 
 
matrix varcov_dmsimple = r(C)
matrix varcov_inv_dmsimple  = invsym(varcov_dmsimple)

	matrix list varcov_dmsimple
	matrix list varcov_inv_dmsimple

// Sum of row elements give us the weight 
forvalues nvars = 1/2{										// Do this for n Indicators (rows)
	scalar weight_var`nvars' = 0							// Placeholder for the weight. Start at 0 
	local totrowscols = rowsof(varcov_inv_dmsimple) 		// Tell me the size of a symetric matrix, here 4
	// Loop for each column 
	forvalues n=1/`totrowscols' {									
		qui local ele`n' = varcov_inv_dmsimple[`nvars',`n'] 		// Get for each indicator (row) each column (element)
		qui scalar weight_var`nvars' = weight_var`nvars' + `ele`n''	// For each indicator (row) summ the elements. This is the weight
		}
scalar list weight_var`nvars' // Display weight
}

// Get SUM n=1 to n=N of (WEIGHT_n X INDICATOR_n) 
 gen 	numerator =  (dm_y1 * weight_var1) 
// We loop to get the sum
forvalues h=2/2{
replace numerator = numerator + (dm_y`h' * weight_var`h') 
}

// The final step is to get the SUM of the weights
scalar denominator = 0
	forvalues nvars = 1/2{
	scalar denominator = denominator + weight_var`nvars' 
	}

gen z_lmpolicyII_types_index = numerator / denominator

label var z_lmpolicyII_types_index "index (labor market policy types)"

drop dm_y1 dm_y2 numerator


// Build index for specific (re-elicited) policy demand 
gen dm_y1 = legislationanchorII
gen dm_y2 = AAanchorII


corr dm_y1 dm_y2 
 
matrix varcov_dmsimple = r(C)
matrix varcov_inv_dmsimple  = invsym(varcov_dmsimple)

	matrix list varcov_dmsimple
	matrix list varcov_inv_dmsimple

// Sum of row elements give us the weight 
forvalues nvars = 1/2{										// Do this for n Indicators (rows)
	scalar weight_var`nvars' = 0							// Placeholder for the weight. Start at 0 
	local totrowscols = rowsof(varcov_inv_dmsimple) 		// Tell me the size of a symetric matrix, here 4
	// Loop for each column 
	forvalues n=1/`totrowscols' {									
		qui local ele`n' = varcov_inv_dmsimple[`nvars',`n'] 		// Get for each indicator (row) each column (element)
		qui scalar weight_var`nvars' = weight_var`nvars' + `ele`n''	// For each indicator (row) summ the elements. This is the weight
		}
scalar list weight_var`nvars' // Display weight 
}

// Get SUM n=1 to n=N of (WEIGHT_n X INDICATOR_n) 
 gen 	numerator =  (dm_y1 * weight_var1) 
// We loop to get the sum
forvalues h=2/2{
replace numerator = numerator + (dm_y`h' * weight_var`h') 
}

// The final step is to get the SUM of the weights
scalar denominator = 0
	forvalues nvars = 1/2{
	scalar denominator = denominator + weight_var`nvars' 
	}

gen z_lmpolicyII_specific_index = numerator / denominator

label var z_lmpolicyII_specific_index "index (labor market policy types)"

drop dm_y1 dm_y2 numerator


save "$path\data\SurveyStageIIAB_final.dta", replace


*********************************************************************************
**  ** 	**	**	**	**	**	**	**	**	**	**	**	**	**	**	**	**	**	**	


exit


```

## How to run a script

Write each script to a file under the output directory, then run it with
exactly this command (the data directory is mounted read-only at its own
path; nothing else from the host is visible; `$SCRIPT` is the absolute path of
the script you wrote):

    SCRIPT=<repo>/benchmark/reproductions/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b/script.R   # or <repo>/benchmark/reproductions/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b/attempt-<n>/script.R
    uv run --directory <repo> python -m benchmark.reproducers.run_sandbox --timeout 300 --label retally.run=claude-code-settele-2022-gender-wage-gap-beliefs-policy-seeded-2026-11-10-b --run-dir "$(dirname "$SCRIPT")" -- docker run --rm --label retally.run=claude-code-settele-2022-gender-wage-gap-beliefs-policy-seeded-2026-11-10-b --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b/mount/settele_2022_gender_wage_gap_beliefs_policy:<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b/mount/settele_2022_gender_wage_gap_beliefs_policy:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R; echo "exit code: $?"

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

The output directory `<repo>/benchmark/reproductions/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b/
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

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b`.
