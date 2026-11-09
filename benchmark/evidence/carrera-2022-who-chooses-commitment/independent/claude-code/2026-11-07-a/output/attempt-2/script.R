library(haven); library(dplyr)
d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/independent/2026-11-07-a/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
print(table(d$flag_exclude_exog, d$flag_low_wtp))
print(table(d$treatment, d$flag_exclude_exog | d$flag_low_wtp))
print(table(d$flag_confusion))
for (k in c(1,2,3,5,7,12)) {
  w <- d[[paste0("wtp",k)]]; m <- d[[paste0("maxwtp",k)]]
  cat(k, "n max:", sum(!is.na(m)), " wtp==max:", sum(w==m, na.rm=TRUE), " wtp==30k:", sum(w==30*k), " wtp>30k:", sum(w>30*k), "\n")
}
s <- d %>% filter(flag_exclude_exog==0, flag_low_wtp==0, treatment!="threshold80_12")
cat("N sample:", nrow(s), "\n")
s2 <- d %>% filter(!(flag_exclude_exog==1 | flag_low_wtp==1))
cat("N after flags:", nrow(s2), "\n")
print(table(s$q169, useNA="a")); print(table(s$q295, useNA="a")); print(table(s$chose_commit12, useNA="a"))
cat("goal-days0 mean/sd:", mean(s$goal-s$days_0), sd(s$goal-s$days_0), "\n")
exp_assigned <- sapply(seq_len(nrow(s)), function(i) s[[paste0("days_", s$incentive[i])]][i])
cat("actual-exp mean/sd:", mean(s$visits-exp_assigned), sd(s$visits-exp_assigned), "\n")
