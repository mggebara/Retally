# Exploratory: variable labels and key tabulations. No RESULT lines.
suppressMessages({library(haven); library(dplyr)})
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/independent/2026-11-02-c/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
d <- read_dta(f)
cat("dims", dim(d), "\n")
for (v in names(d)) {
  lab <- attr(d[[v]], "label"); if (is.null(lab)) lab <- ""
  x <- d[[v]]
  nn <- sum(!is.na(x))
  cat(sprintf("%-16s | %-60s | nonNA=%d | %s\n", v, substr(lab,1,60), nn,
      if (is.numeric(x) && nn>0) paste(signif(c(min(x,na.rm=TRUE), mean(x,na.rm=TRUE), max(x,na.rm=TRUE)),4), collapse=" ") else class(x)[1]))
}
tab <- function(...) print(table(..., useNA="ifany"))
tab(d$year); tab(d$T2, d$year); tab(d$dup, d$year); tab(d$TT199, d$year); tab(d$TT202, d$year)
tab(d$Tm, d$year); tab(d$trim, d$year); tab(d$we, useNA="ifany")
cat("dist summary\n"); print(summary(d$dist)); tab(d$dist[!is.na(d$dist)] )
tab(d$time, d$year)
tab(d$month, d$year)
