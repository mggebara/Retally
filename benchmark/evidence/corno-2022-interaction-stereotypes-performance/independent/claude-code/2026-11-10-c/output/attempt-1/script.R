suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean/"
for (f in c("uctdata_balanced.dta","uctdata_clean.dta")) {
  d <- read_dta(paste0(D,f))
  cat("=====", f, nrow(d), ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x,"label"); if (is.null(lab)) lab <- ""
    if (is.numeric(x)) cat(sprintf("%-28s %-40s na=%d mean=%.4g min=%.4g max=%.4g nuniq=%d\n", v, substr(lab,1,40), sum(is.na(x)), mean(x,na.rm=TRUE), suppressWarnings(min(x,na.rm=TRUE)), suppressWarnings(max(x,na.rm=TRUE)), length(unique(x))))
    else cat(sprintf("%-28s %-40s char nuniq=%d ex=%s\n", v, substr(lab,1,40), length(unique(x)), paste(head(unique(x),3),collapse="|")))
    vl <- attr(x,"labels"); if (!is.null(vl) && length(vl)<15) cat("     labels:", paste(names(vl), vl, sep="=", collapse="; "), "\n")
  }
}
d <- read_dta(paste0(D,"uctdata_balanced.dta"))
print(table(d$Race, useNA="a"))
if ("round" %in% names(d)) print(table(d$round, useNA="a"))
