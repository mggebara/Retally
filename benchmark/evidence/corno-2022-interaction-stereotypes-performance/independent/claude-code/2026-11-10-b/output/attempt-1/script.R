suppressPackageStartupMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-b/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean"
for (f in c("uctdata_balanced.dta", "uctdata_clean.dta")) {
  d <- read_dta(file.path(D, f))
  cat("=====", f, nrow(d), ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]
    lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    if (is.numeric(x)) {
      cat(sprintf("%-28s %-40s nNA=%4d mean=%9.4f min=%9.4f max=%9.4f nuniq=%d\n", v, substr(lab,1,40), sum(is.na(x)), mean(x, na.rm=TRUE), suppressWarnings(min(x,na.rm=TRUE)), suppressWarnings(max(x,na.rm=TRUE)), length(unique(x))))
    } else {
      cat(sprintf("%-28s %-40s char nuniq=%d ex=%s\n", v, substr(lab,1,40), length(unique(x)), paste(head(unique(x),4), collapse="|")))
    }
  }
}
d <- read_dta(file.path(D, "uctdata_balanced.dta"))
try(print(table(d$round, useNA="ifany")))
try(print(table(d$Race, useNA="ifany")))
try(print(table(d$Res_base, useNA="ifany")))
