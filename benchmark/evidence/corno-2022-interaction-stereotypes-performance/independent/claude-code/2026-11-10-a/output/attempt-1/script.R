suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-a/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean/"
for (f in c("uctdata_balanced.dta","uctdata_clean.dta")) {
  d <- read_dta(paste0(D, f))
  cat("=====", f, nrow(d), ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    nm <- sum(is.na(x))
    if (is.numeric(x)) cat(sprintf("%-28s %-50s NA=%4d mean=%9.4f sd=%8.4f min=%8.3f max=%8.3f nuniq=%d\n", v, substr(lab,1,50), nm, mean(x,na.rm=T), sd(x,na.rm=T), min(x,na.rm=T), max(x,na.rm=T), length(unique(x))))
    else cat(sprintf("%-28s %-50s NA=%4d char nuniq=%d\n", v, substr(lab,1,50), nm, length(unique(x))))
  }
  vl <- sapply(d, function(x) !is.null(attr(x,"labels")))
  for (v in names(d)[vl]) { cat(v, ": "); print(attr(d[[v]],"labels")) }
}
