suppressPackageStartupMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-b/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean/uctdata_balanced.dta")
print(names(d))
print(table(d$round, useNA="ifany"))
v <- c("individual","nstudent","round","Race","white","black","mixracebas","GPA","examspassed","continue","PCAperf","DscoreraceIAT","Res_base","blackRes","whiteRes","regprogram","roomnum_base","missfalse","missrofalse","durpcabas_nomiss","rodurpcabas_nomiss")
for (x in intersect(v, names(d))) { cat(x, ":\n"); print(summary(as.numeric(d[[x]]))) }
print(setdiff(v, names(d)))
r2 <- d[d$round==2,]
cat("round2 white", sum(r2$white==1, na.rm=T), "black", sum(r2$black==1,na.rm=T), "\n")
cat("GPA sd round2", sd(r2$GPA,na.rm=T), "mean", mean(r2$GPA,na.rm=T), "\n")
print(table(r2$Race, useNA="ifany"))
