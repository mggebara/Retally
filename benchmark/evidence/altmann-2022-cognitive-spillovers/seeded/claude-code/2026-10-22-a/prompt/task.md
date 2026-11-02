# Retally reproduction task: altmann-2022-cognitive-spillovers (seeded, run 2026-10-22-a)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `altmann-2022-cognitive-spillovers`, mode `seeded`, run `2026-10-22-a`
- Paper: Interventions and Cognitive Spillovers
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a/mount/altmann_2022_cognitive_spillovers`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a/mount/altmann_2022_cognitive_spillovers` as data, and `<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a/paper.txt` as
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

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Claims to Reproduce
1. choice_quality_intervention_t2_col1: 0.107 (change in the probability of correctly solving the decision task) [type: coefficient]
   Location: Table 2, Panel (a) Choice quality, column 1, Intervention
   Context: Table 2 ("Behavior in the targeted choice domain"), Panel (a), column 1. Lab experiment, subjects with scarce cognitive resources (the demanding background task of memorising a seven-digit number) in the Baseline, Directed Attention and Forced Choice environments, pooled over the decision-task payoff schemes and both experiment waves; the Ample-resources condition is not part of this table. OLS of an indicator equal to 1 if the subject correctly solves the decision task in a given round (one observation per subject and round of the main part) on Intervention, an indicator for being in Directed…
2. choice_quality_intervention_t2_col2: 0.11 (change in the probability of correctly solving the decision task) [type: coefficient]
   Location: Table 2, Panel (a) Choice quality, column 2, Intervention
   Context: Table 2, Panel (a), column 2: the column 1 regression (decision-task choice quality on the Intervention indicator, same subject-round sample) with controls: subjects' age, gender, field of study, high school GPA and last high-school math grade, ability in the background and the decision task (measured in the practice parts), perceived multitasking ability, and indicator variables for the subject's assigned payoff scheme and experiment wave. Robust standard errors clustered at the subject level.
3. default_adherence_intervention_t2_col5: -0.217 (change in the probability of choosing the default option) [type: coefficient]
   Location: Table 2, Panel (b) Default adherence, column 5, Intervention
   Context: Table 2, Panel (b), column 5. Same sample as Panel (a). OLS of an indicator equal to 1 if the subject's choice in the decision task in a given round coincides with the (choice alternative corresponding to the) default option, on the Intervention indicator (Directed Attention or Forced Choice vs. Baseline). No controls. Robust standard errors clustered at the subject level.
4. default_adherence_intervention_t2_col6: -0.219 (change in the probability of choosing the default option) [type: coefficient]
   Location: Table 2, Panel (b) Default adherence, column 6, Intervention
   Context: Table 2, Panel (b), column 6: the default-adherence regression of column 5 with the control set of column 2 (age, gender, field of study, high school GPA, last math grade, ability in both tasks, perceived multitasking ability, payoff-scheme and experiment-wave indicators). Robust standard errors clustered at the subject level.
5. default_adherence_directed_attention_t2_col7: -0.137 (change in the probability of choosing the default option) [type: coefficient]
   Location: Table 2, Panel (b) Default adherence, column 7, Directed Attention
   Context: Table 2, Panel (b), column 7. Default adherence (indicator that the round's choice coincides with the default option) regressed on separate indicators for the Directed Attention and Forced Choice environments, Baseline omitted; this is the Directed Attention coefficient. No controls; robust standard errors clustered at the subject level.
6. default_adherence_forced_choice_t2_col7: -0.3 (change in the probability of choosing the default option) [type: coefficient]
   Location: Table 2, Panel (b) Default adherence, column 7, Forced Choice
   Context: Table 2, Panel (b), column 7: the Forced Choice coefficient of the same regression (default adherence on Directed Attention and Forced Choice indicators, Baseline omitted, no controls, robust standard errors clustered by subject). In Forced Choice the decision task has no preselected option, so "default adherence" means choosing the alternative that is the default in the other environments.
7. background_quality_intervention_lab_t3_col1: -0.028 (change in the probability of correctly solving the background task) [type: coefficient]
   Location: Table 3, Lab experiment, column 1, Intervention
   Context: Table 3 ("Cognitive spillovers"), lab experiment, column 1: the paper's spillover result. Same lab sample as Table 2 (scarce cognitive resources; Baseline, Directed Attention, Forced Choice; all payoff schemes and both waves). OLS of an indicator equal to 1 if the subject correctly solves the background task (recalls the memorised number) in a given round, on the Intervention indicator. No controls; robust standard errors clustered at the subject level.
8. background_quality_intervention_lab_t3_col2: -0.038 (change in the probability of correctly solving the background task) [type: coefficient]
   Location: Table 3, Lab experiment, column 2, Intervention
   Context: Table 3, lab experiment, column 2: the column 1 background-task regression with the control set of Table 2 (age, gender, field of study, high school GPA, last math grade, ability in both tasks, perceived multitasking ability, payoff-scheme and experiment-wave indicators). Robust standard errors clustered at the subject level.
9. memory_intervention_online_t3_col5: -0.114 (change in the fraction of pairs uncovered in the Memory game) [type: coefficient]
   Location: Table 3, Online experiment, column 5, Intervention
   Context: Table 3, online experiment, column 5. In the online experiment the background task is a Memory game played alongside the decision task. OLS of the fraction of pairs a subject uncovers in the Memory game in a given round (one observation per subject and round) on the Intervention indicator (intervention vs. baseline condition of the online experiment). No controls; standard errors clustered at the subject level.
10. payoff_share_intervention_t4_col1: 0.006 (change in the share of the maximally attainable payoff) [type: coefficient]
   Location: Table 4, Payoff share, column 1, Intervention
   Context: Table 4 ("Effect of interventions on overall payoffs"), column 1: the paper's net-zero result. Same lab sample as Tables 2 and 3. OLS of the subject's realised share of the maximally attainable overall payoff (decision task plus background task) in the subject's treatment, calculated at the subject-round level, on the Intervention indicator. No controls; robust standard errors clustered at the subject level. Not statistically significant.
11. n_obs_lab_tables_2_to_4: 12160.0 (observations (subject-rounds, lab experiment)) [type: other]
   Location: Tables 2-4, N (every lab-experiment column)
   Context: Number of observations (subject x round) in the lab-experiment regressions of Tables 2, 3 (columns 1-4) and 4: subjects with scarce cognitive resources in the three decision environments, every round of the main part.
12. n_subjects_lab_tables_2_to_4: 608.0 (subjects (clusters)) [type: other]
   Location: Tables 2-4, No. Subjects (lab-experiment columns)
   Context: Number of subjects, which is also the number of clusters, in the lab-experiment regressions of Tables 2, 3 (columns 1-4) and 4.
13. memory_intervention_online_t3_col6: -0.113 (change in the fraction of pairs uncovered in the Memory game) [type: coefficient]
   Location: Table 3, Online experiment, column 6, Intervention
   Context: Table 3, online experiment, column 6: the column 5 Memory-game regression (fraction of pairs uncovered per subject and round on the Intervention indicator) with the online experiment's controls: subjects' age, gender, and screen size. Standard errors clustered at the subject level.

## Dataset Information
Name: altmann_2022_cognitive_spillovers
Local path: <repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a/mount/altmann_2022_cognitive_spillovers
File format: csv
Files in the dataset directory (paths relative to the local path above):
- ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_replication.dta (3.7 MB) — 17840 rows, 46 columns: payoff, Attention, round, ability_task, Treatment_intervention, payoff_share, q_math_grade, q_math_grade_cat, ability_load, Treatment_Environment, q_subject, q_abitur_grade, q_gender, payoff_share_mean, high_task_difficulty, Treatment_Incentives_Baseline_sc, default_correct_choice, diff_choice_second, subject_id, subject_cat, q_abitur_grade_quartile, q_abitur_grade_cat, attention_mean, attention_positive_mean, perc_multitasking_1, perc_multitasking_2, perc_multitasking_1_easy…
- ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_long_mturk.dta (217.0 KB) — 5472 rows, 12 columns: round, memory, gender, Treatment_intervention, payoff_share, math_task_correct, subject_id, passive_choice, math_time, age, window_height1, window_width1
- ReplicationPackage/EmpiricalAnalysis/dofiles/4_1_Allocation_Attention.do (10.2 KB)
- ReplicationPackage/EmpiricalAnalysis/dofiles/4_1_Passive_Behavior.do (9.9 KB)
- ReplicationPackage/EmpiricalAnalysis/dofiles/4_2_Cognitive_Spillover.do (12.3 KB)
- ReplicationPackage/EmpiricalAnalysis/dofiles/4_2_Interventions_targeted_domain.do (12.1 KB)
- ReplicationPackage/EmpiricalAnalysis/dofiles/4_3_Payoffs_And_Efficiency.do (10.2 KB)
- ReplicationPackage/EmpiricalAnalysis/dofiles/Supplementary_Material_Randomization_Check_table.do (4.7 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/_/_eststo.ado (813 B)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/_/_eststo.hlp (10 B)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/_/_gpp.ado (825 B)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/_/_oaxaca.ado (49.6 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/b/binscatter.ado (30.9 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/b/binscatter.sthlp (17.3 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/backup.trk (12.3 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/c/cdfplot.ado (4.2 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/c/cdfplot.hlp (4.0 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/c/coefplot.ado (119.3 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/c/coefplot.sthlp (69.8 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/e/estadd.ado (76.2 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/e/estadd.hlp (35.0 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/e/estout.ado (159.9 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/e/estout.hlp (104.5 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/e/estpost.ado (56.8 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/e/estpost.hlp (57.8 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/e/eststo.ado (9.6 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/e/eststo.hlp (11.0 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/e/esttab.ado (45.7 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/e/esttab.hlp (35.8 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/figout.ado (2.3 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/figout.hlp (5.0 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/fmm.ado (17.2 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/fmm.hlp (8.2 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/fmm_gamma_lf.ado (7.0 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/fmm_gamma_p.ado (2.5 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/fmm_lognormal_lf.ado (6.9 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/fmm_lognormal_p.ado (2.4 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/fmm_negbin1_lf.ado (7.5 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/fmm_negbin1_p.ado (2.9 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/fmm_negbin2_lf.ado (7.5 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/fmm_negbin2_p.ado (3.0 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/fmm_normal_lf.ado (6.9 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/fmm_normal_p.ado (2.4 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/fmm_poisson_lf.ado (4.5 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/fmm_poisson_p.ado (2.4 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/fmm_postestimation.hlp (4.3 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/fmm_studentt_lf.ado (7.5 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/f/fmm_studentt_p.ado (2.4 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/g/gammareg_lf.ado (992 B)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/g/glcurve.ado (6.3 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/g/glcurve.hlp (9.7 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/g/grc1leg.ado (3.2 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/g/grc1leg.hlp (3.9 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/n/normalreg_lf.ado (819 B)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/o/oaxaca.ado (9.6 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/o/oaxaca.hlp (15.2 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/q/quantil2.ado (3.0 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/q/quantil2.hlp (2.2 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/s/s1_grey_color.scheme (211 B)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/s/s1color_black_gray.scheme (143 B)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/s/strdist.ado (4.5 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/s/strdist.sthlp (2.2 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/s/studenttreg_lf.ado (1.3 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/stata.trk (13.2 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/z/ztree2stata.ado (5.0 KB)
- ReplicationPackage/EmpiricalAnalysis/library/stata/ado_ext/plus/z/ztree2stata.hlp (6.3 KB)
- ReplicationPackage/EmpiricalAnalysis/master.do (1.5 KB)
- ReplicationPackage/EmpiricalAnalysis/out/4_1_Allocation_Attention.log (33.7 KB)
- ReplicationPackage/EmpiricalAnalysis/out/4_1_Passive_Behavior.log (76.9 KB)
- ReplicationPackage/EmpiricalAnalysis/out/4_2_Cognitive_Spillover.log (97.4 KB)
- ReplicationPackage/EmpiricalAnalysis/out/4_2_Interventions_targeted_domain.log (121.5 KB)
- ReplicationPackage/EmpiricalAnalysis/out/4_3_Payoffs_And_Efficiency.log (64.8 KB)
- ReplicationPackage/EmpiricalAnalysis/out/Randomization_Check.log (27.7 KB)
- ReplicationPackage/EmpiricalAnalysis/out/figure2.png (334.1 KB)
- ReplicationPackage/EmpiricalAnalysis/out/figure3a.png (187.8 KB)
- ReplicationPackage/EmpiricalAnalysis/out/figure3b.png (202.2 KB)
- ReplicationPackage/EmpiricalAnalysis/out/figure4.png (172.1 KB)
- ReplicationPackage/EmpiricalAnalysis/out/figure5.png (169.3 KB)
- ReplicationPackage/EmpiricalAnalysis/out/figure6.png (169.6 KB)
- ReplicationPackage/EmpiricalAnalysis/out/figure7.png (177.7 KB)
- … and 166 more files (listing truncated)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a/mount/altmann_2022_cognitive_spillovers' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
Installed packages (no network; nothing else can be installed): jsonlite, fixest, lfe, AER, ivreg, plm, estimatr, lme4, quantreg, car, sandwich, lmtest, clubSandwich, multiwayvcov, marginaleffects, MatchIt, optmatch, CBPS, WeightIt, cobalt, did, rdrobust, rddensity, Synth, modelsummary, stargazer, texreg, broom, tidyverse, dplyr, tidyr, readr, stringr, lubridate, data.table, haven, readxl, janitor, zoo, ggplot2, ggridges, ggrepel, gridExtra, cowplot, gtable, extrafont, sf, MASS, nnet, survival, splines, Matrix, boot, stats, utils.
Prefer fixest for fixed effects, IV and clustered SEs; use the other installed packages where the paper's method calls for them.
Set a deterministic seed with ``set.seed(42)`` for any randomness.
Do NOT access the internet; the container runs with --network none.
Do NOT shell out via system() / system2().
Emit RESULT:<name>=<value> lines to stdout at the end via cat().

## Original Replication Scripts
The replication package (the dataset directory) ships the authors' own analysis scripts, reproduced below.  These are the GROUND TRUTH for the exact estimating equation, variable names, sample restrictions, fixed effects, and standard-error clustering — follow them over anything reconstructed from the methodology summary, and prefer them over the paper's text where the two disagree.  Your job is to write R code that implements the SAME SPECIFICATION: translate what the scripts estimate, do not transliterate their syntax line by line (a Stata .do file's regression, e.g. `reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the equivalent fixest::feols() call in R).  Keep only the parts that produce the specific claims being reproduced; skip figure construction and unrelated robustness checks.  The scripts' data-file paths refer to the package's internal layout — resolve them against the dataset directory listed under Dataset Information.

Stata-to-fixest sample matching: feols() drops fixed-effect singletons by default, but Stata's `reg y x i.fe` / `xi:` dummies keep them.  Pass `fixef.rm = "none"` to every feols() call that has fixed effects, otherwise the observation count and the robust SEs drift from the paper's.  Stata's `, r` / `vce(robust)` is `vcov = "hetero"`.

### `ReplicationPackage/EmpiricalAnalysis/master.do`
```stata
* Add Path to your project root, i.e. to the folder where the replication package is located.
global PROJECT_ROOT "<home>/"



* Do not change the next lines
* These lines generate the correct globals to write and read from the correct PATH (depending on your Project Root above)
sysdir set PLUS "${PROJECT_ROOT}EmpiricalAnalysis/library/stata/ado_ext/plus/"
global PATH_DOFILES "${PROJECT_ROOT}EmpiricalAnalysis/dofiles"
global PATH_IN_DATA "${PROJECT_ROOT}EmpiricalAnalysis/original_data/"
global PATH_IN_DATA "${PROJECT_ROOT}EmpiricalAnalysis/original_data/"
global PATH_OUT "${PROJECT_ROOT}EmpiricalAnalysis/out"



// Generate Output folder, if it does not exist
cap mkdir "$PATH_OUT



// global definitions for controls of regression models across do files
global Incentive_control "i.Treatment_Incentives"
global Wave_control "i.original_lab"
global Controls "q_age i.q_gender i.perc_multitasking_1_easy  perc_multitasking_2  i.subject_cat  i.q_abitur_grade_cat i.q_math_grade_cat"
global Ability_control "c.(ability_task ability_load)##i.original_lab"

/* 
* Set graph scheme for right colors
set scheme s1mono */

cap log close
do "${PATH_DOFILES}/4_1_Allocation_Attention.do"
do "${PATH_DOFILES}/4_1_Passive_Behavior.do"
do "${PATH_DOFILES}/4_2_Interventions_targeted_domain.do"
do "${PATH_DOFILES}/4_2_Cognitive_Spillover.do"
do "${PATH_DOFILES}/4_3_Payoffs_And_Efficiency.do"

*Supplemenatary Material only
do "${PATH_DOFILES}/Supplementary_Material_Randomization_Check_table.do"
```

### `ReplicationPackage/EmpiricalAnalysis/dofiles/4_2_Interventions_targeted_domain.do`
```stata
/*
*/

log using `"${PATH_OUT}/4_2_Interventions_targeted_domain.log"', replace

use "${PATH_IN_DATA}/formatted_data_replication.dta", clear





tabstat summation_correct_mean if  Treatment_Incentives!=4, by(Treatment_Environment) stats(mean n)

****************************************************************
**** Table 2, Decision Task + Default Adherence
****************************************************************

reg summation_correct i.Treatment_intervention if Treatment_Incentives!=4, robust cluster(subject_id)
eststo force_plain
reg summation_correct i.Treatment_intervention ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4, robust cluster(subject_id)
eststo force_all_controls_ability

reg summation_correct i.Treatment_Environment if Treatment_Incentives!=4, robust cluster(subject_id)
test 2.Treatment_Environment=3.Treatment_Environment
estadd scalar p_treatments = r(p)
eststo plain

reg summation_correct i.Treatment_Environment ${Incentive_control}  ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4, robust cluster(subject_id)
test 2.Treatment_Environment=3.Treatment_Environment
estadd scalar p_treatments = r(p)
eststo all_controls_ability

reg default_followed i.Treatment_intervention if Treatment_Incentives!=4, robust cluster(subject_id)
eststo passive_force_plain
reg default_followed i.Treatment_intervention ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4, robust cluster(subject_id)
eststo passive_force_controls

reg default_followed i.Treatment_Environment if Treatment_Incentives!=4, robust cluster(subject_id)
test 2.Treatment_Environment=3.Treatment_Environment
estadd scalar p_treatments = r(p)
eststo passive_plain

reg default_followed i.Treatment_Environment ${Incentive_control}  ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4, robust cluster(subject_id)
test 2.Treatment_Environment=3.Treatment_Environment
estadd scalar p_treatments = r(p)
eststo passive_controls

esttab  force_plain  force_all_controls_ability ///
    plain   all_controls_ability ///
     passive_force_plain passive_force_controls ///
     passive_plain  passive_controls ///
    using `"${PATH_OUT}/table2.tex"', replace ///
    b(%5.3f) se(%5.3f) ///
    order(*Treatment_intervention* *Treatment_Environment*) ///
    star(* .1 ** .05 *** .01) ///
    label booktabs nonotes ///
    nodepvars nobase ///
    nomtitles ///
    mgroups("Panel (a): Choice Quality" "Panel (b): Default Adherence" , ///
    pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
    stats(N N_clust r2 p_treatments, fmt(%18.0g %18.0g %5.3f %5.3f) labels(`"N"' "No. Subjects"  "\(R^2\)" "\textsc{Directed}=\textsc{Forced}")) ///
    indicate("Controls = *original* *Incentives* *ability* *age* *gender* *perc_multitasking* *subject_cat*  *q_abitur_grade_cat* *q_math_grade_cat*")






****************************************************************
****  Heterogenous Effects: Incentives
****************************************************************

reg summation_correct i.b1.Treatment_Incentives_Int_sc i.bn.Treatment_Incentives i.Treatment_intervention#i.Treatment_Incentives if Treatment_Incentives!=4, robust cluster(subject_id)
eststo force_plain

reg summation_correct i.b1.Treatment_Incentives_Int_sc i.bn.Treatment_Incentives i.Treatment_intervention#i.Treatment_Incentives  ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4, robust cluster(subject_id)
eststo force_all_controls_ability

reg summation_correct i.b1.Treatment_Incentives_Int_sc i.bn.Treatment_Incentives i.Treatment_Environment#i.Treatment_Incentives if Treatment_Incentives!=4, robust cluster(subject_id)
eststo plain

reg summation_correct i.b1.Treatment_Incentives_Int_sc i.bn.Treatment_Incentives i.Treatment_Environment#i.Treatment_Incentives   ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4, robust cluster(subject_id)
eststo all_controls_ability

reg default_followed i.b1.Treatment_Incentives_Int_sc i.bn.Treatment_Incentives i.Treatment_intervention#i.Treatment_Incentives if Treatment_Incentives!=4, robust cluster(subject_id)
eststo passive_force_plain
reg default_followed i.b1.Treatment_Incentives_Int_sc i.bn.Treatment_Incentives i.Treatment_intervention#i.Treatment_Incentives  ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4, robust cluster(subject_id)
eststo passive_force_controls

reg default_followed i.b1.Treatment_Incentives_Int_sc i.bn.Treatment_Incentives i.Treatment_Environment#i.Treatment_Incentives if Treatment_Incentives!=4, robust cluster(subject_id)
eststo passive_plain

reg default_followed i.b1.Treatment_Incentives_Int_sc i.bn.Treatment_Incentives i.Treatment_Environment#i.Treatment_Incentives   ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4, robust cluster(subject_id)
eststo passive_controls

esttab  force_plain  force_all_controls_ability ///
    plain   all_controls_ability ///
     passive_force_plain passive_force_controls ///
     passive_plain  passive_controls ///
    using `"${PATH_OUT}/tableO_2.tex"', replace ///
    b(%5.3f) se(%5.3f) ///
    order(*Treatment_intervention* *Treatment_Environment*) ///
    star(* .1 ** .05 *** .01) ///
    label booktabs nonotes ///
    nodepvars nobase noomit ///
    interaction("-") ///
    nomtitles ///
    mgroups("Panel (a): Choice Quality" "Panel (b): Default Adherence" , ///
    pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
    stats(N N_clust r2, fmt(%18.0g %18.0g %5.3f ) labels(`"N"' "No. Subjects"  "\(R^2\)")) ///
    indicate("Controls = *original*  *ability* *age* *gender* *perc_multitasking* *subject_cat*  *q_abitur_grade_cat* *q_math_grade_cat*")




****************************************************************
* Heterogenous Effects: Raven Score
****************************************************************

reg summation_correct i.raven_score_median i.Treatment_intervention i.Treatment_intervention#i.raven_score_median   if Treatment_Incentives!=4, robust cluster(subject_id)
eststo force_plain

reg summation_correct i.raven_score_median i.Treatment_intervention i.Treatment_intervention#i.raven_score_median   i.b3.Treatment_Incentives ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4, robust cluster(subject_id)
eststo force_all_controls_ability

reg summation_correct i.raven_score_median i.Treatment_Environment i.Treatment_Environment#i.raven_score_median if Treatment_Incentives!=4, robust cluster(subject_id)
eststo plain

reg summation_correct i.raven_score_median i.Treatment_Environment i.Treatment_Environment#i.raven_score_median ${Incentive_control}  ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4, robust cluster(subject_id)
eststo all_controls_ability

reg default_followed i.raven_score_median i.Treatment_intervention i.Treatment_intervention#i.raven_score_median   if Treatment_Incentives!=4, robust cluster(subject_id)
eststo passive_force_plain

reg default_followed i.raven_score_median i.Treatment_intervention i.Treatment_intervention#i.raven_score_median   ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4, robust cluster(subject_id)
eststo passive_force_controls

reg default_followed i.raven_score_median i.Treatment_Environment i.Treatment_Environment#i.raven_score_median if Treatment_Incentives!=4, robust cluster(subject_id)
eststo passive_plain

reg default_followed i.raven_score_median i.Treatment_Environment i.Treatment_Environment#i.raven_score_median ${Incentive_control}  ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4, robust cluster(subject_id)
eststo passive_controls

esttab  force_plain  force_all_controls_ability ///
    plain   all_controls_ability ///
     passive_force_plain passive_force_controls ///
     passive_plain  passive_controls ///
    using `"${PATH_OUT}/tableO_3.tex"', replace ///
    b(%5.3f) se(%5.3f) ///
    order(*Treatment_intervention* 2.Treatment_Environment* 3.Treatment_Environment*) ///
    star(* .1 ** .05 *** .01) ///
    label booktabs nonotes ///
    nodepvars nobase noomit ///
    nomtitles ///
    mgroups("Panel (a): Choice Quality" "Panel (b): Default Adherence" , ///
    pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
    stats(N N_clust r2, fmt(%18.0g %18.0g %5.3f ) labels(`"N"' "No. Subjects"  "\(R^2\)")) ///
    indicate("Controls = *original* *Incentives* *ability* *age* *gender* *perc_multitasking* *subject_cat*  *q_abitur_grade_cat* *q_math_grade_cat*")



****************************************************************
**** AMPLE
****************************************************************

reg default_followed i.Treatment_intervention if Treatment_Incentives==4, robust cluster(subject_id)
eststo def_force_plain
reg default_followed i.Treatment_intervention ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives==4, robust cluster(subject_id)
eststo def_force_all_controls
reg default_followed i.Treatment_Environment if Treatment_Incentives==4, robust cluster(subject_id)
test 2.Treatment_Environment=3.Treatment_Environment
estadd scalar p_treatments = r(p)
eststo def_plain
reg default_followed i.Treatment_Environment ${Incentive_control}  ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives==4, robust cluster(subject_id)
test 2.Treatment_Environment=3.Treatment_Environment
estadd scalar p_treatments = r(p)
eststo def_all_controls


reg summation_correct i.Treatment_intervention if Treatment_Incentives==4, robust cluster(subject_id)
eststo sum_force_plain
reg summation_correct i.Treatment_intervention ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives==4, robust cluster(subject_id)
eststo sum_force_all_controls
reg summation_correct i.Treatment_Environment if Treatment_Incentives==4, robust cluster(subject_id)
test 2.Treatment_Environment=3.Treatment_Environment
estadd scalar p_treatments = r(p)
eststo sum_plain
reg summation_correct i.Treatment_Environment ${Incentive_control}  ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives==4, robust cluster(subject_id)
test 2.Treatment_Environment=3.Treatment_Environment
estadd scalar p_treatments = r(p)
eststo sum_all_controls



reg load_correct i.Treatment_intervention if  Treatment_Incentives==4, robust cluster(subject_id)
eststo back_force_plain
reg load_correct i.Treatment_intervention ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} if  Treatment_Incentives==4, robust cluster(subject_id)
eststo back_force_all_controls
reg load_correct i.Treatment_Environment if  Treatment_Incentives==4, robust cluster(subject_id)
test 2.Treatment_Environment=3.Treatment_Environment
estadd scalar p_treatments = r(p)
eststo back_plain
reg load_correct i.Treatment_Environment ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} if  Treatment_Incentives==4, robust cluster(subject_id)
test 2.Treatment_Environment=3.Treatment_Environment
estadd scalar p_treatments = r(p)
eststo back_all_controls




esttab ///
    sum_force_plain sum_force_all_controls ///
    sum_plain sum_all_controls ///
    def_force_plain def_force_all_controls ///
    def_plain def_all_controls ///
    back_force_plain back_force_all_controls ///
    back_plain back_all_controls ///
    using `"${PATH_OUT}/tableO_7.tex"', replace ///
    b(%5.3f) se(%5.3f) ///
    star(* .1 ** .05 *** .01) ///
    label booktabs nonotes ///
    nodepvars nobase ///
    nomtitles ///
    mgroups("Choice Quality (Decision Task)" "Default Adherence" "Choice Quality (Background Task)" , ///
    pattern(1 0 0 0 1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
    stats(N N_clust r2 p_treatments, fmt(%18.0g %18.0g %5.3f %5.3f) labels(`"N"' "No. Subjects"  "\(R^2\)" "\textsc{Directed}=\textsc{Forced}")) ///
    indicate("Controls = *original* *Incentives* *ability* *age* *gender* *perc_multitasking* *subject_cat*  *q_abitur_grade_cat* *q_math_grade_cat* *age* *gender*")









log close

```

### `ReplicationPackage/EmpiricalAnalysis/dofiles/Supplementary_Material_Randomization_Check_table.do`
```stata
log using `"${PATH_OUT}/Randomization_Check.log"', replace


use "${PATH_IN_DATA}/formatted_data_replication.dta", clear
keep if round==1


set scheme s1color_black_gray

**********************************
* Little program to convert matrix
**********************************

cap program drop convert
program define convert, eclass
    matrix list `1'
    ereturn  scalar N=.
    ereturn matrix mean `1'
    ereturn local estimates_title="p-values"
end



* Generate variables specifallcy needed for balancing table

egen ability_load_std_1=std(ability_load) if original_lab==1
egen ability_task_std_1=std(ability_task) if original_lab==1

egen ability_load_std=std(ability_load) if original_lab==0
egen ability_task_std=std(ability_task) if original_lab==0

replace ability_load_std=ability_load_std_1 if original_lab==1
replace ability_task_std=ability_task_std_1 if original_lab==1
drop ability_load_std_1 ability_task_std_1

label var ability_task_std "Ability Decision Task (std.)"
label var ability_load_std "Ability Background Task (std.)"

bysort Treatment_Environment Treatment_Incentives: gen obs=_N
label var obs "N"


cap drop treatment_id
egen treatment_id=group(Treatment_Environment Treatment_Incentives )



* Write Balancing table; Different parts are appended after creating results via tabstat

qui file open table_out using `"${PATH_OUT}/tableO_1.tex"', write replace
file write table_out "   \begin{tabular}{l*{13}{c}}" _n
file write table_out "\toprule" _n
file close table_out

estimates clear

bysort Treatment_Environment: eststo: estpost tabstat ability_load_std ability_task_std  q_age q_gender economist perc_multitasking_2 perc_multitasking_1, by(Treatment_Incentives) nototal   statistics(mean sd) columns(statistics) listwise

* copy mean matrix such that p-values vector has the correct length etc.
matrix p_values=e(mean)
local i=0
foreach var of varlist ability_load_std ability_task_std  q_age q_gender economist perc_multitasking_2 perc_multitasking_1 {
    local i=1+`i'
    kwallis `var' , by(treatment_id)
    local p=chi2tail(`r(df)',`r(chi2_adj)')
    matrix p_values[1,`i']=`p'
}

matrix p_values=p_values[1,1..7]
matrix coleq p_values=p-value p-value p-value p-value p-value p-value

* Convert p-values to estimation result and store it
convert p_values
eststo p_values

esttab est*  p_values using `"${PATH_OUT}/tableO_1.tex"', ///
    main(mean %5.2f) aux(sd %5.2f) nostar unstack ///
    noobs nonote label append booktabs compress  ///
    nonumber  nomtitles frag ///
    mgroups("\textsc{Baseline}" "\textsc{Directed Attention}" "\textsc{Forced Choice}" "Kruskal-Wallis" , ///
    pattern(1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///



* As tabstat uses only observation with no missings, perform second part where only data from certain waves are available
estimates clear
bysort Treatment_Environment: eststo: estpost tabstat raven_score treatment_id, by(Treatment_Incentives) nototal   statistics(mean sd) columns(statistics) listwise

* copy mean matrix such that p-values vector has the correct length etc.
matrix p_values=e(mean)
local i=0
foreach var of varlist raven_score treatment_id{
    local i=1+`i'
    kwallis `var' , by(treatment_id)
    local p=chi2tail(`r(df)',`r(chi2_adj)')
    matrix p_values[1,`i']=`p'
}

matrix p_values=p_values[1,1..2]
matrix coleq p_values=p-value p-value

* Convert p-values to estimation result and store it
convert p_values
eststo p_values

esttab est*  p_values using `"${PATH_OUT}/tableO_1.tex"', ///
    append frag  ///
    drop(treatment_id) /// refcat(raven_score "\emph{2nd Wave only}", nolabel) nobaselevels ///
    main(mean %5.2f) aux(sd %5.2f) nostar unstack ///
    eqlabels(none) nolines ///
    noobs nonote label  booktabs compress  ///
    nomtitles nodepvar nonumber

estimates clear
bysort Treatment_Environment: eststo: estpost tabstat  original_lab treatment_id, by(Treatment_Incentives) nototal   statistics(mean sd) columns(statistics) listwise
esttab est*   using `"${PATH_OUT}/tableO_1.tex"', ///
    append frag  drop(treatment_id) ///
    main(mean %4.0g)  nostar unstack ///
    eqlabels(none) ///
    noobs nonote label  booktabs compress  ///
    nomtitles nodepvar nonumber

estimates clear
bysort Treatment_Environment: eststo: estpost tabstat obs  treatment_id, by(Treatment_Incentives) nototal   statistics(mean sd) columns(statistics) listwise
esttab est*   using `"${PATH_OUT}/tableO_1.tex"', ///
    append frag  drop(treatment_id) ///
    main(mean %5.0g)  nostar unstack ///
    eqlabels(none) ///
    noobs nonote label  booktabs compress  ///
    nomtitles nodepvar nonumber

qui file open table_out using `"${PATH_OUT}/tableO_1.tex"', write append
file write table_out "\bottomrule" _n
file write table_out "\end{tabular}" _n
file close table_out



log close





```

### `ReplicationPackage/EmpiricalAnalysis/dofiles/4_1_Allocation_Attention.do`
```stata
/* Do file creates Tables and Figures for first part of Section 4.1 of the paper and tables and figures referenced therein*/

log using `"${PATH_OUT}/4_1_Allocation_Attention.log"', replace

use "${PATH_IN_DATA}/formatted_data_replication.dta", clear


********* Descriptive Figues Attention Allocation

*Individual Decision level
cdfplot Attention if Treatment_Environment==1 ,by(Treatment_Incentives) opt1(lwidth(medthick medthick medthick medthick) lc(gs0 gs7 gs11 gs13) ///
    xtitle("attention (in sec.)")    ///
    legend(label(1 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-10") ///
           label(2 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-20")  ///
           label(3 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-40") ///
           label(4 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-A`=ustrunescape("\u1D0D")'`=ustrunescape("\u1D18")'`=ustrunescape("\u029F")'`=ustrunescape("\u1D07")'") ))  ///
    ytitle("Cumulative Frequency", margin(medium) height(3) size(medium)) xtitle("Attention (in sec.)", margin(medium) height(3) size(medium))
graph export `"${PATH_OUT}/figure2.png"', as(png) replace

* Individual average level
cdfplot attention_mean if Treatment_Environment==1 ,by(Treatment_Incentives) opt1(lwidth(medthick medthick medthick medthick) lc(gs0 gs7 gs11 gs13) ///
    xtitle("Attention (in sec.)")    ///
    legend(label(1 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-10") ///
    label(2 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-20")  ///
    label(3 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-40") ///
    label(4 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-A`=ustrunescape("\u1D0D")'`=ustrunescape("\u1D18")'`=ustrunescape("\u029F")'`=ustrunescape("\u1D07")'") ))  ///
    ytitle("Cumulative Frequency", margin(medium) height(3) size(medium)) xtitle("Attention (in sec.)", margin(medium) height(3) size(medium))
graph export `"${PATH_OUT}/figureO_1.png"', as(png) replace

*Individual Decision level; Low Raven Score
cdfplot Attention if Treatment_Environment==1 & raven_score_median==1,by(Treatment_Incentives) opt1(lwidth(medthick medthick medthick medthick) lc(gs0 gs7 gs11 gs13) ///
    xtitle("Attention (in sec.)")    ///
    legend(label(1 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-10") ///
    label(2 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-20")  ///
    label(3 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-40") ///
    label(4 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-A`=ustrunescape("\u1D0D")'`=ustrunescape("\u1D18")'`=ustrunescape("\u029F")'`=ustrunescape("\u1D07")'") ))  ///
    ytitle("Cumulative Frequency", margin(medium) height(3) size(medlarge)) xtitle("Attention (in sec.)", margin(medium) height(3) size(medlarge))
graph export `"${PATH_OUT}/figureB_1a.png"', as(png) replace

*Individual Decision level; High Raven Score
cdfplot Attention if Treatment_Environment==1 & raven_score_median==2,by(Treatment_Incentives) opt1(lwidth(medthick medthick medthick medthick) lc(gs0 gs7 gs11 gs13) ///
    xtitle("Attention (in sec.)")    ///
    legend(label(1 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-10") ///
    label(2 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-20")  ///
    label(3 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-40") ///
    label(4 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-A`=ustrunescape("\u1D0D")'`=ustrunescape("\u1D18")'`=ustrunescape("\u029F")'`=ustrunescape("\u1D07")'") ))  ///
    ytitle("Cumulative Frequency", margin(medium) height(3) size(medlarge)) xtitle("Attention (in sec.)", margin(medium) height(3) size(medlarge))
graph export `"${PATH_OUT}/figureB_1b.png"', as(png) replace



* Summary statistics and non-parametric tests for numbers reported in the text
tabstat Attention if Treatment_Environment ==1 , by(Treatment_Incentives) stats(mean n)

ksmirnov Attention if Treatment_Environment==1 & Treatment_Incentives==1 | Treatment_Incentives==4, by(Treatment_Incentives)

spearman attention_mean Treatment_Incentives if round==1 & Treatment_Environment==1

tabstat no_attention if Treatment_Environment ==1  , by(Treatment_Incentives) stats(mean n)

spearman  attention_positive_mean Treatment_Incentives if round==1 & Treatment_Environment==1


************Regression Table Average Attention, Extensive Margin + Choice Quality
reg Attention i.Treatment_Incentives_Baseline_sc if Treatment_Environment==1  , cluster(subject_id) robust
test 2.Treatment_Incentives_Baseline_sc=3.Treatment_Incentives_Baseline_sc
estadd scalar p_2_3 = r(p)
test 2.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
estadd scalar p_2_4 = r(p)
test 3.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
estadd scalar p_3_4 = r(p)
eststo plain_attention


reg Attention i.Treatment_Incentives_Baseline_sc ${Wave_control} ${Ability_control} ${Controls} if Treatment_Environment==1  , cluster(subject_id) robust
test 2.Treatment_Incentives_Baseline_sc=3.Treatment_Incentives_Baseline_sc
estadd scalar p_2_3 = r(p)
test 2.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
estadd scalar p_2_4 = r(p)
test 3.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
estadd scalar p_3_4 = r(p)
eststo all_control_attention

reg  no_attention i.Treatment_Incentives_Baseline_sc if Treatment_Environment==1  , cluster(subject_id) robust
test 2.Treatment_Incentives_Baseline_sc=3.Treatment_Incentives_Baseline_sc
estadd scalar p_2_3 = r(p)
test 2.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
estadd scalar p_2_4 = r(p)
test 3.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
estadd scalar p_3_4 = r(p)
eststo plain_attention_pos

reg  no_attention i.Treatment_Incentives_Baseline_sc ${Wave_control} ${Ability_control} ${Controls} if Treatment_Environment==1  , cluster(subject_id) robust
test 2.Treatment_Incentives_Baseline_sc=3.Treatment_Incentives_Baseline_sc
estadd scalar p_2_3 = r(p)
test 2.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
estadd scalar p_2_4 = r(p)
test 3.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
estadd scalar p_3_4 = r(p)
eststo all_control_attention_pos


*Regressions Decision Quality
reg summation_correct i.Treatment_Incentives_Baseline_sc if Treatment_Environment==1  , cluster(subject_id) robust
test 2.Treatment_Incentives_Baseline_sc=3.Treatment_Incentives_Baseline_sc
estadd scalar p_2_3 = r(p)
test 2.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
estadd scalar p_2_4 = r(p)
test 3.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
estadd scalar p_3_4 = r(p)
eststo plain_sum

reg summation_correct i.Treatment_Incentives_Baseline_sc ${Wave_control} ${Ability_control} ${Controls} if Treatment_Environment==1  , cluster(subject_id) robust
test 2.Treatment_Incentives_Baseline_sc=3.Treatment_Incentives_Baseline_sc
estadd scalar p_2_3 = r(p)
test 2.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
estadd scalar p_2_4 = r(p)
test 3.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
estadd scalar p_3_4 = r(p)
eststo all_control_sum


esttab plain_attention  all_control_attention ///
    plain_attention_pos  all_control_attention_pos     ///
    plain_sum  all_control_sum ///
    using `"${PATH_OUT}/tableB_1.tex"', replace ///
    b(%5.3f) se(%5.3f) ///
    order() ///
    star(* .1 ** .05 *** .01) ///
    label booktabs nonotes ///
    noomit nobase ///
    nomtitles ///
    mgroups("Avg. Attention" "Attention\,$=$\,0"  "Choice Quality", ///
    pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
    stats(N N_clust r2 p_2_3 p_2_4 p_3_4, fmt(%18.0g %18.0g %5.3f %5.3f) labels(`"N"' "No. Subjects" "\(R^2\)" "\textsc{Baseline-20}=\textsc{Baseline-40}" "\textsc{Baseline-20}=\textsc{Baseline-A.}" "\textsc{Baseline-40}=\textsc{Baseline-A.}")) ///
    indicate("Controls = *original* *ability* *age* *gender* *perc_multitasking* *subject_cat*  *q_abitur_grade_cat* *q_math_grade_cat*")



* Summary statistics and non-parametric tests for reported in the text

tabstat summation_correct_mean if Treatment_Environment ==1  , by(Treatment_Incentives) stats(mean n)

spearman  summation_correct_mean Treatment_Incentives_Baseline_sc if round==1 & Treatment_Environment==1


log close
```

### `ReplicationPackage/EmpiricalAnalysis/dofiles/4_1_Passive_Behavior.do`
```stata
/* Do file creates Tables and Figures for second part of Section 4.2 of the paper and tables and figures referenced therein*/


log using `"${PATH_OUT}/4_1_Passive_Behavior.log"', replace

use "${PATH_IN_DATA}/formatted_data_replication.dta", clear




tabstat default_followed if Treatment_Environment==1, by(Treatment_Incentives) stats(N mean)

spearman default_followed_mean Treatment_Incentives if round==1 & Treatment_Environment==1



* Overall Barchart Figure 3 (a)
forvalues i=1(1)4{
    reg default_followed i.Treatment_Incentives if Treatment_Environment==1  , cluster(subject_id) robust
    margins i.Treatment_Incentives if Treatment_Incentives==`i', post
    eststo plain_att_`i'
}

coefplot (plain_att_1, bcolor(gs0)) (plain_att_2, bcolor(gs7))  (plain_att_3, bcolor(gs11))  (plain_att_4, bcolor(gs13)) , vertical recast(bar) noci ///
    xlabel(1 "Baseline-10" 2 "Baseline-20" 3 "Baseline-40" 4 "Baseline- A.", labgap(3) labsize(medlarge)) ytitle("Default Adherence", margin(medium) height(3) size(medlarge)) ylabel(0(0.1)1,glcolor(gs13)) ///
    barwidth(0.75) graphregion(color(white)) bgcolor(white)   ///
    offset(0) ///
    coeflabels(,nolabels notick) ///
        legend(label(1 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-10") ///
           label(2 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-20")  ///
           label(3 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-40") ///
           label(4 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-A`=ustrunescape("\u1D0D")'`=ustrunescape("\u1D18")'`=ustrunescape("\u029F")'`=ustrunescape("\u1D07")'") )  ///
    groups(*Treatment_Incentives* = `"Default incorrect"', labcolor(white) labsize(medlarge))

graph export `"${PATH_OUT}/figure3a.png"', as(png) replace


* By Default correct Barchart Figure 3 (b)
forvalues j=1(1)4{
    forvalues i=0(1)1{
        reg default_followed i.Treatment_Incentives#i.default_correct_choice  if Treatment_Environment==1  , cluster(subject_id) robust
        margins i.Treatment_Incentives#i.default_correct_choice if default_correct_choice==`i' & Treatment_Incentives==`j', post
        eststo plain_att_`i'_`j'
    }
}

coefplot (plain_att_0_1, bcolor(gs0)) (plain_att_0_2, bcolor(gs7))  (plain_att_0_3, bcolor(gs11))  (plain_att_0_4, bcolor(gs13))   ///
         (plain_att_1_1, bcolor(gs0)) (plain_att_1_2, bcolor(gs7))  (plain_att_1_3, bcolor(gs11))  (plain_att_1_4, bcolor(gs13))   ///
          , offset(0) vertical recast(bar) noci ///
    coeflabels(,nolabels notick) ///
    ytitle("Default Adherence", margin(medium) height(3) size(medlarge)) ylabel(0(0.1)1,glcolor(gs13)) ///
    barwidth(0.75) graphregion(color(white)) bgcolor(white)   ///
        legend(order(1 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-10" ///
           2 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-20"  ///
           3 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-40" ///
           4 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'-A`=ustrunescape("\u1D0D")'`=ustrunescape("\u1D18")'`=ustrunescape("\u029F")'`=ustrunescape("\u1D07")'"))  ///
        nooffset groups(*0.default_correct_choice* = `"Default incorrect"' *1.default_correct_choice*  = "Default correct", labsize(medlarge))

graph export `"${PATH_OUT}/figure3b.png"', as(png) replace




*********************************************
*By default correct
*********************************************
tabstat default_followed if Treatment_Environment==1 & default_correct_choice==0, by(Treatment_Incentives) stats(N mean)
tabstat default_followed if Treatment_Environment==1 & default_correct_choice==1, by(Treatment_Incentives) stats(N mean)


*Default_followed_correct_mean is calculated using "bysort subject_id default_correct_choice:"; Round 1 Default is correct and therefore use mean from that round
spearman default_followed_correct_mean Treatment_Incentives if round==1 & Treatment_Environment==1
*Explanation see above, round 2 default happens to be false.
spearman default_followed_correct_mean Treatment_Incentives if round==2 & Treatment_Environment==1


******************************************************************************************
*By Raven
******************************************************************************************
tabstat default_followed if Treatment_Environment==1 & raven_score_median==1, by(Treatment_Incentives) stats(N mean)
tabstat default_followed if Treatment_Environment==1 & raven_score_median==2, by(Treatment_Incentives) stats(N mean)

spearman default_followed_mean Treatment_Incentives if round==1 &raven_score_median==1 & Treatment_Environment==1
spearman default_followed_mean Treatment_Incentives if round==1 &raven_score_median==2 & Treatment_Environment==1
spearman default_followed_mean Treatment_Incentives if round==1 &raven_score_quartiles==4 & Treatment_Environment==1













*Regression Table
reg default_followed i.Treatment_Incentives_Baseline_sc if Treatment_Environment==1  , cluster(subject_id) robust
test 2.Treatment_Incentives_Baseline_sc=3.Treatment_Incentives_Baseline_sc
estadd scalar p_2_3 = r(p)
test 2.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
estadd scalar p_2_4 = r(p)
test 3.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
estadd scalar p_3_4 = r(p)
eststo plain_default

reg default_followed i.Treatment_Incentives_Baseline_sc ${Wave_control} ${Ability_control} ${Controls} if Treatment_Environment==1 , cluster(subject_id) robust
test 2.Treatment_Incentives_Baseline_sc=3.Treatment_Incentives_Baseline_sc
estadd scalar p_2_3 = r(p)
test 2.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
estadd scalar p_2_4 = r(p)
test 3.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
estadd scalar p_3_4 = r(p)
eststo all_control_default

forvalues i=0(1)1{

    reg default_followed i.Treatment_Incentives_Baseline_sc if Treatment_Environment==1  & default_correct_choice==`i', cluster(subject_id) robust
    test 2.Treatment_Incentives_Baseline_sc=3.Treatment_Incentives_Baseline_sc
    estadd scalar p_2_3 = r(p)
    test 2.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
    estadd scalar p_2_4 = r(p)
    test 3.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
    estadd scalar p_3_4 = r(p)
    eststo plain_default_`i'

    reg default_followed i.Treatment_Incentives_Baseline_sc ${Wave_control} ${Ability_control} ${Controls} if Treatment_Environment==1 & default_correct_choice==`i' , cluster(subject_id) robust
    test 2.Treatment_Incentives_Baseline_sc=3.Treatment_Incentives_Baseline_sc
    estadd scalar p_2_3 = r(p)
    test 2.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
    estadd scalar p_2_4 = r(p)
    test 3.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
    estadd scalar p_3_4 = r(p)
    eststo all_control_default_`i'
}


************Raven
forvalues i=1(1)2 {
    reg default_followed i.b1.raven_score_median i.b1.Treatment_Incentives_Baseline_sc if Treatment_Environment==1 & raven_score_median==`i'  , cluster(subject_id) robust
    test 2.Treatment_Incentives_Baseline_sc=3.Treatment_Incentives_Baseline_sc
    estadd scalar p_2_3 = r(p)
    test 2.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
    estadd scalar p_2_4 = r(p)
    test 3.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
    estadd scalar p_3_4 = r(p)
    eststo raven_plain_default_`i'

    reg default_followed i.b1.raven_score_median i.b1.Treatment_Incentives_Baseline_sc ${Wave_control} ${Ability_control} ${Controls} if Treatment_Environment==1 & raven_score_median==`i' , cluster(subject_id) robust
    test 2.Treatment_Incentives_Baseline_sc=3.Treatment_Incentives_Baseline_sc
    estadd scalar p_2_3 = r(p)
    test 2.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
    estadd scalar p_2_4 = r(p)
    test 3.Treatment_Incentives_Baseline_sc=4.Treatment_Incentives_Baseline_sc
    estadd scalar p_3_4 = r(p)
    eststo raven_all_control_default_`i'

}


esttab plain_default all_control_default ///
    plain_default_0 all_control_default_0 ///
    plain_default_1 all_control_default_1 ///
    raven_plain_default_1 raven_all_control_default_1 ///
    raven_plain_default_2 raven_all_control_default_2 ///
    using `"${PATH_OUT}/tableB_2.tex"', replace ///
    b(%5.3f) se(%5.3f) ///
    order() star(* .1 ** .05 *** .01) ///
    label booktabs nonotes noomit nobase nomtitles ///
    mgroups("Overall" "Default incorrect" "Default correct" "Raven Low" "Raven High", ///
    pattern(1 0 1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
    stats(N N_clust r2 p_2_3 p_2_4 p_3_4, fmt(%18.0g %18.0g %5.3f %5.3f) labels("N" "No. Subjects" "\(R^2\)" "\textsc{Baseline-20}=\textsc{Baseline-40}" "\textsc{Baseline-20}=\textsc{Baseline-A.}" "\textsc{Baseline-40}=\textsc{Baseline-A.}")) ///
    indicate("Controls = *original* *ability* *age* *gender* *perc_multitasking* *subject_cat*  *q_abitur_grade_cat* *q_math_grade_cat*")







log close
```

### `ReplicationPackage/EmpiricalAnalysis/dofiles/4_2_Cognitive_Spillover.do`
```stata
/*
*/

log using `"${PATH_OUT}/4_2_Cognitive_Spillover.log"', replace


*************** FIRST ESTIMATION RESULTS FORM ONLINE EXPEIRMENT! ******************
use "${PATH_IN_DATA}/formatted_data_long_mturk.dta", clear

eststo clear
foreach var of varlist math_time math_task_correct passive_choice memory payoff_share {

    reg `var' i.Treatment_intervention, cluster(subject_id)
    eststo p_`var'

    reg `var' i.Treatment_intervention  window_height1 window_width1 age i.gender, cluster(subject_id)
    eststo c_`var'
}


esttab * ///
    using `"${PATH_OUT}/tableO_10.tex"', replace ///
    b(%5.3f) se(%5.3f) ///
    star(* .1 ** .05 *** .01) ///
    label booktabs nonotes ///
    nodepvars nobase ///
    nomtitles ///
    mgroups("Avg. Attention" "\shortstack{Choice Quality \\ (Decision Task)}" "Default Adherence" "\shortstack{Choice Quality \\ (Background Task)}"  "Payoff Share" , ///
    pattern(1 0 1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
    stats(N N_clust r2, fmt(%18.0g %18.0g %9.2g) labels("N" "No. Subjects" "\(R^2\)")) ///
    indicate("Controls = *age* *gender* *window*")



cdfplot math_time ,by(Treatment_intervention) opt1(lwidth(medthick))  ///
    legend(label(1 "Baseline") label(2 "Intervention"))  ///
    ytitle("Cumulative Frequency", margin(medium) height(3) size(medium)) ///
    xtitle("Attention (in sec.)", margin(medium) height(3) size(medium)) ///
    legend(order(1 "B`=ustrunescape("\u1D00")'`=ustrunescape("\uA731")'`=ustrunescape("\u1D07")'`=ustrunescape("\u029F")'`=ustrunescape("\u026A")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D07")'" ///
                2 "`=ustrunescape("\u0049")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D1B")'`=ustrunescape("\u1D07")'`=ustrunescape("\u0280")'`=ustrunescape("\u1D20")'`=ustrunescape("\u1D07")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D1B")'`=ustrunescape("\u026A")'`=ustrunescape("\u1D0F")'`=ustrunescape("\u0274")'"))

graph export `"${PATH_OUT}/figureO_3.png"', as(png) replace


eststo clear


* Generate Estimation results for Table 3 in the main text
reg memory i.Treatment_intervention, cluster(subject_id)
eststo p_memory

reg memory i.Treatment_intervention window_height1 window_width1 age i.gender, cluster(subject_id)
eststo c_memory



*************** MAIN LAB EXPEIRMENT **************
use "${PATH_IN_DATA}/formatted_data_replication.dta", clear

* Drop Ample Observations, which are not analyzed in this section.
drop if Treatment_Incentives==4

tabstat load_correct , by(Treatment_intervention)
tabstat load_correct , by(Treatment_Environment)

************************************************************************************
************ Background Task Quality
************************************************************************

reg load_correct i.Treatment_intervention , robust cluster(subject_id)
eststo force_plain
reg load_correct i.Treatment_intervention ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} , robust cluster(subject_id)
eststo force_all_controls_ability

reg load_correct i.Treatment_Environment , robust cluster(subject_id)
test 2.Treatment_Environment=3.Treatment_Environment
estadd scalar p_treatments = r(p)
eststo plain

reg load_correct i.Treatment_Environment ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} , robust cluster(subject_id)
test 2.Treatment_Environment=3.Treatment_Environment
estadd scalar p_treatments = r(p)
eststo all_controls_ability


esttab force_plain  force_all_controls_ability ///
    plain all_controls_ability ///
    p_memory c_memory ///
    using `"${PATH_OUT}/table3.tex"', replace ///
    b(%5.3f) se(%5.3f) ///
    star(* .1 ** .05 *** .01) ///
    label booktabs nonotes ///
    nodepvars nobase ///
    nomtitles ///
    mgroups("Lab Experiment" "Online Experiment" , ///
    pattern(1 0 0 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
    stats(N N_clust r2 p_treatments, fmt(%18.0g %18.0g %5.3f %5.3f) labels(`"N"' "No. Subjects"  "\(R^2\)" "\textsc{Directed}=\textsc{Forced}")) ///
    indicate("Controls = *original* *Incentives* *ability* *age* *gender* *perc_multitasking* *subject_cat*  *q_abitur_grade_cat* *q_math_grade_cat* *age* *gender* *window* ")








************************************************************************************
************ Background Task Quality: HETEROGENEITIES
************************************************************************

***************************
******** RAVEN ************
 ***************************

reg load_correct i.b0.Treatment_intervention#i.bn.raven_score_median i.bn.raven_score_median  ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} , cluster(subject_id) robust nocons
eststo incentives_heterogeneity

coefplot    (incentives_heterogeneity ,  fcolor(gs8) mcolor(gs8) lcolor(gs8)) , ///
    vertical lwidth(*1) keep(*Treatment_intervention*) ///
    ciopts(recast(rcap)lpattern(dash)lwidth(*.6) lcolor(gs0) ) citop ci(95) ///
    xlabel(, labgap(3) labsize(medium)) ytitle ("Spillover", margin(medium) height(3) size(medium)) ylabel(-.1(0.05).1) ///
    graphregion(color(white))  yline(0, lcolor(black)) xlabel(1 "Raven Score {&le} Median" 2 "Raven Score {&gt} Median " )

graph export `"${PATH_OUT}/figure4.png"', as(png) replace


reg load_correct i.raven_score_median i.Treatment_intervention i.Treatment_intervention#i.raven_score_median  , cluster(subject_id) robust
eststo hetero_force_both_raw

reg load_correct i.raven_score_median i.Treatment_intervention i.Treatment_intervention#i.raven_score_median   ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} , cluster(subject_id) robust
eststo hetero_force_all

reg load_correct i.raven_score_median i.Treatment_Environment i.Treatment_Environment#i.raven_score_median  , cluster(subject_id) robust
eststo hetero_both_raw

reg load_correct i.raven_score_median i.Treatment_Environment i.Treatment_Environment#i.raven_score_median   ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} , cluster(subject_id) robust
eststo hetero_all

esttab   hetero_force_both_raw hetero_force_all ///
         hetero_both_raw hetero_all   ///
    using `"${PATH_OUT}/tableO_4.tex"', replace ///
    b(%5.3f) se(%5.3f) ///
    order(*Treatment_intervention* 2.Treatment_Environment* 3.Treatment_Environment*) ///
    star(* .1 ** .05 *** .01) ///
    label booktabs nonotes ///
    nodepvars nobase ///
    nomtitles ///
    mgroups("Spillover" , ///
    pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
     stats(N N_clust r2, fmt(%18.0g %18.0g %5.3f) labels("N" "No. Subjects" "\(R^2\)")) ///
    indicate("Controls = *original* *Incentives* *ability* *age* *gender* *perc_multitasking* *subject_cat*  *q_abitur_grade_cat* *q_math_grade_cat* *age* *gender* ")



***************************
******** Task Difficulty **
***************************

reg load_correct i.b0.Treatment_intervention#i.bn.high_task_difficulty i.bn.high_task_difficulty  ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} , cluster(subject_id) robust nocons
eststo incentives_heterogeneity

coefplot    (incentives_heterogeneity ,  fcolor(gs8) mcolor(gs8) lcolor(gs8)) , ///
    vertical lwidth(*1) keep(*Treatment_intervention*) ///
    ciopts(recast(rcap)lpattern(dash)lwidth(*.6) lcolor(gs0) ) citop ci(95) ///
    xlabel(, labgap(3) labsize(medium)) ytitle ("Spillover", margin(medium) height(3) size(medium)) ///
    graphregion(color(white))  yline(0, lcolor(black)) xlabel(1 "Difficulty {&le} Median" 2 "Difficulty {&gt} Median" ) ylabel(-.1(0.05).1)
graph export `"${PATH_OUT}/figure5.png"', as(png) replace



reg load_correct i.high_task_difficulty i.Treatment_intervention i.Treatment_intervention#i.high_task_difficulty , cluster(subject_id) robust
eststo hetero_force_both_raw

reg load_correct i.high_task_difficulty i.Treatment_intervention i.Treatment_intervention#i.high_task_difficulty  ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} , cluster(subject_id) robust
eststo hetero_force_all

reg load_correct i.high_task_difficulty i.Treatment_Environment i.Treatment_Environment#i.high_task_difficulty , cluster(subject_id) robust
eststo hetero_both_raw

reg load_correct i.high_task_difficulty i.Treatment_Environment i.Treatment_Environment#i.high_task_difficulty  ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} , cluster(subject_id) robust
eststo hetero_all

esttab   hetero_force_both_raw hetero_force_all ///
         hetero_both_raw hetero_all   ///
    using `"${PATH_OUT}/tableO_5.tex"', replace ///
    b(%5.3f) se(%5.3f) ///
    order(*Treatment_intervention* 2.Treatment_Environment* 3.Treatment_Environment*) ///
    star(* .1 ** .05 *** .01) ///
    label booktabs nonotes ///
    nodepvars nobase ///
    nomtitles ///
    mgroups("Spillover" , ///
    pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
     stats(N N_clust r2, fmt(%18.0g %18.0g %5.3f) labels("N" "No. Subjects" "\(R^2\)")) ///
    indicate("Controls = *original* *Incentives* *ability* *age* *gender* *perc_multitasking* *subject_cat*  *q_abitur_grade_cat* *q_math_grade_cat* *age* *gender* ")


***************************
******** Incentives **
***************************


reg load_correct i.b0.Treatment_intervention#i.bn.Treatment_Incentives i.bn.Treatment_Incentives  ${Wave_control} ${Ability_control} ${Controls} , cluster(subject_id) robust nocons
eststo incentives_heterogeneity

coefplot    (incentives_heterogeneity ,  fcolor(gs8) mcolor(gs8) lcolor(gs8)) , ///
    vertical lwidth(*1) keep(*Treatment_intervention*) ///
    ciopts(recast(rcap)lpattern(dash)lwidth(*.6) lcolor(gs0) ) citop ci(95) ///
    xlabel(, labgap(3) labsize(medium)) ytitle ("Spillover", margin(medium) height(3) size(medium)) ///
    graphregion(color(white))  yline(0, lcolor(black))    ///
    xlabel( 1 " `=ustrunescape("\u0049")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D1B")'`=ustrunescape("\u1D07")'`=ustrunescape("\u0280")'`=ustrunescape("\u1D20")'`=ustrunescape("\u1D07")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D1B")'`=ustrunescape("\u026A")'`=ustrunescape("\u1D0F")'`=ustrunescape("\u0274")'-10" ///
    2" `=ustrunescape("\u0049")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D1B")'`=ustrunescape("\u1D07")'`=ustrunescape("\u0280")'`=ustrunescape("\u1D20")'`=ustrunescape("\u1D07")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D1B")'`=ustrunescape("\u026A")'`=ustrunescape("\u1D0F")'`=ustrunescape("\u0274")'-20" ///
    3" `=ustrunescape("\u0049")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D1B")'`=ustrunescape("\u1D07")'`=ustrunescape("\u0280")'`=ustrunescape("\u1D20")'`=ustrunescape("\u1D07")'`=ustrunescape("\u0274")'`=ustrunescape("\u1D1B")'`=ustrunescape("\u026A")'`=ustrunescape("\u1D0F")'`=ustrunescape("\u0274")'-40") ///
    ylabel(-.1(0.05).1)
graph export `"${PATH_OUT}/figure6.png"', as(png) replace


reg load_correct i.Treatment_Incentives_Int_sc i.Treatment_intervention i.Treatment_intervention#i.Treatment_Incentives_Int_sc  , cluster(subject_id) robust
eststo hetero_force_both_raw


reg load_correct i.Treatment_Incentives_Int_sc i.Treatment_intervention i.Treatment_intervention#i.Treatment_Incentives_Int_sc   ${Wave_control} ${Ability_control} ${Controls} , cluster(subject_id) robust
eststo hetero_force_all

reg load_correct i.Treatment_Incentives_Int_sc i.Treatment_Environment i.Treatment_Environment#i.Treatment_Incentives_Int_sc , cluster(subject_id) robust
eststo hetero_both_raw

reg load_correct i.Treatment_Incentives_Int_sc i.Treatment_Environment i.Treatment_Environment#i.Treatment_Incentives_Int_sc  ${Wave_control} ${Ability_control} ${Controls} , cluster(subject_id) robust
eststo hetero_all

esttab   hetero_force_both_raw  hetero_force_all ///
         hetero_both_raw  hetero_all   ///
    using `"${PATH_OUT}/tableO_6.tex"', replace ///
    b(%5.3f) se(%5.3f) ///
    order(*Treatment_intervention* 2.Treatment_Environment* 3.Treatment_Environment*) ///
    star(* .1 ** .05 *** .01) ///
    label booktabs nonotes ///
    nodepvars nobase ///
    nomtitles ///
    mgroups("Spillover" , ///
    pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
     stats(N N_clust r2, fmt(%18.0g %18.0g %5.3f) labels("N" "No. Subjects" "\(R^2\)")) ///
    indicate("Controls = *original* *ability* *age* *gender* *perc_multitasking* *subject_cat*  *q_abitur_grade_cat* *q_math_grade_cat* *age* *gender* ")


log close
```

### `ReplicationPackage/EmpiricalAnalysis/dofiles/4_3_Payoffs_And_Efficiency.do`
```stata
log using `"${PATH_OUT}/4_3_Payoffs_And_Efficiency.log"', replace

use "${PATH_IN_DATA}/formatted_data_replication.dta", clear



reg payoff_share i.Treatment_intervention if Treatment_Incentives!=4, robust cluster(subject_id)
eststo force_plain

reg payoff_share i.Treatment_intervention ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4, robust cluster(subject_id)
eststo force_all_controls_ability


reg payoff_share i.Treatment_Environment if Treatment_Incentives!=4, robust cluster(subject_id)
test 2.Treatment_Environment=3.Treatment_Environment
estadd scalar p_treatments = r(p)
eststo plain

reg payoff_share i.Treatment_Environment ${Incentive_control}  ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4, robust cluster(subject_id)
test 2.Treatment_Environment=3.Treatment_Environment
estadd scalar p_treatments = r(p)
eststo all_controls_ability

esttab  force_plain  force_all_controls_ability  ///
    plain   all_controls_ability ///
    using `"${PATH_OUT}/table4.tex"', replace ///
    b(%5.3f) se(%5.3f) ///
    order(*Treatment_intervention* 2.Treatment_Environment* 3.Treatment_Environment*)  ///
    star(* .1 ** .05 *** .01) ///
    label booktabs nonotes ///
    nodepvars nobase ///
    nomtitles ///
    mgroups("Payoff Share" , ///
    pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
    stats(N N_clust r2 p_treatments, fmt(%18.0g %18.0g %5.3f %5.3f) labels(`"N"' "No. Subjects"  "\(R^2\)" "\textsc{Directed}=\textsc{Forced}")) ///
    indicate("Controls = *original* *Incentives* *ability* *age* *gender* *perc_multitasking* *subject_cat*  *q_abitur_grade_cat* *q_math_grade_cat*")



*** Tables heterogeneity:

reg payoff_share i.b1.Treatment_Incentives_Int_sc i.b1.Treatment_Incentives i.Treatment_intervention i.Treatment_intervention#i.b1.Treatment_Incentives  if Treatment_Incentives!=4 , cluster(subject_id) robust
eststo hetero_force_both_raw
reg payoff_share i.b1.Treatment_Incentives_Int_sc i.b1.Treatment_Incentives i.Treatment_intervention i.Treatment_intervention#i.b1.Treatment_Incentives  ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4 , cluster(subject_id) robust
eststo hetero_force_all

reg payoff_share i.b1.Treatment_Incentives_Int_sc i.b1.Treatment_Incentives i.Treatment_Environment i.Treatment_Environment#i.b1.Treatment_Incentives if Treatment_Incentives!=4 , cluster(subject_id) robust
eststo hetero_both_raw
reg payoff_share i.b1.Treatment_Incentives_Int_sc i.b1.Treatment_Incentives i.Treatment_Environment i.Treatment_Environment#i.b1.Treatment_Incentives  ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4 , cluster(subject_id) robust
eststo hetero_all

esttab   hetero_force_both_raw hetero_force_all ///
         hetero_both_raw hetero_all   ///
    using `"${PATH_OUT}/tableO_8.tex"', replace ///
    b(%5.3f) se(%5.3f) ///
    order(*Treatment_intervention* 2.Treatment_Environment* 3.Treatment_Environment*) ///
    star(* .1 ** .05 *** .01) ///
    label booktabs nonotes ///
    nodepvars nobase noomit ///
    nomtitles ///
    mgroups("Payoff Share" , ///
    pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
     stats(N N_clust r2, fmt(%18.0g %18.0g %5.3f) labels("N" "No. Subjects" "\(R^2\)")) ///
    indicate("Controls = *original*  *ability* *age* *gender* *perc_multitasking* *subject_cat*  *q_abitur_grade_cat* *q_math_grade_cat*")



****************************** Coefplots Heterogeneity ******************************


reg payoff_share i.b0.Treatment_intervention#i.bn.raven_score_median i.bn.raven_score_median  ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} if  Treatment_Incentives!=4, cluster(subject_id) nocons
eststo incentives_heterogeneity

coefplot    (incentives_heterogeneity ,  fcolor(gs8) mcolor(gs8) lcolor(gs8)) , ///
    vertical lwidth(*1) keep(*Treatment_intervention*) ///
    ciopts(recast(rcap)lpattern(dash)lwidth(*.6) lcolor(gs0) ) citop ci(95) ///
    xlabel(, labgap(3) labsize(medlarge)) ytitle ("Payoff Share", margin(medium) height(3) size(medlarge)) ylabel(-.1(0.05).1) ///
    graphregion(color(white))  yline(0, lcolor(black)) xlabel(1 "Raven Score {&le} Median" 2 "Raven Score {&gt} Median")

graph export `"${PATH_OUT}/figure7.png"', as(png) replace

reg payoff_share i.b0.Treatment_intervention#i.bn.raven_score_quartiles i.bn.raven_score_quartiles  ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} if  Treatment_Incentives!=4, cluster(subject_id) nocons
eststo incentives_heterogeneity

coefplot    (incentives_heterogeneity ,  fcolor(gs8) mcolor(gs8) lcolor(gs8)) , ///
    vertical lwidth(*1) keep(*Treatment_intervention*) ///
    ciopts(recast(rcap)lpattern(dash)lwidth(*.6) lcolor(gs0) ) citop ci(95) ///
    xlabel(, labgap(3) labsize(medlarge)) ytitle ("Payoff Share", margin(medium) height(3) size(medlarge)) ylabel(-.1(0.05).1) ///
    graphregion(color(white))  yline(0, lcolor(black)) xlabel(1 `""Raven score" "1st Quartile""' 2 `""Raven score" "2nd Quartile"'  3 `""Raven score" "3rd Quartile""' 4 `""Raven score" "4th Quartile""')

graph export `"${PATH_OUT}/figureO_2.png"', as(png) replace


*** Tables heterogeneity:

reg payoff_share i.raven_score_median i.Treatment_intervention i.Treatment_intervention#i.raven_score_median  if Treatment_Incentives!=4 , cluster(subject_id) robust
eststo hetero_force_both_raw
reg payoff_share i.raven_score_median i.Treatment_intervention i.Treatment_intervention#i.raven_score_median   ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4 , cluster(subject_id) robust
eststo hetero_force_all

reg payoff_share i.raven_score_median i.Treatment_Environment i.Treatment_Environment#i.raven_score_median if Treatment_Incentives!=4 , cluster(subject_id) robust
eststo hetero_both_raw
reg payoff_share i.raven_score_median i.Treatment_Environment i.Treatment_Environment#i.raven_score_median  ${Incentive_control} ${Wave_control} ${Ability_control} ${Controls} if Treatment_Incentives!=4 , cluster(subject_id) robust
eststo hetero_all

esttab   hetero_force_both_raw hetero_force_all ///
         hetero_both_raw hetero_all   ///
    using `"${PATH_OUT}/tableO_9.tex"', replace ///
    b(%5.3f) se(%5.3f) ///
    order(*Treatment_intervention* 2.Treatment_Environment* 3.Treatment_Environment*) ///
    star(* .1 ** .05 *** .01) ///
    label booktabs nonotes ///
    nodepvars nobase noomit ///
    nomtitles ///
    mgroups("Payoff Share" , ///
    pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
     stats(N N_clust r2, fmt(%18.0g %18.0g %5.3f) labels("N" "No. Subjects" "\(R^2\)")) ///
    indicate("Controls = *original* *Incentives* *ability* *age* *gender* *perc_multitasking* *subject_cat*  *q_abitur_grade_cat* *q_math_grade_cat*")















********** Calculate Hypothetical Payoffs for Table 5***************

cap program drop convert
program define convert, eclass
    matrix list `1'
    ereturn  scalar N=.
    ereturn matrix mean `1'
end


use "${PATH_IN_DATA}/formatted_data_replication.dta", clear

*Restrict dataset to Baseline-Scarce treatments
drop if Treatment_Environment!=1
drop if Treatment_Incentives==4
drop if round!=1

expand 3

*Hypo. Treatment ID
bysort subject_id: gen Treatment_Incentives_Hypo=_n
label var Treatment_Incentives_Hypo "Hypothetical Incentives"
label values Treatment_Incentives_Hypo Treatment_Incentives


* Always got 40 cents for load task
gen hypo_payoff_load_mean  = load_correct_mean * 0.4

* Get hypo payoff for decision task using real behavior under one of three incentive schemes
gen hypo_payoff_summation_mean  = .
replace hypo_payoff_summation_mean  = summation_correct_mean * 0.1 if Treatment_Incentives_Hypo ==1
replace hypo_payoff_summation_mean  = summation_correct_mean * 0.2 if Treatment_Incentives_Hypo ==2
replace hypo_payoff_summation_mean  = summation_correct_mean * 0.4 if Treatment_Incentives_Hypo ==3

** Hypothethical payoff + share
gen hypo_payoff_mean = hypo_payoff_load_mean  + hypo_payoff_summation_mean
gen hypo_payoff_share = .
replace hypo_payoff_share  = hypo_payoff_mean / 0.5 if Treatment_Incentives_Hypo ==1
replace hypo_payoff_share  = hypo_payoff_mean / 0.6 if Treatment_Incentives_Hypo ==2
replace hypo_payoff_share  = hypo_payoff_mean / 0.8 if Treatment_Incentives_Hypo ==3

gen hypo_payoff_share_table =hypo_payoff_share
replace hypo_payoff_share_table =. if Treatment_Incentives == Treatment_Incentives_Hypo


estpost tabstat hypo_payoff_share_table if Treatment_Incentives ==1 , by(Treatment_Incentives_Hypo) statistics(mean sd) columns(statistics) listwise nototal
eststo one
estpost tabstat hypo_payoff_share_table if Treatment_Incentives ==2 , by(Treatment_Incentives_Hypo) statistics(mean sd) columns(statistics) listwise nototal
eststo two
estpost tabstat hypo_payoff_share_table if Treatment_Incentives ==3 , by(Treatment_Incentives_Hypo) statistics(mean sd) columns(statistics) listwise nototal
eststo three

estpost tabstat payoff_share_mean if  Treatment_Incentives_Hypo==1 , by(Treatment_Incentives) statistics(mean sd) columns(statistics) listwise nototal
eststo observed

matrix diff=e(mean)
matrix t=e(mean)
estpost ttest hypo_payoff_share if Treatment_Incentives_Hypo ==1 &Treatment_Incentives !=3 , by(Treatment_Incentives )
matrix help=e(b)
matrix help2=e(p)
matrix diff[1,1] = help[1,1]
matrix t[1,1] = help2[1,1]
estpost ttest hypo_payoff_share if Treatment_Incentives_Hypo ==2 &Treatment_Incentives !=3 , by(Treatment_Incentives )
matrix help=e(b)
matrix help2=e(p)
matrix diff[1,2] = help[1,1]
matrix t[1,2] = help2[1,1]
estpost ttest hypo_payoff_share if Treatment_Incentives_Hypo ==3 &Treatment_Incentives !=1 , by(Treatment_Incentives )
matrix help=e(b)
matrix help2=e(p)
matrix diff[1,3] = help[1,1]
matrix t[1,3] = help2[1,1]

convert diff
eststo diff

convert t
eststo t


* Data for Table 5
esttab one two three observed diff t, ///
     order(10 20 40) ///
     main(mean %5.3f) aux(sd %5.3f) ///
     nostar unstack  noobs nonote  nolabel nonumber ///
     mtitles("\textsc{40/10}" "\textsc{40/20}" "\textsc{40/40}" "" "diff" "p-values") ///
     mgroups("Hypothetical behavior in" "Observed" "Diff. to largest benchmark" , pattern(1 0 0 1 1 0) ) ///

clear

log close
```

## How to run a script

Write each script to a file under the output directory, then run it with
exactly this command (the data directory is mounted read-only at its own
path; nothing else from the host is visible; `$SCRIPT` is the absolute path of
the script you wrote):

    SCRIPT=<repo>/benchmark/reproductions/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a/script.R   # or <repo>/benchmark/reproductions/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a/attempt-<n>/script.R
    docker run --rm --label retally.run=claude-code-altmann-2022-cognitive-spillovers-seeded-2026-10-22-a --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a/mount/altmann_2022_cognitive_spillovers:<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a/mount/altmann_2022_cognitive_spillovers:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R > "$(dirname "$SCRIPT")/stdout.txt" 2> "$(dirname "$SCRIPT")/stderr.txt"; echo "exit code: $?"

The sandbox time limit is 300 seconds (memory 4g, 1.0 CPU).  Wrap the
command in a timeout of that many seconds: prefix it with
`perl -e 'alarm shift; exec @ARGV' 300` (or `gtimeout 300` if installed;
macOS has no `timeout`).  If the timeout fires, stop the container with
`docker ps -q --filter label=retally.run=claude-code-altmann-2022-cognitive-spillovers-seeded-2026-10-22-a | xargs docker kill` and treat the
run as a crash (exit code 124).

## Output contract

The output directory `<repo>/benchmark/reproductions/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a/
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

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a`.
