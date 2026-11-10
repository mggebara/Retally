# Retally reproduction task: lopez-2022-patient-demand-prescription-overuse (seeded, run 2026-11-10-a)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `lopez-2022-patient-demand-prescription-overuse`, mode `seeded`, run `2026-11-10-a`
- Paper: Does Patient Demand Contribute to the Overuse of Prescription Drugs?
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a/mount/lopez_2022_patient_demand_prescription_overuse`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a/mount/lopez_2022_patient_demand_prescription_overuse` as data, and `<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a/paper.txt` as
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

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Claims to Reproduce
1. voucher_used_patient_voucher_table3_col1: 0.35 (change in the probability of using a voucher (share of patients)) [type: coefficient]
   Location: Table 3, column (1) Used Voucher, beta_P: Patient Voucher
   Context: Table 3 ("Impacts on Malaria Treatment Outcomes"), column (1). Linear probability model of an indicator that the patient redeemed a voucher for a free course of ACT tablets (simple malaria treatment), from the administrative voucher records, on dummies for Patient Voucher days (vouchers handed to patients on arrival, before the consultation) and Doctor Voucher days (vouchers given to the health workers to assign at their discretion), relative to Control days, with clinic visit date fixed effects and additional controls chosen by post-double-selection lasso (Belloni, Chernozhukov and Hansen 201…
2. voucher_used_doctor_voucher_table3_col1: 0.26 (change in the probability of using a voucher (share of patients)) [type: coefficient]
   Location: Table 3, column (1) Used Voucher, beta_D: Doctor Voucher
   Context: Table 3, column (1): the same lasso-controlled regression of voucher use on the Patient Voucher and Doctor Voucher day dummies with date fixed effects. The entry is the Doctor Voucher coefficient (voucher use relative to Control days, where no vouchers were available). Standard errors clustered by clinic.
3. any_malaria_treatment_prescribed_patient_voucher_table3_col2: 0.052 (change in the probability of an antimalarial prescription) [type: coefficient]
   Location: Table 3, column (2) Any Malaria Treatment, Prescribed, beta_P: Patient Voucher
   Context: Table 3, column (2). Linear probability model of an indicator that the patient was prescribed any malaria treatment (simple or severe) at the consultation, on the Patient Voucher and Doctor Voucher day dummies with clinic visit date fixed effects and the post-double-selection lasso controls of column (1). The entry is the Patient Voucher coefficient. Standard errors clustered by clinic.
4. any_malaria_treatment_prescribed_doctor_voucher_table3_col2: 0.016 (change in the probability of an antimalarial prescription) [type: coefficient]
   Location: Table 3, column (2) Any Malaria Treatment, Prescribed, beta_D: Doctor Voucher
   Context: Table 3, column (2): any malaria treatment prescribed, same specification (date fixed effects, lasso-selected controls, clinic-clustered standard errors). The entry is the Doctor Voucher coefficient.
5. any_malaria_treatment_purchased_patient_voucher_table3_col3: 0.14 (change in the probability of purchasing an antimalarial) [type: coefficient]
   Location: Table 3, column (3) Any Malaria Treatment, Purchased, beta_P: Patient Voucher
   Context: Table 3, column (3). Linear probability model of an indicator that the patient purchased (obtained) any malaria treatment at the clinic, on the Patient Voucher and Doctor Voucher day dummies with clinic visit date fixed effects and the post-double-selection lasso controls. The entry is the Patient Voucher coefficient. Standard errors clustered by clinic.
6. any_malaria_treatment_purchased_doctor_voucher_table3_col3: 0.085 (change in the probability of purchasing an antimalarial) [type: coefficient]
   Location: Table 3, column (3) Any Malaria Treatment, Purchased, beta_D: Doctor Voucher
   Context: Table 3, column (3): any malaria treatment purchased, same specification. The entry is the Doctor Voucher coefficient; standard errors clustered by clinic.
7. severe_malaria_treatment_prescribed_patient_voucher_table3_col4: -0.046 (change in the probability of a severe malaria treatment prescription) [type: coefficient]
   Location: Table 3, column (4) Severe Malaria Treatment, Prescribed, beta_P: Patient Voucher
   Context: Table 3, column (4). Linear probability model of an indicator that the patient was prescribed severe malaria treatment (the more expensive treatment, usually an injection or IV drip), on the Patient Voucher and Doctor Voucher day dummies with clinic visit date fixed effects and the post-double-selection lasso controls. The entry is the Patient Voucher coefficient. Standard errors clustered by clinic.
8. severe_malaria_treatment_prescribed_doctor_voucher_table3_col4: -0.054 (change in the probability of a severe malaria treatment prescription) [type: coefficient]
   Location: Table 3, column (4) Severe Malaria Treatment, Prescribed, beta_D: Doctor Voucher
   Context: Table 3, column (4): severe malaria treatment prescribed, same specification. The entry is the Doctor Voucher coefficient; standard errors clustered by clinic.
9. severe_malaria_treatment_purchased_patient_voucher_table3_col5: -0.022 (change in the probability of purchasing severe malaria treatment) [type: coefficient]
   Location: Table 3, column (5) Severe Malaria Treatment, Purchased, beta_P: Patient Voucher
   Context: Table 3, column (5). Linear probability model of an indicator that the patient purchased severe malaria treatment at the clinic, on the Patient Voucher and Doctor Voucher day dummies with clinic visit date fixed effects and the post-double-selection lasso controls. The entry is the Patient Voucher coefficient. Standard errors clustered by clinic.
10. severe_malaria_treatment_purchased_doctor_voucher_table3_col5: -0.05 (change in the probability of purchasing severe malaria treatment) [type: coefficient]
   Location: Table 3, column (5) Severe Malaria Treatment, Purchased, beta_D: Doctor Voucher
   Context: Table 3, column (5): severe malaria treatment purchased, same specification. The entry is the Doctor Voucher coefficient; standard errors clustered by clinic.
11. n_obs_table3_col1: 2055.0 (patients) [type: count]
   Location: Table 3, N, column (1)
   Context: Number of observations in Table 3, column (1) (voucher use): all patients interviewed in the in-clinic survey.
12. n_obs_table3_cols2_5: 2053.0 (patients) [type: count]
   Location: Table 3, N, columns (2)-(5)
   Context: Number of observations in Table 3, columns (2) through (5) (malaria treatment prescribed and purchased): the in-clinic survey patients with prescription and purchase outcomes recorded.

## Dataset Information
Name: lopez_2022_patient_demand_prescription_overuse
Local path: <repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a/mount/lopez_2022_patient_demand_prescription_overuse
File format: csv
Files in the dataset directory (paths relative to the local path above):
- Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta (53.4 MB) — 2770 rows, 4266 columns: patient, home, date_home_survey, date, gender, french, records, malaria, selected_home_survey, respondent, primary_bambara, pregnancy, injection_IV, patient_voucher, doctor_voucher, CC28xCC39, CC34xCC39, M0prischoolorless, CC39, CC39xCC41, treat_simple_mal_voucher, treat_severe_mal_voucher, RXtreat_simple_mal_voucher, RXtreat_severe_mal_voucher, interventionmorning_2_M, prischoolorless, NBcscom_treat_simple_mal, NBcscom_treat_severe_mal, treat_simple_mal_NOvoucher, treat_severe_mal_NOvoucher, RXtreat_simple_mal_NOvoucher, RXtreat_severe_mal_NOvoucher, correct_simple_mal, correct_severe_mal, correct_sev_simple_mal, U_correct_simple_mal, U_correct_severe_mal, U_correct_sev_simple_mal, H_correct_simple_mal, H_correct_severe_mal…
- Lopez_Sautmann_Schaner_2020/Data/LSS_DoctorEndlineInterview.dta (314.3 KB) — 162 rows, 247 columns: doctor, act_simple, correct_treat_simple_mal, correct_treat_severe_mal, surveyorid, howpatientsrespond, patients_accept, datedoctor, timedoctor, consentdoctoryesno, sendpatient, illness1, desc_otherillness1, illness2, desc_otherillness2, patientunder5, illness1under5, other_illness1under5, illness2under5, other_illness2under5, patientabove5, illness1above5, other_illness1above5, illness2above5, other_illness2above5, patientdiagnosis, patientdiagnosis_1, patientdiagnosis_2, pa…
- Lopez_Sautmann_Schaner_2020/Data/LSS_CSComCensus.dta (50.8 KB) — 60 rows, 43 columns: Date, cscomnum_OS, q1_open, q1_close, q1_doc_open, q1_doc_close, q2_pharm_open_MF, q2_pharm_close_MF, q2_pharm_open_we, q2_pharm_close_we, q3_intern_open_MF, q3_intern_close_MF, q3_intern_open_we, q3_intern_close_we, q4_num_saldoc, q4_num_intern, q4_othRX, q5a, q5b, q5c, q5d, q6a, q6b, q6c, q6d, q7a, q7b, q8a, q8b, q9a, q9b, q10a, q10b, q11a, q11b, q12a, q12b, q13_1, q13_2, q13_3, q13_4, q13_5a, q13_5b
- Lopez_Sautmann_Schaner_2020/1_README.pdf (211.2 KB)
- Lopez_Sautmann_Schaner_2020/Do_Files/Figures/3_graph_outcomeXpredpos_control.do (2.8 KB)
- Lopez_Sautmann_Schaner_2020/Do_Files/Figures/4_graph_tmtXpredpos.do (3.3 KB)
- Lopez_Sautmann_Schaner_2020/Do_Files/Figures/5_graph_voucher_tmt.do (1.4 KB)
- Lopez_Sautmann_Schaner_2020/Do_Files/Figures/B1_graph_misallocation.do (1.4 KB)
- Lopez_Sautmann_Schaner_2020/Do_Files/Figures/B2_graph_dist_pred_pos.do (729 B)
- Lopez_Sautmann_Schaner_2020/Do_Files/Figures/B3_graph_outcomeXpredpos_control_home.do (3.4 KB)
- Lopez_Sautmann_Schaner_2020/Do_Files/Figures/B4_graph_vouchersXbins.do (4.2 KB)
- Lopez_Sautmann_Schaner_2020/Do_Files/LSS_master_data_analysis.do (29.7 KB)
- Lopez_Sautmann_Schaner_2020/Do_Files/Stata admin files/LSS_TablePrograms.do (56.0 KB)
- Lopez_Sautmann_Schaner_2020/Do_Files/Stata admin files/LSS_config_stata.do (1.7 KB)
- Lopez_Sautmann_Schaner_2020/Do_Files/Stata admin files/LSS_make_bootstrap_repsets.do (1.7 KB)
- Lopez_Sautmann_Schaner_2020/Do_Files/Tables/1_table_control_group.do (6.0 KB)
- Lopez_Sautmann_Schaner_2020/Do_Files/Tables/2_table_balance.do (13.7 KB)
- Lopez_Sautmann_Schaner_2020/Do_Files/Tables/B1_table_clinic_census.do (6.8 KB)
- Lopez_Sautmann_Schaner_2020/Do_Files/Tables/B2_table_means_doctor.do (3.7 KB)
- Lopez_Sautmann_Schaner_2020/Do_Files/Tables/B5_table_selection.do (11.9 KB)
- Lopez_Sautmann_Schaner_2020/Do_Files/Tables/B6_table_diff_test_consent.do (12.7 KB)
- Lopez_Sautmann_Schaner_2020/Do_Files/Tables/B7_table_mal_prob_probit.do (2.4 KB)
- Lopez_Sautmann_Schaner_2020/Figures/1_DocPat-graphs-theory-figure-2020-08-28.pdf (137.2 KB)
- Lopez_Sautmann_Schaner_2020/Figures/2_DocPat-InterventionScheduleDiagram.pdf (58.3 KB)
- Lopez_Sautmann_Schaner_2020/Figures/3_outcomeXpredpos_control.pdf (30.4 KB)
- Lopez_Sautmann_Schaner_2020/Figures/4_tmtXpredpos.pdf (48.2 KB)
- Lopez_Sautmann_Schaner_2020/Figures/5_voucher_tmt.pdf (17.6 KB)
- Lopez_Sautmann_Schaner_2020/Figures/B1_misallocation.pdf (17.0 KB)
- Lopez_Sautmann_Schaner_2020/Figures/B2_dist_pred_pos.pdf (25.4 KB)
- Lopez_Sautmann_Schaner_2020/Figures/B3_outcomeXpredpos_control_home.pdf (35.4 KB)
- Lopez_Sautmann_Schaner_2020/Figures/B4_vouchersXbins.pdf (21.0 KB)
- Lopez_Sautmann_Schaner_2020/LSS_Appendix_Replication.tex (6.1 KB)
- Lopez_Sautmann_Schaner_2020/LSS_Main_Replication.tex (5.4 KB)
- Lopez_Sautmann_Schaner_2020/Survey Instruments/CSComPatientInterview_Questionnaire.pdf (13.6 MB)
- Lopez_Sautmann_Schaner_2020/Survey Instruments/DocPat-ClinicCensus-FR-2016-05-17.pdf (214.5 KB)
- Lopez_Sautmann_Schaner_2020/Survey Instruments/DoctorEndlineInterview_Questionnaire.pdf (196.4 KB)
- Lopez_Sautmann_Schaner_2020/Survey Instruments/HomePatientInterview_Questionnaire.pdf (580.2 KB)
- Lopez_Sautmann_Schaner_2020/Survey Instruments/Interventions_Notes.pdf (135.1 KB)
- Lopez_Sautmann_Schaner_2020/Survey Instruments/MorningCSComID_Questionnaire.pdf (135.8 KB)
- Lopez_Sautmann_Schaner_2020/Tables/1_control_group.tex (14.1 KB)
- Lopez_Sautmann_Schaner_2020/Tables/2_balance.tex (61.2 KB)
- Lopez_Sautmann_Schaner_2020/Tables/3_mal_tmt_overall_new_lso.tex (3.3 KB)
- Lopez_Sautmann_Schaner_2020/Tables/4_mal_tmt_het_new_lso.tex (4.2 KB)
- Lopez_Sautmann_Schaner_2020/Tables/5_expected_match_decomp_lso.tex (2.9 KB)
- Lopez_Sautmann_Schaner_2020/Tables/A1_theory_table.tex (3.5 KB)
- Lopez_Sautmann_Schaner_2020/Tables/B10_mal_tmt_overall_nl.tex (2.9 KB)
- Lopez_Sautmann_Schaner_2020/Tables/B11_mal_tmt_het_nl.tex (4.4 KB)
- Lopez_Sautmann_Schaner_2020/Tables/B12_vouchers_tmt_lso.tex (2.2 KB)
- Lopez_Sautmann_Schaner_2020/Tables/B13_stockpiling_lso.tex (1.7 KB)
- Lopez_Sautmann_Schaner_2020/Tables/B14_mal_testing_info_RX_lso.tex (4.2 KB)
- Lopez_Sautmann_Schaner_2020/Tables/B15_cost_overall_lso.tex (3.1 KB)
- Lopez_Sautmann_Schaner_2020/Tables/B16_expected_match_lso.tex (2.4 KB)
- Lopez_Sautmann_Schaner_2020/Tables/B1_clinic_census.tex (13.4 KB)
- Lopez_Sautmann_Schaner_2020/Tables/B2_means_doctor.tex (6.7 KB)
- Lopez_Sautmann_Schaner_2020/Tables/B3_mal_tmt_pat_info_lso.tex (2.4 KB)
- Lopez_Sautmann_Schaner_2020/Tables/B4_mal_tmt_doc_info_lso.tex (2.4 KB)
- Lopez_Sautmann_Schaner_2020/Tables/B5_selection.tex (14.5 KB)
- Lopez_Sautmann_Schaner_2020/Tables/B6_diff_test_consent.tex (80.8 KB)
- Lopez_Sautmann_Schaner_2020/Tables/B7_mal_prob_probit.tex (2.4 KB)
- Lopez_Sautmann_Schaner_2020/Tables/B8_mal_tmt_overall_nc.tex (2.4 KB)
- Lopez_Sautmann_Schaner_2020/Tables/B9_mal_tmt_het_nc.tex (4.0 KB)
- metadata.json (241 B)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a/mount/lopez_2022_patient_demand_prescription_overuse' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
Installed packages (no network; nothing else can be installed): jsonlite, fixest, lfe, AER, ivreg, plm, estimatr, lme4, quantreg, car, sandwich, lmtest, clubSandwich, multiwayvcov, marginaleffects, MatchIt, optmatch, CBPS, WeightIt, cobalt, did, rdrobust, rddensity, Synth, modelsummary, stargazer, texreg, broom, tidyverse, dplyr, tidyr, readr, stringr, lubridate, data.table, haven, readxl, janitor, zoo, ggplot2, ggridges, ggrepel, gridExtra, cowplot, gtable, extrafont, sf, MASS, nnet, survival, splines, Matrix, boot, stats, utils.
Prefer fixest for fixed effects, IV and clustered SEs; use the other installed packages where the paper's method calls for them.
Set a deterministic seed with ``set.seed(42)`` for any randomness.
Do NOT access the internet; the container runs with --network none.
Do NOT shell out via system() / system2().
Emit RESULT:<name>=<value> lines to stdout at the end via cat().

## Original Replication Scripts
The replication package (the dataset directory) ships the authors' own analysis scripts, reproduced below.  These are the GROUND TRUTH for the exact estimating equation, variable names, sample restrictions, fixed effects, and standard-error clustering — follow them over anything reconstructed from the methodology summary, and prefer them over the paper's text where the two disagree.  Your job is to write R code that implements the SAME SPECIFICATION: translate what the scripts estimate, do not transliterate their syntax line by line (a Stata .do file's regression, e.g. `reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the equivalent fixest::feols() call in R).  Keep only the parts that produce the specific claims being reproduced; skip figure construction and unrelated robustness checks.  The scripts' data-file paths refer to the package's internal layout — resolve them against the dataset directory listed under Dataset Information.

Stata-to-fixest sample matching: feols() drops fixed-effect singletons by default, but Stata's `reg y x i.fe` / `xi:` dummies keep them.  Pass `fixef.rm = "none"` to every feols() call that has fixed effects, otherwise the observation count and the robust SEs drift from the paper's.  Stata's `, r` / `vce(robust)` is `vcov = "hetero"`.

### `Lopez_Sautmann_Schaner_2020/Do_Files/LSS_master_data_analysis.do`
```stata
/*------------------------------------------------------------------------------
********************************************************************************
* Lopez, Sautmann, Schaner; AEJ Applied
********************************************************************************

** Analysis file creating tables and data based figures in the paper.
** This version: January, 2021

------------------------------------------------------------------------------*/

clear all
set more off
set matsize 5000
version 13.1
	cap graph set window fontface Times-Roman 

		
********************************************************************************
* Users: Change this section the first time. 
*------------------------------------------
* Define paths: 
*------------

*	global path "../Lopez_Sautmann_Schaner_2020" // use ../ for relative path.

	global data_final= "$path/Data"
	global dofiles_fig   = "$path/Do_Files/Figures"
	global dofiles_tab   = "$path/Do_Files/Tables"
	global dofiles_admin   = "$path/Do_Files/Stata admin files"
	global tables = "$path/Tables"
	global graphs = "$path/Figures"

global prehead1 "\begin{tabular}{l*{"
global prehead2 "}{c}} \hline\hline"

* data set names 
*---------------
global patientdata "LSS_analysis_datasets_20201108.dta"
global censusdata "LSS_CSComCensus.dta"
global doctorendline "LSS_DoctorEndlineInterview.dta"

* SETUP PROGRAM THAT INSTALLS ALL STATA PACKAGES
include "$dofiles_admin/LSS_config_stata.do"

*************************************************************************************************
* LOAD TABLES 
*************************************************************************************************
include "$dofiles_admin/LSS_TablePrograms.do"

* ADDITIONAL CONTROLS + CLUSTERING LEVEL
  * date controls
  global date "DD1-DD35"
  global clinic "CL1-CL59"
  global patient "CC*"
  global cluvar "cscomnum"
  global clulevel "clinic" 
  
#delimit ;  
global footnote0 "\emph{Notes}: Robust standard errors clustered at the $clulevel level in parentheses. 
				 All regressions control for clinic visit date fixed effects. We use double selection 
				 lasso to choose additional controls. Eligible controls include clinic dummies, symptom dummies, duration of illness  
				 (topcoded at the 99th percentile) and its square, patient age and its square, a dummy for patients under 5, patient gender, 
				 a dummy to identify pregnant patients, a dummy to identify whether the patient (versus a caregiver) answered the survey, the gender of the survey 
				 respondent, an ethnicity (Bambara) dummy, a dummy for French speaking respondents, a dummy for literate 
				 respondents, a dummy for respondents with a primary education or less, a dummy to identify patients in the home-based 
				 follow up survey, and pairwise interactions between all previously-listed patient and respondent controls. Missing values are recoded to the sample 
				 mean and separately dummied out. These missing dummies are also used to construct pairwise interactions.";
global footnoteb "\emph{Notes}: Robust standard errors clustered at the $clulevel level in parentheses. 
				 All regressions control for clinic visit date fixed effects. We use double selection 
				 lasso to choose additional controls. See notes to Table 3 for a list of potential controls.";				 
global footnote0_nl "\emph{Notes}: Robust standard errors clustered at the $clulevel level in parentheses. All regressions control for clinic visit date fixed effects.";
global footnote0_nl_new "\emph{Notes}: Robust standard errors clustered at the $clulevel level in parentheses. 
				 All regressions control for clinic visit date fixed effects. Controls include number of symptoms, symptom dummies, 
				 duration of illness (topcoded at the 99th percentile), patient age, a dummy for patients under 5, patient gender, 
				 dummy to identify pregnant patients, a dummy to identify whether the patient (versus a caregiver) answered the survey, 
				 the gender of the survey respondent, an ethnicity (Bambara) dummy, a dummy for French speaking respondents, a dummy for literate 
				 respondents, a dummy for respondents with a primary education or less. Missing values are recoded to the sample mean.";
			 
#delimit cr
global footnote0_alt "\emph{Notes}: Robust standard errors clustered at the $clulevel level in parentheses. All regressions include clinic visit date fixed effects."

global footnote1 "*, **, and *** denote statistical significance at the 10, 5, and 1 percent levels respectively."


*************************************************************************************************
/**** NOTE: the creation of the bootstrap files can take several hours. Uncomment line 87 below to start the bootstrap sampling. */
include "$dofiles_admin/LSS_make_bootstrap_repsets.do"

*************************************************************************************************
* FIGURES
*************************************************************************************************

* FIGURE 3: TREATMENT OUTCOMES BY MALARIA RISK, CONTROL GROUP
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1
	
	do "$dofiles_fig/3_graph_outcomeXpredpos_control.do"
	
* FIGURE 4: TREATMENT OUTCOMES BY MALARIA RISK AND VOUCHER GROUP
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1
	
	do "$dofiles_fig/4_graph_tmtXpredpos.do"

* FIGURE 5: VOUCHERS AND MALARIA TREATMENT
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1
	
	do "$dofiles_fig/5_graph_voucher_tmt.do"
	

***************************************************************************************
* APPENDIX B FIGURES
***************************************************************************************	

* FIGURE B1: MISALLOCATION
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1
	
	do "$dofiles_fig/B1_graph_misallocation.do"

* FIGURE B2: DISTRIBUTION PREDICTED MALARIA
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1

	do "$dofiles_fig/B2_graph_dist_pred_pos.do"
	
* Figure B3: TREATMENT OUTCOMES BY MALARIA RISK, CONTROL GROUP by HOME TEST STATUS
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1
	
	do "$dofiles_fig/B3_graph_outcomeXpredpos_control_home.do"
	
* FIGURE B4: OVERALL IMPACTS ON TREATMENT OUTCOMES -- By bins
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1

    do "$dofiles_fig/B4_graph_vouchersXbins.do"
	

	
**********************************************************************************
* MAIN TABLES
**********************************************************************************


* TABLE 1: CONTROL GROUP TABLE
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1
	
	include "$dofiles_tab/1_table_control_group.do"	

* TABLE 2: BALANCE TABLE
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear

la var under5 "Under 5 Years Old"

* VARS IN TABLE 
	* 0. sample frame
	global varlist0 "nobs"
	* 1. patient chars
	global varlist1 "num_symptoms symptomsscreening_1 symptomsscreening_2 symptomsscreening_3 symptomsscreening_4 symptomsscreening_5 symptomsscreening_6 symptomsscreening_7 daysillness99 agepatient under5 genderpatient pregnancy RDTresult_POS pred_mal_pos"
	* 2. respondent / HH chars
	global varlist2 "respondent gender ethnic_bambara speak_french readwrite_fluent_french prischoolorless total_hh_members_H HH_frac_14 HH_frac_job income_percap_H rent_value_H HH_frac_nets"

	include "$dofiles_tab/2_table_balance.do"

	
* TABLE 3: OVERALL IMPACTS ON TREATMENT OUTCOMES
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1
g RXnone= 1 - RXtreat_sev_simple_mal
g none=   1 - treat_sev_simple_mal
	la var RXnone "Prescribed"
	la var none "Purchased"	
	la var RXtreat_sev_simple_mal "Prescribed"
	la var treat_sev_simple_mal "Purchased"	
	la var used_vouchers_admin "Used Voucher"
	la var RXtreat_severe_mal "Prescribed"
	la var treat_severe_mal "Purchased"		

docpat_theory_lso used_vouchers_admin RXtreat_sev_simple_mal treat_sev_simple_mal RXtreat_severe_mal treat_severe_mal, type(tex) ///
		table("$tables/3_mal_tmt_overall_new_lso.tex") footnote($footnote0 GC, PD, and DD indicate tests of gatekeeping costs, patient-driven, and doctor-driven demand respectively. $footnote1) testof("GC PD PD DD DD") signifevidence("Yes Yes Yes No No") /// 
		prehead1($prehead1) title("Impacts on Malaria Treatment Outcomes") lab(mal_tmt_overall_new) ///
	    prehead2($prehead2) widc(0.12\linewidth) texwid(.95) cluvar($cluvar) partial($date) lcont($date $clinic $patient) ///
		extrahead(\\ & & \multicolumn{2}{c}{Any Malaria Treatment} & \multicolumn{2}{c}{Severe Malaria Treatment}  \\ \cmidrule(lr){3-4} \cmidrule(lr){5-6}) 

* TABLE 4: HET IMPACTS ON TREATMENT OUTCOMES
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear

cap prog drop dome
prog define dome
	drop if dropme==1
	la var used_vouchers_admin "Used Voucher"
	la var RXtreat_severe_mal "Prescribed"
	la var treat_severe_mal "Purchased"		
la var RXtreat_sev_simple_mal "Prescribed"
la var treat_sev_simple_mal "Purchased"	
end

dome

docpat_hettable_theory_lso used_vouchers_admin RXtreat_sev_simple_mal treat_sev_simple_mal RXtreat_severe_mal treat_severe_mal, type(tex) ///
		table("$tables/4_mal_tmt_het_new_lso.tex") footnote($footnoteb Standard errors are based on 1,000 bootstrap replications, with re-sampling at the clinic level. Predicted malaria risk is re-calculated on each bootstrap replication. GC, PD, and DD indicate tests of gatekeeping costs, patient-driven, and doctor-driven demand respectively. $footnote1) /// 
		prehead1($prehead1) title("Impacts on Malaria Treatment Outcomes - Heterogeneity by Predicted Malaria Risk") lab(mal_tmt_het_new) partial($date) ///
	    prehead2($prehead2) widc(0.12\linewidth) texwid(1) cluvar($cluvar) testofh("GC/DD -- -- DD DD") signifevidenceh("No -- -- No No") testofl("GC/PD PD PD -- --") signifevidencel("Yes Yes Yes -- --") ///
		extrahead(\\ & & \multicolumn{2}{c}{Any Malaria Treatment} & \multicolumn{2}{c}{Severe Malaria Treatment}  \\ \cmidrule(lr){3-4} \cmidrule(lr){5-6})  ///
		path("$data_final/_bootstrap") setname("bs_cluCSCOM_") dodo(dome) numreps(1000) lcont($date $clinic $patient)

		
* TABLE 5: IMPACTS ON MATCH - TREATMENT AND ILLNESS
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1
	
	la var RXexpected_mal_match_any "Overall Match"
	la var expected_mal_match_any "Overall Match"	
g RXexpected_mal_match_anyX= RXexpected_mal_match_any if RXmatch_treat_RDT!=.
g expected_mal_match_anyX= expected_mal_match_any if RXmatch_treat_RDT!=.
	la var expected_mal_match_any_pos "Malaria Positive"
	la var RXexpected_mal_match_any_pos "Malaria Positive"
	la var expected_mal_match_any_neg "Malaria Negative"
	la var RXexpected_mal_match_any_neg "Malaria Negative"
	la var RXexpected_mal_match_anyX "Prescribed"
	la var expected_mal_match_anyX "Purchased"
	la var RXmatch_treat_RDT "Prescribed"
	la var match_treat_RDT "Purchased"		
	
* this table decomposes expected match into E(antimal to malaria+) and E(no antimal to malaria-)
docpat_p1_lso RXexpected_mal_match_any_pos RXexpected_mal_match_any_neg RXexpected_mal_match_any expected_mal_match_any_pos expected_mal_match_any_neg expected_mal_match_any, type(tex) ///
		table("$tables/5_expected_match_decomp_lso.tex") footnote($footnoteb The expected match for malaria positive is equal to predicted malaria risk times the relevant malaria treatment/purchase dummy. The expected match for malaria negative is equal to one minus predicted malaria risk times one minus the malaria prescription/purchase dummy. The overall expected match is the sum of these two variables. $footnote1) /// 
		prehead1($prehead1) title("Impacts on Match Between Treatment and Illness") lab(expected_match_decomp) ///
	    prehead2($prehead2) widc(0.1\linewidth) texwid(1.25) cluvar($cluvar) partial($date) lcont($date $clinic $patient) ///
		extrahead(\\ & \multicolumn{3}{c}{Expected Match: Prescribed} & \multicolumn{3}{c}{Expected Match: Purchased}  \\ \cmidrule(lr){2-4} \cmidrule(lr){5-7}) 

	
**********************************************************************************
* APPENDIX TABLES
**********************************************************************************

* TABLE B1: Clinics' characteristics
* --------------------------------------------------------------------------------
use "$data_final/$censusdata", clear

	do "$dofiles_tab/B1_table_clinic_census.do"		
			
* TABLE B2: HEALTH WORKERS BELIEFS
* --------------------------------------------------------------------------------
use "$data_final/$doctorendline", clear
		
	do "$dofiles_tab/B2_table_means_doctor.do"

* TABLE B3: IMPACT OF PATIENT INFORMATION TREATMENT ON MALARIA TREATMENT
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1
	la var RXtreat_sev_simple_mal "Prescribed"
	la var treat_sev_simple_mal "Purchased"	
	la var RXtreat_severe_mal "Prescribed"
	la var treat_severe_mal "Purchased"	

gen doctor_voucher_x_patient_info=doctor_voucher*patient_info
gen patient_voucher_x_patient_info=patient_voucher*patient_info
	
docpat_pat_lso RXtreat_sev_simple_mal treat_sev_simple_mal RXtreat_severe_mal treat_severe_mal, type(tex) ///
		table("$tables/B3_mal_tmt_pat_info_lso.tex") footnote($footnoteb  $footnote1) /// 
		prehead1($prehead1) title("Impacts of Patient Information on Malaria Treatment Outcomes") lab(mal_tmt_pat_info_lso) ///
	    prehead2($prehead2) widc(0.12\linewidth) texwid(0.8) cluvar($cluvar) ///
		extrahead(\\ & \multicolumn{2}{c}{Any Malaria Treatment} & \multicolumn{2}{c}{Severe Malaria Treatment}  \\ \cmidrule(lr){2-3} \cmidrule(lr){4-5}) ///
		partial($date)  lcont($date $clinic $patient)	

* TABLE B4: IMPACT OF DOCTOR INFORMATION TREATMENT ON MALARIA TREATMENT
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1
	la var RXtreat_sev_simple_mal "Prescribed"
	la var treat_sev_simple_mal "Purchased"	
	la var RXtreat_severe_mal "Prescribed"
	la var treat_severe_mal "Purchased"	
	
docpat_doc_lso RXtreat_sev_simple_mal treat_sev_simple_mal RXtreat_severe_mal treat_severe_mal, type(tex) ///
		table("$tables/B4_mal_tmt_doc_info_lso.tex") footnote($footnoteb  $footnote1) /// 
		prehead1($prehead1) title("Impacts of Doctor Information on Malaria Treatment Outcomes") lab(mal_tmt_doc_info_lso) ///
	    prehead2($prehead2) widc(0.1\linewidth) texwid(.8) cluvar($cluvar) ///
		extrahead(\\ & \multicolumn{2}{c}{Any Malaria Treatment} & \multicolumn{2}{c}{Severe Malaria Treatment}  \\ \cmidrule(lr){2-3} \cmidrule(lr){4-5}) ///
		partial($date)  lcont($date $clinic $patient)	
		
* TABLE B5: SELECTION INTO SAMPLE TABLE
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	la var has_valid_rdt_H "Has Valid RDT (Home Survey)"
* VARS IN TABLE 
	* 0. sample frame
	global varlist0 "nobs in_home_survey has_valid_rdt_H"
	* 1. patient chars
	global varlist1 "num_symptoms symptomsscreening_1 symptomsscreening_2 symptomsscreening_3 symptomsscreening_4 symptomsscreening_5 symptomsscreening_6 symptomsscreening_7  daysillness99 agepatient under5 genderpatient pregnancy RDTresult_POS pred_mal_pos"
	* 2. respondent / HH chars
	global varlist2 "respondent gender ethnic_bambara speak_french readwrite_fluent_french prischoolorless total_hh_members_H HH_frac_14 HH_frac_job income_percap_H rent_value_H HH_frac_nets"

	include "$dofiles_tab/B5_table_selection.do"

* TABLE B6: DIFFERENCE BETWEEN CONSENTERS AND NON-CONSENTERS FOR RDT
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear	
	drop if dropme==1
	
	do "$dofiles_tab/B6_table_diff_test_consent.do"

* TABLE B7: PREDICTED MALARIA POSITIVITY
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1

	do "$dofiles_tab/B7_table_mal_prob_probit.do"
	
* TABLE B8: OVERALL IMPACTS ON TREATMENT OUTCOMES -- no controls
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1
	
	la var RXtreat_sev_simple_mal "Prescribed"
	la var treat_sev_simple_mal "Purchased"	
	la var used_vouchers_admin "Used Voucher"
	la var RXtreat_severe_mal "Prescribed"
	la var treat_severe_mal "Purchased"		

docpat_p1_theory used_vouchers_admin RXtreat_sev_simple_mal treat_sev_simple_mal RXtreat_severe_mal treat_severe_mal, extra($date) type(tex) ///
		table("$tables/B8_mal_tmt_overall_nc.tex") footnote($footnote0_nl GC, PD, and DD indicate tests of gatekeeping costs, patient-driven, and doctor-driven demand respectively. $footnote1)  testof("GC PD PD DD DD") signifevidence("Yes Yes Yes No No") /// 
		prehead1($prehead1) title("Impacts on Malaria Treatment Outcomes, No Additional Controls") lab(mal_tmt_overall_new_nc) ///
	    prehead2($prehead2) widc(0.12\linewidth) texwid(.8) cluvar($cluvar) ///
		extrahead(\\ & & \multicolumn{2}{c}{Any Malaria Treatment} & \multicolumn{2}{c}{Severe Malaria Treatment}  \\ \cmidrule(lr){3-4} \cmidrule(lr){5-6}) 

* TABLE B9: HET IMPACTS ON TREATMENT OUTCOMES -- no controls
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear

cap prog drop dome
prog define dome
	drop if dropme==1
	la var used_vouchers_admin "Used Voucher"
	la var RXtreat_severe_mal "Prescribed"
	la var treat_severe_mal "Purchased"		
	la var RXtreat_sev_simple_mal "Prescribed"
	la var treat_sev_simple_mal "Purchased"	
end

dome

docpat_hettable_theory used_vouchers_admin RXtreat_sev_simple_mal treat_sev_simple_mal RXtreat_severe_mal treat_severe_mal, extrac($date) type(tex) ///
		table("$tables/B9_mal_tmt_het_nc.tex") footnote($footnote0_nl Standard errors based GC, PD, and DD indicate tests of gatekeeping costs, patient-driven, and doctor-driven demand respectively. $footnote1) /// 
		prehead1($prehead1) title("Impacts on Malaria Treatment Outcomes - Heterogeneity by Predicted Malaria Risk, No Additional Controls") lab(mal_tmt_het_new_nc) ///
	    prehead2($prehead2) widc(0.12\linewidth) texwid(.8) cluvar($cluvar) testofh("GC/DD -- -- DD DD") signifevidenceh("No -- -- No No") testofl("GC/PD PD PD -- --") signifevidencel("Yes Yes Yes -- --")  ///
		extrahead(\\ & & \multicolumn{2}{c}{Any Malaria Treatment} & \multicolumn{2}{c}{Severe Malaria Treatment}  \\ \cmidrule(lr){3-4} \cmidrule(lr){5-6}) /// 
		path("$data_final/_bootstrap") setname("bs_cluCSCOM_") dodo(dome) numreps(1000)
		


		
* TABLE B10: OVERALL IMPACTS ON TREATMENT OUTCOMES -- NO LASSO
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1      

	sum pregnancy 
	replace pregnancy=r(mean) if pregnancy==.
	sum ethnic_bambara
	replace ethnic_bambara=r(mean) if ethnic_bambara==.
global mycont0 "date_1-date_35"
global covariates "num_symptoms symptomsscreening_1 symptomsscreening_2 symptomsscreening_3 symptomsscreening_4 symptomsscreening_5 symptomsscreening_6 daysillness99 agepatient under5 genderpatient pregnancy MSSpregnancy respondent gender ethnic_bambara MSSethnic_bambara speak_french readwrite_fluent_french prischoolorless"	
global mycont "$mycont0 $covariates" 

	la var RXtreat_sev_simple_mal "Prescribed"
	la var treat_sev_simple_mal "Purchased"	
	la var used_vouchers_admin "Used Voucher"
	la var RXtreat_severe_mal "Prescribed"
	la var treat_severe_mal "Purchased"		

docpat_p1_theory used_vouchers_admin RXtreat_sev_simple_mal treat_sev_simple_mal RXtreat_severe_mal treat_severe_mal, extra($mycont) type(tex) ///
		table("$tables/B10_mal_tmt_overall_nl.tex") footnote($footnote0_nl_new GC, PD, and DD indicate tests of gatekeeping costs, patient-driven, and doctor-driven demand respectively. $footnote1)  testof("GC PD PD DD DD") signifevidence("Yes Yes Yes No No") /// 
		prehead1($prehead1) title("Impacts on Malaria Treatment Outcomes") lab(mal_tmt_overall_nl) ///
	    prehead2($prehead2) widc(0.12\linewidth) texwid(.8) cluvar($cluvar) ///
		extrahead(\\ & & \multicolumn{2}{c}{Any Malaria Treatment} & \multicolumn{2}{c}{Severe Malaria Treatment}  \\ \cmidrule(lr){3-4} \cmidrule(lr){5-6}) 

* TABLE B11: HET IMPACTS ON TREATMENT OUTCOMES -- NO LASSO
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear

cap prog drop dome
prog define dome
	drop if dropme==1
	la var used_vouchers_admin "Used Voucher"
	la var RXtreat_severe_mal "Prescribed"
	la var treat_severe_mal "Purchased"		
	la var RXtreat_sev_simple_mal "Prescribed" 
	la var treat_sev_simple_mal "Purchased"	

	sum pregnancy 
	replace pregnancy=r(mean) if pregnancy==.
	sum ethnic_bambara
	replace ethnic_bambara=r(mean) if ethnic_bambara==.         
end

dome

global covariates "num_symptoms symptomsscreening_1 symptomsscreening_2 symptomsscreening_3 symptomsscreening_4 symptomsscreening_5 symptomsscreening_6 daysillness99 agepatient under5 genderpatient pregnancy MSSpregnancy respondent gender ethnic_bambara MSSethnic_bambara speak_french readwrite_fluent_french prischoolorless"	
global mycont "$mycont0 $covariates" 

docpat_hettable_theory used_vouchers_admin RXtreat_sev_simple_mal treat_sev_simple_mal RXtreat_severe_mal treat_severe_mal, extrac($mycont) type(tex) ///
		table("$tables/B11_mal_tmt_het_nl.tex") footnote($footnote0_nl_new GC, PD, and DD indicate tests of gatekeeping costs, patient-driven, and doctor-driven demand respectively. $footnote1) /// 
		prehead1($prehead1) title("Impacts on Malaria Treatment Outcomes - Heterogeneity by Predicted Malaria Risk") lab(mal_tmt_het_nl) ///
	    prehead2($prehead2) widc(0.12\linewidth) texwid(.8) cluvar($cluvar) testofh("GC/DD -- -- DD DD") signifevidenceh("No -- -- No No") testofl("GC/PD PD PD -- --") signifevidencel("Yes Yes Yes -- --") ///
		extrahead(\\ & & \multicolumn{2}{c}{Any Malaria Treatment} & \multicolumn{2}{c}{Severe Malaria Treatment}  \\ \cmidrule(lr){3-4} \cmidrule(lr){5-6}) ///
		dodo(dome) path("$data_final/_bootstrap") setname("bs_cluCSCOM_") numreps(1000)
		
* TABLE B12: VOUCHERS AND MALARIA TREATMENT
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1
	
docpat_theory_lso treat_severe_mal_voucher treat_severe_mal_NOvoucher treat_simple_mal_voucher treat_simple_mal_NOvoucher , type(tex) ///
		table("$tables/B12_vouchers_tmt_lso.tex") footnote($footnoteb DD and PD indicates a test of doctor and patient-driven demand respectively. $footnote1) testof("DD DD PD PD") signifevidence("No No No Yes") /// 
		prehead1($prehead1) title("Use of Voucher for Purchased Malaria Treatment") lab(vouchers_tmt) ///
	    prehead2($prehead2) widc(0.1\linewidth) texwid(.8) cluvar($cluvar) partial($date) lcont($date $clinic $patient)

* TABLE B13: Stockpiling: Taking medication at home survey - lasso
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1

gen taking_ACT_simple= taking_ACT_t if treat_simple_mal==1

label var taking_ACT_t "All Prescribed ACTs"
label var taking_ACT_simple "Prescribed ACT for Simple Malaria"

docpat_p1_lso taking_ACT_t taking_ACT_simple, type(tex) ///
		table("$tables/B13_stockpiling_lso.tex") footnote($footnoteb The first column is limited to individuals who purchased an ACT treatment at the CSCom as part of either simple or severe malaria treatment. The second column is limited to individuals who purchased an ACT as part of simple malaria treatment. $footnote1) /// 
		prehead1($prehead1) title("Share of Patients Taking An ACT at Home Survey") lab(stockpiling) ///
	    prehead2($prehead2) widc(0.12\linewidth) texwid(1) cluvar($cluvar) partial($date) lcont($date $clinic $patient)
		
* TABLE B14: IMPACT OF INFORMATION TREATMENT ON TESTING
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1
gen no_voucher=.
	replace no_voucher=1 if doctor_voucher==0 & patient_voucher==0
	replace no_voucher=0 if doctor_voucher==1 | patient_voucher==1
gen pat_infoXno_voucher=patient_info*no_voucher
gen pat_infoXdoc_voucher=patient_info*doctor_voucher
gen pat_infoXpat_voucher=patient_info*patient_voucher
gen doctor_voucher_x_patient_info= doctor_voucher*patient_info
gen patient_voucher_x_patient_info = patient_voucher*patient_info
gen reported_Malaria_test_RX=reported_Malaria_test if RXtreat_sev_simple_mal==1
gen reported_RDT_RX=reported_RDT if RXtreat_sev_simple_mal==1
gen reported_GE_FS_RX=reported_GE_FS if RXtreat_sev_simple_mal==1
	la var reported_Malaria_test_RX "Any Malaria Test"
	la var reported_RDT_RX "RDT Test"
	la var reported_GE_FS_RX "Microscopy Test"
	la var RXtreat_sev_simple_mal "Prescribed Antimalarial"
	la var treat_sev_simple_mal "Purchased Antimalarial"
	la var reported_Malaria_test "Any Malaria Test"
	la var reported_GE_FS "Microscopy Test"
	la var reported_RDT "RDT Test"

docpat_pat_aux_lso reported_Malaria_test reported_RDT reported_GE_FS reported_Malaria_test_RX reported_RDT_RX reported_GE_FS_RX, type(tex) ///
		table("$tables/B14_mal_testing_info_RX_lso.tex") footnote($footnoteb  $footnote1) /// 
		prehead1($prehead1) title("Impacts of Patient Information on Malaria Testing at the Clinic") lab(mal_testing_info_RX_lso) ///
	    prehead2($prehead2) widc(0.1\linewidth) texwid(1.3) cluvar($cluvar) ///
		extrahead(\\ & \multicolumn{3}{c}{All Patients} & \multicolumn{3}{c}{If Prescribed Antimalarial}  \\ \cmidrule(lr){2-4} \cmidrule(lr){5-7}) ///
		partial($date)  lcont($date $clinic $patient)
	
		
* TABLE B15: IMPACTS ON COSTS TO PATIENTS AND CLINIC REVENUE -- PATIENT LEVEL
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear

cap prog drop dome
prog define dome
	drop if dropme==1 
g reported_cost_mal= reported_totalcost if RXtreat_sev_simple_mal
g reported_cost_sev= reported_totalcost if RXtreat_severe_mal
	la var reported_totalcost "Patient Costs"
	la var reported_cost_mal "Malaria Patients"
	la var reported_cost_sev "Severe Malaria Patients"	
	la var reported_totalcost_pre "Clinic Revenues"
end

dome 

docpat_pantable_lso reported_totalcost_pre reported_totalcost, type(tex) ///
		table("$tables/B15_cost_overall_lso.tex") footnote($footnoteb In Panel B, standard errors are based on 1,000 bootstrap replications, with re-sampling at the clinic level. Predicted malaria risk is re-calculated on each bootstrap replication. All variables measured in CFA top-coded at the 99th percentile. CFA610 $\approx$ USD1. Malaria cases classified based on doctor prescriptions. $footnote1) /// 
		prehead1($prehead1) title("Impacts on Clinic Revenues and Patient Costs (CFA)") lab(cost_overall) ///
	    prehead2($prehead2) widc(0.12\linewidth) texwid(.8) cluvar($cluvar) /// 
		path("$data_final/_bootstrap") setname("bs_cluCSCOM_") dodo(dome) numreps(1000) partial($date) lcont($date $clinic $patient)
		
		
* TABLE B16: IMPACTS ON MATCH :: TREATMENT AND ILLNESS - RDT SUB-SAMPLE
* --------------------------------------------------------------------------------
use "$data_final/$patientdata", clear
	drop if dropme==1
	
	la var RXexpected_mal_match_any "Overall Match"
	la var expected_mal_match_any "Overall Match"	
g RXexpected_mal_match_anyX= RXexpected_mal_match_any if RXmatch_treat_RDT!=.
g expected_mal_match_anyX= expected_mal_match_any if RXmatch_treat_RDT!=.
	la var expected_mal_match_any_pos "Malaria Positive"
	la var RXexpected_mal_match_any_pos "Malaria Positive"
	la var expected_mal_match_any_neg "Malaria Negative"
	la var RXexpected_mal_match_any_neg "Malaria Negative"
	la var RXexpected_mal_match_anyX "Prescribed"
	la var expected_mal_match_anyX "Purchased"
	la var RXmatch_treat_RDT "Prescribed"
	la var match_treat_RDT "Purchased"		
	
docpat_p1_lso RXexpected_mal_match_anyX expected_mal_match_anyX RXmatch_treat_RDT match_treat_RDT, type(tex) ///
		table("$tables/B16_expected_match_lso.tex") footnote($footnoteb In columns 3 and 4 match quality is equal to 1 if an individual is malaria positive and was prescribed/bought an antimalarial or is malaria negative and was not prescribed/did not buy an antimalarial and is zero otherwise. In columns 1-2 the value of one is replaced with either the probability an individual is positive (for antimalarial receipt) or the probability an individual is negative (for non-receipt). $footnote1) /// 
		prehead1($prehead1) title("Impacts on Match Between Treatment and Illness - RDT Sub-Sample") lab(expected_match_lso) ///
	    prehead2($prehead2) widc(0.1\linewidth) texwid(1.25) cluvar($cluvar) partial($date) lcont($date $clinic $patient) ///
		extrahead(\\ &  \multicolumn{2}{c}{Expected Match} & \multicolumn{2}{c}{Actual Match} \\ \cmidrule(lr){2-3} \cmidrule(lr){4-5}) 	
		
			

```

### `Lopez_Sautmann_Schaner_2020/Do_Files/Stata admin files/LSS_TablePrograms.do`
```stata

* *******************************************************
* PROGRAM: DocPat_TablePrograms
* PROGRAMNER: Simone Schaner
* PURPOSE: Programs to make tables for LSS analysis
* DATE CREATED: 5/1/2019
* *******************************************************


**************************************************************************************************************
* e-class program to product bootstrapped SEs using replicant datasets and pre-specified controls
* note: we assume the "dofirst" bit has already been executed for the main spec, and just
*       needs to be done on loops over the replication set
**************************************************************************************************************
cap prog drop boot_ols
prog define boot_ols, eclass

syntax anything [if] [in] , REPName(string) REPPath(string) NUMreps(integer) [DOFirst(string)] [MAindata(string)]
	marksample touse
	preserve
set more off
* FIRST RUN THE MAIN REGRESSION
qui `anything' `if' 
	tempfile starthere
	save `starthere'
	mat beta= e(b) /* get initial parameter vector */
	local cols= colsof(beta) 
	local obs=e(N)
	local dvar=e(depvar)
	local rname: rowfullnames e(V)
	local cname: colfullnames e(V)
		mat reps=J(`numreps',`cols',.)
* NEXT DO A WHOLE BUNCH OF REPLICATIONS
local i=1
	while `i'<=`numreps' {
qui {
	drop _all
		use "`reppath'/`repname'`i'"
		`dofirst'
		`anything' `if' [`wt']
		mat reps[`i',1]=e(b) 
}
		di `i'
		local ++i
		} /* closes loop where we do command over and over */
* NEXT CALCULATE STANDARD ERRORS
drop _all
	svmat reps
	mat accum var= * [iw=1/`numreps'], dev nocons 
	mat colnames var= `cname'
	mat rownames var= `rname'
		* DISPLAY RESULTS
		*di _n in gr  "Bootstrapped Results"
drop _all
use `starthere'
qui `anything' `if' 
      * ereturn post beta var, esample(`touse') obs(`obs') depname(`dvar') 
	  ereturn repost b=beta V=var
	   ereturn display
restore	   
end



**************************************************************************************************************
* main table w/o one-sided tests
**************************************************************************************************************
cap prog drop docpat_theory_lso
prog define docpat_theory_lso
	est clear
syntax varlist [if], TEXWID(string) [Table(string)] [LCONT(varlist)]  [TYPE(string)] [FOOTnote(string)] [PREHEAD1(string)] /// 
	                 [PREHEAD2(string)] [TITLE(string)] [LABel(string)] WIDC(string) [EXTRAC1(string)] [EXTRAC2(string)] /// 
					 [EXTRAHEAD(string)] [EXTRAVARHead(string)] CLUVar(string) TESTOF(string) SIGNIFEVIDENCE(string) [PARTIAL(string)]
	
qui {


local q= 2
	local colcount= wordcount("`varlist'")+1
	local seclast= `q'-1	
	
// locals to assist in making the table
local ester=1
forval i=1/`q' {
	local eststr`i' ""	
	}
	
// label covariates
la var patient_voucher "$\beta_P$: Patient Voucher"
la var doctor_voucher "$\beta_D$: Doctor Voucher"
local counter=1	
	
	local varhead ""
	local paren`counter' ""
	local outcount=1
	foreach out in `varlist'  {
	
	// GET LABELS HERE
	local labelq : variable label `out'
		local varhead "`varhead'& `labelq'" //this is the label for columns		
		
		pdslasso `out'  patient_voucher doctor_voucher (`lcont') `if', clu(`cluvar') partial(`partial')

			test patient_voucher=doctor_voucher
				local n1= r(p)
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDV `combo'		
		
				local sign = sign(_b[patient_voucher]-_b[doctor_voucher])
				local n1= 1-normal(`sign'*sqrt(r(chi2)))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="ge" local p_one "`combo'"
					
				local n1= normal(`sign'*sqrt(r(chi2)))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="le" local p_one "`combo'"
				
				estadd local p_oneside `p_one'
				
			test patient_voucher=doctor_voucher=0
				local n1= r(p)
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDV0 `combo'

				qui sum `out' if e(sample) & doctor_voucher+patient_voucher==0

				local DV: display %7.3f `r(mean)'
	            estadd local DV `DV'
				
				tokenize `testof'
					estadd local test_of "``outcount''"

				tokenize `signifevidence'
					estadd local signif_evidence "``outcount''"
					
			est store E`ester'
				local eststr`counter' "`eststr`counter'' E`ester'"
				local paren`counter' "`paren`counter'' & (`ester')" // column numbers
				local ++ester	
		local ++outcount
		}
		local ++counter	
		} //end qui loop
* FIRST PANEL		
esttab `eststr1' using "`table'", keep(patient_voucher doctor_voucher) label  noabbrev `type' replace nogaps nomtit nonum ///
		stats(space p_PVDV test_of signif_evidence space DV N, fmt(0 0 0 0 0 a3 a0) labels("\emph{P-values and theory-driven tests}" "\enspace $\beta_P=\beta_D$" "\enspace Test for mechanism:" "\enspace Significant evidence of mechanism:" " " "Mean (Control)" "N")) ///
		nonote  star(* 0.10 ** 0.05 *** 0.01) `extrac1' ///
		b(a2) se(a2) noline subs("\beta\_" "\beta_") /// 
		prehead("\begin{table}[ht!] \begin{adjustbox}{max width=`texwid'\textwidth} \begin{threeparttable} \caption{`title'} \label{`label'} {\begin{tabular}{l*{`colcount'}{C{`widc'}}} \toprule \toprule `paren1' `extrahead' \\ `varhead' `extravarhead' \\ \toprule ")  /// 
		postfoot(\hline \end{tabular} } \begin{tablenotes}[flushleft] \small \item `footnote' \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}) 
end		

**************************************************************************************************************
* theory driven tests in table w/ het tmt by above/below median malaria risk
*	this table uses bootstrapped standard errors coupled w/ variable selection via pdslasso
**************************************************************************************************************
cap prog drop docpat_hettable_theory_lso
prog define docpat_hettable_theory_lso
	est clear
syntax varlist [if], TEXWID(string) [Table(string)]  [TYPE(string)] [FOOTnote(string)] [PREHEAD1(string)] PATH(string) SETNAME(string)  /// 
	                 [PREHEAD2(string)] [TITLE(string)] [LABel(string)] WIDC(string) [EXTRAC1(string)] [EXTRAC2(string)] [PARTIAL(string)] /// 
					 [EXTRAHEAD(string)] [EXTRAVARHead(string)] CLUVar(string) TESTOFH(string) SIGNIFEVIDENCEH(string)  TESTOFL(string) SIGNIFEVIDENCEL(string) /// 
					 NUMreps(integer) DODO(string) LCONT(string)
					 	 
qui {

preserve

local q= 2
	local colcount= wordcount("`varlist'")+1
	local seclast= `q'-1	
	
// locals to assist in making the table
local ester=1
forval i=1/`q' {
	local eststr`i' ""	
	}
	
// label covariates
la var patient_voucher_high "$\delta_{PH}$: Patient Voucher $\times$ High Risk"
la var  doctor_voucher_high "$\delta_{DH}$: Doctor Voucher $\times$ High Risk" 
la var patient_voucher_low "$\delta_{PL}$: Patient Voucher $\times$ Low Risk"
la var doctor_voucher_low "$\delta_{DL}$: Doctor Voucher $\times$ Low Risk" 
la var above_med_pos "$\theta$: High Malaria Risk"
local counter=1	
	local varhead ""
	local paren`counter' ""
	local outcount=1
tempfile theuser
	save `theuser'
	foreach out in `varlist'  {
		drop _all
		use `theuser'
		
	// GET LABELS HERE
	local labelq : variable label `out'
		local varhead "`varhead'& `labelq'" //this is the label for columns		
		
		
	// step 1 :: select covariates using PDS lasso
		pdslasso `out'  patient_voucher_high doctor_voucher_high patient_voucher_low doctor_voucher_low above_med_pos (`lcont') `if', clu(`cluvar') partial(`partial')
			local totcont= "`e(xselected)' `e(xpartial)'"

		
	// step 2 :: bootstrap this thing
	boot_ols reg `out' patient_voucher_high doctor_voucher_high patient_voucher_low doctor_voucher_low above_med_pos `totcont' `if', reppath(`path') repname(`setname') num(`numreps') dofirst(`dodo')
			* NB: since this is bootstrapping after double post lasso, recalculate p-values to be based on asymptotic inference
			*     this ensures that we use asymptotics for both one and two-sided tests 
			test patient_voucher_high = doctor_voucher_high 
				local n1= 2*(1-normal(sqrt(r(F))))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDVhigh `combo'
			
				local sign = sign(_b[patient_voucher_high]-_b[doctor_voucher_high])
				local n1= 1-normal(`sign'*sqrt(r(F)))

				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="ge" local p_one_high "`combo'"

				local n1= normal(`sign'*sqrt(r(F)))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="le" local p_one_high "`combo'"
			
			test patient_voucher_low = doctor_voucher_low 
				local n1= 2*(1-normal(sqrt(r(F))))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDVlow `combo'
				
				local sign = sign(_b[patient_voucher_low]-_b[doctor_voucher_low])
				local n1= 1-normal(`sign'*sqrt(r(F)))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="ge" local p_one_low "`combo'"

				local n1= normal(`sign'*sqrt(r(F)))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="le" local p_one_low "`combo'"

				
				qui sum `out' if e(sample) & doctor_voucher + patient_voucher ==0 & above_med_pos==0
				
				local DV: display %7.3f `r(mean)'
	            estadd local DV `DV'

				tokenize `testofh'
					estadd local test_of_h "``outcount''"

				tokenize `signifevidenceh'
					estadd local signif_evidence_h "``outcount''"

				tokenize `testofl'
					estadd local test_of_l "``outcount''"

				tokenize `signifevidencel'
					estadd local signif_evidence_l "``outcount''"
					
			est store E`ester'
				local eststr`counter' "`eststr`counter'' E`ester'"
				local paren`counter' "`paren`counter'' & (`ester')" // column numbers
				local ++ester	
		local ++outcount
		}
		local ++counter	
		} //end qui loop
* FIRST PANEL		
esttab `eststr1' using "`table'", keep(patient_voucher_high doctor_voucher_high patient_voucher_low doctor_voucher_low above_med_pos) label  noabbrev `type' replace nogaps nomtit nonum ///
		stats(space p_PVDVhigh test_of_h signif_evidence_h space p_PVDVlow test_of_l signif_evidence_l space DV N, fmt(0 0 0 0 0 0 0 0 0 a2 a0) labels("\emph{P-values and theory-driven tests}" "\enspace $\delta_{PH}=\delta_{DH}$" "\enspace Test for mechanism:" "\enspace Significant evidence of mechanism:" " " "\enspace $\delta_{PL}=\delta_{DL}$" "\enspace Test for mechanism:" "\enspace Significant evidence of mechanism:" " " "Mean (Control, Low Risk)" "N")) ///
		nonote  star(* 0.10 ** 0.05 *** 0.01) `extrac1' ///
		b(a2) se(a2) noline subs("\beta\_" "\beta_") /// 
		prehead("\begin{table}[ht!] \begin{adjustbox}{max width=`texwid'\textwidth} \begin{threeparttable} \caption{`title'} \label{`label'} {\begin{tabular}{l*{`colcount'}{C{`widc'}}} \toprule \toprule `paren1' `extrahead' \\ `varhead' `extravarhead' \\ \toprule ")  /// 
		postfoot(\hline \end{tabular} } \begin{tablenotes}[flushleft] \small \item `footnote' \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table})
restore
end		




**************************************************************************************************************
* theory driven tests in table w/ het tmt by above/below median malaria risk
*	this table uses bootstrapped standard errors coupled w/ variable selection via pdslasso
**************************************************************************************************************
cap prog drop docpat_het_theory_lso_simple
prog define docpat_het_theory_lso_simple
	est clear
syntax varlist [if], TEXWID(string) [Table(string)]  [TYPE(string)] [FOOTnote(string)] [PREHEAD1(string)] PATH(string) SETNAME(string)  /// 
	                 [PREHEAD2(string)] [TITLE(string)] [LABel(string)] WIDC(string) [EXTRAC1(string)] [EXTRAC2(string)] [PARTIAL(string)] /// 
					 [EXTRAHEAD(string)] [EXTRAVARHead(string)] CLUVar(string) /// 
					 NUMreps(integer) DODO(string) LCONT(string)
					 	 
qui {

preserve

local q= 2
	local colcount= wordcount("`varlist'")+1
	local seclast= `q'-1	
	
// locals to assist in making the table
local ester=1
forval i=1/`q' {
	local eststr`i' ""	
	}
	
// label covariates
la var patient_voucher_high "$\delta_{PH}$: Patient Voucher $\times$ High Risk"
la var  doctor_voucher_high "$\delta_{DH}$: Doctor Voucher $\times$ High Risk" 
la var patient_voucher_low "$\delta_{PL}$: Patient Voucher $\times$ Low Risk"
la var doctor_voucher_low "$\delta_{DL}$: Doctor Voucher $\times$ Low Risk" 
la var above_med_pos "$\theta$: High Malaria Risk"
local counter=1	
	local varhead ""
	local paren`counter' ""
	local outcount=1
tempfile theuser
	save `theuser'
	foreach out in `varlist'  {
		drop _all
		use `theuser'
		
	// GET LABELS HERE
	local labelq : variable label `out'
		local varhead "`varhead'& `labelq'" //this is the label for columns		
		
		
	// step 1 :: select covariates using PDS lasso
		pdslasso `out'  patient_voucher_high doctor_voucher_high patient_voucher_low doctor_voucher_low above_med_pos (`lcont') `if', clu(`cluvar') partial(`partial')
			local totcont= "`e(xselected)' `e(xpartial)'"

		
	// step 2 :: bootstrap this thing
	boot_ols reg `out' patient_voucher_high doctor_voucher_high patient_voucher_low doctor_voucher_low above_med_pos `totcont' `if', reppath(`path') repname(`setname') num(`numreps') dofirst(`dodo')
			* NB: since this is bootstrapping after double post lasso, recalculate p-values to be based on asymptotic inference
			*     this ensures that we use asymptotics for both one and two-sided tests 
			test patient_voucher_high = doctor_voucher_high 
				local n1= 2*(1-normal(sqrt(r(F))))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDVhigh `combo'
			
				local sign = sign(_b[patient_voucher_high]-_b[doctor_voucher_high])
				local n1= 1-normal(`sign'*sqrt(r(F)))

				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="ge" local p_one_high "`combo'"

				local n1= normal(`sign'*sqrt(r(F)))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="le" local p_one_high "`combo'"
			
			test patient_voucher_low = doctor_voucher_low 
				local n1= 2*(1-normal(sqrt(r(F))))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDVlow `combo'
				
				local sign = sign(_b[patient_voucher_low]-_b[doctor_voucher_low])
				local n1= 1-normal(`sign'*sqrt(r(F)))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="ge" local p_one_low "`combo'"

				local n1= normal(`sign'*sqrt(r(F)))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="le" local p_one_low "`combo'"

				
				qui sum `out' if e(sample) & doctor_voucher + patient_voucher ==0 & above_med_pos==0
				
				local DV: display %7.3f `r(mean)'
	            estadd local DV `DV'

				tokenize `testofh'
					estadd local test_of_h "``outcount''"

				tokenize `signifevidenceh'
					estadd local signif_evidence_h "``outcount''"

				tokenize `testofl'
					estadd local test_of_l "``outcount''"

				tokenize `signifevidencel'
					estadd local signif_evidence_l "``outcount''"
					
			est store E`ester'
				local eststr`counter' "`eststr`counter'' E`ester'"
				local paren`counter' "`paren`counter'' & (`ester')" // column numbers
				local ++ester	
		local ++outcount
		}
		local ++counter	
		} //end qui loop
* FIRST PANEL		
esttab `eststr1' using "`table'", keep(patient_voucher_high doctor_voucher_high patient_voucher_low doctor_voucher_low above_med_pos) label  noabbrev `type' replace nogaps nomtit nonum ///
		stats(space p_PVDVhigh p_PVDVlow space DV N, fmt(0 0 0 0 a2 a0) labels("\emph{P-values}" "\enspace $\delta_{PH}=\delta_{DH}$" "\enspace $\delta_{PL}=\delta_{DL}$" " " "Mean (Control, Low Risk)" "N")) ///
		nonote  star(* 0.10 ** 0.05 *** 0.01) `extrac1' ///
		b(a2) se(a2) noline subs("\beta\_" "\beta_") /// 
		prehead("\begin{table}[ht!] \begin{adjustbox}{max width=`texwid'\textwidth} \begin{threeparttable} \caption{`title'} \label{`label'} {\begin{tabular}{l*{`colcount'}{C{`widc'}}} \toprule \toprule `paren1' `extrahead' \\ `varhead' `extravarhead' \\ \toprule ")  /// 
		postfoot(\hline \end{tabular} } \begin{tablenotes}[flushleft] \small \item `footnote' \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table})
restore
end		



**************************************************************************************************************
* table w/ panels that uses lasso throughout and bootstrapping for the het effects
* NOTE: no theory-driven tests for this one
**************************************************************************************************************
cap prog drop docpat_pantable_lso
prog define docpat_pantable_lso
	est clear
syntax varlist [if], TEXWID(string) [Table(string)] [TYPE(string)] [FOOTnote(string)] [PREHEAD1(string)] /// 
	                 [PREHEAD2(string)] [TITLE(string)] [LABel(string)] WIDC(string) [EXTRAC1(string)] [EXTRAC2(string)] /// 
					 [EXTRAHEAD(string)] [EXTRAVARHead(string)] CLUVar(string) [PARTIAL(string)] NUMreps(integer) DODO(string) ///
					 SETname(string) PATH(string) LCONT(string)
	
qui {

local q= 2
	local colcount= wordcount("`varlist'")+1
	local seclast= `q'-1	
	
// locals to assist in making the table
local ester=1
forval i=1/`q' {
	local eststr`i' ""	
	}
	
// label covariates
la var patient_voucher "\enspace $\beta_P$: Patient Voucher"
la var doctor_voucher "\enspace $\beta_D$: Doctor Voucher"
la var patient_voucher_high "\enspace $\delta_{PH}$: Patient Voucher $\times$ High Risk"
la var doctor_voucher_high "\enspace $\delta_{DH}$: Doctor Voucher $\times$ High Risk" 
la var patient_voucher_low "\enspace $\delta_{PL}$: Patient Voucher $\times$ Low Risk"
la var doctor_voucher_low "\enspace $\delta_{DL}$: Doctor Voucher $\times$ Low Risk" 
la var above_med_pos "\enspace $\theta$: High Malaria Risk"

local counter=1	
	
	local varhead ""
	local paren`counter' ""
	tempfile startfile
	save `startfile'
	
	foreach out in `varlist'  {
	
	// GET LABELS HERE
	local headz`counter' "\emph{Panel A. No Interactions}" // this is the label for panels	
	local labelq : variable label `out'
		local varhead "`varhead'& `labelq'" //this is the label for columns		
		
		pdslasso `out'  patient_voucher doctor_voucher (`lcont') `if', clu(`cluvar') partial(`partial')

			test patient_voucher=doctor_voucher
				local n1= r(p)
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDV `combo'
				
			test patient_voucher=doctor_voucher=0
				local n1= r(p)
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDV0 `combo'
				
				qui sum `out' if e(sample) & infotreat==0 & treat_scheduled==1
				estadd scalar DV=r(mean)
						
			est store E`ester'
				local eststr`counter' "`eststr`counter'' E`ester'"
				local paren`counter' "`paren`counter'' & (`ester')" // column numbers
				local ++ester	
		}
		local ++counter

	// NOW DO INTERACTIONS	
	local varhead ""
	local paren`counter' ""
	foreach out in `varlist'  {
	drop _all
	use `startfile'
	
	// get labels here
	local headz`counter' "\emph{Panel B. Interactions with Predicted Malaria Probability}" // this is the label for panels	
	local labelq : variable label `out'
		local varhead "`varhead'& `labelq'" //this is the label for columns	
		
	// step 1 :: select covariates using PDS lasso
		pdslasso `out'  patient_voucher_high doctor_voucher_high patient_voucher_low doctor_voucher_low above_med_pos (`lcont') `if', clu(`cluvar') partial(`partial')
			local totcont= "`e(xselected)' `e(xpartial)'"
	
	// step 2 :: bootstrap this thing
	boot_ols reg `out' patient_voucher_high doctor_voucher_high patient_voucher_low doctor_voucher_low above_med_pos `totcont' `if', reppath(`path') repname(`setname') num(`numreps') dofirst(`dodo')
		
			test patient_voucher_high = doctor_voucher_high 
				local n1= 2*(1-normal(sqrt(r(F))))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDVhigh `combo'


			test patient_voucher_low = doctor_voucher_low 
				local n1= 2*(1-normal(sqrt(r(F))))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDVlow `combo'
							
				qui sum `out' if e(sample) & doctor_voucher + patient_voucher ==0

				local DV: display %7.3f `r(mean)'
	            estadd local DV `DV'
				
		estadd local space=""	
		est store E`ester'
				local eststr`counter' "`eststr`counter'' E`ester'"
				local paren`counter' "`paren`counter'' & (`ester')" // column numbers
				local ++ester	
		}
		local ++counter		
	
		} //end qui loop
* FIRST PANEL		
esttab `eststr1' using "`table'", keep(patient_voucher doctor_voucher) label  noabbrev `type' replace nogaps nomtit nonum ///
		stats(space p_PVDV p_PVDV0 , fmt( 0 0 0) labels("\emph{P-Values: Two-Sided Tests} \textcolor{white}{XXXXXXXXXXXXXXXXXX}" "\enspace $\beta_P=\beta_D$" "\enspace $\beta_P=\beta_D=0$")) ///
		nonote  star(* 0.10 ** 0.05 *** 0.01) `extrac1' ///
		b(a2) se(a2) noline subs("\beta\_" "\beta_") /// 
		prehead("\begin{table}[ht!] \begin{adjustbox}{max width=`texwid'\textwidth} \begin{threeparttable} \caption{`title'} \label{`label'} {\begin{tabular}{l*{`colcount'}{C{`widc'}}} \toprule \toprule `paren1' `extrahead' \\ `varhead' `extravarhead' \\ \toprule \multicolumn{`colcount'}{l}{`headz1'}  \\") 
* SECOND PANEL
esttab `eststr2' using "`table'", append keep(patient_voucher_high doctor_voucher_high  patient_voucher_low doctor_voucher_low above_med_pos) /// 
		label  noabbrev `type'  nogaps nomtit nonum ///
		stats(space p_PVDVhigh p_PVDVlow space DV N, fmt(0 0 0 0 a2 a0) /// 
		labels("\emph{P-values: Two-Sided Tests}  \textcolor{white}{XXXXXXXXXXXXXXXXXX}" "\enspace $\delta_{PH}=\delta_{DH}$" "\enspace $\delta_{PL}=\delta_{DL}$" " " "Mean (Control)" "N")) ///
		nonote  eqlabels(none) star(* 0.10 ** 0.05 *** 0.01) `extrac2' ///
		b(a2) se(a2) noline subs("\beta\_" "\beta_") /// 
		prehead("{ \begin{tabular}{l*{8}{C{`widc'}}} \\ \multicolumn{`colcount'}{l}{`headz`q''}  \\") /// 
		postfoot(\hline \end{tabular} } \begin{tablenotes}[flushleft] \small \item `footnote' \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}) 
end		



**************************************************************************************************************
* table to show one-panel / main effects using lasso, no theory driven tests
**************************************************************************************************************
cap prog drop docpat_p1_lso
prog define docpat_p1_lso
	est clear
syntax varlist [if], TEXWID(string) [Table(string)]  [TYPE(string)] [FOOTnote(string)] [PREHEAD1(string)] /// 
	                 [PREHEAD2(string)] [TITLE(string)] [LABel(string)] WIDC(string) [EXTRAC1(string)] [EXTRAC2(string)] /// 
					 [EXTRAHEAD(string)] [EXTRAVARHead(string)] CLUVar(string) [PARTIAL(string)] LCONT(string)
	
qui {


local q= 2
	local colcount= wordcount("`varlist'")+1
	local seclast= `q'-1	
	
// locals to assist in making the table
local ester=1
forval i=1/`q' {
	local eststr`i' ""	
	}
	
// label covariates
la var patient_voucher "$\beta_P$: Patient Voucher"
la var doctor_voucher "$\beta_D$: Doctor Voucher"
local counter=1	
	
	local varhead ""
	local paren`counter' ""
	foreach out in `varlist'  {

	// GET LABELS HERE
	local labelq : variable label `out'
		local varhead "`varhead'& `labelq'" //this is the label for columns		
			
		pdslasso `out'  patient_voucher doctor_voucher (`lcont') `if', clu(`cluvar') partial(`partial')

			test patient_voucher=doctor_voucher
				local n1= r(p)
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDV `combo'		
				
			test patient_voucher=doctor_voucher=0
				local n1= r(p)
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDV0 `combo'

				qui sum `out' if e(sample) & doctor_voucher+patient_voucher==0

				local DV: display %7.3f `r(mean)'
	            estadd local DV `DV'
						
			est store E`ester'
				local eststr`counter' "`eststr`counter'' E`ester'"
				local paren`counter' "`paren`counter'' & (`ester')" // column numbers
				local ++ester	
		}
		local ++counter	
	
		} //end qui loop
* FIRST PANEL		
esttab `eststr1' using "`table'", keep(patient_voucher doctor_voucher) label  noabbrev `type' replace nogaps nomtit nonum ///
		stats(space p_PVDV p_PVDV0 space DV N, fmt(0 0 0 0 a2 a0) labels("\emph{P-values}" "\enspace $\beta_P=\beta_D$" "\enspace $\beta_P=\beta_D=0$" " " "Mean (Control)" "N")) ///
		nonote  star(* 0.10 ** 0.05 *** 0.01) `extrac1' ///
		b(a2) se(a2) noline subs("\beta\_" "\beta_") /// 
		prehead("\begin{table}[ht!] \begin{adjustbox}{max width=`texwid'\textwidth} \begin{threeparttable} \caption{`title'} \label{`label'} {\begin{tabular}{l*{`colcount'}{C{`widc'}}} \toprule \toprule `paren1' `extrahead' \\ `varhead' `extravarhead' \\ \toprule ")  /// 
		postfoot(\hline \end{tabular} } \begin{tablenotes}[flushleft] \small \item `footnote' \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}) 
end		


**************************************************************************************************************
* table that looks at impact of patient information
**************************************************************************************************************
cap prog drop docpat_pat_aux_lso
prog define docpat_pat_aux_lso
	est clear
syntax varlist [if], TEXWID(string) [Table(string)]  [TYPE(string)] [FOOTnote(string)] [PREHEAD1(string)] /// 
	                 [PREHEAD2(string)] [TITLE(string)] [LABel(string)] WIDC(string) [EXTRAC1(string)] [EXTRAC2(string)] /// 
					 [EXTRAHEAD(string)] [EXTRAVARHead(string)] CLUVar(string) [PARTIAL(string)] LCONT(string)
	
qui {

local q= 2
	local colcount= wordcount("`varlist'")+1
	local seclast= `q'-1	
	
// locals to assist in making the table
local ester=1
forval i=1/`q' {
	local eststr`i' ""	
	}
	
// label covariates
la var patient_voucher "\enspace Patient Voucher"
la var doctor_voucher "\enspace Doctor Voucher"
la var patient_info "\enspace Patient Information"
la var pat_infoXno_voucher "\enspace Patient Information $\times$ No Voucher"
la var pat_infoXdoc_voucher "\enspace Doctor Voucher $\times$ Patient Information"
la var pat_infoXpat_voucher "\enspace Patient Voucher $\times$ Patient Information"

local counter=1	
	
	local varhead ""
	local paren`counter' ""
	foreach out in `varlist'  {
	
	// GET LABELS HERE
	local headz`counter' "\emph{Panel A. Overall Effects}" // this is the label for panels	
	local labelq : variable label `out'
		local varhead "`varhead'& `labelq'" //this is the label for columns		

		pdslasso `out' patient_info (`lcont') `if', clu(`cluvar') partial(`partial')
		
		qui sum `out' if e(sample) & patient_info==0
		local control_PI: display %10.3f `r(mean)'
		estadd local control_PI `control_PI'
						
			est store E`ester'
				local eststr`counter' "`eststr`counter'' E`ester'"
				local paren`counter' "`paren`counter'' & (`ester')" // column numbers
				local ++ester	
		}
		local ++counter
		
	local varhead ""
	local paren`counter' ""
	foreach out in `varlist'  {

	// GET LABELS HERE
	local headz`counter' "\emph{Panel B. By Voucher Treatment Group}" // this is the label for panels	
	local labelq : variable label `out'
		local varhead "`varhead'& `labelq'" //this is the label for columns		
		
		pdslasso `out' patient_info patient_voucher doctor_voucher pat_infoXpat_voucher pat_infoXdoc_voucher ($date $patient) `if', clu(`cluvar') partial(`partial')
						
			test patient_voucher = doctor_voucher
				local n1= r(p)
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_NoVPVDV `combo'
						
				qui sum `out' if e(sample) & patient_info +doctor_voucher + patient_voucher ==0
				estadd scalar noPInoVoucher=r(mean)
				
		estadd local space=""	
		est store E`ester'
				local eststr`counter' "`eststr`counter'' E`ester'"
				local paren`counter' "`paren`counter'' & (`ester')" // column numbers
				local ++ester	
		}
		local ++counter		
	
		} //end qui loop
* FIRST PANEL		
esttab `eststr1' using "`table'", keep(patient_info) label  noabbrev `type' replace nogaps nomtit nonum ///
		stats(space control_PI, fmt( 0 0) labels(" " "\enspace Mean (No PI)\textcolor{white}{XXXXXXXXXXXXXXX}")) ///
		nonote  star(* 0.10 ** 0.05 *** 0.01) `extrac1' ///
		b(a2) se(a2) noline subs("\beta\_" "\beta_") /// 
		prehead("\begin{table}[ht!] \begin{adjustbox}{max width=`texwid'\textwidth} \begin{threeparttable} \caption{`title'} \label{`label'} {\begin{tabular}{l*{`colcount'}{C{`widc'}}} \toprule \toprule `paren1' `extrahead' \\ `varhead' `extravarhead' \\ \toprule \multicolumn{`colcount'}{l}{`headz1'}  \\") 
* SECOND PANEL
esttab `eststr2' using "`table'", append keep(patient_info patient_voucher doctor_voucher pat_infoXpat_voucher pat_infoXdoc_voucher) /// 
		label  noabbrev `type'  nogaps nomtit nonum ///
		stats(space p_NoVPVDV space noPInoVoucher N, fmt(0 0 0 a3 a0) /// 
		labels("\enspace \emph{P-Values}" "\enspace \enspace Patient Voucher=Doctor Voucher" " "  "\enspace Mean (No PI, No Voucher)" "\enspace N")) ///
		nonote  eqlabels(none) star(* 0.10 ** 0.05 *** 0.01) `extrac2' ///
		b(a2) se(a2) noline subs("\beta\_" "\beta_") /// 
		prehead("{ \begin{tabular}{l*{8}{C{`widc'}}} \\ \multicolumn{`colcount'}{l}{`headz`q''}  \\") /// 
		postfoot(\hline \end{tabular} } \begin{tablenotes}[flushleft] \small \item `footnote' \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}) 
end		



**************************************************************************************************************
* table that looks at impact of patient information
**************************************************************************************************************
cap prog drop docpat_pat_lso
prog define docpat_pat_lso
	est clear
syntax varlist [if], TEXWID(string) [Table(string)]  [TYPE(string)] [FOOTnote(string)] [PREHEAD1(string)] /// 
	                 [PREHEAD2(string)] [TITLE(string)] [LABel(string)] WIDC(string) [EXTRAC1(string)] [EXTRAC2(string)] /// 
					 [EXTRAHEAD(string)] [EXTRAVARHead(string)] CLUVar(string) [PARTIAL(string)] LCONT(string)
	
qui {

local q= 2
	local colcount= wordcount("`varlist'")+1
	local seclast= `q'-1	
	
// locals to assist in making the table
local ester=1
forval i=1/`q' {
	local eststr`i' ""	
	}
	
// label covariates
la var patient_voucher "\enspace Patient Voucher"
la var doctor_voucher "\enspace Doctor Voucher"
la var patient_info "\enspace Patient Information"
la var doctor_voucher_x_patient_info "\enspace Doctor Voucher $\times$ Patient Information"
la var patient_voucher_x_patient_info "\enspace Patient Voucher $\times$ Patient Information"

local counter=1	
	
	local varhead ""
	local paren`counter' ""
	foreach out in `varlist'  {

	// GET LABELS HERE
	local headz`counter' "\emph{Panel B. By Voucher Treatment Group}" // this is the label for panels	
	local labelq : variable label `out'
		local varhead "`varhead'& `labelq'" //this is the label for columns		
		
		pdslasso `out' patient_info patient_voucher  doctor_voucher  patient_voucher_x_patient_info doctor_voucher_x_patient_info   ($date $patient) `if', clu(`cluvar') partial(`partial')
						
			test patient_voucher = doctor_voucher
				local n1= r(p)
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_NoVPVDV `combo'
						
				qui sum `out' if e(sample) & patient_info +doctor_voucher + patient_voucher ==0
				estadd scalar noPInoVoucher=r(mean)
				
		estadd local space=""	
		est store E`ester'
				local eststr`counter' "`eststr`counter'' E`ester'"
				local paren`counter' "`paren`counter'' & (`ester')" // column numbers
				local ++ester	
		}
		local ++counter		
	
		} //end qui loop
* FIRST PANEL		
esttab `eststr1' using "`table'", replace keep(patient_info patient_voucher  doctor_voucher  patient_voucher_x_patient_info doctor_voucher_x_patient_info   ) /// 
		label  noabbrev `type'  nogaps nomtit nonum ///
		stats(space noPInoVoucher N, fmt(0 a3 a0) /// 
		labels(" "  "\enspace Mean (No PI, No Voucher)" "\enspace N")) ///
		nonote  eqlabels(none) star(* 0.10 ** 0.05 *** 0.01) `extrac1' ///
		b(a2) se(a2) noline subs("\beta\_" "\beta_") /// 
		prehead("\begin{table}[h!] \begin{adjustbox}{max width=`texwid'\textwidth} \begin{threeparttable} \caption{`title'} \label{`label'} {\begin{tabular}{l*{`colcount'}{C{`widc'}}} \toprule \toprule `paren1' `extrahead' \\ `varhead' `extravarhead' \\ \toprule ")  /// 
		postfoot(\hline \end{tabular} } \begin{tablenotes}[flushleft] \small \item `footnote' \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}) 
end		


**************************************************************************************************************
* table that looks at impact of doctor information
**************************************************************************************************************
cap prog drop docpat_doc_lso
prog define docpat_doc_lso
	est clear
syntax varlist [if], TEXWID(string) [Table(string)]  [TYPE(string)] [FOOTnote(string)] [PREHEAD1(string)] /// 
	                 [PREHEAD2(string)] [TITLE(string)] [LABel(string)] WIDC(string) [EXTRAC1(string)] [EXTRAC2(string)] /// 
					 [EXTRAHEAD(string)] [EXTRAVARHead(string)] CLUVar(string) [PARTIAL(string)] LCONT(string)

qui {

local q= 2
	local colcount= wordcount("`varlist'")+1
	local seclast= `q'-1	
	
// locals to assist in making the table
local ester=1
forval i=1/`q' {
	local eststr`i' ""	
	}
	
// label covariates
la var patient_voucher "\enspace Patient Voucher"
la var doctor_voucher "\enspace Doctor Voucher"
la var infotreat "\enspace Doctor Information"
la var doctor_voucher_x_doctor_info "\enspace Doctor Voucher $\times$ Doctor Information"
la var patient_voucher_x_doctor_info "\enspace Patient Voucher $\times$ Doctor Information"

local counter=1	

	local varhead ""
	local paren`counter' ""
	foreach out in `varlist'  {

	// GET LABELS HERE
	local labelq : variable label `out'
		local varhead "`varhead'& `labelq'" //this is the label for columns		
		
		pdslasso `out' infotreat patient_voucher doctor_voucher patient_voucher_x_doctor_info doctor_voucher_x_doctor_info ($date $patient) `if', clu(`cluvar') partial(`partial')
						
			test patient_voucher = doctor_voucher
				local n1= r(p)
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_NoVPVDV `combo'
						
				qui sum `out' if e(sample) & infotreat +doctor_voucher + patient_voucher ==0
				local noDInoVoucher: display %7.3f `r(mean)'
	            estadd local noDInoVoucher `noDInoVoucher'
				
		est store E`ester'
				local eststr`counter' "`eststr`counter'' E`ester'"
				local paren`counter' "`paren`counter'' & (`ester')" // column numbers
				local ++ester	
		}
		local ++counter		
	
		} //end qui loop
* FIRST PANEL		
esttab `eststr1' using "`table'", replace keep(infotreat patient_voucher doctor_voucher patient_voucher_x_doctor_info doctor_voucher_x_doctor_info) /// 
		label  noabbrev `type'  nogaps nomtit nonum ///
		stats(space noDInoVoucher N, fmt(0 a3 a0) /// 
		labels(" "  "\enspace Mean (No DI, No Voucher)" "\enspace N")) ///
		nonote  eqlabels(none) star(* 0.10 ** 0.05 *** 0.01) `extrac1' ///
		b(a2) se(a2) noline subs("\beta\_" "\beta_") /// 
		prehead("\begin{table}[h!] \begin{adjustbox}{max width=`texwid'\textwidth} \begin{threeparttable} \caption{`title'} \label{`label'} {\begin{tabular}{l*{`colcount'}{C{`widc'}}} \toprule \toprule `paren1' `extrahead' \\ `varhead' `extravarhead' \\ \toprule ")  /// 
		postfoot(\hline \end{tabular} } \begin{tablenotes}[flushleft] \small \item `footnote' \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}) 
end		



**************************************************************************************************************
* ROBUSTNESS: main table w/ theory-driven tests (no lasso)
**************************************************************************************************************
cap prog drop docpat_p1_theory
prog define docpat_p1_theory
	est clear
syntax varlist [if], TEXWID(string) [Table(string)] [EXtra(varlist)]  [TYPE(string)] [FOOTnote(string)] [PREHEAD1(string)] /// 
	                 [PREHEAD2(string)] [TITLE(string)] [LABel(string)] WIDC(string) [EXTRAC1(string)] [EXTRAC2(string)] /// 
					 [EXTRAHEAD(string)] [EXTRAVARHead(string)] CLUVar(string) TESTOF(string) SIGNIFEVIDENCE(string)
	
qui {


local q= 2
	local colcount= wordcount("`varlist'")+1
	local seclast= `q'-1	
	
// locals to assist in making the table
local ester=1
forval i=1/`q' {
	local eststr`i' ""	
	}
	
// label covariates
la var patient_voucher "$\beta_P$: Patient Voucher"
la var doctor_voucher "$\beta_D$: Doctor Voucher"
local counter=1	
	
	local varhead ""
	local paren`counter' ""
	local outcount=1
	foreach out in `varlist'  {
	
	// GET LABELS HERE
	local labelq : variable label `out'
		local varhead "`varhead'& `labelq'" //this is the label for columns		
		
		reg `out'  patient_voucher doctor_voucher `extra' `if', clu(`cluvar')	

			test patient_voucher=doctor_voucher
				local n1= r(p)
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDV `combo'		
		
				local sign = sign(_b[patient_voucher]-_b[doctor_voucher])
				local n1= ttail(r(df_r),`sign'*sqrt(r(F)))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="ge" local p_one "`combo'"
					
				local n1= 1-ttail(r(df_r),`sign'*sqrt(r(F)))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="le" local p_one "`combo'"
				
				estadd local p_oneside `p_one'
				
			test patient_voucher=doctor_voucher=0
				local n1= r(p)
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDV0 `combo'

				qui sum `out' if e(sample) & doctor_voucher+patient_voucher==0


				local DV: display %7.3f `r(mean)'
	            estadd local DV `DV'
				
				tokenize `testof'
					estadd local test_of "``outcount''"

				tokenize `signifevidence'
					estadd local signif_evidence "``outcount''"
					
			est store E`ester'
				local eststr`counter' "`eststr`counter'' E`ester'"
				local paren`counter' "`paren`counter'' & (`ester')" // column numbers
				local ++ester	
		local ++outcount
		}
		local ++counter	
		} //end qui loop
* FIRST PANEL		
esttab `eststr1' using "`table'", keep(patient_voucher doctor_voucher) label  noabbrev `type' replace nogaps nomtit nonum ///
		stats(space p_PVDV test_of signif_evidence space DV N, fmt(0 0 0 0 0 a3 a0) labels("\emph{P-values and theory-driven tests}" "\enspace $\beta_P=\beta_D$" "\enspace Test for mechanism:" "\enspace Significant evidence of mechanism:" " " "Mean (Control)" "N")) ///
		nonote  star(* 0.10 ** 0.05 *** 0.01) `extrac1' ///
		b(a2) se(a2) noline subs("\beta\_" "\beta_") /// 
		prehead("\begin{table}[ht!] \begin{adjustbox}{max width=`texwid'\textwidth} \begin{threeparttable} \caption{`title'} \label{`label'} {\begin{tabular}{l*{`colcount'}{C{`widc'}}} \toprule \toprule `paren1' `extrahead' \\ `varhead' `extravarhead' \\ \toprule ")  /// 
		postfoot(\hline \end{tabular} } \begin{tablenotes}[flushleft] \small \item `footnote' \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}) 
end		




**************************************************************************************************************
* ROBUSTNESS: het effects table w/ theory-driven tests (no lasso)
**************************************************************************************************************
cap prog drop docpat_hettable_theory
prog define docpat_hettable_theory
	est clear
syntax varlist [if], TEXWID(string) [Table(string)] [EXtra(varlist)]  [TYPE(string)] [FOOTnote(string)] [PREHEAD1(string)] /// 
	                 [PREHEAD2(string)] [TITLE(string)] [LABel(string)] WIDC(string) [EXTRAC(string)] [PARTIAL(string)] /// 
					 [EXTRAHEAD(string)] [EXTRAVARHead(string)] CLUVar(string)  TESTOFH(string) SIGNIFEVIDENCEH(string)  TESTOFL(string) SIGNIFEVIDENCEL(string) ///
				     DODO(string) PATH(string) SETNAME(string) NUMReps(string)  
	
qui {

preserve

local q= 2
	local colcount= wordcount("`varlist'")+1
	local seclast= `q'-1	
	
// locals to assist in making the table
local ester=1
forval i=1/`q' {
	local eststr`i' ""	
	}
	
// label covariates
la var patient_voucher_high "$\delta_{PH}$: Patient Voucher $\times$ High Risk"
la var  doctor_voucher_high "$\delta_{DH}$: Doctor Voucher $\times$ High Risk" 
la var patient_voucher_low "$\delta_{PL}$: Patient Voucher $\times$ Low Risk"
la var doctor_voucher_low "$\delta_{DL}$: Doctor Voucher $\times$ Low Risk" 
la var above_med_pos "$\theta$: High Malaria Risk"
local counter=1	
	local varhead ""
	local paren`counter' ""
	local outcount=1
tempfile theuser
	save `theuser'
	foreach out in `varlist'  {
		drop _all
		use `theuser'
		
	// GET LABELS HERE
	local labelq : variable label `out'
		local varhead "`varhead'& `labelq'" //this is the label for columns		
				
	// bootstrap this thing
	boot_ols reg `out' patient_voucher_high doctor_voucher_high patient_voucher_low doctor_voucher_low above_med_pos `extrac' `if', reppath(`path') repname(`setname') num(`numreps') dofirst(`dodo')

	* NB: recalculate p-values to be based on asymptotic inference
			*     code written so we use asymptotics for both one and two-sided tests 
			test patient_voucher_high = doctor_voucher_high 
				local n1= 2*(1-normal(sqrt(r(F))))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDVhigh `combo'
			
				local sign = sign(_b[patient_voucher_high]-_b[doctor_voucher_high])
				local n1= 1-normal(`sign'*sqrt(r(F)))

				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="ge" local p_one_high "`combo'"

				local n1= normal(`sign'*sqrt(r(F)))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="le" local p_one_high "`combo'"
			
			test patient_voucher_low = doctor_voucher_low 
				local n1= 2*(1-normal(sqrt(r(F))))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDVlow `combo'
				
				local sign = sign(_b[patient_voucher_low]-_b[doctor_voucher_low])
				local n1= 1-normal(`sign'*sqrt(r(F)))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="ge" local p_one_low "`combo'"

				local n1= normal(`sign'*sqrt(r(F)))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="le" local p_one_low "`combo'"

				* CHECK THIS
				qui sum `out' if doctor_voucher + patient_voucher ==0 & above_med_pos==0
				
				local DV: display %7.3f `r(mean)'
	            estadd local DV `DV'
				
				tokenize `testofh'
					estadd local test_of_h "``outcount''"
				tokenize `signifevidenceh'
					estadd local signif_evidence_h "``outcount''"
				
				tokenize `testofl'
					estadd local test_of_l "``outcount''"
				tokenize `signifevidencel'
					estadd local signif_evidence_l "``outcount''"
					
					
			est store E`ester'
				local eststr`counter' "`eststr`counter'' E`ester'"
				local paren`counter' "`paren`counter'' & (`ester')" // column numbers
				local ++ester	
		local ++outcount
		}
		local ++counter	
		} //end qui loop
* FIRST PANEL		
esttab `eststr1' using "`table'", keep(patient_voucher_high doctor_voucher_high patient_voucher_low doctor_voucher_low above_med_pos) label  noabbrev `type' replace nogaps nomtit nonum ///
		stats(space p_PVDVhigh test_of_h signif_evidence_h space p_PVDVlow test_of_l signif_evidence_l space DV N, fmt(0 0 0 0 0 0 0 0 0 a2 a0) labels("\emph{P-values and theory-driven tests}" "\enspace $\delta_{PH}=\delta_{DH}$" "\enspace Test for mechanism:" "\enspace Significant evidence of mechanism:" " " "\enspace $\delta_{PL}=\delta_{DL}$" "\enspace Test for mechanism:" "\enspace Significant evidence of mechanism:" " " "Mean (Control, Low Risk)" "N")) ///
		nonote  star(* 0.10 ** 0.05 *** 0.01) `extrac1' ///
		b(a2) se(a2) noline subs("\beta\_" "\beta_") /// 
		prehead("\begin{table}[ht!] \begin{adjustbox}{max width=`texwid'\textwidth} \begin{threeparttable} \caption{`title'} \label{`label'} {\begin{tabular}{l*{`colcount'}{C{`widc'}}} \toprule \toprule `paren1' `extrahead' \\ `varhead' `extravarhead' \\ \toprule ")  /// 
		postfoot(\hline \end{tabular} } \begin{tablenotes}[flushleft] \small \item `footnote' \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}) 		

		restore
end	

**************************************************************************************************************
* TABLE FOR ANTIBIOTICS
**************************************************************************************************************
cap prog drop docpat_hettable_lso
prog define docpat_hettable_lso
	est clear
syntax varlist [if], TEXWID(string) [Table(string)]  [TYPE(string)] [FOOTnote(string)] [PREHEAD1(string)] PATH(string) SETNAME(string)  /// 
	                 [PREHEAD2(string)] [TITLE(string)] [LABel(string)] WIDC(string) [EXTRAC1(string)] [EXTRAC2(string)] [PARTIAL(string)] /// 
					 [EXTRAHEAD(string)] [EXTRAVARHead(string)] CLUVar(string) /// 
					 NUMreps(integer) DODO(string) LCONT(string)
					 
					 
qui {

preserve

local q= 2
	local colcount= wordcount("`varlist'")+1
	local seclast= `q'-1	

// locals to assist in making the table
local ester=1
forval i=1/`q' {
	local eststr`i' ""	
	}
	
// label covariates
la var patient_voucher_high "$\delta_{PH}$: Patient Voucher $\times$ High Risk"
la var  doctor_voucher_high "$\delta_{DH}$: Doctor Voucher $\times$ High Risk" 
la var patient_voucher_low "$\delta_{PL}$: Patient Voucher $\times$ Low Risk"
la var doctor_voucher_low "$\delta_{DL}$: Doctor Voucher $\times$ Low Risk" 
la var above_med_pos "$\theta$: High Malaria Risk"
local counter=1	
	
	local varhead ""
	local paren`counter' ""
	local outcount=1
tempfile theuser
	save `theuser'	
	foreach out in `varlist'  {
		drop _all
		use `theuser'
	
	// GET LABELS HERE
	local labelq : variable label `out'
		local varhead "`varhead'& `labelq'" //this is the label for columns		
		
	// step 1 :: select covariates using PDS lasso
		pdslasso `out'  patient_voucher_high doctor_voucher_high patient_voucher_low doctor_voucher_low above_med_pos (`lcont') `if', clu(`cluvar') partial(`partial')
			local totcont= "`e(xselected)' `e(xpartial)'"

		
	// step 2 :: bootstrap this thing
	boot_ols reg `out' patient_voucher_high doctor_voucher_high patient_voucher_low doctor_voucher_low above_med_pos `totcont' `if', reppath(`path') repname(`setname') num(`numreps') dofirst(`dodo')
			* NB: since this is bootstrapping after double post lasso, recalculate p-values to be based on asymptotic inference
			*     this ensures that we use asymptotics for both one and two-sided tests 
			test patient_voucher_high = doctor_voucher_high 
				local n1= 2*(1-normal(sqrt(r(F))))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDVhigh `combo'
			
				local sign = sign(_b[patient_voucher_high]-_b[doctor_voucher_high])
				local n1= 1-normal(`sign'*sqrt(r(F)))

				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="ge" local p_one_high "`combo'"

				local n1= normal(`sign'*sqrt(r(F)))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="le" local p_one_high "`combo'"
			
			test patient_voucher_low = doctor_voucher_low 
				local n1= 2*(1-normal(sqrt(r(F))))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				estadd local p_PVDVlow `combo'
				
				local sign = sign(_b[patient_voucher_low]-_b[doctor_voucher_low])
				local n1= 1-normal(`sign'*sqrt(r(F)))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="ge" local p_one_low "`combo'"

				local n1= normal(`sign'*sqrt(r(F)))
				local star ""
					if `n1'<=.01 local star "\sym{***}"
					if `n1'>.01 & `n1'<=.05 local star "\sym{**}"	
					if `n1'>.05 & `n1'<=.1 local star "\sym{*}"	
					local n2 = trim("`: display %10.3f `n1''")
					local combo "`n2'`star'"
				tokenize `oneside'
					if "``outcount''"=="le" local p_one_low "`combo'"

				
				qui sum `out' if e(sample) & doctor_voucher + patient_voucher ==0 & above_med_pos==0
				
				local DV: display %7.3f `r(mean)'
	            estadd local DV `DV'

				tokenize `testofhigh'
					estadd local test_of_high "``outcount''"
				tokenize `testoflow'
					estadd local test_of_low "``outcount''"
					estadd local p_one_high `p_one_high'
					estadd local p_one_low `p_one_low'
					
			est store E`ester'
				local eststr`counter' "`eststr`counter'' E`ester'"
				local paren`counter' "`paren`counter'' & (`ester')" // column numbers
				local ++ester	
		local ++outcount
		}
		local ++counter	
		} //end qui loop
* FIRST PANEL		
esttab `eststr1' using "`table'", keep(patient_voucher_high doctor_voucher_high patient_voucher_low doctor_voucher_low above_med_pos) label  noabbrev `type' replace nogaps nomtit nonum ///
		stats(space p_PVDVhigh  p_PVDVlow space DV N, fmt(0 0 0 0 a2 a0) labels("\emph{P-values}" "\enspace $\delta_{PH}=\delta_{DH}$"  "\enspace $\delta_{PL}=\delta_{DL}$" " " "Mean (Control, Low Risk)" "N")) ///
		nonote  star(* 0.10 ** 0.05 *** 0.01) `extrac1' ///
		b(a2) se(a2) noline subs("\beta\_" "\beta_") /// 
		prehead("\begin{table}[ht!] \begin{adjustbox}{max width=`texwid'\textwidth} \begin{threeparttable} \caption{`title'} \label{`label'} {\begin{tabular}{l*{`colcount'}{C{`widc'}}} \toprule \toprule `paren1' `extrahead' \\ `varhead' `extravarhead' \\ \toprule ")  /// 
		postfoot(\hline \end{tabular} } \begin{tablenotes}[flushleft] \small \item `footnote' \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}) 
restore 
end		

```

### `Lopez_Sautmann_Schaner_2020/Do_Files/Tables/1_table_control_group.do`
```stata

preserve

keep if treatment=="C" | treatment=="PI" 

* Varlists
gen cost_treat_simple=reported_totalcost if treat_simple_mal==1
gen cost_treat_severe=reported_totalcost if treat_severe_mal==1
gen cost_no_mal_treat=reported_totalcost if treat_sev_simple_mal==0
label var cost_treat_simple "Total Cost Simple Malaria (CFA)"
label var cost_treat_severe "Total Cost Severe Malaria (CFA)"
label var cost_no_mal_treat "Total Cost No Malaria Treatment (CFA)"
label var RXtreat_simple_mal "Simple Malaria Treatment: Prescribed" 
label var treat_simple_mal "Simple Malaria Treatment: Purchased" 
label var RXtreat_severe_mal "Severe Malaria Treatment: Prescribed" 
label var treat_severe_mal "Severe Malaria Treatment: Purchased" 
label var referral_observation "Patient Referred to Hospital or Placed Under Observation"
label var taking_treat_simple_mal "Taking Simple Malaria Treat"
label var antibiot "Purchased Antibiotics"
label var injection_IV "Received Injection or IV"
label var taking_treat_simple_mal "Taking Simple Malaria Treatment"
label var thinks_malaria "Respondent Suspects Illness is Malaria (Pre-Consultation)"
local varlist1_intro "thinks_malaria RXtreat_simple_mal treat_simple_mal RXtreat_severe_mal treat_severe_mal antibiot injection_IV referral_observation cost_no_mal_treat cost_treat_simple cost_treat_severe "
 

* Varlists
	local v0= wordcount("`varlist1_intro'")
local totrow= `v0'

matrix table_control_group=J(`totrow',8,.)

loc f = 1
foreach var of local varlist1_intro{

local lbz: variable label `var'
local part`f' "\enspace `lbz' &"

* ALL SAMPLE
	sum `var' 
	local mean: display %10.3f r(mean)
	local N: display %9.0f r(N)
	matrix table_control_group[`f',1] =`mean'
	matrix table_control_group[`f',2] =`N'
	
* ALL PATIENTS WITH VALID TEST	
	sum `var' if RDTresult_NEG!=.
	local mean: display %10.3f r(mean)
	local N: display %9.0f r(N)
	matrix table_control_group[`f',3] =`mean'
	matrix table_control_group[`f',4] =`N'
	
* ALL PATIENTS WITH POSITIVE TEST
	sum `var' if RDTresult_NEG==0
	local mean: display %10.3f r(mean)
	local N: display %9.0f r(N)
	matrix table_control_group[`f',5] =`mean'
	matrix table_control_group[`f',6] =`N'
	
* ALL PATIENTS WITH NEGATIVE TEST
	sum `var' if RDTresult_NEG==1
	local mean: display %10.3f r(mean)
	local N: display %9.0f r(N)
	matrix table_control_group[`f',7] =`mean'
	matrix table_control_group[`f',8] =`N'

local f=`f'+1
	
}

drop _all
svmat table_control_group

g t0=""
	forval i=1/`totrow' {
		di "`part`i''"
		replace t0= "`part`i''" if _n==`i'
	}

foreach i of numlist 1 3 4 5 6 7{	
		tostring table_control_group`i', format("%9.3f") replace force
		replace table_control_group`i'="" if table_control_group`i'=="."
		replace table_control_group`i'="0"+table_control_group`i' if substr(table_control_group`i',1,1)=="."
		replace table_control_group`i'= table_control_group`i'+"&"
	}
	
		tostring table_control_group2, format("%9.0f") replace force
		replace table_control_group2="" if table_control_group2=="."
		replace table_control_group2="0"+table_control_group2 if substr(table_control_group2,1,1)=="."
		replace table_control_group2= table_control_group2+"&"

		tostring table_control_group8, format("%9.3f") replace force
		replace table_control_group8="" if table_control_group8=="."
		replace table_control_group8="0"+table_control_group8 if substr(table_control_group8,1,1)=="."
		replace table_control_group8= table_control_group8+"&" if table_control_group8==""	
		
set obs `=_N+5'		
	g index= _n
		replace index=0 if _n==_N-1
		replace index=.5 if _n==_N-2
		replace index= 5.5 if _n==_N-3
		replace index= 8.5 if _n==_N-4
			replace t0= "\emph{Panel A. Malaria Beliefs and Treatment Outcomes} &" if index==.5
			replace t0= "\emph{Panel B. Other Treatment Outcomes} &" if index==5.5
			replace t0= "\emph{Panel C. Patient Costs} &" if index==8.5
	sort index
	
forval i=3/8 {
	replace table_control_group`i'="-- &" if index>8.5 & index<12
	}
replace table_control_group7= table_control_group7+"\\" if index>0 & index<_N
	
order t0 table_control_group2 table_control_group1 table_control_group3-table_control_group8
	drop table_control_group8 table_control_group6 table_control_group4
keep t0-table_control_group7
list, clean

#delimit ;

local fn "\emph{Notes}: Column 1 reports the number of non-missing observations of variables among all individuals in the Control group. Column 2 reports means for this sample. Columns 3-6 limit the sample to Control group individuals who were administered a valid RDT test at home, with column 3 reporting means for all patients with a valid test, column 4 reporting means for patients with a positive test, and column 5 reporting means for patients with a negative test. Sample sizes for columns 3, 4, and 5 are 346, 86, and 260 respectively. Variables measured in CFA top-coded at the 99th percentile. CFA610 $\approx$ USD1.";
local text0 "\begin{table}[h!] \begin{adjustbox}{max width=1.2\textwidth} \begin{threeparttable} \caption{Descriptive Statistics from Control Group} \label{control_group} { 
			\begin{tabular}{l*{6}{c}} \hline\hline & \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)}  \\
			& \multicolumn{2}{c}{Full Sample}  &  \multicolumn{3}{c}{Has Valid RDT (Home Survey)} &  \\ 
			\cmidrule(lr){2-3} \cmidrule(lr){4-6}  & 
				\multicolumn{1}{c}{\shortstack{N}} & \multicolumn{1}{c}{\shortstack{Mean}} & \multicolumn{1}{c}{\shortstack{All\\Patients}} & \multicolumn{1}{c}{\shortstack{RDT\\Positive}}  & 
				\multicolumn{1}{c}{\shortstack{RDT\\Negative}}  \\ \hline";
local textlast "\hline \end{tabular} } \begin{tablenotes}[flushleft] \small 
		\item `fn' 
		\end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}";
#delimit cr	
	replace t0="`text0'" if _n==1
	replace t0="`textlast'" if _n==_N
*	replace t0=" & " if t1!="" & _n>=2 & _n<_N & t0==""

outfile t0-table_control_group7 using "$tables/1_control_group.tex", noquote replace wide		
	
restore

```

### `Lopez_Sautmann_Schaner_2020/Do_Files/Tables/2_table_balance.do`
```stata

/*-------------------------------------------------------------------------------------------------------------------------------------
	
	Table: Demographic variables. Randomization table. Strata and date FE. ALL PATIENTS THAT SATISFY: Present + Acutely ill + Symptoms>=1
	
-------------------------------------------------------------------------------------------------------------------------------------*/

preserve
		
local namestr  `" "\it{A. Sample Frame}" "' 
	di `"`namestr'"'
la var digestiveproblemsintake "Digestive Problems"
la var poorappetiteintake "Poor Appetite"
la var genderpatient "Male (Patient)"
la var breathingintake "Difficulty Breathing"
la var readwrite_fluent_french "Literate (in French)"
la var gender "Male"
la var islamicschool "Islamic School"
la var ltmiddleschool "Primary School"
la var middleschool "Middle School"
la var ethnic_bambara "Bambara"
la var took_meds_before "Meds Before Visit"
la var thinks_malaria "Suspects Malaria"
la var roomshousehold "Rooms in Home"
la var members14oryounger_H "HH Members Under 15"
la var members15orolder_H "HH Members 15 or Older"
la var membersjob_H "HH Members Working"
la var totalincome_H "Total HH Income" 
la var mosquitonets_H "Number Mosquito Nets"
la var rent_value_H "Rental Value of Home"
la var symptomsscreening_4 "Poor Appetite"
la var symptomsscreening_7 "Weakness/Fatigue"
la var agepatient "Age"
la var age "Age"
la var total_hh_members_H "Household Size"
la var pred_mal_pos "Predicted Malaria Risk"
la var in_home_survey "In Home Survey"
la var has_valid_rdt_H "Took Home-Based RDT"
la var genderpatient "Male"
la var speak_french "Speaks French"
la var prischoolorless "Primary School or Less"


* LABELS
foreach var in total_hh_members_H HH_frac_14 HH_frac_job income_percap_H rent_value_H HH_frac_nets {
	local lbz: variable label `var'
	local lbz "`lbz'$^+$"
		la var `var' "`lbz'"
	}
	
foreach var in $varlist0 $varlist1 $varlist2 {
	local repx ""
	if "`var'"!="nobs" & "`var'"!="bobs" local repx "replace `var'=. if dropme==1"
	`repx'
	}
	
* Varlists
	local v0= wordcount("$varlist0")
	local v1= wordcount("$varlist1")	
	local v2= wordcount("$varlist2")
	

local totrow= 2*(`v0'+`v1'+`v2')+3
	matrix table_randomization=J(`totrow',8,.)
	matrix se= J(`totrow',1,.)

local part1 "\multicolumn{7}{l}{\it{A. Sample Frame (Clinic $\times$ Day-Level Observations)}}"
	
loc f = 2

foreach var in $varlist0 {

local lbz: variable label `var'
	local namestr " `namestr' "`lbz'" "\thinspace" "

local q= `f'+1
local part`f' "\enspace `lbz' &"
local part`q' "\thinspace &" 	

*Regressions
reg `var' patient_voucher doctor_voucher $date, clu($cluvar)
	local coeff_patient_voucher: display %19.3f _b[patient_voucher]
	local coeff_doctor_voucher:  display %19.3f _b[doctor_voucher]
	local se_patient_voucher: display %19.3f _se[patient_voucher]
	local se_doctor_voucher:  display %19.3f _se[doctor_voucher]
	
	matrix table_randomization[`f',2] =`coeff_patient_voucher'
	matrix table_randomization[`f',3] =`coeff_doctor_voucher'

	matrix table_randomization[`f'+1,2] =`se_patient_voucher'
	matrix table_randomization[`f'+1,3] =`se_doctor_voucher'

	matrix se[`f'+1,1]=1

	*P-value
	test patient_voucher==doctor_voucher
	local p_value1: display %7.3f `r(p)'
	matrix table_randomization[`f',4] =`p_value1'
	
	*P-value
	test patient_voucher==doctor_voucher==0
	local p_value2: display %7.3f `r(p)'
	matrix table_randomization[`f',5] =`p_value2'

	*Number of observations
	matrix table_randomization[`f',6] =e(N)
	
	*Average for treatment group
	sum `var' if doctor_voucher+patient_voucher==0 & e(sample)
	local control_mean: display %19.3f r(mean)
	local control_sd: display %19.3f r(sd)

	matrix table_randomization[`f',1] =`control_mean'
	matrix table_randomization[`f'+1,1] =`control_sd'
	
	*Increase the counter of the row 
	loc f = `f' + 2

}

local sustring ""
local sutest1 ""
local sutest2 ""

local part`f' "\multicolumn{7}{l}{\it{B. Patient Characteristics (Individual-Level Observations)}}"
	
local f = `f'+1

local namestr " `namestr' "\it{B. Patient Characteristics}" "

foreach var in $varlist1 {


local lbz: variable label `var'
	local namestr " `namestr' "`lbz'" "\thinspace" "
	
local q= `f'+1
local part`f' "\enspace `lbz' &"
local part`q' "\thinspace &"
	
*Regressions
reg `var'  patient_voucher doctor_voucher $date
	est store E`var'
	local sustring "`sustring' E`var'"
	local sutest2 "`sutest2' [E`var'_mean]patient_voucher=[E`var'_mean]doctor_voucher="
	local sutest1 "`sutest1' [E`var'_mean]patient_voucher=[E`var'_mean]doctor_voucher="
 reg `var' patient_voucher doctor_voucher $date, clu($cluvar)
	local coeff_patient_voucher: display %19.3f _b[patient_voucher]
	local coeff_doctor_voucher:  display %19.3f _b[doctor_voucher]
	local se_patient_voucher: display %19.3f _se[patient_voucher]
	local se_doctor_voucher:  display %19.3f _se[doctor_voucher]
	
	matrix table_randomization[`f',2] =`coeff_patient_voucher'
	matrix table_randomization[`f',3] =`coeff_doctor_voucher'

	matrix table_randomization[`f'+1,2] =`se_patient_voucher'
	matrix table_randomization[`f'+1,3] =`se_doctor_voucher'

	matrix se[`f'+1,1]=1

	*P-value
	test patient_voucher==doctor_voucher
	local p_value1: display %7.3f `r(p)'
	matrix table_randomization[`f',4] =`p_value1'
	
	*P-value
	test patient_voucher==doctor_voucher==0
	local p_value2: display %7.3f `r(p)'
	matrix table_randomization[`f',5] =`p_value2'

	*Number of observations
	matrix table_randomization[`f',6] =e(N)
	
	*Average for treatment group
	sum `var' if doctor_voucher+patient_voucher==0 & e(sample)
	local control_mean: display %19.3f r(mean)
	local control_sd: display %19.3f r(sd)

	matrix table_randomization[`f',1] =`control_mean'
	matrix table_randomization[`f'+1,1] =`control_sd'
	
	*Increase the counter of the row 
	loc f = `f' + 2

}
	
mat li table_randomization


****************************


local part`f' "\multicolumn{7}{l}{\it{C. Respondent and Household Characteristics (Individual-Level Observations)}}"
	
local f = `f'+1

local namestr " `namestr' "\it{C. Respondent Characteristics}" "

foreach var in $varlist2 {


local lbz: variable label `var'
	local namestr " `namestr' "`lbz'" "\thinspace" "
	
local q= `f'+1
local part`f' "\enspace `lbz' &"
local part`q' "\thinspace &"
	
* REGRESSIONS
reg `var'  patient_voucher doctor_voucher $date
	est store E`var'
	local sustring "`sustring' E`var'"
	local sutest2 "`sutest2' [E`var'_mean]patient_voucher=[E`var'_mean]doctor_voucher="
	local sutest1 "`sutest1' [E`var'_mean]patient_voucher=[E`var'_mean]doctor_voucher="
 reg `var' patient_voucher doctor_voucher $date, clu($cluvar)
	local coeff_patient_voucher: display %19.3f _b[patient_voucher]
	local coeff_doctor_voucher:  display %19.3f _b[doctor_voucher]
	local se_patient_voucher: display %19.3f _se[patient_voucher]
	local se_doctor_voucher:  display %19.3f _se[doctor_voucher]
	
	matrix table_randomization[`f',2] =`coeff_patient_voucher'
	matrix table_randomization[`f',3] =`coeff_doctor_voucher'

	matrix table_randomization[`f'+1,2] =`se_patient_voucher'
	matrix table_randomization[`f'+1,3] =`se_doctor_voucher'

	matrix se[`f'+1,1]=1

	*P-value
	test patient_voucher==doctor_voucher
	local p_value1: display %7.3f `r(p)'
	matrix table_randomization[`f',4] =`p_value1'
	
	*P-value
	test patient_voucher==doctor_voucher==0
	local p_value2: display %7.3f `r(p)'
	matrix table_randomization[`f',5] =`p_value2'

	*Number of observations
	matrix table_randomization[`f',6] =e(N)
	
	*Average for treatment group
	sum `var' if doctor_voucher+patient_voucher==0 & e(sample)
	local control_mean: display %19.3f r(mean)
	local control_sd: display %19.3f r(sd)

	matrix table_randomization[`f',1] =`control_mean'
	matrix table_randomization[`f'+1,1] =`control_sd'
	
	*Increase the counter of the row 
	loc f = `f' + 2
	
}

local sutest1 "`sutest1' [Egender_mean]patient_voucher"
local sutest2 "`sutest2' 0"
	
local df= e(df_r)
		
mat li table_randomization
matrix rownames table_randomization= `namestr'

local bc = rowsof(table_randomization)

matrix stars = J(`bc',6,0)

	local end0= `v0'*2
	local start1= `end0'+3
	local end1= `start1' + `v1'*2
	local start2= `end1'+3
	local end2= `totrow'-1
	
forvalues i=4(1)5{

forvalues k = 2(2)`end0' {

	if table_randomization[`k',`i']<=.01{
	local star "1"
	}
	if table_randomization[`k',`i']>.01 & table_randomization[`k',`i']<=.05{
	local star "2"
	}
	if table_randomization[`k',`i']>.05 & table_randomization[`k',`i']<=.10{
	local star "3"
	}
	if table_randomization[`k',`i']>.10{
	local star "0"
	}
	di
    matrix stars[`k',`i'] = `star'
}

forvalues k = `start1'(2)`end1' {

	if table_randomization[`k',`i']<=.01{
	local star "1"
	}
	if table_randomization[`k',`i']>.01 & table_randomization[`k',`i']<=.05{
	local star "2"
	}
	if table_randomization[`k',`i']>.05 & table_randomization[`k',`i']<=.10{
	local star "3"
	}
	if table_randomization[`k',`i']>.10 {
	local star "0"
	}
	di
    matrix stars[`k',`i'] = `star'
}

forvalues k = `start2'(2)`end2' {

	if table_randomization[`k',`i']<=.01{
	local star "1"
	}
	if table_randomization[`k',`i']>.01 & table_randomization[`k',`i']<=.05{
	local star "2"
	}
	if table_randomization[`k',`i']>.05 & table_randomization[`k',`i']<=.10{
	local star "3"
	}
	if table_randomization[`k',`i']>.10 {
	local star "0"
	}
	di
    matrix stars[`k',`i'] = `star'
}
}

// use critical values from t-distribution, just as is done in regressions
local cv10= abs(invt(`df',.05))
local cv5= abs(invt(`df',.025))
local cv1= abs(invt(`df',.005))
	
forvalues i=2(1)3{

	forvalues k = 2(2)`end0' {

		local ttest=abs(table_randomization[`k',`i']/table_randomization[`k'+1,`i'])
		if `ttest'<`cv10' {
		local star "0"
		}
		if `ttest'>=`cv10' & `ttest'<`cv5' {
		local star "3"
		}
		if `ttest'>=`cv5' & `ttest'<`cv1' {
		local star "2"
		}
		if `ttest'>=`cv1' & `ttest'!=. {
		local star "1"
		}
		di
		matrix stars[`k',`i'] = `star'
	}

	forvalues k = `start1'(2)`end1' {

		local ttest=abs(table_randomization[`k',`i']/table_randomization[`k'+1,`i'])
		if `ttest'<`cv10' {
		local star "0"
		}
		if `ttest'>=`cv10' & `ttest'<`cv5' {
		local star "3"
		}
		if `ttest'>=`cv5' & `ttest'<`cv1' {
		local star "2"
		}
		if `ttest'>=`cv1' & `ttest'!=. {
		local star "1"
		}
		di
		matrix stars[`k',`i'] = `star'	
		
		}	
	forvalues k = `start2'(2)`end2' {

		local ttest=abs(table_randomization[`k',`i']/table_randomization[`k'+1,`i'])
		if `ttest'<`cv10' {
		local star "0"
		}
		if `ttest'>=`cv10' & `ttest'<`cv5' {
		local star "3"
		}
		if `ttest'>=`cv5' & `ttest'<`cv1' {
		local star "2"
		}
		if `ttest'>=`cv1' {
		local star "1"
		}
		di
		matrix stars[`k',`i'] = `star'	
		
		}

}

drop _all
svmat table_randomization
svmat stars
svmat se
g t0=""
	forval i=1/`totrow' {
		di "`part`i''"
		replace t0= "`part`i''" if _n==`i'
	}
	
forval var=1/5 {
		tostring table_randomization`var', format("%9.3f") replace force
			replace table_randomization`var'="" if table_randomization`var'=="."
			replace table_randomization`var'="0"+table_randomization`var' if substr(table_randomization`var',1,1)=="."
			
		replace table_randomization`var'= table_randomization`var'+"\sym{*}" if stars`var'==3
		replace table_randomization`var'= table_randomization`var'+"\sym{**}" if stars`var'==2
		replace table_randomization`var'= table_randomization`var'+"\sym{***}" if stars`var'==1
		
	}
			tostring table_randomization6, format("%9.0f") replace force

replace table_randomization1= "["+table_randomization1+"]" if se1==1

forval i=2/3 {
		replace table_randomization`i'="("+table_randomization`i'+")" if se1==1
	}

forval i=1/5 {
		replace table_randomization`i'= table_randomization`i'+"&" if substr(t0,1,7)!="\multic"
	}
		replace table_randomization6= "" if table_randomization6=="." & se1==1
		replace table_randomization6= table_randomization6+"\\" if table_randomization6!="" | substr(t0,1,7)=="\multic"
		replace table_randomization6= table_randomization6+"& \\" if table_randomization6==""	
		
set obs `=_N+2'		
	g index= _n
	replace index=0 if _n==_N-1
	sort index
order t0 table_randomization1-table_randomization8
keep t0-table_randomization8 
list, clean 

#delimit ;
local fn "$footnote0_alt $^+$ indicates that variable was recorded in the home survey only. Variables measured in CFA and duration of illness top-coded at the 99th percentile. CFA610 $\approx$ USD1. $footnote1";
local text0 "\begin{table}[h!] \begin{adjustbox}{max width=.8\textwidth} \begin{threeparttable} \caption{Demographic Characteristics and Randomization Verification} \label{balance} { 
			\begin{tabular}{l*{7}{c}} \hline\hline & \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)}  \\
			&  &  \multicolumn{2}{c}{Regression Coefficients} & \multicolumn{2}{c}{P-Values} &  \\ 
			\cmidrule(lr){3-4} \cmidrule(lr){5-6}  & 
				\multicolumn{1}{c}{\shortstack{Control\\Mean}} & \multicolumn{1}{c}{\shortstack{Patient\\Voucher}} & \multicolumn{1}{c}{\shortstack{Doctor\\ Voucher}}  & 
				\multicolumn{1}{c}{\shortstack{Joint Test\\ PV=DV}} & \multicolumn{1}{c}{\shortstack{Joint Test \\ PV=DV=0}} & \multicolumn{1}{c}{N} \\ \hline";
local textlast "\hline \end{tabular} } \begin{tablenotes}[flushleft] \small 
		\item `fn' 
		\end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}";
#delimit cr	
	replace t0="`text0'" if _n==1
	replace t0="`textlast'" if _n==_N
*	replace t0=" & " if t1!="" & _n>=2 & _n<_N & t0==""

outfile t0-table_randomization6 using "$tables/2_balance.tex", noquote replace wide		
list
restore

```

### `Lopez_Sautmann_Schaner_2020/Do_Files/Tables/B1_table_clinic_census.do`
```stata

* General analysis of the census
	
	drop if cscom==7 // missing info
	
foreach var in q4_num_saldoc q4_num_intern q4_othRX {
		replace `var'=0 if `var'==. | `var'<0
		}

foreach var in q5a q5b q5c q5d {
		replace `var'=0 if `var'<0 | `var'==.
		}
		
foreach var in q6a q6b q6c q6d {
		replace `var'=0 if `var'<0 | `var'==.
		}
label var 	q4_num_saldoc "\enspace Doctors"
label var 	q4_num_intern "\enspace Medical trainees"
label var 	q4_othRX "\enspace Other staff"
label var 	q5a "\enspace Doctors"
label var 	q5b "\enspace Medical trainees"
label var 	q5c "\enspace Lab technician"
label var 	q5d "\enspace Other staff"
label var 	q6a "\enspace Doctors"
label var 	q6b "\enspace Medical trainees"
label var 	q6c "\enspace Lab technician"
label var 	q6d "\enspace Other staff"

replace q1_open="7:00" if q1_open=="07H00" |  q1_open=="07h00"
replace q1_open="7:30" if q1_open=="07h30" |  q1_open=="7h30"
replace q1_open="8:00" if q1_open=="08h00"
gen double doctor_start = clock(q1_open,"hm")
replace q1_close="14:00" if q1_close=="14h00"
replace q1_close="14:30" if q1_close=="14h30"
replace q1_close="15:00" if q1_close=="15h00" |  q1_close=="15hh00"
replace q1_close="16:00" if q1_close=="16h00"
replace q1_close="16:30" if q1_close=="16h30"
replace q1_close="17:30" if q1_close=="17h00"
gen double doctor_end = clock(q1_close,"hm")
format doctor_end %tcHH:MM
format doctor_start %tcHH:MM
replace q2_pharm_open_MF="08h00" if cscomnum ==43 & q2_pharm_open_MF=="14h00"
replace q2_pharm_close_MF="14h00" if cscomnum ==43 & q2_pharm_close_MF=="08h00"
replace q2_pharm_open_MF="7:00" if q2_pharm_open_MF=="07h00"
replace q2_pharm_open_MF="6:00" if q2_pharm_open_MF=="06h00"
replace q2_pharm_open_MF="7:30" if q2_pharm_open_MF=="07h30"
replace q2_pharm_open_MF="8:00" if q2_pharm_open_MF=="08h00"
replace q2_pharm_close_MF="7:00" if q2_pharm_close_MF=="07h00" |  q2_pharm_close_MF=="7h00"
replace q2_pharm_close_MF="7:30" if q2_pharm_close_MF=="07h30"
replace q2_pharm_close_MF="8:00" if q2_pharm_close_MF=="08h00"
replace q2_pharm_close_MF="14:00" if q2_pharm_close_MF=="14h00"
replace q2_pharm_close_MF="14:30" if q2_pharm_close_MF=="14h30"
replace q2_pharm_close_MF="15:00" if q2_pharm_close_MF=="15h00"
replace q2_pharm_close_MF="16:00" if q2_pharm_close_MF=="16h00"
replace q2_pharm_close_MF="16:30" if q2_pharm_close_MF=="16h30"
replace q2_pharm_close_MF="17:00" if q2_pharm_close_MF=="17h00"
replace q2_pharm_close_MF="22:00" if q2_pharm_close_MF=="22h00"
replace q2_pharm_close_MF="23:00" if q2_pharm_close_MF=="23h00"
gen double pharma_start = clock( q2_pharm_open_MF ,"hm")
gen double pharma_end = clock( q2_pharm_close_MF ,"hm")
format pharma_start %tcHH:MM
format pharma_end %tcHH:MM
replace pharma_end=. if pharma_end<=pharma_start		

gen doc_pharma=1 if (pharma_start>=doctor_start) & (pharma_end<=doctor_end)

gen difference_start=abs(pharma_start-doctor_start)
gen minutes_start = minutes(difference_start)

gen difference_end=abs(pharma_end-doctor_end)
gen minutes_end = minutes(difference_end)

replace doc_pharma=1 if minutes_start+minutes_end<=120  & doc_pharma==.

replace doc_pharma=0 if (minutes_start+minutes_end>120 & minutes_start+minutes_end<.) & doc_pharma==.

label var doc_pharma "\enspace Doctor in staff during pharmacy hours"

local varlist "q4_num_saldoc q4_num_intern q4_othRX q5a q5b q5c q5d q6a q6b q6c q6d doc_pharma"
local v0= wordcount("`varlist'")

local totrow= `v0'
matrix table_mean=J(`totrow',5,.)
	
local f=1
foreach var of local varlist{

local lbz: variable label `var'
	local namestr " `namestr' "`lbz'" "\thinspace" "
	
local q= `f'+1
local part`f' "\enspace `lbz' &"
local part`q' "\thinspace &"
		
	*Average for treatment group
	sum `var'
	local control_mean: display %19.3f r(mean)
	local control_sd: display %19.3f r(sd)

	matrix table_mean[`f',1] =`control_mean'
	matrix table_mean[`f',2] =`control_sd'
	matrix table_mean[`f',3] =r(min)
	matrix table_mean[`f',4] =r(max)
	matrix table_mean[`f',5] =r(N)
	
	*Increase the counter of the row 
	loc f = `f' + 1

}

drop _all
svmat table_mean
g t0=""
	forval i=1/`totrow' {
		di "`part`i''"
		replace t0= "`part`i''" if _n==`i'
	}
	
forval var=1/2 {
		tostring table_mean`var', format("%9.3f") replace force
			replace table_mean`var'="" if table_mean`var'=="."
			replace table_mean`var'="0"+table_mean`var' if substr(table_mean`var',1,1)=="."
		
	}	
	

forval i=3/5 {
			tostring table_mean`i', format("%9.0f") replace force
			replace table_mean`i'="" if table_mean`i'=="."
			replace table_mean`i'="0"+table_mean`i' if substr(table_mean`i',1,1)=="."
}

forval i=1/4 {
		replace table_mean`i'= table_mean`i'+"&"
	}
	
			
set obs `=_N+6'		
	g index= _n
		replace index=0 if _n==_N-1
		replace index=.5 if _n==_N-2
		replace index= 3.5 if _n==_N-3
		replace index= 7.5 if _n==_N-4
		replace index= 11.5 if _n==_N-5

			replace t0= "\multicolumn{5}{l}{\emph{Panel A. Number Staff Who Can Write Malaria Prescriptions}} &" if index==.5
			replace t0= "\multicolumn{5}{l}{\emph{Panel B. Number Staff Who Can Perform an RDT Test}} &" if index==3.5
			replace t0= "\multicolumn{5}{l}{\emph{Panel C. Number Staff Who Can Perform a Microscopy Test}} &" if index==7.5
			replace t0= "\multicolumn{5}{l}{\emph{Panel D. Pharmacy}} &" if index==11.5
			
sort index
	
replace table_mean5= table_mean5+"\\" if index>0 & index<_N
			
order t0 table_mean1-table_mean5
keep t0-table_mean5
list, clean

#delimit ;
local fn "\emph{Notes}: Data from clinics census. Rapid Diagnostic Test (RDT) is a cassette-like device that measures a patient's true malaria 
status by using a small amount of blood, are easy to interpret; the microscopy test requires a microscope
managed by well-trained personnel. Medical trainees include interns doing medical training, out of hours providers or non-salaried doctors.
Panel D indicates a dummy variable that takes value 1 if a doctor in staff is present during pharmacy hours on weekdays (including a difference of at most 2 hs.)";
local text0 "\begin{table}[h!] \begin{adjustbox}{max width=.85\textwidth} \begin{threeparttable} \caption{Overview of Clinic Staffing} \label{clinic_census} { 
			\begin{tabular}{l*{6}{c}} \hline\hline & \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)}  & \multicolumn{1}{c}{(4)}  & \multicolumn{1}{c}{(5)}  \\
			& \multicolumn{1}{c}{\shortstack{Mean}} & \multicolumn{1}{c}{SD} & \multicolumn{1}{c}{Min} & \multicolumn{1}{c}{Max} & \multicolumn{1}{c}{N} \\ \hline";
local textlast "\hline \end{tabular} } \begin{tablenotes}[flushleft] \small 
		\item `fn' 
		\end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}";
#delimit cr	
	replace t0="`text0'" if _n==1
	replace t0="`textlast'" if _n==_N

outfile t0-table_mean5 using "$tables/B1_clinic_census.tex", noquote replace wide		
	

```

### `Lopez_Sautmann_Schaner_2020/Do_Files/Tables/B2_table_means_doctor.do`
```stata

* Health workers beliefs

* Same decision in the regression analysis
drop if inlist(position,6,8,9) // drop midwives, la techs, medical biologists
	drop if other_position=="Chargé de la santé de la reproduction" | other_position=="Pharmacien" | other_position=="Directeur Administratif"

g mal_cscom= (malariaabove5 + malariaunder5)/100
	la var mal_cscom "Malaria Prevalence: CSCom Patients"
	la var prevalencemalaria "Malaria Prevalence: General Population"
	la var whichmedicines_antimalarial "\enspace Feels Pressure: Antimalarials"
	la var whichmedicines_painkiller "\enspace Feels Pressure: Pain Killers"
	la var whichmedicines_antibiotic "\enspace Feels Pressure: Antibiotics"
	la var whichmedicines_other "\enspace Feels Pressure: Other Medicines"
	la var pressuremedicines "Feels Pressure from Patients to Prescribe Unnecessary Medication"
	
local varlist "prevalencemalaria mal_cscom pressuremedicines whichmedicines_antimalarial whichmedicines_painkiller whichmedicines_antibiotic whichmedicines_other"
local v0= wordcount("`varlist'")

local totrow= `v0'
matrix table_mean=J(`totrow',3,.)
	
local f=1
foreach var of local varlist{

local lbz: variable label `var'
	local namestr " `namestr' "`lbz'" "\thinspace" "
	
local q= `f'+1
local part`f' "\enspace `lbz' &"
local part`q' "\thinspace &"
		
	*Average for treatment group
	sum `var'
	local control_mean: display %19.3f r(mean)
	local control_sd: display %19.3f r(sd)

	matrix table_mean[`f',1] =`control_mean'
	matrix table_mean[`f',2] =`control_sd'
	matrix table_mean[`f',3] =r(N)
	
	*Increase the counter of the row 
	loc f = `f' + 1

}

drop _all
svmat table_mean
g t0=""
	forval i=1/`totrow' {
		di "`part`i''"
		replace t0= "`part`i''" if _n==`i'
	}
	
forval var=1/2 {
		tostring table_mean`var', format("%9.3f") replace force
			replace table_mean`var'="" if table_mean`var'=="."
			replace table_mean`var'="0"+table_mean`var' if substr(table_mean`var',1,1)=="."
		
	}	
forval i=1/2 {
		replace table_mean`i'= table_mean`i'+"&"
	}
			tostring table_mean3, format("%9.0f") replace force
			replace table_mean3="" if table_mean3=="."
			replace table_mean3="0"+table_mean3 if substr(table_mean3,1,1)=="."

		replace table_mean3= table_mean3+"\\" if table_mean3!=""
		replace table_mean3= table_mean3+"& \\" if table_mean3==""	
	
set obs `=_N+2'		
	g index= _n
	replace index=0 if _n==_N-1
	sort index
order t0 table_mean1-table_mean3
keep t0-table_mean3
list, clean 	

#delimit ;
local fn "\emph{Notes}: Results from post-intervention health worker survey. Sample includes doctors, nurses, and health technicians. A health worker is coded as feeling pressure to prescribe if s/he answers yes to the question: Do you ever feel pressure from patients to prescribe certain medicines when you think they are not necessary? Doctors answering yes were then asked to specify which medications. Antimalarial also includes quinine; pain killer includes analgesic, anti inflammatory, and sedatative; antibiotic includes unspecified antibiotics and ciprofloxacin.";
local text0 "\begin{table}[h!] \begin{adjustbox}{max width=.85\textwidth} \begin{threeparttable} \caption{Health Worker Beliefs from Post-Intervention Survey} \label{means_doctor} { 
			\begin{tabular}{l*{4}{c}} \hline\hline & \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)}  \\
			& \multicolumn{1}{c}{\shortstack{Mean}} & \multicolumn{1}{c}{SD} & \multicolumn{1}{c}{N} \\ \hline";
local textlast "\hline \end{tabular} } \begin{tablenotes}[flushleft] \small 
		\item `fn' 
		\end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}";
#delimit cr	
	replace t0="`text0'" if _n==1
	replace t0="`textlast'" if _n==_N
*	replace t0=" & " if t1!="" & _n>=2 & _n<_N & t0==""

outfile t0-table_mean3 using "$tables/B2_means_doctor.tex", noquote replace wide	



```

### `Lopez_Sautmann_Schaner_2020/Do_Files/Tables/B5_table_selection.do`
```stata

* Selection

preserve
		
local namestr  `" "\it{A. Whole Sample}" "' 
	di `"`namestr'"'
	
	global varlist0_selection "in_home_survey has_valid_rdt_H"
	global varlist1_selection "has_valid_rdt_H"

la var in_home_survey "Took Home Survey"
la var has_valid_rdt_H "Took Home-Based RDT"


foreach var in $varlist0_selection $varlist1_selection {
	local repx ""
	if "`var'"!="nobs" & "`var'"!="bobs" local repx "replace `var'=. if dropme==1"
	`repx'
	}
	
* Varlists
	local v0= wordcount("$varlist0_selection")
	local v1= wordcount("$varlist1_selection")	
	

local totrow= 2*(`v0'+`v0'+`v1')+3
	matrix table_randomization=J(`totrow',8,.)
	matrix se= J(`totrow',1,.)

local part1 "\it{A. Whole Sample} &"
	
loc f = 2

foreach var in $varlist0_selection {

local lbz: variable label `var'
	local namestr " `namestr' "`lbz'" "\thinspace" "

local q= `f'+1
local part`f' "\enspace `lbz' &"
local part`q' "\thinspace &" 	

*Regressions
reg `var' patient_voucher doctor_voucher $date, clu($cluvar)
	local coeff_patient_voucher: display %19.3f _b[patient_voucher]
	local coeff_doctor_voucher:  display %19.3f _b[doctor_voucher]
	local se_patient_voucher: display %19.3f _se[patient_voucher]
	local se_doctor_voucher:  display %19.3f _se[doctor_voucher]
	
	matrix table_randomization[`f',2] =`coeff_patient_voucher'
	matrix table_randomization[`f',3] =`coeff_doctor_voucher'

	matrix table_randomization[`f'+1,2] =`se_patient_voucher'
	matrix table_randomization[`f'+1,3] =`se_doctor_voucher'

	matrix se[`f'+1,1]=1

	*P-value
	test patient_voucher==doctor_voucher
	local p_value1: display %7.3f `r(p)'
	matrix table_randomization[`f',4] =`p_value1'
	
	*P-value
	test patient_voucher==doctor_voucher==0
	local p_value2: display %7.3f `r(p)'
	matrix table_randomization[`f',5] =`p_value2'

	*Number of observations
	matrix table_randomization[`f',6] =e(N)
	
	*Average for treatment group
	sum `var' if doctor_voucher+patient_voucher==0 & e(sample)
	local control_mean: display %19.3f r(mean)
	local control_sd: display %19.3f r(sd)

	matrix table_randomization[`f',1] =`control_mean'
	matrix table_randomization[`f'+1,1] =`control_sd'
	
	*Increase the counter of the row 
	loc f = `f' + 2

}

local sustring ""
local sutest1 ""
local sutest2 ""

local part`f' "\it{B. Selected for Home Survey} &"
	
local f = `f'+1

local namestr " `namestr' "\it{B. Selected for Home Survey}" "

foreach var in $varlist0_selection {


local lbz: variable label `var'
	local namestr " `namestr' "`lbz'" "\thinspace" "
	
local q= `f'+1
local part`f' "\enspace `lbz' &"
local part`q' "\thinspace &"
	
*Regressions
reg `var'  patient_voucher doctor_voucher $date if selected_home_survey==1
	est store E`var'
	local sustring "`sustring' E`var'"
	local sutest2 "`sutest2' [E`var'_mean]patient_voucher=[E`var'_mean]doctor_voucher="
	local sutest1 "`sutest1' [E`var'_mean]patient_voucher=[E`var'_mean]doctor_voucher="
 reg `var' patient_voucher doctor_voucher $date if selected_home_survey==1, clu($cluvar)
	local coeff_patient_voucher: display %19.3f _b[patient_voucher]
	local coeff_doctor_voucher:  display %19.3f _b[doctor_voucher]
	local se_patient_voucher: display %19.3f _se[patient_voucher]
	local se_doctor_voucher:  display %19.3f _se[doctor_voucher]
	
	matrix table_randomization[`f',2] =`coeff_patient_voucher'
	matrix table_randomization[`f',3] =`coeff_doctor_voucher'

	matrix table_randomization[`f'+1,2] =`se_patient_voucher'
	matrix table_randomization[`f'+1,3] =`se_doctor_voucher'

	matrix se[`f'+1,1]=1

	*P-value
	test patient_voucher==doctor_voucher
	local p_value1: display %7.3f `r(p)'
	matrix table_randomization[`f',4] =`p_value1'
	
	*P-value
	test patient_voucher==doctor_voucher==0
	local p_value2: display %7.3f `r(p)'
	matrix table_randomization[`f',5] =`p_value2'

	*Number of observations
	matrix table_randomization[`f',6] =e(N)
	
	*Average for treatment group
	sum `var' if doctor_voucher+patient_voucher==0 & e(sample)
	local control_mean: display %19.3f r(mean)
	local control_sd: display %19.3f r(sd)

	matrix table_randomization[`f',1] =`control_mean'
	matrix table_randomization[`f'+1,1] =`control_sd'
	
	*Increase the counter of the row 
	loc f = `f' + 2

}
	
mat li table_randomization


****************************


local part`f' "\it{C. Took Home Survey} &"
	
local f = `f'+1

local namestr " `namestr' "\it{C. Took Home Survey}" "

foreach var in $varlist1_selection {


local lbz: variable label `var'
	local namestr " `namestr' "`lbz'" "\thinspace" "
	
local q= `f'+1
local part`f' "\enspace `lbz' &"
local part`q' "\thinspace &"
	
* REGRESSIONS
reg `var'  patient_voucher doctor_voucher $date if in_home_survey==1
	est store E`var'
	local sustring "`sustring' E`var'"
	local sutest2 "`sutest2' [E`var'_mean]patient_voucher=[E`var'_mean]doctor_voucher="
	local sutest1 "`sutest1' [E`var'_mean]patient_voucher=[E`var'_mean]doctor_voucher="
 reg `var' patient_voucher doctor_voucher $date if in_home_survey==1, clu($cluvar)
	local coeff_patient_voucher: display %19.3f _b[patient_voucher]
	local coeff_doctor_voucher:  display %19.3f _b[doctor_voucher]
	local se_patient_voucher: display %19.3f _se[patient_voucher]
	local se_doctor_voucher:  display %19.3f _se[doctor_voucher]
	
	matrix table_randomization[`f',2] =`coeff_patient_voucher'
	matrix table_randomization[`f',3] =`coeff_doctor_voucher'

	matrix table_randomization[`f'+1,2] =`se_patient_voucher'
	matrix table_randomization[`f'+1,3] =`se_doctor_voucher'

	matrix se[`f'+1,1]=1

	*P-value
	test patient_voucher==doctor_voucher
	local p_value1: display %7.3f `r(p)'
	matrix table_randomization[`f',4] =`p_value1'
	
	*P-value
	test patient_voucher==doctor_voucher==0
	local p_value2: display %7.3f `r(p)'
	matrix table_randomization[`f',5] =`p_value2'

	*Number of observations
	matrix table_randomization[`f',6] =e(N)
	
	*Average for treatment group
	sum `var' if doctor_voucher+patient_voucher==0 & e(sample)
	local control_mean: display %19.3f r(mean)
	local control_sd: display %19.3f r(sd)

	matrix table_randomization[`f',1] =`control_mean'
	matrix table_randomization[`f'+1,1] =`control_sd'
	
	*Increase the counter of the row 
	loc f = `f' + 2
	
}

local sutest1 "`sutest1' [Egender_mean]patient_voucher"
local sutest2 "`sutest2' 0"
	
local df= e(df_r)
		
mat li table_randomization
matrix rownames table_randomization= `namestr'

local bc = rowsof(table_randomization)

matrix stars = J(`bc',6,0)

	local end0= `v0'*2
	local start1= `end0'+3
	local end1= `start1' + `v1'*2
	local start2= `end1'+3
	local end2= `totrow'-1
	
forvalues i=4(1)5{

forvalues k = 2(2)`end0' {

	if table_randomization[`k',`i']<=.01{
	local star "1"
	}
	if table_randomization[`k',`i']>.01 & table_randomization[`k',`i']<=.05{
	local star "2"
	}
	if table_randomization[`k',`i']>.05 & table_randomization[`k',`i']<=.10{
	local star "3"
	}
	if table_randomization[`k',`i']>.10{
	local star "0"
	}
	di
    matrix stars[`k',`i'] = `star'
}

forvalues k = `start1'(2)`end1' {

	if table_randomization[`k',`i']<=.01{
	local star "1"
	}
	if table_randomization[`k',`i']>.01 & table_randomization[`k',`i']<=.05{
	local star "2"
	}
	if table_randomization[`k',`i']>.05 & table_randomization[`k',`i']<=.10{
	local star "3"
	}
	if table_randomization[`k',`i']>.10 {
	local star "0"
	}
	di
    matrix stars[`k',`i'] = `star'
}

forvalues k = `start2'(2)`end2' {

	if table_randomization[`k',`i']<=.01{
	local star "1"
	}
	if table_randomization[`k',`i']>.01 & table_randomization[`k',`i']<=.05{
	local star "2"
	}
	if table_randomization[`k',`i']>.05 & table_randomization[`k',`i']<=.10{
	local star "3"
	}
	if table_randomization[`k',`i']>.10 {
	local star "0"
	}
	di
    matrix stars[`k',`i'] = `star'
}
}

// use critical values from t-distribution, just as is done in regressions
local cv10= abs(invt(`df',.05))
local cv5= abs(invt(`df',.025))
local cv1= abs(invt(`df',.005))
	
forvalues i=2(1)3{

	forvalues k = 2(2)`end0' {

		local ttest=abs(table_randomization[`k',`i']/table_randomization[`k'+1,`i'])
		if `ttest'<`cv10' {
		local star "0"
		}
		if `ttest'>=`cv10' & `ttest'<`cv5' {
		local star "3"
		}
		if `ttest'>=`cv5' & `ttest'<`cv1' {
		local star "2"
		}
		if `ttest'>=`cv1' & `ttest'!=. {
		local star "1"
		}
		di
		matrix stars[`k',`i'] = `star'
	}

	forvalues k = `start1'(2)`end1' {

		local ttest=abs(table_randomization[`k',`i']/table_randomization[`k'+1,`i'])
		if `ttest'<`cv10' {
		local star "0"
		}
		if `ttest'>=`cv10' & `ttest'<`cv5' {
		local star "3"
		}
		if `ttest'>=`cv5' & `ttest'<`cv1' {
		local star "2"
		}
		if `ttest'>=`cv1' & `ttest'!=. {
		local star "1"
		}
		di
		matrix stars[`k',`i'] = `star'	
		
		}	
	forvalues k = `start2'(2)`end2' {

		local ttest=abs(table_randomization[`k',`i']/table_randomization[`k'+1,`i'])
		if `ttest'<`cv10' {
		local star "0"
		}
		if `ttest'>=`cv10' & `ttest'<`cv5' {
		local star "3"
		}
		if `ttest'>=`cv5' & `ttest'<`cv1' {
		local star "2"
		}
		if `ttest'>=`cv1' {
		local star "1"
		}
		di
		matrix stars[`k',`i'] = `star'	
		
		}

}

drop _all
svmat table_randomization
svmat stars
svmat se
g t0=""
	forval i=1/`totrow' {
		di "`part`i''"
		replace t0= "`part`i''" if _n==`i'
	}
	
forval var=1/5 {
		tostring table_randomization`var', format("%9.3f") replace force
			replace table_randomization`var'="" if table_randomization`var'=="."
			replace table_randomization`var'="0"+table_randomization`var' if substr(table_randomization`var',1,1)=="."
		replace table_randomization`var'= table_randomization`var'+"\sym{*}" if stars`var'==3
		replace table_randomization`var'= table_randomization`var'+"\sym{**}" if stars`var'==2
		replace table_randomization`var'= table_randomization`var'+"\sym{***}" if stars`var'==1
		
	}
replace table_randomization1= "["+table_randomization1+"]" if se1==1

forval i=2/3 {
		replace table_randomization`i'="("+table_randomization`i'+")" if se1==1
	}

forval i=1/5 {
		replace table_randomization`i'= table_randomization`i'+"&"
	}
		tostring table_randomization6, format("%9.0f") replace force
		replace table_randomization6="" if table_randomization6=="."
		replace table_randomization6="0"+table_randomization6 if substr(table_randomization6,1,1)=="."


		replace table_randomization6= table_randomization6+"\\" if table_randomization6!=""
		replace table_randomization6= table_randomization6+"& \\" if table_randomization6==""	
		
set obs `=_N+2'		
	g index= _n
	replace index=0 if _n==_N-1
	sort index
order t0 table_randomization1-table_randomization8
keep t0-table_randomization8 
list, clean 

#delimit ;
local fn "$footnote0_alt $footnote1";
local text0 "\begin{table}[h!] \begin{adjustbox}{max width=1\textwidth} \begin{threeparttable} \caption{Selection into Analysis Samples by Treatment} \label{selection} { 
			\begin{tabular}{l*{7}{c}} \hline\hline & \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)}  \\
			&  &  \multicolumn{2}{c}{Regression Coefficients} & \multicolumn{2}{c}{P-Values} &  \\ 
			\cmidrule(lr){3-4} \cmidrule(lr){5-6}  & 
				\multicolumn{1}{c}{\shortstack{Control\\Mean}} & \multicolumn{1}{c}{\shortstack{Patient\\Voucher}} & \multicolumn{1}{c}{\shortstack{Doctor\\ Voucher}}  & 
				\multicolumn{1}{c}{\shortstack{Joint Test\\ PV=DV}} & \multicolumn{1}{c}{\shortstack{Joint Test \\ PV=DV=0}} & \multicolumn{1}{c}{N} \\ \hline";
local textlast "\hline \end{tabular} } \begin{tablenotes}[flushleft] \small 
		\item `fn' 
		\end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}";
#delimit cr	
	replace t0="`text0'" if _n==1
	replace t0="`textlast'" if _n==_N
*	replace t0=" & " if t1!="" & _n>=2 & _n<_N & t0==""

outfile t0-table_randomization6 using "$tables/B5_selection.tex", noquote replace wide		

restore

```

### `Lopez_Sautmann_Schaner_2020/Do_Files/Tables/B6_table_diff_test_consent.do`
```stata

preserve
		
local namestr  `" "\it{A. Patient Characteristics}" "' 
	di `"`namestr'"'

	
local varlist1a= subinstr("$varlist1", "RDTresult_POS", "",.)
	local varlist1a= "`varlist1a' treat_sev_simple_mal"
local varlist2= "$varlist2"
local varlist3= "$varlist3"

la var digestiveproblemsintake "Digestive Problems"
la var poorappetiteintake "Poor Appetite"
la var genderpatient "Male (Patient)"
la var breathingintake "Difficulty Breathing"
la var readwrite_fluent_french "Literate (in French)"
la var gender "Male"
la var islamicschool "Islamic School"
la var ltmiddleschool "Primary School"
la var middleschool "Middle School"
la var ethnic_bambara "Bambara"
la var took_meds_before "Meds Before Visit"
la var thinks_malaria "Suspects Malaria"
la var roomshousehold "Rooms in Home"
la var members14oryounger_H "HH Members Under 15"
la var members15orolder_H "HH Members 15 or Older"
la var membersjob_H "HH Members Working"
la var totalincome_H "Total HH Income" 
la var mosquitonets_H "Number Mosquito Nets"
la var rent_value_H "Rental Value of Home"
la var symptomsscreening_4 "Poor Appetite"
la var symptomsscreening_7 "Weakness/Fatigue"
la var agepatient "Age"
la var age "Age"
la var total_hh_members_H "Household Size"
la var pred_mal_pos "Predicted Malaria Probability"
la var treat_sev_simple_mal "Purchased Malaria Treatment"
la var speak_french "Speaks French"
la var prischoolorless "Primary School or Less"

g nordt= 1 - rdt_H
	replace nordt=0 if nordt==.
	
foreach var in total_hh_members_H HH_frac_14 HH_frac_job income_percap_H rent_value_H HH_frac_nets {
	local lbz: variable label `var'
	local lbz "`lbz'$^+$"
		la var `var' "`lbz'"
	}
	
foreach var in `varlist1a' `varlist2' {
	local repx ""
	if "`var'"!="nobs" & "`var'"!="bobs" local repx "replace `var'=. if dropme==1"
	`repx'
	}
	
* Varlists
	local v1= wordcount("`varlist1a'")	
	local v2= wordcount("`varlist2'")
	

local totrow= 2*(`v1'+`v2')+4
	matrix table_randomization=J(`totrow',9,.)
	matrix se= J(`totrow',9,.)

local part1 "\it{A. Patient Characteristics} &"
	
loc f = 2

foreach var in `varlist1a' {

cap replace `var'=. if MSS`var'==1

local lbz: variable label `var'
	local namestr " `namestr' "`lbz'" "\thinspace" "

local q= `f'+1
local part`f' "\enspace `lbz' &"
local part`q' "\thinspace &" 	

*Regressions

* first: selected vs. not for home survey
reg `var' selected_home_survey, clu($cluvar)
	local coeff_home: 	 display %7.3f _b[selected_home_survey]
	local se_home: 	     display %7.3f _se[selected_home_survey]
	
	matrix table_randomization[`f',2] =`coeff_home'
	matrix table_randomization[`f'+1,2] =`se_home'
	matrix table_randomization[`f',3] =e(N)
	matrix se[`f'+1,1]=1

	*Average for not selected
	sum `var' if selected_home_survey==0 & e(sample)
	local control_mean: display %7.3f r(mean)
	local control_sd: display %7.3f r(sd)

	matrix table_randomization[`f',1] =`control_mean'
	matrix table_randomization[`f'+1,1] =`control_sd'
	local ct=r(N)
	foreach j in 1 2 3 {
	local do1 ""
	local do2 ""
	if `ct'==0 {
		local do1= "mat table_randomization[`f',`j']=."
		local do2= "mat table_randomization[`f'+1,`j']=."
		}
		`do1'
		`do2'
		}
* second: interviewed vs. not for home survey
reg `var' in_home_survey if selected_home_survey==1, clu($cluvar)
	local coeff_home: 	 display %7.3f _b[in_home_survey]
	local se_home: 	     display %7.3f _se[in_home_survey]
	
	matrix table_randomization[`f',5] =`coeff_home'
	matrix table_randomization[`f'+1,5] =`se_home'
	matrix table_randomization[`f',6] =e(N)
	matrix se[`f'+1,1]=1

	*Average for not in home survey 
	sum `var' if in_home_survey==0 & e(sample) & selected_home_survey==1
	local control_mean: display %7.3f r(mean)
	local control_sd: display %7.3f r(sd)

	matrix table_randomization[`f',4] =`control_mean'
	matrix table_randomization[`f'+1,4] =`control_sd'
	local ct=r(N)
	foreach j in 4 5 6 {
	local do1 ""
	local do2 ""
	if `ct'==0 {
		local do1= "mat table_randomization[`f',`j']=."
		local do2= "mat table_randomization[`f'+1,`j']=."
		}
		`do1'
		`do2'
		}
* third: took RDT vs. not for home survey		
reg `var' nordt if in_home_survey==1, clu($cluvar)
	local coeff_test: 	 display %7.3f _b[nordt]
	local se_test: 	     display %7.3f _se[nordt]
	
	matrix table_randomization[`f',8] =`coeff_test'
	matrix table_randomization[`f'+1,8] =`se_test'
	matrix table_randomization[`f',9] =e(N)
	matrix se[`f'+1,1]=1
	
	*Average for consenters 
	sum `var' if nordt==0 & e(sample)
	local control_mean2: display %7.3f r(mean)
	local control_sd2: display %7.3f r(sd)

	matrix table_randomization[`f',7] =`control_mean2'
	matrix table_randomization[`f'+1,7] =`control_sd2'
	
	*Increase the counter of the row 
	loc f = `f' + 2

}

local sustring ""
local sutest1 ""
local sutest2 ""

local part`f' "\it{B. Household Characteristics} &"
	
local f = `f'+1

local namestr " `namestr' "\it{B. Household Characteristics}" "

foreach var of local varlist2 {

cap replace `var'=. if MSS`var'==1

local lbz: variable label `var'
	local namestr " `namestr' "`lbz'" "\thinspace" "
	
local q= `f'+1
local part`f' "\enspace `lbz' &"
local part`q' "\thinspace &"
	

*Regressions
* first: selected vs. not for home survey
reg `var' selected_home_survey, clu($cluvar)
	local coeff_home: 	 display %7.3f _b[selected_home_survey]
	local se_home: 	     display %7.3f _se[selected_home_survey]
	
	matrix table_randomization[`f',2] =`coeff_home'
	matrix table_randomization[`f'+1,2] =`se_home'
	matrix table_randomization[`f',3] =e(N)
	matrix se[`f'+1,1]=1

	*Average for not selected
	sum `var' if selected_home_survey==0 & e(sample)
	local control_mean: display %7.3f r(mean)
	local control_sd: display %7.3f r(sd)

	matrix table_randomization[`f',1] =`control_mean'
	matrix table_randomization[`f'+1,1] =`control_sd'
	local ct=r(N)
		di `ct'
		
		
	foreach j in 1 2 3 {
	local do1 ""
	local do2 ""
	if `ct'==0 {
		local do1= "mat table_randomization[`f',`j']=."
		local do2= "mat table_randomization[`f'+1,`j']=."
		}
		`do1'
		`do2'
		}
		
reg `var' in_home_survey if selected_home_survey==1, clu($cluvar)
	local coeff_home: 	 display %7.3f _b[in_home_survey]
	local se_home: 	     display %7.3f _se[in_home_survey]
	
	matrix table_randomization[`f',5] =`coeff_home'
	matrix table_randomization[`f'+1,5] =`se_home'
	matrix table_randomization[`f',6] =e(N)
	matrix se[`f'+1,1]=1

	*Average for not in home survey 
	sum `var' if in_home_survey==0 & e(sample) & selected_home_survey==1
	local control_mean: display %7.3f r(mean)
	local control_sd: display %7.3f r(sd)

	matrix table_randomization[`f',4] =`control_mean'
	matrix table_randomization[`f'+1,4] =`control_sd'
	local ct=r(N)
		di `ct'
		
		
	foreach j in 4 5 6	 {
	local do1 ""
	local do2 ""
	if `ct'==0 {
		local do1= "mat table_randomization[`f',`j']=."
		local do2= "mat table_randomization[`f'+1,`j']=."
		}
		`do1'
		`do2'
		}
		
reg `var' nordt if in_home_survey==1, clu($cluvar)
	local coeff_test: 	 display %7.3f _b[nordt]
	local se_test: 	     display %7.3f _se[nordt]
	
	matrix table_randomization[`f',8] =`coeff_test'
	matrix table_randomization[`f'+1,8] =`se_test'
	matrix table_randomization[`f',9] =e(N)
	matrix se[`f'+1,1]=1
	
	*Average for consenters 
	sum `var' if nordt==0 & e(sample)
	local control_mean2: display %7.3f r(mean)
	local control_sd2: display %7.3f r(sd)

	matrix table_randomization[`f',7] =`control_mean2'
	matrix table_randomization[`f'+1,7] =`control_sd2'
	
	*Increase the counter of the row 
	loc f = `f' + 2
	
}
	

local df= e(df_r)
		
mat li table_randomization
matrix rownames table_randomization= `namestr'

local bc = rowsof(table_randomization)

matrix stars = J(`bc',9,0)

	local end1= `v1'*2
	local start2= `end1'+3
	*CL: there was a mistake here, we didn't put * in Panel B (Isabelle's comments)
	local end2= `start2' + `v2'*2-2 
		
		
	di `end1'
	di `start2'
	di `end2'
	

	
// use critical values from t-distribution, just as is done in regressions
local cv10= abs(invt(`df',.05))
local cv5= abs(invt(`df',.025))
local cv1= abs(invt(`df',.005))
	
foreach i in 2 5 8 {

	forvalues k = 2(2)`end1' {

		local ttest=abs(table_randomization[`k',`i']/table_randomization[`k'+1,`i'])
		if `ttest'<`cv10' {
		local star "0"
		}
		if `ttest'>=`cv10' & `ttest'<`cv5' {
		local star "3"
		}
		if `ttest'>=`cv5' & `ttest'<`cv1' {
		local star "2"
		}
		if `ttest'>=`cv1' & `ttest'!=. {
		local star "1"
		}
		di
		matrix stars[`k',`i'] = `star'
	}

	forvalues k = `start2'(2)`end2' {

		local ttest=abs(table_randomization[`k',`i']/table_randomization[`k'+1,`i'])
		if `ttest'<`cv10' {
		local star "0"
		}
		if `ttest'>=`cv10' & `ttest'<`cv5' {
		local star "3"
		}
		if `ttest'>=`cv5' & `ttest'<`cv1' {
		local star "2"
		}
		if `ttest'>=`cv1' & `ttest'!=. {
		local star "1"
		}
		di
		matrix stars[`k',`i'] = `star'	
		
		}	

}

drop _all
svmat table_randomization

list


svmat stars
svmat se
g t0=""
	forval i=1/`totrow' {
		di "`part`i''"
		replace t0= "`part`i''" if _n==`i'
	}
	
foreach var in 1 2 4 5 7 8 {
		tostring table_randomization`var', format("%9.3f") replace force
			replace table_randomization`var'="" if table_randomization`var'=="."
			replace table_randomization`var'="0"+table_randomization`var' if substr(table_randomization`var',1,1)=="."
		replace table_randomization`var'= table_randomization`var'+"\sym{*}" if stars`var'==3
		replace table_randomization`var'= table_randomization`var'+"\sym{**}" if stars`var'==2
		replace table_randomization`var'= table_randomization`var'+"\sym{***}" if stars`var'==1
		
	}
	
foreach var in 3 6 9{
		tostring table_randomization`var', format("%9.0f") replace force
			replace table_randomization`var'="" if table_randomization`var'=="."
			replace table_randomization`var'="0"+table_randomization`var' if substr(table_randomization`var',1,1)=="."
		replace table_randomization`var'= table_randomization`var'+"\sym{*}" if stars`var'==3
		replace table_randomization`var'= table_randomization`var'+"\sym{**}" if stars`var'==2
		replace table_randomization`var'= table_randomization`var'+"\sym{***}" if stars`var'==1
		
	}	
	
foreach i in 1 4 7 {
	replace table_randomization`i'= "["+table_randomization`i'+"]" if se1==1 | se4==1 | se7==1
	}
	
foreach i in 2 5 8 {
		replace table_randomization`i'="("+table_randomization`i'+")" if se1==1
	}

forval i=1/8 {
		replace table_randomization`i'= table_randomization`i'+"&"
	}
		replace table_randomization9= table_randomization9+"\\" if table_randomization9!=""
		replace table_randomization9= table_randomization9+"& \\" if table_randomization9==""	
foreach i in 1 2 4 5 {
		replace table_randomization`i'="&" if table_randomization`i'=="[]&" | table_randomization`i'=="()&"
		}
set obs `=_N+2'		
	g index= _n
	replace index=0 if _n==_N-1
	sort index
order t0 table_randomization1-table_randomization9
keep t0-table_randomization9
list, clean 

#delimit ;
local fn "\emph{Notes}: Robust standard errors clustered at the clinic level in parentheses. $^+$ indicates that variable was recorded in the home survey only. Variables measured in CFA and duration of illness top-coded at the 99th percentile. CFA610 $\approx$ USD1. $footnote1";
local text0 "\begin{table}[h!] \begin{adjustbox}{max width=.91\textwidth} \begin{threeparttable} \caption{Selection Into Home Survey and RDT Consent} \label{diff_test_consent} { 
			\begin{tabular}{l*{10}{c}} \hline\hline & \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)}  & \multicolumn{1}{c}{(7)} & \multicolumn{1}{c}{(8)}  & \multicolumn{1}{c}{(9)} \\
			&   \multicolumn{3}{c}{Whole Sample} &  \multicolumn{3}{c}{Selected Home Survey} & \multicolumn{3}{c}{Took Home Survey}  \\ 
			\cmidrule(lr){2-4} \cmidrule(lr){5-7} \cmidrule(lr){8-10}  & 
				\multicolumn{1}{c}{\shortstack{Mean:\\Not \\ Selected}} & \multicolumn{1}{c}{\shortstack{Diff: \\ Selected }} & \multicolumn{1}{c}{\shortstack{N}} &
				\multicolumn{1}{c}{\shortstack{Mean:\\Survey Not \\ Taken}} & \multicolumn{1}{c}{\shortstack{Diff: \\ Took \\ Survey }} & \multicolumn{1}{c}{\shortstack{N}} &
				\multicolumn{1}{c}{\shortstack{Mean:\\ Took \\ RDT}} & \multicolumn{1}{c}{\shortstack{Diff: \\ Refused \\ RDT}} & 
				\multicolumn{1}{c}{\shortstack{N}} \\ \hline";
local textlast "\hline \end{tabular} } \begin{tablenotes}[flushleft] \small 
		\item `fn' 
		\end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}";
#delimit cr	
	replace t0="`text0'" if _n==1
	replace t0="`textlast'" if _n==_N
		drop if _n==_N-1 | _n==_N-2
list t0-table_randomization9
outfile t0-table_randomization9 using "$tables/B6_diff_test_consent.tex", noquote replace wide		


restore

```

### `Lopez_Sautmann_Schaner_2020/Do_Files/Tables/B7_table_mal_prob_probit.do`
```stata

* Predicting RDT w/ observables

	la var symptomsscreening_2 "Chills or Excessive Sweating"
	la var symptomsscreening_3 "Nausea, Vomiting, or Diarrhea"
	la var symptomsscreening_4 "Reduced Appetite"
	la var symptomsscreening_7 "Weakness, Fatigue, or Reduced Consciousness"
	la var genderpatient "Patient is Male"
	la var speak_french "Speaks French (Resp.)"
	la var readwrite_fluent_french "Literate in French (Resp.)"
	la var prischoolorless "Primary School or Less (Resp.)"
	la var respondent "Patient Answered CSCom Survey"
	la var  daysillness99 "Duration of Illness in Days"
	la var pregnancy "Patient is Pregnant"
	la var speak_french "Respondent Speaks French"
	la var readwrite_fluent_french "Respondent is Literate in French"
	la var prischoolorless "Respondent Has Primary Education or Less"
	la var respondent "Patient Answered Clinic Survey"
	

global predcont "symptomsscreening_1 symptomsscreening_2 symptomsscreening_3 symptomsscreening_4 symptomsscreening_5 symptomsscreening_6 symptomsscreening_7  daysillness99 agepatient under5 u5_age genderpatient pregnancy ethnic_bambara speak_french readwrite_fluent_french prischoolorless respondent" 
global useme ""
	foreach var in $predcont {
		cap g MSS`var'= `var'==.
		cap	replace `var'=0 if `var'==.
		global useme "$useme `var' MSS`var'"
		}	
	g varx= RDTresult_POS
	la var varx "\textcolor{white}{X}"
probit varx  $useme if dropme==0, cluster(cscomnum) asis
drop pred_mal_pos
	predict pred_mal_pos if dropme==0, p	
	estadd scalar addme= `e(r2_p)'
	
esttab using "$tables/B7_mal_prob_probit.tex", label noabbrev nogaps noline nodep nomtit nonum replace keep($predcont) stats(addme N, label("Pseudo R-Squared" "N") fmt(3 0)) se nonote tex /// 
	star(* .1 ** .05 *** .01) prehead(\begin{table}[h!] \begin{adjustbox}{max width=.65\textwidth} \begin{threeparttable} \caption{Predicting RDT Positivity With Observables} \label{malprobprobit} {\begin{tabular}{l*{2}{C{0.15\linewidth}}} \toprule \toprule & (1) \\ & RDT Positive \\ \hline)  /// 
	postfoot(\hline \end{tabular} } \begin{tablenotes}[flushleft] \small \item \emph{Notes}: Robust standard errors clustered at the clinic level in parentheses. Respondent refers to individual who answered clinic survey. ***, **, and * indicate significance at the 1, 5, and 10 percent significance levels respectively. \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}) 	
	drop varx

```

### `Lopez_Sautmann_Schaner_2020/Do_Files/Figures/3_graph_outcomeXpredpos_control.do`
```stata
preserve

// patterns in no voucher group only
keep if doctor_voucher + patient_voucher ==0

// no treatment (RX, taken)
g RXnone= 1 - RXtreat_sev_simple_mal
g none=   1 - treat_sev_simple_mal

// percentiles of predicted pos
g predicted_RDT_POS= pred_mal_pos
_pctile predicted_RDT_POS, p(2.5 97.5)
local bottom=r(r1)
local top=r(r2)
_pctile predicted_RDT_POS, p(25 50 75)
	local p25= r(r1)
	local p50= r(r2)
	local p75= r(r3)
	
// make local linear graphs and trim tails
local varlist "RXnone RXtreat_simple_mal RXtreat_severe_mal none treat_simple_mal treat_severe_mal"

foreach out of local varlist{
local ytit "Local Average"	
local tit: variable label `out'

* all
	lpoly `out' predicted_RDT_POS , deg(1) gen(x_`out' y_`out') se(se_`out') nodraw
		replace y_`out'=. if x_`out'>`top' | x_`out'<`bottom'
		replace x_`out'=. if x_`out'>`top' | x_`out'<`bottom'
		g ul_`out'= y_`out'+1.645*se_`out'
		g ll_`out'= y_`out'-1.645*se_`out'
			
		}


// compile final graph panel by panel

foreach lead in "" {
	line `lead'y_RXnone `lead'y_none `lead'x_none, legend(label(1 "No Treat. Prescribed") label(2 "No Treat. Purchased") size(small) row(1)) xtit("Predicted Malaria Risk", size(medium)) ytit("Share Patients", size(medium)) ///
		graphregion(color(white)) tit("A. No Malaria Treatment", size(medsmall)) lcol(black gs10) lwid(medthick medthick) lpat(solid longdash) name(`lead'PA, replace) ylab(0(.2).8) xline(`p25', lcol(gs7) lpat(dot)) xline(`p50', lcol(gs7) lpat(dot)) xline(`p75', lcol(gs7) lpat(dot))	nodraw
	line `lead'y_RXtreat_simple_mal `lead'y_treat_simple_mal  `lead'x_treat_simple_mal, legend(label(1 "Treatment Prescribed") label(2 "Treatment Purchased") size(small) row(1)) xtit("Predicted Malaria Risk", size(medium)) ytit("Share Patients", size(medium)) ///
		graphregion(color(white)) tit("B. Simple Malaria Treatment", size(medsmall)) lcol(black gs10) lwid(medthick medthick) lpat(solid longdash) name(`lead'PB, replace) ylab(0(.2).8)  xline(`p25', lcol(gs7) lpat(dot)) xline(`p50', lcol(gs7) lpat(dot)) xline(`p75', lcol(gs7) lpat(dot))	nodraw
	line `lead'y_RXtreat_severe_mal `lead'y_treat_severe_mal  `lead'x_treat_severe_mal, legend(label(1 "Treatment Prescribed") label(2 "Treatment Purchased") size(small) row(1)) xtit("Predicted Malaria Risk", size(medium)) ytit("Share Patients", size(medium)) ///
		graphregion(color(white)) tit("C. Severe Malaria Treatment", size(medsmall)) lcol(black gs10) lwid(medthick medthick) lpat(solid longdash) name(`lead'PC, replace) ylab(0(.2).8)  xline(`p25', lcol(gs7) lpat(dot)) xline(`p50', lcol(gs7) lpat(dot)) xline(`p75', lcol(gs7) lpat(dot))	nodraw	
	}
	
graph combine PA PB PC, row(1) graphregion(color(white)) name(final, replace) xsize(12) ysize(4)	

// save output
graph export "$graphs/3_outcomeXpredpos_control.pdf", replace

restore

```

### `Lopez_Sautmann_Schaner_2020/Do_Files/Figures/4_graph_tmtXpredpos.do`
```stata

local reps= 1000

keep if dropme==0

// percentiles of predicted pos
_pctile pred_mal_pos, p(2.5 97.5)
	local bottom=r(r1)
	local top=r(r2)
_pctile pred_mal_pos, p(25 50 75)
	local p25= r(r1)
	local p50= r(r2)
	local p75= r(r3)
	
la var used_vouchers_admin "A. Used Voucher"
la var treat_sev_simple_mal "B. Purchase Any Malaria Treatment"
la var treat_severe_mal "C. Purchase Severe Malaria Treatment" 

mat xgrid= J(50,1,.)

local interval= (`top' - `bottom')/50
	local qq=1
	forval i=`bottom'(`interval')`top' {
		mat xgrid[`qq',1]= `i'
		local ++qq
		}
		
svmat xgrid

// make local linear graphs and trim tails
local varlist "used_vouchers_admin treat_sev_simple_mal treat_severe_mal" 
	foreach out of local varlist {

	lpoly `out' pred_mal_pos if patient_voucher==1, deg(1) gen(Py_`out') at(xgrid) nodraw
		mkmat Py_`out' if xgrid!=., mat(q)
		mat RP`out'= q

	lpoly `out' pred_mal_pos if doctor_voucher==1, deg(1) gen(Dy_`out') at(xgrid) nodraw
		mkmat Dy_`out' if xgrid!=., mat(q)
		mat RD`out'= q	
		}
		
* REPLICATIONS
local k=1
	while `k'<=`reps' {
		
drop _all
use "$data_final/_bootstrap/bs_cluCSCOM_`k'"

keep if dropme==0
		
svmat xgrid

// make local linear graphs and trim tails
local varlist "used_vouchers_admin treat_sev_simple_mal treat_severe_mal" 
	foreach out of local varlist {
	lpoly `out' pred_mal_pos if patient_voucher==1, deg(1) gen(Py_`out') at(xgrid) nodraw
		mkmat Py_`out' if xgrid!=., mat(q)
		mat RP`out'= RP`out',q
	lpoly `out' pred_mal_pos if doctor_voucher==1, deg(1) gen(Dy_`out') at(xgrid) nodraw
		mkmat Dy_`out' if xgrid!=., mat(q)
		mat RD`out'= RD`out',q	
		}
di `k'
local ++k
}

* CALCULATE CONFIDENCE INTERVALS
local varlist "used_vouchers_admin treat_sev_simple_mal treat_severe_mal" 
foreach out of local varlist {
	foreach let in P D {
		mat ul= R`let'`out'[.,2...]'
		mat ll= ul
		mat pe= ul
			drop _all
			svmat ul
			svmat ll
			svmat pe
			collapse (p5) ll* (p95) ul* (sd) pe*
				mkmat ll1-ll50, mat(ll2)
				mkmat ul1-ul50, mat(ul2)
				mkmat pe1-pe50, mat(pe)
					mat ul2= ul2'
					mat ll2= ll2'
					mat pe= pe'
					mat useme= R`let'`out'[1..50,1]
	 mat F`let'`out'= xgrid,useme,ul2,ll2,pe 
	}
	
	* make the final graphs!
	drop _all 
	if "`out'"=="used_vouchers_admin" local tit_`out' "Used Voucher"
	if "`out'"=="treat_sev_simple_mal" local tit_`out' "Purchased Any Malaria Treatment"
	if "`out'"=="treat_severe_mal" local tit_`out' "Purchased Severe Malaria Treatment"
		foreach let in D P {
			svmat F`let'`out'
			g ul`let'= F`let'`out'2 + 1.645*F`let'`out'5
			g ll`let'= F`let'`out'2 - 1.645*F`let'`out'5			
			}

	* this version bootstraps the SEs	
	twoway line ulD llD FD`out'2 ulP llP FP`out'2 FD`out'1, lcol(black black black gs12 gs12 gs12) lpat(dot dot solid dot dot solid) ///
		graphregion(color(white)) legend(order(3 6) label(3 "Doctor Voucher") label(6 "Patient Voucher") size(medium) row(1)) ///
		ytit("Share Patients", size(medlarge)) ylab(0(.2).9) xtit("Predicted Malaria Risk", size(medlarge)) ///
		tit("`tit_`out''", size(large)) name(`out', replace)  /// 
		xline(`p25', lcol(gs12) lpat(dash)) xline(`p50', lcol(gs12) lpat(dash)) xline(`p75', lcol(gs12) lpat(dash))
				
	}
	

* GRAPH
grc1leg used_vouchers_admin treat_sev_simple_mal treat_severe_mal, row(1) graphregion(color(white))	name(final, replace)
gr dis final, xsize(10) ysize(4)	

graph export "$graphs/4_tmtXpredpos.pdf", replace


	

```

### `Lopez_Sautmann_Schaner_2020/Do_Files/Figures/5_graph_voucher_tmt.do`
```stata
* STACKED BAR CHARTS

preserve

cap drop malgroup

local quant=4
xtile malgroup= pred_mal_pos, nq(`quant')
	la define malgroup 1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4"
	la val malgroup malgroup

g treatgroup=1 if patient_voucher+doctor_voucher==0
			replace treatgroup=2 if patient_voucher
			replace treatgroup=3 if doctor_voucher
la define treatgroup 1 "Control" 2 "Patient Voucher" 3 "Doctor Voucher"
	la val treatgroup treatgroup
	
* TREATMENT FOR SEVERE MALARIA
gr bar treat_severe_mal_NOvoucher treat_severe_mal_voucher , over(treatgroup, label(labsize(medlarge))) stack graphregion(color(white)) legend(label(1 "No Voucher Used") label(2 "Voucher Used") size(medium)) bar(1, color(gs9)) bar(2, color(gs12)) tit("B. Severe Malaria Treatment", size(medium)) ytit("Share Patients", size(medlarge)) graphregion(color(white)) name(PB, replace) 	

* TREATMENT FOR SIMPLE MALARIA
gr bar treat_simple_mal_NOvoucher treat_simple_mal_voucher , over(treatgroup, label(labsize(medlarge))) stack graphregion(color(white)) legend(label(1 "No Voucher Used") label(2 "Voucher Used") size(medium)) bar(1, color(gs9)) bar(2, color(gs12)) tit("A. Simple Malaria Treatment", size(medium)) ytit("Share Patients", size(medlarge)) graphregion(color(white)) name(PA, replace) 	
	
grc1leg PA PB, row(1) graphregion(color(white)) name(final, replace) ycommon
gr dis final, xsize(8) ysize(3)	

// save output
graph export "$graphs/5_voucher_tmt.pdf", replace
	
restore

```

### `Lopez_Sautmann_Schaner_2020/Do_Files/Figures/B1_graph_misallocation.do`
```stata
* Misallocation

	la var RXexpected_mal_match_any "Overall Match"
	la var expected_mal_match_any "Overall Match"	
g RXexpected_mal_match_anyX= RXexpected_mal_match_any if RXmatch_treat_RDT!=.
g expected_mal_match_anyX= expected_mal_match_any if RXmatch_treat_RDT!=.
	la var expected_mal_match_any_pos "Malaria Positive"
	la var RXexpected_mal_match_any_pos "Malaria Positive"
	la var expected_mal_match_any_neg "Malaria Negative"
	la var RXexpected_mal_match_any_neg "Malaria Negative"
	la var RXexpected_mal_match_anyX "Prescribed"
	la var expected_mal_match_anyX "Purchased"
	la var RXmatch_treat_RDT "Prescribed"
	la var match_treat_RDT "Purchased"	
	
g match_treat_RDT_pos= match_treat_RDT*RDTresult_POS
g match_treat_RDT_neg= match_treat_RDT*RDTresult_NEG

g testtype= reported_RDT + 2*reported_GE_FS
	replace testtype=. if reported_Malaria_test==1 & testtype==0
	la define testtype 0 "No Malaria Test" 1 "RDT Only" 2 "Microscope Only" 3 "RDT+Microscope"
	la val testtype testtype

gr bar RDTresult_POS match_treat_RDT match_treat_RDT_pos match_treat_RDT_neg , over(testtype) /// 
	legend(label(1 "Positive Home Test") label(2 "Overall Match") label(3 "Match: Positive+Antimalarial") label(4 "Match: Negative+No Antimal.") size(small)) graphregion(color(white)) bar(1, color(gs0)) bar(2, color(gs5)) bar(3, color(gs10)) bar(4, color(gs14))

 graph export "$graphs/B1_misallocation.pdf", replace

```

### `Lopez_Sautmann_Schaner_2020/Do_Files/Figures/B2_graph_dist_pred_pos.do`
```stata
* DISTRIBUTION PREDICTED MALARIA RISK

_pctile pred_mal_pos, p(25 50 75)
	local p25= r(r1)
	local p50= r(r2)
	local p75= r(r3)
	
twoway (kdensity pred_mal_pos if doctor_voucher+patient_voucher==0, lcol(black) lpat(dash)) (kdensity pred_mal_pos if doctor_voucher, lcol(gs10) lwid(medthick)) (kdensity pred_mal_pos if patient_voucher, lcol(gs5) lwid(medthick)), ///
		 legend(label(1 "No Voucher") label(2 "Patient Voucher") label(3 "Doctor Voucher") row(1) size(medsmall)) ytit("Density") xtit("Predicted Malaria Risk") graphregion(color(white)) ///
		xline(`p25', lcol(gs13) lpat(dash)) xline(`p50', lcol(gs13) lpat(dash)) xline(`p75', lcol(gs13) lpat(dash))  

graph export "$graphs/B2_dist_pred_pos.pdf", replace


```

### `Lopez_Sautmann_Schaner_2020/Do_Files/Figures/B3_graph_outcomeXpredpos_control_home.do`
```stata
preserve

// patterns in no voucher group only
keep if doctor_voucher + patient_voucher ==0

// no treatment (RX, taken)
g RXnone= 1 - RXtreat_sev_simple_mal
g none=   1 - treat_sev_simple_mal

// percentiles of predicted pos
g predicted_RDT_POS= pred_mal_pos
_pctile predicted_RDT_POS, p(2.5 97.5)
local bottom=r(r1)
local top=r(r2)
_pctile predicted_RDT_POS, p(25 50 75)
	local p25= r(r1)
	local p50= r(r2)
	local p75= r(r3)
	
// make local linear graphs and trim tails
local varlist "RXnone RXtreat_simple_mal RXtreat_severe_mal none treat_simple_mal treat_severe_mal"

foreach out of local varlist{
local ytit "Local Average"	
local tit: variable label `out'

* has home RDT
	lpoly `out' predicted_RDT_POS if has_valid_rdt_H==1, deg(1) gen(Tx_`out' Ty_`out') se(Tse_`out') nodraw
		replace Ty_`out'=. if Tx_`out'>`top' | Tx_`out'<`bottom'
		replace Tx_`out'=. if Tx_`out'>`top' | Tx_`out'<`bottom'
		g Tul_`out'= Ty_`out'+1.645*Tse_`out'
		g Tll_`out'= Ty_`out'-1.645*Tse_`out'

* no home RDT
	lpoly `out' predicted_RDT_POS if has_valid_rdt_H==0, deg(1) gen(NTx_`out' NTy_`out') se(NTse_`out') nodraw
		replace NTy_`out'=. if NTx_`out'>`top' | NTx_`out'<`bottom'
		replace NTx_`out'=. if NTx_`out'>`top' | NTx_`out'<`bottom'
		g NTul_`out'= NTy_`out'+1.645*NTse_`out'
		g NTll_`out'= NTy_`out'-1.645*NTse_`out'
				
		}


// compile final graph panel by panel

foreach lead in "T" "NT" {
	line `lead'y_RXnone `lead'y_none `lead'x_none, legend(label(1 "No Treat. Prescribed") label(2 "No Treat. Purchased") size(small) row(1)) xtit("Predicted Malaria Risk", size(medium)) ytit("Share Patients", size(medium)) ///
		graphregion(color(white)) tit("A. No Malaria Treatment", size(medsmall)) lcol(black gs10) lwid(medthick medthick) lpat(solid longdash) name(`lead'PA, replace) ylab(0(.2).8) xline(`p25', lcol(gs7) lpat(dot)) xline(`p50', lcol(gs7) lpat(dot)) xline(`p75', lcol(gs7) lpat(dot))	nodraw
	line `lead'y_RXtreat_simple_mal `lead'y_treat_simple_mal  `lead'x_treat_simple_mal, legend(label(1 "Treatment Prescribed") label(2 "Treatment Purchased") size(small) row(1)) xtit("Predicted Malaria Risk", size(medium)) ytit("Share Patients", size(medium)) ///
		graphregion(color(white)) tit("B. Simple Malaria Treatment", size(medsmall)) lcol(black gs10) lwid(medthick medthick) lpat(solid longdash) name(`lead'PB, replace) ylab(0(.2).8)  xline(`p25', lcol(gs7) lpat(dot)) xline(`p50', lcol(gs7) lpat(dot)) xline(`p75', lcol(gs7) lpat(dot))	nodraw
	line `lead'y_RXtreat_severe_mal `lead'y_treat_severe_mal  `lead'x_treat_severe_mal, legend(label(1 "Treatment Prescribed") label(2 "Treatment Purchased") size(small) row(1)) xtit("Predicted Malaria Risk", size(medium)) ytit("Share Patients", size(medium)) ///
		graphregion(color(white)) tit("C. Severe Malaria Treatment", size(medsmall)) lcol(black gs10) lwid(medthick medthick) lpat(solid longdash) name(`lead'PC, replace) ylab(0(.2).8)  xline(`p25', lcol(gs7) lpat(dot)) xline(`p50', lcol(gs7) lpat(dot)) xline(`p75', lcol(gs7) lpat(dot))	nodraw	
	}
	
graph combine TPA TPB TPC, row(1) graphregion(color(white)) tit("Patients With Home RDT Test", size(medsmall)) name(test, replace) nodraw
graph combine NTPA NTPB NTPC, row(1) graphregion(color(white)) tit("Patients With No Home RDT Test", size(medsmall)) name(notest, replace) nodraw

gr combine test notest, row(3) xsize(10) ysize(5) graphregion(color(white))

// save output
graph export "$graphs/B3_outcomeXpredpos_control_home.pdf", replace

restore

```

### `Lopez_Sautmann_Schaner_2020/Do_Files/Figures/B4_graph_vouchersXbins.do`
```stata
preserve
	
collapse (mean) treat_scheduled, by( cscomnum date_morning_survey )
sort cscomnum date_morning_survey
by cscomnum: gen bins=_n

gen bin1=0
replace bin1=1 if bins==1 | bins==2
gen bin2=0
replace bin2=1 if bins==3 | bins==4
gen bin3=0
replace bin3=1 if bins==5 | bins==6

keep cscomnum date_morning_survey bin1 bin2 bin3 bins
sort cscomnum date_morning_survey

* Save this file for the merge
tempfile auxiliar
sa `auxiliar'

restore

sort cscomnum date_morning_survey

merge m:1 cscomnum date_morning_survey using `auxiliar'

assert _m==3
drop _m

* create variables that have the interaction dummies, say, called PV_day1, DV_day1, PV_day2, … etc. 
forvalues i=1/3 {

gen PV_bin`i'=patient_voucher*bin`i'
gen DV_bin`i'=doctor_voucher*bin`i'
}

* generate a set of variables from PV:  V_day1 = PV_day1, V_day2= PV_day2 etc.
forvalues i=1/3 { 

rename PV_bin`i' V_bin`i'

}

foreach var in used_vouchers_admin RXtreat_sev_simple_mal  RXtreat_severe_mal treat_severe_mal treat_sev_simple_mal {

pdslasso `var' DV_bin*  V_bin*  ($date $patient bin1 bin2), clu($cluvar) partial($date bin1 bin2 )

est sto PV`var'
}

forvalues i=1/3 {

rename V_bin`i' PV_bin`i'

}
*generate a set of variables this time from DV: V_day1 = DV_day1, V_day2= DV_day2 etc.
forvalues i=1/3 {

rename DV*bin`i' V_bin`i'

}
	
foreach var in used_vouchers_admin RXtreat_sev_simple_mal  RXtreat_severe_mal treat_severe_mal treat_sev_simple_mal {

pdslasso `var' PV_bin*  V_bin*  ($date $patient bin1 bin2), clu($cluvar) partial($date bin1 bin2)

est sto DV`var'
}
drop V_bin*	
	
coefplot (PVused_vouchers_admin, keep(V_bin* ) label(Patient Voucher) lpat(solid) lcol(black) lwid(medthick)) (DVused_vouchers_admin, keep(V_bin*) label(Doctor Voucher) lpat(longdash) lcol(gs10) lwid(medthick))  ///
  , vertical legend(size(small)) graphregion(color(white)) xtit("Clinic Observation Day", size(small)) ///
  title("A. Used Vouchers", size(small)) recast(line)   ///
   name(PE, replace) xlab(1 "1-2" 2 "3-4" 3 "5-6", labsize(small)) scheme(s2mono)
   
coefplot (PVRXtreat_sev_simple_mal, keep(V_bin* ) label(Patient Voucher) lpat(solid) lcol(black) lwid(medthick)) (DVRXtreat_sev_simple_mal, keep(V_bin*) label(Doctor Voucher) lpat(longdash) lcol(gs10) lwid(medthick))  ///
  , vertical legend(size(small)) graphregion(color(white)) xtit("Clinic Observation Day", size(small)) ///
  title("B. Prescribed Any Malaria Treatment", size(small)) recast(line) ///
   name(PA, replace) xlab(1 "1-2" 2 "3-4" 3 "5-6", labsize(small)) scheme(s2mono)
   
coefplot (PVtreat_sev_simple_mal, keep(V_bin* ) label(Patient Voucher) lpat(solid) lcol(black) lwid(medthick)) (DVtreat_sev_simple_mal, keep(V_bin*) label(Doctor Voucher) lpat(longdash) lcol(gs10) lwid(medthick))  ///
  , vertical legend(size(small)) graphregion(color(white)) xtit("Clinic Observation Day", size(small)) ///
  title("C. Purchased Any Malaria Treatment", size(small)) recast(line) ///
   name(PB, replace) xlab(1 "1-2" 2 "3-4" 3 "5-6", labsize(small)) scheme(s2mono)
   
coefplot (PVRXtreat_severe_mal, keep(V_bin* ) label(Patient Voucher) lpat(solid) lcol(black) lwid(medthick)) (DVRXtreat_severe_mal, keep(V_bin*) label(Doctor Voucher) lpat(longdash) lcol(gs10) lwid(medthick))  ///
  , vertical legend(size(small)) graphregion(color(white)) xtit("Clinic Observation Day", size(small))  ///
  title("D. Prescribed Severe Malaria Treatment", size(small)) recast(line) ///
   name(PC, replace) xlab(1 "1-2" 2 "3-4" 3 "5-6", labsize(small)) scheme(s2mono)
   
coefplot (PVtreat_severe_mal, keep(V_bin* ) label(Patient Voucher) lpat(solid) lcol(black) lwid(medthick)) (DVtreat_severe_mal, keep(V_bin*) label(Doctor Voucher) lpat(longdash) lcol(gs10) lwid(medthick))  ///
  , vertical legend(size(small)) graphregion(color(white)) xtit("Clinic Observation Day", size(small)) ///
  title("E. Purchased Severe Malaria Treatment", size(small)) recast(line) ///
   name(PD, replace) xlab(1 "1-2" 2 "3-4" 3 "5-6", labsize(small)) scheme(s2mono)  
   
grc1leg PE PA PB PC PD , row(3) graphregion(color(white)) name(final, replace)  //xsize(9) ysize(13) 
	gr dis final, xsize(9) ysize(13)
	
 
graph export "$graphs/B4_vouchersXbins.pdf", replace


```

### `Lopez_Sautmann_Schaner_2020/Do_Files/Stata admin files/LSS_make_bootstrap_repsets.do`
```stata

* *****************************************************
* PROGRAM: make_bootstrap_repsets
* PROGRAMMER: Simone Schaner
* DATE CREATED: 29 March 2019
* THIS FILE MAKES 1000 BOOTSTRAP REPLICATION DATASETS
* TO SPEED UP BOOTSTRAP CALCS IN MAIN PAPER
* PROCESS :: 
*		(1) sample 60 clinics w/ replacement
*		(2) apply sample exclusion criteria
*		(3) calculated predicted malaria positivity and
*			associated variables
*		(4) save replicant dataset
* *****************************************************

set seed 34645
local reps= 1000
local i=1
local k=1
	use "$data_final/LSS_analysis_datasets_20201108.dta", clear
		drop *pred_mal_pos*
		drop above_med_pos above_med_pos_new below_med_pos below_med_pos_new
			global predcont "symptomsscreening_1 symptomsscreening_2 symptomsscreening_3 symptomsscreening_4 symptomsscreening_5 symptomsscreening_6 symptomsscreening_7  daysillness99 agepatient under5 u5_age genderpatient pregnancy ethnic_bambara speak_french readwrite_fluent_french prischoolorless respondent" 
			global useme ""
				foreach var in $predcont {
					replace `var'=0 if MSS`var'==1
				global useme "$useme `var' MSS`var'"
				}
		
while `i'<=`reps' {
		preserve	
			bsample 60, cluster(cscomnum)
				keep if dropme==0
			probit RDTresult_POS  $useme ,  asis iter(1000)
				if e(converged)==1 {
					predict pred_mal_pos, p			
						qui sum pred_mal_pos, detail
							g above_med_pos= pred_mal_pos>=r(p50) if pred_mal_pos!=.
							g below_med_pos= above_med_pos==0 if above_med_pos!=. 	
							la var above_med_pos "High Malaria Prob."
						la var below_med_pos "Low Malaria Prob."
						save "$data_final/_bootstrap/bs_cluCSCOM_`i'", replace
								local ++i
					}
		di `k'
		di `i'-1
		local ++k
		restore
		}
	
		

```

### `Lopez_Sautmann_Schaner_2020/Do_Files/Stata admin files/LSS_config_stata.do`
```stata
/*------------------------------------------------------------------------------
********************************************************************************
* Lopez, Sautmann, Schaner; AEJ Applied
********************************************************************************

** Install all Stata packages needed for replication.
** Based on: https://github.com/gslab-econ/template/blob/master/config/config_stata.do

------------------------------------------------------------------------------*/


clear all
set more off

program main
    * *** Add required packages from SSC to this list ***
    local ssc_packages "coefplot pdslasso estadd"
    * *** Add required packages from SSC to this list ***

    if !missing("`ssc_packages'") {
        foreach pkg in `ssc_packages' {
        * install using ssc, but avoid re-installing if already present
            capture which `pkg'
            if _rc == 111 {                 
               dis "Installing `pkg'"
               quietly ssc install `pkg', replace
               }
        }
    }

  * Install packages using net, but avoid re-installing if already present  
	capture which grc1leg
       if _rc == 111 {
        quietly cap ado uninstall grc1leg
        quietly cap net install grc1leg, from("http://www.stata.com/users/vwiggins")   
       }
	   
	capture which st0085_2
       if _rc == 111 {
        quietly cap ado uninstall st0085_2
        quietly cap net install st0085_2, from("http://www.stata-journal.com/software/sj14-2")   
       }
	   
	capture which st0594
       if _rc == 111 {
        quietly cap ado uninstall st0594
        quietly cap net install st0594, from("http://www.stata-journal.com/software/sj20-1")   
       }

end

main

```

## How to run a script

Write each script to a file under the output directory, then run it with
exactly this command (the data directory is mounted read-only at its own
path; nothing else from the host is visible; `$SCRIPT` is the absolute path of
the script you wrote):

    SCRIPT=<repo>/benchmark/reproductions/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a/script.R   # or <repo>/benchmark/reproductions/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a/attempt-<n>/script.R
    uv run --directory <repo> python -m benchmark.reproducers.run_sandbox --timeout 300 --label retally.run=claude-code-lopez-2022-patient-demand-prescription-overuse-seeded-2026-11-10-a --run-dir "$(dirname "$SCRIPT")" -- docker run --rm --label retally.run=claude-code-lopez-2022-patient-demand-prescription-overuse-seeded-2026-11-10-a --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a/mount/lopez_2022_patient_demand_prescription_overuse:<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a/mount/lopez_2022_patient_demand_prescription_overuse:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R; echo "exit code: $?"

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

The output directory `<repo>/benchmark/reproductions/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a/
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

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a`.
