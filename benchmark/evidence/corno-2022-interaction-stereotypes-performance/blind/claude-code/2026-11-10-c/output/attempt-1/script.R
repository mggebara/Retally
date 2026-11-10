suppressPackageStartupMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/blind/2026-11-10-c/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean"
for (f in c("uctdata_balanced.dta","uctdata_clean.dta")) {
  d <- read_dta(file.path(base,f))
  cat("=====", f, nrow(d), ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x,"label"); if (is.null(lab)) lab <- ""
    if (is.numeric(x)) cat(sprintf("%-28s %-40s nNA=%4d mean=%9.4g sd=%9.4g min=%9.4g max=%9.4g nuniq=%d\n", v, substr(lab,1,40), sum(is.na(x)), mean(x,na.rm=T), sd(x,na.rm=T), suppressWarnings(min(x,na.rm=T)), suppressWarnings(max(x,na.rm=T)), length(unique(x))))
    else cat(sprintf("%-28s %-40s char nuniq=%d ex=%s\n", v, substr(lab,1,40), length(unique(x)), paste(head(unique(x),4),collapse="|")))
  }
}
d <- read_dta(file.path(base,"uctdata_clean.dta"))
print(table(d$Race, useNA="a")); print(table(d$Res_base, useNA="a"))
for (v in intersect(c("sample","insample","working","followup","round"), names(d))) print(table(d[[v]],useNA="a"))
