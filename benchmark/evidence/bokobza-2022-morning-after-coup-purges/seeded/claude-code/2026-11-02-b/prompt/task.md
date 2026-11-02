# Retally reproduction task: bokobza-2022-morning-after-coup-purges (seeded, run 2026-11-02-b)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `bokobza-2022-morning-after-coup-purges`, mode `seeded`, run `2026-11-02-b`
- Paper: The Morning After: Cabinet Instability and the Purging of Ministers after Failed Coup Attempts in Autocracies
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b/mount/bokobza_2022_morning_after_coup_purges`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b/mount/bokobza_2022_morning_after_coup_purges` as data, and `<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b/paper.txt` as
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

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Claims to Reproduce
1. failed_coup_base_country_fe: 0.1 (change in the cabinet replacement rate (share of ministers, 0-1)) [type: coefficient]
   Location: Table A1 (Tables for Figure 2), column Base Model, Failed coup attempt
   Context: Table A1 ("Failed coup attempts. Country fixed effects: Country-level results"), Base Model column; plotted in the left panel of Figure 2. Time-series cross-sectional OLS of the year-to-year cabinet replacement rate (one minus the cabinet-size-adjusted retention rate of ministers, from WhoGov, July to July) on a failed coup attempt indicator (Powell and Thyne data; a failed coup before 1 July counts in that year, one after 1 July in the following year), with logged GDP per capita and logged population (Penn World Table 9.0) lagged one year, country fixed effects and year fixed effects. Sample:…
2. failed_coup_main_country_fe: 0.11 (change in the cabinet replacement rate (share of ministers, 0-1)) [type: coefficient]
   Location: Table A1, column Main Model, Failed coup attempt
   Context: Table A1, Main Model column (Figure 2, left panel). Same specification as failed_coup_base_country_fe plus lagged dummies for monarchy, military regime and party regime (Anckar and Fredriksson 2019); country and year fixed effects, country-clustered standard errors.
3. failed_coup_base_leader_fe: 0.08 (change in the cabinet replacement rate (share of ministers, 0-1)) [type: coefficient]
   Location: Table A2 (Tables for Figure 2), column Base Model, Failed coup attempt
   Context: Table A2 ("Failed coup attempts. Leader fixed effects: Country-level results"), Base Model column (Figure 2, left panel, leader fixed effects). Same regressors as failed_coup_base_country_fe (failed coup attempt, lagged logged GDP per capita and population, year fixed effects) with leader fixed effects instead of country fixed effects, so identification is within each autocrat's tenure. Standard errors clustered by country.
4. failed_coup_main_leader_fe: 0.09 (change in the cabinet replacement rate (share of ministers, 0-1)) [type: coefficient]
   Location: Table A2, column Main Model, Failed coup attempt
   Context: Table A2, Main Model column: the Main Model controls (lagged GDP per capita, population, monarchy, military and party regime dummies) with leader and year fixed effects; the monarchy dummy drops out as collinear with the leader fixed effects. Country-clustered standard errors.
5. failed_coup_experience_model: 0.14 (change in the probability of being purged next year) [type: coefficient]
   Location: Table K1 (Table for Figure 3), column H2a: Experience, Failed coup attempt
   Context: Table K1, column H2a: Experience; Figure 3 left panel. Linear probability model of whether a cabinet member is purged (absent from the cabinet the following year; reshuffles within the cabinet are not purges) on a failed coup attempt indicator, experience-group dummies (2-3, 4-6, over 6 years in cabinet; reference under 2 years), their interactions with the failed coup indicator, lagged logged GDP per capita and population, country and year fixed effects. Minister-years in autocracies 1967-2016, excluding the leader and junior ministers or other low-ranking posts; standard errors clustered by …
6. failed_coup_x_over_6_years_experience: -0.1 (difference in the change in purge probability) [type: coefficient]
   Location: Table K1, column H2a: Experience, FCA*Over 6 years of experience (Ref: <2 y)
   Context: Table K1, column H2a: Experience: the interaction of the failed coup attempt indicator with having over six years of cabinet experience (reference: under two years), in the same linear probability model as failed_coup_experience_model.
7. failed_coup_affiliation_model: 0.17 (change in the probability of being purged next year) [type: coefficient]
   Location: Table K1, column H2b: Affiliation, Failed coup attempt
   Context: Table K1, column H2b: Affiliation; Figure 3 right panel. Linear probability model of being purged next year on the failed coup attempt indicator, party affiliation dummies (no party affiliation; from the leader's party; reference: from another party than the leader's), their interactions with the failed coup indicator, cubic polynomials in the minister's years in office, lagged logged GDP per capita and population, country and year fixed effects, country-clustered standard errors. The failed coup coefficient is the effect for ministers from another party than the leader's.
8. failed_coup_x_leaders_party: -0.13 (difference in the change in purge probability) [type: coefficient]
   Location: Table K1, column H2b: Affiliation, FCA*From the leader's party (Ref: Other party)
   Context: Table K1, column H2b: the interaction of the failed coup attempt indicator with being from the leader's party (reference: another party), in the same model as failed_coup_affiliation_model.
9. failed_coup_responsibility_model: 0.2 (change in the probability of being purged next year) [type: coefficient]
   Location: Table K2 (Table for Figure 4), column H3a: Responsibility, Failed coup attempt
   Context: Table K2, column H3a: Responsibility; Figure 4 left panel. Linear probability model of being purged next year on the failed coup attempt indicator, portfolio dummies (Minister of Foreign Affairs, of Finance, of Natural Resources, other type of minister; reference: Minister of Defense), their interactions with the failed coup indicator, cubic polynomials in years in office, lagged logged GDP per capita and population, country and year fixed effects, country-clustered standard errors. The failed coup coefficient is the effect for ministers of defense.
10. failed_coup_x_natural_resources: -0.18 (difference in the change in purge probability) [type: coefficient]
   Location: Table K2, column H3a: Responsibility, FCA*Minister of Natural Resources (Ref: D)
   Context: Table K2, column H3a: the interaction of the failed coup attempt indicator with being minister of natural resources (reference: minister of defense), in the same model as failed_coup_responsibility_model.
11. failed_coup_importance_model: 0.37 (change in the probability of being purged next year) [type: coefficient]
   Location: Table K2, column H3b: Importance, Failed coup attempt
   Context: Table K2, column H3b: Importance; Figure 4 right panel. Linear probability model of being purged next year on the failed coup attempt indicator, rank-tier dummies (vice-president / deputy prime minister / top minister; medium-ranking; low-ranking; junior minister; reference: prime minister or president who is not the leader), their interactions with the failed coup indicator, cubic polynomials in years in office, lagged logged GDP per capita and population, country and year fixed effects, country-clustered standard errors. The failed coup coefficient is the effect for a prime minister or presi…

## Dataset Information
Name: bokobza_2022_morning_after_coup_purges
Local path: <repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b/mount/bokobza_2022_morning_after_coup_purges
File format: csv
Files in the dataset directory (paths relative to the local path above):
- morning_after_dataset_individuallevel.rds (91.8 MB) — data.frame, 205524 rows, 45 columns: year, party, leader, leader_party, party_group, experience, Group, experience_group, country_isocode, country_name, position, name, title, gender, birthyear, party_english, classification, portfolio_1, prestige_1, prestige_numeric, importance_numeric, purged_y1, purged_y2, coupattempt_presentyear, coup_presentyear, coup_lastyear, coupattempt_presentyear_br, coup_presentyear_br, coup_lastyear_br, coupattempt_whogov_type_br, leaderexperience_continuous, democracy_lag_br, n_part…
- morning_after_dataset_countrylevel.dta (1.7 MB) — 7878 rows, 37 columns: independent, democracy1, military_c, monarchy_c, party_c, YEAR_DATA, leader_cab_id, leaderexperience_continuous, COUNTRY_DATA, COUNTRY_ID, democracy_br, ldemocracy_br, replacement_rateadj_minister, replacement_rateadj_minister_300, replacement_rateadj_minister_200, replacement_rateadj_minister_100, coupattempt_whogov, coupattempt_month_whogov, coupattempt_whogov_br, coupattempt_whogov_type_br, ccode, gdp_cap_pwt_ln, pop_pwt_ln, elec_all, t1_e_a, oil_valuepop_2014_ln, growth_p…
- appendix_k1.tex (2.5 KB)
- appendix_k2.tex (3.1 KB)
- appendix_k3.tex (1.8 KB)
- appendix_l1.jpg (101.1 KB)
- appendix_l2.jpg (48.8 KB)
- appendix_m1.jpg (121.1 KB)
- appendix_m2.jpg (63.2 KB)
- appendix_n1.jpg (101.9 KB)
- appendix_n2.jpg (53.8 KB)
- appendix_o1.jpg (60.6 KB)
- appendix_p1.jpg (114.9 KB)
- appendix_p2.jpg (52.4 KB)
- appendix_r1.jpg (99.1 KB)
- figure1.jpg (1.4 MB)
- figure3.jpg (50.9 KB)
- figure4.jpg (73.9 KB)
- figure5.jpg (44.6 KB)
- metadata.json (966 B)
- morning_after_dofile_countrylevel.txt (48.7 KB)
- morning_after_logfile_countrylevel.smcl (1.3 MB)
- morning_after_logfile_individuallevel.html (858.7 KB)
- morning_after_script_individuallevel.R (95.4 KB)
- readme.txt (2.1 KB)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b/mount/bokobza_2022_morning_after_coup_purges' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
Installed packages (no network; nothing else can be installed): jsonlite, fixest, lfe, AER, ivreg, plm, estimatr, lme4, quantreg, car, sandwich, lmtest, clubSandwich, multiwayvcov, marginaleffects, MatchIt, optmatch, CBPS, WeightIt, cobalt, did, rdrobust, rddensity, Synth, modelsummary, stargazer, texreg, broom, tidyverse, dplyr, tidyr, readr, stringr, lubridate, data.table, haven, readxl, janitor, zoo, ggplot2, ggridges, ggrepel, gridExtra, cowplot, gtable, extrafont, sf, MASS, nnet, survival, splines, Matrix, boot, stats, utils.
Prefer fixest for fixed effects, IV and clustered SEs; use the other installed packages where the paper's method calls for them.
Set a deterministic seed with ``set.seed(42)`` for any randomness.
Do NOT access the internet; the container runs with --network none.
Do NOT shell out via system() / system2().
Emit RESULT:<name>=<value> lines to stdout at the end via cat().

## Original Replication Scripts
The replication package (the dataset directory) ships the authors' own analysis scripts, reproduced below.  These are the GROUND TRUTH for the exact estimating equation, variable names, sample restrictions, fixed effects, and standard-error clustering — follow them over anything reconstructed from the methodology summary, and prefer them over the paper's text where the two disagree.  Your job is to write R code that implements the SAME SPECIFICATION: translate what the scripts estimate, do not transliterate their syntax line by line (a Stata .do file's regression, e.g. `reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the equivalent fixest::feols() call in R).  Keep only the parts that produce the specific claims being reproduced; skip figure construction and unrelated robustness checks.  The scripts' data-file paths refer to the package's internal layout — resolve them against the dataset directory listed under Dataset Information.

### `morning_after_script_individuallevel.R`
```r
##############################
#
# Replication file for the individual analysis in:
#
# The Morning After:
# Cabinet Instability and the Purging of Ministers after Failed Coup Attempts in Autocracies
#
# Published in the Journal of Politics
#
##################

# Set-up

windowsFonts(Times=windowsFont("Times New Roman"))

pacman::p_load(tidyverse,texreg,haven,lfe)

############
# Figure 1 #
############

df_figure1 <- read_dta("morning_after_dataset_countrylevel.dta") %>% 
              filter(democracy1==0 & independent==1 & !is.na(coupattempt_whogov) & !is.na(replacement_rateadj_minister)) %>%
              mutate(coupattempt_whogov = as.factor(coupattempt_whogov),
                     coupattempt_whogov = recode(coupattempt_whogov,"1" = "Failed coup attempt","0" = "No failed coup attempt")) %>% 
              dplyr::select(coupattempt_whogov,replacement_rateadj_minister)
# Plot

figure_1 <- ggplot(df_figure1, aes(x=coupattempt_whogov, y=replacement_rateadj_minister)) + 
  geom_violin(fill='#cccccc',alpha=0.8) + 
  theme_bw() +
  theme(panel.border = element_blank(), panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),axis.title.y=element_text(size=16,angle=0,vjust=1),
        axis.text=element_text(size=16),
        text=element_text(family="Times")) +
        ylab("Replacement\nrates") +
        xlab("") +
  geom_boxplot(width=0.1)

# Data points

mean_violin <- df_figure1 %>% group_by(coupattempt_whogov) %>% summarize(median = median(replacement_rateadj_minister,na.rm=TRUE),n = n())

###
# Print ---
###

ggsave(
  'output/figure1.jpg',
  figure_1,
  width = 8,
  height = 6,
  dpi = 1200
)

#############################
# Individual level analysis #
#############################

###
## Load data ---
###

df_aut <- read_rds("morning_after_dataset_individuallevel.rds") %>% filter(democracy_lag == 0 & leader == 0 & !is.na(purged_y1) & !is.na(gdp_cap_pwt_ln) & !is.na(pop_pwt_ln))
  
##
# Get Number of coup attempts ---
##

df_aut_n <- df_aut %>% filter(!is.na(coupattempt_presentyear))

df_aut_names <- length(unique(df_aut_n$name))

n_countries <-  length(unique(df_aut_n$country_isocode))

table(df_aut_n$coupattempt_presentyear)

####
## Set up template for graphs ---
####

pd <- position_dodge(0.75)

plot_canvas <- function(df=df,x=name,y=estimate,se=se){
  ggplot(data = df, aes(y = estimate, x = name)) + 
  geom_point(position = pd) + 
  geom_errorbar(aes(ymin = estimate-1.96*se, ymax = estimate+1.96*se),
                width = 0,
                position = pd,
                size = 1) +
  coord_flip() +
  ylim(-0.1,0.5) +
  labs(x = "", 
       y = "Marginal Effects",
       color = "black") +
  geom_hline(yintercept = 0,
             linetype = "dashed") +
  theme_bw() +
  theme(panel.border = element_blank(), panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), axis.line = element_line(colour = "black"),
        legend.position = "",plot.title = element_text(size=14),
        axis.text.y = element_text(colour = "black",size=14),
        axis.text.x = element_text(colour = "black",size=14),
        text=element_text(family="Times",size=14,color="black"))
}

###
# Figure 3, 4, and 5 ---
###

# Responsibility ---

responsibility_felm <- felm(purged_y1 ~ minister_type/coupattempt_presentyear +
                              gdp_cap_pwt_ln + pop_pwt_ln + experience + I(experience^2) +
                              I(experience^3) | country_isocode+year | 0 | country_isocode , data=df_aut) %>% summary()

coef_responsibility <- tibble(name = c("Minister of Defense","Minister of Finance","Minister of Foreign Affairs",
                                       "Minister of Natural Resources","Other type of minister"),
                              estimate = c(responsibility_felm$coefficients[10],
                                           responsibility_felm$coefficients[11],
                                           responsibility_felm$coefficients[12],
                                           responsibility_felm$coefficients[13],
                                           responsibility_felm$coefficients[14]),
                              se = c(responsibility_felm$coefficients[10,2],
                                     responsibility_felm$coefficients[11,2],
                                     responsibility_felm$coefficients[12,2],
                                     responsibility_felm$coefficients[13,2],
                                     responsibility_felm$coefficients[14,2]
                              )) %>% mutate(name = fct_relevel(name,
                                                               "Minister of Natural Resources",
                                                               "Other type of minister",
                                                               "Minister of Finance",
                                                               "Minister of Foreign Affairs",
                                                               "Minister of Defense"
                              ))


plot_resp <- plot_canvas(coef_responsibility) + ggtitle("H3a: Ministerial responsibility")

# Affiliation ---

df_party <- df_aut %>% filter(party_group != "unknown") %>% mutate(party_group = as.factor(recode(party_group,"independent"="No party affiliation","leader_party"="From the leader's party","other_party"="From another party")))

affiliation_felm <- felm(purged_y1 ~ party_group/coupattempt_presentyear +
                                 gdp_cap_pwt_ln + pop_pwt_ln + experience + I(experience^2) +
                                 I(experience^3) | country_isocode+year | 0 | country_isocode , data=df_party) %>% summary()

coef_affiliation <- tibble(name = c("From another party","From the leader's party","No party affiliation"),
                              estimate = c(affiliation_felm$coefficients[8],
                                           affiliation_felm$coefficients[9],
                                           affiliation_felm$coefficients[10]),
                              se = c(affiliation_felm$coefficients[8,2],
                                     affiliation_felm$coefficients[9,2],
                                     affiliation_felm$coefficients[10,2]
                              )
                              ) %>% mutate(name = fct_relevel(name,
                                "From the leader's party",
                                "No party affiliation",
                                "From another party"))

plot_affiliation <- plot_canvas(coef_affiliation) + ggtitle("H2b: Affiliation")

# Importance ---

df_importance <- df_aut %>% filter(importance_factor != "0" & !is.na(importance_factor))

importance_felm <- felm(purged_y1 ~ importance_factor/coupattempt_presentyear +
                           gdp_cap_pwt_ln + pop_pwt_ln + experience + I(experience^2) +
                           I(experience^3) | country_isocode+year | 0 | country_isocode , data=df_importance) %>% summary()

coef_importance <- tibble(name = c("Junior minister\nor other low-\nranking post","Low-ranking\nminister","Medium-ranking\nminister",
                                    "Vice president,\ndeputy prime minister,\ntop minister","Prime minister/President\n(not leader)"),
                           estimate = c(importance_felm$coefficients[10],
                                        importance_felm$coefficients[11],
                                        importance_felm$coefficients[12],
                                        importance_felm$coefficients[13],
                                        importance_felm$coefficients[14]),
                           se = c(importance_felm$coefficients[10,2],
                                  importance_felm$coefficients[11,2],
                                  importance_felm$coefficients[12,2],
                                  importance_felm$coefficients[13,2],
                                  importance_felm$coefficients[14,2]
                           )
                           ) %>% mutate(name = fct_relevel(name,
                                                           "Junior minister\nor other low-\nranking post","Low-ranking\nminister","Medium-ranking\nminister",
                                                           "Vice president,\ndeputy prime minister,\ntop minister","Prime minister/President\n(not leader)"))


plot_importance <- plot_canvas(coef_importance) + ggtitle("H3b: Importance in cabinet") + ylim(-0.1,0.6)

# Experience ---

df_experience <- df_aut %>% filter(importance_factor != "0.5")

quantiles_experience <- df_aut %>% summarise(x = quantile(experience, c(0.25, 0.5, 0.75)), experience = c(0.25, 0.5, 0.75))

experience_group <- felm(purged_y1 ~ as.factor(experience_group)/coupattempt_presentyear +
                        gdp_cap_pwt_ln + pop_pwt_ln | country_isocode+year | 0 | country_isocode, data=df_experience) %>% summary()

coef_experience_group <- tibble(name = c("Less than 2 years","2-3 years",
                                    "4-6 years","Over 6 years"),
                           estimate = c(experience_group$coefficients[6],
                                        experience_group$coefficients[7],
                                        experience_group$coefficients[8],
                                        experience_group$coefficients[9]),
                           se = c(experience_group$coefficients[6,2],
                                  experience_group$coefficients[7,2],
                                  experience_group$coefficients[8,2],
                                  experience_group$coefficients[9,2]
                           )) %>% mutate(name = fct_relevel(name,
                                                            "Over 6 years","4-6 years",
                                                            "2-3 years",
                                                            "Less than 2 years"
                                                            
                           ))


plot_expgroup <- plot_canvas(coef_experience_group) + ggtitle("H2a: Experience")

# Combination (typology) ---

medianbyyear <- df_experience %>% group_by(country_isocode,year) %>% summarize(experience_median = median(experience,na.rm=TRUE))

df_combination <- df_experience %>% left_join(.,medianbyyear,by=c("country_isocode","year")) %>% filter(party_group != "unknown") %>%
                                                                                                 mutate(experience_bin = ifelse(experience >= experience_median, 1,0),
                                                                                                 important_bin = if_else(importance_numeric %in% c(3,4),1,0),
                                                                                                 loyal_bin = if_else(experience_bin == 1 & party_group == "leader_party",1,0),
                                                                                                 typology = case_when(important_bin == 0 & loyal_bin == 0 ~ 1,
                                                                                                                      important_bin == 1 & loyal_bin == 0 ~ 2,
                                                                                                                      important_bin == 0 & loyal_bin == 1 ~ 3,
                                                                                                                      important_bin == 1 & loyal_bin == 1 ~ 4
                                                                                                 )
)

combination_felm <- felm(purged_y1 ~ as.factor(typology)/coupattempt_presentyear +
                              gdp_cap_pwt_ln + pop_pwt_ln | country_isocode+year | 0 | country_isocode , data=df_combination) %>% summary()

coef_combination <- tibble(name = c("Low responsibility and weak signs of loyalty","High responsibility and weak signs of loyalty",
                                    "Low responsibility and strong signs of loyalty","High responsibility and strong signs of loyalty"),
                              estimate = c(combination_felm$coefficients[6],
                                           combination_felm$coefficients[7],
                                           combination_felm$coefficients[8],
                                           combination_felm$coefficients[9]),
                              se = c(combination_felm$coefficients[6,2],
                                     combination_felm$coefficients[7,2],
                                     combination_felm$coefficients[8,2],
                                     combination_felm$coefficients[9,2]
                              )) %>% mutate(name = fct_relevel(name,
                                                               "High responsibility and strong signs of loyalty","Low responsibility and strong signs of loyalty",
                                                               "High responsibility and weak signs of loyalty","Low responsibility and weak signs of loyalty"
                                                               
                              ))


plot_combination <- plot_canvas(coef_combination) + ggtitle("H4: Combinations of traits")

# Get N's

n_exp <-  df_experience %>% filter(!is.na(coupattempt_presentyear)) %>% group_by(coupattempt_presentyear) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
                             mutate(sum = sum(n))

n_affliation <-  df_party %>% filter(!is.na(coupattempt_presentyear)) %>% group_by(coupattempt_presentyear) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

n_resp <-  df_aut %>% filter(!is.na(coupattempt_presentyear) & !is.na(minister_type)) %>% group_by(coupattempt_presentyear) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

n_importance <-  df_importance %>% filter(!is.na(coupattempt_presentyear)) %>% group_by(coupattempt_presentyear) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

n_comb <-  df_combination %>% filter(!is.na(coupattempt_presentyear)) %>% group_by(coupattempt_presentyear) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

# Print ---

ggsave(
  'output/figure3.jpg',
  gridExtra::grid.arrange(plot_expgroup, plot_affiliation,ncol=2),
  width = 13,
  height = 6,
  dpi = 120
)

ggsave(
  'output/figure4.jpg',
  gridExtra::grid.arrange(plot_resp, plot_importance,ncol=2),
  width = 13,
  height = 6,
  dpi = 120
)

ggsave(
  'output/figure5.jpg',
  plot_combination,
  width = 10,
  height = 6,
  dpi = 120
)

################
## Appendix K ##
################

# Responsibility ---

df_aut <- df_aut %>% mutate(minister_type = fct_relevel(minister_type,
                                                      "Minister of Defense",
                                                      "Minister of Foreign Affairs",
                                                      "Minister of Finance",
                                                      "Other type of minister",                                                      
                                                      "Minister of Natural Resources"
                                                      ))


responsibility_felm <- felm(purged_y1 ~ minister_type*coupattempt_presentyear +
                              gdp_cap_pwt_ln + pop_pwt_ln + experience + I(experience^2) +
                              I(experience^3) | country_isocode+year | 0 | country_isocode, data=df_aut)


# Party affiliation ---

df_party <- df_party %>% mutate(party_group = fct_relevel(party_group,
                                                          "From another party",
                                                          "No party affiliation",
                                                            "From the leader's party"
))

affiliation_felm <- felm(purged_y1 ~ party_group*coupattempt_presentyear +
                           gdp_cap_pwt_ln + pop_pwt_ln + experience + I(experience^2) +
                           I(experience^3) | country_isocode+year | 0 | country_isocode, data=df_party)

# Importance ---

df_importance <- df_importance %>% mutate(importance_factor = fct_relevel(importance_factor,
                                                             "Prime minister/President\n(not leader)",
                                                             "Vice president,\ndeputy prime minister,\ntop minister",
                                                             "Medium-ranking\nminister",
                                                             "Low-ranking\nminister",
                                                             "Junior minister\nor other low-\nranking post"
))

importance_felm <- felm(purged_y1 ~ importance_factor*coupattempt_presentyear +
                          gdp_cap_pwt_ln + pop_pwt_ln + experience + I(experience^2) +
                          I(experience^3) | country_isocode+year | 0 | country_isocode, data=df_importance)

# Experience ---

experience_felm <- felm(purged_y1 ~ experience_group*coupattempt_presentyear +
                           gdp_cap_pwt_ln + pop_pwt_ln | country_isocode+year | 0 | country_isocode, data=df_experience)


# Combination ---

combination_felm <- felm(purged_y1 ~ relevel(as.factor(typology),2)*coupattempt_presentyear +
                           gdp_cap_pwt_ln + pop_pwt_ln | country_isocode+year | 0 | country_isocode , data=df_combination)


# Tables ---

# Table for Figure 3

texreg(list(experience_felm,affiliation_felm),stars = c(0.05),
       file="output/appendix_k1.tex",
       custom.model.names=c("H2a: Experience","H2b: Affiliation"),
       custom.coef.names=c("2-3 years of experience (Ref: <2 y)","4-6 years of experience (Ref: <2 y)","Over 6 years of experience (Ref: <2 y)",
                           "Failed coup attempt", "Log of GDP per capita","Log of Population",
                           "FCA*2-3 years of experience (Ref: <2 y)","FCA*4-6 years of experience (Ref: <2 y)","FCA*Over 6 years of experience (Ref: <2 y)",
                           "No party affiliation (Ref: Other party)","From the leader's party (Ref: Other party)","Experience","Experience^2","Experience^3",
                           "FCA*No party affiliation (Ref: Other party)",
                           "FCA*From the leader's party (Ref: Other party)"),
       reorder.coef=c(1,2,3,10,11,4,7,8,9,15,16,5,6,12,13,14),
       label = "indtable",
       single.row = TRUE,
       caption ="Table for Figure 3",
       caption.above=TRUE,
       include.ci = FALSE,
       include.adjrs = FALSE,
       include.rmse = FALSE,
       custom.note = ("\\parbox{\\linewidth}{\\vspace{2pt}%stars. Dependent variable: Purged next year. 
                      All models include country and year fixed effects. Country-clustered standard errors in parentheses. 
                      FCA = Failed coup attempt}"))

# Table for Figure 4

texreg(list(responsibility_felm,importance_felm),stars = c(0.05),
       file="output/appendix_k2.tex",
       custom.model.names=c("H3a: Responsibility","H3b: Importance"),
       custom.coef.names=c("Minister of Foreign Affairs (Ref: D)","Minister of Finance (Ref: D)", "Other type of minister (Ref: D)",
                            "Minister of Natural Resources (Ref: D)","Failed coup attempt","Log of GDP per capita","Log of Population",
                            "Experience","Experience^2","Experience^3","FCA: Minister of Foreign Affairs (Ref: D)",
                            "FCA*Minister of Finance (Ref: D)","FCA*Other type of minister (Ref: D)","FCA*Minister of Natural Resources (Ref: D)",
                            "VP, DP, top minister (Ref: PMP)","Medium-ranking minister (Ref: PMP)","Low-ranking minister (Ref: PMP)",
                           "Junior minister (Ref: PMP)","FCA*VP, DP, top minister (Ref: PMP)",
                           "FCA*Medium-ranking minister (Ref: PMP)","FCA*Low-ranking minister (Ref: PMP)",
                           "FCA*Junior minister (Ref: PMP)"),
       reorder.coef=c(1,2,3,4,
                      15,16,17,18,
                      5,
                      11,12,13,14,
                      19,20,21,22,
                      6,7,8,9,10),
       label = "indtable2",
       single.row = TRUE,
       caption ="Table for Figure 4",
       caption.above=TRUE,
       include.ci = FALSE,
       include.adjrs = FALSE,
       include.rmse = FALSE,
       custom.note = ("\\parbox{\\linewidth}{\\vspace{2pt}%stars. Dependent variable: Purged next year. 
                      All models include country and year fixed effects. Country-clustered standard errors in parentheses.
                      FCA = Failed coup attempt, D = Defense, PMP = Prime minister or President.}"))

# Table for Figure 5

texreg(list(combination_felm),stars = c(0.05),
       file="output/appendix_k3.tex",
       custom.model.names=c("Combination of traits"),
       custom.coef.names=c("Low responsibility and weak signs of loyalty (Ref: HW)",
                           "Low responsibility and strong signs of loyalty (Ref: HW)",
                          "High responsibility and strong signs of loyalty (Ref: HW)",
                          "Failed coup attempt","Log of GDP per capita","Log of Population",
                          "FCA*High responsibility and weak signs of loyalt (Ref: HW)",
                          "FCA*Low responsibility and strong signs of loyalty (Ref: HW)",
                          "FCA*High responsibility and strong signs of loyalty (Ref: HW)"),
       reorder.coef=c(1,2,3,4,
                      7,8,9,
                      6,5),
       label = "indtable3",
       single.row = TRUE,
       caption ="Table for Figure 5",
       caption.above=TRUE,
       include.ci = FALSE,
       include.adjrs = FALSE,
       include.rmse = FALSE,
       custom.note = ("\\parbox{\\linewidth}{\\vspace{2pt}%stars. Dependent variable: Purged next year. 
                      All models include country and year fixed effects. Country-clustered standard errors in parentheses.
                      FCA = Failed coup attempt, LW = High responsibility and weak signs of loyalty.}"))

################
## Appendix O ##
################

# Affiliation ---

df_party_morethanone <- df_aut %>% filter(party_group != "unknown" & n_party > 0) %>% mutate(party_group = as.factor(recode(party_group,"independent"="No party affiliation","leader_party"="From the leader's party","other_party"="From another party")))

affiliation_felm_morethanone <- felm(purged_y1 ~ party_group/coupattempt_presentyear +
                           gdp_cap_pwt_ln + pop_pwt_ln + experience + I(experience^2) +
                           I(experience^3) | country_isocode+year | 0 | country_isocode , data=df_party_morethanone) %>% summary()

coef_affiliation_morethanone <- tibble(name = c("From another party","From the leader's party","No party affiliation"),
                           estimate = c(affiliation_felm_morethanone$coefficients[8],
                                        affiliation_felm_morethanone$coefficients[9],
                                        affiliation_felm_morethanone$coefficients[10]),
                           se = c(affiliation_felm_morethanone$coefficients[8,2],
                                  affiliation_felm_morethanone$coefficients[9,2],
                                  affiliation_felm_morethanone$coefficients[10,2]
                           )
) %>% mutate(name = fct_relevel(name,
                                "From the leader's party",
                                "No party affiliation",
                                "From another party"))

plot_affiliation_morethanon <- plot_canvas(coef_affiliation_morethanone) + ggtitle("H2b: Affiliation")

# Combination (typology) ---

df_combination_morethanone <- df_combination %>% filter(party_group != "unknown" & n_party > 0)

combination_felm_morethanone <- felm(purged_y1 ~ as.factor(typology)/coupattempt_presentyear +
                           gdp_cap_pwt_ln + pop_pwt_ln | country_isocode+year | 0 | country_isocode , data=df_combination_morethanone) %>% summary()

coef_combination_morethanone <- tibble(name = c("Low responsibility and\nweak signs of loyalty","High responsibility and\nweak signs of loyalty",
                                    "Low responsibility and\nstrong signs of loyalty","High responsibility and\nstrong signs of loyalty"),
                           estimate = c(combination_felm_morethanone$coefficients[6],
                                        combination_felm_morethanone$coefficients[7],
                                        combination_felm_morethanone$coefficients[8],
                                        combination_felm_morethanone$coefficients[9]),
                           se = c(combination_felm_morethanone$coefficients[6,2],
                                  combination_felm_morethanone$coefficients[7,2],
                                  combination_felm_morethanone$coefficients[8,2],
                                  combination_felm_morethanone$coefficients[9,2]
                           )) %>% mutate(name = fct_relevel(name,
                                                            "High responsibility and\nstrong signs of loyalty","Low responsibility and\nstrong signs of loyalty",
                                                            "High responsibility and\nweak signs of loyalty","Low responsibility and\nweak signs of loyalty"
                                                            
                           ))


plot_combination_morethanone <- plot_canvas(coef_combination_morethanone) + ggtitle("H4: Combinations of traits")

# Get N's ---

n_exp <-  df_party_morethanone %>% filter(!is.na(coupattempt_presentyear)) %>% group_by(coupattempt_presentyear) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

n_comb <-  df_combination_morethanone %>% filter(!is.na(coupattempt_presentyear)) %>% group_by(coupattempt_presentyear) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

###
# Print ---
###

ggsave(
  'output/appendix_o1.jpg',
  gridExtra::grid.arrange(plot_affiliation_morethanon, plot_combination_morethanone,ncol=2),
  width = 10,
  height = 6,
  dpi = 120
)

################
## Appendix L ##
################

# Responsiblity ---

responsibility_felm_br <- felm(purged_y1 ~ minister_type/coupattempt_presentyear_br +
                              gdp_cap_pwt_ln + pop_pwt_ln + experience + I(experience^2) +
                              I(experience^3) | country_isocode+year | 0 | country_isocode , data=df_aut) %>% summary()

coef_responsibility_br <- tibble(name = c("Minister of Defense","Minister of Finance","Minister of Foreign Affairs",
                                       "Minister of Natural Resources","Other type of minister"),
                              estimate = c(responsibility_felm_br$coefficients[10],
                                           responsibility_felm_br$coefficients[11],
                                           responsibility_felm_br$coefficients[12],
                                           responsibility_felm_br$coefficients[13],
                                           responsibility_felm_br$coefficients[14]),
                              se = c(responsibility_felm_br$coefficients[10,2],
                                     responsibility_felm_br$coefficients[11,2],
                                     responsibility_felm_br$coefficients[12,2],
                                     responsibility_felm_br$coefficients[13,2],
                                     responsibility_felm_br$coefficients[14,2]
                              )) %>% mutate(name = fct_relevel(name,
                                                               "Minister of Natural Resources",
                                                               "Other type of minister",
                                                               "Minister of Finance",
                                                               "Minister of Foreign Affairs",
                                                               "Minister of Defense"
                              ))


plot_resp_br <- plot_canvas(coef_responsibility_br) + ggtitle("H3a: Ministerial responsibility")

# Affiliation ---

df_party <- df_aut %>% filter(party_group != "unknown") %>% mutate(party_group = as.factor(recode(party_group,"independent"="No party affiliation","leader_party"="From the leader's party","other_party"="From another party")))

affiliation_felm_br <- felm(purged_y1 ~ party_group/coupattempt_presentyear_br +
                           gdp_cap_pwt_ln + pop_pwt_ln + experience + I(experience^2) +
                           I(experience^3) | country_isocode+year | 0 | country_isocode , data=df_party) %>% summary()

coef_affiliation_br <- tibble(name = c("From another party","From the leader's party","No party affiliation"),
                           estimate = c(affiliation_felm_br$coefficients[8],
                                        affiliation_felm_br$coefficients[9],
                                        affiliation_felm_br$coefficients[10]),
                           se = c(affiliation_felm_br$coefficients[8,2],
                                  affiliation_felm_br$coefficients[9,2],
                                  affiliation_felm_br$coefficients[10,2]
                           )
) %>% mutate(name = fct_relevel(name,
                                "From the leader's party",
                                "No party affiliation",
                                "From another party"))

plot_affiliation_br <- plot_canvas(coef_affiliation_br) + ggtitle("H2b: Affiliation")

# Importance ---

df_importance <- df_aut %>% filter(importance_factor != "0")

importance_felm_br <- felm(purged_y1 ~ importance_factor/coupattempt_presentyear_br +
                          gdp_cap_pwt_ln + pop_pwt_ln + experience + I(experience^2) +
                          I(experience^3) | country_isocode+year | 0 | country_isocode , data=df_importance) %>% summary()

coef_importance_br <- tibble(name = c("Junior minister\nor other low\nranking post","Low-ranking\nminister","Medium-ranking\nminister",
                                   "Vice president,\ndeputy prime minister,\ntop minister","Prime minister/President\n(not leader)"),
                          estimate = c(importance_felm_br$coefficients[10],
                                       importance_felm_br$coefficients[11],
                                       importance_felm_br$coefficients[12],
                                       importance_felm_br$coefficients[13],
                                       importance_felm_br$coefficients[14]),
                          se = c(importance_felm_br$coefficients[10,2],
                                 importance_felm_br$coefficients[11,2],
                                 importance_felm_br$coefficients[12,2],
                                 importance_felm_br$coefficients[13,2],
                                 importance_felm_br$coefficients[14,2]
                          )
) %>% mutate(name = fct_relevel(name,
                                "Junior minister\nor other low\nranking post","Low-ranking\nminister","Medium-ranking\nminister",
                                "Vice president,\ndeputy prime minister,\ntop minister","Prime minister/President\n(not leader)"))


plot_importance_br <- plot_canvas(coef_importance_br) + ggtitle("H3b: Importance in cabinet") + ylim(-0.1,0.6)

# Experience ---

experience_group_br <- felm(purged_y1 ~ as.factor(experience_group)/coupattempt_presentyear_br +
                           gdp_cap_pwt_ln + pop_pwt_ln | country_isocode+year | 0 | country_isocode, data=df_experience) %>% summary()

coef_experience_group <- tibble(name = c("Less than 2 years","2-3 years",
                                         "4-6 years","Over 6 years"),
                                estimate = c(experience_group_br$coefficients[6],
                                             experience_group_br$coefficients[7],
                                             experience_group_br$coefficients[8],
                                             experience_group_br$coefficients[9]),
                                se = c(experience_group_br$coefficients[6,2],
                                       experience_group_br$coefficients[7,2],
                                       experience_group_br$coefficients[8,2],
                                       experience_group_br$coefficients[9,2]
                                )) %>% mutate(name = fct_relevel(name,
                                                                 "Over 6 years","4-6 years",
                                                                 "2-3 years",
                                                                 "Less than 2 years"
                                                                 
                                ))


plot_expgroup_br <- plot_canvas(coef_experience_group) + ggtitle("H2a: Experience")

# Combination ---

combination_felm_br <- felm(purged_y1 ~ as.factor(typology)/coupattempt_presentyear_br +
                           gdp_cap_pwt_ln + pop_pwt_ln | country_isocode+year | 0 | country_isocode , data=df_combination) %>% summary()

coef_combination_br <- tibble(name = c("Low responsibility and weak signs of loyalty","High responsibility and weak signs of loyalty",
                                    "Low responsibility and strong signs of loyalty","High responsibility and strong signs of loyalty"),
                           estimate = c(combination_felm_br$coefficients[6],
                                        combination_felm_br$coefficients[7],
                                        combination_felm_br$coefficients[8],
                                        combination_felm_br$coefficients[9]),
                           se = c(combination_felm_br$coefficients[6,2],
                                  combination_felm_br$coefficients[7,2],
                                  combination_felm_br$coefficients[8,2],
                                  combination_felm_br$coefficients[9,2]
                           )) %>% mutate(name = fct_relevel(name,
                                                            "High responsibility and strong signs of loyalty","Low responsibility and strong signs of loyalty",
                                                            "High responsibility and weak signs of loyalty","Low responsibility and weak signs of loyalty"
                                                            
                           ))


plot_combination_br <- plot_canvas(coef_combination_br) + ggtitle("H4: Combinations of traits")

# Get N's ---

n_exp <-  df_experience %>% filter(!is.na(coupattempt_presentyear_br)) %>% group_by(coupattempt_presentyear_br) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

n_affliation <-  df_party %>% filter(!is.na(coupattempt_presentyear_br)) %>% group_by(coupattempt_presentyear_br) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

n_resp <-  df_aut %>% filter(!is.na(coupattempt_presentyear_br) & !is.na(minister_type)) %>% group_by(coupattempt_presentyear_br) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

n_importance <-  df_importance %>% filter(!is.na(coupattempt_presentyear_br)) %>% group_by(coupattempt_presentyear_br) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

n_comb <-  df_combination %>% filter(!is.na(coupattempt_presentyear_br)) %>% group_by(coupattempt_presentyear_br) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

# Print ---

ggsave(
  'output/appendix_l1.jpg',
  gridExtra::grid.arrange(plot_expgroup_br, plot_affiliation_br, plot_resp_br, plot_importance_br),
  width = 10,
  height = 9,
  dpi = 120
)

ggsave(
  'output/appendix_l2.jpg',
  plot_combination_br,
  width = 8,
  height = 9,
  dpi = 120
)

################
## Appendix P ##
################

## Set up template ---

pd <- position_dodge(0.75)

plot_canvas_type <- function(df=df,x=name,y=estimate,se=se, group = group){
    ggplot(data = df, aes(y = estimate, x = name, group = group, colour = group)) + 
    geom_point(position = pd) + 
    geom_errorbar(aes(ymin = estimate-1.96*se, ymax = estimate+1.96*se),
                  width = 0,
                  position = pd,
                  size = 1) +
    coord_flip() +
    ylim(-0.2,0.5) +
    labs(x = "", 
         y = "Marginal Effects",
         color = "black") +
    geom_hline(yintercept = 0,
               linetype = "dashed") +
    theme_bw() +
    theme(panel.border = element_blank(), panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(), axis.line = element_line(colour = "black"),
          legend.position = "bottom",plot.title = element_text(size=14),
          axis.text.y = element_text(colour = "black",size=14),
          axis.text.x = element_text(colour = "black",size=14),
          text=element_text(family="Times",size=14,color="black")) +
    scale_colour_manual(
      name = "", 
      breaks = c("Civilian coup","Military coup"),
      labels = c("Civilian coup","Military coup"),
      values = c("Grey", "Black"))
}

###
# Marginal effects ---
###

# Responsiblity ---

responsibility_felm_brtype <- felm(purged_y1 ~ minister_type/coupattempt_whogov_type_br +
                                 gdp_cap_pwt_ln + pop_pwt_ln + experience + I(experience^2) +
                                 I(experience^3) | country_isocode+year | 0 | country_isocode , data=df_aut) %>% summary()

coef_responsibility_br_type <- tibble(name = c("Minister of Defense","Minister of Finance","Minister of Foreign Affairs",
                                          "Minister of Natural Resources","Other type of minister",
                                          "Minister of Defense","Minister of Finance","Minister of Foreign Affairs",
                                          "Minister of Natural Resources","Other type of minister"),
                                 estimate = c(responsibility_felm_brtype$coefficients[10],
                                              responsibility_felm_brtype$coefficients[11],
                                              responsibility_felm_brtype$coefficients[12],
                                              responsibility_felm_brtype$coefficients[13],
                                              responsibility_felm_brtype$coefficients[14],
                                              responsibility_felm_brtype$coefficients[15],
                                              responsibility_felm_brtype$coefficients[16],
                                              responsibility_felm_brtype$coefficients[17],
                                              responsibility_felm_brtype$coefficients[18],
                                              responsibility_felm_brtype$coefficients[19]),
                                 se = c(responsibility_felm_brtype$coefficients[10,2],
                                        responsibility_felm_brtype$coefficients[11,2],
                                        responsibility_felm_brtype$coefficients[12,2],
                                        responsibility_felm_brtype$coefficients[13,2],
                                        responsibility_felm_brtype$coefficients[14,2],
                                        responsibility_felm_brtype$coefficients[15,2],
                                        responsibility_felm_brtype$coefficients[16,2],
                                        responsibility_felm_brtype$coefficients[17,2],
                                        responsibility_felm_brtype$coefficients[18,2],
                                        responsibility_felm_brtype$coefficients[19,2]),
                                 group = c(rep("Civilian coup",5),rep("Military coup",5))) %>% 
                                 mutate(name = fct_relevel(name,
                                                                  "Minister of Natural Resources",
                                                                  "Other type of minister",
                                                                  "Minister of Finance",
                                                                  "Minister of Foreign Affairs",
                                                                  "Minister of Defense"
                                 ),
                                 group = fct_relevel(group,"Military coup","Civilian coup")
                                 )


plot_resp_br_type <- plot_canvas_type(coef_responsibility_br_type) + ggtitle("H3a: Ministerial responsibility")

# Affiliation ---

affiliation_felm_br <- felm(purged_y1 ~ party_group/coupattempt_whogov_type_br +
                              gdp_cap_pwt_ln + pop_pwt_ln + experience + I(experience^2) +
                              I(experience^3) | country_isocode+year | 0 | country_isocode , data=df_party) %>% summary()

coef_affiliation_br_type <- tibble(name = c("From another party","From the leader's party","No party affiliation",
                                       "From another party","From the leader's party","No party affiliation"),
                              estimate = c(affiliation_felm_br$coefficients[8],
                                           affiliation_felm_br$coefficients[9],
                                           affiliation_felm_br$coefficients[10],
                                           affiliation_felm_br$coefficients[11],
                                           affiliation_felm_br$coefficients[12],
                                           affiliation_felm_br$coefficients[13]),
                              se = c(affiliation_felm_br$coefficients[8,2],
                                     affiliation_felm_br$coefficients[9,2],
                                     affiliation_felm_br$coefficients[10,2],
                                     affiliation_felm_br$coefficients[11,2],
                                     affiliation_felm_br$coefficients[12,2],
                                     affiliation_felm_br$coefficients[13,2]),
                                     group = c(rep("Civilian coup",3),rep("Military coup",3)
                              )) %>% 
              mutate(name = fct_relevel(name,
                                "From the leader's party",
                                "No party affiliation",
                                "From another party"
                                ),
             group = fct_relevel(group,"Military coup","Civilian coup")
             )

plot_affiliation_br_type <- plot_canvas_type(coef_affiliation_br_type) + ggtitle("H2b: Affiliation")

# Importance ---

importance_felm_br <- felm(purged_y1 ~ importance_factor/coupattempt_whogov_type_br +
                             gdp_cap_pwt_ln + pop_pwt_ln + experience + I(experience^2) +
                             I(experience^3) | country_isocode+year | 0 | country_isocode , data=df_importance) %>% summary()

coef_importance_br_type <- tibble(name = c("Junior minister\nor other low\nranking post","Low-ranking\nminister","Medium-ranking\nminister",
                                      "Vice president,\ndeputy prime minister,\ntop minister","Prime minister/President\n(not leader)",
                                      "Junior minister\nor other low\nranking post","Low-ranking\nminister","Medium-ranking\nminister",
                                      "Vice president,\ndeputy prime minister,\ntop minister","Prime minister/President\n(not leader)"),
                             estimate = c(importance_felm_br$coefficients[10],
                                          importance_felm_br$coefficients[11],
                                          importance_felm_br$coefficients[12],
                                          importance_felm_br$coefficients[13],
                                          importance_felm_br$coefficients[14],
                                          importance_felm_br$coefficients[15],
                                          importance_felm_br$coefficients[16],
                                          importance_felm_br$coefficients[17],
                                          importance_felm_br$coefficients[18],
                                          importance_felm_br$coefficients[19]),
                             se = c(importance_felm_br$coefficients[10,2],
                                    importance_felm_br$coefficients[11,2],
                                    importance_felm_br$coefficients[12,2],
                                    importance_felm_br$coefficients[13,2],
                                    importance_felm_br$coefficients[14,2],
                                    importance_felm_br$coefficients[15,2],
                                    importance_felm_br$coefficients[16,2],
                                    importance_felm_br$coefficients[17,2],
                                    importance_felm_br$coefficients[18,2],
                                    importance_felm_br$coefficients[19,2]),
                             group = c(rep("Civilian coup",5),rep("Military coup",5)
                             )
) %>% mutate(name = fct_relevel(name,
                                "Junior minister\nor other low\nranking post","Low-ranking\nminister","Medium-ranking\nminister",
                                "Vice president,\ndeputy prime minister,\ntop minister","Prime minister/President\n(not leader)"),
             group = fct_relevel(group,"Military coup","Civilian coup"))


plot_importance_br_type <- plot_canvas_type(coef_importance_br_type) + ggtitle("H3b: Importance in cabinet") + ylim(-0.2,0.6)

# Experience ---

experience_group_br <- felm(purged_y1 ~ as.factor(experience_group)/coupattempt_whogov_type_br +
                              gdp_cap_pwt_ln + pop_pwt_ln | country_isocode+year | 0 | country_isocode, data=df_experience) %>% summary()

coef_experience_group_type <- tibble(name = c("Less than 2 years","2-3 years",
                                         "4-6 years","Over 6 years",
                                         "Less than 2 years","2-3 years",
                                         "4-6 years","Over 6 years"),
                                estimate = c(experience_group_br$coefficients[6],
                                             experience_group_br$coefficients[7],
                                             experience_group_br$coefficients[8],
                                             experience_group_br$coefficients[9],
                                             experience_group_br$coefficients[10],
                                             experience_group_br$coefficients[11],
                                             experience_group_br$coefficients[12],
                                             experience_group_br$coefficients[13]),
                                se = c(experience_group_br$coefficients[6,2],
                                       experience_group_br$coefficients[7,2],
                                       experience_group_br$coefficients[8,2],
                                       experience_group_br$coefficients[9,2],
                                       experience_group_br$coefficients[10,2],
                                       experience_group_br$coefficients[11,2],
                                       experience_group_br$coefficients[12,2],
                                       experience_group_br$coefficients[13,2]),
                                group = c(rep("Civilian coup",4),rep("Military coup",4))) %>% 
                                mutate(name = fct_relevel(name,
                                                                 "Over 6 years","4-6 years",
                                                                 "2-3 years",
                                                                 "Less than 2 years"
                                                                 
                                ),
                                group = fct_relevel(group,"Military coup","Civilian coup"))


plot_expgroup_br_type <- plot_canvas_type(coef_experience_group_type) + ggtitle("H2a: Experience")

# Combination ---

combination_felm_br <- felm(purged_y1 ~ as.factor(typology)/coupattempt_whogov_type_br +
                              gdp_cap_pwt_ln + pop_pwt_ln | country_isocode+year | 0 | country_isocode , data=df_combination) %>% summary()

coef_combination_br_type <- tibble(name = c("Low responsibility and weak signs of loyalty","High responsibility and weak signs of loyalty",
                                       "Low responsibility and strong signs of loyalty","High responsibility and strong signs of loyalty",
                                       "Low responsibility and weak signs of loyalty","High responsibility and weak signs of loyalty",
                                       "Low responsibility and strong signs of loyalty","High responsibility and strong signs of loyalty"),
                              estimate = c(combination_felm_br$coefficients[6],
                                           combination_felm_br$coefficients[7],
                                           combination_felm_br$coefficients[8],
                                           combination_felm_br$coefficients[9],
                                           combination_felm_br$coefficients[10],
                                           combination_felm_br$coefficients[11],
                                           combination_felm_br$coefficients[12],
                                           combination_felm_br$coefficients[13]),
                              se = c(combination_felm_br$coefficients[6,2],
                                     combination_felm_br$coefficients[7,2],
                                     combination_felm_br$coefficients[8,2],
                                     combination_felm_br$coefficients[9,2],
                                     combination_felm_br$coefficients[10,2],
                                     combination_felm_br$coefficients[11,2],
                                     combination_felm_br$coefficients[12,2],
                                     combination_felm_br$coefficients[13,2]),
                              group = c(rep("Civilian coup",4),rep("Military coup",4))) %>% 
                              mutate(name = fct_relevel(name,"High responsibility and strong signs of loyalty","Low responsibility and strong signs of loyalty",
                                                             "High responsibility and weak signs of loyalty","Low responsibility and weak signs of loyalty"),
                              group = fct_relevel(group,"Military coup","Civilian coup"))

plot_combination_br_type <- plot_canvas_type(coef_combination_br_type) + ggtitle("H4: Combinations of traits")

# Get N's ---

n_exp <-  df_experience %>% filter(!is.na(coupattempt_whogov_type_br) & coupattempt_whogov_type_br !="Royal") %>% group_by(coupattempt_whogov_type_br) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

n_affliation <-  df_party %>% filter(!is.na(coupattempt_whogov_type_br) & coupattempt_whogov_type_br !="Royal") %>% group_by(coupattempt_whogov_type_br) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

n_resp <-  df_aut %>% filter(!is.na(coupattempt_whogov_type_br) & coupattempt_whogov_type_br !="Royal" & !is.na(minister_type)) %>% group_by(coupattempt_whogov_type_br) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

n_importance <-  df_importance %>% filter(!is.na(coupattempt_whogov_type_br) & coupattempt_whogov_type_br !="Royal") %>% group_by(coupattempt_whogov_type_br) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

n_comb <-  df_combination %>% filter(!is.na(coupattempt_whogov_type_br) & coupattempt_whogov_type_br !="Royal") %>% group_by(coupattempt_whogov_type_br) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

###
# Print ---
###

ggsave(
  'output/appendix_p1.jpg',
  gridExtra::grid.arrange(plot_expgroup_br_type, plot_affiliation_br_type, plot_resp_br_type, plot_importance_br_type),
  width = 10,
  height = 9,
  dpi = 120
)

ggsave(
  'output/appendix_p2.jpg',
  plot_combination_br_type,
  width = 8,
  height = 9,
  dpi = 120
)

################
## Appendix R ##
################

###
# Marginal effects ---
###

# Gender

df_aut_gender <- df_aut %>% filter(gender != "Unknown")

hired_gender_felm <- felm(hired ~ gender/coup_lastyear +
                              gdp_cap_pwt_ln + pop_pwt_ln | country_isocode+year | 0 | country_isocode , data=df_aut_gender) %>% summary()

hired_gender <- tibble(name = c("Female","Male"),
                           estimate = c(hired_gender_felm$coefficients[4],
                                        hired_gender_felm$coefficients[5]),
                           se = c(hired_gender_felm$coefficients[4],
                                  hired_gender_felm$coefficients[5]
                           )
) %>% mutate(name = fct_relevel(name,
                                "Female",
                                "Male"))

hired_plot_gender <- plot_canvas(hired_gender) + ggtitle("Gender") + ylim(-0.2,0.5)

# Party affiliation

hired_affiliation_felm <- felm(hired ~ party_group/coup_lastyear +
                              gdp_cap_pwt_ln + pop_pwt_ln | country_isocode+year | 0 | country_isocode , data=df_party) %>% summary()

hired_coef_affiliation <- tibble(name = c("From another party","From the leader's party","No party affiliation"),
                           estimate = c(hired_affiliation_felm$coefficients[5],
                                        hired_affiliation_felm$coefficients[6],
                                        hired_affiliation_felm$coefficients[7]),
                           se = c(hired_affiliation_felm$coefficients[5],
                                  hired_affiliation_felm$coefficients[6],
                                  hired_affiliation_felm$coefficients[7]
                           )
) %>% mutate(name = fct_relevel(name,
                                "From the leader's party",
                                "No party affiliation",
                                "From another party"))

hired_plot_affiliation <- plot_canvas(hired_coef_affiliation) + ggtitle("Affiliation") + ylim(-0.3,0.8)

# Position

responsibility_felm_hired <- felm(hired ~ minister_type/coup_lastyear +
                              gdp_cap_pwt_ln + pop_pwt_ln | country_isocode+year | 0 | country_isocode , data=df_aut) %>% summary()

coef_responsibility_hired <- tibble(name = c("Minister of Defense","Minister of Finance","Minister of Foreign Affairs",
                                          "Minister of Natural Resources","Other type of minister"),
                                 estimate = c(responsibility_felm_hired$coefficients[7],
                                              responsibility_felm_hired$coefficients[8],
                                              responsibility_felm_hired$coefficients[9],
                                              responsibility_felm_hired$coefficients[10],
                                              responsibility_felm_hired$coefficients[11]),
                                 se = c(responsibility_felm_hired$coefficients[7],
                                        responsibility_felm_hired$coefficients[8],
                                        responsibility_felm_hired$coefficients[9],
                                        responsibility_felm_hired$coefficients[10],
                                        responsibility_felm_hired$coefficients[11]
                                 )) %>% mutate(name = fct_relevel(name,
                                                                  "Minister of Natural Resources",
                                                                  "Other type of minister",
                                                                  "Minister of Finance",
                                                                  "Minister of Foreign Affairs",
                                                                  "Minister of Defense"
                                 ))


hired_plot_resp <- plot_canvas(coef_responsibility_hired) + ggtitle("Ministerial responsibility") + ylim(-0.2,0.8)

# Importance

df_importance <- df_aut %>% filter(importance_factor != "0")

importance_felm_hired <- felm(hired ~ importance_factor/coup_lastyear +
                          gdp_cap_pwt_ln + pop_pwt_ln | country_isocode+year | 0 | country_isocode , data=df_importance) %>% summary()

coef_importance_hired <- tibble(name = c("Junior minister\nor other low\nranking post","Low-ranking\nminister","Medium-ranking\nminister",
                                   "Vice president,\ndeputy prime minister,\ntop minister","Prime minister/President\n(not leader)"),
                          estimate = c(importance_felm_hired$coefficients[7],
                                       importance_felm_hired$coefficients[8],
                                       importance_felm_hired$coefficients[9],
                                       importance_felm_hired$coefficients[10],
                                       importance_felm_hired$coefficients[11]),
                          se = c(importance_felm_hired$coefficients[7],
                                 importance_felm_hired$coefficients[8],
                                 importance_felm_hired$coefficients[9],
                                 importance_felm_hired$coefficients[10],
                                 importance_felm_hired$coefficients[11]
                          )
) %>% mutate(name = fct_relevel(name,
                                "Junior minister\nor other low\nranking post","Low-ranking\nminister","Medium-ranking\nminister",
                                "Vice president,\ndeputy prime minister,\ntop minister","Prime minister/President\n(not leader)"))


hired_plot_importance <- plot_canvas(coef_importance_hired) + ggtitle("Importance in cabinet") + ylim(-0.2,0.6)

# Get N's ---

n_gender <-  df_aut_gender %>% filter(!is.na(coup_lastyear) & !is.na(gender)) %>% group_by(coup_lastyear) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

n_party <-  df_party %>% filter(!is.na(coup_lastyear) & !is.na(party_group)) %>% group_by(coup_lastyear) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

n_responsibility <-  df_aut %>% filter(!is.na(coup_lastyear) & !is.na(minister_type)) %>% group_by(coup_lastyear) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

n_importance <-  df_importance %>% filter(!is.na(coup_lastyear)) %>% group_by(coup_lastyear) %>% summarize(n = as.numeric(n())) %>% ungroup() %>%
  mutate(sum = sum(n))

###
# Print ---
###

ggsave(
  'output/appendix_r1.jpg',
  gridExtra::grid.arrange(hired_plot_gender, hired_plot_affiliation,hired_plot_resp,hired_plot_importance,ncol=2),
  width = 10,
  height = 9,
  dpi = 120
)


################
## Appendix N ##
################

df_aut <- read_rds("morning_after_dataset_individuallevel.rds") %>% 
          filter(democracy_lag == 0 & leader == 0 & !is.na(purged_y1) & !is.na(gdp_cap_pwt_ln) & !is.na(pop_pwt_ln) & leaderexperience_continuous > 1)

###
# Marginal effects ---
###


... [truncated: 35,983 more bytes of this script omitted] ...

```

## How to run a script

Write each script to a file under the output directory, then run it with
exactly this command (the data directory is mounted read-only at its own
path; nothing else from the host is visible; `$SCRIPT` is the absolute path of
the script you wrote):

    SCRIPT=<repo>/benchmark/reproductions/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b/script.R   # or <repo>/benchmark/reproductions/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b/attempt-<n>/script.R
    docker run --rm --label retally.run=claude-code-bokobza-2022-morning-after-coup-purges-seeded-2026-11-02-b --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b/mount/bokobza_2022_morning_after_coup_purges:<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b/mount/bokobza_2022_morning_after_coup_purges:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R > "$(dirname "$SCRIPT")/stdout.txt" 2> "$(dirname "$SCRIPT")/stderr.txt"; echo "exit code: $?"

The sandbox time limit is 300 seconds (memory 4g, 1.0 CPU).  Wrap the
command in a timeout of that many seconds: prefix it with
`perl -e 'alarm shift; exec @ARGV' 300` (or `gtimeout 300` if installed;
macOS has no `timeout`).  If the timeout fires, stop the container with
`docker ps -q --filter label=retally.run=claude-code-bokobza-2022-morning-after-coup-purges-seeded-2026-11-02-b | xargs docker kill` and treat the
run as a crash (exit code 124).

## Output contract

The output directory `<repo>/benchmark/reproductions/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b/
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

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b`.
