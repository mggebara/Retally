library(haven)
M <- "<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/independent/2026-11-02-a/mount/hollyer_2022_parties_as_disciplinarians"
d <- read_dta(file.path(M,"cross-national-data.dta"))
print(summary(zap_labels(d)))
for (v in c("system","cl","pluralty","pr","erule")) print(table(d[[v]], useNA="a"))
vars <- c("personal","programmatic","ev_total","partysize","unions","business","religious","pluralty","pr","cl","mdmh","polity","demsys","system","gdppc","gini","ethfrac")
cc <- complete.cases(d[,vars]); cat("complete:",sum(cc)," countries:",length(unique(d$ccode[cc])),"\n")
cc2 <- complete.cases(d[,c(vars,"extremist2","ethnic")]); cat("complete+ext:",sum(cc2),length(unique(d$ccode[cc2])),"\n")
print(quantile(d$ev_total[cc2],c(.25,.75))); 
b <- read_dta(file.path(M,"brazil-RD-data.dta")); print(summary(zap_labels(b))); print(table(b$dlameduck_runs,useNA="a"))
