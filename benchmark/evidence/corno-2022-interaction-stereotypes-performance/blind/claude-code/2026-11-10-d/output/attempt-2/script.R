suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/blind/2026-11-10-d/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean/"
d <- zap_labels(read_dta(paste0(D,"uctdata_balanced.dta")))
for (v in c("roForeign_bas","roprivschool_nomiss","rowhite","roblack","roRace","Race","round","Res_base","continue")) { cat(v,"\n"); print(table(d[[v]], useNA="ifany")) }
cat("program blank:", sum(d$regprogram==""), "\n")
# time variation within student
tv <- d %>% group_by(nstudent) %>% summarise(across(c(GPA,examspassed,continue,PCAperf,DscoreraceIAT,DscoreraceIATbas,mixracebas,roomnum_base,Res_base,regprogram,Falseuct2012,roFalseuct2012), ~ n_distinct(.x)))
print(colSums(tv[,-1] > 1))
r2 <- d %>% filter(round==2)
cat("round2 n", nrow(r2), "\n"); print(table(r2$Race)); print(table(r2$Race, r2$mixracebas))
r1 <- d %>% filter(round==1)
cat("bas IAT eq round1 IAT:", all.equal(r1$DscoreraceIAT, r1$DscoreraceIATbas), "\n")
# room clustering
rm <- r2 %>% count(Res_base, roomnum_base); print(table(rm$n))
rm2 <- r2 %>% count(roomnum_base); print(table(rm2$n))
# GPA standardisation check
cat("GPA r2 mean sd", mean(r2$GPA), sd(r2$GPA), "\n")
cat("PCAperf NA in r2", sum(is.na(r2$PCAperf)), " continue NA", sum(is.na(r2$continue)), "\n")
print(summary(r2[,c("GPA","examspassed","continue","PCAperf")]))
print(cor(r2[,c("GPA","examspassed","continue","PCAperf")], use="complete"))
