suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/blind/2026-11-02-c/mount/gagliarducci_2022_gender_cooperation_congress/3 replication package/Data/AnalysisData/"
b <- read_dta(paste0(D, "bills_analysis_101-111_replication.dta"))
cat(dim(b), "\n")
for (v in names(b)) {
  x <- b[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  if (is.numeric(x)) cat(sprintf("%-32s %-50s na=%d mean=%.3f min=%.3f max=%.3f nuniq=%d\n", v, substr(lab,1,50), sum(is.na(x)), mean(x,na.rm=T), suppressWarnings(min(x,na.rm=T)), suppressWarnings(max(x,na.rm=T)), length(unique(x))))
  else cat(sprintf("%-32s %-50s char nuniq=%d ex=%s\n", v, substr(lab,1,50), length(unique(x)), paste(head(unique(x),3), collapse="|")))
}
print(table(b$v2, useNA="ifany"))
print(table(b$sponsor_party, useNA="ifany"))
if ("private" %in% names(b)) print(table(b$private, useNA="ifany"))
s <- read_dta(paste0(D, "sponsors_analysis_101-111_replication.dta")); cat("sponsors:", dim(s), names(s), "\n")
