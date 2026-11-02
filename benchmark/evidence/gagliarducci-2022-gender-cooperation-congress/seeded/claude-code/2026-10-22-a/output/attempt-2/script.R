suppressMessages({library(haven); library(dplyr)})
cat("rdrobust version:", as.character(packageVersion("rdrobust")), "\n")
print(ls(getNamespace("rdrobust")))
cat("formals rdbwselect:\n"); print(names(formals(rdrobust::rdbwselect)))
D <- "<repo>/benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/seeded/2026-10-22-a/mount/gagliarducci_2022_gender_cooperation_congress/3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.dta"
d <- read_dta(D)
cat(dim(d), "\n")
print(table(d$private, useNA="ifany"))
d <- d[d$private==0,]
cat("dups v2 HRnumber:", sum(duplicated(d[,c("v2","HRnumber")])), "\n")
print(summary(d[,c("minor","sponsor_age","MV1_female","MV1_democrat","numb_cosponsors","numb_cosponsors_opposite","pct_cosponsors_opposite","lnpop","lnarea","lninc","pct_age_over65")]))
print(table(d$sponsor_party, useNA="ifany"))
print(table(d$mixed_gender_election, is.na(d$MV1_female), useNA="ifany"))
print(grep("^house_", names(d), value=TRUE))
