# Retally reproduction task: manekin-2022-effective-for-whom (seeded, run 2026-11-02-b)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `manekin-2022-effective-for-whom`, mode `seeded`, run `2026-11-02-b`
- Paper: Effective for Whom? Ethnic Identity and Nonviolent Resistance
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/seeded/2026-11-02-b/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/seeded/2026-11-02-b/mount/manekin_2022_effective_for_whom`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/manekin-2022-effective-for-whom/seeded/2026-11-02-b`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/seeded/2026-11-02-b/mount/manekin_2022_effective_for_whom` as data, and `<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/seeded/2026-11-02-b/paper.txt` as
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

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/manekin-2022-effective-for-whom/seeded/2026-11-02-b --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Claims to Reproduce
1. study1_us_black_perceived_violence: 0.235 (points on a 0-10 scale) [type: coefficient]
   Location: Table 1, Panel (A) US Sample, Black protesters, Perceived degree of violence
   Context: Table 1 ("Group Identity and Protest Tactic"), Panel (A) U.S. sample, row Black protesters, column Perceived degree of violence. Study 1 online survey experiment (U.S., three waves, November 2018-January 2019): respondents read a simulated news article about a protest with the protesters' identity randomized (white vs Black, signaled by names and a photo) and the tactic randomized (marching in streets, shutting down traffic, destroying police cars), a 2 x 3 factorial design. Outcome: how violent the respondent would say the protest was, 0 (completely nonviolent) to 10 (extremely violent). OLS …
2. study1_us_black_police_action: 0.268 (points on a 0-10 scale) [type: coefficient]
   Location: Table 1, Panel (A) US Sample, Black protesters, Police action required
   Context: Table 1, Panel (A) U.S. sample, row Black protesters, column Police action required. Same Study 1 U.S. design and OLS specification as study1_us_black_perceived_violence (Black protester indicator plus tactic indicators; base white protesters marching in the streets; weighted), with the outcome the respondent's view, 0-10, of the extent to which police action is required to address the protest.
3. study1_israel_ethiopian_perceived_violence: 0.425 (points on a 0-10 scale) [type: coefficient]
   Location: Table 1, Panel (B) Israel Sample, Ethiopian protesters, Perceived degree of violence
   Context: Table 1, Panel (B) Israel sample, row Ethiopian protesters, column Perceived degree of violence. Study 1 Israeli survey (two waves, February-March 2019): protester identity randomized among white Jews (majority), Ethiopian Jews and Israeli Arabs (minorities), noted in the article title, and tactic among marching in streets, shutting down traffic and destroying garbage cans (3 x 3 design). Outcome: perceived violence of the protest, 0-10. OLS on indicators for Ethiopian and Arab protesters and the two more intense tactics; base white protesters marching in the streets; weighted (see study1_us_b…
4. study1_israel_ethiopian_police_action: 0.181 (points on a 0-10 scale) [type: coefficient]
   Location: Table 1, Panel (B) Israel Sample, Ethiopian protesters, Police action required
   Context: Table 1, Panel (B) Israel sample, row Ethiopian protesters, column Police action required (0-10). Same Study 1 Israeli specification as study1_israel_ethiopian_perceived_violence.
5. study1_israel_arab_perceived_violence: 0.623 (points on a 0-10 scale) [type: coefficient]
   Location: Table 1, Panel (B) Israel Sample, Arab protesters, Perceived degree of violence
   Context: Table 1, Panel (B) Israel sample, row Arab protesters, column Perceived degree of violence (0-10). Same Study 1 Israeli specification as study1_israel_ethiopian_perceived_violence; this is the coefficient on the Arab protester indicator.
6. study1_israel_arab_police_action: 0.964 (points on a 0-10 scale) [type: coefficient]
   Location: Table 1, Panel (B) Israel Sample, Arab protesters, Police action required
   Context: Table 1, Panel (B) Israel sample, row Arab protesters, column Police action required (0-10). Same Study 1 Israeli specification as study1_israel_ethiopian_perceived_violence.
7. study2_us_black_perceived_violence: 0.347 (points on a 0-10 scale) [type: coefficient]
   Location: Table 2, Panel (A) US Sample, Black protesters, Perceived degree of violence
   Context: Table 2 ("Group Identity, Protest Goal, and Commitment to Nonviolence"), Panel (A) U.S. sample, row Black protesters, column Perceived degree of violence. Study 2 online survey experiment (U.S., June 2020): a 2 x 2 x 2 factorial vignette design randomizing protester identity (white vs Black), protest goal (general: protesting layoffs; group-based: protesting racial prejudice and police brutality) and whether protesters explicitly stated a commitment to nonviolence. Outcome: perceived violence, 0-10. OLS of the outcome on indicators for Black protesters, minority group goal and commitment to no…
8. study2_us_black_police_action: 0.429 (points on a 0-10 scale) [type: coefficient]
   Location: Table 2, Panel (A) US Sample, Black protesters, Police action required
   Context: Table 2, Panel (A) U.S. sample, row Black protesters, column Police action required (0-10). Same Study 2 U.S. specification as study2_us_black_perceived_violence; Table 2 reports slightly fewer observations for this column than for the other two (respondents missing this outcome are dropped).
9. respondents_study1_us: 2269.0 (respondents) [type: other]
   Location: Research Design (text); Table 1, Panel (A), Observations
   Context: Study 1 U.S. sample size: respondents to the U.S. survey experiment, the observations in each Table 1 Panel (A) regression.
10. respondents_study1_israel: 3063.0 (respondents) [type: other]
   Location: Research Design (text); Table 1, Panel (B), Observations
   Context: Study 1 Israeli sample size: respondents to the Israeli survey experiment, the observations in each Table 1 Panel (B) regression.
11. respondents_study2_us: 3013.0 (respondents) [type: other]
   Location: Research Design (text); Table 2, Panel (A), Observations
   Context: Study 2 U.S. sample size: respondents to the June 2020 U.S. survey experiment, the observations in the Table 2 Panel (A) perceived violence and recall regressions.
12. respondents_study2_israel: 3465.0 (respondents) [type: other]
   Location: Research Design (text); Table 2, Panel (B), Observations
   Context: Study 2 Israeli sample size: respondents to the June 2020 Israeli survey experiment, the observations in each Table 2 Panel (B) regression.

## Dataset Information
Name: manekin_2022_effective_for_whom
Local path: <repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/seeded/2026-11-02-b/mount/manekin_2022_effective_for_whom
File format: csv
Files in the dataset directory (paths relative to the local path above):
- Replication/Data/isr_survey_wave1.rdata (79.3 KB) — objects: isr_survey_wave1 (data.frame, 3063 rows, 20 columns: degree_violence, police_action_required, recall_violence, recall_violence2, identity_protesters, tactic, survey, ResponseId, approve_protest_scale, age, female, education, income, ideology, partyID, interest_news, religiosity, ethnicity, weight, nv_tactic_scale)
- Replication/Data/us_survey_wave1.rdata (46.4 KB) — objects: us_survey_wave1 (data.frame, 2269 rows, 21 columns: identity_protesters, tactic, degree_violence, police_action_required, recall_violence2, survey, caseid, wave, weight, race, age, female, education, income, partyID, ideology, interest_politics, interest_news, approve_protest_scale, approve_protest_dummy, nv_tactic_scale)
- Replication/Data/us_survey_wave2.rdata (92.2 KB) — objects: us_survey_wave2 (data.frame, 3013 rows, 21 columns: degree_violence, police_action_required, recall_violence2, black, commitment, group_goal, ResponseId, age, female, education, income, race, partyID, pol_views, interest_politics, interest_news, identity_protesters_fac, approve_protest_dummy, degree_violence_std, police_action_required_std, recall_violence_std)
- Replication/Data/isr_survey_wave2.rdata (90.6 KB) — objects: isr_survey_wave2 (data.frame, 3465 rows, 20 columns: degree_violence, police_action_required, recall_violence2, identity_protesters, commitment, group_goal, ResponseId, age, female, religiosity, ethnicity, education, income, partyID, ideology, approve_protest_dummy, interest_news, degree_viol…)
- Replication/Data/EBCR_EPR_NAVCO2.rdata (48.0 KB) — objects: EBCR_EPR_NAVCO2 (data.frame, 2628 rows, 59 columns: NAVCO2ID, YEAR, EPR_ID, CAMPAIGN, LOCATION, LCCODE, TARGET, TCCODE, CAMP_GOALS, PRIM_METHOD, NAVCO1, CDIVERS_ETHNIC, EPR_GROUP.x, PARTICIPATION.x, INITIATION.x, MOVEMENT, CLAIM.x, RULE, SOURCES, NOTES, X, GW_COUNTRY_ID, COUNTRY, EPR_GROUP.y…)
- Replication/Data/NAVCO2.rdata (28.2 KB) — objects: NAVCO2 (data.frame, 1726 rows, 57 columns: campaign, location, year, cyear, lccode, target, tccode, navco1designation, camp_orgs, camp_size, camp_size_est, camp_conf_intensity, rad_flank, resis_meth, cdivers_gender, cdivers_age, cdivers_class, cdivers_urbrural, cdivers_ideol, cdiver…)
- Replication/Data/NAVCO2_EPR.rdata (8.3 KB) — objects: NAVCO2_EPR (data.frame, 212 rows, 13 columns: id, campaign, location, year, cyear, lccode, target, tccode, navco1designation, EPR_ID, EPR_STATUS, EPR_STATUS_EXCL, success)
- Replication/Data/isr_survey_text_analysis_arab.rdata (772.6 KB) — objects: isr_survey_text_analysis_arab (list)
- Replication/Data/isr_survey_text_analysis_eth.rdata (824.8 KB) — objects: isr_survey_text_analysis_eth (list)
- Replication/Data/us_survey_text_analysis.rdata (670.9 KB) — objects: us_survey_text_analysis (list)
- Replication/Code/Manekin_Mitts_Effective_for_Whom_Replication.R (3.1 KB)
- Replication/Code/replicate_fig_1.R (3.7 KB)
- Replication/Code/replicate_fig_10.R (1.8 KB)
- Replication/Code/replicate_fig_3.R (13.7 KB)
- Replication/Code/replicate_fig_4.R (5.7 KB)
- Replication/Code/replicate_fig_6.R (4.7 KB)
- Replication/Code/replicate_fig_7.R (4.6 KB)
- Replication/Code/replicate_fig_8.R (1.8 KB)
- Replication/Code/replicate_fig_9.R (1.8 KB)
- Replication/Code/replicate_fig_A1.R (1.5 KB)
- Replication/Code/replicate_fig_A10.R (4.3 KB)
- Replication/Code/replicate_fig_A11.R (4.7 KB)
- Replication/Code/replicate_fig_A12.R (3.9 KB)
- Replication/Code/replicate_fig_A2.R (4.0 KB)
- Replication/Code/replicate_fig_A3.R (522 B)
- Replication/Code/replicate_fig_A6.R (7.6 KB)
- Replication/Code/replicate_fig_A7.R (9.4 KB)
- Replication/Code/replicate_fig_A8.R (10.8 KB)
- Replication/Code/replicate_fig_A9.R (12.2 KB)
- Replication/Code/replicate_table_1.R (1.5 KB)
- Replication/Code/replicate_table_4.R (1.2 KB)
- Replication/Code/replicate_table_A1.R (1.0 KB)
- Replication/Code/replicate_table_A10.R (581 B)
- Replication/Code/replicate_table_A11.R (594 B)
- Replication/Code/replicate_table_A13.R (1.2 KB)
- Replication/Code/replicate_table_A14.R (13.2 KB)
- Replication/Code/replicate_table_A15.R (1.6 KB)
- Replication/Code/replicate_table_A16.R (7.9 KB)
- Replication/Code/replicate_table_A17.R (1.2 KB)
- Replication/Code/replicate_table_A18.R (774 B)
- Replication/Code/replicate_table_A2.R (767 B)
- Replication/Code/replicate_table_A3.R (2.1 KB)
- Replication/Code/replicate_table_A4.R (1.3 KB)
- Replication/Code/replicate_table_A5.R (2.8 KB)
- Replication/Code/replicate_table_A6.R (454 B)
- Replication/Code/replicate_table_A7.R (526 B)
- Replication/Code/replicate_table_A8.R (710 B)
- Replication/Code/replicate_table_A9.R (698 B)
- Replication/Figures/fig_1.pdf (5.5 KB)
- Replication/Figures/fig_10.pdf (5.6 KB)
- Replication/Figures/fig_3.pdf (6.7 KB)
- Replication/Figures/fig_4.pdf (6.6 KB)
- Replication/Figures/fig_6.pdf (5.3 KB)
- Replication/Figures/fig_7.pdf (5.3 KB)
- Replication/Figures/fig_8.pdf (5.7 KB)
- Replication/Figures/fig_9.pdf (5.6 KB)
- Replication/Figures/fig_A1.pdf (7.3 KB)
- Replication/Figures/fig_A10.pdf (5.2 KB)
- Replication/Figures/fig_A11.pdf (5.2 KB)
- Replication/Figures/fig_A12.pdf (6.3 KB)
- Replication/Figures/fig_A2.pdf (4.9 KB)
- Replication/Figures/fig_A3.pdf (24.8 KB)
- Replication/Figures/fig_A6.pdf (8.8 KB)
- Replication/Figures/fig_A7.pdf (12.8 KB)
- Replication/Figures/fig_A8.pdf (9.8 KB)
- Replication/Figures/fig_A9.pdf (11.8 KB)
- Replication/Tables/table_1_panel_A.tex (1.4 KB)
- Replication/Tables/table_1_panel_B.tex (1.5 KB)
- Replication/Tables/table_4_panel_A.tex (1.5 KB)
- Replication/Tables/table_4_panel_B.tex (1.5 KB)
- Replication/Tables/table_A1.tex (1.9 KB)
- Replication/Tables/table_A10.tex (2.9 KB)
- Replication/Tables/table_A11.tex (2.9 KB)
- Replication/Tables/table_A13_panel_A.tex (4.7 KB)
- Replication/Tables/table_A13_panel_B.tex (3.2 KB)
- Replication/Tables/table_A14.tex (2.1 KB)
- Replication/Tables/table_A15_panel_A.tex (1.6 KB)
- Replication/Tables/table_A15_panel_B.tex (2.0 KB)
- Replication/Tables/table_A16.tex (1010 B)
- Replication/Tables/table_A17_panel_A.tex (3.9 KB)
- … and 10 more files (listing truncated)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/seeded/2026-11-02-b/mount/manekin_2022_effective_for_whom' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
Installed packages (no network; nothing else can be installed): jsonlite, fixest, lfe, AER, ivreg, plm, estimatr, lme4, quantreg, car, sandwich, lmtest, clubSandwich, multiwayvcov, marginaleffects, MatchIt, optmatch, CBPS, WeightIt, cobalt, did, rdrobust, rddensity, Synth, modelsummary, stargazer, texreg, broom, tidyverse, dplyr, tidyr, readr, stringr, lubridate, data.table, haven, readxl, janitor, zoo, ggplot2, ggridges, ggrepel, gridExtra, cowplot, gtable, extrafont, sf, MASS, nnet, survival, splines, Matrix, boot, stats, utils.
Prefer fixest for fixed effects, IV and clustered SEs; use the other installed packages where the paper's method calls for them.
Set a deterministic seed with ``set.seed(42)`` for any randomness.
Do NOT access the internet; the container runs with --network none.
Do NOT shell out via system() / system2().
Emit RESULT:<name>=<value> lines to stdout at the end via cat().

## Original Replication Scripts
The replication package (the dataset directory) ships the authors' own analysis scripts, reproduced below.  These are the GROUND TRUTH for the exact estimating equation, variable names, sample restrictions, fixed effects, and standard-error clustering — follow them over anything reconstructed from the methodology summary, and prefer them over the paper's text where the two disagree.  Your job is to write R code that implements the SAME SPECIFICATION: translate what the scripts estimate, do not transliterate their syntax line by line (a Stata .do file's regression, e.g. `reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the equivalent fixest::feols() call in R).  Keep only the parts that produce the specific claims being reproduced; skip figure construction and unrelated robustness checks.  The scripts' data-file paths refer to the package's internal layout — resolve them against the dataset directory listed under Dataset Information.

### `Replication/Code/Manekin_Mitts_Effective_for_Whom_Replication.R`
```r
# ----------------------------------------------------------------------
# Replication for "Effective for Whom? Ethnic Identity and Nonviolent Resistance"
# Devorah Manekin and Tamar Mitts
# American Political Science Review (2021)
# ----------------------------------------------------------------------
# This code replicates the tables figures in the article and the appendix.
# It requires the packages listed below. If not already installed, 
# use the function install.packages() to install them.
# ----------------------------------------------------------------------

rm(list=ls())

library(lemon)
library(stargazer)
library(xtable)
library(fastDummies)
library(tidyr)
library(gridExtra)
library(stm)
library(quanteda)
library(ggplot2)
library(dotwhisker)
library(ggeffects)
library(estimatr)
library(corrplot)

# SET WORKING DIRECTORY
setwd("<home>/Dropbox (Mitts)/Projects/Non-violence/Replication/")

# LOAD DATASETS
load("Data/EBCR_EPR_NAVCO2.rdata")
load("Data/NAVCO2_EPR.rdata")
load("Data/NAVCO2.rdata")
load("Data/us_survey_wave1.rdata")
load("Data/isr_survey_wave1.rdata")
load("Data/us_survey_wave2.rdata")
load("Data/isr_survey_wave2.rdata")
load("Data/us_survey_text_analysis.rdata")
load("Data/isr_survey_text_analysis_eth.rdata")
load("Data/isr_survey_text_analysis_arab.rdata")

##--##--##--##
## Manuscript
##--##--##--##

# Figure 1
source("Code/replicate_fig_1.R")
# Figure 3
source("Code/replicate_fig_3.R")
# Figure 4
source("Code/replicate_fig_4.R")
# Figure 6
source("Code/replicate_fig_6.R")
# Figure 7
source("Code/replicate_fig_7.R")
# Figure 8
source("Code/replicate_fig_8.R")
# Figure 9
source("Code/replicate_fig_9.R")
# Figure 10
source("Code/replicate_fig_10.R")

# Table 1
source("Code/replicate_table_1.R")
# Table 4
source("Code/replicate_table_4.R")

##--##--##--##
## Appendix
##--##--##--##

# Figure A1
source("Code/replicate_fig_A1.R")
# Figure A2
source("Code/replicate_fig_A2.R")
# Figure A3
source("Code/replicate_fig_A3.R")
# Figure A6
source("Code/replicate_fig_A6.R")
# Figure A7
source("Code/replicate_fig_A7.R")
# Figure A8
source("Code/replicate_fig_A8.R")
# Figure A9
source("Code/replicate_fig_A9.R")
# Figure A10
source("Code/replicate_fig_A10.R")
# Figure A11
source("Code/replicate_fig_A11.R")
# Figure A11
source("Code/replicate_fig_A12.R")

# Table A1
source("Code/replicate_table_A1.R")
# Table A2
source("Code/replicate_table_A2.R")
# Table A3
source("Code/replicate_table_A3.R")
# Table A4
source("Code/replicate_table_A4.R")
# Table A5
source("Code/replicate_table_A5.R")
# Table A6
source("Code/replicate_table_A6.R")
# Table A7
source("Code/replicate_table_A7.R")
# Table A8
source("Code/replicate_table_A8.R")
# Table A9
source("Code/replicate_table_A9.R")
# Table A10
source("Code/replicate_table_A10.R")
# Table A10
source("Code/replicate_table_A11.R")
# Table A13
source("Code/replicate_table_A13.R")
# Table A14
source("Code/replicate_table_A14.R")
# Table A15
source("Code/replicate_table_A15.R")
# Table A16
source("Code/replicate_table_A16.R")
# Table A17
source("Code/replicate_table_A17.R")
# Table A18
source("Code/replicate_table_A18.R")

## END
```

### `Replication/Code/replicate_table_1.R`
```r
##--##--##--##
## Table 1
##--##--##--##

## A. U.S
degv_yg = lm(degree_violence ~ identity_protesters + tactic  , data=us_survey_wave1, weights=weight)
police_yg = lm(police_action_required ~ identity_protesters + tactic  , data=us_survey_wave1, weights=weight)
recall_violence_yg = lm(recall_violence2 ~ identity_protesters + tactic  , data=us_survey_wave1, weights=weight)
approve_protest_yg = lm(approve_protest_scale ~ identity_protesters + tactic  , data=us_survey_wave1, weights=weight)
stargazer(degv_yg, recall_violence_yg, police_yg, 
          covariate.labels = c("Black protesters", "Shut down traffic", 
                               "Destroy police cars", "Intercept: White protesters, March in streets"),
          out = "Tables/table_1_panel_A.tex")

## B. Israel
degv_isr = lm(degree_violence ~ identity_protesters + tactic  , data=isr_survey_wave1, weights=weight)
police_isr = lm(police_action_required ~ identity_protesters + tactic  , data=isr_survey_wave1, weights=weight)
recall_violence_isr = lm(recall_violence2 ~ identity_protesters + tactic  , data=isr_survey_wave1, weights=weight)
approve_protest_isr = lm(approve_protest_scale ~ identity_protesters + tactic  , data=isr_survey_wave1, weights=weight)
stargazer(degv_isr, recall_violence_isr, police_isr,
          covariate.labels = c("Ethiopian protesters", "Arab protesters",
                               "Shut down traffic", "Destroy garbage cans",
                               "Intercept: White protesters, March in streets"),
          out = "Tables/table_1_panel_B.tex")

```

### `Replication/Code/replicate_table_4.R`
```r
##--##--##--##
## Table 4
##--##--##--##

## A. U.S. sample
mod1 = lm(degree_violence ~ black + group_goal + commitment , data=us_survey_wave2)
mod2 = lm(recall_violence2 ~ black + group_goal + commitment, data=us_survey_wave2)
mod3 = lm(police_action_required ~ black + group_goal + commitment, data=us_survey_wave2)
stargazer(mod1, mod2, mod3, 
          covariate.labels = c("Black protesters", "Minority group goal",
                               "Commitment to nonviolence", "Intercept: White protesters, generic goal, no commitment"),
          out = "Tables/table_4_panel_A.tex")

## B. Israel sample
mod1_israel = lm(degree_violence ~ identity_protesters + group_goal + commitment, data=isr_survey_wave2)
mod2_israel = lm(recall_violence2 ~ identity_protesters + group_goal + commitment, data=isr_survey_wave2)
mod3_israel = lm(police_action_required ~ identity_protesters + group_goal + commitment, data=isr_survey_wave2)
stargazer(mod1_israel, mod2_israel, mod3_israel,
          covariate.labels = c("Ethiopian protesters", "Arab protesters",
                               "Minority group goal", "Commitment to nonviolence",
                               "Intercept: White protesters, generic goal, no commitment"),
          out = "Tables/table_4_panel_B.tex")

```

### `Replication/Code/replicate_table_A1.R`
```r
##--##--##--##--##--##--##
## Appendix: Table A1
##--##--##--##--##--##--##

stargazer(EBCR_EPR_NAVCO2[,c("YEAR", "success", "INIT_NV_ONSET", "EPR_GROUPSIZE", "EPR_STATUS_ORD",
                             "EPR_STATUS_EXCL", "POP_LOG_LAG_EXT", "GDPPC_LOG_LAG_EXT",
                             "PASTNV", "PASTV", "VDEM_POLYARCHY_LAG", "VDEM_PHYSINT_LAG", 
                             "EPR_TEK_EGIP", "EPR_DOWNGRADED5", "HORIZ_INEQ", "NVYEARS",
                             "VYEARS")],
          covariate.labels = c("Year", "Campaign success", "NV campaign", "EPR group size", "EPR status",
                               "EPR Status: excluded", "Country population (logged)", "Country GDP per capita (logged)", "Prior participation in nonviolence", "Prior participation in violence",
                               "Level of democracy", "Physical integrity index", "Neighboring kin in power",
                               "Downgraded", "Horizontal inequality", "Nonviolent years", "Violent years"),
          out="Tables/table_A1.tex")


```

### `Replication/Code/replicate_table_A10.R`
```r
##--##--##--##--##--##--##
## Appendix: Table A10
##--##--##--##--##--##--##

us_wave2_sumstats = us_survey_wave2[,c("age", "female", "education", "income", "partyID", "pol_views", "interest_politics",
                                       "degree_violence", "police_action_required", "recall_violence2", "race")]
us_wave2_sumstats = dummy_cols(us_wave2_sumstats, select_columns = c("age", "education", "income", "partyID", "pol_views", "race"))
table_a10 = stargazer(us_wave2_sumstats, omit.summary.stat=c("p25", "p75"))
cat(table_a10, sep = '\n', file = "Tables/table_A10.tex")

```

### `Replication/Code/replicate_table_A11.R`
```r
##--##--##--##--##--##--##
## Appendix: Table A11
##--##--##--##--##--##--##

isr_wave2_sumstats = isr_survey_wave2[,c("age", "female", "religiosity", "ethnicity", "education", "income", "partyID", "ideology", 
                                         "degree_violence", "police_action_required", "recall_violence2")]
isr_wave2_sumstats = dummy_cols(isr_wave2_sumstats, select_columns = c("age", "religiosity", "ethnicity", "education", "income", "partyID"))
table_a11 = stargazer(isr_wave2_sumstats, omit.summary.stat=c("p25", "p75"))
cat(table_a11, sep = '\n', file = "Tables/table_A11.tex")

```

### `Replication/Code/replicate_table_A13.R`
```r
##--##--##--##--##--##--##
## Appendix: Table A13
##--##--##--##--##--##--##

## A. U.S. sample
degv_yg = lm(degree_violence ~ identity_protesters + tactic + age +female + education + income  + ideology + race, data=us_survey_wave1, weights=weight)
police_yg = lm(police_action_required ~ identity_protesters + tactic  + age +female + education + income  + ideology + race, data=us_survey_wave1, weights=weight)
recall_violence_yg = lm(recall_violence2 ~ identity_protesters + tactic  + age +female + education + income  + ideology + race, data=us_survey_wave1, weights=weight)
stargazer(degv_yg, recall_violence_yg, police_yg, out = "Tables/table_A13_panel_A.tex")

## B. Israel sample
degv_ip = lm(degree_violence ~ identity_protesters + tactic + age +female + education + income  + ideology + ethnicity, data=isr_survey_wave1, weights=weight)
police_ip = lm(police_action_required ~ identity_protesters + tactic  + age +female + education + income  + ideology + ethnicity , data=isr_survey_wave1, weights=weight)
recall_violence_ip = lm(recall_violence2 ~ identity_protesters + tactic  + age +female + education + income + ideology  + ethnicity , data=isr_survey_wave1, weights=weight)
stargazer(degv_ip, recall_violence_ip, police_ip, out = "Tables/table_A13_panel_B.tex")

```

### `Replication/Code/replicate_table_A14.R`
```r
##--##--##--##
## Table A14
##--##--##--##

us_survey_wave1$identity_protesters_fac = as.factor(us_survey_wave1$identity_protesters)
levels(us_survey_wave1$identity_protesters_fac) = c("White", "Black")
us_survey_wave1$tactic_fac = as.factor(us_survey_wave1$tactic)
levels(us_survey_wave1$tactic_fac) = c("March in streets", "Shut down traffic", "Destroy police cars")

isr_survey_wave1$identity_protesters_fac = as.factor(isr_survey_wave1$identity_protesters)
levels(isr_survey_wave1$identity_protesters_fac) = c("White", "Ethiopian", "Arab")
isr_survey_wave1$tactic_fac = as.factor(isr_survey_wave1$tactic)
levels(isr_survey_wave1$tactic_fac) = c("March in streets", "Shut down traffic", "Destroy garbage cans")


## US sample
us_survey_wave1$degree_violence_std = scale(us_survey_wave1$degree_violence)
us_survey_wave1$police_action_required_std = scale(us_survey_wave1$police_action_required)
us_survey_wave1$recall_violence2_std = scale(us_survey_wave1$recall_violence2)

march1 = lm_robust(degree_violence_std ~ identity_protesters_fac, data=us_survey_wave1[us_survey_wave1$tactic==0,], weights=weight)
shut1 = lm_robust(degree_violence_std ~ identity_protesters_fac, data=us_survey_wave1[us_survey_wave1$tactic==1,], weights=weight)
destroy1 = lm_robust(degree_violence_std ~ identity_protesters_fac , data=us_survey_wave1[us_survey_wave1$tactic==2,], weights=weight)

march2 = lm_robust(police_action_required_std ~ identity_protesters_fac, data=us_survey_wave1[us_survey_wave1$tactic==0,], weights=weight)
shut2 = lm_robust(police_action_required_std ~ identity_protesters_fac, data=us_survey_wave1[us_survey_wave1$tactic==1,], weights=weight)
destroy2 = lm_robust(police_action_required_std ~ identity_protesters_fac, data=us_survey_wave1[us_survey_wave1$tactic==2,], weights=weight)

march3 = lm_robust(recall_violence2_std ~ identity_protesters_fac, data=us_survey_wave1[us_survey_wave1$tactic==0,], weights=weight)
shut3 = lm_robust(recall_violence2_std ~ identity_protesters_fac, data=us_survey_wave1[us_survey_wave1$tactic==1,], weights=weight)
destroy3 = lm_robust(recall_violence2_std ~ identity_protesters_fac , data=us_survey_wave1[us_survey_wave1$tactic==2,], weights=weight)

# Plot differences

term_degree_violence = c(march1$coefficients[2], shut1$coefficients[2], destroy1$coefficients[2])
se_degree_violence = c(march1$std.error[2], shut1$std.error[2], destroy1$std.error[2])
statistic_degree_violence = c(march1$statistic[2], shut1$statistic[2], destroy1$statistic[2])
pval_degree_violence = c(march1$p.value[2], shut1$p.value[2], destroy1$p.value[2])
term = c("1) Minority: March in streets", "2) Minority: Shut down traffic", "3) Minority: Destroy police cars / garbage cans")
degree_violence = as.data.frame(cbind(term_degree_violence, se_degree_violence, statistic_degree_violence, pval_degree_violence))
degree_violence = cbind(degree_violence, term)
colnames(degree_violence) = c("estimate", "std.error", "statistic", "p.value", "term")
rownames(degree_violence) = term
degree_violence$model = "Perceived degree of violence"

term_police_action_required = c(march2$coefficients[2], shut2$coefficients[2], destroy2$coefficients[2])
se_police_action_required = c(march2$std.error[2], shut2$std.error[2], destroy2$std.error[2])
statistic_police_action_required = c(march2$statistic[2], shut2$statistic[2], destroy2$statistic[2])
pval_police_action_required = c(march2$p.value[2], shut2$p.value[2], destroy2$p.value[2])
term = c("1) Minority: March in streets", "2) Minority: Shut down traffic", "3) Minority: Destroy police cars / garbage cans")
police_action_required = as.data.frame(cbind(term_police_action_required, se_police_action_required, statistic_police_action_required, pval_police_action_required))
police_action_required = cbind(police_action_required, term)
colnames(police_action_required) = c("estimate", "std.error", "statistic", "p.value", "term")
rownames(police_action_required) = term
police_action_required$model = "Police action required"

term_recall_violence = c(march3$coefficients[2], shut3$coefficients[2], destroy3$coefficients[2])
se_recall_violence = c(march3$std.error[2], shut3$std.error[2], destroy3$std.error[2])
statistic_recall_violence = c(march3$statistic[2], shut3$statistic[2], destroy3$statistic[2])
pval_recall_violence = c(march3$p.value[2], shut3$p.value[2], destroy3$p.value[2])
term = c("1) Minority: March in streets", "2) Minority: Shut down traffic", "3) Minority: Destroy police cars / garbage cans")
recall_violence = as.data.frame(cbind(term_recall_violence, se_recall_violence, statistic_recall_violence, pval_recall_violence))
recall_violence = cbind(recall_violence, term)
colnames(recall_violence) = c("estimate", "std.error", "statistic", "p.value", "term")
rownames(recall_violence) = term
recall_violence$model = "Recall violence"

differences_us = rbind(degree_violence, police_action_required, recall_violence)


## Israel respondents
isr_survey_wave1$degree_violence_std = scale(isr_survey_wave1$degree_violence)
isr_survey_wave1$police_action_required_std = scale(isr_survey_wave1$police_action_required)
isr_survey_wave1$recall_violence2_std = scale(isr_survey_wave1$recall_violence2)

march1 = lm_robust(degree_violence_std ~ identity_protesters_fac, data=isr_survey_wave1[isr_survey_wave1$tactic==0,], weights=weight)
shut1 = lm_robust(degree_violence_std ~ identity_protesters_fac, data=isr_survey_wave1[isr_survey_wave1$tactic==1,], weights=weight)
destroy1 = lm_robust(degree_violence_std ~ identity_protesters_fac , data=isr_survey_wave1[isr_survey_wave1$tactic==2,], weights=weight)

march2 = lm_robust(police_action_required_std ~ identity_protesters_fac, data=isr_survey_wave1[isr_survey_wave1$tactic==0,], weights=weight)
shut2 = lm_robust(police_action_required_std ~ identity_protesters_fac, data=isr_survey_wave1[isr_survey_wave1$tactic==1,], weights=weight)
destroy2 = lm_robust(police_action_required_std ~ identity_protesters_fac, data=isr_survey_wave1[isr_survey_wave1$tactic==2,], weights=weight)

march3 = lm_robust(recall_violence2_std ~ identity_protesters_fac, data=isr_survey_wave1[isr_survey_wave1$tactic==0,], weights=weight)
shut3 = lm_robust(recall_violence2_std ~ identity_protesters_fac, data=isr_survey_wave1[isr_survey_wave1$tactic==1,], weights=weight)
destroy3 = lm_robust(recall_violence2_std ~ identity_protesters_fac , data=isr_survey_wave1[isr_survey_wave1$tactic==2,], weights=weight)


# Ethiopian protesters
term_degree_violence = c(march1$coefficients[2], shut1$coefficients[2], destroy1$coefficients[2])
se_degree_violence = c(march1$std.error[2], shut1$std.error[2], destroy1$std.error[2])
statistic_degree_violence = c(march1$statistic[2], shut1$statistic[2], destroy1$statistic[2])
pval_degree_violence = c(march1$p.value[2], shut1$p.value[2], destroy1$p.value[2])
term = c("1) Minority: March in streets", "2) Minority: Shut down traffic", "3) Minority: Destroy police cars / garbage cans")
degree_violence = as.data.frame(cbind(term_degree_violence, se_degree_violence, statistic_degree_violence, pval_degree_violence))
degree_violence = cbind(degree_violence, term)
colnames(degree_violence) = c("estimate", "std.error", "statistic", "p.value", "term")
rownames(degree_violence) = term
degree_violence$model = "Perceived degree of violence"

term_police_action_required = c(march2$coefficients[2], shut2$coefficients[2], destroy2$coefficients[2])
se_police_action_required = c(march2$std.error[2], shut2$std.error[2], destroy2$std.error[2])
statistic_police_action_required = c(march2$statistic[2], shut2$statistic[2], destroy2$statistic[2])
pval_police_action_required = c(march2$p.value[2], shut2$p.value[2], destroy2$p.value[2])
term = c("1) Minority: March in streets", "2) Minority: Shut down traffic", "3) Minority: Destroy police cars / garbage cans")
police_action_required = as.data.frame(cbind(term_police_action_required, se_police_action_required, statistic_police_action_required, pval_police_action_required))
police_action_required = cbind(police_action_required, term)
colnames(police_action_required) = c("estimate", "std.error", "statistic", "p.value", "term")
rownames(police_action_required) = term
police_action_required$model = "Police action required"

term_recall_violence = c(march3$coefficients[2], shut3$coefficients[2], destroy3$coefficients[2])
se_recall_violence = c(march3$std.error[2], shut3$std.error[2], destroy3$std.error[2])
statistic_recall_violence = c(march3$statistic[2], shut3$statistic[2], destroy3$statistic[2])
pval_recall_violence = c(march3$p.value[2], shut3$p.value[2], destroy3$p.value[2])
term = c("1) Minority: March in streets", "2) Minority: Shut down traffic", "3) Minority: Destroy police cars / garbage cans")
recall_violence = as.data.frame(cbind(term_recall_violence, se_recall_violence, statistic_recall_violence, pval_recall_violence))
recall_violence = cbind(recall_violence, term)
colnames(recall_violence) = c("estimate", "std.error", "statistic", "p.value", "term")
rownames(recall_violence) = term
recall_violence$model = "Recall violence"

differences_isr_black = rbind(degree_violence, police_action_required, recall_violence)

term_degree_violence = c(march1$coefficients[3], shut1$coefficients[3], destroy1$coefficients[3])
se_degree_violence = c(march1$std.error[3], shut1$std.error[3], destroy1$std.error[3])
statistic_degree_violence = c(march1$statistic[3], shut1$statistic[3], destroy1$statistic[3])
pval_degree_violence = c(march1$p.value[3], shut1$p.value[3], destroy1$p.value[3])
term = c("1) Minority: March in streets", "2) Minority: Shut down traffic", "3) Minority: Destroy police cars / garbage cans")
degree_violence = as.data.frame(cbind(term_degree_violence, se_degree_violence, statistic_degree_violence, pval_degree_violence))
degree_violence = cbind(degree_violence, term)
colnames(degree_violence) = c("estimate", "std.error", "statistic", "p.value", "term")
rownames(degree_violence) = term
degree_violence$model = "Perceived degree of violence"

term_police_action_required = c(march2$coefficients[3], shut2$coefficients[3], destroy2$coefficients[3])
se_police_action_required = c(march2$std.error[3], shut2$std.error[3], destroy2$std.error[3])
statistic_police_action_required = c(march2$statistic[3], shut2$statistic[3], destroy2$statistic[3])
pval_police_action_required = c(march2$p.value[3], shut2$p.value[3], destroy2$p.value[3])
term = c("1) Minority: March in streets", "2) Minority: Shut down traffic", "3) Minority: Destroy police cars / garbage cans")
police_action_required = as.data.frame(cbind(term_police_action_required, se_police_action_required, statistic_police_action_required, pval_police_action_required))
police_action_required = cbind(police_action_required, term)
colnames(police_action_required) = c("estimate", "std.error", "statistic", "p.value", "term")
rownames(police_action_required) = term
police_action_required$model = "Police action required"

term_recall_violence = c(march3$coefficients[3], shut3$coefficients[3], destroy3$coefficients[3])
se_recall_violence = c(march3$std.error[3], shut3$std.error[3], destroy3$std.error[3])
statistic_recall_violence = c(march3$statistic[3], shut3$statistic[3], destroy3$statistic[3])
pval_recall_violence = c(march3$p.value[3], shut3$p.value[3], destroy3$p.value[3])
term = c("1) Minority: March in streets", "2) Minority: Shut down traffic", "3) Minority: Destroy police cars / garbage cans")
recall_violence = as.data.frame(cbind(term_recall_violence, se_recall_violence, statistic_recall_violence, pval_recall_violence))
recall_violence = cbind(recall_violence, term)
colnames(recall_violence) = c("estimate", "std.error", "statistic", "p.value", "term")
rownames(recall_violence) = term
recall_violence$model = "Recall violence"

differences_isr_arab = rbind(degree_violence, police_action_required, recall_violence)

## Result tables for plot
differences_us2 = differences_us
differences_us2$submodel = differences_us2$term
differences_us2$term = "Perception of Blacks \n(United States)"

differences_isr_black2 = differences_isr_black
differences_isr_black2$submodel = differences_isr_black2$term
differences_isr_black2$term = "Perception of Ethiopians \n(Israel)"

differences_isr_arab2 = differences_isr_arab
differences_isr_arab2$submodel = differences_isr_arab2$term
differences_isr_arab2$term = "Perception of Arabs \n(Israel)"

diffs_sm = rbind(differences_us2, differences_isr_arab2, differences_isr_black2)
rownames(diffs_sm) = 1:nrow(diffs_sm)

results_df <- data.frame(term = diffs_sm$term,
                         estimate = diffs_sm$estimate,
                         std.error = diffs_sm$std.error,
                         model = diffs_sm$model,
                         submodel = as.character(diffs_sm$submodel),
                         stringsAsFactors = FALSE)

results_df$submodel[results_df$submodel=="1) Minority: March in streets"] = "March in streets"
results_df$submodel[results_df$submodel=="2) Minority: Shut down traffic"] = "Shut down traffic"
results_df$submodel[results_df$submodel=="3) Minority: Destroy police cars / garbage cans"] = "Destroy property"

results_df$model[results_df$model=="Perceived degree of violence"] = "1. Perceived degree \nof violence"
results_df$model[results_df$model=="Police action required"] = "3. Police action \nrequired"
results_df$model[results_df$model=="Recall violence"] = "2. Recall \nviolence"


table_a14 = xtable(results_df[,-1], digits=2)
print(table_a14, file="Tables/table_A14.tex")


```

### `Replication/Code/replicate_table_A15.R`
```r
##--##--##--##--##--##--##
## Appendix: Table A15
##--##--##--##--##--##--##

## A. U.S. sample
degv_yg = lm(degree_violence ~ identity_protesters * tactic  , data=us_survey_wave1, weights=weight)
police_yg = lm(police_action_required ~ identity_protesters * tactic  , data=us_survey_wave1, weights=weight)
recall_violence_yg = lm(recall_violence2 ~ identity_protesters * tactic  , data=us_survey_wave1, weights=weight)
stargazer(degv_yg, recall_violence_yg, police_yg, 
          covariate.labels = c("Black protesters", "Shut down traffic", "Destroy police cars",
                               "Black protesters x Shut down traffic", 
                               "Black protesters x Destroy police cars", "Intercept"),
          out = "Tables/table_A15_panel_A.tex")

## B. Israel sample
degv_isr = lm(degree_violence ~ identity_protesters * tactic  , data=isr_survey_wave1, weights=weight)
police_isr = lm(police_action_required ~ identity_protesters * tactic  , data=isr_survey_wave1, weights=weight)
recall_violence_isr = lm(recall_violence2 ~ identity_protesters * tactic  , data=isr_survey_wave1, weights=weight)
stargazer(degv_isr, recall_violence_isr, police_isr,
          covariate.labels = c("Ethiopian protesters", "Arab protesters", "Shut down traffic",
                               "Destroy garbage cans", "Ethiopian protesters x Shut down traffic",
                               "Arab protesters x Shut down traffic", "Ethiopian protesters x Destroy garbage cans",
                               "Arab protesters x Destroy garbage cans", "Intercept"),
          out = "Tables/table_A15_panel_B.tex")


```

### `Replication/Code/replicate_table_A16.R`
```r
##--##--##--##--##--##--##
## Appendix: Table A16
##--##--##--##--##--##--##

## A. U.S. 
degv_yg_nv_maj = lm_robust(degree_violence ~ identity_protesters  , data=us_survey_wave1[us_survey_wave1$tactic==0 & us_survey_wave1$race=="White",], weights=weight)
police_yg_nv_maj = lm_robust(police_action_required ~ identity_protesters  , data=us_survey_wave1[us_survey_wave1$tactic==0 & us_survey_wave1$race == "White",], weights=weight)
degv_yg_nv_min = lm_robust(degree_violence ~ identity_protesters  , data=us_survey_wave1[us_survey_wave1$tactic==0 & us_survey_wave1$race=="Black",], weights=weight)
police_yg_nv_min = lm_robust(police_action_required ~ identity_protesters  , data=us_survey_wave1[us_survey_wave1$tactic==0 & us_survey_wave1$race == "Black",], weights=weight)

# Majority perceptions
us_mean_degv_maj_white = degv_yg_nv_maj$coefficients[1]
us_mean_degv_maj_black = degv_yg_nv_maj$coefficients[1] + degv_yg_nv_maj$coefficients[2] 
us_diff_degv_maj = degv_yg_nv_maj$coefficients[2]
us_pval_diff_degv_maj = degv_yg_nv_maj$p.value[2]
us_pct_change_degv_maj = (degv_yg_nv_maj$coefficients[2] /us_mean_degv_maj_white)*100
us_mean_police_maj_white = police_yg_nv_maj$coefficients[1]
us_mean_police_maj_black = police_yg_nv_maj$coefficients[1] + police_yg_nv_maj$coefficients[2] 
us_diff_police_maj = police_yg_nv_maj$coefficients[2]
us_pval_diff_police_maj = police_yg_nv_maj$p.value[2]
us_pct_change_police_maj = (police_yg_nv_maj$coefficients[2] /us_mean_police_maj_white)*100

# Minority perceptions
us_mean_degv_min_white = degv_yg_nv_min$coefficients[1]
us_mean_degv_min_black = degv_yg_nv_min$coefficients[1] + degv_yg_nv_min$coefficients[2] 
us_diff_degv_min = degv_yg_nv_min$coefficients[2]
us_pval_diff_degv_min = degv_yg_nv_min$p.value[2]
us_pct_change_degv_min = (degv_yg_nv_min$coefficients[2] /us_mean_degv_min_white)*100
us_mean_police_min_white = police_yg_nv_min$coefficients[1]
us_mean_police_min_black = police_yg_nv_min$coefficients[1] + police_yg_nv_min$coefficients[2] 
us_diff_police_min = police_yg_nv_min$coefficients[2]
us_pval_diff_police_min = police_yg_nv_min$p.value[2]
us_pct_change_police_min = (police_yg_nv_min$coefficients[2] /us_mean_police_min_white)*100


## B. ISRAEL
degv_isr_nv_maj = lm_robust(degree_violence ~ identity_protesters  , data=isr_survey_wave1[isr_survey_wave1$survey=="isr" & isr_survey_wave1$tactic==0 &  isr_survey_wave1$ethnicity!= "Ethiopia",])
police_isr_nv_maj = lm_robust(police_action_required ~ identity_protesters  , data=isr_survey_wave1[isr_survey_wave1$survey=="isr" & isr_survey_wave1$tactic==0 & isr_survey_wave1$ethnicity!= "Ethiopia",])
degv_isr_nv_min = lm_robust(degree_violence ~ identity_protesters  , data=isr_survey_wave1[isr_survey_wave1$survey=="isr_ar" & isr_survey_wave1$tactic==0,])
police_isr_nv_min = lm_robust(police_action_required ~ identity_protesters  , data=isr_survey_wave1[isr_survey_wave1$survey=="isr_ar" & isr_survey_wave1$tactic==0,])

# Majority perceptions
israel_mean_degv_maj_whitejew = degv_isr_nv_maj$coefficients[1]
isr_mean_degv_maj_eth = degv_isr_nv_maj$coefficients[1] + degv_isr_nv_maj$coefficients[2] 
isr_mean_degv_maj_arab = degv_isr_nv_maj$coefficients[1] + degv_isr_nv_maj$coefficients[3] 
isr_diff_degv_maj_eth = degv_isr_nv_maj$coefficients[2]
isr_diff_degv_maj_arab = degv_isr_nv_maj$coefficients[3]
isr_pval_diff_degv_maj_eth = degv_isr_nv_maj$p.value[2]
isr_pval_diff_degv_maj_arab = degv_isr_nv_maj$p.value[3]
isr_pct_change_degv_maj_eth = (degv_isr_nv_maj$coefficients[2] /israel_mean_degv_maj_whitejew)*100
isr_pct_change_degv_maj_arab = (degv_isr_nv_maj$coefficients[3] /israel_mean_degv_maj_whitejew)*100
israel_mean_police_maj_whitejew = police_isr_nv_maj$coefficients[1]
isr_mean_police_maj_eth = police_isr_nv_maj$coefficients[1] + police_isr_nv_maj$coefficients[2] 
isr_mean_police_maj_arab = police_isr_nv_maj$coefficients[1] + police_isr_nv_maj$coefficients[3] 
isr_diff_police_maj_eth = police_isr_nv_maj$coefficients[2]
isr_diff_police_maj_arab = police_isr_nv_maj$coefficients[3]
isr_pval_diff_police_maj_eth = police_isr_nv_maj$p.value[2]
isr_pval_diff_police_maj_arab = police_isr_nv_maj$p.value[3]
isr_pct_change_police_maj_eth = (police_isr_nv_maj$coefficients[2] /israel_mean_police_maj_whitejew)*100
isr_pct_change_police_maj_arab = (police_isr_nv_maj$coefficients[3] /israel_mean_police_maj_whitejew)*100

## Minority perceptions
israel_mean_degv_min_whitejew = degv_isr_nv_min$coefficients[1]
isr_mean_degv_min_eth = degv_isr_nv_min$coefficients[1] + degv_isr_nv_min$coefficients[2] 
isr_mean_degv_min_arab = degv_isr_nv_min$coefficients[1] + degv_isr_nv_min$coefficients[3] 
isr_diff_degv_min_eth = degv_isr_nv_min$coefficients[2]
isr_diff_degv_min_arab = degv_isr_nv_min$coefficients[3]
isr_pval_diff_degv_min_eth = degv_isr_nv_min$p.value[2]
isr_pval_diff_degv_min_arab = degv_isr_nv_min$p.value[3]
isr_pct_change_degv_min_eth = (degv_isr_nv_min$coefficients[2] /israel_mean_degv_min_whitejew)*100
isr_pct_change_degv_min_arab = (degv_isr_nv_min$coefficients[3] /israel_mean_degv_min_whitejew)*100
israel_mean_police_min_whitejew = police_isr_nv_min$coefficients[1]
isr_mean_police_min_eth = police_isr_nv_min$coefficients[1] + police_isr_nv_min$coefficients[2] 
isr_mean_police_min_arab = police_isr_nv_min$coefficients[1] + police_isr_nv_min$coefficients[3] 
isr_diff_police_min_eth = police_isr_nv_min$coefficients[2]
isr_diff_police_min_arab = police_isr_nv_min$coefficients[3]
isr_pval_diff_police_min_eth = police_isr_nv_min$p.value[2]
isr_pval_diff_police_min_arab = police_isr_nv_min$p.value[3]
isr_pct_change_police_min_eth = (police_isr_nv_min$coefficients[2] /israel_mean_police_min_whitejew)*100
isr_pct_change_police_min_arab = (police_isr_nv_min$coefficients[3] /israel_mean_police_min_whitejew)*100

us_degv_maj = c(us_mean_degv_maj_white, us_mean_degv_maj_black, us_diff_degv_maj, us_pval_diff_degv_maj, us_pct_change_degv_maj)
us_degv_min = c(us_mean_degv_min_white, us_mean_degv_min_black, us_diff_degv_min, us_pval_diff_degv_min, us_pct_change_degv_min)
us_police_maj = c(us_mean_police_maj_white, us_mean_police_maj_black, us_diff_police_maj, us_pval_diff_police_maj, us_pct_change_police_maj)
us_police_min = c(us_mean_police_min_white, us_mean_police_min_black, us_diff_police_min, us_pval_diff_police_min, us_pct_change_police_min)

isr_degv_maj_eth = c(israel_mean_degv_maj_whitejew, isr_mean_degv_maj_eth, isr_diff_degv_maj_eth, isr_pval_diff_degv_maj_eth, isr_pct_change_degv_maj_eth)
isr_degv_maj_arab = c(israel_mean_degv_maj_whitejew, isr_mean_degv_maj_arab, isr_diff_degv_maj_arab, isr_pval_diff_degv_maj_arab, isr_pct_change_degv_maj_arab)
isr_degv_min_eth = c(israel_mean_degv_min_whitejew, isr_mean_degv_min_eth, isr_diff_degv_min_eth, isr_pval_diff_degv_min_eth, isr_pct_change_degv_min_eth)
isr_degv_min_arab = c(israel_mean_degv_min_whitejew, isr_mean_degv_min_arab, isr_diff_degv_min_arab, isr_pval_diff_degv_min_arab, isr_pct_change_degv_min_arab)
isr_police_maj_eth = c(israel_mean_police_maj_whitejew, isr_mean_police_maj_eth, isr_diff_police_maj_eth, isr_pval_diff_police_maj_eth, isr_pct_change_police_maj_eth)
isr_police_maj_arab = c(israel_mean_police_maj_whitejew, isr_mean_police_maj_arab, isr_diff_police_maj_arab, isr_pval_diff_police_maj_arab, isr_pct_change_police_maj_arab)
isr_police_min_eth = c(israel_mean_police_min_whitejew, isr_mean_police_min_eth, isr_diff_police_min_eth, isr_pval_diff_police_min_eth, isr_pct_change_police_min_eth)
isr_police_min_arab = c(israel_mean_police_min_whitejew, isr_mean_police_min_arab, isr_diff_police_min_arab, isr_pval_diff_police_min_arab, isr_pct_change_police_min_arab)

pct_change_tab = rbind(us_degv_maj, us_degv_min, us_police_maj, us_police_min, 
                       isr_degv_maj_arab, isr_degv_min_arab, isr_police_maj_arab, isr_police_min_arab,
                       isr_degv_maj_eth, isr_degv_min_eth, isr_police_maj_eth, isr_police_min_eth) 
colnames(pct_change_tab) = c("Mean (majority)", "Mean (minority)", "Difference", "P-value", "Percent change")

table_a15 = xtable(pct_change_tab, digits=2)
print(table_a15, file="Tables/table_A16.tex")

```

### `Replication/Code/replicate_table_A17.R`
```r
##--##--##--##--##--##--##
## Appendix: Table A17
##--##--##--##--##--##--##

## A. U.S. sample
mod1 = lm(degree_violence ~ black + group_goal + commitment + age + female +education + income + pol_views + race, data=us_survey_wave2)
mod2 = lm(recall_violence2 ~ black + group_goal + commitment + age + female +education + income + pol_views + race, data=us_survey_wave2)
mod3 = lm(police_action_required ~ black + group_goal + commitment + age + female +education + income + pol_views + race, data=us_survey_wave2)
stargazer(mod1, mod2, mod3, out="Tables/table_A17_panel_A.tex")

## B. Israel sample
mod1_israel = lm(degree_violence ~ identity_protesters + group_goal + commitment + age + female +education + income + ideology + ethnicity, data=isr_survey_wave2)
mod2_israel = lm(recall_violence2 ~ identity_protesters + group_goal + commitment + age + female +education + income + ideology + ethnicity, data=isr_survey_wave2)
mod3_israel = lm(police_action_required ~ identity_protesters + group_goal + commitment + age + female +education + income + ideology + ethnicity, data=isr_survey_wave2)
stargazer(mod1_israel, mod2_israel, mod3_israel, out="Tables/table_A17_panel_B.tex")

```

### `Replication/Code/replicate_table_A18.R`
```r
##--##--##--##--##--##--##
## Appendix: Table A18
##--##--##--##--##--##--##

generic_goal_dv = lm(degree_violence ~ identity_protesters + commitment , data=isr_survey_wave2[isr_survey_wave2$group_goal==0,])
generic_goal_rv = lm(recall_violence2 ~ identity_protesters + commitment , data=isr_survey_wave2[isr_survey_wave2$group_goal==0,])
generic_goal_paq = lm(police_action_required ~ identity_protesters + commitment , data=isr_survey_wave2[isr_survey_wave2$group_goal==0,])
stargazer(generic_goal_dv, generic_goal_rv, generic_goal_paq,
          covariate.labels = c("Ethiopian protesters", "Arab protesters",
                               "Commitment to nonviolence", "Intercept: White protesters, generic goal, no commitment"),
          out = "Tables/table_A18.tex")

```

### `Replication/Code/replicate_table_A2.R`
```r
##--##--##--##--##--##--##
## Appendix: Table A2
##--##--##--##--##--##--##

nv_majority = prop.table(table(NAVCO2_EPR$success[NAVCO2_EPR$navco1designation==1 & NAVCO2_EPR$EPR_STATUS_EXCL==0]))
v_majority = prop.table(table(NAVCO2_EPR$success[NAVCO2_EPR$navco1designation==0 & NAVCO2_EPR$EPR_STATUS_EXCL==0]))
nv_minority = prop.table(table(NAVCO2_EPR$success[NAVCO2_EPR$navco1designation==1 & NAVCO2_EPR$EPR_STATUS_EXCL==1]))
v_minority = prop.table(table(NAVCO2_EPR$success[NAVCO2_EPR$navco1designation==0 & NAVCO2_EPR$EPR_STATUS_EXCL==1]))

navco_table = cbind(nv_majority, v_majority, nv_minority, v_minority)
rownames(navco_table) = c("Campaign failure",   "Campaign success")

table_a2 = xtable(navco_table, digits=2)
print(table_a2, file="Tables/table_A2.tex")
```

### `Replication/Code/replicate_table_A3.R`
```r
##--##--##--##--##--##--##
## Appendix: Table A3
##--##--##--##--##--##--##

tab1 = lm(success ~  EPR_STATUS_EXCL* INIT_NV_ONSET , data= EBCR_EPR_NAVCO2) 
tab2 = lm(success ~  EPR_STATUS_EXCL *  INIT_NV_ONSET + EPR_GROUPSIZE + POP_LOG_LAG_EXT + GDPPC_LOG_LAG_EXT + PASTNV + PASTV + VDEM_POLYARCHY_LAG + VDEM_PHYSINT_LAG + NVYEARS +I(NVYEARS^2) + I(NVYEARS^3) + VYEARS + I(VYEARS^2) + I(VYEARS^3), data= EBCR_EPR_NAVCO2) 
tab3 = lm(success ~  EPR_STATUS_EXCL *  INIT_NV_ONSET + EPR_GROUPSIZE + POP_LOG_LAG_EXT + GDPPC_LOG_LAG_EXT + PASTNV + PASTV + VDEM_POLYARCHY_LAG + VDEM_PHYSINT_LAG + EPR_TEK_EGIP + EPR_DOWNGRADED5 + HORIZ_INEQ + NVYEARS + I(NVYEARS^2) + I(NVYEARS^3) + VYEARS + I(VYEARS^2) + I(VYEARS^3) , data= EBCR_EPR_NAVCO2)  
tab4 = lm(success ~  EPR_STATUS_ORD* INIT_NV_ONSET , data= EBCR_EPR_NAVCO2) 
tab5 = lm(success ~  EPR_STATUS_ORD *  INIT_NV_ONSET + EPR_GROUPSIZE + POP_LOG_LAG_EXT + GDPPC_LOG_LAG_EXT + PASTNV + PASTV + VDEM_POLYARCHY_LAG + VDEM_PHYSINT_LAG + NVYEARS +I(NVYEARS^2) + I(NVYEARS^3) + VYEARS + I(VYEARS^2) + I(VYEARS^3), data= EBCR_EPR_NAVCO2) 
tab6 = lm(success ~  EPR_STATUS_ORD *  INIT_NV_ONSET + EPR_GROUPSIZE + POP_LOG_LAG_EXT + GDPPC_LOG_LAG_EXT + PASTNV + PASTV + VDEM_POLYARCHY_LAG + VDEM_PHYSINT_LAG + EPR_TEK_EGIP + EPR_DOWNGRADED5 + HORIZ_INEQ + NVYEARS + I(NVYEARS^2) + I(NVYEARS^3) + VYEARS + I(VYEARS^2) + I(VYEARS^3) , data= EBCR_EPR_NAVCO2)  

stargazer(tab4, tab5, tab6, tab1, tab2, tab3, table.placement="H", order = c(3,1,20, 2, 21),
          covariate.labels = c("NV campaign", "EPR Status", "EPR Status × NV Campaign",
                               "EPR Status: Excluded", "EPR Status: Excluded × NV Campaign",
                               "EPR group size", "Country population", "Country GDP per capita",
                               "Prior participation in NV", "Prior participation in V",
                               "Level of democracy", "Physical integrity index", "Neighboring kin in power",
                               "Group status downgraded", "Horizontal inequality"),
          omit = c("VYEARS", "NVYEARS"),
          out="Tables/table_A3.tex")

```

### `Replication/Code/replicate_table_A4.R`
```r
##--##--##--##--##--##--##
## Appendix: Table A4
##--##--##--##--##--##--##

tab7 = lm(success ~  EPR_GROUPSIZE* INIT_NV_ONSET , data= EBCR_EPR_NAVCO2) 
tab8 = lm(success ~  EPR_GROUPSIZE *  INIT_NV_ONSET  + POP_LOG_LAG_EXT + GDPPC_LOG_LAG_EXT + PASTNV + PASTV + VDEM_POLYARCHY_LAG + VDEM_PHYSINT_LAG + NVYEARS +I(NVYEARS^2) + I(NVYEARS^3) + VYEARS + I(VYEARS^2) + I(VYEARS^3), data= EBCR_EPR_NAVCO2) 
tab9 = lm(success ~  EPR_GROUPSIZE *  INIT_NV_ONSET  + POP_LOG_LAG_EXT + GDPPC_LOG_LAG_EXT + PASTNV + PASTV + VDEM_POLYARCHY_LAG + VDEM_PHYSINT_LAG + EPR_TEK_EGIP + EPR_DOWNGRADED5 + HORIZ_INEQ + NVYEARS + I(NVYEARS^2) + I(NVYEARS^3) + VYEARS + I(VYEARS^2) + I(VYEARS^3) , data= EBCR_EPR_NAVCO2)  

stargazer(tab7, tab8, tab9, table.placement="H", order = c(2,1,18),
          covariate.labels = c("NV campaign", "EPR group size", "EPR group size × NV campaign",
                               "Country population", "Country GDP per capita",
                               "Prior participation in NV", "Prior participation in V",
                               "Level of democracy", "Physical integrity index", 
                               "Neighboring kin in power", "Group status downgraded",
                               "Horizontal inequality"),
          omit = c("VYEARS", "NVYEARS"),
          out="Tables/table_A4.tex")
```

### `Replication/Code/replicate_table_A5.R`
```r
##--##--##--##--##--##--##
## Appendix: Table A5
##--##--##--##--##--##--##

# Status (excluded, not excluded)

nv_status = lm(success ~  EPR_STATUS_EXCL + EPR_GROUPSIZE + POP_LOG_LAG_EXT + GDPPC_LOG_LAG_EXT + PASTNV + PASTV + VDEM_POLYARCHY_LAG + VDEM_PHYSINT_LAG + EPR_TEK_EGIP + EPR_DOWNGRADED5 + HORIZ_INEQ + NVYEARS + I(NVYEARS^2) + I(NVYEARS^3) + VYEARS + I(VYEARS^2) + I(VYEARS^3) , data= EBCR_EPR_NAVCO2[EBCR_EPR_NAVCO2$INIT_NV_ONSET==1,])  
v_status = lm(success ~  EPR_STATUS_EXCL + EPR_GROUPSIZE + POP_LOG_LAG_EXT + GDPPC_LOG_LAG_EXT + PASTNV + PASTV + VDEM_POLYARCHY_LAG + VDEM_PHYSINT_LAG + EPR_TEK_EGIP + EPR_DOWNGRADED5 + HORIZ_INEQ + NVYEARS + I(NVYEARS^2) + I(NVYEARS^3) + VYEARS + I(VYEARS^2) + I(VYEARS^3) , data= EBCR_EPR_NAVCO2[EBCR_EPR_NAVCO2$INIT_V_ONSET==1,])  

preds_nv = ggpredict(nv_status, terms = c("EPR_STATUS_EXCL"))
preds_nv$tactic = "Non-violent"
preds_v = ggpredict(v_status, terms = c("EPR_STATUS_EXCL"))
preds_v$tactic = "Violent"

preds_status = rbind(preds_nv, preds_v)
preds_status$tactic <- factor(preds_status$tactic, levels = c("Violent", "Non-violent"))
preds_status$Status = "Excluded"
preds_status$Status[preds$x==0] = "Not excluded"
preds_status$type = "status"

## Size (above and below the mean of the distribution)

EBCR_EPR_NAVCO2$small_size = NA
EBCR_EPR_NAVCO2$small_size[EBCR_EPR_NAVCO2$EPR_GROUPSIZE < mean(EBCR_EPR_NAVCO2$EPR_GROUPSIZE, na.rm=T)] = 1
EBCR_EPR_NAVCO2$small_size[EBCR_EPR_NAVCO2$EPR_GROUPSIZE >= mean(EBCR_EPR_NAVCO2$EPR_GROUPSIZE, na.rm=T)] = 0

nv_size = lm(success ~  small_size  + POP_LOG_LAG_EXT + GDPPC_LOG_LAG_EXT + PASTNV + PASTV + VDEM_POLYARCHY_LAG + VDEM_PHYSINT_LAG + EPR_TEK_EGIP + EPR_DOWNGRADED5 + HORIZ_INEQ + NVYEARS + I(NVYEARS^2) + I(NVYEARS^3) + VYEARS + I(VYEARS^2) + I(VYEARS^3) , data= EBCR_EPR_NAVCO2[EBCR_EPR_NAVCO2$INIT_NV_ONSET==1,])  
v_size = lm(success ~  small_size  + POP_LOG_LAG_EXT + GDPPC_LOG_LAG_EXT + PASTNV + PASTV + VDEM_POLYARCHY_LAG + VDEM_PHYSINT_LAG + EPR_TEK_EGIP + EPR_DOWNGRADED5 + HORIZ_INEQ + NVYEARS + I(NVYEARS^2) + I(NVYEARS^3) + VYEARS + I(VYEARS^2) + I(VYEARS^3) , data= EBCR_EPR_NAVCO2[EBCR_EPR_NAVCO2$INIT_V_ONSET==1,])  

preds_nv = ggpredict(nv_size, terms = c("small_size"))
preds_nv$tactic = "Non-violent"
preds_v = ggpredict(v_size, terms = c("small_size"))
preds_v$tactic = "Violent"

preds_size = rbind(preds_nv, preds_v)
preds_size$tactic <- factor(preds_size$tactic, levels = c("Violent", "Non-violent"))
preds_size$Status = "Group size < mean"
preds_size$Status[preds_size$x==0] = "Group size >= mean"
preds_size$type = "size"

preds_all = as.data.frame(rbind(preds_status, preds_size))
preds_all = preds_all[,c("predicted", "std.error", "conf.low", "conf.high",
                         "tactic", "Status")]
table_a5 = xtable(preds_all, digits=2)
print(table_a5, file="Tables/table_A5.tex")

```

### `Replication/Code/replicate_table_A6.R`
```r
##--##--##--##--##--##--##
## Appendix: Table A6
##--##--##--##--##--##--##

pol_irr1 = lm(success ~  navco1designation , 
              data= NAVCO2[!(NAVCO2$id %in% NAVCO2_EPR$id),])
pol_irr2 = lm(success ~  navco1designation , 
              data= NAVCO2[NAVCO2$id %in% NAVCO2_EPR$id[NAVCO2_EPR$EPR_STATUS == "IRRELEVANT"],])

stargazer(pol_irr1, pol_irr2, covariate.labels = c("Nonviolent campaign", "Constant"),
          out="Tables/table_A6.tex")

```

### `Replication/Code/replicate_table_A7.R`
```r
##--##--##--##--##--##--##
## Appendix: Table A7
##--##--##--##--##--##--##

us_wave1_sumstats = us_survey_wave1[,c("age", "female", "education", "income", "partyID", "ideology", "interest_politics",
                                      "degree_violence", "police_action_required", "recall_violence2", "race")]
us_wave1_sumstats = dummy_cols(us_wave1_sumstats, select_columns = c("education", "income", "partyID", "ideology", "race"))
stargazer(us_wave1_sumstats, omit.summary.stat=c("p25", "p75"), out="Tables/table_A7.tex")
```

### `Replication/Code/replicate_table_A8.R`
```r
##--##--##--##--##--##--##
## Appendix: Table A8
##--##--##--##--##--##--##

isr_wave1_jewish = isr_survey_wave1[isr_survey_wave1$survey=="isr",]
isr_wave1_jewish_sumstats = isr_wave1_jewish[,c("age", "female", "religiosity", "ethnicity", "education", "income", "partyID", "ideology", "interest_news",
                                                "degree_violence", "police_action_required", "recall_violence2")]
isr_wave1_jewish_sumstats = dummy_cols(isr_wave1_jewish_sumstats, select_columns = c("age", "religiosity", "ethnicity", "education", "income", "partyID"))
table_a8 = stargazer(isr_wave1_jewish_sumstats, omit.summary.stat=c("p25", "p75"))
cat(table_a8, sep = '\n', file = "Tables/table_A8.tex")

```

### `Replication/Code/replicate_table_A9.R`
```r
##--##--##--##--##--##--##
## Appendix: Table A9
##--##--##--##--##--##--##

isr_wave1_arab = isr_survey_wave1[isr_survey_wave1$survey=="isr_ar",]
isr_wave1_arab_sumstats = isr_wave1_arab[,c("age", "female", "religiosity", "ethnicity", "education", "income", "partyID", "ideology", "interest_news",
                                            "degree_violence", "police_action_required", "recall_violence2")]
isr_wave1_arab_sumstats = dummy_cols(isr_wave1_arab_sumstats, select_columns = c("age", "religiosity", "ethnicity", "education", "income", "partyID"))
table_a9 = stargazer(isr_wave1_arab_sumstats, omit.summary.stat=c("p25", "p75"))
cat(table_a9, sep = '\n', file = "Tables/table_A9.tex")


```

## How to run a script

Write each script to a file under the output directory, then run it with
exactly this command (the data directory is mounted read-only at its own
path; nothing else from the host is visible; `$SCRIPT` is the absolute path of
the script you wrote):

    SCRIPT=<repo>/benchmark/reproductions/manekin-2022-effective-for-whom/seeded/2026-11-02-b/script.R   # or <repo>/benchmark/reproductions/manekin-2022-effective-for-whom/seeded/2026-11-02-b/attempt-<n>/script.R
    docker run --rm --label retally.run=claude-code-manekin-2022-effective-for-whom-seeded-2026-11-02-b --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/seeded/2026-11-02-b/mount/manekin_2022_effective_for_whom:<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/seeded/2026-11-02-b/mount/manekin_2022_effective_for_whom:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R > "$(dirname "$SCRIPT")/stdout.txt" 2> "$(dirname "$SCRIPT")/stderr.txt"; echo "exit code: $?"

The sandbox time limit is 300 seconds (memory 4g, 1.0 CPU).  Wrap the
command in a timeout of that many seconds: prefix it with
`perl -e 'alarm shift; exec @ARGV' 300` (or `gtimeout 300` if installed;
macOS has no `timeout`).  If the timeout fires, stop the container with
`docker ps -q --filter label=retally.run=claude-code-manekin-2022-effective-for-whom-seeded-2026-11-02-b | xargs docker kill` and treat the
run as a crash (exit code 124).

## Output contract

The output directory `<repo>/benchmark/reproductions/manekin-2022-effective-for-whom/seeded/2026-11-02-b` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/manekin-2022-effective-for-whom/seeded/2026-11-02-b/
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

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/manekin-2022-effective-for-whom/seeded/2026-11-02-b`.
