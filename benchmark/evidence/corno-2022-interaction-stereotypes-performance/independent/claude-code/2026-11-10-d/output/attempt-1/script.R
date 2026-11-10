suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-d/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean/"
options(width=200)
for (f in c("uctdata_balanced.dta","uctdata_clean.dta")) {
  d <- read_dta(paste0(D,f))
  cat("=====", f, nrow(d), ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x,"label"); if (is.null(lab)) lab <- ""
    if (is.numeric(x)) cat(sprintf("%-28s %-50s n=%d mean=%.4g min=%.4g max=%.4g nuniq=%d\n", v, substr(lab,1,50), sum(!is.na(x)), mean(x,na.rm=TRUE), suppressWarnings(min(x,na.rm=TRUE)), suppressWarnings(max(x,na.rm=TRUE)), length(unique(x))))
    else cat(sprintf("%-28s %-50s chr nuniq=%d ex=%s\n", v, substr(lab,1,50), length(unique(x)), paste(head(unique(x),4),collapse="|")))
  }
}
d <- read_dta(paste0(D,"uctdata_clean.dta"))
for (v in c("Race","round","Res_base","mixracebas","black","white","Else","coloured")) if (v %in% names(d)) {cat(v,"\n"); print(table(d[[v]], useNA="ifany"))}
if ("round" %in% names(d)) print(table(d$round, d$Race, useNA="ifany"))
