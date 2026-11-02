suppressPackageStartupMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/seeded/2026-11-02-a/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
cat(nrow(d), "\n")
for (v in c("wave","type_of_info","incentive","flag_low_wtp","flag_exclude_exog","q170","q169","q296","q295","chose_commit12","chose_anticommit11","treatment")) {
  cat("==", v, class(d[[v]]), "\n"); print(table(as_factor(d[[v]]), useNA="always"))
}
for (v in c("wtp1","wtp2","wtp12","days_0","days_12","goal","visits")) {cat(v, class(d[[v]]), "\n"); print(summary(as.numeric(d[[v]])))}
print(grep("^(id|commit|percent)", names(d), value=TRUE))
