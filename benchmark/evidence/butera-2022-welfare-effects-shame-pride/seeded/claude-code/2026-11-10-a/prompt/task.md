# Retally reproduction task: butera-2022-welfare-effects-shame-pride (seeded, run 2026-11-10-a)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `butera-2022-welfare-effects-shame-pride`, mode `seeded`, run `2026-11-10-a`
- Paper: Measuring the Welfare Effects of Shame and Pride
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-a/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-a`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride` as data, and `<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-a/paper.txt` as
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

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-a --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Claims to Reproduce
1. public_recognition_points_prolific_table5_col1: 105.01 (points scored in the round) [type: coefficient]
   Location: Table 5, Public recognition, column (1) Prolific
   Context: Table 5 ("The effect of public recognition and financial incentives on performance in the charitable contribution experiments"), column (1). OLS of points scored in a round of the button-pressing task on indicators for the Publicly-Shared Effort Round (public recognition) and the round with performance-based pay for the participant (financial incentives), the Anonymous Effort Round being the omitted round, with dummies for the order in which the round appeared to the participant (first, second, third). One observation per participant and round. Sample: the Prolific experiment after the paper's…
2. financial_incentives_points_prolific_table5_col1: 185.74 (points scored in the round) [type: coefficient]
   Location: Table 5, Financial incentives, column (1) Prolific
   Context: Table 5, column (1): the same regression of points scored on the public recognition and financial incentive round indicators with round-order dummies in the Prolific sample; the entry is the financial incentives coefficient (Prolific incentive: two cents for every ten points, paid to the participant). Participant-clustered standard errors.
3. public_recognition_points_berkeley_table5_col2: 134.41 (points scored in the round) [type: coefficient]
   Location: Table 5, Public recognition, column (2) Berkeley
   Context: Table 5, column (2): the column (1) regression (points on the public recognition and financial incentive round indicators, round-order dummies) in the Berkeley experiment, after the attention-check and incoherent-preference exclusions. Participant-clustered standard errors. The entry is the public recognition coefficient.
4. financial_incentives_points_berkeley_table5_col2: 177.76 (points scored in the round) [type: coefficient]
   Location: Table 5, Financial incentives, column (2) Berkeley
   Context: Table 5, column (2), Berkeley sample: the financial incentives coefficient (incentive five cents for every ten points). Same regression, exclusions and participant-clustered standard errors.
5. public_recognition_points_bu_table5_col3: 103.61 (points scored in the round) [type: coefficient]
   Location: Table 5, Public recognition, column (3) BU
   Context: Table 5, column (3): the column (1) regression in the BU (Boston University classroom) experiment, after the attention-check and incoherent-preference exclusions. Participant-clustered standard errors. The entry is the public recognition coefficient.
6. financial_incentives_points_bu_table5_col3: 118.33 (points scored in the round) [type: coefficient]
   Location: Table 5, Financial incentives, column (3) BU
   Context: Table 5, column (3), BU sample: the financial incentives coefficient (incentive five cents for every ten points). Same regression, exclusions and participant-clustered standard errors.
7. n_obs_prolific_table5_col1: 2904.0 (participant-rounds) [type: count]
   Location: Table 5, Observations, column (1) Prolific
   Context: Number of observations in Table 5, column (1): participant-round observations (three rounds per participant) of the Prolific experiment's final sample.
8. n_obs_berkeley_table5_col2: 1152.0 (participant-rounds) [type: count]
   Location: Table 5, Observations, column (2) Berkeley
   Context: Number of observations in Table 5, column (2): participant-round observations of the Berkeley experiment's final sample.
9. n_obs_bu_table5_col3: 354.0 (participant-rounds) [type: count]
   Location: Table 5, Observations, column (3) BU
   Context: Number of observations in Table 5, column (3): participant-round observations of the BU experiment's final sample.
10. action_signaling_gamma1_berkeley_table7_panelA: 0.3 (WTP in dollars per hundred points (structural PRU, linear term)) [type: coefficient]
   Location: Table 7, panel (a) Action-signaling model parameter estimates, Berkeley, gamma_1^a
   Context: Table 7 ("Structural estimates and tests of consistency"), panel (a), Berkeley row, first column: the linear coefficient of the quadratic structural public recognition utility of the action-signaling model, gamma_1 (a - rho abar) + gamma_2 (a - rho abar)^2 (Section 7.1, equation 5), with effort a in hundreds of points. The structural parameters are functions of the reduced-form quadratic PRU r0 + r1 a + r2 a^2 estimated in Table 6, column (4) (OLS of stated WTP on the interval midpoint in hundreds of points and its square, the 1700+ interval excluded, Berkeley final sample), with the compariso…
11. action_signaling_rho_berkeley_table7_panelA: 0.87 (multiple of average performance (reference standard rho)) [type: coefficient]
   Location: Table 7, panel (a) Action-signaling model parameter estimates, Berkeley, rho^a
   Context: Table 7, panel (a), Berkeley row: the action-signaling model's reference-standard parameter rho (image payoffs turn from negative to positive at rho times average performance), recovered from the Table 6 column (4) reduced-form quadratic PRU and the average points (in hundreds) scored with public recognition in the Berkeley sample (anonymous-round mean plus the Table 5 column (2) public recognition effect). Full-sample point estimate; bootstrapped percentile confidence interval in the table.
12. cost_parameter_c_berkeley_table7_panelA: 0.21 (dollars per hundred points squared (effort cost curvature c)) [type: coefficient]
   Location: Table 7, panel (a) Action-signaling model parameter estimates, Berkeley, c
   Context: Table 7, panel (a), Berkeley row, last column: the cost-of-effort parameter c of the quadratic material utility theta a - c a^2 / 2, identified by equating the model's predicted effect of public recognition (equations 7-8, from the Table 6 column (4) reduced-form PRU) with the public recognition treatment effect estimated in Table 5, column (2), effort in hundreds of points. Full-sample point estimate; bootstrapped percentile confidence interval in the table.
13. predicted_financial_incentive_effect_berkeley_table7_panelC: 2.33 (hundreds of points) [type: other]
   Location: Table 7, panel (c) Predicted and actual effects of financial incentives, Berkeley, Model prediction
   Context: Table 7, panel (c), Berkeley row, "Model prediction": the structural model's predicted effect of the financial incentive on points scored (in hundreds of points), p / c, where p is the incentive of 5 cents for every ten points expressed per hundred points and c is the panel (a) cost parameter (Section 7.1, "Consistency with financial incentive effects"). Compared in the table with the directly estimated effect from Table 5. Full-sample point estimate; bootstrapped percentile confidence interval in the table.

## Dataset Information
Name: butera_2022_welfare_effects_shame_pride
Local path: <repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride
File format: csv
Files in the dataset directory (paths relative to the local path above):
- Packet/Analysis/Code/charity_model_selection.do (7.2 KB)
- Packet/Analysis/Code/charity_reduced_form_analysis.do (39.9 KB)
- Packet/Analysis/Code/ind_differences_analysis.do (5.0 KB)
- Packet/Analysis/Code/welfare_estimates.do (17.6 KB)
- Packet/Analysis/Code/ymca_impact_of_pr_on_attendance.do (3.6 KB)
- Packet/Analysis/Code/ymca_piped_values.do (15.0 KB)
- Packet/Analysis/Code/ymca_reduced_form_pr_function.do (26.9 KB)
- Packet/Analysis/Code/ymca_reduced_form_pr_function_figures.do (19.1 KB)
- Packet/Build/Gen_Vars.do (2.8 KB)
- Packet/Build/Label_Rounds.do (1.5 KB)
- Packet/Build/Prolific_Build.do (1.5 KB)
- Packet/Build/University_Build.do (1.6 KB)
- Packet/Build/build_charity_master.do (2.7 KB)
- Packet/Build/build_ymca_admin.do (2.9 KB)
- Packet/Build/build_ymca_survey.do (4.8 KB)
- Packet/QSF files and scripts/BU_QM221.qsf (1.1 MB)
- Packet/QSF files and scripts/BU_QM222.qsf (1.1 MB)
- Packet/QSF files and scripts/Berkeley.qsf (1.1 MB)
- Packet/QSF files and scripts/Experiment details appendix.pdf (2.8 MB)
- Packet/QSF files and scripts/Prolific.qsf (1.2 MB)
- Packet/QSF files and scripts/YMCA.qsf (232.9 KB)
- Packet/README.docx (33.4 KB)
- Packet/README.pdf (203.2 KB)
- Packet/Raw Data/berkeley_survey_data.csv (131.9 KB) — columns: id,attention_check,preference_0,preference_100,preference_200,preference_300,preference_400,preference_500,preference_600,preference_700,preference_800,preference_900,preference_1000,preference_1100,preference_1200,preference_1300,preferenc…
- Packet/Raw Data/bu_qm221_survey_data.csv (19.7 KB) — columns: id,attention_check,preference_0,preference_100,preference_200,preference_300,preference_400,preference_500,preference_600,preference_700,preference_800,preference_900,preference_1000,preference_1100,preference_1200,preference_1300,preferenc…
- Packet/Raw Data/bu_qm222_survey_data.csv (38.8 KB) — columns: id,attention_check,preference_0,preference_100,preference_200,preference_300,preference_400,preference_500,preference_600,preference_700,preference_800,preference_900,preference_1000,preference_1100,preference_1200,preference_1300,preferenc…
- Packet/Raw Data/prolific_survey_data.csv (343.1 KB) — columns: id,attention_check,preference_0,preference_100,preference_200,preference_300,preference_400,preference_500,preference_600,preference_700,preference_800,preference_900,preference_1000,preference_1100,preference_1200,preference_1300,preferenc…
- Packet/Raw Data/ymca_membership_data.csv (677.9 KB) — columns: ymca_id,survey_id,age,female,m2017_7,m2017_6,m2017_5,m2017_4,m2017_3,m2017_2,m2017_1,m2016_12,m2016_11,m2016_10,m2016_9,m2016_8,m2016_7,m2016_6,m2016_5
- Packet/Raw Data/ymca_scans.csv (20.5 MB) — columns: ymca_id,survey_id,USRDateTime
- Packet/Raw Data/ymca_survey_data.csv (62.9 KB) — columns: ymca_id,survey_id,q9,q10_1,q15,q16_1,q18_1,q35,q37,times_0_1,times_0_no_1,times_0_no_8,times_0_yes_1,times_0_yes_8,times_1_1,times_1_no_1,times_1_no_8,times_1_yes_1,times_1_yes_8,times_2_1,times_2_no_1,times_2_no_8,times_2_yes_1,times_2_yes…
- Packet/Raw Data/ymca_treatment_assignment.csv (5.6 KB) — columns: ymca_id,survey_id,treatment
- Packet/data dictionary.xlsx (28.8 KB)
- Packet/master_file.do (1.9 KB)
- metadata.json (240 B)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
Installed packages (no network; nothing else can be installed): jsonlite, fixest, lfe, AER, ivreg, plm, estimatr, lme4, quantreg, car, sandwich, lmtest, clubSandwich, multiwayvcov, marginaleffects, MatchIt, optmatch, CBPS, WeightIt, cobalt, did, rdrobust, rddensity, Synth, modelsummary, stargazer, texreg, broom, tidyverse, dplyr, tidyr, readr, stringr, lubridate, data.table, haven, readxl, janitor, zoo, ggplot2, ggridges, ggrepel, gridExtra, cowplot, gtable, extrafont, sf, MASS, nnet, survival, splines, Matrix, boot, stats, utils.
Prefer fixest for fixed effects, IV and clustered SEs; use the other installed packages where the paper's method calls for them.
Set a deterministic seed with ``set.seed(42)`` for any randomness.
Do NOT access the internet; the container runs with --network none.
Do NOT shell out via system() / system2().
Emit RESULT:<name>=<value> lines to stdout at the end via cat().

## Original Replication Scripts
The replication package (the dataset directory) ships the authors' own analysis scripts, reproduced below.  These are the GROUND TRUTH for the exact estimating equation, variable names, sample restrictions, fixed effects, and standard-error clustering — follow them over anything reconstructed from the methodology summary, and prefer them over the paper's text where the two disagree.  Your job is to write R code that implements the SAME SPECIFICATION: translate what the scripts estimate, do not transliterate their syntax line by line (a Stata .do file's regression, e.g. `reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the equivalent fixest::feols() call in R).  Keep only the parts that produce the specific claims being reproduced; skip figure construction and unrelated robustness checks.  The scripts' data-file paths refer to the package's internal layout — resolve them against the dataset directory listed under Dataset Information.

Stata-to-fixest sample matching: feols() drops fixed-effect singletons by default, but Stata's `reg y x i.fe` / `xi:` dummies keep them.  Pass `fixef.rm = "none"` to every feols() call that has fixed effects, otherwise the observation count and the robust SEs drift from the paper's.  Stata's `, r` / `vce(robust)` is `vcov = "hetero"`.

### `Packet/master_file.do`
```stata
/******************************************************************************

	Sets filepaths and runs all code

******************************************************************************/

clear matrix
clear mata
clear all
set more off

cd


* Replace rootdir with file location
if "`c(username)'" == "billy" {
	global rootdir "C:<home>/Dropbox/YMCAHabits/DataAnalysis/packet"
}


* The subfolders in the filepaths below need to exist for code to run. 
global analysisdir "$rootdir/Analysis/Code"
global builddir "$rootdir/Build"
global datadir "$rootdir/Prepped data"
global tempdir "$rootdir/temp"
global rawdir "$rootdir/Raw data"
global outputdir "$rootdir/Analysis/Output" 
global logdir "$rootdir/Analysis/Output" 


* Packages to install
 local ssc_packages "binscatter cdfplot estout"
    * *** Add required packages from SSC to this list ***

    if !missing("`ssc_packages'") {
        foreach pkg in "`ssc_packages'" {
        * install using ssc, but avoid re-installing if already present
            capture which `pkg'
            if _rc == 111 {                 
               dis "Installing `pkg'"
               quietly ssc install `pkg', replace
               }
        }
    }
 
 
* Next run build files
do "$builddir/build_ymca_admin.do" // must run before ymca_survey
do "$builddir/build_ymca_survey.do"
do "$builddir/build_charity_master.do"
 
* Next run analysis files
local randseed 12345
set seed `randseed' // change seed here

do "$analysisdir/charity_reduced_form_analysis.do" 
do "$analysisdir/charity_model_selection.do" 
do "$analysisdir/ymca_impact_of_pr_on_attendance.do" 
do "$analysisdir/ymca_piped_values.do" 
do "$analysisdir/ymca_reduced_form_pr_function.do" 
do "$analysisdir/ymca_reduced_form_pr_function_figures.do" 
do "$analysisdir/welfare_estimates.do" 
do "$analysisdir/ind_differences_analysis.do" // must run after welfare estimates


```

### `Packet/Build/build_charity_master.do`
```stata
/******************************************************************************

	Build_Master.do
	
	Clean data from all samples of the Real Effort Experiment and combine into
	a single dataset. Uses globals from SetGlobals.do.
	
******************************************************************************/
set more off

** Clean and save the data for each sample **
do "$builddir/University_Build"
do "$builddir/Prolific_Build"

** add bu221
use "$datadir/bu_qm221_cleaned_data", replace
replace sample = "qm221"

use "$datadir/prolific_cleaned_data", replace

** Combine the datasets **
foreach sample in berkeley bu_qm221 bu_qm222{
	append using "$datadir/`sample'_cleaned_data", force
	}
	
	
** Assign unique identifiers **
set seed 100
drop id
gen id = runiformint(1000000, 9999999)
la var id "ID"

** Order variables **
order sample id age gender race edu affiliation preference* *wtp*


** Label variables **
forval i = 0/17{
	loc j = `i'*100
	loc k = (`i'+1)*100
	la var preference_`j' "Pref. for PR, `j'-`k' pts"
	la var wtp`i' "WTP for PR, `j'-`k' pts, sliders"
	la var nwtp`i' "WTP for PR, `j'-`k' pts, hypothetical"
	
	if `i' == 17{
		la var preference_`j' "Pref. for PR, 1700+ pts"
		la var wtp`i' "WTP for PR, 1700+ pts, sliders"
		la var nwtp`i' "WTP for PR, 1700+ pts, hypothetical"
		}
	}
la var realized_wtp "WTP for PR, realized pts interval, sliders"
la var realized_nwtp "WTP for PR, realized pts interval, hypothetical"
la var clicked "Clicked to view past performance chart"
la var prolific_experience "# of Prolific studies completed"
la var badgegroupsize "Group assignment, size of group"
la var badgegroupshared "Group assignment, # shared"
la var recog_group_assign "Public recog. group assignment"
la var earnpts "Financial incentives round pts"
la var earndon "Financial incentives round donation"
la var earnown "Financial incentives round earnings"
la var anompts "Anonymous round pts"
la var anomdon "Anonymous round donation"
la var recogpts "Public recog. (PR) round pts"
la var recogdon "Public recog. (PR) round donation"
la var condition "Round order"
la var switch_preference "Times PR preference switched"
la var realized_interval "Realized pts interval"
la var countround "Round counted"
la var publicize "Public recog. outcome"
la var finalpoints "Points counted"
la var finaldonation "Donation counted"
la var finalearned "Earnings counted"
la var practicepts "Practice round pts"
la var earn_time "Financial incentive round time (sec.)"
la var anom_time "Anonymous round time (sec.)"
la var rec_time "Public recog. (PR) round time (sec.)"


** Save combined dataset **
save "$datadir/charity_cleaned_data", replace

```

### `Packet/Analysis/Code/charity_reduced_form_analysis.do`
```stata
/******************************************************************************
	
	Reduced-form analysis of data from the charitable contribution experiments.
	
	Creates Tables 5, 6, 8, and A10-16 as well as Figures 7-9, A8-A10
	
******************************************************************************/
set more off

** Load cleaned data **
use "$datadir/charity_cleaned_data", clear


** Create a program to write to a latex file **
cap rm "$outputdir/numbersfortext.tex" // remove old version
cap program drop latex_write
program define latex_write
	if "`c(os)'" == "MacOSX" local command \\newcommand{\\\`1'}{`2'}
	else local command \newcommand{\\`1'}{`2'}
	! echo `command'  >> "$outputdir/numbersfortext.tex"
end

* rename sample
replace sample = "QM" if sample == "BU QM221"

** Declare locals **
* Excluding those who failed the attention check
loc flag = "flag_attention_check == 0"

* Excluding those who failed the consistency criterion
loc excl "consistent_b == 1"

* List of samples
loc samples "Prolific Berkeley BU"


** Record & drop observations with disqualifying points **
gen high_pts = 0
foreach round in anom earn recog{
	replace high_pts = 1 if `round'pts > 3000
	}
foreach s in `samples'{

	* Number in full sample		
	sum id if sample == "`s'"
	loc obs : di %4.0f r(N)
	latex_write Nall`s' `obs'

	* Number dropped due to disqualifying points
	sum high_pts if sample == "`s'"
	loc obs : di %4.0f r(N)*r(mean)
	latex_write Nexclpts`s' `obs'
	
	}
drop if high_pts == 1

* idenify avg points in for > 1700 bin by sample
foreach s in `samples'{
	reg recogpts if sample == "`s'" & `flag' & `excl' & recogpts >= 1700, cluster(id)
	
	
	scalar topint`s' = 0.01* r(table)[1,1]
	loc topint`s'mean: di %4.1f r(table)[1,1]
	loc topint`s'se: di %4.1f r(table)[2,1]
	latex_write topint`s'mean `topint`s'mean'
	latex_write topint`s'se `topint`s'se'
}

* Identify average points for > 1700 bin (avg of samples):
encode sample, gen(s_no)

reg recogpts i.s_no if sample != "QM" & `flag' & `excl' & recogpts >= 1700, cluster(id)

lincom 1/3*(3*_cons + _b[2.s_no] + _b[3.s_no])
scalar topintavg = 0.01*r(estimate)
loc topintavgmean: di %4.1f r(estimate)
loc topintavgse: di %4.1f r(se)
latex_write topintavgmean `topintavgmean'
latex_write topintavgse `topintavgse'


** Generate & export summary statistics by sample **
gen female = gender == 2

foreach s in `samples'{
	
	* Number in analysis sample
	sum id if sample == "`s'" & `flag' & `excl'
	loc obs : di %4.0f r(N)
	latex_write Nsample`s' `obs'
	
	* Percent female
	sum female if sample == "`s'" & `flag' & `excl'
	loc pct : di %4.0f round(r(mean)*100)
	latex_write female`s' `pct'
	
	* Average age
	sum age if sample == "`s'" & `flag' & `excl'
	loc avg : di %4.0f round(r(mean))
	latex_write age`s' `avg'
	
	* Number scoring more than 1700 points in at least one round
	loc pct = 0
	foreach round in anom recog earn{
		gen `round'over1700`s' = `round'pts >= 1700 ///
			if sample == "`s'" & `flag' & `excl'
		sum `round'over1700`s'
		loc pct = `pct' + r(mean)
		drop `round'over1700`s'
		}
	loc pct : di %4.1f 100*`pct'/3
	latex_write highestint`s' `pct'
	
	* Percent failing consistency criterion of choice
	sum consistent_b if sample == "`s'" & `flag'
	loc pct : di %4.0f round((1-r(mean))*100)
	latex_write failb`s' `pct'
	
	* Number failing consistency criterion of choice
	loc N : di %4.0f (1-r(mean))*r(N)
	latex_write Nfailb`s' `N'
	
	* Percent failing stricter consistency criterion
	sum consistent if sample == "`s'" & `flag'
	loc pct : di %4.0f round((1-r(mean))*100)
	latex_write faila`s' `pct'
	
	* Likelihood of failing stricter criterion given passed looser one
	sum consistent if sample == "`s'" & `flag' & `excl'
	loc pct : di %4.1f (1-r(mean))*100
	latex_write failaifb`s' `pct'
	
	* Percent of WTPs censored (either above or below)
	* Reshape data
	preserve
	reshape long wtp nwtp, i(id) j(interval)
	
	* Declare local for slider WTP limit
	if "`s'" == "Prolific" loc L = 10
	else loc L = 25

	* Generate variable for stated WTPs above upper limit or below lower limit
	gen cens_wtp_`s' = ((wtp == `L' & nwtp > `L') | ///
		(wtp == -`L' & nwtp < -`L')) if sample == "`s'" & `flag' & `excl'

	* Summarize percentage
	sum cens_wtp_`s'
	loc pct : di %4.0f round(r(mean)*100)
	latex_write censwtp`s' `pct'
	
	* Generate variable for stated WTPs equal to or beyond limits
	gen weak_cens_wtp_`s' = ((wtp == `L' & nwtp >= `L') | ///
		(wtp == -`L' & nwtp <= -`L')) if sample == "`s'" & `flag' & `excl'

	* Summarize percentage
	sum weak_cens_wtp_`s'
	loc pct : di %4.0f round(r(mean)*100)
	latex_write weakcenswtp`s' `pct'
	
	restore
	
	
	* Number failing attention check
	sum flag_attention_check if sample == "`s'"
	loc num : di %4.0f r(mean)*r(N)
	latex_write failcheck`s' `num'
	
	* Average pairwise correlation between round points
	* Generate correlations
	loc k = 1
	foreach r1 in anom recog earn{
		foreach r2 in anom recog earn{
			if "`r1'" != "`r2'"{
				pwcorr `r1'pts `r2'pts if sample == "`s'" & `flag' & `excl'
				loc cor`k' = r(rho)
				loc cor : di %4.3f `r(rho)'
				latex_write corr`r1'`r2'`s' `cor'
				loc ++k
				}
			}
		}
		
	* Average the correlations
	loc avg_corr : di %4.3f (`cor1' + `cor2' + `cor3' + `cor4' + `cor5' ///
		+ `cor6')/6
	latex_write corr`s' `avg_corr'
	
	}

* Percent of each affiliation in the Berkeley sample
gen undergrad = affiliation == 1
gen grad = affiliation == 6 | affiliation == 7
gen other = affiliation == 8
gen blank = affiliation == 9
foreach aff in undergrad grad other blank{
	sum `aff' if sample == "Berkeley" & `flag' & `excl'
	loc pct : di %4.0f round(r(mean)*100)
	latex_write `aff'Berkeley `pct'
	}
	
* For the Prolific sample
* Generate group size variables
levelsof badgegroupsize, local(sizes)
bys recog_group_assign: egen recog_group_size = count(recog_group_assign) ///
	if `flag' & `excl'

foreach size of local sizes{
	gen group`size' = (badgegroupsize == `size') if !missing(badgegroupsize)
	
	* Declare local for naming
	if `size' == 15 loc name "ft"
	else if `size' == 75 loc name "sf"
	else loc name "th"
	
	* Number of groups of each size
	sum group`size'
	loc num : di %4.0f round((r(mean)*r(N))/`size')
	di `num'
	latex_write group`name'Prolific `num'
	
	* Group size ranges
	sum recog_group_size if badgegroupsize == `size' & recog_group_size != 0
	loc lbsize : di %4.0f r(min)
	latex_write group`name'ProlificLB `lbsize'
	loc ubsize : di %4.0f r(max)
	latex_write group`name'ProlificUB `ubsize'
	
	}

* Mean, median, and IQR of past Prolific tasks completed
sum prolific_experience if sample == "Prolific" & `flag' & `excl', d
loc avg : di %4.0f round(r(mean))
latex_write tasksmeanProlific `avg'
loc med : di %4.0f r(p50)
latex_write tasksmedianProlific `med'
loc iqr : di %4.0f r(p75) - r(p25)
latex_write tasksiqrProlific `iqr'

* Number of groups in Berkeley sample
gen sampleBerkeley = sample == "Berkeley"
sum sampleBerkeley
loc num : di %4.0f round((r(mean)*r(N))/75)
latex_write groupBerkeley `num'

* Berkeley group sizes *
sum recog_group_size if sample == "Berkeley" & recog_group_size != 0
loc lbsize : di %4.0f r(min)
latex_write groupBerkeleyLB `lbsize'
loc ubsize : di %4.0f r(max)
latex_write groupBerkeleyUB `ubsize'
	
* Generate variable for constant WTP across all intervals
gen const_wtp = 1
forval i = 1/17{
	loc j = `i' - 1
	replace const_wtp = 0 if wtp`i' != wtp`j'
	}
	
* Generate variable for constant WTP of 0
gen const_wtp_zero = (const_wtp == 1 & wtp0 == 0)

* Summarize variable for full sample & subsamples
sum const_wtp_zero if `flag' & `excl'
loc pct : di %4.0f round(100*(1-`r(mean)'))
latex_write nonconszerowtpall `pct'
foreach s in `samples'{
	sum const_wtp_zero if sample == "`s'" & `flag' & `excl'
	loc pct : di %4.0f round(100*(1-`r(mean)'))
	latex_write nonconszerowtp`s' `pct'
	}
	
* Summarize percent increase in donations from recognition treatment
foreach s in `samples'{
	sum recogpts if sample == "`s'" & `flag' & `excl'
	loc totalrecogpts = r(N)*r(mean)
	sum anompts if sample == "`s'" & `flag' & `excl'
	loc totalanompts = r(N)*r(mean)
	loc pct : di %4.0f round(100*(`totalrecogpts'-`totalanompts')/`totalanompts')
	latex_write donincpct`s' `pct'
	}


** Reshape data & generate variables for round points analysis **
* Generate differences of points scored between rounds
gen recog_anom_diff = recogpts - anompts
gen earn_anom_diff = earnpts - anompts
gen earn_recog_diff = earnpts - recogpts

* Generate median breaks & average points std deviation
foreach s in `samples' QM {
		
	* Generate indicator for above median anonymous round score
	sum anompts if sample == "`s'" & `flag' & `excl', d
	loc med = r(p50)
	gen abovemed_`s' = (anompts >= `med') if sample == "`s'" & `flag' & `excl'
	
	* Generate indicator for above median SR-anonymous round score difference
	sum recog_anom_diff if sample == "`s'" & `flag' & `excl', d
	loc med = r(p50)
	gen abovemeddiff_`s' = (recog_anom_diff >= `med') ///
		if sample == "`s'" & `flag' & `excl'
	
	* Generate average points variable
	gen avg_pts_`s' = (recogpts + anompts + earnpts)/3 ///
		if sample == "`s'" & `flag' & `excl'
		
	* Store & export standard deviation of average round points
	loc sd_sum = 0
	foreach diff in recog_anom_diff earn_anom_diff earn_recog_diff{
		sum `diff' if sample == "`s'" & `flag' & `excl'
		loc sd_sum = `sd_sum' + r(sd)
		}
	loc diffsd_`s' = `sd_sum'/3
	loc ptsdiff : di %4.1f `diffsd_`s''
	latex_write diffptssd`s' `ptsdiff'
	
	* Store standard deviations of points (00s) in the anonymous round
	if "`s'" == "Prolific" gen anompts_h = anompts/100 // 1st loop only
	sum anompts_h if sample == "`s'" & `flag' & `excl'
	loc anomsd_`s' = `r(sd)'
	loc anommean_`s' = `r(mean)'
		
	}
	
	
** Create demand curves
* Create var to identify relevant sample
gen main_sample = (flag_attention_check == 0)*(consistent_b == 1)

* Create a list of prices -$10, -$9.75,..., $10 **
gen price_prol = -10+0.25*(_n-1) if _n <= 81

* Create a list of prices -$25, -$24.75,..., $25 **
gen price_buucb = -25+0.5*(_n-1) if _n <= 101

* Create counts of each sample after restrictions
foreach s in `samples' {
	count if main_sample == 1 & sample == "`s'"
	scalar N`s' = r(N)
}

* To make life easier for the iterated loop 
gen preference_000 = preference_0

foreach s in `samples' {
	forval int = 0(2)16 {
		local int2 = `int'+1
		gen demand`int'`int2'_`s' = .
		
		* set price range locals
		if "`s'" == "Prolific" {
			local price price_prol
			local p_int = 0.25
			local p_min = -10
			local p_max = 10
			local p_u_neg = 0 - `p_int'
			local p_l_pos = 0+`p_int'
			local p_u_pos = -1*`p_min'
			local p_graph_int = 2
		}
		
		if "`s'" == "BU" | "`s'" == "Berkeley" {
			local price price_buucb
			local p_int = 0.5
			local p_min = -25
			local p_max = 25
			local p_u_neg = 0 - `p_int'
			local p_l_pos = 0+`p_int'
			local p_u_pos = -1*`p_min'
			local p_graph_int = 5
		}
		
		* For negative prices: use WTP > p preference == yes
		forval p = `p_min'(`p_int')`p_u_neg' {
			qui count if main_sample == 1 & sample == "`s'" & wtp`int' > `p'
			scalar temp = r(N)
			
			qui count if main_sample == 1 & sample == "`s'" & wtp`int2' > `p'
			replace demand`int'`int2'_`s' = (temp+r(N))/(2*N`s') if `price' == `p'
			
		}

		* zero price: WTP >= p and preference == yes
		qui count if main_sample == 1 & sample == "`s'" & wtp`int' >= 0 & preference_`int'00 == 1
		scalar temp = r(N)
			
		qui count if main_sample == 1 & sample == "`s'" & wtp`int2' >= 0 & preference_`int2'00 == 1
		replace demand`int'`int2'_`s' = (temp+r(N))/(2*N`s') if `price' == 0
			
		* positive price: WTP >= p
		forval p = `p_l_pos'(`p_int')`p_u_pos' {
			qui count if main_sample == 1 & sample == "`s'" & wtp`int' >= `p'
			scalar temp = r(N)
			
			qui count if main_sample == 1 & sample == "`s'" & wtp`int2' >= `p'
			replace demand`int'`int2'_`s' = (temp+r(N))/(2*N`s') if `price' == `p'
			
		}								
	}

	* create graphs			
	twoway (line `price' demand01_`s' if `price' <= `p_max', lc(gs12) lpattern(dash) msymbol(none) ) ///
		(line `price' demand23_`s' if `price' <= `p_max', lc(gs11) lpattern(dash) msymbol(none) ) ///
		(line `price' demand45_`s' if `price' <= `p_max', lc(gs10) lpattern(dash) msymbol(none) ) ///
		(line `price' demand67_`s' if `price' <= `p_max', lc(gs8) lpattern(dash) msymbol(none) ) ///
		(line `price' demand89_`s' if `price' <= `p_max', lc(gs7) lpattern(dash) msymbol(none) ) ///
		(line `price' demand1011_`s' if `price' <= `p_max', lc(gs6) lpattern(dot) msymbol(none) ) ///
		(line `price' demand1213_`s' if `price' <= `p_max', lc(gs5) lpattern(dash) msymbol(none) ) ///
		(line `price' demand1415_`s' if `price' <= `p_max', lc(gs3) lpattern(longdash) msymbol(none) ) ///
		(line `price' demand1617_`s' if `price' <= `p_max', lc(gs0) lpattern(solid) msymbol(none) ) ///
		(scatteri 0 0.2 (6) "0.2" 0 0.4 (6) "0.4" 0 0.6 (6) "0.6" 0 0.8 (6) "0.8" 0 1 (6) "1", /// 
	 ms(|) mlc(black) mlabsize(vsmall) mlabpos(6) mlabcolor(black) msize(*1.5)), ///
			graphregion(fcolor(white) lcolor(white) margin(3 15 1 3)) ///
			plotregion(fcolor(white) lcolor(white) margin(b = 0 r = 3) ) ///
			xtitle("Fraction demanding public recognition", size(small)) ///
			ytitle("Price " "($) ", orientation(horizontal) placement(n) size(small)) ///
			ylabel(`p_min'(`p_graph_int')`p_max', angle(0) nogrid labsize(vsmall)) ///
			yline(0, lp(solid) lc(black) lwidth(thin) ) ///
			yscale(range(`p_min' `p_max')) ///
			xscale(range(0 1) off) ///
			text(0 1.1 "Fraction" "demanding" "public" "recognition", size(small)) /// 
			legend (order(1 "0-199 pts" 2 "200-399 pts" 3 "400-599 pts" 4 "600-799 pts" ///
					5 "800-999 pts" 6 "1000-1199 pts" 7 "1200-1399 pts" 8 "1400-1599 pts" ///
					9 "{&ge} 1600 points") size(vsmall) symxsize(6) rows(2)) ///
			
	graph export "$outputdir/demandcurves_`s'_all.pdf", replace
}

drop main_sample

preserve
* Rename variables
foreach round in anom recog earn{
	rename `round'pts pts`round'
	}

* Reshape data
reshape long pts, i(id) j(round) string

* Generate indicators for round
gen SR = (round == "recog")
gen ownpay = (round == "earn")

* Add variable for order in which round appeared
do "$builddir/Label_Rounds.do"

* Generate indicators for round order
tab order, gen(o)

	
** Generate CDFs of points scored in each round **
foreach s in `samples'{

	cdfplot pts if sample == "`s'" & `flag' & `excl', by(round) ///
		opt1(lp(dash longdash solid) lc(gs10 navy maroon) ///
		graphregion(color(white))) ///
		xtitle("Points", height(6)) ///
		ytitle("") ylabel(,angle(0)) ylab(0(.2)1) ///
		legend(order(1 3 2) label(1 "Anonymous") label(2 "Financial incentives") label(3 "Public recognition"))
	graph export "$outputdir/cdf_`s'.pdf", replace

	}


** Regressions of points scored on round conditions **
foreach restrict in "" "& o1 == 1"  {

	eststo clear
	foreach s in `samples' QM {

		* Run regression for each sample
		reg pts SR ownpay o1 o2 if sample == "`s'" & `flag' & `excl' ///
			`restrict', clus(id)
		eststo spec_`s'
		if "`restrict'" != "& o1 == 1" estadd loc oe "Yes"
		estadd loc sname "`s'"
		
		loc change_att = _b[SR]
		
		if "`restrict'" == ""{
			* Test for joint significance of order effects
			test (o1 = 0) (o2 = 0)
			local p : di %4.3f r(p)
			estadd local pval `p'
			
			* Export & store coefficients
			loc SRptseffect`s' = _b[SR]
			loc b : di %3.0f `SRptseffect`s''
			latex_write SRptseffect`s' `b'
			
			loc FIptseffect`s' = _b[ownpay]
			loc b : di %3.0f `FIptseffect`s''
			latex_write FIptseffect`s' `b'
			
			}
			
		* Add control mean & standard error
		ci means pts if round == "anom" & e(sample) 
		loc m : di %4.1f r(mean)
		estadd local cmean `m'
		loc se : di %4.1f r(se)
		estadd local cse "(`se')"
		
		* Output percent change in attendance
		if "`restrict'" == ""{
			loc changeatt`s': di %4.2f 100*`change_att'/`m'
			latex_write changeatt`s' `changeatt`s''
			
			loc anompts`s': di %4.0f `m'
			latex_write anompts`s' `anompts`s''
		}
		
		* Run regression with group size interactions for Prolific sample
		if "`s'" == "Prolific" & "`restrict'" == ""{
			reg pts SR ownpay o1 o2 group300 group15 ///
				c.SR#c.group300 c.SR#c.group15 ///
				c.ownpay#c.group300 c.ownpay#c.group15 ///
				if sample == "`s'" & `flag' & `excl' `restrict', clus(id)
			eststo specgroup
			estadd loc oe "Yes"
			estadd loc sname "`s'"
			
			* Test for joint significance of order effects
			test (o1 = 0) (o2 = 0)
			local p : di %4.3f r(p)
			estadd local pval `p'
			
			}
		}
	
	* Declare locals for output
	if "`restrict'" == ""{
		loc name ""
		loc stats `"cmean cse oe pval sname N N_clust, l("Control mean" " " "\hline Round order dummies" "Order dummies F-test" "\hline Sample" "Observations" "N. Subjects") fmt(%8.0f %8.0f %8.0f %8.0f %8.0f)"'
		loc stats_qm `"cmean cse N N_clust, l("Control mean" " " "\hline Observations" "N. Subjects") fmt(%8.0f %8.0f %8.0f %8.0f %8.0f)"'
		}
	else {
		loc name "_first_round"
		loc stats `"cmean cse sname N, l("Control mean" " " "\hline Sample" "N. Subjects") fmt(%8.0f %8.0f)"'
		}
		
	* Export regression output
	if "`restrict'" == "" {
		esttab spec_Prolific spec_Berkeley spec_BU specgroup ///
			using "$outputdir/pts`name'.tex", ///
			nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{l*{@M}{c}}" "\hline") ///
			prefoot("\hline") postfoot("\hline" "\end{tabular}") ///
			mlabels(none) nonumbers posthead("& (1) & (2) & (3) & (4) \\ " "Model & OLS & OLS & OLS & OLS \\" "Dependent var. & Points & Points & Points & Points \\ \hline") ///
			replace se nonote nonumbers star(* 0.10 ** 0.05 *** 0.01) drop(o1 o2 _cons) ///
			order(SR ownpay group300 c.SR#c.group300 c.ownpay#c.group300 group15 c.SR#c.group15 c.ownpay#c.group15) ///
			varlabels(SR "Public recognition" ownpay "Financial incentives" group300 "Group of 300" group15 "Group of 15" c.SR#c.group300 "Group of 300 $\times$ Public recognition" c.SR#c.group15 "Group of 15 $\times$ Public recognition" c.ownpay#c.group300 "Group of 300 $\times$ Financial incentives" c.ownpay#c.group15 "Group of 15 $\times$ Financial incentives") ///
			b(%8.2f) se(%8.2f) stats(`stats')
		
		
			
		esttab spec_QM ///
			using "$outputdir/pts_qm221.tex", ///
			nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{l*{@M}{c}}" "\hline") ///
			prefoot("\hline") postfoot("\hline" "\end{tabular}") ///
			mlabels(none) nonumbers posthead("& (1) \\ " "Model & OLS \\" "Dependent var. & Points  \\ \hline") ///
			replace se nonote nonumbers star(* 0.10 ** 0.05 *** 0.01) drop(o1 o2 _cons) ///
			order(SR ownpay) varlabels(SR "Public recognition" ownpay "Financial incentives") ///
			b(%8.2f) se(%8.2f) stats(`stats_qm')
	}
	
	else esttab spec_Prolific spec_Berkeley spec_BU using "$outputdir/pts`name'.tex", ///
			nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{l*{@M}{c}}" "\hline") ///
			prefoot("\hline") postfoot("\hline" "\end{tabular}") ///
			mlabels(none) nonumbers posthead("& (1) & (2) & (3) \\" "Model & OLS & OLS & OLS \\" "Dependent var. & Points & Points & Points \\ \hline") ///
			replace se nonote nonumbers star(* 0.10 ** 0.05 *** 0.01) drop(o1 o2 _cons) ///
			varlabels(SR "Public recognition" ownpay "Financial incentives") ///
			order(SR ownpay _cons) b(%8.2f) se(%8.2f) stats(`stats')
	
}

restore



** Generate summary statistics of scores in the social recognition round **
foreach s in `samples' QM {

	sum recogpts if sample == "`s'" & `flag' & `excl', d
	loc srptsmean`s' : di %4.1f r(mean)
	latex_write srptsmean`s' `srptsmean`s''
	
	forval i = 25(25)75{
	
		if `i' == 25 loc name "tfive"
		else if `i' == 50 local name "fifty"
		else loc name "sfive"
	
		loc srptsp`i'`s' : di %4.1f r(p`i')
		latex_write srptsp`name'`s' `srptsp`i'`s''
		}
	}


** Reshape data & generate variables for WTP analysis **
reshape long wtp nwtp, i(id) j(interval)

* Generate indicator for 1700+ points interval
gen interval_17 = (interval == 17)

* Generate ingredients for indicator of avg round points "close" to midpoint
gen interval_midpoint = (interval + .5)*100
gen close = .
	
* Generate placeholder variables
foreach interactor in above_median above_median_D{
	gen interval_`interactor' = .
	gen interval_sq_`interactor' = .
	}

gen interval_top_avg = interval
 	
* Generate interactions with Prolific group size indicators
foreach interactor in group300 group15{
	gen interval_`interactor' = `interactor'*interval
	gen interval_sq_`interactor' = `interactor'*(interval^2)
	}
	
	
** Generate graphs of the average WTP in each points interval **
foreach s in `samples'{

	* Regression of WTP on points interval
	reg wtp ibn.interval if sample == "`s'" & `flag' & `excl', ///
		nocons cluster(id)

	* Store output
	matrix temp = r(table)'
	matrix temp_b = temp[1...,1]
	matrix temp_lb = temp[1...,5]
	matrix temp_ub = temp[1...,6]

	svmat double temp_b, name(wtp_avg_`s'_all)
	svmat double temp_lb, name(wtp_lb_`s'_all)
	svmat double temp_ub, name(wtp_ub_`s'_all)
	
	* For above vs. below median
	foreach group in am bm{
	
		if "`group'" == "am" loc restrict "abovemed_`s' == 1"
		else loc restrict "abovemed_`s' == 0"
		
		* Regression of WTP on points interval
		reg wtp ibn.interval if sample == "`s'" & `flag' & `excl' ///
			& `restrict', nocons cluster(id)

		* Store output
		matrix temp = r(table)'
		matrix temp_b = temp[1...,1]
		matrix temp_lb = temp[1...,5]
		matrix temp_ub = temp[1...,6]

		svmat double temp_b, name(wtp_avg_`s'_`group')
		svmat double temp_lb, name(wtp_lb_`s'_`group')
		svmat double temp_ub, name(wtp_ub_`s'_`group')
		
		}
	
	* Transform interval variable
	replace interval = (interval + .5)*100
	replace interval_top_avg = interval
	
	* Declare local for formatting
	if "`s'" == "Prolific" loc ylab "-1.5(.5)1.5"
	else loc ylab "-6(2)4"
	
	* find average points of last bin
	replace interval_top_avg = round(`topintavgmean',0) if interval_top_avg == 1750
	loc topinta = round(`topintavgmean',0)
		
	* Create chart with CIs & quadratic fit
	twoway (scatter wtp_avg_`s'_all interval, mcolor(navy) m(circle)) ///
		(rcap wtp_lb_`s'_all wtp_ub_`s'_all interval, lpattern(dash) lcolor(navy) lwidth(thin)) ///
		(qfit wtp_avg_`s'_all interval, lcolor(maroon)), ///
		graphregion(fcolor(white) lcolor(white)) legend(off) ///
		xtitle("Points", height(6)) ylabel(`ylab',angle(0)) ///
		xlab(0 "0" 300 "300" 600 "600" 900 "900" 1200 "1200" 1500 "1500" 1750 "{&ge}1700", labgap(*1.5)) ///
		yline(0, lpattern(dash) lwidth(thick) lcolor(gs11)) ///
		ytitle("WTP ($)", orientation(horizontal) placement(n)) ///
		xline(`srptsmean`s'', extend lwidth(thin) lcolor(red) lpattern(longdash))
		graph export "$outputdir/wtps_ci_qfit_`s'.pdf", replace
			
	* Create chart with above and below median comparison
	twoway (scatter wtp_avg_`s'_all interval, mcolor(navy) m(circle)) ///
		(scatter wtp_avg_`s'_am interval, mcolor(maroon)  msymbol(+)) ///
		(scatter wtp_avg_`s'_bm interval, mcolor(dkgreen*.8) m(X)), ///
		graphregion(fcolor(white) lcolor(white)) ylabel(`ylab',angle(0)) ///
		yline(0, lpattern(dash) lwidth(thick) lcolor(gs11)) ///
		xtitle("Points", height(6)) ///
		xlab(0 "0" 300 "300" 600 "600" 900 "900" 1200 "1200" 1500 "1500" 1750 "{&ge}1700", labgap(*1.5)) ///
		ytitle("WTP ($)", orientation(horizontal) placement(n)) ///
		xline(`srptsmean`s'', extend lwidth(thin) lcolor(red) lpattern(longdash)) ///
		legend(label(1 "Full sample") label(2 "Above median anon. score") label(3 "Below median anon. score"))
	graph export "$outputdir/wtps_split_`s'.pdf", replace
	
	
	* Create chart with moved top bin
	twoway (scatter wtp_avg_`s'_all interval_top_avg, mcolor(navy) m(circle)) ///
		(scatter wtp_avg_`s'_am interval_top_avg, mcolor(maroon)  msymbol(+)) ///
		(scatter wtp_avg_`s'_bm interval_top_avg, mcolor(dkgreen*.8) m(X)), ///
		graphregion(fcolor(white) lcolor(white)) ylabel(`ylab',angle(0)) ///
		yline(0, lpattern(dash) lwidth(thick) lcolor(gs11)) ///
		xtitle("Points", height(6)) ///
		xlab(0 "0" 300 "300" 600 "600" 900 "900" 1200 "1200" 1500 "1500" `topinta' "{&ge}1700", labgap(*1.5)) ///
		ytitle("WTP ($)", orientation(horizontal) placement(n)) ///
		xline(`srptsmean`s'', extend lwidth(thin) lcolor(red) lpattern(longdash)) ///
		legend(label(1 "Full sample") label(2 "Above median anon. score") label(3 "Below median anon. score"))
	graph export "$outputdir/wtps_split_topintavg`s'.pdf", replace
	
	* Revert interval variable
	replace interval_top_avg = 1750 if interval_top_avg > 1700
	replace interval = interval/100 - .5
	
	}

	
** Define programs to generate curvature confidence intervals **
capture program drop get_ci
program define get_ci, rclass

	nlcom -2*_b[c.interval#c.interval]/(_b[interval]+2*_b[c.interval#c.interval]*`2') // measure of curvature
	
	matrix tempb = r(b)
	matrix tempv = r(V)
	loc x : di %4.3f tempb[1,1]
	loc lb : di %4.3f tempb[1,1] - (invnormal(.975)*(sqrt(tempv[1,1])))
	loc ub : di %4.3f tempb[1,1] + (invnormal(.975)*(sqrt(tempv[1,1])))
	
	return loc alpha "`x'"
	return loc ci : di "[`lb', `ub']"
	
	* Multiply estimate by SD of points in the anonymous round
	nlcom -2*`1'*_b[c.interval#c.interval]/_b[interval]
	
	matrix tempb = r(b)
	matrix tempv = r(V)
	loc x : di %4.3f tempb[1,1]
	loc lb : di %4.3f tempb[1,1] - (invnormal(.975)*(sqrt(tempv[1,1])))
	loc ub : di %4.3f tempb[1,1] + (invnormal(.975)*(sqrt(tempv[1,1])))
	
	return loc alpha2 "`x'"
	return loc ci2 : di "[`lb', `ub']"
	
end	



** Run regressions of WTP on points intervals **
* Transform interval variable
replace interval = interval + .5

* Run regression
foreach s in `samples' QM {

	* Linear in points interval
	reg wtp interval if sample == "`s'" & `flag' & `excl' ///
		& interval < 17, clus(id)
	eststo l_`s'
	estadd loc sname "`s'"
	estadd loc alpha "--"
	estadd loc c_int "--"
	estadd loc alpha2 "--"
	estadd loc c_int2 "--"
	
	* Export & store coefficients
	loc SRequiv`s' = _b[interval]*10
	loc b : di %3.2f `SRequiv`s''
	latex_write SRequiv`s' `b'
	
	* Export estimates for financial incentive effect
	if "`s'" == "Prolific" loc rate = 2
	else loc rate = 5
	loc FIesteffect`s' = round(`SRptseffect`s'',1)*(`rate'/round(`SRequiv`s'',.01))
	loc b : di %3.0f `FIesteffect`s''
	latex_write FIesteffect`s' `b'
	
	* Quadratic in points interval
	reg wtp c.interval##c.interval if sample == "`s'" & `flag' & `excl' ///
		& interval < 17, clus(id)
	eststo sq_`s'
	estadd loc sname "`s'"
	qui get_ci `anomsd_`s'' `anommean_`s''
	estadd loc alpha "`r(alpha)'"
	estadd loc c_int "`r(ci)'"
	estadd loc alpha2 "`r(alpha2)'"
	estadd loc c_int2 "`r(ci2)'"
	
	* Temporarily rename above median indicator
	ren abovemed_`s' above_median
	
	* Temporarily rename above median difference indicator
	ren abovemeddiff_`s' above_median_D
	
	/* Define close variable as average round points within the average 
	   sd of points differences between rounds of interval midpoint */
	replace close = (avg_pts_`s' <= interval_midpoint + 500) & ///
		(avg_pts_`s' >= interval_midpoint - 500)
	
	* Fill in interactions
	foreach interactor in above_median above_median_D{
		replace interval_`interactor' = `interactor'*interval
		replace interval_sq_`interactor' = `interactor'*(interval^2)
		}
		
		
	* Restriction by "close" indicator, linear in points interval
	reg wtp interval if sample == "`s'" & `flag' & `excl' ///
		& interval < 17 & close == 1, clus(id)
	eststo close_l_`s'
	estadd loc sname "`s'"
	estadd loc alpha "--"
	estadd loc c_int "--"
	estadd loc alpha2 "--"
	estadd loc c_int2 "--"
	
	* Restriction by "close" indicator, quadratic in points interval
	reg wtp c.interval##c.interval if sample == "`s'" & `flag' & `excl' ///
		& interval < 17 & close == 1, clus(id)
	eststo close_sq_`s'
	estadd loc sname "`s'"
	qui get_ci `anomsd_`s'' `anommean_`s''
	estadd loc alpha "`r(alpha)'"
	estadd loc c_int "`r(ci)'"
	estadd loc alpha2 "`r(alpha2)'"
	estadd loc c_int2 "`r(ci2)'"	
		
	* Interaction with various variables
	foreach interactor in above_median above_median_D{
	
		* Run regression, linear in points interval
		reg wtp interval `interactor' ///
			interval_`interactor' if sample == "`s'" & `flag' & `excl' ///
			& interval < 17, clus(id)
		eststo l_`interactor'_`s'
		estadd loc sname "`s'"
		
		* Run regression, quadratic in points interval
		reg wtp c.interval##c.interval `interactor' ///
			interval*_`interactor' if sample == "`s'" & `flag' & `excl' ///
			& interval < 17, clus(id)
		eststo sq_`interactor'_`s'
		estadd loc sname "`s'"
		
		}
		
	* Interaction with group size indicators for Prolific sample
	if "`s'" == "Prolific"{
	
		* Linear in points interval
		reg wtp interval group300 group15 interval_group300 interval_group15 ///
			if sample == "`s'" & `flag' & `excl' & interval < 17, clus(id)
		eststo l_size
		
		* Quadratic in points interval
		reg wtp c.interval##c.interval group300 group15 ///
			interval*_group300 interval*_group15 ///
			if sample == "`s'" & `flag' & `excl' & interval < 17, clus(id)
		eststo sq_size
		
		}
	
	
	* Spec including top interval	
	if "`s'" != "QM" {
		replace interval = topintavg if interval >= 17
			
		
		reg wtp c.interval##c.interval if sample == "`s'" & `flag' & `excl', clus(id)
		
		eststo topintavg_`s'
		estadd loc sname "`s'"
		qui get_ci `anomsd_`s'' `anommean_`s''
		estadd loc alpha "`r(alpha)'"
		estadd loc c_int "`r(ci)'"
		estadd loc alpha2 "`r(alpha2)'"
		estadd loc c_int2 "`r(ci2)'"
	
		replace interval = 17.5 if interval > 17
	}	
	
		
	* Revert renaming & restore placeholders
	ren (above_median above_median_D) ///
		(abovemed_`s' abovemeddiff_`s')
	replace close = .
	foreach interactor in above_median above_median_D{
		replace interval_`interactor' = .
		replace interval_sq_`interactor' = .
		}
			
	}
	
* Export regression output
foreach r in "" "close_"{
	esttab `r'l_Pr* `r'sq_Pr* `r'l_Be* `r'sq_Be* `r'l_BU `r'sq_BU ///
		using "$outputdir/`r'wtp_pts.tex", ///
		nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{l*{@M}{c}}" "\hline") ///
		prefoot("\hline") postfoot("\hline" "\end{tabular}") ///
		mlabels(none) nonumbers posthead("& (1) & (2) & (3) & (4) & (5) & (6) \\" "Model & OLS & OLS & OLS & OLS & OLS & OLS \\" "Dependent var. & WTP & WTP & WTP & WTP & WTP & WTP \\ \hline") ///
		replace se nonote nonumbers star(* 0.10 ** 0.05 *** 0.01) ///
		order(interval c.interval#c.interval _cons) b(%8.3f) se(%8.3f) ///
		varlabels(_cons "Constant" interval "Points (00s)" c.interval#c.interval "Points (00s) sq.") ///
		stats(alpha c_int alpha2 c_int2 sname N N_clust, l("$-\textrm{R}^{''}/ \textrm{R}'(\bar{a}\textsubscript{pop})$" "95\% CI" "$-\text{R}^{''}/ \text{R}'(\bar{a}\textsubscript{pop}) \times \text{SD}$" "95\% CI" "\hline Sample" "Observations" "N. Subjects") fmt(%8.0f %8.0f %8.0f %8.0f %8.0f))
	

}

esttab l_QM sq_QM ///
		using "$outputdir/wtp_pts_QM.tex", ///
		nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{l*{@M}{c}}" "\hline") ///
		prefoot("\hline") postfoot("\hline" "\end{tabular}") ///
		mlabels(none) nonumbers posthead("& (1) & (2) \\" "Model & OLS & OLS  \\" "Dependent var. & WTP & WTP  \\ \hline") ///
		replace se nonote nonumbers star(* 0.10 ** 0.05 *** 0.01) ///
		order(interval c.interval#c.interval _cons) b(%8.3f) se(%8.3f) ///
		varlabels(_cons "Constant" interval "Points (00s)" c.interval#c.interval "Points (00s) sq.") ///
		stats(alpha c_int alpha2 c_int2 sname N N_clust, l("$-\textrm{R}^{''}/ \textrm{R}'(\bar{a}\textsubscript{pop})$" "95\% CI" "$-\text{R}^{''}/ \text{R}'(\bar{a}\textsubscript{pop}) \times \text{SD}$" "95\% CI" "\hline Sample" "Observations" "N. Subjects") fmt(%8.0f %8.0f %8.0f %8.0f %8.0f))


esttab topintavg_Pr* topintavg_Be* topintavg_BU ///
		using "$outputdir/wtp_pts_topintavg.tex", ///
		nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{l*{@M}{c}}" "\hline") ///
		prefoot("\hline") postfoot("\hline" "\end{tabular}") ///
		mlabels(none) nonumbers posthead("& (1) & (2) & (3) \\" "Model & OLS & OLS & OLS \\" "Dependent var. & WTP & WTP & WTP \\ \hline") ///
		replace se nonote nonumbers star(* 0.10 ** 0.05 *** 0.01) ///
		order(interval c.interval#c.interval _cons) b(%8.3f) se(%8.3f) ///
		varlabels(_cons "Constant" interval "Points (00s)" c.interval#c.interval "Points (00s) sq.") ///
		stats(alpha c_int alpha2 c_int2 sname N N_clust, l("$-\textrm{R}^{''}/ \textrm{R}'(\bar{a}\textsubscript{pop})$" "95\% CI" "$-\text{R}^{''}/ \text{R}'(\bar{a}\textsubscript{pop}) \times \text{SD}$" "95\% CI" "\hline Sample" "Observations" "N. Subjects") fmt(%8.0f %8.0f %8.0f %8.0f %8.0f))

		
foreach i in above_median above_median_D {
	esttab l_`i'_Pr* sq_`i'_Pr* l_`i'_Be* sq_`i'_Be* l_`i'_BU sq_`i'_BU ///
		using "$outputdir/wtp_pts_`i'.tex", ///
		nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{l*{@M}{c}}" "\hline") ///
		prefoot("\hline") postfoot("\hline" "\end{tabular}") ///
		mlabels(none) nonumbers posthead("& (1) & (2) & (3) & (4) & (5) & (6) \\" "Model & OLS & OLS & OLS & OLS & OLS & OLS \\" "Dependent var. & WTP & WTP & WTP & WTP & WTP & WTP \\ \hline") ///
		replace se nonote nonumbers starlevels(* 0.10 ** 0.05 *** 0.01) ///
		wrap varwidth(25) ///
		order(interval c.interval#c.interval `i' interval_`i' interval_sq_`i' _cons) ///
		varlabels(_cons "Constant" interval "Points (00s)" c.interval#c.interval "Points (00s) sq." above_median "Above med. anon. score" interval_above_median "Points (00s) $\times$ Above med. anon. score" interval_sq_above_median "Points (00s) sq. $\times$ Above med. anon. score" above_median_D "Above med. PR impact" interval_above_median_D "Points (00s) $\times$ Above med. PR impact" interval_sq_above_median_D "Points (00s) sq. $\times$ Above med. PR impact") ///
		b(%8.3f) se(%8.3f)	stats(sname N N_clust, l("Sample" "Observations" "N. Subjects") fmt(%8.0f %8.0f %8.0f))
	}
	
esttab l_size sq_size using "$outputdir/wtp_pts_gpsize.tex", ///
	nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{l*{@M}{c}}" "\hline") ///
	prefoot("\hline") postfoot("\hline" "\end{tabular}") ///
	mlabels(none) nonumbers posthead("& (1) & (2) \\" "Model & OLS & OLS \\" "Dependent var. & WTP & WTP \\ \hline") ///
	replace se nonote nonumbers starlevels(* 0.10 ** 0.05 *** 0.01) ///
	order(interval c.interval#c.interval group300 interval_group300 interval_sq_group300 group15 interval_group15 interval_sq_group15 _cons) ///
	varlabels(_cons "Constant" interval "Points (00s)" c.interval#c.interval "Points (00s) sq." group300 "Group of 300" interval_group300 "Group of 300 $\times$ Points (00s)" interval_sq_group300 "Group of 300 $\times$ Points (00s) sq." group15 "Group of 15" interval_group15 "Group of 15 $\times$ Points (00s)" interval_sq_group15 "Group of 15 $\times$ Points (00s) sq.") ///
	b(%8.3f) se(%8.3f)	stats(N N_clust, l("Observations" "N. Subjects") fmt(%8.0f %8.0f))


** Generate imputed WTPs for different SR round scores **
* Generate scores in the SR round for each sample
egen recogpts_mean = mean(recogpts) if `flag' & `excl', by(sample)
forval pct = 25(25)75{
	egen recogpts_p`pct' = pctile(recogpts) if `flag' & `excl', ///
		p(`pct') by(sample)
}

* Generate imputed WTPs for each SR round score statistic
foreach stat in mean p25 p50 p75{

	* Assign the relevant points interval
	gen `stat'_sr_interval = floor(recogpts_`stat'/100) + .5
	
	* Assign next closest interval
	gen `stat'_next_sr_interval = `stat'_sr_interval - 1 ///
		if ((`stat'_sr_interval*100) - recogpts_`stat' > 0)
	replace `stat'_next_sr_interval = `stat'_sr_interval + 1 ///
		if ((`stat'_sr_interval*100) - recogpts_`stat' <= 0)
	
	* Generate weights
	gen x_`stat' = 1 - ((abs(recogpts_`stat' - `stat'_sr_interval*100))/100)
	gen y_`stat' = 1 - ((abs(recogpts_`stat' - `stat'_next_sr_interval*100))/100)

	* Generate imputed WTP
	gen `stat'_int_wtp =  wtp if interval == `stat'_sr_interval
	gen next_`stat'_int_wtp = wtp if interval == `stat'_next_sr_interval
	bys id: egen `stat'_interval_wtp = mean(`stat'_int_wtp)
	bys id: egen next_`stat'_interval_wtp = mean(next_`stat'_int_wtp)
	gen wtp_imp_sr`stat' = ///
		x_`stat'*`stat'_interval_wtp + y_`stat'*next_`stat'_interval_wtp

	}
	
* Summarize imputed WTPs
foreach s in `samples'{
	foreach stat in mean p25 p50 p75{
		
		* Declare locals for naming
		if "`stat'" == "p25" loc name "ptfive"
		else if "`stat'" == "p50" loc name "pfifty"
		else if "`stat'" == "p75" loc name "psfive"
		else loc name "mean"
	
		* Generate means & 95% CIs of imputed WTPs
		ci means wtp_imp_sr`stat' if sample == "`s'" & `flag' & `excl' ///
			& interval == .5 // only keep one observation for each participant
		loc est : di %4.2f r(mean)
		loc ub : di %4.2f r(ub)
		loc lb : di %4.2f r(lb)
		loc ci : di "[`lb', `ub']"
		
		* Store estimates
		latex_write sr`name'wtp`s' `est'
		latex_write sr`name'wtpCI`s' "`ci'"

		}
	}


** Create program for bootstrapping procedure **
capture program drop realized_wtp
program define realized_wtp, rclass

	* Generate placeholder variable
	gen interval_avg_wtp = .

	* Fill in values for average WTP in realized interval
	forval int = 0/17{
		sum wtp if interval == `int' + .5
		replace interval_avg_wtp = r(mean) if realized_interval == `int' ///
			& realized_interval == (interval - 0.5)
		}

	* Find mean average WTP for full sample
	reg interval_avg_wtp, cluster(id)
	return scalar avg_wtp_all = _b[_cons]

	* Find & return mean average WTP in each quartile
	reg interval_avg_wtp quart_`1'_*, nocons cluster(id)
	forval i = 1/4{
		return scalar avg_wtp_q`i' = _b[quart_`1'_`i']
		}
	
	* Drop variable
	drop interval_avg_wtp
		
end

	
** Create chart of average WTP in realized interval by SR points quartile **
* Generate quartiles based on points scored in the SR round
foreach s in `samples'{

	* Generate an indicator for each quartile
	xtile quart_`s' = recogpts if sample == "`s'" & `flag' & `excl', nq(4)
	tab quart_`s', generate(quart_`s'_)

	* Store mean points in SR round by quartile
	forval i = 1/4{
		sum recogpts if sample == "`s'" & `flag' & `excl' & quart_`s'_`i' == 1
		loc srptsq`i'mean`s' : di %4.1f r(mean)
		}
		
	preserve
	drop if !(sample == "`s'" & `flag' & `excl')
	
	* Generate estimates with bootstrapping
	bootstrap avg_wtp_all = r(avg_wtp_all) avg_wtp_q1 = r(avg_wtp_q1) ///
		avg_wtp_q2 = r(avg_wtp_q2) avg_wtp_q3 = r(avg_wtp_q3) ///
		avg_wtp_q4 = r(avg_wtp_q4), reps(1000) cluster(id) ///
		nodrop level(95) seed(`randseed'): realized_wtp `s'
	estat bootstrap, all
	
	* Store output
	matrix temp_b =  e(b)'
	matrix temp =    e(ci_percentile)'
	matrix temp_lb = temp[1...,1]
	matrix temp_ub = temp[1...,2]
	matrix temp_q =  (0 \ 1 \ 2 \ 3 \ 4)

	svmat double temp_b,  name(realized_wtp_avg_`s')
	svmat double temp_lb, name(realized_wtp_lb_`s')
	svmat double temp_ub, name(realized_wtp_ub_`s')
	svmat int    temp_q,  name(realized_wtp_gp_`s')
	
	loc imagepayoff`s': di %4.2f e(b)[1,1]
	latex_write imagepayoff`s' `imagepayoff`s''
	
	* Declare local for formatting
	if "`s'" == "Prolific" loc ylab "-1.5(.5)1.5"
	else loc ylab "-6(2)4"
	
	* Plot means with CIs
	tw (sc realized_wtp_avg_`s' realized_wtp_gp_`s', color(navy)) ///
	   (rcap realized_wtp_ub_`s' realized_wtp_lb_`s' realized_wtp_gp_`s', lcolor(navy) lwidth(thin) lpattern(dash)), ///
	   xlab(-.5 " " 0 `""Full sample" "{it:`srptsmean`s''}""'  1 `""Quartile 1" "{it:`srptsq1mean`s''}""' 2 `""Quartile 2" "{it:`srptsq2mean`s''}""' 3 `""Quartile 3" "{it:`srptsq3mean`s''}""' 4 `""Quartile 4" "{it:`srptsq4mean`s''}""' 4.5 " ", noticks labgap(3)) ///
	   xtitle("Quartile of points {it:x} scored in the PR round" "{it:Mean of x}", height(9)) ///
	   ytitle("WTP ($)", orientation(horizontal) placement(n)) ///
	   ylabel(`ylab',angle(0)) legend(off) graphregion(color(white)) ///
	   xtick(0 1 2 3 4) yline(0, lpattern(dash) lwidth(thick) lcolor(gs11))
	   graph export "$outputdir/realized_wtp_`s'.pdf", replace
	   
	restore
		
	}

```

### `Packet/Analysis/Code/ind_differences_analysis.do`
```stata
******************************************************************************
* Analysis for individual differences appendix (ymca and charity experiments)
	* Generates estimates for Tables A21-A22
	* writes to same numbers tex file as the welfare estimates file
******************************************************************************

* First perform ind differences analysis on YMCA sample
use "$datadir/experiment_build.dta", replace


* Reshape long
reshape long wtp, i(id) j(interval)

* gen visits variables
gen visits = 0
replace visits = 1 if interval == 1
replace visits = 2 if interval == 2
replace visits = 3 if interval == 3
replace visits = 4 if interval == 4
replace visits = 5.5 if interval == 56
replace visits = 7.5 if interval == 78
replace visits = 10.5 if interval == 912
replace visits = 15 if interval == 1317
replace visits = 20 if interval == 1822
replace visits = 26.5 if interval == 2328

gen visits2 = visits^2

* Label variables
label var visits "N. visits"
label var visits2 "N. visits sq."
label var wtp "WTP"

* generate vars for regression
gen closeb = abs(visits - beliefs_w_image)
gen origin = visits == 0


* Run xtmixed regression w/in 4 of beliefs
xtmixed wtp visits visits2 if coherent_sample == 1  & closeb <= 4 || id: || id: visits visits2, nocons cov(unstructured) variance vce(cluster id) 

* return point estimates and se for fixed effects
loc Rzeroymca: di %8.3f r(table)[1,3]
loc Rzeroymcase: di %8.3f r(table)[2,3]

loc Roneymca: di %8.3f r(table)[1,1]
loc Roneymcase: di %8.3f r(table)[2,1]

loc Rtwoymca: di %8.3f r(table)[1,2]
loc Rtwoymcase: di %8.3f r(table)[2,2]

* return point estimates and se for random effects
_diparm lns1_1_1, f(exp(@)^2) d(2*exp(@)^2) // var(constant)
return list

loc varRzeroymca: di %8.3f r(est)
loc varRzeroymcase: di %8.3f r(se)

_diparm lns1_2_1, f(exp(@)^2) d(2*exp(@)^2) // var(r1)
return list

loc varRoneymca: di %8.3f r(est)
loc varRoneymcase: di %8.3f r(se)

_diparm lns1_2_2, f(exp(@)^2) d(2*exp(@)^2) // var(r2)
return list

loc varRtwoymca: di %8.5f r(est)
loc varRtwoymcase: di %8.5f r(se)

_diparm atr1_2_1_2 lns1_2_1 lns1_2_2, f(tanh(@1)*exp(@2+@3))  ///
        d((1-tanh(@1)^2)*exp(@2+@3) tanh(@1)*exp(@2+@3) tanh(@1)*exp(@2+@3))

loc covRymca: di %8.3f r(est)
loc covRymcase: di %8.3f r(se)


foreach x in Rzeroymca Rzeroymcase Roneymca Roneymcase Rtwoymca	Rtwoymcase ///
	varRzeroymca varRzeroymcase varRoneymca varRoneymcase ///
	varRtwoymca	varRtwoymcase covRymca covRymcase {
	latex_write `x' ``x''
}

**********************
* Next perform analysis on charity data
**********************
** Load cleaned data **
use "$datadir/charity_cleaned_data", clear

* Impose standard sample restrictions
keep if flag_attention_check == 0
keep if consistent_b == 1


** Record & drop observations with disqualifying points **
gen high_pts = 0
foreach round in anom earn recog{
	replace high_pts = 1 if `round'pts > 3000
	}
foreach s in `samples'{

	* Number in full sample		
	sum id if sample == "`s'"
	loc obs : di %4.0f r(N)
	latex_write Nall`s' `obs'

	* Number dropped due to disqualifying points
	sum high_pts if sample == "`s'"
	loc obs : di %4.0f r(N)*r(mean)
	latex_write Nexclpts`s' `obs'
	
	}
drop if high_pts == 1
	

* restrict just to needed vars
keep id sample wtp*

drop if sample == "BU QM221"

* List of samples
loc samples "Prolific Berkeley BU" 

** Reshape data & generate variables for WTP analysis **
reshape long wtp, i(id) j(interval)

* transform interval
replace interval = interval + 0.5

gen interval2 = interval^2

* record output

foreach s in `samples' {
	di "`s'"
	
	xtmixed wtp interval interval2 if sample == "`s'" ///
		& interval < 17, || id: || id: interval interval2, nocons cov(unstructured) variance vce(cluster id) 
		
	
	* return point estimates and se for fixed effects
	loc Rzero`s': di %8.3f r(table)[1,3]
	loc Rzero`s'se: di %8.3f r(table)[2,3]

	loc Rone`s': di %8.3f r(table)[1,1]
	loc Rone`s'se: di %8.3f r(table)[2,1]

	loc Rtwo`s': di %8.3f r(table)[1,2]
	loc Rtwo`s'se: di %8.3f r(table)[2,2]

	* return point estimates and se for random effects
	_diparm lns1_1_1, f(exp(@)^2) d(2*exp(@)^2) // var(constant)
	return list

	loc varRzero`s': di %8.3f r(est)
	loc varRzero`s'se: di %8.3f r(se)

	_diparm lns1_2_1, f(exp(@)^2) d(2*exp(@)^2) // var(r1)
	return list

	loc varRone`s': di %8.3f r(est)
	loc varRone`s'se: di %8.3f r(se)

	_diparm lns1_2_2, f(exp(@)^2) d(2*exp(@)^2) // var(r2)
	return list

	loc varRtwo`s': di %8.5f r(est)
	loc varRtwo`s'se: di %8.5f r(se)

	_diparm atr1_2_1_2 lns1_2_1 lns1_2_2, f(tanh(@1)*exp(@2+@3))  ///
			d((1-tanh(@1)^2)*exp(@2+@3) tanh(@1)*exp(@2+@3) tanh(@1)*exp(@2+@3))

	loc covR`s': di %8.3f r(est)
	loc covR`s'se: di %8.3f r(se)


	foreach x in Rzero`s' Rzero`s'se Rone`s' Rone`s'se Rtwo`s'	Rtwo`s'se ///
		varRzero`s' varRzero`s'se varRone`s' varRone`s'se ///
		varRtwo`s'	varRtwo`s'se covR`s' covR`s'se {
		latex_write `x' ``x''
	}
}


```

### `Packet/Analysis/Code/welfare_estimates.do`
```stata


cap rm "$outputdir/numbersStr.tex" // remove old version of file
cap program drop latex_write
program define latex_write
	if "`c(os)'" == "MacOSX" local command \\newcommand{\\\`1'}{`2'}
	else local command \newcommand{\\`1'}{`2'}
	! echo `command'  >> "$outputdir/numbersStr.tex"
end


***************************************************************
* (I) YMCA: recover parameters
***************************************************************

use "$datadir/structural_build.dta", replace

* generate predicted impact of $1 incentive
gen pred_impact_fin = beliefs_w_1 - beliefs_wout_image

* Reshape long
reshape long wtp, i(id) j(interval)

* gen visits variables
gen visits = 0
replace visits = 1 if interval == 1
replace visits = 2 if interval == 2
replace visits = 3 if interval == 3
replace visits = 4 if interval == 4
replace visits = 5.5 if interval == 56
replace visits = 7.5 if interval == 78
replace visits = 10.5 if interval == 912
replace visits = 15 if interval == 1317
replace visits = 20 if interval == 1822
replace visits = 26.5 if interval == 2328

* gen other variables for regressions
gen visits2 = visits^2
gen origin = (visits == 0)

gen closeb = abs(visits - beliefs_w_image)

gen Coh = coherent_sample
gen Mon = monotonic_sample

* save temp dataset
save "$tempdir/structural_build_long.dta", replace


******************************************************
* program to identify structural parameters for YMCA
******************************************************
* identify avg att in population
reg attendance if origin == 1 & inexp == 0, r
scalar a_pop = _b[_cons]

capture program drop param_ymca

program define param_ymca, rclass
	*********************************************************
	* Part 1: identify c, gamma1, gamma2, rho
	*********************************************************
	* identify tau
	reg attendance image past if `1' ==1 & origin == 1 & inexp == 1, r 
	scalar tau = _b[image]

	* identify average attendance without image
	reg attendance if `1' == 1 & origin == 1 & image == 0 & inexp == 1, r
	scalar att_noim = _b[_cons]

	* identify avg attendance with image
	scalar att_im = att_noim + tau
	
	* identify gamma1, gamma2, rho
	tobit wtp visits visits2 if `1' == 1 & closeb <= `3' & inexp == 1, ll ul vce(cluster id)
	scalar r1 = _b[visits]
	scalar r2 = _b[visits2]
	scalar r0 = _b[_cons]
	
	scalar gamma2 = r2
	scalar gamma1 = (r1^2 - 4*gamma2*r0)^(0.5)
	scalar rho = (gamma1 - r1)/(2*gamma2*a_pop)
	
	* identify c
	scalar c = (r1 + 2 * r2 * att_im)/(tau)
	
	* identify rho_type
	scalar rho_type = (gamma1 - r1)/(2*gamma2*a_pop) - gamma1/(c*a_pop)
	
	* identify gamma1_type and gamma2_type
	scalar gamma1t = gamma1/(c-2*r2)
	scalar gamma2t = gamma2/(c-2*r2)^2
	
	*********************************************************
	* Part 2: identify predicted impact of financial inc.
	*********************************************************
		
	* identify pred att with $y incentive
	reg pred_impact_fin if `1' == 1 & origin == 1 & inexp == 1, r
	scalar fin_pred = _b[_cons]
	
	* solve for the effect of a $y incentive
	scalar fin_inc = `2'/c
	
	* solve for difference b/t pred and estimated
	scalar diff_fin = fin_inc - fin_pred
	
	*********************************************************
	* Part 3: return scalars
	*********************************************************
	return scalar c = c
	return scalar fin_inc = fin_inc
	return scalar diff_fin = diff_fin
	return scalar fin_pred = fin_pred
	return scalar att_noim = att_noim
	return scalar att_im = att_im
	return scalar tau = tau
	return scalar gamma1 = gamma1
	return scalar gamma2 = gamma2
	return scalar rho = rho
	return scalar rho_type = rho_type
	return scalar a_pop = a_pop
	return scalar gamma1t = gamma1t
	return scalar gamma2t = gamma2t
end

qui param_ymca coherent_sample 1 4
return list

foreach s in Coh { 
	
	* drop incoherent/mon-mon obs so they don't get resampled
	preserve
	
	drop if `s' == 0 | inexp == 0
	
	* bootstrap
	bootstrap c = r(c) dfin = r(diff_fin) afin = r(fin_pred) pfin = r(fin_inc)  ///
			  rho = r(rho) gammaI = r(gamma1) gammaII = r(gamma2) ///
			  rhoT = r(rho_type) gammaIT = r(gamma1t) gammaIIT = r(gamma2t), ///
			  reps(1000) saving("$tempdir/reps_param_ymca.dta", replace) seed(12345) ///
			  cluster(id) nodrop: param_ymca `s' 1 4 
	
	* display output
	estat bootstrap, all
	
	* store output (means + percentile CI)
	local count = 0
	
	local varlist "c dfin afin pfin rho gammaI gammaII rhoT gammaIT gammaIIT"
	foreach var in `varlist'  {
		
		* format output
		local count = `count' + 1
		
		local mean :  di %4.2f e(b)[1,`count']
		local lb :  di %4.2f e(ci_percentile)[1,`count']
		local ub :  di %4.2f e(ci_percentile)[2,`count']
		
		** have gamma2 to 3 dec instead
		if `count' == 7 | `count' == 10 {
		
			local mean :  di %4.3f e(b)[1,`count']
			local lb :  di %4.3f e(ci_percentile)[1,`count']
			local ub :  di %4.3f e(ci_percentile)[2,`count']
			
		}
		
		** record c, rhos, gammas for welfare calcs
		if `count' == 1 | `count' >= 5 {
			scalar `var'`s' = e(b)[1,`count']	
		}
		
		** also record CI bounds for gamma2
		if `count' == 7 | `count' == 10 {
			scalar `var'lb`s' = e(ci_percentile)[1,`count']
			scalar `var'ub`s' = e(ci_percentile)[2,`count']
		}
		
		* write output to tex
		latex_write `var'`s' `mean'
		latex_write `var'lb`s' `lb'
		latex_write `var'ub`s' `ub'
		
	}
	
restore

}

* Now store standard dev of att for mainpop
sum attendance if inexp == 0
scalar sd_mainpop = r(sd)
scalar sd_theta_mainpop = r(sd)*cCoh

di sd_mainpop "`sd_mainpop'"
di sd_theta_mainpop "`sd_theta_mainpop'"

***************************************************************
* (II) Real effort: recover parameters
***************************************************************

use "$datadir/charity_cleaned_data.dta", replace

drop if sample == "BU QM221"

** Declare locals **
* Excluding those who failed the attention check
loc flag = "flag_attention_check == 0"

* Excluding those who failed the consistency criterion
loc excl "consistent_b == 1"

* List of samples
loc samples "Prolific Berkeley BU"

* Rename variables
foreach round in anom recog earn{
	rename `round'pts pts`round'
	}

* Reshape data
reshape long pts, i(id) j(round) string

* Generate indicators for round
gen SR = (round == "recog")
gen ownpay = (round == "earn")

* Add variable for order in which round appeared
do "$builddir/Label_Rounds.do"

* Generate indicators for round order
tab order, gen(o)

** Reshape data & generate variables for WTP analysis **
reshape long wtp nwtp, i(id round) j(interval)

* Generate ingredients for indicator of avg round points "close" to midpoint
gen interval_midpoint = (interval + .5)*100

* Transform interval variable
gen int_no = interval

replace interval = interval + .5
gen interval2 = interval^2

gen int_pts = interval * 100
gen int_pts2 = int_pts^2

gen pts00 = pts/100

encode sample, gen(s_no)

*** record avg points as scalars
forval i = 1/3 {
reg pts00 if s_no == `i' & flag_attention_check == 0  & consistent_b == 1 & round == "anom", clus(id)
	scalar pts_noim`i' = _b[_cons]

sum pts00 if s_no == `i' & flag_attention_check == 0  & consistent_b == 1 & round == "anom", detail 
	scalar sd_`i' = r(sd)
}

capture program drop param_effort

program define param_effort, rclass

	* Recover tau, impact of fin 
	reg pts00 SR ownpay o1 o2 if flag_attention_check == 0 & consistent_b == 1  & s_no == `1', clus(id)

	scalar tau = _b[SR]
	scalar fin_act = _b[ownpay]
	
	* identify average performance without image
	reg pts00 if s_no == `1' & flag_attention_check == 0  & consistent_b == 1 & round == "anom", clus(id)
	scalar pts_noim = _b[_cons]

	* identify avg attendance with image
	scalar pts_im = pts_noim + tau
	
	* set a_pop to be avg points with image
	scalar a_pop = pts_im
	
	* identify gamma1, gamma2, rho
	reg wtp interval interval2 if s_no == `1' & flag_attention_check == 0  & consistent_b == 1 & interval < 17, clus(id)
	
	scalar r1 = _b[interval]
	scalar r2 = _b[interval2]
	scalar r0 = _b[_cons]
	
	scalar gamma2 = r2
	scalar gamma1 = (r1^2 - 4*gamma2*r0)^(0.5)
	scalar rho = (gamma1 - r1)/(2*gamma2*pts_im)
	
	* identify c
	scalar c = (r1 + 2 * r2 * pts_im)/(tau)
	
	* identify rho_type
	scalar rho_type = (gamma1 - r1)/(2*gamma2*pts_noim) - gamma1/(c*pts_noim)
	
	* identify gamma1_type and gamma2_type
	scalar gamma1t = gamma1/(c-2*r2)
	scalar gamma2t = gamma2/(c-2*r2)^2
	
	*********************************************************
	* Part 2: identify predicted impact of financial inc.
	*********************************************************

	* solve for the effect of a $y incentive
	scalar fin_inc = `2'/c
	
	scalar diff_fin = fin_inc - fin_act

	*********************************************************
	* Part 3: return scalars
	*********************************************************
	
	* store SD of theta
	scalar sd_theta_`1' = sd_`1'*c
	
	* return scalars
	return scalar c = c
	return scalar fin_inc = fin_inc
	return scalar diff_fin = diff_fin
	return scalar fin_act = fin_act
	return scalar pts_noim = pts_noim
	return scalar pts_im = pts_im
	return scalar tau = tau
	return scalar gamma1 = gamma1
	return scalar gamma2 = gamma2
	return scalar rho = rho
	return scalar rho_type = rho_type
	return scalar a_pop = a_pop
	return scalar gamma1t = gamma1t
	return scalar gamma2t = gamma2t
	
end

* run bootstrap
forval s = 1/3 {
	
	* set sample-specific label, fin inc.
	if `s' == 1 {
		local s_label = "BU"
		scalar inc = 0.5
	}
	
	if `s' == 2 {
		local s_label = "Berk"
		scalar inc = 0.5
	}
	
	if `s' == 3 {
		local s_label = "Prol"
		scalar inc = 0.2
	}
	
	* drop incoherent/mon-mon obs so they don't get resampled
	preserve
	
	drop if s_no != `s' | flag_attention_check == 1 | consistent_b == 0 
	
	
	* bootstrap
	bootstrap c = r(c) dfin = r(diff_fin) afin = r(fin_act) pfin = r(fin_inc)  ///
			  rho = r(rho) gammaI = r(gamma1) gammmaII = r(gamma2) ///
			  rhoT = rho_type gammaIT = r(gamma1t) gammaIIT = r(gamma2t), ///
			  reps(1000) saving("$tempdir/reps_param_`s_label'.dta", replace) seed(12345) ///
			  cluster(id) nodrop: param_effort `s' inc
	
	* display output
	estat bootstrap, all
	
	* store output (means + percentile CI)
	local count = 0
	
	local varlist "c dfin afin pfin rho gammaI gammaII rhoT gammaIT gammaIIT"
	foreach var in `varlist'  {
		
		* format output
		local count = `count' + 1
		
		local mean :  di %4.2f e(b)[1,`count']
		local lb :  di %4.2f e(ci_percentile)[1,`count']
		local ub :  di %4.2f e(ci_percentile)[2,`count']
		
		** have gamma2 to 3 dec instead
		if `count' == 7 | `count' == 10 {
		
			local mean :  di %4.3f e(b)[1,`count']
			local lb :  di %4.3f e(ci_percentile)[1,`count']
			local ub :  di %4.3f e(ci_percentile)[2,`count']
			
		}
		
		** record rhos for welfare calcs
		if `count' == 5 | `count' == 8 {
			scalar `var'`s_label' = e(b)[1,`count']	
		}
		
		* write output to tex
		latex_write `var'`s_label' `mean'
		latex_write `var'lb`s_label' `lb'
		latex_write `var'ub`s_label' `ub'
		
	}
	* record gammaI and gammaII
	scalar gammaI`s_label' = e(b)[1,6]
	scalar gammaII`s_label' = e(b)[1,7]
	scalar gammaIT`s_label' = e(b)[1,9]
	scalar gammaIIT`s_label' = e(b)[1,10]
	
	restore
}

*********************************************************
* (III): Create programs to identify direct emotional effects
	* program takes 4 args: gamma1, gamma2, rho, c
*********************************************************
use "$tempdir/structural_build_long.dta", replace

* identify average att
sum attendance if inexp == 0
scalar a_pop = r(mean)

cap program drop action_emotion

program define action_emotion, rclass
	
	* identify \bar{a}_eq
	scalar a_eq = (a_pop + `1'/`4')/(1-(1-`3')*2*`2'/`4')
	
	* identify counterfactual attendance for mainpop
	qui gen attendance_eq = (attendance + `1'/`4' - 2*`2'*`3'*a_eq/`4')/(1-2*`2'/`4')
	
	qui sum attendance_eq if inexp == 0
	return scalar test_aeq = r(mean)
	
	* identify direct emotional effect
	qui gen emotion = `1'*(attendance_eq - `3'*a_eq) + `2'*(attendance_eq - `3'*a_eq)^2
	qui sum emotion if inexp == 0
	scalar S = r(mean)
	
	* identify change in behavior
	qui gen delta_att = attendance_eq - attendance
	qui sum delta_att if inexp == 0
	scalar d_att = 100*r(mean)/a_pop

	* return scalars
	return scalar aeq = a_eq
	return scalar S = S
	return scalar datt = d_att

	qui drop emotion delta_att attendance_eq
end




cap program drop type_emotion

program define type_emotion, rclass
	
	*first, convert from gamma1 and gamma2 to t1 and t2
	scalar r2 = ((1+4*`2'*`4')-sqrt(8*`2'*`4'+1))/(8*`2')
	scalar r1 = (`4'-2*r2)^2*`1'/`4' - 2*r2*`3'*a_pop
	scalar r0 = -r1 * (`3'*a_pop + r1/`4')/(1-2*r2/`4') - r2*((`3'*a_pop + r1/`4')/(1-2*r2/`4'))^2

	return scalar r2 = r2
	return scalar r1 = r1
	return scalar r0 = r0
	
	* identify counterfactual attendance for mainpop
	qui gen attendance_eq = (attendance + r1/`4')/(1-2*r2/`4')
	
	qui sum attendance_eq if inexp == 0
	scalar aeq = r(mean)
	
	
	* identify direct emotional effect
	qui gen emotion = `4'*`1'*(attendance-`3'*a_pop)+(`4')^2*`2'*(attendance-`3'*a_pop)^2
	qui sum emotion if inexp == 0
	scalar S = r(mean)
	
	* identify change in behavior
	qui gen delta_att = attendance_eq - attendance
	qui sum delta_att if inexp == 0
	scalar datt = 100*r(mean)/a_pop
	
	
	* return scalars
	return scalar aeq = aeq
	return scalar S = S
	return scalar datt = datt

	qui drop emotion delta_att attendance_eq 
end

*** test

qui type_emotion gammaITCoh gammaIITCoh rhoTCoh cCoh
return list


*********************************************************
* (IV): Output action-based results
	* program takes 4 args: gamma1, gamma2, rho, c
*********************************************************
	

* first 4 rows: gammaI and gammaII from coh * 4 val of rho
foreach rho in rhoCoh rhoProl rhoBerk rhoBU {
	
	foreach gamma2 in gammaIICoh {
		
		* run action program
		action_emotion gammaICoh `gamma2' `rho' cCoh
		
		* return action output
		local S_mean :  di %4.2f r(S)
		local datt_mean :  di %4.2f r(datt)
		local rat_mean :  di %4.2f r(rat)

		latex_write AS`rho'`gamma2' `S_mean'
		latex_write Adatt`rho'`gamma2' `datt_mean'

	}
}

* next 3 rows:  gammaII calculated to match curv from charity exp
foreach s in Prol Berk BU {
	
	if "`s'" == "Prol" {
		loc s_no = 3
	}
	
	if "`s'" == "Berk" {
		loc s_no = 2
	}
	
	if "`s'" == "BU" {
		loc s_no = 1
	}
	
	*first set gammaII`sample' to be gammaII`sample'/gammaI`sample' * gammaIymca * sd(sample)/sd(ymca)
	scalar gammaIIimp`s' = gammaII`s'/gammaI`s' * gammaICoh * sd_`s_no'/sd_mainpop
		
	* run program
	action_emotion gammaICoh gammaIIimp`s' rhoCoh cCoh
	
	* return output
	local S_mean :  di %4.2f r(S)
	local datt_mean :  di %4.2f r(datt)

	latex_write AS`s'rhoCoh `S_mean'
	latex_write Adatt`s'rhoCoh `datt_mean'

}

* last 3 rows: gammaII calculated to match curv from charity exp, and rho from charity exp
foreach s in Prol Berk BU {
	
	* run program
	action_emotion gammaICoh gammaIIimp`s' rho`s' cCoh
	
	* return output
	local S_mean :  di %4.2f r(S)
	local datt_mean :  di %4.2f r(datt)

	latex_write AS`s'rho`s' `S_mean'
	latex_write Adatt`s'rho`s' `datt_mean'

}

*****************************************************************
* (V): Output type-based results
	* program takes 4 args: gamma1, gamma2, rho, c
*****************************************************************

* first 4 rows: 
foreach rho in rhoTCoh rhoTProl rhoTBerk rhoTBU {
	
		* run type program
		type_emotion gammaITCoh gammaIITCoh `rho' cCoh
		
		* return action output
		local S_mean :  di %4.2f r(S)
		local datt_mean :  di %4.2f r(datt)

		latex_write TS`rho'`gamma2' `S_mean'
		latex_write Tdatt`rho'`gamma2' `datt_mean'


	}


* next 3 rows: gammaII calculated to match curv from charity exp
foreach s in Prol Berk BU {

	if "`s'" == "Prol" {
		loc s_no = 3
	}
	
	if "`s'" == "Berk" {
		loc s_no = 2
	}
	
	if "`s'" == "BU" {
		loc s_no = 1
	}
	
	*first set gammaII`sample' to be gammaII`sample'/gammaI`sample' * gammaIymca * sd(sample)/sd(ymca)
	scalar gammaIITimp`s' = gammaIIT`s'/gammaIT`s' * gammaITCoh * sd_theta_`s_no'/sd_theta_mainpop
		
	* run program
	type_emotion gammaITCoh gammaIITimp`s' rhoTCoh cCoh
	
	* return output
	local S_mean :  di %4.2f r(S)
	local datt_mean :  di %4.2f r(datt)

	latex_write TS`s'rhoTCoh `S_mean'
	latex_write Tdatt`s'rhoTCoh `datt_mean'

}

* last 3 rows: gammaII calculated to match curv from charity exp, and rho from charity exp
foreach s in Prol Berk BU {
		
	* run program
	type_emotion gammaITCoh gammaIITimp`s' rhoT`s' cCoh
	
	* return output
	local S_mean :  di %4.2f r(S)
	local datt_mean :  di %4.2f r(datt)

	latex_write TS`s'rhoT`s' `S_mean'
	latex_write Tdatt`s'rhoT`s' `datt_mean'

}


* output other gammas, stats used
foreach s in Prol Berk BU {

	if "`s'" == "Prol" {
		loc s_no = 3
	}
	
	if "`s'" == "Berk" {
		loc s_no = 2
	}
	
	if "`s'" == "BU" {
		loc s_no = 1
	}
	
	loc gammaIIimp`s': di %4.3f gammaIIimp`s'
	loc gammaIITimp`s': di %4.3f gammaIITimp`s'
	
	loc sd_theta`s': di %4.2f sd_theta_`s_no' 
	loc sd_`s': di %4.2f sd_`s_no' 
	
	latex_write "sdtheta`s'" `sd_theta`s''
	latex_write "sd`s'" `sd_`s''
	latex_write "gammaII`s'welfare" `gammaIIimp`s''
	latex_write "gammaIIT`s'welfare" `gammaIITimp`s''
}

loc sd_theta_mainpop: di %4.2f sd_theta_mainpop
loc sd_mainpop: di %4.2f sd_mainpop

latex_write "sdthetamainpop" `sd_theta_mainpop'
latex_write "sdmainpop" `sd_mainpop'






```

### `Packet/Build/Gen_Vars.do`
```stata
/******************************************************************************

	Gen_Vars.do
	
	Generate WTP and preference variables. Uses globals from SetGlobals.do.
	
******************************************************************************/

** Generate variable for number of switches in preferences for recognition **
gen switch_preference = 0
forval i = 100(100)1700{
	local j = `i' - 100
	replace switch = switch + 1 if preference_`j' != preference_`i'
	}
	
	
** Generate consistency indicators **
* Always yes, always no, or switch once from no to yes in pref for recognition
gen consistent = ((switch_preference == 0) | ///
	(switch_preference == 1 & preference_0 == 0))
label var consistent "all Y, all N, or N->Y" 
	
* Same as above, but also yes pref for recognition in the middle points range
gen consistent_b = consistent
replace consistent_b = 1 if (switch_preference == 2 & preference_0 == 0)
label var consistent_b "all Y, all N, N->Y, or N->Y->N" 
	
	
** Generate WTP variables **
forval i = 0/17{
	loc j = `i'*100

	* Rename anonymous WTP variable to general WTP
	rename pref_anom_`j'_1 wtp`i'
	
	* Make anonymous WTPs negative
	replace wtp`i' = -1 * wtp`i'
	
	* Enter recognition WTPs where anonymous WTPs are missing
	replace wtp`i' = pref_rec_`j'_1 if missing(wtp`i')
	
	}
	

** Generate a variable for those whose WTPs are "approximately monotonic **
*  Definition: for all i < j, WTP_{j} >= WTP_{i-1}
gen approx_monotonic = 1
forval i = 2/17{
	loc j = `i' - 2
	
	* Switch indicator to 0 if condition fails for any i < j
	forval k = 0/`j'{
		replace approx_monotonic = 0 if wtp`i' < wtp`k'
		}
	}
label var approx_monotonic "for all i < j, WTP_{j} >= WTP_{i-1}"
	
	
** Generate WTP variable using hypothetical WTPs **
forval i = 0/17{
	loc j = `i'*100

	gen nwtp`i' = wtp`i'
	
	* Fill in hypothetical WTP if not missing
	replace nwtp`i' = pref_anom_`j'_10 * -1 if !missing(pref_anom_`j'_10)
	replace nwtp`i' = pref_rec_`j'_10 if !missing(pref_rec_`j'_10)

	}
	
	
** Generate realized WTP variables **
* Assign relevant interval
gen realized_interval = floor(recogpts/100)
replace realized_interval = 17 if realized_interval > 17

* Assign WTP for relevant interval
foreach var in wtp nwtp{
	gen realized_`var' = .
	forval i = 0/17{
		replace realized_`var' = `var'`i' if realized_interval == `i' 
		}
	}


** Generate & fill in timer variables with data from existing variables **
foreach round in anom rec earn{
	gen `round'_time = .
	
	foreach x in aer are era ear rea rae{
		replace `round'_time = `round'_`x'_timer_pagesubmit if ///
			!missing(`round'_`x'_timer_pagesubmit)
		}
	}
	
	
** Drop separate timer variables and intermediate variables **
drop *pagesubmit pref_*


** Make all variable names lowercase if not already **
rename *, lower

```

### `Packet/Build/Label_Rounds.do`
```stata
/******************************************************************************

	Label_Rounds.do
	
	Labels points with the order in which the order from which they were earned
	appeared. Used in analysis.
	
******************************************************************************/
gen order=.

* Round order for anom, earn, recog ordering
replace order=1 if round=="anom"&condition=="AER"
replace order=2 if round=="recog"&condition=="AER"
replace order=3 if round=="earn"&condition=="AER"

* Round order for anom, recog, earn ordering
replace order=1 if round=="anom"&condition=="ARE"
replace order=3 if round=="recog"&condition=="ARE"
replace order=2 if round=="earn"&condition=="ARE"

* Round order for earn, anom, recog ordering
replace order=2 if round=="anom"&condition=="EAR"
replace order=1 if round=="recog"&condition=="EAR"
replace order=3 if round=="earn"&condition=="EAR"

* Round order for earn, recog, anom ordering
replace order=3 if round=="anom"&condition=="ERA"
replace order=1 if round=="recog"&condition=="ERA"
replace order=2 if round=="earn"&condition=="ERA"

* Round order for recog, anom, earn ordering
replace order=2 if round=="anom"&condition=="RAE"
replace order=3 if round=="recog"&condition=="RAE"
replace order=1 if round=="earn"&condition=="RAE"

* Round order for recog, earn, anom ordering
replace order=3 if round=="anom"&condition=="REA"
replace order=2 if round=="recog"&condition=="REA"
replace order=1 if round=="earn"&condition=="REA"

```

### `Packet/Build/Prolific_Build.do`
```stata
/******************************************************************************

	Prolific_Build.do
	
	Clean data from the Prolific sample of the Real Effort Experiment for
	analysis. Uses globals from SetGlobals.do.
	
******************************************************************************/
set more off
clear all

** save 
import delimited "$rawdir/prolific_survey_data.csv"

break

** generate attention check flag
gen flag_attention_check = 1 - missing(attention_check)
	
** Destring numeric variables **
foreach var of varlist clicked finalpoints-finalearned {
	destring `var', replace
	}

* Destring hypothetical WTPs
forval i = 0(100)1700{
	foreach state in anom rec{ 
		destring pref_`state'_`i'_10, replace
		}
	}
	
	
** Add labels to numeric variables **
* Preferences
label def preflab 0 "no" 1 "yes"
forval i = 0(100)1700{
	label values preference_`i' preflab
	}
	
* Gender
label def gendlab 1 "male" 2 "female" 3 "other" 4 "no response"
label values gender gendlab

* Race
label def racelab 1 "AIAN" 2 "API" 3 "black" 4 "hispanic" 5 "white" ///
	6 "other" 7 "no response"
label values race racelab

* Education
label def edulab 1 "< HS" 2 "HS/GED" 3 "associate's" 4 "bachelor's" 5 "> bachelor's" 6 "no response"
label values edu edulab


** Change extreme age values to missing **
replace age = . if age < 18 | age > 100

	
** Generate WTP & preference variables for analysis **
do "$builddir/Gen_Vars"


** Save data **
save "$datadir/prolific_cleaned_data", replace

```

### `Packet/Build/University_Build.do`
```stata
/******************************************************************************

	University_Build.do
	
	Clean data from the Berkeley & BU samples of the Real Effort Experiment for 
	analysis. Uses globals from SetGlobals.do.
	
******************************************************************************/
set more off

foreach sample in berkeley bu_qm221 bu_qm222{

	** Import**
	clear all
	import delimited "$rawdir/`sample'_survey_data.csv"
	
	** generate attention check flag
	gen flag_attention_check = 1 - missing(attention_check)
	
	** Destring numeric variables **
	foreach var of varlist clicked finalpoints-finalearned {
		destring `var', replace
		}
	
	* Destring hypothetical WTPs
	forval i = 0(100)1700{
	foreach state in anom rec{ 
		destring pref_`state'_`i'_10, replace
		}
	}
		
		
	** Add labels to numeric variables **
	* Preferences
	label def preflab 0 "no" 1 "yes"
	forval i = 0(100)1700{
		label values preference_`i' preflab
		}
		
	* Gender
	label def gendlab 1 "male" 2 "female" 3 "other" 4 "no response"
	label values gender gendlab
	
	* Race
	label def racelab 1 "AIAN" 2 "API" 3 "black" 4 "hispanic" 5 "white" ///
		6 "other" 7 "no response"
	label values race racelab
	
	* Affiliation for the Berkeley sample
	if "`sample'" == "berkeley"{
		label def affillab 1 "undergrad" 6 "grad" 7 "PhD" 8 "other" 9 "no response"
		label values affiliation affillab
		}

		
	** Generate WTP & preference variables for analysis **
	do "$builddir/Gen_Vars"
	
	
	** Save data **
	save "$datadir/`sample'_cleaned_data", replace
	
	}

```

### `Packet/Build/build_ymca_admin.do`
```stata

********************************************
* Prepare attendance data
********************************************

* First load all excel sheets and convert to dta
import delimited using "$rawdir/ymca_scans.csv", clear


* Convert usrdatetime into separate vars for day, month, and year
gen scandate = date(usrdatetime, "DMYhms")
format scandate %td

gen month = month(scandate)
gen day = day(scandate)
gen year = year(scandate)

drop usrdatetime scandate

* Restrict to max of one scan per day
duplicates drop

* Generate attendance by month counts
bysort ymca_id year month: gen att = _N

* Generate attendance during the experiment
gen att_exp = 0
replace att_exp = 1 if year == 2017 & month == 6 & day >= 15
replace att_exp = 1 if year == 2017 & month == 7 & day <= 15

bysort ymca_id: egen attendance = sum(att_exp)



drop att_exp 

** prepare for reshape
drop day 
duplicates drop

** reshape in two steps
reshape wide att, i(ymca_id attendance month) j(year)

rename att2017 att2017_
rename att2016 att2016_

reshape wide att2016_ att2017_, i(ymca_id attendance) j(month)

** drop empty variables
drop att2016_1 att2016_2 att2016_3 att2016_4  ///
	att2017_8 att2017_9 att2017_10 att2017_11 att2017_12

* Reorder variables
order ymca_id attendance att2016_5 att2016_6 att2016_7 att2016_8 ///
	att2016_9 att2016_10 att2016_11 att2016_12 att2017_1 att2017_2 att2017_3 ///
	att2017_4 att2017_5 att2017_6 att2017_7
	
save "$tempdir/ymca_att_by_month.dta", replace

*******************************************************************
* Merge on membership data and clean combined membership-scan data
*******************************************************************
*Load membership data
import delimited "$rawdir/ymca_membership_data.csv", clear

* merge with attendance data
merge 1:1 ymca_id using "$tempdir/ymca_att_by_month.dta", nogen


* Set months local
local months "2017_7" "2017_6" "2017_5" ///
	"2017_4" "2017_3" "2017_2" "2017_1" ///
	"2016_12" "2016_11" "2016_10" "2016_9" ///
	"2016_8" "2016_7" "2016_6" "2016_5"

* Replace att = 0 if person was member that month
foreach month in "`months'" {
	replace att`month' = 0 if att`month' == .  & m`month' == 1
	replace m`month' = 1 if att`month' != .
}

* Replace attendance = 0 if person was member in June 2017
replace attendance = 0 if attendance == . & m2017_6 == 1

********************************************
* Generate average past attendance
********************************************
* Firsh generate total attendance in preperiod (05/2016-05/2017)
egen att_preperiod = rowtotal(att2016_5 att2016_6 att2016_7 att2016_8 ///
	att2016_9 att2016_10 att2016_11 att2016_12 att2017_1 att2017_2 att2017_3 ///
	att2017_4 att2017_5)
	
* Now calculate average past att of preperiod
gen past = att_preperiod/13

* save output of the full YOTA pop dataset
save "$datadir/ymca_full_pop.dta", replace

```

### `Packet/Build/build_ymca_survey.do`
```stata

* First load treatment assignment csv and convert to dta
import delimited using  "$rawdir/ymca_treatment_assignment.csv", clear

** label the treatment var
label var treatment "Treatment assignment: (i) no public recognition, (ii) public recognition, (iii) chosen via BDM elicitation"

label define T 0 "No PR" 1 "PR" 2 "BDM"
label values treatment T


save "$tempdir/ymca_treatment_assignment.dta", replace

*Load csv file
import delimited using  "$rawdir/ymca_survey_data.csv", clear

* merge on treatment assignment
merge 1:1 survey using "$tempdir/ymca_treatment_assignment.dta", nogen

* Create bdm assignment dummy
gen bdm = (treatment == 2)
label var bdm "PR chosen by BDM"

* Create dummy for PR treatment
gen image = (treatment == 1)
replace image = . if bdm == 1 // exclude those who endogenously chose PR
label var bdm "Randomly assigned to PR"

* Renaming Beliefs variables
rename q25 beliefs_morethan4
rename q26_1 beliefs_w_image
rename q27_1 beliefs_wout_image
rename q28_1 beliefs_wout_exp
rename q30_1 beliefs_w_1
rename q30_2 beliefs_w_3
rename q31_1 payment1
rename q71_1 payment3

* Recode beliefs_morethan4 (currently 1 = yes, 2 = no)
replace beliefs_morethan4 = 0 if beliefs_morethan4 == 2

* label belief vars
label var beliefs_morethan4 "Will you attend more than 4x this month? (1 = yes)"
label var beliefs_w_image "Believed att. with PR"
label var beliefs_wout_image "Believed att. without PR"
label var beliefs_wout_exp "Believed att. if not in experiment"
label var beliefs_w_1 "Believed att. with $1 incentive"
label var beliefs_w_3 "Believed att. with $3 incentive"
label var payment1 "WTP for $1 incentive"
label var payment3 "WTP for $3 incentive"


/******************************************************************************************
*Generating WTP variables and switch counts (changing preferences for image as visits increase) 

times_x_1: preference for PR if attend in interval x 
times_x_no_1: WTP to avoid PR if attend in interval x 
times_x_yes_1: WTP to have PR if attend in interval x 

******************************************************************************************/

gen switch = 0
gen switch_yes_no = 0

gen temp = (times_0_1 == 2) // set value for first iteration of loop

*generate image var, wtp var, and check for switches
	foreach x in 0 1 2 3 4 56 78 912 1317 1822 2328 {
		
		gen image`x' = (times_`x'_1 == 2)
		
		gen wtp`x' = -1* times_`x'_no_1 if image`x' == 0
		replace wtp`x' = times_`x'_yes_1 if image`x' == 1
		
		replace switch = switch + 1 if image`x' != temp
		replace switch_yes_no = switch_yes_no + 1 if image`x' < temp
		
		replace temp = image`x'
	}

*************************************************************
* Record "incoherent" responses
*************************************************************
* coherent: exclude ... -> yes -> no -> yes -> ...
gen coherent = 1
replace coherent = 0 if switch > 2
replace coherent = 0 if image0 == 1 & switch == 2

* monotonic
gen monotonic = 1
replace monotonic = 0 if switch_yes_no > 0

* generate sample variables
gen inexperiment = 1

gen coherent_sample = 1
replace coherent_sample = 0 if coherent == 0 | bdm == 1
label var coherent_sample "Coherent sample"

gen robust_sample = 1
replace robust_sample = 0 if bdm == 1
label var robust_sample "Full sample"

gen monotonic_sample = 1
replace monotonic_sample = 0 if monotonic == 0 | bdm == 1
label var monotonic_sample "Monotonic sample"

* prepare for merge
keep wtp* image* beliefs* payment* inexperiment bdm coherent monotonic coherent_sample robust_sample monotonic_sample switch* survey_id ymca_id

save "$tempdir/survey_data.dta", replace


****************************
** Merge on attendance data 
****************************

merge 1:m ymca_id using "$datadir/ymca_full_pop.dta"

* create interaction term vars for regressions
gen imagep = image * past
gen imageatt = image * attendance
gen attendance2 = attendance^2


* label variables for regressions
label var imagep "PR $\times$ Avg. past att."
label var imageatt "PR $\times$ Predicted no-SR-att"
label var image "Public recognition"
label var past "Avg. past att."
label var beliefs_w_image "Beliefs"
label var attendance "att."


* drop unmatched obs
drop if _merge == 1 // one obs, likely entered wrong email

* create id variable
gen id = _n

* order most relevant vars
order id coherent_sample monotonic_sample image attendance wtp*

* gen inexp =0
replace inexperiment = 0 if _merge != 3
drop _merge 

* save build for structural estimation
save "$datadir/structural_build.dta", replace

* restrict to experiment population
drop if inexperiment == 0 // not in experiment

* save build of experimental population
save "$datadir/experiment_build.dta", replace

```

### `Packet/Analysis/Code/charity_model_selection.do`
```stata
/******************************************************************************
	Polynomial model selection analysis for charity experiments
	
	Creates Tables A18-A20
******************************************************************************/
set more off

** Load cleaned data **
use "$datadir/charity_cleaned_data", clear

* exclude QM 221
drop if sample == "BU QM221"

** Declare locals **
* Excluding those who failed the attention check
loc flag = "flag_attention_check == 0"

* Excluding those who failed the consistency criterion
loc excl "consistent_b == 1"

* List of samples
loc samples "Prolific Berkeley BU"

* Rename variables
foreach round in anom recog earn{
	rename `round'pts pts`round'
	}

* Reshape data
reshape long pts, i(id) j(round) string

* Generate indicators for round
gen SR = (round == "recog")
gen ownpay = (round == "earn")

** Reshape data & generate variables for WTP analysis **
reshape long wtp nwtp, i(id round) j(interval)

* Generate ingredients for indicator of avg round points "close" to midpoint
gen interval_midpoint = (interval + .5)*100

* Transform interval variable
gen int_no = interval

replace interval = interval + .5
gen interval2 = interval^2

gen int_pts = interval * 100
gen int_pts2 = int_pts^2

gen pts00 = pts/100

encode sample, gen(s_no)

gen interval3 = interval^3
gen interval4 = interval^4
gen interval5 = interval^5
gen interval6 = interval^6

label var interval "Points (00s)"
label var interval2 "Points (00s)$^2$"
label var interval3 "Points (00s)$^3$"
label var interval4 "Points (00s)$^4$"


* Generate model selection tables
forval s = 1/3 {
di "************************************************************************"
di "Sample `s'"
di "************************************************************************"

****************************************************************************
* (1) Linear
****************************************************************************
reg wtp interval if s_no == `s' & flag_attention_check == 0  & consistent_b == 1 & interval < 17, clus(id)
eststo poly1`s'

estat ic
loc b: di %12.0fc r(S)[1,6] 

estadd local BIC "`b'"
estadd local dBIC "--"


****************************************************************************
* (2) Quadratic
****************************************************************************
reg wtp interval interval2 if s_no == `s' & flag_attention_check == 0  & consistent_b == 1 & interval < 17, clus(id)
eststo poly2`s'

estadd local Fstat = "--"
estadd local pval = "--"

estat ic
loc b: di %12.0fc r(S)[1,6]
loc b_q = r(S)[1,6] 

loc db_q: di %4.2fc  r(S)[1,6] - `b_q'

estadd local BIC "`b'"
estadd local dBIC "--"


****************************************************************************
* (3) Cubic
****************************************************************************
reg wtp interval interval2 interval3 if s_no == `s' & flag_attention_check == 0  & consistent_b == 1 & interval < 17, clus(id)
eststo poly3`s'

estat ic
loc b: di %12.0fc r(S)[1,6]

loc db_q: di %4.2fc  r(S)[1,6] - `b_q'

estadd local BIC "`b'"
estadd local dBIC "`db_q'"


****************************************************************************
* (4) Quartic
****************************************************************************
reg wtp interval interval2 interval3 interval4 if s_no == `s' & flag_attention_check == 0  & consistent_b == 1 & interval < 17, clus(id)
eststo poly4`s'


estat ic
loc b: di %12.0fc r(S)[1,6]

loc db_q: di %4.2fc  r(S)[1,6] - `b_q'

estadd local BIC "`b'"
estadd local dBIC "`db_q'"


}

* With points bunching
gen pts500 = (interval > 4.5)
gen pts1000 = (interval > 9.5) 
gen pts1500 = (interval > 14.5) 

label var pts500 "Points $\geq$ 500"
label var pts1000 "Points $\geq$ 1000"
label var pts1500 "Points $\geq$ 1500"


* pts specs 
forval s = 1/3 {
di "************************************************************************"
di "Sample `s'"
di "************************************************************************"

****************************************************************************
* (1) Linear
****************************************************************************
reg wtp interval pts500 pts1000 pts1500 if s_no == `s' & flag_attention_check == 0  & consistent_b == 1 & interval < 17, clus(id)
eststo poly1`s'_round

estadd local Fstat = "--"
estadd local pval = "--"

estat ic
loc b: di %12.0fc r(S)[1,6] 

estadd local BIC "`b'"
estadd local dBIC "--"

****************************************************************************
* (2) Quadratic
****************************************************************************
reg wtp interval interval2 pts500 pts1000 pts1500 if s_no == `s' & flag_attention_check == 0  & consistent_b == 1 & interval < 17, clus(id)
eststo poly2`s'_round

estadd local Fstat = "--"
estadd local pval = "--"

estat ic
loc b: di %12.0fc r(S)[1,6]
loc b_q = r(S)[1,6] 

loc db_q: di %4.2fc  r(S)[1,6] - `b_q'

estadd local BIC "`b'"
estadd local dBIC "--"

estadd local LRstat = "--"
estadd local LRpval = "--"

****************************************************************************
* (3) Cubic
****************************************************************************
reg wtp interval interval2 interval3 pts500 pts1000 pts1500 if s_no == `s' & flag_attention_check == 0  & consistent_b == 1 & interval < 17, clus(id)
eststo poly3`s'_round

test interval3
loc Ftemp: di %4.2f r(F)
loc ptemp: di %4.2f r(p)
estadd local Fstat = "`Ftemp'"
estadd local pval = "`ptemp'"

estat ic
loc b: di %12.0fc r(S)[1,6]

loc db_q: di %4.2fc  r(S)[1,6] - `b_q'

estadd local BIC "`b'"
estadd local dBIC "`db_q'"



****************************************************************************
* (4) Quartic
****************************************************************************
reg wtp interval interval2 interval3 interval4 pts500 pts1000 pts1500 if s_no == `s' & flag_attention_check == 0  & consistent_b == 1 & interval < 17, clus(id)
eststo poly4`s'_round

test interval3 interval4
loc Ftemp: di %4.2f r(F)
loc ptemp: di %4.2f r(p)
estadd local Fstat = "`Ftemp'"
estadd local pval = "`ptemp'"

estat ic
loc b: di %12.0fc r(S)[1,6]

loc db_q: di %4.2fc  r(S)[1,6] - `b_q'

estadd local BIC "`b'"
estadd local dBIC "`db_q'"



*****************************************
* Output table
*****************************************
esttab poly1`s' poly2`s' poly3`s' poly4`s' poly1`s'_round poly2`s'_round poly3`s'_round poly4`s'_round using "$outputdir\polynomial`s'_bunch.tex", replace b(3) se(3) order(interval interval2 interval3 interval4 pts500 pts1000 pts1500) eqlabels(none) label starlevels( * 0.10 ** 0.05 *** 0.010) nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi }" "\setlength{\tabcolsep}{1pt}" "\begin{tabular}{l*{@M}{c}}" "\hline") prefoot("\hline") postfoot("\hline" "\end{tabular}") mlabels(none) nonumbers posthead("& (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\" "Dependent var. & WTP & WTP & WTP & WTP & WTP & WTP & WTP & WTP \\ \hline")  nonum stats(BIC N N_clust, l("BIC" "\hline Observations" "N. Subjects") fmt(%12.0fc %8.0f)) nonum nonotes nogaps

}

```

### `Packet/Analysis/Code/ymca_impact_of_pr_on_attendance.do`
```stata
******************************************************************************
* Generates Figure A2, Table 2, and Table A7
******************************************************************************


use "$datadir/experiment_build.dta", replace

gen Mon = monotonic_sample
gen Coh = coherent_sample
gen All = robust_sample // not included as table in paper

* Effects of PR on att tables
foreach s in Mon Coh {

	* Identify median past attendance
	sum past if `s' == 1, detail
	scalar median_pa = r(p50)
	

	* Regressions for table: impact of sr on attendance
	reg attendance image if `s' == 1, r
	eststo reg1`s'
	estadd local Sample "`s'"
	
	ci means attendance if `s' == 1 & image == 0
	loc ctrl_mean: di %4.2f r(mean)
	loc ctrl_se: di %4.2f r(se)
	estadd local cmean `ctrl_mean'
	estadd local cse "(`ctrl_se')"

	reg attendance image past if `s' == 1, r 
	eststo reg2`s'
	estadd local Sample "`s'"
	
	ci means attendance if `s' == 1 & image == 0
	loc ctrl_mean: di %4.2f r(mean)
	loc ctrl_se: di %4.2f r(se)
	estadd local cmean `ctrl_mean'
	estadd local cse "(`ctrl_se')"
	
	reg attendance image past beliefs_w_image if `s' == 1, r
	eststo reg3`s'
	estadd local Sample "`s'"
	
	ci means attendance if `s' == 1 & image == 0
	loc ctrl_mean: di %4.2f r(mean)
	loc ctrl_se: di %4.2f r(se)
	estadd local cmean `ctrl_mean'
	estadd local cse "(`ctrl_se')"
	
}

		esttab reg1Mon reg2Mon reg3Mon using "$outputdir\sr_on_attendance_Mon.tex", replace b(2) se(2) label  drop(_cons) starlevels( * 0.10 ** 0.05 *** 0.010) nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi }" "\setlength{\tabcolsep}{1pt}" "\begin{tabular}{l*{@M}{c}}" "\hline") prefoot("\hline") postfoot("\hline" "\end{tabular}") mlabels(none) nonumbers posthead("& (1) & (2) & (3)  \\ \hline") nonotes stats(cmean cse N, l("Control mean" " " "\hline N. Subjects") fmt(%8.0f %8.0f %8.0f %8.0f)) sfmt(0)

	
	esttab reg1Coh reg2Coh reg3Coh using "$outputdir\sr_on_attendance_Coh.tex", replace b(2) se(2) label  drop(_cons) starlevels( * 0.10 ** 0.05 *** 0.010) nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi }" "\setlength{\tabcolsep}{1pt}" "\begin{tabular}{l*{@M}{c}}" "\hline") prefoot("\hline") postfoot("\hline" "\end{tabular}") mlabels(none) nonumbers posthead("& (1) & (2) & (3) \\ \hline") nonotes stats(cmean cse N, l("Control mean" " " "\hline N. Subjects") fmt(%8.0f %8.0f %8.0f %8.0f)) sfmt(0)

	est clear


********************************************************
* Figure comparing actual and predicted PR attendance
********************************************************
gen relevant_beliefs = .
replace relevant_beliefs = beliefs_wout_image if image == 0
replace relevant_beliefs = beliefs_w_image if image == 1

label var relevant_beliefs "Beliefs about future attendance"
label var attendance "Attendance during the experiment"	

foreach s in Coh {
	preserve 

	keep if `s' == 1

	xtile belief_quantile = relevant_beliefs, n(10)
	bysort belief_quantile: egen att_bin = mean(attendance)
	bysort belief_quantile: egen belief_bin = mean(relevant_beliefs)

	collapse belief_bin att_bin, by(belief_quantile)

	gen fortyfive = 0
	replace fortyfive = 25 if belief_quantile == 10

	twoway (scatter att_bin belief_bin, mc(dknavy)) ///
		(lfit att_bin belief_bin, lpattern(solid) lwidth(thin) color(dknavy)) /// 
		(line fortyfive fortyfive, lc(gs10) lpattern(dash)), ///
		xtitle(Beliefs about future attendance) ///
		ytitle("Attendance" "during the" "experiment", orientation(horizontal) placement(n) size(small)) ///
		ylabel(,angle(0)) ///
		xscale(range(0 25)) ///
		plotregion(fcolor(white) lcolor(white)) ///
		graphregion(fcolor(white) lcolor(white)) ///
		legend(off)

	graph export "$outputdir/beliefs_att`s'.pdf", replace
	
	restore 
}
```

### `Packet/Analysis/Code/ymca_piped_values.do`
```stata
************************************************************************************
* Generate Table 1 and many values displayed in text related to the YMCA experiment.
************************************************************************************

** Create a program to write to a latex file **
cap rm "$outputdir/numbersSR1.tex" // remove old version
cap program drop latex_write
program define latex_write
	if "`c(os)'" == "MacOSX" local command \\newcommand{\\\`1'}{`2'}
	else local command \newcommand{\\`1'}{`2'}
	! echo `command'  >> "$outputdir/numbersSR1.tex"
end
cap rm "numbersSR1.tex"


use "$datadir/experiment_build.dta", replace

***************************************************************
* % attendance increase (coherent_sample, control for past att)
***************************************************************
reg attendance image past if coherent_sample == 1, r 

scalar tau = _b[image]

sum attendance if image == 0 & coherent_sample == 1

scalar a0Coh = r(mean)

loc attincpt: di %4.0f tau/a0Coh * 100
latex_write attincpt `attincpt'

loc anoPR: di %4.1f a0Coh
latex_write anoPR `anoPR'

******************************************
* Avg att. stats
******************************************
use "$datadir/structural_build.dta", replace

* avg YOTA attendance
sum attendance if inexp == 0

loc YOTAatt: di %4.2f r(mean)
latex_write YOTAatt `YOTAatt'

* avg past att: YOTA
sum past if inexp == 0

loc YOTApastatt: di %4.2f r(mean)
latex_write YOTApastatt `YOTApastatt'

* avg past att: coh sample
sum past if coherent_sample == 1

loc Cohpastatt: di %4.2f r(mean)
latex_write Cohpastatt `Cohpastatt'

* avg past att: below/above median
sum past if coherent_sample == 1, detail
loc split = r(p50)

sum past if coherent_sample == 1 & past < `split'
loc Cohbelowmedpastatt: di %4.2f r(mean)
latex_write Cohbelowmedpastatt `Cohbelowmedpastatt'

sum past if coherent_sample == 1 & past >= `split'
loc Cohabovemedpastatt: di %4.2f r(mean)
latex_write Cohabovemedpastatt `Cohabovemedpastatt'

*SD of attendance less May attendance
gen diff_att_exp_may = attendance - att2017_5
sum diff_att_exp_may if coherent_sample == 1
loc CohSDattmonth: di %4.2f r(sd)
latex_write CohSDattmonth `CohSDattmonth'


******************************************
* # with always 0
******************************************
use "$datadir/experiment_build.dta", replace

unab wtp_list: wtp*

gen count_zero = 0

foreach var in `wtp_list' {
	replace count_zero = count_zero + (`var' == 0)
}
replace count_zero = max(count_zero-10, 0)
sum count_zero if coherent_sample == 1

loc notalwayszero: di %4.0f (1-r(mean))*100
latex_write notalwayszero `notalwayszero'

*******************************************
* Effects of PR on att for Coh, non-Mon
*******************************************
reg attendance image past if coherent_sample == 1 & monotonic_sample == 0

loc mean_effect: di %4.2f r(table)[1,1]
loc lb_effect: di %4.2f r(table)[5,1]
loc ub_effect: di %4.2f r(table)[6,1]

latex_write PReffectCohnonMon `mean_effect'
latex_write PReffectlbCohnonMon `lb_effect'
latex_write PReffectubCohnonMon `ub_effect'

reg attendance image if coherent_sample == 1 & monotonic_sample == 0

loc mean_effect: di %4.2f r(table)[1,1]
loc lb_effect: di %4.2f r(table)[5,1]
loc ub_effect: di %4.2f r(table)[6,1]

latex_write PReffectCohnonMonnopast `mean_effect'
latex_write PReffectlbCohnonMonnopast `lb_effect'
latex_write PReffectubCohnonMonnopast `ub_effect'

*******************************************
* balance tables
*******************************************

use "$datadir/experiment_build.dta", replace

* Set the sample
local sample coherent_sample

unab wtp_list: wtp*

foreach var in `wtp_list' {
	bysort id: egen temp = total(`var') if inexp == 1
	replace `var' = temp
	drop temp
}

** generating average individual WTP 
egen sum_individual_wtp= rowtotal(`wtp_list'), missing

* Generating average individual WTP 
gen avgwtp= sum_individual_wtp/11

* Rename variables for piping
ren beliefs_w_image beliefsSR
ren beliefs_wout_image beliefsnoSR

* ttest tables with standard deviations.  Generates std. dev for table 1.
local ttest_list avgwtp past beliefsSR beliefsnoSR female age

foreach var in `ttest_list' {
	ttest `var' if `sample' == 1, by(image)
	
	local sdnoSR : di %4.2f r(sd_1)
	local sdSR : di %4.2f r(sd_2)
	local mnoSR : di %4.2f r(mu_1)
	local mSR : di %4.2f r(mu_2)
	local pval : di %4.2f r(p)	
	
	latex_write `var'sdnoSR `sdnoSR'
	latex_write `var'sdSR `sdSR'
	latex_write `var'mnoSR `mnoSR'
	latex_write `var'mSR `mSR'
	latex_write `var'pval `pval'
	
	* write N
	if `var' == avgwtp {
		local NnoSR : di %4.0f r(N_1)
		local NSR : di %4.0f r(N_2)
		local Ntot = `NnoSR' + `NSR'
		
		latex_write NnoSR `NnoSR'
		latex_write NSR `NSR'
		latex_write Ntot `Ntot'
	}
}

********************************************
* standard deviations of past - current att.
********************************************

use "$datadir/structural_build.dta", replace

gen diff = past - attendance 
sum diff if inexp == 0

local sd : di %4.2f r(sd)
latex_write SDpastYOTA `sd'

sum diff if coherent_sample == 1 & image == 0

local sd : di %4.2f r(sd)
latex_write SDpastCoh `sd'

sum diff if monotonic_sample == 1 & image == 0

local sd : di %4.2f r(sd)
latex_write SDpastMon `sd'


sum attendance if inexp == 0
scalar avg_att_mainpop = r(mean)
scalar sd_mainpop = r(sd)

loc mean : di %4.2f r(mean)
loc sd : di %4.2f r(sd)

latex_write avgattYOTA `mean'
latex_write SDYOTA `sd'

scalar avg_att_mainpop2 = avg_att_mainpop^2


sum attendance if inexp == 0
scalar avg_att_mainpop = r(mean)
scalar avg_att_mainpop2 = avg_att_mainpop^2


*transform attendance
gen att_int = attendance
replace att_int = 4.5 + 1/3*(attendance -4 ) if attendance <=8 & attendance >= 5
replace att_int = 6.5 + 1/5 *(attendance -8) if attendance <=12 & attendance >= 9
replace att_int = 7.5 + 1/6*(attendance -12) if attendance <=22 & attendance >= 13
replace att_int = 9.5 + 1/10*(attendance -22) if attendance <=31 & attendance >= 23

sum att_int if inexp == 0
loc sd_int_mainpop : di %4.2f r(sd)

latex_write SDintYOTA `sd_int_mainpop'

********************************************
* Fraction of people with beliefs >=23, >=18
********************************************
use "$datadir/experiment_build.dta", replace

gen Mon = monotonic_sample
gen Coh = coherent_sample

gen above23 = (beliefs_w_image >= 23)
gen above18 = (beliefs_w_image >= 18)

foreach s in Mon Coh {
		sum above23 if `s' == 1
		local m23 : di %4.2f r(mean)
		latex_write abovetwentythree`s' `m23'
		
		sum above18 if `s' == 1
		local m18 : di %4.2f r(mean)
		latex_write aboveeighteen`s' `m18'
}

********************************************
* WTP = 0 Tobit tests
********************************************
* Reshape long
reshape long wtp, i(id) j(interval)

* gen visits variables
gen visits = 0
replace visits = 1 if interval == 1
replace visits = 2 if interval == 2
replace visits = 3 if interval == 3
replace visits = 4 if interval == 4
replace visits = 5.5 if interval == 56
replace visits = 7.5 if interval == 78
replace visits = 10.5 if interval == 912
replace visits = 15 if interval == 1317
replace visits = 20 if interval == 1822
replace visits = 26.5 if interval == 2328

gen visits2 = visits^2

* generate close visits
gen visitsL = 0
replace visitsL = 1 if interval == 1
replace visitsL = 2 if interval == 2
replace visitsL = 3 if interval == 3
replace visitsL = 4 if interval == 4
replace visitsL = 5 if interval == 56
replace visitsL = 7 if interval == 78
replace visitsL = 9 if interval == 912
replace visitsL = 13 if interval == 1317
replace visitsL = 18 if interval == 1822
replace visitsL = 23 if interval == 2328

gen visitsU = 0
replace visitsU = 1 if interval == 1
replace visitsU = 2 if interval == 2
replace visitsU = 3 if interval == 3
replace visitsU = 4 if interval == 4
replace visitsU = 6 if interval == 56
replace visitsU = 8 if interval == 78
replace visitsU = 12 if interval == 912
replace visitsU = 17 if interval == 1317
replace visitsU = 22 if interval == 1822
replace visitsU = 31 if interval == 2328

gen closeb = abs(visits - beliefs_w_image)

* Run tobit -- close beliefs
foreach s in Mon Coh {
	tobit wtp visits visits2 if `s' == 1 & closeb <= 4, ll ul vce(cluster id)

	* Test of significance at 0 attendance using Tobit
	lincom (_b[_cons] + _b[visits]*0 + _b[visits2]*0)

	** store coefficient
	local mean : di %4.2f r(estimate)
	local lb : di %4.2f r(lb)
	local ub : di %4.2f r(ub)
	local p : di %4.2f r(p)

	latex_write est`s'Tobitzerocloseb `mean'
	latex_write lb`s'Tobitzerocloseb `lb'
	latex_write ub`s'Tobitzerocloseb `ub'
	latex_write p`s'Tobitzerocloseb `p'

	* Test of significance at 1 attendance using Tobit
	lincom (_b[_cons] + _b[visits]*1 + _b[visits2]*1)

	** store coefficient
	local mean : di %4.2f r(estimate)
	local lb : di %4.2f r(lb)
	local ub : di %4.2f r(ub)
	local p : di %4.2f r(p)

	latex_write est`s'Tobitonecloseb `mean'
	latex_write lb`s'Tobitonecloseb `lb'
	latex_write ub`s'Tobitonecloseb `ub'
	latex_write p`s'Tobitonecloseb `p'

	* Test of significance at 2 attendances using Tobit
	lincom (_b[_cons] + _b[visits]*2 + _b[visits2]*4)

	** store coefficient
	local mean : di %4.2f r(estimate)
	local lb : di %4.2f r(lb)
	local ub : di %4.2f r(ub)
	local p : di %4.2f r(p)

	latex_write est`s'Tobittwocloseb `mean'
	latex_write lb`s'Tobittwocloseb `lb'
	latex_write ub`s'Tobittwocloseb `ub'
	latex_write p`s'Tobittwocloseb `p'


	* Test of significance at 4 attendances using Tobit
	lincom (_b[_cons] + _b[visits]*4 + _b[visits2]*16)

	** store coefficient
	local mean : di %4.2f r(estimate)
	local lb : di %4.2f r(lb)
	local ub : di %4.2f r(ub)
	local p : di %4.2f r(p)

	latex_write est`s'Tobitfourcloseb `mean'
	latex_write lb`s'Tobitfourcloseb `lb'
	latex_write ub`s'Tobitfourcloseb `ub'
	latex_write p`s'Tobitfourcloseb `p'

		
	* Test of significance at avg attendance using Tobit
	lincom (_b[_cons] + _b[visits]*avg_att_mainpop + _b[visits2]*avg_att_mainpop2)

	** store coefficient
	local mean : di %4.2f r(estimate)
	local lb : di %4.2f r(lb)
	local ub : di %4.2f r(ub)
	local p : di %4.2f r(p)

	latex_write est`s'TobitMcloseb `mean'
	latex_write lb`s'TobitMcloseb `lb'
	latex_write ub`s'TobitMcloseb `ub'
	latex_write p`s'TobitMcloseb `p'
}

* Run tobit -- all
foreach s in Mon Coh {
	tobit wtp visits visits2 if `s' == 1, ll ul vce(cluster id)

	* Test of significance at 0 attendance using Tobit
	lincom (_b[_cons] + _b[visits]*0 + _b[visits2]*0)

	** store coefficient
	local mean : di %4.2f r(estimate)
	local lb : di %4.2f r(lb)
	local ub : di %4.2f r(ub)
	local p : di %4.2f r(p)

	latex_write est`s'Tobitzeroall `mean'
	latex_write lb`s'Tobitzeroall `lb'
	latex_write ub`s'Tobitzeroall `ub'
	latex_write p`s'Tobitzeroall `p'

	* Test of significance at 1 attendance using Tobit
	lincom (_b[_cons] + _b[visits]*1 + _b[visits2]*1)

	** store coefficient
	local mean : di %4.2f r(estimate)
	local lb : di %4.2f r(lb)
	local ub : di %4.2f r(ub)
	local p : di %4.2f r(p)

	latex_write est`s'Tobitoneall `mean'
	latex_write lb`s'Tobitoneall `lb'
	latex_write ub`s'Tobitoneall `ub'
	latex_write p`s'Tobitoneall `p'

	* Test of significance at 2 attendances using Tobit
	lincom (_b[_cons] + _b[visits]*2 + _b[visits2]*4)

	** store coefficient
	local mean : di %4.2f r(estimate)
	local lb : di %4.2f r(lb)
	local ub : di %4.2f r(ub)
	local p : di %4.2f r(p)

	latex_write est`s'Tobittwoall `mean'
	latex_write lb`s'Tobittwoall `lb'
	latex_write ub`s'Tobittwoall `ub'
	latex_write p`s'Tobittwoall `p'


	* Test of significance at 4 attendances using Tobit
	lincom (_b[_cons] + _b[visits]*4 + _b[visits2]*16)

	** store coefficient
	local mean : di %4.2f r(estimate)
	local lb : di %4.2f r(lb)
	local ub : di %4.2f r(ub)
	local p : di %4.2f r(p)

	latex_write est`s'Tobitfourall `mean'
	latex_write lb`s'Tobitfourall `lb'
	latex_write ub`s'Tobitfourall `ub'
	latex_write p`s'Tobitfourall `p'

		
	* Test of significance at avg attendance using Tobit
	lincom (_b[_cons] + _b[visits]*avg_att_mainpop + _b[visits2]*avg_att_mainpop2)

	** store coefficient
	local mean : di %4.2f r(estimate)
	local lb : di %4.2f r(lb)
	local ub : di %4.2f r(ub)
	local p : di %4.2f r(p)

	latex_write est`s'TobitMall `mean'
	latex_write lb`s'TobitMall `lb'
	latex_write ub`s'TobitMall `ub'
	latex_write p`s'TobitMall `p'
}


********************************************
* WTP = 0 Imputed test
********************************************
* imputed wtp tests -- close beliefs
	foreach s in Mon Coh {
	reg wtp if `s' == 1 & visits == 3
	eststo v3

	reg wtp if `s' == 1 & visits == 4
	eststo v4

	suest v3 v4, cluster(id)
	lincom (avg_att_mainpop - 3)*[v3_mean]_cons + (4 - avg_att_mainpop)*[v4_mean]_cons

	local mean : di %4.2f r(estimate)
	local lb : di %4.2f r(lb)
	local ub : di %4.2f r(ub)
	local p : di %4.2f r(p)

	latex_write est`s'imputeMcloseb `mean'
	latex_write lb`s'imputeMcloseb `lb'
	latex_write ub`s'imputeMcloseb `ub'
	latex_write p`s'imputeMcloseb `p'
}

* imputed wtp tests -- all
	foreach s in Mon Coh {
	reg wtp if closeb <=4 & `s' == 1 & visits == 3
	eststo v3

	reg wtp if closeb <=4 & `s' == 1 & visits == 4
	eststo v4

	suest v3 v4, cluster(id)
	lincom (avg_att_mainpop - 3)*[v3_mean]_cons + (4 - avg_att_mainpop)*[v4_mean]_cons

	local mean : di %4.2f r(estimate)
	local lb : di %4.2f r(lb)
	local ub : di %4.2f r(ub)
	local p : di %4.2f r(p)

	latex_write est`s'imputeMall `mean'
	latex_write lb`s'imputeMall `lb'
	latex_write ub`s'imputeMall `ub'
	latex_write p`s'imputeMall `p'
}

**********************************************************
* Beliefs
**********************************************************

use "$datadir/experiment_build.dta", replace

* set sample
local sample coherent_sample

* Create variables to estimate/compare predicted impact
gen pred_impact_gt = beliefs_wout_image - beliefs_wout_exp
gen pred_impact_sr = beliefs_w_image - beliefs_wout_image
gen pred_impact_fin = beliefs_w_1 - beliefs_wout_image

* Record CI of predicted impact

foreach var in gt sr fin {

	ci means pred_impact_`var'
	
	** store in numbers file
	local mean : di %4.2f r(mean)
	local lb : di %4.2f r(lb)
	local ub : di %4.2f r(ub)
	
	latex_write `var'Pred `mean'
	latex_write `var'Predlb `lb'
	latex_write `var'Predub `ub'
}

* Compare predicted/actual impact of public recognition

qui reg pred_impact_sr if `sample' == 1
eststo p_sr
qui reg attendance image past if `sample' == 1
eststo a_sr

suest p_sr a_sr, cluster(id)
lincom [p_sr_mean]_cons - [a_sr_mean]image

*** write results to tex
local a :  di %4.2f e(b)[1,3]

local mean : di %4.2f r(estimate)
local lb : di %4.2f r(lb)
local ub : di %4.2f r(ub)
local p : di %4.2f r(p)

latex_write SRactual `a'
latex_write diffSR `mean'
latex_write diffSRlb `lb'
latex_write diffSRub `ub'
latex_write diffSRpval `p'
```

### `Packet/Analysis/Code/ymca_reduced_form_pr_function.do`
```stata
******************************************************************************************
* Creates Tables 3-4 and Tables A1-A6.
******************************************************************************************

* store standard deviation of attendance from whole population
use "$datadir/structural_build.dta", replace

sum attendance if inexp == 0
scalar avg_att_mainpop = r(mean)
scalar avg_att_mainpop2 = avg_att_mainpop^2
scalar sd_mainpop = r(sd)

*transform attendance
gen att_int = attendance
replace att_int = 4.5 + 1/3*(attendance -4 ) if attendance <=8 & attendance >= 5
replace att_int = 6.5 + 1/5 *(attendance -8) if attendance <=12 & attendance >= 9
replace att_int = 7.5 + 1/6*(attendance -12) if attendance <=22 & attendance >= 13
replace att_int = 9.5 + 1/10*(attendance -22) if attendance <=31 & attendance >= 23

sum att_int if inexp == 0
scalar sd_int_mainpop = r(sd)

* Now load survey data
use "$datadir/experiment_build.dta", replace


* Define motivation variables
gen motivation = payment1 - 0.5 * (beliefs_w_1 + beliefs_wout_image)
label var motivation "WTP motivation"

* Reshape long
reshape long wtp, i(id) j(interval)

* gen visits variables
gen visits = 0
replace visits = 1 if interval == 1
replace visits = 2 if interval == 2
replace visits = 3 if interval == 3
replace visits = 4 if interval == 4
replace visits = 5.5 if interval == 56
replace visits = 7.5 if interval == 78
replace visits = 10.5 if interval == 912
replace visits = 15 if interval == 1317
replace visits = 20 if interval == 1822
replace visits = 26.5 if interval == 2328

gen visits2 = visits^2

* generate close visits
gen visitsL = 0
replace visitsL = 1 if interval == 1
replace visitsL = 2 if interval == 2
replace visitsL = 3 if interval == 3
replace visitsL = 4 if interval == 4
replace visitsL = 5 if interval == 56
replace visitsL = 7 if interval == 78
replace visitsL = 9 if interval == 912
replace visitsL = 13 if interval == 1317
replace visitsL = 18 if interval == 1822
replace visitsL = 23 if interval == 2328

gen visitsU = 0
replace visitsU = 1 if interval == 1
replace visitsU = 2 if interval == 2
replace visitsU = 3 if interval == 3
replace visitsU = 4 if interval == 4
replace visitsU = 6 if interval == 56
replace visitsU = 8 if interval == 78
replace visitsU = 12 if interval == 912
replace visitsU = 17 if interval == 1317
replace visitsU = 22 if interval == 1822
replace visitsU = 31 if interval == 2328

* generate interval index
gen interval_idx = 0
replace interval_idx = 1 if interval == 1
replace interval_idx = 2 if interval == 2
replace interval_idx = 3 if interval == 3
replace interval_idx = 4 if interval == 4
replace interval_idx = 5 if interval == 56
replace interval_idx = 6 if interval == 78
replace interval_idx = 7 if interval == 912
replace interval_idx = 8 if interval == 1317
replace interval_idx = 9 if interval == 1822
replace interval_idx = 10 if interval == 2328

gen interval_idx2 = interval_idx^2

label var interval_idx "Interval no."
label var interval_idx2 "Interval no. sq."

* generate ln visits
gen ln_visits = ln(1 + visits)

gen ln_visits2 = ln_visits^2

label var ln_visits "ln(1 $+$ visits)"
label var ln_visits2 "ln(1 $+$ visits) sq."


* Change definition of close
gen closep = abs(visits - past)
gen closeb = abs(visits - beliefs_w_image)
local close_var closep

* Generate new variables
label var visits "N. visits"
label var visits2 "N. visits sq."
label var wtp "WTP"

gen visitsp = visits * past
gen visits2p = visits2 * past

label var visitsp "N. visits $\times$ Past att."
label var visits2p "N. visits sq. $\times$ Past att."

gen visitsw = visits * motivation
gen visits2w = visits2 * motivation

label var visitsw "N. visits $\times$ WTP motiv."
label var visits2w "N. visits sq. $\times$ WTP motiv."

gen origin = visits == 0


* write program to recover curv. ci
cap program drop get_ci

program define get_ci, rclass
	nlcom -2*_b[`2']/(_b[`1']+2*_b[`2']*avg_att_mainpop)

	scalar l = r(b)[1,1]- (invnormal(.975)*(sqrt(r(V)[1,1])))
	scalar u = r(b)[1,1]+ (invnormal(.975)*(sqrt(r(V)[1,1])))

	local lb : di %4.3f l
	local ub : di %4.3f u
	
	
	scalar l_sd = l*`3'
	scalar u_sd = u*`3'
	
	local lb_sd : di %4.3f l_sd
	local ub_sd : di %4.3f u_sd
	
	
	return loc alpha: di %4.3f r(b)[1,1]
	return loc alpha_sd: di %4.3f r(b)[1,1]*`3'
	
	return loc ci : di "[`lb', `ub']"
	return loc ci_sd : di "[`lb_sd', `ub_sd']"
end

* shorten sample names for loop
gen Mon = monotonic_sample
gen Coh = coherent_sample
gen All = robust_sample





*****************************************************************************
* Tables using all intervals for each individual
*****************************************************************************
est clear

foreach s in Mon Coh {
	* OLS regressions 
	
	**(1)**
	reg wtp visits if `s' == 1, cluster(id)
	eststo
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	
	**(2)**
	reg wtp visits visits2 if `s' == 1, cluster(id)
	eststo
	estadd local sample = substr("`s'",1,3)
	
	qui get_ci visits visits2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"
	
	* Tobit regressions
	
	**(3)**
	tobit wtp visits if `s' == 1, ll ul vce(cluster id)
	eststo
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	
	**(4)**
	tobit wtp visits visits2 if `s' == 1, ll ul vce(cluster id)
	eststo
	estadd local sample = substr("`s'",1,3)
	
	qui get_ci visits visits2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"
	
* output 
esttab using "$outputdir\rf_sr_`s'.tex", replace b(2) se(2) eqlabels(none) drop(var(e.wtp)) label starlevels( * 0.10 ** 0.05 *** 0.010) nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi }" "\setlength{\tabcolsep}{1pt}" "\begin{tabular}{l*{@M}{c}}" "\hline") prefoot("\hline") postfoot("\hline" "\end{tabular}") mlabels(none) nonumbers posthead("& (1) & (2) & (3) & (4) \\" "Model & OLS & OLS & Tobit & Tobit \\" "Dependent var. & WTP & WTP & WTP & WTP \\ \hline") nonum stats(alpha c_int alpha_sd c_int_sd N N_clust, l("$-\textrm{R}^{''}/\textrm{R}^{'}(\bar{a}\textsubscript{pop})$" "95\% CI" "$-\textrm{R}^{''}/\textrm{R}^{'}(\bar{a}\textsubscript{pop}) \times $ SD" "95\% CI" " \hline Observations" "N. Subjects") fmt(%8.0f)) nonotes nogaps

est clear
}


*****************************************************************************
* Table restricting to near beliefs
*****************************************************************************
est clear

foreach s in Coh Mon {
	* Regressions w/in 4 of beliefs
	
	**(1)**
	reg wtp visits if `s' == 1 & closeb <= 4, cluster(id)
	eststo olslin4`s'
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local subsample = "$\leq 4$"
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	
	**(2)**
	reg wtp visits visits2 if `s' == 1 & closeb <= 4, cluster(id)
	eststo olsquad4`s'
	estadd local sample = substr("`s'",1,3)
	estadd local subsample = "$\leq 4$"
	
	qui get_ci visits visits2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"
	
	**(3)**
	tobit wtp visits if `s' == 1 & closeb <= 4, ll ul vce(cluster id)
	eststo tobitlin4`s'
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local subsample = "$\leq 4$"
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	
	**(4)**
	tobit wtp visits visits2 if `s' == 1 & closeb <= 4, ll ul vce(cluster id)
	eststo tobitquad4`s'
	estadd local sample = substr("`s'",1,3)
	estadd local subsample = "$\leq 4$"
	
	qui get_ci visits visits2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"
	
	* Exact
	
	**(5)**
	reg wtp visits if `s' == 1 & beliefs_w_image <= visitsU & beliefs_w_image >= visitsL, cluster(id)
	eststo olslinexact`s'
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local subsample = "Exact"
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	
	**(6)**
	reg wtp visits visits2 if `s' == 1 & beliefs_w_image <= visitsU & beliefs_w_image >= visitsL, cluster(id)
	eststo olsquadexact`s'
	estadd local sample = substr("`s'",1,3)
	estadd local subsample = "Exact"
	
	qui get_ci visits visits2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"
	
	**(7)**
	tobit wtp visits if `s' == 1 & beliefs_w_image <= visitsU & beliefs_w_image >= visitsL, ll ul vce(cluster id)
	eststo tobitlinexact`s'
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local subsample = "Exact"
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	
	**(8)**
	tobit wtp visits visits2 if `s' == 1 & beliefs_w_image <= visitsU & beliefs_w_image >= visitsL, ll ul vce(cluster id)
	eststo tobitquadexact`s'
	estadd local sample = substr("`s'",1,3)
	estadd local subsample = "Exact"
	
	qui get_ci visits visits2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"

	* output 
	
	esttab olslin4`s' olsquad4`s' tobitlin4`s' tobitquad4`s' olslinexact`s' olsquadexact`s' tobitlinexact`s' tobitquadexact`s' using "$outputdir\rf_sr_belief_`s'.tex", replace b(2) se(2) eqlabels(none) drop(var(e.wtp)) label starlevels( * 0.10 ** 0.05 *** 0.010) nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi }" "\setlength{\tabcolsep}{1pt}" "\begin{tabular}{l*{@M}{c}}" "\hline") prefoot("\hline") postfoot("\hline" "\end{tabular}") mlabels(none) nonumbers posthead("& (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\" "Model & OLS & OLS & Tobit & Tobit & OLS & OLS & Tobit & Tobit \\" "Dependent var. & WTP & WTP & WTP & WTP & WTP & WTP & WTP & WTP \\ \hline")  nonum stats(alpha c_int alpha_sd c_int_sd subsample N N_clust, l("$-\textrm{R}^{''}/\textrm{R}^{'}(\bar{a}\textsubscript{pop})$" "95\% CI" "$-\textrm{R}^{''}/\textrm{R}^{'}(\bar{a}\textsubscript{pop}) \times $ SD" "95\% CI" " \hline Restriction " "Observations" "N. Subjects") fmt(%8.0f %8.0f %8.0f %8.0f %8.0f)) nonum nonotes nogaps
	
}

est clear

*****************************************************************************
* Tables restricting highest intervals 
*****************************************************************************
est clear

foreach s in Coh {
	* Regressions w/in excl top interval
	
	**(1)**
	reg wtp visits if `s' == 1 & visitsL <= 22, cluster(id)
	eststo olslintop`s'
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local subsample = "Top"
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	
	**(2)**
	reg wtp visits visits2 if `s' == 1 & visitsL <= 22, cluster(id)
	eststo olsquadtop`s'
	estadd local sample = substr("`s'",1,3)
	estadd local subsample = "Top"
	
	qui get_ci visits visits2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"
	
	**(3)**
	tobit wtp visits if `s' == 1 & visitsL <= 22, ll ul vce(cluster id)
	eststo tobitlintop`s'
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local subsample = "Top"
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	
	**(4)**
	tobit wtp visits visits2 if `s' == 1 & visitsL <= 22, ll ul vce(cluster id)
	eststo tobitquadtop`s'
	estadd local sample = substr("`s'",1,3)
	estadd local subsample = "Top"
	
	qui get_ci visits visits2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"
	
	* Regressions w/in excl top intervals
	
	**(5)**
	reg wtp visits if `s' == 1 & visitsL <= 17, cluster(id)
	eststo olslintop2`s'
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local subsample = "Top 2"
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	
	**(6)**
	reg wtp visits visits2 if `s' == 1 & visitsL <= 17, cluster(id)
	eststo olsquadtop2`s'
	estadd local sample = substr("`s'",1,3)
	estadd local subsample = "Top 2"
	
	qui get_ci visits visits2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"
	
	**(7)**
	tobit wtp visits if `s' == 1 & visitsL <= 17, ll ul vce(cluster id)
	eststo tobitlintop2`s'
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local subsample = "Top 2"
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	
	**(8)**
	tobit wtp visits visits2 if `s' == 1 & visitsL <= 17, ll ul vce(cluster id)
	eststo tobitquadtop2`s'
	estadd local sample = substr("`s'",1,3)
	estadd local subsample = "Top 2"
	
	qui get_ci visits visits2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"

	* output 
	esttab olslintop`s' olsquadtop`s' tobitlintop`s' tobitquadtop`s' olslintop2`s' olsquadtop2`s' tobitlintop2`s' tobitquadtop2`s'  using "$outputdir\rf_sr_excl_top_`s'.tex", replace b(2) se(2) eqlabels(none) drop(var(e.wtp)) label starlevels( * 0.10 ** 0.05 *** 0.010) nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi }" "\setlength{\tabcolsep}{1pt}" "\begin{tabular}{l*{@M}{c}}" "\hline") prefoot("\hline") postfoot("\hline" "\end{tabular}") mlabels(none) nonumbers posthead("& (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\" "Model & OLS & OLS & Tobit & Tobit & OLS & OLS & Tobit & Tobit \\" "Dependent var. & WTP & WTP & WTP & WTP & WTP & WTP & WTP & WTP \\ \hline")  stats(alpha c_int alpha_sd c_int_sd sample subsample N N_clust, l("$-\textrm{R}^{''}/\textrm{R}^{'}(\bar{a}\textsubscript{pop})$" "95\% CI" "$-\textrm{R}^{''}/\textrm{R}^{'}(\bar{a}\textsubscript{pop}) \times $ SD" "95\% CI" " \hline Excl. int." "Observations" "N. Subjects") fmt(%8.0f %8.0f %8.0f %8.0f %8.0f %8.0f)) nonum nonotes nogaps
	
	
}

est clear

*****************************************************************************
* Tables using the w/in 4 of past att. restriction
*****************************************************************************
est clear

foreach s in Coh {
	* OLS regressions 
	
	**(1)**
	reg wtp visits if `s' == 1 & closep <= 4, cluster(id)
	eststo
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	
	**(2)**
	reg wtp visits visits2 if `s' == 1 & closep <= 4, cluster(id)
	eststo
	estadd local sample = substr("`s'",1,3)
	
	qui get_ci visits visits2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"
	
	* Tobit regressions
	
	**(3)**
	tobit wtp visits if `s' == 1 & closep <= 4, ll ul vce(cluster id)
	eststo
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	
	**(4)**
	tobit wtp visits visits2 if `s' == 1 & closep <= 4, ll ul vce(cluster id)
	eststo
	estadd local sample = substr("`s'",1,3)
	
	qui get_ci visits visits2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"

	* output 
	esttab using "$outputdir\rf_sr_closep_`s'.tex", replace b(2) se(2) eqlabels(none) drop(var(e.wtp)) label starlevels( * 0.10 ** 0.05 *** 0.010) nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi }" "\setlength{\tabcolsep}{1pt}" "\begin{tabular}{l*{@M}{c}}" "\hline") prefoot("\hline") postfoot("\hline" "\end{tabular}") mlabels(none) nonumbers posthead("& (1) & (2) & (3) & (4) \\" "Model & OLS & OLS & Tobit & Tobit \\" "Dependent var. & WTP & WTP & WTP & WTP \\ \hline")  stats(alpha c_int alpha_sd c_int_sd N N_clust, l("$-\textrm{R}^{''}/\textrm{R}^{'}(\bar{a}\textsubscript{pop})$" "95\% CI" "$-\textrm{R}^{''}/\textrm{R}^{'}(\bar{a}\textsubscript{pop}) \times $ SD" "95\% CI" " \hline Observations" "N. Subjects") fmt(%8.0f %8.0f %8.0f %8.0f)) nonum nonotes nogaps
	
	est clear
}


*****************************************************************************
* Regressions on index no. instead of attendance
*****************************************************************************
est clear

foreach s in Coh {
	* OLS regressions 
	
	**(1)**
	reg wtp interval_idx if `s' == 1, cluster(id)
	eststo
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	
	**(2)**
	reg wtp interval_idx interval_idx2 if `s' == 1, cluster(id)
	eststo
	estadd local sample = substr("`s'",1,3)
	
	qui get_ci interval_idx interval_idx2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"
	
	* Tobit regressions
	
	**(3)**
	tobit wtp interval_idx if `s' == 1, ll ul vce(cluster id)
	eststo
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	
	**(4)**
	tobit wtp interval_idx interval_idx2 if `s' == 1, ll ul vce(cluster id)
	eststo
	estadd local sample = substr("`s'",1,3)
	
	qui get_ci interval_idx interval_idx2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"

	* output 
	esttab using "$outputdir\rf_sr_int_`s'.tex", replace b(2) se(2) eqlabels(none) drop(var(e.wtp)) label starlevels( * 0.10 ** 0.05 *** 0.010) nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi }" "\setlength{\tabcolsep}{1pt}" "\begin{tabular}{l*{@M}{c}}" "\hline") prefoot("\hline") postfoot("\hline" "\end{tabular}") mlabels(none) nonumbers posthead("& (1) & (2) & (3) & (4) \\" "Model & OLS & OLS & Tobit & Tobit \\" "Dependent var. & WTP & WTP & WTP & WTP \\ \hline") nonum stats(alpha c_int alpha_sd c_int_sd N N_clust, l("$-\textrm{R}^{''}/\textrm{R}^{'}(\bar{a}\textsubscript{pop})$" "95\% CI" "$-\textrm{R}^{''}/\textrm{R}^{'}(\bar{a}\textsubscript{pop}) \times $ SD" "95\% CI" " \hline Observations" "N. Subjects") fmt(%8.0f %8.0f %8.0f %8.0f)) nonum nonotes nogaps
	
	est clear
}

*****************************************************************************
* Reg on index no -- within 4 of beliefs restriction
*****************************************************************************
est clear

foreach s in Coh {
	* OLS regressions 
	
	**(1)**
	reg wtp interval_idx if `s' == 1 & closeb <= 4, cluster(id)
	eststo
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	
	**(2)**
	reg wtp interval_idx interval_idx2 if `s' == 1 & closeb <= 4, cluster(id)
	eststo
	estadd local sample = substr("`s'",1,3)
	
	qui get_ci interval_idx interval_idx2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"
	
	* Tobit regressions
	
	**(3)**
	tobit wtp interval_idx if `s' == 1 & closeb <= 4, ll ul vce(cluster id)
	eststo
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	
	**(4)**
	tobit wtp interval_idx interval_idx2 if `s' == 1 & closeb <= 4, ll ul vce(cluster id)
	eststo
	estadd local sample = substr("`s'",1,3)
	
	qui get_ci interval_idx interval_idx2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"

	* output 
	esttab using "$outputdir\rf_sr_int_closeb_`s'.tex", replace b(2) se(2) eqlabels(none) drop(var(e.wtp)) label starlevels( * 0.10 ** 0.05 *** 0.010) nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi }" "\setlength{\tabcolsep}{1pt}" "\begin{tabular}{l*{@M}{c}}" "\hline") prefoot("\hline") postfoot("\hline" "\end{tabular}") mlabels(none) nonumbers posthead("& (1) & (2) & (3) & (4) \\" "Model & OLS & OLS & Tobit & Tobit \\" "Dependent var. & WTP & WTP & WTP & WTP \\ \hline") stats(alpha c_int alpha_sd c_int_sd N N_clust, l("$-\textrm{R}^{''}/\textrm{R}^{'}(\bar{a}\textsubscript{pop})$" "95\% CI" "$-\textrm{R}^{''}/\textrm{R}^{'}(\bar{a}\textsubscript{pop}) \times $ SD" "95\% CI" " \hline Observations" "N. Subjects") fmt(%8.0f %8.0f %8.0f %8.0f)) nonum nonotes nogaps
	
	est clear
}



**********************************************************************
* Tables examining heterogeneity along WTP motiv 
**********************************************************************
est clear

foreach s in Coh {
	
	* identify median of sample
	qui sum motivation if `s' == 1, detail
	scalar split_value = r(p50)

	
	
	**(1), OLS regression, all**
	reg wtp visits visits2 motivation visitsw visits2w if `s' == 1, cluster(id)
	eststo
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	estadd local subsample = "All"

	**(2), Tobit regression, all**
	tobit wtp visits visits2 motivation visitsw visits2w if `s' == 1, ll ul vce(cluster id)
	eststo
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	estadd local subsample = "All"
	
	**(3), OLS regression, all**
	reg wtp visits visits2 motivation visitsw visits2w if `s' == 1 & closeb <= 4, cluster(id)
	eststo
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	estadd local subsample = "$\leq 4$"

	**(4), Tobit regression, all**
	tobit wtp visits visits2 motivation visitsw visits2w if `s' == 1 & closeb <= 4, ll ul vce(cluster id)
	eststo
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	estadd local subsample = "$\leq 4$"

	* output 
	esttab using "$outputdir\rf_sr_motiv_`s'.tex", replace b(2) se(2) eqlabels(none) drop(var(e.wtp)) label starlevels( * 0.10 ** 0.05 *** 0.010) nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi }" "\setlength{\tabcolsep}{1pt}" "\begin{tabular}{l*{@M}{c}}" "\hline") prefoot("\hline") postfoot("\hline" "\end{tabular}") mlabels(none) nonumbers posthead("& (1) & (2) & (3) & (4)\\" "Model & OLS & OLS & Tobit & Tobit \\" "Dependent var. & WTP & WTP & WTP & WTP \\ \hline") nonum stats(subsample N N_clust, l("Restriction" "Observations" "N. Subjects") fmt(%8.0f %8.0f %8.0f)) nonotes nogaps
	
	est clear
}



**********************************************************************
* Tables examining heterogeneity along past att.
**********************************************************************
est clear

foreach s in Coh {
	
	* identify median of sample
	qui sum past if `s' == 1, detail
	scalar split_value = r(p50)

	* OLS regressions 
	
	**(1)**
	reg wtp visits visits2 if `s' == 1 & past >= split_value, cluster(id)
	eststo
	estadd local subsample = "Above med."
	estadd local sample = substr("`s'",1,3)
	
	qui get_ci visits visits2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"
	
	**(2)**
	reg wtp visits visits2 if `s' == 1 & past < split_value, cluster(id)
	eststo
	estadd local subsample = "Below med."
	estadd local sample = substr("`s'",1,3)
	
	qui get_ci visits visits2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"
	
	**(3)**
	reg wtp visits visits2 past visitsp visits2p if `s' == 1, cluster(id)
	eststo
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	estadd local subsample = "--"

	* Tobit regressions
	
	**(4)**
	tobit wtp visits visits2 if `s' == 1 & past >= split_value, ll ul vce(cluster id)
	eststo
	estadd local subsample = "Above med."
	estadd local sample = substr("`s'",1,3)
	
	qui get_ci visits visits2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"
	
	**(5)**
	tobit wtp visits visits2 if `s' == 1 & past < split_value, ll ul vce(cluster id)
	eststo
	estadd local subsample = "Below med."
	estadd local sample = substr("`s'",1,3)
	
	qui get_ci visits visits2 sd_mainpop
	
	estadd local alpha = "`r(alpha)'"
	estadd local c_int = "`r(ci)'"
	estadd local alpha_sd = "`r(alpha_sd)'"
	estadd local c_int_sd = "`r(ci_sd)'"
	
	**(6)**
	tobit wtp visits visits2 past visitsp visits2p if `s' == 1, ll ul vce(cluster id)
	eststo
	estadd local alpha = "--"
	estadd local sample = substr("`s'",1,3)
	estadd local c_int = "--"
	estadd local alpha_sd = "--"
	estadd local c_int_sd = "--"
	estadd local subsample = "--"

	* output 
	esttab using "$outputdir\rf_sr_past_`s'.tex", replace b(2) se(2) eqlabels(none) drop(var(e.wtp)) label starlevels( * 0.10 ** 0.05 *** 0.010) nolines prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi }" "\setlength{\tabcolsep}{1pt}" "\begin{tabular}{l*{@M}{c}}" "\hline") prefoot("\hline") postfoot("\hline" "\end{tabular}") mlabels(none) nonumbers posthead("& (1) & (2) & (3) & (4)& (5) & (6) \\" "Model & OLS & OLS & OLS & Tobit & Tobit & Tobit \\" "Dependent var. & WTP & WTP & WTP & WTP & WTP & WTP \\ \hline") nonum stats(alpha c_int alpha_sd c_int_sd sample subsample N N_clust, l("$-\textrm{R}^{''}/\textrm{R}^{'}(\bar{a}\textsubscript{pop})$" "95\% CI" "$-\textrm{R}^{''}/\textrm{R}^{'}(\bar{a}\textsubscript{pop}) \times $ SD" "95\% CI" " \hline Restriction" "Observations" "N. Subjects") fmt(%8.0f %8.0f %8.0f %8.0f %8.0f %8.0f)) nonotes nogaps
	
	est clear
}



```

### `Packet/Analysis/Code/ymca_reduced_form_pr_function_figures.do`
```stata
***********************************************************************
* Generates Figures 3-6 and Figures A3-A7.
***********************************************************************

use "$datadir/experiment_build.dta", replace

* Set sample
gen Coh = coherent_sample
gen Mon = monotonic_sample // only results for coherent sample are included in paper

* Define potential split variables
gen motivation = payment1 - 0.5 * (beliefs_w_1 + beliefs_wout_image)

*********************************************************************
* Chart of cdf of attendance by image
*********************************************************************

foreach s in Coh {
	
	sort attendance
	cdfplot attendance if `s' == 1, by(image) opt1( lp(solid longdash) lc(dknavy maroon) lwidth(thin)) ///
		graphregion(fcolor(white) lcolor(white)) ///
		xtitle("Attendance") ///
		ytitle("") ///
		ylabel(,angle(0)) ///
		yscale(range(0 1)) ///
		xscale(range(0 31)) ///
		legend(label(1 "No public recognition") label(2 "Public recognition") ) ///

	graph export "$outputdir\cdf_att`s'.pdf", replace

}

*********************************************************************
* Demand curve for 0 att, 23-28 att
*********************************************************************
gen price = -9 + 1*_n if _n <=17

count if coherent_sample == 1
scalar cohN = r(N)

* negative vals: WTP > p

foreach int in 0 1 2 3 4 56 78 912 1317 1822 2328 {
	gen demand`int' = .

	forval p = 1(1)8 {
		qui count if coherent_sample == 1 & wtp`int' > -9 + `p'
		replace demand`int' = r(N)/cohN if _n == `p'
		
	}

	* positive vals: WTP >= p and image == 1
	qui count if coherent_sample == 1 & wtp`int' >= 0 & image`int' == 1
	replace demand`int' = r(N)/cohN if _n == 9
		
	* positive vals: WTP >= p
	forval p = 10(1)17 {
		qui count if coherent_sample == 1 & wtp`int' >= -9 + `p'
		replace demand`int' = r(N)/cohN if _n == `p'

	}								
}

		
twoway (line price demand0 if price >= -8 & price <= 8, lc(gs12) lpattern(dash) msymbol(none) ) ///
	(line price demand1 if price >= -8 & price <= 8, lc(gs11) lpattern(dash) msymbol(none) ) ///
	(line price demand2 if price >= -8 & price <= 8, lc(gs10) lpattern(dash) msymbol(none) ) ///
	(line price demand3 if price >= -8 & price <= 8, lc(gs8) lpattern(dash) msymbol(none) ) ///
	(line price demand4 if price >= -8 & price <= 8, lc(gs7) lpattern(dash) msymbol(none) ) ///
	(line price demand56 if price >= -8 & price <= 8, lc(gs7) lpattern(dot) msymbol(none) ) ///
	(line price demand78 if price >= -8 & price <= 8, lc(gs6) lpattern(shortdash_dot) msymbol(none) ) ///
	(line price demand912 if price >= -8 & price <= 8, lc(gs5) lpattern(shortdash) msymbol(none) ) ///
	(line price demand1317 if price >= -8 & price <= 8, lc(gs4) lpattern(dash) msymbol(none) ) ///
	(line price demand1822 if price >= -8 & price <= 8, lc(gs3) lpattern(longdash) msymbol(none) ) ///
	(line price demand2328 if price >= -8 & price <= 8, lc(gs2) lpattern(solid) msymbol(none) ) ///
	(scatteri 0 0.2 (6) "0.2" 0 0.4 (6) "0.4" 0 0.6 (6) "0.6" 0 0.8 (6) "0.8" 0 1 (6) "1", /// 
 ms(|) mlc(black) mlabsize(vsmall) mlabpos(6) mlabcolor(black) msize(*1.5)), ///
		graphregion(fcolor(white) lcolor(white) margin(3 15 1 3)) ///
		plotregion(fcolor(white) lcolor(white) margin(b = 0 r = 3) ) ///
		xtitle("Fraction demanding public recognition", size(small)) ///
		ytitle("Price" "($)", orientation(horizontal) placement(n) size(small)) ///
		ylabel(-8(2)8, angle(0) nogrid labsize(vsmall)) ///
		yline(0, lp(solid) lc(black) lwidth(thin) ) ///
		xscale(range(0 1) off) ///
		text(0 1.1 "Fraction" "demanding" "public" "recognition", size(small)) /// 
		legend (order(1 "0 att." 2 "1 att." 3 "2 att." 4 "3 att." ///
				5 "4 att." 6 "5-6 att." 7 "7-8 att." 8 "9-12 att." ///
				9 "13-17 att." 10 "18-22 att." 11 "{&ge} 23 att.") size(vsmall) symxsize(6) rows(2)) ///
		
graph export "$outputdir/demandcurves_all.pdf", replace

*********************************************************************
* Chart of cdf of attendance within interval
*********************************************************************

* generate fraction with att in each interval
gen attendance_int = attendance
replace attendance_int = 5 if attendance >=5 & attendance <= 6
replace attendance_int = 6 if attendance >=7 & attendance <= 8
replace attendance_int = 7 if attendance >=9 & attendance <= 12
replace attendance_int = 8 if attendance >=13 & attendance <= 17
replace attendance_int = 9 if attendance >=18 & attendance <= 22
replace attendance_int = 10 if attendance >=23

* create series
forval i = 0/10 {
gen att_int`i' = attendance_int < `i'
}

foreach s in Coh {
preserve 

	keep if `s' == 1
	collapse att_int*
	xpose, clear
	ren v1 att_int
	gen interval = _n - 1
	
	twoway (line att_int interval, c(stairstep) lc(dknavy) lwidth(thin) msymbol(none) ) ///
	(lfit att_int interval, estopts(nocons) lc(maroon) lpattern(longdash) lwidth(thin) msymbol(none)), ///
			plotregion(fcolor(white) lcolor(white)) ///
			graphregion(fcolor(white) lcolor(white)) ///
			xtitle("Interval no.") ///
			ytitle("") ///
			xscale(range(0 10)) ///
			xlab(0(1)10) ///
			yscale(range(0 1)) ///
			legend(label(1 "CDF") label(2 "Linear fit")) ///

graph export "$outputdir\cdf_att_int`s'.pdf", replace

restore
}


*********************************************************************
* WTP figure
*********************************************************************

* Reshape long
reshape long wtp, i(id) j(interval)

* create variable for x-axis
gen visits = 0
replace visits = 1 if interval == 1
replace visits = 2 if interval == 2
replace visits = 3 if interval == 3
replace visits = 4 if interval == 4
replace visits = 5.5 if interval == 56
replace visits = 7.5 if interval == 78
replace visits = 10.5 if interval == 912
replace visits = 15 if interval == 1317
replace visits = 20 if interval == 1822
replace visits = 26.5 if interval == 2328

gen visits2 = visits^2

* create close variable
gen closeb = abs(visits - beliefs_w_image)
local close = 4

* identify avg wtp
local avg_att_mainpop = 3.14


foreach s in Coh {

	if `s' == Coh {
		local sample_label = "Coherent"
	}

	* find avg wtp for each interval using w/in 4 of beliefs restriction
	 reg wtp ibn.interval if `s' == 1 & closeb <= `close', nocons cluster(id)

	* store output
	matrix temp_b = r(table)[1,1...]'
	matrix temp_ll = r(table)[5,1...]'
	matrix temp_ul = r(table)[6,1...]'

	svmat double temp_b, name(wtp_avg_point_cb`close')
	svmat double temp_ll, name(wtp_avg_lb_cb`close')
	svmat double temp_ul, name(wtp_avg_ub_cb`close')

	* create chart
	twoway (scatter wtp_avg_point_cb`close' visits, mcolor(dknavy) lpattern(none) msymbol(circle) ) ///
		(rcap wtp_avg_lb_cb`close' wtp_avg_ub_cb`close' visits, lpattern(dash) lwidth(thin) lcolor(dknavy) c(l) m(i) ) ///
		(qfit wtp_avg_point_cb`close' visits, color(maroon) lwidth(thin)), ///
		plotregion(fcolor(white) lcolor(white) margin(b = 0 r = 8)) ///
		graphregion(fcolor(white) lcolor(white)) ///
		xtitle("Visits") ///
		ytitle("WTP ($)", orientation(horizontal) placement(n)) ///
		yline(0, lpattern(dash) lwidth(thick) lcolor(gs11)) ///
		ylabel(-7.5(2.5)7.5, angle(0)) ///
		legend(off) ///	
		xline(`avg_att_mainpop', extend lwidth(thin) lcolor(red) lpattern(longdash)) ///

	graph export "$outputdir\rf_sr_`s'_cb`close'.pdf", replace
	
	drop wtp_avg_point_cb`close'1 wtp_avg_lb_cb`close'1 wtp_avg_ub_cb`close'1
	
}

**********************************************************************
* Reduced-form PR figure by past attendance
**********************************************************************
foreach s in Coh Mon {

	local sample_label = "Monotonic"

	if `s' == Coh {
		local sample_label = "Coherent"
	}
	
	foreach split in past motivation  {
	
		local split_label = "median past att."

		if "`split'" == "motivation" {
			local split_label = "median WTP motiv."
		}
		
		
		* Identify median `split' and choose split value
		qui sum `split' if `s' == 1, detail
		scalar split_value = r(p50)
		
		* Chart of avg WTP by visits
		bysort visits:  egen wtp_avg = mean(wtp) if `s' == 1
		bysort visits:  egen wtp_avg_above = mean(wtp) if `s' == 1 & `split' >= split_value
		bysort visits: 	egen wtp_avg_below = mean(wtp) if `s' == 1 & `split' < split_value
		label var wtp_avg "Avg. WTP"
		label var wtp_avg_above "Avg. WTP, {&ge} `split_label'"
		label var wtp_avg_below "Avg. WTP, < `split_label'"

		twoway (scatter wtp_avg visits if `s' == 1, mcolor(dknavy)  msymbol(circle) ) ///
			(scatter wtp_avg_above visits if `s' == 1, mcolor(maroon)  msymbol(+) ) ///
			(scatter wtp_avg_below visits if `s' == 1, mcolor(dkgreen*.8)  msymbol(X) ), ///
			plotregion(fcolor(white) lcolor(white)) ///
			graphregion(fcolor(white) lcolor(white)) ///
			xtitle("Visits") ///
			ytitle("WTP ($)", orientation(horizontal) placement(n)) ///
			yline(0, lpattern(dash) lwidth(thick) lcolor(gs11)) ///
			ylabel(-5(2.5)5, angle(0)) ///
			legend(label(1 "Full sample") label(2 "Above `split_label'") label(3 "Below `split_label'") height(8)) ///
			xline(`avg_att_mainpop', extend lwidth(thin) lcolor(red) lpattern(longdash)) ///


		graph export "$outputdir\rf_sr_het_`split'_`s'.pdf", replace
		
		drop wtp_avg wtp_avg_above wtp_avg_below
		
		}
}


**********************************************************************
* binscatter
**********************************************************************

* generate interval index
gen interval_idx = 0
replace interval_idx = 1 if interval == 1
replace interval_idx = 2 if interval == 2
replace interval_idx = 3 if interval == 3
replace interval_idx = 4 if interval == 4
replace interval_idx = 5 if interval == 56
replace interval_idx = 6 if interval == 78
replace interval_idx = 7 if interval == 912
replace interval_idx = 8 if interval == 1317
replace interval_idx = 9 if interval == 1822
replace interval_idx = 10 if interval == 2328

gen interval_idx2 = interval_idx^2

label var interval_idx "Interval no."
label var interval_idx2 "Interval no. sq."

label values interval_idx interval_label


* binscatters
foreach s in Coh {
	binscatter wtp interval_idx if `s' == 1 & closeb <= `close', line(qfit) nbins(11) ///
		graphregion(fcolor(white) lcolor(white)) ///
		xtitle(Interval of future attendance) ///
		xlab(0(1)10, valuelabel) ///
		yscale(range(-5 5)) ///
		ylab(-5(2.5)5) ///
		ytitle("WTP ($)", orientation(horizontal) placement(n) size(small)) ///
		yline(0, lpattern(dash) lwidth(thick) lcolor(gs11)) ///
		ylabel(-5(2.5)5, angle(0)) ///

	graph export "$outputdir\cb`close'_int_binscatter_`s'.pdf", replace

	binscatter wtp interval_idx if `s' == 1, line(qfit) nbins(11) ///
		graphregion(fcolor(white) lcolor(white)) ///
		xtitle(Interval of future attendance) ///
		ytitle("WTP ($)", orientation(horizontal) placement(n) size(small)) ///
		yscale(range(-5 5)) ///
		ylab(-5(2.5)5) ///
		xlab(0(1)10, valuelabel)  ///
		yline(0, lpattern(dash) lwidth(thick) lcolor(gs11)) ///
		ylabel(-5(2.5)5, angle(0)) ///

	graph export "$outputdir\int_binscatter_`s'.pdf", replace

}

**********************************************************************
* Reduced-form PR figure -- non-monotonic, but coherent
**********************************************************************
* Chart of avg WTP by visits
cap drop wtp_avg

bysort visits:  egen wtp_avg = mean(wtp) if coherent_sample == 1 & monotonic_sample == 0 

label var wtp_avg "Coherent, non-monotonic"


twoway (scatter wtp_avg visits if coherent_sample == 1 & monotonic_sample == 0, mcolor(dknavy) msymbol(circle) ), ///
	plotregion(fcolor(white) lcolor(white)) ///
	graphregion(fcolor(white) lcolor(white)) ///
	xtitle("Visits") ///
	ytitle("WTP ($)", orientation(horizontal) placement(n)) ///
	ylabel(-5(2.5)5, angle(0)) ///
	yline(0, lpattern(dash) lwidth(thick) lcolor(gs11)) ///
	xline(`avg_att_mainpop', extend lwidth(thin) lcolor(red) lpattern(longdash)) ///
	legend(on label(1 "Coherent, non-monotonic") height(8)) ///

graph export "$outputdir\rf_sr_coh_nonmon.pdf", replace

********************************************************************
* spikeplot of wtp by attendance
********************************************************************
* generate lower-bounds, upper-bounds for each int

gen visitslb = 0
replace visitslb = 1 if interval == 1
replace visitslb = 2 if interval == 2
replace visitslb = 3 if interval == 3
replace visitslb = 4 if interval == 4
replace visitslb = 5 if interval == 56
replace visitslb = 7 if interval == 78
replace visitslb = 9 if interval == 912
replace visitslb = 13 if interval == 1317
replace visitslb = 18 if interval == 1822
replace visitslb = 23 if interval == 2328

gen visitsub = 0
replace visitsub = 1 if interval == 1
replace visitsub = 2 if interval == 2
replace visitsub = 3 if interval == 3
replace visitsub = 4 if interval == 4
replace visitsub = 6 if interval == 56
replace visitsub = 8 if interval == 78
replace visitsub = 12 if interval == 912
replace visitsub = 17 if interval == 1317
replace visitsub = 22 if interval == 1822
replace visitsub = 28 if interval == 2328

** Create program for bootstrapping procedure **
capture program drop realized_wtp
program define realized_wtp, rclass

	* Generate placeholder variable
	gen interval_avg_wtp = .

	* Fill in values for average WTP in realized interval
	forval int = 0/10 {
		** Use "w/in 4" to identify average
		sum wtp if interval_idx == `int' & closeb <= 4
		** replace based on actual realized attendance
		replace interval_avg_wtp = r(mean) if attendance >= visitslb ///
			& attendance <= visitsub & interval_idx == `int' & image == 1
		}

	* Find mean average WTP for full sample
	reg interval_avg_wtp if image == 1, cluster(id)
	return scalar avg_wtp_all = _b[_cons]

	* Find & return mean average WTP in each quartile
	reg interval_avg_wtp quart_`1'_* if image == 1, nocons cluster(id)
	forval i = 1/4{
		return scalar avg_wtp_q`i' = _b[quart_`1'_`i']
		}
	
	* Drop variable
	drop interval_avg_wtp
		
end


** Create chart of average WTP in realized interval by PR att quartile **
* Generate quartiles based attendance with PR 


foreach s in Coh {

	* Generate an indicator for each quartile
	xtile quart_`s' = attendance if `s' == 1 & image == 1, nq(4)
	tab quart_`s', generate(quart_`s'_)

	* Store mean attendance by quartile
	forval i = 1/4{
		sum attendance if `s' == 1 & quart_`s'_`i' == 1 & image == 1
		loc attq`i'mean`s' : di %4.1f r(mean)
		}
		
	* Store mean attendance for sample (image = 1)
	sum attendance if `s' == 1 & image == 1
	loc attmean`s' : di %4.1f r(mean)
	
	preserve

	drop if `s' == 0
	
	* Generate estimates with bootstrapping
	bootstrap avg_wtp_all = r(avg_wtp_all) avg_wtp_q1 = r(avg_wtp_q1) ///
		avg_wtp_q2 = r(avg_wtp_q2) avg_wtp_q3 = r(avg_wtp_q3) ///
		avg_wtp_q4 = r(avg_wtp_q4), reps(1000) cluster(id) ///
		nodrop level(95) seed(`randseed'): realized_wtp `s'
	estat bootstrap, all
	
	* Store output
	matrix temp_b =  e(b)'
	matrix temp =    e(ci_percentile)'
	matrix temp_lb = temp[1...,1]
	matrix temp_ub = temp[1...,2]
	matrix temp_q =  (0 \ 1 \ 2 \ 3 \ 4)

	svmat double temp_b,  name(realized_wtp_avg_`s')
	svmat double temp_lb, name(realized_wtp_lb_`s')
	svmat double temp_ub, name(realized_wtp_ub_`s')
	svmat int    temp_q,  name(realized_wtp_gp_`s')
	
	
	* Plot means with CIs
	tw (sc realized_wtp_avg_`s' realized_wtp_gp_`s', color(dknavy)) ///
	   (rcap realized_wtp_ub_`s' realized_wtp_lb_`s' realized_wtp_gp_`s', lcolor(dknavy) lwidth(thin) lpattern(dash)), ///
	   xlab(-.5 " " 0 `""Full sample" "{it:`attmean`s''}""'  1 `""Quartile 1" "{it:`attq1mean`s''}""' 2 `""Quartile 2" "{it:`attq2mean`s''}""' 3 `""Quartile 3" "{it:`attq3mean`s''}""' 4 `""Quartile 4" "{it:`attq4mean`s''}""' 4.5 " ", noticks labgap(3)) ///
	   xtitle("Quartile of attendance {it:x}" "{it:Mean of x}", height(9)) ///
	   ytitle("WTP ($)", orientation(horizontal) placement(n)) ///
	   ylabel(-7.5(2.5)7.5, angle(0)) ///
	   legend(off) ///
	   graphregion(fcolor(white) lcolor(white)) ///
	   xtick(0 1 2 3 4) yline(0, lpattern(dash) lwidth(thick) lcolor(gs11))
	   graph export "$outputdir\wtp_att_quartile_nonpar_`s'.pdf", replace

	   
	restore
		
}


********************************************************************
* spikeplot of wtp by attendance -- tobit
********************************************************************

** Create program for bootstrapping procedure **
capture program drop realized_wtp_tobit
program define realized_wtp_tobit, rclass

	* Generate placeholder variable
	gen interval_avg_wtp = .
	
	* identify predicted wtp values
	tobit wtp visits visits2 if closeb <= 4, ll ul vce(cluster id)
	predict wtp_pred, xb

	* Fill in values for average WTP in realized interval
	forval int = 0/10 {
		** replace based on actual realized attendance
		replace interval_avg_wtp = wtp_pred if attendance >= visitslb ///
			& attendance <= visitsub & interval_idx == `int' & image == 1
		}

	* Find mean average WTP for full sample
	reg interval_avg_wtp if image == 1, cluster(id)
	return scalar avg_wtp_all = _b[_cons]

	* Find & return mean average WTP in each quartile
	reg interval_avg_wtp quart_`1'_* if image == 1, nocons cluster(id)
	forval i = 1/4{
		return scalar avg_wtp_q`i' = _b[quart_`1'_`i']
		}
	
	* Drop variable
	drop interval_avg_wtp wtp_pred
		
end


** Create chart of average WTP in realized interval by PR att quartile **
* Generate quartiles based attendance with PR 

foreach s in Coh {
	
	preserve

	drop if `s' == 0
	
	* Generate estimates with bootstrapping
	bootstrap avg_wtp_all = r(avg_wtp_all) avg_wtp_q1 = r(avg_wtp_q1) ///
		avg_wtp_q2 = r(avg_wtp_q2) avg_wtp_q3 = r(avg_wtp_q3) ///
		avg_wtp_q4 = r(avg_wtp_q4), reps(1000) cluster(id) ///
		nodrop level(95) seed(`randseed'): realized_wtp_tobit `s'
	estat bootstrap, all
	
	* Store output
	matrix temp_b =  e(b)'
	matrix temp =    e(ci_percentile)'
	matrix temp_lb = temp[1...,1]
	matrix temp_ub = temp[1...,2]
	matrix temp_q =  (0 \ 1 \ 2 \ 3 \ 4)

	svmat double temp_b,  name(realized_wtp_avg_`s')
	svmat double temp_lb, name(realized_wtp_lb_`s')
	svmat double temp_ub, name(realized_wtp_ub_`s')
	svmat int    temp_q,  name(realized_wtp_gp_`s')
	
	* Plot means with CIs
	tw (sc realized_wtp_avg_`s' realized_wtp_gp_`s', color(dknavy)) ///
	   (rcap realized_wtp_ub_`s' realized_wtp_lb_`s' realized_wtp_gp_`s', lcolor(dknavy) lwidth(thin) lpattern(dash)), ///
	   xlab(-.5 " " 0 `""Full sample" "{it:`attmean`s''}""'  1 `""Quartile 1" "{it:`attq1mean`s''}""' 2 `""Quartile 2" "{it:`attq2mean`s''}""' 3 `""Quartile 3" "{it:`attq3mean`s''}""' 4 `""Quartile 4" "{it:`attq4mean`s''}""' 4.5 " ", noticks labgap(3)) ///
	   xtitle("Quartile of attendance {it:x}" "{it:Mean of x}", height(9)) ///
	   ytitle("WTP ($)", orientation(horizontal) placement(n)) ///
	   ylabel(-7.5(2.5)7.5, angle(0)) ///
	   legend(off) ///
	   graphregion(fcolor(white) lcolor(white)) ///
	   xtick(0 1 2 3 4) yline(0, lpattern(dash) lwidth(thick) lcolor(gs11))
	   graph export "$outputdir\wtp_att_quartile`s'.pdf", replace

	   
	restore
		
}

```

## How to run a script

Write each script to a file under the output directory, then run it with
exactly this command (the data directory is mounted read-only at its own
path; nothing else from the host is visible; `$SCRIPT` is the absolute path of
the script you wrote):

    SCRIPT=<repo>/benchmark/reproductions/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-a/script.R   # or <repo>/benchmark/reproductions/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-a/attempt-<n>/script.R
    uv run --directory <repo> python -m benchmark.reproducers.run_sandbox --timeout 300 --label retally.run=claude-code-butera-2022-welfare-effects-shame-pride-seeded-2026-11-10-a --run-dir "$(dirname "$SCRIPT")" -- docker run --rm --label retally.run=claude-code-butera-2022-welfare-effects-shame-pride-seeded-2026-11-10-a --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride:<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R; echo "exit code: $?"

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

The output directory `<repo>/benchmark/reproductions/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-a` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-a/
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

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/butera-2022-welfare-effects-shame-pride/seeded/2026-11-10-a`.
