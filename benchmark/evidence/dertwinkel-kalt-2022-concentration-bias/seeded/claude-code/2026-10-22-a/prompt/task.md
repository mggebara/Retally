# Retally reproduction task: dertwinkel-kalt-2022-concentration-bias (seeded, run 2026-10-22-a)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `dertwinkel-kalt-2022-concentration-bias`, mode `seeded`, run `2026-10-22-a`
- Paper: Concentration Bias in Intertemporal Choice
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/seeded/2026-10-22-a/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/seeded/2026-10-22-a/mount/dertwinkel_kalt_2022_concentration_bias`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/dertwinkel-kalt-2022-concentration-bias/seeded/2026-10-22-a`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/seeded/2026-10-22-a/mount/dertwinkel_kalt_2022_concentration_bias` as data, and `<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/seeded/2026-10-22-a/paper.txt` as
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

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/dertwinkel-kalt-2022-concentration-bias/seeded/2026-10-22-a --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Claims to Reproduce
1. abs_concentration_bias_midpoint_table2_col2: 37.61 (additional real-effort tasks per workday) [type: coefficient]
   Location: Table 2, column 2 (OLS, Midpoint), row 'd~ in Main-Treatment'
   Context: Table 2 ("Absolute and relative concentration bias in Main-Treatment"), column 2. The average absolute measure of concentration bias, d~: the number of additional per-workday real-effort tasks a subject is willing to complete in the unbalanced trade-off beyond the indifference points elicited in the eight balanced trade-offs. Subjects with an upper corner choice in the unbalanced trade-off are assigned the midpoint between the lower bound (62) and their manually stated indifference point. Estimated by OLS of d~ on a constant (the sample mean); robust standard errors. Sample: all Main-Treatment…
2. abs_concentration_bias_tobit_table2_col4: 37.094 (additional real-effort tasks per workday) [type: coefficient]
   Location: Table 2, column 4 (Tobit), row 'd~ in Main-Treatment'
   Context: Table 2, column 4: a Tobit regression of the absolute measure d~ on a constant, based on the lower-bound measure (upper-corner subjects assigned the upper end of the elicitation range) and treating the ends of the elicitation range as censoring points. Same Main-Treatment main sample as column 2.
3. rel_concentration_bias_lower_table2_col1: 0.19 (share (relative increase in per-workday willingness to work)) [type: coefficient]
   Location: Table 2, column 1 (OLS, Lower bound), row 'd~rel in Main-Treatment'
   Context: Table 2, column 1, second row: the average relative measure of concentration bias, d~rel = (1/8) sum over workdays t of d~ / (e_t + x~_t), where e_t is the mandatory number of tasks on workday t and x~_t the indifference point elicited in balanced trade-off t; upper-corner subjects' d~ set to the lower bound. OLS on a constant, robust standard errors, Main-Treatment main sample.
4. rel_concentration_bias_midpoint_table2_col2: 0.224 (share (relative increase in per-workday willingness to work)) [type: coefficient]
   Location: Table 2, column 2 (OLS, Midpoint), row 'd~rel in Main-Treatment'
   Context: Table 2, column 2, second row: the paper's headline measure (Result 1) — the average relative measure of concentration bias d~rel, with upper-corner subjects' d~ set to the midpoint between the lower bound and their manually stated indifference point. OLS on a constant, robust standard errors, Main-Treatment main sample.
5. rel_concentration_bias_upper_table2_col3: 0.259 (share (relative increase in per-workday willingness to work)) [type: coefficient]
   Location: Table 2, column 3 (OLS, Upper bound), row 'd~rel in Main-Treatment'
   Context: Table 2, column 3, second row: the average relative measure d~rel with upper-corner subjects' d~ set to their manually stated indifference point (upper bound). OLS on a constant, robust standard errors, Main-Treatment main sample.
6. n_obs_table2: 100.0 (observations (subjects)) [type: other]
   Location: Table 2, Observations (all four columns)
   Context: Number of observations (subjects) in each column of Table 2: the Main-Treatment subjects remaining after the preregistered exclusion of subjects with a corner choice in any balanced trade-off.
7. rel_cb_mechanism_treatment_table3_col1: 0.075 (share (relative measure of concentration bias)) [type: coefficient]
   Location: Table 3, column 1, row 'd~rel in Mechanism-Treatment'
   Context: Table 3 ("Average relative measure of concentration bias (d~rel) across conditions"), column 1: OLS of the midpoint-based relative measure d~rel on a constant and an indicator for Main-Treatment, estimated on the pooled Main-Treatment and Mechanism-Treatment main samples (between-subjects); this row is the constant, i.e. average d~rel in Mechanism-Treatment (raise in the voucher shown as a sum of its parts). Robust standard errors.
8. diff_main_minus_mechanism_table3_col1: 0.149 (share (difference in relative measure of concentration bias)) [type: coefficient]
   Location: Table 3, column 1, row 'Difference: Main-Treatment - Mechanism-Treatment'
   Context: Table 3, column 1: the coefficient on the Main-Treatment indicator in the column 1 regression — the difference in average d~rel, Main-Treatment minus Mechanism-Treatment (Result 2). Robust standard errors.
9. rel_cb_donation_treatment_table3_col2: 0.135 (share (relative measure of concentration bias)) [type: coefficient]
   Location: Table 3, column 2, row 'd~rel in Donation-Treatment'
   Context: Table 3, column 2: OLS of d~rel on a constant and a condition indicator on the pooled Donation-Treatment and Donation-Control main samples (the benefit of working is a donation to a charity instead of a restaurant voucher); this row is average d~rel in Donation-Treatment (Result 3). Robust standard errors.
10. diff_donation_treatment_minus_control_table3_col2: 0.158 (share (difference in relative measure of concentration bias)) [type: coefficient]
   Location: Table 3, column 2, row 'Difference: Donation-Treatment - Donation-Control'
   Context: Table 3, column 2: the difference in average d~rel between Donation-Treatment and Donation-Control, reported as Donation-Treatment minus Donation-Control. In the Control conditions the final trade-off repeats a balanced trade-off (j = 1, 4 or 8) with the same deviation range as the unbalanced trade-off, so the "placebo" deviation should be zero. Robust standard errors.
11. diff_main_treatment_minus_control_table3_col3: 0.247 (share (difference in relative measure of concentration bias)) [type: coefficient]
   Location: Table 3, column 3, row 'Difference: Main-Treatment - Main-Control'
   Context: Table 3, column 3: OLS of d~rel on a constant and a Treatment indicator on the pooled Main-Treatment and Main-Control main samples; this row is the Treatment coefficient, the difference in average d~rel, Main-Treatment minus Main-Control (the constant, reported in the row above, is average d~rel in Main-Control). Robust standard errors.
12. diff_mechanism_treatment_minus_control_table3_col4: 0.09 (share (difference in relative measure of concentration bias)) [type: coefficient]
   Location: Table 3, column 4, row 'Difference: Mechanism-Treatment - Mechanism-Control'
   Context: Table 3, column 4: OLS of d~rel on a constant and a Treatment indicator on the pooled Mechanism-Treatment and Mechanism-Control main samples; this row is the Treatment coefficient, the difference in average d~rel, Mechanism-Treatment minus Mechanism-Control. Robust standard errors.
13. n_obs_table3: 200.0 (observations (subjects, two conditions pooled)) [type: other]
   Location: Table 3, Observations (all four columns)
   Context: Number of observations in each column of Table 3: the main samples of the two between-subjects conditions compared in that column, after the preregistered exclusions.

## Dataset Information
Name: dertwinkel_kalt_2022_concentration_bias
Local path: <repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/seeded/2026-10-22-a/mount/dertwinkel_kalt_2022_concentration_bias
File format: csv
Files in the dataset directory (paths relative to the local path above):
- Consumption Experiment/R/Calibration Exercise.R (33.7 KB)
- Consumption Experiment/R/Figures C1 i-vi.pdf (395.2 KB)
- Consumption Experiment/Stata/Consumption_Experiment figures.do (3.4 KB)
- Consumption Experiment/Stata/Consumption_Experiment tables and values.do (9.6 KB)
- Consumption Experiment/Stata/Consumption_Experiment tables and values.log (63.7 KB)
- Consumption Experiment/Stata/Consumption_Experiment.csv (930.5 KB) — columns: tn,dispersed,age,study,mathgrade,disposable_income,raven_correct_answers,math_answers_correct,crt_answers_correct,session,treatment,average_ip,decision_number,utility_point,corner,chose_corner,indifference_point,pizza,control,main,id_stage2…
- Consumption Experiment/Stata/Figure 3.pdf (26.0 KB)
- Consumption Experiment/Stata/Figures A5-A7.pdf (69.2 KB)
- Consumption Experiment/Table 1.tex (4.0 KB)
- Consumption Experiment/oTree/CRT/__init__.py (0 B)
- Consumption Experiment/oTree/CRT/__pycache__/__init__.cpython-36.pyc (174 B)
- Consumption Experiment/oTree/CRT/__pycache__/__init__.cpython-37.pyc (185 B)
- Consumption Experiment/oTree/CRT/__pycache__/__init__.cpython-38.pyc (189 B)
- Consumption Experiment/oTree/CRT/__pycache__/models.cpython-36.pyc (1.7 KB)
- Consumption Experiment/oTree/CRT/__pycache__/models.cpython-37.pyc (1.7 KB)
- Consumption Experiment/oTree/CRT/__pycache__/models.cpython-38.pyc (1.8 KB)
- Consumption Experiment/oTree/CRT/__pycache__/pages.cpython-36.pyc (1.6 KB)
- Consumption Experiment/oTree/CRT/__pycache__/pages.cpython-37.pyc (1.7 KB)
- Consumption Experiment/oTree/CRT/__pycache__/pages.cpython-38.pyc (1.6 KB)
- Consumption Experiment/oTree/CRT/_builtin/__init__.py (399 B)
- Consumption Experiment/oTree/CRT/_builtin/__pycache__/__init__.cpython-36.pyc (855 B)
- Consumption Experiment/oTree/CRT/_builtin/__pycache__/__init__.cpython-37.pyc (904 B)
- Consumption Experiment/oTree/CRT/_builtin/__pycache__/__init__.cpython-38.pyc (915 B)
- Consumption Experiment/oTree/CRT/models.py (1.2 KB)
- Consumption Experiment/oTree/CRT/pages.py (899 B)
- Consumption Experiment/oTree/CRT/templates/CRT/Instructions.html (468 B)
- Consumption Experiment/oTree/CRT/templates/CRT/Page1.html (330 B)
- Consumption Experiment/oTree/CRT/templates/CRT/Page2.html (328 B)
- Consumption Experiment/oTree/CRT/templates/CRT/Page3.html (326 B)
- Consumption Experiment/oTree/CRT/tests.py (192 B)
- Consumption Experiment/oTree/Procfile (63 B)
- Consumption Experiment/oTree/README.txt (303 B)
- Consumption Experiment/oTree/StartPage/__init__.py (0 B)
- Consumption Experiment/oTree/StartPage/__pycache__/__init__.cpython-35.pyc (141 B)
- Consumption Experiment/oTree/StartPage/__pycache__/__init__.cpython-36.pyc (190 B)
- Consumption Experiment/oTree/StartPage/__pycache__/__init__.cpython-37.pyc (190 B)
- Consumption Experiment/oTree/StartPage/__pycache__/__init__.cpython-38.pyc (195 B)
- Consumption Experiment/oTree/StartPage/__pycache__/models.cpython-35.pyc (1.4 KB)
- Consumption Experiment/oTree/StartPage/__pycache__/models.cpython-36 (Louis Strangs in Konflikt stehende Kopie 2018-04-10).pyc (1.6 KB)
- Consumption Experiment/oTree/StartPage/__pycache__/models.cpython-36.pyc (1.6 KB)
- Consumption Experiment/oTree/StartPage/__pycache__/models.cpython-37.pyc (1.6 KB)
- Consumption Experiment/oTree/StartPage/__pycache__/models.cpython-38.pyc (1.6 KB)
- Consumption Experiment/oTree/StartPage/__pycache__/views.cpython-35.pyc (1.1 KB)
- Consumption Experiment/oTree/StartPage/__pycache__/views.cpython-36 (Louis Strangs in Konflikt stehende Kopie 2018-04-10).pyc (1.5 KB)
- Consumption Experiment/oTree/StartPage/__pycache__/views.cpython-36.pyc (2.6 KB)
- Consumption Experiment/oTree/StartPage/__pycache__/views.cpython-37.pyc (2.3 KB)
- Consumption Experiment/oTree/StartPage/__pycache__/views.cpython-38.pyc (2.2 KB)
- Consumption Experiment/oTree/StartPage/_builtin/__init__.py (655 B)
- Consumption Experiment/oTree/StartPage/_builtin/__pycache__/__init__.cpython-35.pyc (1.2 KB)
- Consumption Experiment/oTree/StartPage/_builtin/__pycache__/__init__.cpython-36.pyc (1.2 KB)
- Consumption Experiment/oTree/StartPage/_builtin/__pycache__/__init__.cpython-37.pyc (1.2 KB)
- Consumption Experiment/oTree/StartPage/_builtin/__pycache__/__init__.cpython-38.pyc (1.2 KB)
- Consumption Experiment/oTree/StartPage/migrations/__pycache__/__init__.cpython-35.pyc (152 B)
- Consumption Experiment/oTree/StartPage/models.py (1.1 KB)
- Consumption Experiment/oTree/StartPage/static/StartPage/UBo-BonnEconLab.svg (33.0 KB)
- Consumption Experiment/oTree/StartPage/static/StartPage/uni_bonn.svg (9.8 KB)
- Consumption Experiment/oTree/StartPage/templates/StartPage/StartPageWork.html (3.8 KB)
- Consumption Experiment/oTree/StartPage/tests.py (257 B)
- Consumption Experiment/oTree/StartPage/views.py (1.6 KB)
- Consumption Experiment/oTree/_rooms/econ101.txt (135 B)
- Consumption Experiment/oTree/_rooms/subjects.txt (399 B)
- Consumption Experiment/oTree/_static/global/SourceCodePro-Black.ttf.woff (91.5 KB)
- Consumption Experiment/oTree/_static/global/SourceCodePro-BlackIt.ttf.woff (79.6 KB)
- Consumption Experiment/oTree/_static/global/SourceCodePro-Bold.ttf.woff (93.2 KB)
- Consumption Experiment/oTree/_static/global/SourceCodePro-BoldIt.ttf.woff (80.8 KB)
- Consumption Experiment/oTree/_static/global/SourceCodePro-ExtraLight.ttf.woff (91.9 KB)
- Consumption Experiment/oTree/_static/global/SourceCodePro-ExtraLightIt.ttf.woff (79.1 KB)
- Consumption Experiment/oTree/_static/global/SourceCodePro-It.ttf.woff (82.3 KB)
- Consumption Experiment/oTree/_static/global/SourceCodePro-Light.ttf.woff (93.7 KB)
- Consumption Experiment/oTree/_static/global/SourceCodePro-LightIt.ttf.woff (81.0 KB)
- Consumption Experiment/oTree/_static/global/SourceCodePro-Medium.ttf.woff (93.5 KB)
- Consumption Experiment/oTree/_static/global/SourceCodePro-MediumIt.ttf.woff (80.6 KB)
- Consumption Experiment/oTree/_static/global/SourceCodePro-Regular.ttf.woff (93.6 KB)
- Consumption Experiment/oTree/_static/global/SourceCodePro-Semibold.ttf.woff (93.3 KB)
- Consumption Experiment/oTree/_static/global/SourceCodePro-SemiboldIt.ttf.woff (80.7 KB)
- Consumption Experiment/oTree/_static/global/SourceCodePro_SourceSansPro_LICENSE.txt (4.5 KB)
- Consumption Experiment/oTree/_static/global/SourceSansPro-Black.ttf.woff (111.1 KB)
- Consumption Experiment/oTree/_static/global/SourceSansPro-BlackIt.ttf.woff (48.5 KB)
- Consumption Experiment/oTree/_static/global/SourceSansPro-Bold.ttf.woff (115.1 KB)
- Consumption Experiment/oTree/_static/global/SourceSansPro-BoldIt.ttf.woff (49.4 KB)
- … and 288 more files (listing truncated)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/seeded/2026-10-22-a/mount/dertwinkel_kalt_2022_concentration_bias' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
Installed packages (no network; nothing else can be installed): jsonlite, fixest, lfe, AER, ivreg, plm, estimatr, lme4, quantreg, car, sandwich, lmtest, clubSandwich, multiwayvcov, marginaleffects, MatchIt, optmatch, CBPS, WeightIt, cobalt, did, rdrobust, rddensity, Synth, modelsummary, stargazer, texreg, broom, tidyverse, dplyr, tidyr, readr, stringr, lubridate, data.table, haven, readxl, janitor, zoo, ggplot2, ggridges, ggrepel, gridExtra, cowplot, gtable, extrafont, sf, MASS, nnet, survival, splines, Matrix, boot, stats, utils.
Prefer fixest for fixed effects, IV and clustered SEs; use the other installed packages where the paper's method calls for them.
Set a deterministic seed with ``set.seed(42)`` for any randomness.
Do NOT access the internet; the container runs with --network none.
Do NOT shell out via system() / system2().
Emit RESULT:<name>=<value> lines to stdout at the end via cat().

## Original Replication Scripts
The replication package (the dataset directory) ships the authors' own analysis scripts, reproduced below.  These are the GROUND TRUTH for the exact estimating equation, variable names, sample restrictions, fixed effects, and standard-error clustering — follow them over anything reconstructed from the methodology summary, and prefer them over the paper's text where the two disagree.  Your job is to write R code that implements the SAME SPECIFICATION: translate what the scripts estimate, do not transliterate their syntax line by line (a Stata .do file's regression, e.g. `reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the equivalent fixest::feols() call in R).  Keep only the parts that produce the specific claims being reproduced; skip figure construction and unrelated robustness checks.  The scripts' data-file paths refer to the package's internal layout — resolve them against the dataset directory listed under Dataset Information.

Stata-to-fixest sample matching: feols() drops fixed-effect singletons by default, but Stata's `reg y x i.fe` / `xi:` dummies keep them.  Pass `fixef.rm = "none"` to every feols() call that has fixed effects, otherwise the observation count and the robust SEs drift from the paper's.  Stata's `, r` / `vce(robust)` is `vcov = "hetero"`.

### `Consumption Experiment/Stata/Consumption_Experiment tables and values.do`
```stata
**************************************************************************************
**  Stata do-file for Dertwinkel-Kalt, Gerhardt, Riener, Schwerter, and Strang:     **
**  “Concentration Bias in Intertemporal Choice”, Review of Economic Studies, 2021  **
**************************************************************************************



clear all
clear matrix
set more off

import delimited Consumption_Experiment.csv, clear

// indifference_point:
//    willingness to complete additional tasks ($\tilde{x}$)
// id_stage2:
//    indifference point in the unbalanced trade-off
//    as deviation from the point prediction of standard discounting
//    (absolute measure of concentration bias, $\tilde{d}^$)
// qe_ard:
//    quantitative effect, average relative deviation
//    (relative measure of concentration bias, $\tilde{d}^\textup{rel}$)
// qe_rad:
//    quantitative effect, relative average deviation
//    (alternative relative measure of concentration bias, $\tilde{d}^\textup{rel, alt}$)
// utility_point:
//    trade-off number j as explained in Section 2.2 and Table 1
// pap_sample:
//    = 1 if exclusion criteria from preanalysis plan (https://doi.org/10.1257/rct.4446,
//    https://doi.org/10.1257/rct.4341) are fulfilled
// main:
//    = 1 for the Main condition, = 0 for the Mechanism condition
// dispersed:
//    = 1 for the Mechanism condition, = 0 for the Main condition
// treatment:
//    = 1 for the Treatment condition, = 0 for the Control condition
// control:
//    = 1 for the Control condition, = 0 for the Treatment condition
// pizza:
//    = 1 for the Main and Mechanism conditions, = 0 for the Donation condition



*****************
**  MAIN TEXT  **
*****************


** Section 2.4 **

* Equation (2.10)
sum indifference_point if pap_sample == 1 & dispersed == 0 & treatment == 1 & ///
	decision_number < 9 & utility_point == 1
sum indifference_point if pap_sample == 1 & dispersed == 0 & treatment == 1 & ///
	decision_number < 9 & utility_point == 2
sum indifference_point if pap_sample == 1 & dispersed == 0 & treatment == 1 & ///
	decision_number < 9 & utility_point == 3
sum indifference_point if pap_sample == 1 & dispersed == 0 & treatment == 1 & ///
	decision_number < 9 & utility_point == 4
sum indifference_point if pap_sample == 1 & dispersed == 0 & treatment == 1 & ///
	decision_number < 9 & utility_point == 5
sum indifference_point if pap_sample == 1 & dispersed == 0 & treatment == 1 & ///
	decision_number < 9 & utility_point == 6
sum indifference_point if pap_sample == 1 & dispersed == 0 & treatment == 1 & ///
	decision_number < 9 & utility_point == 7
sum indifference_point if pap_sample == 1 & dispersed == 0 & treatment == 1 & ///
	decision_number < 9 & utility_point == 8


** Table 2 **

* Absolute measure ($\tilde{d}$)
* Lower bound
reg   id_stage2       if pap_sample == 1 & dispersed == 0 & treatment == 1, r
* Midpoint
reg   avg_id_stage2   if pap_sample == 1 & dispersed == 0 & treatment == 1, r
* Upper bound
reg   id_stage2_upper if pap_sample == 1 & dispersed == 0 & treatment == 1, r
* Tobit regression
tobit id_stage2       if pap_sample == 1 & dispersed == 0 & treatment == 1, ll(-63) ul(63)

* Relative measure ($\tilde{d}^\textup{rel}$)
* Lower bound
reg   qe_ard_lower    if pap_sample == 1 & dispersed == 0 & treatment == 1, r
* Midpoint
reg   qe_ard          if pap_sample == 1 & dispersed == 0 & treatment == 1, r
* Upper bound
reg   qe_ard_upper    if pap_sample == 1 & dispersed == 0 & treatment == 1, r


** Section 3 **

* Incidence of types in Mechanism-Treatment
tab     id_stage2_sign   if pap_sample == 1 & treatment == 1 & dispersed == 1
* Incidence of types in Main-Treatment
tab     id_stage2_sign   if pap_sample == 1 & treatment == 1 & dispersed == 0
* Comparison Main-Treatment vs. Mechanism-Treatment
ranksum id_stage2_sign   if pap_sample == 1 & treatment == 1, by(dispersed)
* Size of concentration bias conditional on its presence in Main-Treatment vs. Mechanism-Treatment
reg     qe_ard dispersed if pap_sample == 1 & treatment == 1 & id_stage2_sign == 1


** Table 3 **

* Mechanism-Treatment vs. Main-Treatment
reg qe_ard main      if pap_sample == 1 & treatment == 1, r
* Donation-Treatment vs. Donation-Control
reg qe_ard control   if pap_sample == 1 & pizza == 0,     r
	// Note that the coefficient on the variable "control" is negative (-0.158), thus the difference
	// Donation-Treatment - Donation-Control that is reported in the manuscript (0.158) is positive
* Main-Control vs. Main-Treatment
reg qe_ard treatment if pap_sample == 1 & pizza == 1 & dispersed == 0, r
* Mechanism-Control vs. Mechanism-Treatment
reg qe_ard treatment if pap_sample == 1 & pizza == 1 & dispersed == 1, r


** Section 4 **

* Noise
ttest cb_effect = 0.5 if pap_sample == 1 & treatment == 1 & dispersed == 0



******************************
**  SUPPLEMENTARY APPENDIX  **
******************************


** Table A1: Cognitive measures **

* Control variables
global controls_main_tr_manual "d_a*_main_tr d_g*_main_tr d_d*_main_tr d_t*_main_tr"
* Column 1
reg qe_ard                   $controls_main_tr_manual ///
	if pap_sample == 1 & dispersed == 0 & treatment == 1, r
* Column 2: RT in unbalanced trade-off
reg qe_ard std_rt_2_main_tr  $controls_main_tr_manual ///
	if pap_sample == 1 & dispersed == 0 & treatment == 1, r
* Column 3: Math score
reg qe_ard std_math_main_tr  $controls_main_tr_manual ///
	if pap_sample == 1 & dispersed == 0 & treatment == 1, r
* Column 4: CRT score
reg qe_ard std_crt_main_tr   $controls_main_tr_manual ///
	if pap_sample == 1 & dispersed == 0 & treatment == 1, r
* Column 4: Raven IQ score
reg qe_ard std_raven_main_tr $controls_main_tr_manual ///
	if pap_sample == 1 & dispersed == 0 & treatment == 1, r
* Column 5: All cognitive measures simultaneuosly
reg qe_ard std_rt_2_main_tr std_math_main_tr std_crt_main_tr std_raven_main_tr ///
	                         $controls_main_tr_manual ///
	if pap_sample == 1 & dispersed == 0 & treatment == 1, r


** Table A2 **

* Absolute measure ($\tilde{d}$)
* Lower bound
reg   id_stage2       if dispersed == 0 & treatment == 1, r
* Midpoint
reg   avg_id_stage2   if dispersed == 0 & treatment == 1, r
* Upper bound
reg   id_stage2_upper if dispersed == 0 & treatment == 1, r
* Tobit
tobit id_stage2       if dispersed == 0 & treatment == 1, ll(-63) ul(63)

* Relative measure ($\tilde{d}^\textup{rel}$)
* Lower bound
reg   qe_ard_lower    if dispersed == 0 & treatment == 1, r
* Midpoint
reg   qe_ard          if dispersed == 0 & treatment == 1, r
* Upper bound
reg   qe_ard_upper    if dispersed == 0 & treatment == 1, r


** Table A3 **

* Relative measure of concentration bias $\tilde{d}^\textup{rel}$,
* Mechanism-Treatment vs. Main-Treatment
reg qe_ard main      if treatment == 1, r
* Donation-Treatment vs. Donation-Control
reg qe_ard control   if pizza == 0,     r
	// Note that the coefficient on the variable "control" is negative (−0.158),
	// thus the difference Donation-Treatment − Donation-Control that is reported
	// in the manuscript (0.158) is positive
* Main-Control vs. Main-Treatment
reg qe_ard treatment if pizza == 1 & dispersed == 0, r
* Mechanism-Control vs. Mechanism-Treatment
reg qe_ard treatment if pizza == 1 & dispersed == 1, r


** Table A4 **

* Alternative relative measure of concentration bias $\tilde{d}^\textup{rel, alt}$
* Lower bound
reg qe_rad_lower if pap_sample == 1 & dispersed == 0 & treatment == 1, r
* Midpoint
reg qe_rad       if pap_sample == 1 & dispersed == 0 & treatment == 1, r
* Upper bound
reg qe_rad_upper if pap_sample == 1 & dispersed == 0 & treatment == 1, r


** Table A5 **

* Alternative relative measure of concentration bias $\tilde{d}^\textup{rel, alt}$
* Mechanism-Treatment vs. Main-Treatment
reg qe_rad main      if pap_sample == 1 & treatment == 1, r
* Donation-Treatment vs. Donation-Control
reg qe_rad control   if pap_sample == 1 & pizza == 0,     r
	// Note that the coefficient on the variable “control” is negative (−0.158),
	// thus the difference Donation-Treatment − Donation-Control that is reported
	// in the manuscript (0.158) is positive
* Main-Control vs. Main-Treatment
reg qe_rad treatment if pap_sample == 1 & pizza == 1 & dispersed == 0, r
* Mechanism-Control vs. Mechanism-Treatment
reg qe_rad treatment if pap_sample == 1 & pizza == 1 & dispersed == 1, r


** Table A6 **

* Absolute measure ($\tilde{d}$)
* Mechanism-Treatment vs. Main-Treatment
reg avg_id_stage2 main      if pap_sample == 1 & treatment == 1, r
* Donation-Treatment vs. Donation-Control
reg avg_id_stage2 control   if pap_sample == 1 & pizza == 0,     r
	// Note that the coefficient on the variable “control” is negative (−28.250),
	// thus the difference Donation-Treatment − Donation-Control that is reported
	// in the manuscript (28.250) is positive
* Main-Control vs. Main-Treatment
reg avg_id_stage2 treatment if pap_sample == 1 & pizza == 1 & dispersed == 0, r
* Mechanism-Control vs. Mechanism-Treatment
reg avg_id_stage2 treatment if pap_sample == 1 & pizza == 1 & dispersed == 1, r


** Table A7 **

* Absolute measure ($\tilde{d}$)
* Mechanism-Treatment vs. Main-Treatment
tobit id_stage2 main      if pap_sample == 1 & treatment == 1,              ll(-63) ul(63)
* Donation-Treatment vs. Donation-Control
tobit id_stage2 control   if pap_sample == 1 & pizza == 0,                  ll(-63) ul(63)
	// Note that the coefficient on the variable “control” is negative (−26.853),
	// thus the difference Donation-Treatment − Donation-Control that is reported
	// in the manuscript (26.853) is positive
* Main-Control vs. Main-Treatment
tobit id_stage2 treatment if pap_sample == 1 & pizza == 1 & dispersed == 0, ll(-63) ul(63)
* Mechanism-Control vs. Mechanism-Treatment
tobit id_stage2 treatment if pap_sample == 1 & pizza == 1 & dispersed == 1, ll(-63) ul(63)

```

### `Money Experiment/Stata/Money_Experiment tables and values.do`
```stata
**************************************************************************************
**  Stata do-file for Dertwinkel-Kalt, Gerhardt, Riener, Schwerter, and Strang:     **
**  “Concentration Bias in Intertemporal Choice”, Review of Economic Studies, 2021  **
**************************************************************************************



clear all
clear matrix
set more off

import delimited Money_Experiment.csv, clear

// diff_bs_choice: Difference in savings rate between unbalanced and balanced budget sets

// condition = 7: inc_bs    // increasingly dispersed budget sets: Conc-Disp
// condition = 8: dec_bs    // dereasingly  dispersed budget sets: Disp-Conc

// condition = 1: inc_bs_2  // Conc-Disp[2]
// condition = 3: inc_bs_4  // Conc-Disp[4]
// condition = 5: inc_bs_8  // Conc-Disp[8]

// condition = 2: dec_bs_2  // Disp[2]-Conc
// condition = 4: dec_bs_4  // Disp[4]-Conc
// condition = 6: dec_bs_8  // Disp[8]-Conc

// treatment:
//    = 1 for the Money-Main condition, = 0 for the Money-Mechanism condition



*****************
**  MAIN TEXT  **
*****************


** Section 5 **

* $\hat{d}_\textup{C-D}$ (concentrated-dispersed, Conc-Disp)
reg diff_bs_choice if condition == 7 & treatment == 1
* $\hat{d}_\textup{D-C}$ (dispersed-concentrated, Disp-Conc)
reg diff_bs_choice if condition == 8 & treatment == 1

* $\hat{d}_8$
reg diff_bs_choice if (condition == 5 | condition == 6) & treatment == 1, cluster(tn)
* $\hat{d}_4$
reg diff_bs_choice if (condition == 3 | condition == 4) & treatment == 1, cluster(tn)
* $\hat{d}_2$
reg diff_bs_choice if (condition == 1 | condition == 2) & treatment == 1, cluster(tn)

* $\hat{d}_8 > \hat{d}_2$: Conc-Disp[8] and Disp[8]-Conc vs. Conc-Disp[2] and Disp[2]-Conc
reg diff_bs_choice disp_2 if (condition == 1 | condition == 2 | condition == 5 | condition == 6) & treatment == 1, cluster(tn)
* $\hat{d}_4 > \hat{d}_2$: Conc-Disp[2] and Disp[2]-Conc vs. Conc-Disp[4] and Disp[4]-Conc
reg diff_bs_choice disp_2 if (condition == 1 | condition == 2 | condition == 3 | condition == 4) & treatment == 1, cluster(tn)
* $\hat{d}_8 > \hat{d}_4$: Conc-Disp[8] and Disp[8]-Conc vs. Conc-Disp[4] and Disp[4]-Conc
reg diff_bs_choice disp_4 if (condition == 3 | condition == 4 | condition == 5 | condition == 6) & treatment == 1, cluster(tn)



******************************
**  SUPPLEMENTARY APPENDIX  **
******************************


** Table D1 **

* $\hat{d}$
reg diff_bs_choice if (condition == 7 | condition == 8) & treatment == 1, cluster(tn)


** Table D2 **

* Column 1: Frequenccy of $\hat{d}_\textup{C-D}$ (concentrated-dispersed, Conc-Disp)
tab diff_bs_sign if condition == 7 & treatment == 1
* Column 2: Frequenccy of $\hat{d}_\textup{D-C}$ (dispersed-concentrated, Disp-Conc)
tab diff_bs_sign if condition == 8 & treatment == 1


** Table D3 **

* $\hat{d}$, cognitive control variables
* Response time
reg diff_bs_choice diff_bs_time_treatment_only_std ///
	if (condition == 7 | condition == 8) & treatment == 1, cluster(tn)
* CRT score
reg diff_bs_choice crt_treatment_only_std ///
	if (condition == 7 | condition == 8) & treatment == 1, cluster(tn)
* Math task
reg diff_bs_choice math_treatment_only_std ///
	if (condition == 7 | condition == 8) & treatment == 1, cluster(tn)


** Table D4 **

* $\hat{d}$, Money-Mechanism vs. Money-Main
* Column 1
reg diff_bs_choice treatment ///
	if (condition == 7 | condition == 8), cluster(tn)
* Column 2
reg diff_bs_choice treatment diff_bs_time_std crt_std math_std ///
	if (condition == 7 | condition == 8), cluster(tn)


** Section D.3.2: Degree of dispersion **

// See code for Section 5 above.

```

### `Consumption Experiment/R/Calibration Exercise.R`
```r
######################################################################################
##  R script for the calibration exercise reported in Section 4 (and Supplementary  ##
##  Appendix C) of Dertwinkel-Kalt, Gerhardt, Riener, Schwerter, and Strang:        ##
##  “Concentration Bias in Intertemporal Choice”, Review of Economic Studies, 2021  ##
######################################################################################




####  LOAD DATA FILE  ####

# If the analysis has already been run and you simply want to retrieve some values,
# load the generated data set:
#load('Estimation of delta-gamma combinations 2021-02-15.RData')




####  REQUIRED PACKAGES ####

packages_required <- c("crayon", "fields", "plotly", "Cairo")
install.packages( setdiff( packages_required, rownames( installed.packages() ) ) )
for(name in packages_required) { library(name, character.only = TRUE) }




####  EXOGENOUS PARAMETERS AND OBSERVED CHOICES  ####


baseline_voucher   = 7.50
raises             = c(290, 270, 310, 270, 320, 290, 310, 320) / 100
v_max              = baseline_voucher + sum(raises)

base_constants     = rep(100, 8) + c(29, 32, 43, 15, 21, 17, 35, 27)

indiff_points_main_t =
   c(39.20, 34.94, 33.61, 41.46, 41.80, 42.20, 35.93, 38.25)  # avg. 38.42375
indiff_points_main_c =
   c(36.02, 31.51, 30.42, 36.00, 38.87, 40.61, 35.68, 35.78)  # avg. 35.61125
indiff_points_mech_t =
   c(37.53, 34.50, 40.15, 35.77, 39.72, 34.60, 34.67, 35.55)  # avg. 36.56125
indiff_points_mech_c =
   c(37.85, 35.45, 37.19, 34.87, 38.07, 32.86, 35.57, 35.31)  # avg. 35.89625
indiff_points_main_t_unbal = indiff_points_main_t + 37.6
indiff_points_mech_t_unbal = indiff_points_mech_t + 13.8

( l_max = max(
   base_constants +
   c(indiff_points_main_t, indiff_points_main_c, indiff_points_mech_t, indiff_points_mech_c)
) )




####  DEFINE PARAMETERS AND FUNCTIONS  ####


# Disutility of labour is convex if α > 1
disu <- function(l, α) {
   #-(l^α)
   -(l / l_max)^α * l_max
}
plot( 1:l_max, disu(1:l_max, 1.5), type = "l", col = "red" )

# Utility of voucher is concave if ω < 1
u <- function(c, ω) {
   #c^ω
   ( c / v_max )^ω * v_max
}
plot( 1:v_max, u(1:v_max, 0.5), type = "l", col = "green" )

# Focus weights (no focusing if γ = 0)
g_fw <- function(Δu, γ) {
   ( abs(Δu) )^γ
}

# Factor reducing (“learning”) or increasing (“fatigue”) subsequent disutility,
# depending on amount worked so far
avg_experiencce = mean( cumsum( c(10, base_constants + indiff_points_main_t) ) )
max_experience  =          sum( c(10, base_constants + indiff_points_main_t) )
disu_red <- function(l_agg, ρ_l, ρ_f) {
   logit <- function(x, m, s) {
      1  / ( 1 + exp(-s * (x - m) ) )
   }
   # We use the logit function because it is very flexible:
   # it permits a convex or concave shape or a switch of the curvature, that is,
   # an increasing or decreasing marginal effect or switch between the two
   disu = logit(l_agg - avg_experiencce, ρ_l, ρ_f / 100)
   disu_adj = disu / max( logit(L_grid - avg_experiencce, ρ_l, ρ_f / 100) )
      # Adjustment such that function either starts or ends at 1
   return(disu_adj)
}
L_grid = seq( 0, sum( c(10, base_constants + indiff_points_main_t) ) )
# Illustrate some possible shapes of the history-dependent weighting function:
plot ( L_grid, disu_red(L_grid,    0,  0.20), col = 'navy', type = 'l', ylim = c(0, 1) )
lines( L_grid, disu_red(L_grid,    0,  0.15), col = 'violet' )
lines( L_grid, disu_red(L_grid, -300,  0.15), col = 'blue' )
lines( L_grid, disu_red(L_grid,    0,  0.10), col = 'orange' )
lines( L_grid, disu_red(L_grid,    0,  0.04), col = 'yellow' )
lines( L_grid, disu_red(L_grid,    0,  0.00), col = 'black' )
lines( L_grid, disu_red(L_grid,    0, -0.02), col = 'red' )
lines( L_grid, disu_red(L_grid,    0, -0.10), col = 'pink' )
lines( L_grid, disu_red(L_grid,    0, -0.40), col = 'green' )
lines( L_grid, disu_red(L_grid,  600, -0.30), col = 'brown' )

# Aggregate utility
# Parameters:
# L_mat:     Matrix of number of tasks performed (one period per column)
# L_mat_alt: Matrix of number of tasks performed according to the alternative on offer
#            (one period per column) — necessary to calculate focus weights,
#            which depend on the utility range spanned by the available alternatives
# v:         Voucher value
# v_alt:     Voucher value according to the alternative on offer — necessary to calculate
#            focus weight, which depends on the utility range spanned by the available
#            alternatives
# α:         Curvature parameter of the disutility of labour
# ω:         Curvature parameter of the utility of the voucher
# φ:         Paremter weighing utility of the voucher and disutility of labour
# ρ_l, ρ_f:  Location and slope parameter of the logistic function that gives rise
#            to the history-dependent utility weights
# γ:         Parameter determining the increase of the focus weights in the utility range
# δ:         Exponential discount factor
U <- function(L_mat, L_mat_alt, v, v_alt, α, ω, φ, ρ_l, ρ_f, γ, δ) {
   L     = cbind(10, L_mat    )  # Experience on the first workday are the 10 practice rounds
   L_alt = cbind(10, L_mat_alt)  # Experience on the first workday are the 10 practice rounds
   # Initialize matrices with NA
   weighted_util = matrix(NA, nrow = dim(L_mat)[1], ncol = 9)
   weighted_util_alt = weighted_util
   fw_weighted_util = weighted_util
   # Weighted utility on workday 1
   weighted_util[, 1] =
      δ^0 * disu_red(L    [, 1, drop = FALSE], ρ_l, ρ_f) * disu(L    [, 2], α)
   weighted_util_alt[, 1] =
      δ^0 * disu_red(L_alt[, 1, drop = FALSE], ρ_l, ρ_f) * disu(L_alt[, 2], α)
   # Weighted utility on wworkdays 2–8
   for (t in 2:8) {
      weighted_util[, t] =
         δ^(t-1) * disu_red(rowSums(L    [, 1:t, drop = FALSE]), ρ_l, ρ_f) * disu(L    [, t + 1], α)
   }
   for (t in 2:8) {
      weighted_util_alt[, t] =
         δ^(t-1) * disu_red(rowSums(L_alt[, 1:t, drop = FALSE]), ρ_l, ρ_f) * disu(L_alt[, t + 1], α)
   }
   # Weighted utility in period 9 (restaurant day)
   weighted_util[, 9] =
      φ * u(v, ω)  # δ^8 * u(v, ω)
   weighted_util_alt[, 9] =
      φ * u(v_alt, ω)  # δ^8 * u(v, ω)
   # Apply focus weights to comput focus-weighted utility per period
   fw_weighted_util =
      g_fw( weighted_util - weighted_util_alt, γ ) * weighted_util
   # Sum focus-weighted utility over periods
   fw_weighted_util_summed = matrix( rowSums(fw_weighted_util), nrow = dim(L_mat)[1], ncol = 1 )
   return(fw_weighted_util_summed)
}

# Utility for balanced decisions
utility_bal_complete_A <- function(t, add_tasks, α, ω, φ, ρ_l, ρ_f, γ, δ) {
   L_B =
      matrix( base_constants, nrow = length(add_tasks), ncol = length(base_constants), byrow = TRUE)
   L_A = L_B
   L_A[, t] = L_B[, t] + add_tasks
   raises_lagged = c(0, raises[1:7])
   U(
      L_A, L_B,  # L_A: Option under consideration, L_B: alternative option
      baseline_voucher + sum(raises       [1:t]), baseline_voucher + sum(raises_lagged[1:t]),
      α, ω, φ, ρ_l, ρ_f, γ, δ
   )
}
utility_bal_complete_B <- function(t, add_tasks, α, ω, φ, ρ_l, ρ_f, γ, δ) {
   L_B =
      matrix( base_constants, nrow = length(add_tasks), ncol = length(base_constants), byrow = TRUE)
   L_A = L_B
   L_A[, t] = L_B[, t] + add_tasks
   raises_lagged = c(0, raises[1:7])
   U(
      L_B, L_A,  # L_B: Option under consideration, L_A: alternative option
      baseline_voucher + sum(raises_lagged[1:t]), baseline_voucher + sum(raises       [1:t]),
      α, ω, φ, ρ_l, ρ_f, γ, δ
   )
}

# Utility for unbalanced decisions
utility_unbal_complete_A <- function(indiff_bal, add_tasks, α, ω, φ, ρ_l, ρ_f, γ, δ) {
   L_B = matrix(
      base_constants + indiff_bal, nrow = length(add_tasks), ncol = length(base_constants), byrow = TRUE
   )
   L_A = L_B + add_tasks
   U(
      L_A, L_B,  # L_A: Option under consideration, L_B: alternative option
      baseline_voucher + sum(raises), baseline_voucher,
      α, ω, φ, ρ_l, ρ_f, γ, δ
   )
}
utility_unbal_complete_B <- function(            add_tasks, α, ω, φ, ρ_l, ρ_f, γ, δ) {
   L_B = matrix(
      base_constants, nrow = length(add_tasks), ncol = length(base_constants), byrow = TRUE
   )
   L_A = L_B + add_tasks
   U(
      L_B, L_A,  # L_B: Option under consideration, L_A: alternative option
      baseline_voucher,               baseline_voucher + sum(raises),
      α, ω, φ, ρ_l, ρ_f, γ, δ
   )
}




####  PERFORM GRID SEARCH TO FIT THE OBSERVED CHOICES  ####


# Grids for estimation of the focusing model
α_grid =
   seq(    3.00,     3.15, by =   0.01)  # 2021-03-23
   #seq(    3.00,     3.10, by =   0.01)  # 2021-02-15 - Result: 3.07-3.08
   #seq(    2.97,     3.01, by =   0.01)  # 2021-02-15 - Result: 3.01
   #seq(    2.85,     3.00, by =   0.01)  # 2021-02-11 - Result: 2.99
   #seq(    2.80,     2.90, by =   0.01)  # 2021-02-11 - Result: 2.90
   #seq(    2.75,     2.85, by =   0.01)  # 2021-02-10 - Result: 2.85
   #seq(    0.70,     3.10, by =   0.10)  # 2021-02-05
ω_grid =
   seq(    0.80,     0.95, by =   0.01)  # 2021-03-23
   #seq(    0.95,     0.98, by =   0.01)  # 2021-02-15: 0.96
   #seq(    0.93,     0.97, by =   0.01)  # 2021-02-15 - Result: 0.96
   #seq(    0.90,     1.00, by =   0.01)  # 2021-02-11 - Result: 0.95
   #seq(    0.85,     0.95, by =   0.01)  # 2021-02-10 - Result: 0.95
   #seq(    0.60,     2.10, by =   0.10)  # 2021-02-05
ρ_l_grid =
   0
ρ_f_grid =
   0
φ_grid =
   seq(   26.25,    26.50, by =   0.01)  # 2021-03-23
   #seq(   26.35,    26.45, by =   0.01)  # 2021-02-15 - Result: 26.38/26.40
   #seq(   26.20,    26.40, by =   0.01)  # 2021-02-15 - Result: 26.38/26.40
   #seq(   25.50,    26.50, by =   0.10)  # 2021-02-11 - Result: 26.30
   #seq(   25.00,    27.00, by =   0.10)  # 2021-02-11 - Result: 25.90
   #seq(   22.00,    27.50, by =   0.10)  # 2021-02-10 - Result: 26.00
   #c(0.1, 0.2, 0.4, 0.5, 0.75, 1, 2, 4, 5, 7.5, 10, 12, 15, 20, 22, 25, 27.5, 30)  # 2021-02-05
   #c(0.1, 0.15, 0.2, 0.25, 0.4, 0.5, 0.7, 1, 2, 3, 4, 5, 7.5, 10, 12, 14, 16, 20, 25)
   #seq(    0.25,    20.25, by =   0.50)  # LB reached in pooled bal-unbal estimation
δ_grid =
   seq(    0.995,    1.005, by =  0.001)
   #seq(     0.95,     1.05, by =   0.01)  # 2021-02-10 - Result: 1.01
   #seq(     0.80,     1.80, by =   0.10)  # 2021-02-05
γ_grid =
   seq(     0.60,     0.68, by =   0.01)  # 2021-03-23
   #seq(     0.62,     0.68, by =   0.01)  # 2021-02-15 - Result: 0.64
   #seq(     0.60,     0.64, by =   0.01)  # 2021-02-14 - Result: 0.64
   #seq(     0.55,     0.65, by =   0.01)  # 2021-02-11 - Result: 0.62
   #seq(     0.55,     0.65, by =   0.01)  # 2021-02-11 - Result: 0.61
   #seq(     0.57,     0.67, by =   0.01)  # 2021-02-10 - Result: 0.59
   #seq(     0.00,     1.00, by =   0.02)  # 2021-02-05

# # Grids for estimation of the history-dependent model
# α_grid     =
#    seq(    2.11,     2.15, by =   0.01)  # 2021-03-30
#    #seq(    2.10,     2.14, by =   0.01)  # 2021-03-30 - Result: 2.13
#    #seq(    2.10,     2.14, by =   0.01)  # 2021-02-15 - Result: 2.12
#    #seq(    2.10,     2.16, by =   0.01)  # 2021-02-13 - Result: 2.12
#    #seq(    2.12,     2.20, by =   0.01)  # 2021-02-12 - Result: 2.13
#    #seq(    2.15,     2.25, by =   0.01)  # 2021-02-10 - Result: 2.16
#    #seq(    0.70,     3.10, by =   0.10)  # 2021-02-05
# ω_grid     =
#    seq(    2.09,     2.13, by =   0.01)  # 2021-03-30
#    #seq(    2.09,     2.13, by =   0.01)  # 2021-02-15: Result: 2.11
#    #seq(    2.07,     2.13, by =   0.01)  # 2021-02-13: Result: 2.11
#    #seq(    2.07,     2.17, by =   0.01)  # 2021-02-12: Result: 2.10
#    #seq(    2.12,     2.20, by =   0.01)  # 2021-02-11 - Result: 2.12
#    #seq(    2.15,     2.25, by =   0.01)  # 2021-02-10 - Result: 2.16
#    #seq(    0.60,     2.10, by =   0.10)  # 2021-02-05
# ρ_l_grid =
#    seq(-2750.00, -2650.00, by = 10.00)  # 2021-03-30
#    #seq(-2700.00, -2600.00, by =  10.00)  # 2021-03-30 - Result: -2700
#    #seq(-2700.00, -2450.00, by =  10.00)  # 2021-02-15 - Result: -2660
#    #seq(-2800.00, -2480.00, by =  10.00)  # 2021-02-13 - Result: (-2660, -2490)
#    #seq(-2500.00, -2350.00, by =  10.00)  # 2021-02-13 - Result: (-2500, -2490)
#    #seq(-2400.00, -2300.00, by =  10.00)  # 2021-02-12 - Result: -2400
#    #seq(-2400.00, -2200.00, by =  10.00)  # 2021-02-11 - Result: -2340
#    #seq(-2400.00, -1800.00, by = 100.00)  # 2021-02-10 - Result: -2300.00
#    #seq(-3000.00, -1200.00, by = 300.00)  # 2021-02-05 - LB reached in pooled bal-unbal estimation
# ρ_f_grid =
#    seq(   -0.39,    -0.35, by =   0.01)  # 2021-03-30
#    #seq(   -0.38,    -0.36, by =   0.01)  # 2021-02-15 - Result: -0.37
#    #seq(   -0.38,    -0.36, by =   0.01)  # 2021-02-12
#    #seq(   -0.43,    -0.33, by =   0.01)  # 2021-02-13 - Result: -0.37
#    #seq(   -0.45,    -0.30, by =   0.01)  # 2021-02-11 - Result: -0.38
#    #seq(   -0.50,    -0.40, by =   0.01)  # 2021-02-10 - Result: -0.40
#    #seq(   -0.75,     0.15, by =   0.15)  # 2021-02-05 - LB reached in pooled bal-unbal estimation
# φ_grid =
#    seq(    6.25,     6.35, by =   0.01)  # 2021-03-30
#    #seq(    6.10,     6.30, by =   0.01)  # 2021-03-30 - Result: 6.29
#    #seq(    6.10,     6.30, by =   0.01)  # 2021-02-15 - Result: 6.20
#    #seq(    6.00,     6.60, by =   0.10)  # 2021-02-13 - Result: 6.20
#    #seq(    5.50,     6.50, by =   0.10)  # 2021-02-11 - Result: 6.30
#    #seq(    4.00,     6.00, by =   0.10)  # 2021-02-10 - Result: 5.90
#    #c(0.1, 0.2, 0.4, 0.5, 0.75, 1, 2, 4, 5, 7.5, 10, 12, 15, 20, 22, 25, 27.5, 30)  # 2021-02-05
#    #c(0.1, 0.15, 0.2, 0.25, 0.4, 0.5, 0.7, 1, 2, 3, 4, 5, 7.5, 10, 12, 14, 16, 20, 25)  # 2021-02-05
#    #seq(    0.25,    20.25, by =   0.50)  # 2021-02-05 - LB reached in pooled bal-unbal estimation
# δ_grid =
#    seq(    1.476,    1.486, by =  0.001)  # 2021-03-30
#    #seq(     1.47,     1.49, by =   0.001)  # 2021-03-30 - Result: 1.482
#    #seq(     1.47,     1.49, by =   0.01)  # 2021-02-15 - Result: 1.48
#    #seq(     1.45,     1.51, by =   0.01)  # 2021-02-13 - Result: 1.48
#    #seq(     1.45,     1.55, by =   0.01)  # 2021-02-12 - Result: 1.48
#    #seq(     1.50,     1.60, by =   0.01)  # 2021-02-11 - Result: 1.50
#    #seq(     1.50,     1.70, by =   0.01)  # 2021-02-10 - Result: 1.53
#    #seq(     0.80,     1.80, by =   0.10)  # 2021-02-05
# γ_grid =
#    0

( num_rows =
   length(α_grid) * length(ω_grid) * length(ρ_l_grid) * length(ρ_f_grid) *
   length(φ_grid) * length(δ_grid) * length(γ_grid) )

results_cols <- c(
   "α", "ω", "ρ_l", "ρ_f", "φ", "δ", "γ",
   "IDP_pred[1]", "IDP_pred[2]", "IDP_pred[3]", "IDP_pred[4]",
   "IDP_pred[5]", "IDP_pred[6]", "IDP_pred[7]", "IDP_pred[8]",
   "IDP_diff_unbal",
   "multiple_minima",
   "SSR_main_t_bal",   "SSR_main_c_bal",  "SSR_mech_t_bal",   "SSR_mech_c_bal",  "SSR_t_bal",  "SSR_c_bal", "SSR_bal",
   "SSR_main_t_unbal",                    "SSR_mech_t_unbal",                                               "SSR_unbal",
   "SSR_main_t",       "SSR_main",        "SSR_mech_t",       "SSR_mech",                                   "SSR"
)
results <- matrix( data = NA, nrow = num_rows, ncol = length(results_cols) )
colnames(results) <- results_cols

# Candiate workloads (x) in the balanced decisions
indiff_points_t_try       = seq( 0 , 75, 0.1)
# Candidate additional workloads (d) in the unbalanced decisions
indiff_points_t_try_unbal = seq(-40, 60, 0.1)

# Calculate the theoretically predicted indifference points for all possible parameter combinations
# and record the associated sum of square residuals from the observed choices
for(a in 1:length(α_grid)) {
   for(o in 1:length(ω_grid)) {
      for(r_l in 1:length(ρ_l_grid)) {
         for(r_f in 1:length(ρ_f_grid)) {
            for(f in 1:length(φ_grid)) {
               for(d in 1:length(δ_grid)) {
                  for(g in 1:length(γ_grid)) {
                     if( mean(c(a, o, r_l, r_f, f, d, g)) == 1 ) {
                        row = 1
                        start_date_time = format(Sys.time(), "%Y-%m-%d-%H-%M")
                        print( paste( "Started:", start_date_time ) )
                     } else {
                        row = row + 1
                     }
                     α   = α_grid[a]
                     ω   = ω_grid[o]
                     ρ_l = ρ_l_grid[r_l]
                     ρ_f = ρ_f_grid[r_f]
                     φ   = φ_grid[f]
                     δ   = δ_grid[d]
                     γ   = γ_grid[g]
                     if(row %% 1000 == 0) {
                        print( paste("Iteration", row, "of", num_rows) )
                     }
                     results[row, "α"]   = α
                     results[row, "ω"]   = ω
                     results[row, "ρ_l"] = ρ_l
                     results[row, "ρ_f"] = ρ_f
                     results[row, "φ"]   = φ
                     results[row, "δ"]   = δ
                     results[row, "γ"]   = γ
                     IDP_pred = rep( NA, length(base_constants) )
                     Delta_U_vec_bal = rep( NA, length(indiff_points_t_try) )
                     results[row, "multiple_minima"] = 0
                     for (t in 1:length(base_constants)) {
                        # Generate vector of uility differences based on candiate workloads indiff_points_t_try
                        Delta_U_vec_bal =
                           abs(
                              utility_bal_complete_A(t, indiff_points_t_try, α, ω, φ, ρ_l, ρ_f, γ, δ) -
                              utility_bal_complete_B(t, indiff_points_t_try, α, ω, φ, ρ_l, ρ_f, γ, δ)
                           )
                           # We could set γ = 0, since we are interested only in indifference points,
                           # and in these, the focus weights cancel each other for balanced decisions, while in all
                           # other pairwise balanced decisions, focus weighting amplifies an existing preference.
                        # Find the workload that minimizes the utility difference, which approximates indifference
                        # (Since only integer values for the workloads were possible, we do not determine indifference
                        # more precisely)
                        min_idx_bal = which(Delta_U_vec_bal == min(Delta_U_vec_bal), arr.ind = TRUE)
                        # Issue warning if multiple minima were found:
                        if( dim(min_idx_bal)[1] > 1 ) {
                           cat( red("\nMultiple minima:\n") )
                           print( paste("Iteration", row) )
                           print( paste("Number of grid points with identical fit:", dim(min_idx_bal)[1]) )
                           print(min_idx_bal)
                           #system("say -v Alex      Warning!")
                           #system("say -v Samantha  Multiple minima detected!")
                           #readline(prompt = "Press [enter] to continue")
                           results[row, "multiple_minima"] = results[row, "multiple_minima"] + dim(min_idx_bal)[1]
                        }
                        # Record the indifference-generating workload (\tilde{x}_t)
                        IDP_pred[t] = indiff_points_t_try[ min_idx_bal[1] ]
                        results[ row, paste0("IDP_pred[", t, "]") ] = IDP_pred[t]
                     }
                     # Record the associated sum of squared residuals for the balanced decisions
                     results[row, "SSR_main_t_bal"] = sum( (IDP_pred - indiff_points_main_t)^2 )
                     results[row, "SSR_main_c_bal"] = sum( (IDP_pred - indiff_points_main_c)^2 )
                     results[row, "SSR_mech_t_bal"] = sum( (IDP_pred - indiff_points_mech_t)^2 )
                     results[row, "SSR_mech_c_bal"] = sum( (IDP_pred - indiff_points_mech_c)^2 )
                     # Determine the indifference-generating additional workload in the unbalanced decision
                     Delta_U_vec_unbal =
                        abs(
                           utility_unbal_complete_A(IDP_pred, indiff_points_t_try_unbal, α, ω, φ, ρ_l, ρ_f, γ, δ) -
                           utility_unbal_complete_B(          indiff_points_t_try_unbal, α, ω, φ, ρ_l, ρ_f, γ, δ)
                        )
                     min_idx_unbal = which(Delta_U_vec_unbal == min(Delta_U_vec_unbal), arr.ind = TRUE)
                     IDP_diff_unbal = indiff_points_t_try_unbal[ min_idx_unbal[1] ]
                     # Record the indifference-generating additional workload (\tilde{d})
                     results[row, "IDP_diff_unbal"  ] = IDP_diff_unbal
                     # Record the sum of squared residuals for the unbalanced decisions
                     results[row, "SSR_main_t_unbal"] =
                        sum( (IDP_pred + IDP_diff_unbal - indiff_points_main_t_unbal)^2 )
                     results[row, "SSR_mech_t_unbal"] =
                        sum( (IDP_pred + IDP_diff_unbal - indiff_points_mech_t_unbal)^2 )
                  }
               }
            }
         }
      }
   }
   save.image( file = paste0('Estimation of delta-gamma combinations ', start_date_time, '.RData') )
   if(row == num_rows) {
      print( paste( "Finished:", format(Sys.time(), "%Y-%m-%d-%H-%M") ) )
   }
}




####  DETERMINE THE BEST-FITTING PARAMETER COMBINATION  ####


# We search for the (α, ω, ρ_l, ρ_f, φ, δ, γ) combination that minimizes the sum of squared residuals
# for the target type of decisions

# Fill columns for "pooled" estimation
{
   results[, "SSR_t_bal" ] =  results[, "SSR_main_t_bal"]   + results[, "SSR_mech_t_bal"]
   results[, "SSR_c_bal" ] =  results[, "SSR_main_c_bal"]   + results[, "SSR_mech_c_bal"]
   results[, "SSR_bal"   ] =  results[, "SSR_t_bal"]        + results[, "SSR_c_bal"]
   results[, "SSR_unbal" ] =  results[, "SSR_main_t_unbal"] + results[, "SSR_mech_t_unbal"]
   results[, "SSR_main_t"] =  results[, "SSR_main_t_bal"]   + results[, "SSR_main_t_unbal"]
   results[, "SSR_mech_t"] =  results[, "SSR_mech_t_bal"]   + results[, "SSR_mech_t_unbal"]
   results[, "SSR_main"  ] =  results[, "SSR_main_t_bal"]   + results[, "SSR_main_c_bal"]   + results[, "SSR_main_t_unbal"]
   results[, "SSR_mech"  ] =  results[, "SSR_mech_t_bal"]   + results[, "SSR_mech_c_bal"]   + results[, "SSR_mech_t_unbal"]
   results[, "SSR"       ] =  results[, "SSR_bal"]          + results[, "SSR_unbal"]
}
## Consistency check:
#cbind(results[, "SSR"], results[, "SSR_main"] + results[, "SSR_mech"])

# Check for multiple minima
max( results[, "multiple_minima"] )

# Select relevant columns
col_start = which( colnames(results) == "IDP_pred[1]" )

# Balanced as well as unbalanced decisions, main_t_bal and main_t_unbal
( SSR_main_t_min_idx <-
   which( results[, "SSR_main_t"] == min(results[, "SSR_main_t"] ), arr.ind = TRUE) )
SSR_main_t_min_idx = SSR_main_t_min_idx[1]
( indiff_points_main_t_pred      = results[SSR_main_t_min_idx, col_start:(col_start + 7)] )
( indiff_points_diff_main_t_pred = results[SSR_main_t_min_idx, "IDP_diff_unbal"] )
round( results[SSR_main_t_min_idx, ], digits = 3 )
{
   cat( "Predicted:", indiff_points_main_t_pred,  "-- avg.:", mean(indiff_points_main_t_pred),  "\n" )
   cat( "Real:     ", indiff_points_main_t,       "-- avg.:", mean(indiff_points_main_t  ),     "\n" )
   cat( "Predicted:", indiff_points_main_t_pred + indiff_points_diff_main_t_pred, "-- avg.:",
                 mean(indiff_points_main_t_pred + indiff_points_diff_main_t_pred), "\n" )
   cat( "Real:     ", indiff_points_main_t_unbal, "-- avg.:", mean(indiff_points_main_t_unbal), "\n" )
   par(family = "Times New Roman", lheight = 0.975)
   plot(
      indiff_points_main_t, col = "navy", type = "l",
      ylim = c(0, 83),
      xlab = bquote( "Workday" ~ italic(t) ),
      ylab = "",
   )
   lines(indiff_points_main_t_unbal, col = "navy", lwd = 2)
   lines(indiff_points_main_t_pred,  col = "red3", lty = 2)
   lines(indiff_points_main_t_pred + indiff_points_diff_main_t_pred, col = "red3", lty = 2, lwd = 2)
   legend(x = 5.5, y = 15.5,
      legend = c(
          "Observed, unbalanced choice",
          "Observed, balanced choices",
          "Predicted, unbalanced choice",
          "Predicted, balanced choices"
      ),
      col = c("navy", "navy", "red3", "red3"),
      lty = c(1, 1, 2, 2),
      lwd = c(2, 1, 2, 1),
      cex = 0.9,
      box.lty = 0
   )
   title(
      ylab = bquote(
         "Willingness to work additional tasks:" ~ tilde(italic(x))[t] ~
         "and" ~ tilde(italic(x))[t] ~ "+" ~ tilde(italic(d))
      ),
      line = 2.5
   )
}
plot (
   L_grid,
   disu_red(L_grid, results[SSR_main_t_min_idx, "ρ_l"], results[SSR_main_t_min_idx, "ρ_f"]),
   type = 'l', col = 'navy', ylim = c(0, 1),
   ylab = "History-dependent utility weight"
)



####  ILLUSTRATION OF THE INTUITION  ####


# Figure C1 in the Supplementary Appendix

enum <- function(n) { paste0( "(", tolower( as.roman(n) ), ") " ) }
set_params <- function(fig_counter) {
   if(fig_counter == 1) {
      # (i) Focusing estimates, yields \tilde{d} = 37.7
      plot_title <<- paste0( enum(fig_counter), "Best fit of focusing" )
      α_fix   <<-     3.120
      ω_fix   <<-     0.880
      φ_fix   <<-    26.490
      ρ_l_fix <<-     0       # no history dependence
      ρ_f_fix <<-     0       # no history dependence
      δ_fix   <<-     0.998
      γ_fix   <<-     0.65    # focusing
      plot( L_grid, disu_red(L_grid, ρ_l_fix, ρ_f_fix), type = 'l', col = 'navy', ylim = c(0, 1) )
   }
   if(fig_counter == 2) {
      # (ii) Best fit of time-nonseparability
      plot_title <<-
         paste0(
            enum(fig_counter), "Best fit of time-nonseparability: requires extreme anti-discounting"
         )
      α_fix   <<-     2.130
      ω_fix   <<-     2.110
      φ_fix   <<-     6.290
      ρ_l_fix <<- -2710       # history dependence
      ρ_f_fix <<-    -0.370   # history dependence
      δ_fix   <<-     1.482
      γ_fix   <<-     0       # no focusing
      plot( L_grid, disu_red(L_grid, ρ_l_fix, ρ_f_fix), type = 'l', col = 'navy', ylim = c(0, 1) )
   }
   if(fig_counter == 3) {
      # (iii) Starting from focusing estimates, some learning
      plot_title <<- paste0( enum(fig_counter), "Weak learning" )
      α_fix   <<-     3.120
      ω_fix   <<-     0.880
      φ_fix   <<-    26.490
      ρ_l_fix <<- -2000       # history dependence
      ρ_f_fix <<-    -0.05    # history dependence
      δ_fix   <<-     0.998
      γ_fix   <<-     0       # no focusing
      plot( L_grid, disu_red(L_grid, ρ_l_fix, ρ_f_fix), type = 'l', col = 'navy', ylim = c(0, 1) )
   }
   if(fig_counter == 4) {
      # (iv) Starting from focusing estimates, strong learning such that \tilde{d} = 37.6
      plot_title <<- paste0( enum(fig_counter), "Strong learning" )
      α_fix   <<-     3.120
      ω_fix   <<-     0.880
      φ_fix   <<-    26.490
      ρ_l_fix <<- -2000       # history dependence
      ρ_f_fix <<-    -0.267   # history dependence
      δ_fix   <<-     0.998
      γ_fix   <<-     0       # no focusing
      plot( L_grid, disu_red(L_grid, ρ_l_fix, ρ_f_fix), type = 'l', col = 'navy', ylim = c(0, 1) )
   }
   if(fig_counter == 5) {
      # (v) Starting from focusing estimates, strong learning,
      # thwarted by concavity of the voucher utility function
      plot_title <<- paste0( enum(fig_counter), "Strong learning and concavity" )
      α_fix   <<-     3.120
      ω_fix   <<-     0.2
      φ_fix   <<-    26.490
      ρ_l_fix <<- -2000       # history dependence
      ρ_f_fix <<-    -0.267   # history dependence
      δ_fix   <<-     0.998
      γ_fix   <<-     0       # no focusing
      plot( L_grid, disu_red(L_grid, ρ_l_fix, ρ_f_fix), type = 'l', col = 'navy', ylim = c(0, 1) )
   }
   if(fig_counter == 6) {
      # (vi) Starting from Focusing estimates, strong learning, thwarted by discounting
      plot_title <<- paste0( enum(fig_counter), "Strong learning and anti-discounting" )
      α_fix   <<-     3.120
      ω_fix   <<-     0.880
      φ_fix   <<-    26.490
      ρ_l_fix <<- -2000       # history dependence
      ρ_f_fix <<-    -0.267   # history dependence
      δ_fix   <<-     1.33
      γ_fix   <<-     0       # no focusing
      plot( L_grid, disu_red(L_grid, ρ_l_fix, ρ_f_fix), type = 'l', col = 'navy', ylim = c(0, 1) )
   }
   if(fig_counter == 7) {
      # (vii) Focusing estimates, some exhaustion
      # (not included in the Supplementary Appendix)
      plot_title <<- paste0( enum(fig_counter), "Focusing in combination with some fatigue" )
      α_fix   <<-     3.120
      ω_fix   <<-     0.880
      φ_fix   <<-    21.99    # = 26.490 * 0.83
      ρ_l_fix <<- -2000       # history dependence
      ρ_f_fix <<-     0.05    # history dependence
      δ_fix   <<-     0.998
      γ_fix   <<-     0.65    # focusing
      plot( L_grid, disu_red(L_grid, ρ_l_fix, ρ_f_fix), type = 'l', col = 'navy', ylim = c(0, 1) )
   }
}

gen_PDFs = 0  # Set to 1 to generate PDFs of the plots
quartzFonts(
   custom.quartz = c(
      "Times New Roman", "Times New Roman Bold", "Times New Roman Italic", "Hiragino Mincho ProN W3"
   )  # abusing bolditalic to print symbols included in the "Hiragino Mincho ProN W3" font
)
par(family = "custom.quartz", lheight = 1, cex.lab = 1.2)
#par(family = "Times New Roman", lheight = 1, cex.lab = 1.2)

begin_PDF <- function(fig_counter) {
   if(gen_PDFs == 1) {
      CairoFonts(
         regular    = "Times New Roman:style=Regular",
         italic     = "Times New Roman:style=Italic",
         bold       = "Times New Roman:style=Bold",
         bolditalic = "Hiragino Mincho ProN W3:style=Regular",
            # abusing bolditalic to print symbols included in the Hiragino Mincho ProN W3 font
         symbol     = "Symbol"
      )
      CairoPDF(
         file = paste0("ExCalibr", fig_counter, ".pdf"),
         width = 9, height = 7, # size in inches
         pointsize = 14
      )
   }
}

end_PDF <- function(fig_counter) {
   if(gen_PDFs == 1) {
      dev.off()
   }
}

y_offset = 0

for(fig_counter in 1:7) {
   set_params(fig_counter)
   # plot ( L_grid, disu_red(L_grid, ρ_l_fix, ρ_f_fix), type = 'l', col = 'navy', ylim = c(0, 1) )
   indiff_points_t_try = seq(0, 300, 0.1)
   indiff_points_sim   = rep( NA, length(base_constants) )
   for (t in 1:length(base_constants)) {
      Delta_U_vec =
         abs(
            utility_bal_complete_A(t, indiff_points_t_try, α_fix, ω_fix, φ_fix, ρ_l_fix, ρ_f_fix, γ_fix, δ_fix) -
            utility_bal_complete_B(t, indiff_points_t_try, α_fix, ω_fix, φ_fix, ρ_l_fix, ρ_f_fix, γ_fix, δ_fix)
         )
      min_idx = which(Delta_U_vec == min(Delta_U_vec), arr.ind = TRUE)
      indiff_points_sim[t] = indiff_points_t_try[ min_idx[1] ]
   }
   indiff_points_sim
   indiff_points_t_try_unbal = seq(-75, 75, 0.1)
   Delta_U_vec_unbal =
      abs(
         utility_unbal_complete_A(
            indiff_points_sim, indiff_points_t_try_unbal, α_fix, ω_fix, φ_fix, ρ_l_fix, ρ_f_fix, γ_fix, δ_fix
         ) -
         utility_unbal_complete_B(
                               indiff_points_t_try_unbal, α_fix, ω_fix, φ_fix, ρ_l_fix, ρ_f_fix, γ_fix, δ_fix
         )
      )
   min_idx_unbal = which(Delta_U_vec_unbal == min(Delta_U_vec_unbal), arr.ind = TRUE)
   ( d_tilde = indiff_points_t_try_unbal[ min_idx_unbal[1] ] )
   ( indiff_points_sim_unbal = indiff_points_sim + d_tilde )
   {
      cat( "Simulated:", indiff_points_sim_unbal,    "-- avg.:", mean(indiff_points_sim_unbal),    "\n" )
      cat( "Real:     ", indiff_points_main_t_unbal, "-- avg.:", mean(indiff_points_main_t_unbal), "\n" )
      format_number <- function(x, n) {
         if(x < 0) {
            mstring = paste0( "−", formatC( abs(x), digits = n, format = "f" ) )
         } else {
            mstring = formatC( abs(x), digits = n, format = "f" )
         }
         return(mstring)
      }
      if(ρ_f_fix < 0) { ρ_f_string = paste0("−", abs(ρ_f_fix)) } else { ρ_f_string = paste0(ρ_f_fix) }
      current_plot <- function() {
         plot(
            y_offset + indiff_points_main_t_unbal, col = "navy", type = "l", lwd = 2,
            ylim = c(0, 200),
            xlab = bquote( "Workday" ~ italic(t) ),
            ylab = "",
            main =
               bquote(
                  atop(
                     bold(.(plot_title)),
                     italic(δ) ~ "=" ~ .(format_number(δ_fix, 3)) * "," ~
                     italic(α) ~ "=" ~ .(format_number(α_fix, 2)) * "," ~
                     italic(ω) ~ "=" ~ .(format_number(ω_fix, 2)) * "," ~
                     italic(γ) ~ "=" ~ .(format_number(γ_fix, 2)) * "," ~
                     italic(ρ)[l] ~ "=" ~ .(format_number(ρ_l_fix, 0)) * "," ~
                     italic(ρ)[f] ~ "=" ~ .(format_number(ρ_f_fix, 3)) ~
                     ~ bolditalic("⇒") ~ ~
                     tilde(italic(d)) ~ "=" ~ .(format_number(d_tilde, 2))
                  )
               ),
         )
         title( ylab =
            bquote(
               "Willingness to work additional tasks:" ~ tilde(italic(x))[t] ~
               "and" ~ tilde(italic(x))[t] ~ "+" ~ tilde(italic(d))
            ), line = 2.75
         )
         lines(y_offset + indiff_points_sim_unbal, col = "red3", lty = 2, lwd = 2)
         lines(y_offset + indiff_points_main_t, col = "navy", lty = 1)
         lines(y_offset + indiff_points_sim, col = "red3",  lty = 2)
         legend(x = 1, y = 200,
             legend = c(
                "Observed, unbalanced choice",
                "Observed, balanced choices",
                "Predicted, unbalanced choice",
                "Predicted, balanced choices"
             ),
             col = c("navy", "navy", "red3", "red3"),
             lty = c(1, 1, 2, 2),
             lwd = c(2, 1, 2, 1),
             cex = 0.9,
             box.lty = 0
         )
      }
      begin_PDF(fig_counter)
      current_plot()
      end_PDF(fig_counter)
      if(gen_PDFs == 0) {
         current_plot()
         #readline(prompt="Press [enter] to continue")
      }
   }
   cat( "d =", indiff_points_t_try_unbal[ min_idx_unbal[1] ], "\n\n" )
   cat(
      "SSR =",
      sum(
         (indiff_points_sim       - indiff_points_main_t      )^2 +
         (indiff_points_sim_unbal - indiff_points_main_t_unbal)^2
      ),
      "\n\n"
   )
}

```

### `Consumption Experiment/Stata/Consumption_Experiment figures.do`
```stata
**************************************************************************************
**  Stata do-file for Dertwinkel-Kalt, Gerhardt, Riener, Schwerter, and Strang:     **
**  “Concentration Bias in Intertemporal Choice”, Review of Economic Studies, 2021  **
**************************************************************************************


clear all
clear matrix
set more off

import delimited Consumption_Experiment.csv, clear
// id_stage2:
// indifference point in the unbalanced trade-off
// as deviation from the point prediction of standard discounting
// (absolute measure of concentration bias, $\tilde{d}^$)
// qe_ard:
// quantitative effect, average relative deviation
// (relative measure of concentration bias, $\tilde{d}^\textup{rel}$)
// qe_rad:
// quantitative effect, relative average deviation
// (alternative relative measure of concentration bias, $\tilde{d}^\textup{rel, alt}$)

graph set window fontface "Times New Roman"



*****************
**  MAIN TEXT  **
*****************


** Figure 3 **

* Relative measure of concentration bias $\tilde{d}^\textup{rel}$
hist qe_ard if treatment == 1 & pap_sample == 1 & dispersed == 0 & pizza == 1, ///
	frac width(0.01) start(-.25) ///
	title("") ///
	yscale(range(0 0.07)) ///
	fysize(50) ///
	xscale(range(-0.2 0.8 0.2)) ///
	ytitle("Fraction of subjects", margin(medium) alignment(middle)) ///
	xtitle(Relative measure of concentration bias) ///
	ylabel(0(.02)0.07) ///
	graphregion(color(white)) ///
	xsize(2) ysize(1) ///
	bgcolor(white) ///
	blcolor(white) ///
	bfcolor("0 0 128") ///
	lwidth(0.1)



******************************
**  SUPPLEMENTARY APPENDIX  **
******************************


** Figure A5 **

* Relative measure of concentration bias $\tilde{d}^\textup{rel}$,
* including those subjects that were excluded in the main sample
hist qe_ard if treatment == 1 & dispersed == 0 & pizza == 1, ///
	frac width(0.01) start(-.25) ///
	title("") ///
	yscale(range(0 0.07)) ///
	fysize(50) ///
	xscale(range(-0.2 0.8 0.2)) ///
	ytitle("Fraction of subjects", margin(medium) alignment(middle)) ///
	xtitle(Relative measure of concentration bias) ///
	ylabel(0(.02)0.07) ///
	graphregion(color(white)) ///
	xsize(2) ysize(1) ///
	bgcolor(white) ///
	blcolor(white) ///
	bfcolor("0 0 128") ///
	lwidth(0.1)


** Figure A6 **

* Alternative relative measure of concentration bias $\tilde{d}^\textup{rel, alt}$
hist qe_rad if treatment == 1 & pap_sample == 1 & dispersed == 0 & pizza == 1, ///
	frac width(0.01) start(-.25) ///
	title("") ///
	yscale(range(0 0.07)) ///
	fysize(50) ///
	xscale(range(-0.2 0.8 0.2)) ///
	ytitle("Fraction of subjects", margin(medium) alignment(middle)) ///
	xtitle(Relative measure of concentration bias) ///
	ylabel(0(.02)0.07) ///
	graphregion(color(white)) ///
	xsize(2) ysize(1) ///
	bgcolor(white) ///
	blcolor(white) ///
	bfcolor("0 0 128") ///
	lwidth(0.1)


** Figure A7 **

* Absolute measure of concentration bias $\tilde{d}^$
hist avg_id_stage2 if treatment == 1 & pap_sample == 1 & dispersed == 0 & pizza == 1, ///
	frac width(1) start(-30) ///
	title("") ///
	yscale(range(0 / .06)) ///
	fysize(50) ///
	xscale(range(0 / 99)) ///
	ytitle("Fraction of subjects", margin(medium) alignment(middle)) ///
	xtitle(Absolute measure of concentration bias) ///
	ylabel(0(.02)0.06) ///
	xlabel(-20(20)99) ///
	graphregion(color(white)) ///
	xsize(2) ysize(1) ///
	bgcolor(white) ///
	blcolor(white) ///
	bfcolor("0 0 128") ///
	lwidth(0.1)

```

## How to run a script

Write each script to a file under the output directory, then run it with
exactly this command (the data directory is mounted read-only at its own
path; nothing else from the host is visible; `$SCRIPT` is the absolute path of
the script you wrote):

    SCRIPT=<repo>/benchmark/reproductions/dertwinkel-kalt-2022-concentration-bias/seeded/2026-10-22-a/script.R   # or <repo>/benchmark/reproductions/dertwinkel-kalt-2022-concentration-bias/seeded/2026-10-22-a/attempt-<n>/script.R
    docker run --rm --label retally.run=claude-code-dertwinkel-kalt-2022-concentration-bias-seeded-2026-10-22-a --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/seeded/2026-10-22-a/mount/dertwinkel_kalt_2022_concentration_bias:<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/seeded/2026-10-22-a/mount/dertwinkel_kalt_2022_concentration_bias:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R > "$(dirname "$SCRIPT")/stdout.txt" 2> "$(dirname "$SCRIPT")/stderr.txt"; echo "exit code: $?"

The sandbox time limit is 300 seconds (memory 4g, 1.0 CPU).  Wrap the
command in a timeout of that many seconds: prefix it with
`perl -e 'alarm shift; exec @ARGV' 300` (or `gtimeout 300` if installed;
macOS has no `timeout`).  If the timeout fires, stop the container with
`docker ps -q --filter label=retally.run=claude-code-dertwinkel-kalt-2022-concentration-bias-seeded-2026-10-22-a | xargs docker kill` and treat the
run as a crash (exit code 124).

## Output contract

The output directory `<repo>/benchmark/reproductions/dertwinkel-kalt-2022-concentration-bias/seeded/2026-10-22-a` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/dertwinkel-kalt-2022-concentration-bias/seeded/2026-10-22-a/
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

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/dertwinkel-kalt-2022-concentration-bias/seeded/2026-10-22-a`.
