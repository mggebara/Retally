# Retally reproduction task: arias-2022-changing-tides-climate-migration (seeded, run 2026-11-02-b)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `arias-2022-changing-tides-climate-migration`, mode `seeded`, run `2026-11-02-b`
- Paper: Changing Tides: Public Attitudes on Climate Migration
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b/mount/arias_2022_changing_tides_climate_migration`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b/mount/arias_2022_changing_tides_climate_migration` as data, and `<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b/paper.txt` as
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

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Claims to Reproduce
1. amce_drought_us: 0.035 (change in probability profile is preferred) [type: coefficient]
   Location: Table 2, U.S. Sample, Reason for Migration: Drought
   Context: Table 2 ("Main Average Marginal Component Effects (Compared to Baseline Levels)"), U.S. sample, row Reason for Migration: Drought. Choice-based conjoint experiment fielded with Dynata on a nationally representative online U.S. sample; respondents saw nine pairs of randomized migrant profiles varying on seven attributes (reason for migration, language fluency, gender, occupation, religion, origin, vulnerability; Table 1) and indicated their preference for admitting one of the two migrants for settlement in their state. Estimand: the average marginal component effect (AMCE), the average change i…
2. amce_flooding_us: 0.037 (change in probability profile is preferred) [type: coefficient]
   Location: Table 2, U.S. Sample, Reason for Migration: Flooding
   Context: Table 2, U.S. sample, row Reason for Migration: Flooding. Same full-model AMCE as amce_drought_us (all seven attributes, all profile pairs, baseline economic opportunity, respondent-clustered robust standard errors).
3. amce_wildfires_us: 0.04 (change in probability profile is preferred) [type: coefficient]
   Location: Table 2, U.S. Sample, Reason for Migration: Wildfires
   Context: Table 2, U.S. sample, row Reason for Migration: Wildfires. Same full-model AMCE as amce_drought_us (baseline economic opportunity, respondent-clustered robust standard errors).
4. amce_persecution_us: 0.076 (change in probability profile is preferred) [type: coefficient]
   Location: Table 2, U.S. Sample, Reason for Migration: Political/religious/ethnic persecution
   Context: Table 2, U.S. sample, row Reason for Migration: Political/religious/ ethnic persecution. Same full-model AMCE as amce_drought_us (baseline economic opportunity, respondent-clustered robust standard errors).
5. amce_drought_germany: 0.081 (change in probability profile is preferred) [type: coefficient]
   Location: Table 2, German Sample, Reason for Migration: Drought
   Context: Table 2, German sample, row Reason for Migration: Drought. The same conjoint design fielded with Dynata on a nationally representative online German sample (factors and levels identical to the U.S. survey except that agnostic was replaced with atheist in Germany); full-model AMCE with all seven attributes on all profile pairs, baseline economic opportunity, robust standard errors clustered by respondent.
6. amce_flooding_germany: 0.086 (change in probability profile is preferred) [type: coefficient]
   Location: Table 2, German Sample, Reason for Migration: Flooding
   Context: Table 2, German sample, row Reason for Migration: Flooding. Same full-model AMCE as amce_drought_germany.
7. amce_wildfires_germany: 0.06 (change in probability profile is preferred) [type: coefficient]
   Location: Table 2, German Sample, Reason for Migration: Wildfires
   Context: Table 2, German sample, row Reason for Migration: Wildfires. Same full-model AMCE as amce_drought_germany.
8. amce_persecution_germany: 0.162 (change in probability profile is preferred) [type: coefficient]
   Location: Table 2, German Sample, Reason for Migration: Political/religious/ethnic persecution
   Context: Table 2, German sample, row Reason for Migration: Political/ religious/ethnic persecution. Same full-model AMCE as amce_drought_germany.
9. respondents_us: 1086.0 (respondents) [type: other]
   Location: Study 1: Empirical Design (text)
   Context: Number of U.S. respondents in the conjoint experiment (the nationally representative online sample fielded with Dynata), as stated in the Study 1 design section.
10. respondents_germany: 1074.0 (respondents) [type: other]
   Location: Study 1: Empirical Design (text)
   Context: Number of German respondents in the conjoint experiment, as stated in the Study 1 design section.
11. choice_tasks_us: 18966.0 (choice tasks (profiles)) [type: other]
   Location: Study 1: Empirical Design (text)
   Context: Number of "unique choice tasks" the design section reports for the U.S. sample: the observations entering the U.S. AMCE estimation (one per migrant profile, two profiles per pairing).
12. choice_tasks_germany: 18862.0 (choice tasks (profiles)) [type: other]
   Location: Study 1: Empirical Design (text)
   Context: Number of "unique choice tasks" the design section reports for the German sample: the observations entering the German AMCE estimation (one per migrant profile, two profiles per pairing).

## Dataset Information
Name: arias_2022_changing_tides_climate_migration
Local path: <repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b/mount/arias_2022_changing_tides_climate_migration
File format: csv
Files in the dataset directory (paths relative to the local path above):
- Climate Migration 1_ Article- Germany_September 7, 2019_09.31.csv (1.5 MB) — columns: StartDate,EndDate,Status,IPAddress,Progress,Duration (in seconds),Finished,RecordedDate,ResponseId,RecipientLastName,RecipientFirstName,RecipientEmail,ExternalReference,LocationLatitude,LocationLongitude,DistributionChannel,UserLanguage,GEN…
- Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv (3.6 MB) — columns: StartDate,EndDate,Status,IPAddress,Progress,Duration (in seconds),Finished,RecordedDate,ResponseId,RecipientLastName,RecipientFirstName,RecipientEmail,ExternalReference,LocationLatitude,LocationLongitude,DistributionChannel,UserLanguage,Q59…
- Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv (3.2 MB) — columns: StartDate,EndDate,Status,IPAddress,Progress,Duration (in seconds),Finished,RecordedDate,ResponseId,RecipientLastName,RecipientFirstName,RecipientEmail,ExternalReference,LocationLatitude,LocationLongitude,DistributionChannel,UserLanguage,Q59…
- Migration Follow-Up_August 1, 2020_12.19.csv (77.7 KB) — columns: StartDate,EndDate,Status,IPAddress,Progress,Duration (in seconds),Finished,RecordedDate,ResponseId,RecipientLastName,RecipientFirstName,RecipientEmail,ExternalReference,LocationLatitude,LocationLongitude,DistributionChannel,UserLanguage,gen…
- Migration_Analysis_Final.R (202.5 KB)
- conjoint_design.dat (827 B)
- conjoint_design_german2.dat (890 B)
- conjoint_design_german2_internal.dat (779 B)
- conjoint_design_internal.dat (723 B)
- germany_state_key.csv (712 B) — columns: ﻿qualtrics_code,state_name,region,east_indicator,east_indicator2,east_indicator3,east_indicator4,east_indicator5,east_indicator6,east_indicator7
- usclimate_exp1.csv (1.7 MB) — columns: Obs,StartDate,EndDate,Status,IPAddress,Progress,Durationinseconds,Finished,RecordedDate,ResponseId,RecipientLastName,RecipientFirstName,RecipientEmail,ExternalReference,LocationLatitude,LocationLongitude,DistributionChannel,UserLanguage,GEN…

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b/mount/arias_2022_changing_tides_climate_migration' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
Installed packages (no network; nothing else can be installed): jsonlite, fixest, lfe, AER, ivreg, plm, estimatr, lme4, quantreg, car, sandwich, lmtest, clubSandwich, multiwayvcov, marginaleffects, MatchIt, optmatch, CBPS, WeightIt, cobalt, did, rdrobust, rddensity, Synth, modelsummary, stargazer, texreg, broom, tidyverse, dplyr, tidyr, readr, stringr, lubridate, data.table, haven, readxl, janitor, zoo, ggplot2, ggridges, ggrepel, gridExtra, cowplot, gtable, extrafont, sf, MASS, nnet, survival, splines, Matrix, boot, stats, utils.
Prefer fixest for fixed effects, IV and clustered SEs; use the other installed packages where the paper's method calls for them.
Set a deterministic seed with ``set.seed(42)`` for any randomness.
Do NOT access the internet; the container runs with --network none.
Do NOT shell out via system() / system2().
Emit RESULT:<name>=<value> lines to stdout at the end via cat().

## Original Replication Scripts
The replication package (the dataset directory) ships the authors' own analysis scripts, reproduced below.  These are the GROUND TRUTH for the exact estimating equation, variable names, sample restrictions, fixed effects, and standard-error clustering — follow them over anything reconstructed from the methodology summary, and prefer them over the paper's text where the two disagree.  Your job is to write R code that implements the SAME SPECIFICATION: translate what the scripts estimate, do not transliterate their syntax line by line (a Stata .do file's regression, e.g. `reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the equivalent fixest::feols() call in R).  Keep only the parts that produce the specific claims being reproduced; skip figure construction and unrelated robustness checks.  The scripts' data-file paths refer to the package's internal layout — resolve them against the dataset directory listed under Dataset Information.

### `Migration_Analysis_Final.R`
```r
######### Setup ######### 
remove(list=ls())
set.seed(8675309)
memory.limit(size=20000) 
options(xtable.comment = FALSE)
wd <- "C:<home>/Dropbox/Research/Climate Migration Paper/Final Files" #Change to your local WD

setwd(wd)

library(tidyverse)
library(xtable)
library(ggplot2)
library(ggpubr)
library(corrplot)
library(car)
library(splines)
library(readxl)
library(stargazer)
library(psych)
library(lemon)
library(boot)
library(cjoint)
library(cregg)
library(margins)
library(FindIt)
library(ggpubr)

# Data files needed (place in local WD): 
# 1. Study 1 (US): conjoint_design.dat
# 2. Study 1 (US): conjoint_design_internal.dat
# 3. Study 1 (US): Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv
# 4. Study 1 (Germany): conjoint_design_german2.dat
# 5. Study 1 (Germany): conjoint_design_german2_internal.dat
# 6. Study 1 (Germany): Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv
# 7. Study 1 and Study 2 (Germany): germany_state_key.csv
# 8. Study 2 (US): usclimate_exp1.csv
# 9. Study 2 (Germany): Climate Migration 1_ Article- Germany_September 7, 2019_09.31.csv
# 9. Study 3 Follow-Up (US): Migration Follow-Up_August 1, 2020_12.19.csv


########################### Study 1: US ########################### 
######### Import data ######### 
cjt_us_design <- makeDesign(type="file", filename= "conjoint_design.dat")

cjt_us_design_internal <- makeDesign(type="file", filename= 'conjoint_design_internal.dat')

cjt_us_data <- read.qualtrics(filename = "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv", 
                              new.format = T, 
                              respondentID = "ResponseId",
                              responses=c("force_choice", "Q184", "Q186", 
                                          "Q188", "Q190", "Q192",
                                          "Q194", "Q196", "Q198"),
                              covariates=c("GENDER_resp", "EDUCATION_resp",	"IDEOLOGY",
                                           'PARTISANSHIP',	'PARTISANSHIP_D',	'PARTISANSHIP_R',	'PARTISANSHIP_I', 'RELIGIOSITY_resp',
                                           'NATIVE_BORN',	'EMPLOYMENT_resp',
                                           'Age',	'TRUST_GOVT',	'POL_INTEREST',
                                           'FP_ORIENTATION_1',	'FP_ORIENTATION_2',	'FP_ORIENTATION_3',	'FP_ORIENTATION_4',
                                           'SOC_DOM_1',	'SOC_DOM_2',	'SOC_DOM_3',	'SOC_DOM_4',
                                           'EMPATHY_1',	'EMPATHY_2',	'EMPATHY_3',	'EMPATHY_4',
                                           'city', 'state_region'))

cjt_us_data_relig <- read.qualtrics(filename = "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv", 
                                    new.format = T, 
                                    respondentID = "ResponseId",
                                    responses=c("force_choice", "Q184", "Q186", 
                                                "Q188", "Q190", "Q192",
                                                "Q194", "Q196", "Q198"),
                                    covariates=c('RELIGIOSITY_resp'))

cjt_us_data_rank <- read.qualtrics(filename = "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv", 
                                   new.format = T, 
                                   respondentID = "ResponseId",
                                   responses=c("force_choice", "Q184", "Q186", 
                                               "Q188", "Q190", "Q192",
                                               "Q194", "Q196", "Q198"),
                                   covariates=c("GENDER_resp", "EDUCATION_resp",	"IDEOLOGY",
                                                'PARTISANSHIP',	'PARTISANSHIP_D',	'PARTISANSHIP_R',	'PARTISANSHIP_I',
                                                'NATIVE_BORN',	'EMPLOYMENT_resp',
                                                'Age',	'TRUST_GOVT',	'POL_INTEREST',
                                                'FP_ORIENTATION_1',	'FP_ORIENTATION_2',	'FP_ORIENTATION_3',	'FP_ORIENTATION_4',
                                                'SOC_DOM_1',	'SOC_DOM_2',	'SOC_DOM_3',	'SOC_DOM_4',
                                                'EMPATHY_1',	'EMPATHY_2',	'EMPATHY_3',	'EMPATHY_4',
                                                'city', 'state_region'),
                                   ranks = c("RATE_MIG1","RATE_MIG2",
                                             "Q168", "Q169",
                                             "Q170", "Q171",
                                             "Q172", "Q173",
                                             "Q174", "Q175",
                                             "Q176", "Q177",
                                             "Q178", "Q179",
                                             "Q180", "Q181",
                                             "Q182", "Q183"))

cjt_us_data_rank <- cjt_us_data_rank %>% 
  dplyr::rename(rank_outcome = selected) %>% 
  dplyr::select(rank_outcome)

cjt_us_data_relig <- cjt_us_data_relig %>% 
  dplyr::select(RELIGIOSITY_resp)

cjt_us_data <- cbind(cjt_us_data, cjt_us_data_rank, cjt_us_data_relig)

cjt_us_data <- cjt_us_data[!is.na(cjt_us_data$selected), ]

######### Recoding ######### 
cjt_us_data <- cjt_us_data[cjt_us_data$Occupation != 'Unemployer', ]
cjt_us_data$Occupation <- factor(cjt_us_data$Occupation)

cjt_us_data$PARTISANSHIP6 <- NA

for(i in 1:nrow(cjt_us_data)){
  if(cjt_us_data[i, "PARTISANSHIP_D"]==1){
    cjt_us_data[i, "PARTISANSHIP6"]<- 6}
  if(cjt_us_data[i, "PARTISANSHIP_D"]==2){
    cjt_us_data[i, "PARTISANSHIP6"]<- 5}
  if(cjt_us_data[i, "PARTISANSHIP_I"]==1){
    cjt_us_data[i, "PARTISANSHIP6"]<- 4}
  if(cjt_us_data[i, "PARTISANSHIP_I"]==2){
    cjt_us_data[i, "PARTISANSHIP6"]<- 3}
  if(cjt_us_data[i, "PARTISANSHIP_R"]==2){
    cjt_us_data[i, "PARTISANSHIP6"]<- 2}
  if(cjt_us_data[i, "PARTISANSHIP_R"]==1){
    cjt_us_data[i, "PARTISANSHIP6"]<- 1}
}  

cjt_us_data$FP_ORIENTATION_1 <- car::recode(cjt_us_data$FP_ORIENTATION_1,
                                            "'Definitely agree'=5; 'Somewhat agree'=4; 'Neither agree nor disagree'=3; 'Somewhat disagree'=2; 'Definitely disagree'=1")
cjt_us_data$FP_ORIENTATION_2 <- car::recode(cjt_us_data$FP_ORIENTATION_2,
                                            "'Definitely agree'=5; 'Somewhat agree'=4; 'Neither agree nor disagree'=3; 'Somewhat disagree'=2; 'Definitely disagree'=1")
#reverse coded 
cjt_us_data$FP_ORIENTATION_3 <- car::recode(cjt_us_data$FP_ORIENTATION_3,
                                            "'Definitely agree'=1; 'Somewhat agree'=2; 'Neither agree nor disagree'=3; 'Somewhat disagree'=4; 'Definitely disagree'=5")
#reverse coded
cjt_us_data$FP_ORIENTATION_4 <-  car::recode(cjt_us_data$FP_ORIENTATION_4,
                                             "'Definitely agree'=1; 'Somewhat agree'=2; 'Neither agree nor disagree'=3; 'Somewhat disagree'=4; 'Definitely disagree'=5")

cjt_us_data$SOC_DOM_1 <- car::recode(cjt_us_data$SOC_DOM_1,
                                     "'Definitely favor'=1; 'Somewhat favor'=2; 'Neither oppose nor favor'=3; 'Somewhat oppose'=4; 'Definitely oppose'=5")
#reverse coded
cjt_us_data$SOC_DOM_2 <- car::recode(cjt_us_data$SOC_DOM_2,
                                     "'Definitely favor'=5; 'Somewhat favor'=4; 'Neither oppose nor favor'=3; 'Somewhat oppose'=2; 'Definitely oppose'=1")

cjt_us_data$SOC_DOM_3 <- car::recode(cjt_us_data$SOC_DOM_3,
                                     "'Definitely favor'=1; 'Somewhat favor'=2; 'Neither oppose nor favor'=3; 'Somewhat oppose'=4; 'Definitely oppose'=5")
#reverse coded
cjt_us_data$SOC_DOM_4 <- car::recode(cjt_us_data$SOC_DOM_4,
                                     "'Definitely favor'=5; 'Somewhat favor'=4; 'Neither oppose nor favor'=3; 'Somewhat oppose'=2; 'Definitely oppose'=1")

cjt_us_data$EMPATHY_1 <- car::recode(cjt_us_data$EMPATHY_1,
                                     "'Describes me very well'=5; 'Describes me fairly well'=4; 'Describes me moderately well'=3; 'Describes me very little'=2; 'Does not describe me at all'=1")
#reverse coded
cjt_us_data$EMPATHY_2 <- car::recode(cjt_us_data$EMPATHY_2,
                                     "'Describes me very well'=1; 'Describes me fairly well'=2; 'Describes me moderately well'=3; 'Describes me very little'=4; 'Does not describe me at all'=5")
#reverse coded
cjt_us_data$EMPATHY_3 <- car::recode(cjt_us_data$EMPATHY_3,
                                     "'Describes me very well'=1; 'Describes me fairly well'=2; 'Describes me moderately well'=3; 'Describes me very little'=4; 'Does not describe me at all'=5")
cjt_us_data$EMPATHY_4 <- car::recode(cjt_us_data$EMPATHY_4,
                                     "'Describes me very well'=5; 'Describes me fairly well'=4; 'Describes me moderately well'=3; 'Describes me very little'=2; 'Does not describe me at all'=1")

cjt_us_data <- cjt_us_data %>% 
  mutate(PARTISANSHIP_bin = ifelse(PARTISANSHIP6>3, "D", "R"),
         AGE = as.numeric(Age)) 

cjt_us_data$border_state_indicator <- 1*(cjt_us_data$state_region %in% c("TX", "CA", "AZ", "NM"))

cjt_us_data$border_state_indicator_noCA <- 1*(cjt_us_data$state_region %in% c("TX", "AZ", "NM"))

cjt_us_data$urban_indicator <- 1*(cjt_us_data$city %in% c("New York", "Los Angeles", "Chicago", 
                                                          "Houston", "Phoenix", "Philadelphia",
                                                          "San Antonio", "San Diego", "Dallas", "San Jose")) 

cjt_us_data <- cjt_us_data[5:nrow(cjt_us_data), ]

cjt_us_data$EDUCATION_num <- as.numeric(cjt_us_data$EDUCATION_resp)-1
cjt_us_data$IDEOLOGY_num <- as.numeric(car::recode(cjt_us_data$IDEOLOGY,
                                                   "'Extremely liberal'=7; 'Liberal'=6; 'Slightly liberal'=5; 
'Moderate, middle of the road'=4; 
      'Slightly conservative'=3; 'Conservative'=2; 'Extremely conservative'=1"))-1
cjt_us_data$RELIGIOSITY_num <- as.numeric(cjt_us_data$RELIGIOSITY_resp)-1
cjt_us_data$NATIVE_BORN_num <- ifelse(cjt_us_data$NATIVE_BORN == "United States", 1, 0)
cjt_us_data$EMPLOYMENT_num <- as.numeric(car::recode(cjt_us_data$EMPLOYMENT,
                                                     "'17'=7; '16'=6; '21'=5; '18'=4; 
      '20'=3; '19'=2; '17 '=1"))
cjt_us_data$TRUST_GOVT_num <- as.numeric(car::recode(cjt_us_data$TRUST_GOVT,
                                                     "'Most of the time'=3; 'Only some of the time'=2; 'Just about always'=1"))-1
cjt_us_data$POL_INTEREST_num <- as.numeric(car::recode(cjt_us_data$POL_INTEREST,
                                                       "'Most of the time'=4; 
      'Some of the time'=3; 'Only now and then'=2; 'Hardly at all'=1"))-1

######### Construct scales ######### 
fp_orientation <- data.frame(cjt_us_data[,c("FP_ORIENTATION_1", "FP_ORIENTATION_2", "FP_ORIENTATION_3", "FP_ORIENTATION_4")])
soc_dom <- data.frame(cjt_us_data[,c("SOC_DOM_1", "SOC_DOM_2", "SOC_DOM_3", "SOC_DOM_4")])
empathy <- data.frame(cjt_us_data[,c("EMPATHY_1", "EMPATHY_2", "EMPATHY_3", "EMPATHY_4")])


fp_orientation <- data.frame(sapply(fp_orientation, FUN= function(x) as.numeric(x))-1)
soc_dom <- data.frame(sapply(soc_dom, FUN= function(x) as.numeric(x))-1)
empathy <- data.frame(sapply(empathy, FUN= function(x) as.numeric(x))-1)

#calculate chronbach's alpha for each index
# psych::alpha(fp_orientation) 
# psych::alpha(soc_dom) 
# psych::alpha(empathy) 

#r=create the index variable as the mean score on the individual items
cjt_us_data$fp_orientation_index <- apply(fp_orientation, MARGIN = 1, FUN = mean)
cjt_us_data$soc_dom_index <- apply(soc_dom, MARGIN = 1, FUN = mean)
cjt_us_data$empathy_index <- apply(empathy, MARGIN = 1, FUN = mean)

######### Balance, summary stats ######### 
cjt_us_data$PARTISANSHIP_bin <- as.factor(cjt_us_data$PARTISANSHIP_bin)
cjt_us_data$PARTISANSHIP_num <- as.numeric(cjt_us_data$PARTISANSHIP_bin)
cjt_us_data$GENDER_num <- ifelse(cjt_us_data$GENDER == "Female", 1, 0)

vars <- c('AGE', 'fp_orientation_index', 'soc_dom_index', "empathy_index", 
          'PARTISANSHIP_num', "GENDER_num", "EDUCATION_num",
          "IDEOLOGY_num",  "NATIVE_BORN_num",
          "EMPLOYMENT_num", "TRUST_GOVT_num", "POL_INTEREST_num"
          ,"RELIGIOSITY_num"
)

var_labels <- c("Age", "Foreign Policy Orientation", "Social Dominance", "Empathy",
                "Partisanship", "Gender", "Education", "Ideology", "Native Born",
                "Employment", "Trust in Government", "Political Interest"
                ,"Religiosity"
)

sum_stats <- data.frame(matrix(NA,length(vars), 7))
colnames(sum_stats) <- c("Var.", "Min.", "1st Qu.",  "Median",
                         "Mean", "3rd Qu.",    "Max." )
sum_stats[, 1] <- var_labels

for (i in 1:length(vars)){
  string <- paste('sum <- summary(cjt_us_data$',vars[i], ')',
                  sep = "", collapse = "")
  eval(parse(text=string))
  sum_stats[i, 2:7] <- sum
  
}

xtable(sum_stats, caption = "Experiment 1 Summary Statistics, US Sample", digits = c(0, 0, 0, 2, 2, 2, 2, 0))

######### Conjoint main analysis ######### 
baselines <- list()
baselines$Vulnerability <- 'None'
baselines$Reason.for.migration <- 'Economic opportunity'
baselines$Occupation <- 'Unemployed'
baselines$Language.Fluency <- 'None'
baselines$Origin <- 'Another region in your country'

cjt_us_results <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation + Origin +
                                 Reason.for.migration + Religion + Vulnerability, 
                               data = cjt_us_data,
                               cluster= T,
                               respondent.id = 'Response.ID',
                               design= cjt_us_design, 
                               baselines=baselines)

summary(cjt_us_results)$amce
xtable(summary(cjt_us_results)$amce[, c(1:4, 7)], digits=3, 
       font.size = "small", caption = "AMCE, US Sample (Compared to baseline levels")

levels.test<-list()
levels.test[["Gender"]]<-c("Female","Male")
levels.test[["Language Fluency"]]<-c('None', "Broken", "Fluent")
levels.test[["Occupation"]]<-c("Unemployed","Cleaner", "Doctor", "Teacher")
levels.test[["Origin"]]<-c("Same Country", "Afghanistan", "Ethiopia", "Myanmar", "Ukraine")
levels.test[["Reason.for.migration"]]<-c("Economic","Drought", "Flooding", "Persecution", "Wildfires")
levels.test[["Religion"]]<-c("Agnostic","Christian", "Muslim")
levels.test[["Vulnerability"]]<-c("None","Food insc.", "No family", "Physical handicap", "PTSD")

plot.amce(cjt_us_results, xlab="Expected Change in Migrant Profile Selection, US",
          main="", 
          level.names = levels.test,
          attribute.names = c("Gender","Language Fluency","Occupation",
                              "Origin", "Reason", "Religion", "Vulnerability"),
          # xlim=c(-0.07, .2),
          text.size=9)

######### Robustness ######### 
#Only respondents who complete all 9 tasks
cjt_us_data_only9tasks <- cjt_us_data %>% 
  group_by(Response.ID) %>% 
  mutate(resp_profiles_count = n()) 

cjt_us_data_only9tasks <- cjt_us_data_only9tasks[cjt_us_data_only9tasks$resp_profiles_count > 17, ]

nrow(cjt_us_data) - nrow(cjt_us_data_only9tasks) 
length(unique(cjt_us_data$Response.ID)) -
  length(unique(cjt_us_data_only9tasks$Response.ID))

cjt_us_results_only_9tasks <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation + Origin +
                                             Reason.for.migration + Religion + Vulnerability, 
                                           data = cjt_us_data_only9tasks,
                                           cluster= T,
                                           respondent.id = 'Response.ID',
                                           design= cjt_us_design, 
                                           baselines=baselines)

summary(cjt_us_results_only_9tasks)$amce
xtable(summary(cjt_us_results_only_9tasks)$amce[, c(1:4, 7)], digits=3, 
       font.size = "small", caption = "AMCE, US Sample (Compared to baseline levels- \n Only respondents who complete all 9 tasks")

summary(cjt_us_results_only_9tasks)$amce$Estimate - summary(cjt_us_results)$amce$Estimate

#Compare internal and external migrant profiles
cjt_us_data_internal <- cjt_us_data[! (cjt_us_data$Origin %in% "Another region in your country" & 
                                         cjt_us_data$Reason.for.migration %in% 
                                         "Political/religious/ethnic persecution"), ]

cjt_us_data_internal_strict <- cjt_us_data[! (cjt_us_data$Origin %in% "Another region in your country") , ]

cjt_us_data_internal_actual <- cjt_us_data[(cjt_us_data$Origin %in% "Another region in your country"), ]

nrow(cjt_us_data) - nrow(cjt_us_data_internal)

length(unique(cjt_us_data$Response.ID)) -
  length(unique(cjt_us_data_internal$Response.ID))

cjt_us_results_internal <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation + Origin +
                                          Reason.for.migration + Religion + Vulnerability, 
                                        data = cjt_us_data_internal,
                                        cluster= T,
                                        respondent.id = 'Response.ID',
                                        design= cjt_us_design, 
                                        baselines=baselines)

round(summary(cjt_us_results_internal)$amce$Estimate  - summary(cjt_us_results)$amce$Estimate, 3)

us_int_table1 <- as_tibble(summary(cjt_us_results_internal)$amce[, c(1:4, 7)]) %>% 
  cbind(round(summary(cjt_us_results_internal)$amce$Estimate  - summary(cjt_us_results)$amce$Estimate, 3))

names(us_int_table1)[6] <- "Est. Diff. from Full Model"

xtable(us_int_table1, digits = 3,
       font.size = "small", caption = "AMCE, US Sample (Compared to baseline levels- \n Excluding 'implausible' internal migration profiles")

baselines$Origin <- 'Ukraine'
cjt_us_results_internal_strict <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation + Origin +
                                                 Reason.for.migration + Religion + Vulnerability, 
                                               data = cjt_us_data_internal_strict,
                                               cluster= T,
                                               respondent.id = 'Response.ID',
                                               design= cjt_us_design, 
                                               baselines=baselines)

cjt_us_results2 <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation + Origin +
                                  Reason.for.migration + Religion + Vulnerability, 
                                data = cjt_us_data,
                                cluster= T,
                                respondent.id = 'Response.ID',
                                design= cjt_us_design, 
                                baselines=baselines)

us_int_table2 <- as_tibble(summary(cjt_us_results_internal_strict)$amce[, c(1:4, 7)]) %>% 
  cbind(round(summary(cjt_us_results_internal_strict)$amce$Estimate  -
                summary(cjt_us_results2)$amce$Estimate[c(1:7, 9:20)], 3))

xtable(us_int_table2, digits = 3,
       font.size = "small", caption = "AMCE, US Sample (Compared to baseline levels- \n Excluding all internal migration profiles")

summary(cjt_us_results_internal_strict)$amce$Estimate  - summary(cjt_us_results2)$amce$Estimate[c(1:7, 9:20)]

place <- round(summary(cjt_us_results_internal_strict)$amce$Estimate  - summary(cjt_us_results2)$amce$Estimate[c(1:7, 9:20)], 4)

cjt_us_internal_comparisons <- cbind(summary(cjt_us_results_internal)$amce$Attribute, 
                                     summary(cjt_us_results_internal)$amce$Level, 
                                     round(summary(cjt_us_results_internal)$amce$Estimate  - summary(cjt_us_results)$amce$Estimate, 4),
                                     c(place[1:9], NA, place[10:19]))

colnames(cjt_us_internal_comparisons) <- c("Attribute", "Level", "Full Model - Implausible Internal Profiles Removed", "Full Model - All Internal Profiles Removed")

xtable(cjt_us_internal_comparisons, 
       font.size = "small", caption = "AMCE Differences, US Sample (Compared to baseline levels- \n Full Set Compared to Restricted Internal Sets \n Baseline Origin for Second Comparison Changed to Ukraine")

baselines <- list()
baselines$Vulnerability <- 'None'
baselines$Reason.for.migration <- 'Economic opportunity'
baselines$Occupation <- 'Unemployed'
baselines$Language.Fluency <- 'Broken'

cjt_us_results_internal_actual <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation  +
                                                 Reason.for.migration + Religion + Vulnerability, 
                                               data = cjt_us_data_internal_actual,
                                               cluster= T,
                                               respondent.id = 'Response.ID',
                                               design= cjt_us_design_internal, 
                                               baselines=baselines)

cjt_us_results3 <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation + Origin +
                                  Reason.for.migration + Religion + Vulnerability, 
                                data = cjt_us_data,
                                cluster= T,
                                respondent.id = 'Response.ID',
                                design= cjt_us_design, 
                                baselines=baselines)

us_ext_table <- as_tibble(summary(cjt_us_results_internal_actual)$amce[, c(1:4, 7)]) %>% 
  cbind(round(summary(cjt_us_results_internal_actual)$amce$Estimate  - summary(cjt_us_results3)$amce$Estimate[c(1:6, 11:20)], 3))

xtable(us_ext_table, digits = 3,
       font.size = "small", caption = "AMCE, US Sample (Compared to baseline levels- \n Excluding all external migration profiles")

#Only respondents 18 and over
cjt_us_data_age_subset <- subset(x = cjt_us_data, subset = AGE > 17)

nrow(cjt_us_data) - nrow(cjt_us_data_age_subset) 
length(unique(cjt_us_data$Response.ID)) -
  length(unique(cjt_us_data_age_subset$Response.ID))

baselines <- list()
baselines$Vulnerability <- 'None'
baselines$Reason.for.migration <- 'Economic opportunity'
baselines$Occupation <- 'Unemployed'
baselines$Language.Fluency <- 'None'
baselines$Origin <- 'Another region in your country'

cjt_us_results_age_subset <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation + Origin +
                                            Reason.for.migration + Religion + Vulnerability, 
                                          data = cjt_us_data_age_subset,
                                          cluster= T,
                                          respondent.id = 'Response.ID',
                                          design= cjt_us_design, 
                                          baselines=baselines)

summary(cjt_us_results_age_subset)$amce
xtable(summary(cjt_us_results_age_subset)$amce[, c(1:4, 7)], digits=3, 
       font.size = "small", caption = "AMCE, US Sample Age Over 18 (Compared to baseline levels)")

summary(cjt_us_results_age_subset)$amce$Estimate - summary(cjt_us_results)$amce$Estimate

#Look at rank DV
cjt_us_rank <- cjoint::amce(rank_outcome ~ Gender + Language.Fluency + Occupation + Origin +
                              Reason.for.migration + Religion + Vulnerability , 
                            data = cjt_us_data,
                            cluster= T,
                            respondent.id = 'Response.ID',
                            design= cjt_us_design, 
                            baselines=baselines)

summary(cjt_us_rank)$amce
xtable(summary(cjt_us_rank)$amce[, c(1:4, 7)], digits=3, 
       font.size = "small", caption = "AMCE, US Sample (Compared to baseline levels")

plot.amce(cjt_us_rank, xlab="Expected Change in Migrant Profile Selection, US (Rating Results)",
          main="", 
          level.names = levels.test,
          attribute.names = c("Gender","Language Fluency","Occupation",
                              "Origin", "Reason", "Religion", "Vulnerability"),
          # xlim=c(-0.07, .2),
          text.size=9)

#Interactions
cjt_us_interaction <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation + Origin +
                                     Reason.for.migration + Religion + Vulnerability + 
                                     Reason.for.migration*Origin, 
                                   data = cjt_us_data,
                                   cluster= T,
                                   respondent.id = 'Response.ID',
                                   design= cjt_us_design, 
                                   baselines=baselines)
plot.amce(cjt_us_interaction, xlab="Expected Change in Migrant Profile Selection, US",
          main="", 
          level.names = levels.test,
          attribute.names = c("Gender","Language Fluency","Occupation",
                              "Origin", "Reason", "Religion", "Vulnerability", "Origin*Reason"),
          # xlim=c(-0.07, .2),
          text.size=9)

cjt_us_interaction2 <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation + Origin +
                                      Reason.for.migration + Religion + Vulnerability + 
                                      Reason.for.migration*Vulnerability, 
                                    data = cjt_us_data,
                                    cluster= T,
                                    respondent.id = 'Response.ID',
                                    design= cjt_us_design, 
                                    baselines=baselines)
plot.amce(cjt_us_interaction2, xlab="Expected Change in Migrant Profile Selection, US",
          main="", 
          level.names = levels.test,
          attribute.names = c("Gender","Language Fluency","Occupation",
                              "Origin", "Reason", "Religion", "Vulnerability", "Reason*Vulnerability"),
          # xlim=c(-0.07, .2),
          text.size=9)


######### Marginal Means and Subgroups ######### 
cjt_us_data$Language.Fluency2 <- car::recode(cjt_us_data$Language.Fluency,
                                             "'None'='None_lf'")
cjt_us_data$Origin <- car::recode(cjt_us_data$Origin,
                                  "'Another region in your country'='Same Country'")
cjt_us_data$Reason.for.migration <- car::recode(cjt_us_data$Reason.for.migration,
                                                "'Economic opportunity'='Economic'; 'Political/religious/ethnic persecution'='Persecution'")
cjt_us_data$Religion <- car::recode(cjt_us_data$Religion,
                                    "'Agnostic'='Athiest'")
cjt_us_data$Vulnerability <- car::recode(cjt_us_data$Vulnerability,
                                         "'Food insecurity'='Food insc.'; 'Physically handicapped'='Physical handicap'; 'No surviving family members'='No family';'Post Traumatic Stress Disorder (PTSD)'='PTSD'")

us_mms <- selected ~ Language.Fluency2 + Occupation + 
  Gender + Origin +
  Religion + Vulnerability + Reason.for.migration

us_mms_interaction <- selected ~ Language.Fluency2 + Occupation + 
  Gender + Origin +
  Religion + Vulnerability + Reason.for.migration +
  Reason.for.migration*Origin

plot(mm(cjt_us_data, us_mms, id = ~Response.ID), vline = 0.5, xlab = "Conjoint Marginal Means, US", 
     legend_pos = "none")

plot(mm(cjt_us_data, us_mms_interaction, id = ~Response.ID), vline = 0.5, xlab = "Conjoint Marginal Means, US", 
     legend_pos = "none")


cjt_us_data$PARTISANSHIP_bin <- relevel(cjt_us_data$PARTISANSHIP_bin, "R")
cjt_us_data <- cjt_us_data %>% 
  mutate(empathy_bin_mean = as.factor(ifelse(empathy_index>2.20, "emp_high", "emp_low")),
         empathy_bin_quart = as.factor(ifelse(empathy_index>2.50, "emp_high", 
                                              ifelse(empathy_index<1.75,"emp_low", NA))),
         age_bin_mean = as.factor(ifelse(AGE>44.12, "age_high", "age_low")),
         age_bin_quart = as.factor(ifelse(AGE>60.00 , "age_high", 
                                          ifelse(empathy_index<28.00,"age_low", NA))),
         origin_binary = as.factor(ifelse(Origin=="Same Country", "Same Country", "Other Country")),
         education_college_bin = as.factor(ifelse(EDUCATION_num> 4, "college_degree", "no_college_degree")),
         employed_bin = as.factor(ifelse(EMPLOYMENT_num %in% c(1, 6, 5), "employed", "not_employed")),
         unemployed_bin = as.factor(ifelse(EMPLOYMENT_num==7, "unemployed", "not_unemployed")) 
  )

us_mms_origin_bin <- selected ~ Language.Fluency2 + Occupation + 
  Gender + origin_binary +
  Religion + Vulnerability + Reason.for.migration

us_mms_origin_bin_interaction <- selected ~ Language.Fluency2 + Occupation + 
  Gender + origin_binary +
  Religion + Vulnerability + Reason.for.migration +
  Reason.for.migration*origin_binary

#collapse origin
plot(mm(cjt_us_data, us_mms_origin_bin, id = ~Response.ID), vline = 0.5, xlab = "Conjoint Marginal Means, US", 
     legend_pos = "none", alpha=.9)

#origin * reason
mm_diffs_origin_bin <- mm_diffs(data = cjt_us_data, 
                                formula = selected ~ Language.Fluency2 + Occupation + 
                                  Gender + 
                                  Religion + Vulnerability + Reason.for.migration,
                                by = ~origin_binary, 
                                id = ~Response.ID)

#difference of same country - other country
mm_diffs_origin_bin <- mm_diffs_origin_bin[, c(4:7, 9)]

mm_diffs_origin_bin[18:22, ]

colnames(mm_diffs_origin_bin) <- c("Feature", "Level", "Est.", "SE", "P")
xtable(mm_diffs_origin_bin, digits=3, 
       font.size = "small", caption = "Marginal Mean Differences by Origin, US Sample (same country - other country)")

mm_by_part_bin <- cj(cjt_us_data, 
                     selected ~ Language.Fluency2 + Occupation + 
                       Gender + Origin +
                       Religion + Vulnerability + Reason.for.migration,
                     id = ~Response.ID, estimate = "mm", by = ~PARTISANSHIP_bin)

# test of whether any of the interactions between the by variable and feature levels differ from zero
cj_anova(cjt_us_data, 
         selected ~ Language.Fluency2 + Occupation + 
           Gender + Origin +
           Religion + Vulnerability + Reason.for.migration,
         by = ~PARTISANSHIP_bin)

mm_by_empathy_bin_mean <- cj(cjt_us_data, 
                             selected ~ Language.Fluency2 + Occupation + 
                               Gender + Origin +
                               Religion + Vulnerability + Reason.for.migration,
                             id = ~Response.ID, estimate = "mm", by = ~empathy_bin_mean)

cj_anova(cjt_us_data, 
         selected ~ Language.Fluency2 + Occupation + 
           Gender + Origin +
           Religion + Vulnerability + Reason.for.migration,
         by = ~empathy_bin_mean)

mm_by_empathy_bin_quart <- cj(cjt_us_data, 
                              selected ~ Language.Fluency2 + Occupation + 
                                Gender + Origin +
                                Religion + Vulnerability + Reason.for.migration,
                              id = ~Response.ID, estimate = "mm", by = ~empathy_bin_quart)

cj_anova(na.omit(cjt_us_data), 
         selected ~ Language.Fluency2 + Occupation + 
           Gender + Origin +
           Religion + Vulnerability + Reason.for.migration,
         by = ~empathy_bin_quart)

mm_by_age_bin_mean <- cj(cjt_us_data, 
                         selected ~ Language.Fluency2 + Occupation + 
                           Gender + Origin +
                           Religion + Vulnerability + Reason.for.migration,
                         id = ~Response.ID, estimate = "mm", by = ~age_bin_mean)

cj_anova(na.omit(cjt_us_data), 
         selected ~ Language.Fluency2 + Occupation + 
           Gender + Origin +
           Religion + Vulnerability + Reason.for.migration,
         by = ~age_bin_mean)

mm_by_age_bin_qurat <- cj(cjt_us_data, 
                          selected ~ Language.Fluency2 + Occupation + 
                            Gender + Origin +
                            Religion + Vulnerability + Reason.for.migration,
                          id = ~Response.ID, estimate = "mm", by = ~age_bin_quart)

cj_anova(na.omit(cjt_us_data), 
         selected ~ Language.Fluency2 + Occupation + 
           Gender + Origin +
           Religion + Vulnerability + Reason.for.migration,
         by = ~age_bin_quart)

mm_by_gender <- cj(cjt_us_data, 
                   selected ~ Language.Fluency2 + Occupation + 
                     Gender + Origin +
                     Religion + Vulnerability + Reason.for.migration,
                   id = ~Response.ID, estimate = "mm", by = ~Gender)

cj_anova(na.omit(cjt_us_data), 
         selected ~ Language.Fluency2 + Occupation + 
           Gender + Origin +
           Religion + Vulnerability + Reason.for.migration,
         by = ~Gender)

mm_by_border_state <- cj(cjt_us_data, 
                         selected ~ Language.Fluency2 + Occupation + 
                           Gender + Origin +
                           Religion + Vulnerability + Reason.for.migration,
                         id = ~Response.ID, estimate = "mm", by = ~border_state_indicator)

cj_anova(na.omit(cjt_us_data), 
         selected ~ Language.Fluency2 + Occupation + 
           Gender + Origin +
           Religion + Vulnerability + Reason.for.migration,
         by = ~border_state_indicator)

mm_by_college_degree <- cj(cjt_us_data, 
                           selected ~ Language.Fluency2 + Occupation + 
                             Gender + Origin +
                             Religion + Vulnerability + Reason.for.migration,
                           id = ~Response.ID, estimate = "mm", by = ~education_college_bin)

cj_anova(na.omit(cjt_us_data), 
         selected ~ Language.Fluency2 + Occupation + 
           Gender + Origin +
           Religion + Vulnerability + Reason.for.migration,
         by = ~education_college_bin)

cj_anova(na.omit(cjt_us_data), 
         selected ~ Language.Fluency2 + Occupation + 
           Gender + Origin +
           Religion + Vulnerability + Reason.for.migration,
         by = ~employed_bin)

cj_anova(na.omit(cjt_us_data), 
         selected ~ Language.Fluency2 + Occupation + 
           Gender + Origin +
           Religion + Vulnerability + Reason.for.migration,
         by = ~unemployed_bin)

mm_by_employed <- cj(cjt_us_data, 
                     selected ~ Language.Fluency2 + Occupation + 
                       Gender + Origin +
                       Religion + Vulnerability + Reason.for.migration,
                     id = ~Response.ID, estimate = "mm", by = ~employed_bin)

mm_by_unemployed <- cj(cjt_us_data, 
                       selected ~ Language.Fluency2 + Occupation + 
                         Gender + Origin +
                         Religion + Vulnerability + Reason.for.migration,
                       id = ~Response.ID, estimate = "mm", by = ~unemployed_bin)

plot(mm_by_part_bin, group = "BY", vline = 0.5, xlab = "Marginal Mean Diff. (US)", 
     legend_title = "PID") + 
  scale_color_manual(name="PID", labels= c("Dem", "Rep"), values = c("blue", "red"))

plot(mm_by_age_bin_mean, group = "BY", vline = 0.5, xlab = "Marginal Mean Diff. (US)", 
     legend_title = "Age")  + 
  scale_color_manual(values=c("blue", "red"), name="Age", labels= c("4th quart.", "1st quart."))

plot(mm_by_border_state, group = "BY", vline = 0.5, xlab = "Marginal Mean Diff. (US)", 
     legend_title = "State") +  
  ggplot2::scale_color_manual(values=c("blue", "red"),name="State", labels= c("Non-Border", "Border"))

plot(mm_by_empathy_bin_quart, group = "BY", vline = 0.5, xlab = "Marginal Mean Diff. (US)", 
     legend_title = "Empathy") +  
  ggplot2::scale_color_manual(values=c("blue", "red"),name="State", labels= c("4th quart.", "1st quart."))

plot(mm_by_college_degree, group = "BY", vline = 0.5, xlab = "Marginal Mean Diff. (US)", 
     legend_title = "College Degree") +
  scale_color_manual(name="Education", labels= c("College Degree", "No College Degree"), values = c("blue", "red"))

plot(mm_by_employed, group = "BY", vline = 0.5, xlab = "Marginal Mean Diff. (US)", 
     legend_title = "Employment") +
  scale_color_manual(name="Employment", labels= c("Employed", "Not Employed"), values = c("blue", "red"))

plot(mm_by_unemployed, group = "BY", vline = 0.5, xlab = "Marginal Mean Diff. (US)", 
     legend_title = "Employment") +
  scale_color_manual(name="Employment", labels= c("Not Unemployed", "Unemployed"), values = c("blue", "red"))

diff_mms_by_part_bin <- cj(cjt_us_data, 
                           selected ~ Language.Fluency2 + Occupation + 
                             Gender + Origin +
                             Religion + Vulnerability + Reason.for.migration,
                           id = ~Response.ID, estimate = "mm_diff",
                           by = ~PARTISANSHIP_bin)

plot(rbind(mm_by_part_bin, diff_mms_by_part_bin), legend_pos = "none") + ggplot2::facet_wrap(~BY, ncol = 3L)
plot(diff_mms_by_part_bin, legend_pos = "none",
     xlab= "Marginal Mean Diff., D-R") #difference in marginal means R and D


######### Diagnostics #########
plot(cj_freqs(cjt_us_data, us_mms, id = ~Response.ID), legend_pos = "none", ylab = "Frequency of Level in Conjoint Design (US)") 

plot(cj(cjt_us_data, us_mms, id = ~Response.ID, by = ~profile, estimate = "mm"), group = "profile", vline = 0.5, legend_pos = "none", xlab= "Marginal Mean, Left vs Right Profile (US)")

########################### Study 1: Germany  ########################## 
######### Import data ######### 
cjt_ger_design2 <- makeDesign(type="file", filename= 'conjoint_design_german2.dat')

cjt_ger_design2_internal <- makeDesign(type="file", filename= 'conjoint_design_german2_internal.dat')


cjt_ger_data <- read.qualtrics(filename = "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv", 
                               new.format = T, 
                               respondentID = "ResponseId",
                               responses=c("force_choice", "Q184", "Q186", 
                                           "Q188", "Q190", "Q192",
                                           "Q194", "Q196", "Q198"),
                               covariates=c("GENDER_resp", "EDUCATION_resp",	"IDEOLOGY",
                                            'RELIGIOSITY_resp',	'NATIVE_BORN',	'EMPLOYMENT_resp',
                                            'Age',	'TRUST_GOVT',	'POL_INTEREST',	
                                            'FP_ORIENTATION_1',	'FP_ORIENTATION_2',	'FP_ORIENTATION_3',	'FP_ORIENTATION_4',
                                            'EMPATHY_1',	'EMPATHY_2',	'EMPATHY_3',	'EMPATHY_4',
                                            'city', 'state_region'))

cjt_ger_data_trust_gov <- read.qualtrics(filename = "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv", 
                                         new.format = T, 
                                         respondentID = "ResponseId",
                                         responses=c("force_choice", "Q184", "Q186", 
                                                     "Q188", "Q190", "Q192",
                                                     "Q194", "Q196", "Q198"),
                                         covariates=c('TRUST_GOVT'))

cjt_ger_data_rank <- read.qualtrics(filename = "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv", 
                                    new.format = T, 
                                    respondentID = "ResponseId",
                                    responses=c("force_choice", "Q184", "Q186", 
                                                "Q188", "Q190", "Q192",
                                                "Q194", "Q196", "Q198"),
                                    covariates=c("GENDER_resp", "EDUCATION_resp",	"IDEOLOGY",
                                                 'RELIGIOSITY_resp',	'NATIVE_BORN',	'EMPLOYMENT_resp',
                                                 'Age',	'TRUST_GOVT',	'POL_INTEREST',	
                                                 'FP_ORIENTATION_1',	'FP_ORIENTATION_2',	'FP_ORIENTATION_3',	'FP_ORIENTATION_4',
                                                 'EMPATHY_1',	'EMPATHY_2',	'EMPATHY_3',	'EMPATHY_4',
                                                 'city', 'state_region'),
                                    ranks = c("RATE_MIG1","RATE_MIG2",
                                              "Q168", "Q169",
                                              "Q170", "Q171",
                                              "Q172", "Q173",
                                              "Q174", "Q175",
                                              "Q176", "Q177",
                                              "Q178", "Q179",
                                              "Q180", "Q181",
                                              "Q182", "Q183"))

cjt_ger_data_rank <- cjt_ger_data_rank %>% 
  dplyr::rename(rank_outcome = selected) %>% 
  dplyr::select(rank_outcome)

cjt_ger_data_trust_gov <- cjt_ger_data_trust_gov %>% 
  dplyr::select(TRUST_GOVT)

cjt_ger_data <- cbind(cjt_ger_data, cjt_ger_data_rank, cjt_ger_data_trust_gov)

cjt_ger_data <- cjt_ger_data[!is.na(cjt_ger_data$selected), ]

######### Recoding ######### 
ger_states <- read.csv(file = 'germany_state_key.csv') 

names(ger_states) <- c("qualtrics_code", "state_name", "region",
                       "east_indicator", "east_indicator2",
                       "east_indicator3", "east_indicator4",
                       "east_indicator5", "east_indicator6",
                       "east_indicator7")

cjt_ger_data <- cjt_ger_data %>%
  mutate(state_num = as.numeric(paste(state_region))) %>%
  left_join(ger_states, by=c("state_num"= "qualtrics_code"))

cjt_ger_data$urban_indicator <- 1*(cjt_ger_data$city %in% c("Berlin", "Hamburg", "Munich",
                                                            "Cologne", "Frankfurt Am Main", "Stuttgart",
                                                            "Dusseldorf", "Dortmund", "Essen", "Leipzig"))

cjt_ger_data$FP_ORIENTATION_1 <- car::recode(cjt_ger_data$FP_ORIENTATION_1,
                                             "'Stimme vollstÃ¤ndig zu'=5; 'Stimme weitestgehend zu'=4; 'Stimme weder zu noch nicht zu'=3; 'Stimme weniger zu'=2; 'Stimme gar nicht zu'=1")
cjt_ger_data$FP_ORIENTATION_2 <- car::recode(cjt_ger_data$FP_ORIENTATION_2,
                                             "'Stimme vollstÃ¤ndig zu'=5; 'Stimme weitestgehend zu'=4; 'Stimme weder zu noch nicht zu'=3; 'Stimme weniger zu'=2; 'Stimme gar nicht zu'=1")
#reverse coded 
cjt_ger_data$FP_ORIENTATION_3 <- car::recode(cjt_ger_data$FP_ORIENTATION_3,
                                             "'Stimme vollstÃ¤ndig zu'=1; 'Stimme weitestgehend zu'=2; 'Stimme weder zu noch nicht zu'=3; 'Stimme weniger zu'=4; 'Stimme gar nicht zu'=5")

cjt_ger_data$EMPATHY_1 <- car::recode(cjt_ger_data$EMPATHY_1,
                                      "'Stimme vollstÃ¤ndig zu'=5; 'Stimme weitestgehend zu'=4; 'Stimme weder zu noch nicht zu'=3; 'Stimme weniger zu'=2; 'Stimme gar nicht zu'=1")
#reverse coded
cjt_ger_data$EMPATHY_2 <- car::recode(cjt_ger_data$EMPATHY_2,
                                      "'Stimme vollstÃ¤ndig zu'=1; 'Stimme weitestgehend zu'=2; 'Stimme weder zu noch nicht zu'=3; 'Stimme weniger zu'=4; 'Stimme gar nicht zu'=5")

#reverse coded
cjt_ger_data$EMPATHY_3 <- car::recode(cjt_ger_data$EMPATHY_3,
                                      "'Stimme vollstÃ¤ndig zu'=1; 'Stimme weitestgehend zu'=2; 'Stimme weder zu noch nicht zu'=3; 'Stimme weniger zu'=4; 'Stimme gar nicht zu'=5")

cjt_ger_data$EMPATHY_4 <- car::recode(cjt_ger_data$EMPATHY_4,
                                      "'Stimme vollstÃ¤ndig zu'=5; 'Stimme weitestgehend zu'=4; 'Stimme weder zu noch nicht zu'=3; 'Stimme weniger zu'=2; 'Stimme gar nicht zu'=1")
cjt_ger_data <- cjt_ger_data %>% 
  mutate(AGE = as.numeric(Age)) 

cjt_ger_data$GENDER_num <- ifelse(cjt_ger_data$GENDER_resp == 2, 1, 0)

cjt_ger_data$EDUCATION_num <- as.numeric(car::recode(cjt_ger_data$EDUCATION,
                                                     "'Abgeschlossenes Hochschulstudium'=6; 'Angefangenes Hochschulstudium'=5; 'Abitur'=4; 
                                                     'Facabitur'=3; 'Realschulabschluss'=2; 'Haptschulabschluss'=1"))-1
cjt_ger_data$IDEOLOGY_num <- as.numeric(car::recode(cjt_ger_data$IDEOLOGY,
                                                    "'Extrem liberal'=7; 'Liberal'=6; 'Etwas liberal'=5; 
                                                    'Moderat, die gemÃÂ¤ÃÅ¸igte Mitte'=4; 
                                                    'Etwas konservativ'=3; 'Konservativ'=2; 'Extrem konservativ'=1"))-1
cjt_ger_data$RELIGIOSITY_num <- as.numeric(car::recode(cjt_ger_data$RELIGIOSITY,
                                                       "'Mehr als einmal die Woche'=6; 'WÃÂ¶chentlich '=5; 'Ein paar Mal im Monat'=4; 
                                                       'Ein paar Mal im Jahr'=3; 'Einmal im Jahr oder weniger'=2; 'Nie'=1"))-1
cjt_ger_data$NATIVE_BORN_num <- ifelse(cjt_ger_data$NATIVE_BORN == 1, 1, 0)

cjt_ger_data$EMPLOYMENT_num <- as.numeric(car::recode(cjt_ger_data$EMPLOYMENT,
                                                      "'17'=7; '16'=6; '21'=5; '18'=4; 
                                                      '20'=3; '19'=2; '17 '=1"))
cjt_ger_data$TRUST_GOVT_num <-as.numeric(cjt_ger_data$TRUST_GOVT)-1
cjt_ger_data$POL_INTEREST_num <- as.numeric(car::recode(cjt_ger_data$POL_INTEREST,
                                                        "'Mesitens'=4; 
                                                        'Manchmal'=3; 'Nur ab und zu'=2; 'Kaum'=1"))-1

######### Construct scales ######### 
fp_orientation_ger <- data.frame(cjt_ger_data[,c("FP_ORIENTATION_1", "FP_ORIENTATION_2", "FP_ORIENTATION_3")])
empathy_ger <- data.frame(cjt_ger_data[,c("EMPATHY_1", "EMPATHY_2", "EMPATHY_3", "EMPATHY_4")])

fp_orientation_ger <- data.frame(sapply(fp_orientation_ger, FUN= function(x) as.numeric(x))-1)
empathy_ger <- data.frame(sapply(empathy_ger, FUN= function(x) as.numeric(x))-1)

#calculate chronbach's alpha for each index
# psych::alpha(fp_orientation_ger)  
# psych::alpha(empathy_ger) 

#r=create the index variable as the mean score on the individual items
cjt_ger_data$fp_orientation_index <- apply(fp_orientation_ger, MARGIN = 1, FUN = mean)
cjt_ger_data$empathy_index <- apply(empathy_ger, MARGIN = 1, FUN = mean)

######### Balance, summary stats ######### 
vars <- c('AGE', 'fp_orientation_index',  "empathy_index", 
          "GENDER_num", "EDUCATION_num",
          "IDEOLOGY_num",  "NATIVE_BORN_num",
          "EMPLOYMENT_num", "TRUST_GOVT_num",
          "POL_INTEREST_num","RELIGIOSITY_num"
)

var_labels <- c("Age", "Foreign Policy Orientation",  "Empathy",
                "Gender", "Education", "Ideology", "Native Born",
                "Employment", "Trust in Government", 
                "Political Interest","Religiosity"
)

sum_stats <- data.frame(matrix(NA,length(vars), 7))
colnames(sum_stats) <- c("Var.", "Min.", "1st Qu.",  "Median",
                         "Mean", "3rd Qu.",    "Max." )
sum_stats[, 1] <- var_labels

for (i in 1:length(vars)){
  string <- paste('sum <- summary(cjt_ger_data$',vars[i], ')',
                  sep = "", collapse = "")
  eval(parse(text=string))
  sum_stats[i, 2:7] <- sum
  
}

xtable(sum_stats, caption = "Experiment 1 Summary Statistics, GER Sample", digits = c(0, 0, 0, 2, 2, 2, 2, 0))

######### Conjoint main analysis ######### 
names(cjt_ger_data)[23] <- "Occupation"
names(cjt_ger_data)[25] <- "Gender"
names(cjt_ger_data)[27] <- "Reason.for.migration"
names(cjt_ger_data)[29] <- "Origin"
names(cjt_ger_data)[31] <- "Religion"
names(cjt_ger_data)[34] <- "Language.Fluency"
names(cjt_ger_data)[36] <- "Vulnerability"

baselines <- list()
baselines$Gender <- 'Weiblich'
baselines$Vulnerability <- 'Keine'
baselines$'Reason.for.migration' <- 'Wirtschaftliche Perspektive'
baselines$Occupation <- 'Arbeitslos'
baselines$'Language Fluency' <- 'Keine'
baselines$Origin <- 'Aus einem anderen Teil Ihres Landes'

cjt_ger_results <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation + Origin +
                                  Reason.for.migration + Religion + Vulnerability, 
                                data = cjt_ger_data,
                                cluster= T,
                                respondent.id = 'Response.ID',
                                design= cjt_ger_design2, 
                                baselines=baselines
)

summary(cjt_ger_results)$amce
xtable(summary(cjt_ger_results)$amce[, c(1:4, 7)], digits=3, 
       font.size = "small", caption = "AMCE, German Sample (Compared to baseline levels")


levels.test<-list()
levels.test[["Gender"]]<-c("Female","Male")
levels.test[["Language Fluency"]]<-c('None', "Fluent", "Broken")
levels.test[["Occupation"]]<-c("Unemployed","Doctor", "Teacher", "Cleaner")
levels.test[["Origin"]]<-c("Same Country", "Ethiopia", "Afghanistan", "Myanmar", "Ukraine")
levels.test[["Reason.for.migration"]]<-c("Economic","Flooding", "Drought", "Persecution", "Wildfires")
levels.test[["Religion"]]<-c("Athiest","Christian", "Muslim")
levels.test[["Vulnerability"]]<-c("None","Food insc.", "Physical handicap", "No family", "PTSD")

plot.amce(cjt_ger_results, xlab="Expected Change in Migrant Profile Selection, Germany",
          main="",
          level.names = levels.test,
          attribute.names = c("Gender","Language Fluency","Occupation",
                              "Origin", "Reason", "Religion", "Vulnerability"),
          xlim=c(-0.11, .2),
          text.size=9)

######### Robustness ######### 
#Only respondents who complete all 9 tasks
cjt_ger_data_only9tasks <- cjt_ger_data %>% 
  group_by(Response.ID) %>% 
  mutate(resp_profiles_count = n()) 

cjt_ger_data_only9tasks <- cjt_ger_data_only9tasks[cjt_ger_data_only9tasks$resp_profiles_count > 17, ]

nrow(cjt_ger_data) - nrow(cjt_ger_data_only9tasks) 
length(unique(cjt_ger_data$Response.ID)) -
  length(unique(cjt_ger_data_only9tasks$Response.ID))

cjt_ger_results_only_9tasks <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation + Origin +
                                              Reason.for.migration + Religion + Vulnerability, 
                                            data = cjt_ger_data_only9tasks,
                                            cluster= T,
                                            respondent.id = 'Response.ID',
                                            design= cjt_ger_design2, 
                                            baselines=baselines)

summary(cjt_ger_results_only_9tasks)$amce
xtable(summary(cjt_ger_results_only_9tasks)$amce[, c(1:4, 7)], digits=3, 
       font.size = "small", caption = "AMCE, German Sample (Compared to baseline levels- \n Only respondents who complete all 9 tasks")

summary(cjt_ger_results_only_9tasks)$amce$Estimate - summary(cjt_ger_results)$amce$Estimate

#Compare internal and external migrant profiles
cjt_ger_data_internal <- cjt_ger_data[! (cjt_ger_data$Origin %in% "Aus einem anderen Teil Ihres Landes" & 
                                           cjt_ger_data$Reason.for.migration %in% 
                                           c("DÃ¼rre", "WaldbrÃ¤nde",
                                             "Politische/religiÃ¶se/ethnische Verfolgung")), ]

cjt_ger_data_internal_strict <- cjt_ger_data[! (cjt_ger_data$Origin %in% "Aus einem anderen Teil Ihres Landes"), ]


length(unique(cjt_ger_data$Response.ID)) -
  length(unique(cjt_ger_data_internal$Response.ID))

cjt_ger_results_internal <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation + Origin +
                                           Reason.for.migration + Religion + Vulnerability, 
                                         data = cjt_ger_data_internal,
                                         cluster= T,
                                         respondent.id = 'Response.ID',
                                         design= cjt_ger_design2, 
                                         baselines=baselines)

summary(cjt_ger_results_internal)$amce$Estimate  - summary(cjt_ger_results)$amce$Estimate

ger_int_table1 <- as_tibble(summary(cjt_ger_results_internal)$amce[, c(1:4, 7)]) %>% 
  cbind(round(summary(cjt_ger_results_internal)$amce$Estimate  - summary(cjt_ger_results)$amce$Estimate, 3))

xtable(ger_int_table1, digits = 3,
       font.size = "small", caption = "AMCE, Ger Sample (Compared to baseline levels- \n Excluding 'implausible' internal migration profiles")

baselines$Origin <- 'Ukraine'

cjt_ger_results_internal_strict <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation + Origin +
                                                  Reason.for.migration + Religion + Vulnerability, 
                                                data = cjt_ger_data_internal_strict,
                                                cluster= T,
                                                respondent.id = 'Response.ID',
                                                design= cjt_ger_design2, 
                                                baselines=baselines)

cjt_ger_results2 <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation + Origin +
                                   Reason.for.migration + Religion + Vulnerability, 
                                 data = cjt_ger_data,
                                 cluster= T,
                                 respondent.id = 'Response.ID',
                                 design= cjt_ger_design2, 
                                 baselines=baselines
)

ger_int_table2 <- as_tibble(summary(cjt_ger_results_internal_strict)$amce[, c(1:4, 7)]) %>% 
  cbind(round(summary(cjt_ger_results_internal_strict)$amce$Estimate  - summary(cjt_ger_results2)$amce$Estimate[c(1:8, 10:20)], 3))

xtable(ger_int_table2, digits = 3,
       font.size = "small", caption = "AMCE, German Sample (Compared to baseline levels- \n Excluding all internal migration profiles")

summary(cjt_ger_results_internal_strict)$amce$Estimate  - summary(cjt_ger_results2)$amce$Estimate[c(1:8, 10:20)]

place_ger <- round(summary(cjt_ger_results_internal_strict)$amce$Estimate  - summary(cjt_ger_results2)$amce$Estimate[c(1:8, 10:20)], 4)

cjt_ger_internal_comparisons <- cbind(summary(cjt_ger_results_internal)$amce$Attribute, 
                                      summary(cjt_ger_results_internal)$amce$Level, 
                                      round(summary(cjt_ger_results_internal)$amce$Estimate  - summary(cjt_ger_results)$amce$Estimate, 4),
                                      c(place_ger[1:9], NA, place_ger[10:19]))

colnames(cjt_ger_internal_comparisons) <- c("Attribute", "Level", "Full Model - Implausible Internal Profiles Removed", "Full Model - All Internal Profiles Removed")

xtable(cjt_ger_internal_comparisons, 
       font.size = "small", caption = "AMCE Differences, German Sample (Compared to baseline levels- \n Full Set Compared to Restricted Internal Sets \n Baseline Origin for Second Comparison Changed to Ukraine")

baselines <- list()
baselines$Gender <- 'Weiblich'
baselines$Vulnerability <- 'Keine'
baselines$'Reason.for.migration' <- 'Wirtschaftliche Perspektive'
baselines$Occupation <- 'Arbeitslos'
baselines$'Language Fluency' <- 'Gebrochen'

cjt_ger_data_internal_actual <- cjt_ger_data[(cjt_ger_data$Origin %in% "Aus einem anderen Teil Ihres Landes"), ]

cjt_ger_results_internal_actual <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation  +
                                                  Reason.for.migration + Religion + Vulnerability, 
                                                data = cjt_ger_data_internal_actual,
                                                cluster= T,
                                                respondent.id = 'Response.ID',
                                                design= cjt_ger_design2_internal, 
                                                baselines=baselines)

cjt_ger_results3 <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation  +
                                   Reason.for.migration + Religion + Vulnerability, 
                                 data = cjt_ger_data,
                                 cluster= T,
                                 respondent.id = 'Response.ID',
                                 design= cjt_ger_design2, 
                                 baselines=baselines
)

ger_ext_table <- as_tibble(summary(cjt_ger_results_internal_actual)$amce[, c(1:4, 7)]) %>% 
  cbind(round(summary(cjt_ger_results_internal_actual)$amce$Estimate  - summary(cjt_ger_results3)$amce$Estimate[c(1:2, 4:16)], 3))

xtable(ger_ext_table, digits = 3,
       font.size = "small", caption = "AMCE, Ger Sample (Compared to baseline levels- \n Excluding external migration profiles")

#Only respondents 18 and over
cjt_ger_data_age_subset <- subset(x = cjt_ger_data, subset = AGE > 17)

nrow(cjt_ger_data) - nrow(cjt_ger_data_age_subset) 
length(unique(cjt_ger_data$Response.ID)) -
  length(unique(cjt_ger_data_age_subset$Response.ID))

names(cjt_ger_data_age_subset)[23] <- "Occupation"
names(cjt_ger_data_age_subset)[25] <- "Gender"
names(cjt_ger_data_age_subset)[27] <- "Reason.for.migration"
names(cjt_ger_data_age_subset)[29] <- "Origin"
names(cjt_ger_data_age_subset)[31] <- "Religion"
names(cjt_ger_data_age_subset)[34] <- "Language.Fluency"
names(cjt_ger_data_age_subset)[36] <- "Vulnerability"

baselines <- list()
baselines$Gender <- 'Weiblich'
baselines$Vulnerability <- 'Keine'
baselines$'Reason.for.migration' <- 'Wirtschaftliche Perspektive'
baselines$Occupation <- 'Arbeitslos'
baselines$'Language Fluency' <- 'Keine'
baselines$Origin <- 'Aus einem anderen Teil Ihres Landes'

cjt_ger_results_age_subset <- cjoint::amce(selected ~ Gender + Language.Fluency + Occupation + Origin +
                                             Reason.for.migration + Religion + Vulnerability, 
                                           data = cjt_ger_data_age_subset,
                                           cluster= T,
                                           respondent.id = 'Response.ID',
                                           design= cjt_ger_design2, 
                                           baselines=baselines
)

summary(cjt_ger_results_age_subset)$amce
xtable(summary(cjt_ger_results_age_subset)$amce[, c(1:4, 7)], digits=3, 
       font.size = "small", caption = "AMCE, German Sample Age Over 18 (Compared to baseline levels)")

summary(cjt_ger_results_age_subset)$amce$Estimate - summary(cjt_ger_results)$amce$Estimate

#Rank DV
cjt_ger_rank <- cjoint::amce(rank_outcome ~ Gender + Language.Fluency + Occupation + Origin +
                               Reason.for.migration + Religion + Vulnerability , 
                             data = cjt_ger_data,
                             cluster= T,
                             respondent.id = 'Response.ID',
                             design= cjt_ger_design2, 
                             baselines=baselines)

summary(cjt_ger_rank)$amce
xtable(summary(cjt_ger_rank)$amce[, c(1:4, 7)], digits=3, 
       font.size = "small", caption = "AMCE, German Sample (Compared to baseline levels): Rating Outcome")

plot.amce(cjt_ger_rank, xlab="Expected Change in Migrant Profile Selection, Germany (Rating Results)",
          main="", 
          level.names = levels.test,
          attribute.names = c("Gender","Language Fluency","Occupation",

... [truncated: 143,704 more bytes of this script omitted] ...

```

## How to run a script

Write each script to a file under the output directory, then run it with
exactly this command (the data directory is mounted read-only at its own
path; nothing else from the host is visible; `$SCRIPT` is the absolute path of
the script you wrote):

    SCRIPT=<repo>/benchmark/reproductions/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b/script.R   # or <repo>/benchmark/reproductions/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b/attempt-<n>/script.R
    docker run --rm --label retally.run=claude-code-arias-2022-changing-tides-climate-migration-seeded-2026-11-02-b --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b/mount/arias_2022_changing_tides_climate_migration:<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b/mount/arias_2022_changing_tides_climate_migration:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R > "$(dirname "$SCRIPT")/stdout.txt" 2> "$(dirname "$SCRIPT")/stderr.txt"; echo "exit code: $?"

The sandbox time limit is 300 seconds (memory 4g, 1.0 CPU).  Wrap the
command in a timeout of that many seconds: prefix it with
`perl -e 'alarm shift; exec @ARGV' 300` (or `gtimeout 300` if installed;
macOS has no `timeout`).  If the timeout fires, stop the container with
`docker ps -q --filter label=retally.run=claude-code-arias-2022-changing-tides-climate-migration-seeded-2026-11-02-b | xargs docker kill` and treat the
run as a crash (exit code 124).

## Output contract

The output directory `<repo>/benchmark/reproductions/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b/
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

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b`.
