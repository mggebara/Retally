suppressMessages(library(haven)); suppressMessages(library(dplyr))
d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/blind/2026-11-02-b/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
print(table(d$wave, d$wavenum))
print(table(exog = d$flag_exclude_exog, low = d$flag_low_wtp))
print(table(d$treatment, flagged = (d$flag_exclude_exog == 1 | d$flag_low_wtp == 1)))
print(table(d$flag_confusion))
w12 <- d %>% filter(wavenum %in% 1:2)
print(table(q169 = w12$q169, c12 = w12$chose_commit12, useNA = "ifany"))
print(table(q295 = w12$q295, c12 = w12$chose_commit12, useNA = "ifany"))
print(table(q169 = w12$q169, q295 = w12$q295, useNA = "ifany"))
print(table(q170 = w12$q170, a11 = w12$chose_anticommit11, useNA = "ifany"))
# label attributes of the choice vars
for (v in c("q169","q170","q295","q296","chose_commit12")) { cat(v, ":"); str(attributes(d[[v]])) }
# check wtp vs maxwtp
cat("wtp1==maxwtp1 where maxwtp present:", mean(d$wtp1[!is.na(d$maxwtp1)] == d$maxwtp1[!is.na(d$maxwtp1)]), "\n")
cat("wtp7==maxwtp7 where maxwtp present:", mean(d$wtp7[!is.na(d$maxwtp7)] == d$maxwtp7[!is.na(d$maxwtp7)]), "\n")
