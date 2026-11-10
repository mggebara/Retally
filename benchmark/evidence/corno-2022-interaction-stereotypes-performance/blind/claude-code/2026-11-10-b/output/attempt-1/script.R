suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/blind/2026-11-10-b/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean/"
for (f in c("uctdata_balanced.dta","uctdata_clean.dta")) {
  d <- read_dta(paste0(D,f))
  cat("=====", f, nrow(d), ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x,"label"); if (is.null(lab)) lab <- ""
    cat(sprintf("%-28s %-10s nNA=%4d nuniq=%5d mean=%s | %s\n", v, class(x)[1], sum(is.na(x)), length(unique(x)),
      if (is.numeric(x)) format(round(mean(x,na.rm=TRUE),4)) else "", lab))
  }
}
d <- read_dta(paste0(D,"uctdata_balanced.dta"))
if ("round" %in% names(d)) print(table(d$round, useNA="ifany"))
