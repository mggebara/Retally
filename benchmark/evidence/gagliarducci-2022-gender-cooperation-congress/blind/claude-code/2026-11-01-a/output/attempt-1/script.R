suppressPackageStartupMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/blind/2026-11-01-a/mount/gagliarducci_2022_gender_cooperation_congress/3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.dta")
cat(dim(d), "\n")
for (v in names(d)) {
  x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  if (is.numeric(x)) cat(sprintf("%-32s %-45s na=%d mean=%.3f min=%.3f max=%.3f nuniq=%d\n", v, substr(lab,1,45), sum(is.na(x)), mean(x,na.rm=TRUE), min(x,na.rm=TRUE), max(x,na.rm=TRUE), length(unique(x))))
  else cat(sprintf("%-32s %-45s char nuniq=%d ex=%s\n", v, substr(lab,1,45), length(unique(x)), paste(head(unique(x),3),collapse="|")))
}
print(table(d$v2, useNA="ifany")); print(table(d$sponsor_party, useNA="ifany"))
print(table(d$private, useNA="ifany"))
