suppressPackageStartupMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/blind/2026-11-10-a/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean/"
options(width = 200)
d <- read_dta(paste0(base, "uctdata_balanced.dta"))
# variables constant within student across rounds?
vars <- c("GPA","examspassed","continue","PCAperf","mixracebas","DscoreraceIATbas","DscoreacaIATbas","Res_base","roomnum_base",
          "Falseuct2012","consbas_nomiss","durpcabas_nomiss","privateschool_nomiss","Foreign","roFalseuct2012","rodurpcabas_nomiss",
          "roconsbas_nomiss","roForeign_bas","roprivschool_nomiss","regprogram","Female","Race")
for (v in vars) {
  k <- d %>% group_by(nstudent) %>% summarise(n = n_distinct(.data[[v]]))
  cat(v, "max distinct within student:", max(k$n), "\n")
}
r2 <- d %>% filter(round == 2); r1 <- d %>% filter(round == 1)
cat("IAT bas == round1 IAT:", all.equal(r1$DscoreraceIAT[match(r2$nstudent, r1$nstudent)], r2$DscoreraceIATbas), "\n")
cat("GPA sd r2:", sd(r2$GPA), "mean:", mean(r2$GPA), "\n")
print(table(r2$regprogram == "")); print(head(sort(table(r2$regprogram), decreasing=TRUE), 50))
print(table(r2$Race, r2$mixracebas))
# rooms
rm <- r2 %>% count(Res_base, roomnum_base); print(table(rm$n))
rm2 <- r2 %>% count(roomnum_base); print(table(rm2$n))
cat("roomnum across res:", nrow(rm), nrow(rm2), "\n")
# own PCA of performance index
ok <- complete.cases(r2[, c("GPA","examspassed","continue")])
p <- prcomp(r2[ok, c("GPA","examspassed","continue")], scale. = TRUE)
print(p$rotation); cat("cor own PC1 vs PCAperf:", cor(p$x[,1], r2$PCAperf[ok]), "\n")
print(summary(lm(r2$PCAperf[ok] ~ p$x[,1])))
cat("sd PCAperf:", sd(r2$PCAperf, na.rm=TRUE), "sd own:", sd(p$x[,1]), "\n")
print(summary(r2[, c("roForeign_bas","roprivschool_nomiss","roforeign_missingbas","roprivschool_miss","missrofalse","rodurpcabas_miss","roconsbas_missing")]))
print(table(r2$blackRes)); print(table(r2$whiteRes))
print(table(is.na(r2$roRace)))
