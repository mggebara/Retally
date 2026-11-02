suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/gagliarducci-2022-gender-cooperation-congress/independent/2026-10-22-a/mount/gagliarducci_2022_gender_cooperation_congress/3 replication package/Data/AnalysisData/"
b <- read_dta(paste0(D, "bills_analysis_101-111_replication.dta"))
cat(dim(b), "\n")
for (v in names(b)) {
  x <- b[[v]]
  lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  if (is.numeric(x)) cat(sprintf("%-32s %-45s na=%d mean=%.3f min=%.3f max=%.3f nuniq=%d\n", v, substr(lab,1,45), sum(is.na(x)), mean(x,na.rm=T), min(x,na.rm=T), max(x,na.rm=T), length(unique(x))))
  else cat(sprintf("%-32s %-45s char nuniq=%d ex=%s\n", v, substr(lab,1,45), length(unique(x)), paste(head(unique(x),3), collapse="|")))
}
s <- read_dta(paste0(D, "sponsors_analysis_101-111_replication.dta")); cat("sponsors:", dim(s), names(s), "\n")
