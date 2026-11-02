suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/independent/2026-11-02-c/mount/gagliarducci_2022_gender_cooperation_congress/3 replication package/Data/AnalysisData/"
b <- read_dta(paste0(D,"bills_analysis_101-111_replication.dta"))
cat(dim(b), "\n")
for (v in names(b)) { x <- b[[v]]; lab <- attr(x,"label"); cat(sprintf("%-35s %-10s nNA=%6d nuniq=%6d mean=%s | %s\n", v, class(x)[1], sum(is.na(x)), length(unique(x)), if(is.numeric(x)) signif(mean(x,na.rm=T),4) else "", ifelse(is.null(lab),"",lab))) }
s <- read_dta(paste0(D,"sponsors_analysis_101-111_replication.dta")); print(names(s))
print(table(b$v2, useNA="ifany"))
print(table(b$sponsor_party, useNA="ifany"))
