library(haven); library(dplyr)
d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/blind/2026-11-02-c/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
print(table(exog=d$flag_exclude_exog, low=d$flag_low_wtp))
print(table(d$treatment, excl = d$flag_exclude_exog==1 | d$flag_low_wtp==1))
print(table(d$flag_confusion))
print(table(q169=d$q169, c12=d$chose_commit12, useNA="ifany"))
print(table(q295=d$q295, c12=d$chose_commit12, useNA="ifany"))
for (p in c(1,2,3,5,7,12)) {
  w <- d[[paste0("wtp",p)]]; m <- d[[paste0("maxwtp",p)]]
  cat("p=",p," max wtp=",max(w)," n at slider max=",sum(w==30*p)," n>max=",sum(w>30*p),
      " maxwtp nonNA=",sum(!is.na(m)), " wtp==maxwtp where nonNA:", sum(w==m, na.rm=TRUE), "\n")
  print(summary(w[!is.na(m)]))
}
