# Retally reproduction task: saccardo-2023-demand-moral-commitment (seeded, run 2026-11-10-a)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `saccardo-2023-demand-moral-commitment`, mode `seeded`, run `2026-11-10-a`
- Paper: Enabling or Limiting Cognitive Flexibility? Evidence of Demand for Moral Commitment
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a/mount/saccardo_2023_demand_moral_commitment`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a/mount/saccardo_2023_demand_moral_commitment` as data, and `<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a/paper.txt` as
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

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Claims to Reproduce
1. see_incentive_first_costly_table2_col1: -0.139 (change in the probability of preferring to see the incentive first) [type: coefficient]
   Location: Table 2, column (1), See Incentive First Costly
   Context: Table 2 ("Preference for Information Order"), column (1). Linear probability model of an indicator that the advisor prefers to see the incentive first (rather than assess the quality signal first) in the Choice experiment, on indicators for the Choice Free—Professionals, See Incentive First Costly and Assess Quality First Costly treatments (the Choice Free treatment on the AMT convenience sample is the omitted group), with controls for the advisor's gender and age, the wave of the experiment, whether incentives were probabilistic, the position of the products on the screen, and the interaction…
2. assess_quality_first_costly_table2_col1: 0.152 (change in the probability of preferring to see the incentive first) [type: coefficient]
   Location: Table 2, column (1), Assess Quality First Costly
   Context: Table 2, column (1): the same linear probability model of preferring to see the incentive first on the treatment indicators and controls. The entry is the Assess Quality First Costly coefficient (assessing quality first costs a third of the commission). Robust standard errors (HC3).
3. choice_free_professionals_table2_col1: -0.095 (change in the probability of preferring to see the incentive first) [type: coefficient]
   Location: Table 2, column (1), Choice Free—Professionals
   Context: Table 2, column (1): the same linear probability model. The entry is the Choice Free—Professionals coefficient (advisors who self-report working in finance and insurance or legal services, recruited on Prolific and CloudResearch, relative to the AMT Choice Free advisors). Robust standard errors (HC3).
4. selfishness_table2_col2: 0.028 (change in the probability of preferring to see the incentive first per standard deviation of selfishness) [type: coefficient]
   Location: Table 2, column (2), Selfishness
   Context: Table 2, column (2): the column (1) model with the advisor's Selfishness added, a standardized measure of the number of times the advisor chose to recommend the incentivized product in the five- decision multiple price list on moral costs, elicited at the end of the experiment (not elicited for the professionals, so this column covers the AMT treatments only). The entry is the Selfishness coefficient. Robust standard errors (HC3).
5. selfishness_table2_col3: 0.039 (change in the probability of preferring to see the incentive first per standard deviation of selfishness) [type: coefficient]
   Location: Table 2, column (3), Selfishness
   Context: Table 2, column (3): the column (2) model with the interactions of Selfishness with the See Incentive First Costly and the Assess Quality First Costly indicators added. The entry is the Selfishness main effect. Robust standard errors (HC3).
6. see_incentive_first_costly_x_selfishness_table2_col3: -0.022 (change in the selfishness slope of preferring to see the incentive first) [type: coefficient]
   Location: Table 2, column (3), See Incentive First Costly × Selfishness
   Context: Table 2, column (3): the same model with both interactions. The entry is the See Incentive First Costly × Selfishness coefficient. Robust standard errors (HC3).
7. see_quality_first_costly_x_selfishness_table2_col3: -0.021 (change in the selfishness slope of preferring to see the incentive first) [type: coefficient]
   Location: Table 2, column (3), See Quality First Costly × Selfishness
   Context: Table 2, column (3): the same model with both interactions. The entry is the See Quality First Costly × Selfishness coefficient (the interaction with the Assess Quality First Costly indicator). Robust standard errors (HC3).
8. n_obs_table2_col1: 5908.0 (advisors) [type: count]
   Location: Table 2, Observations, column (1)
   Context: Number of observations in Table 2, column (1): advisors in the four main Choice treatments, professionals included.
9. n_obs_table2_cols2_3: 5196.0 (advisors) [type: count]
   Location: Table 2, Observations, columns (2) and (3)
   Context: Number of observations in Table 2, columns (2) and (3): the advisors with the Selfishness measure (the AMT treatments, without the professionals).
10. prefer_see_incentive_first_assigned_table3_col1: 0.195 (change in the probability of recommending the incentivized product) [type: coefficient]
   Location: Table 3, column (1) Assigned pref., Prefer to See Incentive First
   Context: Table 3 ("Advisor Recommendations"), column (1). Linear probability model of an indicator that the advisor recommends the incentivized product, for advisors who were assigned their preferred information order, on Prefer to See Incentive First (the advisor's preference), a No Conflict indicator (the quality signal is not in conflict with the advisor's commission) and its interaction with Prefer to See Incentive First, the Choice Free—Professionals, See Incentive First Costly and Assess Quality First Costly indicators, an Incentive for B indicator, and controls for gender, age, wave, probabilist…
11. prefer_see_incentive_first_not_assigned_table3_col2: 0.003 (change in the probability of recommending the incentivized product) [type: coefficient]
   Location: Table 3, column (2) Not assigned pref., Prefer to See Incentive First
   Context: Table 3, column (2): the column (1) model for advisors who were not assigned their preferred information order. The entry is the Prefer to See Incentive First coefficient. Robust standard errors (HC3).
12. prefer_see_incentive_first_x_not_assigned_table3_col3: -0.14 (change in the probability of recommending the incentivized product) [type: coefficient]
   Location: Table 3, column (3) Both, Prefer to See Incentive First × Not Assigned Preference
   Context: Table 3, column (3): both groups pooled, with a Not Assigned Preference indicator (not receiving the preferred order) and its interactions with Prefer to See Incentive First and with No Conflict added to the column (1) regressors. The entry is the Prefer to See Incentive First × Not Assigned Preference coefficient. Robust standard errors (HC3).
13. n_obs_table3_col1: 4448.0 (advisors) [type: count]
   Location: Table 3, Observations, column (1)
   Context: Number of observations in Table 3, column (1): advisors in the main Choice treatments who were assigned their preferred information order.

## Dataset Information
Name: saccardo_2023_demand_moral_commitment
Local path: <repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a/mount/saccardo_2023_demand_moral_commitment
File format: csv
Files in the dataset directory (paths relative to the local path above):
- Data/Clean Data/Choice_coding_explanations.dta (2.3 MB) — 1749 rows, 125 columns: commission, conflict, choice, sample, professionals, prolific, cloudresearch, probabilistic_incentive, wave, treatment, choicebefore_getyourchoice, recommendincentive, flippedorder, selfish, professionalscloudresearch, _mergedecisions, incentiveshigh, professionalsfree, incentiveshigh_incentiveleft, commission_expl1, commission_expl2, qualitycostly, wave1, wave2, wave3, selfishseequalitycostly, seequalitycostly, commission_expl, signalblue, getbeforenoconflict, noconflict, ch…
- Data/Clean Data/choice_experiments.dta (7.1 MB) — 6976 rows, 94 columns: commission, conflict, choice, sample, professionals, prolific, cloudresearch, probabilistic_incentive, wave, treatment, choicebefore_getyourchoice, recommendincentive, flippedorder, selfish, professionalscloudresearch, incentiveshigh, professionalsfree, incentiveshigh_incentiveleft, qualitycostly, wave1, wave2, wave3, selfishseequalitycostly, seequalitycostly, signalblue, getbeforenoconflict, noconflict, choicebeforenoconflict, notgetyourchoicenoconflict, logsignalhigh, logsi…
- Data/Clean Data/nochoice1_2_merged.dta (911.5 KB) — 886 rows, 177 columns: gender, order, commission, signal, treatment, conflict, wave, choice, signalblue, inconsistentid, selfish, noconflict, seeincentivefirst_noconflict, recommendationb, recommendationa, recommendb, recommendincentive, recommendincentive_before, recommendincentive_after, incentiveforA, incentiveB, seeincentivefirst, incentiveA, q62_firstclick, q124_firstclick, q149_firstclick, q25_firstclick, q27_firstclick, q74_firstclick, q24_firstclick, q99_firstclick, q29_firstclick, q159_fir…
- Data/Clean Data/NoChoiceSimoultaneous.dta (524.5 KB) — 559 rows, 158 columns: gender, order, commission, signal, treatment, conflict, wave, signalblue, inconsistentid, noconflict, recommendationb, recommendationa, recommendb, recommendincentive, incentiveforA, incentiveB, seeincentivefirst, q62_firstclick, q124_first…
- Data/Clean Data/Choice_Deterministic.dta (739.2 KB) — 952 rows, 128 columns: gender, incentive, commission, signal, conflict, sample, choicebefore_getyourchoiceDet, sizecommission, recommenda, signalblue, costlydemand, inconsistentid, incentiveB, incentiveA, recommendincentive, recommendationa, recommendationb, reco…
- Data/Clean Data/stakes.dta (1.1 MB) — 1681 rows, 143 columns: gender, commission, signal, conflict, choice, signalblue, recommenda, inconsistentid, selfish, recommendincentive, incentiveB, noconflict, choicebeforenoconflict, notgetyourchoicenoconflict, recommendationa, recommendationb, recommendb, cho…
- Data/Clean Data/nochoice.dta (312.4 KB) — 327 rows, 133 columns: gender, treatment, conflict, choice, signalblue, inconsistentid, selfish, noconflict, seeincentivefirst_noconflict, recommendationb, recommendationa, recommendb, recommendincentive, recommendincentive_before, recommendincentive_after, incen…
- Data/Clean Data/predictionsstudy.dta (1.0 MB) — 288 rows, 121 columns: gender, treatment, choice, attentive, control1, response, attentivenum, q62_firstclick, q349_firstclick, q359_firstclick, q309_firstclick, q353_firstclick, q357_firstclick, q350_firstclick, q358_firstclick, q375_firstclick, q378_firstclick,…
- Data/Clean Data/InformationArchitect_advisors.dta (326.4 KB) — 498 rows, 115 columns: gender, conflict, treatment, id_advisor, dm_choicebefore, signalblue, inconsistentid, recommendincentive, incentiveforA, incentiveB, recommendationb, recommendationa, recommendb, q62_firstclick, q124_firstclick, q149_firstclick, q25_firstcl…
- Data/Clean Data/professionals.dta (522.0 KB) — 712 rows, 22 columns: sample, conflict, choice, recommendincentive, signalblue, costlydemand, choicebefore, explanationchoice, incentiveA, incentiveB, age, jobtitle, newid, shortid, currentcountryofresidence, industry, beliefbin, belief, getbefore, female, belie…
- Code/analysis.do (168.4 KB)
- Code/config.do (1.4 KB)
- Code/datacleaning.do (58.6 KB)
- Code/main.do (335 B)
- Data/Clean Data/Clients_Blinding.dta (17.6 KB)
- Data/Clean Data/Clients_ChoiceDeterministic_MPL.dta (13.5 KB)
- Data/Clean Data/Clients_ChoiceDeterministic_Main.dta (11.0 KB)
- Data/Clean Data/Clients_IAAdvisors_MPL.dta (10.0 KB)
- Data/Clean Data/Clients_IAInfoArchitects_MPL.dta (10.0 KB)
- Data/Clean Data/Clients_InfoArchitectsMain.dta (9.8 KB)
- Data/Clean Data/Clients_MPL.dta (60.1 KB)
- Data/Clean Data/Clients_Main.dta (79.6 KB)
- Data/Clean Data/Clients_NoChoiceSimultaneousMPL.dta (9.5 KB)
- Data/Clean Data/Clients_NoChoiceSimultaneousMain.dta (8.5 KB)
- Data/Clean Data/InformationArchitect.dta (358.0 KB)
- Data/Clean Data/predictions_explanations_coded.dta (333.1 KB)
- Data/Clean Data/professionals_jobtitles.dta (157.0 KB)
- Data/Raw Data/Choice1_deidentified.csv (1.8 MB) — columns: startdate,enddate,status,progress,durationinseconds,finished,recordeddate,responseid,distributionchannel,userlanguage,q60_1,q60_2,q60_3,q62_firstclick,q62_lastclick,q62_pagesubmit,q62_clickcount,q39,q124_firstclick,q124_lastclick,q124_pages…
- Data/Raw Data/Choice2_deidentified.csv (1.4 MB) — columns: startdate,enddate,status,progress,durationinseconds,finished,recordeddate,responseid,distributionchannel,userlanguage,q_recaptchascore,q_relevantidduplicate,q_relevantidduplicatescore,q_relevantidfraudscore,q_relevantidlaststartdate,q60_1,q…
- Data/Raw Data/Choice3_deidentified.csv (1.7 MB) — columns: startdate,enddate,status,progress,durationinseconds,finished,recordeddate,responseid,distributionchannel,userlanguage,q_recaptchascore,q_relevantidduplicate,q_relevantidduplicatescore,q_relevantidfraudscore,q_relevantidlaststartdate,q60_1,q…
- Data/Raw Data/ChoiceDeterministic_deidentified.csv (744.3 KB) — columns: startdate,enddate,status,progress,durationinseconds,finished,recordeddate,responseid,distributionchannel,userlanguage,q_recaptchascore,q_relevantidduplicate,q_relevantidduplicatescore,q_relevantidfraudscore,q_relevantidlaststartdate,q60_1,q…
- Data/Raw Data/Choice_explanations_deidentified.xlsx (235.1 KB)
- Data/Raw Data/Clients/Clients_Blinding_deidentified.csv (12.2 KB) — columns: recommendation_infoavoidance,ia_quality,sample,client_startdate,client_enddate,choice1,experiment,clientid_short
- Data/Raw Data/Clients/Clients_ChoiceDeterministic_MPL_deidentified.csv (6.3 KB) — columns: incentiveb,advisor_lotteryrowselected,odds_2dollarsx,advisor_recommends_producty,highqualitympl,sample,client_startdate,client_enddate,client_choicey,experiment,clientid_short
- Data/Raw Data/Clients/Clients_ChoiceDeterministic_Main_deidentified.csv (4.2 KB) — columns: incentiveb,signalblue,advisor_recommendb,highquality,highincentive,sample,client_startdate,client_enddate,client_choiceb,clientid_short
- Data/Raw Data/Clients/Clients_IAAdvisors_MPL_deidentified.csv (3.1 KB) — columns: incentiveb,advisor_lotteryrowselected,odds_2dollarsx,advisor_recommends_producty,highqualitympl,sample,client_startdate,client_enddate,client_choicey,clientid_short
- Data/Raw Data/Clients/Clients_IAInfoArchitects_MPL_deidentified.csv (3.1 KB) — columns: incentiveb,advisor_lotteryrowselected,odds_2dollarsx,advisor_recommends_producty,highqualitympl,sample,client_startdate,client_enddate,client_choicey,clientid_short
- Data/Raw Data/Clients/Clients_InfoArchitectsMain_deidentified.csv (2.8 KB) — columns: incentiveb,signalblue,advisor_recommendb,highquality,highincentive,sample,client_startdate,client_enddate,client_choiceb,clientid_short
- Data/Raw Data/Clients/Clients_MPL_deidentified.csv (50.6 KB)
- Data/Raw Data/Clients/Clients_Main_deidentified.csv (59.6 KB)
- Data/Raw Data/Clients/Clients_NoChoiceSimultaneousMPL_deidentified.csv (2.4 KB)
- Data/Raw Data/Clients/Clients_NoChoiceSimultaneousMain_deidentified.csv (2.0 KB)
- Data/Raw Data/InformationArchitect_Advisor_deidentified.csv (206.9 KB)
- Data/Raw Data/InformationArchitect_deidentified.csv (319.9 KB)
- Data/Raw Data/NoChoiceSimoultaneous_deidentified.csv (466.8 KB)
- Data/Raw Data/NoChoice_deidentified.csv (203.8 KB)
- Data/Raw Data/ProfessionalsCloudresearch_deidentified.csv (151.5 KB)
- Data/Raw Data/ProfessionalsProlific_deidentified.csv (373.6 KB)
- Data/Raw Data/Professionals_jobtitles.xlsx (41.2 KB)
- Data/Raw Data/Stakes_deidentified.csv (1.2 MB)
- Data/Raw Data/predictions_deidentified.xlsx (291.2 KB)
- Data/Raw Data/predictions_explanations_coded_deidentified.xlsx (24.4 KB)
- Qualtrics/Choice3.qsf (779.1 KB)
- Qualtrics/Clients_ProductA.qsf (27.8 KB)
- Qualtrics/Clients_ProductB.qsf (23.2 KB)
- Qualtrics/NoChoice.qsf (311.4 KB)
- Qualtrics/Predictions.qsf (773.4 KB)
- Qualtrics/Professionals_CloudResearch.qsf (599.5 KB)
- Qualtrics/Professionals_Prolific.qsf (590.1 KB)
- Qualtrics/Revision-Choice_Deterministic.qsf (744.3 KB)
- Qualtrics/Revision-InformationArchitect.qsf (758.1 KB)
- Qualtrics/Stakes.qsf (611.1 KB)
- README.pdf (190.5 KB)
- metadata.json (240 B)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a/mount/saccardo_2023_demand_moral_commitment' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
Installed packages (no network; nothing else can be installed): jsonlite, fixest, lfe, AER, ivreg, plm, estimatr, lme4, quantreg, car, sandwich, lmtest, clubSandwich, multiwayvcov, marginaleffects, MatchIt, optmatch, CBPS, WeightIt, cobalt, did, rdrobust, rddensity, Synth, modelsummary, stargazer, texreg, broom, tidyverse, dplyr, tidyr, readr, stringr, lubridate, data.table, haven, readxl, janitor, zoo, ggplot2, ggridges, ggrepel, gridExtra, cowplot, gtable, extrafont, sf, MASS, nnet, survival, splines, Matrix, boot, stats, utils.
Prefer fixest for fixed effects, IV and clustered SEs; use the other installed packages where the paper's method calls for them.
Set a deterministic seed with ``set.seed(42)`` for any randomness.
Do NOT access the internet; the container runs with --network none.
Do NOT shell out via system() / system2().
Emit RESULT:<name>=<value> lines to stdout at the end via cat().

## Original Replication Scripts
The replication package (the dataset directory) ships the authors' own analysis scripts, reproduced below.  These are the GROUND TRUTH for the exact estimating equation, variable names, sample restrictions, fixed effects, and standard-error clustering — follow them over anything reconstructed from the methodology summary, and prefer them over the paper's text where the two disagree.  Your job is to write R code that implements the SAME SPECIFICATION: translate what the scripts estimate, do not transliterate their syntax line by line (a Stata .do file's regression, e.g. `reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the equivalent fixest::feols() call in R).  Keep only the parts that produce the specific claims being reproduced; skip figure construction and unrelated robustness checks.  The scripts' data-file paths refer to the package's internal layout — resolve them against the dataset directory listed under Dataset Information.

Stata-to-fixest sample matching: feols() drops fixed-effect singletons by default, but Stata's `reg y x i.fe` / `xi:` dummies keep them.  Pass `fixef.rm = "none"` to every feols() call that has fixed effects, otherwise the observation count and the robust SEs drift from the paper's.  Stata's `, r` / `vce(robust)` is `vcov = "hetero"`.

### `Code/analysis.do`
```stata

************************************************************************************************************************************
*** CLIENTS -MAIN TEXT ****
************************************************************************************************************************************

clear
u "${data}Clients_Main.dta"
*** We recruited clients ($N=924$) later (page 21)
**** Overall, 84\% of clients followed the advisor's recommendation (p.21)
tab follow

*** Footnote 18 (p.22) 
clear
u "${data}Clients_MPL.dta"
*** we recruited a total of 866 clients (p. 22)
**** Of these, 80% of clients followed the advisor's recommendation (p. 22)
tab follow

*** Footnote 19 (p.22) 
clear
u "${data}Clients_Blinding.dta"
*** we recruited 188 advisees (p. 22)
**** Of these, 84% followed the advisors' recommendation. (p. 22)
tab follow

****** TABLE 1 *** SAMPLE SIZES in the table
*NoChoice, SeeIncentiveFirst N=152; Assess Quality First N=147
	u "${data}nochoice.dta", clear
	drop if alphavaluefinal==.
	tab seeincentivefirst
	
*Choice, ChoiceFreeProfessionals=712;ChoiceFree=2574;  
        *See IncentiveFirst Costly=1562; AssessQualityFirst Costly=1067
		u "${data}choice_experiments.dta", clear
		drop if study!=1 & alphavaluefinal==.
		tab condition if Highx10==0 & Highx100==0
		* ChoiceFree -HighStakes (10-fold)=275
		tab condition if Highx10==1
		* ChoiceFree -HighStakes (100-fold)=110
		tab condition if Highx100==1

*ChoiceDeterministic, Replication=385; Deterministic=369
		u "${data}Choice_Deterministic.dta", clear
		drop if alphavaluefinal==.
		tab Deterministic

***ChoiceStakes, Low Incentive=483; IntermediateIncentive=511; HighIncentive=478
		u "${data}stakes.dta", clear
		drop if alphavaluefinal==.
		tab condition

***Information Architect: IA-Advisor=245; IA-Client=253
		u "${data}InformationArchitect.dta", clear
		drop if alphavaluefinal==.
		tab IAAdvisor

*** Total sample size in Table 1: N=9323
di 152+147+712+2574+1562+1067+275+110+385+369+483+511+478+245+253

************************************************************************************************************************************
************************************************************************************************************************************

*    NO CHOICE - MAIN TEXT  

************************************************************************************************************************************
************************************************************************************************************************************
************************************************************************************************************************************
clear
u "${data}nochoice.dta"


drop if alphavaluefinal==.

*PROPORTION TESTS	
prtest recommendincentive if conflict==1, by(seeincentivefirst)
prtest recommendincentive if conflict==0, by(seeincentivefirst)

*** NOCHOICE VS CHOICE COMPARISON for Table C.17 in the Appendix
mean  recommendincentive if seeincentivefirst==1 & conflict==1
mean  recommendincentive if seeincentivefirst==0 & conflict==1

reg recommendincentive seeincentivefirst##noconflict female age, vce(hc3)

*ADDITIONAL DESCRIPTIVES - BY COMMISSION	
estpost summarize recommendincentive ///
	recommendincentive_before recommendincentive_after if conflict==1,detail 
eststo d_nochoice


forvalues i=0(1)1{
estpost summarize recommendincentive ///
	recommendincentive_before recommendincentive_after if incentiveA==`i' & conflict==1,detail 
eststo d_nochoice`i'
}

** "Throughout, advisors exhibit a preference for product A"
tabstat recommendincentive if incentiveB==1 & noconflict==1, stats(mean n)
** "recommending it 16% of the times even when the quality signal is a $2 ball and the advisor is incentivized to recommend B
gen notrecommendincentive=1-recommendincentive
tabstat notrecommendincentive if incentiveB==1 & noconflict==1, stats(mean n)
/*reg recommendincentive noconflict incentiveB female age stdalpha 
	if missingalpha==0, vce(hc3) */


*FIGURE NO CHOICE - RECOMMENDATIONS		
bys before conflict: egen meanrec=mean(recommendincentive)
bys before conflict: egen sdrec=sd(recommendincentive) 
bys before conflict: egen nrec=count(recommendincentive)

*Binomial SE (formula: sqrt(p(1-p)/n))
g lorec=meanrec-1.96*(sqrt((meanrec*(1-meanrec))/nrec))
g hirec=meanrec+1.96*(sqrt((meanrec*(1-meanrec))/nrec))

gen xaxis=0 if before==1 & conflict==1
replace xaxis=1 if before==0 & conflict==1
replace xaxis=2.5 if before==1 & conflict==0
replace xaxis=3.5 if before==0 & conflict==0


twoway 	(bar meanrec xaxis if before==1 & conflict==1, color(black) barw(0.7)) ///
(bar meanrec xaxis if before==0 & conflict==1, fcolor(white) lcolor(black) barw(0.7) ) ///
(bar meanrec xaxis if before==1 & conflict==0, color(black) barw(0.7)) ///
(bar meanrec xaxis if before==0 & conflict==0, color(white) lcolor(black) barw(0.7)) ///
(rcap lorec hirec xaxis , lcolor(black*0.3) lwidth(medthick)) ///
, xtitle(" ") ///
ytitle("{bf: Incentivized Product Recommendation}") ///
graphr(c(white)) plotr(c(white)) ///
ylabel(0(0.1)1, gmax) ///
xlabel(0.5 "{bf: Conflict}"  3 "{bf: No Conflict}" ) ///
xscale(r(-0.5 3.5)) legend(order(1 "See Incentive First" 2 "See Quality First"))
graph export "${main}/nochoice_recommendations.png", replace


*REGRESSIONS (Reported in Appendix C.1)
clear 
u "${data}nochoice.dta"

*******APPENDIX*********
** MAIN REGRESSION (APPENDIX, TABLE C.1)
est clear
eststo:reg recommendincentive seeincentivefirst noconflict   incentiveB female age stdalpha  if missingalpha==0 & conflict==1, vce(hc3)
eststo:reg recommendincentive seeincentivefirst noconflict   incentiveB female age  stdalpha if missingalpha==0 & conflict==0, vce(hc3)
eststo:reg recommendincentive seeincentivefirst noconflict seeincentivefirst_noconflict   incentiveB female age stdalpha  if missingalpha==0, vce(hc3)

local panel "\begin{table}[h!]" "\centering" "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\fontsize{10}{11}\selectfont" "\caption{Recommendations}" "\begin{tabular}{l*{3}{c}} \hline" 
local dv "$\ \ \ \ \ \ \ \ \ \ \ \ \ \ $    &\multicolumn{1}{c}{\textbf{Conflict }} &\multicolumn{1}{c}{\textbf{No Conflict}} & \multicolumn{1}{c}{\textbf{Both}} \\\hline & & & \\"

esttab using "${appendix}NoChoice_Recommendations.tex",  se r2 replace nolines cells(b(star fmt(3)) se(par fmt(3))) ///
coeflabel (seeincentivefirst "See Incentive First" noconflict "No Conflict" seeincentivefirst_noconflict "See Incentive First * No Conflict"  ///
 incentiveB "Incentive for B" ///
female "Female" age "Age" stdalpha "Selfishness"  ) ///
order ( seeincentivefirst noconflict seeincentivefirst_noconflict  incentiveB female age stdalpha) collabels(none) ///
drop ( female age) ///
star( * 0.10 ** 0.05 *** 0.01) ///
nomtitle label substitute(" 0.000 " " " " (.) " " ") ///
prehead("`panel'") posthead("`dv'") postfoot("\hline" "\end{tabular}%" "\captionsetup{width=0.7\textwidth}" "\caption*{\footnotesize \textit{Notes:} This table displays the estimated coefficients from linear probability models on the advisors' recommendations. See Incentive first is a binary indicator coded as 1 for participants who were randomly assigned to see the incentive first. Selfishness is a standardized measure of the number of times the advisor chose to recommend the incentivized product in the MPL task aimed at measuring moral costs. The sample includes attentive participants who did not switch multiple times in this elicitation. The regression includes individual controls for the advisor's gender and age. Robust standard errors (HC3) in parentheses}" "\label{tab:nochoicerec}" "\end{table}")


** REGRESSION THAT INCLUDES INATTENTIVE (APPENDIX, TABLE C.2)
clear
u "${data}nochoice.dta"



est clear 
eststo:reg recommendincentive seeincentivefirst noconflict   incentiveB female age   if conflict==1, vce(hc3)
eststo:reg recommendincentive seeincentivefirst noconflict   incentiveB female age   if conflict==0, vce(hc3)
eststo:reg recommendincentive seeincentivefirst noconflict seeincentivefirst_noconflict   incentiveB female age, vce(hc3)

local panel "\begin{table}[h!]" "\centering" "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\fontsize{10}{11}\selectfont" "\caption{Recommendations including Inattentive}" "\begin{tabular}{l*{3}{c}} \hline" 
local dv "$\ \ \ \ \ \ \ \ \ \ \ \ \ \ $    &\multicolumn{1}{c}{\textbf{Conflict }} &\multicolumn{1}{c}{\textbf{No Conflict}} & \multicolumn{1}{c}{\textbf{Both}} \\\hline & & & \\"

esttab using  "${appendix}NoChoice_Recommendations_Inattentive.tex",  se r2 replace nolines cells(b(star fmt(3)) se(par fmt(3))) collabels(none) ///
coeflabel (seeincentivefirst "See Incentive First" noconflict "No Conflict" seeincentivefirst_noconflict "See Incentive First * No Conflict"  ///
 incentiveB "Incentive for B" ///
female "Female" age "Age"  ) ///
order ( seeincentivefirst noconflict seeincentivefirst_noconflict  incentiveB female age) ///
drop ( female age) ///
star( * 0.10 ** 0.05 *** 0.01) ///
nomtitle label substitute(" 0.000 " " " " (.) " " ") ///
prehead("`panel'") posthead("`dv'") postfoot("\hline" "\end{tabular}%" "\captionsetup{width=0.7\textwidth}" "\caption*{\footnotesize \textit{Notes:} This table displays the estimated coefficients from linear probability models on the advisors' recommendations. See Incentive first is a binary indicator coded as 1 for participants who were randomly assigned to see the incentive first. The sample includes all participants, including those who switched multiple times in the MPL task to measure moral costs.  The regression includes individual controls for the advisor's gender and age. Robust standard errors (HC3) in parentheses}" "\label{tab:nochoicerec_inattentive}" "\end{table}")


/************************************************************************************************************************************
************************************************************************************************************************************

    CHOICE -  MAIN TEXT 

************************************************************************************************************************************
************************************************************************************************************************************
************************************************************************************************************************************/


clear
u "${data}choice_experiments.dta"

*As pre-registered, drop Mturk participant with inconsistent alpha value
drop if study!=1 & alphavaluefinal==. /*(study1 are profs and there's no MPL')*/

************************************
/*FOOTNOTE 13
PROFESSIONALS: Comparison Prolific / CloudResearch
************************************

We pool these two samples since choices regarding the preferred sequence of information 
did not vary significantly across them ($p$=0.308) */
prtest choicebefore if study==1, by(sample)
*and recommendations did not differ either ($p$=0.820). 
reg recommendincentive cloudresearch conflict female age locatedus  if study==1

************************************
/*FOOTNOTE 15
************************************
*"We found no effect of incentive size, order or their interaction on the preference to see the incentive first ")*/
 reg choicebefore incentiveshigh##incentiveleft if study==4, ro

*"We also found no effect of incentive size, order or their interaction on recommendations)
reg recommendincentive incentiveshigh##incentiveleft if study==4 & conflict==1, ro
************************************


******************************************************************************************************************************************
******************************************************************************************************************************************
** PREFERENCES / DEMAND - MAIN TEXT 
******************************************************************************************************************************************
******************************************************************************************************************************************

global covariates "wave2 wave3 professionalscloudresearch incentiveshigh##incentiveleft age female"	
global covariates2 "professionalsfree seeincentivecostly seequalitycostly wave2 wave3 professionalscloudresearch incentiveshigh incentiveleft incentiveshigh_incentiveleft age female"

*FIGURE 4: ADVISOR PREFERENCES

eststo:reg choicebefore i.treatment $covariates if Highx10==0 & Highx100==0, vce(hc3)
margins i.treatment, atmeans saving("${main}Choice_adjusted_demand", replace)

*return list
matrix coeffs=r(table)
matrix list coeffs

g preddemand=coeffs[1,1] if treatment==0
g sepreddemand=coeffs[2,1] if treatment==0
forval i=2(1)4{
	local j=`i'-1
replace preddemand=coeffs[1,`i'] if treatment==`j'
replace sepreddemand=coeffs[2,`i'] if treatment==`j'
}
g ubpreddemand=preddemand+1.96*sepreddemand
g lbpreddemand=preddemand-1.96*sepreddemand

g xaxis=1 if treatment==1
replace xaxis=3.10 if treatment==2
replace xaxis=2.10 if treatment==0
replace xaxis=4.10 if treatment==3

g meancommit=1
			
		twoway (bar meancommit xaxis, ///
		lcolor(gs10) fcolor(white) barw(0.5) ) ///
		(bar preddemand xaxis, color(gs10) barw(0.5) ) ///
		(rcap  ubpreddemand lbpreddemand xaxis if xaxis!=., color(gs9) lwidth(*0.5)) ///
		, xtitle(Study) ///
			ytitle("Advisor preference") ///
			graphr(c(white)) plotr(c(white)) ///
			ylabel(0(0.2)1, gmax) ///
			xlabel(			2.10 `" "Choice" "Free" "' ///
			1 `" "Choice Free" "- Professionals" "' ///
			4.10 `" "Quality First" "Costly" "' ///
			3.10 `" "Incentive First" "Costly" "') ///
			xscale(r(0.5 3.5)) legend(lab(1 "Prefer to assess quality first") ///
			lab(2 "Prefer to see incentive first") order(2 1)) /// 
			xtitle("") ///
			text(0.8 1 "0.55", color(black)) text(0.30 1 "0.45", color(black))  ///
			text(0.8 2.10 "0.45") text(0.30 2.10 "0.55") ///
			text(0.8 3.10 "0.59")text(0.30 3.10 "0.41") ///
			text(0.8 4.10 "0.30")  text(0.30 4.10 "0.70") 
			*graph export "${main}Demand_predicted_errorbars.png", replace
			graph export "${main}Choice_Demand_predicted_errorbars.pdf", replace

			
*TABLE 2: PREFERENCES FOR INFORMATION ORDER
est clear
eststo:reg choicebefore $covariates2 if Highx10==0 & Highx100==0, vce(hc3)
eststo:reg choicebefore $covariates2 stdalpha if Highx10==0 & Highx100==0 & professionals==0, vce(hc3)
eststo:reg choicebefore $covariates2 stdalpha selfishseeincentivecostly selfishseequalitycostly if Highx10==0 & Highx100==0, vce(hc3)

local panel "\begin{table}[h!]" "\centering" "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\fontsize{10}{11}\selectfont" "\caption{Preference for Information Order}" "\begin{tabular}{l*{3}{c}} \hline" 
local dv "$\ \ \ \ \ \ \ \ \ \ \ \ \ \ $    &\multicolumn{3}{c}{\textbf{Prefer to See Incentive First}} \\\hline & & & \\"

esttab using  "${main}Choice_Demand.tex", ///
 se r2 replace nolines cells(b(star fmt(3)) se(par fmt(3))) ///
coeflabel (professionalsfree "Choice Free -- Professionals    $  \ \ \ \ \ \ \  $" seeincentivecostly "See Incentive First Costly          " seequalitycostly "Assess Quality First Costly" wave2 "Wave 2" wave3 "Wave 3" ///
female "Female" age "Age" stdalpha "Selfishness" professionalscloudresearch "Professionals x Cloudresearch" selfishseeincentivecostly "See Incentive First Costly X Selfishness       " selfishseequalitycostly "See Quality First Costly X Selfishness            " ///
incentiveshigh "Probabilistic Incentive Mturk" incentiveleft "Order" incentiveshigh_incentiveleft "Probabilistic Incentive X Order") ///
order (seeincentivecostly seequalitycostly  professionalsfree stdalpha selfishseeincentivecostly selfishseequalitycostly female age wave2 wave3 incentiveshigh incentiveleft incentiveshigh_incentiveleft professionalscloudresearch ) ///
star(* 0.10 ** 0.05 *** 0.01)  collabels(none)  ///
drop(wave2 wave3 incentiveshigh incentiveleft incentiveshigh_incentiveleft professionalscloudresearch) ///
nomtitle label substitute(" 0.000 " " " " (.) " " ") ///
prehead("`panel'") posthead("`dv'") postfoot("\hline" "\end{tabular}%" "\captionsetup{width=0.8\textwidth}" "\caption*{\footnotesize \textit{Notes:} This table displays the estimated coefficients from linear probability models on the preference to see the incentive first. See Incentive First Costly and Assess Quality First Costly are indicator variables that take value 1 in the respective treatment, 0 otherwise. Selfishness was elicited at the end of the experiment, using a multiple price list (MPL) with 5 decisions. The variable is a standardized measure of the number of times the advisor chose to recommend the incentivized product in the MPL task. The regression models in columns (2) and (3) include individual controls for the advisor's gender and age, each wave of the experiment, whether incentives were probabilistic, the position of the products on the screen and the interaction between these two variables. Robust standard errors (HC3) in parentheses. * p$<$.10; ** p$<$.05; *** p$<$.01}" "\label{tab:demand}" "\end{table}")

***************
* BLINDING **
***************


tabstat avoid_incentiveinfo if wave3==1 & Highx10==0 & Highx100==0 & age!=. & female!=., by(choiceafter)
**Overall percentages


*PROPORTION TESTS	
prtest avoid_incentiveinfo if wave3==1 & Highx10==0 & Highx100==0 & age!=. & female!=., by(choiceafter)

	
*STACKED FIGURE
bys choicebefore: egen blind=mean(avoid_incentiveinfo) if Highx10==0 & Highx100==0 & age!=. & female!=. & wave3==1
bys choicebefore: egen blindsd=sd(avoid_incentiveinfo) if Highx10==0 & Highx100==0 & age!=. & female!=. & wave3==1
bys choicebefore: egen blindn=count(avoid_incentiveinfo) if Highx10==0 & Highx100==0 & age!=. & female!=. & wave3==1

summ avoid_incentiveinfo if Highx10==0 & Highx100==0, d
return list

g loblind=blind-1.96*(blindsd/sqrt(blindn))
g hiblind=blind+1.96*(blindsd/sqrt(blindn))


tab blind

twoway (bar meancommit choiceafter, lcolor(black) fcolor(white) barwidth(0.3)) ///
		(bar blind choiceafter, color(gs8) barwidth(0.3)) ///
		(rcap loblind hiblind choiceafter, color(gs12)) ///
		, graphr(c(white)) xlabel(0 "Prefer to See Incentive First" 1 "Prefer to Assess Quality First") ///
		xscale(r(-0.4 1.4)) legend(order(1 "Prefer Not to Blind Incentive Information" ///
		2 "Prefer Blinding Incentive Information") rows(2)) ylabel(0(0.2)1) ///
		ytitle("Advisor Preference to Blind" " ") ///
		xtitle(" " "Advisor Preference in Choice Experiment") ///
		text(0.2 0 "0.32") text(0.2 1 "0.55")  ///
		text(0.8 0 "0.68") text(0.8 1 "0.45")
graph export "${main}Choice_Blinding.png", replace


/*The difference in preference to blind between advisors who prefer to see incentive first 
and those who prefer to see quality first  remains large (22 percentage points) and significant 
in regression analyses that control for treatment, gender, age, advisors facing a conflict of interest in the main experiment, and for being assigned 
to their preferred order in the main experiment ($t$-stat$=-7.18$, $p<0.001$, see Online Appendix C.2) */
reg avoid_incentive choicebefore notgetyourchoice choicebeforenotgetyourchoice $covariates2 noconflict if Highx10==0 & Highx100==0, vce(hc3)

********************************************************************************	
********************************************************************************	
*CHOICE - CODED EXPLANATIONS OF CHOICE 
********************************************************************************	
********************************************************************************
 u "${data}Choice_coding_explanations.dta", clear


*Main Text - page 23 - Section 4.
*Appendix C.2.4.
	*N=1749 advisors
	tab study

	*"classified their responses into four categories, which apply to 91\% of 
	*the responses. The remaining 9\% consists of empty or unrelated comments according to both raters."
	tabstat nocategory if choicebefore!=., s(mean n)

	*"Agreed in over 82% of their classifications..." and Kappa=0.76.
	kap mergedcategory1 mergedcategory2

*Main Text - Section 6.2
	*rarely report that they are indifferent between seeing the incentive 
	*first or assessing quality first (on average, 10\% of the comments)
	tab nomatter if choicebefore!=.

	*an average of 41\% of AMT participants and 53\% of professionals
	* versus 5\% of AMT participants and 7\% of professionals, 
	*respectively, $\chi^2\textrm{-stat}=405$, $p<$0.001
	tabstat limitbias if nocategory==0 & condition!="ChoiceFree_Professionals", by(choicebefore)
	tabstat limitbias if nocategory==0 & condition=="ChoiceFree_Professionals", by(choicebefore)
	tab limitbias choicebefore, chi2

	*an average of 36% of the cases for both AMT and for professionals
	tabstat commission_expl if nocategory==0 & condition=="ChoiceFree_Professionals", by(choicebefore)
	 tabstat commission_expl if nocategory==0 & condition!="ChoiceFree_Professionals", by(choicebefore)

	 
*******************************************
* APPENDIX C.2.4 - TABLE C.15
*******************************************	 
preserve
collapse limitbias nomatter commission_expl otherreason ///
 (count) nlimitbias=limitbias if nocategory==0, by(choicebefore)
 egen sumn=total(nlimitbias)
 drop nlimitbias
save "${appendix}taba.dta", replace
restore 
preserve
collapse limitbias nomatter commission_expl otherreason ///
 (count) nlimitbias=limitbias if nocategory==0 & condition!="ChoiceFree_Professionals", by(choicebefore)
 egen sumn=total(nlimitbias)
 drop nlimitbias
save "${appendix}tabb.dta", replace
restore 
preserve
collapse limitbias nomatter commission_expl otherreason ///
 (count) nlimitbias=limitbias if nocategory==0 & condition=="ChoiceFree_Professionals", by(choicebefore)
 egen sumn=total(nlimitbias)
 drop nlimitbias 
save "${appendix}tabc.dta", replace
restore 

preserve
clear
u "${appendix}taba.dta"
append using "${appendix}tabb.dta"
append using "${appendix}tabc.dta"
export excel "${appendix}tablec15.xlsx", replace first(var) keepcellfmt
rm "${appendix}taba.dta"
rm "${appendix}tabb.dta"
rm "${appendix}tabc.dta"
restore 
	 
	 
******************************************************************************************************************************************
******************************************************************************************************************************************
** RECOMMENDATIONS - MAIN TEXT 
******************************************************************************************************************************************
******************************************************************************************************************************************

u "${data}choice_experiments.dta", clear
*As pre-registered, drop Mturk participant with inconsistent alpha value
drop if study!=1 & alphavaluefinal==. /*(study1 are profs and there's no MPL')*/
gen incentiveBgetbefore=incentiveB*getbefore

**** FIGURE ***** MAIN TEXT

cap drop predrecommend_* ubpredrecommend_* lbpredrecommend_* sepredrecommend_*
g predrecommend_dqf_gqf=.
g sepredrecommend_dqf_gqf=.
g predrecommend_dqf_gif=.
g sepredrecommend_dqf_gif=.
g predrecommend_dif_gqf=.
g sepredrecommend_dif_gqf=.
g predrecommend_dif_gif=.
g sepredrecommend_dif_gif=.

*demand incentive first 
est clear
eststo:reg recommendincentive i.treatment##i.getbefore incentiveB  $covariates2 ///
if choicebefore==1  ///
& conflict==1 & Highx10==0 & Highx100==0, vce(hc3) 
forval i=0(1)3{
margins i.getbefore if treatment==`i', atmeans saving("${main}adjusted_recommendations", replace)
matrix coeffs=r(table)
replace predrecommend_dif_gqf=coeffs[1,1] if treatment==`i' & choicebefore==1 & getbefore==0
replace sepredrecommend_dif_gqf=coeffs[2,1] if treatment==`i' & choicebefore==1 & getbefore==0
replace predrecommend_dif_gif=coeffs[1,2] if treatment==`i' & choicebefore==1 & getbefore==1
replace sepredrecommend_dif_gif=coeffs[2,2] if treatment==`i' & choicebefore==1 & getbefore==1
}	
g ubpredrecommend_dif_gif=predrecommend_dif_gif+1.96*sepredrecommend_dif_gif
g lbpredrecommend_dif_gif=predrecommend_dif_gif-1.96*sepredrecommend_dif_gif
g ubpredrecommend_dif_gqf=predrecommend_dif_gqf+1.96*sepredrecommend_dif_gqf
g lbpredrecommend_dif_gqf=predrecommend_dif_gqf-1.96*sepredrecommend_dif_gqf


*demand quality first 
est clear
eststo:reg recommendincentive i.treatment##i.getbefore incentiveB  $covariates2 ///
if choicebefore==0  ///
& conflict==1 & Highx10==0 & Highx100==0, vce(hc3)  
forval i=0(1)3{
margins i.getbefore if treatment==`i', atmeans saving("${main}adjusted_recommendations", replace)
matrix coeffs=r(table)
replace predrecommend_dqf_gqf=coeffs[1,1] if treatment==`i' & choicebefore==0 & getbefore==0
replace sepredrecommend_dqf_gqf=coeffs[2,1] if treatment==`i' & choicebefore==0 & getbefore==0
replace predrecommend_dqf_gif=coeffs[1,2] if treatment==`i' & choicebefore==0 & getbefore==1
replace sepredrecommend_dqf_gif=coeffs[2,2] if treatment==`i' & choicebefore==0 & getbefore==1
}	
g ubpredrecommend_dqf_gif=predrecommend_dqf_gif+1.96*sepredrecommend_dqf_gif 
g lbpredrecommend_dqf_gif=predrecommend_dqf_gif-1.96*sepredrecommend_dqf_gif
g ubpredrecommend_dqf_gqf=predrecommend_dqf_gqf+1.96*sepredrecommend_dqf_gqf
g lbpredrecommend_dqf_gqf=predrecommend_dqf_gqf-1.96*sepredrecommend_dqf_gqf


cap drop treatnumgraph2
g treatnumgraph2=2 if  choicebefore==1 & getbefore==1 & condition=="ChoiceFree" & professionals==0
replace treatnumgraph2=2.1 if choicebefore==1 & getbefore==0 & condition=="ChoiceFree" & professionals==0
replace treatnumgraph2=2.2 if  choicebefore==0 & getbefore==1 & condition=="ChoiceFree" & professionals==0
replace treatnumgraph2=2.3 if  choicebefore==0 & getbefore==0 & condition=="ChoiceFree" & professionals==0


replace treatnumgraph2=1 if  choicebefore==1 & getbefore==1 & condition=="ChoiceFree_Professionals" 
replace treatnumgraph2=1.1 if choicebefore==1 & getbefore==0 & condition=="ChoiceFree_Professionals" 
replace treatnumgraph2=1.2 if  choicebefore==0 & getbefore==1 & condition=="ChoiceFree_Professionals" 
replace treatnumgraph2=1.3 if  choicebefore==0 & getbefore==0 & condition=="ChoiceFree_Professionals" 

replace treatnumgraph2=4 if  choicebefore==1 & getbefore==1 & condition=="PayAfter"
replace treatnumgraph2=4.1 if  choicebefore==1 & getbefore==0 & condition=="PayAfter"
replace treatnumgraph2=4.2 if  choicebefore==0 & getbefore==1 & condition=="PayAfter"
replace treatnumgraph2=4.3 if  choicebefore==0 & getbefore==0 & condition=="PayAfter"

replace treatnumgraph2=3 if  choicebefore==1 & getbefore==1 & condition=="PayBefore"
replace treatnumgraph2=3.1 if  choicebefore==1 & getbefore==0 & condition=="PayBefore"
replace treatnumgraph2=3.2 if  choicebefore==0 & getbefore==1 & condition=="PayBefore"
replace treatnumgraph2=3.3 if  choicebefore==0 & getbefore==0 & condition=="PayBefore"

		
*Conflict panel for long version of figure 		
twoway 	(scatteri 1 0.7 1 1.7, bcolor(gs15) recast(area)) ///
		(scatteri 1 2.7 1 3.7, bcolor(gs15) recast(area)) ///
		(rcap lbpredrecommend_dif_gif ubpredrecommend_dif_gif treatnumgraph2, lcolor(red) lwidth(thin)) ///
		(rcap lbpredrecommend_dqf_gqf ubpredrecommend_dqf_gqf treatnumgraph2, lcolor(black) lwidth(thin)) ///
		(rcap lbpredrecommend_dif_gqf ubpredrecommend_dif_gqf treatnumgraph2, lcolor(red*0.3) lwidth(thin)) ///
		(rcap lbpredrecommend_dqf_gif ubpredrecommend_dqf_gif treatnumgraph2, lcolor(black*0.3) lwidth(thin)) ///
		(scatter predrecommend_dif_gif treatnumgraph2 if ///
		condition=="ChoiceFree_Professionals" & professionals==1 , mcolor(red) msize(*0.75) ms(T)) ///
		(scatter predrecommend_dif_gqf treatnumgraph2 if ///
		condition=="ChoiceFree_Professionals" & professionals==1 & choicebefore==1 & getbefore==0, mfcolor(white) msize(*0.8) mlcolor(red%50) ms(S)) ///
		(scatter predrecommend_dqf_gif treatnumgraph2 if ///
		condition=="ChoiceFree_Professionals" & professionals==1 & choicebefore==0 & getbefore==1,  mfcolor(white) mlcolor(black%50) msize(*0.8) ms(T)) ///
		(scatter predrecommend_dqf_gqf treatnumgraph2 if ///
		condition=="ChoiceFree_Professionals" & professionals==1 & choicebefore==0 & getbefore==0, mcolor(black) msize(*0.8) ms(S)) ///
		(scatter predrecommend_dif_gif treatnumgraph2 if ///
		condition=="ChoiceFree" , mcolor(red) msize(*0.75) ms(T)) ///
		(scatter predrecommend_dif_gqf treatnumgraph2 if ///
		condition=="ChoiceFree" , mfcolor(white) msize(*0.8) mlcolor(red%50) ms(T)) ///
		(scatter predrecommend_dqf_gif treatnumgraph2 if ///
		condition=="ChoiceFree", mfcolor(white)  mlcolor(black*0.3) msize(*0.8) ms(S)) ///
		(scatter predrecommend_dqf_gqf treatnumgraph2 if ///
		condition=="ChoiceFree", msize(*0.8) mcolor(black) ms(S)) ///
		(scatter predrecommend_dif_gif treatnumgraph2 if condition=="PayAfter", mcolor(red) msize(*0.75) ms(T)) ///
		(scatter predrecommend_dif_gqf treatnumgraph2 if condition=="PayAfter", mfcolor(white) msize(*0.8) mlcolor(red%50)  ms(T)) ///
		(scatter predrecommend_dqf_gif treatnumgraph2 if condition=="PayAfter", mfcolor(white) mlcolor(black%50) msize(*0.8) ms(S)) ///
		(scatter predrecommend_dqf_gqf treatnumgraph2 if condition=="PayAfter", mcolor(black)  msize(*0.8)  ms(S)) ///
		(scatter predrecommend_dif_gif treatnumgraph2 if condition=="PayBefore", mcolor(red) msize(*0.75) ms(T)) ///
		(scatter predrecommend_dif_gqf treatnumgraph2 if condition=="PayBefore", mfcolor(white) msize(*0.8) mlcolor(red%50)  ms(T)) ///
		(scatter predrecommend_dqf_gif treatnumgraph2 if condition=="PayBefore", mfcolor(white) mlcolor(black%50) msize(*0.8) ms(S)) ///
		(scatter predrecommend_dqf_gqf treatnumgraph2 if condition=="PayBefore", msize(*0.8) mcolor(black) ms(S)) ///
		, graphr(c(white)) plotr(c(white)) ///
		ylabel(0.3(0.1)1) yscale(r(0.3 1)) 	///
		xtitle(" ") ///
		xlabel(none) ///                  
		xscale(r(0.7 4.6)) ///
		legend(order( - "{bf:Advisor Prefers to}" "{bf:See Incentive First}" ///
				7 8 - "{bf:Advisor Prefers to}" "{bf:Assess Quality First}" 9 10) ///
		lab(7 " Assigned to See Incentive First") ///
		lab(8 " Assigned to Assess Quality First") ///
		lab(10 " Assigned to Assess Quality First") ///
		lab(9 " Assigned to See Incentive First") ///
		rows(3) colfirst size(*0.7)) ///
		text(0.38 1.15 "{bf: Choice Free}", color(black) size(*0.8)) ///
		text(0.35 1.15 "{bf: - Professionals}", color(black) size(*0.8)) ///		
		text(0.38 2.15 "{bf: Choice}", color(black) size(*0.8)) ///
		 text(0.35 2.15 "{bf: Free }", color(black) size(*0.8)) ///
		text(0.38 4.15 "{bf: Quality First}", color(black) size(*0.8)) ///
		text(0.35 4.15 "{bf: Costly}", color(black) size(*0.8)) ///
		text(0.38 3.15 "{bf: Incentive First}", color(black) size(*0.8)) ///
		text(0.35 3.15 "{bf: Costly}", color(black) size(*0.8)) ///
		ytitle("{bf:Incentivized product recommendation}" " " ) 
		
		graph export "${main}Choice_recommendations_conflict_pred.pdf", replace

/* By contrast, those who prefer and are assigned to see quality first, recommend the incentivized product significantly less often in all cases (t-test, all p<.001) */
ttest recommendincentive if getyourchoice==1 & Highx10==0 & Highx100==0 & age!=. & treatment==0, by(choicebefore)
ttest recommendincentive if getyourchoice==1 & Highx10==0 & Highx100==0 & age!=. & treatment==1, by(choicebefore)
ttest recommendincentive if getyourchoice==1 & Highx10==0 & Highx100==0 & age!=. & treatment==2, by(choicebefore)
ttest recommendincentive if getyourchoice==1 & Highx10==0 & Highx100==0 & age!=. & treatment==3, by(choicebefore)


***Check effect of seeing incentive first vs. quality first among those who prefer to see incentive first in the COSTLY version of Choice, AMT-1 wave (to be used in Prediction study, in Appendix F)
tabstat recommendincentive if  choicebefore==1 & conflict==1 & wave=="AMT-1" & condition=="PayBefore" & alphavaluefinal!=., by(getbefore) 	stats(mean sd)	

*******************************************
* TABLE 3: RECOMMENDATIONS BY ASSIGNMENT & PREFERENCE 
*******************************************


*get pref
est clear 
eststo: reg recommendincentive choicebefore choicebeforenoconflict ///
		noconflict incentiveB $covariates2 if Highx10==0 & Highx100==0 & getyourchoice==1, vce(hc3)
test choicebefore+choicebeforenoconflict==0
		
*not get
eststo: reg recommendincentive choicebefore choicebeforenoconflict ///
		noconflict incentiveB $covariates2 if Highx10==0 & Highx100==0 & getyourchoice==0, vce(hc3)

*combined
eststo: reg recommendincentive choicebefore choicebeforenoconflict ///
		noconflict notgetyourchoice choicebeforenotgetyourchoice notgetyourchoicenoconflict incentiveB $covariates2 ///
		if Highx10==0 & Highx100==0, vce(hc3)
test choicebefore+choicebeforenoconflict==0
test choicebefore+notgetyourchoice+choicebeforenotgetyourchoice==0
test notgetyourchoice+choicebeforenotgetyourchoice==0		

lincom notgetyourchoice+choicebeforenotgetyourchoice


local panel "\begin{table}[h!]" "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\fontsize{10}{10}\selectfont" "\caption{Advisor Recommendations}" "\hspace{-1cm}" "\begin{tabular}{l*{3}{c}} \hline" 
local dv "&\multicolumn{3}{c}{\textbf{Recommend incentivized product}} \\"
local groups "\multicolumn{1}{r}{\textit{Assignment:}}&\multicolumn{1}{c}{Assigned Pref.}&\multicolumn{1}{c}{Not Assigned Pref.}&\multicolumn{1}{c}{Both} \\\hline &  &     &     \\   "
local conflict "&\multicolumn{1}{c}{Conflict}&\multicolumn{1}{c}{No Conflict}&\multicolumn{1}{c}{Conflict}&\multicolumn{1}{c}{No Conflict}&\multicolumn{1}{c}{Conflict}&\multicolumn{1}{c}{No Conflict} \\ \hline    & &    &            &     &            &  \\"
	
esttab using  "${main}recommendations_pref_assign.tex",  se r2 replace cells(b(star fmt(3)) se(par fmt(3))) ///
coeflabel (noconflict "No Conflict" getbefore "Assigned to See Incentive First"  getbeforenoconflict "Assigned to See Incentive First X No Conflict" professionalsfree "Choice Free--Professionals" seeincentivecostly "See Incentive First Costly" seequalitycostly "Assess Quality First Costly" wave2 "Wave 2" wave3 "Wave 3" notgetyourchoice "Not Assigned Preference" ///
female "Female" age "Age" selfish "Selfish" professionalscloudresearch "Professionals x Cloudresearch" selfishseeincentivecostly "Selfish X See Incentive First Costly" selfishseequalitycostly "Selfish X See Quality First Costly" ///
incentiveshigh "Probabilistic Incentive Mturk" incentiveleft "Order" incentiveshigh_incentiveleft "Probabilistic Incentive X Order" ///
incentiveB "Incentive for B" choicebefore "Prefer to See Incentive First" ///
choicebeforenoconflict "No Conflict X Prefer to See Incentive First" ///
choicebeforenotgetyourchoice "Prefer to See Incentive First X Not Assigned Preference" ///
notgetyourchoicenoconflict "No Conflict X Not Assigned Preference") ///
order (choicebefore notgetyourchoice choicebeforenotgetyourchoice noconflict choicebeforenoconflict notgetyourchoicenoconflict  professionalsfree seeincentivecostly seequalitycostly  incentiveB  selfish female age wave2 wave3 incentiveshigh incentiveleft incentiveshigh_incentiveleft professionalscloudresearch ) ///
star(* 0.10 ** 0.05 *** 0.01)  title("Advisor Recommendations") ///
drop(selfish wave2 wave3 incentiveshigh incentiveleft incentiveshigh_incentiveleft professionalscloudresearch) ///
mlabels(none) label collabels(none) substitute(" 0.00 " " " " (.) " " ") ///
posthead("`dv'" "`groups'") prehead("`panel'") nolines postfoot("\hline" "\end{tabular}%" "\captionsetup{width=1.15\textwidth}" "\caption*{\footnotesize Note: This table displays the estimated coefficients from linear probability models on the advisor's decision to recommend the incentivized option. Column (1) focuses on individuals who are assigned their preference, while column (2) focuses on individuals who are not assigned their preference. Both groups are merged in column (3). Prefer to See Incentive First is an indicator of the advisor's preference, and Not Assigned Preference is an indicator for not receiving the preferred order. No Conflict is an indicator for the cases in which the signal of quality is not in conflict with the advisor's commission. See Incentive First Costly and Assess Quality First Costly are indicator variables that take value 1 in the respective treatment, 0 otherwise. All regression models include individual controls for the advisor's gender and age, each wave of the experiment, whether incentives were probabilistic, the position of the products on the screen and the interaction between these two variables. The same analysis including a measure of advisor's selfishness are shown in Online Appendix C. Robust standard errors (HC3) in parentheses. * p$<$.10; ** p$<$.05; *** p$<$.01}" "\label{tab:recommendations}" "\end{table}")
		
		
/* page 30 On average, advisors who choose to see the incentive first are 9.8 percentage points more likely to recommend the incentivized product if they 
are assigned their preferred order ($t-\textrm{stat}=3.66$, $p<0.001$).	*/

reg recommendincentive i.getbefore incentiveB incentiveBgetbefore   ///
$covariates2 if choicebefore==1 & conflict==1  & Highx10==0 & Highx100==0, vce(hc3)	

/* page 33: In the Choice experiment, we estimate a 23.5 percentage point gap */

reg recommendincentive choicebefore choicebeforenoconflict ///
noconflict incentiveB $covariates2 if Highx10==0 & Highx100==0 & getyourchoice==1 & treatment==0, vce(hc3)
*** 23.5pp [18.67-28.4]: Estimated Gap in recommendations Between Prefer&Get Incentive and Prefer&GetQuality, ChoiceFree

/* page 33: "which is not significantly different from the gap estimated in the NoChoice experiment  ($t-\textrm{stat}=1.26$, $p=0.207$)
 but directionally larger by about 7 percentage points.
 
 
COMPARISON OF GAP IN CHOICE TO GAP IN NOCHOICE (APPENDIX TABLE C.16) */ 


*clear
*u "${data}choice_experiments.dta"
preserve
keep if treatment==0
gen seeincentivefirst=getbefore
append using "${data}nochoice.dta"
gen nochoice=0
replace nochoice=1 if choice=="No Choice"
replace nochoice=1 if seeincentivefirst==.
replace seeincentivefirst=0 if condition=="AfterA" | condition=="AfterB"
replace seeincentivefirst=1 if condition=="BeforeA" | condition=="BeforeB"
replace getbefore=1 if nochoice==1 & seeincentivefirst==1
replace incentiveshigh=0 if nochoice==1
replace incentiveleft=0 if nochoice==1
drop if Highx10==1 
drop if Highx100==1
replace noconflict=1-conflict if nochoice==1
replace wave1=0 if nochoice==1
replace wave2=0 if nochoice==1
replace wave3=0  if nochoice==1
gen choice1=1-nochoice
replace seeincentivefirst_noconflict=seeincentivefirst*noconflict
gen seeincentivefirst_nochoice=seeincentivefirst*nochoice
gen seeincentivefirst_nochoiceNocon=seeincentivefirst*nochoice*noconflict
gen nochoice_noconflict=nochoice*noconflict
replace incentiveshigh_incentive=0 if nochoice==1
drop if alphavaluefinal==.


est clear 
eststo: reg recommendincentive seeincentivefirst noconflict seeincentivefirst_noconflict incentiveB wave2 wave3 incentiveshigh incentiveleft incentiveshigh_incentive age female if  choice=="No Choice"
eststo: reg recommendincentive seeincentivefirst noconflict seeincentivefirst_noconflict incentiveB wave2 wave3 incentiveshigh incentiveleft incentiveshigh_incentive age female if (getyourchoice==1 ) & choice=="Choice"
eststo: reg recommendincentive seeincentivefirst nochoice seeincentivefirst_nochoice noconflict  seeincentivefirst_noconflict nochoice_noconflict seeincentivefirst_nochoiceNocon incentiveB wave2 wave3 incentiveshigh incentiveleft incentiveshigh_incentive age female if ((choice=="Choice" & getyourchoice==1) | choice=="No Choice") 



local panel "\begin{table}[h!]" "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\fontsize{10}{10}\selectfont" "\caption{Advisor Recommendations}" "\begin{tabular}{l*{3}{c}} \hline" 
local dv "&\multicolumn{3}{c}{\textbf{Recommend incentivized product}} \\"
local groups "\multicolumn{1}{r}{\textit{Sample:}}&\multicolumn{1}{c}{NoChoice.}&\multicolumn{1}{c}{Choice}&\multicolumn{1}{c}{Both} \\\hline &  &     &     \\   "
local conflict "\multicolumn{1}{r}{\textit{Assignment:}}&\multicolumn{1}{c}{Randomly Assigned}&\multicolumn{1}{c}{Prefer and Assigned}&\multicolumn{1}{c}{Both} \\\hline &  &     &     \\   "


esttab using  "${appendix}choice_nochoice.tex",  se r2 replace cells(b(star fmt(4)) se(par fmt(4))) ///
coeflabel (seeincentivefirst "See Incentive First" noconflict "No Conflict" seeincentivefirst_noconflict "See Incentive First X No Conflict"  ///
nochoice "No Choice" seeincentivefirst_nochoice  "See IncentiveFirst X NoChoice"  nochoice_noconflict "No Choice X No Conflict" seeincentivefirst_nochoiceNocon "See Incentive First X No Choice X No Conflict"  ///
wave2 "Wave 2" wave3 "Wave 3" ///
incentiveB "Incentive for B" choicebefore "Prefer to See Incentive First" ) ///
star(* 0.10 ** 0.05 *** 0.01)  title("Advisor Recommendations") ///
order(seeincentivefirst nochoice seeincentivefirst_nochoice noconflict nochoice_noconflict seeincentivefirst_noconflict seeincentivefirst_nochoiceNocon incentiveB) ///
drop( wave2 wave3 incentiveshigh incentiveleft incentiveshigh_incentiveleft female age) ///
mlabels(none) label collabels(none) substitute(" 0.000 " " " " (.) " " ") ///
posthead("`dv'" "`groups'") prehead("`panel'") nolines postfoot("\hline" "\end{tabular}%" "\captionsetup{width=\textwidth}" "\caption*{\footnotesize Note: This table displays the estimated coefficients from linear probability models on the advisor's decision to recommend the incentivized option. Column (1) focuses on the NoChoice Experiment, while column (2) focuses on  the Choice Experiment (ChoiceFree Treatment only) and on individuals who are assigned their preference. Both groups are merged in column (3). See Incentive First is an indicator for whether advisors are randomly assigned to see the incentive first in NoChoice, and whether, conditional on preferring to see the incentive first, they are assigned to see the incentive first in Choice. No Conflict is an indicator for the cases in which the signal of quality is not in conflict with the advisor's commission.  All regression models include individual controls for the advisor's gender and age, each wave of the experiment, whether incentives were probabilistic, the position of the products on the screen and the interaction between these two variables. Robust standard errors (HC3) in parentheses. * p$<$.10; ** p$<$.05; *** p$<$.01}" "\label{tab:recommendations}" "\end{table}")

restore 


/* PAGE 32: "Relative to advisors who are assigned to receive cognitive flexibility, those who are assigned moral commitment are 9 percentage points less likely 
to recommend the incentivized product ($t-\textrm{stat}=3.05$, $p=0.002$) */
reg recommendincentive i.getbefore incentiveB incentiveBgetbefore   ///
$covariates2 if choicebefore==0 & conflict==1  & Highx10==0 & Highx100==0, vce(hc3)

*******************************************
**** BELIEFS ******
*******************************************

*** LOGIT BELIEFS

*** GENERATE TABLE 4: BELIEF UPDATING	


cap program drop appendmodels 
program appendmodels, eclass
     syntax namelist
     tempname b V tmp
    foreach name of local namelist {
         qui est restore `name'
         mat `tmp' = e(b)
         local eq1: coleq `tmp'
         gettoken eq1 : eq1
         mat `tmp' = `tmp'[1,"`eq1':"]
        local cons = colnumb(`tmp',"_cons")
         if `cons'<. & `cons'>1 {
             mat `tmp' = `tmp'[1,1..`cons'-1]
         }
         mat `b' = nullmat(`b') , `tmp'
        mat `tmp' = e(V)
         mat `tmp' = `tmp'["`eq1':","`eq1':"]
         if `cons'<. & `cons'>1 {
             mat `tmp' = `tmp'[1..`cons'-1,1..`cons'-1]
        }
        capt confirm matrix `V'
         if _rc {
             mat `V' = `tmp'
        }
         else {
            mat `V' = ///
             ( `V' , J(rowsof(`V'),colsof(`tmp'),0) ) \ ///
             ( J(rowsof(`tmp'),colsof(`V'),0) , `tmp' )
         }
     }
     local names: colfullnames `b'
     mat coln `V' = `names'
     mat rown `V' = `names'
     eret post `b' `V'
     eret local cmd "whatever"
end


est clear
*Column 1-Panel A: Assigned Preferences (All)
eststo belief_all0: reg logitbelief bad good  ///
		if Highx10==0 & Highx100==0 & getyourchoice==1, vce(hc3) nocons
*mentioned in text: page 34, 5.57, p=0.018
test good=bad
*Column 1-Panel B: Assigned Preferences (By Choice)
*Quality first: f=q
eststo belief_0: reg logitbelief bad good  ///
		if Highx10==0 & Highx100==0 & getyourchoice==1 & choicebefore==0, vce(hc3) nocons

test good=bad

*Incentive first: f=i
eststo belief_1: reg logitbelief bad good ///
		if Highx10==0 & Highx100==0 & getyourchoice==1 & choicebefore==1, vce(hc3) nocons

test good=bad

eststo bivar: appendmodels belief_all0 belief_1 belief_0 

*mentioned in text, t-stats from table (2.45 and 2.19, p=0.014 and p=0.029, respectively)
reg logitbelief good bad goodchoicebefore badchoicebefore ///
		if Highx10==0 & Highx100==0 & getyourchoice==1, vce(hc3) nocons
test goodchoicebefore==0
estadd scalar test_good_ifirst=r(p): bivar
test badchoicebefore==0
estadd scalar test_bad_ifirst=r(p): bivar
summ logitbelief if Highx10==0 & Highx100==0 & getyourchoice==1
estadd scalar obs=r(N): bivar 

*Column 2-Panel A: Not Assigned Preferences (All)
eststo belief_all1: reg logitbelief bad good ///
		if Highx10==0 & Highx100==0 & getyourchoice==0, vce(hc3) nocons

*Column 2-Panel B: Not Assigned Preferences (By Choice)
*Quality first: f=q
eststo belief_2: reg logitbelief bad good ///
		if Highx10==0 & Highx100==0 & getyourchoice==0 & choicebefore==0, vce(hc3) nocons

*Incentive first: f=i
eststo belief_3: reg logitbelief bad good  ///
		if Highx10==0 & Highx100==0 & getyourchoice==0 & choicebefore==1, vce(hc3) nocons


eststo bivar2: appendmodels belief_all1 belief_3 belief_2 

reg logitbelief good bad goodchoicebefore badchoicebefore ///
		if Highx10==0 & Highx100==0 & getyourchoice==0, vce(hc3) nocons

test goodchoicebefore==0
estadd scalar test_good_ifirst=r(p): bivar2
test badchoicebefore==0
estadd scalar test_bad_ifirst=r(p): bivar2
summ logitbelief if Highx10==0 & Highx100==0 & getyourchoice==0
estadd scalar obs=r(N): bivar2 

*Excluding subjects who update in the wrong direction
*Column 3-Panel A: Assigned Preferences (All)
eststo belief_all2: reg logitbelief bad good  ///
		if Highx10==0 & Highx100==0 & getyourchoice==1 & updatewrong==0, vce(hc3) nocons
*mentioned in text: page 34, 12.06, p<0.001
test good=bad

*Column 3-Panel B: Assigned Preferences (By Choice)
*Quality first: f=q
eststo belief_4: reg logitbelief bad good  ///
		if Highx10==0 & Highx100==0 & getyourchoice==1 & updatewrong==0 & choicebefore==0, vce(hc3) nocons
test good=bad

*Incentive first: f=i
eststo belief_5: reg logitbelief bad good  ///
		if Highx10==0 & Highx100==0 & getyourchoice==1 & updatewrong==0 & choicebefore==1, vce(hc3) nocons
test good=bad	
	

eststo bivar3: appendmodels belief_all2 belief_5 belief_4 
*Mentioned in text: page 35, t-stats from table 1.76 and 0.81
reg logitbelief good bad goodchoicebefore badchoicebefore ///
		if Highx10==0 & Highx100==0 & getyourchoice==1 & updatewrong==0, vce(hc3) nocons

test goodchoicebefore==0
estadd scalar test_good_ifirst=r(p): bivar3
test badchoicebefore==0
estadd scalar test_bad_ifirst=r(p): bivar3
summ logitbelief if Highx10==0 & Highx100==0 & getyourchoice==1 & updatewrong==0
estadd scalar obs=r(N): bivar3


*Column 4-Panel A: Not Assigned Preferences (All)
eststo belief_all3: reg logitbelief bad good  ///
		if Highx10==0 & Highx100==0 & getyourchoice==0 & updatewrong==0, vce(hc3) nocons
test good=bad

*Column 4-Panel B: Not Assigned Preferences (BY Choice)
*Quality first: f=q
eststo belief_6: reg logitbelief bad good  ///
		if Highx10==0 & Highx100==0 & getyourchoice==0 & updatewrong==0 & choicebefore==0, vce(hc3) nocons
test good=bad

*Incentive first: f=i	
eststo belief_7: reg logitbelief bad good  ///
		if Highx10==0 & Highx100==0 & getyourchoice==0 & updatewrong==0 & choicebefore==1, vce(hc3) nocons
test good=bad	

eststo bivar4: appendmodels belief_all3 belief_7 belief_6 

reg logitbelief good bad goodchoicebefore badchoicebefore ///
		if Highx10==0 & Highx100==0 & getyourchoice==0 & updatewrong==0, robust nocons

test goodchoicebefore==0
estadd scalar test_good_ifirst=r(p): bivar4
test badchoicebefore==0
estadd scalar test_bad_ifirst=r(p): bivar4
summ logitbelief if Highx10==0 & Highx100==0 & getyourchoice==0 & updatewrong==0
estadd scalar obs=r(N): bivar4


*estadd scalar test_bad_good_news=r(p): belief_0

local panel "\begin{table}[h!]" "\centering" "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\fontsize{9}{10}\selectfont" "\begin{tabular}{l*{4}{c}}\hline" 
local dv "&\multicolumn{4}{c}{\textbf{Log-odds Belief}} \\"
local pref "\multicolumn{1}{r}{\textit{Assignment:}}&\multicolumn{1}{c}{Assigned Pref.}&\multicolumn{1}{c}{Not Assigned Pref.}&\multicolumn{1}{c}{Assigned Pref.}&\multicolumn{1}{c}{Not Assigned Pref.}\\    "
local groups "\multicolumn{1}{r}{\textit{Data:}} &\multicolumn{2}{c}{All}&\multicolumn{2}{c}{Excl. update in wrong direction}  \\\hline        &            &     &            &  \\"

esttab bivar bivar2 bivar3 bivar4 using  "${main}beliefs_pref_assign.tex",  se r2 replace nolines cells(b(star fmt(3)) se(par fmt(3))) ///
coeflabel (bad "$\beta_C$" good "$\beta_{NC}$") ///
order (bad good) ///
star(* 0.10 ** 0.05 *** 0.01) ///
mlabels(none) label collabels(none) ///
stats(obs test_bad_ifirst test_good_ifirst, fmt(%9.0g %9.3f %9.3f %9.3f %9.3f) labels("Observations" "$\beta^{f=q}_C=\beta^{f=i}_{C}$" "$\beta^{f=q}_{NC}=\beta^{f=i}_{NC}$" )) ///
addnotes("Note:  * p$<$.10; ** p$<$.05; *** p$<$.01") posthead("`dv'" "`pref'" "`groups'") prehead("`panel'") ///
 postfoot("\hline" "\end{tabular}%" "\captionsetup{width=\textwidth}" ///
"\caption*{\footnotesize \textit{Notes:} The outcome in all regressions is the log belief ratio. $\beta^f_C$ and $\beta^f_{NC}$ are the estimated effects of the log likelihood ratio for conflict and no conflict signals, respectively, for advisors who prefer order $f$ ($f=i$ indicates a preference to see the incentive first, and $f=q$ indicates a preference to see quality first). Columns(1) and (2) include all advisors. Columns (3) and (4) exclude advisors who updated in the wrong direction. Columns (1) and (3) include only advisors who were assigned their preference, while columns (2) and (4) include only advisors who were not assigned their preference. Robust standard errors (HC3) in parentheses.\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\).}" "\label{tab:beliefs}" "\end{table}")

******************************************
***** CHOICE EXPERIMENT: APPENDIX ******
*******************************************
preserve
***** APPENDIX B - TABLE B.1 ****** SAMPLE SIZES in the table
*NoChoice, SeeIncentiveFirst N=152; Assess Quality First N=147
	u "${data}nochoice.dta", clear
	drop if alphavaluefinal==.
	tab seeincentivefirst
	
*Choice, * AMT-1
		 *ChoiceFree= 1308; Incentive First Costly= 
		 u "${data}choice_experiments.dta", clear
		 drop if study!=1 & alphavaluefinal==.
		 tab condition if Highx10==0 & Highx100==0 & wave1==1
		 * AMT-2 
		 *Choice Free, $0.15 = 511; Choice Free, $15 to 1/100 = 542
		 tab condition incentiveshigh if wave2==1
		 * AMT-3 
		 *Choice Free =213 ; QualityFirst Costly=1067, IncentiveFirstCostly=215
		 tab condition if Highx10==0 & Highx100==0 & wave3==1
		 * ChoiceFree -HighStakes (10-fold)=110
		 tab condition if Highx10==1
		 * ChoiceFree -HighStakes (100-fold)=110
		 tab condition if Highx100==1

***ChoiceStakes, Low Incentive=483; IntermediateIncentive=511; HighIncentive=478
		u "${data}stakes.dta", clear
		drop if alphavaluefinal==.
		tab condition
		
***Information Architect: IA-Advisor=245; IA-Client=253
		u "${data}InformationArchitect.dta", clear
		drop if alphavaluefinal==.
		tab IAAdvisor
		
*ChoiceDeterministic, Replication=385; Deterministic=369
		u "${data}Choice_Deterministic.dta", clear
		drop if alphavaluefinal==.
		tab Deterministic

***NoChoiceSimultaneous, SeeIncentiveFirst=70; AssessQualityFirst=78; Simultaneous=128		u "${data}NoChoiceSimoultaneous.dta", clear
		u "${data}NoChoiceSimoultaneous.dta", clear
		drop if alphavaluefinal==.
		tab treatment

***Predictions, N=288
		u "${data}predictionsstudy.dta", clear
		tab gap


*** Total sample size in Table B.1: N=9599 
di 152+147+1308+1347+511+542+712+213+1067+215+275+110+483+511+478+245+253+385+369+70+78+128
restore
***** *APPENDIX B.2 - ADDITIONAL ANALYSES ******
preserve 
u "${data}professionals_jobtitles.dta", clear
*Essential: 
*Out of 712 professionals, 677 (95\%) provided job descriptions 
*that could be used by our independent raters to judge 
*whether their position was fiduciary or not.
tab fiduciary_2 fiduciary_1

di 677/712

*The raters agreed on their classification of fiduciary duty 
*in 87\% of the cases (interrater agreement $\kappa$=0.85).
alpha fiduciary_2 fiduciary_1
tab fiduciary_2 fiduciary_1
di (247+341)/677

*At least one rater classified job titles 
*as fiduciary in 62.9% of the cases (50% both, 12.7% one), while they agreed 
*that 37% of the job titles conveyed a position without fiduciary duty. 
egen meanfiduciary=rowmean(fiduciary_2 fiduciary_1)
tab meanfiduciary
di 100-37.09
*Focusing on the cases with agreement, 58\% of 
*the job titles were considered as fiduciary.  
tab fiduciary_2 fiduciary_1
di 341/(247+341)


*JOB TITLE
*Job titles frequently found in the data included the word analyst 
*(financial, actuarial, etc., in 9.4\% of the cases), accountant or 
*account manager (11.6\% of the cases), and lawyer or paralegal 
*(in 7.2\% of the cases). In their job titles, 14\% of participants 
*included the word ``manager.''

cap drop account
gen account = regexm(jobtitle, "account") | regexm(jobtitle, "Account")
tab account 

gen analyst = regexm(jobtitle, "analyst") | regexm(jobtitle, "Analyst")
tab analyst

gen lawyer = regexm(jobtitle, "lawyer") | regexm(jobtitle, "Lawyer") | regexm(jobtitle, "Legal") | regexm(jobtitle, "legal")
tab lawyer

gen manager = regexm(jobtitle, "manager") | regexm(jobtitle, "Manager") 
tab manager


*Prolific provides this information for some of our participants, but it
* was missing in 156 of 493 cases. 
tab industry if cloudresearch==0, m


*The agreement between raters regarding
* industry classification was high for CloudResearch ($\kappa=0.80$) and 
*somewhat lower for the missing cases on Prolific ($\kappa=0.65$). 
alpha industrycode_2 industrycode_1 if cloudresearch==1
alpha industrycode_2 industrycode_1 if cloudresearch==0 & industry==""


*Overall, for cases in which there is an agreement (636 out of 712), 
*we find that 72.5\% of professionals work in the finance and insurance 
*industry, 18.9\% in legal service, and for the remaining 8.7\% the industry is unknown. 

g agreedcode=industrycode_2==industrycode_1
tab industrytype_2 industrytype_1 if agreedcode==1, m cell
restore



******************************************
***** *APPENDIX C.2 - ADDITIONAL ANALYSES ******
*******************************************
***APPENDIX TABLE C.3 ****
*******************************************
preserve 
collapse year choicebefore (count) countobs=choicebefore, by(wave condition incentivedesign)

order year wave condition incentivedesign countobs choicebefore 
replace condition="Choice Free" if condition=="ChoiceFree"
replace condition="Incentive First Costly" if condition=="PayBefore"
replace condition="Quality First Costly" if condition=="PayAfter"
format choicebefore %9.3fc
format countobs %9.0fc
rename wave Wave
rename condition Treatment
rename incentivedesign Incentives
rename year Year 
rename countobs N
rename choicebefore DemandIncentiveFirst
drop Incentives Year
dataout, save("${appendix}AppendixTable_Conditions_Choice.tex") tex head replace
restore

*******************************************
**** APPENDIX TABLE C.4: BLINDING 
*******************************************
*******************************************

est clear 
eststo: reg avoid_incentive choicebefore $covariates2 noconflict if Highx10==0 & Highx100==0 & getyourchoice==1, vce(hc3)
eststo: reg avoid_incentive choicebefore $covariates2 noconflict if Highx10==0 & Highx100==0 & getyourchoice==0, vce(hc3)
eststo: reg avoid_incentive choicebefore notgetyourchoice choicebeforenotgetyourchoice $covariates2 noconflict if Highx10==0 & Highx100==0, vce(hc3)
*reg avoid_incentive choicebefore notgetyourchoice choicebeforenotgetyourchoice noconflict $covariates2 if Highx10==0 & Highx100==0, robust



local panel "\begin{table}[h!]" "\centering" "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\fontsize{10}{11}\selectfont" "\caption{Preferences for Blindness and Preferences for Information Order}" "\begin{tabular}{l*{3}{c}} \hline" 
local dv "& \multicolumn{3}{c}{\textbf{Advisor Preference to Blind}} \\"   
local pref "&\multicolumn{1}{c}{Assigned Pref.} &\multicolumn{1}{c}{Not Assigned Pref.} &\multicolumn{1}{c}{Both}  \\\hline & & & \\"


esttab using  "${appendix}Choice_Blinding.tex",  se r2 replace nolines cells(b(star fmt(3)) se(par fmt(3))) ///
coeflabel (noconflict "No Conflict" ///
 choicebefore "Prefer Incentive First" notgetyourchoice "Not Assigned Preference" ///
choicebeforenotgetyourchoice "Prefer Incentive First X Not Assigned Preference" ///
seequalitycostly "Assess Quality First Costly" seeincentivecostly "See Incentive First Costly") ///
order (choicebefore noconflict notgetyourchoice ///
choicebeforenotgetyourchoice seeincentivecostly seequalitycostly) ///
star(* 0.10 ** 0.05 *** 0.01) ///
mlabels(none) label collabels(none) ///
drop(professionalsfree wave2 wave3 professionalscloudresearch incentiveshigh incentiveleft ///
incentiveshigh_incentiveleft age female) ///
addnotes("Note:  * p$<$.10; ** p$<$.05; *** p$<$.01") posthead("`dv'" "`pref'" ) prehead("`panel'") ///
 postfoot("\hline" "\end{tabular}%" "\captionsetup{width=1\textwidth}" ///
"\caption*{\footnotesize \textit{Notes:} This table displays the coefficient estimates of OLS regressions on the advisor's preferences to blind themselves to incentives information in the Blinding task. Robust standard errors in parentheses. \sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\).}" "\label{tab:blinding1}" "\end{table}")


*******************************************
**** APPENDIX TABLE C.5 - BLINDING ADDING SELFISHNESS 
*******************************************

est clear 
eststo: reg avoid_incentive choicebefore $covariates2 noconflict stdalpha if Highx10==0 & Highx100==0 & getyourchoice==1, vce(hc3)
eststo: reg avoid_incentive choicebefore $covariates2 noconflict stdalpha if Highx10==0 & Highx100==0 & getyourchoice==0, vce(hc3)
eststo: reg avoid_incentive choicebefore notgetyourchoice choicebeforenotgetyourchoice $covariates2 noconflict  stdalpha if Highx10==0 & Highx100==0, vce(hc3)


local panel "\begin{table}[h!]" "\centering" "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\fontsize{10}{11}\selectfont" "\caption{Preferences for Blindness, Information Order \& Selfishness}" "\begin{tabular}{l*{3}{c}} \hline" 
local dv "& \multicolumn{3}{c}{\textbf{Advisor Preference to Blind}} \\"   
local pref "&\multicolumn{1}{c}{Assigned Pref.} &\multicolumn{1}{c}{Not Assigned Pref.} &\multicolumn{1}{c}{Both}  \\\hline & & & \\"

esttab using  "${appendix}Choice_Blinding_selfish.tex",  se r2 replace nolines cells(b(star fmt(3)) se(par fmt(3))) ///
coeflabel (noconflict "No Conflict" ///
 choicebefore "Prefer Incentive First" notgetyourchoice "Not Assigned Preference" ///
choicebeforenotgetyourchoice "Prefer Incentive First X Not Assigned Preference" ///
seequalitycostly "Assess Quality First Costly" seeincentivecostly "See Incentive First Costly" ///
stdalpha "Selfishness") ///
order (choicebefore noconflict notgetyourchoice ///
choicebeforenotgetyourchoice seeincentivecostly seequalitycostly stdalpha) ///
star(* 0.10 ** 0.05 *** 0.01) ///
mlabels(none) label collabels(none) ///
drop(professionalsfree wave2 wave3 professionalscloudresearch incentiveshigh incentiveleft ///

... [truncated: 109,880 more bytes of this script omitted] ...

```

### `Code/main.do`
```stata

clear 
*GLOBALS
*set the path to "YOUR PATH"
local path=" "
		
		global raw  "`path'/Data/Raw Data/"
		global data "`path'/Data/Clean Data/"
		global main "`path'/Results/Main Text/"
		global appendix "`path'/Results/Appendix/" 
		global code "`path'/Code/" 

do "${code}config.do"
do "${code}datacleaning.do"
do "${code}analysis.do"

```

### `Code/config.do`
```stata
clear all
set more off

program main
    * *** Add required packages from SSC to this list ***
    local ssc_packages "estout grc1leg dataout cdfplot"
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

 /* Install packages using net, but avoid re-installing if already present
    capture which yaml
       if _rc == 111 {
        quietly net from "https://raw.githubusercontent.com/gslab-econ/stata-misc/master/"
        quietly cap ado uninstall yaml
        quietly net install yaml
       }
    * Install complicated packages : moremata (which cannot be tested for with which)
    capture confirm file $adobase/plus/m/moremata.hlp
        if _rc != 0 {
        cap ado uninstall moremata
        ssc install moremata
        }
     * Standard GSLAB stuff
    quietly net from "https://raw.githubusercontent.com/gslab-econ/gslab_stata/master/gslab_misc/ado"
       quietly cap net uninstall matrix_to_txt
       quietly net install matrix_to_txt
       quietly cap net uninstall preliminaries
       quietly net install preliminaries
*/
end

main

```

### `Code/datacleaning.do`
```stata
		
/*-------------------------------*/	
*NO CHOICE 
/*-------------------------------*/	

clear
import delimited "${raw}NoChoice_deidentified.csv", varnames(1)
drop if status==1
tab distributionchannel
drop if distributionchannel=="preview"
tab finished
keep if finished==1

sort newid
quietly by newid:  gen dup = cond(_N==1,0,_n)
tab dup
drop if dup!=0

rename q32 attention

g id=_n
g attentionpassed=attention==3
keep if attentionpassed==1


*Treatments
g treatment=1 if condition=="BeforeA"
replace treatment=2 if condition=="AfterA"
replace treatment=3 if condition=="BeforeB"
replace treatment=4 if condition=="AfterB"

label def treat 1 "Before A" 2 "After A" 3 "Before B" 4 "After B"
label val treatment treat 



*Beliefs
g beliefbin=q45 
g beliefnum=q43

*Recommend b
g recommendb=(recommendationa==2 | recommendationb==2)

*Signal
g signalblue=(fl_211_do=="Signal_blue2" | fl_221_do=="Signal_blue2" | fl_229_do=="Signal_blue2" | fl_127_do=="Signal_blue2")

*Conflict
g conflict=1 if treatment<3 & signalblue==1
replace conflict=1 if treatment>2 & signalblue==0
replace conflict=0 if conflict==.

*Commission
g incentiveA=(condition=="AfterA" | condition=="BeforeA")
g incentiveB=1-incentiveA

*Recommend incentivized
g recommendincentivized=recommendb if treatment>2
replace recommendincentivized=1-recommendb if treatment<3

*Before-After
g before=(treatment==1 | treatment==3)
g after=1-before

*Prosociality 		
forval i=2(1)5{
recode q8`i' (1=0) (2=1)
}

rename q82 alpha1
rename q83 alpha2
rename q84 alpha3
rename q85 alpha4
rename q176 alpha5

recode alpha5 (1=0) (2=1)

egen alphamiss=rowmiss(alpha1 alpha2 alpha3 alpha4) 
tab alphamiss

*alpha1-5 equal 1 is recommend the incentivized option 

*RESTRICTING RESPONDENTS TO THOSE WITH COMPLETE ALPHA CHOICES
keep if alphamiss==0

*Prosociality switch 
reshape long alpha, i(id) j(number)
	
sort id number		
g previouschoice=alpha[_n-1] if number>1		
g steptob=(alpha-previouschoice) if number>1
bys id: egen sumsteptob=total(steptob) 

*Alpha value final = number of times you go with the incentive to recommend Y
g alphavalue=0 if sumsteptob==0 & alpha==0 & number==5 /*always choosing X, no incentive*/
replace alphavalue=5 if sumsteptob==0 & alpha==1 & number==5 /*always choosing Y, incentive*/
*Alpha value is the question number when the steptob is 1 for those who switch
replace alphavalue=number-1 if sumsteptob==1 & steptob==1 

g inconsistentchoice=(steptob==-1)
bys id: egen inconsistentid=total(inconsistentchoice) 

bys id: egen alphavaluefinal=total(alphavalue) 
replace alphavaluefinal=. if inconsistentid>0

tab alphavaluefinal, m
cap drop alphavalue inconsistentchoice previouschoice steptob
reshape wide alpha, i(id) j(number)

*Average alpha
tab alphavaluefinal if treatment!=., m

rename recommendincentivized recommendincentive
g female=(gender==2)
replace age="31" if age=="3i"
destring age, replace
recode englishnative (2=0)

g nodifficulty=(difficulty==2)
replace nodifficulty=. if difficulty==.

label var female "Female"
label var age "Age"

gen seeincentivefirst=(condition=="BeforeA" | condition=="BeforeB")

gen selfish=0
replace selfish=1 if alphavaluefinal>3
replace selfish=. if alphavaluefinal==.
gen missingalpha=0
replace missingalpha=1 if alphavaluefinal==.

gen noconflict=1-conflict
g seeincentivefirst_noconflict=seeincentivefirst*noconflict 	


g recommendincentive_before=recommendincentive if seeincentivefirst==1
g recommendincentive_after=recommendincentive if seeincentivefirst==0	


egen stdalpha=std(alphavaluefinal)


g choice="No Choice"


save "${data}nochoice.dta", replace		



/*------------------------------*/
*CHOICE EXPERIMENT
/*------------------------------*/
*** CLEANING DEIDENTIFIED DATA
clear
import delimited "${raw}Choice1_deidentified.csv", varnames(1)

drop if status==1
*drop if workerid==""
tab distributionchannel
drop if distributionchannel=="preview"
tab finished
keep if finished==1


sort newid
quietly by newid:  gen dup = cond(_N==1,0,_n)
tab dup
drop if dup!=0 


rename q32 attention

g id=_n+10000
g attentionpassed=attention==3
keep if attentionpassed==1

***gen IncentiveB
g incentiveB=.
replace incentiveB=1 if condition=="choiceFreeB"
replace incentiveB=1 if condition=="choicePayB"
replace incentiveB=0 if condition=="choiceFreeA"
replace incentiveB=0 if condition=="choicePayA"

g incentiveA=.
replace incentiveA=1 if condition=="choiceFreeA"
replace incentiveA=1 if condition=="choicePayA"
replace incentiveA=0 if condition=="choiceFreeB"
replace incentiveA=0 if condition=="choicePayB"

**Commission
gen commission="commissionB" if incentiveB==1
replace commission="commissionA" if incentiveB==0

*Choice before
g choicebefore=(choicefreeq==1 | choicepay==1)

*Recommendation 
g recommendb=(recommendationa==2 | recommendationb==2)
replace recommendb=. if recommendationa==. & recommendationb==.
g recommenda=1-recommendb	

g recommendincentive=recommendb if commission=="commissionB"
replace recommendincentive=recommenda if commission=="commissionA"	


*Beliefs
g beliefbin=q45 
g belief=q43 
replace belief=q43*100 if q43<1

*Signal
g signalblue=(fl_298_do=="Signal_blue2" ///
		| fl_304_do=="Signal_blue2" ///
		| fl_211_do=="Signal_blue2" ///
		| fl_221_do=="Signal_blue2" ///
		| fl_310_do=="Signal_blue2" ///
		| fl_229_do=="Signal_blue2" ///
		| fl_325_do=="Signal_blue2" ///
		| fl_127_do=="Signal_blue2")	
	
			
*Conflict	
g conflict=0
replace conflict=1 if signalblue==1 & commission=="commissionA"
replace conflict=1 if signalblue==0 & commission=="commissionB"


*Treatment 
g treatment="ChoiceFree" if condition=="choiceFreeA" | condition=="choiceFreeB"
replace treatment="ChoicePay" if condition=="choicePayA" | condition=="choicePayB"


*Random assignment to order
g get=fl_264_do if condition=="choiceFreeA" & choicefreeq==2
replace get=fl_265_do if condition=="choiceFreeA" & choicefreeq==1

replace get=fl_289_do if condition=="choiceFreeB" & choicefreeq==1
replace get=fl_287_do if condition=="choiceFreeB" & choicefreeq==2

replace get=fl_342_do if condition=="choicePayA" & choicepayq==2
replace get=fl_272_do if condition=="choicePayA" & choicepayq==1

replace get=fl_320_do if condition=="choicePayB" & choicepayq==1
replace get=fl_331_do if condition=="choicePayB" & choicepayq==2

g getafter=(get=="GetAfter") 
g getbefore=1-getafter

g costlydemand=(condition=="choicePayA" | condition=="choicePayB") 
g choicewave=1

g study=2 if costlydemand==0
replace study=3 if costlydemand==1

replace age="51" if age=="51`"
replace age="" if age=="re"
destring age, replace

*Prosociality
destring q82 q83 q84 q85 q176, force replace
 		
forval i=2(1)5{
recode q8`i' (1=0) (2=1)
}

rename q82 alpha1
rename q83 alpha2
rename q84 alpha3
rename q85 alpha4
rename q176 alpha5
recode alpha5 (1=0) (2=1)
egen alphamiss=rowmiss(alpha1 alpha2 alpha3 alpha4 alpha5) 
keep if alphamiss==0

g choice="Choice"


drop fl_17_do fl_264_do fl_298_do fl_265_do fl_211_do fl_272_do fl_304_do fl_342_do ///
*fl_289_do fl_221_do fl_310_do fl_287_do fl_229_do fl_320_do fl_320_do fl_325_do fl_331_do fl_127_do
	
 
save "${data}choice1.dta", replace

/*-------------------------------*/	
*PROFESSIONALS STUDY
/*-------------------------------*/	

*** CLEAN DE_IDENTIFIED DATA
**PROLIFIC
clear
import delimited "${raw}ProfessionalsProlific_deidentified.csv", varnames(1)

drop if status==1
drop if distributionchannel=="preview"
keep if finished==1
sort newid
quietly by newid:  gen dup = cond(_N==1,0,_n)
drop if dup>0


g sample="Prolific"



save "${data}professionals_prolific", replace

*CLOUDRESEARCH
clear
import delimited "${raw}ProfessionalsCloudresearch_deidentified.csv", varnames(1)

g sample="CloudResearch"
drop if status==1
drop if distributionchannel=="preview"
keep if finished==1

sort newid
quietly by newid:  gen dup = cond(_N==1,0,_n)
tab dup
drop if dup!=0


drop fl_17_do fl_481_do fl_523_do fl_528_do fl_548_do fl_555_do fl_563_do fl_657_do fl_629_do fl_656_do fl_642_do
 
rename industry industry_cloudresearch
append using "${data}professionals_prolific.dta", force

	
g attentionpassed=attention==3 
drop if attentionpassed==0


*Choice
g choicebefore=(choicefree==1)
replace choicebefore=. if choicefree==.
drop if choicebefore==.

*Beliefs
g beliefbin=q45 
g beliefnum=q43
g belief=q43 
replace belief=q43*100 if q43<1

*Recommendation 
g recommendb=(recommendationa==2 | recommendationb==2)
replace recommendb=. if recommendationa==. & recommendationb==.
g recommenda=1-recommendb	
g recommendincentive=recommenda if condition=="choicefreeA"
replace recommendincentive=recommendb if condition=="choicefreeB"
		
*Get before		
g getafter=(getbefore=="GetAfter") 
g getbefore2=(getbefore=="GetBefore")
drop getbefore
rename getbefore2 getbefore

*Signal
g signalblue=signal=="Blue"

*Conflict
g conflict=0
replace conflict=1 if signalblue==1 & (condition=="choicefreeA")	
replace conflict=1 if signalblue==0 & (condition=="choicefreeB")	 

g incentiveA=(commission=="commissionA")
g incentiveB=1-incentiveA
g costlydemand=0	
	
g female=(gender==2)
	
g choice="Professionals"

g beliefcorrect=0
replace beliefcorrect=1 if beliefbin==4 & signalblue==1 /*signal $2, quality low with 25% chance*/
replace beliefcorrect=1 if beliefbin==8 & signalblue==0 /*signal $0, quality low with 66.7% chance*/

g explanationchoice=q211

destring age, replace

g id=_n+20000



keep recommendincentive getbefore incentiveB incentiveA ///
costlydemand choicebefore belief conflict signalblue ///
female age  sample beliefbin choice beliefcorrect ///
 newid explanationchoice 	jobtitle industry shortid currentcountr
 
g study=1 

save "${data}professionals.dta", replace

/*-------------------------------*/	
*PROFESSIONALS - JOB TITLES
/*-------------------------------*/	


clear
import excel "${raw}Professionals_jobtitles.xlsx", first case(l)
save "${data}professionals_jobtitles.dta", replace

/*-------------------------------*/	
*CHOICE 2 - REVERSED
/*-------------------------------*/	
*** CLEANING DEIDENTIFIED DATA
clear
import delimited "${raw}Choice2_deidentified.csv", varnames(1)

drop if status==1

tab distributionchannel
drop if distributionchannel=="preview"
tab finished
keep if finished==1

sort newid
quietly by newid:  gen dup = cond(_N==1,0,_n)
tab dup
drop if dup>0



drop if  q_recaptchascore<.50


g id=_n+30000

g attention=attention_a
replace attention=attention_b if attention_b!=.
replace attention=att_highro if att_highro!=.
replace attention=att_highflipped if att_highflipped!=.
drop attention_a attention_b att_highro att_highflipped

g attentionpassed=attention==3 
tab attentionpassed 
drop if attentionpassed==0
rename q211 explanationchoice
replace explanationchoice=q188 if explanationchoice==""
drop q188



*Choice before
g choicebefore=.
replace choicebefore=1 if choicefreereghigh==1
replace choicebefore=0 if choicefreereghigh==2

*Beliefs
g beliefbin=q45 
*g beliefnum=q43
g belief=q43 if incentives=="$0.15 "
replace belief=q551 if incentives=="$15 "
replace beliefbin=q550 if incentives=="$15 "
replace belief=q43*100 if q43<1 

*Recommendation 
g recommendb=.
replace recommendb=1 if  recommendationb==2
replace recommendb=0 if  recommendationb==1
replace recommendb=1 if  recommendationb_flip==2
replace recommendb=0 if  recommendationb_flip==1

replace recommendb=1 if  recommendationa==2
replace recommendb=0 if  recommendationa==1
replace recommendb=1 if  recommendationa_flip==2
replace recommendb=0 if  recommendationa_flip==1

g recommenda=1-recommendb	

g recommendincentive=recommendb if commission=="commissionB"
replace recommendincentive=recommenda if commission=="commissionA"

*Signal
g signalblue=.
*replace signalblue=1 if signal=="Blue"
replace signalblue=1 if fl_272_do=="Signal_blue2"
replace signalblue=1 if fl_459_do=="Signal_blue2HIGHINCENTIVES"
replace signalblue=1 if fl_260_do=="Signal_blue2"
replace signalblue=1 if fl_450_do=="Signal_blue2HIGHINCENTIVES"
replace signalblue=1 if fl_248_do=="Signal_blue2REVERSEPRODUCTORDER"
replace signalblue=1 if fl_508_do=="Signal_blue2REVERSEPRODUCTORDER-HIGHINCENTIVES"
replace signalblue=1 if fl_236_do=="Signal_blue2REVERSEPRODUCTORDER"
replace signalblue=1 if fl_469_do=="Signal_blue2REVERSEPRODUCTORDER-HIGHINCENTIVES"
replace signalblue=1 if fl_163_do=="Signal_blue2"
replace signalblue=1 if fl_476_do=="Signal_blue2HIGHINCENTIVES"
replace signalblue=1 if fl_151_do=="Signal_blue2"
replace signalblue=1 if fl_483_do=="Signal_blue2HIGHINCENTIVES"
replace signalblue=1 if fl_139_do=="Signal_blue2REVERSEPRODUCTORDER"
replace signalblue=1 if fl_491_do=="Signal_blue2REVERSEPRODUCTORDER-HIGHINCENTIVES"
replace signalblue=1 if fl_127_do=="Signal_blue2REVERSEPRODUCTORDER"
replace signalblue=1 if fl_499_do=="Signal_blue2REVERSEPRODUCTORDER-HIGHINCENTIVES"
replace signalblue=1 if signal=="Blue"



replace signalblue=0 if fl_272_do=="Signal_red0"
replace signalblue=0 if fl_459_do=="Signal_red0HIGHINCENTIVES"
replace signalblue=0 if fl_260_do=="Signal_red0"
replace signalblue=0 if fl_450_do=="Signal_red0HIGHINCENTIVES"
replace signalblue=0 if fl_248_do=="Signal_redREVERSEPRODUCTORDER"
replace signalblue=0 if fl_508_do=="Signal_redREVERSEPRODUCTORDER-HIGHINCENTIVES"
replace signalblue=0 if fl_236_do=="Signal_redREVERSEPRODUCTORDER"
replace signalblue=0 if fl_469_do=="Signal_redREVERSEPRODUCTORDER-HIGHINCENTIVES"
replace signalblue=0 if fl_163_do=="Signal_red0"
replace signalblue=0 if fl_476_do=="Signal_red0HIGHINCENTIVES"
replace signalblue=0 if fl_151_do=="Signal_red0"
replace signalblue=0 if fl_483_do=="Signal_red0HIGHINCENTIVES"
replace signalblue=0 if fl_139_do=="Signal_redREVERSEPRODUCTORDER"
replace signalblue=0 if fl_491_do=="Signal_redREVERSEPRODUCTORDER-HIGHINCENTIVES"
replace signalblue=0 if fl_127_do=="Signal_redREVERSEPRODUCTORDER"
replace signalblue=0 if fl_499_do=="Signal_redREVERSEPRODUCTORDER-HIGHINCENTIVES"
replace signalblue=0 if signal=="Red"


*Conflict
g conflict=.
replace conflict=1 if signalblue==0 & commission=="commissionB"
replace conflict=0 if signalblue==1 & commission=="commissionB"
replace conflict=1 if signalblue==1 & commission=="commissionA"
replace conflict=0 if signalblue==0 & commission=="commissionA"

g incentiveshigh=(incentives=="$15 ")
g flippedorder=(uncertainproduct=="Product A")
g costlydemand=0	
g incentiveA=(commission=="commissionA")
g incentiveB=1-incentiveA

gen incentiveleft=.
replace incentiveleft=1 if incentiveB==1 & flippedorder==1
replace incentiveleft=0 if incentiveB==1 & flippedorder==0
replace incentiveleft=1 if incentiveA==1 & flippedorder==0
replace incentiveleft=0 if incentiveA==1 & flippedorder==1

tab condition
replace condition="ChoiceFree" 

g choicewave=2
g getafter=(getbefore=="GetAfter") 
cap drop getbefore
g getbefore=1-getafter
g study=4 


*Prosociality


forval i=2(1)5{
recode q8`i' (1=0) (2=1)
}
forval i=4(1)8{
recode q54`i' (1=0) (2=1)
}

g alpha1=q82 if incentiveshigh==0
replace alpha1=q544 if incentiveshigh==1
g alpha2=q83 if incentiveshigh==0
replace alpha2=q545 if incentiveshigh==1
g alpha3=q84 if incentiveshigh==0
replace alpha3=q546 if incentiveshigh==1
g alpha4=q85 if incentiveshigh==0
replace alpha4=q547 if incentiveshigh==1

g alpha5=v193 if incentiveshigh==0
recode alpha5 (1=0) (2=1)
replace alpha5=q548 if incentiveshigh==1

egen alphamiss=rowmiss(alpha1 alpha2 alpha3 alpha4 alpha5) 
keep if alphamiss==0
g choice="Choice"


drop fl_101_do fl_226_do fl_341_do fl_314_do fl_411_do fl_271_do fl_272_do fl_459_do ///
fl_259_do fl_260_do fl_450_do fl_247_do fl_248_do fl_508_do fl_235_do fl_236_do fl_469_do /// 
fl_117_do fl_365_do fl_205_do fl_413_do fl_162_do fl_163_do fl_476_do fl_150_do fl_151_do fl_483_do ///
fl_138_do fl_139_do fl_491_do fl_126_do fl_127_do fl_499_do 

save "${data}choice2.dta", replace


/*-------------------------------*/	
*CHOICE 3 - wave3
/*-------------------------------*/	


*** CLEANING DEIDENTIFIED DATA
clear
import delimited "${raw}Choice3_deidentified.csv", varnames(1)

drop if status==1
*drop if workerid==""
tab distributionchannel
drop if distributionchannel=="preview"
tab finished
keep if finished==1

tab attention
replace attention=q343 if condition=="Highx10" | condition=="Highx100"
keep if attention!=.
gen attentionpassed=(attention==3)

tab attentionpassed
**94.86% passed the attention check (N=2095) out of 2202 who completed the attention check question
drop if attentionpassed!=1


sort newid
quietly by newid:  gen dup = cond(_N==1,0,_n)
tab dup
drop if dup!=0

drop if  q_recaptchascore<.50
tab status


sort startdate
g id=_n+40000


**Beliefs
replace beliefbin=beliefbin_high if beliefbin==.	
drop beliefbin_high
replace belief=belief_high if belief_high!=.
drop belief_high
replace belief=belief*100 if belief<1


replace age="" if age=="casian"
destring age, replace

***Gen recommendB and recommenda dummies

g recommendb=.
replace recommendb=1 if  recommendationb==2
replace recommendb=0 if  recommendationb==1

replace recommendb=1 if  recommendationa==2
replace recommendb=0 if  recommendationa==1


g recommenda=1-recommendb	

***gen IncentiveB
g incentiveB=.
replace incentiveB=1 if commission=="commissionB"
replace incentiveB=0 if commission=="commissionA"

g incentiveA=.
replace incentiveA=1 if commission=="commissionA"
replace incentiveA=0 if commission=="commissionB"


*GET by treatment
g getafter=(getbefore=="GetAfter") 
cap drop getbefore
g getbefore=1-getafter


**gen bluesignal dummy
g signalblue=.
replace signalblue=1 if signal=="Blue"
replace signalblue=1 if fl_750_do=="SignalBlue_HighIncentives"
replace signalblue=1 if fl_773_do=="SignalBlue_HighIncentives"
replace signalblue=1 if fl_785_do=="SignalBlue_HighIncentives"
replace signalblue=1 if fl_528_do=="Signal_blue2"
replace signalblue=1 if fl_555_do=="Signal_blue2"
replace signalblue=1 if fl_555_do=="Signal_blue2"
replace signalblue=1 if fl_629_do=="Signal_blue2"
replace signalblue=1 if fl_642_do=="Signal_blue2"
replace signalblue=0 if signal=="Red"
replace signalblue=0 if fl_750_do=="SignalRed_highIncentives"
replace signalblue=0 if fl_773_do=="SignalRed_highIncentives"
replace signalblue=0 if fl_785_do=="SignalRed_highIncentives"
replace signalblue=0 if fl_528_do=="Signal_red0"
replace signalblue=0 if fl_555_do=="Signal_red0"
replace signalblue=0 if fl_555_do=="Signal_red0"
replace signalblue=0 if fl_629_do=="Signal_red0"
replace signalblue=0 if fl_642_do=="Signal_red0"

g conflict=.
replace conflict=1 if signalblue==0 & commission=="commissionB"
replace conflict=0 if signalblue==1 & commission=="commissionB"
replace conflict=1 if signalblue==1 & commission=="commissionA"
replace conflict=0 if signalblue==0 & commission=="commissionA"
	

tab commission 
g recommendincentive=recommendb if commission=="commissionB"
replace recommendincentive=recommenda if commission=="commissionA"	


gen choicebefore=.
replace choicebefore=1 if choicefree==1
replace choicebefore=0 if choicefree==2
replace choicebefore=1 if choicepaybefore==1
replace choicebefore=0 if choicepaybefore==2
replace choicebefore=0 if choicepayafter==2
replace choicebefore=1 if choicepayafter==1



*** DUMMIES FOR STAKE TREATMENTS

gen HighStakes=""
replace HighStakes=condition if condition=="Highx10"
replace HighStakes=condition if condition=="Highx100"

gen Highx10=0
replace Highx10=1 if  condition=="Highx10"
gen  Highx100=0
replace Highx100=1 if  condition=="Highx100"

replace condition="ChoiceFree" if Highx10==1
replace condition="ChoiceFree" if Highx100==1


**Info avoidance
tab ia_choice
gen chooseblindness=ia_choice
replace chooseblindness=0 if ia_choice==2
tab chooseblindness

gen ia_recommend1=.
replace ia_recommend1=1 if ia_rec_quality0==1 | ia_recq2==1 | ia_rec_both2==1 | ia_rec_both0==1
replace ia_recommend1=0 if ia_rec_quality0==2 | ia_recq2==2 | ia_rec_both2==2 | ia_rec_both0==2

gen ia_recommendincentive=1 if ia_recommend1==1 & ia_incentive=="Product 1"
replace ia_recommendincentive=0 if ia_recommend1==0 & ia_incentive=="Product 1"
replace ia_recommendincentive=1 if ia_recommend1==0 & ia_incentive=="Product 2"
replace ia_recommendincentive=0 if ia_recommend1==1 & ia_incentive=="Product 2"




***Prosociality
forval i=1(1)5{
recode alpha`i' (1=0) (2=1)
}	

egen alphamiss=rowmiss(alpha1 alpha2 alpha3 alpha4) 
keep if alphamiss==0

gen study=6
rename q211 explanationchoice
gen costlydemand=0
replace costlydemand=1 if condition=="PayBefore"


g sample="MTurk"
	


drop fl_728_do fl_816_do fl_737_do fl_759_do fl_750_do fl_761_do fl_773_do fl_778_do ///
 fl_785_do fl_793_do fl_800_do fl_825_do fl_837_do fl_903_do fl_843_do fl_870_do fl_850_do ///
fl_880_do fl_855_do fl_889_do fl_17_do fl_481_do fl_523_do fl_528_do fl_548_do fl_555_do ///
 fl_563_do fl_657_do fl_629_do fl_656_do fl_642_do fl_933_do fl_916_do fl_935_do

g choice="Choice"
save "${data}choice3.dta", replace

	
	
/*-------------------------------*/	
*POOLING ALL CHOICE WAVES INTO 1 DATASET
/*-------------------------------*/	
		

	u "${data}choice1.dta", clear
	append using "${data}choice2.dta" 
	append using "${data}choice3.dta"

	*Prosociality - switch point 
	reshape long alpha, i(id) j(number)
			
	sort id number		
	g previouschoice=alpha[_n-1] if number>1		
	g steptob=(alpha-previouschoice) if number>1
	bys id: egen sumsteptob=total(steptob) 

	*Alpha value final = number of times you go with the incentive to recommend Y
	g alphavalue=0 if sumsteptob==0 & alpha==0 & number==5 /*always choosing X, no incentive*/
	replace alphavalue=5 if sumsteptob==0 & alpha==1 & number==5 /*always choosing Y, incentive*/
	*Alpha value is the question number when the steptob is 1 for those who switch
	replace alphavalue=number-1 if sumsteptob==1 & steptob==1 

	g inconsistentchoice=(steptob==-1)
	bys id: egen inconsistentid=total(inconsistentchoice) 

	bys id: egen alphavaluefinal=total(alphavalue) 
	replace alphavaluefinal=. if inconsistentid>0

	cap drop alphavalue inconsistentchoice previouschoice steptob 

	reshape wide alpha, i(id) j(number)


	*ATTENTIVE GUYS are DROPPED FOR INCOMPLETE ANSWERS
	*KEEP CONSISTENT GUYS IN ALPHA TASK		
	tab alphavaluefinal, m
	egen stdalpha=std(alphavaluefinal)

	gen selfish=(alphavaluefinal>3)
	replace selfish=. if alphavaluefinal==.
		
	*tab attention0, m
	*keep if attention0==1
			
	destring gender age englishnative difficulty, force replace 
	g female=(gender==2)
	recode englishnative (2=0)
	g nodifficulty=(difficulty==2)
	replace nodifficulty=. if difficulty==.

	label var female "Female"
	label var age "Age"

	g beliefcorrect=0
	replace beliefcorrect=1 if beliefbin==4 & signalblue==1
	replace beliefcorrect=1 if beliefbin==8 & signalblue==0

	replace sample="MTurk"
	
	replace incentiveleft=0 if study!=4
	replace incentiveshigh=0 if study!=4
	
	drop if choicebefore==.
	tab condition, m
	replace condition="ChoiceFree" if condition=="choiceFreeA"
	replace condition="ChoiceFree" if condition=="choiceFreeB"
	replace condition="PayBefore" if condition=="choicePayA"
	replace condition="PayBefore" if condition=="choicePayB"

		
keep id startdate enddate attentionpassed recommendincentive getbefore incentiveB incentiveA commission costlydemand ///
choicebefore belief beliefbin conflict signalblue female age selfish stdalpha ///
alphavaluefinal beliefcorrect newid shortid ///
sample choice incentiveshigh flippedorder /// 
incentiveleft condition study  Highx10 Highx100 chooseblindness 

append using "${data}professionals.dta"

rename costlydemand incentivecostly
	g qualitycostly=0
	replace qualitycostly=1 if condition=="PayAfter"

g professionals=(study==1)
g prolific=(sample=="Prolific")
g cloudresearch=(sample=="CloudResearch")
gen professionalscloudresearch=0 if professionals==1 & cloudresearch==1
replace professionalscloudresearch=1 if professionals==1 & cloudresearch==1
replace incentiveshigh=0 if incentiveshigh==.
replace incentiveleft=0 if incentiveleft==.
replace Highx10=0 if Highx10==.
replace Highx100=0 if Highx100==.
g mturkwave=.
replace mturkwave=1 if study==2 | study==3
replace mturkwave=2 if study==4
replace mturkwave=3 if study==6

***drop 1 participant <18 to comply w IRB rules
drop if age<18
replace age=. if age==545


replace condition="ChoiceFree_Professionals" if study==1
tab condition

drop if choicebefore==.

replace study=7 if study==6 & condition=="PayBefore"
replace study=8 if study==6 & condition=="PayAfter"

** waves
g wave1=(study==2 | study==3)
g wave2=(study==4)
g wave3=(study==6 | study==7 | study==8)

**professionals cloudresearch
replace professionalscloudresearch=0 if professionalscloudresearch==.

**probabilistic incentives
g probabilistic_incentive=1 if incentiveshigh==1
replace probabilistic_incentive=1 if professionals==1
replace probabilistic_incentive=0 if professionals==0 & incentiveshigh==0

**locatedUS

	g locatedus=1 if study>1
	replace locatedus=1 if study==1 & prolific==0
	replace locatedus=1 if study==1 & prolific==1 & currentcountryofresidence=="United States"
	replace locatedus=0 if study==1 & prolific==1 & currentcountryofresidence!="United States"
	drop currentcountryofresidence

**For appendix
g wave="AMT-1" if wave1==1
replace wave="AMT-2" if wave2==1
replace wave="AMT-3" if wave3==1
replace wave="Prolific/CloudResearch" if study==1

g incentivedesign="0.15" if wave1==1
replace incentivedesign="15 (to 1 out of 100)" if incentiveshigh==1 | wave=="Prolific/CloudResearch"
replace incentivedesign="1.50" if Highx10==1
replace incentivedesign="15 (to everyone)" if Highx100==1
replace incentivedesign="0.15" if wave2==1 & incentiveshigh==0
replace incentivedesign="0.15" if wave3==1 & Highx10==0 & Highx100==0

g year=2019 if wave1==1
replace year=2020 if wave2==1 | wave=="Prolific/CloudResearch"
replace year=2021 if wave3==1


g treatment=0 if condition=="ChoiceFree"
replace treatment=1 if  professionals==1
replace treatment=2 if condition=="PayBefore" 
replace treatment=3 if condition=="PayAfter"
gen selfishseeincentivecostly=stdalpha*incentivecostly
gen selfishseequalitycostly=stdalpha*qualitycostly

gen committ=1-choicebefore

*Separate dummies, instead of factor variables in regression
g professionalsfree=(professionals==1)
g seeincentivecostly=condition=="PayBefore" 
g seequalitycostly=condition=="PayAfter"
g incentiveshigh_incentiveleft=incentiveshigh*incentiveleft

*blinding

g avoid_incentiveinfo=(chooseblindness==1)
replace avoid_incentiveinfo=. if chooseblindness==.
gen choiceafter=1-choicebefore

**Recommendations
***Gen indicator for whether participants get their desired choice of info order
gen getyourchoice=0
replace getyourchoice=1 if choicebefore==1 & getbefore==1
replace getyourchoice=1 if choicebefore==0 & getbefore==0
label var getyourchoice "Random Assignment to Preferred Order"

g choicebefore_getyourchoice=choicebefore*getyourchoice	
label var choicebefore_getyourchoice "Prefer to See Incentive First X Random Assignment"


g getbeforenoconflict=getbefore*(1-conflict)	
g noconflict=1-conflict
g choicebeforenoconflict=choicebefore*(1-conflict)

g choicebefore_getbefore=choicebefore*getbefore
g choicebefore_getbefore_nocon=choicebefore*getbefore*(1-conflict)

g notgetyourchoice=(1-getyourchoice)
g notgetyourchoicenoconflict=(1-getyourchoice)*(1-conflict)
g choicebeforenotgetyourchoice=notgetyourchoice*choicebefore

gen choicebeforegetbefore=choicebefore*getbefore

***Beliefs
g logsignalhigh=-log(2) /*prob signal H if q=L 0.4 / prob signal H if q=H 0.8 --> log(1/2)=-log(2)*/
g logsignallow=log(3) /*prob signal L if q=L 0.6 / prob signal L if quality H 0.2 --> log(3) */

g logitbelief=log(belief/(100-belief))	/*that B is low quality*/


g good=0
replace good=logsignallow if incentiveA==1 & signalblue==0
replace good=logsignalhigh if incentiveB==1 & signalblue==1
g bad=0
replace bad=logsignallow if incentiveB==1 & signalblue==0
replace bad=logsignalhigh if incentiveA==1 & signalblue==1

g goodchoicebefore=good*choicebefore 
g badchoicebefore=bad*choicebefore 

g goodgetyourchoice=good*getyourchoice
g badgetyourchoice=bad*getyourchoice

g goodnotgetyourchoice=good*(1-getyourchoice)
g badnotgetyourchoice=bad*(1-getyourchoice)

g goodchoicebeforenotgetyourchoice=good*(1-getyourchoice)*choicebefore
g badchoicebeforenotgetyourchoice=bad*(1-getyourchoice)*choicebefore

g bayesianposterior=33 if signalblue==1
replace bayesianposterior=75 if signalblue==0

label var good "Good news (log odds incl.)"
label var bad "Bad news (log odds incl.)"
label var badchoicebefore "Bad news (log) X Pref Inc 1st"
label var goodchoicebefore "Good news (log) X Pref Inc 1st"
label var goodgetyourchoice "Good news (log) X Get Choice"
label var badgetyourchoice "Bad news (log) X Get Choice"
label var goodnotgetyourchoice "Good news (log) X Not Get Choice"
label var badnotgetyourchoice "Bad news (log) X Not Get Choice"
label var goodchoicebeforenotgetyourchoice "Good news (log) X Prefer Inc 1st X Not Get Choice"
label var badchoicebeforenotgetyourchoice "bad news (log) X Prefer Inc 1st X Not Get Choice"
label var bayesianposterior "Bayesian Posterior"

g badsignal=0
replace badsignal=1 if incentiveB==1 & signalblue==0
replace badsignal=1 if incentiveA==1 & signalblue==1 
			

*Gen variables for those who update in correct direction
*belief is likelihood that quality is LOW, so if signal is blue($2), likelihood should be 25
g updatecorrect=(belief<50) if signalblue==1
replace updatecorrect=(belief>50) if signalblue==0

g updatedirection=1 if signalblue==1 & belief<50
replace updatedirection=1 if signalblue==0 & belief>50
replace updatedirection=0 if belief==50
replace updatedirection=-1 if belief>50 & signalblue==1
replace updatedirection=-1 if belief<50 & signalblue==0

g updatewrong=(updatedirection==-1)

**cumulative beliefs distance
g beliefdistance=belief-33.3 if signalblue==1 /*positive difference=too little updating*/
replace beliefdistance=75-belief if signalblue==0 /*positive difference=too little updating*/

g relbeliefdistance=(50-belief)/(50-33) if signalblue==1
replace relbeliefdistance=(50-belief)/(50-75) if signalblue==0

**correct direction - incentivized measure
*Prob quality of B is low, bin #5 - 41-50%

g correctdirbin=0
replace correctdirbin=1 if signalblue==1 & beliefbin<6 & beliefbin!=. /*if signal is blue, $2, it decreases*/
replace correctdirbin=1 if signalblue==0 & beliefbin>4 & beliefbin!=. /*if signal is blue, $0, it decreases*/

*correct bin - incentivized measure
g beliefinbin=0
replace beliefinbin=1 if belief<11 & beliefbin==1
replace beliefinbin=1 if belief>10 & belief<21 & beliefbin==2
replace beliefinbin=1 if belief>20 & belief<31 & beliefbin==3
replace beliefinbin=1 if belief>30 & belief<41 & beliefbin==4
replace beliefinbin=1 if belief>40 & belief<51 & beliefbin==5
replace beliefinbin=1 if belief>50 & belief<61 & beliefbin==6
replace beliefinbin=1 if belief>60 & belief<71 & beliefbin==7
replace beliefinbin=1 if belief>70 & belief<81 & beliefbin==8
replace beliefinbin=1 if belief>80 & belief<91 & beliefbin==9
replace beliefinbin=1 if belief>90 & belief!=. & beliefbin==10
replace beliefinbin=. if belief==. | beliefbin==. 

** belief at prior

g belief_prior=0
replace belief_prior=1 if beliefbin==5
replace belief_prior=. if beliefbin==.

*** belief at prior - continuous
g belief_prior_continuos=0
replace belief_prior_continuos=1 if belief==50
replace belief_prior_continuos=. if belief==.

drop newid 

save "${data}choice_experiments.dta", replace


/*-----CHOICE - CODED EXPLANATIONS OF CHOICE -------*/
*IMPORT EXPLANATIONS CSV
clear
import excel "${raw}Choice_explanations_deidentified.xlsx", first case(l)		
save "${data}coding_explanations.dta", replace

u "${data}choice_experiments.dta", clear
keep if mturkwave==2 | professionals==1
rename id participant_id 
g id=shortid 
bys id: egen countid=count(id) 
tab countid study
drop if alphavaluefinal==. & study!=1

merge 1:m shortid using "${data}coding_explanations.dta", force
rename _merge _mergedecisions
keep if _mergedecisions==3
tab countid study if rater==1

replace condition="ChoiceFree_Professionals" if study==1
egen rowsum=rowtotal(limitbias nomatter commission_expl feeling other)

g mergedcategory=1 if limitbias==1 & rowsum<2
replace mergedcategory=2 if nomatter==1 & rowsum<2
replace mergedcategory=3 if commission_expl==1 & rowsum<2
replace mergedcategory=4 if (feeling==1 | other==1) & (rowsum==1 | rowsum==2)
replace mergedcategory=5 if rowsum==0
replace mergedcategory=6 if rowsum>1 & limitbias==1 & nomatter==1
replace mergedcategory=7 if rowsum>1 & limitbias==1 & commission_expl==1
replace mergedcategory=8 if rowsum>1 & limitbias==1 & (feeling==1 | other==1)
replace mergedcategory=9 if rowsum>1 & commission_expl==1 & nomatter==1
replace mergedcategory=10 if rowsum>1 & nomatter==1 & (feeling==1 | other==1)		
replace mergedcategory=11 if rowsum>1 & commission_expl==1 & (feeling==1 | other==1)

g otherreason=(other==1 | feeling==1)

reshape wide limitbias nomatter commission_expl feeling other comments rowsum ///
	mergedcategory otherreason, i(shortid) j(rater)
	
g nocategory1=(limitbias1==0 & nomatter1==0 & commission_expl1==0 & otherreason1==0)
g nocategory2=(limitbias2==0 & nomatter2==0 & commission_expl2==0 & otherreason2==0)
	
foreach v of newlist limitbias nomatter commission_expl feeling other otherreason nocategory {
egen `v'=rowmean(`v'1 `v'2)
}
egen mergedcategory=rowmean(mergedcategory1 mergedcategory2)

drop shortid

save "${data}Choice_coding_explanations.dta", replace



/*-------------------------------*/	
*STAKES STUDY
/*-------------------------------*/	


*** CLEANING DEIDENTIFIED DATA
clear
import delimited "${raw}Stakes_deidentified.csv", varnames(1)

drop if status==1
tab distributionchannel
drop if distributionchannel=="preview"
tab finished
keep if finished==1

g attentionpassed=attention==3 
keep if attentionpassed==1


sort newid
quietly by newid:  gen dup = cond(_N==1,0,_n)
tab dup
drop if dup!=0

drop if  q_recaptchascore<.50

g id=_n+50000


*Treatment
g condition2=0.30 if condition=="PayBefore_HighCommission"
replace condition2=0.15 if condition=="PayBefore_main"
replace condition2=0.01 if condition=="PayBeforeLowCommission"

recode choicepaybefore (2=0)
recode choicehighcommission (2=0)
recode choicelowcommission (2=0)

g choicebefore=choicepaybefore if condition=="PayBefore_main"
replace choicebefore=choicehighcommission if condition=="PayBefore_HighCommission"
replace choicebefore=choicelowcommission if condition=="PayBeforeLowCommission"

*Signal
g signalblue=(signal=="Blue")

*Beliefs
g beliefbin=q45		
g belief=q43

g beliefcorrect=0
replace beliefcorrect=1 if beliefbin==4 & signalblue==1
replace beliefcorrect=1 if beliefbin==8 & signalblue==0

*Recommendation
g recommendb=(recommendationa==2 | recommendationb==2)
g recommenda=1-recommendb	
g recommendincentive=recommenda if commission=="commissionA"
replace recommendincentive=recommendb if commission=="commissionB"


			
*Conflict
g conflict=0
replace conflict=1 if signalblue==1 & commission=="commissionA"
replace conflict=1 if signalblue==0 & commission=="commissionB"	 

*Get before
g getbeforenum=(fl_523_do=="GetBeforeIncentiveforA" | ///
				fl_548_do=="GetBeforeIncentiveforA" |  ///
				fl_657_do=="GetBeforeIncentiveforB" | ///
				fl_656_do=="GetBeforeIncentiveforB" )
drop getbefore
rename getbeforenum getbefore

destring age, replace

**Gender
gen female=.
replace female=1 if gender==2
replace female=0 if gender==1

*Prosociality
forval i=2(1)5{
recode q8`i' (1=0) (2=1)
}

rename q82 alpha1
rename q83 alpha2
rename q84 alpha3
rename q85 alpha4
rename q176 alpha5
recode alpha5 (1=0) (2=1)

egen alphamiss=rowmiss(alpha1 alpha2 alpha3 alpha4) 
keep if alphamiss==0

*Prosociality - switch point 
	reshape long alpha, i(id) j(number)
			
	sort id number		
	g previouschoice=alpha[_n-1] if number>1		
	g steptob=(alpha-previouschoice) if number>1
	bys id: egen sumsteptob=total(steptob) 

	*Alpha value final = number of times you go with the incentive to recommend Y
	g alphavalue=0 if sumsteptob==0 & alpha==0 & number==5 /*always choosing X, no incentive*/
	replace alphavalue=5 if sumsteptob==0 & alpha==1 & number==5 /*always choosing Y, incentive*/
	*Alpha value is the question number when the steptob is 1 for those who switch
	replace alphavalue=number-1 if sumsteptob==1 & steptob==1 

	g inconsistentchoice=(steptob==-1)
	bys id: egen inconsistentid=total(inconsistentchoice) 

	bys id: egen alphavaluefinal=total(alphavalue) 
	replace alphavaluefinal=. if inconsistentid>0

	cap drop alphavalue inconsistentchoice previouschoice steptob 

	reshape wide alpha, i(id) j(number)


	*ATTENTIVE GUYS are DROPPED FOR INCOMPLETE ANSWERS
	*KEEP CONSISTENT GUYS IN ALPHA TASK		
	tab alphavaluefinal, m
	gen selfish=(alphavaluefinal>3)
	replace selfish=. if alphavaluefinal==.
		
g choice="Stakes"

drop if choicebefore==.

g conditionnum=1 if condition=="PayBeforeLowCommission"
replace conditionnum=2 if condition=="PayBefore_main"
replace conditionnum=3 if condition=="PayBefore_HighCommission"

keep if conditionnum!=.

label var female "Female"
label var age "Age"

replace age=61 if age==611
		
g commissionlow=conditionnum==1
g commissionintermediate=conditionnum==2
g commissionhigh=conditionnum==3
		
g noconflict=1-conflict
g choicebeforenoconflict=choicebefore*noconflict
g incentiveB=commission=="commissionB"

g getyourchoice=0
replace getyourchoice=1 if choicebefore==1 & getbefore==1
replace getyourchoice=1 if choicebefore==0 & getbefore==0

g notgetyourchoice=1-getyourchoice
g choicebeforenotgetyourchoice=choicebefore*notgetyourchoice
g notgetyourchoicenoconflict=noconflict*notgetyourchoice

g commissionlowchoicebefore=commissionlow*choicebefore
g commissionhighchoicebefore=commissionhigh*choicebefore

egen stdalpha=std(alphavaluefinal)


drop responseid newid    
drop   distributionchannel userlanguage
drop fl_17_do fl_481_do fl_523_do fl_528_do fl_548_do fl_555_do fl_563_do fl_657_do fl_629_do fl_656_do fl_642_do


save "${data}stakes.dta", replace


/*-------------------------------*/	
* INFORMATION ARCHITECT STUDY
/*-------------------------------*/	

*** INFORMATION ARCHITECTS*****

*** CLEANING DEIDENTIFIED DATA
clear
import delimited "${raw}InformationArchitect_deidentified.csv", varnames(1)


drop if status==1
tab distributionchannel
drop if distributionchannel=="preview"
tab finished
keep if finished==1


sort newid
quietly by newid:  gen dup = cond(_N==1,0,_n)
tab dup
drop if dup!=0

drop if  q_recaptchascore<.50


gen attentionpassed=.
replace attentionpassed=1 if attention==3
replace attentionpassed=0 if attention==1 | attention==2 | attention==4 
tab attentionpassed
**92.11% passed the attention check (N=549) out of 602 who completed the attention check question


drop if attentionpassed!=1
sort startdate
gen id=_n+70000

** condition
replace condition="IA-Advisor" if condition=="DM-Advisor"
replace condition="IA-Client" if condition=="DM-Client"


**Gender
gen female=.
replace female=1 if gender==2
replace female=0 if gender==1

**Age
destring age, replace

gen choicebefore=0
replace choicebefore=1 if condition=="IA-Advisor" & choicedmadvisor==1
replace choicebefore=1 if condition=="IA-Client" & choicedmclient==1

***Prosociality


forval i=1(1)5{
	recode alpha`i' (1=0) (2=1)
	}

egen alphamiss=rowmiss(alpha1 alpha2 alpha3 alpha4) 
keep if alphamiss==0

reshape long alpha, i(id) j(number)


sort id number		
	g previouschoice=alpha[_n-1] if number>1		
	g steptob=(alpha-previouschoice) if number>1
	bys id: egen sumsteptob=total(steptob) 

	g alphavalue=0 if sumsteptob==0 & alpha==0 & number==5 /*always choosing X, no incentive*/
	replace alphavalue=5 if sumsteptob==0 & alpha==1 & number==5 /*always choosing Y, incentive*/
	replace alphavalue=number-1 if sumsteptob==1 & steptob==1 

	g inconsistentchoice=(steptob==-1)
	bys id: egen inconsistentid=total(inconsistentchoice) 

	bys id: egen alphavaluefinal=total(alphavalue) 
	replace alphavaluefinal=. if inconsistentid>0
	
cap drop alphavalue inconsistentchoice previouschoice steptob 

	reshape wide alpha, i(id) j(number)
	
gen study=9

sort choicebefore alphavaluefinal
gen missingalpha=0
replace missingalpha=1 if alphavaluefinal==.
sort missingalpha choicebefore
gen id_pair=_n


gen IAAdvisor=(condition=="IA-Advisor")
gen IAClient=(condition=="IA-Client")

drop newid

save "${data}InformationArchitect.dta", replace

*** ADVISORS*****

*** CLEANING DEIDENTIFIED DATA
clear
import delimited "${raw}InformationArchitect_Advisor_deidentified.csv", varnames(1)


drop if status==1
tab distributionchannel
drop if distributionchannel=="preview"
tab finished
keep if finished==1


**Gender
gen female=.
replace female=1 if gender==2
replace female=0 if gender==1

**Age
destring age, replace

**Signal Blue
gen signalblue=.
replace signalblue=1 if fl_211_do=="Signal_blue2"
replace signalblue=0 if fl_211_do=="Signal_red0"
replace signalblue=1 if fl_221_do=="Signal_blue2"
replace signalblue=0 if fl_221_do=="Signal_red0"
replace signalblue=1 if fl_229_do=="Signal_blue2"
replace signalblue=0 if fl_229_do=="Signal_red0"
replace signalblue=1 if fl_127_do=="Signal_blue2"
replace signalblue=0 if fl_127_do=="Signal_red0"

**Beliefs
g beliefcorrect=0
replace beliefcorrect=1 if beliefbin==4 & signalblue==1
replace beliefcorrect=1 if beliefbin==8 & signalblue==0

*Recommendation
g recommendb=(recommendationa==2 | recommendationb==2)

*Conflict
gen conflict=0
replace conflict=1 if condition=="AfterA" & signalblue==1
replace conflict=1 if condition=="AfterB" & signalblue==0
replace conflict=1 if condition=="BeforeA" & signalblue==1
replace conflict=1 if condition=="BeforeB" & signalblue==0

**gen id
gen id_advisor=_n+75000


**Prosociality
forval i=1(1)5{
	recode alpha`i' (1=0) (2=1)
	}


reshape long alpha, i(id_advisor) j(number)
				
		sort id_advisor number		
		g previouschoice=alpha[_n-1] if number>1		

		g steptob=(alpha-previouschoice) if number>1
		bys id_advisor: egen sumsteptob=total(steptob) 
	
	*Alpha value final = number of times you go with the incentive to recommend Y
	g alphavalue=0 if sumsteptob==0 & alpha==0 & number==5 /*always choosing X, no incentive*/
	replace alphavalue=5 if sumsteptob==0 & alpha==1 & number==5 /*always choosing Y, incentive*/
	*Alpha value is the question number when the steptob is 1 for those who switch
	replace alphavalue=number-1 if sumsteptob==1 & steptob==1 

	g inconsistentchoice=(steptob==-1)
	bys id_advisor: egen inconsistentid=total(inconsistentchoice) 

	bys id_advisor: egen alphavaluefinal=total(alphavalue) 
	replace alphavaluefinal=. if inconsistentid>0
	
cap drop alphavalue inconsistentchoice previouschoice steptob 

	reshape wide alpha, i(id_advisor) j(number)
	
gen study=9

tab conflict

*Recommend incentive
gen recommendincentive=0                             
replace recommendincentive=1 if (condition=="AfterA" | condition=="BeforeA" ) & recommendb==0
replace recommendincentive=1 if (condition=="AfterB" | condition=="BeforeB" ) & recommendb==1

gen treatment=0
replace treatment =1 if condition=="BeforeA" | condition=="BeforeB"
replace treatment =2 if condition=="AfterA" | condition=="AfterB"

gen incentiveforA=.
replace incentiveforA=1 if  (condition=="AfterA" | condition=="BeforeA" ) 
replace incentiveforA=0 if  (condition=="AfterB" | condition=="BeforeB" ) 

gen incentiveB=1-incentiveforA

drop newid

save "${data}InformationArchitect_advisors.dta", replace


	
******* APPENDIX *********
	
/*-------------------------------*/	
*NO CHOICE - TOGETHER for APPENDIX
/*-------------------------------*/	

clear
import delimited "${raw}NoChoiceSimoultaneous_deidentified.csv", varnames(1)


drop if status==1
*drop if workerid==""
tab distributionchannel
drop if distributionchannel=="preview"
tab finished
keep if finished==1


sort newid
quietly by newid:  gen dup = cond(_N==1,0,_n)
tab dup
drop if dup!=0

rename q32 attention

g attentionpassed=attention==3
keep if attentionpassed==1


tab q_recaptchascore
drop if q_recaptchascore<.5


sort startdate
gen id=_n + 80000


*Beliefs
g beliefbin=q45 
g beliefnum=q43

**Gender
gen female=.
replace female=1 if gender==2
replace female=0 if gender==1



gen treatment=0
replace treatment =1 if condition=="BeforeA" | condition=="BeforeB"
replace treatment =2 if condition=="AfterA" | condition=="AfterB"
replace treatment =3 if condition=="TogetherA" | condition=="TogetherB"


g recommendb=(recommendationa==2 | recommendationb==2)


gen signalblue=.
replace signalblue=1 if fl_259_do=="All-Signalblue-incentiveA"
replace signalblue=0 if fl_259_do=="All-Signalred-incentiveA"
replace signalblue=0 if fl_268_do=="All-Signalred-incentiveB"
replace signalblue=1 if fl_268_do=="All-Signalblue-incentiveB"
replace signalblue=1 if fl_211_do=="Signal_blue2"
replace signalblue=0 if fl_211_do=="Signal_red0"
replace signalblue=1 if fl_221_do=="Signal_blue2"
replace signalblue=0 if fl_221_do=="Signal_red0"
replace signalblue=1 if fl_229_do=="Signal_blue2"
replace signalblue=0 if fl_229_do=="Signal_red0"
replace signalblue=1 if fl_127_do=="Signal_blue2"
replace signalblue=0 if fl_127_do=="Signal_red0"

gen conflict=0
replace conflict=1 if cond=="AfterA" & signalblue==1
replace conflict=1 if cond=="AfterB" & signalblue==0
replace conflict=1 if cond=="BeforeA" & signalblue==1
replace conflict=1 if cond=="BeforeB" & signalblue==0
replace conflict=1 if cond=="TogetherA" & signalblue==1
replace conflict=1 if cond=="TogetherB" & signalblue==0


tab conflict

gen recommendincentive=0                             
replace recommendincentive=1 if (cond=="AfterA" | cond=="BeforeA" | cond=="TogetherA") & recommendb==0
replace recommendincentive=1 if (cond=="AfterB" | cond=="BeforeB" | cond=="TogetherB") & recommendb==1

gen incentiveforA=.
replace incentiveforA=1 if  (cond=="AfterA" | cond=="BeforeA" | cond=="TogetherA") 
replace incentiveforA=0 if  (cond=="AfterB" | cond=="BeforeB" | cond=="TogetherB") 

gen incentiveB=1-incentiveforA

*Prosociality 		
forval i=2(1)5{
recode q8`i' (1=0) (2=1)
}

rename q82 alpha1
rename q83 alpha2
rename q84 alpha3
rename q85 alpha4
rename q176 alpha5
recode alpha5 (1=0) (2=1)

egen alphamiss=rowmiss(alpha1 alpha2 alpha3 alpha4) 
tab alphamiss

*alpha1-5 equal 1 is recommend the incentivized option 

*RESTRICTING RESPONDENTS TO THOSE WITH COMPLETE ALPHA CHOICES
keep if alphamiss==0

*Prosociality switch 
reshape long alpha, i(id) j(number)
	
sort id number		
g previouschoice=alpha[_n-1] if number>1		
g steptob=(alpha-previouschoice) if number>1
bys id: egen sumsteptob=total(steptob) 

*Alpha value final = number of times you go with the incentive to recommend Y
g alphavalue=0 if sumsteptob==0 & alpha==0 & number==5 /*always choosing X, no incentive*/
replace alphavalue=5 if sumsteptob==0 & alpha==1 & number==5 /*always choosing Y, incentive*/
*Alpha value is the question number when the steptob is 1 for those who switch
replace alphavalue=number-1 if sumsteptob==1 & steptob==1 

g inconsistentchoice=(steptob==-1)
bys id: egen inconsistentid=total(inconsistentchoice) 

bys id: egen alphavaluefinal=total(alphavalue) 
replace alphavaluefinal=. if inconsistentid>0

tab alphavaluefinal, m
cap drop alphavalue inconsistentchoice previouschoice steptob
reshape wide alpha, i(id) j(number)

*alpha
tab alphavaluefinal if treatment!=., m


gen seeincentivefirst=(treatment==1)

gen Together=(treatment==3)

gen noconflict=1-conflict

gen wave=2


gen missingalpha=(alphavaluefinal==.)

drop responseid newid shortid

save "${data}NoChoiceSimoultaneous.dta", replace

	
/*-------------------------------*/	
*CHOICE DETERMINISTIC
/*-------------------------------*/	

clear
import delimited "${raw}ChoiceDeterministic_deidentified.csv", varnames(1)


drop if status==1
tab distributionchannel
drop if distributionchannel=="preview"
tab finished
keep if finished==1


sort newid
quietly by newid:  gen dup = cond(_N==1,0,_n)
tab dup
drop if dup!=0

drop if  q_recaptchascore<.50


g id=_n + 90000
tab attention, m
g attentionpassed=attention==3

tab attentionpassed
**78.89% passed the attention check (N=953) out of 1200 who completed the attention check question and were not excluded according to the criteria above
drop if attentionpassed!=1


tab belief
replace belief=belief*100 if belief<1

***Gen recommendB and recommenda dummies

g recommendb=.
replace recommendb=1 if  recommendationb==2
replace recommendb=0 if  recommendationb==1

replace recommendb=1 if  recommendationa==2
replace recommendb=0 if  recommendationa==1


g recommenda=1-recommendb	


***gen IncentiveB
g incentiveB=.
replace incentiveB=1 if commission=="commissionB"
replace incentiveB=0 if commission=="commissionA"

g incentiveA=.
replace incentiveA=1 if commission=="commissionA"
replace incentiveA=0 if commission=="commissionB"


*GET by treatment
g getafter=(getbefore=="GetAfter") 
cap drop getbefore
g getbefore=1-getafter



**gen bluesignal dummy
g signalblue=.
replace signalblue=1 if fl_528_do=="Signal_blue2"
replace signalblue=1 if fl_1034_do=="Signal_blue2"
replace signalblue=1 if fl_555_do=="Signal_blue2"
replace signalblue=1 if fl_1047_do=="Signal_blue2"
replace signalblue=1 if fl_629_do=="Signal_blue2"
replace signalblue=1 if fl_642_do=="Signal_blue2"
replace signalblue=1 if fl_1060_do=="Signal_blue2"
replace signalblue=1 if fl_1073_do=="Signal_blue2"

replace signalblue=0 if fl_528_do=="Signal_red0"
replace signalblue=0 if fl_555_do=="Signal_red0"
replace signalblue=0 if fl_1047_do=="Signal_red0"
replace signalblue=0 if fl_1034_do=="Signal_red0"
replace signalblue=0 if fl_629_do=="Signal_red0"
replace signalblue=0 if fl_642_do=="Signal_red0"
replace signalblue=0 if fl_1060_do=="Signal_red0"
replace signalblue=0 if fl_1073_do=="Signal_red0"
drop if signalblue==.

g conflict=.
replace conflict=1 if signalblue==0 & commission=="commissionB"
replace conflict=0 if signalblue==1 & commission=="commissionB"
replace conflict=1 if signalblue==1 & commission=="commissionA"
replace conflict=0 if signalblue==0 & commission=="commissionA"
	

tab commission 
g recommendincentive=recommendb if commission=="commissionB"
replace recommendincentive=recommenda if commission=="commissionA"	


gen choicebefore=.
replace choicebefore=1 if choicefree==1
replace choicebefore=0 if choicefree==2



**Gender
gen female=.
replace female=1 if gender==2
replace female=0 if gender==1


***Prosociality
forval i=1(1)5{
recode alpha`i' (1=0) (2=1)
}	

egen alphamiss=rowmiss(alpha1 alpha2 alpha3 alpha4) 
keep if alphamiss==0

g sample="MTurk"
rename q211 explanationchoice
gen costlydemand=0


reshape long alpha, i(id) j(number)
	
sort id number		
g previouschoice=alpha[_n-1] if number>1		
g steptob=(alpha-previouschoice) if number>1
bys id: egen sumsteptob=total(steptob) 

*Alpha value final = number of times you go with the incentive to recommend Y
g alphavalue=0 if sumsteptob==0 & alpha==0 & number==5 /*always choosing X, no incentive*/
replace alphavalue=5 if sumsteptob==0 & alpha==1 & number==5 /*always choosing Y, incentive*/
*Alpha value is the question number when the steptob is 1 for those who switch
replace alphavalue=number-1 if sumsteptob==1 & steptob==1 

g inconsistentchoice=(steptob==-1)
bys id: egen inconsistentid=total(inconsistentchoice) 

bys id: egen alphavaluefinal=total(alphavalue) 
replace alphavaluefinal=. if inconsistentid>0

tab alphavaluefinal, m
cap drop alphavalue inconsistentchoice previouschoice steptob
reshape wide alpha, i(id) j(number)

*Average alpha
tab alphavaluefinal, m


gen Deterministic=(condition=="ChoiceFree_Deterministic")

egen stdalpha=std(alphavaluefinal)

* prepare data for regressions
g getbefore_Deterministic=getbefore*Deterministic	
label var getbefore_Deterministic "Get Before X Deterministic"

gen Not_getyourchoice=0
replace Not_getyourchoice=1 if choicebefore==1 & getbefore==0
replace Not_getyourchoice=1 if choicebefore==0 & getbefore==1
gen getyourchoice=1-Not_getyourchoice

gen choicebefore_Notgetyourchoice=choicebefore*Not_getyourchoice
gen noconflict=1-conflict
gen noconflict_choicebefore=noconflict*choicebefore
gen noconflict_Notgetyourchoice=noconflict*Not_getyourchoice

gen choicebefore_Deterministic=choicebefore*Deterministic
gen choicebefore_getyourchoiceDet=choicebefore*getyourchoice*Deterministic
gen choicebefore_noconflict=choicebefore*noconflict
gen Deterministic_noconflict=Deterministic*noconflict
gen Deterministic_choicebeforeNocon=Deterministic*noconflict*choicebefore

label var getyourchoice "Random Assignment to Preferred Order"
label var choicebefore_getyourchoice "Prefer to See Incentive First X Random Assignment"

gen getyourchoice_Det=getyourchoice*Deterministic

drop responseid newid shortid dup
drop fl_728_do fl_17_do fl_481_do fl_523_do fl_528_do fl_1034_do fl_548_do fl_555_do fl_1047_do fl_563_do fl_657_do fl_629_do fl_1060_do fl_656_do fl_642_do fl_1073_do
save "${data}Choice_Deterministic.dta", replace

/*-------------------------------*/	
*PREDICTIONS
/*-------------------------------*/	
clear
import excel "${raw}predictions_explanations_coded_deidentified.xlsx", firstrow
save "${data}predictions_explanations_coded.dta", replace

clear
import excel "${raw}predictions_deidentified.xlsx", firstrow


drop if _n<3
drop if status==1
drop if q_relevantidduplicate==1
drop if q_relevantidfraudscore!=0

destring  predictbeforered_es_1 predictafterred_es_1 predictbeforeblue_es_1 predictafterblue_es_1, force replace

g predictbeforered1=predictbeforered_es_1
g predictafterred1=predictafterred_es_1
g predictbeforeblue1=predictbeforeblue_es_1
g predictafterblue1=predictafterblue_es_1
g gapred=predictbeforered1-58 if predictbeforered1!=.
replace gapred=68-predictafterred1 if predictafterred1!=.
g gapblue=predictbeforeblue1-75 if predictbeforeblue1!=.
replace gapblue=86-predictafterblue1 if predictafterblue1!=.

g gap=gapred if gapred!=.
replace gap=gapblue if gapblue!=.

g choice="Predictions"

tab gap
drop if gap==.

merge 1:1 shortid using "${data}predictions_explanations_coded.dta" 


g attentivenum=attentive=="YES"
tab attentivenum
keep if attentivenum==1

tab gender 
destring age, force replace
tabstat age


replace gap=gap/100	
replace gapred=gapred/100	
replace gapblue=gapblue/100	
	
egen meangap=mean(gap)
egen sdgap=sd(gap)
egen ngap=count(gap)

g logap = meangap - sdgap/(sqrt(ngap))
g higap = meangap + sdgap/(sqrt(ngap))


g predicteddirection=predictafterred if predictafterred!=.
replace predicteddirection=predictbeforered if predictbeforered!=.
replace predicteddirection=predictafterblue if predictafterblue!=.
replace predicteddirection=predictbeforeblue if predictbeforeblue!=.


g before=1 if predictbeforered!=. | predictbeforeblue!=.
replace before=0 if predictafterred!=. | predictafterblue!=.

g predictcorrect=1 if (predicteddirection==1 & before==0) | (predicteddirection==3 & before==1)
replace predictcorrect=0 if (predicteddirection==2 & before==0) | (predicteddirection==2 & before==1)
replace predictcorrect=-1 if (predicteddirection==3 & before==0) | (predicteddirection==1 & before==1)

drop _merge responseid
save "${data}predictionsstudy.dta", replace

/*-------------------------------*/	
*CLIENTS
/*-------------------------------*/	

*** NOCHOICE, CHOICE AND STAKES EXPERIMENTS - MAIN
clear
import delimited using "${raw}Clients/Clients_Main_deidentified.csv", varnames(1)

gen follow=.
replace follow=1 if client_choiceb==1 & advisor_recommendb==1
replace follow=1 if client_choiceb==0 & advisor_recommendb==0
replace follow=0 if client_choiceb==0 & advisor_recommendb==1
replace follow=0 if client_choiceb==1 & advisor_recommendb==0

save "${data}Clients_Main.dta", replace


*** CLIENTS ** NOCHOICE, CHOICE AND STAKES EXPERIMENTS - MPL

clear
import delimited using "${raw}Clients/Clients_MPL_deidentified.csv", varnames(1)

gen follow=.
replace follow=1 if advisor_recommends_producty==1 & client_choicey==1
replace follow=1 if advisor_recommends_producty==0 & client_choicey==0
replace follow=0 if advisor_recommends_producty==0 & client_choicey==1
replace follow=0 if advisor_recommends_producty==1 & client_choicey==0

save "${data}Clients_MPL.dta", replace

*** CLIENTS ** NOCHOICE, CHOICE AND STAKES EXPERIMENTS - BLINDING

clear
import delimited using "${raw}Clients/Clients_Blinding_deidentified.csv", varnames(1)


gen follow=.
replace follow=1 if recommendation_infoavoidance==1 & choice1==1
replace follow=1 if recommendation_infoavoidance==0 & choice1==0
replace follow=0 if recommendation_infoavoidance==0 & choice1==1
replace follow=0 if recommendation_infoavoidance==1 & choice1==0

save "${data}Clients_Blinding.dta", replace

*** CLIENTS ** INFORMATION ARCHITECTS - MAIN
clear 
import delimited using "${raw}Clients/Clients_InfoArchitectsMain_deidentified.csv", varnames(1)

gen follow=.
replace follow=1 if client_choiceb==1 & advisor_recommendb==1
replace follow=1 if client_choiceb==0 & advisor_recommendb==0
replace follow=0 if client_choiceb==0 & advisor_recommendb==1
replace follow=0 if client_choiceb==1 & advisor_recommendb==0

save "${data}Clients_InfoArchitectsMain.dta", replace

*** CLIENTS ** INFORMATION ARCHITECTS - MPL ADVISORS

clear 
import delimited using "${raw}Clients/Clients_IAAdvisors_MPL_deidentified.csv", varnames(1)


gen follow=.
replace follow=1 if advisor_recommends_producty==1 & client_choicey==1
replace follow=1 if advisor_recommends_producty==0 & client_choicey==0
replace follow=0 if advisor_recommends_producty==0 & client_choicey==1
replace follow=0 if advisor_recommends_producty==1 & client_choicey==0

save "${data}Clients_IAAdvisors_MPL.dta", replace

*** CLIENTS ** INFORMATION ARCHITECTS - MPL INFO ARCHITECTS
clear
import delimited using "${raw}Clients/Clients_IAInfoArchitects_MPL_deidentified.csv", varnames(1)


gen follow=.
replace follow=1 if advisor_recommends_producty==1 & client_choicey==1
replace follow=1 if advisor_recommends_producty==0 & client_choicey==0
replace follow=0 if advisor_recommends_producty==0 & client_choicey==1
replace follow=0 if advisor_recommends_producty==1 & client_choicey==0

save "${data}Clients_IAInfoArchitects_MPL.dta", replace


*** CLIENTS ** NOCHOICE SIMULTANEOUS - MAIN

clear 
import delimited using "${raw}Clients/Clients_NoChoiceSimultaneousMain_deidentified.csv", varnames(1)

gen follow=.
replace follow=1 if advisor_recommendb==1 & client_choiceb==1
replace follow=1 if advisor_recommendb==0 & client_choiceb==0
replace follow=0 if advisor_recommendb==0 & client_choiceb==1
replace follow=0 if advisor_recommendb==1 & client_choiceb==0

save "${data}Clients_NoChoiceSimultaneousMain.dta", replace


*** CLIENTS ** NOCHOICE SIMULTANEOUS - MPL

clear
import delimited using "${raw}Clients/Clients_NoChoiceSimultaneousMPL_deidentified.csv", varnames(1)


gen follow=.
replace follow=1 if advisor_recommends_producty==1 & client_choicey==1
replace follow=1 if advisor_recommends_producty==0 & client_choicey==0
replace follow=0 if advisor_recommends_producty==0 & client_choicey==1
replace follow=0 if advisor_recommends_producty==1 & client_choicey==0

save "${data}Clients_NoChoiceSimultaneousMPL.dta", replace

*** CLIENTS ** CHOICE DETERMINISTIC - MAIN
clear 
import delimited using "${raw}Clients/Clients_ChoiceDeterministic_Main_deidentified.csv", varnames(1)
gen follow=.
replace follow=1 if advisor_recommendb==1 & client_choiceb==1
replace follow=1 if advisor_recommendb==0 & client_choiceb==0
replace follow=0 if advisor_recommendb==0 & client_choiceb==1
replace follow=0 if advisor_recommendb==1 & client_choiceb==0

save "${data}Clients_ChoiceDeterministic_Main.dta", replace

*** CLIENTS ** CHOICE DETERMINISTIC - MPL


clear 
import delimited using "${raw}Clients/Clients_ChoiceDeterministic_MPL_deidentified.csv", varnames(1)


gen follow=.
replace follow=1 if advisor_recommends_producty==1 & client_choicey==1
replace follow=1 if advisor_recommends_producty==0 & client_choicey==0
replace follow=0 if advisor_recommends_producty==0 & client_choicey==1
replace follow=0 if advisor_recommends_producty==1 & client_choicey==0

save "${data}Clients_ChoiceDeterministic_MPL.dta", replace

*drop unnecessary files
rm "${data}choice1.dta"
rm "${data}choice2.dta"
rm "${data}choice3.dta"
rm "${data}professionals_prolific.dta"

... [truncated: 36 more bytes of this script omitted] ...

```

## How to run a script

Write each script to a file under the output directory, then run it with
exactly this command (the data directory is mounted read-only at its own
path; nothing else from the host is visible; `$SCRIPT` is the absolute path of
the script you wrote):

    SCRIPT=<repo>/benchmark/reproductions/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a/script.R   # or <repo>/benchmark/reproductions/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a/attempt-<n>/script.R
    uv run --directory <repo> python -m benchmark.reproducers.run_sandbox --timeout 300 --label retally.run=claude-code-saccardo-2023-demand-moral-commitment-seeded-2026-11-10-a --run-dir "$(dirname "$SCRIPT")" -- docker run --rm --label retally.run=claude-code-saccardo-2023-demand-moral-commitment-seeded-2026-11-10-a --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a/mount/saccardo_2023_demand_moral_commitment:<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a/mount/saccardo_2023_demand_moral_commitment:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R; echo "exit code: $?"

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

The output directory `<repo>/benchmark/reproductions/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a/
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

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a`.
