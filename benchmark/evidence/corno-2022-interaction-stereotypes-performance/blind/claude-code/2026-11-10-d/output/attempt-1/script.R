suppressMessages({library(haven)})
D <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/blind/2026-11-10-d/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean/"
for (f in c("uctdata_clean.dta","uctdata_balanced.dta")) {
  d <- read_dta(paste0(D,f))
  cat("=====", f, nrow(d), ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x,"label"); if (is.null(lab)) lab <- ""
    if (is.numeric(x)) cat(sprintf("%-26s %-45s nNA=%4d mean=%9.4f min=%9.4f max=%9.4f nu=%d\n", v, substr(lab,1,45), sum(is.na(x)), mean(x,na.rm=TRUE), suppressWarnings(min(x,na.rm=TRUE)), suppressWarnings(max(x,na.rm=TRUE)), length(unique(x))))
    else cat(sprintf("%-26s %-45s char nu=%d e.g. %s\n", v, substr(lab,1,45), length(unique(x)), paste(head(unique(x),4),collapse="|")))
  }
}
